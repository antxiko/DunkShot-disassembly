"""El parche MSX2: que el IPS reproduce el ROM parcheado y que solo toca lo
que dice tocar.

Corre con el cartucho delante; sin el, se queda en lo que no lo necesita (el
IPS esta bien formado y sus tramos son los previstos).
"""

import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "dunkshot.rom")
IPS = os.path.join(RAIZ, "parche", "dunkshot_msx2.ips")
ORG = 0x4000

# Los tramos que cambia el parche (inicio, fin incluido), medidos al generarlo.
TRAMOS = [(0x43AA, 0x43AE), (0x5037, 0x5038), (0x504C, 0x504D), (0x5058, 0x5059),
          (0x51C0, 0x51CB), (0x51CF, 0x51CF), (0x5B7A, 0x5B7E), (0x5B83, 0x5B84),
          (0x5BE8, 0x5BE8), (0x5BEF, 0x5BF2), (0x5BF4, 0x5BFA), (0x5BFD, 0x5BFD),
          (0x5C04, 0x5C05), (0x5C07, 0x5C07), (0x5FF7, 0x5FFA), (0x6EA0, 0x6EBF),
          (0x6F30, 0x6F42), (0x7374, 0x737A), (0x7AAE, 0x7ABA), (0x804E, 0x804E),
          (0x8057, 0x805B), (0x80D7, 0x80D7), (0x80DE, 0x80DE), (0xBFD4, 0xBFFB)]


def lee_ips(ruta):
    d = open(ruta, "rb").read()
    assert d[:5] == b"PATCH" and d[-3:] == b"EOF", ruta
    i, regs = 5, []
    while d[i:i + 3] != b"EOF":
        a = int.from_bytes(d[i:i + 3], "big")
        n = int.from_bytes(d[i + 3:i + 5], "big")
        regs.append((a, d[i + 5:i + 5 + n]))
        i += 5 + n
    return regs


class ElIps(unittest.TestCase):
    def test_esta_bien_formado_y_toca_lo_previsto(self):
        regs = lee_ips(IPS)
        self.assertEqual([(a + ORG, a + ORG + len(b) - 1) for a, b in regs], TRAMOS)
        self.assertEqual(sum(len(b) for _, b in regs), 170)

    def test_el_codigo_nuevo_cae_en_relleno_y_huerfanos(self):
        """0xBFD4-0xBFFF era relleno a 0xFF; 0x6EA0-0x6EDC, 0x6F30-0x6F47 y
        0x7AAE-0x7ABD, codigo huerfano."""
        regs = dict((a + ORG, b) for a, b in lee_ips(IPS))
        for ini, tope in ((0xBFD4, 0xC000), (0x6EA0, 0x6EDD), (0x6F30, 0x6F48), (0x7AAE, 0x7ABE)):
            self.assertIn(ini, regs)
            self.assertLessEqual(ini + len(regs[ini]), tope)

    def test_el_gancho_pone_screen_4_solo_en_msx2(self):
        regs = dict((a + ORG, b) for a, b in lee_ips(IPS))
        gancho = regs[0xBFD4]
        # call INIGRP / ld a,(0x002D) / and a / ret z / ld bc,0x0400 / call WRTVDP / ret
        self.assertTrue(gancho.startswith(bytes.fromhex("cd 72 00 3a 2d 00 a7 c8 01 00 04 cd 47 00 c9")))
        self.assertEqual(regs[0x5037], bytes.fromhex("d4 bf"))              # jp 0xBFD4
        self.assertEqual(regs[0x5B7A], bytes.fromhex("3e 3c 77 3e 78"))     # ATRBAS alto 0x3C, R5 = 0x78
        self.assertEqual(regs[0x43AA], bytes.fromhex("b0 b4 b8 b4 b0"))     # la red, 0x50 mas arriba


class ElRomParcheado(unittest.TestCase):
    def test_aplicar_el_ips_da_lo_mismo_que_la_herramienta(self):
        if not os.path.exists(ROM):
            return                      # sin el cartucho solo vale lo del IPS
        import parche_msx2
        rom = open(ROM, "rb").read()
        nuevo = parche_msx2.aplica(rom)
        por_ips = bytearray(rom)
        for a, b in lee_ips(IPS):
            por_ips[a:a + len(b)] = b
        self.assertEqual(bytes(por_ips), nuevo)
        cambiados = [i for i in range(len(rom)) if rom[i] != nuevo[i]]
        self.assertEqual(len(cambiados), 170)


if __name__ == "__main__":
    unittest.main()

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
BYTES_CAMBIADOS = 164

# Los tramos que cambia el parche (inicio, fin incluido), medidos al generarlo.
TRAMOS = [(0x5037, 0x5038), (0x5065, 0x5065), (0x5B7C, 0x5B7C), (0x5B83, 0x5B84),
          (0x5B9C, 0x5B9C), (0x5BE8, 0x5BE8), (0x5BF4, 0x5BF4), (0x5BF9, 0x5BFA),
          (0x5BFD, 0x5C0A), (0x6EA0, 0x6EB9), (0x6EBB, 0x6EBC), (0x6EBE, 0x6EC1),
          (0x6EC3, 0x6EC5), (0x6EC9, 0x6ECE), (0x6ED0, 0x6ED6), (0x6F30, 0x6F45),
          (0x7374, 0x737A), (0x7AAE, 0x7AB6), (0x804E, 0x804E), (0x8057, 0x805B),
          (0x80CE, 0x80D0), (0x80D7, 0x80D7), (0x80DE, 0x80DE), (0xBFD4, 0xBFFD)]

# Donde cae el codigo nuevo: relleno a 0xFF al final y tres huecos de codigo huerfano.
HUECOS = [(0xBFD4, 0xC000), (0x6EA0, 0x6EDD), (0x6F30, 0x6F48), (0x7AAE, 0x7ABE)]


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
        self.assertEqual(sum(len(b) for _, b in regs), BYTES_CAMBIADOS)

    def test_el_codigo_nuevo_cae_en_relleno_y_huerfanos(self):
        """Todo tramo que empieza en un hueco acaba dentro de el, y los cuatro
        huecos se usan."""
        regs = lee_ips(IPS)
        for ini, tope in HUECOS:
            dentro = [(a + ORG, a + ORG + len(b)) for a, b in regs if ini <= a + ORG < tope]
            self.assertTrue(dentro, hex(ini))
            self.assertEqual(dentro[0][0], ini)
            for _, fin in dentro:
                self.assertLessEqual(fin, tope)

    def test_el_gancho_pone_screen_4_solo_en_msx2(self):
        regs = dict((a + ORG, b) for a, b in lee_ips(IPS))
        gancho = regs[0xBFD4]
        # call INIGRP / ld hl,0x3E00 / ld (ATRBAS),hl / ld a,(0x002D) / and a / ld bc,0x7C05 /
        # jp z,WRTVDP / ld bc,0x0400 / call WRTVDP / ld bc,0x7F05 / jp WRTVDP
        self.assertEqual(gancho[:31], bytes.fromhex(
            "cd 72 00 21 00 3e 22 28 f9 3a 2d 00 a7 01 05 7c ca 47 00 01 00 04 cd 47 00 01 05 7f c3 47 00"))
        # r5_segun_maquina: ld a,(0x002D) / and a / jr z,+2 / ld b,0x7F / jp WRTVDP
        self.assertEqual(gancho[31:], bytes.fromhex("3a 2d 00 a7 28 02 06 7f c3 47 00"))
        self.assertEqual(regs[0x5037], bytes.fromhex("d4 bf"))              # jp 0xBFD4
        self.assertEqual(regs[0x5B7C], b"")                             # xor 1: 0x3E <-> 0x3F
        self.assertEqual(regs[0x5B83], bytes.fromhex("f3 bf"))              # call r5_segun_maquina
        self.assertEqual(regs[0x5B9C], b">")                             # congela: cp 0x3E

    def test_las_tablas_en_el_bloque_de_1_kb_de_0x3c00(self):
        """Colores en 0x3C00 (la primera mitad del bloque), atributos en 0x3E00
        y la segunda tabla del MSX1 en 0x3F00."""
        regs = dict((a + ORG, b) for a, b in lee_ips(IPS))
        self.assertEqual(regs[0x6EA0][7:10], bytes.fromhex("21 00 3c"))    # tabla_colores: ld hl,0x3C00
        self.assertEqual(regs[0x7AAE], bytes.fromhex("cd 07 5b 21 b3 e7 c3 a0 6e"))  # vuelca_colores
        self.assertEqual(regs[0x5BE8], b">")                             # la copia rotada a 0x3E00
        self.assertEqual(regs[0x5BF4], b"?")                             # la invertida a 0x3F00
        self.assertEqual(regs[0x5BF9], bytes.fromhex("ae 7a"))              # jp vuelca_colores
        # oculta_sprites: ld hl,0x3E00 / call fin_tabla / ld hl,0x3F00 / ld a,0xD0 / jp escribe_vram
        self.assertEqual(regs[0x5BFD], bytes.fromhex("3e cd c9 6e 21 00 3f 3e d0 c3 f7 5a 00 00"))
        for a in (0x5065, 0x804E, 0x80D7, 0x80DE):
            self.assertEqual(regs[a], b">", hex(a))                      # 0x1Bxx -> 0x3Exx


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
        self.assertEqual(len(cambiados), BYTES_CAMBIADOS)

    def test_los_patrones_de_sprite_no_se_tocan(self):
        """El diseno no mueve patrones: ni la red (0x43AA), ni los huecos de
        patron (0x5FF7), ni los numeros (0x51C0), ni la carga de la red y el
        balon (0x504B, 0x5057)."""
        if not os.path.exists(ROM):
            return
        import parche_msx2
        rom = open(ROM, "rb").read()
        nuevo = parche_msx2.aplica(rom)
        for a, n in ((0x43AA, 5), (0x5FF7, 4), (0x51C0, 16), (0x504B, 3), (0x5057, 3)):
            self.assertEqual(rom[a - ORG:a - ORG + n], nuevo[a - ORG:a - ORG + n], hex(a))


if __name__ == "__main__":
    unittest.main()

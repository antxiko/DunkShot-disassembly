"""El parche MSX2 de la version "a": que el IPS reproduce el ROM parcheado y
que solo toca lo que dice tocar.

Corre con el cartucho delante; sin el, se queda en lo que no lo necesita (el
IPS esta bien formado y sus tramos son los previstos).
"""

import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "..", "tools"))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "dunkshot.rom")
IPS = os.path.join(RAIZ, "parche", "dunkshot_a_msx2.ips")
ORG = 0x4000
BYTES_CAMBIADOS = 165

# Los tramos que cambia el parche (inicio, fin incluido), medidos al generarlo.
TRAMOS = [(0x4D92, 0x4DA5), (0x4DA7, 0x4DAF), (0x5C50, 0x5C65), (0x5D65, 0x5D6B),
          (0x5D6D, 0x5D8A), (0x5D8E, 0x5D96), (0x5DB1, 0x5DB2), (0x5DDF, 0x5DDF),
          (0x61A7, 0x61A7), (0x61AE, 0x61AF), (0x61C7, 0x61C7), (0x6213, 0x6213),
          (0x621F, 0x621F), (0x6224, 0x6225), (0x6228, 0x6235), (0x6DFE, 0x6E0B),
          (0x73A3, 0x73A3), (0x73AC, 0x73B0), (0x7423, 0x7425), (0x742C, 0x742C),
          (0x7433, 0x7433), (0x7E91, 0x7E9B), (0x87F3, 0x87F9)]

# Donde cae el codigo nuevo: cinco rutinas huerfanas (nadie las llama ni las
# nombra; tools/apunta_a.py lo comprueba).
HUECOS = [(0x4D92, 0x4DB3), (0x5C50, 0x5C68), (0x5D65, 0x5D97), (0x6DFE, 0x6E0E),
          (0x7E91, 0x7EA3)]


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

    def test_el_codigo_nuevo_cae_en_huerfanos(self):
        """Todo tramo que empieza en un hueco acaba dentro de el, y los cinco
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
        # (el IPS se salta los bytes que no cambian: de ahi los dos trozos)
        self.assertEqual(regs[0x4D92], bytes.fromhex(
            "cd 72 00 21 00 3e 22 28 f9 3a 2d 00 a7 01 05 7c ca 47 00 01"))
        self.assertEqual(regs[0x4DA7], bytes.fromhex("04 cd 47 00 01 05 7f c3 47"))
        # r5_segun_maquina: ld a,(0x002D) / and a / jr z,+2 / ld b,0x7F / jp WRTVDP
        self.assertEqual(regs[0x7E91], bytes.fromhex("3a 2d 00 a7 28 02 06 7f c3 47 00"))
        self.assertEqual(regs[0x5DB1], bytes.fromhex("92 4d"))              # jp 0x4D92
        self.assertEqual(regs[0x61A7], b"\x01")                             # xor 1: 0x3E <-> 0x3F
        self.assertEqual(regs[0x61AE], bytes.fromhex("91 7e"))              # call r5_segun_maquina
        self.assertEqual(regs[0x61C7], b">")                                # congela: cp 0x3E

    def test_las_tablas_en_el_bloque_de_1_kb_de_0x3c00(self):
        """Colores en 0x3C00 (la primera mitad del bloque), atributos en 0x3E00
        y la segunda tabla del MSX1 en 0x3F00."""
        regs = dict((a + ORG, b) for a, b in lee_ips(IPS))
        # tabla_colores: ... push hl / ld hl,0x3C00 (el 0x21 ya estaba)
        self.assertEqual(regs[0x5D65][5:7] + regs[0x5D6D][:1], bytes.fromhex("f3 e5 00")[:2] + b"\x00")
        self.assertEqual(regs[0x5D8E], bytes.fromhex("cd 32 61 21 68 ec c3 65 5d"))  # vuelca_colores
        self.assertEqual(regs[0x6213], b">")                                # la copia rotada a 0x3E00
        self.assertEqual(regs[0x621F], b"?")                                # la invertida a 0x3F00
        self.assertEqual(regs[0x6224], bytes.fromhex("8e 5d"))              # jp vuelca_colores
        # oculta_sprites: ld hl,0x3E00 / call fin_tabla / ld hl,0x3F00 / ld a,0xD0 / jp escribe_vram
        self.assertEqual(regs[0x6228], bytes.fromhex("3e cd fe 6d 21 00 3f 3e d0 c3 22 61 00 00"))
        for a in (0x5DDF, 0x73A3, 0x742C, 0x7433):
            self.assertEqual(regs[a], b">", hex(a))                         # 0x1Bxx -> 0x3Exx


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
        """El diseno no mueve patrones: ni la red (0x43AD), ni los huecos de
        patron (0x6662), ni los numeros (0x5F3D), ni la carga de la red y el
        balon (0x5DC5, 0x5DD1)."""
        if not os.path.exists(ROM):
            return
        import parche_msx2
        rom = open(ROM, "rb").read()
        nuevo = parche_msx2.aplica(rom)
        for a, n in ((0x43AD, 5), (0x6662, 4), (0x5F3D, 16), (0x5DC5, 3), (0x5DD1, 3)):
            self.assertEqual(rom[a - ORG:a - ORG + n], nuevo[a - ORG:a - ORG + n], hex(a))

    def test_el_codigo_huerfano_que_se_pisa_no_lo_llama_nadie(self):
        """Cada hueco es una rutina que ninguna palabra de los 32 KB nombra
        (salvo coincidencias dentro de datos o de la propia rutina)."""
        if not os.path.exists(ROM):
            return
        rom = open(ROM, "rb").read()
        for ini, tope in HUECOS:
            for dirr in range(ORG, ORG + len(rom) - 1):
                if ini <= dirr < tope:
                    continue                                # dentro del propio hueco
                p = rom[dirr - ORG] | rom[dirr - ORG + 1] << 8
                if p == ini:
                    self.fail("0x%04X apunta al hueco 0x%04X" % (dirr, ini))


if __name__ == "__main__":
    unittest.main()

"""Lo que se afirma del cartucho (la version "a" de GoodMSX), comprobado contra
sus bytes.

Corre con el cartucho delante y sin el: cuando no esta, la imagen se rehace
desde las filas defb/defw del listado, que si viaja con el repositorio. Sin el
cartucho solo se comprueba lo que cae en datos.
"""

import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "..", "tools"))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "dunkshot.rom")
ASM = os.path.join(RAIZ, "src", "dunkshot.asm")
ENTRIES = os.path.join(RAIZ, "src", "dunkshot.entries")
ORG = 0x4000
TAM = 32768

FILA = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")


def imagen_desde_el_listado():
    img = bytearray(TAM)
    with open(ASM, encoding="utf-8") as f:
        for ln in f:
            m = FILA.match(ln)
            if not m:
                continue
            ancho, cuerpo, dirr = m.group(1), m.group(2), int(m.group(3), 16)
            p = dirr - ORG
            for tok in cuerpo.split(","):
                tok = tok.strip().rstrip("h")
                if not tok:
                    continue
                v = int(tok, 16)
                if ancho == "b":
                    img[p] = v
                    p += 1
                else:
                    img[p] = v & 0xFF
                    img[p + 1] = v >> 8
                    p += 2
    return bytes(img)


def lee():
    if os.path.exists(ROM):
        with open(ROM, "rb") as f:
            return f.read()
    return imagen_desde_el_listado()


def palabra(rom, a):
    return rom[a - ORG] | rom[a - ORG + 1] << 8


class Cabecera(unittest.TestCase):
    def test_es_un_cartucho_msx_de_32k(self):
        rom = lee()
        self.assertEqual(rom[:2], b"AB")
        self.assertEqual(len(rom), TAM)

    def test_init_es_4010(self):
        self.assertEqual(palabra(lee(), 0x4002), 0x4010)

    def test_solo_usa_init(self):
        """STATEMENT, DEVICE y TEXT a cero."""
        self.assertEqual(lee()[4:16], b"\x00" * 12)

    def test_acaba_en_relleno(self):
        """Los dos ultimos bytes son 0xFF, y otros 24 delante de la red."""
        rom = lee()
        self.assertEqual(rom[-2:], b"\xff\xff")
        self.assertEqual(rom[0x9CE3 - ORG:0x9CFB - ORG], b"\xff" * 24)


class TablaDeSaltos(unittest.TestCase):
    """Las dos tablas de cuatro `jp` detras del `jp (hl)` de 0x958B."""

    def test_ocho_jp_dentro_del_cartucho(self):
        rom = lee()
        for i in range(8):
            a = 0x958C + 3 * i
            self.assertEqual(rom[a - ORG], 0xC3, hex(a))
            destino = palabra(rom, a + 1)
            self.assertTrue(0x95A4 <= destino < 0x9713, hex(destino))

    def test_la_vuelta_apilada_es_95a4(self):
        """0x9587: ld de,0x95A4 / push de, justo antes del jp (hl)."""
        rom = lee()
        self.assertEqual(rom[0x9587 - ORG:0x958B - ORG], bytes([0x11, 0xA4, 0x95, 0xD5]))


class BloquesComprimidos(unittest.TestCase):
    """Cada bloque acaba justo donde empieza el siguiente, y mide lo que el
    codigo copia despues."""

    def test_los_bloques_encadenan(self):
        from graficos import Rom, BLOQUES
        rom = Rom(ROM) if os.path.exists(ROM) else None
        if rom is None:
            rom = Rom.__new__(Rom)
            rom.d = lee()
        fines = {}
        for a, f, _, _ in BLOQUES:
            _, fin = f(rom, a)
            fines[a] = fin
        self.assertEqual(fines[0x9DBB], 0xA19E)
        self.assertEqual(fines[0xA19E], 0xA616)
        self.assertEqual(fines[0xA616], 0xA9F6)
        self.assertEqual(fines[0xA9F6], 0xAA24)
        self.assertEqual(fines[0xADE4], 0xB23E)
        self.assertEqual(fines[0xB23E], 0xB346)
        self.assertEqual(fines[0xB346], 0xB44E)
        self.assertEqual(fines[0xB44E], 0xB556)
        self.assertEqual(fines[0xB556], 0xB5F5)
        self.assertEqual(fines[0xB5F5], 0xB794)
        self.assertEqual(fines[0xB794], 0xB8C0)
        self.assertEqual(fines[0xB8C0], 0xB9D4)
        self.assertEqual(fines[0xB9D4], 0xBB27)
        self.assertEqual(fines[0xBB27], 0xBC34)
        self.assertEqual(fines[0xBD34], 0xBFFE)

    def test_los_tamanos_son_los_que_copia_el_codigo(self):
        from graficos import Rom, BLOQUES
        rom = Rom.__new__(Rom)
        rom.d = lee()
        tam = {a: len(f(rom, a)[0]) for a, f, _, _ in BLOQUES}
        self.assertEqual(tam[0x9DBB], 2048)      # tres bancos de 64 sprites
        self.assertEqual(tam[0xA19E], 2048)
        self.assertEqual(tam[0xA616], 2048)
        self.assertEqual(tam[0xA9F6], 128)       # cuatro sprites mas
        self.assertEqual(tam[0xADE4], 2000)      # 250 patrones
        self.assertEqual(tam[0xB23E], 2000)      # y sus 250 colores, por AREA
        self.assertEqual(tam[0xB556], 672)       # 0x2A0 (0x6BA0)
        self.assertEqual(tam[0xB5F5], 720)       # 0x2D0 (0x5F14)
        self.assertEqual(tam[0xB794], 544)       # 0x220 (0x76D0)
        self.assertEqual(tam[0xB8C0], 768)       # 0x300 (0x74F2)
        self.assertEqual(tam[0xB9D4], 640)       # 0x280 (0x6B3B)
        self.assertEqual(tam[0xBB27], 640)       # 0x280 (0x6B50)
        self.assertEqual(tam[0xBD34], 56 * 24)   # la pista entera

    def test_el_marcador_son_21_por_4(self):
        from graficos import Rom, des_5331
        rom = Rom.__new__(Rom)
        rom.d = lee()
        caja, fin = des_5331(rom, 0x6AFD)
        self.assertEqual(fin, 0x6B2F)
        self.assertEqual(len(caja), 21 * 4)

    def test_las_tres_areas_cambian_los_colores(self):
        from graficos import Rom, des_5373
        rom = Rom.__new__(Rom)
        rom.d = lee()
        areas = [des_5373(rom, a)[0] for a in (0xB23E, 0xB346, 0xB44E)]
        self.assertEqual(len({bytes(a) for a in areas}), 3)


class Sonido(unittest.TestCase):
    def test_trece_piezas_dentro_de_su_zona(self):
        rom = lee()
        for i in range(13):
            p = palabra(rom, 0x8E61 + 2 * i)
            self.assertTrue(0x8E88 <= p < 0x956F, hex(p))

    def test_cada_pieza_acaba_antes_del_codigo(self):
        from sonido import recorre
        rom = lee()
        for i in range(13):
            p = palabra(rom, 0x8E61 + 2 * i)
            self.assertLessEqual(recorre(rom, p), 0x956F)


class Poses(unittest.TestCase):
    def test_los_patrones_de_las_poses_existen(self):
        """196 patrones: 192 en los tres bancos y cuatro aparte."""
        rom = lee()
        self.assertLessEqual(max(rom[0xAB64 - ORG:0xADE4 - ORG]), 195)

    def test_las_parejas_de_colores_son_piel_y_pelo(self):
        rom = lee()
        pieles = {rom[0x7439 - ORG + 2 * i] for i in range(32)}
        self.assertEqual(pieles, {0x0B, 0x0A, 0x01})

    def test_los_companeros_de_cada_jugador(self):
        rom = lee()
        t = rom[0x9B25 - ORG:0x9B31 - ORG]
        self.assertEqual(list(t), [1, 2, 0, 2, 0, 1, 4, 5, 3, 5, 3, 4])


class Huerfanos(unittest.TestCase):
    def test_cada_huerfano_lleva_su_motivo(self):
        with open(ENTRIES, encoding="utf-8") as f:
            lineas = [ln for ln in f if ln.startswith("0x")]
        huerfanos = [ln for ln in lineas if "huerfano" in ln]
        self.assertEqual(len(huerfanos), 16)
        for ln in huerfanos:
            self.assertRegex(ln, r"codigo huerfano: \S")


class LoQueCambiaEnLaVersionA(unittest.TestCase):
    """Lo que esta ROM hace distinto de la primera, comprobado en sus bytes."""

    def test_la_pareja_de_cada_jugador_es_el_de_enfrente(self):
        """0x603C reparte en +0x25 la tabla 3 4 5 0 1 2 (la primera: 5 4 3 2 1 0)."""
        rom = lee()
        self.assertEqual(list(rom[0x6050 - ORG:0x6056 - ORG]), [3, 4, 5, 0, 1, 2])
        # ld hl,0xC435 / ld de,0x6050
        self.assertEqual(rom[0x603C - ORG:0x6042 - ORG], bytes([0x21, 0x35, 0xC4, 0x11, 0x50, 0x60]))

    def test_el_rotulo_de_la_tecla(self):
        rom = lee()
        self.assertEqual(rom[0x7F76 - ORG:0x7F86 - ORG], b"PUSH SPACE KEY>\x00")

    def test_los_creditos_dicen_kagami(self):
        self.assertIn(b"S;KAGAMI\x00", lee())
        self.assertNotIn(b"S;MIRROR", lee())

    def test_la_quinta_falta_solo_expulsa_a_las_personas(self):
        """0x6C5E: jr nz (equipo de la maquina) salta al borrado de faltas."""
        rom = lee()
        self.assertEqual(rom[0x6C5E - ORG:0x6C60 - ORG], bytes([0x20, 0x11]))     # jr nz,0x6C71
        self.assertEqual(rom[0x6C71 - ORG:0x6C73 - ORG], bytes([0x36, 0x00]))     # ld (hl),0

    def test_el_tiro_suma_los_dos_contadores_al_anotar(self):
        """0x8C15 suma el valor a (0xED89) y a (0xED8B), cada uno con tope 0xFF."""
        rom = lee()
        cuerpo = rom[0x8C15 - ORG:0x8C2D - ORG]
        self.assertEqual(cuerpo.count(bytes([0x3E, 0xFF])), 2)
        self.assertIn(bytes([0x2A, 0x89, 0xED]), cuerpo)
        self.assertIn(bytes([0x2A, 0x8B, 0xED]), cuerpo)


if __name__ == "__main__":
    unittest.main()

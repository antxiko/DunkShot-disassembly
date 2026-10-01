"""Lo que se afirma del cartucho, comprobado contra sus bytes.

Corre con el cartucho delante y sin el: cuando no esta, la imagen se rehace
desde las filas defb/defw del listado, que si viaja con el repositorio. Sin el
cartucho solo se comprueba lo que cae en datos.
"""

import os
import re
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
        """Los 44 ultimos bytes son 0xFF."""
        self.assertEqual(lee()[-44:], b"\xff" * 44)


class TablaDeSaltos(unittest.TestCase):
    """Las dos tablas de cuatro `jp` detras del `jp (hl)` de 0xB984."""

    def test_ocho_jp_dentro_del_cartucho(self):
        rom = lee()
        for i in range(8):
            a = 0xB985 + 3 * i
            self.assertEqual(rom[a - ORG], 0xC3, hex(a))
            destino = palabra(rom, a + 1)
            self.assertTrue(0xB99D <= destino < 0xBB0C, hex(destino))

    def test_la_vuelta_apilada_es_b99d(self):
        """0xB980: ld de,0xB99D / push de, justo antes del jp (hl)."""
        rom = lee()
        self.assertEqual(rom[0xB980 - ORG:0xB984 - ORG], bytes([0x11, 0x9D, 0xB9, 0xD5]))


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
        self.assertEqual(fines[0x9725], 0x9B08)
        self.assertEqual(fines[0x9B08], 0x9F80)
        self.assertEqual(fines[0x9F80], 0xA360)
        self.assertEqual(fines[0xA360], 0xA38E)
        self.assertEqual(fines[0xA74E], 0xABA8)
        self.assertEqual(fines[0xABA8], 0xACB0)
        self.assertEqual(fines[0xACB0], 0xADB8)
        self.assertEqual(fines[0xADB8], 0xAEC0)
        self.assertEqual(fines[0xAEC0], 0xAF5F)
        self.assertEqual(fines[0xAF5F], 0xB0FE)
        self.assertEqual(fines[0xB0FE], 0xB22A)
        self.assertEqual(fines[0xB22A], 0xB33E)
        self.assertEqual(fines[0xB33E], 0xB491)
        self.assertEqual(fines[0xB491], 0xB59E)
        self.assertEqual(fines[0xB69E], 0xB968)

    def test_los_tamanos_son_los_que_copia_el_codigo(self):
        from graficos import Rom, BLOQUES
        rom = Rom.__new__(Rom)
        rom.d = lee()
        tam = {a: len(f(rom, a)[0]) for a, f, _, _ in BLOQUES}
        self.assertEqual(tam[0x9725], 2048)      # tres bancos de 64 sprites
        self.assertEqual(tam[0x9B08], 2048)
        self.assertEqual(tam[0x9F80], 2048)
        self.assertEqual(tam[0xA360], 128)       # cuatro sprites mas
        self.assertEqual(tam[0xA74E], 2000)      # 250 patrones
        self.assertEqual(tam[0xABA8], 2000)      # y sus 250 colores, por AREA
        self.assertEqual(tam[0xAEC0], 672)       # 0x2A0 (0x784E)
        self.assertEqual(tam[0xAF5F], 720)       # 0x2D0 (0x5197)
        self.assertEqual(tam[0xB0FE], 544)       # 0x220 (0x837B)
        self.assertEqual(tam[0xB22A], 768)       # 0x300 (0x819D)
        self.assertEqual(tam[0xB33E], 640)       # 0x280 (0x77E9)
        self.assertEqual(tam[0xB491], 640)       # 0x280 (0x77FE)
        self.assertEqual(tam[0xB69E], 56 * 24)   # la pista entera

    def test_el_marcador_son_21_por_4(self):
        from graficos import Rom, des_5331
        rom = Rom.__new__(Rom)
        rom.d = lee()
        caja, fin = des_5331(rom, 0x77AB)
        self.assertEqual(fin, 0x77DD)
        self.assertEqual(len(caja), 21 * 4)


class Sonido(unittest.TestCase):
    def test_trece_piezas_dentro_de_su_zona(self):
        rom = lee()
        for i in range(13):
            p = palabra(rom, 0x8F57 + 2 * i)
            self.assertTrue(0x8F7E <= p < 0x9665, hex(p))

    def test_cada_pieza_acaba_antes_de_los_sprites(self):
        from sonido import recorre
        rom = lee()
        for i in range(13):
            p = palabra(rom, 0x8F57 + 2 * i)
            self.assertLessEqual(recorre(rom, p), 0x9665)


class Poses(unittest.TestCase):
    def test_los_patrones_de_las_poses_existen(self):
        """196 patrones: 192 en los tres bancos y cuatro en 0xE400."""
        rom = lee()
        self.assertLessEqual(max(rom[0xA4CE - ORG:0xA74E - ORG]), 195)

    def test_las_parejas_de_colores_son_piel_y_pelo(self):
        rom = lee()
        pieles = {rom[0x80E4 - ORG + 2 * i] for i in range(32)}
        self.assertEqual(pieles, {0x0B, 0x0A, 0x01})

    def test_los_companeros_de_cada_jugador(self):
        rom = lee()
        t = rom[0xBF1E - ORG:0xBF2A - ORG]
        self.assertEqual(list(t), [1, 2, 0, 2, 0, 1, 4, 5, 3, 5, 3, 4])


class Huerfanos(unittest.TestCase):
    def test_cada_huerfano_lleva_su_motivo(self):
        with open(ENTRIES, encoding="utf-8") as f:
            lineas = [ln for ln in f if ln.startswith("0x")]
        huerfanos = [ln for ln in lineas if "huerfano" in ln]
        self.assertEqual(len(huerfanos), 17)
        for ln in huerfanos:
            self.assertRegex(ln, r"codigo huerfano: \S")


if __name__ == "__main__":
    unittest.main()

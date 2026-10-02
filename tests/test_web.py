"""Las cifras y los textos que publica la web, contra lo que mide el repositorio.

Lo que se rompe solo: una cifra que envejece en tools/contenido_web.py, una
herramienta o un texto copiado de otro juego, una imagen de la galeria que no
existe. Las comprobaciones corren sin la ROM: leen el listado y las notas.
"""

import os
import re
import subprocess
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

import contenido_web as cw  # noqa: E402

ASM = os.path.join(RAIZ, "src", "dunkshot.asm")
PY = sys.executable


def salida(*args):
    return subprocess.run([PY] + list(args), capture_output=True, text=True,
                          cwd=RAIZ, encoding="utf-8", errors="replace").stdout


class LasCifrasDeLaPortada(unittest.TestCase):
    def test_la_suma_de_bytes_da_el_cartucho(self):
        self.assertEqual(cw.CODIGO + cw.DATOS, 32768)

    def test_las_cifras_de_bytes_son_las_de_este_listado(self):
        """Los bytes de datos son las filas defb/defw del listado, que viaja
        con el repositorio; los de codigo, el resto de los 32 KB."""
        fila = re.compile(r"^\s+def(b|w)\s+([0-9a-fA-F,h ]+)\s*;\s*([0-9a-f]{4})")
        datos = 0
        with open(ASM, encoding="utf-8") as f:
            for ln in f:
                m = fila.match(ln)
                if m:
                    n = len([t for t in m.group(2).split(",") if t.strip()])
                    datos += n * (2 if m.group(1) == "w" else 1)
        self.assertEqual(datos, cw.DATOS)
        self.assertEqual(32768 - datos, cw.CODIGO)

    def test_la_densidad_y_las_flojas_son_las_del_listado(self):
        out = salida("tools/densidad.py", ASM)
        m = re.search(r"en total: (\d+) instrucciones, (\d+) comentarios", out)
        self.assertIsNotNone(m, out[-400:])
        self.assertEqual(int(m.group(1)), cw.INSTRUCCIONES)
        self.assertEqual(int(m.group(2)), cw.COMENTARIOS)
        self.assertIn("0 rutinas por debajo del 10 %", out)
        self.assertGreaterEqual(cw.COMENTARIOS * 100.0 / cw.INSTRUCCIONES, 40.0)

    def test_las_rutinas_son_las_de_densidad(self):
        out = salida("tools/densidad.py", ASM)
        m = re.search(r"por debajo del 10 %, de (\d+)", out)
        self.assertIsNotNone(m, out[-400:])
        self.assertEqual(int(m.group(1)), cw.RUTINAS)

    def test_ningun_call_sin_nombre(self):
        out = salida("tools/sin_bautizar.py", ASM)
        self.assertTrue(out.startswith("0 rutinas sin bautizar"), out[:200])

    def test_la_ficha_dice_el_sha_y_la_compania(self):
        for idioma in ("es", "en"):
            ficha = " ".join(cw.PORTADA[idioma]["ficha"])
            self.assertIn("a1891e03", ficha)
            self.assertIn("HAL Laboratory", ficha)
            self.assertIn("32 KB", ficha)
        self.assertEqual(cw.COMPANIA, "HAL Laboratory")
        self.assertEqual(cw.ANIO, 1986)


class NadaDeOtroJuego(unittest.TestCase):
    OTROS = re.compile(r"Q\*bert|qbert|Konami|RC-7\d\d|Hinotori|Rastan", re.I)

    def test_el_encabezado_del_listado_es_de_este_juego(self):
        cab = open(ASM, encoding="utf-8").read(600)
        self.assertIn("DUNK SHOT", cab)
        self.assertIn("HAL Laboratory", cab)

    def test_la_licencia_y_los_avisos_son_de_este_juego(self):
        for fn in ("LICENSE", "AVISO-LEGAL.md", "LEGAL-NOTICE.md", "README.md", "README.es.md"):
            t = open(os.path.join(RAIZ, fn), encoding="utf-8").read()
            self.assertIn("Dunk Shot", t, fn)
            self.assertIsNone(self.OTROS.search(t), fn)

    def test_las_herramientas_no_apuntan_a_otro_juego(self):
        for fn in os.listdir(os.path.join(RAIZ, "tools")):
            if not fn.endswith((".py", ".sh", ".tcl")):
                continue
            t = open(os.path.join(RAIZ, "tools", fn), encoding="utf-8").read()
            self.assertNotIn("qbert", t.lower(), fn)

    def test_ni_los_textos_publicados(self):
        for carpeta in ("docs", os.path.join("docs", "es")):
            for fn in os.listdir(os.path.join(RAIZ, carpeta)):
                if fn.endswith(".md"):
                    t = open(os.path.join(RAIZ, carpeta, fn), encoding="utf-8").read()
                    self.assertIsNone(self.OTROS.search(t), os.path.join(carpeta, fn))


class LaGaleria(unittest.TestCase):
    def test_estan_todas_las_de_la_galeria(self):
        imgdir = os.path.join(RAIZ, "docs", "imagenes")
        for fich, es, en in cw.GALERIA:
            self.assertTrue(os.path.exists(os.path.join(imgdir, fich)), fich)
            self.assertTrue(es and en, fich)
        self.assertTrue(os.path.exists(os.path.join(imgdir, cw.LOGOTIPO)))

    def test_las_ocho_paginas_en_los_dos_idiomas(self):
        en = {"GETTING-STARTED", "THE-GAME", "THE-CARTRIDGE", "THE-CODE",
              "FINDINGS", "IN-THE-EMULATOR", "OPEN-QUESTIONS", "THE-MSX2-PATCH"}
        es = {"EMPEZAR", "EL-JUEGO", "EL-CARTUCHO", "EL-CODIGO",
              "HALLAZGOS", "EN-EL-EMULADOR", "PREGUNTAS-ABIERTAS", "EL-PARCHE-MSX2"}
        for carpeta, nombres in (("docs", en), (os.path.join("docs", "es"), es)):
            hay = {fn[:-3] for fn in os.listdir(os.path.join(RAIZ, carpeta)) if fn.endswith(".md")}
            self.assertTrue(nombres <= hay, (carpeta, nombres - hay))


if __name__ == "__main__":
    unittest.main()

"""Las pantallas montadas desde la ROM.

Cada montaje (tools/pantallas.py) esta cotejado byte a byte contra un volcado
de VRAM de openMSX (tools/coteja.py): titulo, menu del titulo, SET-UP, equipo y partido
a 0 diferencias. Los volcados no viajan con el repositorio; lo que si viaja es
el sha256 de la VRAM montada, para que un cambio en los descompresores o en el
montaje salte aqui.
"""

import hashlib
import os
import sys
import unittest

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(RAIZ, "tools"))

ROM = os.path.join(RAIZ, "dunkshot.rom")


def rom():
    from graficos import Rom
    if os.path.exists(ROM):
        return Rom(ROM)
    from test_listado import lee
    r = Rom.__new__(Rom)
    r.d = lee()
    return r


def sha(datos):
    return hashlib.sha256(bytes(datos)).hexdigest()[:16]


class Pantallas(unittest.TestCase):
    def test_titulo(self):
        from pantallas import Maquina
        m = Maquina(rom()).titulo()
        self.assertEqual(sha(m.vram), "153b6800faa3907b")

    def test_menu_del_titulo(self):
        from pantallas import Maquina
        m = Maquina(rom()).menu_titulo()
        self.assertEqual(sha(m.vram), "e22d6d4b3cb65289")

    def test_setup(self):
        from pantallas import Maquina
        m = Maquina(rom()).setup()
        self.assertEqual(sha(m.vram), "5c55faba87d10931")

    def test_equipo(self):
        from pantallas import Maquina
        m = Maquina(rom()).equipo()
        self.assertEqual(sha(m.vram), "00fe1fd048f1062a")

    def test_load_data_error(self):
        from pantallas import Maquina
        m = Maquina(rom()).equipo_load_data(True)
        self.assertEqual(sha(m.vram), "e9fdcc61770cb47b")

    def test_partido(self):
        from pantallas import Maquina
        m = Maquina(rom()).partido(12)
        self.assertEqual(sha(m.vram), "a859a5210d1bc919")

    def test_la_pista_tiene_56_columnas(self):
        from pantallas import Maquina
        pix = Maquina(rom()).pista_completa(0, k=1)
        self.assertEqual((len(pix[0]), len(pix)), (56 * 8, 24 * 8))

    def test_las_tres_areas_cambian_los_colores(self):
        from graficos import des_5373
        r = rom()
        areas = [des_5373(r, a)[0] for a in (0xABA8, 0xACB0, 0xADB8)]
        self.assertEqual(len({bytes(a) for a in areas}), 3)


class Jugadores(unittest.TestCase):
    def test_una_pose_son_cuatro_sprites(self):
        from pantallas import Maquina
        m = Maquina(rom())
        for p in (0, 0x69, 0x98, 159):
            spr = m.pose(p)
            self.assertEqual(len(spr), 4)
            for pat, dy, dx in spr:
                self.assertLess(pat, 196)

    def test_las_poses_del_saque_inicial(self):
        """Lo que la RAM del partido decia al arrancar: poses 0x69 y 0x98,
        grupos 26 y 38 con los desplazamientos (26,10,35,19)."""
        from pantallas import Maquina
        m = Maquina(rom())
        self.assertEqual([dy for _, dy, _ in m.pose(0x69)], [26, 10, 35, 19])
        self.assertEqual([dy for _, dy, _ in m.pose(0x98)], [26, 10, 35, 19])


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Las imagenes de la web, todas desde la ROM con pantallas.py y graficos.py.

Ni una captura: cada pantalla se monta con las tablas del cartucho. Las que
tienen volcado de openMSX estan cotejadas byte a byte (tools/coteja.py).

Uso: imagenes.py <rom> <directorio>
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from graficos import (Rom, des_52cf, des_5331, des_5373, des_535b, PALETA,  # noqa: E402
                      lienzo, escala, pinta_patron, pinta_sprite16, png, hoja_sprites)
from pantallas import Maquina, NOMBRES                                      # noqa: E402


def guarda(ruta, pix):
    open(ruta, "wb").write(png(len(pix[0]), len(pix), pix))
    print("  %s %dx%d" % (os.path.basename(ruta), len(pix[0]), len(pix)))


def marco_del_rotulo(m):
    """Las filas de la tabla de nombres del titulo con el logotipo: desde la
    primera con algo que no sea espacio hasta la ultima antes de las lineas
    de la pista (0xF2/0xEC), medido sobre la tabla, no a ojo."""
    filas = [f for f in range(24)
             if any(m.vram[NOMBRES + f * 32 + c] not in (0x20,) for c in range(32))]
    f0 = filas[0]
    f1 = f0
    while f1 + 1 < 24 and all(m.vram[NOMBRES + (f1 + 1) * 32 + c] not in (0xF2, 0xEC) for c in range(32)):
        f1 += 1
    return f0, f1


def recorta(pix, x0, y0, ancho, alto):
    return [fila[x0:x0 + ancho] for fila in pix[y0:y0 + alto]]


def main():
    rom = Rom(sys.argv[1])
    out = sys.argv[2]
    os.makedirs(out, exist_ok=True)

    # El rotulo: las filas del logotipo de la pantalla de titulo
    m = Maquina(rom).titulo()
    f0, f1 = marco_del_rotulo(m)
    pix = m.dibuja(k=1)
    guarda(os.path.join(out, "rotulo.png"), escala(recorta(pix, 0, f0 * 8, 256, (f1 - f0 + 1) * 8), 2))

    # Las pantallas cotejadas
    guarda(os.path.join(out, "titulo.png"), Maquina(rom).titulo().dibuja())
    guarda(os.path.join(out, "menu_titulo.png"), Maquina(rom).menu_titulo().dibuja())
    guarda(os.path.join(out, "setup.png"), Maquina(rom).setup().dibuja())
    guarda(os.path.join(out, "partido.png"), Maquina(rom).partido(12).dibuja())
    guarda(os.path.join(out, "equipo.png"), Maquina(rom).equipo().dibuja())
    guarda(os.path.join(out, "cinta.png"), Maquina(rom).equipo_load_data(True).dibuja())

    # La pista entera, en sus tres colores
    for area in range(3):
        guarda(os.path.join(out, "pista_area%d.png" % (area + 1)), Maquina(rom).pista_completa(area))

    # Los jugadores: las 160 poses con una pareja piel/pelo y una camiseta de cada equipo
    guarda(os.path.join(out, "poses.png"), Maquina(rom).hoja_poses(0x0B, 0x01, 0x08))
    guarda(os.path.join(out, "poses_azul.png"), Maquina(rom).hoja_poses(0x01, 0x05, 0x05))

    # Las 32 parejas de piel y pelo (0x80E4) sobre la pose 0x69 del saque, con las dos camisetas
    m = Maquina(rom)
    pix = lienzo(32 * 24, 2 * 56, (40, 40, 40))
    for i in range(32):
        piel, pelo = rom[0x80E4 + 2 * i], rom[0x80E4 + 2 * i + 1]
        m.jugador(pix, i * 24 + 20, 52, 0x69, piel, pelo, 0x08)
        m.jugador(pix, i * 24 + 20, 108, 0x98, piel, pelo, 0x05)
    guarda(os.path.join(out, "colores_jugadores.png"), escala(pix, 2))

    # Los sprites fijos: la red (tres cuadros), el balon, su sombra y la flecha
    red = rom[0x9665:0x96C5]
    otros = rom[0x96C5:0x9725]
    pix = lienzo(6 * 20, 20, (40, 40, 40))
    for i in range(3):
        pinta_sprite16(pix, i * 20 + 2, 2, red[i * 32:i * 32 + 32], 0x0A)
    for i, color in enumerate((0x0A, 0x01, 0x08)):
        pinta_sprite16(pix, (3 + i) * 20 + 2, 2, otros[i * 32:i * 32 + 32], color)
    guarda(os.path.join(out, "sprites_fijos.png"), escala(pix, 4))

    # Los 196 patrones de sprite, tal cual
    spr = m.patrones_sprite()
    guarda(os.path.join(out, "patrones_sprite.png"), hoja_sprites(spr, 16, 15, 2))

    # Los 250 patrones de la pista con los colores del AREA 1, y los 80 del logotipo
    pista, _ = des_52cf(rom, 0xA74E)
    col, _ = des_5373(rom, 0xABA8)
    col2, _ = des_535b(rom, 0xAEC0)
    colores = bytearray(col[:2000])
    colores[0x100:0x100 + len(col2)] = col2
    pix = lienzo(16 * 8, 16 * 8, (40, 40, 40))
    for t in range(250):
        pinta_patron(pix, (t % 16) * 8, (t // 16) * 8, pista[t * 8:t * 8 + 8], colores[t * 8:t * 8 + 8])
    guarda(os.path.join(out, "tiles.png"), escala(pix, 3))
    pat, _ = des_52cf(rom, 0xB33E)
    colg, _ = des_52cf(rom, 0xB491)
    pix = lienzo(16 * 8, 5 * 8, (40, 40, 40))
    for i in range(80):
        pinta_patron(pix, (i % 16) * 8, (i // 16) * 8, pat[i * 8:i * 8 + 8], colg[i * 8:i * 8 + 8])
    guarda(os.path.join(out, "tiles_logo.png"), escala(pix, 3))

    # Lo que no se pinta nunca: los tiles 0x73, 0x85 y 0x86 de la pista y la
    # E y la S de "ESC" (0xFB, 0xFC) del logotipo; la C (0xFD) si sale en el titulo
    pix = lienzo(6 * 8, 8, (40, 40, 40))
    for i, t in enumerate((0x73, 0x85, 0x86)):
        pinta_patron(pix, i * 8, 0, pista[t * 8:t * 8 + 8], colores[t * 8:t * 8 + 8])
    for i, t in enumerate((0xFB, 0xFC, 0xFD)):
        k = t - 0xB0
        pinta_patron(pix, (3 + i) * 8, 0, pat[k * 8:k * 8 + 8], colg[k * 8:k * 8 + 8])
    guarda(os.path.join(out, "sin_uso.png"), escala(pix, 6))


if __name__ == "__main__":
    main()

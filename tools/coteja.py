#!/usr/bin/env python3
"""Coteja una pantalla montada desde la ROM (pantallas.py) contra un volcado
de VRAM de openMSX, byte a byte.

Se compara lo que se VE: la tabla de nombres de las filas pedidas; de cada
tercio, el patron y el color de los tiles que su tabla de nombres usa; y, si
se pide, los sprites que el VDP pinta (hasta el primer 0xD0) con sus patrones.
Lo que queda en la VRAM de pantallas anteriores y no se usa no cuenta.

Uso: coteja.py <montada.vram> <volcado.vram> [<volcado.regs>] [--sprites]
     [--filas a-b] [--png salida.png]
"""
import sys

from graficos import PALETA, lienzo, escala, pinta_patron, pinta_sprite16, png

PATRONES, NOMBRES, COLORES, SPRITES = 0x0000, 0x1800, 0x2000, 0x3800


def sat_de(regs):
    """La tabla de atributos de sprite que dice el registro 5."""
    return (regs[5] & 0x7F) * 0x80 if regs else 0x1B00


def diferencias(a, v, filas=range(24), sprites=False, sat=0x1B00):
    """Lista de (que, direccion, nuestro, volcado)."""
    out = []
    for f in filas:
        for c in range(32):
            d = NOMBRES + 32 * f + c
            if a[d] != v[d]:
                out.append(("nombre", d, a[d], v[d]))
    usados = {}
    for f in filas:
        for c in range(32):
            usados.setdefault(f // 8, set()).add(v[NOMBRES + 32 * f + c])
    for tercio, tiles in usados.items():
        for t in sorted(tiles):
            for base, que in ((PATRONES, "patron"), (COLORES, "color")):
                d = base + 0x800 * tercio + 8 * t
                for i in range(8):
                    if a[d + i] != v[d + i]:
                        out.append((que, d + i, a[d + i], v[d + i]))
    if sprites:
        for plano in range(32):
            d = sat + 4 * plano
            if v[d] == 0xD0:
                break
            for i in range(4):
                if a[d + i] != v[d + i]:
                    out.append(("sprite", d + i, a[d + i], v[d + i]))
            p = (v[d + 2] & 0xFC) * 8
            for i in range(32):
                if a[SPRITES + p + i] != v[SPRITES + p + i]:
                    out.append(("patron_sprite", SPRITES + p + i, a[SPRITES + p + i], v[SPRITES + p + i]))
    return out


def dibuja(vram, filas=range(24), sprites=False, sat=0x1B00, fondo=1, k=2):
    pix = lienzo(256, 192, PALETA[fondo])
    for f in filas:
        for c in range(32):
            n = vram[NOMBRES + f * 32 + c]
            tercio = (f // 8) * 0x800
            pat = vram[PATRONES + tercio + n * 8:PATRONES + tercio + n * 8 + 8]
            col = vram[COLORES + tercio + n * 8:COLORES + tercio + n * 8 + 8]
            pinta_patron(pix, c * 8, f * 8, pat, col)
    if sprites:
        for i in reversed(range(32)):
            y, x, p, cl = vram[sat + i * 4:sat + i * 4 + 4]
            if y == 0xD0 or y == 209:
                continue
            if any(vram[sat + j * 4] == 0xD0 for j in range(i)):
                continue
            pat = vram[SPRITES + (p & 0xFC) * 8:SPRITES + (p & 0xFC) * 8 + 32]
            pinta_sprite16(pix, x - (32 if cl & 0x80 else 0), (y + 1) & 0xFF, pat, cl & 15)
    return escala(pix, k)


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    a = open(args[0], "rb").read()
    v = open(args[1], "rb").read()
    regs = open(args[2], "rb").read() if len(args) > 2 and args[2].endswith(".regs") else None
    filas = range(24)
    if "--filas" in sys.argv:
        i, j = sys.argv[sys.argv.index("--filas") + 1].split("-")
        filas = range(int(i), int(j) + 1)
    sprites = "--sprites" in sys.argv
    sat = sat_de(regs)
    dif = diferencias(a, v, filas, sprites, sat)
    por = {}
    for que, d, x, y in dif:
        por.setdefault(que, []).append((d, x, y))
    print("%d diferencias" % len(dif), {k: len(w) for k, w in por.items()})
    for que, w in por.items():
        print("  %s: %s%s" % (que, " ".join("%04X(%02X/%02X)" % t for t in w[:12]), " ..." if len(w) > 12 else ""))
    if "--png" in sys.argv:
        salida = sys.argv[sys.argv.index("--png") + 1]
        fondo = (regs[7] & 15) if regs else 1
        open(salida, "wb").write(png(512, 384, dibuja(v, filas, sprites, sat, fondo)))
        print("volcado dibujado en", salida)
    return 1 if dif else 0


if __name__ == "__main__":
    sys.exit(main())

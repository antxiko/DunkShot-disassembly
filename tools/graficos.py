#!/usr/bin/env python3
"""Los formatos del cartucho, leidos desde la ROM con codigo nuestro.

Tres descompresores, portados instruccion a instruccion de las rutinas del
cartucho (las direcciones son las del listado):

  - des_52cf(): el de 0x52CF, el general. Cabecera de dos bytes (mascara,
    valor). Una ficha x es de control si (x & mascara) == valor; entonces
    a = x & ~mascara (>> 1 si la mascara es impar):
      a >= 2  -> el byte siguiente, repetido a+1 veces
      a == 0  -> el byte siguiente n es un indice: copia los 8 bytes que
                 estan en destino + n*8 (un diccionario sobre lo YA escrito);
                 n == 0xFF acaba
      a == 1  -> igual, pero con los bits de cada byte dados la vuelta
    Lo demas son literales.
  - des_5331(): el de 0x5331, solo repeticiones. Misma cabecera; una ficha
    de control seguida de si misma acaba; si no, el byte siguiente se repite
    a+3 veces.
  - des_535b(): el de 0x535B. Un byte que se salta, luego la marca c; c c
    acaba; c v n escribe v n veces (n = 0 -> 256).

Y lo que hace falta para dibujar: patrones de 8x8 (1 bit por pixel), colores
por fila de SCREEN 2 y sprites de 16x16 (32 bytes, la mitad izquierda y luego
la derecha).
"""
import struct
import sys
import zlib

ORG = 0x4000

PALETA = [(0, 0, 0), (0, 0, 0), (62, 184, 73), (116, 208, 125),
          (89, 85, 224), (128, 118, 241), (185, 94, 81), (101, 219, 239),
          (219, 101, 89), (255, 137, 125), (204, 195, 94), (222, 208, 135),
          (58, 162, 65), (183, 102, 181), (204, 204, 204), (255, 255, 255)]


class Rom:
    def __init__(self, ruta):
        self.d = open(ruta, "rb").read()
        assert len(self.d) == 32768, len(self.d)

    def __getitem__(self, a):
        if isinstance(a, slice):
            return self.d[a.start - ORG:a.stop - ORG]
        return self.d[a - ORG]

    def palabra(self, a):
        return self[a] | self[a + 1] << 8


def des_52cf(rom, src):
    """Devuelve (bytes descomprimidos, primera direccion despues del bloque)."""
    out = bytearray()
    hl = src
    masc, val = rom[hl], rom[hl + 1]
    hl += 2
    while True:
        x = rom[hl]
        hl += 1
        if (x & masc) != val:
            out.append(x)
            continue
        a = x & (~masc & 0xFF)
        if masc & 1:
            a >>= 1
        if a >= 2:
            out += bytes([rom[hl]]) * (a + 1)
            hl += 1
            continue
        n = rom[hl]
        hl += 1
        if a == 0 and n == 0xFF:
            return bytes(out), hl
        blk = bytes(out[n * 8:n * 8 + 8])
        assert len(blk) == 8, (hex(src), hex(hl), n, len(out))
        if a == 1:
            blk = bytes(int(format(v, "08b")[::-1], 2) for v in blk)
        out += blk


def des_5331(rom, src):
    out = bytearray()
    hl = src
    masc, val = rom[hl], rom[hl + 1]
    hl += 2
    while True:
        x = rom[hl]
        if (x & masc) != val:
            out.append(x)
            hl += 1
            continue
        if rom[hl + 1] == x:
            return bytes(out), hl + 2
        a = x & (~masc & 0xFF)
        if masc & 1:
            a >>= 1
        out += bytes([rom[hl + 1]]) * (a + 3)
        hl += 2


def des_535b(rom, src):
    out = bytearray()
    hl = src + 1
    c = rom[hl]
    hl += 1
    while True:
        a = rom[hl]
        if a != c:
            out.append(a)
            hl += 1
            continue
        if rom[hl + 1] == c:
            return bytes(out), hl + 2
        v, n = rom[hl + 1], rom[hl + 2]
        out += bytes([v]) * (n or 256)
        hl += 3


def des_5373(rom, src):
    """El de 0x5373, parejas de bytes repetidas (las tablas de color por AREA).

    Un byte a < 0x10 abre una cuenta: (a << 8 | siguiente) + 1 parejas, y
    luego vienen los dos bytes de la pareja; a == 0 con cuenta 0 acaba. Un
    byte a >= 0x10 es el byte alto de UNA pareja, y el siguiente el bajo.
    """
    out = bytearray()
    hl = src
    while True:
        a = rom[hl]
        if a < 0x10:
            n = (a << 8 | rom[hl + 1])
            hl += 2
            if n == 0:
                return bytes(out), hl
            n += 1
            a = rom[hl]
            hl += 1
        else:
            n = 1
            hl += 1
        out += bytes([a, rom[hl]]) * n
        hl += 1


# Los bloques comprimidos del cartucho: (origen, descompresor, destino en RAM,
# que es). Los finales los da el propio descompresor, y cada uno acaba justo
# donde empieza el siguiente.
BLOQUES = [
    (0x9725, des_52cf, 0xCC00, "patrones de sprite 0-63 de los jugadores"),
    (0x9B08, des_52cf, 0xD400, "patrones de sprite 64-127"),
    (0x9F80, des_52cf, 0xDC00, "patrones de sprite 128-191"),
    (0xA360, des_5331, 0xE400, "cuatro patrones de sprite a 0xE400"),
    (0xA74E, des_52cf, 0xC400, "los 250 patrones de la pista (-> VRAM 0x0000, x3)"),
    (0xABA8, des_5373, 0xC400, "colores de la pista, AREA 1 (-> VRAM 0x2000)"),
    (0xACB0, des_5373, 0xC400, "colores de la pista, AREA 2"),
    (0xADB8, des_5373, 0xC400, "colores de la pista, AREA 3"),
    (0xAEC0, des_535b, 0xC400, "colores de los patrones 0x20-0x73 (-> VRAM 0x2100)"),
    (0xAF5F, des_52cf, 0xEA89, "los ocho equipos (-> 0xEA89, 8 x 90)"),
    (0xB0FE, des_5331, 0xC400, "tabla de nombres del titulo (-> VRAM 0x1800, 17 filas)"),
    (0xB22A, des_5331, 0xC400, "tabla de nombres entera (-> VRAM 0x1800, 24 filas)"),
    (0xB33E, des_52cf, 0xC400, "patrones 0xB0-0xFF del logotipo (-> VRAM 0x0580, x3)"),
    (0xB491, des_52cf, 0xC400, "colores del logotipo (-> VRAM 0x2580, x3)"),
    (0xB69E, des_5331, 0xC400, "las gradas: 42 filas de 32 patrones"),
]


def descomprime(rom, src):
    for a, f, dst, _ in BLOQUES:
        if a == src:
            return f(rom, src)
    raise KeyError(hex(src))


# ------------------------------------------------------------------ dibujo

def png(ancho, alto, pix):
    """PNG RGB sin dependencias. pix: lista de filas de (r,g,b)."""
    raw = b"".join(b"\0" + bytes(c for p in fila for c in p) for fila in pix)

    def chunk(t, d):
        return (struct.pack(">I", len(d)) + t + d
                + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF))
    return (b"\x89PNG\r\n\x1a\n"
            + chunk(b"IHDR", struct.pack(">IIBBBBB", ancho, alto, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


def lienzo(ancho, alto, color=(0, 0, 0)):
    return [[color] * ancho for _ in range(alto)]


def escala(pix, k):
    return [[p for p in fila for _ in range(k)] for fila in pix for _ in range(k)]


def pinta_patron(pix, x0, y0, pat, col=None, tinta=15, papel=0):
    """Un patron de 8x8 (8 bytes). col: 8 bytes de color SCREEN 2 (tinta<<4|papel)."""
    for f in range(8):
        if col is not None:
            tinta, papel = col[f] >> 4, col[f] & 15
        b = pat[f]
        for c in range(8):
            v = tinta if b & (0x80 >> c) else papel
            if v:
                pix[y0 + f][x0 + c] = PALETA[v]


def pinta_sprite16(pix, x0, y0, pat, color):
    """Sprite de 16x16: 32 bytes, 16 de la mitad izquierda y 16 de la derecha."""
    for mitad in range(2):
        for f in range(16):
            b = pat[mitad * 16 + f]
            for c in range(8):
                if b & (0x80 >> c):
                    y, x = y0 + f, x0 + mitad * 8 + c
                    if 0 <= y < len(pix) and 0 <= x < len(pix[0]):
                        pix[y][x] = PALETA[color]


def hoja_patrones(datos, por_fila=16, col=None, k=3):
    """Todos los patrones de 8x8 de un bloque, en una rejilla."""
    n = len(datos) // 8
    filas = (n + por_fila - 1) // por_fila
    pix = lienzo(por_fila * 8, filas * 8, (40, 40, 40))
    for i in range(n):
        c = col[i * 8:i * 8 + 8] if col is not None and len(col) >= (i + 1) * 8 else None
        pinta_patron(pix, (i % por_fila) * 8, (i // por_fila) * 8, datos[i * 8:i * 8 + 8], c)
    return escala(pix, k)


def hoja_sprites(datos, por_fila=8, color=15, k=3):
    n = len(datos) // 32
    filas = (n + por_fila - 1) // por_fila
    pix = lienzo(por_fila * 16, filas * 16, (40, 40, 40))
    for i in range(n):
        pinta_sprite16(pix, (i % por_fila) * 16, (i // por_fila) * 16, datos[i * 32:i * 32 + 32], color)
    return escala(pix, k)


def guarda(ruta, pix):
    open(ruta, "wb").write(png(len(pix[0]), len(pix), pix))


if __name__ == "__main__":
    rom = Rom(sys.argv[1] if len(sys.argv) > 1 else "dunkshot.rom")
    for a, f, dst, que in BLOQUES:
        out, fin = f(rom, a)
        print("%04X-%04X (%4d B) -> %04X %5d B  %s" % (a, fin - 1, fin - a, dst, len(out), que))

#!/usr/bin/env python3
"""El parche MSX2 contra el parpadeo: en un MSX2 el juego pasa a SCREEN 4
(sprites en modo 2, OCHO por linea) en vez de SCREEN 2 (cuatro por linea).
El mismo fichero sigue valiendo en un MSX1, donde se comporta como el
original: dos tablas de atributos que se alternan cada cuadro.

Donde van las tablas. En el modo de sprites 2 del V9938 el registro 5 senala
un bloque de 1 KB (sus bits 0-2 van a 1 y el VDP los ignora): la primera
mitad del bloque es la tabla de colores de sprite (16 bytes por sprite, 512
en total) y en la segunda, a +0x200, estan los 128 bytes de atributos. Bajo
los 16 KB del MSX1 el juego solo deja libre 0x3C00-0x3FFF (los patrones de
sprite acaban en 0x3BBF), asi que: colores en 0x3C00-0x3DFF y atributos en
0x3E00-0x3E7F. No hay que mover nada.

El juego original alterna dos tablas, 0x1B00 y 0x1F00 (bit 2 del alto de
ATRBAS, 0xF929, que doblado es el registro 5). El parche las lleva a 0x3E00
y 0x3F00 (bit 0 del alto de ATRBAS: R5 = 0x7C o 0x7E); en un MSX2 el
registro 5 se escribe siempre a 0x7F, con lo que el VDP ensena 0x3E00 los
dos cuadros (la lista rotada de 0xE7B0, de la que salen los colores) y la
copia de 0x3F00 no la mira nadie.

Lo que cambia en el cartucho:

  0x5036  `jp INIGRP` -> `jp gancho_inigrp`: tras INIGRP, ATRBAS = 0x3E00 y
          R5 = 0x7C; si la BIOS es de MSX2 (byte 0x002D), ademas R0 = 4
          (M4: modo G3, SCREEN 4; el TMS9918 no tiene M4) y R5 = 0x7F.
  0x5B7B  `xor 4` -> `xor 1`: la alternancia entre 0x3E00 y 0x3F00.
  0x5B82  el WRTVDP de la alternancia pasa por `r5_segun_maquina`: en un
          MSX2 el registro 5 siempre a 0x7F.
  0x5B9B  `cp 0x1B` -> `cp 0x3E`: congela_sprites deja visible 0x3E00.
  0x5BE6, 0x5BF2  los dos volcados por cuadro, a 0x3E00 y 0x3F00; el segundo
          sigue en `vuelca_colores` (huerfano 0x7AAE): tras copiarlo, la
          tabla de colores de sprite (0x3C00) desde los colores de la lista
          de 0xE7B0 (`tabla_colores`, huerfano 0x6EA0; en un MSX1 vuelve sin
          hacer nada).
  0x5BFB, 0x7374, 0x8057  los fines de lista: 0xD0 (fin en el TMS9918) y
          0xD8 en la entrada siguiente (fin en el V9938): `fin_tabla`.
  0x5063, 0x804C, 0x80D5, 0x80DC  0x1B00/0x1B10 -> 0x3E00/0x3E10.
  0x80CE  el final de `viste_jugador` (la figura de muestra de los menus de
          equipo) salta a `colores_menu` (huerfano 0x6F30): lee los 8
          atributos de la VRAM y rellena sus colores con `tabla_colores`.

Uso: parche_msx2.py <dunkshot.rom> <salida.rom> <salida.ips> [<listado.asm>]
"""
import os
import subprocess
import sys
import tempfile

PASMO = os.environ.get("PASMO", "pasmo")
ORG = 0x4000

GANCHO_INIGRP = 0xBFD4      # 31 bytes (relleno a 0xFF hasta 0xBFFF)
R5_MAQUINA = 0xBFF3         # 11 bytes (hasta 0xBFFD)
TABLA_COLORES = 0x6EA0      # 41 bytes (huerfano 0x6EA0-0x6EDC)
FIN_TABLA = 0x6EC9          # 14 bytes (hasta 0x6ED6)
COLORES_MENU = 0x6F30       # 22 bytes (huerfano 0x6F30-0x6F47)
VUELCA_COLORES = 0x7AAE     # 9 bytes (huerfano 0x7AAE-0x7ABD)

SAT = 0x3E00                # atributos: 128 bytes (y la otra tabla del MSX1 en 0x3F00)
SAT2 = 0x3F00
COLORES = 0x3C00            # colores de sprite en modo 2: 512 bytes antes

ESCRIBE_VRAM = 0x5AF7
COPIA_A_VRAM = 0x5B07
LEE_DE_VRAM = 0x5B2A

TROZOS = {
    "gancho_inigrp": (GANCHO_INIGRP, """
    org 0x%04X
gancho_inigrp:
    call 0x0072          ; INIGRP: SCREEN 2 con la BIOS, como antes
    ld hl,0x%04X         ; ATRBAS: la tabla de atributos visible, 0x3E00
    ld (0xF928),hl
    ld a,(0x002D)        ; version del MSX: 0 = MSX1
    and a
    ld bc,0x7C05         ; R5 = 0x7C: atributos en 0x3E00 (TMS9918)
    jp z,0x0047          ; MSX1: WRTVDP y vuelve
    ld bc,0x0400         ; R0 = 0000 0100: M4 -> G3 (SCREEN 4)
    call 0x0047          ; WRTVDP, deja RG0SAV al dia
    ld bc,0x7F05         ; R5 = 0x7F: el bloque de 1 KB de 0x3C00, bits 0-2 a 1
    jp 0x0047
""" % (GANCHO_INIGRP, SAT)),
    "r5_segun_maquina": (R5_MAQUINA, """
    org 0x%04X
r5_segun_maquina:        ; B = 0x7C o 0x7E (la alternancia del MSX1), C = 5
    ld a,(0x002D)        ; version del MSX
    and a
    jr z,escribe         ; MSX1: tal cual
    ld b,0x7F            ; MSX2: siempre el mismo bloque, 0x3E00 a la vista
escribe:
    jp 0x0047            ; WRTVDP
""" % R5_MAQUINA),
    "tabla_colores": (TABLA_COLORES, """
    org 0x%04X
tabla_colores:           ; HL = el color del sprite 0 en una lista de atributos en RAM
    ld a,(0x002D)        ; version del MSX
    and a
    ret z                ; MSX1: no hay tabla de colores de sprite
    di
    push hl
    ld hl,0x%04X         ; la tabla de colores de sprite: la primera mitad del bloque de R5
    call 0x0053          ; SETWRT
    pop hl
    ld a,(0x0007)        ; el puerto de datos del VDP
    ld c,a
    ld d,32              ; los 32 sprites
bucle:
    ld a,(hl)            ; su color, con el bit 7 (EC) si lo lleva
    and 0x8F             ; sin los bits CC e IC del modo 2
    ld b,16
lineas:
    out (c),a            ; el mismo color en las 16 lineas
    djnz lineas
    inc hl
    inc hl
    inc hl
    inc hl               ; el siguiente atributo
    dec d
    jr nz,bucle
    ei
    ret
""" % (TABLA_COLORES, COLORES)),
    "fin_tabla": (FIN_TABLA, """
    org 0x%04X
fin_tabla:               ; HL = la entrada de atributos donde acaba la lista
    ld a,0xD0            ; Y = 208: fin de tabla en el TMS9918
    call 0x%04X          ; escribe_vram: A en la VRAM HL
    inc hl
    inc hl
    inc hl
    inc hl
    ld a,0xD8            ; Y = 216: fin de tabla en el V9938 (modo 2)
    jp 0x%04X
""" % (FIN_TABLA, ESCRIBE_VRAM, ESCRIBE_VRAM)),
    "colores_menu": (COLORES_MENU, """
    org 0x%04X
colores_menu:            ; el final de viste_jugador (0x80CE): su bucle y luego los colores
    dec b
    jp nz,0x80B8         ; los cuatro atributos de la figura
    ld hl,0x%04X         ; los 8 atributos de las dos figuras, de la VRAM
    ld de,0xE730         ; a la lista de la otra tabla (el partido la rehace)
    ld bc,0x0020
    call 0x%04X          ; lee_de_vram
    ld hl,0xE733         ; el color del sprite 0
    jp 0x%04X            ; tabla_colores
""" % (COLORES_MENU, SAT, LEE_DE_VRAM, TABLA_COLORES)),
    "vuelca_colores": (VUELCA_COLORES, """
    org 0x%04X
vuelca_colores:          ; el final de vuelca_sprites: la segunda copia y los colores
    call 0x%04X          ; copia_a_vram: 0xE730 a 0x3F00, como antes
    ld hl,0xE7B3         ; el color del sprite 0 de la lista rotada, la que se ve en MSX2
    jp 0x%04X            ; tabla_colores
""" % (VUELCA_COLORES, COPIA_A_VRAM, TABLA_COLORES)),
}

LIMITES = {GANCHO_INIGRP: R5_MAQUINA, R5_MAQUINA: 0xC000,
           TABLA_COLORES: FIN_TABLA, FIN_TABLA: 0x6EDD, COLORES_MENU: 0x6F48,
           VUELCA_COLORES: 0x7ABE}


def direccion(a):
    return bytes([a & 0xFF, a >> 8])


def salto(a):
    return b"\xC3" + direccion(a)


def llamada(a):
    return b"\xCD" + direccion(a)


# Parches de bytes sueltos: (direccion, bytes originales, bytes nuevos).
BYTES = [
    # jp INIGRP -> jp gancho_inigrp
    (0x5036, bytes.fromhex("c3 72 00"), salto(GANCHO_INIGRP)),
    # alterna_tabla_atributos: xor 4 (0x1B <-> 0x1F) -> xor 1 (0x3E <-> 0x3F)
    (0x5B7B, bytes.fromhex("ee 04"), bytes.fromhex("ee 01")),
    # ... y su WRTVDP pasa por r5_segun_maquina
    (0x5B82, bytes.fromhex("cd 47 00"), llamada(R5_MAQUINA)),
    # congela_sprites: la tabla que deja a la vista
    (0x5B9B, bytes.fromhex("fe 1b"), bytes([0xFE, SAT >> 8])),
    # vuelca_sprites: las dos copias, a 0x3E00 y 0x3F00, y el final en vuelca_colores
    (0x5BE6, bytes.fromhex("11 00 1b"), b"\x11" + direccion(SAT)),
    (0x5BF2, bytes.fromhex("11 00 1f"), b"\x11" + direccion(SAT2)),
    (0x5BF8, bytes.fromhex("c3 07 5b"), salto(VUELCA_COLORES)),
    # oculta_sprites: fin_tabla en 0x3E00 (0xD0 y 0xD8) y 0xD0 en 0x3F00
    (0x5BFB, bytes.fromhex("21 00 1b 3e d0 cd f7 5a 21 00 1f 3e d0 c3 f7 5a"),
     b"\x21" + direccion(SAT) + llamada(FIN_TABLA) + b"\x21" + direccion(SAT2)
     + bytes.fromhex("3e d0") + salto(ESCRIBE_VRAM) + bytes(2)),
    # ld a,0xD0 / ld hl,0x1B00 / call WRTVRM -> ld hl,0x3E00 / call fin_tabla
    (0x7374, bytes.fromhex("3e d0 21 00 1b cd 4d 00"),
     b"\x21" + direccion(SAT) + llamada(FIN_TABLA) + bytes(2)),
    (0x804C, bytes.fromhex("21 00 1b"), b"\x21" + direccion(SAT)),
    # ld a,0xD0 / jp escribe_vram -> jp fin_tabla
    (0x8057, bytes.fromhex("3e d0 c3 f7 5a"), salto(FIN_TABLA) + bytes(2)),
    (0x80D5, bytes.fromhex("21 00 1b"), b"\x21" + direccion(SAT)),
    (0x80DC, bytes.fromhex("21 10 1b"), b"\x21" + direccion(SAT + 0x10)),
    # la tabla limpia que dejo CLRSPR, ahora en ATRBAS = 0x3E00
    (0x5063, bytes.fromhex("21 00 1b"), b"\x21" + direccion(SAT)),
    # viste_jugador: djnz L_80B8 / ret -> jp colores_menu
    (0x80CE, bytes.fromhex("10 e8 c9"), salto(COLORES_MENU)),
]


def ensambla(nombre, org, fuente):
    with tempfile.TemporaryDirectory() as d:
        asm = os.path.join(d, nombre + ".asm")
        binario = os.path.join(d, nombre + ".bin")
        with open(asm, "w") as f:
            f.write(fuente)
        r = subprocess.run([PASMO, asm, binario], capture_output=True, text=True)
        if r.returncode:
            sys.exit("pasmo fallo en %s:\n%s%s" % (nombre, r.stdout, r.stderr))
        with open(binario, "rb") as f:
            return f.read()


def ips(original, nuevo):
    """Un IPS con un registro por tramo que cambia."""
    out = bytearray(b"PATCH")
    for i, j in tramos(original, nuevo):
        out += i.to_bytes(3, "big") + (j - i).to_bytes(2, "big") + nuevo[i:j]
    out += b"EOF"
    return bytes(out)


def aplica(rom):
    nuevo = bytearray(rom)
    for a, viejos, nuevos in BYTES:
        o = a - ORG
        assert bytes(nuevo[o:o + len(viejos)]) == viejos, "0x%04X no es lo esperado: %s" % (a, nuevo[o:o + len(viejos)].hex())
        assert len(nuevos) == len(viejos), hex(a)
        nuevo[o:o + len(nuevos)] = nuevos
    for nombre, (org, fuente) in TROZOS.items():
        codigo = ensambla(nombre, org, fuente)
        assert org + len(codigo) <= LIMITES[org], "%s no cabe: %d bytes" % (nombre, len(codigo))
        o = org - ORG
        nuevo[o:o + len(codigo)] = codigo
    return bytes(nuevo)


def tramos(a, b):
    i = 0
    while i < len(a):
        if a[i] == b[i]:
            i += 1
            continue
        j = i
        while j < len(a) and a[j] != b[j]:
            j += 1
        yield i, j
        i = j


def listado():
    return "\n".join("; ---- %s ----%s" % (n, f) for n, (_, f) in TROZOS.items())


def main():
    rom = open(sys.argv[1], "rb").read()
    assert len(rom) == 32768
    nuevo = aplica(rom)
    open(sys.argv[2], "wb").write(nuevo)
    open(sys.argv[3], "wb").write(ips(rom, nuevo))
    if len(sys.argv) > 4:
        open(sys.argv[4], "w").write(listado())
    cambios = list(tramos(rom, nuevo))
    print("%d tramos cambiados, %d bytes:" % (len(cambios), sum(j - i for i, j in cambios)))
    for i, j in cambios:
        print("  (0x%04X, 0x%04X)," % (i + ORG, j + ORG - 1))


if __name__ == "__main__":
    main()

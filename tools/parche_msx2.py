#!/usr/bin/env python3
"""El parche MSX2 contra el parpadeo: en un MSX2 el juego pasa a SCREEN 4
(sprites en modo 2, OCHO por linea) en vez de SCREEN 2 (cuatro por linea).
El mismo fichero sigue valiendo en un MSX1.

Por que hace falta mover tablas. En el modo de sprites 2 del V9938 la tabla
de atributos tiene que estar en un multiplo de 1 KB (los bits 0-2 de R5 van
a 1 y el VDP los ignora) y la tabla de colores de sprite, 16 bytes por
sprite, va 512 bytes antes. Bajo los 16 KB del MSX1 solo queda un sitio sin
pisar las tablas del juego: atributos en 0x3C00 y colores en 0x3A00-0x3BFF.
Ahi estaban los patrones de sprite de los jugadores 4 y 5 (0x3A00-0x3AFF) y
los de la red, el balon, la sombra y la flecha (0x3B00-0x3BBF): se mueven
0x280 bytes arriba (0x3C80-0x3E3F) y sus numeros de patron suben 0x50.

Lo que cambia en el cartucho:

  0x5036  `jp INIGRP` -> `jp gancho_inigrp`: tras INIGRP, si la BIOS es de
          MSX2 (byte 0x002D), R0 = 4 (M4: modo G3, SCREEN 4). En un MSX1 no
          se toca (el TMS9918 no tiene M4 y pondria SCREEN 1).
  0x5B7A  0x5B77 alternaba ATRBAS entre 0x1B00 y 0x1F00 y escribia R5 (el
          reparto del parpadeo); ahora ATRBAS = 0x3C00 y R5 = 0x78, que
          `r5_segun_maquina` sube a 0x7F en un MSX2 (bits 0-2 a 1).
  0x5BE3  un volcado por cuadro (0xE7B0 -> 0x3C00) en vez de dos, y la tabla
          de colores de sprite (0x3A00) desde los colores de los atributos
          (`tabla_colores`, en el hueco de codigo huerfano de 0x6EA0). En un
          MSX1 esa tabla no la mira nadie.
  0x5BFB, 0x7374, 0x8057  los fines de lista: 0xD0 (fin en el TMS9918) y
          0xD8 en la entrada siguiente (fin en el V9938): `fin_tabla`.
  0x804C, 0x80D5, 0x80DC  0x1B00/0x1B10 -> 0x3C00/0x3C10.
  0x5FF7  `sube_patrones_pose`: a los huecos de patron de los jugadores 4 y 5
          se les suma 0x280 (`hueco_patron`).
  0x51C0  los numeros de patron de los 24 sprites de jugador: 0x00-0x3C y
          luego 0x90-0xAC (`numeros_patron`); 0x51CF 0x6C -> 0xBC (balon).
  0x504B, 0x5057  la red a 0x3D80 y el balon a 0x3DE0.
  0x43AA  los tres cuadros de la red: 0x60 0x64 0x68 -> 0xB0 0xB4 0xB8.

Lo que no cambia: 0x5063 sigue leyendo en 0x1B00 lo que CLRSPR dejo alli.
Lo que se pierde en MSX2 (no en MSX1): la figura de muestra de los menus de
equipo escribe su color en el atributo, que el modo 2 no mira; sale con el
color que tuviera ese sprite en la tabla de colores.

Uso: parche_msx2.py <dunkshot.rom> <salida.rom> <salida.ips> [<listado.asm>]
"""
import os
import subprocess
import sys
import tempfile

PASMO = os.environ.get("PASMO", "pasmo")
ORG = 0x4000

GANCHO_INIGRP = 0xBFD4      # 15 bytes
FIN_TABLA = 0xBFE3          # 14 bytes
R5_MAQUINA = 0xBFF1         # 11 bytes (hasta 0xBFFB)
TABLA_COLORES = 0x6EA0      # 32 bytes (huerfano 0x6EA0-0x6EDC)
HUECO_PATRON = 0x7AAE       # 13 bytes (huerfano 0x7AAE-0x7ABD)
NUMEROS_PATRON = 0x6F30     # 19 bytes (huerfano 0x6F30-0x6F47)

TROZOS = {
    "gancho_inigrp": (GANCHO_INIGRP, """
    org 0x%04X
gancho_inigrp:
    call 0x0072          ; INIGRP: SCREEN 2 con la BIOS, como antes
    ld a,(0x002D)        ; version del MSX: 0 = MSX1
    and a
    ret z                ; en un MSX1 no hay mas
    ld bc,0x0400         ; R0 = 0000 0100: M4 -> G3 (SCREEN 4)
    call 0x0047          ; WRTVDP, deja RG0SAV al dia
    ret
""" % GANCHO_INIGRP),
    "fin_tabla": (FIN_TABLA, """
    org 0x%04X
fin_tabla:
    ld a,0xD0            ; Y = 208: fin de tabla en el TMS9918
    call 0x5AF7          ; escribe_vram: A en la VRAM HL
    inc hl
    inc hl
    inc hl
    inc hl
    ld a,0xD8            ; Y = 216: fin de tabla en el V9938 (modo 2)
    jp 0x5AF7
""" % FIN_TABLA),
    "r5_segun_maquina": (R5_MAQUINA, """
    org 0x%04X
r5_segun_maquina:
    ld a,(0x002D)        ; version del MSX
    and a
    jr z,escribe         ; MSX1: R5 = 0x78 (0x3C00 >> 7)
    ld b,0x7F            ; MSX2: los bits 0-2 a 1, como pide el modo 2
escribe:
    jp 0x0047            ; WRTVDP con B = dato, C = 5
""" % R5_MAQUINA),
    "tabla_colores": (TABLA_COLORES, """
    org 0x%04X
tabla_colores:
    di
    ld hl,0x3A00         ; la tabla de colores de sprite: 512 bytes antes de la de atributos
    call 0x0053          ; SETWRT
    ld hl,0xE7B3         ; el color del sprite 0 en la lista de este cuadro
    ld a,(0x0007)        ; el puerto de datos del VDP
    ld c,a
    ld d,32              ; los 32 sprites
bucle:
    ld a,(hl)            ; su color, con el bit 7 (EC) si lo lleva
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
""" % TABLA_COLORES),
    "hueco_patron": (HUECO_PATRON, """
    org 0x%04X
hueco_patron:
    ld de,0x3800         ; HL = jugador * 128
    add hl,de            ; su hueco de patrones
    ld a,h
    cp 0x3A              ; jugadores 0-3: 0x3800-0x39FF, se quedan
    ret c
    ld de,0x280          ; jugadores 4 y 5: 0x3C80 y 0x3D00
    add hl,de
    ret
""" % HUECO_PATRON),
    "numeros_patron": (NUMEROS_PATRON, """
    org 0x%04X
numeros_patron:
    ld de,4              ; cuatro bytes por atributo
    xor a                ; patron 0
    ld b,24              ; los 24 sprites de jugador
bucle:
    ld (hl),a
    add hl,de
    add a,4              ; el siguiente patron de 16x16
    cp 0x40              ; el 17 (jugador 4) empieza en 0x90, no en 0x40
    jr nz,sigue
    add a,0x50
sigue:
    djnz bucle
    ret                  ; A = 0xB0: la red
""" % NUMEROS_PATRON),
}

# Parches de bytes sueltos: (direccion, bytes originales, bytes nuevos).
BYTES = [
    (0x5036, bytes.fromhex("c3 72 00"), bytes([0xC3, GANCHO_INIGRP & 0xFF, GANCHO_INIGRP >> 8])),
    (0x5B7A, bytes.fromhex("7e ee 04 77 17 47 0e 05 cd 47 00"),
     bytes.fromhex("3e 3c 77 3e 78 47 0e 05") + bytes([0xCD, R5_MAQUINA & 0xFF, R5_MAQUINA >> 8])),
    (0x5BE3, bytes.fromhex("01 80 00 11 00 1b 21 b0 e7 cd 07 5b 01 80 00 11 00 1f 21 30 e7 c3 07 5b"),
     bytes.fromhex("01 80 00 11 00 3c 21 b0 e7 cd 07 5b")
     + bytes([0xC3, TABLA_COLORES & 0xFF, TABLA_COLORES >> 8]) + bytes(9)),
    (0x5BFB, bytes.fromhex("21 00 1b 3e d0 cd f7 5a 21 00 1f 3e d0 c3 f7 5a"),
     bytes.fromhex("21 00 3c 3e d0 cd f7 5a 21 04 3c 3e d8 c3 f7 5a")),
    (0x7374, bytes.fromhex("3e d0 21 00 1b cd 4d 00"),
     bytes.fromhex("21 00 3c") + bytes([0xCD, FIN_TABLA & 0xFF, FIN_TABLA >> 8, 0, 0])),
    (0x804C, bytes.fromhex("21 00 1b"), bytes.fromhex("21 00 3c")),
    (0x8057, bytes.fromhex("3e d0 c3 f7 5a"), bytes([0xC3, FIN_TABLA & 0xFF, FIN_TABLA >> 8, 0, 0])),
    (0x80D5, bytes.fromhex("21 00 1b"), bytes.fromhex("21 00 3c")),
    (0x80DC, bytes.fromhex("21 10 1b"), bytes.fromhex("21 10 3c")),
    (0x5FF7, bytes.fromhex("11 00 38 19"), bytes([0xCD, HUECO_PATRON & 0xFF, HUECO_PATRON >> 8, 0])),
    (0x51C0, bytes.fromhex("11 04 00 af 06 18 77 19 c6 04 10 fa"),
     bytes([0xCD, NUMEROS_PATRON & 0xFF, NUMEROS_PATRON >> 8]) + bytes(9)),
    (0x51CE, bytes.fromhex("3e 6c"), bytes.fromhex("3e bc")),
    (0x504B, bytes.fromhex("11 00 3b"), bytes.fromhex("11 80 3d")),
    (0x5057, bytes.fromhex("11 60 3b"), bytes.fromhex("11 e0 3d")),
    (0x43AA, bytes.fromhex("60 64 68 64 60"), bytes.fromhex("b0 b4 b8 b4 b0")),
]


def ensambla(nombre, org, fuente):
    with tempfile.TemporaryDirectory() as d:
        asm = os.path.join(d, nombre + ".asm")
        binario = os.path.join(d, nombre + ".bin")
        open(asm, "w").write(fuente)
        r = subprocess.run([PASMO, asm, binario], capture_output=True, text=True)
        if r.returncode:
            sys.exit("pasmo fallo en %s:\n%s%s" % (nombre, r.stdout, r.stderr))
        return open(binario, "rb").read()


def ips(original, nuevo):
    """Un IPS con un registro por tramo que cambia."""
    out = bytearray(b"PATCH")
    for i, j in tramos(original, nuevo):
        out += i.to_bytes(3, "big") + (j - i).to_bytes(2, "big") + nuevo[i:j]
    out += b"EOF"
    return bytes(out)


LIMITES = {GANCHO_INIGRP: 0xBFE3, FIN_TABLA: 0xBFF1, R5_MAQUINA: 0xC000,
           TABLA_COLORES: 0x6EDD, HUECO_PATRON: 0x7ABE, NUMEROS_PATRON: 0x6F48}


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

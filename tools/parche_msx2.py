#!/usr/bin/env python3
"""El parche MSX2 contra el parpadeo: en un MSX2 el juego pasa a SCREEN 4
(sprites en modo 2, OCHO por linea) en vez de SCREEN 2 (cuatro por linea).
El mismo fichero sigue valiendo en un MSX1, donde se comporta como el
original: dos tablas de atributos que se alternan cada cuadro.

Sirve para las DOS ROM de Dunk Shot que circulan:

  "1"  la primera (GoodMSX [!], sha256 a1891e03...)
  "a"  la corregida (GoodMSX [a], sha256 a9e759ae...): casi todo el programa
       esta en otro sitio y la RAM de trabajo se reparte de otra manera

La herramienta mira la huella de la ROM y aplica la tabla de direcciones de
la que toca; el codigo que se inyecta es el mismo.

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
dos cuadros (la lista rotada, de la que salen los colores) y la copia de
0x3F00 no la mira nadie.

Lo que cambia en el cartucho (direcciones de la ROM "1"; la "a" tiene las
mismas piezas en otras direcciones, ver DIRECCIONES):

  jp INIGRP -> jp gancho_inigrp: tras INIGRP, ATRBAS = 0x3E00 y R5 = 0x7C; si
          la BIOS es de MSX2 (byte 0x002D), ademas R0 = 4 (M4: modo G3,
          SCREEN 4; el TMS9918 no tiene M4) y R5 = 0x7F.
  xor 4 -> xor 1 en la alternancia entre 0x3E00 y 0x3F00.
  El WRTVDP de la alternancia pasa por `r5_segun_maquina`: en un MSX2 el
          registro 5 siempre a 0x7F.
  cp 0x1B -> cp 0x3E: congela_sprites deja visible 0x3E00.
  Los dos volcados por cuadro, a 0x3E00 y 0x3F00; el segundo sigue en
          `vuelca_colores`: tras copiarlo, la tabla de colores de sprite
          (0x3C00) desde los colores de la lista rotada (`tabla_colores`; en
          un MSX1 vuelve sin hacer nada).
  Los fines de lista: 0xD0 (fin en el TMS9918) y 0xD8 en la entrada siguiente
          (fin en el V9938): `fin_tabla`.
  0x1B00/0x1B10 -> 0x3E00/0x3E10 en los sitios que escriben la tabla visible.
  El final de `viste_jugador` (la figura de muestra de los menus de equipo)
          salta a `colores_menu`: lee los 8 atributos de la VRAM y rellena
          sus colores con `tabla_colores`.

El codigo nuevo cae en rutinas HUERFANAS (nadie las llama ni las nombra) y en
el relleno del final de la ROM "1".

Uso: parche_msx2.py <dunkshot.rom> <salida.rom> <salida.ips> [<listado.asm>]
"""
import hashlib
import os
import subprocess
import sys
import tempfile

PASMO = os.environ.get("PASMO", "pasmo")
ORG = 0x4000

SAT = 0x3E00                # atributos: 128 bytes (y la otra tabla del MSX1 en 0x3F00)
SAT2 = 0x3F00
COLORES = 0x3C00            # colores de sprite en modo 2: 512 bytes antes

# sha256 de cada ROM -> version
HUELLAS = {
    "a1891e038566596a9f67067b8ea4694709aa9fee93c8ac0379360b30ea3abe62": "1",
    "a9e759aeb5c94c3060095d4e50c8170b80ab08df95d8a5666a29badf0a912adf": "a",
}

# Todas las direcciones que cambian de una ROM a otra.
DIRECCIONES = {
    "1": dict(
        # donde cae el codigo inyectado (y hasta donde puede llegar)
        gancho_inigrp=(0xBFD4, 0xBFF3), r5_segun_maquina=(0xBFF3, 0xC000),
        tabla_colores=(0x6EA0, 0x6EC9), fin_tabla=(0x6EC9, 0x6EDD),
        colores_menu=(0x6F30, 0x6F48), vuelca_colores=(0x7AAE, 0x7ABE),
        # rutinas del juego que el codigo inyectado llama
        escribe_vram=0x5AF7, copia_a_vram=0x5B07, lee_de_vram=0x5B2A,
        # RAM: lista de atributos de la otra tabla, y el color del sprite 0 de cada lista
        lista_2=0xE730, lista_1=0xE7B0,
        bucle_menu=0x80B8,
        # sitios del cartucho que se tocan
        jp_inigrp=0x5036, xor_alterna=0x5B7B, wrtvdp_alterna=0x5B82, cp_congela=0x5B9B,
        volcado_1=0x5BE6, volcado_2=0x5BF2, final_volcado=0x5BF8, oculta=0x5BFB,
        fin_lista_tabla=0x7374, ld_804c=0x804C, fin_lista_jugador=0x8057,
        ld_80d5=0x80D5, ld_80dc=0x80DC, ld_clrspr=0x5063, fin_viste=0x80CE,
    ),
    "a": dict(
        gancho_inigrp=(0x4D92, 0x4DB3), r5_segun_maquina=(0x7E91, 0x7EA3),
        tabla_colores=(0x5D65, 0x5D8E), fin_tabla=(0x6DFE, 0x6E0E),
        colores_menu=(0x5C50, 0x5C68), vuelca_colores=(0x5D8E, 0x5D97),
        escribe_vram=0x6122, copia_a_vram=0x6132, lee_de_vram=0x6155,
        lista_2=0xEBE5, lista_1=0xEC65,
        bucle_menu=0x740D,
        jp_inigrp=0x5DB0, xor_alterna=0x61A6, wrtvdp_alterna=0x61AD, cp_congela=0x61C6,
        volcado_1=0x6211, volcado_2=0x621D, final_volcado=0x6223, oculta=0x6226,
        fin_lista_tabla=0x87F3, ld_804c=0x73A1, fin_lista_jugador=0x73AC,
        ld_80d5=0x742A, ld_80dc=0x7431, ld_clrspr=0x5DDD, fin_viste=0x7423,
    ),
}

PLANTILLAS = {
    "gancho_inigrp": """
    org 0x{org:04X}
gancho_inigrp:
    call 0x0072          ; INIGRP: SCREEN 2 con la BIOS, como antes
    ld hl,0x{SAT:04X}         ; ATRBAS: la tabla de atributos visible, 0x3E00
    ld (0xF928),hl
    ld a,(0x002D)        ; version del MSX: 0 = MSX1
    and a
    ld bc,0x7C05         ; R5 = 0x7C: atributos en 0x3E00 (TMS9918)
    jp z,0x0047          ; MSX1: WRTVDP y vuelve
    ld bc,0x0400         ; R0 = 0000 0100: M4 -> G3 (SCREEN 4)
    call 0x0047          ; WRTVDP, deja RG0SAV al dia
    ld bc,0x7F05         ; R5 = 0x7F: el bloque de 1 KB de 0x3C00, bits 0-2 a 1
    jp 0x0047
""",
    "r5_segun_maquina": """
    org 0x{org:04X}
r5_segun_maquina:        ; B = 0x7C o 0x7E (la alternancia del MSX1), C = 5
    ld a,(0x002D)        ; version del MSX
    and a
    jr z,escribe         ; MSX1: tal cual
    ld b,0x7F            ; MSX2: siempre el mismo bloque, 0x3E00 a la vista
escribe:
    jp 0x0047            ; WRTVDP
""",
    "tabla_colores": """
    org 0x{org:04X}
tabla_colores:           ; HL = el color del sprite 0 en una lista de atributos en RAM
    ld a,(0x002D)        ; version del MSX
    and a
    ret z                ; MSX1: no hay tabla de colores de sprite
    di
    push hl
    ld hl,0x{COLORES:04X}         ; la tabla de colores de sprite: la primera mitad del bloque de R5
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
""",
    "fin_tabla": """
    org 0x{org:04X}
fin_tabla:               ; HL = la entrada de atributos donde acaba la lista
    ld a,0xD0            ; Y = 208: fin de tabla en el TMS9918
    call 0x{escribe_vram:04X}          ; escribe_vram: A en la VRAM HL
    inc hl
    inc hl
    inc hl
    inc hl
    ld a,0xD8            ; Y = 216: fin de tabla en el V9938 (modo 2)
    jp 0x{escribe_vram:04X}
""",
    "colores_menu": """
    org 0x{org:04X}
colores_menu:            ; el final de viste_jugador: su bucle y luego los colores
    dec b
    jp nz,0x{bucle_menu:04X}         ; los cuatro atributos de la figura
    ld hl,0x{SAT:04X}         ; los 8 atributos de las dos figuras, de la VRAM
    ld de,0x{lista_2:04X}         ; a la lista de la otra tabla (el partido la rehace)
    ld bc,0x0020
    call 0x{lee_de_vram:04X}          ; lee_de_vram
    ld hl,0x{lista_2_c:04X}         ; el color del sprite 0
    jp 0x{tabla_colores:04X}            ; tabla_colores
""",
    "vuelca_colores": """
    org 0x{org:04X}
vuelca_colores:          ; el final de vuelca_sprites: la segunda copia y los colores
    call 0x{copia_a_vram:04X}          ; copia_a_vram: la lista a 0x3F00, como antes
    ld hl,0x{lista_1_c:04X}         ; el color del sprite 0 de la lista rotada, la que se ve en MSX2
    jp 0x{tabla_colores:04X}            ; tabla_colores
""",
}
ORDEN = ["gancho_inigrp", "r5_segun_maquina", "tabla_colores", "fin_tabla",
         "colores_menu", "vuelca_colores"]


def direccion(a):
    return bytes([a & 0xFF, a >> 8])


def salto(a):
    return b"\xC3" + direccion(a)


def llamada(a):
    return b"\xCD" + direccion(a)


def version_de(rom):
    h = hashlib.sha256(rom).hexdigest()
    if h not in HUELLAS:
        sys.exit("Esta ROM no es ninguna de las dos conocidas (sha256 %s)" % h)
    return HUELLAS[h]


def valores(v):
    """Las direcciones de la version v, con las derivadas."""
    d = dict(DIRECCIONES[v])
    d["SAT"], d["SAT2"], d["COLORES"] = SAT, SAT2, COLORES
    d["lista_2_c"] = d["lista_2"] + 3       # color del sprite 0 de la lista
    d["lista_1_c"] = d["lista_1"] + 3
    d["tabla_colores"] = d["tabla_colores"][0]
    return d


def trozos(v):
    """{nombre: (org, tope, fuente)} del codigo que se inyecta."""
    d = valores(v)
    out = {}
    for nombre in ORDEN:
        org, tope = DIRECCIONES[v][nombre]
        out[nombre] = (org, tope, PLANTILLAS[nombre].format(org=org, **d))
    return out


def bytes_sueltos(v):
    """Parches de bytes sueltos: (direccion, bytes originales, bytes nuevos)."""
    d = valores(v)
    gancho = DIRECCIONES[v]["gancho_inigrp"][0]
    r5 = DIRECCIONES[v]["r5_segun_maquina"][0]
    fin_tabla = DIRECCIONES[v]["fin_tabla"][0]
    vuelca = DIRECCIONES[v]["vuelca_colores"][0]
    menu = DIRECCIONES[v]["colores_menu"][0]
    esc, cop = d["escribe_vram"], d["copia_a_vram"]
    return [
        # jp INIGRP -> jp gancho_inigrp
        (d["jp_inigrp"], bytes.fromhex("c3 72 00"), salto(gancho)),
        # la alternancia de tablas: xor 4 (0x1B <-> 0x1F) -> xor 1 (0x3E <-> 0x3F)
        (d["xor_alterna"], bytes.fromhex("ee 04"), bytes.fromhex("ee 01")),
        # ... y su WRTVDP pasa por r5_segun_maquina
        (d["wrtvdp_alterna"], bytes.fromhex("cd 47 00"), llamada(r5)),
        # congela_sprites: la tabla que deja a la vista
        (d["cp_congela"], bytes.fromhex("fe 1b"), bytes([0xFE, SAT >> 8])),
        # vuelca_sprites: las dos copias, a 0x3E00 y 0x3F00, y el final en vuelca_colores
        (d["volcado_1"], bytes.fromhex("11 00 1b"), b"\x11" + direccion(SAT)),
        (d["volcado_2"], bytes.fromhex("11 00 1f"), b"\x11" + direccion(SAT2)),
        (d["final_volcado"], b"\xC3" + direccion(cop), salto(vuelca)),
        # oculta_sprites: fin_tabla en 0x3E00 (0xD0 y 0xD8) y 0xD0 en 0x3F00
        (d["oculta"], bytes.fromhex("21 00 1b 3e d0") + llamada(esc)
         + bytes.fromhex("21 00 1f 3e d0") + salto(esc),
         b"\x21" + direccion(SAT) + llamada(fin_tabla) + b"\x21" + direccion(SAT2)
         + bytes.fromhex("3e d0") + salto(esc) + bytes(2)),
        # ld a,0xD0 / ld hl,0x1B00 / call WRTVRM -> ld hl,0x3E00 / call fin_tabla
        (d["fin_lista_tabla"], bytes.fromhex("3e d0 21 00 1b cd 4d 00"),
         b"\x21" + direccion(SAT) + llamada(fin_tabla) + bytes(2)),
        (d["ld_804c"], bytes.fromhex("21 00 1b"), b"\x21" + direccion(SAT)),
        # ld a,0xD0 / jp escribe_vram -> jp fin_tabla
        (d["fin_lista_jugador"], b"\x3E\xD0" + salto(esc), salto(fin_tabla) + bytes(2)),
        (d["ld_80d5"], bytes.fromhex("21 00 1b"), b"\x21" + direccion(SAT)),
        (d["ld_80dc"], bytes.fromhex("21 10 1b"), b"\x21" + direccion(SAT + 0x10)),
        # la tabla limpia que dejo CLRSPR, ahora en ATRBAS = 0x3E00
        (d["ld_clrspr"], bytes.fromhex("21 00 1b"), b"\x21" + direccion(SAT)),
        # viste_jugador: djnz bucle / ret -> jp colores_menu
        (d["fin_viste"], b"\x10" + bytes([(d["bucle_menu"] - (d["fin_viste"] + 2)) & 0xFF]) + b"\xC9",
         salto(menu)),
    ]


def ensambla(nombre, fuente):
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


def aplica(rom, v=None):
    v = v or version_de(rom)
    nuevo = bytearray(rom)
    for a, viejos, nuevos in bytes_sueltos(v):
        o = a - ORG
        assert bytes(nuevo[o:o + len(viejos)]) == viejos, "0x%04X no es lo esperado: %s" % (a, nuevo[o:o + len(viejos)].hex())
        assert len(nuevos) == len(viejos), hex(a)
        nuevo[o:o + len(nuevos)] = nuevos
    for nombre, (org, tope, fuente) in trozos(v).items():
        codigo = ensambla(nombre, fuente)
        assert org + len(codigo) <= tope, "%s no cabe: %d bytes" % (nombre, len(codigo))
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


def listado(v):
    return "\n".join("; ---- %s ----%s" % (n, f) for n, (_, _, f) in trozos(v).items())


def main():
    rom = open(sys.argv[1], "rb").read()
    assert len(rom) == 32768
    v = version_de(rom)
    nuevo = aplica(rom, v)
    open(sys.argv[2], "wb").write(nuevo)
    open(sys.argv[3], "wb").write(ips(rom, nuevo))
    if len(sys.argv) > 4:
        open(sys.argv[4], "w").write(listado(v))
    cambios = list(tramos(rom, nuevo))
    print("ROM \"%s\": %d tramos cambiados, %d bytes:" % (v, len(cambios), sum(j - i for i, j in cambios)))
    for i, j in cambios:
        print("  (0x%04X, 0x%04X)," % (i + ORG, j + ORG - 1))


if __name__ == "__main__":
    main()

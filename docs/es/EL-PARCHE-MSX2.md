# El parche MSX2

Dunk Shot parpadea porque cada jugador son cuatro sprites apilados y el
TMS9918 no pinta más de cuatro por línea: el juego los reparte a propósito,
rotando siete grupos cada cuadro entre dos tablas de atributos ([El
código](EL-CODIGO.md#los-sprites-y-el-parpadeo)). El V9938 del MSX2 pinta
ocho por línea, así que el mismo cartucho puede dejar de repartirlos.
`parche/dunkshot_msx2.ips` es un parche IPS de 292 bytes que hace eso: 164
bytes cambiados en 24 tramos, y el resultado sigue jugándose en un MSX1 como
el original.

## Medido, antes y después

La sonda `tools/omsx_parpadeo.tcl` lee, cada cuadro, la tabla de atributos
que el VDP está enseñando y cuenta, línea a línea, los sprites que pasan del
límite del VDP (cuatro en el TMS9918, ocho en el V9938 en modo de sprites 2):
esos son los que no se pintan. Treinta segundos de un partido arrancado con
el espacio desde el título; la máquina lleva los dos equipos, así que no hay
dos partidos iguales.

| cartucho | máquina | cuadros | sprites sin pintar, por cuadro | peor cuadro |
|---|---|---|---|---|
| original | C-BIOS_MSX1_JP (MSX1, 60 Hz) | 1.798 | 66,7 | 166 |
| parcheado | C-BIOS_MSX1_JP (MSX1, 60 Hz) | 1.798 | 69,5 | 175 |
| parcheado | Philips_NMS_8250 (MSX2, 50 Hz) | 1.505 | 1,7 | 22 |

En el MSX1 el cartucho parcheado se comporta como el original: el registro 5
alterna entre sus dos tablas, 899 cuadros cada una. En el MSX2 lo que queda
son los momentos en que cinco o seis jugadores se amontonan en las mismas
líneas con el balón y su sombra, más de ocho; la rotación del propio juego
sigue repartiendo esos. El reloj del partido va al mismo paso.

    sh tools/lanza_parpadeo.sh work/p_msx1 C-BIOS_MSX1_JP dunkshot.rom 4 16 46 "4 8 0x01 7 8 0x01 10 8 0x01"
    sh tools/lanza_parpadeo.sh work/p_msx2 Philips_NMS_8250 work/dunkshot_msx2.rom 8 20 50 "8 8 0x01 11 8 0x01 14 8 0x01"

Los argumentos son el directorio de salida, la máquina, la ROM, el límite,
los segundos medidos y las teclas como en [En el emulador](EN-EL-EMULADOR.md);
el MSX2 arranca más tarde, de ahí las teclas más tarde. Con `DS_THROTTLE=on`
corre a velocidad real, para verlo. Todo esto está medido en openMSX; nadie
lo ha pasado aún por una máquina real.

## Lo que cambia el V9938

SCREEN 4 (modo G3) es SCREEN 2 con los sprites en modo 2: mismas tablas de
patrones, nombres y colores, así que los gráficos del juego no se tocan.
Cambian tres cosas:

- El registro 0 lleva el bit 2 (M4) en vez del bit 1 (M3). El TMS9918 no
  tiene M4, así que en un MSX1 no hay que tocarlo.
- El registro 5, con los bits 0-2 a 1 (el VDP los ignora), señala un bloque
  de 1 KB: su primera mitad es la tabla de colores de sprite, 16 bytes por
  sprite, un color por línea (bit 7 = early clock, como en el atributo), y
  los 128 bytes de atributos van en +0x200. El byte de color del atributo se
  ignora. Es lo que hace la BIOS en SCREEN 4: R5 = 0x3F, colores en 0x1C00,
  atributos en 0x1E00.
- El fin de la lista es Y = 216, no 208.

Bajo los 16 KB de un MSX1 el juego solo deja sin usar 0x3C00-0x3FFF (los
patrones de sprite acaban en 0x3BBF), así que: colores en 0x3C00-0x3DFF,
atributos en 0x3E00, y la segunda tabla que el MSX1 alterna en 0x3F00. En un
MSX1, R5 = 0x7C o 0x7E señala esas dos tablas; en un MSX2, R5 vale siempre
0x7F y el VDP enseña 0x3E00 los dos cuadros, la lista rotada de 0xE7B0, de la
que salen los colores. No se mueve ningún patrón.

## Lo que cambia en el cartucho

- `0x5036`: el `jp INIGRP` va a un gancho en el relleno a 0xFF de `0xBFD4`:
  tras INIGRP, ATRBAS = 0x3E00 y R5 = 0x7C; si la BIOS es de MSX2 (byte
  0x002D), además R0 = 4 y R5 = 0x7F.
- `0x5B7B`: el `xor 4` pasa a `xor 1`: la alternancia es 0x3E00 / 0x3F00.
  Su WRTVDP (`0x5B82`) pasa por `0xBFF3`, que en un MSX2 escribe siempre
  0x7F. `0x5B9B` compara con 0x3E, la tabla que `congela_sprites` deja a la
  vista.
- `0x5BE6`, `0x5BF2`: las dos copias por cuadro van a 0x3E00 y 0x3F00; la
  segunda sigue en `0x7AAE` con la tabla de colores: los 32 colores de la
  lista de 0xE7B0, 16 bytes cada uno, a 0x3C00 con `out` y sin
  interrupciones (`0x6EA0`). En un MSX1 vuelve sin hacer nada.
- `0x5BFB`, `0x7374`, `0x8057`: los fines de lista escriben 0xD0 y, en la
  entrada siguiente, 0xD8 (`0x6EC9`).
- `0x5063`, `0x804C`, `0x80D5`, `0x80DC`: 0x1B00 y 0x1B10 pasan a 0x3E00 y
  0x3E10.
- `0x80CE`: el final de `viste_jugador`, la figura de muestra de las fichas
  de equipo y de TRADE, salta a `0x6F30`: relee los ocho atributos de la
  VRAM y rellena sus colores, para que la figura conserve piel, pelo y
  camiseta también en un MSX2.

El código nuevo vive en el relleno de 0xBFD4-0xBFFD y en tres rutinas
huérfanas que nadie llama (0x6EA0, 0x6F30, 0x7AAE). `tools/parche_msx2.py`
ensambla los trozos con Pasmo, parchea los operandos y escribe la ROM, el
IPS y `parche/parche_msx2.asm`, el listado del código nuevo;
`tests/test_parche.py` comprueba que el IPS lo reproduce y solo toca esos
tramos.

    make parche     # work/dunkshot_msx2.rom y parche/dunkshot_msx2.ips, desde dunkshot.rom

## Cómo aplicarlo

El IPS se aplica al cartucho de 32 KB (sha256 `a1891e03...`), con cualquier
herramienta de IPS o con estas líneas de Python:

    rom = bytearray(open("dunkshot.rom", "rb").read())
    ips = open("parche/dunkshot_msx2.ips", "rb").read()
    i = 5
    while ips[i:i + 3] != b"EOF":
        a, n = int.from_bytes(ips[i:i + 3], "big"), int.from_bytes(ips[i + 3:i + 5], "big")
        rom[a:a + n] = ips[i + 5:i + 5 + n]
        i += 5 + n
    open("dunkshot_msx2.rom", "wb").write(rom)

El resultado tiene sha256 `e5e14b0f7b188b77ae7b8daa28d98ee1e8c9bfc3d6479b9b93c0afbfd1037e6c`
y tampoco se distribuye. En openMSX:

    openmsx -machine Philips_NMS_8250 -cart dunkshot_msx2.rom

Vale cualquier MSX2; en un MSX1 se juega como el original.

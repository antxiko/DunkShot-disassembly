# Dunk Shot: las dos ROM, la primera y la "a"

La ROM `[a]` de GoodMSX (sha256 `a9e759ae...`) es el mismo programa que la
primera (`[!]`, sha256 `a1891e03...`) reensamblado y con arreglos. Este
fichero dice QUE cambia y COMO se ha comprobado. Todo lo de aqui sale de
comparar las dos ROM con `tools/traduce_version.py`. Las direcciones de la version "a" son las de su desensamblado, en `rom_a/`.

## Como se ha comparado

Un `diff` binario no sirve: casi todo esta en otra direccion y la RAM de
trabajo esta repartida de otra manera. Se hizo asi:

1. Cada instruccion de la primera se busca en la nueva con su operando
   absoluto como comodin; cuando el operando ya se sabe traducir, el comodin
   pasa a ser el valor traducido. Cuatro pasadas. Lo que no encaja queda como
   CAMBIO.
2. De los operandos emparejados sale el mapa de RAM por votacion: 257
   direcciones, ni un conflicto. Sale a bloques (por ejemplo 0xE500-0xE61F, los
   seis registros de jugador, pasan a 0xC410-0xC52F).
3. Resultado: 10.430 de 10.690 instrucciones de la primera estan, iguales, en
   la nueva. Las 260 restantes son los cambios. Del lado nuevo quedan 569 bytes
   de codigo sin pareja en la primera.
4. El desensamblado de la version "a" reensambla la ROM byte a byte, sin
   un solo byte sin explicar, y los tests de los datos comprimidos, la musica y
   la tabla de saltos pasan con las direcciones nuevas: es la prueba
   independiente de que el mapa de datos es bueno.

## Como esta ordenada la ROM

| | primera | `[a]` |
|---|---|---|
| codigo de la pagina 1 | 0x4010-0x8C2F | 0x4010-0x8C4B (casi lo mismo, otro orden de rutinas) |
| musica y sonido | 0x8ED5-0x9665 | 0x8DDF-0x956F |
| despachador de la pagina 2 (`jp (hl)`) | 0xB984, al final | 0x958B, antes de los graficos |
| graficos comprimidos y pista | 0x9665-0xB968 | 0x9CFB-0xBFFE |
| relleno | 44 bytes al final | 24 bytes antes de la red y 2 al final |

Consecuencia para el parche: ya no hay hueco al final de la ROM; el codigo
del parche cae en cinco rutinas huerfanas (ver el repositorio [DunkShot-MSX2-Patch](https://github.com/antxiko/DunkShot-MSX2-Patch)).

## Lo que cambia en el juego

Direcciones de la ROM `[a]` salvo que se diga otra cosa.

**Faltas.**

- `rotulo_falta_marcador` (0x6BB8): con cinco faltas personales, la primera
  version sacaba al jugador de la pista en los dos equipos. La nueva solo
  expulsa (y obliga al cambio) al jugador de un equipo que lleva una persona;
  al de la maquina solo le pone las faltas a cero.
- Los emparejamientos de marcaje (`empareja_jugadores`, 0x603C): ahora el
  par de cada jugador es el de enfrente (tabla 3 4 5 0 1 2 en 0x6050); antes
  era 5 4 3 2 1 0.
- `pinta_area_si_sigue` (0x6E4B): tras el final de la mitad ya no se repinta
  AREA=.
- `pausa_final` (0x4272): al acabar el partido el balon sale de la pista y hay
  dos segundos de pausa; antes seguian jugandose 120 cuadros.

**Puntuacion.**

- `suma_canasta` (0x8C15) suma el valor de la canasta a los dos contadores
  del tirador al ANOTAR, cada uno con tope 0xFF. La primera sumaba el del
  campo 8 al tirar, entrara o no.
- Los ajustes de habilidad tras el partido (`mejora_13`, `mejora_16`,
  `mejora_18`, `mejora_1b`, `experiencia`) cortan a 0xFF cuando hay acarreo,
  y lo que se baja tras perder pasa de 10 a 4 en el campo 0x13.
- Niveles de la maquina: campo 0x18 = 10 por nivel mas 20 (antes mas 30) y
  campo 0x1B = 5 (antes 10).

**Juego.**

- La penalizacion de un tiro por el defensor (`defensa`, 0x8493) pasa a
  (14 - distancia) por 12 mas 20 si salta; antes (13 - distancia) por 16 mas 32
  si saltaba y otros 32 si estaba mas alto.
- La altura inicial del balon deja Z en 0xFFFF en vez de 0 (0x834C).
- La defensa de la maquina (`decide_defensor_libre`, `defensa_encima`,
  `defensa_tapa`): no decide si hay una orden pendiente; espera 21 cuadros
  fijos (antes de 20 a 35 al azar); la orden de tirar pasa de 0x10 a 0x15 y
  al taponar copia la pose del atacante en vez de poner brazos arriba.
- Las formaciones de ataque: cada jugador mira su propia jugada (+0x22); un
  robo con una formacion en marcha la corta (`hay_formacion`, bandera 0xC5FE);
  `en_zona_poseedor` usa `zona_tiro` y no un rectangulo; `acabados` pide los
  tres atacantes sin pasos, no dos.
- `mueve_jugador` (0x4CDB) ya no limita la X con la ventana en el centro.
- Con la ventana desplazandose a la derecha (bit 4 de 0xC5DF) el jugador sin
  balon solo atiende al pase que le llega. SUPOSICION: no he visto en la ROM
  quien pone ese bit con otra cosa que el desplazamiento.

**Textos.**

- `PUSH ANY KEY.` pasa a `PUSH SPACE KEY>`, una columna a la izquierda.
- Los creditos dicen `S;KAGAMI` donde decian `S;MIRROR`.

**Codigo huerfano.** Desaparecen tres rutinas que nadie llamaba en la primera
y quedan dos mas sin llamar (`limita_centro`, 0x4D92, y el rectangulo de la
canasta, 0x5D65). Las que siguen estan declaradas en `src/dunkshot.entries`.

## El mapa de la RAM de trabajo (primera -> `[a]`)

| primera | `[a]` | que es |
|---|---|---|
| 0xE400 | 0xEB3D | bancos de patrones descomprimidos |
| 0xE4DF-0xE525... | 0xC3?? | desplazamiento -0x20F0: los seis registros de jugador (0xE500 -> 0xC410) |
| 0xE620-0xE65F, 0xE6B0-0xE6ED | -0x20F0 | balon y sombras de atributos |
| 0xE6EF-0xE6F6 | -0x20EF | |
| 0xE718-0xE730, 0xE7B0, 0xE830-0xE841 | +0x4B5 | VRAM pendiente y listas de sprites (0xE730 -> 0xEBE5, 0xE7B0 -> 0xEC65) |
| 0xE842-0xE870, 0xE93D-0xE95C, 0xEA29-0xEA89 | -0x223A | equipos |
| 0xED78-0xED9B | -0x12 | contadores de partido y puntos |
| 0xEFCD-0xEFDE | -0x280 | tipo de falta, modos de equipo |
| 0xC000, 0xC200, 0xC300 | igual | tablas de cuadrados, perspectiva y arcotangentes |

(La lista completa, de 257 direcciones, se rehace con
`python tools/traduce_version.py . dunkshot_a.rom DIR_SALIDA`, que la
deja en `work/mapa_version.json`.)

# El código

## El arranque y el bucle

INIT (`0x4010`) pone la pila en 0xF200, activa la ranura en la página 2,
engancha la interrupción de cuadro a `0x606E` y arranca: `0x5189` limpia la
RAM, `0x501F` pone SCREEN 2 y carga patrones, sprites y colores, `0x7322` deja
los equipos ABC y DEF, y el bucle de `0x4044` encadena título (`0x839C`),
espera (`0x8B28`), menú (`0x83BA`), SET-UP (`0x812F`) y partido. La
interrupción lleva el giro de los jugadores, las caídas, la red y los botones
(`0x60A0`-`0x62E3`).

## Los sprites y el parpadeo

Cada cuadro, `0x5C40` calcula los cuatro sprites de cada jugador: a la
posición de los pies le resta los desplazamientos de la pose (`0xA38E`) y
ajusta la altura con las curvas de perspectiva de `0xB59E` y `0xB61E`
(`0x5DE4`, `0x5DAF`). Como el TMS9918 no pinta más de cuatro sprites por
línea, `0x5C0B` monta los siete grupos (seis jugadores y los fijos) en un
orden que cambia cada cuadro, `0x5BAB` los copia al revés en otro búfer y los
dos van a las dos tablas de atributos (0x1B00, 0x1F00); `0x5B77` cambia el
bit 2 del registro 5 para enseñar una u otra. Es lo que hace que los
jugadores parpadeen cuando se juntan.

![Las 160 poses](../imagenes/poses.png)

## La ventana sobre la pista

El mapa de 56 × 24 está en RAM (0xC400, descomprimido por `0x5F8D`). `0x5F33`
copia a la tabla de nombres las 24 filas de 32 bytes que empiezan en la
columna de 0xE830, con `0x5B07` (SETWRT y `outi`); `0x5E7C` decide cuándo
moverla. No hay desplazamiento fino: la pantalla salta de columna en columna.

## Dibujar en la VRAM

Tres rutinas lo hacen todo: `0x5B07` escribe BC bytes de HL en DE, `0x5B50`
rellena BC bytes con A y `0x5AF7` escribe un byte en HL. Encima van `0x7C1B`
(una cadena acabada en cero), `0x7C29` (B filas de C caracteres), `0x7FC1`
(un cuadro con los patrones 0xF5-0xF7 y 0x62-0x67) y los impresores de
números de `0x7ACF`, `0x7ADA` y `0x7AA7`, que dejan en blanco los ceros de la
izquierda contando en C los dígitos ya escritos.

## El selector de menús

`0x8AC9` recibe la posición del cursor, el número de opciones y el patrón de
la bola (0x6F); lee con CHGET, sube y baja con 0x1E y 0x1F y devuelve
cualquier otra tecla. La opción elegida vive en 0xEFCD, cuyo bit 7 dice si se
trata del equipo de la derecha.

## La máquina

Con el balón, `0xBB14` lleva al jugador por cinco estados (0xF009): elegir un
punto hacia la canasta con seno y coseno de las tablas de 0xC000, correr a
él, encararla, ir al punto de tiro y tirar, robar o pasar según el azar y las
habilidades +0x1D y +0x1E. Sin el balón, `0xBD61` (0xF00A) va a por el que lo
lleva, lo marca o se queda, y `0x76AE` mide la zona del tiro. Las jugadas de
0xEA89 dan a cada jugador un guion de puntos a los que ir.

## El sonido

`0x8D42` arranca la pieza A si su prioridad (`0x8F71`) no es menor que la que
suena; `0x8D8B` corre cada cuadro y `0x8DB2` interpreta: 0x40-0xFF nota (canal
en los dos bits altos, índice en la tabla de 64 periodos), 0x20-0x25
mezclador, 0x26-0x2F registro, 0x33 salto, 0x34/0x35 llamada y vuelta con pila
propia en IX, 0x36/0x37 bucle, 0x38-0x3B volumen relativo, 0x3D silencio,
0x00-0x1F espera; una espera de cero acaba la pieza. Trece piezas, diez
distintas: la música es la 1 (y la 8, el mismo puntero) y la 4, la 5 y la 6
son la misma con tres prioridades.

## El azar

El registro R del Z80 (`0x50E9`, `0x6F53`, `0x6F76`): un bit o un byte, según
haga falta.

## Lo que no corre nadie

Diecisiete trozos de código sin llamadas, declarados en
`src/dunkshot.entries` con su motivo: entradas alternativas (`0x59BA`,
`0x59E8`, `0x5AFD`), rutinas sueltas (`0x441D` niega HL, `0x6F76` da 1 o 2 al
azar, `0x8D3B` espera a que acabe el sonido), un contador de cinco cifras
(`0x7AAE`) y `0x8B3C`, que escribe un cero en 0x785B, que es ROM: un resto de
cuando el programa se probaba en RAM.

# Empezar

Hace falta Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) y tu propia
imagen del cartucho como `dunkshot.rom` en la raíz del repositorio (32.768
bytes; `make comprueba` verifica el sha256). La ROM no se distribuye.

    make            # listado, reensamblado, controles y tests
    make imagenes   # las imágenes de la web, desde la ROM
    make web        # la web bilingüe en docs/

`make` genera `src/dunkshot.asm` desde el binario y las notas
(`src/dunkshot.notes`), lo reensambla con Pasmo y comprueba que sale la ROM
exacta; después pasa los controles que el reensamblado no cubre: que ningún
dato se lea como código, que ningún punto de entrada caiga en una zona de
datos y que no quede un byte sin asignar.

## Las herramientas

- `tools/z80trace.py` y `tools/mkasm.py`: el trazador y el generador del
  listado. Los puntos de entrada que el trazado no deduce (el gancho de la
  interrupción, los ocho `jp` de 0xB985 y el código huérfano) están en
  `src/dunkshot.entries`, cada uno con su motivo.
- `tools/graficos.py`: los cuatro descompresores del cartucho y el dibujo de
  patrones y sprites. `tools/pantallas.py` monta cada pantalla en una VRAM;
  `tools/coteja.py` la compara con un volcado de openMSX; `tools/imagenes.py`
  genera la galería.
- `tools/sonido.py` recorre las trece piezas como las lee el motor.
- `tools/lanza_vuelca.sh` y `tools/omsx_vuelca.tcl`: un openMSX que pulsa teclas
  en los instantes que se le dicen y vuelca VRAM, RAM y registros.
- `tools/densidad.py`, `tools/huecos.py`, `tools/margen.py` y
  `tools/sin_bautizar.py`: la medida de los comentarios.

## Las notas

El listado no se edita a mano: cada comentario es una directiva del fichero
de notas anclada a una dirección (`C 0x5F33 texto`), cada rutina con nombre
una `L`, y cada bloque de datos una `D` con su medida. `make listado` las
aplica y `tools/valida_c.py` avisa si alguna cae a media instrucción o está
repetida.

# Dunk Shot (MSX) — desensamblado comentado

*(Also available [in English](README.md).)*

Desensamblado comentado de **Dunk Shot** (HAL Laboratory, 1986), cartucho de
32 KB para **MSX**: sin mapeador, en las páginas 1 y 2.

**La web**: https://antxiko.github.io/DunkShot-disassembly/es/

| | |
|---|---|
| explicado | 100 % (20.642 bytes de código, 12.126 de datos) |
| comentado | 43,2 % de las instrucciones |
| rutinas | 1.289, ninguna por debajo del 10 % |
| reensamblado | la ROM, byte a byte |
| imágenes | dibujadas desde la ROM; seis pantallas cotejadas contra openMSX, 0 diferencias |

## Qué hay

- El listado (`src/dunkshot.asm`), que se genera desde el binario y las notas y
  reensambla la ROM exacta.
- La pista entera de 56 columnas en sus tres colores, el título, los menús, la
  ficha de equipo y el partido, montados desde las tablas del cartucho.
- Los jugadores: 160 poses de cuatro sprites y 32 aspectos de piel y pelo.
- Cómo funciona: la ventana de 32 columnas, el reparto de sprites que parpadea,
  los equipos de la máquina por nivel, la cinta como BSAVE, las jugadas, los
  cuatro compresores y el motor de sonido.

## Cómo reproducirlo

Hace falta Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) y **tu propia
imagen del cartucho** como `dunkshot.rom` en la raíz:

```
sha256  a1891e038566596a9f67067b8ea4694709aa9fee93c8ac0379360b30ea3abe62
make
```

Los detalles, en [Empezar](docs/es/EMPEZAR.md).

## Aviso

El juego es de HAL Laboratory; aquí solo están el análisis, los comentarios y
las herramientas. La ROM no se distribuye. Ver [AVISO-LEGAL.md](AVISO-LEGAL.md).

#!/usr/bin/env python3
"""Recorre las piezas de sonido tal como las lee el motor de 0x8DB2.

El motor (tick en 0x8D8B, una vez por cuadro) lee fichas de una pieza hasta
dar con una ESPERA, y vuelve al cuadro siguiente. Las fichas, por su byte:

  0xC0-0xFF, 0x80-0xBF, 0x40-0x7F   nota: el canal es (x>>6)-1 (C, B, A) y
                                     x & 0x3F el indice en la tabla de notas
                                     de 0x8ED5 (64 periodos de 16 bits)
  0x20-0x25   mezclador: registro 7 <- byte 0x8F55[x & 0x0F]
  0x26-0x2F   registro (x & 0x0F) <- byte siguiente
  0x30/0x32/0x3C  deslizamiento de tono del canal A/B/C: al periodo actual se
                  le suma el byte siguiente, con signo
  0x33 nn nn  salto
  0x34 nn nn  llamada (pila propia en IX)
  0x35        vuelta de la llamada
  0x36 n      abre un bucle de n vueltas (n = 0x1F: el tempo de 0xEFE8)
  0x37        cierra el bucle
  0x38-0x3B   volumen del canal (x & 3): al actual se le suma el byte
              siguiente, con signo, y se recorta a 0..16
  0x3D        silencio: registros 0-5 a cero
  0x00-0x1F   ESPERA de x cuadros (0x1F: los de 0xEFE8); 0x00 acaba la pieza

Uso: sonido.py <rom>   -> el principio y el final de cada pieza
"""
import sys

ORG = 0x4000
NOTAS = 0x8ED5
MEZCLA = 0x8F55
PUNTEROS = 0x8F57
PRIORIDAD = 0x8F71
N_PIEZAS = 13


def recorre(rom, ini, tope=0xC000):
    """Direccion siguiente al ultimo byte que la pieza llega a leer.

    Un salto hacia atras es un bucle infinito: la pieza acaba ahi. Una espera
    de cero acaba la pieza.
    """
    hl = ini
    maximo = ini
    pila = []
    bucles = []
    vistos = set()
    while hl < tope:
        x = rom[hl - ORG]
        if hl in vistos and not bucles:
            break
        vistos.add(hl)
        maximo = max(maximo, hl + 1)
        if x & 0xC0:
            hl += 1
        elif x & 0x20:
            if x & 0x10:
                if x == 0x3D or x == 0x35 or x == 0x37:
                    if x == 0x35:
                        if not pila:
                            break
                        hl = pila.pop()
                        continue
                    if x == 0x37:
                        if bucles:
                            n, vuelta = bucles[-1]
                            n -= 1
                            if n > 0:
                                bucles[-1] = (n, vuelta)
                                hl = vuelta
                                continue
                            bucles.pop()
                    hl += 1
                elif x in (0x33, 0x34):
                    dest = rom[hl + 1 - ORG] | rom[hl + 2 - ORG] << 8
                    maximo = max(maximo, hl + 3)
                    if x == 0x34:
                        pila.append(hl + 3)
                        hl = dest
                    else:
                        if dest <= hl:
                            break
                        hl = dest
                elif x == 0x36:
                    n = rom[hl + 1 - ORG]
                    bucles.append((2 if n == 0x1F else n, hl + 2))
                    hl += 2
                else:
                    hl += 2
            else:
                hl += 1 if (x & 0x0F) < 6 else 2
        else:
            if x == 0:
                maximo = max(maximo, hl + 1)
                break
            hl += 1
    return maximo


def main():
    rom = open(sys.argv[1], "rb").read()
    punteros = [rom[PUNTEROS - ORG + 2 * i] | rom[PUNTEROS - ORG + 2 * i + 1] << 8
                for i in range(N_PIEZAS)]
    prioridad = rom[PRIORIDAD - ORG:PRIORIDAD - ORG + N_PIEZAS]
    print("pieza  inicio  fin     bytes  prioridad")
    distintos = sorted(set(punteros))
    for i, p in enumerate(punteros):
        fin = recorre(rom, p)
        print("  %2d   0x%04X  0x%04X  %5d  %3d" % (i, p, fin - 1, fin - p, prioridad[i]))
    print("\npiezas distintas, por direccion:")
    for p in distintos:
        fin = recorre(rom, p)
        sig = [q for q in distintos if q > p]
        print("  0x%04X-0x%04X  %5d B  siguiente 0x%04X" % (p, fin - 1, fin - p, sig[0] if sig else 0x9665))


if __name__ == "__main__":
    main()

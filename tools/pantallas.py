#!/usr/bin/env python3
"""Monta en Python la VRAM de cada pantalla leyendo las tablas del cartucho.

No se ejecuta el juego: cada funcion hace lo mismo que la rutina del cartucho
que monta esa pantalla, con las direcciones del listado al lado, y escribe en
una VRAM de 16 KB. Lo que sale se coteja byte a byte contra un volcado de
openMSX (tools/coteja.py), y se dibuja (tools/imagenes.py).

La VRAM es la de SCREEN 2 tal como la deja INIGRP (0x0072, lo llama 0x502E):
patrones en 0x0000, nombres en 0x1800, atributos de sprite en 0x1B00 (o en
0x1F00: 0x5B77 cambia el bit 2 del registro 5 en cada cuadro), colores en
0x2000 y patrones de sprite en 0x3800.
"""
import sys

from graficos import (Rom, des_52cf, des_5331, des_535b, des_5373, PALETA,
                      lienzo, escala, pinta_patron, pinta_sprite16, png)

PATRONES, NOMBRES, ATRIBUTOS, COLORES, SPRITES = 0x0000, 0x1800, 0x1B00, 0x2000, 0x3800


class Maquina:
    def __init__(self, rom):
        self.rom = rom
        self.vram = bytearray(0x4000)
        self.ram = bytearray(0x10000)      # solo lo que hace falta (0xC000-)
        self.inigrp()

    # --- la BIOS -----------------------------------------------------------
    def inigrp(self):
        """INIGRP: nombres 0..255 en los tres tercios y colores FORCLR/BAKCLR.

        0x502E pone FORCLR (0xF3E9) y BAKCLR (0xF3EA) a 1 antes de llamarla,
        asi que la tabla de colores entera queda a 0x11.
        """
        for t in range(3):
            for i in range(256):
                self.vram[NOMBRES + t * 256 + i] = i
        for i in range(0x1800):
            self.vram[COLORES + i] = 0x11

    def clrspr(self):
        """CLRSPR: los 32 atributos con Y = 209 (fuera de pantalla), patrones a 0."""
        for i in range(32):
            self.vram[ATRIBUTOS + i * 4:ATRIBUTOS + i * 4 + 4] = bytes([209, 0, i * 4, 0])
        for i in range(0x800):
            self.vram[SPRITES + i] = 0

    # --- las rutinas del cartucho -----------------------------------------
    def ldirvm(self, dst, datos):
        self.vram[dst:dst + len(datos)] = datos

    def filvrm(self, dst, n, v):
        """0x5B50: A en N posiciones desde HL (como FILVRM)."""
        self.vram[dst:dst + n] = bytes([v]) * n

    def tres_tercios(self, dst, datos):
        """0x50C1 / 0x7807: lo mismo en los tres tercios (DE, DE+0x800, DE+0x1000)."""
        for t in range(3):
            self.ldirvm(dst + t * 0x800, datos)

    def pantalla_base(self):
        """0x501F -> 0x5039/0x50AC: sprites fijos, patrones de la pista y colores del AREA."""
        self.clrspr()                                            # 0x503F
        self.ldirvm(0x3B00, self.rom[0x9665:0x96C5])             # 0x504B
        self.ldirvm(0x3B60, self.rom[0x96C5:0x9725])             # 0x5057
        pista, _ = des_52cf(self.rom, 0xA74E)                    # 0x50AC -> 0xC400
        self.ram[0xC400:0xC400 + len(pista)] = pista
        self.tres_tercios(PATRONES, self.ram[0xC400:0xCC00])     # 0x50C1: 3 x 0x800
        self.area(0)                                             # 0x781D con (0xEFDB) = 0

    def area(self, n):
        """0x781D-0x7857: la tabla de colores del AREA n (0x785A) y la de 0xAEC0."""
        ptr = self.rom.palabra(0x785A + n * 4)
        col, _ = des_5373(self.rom, ptr)                         # -> 0xC400
        self.ram[0xC400:0xC400 + len(col)] = col
        self.tres_tercios(COLORES, self.ram[0xC400:0xCC00])      # 0x7839 -> 0x7807: 0x800 en los tres tercios (los ultimos 48 B son lo que habia en 0xC400)
        col2, _ = des_535b(self.rom, 0xAEC0)                     # 0x7842 -> 0xC400
        self.ram[0xC400:0xC400 + len(col2)] = col2
        self.tres_tercios(0x2100, self.ram[0xC400:0xC400 + 0x2A0])   # 0x784E -> 0x7807

    def logo(self):
        """0x77DD: los 80 patrones del logotipo (0xB0-0xFF) y sus colores, en los tres tercios."""
        self.filvrm(NOMBRES, 0x300, 0x20)                        # 0x50DA
        pat, _ = des_52cf(self.rom, 0xB33E)
        self.ram[0xC400:0xC400 + len(pat)] = pat
        self.tres_tercios(0x0580, self.ram[0xC400:0xC400 + 0x280])   # 0x77E9
        col, _ = des_52cf(self.rom, 0xB491)
        self.ram[0xC400:0xC400 + len(col)] = col
        self.tres_tercios(0x2580, self.ram[0xC400:0xC400 + 0x280])   # 0x77FE

    def texto(self, dst, src):
        """0x7C1B: la cadena de la ROM acabada en cero, caracter a caracter (0x5AF7)."""
        while self.rom[src]:
            self.vram[dst] = self.rom[src]
            dst += 1
            src += 1

    def titulo(self):
        """0x839C: la pantalla de titulo."""
        self.pantalla_base()
        self.logo()
        # 0x836F: borra los nombres, descomprime las 17 filas de 0xB0FE y las pone
        self.filvrm(NOMBRES, 0x300, 0x20)                        # 0x50DA
        nom, _ = des_5331(self.rom, 0xB0FE)
        self.ram[0xC400:0xC400 + len(nom)] = nom
        self.ldirvm(NOMBRES, self.ram[0xC400:0xC400 + 0x220])    # 0x837B
        # 0x8387/0x8390: los nombres de los dos equipos (tres letras cada uno), que
        # 0x7322 deja en "ABC" y "DEF" al arrancar (0xE851 y 0xE93D)
        self.ldirvm(0x19E7, b"ABC")
        self.ldirvm(0x19F6, b"DEF")
        self.texto(0x1A66, 0x7D5A)                               # @1986 HAL LABORATORY
        self.texto(0x1AAB, 0x7D6F)                               # F.NAKAMURA
        self.texto(0x1ACB, 0x7D7A)                               # S.MIRROR
        return self

    def cuadro(self, dst, filas, ancho):
        """0x7FC1: un cuadro con los tiles 0xF5 0xF7 0xF6 arriba, 0x62 0x65 0x63
        abajo y 0x66/0x67 a los lados; D = filas hasta el borde de abajo, E =
        ancho - 1 (la esquina derecha pisa el ultimo 0xF7)."""
        self.vram[dst] = 0xF5
        self.vram[dst + 1:dst + 1 + ancho] = bytes([0xF7]) * ancho
        self.vram[dst + ancho] = 0xF6
        abajo = dst + filas * 32
        self.vram[abajo] = 0x62
        self.vram[abajo + 1:abajo + 1 + ancho] = bytes([0x65]) * ancho
        self.vram[abajo + ancho] = 0x63
        for f in range(1, filas):
            self.vram[dst + f * 32] = 0x66
            self.vram[dst + f * 32 + ancho] = 0x67

    def filas_de_texto(self, dst, src, filas, ancho):
        """0x7C29: B filas de C caracteres seguidos de la ROM, una debajo de otra."""
        for f in range(filas):
            self.ldirvm(dst + f * 32, self.rom[src + f * ancho:src + (f + 1) * ancho])

    def cursor(self, dst, seleccion=0):
        """0x8AC9/0x8B06: la bola del cursor (tile 0x6F) en la fila elegida."""
        self.vram[dst + seleccion * 32] = 0x6F

    def menu_titulo(self):
        """0x83BA: el titulo con el primer menu (SET-UP, LEFT TEAM, RIGHT TEAM, TRADE)."""
        self.titulo()                                            # 0x836F (sin los creditos: 0x839C no se llama aqui)
        self.filvrm(0x1A66, 20, 0x20)                            # los creditos no estan: 0x836F borra la tabla
        self.filvrm(0x1AAB, 10, 0x20)
        self.filvrm(0x1ACB, 8, 0x20)
        self.cuadro(0x1A48, 5, 15)                               # 0x83D3: de = 0x050F
        self.filas_de_texto(0x1A6B, 0x7D32, 4, 10)               # 0x83DC: bc = 0x040A
        self.cursor(0x1A6A)                                      # 0x83F4: 0x8AC9 con 4 opciones
        return self

    def setup(self, mitad=1, area=0, nombres=(b"ABC", b"DEF")):
        """0x812F: la pantalla SET-UP (PLAY, STARTERS, CHANGE SIDES...)."""
        self.pantalla_base()
        self.logo()
        nom, _ = des_5331(self.rom, 0xB22A)                      # 0x8194 -> 0xC400
        self.ram[0xC400:0xC400 + len(nom)] = nom
        self.ldirvm(NOMBRES, self.ram[0xC400:0xC400 + 0x300])
        self.ldirvm(0x18C7, nombres[0])                          # 0x81A9
        self.ldirvm(0x18D6, nombres[1])
        for i in range(4):                                       # 0x81BB: HALF 05 10 15 20
            self.vram[0x194B + i * 4] = 0x20
        self.vram[0x194B + mitad * 4] = 0xF9
        for i in range(3):                                       # 0x81DC: COURT
            self.vram[0x198C + i * 5] = 0x20
        self.vram[0x198C + area * 5] = 0xF9
        self.cursor(0x1A28)                                      # 0x8141: 0x8AC9 con 6 opciones
        return self

    def relleno_filas(self, dst, filas, ancho, tile):
        """0x7E0F: B filas de C tiles iguales desde HL."""
        for f in range(filas):
            self.filvrm(dst + f * 32, ancho, tile)

    def equipo(self, nombre=b"ABC", nivel=1, derecha=False):
        """0x862B + 0x7B75 + 0x8B57: la pantalla de equipo con la ficha de un
        equipo de la maquina (COMPUTER TEAM, LEVEL n), que es como arranca."""
        self.pantalla_base()
        self.logo()
        self.filvrm(NOMBRES, 0x300, 0x20)                        # 0x50DA
        self.filas_de_texto(0x1804, 0x7CD3, 5, 10)               # 0x862E: MAKE TEAM ... EDIT TEAM
        self.cuadro(0x1810, 3, 13)                               # 0x863D: el cuadro de los mensajes
        # 0x7B75: la ficha
        self.filvrm(0x18A0, 0x260, 0x20)                         # 0x7B78: filas 5 a 23 en blanco
        self.cuadro(0x18A1, 18, 29)                              # 0x7B83
        barra = 0xB3 if derecha else 0xB0                        # 0x7F90: la barra del color del equipo
        self.filvrm(0x18C2, 0x1C, barra)
        self.vram[0x18C2 + 0x0C] = barra + 1
        self.vram[0x18C2 + 0x10] = barra + 2
        self.ldirvm(0x18CF, nombre)                              # 0x7FBB -> 0x8396
        self.filvrm(0x18E2, 0x1C, 0xFA)                          # 0x7B95: la linea bajo la cabecera
        # 0x7BE5 (rotulos de estadisticas), 0x7BAE, 0x7E7F, 0x7EE0, 0x7EB2 y 0x7F51
        # pintan la plantilla, pero 0x8B8F la tapa entera despues: no hace falta montarla
        # 0x8B57 con el equipo en modo 2 (maquina): 0x8B81
        self.relleno_filas(0x1902, 15, 28, 0xF0)                 # 0x8B8F: el fondo rayado
        self.cuadro(0x1986, 4, 19)                               # 0x8B98
        self.relleno_filas(0x19A7, 3, 18, 0x20)                  # 0x8BA1
        self.filvrm(0x19C7, 18, 0xF4)                            # 0x8BAC: la linea del medio
        self.texto(0x19ED, 0x7CC8)                               # 0x8BB7: LEVEL
        self.vram[0x19F3] = 0x30 + nivel                         # 0x8BC5: el nivel (roster+3)
        self.texto(0x19AA, 0x7D8E)                               # 0x8B86: COMPUTER TEAM
        self.cursor(0x1803)                                      # 0x8655: 0x8AC9 con 5 opciones
        return self

    def equipo_load_data(self, error=False):
        """0x870F: LOAD DATA en la pantalla de equipo: "LOAD DATA." y "SURE?" en el
        cuadro de los mensajes; si la cinta falla, "ERROR!" encima de SURE? (0x8740)."""
        self.equipo()
        self.vram[0x1803] = 0x20                                 # el cursor baja a la segunda opcion
        self.cursor(0x1803, 1)
        self.texto(0x1832, 0x7DC6)                               # LOAD DATA.
        self.texto(0x1854, 0x7DE4)                               # SURE?
        if error:
            self.texto(0x1851, 0x7DEA)                           # "   ERROR!   "
        return self

    # --- la pista entera -------------------------------------------------
    def pista_completa(self, area=0, k=2):
        """Las 56 columnas x 24 filas de la pista (0xB69E, 1344 bytes), con los
        patrones de la pista y los colores del AREA: lo que 0x5F33 va mostrando
        por una ventana de 32 columnas (0xE830 = columna de la izquierda, 0-24).
        """
        self.pantalla_base()
        self.area(area)
        mapa, _ = des_5331(self.rom, 0xB69E)                     # 0x5F8D -> 0xC400
        assert len(mapa) == 56 * 24, len(mapa)
        pix = lienzo(56 * 8, 24 * 8, PALETA[1])
        for f in range(24):
            for c in range(56):
                n = mapa[f * 56 + c]
                pat = self.vram[PATRONES + n * 8:PATRONES + n * 8 + 8]
                col = self.vram[COLORES + n * 8:COLORES + n * 8 + 8]
                pinta_patron(pix, c * 8, f * 8, pat, col)
        return escala(pix, k)

    def ventana_pista(self, columna):
        """0x5F33: las 24 filas de la ventana que empieza en esa columna, en la tabla de nombres."""
        mapa, _ = des_5331(self.rom, 0xB69E)
        for f in range(24):
            self.vram[NOMBRES + f * 32:NOMBRES + f * 32 + 32] = mapa[f * 56 + columna:f * 56 + columna + 32]

    # --- el partido ------------------------------------------------------
    def digito(self, dst, n, c):
        """0x7ACF + 0x7ADA + 0x7AA7: un digito; sale en blanco si C (los
        digitos que ya han contado) sigue a cero. Devuelve C + n."""
        self.vram[dst] = 0x30 + n if (c + n) else 0x20
        return c + n

    def numero(self, dst, valor, divisores, c=0, inc_tras_primero=False):
        """Un digito por divisor y el ultimo siempre escrito (0x7AA4: ld a,l).
        0x7A43 hace `inc c` detras del primer digito (los minutos)."""
        for i, d in enumerate(divisores):
            n, valor = divmod(valor, d)
            c = self.digito(dst, n, c)
            if i == 0 and inc_tras_primero:
                c += 1
            dst += 1
        self.vram[dst] = 0x30 + valor
        return dst + 1, c

    def marcador(self, nombres=(b"ABC", b"DEF"), puntos=(0, 0), faltas=(0, 0),
                 segundos=600, mitad=0):
        """0x7A17: el cuadro de 21x4 de 0xEF77 (0x77AB descomprimido) en la
        columna 6 y, encima, los nombres, las faltas de equipo, los puntos, el
        tiempo y el numero de la mitad."""
        caja, _ = des_5331(self.rom, 0x77AB)                     # 0x77A2 -> 0xEF77
        for f in range(4):                                       # 0x7A0B: bc = 0x0415
            self.ldirvm(NOMBRES + 0x06 + 32 * f, caja[f * 21:(f + 1) * 21])
        minutos, resto = divmod(segundos, 60)
        d, c = self.numero(0x184E, minutos, (10,), inc_tras_primero=True)   # 0x7A43
        self.vram[d] = 0x3A                                      # ':' (0x7A6C)
        self.numero(d + 1, resto, (10,), c)                      # 0x7A96 con C > 0
        for dst, v in ((0x184A, puntos[0]), (0x1854, puntos[1])):   # 0x7A71 -> 0x7A84
            self.numero(dst, v, (100, 10))
        for dst, v in ((0x1847, faltas[0]), (0x1858, faltas[1])):   # 0x7941 -> 0x7A96
            self.numero(dst, v, (10,))
        self.vram[0x182E] = 0x2E + mitad                         # 0x7A38
        self.ldirvm(0x182A, nombres[0])                          # 0x8396 (0xE851)
        self.ldirvm(0x1834, nombres[1])                          # 0x8396 (0xE93D)

    def partido(self, columna=12, area=0):
        """0x7B57: la pantalla del partido con la ventana en esa columna."""
        self.pantalla_base()
        self.area(area)
        self.filvrm(NOMBRES, 0x300, 0x20)                        # 0x50DA
        self.ventana_pista(columna)                              # 0x5F8D + 0x5F33
        self.marcador()
        return self

    # --- los jugadores ---------------------------------------------------
    def patrones_sprite(self):
        """Los 196 patrones de 16x16 de los jugadores: 192 en los tres bancos
        (RAM 0xCC00-0xE3FF) y cuatro mas en 0xE400 (0xA360); las poses llegan
        al 194."""
        if not hasattr(self, "_spr"):
            a, _ = des_52cf(self.rom, 0x9725)
            b, _ = des_52cf(self.rom, 0x9B08)
            c, _ = des_52cf(self.rom, 0x9F80)
            d, _ = des_5331(self.rom, 0xA360)
            self._spr = a + b + c + d
        return self._spr

    def pose(self, p):
        """(patron, dy, dx) de los cuatro sprites de la pose p: patrones de
        0xA4CE, desplazamientos de 0xA38E (grupo p >> 2); 0x5C40 los RESTA de la
        posicion del jugador (los pies), asi que el mayor dy es el de arriba."""
        g = p >> 2
        return [(self.rom[0xA4CE + p * 4 + i],
                 self.rom[0xA38E + g * 8 + i * 2], self.rom[0xA38E + g * 8 + i * 2 + 1])
                for i in range(4)]

    def jugador(self, pix, x, y, p, piel, pelo, camiseta):
        """Pinta la pose p con los pies en (x, y). Colores por sprite como los
        reparte 0x71CC/0x71F4: piel, piel, pelo, camiseta."""
        spr = self.patrones_sprite()
        for (pat, dy, dx), color in zip(self.pose(p), (piel, piel, pelo, camiseta)):
            pinta_sprite16(pix, x - dx, y - dy, spr[pat * 32:pat * 32 + 32], color)

    def hoja_poses(self, piel=0x0B, pelo=0x01, camiseta=0x08, por_fila=16, k=2):
        """Las 160 poses, montadas de sus cuatro sprites."""
        celda_x, celda_y = 24, 56
        filas = (160 + por_fila - 1) // por_fila
        pix = lienzo(por_fila * celda_x, filas * celda_y, (40, 40, 40))
        for p in range(160):
            cx = (p % por_fila) * celda_x + 4
            cy = (p // por_fila) * celda_y + 52
            self.jugador(pix, cx + 16, cy, p, piel, pelo, camiseta)
        return escala(pix, k)

    # --- dibujo ----------------------------------------------------------
    def dibuja(self, filas=range(24), k=2, sprites=False):
        pix = lienzo(256, 192, PALETA[1])
        for f in filas:
            for c in range(32):
                n = self.vram[NOMBRES + f * 32 + c]
                tercio = (f // 8) * 0x800
                pat = self.vram[PATRONES + tercio + n * 8:PATRONES + tercio + n * 8 + 8]
                col = self.vram[COLORES + tercio + n * 8:COLORES + tercio + n * 8 + 8]
                pinta_patron(pix, c * 8, f * 8, pat, col)
        if sprites:
            for i in range(32):
                y, x, p, cl = self.vram[ATRIBUTOS + i * 4:ATRIBUTOS + i * 4 + 4]
                if y == 208:
                    break
                if y == 209:
                    continue
                pat = self.vram[SPRITES + (p & 0xFC) * 8:SPRITES + (p & 0xFC) * 8 + 32]
                pinta_sprite16(pix, x - (32 if cl & 0x80 else 0), (y + 1) & 0xFF, pat, cl & 15)
        return escala(pix, k)


if __name__ == "__main__":
    rom = Rom(sys.argv[1] if len(sys.argv) > 1 else "dunkshot.rom")
    m = Maquina(rom).titulo()
    open("work/g/titulo.png", "wb").write(png(512, 384, m.dibuja()))
    open("work/titulo.vram", "wb").write(m.vram)
    print("work/g/titulo.png y work/titulo.vram")
    for area in range(3):
        pix = Maquina(rom).pista_completa(area)
        open("work/g/pista_area%d.png" % (area + 1), "wb").write(png(len(pix[0]), len(pix), pix))
    print("work/g/pista_area1..3.png")
    m = Maquina(rom).partido(12)
    open("work/g/partido_12.png", "wb").write(png(512, 384, m.dibuja()))
    open("work/partido_12.vram", "wb").write(m.vram)
    pix = Maquina(rom).hoja_poses()
    open("work/g/poses.png", "wb").write(png(len(pix[0]), len(pix), pix))
    print("work/g/partido_12.png, work/partido_12.vram, work/g/poses.png")
    m = Maquina(rom).menu_titulo()
    open("work/g/menu_titulo.png", "wb").write(png(512, 384, m.dibuja()))
    open("work/menu_titulo.vram", "wb").write(m.vram)
    m = Maquina(rom).setup()
    open("work/g/setup.png", "wb").write(png(512, 384, m.dibuja()))
    open("work/setup.vram", "wb").write(m.vram)
    print("work/g/menu_titulo.png, work/g/setup.png")
    m = Maquina(rom).equipo()
    open("work/g/equipo.png", "wb").write(png(512, 384, m.dibuja()))
    open("work/equipo.vram", "wb").write(m.vram)
    print("work/g/equipo.png")

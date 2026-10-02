; ---- gancho_inigrp ----
    org 0xBFD4
gancho_inigrp:
    call 0x0072          ; INIGRP: SCREEN 2 con la BIOS, como antes
    ld hl,0x3E00         ; ATRBAS: la tabla de atributos visible, 0x3E00
    ld (0xF928),hl
    ld a,(0x002D)        ; version del MSX: 0 = MSX1
    and a
    ld bc,0x7C05         ; R5 = 0x7C: atributos en 0x3E00 (TMS9918)
    jp z,0x0047          ; MSX1: WRTVDP y vuelve
    ld bc,0x0400         ; R0 = 0000 0100: M4 -> G3 (SCREEN 4)
    call 0x0047          ; WRTVDP, deja RG0SAV al dia
    ld bc,0x7F05         ; R5 = 0x7F: el bloque de 1 KB de 0x3C00, bits 0-2 a 1
    jp 0x0047

; ---- r5_segun_maquina ----
    org 0xBFF3
r5_segun_maquina:        ; B = 0x7C o 0x7E (la alternancia del MSX1), C = 5
    ld a,(0x002D)        ; version del MSX
    and a
    jr z,escribe         ; MSX1: tal cual
    ld b,0x7F            ; MSX2: siempre el mismo bloque, 0x3E00 a la vista
escribe:
    jp 0x0047            ; WRTVDP

; ---- tabla_colores ----
    org 0x6EA0
tabla_colores:           ; HL = el color del sprite 0 en una lista de atributos en RAM
    ld a,(0x002D)        ; version del MSX
    and a
    ret z                ; MSX1: no hay tabla de colores de sprite
    di
    push hl
    ld hl,0x3C00         ; la tabla de colores de sprite: la primera mitad del bloque de R5
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

; ---- fin_tabla ----
    org 0x6EC9
fin_tabla:               ; HL = la entrada de atributos donde acaba la lista
    ld a,0xD0            ; Y = 208: fin de tabla en el TMS9918
    call 0x5AF7          ; escribe_vram: A en la VRAM HL
    inc hl
    inc hl
    inc hl
    inc hl
    ld a,0xD8            ; Y = 216: fin de tabla en el V9938 (modo 2)
    jp 0x5AF7

; ---- colores_menu ----
    org 0x6F30
colores_menu:            ; el final de viste_jugador (0x80CE): su bucle y luego los colores
    dec b
    jp nz,0x80B8         ; los cuatro atributos de la figura
    ld hl,0x3E00         ; los 8 atributos de las dos figuras, de la VRAM
    ld de,0xE730         ; a la lista de la otra tabla (el partido la rehace)
    ld bc,0x0020
    call 0x5B2A          ; lee_de_vram
    ld hl,0xE733         ; el color del sprite 0
    jp 0x6EA0            ; tabla_colores

; ---- vuelca_colores ----
    org 0x7AAE
vuelca_colores:          ; el final de vuelca_sprites: la segunda copia y los colores
    call 0x5B07          ; copia_a_vram: 0xE730 a 0x3F00, como antes
    ld hl,0xE7B3         ; el color del sprite 0 de la lista rotada, la que se ve en MSX2
    jp 0x6EA0            ; tabla_colores

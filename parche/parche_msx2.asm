; ---- gancho_inigrp ----
    org 0xBFD4
gancho_inigrp:
    call 0x0072          ; INIGRP: SCREEN 2 con la BIOS, como antes
    ld a,(0x002D)        ; version del MSX: 0 = MSX1
    and a
    ret z                ; en un MSX1 no hay mas
    ld bc,0x0400         ; R0 = 0000 0100: M4 -> G3 (SCREEN 4)
    call 0x0047          ; WRTVDP, deja RG0SAV al dia
    ret

; ---- fin_tabla ----
    org 0xBFE3
fin_tabla:
    ld a,0xD0            ; Y = 208: fin de tabla en el TMS9918
    call 0x5AF7          ; escribe_vram: A en la VRAM HL
    inc hl
    inc hl
    inc hl
    inc hl
    ld a,0xD8            ; Y = 216: fin de tabla en el V9938 (modo 2)
    jp 0x5AF7

; ---- r5_segun_maquina ----
    org 0xBFF1
r5_segun_maquina:
    ld a,(0x002D)        ; version del MSX
    and a
    jr z,escribe         ; MSX1: R5 = 0x78 (0x3C00 >> 7)
    ld b,0x7F            ; MSX2: los bits 0-2 a 1, como pide el modo 2
escribe:
    jp 0x0047            ; WRTVDP con B = dato, C = 5

; ---- tabla_colores ----
    org 0x6EA0
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

; ---- hueco_patron ----
    org 0x7AAE
hueco_patron:
    ld de,0x3800         ; HL = jugador * 128
    add hl,de            ; su hueco de patrones
    ld a,h
    cp 0x3A              ; jugadores 0-3: 0x3800-0x39FF, se quedan
    ret c
    ld de,0x280          ; jugadores 4 y 5: 0x3C80 y 0x3D00
    add hl,de
    ret

; ---- numeros_patron ----
    org 0x6F30
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

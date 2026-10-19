; ==========================================================================
; DUNK SHOT (version a, GoodMSX) - HAL Laboratory - MSX1 - cartucho de 32 KB en las paginas 1 y 2
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; Etiquetas que no caen en ninguna posicion emitida del listado
; (destinos fuera del binario o dentro de una instruccion).
; ----------------------------------------------------------------------
L_66C5:	equ 0x066c5

; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
l9b23h:	equ 0x09b23

; ----------------------------------------------------------------------
; DATOS cabecera: Cabecera del cartucho: "AB", INIT = 0x4010,
;   STATEMENT/DEVICE/TEXT a cero
;   0x4000..0x4010  (16 bytes)
DATA_cabecera:
	defb 041h,042h	; 4000
	defw 04010h	; 4002  -> inicio
	defw 00000h,00000h,00000h	; 4004
	defb 000h,000h,000h,000h,000h,000h	; 400a

; ======================================================================
; CODIGO 0x4010..0x43ad  (925 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Arranque y bucle principal =====
; ----------------------------------------------------------------------
inicio:		; Punto de entrada del cartucho: pagina 2, gancho H.TIMI y bucle titulo/partido
	ld sp,0f200h		;4010   ; pila en 0xF200
	xor a			;4013   ; A = 0
	ld (0f3dbh),a		;4014   ; CLIKSW = 0: sin clic de teclado
	call 00138h		;4017   ; BIOS RSLREG - Reads the primary slot register
	rrca			;401a   ; slot primario de la pagina 1 (bits 2-3 de RSLREG)
	rrca			;401b   ; bits 2-3 a los bits 0-1
	and 003h		;401c   ; ranura primaria de la pagina 1 (bits 2-3 de RSLREG)
	ld c,a			;401e   ; BC = slot primario
	ld b,000h		;401f   ; BC = ranura
	ld hl,0fcc1h		;4021   ; EXPTBL: bit 7 si el slot esta expandido
	add hl,bc			;4024   ; EXPTBL del slot
	or (hl)			;4025   ; bit 7 de slot expandido
	ld c,a			;4026   ; C = slot con su bit de expansion
	inc hl			;4027   ; HL + 4: SLTTBL del mismo slot
	inc hl			;4028   ; cuatro mas: SLTTBL
	inc hl			;4029
	inc hl			;402a
	ld a,(hl)			;402b   ; SLTTBL del slot: subslot de la pagina 1
	and 00ch		;402c   ; subslot de la pagina 1 (bits 2-3)
	or c			;402e   ; A = numero de slot completo para ENASLT
	ld hl,08000h		;402f   ; pagina 2 (0x8000-0xBFFF)
	call 00024h		;4032   ; BIOS ENASLT - Switches to specified slot and page definitively | el mismo slot del cartucho tambien en la pagina 2
	call sonido_apagado		;4035   ; sonido parado
	ld a,0c3h		;4038   ; H.TIMI = jp 0x687E (rutina de interrupcion)
	ld (0fd9fh),a		;403a   ; opcode jp
	ld hl,0687eh		;403d   ; destino del gancho
	ld (0fda0h),hl		;4040   ; la direccion del gancho: 0x687E
	ei			;4043   ; interrupciones en marcha con el gancho puesto
	call borra_ram		;4044   ; RAM 0xC410-0xEF97 a cero
	call monta_pantalla		;4047   ; SCREEN 2, sprites y pista
	call inicia_equipos		;404a   ; equipos ABC y DEF
vuelta_al_titulo:		; Reinicio tras un partido o una demo: titulo, menu y SET-UP
	ld sp,0f200h		;404d   ; pila otra vez al principio: aqui se vuelve del partido
	call oculta_sprites		;4050   ; sprites ocultos en las dos tablas de atributos
	ld a,00ah		;4053   ; pieza 0x0A: musica del titulo
	call arranca_sonido		;4055   ; suena el titulo
	call congela_sprites		;4058   ; congela la alternancia de tablas de sprites
	call logotipo		;405b   ; logotipo en los patrones 0xB0-0xFF
	ld hl,005dch		;405e   ; 1500 cuadros de espera antes de la demo
	ld (0ed7eh),hl		;4061   ; cuenta atras general (la baja la interrupcion)
	call pantalla_titulo		;4064   ; fondo y creditos
espera_titulo:		; Espera un disparo en el titulo o que se acabe la cuenta y salte la demo
	ld hl,(0ed7eh)		;4067   ; cuenta atras del titulo
	ld a,h			;406a   ; el temporizador del titulo
	or l			;406b   ; a cero?
	jp z,arranca_demo		;406c   ; se acabo la espera: arranca la demo
	call lee_disparo		;406f   ; espacio o disparo?
	jr z,espera_titulo		;4072   ; nada pulsado: sigue esperando
menu_y_setup:		; Menu del titulo y SET-UP hasta que se elija START
	call menu_titulo		;4074   ; menu del titulo
	call pantalla_setup		;4077   ; pantalla SET-UP; acarreo = volver al menu
	jr c,menu_y_setup		;407a   ; ESC en SET-UP: otra vez al menu
	xor a			;407c   ; A = 0
	ld (0c605h),a		;407d   ; 0 = partido de verdad, no demo
L_4080:
	call suelta_sprites		;4080   ; reanuda la alternancia de tablas de sprites
	call borra_jugada		;4083   ; jugadores parados
	call inicia_partido		;4086   ; variables de jugada
	xor a			;4089   ; A = combinacion de mandos
	ld hl,0ed56h		;408a   ; modo del equipo izquierdo
	bit 1,(hl)		;408d   ; bit 1 del modo: equipo de la maquina (modo 2)
	jr z,L_4093		;408f   ; no es de la maquina
	set 1,a		;4091   ; bit 1: izquierdo de la maquina
L_4093:
	ld hl,0ed57h		;4093   ; modo del equipo derecho
	bit 1,(hl)		;4096   ; bit 1 del modo del equipo derecho
	jr z,L_409C		;4098   ; bit 1 de 0xED57 a cero: bit 0 de 0xEF98 a cero
	set 0,a		;409a   ; bit 0: derecho de la maquina
L_409C:
	ld (0ef98h),a		;409c   ; combinacion de mandos (indice de la tabla de saltos 0x958C)
L_409F:
	call monta_partido		;409f   ; monta la pantalla de juego
bucle_partido:		; Un cuadro del partido y las comprobaciones de fin de mitad, faltas y saques
	call cuadro_partido		;40a2   ; cuadro completo: logica, VRAM y sprites
	call violaciones		;40a5   ; cuentas de 10 y 30 segundos vencidas
	call fin_de_mitad		;40a8   ; fin de la mitad?
	jp nz,final_de_mitad		;40ab   ; si: pitido y final de mitad
	ld a,(0cb28h)		;40ae   ; canasta hecha?
	and a			;40b1   ; hay falta?
	call nz,tras_canasta		;40b2   ; si: saque de fondo tras la canasta
	ld a,(0cb34h)		;40b5   ; infractor pendiente?
	and a			;40b8   ; hay pase?
	call p,pita_falta		;40b9   ; hay infractor: se pita la falta
	ld a,(0c616h)		;40bc   ; formacion pedida?
	and a			;40bf   ; positivo: hay formacion que pintar
	call m,inicia_formacion		;40c0   ; bit 7 de 0xC616: formacion pedida
	call vigila_formacion		;40c3   ; corta la formacion si toca
	jr bucle_partido		;40c6   ; siguiente cuadro
fin_de_mitad:		; Devuelve NZ cuando (0xED68) dice que la mitad se ha acabado
	ld a,(0ed68h)		;40c8   ; 1 = la mitad ha acabado
	and a			;40cb   ; cero: sigue el partido
	ret			;40cc   ; Z si el partido sigue
violaciones:		; Si salto la cuenta de 10 (0xED6F) o de 30 segundos (0xED70), apunta la falta al controlado del equipo con el balon
	ld a,(0ed6fh)		;40cd   ; cuenta de 10 segundos
	dec a			;40d0   ; 1 = vencida
	ld b,003h		;40d1   ; rotulo 3: 10 SECOND
	jr z,L_40DC		;40d3   ; un jugador humano ha pedido cambio
	ld a,(0ed70h)		;40d5   ; cuenta de 30 segundos
	ld b,004h		;40d8   ; rotulo 4: 30 SECOND
	dec a			;40da   ; 1 = vencida
	ret nz			;40db   ; ninguno: nada
L_40DC:
	call controlado		;40dc   ; infractor: el controlado del equipo con el balon
	ld (0cb34h),a		;40df   ; jugador infractor
	ld a,b			;40e2   ; A = 3 o 4: que equipo
	ld (0cb35h),a		;40e3   ; tipo de falta
	ret			;40e6   ; (0xCB35) = equipo del cambio
cuadro_partido:		; Un cuadro del partido: logica de los seis jugadores y, entre paso y paso, el servicio de VRAM pendiente
	di			;40e7   ; sin interrupciones mientras se mueve a los jugadores
	call lados_jugadores		;40e8   ; lado de la pista de cada uno
	call mueve_jugadores		;40eb   ; mueve y limita a los seis
	ei			;40ee   ; interrupciones otra vez
	call servicio_vram		;40ef   ; servicio de VRAM si ya llego la interrupcion
	call logica_jugadores		;40f2   ; mandos, maquina y poses
	call servicio_vram		;40f5   ; un cuadro
	call formacion		;40f8   ; formacion cada 32 cuadros
	call recoge_balon		;40fb   ; balon suelto: quien lo coge
	call servicio_vram		;40fe   ; un cuadro
	call desplaza_ventana		;4101   ; desplaza la ventana o refresca el marcador
	call desplaza_ventana		;4104
	call servicio_vram		;4107   ; un cuadro
	call ordena_profundidad		;410a   ; orden de pintado
	call servicio_vram		;410d   ; un cuadro
	call vuelca_sprites		;4110   ; ordena y copia los sprites a 0x1B00 y 0x1F00
	call servicio_vram		;4113   ; un cuadro
	ld hl,0c5e7h		;4116   ; cuenta de cuadros del partido
	inc (hl)			;4119   ; un cuadro mas
	ld a,(0c605h)		;411a   ; en la demo cualquier disparo
	and a			;411d   ; 0 = partido de verdad
	ret z			;411e   ; no esta activo: nada
	call lee_disparo		;411f   ; en la demo, un disparo la corta
	ret z			;4122   ; sin disparo: nada
	call fin_demo		;4123   ; corta la demo y vuelve al titulo
	jp vuelta_al_titulo		;4126   ; al titulo
fin_de_partido:		; GAME OVER: decide el ganador, toca su pieza y los ganadores saltan hasta que se pulse algo
	call rotulo_game_over		;4129   ; rotulo GAME OVER en el marcador
	call pausa_final		;412c   ; dos segundos de pausa con el balon fuera de la pista (la primera version dejaba seguir el juego 120 cuadros)
	ld b,0ffh		;412f   ; B = 0xFF: empate
	ld a,(0c7f3h)		;4131   ; puntos del equipo izquierdo
	ld hl,0c823h		;4134   ; contra los del derecho
	cp (hl)			;4137   ; izquierdo contra derecho
	jr z,L_413E		;4138
	inc b			;413a   ; B = 0
	jr nc,L_413E		;413b   ; el izquierdo tiene mas: gana el
	inc b			;413d   ; B = 1: gana el derecho
L_413E:
	ld a,b			;413e
	ld (0c606h),a		;413f   ; 0xFF empate, 0 gana el izquierdo, 1 gana el derecho
	inc b			;4142   ; Z si gano el izquierdo
	dec b			;4143
	jp m,L_416D		;4144   ; empate: pieza 0x0C
	ld hl,(0ed56h)		;4147   ; modos de los dos equipos (L izquierdo, H derecho)
	ld a,l			;414a   ; modo del izquierdo
	jr z,L_414E		;414b
	ld a,h			;414d   ; modo del derecho
L_414E:
	and a			;414e   ; el ganador tiene que tener un equipo propio
	jr nz,L_416D		;414f   ; el ganador no es el modo 0: pieza 0x0C
	inc b			;4151
	dec b			;4152
	ld a,h			;4153   ; modo del perdedor
	jr z,L_4157		;4154
	ld a,l			;4156
L_4157:
	cp 002h		;4157   ; el perdedor tiene que ser la maquina (modo 2)
	jr nz,L_416D		;4159
	inc b			;415b   ; de que lado es el perdedor
	dec b			;415c
	ld a,(0c61ah)		;415d   ; nivel del equipo izquierdo
	jr nz,L_4165		;4160
	ld a,(0c706h)		;4162   ; nivel del equipo derecho
L_4165:
	cp 008h		;4165   ; nivel del perdedor (roster +3) igual a 8
	jr nz,L_416D		;4167   ; no es la maquina de nivel 8
	ld a,00bh		;4169   ; pieza 0x0B: equipo propio gana a la maquina de nivel 8
	jr L_416F		;416b
L_416D:
	ld a,00ch		;416d   ; pieza 0x0C: final de partido normal
L_416F:
	call arranca_sonido		;416f   ; suena la pieza
	call oculta_balon		;4172   ; balon oculto
	call push_any_key		;4175   ; rotulo PUSH ANY KEY en la fila 23
celebra_ganadores:		; Bucle del GAME OVER: saltos al azar de los ganadores hasta pulsar un disparo
	call lee_disparo		;4178   ; disparo: se acabo
	jr nz,L_41D9		;417b
	ld a,007h		;417d   ; 7: balon de nadie
	ld (0c5dfh),a		;417f   ; SUPOSICION: 7 = nadie controlado
	ld ix,0c410h		;4182   ; IX = equipo izquierdo, IY = derecho
	ld iy,0c4a0h		;4186   ; IY = equipo derecho
	ld a,(0c606h)		;418a   ; resultado
	and a			;418d
	jp m,L_41D1		;418e   ; empate: nadie salta
	jr z,L_419B		;4191   ; gana el izquierdo
	ld ix,0c4a0h		;4193   ; gana el derecho: se cambian los papeles
	ld iy,0c410h		;4197   ; IY = equipo izquierdo
L_419B:
	ld b,003h		;419b   ; tres jugadores por equipo
L_419D:
	ld a,(ix+00ch)		;419d   ; ya esta en el aire
	and a			;41a0   ; en el aire?
	jr nz,L_41BE		;41a1
	call azar_r		;41a3   ; una vez de cada cuatro al azar
	and 003h		;41a6   ; 3 de cada 4 veces no salta
	jr nz,L_41BE		;41a8
	ld (ix+00ch),00fh		;41aa   ; gravedad del salto
	ld (ix+00ah),04ah		;41ae   ; velocidad vertical inicial 0x14A
	ld (ix+00bh),001h		;41b2   ; (velocidad 0x14A)
	ld (ix+00dh),052h		;41b6   ; pose 0x52: salto
	set 7,(ix+00fh)		;41ba   ; pose cambiada
L_41BE:
	ld (iy+020h),07fh		;41be   ; SUPOSICION: destino Y 0x7F (+0x20) del perdedor
	ld a,(iy+003h)		;41c2   ; X del perdedor
	ld (iy+021h),a		;41c5   ; como destino X
	ld de,00030h		;41c8   ; siguiente jugador (registros de 0x30)
	add ix,de		;41cb   ; siguiente ganador
	add iy,de		;41cd   ; siguiente perdedor
	djnz L_419D		;41cf
L_41D1:
	call cuadro_partido		;41d1   ; un cuadro
	call recoloca_fuera_de_pista		;41d4   ; SUPOSICION: los que salen por la derecha vuelven a la pista
	jr celebra_ganadores		;41d7
L_41D9:
	call borra_jugada		;41d9   ; nueva pantalla: borra el partido
	call guarda_resultado		;41dc   ; SUPOSICION: guarda el resultado del partido
	jp vuelta_al_titulo		;41df
final_de_mitad:		; Pitido de final de mitad; tras la primera, HALF TIME y vuelta a empezar; tras la segunda, GAME OVER
	ld a,006h		;41e2
	call arranca_sonido		;41e4   ; pieza 6: bocina de final
	ld a,001h		;41e7   ; bloquea mandos, ataque, defensa, movimiento y tiro
	ld (0cb31h),a		;41e9
	ld (0cb2eh),a		;41ec
	ld (0cb2fh),a		;41ef
	ld (0cb30h),a		;41f2
	ld (0cb32h),a		;41f5
L_41F8:
	ld a,(0c53ch)		;41f8   ; balon libre (gravedad): se deja caer antes del pitido final
	and a			;41fb
	push af			;41fc
	call nz,cuadro_partido		;41fd   ; deja que caiga
	pop af			;4200
	jr nz,L_41F8		;4201
	ld a,(0ed66h)		;4203   ; numero de mitad: 0 la primera
	and a			;4206   ; Z: primera mitad
	jp nz,fin_de_partido		;4207   ; acabo la segunda: GAME OVER
	call rotulo_half_time		;420a   ; rotulo HALF TIME
	call pausa_final		;420d
	ld a,007h		;4210
	ld (0c5dfh),a		;4212
	ld a,07fh		;4215   ; destino Y 0x7F
	ld hl,0c413h		;4217   ; X del primer jugador (+3)
	ld b,006h		;421a   ; los seis jugadores
L_421C:
	ld c,(hl)			;421c   ; X del jugador
	ld de,0001dh		;421d
	add hl,de			;4220   ; destino Y (+0x20)
	ld (hl),a			;4221   ; SUPOSICION: destino (Y 0x7F, X la suya) en +0x20/+0x21
	inc hl			;4222
	ld (hl),c			;4223   ; destino X (+0x21) = la suya
	ld de,00012h		;4224   ; siguiente registro
	add hl,de			;4227
	djnz L_421C		;4228
L_422A:
	call cuadro_partido		;422a   ; se van a la banda
	call todos_llegaron		;422d   ; SUPOSICION: Z cuando todos han llegado al destino
	jr z,L_4237		;4230   ; todos llegaron
	call recoloca_fuera_de_pista		;4232   ; los que pasan de la banda se quedan en ella
	jr L_422A		;4235
L_4237:
	ld a,(0c605h)		;4237   ; demo?
	and a			;423a
	jr z,L_4243		;423b   ; partido de verdad: sigue
	call fin_demo		;423d   ; en la demo vuelve al titulo
	jp vuelta_al_titulo		;4240
L_4243:
	call push_any_key		;4243   ; rotulo PUSH ANY KEY
	ld a,00ah		;4246   ; pieza 0x0A
	call arranca_sonido		;4248
L_424B:
	call lee_disparo		;424b   ; espera un disparo
	jr z,L_424B		;424e
	ld hl,0ed66h		;4250   ; segunda mitad
	inc (hl)			;4253   ; mitad 1
	call congela_sprites		;4254
	call oculta_sprites		;4257   ; sin sprites
	call cambios		;425a   ; SUPOSICION: pantalla entre mitades
	call congela_sprites		;425d
	call inicia_mitad		;4260   ; reloj de la segunda mitad
	call suelta_sprites		;4263
	call muestra_balon		;4266   ; balon visible
	call borra_jugada		;4269   ; jugadores parados
	call inicia_partido		;426c   ; variables de jugada
	jp L_409F		;426f   ; al bucle del partido
pausa_final:		; Retira el balon de la pista y espera dos segundos: la interrupcion baja (0xC600) hasta cero
	call oculta_balon		;4272   ; sin balon en la pista
	ld hl,00078h		;4275   ; dos segundos de espera
	ld (0c600h),hl		;4278
L_427B:
	ld hl,(0c600h)		;427b   ; la baja la interrupcion
	ld a,h			;427e
	or l			;427f
	jr nz,L_427B		;4280
	ret			;4282
arranca_demo:		; Demo del titulo: equipos de la maquina y partido con la bandera 0xC605 a 1
	call congela_sprites		;4283
	call prepara_demo		;4286   ; equipos de la demo
	call borra_jugada		;4289   ; jugadores parados
	call inicia_partido		;428c   ; variables de jugada
	ld a,001h		;428f
	ld (0c605h),a		;4291   ; 1 = demo
	jp L_4080		;4294   ; arranca el partido
recoloca_fuera_de_pista:		; SUPOSICION: los jugadores con Y mayor de 0x77 se paran y se colocan en la X (0xC5D6) negada
	ld b,006h		;4297   ; seis jugadores
	ld ix,0c410h		;4299   ; primer registro de jugador
	ld de,00030h		;429d
	ld hl,0c5d6h		;42a0   ; SUPOSICION: X de la canasta
L_42A3:
	ld a,077h		;42a3   ; limite de la banda
	cp (ix+001h)		;42a5   ; Y del jugador (+1)
	jr nc,L_42CA		;42a8   ; Y no pasa de 0x77
	ld (ix+020h),000h		;42aa   ; SUPOSICION: destino borrado
	ld (ix+021h),000h		;42ae   ; sin destino X
	ld (ix+004h),000h		;42b2   ; velocidades Y (+4/+5) y X (+6/+7) a cero
	ld (ix+005h),000h		;42b6
	ld (ix+006h),000h		;42ba
	ld (ix+007h),000h		;42be
	ld a,(0c5d6h)		;42c2
	neg		;42c5
	ld (ix+003h),a		;42c7   ; X opuesta a la canasta
L_42CA:
	add ix,de		;42ca   ; siguiente registro
	djnz L_42A3		;42cc
	ret			;42ce

; ----------------------------------------------------------------------
; ===== Comienzo de cada mitad: pista, marcador y salto entre dos =====
; ----------------------------------------------------------------------
monta_partido:		; Pista en 0xCB3D, ventana centrada, marcador y salto entre dos; despues da el control al equipo que se queda el balon
	call descomprime_mapa		;42cf   ; pista de 56 columnas
	ld a,00ch		;42d2   ; ventana en la columna 12 (el centro)
	ld (0ece5h),a		;42d4   ; columna de la ventana
	ld a,080h		;42d7   ; X fina en el centro
	ld (0ece6h),a		;42d9   ; X fina
	xor a			;42dc   ; desplazamiento 0
	call copia_ventana		;42dd   ; copia la ventana sin moverla
	call congela_sprites		;42e0   ; tabla de sprites fija mientras se pinta
	call monta_marcador		;42e3   ; marcador completo
	call suelta_sprites		;42e6
	ld hl,0012ch		;42e9   ; 300 cuadros para el salto entre dos
	ld (0c600h),hl		;42ec   ; cuenta atras del salto
	ld a,001h		;42ef   ; 1 = salto entre dos en marcha
	ld (0c602h),a		;42f1
bucle_salto_entre_dos:		; Cuadros del salto inicial hasta que alguien se queda el balon
	call salto_entre_dos		;42f4   ; logica del salto inicial
	call servicio_vram		;42f7   ; servicio de VRAM
	call ordena_profundidad		;42fa   ; orden de pintado
	call servicio_vram		;42fd
	call vuelca_sprites		;4300   ; sprites
	ld a,(0c602h)		;4303   ; 0 = ya hay poseedor
	and a			;4306
	jr nz,bucle_salto_entre_dos		;4307
	ld a,(0c5dfh)		;4309   ; jugador con el balon (bits 0-2)
	push af			;430c
	cp 003h		;430d   ; 0-2 equipo izquierdo, 3-5 derecho
	jr nc,L_431A		;430f   ; 3-5: equipo derecho
	call registro_jugador		;4311   ; registro del poseedor
	call controla_poseedor		;4314   ; controla a quien tiene el balon
	xor a			;4317   ; ataca el equipo izquierdo
	jr L_4322		;4318
L_431A:
	call registro_jugador		;431a   ; registro del poseedor
	call controla_poseedor		;431d
	ld a,001h		;4320   ; ataca el equipo derecho
L_4322:
	ld (0ecf1h),a		;4322   ; bit 0 = equipo con el balon
	ld de,00025h		;4325   ; +0x25: su defensor emparejado, que pasa a controlarse
	add hl,de			;4328
	ld a,(hl)			;4329   ; su par
	call controla		;432a   ; controlado del otro equipo
	pop af			;432d
	ld (0c5e2h),a		;432e   ; SUPOSICION: ultimo poseedor
	call destinos_defensa		;4331   ; SUPOSICION: destinos de los que no tienen el balon
	call reloj_en_marcha		;4334   ; reloj en marcha
	call cuenta_10s		;4337   ; cuenta de 10 segundos
	jp cuenta_30s		;433a   ; y la de 30 segundos
controla_poseedor:		; Pasa el control al jugador A y lo apunta en los bits bajos de 0xC5DF
	call controla		;433d
	ld c,a			;4340
	ld a,(0c5d0h)		;4341   ; bits altos de salida (desplazamiento de ventana)
	or c			;4344
	ld (0c5dfh),a		;4345   ; poseedor
	ret			;4348
logica_jugadores:		; Recorre los seis jugadores: mando o maquina, pose y velocidad de cada uno; despues la animacion de la red
	call elige_receptor		;4349   ; elige y marca el receptor del pase
	ld ix,0c410h		;434c   ; primer registro
	exx			;4350
	ld b,006h		;4351   ; seis jugadores
	ld c,000h		;4353   ; C' = numero de jugador
L_4355:
	ld a,c			;4355   ; jugador en curso (0-5)
	ld (0ebd6h),a		;4356   ; jugador en curso
	ld hl,00000h		;4359
	exx			;435c
	ld c,03fh		;435d   ; sin direccion
	ld de,00000h		;435f   ; sin movimiento
	ex af,af'			;4362
	ld a,000h		;4363   ; A' = equipo izquierdo
	ex af,af'			;4365
	exx			;4366
	ld a,(0c5e8h)		;4367   ; controlado del equipo izquierdo
	cp c			;436a   ; es el controlado izquierdo?
	push af			;436b
	exx			;436c
	call z,lee_mando		;436d   ; si es el: lo mueve el mando
	pop af			;4370
	jr z,L_438B		;4371   ; ya movido por el mando
	exx			;4373
	ld a,(0c5ebh)		;4374   ; controlado del equipo derecho
	cp c			;4377   ; es el controlado derecho?
	push af			;4378
	exx			;4379
	ex af,af'			;437a
	ld a,001h		;437b   ; A' = equipo derecho
	ex af,af'			;437d
	call z,lee_mando		;437e   ; lo mueve el mando
	pop af			;4381
	jr z,L_438B		;4382   ; ya movido por el mando
	exx			;4384
	ld a,c			;4385   ; A = numero de jugador
	exx			;4386
	call maquina		;4387   ; los demas: la maquina
	ex af,af'			;438a
L_438B:
	ex af,af'			;438b   ; pose pedida a A'
	call decide_accion		;438c   ; decide la accion y la pose
	call aplica_pose		;438f   ; aplica pose y velocidad
	exx			;4392
	ld de,00030h		;4393   ; siguiente registro
	add ix,de		;4396   ; siguiente registro
	inc c			;4398   ; siguiente numero
	djnz L_4355		;4399
	exx			;439b
	ld a,(0c543h)		;439c   ; paso de la animacion de la red
	and a			;439f   ; negativo: red parada
	ret m			;43a0
	ld e,a			;43a1
	ld d,000h		;43a2
	ld hl,043adh		;43a4   ; patrones de red 0x60, 0x64, 0x68
	add hl,de			;43a7
	ld a,(hl)			;43a8   ; patron de este paso
	ld (0c5c2h),a		;43a9   ; patron de la red en curso
	ret			;43ac

; ----------------------------------------------------------------------
; DATOS cuadros_e6b2: Cinco numeros de patron (0x60 0x64 0x68 0x64 0x60):
;   0x43A4 copia a 0xC5C2 el de indice (0xC543)
;   0x43ad..0x43b2  (5 bytes)
DATA_cuadros_e6b2:
	defb 060h,064h,068h,064h,060h	; 43ad

; ======================================================================
; CODIGO 0x43b2..0x4c13  (2145 bytes)
; ======================================================================


aplica_pose:		; Guarda la pose de A' (+0x0D), su direccion (+0x15) y convierte la direccion DE en velocidades Y (+4/+5) y X (+6/+7)
	ei			;43b2
	ex af,af'			;43b3   ; A = pose pedida
	ld (ix+00dh),a		;43b4   ; pose nueva
	rrca			;43b7   ; bits 2-4 de la pose: direccion 0-7
	rrca			;43b8
	and 007h		;43b9
	ld c,a			;43bb
	ld (0ebdch),a		;43bc   ; direccion en curso
	ld a,d			;43bf   ; hay direccion?
	or e			;43c0
	push bc			;43c1
	jr z,L_43CF		;43c2
	ld a,(0ebd6h)		;43c4   ; jugador en curso
	ld b,a			;43c7
	ld a,(0cb2eh)		;43c8   ; sin bloqueo de movimiento
	and a			;43cb
	call z,bloqueo_pase		;43cc   ; poseedor: se para un instante o rodea
L_43CF:
	pop bc			;43cf
	ld (ix+015h),c		;43d0   ; direccion del jugador
	ld l,a			;43d3   ; L = bits de la pose
	ld a,d			;43d4   ; hay movimiento?
	or e			;43d5
	jr nz,L_43DD		;43d6
	ld hl,00000h		;43d8   ; parado: velocidad cero
	jr L_43F5		;43db
L_43DD:
	bit 0,l		;43dd   ; bit 0: velocidad con balon o sin el
	jr nz,L_43EC		;43df
	ld l,(ix+010h)		;43e1   ; velocidad +0x10/+0x11
	ld h,(ix+011h)		;43e4   ; velocidad sin balon (+0x10/+0x11)
	call ajusta_velocidad		;43e7   ; menos la fatiga
	jr L_43F5		;43ea
L_43EC:
	ld l,(ix+012h)		;43ec   ; velocidad +0x12/+0x13
	ld h,(ix+013h)		;43ef   ; velocidad con balon (+0x12/+0x13)
	call ajusta_velocidad		;43f2   ; menos la fatiga
L_43F5:
	push hl			;43f5
	ld a,d			;43f6   ; signo de la direccion Y
	and a			;43f7
	call z,cero_hl		;43f8   ; D = 0: sin velocidad Y
	call m,niega_hl		;43fb   ; D negativo: velocidad negada
	ld (ix+004h),l		;43fe   ; velocidad Y
	ld (ix+005h),h		;4401   ; (byte alto)
	pop hl			;4404
	ld a,e			;4405   ; signo de la direccion X
	and a			;4406
	call z,cero_hl		;4407   ; E = 0: sin velocidad X
	call m,niega_hl		;440a   ; X hacia atras
	ld (ix+006h),l		;440d   ; velocidad X
	ld (ix+007h),h		;4410   ; (byte alto)
	ret			;4413
cero_hl:		; HL = 0
	ld hl,00000h		;4414
	ret			;4417
niega_hl:		; HL = -HL
	ld a,h			;4418   ; complemento a dos de HL
	cpl			;4419
	ld h,a			;441a
	ld a,l			;441b
	cpl			;441c
	ld l,a			;441d
	inc hl			;441e
	ret			;441f
niega_hl_huerfano:		; Huerfano: negaria H y L por separado (no es -HL)
	ld a,h			;4420   ; niega cada byte (no es -HL)
	neg		;4421
	ld h,a			;4423
	ld a,l			;4424
	neg		;4425
	ld l,a			;4427
	ret			;4428
ajusta_velocidad:		; Resta a la velocidad HL un valor del roster (campo 0x20) del jugador +0x1F en el equipo con el balon
	push de			;4429
	push hl			;442a
	ld a,(0ecf1h)		;442b   ; equipo con el balon en el bit 7
	rrca			;442e
	or (ix+01fh)		;442f   ; jugador del roster
	ld (0ed4dh),a		;4432   ; equipo para 0x71B6
	ld c,020h		;4435   ; campo 0x20 del roster
	call campo_equipo		;4437   ; cuenta 0x20: cansancio del jugador
	inc hl			;443a
	ld l,(hl)			;443b   ; byte alto del cansancio
	ld h,000h		;443c
	ld d,008h		;443e
	call divide8		;4440   ; cansancio / 8
	ld h,000h		;4443
	call niega_hl		;4445   ; se resta
	pop de			;4448
	add hl,de			;4449   ; velocidad menos el cansancio
	pop de			;444a
	ret			;444b
bloqueo_pase:		; SUPOSICION: el poseedor se queda parado un cuadro de cada ocho; si un rival esta delante cambia de direccion
	ld a,(0c5dfh)		;444c   ; poseedor
	and 007h		;444f
	cp b			;4451   ; es el jugador en curso?
	jr nz,L_4460		;4452
	ld a,(0c5e7h)		;4454   ; cuenta de cuadros del partido
	and 007h		;4457   ; uno de cada ocho cuadros
	jr nz,L_4460		;4459
	ld de,00000h		;445b   ; se para ese cuadro
	and a			;445e
	ret			;445f
L_4460:
	push de			;4460
	call rival_delante		;4461   ; rival cerca en la direccion de avance?
	pop de			;4464
	ret nc			;4465
	ld a,(0ebdch)		;4466   ; direccion en curso
	push af			;4469
	call maquina_roba		;446a   ; la maquina intenta robar
	push bc			;446d
	push hl			;446e
	ld b,002h		;446f   ; gira dos pasos a un lado
	ld hl,0ebcfh		;4471   ; bit 7 de la cuenta: gira a un lado o al otro
	bit 7,(hl)		;4474   ; bit 7 de la cuenta de cuadros
	jr z,L_447A		;4476
	ld b,0feh		;4478   ; o dos al otro
L_447A:
	add a,b			;447a
	and 007h		;447b   ; direccion nueva
	pop hl			;447d
	pop bc			;447e
	call vector_direccion		;447f   ; SUPOSICION: direccion corregida en DE
	pop af			;4482
	ret			;4483
lee_mando:		; Jugador controlado por un humano: lee su mando segun 0xEF98 y guarda la entrada del equipo
	ld a,(0cb31h)		;4484   ; SUPOSICION: mandos bloqueados durante la falta
	and a			;4487   ; mandos bloqueados: lo lleva la maquina
	jp nz,maquina		;4488
	call controlado		;448b   ; poseedor del equipo con el balon
	ld b,a			;448e   ; controlado del equipo con el balon
	ld a,(0ebd6h)		;448f
	cp b			;4492   ; el jugador en curso?
	jr nz,L_44AB		;4493
	ld a,(0c5dfh)		;4495   ; pase en vuelo?
	bit 6,a		;4498
	jr z,L_44A4		;449a
	ld a,(0c616h)		;449c   ; formacion en curso
	cp 03fh		;449f
	jp nz,maquina		;44a1   ; con formacion en curso, la maquina
L_44A4:
	ld a,(0cb24h)		;44a4   ; reboteador del ataque
	and a			;44a7
	jp p,maquina		;44a8   ; va al rebote: la maquina
L_44AB:
	ex af,af'			;44ab   ; A = equipo
	and a			;44ac
	push af			;44ad
	call lee_mando_lado		;44ae   ; lee el mando del equipo A'
	ld b,a			;44b1   ; B = botones
	ld a,c			;44b2   ; C = direccion (0x3F ninguna)
	and 03fh		;44b3   ; direccion 0x3F = ninguna
	or b			;44b5
	ld c,a			;44b6
	pop af			;44b7
	jr nz,L_44C6		;44b8   ; equipo derecho
	ld a,b			;44ba
	ld (0c5e3h),a		;44bb   ; entrada del equipo izquierdo
	exx			;44be
	ld hl,(0c5ech)		;44bf   ; registro del controlado del otro equipo
	exx			;44c2
	ex af,af'			;44c3
	jr L_44D0		;44c4
L_44C6:
	ld a,b			;44c6
	ld (0c5e5h),a		;44c7   ; entrada del equipo derecho
	exx			;44ca
	ld hl,(0c5e9h)		;44cb   ; registro del controlado del otro equipo
	exx			;44ce
	ex af,af'			;44cf
L_44D0:
	push ix		;44d0
	pop hl			;44d2
	push af			;44d3
	ld a,(0c616h)		;44d4
	cp 006h		;44d7
	jr c,L_44F9		;44d9
	ld a,c			;44db   ; direccion pedida
	and 03fh		;44dc
	cp 03fh		;44de   ; sin direccion
	jr z,L_44F9		;44e0
	call controlado		;44e2   ; controlado del equipo con el balon
	push hl			;44e5
	ld hl,0ebd6h		;44e6
	cp (hl)			;44e9   ; es el jugador en curso?
	pop hl			;44ea
	jr nz,L_44F9		;44eb
	ld a,(0cb1fh)		;44ed   ; formacion elegida
	and a			;44f0
	jr z,L_44F9		;44f1   ; ninguna
	dec a			;44f3   ; pide la formacion elegida (0xCB1F)
	set 7,a		;44f4
	ld (0c616h),a		;44f6   ; formacion pedida
L_44F9:
	pop af			;44f9
	ret			;44fa
maquina_roba:		; Defensor de la maquina: a veces intenta robar o taponar al poseedor si lo tiene delante
	push af			;44fb
	push de			;44fc
	ld a,(0ebd6h)		;44fd   ; jugador en curso
	ld b,a			;4500
	ld a,(0c5e8h)		;4501   ; es el controlado izquierdo?
	cp b			;4504
	jr z,L_450D		;4505
	ld a,(0c5ebh)		;4507   ; es el controlado derecho?
	cp b			;450a
	jr nz,L_4545		;450b   ; no es controlado: nada
L_450D:
	push hl			;450d
	ld a,b			;450e   ; equipo del jugador
	ld hl,0ed56h		;450f   ; modos de los equipos
	cp 003h		;4512
	jr c,L_4517		;4514
	inc hl			;4516
L_4517:
	ld a,(hl)			;4517   ; modo del equipo
	pop hl			;4518
	cp 002h		;4519   ; modo 2: no roba
	jr z,L_4545		;451b   ; modo 2: la maquina ya lo hace
	call hay_sitio_para_tirar		;451d   ; SUPOSICION: rival al alcance
	jr nc,L_4545		;4520   ; nadie al alcance
	ld de,0000fh		;4522
	ld a,(hl)			;4525   ; lado del rival
	xor (ix+00fh)		;4526   ; contra el del jugador
	bit 3,a		;4529   ; bit 3: mismo sentido de ataque
	jr nz,L_4545		;452b
	call aleatorio		;452d   ; una de cada cuatro veces
	and 003h		;4530
	jr nz,L_4545		;4532
	call puede_pasar		;4534   ; tiene linea de pase?
	jr nc,L_4545		;4537
	bit 3,(ix+00fh)		;4539   ; atacante o defensor
	push af			;453d
	call nz,pasa_al_companero_5		;453e   ; SUPOSICION: tapon del defensor
	pop af			;4541
	call z,pasa_a_un_companero		;4542   ; SUPOSICION: robo del atacante
L_4545:
	pop de			;4545
	pop af			;4546
	ret			;4547
rival_delante:		; Acarreo si algun otro jugador esta a menos de 8 en la direccion de avance
	ld a,b			;4548
	call registro_jugador		;4549   ; registro del jugador B
	call xy_registro		;454c   ; su posicion
	ld c,b			;454f   ; C = jugador a no mirar
	ld b,006h		;4550   ; los seis registros
	ld hl,0c410h		;4552   ; seis registros
	xor a			;4555
L_4556:
	cp c			;4556   ; no se compara consigo mismo
	push bc			;4557
	push hl			;4558
	call nz,mira_jugador		;4559   ; esta delante?
	pop hl			;455c
	pop bc			;455d
	ret c			;455e
	push de			;455f
	ld de,00030h		;4560   ; siguiente registro
	add hl,de			;4563
	pop de			;4564
	inc a			;4565   ; siguiente jugador
	djnz L_4556		;4566
	xor a			;4568   ; ninguno delante
	ret			;4569
mira_jugador:		; Distancia y rumbo al jugador A; acarreo si esta cerca y casi en la misma direccion
	ld b,a			;456a
	push bc			;456b
	push de			;456c
	push de			;456d
	call xy_registro		;456e   ; posicion del otro
	ex de,hl			;4571
	pop de			;4572
	call distancia_rumbo		;4573   ; distancia y rumbo
	cp 008h		;4576   ; a menos de 8
	call c,misma_direccion		;4578   ; y en la misma direccion?
	pop de			;457b
	pop bc			;457c
	ld a,b			;457d
	ret			;457e
misma_direccion:		; Acarreo si las direcciones 0xEBDC y 0xEBDD difieren menos de 2
	ld a,(0ebdch)		;457f   ; direccion del jugador
	ld b,a			;4582
	ld a,(0ebddh)		;4583   ; rumbo al otro
	sub b			;4586   ; diferencia
	jp p,L_458C		;4587
	neg		;458a   ; en valor absoluto
L_458C:
	cp 002h		;458c   ; acarreo si es menor de 2
	ret			;458e
distancia_rumbo:		; A = distancia entre los puntos DE y HL, (0xEBDD) = rumbo de uno a otro (0-7)
	call diferencia_xy		;458f   ; diferencias Y y X
	push de			;4592
	push hl			;4593
	call distancia		;4594   ; distancia
	pop hl			;4597
	pop de			;4598
	push af			;4599
	ld b,010h		;459a
	call rumbo		;459c   ; rumbo de 0 a 7
	ld (0ebddh),a		;459f   ; rumbo guardado
	pop af			;45a2
	ret			;45a3
diferencia_xy:		; H = diferencia de Y y L = diferencia de X entre los puntos de DE y HL
	push bc			;45a4
	ld b,e			;45a5
	ld c,l			;45a6
	call resta_con_signo		;45a7   ; diferencia de las Y
	push hl			;45aa
	ld d,b			;45ab
	ld h,c			;45ac
	call resta_con_signo		;45ad   ; diferencia de las X
	pop de			;45b0
	pop bc			;45b1
	ret			;45b2
resta_con_signo:		; HL = D - H con extension de signo
	ld a,d			;45b3
	call extiende_signo		;45b4   ; D con signo
	ex de,hl			;45b7
	ld a,d			;45b8
	call extiende_signo		;45b9   ; H con signo
	ex de,hl			;45bc
	sbc hl,de		;45bd   ; D - H
	ret			;45bf
xy_registro:		; D = Y (+1) y E = X (+3) del registro HL
	inc hl			;45c0
	ld d,(hl)			;45c1   ; Y (+1)
	inc hl			;45c2
	inc hl			;45c3
	ld e,(hl)			;45c4   ; X (+3)
	ret			;45c5
xy_dos_registros:		; D,E del registro DE y H,L del registro HL
	push bc			;45c6
	inc hl			;45c7
	ld b,(hl)			;45c8   ; Y del registro HL
	inc hl			;45c9
	inc hl			;45ca
	ld c,(hl)			;45cb   ; X del registro HL
	ex de,hl			;45cc
	inc hl			;45cd
	ld d,(hl)			;45ce   ; Y del registro DE
	inc hl			;45cf
	inc hl			;45d0
	ld e,(hl)			;45d1   ; X del registro DE
	ld h,b			;45d2
	ld l,c			;45d3
	pop bc			;45d4
	ret			;45d5
decide_accion:		; Accion del jugador en curso: con balon, sin balon, en el aire, pase, tiro o mate
	call servicio_vram		;45d6   ; servicio de VRAM entre jugador y jugador
	di			;45d9
	call marca_pose		;45da   ; marca pose cambiada
	call controlado		;45dd   ; controlado del equipo con el balon
	ld b,a			;45e0
	ld a,(0ebd6h)		;45e1
	cp b			;45e4   ; es el jugador en curso?
	jr nz,L_45EE		;45e5
	ld a,(0cb3ch)		;45e7   ; SUPOSICION: tiro automatico en cuenta atras
	and a			;45ea
	jp nz,tiro_automatico		;45eb   ; tiro automatico en marcha
L_45EE:
	ld a,(0ebd6h)		;45ee
	ld b,a			;45f1
	ld a,(0c5dfh)		;45f2   ; jugador con el balon
	and 007h		;45f5
	cp b			;45f7   ; es el poseedor?
	push af			;45f8
	call nz,sin_balon		;45f9   ; no es el: sin balon
	pop af			;45fc
	jp nz,suelta_boton		;45fd   ; sin balon: boton a cero
	call en_el_aire		;4600   ; en el aire?
	push af			;4603
	call nz,en_aire_con_balon		;4604   ; en el aire con balon
	pop af			;4607
	jp nz,suelta_boton		;4608   ; en el aire: boton a cero
	call cuadros_boton		;460b   ; cuadros que lleva pulsado el boton
	and a			;460e
	push af			;460f
	call z,anda		;4610   ; sin pulsar: anda o corre
	pop af			;4613
	jp z,suelta_boton		;4614   ; boton a cero
	bit 7,c		;4617   ; bit 7 de C: boton soltado
	push af			;4619
	call nz,soltado_con_balon		;461a   ; soltado: pasa o salta
	pop af			;461d
	ret nz			;461e
	call cuadros_boton		;461f   ; pulsacion corta: pase
	cp 00ch		;4622   ; menos de 12 cuadros
	push af			;4624
	call c,pase		;4625   ; pulsacion corta: pase
	pop af			;4628
	jp c,suelta_boton		;4629
	ld a,(0cb2bh)		;462c   ; SUPOSICION: pase forzado
	and a			;462f
	push af			;4630
	call p,pase		;4631   ; pase forzado
	pop af			;4634
	jp p,suelta_boton		;4635
	call pose_bit6		;4638   ; campo propio: no salta
	jp nz,anda		;463b   ; campo propio: corre botando
	call salta		;463e   ; pulsacion larga en campo contrario: salta
	jp suelta_boton		;4641
cuadros_boton:		; A = cuadros que el equipo del jugador en curso lleva con el boton pulsado
	ld a,(0ebd6h)		;4644
	cp 003h		;4647   ; equipo derecho?
	jr nc,L_464F		;4649
	ld a,(0c5e4h)		;464b   ; cuadros del izquierdo
	ret			;464e
L_464F:
	ld a,(0c5e6h)		;464f   ; cuadros del derecho
	ret			;4652
pon_cuadros_boton:		; Guarda A como cuadros de boton del equipo del jugador en curso
	push af			;4653
	ld a,(0ebd6h)		;4654
	cp 003h		;4657   ; equipo derecho?
	jr nc,L_4660		;4659
	pop af			;465b
	ld (0c5e4h),a		;465c   ; cuadros del izquierdo
	ret			;465f
L_4660:
	pop af			;4660
	ld (0c5e6h),a		;4661   ; cuadros del derecho
	ret			;4664
tiro_automatico:		; SUPOSICION: cuenta atras de (0xCB3C) cada 10 cuadros; al acabar tira o salta solo
	ld a,(ix+026h)		;4665   ; retardo del jugador
	and a			;4668
	ld hl,0cb3ch		;4669   ; pasos del tiro automatico
	jp nz,L_4674		;466c
	ld (ix+026h),00ah		;466f   ; diez cuadros entre pasos
	dec (hl)			;4673   ; un paso menos
L_4674:
	ld de,00000h		;4674   ; sin movimiento
	ld c,03fh		;4677   ; sin direccion
	ld a,(hl)			;4679
	dec a			;467a   ; paso 1: tira
	jp z,tira		;467b
	dec a			;467e   ; paso 2: salta
	jp z,tiro_al_caer		;467f
	dec a			;4682   ; paso 3: bota
	jp z,L_4AAC		;4683
	ret			;4686
tiro_al_caer:		; SUPOSICION: si el balon no esta en el aire salta con el
	ld a,(0c53ch)		;4687   ; balon ya en el aire?
	and a			;468a
	jr nz,tira		;468b
	call salta		;468d   ; salta con el
	ld (ix+00ch),000h		;4690   ; SUPOSICION: pero sin despegar
	ld (ix+00ah),000h		;4694
	ld (ix+00bh),000h		;4698
	ret			;469c
tira:		; Con el balon en la mano lanza a canasta
	ld a,(0c5dfh)		;469d   ; balon en vuelo?
	bit 7,a		;46a0
	jp nz,corre_al_balon		;46a2   ; a por el balon
	ld a,001h		;46a5   ; 1 = tiro forzado
	ld (0cb32h),a		;46a7   ; 1 = tiro forzado
	call lanza		;46aa   ; tira
	xor a			;46ad
	ld (0cb32h),a		;46ae   ; fin del tiro forzado
	ret			;46b1
elige_receptor:		; Calcula los datos de los dos companeros del poseedor en 0xC5F3 y 0xC5F8 y marca al mejor para el pase
	call quita_marca		;46b2   ; quita la marca anterior
	ld a,(0c5f2h)		;46b5   ; eleccion de receptor bloqueada
	and a			;46b8
	ret nz			;46b9
	ld a,(0c5dfh)		;46ba   ; bit 7 balon en vuelo, bit 6 pase
	and 0c7h		;46bd   ; bits del poseedor y del vuelo
	bit 7,a		;46bf   ; balon en vuelo
	ret nz			;46c1
	bit 6,a		;46c2   ; pase en vuelo
	ret nz			;46c4
	cp 007h		;46c5   ; nadie tiene el balon
	ret z			;46c7
	call registro_jugador		;46c8   ; registro del poseedor
	ld (0c5e0h),hl		;46cb   ; registro del poseedor
	exx			;46ce
	ld de,0c5f3h		;46cf   ; dos fichas de 5 bytes desde 0xC5F3
	exx			;46d2
	cp 003h		;46d3   ; equipo izquierdo?
	call c,fichas_izquierda		;46d5   ; companeros del equipo izquierdo
	call nc,fichas_derecha		;46d8   ; companeros del equipo derecho
	call companeros_a_tiro		;46db   ; mira cuales tiene a tiro
	dec c			;46de   ; C = companeros a tiro
	inc c			;46df
	ld a,0ffh		;46e0   ; ninguno a tiro
	jr z,L_4711		;46e2   ; ninguno
	ld a,003h		;46e4   ; los dos a tiro?
	cp c			;46e6
	jr nz,L_46FB		;46e7
	ld c,000h		;46e9
	ld a,(0c5f5h)		;46eb   ; el primero esta en la mitad del poseedor?
	and a			;46ee
	jr nz,L_470A		;46ef
	ld a,(0c5fah)		;46f1   ; y el segundo?
	and a			;46f4
	jr nz,L_46FB		;46f5
	ld a,h			;46f7   ; el mas alineado
	cp l			;46f8
	jr c,L_470A		;46f9
L_46FB:
	bit 0,c		;46fb   ; primero a tiro: se queda
	jr nz,L_470A		;46fd
	ld hl,0c5f8h		;46ff   ; el segundo pasa a ser el elegido
	ld de,0c5f3h		;4702   ; el segundo pasa a la primera ficha
	ld bc,00005h		;4705
	ldir		;4708
L_470A:
	ld hl,0c5f3h		;470a   ; receptor
	ld a,(hl)			;470d
	call marca_jugador		;470e   ; parpadea el receptor
L_4711:
	cp 0ffh		;4711   ; ninguno
	ret nz			;4713
	ld (0c5f3h),a		;4714   ; sin receptor
	ret			;4717
companeros_a_tiro:		; Bits 0 y 1 de C: companero 1 o 2 dentro de 0x40 de diferencia con la direccion del poseedor
	call rumbos_companeros		;4718
	exx			;471b
	ld de,(0c5e0h)		;471c   ; registro del poseedor
	ld hl,00015h		;4720
	add hl,de			;4723
	ld a,(hl)			;4724   ; direccion del poseedor (+0x15)
	exx			;4725
	add a,a			;4726   ; por 32: angulo de 0 a 255
	add a,a			;4727
	add a,a			;4728
	add a,a			;4729
	add a,a			;472a
	ld c,a			;472b
	cp h			;472c   ; diferencia con el companero 1
	jr nc,L_4732		;472d
	ld b,a			;472f
	ld a,h			;4730
	ld h,b			;4731
L_4732:
	sub h			;4732
	jp p,L_4738		;4733
	neg		;4736   ; en valor absoluto
L_4738:
	ld h,a			;4738
	ld a,c			;4739
	cp l			;473a   ; diferencia con el companero 2
	jr nc,L_4740		;473b
	ld b,a			;473d
	ld a,l			;473e
	ld l,b			;473f
L_4740:
	sub l			;4740
	jp p,L_4746		;4741
	neg		;4744   ; en valor absoluto
L_4746:
	ld l,a			;4746
	ld c,000h		;4747
	exx			;4749
	ld hl,0c5f4h		;474a   ; mitad del 1
	ld a,(hl)			;474d
	inc hl			;474e
	inc hl			;474f
	inc hl			;4750
	inc hl			;4751
	inc hl			;4752
	exx			;4753
	and a			;4754
	jp m,L_475F		;4755   ; otra mitad o centro: no
	ld a,040h		;4758   ; a menos de 0x40
	cp h			;475a
	jr c,L_475F		;475b
	set 0,c		;475d   ; bit 0: companero 1 a tiro
L_475F:
	exx			;475f
	ld a,(hl)			;4760   ; mitad del 2
	exx			;4761
	and a			;4762
	ret m			;4763
	ld a,040h		;4764   ; a menos de 0x40
	cp l			;4766
	ret c			;4767
	set 1,c		;4768   ; bit 1: companero 2 a tiro
	ret			;476a
rumbos_companeros:		; D, E = jugadores de las dos fichas; H, L = sus rumbos
	ld bc,0c5f3h		;476b   ; primera ficha
	ld a,(bc)			;476e
	ld d,a			;476f   ; D = jugador 1
	inc bc			;4770
	inc bc			;4771
	inc bc			;4772
	inc bc			;4773
	ld a,(bc)			;4774
	ld h,a			;4775   ; H = angulo 1
	inc bc			;4776
	ld a,(bc)			;4777
	ld e,a			;4778   ; E = jugador 2
	inc bc			;4779
	inc bc			;477a
	inc bc			;477b
	inc bc			;477c
	ld a,(bc)			;477d
	ld l,a			;477e   ; L = angulo 2
	ret			;477f
fichas_izquierda:		; Ficha de los dos companeros del jugador A (equipo 0-2)
	push af			;4780
	ld c,a			;4781   ; C = poseedor
	ld a,000h		;4782
	cp c			;4784
	ld a,c			;4785
	ld c,000h		;4786   ; companero 0
	call nz,ficha_companero		;4788
	ld c,001h		;478b   ; companero 1
	cp c			;478d
	call nz,ficha_companero		;478e
	ld c,002h		;4791   ; companero 2
	cp c			;4793
	call nz,ficha_companero		;4794
	pop af			;4797
	ret			;4798
fichas_derecha:		; Ficha de los dos companeros del jugador A (equipo 3-5)
	push af			;4799
	ld c,003h		;479a   ; companero 3
	cp c			;479c
	call nz,ficha_companero		;479d
	ld c,004h		;47a0   ; companero 4
	cp c			;47a2
	call nz,ficha_companero		;47a3
	ld c,005h		;47a6   ; companero 5
	cp c			;47a8
	call nz,ficha_companero		;47a9
	pop af			;47ac
	ret			;47ad
ficha_companero:		; Escribe en DE' la ficha del jugador C: numero, misma mitad (0) o no (0xFF), 0, rumbo de 0 a 7 y angulo fino menos 16
	ld b,a			;47ae
	push bc			;47af
	ld a,c			;47b0
	exx			;47b1
	ld (de),a			;47b2   ; numero de jugador
	inc de			;47b3
	exx			;47b4
	call registro_jugador		;47b5   ; registro del companero
	ld de,(0c5e0h)		;47b8   ; poseedor
	call xy_dos_registros		;47bc   ; posiciones
	call misma_mitad		;47bf   ; misma mitad o no
	exx			;47c2
	ld (de),a			;47c3
	inc de			;47c4
	exx			;47c5
	push de			;47c6
	push hl			;47c7
	call cero		;47c8   ; campo vacio
	pop hl			;47cb
	pop de			;47cc
	exx			;47cd
	ld (de),a			;47ce
	inc de			;47cf
	exx			;47d0
	call diferencia_xy		;47d1   ; rumbo desde el poseedor
	ld b,010h		;47d4
	call rumbo		;47d6   ; rumbo de 0 a 7
	exx			;47d9
	ld (de),a			;47da
	inc de			;47db
	ld a,(0c5d2h)		;47dc   ; angulo fino menos 16
	add a,0f0h		;47df
	ld (de),a			;47e1
	inc de			;47e2
	exx			;47e3
	pop bc			;47e4
	ld a,b			;47e5
	ret			;47e6
ficha_suelta:		; SUPOSICION: ficha de un solo jugador en 0xC5F3
	ld c,a			;47e7
	call registro_jugador		;47e8
	ld de,(0c5e0h)		;47eb   ; desde el poseedor
	exx			;47ef
	ld de,0c5f3h		;47f0   ; en la primera ficha
	exx			;47f3
	jp ficha_companero		;47f4
misma_mitad:		; 0 si el companero (L) esta en la misma mitad que el poseedor (E); 0xFF si esta en el centro (menos de 3) o en la otra
	ld a,l			;47f7   ; X del companero
	and a			;47f8
	jp p,L_47FE		;47f9
	neg		;47fc
L_47FE:
	cp 003h		;47fe   ; menos de 3: en el centro
	ld a,0ffh		;4800
	ret c			;4802
	ld a,l			;4803   ; en la misma mitad que el poseedor?
	xor e			;4804
	and a			;4805
	ld a,000h		;4806   ; 0: misma mitad
	ret p			;4808
	dec a			;4809   ; 0xFF: la otra mitad
	ret			;480a
cero:		; A = 0
	xor a			;480b
	ret			;480c
pase:		; Lanza el pase al receptor marcado: el receptor se gira hacia el poseedor y se para
	ld a,(0c5f3h)		;480d   ; receptor elegido
	cp 0ffh		;4810   ; 0xFF: sin receptor
	jp z,anda		;4812   ; nadie: no hay pase
	ld b,a			;4815
	ld a,(0ebd6h)		;4816   ; jugador en curso
	cp b			;4819   ; el receptor no puede ser el mismo
	jp z,anda		;481a
	ld a,(0cb32h)		;481d   ; SUPOSICION: tiro forzado en curso
	and a			;4820
	jp nz,anda		;4821   ; tiro forzado: no pasa
	ld a,(0c5dfh)		;4824   ; estado del balon
	or 047h		;4827   ; bit 6 = pase en vuelo, sin poseedor
	ld (0c5dfh),a		;4829
	call rumbo_receptor		;482c   ; C = rumbo al receptor
	ld a,c			;482f
	or 063h		;4830   ; pose de pase con su direccion
	push af			;4832
	push de			;4833
	ld a,(0c5f3h)		;4834   ; receptor
	call registro_jugador		;4837
	push hl			;483a
	pop iy		;483b
	ld a,(0c5f6h)		;483d   ; mira al que le pasa
	add a,004h		;4840   ; rumbo opuesto: mira al que pasa
	and 007h		;4842
	ld (iy+015h),a		;4844   ; direccion del receptor
	add a,a			;4847   ; a los bits 2-4 de la pose
	add a,a			;4848
	or 063h		;4849   ; pose de recibir
	ld (iy+00dh),a		;484b   ; pose de recibir
	xor a			;484e   ; sin destino ni velocidad
	ld (iy+020h),a		;484f   ; sin destino Y
	ld (iy+021h),a		;4852   ; sin destino X
	ld (iy+004h),a		;4855   ; sin velocidad Y
	ld (iy+005h),a		;4858
	ld (iy+006h),a		;485b   ; sin velocidad X
	ld (iy+007h),a		;485e
	call lanza_pase		;4861   ; trayectoria del balon
	pop de			;4864
	pop af			;4865
	ex af,af'			;4866   ; pose del que pasa a A'
	ret			;4867
rumbo_receptor:		; C = rumbo al receptor por 4 (campo de direccion de la pose)
	ld a,(0c5f6h)		;4868   ; rumbo al receptor (ficha +3)
	add a,a			;486b
	add a,a			;486c
	ld c,a			;486d
	ret			;486e
suelta_boton:		; Si el jugador en curso es el controlado de su equipo, pone a cero su cuenta de boton
	push af			;486f
	ld a,(0ebd6h)		;4870   ; jugador en curso
	ld b,a			;4873
	cp 003h		;4874   ; equipo derecho?
	jr nc,L_487D		;4876
	ld a,(0c5e8h)		;4878   ; controlado izquierdo
	jr L_4880		;487b
L_487D:
	ld a,(0c5ebh)		;487d   ; controlado derecho
L_4880:
	cp b			;4880   ; es el?
	jr nz,L_4887		;4881
	xor a			;4883
	call pon_cuadros_boton		;4884   ; cuadros de boton a cero
L_4887:
	pop af			;4887
	ret			;4888
sin_balon:		; Jugador sin balon: en el aire, recoge, defiende o corre
	call en_el_aire		;4889   ; en el aire?
	and a			;488c
	jr z,L_48AA		;488d   ; en el suelo
	ld a,(0ebd6h)		;488f   ; jugador en curso
	ld hl,0c5efh		;4892   ; SUPOSICION: el que tiro
	cp (hl)			;4895
	jp z,sigue_en_aire		;4896   ; el que tiro: sigue en el aire
	ld hl,0c5f0h		;4899   ; SUPOSICION: los que saltaron por el balon
	cp (hl)			;489c
	jp z,pose_en_aire		;489d   ; saltador del izquierdo: pose del aire
	ld hl,0c5f1h		;48a0   ; saltador del derecho
	cp (hl)			;48a3
	jp z,pose_en_aire		;48a4
	jp sigue_en_aire		;48a7   ; los demas siguen en el aire
L_48AA:
	ld a,(0c5dfh)		;48aa   ; alguien tiene el balon?
	bit 4,a		;48ad   ; bit 4 de 0xC5DF: la ventana se desplaza a la derecha (lo pone 0x52BA)
	jr nz,L_48CE		;48af   ; SUPOSICION: con la ventana en marcha solo se mira si es el receptor de un pase (0x48CE)
	cp 007h		;48b1   ; 7 o mas: nadie con el balon
	jr c,L_48E9		;48b3   ; hay poseedor: roba o tapona (0x48E9)
	bit 7,c		;48b5   ; balon suelto y sin boton: corre
	jr z,corre_al_balon		;48b7   ; boton sin soltar: corre al balon
	cp 007h		;48b9   ; 7: balon suelto
	jr z,L_48C4		;48bb
	exx			;48bd
	call en_el_aire		;48be   ; en el aire?
	exx			;48c1
	jr z,corre_al_balon		;48c2
L_48C4:
	call direccion_pose		;48c4   ; salta a por el balon
	ld a,c			;48c7   ; C = direccion
	or 042h		;48c8   ; pose de salto a por el balon
	ex af,af'			;48ca
	jp salto		;48cb   ; despega
L_48CE:
	ld a,(0c5f3h)		;48ce   ; es el receptor del pase?
	ld b,a			;48d1
	ld a,(0ebd6h)		;48d2   ; es el jugador en curso?
	cp b			;48d5
	jr nz,corre_al_balon		;48d6
	ld a,(ix+00dh)		;48d8   ; pose actual
	and 0e3h		;48db   ; accion y fotograma
	cp 063h		;48dd   ; sigue en pose de recibir
	jr nz,corre_al_balon		;48df
	push af			;48e1
	call direccion_pose		;48e2   ; sigue mirando igual
	pop af			;48e5
	or c			;48e6
	ex af,af'			;48e7
	ret			;48e8
L_48E9:
	bit 7,c		;48e9   ; boton soltado?
	jp nz,robo		;48eb   ; boton soltado: roba o tapona
corre_al_balon:		; Sin direccion pedida se gira hacia el balon; con direccion corre
	ld a,d			;48ee   ; hay direccion?
	or e			;48ef
	jp nz,corre		;48f0   ; si: corre
	push de			;48f3
	push ix		;48f4
	pop de			;48f6
	ld hl,0c530h		;48f7   ; registro del balon
	call xy_dos_registros		;48fa   ; posiciones del jugador y del balon
	call diferencia_xy		;48fd   ; diferencias
	ld b,010h		;4900
	call rumbo		;4902   ; rumbo al balon
	ld c,a			;4905
	call direccion_pose		;4906   ; C = rumbo por 4
	pop de			;4909
	bit 3,(ix+00fh)		;490a   ; bit 3: atacante
	jr nz,L_4914		;490e   ; defensor: pose 0x80
	or 080h		;4910
	ex af,af'			;4912
	ret			;4913
L_4914:
	or 061h		;4914   ; atacante: pose 0x61
	ex af,af'			;4916
	ret			;4917
robo:		; SUPOSICION: defensor que pulsa el boton intenta robar; la suerte depende de +0x1D
	ld a,(0c5fdh)		;4918   ; intento de robo pedido?
	and a			;491b
	jr z,L_4930		;491c
	xor a			;491e   ; atendido
	ld (0c5fdh),a		;491f
	call hay_sitio_para_tirar		;4922   ; al alcance del poseedor?
	jr nc,L_4930		;4925
	call aleatorio		;4927   ; sale bien si el azar es menor que +0x1D
	cp (ix+01dh)		;492a   ; el azar contra la habilidad (+0x1D)
	call c,roba_balon		;492d
L_4930:
	ld c,03fh		;4930   ; sin direccion
	call direccion_pose		;4932   ; mantiene la direccion
	or 081h		;4935   ; pose de robo, sin moverse
	ld de,00000h		;4937   ; sin movimiento
	ex af,af'			;493a
	ret			;493b
roba_balon:		; SUPOSICION: el balon cambia de manos: pitido, nuevo poseedor y relojes de 10 y 30 segundos a cero
	ld a,(0c602h)		;493c   ; no durante el salto entre dos
	and a			;493f   ; salto entre dos en marcha
	ret nz			;4940
	ld a,(0ece6h)		;4941   ; SUPOSICION: no con la ventana en el centro
	cp 080h		;4944   ; ventana en el centro: no
	ret z			;4946
	ld a,002h		;4947   ; pieza 2: robo
	call arranca_sonido		;4949
	call suelta_boton		;494c   ; boton a cero
	ld a,(0c616h)		;494f
	cp 03fh		;4952
	jr z,L_495B		;4954
	ld a,0ffh		;4956
	ld (0c5feh),a		;4958
L_495B:
	ld a,(0ebd6h)		;495b   ; el ladron
	push af			;495e
	push af			;495f
	call da_balon		;4960   ; nuevo poseedor
	call balon_quieto		;4963   ; balon parado
	ld (0c545h),a		;4966   ; SUPOSICION: canasta a la que ataca
	pop af			;4969
	call cuenta_10s		;496a   ; 10 segundos si esta en su campo
	pop af			;496d
	call fin_cuenta_10s		;496e   ; desactivada si esta en el contrario
	jp cuenta_30s		;4971   ; y 30 segundos
pose_en_aire:		; Pose 0x43 en el aire
	call direccion_actual		;4974
	or 043h		;4977   ; pose 0x43: en el aire
	ld de,00000h		;4979   ; sin movimiento
	ex af,af'			;497c
	ret			;497d
pose_en_aire_huerfano:		; Huerfano: pose del aire conservando la accion de +0x0D
	call direccion_actual		;497e
	call pose_actual		;4981
	and 0e3h		;4984   ; accion y fotograma de la pose
	or c			;4986
	ex af,af'			;4987
	ret			;4988
en_el_aire:		; NZ si el jugador IX esta en el aire (+0x0C gravedad)
	ld a,(ix+00ch)		;4989   ; gravedad (+0x0C)
	and a			;498c
	ret			;498d
en_aire_con_balon:		; En el aire con el balon: tira, pasa o machaca al soltar el boton
	push bc			;498e
	call pose_bit6		;498f   ; campo propio?
	pop bc			;4992
	call nz,suelta_boton		;4993   ; si: boton a cero
	jr nz,sigue_en_aire		;4996
	ld a,(0ed61h)		;4998   ; 1 = puede machacar
	cp 001h		;499b   ; 1: mate
	jr z,mate		;499d
	bit 7,c		;499f   ; boton aun pulsado
	jr z,lanza		;49a1
sigue_en_aire:		; Balon en lo alto del salto
	push de			;49a3
	push hl			;49a4
	ld hl,(0c5e0h)		;49a5   ; registro del poseedor
	ld a,h			;49a8
	or l			;49a9
	jr z,L_49B5		;49aa   ; nadie
	ld de,00009h		;49ac   ; altura del jugador
	add hl,de			;49af   ; altura (+9)
	ld a,(hl)			;49b0
	and a			;49b1
	call nz,balon_a_la_altura		;49b2   ; balon a su altura
L_49B5:
	pop hl			;49b5
	pop de			;49b6
	call direccion_giro		;49b7   ; C = direccion
	ld a,(0c53ch)		;49ba   ; balon libre?
	and a			;49bd
	push de			;49be
	ld de,04c23h		;49bf   ; posiciones del balon en la mano (0x4C23)
	call z,balon_en_mano		;49c2   ; en la mano: con el jugador
	pop de			;49c5
	call pose_actual		;49c6   ; pose actual
	and 0e3h		;49c9   ; accion y fotograma
	ld de,00000h		;49cb   ; sin movimiento
	or c			;49ce
	ex af,af'			;49cf
	ret			;49d0
balon_a_la_altura:		; SUPOSICION: altura del balon segun la del jugador
	ld a,(0c53ch)		;49d1   ; balon libre: no se toca
	and a			;49d4
	ret nz			;49d5
	ld a,0e3h		;49d6   ; 0xE3 mas la altura
	add a,(hl)			;49d8
	ld (0c53dh),a		;49d9   ; altura del balon
	ret			;49dc
lanza:		; Suelta el balon a canasta: trayectoria y balon en vuelo
	call direccion_giro		;49dd   ; C = direccion
	ld a,c			;49e0
	or 041h		;49e1   ; pose de tiro
	push af			;49e3
	call tiro		;49e4   ; SUPOSICION: calcula el tiro
	call al_rebote		;49e7   ; los mas cercanos van al rebote
	ld a,(0ebd6h)		;49ea
	ld (0c5efh),a		;49ed   ; jugador que tiro
	ld a,(0c5dfh)		;49f0   ; estado del balon
	or 087h		;49f3   ; balon en vuelo, sin poseedor
	ld (0c5dfh),a		;49f5
	ld de,00000h		;49f8   ; sin movimiento
	pop af			;49fb
	ex af,af'			;49fc
	ret			;49fd
mate:		; Machaque: balon directo a la canasta, red animada y tiro anotado
	ld a,(ix+00bh)		;49fe   ; todavia subiendo
	and a			;4a01   ; velocidad alta 0: ya no sube
	jp nz,sigue_en_aire		;4a02
	ld a,(0c5dfh)		;4a05   ; poseedor
	and 007h		;4a08
	cp 007h		;4a0a   ; sin balon no hay mate
	jp z,sigue_en_aire		;4a0c
	call direccion_giro		;4a0f   ; C = direccion
	ld a,c			;4a12
	or 041h		;4a13   ; pose de mate
	push af			;4a15
	ld a,(0ebd6h)		;4a16   ; el que machaca
	ld (0c5efh),a		;4a19   ; jugador que tiro
	ld (0ed64h),a		;4a1c   ; SUPOSICION: autor del mate
	ld a,001h		;4a1f   ; 1 = canasta pendiente
	ld (0ed67h),a		;4a21   ; SUPOSICION: canasta pendiente de anotar
	ld a,087h		;4a24   ; balon en vuelo
	ld (0c5dfh),a		;4a26   ; balon en vuelo, sin poseedor
	call cuenta_tiro		;4a29
	ld a,001h		;4a2c   ; balon camino de la canasta
	ld (0cb28h),a		;4a2e   ; canasta hecha
	ld a,00fh		;4a31   ; gravedad del balon
	ld (0c53ch),a		;4a33
	ld hl,0c5d3h		;4a36   ; posicion de la canasta
	call xy_registro		;4a39   ; canasta
	ld a,d			;4a3c
	ld (0c531h),a		;4a3d   ; balon en la Y de la canasta
	ld a,e			;4a40
	ld (0c533h),a		;4a41   ; y en su X
	xor a			;4a44   ; A = 0
	ld (0c53dh),a		;4a45   ; balon fuera de la mano
	ld (0c530h),a		;4a48   ; fracciones a cero
	ld (0c532h),a		;4a4b
	ld (0c607h),a		;4a4e   ; sin pasos
	dec a			;4a51
	ld (0cb27h),a		;4a52   ; sin reboteador
	ld hl,00000h		;4a55
	ld (0c536h),hl		;4a58   ; sin velocidad
	ld (0c534h),hl		;4a5b
	ld hl,0ff9ch		;4a5e   ; SUPOSICION: velocidad del balon -100
	ld (0c53ah),hl		;4a61
	ld a,004h		;4a64   ; cuatro botes al caer
	ld (0ed5fh),a		;4a66
	ld a,0cch		;4a69   ; altura del aro
	ld (0c539h),a		;4a6b   ; Z del balon a la altura del aro
	neg		;4a6e
	ld (0ed60h),a		;4a70   ; SUPOSICION: altura del aro en positivo
	ld a,00ah		;4a73   ; 10 cuadros por paso de la red
	ld (0c544h),a		;4a75
	xor a			;4a78
	ld (0c543h),a		;4a79   ; arranca la animacion de la red
	ld hl,0c5e3h		;4a7c   ; boton 1 del izquierdo soltado
	res 7,(hl)		;4a7f   ; botones soltados
	ld hl,0c5e5h		;4a81   ; boton 1 del derecho
	res 7,(hl)		;4a84
	ld de,00000h		;4a86   ; sin movimiento
	pop af			;4a89
	ex af,af'			;4a8a
	ret			;4a8b
pose_actual:		; A = pose (+0x0D) del jugador IX
	ld a,(ix+00dh)		;4a8c
	ret			;4a8f
soltado_con_balon:		; Boton soltado con el balon: en campo propio pasa, en el contrario pasa o salta
	push bc			;4a90
	call pose_bit6		;4a91   ; campo propio?
	pop bc			;4a94
	jr z,bote		;4a95   ; campo contrario: bota o salta
	call suelta_boton		;4a97   ; boton a cero
	ld a,(0c5f3h)		;4a9a   ; hay receptor?
	inc a			;4a9d
	jp z,anda		;4a9e   ; no: sigue botando
	jp pase		;4aa1   ; pasa
bote:		; SUPOSICION: pulsacion corta en campo contrario: bota el balon en la mano
	call cuadros_boton		;4aa4   ; cuadros pulsado
	cp 00ch		;4aa7   ; 12 o mas: salta
	jp nc,salta		;4aa9
L_4AAC:
	push de			;4aac
	call direccion_pose		;4aad   ; C = direccion
	ld de,04c23h		;4ab0   ; posiciones de la mano
	call balon_en_mano		;4ab3
	pop de			;4ab6
	call balon_bajo		;4ab7   ; balon bajo
	ld a,c			;4aba
	or 062h		;4abb   ; pose de bote parado
	ex af,af'			;4abd
	ret			;4abe
balon_bajo:		; Altura del balon en la mano 0xF0
	ld a,0f0h		;4abf
	ld (0c53dh),a		;4ac1
	ret			;4ac4
salta:		; Salto del poseedor con el balon
	ld a,(0cb32h)		;4ac5   ; tiro forzado?
	and a			;4ac8
	jp nz,lanza		;4ac9   ; si: tira
	push de			;4acc
	call direccion_pose		;4acd   ; C = direccion
	ld de,04c23h		;4ad0   ; posiciones de la mano
	call balon_en_mano		;4ad3
	pop de			;4ad6
	call balon_alto		;4ad7   ; balon alto
	ld a,c			;4ada
	or 040h		;4adb   ; pose de salto
	ld de,00000h		;4add   ; sin movimiento
	push af			;4ae0
	call salto		;4ae1   ; despega
	call giro_al_aro		;4ae4   ; se gira al aro en el aire
	pop af			;4ae7
	ex af,af'			;4ae8
	ret			;4ae9
balon_alto:		; Altura del balon en la mano 0xE3
	ld a,0e3h		;4aea
	ld (0c53dh),a		;4aec
	ret			;4aef
giro_al_aro:		; En el aire se va girando hacia la canasta: pasos (+0x14), rumbo (+0x16) y sentido (+0x18)
	push af			;4af0
	push de			;4af1
	push ix		;4af2
	pop de			;4af4
	ld hl,0c5d3h		;4af5   ; canasta
	call xy_dos_registros		;4af8   ; jugador y canasta
	ld b,010h		;4afb
	call rumbo_entre		;4afd   ; rumbo a la canasta
	ld (ix+014h),006h		;4b00   ; seis pasos de giro
	ld (ix+016h),a		;4b04   ; rumbo de destino
	ld b,a			;4b07
	ld a,(ix+015h)		;4b08   ; direccion actual
	ld (ix+017h),a		;4b0b   ; como direccion de giro
	ld c,a			;4b0e
	call sentido_giro		;4b0f   ; sentido de giro
	ld (ix+018h),a		;4b12   ; sentido del giro
	pop de			;4b15
	pop af			;4b16
	ret			;4b17
sentido_giro:		; 1 si el rumbo B esta a menos de media vuelta a la derecha de C, si no 0xFF
	ld a,b			;4b18   ; destino menos actual
	sub c			;4b19
	and 007h		;4b1a
	cp 004h		;4b1c   ; menos de media vuelta
	jr nc,L_4B23		;4b1e
	ld a,001h		;4b20   ; 1: a la derecha
	ret			;4b22
L_4B23:
	ld a,0ffh		;4b23   ; 0xFF: a la izquierda
	ret			;4b25
anda:		; Poseedor sin pulsar: bota el balon parado o corriendo
	ld a,(0c603h)		;4b26   ; bote forzado?
	and a			;4b29
	jp nz,L_4AAC		;4b2a   ; SUPOSICION: forzado a botar
	ld a,(0ece7h)		;4b2d   ; balon oculto: corre sin el
	and a			;4b30
	jp nz,corre_al_balon		;4b31
	xor a			;4b34
	ld (0c53ch),a		;4b35   ; balon en la mano
	ld (0c53dh),a		;4b38   ; balon a ras de la mano
	ld a,d			;4b3b   ; hay direccion?
	or e			;4b3c
	jp nz,corre_botando		;4b3d   ; hay direccion: corre
	call direccion_pose		;4b40   ; C = direccion
	push de			;4b43
	ld de,04c13h		;4b44   ; posiciones del bote (0x4C13)
	call balon_en_mano		;4b47   ; balon junto al jugador
	call paso_bote		;4b4a   ; fotograma del bote
	pop de			;4b4d
	call sonido_bote		;4b4e   ; suena el bote
	ld a,c			;4b51
	or 060h		;4b52   ; pose parado botando
	ex af,af'			;4b54
	ret			;4b55
paso_bote:		; Cada 4 cuadros cambia el fotograma del bote
	push hl			;4b56
	ld hl,0ebcfh		;4b57   ; cuenta de cuadros
	bit 2,(hl)		;4b5a   ; bit 2
	pop hl			;4b5c
	ret z			;4b5d
	inc c			;4b5e   ; fotograma siguiente
	ret			;4b5f
direccion_giro:		; C = rumbo del giro (+0x17) por 4, o el de C
	ld a,(ix+017h)		;4b60   ; direccion de giro
	and a			;4b63
	jp m,direccion_pose		;4b64   ; sin giro: la de C
	add a,a			;4b67   ; por 4
	add a,a			;4b68
	ld c,a			;4b69
	ret			;4b6a
direccion_pose:		; C = direccion por 4 (bits 2-4 de la pose)
	ld a,c			;4b6b   ; direccion por 4
	add a,a			;4b6c
	add a,a			;4b6d
	and 03ch		;4b6e   ; bits 2-5
	bit 5,a		;4b70   ; 0x3F: sin direccion pedida
	call nz,direccion_actual		;4b72   ; se queda la actual
	ld c,a			;4b75
	ret			;4b76
direccion_actual:		; A = bits de direccion de la pose actual
	call pose_actual		;4b77
	and 01ch		;4b7a   ; bits 2-4: direccion
	ret			;4b7c
marca_pose:		; Pose cambiada (bit 7 de +0x0F)
	set 7,(ix+00fh)		;4b7d
	ret			;4b81
sonido_bote:		; Bote en el suelo: pieza 9 y balon a ras de suelo; en lo alto 0xF8
	bit 0,c		;4b82   ; bit 0: fotograma arriba o abajo
	jr z,L_4B8A		;4b84
	ld a,0f8h		;4b86   ; balon arriba
	jr L_4B91		;4b88
L_4B8A:
	ld a,009h		;4b8a   ; pieza 9: el balon toca el suelo
	call arranca_sonido		;4b8c   ; pieza 9: bote
	ld a,000h		;4b8f   ; balon abajo
L_4B91:
	ld (0c53dh),a		;4b91   ; altura del balon en la mano
	ret			;4b94
corre_botando:		; Corre botando el balon
	ld a,(0ece7h)		;4b95   ; balon oculto?
	and a			;4b98
	jp nz,corre		;4b99
	call direccion_pose		;4b9c   ; C = direccion
	push de			;4b9f
	ld de,04c13h		;4ba0   ; posiciones del bote al correr
	call balon_en_mano		;4ba3   ; balon junto al jugador
	call fotograma_carrera		;4ba6   ; fotograma de la carrera
	pop de			;4ba9
	call sonido_bote		;4baa   ; bote
	ld a,c			;4bad
	or 020h		;4bae   ; pose de correr
	ex af,af'			;4bb0
	ret			;4bb1
fotograma_carrera:		; Fotograma de la carrera segun la cuenta de cuadros (bits 3-4)
	ld a,(0ebcfh)		;4bb2   ; cuenta de cuadros
	rrca			;4bb5
	rrca			;4bb6
	rrca			;4bb7
	and 003h		;4bb8   ; bits 3-4: fotograma 0-3
	or c			;4bba
	ld c,a			;4bbb
	ret			;4bbc
corre:		; Corre sin balon
	call direccion_pose		;4bbd   ; C = direccion
	call fotograma_corre		;4bc0   ; fotograma
	ld a,c			;4bc3
	or 000h		;4bc4   ; pose 0x00: correr
	ex af,af'			;4bc6
	ret			;4bc7
fotograma_corre:		; Fotograma de la carrera sin balon
	ld a,(0ebcfh)		;4bc8   ; cuenta de cuadros
	rrca			;4bcb
	rrca			;4bcc
	rrca			;4bcd
	and 003h		;4bce   ; fotograma 0-3
	or c			;4bd0
	ld c,a			;4bd1
	ret			;4bd2
rumbo_entre:		; Rumbo de 0 a 7 entre los registros DE y HL
	call diferencia_xy		;4bd3   ; diferencias
rumbo:		; Rumbo de 0 a 7 de la diferencia HL; el angulo fino queda en (0xC5D2)
	call mitad_de		;4bd6   ; a la mitad
	push bc			;4bd9
	call angulo		;4bda   ; angulo de 0 a 255
	pop bc			;4bdd
	add a,b			;4bde   ; mas el giro B
	ld (0c5d2h),a		;4bdf   ; angulo fino
	rlca			;4be2   ; tres bits altos
	rlca			;4be3
	rlca			;4be4
	and 007h		;4be5   ; rumbo de 0 a 7
	ret			;4be7
mitad_de:		; Divide DE y HL entre 2
	ex de,hl			;4be8
	call mitad_hl		;4be9   ; HL / 2
	ex de,hl			;4bec
mitad_hl:		; HL / 2 con signo
	sra h		;4bed
	rr l		;4bef
	ret			;4bf1
balon_en_mano:		; Pone el balon junto al jugador IX con el desplazamiento de la tabla DE segun la direccion C
	ld a,c			;4bf2   ; direccion por 2: dos bytes por entrada
	rrca			;4bf3
	ld h,000h		;4bf4
	ld l,a			;4bf6
	add hl,de			;4bf7
	ld d,(hl)			;4bf8   ; dy
	inc hl			;4bf9
	ld e,(hl)			;4bfa   ; dx
	exx			;4bfb
	ld hl,0c530h		;4bfc   ; registro del balon
	exx			;4bff
	ld a,d			;4c00
	add a,(ix+001h)		;4c01   ; Y del jugador mas desplazamiento
	ld d,a			;4c04
	exx			;4c05
	inc hl			;4c06
	ld (hl),a			;4c07   ; Y del balon
	inc hl			;4c08
	exx			;4c09
	ld a,e			;4c0a
	add a,(ix+003h)		;4c0b   ; X del jugador mas desplazamiento
	exx			;4c0e
	inc hl			;4c0f
	ld (hl),a			;4c10   ; X del balon
	exx			;4c11
	ret			;4c12

; ----------------------------------------------------------------------
; DATOS pasos_a: Ocho pares (dx, dy) con signo que recorren 0x4B44 y 0x4BA0
;   0x4c13..0x4c23  (16 bytes)
DATA_pasos_a:
	defb 0ffh,003h	; 4c13
	defb 0ffh,005h	; 4c15
	defb 000h,004h	; 4c17
	defb 001h,003h	; 4c19
	defb 001h,0fdh	; 4c1b
	defb 001h,0fch	; 4c1d
	defb 000h,0fch	; 4c1f
	defb 0ffh,0fdh	; 4c21

; ----------------------------------------------------------------------
; DATOS pasos_b: Ocho pares (dx, dy) con signo que recorren 0x49BF, 0x4AB0,
;   0x4AD0 y 0x8301
;   0x4c23..0x4c33  (16 bytes)
DATA_pasos_b:
	defb 0ffh,001h	; 4c23
	defb 0ffh,002h	; 4c25
	defb 000h,003h	; 4c27
	defb 001h,001h	; 4c29
	defb 001h,0feh	; 4c2b
	defb 001h,0fdh	; 4c2d
	defb 000h,0fdh	; 4c2f
	defb 0ffh,0ffh	; 4c31

; ======================================================================
; CODIGO 0x4c33..0x4dd2  (415 bytes)
; ======================================================================


salto:		; Despega al jugador IX: velocidad segun +0x1C y el roster; si va con el balon cerca del aro y alto, puede machacar
	ld a,(ix+00ch)		;4c33   ; gravedad (+0x0C)
	and a			;4c36
	ret nz			;4c37   ; ya esta en el aire
	push de			;4c38
	push hl			;4c39
	ld (ix+00ch),00fh		;4c3a   ; gravedad
	ld (ix+020h),000h		;4c3e   ; sin destino
	ld (ix+021h),000h		;4c42   ; sin destino X
	ld a,001h		;4c46   ; salto con balon (pasos si cae con el)
	ld (0c607h),a		;4c48   ; 1 = salto con el balon
	ld e,(ix+01ch)		;4c4b   ; SUPOSICION: potencia de salto del jugador
	srl e		;4c4e   ; la mitad de +0x1C
	ld d,000h		;4c50
	ld hl,0014ah		;4c52   ; velocidad base 0x14A
	add hl,de			;4c55   ; base mas la mitad
	push hl			;4c56
	ld a,(0ecf1h)		;4c57   ; equipo con el balon
	rrca			;4c5a
	ld (0ed4dh),a		;4c5b   ; en el bit 7 para 0x71B6
	ld c,021h		;4c5e   ; campo 0x21 del roster
	call campo_equipo		;4c60
	ex de,hl			;4c63
	ld l,(ix+01fh)		;4c64   ; +0x1F: jugador en el roster
	ld h,000h		;4c67   ; jugador por 2
	add hl,hl			;4c69
	add hl,de			;4c6a
	ld e,(hl)			;4c6b   ; valor de la tabla del roster
	srl e		;4c6c   ; entre 4
	srl e		;4c6e
	ld d,000h		;4c70
	pop hl			;4c72
	and a			;4c73
	sbc hl,de		;4c74   ; se resta
	ld (ix+00ah),l		;4c76   ; velocidad vertical
	ld (ix+00bh),h		;4c79   ; (byte alto)
	ld a,(0ebd6h)		;4c7c   ; el saltador
	call apunta_saltador		;4c7f   ; apunta al saltador de su equipo
	ld a,(0c5dfh)		;4c82   ; poseedor
	push hl			;4c85
	ld hl,0ebd6h		;4c86
	cp (hl)			;4c89   ; es el que salta?
	pop hl			;4c8a
	jr nz,L_4CAE		;4c8b   ; no: no hay mate
	push ix		;4c8d
	pop de			;4c8f
	push hl			;4c90
	ld hl,0c5d3h		;4c91   ; distancia a la canasta
	call xy_dos_registros		;4c94   ; jugador y canasta
	call diferencia_xy		;4c97
	call distancia		;4c9a   ; distancia
	cp 008h		;4c9d   ; a menos de 8
	pop hl			;4c9f
	jr nc,L_4CAE		;4ca0   ; 8 o mas: lejos
	ld de,00190h		;4ca2   ; y velocidad de al menos 0x190
	sbc hl,de		;4ca5   ; velocidad menos 0x190
	jr c,L_4CAE		;4ca7   ; salto flojo: no hay mate
	ld a,001h		;4ca9   ; 1 = puede machacar
	ld (0ed61h),a		;4cab
L_4CAE:
	pop hl			;4cae
	pop de			;4caf
	ret			;4cb0
mueve_jugadores:		; Suma la velocidad y limita a la pista a los seis jugadores
	ld a,(0cb30h)		;4cb1   ; SUPOSICION: movimiento parado
	and a			;4cb4   ; 0: se mueven
	ret nz			;4cb5
	ld ix,0c410h		;4cb6   ; primer registro
	ld de,00030h		;4cba
	ld b,006h		;4cbd   ; seis jugadores
	ld a,(0c5dfh)		;4cbf   ; poseedor
	and 007h		;4cc2   ; numero del poseedor
	ld (0ebd6h),a		;4cc4   ; como jugador en curso
	exx			;4cc7
	ld c,000h		;4cc8   ; C' = numero de jugador
	exx			;4cca
L_4CCB:
	push bc			;4ccb
	call mueve_jugador		;4ccc   ; limites del jugador IX
	pop bc			;4ccf
	ld de,00030h		;4cd0   ; siguiente registro
	add ix,de		;4cd3
	exx			;4cd5
	inc c			;4cd6   ; siguiente numero
	exx			;4cd7
	djnz L_4CCB		;4cd8
	ret			;4cda
mueve_jugador:		; Limita la Y (+1) y la X (+3, fraccion en +2) del jugador IX a la pista y a su medio campo; la primera version limitaba antes la X con la ventana en el centro (0x4D92) y esta ya no lo hace
	ld d,(ix+001h)		;4cdb   ; Y del jugador
	ld e,(ix+003h)		;4cde   ; X del jugador
	call limita_y		;4ce1   ; limites de Y
	ld a,(ix+00fh)		;4ce4   ; bits 3-6 de +0x0F: lado y campo
	and 078h		;4ce7   ; bits 3-6
	call limita_campo		;4ce9   ; limites de X segun el campo
	ld (ix+001h),d		;4cec   ; Y limitada
	ld (ix+003h),e		;4cef   ; X limitada
	ret			;4cf2
limita_campo:		; Limites de X segun el campo del jugador y el lado al que ataca
	bit 3,a		;4cf3   ; bit 3: sentido de ataque
	jp z,L_4D6E		;4cf5
	bit 5,a		;4cf8   ; bit 5: mitad del cuadro anterior
	jp nz,L_4D0A		;4cfa
	bit 4,a		;4cfd   ; bit 4
	jp nz,L_4D36		;4cff
	bit 6,a		;4d02   ; bit 6: mitad actual
	jp nz,L_4D4D		;4d04
	jp limite_a0		;4d07   ; no pasa de -0x60
L_4D0A:
	bit 4,a		;4d0a   ; bit 4
	jp nz,L_4D26		;4d0c
	bit 6,a		;4d0f   ; bit 6: mitad actual
	jp nz,limite_60		;4d11
	ld a,(0ebd6h)		;4d14   ; poseedor
	exx			;4d17
	cp c			;4d18   ; es el jugador en curso?
	exx			;4d19
	ret nz			;4d1a
	ld a,(0c5dfh)		;4d1b   ; SUPOSICION: el poseedor paso al campo contrario
	or 010h		;4d1e   ; bit 4 del estado: desplazar la ventana a la derecha
	ld (0c5dfh),a		;4d20
	jp fin_cuenta_10s		;4d23   ; se acaba la cuenta de 10 segundos
L_4D26:
	bit 6,a		;4d26   ; bit 6: mitad actual
	jp nz,limite_60		;4d28
L_4D2B:
	ld e,000h		;4d2b   ; X justo en el centro
	ld (ix+002h),000h		;4d2d   ; fraccion 0
	set 6,(ix+00fh)		;4d31   ; mitad derecha
	ret			;4d35
L_4D36:
	bit 6,a		;4d36   ; bit 6: mitad actual
	jp z,limite_a0		;4d38
	ld a,(0ebd6h)		;4d3b   ; poseedor
	exx			;4d3e
	cp c			;4d3f   ; es el jugador en curso?
	exx			;4d40
	ret nz			;4d41
	ld a,(0c5dfh)		;4d42   ; SUPOSICION: el poseedor paso al otro campo
	or 008h		;4d45   ; bit 3 del estado: desplazar la ventana a la izquierda
	ld (0c5dfh),a		;4d47
	jp fin_cuenta_10s		;4d4a   ; ha pasado al campo contrario
L_4D4D:
	ld e,0ffh		;4d4d   ; X justo antes del centro
	ld (ix+002h),0ffh		;4d4f   ; fraccion 0xFF
	res 6,(ix+00fh)		;4d53   ; mitad izquierda
	ret			;4d57
limite_a0:		; X no menor de 0xA0 (-0x60, fraccion 0xFF)
	ld a,e			;4d58
	cp 0a0h		;4d59   ; X por debajo de -0x60?
	ret nc			;4d5b
	ld e,0a0h		;4d5c   ; tope -0x60
	ld (ix+002h),0ffh		;4d5e
	ret			;4d62
limite_60:		; X no mayor de 0x60 (fraccion 0)
	ld a,e			;4d63
	cp 060h		;4d64   ; X por encima de 0x60?
	ret c			;4d66
	ld e,060h		;4d67   ; tope 0x60
	ld (ix+002h),000h		;4d69
	ret			;4d6d
L_4D6E:
	bit 5,a		;4d6e   ; bit 5: mitad anterior
	jr nz,L_4D82		;4d70
	bit 4,a		;4d72   ; bit 4
	jr nz,L_4D7C		;4d74
	bit 6,a		;4d76   ; bit 6: mitad actual
	jr nz,L_4D2B		;4d78
	jr limite_a0		;4d7a
L_4D7C:
	bit 6,a		;4d7c
	jr nz,limite_60		;4d7e
	jr limite_a0		;4d80
L_4D82:
	bit 4,a		;4d82
	jr nz,L_4D8C		;4d84
	bit 6,a		;4d86
	jr nz,limite_60		;4d88
	jr limite_a0		;4d8a
L_4D8C:
	bit 6,a		;4d8c
	jr nz,limite_60		;4d8e
	jr L_4D4D		;4d90
limita_centro:		; Huerfano: con la ventana en la columna central, limites 0x3C y 0xC4 de la X (la primera version la llamaba desde 0x4CDB)
	ld a,(0ece6h)		;4d92   ; X fina de la ventana
	cp 080h		;4d95   ; 0x80: centrada
	ret nz			;4d97
	bit 6,(ix+00fh)		;4d98   ; mitad del jugador
	ld a,e			;4d9c
	jr z,L_4DA9		;4d9d
	cp 03ch		;4d9f   ; por debajo de 0x3C?
	ret c			;4da1
	ld e,03ch		;4da2   ; tope 0x3C
	ld (ix+000h),000h		;4da4
	ret			;4da8
L_4DA9:
	cp 0c4h		;4da9   ; por encima de 0xC4?
	ret nc			;4dab
	ld e,0c4h		;4dac   ; tope 0xC4
	ld (ix+000h),0ffh		;4dae
	ret			;4db2
limita_y:		; Y entre 0x0C y 0x68
	ld a,d			;4db3
	cp 00ch		;4db4   ; por debajo de 0x0C?
	jr nc,L_4DBB		;4db6
	ld d,00ch		;4db8   ; tope 0x0C
	ret			;4dba
L_4DBB:
	cp 068h		;4dbb   ; por encima de 0x68?
	ret c			;4dbd
	ld d,068h		;4dbe   ; tope 0x68
	ret			;4dc0
registro_jugador:		; HL = registro del jugador A (tabla 0x4DD2)
	push af			;4dc1
	push de			;4dc2
	add a,a			;4dc3   ; dos bytes por jugador
	ld e,a			;4dc4
	ld d,000h		;4dc5
	ld hl,04dd2h		;4dc7   ; tabla de registros
	add hl,de			;4dca
	ld a,(hl)			;4dcb
	inc hl			;4dcc
	ld h,(hl)			;4dcd
	ld l,a			;4dce
	pop de			;4dcf
	pop af			;4dd0
	ret			;4dd1

; ----------------------------------------------------------------------
; DATOS registros_jugador: Los seis registros de jugador, de 0x30 bytes cada
;   uno, en 0xC410 0xC440 0xC470 0xC4A0 0xC4D0 0xC500: 0x4DC1 devuelve en HL
;   el del jugador A
;   0x4dd2..0x4dde  (12 bytes)
DATA_registros_jugador:
	defw 0c410h,0c440h,0c470h,0c4a0h,0c4d0h,0c500h	; 4dd2

; ======================================================================
; CODIGO 0x4dde..0x526a  (1164 bytes)
; ======================================================================


lados_jugadores:		; Actualiza el lado de la pista de cada jugador (bits 5-6 de +0x0F)
	ld hl,0c60ah		;4dde   ; zonas de los tres atacantes
	ld b,003h		;4de1
	call zonas_a_4		;4de3
	ld b,006h		;4de6   ; seis jugadores
	ld ix,0c410h		;4de8
	ld de,00030h		;4dec
	ld h,000h		;4def   ; H = numero de jugador
L_4DF1:
	ld a,(ix+003h)		;4df1   ; X del jugador
	push de			;4df4
	push hl			;4df5
	call lado_x		;4df6   ; bits 5-6 de +0x0F
	call zona_jugador		;4df9   ; zona de los atacantes
	pop hl			;4dfc
	pop de			;4dfd
	add ix,de		;4dfe   ; siguiente registro
	inc h			;4e00
	djnz L_4DF1		;4e01
	ret			;4e03
cambio_de_posesion:		; Invierte el sentido de ataque (bit 3 de +0x0F) de los seis jugadores y la canasta atacada
	ld a,(0ecf1h)		;4e04
	res 7,a		;4e07   ; cambio atendido
	ld (0ecf1h),a		;4e09
	ld c,008h		;4e0c   ; bit 3: sentido de ataque
	ld hl,0ebd8h		;4e0e   ; SUPOSICION: sin jugador asignado
	ld (hl),0ffh		;4e11
	ld ix,0c410h		;4e13   ; seis jugadores
	ld b,006h		;4e17
	ld de,00030h		;4e19
L_4E1C:
	ld a,(ix+00fh)		;4e1c   ; banderas del jugador
	xor c			;4e1f   ; invierte el bit 3
	ld (ix+00fh),a		;4e20
	add ix,de		;4e23
	djnz L_4E1C		;4e25
	ld a,(0ecf1h)		;4e27   ; equipo con el balon
	and a			;4e2a
	ld hl,0c5d7h		;4e2b   ; SUPOSICION: canasta defendida (0xC5D7)
	inc hl			;4e2e
	ld a,039h		;4e2f   ; SUPOSICION: canasta a la que se ataca
	ld (hl),a			;4e31
	inc hl			;4e32
	inc hl			;4e33
	jr nz,L_4E3A		;4e34
	ld a,062h		;4e36   ; SUPOSICION: canasta de la derecha
	jr L_4E3C		;4e38
L_4E3A:
	ld a,09eh		;4e3a   ; SUPOSICION: canasta de la izquierda
L_4E3C:
	ld (hl),a			;4e3c
	ret			;4e3d
lado_x:		; Bit 6 de +0x0F = X positiva (mitad derecha); bit 5 = el valor anterior
	and a			;4e3e
	ld a,(ix+00fh)		;4e3f   ; banderas del jugador
	call m,x_negativa		;4e42   ; X negativa: mitad izquierda
	call p,x_positiva		;4e45   ; X positiva: mitad derecha
	ld (ix+00fh),c		;4e48   ; banderas nuevas
	ret			;4e4b
x_negativa:		; C = +0x0F con el bit 6 a 0 y el anterior en el bit 5
	push af			;4e4c
	and 0dfh		;4e4d   ; sin el bit 5
	ld c,a			;4e4f
	and 040h		;4e50   ; bit 6 actual
	rra			;4e52   ; pasa al bit 5
	or c			;4e53
	res 6,a		;4e54   ; bit 6 a 0
	ld c,a			;4e56
	pop af			;4e57
	ret			;4e58
x_positiva:		; C = +0x0F con el bit 6 a 1 y el anterior en el bit 5
	push af			;4e59
	and 0dfh		;4e5a   ; sin el bit 5
	ld c,a			;4e5c
	and 040h		;4e5d   ; bit 6 actual
	rra			;4e5f   ; pasa al bit 5
	or c			;4e60
	set 6,a		;4e61   ; bit 6 a 1
	ld c,a			;4e63
	pop af			;4e64
	ret			;4e65
destinos_defensa:		; SUPOSICION: los del equipo sin balon reciben un destino en +0x20/+0x21; los atacantes el bit 3
	ld ix,0c410h		;4e66   ; primer registro
	ld b,006h		;4e6a   ; seis jugadores
	ld a,(0ecf1h)		;4e6c   ; equipo con el balon
	and 001h		;4e6f
	ld c,a			;4e71
	xor a			;4e72   ; A = numero de jugador
L_4E73:
	push af			;4e73
	cp 003h		;4e74   ; equipo derecho?
	jr c,L_4E90		;4e76
	inc c			;4e78
	dec c			;4e79
	jr nz,L_4E80		;4e7a   ; el izquierdo tiene el balon: defiende el derecho
	ld a,008h		;4e7c   ; atacante: bit 3
	jr L_4EA6		;4e7e
L_4E80:
	push de			;4e80
	push bc			;4e81
	call posicion_defensa		;4e82   ; posicion de defensa
	pop bc			;4e85
	ld (ix+020h),d		;4e86   ; destino Y
	ld (ix+021h),e		;4e89   ; destino X
	pop de			;4e8c
	xor a			;4e8d
	jr L_4EA6		;4e8e
L_4E90:
	inc c			;4e90
	dec c			;4e91
	jr z,L_4E98		;4e92   ; el derecho tiene el balon: defiende el izquierdo
	ld a,008h		;4e94   ; atacante: bit 3
	jr L_4EA6		;4e96
L_4E98:
	push de			;4e98
	push bc			;4e99
	call posicion_defensa		;4e9a   ; posicion de defensa
	pop bc			;4e9d
	ld (ix+020h),d		;4e9e   ; destino Y
	ld (ix+021h),e		;4ea1   ; destino X
	pop de			;4ea4
	xor a			;4ea5
L_4EA6:
	or (ix+00fh)		;4ea6   ; bit 3 en las banderas
	ld (ix+00fh),a		;4ea9
	ld de,00030h		;4eac
	pop af			;4eaf
	inc a			;4eb0   ; siguiente numero
	add ix,de		;4eb1   ; siguiente registro
	djnz L_4E73		;4eb3
	jp cambio_de_posesion		;4eb5   ; y se invierte el ataque
extiende_signo:		; DE = A con signo
	ld e,a			;4eb8
	ld d,000h		;4eb9
	and a			;4ebb   ; positivo: D = 0
	ret p			;4ebc
	dec d			;4ebd   ; negativo: D = 0xFF
	ret			;4ebe
controlados:		; A = controlado del equipo con el balon, A' = el del otro
	ld a,(0ecf1h)		;4ebf   ; equipo con el balon
	and 001h		;4ec2
	jr nz,L_4ECF		;4ec4
	ld a,(0c5e8h)		;4ec6   ; controlado izquierdo
	ex af,af'			;4ec9
	ld a,(0c5ebh)		;4eca   ; A' = controlado derecho
	ex af,af'			;4ecd
	ret			;4ece
L_4ECF:
	ld a,(0c5ebh)		;4ecf   ; controlado derecho
	ex af,af'			;4ed2
	ld a,(0c5e8h)		;4ed3   ; A' = controlado izquierdo
	ex af,af'			;4ed6
	ret			;4ed7
controlado:		; A = jugador controlado del equipo con el balon
	ld a,(0ecf1h)		;4ed8   ; equipo con el balon
	and 001h		;4edb
	jr nz,L_4EE3		;4edd
	ld a,(0c5e8h)		;4edf   ; controlado izquierdo
	ret			;4ee2
L_4EE3:
	ld a,(0c5ebh)		;4ee3   ; controlado derecho
	ret			;4ee6
apunta_saltador:		; Guarda el jugador A como saltador de su equipo (0xC5F0 o 0xC5F1)
	cp 003h		;4ee7   ; equipo derecho?
	jr nc,L_4EEF		;4ee9
	ld (0c5f0h),a		;4eeb   ; saltador izquierdo
	ret			;4eee
L_4EEF:
	ld (0c5f1h),a		;4eef   ; saltador derecho
	ret			;4ef2
borra_saltador:		; Borra el saltador del equipo del jugador A
	cp 003h		;4ef3
	ld hl,0c5f0h		;4ef5   ; saltador izquierdo
	jr c,L_4EFD		;4ef8
	ld hl,0c5f1h		;4efa   ; saltador derecho
L_4EFD:
	ld (hl),0ffh		;4efd   ; ya no salta
	ld hl,(0c5efh)		;4eff   ; HL = palabra de 0xC5EF: L el que tiro, H el saltador izquierdo (0xFF casi siempre); SUPOSICION: se queria ld hl,0xC5EF
	cp (hl)			;4f02   ; compara A con el byte de 0xFF00-0xFF05, 0xFFFF o la BIOS segun H:L
	ret nz			;4f03
	ld (hl),0ffh		;4f04   ; si coincide escribe 0xFF alli; 0xC5EF no se borra
	ret			;4f06
recoge_balon:		; Balon suelto: el primero que este a menos de 10 y a su altura se lo queda
	ld a,(0c5dfh)		;4f07   ; 7 = balon suelto
	cp 007h		;4f0a
	ret nz			;4f0c
	ld hl,0c410h		;4f0d
	ld b,006h		;4f10
	ld c,000h		;4f12
L_4F14:
	push bc			;4f14
	push hl			;4f15
	ld de,0c530h		;4f16   ; registro del balon
	call xy_dos_registros		;4f19
	call diferencia_xy		;4f1c
	call distancia		;4f1f
	pop hl			;4f22
	pop bc			;4f23
	cp 00ah		;4f24   ; a menos de 10?
	jr c,L_4F30		;4f26
L_4F28:
	ld de,00030h		;4f28
	add hl,de			;4f2b
	inc c			;4f2c
	djnz L_4F14		;4f2d
	ret			;4f2f
L_4F30:
	push bc			;4f30
	push hl			;4f31
	ld a,(0c539h)		;4f32   ; altura del balon
	ld c,a			;4f35
	dec c			;4f36
	ld de,00009h		;4f37   ; altura del jugador
	add hl,de			;4f3a
	ld a,0e0h		;4f3b
	add a,(hl)			;4f3d
	cp c			;4f3e
	pop hl			;4f3f
	pop bc			;4f40
	jr nc,L_4F28		;4f41
	ld a,(0c602h)		;4f43   ; durante el salto entre dos
	and a			;4f46
	jp nz,palmeo_salto		;4f47
	ld a,(0cb28h)		;4f4a   ; tiro en vuelo
	and a			;4f4d
	jr z,L_4F57		;4f4e
	ld a,(0cb2bh)		;4f50
	and a			;4f53
	jp m,L_4F28		;4f54
L_4F57:
	ld a,(0cb26h)		;4f57   ; SUPOSICION: jugadores que no pueden cogerlo
	cp c			;4f5a
	jr z,L_4F69		;4f5b
	ld a,(0cb28h)		;4f5d
	and a			;4f60
	jr nz,L_4F28		;4f61
	ld a,(0cb27h)		;4f63
	cp c			;4f66
	jr nz,L_4F28		;4f67
L_4F69:
	ld a,(0c539h)		;4f69
	ld (0c53dh),a		;4f6c
	call para_balon		;4f6f   ; SUPOSICION: canasta a la que ataca
	ld (0c534h),hl		;4f72
	ld (0c536h),hl		;4f75
	xor a			;4f78
	ld (0ed67h),a		;4f79
	ld (0c607h),a		;4f7c
	ld a,c			;4f7f
	call da_balon		;4f80   ; nuevo poseedor
	ld a,0ffh		;4f83   ; nadie bloqueado
	ld (0ed61h),a		;4f85
	ld (0cb26h),a		;4f88
	ld (0cb27h),a		;4f8b
	ld (0cb24h),a		;4f8e
	ld (0cb25h),a		;4f91
	ld a,(0cb28h)		;4f94
	and a			;4f97
	ret nz			;4f98
	call cuenta_10s		;4f99   ; relojes de 10 y 30 segundos
	call cuenta_30s		;4f9c
	ret			;4f9f
da_balon:		; Da el balon al jugador A; el otro equipo pasa a controlar a su defensor emparejado (+0x25)
	push ix		;4fa0
	push hl			;4fa2
	push de			;4fa3
	push bc			;4fa4
	push af			;4fa5
	call pon_poseedor		;4fa6   ; poseedor nuevo y controlados
	pop af			;4fa9
	call registro_jugador		;4faa   ; registro del nuevo poseedor
	ld de,00025h		;4fad
	add hl,de			;4fb0
	ld a,(hl)			;4fb1   ; su par (+0x25)
	call controla		;4fb2   ; pasa a ser el controlado del rival
	pop bc			;4fb5
	pop de			;4fb6
	pop hl			;4fb7
	pop ix		;4fb8
	ret			;4fba
controla:		; Jugador controlado: A menor que 3 en 0xC5E8/0xC5E9, si no en 0xC5EB/0xC5EC
	cp 003h		;4fbb
	jr nc,L_4FD4		;4fbd
	ld (0c5e8h),a		;4fbf   ; controlado del equipo izquierdo
	push hl			;4fc2
	push af			;4fc3
	ld a,(0ecf1h)		;4fc4
	and a			;4fc7
	call nz,marca_controlado		;4fc8
	pop af			;4fcb
	call registro_jugador		;4fcc
	ld (0c5e9h),hl		;4fcf   ; su registro
	pop hl			;4fd2
	ret			;4fd3
L_4FD4:
	ld (0c5ebh),a		;4fd4   ; controlado del equipo derecho
	push hl			;4fd7
	push af			;4fd8
	ld a,(0ecf1h)		;4fd9   ; equipo con el balon
	and a			;4fdc
	call z,marca_controlado		;4fdd   ; el derecho ataca: marca a su controlado
	pop af			;4fe0
	call registro_jugador		;4fe1
	ld (0c5ech),hl		;4fe4   ; registro del controlado derecho
	pop hl			;4fe7
	ret			;4fe8
reloj_en_marcha:		; Pone en marcha el reloj del partido
	xor a			;4fe9
	ld (0ed6bh),a		;4fea
	ld (0ed6ch),a		;4fed
	ret			;4ff0
espera_300:		; Cuenta atras general de 300 cuadros
	ld hl,0012ch		;4ff1
	ld (0ed7eh),hl		;4ff4
	ret			;4ff7
nada_huerfano:		; Huerfano: un ret suelto
	ret			;4ff8
cuenta_10s:		; Si el poseedor esta en su campo, arranca la cuenta de 10 segundos (600 cuadros en 0xED78)
	call controlado		;4ff9
	call registro_jugador		;4ffc
	call pose_bit6		;4fff
	ret z			;5002
	xor a			;5003
	ld (0ed6fh),a		;5004
	ld hl,00258h		;5007   ; 600 cuadros
	ld (0ed78h),hl		;500a
	ret			;500d
fin_cuenta_10s:		; En el campo contrario la cuenta de 10 segundos queda desactivada (2)
	call controlado		;500e   ; controlado del equipo con el balon
	call registro_jugador		;5011
	call pose_bit6		;5014
	ret nz			;5017   ; aun en su campo
	ld a,002h		;5018   ; 2 = cuenta desactivada
	ld (0ed6fh),a		;501a
	ret			;501d
cuenta_30s:		; Arranca la cuenta de 30 segundos (1800 cuadros en 0xED7A)
	xor a			;501e
	ld (0ed70h),a		;501f
	ld hl,00708h		;5022
	ld (0ed7ah),hl		;5025
	ret			;5028
para_30s_huerfano:		; Huerfano: desactivaria la cuenta de 30 segundos
	ld a,002h		;5029
	ld (0ed70h),a		;502b
	ret			;502e

; ----------------------------------------------------------------------
; ===== Faltas: rotulo, tiros libres y saques =====
; ----------------------------------------------------------------------
pita_falta:		; Falta del jugador de 0xCB34: rotulo, silbato y, segun el tipo, tiros libres o saque
	ld a,(0c5dfh)		;502f
	and 0c0h		;5032
	jr nz,sin_falta		;5034
	call balon_quieto		;5036
	call corta_formacion		;5039
	ld a,(0cb34h)		;503c   ; infractor
	call registro_jugador		;503f
	call xy_registro		;5042
	call aparta_del_centro		;5045   ; posicion de la falta lejos del centro
	ld (0cb37h),de		;5048   ; posicion de la falta
	call rotulo_falta		;504c   ; rotulo, silbato y ventana hacia la falta
	ld de,sin_falta		;504f   ; al acabar, sin falta pendiente
	push de			;5052
	ld a,(0cb35h)		;5053   ; tipos 0-4 (pasos y cuentas): saque
	cp 005h		;5056
	jp c,saque		;5058
	ld a,(0cb34h)		;505b
	call registro_jugador		;505e
	ld de,0000fh		;5061
	add hl,de			;5064
	bit 3,(hl)		;5065   ; falta en ataque: saque
	jp nz,saque		;5067
	ld a,(0cb36h)		;506a   ; jugador que recibe la falta
	ld (0ed83h),a		;506d
	call registro_jugador		;5070
	ld de,0000ch		;5073   ; estaba en el aire (tirando)
	add hl,de			;5076
	ld a,(hl)			;5077
	and a			;5078
	jp nz,tiros_libres		;5079   ; si: tiros libres
	call zona_tiro		;507c   ; zona de la victima
	ld a,(0ed82h)		;507f   ; dentro de la zona: tiros libres
	and a			;5082
	jp z,tiros_libres		;5083
	ld a,(0ecf1h)		;5086   ; equipo con el balon
	ld hl,0c7f4h		;5089   ; faltas del equipo izquierdo
	and a			;508c
	jr nz,L_5092		;508d
	ld hl,0c824h		;508f   ; faltas del equipo derecho
L_5092:
	ld a,(hl)			;5092
	cp 007h		;5093   ; SUPOSICION: 7 o mas: tiros de bonus
	jp nc,bonus		;5095
	jp saque		;5098
sin_falta:		; Infractor, tipo y victima a 0xFF
	ld a,0ffh		;509b
	ld (0cb34h),a		;509d
	ld (0cb35h),a		;50a0
	ld (0cb36h),a		;50a3
	ret			;50a6
pareja_infractor:		; A = defensor emparejado (+0x25) del infractor
	ld a,(0cb34h)		;50a7   ; infractor
	call registro_jugador		;50aa
	ld de,00025h		;50ad
	add hl,de			;50b0
	ld a,(hl)			;50b1   ; su par (+0x25)
	ret			;50b2
bonus:		; SUPOSICION: tiros con el bit 7 (uno mas uno)
	ld a,082h		;50b3
	jr L_50CF		;50b5
aparta_del_centro:		; SUPOSICION: si la X de la falta esta a menos de 8 del centro la lleva a +8 o -8 segun la ventana
	ld a,e			;50b7
	and a			;50b8
	jp p,L_50BE		;50b9
	neg		;50bc
L_50BE:
	cp 008h		;50be   ; a 8 o mas del centro: se queda
	ret nc			;50c0
	ld a,(0ece5h)		;50c1   ; columna de la ventana
	and a			;50c4
	jr nz,L_50CA		;50c5
	ld e,0f8h		;50c7   ; a -8
	ret			;50c9
L_50CA:
	ld e,008h		;50ca
	ret			;50cc
tiros_libres:		; Dos tiros libres para la victima: colocacion, bote, cinco segundos para tirar
	ld a,002h		;50cd   ; dos tiros
L_50CF:
	ld (0cb39h),a		;50cf
L_50D2:
	call coloca_tiros_libres		;50d2   ; coloca a todos en la linea
	ld a,(0cb36h)		;50d5   ; balon al tirador
	call da_balon		;50d8
	call oculta_balon		;50db
	ld a,001h		;50de   ; movimiento y mandos bloqueados
	ld (0cb31h),a		;50e0
	ld (0cb2eh),a		;50e3
	ld (0cb2fh),a		;50e6
	ld (0c5f2h),a		;50e9
	call borra_entradas		;50ec   ; entradas a cero
L_50EF:
	call cuadro_partido		;50ef
	call todos_llegaron		;50f2   ; hasta que lleguen todos
	jr nz,L_50EF		;50f5
siguiente_tiro_libre:		; Tirador mirando al aro, bote y cuenta de cinco segundos
	ld hl,(0cb3ah)		;50f7
	ld de,00003h		;50fa
	add hl,de			;50fd
	ld a,(hl)			;50fe
	call pose_tirador		;50ff   ; pose del tirador mirando a la canasta
	call muestra_balon		;5102
	ld a,001h		;5105   ; bote forzado
	ld (0c603h),a		;5107
	ld a,03ch		;510a   ; un segundo botando
	ld (0c600h),a		;510c
L_510F:
	call cuadro_partido		;510f
	ld a,(0c600h)		;5112
	and a			;5115
	jr nz,L_510F		;5116
	xor a			;5118
	ld (0c603h),a		;5119
	inc a			;511c
	ld (0cb32h),a		;511d   ; tiro solo con el boton
	ld hl,0ed5eh		;5120
	set 6,(hl)		;5123
	call espera_300		;5125   ; cinco segundos para tirar
	call retardo_maquina		;5128
L_512B:
	call cuadro_partido		;512b
	ld a,(0ecf1h)		;512e   ; boton del equipo que tira
	call lee_mando_lado		;5131
	bit 7,a		;5134
	call nz,cuenta_tiro_libre		;5136
	ld a,(0c5dfh)		;5139   ; ya ha tirado
	bit 7,a		;513c
	jr nz,L_5149		;513e
	ld hl,(0ed7eh)		;5140   ; sin tiempo: violacion
	ld a,h			;5143
	or l			;5144
	jr nz,L_512B		;5145
	jr violacion_5s		;5147
L_5149:
	jr tras_tiro_libre		;5149
violacion_5s:		; Se acabo el tiempo del tiro libre o del saque: 5 SECOND y saque del rival
	xor a			;514b
	ld (0c5f2h),a		;514c
	ld (0cb32h),a		;514f
	ld (0cb2fh),a		;5152
	ld (0cb3ch),a		;5155
	ld a,002h		;5158   ; rotulo 2: 5 SECOND
	ld (0cb35h),a		;515a
	ld a,(0cb36h)		;515d
	and a			;5160
	call m,pareja_infractor		;5161   ; SUPOSICION: infractor el emparejado
	ld (0cb34h),a		;5164
	push af			;5167
	call rotulo_falta		;5168
	pop af			;516b
	jp saque		;516c
cuenta_tiro_libre:		; Al pulsar arranca la cuenta del tiro automatico (4 pasos)
	ld a,(0cb3ch)		;516f   ; cuenta ya en marcha
	and a			;5172
	ret nz			;5173
	ld a,004h		;5174   ; cuatro pasos
	ld (0cb3ch),a		;5176
	ret			;5179
tras_tiro_libre:		; Quedan tiros? espera a que el balon se pare y repite
	ld a,(0cb39h)		;517a   ; tiros que quedan
	dec a			;517d
	bit 0,a		;517e   ; bit 0 a 0: era el ultimo
	ld (0cb39h),a		;5180
	jr z,ultimo_tiro_libre		;5183
	and a			;5185
	jp m,tiro_bonus		;5186   ; bit 7: uno mas uno
L_5189:
	call cuadro_partido		;5189   ; espera a que el balon se pare
	ld a,(0c53ch)		;518c
	and a			;518f
	jr nz,L_5189		;5190
	ld a,(0cb36h)		;5192   ; balon otra vez al tirador
	ld (0c5dfh),a		;5195
	xor a			;5198
	ld (0cb28h),a		;5199
	jp siguiente_tiro_libre		;519c
ultimo_tiro_libre:		; Tras el ultimo tiro se reanuda el juego
	call reanuda		;519f
	ld a,002h		;51a2
	ld (0ed6dh),a		;51a4   ; SUPOSICION: rebote pendiente
	jp al_rebote		;51a7
reanuda:		; Desbloquea movimiento y mandos y pone el reloj en marcha
	xor a			;51aa
	ld (0cb32h),a		;51ab   ; sin tiro forzado
	ld (0cb2fh),a		;51ae   ; defensa libre
	ld (0cb2eh),a		;51b1   ; ataque libre
	ld (0cb31h),a		;51b4   ; mandos libres
	ld (0c5f2h),a		;51b7   ; eleccion de receptor libre
	jp reloj_en_marcha		;51ba
tiro_bonus:		; SUPOSICION: uno mas uno: si el primero entra se tira el segundo
	call reanuda		;51bd
	ld a,001h		;51c0
	ld (0ed6bh),a		;51c2   ; reloj parado
	call al_rebote		;51c5
L_51C8:
	call cuadro_partido		;51c8
	ld a,(0c5dfh)		;51cb   ; espera a que el balon quede suelto
	cp 007h		;51ce
	jr nz,L_51C8		;51d0
	ld a,(0cb39h)		;51d2
	bit 0,a		;51d5
	jr z,reanuda		;51d7
	ld a,(0ed61h)		;51d9   ; fallo: se reanuda
	and a			;51dc
	jp m,reanuda		;51dd
	ld a,001h		;51e0
	ld (0cb2fh),a		;51e2
	ld (0cb2eh),a		;51e5
	ld (0cb31h),a		;51e8
	xor a			;51eb
	ld (0cb30h),a		;51ec
	ld (0cb28h),a		;51ef
	dec a			;51f2
	ld (0cb2bh),a		;51f3
L_51F6:
	call cuadro_partido		;51f6
	ld a,(0c53ch)		;51f9
	and a			;51fc
	jr nz,L_51F6		;51fd
	jp L_50D2		;51ff
todos_llegaron:		; Z cuando ningun jugador tiene destino (+0x20/+0x21)
	ld hl,0c430h		;5202   ; destino del primer jugador
	ld de,0002fh		;5205
	ld b,006h		;5208
	xor a			;520a
L_520B:
	or (hl)			;520b   ; destino Y
	inc hl			;520c
	or (hl)			;520d   ; destino X
	add hl,de			;520e   ; siguiente registro
	djnz L_520B		;520f
	and a			;5211
	ret			;5212
coloca_tiros_libres:		; Destinos de la linea de tiros libres (tablas 0x526A y 0x5276) para todos menos el tirador
	ld a,(0cb36h)		;5213   ; SUPOSICION: (0xCB36) es el emparejado del infractor ya calculado; la primera version lo sacaba con pareja_infractor
	call registro_jugador		;5216   ; registro del emparejado del infractor
	ld (0cb3ah),hl		;5219
	ld de,00020h		;521c
	add hl,de			;521f
	cp 003h		;5220
	ld de,0526ah		;5222   ; tabla de un lado
	jr c,L_522A		;5225
	ld de,05276h		;5227   ; tabla del otro
L_522A:
	call pon_destino		;522a
	ld hl,0c430h		;522d
	ld c,000h		;5230
	ld b,006h		;5232
L_5234:
	ld a,(0cb36h)		;5234   ; el tirador no se mueve
	cp c			;5237
	call nz,pon_destino		;5238   ; destino de la tabla
	call siguiente_registro		;523b   ; siguiente registro
	inc c			;523e
	djnz L_5234		;523f
	ret			;5241
pose_tirador:		; Pose del tirador mirando a un lado o al otro (direccion 2 o 6)
	ex af,af'			;5242
	ld hl,(0cb3ah)		;5243   ; registro del tirador
	ld de,0000dh		;5246
	add hl,de			;5249
	ld a,(hl)			;524a
	and 0e3h		;524b   ; pose sin la direccion
	ld c,a			;524d
	ex af,af'			;524e
	and a			;524f   ; signo de la X del tirador (en A')
	ld a,008h		;5250   ; direccion 2
	jp p,L_5257		;5252
	ld a,018h		;5255   ; direccion 6
L_5257:
	or c			;5257
	ld (hl),a			;5258
	ret			;5259
pon_destino:		; Destino Y, X desde la tabla DE
	ld a,(de)			;525a   ; destino Y de la tabla
	inc de			;525b
	ld (hl),a			;525c
	inc hl			;525d
	ld a,(de)			;525e   ; destino X de la tabla
	inc de			;525f
	ld (hl),a			;5260
	dec hl			;5261
	ret			;5262
siguiente_registro:		; HL + 0x30
	push de			;5263
	ld de,00030h		;5264
	add hl,de			;5267
	pop de			;5268
	ret			;5269

; ----------------------------------------------------------------------
; DATOS posiciones_a: Seis pares (X, Y) que recorre 0x5222
;   0x526a..0x5276  (12 bytes)
DATA_posiciones_a:
	defb 03ah,038h	; 526a
	defb 02ah,048h	; 526c
	defb 04ah,048h	; 526e
	defb 02ah,054h	; 5270
	defb 04ah,054h	; 5272
	defb 060h,01eh	; 5274

; ----------------------------------------------------------------------
; DATOS posiciones_b: Seis pares (X, Y) que recorre 0x5227: las mismas X que
;   0x526A con la Y del otro lado
;   0x5276..0x5282  (12 bytes)
DATA_posiciones_b:
	defb 03ah,0c8h	; 5276
	defb 02ah,0ach	; 5278
	defb 04ah,0ach	; 527a
	defb 060h,0e2h	; 527c
	defb 02ah,0b8h	; 527e
	defb 04ah,0b8h	; 5280

; ======================================================================
; CODIGO 0x5282..0x5466  (484 bytes)
; ======================================================================


rotulo_falta:		; Prepara 0xED4D (tipo, equipo y jugador), silbato, rotulo y desplaza la ventana hacia la falta
	ld a,(0cb34h)		;5282
	cp 003h		;5285
	push af			;5287
	call registro_jugador		;5288
	ld de,0001fh		;528b   ; +0x1F: jugador en el roster
	add hl,de			;528e
	ld a,(hl)			;528f
	ld b,a			;5290
	pop af			;5291
	jr c,L_5296		;5292
	set 7,b		;5294   ; equipo derecho
L_5296:
	ld a,(0cb35h)		;5296   ; tipo de falta por 8
	add a,a			;5299
	add a,a			;529a
	add a,a			;529b
	or b			;529c
	ld (0ed4dh),a		;529d
	ld a,003h		;52a0   ; pieza 3: silbato
	call arranca_sonido		;52a2
	call rotulo_falta_marcador		;52a5   ; SUPOSICION: apunta la falta y su rotulo
	ld a,(0ece6h)		;52a8   ; solo con la ventana en el centro
	cp 080h		;52ab
	ret nz			;52ad
	ld hl,(0cb37h)		;52ae
	ld a,l			;52b1
	and a			;52b2
	ld c,008h		;52b3   ; bit 3: ventana a la izquierda
	jp p,L_52BA		;52b5
	ld c,010h		;52b8   ; bit 4: ventana a la derecha
L_52BA:
	ld a,(0c5dfh)		;52ba
	or c			;52bd
	ld (0c5dfh),a		;52be
	ld a,001h		;52c1   ; movimiento parado
	ld (0cb30h),a		;52c3
	ret			;52c6
saque:		; Saque del equipo que no cometio la falta: colocacion, cinco segundos y pase desde fuera
	ld a,(0cb34h)		;52c7
	call registro_jugador		;52ca
	call posiciones_saque		;52cd   ; posiciones del saque
	call sin_destinos		;52d0   ; sin destinos los del otro equipo
	call reinicia_estados_maquina		;52d3
	xor a			;52d6   ; sin bote forzado
	ld (0c603h),a		;52d7
	inc a			;52da
	ld (0cb30h),a		;52db
	ld (0cb2eh),a		;52de
	ld (0cb31h),a		;52e1
	ld (0ef8eh),a		;52e4
	call borra_entradas		;52e7
	call oculta_balon		;52ea   ; balon oculto mientras se colocan
	call equipo_con_balon		;52ed   ; primer jugador del equipo que saca
	ld de,00020h		;52f0   ; su destino: el punto de saque
	add hl,de			;52f3
	ld d,(hl)			;52f4
	inc hl			;52f5
	ld e,(hl)			;52f6
	dec hl			;52f7
	push hl			;52f8
	push de			;52f9
	push hl			;52fa
L_52FB:
	call cuadro_partido		;52fb
	call todos_llegaron		;52fe   ; hasta que lleguen todos
	jr nz,L_52FB		;5301
	call muestra_balon		;5303
	ld a,001h		;5306
	call espera_300		;5308   ; cinco segundos para sacar
	ld (0c603h),a		;530b
	pop hl			;530e
	ld de,00020h		;530f
	and a			;5312
	sbc hl,de		;5313
	call pose_saque		;5315   ; pose del que saca
	call retardo_maquina		;5318
L_531B:
	call cuadro_partido		;531b
	ld a,(0ecf1h)		;531e
	call lee_mando_lado		;5321   ; boton del equipo que saca
	bit 7,a		;5324
	ld c,03fh		;5326
	ld de,00000h		;5328
	jr nz,L_5336		;532b
	ld hl,(0ed7eh)		;532d   ; sin tiempo: violacion
	ld a,h			;5330
	or l			;5331
	jr nz,L_531B		;5332
	jr L_5382		;5334
L_5336:
	call controlado		;5336   ; controlado del equipo que saca
	call registro_jugador		;5339
	push hl			;533c
	pop ix		;533d
	call pase		;533f   ; pasa
	xor a			;5342
	ld (0c603h),a		;5343
L_5346:
	call cuadro_partido		;5346
	ld a,(0c5dfh)		;5349   ; espera a que alguien lo coja
	cp 007h		;534c
	jr nc,L_5346		;534e
	call reloj_en_marcha		;5350   ; reloj en marcha
	call cuenta_30s		;5353   ; cuenta de 30 segundos
	call pose_bit6		;5356
	call nz,cuenta_10s		;5359   ; y la de 10 si esta en su campo
	pop de			;535c
	pop hl			;535d
	ld a,d			;535e   ; punto del saque
	cp 039h		;535f
	ld d,008h		;5361   ; vuelve a la pista por un lado
	jr c,L_5367		;5363
	ld d,06ch		;5365   ; o por el otro
L_5367:
	ld (hl),d			;5367
	inc hl			;5368
	ld (hl),e			;5369
	dec hl			;536a
L_536B:
	push hl			;536b   ; hasta que llegue
	call cuadro_partido		;536c
	pop hl			;536f
	ld a,(hl)			;5370
	and a			;5371
	jr nz,L_536B		;5372
	xor a			;5374   ; juego normal
	ld (0cb2eh),a		;5375
	ld (0cb30h),a		;5378
	ld (0cb31h),a		;537b
	ld (0ef8eh),a		;537e
	ret			;5381
L_5382:
	pop de			;5382
	pop de			;5383
	jp violacion_5s		;5384
borra_entradas:		; 0xC5E3-0xC5E6 a cero: entradas y cuadros de boton de los dos equipos
	xor a			;5387
	ld hl,0c5e3h		;5388
	ld b,004h		;538b
L_538D:
	ld (hl),a			;538d
	inc hl			;538e
	djnz L_538D		;538f
	ret			;5391
sin_destinos:		; Borra el destino de los tres del otro equipo
	call equipo_sin_balon		;5392
	ld de,00020h		;5395
	add hl,de			;5398
	ld b,003h		;5399
L_539B:
	ld (hl),000h		;539b   ; destino Y a cero
	inc hl			;539d
	ld (hl),000h		;539e   ; destino X a cero
	dec hl			;53a0
	call siguiente_registro		;53a1   ; siguiente registro
	djnz L_539B		;53a4
	ret			;53a6
pose_saque:		; Pose 0x62 del que saca mirando hacia la pista
	push hl			;53a7
	inc hl			;53a8
	ld a,(hl)			;53a9   ; Y del que saca
	dec hl			;53aa
	cp 039h		;53ab   ; de que lado del medio (Y 0x39)?
	ld a,000h		;53ad   ; direccion 0
	jr nc,L_53B3		;53af
	ld a,004h		;53b1   ; direccion 4
L_53B3:
	add a,a			;53b3   ; por 4
	add a,a			;53b4
	ld b,a			;53b5
	ld de,0000dh		;53b6
	add hl,de			;53b9
	ld a,062h		;53ba   ; pose 0x62 de saque
	or b			;53bc
	ld (hl),a			;53bd
	inc hl			;53be
	inc hl			;53bf
	set 7,(hl)		;53c0   ; pose cambiada
	pop hl			;53c2
	ret			;53c3
posiciones_saque:		; Elige la tabla de posiciones del saque segun el lado de la falta y el campo
	push hl			;53c4
	ld de,0000fh		;53c5
	add hl,de			;53c8
	ld a,(hl)			;53c9
	pop hl			;53ca
	bit 3,a		;53cb   ; bit 3: sentido de ataque
	jp z,posiciones_saque_b		;53cd
	call pose_bit6		;53d0
	call balon_a_sacador		;53d3
	jp z,posiciones_campo_propio		;53d6   ; en su campo
L_53D9:
	bit 6,c		;53d9   ; bit 6: mitad de la falta
	jr z,L_53EC		;53db
	call punto_falta		;53dd
	jr c,L_53E7		;53e0
	ld de,0546bh		;53e2   ; tabla de posiciones 0x546B
	jr L_53F9		;53e5
L_53E7:
	ld de,05475h		;53e7
	jr L_53F9		;53ea
L_53EC:
	call punto_falta		;53ec
	jr c,L_53F6		;53ef
	ld de,05466h		;53f1
	jr L_53F9		;53f4
L_53F6:
	ld de,05470h		;53f6
L_53F9:
	call equipo_con_balon		;53f9   ; equipo que saca
	push de			;53fc
	ld de,00020h		;53fd   ; destino del primero
	add hl,de			;5400
	pop de			;5401
	ld a,(de)			;5402
	inc de			;5403
	ld (hl),a			;5404   ; destino Y de la tabla
	inc hl			;5405
	ld (hl),c			;5406   ; destino X = la de la falta
	dec hl			;5407
	ld b,002h		;5408   ; los otros dos
L_540A:
	call siguiente_registro		;540a   ; siguiente registro
	call pon_destino		;540d   ; su destino de la tabla
	djnz L_540A		;5410
	ld a,(0ecf1h)		;5412   ; equipo con el balon
	and a			;5415
	ld a,000h		;5416   ; saca el jugador 0
	jp z,da_balon		;5418
	ld a,003h		;541b   ; o el 3
	jp da_balon		;541d
punto_falta:		; H, L = posicion de la falta (Y, X); acarreo si la Y es menor de 0x39
	ld hl,(0cb37h)		;5420
	ld a,h			;5423
	ld c,l			;5424
	cp 039h		;5425
	ret			;5427
posiciones_saque_b:		; Lo mismo para el otro sentido
	call pose_bit6		;5428
	call balon_a_sacador		;542b
	jp z,posiciones_campo_propio		;542e
	jp L_53D9		;5431
balon_a_sacador:		; Da el balon al equipo del emparejado del infractor
	push af			;5434
	push bc			;5435
	push de			;5436
	push hl			;5437
	call pareja_infractor		;5438   ; par del infractor
	cp 003h		;543b   ; de que equipo es
	ld a,000h		;543d   ; saca el jugador 0
	jr c,L_5443		;543f
	ld a,003h		;5441   ; o el 3
L_5443:
	call da_balon		;5443   ; le da el balon
	pop hl			;5446
	pop de			;5447
	pop bc			;5448
	pop af			;5449
	ret			;544a
equipo_con_balon:		; HL = primer registro del equipo con el balon (0xC410 o 0xC4A0)
	push af			;544b
	ld a,(0ecf1h)		;544c   ; equipo con el balon
	and a			;544f
	ld hl,0c410h		;5450   ; izquierdo: 0xC410
	jr z,L_5458		;5453
	ld hl,0c4a0h		;5455   ; derecho: 0xC4A0
L_5458:
	pop af			;5458
	ret			;5459
equipo_sin_balon:		; HL = primer registro del otro equipo
	ld a,(0ecf1h)		;545a   ; equipo con el balon
	and a			;545d
	ld hl,0c410h		;545e   ; 0xC410 si ataca el derecho
	ret nz			;5461
	ld hl,0c4a0h		;5462   ; 0xC4A0 si ataca el izquierdo
	ret			;5465

; ----------------------------------------------------------------------
; DATOS posiciones_c: Cuatro fichas de cinco bytes (0x5466, 0x546B, 0x5470,
;   0x5475) que cargan 0x53F1, 0x53E2, 0x53F6 y 0x53E7
;   0x5466..0x547a  (20 bytes)
DATA_posiciones_c:
	defb 070h,03ah,0dch,014h,0b8h	; 5466
	defb 070h,03ah,024h,014h,048h	; 546b
	defb 004h,03ah,0dch,060h,0b8h	; 5470
	defb 004h,03ah,024h,060h,048h	; 5475

; ======================================================================
; CODIGO 0x547a..0x54bc  (66 bytes)
; ======================================================================


posiciones_campo_propio:		; Posiciones del saque en el campo propio (tablas 0x54BC-0x54C8)
	bit 6,c		;547a   ; bit 6: mitad de la falta
	jr z,L_548D		;547c
	call punto_falta		;547e
	jr c,L_5488		;5481
	ld de,054c0h		;5483   ; tabla 0x54C0
	jr L_549A		;5486
L_5488:
	ld de,054c8h		;5488
	jr L_549A		;548b
L_548D:
	call punto_falta		;548d
	jr c,L_5497		;5490
	ld de,054bch		;5492
	jr L_549A		;5495
L_5497:
	ld de,054c4h		;5497
L_549A:
	call equipo_con_balon		;549a   ; equipo que saca
	push de			;549d
	ld de,00020h		;549e   ; destino del primero
	add hl,de			;54a1
	pop de			;54a2
	call destino_tabla		;54a3   ; dos jugadores con la X de C
	call destino_tabla		;54a6
	ld a,(de)			;54a9   ; el tercero: Y e X de la tabla
	inc de			;54aa
	ld (hl),a			;54ab
	inc hl			;54ac
	ld a,(de)			;54ad
	ld (hl),a			;54ae
	ret			;54af
destino_tabla:		; Destino Y desde la tabla y la X de C, y siguiente registro
	ld a,(de)			;54b0   ; destino Y de la tabla
	inc de			;54b1
	ld (hl),a			;54b2
	inc hl			;54b3
	ld (hl),c			;54b4   ; destino X = C
	push de			;54b5
	ld de,0002fh		;54b6   ; siguiente registro (+0x30 desde +0x21)
	add hl,de			;54b9
	pop de			;54ba
	ret			;54bb

; ----------------------------------------------------------------------
; DATOS posiciones_d: Cuatro fichas de cuatro bytes (0x54BC, 0x54C0, 0x54C4,
;   0x54C8) que cargan 0x5492, 0x5483, 0x5497 y 0x5488
;   0x54bc..0x54cc  (16 bytes)
DATA_posiciones_d:
	defb 070h,03ah,014h,048h	; 54bc
	defb 070h,03ah,014h,0b8h	; 54c0
	defb 004h,03ah,060h,048h	; 54c4
	defb 004h,03ah,060h,0a0h	; 54c8

; ======================================================================
; CODIGO 0x54cc..0x567f  (435 bytes)
; ======================================================================


salto_entre_dos:		; Cuadro del salto inicial: silbato, balon arriba y salto de los dos controlados al pulsar
	ld hl,(0c600h)		;54cc   ; cuenta atras del salto
	ld a,h			;54cf
	or l			;54d0
	jr nz,silbato_salto		;54d1
	ld a,(0c53ch)		;54d3   ; balon aun sin lanzar
	and a			;54d6
	call z,lanza_balon_salto		;54d7
	ld a,(0c53bh)		;54da   ; el balon ya cae?
	and a			;54dd
	ret p			;54de
	call recoge_balon		;54df   ; alguien lo coge?
	ld a,(0c5dfh)		;54e2
	cp 007h		;54e5
	jp c,fin_salto		;54e7
	xor a			;54ea
	call lee_mando_lado		;54eb   ; boton del equipo izquierdo
	bit 7,a		;54ee
	ld a,(0c5e8h)		;54f0
	call nz,salta_por_el_balon		;54f3
	ld a,001h		;54f6
	call lee_mando_lado		;54f8   ; boton del equipo derecho
	bit 7,a		;54fb
	ld a,(0c5ebh)		;54fd
	call nz,salta_por_el_balon		;5500
	ret			;5503
silbato_salto:		; A tres segundos del lanzamiento, pieza 3 una sola vez
	ld de,000b4h		;5504   ; tres segundos antes
	sbc hl,de		;5507
	ret nc			;5509
	ld a,(0cb33h)		;550a   ; silbato ya tocado
	and a			;550d
	ret nz			;550e
	ld a,0ffh		;550f   ; una sola vez
	ld (0cb33h),a		;5511
	ld a,003h		;5514   ; pieza 3: silbato
	jp arranca_sonido		;5516
salta_por_el_balon:		; El controlado A salta (pose 0x41)
	ld (0ebd6h),a		;5519   ; jugador en curso
	call registro_jugador		;551c
	push hl			;551f
	pop ix		;5520
	ld a,(ix+00dh)		;5522   ; direccion de la pose
	and 01ch		;5525
	ld c,a			;5527
	ld a,041h		;5528   ; pose 0x41: salto
	or c			;552a
	ld (ix+00dh),a		;552b
	set 7,(ix+00fh)		;552e   ; pose cambiada
	jp salto		;5532   ; despega
palmeo_salto:		; El jugador C toca el balon en el salto entre dos: lo palmea hacia un companero (3 de 4 veces) o hacia un rival
	ld a,c			;5535
	ld (0c5e2h),a		;5536   ; SUPOSICION: ultimo poseedor
	ld a,003h		;5539   ; jugadores 0-3: palmea el del equipo izquierdo
	cp c			;553b
	jr c,L_556A		;553c
	ld a,001h		;553e   ; saltador izquierdo: jugador 1
	call registro_jugador		;5540
	push hl			;5543
	pop ix		;5544
	ld (ix+00dh),049h		;5546   ; pose de palmeo
	set 7,(ix+00fh)		;554a
	call aleatorio		;554e   ; una vez de cada cuatro al rival
	cp 040h		;5551
	jr c,L_5560		;5553
	ld a,008h		;5555   ; ventana hacia la derecha
	ld (0c5d0h),a		;5557
	ld a,002h		;555a   ; al companero 2
	ld c,07bh		;555c
	jr palmea_a		;555e
L_5560:
	xor a			;5560
	ld (0c5d0h),a		;5561
	ld a,003h		;5564   ; al rival 3
	ld c,07bh		;5566
	jr palmea_a		;5568
L_556A:
	ld a,004h		;556a   ; saltador derecho: jugador 4
	call registro_jugador		;556c
	push hl			;556f
	pop ix		;5570
	ld (ix+00dh),059h		;5572   ; pose de palmeo
	set 7,(ix+00fh)		;5576
	call aleatorio		;557a
	cp 040h		;557d
	jr nc,L_558B		;557f
	xor a			;5581
	ld (0c5d0h),a		;5582
	ld a,000h		;5585   ; al rival 0
	ld c,06bh		;5587
	jr palmea_a		;5589
L_558B:
	ld a,010h		;558b   ; ventana hacia la izquierda
	ld (0c5d0h),a		;558d
	ld a,005h		;5590   ; al companero 5
	ld c,06bh		;5592
palmea_a:		; Lanza el balon como un tiro hacia el jugador A, que se pone en pose de recibir
	ld (0c5f3h),a		;5594
	call registro_jugador		;5597
	push hl			;559a
	ld de,0000dh		;559b
	add hl,de			;559e
	ld (hl),c			;559f   ; pose de recibir
	inc hl			;55a0
	inc hl			;55a1
	set 7,(hl)		;55a2
	pop hl			;55a4
	call xy_registro		;55a5
	ld a,d			;55a8
	ld (0c5d4h),a		;55a9   ; el destino del tiro es el receptor
	ld a,e			;55ac
	ld (0c5d6h),a		;55ad
	ld a,087h		;55b0   ; balon en vuelo
	ld (0c5dfh),a		;55b2
	ld a,(0c539h)		;55b5   ; sale de la altura a la que estaba
	ld (0c53dh),a		;55b8
	jp tiro		;55bb
fin_salto:		; Acaba el salto entre dos: balon en la mano, canasta del equipo que lo tiene y sin falta pendiente
	xor a			;55be
	ld (0c602h),a		;55bf   ; salto entre dos acabado
	ld (0ed67h),a		;55c2
	ld (0c53dh),a		;55c5   ; balon fuera de la mano
	call para_balon		;55c8   ; fisica del balon a cero (la primera version la ponia a cero aqui, instruccion a instruccion)
	ld a,(0c5dfh)		;55cb   ; equipo del poseedor
	and 007h		;55ce
	cp 003h		;55d0
	ld a,062h		;55d2   ; SUPOSICION: canasta a la que ataca
	jr c,L_55D8		;55d4
	neg		;55d6
L_55D8:
	ld hl,0c5d3h		;55d8
	inc hl			;55db
	ld (hl),039h		;55dc
	inc hl			;55de
	inc hl			;55df
	ld (hl),a			;55e0
	xor a			;55e1
	ld (0ef8eh),a		;55e2   ; balon ya no lanzado
	ld (0cb33h),a		;55e5
	dec a			;55e8
	ld (0cb34h),a		;55e9   ; sin falta
	ld (0cb36h),a		;55ec
	ld (0cb35h),a		;55ef
	ld a,(0c5e8h)		;55f2   ; refresca el controlado de los dos equipos
	call controla		;55f5
	ld a,(0c5ebh)		;55f8
	jp controla		;55fb
lanza_balon_salto:		; El arbitro lanza el balon: centro de la pista, altura 0xF0 y velocidad 0x244 hacia arriba
	ld a,03ah		;55fe   ; Y del centro
	ld (0c531h),a		;5600
	ld a,000h		;5603
	ld (0c533h),a		;5605
	ld a,00fh		;5608   ; gravedad
	ld (0c53ch),a		;560a
	ld a,0f0h		;560d   ; altura de salida
	ld (0c539h),a		;560f
	ld hl,00244h		;5612   ; velocidad vertical
	ld (0c53ah),hl		;5615
	ld a,0ffh		;5618
	ld (0ef8eh),a		;561a
	ret			;561d
retardo_maquina:		; SUPOSICION: 12 cuadros de reaccion de la maquina (0xEF96/0xEF97) si estaban a cero
	ld a,(0ecf1h)		;561e
	and a			;5621
	ld hl,0ef96h		;5622
	jr z,L_5628		;5625
	inc hl			;5627
L_5628:
	ld a,(hl)			;5628
	and a			;5629
	ret nz			;562a
	ld (hl),00ch		;562b
	ret			;562d
maquina:		; Jugador no controlado: decide destino (ataque o defensa) y anda hacia el
	bit 3,(ix+00fh)		;562e   ; bit 3: atacante
	jr nz,L_5639		;5632
	call defensa_maquina		;5634   ; defiende
	jr anda_al_destino		;5637
L_5639:
	call ataque_maquina		;5639   ; ataca
anda_al_destino:		; Jugador IX: si tiene destino (+0x20/+0x21) y no espera (+0x26), DE y C = paso y direccion hacia el; si no, parado; HL = su registro
	ld h,(ix+020h)		;563c   ; destino
	ld l,(ix+021h)		;563f
	bit 7,h		;5642   ; negativo: sin destino
	jr nz,L_5668		;5644
	ld a,h			;5646
	or l			;5647
	jr z,L_5668		;5648
	ld a,(ix+026h)		;564a   ; aun esperando (+0x26)
	and a			;564d
	jr nz,L_5668		;564e
	ld d,(ix+001h)		;5650
	ld e,(ix+003h)		;5653
	ld b,010h		;5656   ; rumbo al destino
	call diferencia_xy		;5658
	call mitad_de		;565b
	call rumbo		;565e
	call vector_direccion		;5661   ; vector de la direccion
	push ix		;5664
	pop hl			;5666
	ret			;5667
L_5668:
	ld de,00000h		;5668   ; se queda parado
	ld c,03fh		;566b
	push ix		;566d
	pop hl			;566f
	ret			;5670
vector_direccion:		; DE = paso (dx, dy) de la tabla 0x567F para la direccion A; C = A
	add a,a			;5671   ; dos bytes por direccion
	ld hl,0567fh		;5672   ; tabla de pasos
	ld e,a			;5675
	ld d,000h		;5676
	add hl,de			;5678
	rrca			;5679   ; A = direccion otra vez
	ld d,(hl)			;567a   ; dy
	inc hl			;567b
	ld e,(hl)			;567c   ; dx
	ld c,a			;567d
	ret			;567e

; ----------------------------------------------------------------------
; DATOS ocho_direcciones: Ocho pares (dx, dy) con signo, las ocho direcciones
;   en el orden (-1,0) (-1,1) (0,1) (1,1) (1,0) (1,-1) (0,-1) (-1,-1): los
;   recorre 0x5672
;   0x567f..0x568f  (16 bytes)
DATA_ocho_direcciones:
	defb 0ffh,000h	; 567f
	defb 0ffh,001h	; 5681
	defb 000h,001h	; 5683
	defb 001h,001h	; 5685
	defb 001h,000h	; 5687
	defb 001h,0ffh	; 5689
	defb 000h,0ffh	; 568b
	defb 0ffh,0ffh	; 568d

; ======================================================================
; CODIGO 0x568f..0x57e7  (344 bytes)
; ======================================================================


tras_canasta:		; Saque de fondo tras una canasta: recoge el defensor, sale de la linea, cinco segundos para pasar
	ld a,001h		;568f   ; todo bloqueado
	ld (0cb2eh),a		;5691
	ld (0cb2fh),a		;5694
	ld (0cb30h),a		;5697
	ld (0c5f2h),a		;569a
	ld (0cb32h),a		;569d
	ld (0cb31h),a		;56a0
	ld (0ef8eh),a		;56a3
	call reinicia_estados_maquina		;56a6
	call espera_aterrizaje		;56a9   ; espera a que caiga el que ha tirado
	call posiciones_tras_canasta		;56ac   ; posiciones y quien saca
	ld a,(0cb2bh)		;56af
	call registro_jugador		;56b2
	ld (0cb2ch),hl		;56b5
L_56B8:
	call cuadro_partido		;56b8   ; hasta que recoja el balon
	ld a,(0c5dfh)		;56bb
	ld b,a			;56be
	ld a,(0cb2bh)		;56bf
	cp b			;56c2
	jr nz,L_56B8		;56c3
	ld a,0ffh		;56c5   ; tiro resuelto
	ld (0ed61h),a		;56c7
	ld hl,(0cb2ch)		;56ca
	push hl			;56cd
	push hl			;56ce
	pop ix		;56cf
	call tras_la_linea		;56d1   ; destino detras de la linea de fondo
L_56D4:
	call cuadro_partido		;56d4
	ld hl,(0cb2ch)		;56d7   ; hasta que llegue
	ld de,00020h		;56da
	add hl,de			;56dd
	ld a,(hl)			;56de
	inc hl			;56df
	or (hl)			;56e0
	jr nz,L_56D4		;56e1
	call mira_pista		;56e3   ; mirando a la pista
	xor a			;56e6
	ld (0cb28h),a		;56e7
	ld (0cb32h),a		;56ea
	call borra_entradas		;56ed   ; entradas a cero
L_56F0:
	call cuadro_partido		;56f0
	ld a,(0c5f3h)		;56f3   ; hasta que llegue el receptor
	call registro_jugador		;56f6
	ld de,00020h		;56f9
	add hl,de			;56fc
	ld a,(hl)			;56fd
	inc hl			;56fe
	or (hl)			;56ff
	jr nz,L_56F0		;5700
	xor a			;5702
	ld (0cb31h),a		;5703
	ld (0c5f2h),a		;5706
	ld (0ef8eh),a		;5709
	inc a			;570c
	ld (0c603h),a		;570d   ; bote forzado
	ld a,(0c5dfh)		;5710   ; SUPOSICION: el que saca
	ld (0ef8dh),a		;5713
	call espera_300		;5716   ; cinco segundos para sacar
	pop ix		;5719
	call retardo_maquina		;571b
L_571E:
	call cuadro_partido		;571e
	ld a,(0c5dfh)		;5721
	bit 6,a		;5724   ; bit 6: ya ha pasado
	jr nz,saque_hecho		;5726
	ld hl,(0ed7eh)		;5728   ; sin tiempo: violacion
	ld a,h			;572b
	or l			;572c
	jr nz,L_571E		;572d
	jr violacion_saque		;572f
saque_hecho:		; Pase de saque hecho: cuentas de 10 y 30 segundos y vuelta al juego
	xor a			;5731
	ld (0c603h),a		;5732   ; sin bote forzado
	ld (0cb30h),a		;5735   ; movimiento libre
	dec a			;5738
	ld (0ef8dh),a		;5739   ; SUPOSICION: sin sacador
	call cuenta_30s		;573c   ; cuenta de 30 segundos
	call cuenta_10s		;573f   ; y de 10
	ld hl,(0cb2ch)		;5742   ; SUPOSICION: destino Y = su Y actual
	inc hl			;5745
	ld a,(hl)			;5746
	ld de,0001fh		;5747
	add hl,de			;574a
	ld (hl),a			;574b   ; destino Y del sacador
	xor a			;574c
	ld (0cb2fh),a		;574d   ; defensa y ataque libres
	ld (0cb2eh),a		;5750
	dec a			;5753
	ld (0cb2bh),a		;5754   ; sin recogedor
	ret			;5757
violacion_saque:		; Cinco segundos sin sacar: 5 SECOND
	ld a,002h		;5758   ; rotulo 2: 5 SECOND
	ld (0cb35h),a		;575a
	ld a,(0c5dfh)		;575d
	ld (0cb34h),a		;5760
	xor a			;5763
	ld (0cb2fh),a		;5764
	dec a			;5767
	ld (0cb2bh),a		;5768
	ld (0ef8dh),a		;576b
	ret			;576e
espera_aterrizaje:		; Espera a que el ultimo que ha tirado (0xED64) toque el suelo
	ld a,(0ed64h)		;576f
	call registro_jugador		;5772
	ld de,0000ch		;5775
	add hl,de			;5778
L_5779:
	ld a,(hl)			;5779   ; gravedad del que tiro
	and a			;577a
	ret z			;577b   ; ya en el suelo
	push hl			;577c
	call cuadro_partido		;577d   ; un cuadro mas
	pop hl			;5780
	jr L_5779		;5781
mira_pista:		; Pose del que saca mirando hacia la pista (direccion 6 o 2)
	ld ix,(0cb2ch)		;5783
	ld a,(ix+003h)		;5787   ; X del sacador
	and a			;578a
	ld a,006h		;578b   ; direccion 6
	jp p,L_5794		;578d
	add a,004h		;5790   ; o la opuesta (2)
	and 007h		;5792
L_5794:
	add a,a			;5794   ; por 4
	add a,a			;5795
	ld b,a			;5796
	ld a,(ix+00dh)		;5797   ; pose actual
	and 0e3h		;579a   ; sin direccion
	or b			;579c
	ld (ix+00dh),a		;579d   ; con la nueva
	ret			;57a0
tras_la_linea:		; Destino del que saca detras de la linea de fondo (Y 0x60, X +-0x68)
	ld a,(ix+003h)		;57a1
	and a			;57a4
	ld a,068h		;57a5
	jp p,L_57AC		;57a7
	neg		;57aa
L_57AC:
	ld (ix+020h),060h		;57ac
	ld (ix+021h),a		;57b0
	ret			;57b3
posiciones_tras_canasta:		; Destinos de los seis desde las tablas 0x57E7 o 0x57F6; la marcada con 1 es el receptor
	call recoge_tras_canasta		;57b4   ; quien saca
	cp 003h		;57b7
	ld hl,057e7h		;57b9   ; un lado
	jr c,L_57C1		;57bc
	ld hl,057f6h		;57be   ; el otro
L_57C1:
	ld iy,0c410h		;57c1
	ld c,000h		;57c5
	ld b,006h		;57c7
L_57C9:
	cp c			;57c9
	jr z,L_57DE		;57ca
	ex af,af'			;57cc
	ld a,(hl)			;57cd
	inc hl			;57ce
	and a			;57cf
	jr z,L_57D6		;57d0
	ld a,c			;57d2   ; receptor del saque
	ld (0c5f3h),a		;57d3
L_57D6:
	ex af,af'			;57d6
	ld d,(hl)			;57d7
	inc hl			;57d8
	ld e,(hl)			;57d9
	inc hl			;57da
	call destino_iy		;57db   ; destino del jugador
L_57DE:
	ld de,00030h		;57de
	add iy,de		;57e1
	inc c			;57e3
	djnz L_57C9		;57e4
	ret			;57e6

; ----------------------------------------------------------------------
; DATOS posiciones_e: Cinco tripletes (lado, X, Y) que recorre 0x57B9
;   0x57e7..0x57f6  (15 bytes)
DATA_posiciones_e:
	defb 000h,060h,048h	; 57e7
	defb 001h,060h,0b8h	; 57ea
	defb 000h,014h,03eh	; 57ed
	defb 000h,03ah,01ah	; 57f0
	defb 000h,060h,03eh	; 57f3

; ----------------------------------------------------------------------
; DATOS posiciones_f: Cinco tripletes (lado, X, Y) que recorre 0x57BE
;   0x57f6..0x5805  (15 bytes)
DATA_posiciones_f:
	defb 000h,014h,0aeh	; 57f6
	defb 000h,03ah,0d2h	; 57f9
	defb 000h,060h,0aeh	; 57fc
	defb 000h,060h,0b8h	; 57ff
	defb 001h,060h,048h	; 5802

; ======================================================================
; CODIGO 0x5805..0x5a85  (640 bytes)
; ======================================================================


recoge_tras_canasta:		; El defensor mas cercano al balon va a por el (0xCB2B y 0xCB26)
	ld a,(0c533h)		;5805   ; lado del balon
	and a			;5808
	ld c,000h		;5809
	ld hl,0c410h		;580b
	jp m,L_5816		;580e
	ld c,003h		;5811   ; equipo derecho
	ld hl,0c4a0h		;5813
L_5816:
	exx			;5816
	ld hl,000ffh		;5817
	exx			;581a
	ld b,003h		;581b
L_581D:
	push bc			;581d
	push hl			;581e
	ld de,0c530h		;581f   ; distancia al balon
	call xy_dos_registros		;5822
	call diferencia_xy		;5825
	call distancia		;5828
	pop hl			;582b
	pop bc			;582c
	ld d,c			;582d
	ld e,a			;582e
	push de			;582f
	exx			;5830
	pop de			;5831
	call menor		;5832   ; se queda el mas cercano
	exx			;5835
	ld de,00030h		;5836
	add hl,de			;5839
	inc c			;583a
	djnz L_581D		;583b
	exx			;583d
	ld a,h			;583e
	exx			;583f
	ld (0cb2bh),a		;5840   ; el que saca
	ld (0cb26h),a		;5843
	ld c,a			;5846
	ld a,0ffh		;5847
	ld (0cb27h),a		;5849
	ld hl,0c5d3h		;584c   ; destino: el balon
	call xy_registro		;584f
	push de			;5852
	ld a,c			;5853
	ld de,00020h		;5854
	call registro_jugador		;5857
	add hl,de			;585a
	pop de			;585b
	ld (hl),d			;585c
	inc hl			;585d
	ld (hl),e			;585e
	ret			;585f
menor:		; DE = el menor por E de DE y HL
	ld a,e			;5860
	cp l			;5861
	ret nc			;5862
	ex de,hl			;5863
	ret			;5864
defensa_maquina:		; Defensor no controlado: se coloca entre su par (+0x25) y la canasta, o le sigue si su par corre a un destino
	ld a,(0cb2fh)		;5865   ; movimiento de la defensa bloqueado
	and a			;5868
	ret nz			;5869
	ld a,(ix+020h)		;586a   ; ya tiene destino
	or (ix+021h)		;586d
	ret nz			;5870
	ld a,(ix+025h)		;5871   ; su par
	call registro_jugador		;5874
	push hl			;5877
	pop iy		;5878
	ld a,(iy+020h)		;587a   ; su par va a un destino: le sigue
	or (iy+021h)		;587d
	jp nz,sigue_par		;5880
	push hl			;5883
	ex de,hl			;5884
	ld hl,0c5d7h		;5885   ; SUPOSICION: canasta que defiende (0xC5D7)
	call xy_dos_registros		;5888
	ld a,(0cb2eh)		;588b   ; con el juego parado: a un lado de la pista
	and a			;588e
	jr z,L_589E		;588f
	ld l,000h		;5891
	ld a,039h		;5893
	cp (ix+001h)		;5895
	ld h,008h		;5898
	jr c,L_589E		;589a
	ld h,06ch		;589c
L_589E:
	call diferencia_xy		;589e
	call mitad_de		;58a1
	call angulo		;58a4   ; angulo del par a la canasta
	ld b,a			;58a7
	call controlado		;58a8   ; controlado del equipo con el balon
	call registro_jugador		;58ab
	pop de			;58ae
	push bc			;58af
	call xy_dos_registros		;58b0
	call diferencia_xy		;58b3
	call mitad_de		;58b6
	call angulo		;58b9   ; angulo del par al controlado
	pop bc			;58bc
	ld c,a			;58bd
	add a,b			;58be   ; bisectriz de los dos angulos
	rra			;58bf
	ld d,a			;58c0
	ld a,b			;58c1
	cp c			;58c2
	jr nc,L_58C8		;58c3
	ld b,c			;58c5
	ld c,a			;58c6
	ld a,b			;58c7
L_58C8:
	sub c			;58c8
	cp 080h		;58c9
	ld a,d			;58cb
	jr c,L_58D0		;58cc
	xor 080h		;58ce
L_58D0:
	push af			;58d0
	ld hl,00010h		;58d1   ; 16 unidades en esa direccion
	call por_coseno		;58d4
	pop af			;58d7
	push hl			;58d8
	ld hl,00010h		;58d9
	call por_seno		;58dc
	ld e,(iy+002h)		;58df
	ld d,(iy+003h)		;58e2
	add hl,de			;58e5
	ld a,h			;58e6
	ld (0c609h),a		;58e7   ; X del punto de marcaje
	ld e,(iy+000h)		;58ea
	ld d,(iy+001h)		;58ed
	pop hl			;58f0
	add hl,de			;58f1
	ld a,h			;58f2
	ld (0c608h),a		;58f3   ; Y del punto de marcaje
	push ix		;58f6
	pop hl			;58f8
	call xy_registro		;58f9
	ld hl,(0c608h)		;58fc
	ld a,h			;58ff
	call limita_60		;5900   ; X limitada a +-0x60
	ld h,l			;5903
	ld l,a			;5904
	push hl			;5905
	call diferencia_xy		;5906
	call distancia		;5909
	pop hl			;590c
	cp 00ch		;590d   ; a menos de 12 no se mueve
	ret c			;590f
	ld (ix+020h),h		;5910   ; destino nuevo
	ld (ix+021h),l		;5913
	ret			;5916
sigue_par:		; Destino 12 unidades por delante del destino de su par, con un retardo de reaccion
	call controlados		;5917   ; controlado del equipo con el balon
	call registro_jugador		;591a
	call xy_registro		;591d   ; su posicion
	ld h,(iy+020h)		;5920   ; destino del par
	ld l,(iy+021h)		;5923
	push hl			;5926
	ex de,hl			;5927
	call diferencia_xy		;5928
	call mitad_de		;592b
	call angulo		;592e   ; angulo del controlado al destino
	push af			;5931
	ld hl,0000ch		;5932   ; 12 unidades
	call por_coseno		;5935
	pop af			;5938
	pop de			;5939
	ex af,af'			;593a
	ld a,h			;593b
	add a,d			;593c   ; Y del destino mas dy
	ld d,a			;593d
	ex af,af'			;593e
	push de			;593f
	ld hl,0000ch		;5940
	call por_seno		;5943
	pop de			;5946
	ld a,h			;5947
	add a,e			;5948   ; X del destino mas dx
	call limita_60		;5949
	ld e,a			;594c
	push de			;594d
	ld h,(ix+001h)		;594e   ; posicion del defensor
	ld l,(ix+003h)		;5951
	call diferencia_xy		;5954
	call distancia		;5957   ; distancia al punto nuevo
	cp 004h		;595a   ; a menos de 4 no se mueve
	pop de			;595c
	ret c			;595d
	call destino_ix		;595e   ; destino nuevo
	jp retardo_reaccion		;5961   ; y retardo de reaccion
limita_60:		; A con signo limitado a +-0x60
	ld c,a			;5964
	bit 7,c		;5965   ; signo
	push af			;5967
	jr z,L_596D		;5968
	neg		;596a   ; valor absoluto
	ld c,a			;596c
L_596D:
	ld a,060h		;596d
	cp c			;596f
	jr nc,L_5974		;5970
	ld c,060h		;5972
L_5974:
	pop af			;5974
	ld a,c			;5975
	ret z			;5976
	neg		;5977
	ret			;5979
retardo_reaccion:		; Retardo al azar (+0x26) segun el nivel del equipo (roster +3, 1-8)
	ld a,(0cb25h)		;597a   ; SUPOSICION: reboteador del otro equipo
	and a			;597d
	ret p			;597e
	ld a,(0ecf1h)		;597f
	and 001h		;5982
	ld hl,0c61ah		;5984
	jr z,L_598C		;5987
	ld hl,0c706h		;5989
L_598C:
	ld b,(hl)			;598c
	ld a,008h		;598d   ; 9 menos el nivel
	sub b			;598f
	inc a			;5990
	ld e,006h		;5991   ; por 6
	call multiplica		;5993
	ld b,l			;5996
	call aleatorio		;5997   ; azar de 0 a 63 por debajo del limite
	and 03fh		;599a
	cp b			;599c
	jr nc,L_598C		;599d
	add a,00ch		;599f   ; minimo 12 cuadros mas el de su par
	add a,(iy+026h)		;59a1
	ld (ix+026h),a		;59a4
	ret			;59a7
por_coseno:		; HL por la tabla 0xC200 en A-0x40, con signo
	push hl			;59a8
	call tabla_c2_desfase		;59a9
	jr L_59B2		;59ac
por_seno:		; HL por la tabla 0xC200 en A, con signo
	push hl			;59ae
	call tabla_c2		;59af
L_59B2:
	ld a,d			;59b2   ; signo del factor
	and a			;59b3
	pop hl			;59b4
	push af			;59b5
	ld d,000h		;59b6
	call multiplica16		;59b8   ; por HL
	pop af			;59bb
	ret p			;59bc
	jp niega_hl		;59bd   ; negativo
ataque_maquina:		; Atacante no controlado: sigue la jugada en curso (0xC616) paso a paso
	ld a,(0cb2eh)		;59c0   ; movimiento bloqueado
	and a			;59c3
	ret nz			;59c4
	ld a,(ix+020h)		;59c5   ; ya tiene destino
	or (ix+021h)		;59c8
	ret nz			;59cb
	ld a,(ix+022h)		;59cc   ; su jugada (+0x22): 0x3F = sin jugada (la primera version miraba una sola para todos)
	cp 03fh		;59cf   ; 0x3F: sin jugada
	ret z			;59d1   ; sin jugada: nada
	and 007h		;59d2   ; numero de formacion
	cp 006h		;59d4   ; solo las formaciones 0 a 5
	ret nc			;59d6   ; otra cosa: nada
	ld a,(0ebd6h)		;59d7
	call paso_formacion		;59da   ; paso de la jugada para este jugador
	ld a,(hl)			;59dd
	inc hl			;59de
	ld (ix+026h),a		;59df   ; espera antes de moverse
	ld d,(hl)			;59e2
	inc hl			;59e3
	bit 7,d		;59e4   ; bit 7: fin de la jugada
	jr nz,sin_jugada		;59e6
	ld e,(hl)			;59e8
	bit 4,(ix+00fh)		;59e9   ; bit 4: lado, la X cambia de signo
	jr nz,L_59F3		;59ed
	ld a,e			;59ef
	neg		;59f0
	ld e,a			;59f2
L_59F3:
	inc hl			;59f3
	call destino_ix		;59f4   ; destino
	ld a,(0ebd6h)		;59f7
	jp avanza_paso		;59fa   ; siguiente paso
sin_jugada:		; Pone la jugada (+0x22) del jugador IX a 0x3F: sin jugada
	ld (ix+022h),03fh		;59fd   ; sin jugada para el
	ret			;5a01
formacion:		; SUPOSICION: al pedirlo (0xED87) coloca a los tres atacantes en la formacion de la zona del controlado (tabla 0x5A85)
	ld a,(0ed87h)		;5a02
	and a			;5a05
	ret z			;5a06
	xor a			;5a07
	ld (0ed87h),a		;5a08
	ld a,(0c5dfh)		;5a0b   ; ni con un pase en vuelo: bit 6 de 0xC5DF
	bit 6,a		;5a0e   ; pase en vuelo?
	ret nz			;5a10   ; si: nada
	ld a,(0cb2eh)		;5a11
	and a			;5a14
	ret nz			;5a15
	ld a,(0cb24h)		;5a16   ; SUPOSICION: dos banderas, 0xCB24 y 0xCB25
	ld hl,0cb25h		;5a19   ; la segunda
	and (hl)			;5a1c   ; solo sigue si las dos tienen el bit 7
	ret p			;5a1d   ; alguna sin el: nada
	call controlado		;5a1e   ; controlado
	ld b,a			;5a21
	call registro_jugador		;5a22
	push hl			;5a25
	pop ix		;5a26
	ld a,(ix+001h)		;5a28   ; Y del controlado
	ld hl,05a85h		;5a2b
	ld de,0000fh		;5a2e
	cp 029h		;5a31   ; zona 0: menos de 0x29
	jr c,L_5A3B		;5a33
	add hl,de			;5a35
	cp 04bh		;5a36   ; zona 1: menos de 0x4B
	jr c,L_5A3B		;5a38
	add hl,de			;5a3a
L_5A3B:
	ld c,000h		;5a3b
	ld a,b			;5a3d
	cp 003h		;5a3e   ; equipo derecho: jugadores 3-5
	jr c,L_5A46		;5a40
	ld c,003h		;5a42
	sub 003h		;5a44
L_5A46:
	push hl			;5a46
	ld l,a			;5a47
	ld h,000h		;5a48
	ld e,l			;5a4a
	ld d,h			;5a4b
	add hl,hl			;5a4c   ; 5 bytes por jugador
	add hl,hl			;5a4d
	add hl,de			;5a4e
	pop de			;5a4f
	add hl,de			;5a50
	push hl			;5a51
	ld a,c			;5a52
	call registro_jugador		;5a53
	push hl			;5a56
	pop ix		;5a57
	pop hl			;5a59
	ld de,00030h		;5a5a
	ld b,003h		;5a5d   ; tres jugadores
L_5A5F:
	ld a,(hl)			;5a5f   ; Y de la tabla
	inc hl			;5a60
	and a			;5a61
	jr z,L_5A7D		;5a62   ; 0: este no se mueve
	push bc			;5a64
	ld c,a			;5a65
	ld a,(ix+022h)		;5a66
	cp 03fh		;5a69
	ld a,c			;5a6b
	pop bc			;5a6c
	jr nz,L_5A82		;5a6d
	ld (ix+020h),a		;5a6f   ; destino Y
	ld a,(hl)			;5a72   ; X de la tabla
	inc hl			;5a73
	inc c			;5a74
	dec c			;5a75
	jr z,L_5A7A		;5a76
	neg		;5a78   ; negada en el equipo derecho
L_5A7A:
	ld (ix+021h),a		;5a7a   ; destino X (negada en el derecho)
L_5A7D:
	add ix,de		;5a7d
	djnz L_5A5F		;5a7f
	ret			;5a81
L_5A82:
	inc hl			;5a82
	jr L_5A7D		;5a83

; ----------------------------------------------------------------------
; DATOS posiciones_g: 45 bytes que recorre 0x5A2B
;   0x5a85..0x5ab2  (45 bytes)
DATA_posiciones_g:
	defb 000h,03ah,024h,060h,048h,03ah,024h,000h,060h,048h,03ah,024h,060h,048h,000h	; 5a85  .:$`H:$.`H:$`H.
	defb 000h,014h,048h,060h,048h,014h,048h,000h,060h,048h,014h,048h,060h,048h,000h	; 5a94  ..H`H.H.`H.H`H.
	defb 000h,014h,048h,03ah,024h,014h,048h,000h,03ah,024h,014h,048h,03ah,024h,000h	; 5aa3  ..H:$.H.:$.H:$.

; ======================================================================
; CODIGO 0x5ab2..0x5b5c  (170 bytes)
; ======================================================================


al_rebote:		; Tras un tiro el mas cercano a la canasta de cada equipo va a por el rebote
	ld a,(0cb2eh)		;5ab2   ; ataque bloqueado
	and a			;5ab5
	ret nz			;5ab6
	push af			;5ab7
	ld a,(0cb24h)		;5ab8   ; reboteadores ya elegidos?
	and a			;5abb
	call m,reboteadores		;5abc   ; elige los dos
	pop af			;5abf
	ret			;5ac0
reboteadores:		; Atacante y defensor mas cercanos a la canasta (0xCB24/0xCB27 y 0xCB25/0xCB26) con destino al aro
	call cercano_ataque		;5ac1
	ld (0cb24h),a		;5ac4   ; reboteador atacante
	ld (0cb27h),a		;5ac7
	call destino_canasta		;5aca
	call cercano_defensa		;5acd
	ld (0cb25h),a		;5ad0   ; reboteador defensor
	ld (0cb26h),a		;5ad3
destino_canasta:		; Destino del jugador A: la canasta 0xC5D3
	ld de,0c5d3h		;5ad6
destino_punto:		; Destino del jugador A: la posicion del registro DE
	call registro_jugador		;5ad9   ; registro del jugador
	push hl			;5adc
	pop iy		;5add
	ex de,hl			;5adf
	call xy_registro		;5ae0   ; posicion del punto DE
	jp destino_iy		;5ae3   ; como destino
cercano_defensa:		; Jugador del equipo sin balon mas cercano a la canasta
	ld hl,000ffh		;5ae6   ; distancia minima de partida
	ld c,000h		;5ae9
	ld b,003h		;5aeb
	ld a,(0ecf1h)		;5aed   ; equipo con el balon
	and a			;5af0
	jr nz,L_5B06		;5af1
	ld c,003h		;5af3   ; defiende el derecho: 3-5
	jr L_5B06		;5af5
cercano_ataque:		; Jugador del equipo con el balon mas cercano a la canasta
	ld hl,000ffh		;5af7   ; distancia minima de partida
	ld c,000h		;5afa
	ld b,003h		;5afc
	ld a,(0ecf1h)		;5afe   ; equipo con el balon
	and a			;5b01
	jr z,L_5B06		;5b02
	ld c,003h		;5b04   ; ataca el derecho: 3-5
L_5B06:
	ld a,c			;5b06   ; jugador C
	push bc			;5b07
	push hl			;5b08
	call registro_jugador		;5b09
	ld de,0c5d3h		;5b0c   ; canasta
	call xy_dos_registros		;5b0f
	call diferencia_xy		;5b12
	call absolutos_7f		;5b15   ; abs de las diferencias
	call distancia		;5b18   ; distancia a la canasta
	pop hl			;5b1b
	pop bc			;5b1c
	ld d,c			;5b1d
	ld e,a			;5b1e
	cp l			;5b1f   ; mas cerca que el mejor?
	jr nc,L_5B23		;5b20
	ex de,hl			;5b22   ; nuevo mejor
L_5B23:
	inc c			;5b23
	djnz L_5B06		;5b24
	ld a,h			;5b26
	ret			;5b27
absolutos_7f:		; Abs de H y L limitado a 0x7F
	ex de,hl			;5b28
	call absoluto_7f		;5b29
	ex de,hl			;5b2c
absoluto_7f:		; A = abs(HL) limitado a 0x7F
	ld a,h			;5b2d
	and a			;5b2e
	ld a,l			;5b2f
	jp p,L_5B35		;5b30
	neg		;5b33
L_5B35:
	cp 080h		;5b35
	jr c,L_5B3B		;5b37
	ld a,07fh		;5b39
L_5B3B:
	ld l,a			;5b3b
	ld h,000h		;5b3c
	ret			;5b3e
posicion_defensa:		; DE = posicion de defensa del jugador A (tabla 0x5B5C o 0x5B62 segun el lado)
	push hl			;5b3f
	ld hl,05b62h		;5b40
	bit 4,(ix+00fh)		;5b43
	jr z,L_5B4C		;5b47
	ld hl,05b5ch		;5b49
L_5B4C:
	cp 003h		;5b4c
	jr c,L_5B52		;5b4e
	sub 003h		;5b50
L_5B52:
	add a,a			;5b52   ; dos bytes por jugador
	ld e,a			;5b53
	ld d,000h		;5b54
	add hl,de			;5b56
	ld d,(hl)			;5b57   ; Y de defensa
	inc hl			;5b58
	ld e,(hl)			;5b59   ; X de defensa
	pop hl			;5b5a
	ret			;5b5b

; ----------------------------------------------------------------------
; DATOS posiciones_h: Tres pares (X, Y) que recorre 0x5B49
;   0x5b5c..0x5b62  (6 bytes)
DATA_posiciones_h:
	defb 014h,048h	; 5b5c
	defb 03ah,024h	; 5b5e
	defb 060h,048h	; 5b60

; ----------------------------------------------------------------------
; DATOS posiciones_i: Tres pares (X, Y) que recorre 0x5B40: las mismas X que
;   0x5B5C con la Y del otro lado (0x100 - Y)
;   0x5b62..0x5b68  (6 bytes)
DATA_posiciones_i:
	defb 014h,0b8h	; 5b62
	defb 03ah,0dch	; 5b64
	defb 060h,0b8h	; 5b66

; ======================================================================
; CODIGO 0x5b68..0x5f6d  (1029 bytes)
; ======================================================================


zonas_a_4:		; Cuatro en 0xC60A-0xC60C salvo las negativas
	ld hl,0c60ah		;5b68
	ld b,003h		;5b6b
L_5B6D:
	ld a,(hl)			;5b6d
	and a			;5b6e
	jp m,L_5B74		;5b6f
	ld (hl),004h		;5b72
L_5B74:
	inc hl			;5b74
	djnz L_5B6D		;5b75
	ret			;5b77
zona_jugador:		; SUPOSICION: apunta la zona de la pista de cada atacante en 0xC60A/0xC60D
	bit 3,c		;5b78   ; solo los atacantes
	ret z			;5b7a
	call carril		;5b7b   ; carril del jugador
	ld c,a			;5b7e
	ld a,h			;5b7f
	call pon_e847		;5b80   ; se apunta
	ld a,h			;5b83
	cp 003h		;5b84   ; jugador de 0 a 2
	jr c,L_5B8A		;5b86
	sub 003h		;5b88
L_5B8A:
	ld h,a			;5b8a
	ld a,c			;5b8b
	ld c,h			;5b8c
	jr pon_e844		;5b8d
pon_e847:		; (0xC60D + jugador mod 3) = C
	push hl			;5b8f
	ld hl,0c60dh		;5b90   ; tabla de carriles
	call indice_mod3		;5b93
	ld (hl),c			;5b96   ; guarda C
	pop hl			;5b97
	ret			;5b98
lee_e847:		; A = (0xC60D + jugador mod 3)
	push hl			;5b99
	ld hl,0c60dh		;5b9a   ; tabla de carriles
	call indice_mod3		;5b9d
	ld a,(hl)			;5ba0   ; lee
	pop hl			;5ba1
	ret			;5ba2
lee_e844:		; A = (0xC60A + jugador mod 3)
	push hl			;5ba3
	ld hl,0c60ah		;5ba4   ; tabla de zonas
	call indice_mod3		;5ba7
	ld a,(hl)			;5baa   ; lee
	pop hl			;5bab
	ret			;5bac
pon_e844:		; (0xC60A + C mod 3) = A mod 3
	push hl			;5bad
	ld hl,0c60ah		;5bae   ; tabla de zonas
	call indice_mod3		;5bb1
	ld a,c			;5bb4
	cp 003h		;5bb5   ; jugador de 0 a 2
	jr c,L_5BBB		;5bb7
	sub 003h		;5bb9
L_5BBB:
	ld (hl),a			;5bbb
	pop hl			;5bbc
	ret			;5bbd
indice_mod3:		; HL + (A mod 3)
	push de			;5bbe
	cp 003h		;5bbf
	jr c,L_5BC5		;5bc1
	sub 003h		;5bc3
L_5BC5:
	ld e,a			;5bc5
	ld d,000h		;5bc6
	add hl,de			;5bc8
	pop de			;5bc9
	ret			;5bca
carril:		; A = carril segun la Y: 0 de 0x08 a 0x29, 1 hasta 0x4A, 2 hasta 0x6C
	push bc			;5bcb
	push de			;5bcc
	call carril_c		;5bcd   ; C = carril
	ld a,c			;5bd0   ; a A
	pop de			;5bd1
	pop bc			;5bd2
	ret			;5bd3
carril_c:		; C = carril de la Y (+1) del jugador IX; NZ si esta en alguno
	ld b,(ix+001h)		;5bd4
	ld c,000h		;5bd7
	ld a,b			;5bd9
	ld de,00829h		;5bda   ; carril 0: 0x08-0x28
	call entre		;5bdd
	ret nz			;5be0
	inc c			;5be1
	ld a,b			;5be2
	ld de,0294ah		;5be3   ; carril 1: 0x29-0x49
	call entre		;5be6
	ret nz			;5be9
	inc c			;5bea
	ld a,b			;5beb
	ld de,04a6ch		;5bec   ; carril 2: 0x4A-0x6B
entre:		; NZ si A esta entre D y E-1
	cp d			;5bef   ; por debajo de D?
	jr c,L_5BF7		;5bf0
	cp e			;5bf2   ; de E en adelante?
	jr nc,L_5BF7		;5bf3
	and a			;5bf5   ; dentro: NZ
	ret			;5bf6
L_5BF7:
	xor a			;5bf7
	ret			;5bf8
destino_ix:		; Destino (D, E) del jugador IX
	ld (ix+020h),d		;5bf9
	ld (ix+021h),e		;5bfc
	ret			;5bff
destino_iy:		; Destino (D, E) del jugador IY
	ld (iy+020h),d		;5c00
	ld (iy+021h),e		;5c03
	ret			;5c06
inicia_formacion:		; Arranca la formacion A (0-5) del equipo con el balon: pasos de cada atacante desde la tabla del equipo en 0xC84F
	ld hl,0c60ah		;5c07
	ld b,003h		;5c0a
	and 007h		;5c0c
	cp 006h		;5c0e   ; solo las formaciones 0 a 5
	ret nc			;5c10
	ld c,a			;5c11
	ld a,004h		;5c12   ; 4 = alguno sin zona
L_5C14:
	cp (hl)			;5c14
	ret z			;5c15
	bit 7,(hl)		;5c16
	ret nz			;5c18
	inc hl			;5c19
	djnz L_5C14		;5c1a
	ld a,c			;5c1c
	call pon_formacion		;5c1d   ; formacion en +0x22 de los tres
	ld a,c			;5c20
	push bc			;5c21
	call bloque_formacion		;5c22   ; bloque de la tabla del equipo
	call punteros_formacion		;5c25   ; punteros de pasos de cada jugador
	pop bc			;5c28
	ld a,c			;5c29
	and 007h		;5c2a
	ld (0c616h),a		;5c2c   ; formacion en curso
	inc a			;5c2f
	ld (0cb1fh),a		;5c30   ; letra que muestra FORMATION=
	xor a			;5c33
	ld (0c5feh),a		;5c34
	ret			;5c37
pon_formacion:		; +0x22 de los tres atacantes = A
	ld b,a			;5c38
	ld hl,0c432h		;5c39   ; equipo izquierdo
	ld a,(0ecf1h)		;5c3c
	and a			;5c3f
	jr z,L_5C45		;5c40
	ld hl,0c4c2h		;5c42   ; equipo derecho
L_5C45:
	ld a,b			;5c45
	ld b,003h		;5c46
	ld de,00030h		;5c48
L_5C4B:
	ld (hl),a			;5c4b
	add hl,de			;5c4c
	djnz L_5C4B		;5c4d
	ret			;5c4f
pon_formacion_huerfano:		; Huerfano: pondria C con el bit 7 en +0x22 (el puntero del equipo derecho sigue mal: 0x4C52 en vez de 0xC4C2)
	set 7,c		;5c50   ; bit 7 en la formacion
	ld a,(0ecf1h)		;5c52
	ld hl,0c432h		;5c55   ; equipo izquierdo
	and a			;5c58
	jr z,L_5C5E		;5c59
	ld hl,04c52h		;5c5b   ; equipo derecho: puntero 0x4C52 (deberia ser 0xC4C2)
L_5C5E:
	ld b,003h		;5c5e
	ld de,00030h		;5c60
L_5C63:
	ld (hl),c			;5c63
	add hl,de			;5c64
	djnz L_5C63		;5c65
	ret			;5c67
bloque_formacion:		; HL = guion de 24 bytes: 144 x formacion + 24 x (2 x carril del controlado + bit al azar)
	call tabla_equipo		;5c68
	call controlados		;5c6b
	call lee_e847		;5c6e   ; zona del controlado
	add a,a			;5c71
	ld b,a			;5c72
	ld a,r		;5c73   ; al azar una de dos variantes
	and 001h		;5c75
	add a,b			;5c77
	nop			;5c78
	add a,a			;5c79   ; 24 bytes por variante
	add a,a			;5c7a
	add a,a			;5c7b
	ld b,a			;5c7c
	add a,a			;5c7d
	add a,b			;5c7e
	ld d,000h		;5c7f
	ld e,a			;5c81
	add hl,de			;5c82
	ret			;5c83
tabla_equipo:		; HL = 0xC84F + A * 0x90 (144 bytes por formacion: 6 variantes x 3 jugadores x 8)
	ld l,a			;5c84
	ld h,000h		;5c85
	add hl,hl			;5c87   ; A por 16
	add hl,hl			;5c88
	add hl,hl			;5c89
	add hl,hl			;5c8a
	ld d,h			;5c8b
	ld e,l			;5c8c
	add hl,hl			;5c8d   ; A por 128
	add hl,hl			;5c8e
	add hl,hl			;5c8f
	add hl,de			;5c90   ; A por 144
	ld de,0c84fh		;5c91   ; tabla de formaciones del equipo
	add hl,de			;5c94
	ret			;5c95
paso_formacion:		; HL = puntero al siguiente paso de la formacion del jugador A
	call puntero_paso		;5c96   ; puntero del jugador
	ld e,(hl)			;5c99   ; paso en curso
	inc hl			;5c9a
	ld d,(hl)			;5c9b
	ex de,hl			;5c9c
	ret			;5c9d
punteros_formacion:		; Puntero de cada uno de los tres atacantes: bloque mas 8 por su zona
	ld b,003h		;5c9e
	ld c,008h		;5ca0
	xor a			;5ca2
L_5CA3:
	push hl			;5ca3
	push bc			;5ca4
	push af			;5ca5
	call lee_e844		;5ca6   ; zona del jugador
	push af			;5ca9
	and a			;5caa
	jr z,L_5CB2		;5cab
	ld b,a			;5cad
	xor a			;5cae
L_5CAF:
	add a,c			;5caf
	djnz L_5CAF		;5cb0
L_5CB2:
	ld e,a			;5cb2   ; 8 bytes por zona
	ld d,000h		;5cb3
	add hl,de			;5cb5   ; puntero de pasos
	ex de,hl			;5cb6
	pop af			;5cb7
	call puntero_paso		;5cb8   ; hueco del jugador
	ld (hl),e			;5cbb   ; guarda el puntero
	inc hl			;5cbc
	ld (hl),d			;5cbd
	pop af			;5cbe
	pop bc			;5cbf
	pop hl			;5cc0
	inc a			;5cc1   ; siguiente jugador
	djnz L_5CA3		;5cc2
	ret			;5cc4
avanza_paso:		; Guarda DE como puntero de pasos del jugador A
	ex de,hl			;5cc5
	call puntero_paso		;5cc6   ; hueco del jugador
	ld (hl),e			;5cc9   ; guarda el puntero
	inc hl			;5cca
	ld (hl),d			;5ccb
	inc hl			;5ccc
	ex de,hl			;5ccd
	ret			;5cce
puntero_paso:		; HL = 0xC610 + (A mod 3) * 2
	push af			;5ccf
	cp 003h		;5cd0
	jr c,L_5CD6		;5cd2
	sub 003h		;5cd4
L_5CD6:
	add a,a			;5cd6   ; dos bytes por jugador
	push de			;5cd7
	ld e,a			;5cd8
	ld d,000h		;5cd9
	ld hl,0c610h		;5cdb   ; punteros de pasos
	add hl,de			;5cde
	pop de			;5cdf
	pop af			;5ce0
	ret			;5ce1
vigila_formacion:		; Cancela la formacion en curso si se cumple alguna condicion de corte
	ld hl,0c616h		;5ce2
	ld a,03fh		;5ce5   ; 0x3F: no hay formacion
	cp (hl)			;5ce7
	ret z			;5ce8
	call en_zona_poseedor		;5ce9   ; el poseedor ya esta cerca de la canasta
	jr z,corta_formacion		;5cec   ; dentro de la zona: corta la formacion
	call acabados		;5cee   ; dos o mas atacantes ya sin pasos
	jr c,corta_formacion		;5cf1
	call tiro_en_vuelo		;5cf3   ; tiro en vuelo
	jp m,corta_formacion		;5cf6
	call hay_formacion		;5cf9
	ret z			;5cfc   ; si no hubo robo, sigue la formacion
corta_formacion:		; Quita la formacion en curso: destino a cero y +0x22 = 0x3F en los tres atacantes, (0xC616) = 0x3F y repinta FORMATION=
	ld hl,0c430h		;5cfd   ; destinos de los tres atacantes
	ld a,(0ecf1h)		;5d00
	and a			;5d03
	jr z,L_5D09		;5d04
	ld hl,0c4c0h		;5d06   ; equipo derecho
L_5D09:
	ld de,0002eh		;5d09
	ld b,003h		;5d0c
	ld a,03fh		;5d0e
L_5D10:
	ld (hl),000h		;5d10   ; sin destino
	inc hl			;5d12
	ld (hl),000h		;5d13
	inc hl			;5d15
	ld (hl),a			;5d16   ; sin formacion
	add hl,de			;5d17
	djnz L_5D10		;5d18
	ld a,03fh		;5d1a
	ld (0c616h),a		;5d1c   ; sin formacion en curso
	ld a,080h		;5d1f   ; repinta FORMATION=
	ld (0cb1fh),a		;5d21
	ret			;5d24
tiro_en_vuelo:		; Flags de 0xC5DF: negativo con el balon en vuelo
	ld a,(0c5dfh)		;5d25
	and a			;5d28
	ret			;5d29
hay_formacion:		; NZ si (0xC5FE) valia algo, y lo pone a cero: lo pone a 0xFF 0x4958 cuando un robo llega con una formacion en curso; la primera version devolvia NZ si habia formacion en curso
	ld a,(0c5feh)		;5d2a
	and a			;5d2d
	ld a,000h		;5d2e
	ld (0c5feh),a		;5d30
	ret			;5d33
acabados:		; Acarreo si los tres atacantes ya no tienen pasos (+0x22 = 0x3F); la primera version bastaba con dos
	ld hl,0c432h		;5d34
	ld a,(0ecf1h)		;5d37
	and a			;5d3a
	jr z,L_5D40		;5d3b
	ld hl,0c4c2h		;5d3d   ; equipo derecho
L_5D40:
	ld b,003h		;5d40
	ld a,03fh		;5d42
	ld de,00030h		;5d44
	ld c,000h		;5d47
L_5D49:
	cp (hl)			;5d49   ; sin pasos
	jr nz,L_5D4D		;5d4a
	inc c			;5d4c
L_5D4D:
	add hl,de			;5d4d
	djnz L_5D49		;5d4e
	ld a,002h		;5d50   ; 2: acarreo si C es 3 (la primera version: 1, con dos)
	cp c			;5d52
	ret			;5d53
en_zona_poseedor:		; Z si el poseedor (0-5) esta dentro de la zona de tiro de su canasta (0xED82 = 0 tras zona_tiro); con el balon suelto o en el aire (6 o mas) sale sin tocar nada. La primera version comparaba su posicion con un rectangulo
	ld a,(0c5dfh)		;5d54   ; poseedor
	cp 006h		;5d57   ; 6 o mas: nadie con el balon
	ret nc			;5d59   ; nadie: tal cual
	ld (0ed83h),a		;5d5a   ; jugador al que se mira
	call zona_tiro		;5d5d   ; zona de tiro del poseedor
	ld a,(0ed82h)		;5d60   ; (0xED82): 0 = dentro de la zona
	and a			;5d63   ; Z si esta en ella
	ret			;5d64
rectangulo_huerfano:		; Huerfano: lo que queda del rectangulo de canasta de la primera version (X de 0x41 a 0x5F o de 0xA0 a 0xBE); ya no lo llama nadie
	bit 4,(hl)		;5d65   ; bit 4: lado de la canasta
	jr z,L_5D71		;5d67
	ld de,02941h		;5d69   ; X de 0x41 a 0x5F
	ld hl,04a60h		;5d6c
	jr L_5D87		;5d6f
L_5D71:
	ld de,028bfh		;5d71   ; X de 0xA0 a 0xBE
	ld hl,049a0h		;5d74
	ld a,b			;5d77   ; Y menor que el minimo?
	cp d			;5d78
	jr c,L_5D97		;5d79
	cp h			;5d7b   ; Y por encima del maximo?
	jr nc,L_5D97		;5d7c
	ld a,c			;5d7e   ; X
	cp e			;5d7f
	jr nc,L_5D97		;5d80
	cp l			;5d82
	jr c,L_5D97		;5d83
	jr L_5D95		;5d85
L_5D87:
	ld a,b			;5d87   ; Y menor que el minimo?
	cp d			;5d88
	jr c,L_5D97		;5d89
	cp h			;5d8b   ; Y por encima del maximo?
	jr nc,L_5D97		;5d8c
	ld a,c			;5d8e   ; X
	cp e			;5d8f
	jr c,L_5D97		;5d90
	cp l			;5d92
	jr nc,L_5D97		;5d93
L_5D95:
	and a			;5d95
	ret			;5d96
L_5D97:
	xor a			;5d97
	ret			;5d98

; ----------------------------------------------------------------------
; ===== Montaje de la pantalla y estado inicial =====
; ----------------------------------------------------------------------
monta_pantalla:		; SCREEN 2, graficos de sprites y patrones de la pista
	call congela_sprites		;5d99   ; pantalla parada mientras se monta
	call pon_screen2		;5d9c   ; SCREEN 2 con la BIOS
	call graficos_sprites		;5d9f   ; sprites: fijos, patrones en RAM y los atributos
	call patrones_pista		;5da2   ; los 250 patrones de la pista y los colores del AREA
	jp suelta_sprites		;5da5   ; pantalla en marcha, y vuelve
pon_screen2:		; Fondo y borde negros y SCREEN 2 por la BIOS
	ld a,001h		;5da8   ; FORCLR = BAKCLR = 1: la tabla de colores entera a 0x11
	ld (0f3ebh),a		;5daa   ; BDRCLR = 1 (negro)
	ld (0f3eah),a		;5dad   ; BAKCLR = 1
	jp 00072h		;5db0   ; BIOS INIGRP - Switches to SCREEN 2 (high resolution screen with 256*192 pixels)
graficos_sprites:		; Descomprime los patrones de jugador a la RAM, sprites de 16x16, red y balon a 0x3B00 y copia inicial de atributos
	call patrones_jugadores		;5db3   ; los 196 patrones de sprite a la RAM (0xD33D-0xE47F)
	call sprites_16x16		;5db6   ; sprites de 16x16
	call 00069h		;5db9   ; BIOS CLRSPR - Initialises all sprites
	call alterna_tabla_atributos		;5dbc   ; limpia tambien la otra tabla de atributos
	call 00069h		;5dbf   ; BIOS CLRSPR - Initialises all sprites
	call alterna_tabla_atributos		;5dc2   ; alterna la tabla de atributos
	ld de,03b00h		;5dc5   ; red de la canasta: 3 patrones de 16x16
	ld hl,09cfbh		;5dc8   ; los 96 bytes de la red
	ld bc,00060h		;5dcb   ; tres patrones de 32 bytes
	call copia_a_vram		;5dce   ; a la VRAM 0x3B00
	ld de,03b60h		;5dd1   ; balon, sombra y flecha
	ld hl,09d5bh		;5dd4   ; balon, sombra y flecha
	ld bc,00060h		;5dd7   ; tres patrones
	call copia_a_vram		;5dda   ; a la VRAM 0x3B60
	ld hl,01b00h		;5ddd   ; tabla de atributos limpia a la sombra 0xEBE5
	ld de,0ebe5h		;5de0   ; 0xEBE5: el bufer de atributos
	push de			;5de3   ; guardado
	ld bc,00080h		;5de4   ; 0x80 bytes: los 32 sprites
	push bc			;5de7   ; guardada la cuenta
	call lee_de_vram		;5de8   ; los atributos que dejo CLRSPR (Y = 209), de la VRAM al bufer
	pop bc			;5deb   ; recupera la cuenta
	pop hl			;5dec   ; HL = 0xEBE5
	ld de,0ec65h		;5ded   ; y a la segunda lista 0xEC65
	ldir		;5df0   ; copia al otro bufer, 0xEC65
	ret			;5df2
patrones_jugadores:		; Descomprime los 196 patrones de 16x16 de los jugadores en 0xD33D-0xE47F
	ld de,0d33dh		;5df3   ; primer banco: patrones 0-63
	ld hl,09dbbh		;5df6   ; primer bloque a 0xD33D
	call descomprime		;5df9   ; de 0x9DBB
	ld de,0db3dh		;5dfc   ; segundo banco: 64-127
	ld hl,0a19eh		;5dff   ; segundo bloque a 0xDB3D
	call descomprime		;5e02   ; de 0xA19E
	ld de,0e33dh		;5e05   ; tercer banco: 128-191
	ld hl,0a616h		;5e08   ; tercer bloque a 0xE33D
	call descomprime		;5e0b   ; de 0xA616
	ld de,0eb3dh		;5e0e   ; los cuatro de 0xEB3D: 192-195
	ld hl,0a9f6h		;5e11   ; cuarto bloque (solo repeticiones) a 0xEB3D
	call descomprime_rep		;5e14   ; de 0xA9F6, solo repeticiones
	jp marcador_ram		;5e17   ; el marcador descomprimido a 0xECF7, y vuelve
sprites_16x16:		; Bit 1 del registro 1 del VDP: sprites de 16x16
	ld a,(0f3e0h)		;5e1a   ; RG1SAV
	or 002h		;5e1d   ; bit 1 del registro 1: sprites de 16x16
	ld b,a			;5e1f   ; B = valor
	ld c,001h		;5e20   ; registro 1
	call 00047h		;5e22   ; BIOS WRTVDP - Writes data in the VDP-register
	ret			;5e25   ; listo
patrones_pista:		; Nombres en blanco, 250 patrones de la pista en los tres tercios y colores del AREA
	call borra_nombres		;5e26   ; nombres a 0x20
	ld de,0cb3dh		;5e29   ; a 0xCB3D provisionalmente
	ld hl,0ade4h		;5e2c   ; los 250 patrones comprimidos
	call descomprime		;5e2f   ; a 0xCB3D
	ld de,00000h		;5e32   ; desde el patron 0
	call patrones_tres_tercios		;5e35   ; a los tres tercios desde la VRAM 0
	jp colores_area		;5e38   ; colores del AREA elegida
patrones_tres_tercios:		; Copia los 2 KB de 0xCB3D a la VRAM DE y a los dos tercios siguientes
	ld hl,0cb3dh		;5e3b   ; el bufer
	ld b,003h		;5e3e   ; tres tercios de 0x800
L_5E40:
	push bc			;5e40   ; guarda la cuenta de tercios
	push hl			;5e41   ; el origen
	push de			;5e42   ; y el destino
	ld bc,00800h		;5e43   ; un tercio: 0x800 bytes
	call 0005ch		;5e46   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop de			;5e49   ; recupera el destino
	ld hl,00800h		;5e4a   ; un tercio mas
	add hl,de			;5e4d   ; el siguiente
	ex de,hl			;5e4e   ; DE = destino
	pop hl			;5e4f   ; HL = origen
	pop bc			;5e50   ; recupera la cuenta
	djnz L_5E40		;5e51   ; los tres
	ret			;5e53
borra_nombres:		; Tabla de nombres 0x1800 entera a espacios (0x20)
	ld a,020h		;5e54   ; espacio
	ld hl,01800h		;5e56   ; la tabla de nombres
	ld bc,00300h		;5e59   ; las 768 celdas
	call rellena_vram		;5e5c   ; rellena
	ret			;5e5f
inicia_partido:		; Tablas de perspectiva, semilla al azar y todas las variables de jugada a su valor de salida
	call tablas_mates		;5e60   ; tablas de perspectiva 0xC000-0xC2FF
	ld a,r		;5e63   ; semilla del azar desde el registro R
	ld l,a			;5e65   ; L = el registro R
	ld h,000h		;5e66   ; HL = semilla
	ld (0c400h),hl		;5e68   ; (0xC400): semilla del azar
	ld a,0ffh		;5e6b   ; SUPOSICION: sin repeticion de mando
	ld (0ef8dh),a		;5e6d   ; ningun jugador bloqueado
	ld (0cb2bh),a		;5e70   ; SUPOSICION: tiro forzado desactivado
	ld (0cb24h),a		;5e73   ; (0xCB24) a 0xFF
	ld (0cb25h),a		;5e76   ; (0xCB25) a 0xFF
	ld (0c5e2h),a		;5e79   ; ultimo poseedor: ninguno
	ld (0ed61h),a		;5e7c   ; nadie puede machacar
	ld (0c5f0h),a		;5e7f   ; saltadores de los dos equipos: ninguno
	ld (0c5f1h),a		;5e82   ; (0xC5F1) a 0xFF
	ld (0c5efh),a		;5e85   ; nadie ha tirado
	ld (0cb26h),a		;5e88   ; (0xCB26) a 0xFF
	ld (0cb27h),a		;5e8b   ; (0xCB27) a 0xFF
	ld (0cb34h),a		;5e8e   ; sin infractor
	ld (0cb35h),a		;5e91   ; sin tipo de falta
	ld (0cb36h),a		;5e94   ; (0xCB36) a 0xFF: nadie pasa
	ld a,001h		;5e97   ; controlado izquierdo: jugador 1
	ld (0c5e8h),a		;5e99   ; (0xC5E8) = 1: controlado de la izquierda
	ld a,004h		;5e9c   ; controlado derecho: jugador 4
	ld (0c5ebh),a		;5e9e   ; (0xC5EB) = 4: controlado de la derecha
	ld a,007h		;5ea1   ; balon suelto
	ld (0c5dfh),a		;5ea3   ; (0xC5DF) = 7: estado del partido
	ld a,03fh		;5ea6   ; sin formacion
	ld (0c616h),a		;5ea8   ; (0xC616) = 0x3F: sin formacion
	ld hl,00000h		;5eab   ; HL = 0
	ld (0ebd2h),hl		;5eae   ; sin marca de jugador
	ld hl,0d1d1h		;5eb1   ; SUPOSICION: limites de la pista
	ld (0c5dbh),hl		;5eb4   ; (0xC5DB) = 0xD1D1
	ld de,0389eh		;5eb7   ; SUPOSICION: canasta (0xC5D3) en Y 0x38, X 0x9E
	ld hl,0c5d4h		;5eba   ; 0xC5D4: la canasta
	ld (hl),d			;5ebd   ; Y de la canasta = 0x38
	inc hl			;5ebe   ; +2
	inc hl			;5ebf
	ld (hl),e			;5ec0   ; X de la canasta = 0x9E
	call tablas_equipos		;5ec1   ; tabla de cada equipo desde 0xB5F5
	call sombras_iniciales		;5ec4   ; colocacion inicial de los sprites
	call coloca_jugadores		;5ec7   ; posiciones de salida de los seis
	call sin_direccion		;5eca   ; sin direccion ni giro
	jp empareja_jugadores		;5ecd   ; parejas de marcaje en +0x25
borra_jugada:		; Pone a cero los campos +4 a +0x17 de los seis jugadores y el balon y las banderas de la jugada
	ld hl,0c414h		;5ed0   ; campo +4 del primer registro
	ld b,007h		;5ed3   ; seis jugadores y el balon
	xor a			;5ed5   ; A = 0
L_5ED6:
	push bc			;5ed6   ; guarda la cuenta de registros
	ld b,014h		;5ed7   ; 20 bytes desde +4
L_5ED9:
	ld (hl),a			;5ed9   ; un byte a cero
	inc hl			;5eda   ; siguiente
	djnz L_5ED9		;5edb   ; 20 bytes (+4 a +0x17)
	ld de,0001ch		;5edd   ; al siguiente registro (+0x30)
	add hl,de			;5ee0   ; mas 28: el +4 del registro siguiente
	pop bc			;5ee1   ; recupera la cuenta
	djnz L_5ED6		;5ee2   ; los siete (seis jugadores y el balon)
	ld (0cb30h),a		;5ee4   ; (0xCB30) a cero
	ld (0cb2eh),a		;5ee7   ; (0xCB2E) a cero
	ld (0cb2fh),a		;5eea   ; (0xCB2F) a cero
	ld (0ece7h),a		;5eed   ; (0xECE7) a cero
	ld (0c603h),a		;5ef0   ; (0xC603) a cero
	ld (0cb28h),a		;5ef3   ; (0xCB28) a cero: sin falta
	ld (0c607h),a		;5ef6   ; (0xC607) a cero
	ld (0cb31h),a		;5ef9   ; (0xCB31) a cero
	ld (0cb32h),a		;5efc   ; (0xCB32) a cero
	ld (0c5f2h),a		;5eff   ; (0xC5F2) a cero
	ld (0c5feh),a		;5f02   ; (0xC5FE) a cero: ningun robo pendiente de cortar la formacion
	ret			;5f05
borra_ram:		; Pone a cero 0xC410-0xEF97 (0x2B88 bytes): jugadores, sprites, equipos y variables
	ld hl,0c410h		;5f06   ; desde 0xC410, el registro del primer jugador
	ld bc,02b87h		;5f09   ; 0x2B87 mas el primero: hasta 0xEF97
	ld (hl),000h		;5f0c   ; el primero a cero
	ld d,h			;5f0e   ; DE = HL + 1
	ld e,l			;5f0f
	inc de			;5f10
	ldir		;5f11   ; y el resto copiando el anterior
	ret			;5f13
tablas_equipos:		; Descomprime los 720 bytes de 0xB5F5 en 0xC84F
	ld bc,002d0h		;5f14   ; 720 bytes (no los usa 0x6056: el bloque dice su fin)
	ld de,0c84fh		;5f17   ; a 0xC84F
	ld hl,0b5f5h		;5f1a   ; de 0xB5F5
	jp descomprime		;5f1d   ; descomprime y vuelve
sombras_iniciales:		; Colocacion, patrones y colores iniciales de los 28 sprites de la sombra 0xC560
	ld hl,0c560h		;5f20   ; los atributos de los jugadores
	ld b,006h		;5f23   ; seis jugadores
L_5F25:
	ld de,05f6dh		;5f25   ; colocacion de salida (0x5F6D)
	push bc			;5f28   ; guarda la cuenta
	ld b,004h		;5f29   ; cuatro sprites
L_5F2B:
	ld a,(de)			;5f2b   ; dy
	inc de			;5f2c   ; siguiente
	ld (hl),a			;5f2d   ; Y
	inc hl			;5f2e   ; siguiente byte
	ld a,(de)			;5f2f   ; dx
	inc de			;5f30   ; siguiente
	ld (hl),a			;5f31   ; X
	inc hl			;5f32   ; se salta patron y color
	inc hl			;5f33
	inc hl			;5f34
	djnz L_5F2B		;5f35   ; los cuatro
	pop bc			;5f37   ; recupera la cuenta
	djnz L_5F25		;5f38   ; los seis, con los mismos cuatro pares
	ld hl,0c562h		;5f3a   ; numero de patron de cada sprite
	ld de,00004h		;5f3d   ; cuatro bytes por atributo
	xor a			;5f40   ; patron 0
	ld b,018h		;5f41   ; 24 sprites de jugador: 0, 4, 8...
L_5F43:
	ld (hl),a			;5f43   ; numero de patron
	add hl,de			;5f44   ; atributo siguiente
	add a,004h		;5f45   ; patron siguiente: 4 bytes mas (16x16)
	djnz L_5F43		;5f47   ; los 24 sprites de jugador: patrones 0-0x5C
	ld (hl),a			;5f49   ; el 25: patron 0x60 (la red)
	add hl,de			;5f4a   ; siguiente
	ld a,06ch		;5f4b   ; balon: patrones 0x6C, 0x70, 0x74
	ld b,003h		;5f4d   ; tres mas
L_5F4F:
	ld (hl),a			;5f4f   ; patron 0x6C, 0x70, 0x74: balon, sombra, flecha
	add a,004h		;5f50   ; siguiente patron
	add hl,de			;5f52   ; siguiente atributo
	djnz L_5F4F		;5f53   ; los tres
	ld hl,0c5c0h		;5f55   ; cuatro sprites del balon y la red (0x5F75)
	ld de,05f75h		;5f58   ; los cuatro tripletes
	ld b,004h		;5f5b   ; cuatro sprites fijos
L_5F5D:
	ld a,(de)			;5f5d   ; Y
	inc de			;5f5e   ; siguiente
	ld (hl),a			;5f5f   ; al atributo
	inc hl			;5f60   ; X
	ld a,(de)			;5f61   ; X
	inc de			;5f62   ; siguiente
	ld (hl),a			;5f63   ; al atributo
	inc hl			;5f64   ; se salta el patron
	inc hl			;5f65   ; color
	ld a,(de)			;5f66   ; color
	inc de			;5f67   ; siguiente
	ld (hl),a			;5f68   ; al atributo
	inc hl			;5f69   ; siguiente atributo
	djnz L_5F5D		;5f6a   ; los cuatro
	ret			;5f6c

; ----------------------------------------------------------------------
; DATOS sprites_jugador_yx: Cuatro pares (Y, X) de los cuatro sprites de un
;   jugador: 0x5F20 los copia a los seis grupos de cuatro atributos de 0xC560
;   0x5f6d..0x5f75  (8 bytes)
DATA_sprites_jugador_yx:
	defb 01fh,008h	; 5f6d
	defb 00fh,008h	; 5f6f
	defb 01fh,008h	; 5f71
	defb 00fh,008h	; 5f73

; ----------------------------------------------------------------------
; DATOS sprites_fijos: Cuatro tripletes (Y, X, color) de los cuatro sprites de
;   0xC5C0 (los que no son jugadores): 0x5F55 los copia saltandose el byte del
;   patron
;   0x5f75..0x5f81  (12 bytes)
DATA_sprites_fijos:
	defb 000h,0f8h,00ah	; 5f75
	defb 0f2h,0f8h,00ah	; 5f78
	defb 0f1h,0f8h,001h	; 5f7b
	defb 0d1h,000h,008h	; 5f7e

; ======================================================================
; CODIGO 0x5f81..0x5fd2  (81 bytes)
; ======================================================================


coloca_jugadores:		; Posiciones de salida y velocidades segun la plantilla
	call posiciones_salida		;5f81   ; los seis jugadores a sus posiciones de saque
	jp velocidades		;5f84   ; y las velocidades, y vuelve
posiciones_salida:		; Y, X, banderas y pose de los seis jugadores e Y, X del balon desde 0x5FD2
	ld ix,0c410h		;5f87   ; el primer registro
	ld de,00030h		;5f8b   ; 0x30 por registro
	ld hl,05fd2h		;5f8e   ; la tabla de posiciones iniciales
	ld b,006h		;5f91   ; seis jugadores
L_5F93:
	ld a,(hl)			;5f93   ; Y de salida
	inc hl			;5f94   ; siguiente
	ld (ix+001h),a		;5f95   ; +1: Y
	ld a,(hl)			;5f98   ; X de salida (con signo desde el centro)
	inc hl			;5f99   ; siguiente
	ld (ix+003h),a		;5f9a   ; +3: X
	ld a,(hl)			;5f9d   ; banderas +0x0F
	inc hl			;5f9e   ; siguiente
	ld (ix+00fh),a		;5f9f   ; +0x0F: patrones
	ld a,(hl)			;5fa2   ; pose de salida
	inc hl			;5fa3   ; siguiente
	ld (ix+00dh),a		;5fa4   ; +0x0D: pose
	ld (ix+022h),03fh		;5fa7   ; sin formacion (+0x22)
	add ix,de		;5fab   ; siguiente registro
	djnz L_5F93		;5fad   ; los seis
	ld a,(hl)			;5faf   ; posicion del balon
	inc hl			;5fb0   ; siguiente
	ld (ix+001h),a		;5fb1   ; el balon: Y
	ld a,(hl)			;5fb4   ; X
	ld (ix+003h),a		;5fb5   ; el balon: X
	ld hl,0c410h		;5fb8   ; el primer registro
	ld de,00030h		;5fbb   ; 0x30 por registro
	ld b,006h		;5fbe   ; seis jugadores
	ld a,080h		;5fc0   ; pose cambiada de cada jugador
L_5FC2:
	ld (0ecech),hl		;5fc2   ; (0xECEC): registro en curso
	ld (0ecebh),a		;5fc5   ; (0xECEB): bit 7, pose cambiada
	push af			;5fc8   ; guarda el jugador
	call copia_pose		;5fc9   ; patrones de su pose a la VRAM
	pop af			;5fcc   ; recupera el jugador
	add hl,de			;5fcd   ; siguiente registro
	inc a			;5fce   ; siguiente jugador
	djnz L_5FC2		;5fcf   ; los seis
	ret			;5fd1   ; listo

; ----------------------------------------------------------------------
; DATOS jugadores_inicial: Seis fichas de cuatro bytes (campos +1, +3, +0F y
;   +0D de cada registro de 0xC410) y dos bytes mas (+1 y +3 del septimo
;   registro, 0xC530): 0x5F87 las reparte al arrancar
;   0x5fd2..0x5fec  (26 bytes)
DATA_jugadores_inicial:
	defb 02ah,0f0h,010h,069h	; 5fd2
	defb 03ah,0fbh,010h,069h	; 5fd6
	defb 04ah,010h,070h,079h	; 5fda
	defb 02ah,010h,060h,098h	; 5fde
	defb 03ah,005h,060h,098h	; 5fe2
	defb 04ah,0f0h,000h,088h	; 5fe6
	defb 064h,064h	; 5fea

; ======================================================================
; CODIGO 0x5fec..0x6050  (100 bytes)
; ======================================================================


velocidades:		; Velocidad con balon (+0x10) y sin balon (+0x12) a partir de la rapidez +0x1B del roster
	ld ix,0c410h		;5fec
	ld de,00030h		;5ff0
	ld b,006h		;5ff3
L_5FF5:
	exx			;5ff5
	ld de,0005ah		;5ff6   ; base 0x5A
	call suma_rapidez		;5ff9
	ld (ix+010h),l		;5ffc
	ld (ix+011h),h		;5fff
	ld de,0003fh		;6002   ; base 0x3F
	call suma_rapidez		;6005
	ld (ix+012h),l		;6008
	ld (ix+013h),h		;600b
	exx			;600e
	add ix,de		;600f
	djnz L_5FF5		;6011
	ret			;6013
suma_rapidez:		; HL = DE + (+0x1B)/2
	ld a,(ix+01bh)		;6014   ; rapidez del jugador (+0x1B)
	and a			;6017
	rra			;6018   ; la mitad
	ld l,a			;6019
	ld h,000h		;601a
	add hl,de			;601c   ; mas la base
	ret			;601d
sin_direccion:		; Direccion 0x3F, rumbo y giro 0xFF y sentido 0 en los seis
	ld ix,0c410h		;601e
	ld de,00030h		;6022
	ld b,006h		;6025
L_6027:
	ld (ix+015h),03fh		;6027   ; sin direccion
	xor a			;602b
	dec a			;602c
	ld (ix+016h),a		;602d   ; sin rumbo de giro
	ld (ix+017h),a		;6030
	xor a			;6033
	ld (ix+018h),a		;6034   ; sin sentido de giro
	add ix,de		;6037   ; siguiente registro
	djnz L_6027		;6039
	ret			;603b
empareja_jugadores:		; +0x25 de los seis: el par de cada uno, el que tiene enfrente (3 4 5 0 1 2, tabla 0x6050); la primera version los emparejaba 5 4 3 2 1 0
	ld hl,0c435h		;603c   ; +0x25 del primer registro
	ld de,06050h		;603f   ; tabla de pares
	ld b,006h		;6042   ; seis jugadores
L_6044:
	ld a,(de)			;6044   ; su par
	inc de			;6045
	ld (hl),a			;6046   ; al campo +0x25
	push de			;6047   ; guarda el puntero de la tabla
	ld de,00030h		;6048   ; siguiente registro
	add hl,de			;604b
	pop de			;604c
	djnz L_6044		;604d
	ret			;604f

; ----------------------------------------------------------------------
; DATOS pares_jugadores: Seis numeros (3 4 5 0 1 2): el par de cada jugador,
;   el que tiene enfrente (el 0 con el 3, el 1 con el 4, el 2 con el 5);
;   0x603C los copia al campo +0x25 de los seis registros
;   0x6050..0x6056  (6 bytes)
DATA_pares_jugadores:
	defb 003h,004h,005h,000h,001h,002h	; 6050

; ======================================================================
; CODIGO 0x6056..0x681d  (1991 bytes)
; ======================================================================


descomprime:		; Descompresor general: cabecera mascara/valor, repeticiones y referencias de 8 bytes (directas o con los bits al reves) a lo ya escrito
	push de			;6056   ; guarda el destino
	exx			;6057   ; en DE': la base del diccionario (lo ya escrito)
	pop de			;6058   ; DE' = destino inicial
	exx			;6059   ; registros normales
	ld c,(hl)			;605a   ; C = mascara del byte de control
	inc hl			;605b   ; C = mascara
	ld b,(hl)			;605c   ; B = valor que lo identifica
	inc hl			;605d   ; B = valor de control; HL = primera ficha
L_605E:
	push bc			;605e   ; guarda mascara y valor
	ld a,(hl)			;605f   ; la ficha
	and c			;6060   ; solo los bits de la mascara
	cp b			;6061   ; es de control?
	jr nz,L_607C		;6062   ; byte normal: literal
	ld a,c			;6064   ; contador de repeticion
	cpl			;6065   ; A = ~mascara
	and (hl)			;6066   ; A = la ficha sin los bits de control
	inc hl			;6067   ; siguiente byte
	bit 0,c		;6068   ; mascara impar: contador en los bits altos
	jr z,L_606D		;606a   ; mascara par: tal cual
	rra			;606c   ; mascara impar: el bit 0 era de control, fuera
L_606D:
	cp 002h		;606d   ; 0 o 1: referencia al diccionario
	jr c,L_6080		;606f   ; 0 o 1: diccionario (0x6080)
	inc a			;6071   ; 2 o mas: A + 1 repeticiones
	ld b,a			;6072   ; repeticiones
L_6073:
	ld a,(hl)			;6073   ; el byte a repetir
L_6074:
	ld (de),a			;6074   ; al destino
	inc de			;6075   ; siguiente
	djnz L_6074		;6076   ; B veces
L_6078:
	inc hl			;6078   ; ficha siguiente
	pop bc			;6079   ; recupera mascara y valor
	jr L_605E		;607a   ; otra ficha
L_607C:
	ld b,001h		;607c   ; literal suelto
	jr L_6073		;607e   ; un literal: B = 1 y a copiarlo
L_6080:
	and a			;6080   ; 0 o 1?
	jr nz,L_6089		;6081   ; 1: con los bits al reves (0x6089 con B = 1)
	ld b,(hl)			;6083   ; 0xFF tras el 0: fin
	inc b			;6084   ; indice 0xFF: fin
	jr nz,L_6089		;6085   ; otro indice: diccionario
	pop bc			;6087   ; recupera mascara y valor
	ret			;6088   ; HL = primera direccion despues del bloque
L_6089:
	push hl			;6089   ; guarda la ficha
	ld b,a			;608a   ; B = 0 (copia) o 1 (bits al reves)
	ld a,(hl)			;608b   ; A = indice del diccionario
	exx			;608c   ; registros alternativos
	ld l,a			;608d   ; numero de bloque de 8 bytes ya escrito
	ld h,000h		;608e   ; HL' = indice
	add hl,hl			;6090   ; por dos
	add hl,hl			;6091   ; por cuatro
	add hl,hl			;6092   ; por ocho
	add hl,de			;6093   ; mas la base: la entrada de ocho bytes ya escrita
	push hl			;6094   ; guardada
	exx			;6095   ; registros normales
	pop hl			;6096   ; HL = la entrada
	ld a,b			;6097   ; copia o al reves?
	and a			;6098   ; cero: copia
	jr nz,L_60A3		;6099   ; uno: al reves
	ld bc,00008h		;609b   ; copia directa
	ldir		;609e   ; ocho bytes tal cual
L_60A0:
	pop hl			;60a0   ; recupera el puntero de fichas
	jr L_6078		;60a1   ; ficha siguiente
L_60A3:
	ld c,008h		;60a3   ; copia en espejo
L_60A5:
	push de			;60a5   ; guarda el destino
	ld a,(hl)			;60a6   ; un byte de la entrada
	ld b,008h		;60a7   ; bits del byte al reves
L_60A9:
	rra			;60a9   ; un bit por la derecha
	rl d		;60aa   ; entra por la izquierda de D
	djnz L_60A9		;60ac   ; los ocho bits
	ld a,d			;60ae   ; A = el byte dado la vuelta
	pop de			;60af   ; recupera el destino
	ld (de),a			;60b0   ; al destino
	inc de			;60b1   ; siguiente
	inc hl			;60b2   ; siguiente byte de la entrada
	dec c			;60b3   ; los ocho
	jr nz,L_60A5		;60b4   ; otro byte
	jr L_60A0		;60b6   ; ficha siguiente
descomprime_rep:		; Descompresor de solo repeticiones; fin cuando el control va seguido de si mismo
	ld c,(hl)			;60b8   ; C = mascara
	inc hl			;60b9   ; siguiente
	ld b,(hl)			;60ba   ; B = valor de control
	inc hl			;60bb   ; HL = primera ficha
L_60BC:
	push bc			;60bc   ; guarda mascara y valor
	ld a,(hl)			;60bd   ; la ficha
	and c			;60be   ; solo los bits de la mascara
	cp b			;60bf   ; es de control?
	jr nz,L_60DE		;60c0   ; no: literal
	inc hl			;60c2   ; el byte siguiente
	cp (hl)			;60c3   ; control repetido: fin
	jr nz,L_60C8		;60c4   ; distinto de la ficha: repeticion
	pop bc			;60c6   ; igual: recupera y acaba
	ret			;60c7   ; HL = primera direccion despues del bloque
L_60C8:
	ld a,c			;60c8   ; A = ~mascara
	cpl			;60c9   ; complemento
	dec hl			;60ca   ; de vuelta a la ficha
	and (hl)			;60cb   ; la ficha sin los bits de control
	inc hl			;60cc   ; al byte siguiente
	bit 0,c		;60cd   ; mascara impar?
	jr z,L_60D2		;60cf   ; par: tal cual
	rra			;60d1   ; impar: el bit 0 fuera
L_60D2:
	add a,003h		;60d2   ; minimo 3 repeticiones
	ld b,a			;60d4   ; B = A + 3 repeticiones
L_60D5:
	ld a,(hl)			;60d5   ; el byte a repetir
L_60D6:
	ld (de),a			;60d6   ; al destino
	inc de			;60d7   ; siguiente
	djnz L_60D6		;60d8   ; B veces
	inc hl			;60da   ; ficha siguiente
	pop bc			;60db   ; recupera mascara y valor
	jr L_60BC		;60dc   ; otra ficha
L_60DE:
	ld b,001h		;60de   ; un literal
	jr L_60D5		;60e0   ; a copiarlo
descomprime_marca:		; Formato c v n: con la marca c, n copias de v; fin con la marca repetida
	inc hl			;60e2   ; se salta el primer byte
	ld c,(hl)			;60e3   ; C = la marca
	inc hl			;60e4   ; primera ficha
L_60E5:
	ld a,(hl)			;60e5   ; la ficha
	cp c			;60e6   ; es la marca?
	jr nz,L_60F6		;60e7   ; no: literal
	inc hl			;60e9   ; el byte siguiente
	cp (hl)			;60ea   ; la marca otra vez: fin
	ret z			;60eb   ; HL = la segunda marca
	ld a,(hl)			;60ec   ; A = el byte a repetir
	inc hl			;60ed   ; siguiente
	ld b,(hl)			;60ee   ; B = cuantas veces (0 = 256)
L_60EF:
	ld (de),a			;60ef   ; al destino
	inc de			;60f0   ; siguiente
	djnz L_60EF		;60f1   ; B veces
	inc hl			;60f3   ; ficha siguiente
	jr L_60E5		;60f4   ; otra ficha
L_60F6:
	ld b,001h		;60f6   ; un literal
	jr L_60EF		;60f8   ; a copiarlo
descomprime_parejas:		; Parejas de bytes repetidas: cuenta de 12 bits y la pareja; menos de 0x10 en el primero = cuenta
	ld a,(hl)			;60fa   ; el primer byte de la ficha
	cp 010h		;60fb   ; 0x10 o mas: una sola pareja
	jr nc,L_611D		;60fd   ; a copiarla
	ld b,a			;60ff   ; cuenta alta
	inc hl			;6100   ; B = alto de la cuenta
	ld c,(hl)			;6101   ; C = bajo
	inc hl			;6102   ; HL = la pareja
	and a			;6103   ; alto a cero?
	jr nz,L_6108		;6104   ; no: cuenta de verdad
	or c			;6106   ; cuenta 0: fin
	ret z			;6107   ; cuenta cero: fin
L_6108:
	inc bc			;6108   ; cuenta + 1
	ld a,(hl)			;6109   ; A = primer byte de la pareja
L_610A:
	inc hl			;610a   ; siguiente
	push hl			;610b   ; guarda el puntero
	ld l,(hl)			;610c   ; L = segundo byte
	ld h,a			;610d   ; H = primero
L_610E:
	ld a,h			;610e   ; el primero
	ld (de),a			;610f   ; al destino
	inc de			;6110   ; siguiente
	ld a,l			;6111   ; el segundo
	ld (de),a			;6112   ; al destino
	inc de			;6113   ; siguiente
	dec bc			;6114   ; una pareja menos
	ld a,b			;6115   ; quedan?
	or c			;6116
	jr nz,L_610E		;6117   ; otra
	pop hl			;6119   ; recupera el puntero
	inc hl			;611a   ; ficha siguiente
	jr descomprime_parejas		;611b   ; otra ficha
L_611D:
	ld bc,00001h		;611d   ; pareja suelta
	jr L_610A		;6120   ; una pareja: a copiarla
escribe_vram:		; Escribe A en la VRAM HL y apunta (0xEBCD)
	ld (0ebcdh),hl		;6122   ; puntero de VRAM para la interrupcion
	jp 0004dh		;6125   ; BIOS WRTVRM - Writes data in VRAM
lee_vram_huerfano:		; Huerfano: leeria el byte de VRAM HL dejando (0xEBCD) en modo lectura
	set 7,h		;6128   ; bit 7 = puntero de lectura
	ld (0ebcdh),hl		;612a   ; (0xEBCD): puntero de VRAM en curso
	res 7,h		;612d   ; direccion de lectura
	jp 0004ah		;612f   ; BIOS RDVRM - Reads the content of VRAM
copia_a_vram:		; Copia BC bytes de HL a la VRAM DE con outi, guardando el puntero en (0xEBCD) por si la interrupcion lo pisa
	ex de,hl			;6132   ; HL = destino, DE = origen
	ld (0ebcdh),hl		;6133   ; (0xEBCD): destino en curso
	call 00053h		;6136   ; BIOS SETWRT - Enables VDP to write
	ex de,hl			;6139   ; HL = origen
	ld a,b			;613a   ; B = resto, C = bloques de 256
	ld b,c			;613b   ; B = bajo de la cuenta
	ld c,a			;613c   ; C = alto
	inc c			;613d   ; mas uno para el djnz implicito
L_613E:
	push bc			;613e   ; guarda la cuenta
	ld a,(00007h)		;613f   ; puerto de datos del VDP segun la BIOS
	ld c,a			;6142   ; C = puerto de datos del VDP (0x0007 de la BIOS)
	di			;6143   ; cada byte sin interrupciones
L_6144:
	outi		;6144   ; un byte a la VRAM, HL++, B--
	inc de			;6146   ; DE lleva la cuenta del destino
	jr nz,L_6144		;6147   ; los B bytes
	ld (0ebcdh),de		;6149   ; puerto VRAM al dia para la interrupcion
	ei			;614d   ; interrupciones otra vez
	pop bc			;614e   ; recupera la cuenta
	ld b,000h		;614f   ; 256 mas
	dec c			;6151   ; un bloque de 256 menos
	jr nz,L_613E		;6152   ; los que queden
	ret			;6154
lee_de_vram:		; Lee BC bytes de la VRAM HL en la RAM DE
	set 7,h		;6155   ; bit 7 = lectura
	ld (0ebcdh),hl		;6157   ; (0xEBCD): el origen
	res 7,h		;615a   ; direccion de lectura
	call 00050h		;615c   ; BIOS SETRD - Enables VDP to read
	ex de,hl			;615f   ; HL = destino en RAM
	ld a,b			;6160   ; A = bajo de la cuenta
	ld b,c			;6161   ; B = bajo
	ld c,a			;6162   ; C = alto
	inc c			;6163   ; mas uno
L_6164:
	push bc			;6164   ; guarda la cuenta
	ld a,(00006h)		;6165   ; puerto de lectura del VDP
	ld c,a			;6168   ; C = puerto de datos
	di			;6169   ; sin interrupciones
L_616A:
	ini		;616a   ; un byte de la VRAM a (HL), HL++, B--
	inc de			;616c   ; DE lleva la cuenta
	jr nz,L_616A		;616d   ; los B bytes
	ld (0ebcdh),de		;616f   ; (0xEBCD) = siguiente direccion
	ei			;6173   ; interrupciones otra vez
	pop bc			;6174   ; recupera la cuenta
	ld b,000h		;6175   ; 256 mas
	dec c			;6177   ; un bloque menos
	jr nz,L_6164		;6178   ; los que queden
	ret			;617a
rellena_vram:		; Rellena BC bytes de la VRAM HL con A
	push hl			;617b   ; guarda HL
	push de			;617c   ; DE
	push af			;617d   ; y el valor
	ld (0ebcdh),hl		;617e   ; (0xEBCD): destino
	ld e,c			;6181   ; DE = cuenta
	ld d,b			;6182
	call 00053h		;6183   ; BIOS SETWRT - Enables VDP to write
	ld a,(00007h)		;6186   ; puerto de datos del VDP
	ld c,a			;6189   ; en C
L_618A:
	pop af			;618a   ; el valor
	di			;618b   ; sin interrupciones mientras se escribe
	out (c),a		;618c   ; a la VRAM
	inc hl			;618e   ; siguiente
	ld (0ebcdh),hl		;618f   ; (0xEBCD) al dia
	ei			;6192   ; interrupciones
	push af			;6193   ; guarda el valor
	dec de			;6194   ; uno menos
	ld a,d			;6195
	or e			;6196   ; quedan?
	jr nz,L_618A		;6197   ; otro
	pop af			;6199   ; recupera el valor
	pop de			;619a   ; DE
	pop hl			;619b   ; y HL
	ret			;619c
alterna_sprites:		; Interrupcion: cambia la tabla de atributos visible entre 0x1B00 y 0x1F00 salvo si esta congelada
	ld a,(0ece8h)		;619d   ; 0xECE8 distinto de 0: alternancia congelada
	and a			;61a0   ; pantalla apagada?
	ret nz			;61a1   ; si: nada
alterna_tabla_atributos:		; Cambia el bit 2 del registro 5 (RG5SAV, 0xF929): la tabla de atributos pasa de 0x1B00 a 0x1F00 o al reves, y deja el puntero de VRAM (0xEBCD) preparado para lo que venga
	ld hl,0f929h		;61a2   ; ATRBAS alto: 0x1B o 0x1F
	ld a,(hl)			;61a5   ; A = registro 5 guardado (RG5SAV)
	xor 004h		;61a6   ; cambia el bit 2: 0x1B00 <-> 0x1F00
	ld (hl),a			;61a8   ; guardado
	rla			;61a9   ; registro 5 del VDP (0x36 o 0x3E)
	ld b,a			;61aa   ; B = valor
	ld c,005h		;61ab   ; registro 5
	call 00047h		;61ad   ; BIOS WRTVDP - Writes data in the VDP-register
	ld hl,(0ebcdh)		;61b0   ; restaura el puntero de VRAM del programa
	call 00053h		;61b3   ; BIOS SETWRT - Enables VDP to write
	ld a,h			;61b6   ; A = alto del puntero
	res 7,h		;61b7   ; sin el bit de escritura
	and a			;61b9   ; era de lectura?
	call m,00050h		;61ba   ; BIOS SETRD - Enables VDP to read | bit 7: estaba leyendo
	ret			;61bd
congela_sprites:		; Para la alternancia y deja visible la tabla 0x1B00
	ld a,0ffh		;61be   ; (0xECE8) = 0xFF: pantalla parada
	ld (0ece8h),a		;61c0
	ld a,(0f929h)		;61c3   ; registro 5 guardado
	cp 01bh		;61c6   ; ya esta en 0x1B00
	ret z			;61c8   ; 0x1B: la de la BIOS, sin alternar
	push bc			;61c9   ; guarda BC
	push hl			;61ca   ; y HL
	call alterna_tabla_atributos		;61cb   ; alterna la tabla de atributos
	pop hl			;61ce   ; recupera HL
	pop bc			;61cf   ; y BC
	ret			;61d0
suelta_sprites:		; Reanuda la alternancia de tablas de atributos
	xor a			;61d1   ; (0xECE8) = 0: pantalla en marcha
	ld (0ece8h),a		;61d2
	ret			;61d5
vuelca_sprites:		; Monta la lista de atributos de los siete grupos rotando su orden y la copia a 0x1B00 y 0x1F00
	call monta_atributos		;61d6   ; monta en 0xEC65 los siete grupos de atributos en el orden de este cuadro (grupo_en_orden) y deja en HL el final
	ld b,007h		;61d9   ; siete grupos: seis jugadores y el balon
	ld de,0ebe4h		;61db   ; DE = ultimo tamano de la lista de grupos (0xEBDE-0xEBE4)
	exx			;61de   ; DE' = destino en 0xEBE5
	ld de,0ebe5h		;61df
	exx			;61e2
	ld a,(de)			;61e3   ; A = tamano del grupo
	dec de			;61e4   ; tamano anterior
	push de			;61e5   ; guarda la lista
	ld e,a			;61e6   ; DE = tamano
	ld d,000h		;61e7
	and a			;61e9   ; HL -= tamano: principio del grupo
	sbc hl,de		;61ea
	pop de			;61ec   ; recupera la lista
L_61ED:
	push af			;61ed   ; guarda el tamano
	push hl			;61ee   ; y el origen
	exx			;61ef
	ld c,a			;61f0   ; BC' = tamano
	ld b,000h		;61f1
	pop hl			;61f3   ; HL' = origen
	push bc			;61f4   ; guarda el tamano
	push de			;61f5   ; y el destino
	ldir		;61f6   ; copia el grupo
	pop de			;61f8   ; recupera el destino
	pop bc			;61f9   ; y el tamano
	ex de,hl			;61fa   ; HL' = destino
	add hl,bc			;61fb   ; mas el tamano
	ex de,hl			;61fc   ; DE' = destino siguiente
	exx			;61fd
	pop af			;61fe   ; recupera el tamano
	push de			;61ff   ; guarda la lista
	ld e,a			;6200   ; DE = tamano
	ld d,000h		;6201
	and a			;6203
	sbc hl,de		;6204   ; HL -= tamano: el principio del grupo anterior (0xEC65 se recorre de atras adelante: 0xEBE5 queda con los grupos al reves)
	pop de			;6206   ; recupera la lista
	ld a,(de)			;6207   ; A = tamano del grupo anterior
	dec de			;6208   ; lista hacia atras
	djnz L_61ED		;6209   ; los siete grupos
	call espera_interrupcion		;620b   ; espera la interrupcion
	ld bc,00080h		;620e   ; lista rotada en 0xEC65 a 0x1B00
	ld de,01b00h		;6211   ; la tabla de atributos de 0x1B00: los grupos en el orden del cuadro
	ld hl,0ec65h		;6214   ; desde 0xEC65
	call copia_a_vram		;6217   ; 0x80 bytes: los 32 sprites
	ld bc,00080h		;621a   ; lista en 0xEBE5 a 0x1F00
	ld de,01f00h		;621d   ; la de 0x1F00: los mismos al reves; el registro 5 (0x61A2) dice cual se ve
	ld hl,0ebe5h		;6220   ; desde 0xEBE5
	jp copia_a_vram		;6223   ; 0x80 bytes, y vuelve
oculta_sprites:		; Y = 0xD0 en el primer sprite de las dos tablas: no se pinta ninguno
	ld hl,01b00h		;6226   ; primera tabla de atributos
	ld a,0d0h		;6229   ; Y 0xD0: fin de la lista
	call escribe_vram		;622b
	ld hl,01f00h		;622e   ; segunda tabla
	ld a,0d0h		;6231
	jp escribe_vram		;6233
monta_atributos:		; Calcula los atributos de los siete grupos en la lista 0xEC65 y el numero de sprites de cada uno en 0xEBDE
	ld a,(0ed80h)		;6236   ; SUPOSICION: parpadeo del marcador de jugador activo
	and a			;6239
	jr nz,L_624B		;623a
	ld hl,(0ebd4h)		;623c
	ld a,h			;623f
	or l			;6240
	jr z,L_624B		;6241
	res 7,(hl)		;6243
	ld hl,00000h		;6245   ; quita la marca
	ld (0ebd4h),hl		;6248
L_624B:
	ld b,007h		;624b
	ld c,000h		;624d
	exx			;624f
	ld hl,0ec65h		;6250   ; lista de atributos en construccion
	exx			;6253
	ld hl,0ebdeh		;6254   ; cuenta de sprites por grupo
L_6257:
	push hl			;6257
	ld a,c			;6258   ; puesto de pintado C
	call grupo_en_orden		;6259   ; registro de ese puesto
	call atributos_grupo		;625c   ; sus sprites a la lista
	pop hl			;625f
	ld (hl),a			;6260   ; numero de sprites del grupo
	inc hl			;6261
	inc c			;6262   ; siguiente puesto
	djnz L_6257		;6263
	exx			;6265
	push hl			;6266
	exx			;6267
	pop hl			;6268   ; HL = fin de la lista
	ret			;6269
atributos_grupo:		; Atributos de los cuatro sprites del grupo C a partir de la posicion en pantalla (perspectiva) y la colocacion de la pose
	push bc			;626a
	ld c,a			;626b
	push bc			;626c
	call y_pantalla		;626d   ; Y de pantalla
	ld d,a			;6270
	call x_pantalla		;6271   ; X de pantalla
	ld e,a			;6274
	pop bc			;6275
	ld a,006h		;6276   ; el grupo 6 es el balon
	cp c			;6278
	jp z,atributos_balon		;6279
	push de			;627c
	ld de,00009h		;627d   ; +9 del registro: SUPOSICION altura de cada sprite
	add hl,de			;6280
	push hl			;6281
	exx			;6282
	pop de			;6283
	exx			;6284
	call sombra_grupo		;6285   ; sombra de atributos del jugador
	pop de			;6288
	xor a			;6289
	ld b,004h		;628a
L_628C:
	push af			;628c
	push de			;628d
	ld a,d			;628e
	cp 0d0h		;628f   ; Y 0xD0 o mas: fuera de pantalla
	jr nc,L_6298		;6291
	exx			;6293
	ld a,(de)			;6294
	exx			;6295
	add a,d			;6296
	ld d,a			;6297
L_6298:
	xor a			;6298
	ld (0ece9h),a		;6299   ; bit early clock apagado
	ld a,(hl)			;629c
	inc hl			;629d
	neg		;629e   ; resta dy de la colocacion
	add a,d			;62a0
	exx			;62a1
	ld (hl),a			;62a2
	inc hl			;62a3
	exx			;62a4
	ld a,(hl)			;62a5
	inc hl			;62a6
	neg		;62a7   ; resta dx de la colocacion
	jp p,L_62BC		;62a9
	push af			;62ac
	ld a,e			;62ad
	cp 020h		;62ae   ; X cerca del borde izquierdo
	jr nc,L_62BB		;62b0
	ld a,080h		;62b2   ; early clock: corre el sprite 32 pixeles
	ld (0ece9h),a		;62b4
	ld a,e			;62b7
	add a,020h		;62b8
	ld e,a			;62ba
L_62BB:
	pop af			;62bb
L_62BC:
	add a,e			;62bc   ; X de pantalla mas dx
	exx			;62bd
	ld (hl),a			;62be   ; X del sprite
	inc hl			;62bf
	exx			;62c0
	ld a,(hl)			;62c1   ; numero de patron
	inc hl			;62c2
	exx			;62c3
	ld (hl),a			;62c4   ; patron del sprite
	inc hl			;62c5
	exx			;62c6
	call color_sprite		;62c7   ; color
	pop de			;62ca
	pop af			;62cb
	add a,004h		;62cc   ; siguiente sprite: 4 bytes
	djnz L_628C		;62ce
	pop bc			;62d0
	ret			;62d1
color_sprite:		; Color del sprite con el bit early clock; el bit 7 en el cuarto sprite (camiseta) hace parpadear la marca en blanco
	ld a,b			;62d2   ; cuarto sprite del grupo (camiseta)?
	cp 001h		;62d3
	jr nz,L_62DC		;62d5
	ld a,(hl)			;62d7   ; color con la marca?
	bit 7,a		;62d8
	jr nz,L_62E9		;62da   ; parpadea
L_62DC:
	ld a,(hl)			;62dc
L_62DD:
	inc hl			;62dd
	push hl			;62de
	ld hl,0ece9h		;62df   ; bit early clock
	or (hl)			;62e2   ; en el color
	pop hl			;62e3
	exx			;62e4
	ld (hl),a			;62e5   ; color del sprite
	inc hl			;62e6
	exx			;62e7
	ret			;62e8
L_62E9:
	res 7,a		;62e9
	ld c,a			;62eb
	ld a,(0ebcfh)		;62ec   ; cuenta de cuadros: parpadeo cada 4
	bit 2,a		;62ef
	ld a,c			;62f1
	jr nz,L_62DD		;62f2
	ld a,00fh		;62f4   ; blanco
	jr L_62DD		;62f6
marca_jugador:		; Pone el bit 7 (marca) en el color del grupo A y lo recuerda en (0xEBD2)
	push hl			;62f8
	push de			;62f9
	call color_grupo		;62fa   ; color del cuarto sprite del grupo
	set 7,(hl)		;62fd   ; marca
	ld (0ebd2h),hl		;62ff   ; recuerda donde
	pop de			;6302
	pop hl			;6303
	ret			;6304
quita_marca:		; Quita la marca puesta por 0x62F8
	push hl			;6305
	ld hl,(0ebd2h)		;6306   ; marca puesta
	ld a,h			;6309
	or l			;630a
	jr z,L_630F		;630b   ; ninguna
	res 7,(hl)		;630d   ; la quita
L_630F:
	pop hl			;630f
	ret			;6310
color_grupo:		; HL = color del cuarto sprite (camiseta) del grupo A en la sombra 0xC560
	ld l,a			;6311
	ld h,000h		;6312
	add hl,hl			;6314   ; 16 bytes por grupo
	add hl,hl			;6315
	add hl,hl			;6316
	add hl,hl			;6317
	ld de,0c560h		;6318   ; sombra de atributos
	add hl,de			;631b
	ld de,0000fh		;631c   ; color del cuarto sprite (+0x0F)
	add hl,de			;631f
	ret			;6320
marca_controlado:		; Marca al jugador controlado del bando de (0xECF1) durante 180 cuadros
	push de			;6321
	ld hl,(0ebd4h)		;6322   ; marca anterior
	ld a,l			;6325
	or h			;6326
	jr z,L_632B		;6327
	res 7,(hl)		;6329   ; la quita
L_632B:
	ld a,(0ecf1h)		;632b
	and a			;632e
	ld a,(0c5e8h)		;632f   ; controlado del equipo izquierdo
	jr nz,L_6337		;6332
	ld a,(0c5ebh)		;6334   ; controlado del equipo derecho
L_6337:
	call color_grupo		;6337
	set 7,(hl)		;633a
	ld (0ebd4h),hl		;633c
	ld a,0b4h		;633f   ; 180 cuadros de marca
	ld (0ed80h),a		;6341
	pop de			;6344
	ret			;6345
muestra_balon:		; (0xECE7) = 0: balon y sombra visibles
	xor a			;6346
	ld (0ece7h),a		;6347
	ret			;634a
oculta_balon:		; (0xECE7) = 0x80: balon y sombra fuera de la pantalla
	ld a,080h		;634b
	ld (0ece7h),a		;634d
	ret			;6350
atributos_balon:		; Grupo 6: aro, balon, sombra y cuarto sprite; devuelve 16 bytes
	push de			;6351
	push de			;6352
	call sprite_red		;6353   ; sprite del aro y la red
	pop de			;6356
	call sprite_balon		;6357   ; sprite del balon
	pop de			;635a
	call sprite_sombra		;635b   ; sombra del balon
	call sprite_fijo		;635e   ; cuarto sprite fijo
	ld a,010h		;6361
	pop bc			;6363
	ret			;6364
sprite_red:		; Red en la posicion de pantalla (0xC5DB) mas su colocacion de 0xC5C0
	ld hl,0c5dbh		;6365   ; posicion de la red en pantalla
	ld d,(hl)			;6368
	inc hl			;6369
	ld e,(hl)			;636a
	ld hl,0c5c0h		;636b   ; colocacion de la red
	ld a,d			;636e
	add a,(hl)			;636f   ; Y mas dy
	ld d,a			;6370
	inc hl			;6371
	ld a,e			;6372
	add a,(hl)			;6373   ; X mas dx
	ld e,a			;6374
	inc hl			;6375
	ld b,(hl)			;6376   ; patron
	inc hl			;6377
	ld c,(hl)			;6378   ; color
	jp guarda_atributos		;6379
sprite_balon:		; Balon en Y de pantalla mas altura de la mano, la Z y la colocacion; oculto si (0xECE7)
	ld a,(0ece7h)		;637c   ; balon oculto
	and a			;637f
	jr z,L_6386		;6380
	ld a,0d1h		;6382   ; Y 0xD1: fuera de la pantalla
	jr L_6397		;6384
L_6386:
	ld hl,0c540h		;6386   ; altura de la mano en vuelo
	ld a,d			;6389
	add a,(hl)			;638a
	ld hl,0c53dh		;638b   ; altura en la mano
	add a,(hl)			;638e
	ld hl,0c539h		;638f   ; Z del balon
	add a,(hl)			;6392
	ld hl,0c5c4h		;6393
	add a,(hl)			;6396
L_6397:
	ld d,a			;6397   ; Y del balon
	inc hl			;6398
	ld a,(hl)			;6399   ; X de colocacion
	add a,e			;639a
	ld e,a			;639b
	inc hl			;639c
	ld b,(hl)			;639d   ; patron
	inc hl			;639e
	ld c,(hl)			;639f   ; color
	jp guarda_atributos		;63a0
sprite_sombra:		; Sombra del balon en el suelo; oculta si (0xECE7)
	ld a,(0ece7h)		;63a3
	and a			;63a6
	jr z,L_63AD		;63a7
	ld a,0d1h		;63a9
	jr L_63B2		;63ab
L_63AD:
	ld hl,0c5c8h		;63ad
	ld a,d			;63b0
	add a,(hl)			;63b1
L_63B2:
	ld d,a			;63b2   ; Y de la sombra
	inc hl			;63b3
	ld a,e			;63b4
	add a,(hl)			;63b5   ; X de colocacion
	ld e,a			;63b6
	inc hl			;63b7
	ld b,(hl)			;63b8   ; patron
	inc hl			;63b9
	ld c,(hl)			;63ba   ; color
	jp guarda_atributos		;63bb
sprite_fijo:		; Cuarto sprite del grupo con la colocacion fija de 0xC5CC
	ld hl,0c5cch		;63be   ; cuarto sprite: posicion fija
	ld d,(hl)			;63c1
	inc hl			;63c2
	ld e,(hl)			;63c3
	inc hl			;63c4
	ld b,(hl)			;63c5   ; patron
	inc hl			;63c6
	ld c,(hl)			;63c7   ; color
	jp guarda_atributos		;63c8
guarda_atributos:		; Escribe Y, X, patron y color en la lista HL'
	push bc			;63cb
	push de			;63cc
	exx			;63cd   ; a la lista de HL'
	pop de			;63ce
	pop bc			;63cf
	ld (hl),d			;63d0   ; Y
	inc hl			;63d1
	ld (hl),e			;63d2   ; X
	inc hl			;63d3
	ld (hl),b			;63d4   ; patron
	inc hl			;63d5
	ld (hl),c			;63d6   ; color
	inc hl			;63d7
	exx			;63d8
	ret			;63d9
x_pantalla:		; X de pantalla: (0xECE6) mas la X (+3) escalada por la curva 0xBCB4 segun la Y (+1); 0xE1 si se sale
	push hl			;63da
	inc hl			;63db
	ld a,(hl)			;63dc   ; Y (+1)
	inc hl			;63dd
	inc hl			;63de
	ld c,(hl)			;63df   ; X (+3)
	push de			;63e0
	ld e,a			;63e1
	ld d,000h		;63e2
	ld hl,0bcb4h		;63e4   ; escala segun la profundidad
	add hl,de			;63e7
	ld e,(hl)			;63e8   ; factor de escala
	ld a,c			;63e9   ; X con signo
	bit 7,a		;63ea
	jr z,L_63F0		;63ec
	neg		;63ee   ; valor absoluto
L_63F0:
	call multiplica		;63f0
	add hl,hl			;63f3
	ld a,h			;63f4
	ld hl,0ece6h		;63f5   ; X fina de la ventana
	bit 7,c		;63f8
	jr z,L_6403		;63fa
	neg		;63fc
	add a,(hl)			;63fe
	jr nc,L_6409		;63ff
	jr L_6406		;6401
L_6403:
	add a,(hl)			;6403
	jr c,L_6409		;6404
L_6406:
	pop de			;6406
L_6407:
	pop hl			;6407
	ret			;6408
L_6409:
	pop de			;6409
	ld d,0e1h		;640a   ; fuera: oculto
	ld e,a			;640c
	jr L_6407		;640d
y_pantalla:		; Y de pantalla: curva 0xBC34 segun la Y (+1), mas 0x40; 0xE1 si pasa de 0xC0
	push hl			;640f
	inc hl			;6410
	ld a,(hl)			;6411   ; Y (+1)
	push de			;6412
	ld e,a			;6413
	ld d,000h		;6414
	ld hl,0bc34h		;6416   ; curva de la Y de pantalla
	add hl,de			;6419
	ld a,(hl)			;641a
	add a,040h		;641b   ; mas la linea del horizonte
	cp 0c0h		;641d   ; fuera por abajo?
	jr c,L_6423		;641f
	ld a,0e1h		;6421   ; oculto
L_6423:
	pop de			;6423
	pop hl			;6424
	ret			;6425
grupo_en_orden:		; HL = registro que va en el puesto A del orden de pintado (+0x0E), C su numero
	push bc			;6426
	push de			;6427
	ld hl,0c41eh		;6428   ; +0x0E del primer registro
	ld de,00030h		;642b
	ld b,007h		;642e
	ld c,000h		;6430
L_6432:
	cp (hl)			;6432   ; es este puesto?
	jr z,L_643C		;6433
	add hl,de			;6435   ; siguiente registro
	inc c			;6436
	djnz L_6432		;6437
	ld hl,0000eh		;6439   ; no encontrado
L_643C:
	and a			;643c
	ld a,c			;643d   ; A = numero de registro
	ld de,0000eh		;643e   ; HL = registro
	sbc hl,de		;6441
	pop de			;6443
	pop bc			;6444
	ret			;6445
ordena_profundidad:		; Ordena los siete registros por la profundidad +1 (mayor primero) y guarda el puesto en +0x0E
	ld hl,0c411h		;6446   ; +1 de cada registro
	ld de,0ebd6h		;6449   ; lista temporal en 0xEBD6
	ld b,007h		;644c
L_644E:
	ld a,(hl)			;644e   ; Y del registro
	push de			;644f
	ld de,00030h		;6450   ; siguiente registro
	add hl,de			;6453
	pop de			;6454
	ld (de),a			;6455   ; a la lista
	inc de			;6456
	djnz L_644E		;6457
	ld hl,0ebd6h		;6459   ; lista de siete
	ld d,h			;645c
	ld e,l			;645d
	inc hl			;645e
	ld b,006h		;645f   ; seis pasadas
L_6461:
	push bc			;6461   ; ordenacion de burbuja
	ld a,(de)			;6462
L_6463:
	cp (hl)			;6463   ; menor que el siguiente?
	call c,intercambia		;6464   ; los cambia
	inc hl			;6467
	djnz L_6463		;6468
	inc de			;646a   ; siguiente posicion
	ld h,d			;646b
	ld l,e			;646c
	inc hl			;646d
	pop bc			;646e
	djnz L_6461		;646f
	ld de,0c410h		;6471   ; puesto de cada registro
	ld hl,0ebd6h		;6474
	ld b,007h		;6477
L_6479:
	push bc			;6479
	inc de			;647a   ; +1 del registro
	ld b,007h		;647b   ; siete puestos
	ld c,000h		;647d   ; C = puesto
	ld a,(de)			;647f   ; Y del registro
	push hl			;6480
L_6481:
	cp (hl)			;6481   ; es la del puesto C?
	call z,pon_puesto		;6482   ; se lo asigna
	inc hl			;6485
	inc c			;6486   ; siguiente puesto
	djnz L_6481		;6487
	ld hl,0002fh		;6489   ; siguiente registro (+0x30)
	add hl,de			;648c
	ex de,hl			;648d
	pop hl			;648e
	pop bc			;648f
	djnz L_6479		;6490
	ret			;6492
intercambia:		; Cambia (DE) y (HL)
	ex af,af'			;6493
	ld a,(hl)			;6494
	ld (de),a			;6495   ; el de HL a DE
	ex af,af'			;6496
	ld (hl),a			;6497   ; el de DE a HL
	ld a,(de)			;6498
	ret			;6499
pon_puesto:		; Puesto C en +0x0E y marca usada
	push hl			;649a
	ld hl,0000dh		;649b   ; +0x0E del registro
	add hl,de			;649e
	ld b,001h		;649f   ; una sola vez
	ld a,c			;64a1
	ld (hl),a			;64a2   ; puesto
	pop hl			;64a3
	ld (hl),0ffh		;64a4   ; puesto usado
	ret			;64a6
centra_ventana:		; Mueve la ventana una columna hacia la central (12)
	ld de,0ece5h		;64a7
	ld hl,0c5dfh		;64aa
	ld a,(de)			;64ad
	ld c,(hl)			;64ae
	cp 00ch		;64af   ; ya centrada
	ret z			;64b1
	and a			;64b2
	jr nz,L_64BC		;64b3
	inc a			;64b5
	set 4,c		;64b6   ; bit 4: hacia la derecha
	ld b,0f8h		;64b8
	jr L_64C1		;64ba
L_64BC:
	dec a			;64bc
	set 3,c		;64bd   ; bit 3: hacia la izquierda
	ld b,008h		;64bf
L_64C1:
	ld (de),a			;64c1   ; columna nueva
	ld (hl),c			;64c2   ; bits de desplazamiento
	ld hl,0ece6h		;64c3   ; X fina
	ld a,b			;64c6
	add a,(hl)			;64c7   ; mas o menos 8
	ld (hl),a			;64c8
	call desplaza_ventana		;64c9   ; desplaza ya
desplaza_ventana:		; Si 0xC5DF pide desplazar, mueve la ventana una columna, ajusta la X fina y la canasta; si no, refresca el marcador
	ld hl,0ece6h		;64cc
	ld a,(0c5dfh)		;64cf
	ld c,a			;64d2
	bit 4,a		;64d3   ; bit 4: desplaza a la derecha
	jr z,L_64EA		;64d5
	ld a,008h		;64d7   ; X fina mas 8
	ld b,a			;64d9
	add a,(hl)			;64da
	ld (hl),a			;64db
	ld a,0ffh		;64dc   ; una columna menos
	ld hl,0c5d3h		;64de   ; canasta de la derecha
	inc hl			;64e1
	ld (hl),039h		;64e2
	inc hl			;64e4
	inc hl			;64e5
	ld (hl),09eh		;64e6
	jr L_6500		;64e8
L_64EA:
	bit 3,a		;64ea   ; bit 3: desplaza a la izquierda
	jp z,refresca_marcador		;64ec
	ld a,0f8h		;64ef   ; X fina menos 8
	ld b,a			;64f1
	add a,(hl)			;64f2
	ld (hl),a			;64f3
	ld a,001h		;64f4   ; una columna mas
	ld hl,0c5d3h		;64f6   ; canasta de la izquierda
	inc hl			;64f9
	ld (hl),039h		;64fa
	inc hl			;64fc
	inc hl			;64fd
	ld (hl),062h		;64fe
L_6500:
	push bc			;6500
	call copia_ventana		;6501   ; copia la ventana
	push af			;6504
	call nc,posicion_red		;6505   ; recalcula la posicion de la red
	pop af			;6508
	pop bc			;6509
	ret nc			;650a
	ld a,c			;650b   ; tope: deja de desplazar
	and 0e7h		;650c
	ld (0c5dfh),a		;650e
	ld a,b			;6511   ; deshace la X fina
	neg		;6512
	ld hl,0ece6h		;6514
	add a,(hl)			;6517
	ld (hl),a			;6518
	ld a,080h		;6519   ; repinta FORMATION=
	ld (0cb1fh),a		;651b
	call congela_sprites		;651e
	call monta_marcador		;6521   ; marcador entero
	jp suelta_sprites		;6524
refresca_marcador:		; Sin desplazamiento: tiempo, faltas y rotulos pendientes
	ld a,(0ed5ch)		;6527
	and a			;652a
	call nz,pinta_tiempo		;652b   ; tiempo en el marcador
	call zona_controlado		;652e
	ld hl,0ed82h		;6531
	bit 7,(hl)		;6534
	call nz,pinta_area_si_sigue		;6536   ; AREA= pendiente: por 0x6E4B, que no pinta tras el final de la mitad
	ld hl,0cb1fh		;6539
	bit 7,(hl)		;653c
	call nz,pinta_formacion		;653e   ; FORMATION= pendiente
	ret			;6541
posicion_red:		; Posicion de pantalla de la red (0xC5DB) a partir de la canasta 0xC5D3
	ld hl,0c5d3h		;6542   ; canasta
	call y_pantalla		;6545   ; Y de pantalla
	add a,0cch		;6548   ; menos 0x34: el aro
	ld d,a			;654a
	call x_pantalla		;654b   ; X de pantalla
	ld e,a			;654e
	ld a,(0c5dfh)		;654f
	bit 3,a		;6552   ; lado de la ventana
	jr nz,L_6557		;6554
	dec e			;6556   ; un pixel a la izquierda
L_6557:
	ld hl,0c5dbh		;6557
	ld (hl),d			;655a
	inc hl			;655b
	ld (hl),e			;655c
	ret			;655d
copia_ventana:		; Mueve la ventana A columnas (si cabe en 0-24) y copia sus 32 x 24 nombres de 0xCB3D a la VRAM; acarreo si no cabe
	ld c,a			;655e   ; C = cuantas columnas
	call cabe_columna		;655f   ; cabe la ventana?
	ret c			;6562   ; fuera de la pista: nada
	ld a,(0ece5h)		;6563   ; columna nueva
	add a,c			;6566   ; columna nueva
	ld (0ece5h),a		;6567   ; (0xECE5) al dia
	call limita_columna		;656a   ; entre 0 y 24
	call extiende_a		;656d   ; DE = la columna, con signo
	ld hl,0cb3dh		;6570   ; primera columna en el mapa
	add hl,de			;6573   ; HL = la columna en la fila 0 del mapa
	ld b,018h		;6574   ; 24 filas
	ld de,01800h		;6576   ; fila 0 de la tabla de nombres
L_6579:
	push bc			;6579   ; guarda la cuenta de filas
	ld bc,00020h		;657a   ; 32 columnas por fila
	push de			;657d   ; guarda el destino
	push hl			;657e   ; y el origen
	call copia_a_vram		;657f   ; 32 bytes a la VRAM
	pop hl			;6582   ; recupera el origen
	ld de,00038h		;6583   ; siguiente fila del mapa (56)
	add hl,de			;6586   ; mas 56: la fila siguiente del mapa
	pop de			;6587   ; recupera el destino
	push hl			;6588   ; guarda el origen
	ld hl,00020h		;6589   ; 32 mas
	add hl,de			;658c   ; la fila siguiente de la tabla de nombres
	ex de,hl			;658d   ; DE = destino
	pop hl			;658e   ; HL = origen
	pop bc			;658f   ; recupera la cuenta
	djnz L_6579		;6590   ; las 24 filas
	ret			;6592
limita_columna:		; A = columna de la ventana entre 0 y 0x19
	ld a,(0ece5h)		;6593   ; la columna
	and a			;6596   ; negativa?
	jp p,L_659C		;6597   ; no: mira el tope
	xor a			;659a   ; si: cero
	ret			;659b
L_659C:
	cp 019h		;659c   ; 25 o mas?
	ret c			;659e   ; no: vale
	ld a,019h		;659f   ; si: 25
	ret			;65a1
cabe_columna:		; Acarreo si la columna mas C se sale de 0-24
	ld a,(0ece5h)		;65a2   ; la columna
	add a,c			;65a5   ; mas lo que se quiere mover
	jp m,L_65AF		;65a6   ; negativa: no se puede
	cp 019h		;65a9   ; 25 o mas: no se puede
	jr nc,L_65AF		;65ab
	and a			;65ad   ; sin acarreo: se puede
	ret			;65ae
L_65AF:
	scf			;65af   ; acarreo: no
	ret			;65b0
extiende_a:		; DE = A con signo
	ld d,000h		;65b1   ; D = 0
	ld e,a			;65b3   ; E = A
	and a			;65b4   ; negativo?
	ret p			;65b5   ; no: listo
	dec d			;65b6   ; si: D = 0xFF
	ret			;65b7
descomprime_mapa:		; Mapa de la pista de 56 x 24 (0xBD34) a 0xCB3D
	ld hl,0bd34h		;65b8   ; el mapa de la pista comprimido
	ld de,0cb3dh		;65bb   ; al bufer
	jp descomprime_rep		;65be   ; descomprime y vuelve
servicio_vram:		; Si ya paso la interrupcion, hace el trabajo de VRAM pendiente: patrones de la pose cambiada y la ventana de la pista
	ld a,(0ebd0h)		;65c1   ; bandera que pone la interrupcion
	and a			;65c4   ; cero: nada que hacer
	ret z			;65c5
	xor a			;65c6   ; (0xEBD0) a cero
	ld (0ebd0h),a		;65c7
	push bc			;65ca   ; guarda todos los registros
	push de			;65cb
	push hl			;65cc
	ex af,af'			;65cd
	exx			;65ce
	push af			;65cf
	push bc			;65d0
	push de			;65d1
	push hl			;65d2
	push ix		;65d3
	push iy		;65d5
	call copia_pose		;65d7   ; patrones de la pose cambiada
	call integra_jugadores		;65da   ; el movimiento de los seis jugadores
	call mueve_balon		;65dd   ; y el del balon
	pop iy		;65e0   ; recupera todos los registros
	pop ix		;65e2
	pop hl			;65e4
	pop de			;65e5
	pop bc			;65e6
	pop af			;65e7
	ex af,af'			;65e8
	exx			;65e9
	pop hl			;65ea
	pop de			;65eb
	pop bc			;65ec
	ret			;65ed
copia_pose:		; Copia a 0x3800+n*128 los cuatro patrones de 16x16 de la pose del jugador marcado en (0xECEB) y su colocacion a la sombra 0xC560
	ld a,(0ecebh)		;65ee   ; bit 7: hay pose cambiada; bits bajos: jugador
	bit 7,a		;65f1   ; bit 7: la pose cambio
	ret z			;65f3   ; no: nada
	push af			;65f4   ; guarda A
	xor a			;65f5   ; quita la marca
	ld (0ecebh),a		;65f6
	pop af			;65f9   ; recupera A
	xor 080h		;65fa   ; A = numero de jugador
sube_patrones_pose:		; Copia a la VRAM los cuatro patrones de la pose del registro en curso (0x3800 + jugador * 128) y los cuatro (dy, dx) de su grupo a los atributos de 0xC560 + jugador * 16
	push bc			;65fc   ; guarda BC
	push de			;65fd   ; DE
	push hl			;65fe   ; y HL
	ld hl,(0ecech)		;65ff   ; registro del jugador
	ld de,0000fh		;6602   ; campo +0x0F
	add hl,de			;6605   ; HL = registro + 0x0F
	res 7,(hl)		;6606   ; pose ya atendida
	ld de,0fffeh		;6608   ; menos dos
	add hl,de			;660b   ; HL = registro + 0x0D: la pose
	ld l,(hl)			;660c   ; pose (+0x0D)
	push af			;660d   ; guarda el jugador
	push hl			;660e   ; y la pose
	call patrones_de_pose		;660f
	push hl			;6612
	call hueco_de_jugador		;6613
	pop hl			;6616   ; HL = los cuatro patrones
	ld b,004h		;6617   ; cuatro patrones de 16x16
L_6619:
	push bc			;6619   ; guarda la cuenta
	ld a,(hl)			;661a   ; A = numero de patron
	inc hl			;661b   ; siguiente
	push hl			;661c   ; guarda la pose
	call patron_en_ram		;661d
	ld bc,00020h		;6620   ; 32 bytes
	push de			;6623   ; guarda el hueco
	call copia_a_vram		;6624   ; el patron a la VRAM
	pop de			;6627   ; recupera el hueco
	ld hl,00020h		;6628   ; 32 mas
	add hl,de			;662b   ; el hueco siguiente
	ex de,hl			;662c   ; DE = hueco
	pop hl			;662d   ; recupera la pose
	pop bc			;662e   ; y la cuenta
	djnz L_6619		;662f   ; los cuatro patrones
	pop hl			;6631   ; HL = pose
	ld a,l			;6632   ; L = pose
	call colocacion_de_pose		;6633
	pop af			;6636
	push hl			;6637
	ld c,a			;6638
	call sombra_grupo		;6639
	pop de			;663c   ; DE = la colocacion
	ld b,004h		;663d   ; cuatro sprites
L_663F:
	ld a,(de)			;663f   ; dy
	inc de			;6640   ; siguiente
	ld (hl),a			;6641   ; al atributo (Y)
	inc hl			;6642   ; siguiente byte
	ld a,(de)			;6643   ; dx
	inc de			;6644   ; siguiente
	ld (hl),a			;6645   ; al atributo (X)
	inc hl			;6646   ; se salta patron y color
	inc hl			;6647
	inc hl			;6648
	djnz L_663F		;6649   ; los cuatro sprites
	pop hl			;664b   ; recupera HL
	pop de			;664c   ; DE
	pop bc			;664d   ; y BC
	ret			;664e
patrones_de_pose:		; HL = los cuatro patrones de la pose A (tabla 0xAB64, 4 por pose)
	ld h,000h		;664f   ; HL = pose
	add hl,hl			;6651   ; por dos
	add hl,hl			;6652   ; por cuatro
	ld de,0ab64h		;6653   ; tabla de poses: 4 patrones por pose
	add hl,de			;6656   ; HL = los cuatro patrones de la pose
	ret			;6657
hueco_de_jugador:		; DE = el hueco del jugador A en la tabla de patrones de sprite de la VRAM: 0x3800 + A * 128
	ld l,a			;6658   ; L = jugador
	ld h,000h		;6659   ; HL = jugador
	add hl,hl			;665b   ; por 2
	add hl,hl			;665c   ; por 4
	add hl,hl			;665d   ; por 8
	add hl,hl			;665e   ; por 16
	add hl,hl			;665f   ; por 32
	add hl,hl			;6660   ; por 64
	add hl,hl			;6661   ; por 128: cuatro patrones de 32 bytes por jugador
	ld de,03800h		;6662   ; patrones de sprite del jugador: 0x3800+n*128
	add hl,de			;6665   ; HL = su hueco en la tabla de patrones de sprite
	ex de,hl			;6666   ; DE = el hueco
	ret			;6667
patron_en_ram:		; HL = el patron A en la RAM (0xD33D + A * 32); conserva DE
	push de			;6668   ; y el hueco
	ld l,a			;6669   ; HL = patron
	ld h,000h		;666a
	add hl,hl			;666c   ; por 2
	add hl,hl			;666d   ; por 4
	add hl,hl			;666e   ; por 8
	add hl,hl			;666f   ; por 16
	add hl,hl			;6670   ; por 32 bytes
	ld de,0d33dh		;6671   ; cada patron 32 bytes en 0xD33D
	add hl,de			;6674   ; HL = el patron en RAM
	pop de			;6675   ; DE = el hueco
	ret			;6676
colocacion_de_pose:		; HL = los ocho bytes de colocacion (dy, dx) del grupo de la pose A (tabla 0xAA24, grupo = A >> 2)
	and 0fch		;6677   ; sin los dos bits bajos: el grupo por cuatro
	ld l,a			;6679   ; HL = grupo * 4
	ld h,000h		;667a
	ld de,0aa24h		;667c   ; colocacion: grupo pose>>2, 4 pares (dy, dx)
	add hl,hl			;667f   ; por dos: grupo * 8
	add hl,de			;6680   ; HL = los ocho bytes de colocacion del grupo
	ret			;6681
sombra_grupo:		; HL = 0xC560 + C*16: atributos del grupo C
	ld l,c			;6682   ; L = jugador
	ld h,000h		;6683   ; HL = jugador
	add hl,hl			;6685   ; por 2
	add hl,hl			;6686   ; por 4
	add hl,hl			;6687   ; por 8
	add hl,hl			;6688   ; por 16
	ld de,0c560h		;6689
	add hl,de			;668c   ; HL = sus atributos
	ret			;668d
espera_interrupcion:		; Espera a que la interrupcion ponga (0xEBD0)
	push af			;668e   ; guarda A
	push hl			;668f   ; y HL
	ld hl,0ebd0h		;6690
	ld (hl),000h		;6693   ; (0xEBD0) = 0: la interrupcion lo pondra a otra cosa
L_6695:
	ld a,(hl)			;6695   ; sigue a cero?
	and a			;6696   ; comprueba
	jr z,L_6695		;6697   ; si: espera
	pop hl			;6699   ; recupera HL
	pop af			;669a   ; y A
	ret			;669b
espera_cuadros_huerfano:		; Huerfano: esperaria B interrupciones
	call espera_interrupcion		;669c   ; un cuadro
	djnz espera_cuadros_huerfano		;669f   ; B cuadros
	ret			;66a1
absolutos:		; L y E en valor absoluto
	ld a,l			;66a2
	and a			;66a3
	jp p,L_66AA		;66a4
	neg		;66a7
	ld l,a			;66a9
L_66AA:
	ld a,e			;66aa   ; abs de E
	and a			;66ab
	ret p			;66ac
	neg		;66ad   ; negativo: se invierte
	ld e,a			;66af
	ret			;66b0
cuadrados:		; HL = L al cuadrado y DE = E al cuadrado (tablas 0xC000/0xC100)
	ld h,0c0h		;66b1   ; tablas de cuadrados en 0xC000/0xC100
	ld d,h			;66b3
	ld a,(hl)			;66b4   ; byte bajo de L al cuadrado
	inc h			;66b5
	ld h,(hl)			;66b6   ; byte alto
	ld l,a			;66b7
	ld a,(de)			;66b8   ; byte bajo de E al cuadrado
	ld c,a			;66b9
	inc d			;66ba
	ld a,(de)			;66bb   ; byte alto
	ld d,a			;66bc
	ld e,c			;66bd
	ret			;66be
raiz:		; Raiz cuadrada de HL por busqueda binaria en la tabla de cuadrados
	xor a			;66bf
	ld b,080h		;66c0
	ex de,hl			;66c2
L_66C3:
	sub b			;66c3   ; prueba bajando el paso B
	cp 080h		;66c4
	ld l,a			;66c6
	ld h,0c0h		;66c7   ; cuadrado del candidato
	ld a,e			;66c9
	sub (hl)			;66ca   ; DE menos el cuadrado
	ld c,a			;66cb
	inc h			;66cc
	ld a,d			;66cd
	sbc a,(hl)			;66ce
	jr nc,L_66DA		;66cf   ; cabe: sube
	or c			;66d1   ; exacto: es la raiz
	ld a,l			;66d2
	ret z			;66d3
	srl b		;66d4   ; paso a la mitad
	jr nz,L_66C3		;66d6
	dec a			;66d8   ; se pasa: uno menos
	ret			;66d9
L_66DA:
	or c			;66da   ; exacto?
	ld a,l			;66db
	ret z			;66dc
	srl b		;66dd   ; paso a la mitad
	jr nz,$-26		;66df
	ret			;66e1
angulo:		; Angulo de 0 a 255 del vector (L, E) con la tabla de arcotangentes 0xC300
	ld a,e			;66e2   ; signos de E y L
	rla			;66e3
	ld a,l			;66e4
	rla			;66e5
	rla			;66e6
	and 003h		;66e7   ; cuadrante en A'
	ex af,af'			;66e9
	call absolutos		;66ea   ; valores absolutos
	ld a,e			;66ed
	cp l			;66ee   ; iguales: 45 grados
	jr z,L_6723		;66ef
	jr c,L_66F4		;66f1
	ex de,hl			;66f3   ; el menor en E
L_66F4:
	push af			;66f4
	ld bc,00800h		;66f5
	ld a,e			;66f8
L_66F9:
	sla c		;66f9
	add a,a			;66fb
	jr c,L_6701		;66fc
	cp l			;66fe
	jr c,L_6703		;66ff
L_6701:
	sub l			;6701
	inc c			;6702
L_6703:
	djnz L_66F9		;6703
	pop af			;6705
	ld b,0c3h		;6706   ; tabla de arcotangentes 0xC300
	ld a,(bc)			;6708   ; angulo dentro del octante
	jr nc,L_670F		;6709
	sub 040h		;670b   ; complemento si se cambiaron
	neg		;670d
L_670F:
	ld c,a			;670f   ; C = angulo del octante
	ex af,af'			;6710   ; cuadrante
	jr z,L_671B		;6711
	dec a			;6713
	jr z,L_671F		;6714
	dec a			;6716
	ld a,080h		;6717   ; media vuelta
	jr z,L_671F		;6719
L_671B:
	sub c			;671b
	add a,080h		;671c
	ret			;671e
L_671F:
	add a,c			;671f
	add a,080h		;6720
	ret			;6722
L_6723:
	and a			;6723
	jr z,L_672A		;6724
	ld a,020h		;6726
	jr L_670F		;6728
L_672A:
	ld a,040h		;672a
	ret			;672c
distancia:		; A = raiz de (dx2 + dy2) de la diferencia HL, como mucho 0x7F
	call absolutos		;672d   ; abs de las diferencias
	call cuadrados		;6730   ; cuadrados
	add hl,de			;6733   ; dx2 + dy2
	call raiz		;6734   ; raiz
	and a			;6737
	ret p			;6738
	ld a,07fh		;6739   ; tope 0x7F
	ret			;673b
multiplica:		; HL = A * E sin signo
	ld l,a			;673c
	xor a			;673d
	ex af,af'			;673e
	jr L_6747		;673f
multiplica_signo_huerfano:		; Huerfano: multiplicaria A * E con el signo de los dos
	ld l,a			;6741
	xor e			;6742
	ex af,af'			;6743
	call absolutos		;6744
L_6747:
	ld a,e			;6747
	cp l			;6748
	jr c,L_674D		;6749
	ex de,hl			;674b
	ld a,e			;674c
L_674D:
	ld e,l			;674d
	ld h,000h		;674e
	ld d,h			;6750
	ld b,008h		;6751
L_6753:
	add a,a			;6753
	jr c,L_6760		;6754
	djnz L_6753		;6756
	ld l,h			;6758
	jr L_6762		;6759
L_675B:
	add hl,hl			;675b
	rla			;675c
	jr nc,L_6760		;675d
	add hl,de			;675f
L_6760:
	djnz L_675B		;6760
L_6762:
	ex af,af'			;6762   ; signo del resultado
	jp p,L_676D		;6763
	xor a			;6766   ; negativo: HL = -HL
	sub l			;6767
	ld l,a			;6768
	sbc a,a			;6769
	sub h			;676a
	ld h,a			;676b
	ret			;676c
L_676D:
	ld a,h			;676d
	ret			;676e
multiplica_d_huerfano:		; Huerfano: multiplicaria con el signo de D
	ld l,a			;676f
	ld a,d			;6770
	and a			;6771
	ex af,af'			;6772
	jr L_6747		;6773
multiplica16:		; HL = DE * HL (16 bits)
	ld c,l			;6775
	ld a,h			;6776
	ld hl,00000h		;6777
	ld b,010h		;677a
L_677C:
	add hl,hl			;677c
	sla c		;677d
	rla			;677f
	jr nc,L_6783		;6780
	add hl,de			;6782
L_6783:
	djnz L_677C		;6783
	ret			;6785
divide16:		; HL = HL / DE
	ld c,h			;6786
	ld a,l			;6787
	ld hl,00000h		;6788
	ld b,010h		;678b
L_678D:
	add a,a			;678d   ; bit siguiente del dividendo
	rl c		;678e
	adc hl,hl		;6790   ; al resto
	push hl			;6792
	and a			;6793
	sbc hl,de		;6794   ; resto menos divisor
	jr c,L_679A		;6796   ; no cabe
	inc a			;6798   ; bit 1 en el cociente
	ex (sp),hl			;6799
L_679A:
	pop hl			;679a
	djnz L_678D		;679b
	ld l,a			;679d
	ld h,c			;679e
	ret			;679f
divide8:		; L = HL / D (8 pasos)
	push bc			;67a0
	ld e,000h		;67a1
	ld b,008h		;67a3
L_67A5:
	add hl,hl			;67a5   ; siguiente paso
	and a			;67a6
	sbc hl,de		;67a7   ; resta el divisor
	inc hl			;67a9   ; bit del cociente
	jp p,L_67B0		;67aa
	add hl,de			;67ad   ; no cabia: se repone
	res 0,l		;67ae
L_67B0:
	djnz L_67A5		;67b0
	pop bc			;67b2
	ret			;67b3
aleatorio:		; Generador pseudoaleatorio de 16 bits en (0xC400): cuatro pasos de registro de desplazamiento; devuelve el byte bajo en A
	push bc			;67b4
	push hl			;67b5
	ld b,004h		;67b6
	ld hl,(0c400h)		;67b8   ; semilla
L_67BB:
	add hl,hl			;67bb   ; desplaza la semilla
	rla			;67bc
	rla			;67bd
	xor l			;67be   ; mezcla de bits
	rla			;67bf
	xor l			;67c0
	srl a		;67c1
	srl a		;67c3
	cpl			;67c5   ; bit nuevo
	and 001h		;67c6
	or l			;67c8   ; entra por la derecha
	ld l,a			;67c9
	djnz L_67BB		;67ca   ; cuatro bits nuevos
	ld (0c400h),hl		;67cc   ; semilla nueva
	ld a,l			;67cf   ; A = byte bajo
	pop hl			;67d0
	pop bc			;67d1
	ret			;67d2
tabla_c2_desfase:		; DE = valor con signo de la tabla 0xC200 en A-0x40
	sub 040h		;67d3
tabla_c2:		; DE = valor con signo de la tabla 0xC200 en A
	ld l,a			;67d5
	ld h,0c2h		;67d6   ; tabla 0xC200
	ld e,(hl)			;67d8   ; valor
	ld d,000h		;67d9
	and a			;67db
	ret p			;67dc   ; positivo
	dec d			;67dd   ; negativo: D = 0xFF
	ret			;67de
tablas_mates:		; Tablas de 0xC000: cuadrados (0xC000 bajo, 0xC100 alto), curva simetrica 0xC200 y arcotangentes 0xC300
	ld hl,0c000h		;67df   ; 0xC000: la tabla de 256 palabras (bajo en 0xC0xx, alto en 0xC1xx)
L_67E2:
	push hl			;67e2   ; guarda la posicion
	ld a,l			;67e3   ; A = indice 0-255
	ld e,a			;67e4   ; E = indice
	call multiplica		;67e5   ; n por n
	ex de,hl			;67e8   ; DE = el valor
	pop hl			;67e9   ; recupera la posicion
	ld (hl),e			;67ea   ; byte bajo del cuadrado en 0xC000
	inc h			;67eb   ; 0xC1xx
	ld (hl),d			;67ec   ; byte alto en 0xC100
	dec h			;67ed   ; 0xC0xx
	inc l			;67ee   ; siguiente indice
	jr nz,L_67E2		;67ef   ; los 256
	xor a			;67f1   ; A = 0: el primer valor
	ld de,0c300h		;67f2   ; arcotangentes en 0xC300
	ld hl,0681dh		;67f5   ; cuantas veces sale cada valor (0x681D)
L_67F8:
	ld b,(hl)			;67f8   ; B = longitud del tramo
L_67F9:
	ld (de),a			;67f9   ; el valor, B veces
	inc e			;67fa   ; siguiente posicion
	djnz L_67F9		;67fb   ; el tramo
	inc hl			;67fd   ; siguiente longitud
	inc a			;67fe   ; valor siguiente
	cp 021h		;67ff   ; valores 0 a 0x20
	jr nz,L_67F8		;6801   ; hasta 0x21: 33 tramos
	and a			;6803   ; sin acarreo para el ultimo byte
	ld bc,0687dh		;6804   ; curva leida al reves desde 0x687D
	ld de,0c240h		;6807   ; mitad de arriba desde 0xC240
	ld hl,0c23fh		;680a   ; mitad de abajo desde 0xC23F
L_680D:
	ld a,(bc)			;680d   ; un byte de la tabla, de atras adelante
	ld (de),a			;680e   ; hacia arriba desde 0xC240
	ld (hl),a			;680f   ; hacia abajo desde 0xC23F
	dec bc			;6810   ; byte anterior
	inc de			;6811   ; posicion de arriba
	jr z,L_6817		;6812   ; L llego a cero: ya esta
	dec l			;6814   ; posicion de abajo
	jr L_680D		;6815   ; siguiente
L_6817:
	ld bc,00080h		;6817   ; SUPOSICION: segunda mitad de la tabla
	ldir		;681a   ; copia el ultimo tramo
	ret			;681c

; ----------------------------------------------------------------------
; DATOS anchuras_perspectiva: 33 longitudes de tramo (0x67F5 las escribe como
;   ceros seguidos de un 1 en 0xC300) y, leidas al reves desde 0x687D por
;   0x6804, el espejo que rellena 0xC240 hacia arriba y 0xC23F hacia abajo
;   0x681d..0x687e  (97 bytes)
DATA_anchuras_perspectiva:
	defb 004h,006h,006h,007h,006h,006h,007h,006h,007h,006h,007h	; 681d  ...........
	defb 007h,007h,007h,007h,007h,007h,008h,007h,008h,008h,009h	; 6828  ...........
	defb 008h,009h,009h,00ah,009h,00ah,00bh,00bh,00bh,00ch,006h	; 6833  ...........
	defb 000h,006h,00dh,013h,019h,01fh,026h,02ch,032h,038h,03eh	; 683e  ......&,28>
	defb 044h,04ah,050h,056h,05ch,062h,068h,06dh,073h,079h,07eh	; 6849  DJPV\bhmsy~
	defb 084h,089h,08eh,093h,098h,09dh,0a2h,0a7h,0ach,0b1h,0b5h	; 6854  ...........
	defb 0b9h,0beh,0c2h,0c6h,0cah,0ceh,0d1h,0d5h,0d8h,0dch,0dfh	; 685f  ...........
	defb 0e2h,0e5h,0e7h,0eah,0edh,0efh,0f1h,0f3h,0f5h,0f7h,0f8h	; 686a  ...........
	defb 0fah,0fbh,0fch,0fdh,0feh,0ffh,0ffh,0ffh,0ffh	; 6875  .........

; ======================================================================
; CODIGO 0x687e..0x6afd  (639 bytes)
; ======================================================================


interrupcion:		; H.TIMI: tablas de sprites, sonido, contadores, saltos y cambio de pose de un jugador por cuadro
	ld a,0ffh		;687e   ; aviso al bucle principal: ya hubo interrupcion
	ld (0ebd0h),a		;6880
	call alterna_sprites		;6883
	call tick_sonido		;6886   ; tick del sonido
	ld hl,0ebcfh		;6889   ; cuenta de cuadros
	inc (hl)			;688c
	ld hl,(0c600h)		;688d   ; cuenta atras en cuadros de 0xC600
	ld a,h			;6890
	or l			;6891
	jr z,L_6898		;6892
	dec hl			;6894
	ld (0c600h),hl		;6895
L_6898:
	call reloj		;6898   ; reloj y temporizadores del partido
	call descuenta_ordenes		;689b
	ld ix,0c410h		;689e   ; saltos: los seis jugadores
	ld de,00030h		;68a2
	ld b,006h		;68a5
L_68A7:
	xor a			;68a7
	or (ix+026h)		;68a8   ; SUPOSICION: retardo +0x26 del jugador
	jr z,siguiente_retardo		;68ab
	dec (ix+026h)		;68ad
siguiente_retardo:		; Bucle de retardos (+0x26) y resto de la interrupcion: pose pendiente, botones, giro del controlado, caidas y red
	add ix,de		;68b0   ; siguiente registro
	djnz L_68A7		;68b2
	ld a,(0ecebh)		;68b4   ; bit 7 de 0xECEB: aun hay pose por copiar
	and a			;68b7
	call p,busca_pose_cambiada		;68b8   ; sin pose pendiente: busca la siguiente
	call cuenta_botones		;68bb   ; botones de los dos equipos
	call controlado		;68be   ; controlado del equipo con el balon
	call registro_jugador		;68c1
	ld de,00016h		;68c4   ; +0x16: rumbo al que gira
	add hl,de			;68c7
	ld a,(hl)			;68c8
	and a			;68c9
	jp m,caidas		;68ca   ; 0xFF: no gira
	dec hl			;68cd   ; +0x14: cuadros hasta el siguiente paso
	dec hl			;68ce
	ld a,(hl)			;68cf
	and a			;68d0
	jr nz,espera_giro		;68d1   ; aun esperando
	inc hl			;68d3
	ld a,(hl)			;68d4   ; direccion actual (+0x15)
	inc hl			;68d5
	cp (hl)			;68d6   ; ya mira al rumbo?
	jr z,fin_giro		;68d7
	ld b,a			;68d9
	ld a,(hl)			;68da   ; giro en curso (+0x17)
	cp b			;68db
	jr z,fin_giro		;68dc   ; ya llego
	inc hl			;68de
	inc hl			;68df
	ld a,(hl)			;68e0   ; sentido del giro (+0x18)
	dec hl			;68e1
	dec hl			;68e2
	dec hl			;68e3
	add a,(hl)			;68e4   ; un paso de giro
	inc hl			;68e5
	inc hl			;68e6
	and 007h		;68e7
	ld (hl),a			;68e9   ; direccion nueva en +0x17
	dec hl			;68ea
	dec hl			;68eb
	dec hl			;68ec
	ld (hl),006h		;68ed   ; seis cuadros por paso
	jr caidas		;68ef
espera_giro:		; Un cuadro menos para el siguiente paso de giro
	dec (hl)			;68f1
	jr caidas		;68f2
fin_giro:		; Giro acabado: rumbo y giro a 0xFF, sentido 0
	xor a			;68f4
	dec a			;68f5   ; 0xFF
	ld (hl),a			;68f6   ; rumbo: ninguno
	inc hl			;68f7
	ld (hl),a			;68f8   ; giro: ninguno
	inc hl			;68f9
	inc a			;68fa
	ld (hl),a			;68fb   ; sentido 0
caidas:		; Un paso de la caida de los seis jugadores que estan en el aire
	ld hl,0c410h		;68fc   ; caida de los jugadores en el aire
	ld b,006h		;68ff   ; seis jugadores
	ld c,000h		;6901
L_6903:
	push hl			;6903
	push hl			;6904
	ld de,0000ch		;6905   ; +0x0C gravedad: distinto de 0 en el aire
	add hl,de			;6908
	ld a,(hl)			;6909
	pop hl			;690a
	and a			;690b
	call nz,caida		;690c
	pop hl			;690f
	ld de,00030h		;6910   ; siguiente registro
	add hl,de			;6913
	inc c			;6914   ; numero de jugador
	djnz L_6903		;6915
anima_red:		; Animacion de la red tras una canasta: cinco pasos de 10 cuadros
	ld a,(0c543h)		;6917   ; paso de la red (negativo: parada)
	and a			;691a
	ret m			;691b
	ld a,(0c544h)		;691c   ; cuadros del paso
	and a			;691f
	jr z,paso_red		;6920
	dec a			;6922
	ld (0c544h),a		;6923   ; un cuadro menos
	ret			;6926
paso_red:		; Siguiente paso de la red; tras el quinto se para (0xFF)
	ld a,(0c543h)		;6927
	inc a			;692a
	cp 005h		;692b   ; cinco pasos
	jr c,L_6931		;692d
	ld a,0ffh		;692f
L_6931:
	ld (0c543h),a		;6931
	ret nc			;6934
	ld a,00ah		;6935   ; 10 cuadros por paso
	ld (0c544h),a		;6937
	ret			;693a
caida:		; Un paso de la parabola del salto: Z (+8) menos velocidad (+0x0A), velocidad menos gravedad (+0x0C); al tocar el suelo lo para
	push hl			;693b
	pop ix		;693c
	ld e,(ix+00ah)		;693e   ; velocidad vertical
	ld d,(ix+00bh)		;6941   ; (+0x0A/+0x0B)
	ld l,(ix+008h)		;6944   ; altura (negativa = en el aire)
	ld h,(ix+009h)		;6947   ; (+8/+9)
	and a			;694a
	sbc hl,de		;694b   ; Z menos velocidad
	jp p,L_6966		;694d   ; llega al suelo
	ld (ix+008h),l		;6950
	ld (ix+009h),h		;6953
	ld l,(ix+00ch)		;6956   ; la gravedad frena la subida
	ld h,000h		;6959   ; gravedad (+0x0C)
	ex de,hl			;695b
	and a			;695c
	sbc hl,de		;695d
	ld (ix+00ah),l		;695f   ; velocidad nueva
	ld (ix+00bh),h		;6962
	ret			;6965
L_6966:
	xor a			;6966   ; en el suelo: todo a cero
	ld (ix+00ch),a		;6967   ; sin gravedad: en el suelo
	ld (ix+00ah),a		;696a   ; velocidad vertical a cero
	ld (ix+00bh),a		;696d
	ld (ix+008h),a		;6970   ; altura a cero
	ld (ix+009h),a		;6973
	ld (ix+014h),a		;6976   ; sin pasos de giro
	ld (ix+018h),a		;6979   ; sentido 0
	dec a			;697c
	ld (ix+016h),a		;697d   ; SUPOSICION: sin destino de balon
	ld a,c			;6980
	call borra_saltador		;6981   ; ya no es saltador de su equipo
	ld a,(0c5dfh)		;6984   ; el que cae es el poseedor?
	cp c			;6987
	ret nz			;6988
	ld a,(0c607h)		;6989   ; salto con el balon?
	and a			;698c
	ret z			;698d
	xor a			;698e
	ld (0c607h),a		;698f   ; se acabo el salto
	ld (0cb35h),a		;6992   ; rotulo 0: TRAVELLING
	ld a,c			;6995
	ld (0cb34h),a		;6996   ; infractor: el que cae con el balon
	ret			;6999
busca_pose_cambiada:		; Recorre los seis jugadores desde el ultimo atendido y apunta en 0xECEB/0xECEC el primero con la pose cambiada
	ld a,(0eceah)		;699a   ; ultimo jugador atendido
	call siguiente_de_seis		;699d   ; empieza por el siguiente
	call registro_jugador		;69a0
	ld de,0000fh		;69a3   ; +0x0F del primer registro
	add hl,de			;69a6
	ld de,00030h		;69a7
	ld b,006h		;69aa   ; seis jugadores
L_69AC:
	bit 7,(hl)		;69ac   ; bit 7 de +0x0F: pose cambiada
	jr nz,L_69BC		;69ae
	call siguiente_de_seis		;69b0   ; siguiente numero
	jr nz,L_69B8		;69b3
	ld hl,0c3efh		;69b5   ; al pasar del 5 vuelve a 0xC410 (0xC3EF + 0x30)
L_69B8:
	add hl,de			;69b8
	djnz L_69AC		;69b9
	ret			;69bb
L_69BC:
	ld (0eceah),a		;69bc   ; ultimo atendido
	or 080h		;69bf
	ld (0ecebh),a		;69c1   ; jugador pendiente para 0x65EE
	ld de,0000fh		;69c4   ; de +0x0F al registro
	and a			;69c7
	sbc hl,de		;69c8
	ld (0ecech),hl		;69ca
	ret			;69cd
siguiente_de_seis:		; A+1 dando la vuelta en 6
	inc a			;69ce
	cp 006h		;69cf
	ret c			;69d1
	xor a			;69d2
	ret			;69d3
pon_poseedor:		; El jugador C tiene el balon: su equipo lo controla, el rival controla a su par y, si cambia el equipo, se invierte el ataque
	ld c,a			;69d4
	call controla		;69d5   ; controlado de su equipo
	call espejo_jugador		;69d8   ; su par del otro equipo
	call controla		;69db   ; controlado del otro equipo
	ld a,c			;69de
	call registro_jugador		;69df
	ld (0c5e0h),hl		;69e2   ; registro del poseedor
	ld a,(0c5dfh)		;69e5   ; bits 0-2: poseedor
	and 0f8h		;69e8
	or c			;69ea
	ld (0c5dfh),a		;69eb
	and 007h		;69ee
	ld b,a			;69f0
	ld a,(0c5e2h)		;69f1   ; ultimo poseedor
	and a			;69f4
	ret m			;69f5   ; negativo: no se cuenta
	ld c,a			;69f6
	ld a,b			;69f7
	cp c			;69f8   ; el mismo: nada que hacer
	ret z			;69f9
	ld (0c5e2h),a		;69fa   ; nuevo ultimo poseedor
	cp 003h		;69fd   ; equipo 0 o 1
	jr nc,L_6A04		;69ff
	xor a			;6a01
	jr L_6A06		;6a02
L_6A04:
	ld a,001h		;6a04
L_6A06:
	ld b,a			;6a06
	ld a,(0ecf1h)		;6a07   ; equipo con el balon
	cp b			;6a0a   ; no ha cambiado
	ret z			;6a0b
	ld a,080h		;6a0c   ; cambio pendiente (bit 7)
	or b			;6a0e
	ld (0ecf1h),a		;6a0f
	jp cambio_de_posesion		;6a12   ; se invierte el sentido de ataque
espejo_jugador:		; A = indice espejo (+0x25) del jugador A
	call registro_jugador		;6a15
	ld de,00025h		;6a18
	add hl,de			;6a1b
	ld a,(hl)			;6a1c
	ret			;6a1d
cuenta_botones:		; Interrupcion: cuadros que cada equipo lleva con el boton 1 pulsado
	ld hl,0c5e3h		;6a1e   ; entrada del equipo izquierdo
	bit 7,(hl)		;6a21
	jr z,L_6A29		;6a23
	ld hl,0c5e4h		;6a25   ; cuadros de boton del izquierdo
	inc (hl)			;6a28
L_6A29:
	ld hl,0c5e5h		;6a29   ; entrada del equipo derecho
	bit 7,(hl)		;6a2c
	jr z,L_6A34		;6a2e
	ld hl,0c5e6h		;6a30   ; cuadros de boton del derecho
	inc (hl)			;6a33
L_6A34:
	call boton2_ataque		;6a34   ; boton 2 del ataque y del defensor
	jp boton1_defensa		;6a37   ; boton 1 del defensor
boton2_ataque:		; SUPOSICION: En campo contrario el boton 2 del equipo con el balon elige formacion o corta la que hay
	call boton2_defensa		;6a3a   ; boton 2 del equipo sin balon
	ld a,(0c5dfh)		;6a3d   ; poseedor
	and 007h		;6a40
	call registro_jugador		;6a42
	ld de,0000fh		;6a45   ; lado y campo (+0x0F)
	add hl,de			;6a48
	ld a,(hl)			;6a49
	add a,a			;6a4a
	add a,a			;6a4b
	xor (hl)			;6a4c
	bit 6,a		;6a4d
	ret nz			;6a4f   ; en su campo: no hay formaciones
	ld a,(0ecf1h)		;6a50   ; entrada del equipo con el balon
	and 001h		;6a53
	ld a,(0c5e3h)		;6a55
	jr z,L_6A5D		;6a58
	ld a,(0c5e5h)		;6a5a
L_6A5D:
	bit 6,a		;6a5d   ; bit 6: boton 2
	jr z,boton2_suelto		;6a5f
	ld a,(0ecf2h)		;6a61   ; ya estaba pulsado
	and a			;6a64
	ret nz			;6a65
	ld a,0ffh		;6a66   ; pulsacion atendida
	ld (0ecf2h),a		;6a68
	ld a,(0c616h)		;6a6b   ; hay formacion en curso?
	cp 03fh		;6a6e
	jr z,L_6A7A		;6a70
	ld a,03fh		;6a72   ; la corta
	ld (0c616h),a		;6a74
	xor a			;6a77   ; FORMATION= sin letra
	jr L_6A84		;6a78
L_6A7A:
	ld a,(0cb1fh)		;6a7a   ; siguiente formacion de las seis
	inc a			;6a7d
	cp 006h		;6a7e
	jr c,L_6A84		;6a80
	sub 006h		;6a82
L_6A84:
	set 7,a		;6a84   ; bit 7: repintar
	ld (0cb1fh),a		;6a86
	ret			;6a89
boton2_suelto:		; Boton 2 suelto
	xor a			;6a8a
	ld (0ecf2h),a		;6a8b
	ret			;6a8e
boton2_defensa:		; SUPOSICION: El boton 2 del equipo sin balon pasa el control al siguiente de sus tres jugadores
	ld a,(0ecf1h)		;6a8f
	and 001h		;6a92   ; equipo con el balon
	ld a,(0c5e3h)		;6a94   ; entrada del izquierdo si defiende
	jr nz,L_6A9C		;6a97
	ld a,(0c5e5h)		;6a99   ; entrada del derecho si defiende
L_6A9C:
	bit 6,a		;6a9c   ; bit 6: boton 2
	jr z,boton2_defensa_suelto		;6a9e
	ld a,(0ecf3h)		;6aa0   ; ya estaba pulsado
	and a			;6aa3
	ret nz			;6aa4
	ld a,0ffh		;6aa5
	ld (0ecf3h),a		;6aa7
	ld a,(0ecf1h)		;6aaa   ; defiende el derecho?
	and a			;6aad
	jr nz,L_6ABC		;6aae
	ld a,(0c5ebh)		;6ab0   ; controlado del derecho
	inc a			;6ab3   ; siguiente de 3 a 5
	cp 006h		;6ab4
	jr c,L_6AC5		;6ab6
	ld a,003h		;6ab8
	jr L_6AC5		;6aba
L_6ABC:
	ld a,(0c5e8h)		;6abc   ; controlado del izquierdo
	inc a			;6abf   ; siguiente de 0 a 2
	cp 003h		;6ac0
	jr c,L_6AC5		;6ac2
	xor a			;6ac4
L_6AC5:
	jp controla		;6ac5   ; nuevo controlado
boton2_defensa_suelto:		; Boton 2 suelto
	xor a			;6ac8
	ld (0ecf3h),a		;6ac9
	ret			;6acc
boton1_defensa:		; SUPOSICION: Al pulsar el boton 1 del equipo sin balon pide un intento de robo (0xC5FD)
	ld a,(0c5fdh)		;6acd   ; intento aun pendiente
	and a			;6ad0
	ret nz			;6ad1
	ld a,(0ecf1h)		;6ad2   ; equipo con el balon
	and 001h		;6ad5
	jr z,L_6ADE		;6ad7
	ld a,(0c5e3h)		;6ad9   ; entrada del izquierdo
	jr L_6AE1		;6adc
L_6ADE:
	ld a,(0c5e5h)		;6ade   ; entrada del derecho
L_6AE1:
	bit 7,a		;6ae1   ; bit 7: boton 1
	ld a,000h		;6ae3
	jr z,L_6AE8		;6ae5
	inc a			;6ae7
L_6AE8:
	ld hl,0ecf6h		;6ae8   ; estado anterior del boton
	cp (hl)			;6aeb
	ret z			;6aec
	ld (hl),a			;6aed   ; estado nuevo
	and a			;6aee
	ret z			;6aef
	ld (0c5fdh),a		;6af0   ; recien pulsado: intento de robo
	ret			;6af3
marcador_ram:		; Descomprime el marcador de 21 x 4 (0x6AFD) a 0xECF7
	ld hl,06afdh		;6af4
	ld de,0ecf7h		;6af7
	jp descomprime_rep		;6afa

; ----------------------------------------------------------------------
; DATOS marcador_comprimido: Bloque comprimido en el formato de 0x60B8 (50
;   bytes) que 0x6AF4 descomprime en 0xECF7: 84 numeros de patron, las filas
;   del marcador (0x60-0x71, 0x5C-0x5F y los 0x65 del borde)
;   0x6afd..0x6b2f  (50 bytes)
DATA_marcador_comprimido:
	defb 080h,080h,060h,064h,064h,068h,08ah,064h,068h,064h	; 6afd  ..`ddh.dhd
	defb 064h,061h,066h,070h,071h,06ah,082h,020h,05ch,05dh	; 6b07  dafpqj. \]
	defb 05eh,05fh,081h,020h,06ah,070h,071h,067h,066h,020h	; 6b11  ^_. jpqgf 
	defb 020h,06ah,08ah,020h,06ah,020h,020h,067h,062h,065h	; 6b1b   j. j  gbe
	defb 065h,069h,08ah,065h,069h,065h,065h,063h,080h,080h	; 6b25  ei.eieec..

; ======================================================================
; CODIGO 0x6b2f..0x6bac  (125 bytes)
; ======================================================================


logotipo:		; Descomprime el logotipo (0xB9D4 patrones, 0xBB27 colores) a los patrones 0xB0-0xFF de los tres tercios
	call borra_nombres		;6b2f
	ld de,0cb3dh		;6b32
	ld hl,0b9d4h		;6b35
	call descomprime		;6b38
	ld de,00580h		;6b3b   ; patrones 0xB0-0xFF del primer tercio
	ld hl,0cb3dh		;6b3e
	ld bc,00280h		;6b41
	call tres_tercios		;6b44
	ld hl,0bb27h		;6b47   ; sus colores
	ld de,0cb3dh		;6b4a
	call descomprime		;6b4d
	ld de,02580h		;6b50   ; colores desde 0x2580
	ld hl,0cb3dh		;6b53
	ld bc,00280h		;6b56
tres_tercios:		; Copia BC bytes de HL a la VRAM DE y a los dos tercios siguientes (0x800 mas alla)
	ld a,003h		;6b59   ; tres tercios
L_6B5B:
	push hl			;6b5b   ; guarda el origen
	push de			;6b5c   ; el destino
	push bc			;6b5d   ; la cuenta
	push af			;6b5e   ; y los tercios que quedan
	call copia_a_vram		;6b5f   ; un tercio
	pop af			;6b62   ; recupera los tercios
	pop bc			;6b63   ; la cuenta
	pop de			;6b64   ; y el destino
	ld hl,00800h		;6b65   ; 0x800 mas
	add hl,de			;6b68   ; el tercio siguiente
	ex de,hl			;6b69   ; DE = destino
	pop hl			;6b6a   ; recupera el origen
	dec a			;6b6b   ; un tercio menos
	jr nz,L_6B5B		;6b6c   ; los tres
	ret			;6b6e
colores_area:		; Colores de la pista segun COLOR OF COURT (tabla 0x6BAC) en los tres tercios y 0xB556 encima en 0x2100
	call congela_sprites		;6b6f   ; pantalla parada
	ld a,(0ed5bh)		;6b72   ; COLOR OF COURT
	add a,a			;6b75   ; por dos
	add a,a			;6b76   ; por cuatro: cuatro bytes por AREA
	ld l,a			;6b77   ; HL = AREA * 4
	ld h,000h		;6b78   ; HL = indice
	ld de,06bach		;6b7a   ; tabla de bloques de color por AREA
	add hl,de			;6b7d   ; HL = la ficha del AREA
	ld e,(hl)			;6b7e   ; puntero bajo
	inc hl			;6b7f   ; siguiente
	ld d,(hl)			;6b80   ; puntero alto
	ex de,hl			;6b81   ; HL = la tabla de colores comprimida
	ld de,0cb3dh		;6b82   ; a 0xCB3D
	call descomprime_parejas		;6b85   ; parejas repetidas
	ld hl,0cb3dh		;6b88   ; desde el bufer
	ld de,02000h		;6b8b   ; tabla de colores 0x2000
	ld bc,00800h		;6b8e   ; 0x800 bytes: los 256 colores de un tercio
	call tres_tercios		;6b91   ; a los tres tercios
	ld hl,0b556h		;6b94   ; colores comunes a las tres AREAS
	ld de,0cb3dh		;6b97   ; a 0xCB3D
	call descomprime_marca		;6b9a   ; descomprime (marca c v n)
	ld hl,0cb3dh		;6b9d   ; desde el bufer
	ld de,02100h		;6ba0   ; desde 0x2100
	ld bc,002a0h		;6ba3   ; 0x2A0 bytes: los patrones 0x20-0x73
	call tres_tercios		;6ba6   ; a los tres tercios desde 0x2100
	jp suelta_sprites		;6ba9   ; pantalla en marcha, y vuelve

; ----------------------------------------------------------------------
; DATOS areas: Tres fichas de cuatro bytes, una por AREA del menu: puntero a
;   su tabla de colores comprimida (0xB23E, 0xB346, 0xB44E) y dos colores;
;   0x6B6F elige la de (0xED5B) y la descomprime (0x60FA) en 0xCB3D para la
;   tabla de colores de la VRAM, y 0x75C4 lee los dos bytes de detras
;   0x6bac..0x6bb8  (12 bytes)
DATA_areas:
	defw 0b23eh	; 6bac  -> DATA_colores_area_1
	defb 081h,051h	; 6bae
	defb 046h,0b3h	; 6bb0
	defb 021h,081h	; 6bb2
	defb 04eh,0b4h	; 6bb4
	defb 051h,021h	; 6bb6

; ======================================================================
; CODIGO 0x6bb8..0x6cbf  (263 bytes)
; ======================================================================


rotulo_falta_marcador:		; Para el reloj y escribe en el marcador el rotulo, el jugador y sus faltas; con 5 faltas personales expulsa al jugador de un equipo de personas, y a uno de la maquina solo le borra las faltas (la primera version lo sacaba de la pista en los dos casos)
	ld hl,0ed6bh		;6bb8
	ld (hl),001h		;6bbb   ; reloj parado
	inc hl			;6bbd
	ld b,005h		;6bbe
L_6BC0:
	ld (hl),002h		;6bc0   ; cuentas desactivadas
	inc hl			;6bc2
	djnz L_6BC0		;6bc3
	ld a,(0ed4dh)		;6bc5   ; tipo de falta (bits 3-6 de 0xED4D)
	rra			;6bc8
	rra			;6bc9
	rra			;6bca
	and 00fh		;6bcb
	push af			;6bcd
	ld hl,06d41h		;6bce   ; cabecera de violacion
	cp 005h		;6bd1
	jr c,L_6BD8		;6bd3
	ld hl,06d4eh		;6bd5   ; cabecera de falta personal
L_6BD8:
	ld bc,0000dh		;6bd8
	ld de,0182ah		;6bdb   ; fila 1 del marcador
	call copia_a_vram		;6bde
	pop af			;6be1
	push af			;6be2
	call pinta_rotulo		;6be3   ; rotulo del tipo
	ld c,000h		;6be6
	call campo_cabecera		;6be8   ; nombre del jugador
	ld de,0182bh		;6beb
	ld bc,00003h		;6bee
	call copia_a_vram		;6bf1
	ld a,(0ed4dh)		;6bf4   ; numero del jugador
	and 007h		;6bf7
	add a,031h		;6bf9
	ld hl,0182fh		;6bfb
	call escribe_vram		;6bfe
	ld c,018h		;6c01   ; campo 0x18 del roster: faltas personales
	call campo_equipo		;6c03
	ld a,(0ed4dh)		;6c06
	and 007h		;6c09
	ld c,a			;6c0b
	ld b,000h		;6c0c
	add hl,bc			;6c0e
	pop af			;6c0f
	cp 005h		;6c10
	jr c,L_6C26		;6c12
	inc (hl)			;6c14   ; una falta mas
	push hl			;6c15
	ld c,005h		;6c16   ; campo 5: faltas del partido
	call campo_equipo		;6c18
	inc (hl)			;6c1b
	call congela_sprites		;6c1c
	call pinta_faltas_equipo		;6c1f   ; faltas de equipo en el marcador
	call suelta_sprites		;6c22
	pop hl			;6c25
L_6C26:
	ld a,(hl)			;6c26   ; faltas del jugador
	and a			;6c27
	jr z,L_6C39		;6c28   ; ninguna
	push af			;6c2a
	push hl			;6c2b
	ld c,a			;6c2c
	ld b,000h		;6c2d
	ld a,06fh		;6c2f   ; una marca por falta
	ld hl,01831h		;6c31   ; fila 1, columna 17
	call rellena_vram		;6c34
	pop hl			;6c37
	pop af			;6c38
L_6C39:
	ld c,a			;6c39   ; C = faltas del jugador
	push hl			;6c3a
	xor a			;6c3b   ; (0xED5D) a cero: ningun cambio pedido
	ld (0ed5dh),a		;6c3c
	ld hl,000f0h		;6c3f   ; cuatro segundos de rotulo
	ld (0ed7eh),hl		;6c42   ; temporizador del rotulo
	pop hl			;6c45
	ld a,(0ed4dh)		;6c46   ; tipo de falta (bits 3-6 de 0xED4D)
	and 078h		;6c49
	rra			;6c4b
	rra			;6c4c
	rra			;6c4d
	cp 005h		;6c4e
	jr c,L_6C73		;6c50   ; violacion: sigue el juego tras el rotulo
	ld a,c			;6c52   ; faltas del jugador
	cp 005h		;6c53   ; menos de cinco: sigue el juego
	jr c,L_6C73		;6c55   ; sigue
	push hl			;6c57
	call modo_equipo		;6c58   ; modo del equipo del jugador: 0 = lo lleva una persona
	ld a,(hl)			;6c5b
	pop hl			;6c5c
	and a			;6c5d
	jr nz,L_6C71		;6c5e   ; de la maquina: solo se le borran las faltas (0x6C71); la primera version la sacaba de la pista igual
	ld c,007h		;6c60   ; campo 7 del roster: la mascara de jugadores en pista
	call campo_equipo		;6c62
	and 007h		;6c65
	ld b,a			;6c67
	call bit_de		;6c68   ; fuera de la mascara de jugadores en pista
	cpl			;6c6b
	and (hl)			;6c6c
	ld (hl),a			;6c6d
	jp L_6E7D		;6c6e   ; de una persona: expulsado, cambio obligado
L_6C71:
	ld (hl),000h		;6c71   ; equipo de la maquina: faltas a cero
L_6C73:
	ld a,(0ed56h)		;6c73   ; modo del equipo izquierdo
	and a			;6c76   ; 0 = lo lleva una persona
	jp z,espera_cambio		;6c77   ; una persona: espera un disparo o el tiempo
	ld a,(0ed57h)		;6c7a   ; modo del equipo derecho
	and a			;6c7d   ; 0 = lo lleva una persona
	jp z,espera_cambio		;6c7e   ; una persona: espera un disparo o el tiempo
L_6C81:
	ld hl,(0ed7eh)		;6c81   ; espera el rotulo
	ld a,h			;6c84
	or l			;6c85
	jr nz,L_6C81		;6c86
	call congela_sprites		;6c88
	call centra_ventana		;6c8b   ; ventana otra vez al centro
	jp suelta_sprites		;6c8e
pinta_faltas_equipo:		; Faltas de equipo (0xC7F4 y 0xC824) en 0x1847 y 0x1858
	ld de,01847h		;6c91
	ld hl,(0c7f4h)		;6c94
	call dos_cifras_l		;6c97
	ld de,01858h		;6c9a
	ld hl,(0c824h)		;6c9d
dos_cifras_l:		; Numero L de dos cifras en la VRAM DE
	ld h,000h		;6ca0
	ld c,h			;6ca2
	jp L_6DE6		;6ca3
pinta_rotulo:		; Rotulo de falta de indice A (13 caracteres de 0x6CBF) en 0x184A
	ld l,a			;6ca6   ; L = indice del rotulo
	ld h,000h		;6ca7   ; HL = indice
	ld c,l			;6ca9   ; BC = indice
	ld b,h			;6caa
	add hl,hl			;6cab   ; por dos
	add hl,hl			;6cac   ; por cuatro
	ld e,l			;6cad   ; DE = indice * 4
	ld d,h			;6cae   ; guardado
	add hl,hl			;6caf   ; por ocho
	add hl,de			;6cb0   ; mas cuatro: por doce
	add hl,bc			;6cb1   ; mas uno: por trece, lo que mide cada rotulo
	ld de,06cbfh		;6cb2   ; la tabla de los doce rotulos
	add hl,de			;6cb5   ; HL = el rotulo
	ld de,0184ah		;6cb6   ; fila 2, columna 10 de la pantalla
	ld bc,0000dh		;6cb9   ; trece caracteres
	jp copia_a_vram		;6cbc   ; a la VRAM

; ----------------------------------------------------------------------
; DATOS rotulos_falta: Doce rotulos de trece caracteres (0x6CA6 pinta el de
;   indice A en 0x184A): TRAVELLING, 3/5/10/30 SECOND, CHARGING, HACKING,
;   HOLDING, PUSHING, BLOCKING y los dos del contador (los n son digitos). Los
;   0x6C/0x6D de los extremos son los bordes del cuadro
;   0x6cbf..0x6d5b  (156 bytes)
DATA_rotulos_falta:
	defb 06ch,054h,052h,041h,056h,045h,04ch,04ch,049h,04eh,047h,03eh,06ch	; 6cbf  lTRAVELLING>l
	defb 06ch,020h,033h,020h,053h,045h,043h,04fh,04eh,044h,03eh,020h,06ch	; 6ccc  l 3 SECOND> l
	defb 06ch,020h,035h,020h,053h,045h,043h,04fh,04eh,044h,03eh,020h,06ch	; 6cd9  l 5 SECOND> l
	defb 06ch,031h,030h,020h,053h,045h,043h,04fh,04eh,044h,03eh,03eh,06ch	; 6ce6  l10 SECOND>>l
	defb 06ch,033h,030h,020h,053h,045h,043h,04fh,04eh,044h,03eh,03eh,06ch	; 6cf3  l30 SECOND>>l
	defb 06dh,020h,043h,048h,041h,052h,047h,049h,04eh,047h,03eh,020h,06dh	; 6d00  m CHARGING> m
	defb 06dh,020h,048h,041h,043h,04bh,049h,04eh,047h,03eh,03eh,020h,06dh	; 6d0d  m HACKING>> m
	defb 06dh,020h,048h,04fh,04ch,044h,049h,04eh,047h,03eh,03eh,020h,06dh	; 6d1a  m HOLDING>> m
	defb 06dh,020h,050h,055h,053h,048h,049h,04eh,047h,03eh,03eh,020h,06dh	; 6d27  m PUSHING>> m
	defb 06dh,020h,042h,04ch,04fh,043h,04bh,049h,04eh,047h,03eh,020h,06dh	; 6d34  m BLOCKING> m
	defb 06ch,020h,020h,020h,03ch,020h,020h,06eh,06eh,06eh,06eh,06eh,06ch	; 6d41  l   <  nnnnnl
	defb 06dh,020h,020h,020h,03ch,020h,020h,06eh,06eh,06eh,06eh,06eh,06dh	; 6d4e  m   <  nnnnnm

; ======================================================================
; CODIGO 0x6d5b..0x6faa  (591 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Marcador del partido =====
; ----------------------------------------------------------------------
marco_marcador:		; Copia el marcador de 21 x 4 (0xECF7) a la columna 6 de la fila 0
	ld bc,00415h		;6d5b   ; 4 filas de 21
	ld hl,0ecf7h		;6d5e   ; el marcador descomprimido (0x6AF4)
	ld de,01806h		;6d61   ; fila 0, columna 6
	jp copia_bloque		;6d64   ; cuatro filas de 21
monta_marcador:		; Marco, tiempo, puntos, faltas, mitad y nombres de los dos equipos
	call marco_marcador		;6d67   ; el cuadro
	call pinta_tiempo		;6d6a   ; tiempo
	call pinta_puntos		;6d6d   ; puntos
	call pinta_faltas_equipo		;6d70   ; faltas de equipo
	call pinta_mitad		;6d73   ; numero de mitad
	ld de,0182ah		;6d76   ; nombre del equipo izquierdo
	ld hl,0c617h		;6d79   ; el nombre del equipo de la izquierda (0xC617)
	call copia_tres		;6d7c   ; tres letras en la VRAM DE
	ld de,01834h		;6d7f   ; nombre del equipo derecho
	ld hl,0c703h		;6d82   ; el de la derecha (0xC703)
	jp copia_tres		;6d85   ; tres letras
pinta_mitad:		; Numero de la mitad (patron 0x2E + (0xED66)) en 0x182E
	ld a,(0ed66h)		;6d88   ; (0xED66): mitad en curso, 0 o 1
	add a,02eh		;6d8b   ; patron 0x2E o 0x2F: el 1 o el 2 del "HALF"
	ld hl,0182eh		;6d8d   ; fila 1, columna 14
	jp escribe_vram		;6d90   ; a la VRAM
pinta_tiempo:		; Tiempo restante (0xED69, segundos) como m:ss en 0x184E
	xor a			;6d93   ; (0xED5C) a cero
	ld (0ed5ch),a		;6d94   ; tiempo ya repintado
	ld hl,(0ed69h)		;6d97   ; HL = segundos que quedan
	ld de,0184eh		;6d9a   ; fila 2, columna 14: los minutos
	ld c,000h		;6d9d   ; digitos escritos: ninguno
	push de			;6d9f   ; guarda la posicion
	ld de,00258h		;6da0   ; 600 segundos: decenas de minuto
	call divide_resta		;6da3   ; A = decenas de minuto (600 s), C acumula
	pop de			;6da6   ; recupera la posicion
	call cifra		;6da7   ; A = digito o blanco
	call pinta_digito		;6daa   ; a la VRAM, DE++
	inc c			;6dad   ; los minutos siempre se pintan
	push de			;6dae   ; guarda la posicion
	ld de,0003ch		;6daf   ; 60 segundos
	call divide_resta		;6db2   ; A = minutos sueltos (60 s)
	pop de			;6db5   ; recupera la posicion
	call cifra		;6db6   ; digito (C ya no es cero)
	call pinta_digito		;6db9   ; a la VRAM
	ld a,03ah		;6dbc   ; dos puntos y los segundos
	jp dos_cifras		;6dbe   ; los segundos, en dos cifras, detras del ':'
pinta_puntos:		; Puntos de los dos equipos (0xC7F3 y 0xC823) en 0x184A y 0x1854
	xor a			;6dc1   ; (0xED5E) a cero
	ld (0ed5eh),a		;6dc2   ; puntos ya repintados
	ld de,0184ah		;6dc5   ; fila 2, columna 10: puntos de la izquierda
	ld hl,(0c7f3h)		;6dc8   ; puntos del izquierdo
	call pinta_numero		;6dcb   ; tres cifras
	ld de,01854h		;6dce   ; fila 2, columna 20: puntos de la derecha
	ld hl,(0c823h)		;6dd1   ; puntos del derecho
pinta_numero:		; Numero L de tres cifras en la VRAM DE, sin ceros a la izquierda
	ld h,000h		;6dd4   ; HL = los puntos, un byte
	push de			;6dd6   ; guarda la posicion
	ld c,000h		;6dd7   ; C = 0: ningun digito escrito
L_6DD9:
	ld de,00064h		;6dd9   ; centenas
	call divide_resta		;6ddc   ; A = centenas
	pop de			;6ddf   ; recupera la posicion
	call cifra		;6de0   ; digito o blanco
dos_cifras:		; Pinta A y luego decenas y unidades de HL
	call pinta_digito		;6de3   ; a la VRAM
L_6DE6:
	push de			;6de6   ; guarda la posicion
	ld de,0000ah		;6de7   ; decenas
	call divide_resta		;6dea   ; A = decenas
	pop de			;6ded   ; recupera la posicion
	call cifra		;6dee   ; digito o blanco
	call pinta_digito		;6df1   ; a la VRAM
	ld a,l			;6df4   ; unidades siempre
	add a,030h		;6df5   ; las unidades, siempre
pinta_digito:		; Escribe A en la VRAM DE y avanza
	ex de,hl			;6df7   ; HL = posicion
	call escribe_vram		;6df8   ; el digito
	inc hl			;6dfb   ; posicion siguiente
	ex de,hl			;6dfc   ; DE = posicion
	ret			;6dfd
pinta_cinco_cifras_huerfano:		; Huerfano: pintaria un numero de cinco cifras (10000 y 1000 antes de 0x6DD9)
	push de			;6dfe   ; guarda la posicion
	ld c,000h		;6dff   ; C = 0: ningun digito escrito
	ld de,02710h		;6e01   ; 10000
	call divide_resta		;6e04   ; A = decenas de millar
	pop de			;6e07   ; recupera la posicion
	call cifra		;6e08   ; digito o blanco
	call pinta_digito		;6e0b   ; a la VRAM
cuatro_cifras:		; Imprime HL en cuatro cifras (millares, centenas, decenas, unidades) con los ceros de la izquierda en blanco; la entrada de cinco cifras es 0x6DFE
	push de			;6e0e   ; guarda la posicion
	ld de,003e8h		;6e0f   ; 1000
	call divide_resta		;6e12   ; A = millares
	pop de			;6e15   ; recupera la posicion
	call cifra		;6e16   ; digito o blanco
	call pinta_digito		;6e19   ; a la VRAM
	push de			;6e1c   ; guarda la posicion
	jr L_6DD9		;6e1d   ; y sigue con las tres cifras de abajo
divide_resta:		; A = HL / DE por restas, HL = resto; C cuenta las cifras no nulas
	xor a			;6e1f   ; A = 0: la cuenta
L_6E20:
	sbc hl,de		;6e20   ; HL -= DE
	jr c,L_6E28		;6e22   ; ya no cabe
	inc a			;6e24   ; una mas
	inc c			;6e25   ; C tambien
	jr L_6E20		;6e26   ; otra vez
L_6E28:
	add hl,de			;6e28   ; deshace la ultima resta
	ret			;6e29
cifra:		; Codigo ASCII de la cifra; espacio si aun no ha salido ninguna
	add a,030h		;6e2a   ; el digito
	inc c			;6e2c   ; C sin cambiar
	dec c			;6e2d
	ret nz			;6e2e   ; C no era cero: el digito
	ld a,020h		;6e2f   ; C era cero: blanco
	ret			;6e31
pinta_formacion:		; FORMATION= y la letra de la formacion (0xCB1F) en la fila 23; ? si es 0
	res 7,(hl)		;6e32   ; quita la marca de repintar
	ld c,(hl)			;6e34   ; C = formacion
	ld hl,01aefh		;6e35   ; fila 23, columna 15
	ld de,0710ah		;6e38   ; "FORMATION="
	call imprime		;6e3b   ; al rotulo
	ld a,c			;6e3e   ; A = formacion
	and a			;6e3f   ; cero?
	jr z,L_6E46		;6e40   ; cero: la letra de ninguna
	add a,040h		;6e42   ; 1 = A
	jr L_6E48		;6e44   ; a escribirla
L_6E46:
	ld a,03fh		;6e46   ; ?
L_6E48:
	jp escribe_vram		;6e48   ; la letra a la VRAM
pinta_area_si_sigue:		; Si la mitad ha acabado (0xED68 distinto de cero) no pinta nada; si no, sigue en pinta_area
	ld a,(0ed68h)		;6e4b   ; 1 = la mitad ha acabado
	and a			;6e4e   ; mitad acabada?
	ret nz			;6e4f   ; si: sin AREA=
pinta_area:		; AREA= y la zona de tiro del controlado (0xED82) en la fila 23: 1-3, o F si es 0
	res 7,(hl)		;6e50   ; quita la marca de repintar
	ld c,(hl)			;6e52   ; C = zona
	ld hl,01ae6h		;6e53   ; fila 23, columna 6
	ld de,07115h		;6e56   ; "AREA="
	call imprime		;6e59   ; al rotulo
	ld a,c			;6e5c   ; A = zona
	and a			;6e5d   ; cero?
	jr z,L_6E64		;6e5e   ; cero: la F
	add a,031h		;6e60   ; '1' + zona - 1: 1, 2 o 3
	jr L_6E66		;6e62   ; a escribirla
L_6E64:
	ld a,046h		;6e64   ; la F
L_6E66:
	jp escribe_vram		;6e66   ; a la VRAM
espera_cambio:		; Tras un rotulo espera un disparo o el tiempo; el primer disparo ofrece MEMBER CHANGE
	call lee_disparo		;6e69   ; hay disparo o espacio?
	jr nz,L_6E7D		;6e6c   ; si: a cambiar
	ld hl,(0ed7eh)		;6e6e   ; tiempo de espera
	ld a,h			;6e71   ; el temporizador a cero?
	or l			;6e72   ; sigue esperando
	jr nz,espera_cambio		;6e73
	ld a,(0ed5dh)		;6e75   ; SUPOSICION: se pidio cambio de jugadores
	and a			;6e78   ; cero: nada que cambiar
	jr nz,cambios		;6e79   ; hay cambios
	jr rehace_pista		;6e7b   ; solo rehacer la pista
L_6E7D:
	ld hl,0ed5dh		;6e7d   ; segundo disparo: cambios
	ld a,(hl)			;6e80   ; ya estaba el mensaje?
	and a			;6e81   ; si: espera
	jr nz,espera_cambio		;6e82
	inc (hl)			;6e84   ; marca que esta
	ld hl,01ae0h		;6e85   ; fila 23 con el patron 0x84
	ld bc,00020h		;6e88   ; una fila
	ld a,084h		;6e8b   ; patron 0x84
	call rellena_vram		;6e8d   ; la fila entera
	call congela_sprites		;6e90   ; sprites quietos
	ld hl,01ae9h		;6e93   ; rotulo MEMBER CHANGE
	ld de,07155h		;6e96   ; "MEMBER CHANGE."
	call imprime		;6e99   ; al rotulo
	call suelta_sprites		;6e9c   ; sprites otra vez
	jr espera_cambio		;6e9f   ; y a esperar
cambios:		; Cambio de jugadores en el descanso si algun equipo es humano; despues rehace la pista
	ld a,(0ed56h)		;6ea1   ; (0xED56): modo del equipo de la izquierda
	and a			;6ea4   ; humano?
	jr z,L_6EAC		;6ea5   ; si: rehacer
	ld a,(0ed57h)		;6ea7   ; los dos de la maquina: sin cambios
	and a			;6eaa   ; (0xED57) humano?
	ret nz			;6eab   ; los dos de la maquina: nada
L_6EAC:
	call congela_sprites		;6eac   ; sprites quietos mientras se repinta
	call logotipo		;6eaf   ; logotipo
	call monta_marcador		;6eb2   ; marcador
	call sprites_plantilla		;6eb5   ; SUPOSICION: pantalla de cambios
	call titulares_humanos		;6eb8   ; las posiciones de los dos equipos
	call borra_nombres		;6ebb   ; nombres en blanco
	call patrones_pista		;6ebe   ; patrones y colores de la pista
rehace_pista:		; Descomprime el mapa y centra la ventana
	call descomprime_mapa		;6ec1   ; el mapa de 56 columnas a 0xCB3D
	call centra_ventana		;6ec4   ; la ventana
	jp suelta_sprites		;6ec7   ; sprites otra vez
pantalla_plantilla:		; Recuadro de la plantilla: NO PLAYER FOULS FATIGUE, ocho jugadores y estadisticas
	call opcion_cero		;6eca   ; opcion a cero
	ld hl,018a0h		;6ecd   ; filas 5 a 23 en blanco
	ld bc,00260h		;6ed0   ; 0x260 bytes: 19 filas
	ld a,020h		;6ed3   ; blanco
	call rellena_vram		;6ed5   ; filas 5 a 23 borradas
	ld hl,018a1h		;6ed8   ; recuadro
	ld de,0121dh		;6edb   ; 18 filas de alto, 30 de ancho
	call cuadro		;6ede   ; el cuadro de la ficha
	ld hl,018c2h		;6ee1   ; fila 6, columna 2
	ld bc,01c0ch		;6ee4   ; 28 de barra, el nombre a 12
	call cabecera_equipo		;6ee7   ; la barra de color con el nombre
	ld a,0fah		;6eea   ; linea bajo la cabecera
	ld hl,018e2h		;6eec   ; fila 7, columna 2
	ld bc,0001ch		;6eef   ; 28 patrones
	call rellena_vram		;6ef2   ; la linea
	call rotulos_estadisticas		;6ef5   ; SKILL y STATISTICS
	ld hl,01a6fh		;6ef8   ; fila 19, columna 15
	ld bc,00403h		;6efb   ; 4 filas de 3
	ld d,08fh		;6efe   ; patron 0x8F
	call rellena_bloque		;6f00   ; el hueco de las habilidades del equipo
L_6F03:
	call cabecera_plantilla		;6f03   ; la cabecera de la plantilla (NO PLAYER FOULS FATIGUE y 1-8)
	call pinta_nombres		;6f06   ; los ocho nombres
	call pinta_en_pista		;6f09   ; quien esta en pista
	call pinta_faltas		;6f0c   ; las faltas
	jp pinta_fatiga		;6f0f   ; la fatiga, y vuelve
cabecera_plantilla:		; Lineas, cabecera NO PLAYER FOULS FATIGUE y numeros 1-8
	ld a,0fah		;6f12   ; patron 0xFA: linea
	ld hl,01a42h		;6f14   ; fila 18, columna 2
	ld bc,0001ch		;6f17   ; 28 de ancho
	call rellena_guarda		;6f1a   ; la linea de abajo
	ld a,0f4h		;6f1d   ; patron 0xF4: linea fina
	ld hl,01922h		;6f1f   ; fila 9, columna 2
	call rellena_guarda		;6f22   ; la linea bajo la cabecera
	ld de,06faah		;6f25   ; NO PLAYER FOULS FATIGUE
	ld hl,01903h		;6f28   ; fila 8, columna 3
	call imprime		;6f2b   ; NO PLAYER FOULS FATIGUE
	ld de,01944h		;6f2e   ; numeros 1 a 8 en columna
	ld hl,06feeh		;6f31   ; "12345678"
	ld bc,00801h		;6f34   ; ocho filas de un caracter
	jp copia_bloque		;6f37   ; la columna de numeros, y vuelve
rotulos_estadisticas:		; SKILL, STATISTICS, S J R y SCORE FOULS GAMES
	ld de,06fc5h		;6f3a   ; "SKILL"
	ld hl,01a76h		;6f3d   ; fila 19, columna 22
	call imprime		;6f40   ; a la VRAM
	ld de,06fcbh		;6f43   ; "STATISTICS"
	ld hl,01a63h		;6f46   ; fila 19, columna 3
	call imprime		;6f49   ; a la VRAM
	ld de,01a93h		;6f4c   ; fila 20, columna 19
	ld hl,06fd6h		;6f4f   ; "S." "J." "R."
	ld bc,00302h		;6f52   ; tres filas de dos
	call copia_bloque		;6f55   ; la columna de las habilidades
	ld de,01a83h		;6f58   ; fila 20, columna 3
	ld hl,06fdch		;6f5b   ; "SCORE:" "FOULS:" "GAMES:"
	ld bc,00306h		;6f5e   ; tres filas de seis
	call copia_bloque		;6f61   ; la columna de las estadisticas
habilidades_y_estadisticas:		; Las barras de habilidad del equipo (0x7250) en la fila 20 y los tres numeros de SCORE, FOULS y GAMES (0x72C5)
	ld hl,01a95h		;6f64   ; fila 20, columna 21
	call pinta_habilidad		;6f67   ; las barras de habilidad del equipo
	ld de,01a89h		;6f6a   ; fila 20, columna 9
	jp pinta_estadisticas		;6f6d   ; los tres numeros, y vuelve
imprime:		; Escribe en la VRAM HL la cadena DE acabada en 0
	push de			;6f70   ; guarda el principio de la cadena
L_6F71:
	ld a,(de)			;6f71   ; un caracter
	and a			;6f72   ; cero: fin
	jr nz,L_6F77		;6f73   ; sigue
	pop de			;6f75
	ret			;6f76
L_6F77:
	call escribe_vram		;6f77
	inc de			;6f7a
	inc hl			;6f7b
	jr L_6F71		;6f7c
copia_bloque:		; Copia B filas de C caracteres de HL a la VRAM DE (filas de 32)
	push bc			;6f7e
	push hl			;6f7f
L_6F80:
	push bc			;6f80
	push de			;6f81
	ld b,000h		;6f82
	push hl			;6f84
	push bc			;6f85
	call copia_a_vram		;6f86   ; una fila
	pop bc			;6f89
	pop hl			;6f8a
	add hl,bc			;6f8b   ; siguiente fila del origen
	pop de			;6f8c
	push hl			;6f8d
	ld hl,00020h		;6f8e   ; siguiente fila de la pantalla
	add hl,de			;6f91
	ex de,hl			;6f92
	pop hl			;6f93
	pop bc			;6f94
	djnz L_6F80		;6f95
	pop hl			;6f97
	pop bc			;6f98
	ret			;6f99
imprime_filas:		; Imprime B cadenas seguidas en filas sucesivas
	push bc			;6f9a
	push de			;6f9b
	push hl			;6f9c
	call imprime		;6f9d   ; una cadena
	pop hl			;6fa0
	ld de,00020h		;6fa1   ; fila siguiente
	add hl,de			;6fa4
	pop de			;6fa5
	pop bc			;6fa6
	djnz imprime_filas		;6fa7
	ret			;6fa9

; ----------------------------------------------------------------------
; DATOS textos: Los textos de los menus, acabados en cero: los imprime 0x6F70
;   caracter a caracter con 0x6122, y los bloques de filas (12345678, ELM JNR
;   HIG COL YUG ESP USA PRO, S J R) los copia 0x6F7E en filas de 32. El punto
;   es ';', el guion es '<' y la arroba es el (c)
;   0x6faa..0x7164  (442 bytes)
DATA_textos:
	defb 04eh,04fh,020h,020h,050h,04ch,041h,059h,045h,052h,020h,020h,046h,04fh,055h,04ch,053h,020h,020h,046h,041h,054h,049h,047h,055h,045h,000h	; 6faa  NO  PLAYER  FOULS  FATIGUE.
	defb 053h,04bh,049h,04ch,04ch,000h	; 6fc5
	defb 053h,054h,041h,054h,049h,053h,054h,049h,043h,053h,000h	; 6fcb  STATISTICS.
	defb 053h,03ch,04ah,03ch,052h,03ch,053h,043h,04fh,052h,045h,03ah,046h,04fh,055h,04ch,053h,03ah,047h,041h,04dh,045h,053h,03ah,031h,032h,033h,034h,035h,036h,037h,038h,045h,04ch,04dh,04ah,04eh,052h,048h,049h,047h,043h,04fh,04ch,059h,055h,047h,045h,053h,050h,055h,053h,041h,050h,052h,04fh,043h,04fh,04dh,050h,055h,054h,045h,052h,020h,054h,045h,041h,04dh,053h,000h	; 6fd6  S<J<R<SCORE:FOULS:GAMES:12345678ELMJNRHIGCOLYUGESPUSAPROCOMPUTER TEAMS.
	defb 04ch,045h,056h,045h,04ch,000h	; 701d
	defb 054h,045h,041h,04dh,000h	; 7023
	defb 04dh,041h,04bh,045h,020h,054h,045h,041h,04dh,020h,04ch,04fh,041h,044h,020h,044h,041h,054h,041h,020h,052h,045h,041h,044h,059h,03ch,04dh,041h,044h,045h,043h,04fh,04dh,050h,055h,054h,045h,052h,020h,020h,045h,044h,049h,054h,020h,054h,045h,041h,04dh,020h,053h,054h,041h,052h,054h,045h,052h,053h,000h	; 7028  MAKE TEAM LOAD DATA READY<MADECOMPUTER  EDIT TEAM STARTERS.
	defb 020h,054h,045h,041h,04dh,020h,04eh,041h,04dh,045h,03ah,020h,020h,020h,020h,020h,06bh,06bh,06bh,020h,020h,020h,020h,020h,054h,052h,041h,044h,045h,000h	; 7063   TEAM NAME:     kkk     TRADE.
	defb 04eh,041h,04dh,045h,03ah,000h	; 7081
	defb 053h,045h,054h,03ch,055h,050h,020h,020h,020h,020h,04ch,045h,046h,054h,020h,054h,045h,041h,04dh,020h,052h,049h,047h,048h,054h,020h,054h,045h,041h,04dh,054h,052h,041h,044h,045h,020h,020h,020h,020h,020h,040h,031h,039h,038h,036h,020h,048h,041h,04ch,020h,04ch,041h,042h,04fh,052h,041h,054h,04fh,052h,059h,000h	; 7087  SET<UP    LEFT TEAM RIGHT TEAMTRADE     @1986 HAL LABORATORY.
	defb 046h,03bh,04eh,041h,04bh,041h,04dh,055h,052h,041h,000h	; 70c4  F;NAKAMURA.
	defb 053h,03bh,04bh,041h,047h,041h,04dh,049h,000h	; 70cf  S;KAGAMI.
	defb 054h,045h,041h,04dh,020h,04ch,045h,056h,045h,04ch,000h	; 70d8  TEAM LEVEL.
	defb 043h,04fh,04dh,050h,055h,054h,045h,052h,020h,054h,045h,041h,04dh,000h	; 70e3  COMPUTER TEAM.
	defb 052h,045h,041h,044h,059h,03ch,04dh,041h,044h,045h,000h	; 70f1  READY<MADE.
	defb 04eh,04fh,020h,044h,045h,041h,04ch,044h,045h,041h,04ch,020h,020h,020h,046h,04fh,052h,04dh,041h,054h,049h,04fh,04eh,03dh,000h	; 70fc  NO DEALDEAL   FORMATION=.
	defb 041h,052h,045h,041h,03dh,000h	; 7115
	defb 04ch,04fh,041h,044h,020h,044h,041h,054h,041h,03bh,000h	; 711b  LOAD DATA;.
	defb 053h,041h,056h,045h,020h,044h,041h,054h,041h,03bh,000h	; 7126  SAVE DATA;.
	defb 056h,045h,052h,049h,046h,059h,03bh,000h	; 7131  VERIFY;.
	defb 053h,055h,052h,045h,03fh,000h	; 7139
	defb 020h,020h,020h,045h,052h,052h,04fh,052h,03eh,020h,020h,020h,000h	; 713f     ERROR>   .
	defb 020h,046h,04fh,055h,04eh,044h,03ah,020h,000h	; 714c   FOUND: .
	defb 04dh,045h,04dh,042h,045h,052h,020h,043h,048h,041h,04eh,047h,045h,03eh,000h	; 7155  MEMBER CHANGE>.

; ======================================================================
; CODIGO 0x7164..0x7439  (725 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Pantallas de plantilla y SET-UP =====
; ----------------------------------------------------------------------
rellena_bloque:		; B filas de C bytes con D desde la VRAM HL
	push bc			;7164
L_7165:
	push bc			;7165
	ld a,d			;7166   ; caracter
	ld b,000h		;7167
	call rellena_vram		;7169   ; una fila de C
	ld bc,00020h		;716c   ; siguiente fila
	add hl,bc			;716f
	pop bc			;7170
	djnz L_7165		;7171
	pop bc			;7173
	ret			;7174
rellena_guarda:		; Rellena la VRAM conservando A y BC
	push af			;7175
	push bc			;7176
	call rellena_vram		;7177   ; conserva A y BC
	pop bc			;717a
	pop af			;717b
	ret			;717c
cuadro_guarda:		; Cuadro de 0x7316 conservando DE
	push de			;717d
	call cuadro		;717e
	pop de			;7181
	ret			;7182
campo_jugador:		; HL = campo C del jugador (0xED4D) & 7 del roster del equipo (bit 7)
	ld a,(0ed4dh)		;7183
	ld hl,0c61bh		;7186   ; jugadores del roster izquierdo
	bit 7,a		;7189
	jr z,L_7190		;718b
	ld hl,0c707h		;718d   ; jugadores del roster derecho
L_7190:
	push bc			;7190
	ld b,000h		;7191
	add hl,bc			;7193
	and 007h		;7194
	jr z,L_71A1		;7196
	ld b,a			;7198
	push de			;7199
	ld de,0001dh		;719a   ; 29 bytes por jugador
L_719D:
	add hl,de			;719d
	djnz L_719D		;719e
	pop de			;71a0
L_71A1:
	pop bc			;71a1
	ret			;71a2
campo_cabecera:		; HL = byte C de la cabecera del roster (nombre y nivel) del equipo de (0xED4D)
	ld a,(0ed4dh)		;71a3
	ld hl,0c617h		;71a6
	bit 7,a		;71a9
	jr z,L_71B0		;71ab
	ld hl,0c703h		;71ad
L_71B0:
	push bc			;71b0
	ld b,000h		;71b1
	add hl,bc			;71b3
	pop bc			;71b4
	ret			;71b5
campo_equipo:		; HL = cuenta C del equipo de (0xED4D) en 0xC7EF o 0xC81F
	ld a,(0ed4dh)		;71b6
	ld hl,0c7efh		;71b9
	bit 7,a		;71bc
	jr z,L_71C3		;71be
	ld hl,0c81fh		;71c0
L_71C3:
	push bc			;71c3
	ld b,000h		;71c4
	add hl,bc			;71c6
	pop bc			;71c7
	ret			;71c8
modo_equipo:		; HL = modo del equipo de (0xED4D): 0xED56 o 0xED57
	ld a,(0ed4dh)		;71c9
	ld hl,0ed56h		;71cc   ; modo del izquierdo
	bit 7,a		;71cf   ; equipo derecho?
	ret z			;71d1
	inc hl			;71d2   ; modo del derecho
	ret			;71d3
pinta_nombres:		; Nombres de los ocho jugadores en la columna 6 desde la fila 10
	ld a,(0ed4dh)		;71d4
	push af			;71d7
	and 080h		;71d8
	ld (0ed4dh),a		;71da
	ld c,000h		;71dd
	call campo_jugador		;71df
	ld de,01946h		;71e2   ; fila 10, columna 6
	ld b,008h		;71e5
L_71E7:
	push bc			;71e7
	push de			;71e8
	ld bc,00008h		;71e9   ; 8 caracteres
	push hl			;71ec
	push bc			;71ed
	call copia_a_vram		;71ee   ; nombre a la pantalla
	pop bc			;71f1
	pop hl			;71f2
	ld de,0001dh		;71f3   ; siguiente jugador del roster
	add hl,de			;71f6
	pop de			;71f7
	push hl			;71f8
	ld hl,00020h		;71f9   ; siguiente fila
	add hl,de			;71fc
	ex de,hl			;71fd
	pop hl			;71fe
	pop bc			;71ff
	djnz L_71E7		;7200
	pop af			;7202
	ld (0ed4dh),a		;7203   ; equipo de antes
	ret			;7206
pinta_faltas:		; Columna FOULS: cinco casillas 0x6E con una marca 0x6F por falta personal
	ld hl,0194fh		;7207
	ld bc,00805h		;720a   ; 8 filas de 5
	ld d,06eh		;720d
	call rellena_bloque		;720f
	ld c,018h		;7212   ; faltas personales de cada jugador
	call campo_equipo		;7214
	ex de,hl			;7217
	ld b,008h		;7218
	ld hl,0194fh		;721a
L_721D:
	ld a,(de)			;721d   ; faltas del jugador
	and a			;721e
	jr z,L_722B		;721f
	push bc			;7221
	ld c,a			;7222
	ld b,000h		;7223
	ld a,06fh		;7225   ; marca de falta
	call rellena_vram		;7227
	pop bc			;722a
L_722B:
	push de			;722b
	ld de,00020h		;722c   ; siguiente fila
	add hl,de			;722f
	pop de			;7230
	inc de			;7231   ; siguiente jugador
	djnz L_721D		;7232
	ret			;7234
pinta_en_pista:		; Marca 0x73 en los jugadores en pista y 0x72 en los del banquillo
	ld c,007h		;7235   ; mascara de jugadores en pista
	call campo_equipo		;7237
	ld c,(hl)			;723a
	ld b,008h		;723b
	ld hl,01943h		;723d
	ld de,00020h		;7240
L_7243:
	ld a,072h		;7243   ; bit del jugador
	rr c		;7245
	adc a,000h		;7247
	call escribe_vram		;7249
	add hl,de			;724c
	djnz L_7243		;724d
	ret			;724f
pinta_habilidad:		; Tres barras de habilidad del jugador (campos 0x10, 0x13, 0x16) si el bit 6 de 0xED4D lo pide
	push hl			;7250
	ld a,(0ed4dh)		;7251
	push af			;7254
	ld d,0b6h		;7255   ; fondo de la barra
	bit 6,a		;7257
	jr z,L_725C		;7259
	inc d			;725b
L_725C:
	ld bc,00308h		;725c   ; 3 filas de 8
	call rellena_bloque		;725f
	pop af			;7262
	bit 6,a		;7263
	jr nz,L_7269		;7265
	pop hl			;7267
	ret			;7268
L_7269:
	ld c,00fh		;7269   ; campo 0x0F
	call campo_jugador		;726b
	inc hl			;726e   ; primera habilidad (0x10)
	ex de,hl			;726f
	pop hl			;7270
	call barra		;7271   ; barra 1
	inc de			;7274   ; tres bytes mas: campo 0x13
	inc de			;7275
	inc de			;7276
	call barra		;7277   ; barra 2
	inc de			;727a   ; campo 0x16: barra 3
	inc de			;727b
	inc de			;727c
barra:		; Barra del valor (DE)/4: bloques llenos 0xBF por cada 8 y un final 0xB7-0xBE
	push bc			;727d
	ld a,(de)			;727e   ; valor
	srl a		;727f   ; entre 4
	srl a		;7281
	ld c,a			;7283
	srl a		;7284   ; entre 32: bloques llenos
	srl a		;7286
	srl a		;7288
	ld b,a			;728a
	push hl			;728b
	and a			;728c
	jr z,L_7297		;728d   ; ninguno lleno
L_728F:
	ld a,0bfh		;728f   ; bloque lleno
	call escribe_vram		;7291
	inc hl			;7294
	djnz L_728F		;7295
L_7297:
	ld a,c			;7297   ; bloque final segun el resto
	and 007h		;7298
	add a,0b7h		;729a
	call escribe_vram		;729c
	pop hl			;729f
	ld bc,00020h		;72a0
	add hl,bc			;72a3
	pop bc			;72a4
	ret			;72a5
pinta_fatiga:		; Barras de FATIGUE de los ocho jugadores (byte alto del cansancio)
	ld hl,01955h		;72a6
	ld bc,00808h		;72a9
	ld d,0b7h		;72ac
	call rellena_bloque		;72ae
	ld c,020h		;72b1   ; cansancio de los ocho
	call campo_equipo		;72b3
	inc hl			;72b6
	ex de,hl			;72b7
	ld hl,01955h		;72b8
	ld b,008h		;72bb
L_72BD:
	call barra		;72bd
	inc de			;72c0
	inc de			;72c1
	djnz L_72BD		;72c2
	ret			;72c4
pinta_estadisticas:		; Tres contadores de 16 bits del jugador (campo 9) en cuatro cifras
	ld c,009h		;72c5
	call campo_jugador		;72c7
	ld b,003h		;72ca
L_72CC:
	push bc			;72cc
	ld c,(hl)			;72cd   ; contador de 16 bits
	inc hl			;72ce
	ld b,(hl)			;72cf
	inc hl			;72d0
	push hl			;72d1
	push de			;72d2
	ld h,b			;72d3
	ld l,c			;72d4
	ld c,000h		;72d5
	call cuatro_cifras		;72d7   ; cuatro cifras
	pop de			;72da
	ld hl,00020h		;72db   ; fila siguiente
	add hl,de			;72de
	ex de,hl			;72df
	pop hl			;72e0
	pop bc			;72e1
	djnz L_72CC		;72e2
	ret			;72e4
cabecera_equipo:		; Franja del equipo (0xB0 izquierdo, 0xB3 derecho), sus extremos y el nombre
	ld d,0b0h		;72e5
	ld a,(0ed4dh)		;72e7
	bit 7,a		;72ea
	jr z,L_72F0		;72ec
	ld d,0b3h		;72ee
L_72F0:
	ld a,d			;72f0   ; franja del equipo
	push bc			;72f1
	ld c,b			;72f2
	ld b,000h		;72f3
	call rellena_vram		;72f5   ; B caracteres
	pop bc			;72f8
	ld b,000h		;72f9
	add hl,bc			;72fb
	inc d			;72fc   ; extremo izquierdo
	ld a,d			;72fd
	call escribe_vram		;72fe
	inc hl			;7301
	inc hl			;7302
	inc hl			;7303
	inc hl			;7304
	inc d			;7305   ; extremo derecho
	ld a,d			;7306
	call escribe_vram		;7307
	dec hl			;730a
	dec hl			;730b
	dec hl			;730c
	ex de,hl			;730d
	ld c,000h		;730e
	call campo_cabecera		;7310   ; nombre del equipo
	jp copia_tres		;7313
cuadro:		; Cuadro de D filas y E+1 de ancho: esquinas, lados y bordes
	push hl			;7316
	ld a,0f5h		;7317   ; esquina superior izquierda
	call escribe_vram		;7319
	ld a,0f7h		;731c   ; borde superior
	call linea		;731e
	ld a,0f6h		;7321   ; esquina superior derecha
	call escribe_vram		;7323
	ld h,000h		;7326
	ld l,d			;7328
	add hl,hl			;7329
	add hl,hl			;732a
	add hl,hl			;732b
	add hl,hl			;732c
	add hl,hl			;732d
	pop bc			;732e
	push bc			;732f
	add hl,bc			;7330
	ld a,062h		;7331   ; esquina inferior izquierda
	call escribe_vram		;7333
	ld a,065h		;7336   ; borde inferior
	call linea		;7338
	ld a,063h		;733b   ; esquina inferior derecha
	call escribe_vram		;733d
	pop hl			;7340
	ld bc,00020h		;7341
	add hl,bc			;7344
	push hl			;7345
	ld c,066h		;7346   ; lado izquierdo
	call columna		;7348
	pop hl			;734b
	ld b,000h		;734c
	ld c,e			;734e
	add hl,bc			;734f
	ld c,067h		;7350   ; lado derecho
columna:		; B-1 veces el caracter C hacia abajo
	ld b,d			;7352
	dec b			;7353
L_7354:
	ld a,c			;7354   ; caracter del lado
	call escribe_vram		;7355
	push de			;7358
	ld de,00020h		;7359   ; fila siguiente
	add hl,de			;735c
	pop de			;735d
	djnz L_7354		;735e
	ret			;7360
linea:		; E caracteres A a la derecha de HL
	inc hl			;7361
	ld b,000h		;7362   ; E caracteres
	ld c,e			;7364
	push bc			;7365
	call rellena_vram		;7366   ; rellena
	pop bc			;7369
	dec hl			;736a
	add hl,bc			;736b   ; al final de la linea
	ret			;736c
sprites_plantilla:		; Pose 0x90 del jugador 0 en la VRAM y dos grupos de cuatro sprites para mostrar a los jugadores
	xor a			;736d
	call registro_jugador		;736e
	ld (0ecech),hl		;7371
	ld de,0000dh		;7374
	add hl,de			;7377
	ld (hl),090h		;7378   ; pose 0x90: de frente
	call sube_patrones_pose		;737a   ; sus patrones a 0x3800
patrones_plantilla:		; Numeros de patron de los dos grupos de sprites de la plantilla y Y 0xC0
	xor a			;737d
	ld hl,(0f928h)		;737e   ; tabla de atributos visible
	inc hl			;7381
	inc hl			;7382
	ld b,004h		;7383   ; patrones 0, 4, 8, 12
	ld de,00004h		;7385
L_7388:
	push af			;7388
	call escribe_vram		;7389
	pop af			;738c
	add a,e			;738d
	add hl,de			;738e
	djnz L_7388		;738f
	xor a			;7391   ; y el segundo grupo igual
	ld b,004h		;7392
L_7394:
	push af			;7394
	call escribe_vram		;7395
	pop af			;7398
	add a,e			;7399
	add hl,de			;739a
	djnz L_7394		;739b
	ld a,0c0h		;739d   ; Y 0xC0: ocultos de momento
	ld b,008h		;739f
	ld hl,01b00h		;73a1
L_73A4:
	push af			;73a4
	call escribe_vram		;73a5
	pop af			;73a8
	add hl,de			;73a9
	djnz L_73A4		;73aa
	ld a,0d0h		;73ac   ; fin de la lista de sprites
	jp escribe_vram		;73ae
viste_jugador:		; Colores del grupo de sprites del jugador de (0xED4D) y su colocacion en DE
	push bc			;73b1
	ld c,003h		;73b2
	call campo_equipo		;73b4   ; color del equipo
	ld a,(hl)			;73b7
	and 0f0h		;73b8
	rra			;73ba
	rra			;73bb
	rra			;73bc
	rra			;73bd
	ld c,00fh		;73be   ; camiseta en el sprite 3
	call atributo_plantilla		;73c0
	call escribe_vram		;73c3
	ld c,008h		;73c6   ; aspecto del jugador
	call campo_jugador		;73c8
	ld a,(hl)			;73cb
	add a,a			;73cc
	ld l,a			;73cd
	ld h,000h		;73ce
	ld de,07439h		;73d0
	add hl,de			;73d3
	ld a,(hl)			;73d4
	push hl			;73d5
	ld c,003h		;73d6
	call atributo_plantilla		;73d8   ; piel en los sprites 0 y 1
	push af			;73db
	call escribe_vram		;73dc
	ld de,00004h		;73df
	add hl,de			;73e2
	pop af			;73e3
	call escribe_vram		;73e4
	pop hl			;73e7
	inc hl			;73e8
	ld a,(hl)			;73e9
	ld c,00bh		;73ea   ; pelo en el sprite 2
	call atributo_plantilla		;73ec
	call escribe_vram		;73ef
	ld a,090h		;73f2   ; colocacion de la pose 0x90
	srl a		;73f4
	srl a		;73f6
	ld l,a			;73f8
	ld h,000h		;73f9
	add hl,hl			;73fb
	add hl,hl			;73fc
	add hl,hl			;73fd
	ld de,0aa24h		;73fe
	add hl,de			;7401
	push hl			;7402
	pop ix		;7403
	ld c,000h		;7405
	call atributo_plantilla		;7407
	pop de			;740a
	ld b,004h		;740b
L_740D:
	ld a,d			;740d
	sub (ix+000h)		;740e   ; Y menos dy
	call escribe_vram		;7411
	inc ix		;7414
	inc hl			;7416
	ld a,e			;7417
	sub (ix+000h)		;7418   ; X menos dx
	call escribe_vram		;741b
	inc ix		;741e
	inc hl			;7420
	inc hl			;7421
	inc hl			;7422
	djnz L_740D		;7423
	ret			;7425
atributo_plantilla:		; HL = 0x1B00 (izquierdo) o 0x1B10 (derecho) mas C
	push af			;7426
	ld a,(0ed4dh)		;7427   ; equipo
	ld hl,01b00h		;742a   ; sprites del izquierdo
	bit 7,a		;742d
	jr z,L_7434		;742f
	ld hl,01b10h		;7431   ; sprites del derecho
L_7434:
	ld b,000h		;7434
	add hl,bc			;7436
	pop af			;7437
	ret			;7438

; ----------------------------------------------------------------------
; DATOS colores_equipo: 32 parejas de colores (piel, camiseta): la piel
;   recorre 0x0B, 0x0A y 0x01 y la camiseta once colores; 0x73B1 pinta la
;   pareja del equipo (hl) con 0x7426 y 0x6122
;   0x7439..0x7479  (64 bytes)
DATA_colores_equipo:
	defb 00bh,001h	; 7439
	defb 00ah,001h	; 743b
	defb 001h,00ah	; 743d
	defb 00bh,00dh	; 743f
	defb 00ah,00dh	; 7441
	defb 001h,00dh	; 7443
	defb 00bh,009h	; 7445
	defb 00ah,009h	; 7447
	defb 001h,009h	; 7449
	defb 00bh,003h	; 744b
	defb 00ah,003h	; 744d
	defb 001h,003h	; 744f
	defb 00bh,007h	; 7451
	defb 00ah,007h	; 7453
	defb 001h,007h	; 7455
	defb 00bh,008h	; 7457
	defb 00ah,008h	; 7459
	defb 001h,008h	; 745b
	defb 00bh,002h	; 745d
	defb 00ah,002h	; 745f
	defb 001h,002h	; 7461
	defb 00bh,005h	; 7463
	defb 00ah,005h	; 7465
	defb 001h,005h	; 7467
	defb 00bh,006h	; 7469
	defb 00ah,006h	; 746b
	defb 001h,006h	; 746d
	defb 00bh,00ch	; 746f
	defb 00ah,00ch	; 7471
	defb 001h,00ch	; 7473
	defb 00bh,004h	; 7475
	defb 00ah,004h	; 7477

; ======================================================================
; CODIGO 0x7479..0x7f48  (2767 bytes)
; ======================================================================


borra_rotulo:		; Dos filas de 12 espacios en 0x1831
	ld hl,01831h		;7479
	ld bc,0020ch		;747c
	ld d,020h		;747f
	jp rellena_bloque		;7481

; ----------------------------------------------------------------------
; ===== SET-UP, titulo y menus de equipo =====
; ----------------------------------------------------------------------
pantalla_setup:		; Pantalla SET-UP: START, STARTERS, cambio de lados, de colores, LENGTH OF HALF y COLOR OF COURT; acarreo = ESC
	call patrones_plantilla		;7484
	call fondo_setup		;7487   ; fondo de la pantalla (0xB8C0)
	call opcion_cero		;748a   ; opcion 0
setup_repinta:		; Nombres, marcas de LENGTH y de COLOR OF COURT
	call nombres_setup		;748d   ; nombres de los equipos
	call marca_length		;7490   ; marca de LENGTH OF HALF
	call marca_court		;7493   ; marca de COLOR OF COURT
setup_menu:		; Selector de seis opciones con el cursor 0x6F en la columna 8
	ld hl,01a28h		;7496   ; cursor en 0x1A28
	ld bc,0066fh		;7499   ; seis opciones, cursor 0x6F
	call selector		;749c
	ld a,c			;749f
	cp 01bh		;74a0   ; ESC: vuelve al menu
	jr z,setup_esc		;74a2
	cp 020h		;74a4   ; espacio: elige
	jr z,L_74D5		;74a6
	cp 01ch		;74a8   ; cursor derecha
	jr z,L_74B0		;74aa
	cp 01dh		;74ac   ; cursor izquierda
	jr nz,setup_menu		;74ae
L_74B0:
	ld a,e			;74b0
	cp 002h		;74b1   ; opcion 2: cambia los equipos de lado
	jr nz,L_74BA		;74b3
	call cambia_lados		;74b5
	jr setup_repinta		;74b8
L_74BA:
	cp 003h		;74ba   ; opcion 3: cambia los colores
	jr nz,L_74C3		;74bc
	call cambia_colores		;74be
	jr setup_menu		;74c1
L_74C3:
	cp 004h		;74c3   ; opcion 4: LENGTH OF HALF
	jr nz,L_74CC		;74c5
	call cambia_length		;74c7
	jr setup_repinta		;74ca
L_74CC:
	cp 005h		;74cc   ; opcion 5: COLOR OF COURT
	jr nz,setup_menu		;74ce
	call cambia_court		;74d0
	jr setup_repinta		;74d3
L_74D5:
	ld a,e			;74d5   ; opcion 0: START
	and a			;74d6
	jr nz,L_74DE		;74d7
	call inicia_reloj_partido		;74d9   ; primera mitad y reloj
	and a			;74dc   ; sin acarreo: a jugar
	ret			;74dd
L_74DE:
	cp 001h		;74de   ; opcion 1: STARTERS
	jr nz,setup_menu		;74e0
	call pantalla_starters		;74e2
	jr pantalla_setup		;74e5
setup_esc:		; Acarreo: vuelta al menu del titulo
	scf			;74e7
	ret			;74e8
fondo_setup:		; Descomprime el fondo del SET-UP (0xB8C0) y lo copia a la tabla de nombres
	ld hl,0b8c0h		;74e9   ; fondo comprimido
	ld de,0cb3dh		;74ec
	call descomprime_rep		;74ef   ; solo repeticiones
	ld hl,0cb3dh		;74f2
	ld de,01800h		;74f5   ; tabla de nombres entera
	ld bc,00300h		;74f8
	jp copia_a_vram		;74fb
nombres_setup:		; Nombres de los dos equipos en 0x18C7 y 0x18D6
	ld hl,0c617h		;74fe   ; nombre del izquierdo
	ld de,018c7h		;7501
	call copia_tres		;7504
	ld hl,0c703h		;7507   ; nombre del derecho
	ld de,018d6h		;750a
	jp copia_tres		;750d
marca_length:		; Borra las cuatro marcas y pone 0xF9 en la de LENGTH OF HALF
	ld b,004h		;7510   ; cuatro casillas de 4 en 4
	ld hl,0194bh		;7512
	ld de,00004h		;7515
L_7518:
	ld a,020h		;7518
	call escribe_vram		;751a
	add hl,de			;751d
	djnz L_7518		;751e
	ld de,0194bh		;7520
	ld a,(0ed5ah)		;7523   ; LENGTH OF HALF por 4
	add a,a			;7526
	add a,a			;7527
pon_marca:		; Marca 0xF9 en DE + desplazamiento
	ld l,a			;7528
	ld h,000h		;7529
	add hl,de			;752b
	ld a,0f9h		;752c
	jp escribe_vram		;752e
marca_court:		; Borra las tres marcas y pone la de COLOR OF COURT
	ld b,003h		;7531   ; tres casillas de 5 en 5
	ld hl,0198ch		;7533
	ld de,00005h		;7536
L_7539:
	ld a,020h		;7539   ; borra la casilla
	call escribe_vram		;753b
	add hl,de			;753e
	djnz L_7539		;753f   ; tres casillas
	ld de,0198ch		;7541   ; primera casilla
	ld a,(0ed5bh)		;7544   ; COLOR OF COURT por 5
	ld b,a			;7547
	add a,a			;7548
	add a,a			;7549
	add a,b			;754a
	jr pon_marca		;754b
cambia_lados:		; Intercambia los modos y los rosters (0xEC bytes) de los dos equipos
	ld hl,0ed56h		;754d   ; modos de los dos equipos
	ld a,(hl)			;7550
	inc hl			;7551
	ld b,(hl)			;7552
	ld (hl),a			;7553
	dec hl			;7554
	ld (hl),b			;7555
	ld hl,0c617h		;7556   ; roster izquierdo
	ld de,0c703h		;7559   ; roster derecho
	ld bc,000ech		;755c   ; 236 bytes
intercambia_bloque:		; Intercambia BC bytes entre HL y DE
	ld a,(hl)			;755f   ; byte de HL
	push af			;7560
	ld a,(de)			;7561   ; el de DE a HL
	ld (hl),a			;7562
	pop af			;7563
	ld (de),a			;7564   ; el de HL a DE
	inc de			;7565
	inc hl			;7566
	dec bc			;7567   ; cuenta de bytes
	ld a,b			;7568
	or c			;7569
	jr nz,intercambia_bloque		;756a
	ret			;756c
cambia_colores:		; Intercambia los colores de los equipos y repinta sus franjas
	ld hl,0c7f2h		;756d   ; color del izquierdo
	ld de,0c822h		;7570   ; color del derecho
	ld b,(hl)			;7573
	ld a,(de)			;7574
	ld (hl),a			;7575
	ld a,b			;7576
	ld (de),a			;7577
pinta_franjas:		; Franjas de color de los dos equipos (24 bytes de color en 0x2580 y 0x2598)
	ld hl,02580h		;7578
	ld bc,00018h		;757b
	ld a,(0c7f2h)		;757e   ; color del izquierdo
	call rellena_guarda		;7581
	ld hl,02598h		;7584
	ld a,(0c822h)		;7587   ; color del derecho
	jp rellena_guarda		;758a
cambia_length:		; LENGTH OF HALF mas o menos uno (0-3) segun la tecla
	ld a,(0ed5ah)		;758d
	ld b,a			;7590
	ld a,c			;7591
	cp 01ch		;7592   ; derecha: uno mas
	jr nz,L_7599		;7594
	inc b			;7596
	jr L_759A		;7597
L_7599:
	dec b			;7599
L_759A:
	ld a,b			;759a
	and 003h		;759b   ; da la vuelta en 4
	ld (0ed5ah),a		;759d
	ret			;75a0
cambia_court:		; COLOR OF COURT mas o menos uno (0-2) y los colores de equipo de esa pista (0x6BAE)
	ld a,(0ed5bh)		;75a1   ; COLOR OF COURT
	ld b,a			;75a4
	ld a,c			;75a5
	cp 01ch		;75a6   ; derecha?
	jr nz,L_75AD		;75a8
	inc b			;75aa   ; uno mas
	jr L_75AE		;75ab
L_75AD:
	dec b			;75ad
L_75AE:
	ld a,b			;75ae
	cp 003h		;75af   ; paso de 2 a 0
	jr z,L_75BB		;75b1
	cp 0ffh		;75b3
	jr nz,L_75BC		;75b5
	ld a,002h		;75b7   ; paso de 0 a 2
	jr L_75BC		;75b9
L_75BB:
	xor a			;75bb
L_75BC:
	ld (0ed5bh),a		;75bc
	add a,a			;75bf
	add a,a			;75c0
	ld l,a			;75c1
	ld h,000h		;75c2
	ld de,06baeh		;75c4   ; colores de equipo de la pista
	add hl,de			;75c7
	ld a,(hl)			;75c8
	ld (0c7f2h),a		;75c9   ; color del izquierdo
	inc hl			;75cc
	ld a,(hl)			;75cd
	ld (0c822h),a		;75ce   ; color del derecho
	jp pinta_franjas		;75d1
pantalla_starters:		; STARTERS: cada equipo humano elige sus tres titulares
	call borra_nombres		;75d4
	ld hl,0180bh		;75d7   ; franjas de los rotulos
	ld bc,0000ah		;75da
	ld a,0fah		;75dd
	call rellena_guarda		;75df
	ld hl,0184bh		;75e2
	call rellena_guarda		;75e5
	ld hl,0182ch		;75e8   ; STARTERS
	ld de,0705ah		;75eb
	call imprime		;75ee
titulares_humanos:		; Cada equipo de modo 0 elige sus titulares; despues sprites y registros
	xor a			;75f1
	ld (0ed4dh),a		;75f2   ; equipo izquierdo
	ld a,(0ed56h)		;75f5   ; modo 0: elige sus titulares
	and a			;75f8
	jr nz,L_7601		;75f9
	call pantalla_plantilla		;75fb
	call elige_titulares		;75fe
L_7601:
	call patrones_plantilla		;7601
	ld hl,0ed4dh		;7604   ; equipo derecho
	set 7,(hl)		;7607
	ld a,(0ed57h)		;7609
	and a			;760c
	jr nz,L_7615		;760d
	call pantalla_plantilla		;760f
	call elige_titulares		;7612
L_7615:
	call sprites_plantilla		;7615
	jp jugadores_en_pista		;7618   ; titulares a los registros
elige_titulares:		; Cursor sobre los ocho jugadores: espacio pone o quita, izquierda/derecha cambian de vista; ESC con tres titulares
	call 00156h		;761b   ; BIOS KILBUF - Clears keyboard buffer
	call opcion_cero		;761e
	ld hl,0ed4dh		;7621   ; sin barras de habilidad
	res 6,(hl)		;7624
titulares_muestra:		; Viste el sprite del jugador del cursor
	ld bc,0b483h		;7626
	call viste_jugador		;7629
titulares_pinta:		; Marcas de titular
	call habilidades_y_estadisticas		;762c
	call pinta_en_pista		;762f
titulares_menu:		; Selector de los ocho jugadores
	ld bc,008f9h		;7632   ; ocho opciones, cursor 0xF9
	ld hl,01942h		;7635
	call selector		;7638
	cp 01bh		;763b   ; ESC
	jr z,titulares_fin		;763d
	cp 020h		;763f   ; espacio: pone o quita
	jr z,L_7658		;7641
	cp 01eh		;7643   ; arriba
	jr z,titulares_muestra		;7645
	cp 01fh		;7647   ; abajo
	jr z,titulares_muestra		;7649
	cp 01ch		;764b   ; derecha
	jr z,L_7653		;764d
	cp 01dh		;764f   ; izquierda
	jr nz,titulares_menu		;7651
L_7653:
	call cambia_vista		;7653   ; cambia de vista
	jr titulares_pinta		;7656
L_7658:
	call alterna_titular		;7658
	jr titulares_muestra		;765b
titulares_fin:		; Solo sale con exactamente tres titulares
	ld c,007h		;765d   ; mascara de titulares
	call campo_equipo		;765f
	ld a,(hl)			;7662
	call cuenta_titulares		;7663
	jr nz,titulares_menu		;7666
	ret			;7668
cambia_vista:		; Invierte el bit 6 de 0xED4D: barras de habilidad o estadisticas
	ld a,(0ed4dh)		;7669
	bit 6,a		;766c
	jr z,L_7674		;766e
	res 6,a		;7670
	jr L_7676		;7672
L_7674:
	set 6,a		;7674
L_7676:
	ld (0ed4dh),a		;7676
	ret			;7679
alterna_titular:		; Pone o quita al jugador E de la mascara de titulares; con 5 faltas no entra
	push de			;767a
	ld c,007h		;767b   ; mascara de titulares
	call campo_equipo		;767d
	pop de			;7680
	ld b,e			;7681
	call bit_de		;7682   ; bit del jugador
	ld c,a			;7685
	push bc			;7686
	push hl			;7687
	ld c,018h		;7688   ; faltas personales
	call campo_equipo		;768a
	ld d,000h		;768d
	add hl,de			;768f
	ld a,(hl)			;7690
	cp 005h		;7691   ; expulsado: fuera
	pop hl			;7693
	pop bc			;7694
	jr nc,quita_titular		;7695
	ld a,(hl)			;7697   ; ya era titular: lo quita
	and c			;7698
	jr nz,quita_titular		;7699
	ld a,(hl)			;769b
	or c			;769c
	call cuenta_titulares		;769d   ; con el cuenta mas de tres?
	jr z,L_76A8		;76a0
	jr c,L_76A8		;76a2
	ret			;76a4
quita_titular:		; Quita el bit C de la mascara
	ld a,c			;76a5
	cpl			;76a6
	and (hl)			;76a7
L_76A8:
	ld (hl),a			;76a8
	ret			;76a9
cuenta_titulares:		; C = bits a 1 de A; Z si son tres, acarreo si menos
	ld d,a			;76aa
	ld c,000h		;76ab
	ld b,008h		;76ad
L_76AF:
	rra			;76af
	jr nc,L_76B3		;76b0
	inc c			;76b2
L_76B3:
	djnz L_76AF		;76b3
	ld a,c			;76b5
	cp 003h		;76b6
	ld a,d			;76b8
	ret			;76b9
bit_de:		; A = 1 desplazado B veces
	ld a,001h		;76ba
	inc b			;76bc
	dec b			;76bd
	ret z			;76be
L_76BF:
	sla a		;76bf
	djnz L_76BF		;76c1
	ret			;76c3
fondo_titulo:		; Fondo del titulo (0xB794) y nombres de los dos equipos
	call borra_nombres		;76c4
	ld hl,0b794h		;76c7   ; fondo comprimido
	ld de,0cb3dh		;76ca
	call descomprime_rep		;76cd
	ld hl,0cb3dh		;76d0
	ld de,01800h		;76d3
	ld bc,00220h		;76d6   ; 17 filas
	call copia_a_vram		;76d9
	ld hl,0c617h		;76dc   ; nombre del equipo izquierdo
	ld de,019e7h		;76df
	call copia_tres		;76e2
	ld hl,0c703h		;76e5   ; nombre del equipo derecho
	ld de,019f6h		;76e8
copia_tres:		; Copia los tres caracteres de HL a la VRAM DE (nombre de equipo)
	ld bc,00003h		;76eb
	jp copia_a_vram		;76ee
pantalla_titulo:		; Titulo: fondo, copyright de HAL y los dos creditos
	call fondo_titulo		;76f1
	ld hl,01a66h		;76f4   ; @1986 HAL LABORATORY
	ld de,070afh		;76f7
	call imprime		;76fa
	ld hl,01aabh		;76fd   ; F;NAKAMURA
	ld de,070c4h		;7700
	call imprime		;7703
	ld hl,01acbh		;7706   ; S;KAGAMI (la primera version decia S;MIRROR)
	ld de,070cfh		;7709
	jp imprime		;770c
menu_titulo:		; Menu del titulo: SET-UP, LEFT TEAM, RIGHT TEAM y TRADE
	xor a			;770f
	ld hl,0c7f3h		;7710   ; cuentas del equipo izquierdo a cero
	ld b,02ch		;7713
L_7715:
	ld (hl),a			;7715
	inc hl			;7716
	djnz L_7715		;7717
	ld hl,0c823h		;7719   ; cuentas del equipo derecho a cero
	ld b,02ch		;771c
L_771E:
	ld (hl),a			;771e
	inc hl			;771f
	djnz L_771E		;7720
	call sprites_plantilla		;7722
	call fondo_titulo		;7725
	ld hl,01a48h		;7728   ; cuadro del menu
	ld de,0050fh		;772b
	call cuadro		;772e
	ld hl,07087h		;7731   ; SET-UP, LEFT TEAM, RIGHT TEAM, TRADE
	ld de,01a6bh		;7734
	ld bc,0040ah		;7737
	call copia_bloque		;773a
	call opcion_cero		;773d
suelta_espacio:		; Espera a soltar el espacio
	xor a			;7740
	call 000d8h		;7741   ; BIOS GTTRIG - Returns current trigger status
	jr nz,suelta_espacio		;7744
	call 00156h		;7746   ; BIOS KILBUF - Clears keyboard buffer
menu_titulo_elige:		; Selector de cuatro opciones; solo vale el espacio
	ld hl,01a6ah		;7749
	ld bc,0046fh		;774c   ; cuatro opciones, cursor 0x6F
	call selector		;774f
	ld a,c			;7752
	cp 020h		;7753
	jr nz,menu_titulo_elige		;7755
	ld a,e			;7757
	and a			;7758
	jr z,titulares_por_defecto		;7759   ; SET-UP
	cp 001h		;775b   ; LEFT TEAM
	jr nz,L_7768		;775d
	xor a			;775f
L_7760:
	ld (0ed4dh),a		;7760
	call menu_equipo		;7763   ; menu del equipo
	jr menu_titulo		;7766
L_7768:
	cp 002h		;7768   ; RIGHT TEAM
	jr nz,L_7770		;776a
	ld a,080h		;776c
	jr L_7760		;776e
L_7770:
	call trade		;7770   ; TRADE
	jr menu_titulo		;7773
titulares_por_defecto:		; Titulares 0, 1 y 2 en los dos equipos y a la pantalla SET-UP
	ld a,007h		;7775
	ld (0c7f6h),a		;7777
	ld (0c826h),a		;777a
	ret			;777d
trade:		; TRADE: cada equipo humano ofrece un jugador y se intercambian si se acepta DEAL
	ld hl,(0ed56h)		;777e   ; modos de los dos equipos
	ld a,h			;7781
	and a			;7782
	jr z,L_7788		;7783
	ld a,l			;7785
	and a			;7786
	ret nz			;7787
L_7788:
	call borra_nombres		;7788
	xor a			;778b   ; sin titulares mientras tanto
	ld (0c7f6h),a		;778c
	ld (0c826h),a		;778f
	ld a,0fah		;7792   ; franjas del rotulo
	ld hl,0182bh		;7794
	ld bc,00009h		;7797
	call rellena_guarda		;779a
	ld hl,0186bh		;779d
	call rellena_guarda		;77a0
	ld de,0707bh		;77a3   ; TRADE
	ld hl,0184dh		;77a6
	call imprime		;77a9
	ld hl,00000h		;77ac   ; jugadores ofrecidos: 0 y 0
	ld (0ed58h),hl		;77af
	xor a			;77b2
	ld (0ed4dh),a		;77b3
	ld a,(0ed56h)		;77b6   ; equipo izquierdo humano?
	and a			;77b9
	jr nz,L_77C3		;77ba
	call pantalla_plantilla		;77bc
	call elige_ofrecido		;77bf   ; elige su jugador
	ret c			;77c2
L_77C3:
	ld a,080h		;77c3
	ld (0ed4dh),a		;77c5
	ld a,(0ed57h)		;77c8   ; equipo derecho humano?
	and a			;77cb
	jr nz,trade_mesa		;77cc
	call patrones_plantilla		;77ce
	call pantalla_plantilla		;77d1
	call elige_ofrecido		;77d4
	ret c			;77d7
trade_mesa:		; Pantalla del trato: los dos jugadores ofrecidos con sus habilidades y estadisticas, y NO DEAL / DEAL
	ld hl,018a0h		;77d8   ; filas 5 a 23 en blanco
	ld bc,00260h		;77db
	ld a,020h		;77de
	call rellena_vram		;77e0
	ld hl,018c1h		;77e3   ; recuadro izquierdo
	ld de,0090eh		;77e6
	call cuadro_guarda		;77e9
	ld hl,018d0h		;77ec   ; recuadro derecho
	call cuadro_guarda		;77ef
	ld hl,01a29h		;77f2   ; recuadro del menu
	ld de,0030dh		;77f5
	call cuadro		;77f8
	ld a,0fah		;77fb   ; lineas de separacion
	ld hl,01902h		;77fd
	ld bc,0000dh		;7800
	call rellena_guarda		;7803
	ld hl,01911h		;7806
	call rellena_guarda		;7809
	ld hl,019a2h		;780c
	call rellena_guarda		;780f
	ld hl,019b1h		;7812
	call rellena_guarda		;7815
	ld hl,01922h		;7818   ; fondos de las barras
	ld bc,00403h		;781b
	ld d,08fh		;781e
	call rellena_bloque		;7820
	ld hl,01931h		;7823
	call rellena_bloque		;7826
	ld de,01945h		;7829   ; S J R
	ld hl,06fd6h		;782c
	ld bc,00302h		;782f
	call copia_bloque		;7832
	ld de,01954h		;7835
	call copia_bloque		;7838
	ld hl,01928h		;783b   ; SKILL
	ld de,06fc5h		;783e
	call imprime		;7841
	ld hl,01937h		;7844
	call imprime		;7847
	ld hl,019c2h		;784a   ; NAME:
	ld de,07081h		;784d
	call imprime		;7850
	ld hl,019d1h		;7853
	call imprime		;7856
	ld hl,(0ed56h)		;7859   ; los dos humanos: sin jugador nuevo
	ld a,l			;785c
	or h			;785d
	jr z,trade_pinta		;785e
	inc l			;7860
	dec l			;7861
	ld hl,0c707h		;7862   ; la maquina ofrece un jugador nuevo
	ld a,(0ed58h)		;7865
	jr z,L_7872		;7868
	ld hl,0c61bh		;786a
	ld a,(0ed59h)		;786d
	set 7,a		;7870
L_7872:
	call crea_jugador		;7872
trade_pinta:		; Pinta los dos jugadores ofrecidos: sprite, nombre, habilidades y franja del equipo
	ld a,(0ed58h)		;7875   ; jugador del equipo izquierdo
	ld (0ed4dh),a		;7878
	push af			;787b
	ld bc,0641bh		;787c
	call viste_jugador		;787f
	pop af			;7882
	or 040h		;7883   ; con barras de habilidad
	ld (0ed4dh),a		;7885
	ld c,000h		;7888   ; nombre
	call campo_jugador		;788a
	ld de,019c7h		;788d   ; en 0x19C7
	ld bc,00008h		;7890
	call copia_a_vram		;7893
	ld hl,01947h		;7896   ; barras de habilidad
	call pinta_habilidad		;7899
	ld hl,018e2h		;789c   ; franja del equipo
	ld bc,00d04h		;789f
	call cabecera_equipo		;78a2
	ld a,(0ed59h)		;78a5   ; jugador del equipo derecho
	or 080h		;78a8
	ld (0ed4dh),a		;78aa
	push af			;78ad
	ld bc,06493h		;78ae
	call viste_jugador		;78b1
	pop af			;78b4
	or 0c0h		;78b5
	ld (0ed4dh),a		;78b7
	ld c,000h		;78ba   ; nombre
	call campo_jugador		;78bc
	ld de,019d6h		;78bf   ; en 0x19D6
	ld bc,00008h		;78c2
	call copia_a_vram		;78c5
	ld hl,01956h		;78c8   ; barras de habilidad
	call pinta_habilidad		;78cb
	ld hl,018f1h		;78ce   ; franja del equipo
	ld bc,00d04h		;78d1
	call cabecera_equipo		;78d4
	ld de,01a4dh		;78d7   ; NO DEAL / DEAL
	ld hl,070fch		;78da
	ld bc,00207h		;78dd
	call copia_bloque		;78e0
	call opcion_cero		;78e3
trade_elige:		; Espacio sobre NO DEAL o DEAL
	ld hl,01a4ch		;78e6
	ld bc,0026fh		;78e9
	call selector		;78ec
	cp 020h		;78ef
	jr nz,trade_elige		;78f1
	ld a,e			;78f3   ; NO DEAL
	and a			;78f4
	ret z			;78f5
	ld a,(0ed58h)		;78f6   ; jugador ofrecido por el izquierdo
	ld (0ed4dh),a		;78f9
	ld c,000h		;78fc
	call campo_jugador		;78fe
	push hl			;7901
	ld a,(0ed59h)		;7902   ; jugador ofrecido por el derecho
	or 080h		;7905
	ld (0ed4dh),a		;7907
	ld c,000h		;790a
	call campo_jugador		;790c
	pop de			;790f
	ld bc,0001dh		;7910   ; intercambia sus 29 bytes
	call intercambia_bloque		;7913
	ld b,032h		;7916   ; el borde parpadea 50 veces
L_7918:
	push bc			;7918
	call parpadeo_borde		;7919
	pop bc			;791c
	djnz L_7918		;791d
	ld a,001h		;791f   ; borde negro otra vez
	ld (0f3ebh),a		;7921
	jp 00062h		;7924   ; BIOS CHGCLR - Changes the screen colors
parpadeo_borde:		; Siguiente color de borde y espera de dos cuadros
	ld a,(0f3ebh)		;7927
	inc a			;792a
	and 00fh		;792b
	ld (0f3ebh),a		;792d
	call 00062h		;7930   ; BIOS CHGCLR - Changes the screen colors
	ld hl,00002h		;7933   ; dos cuadros
	ld (0ed7eh),hl		;7936
L_7939:
	ld hl,(0ed7eh)		;7939
	ld a,h			;793c
	or l			;793d
	jr nz,L_7939		;793e
	ret			;7940
elige_ofrecido:		; Cursor sobre los ocho jugadores para elegir el que se ofrece; acarreo con ESC
	ld bc,0b483h		;7941
	call viste_jugador		;7944
L_7947:
	call habilidades_y_estadisticas		;7947
L_794A:
	ld bc,008f9h		;794a   ; ocho opciones
	ld hl,01942h		;794d
	call selector		;7950
	cp 01bh		;7953
	jr z,elige_esc		;7955
	cp 020h		;7957   ; espacio: elegido
	jr z,L_7970		;7959
	cp 01eh		;795b
	jr z,elige_ofrecido		;795d
	cp 01fh		;795f
	jr z,elige_ofrecido		;7961
	cp 01ch		;7963
	jr z,L_796B		;7965
	cp 01dh		;7967
	jr nz,L_794A		;7969
L_796B:
	call cambia_vista		;796b
	jr L_7947		;796e
L_7970:
	ld a,(0ed4dh)		;7970   ; jugador ofrecido del equipo
	ld hl,0ed58h		;7973
	bit 7,a		;7976
	jr z,L_797B		;7978
	inc hl			;797a
L_797B:
	ld (hl),e			;797b
	and a			;797c
	ret			;797d
elige_esc:		; Acarreo: cancelado
	scf			;797e
	ret			;797f
menu_equipo:		; Menu del equipo: MAKE TEAM, LOAD DATA, READY-MADE, COMPUTER, EDIT TEAM; DEL graba
	call borra_nombres		;7980
	ld hl,07028h		;7983   ; cinco opciones de 10 letras
	ld de,01804h		;7986
	ld bc,0050ah		;7989
	call copia_bloque		;798c
	call 00041h		;798f   ; BIOS DISSCR - Inhibits the screen display | pantalla apagada mientras se pinta
	ld hl,01810h		;7992
	ld de,0030dh		;7995
	call cuadro		;7998
	call pantalla_plantilla		;799b   ; plantilla
	call opcion_cero		;799e
L_79A1:
	call borra_rotulo		;79a1
	call panel_modo		;79a4   ; panel segun el modo
	call 00044h		;79a7   ; BIOS ENASCR - Displays the screen
menu_equipo_elige:		; Selector de cinco opciones del menu del equipo
	ld hl,01803h		;79aa
	ld bc,0056fh		;79ad
	call selector		;79b0
	ld a,c			;79b3
	cp 01bh		;79b4   ; ESC: vuelve
	ret z			;79b6
	cp 07fh		;79b7   ; DEL: SAVE DATA
	jr z,pide_grabar		;79b9
	cp 020h		;79bb
	jr nz,menu_equipo_elige		;79bd
	ld a,e			;79bf
	and a			;79c0
	jr nz,L_79C8		;79c1
	call make_team		;79c3   ; MAKE TEAM
	jr L_79A1		;79c6
L_79C8:
	cp 001h		;79c8
	jr nz,L_79D1		;79ca
	call load_data		;79cc   ; LOAD DATA
	jr L_79A1		;79cf
L_79D1:
	cp 002h		;79d1
	jr nz,L_79DA		;79d3
	call ready_made		;79d5   ; READY-MADE
	jr L_79A1		;79d8
L_79DA:
	cp 003h		;79da
	jr nz,L_79E3		;79dc
	call computer		;79de   ; COMPUTER
	jr L_79A1		;79e1
L_79E3:
	call edit_team		;79e3   ; EDIT TEAM
	jr L_79A1		;79e6
pide_grabar:		; Solo graba un equipo propio (modo 0)
	call modo_equipo		;79e8   ; modo del equipo
	ld a,(hl)			;79eb
	and a			;79ec   ; 0: equipo propio
	jr nz,menu_equipo_elige		;79ed
	call save_data		;79ef   ; graba
	jr L_79A1		;79f2
make_team:		; MAKE TEAM: nombre nuevo, modo 0, jugadores nuevos al azar y edicion de sus nombres
	call pide_nombre		;79f4
	ret c			;79f7
	call modo_equipo		;79f8
	ld (hl),000h		;79fb   ; modo 0: equipo propio
	ld a,(0ed4dh)		;79fd
	ld (0ed4eh),a		;7a00
	and 080h		;7a03
	call roster_nuevo		;7a05   ; roster nuevo
edita_equipo:		; Plantilla y edicion de los ocho jugadores
	ld a,(0ed4dh)		;7a08
	ld (0ed4eh),a		;7a0b   ; opcion guardada
	call pantalla_plantilla		;7a0e   ; plantilla
	call edita_nombres		;7a11   ; edita nombres y aspecto
	ld a,(0ed4eh)		;7a14
	ld (0ed4dh),a		;7a17
	ld hl,01942h		;7a1a   ; borra la columna del cursor
	ld bc,00801h		;7a1d
	ld d,020h		;7a20
	jp rellena_bloque		;7a22
roster_nuevo:		; Borra el roster del equipo A y crea ocho jugadores sin nombre con caracteristicas al azar
	ld (0ed4dh),a		;7a25
	ld c,000h		;7a28   ; primer jugador
	call campo_jugador		;7a2a
	push hl			;7a2d
	ld d,h			;7a2e
	ld e,l			;7a2f
	inc de			;7a30
	ld (hl),000h		;7a31
	ld bc,000e7h		;7a33   ; 232 bytes a cero
	ldir		;7a36
	pop hl			;7a38
	call nombres_en_blanco		;7a39   ; nombres en blanco
	ld c,00fh		;7a3c   ; campo 0x0F
	call campo_jugador		;7a3e
	ld b,008h		;7a41   ; ocho jugadores
L_7A43:
	push hl			;7a43
	call azar_a		;7a44   ; tres azares
	call azar_c		;7a47   ; y otros
	call azar_e		;7a4a
	call azar_g		;7a4d
	call azar_i		;7a50
	pop hl			;7a53
	ld de,0001dh		;7a54   ; siguiente jugador
	add hl,de			;7a57
	djnz L_7A43		;7a58
	ret			;7a5a
edit_team:		; EDIT TEAM: solo con un equipo propio
	call modo_equipo		;7a5b
	ld a,(hl)			;7a5e
	and a			;7a5f
	ret nz			;7a60
	jp edita_equipo		;7a61
load_data:		; LOAD DATA: carga de cinta tras SURE?; si falla, ERROR
	ld hl,01832h		;7a64   ; LOAD DATA;
	ld de,0711bh		;7a67
	call imprime		;7a6a
	ld hl,01854h		;7a6d   ; SURE?
	ld de,07139h		;7a70
	call imprime		;7a73
L_7A76:
	call 0009fh		;7a76   ; BIOS CHGET - One character input (waiting)
	cp 01bh		;7a79
	ret z			;7a7b
	cp 020h		;7a7c
	jr nz,L_7A76		;7a7e
	xor a			;7a80   ; pieza 0: silencio
	call arranca_sonido		;7a81
	ld c,000h		;7a84
	call campo_cabecera		;7a86   ; cabecera del roster
	call carga_equipo		;7a89
	push af			;7a8c
	ld a,00ah		;7a8d   ; pieza 0x0A
	call arranca_sonido		;7a8f
	pop af			;7a92
	jr nc,cargado		;7a93
error_cinta:		; Rotulo ERROR y espera el espacio
	ld hl,01851h		;7a95
	ld de,0713fh		;7a98
	call imprime		;7a9b
L_7A9E:
	call 0009fh		;7a9e   ; BIOS CHGET - One character input (waiting)
	cp 020h		;7aa1
	jr nz,L_7A9E		;7aa3
	ret			;7aa5
cargado:		; Nombre del equipo cargado y modo 0
	ld c,000h		;7aa6   ; nombre del equipo
	call campo_cabecera		;7aa8
	ld de,018cfh		;7aab   ; en el marcador
	call copia_tres		;7aae
	call modo_equipo		;7ab1
	ld (hl),000h		;7ab4   ; modo 0: propio
	ret			;7ab6
save_data:		; SAVE DATA: graba el roster en cinta y ofrece VERIFY
	ld hl,01832h		;7ab7   ; SAVE DATA;
	ld de,07126h		;7aba
	call imprime		;7abd
	ld hl,01854h		;7ac0   ; SURE?
	ld de,07139h		;7ac3
	call imprime		;7ac6
L_7AC9:
	call 0009fh		;7ac9   ; BIOS CHGET - One character input (waiting)
	cp 01bh		;7acc
	ret z			;7ace
	cp 020h		;7acf
	jr nz,L_7AC9		;7ad1
	xor a			;7ad3
	call arranca_sonido		;7ad4
	call nombre_fichero		;7ad7   ; nombre de fichero
	ld c,000h		;7ada
	call campo_cabecera		;7adc
	push hl			;7adf
	ld de,000ebh		;7ae0   ; fin del bloque: 0xEB bytes
	add hl,de			;7ae3
	ld (0f87dh),hl		;7ae4   ; SUPOSICION: direccion final para la grabacion
	pop hl			;7ae7
	call graba_equipo_sp		;7ae8   ; graba en cinta
	jr c,error_cinta		;7aeb
	call borra_rotulo		;7aed
	ld hl,01833h		;7af0   ; VERIFY;
	ld de,07131h		;7af3
	call imprime		;7af6
	ld hl,01854h		;7af9
	ld de,07139h		;7afc
	call imprime		;7aff
L_7B02:
	call 0009fh		;7b02   ; BIOS CHGET - One character input (waiting)
	cp 01bh		;7b05
	ret z			;7b07
	cp 020h		;7b08
	jr nz,L_7B02		;7b0a
	call nombre_fichero		;7b0c
	ld c,000h		;7b0f
	call campo_cabecera		;7b11
	call verifica_equipo		;7b14   ; verifica la grabacion
	push af			;7b17
	ld a,00ah		;7b18
	call arranca_sonido		;7b1a
	pop af			;7b1d
	jp c,error_cinta		;7b1e
	ret			;7b21
nombre_fichero:		; FILNAM = las tres letras del equipo y tres 0x7F
	ld c,000h		;7b22
	call campo_cabecera		;7b24
	push hl			;7b27
	ld de,0f866h		;7b28   ; FILNAM
	ld bc,00003h		;7b2b
	ldir		;7b2e
	ld a,07fh		;7b30
	ld b,003h		;7b32
L_7B34:
	ld (de),a			;7b34
	inc de			;7b35
	djnz L_7B34		;7b36
	pop hl			;7b38
	ret			;7b39
pinta_encontrado:		; FOUND: y el nombre de FILNAM
	ld hl,01831h		;7b3a
	ld de,0714ch		;7b3d   ; FOUND:
	call imprime		;7b40
	ex de,hl			;7b43
	ld hl,0f866h		;7b44   ; nombre de FILNAM
	jp copia_tres		;7b47
ready_made:		; READY-MADE: nombre, TEAM LEVEL de 1 a 8 y equipo generado de ese nivel (modo 1)
	ld hl,01902h		;7b4a   ; fondo del panel
	ld bc,00f1ch		;7b4d
	ld d,0feh		;7b50
	call rellena_bloque		;7b52
	ld hl,01928h		;7b55   ; recuadro
	ld de,00b0fh		;7b58
	call cuadro		;7b5b
	ld hl,01949h		;7b5e
	ld bc,00a0eh		;7b61
	ld d,020h		;7b64
	call rellena_bloque		;7b66
	ld hl,01969h		;7b69
	ld bc,0000eh		;7b6c
	ld a,0f4h		;7b6f
	call rellena_vram		;7b71
	ld hl,0194bh		;7b74   ; TEAM LEVEL
	ld de,070d8h		;7b77
	call imprime		;7b7a
	ld hl,0198dh		;7b7d   ; LEVEL ocho veces
	ld de,0701dh		;7b80
	ld b,008h		;7b83
	call imprime_filas		;7b85
	ld de,01993h		;7b88   ; numeros 1 a 8
	ld hl,06feeh		;7b8b
	ld bc,00801h		;7b8e
	call copia_bloque		;7b91
	call pide_nombre		;7b94   ; nombre del equipo
	ret c			;7b97
	ld a,(0ed4dh)		;7b98
	ld (0ed4eh),a		;7b9b
	and 080h		;7b9e
	ld (0ed4dh),a		;7ba0
	call opcion_cero		;7ba3
ready_made_elige:		; Selector de los ocho niveles
	ld hl,0198ch		;7ba6
	ld bc,008f9h		;7ba9
	call selector		;7bac
	ld a,c			;7baf
	cp 01bh		;7bb0
	jr z,ready_made_esc		;7bb2
	cp 020h		;7bb4
	jr nz,ready_made_elige		;7bb6
	ld c,003h		;7bb8   ; nivel = opcion + 1 (roster +3)
	call campo_cabecera		;7bba
	inc e			;7bbd
	ld (hl),e			;7bbe
	call genera_equipo		;7bbf   ; jugadores del nivel
	call modo_equipo		;7bc2
	ld (hl),001h		;7bc5   ; modo 1: READY-MADE
	ld hl,0198ch		;7bc7
	ld bc,00901h		;7bca
	ld d,020h		;7bcd
	call rellena_bloque		;7bcf
	jr restaura_opcion		;7bd2
ready_made_esc:		; ESC: vuelve a poner el nombre anterior
	ld c,000h		;7bd4
	call campo_cabecera		;7bd6   ; nombre del equipo
	ex de,hl			;7bd9
	push de			;7bda
	ld hl,0ed53h		;7bdb   ; el anterior (0xED53)
	ld bc,00003h		;7bde
	ldir		;7be1
	pop hl			;7be3
	ld de,018cfh		;7be4   ; en el marcador
	call copia_tres		;7be7
restaura_opcion:		; Recupera 0xED4D
	ld a,(0ed4eh)		;7bea
	ld (0ed4dh),a		;7bed
	ret			;7bf0
computer:		; COMPUTER: equipo de la maquina de nivel 1 a 8 con su nombre de la tabla 0x6FF3 (modo 2)
	call borra_rotulo		;7bf1
	ld hl,01902h		;7bf4   ; fondo del panel
	ld bc,00f1ch		;7bf7
	ld d,0f0h		;7bfa
	call rellena_bloque		;7bfc
	ld hl,01923h		;7bff   ; recuadro
	ld de,00b19h		;7c02
	call cuadro		;7c05
	ld hl,01944h		;7c08
	ld bc,00a18h		;7c0b
	ld d,020h		;7c0e
	call rellena_bloque		;7c10
	ld hl,01964h		;7c13
	ld bc,00018h		;7c16
	ld a,0f4h		;7c19
	call rellena_vram		;7c1b
	ld de,0700eh		;7c1e   ; COMPUTER TEAMS
	ld hl,01949h		;7c21
	call imprime		;7c24
	ld de,0701dh		;7c27   ; LEVEL ocho veces
	ld hl,01986h		;7c2a
	ld b,008h		;7c2d
	call imprime_filas		;7c2f
	ld de,07023h		;7c32   ; TEAM ocho veces
	ld hl,01996h		;7c35
	ld b,008h		;7c38
	call imprime_filas		;7c3a
	ld d,03bh		;7c3d
	ld bc,00803h		;7c3f
	ld hl,0198eh		;7c42
	call rellena_bloque		;7c45
	ld hl,06feeh		;7c48   ; numeros 1 a 8
	ld de,0198ch		;7c4b
	ld bc,00801h		;7c4e
	call copia_bloque		;7c51
	ld hl,06ff6h		;7c54   ; nombres de los ocho equipos
	ld de,01992h		;7c57
	ld bc,00803h		;7c5a
	call copia_bloque		;7c5d
	ld a,(0ed4dh)		;7c60
	ld (0ed4eh),a		;7c63
	call opcion_cero		;7c66
computer_elige:		; Selector de los ocho equipos de la maquina
	ld hl,01985h		;7c69
	ld bc,008f9h		;7c6c
	call selector		;7c6f
	ld a,c			;7c72
	cp 01bh		;7c73
	jr z,L_7CA7		;7c75
	cp 020h		;7c77
	jr nz,computer_elige		;7c79
	ld c,003h		;7c7b   ; nivel = opcion + 1
	call campo_cabecera		;7c7d
	inc e			;7c80
	ld (hl),e			;7c81
	ld c,000h		;7c82
	call campo_cabecera		;7c84
	ex de,hl			;7c87
	ld a,l			;7c88   ; tres letras por equipo
	add a,a			;7c89
	add a,l			;7c8a
	ld l,a			;7c8b
	ld h,000h		;7c8c
	ld bc,06ff3h		;7c8e
	add hl,bc			;7c91
	ld bc,00003h		;7c92
	push hl			;7c95
	ldir		;7c96
	pop hl			;7c98
	ld de,018cfh		;7c99   ; nombre en el marcador
	call copia_tres		;7c9c
	call genera_equipo		;7c9f   ; jugadores del nivel
	call modo_equipo		;7ca2
	ld (hl),002h		;7ca5   ; modo 2: maquina
L_7CA7:
	ld a,(0ed4eh)		;7ca7
	ld (0ed4dh),a		;7caa   ; opcion de antes
	ld hl,01985h		;7cad   ; borra la columna del cursor
	ld bc,00901h		;7cb0
	ld d,020h		;7cb3
	jp rellena_bloque		;7cb5
pide_nombre:		; TEAM NAME: tres letras; guarda el anterior en 0xED53 y pone el nuevo
	call borra_rotulo		;7cb8
	ld de,01831h		;7cbb   ; TEAM NAME:
	ld hl,07063h		;7cbe
	ld bc,0020ch		;7cc1
	call copia_bloque		;7cc4
	ld hl,01855h		;7cc7
	call lee_nombre		;7cca   ; lee el nombre
	ret c			;7ccd
	ld c,000h		;7cce
	call campo_cabecera		;7cd0
	push hl			;7cd3
	ld de,0ed53h		;7cd4   ; nombre anterior a 0xED53
	ld bc,00003h		;7cd7
	ldir		;7cda
	pop hl			;7cdc
	push hl			;7cdd
	ex de,hl			;7cde
	ld hl,0ed50h		;7cdf   ; nombre nuevo desde 0xED50
	ld bc,00003h		;7ce2
	ldir		;7ce5
	pop hl			;7ce7
	push hl			;7ce8
	ld de,018cfh		;7ce9
	call copia_tres		;7cec
	pop hl			;7cef
	and a			;7cf0
	ret			;7cf1
mayusculas:		; Letras minusculas a mayusculas
	cp 061h		;7cf2   ; antes de la a?
	ret c			;7cf4
	cp 07bh		;7cf5   ; despues de la z?
	ret nc			;7cf7
	sub 020h		;7cf8   ; a mayuscula
	ret			;7cfa
lee_nombre:		; Lee tres letras en 0xED50 con CHGET: BS borra, RETURN acepta, ESC cancela (acarreo), punto = 0x3B
	push hl			;7cfb
	ld b,003h		;7cfc
	ld hl,0ed50h		;7cfe
L_7D01:
	ld (hl),06bh		;7d01   ; tres huecos 0x6B
	inc hl			;7d03
	djnz L_7D01		;7d04
	pop hl			;7d06
	ld de,0ed50h		;7d07
	xor a			;7d0a
	ld (0ed4fh),a		;7d0b   ; letras escritas
L_7D0E:
	push hl			;7d0e
	push de			;7d0f
	ex de,hl			;7d10
	ld hl,0ed50h		;7d11   ; nombre en curso
	call copia_tres		;7d14   ; a la pantalla
	pop de			;7d17
	pop hl			;7d18
L_7D19:
	call 0009fh		;7d19   ; BIOS CHGET - One character input (waiting)
	call mayusculas		;7d1c
	cp 008h		;7d1f   ; BS
	jr z,borra_letra		;7d21
	cp 00dh		;7d23   ; RETURN
	jr z,acepta_nombre		;7d25
	cp 01bh		;7d27   ; ESC
	jr z,L_7D6E		;7d29
	cp 02eh		;7d2b   ; punto
	jr z,L_7D46		;7d2d
	cp 041h		;7d2f   ; solo letras A-Z
	jr c,L_7D19		;7d31
	cp 05bh		;7d33
	jr nc,L_7D19		;7d35
L_7D37:
	ld (de),a			;7d37   ; letra
	ld a,(0ed4fh)		;7d38   ; posicion
	cp 002h		;7d3b   ; ya en la tercera
	jr z,L_7D0E		;7d3d
	inc a			;7d3f   ; siguiente posicion
	inc de			;7d40
	ld (0ed4fh),a		;7d41
	jr L_7D0E		;7d44
L_7D46:
	ld a,03bh		;7d46
	jr L_7D37		;7d48
borra_letra:		; Retroceso en el nombre
	ld a,(0ed4fh)		;7d4a   ; posicion
	cp 002h		;7d4d
	jr nz,L_7D62		;7d4f
	ld b,a			;7d51
	ld a,(de)			;7d52   ; letra de la tercera
	cp 06bh		;7d53   ; hueco?
	ld a,b			;7d55
	jr nz,L_7D5D		;7d56
L_7D58:
	dec a			;7d58
	dec de			;7d59
	ld (0ed4fh),a		;7d5a
L_7D5D:
	ld a,06bh		;7d5d
	ld (de),a			;7d5f
	jr L_7D0E		;7d60
L_7D62:
	and a			;7d62
	jr z,L_7D0E		;7d63
	jr L_7D58		;7d65
acepta_nombre:		; RETURN solo con el nombre completo
	ld a,(de)			;7d67
	cp 06bh		;7d68
	jr z,L_7D19		;7d6a
	xor a			;7d6c
	ret			;7d6d
L_7D6E:
	scf			;7d6e
	ret			;7d6f
edita_nombres:		; Edita los nombres de los ocho jugadores; izquierda/derecha cambian su aspecto
	ld a,(0ed4dh)		;7d70
	or 040h		;7d73   ; vista de estadisticas
	ld (0ed4dh),a		;7d75
	call rotulos_estadisticas		;7d78
L_7D7B:
	ld bc,0b483h		;7d7b
	call viste_jugador		;7d7e
	xor a			;7d81
	ld (0ed4fh),a		;7d82   ; posicion en el nombre
	call habilidades_y_estadisticas		;7d85
L_7D88:
	call pinta_nombres		;7d88
edita_elige:		; Selector de jugador con letras, BS, punto y cambio de aspecto
	ld hl,01942h		;7d8b
	ld bc,008f9h		;7d8e
	call selector		;7d91
	ld a,c			;7d94
	cp 01bh		;7d95   ; ESC: acaba
	ret z			;7d97
	cp 01eh		;7d98
	jr z,L_7D7B		;7d9a
	cp 01fh		;7d9c
	jr z,L_7D7B		;7d9e
	cp 01ch		;7da0   ; derecha: aspecto siguiente
	jr z,aspecto_siguiente		;7da2
	cp 01dh		;7da4   ; izquierda: aspecto anterior
	jr z,aspecto_anterior		;7da6
	cp 008h		;7da8   ; BS
	jr z,borra_letra_jugador		;7daa
	cp 02eh		;7dac   ; punto
	jr z,L_7DDE		;7dae
	cp 041h		;7db0   ; solo letras A-Z
	jr c,edita_elige		;7db2
	cp 05bh		;7db4
	jr nc,edita_elige		;7db6
L_7DB8:
	push af			;7db8
	ld c,000h		;7db9
	call campo_jugador		;7dbb
	ld a,(0ed4fh)		;7dbe
	and a			;7dc1
	jr nz,L_7DCD		;7dc2   ; primera letra: borra el nombre
	ld b,008h		;7dc4
	push hl			;7dc6
L_7DC7:
	ld (hl),06bh		;7dc7
	inc hl			;7dc9
	djnz L_7DC7		;7dca
	pop hl			;7dcc
L_7DCD:
	ld e,a			;7dcd   ; posicion
	ld d,000h		;7dce
	add hl,de			;7dd0
	pop af			;7dd1
	ld (hl),a			;7dd2   ; letra en su sitio
	ld a,e			;7dd3
	cp 007h		;7dd4   ; ya en la octava
	jr z,L_7D88		;7dd6
	inc a			;7dd8   ; siguiente posicion
	ld (0ed4fh),a		;7dd9
	jr L_7D88		;7ddc
L_7DDE:
	ld a,03bh		;7dde
	jr L_7DB8		;7de0
aspecto_siguiente:		; Aspecto (campo 8) mas uno, de 0 a 31
	ld c,008h		;7de2
	call campo_jugador		;7de4
	ld a,(hl)			;7de7
	inc a			;7de8
L_7DE9:
	and 01fh		;7de9
	ld (hl),a			;7deb
	jr L_7D7B		;7dec
aspecto_anterior:		; Aspecto menos uno
	ld c,008h		;7dee
	call campo_jugador		;7df0
	ld a,(hl)			;7df3
	dec a			;7df4
	jr L_7DE9		;7df5
borra_letra_jugador:		; Retroceso en el nombre del jugador
	ld c,000h		;7df7
	call campo_jugador		;7df9   ; nombre del jugador
	ld a,(0ed4fh)		;7dfc   ; posicion
	ld e,a			;7dff
	ld d,000h		;7e00
	add hl,de			;7e02
	cp 007h		;7e03   ; en la octava?
	jr nz,L_7E18		;7e05
	ld b,a			;7e07
	ld a,(hl)			;7e08   ; letra de la octava
	cp 06bh		;7e09   ; hueco?
	ld a,b			;7e0b
	jr nz,L_7E13		;7e0c
L_7E0E:
	dec a			;7e0e
	dec hl			;7e0f
	ld (0ed4fh),a		;7e10
L_7E13:
	ld (hl),06bh		;7e13
	jp L_7D88		;7e15
L_7E18:
	and a			;7e18
	jp z,L_7D88		;7e19
	jr L_7E0E		;7e1c
selector:		; Selector de B opciones en la columna HL con el cursor C: arriba y abajo mueven (0xED4D bits 0-5); devuelve en A y C cualquier otra tecla y en E la opcion
	ld a,(0ed4dh)		;7e1e   ; bits 6-7 de 0xED4D se conservan
	ld e,a			;7e21
	and 0c0h		;7e22
	ld d,a			;7e24
	ld a,e			;7e25
	and 03fh		;7e26
	ld e,a			;7e28
	ld a,c			;7e29
	exx			;7e2a
	ld c,a			;7e2b
	exx			;7e2c
	call pinta_cursor		;7e2d   ; pinta el cursor
	call 0009fh		;7e30   ; BIOS CHGET - One character input (waiting) | espera una tecla
	call mayusculas		;7e33
	ld c,a			;7e36
	cp 01eh		;7e37   ; arriba
	jr nz,L_7E41		;7e39
	inc e			;7e3b
	dec e			;7e3c
	ret z			;7e3d
	dec e			;7e3e
	jr L_7E4B		;7e3f
L_7E41:
	cp 01fh		;7e41   ; abajo
	ret nz			;7e43
	inc e			;7e44
	ld a,e			;7e45
	cp b			;7e46
	jr c,L_7E4B		;7e47
	dec e			;7e49
	ret			;7e4a
L_7E4B:
	ld a,d			;7e4b   ; opcion nueva
	or e			;7e4c
	ld (0ed4dh),a		;7e4d   ; opcion nueva
	push bc			;7e50
	exx			;7e51
	ld a,c			;7e52   ; cursor
	exx			;7e53
	ld c,a			;7e54
	call pinta_cursor		;7e55   ; lo pinta
	pop bc			;7e58
	ld a,c			;7e59   ; A = tecla
	ret			;7e5a
pinta_cursor:		; Borra la columna de B filas y pone el caracter C en la fila de la opcion
	push de			;7e5b
	push hl			;7e5c
	push hl			;7e5d
	push bc			;7e5e
	ld d,020h		;7e5f   ; espacios
	ld c,001h		;7e61   ; columna de B filas
	call rellena_bloque		;7e63   ; borra el cursor anterior
	pop bc			;7e66
	pop de			;7e67
	ld a,(0ed4dh)		;7e68   ; opcion
	and 03fh		;7e6b
	ld l,a			;7e6d
	ld h,000h		;7e6e
	add hl,hl			;7e70   ; por 32: fila
	add hl,hl			;7e71
	add hl,hl			;7e72
	add hl,hl			;7e73
	add hl,hl			;7e74
	add hl,de			;7e75   ; columna del cursor
	ld a,c			;7e76   ; caracter del cursor
	call escribe_vram		;7e77
	pop hl			;7e7a
	pop de			;7e7b
	ret			;7e7c
lee_disparo:		; NZ si se pulsa el espacio o el disparo de un joystick
	xor a			;7e7d   ; espacio
	call 000d8h		;7e7e   ; BIOS GTTRIG - Returns current trigger status
	and a			;7e81
	ret nz			;7e82
	ld a,001h		;7e83   ; disparo del joystick 1
	call 000d8h		;7e85   ; BIOS GTTRIG - Returns current trigger status
	and a			;7e88
	ret nz			;7e89
	ld a,002h		;7e8a   ; disparo del joystick 2
	call 000d8h		;7e8c   ; BIOS GTTRIG - Returns current trigger status
	and a			;7e8f
	ret			;7e90
colores_por_defecto_huerfano:		; Huerfano: pondria los colores de equipo de la primera pista
	ld hl,06badh		;7e91
	ld (hl),000h		;7e94   ; SUPOSICION: COLOR OF COURT a 0 (escribe en la ROM)
	inc hl			;7e96
	ld a,(hl)			;7e97   ; color del izquierdo
	ld (0c7f2h),a		;7e98
	inc hl			;7e9b
	ld a,(hl)			;7e9c   ; color del derecho
	ld (0c822h),a		;7e9d
	jp pinta_franjas		;7ea0
opcion_cero:		; Opcion 0 conservando el bit 7 (equipo)
	ld a,(0ed4dh)		;7ea3
	and 080h		;7ea6
	ld (0ed4dh),a		;7ea8
	ret			;7eab
panel_modo:		; Panel segun el modo: plantilla (0), READY-MADE (1) o COMPUTER TEAM (2) con su nivel
	call patrones_plantilla		;7eac
	call modo_equipo		;7eaf
	ld a,(hl)			;7eb2   ; modo 0: plantilla
	and a			;7eb3
	jr nz,L_7EC4		;7eb4
	ld hl,01902h		;7eb6
	ld bc,00f1ch		;7eb9
	ld d,020h		;7ebc
	call rellena_bloque		;7ebe
	jp L_6F03		;7ec1
L_7EC4:
	cp 001h		;7ec4   ; modo 1: READY-MADE
	jr nz,L_7ED6		;7ec6
	ld d,0feh		;7ec8
	call panel_nivel		;7eca
	ld hl,019abh		;7ecd
	ld de,070f1h		;7ed0
	jp imprime		;7ed3
L_7ED6:
	ld d,0f0h		;7ed6   ; modo 2: COMPUTER TEAM
	call panel_nivel		;7ed8
	ld hl,019aah		;7edb
	ld de,070e3h		;7ede
	jp imprime		;7ee1
panel_nivel:		; Fondo D, recuadro, LEVEL y el nivel del equipo
	ld hl,01902h		;7ee4   ; fondo D
	ld bc,00f1ch		;7ee7
	call rellena_bloque		;7eea
	ld hl,01986h		;7eed   ; recuadro del nivel
	ld de,00413h		;7ef0
	call cuadro		;7ef3
	ld hl,019a7h		;7ef6   ; interior en blanco
	ld bc,00312h		;7ef9
	ld d,020h		;7efc
	call rellena_bloque		;7efe
	ld hl,019c7h		;7f01   ; linea
	ld bc,00012h		;7f04
	ld a,0f4h		;7f07
	call rellena_vram		;7f09
	ld hl,019edh		;7f0c   ; LEVEL
	ld de,0701dh		;7f0f
	call imprime		;7f12
	ld c,003h		;7f15   ; nivel (roster +3)
	call campo_cabecera		;7f17
	ld a,(hl)			;7f1a   ; nivel
	add a,030h		;7f1b   ; en ASCII
	ld hl,019f3h		;7f1d
	jp escribe_vram		;7f20
azar_r:		; Aleatorio mezclado con el registro R
	call aleatorio		;7f23   ; azar
	push bc			;7f26
	ld b,a			;7f27
	ld a,r		;7f28   ; registro de refresco
	add a,b			;7f2a   ; mezcla
	pop bc			;7f2b
	ret			;7f2c
rotulo_half_time:		; HALF TIME en el marcador
	ld hl,07f48h		;7f2d
	jr rotulo_dos_filas		;7f30
rotulo_game_over:		; GAME OVER en el marcador
	ld hl,07f52h		;7f32
rotulo_dos_filas:		; Dos filas de cinco caracteres de HL en 0x182E
	call congela_sprites		;7f35
	ld de,0182eh		;7f38   ; fila 1, columna 14
	ld bc,00205h		;7f3b   ; dos filas de cinco
	call copia_bloque		;7f3e
	xor a			;7f41
	ld (0ed5ch),a		;7f42   ; sin repintar el tiempo
	jp suelta_sprites		;7f45

; ----------------------------------------------------------------------
; DATOS rotulo_half_time: "HALF TIME." (diez caracteres, sin fin de cadena):
;   lo copia 0x7F2D
;   0x7f48..0x7f52  (10 bytes)
DATA_rotulo_half_time:
	defb 048h,041h,04ch,046h,020h,054h,049h,04dh,045h,03eh	; 7f48  HALF TIME>

; ----------------------------------------------------------------------
; DATOS rotulo_game_over: "GAME OVER." (diez caracteres, sin fin de cadena):
;   lo copia 0x7F32
;   0x7f52..0x7f5c  (10 bytes)
DATA_rotulo_game_over:
	defb 047h,041h,04dh,045h,020h,04fh,056h,045h,052h,03eh	; 7f52  GAME OVER>

; ======================================================================
; CODIGO 0x7f5c..0x7f76  (26 bytes)
; ======================================================================


push_any_key:		; PUSH SPACE KEY> en la fila 23 (la primera version decia PUSH ANY KEY.)
	call congela_sprites		;7f5c
	ld hl,01ae0h		;7f5f   ; fila 23
	ld bc,00020h		;7f62
	ld a,084h		;7f65   ; franja 0x84
	call rellena_vram		;7f67
	ld hl,01ae9h		;7f6a   ; una columna antes: el rotulo es un caracter mas largo
	ld de,07f76h		;7f6d   ; PUSH SPACE KEY>
	call imprime		;7f70
	jp suelta_sprites		;7f73

; ----------------------------------------------------------------------
; DATOS rotulo_push_any_key: "PUSH SPACE KEY>" acabado en cero (la primera
;   version decia "PUSH ANY KEY."): lo imprime 0x7F70
;   0x7f76..0x7f86  (16 bytes)
DATA_rotulo_push_any_key:
	defb 050h,055h,053h,048h,020h,053h,050h,041h,043h,045h,020h,04bh,045h,059h,03eh,000h	; 7f76  PUSH SPACE KEY>.

; ======================================================================
; CODIGO 0x7f86..0x8964  (2526 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Movimiento de jugadores y balon (servicio de cada cuadro) =====
; ----------------------------------------------------------------------
integra_jugadores:		; Suma la velocidad a la posicion de los seis jugadores y comprueba si han llegado a su destino
	ld ix,0c410h		;7f86   ; el primer registro de jugador
	ld b,006h		;7f8a   ; los seis
	ld c,000h		;7f8c   ; C = indice
L_7F8E:
	ld l,(ix+000h)		;7f8e   ; Y en 8.8 (+0/+1)
	ld h,(ix+001h)		;7f91
	ld e,(ix+004h)		;7f94   ; velocidad Y (+4/+5)
	ld d,(ix+005h)		;7f97
	add hl,de			;7f9a
	push hl			;7f9b
	ld (ix+000h),l		;7f9c
	ld (ix+001h),h		;7f9f
	ld l,(ix+002h)		;7fa2   ; X en 8.8 (+2/+3)
	ld h,(ix+003h)		;7fa5
	ld e,(ix+006h)		;7fa8   ; velocidad X (+6/+7)
	ld d,(ix+007h)		;7fab
	add hl,de			;7fae
	ld (ix+002h),l		;7faf
	ld (ix+003h),h		;7fb2
	pop de			;7fb5
	ld e,h			;7fb6
	ld h,(ix+020h)		;7fb7   ; destino Y (+0x20) y X (+0x21)
	ld l,(ix+021h)		;7fba
	ld a,h			;7fbd
	or l			;7fbe
	jr z,L_7FFB		;7fbf   ; sin destino
	call diferencia_xy		;7fc1
	push bc			;7fc4
	call distancia		;7fc5   ; distancia al destino
	pop bc			;7fc8
	cp 006h		;7fc9   ; a menos de 6: ha llegado
	jr nc,L_7FFB		;7fcb
	xor a			;7fcd
	ld (ix+020h),a		;7fce   ; borra el destino
	ld (ix+021h),a		;7fd1
	ld (ix+000h),a		;7fd4   ; y las fracciones de Y y X
	ld (ix+002h),a		;7fd7
	ld a,(0cb24h)		;7fda   ; SUPOSICION: jugador que toma el control al llegar
	cp c			;7fdd
	jr nz,L_7FED		;7fde
	ld a,(0cb24h)		;7fe0
	call controla		;7fe3
	ld a,0ffh		;7fe6   ; atendido
	ld (0cb24h),a		;7fe8
	jr L_7FFB		;7feb
L_7FED:
	ld a,(0cb25h)		;7fed   ; el del otro equipo
	cp c			;7ff0
	jr nz,L_7FFB		;7ff1
	call controla		;7ff3
	ld a,0ffh		;7ff6
	ld (0cb25h),a		;7ff8
L_7FFB:
	ld de,00030h		;7ffb   ; siguiente registro
	add ix,de		;7ffe
	inc c			;8000
	dec b			;8001
	jp nz,L_7F8E		;8002
	ret			;8005
mueve_balon:		; Un paso del balon libre: pase en linea recta, tiro en parabola; al llegar da el balon o resuelve el tiro
	ld hl,0c53ch		;8006   ; gravedad del balon: 0 = en la mano
	ld a,(hl)			;8009
	and a			;800a
	ret z			;800b
	ld a,(0c602h)		;800c   ; salto entre dos
	and a			;800f
	jr nz,L_8024		;8010
	ld a,(0c5dfh)		;8012
	and 0c0h		;8015
	jp z,balon_cae		;8017   ; nadie tira ni pasa: bota o rueda
	rlca			;801a
	jr nc,L_8024		;801b   ; pase en vuelo
	ld a,(0ed61h)		;801d   ; 1 = mate: directo al aro
	dec a			;8020
	jp z,balon_en_el_aro		;8021
L_8024:
	ld a,(0c539h)		;8024
	and a			;8027
	jp p,L_8073		;8028
	ld a,(0c5dfh)		;802b
	ld hl,(0c530h)		;802e   ; Y del balon
	ld de,(0c534h)		;8031   ; mas velocidad Y
	add hl,de			;8035
	ld (0c530h),hl		;8036
	ld hl,(0c532h)		;8039   ; X del balon
	ld de,(0c536h)		;803c   ; mas velocidad X
	add hl,de			;8040
	ld (0c532h),hl		;8041
	bit 6,a		;8044   ; bit 6: pase
	jr z,L_804F		;8046
	ld hl,0c545h		;8048   ; pasos del pase: llega al pasar por 0
	inc (hl)			;804b
	ret m			;804c   ; el pase aun no ha llegado: sigue
	jr L_8073		;804d   ; llego: a 0x8073
L_804F:
	ld hl,(0c53fh)		;804f   ; altura de la mano en vuelo (+0x0F)
	ld de,(0c541h)		;8052
	add hl,de			;8056
	ld (0c53fh),hl		;8057
	ld hl,(0c53ah)		;805a   ; velocidad vertical
	ld a,(0c53ch)		;805d   ; menos la gravedad
	call extiende_signo		;8060
	sbc hl,de		;8063
	ld (0c53ah),hl		;8065
	ex de,hl			;8068
	ld hl,(0c538h)		;8069   ; Z menos velocidad
	and a			;806c
	sbc hl,de		;806d
	ld (0c538h),hl		;806f
	ret			;8072   ; el tiro sigue en el aire
L_8073:
	ld a,(0c5dfh)		;8073
	bit 7,a		;8076
	jr nz,balon_en_el_aro		;8078   ; tiro: llega al aro
	ld a,(0c602h)		;807a
	and a			;807d
	ret nz			;807e
	call balon_quieto		;807f   ; balon parado
	ld a,(0ed65h)		;8082   ; el receptor del pase
	call registro_jugador		;8085
	push hl			;8088
	pop ix		;8089
	call sin_jugada		;808b
	call da_balon		;808e
	ld hl,0c5dfh		;8091
	res 6,(hl)		;8094   ; pase acabado
	ret			;8096
balon_quieto:		; Sin receptor y toda la fisica del balon a cero
	ld a,0ffh		;8097
	ld (0c5f3h),a		;8099
para_balon:		; Fisica del balon a cero (posicion fina, velocidades, altura, pasos)
	xor a			;809c
	ld l,a			;809d
	ld h,a			;809e
	ld (0c53ch),a		;809f   ; gravedad: balon en la mano
	ld (0c530h),a		;80a2   ; fracciones de Y y X
	ld (0c532h),a		;80a5
	ld (0c53fh),hl		;80a8   ; altura de la mano en vuelo
	ld (0c534h),hl		;80ab   ; velocidad Y
	ld (0c536h),hl		;80ae   ; velocidad X
	ld (0c541h),hl		;80b1
	ld (0c538h),hl		;80b4   ; Z
	ld (0c53ah),hl		;80b7   ; velocidad vertical
	ld (0c545h),a		;80ba   ; pasos del pase
	ret			;80bd
poseedor_salto:		; SUPOSICION: en el salto entre dos el balon va al de 0xC5F3
	ld a,(0c5f3h)		;80be
	ld (0c5dfh),a		;80c1
	ret			;80c4
balon_en_el_aro:		; El tiro llega a la canasta: si entra suma los puntos y cae por la red; si no, rebota en el aro
	ld a,(0c602h)		;80c5
	and a			;80c8
	jr nz,poseedor_salto		;80c9
	ld hl,0c5dfh		;80cb
	res 7,(hl)		;80ce   ; ya no esta en vuelo
	ld a,(0cb28h)		;80d0
	and a			;80d3
	jr z,resuelve_tiro		;80d4
	ld a,0ffh		;80d6   ; SUPOSICION: nadie ha tirado
	ld (0c5efh),a		;80d8
resuelve_tiro:		; Canasta o aro segun 0xED61
	ld hl,00000h		;80db
	ld (0c53fh),hl		;80de
	ld (0c541h),hl		;80e1
	ld a,(0ed61h)		;80e4   ; bit 7: fallo
	rlca			;80e7
	jr c,rebote_en_aro		;80e8
	call suma_canasta		;80ea   ; suma la canasta a las estadisticas del tirador
	call pinta_puntos		;80ed   ; puntos al marcador
	call aleatorio		;80f0
	ld a,001h		;80f3   ; pieza 1: canasta
	call arranca_sonido		;80f5
	ld a,001h		;80f8   ; canasta hecha
	ld (0cb28h),a		;80fa
	ld (0c536h),hl		;80fd   ; balon sin velocidad horizontal
	ld (0c534h),hl		;8100
	ld a,0ffh		;8103
	ld (0cb27h),a		;8105
	ld hl,(0c53ah)		;8108   ; cae a un cuarto de la velocidad
	call niega_hl		;810b
	rr h		;810e
	rr l		;8110
	and a			;8112
	rr h		;8113
	rr l		;8115
	call niega_hl		;8117
	ld (0c53ah),hl		;811a
	ld a,004h		;811d   ; cuatro botes en el suelo
	ld (0ed5fh),a		;811f
	ld a,0cch		;8122   ; altura del aro
	ld (0c539h),a		;8124
	neg		;8127
	ld (0ed60h),a		;8129
	ld a,00ah		;812c   ; arranca la animacion de la red
	ld (0c544h),a		;812e
	xor a			;8131
	ld (0c543h),a		;8132
	ret			;8135
rebote_en_aro:		; El balon da en el aro: pieza 7, velocidades a un octavo y rebote segun el tipo de fallo
	ld a,007h		;8136   ; pieza 7: aro
	call arranca_sonido		;8138
	ld a,0cch		;813b   ; altura del aro
	ld (0c539h),a		;813d
	ld hl,(0c534h)		;8140   ; velocidad Y a un octavo
	call octavo		;8143
	ld a,(0ed61h)		;8146   ; tipo de fallo (bits bajos)
	and 07fh		;8149
	cp 001h		;814b
	call z,cero_hl		;814d   ; 1: cae recto
	cp 002h		;8150
	call z,niega_hl		;8152   ; 2: vuelve hacia atras
	ld (0c534h),hl		;8155
	ld hl,(0c536h)		;8158   ; velocidad X a un octavo y al reves
	call octavo		;815b
	call niega_hl		;815e
	ld (0c536h),hl		;8161
	ld hl,(0c53ah)		;8164   ; sube a la mitad de la velocidad de caida
	call niega_hl		;8167
	and a			;816a
	rr h		;816b
	rr l		;816d
	ld (0c53ah),hl		;816f
	ret			;8172
octavo:		; HL/8 con signo
	ld a,h			;8173   ; signo
	and a			;8174
	push af			;8175
	rr h		;8176   ; tres desplazamientos: entre 8
	rr l		;8178
	rr h		;817a
	rr l		;817c
	rr h		;817e
	rr l		;8180
	pop af			;8182
	jp m,L_818B		;8183
	ld a,01fh		;8186   ; positivo: tres bits altos a 0
	and h			;8188
	ld h,a			;8189
	ret			;818a
L_818B:
	ld a,0e0h		;818b
	or h			;818d
	ld h,a			;818e
	ret			;818f
balon_cae:		; Balon sin poseedor ni vuelo: cae y bota en el suelo; tras los botes se queda quieto
	ld a,(0c53ch)		;8190
	and a			;8193
	ret z			;8194
	ld a,(0c5dfh)		;8195
	bit 7,a		;8198   ; tiro en vuelo
	ret nz			;819a
	bit 6,a		;819b   ; pase en vuelo
	ret nz			;819d
	ld a,(0ed61h)		;819e
	bit 7,a		;81a1   ; rebote libre: rueda por la pista
	jr nz,rebote_libre		;81a3
	ld hl,(0c53ah)		;81a5   ; velocidad vertical menos gravedad
	ld a,(0c53ch)		;81a8
	call extiende_signo		;81ab
	and a			;81ae
	sbc hl,de		;81af
	ld (0c53ah),hl		;81b1
	ex de,hl			;81b4
	ld hl,(0c538h)		;81b5   ; Z menos velocidad
	and a			;81b8
	sbc hl,de		;81b9
	ld (0c538h),hl		;81bb
	ret m			;81be   ; sigue en el aire
	ld a,(0ed5fh)		;81bf   ; botes que quedan
	and a			;81c2
	jr z,L_81E0		;81c3
	dec a			;81c5
	cp 003h		;81c6
	ld (0ed5fh),a		;81c8
	jr nz,L_81D2		;81cb
	ld a,002h		;81cd   ; pieza 2: bote del balon
	call arranca_sonido		;81cf
L_81D2:
	ex de,hl			;81d2
	call rebote_amortiguado		;81d3   ; rebota con tres cuartos de la velocidad
	ld (0c53ah),hl		;81d6
	ld hl,00000h		;81d9   ; en el suelo
	ld (0c538h),hl		;81dc
	ret			;81df
L_81E0:
	call para_balon		;81e0   ; sin botes: balon parado
	ld a,0ffh		;81e3
	ld (0ed5fh),a		;81e5
	ld (0ed61h),a		;81e8
	ret			;81eb
rebote_libre:		; Balon suelto tras un fallo: avanza, bota con perdida y se frena; si sale por los lados lo recoge el controlado
	ld hl,(0c532h)		;81ec
	ld de,(0c536h)		;81ef
	add hl,de			;81f3
	ld (0c532h),hl		;81f4
	ld hl,(0c530h)		;81f7   ; Y del balon
	ld de,(0c534h)		;81fa
	add hl,de			;81fe
	ld (0c530h),hl		;81ff
	ld a,h			;8202
	cp 008h		;8203   ; fuera por un lado
	jr c,balon_fuera		;8205
	cp 06ch		;8207   ; fuera por el otro
	jr nc,balon_fuera		;8209
	ld hl,(0c53ah)		;820b   ; cae con la gravedad
	ld a,(0c53ch)		;820e
	call extiende_signo		;8211
	sbc hl,de		;8214
	ld (0c53ah),hl		;8216
	ex de,hl			;8219
	ld hl,(0c538h)		;821a
	and a			;821d
	sbc hl,de		;821e
	ld (0c538h),hl		;8220
	ret m			;8223   ; en el aire
	ld hl,00000h		;8224   ; toca el suelo
	ld (0c538h),hl		;8227
	ex de,hl			;822a
	call rebote_amortiguado		;822b   ; rebote con tres cuartos
	ld (0c53ah),hl		;822e
	ld a,(0cb26h)		;8231   ; SUPOSICION: los que iban a por el balon apuntan a donde bota
	call persigue_balon		;8234
	ld a,(0cb27h)		;8237
	call persigue_balon		;823a
	ld hl,(0c536h)		;823d   ; frena la velocidad X
	call frena		;8240
	ld (0c536h),hl		;8243
	push hl			;8246
	ld hl,(0c534h)		;8247   ; frena la velocidad Y
	call frena		;824a
	ld (0c534h),hl		;824d
	pop de			;8250
	ld a,h			;8251   ; todo a cero: balon parado
	or l			;8252
	or d			;8253
	or e			;8254
	ret nz			;8255
	xor a			;8256
	ld (0c53ch),a		;8257
	ld (0c53ah),hl		;825a
	ret			;825d
persigue_balon:		; Si A es un jugador, le da como destino el balon
	and a			;825e
	ld de,0c530h		;825f
	call p,destino_punto		;8262
	ret			;8265
frena:		; Acerca HL a cero en una unidad
	ld a,h			;8266
	or l			;8267
	ret z			;8268   ; ya es cero
	ld a,h			;8269
	call extiende_signo		;826a   ; DE = 0 o 0xFFFF segun el signo
	ld a,d			;826d
	or e			;826e
	jr nz,L_8272		;826f
	inc de			;8271   ; positivo: DE = 1
L_8272:
	ex de,hl			;8272
	call niega_hl		;8273
	add hl,de			;8276
	ret			;8277
balon_fuera:		; Balon fuera por un lado: lo recibe el controlado del equipo con el balon
	ld a,0ffh		;8278   ; 0xFF: sin tiro pendiente
	ld (0ed61h),a		;827a
	call para_balon		;827d   ; balon parado
	ld (0c536h),hl		;8280
	ld (0c534h),hl		;8283
	call controlado		;8286   ; controlado del equipo con el balon
	ld (0c5dfh),a		;8289   ; pasa a tener el balon
	ret			;828c
rebote_amortiguado:		; HL = tres cuartos de abs(HL)
	ld a,h			;828d
	and a			;828e
	call m,niega_hl		;828f   ; valor absoluto
	push hl			;8292
	srl h		;8293   ; entre 4
	rr l		;8295
	srl h		;8297
	rr l		;8299
	ex de,hl			;829b
	pop hl			;829c
	and a			;829d
	sbc hl,de		;829e   ; menos un cuarto
	ret			;82a0
lanza_pase:		; Balon del poseedor IX al receptor IY: posiciones de la mano, velocidad y numero de pasos
	push ix		;82a1
	ld a,0f0h		;82a3   ; altura del balon en la mano
	ld (0c53dh),a		;82a5
	ld a,(0c5f3h)		;82a8   ; receptor
	ld (0ed65h),a		;82ab
	call registro_jugador		;82ae
	pop de			;82b1
	call xy_dos_registros		;82b2
	call manos		;82b5   ; mas el desplazamiento de las manos
	call balon_en_de		;82b8   ; balon en la mano del que pasa
	call velocidades_vuelo		;82bb   ; velocidades del pase
	ld a,l			;82be
	neg		;82bf
	jr z,L_82C4		;82c1
	dec a			;82c3
L_82C4:
	scf			;82c4
	rra			;82c5
	ld (0c545h),a		;82c6   ; pasos negativos hasta llegar
	ex de,hl			;82c9
	ld a,00fh		;82ca   ; gravedad: balon libre
	ld (0c53ch),a		;82cc
	jp altura_inicial		;82cf
balon_en_de:		; Balon en Y = D y X = E, fracciones a cero
	ld a,d			;82d2
	ld (0c531h),a		;82d3   ; Y del balon
	ld a,e			;82d6
	ld (0c533h),a		;82d7   ; X del balon
	xor a			;82da
	ld (0c530h),a		;82db   ; fracciones a cero
	ld (0c532h),a		;82de
	ret			;82e1
manos:		; Suma a DE y HL el desplazamiento de la mano de IX y de IY segun su direccion
	ld a,(ix+015h)		;82e2   ; direccion del que pasa
	call mano		;82e5   ; desplazamiento de su mano
	ld a,c			;82e8
	add a,e			;82e9   ; X mas dx
	ld e,a			;82ea
	ld a,b			;82eb
	add a,d			;82ec   ; Y mas dy
	ld d,a			;82ed
	ld a,(iy+015h)		;82ee   ; direccion del receptor
	call mano		;82f1   ; desplazamiento de su mano
	ld a,c			;82f4
	add a,l			;82f5
	ld l,a			;82f6
	ld a,b			;82f7
	add a,h			;82f8
	ld h,a			;82f9
	ret			;82fa
mano:		; BC = desplazamiento (dx, dy) de la tabla 0x4C23 para la direccion A
	push de			;82fb
	push hl			;82fc
	add a,a			;82fd   ; dos bytes por direccion
	ld e,a			;82fe
	ld d,000h		;82ff
	ld hl,04c23h		;8301   ; tabla de manos
	add hl,de			;8304
	ld b,(hl)			;8305   ; B = dy
	inc hl			;8306
	ld c,(hl)			;8307   ; C = dx
	pop hl			;8308
	pop de			;8309
	ret			;830a
tiro:		; Lanza el tiro a canasta del jugador en curso: desvio, velocidades y altura inicial
	ld a,(0c602h)		;830b
	and a			;830e
	jr nz,L_831A		;830f
	ld a,(0c53ch)		;8311   ; balon ya libre
	and a			;8314
	ret nz			;8315
	xor a			;8316   ; no hay pasos
	ld (0c607h),a		;8317
L_831A:
	ld a,(0ebd6h)		;831a
	ld (0ed64h),a		;831d   ; SUPOSICION: autor del tiro
	ld a,001h		;8320
	ld (0ed67h),a		;8322   ; SUPOSICION: canasta pendiente de anotar
	call desvio_tiro		;8325   ; desvio del tiro (0 si entra)
	ld de,0c530h		;8328   ; del balon a la canasta
	ld hl,0c5d3h		;832b
	call xy_dos_registros		;832e
	add a,h			;8331   ; desvio en Y (a lo ancho)
	ld h,a			;8332
	call velocidades_vuelo		;8333   ; velocidades Y y X
	push hl			;8336
	ld a,(0c53dh)		;8337
	call subida_mano		;833a   ; velocidad de subida de la mano
	ld (0c541h),hl		;833d
	ld a,00fh		;8340   ; gravedad
	ld (0c53ch),a		;8342
	pop de			;8345
	call velocidad_tiro		;8346   ; velocidad vertical del tiro
	ld (0c53ah),hl		;8349
altura_inicial:		; Altura de la mano a 0xC53F y Z del balon a 0xFFFF
	ld a,(0c53dh)		;834c   ; altura del balon en la mano
	ld d,a			;834f
	ld e,000h		;8350
	ld (0c53fh),de		;8352   ; como altura de vuelo 8.8
	xor a			;8356
	ld (0c53dh),a		;8357   ; balon fuera de la mano
	ld hl,0ffffh		;835a   ; Z = 0xFFFF (la primera version la dejaba a cero)
	ld (0c538h),hl		;835d   ; Z del balon
	ret			;8360
velocidades_vuelo:		; Velocidades Y y X del balon para llegar en (0xED62) pasos; el pase va al doble
	call componentes		;8361
	push hl			;8364
	ld hl,0c5dfh		;8365
	bit 6,(hl)		;8368
	pop hl			;836a
	call nz,dobla		;836b   ; pase: el doble de rapido
	ld (0c534h),de		;836e
	ld (0c536h),hl		;8372
	ld h,a			;8375
	ld l,000h		;8376
	ld de,(0ed62h)		;8378
	call divide16		;837c   ; SUPOSICION: paso fino
	ld a,l			;837f
	and a			;8380
	ret p			;8381
	inc h			;8382
	ret			;8383
dobla:		; HL y DE por 2
	add hl,hl			;8384
	ex de,hl			;8385
	add hl,hl			;8386
	ex de,hl			;8387
	ret			;8388
subida_mano:		; Velocidad de la altura de la mano hasta la del aro (0xCC) o la del salto entre dos (0xF0)
	neg		;8389   ; altura de partida negada
	push af			;838b
	ld a,(0c602h)		;838c   ; salto entre dos?
	and a			;838f
	ld c,0cch		;8390   ; altura del aro
	jr z,L_8396		;8392
	ld c,0f0h		;8394   ; altura del palmeo
L_8396:
	pop af			;8396
	add a,c			;8397   ; diferencia de alturas
	jr z,L_83AA		;8398   ; ninguna: velocidad 0
	push af			;839a
	ld d,a			;839b
	ld e,000h		;839c
	ex de,hl			;839e
	call m,niega_hl		;839f
	call divide16		;83a2   ; entre el tiempo de vuelo
	pop af			;83a5
	call m,niega_hl		;83a6   ; con el signo de la diferencia
	ret			;83a9
L_83AA:
	ld hl,00000h		;83aa
	ret			;83ad
componentes:		; Distancia y rumbo hacia el destino y sus componentes por seno y coseno
	call tiempo_vuelo		;83ae   ; distancia y tiempo
	push af			;83b1
	ld e,b			;83b2
	ld l,c			;83b3
	call angulo		;83b4   ; angulo del vector
	push af			;83b7
	ld hl,(0ed62h)		;83b8   ; tiempo de vuelo
	call por_tabla_c2_desfase		;83bb   ; componente Y
	pop af			;83be
	push hl			;83bf
	ld hl,(0ed62h)		;83c0
	call por_tabla_c2		;83c3   ; componente X
	pop de			;83c6
	pop af			;83c7
	ret			;83c8
por_tabla_c2:		; HL por el valor con signo de la tabla 0xC200 en A (SUPOSICION: seno)
	push hl			;83c9
	call tabla_c2		;83ca
	jr L_83D3		;83cd
por_tabla_c2_desfase:		; HL por el valor de la tabla 0xC200 en A-0x40 (SUPOSICION: coseno)
	push hl			;83cf
	call tabla_c2_desfase		;83d0
L_83D3:
	ld a,d			;83d3   ; signo del factor
	and a			;83d4
	pop hl			;83d5
	push af			;83d6
	ld d,000h		;83d7
	call multiplica16		;83d9   ; tiempo por el factor
	ld l,h			;83dc   ; entre 256
	ld h,000h		;83dd
	pop af			;83df
	ret p			;83e0
	jp niega_hl		;83e1   ; negativo
velocidad_tiro:		; Velocidad vertical a partir del tiempo de vuelo
	call multiplica		;83e4
	and a			;83e7
	rr h		;83e8
	rr l		;83ea
	ret			;83ec
desvio_tiro:		; 0 en el salto entre dos; si no, decide si el tiro entra
	ld a,(0c602h)		;83ed
	and a			;83f0
	jr z,probabilidad_tiro		;83f1
	xor a			;83f3
	ret			;83f4
probabilidad_tiro:		; Probabilidad de canasta segun la distancia, el tirador (roster campo 0x21) y la defensa; A = desvio (0, 3 o -3)
	push ix		;83f5
	pop de			;83f7
	ld hl,0c5d3h		;83f8   ; distancia a la canasta
	call xy_dos_registros		;83fb
	call tiempo_vuelo		;83fe
	push af			;8401
	ld a,(0ecf1h)		;8402
	rrca			;8405
	ld l,(ix+01fh)		;8406
	or l			;8409
	ld (0ed4dh),a		;840a   ; equipo y jugador para 0x71B6
	ld h,000h		;840d
	add hl,hl			;840f
	ex de,hl			;8410
	ld c,021h		;8411   ; campo 0x21: punteria por distancia
	call campo_equipo		;8413
	add hl,de			;8416
	ld b,(hl)			;8417
	ld c,(ix+01ah)		;8418   ; SUPOSICION: punteria del jugador (+0x1A)
	pop af			;841b
	call probabilidad		;841c   ; probabilidad
	call dado_tiro		;841f   ; tira el dado
	jp z,cuenta_tiro		;8422
	call aleatorio		;8425   ; fallo: desvio a un lado o al otro
	bit 7,a		;8428
	jr z,L_842F		;842a
	ld a,003h		;842c
	ret			;842e
L_842F:
	ld a,0fdh		;842f
	ret			;8431
cuenta_tiro:		; Marca el tiro (bit 0 de 0xED5E) y apunta su valor con 0x8BBB
	push af			;8432
	push hl			;8433
	ld hl,0ed5eh		;8434   ; bandera de tiros
	set 0,(hl)		;8437   ; bit 0: hubo tiro
	call anota_tiro		;8439   ; apunta su valor
	pop hl			;843c
	pop af			;843d
	ret			;843e
tiempo_vuelo:		; A = distancia a destino; (0xED62) = pasos de vuelo: 2d+50 en el tiro, 255 en el pase
	call diferencia_xy		;843f   ; diferencias Y y X
	ld b,e			;8442
	ld c,l			;8443
	push bc			;8444
	call distancia		;8445   ; distancia
	pop bc			;8448
	push af			;8449
	ld hl,0c5dfh		;844a
	bit 6,(hl)		;844d   ; pase?
	jr nz,L_8459		;844f
	add a,a			;8451   ; tiro: 2 * distancia + 50
	add a,032h		;8452
	ld l,a			;8454
	ld h,000h		;8455
	jr nc,L_845C		;8457   ; sin desbordar
L_8459:
	ld hl,000ffh		;8459
L_845C:
	ld (0ed62h),hl		;845c
	pop af			;845f
	ret			;8460
probabilidad:		; Probabilidad de 0 a 255 a partir de la distancia y la punteria, menos la defensa
	push af			;8461
	ld a,c			;8462   ; punteria (C)
	cpl			;8463   ; invertida
	srl a		;8464   ; entre 8
	srl a		;8466
	srl a		;8468
	ld l,a			;846a
	pop af			;846b
	add a,l			;846c   ; mas la distancia
	ld e,a			;846d
	push bc			;846e
	call multiplica		;846f   ; por la distancia
	ld b,005h		;8472   ; entre 32
L_8474:
	srl h		;8474
	rr l		;8476
	djnz L_8474		;8478
	pop bc			;847a
	ld e,b			;847b   ; campo del roster (B)
	srl e		;847c   ; entre 8
	srl e		;847e
	srl e		;8480
	ld d,000h		;8482
	add hl,de			;8484   ; suma
	call defensa		;8485   ; penalizacion por la defensa
	ex de,hl			;8488
	ld hl,000ffh		;8489   ; 255 menos la dificultad
	and a			;848c
	sbc hl,de		;848d
	ld a,l			;848f
	ret nc			;8490   ; no negativa
	xor a			;8491   ; imposible: 0
	ret			;8492
defensa:		; Penalizacion del tiro segun la cercania del defensor emparejado (+0x25): (14 - distancia) por 12 y 20 mas si salta. La primera version tambien sumaba 32 si el defensor estaba mas alto
	push hl			;8493
	ld a,(ix+025h)		;8494   ; defensor emparejado
	call registro_jugador		;8497
	push hl			;849a
	pop iy		;849b
	ld e,(iy+001h)		;849d
	ld d,(iy+003h)		;84a0
	ld l,(ix+001h)		;84a3
	ld h,(ix+003h)		;84a6
	call distancia_aprox		;84a9
	pop hl			;84ac
	sub 00eh		;84ad   ; a menos de 14 (la primera version: 13)
	ret nc			;84af
	neg		;84b0
	ld c,a			;84b2   ; C = 14 - distancia
	ld b,00ch		;84b3   ; (14 - d) por 12, sumado en A (la primera version: por 16)
	xor a			;84b5
L_84B6:
	add a,c			;84b6
	djnz L_84B6		;84b7
	ld e,a			;84b9
	ld d,000h		;84ba
	add hl,de			;84bc
	ld a,(iy+00ch)		;84bd   ; el defensor salta: 32 mas
	and a			;84c0   ; el defensor salta?
	ret z			;84c1
	ld de,00014h		;84c2   ; salta: 20 mas (la primera version: 32, y otros 32 si estaba mas alto)
	add hl,de			;84c5
	ret			;84c6
distancia_aprox:		; Distancia aproximada entre dos puntos
	ld a,e			;84c7   ; diferencia de Y
	sub l			;84c8
	ld e,a			;84c9
	ld l,000h		;84ca
	ld a,d			;84cc   ; X del primero
	bit 7,a		;84cd   ; negativa?
	jr z,L_84D4		;84cf
	neg		;84d1
	inc l			;84d3   ; un signo negativo mas
L_84D4:
	ld d,a			;84d4   ; valor absoluto
	ld a,h			;84d5   ; X del segundo
	bit 7,a		;84d6
	jr z,L_84DD		;84d8
	neg		;84da
	inc l			;84dc   ; un signo negativo mas
L_84DD:
	bit 0,l		;84dd
	jr z,L_84E4		;84df
	add a,d			;84e1
	jr L_84E5		;84e2
L_84E4:
	sub d			;84e4
L_84E5:
	ld l,a			;84e5
	jp distancia		;84e6
dado_tiro:		; Compara la probabilidad A con el azar: 0xED61 = 0 canasta, 0x80 + tipo de rebote si falla
	push af			;84e9
	call aleatorio		;84ea   ; avanza el azar
	pop af			;84ed
	ld hl,(0c400h)		;84ee   ; azar en L
	cp l			;84f1   ; probabilidad mayor o igual: canasta
	jr nc,L_84FE		;84f2
	ld a,l			;84f4   ; fallo: tipo de rebote de 0 a 3
	and 003h		;84f5
	jr z,L_84FA		;84f7
	dec a			;84f9   ; tipo 1-3 a 0-2
L_84FA:
	or 080h		;84fa
	jr L_84FF		;84fc
L_84FE:
	xor a			;84fe
L_84FF:
	ld (0ed61h),a		;84ff
	ret			;8502

; ----------------------------------------------------------------------
; ===== Plantillas: demo, jugadores en pista y jugadores al azar =====
; ----------------------------------------------------------------------
prepara_demo:		; Guarda los dos rosters, pone a cero las cuentas de equipo y crea dos equipos de nivel 4 para la demo de 60 segundos
	ld hl,0c617h		;8503   ; rosters de los dos equipos
	ld de,0ed8dh		;8506   ; copia de seguridad en 0xED8D
	ld bc,001d8h		;8509   ; 472 bytes
	ldir		;850c
	xor a			;850e
	ld hl,0c7f3h		;850f   ; cuentas del equipo izquierdo
	ld b,02ch		;8512
L_8514:
	ld (hl),a			;8514
	inc hl			;8515
	djnz L_8514		;8516
	ld hl,0c823h		;8518   ; cuentas del equipo derecho
	ld b,02ch		;851b
L_851D:
	ld (hl),a			;851d
	inc hl			;851e
	djnz L_851D		;851f
	ld hl,00700h		;8521   ; jugadores 0, 1 y 2 en la pista
	ld (0c7f5h),hl		;8524
	ld (0c825h),hl		;8527
	xor a			;852a
	ld (0ed66h),a		;852b   ; primera mitad
	ld a,004h		;852e   ; equipo izquierdo, nivel 4
	ld (0ed4dh),a		;8530
	call genera_equipo		;8533   ; jugadores al azar
	ld a,084h		;8536   ; equipo derecho, nivel 4
	ld (0ed4dh),a		;8538
	call genera_equipo		;853b
	ld hl,(0ed56h)		;853e   ; modos de verdad guardados
	ld (0ef65h),hl		;8541
	ld hl,00202h		;8544   ; los dos equipos de la maquina
	ld (0ed56h),hl		;8547
	ld hl,0003ch		;854a   ; mitad de 60 segundos
	jp L_882C		;854d
fin_demo:		; Devuelve los rosters y los modos guardados por 0x8503
	ld hl,0ed8dh		;8550
	ld de,0c617h		;8553
	ld bc,001d8h		;8556
	ldir		;8559
	ld hl,(0ef65h)		;855b   ; modos de verdad
	ld (0ed56h),hl		;855e
	ret			;8561
crea_jugador:		; Jugador nuevo en HL: nombre de ocho ?, aspecto al azar y habilidades al azar sobre la base del equipo
	push hl			;8562
	ld (0ed4dh),a		;8563   ; jugador y equipo para 0x7183
	ld bc,0001ch		;8566   ; 29 bytes a cero
	ld d,h			;8569
	ld e,l			;856a
	inc de			;856b
	ld (hl),000h		;856c
	ldir		;856e
	pop hl			;8570
	ld b,008h		;8571
L_8573:
	ld (hl),03fh		;8573   ; nombre ????????
	inc hl			;8575
	djnz L_8573		;8576
	call azar_r		;8578   ; aspecto al azar (0-31)
	and 01fh		;857b
	ld (hl),a			;857d
	ld bc,00008h		;857e
	add hl,bc			;8581
	ex de,hl			;8582
	ld c,010h		;8583   ; campo 0x10 del roster
	call campo_jugador		;8585
	ex de,hl			;8588
	ld a,(de)			;8589
	ld (hl),a			;858a
	ld b,a			;858b
	call azar_b		;858c   ; primera habilidad al azar
	call maximo_tres		;858f
	call azar_r		;8592   ; segunda habilidad: base mas azar menos 16
	and 01fh		;8595
	ld c,a			;8597
	ld a,(de)			;8598
	add a,c			;8599
	sub 010h		;859a
	jr nc,L_859F		;859c
	ld a,(de)			;859e
L_859F:
	ld b,a			;859f
	ld (hl),a			;85a0   ; segunda habilidad
	call azar_d		;85a1   ; y sus topes
	call maximo_tres		;85a4
	ld a,c			;85a7   ; otro azar: el complemento
	cpl			;85a8
	and 01fh		;85a9
	inc a			;85ab
	ld c,a			;85ac
	ld a,(de)			;85ad   ; base del equipo
	add a,c			;85ae
	sub 010h		;85af   ; menos 16
	jr nc,L_85B4		;85b1
	ld a,(de)			;85b3   ; sin bajar de la base
L_85B4:
	ld b,a			;85b4
	ld (hl),a			;85b5
	call azar_f		;85b6   ; tope de la habilidad
	cp b			;85b9
	jr nc,L_85C1		;85ba
	dec hl			;85bc
	dec hl			;85bd
	ld (hl),a			;85be
	inc hl			;85bf
	inc hl			;85c0
L_85C1:
	inc de			;85c1
	inc de			;85c2
	ld a,(de)			;85c3
	ld (hl),a			;85c4
	ld b,a			;85c5
	call azar_h		;85c6   ; tercera habilidad
	call maximo_tres		;85c9
	ld a,(de)			;85cc
	add a,008h		;85cd   ; y su tope: 8 mas
	jr nc,L_85D3		;85cf
	ld a,0ffh		;85d1
L_85D3:
	ld b,a			;85d3
	ld (hl),a			;85d4   ; tope de la tercera
	call azar_j		;85d5   ; ultimo byte al azar
	dec hl			;85d8
	ld a,(hl)			;85d9   ; habilidad anterior
	cp b			;85da   ; la mayor de las dos
	ret c			;85db
	dec hl			;85dc
	ld (hl),a			;85dd
	ret			;85de
maximo_tres:		; Si A es menor que B lo guarda tres bytes atras; DE avanza tres
	cp b			;85df   ; A menor que B?
	jr nc,L_85E9		;85e0
	dec hl			;85e2   ; guarda A tres atras
	dec hl			;85e3
	dec hl			;85e4
	ld (hl),a			;85e5
	inc hl			;85e6
	inc hl			;85e7
	inc hl			;85e8
L_85E9:
	inc de			;85e9
	inc de			;85ea
	inc de			;85eb
	ret			;85ec
jugadores_en_pista:		; Copia a los seis registros las caracteristicas de los jugadores en pista, sus camisetas y su piel y pelo
	ld hl,(0c7f5h)		;85ed   ; SUPOSICION: bandera de mascara no vacia
	ld a,h			;85f0
	or l			;85f1
	ld (0c7f5h),a		;85f2
	ld hl,(0c825h)		;85f5
	ld a,h			;85f8
	or l			;85f9
	ld (0c825h),a		;85fa
	xor a			;85fd
	ld (0ed4dh),a		;85fe   ; equipo izquierdo
	ld a,(0c7f6h)		;8601   ; mascara de jugadores en pista
	ld c,a			;8604
	ld ix,0c410h		;8605   ; tres registros del equipo izquierdo
	ld hl,0c62ah		;8609   ; campo 0x0F del primer jugador del roster
	call copia_caracteristicas		;860c
	ld a,080h		;860f   ; equipo derecho
	ld (0ed4dh),a		;8611
	ld a,(0c826h)		;8614
	ld c,a			;8617
	ld ix,0c4a0h		;8618
	ld hl,0c716h		;861c
	call copia_caracteristicas		;861f
	ld hl,0c56fh		;8622   ; color del sprite 3 (camiseta) del jugador 0
	ld a,(0c7f2h)		;8625   ; color del equipo izquierdo
	call camisetas		;8628
	ld a,(0c822h)		;862b   ; color del equipo derecho
	call camisetas		;862e
	ld hl,0c42fh		;8631   ; +0x1F: jugador del roster
	ld ix,0c560h		;8634   ; sombra de atributos
	ld b,003h		;8638   ; tres del equipo izquierdo
L_863A:
	ld a,(hl)			;863a
	call piel_y_pelo		;863b
	djnz L_863A		;863e
	ld b,003h		;8640
L_8642:
	ld a,(hl)			;8642
	set 7,a		;8643   ; bit 7: equipo derecho
	call piel_y_pelo		;8645
	djnz L_8642		;8648
	ret			;864a
piel_y_pelo:		; Colores de piel (sprites 0 y 1) y pelo (sprite 2) del jugador A segun su aspecto (tabla 0x7439)
	push hl			;864b
	ld (0ed4dh),a		;864c
	ld c,008h		;864f   ; campo 8: aspecto
	call campo_jugador		;8651
	ld l,(hl)			;8654
	ld h,000h		;8655
	add hl,hl			;8657
	ld de,07439h		;8658   ; parejas (piel, pelo)
	add hl,de			;865b
	ld a,(hl)			;865c
	inc hl			;865d
	ld c,(hl)			;865e
	pop hl			;865f
	ld (ix+003h),a		;8660   ; piel del sprite 0
	ld (ix+007h),a		;8663   ; y del sprite 1
	ld (ix+00bh),c		;8666   ; pelo del sprite 2
	ld de,00030h		;8669
	add hl,de			;866c
	ld de,00010h		;866d   ; siguiente sombra de 16 bytes
	add ix,de		;8670
	ret			;8672
camisetas:		; Nibble alto del color del equipo como color del sprite de camiseta de tres jugadores
	rra			;8673
	rra			;8674
	rra			;8675
	rra			;8676
	and 00fh		;8677
	ld b,003h		;8679   ; tres jugadores
	ld de,00010h		;867b
L_867E:
	ld (hl),a			;867e
	add hl,de			;867f
	djnz L_867E		;8680
	ret			;8682
copia_caracteristicas:		; Para cada bit de C, copia al registro IX los campos del jugador del roster HL
	ld b,008h		;8683   ; ocho del roster
	ld e,000h		;8685
siguiente_del_roster:		; Bit del jugador: si esta en pista copia sus campos al siguiente registro
	srl c		;8687   ; bit del jugador
	jr nc,L_86C2		;8689   ; en el banquillo
	push hl			;868b
	ld (ix+01fh),e		;868c   ; +0x1F: numero en el roster
	ld a,(hl)			;868f   ; campo 0x0F a +0x19
	ld (ix+019h),a		;8690
	inc hl			;8693
	ld a,(hl)			;8694   ; campo 0x10 a +0x1A
	ld (ix+01ah),a		;8695
	inc hl			;8698
	inc hl			;8699
	inc hl			;869a
	ld a,(hl)			;869b   ; SUPOSICION: campo 0x13 a +0x1C (salto)
	ld (ix+01ch),a		;869c
	inc hl			;869f
	inc hl			;86a0
	inc hl			;86a1
	ld a,(hl)			;86a2   ; SUPOSICION: campo 0x16 a +0x1B (rapidez)
	ld (ix+01bh),a		;86a3
	inc hl			;86a6
	inc hl			;86a7
	ld a,(hl)			;86a8   ; campo 0x18 a +0x1D (SUPOSICION: robo)
	ld (ix+01dh),a		;86a9
	push bc			;86ac
	ld c,010h		;86ad   ; cuenta del equipo 0x10 + jugador
	call campo_equipo		;86af
	pop bc			;86b2
	ld d,000h		;86b3
	add hl,de			;86b5
	ld a,(hl)			;86b6
	ld (ix+01eh),a		;86b7   ; a +0x1E
	pop hl			;86ba
	push de			;86bb
	ld de,00030h		;86bc   ; siguiente registro
	add ix,de		;86bf
	pop de			;86c1
L_86C2:
	push de			;86c2
	ld de,0001dh		;86c3   ; siguiente jugador del roster
	add hl,de			;86c6
	pop de			;86c7
	inc e			;86c8
	djnz siguiente_del_roster		;86c9
	ret			;86cb
azar_a:		; Tres bytes al azar: 0, 0x14-0x23, 0x80-0xFF, 0xC0-0xFF
	xor a			;86cc
	ld (hl),a			;86cd   ; 0
	inc hl			;86ce
	call azar_r		;86cf   ; 0x14-0x23
	and 00fh		;86d2
	add a,014h		;86d4
	ld (hl),a			;86d6
azar_b:		; Dos bytes al azar: 0x80-0xFF y 0xC0-0xFF
	inc hl			;86d7
	call azar_r		;86d8   ; 0x80-0xFF
	and 07fh		;86db
	add a,080h		;86dd
	ld (hl),a			;86df
	inc hl			;86e0
	call azar_r		;86e1   ; 0xC0-0xFF
	and 03fh		;86e4
	add a,0c0h		;86e6
	ld (hl),a			;86e8
	inc hl			;86e9
	ret			;86ea
azar_c:		; Tres bytes al azar: 0x0A-0x19, 0x08-0x0F, 0xC0-0xFF
	call azar_r		;86eb
	and 00fh		;86ee
	add a,00ah		;86f0
	ld (hl),a			;86f2
azar_d:		; Dos bytes al azar: 0x08-0x0F y 0xC0-0xFF
	inc hl			;86f3
	call azar_r		;86f4   ; 0x08-0x0F
	and 007h		;86f7
	add a,008h		;86f9
	ld (hl),a			;86fb
	inc hl			;86fc
	call azar_r		;86fd   ; 0xC0-0xFF
	and 03fh		;8700
	add a,0c0h		;8702
	ld (hl),a			;8704
	inc hl			;8705
	ret			;8706
azar_e:		; Dos bytes al azar: 0x0A-0x19 y 0xC0-0xFF
	call azar_r		;8707
	and 00fh		;870a
	add a,00ah		;870c
	ld (hl),a			;870e
azar_f:		; Un byte al azar 0xC0-0xFF
	inc hl			;870f
	call azar_r		;8710   ; 0xC0-0xFF
	and 03fh		;8713
	add a,0c0h		;8715
	ld (hl),a			;8717
	inc hl			;8718
	ret			;8719
azar_g:		; Tres bytes al azar: 0x14-0x23, 0x04-0x07, 0x60-0x7F
	call azar_r		;871a
	and 00fh		;871d
	add a,014h		;871f
	ld (hl),a			;8721
azar_h:		; Dos bytes al azar: 0x04-0x07 y 0x60-0x7F
	inc hl			;8722
	call azar_r		;8723   ; 0x04-0x07
	and 003h		;8726
	add a,004h		;8728
	ld (hl),a			;872a
	inc hl			;872b
	call azar_r		;872c   ; 0x60-0x7F
	and 01fh		;872f
	add a,060h		;8731
	ld (hl),a			;8733
	inc hl			;8734
	ret			;8735
azar_i:		; Dos bytes al azar: 0x6E-0xAD y 0x32-0x51
	call azar_r		;8736
	and 03fh		;8739
	add a,06eh		;873b
	ld (hl),a			;873d
azar_j:		; Un byte al azar 0x32-0x51
	inc hl			;873e
	call azar_r		;873f   ; 0x32-0x51
	and 01fh		;8742
	add a,032h		;8744
	ld (hl),a			;8746
	inc hl			;8747
	ret			;8748
genera_equipo:		; Ocho jugadores de la maquina: aspecto al azar y habilidades segun el nivel de (0xED4D)
	ld a,(0ed4dh)		;8749
	push af			;874c
	call opcion_cero		;874d   ; SUPOSICION: nombres de la maquina
	ld c,008h		;8750   ; campo 8 del primer jugador
	call campo_jugador		;8752
	pop af			;8755
	ld (0ed4dh),a		;8756
	ld b,008h		;8759   ; ocho jugadores
L_875B:
	push bc			;875b
	push hl			;875c
	call azar_r		;875d   ; aspecto al azar
	and 01fh		;8760
	ld (hl),a			;8762
	ld de,00008h		;8763
	add hl,de			;8766
	ld de,01e1eh		;8767   ; campo 0x10: 30 por nivel mas 30
	call segun_nivel		;876a
	ld de,01e14h		;876d   ; campo 0x13: 30 por nivel mas 20
	call segun_nivel		;8770
	ld de,01e19h		;8773   ; campo 0x16: 30 por nivel mas 25
	call segun_nivel		;8776
	dec hl			;8779
	dec hl			;877a
	ld (hl),a			;877b   ; tope del 0x16 en 0x17
	inc hl			;877c
	ld de,00a14h		;877d   ; campo 0x18: 10 por nivel mas 20 (la primera version: mas 30)
	call segun_nivel		;8780
	ld (hl),005h		;8783   ; campo 0x1B = 5 (la primera version: 10)
	pop hl			;8785
	pop bc			;8786
	ld de,0001dh		;8787   ; siguiente jugador
	add hl,de			;878a
	djnz L_875B		;878b
	ret			;878d
segun_nivel:		; (HL) = D * nivel + E; HL avanza tres
	ld a,(0ed4dh)		;878e   ; nivel en los bits bajos
	and 00fh		;8791
	jr z,L_879B		;8793
	ld c,a			;8795
	xor a			;8796
L_8797:
	add a,d			;8797
	dec c			;8798
	jr nz,L_8797		;8799
L_879B:
	add a,e			;879b   ; mas la base E
	ld (hl),a			;879c   ; al campo
	inc hl			;879d
	inc hl			;879e
	inc hl			;879f
	ret			;87a0

; ----------------------------------------------------------------------
; ===== Equipos, reloj y fatiga =====
; ----------------------------------------------------------------------
inicia_equipos:		; Equipos de salida ABC y DEF, opciones por defecto y textos de las teclas de funcion borrados
	ld hl,0f87fh		;87a1   ; FNKSTR: textos de las teclas de funcion
	push hl			;87a4
	ld (hl),000h		;87a5
	ld de,0f880h		;87a7
	ld bc,0009fh		;87aa
	ldir		;87ad
	pop hl			;87af
	ld (hl),07fh		;87b0   ; SUPOSICION: marca para la grabacion en cinta
	ld hl,0c617h		;87b2   ; nombre del equipo izquierdo
	ld a,041h		;87b5   ; ABC
	ld b,003h		;87b7
L_87B9:
	ld (hl),a			;87b9
	inc hl			;87ba
	inc a			;87bb
	djnz L_87B9		;87bc
	ld hl,0c703h		;87be   ; nombre del equipo derecho: DEF
	ld b,003h		;87c1
L_87C3:
	ld (hl),a			;87c3
	inc hl			;87c4
	inc a			;87c5
	djnz L_87C3		;87c6
	xor a			;87c8
	ld (0ed5bh),a		;87c9   ; COLOR OF COURT = 0
	ld (0ed56h),a		;87cc   ; modos de los dos equipos a 0
	ld (0ed57h),a		;87cf
	inc a			;87d2
	ld (0ed6bh),a		;87d3   ; reloj parado
	ld a,001h		;87d6
	ld (0ed5ah),a		;87d8   ; LENGTH OF HALF = 1
	ld a,(06baeh)		;87db   ; color del equipo izquierdo (0x6BAE)
	ld (0c7f2h),a		;87de
	ld a,(06bafh)		;87e1   ; color del equipo derecho (0x6BAF)
	ld (0c822h),a		;87e4
	ld hl,0c61bh		;87e7   ; nombres de jugador del izquierdo en blanco
	call nombres_en_blanco		;87ea
	ld hl,0c707h		;87ed   ; y los del derecho
	call nombres_en_blanco		;87f0
	ld a,0d0h		;87f3   ; sprites ocultos
	ld hl,01b00h		;87f5
	call 0004dh		;87f8   ; BIOS WRTVRM - Writes data in VRAM
	ld hl,00002h		;87fb   ; modo 2 el izquierdo, 0 el derecho
	ld (0ed56h),hl		;87fe
	ld a,001h		;8801
	ld (0c61ah),a		;8803   ; nivel 1 del equipo izquierdo
	dec a			;8806
	ld (0ed4dh),a		;8807
	call genera_equipo		;880a
	ld a,080h		;880d
	jp roster_nuevo		;880f
inicia_reloj_partido:		; Primera mitad, cansancio al azar y reloj de la mitad
	xor a			;8812
	ld (0ed66h),a		;8813   ; mitad 0
	call azar_jugadores		;8816   ; valores al azar de los jugadores
inicia_mitad:		; Reloj de la mitad: (LENGTH OF HALF + 1) * 300 segundos, faltas de equipo a cero
	ld a,001h		;8819
	ld (0ed6bh),a		;881b   ; reloj parado
	ld a,(0ed5ah)		;881e   ; LENGTH OF HALF
	inc a			;8821
	ld hl,00000h		;8822
	ld de,0012ch		;8825   ; 300 segundos por paso
L_8828:
	add hl,de			;8828
	dec a			;8829
	jr nz,L_8828		;882a
L_882C:
	ld (0ed69h),hl		;882c   ; tiempo de la mitad
	ld hl,0003ch		;882f   ; 60 cuadros por segundo
	ld (0ed72h),hl		;8832
	call desactiva_cuentas		;8835   ; cuentas de 10 y 30 segundos desactivadas
	xor a			;8838
	ld (0c7f4h),a		;8839   ; faltas del equipo izquierdo
	ld (0c824h),a		;883c   ; faltas del equipo derecho
	ld (0ed67h),a		;883f   ; sin tiro pendiente
	ld (0ed68h),a		;8842   ; la mitad no ha acabado
	call jugadores_en_pista		;8845
	jp patrones_pista		;8848
nombres_en_blanco:		; Ocho nombres de 8 caracteres 0x6B en el roster HL (pasos de 29)
	ld de,0001dh		;884b
	ld c,008h		;884e
L_8850:
	push hl			;8850
	ld b,008h		;8851
L_8853:
	ld (hl),06bh		;8853   ; espacio de nombre
	inc hl			;8855
	djnz L_8853		;8856
	pop hl			;8858   ; siguiente jugador
	add hl,de			;8859
	dec c			;885a
	jr nz,L_8850		;885b
	ret			;885d
azar_jugadores:		; Ocho valores al azar de 0x10 a 0x1F en 0xC7FF y 0xC82F
	ld hl,0c7ffh		;885e
	call azar_ocho		;8861
	ld hl,0c82fh		;8864
azar_ocho:		; Ocho valores al azar de 0x10 a 0x1F en HL
	ld b,008h		;8867
L_8869:
	call azar_r		;8869   ; azar
	and 00fh		;886c
	add a,010h		;886e   ; 0x10-0x1F
	ld (hl),a			;8870
	inc hl			;8871
	djnz L_8869		;8872
	ret			;8874
reloj:		; Interrupcion: temporizadores de 0xED72 (seis de 16 bits), cuenta atras de 0xED7E/0xED80 y segundero del partido
	ld a,(0ed6bh)		;8875   ; reloj parado: solo las cuentas atras
	and a			;8878
	jr nz,L_88A3		;8879
	ld a,(0ed67h)		;887b
	and a			;887e
	call nz,desactiva_cuentas		;887f   ; SUPOSICION: tiro pendiente
	ld hl,0ed72h		;8882   ; seis temporizadores de 16 bits
	ld de,0ed6ch		;8885   ; con su bandera de vencido
	ld b,006h		;8888
L_888A:
	ld a,(de)			;888a
	and a			;888b
	jr nz,L_889E		;888c   ; ya vencido
	push de			;888e
	ld e,(hl)			;888f
	inc hl			;8890
	ld d,(hl)			;8891
	dec de			;8892
	ld (hl),d			;8893
	dec hl			;8894
	ld (hl),e			;8895
	ld a,d			;8896
	or e			;8897
	pop de			;8898
	jr nz,L_889E		;8899
	ld a,001h		;889b   ; vencido: bandera a 1
	ld (de),a			;889d
L_889E:
	inc de			;889e
	inc hl			;889f
	inc hl			;88a0
	djnz L_888A		;88a1
L_88A3:
	ld b,002h		;88a3   ; dos cuentas atras: 0xED7E y 0xED80
	ld hl,0ed7eh		;88a5
L_88A8:
	ld e,(hl)			;88a8   ; cuenta atras de 16 bits
	inc hl			;88a9
	ld d,(hl)			;88aa
	ld a,d			;88ab
	or e			;88ac
	jr z,L_88B4		;88ad   ; ya a cero
	dec de			;88af   ; un cuadro menos
	ld (hl),d			;88b0
	dec hl			;88b1
	ld (hl),e			;88b2
	inc hl			;88b3
L_88B4:
	inc hl			;88b4
	djnz L_88A8		;88b5
	ld a,(0ed72h)		;88b7   ; cuadros del segundo
	ld b,a			;88ba
	and 007h		;88bb
	jr nz,L_88C3		;88bd
	inc a			;88bf
	ld (0ed86h),a		;88c0   ; aviso cada 8 cuadros
L_88C3:
	ld a,b			;88c3
	and 01fh		;88c4
	jr nz,L_88CC		;88c6
	inc a			;88c8
	ld (0ed87h),a		;88c9   ; aviso cada 32 cuadros (formacion)
L_88CC:
	ld hl,(0ed69h)		;88cc   ; tiempo de la mitad
	ld a,h			;88cf
	or l			;88d0
	jr z,fin_por_tiempo		;88d1
	ld a,(0ed6ch)		;88d3   ; ha pasado un segundo?
	dec a			;88d6
	ret nz			;88d7
	ld hl,0003ch		;88d8   ; otros 60 cuadros
	ld (0ed72h),hl		;88db
	ld (0ed6ch),a		;88de
	inc a			;88e1
	ld (0ed5ch),a		;88e2   ; hay que repintar el tiempo
	ld hl,(0ed69h)		;88e5   ; un segundo menos
	dec hl			;88e8
	ld (0ed69h),hl		;88e9
	ld a,h			;88ec
	or l			;88ed
	jr nz,fatiga		;88ee
	inc a			;88f0
	ld (0ed6bh),a		;88f1   ; tiempo agotado: reloj parado
fin_por_tiempo:		; Sin tiempo: la mitad acaba cuando no hay tiro en el aire ni desplazamiento de ventana
	ld a,(0ed67h)		;88f4
	and a			;88f7
	ret nz			;88f8
	ld a,(0c5dfh)		;88f9
	and 018h		;88fc
	ret nz			;88fe
	inc a			;88ff
	ld (0ed68h),a		;8900   ; fin de la mitad
	ret			;8903
fatiga:		; Cada segundo de juego: los ocho jugadores de cada equipo ganan cansancio en la pista y lo pierden en el banquillo
	ld a,(0ed6bh)		;8904
	and a			;8907
	ret nz			;8908
	ld a,(0c7f6h)		;8909   ; jugadores en pista del izquierdo (bits)
	ld hl,0c636h		;890c   ; campo de fatiga del roster
	ld de,0c80fh		;890f   ; cansancio acumulado
	call fatiga_equipo		;8912
	ld a,(0c826h)		;8915   ; los del equipo derecho
	ld hl,0c722h		;8918
	ld de,0c83fh		;891b
fatiga_equipo:		; Ocho jugadores: bit a 1 suma, a 0 resta, con tope 0xFF00 y 0
	ld b,008h		;891e
L_8920:
	rra			;8920   ; bit del jugador
	push bc			;8921
	push af			;8922
	push hl			;8923
	ld c,(hl)			;8924
	ld b,000h		;8925
	ld a,(de)			;8927
	ld l,a			;8928
	inc de			;8929
	ld a,(de)			;892a
	ld h,a			;892b
	jr nc,descansa		;892c   ; en el banquillo: descansa
	add hl,bc			;892e
	jr nc,L_8934		;892f
	ld hl,0ff00h		;8931   ; tope
L_8934:
	ld a,h			;8934   ; byte alto
	ld (de),a			;8935
	dec de			;8936
	ld a,l			;8937   ; byte bajo
	ld (de),a			;8938
	pop hl			;8939
	pop af			;893a
	ld bc,0001dh		;893b   ; siguiente jugador del roster
	add hl,bc			;893e
	pop bc			;893f
	inc de			;8940   ; siguiente contador
	inc de			;8941
	djnz L_8920		;8942
	ret			;8944
descansa:		; Resta sin bajar de cero
	sbc hl,bc		;8945
	jr nc,L_8934		;8947
	ld hl,00000h		;8949
	jr L_8934		;894c
desactiva_cuentas:		; Cuentas de 0xED6D-0xED70 a 2 (desactivadas) y umbrales de 0x8964 a 0xED74
	ld hl,0ed6dh		;894e
	ld b,004h		;8951
L_8953:
	ld (hl),002h		;8953   ; cuentas 0xED6D-0xED70 desactivadas (2)
	inc hl			;8955
	djnz L_8953		;8956
	ld hl,08964h		;8958   ; umbrales de 0x8964
	ld de,0ed74h		;895b   ; a 0xED74
	ld bc,00008h		;895e
	ldir		;8961
	ret			;8963

; ----------------------------------------------------------------------
; DATOS umbrales_ed86: Cuatro palabras (210, 330, 630 y 1830) que 0x894E copia
;   a 0xED74-0xED7B
;   0x8964..0x896c  (8 bytes)
DATA_umbrales_ed86:
	defw 000d2h,0014ah,00276h,00726h	; 8964

; ======================================================================
; CODIGO 0x896c..0x8ddf  (1139 bytes)
; ======================================================================


guarda_resultado:		; Suma el partido a las estadisticas de los equipos con modo 0: partidos, puntos, faltas
	ld a,(0ed56h)		;896c
	and a			;896f
	jr nz,L_8998		;8970
	ld a,(0c7f3h)		;8972   ; puntos propios
	ld b,a			;8975
	ld a,(0c823h)		;8976   ; y del rival
	call resultado		;8979   ; 0xED85 = 1 si gano
	ld de,0c807h		;897c
	ld hl,0c626h		;897f
	call suma_ocho		;8982   ; puntos de los ocho jugadores
	ld a,(0c7f5h)		;8985   ; faltas
	ld hl,0c628h		;8988
	call cuenta_partidos		;898b
	ld ix,0c61bh		;898e
	ld hl,0c7f7h		;8992
	call mejora_equipo		;8995
L_8998:
	ld a,(0ed57h)		;8998   ; equipo derecho
	and a			;899b
	ret nz			;899c
	ld a,(0c823h)		;899d   ; puntos del derecho
	ld b,a			;89a0
	ld a,(0c7f3h)		;89a1   ; contra los del izquierdo
	call resultado		;89a4   ; ganado o perdido
	ld de,0c837h		;89a7   ; puntos de los ocho
	ld hl,0c712h		;89aa
	call suma_ocho		;89ad
	ld a,(0c825h)		;89b0   ; faltas
	ld hl,0c714h		;89b3
	call cuenta_partidos		;89b6   ; partidos jugados
	ld ix,0c707h		;89b9   ; roster derecho
	ld hl,0c827h		;89bd
mejora_equipo:		; Experiencia y caracteristicas de los ocho jugadores tras el partido
	push af			;89c0
	call experiencia		;89c1   ; experiencia
	pop af			;89c4
	call mejora_13		;89c5   ; y las cuatro caracteristicas
	call mejora_16		;89c8
	call mejora_18		;89cb
	jp mejora_1b		;89ce
suma_ocho:		; Suma ocho bytes de DE a ocho contadores de 16 bits del roster HL
	ld b,008h		;89d1
L_89D3:
	ld a,(de)			;89d3   ; contador del roster
	add a,(hl)			;89d4   ; mas el valor
	ld (hl),a			;89d5
	jr nc,L_89DB		;89d6
	inc hl			;89d8
	inc (hl)			;89d9   ; acarreo al byte alto
	dec hl			;89da
L_89DB:
	push de			;89db
	ld de,0001dh		;89dc   ; siguiente jugador del roster
	add hl,de			;89df
	pop de			;89e0
	inc de			;89e1   ; siguiente valor
	djnz L_89D3		;89e2
	ret			;89e4
cuenta_partidos:		; Suma 1 al contador de 16 bits de cada jugador cuyo bit de A este a 1 (roster HL, pasos de 29)
	push af			;89e5
	ld b,008h		;89e6
L_89E8:
	rra			;89e8   ; bit del jugador
	jr nc,L_89F2		;89e9
	ld e,(hl)			;89eb
	inc hl			;89ec
	ld d,(hl)			;89ed
	inc de			;89ee   ; uno mas
	ld (hl),d			;89ef
	dec hl			;89f0
	ld (hl),e			;89f1
L_89F2:
	ld de,0001dh		;89f2
	add hl,de			;89f5
	djnz L_89E8		;89f6
	pop af			;89f8
	ret			;89f9
resultado:		; (0xED85) = 1 si el equipo gano (A, puntos del rival, menor que B, los suyos); 0 si no
	cp b			;89fa
	ld a,000h		;89fb
	jr nc,L_8A00		;89fd
	inc a			;89ff
L_8A00:
	ld (0ed85h),a		;8a00
	ret			;8a03
experiencia:		; SUPOSICION: tras el partido suma la experiencia de los ocho jugadores y recalcula su habilidad (+0x0F/+0x10)
	push ix		;8a04
	ld a,(0ed85h)		;8a06
	ld d,a			;8a09
	ld b,008h		;8a0a
L_8A0C:
	push bc			;8a0c
	push hl			;8a0d
	push de			;8a0e
	ld a,(hl)			;8a0f
	add a,(ix+009h)		;8a10   ; SUPOSICION: experiencia acumulada (+9/+0x0A)
	ld (ix+009h),a		;8a13
	jr nc,L_8A1B		;8a16
	inc (ix+00ah)		;8a18
L_8A1B:
	ld a,(hl)			;8a1b
	ld e,(ix+011h)		;8a1c
	call multiplica		;8a1f   ; por el factor del jugador (+0x11)
	ld e,(ix+00fh)		;8a22
	ld d,(ix+010h)		;8a25
	add hl,de			;8a28
	ld a,h			;8a29   ; A = byte alto del nuevo valor
	jr nc,L_8A2E		;8a2a   ; sin acarreo: vale
	ld a,0ffh		;8a2c   ; con acarreo: 0xFF (la primera version no lo cortaba)
L_8A2E:
	cp (ix+012h)		;8a2e   ; contra el tope (+0x12)
	jr c,L_8A36		;8a31
	ld a,(ix+012h)		;8a33
L_8A36:
	pop de			;8a36
	inc d			;8a37
	dec d			;8a38
	jr nz,L_8A40		;8a39
	sub 004h		;8a3b   ; tras perder, 4 menos (la primera version: 10)
	jr nc,L_8A40		;8a3d
	xor a			;8a3f
L_8A40:
	ld (ix+010h),a		;8a40
	ld (ix+00fh),l		;8a43
	ld bc,0001dh		;8a46   ; siguiente jugador del roster
	add ix,bc		;8a49
	pop hl			;8a4b
	pop bc			;8a4c
	inc hl			;8a4d
	djnz L_8A0C		;8a4e
	pop ix		;8a50
	ret			;8a52
mejora_13:		; SUPOSICION: campo +0x13 de los jugadores en pista sube +0x14 hasta +0x15; tras perder baja 4
	push ix		;8a53
	push af			;8a55
	ld c,a			;8a56
	ld b,008h		;8a57
L_8A59:
	ld a,(ix+013h)		;8a59   ; campo 0x13
	inc d			;8a5c   ; D = 0: no ha ganado
	dec d			;8a5d
	jr nz,L_8A69		;8a5e
	rr c		;8a60
	sub 004h		;8a62   ; baja 4
	jr nc,L_8A7C		;8a64
	xor a			;8a66
	jr L_8A7C		;8a67
L_8A69:
	rr c		;8a69
	jr nc,L_8A7C		;8a6b
	add a,(ix+014h)		;8a6d   ; sube (+0x14)
	jr nc,L_8A74		;8a70   ; con acarreo: 0xFF
	ld a,0ffh		;8a72
L_8A74:
	cp (ix+015h)		;8a74   ; contra el tope (+0x15)
	jr c,L_8A7C		;8a77
	ld a,(ix+015h)		;8a79
L_8A7C:
	ld (ix+013h),a		;8a7c   ; campo 0x13 nuevo
	push bc			;8a7f   ; guarda BC
	ld bc,0001dh		;8a80   ; siguiente jugador del roster
	add ix,bc		;8a83
	pop bc			;8a85
	djnz L_8A59		;8a86   ; los ocho
L_8A88:
	pop af			;8a88
	pop ix		;8a89
	ret			;8a8b
mejora_16:		; SUPOSICION: campo +0x16 sube 10 hasta +0x17; tras perder baja 2
	push ix		;8a8c
	push af			;8a8e
	ld c,a			;8a8f
	ld b,008h		;8a90
L_8A92:
	ld a,(ix+016h)		;8a92   ; campo 0x16
	inc d			;8a95   ; D = 0: no ha ganado
	dec d			;8a96
	jr nz,L_8AA2		;8a97
	rr c		;8a99   ; baja 2
	sub 002h		;8a9b
	jr nc,L_8AB4		;8a9d
	xor a			;8a9f
	jr L_8AB4		;8aa0
L_8AA2:
	rr c		;8aa2
	jr nc,L_8AB4		;8aa4
	add a,00ah		;8aa6   ; sube 10
	jr nc,L_8AAC		;8aa8
	ld a,0ffh		;8aaa   ; con acarreo: 0xFF
L_8AAC:
	cp (ix+017h)		;8aac   ; contra el tope (+0x17)
	jr c,L_8AB4		;8aaf
	ld a,(ix+017h)		;8ab1
L_8AB4:
	ld (ix+016h),a		;8ab4
	push bc			;8ab7
	ld bc,0001dh		;8ab8   ; siguiente jugador del roster
	add ix,bc		;8abb
	pop bc			;8abd
	djnz L_8A92		;8abe
	jr L_8A88		;8ac0
mejora_18:		; SUPOSICION: campo +0x18 sube +0x19 hasta +0x1A; tras perder baja 2
	push ix		;8ac2
	push af			;8ac4
	ld c,a			;8ac5
	ld b,008h		;8ac6
L_8AC8:
	ld a,(ix+018h)		;8ac8   ; campo 0x18
	inc d			;8acb
	dec d			;8acc
	jr nz,L_8AD8		;8acd
	rr c		;8acf
	sub 002h		;8ad1   ; sin ganar: baja 2
	jr nc,L_8AEB		;8ad3
	xor a			;8ad5
	jr L_8AEB		;8ad6
L_8AD8:
	rr c		;8ad8
	jr nc,L_8AEB		;8ada
	add a,(ix+019h)		;8adc   ; sube (+0x19)
	jr nc,L_8AE3		;8adf
	ld a,0ffh		;8ae1   ; con acarreo: 0xFF
L_8AE3:
	cp (ix+01ah)		;8ae3   ; contra el tope (+0x1A)
	jr c,L_8AEB		;8ae6
	ld a,(ix+01ah)		;8ae8
L_8AEB:
	ld (ix+018h),a		;8aeb
	push bc			;8aee
	ld bc,0001dh		;8aef   ; siguiente jugador del roster
	add ix,bc		;8af2
	pop bc			;8af4
	djnz L_8AC8		;8af5
	jr L_8A88		;8af7
mejora_1b:		; SUPOSICION: campo +0x1B baja 1 hasta +0x1C; tras perder sube 1
	ld c,a			;8af9
	ld b,008h		;8afa
L_8AFC:
	ld a,(ix+01bh)		;8afc   ; campo 0x1B
	inc d			;8aff
	dec d			;8b00
	jr nz,L_8B0D		;8b01
	rr c		;8b03
	add a,001h		;8b05   ; sin ganar: sube 1
	jr nc,L_8B1B		;8b07
	ld a,0ffh		;8b09
	jr L_8B1B		;8b0b
L_8B0D:
	rr c		;8b0d
	jr nc,L_8B1B		;8b0f
	sub 001h		;8b11   ; baja 1
	cp (ix+01ch)		;8b13   ; contra el tope (+0x1C)
	jr nc,L_8B1B		;8b16
	ld a,(ix+01ch)		;8b18
L_8B1B:
	ld (ix+01bh),a		;8b1b
	push bc			;8b1e
	ld bc,0001dh		;8b1f   ; siguiente jugador del roster
	add ix,bc		;8b22
	pop bc			;8b24
	djnz L_8AFC		;8b25
	ret			;8b27
zona_controlado:		; Cada 8 cuadros mira en que zona de tiro esta el controlado y lleva la cuenta de 3 segundos
	ld a,(0ed86h)		;8b28
	and a			;8b2b
	ret z			;8b2c
	xor a			;8b2d
	ld (0ed86h),a		;8b2e
	call controlado		;8b31   ; controlado del equipo con el balon
	ld (0ed83h),a		;8b34
	ld a,001h		;8b37
	jr L_8B3C		;8b39
zona_tiro:		; Zona del jugador (0xED83) respecto a su canasta: 0 dentro de la zona, 1 media distancia, 2 triple; vigila los 3 segundos
	xor a			;8b3b
L_8B3C:
	ld (0ed84h),a		;8b3c
	push hl			;8b3f
	ld a,(0ed83h)		;8b40   ; jugador
	push af			;8b43
	call registro_jugador		;8b44
	inc hl			;8b47   ; Y e X del jugador
	ld e,(hl)			;8b48
	inc hl			;8b49
	inc hl			;8b4a
	ld d,(hl)			;8b4b
	pop af			;8b4c
	ld hl,0503ah		;8b4d
	cp 003h		;8b50
	jr c,L_8B56		;8b52
	ld h,0b0h		;8b54   ; la del equipo 3-5 (X 0xB0)
L_8B56:
	push de			;8b56
	call distancia_aprox		;8b57   ; distancia a la canasta
	pop de			;8b5a
	cp 028h		;8b5b   ; 40 o mas: triple
	jr nc,L_8BB1		;8b5d
	ld a,e			;8b5f
	cp 02eh		;8b60   ; fuera del ancho de la zona
	jr c,L_8BA3		;8b62
	cp 046h		;8b64
	jr nc,L_8BA3		;8b66
	ld a,d			;8b68
	bit 7,a		;8b69
	jr nz,L_8B9F		;8b6b
	cp 03ch		;8b6d   ; fuera del largo de la zona
	jr c,L_8BA3		;8b6f
L_8B71:
	xor a			;8b71   ; zona 0: dentro de la zona
	call misma_zona		;8b72
	jr z,L_8B9A		;8b75   ; sigue en la misma zona
	ld a,(0ed6dh)		;8b77   ; vencio la cuenta de 3 segundos?
	dec a			;8b7a
	jr nz,L_8B8B		;8b7b
	ld a,001h		;8b7d   ; rotulo 1: 3 SECOND
	ld (0cb35h),a		;8b7f
	ld a,(0ed83h)		;8b82   ; infractor
	ld (0cb34h),a		;8b85
	xor a			;8b88
	jr L_8B9D		;8b89
L_8B8B:
	dec a			;8b8b
	jr nz,L_8B97		;8b8c
	ld hl,000d2h		;8b8e   ; 210 cuadros de cuenta
	ld (0ed74h),hl		;8b91
	ld (0ed6dh),a		;8b94   ; cuenta de 3 segundos en marcha
L_8B97:
	xor a			;8b97
L_8B98:
	set 7,a		;8b98   ; bit 7: repintar el rotulo AREA
L_8B9A:
	ld (0ed82h),a		;8b9a   ; zona nueva
L_8B9D:
	pop hl			;8b9d
	ret			;8b9e
L_8B9F:
	cp 0c4h		;8b9f
	jr c,L_8B71		;8ba1
L_8BA3:
	ld a,001h		;8ba3   ; zona 1: media distancia
L_8BA5:
	call misma_zona		;8ba5
	jr z,L_8B9A		;8ba8
	ld hl,0ed6dh		;8baa   ; fuera de la zona: cuenta desactivada
	ld (hl),002h		;8bad
	jr L_8B98		;8baf
L_8BB1:
	ld a,002h		;8bb1   ; zona 2: triple
	jr L_8BA5		;8bb3
misma_zona:		; Z si la zona A es la de (0xED84)
	ld hl,0ed84h		;8bb5
	inc (hl)			;8bb8
	dec (hl)			;8bb9
	ret			;8bba
anota_tiro:		; Al tirar desactiva las cuentas y guarda el valor de la canasta (1 tiro libre, 2 o 3) y a quien sumarla
	ld hl,0ed6dh		;8bbb
	ld b,004h		;8bbe
L_8BC0:
	ld (hl),002h		;8bc0
	inc hl			;8bc2
	djnz L_8BC0		;8bc3
	ld a,(0ed5eh)		;8bc5   ; bits del tiro (bit 6 tiro libre)
	ld c,a			;8bc8
	and 03fh		;8bc9
	jr z,L_8C0F		;8bcb   ; sin tiro
	ld b,000h		;8bcd
	call controlado		;8bcf   ; tirador
	cp 003h		;8bd2
	jr c,L_8BD8		;8bd4
	set 7,b		;8bd6   ; bit 7: equipo derecho
L_8BD8:
	ld (0ed83h),a		;8bd8
	call campo_1f		;8bdb   ; +0x1F del tirador
	ld e,(hl)			;8bde
	ld d,000h		;8bdf
	ld a,b			;8be1
	ld (0ed4dh),a		;8be2
	push bc			;8be5
	ld c,008h		;8be6   ; campo 8 del roster: SUPOSICION tiros intentados
	call campo_equipo		;8be8
	pop bc			;8beb
	add hl,de			;8bec
	ld (0ed8bh),hl		;8bed   ; (0xED8B): el contador del campo 8 del tirador; ya no se le suma aqui al tirar sino al anotar (0x8C22)
	ld a,001h		;8bf0   ; tiro libre: 1 punto
	bit 6,c		;8bf2
	jr nz,L_8C04		;8bf4
	call zona_tiro		;8bf6   ; zona del tiro
	ld a,(0ed82h)		;8bf9
	and 00fh		;8bfc
	inc a			;8bfe
	cp 001h		;8bff
	jr nz,L_8C04		;8c01
	inc a			;8c03   ; dentro de la zona tambien vale 2
L_8C04:
	ld (0ed88h),a		;8c04   ; valor de la canasta
	ld c,004h		;8c07   ; campo 4 del roster: SUPOSICION puntos del jugador
	call campo_equipo		;8c09
	ld (0ed89h),hl		;8c0c   ; (0xED89): el contador de puntos del jugador, donde se sumara al anotar
L_8C0F:
	ld hl,0ed5eh		;8c0f
	res 6,(hl)		;8c12   ; tiro atendido
	ret			;8c14
suma_canasta:		; Al anotar suma el valor de la canasta (0xED88) al contador del jugador (0xED89) y al del campo 8 (0xED8B), cada uno con tope 0xFF; la primera version sumaba el segundo al tirar, anotara o no
	ld hl,(0ed89h)		;8c15   ; contador de puntos del jugador (0xED89)
	ld a,(0ed88h)		;8c18   ; valor de la canasta
	ld b,a			;8c1b   ; B = el valor, para el otro contador
	add a,(hl)			;8c1c   ; suma
	jr nc,L_8C21		;8c1d   ; sin acarreo: vale
	ld a,0ffh		;8c1f   ; con acarreo: tope 0xFF
L_8C21:
	ld (hl),a			;8c21   ; lo guarda
	ld hl,(0ed8bh)		;8c22   ; el otro contador (0xED8B)
	ld a,b			;8c25   ; valor de la canasta
	add a,(hl)			;8c26   ; suma
	jr nc,L_8C2B		;8c27   ; sin acarreo: vale
	ld a,0ffh		;8c29   ; tope 0xFF
L_8C2B:
	ld (hl),a			;8c2b   ; lo guarda
	ret			;8c2c
campo_1f:		; HL = +0x1F del jugador A
	ld hl,0c42fh		;8c2d
	ld de,00030h		;8c30
L_8C33:
	and a			;8c33
	ret z			;8c34
	add hl,de			;8c35
	dec a			;8c36
	jr L_8C33		;8c37
sonido_apagado:		; Pieza ninguna (0xFF) y contador a cero: lo llama INIT
	xor a			;8c39   ; A = 0
	ld (0ef6ch),a		;8c3a   ; (0xEF6C): cuadros que faltan para la ficha siguiente
	dec a			;8c3d   ; A = 0xFF
	ld (0ef67h),a		;8c3e   ; (0xEF67): pieza que suena, (0xEF6D): su prioridad; 0xFF = ninguna
	ld (0ef6dh),a		;8c41   ; prioridad ninguna
	ret			;8c44
huerfano_espera_sonido:		; Huerfano: espera a que se acabe el sonido en curso
	ld a,(0ef6ch)		;8c45
	and a			;8c48   ; suena algo?
	jr nz,huerfano_espera_sonido		;8c49   ; si: sigue esperando
	ret			;8c4b

; ----------------------------------------------------------------------
; ===== El motor de sonido: arrancar una pieza, el tick y el interprete =====
; ----------------------------------------------------------------------
arranca_sonido:		; Pide la pieza A (0-12) guardando los registros: si no es de prioridad menor que la que suena, la pone en marcha
	push af			;8c4c   ; guarda todos los registros
	push bc			;8c4d
	push de			;8c4e
	push hl			;8c4f
	call arranca_sonido_a		;8c50   ; la de verdad
	pop hl			;8c53   ; y los recupera
	pop de			;8c54
	pop bc			;8c55
	pop af			;8c56
	ret			;8c57
arranca_sonido_a:		; A negativo: nada. Compara la prioridad (0x8E7B) con la de la pieza en curso; con 0x1E o mas no se repite la misma pieza
	and a			;8c58   ; pieza negativa?
	ret m			;8c59   ; si: nada
	ld e,a			;8c5a   ; E = pieza
	ld c,e			;8c5b   ; BC = pieza
	ld b,000h		;8c5c
	ld hl,08e7bh		;8c5e   ; 0x8E7B: prioridad de cada pieza
	add hl,bc			;8c61   ; HL = su prioridad
	ld a,(0ef6dh)		;8c62   ; (0xEF6D): prioridad de la que suena (0xFF si ninguna)
	cp (hl)			;8c65   ; menor que la actual: no entra
	ret c			;8c66   ; menor que la que suena: no
	ld a,(hl)			;8c67   ; A = prioridad de la nueva
	ld (0ef6dh),a		;8c68   ; ya es la que suena
	cp 01eh		;8c6b   ; prioridad 30 o mas: si ya suena esa misma pieza no se reinicia
	jr c,L_8C76		;8c6d   ; menos de 30: entra siempre (0x8C76)
	jr nc,L_8C71		;8c6f   ; 30 o mas: mira si es la misma
L_8C71:
	ld a,(0ef67h)		;8c71   ; la pieza que suena
	cp e			;8c74   ; es la misma?
	ret z			;8c75   ; si: no se reinicia
L_8C76:
	ld a,e			;8c76   ; A = pieza
	ld (0ef67h),a		;8c77   ; (0xEF67): la pieza en curso
	add a,a			;8c7a   ; dos bytes por puntero
	ld c,a			;8c7b   ; BC = desplazamiento
	ld hl,08e61h		;8c7c   ; 0x8E61: los trece punteros
	add hl,bc			;8c7f   ; HL = su puntero
	ld e,(hl)			;8c80   ; E = byte bajo
	inc hl			;8c81
	ld d,(hl)			;8c82   ; D = byte alto
	di			;8c83   ; sin interrupciones mientras se cambia
	ld (0ef68h),de		;8c84   ; (0xEF68): puntero a la ficha siguiente
	ld hl,0ef8dh		;8c88   ; (0xEF6A): la pila propia de las llamadas, que crece hacia abajo desde 0xEF8D
	ld (0ef6ah),hl		;8c8b   ; pila propia vacia
	ld a,001h		;8c8e   ; un cuadro y empieza
	ld (0ef6ch),a		;8c90   ; un cuadro de espera
	ei			;8c93   ; interrupciones otra vez
	ret			;8c94
tick_sonido:		; Cada cuadro: si no suena nada marca 0xFF; si no, descuenta y al llegar a cero interpreta fichas hasta la siguiente espera
	ld hl,0ef6ch		;8c95   ; HL = contador
	ld a,(hl)			;8c98   ; A = cuadros que faltan
	and a			;8c99   ; cero: nada suena
	jr nz,L_8CA5		;8c9a   ; queda espera
	ld a,0ffh		;8c9c   ; nada sonando: pieza y prioridad a 0xFF
	ld (0ef6dh),a		;8c9e   ; prioridad ninguna
	ld (0ef67h),a		;8ca1   ; pieza ninguna
	ret			;8ca4
L_8CA5:
	dec (hl)			;8ca5   ; todavia esperando
	ret nz			;8ca6   ; todavia no
	ld hl,(0ef68h)		;8ca7   ; HL = ficha siguiente, IX = la pila
	ld ix,(0ef6ah)		;8caa   ; IX = la pila propia
	call interpreta_ficha		;8cae   ; interpreta hasta una espera: A = cuadros
	ld (0ef6ch),a		;8cb1   ; cuadros hasta la siguiente ficha
	ld (0ef68h),hl		;8cb4   ; puntero nuevo
	ld (0ef6ah),ix		;8cb7   ; pila nueva
	ret			;8cbb
interpreta_ficha:		; Lee fichas desde HL hasta dar con una espera; devuelve en A los cuadros (0 acaba la pieza) y en HL la siguiente
	ld a,(hl)			;8cbc   ; bits 7-6 a cero: no es nota
	and 0c0h		;8cbd   ; bits 7 y 6: el canal
	jr z,L_8CE1		;8cbf   ; cero: no es nota
	rlca			;8cc1   ; canal = (ficha >> 6) - 1, por dos: el registro del periodo
	rlca			;8cc2   ; canal en los bits 1-0
	dec a			;8cc3   ; 1-3 -> 0-2
	add a,a			;8cc4   ; por dos: registros 0/1, 2/3, 4/5
	push af			;8cc5   ; guarda el registro
	ld a,(hl)			;8cc6   ; indice de nota (0-63)
	and 03fh		;8cc7   ; indice de la nota
	add a,a			;8cc9   ; dos bytes por periodo
	exx			;8cca   ; registros alternativos para no perder HL
	ld b,000h		;8ccb   ; BC = desplazamiento
	ld c,a			;8ccd   ; bajo
	ld hl,08ddfh		;8cce   ; 0x8DDF: los 64 periodos de 16 bits
	add hl,bc			;8cd1   ; HL = el periodo
	ld e,(hl)			;8cd2   ; E = byte bajo del periodo
	pop af			;8cd3   ; A = registro
	call 00093h		;8cd4   ; BIOS WRTPSG - Writes data to PSG-register | registro bajo del periodo
	inc a			;8cd7   ; registro alto
	inc hl			;8cd8   ; byte alto del periodo
	ld e,(hl)			;8cd9   ; E = byte alto
	call 00093h		;8cda   ; BIOS WRTPSG - Writes data to PSG-register | registro alto
	exx			;8cdd   ; HL de vuelta
	inc hl			;8cde   ; ficha siguiente
	jr interpreta_ficha		;8cdf   ; y otra ficha: la nota no espera
L_8CE1:
	ld a,(hl)			;8ce1   ; bit 5 a cero: 0x00-0x1F, una espera
	and 020h		;8ce2   ; bit 5?
	jr nz,L_8CF0		;8ce4   ; a uno: orden o registro
	ld a,(hl)			;8ce6   ; A = la espera
	cp 01fh		;8ce7   ; 0x1F: la espera vale lo que diga (0xEF6E)
	jr nz,L_8CEE		;8ce9   ; no es 0x1F: tal cual
	ld a,(0ef6eh)		;8ceb   ; (0xEF6E): el tempo
L_8CEE:
	inc hl			;8cee   ; ficha siguiente
	ret			;8cef   ; vuelve con los cuadros en A
L_8CF0:
	ld a,(hl)			;8cf0   ; A = la ficha
	bit 4,a		;8cf1   ; bit 4: 0x30-0x3F, ordenes
	jr nz,L_8D11		;8cf3   ; bit 4 a uno: 0x30-0x3F
	and 00fh		;8cf5   ; 0x20-0x2F: registro del PSG
	cp 006h		;8cf7   ; 0x20-0x25: el mezclador (registro 7) con un valor de 0x8E5F
	jr nc,L_8D09		;8cf9   ; 6 o mas: registro directo (0x8D09)
	push hl			;8cfb   ; guarda el puntero
	ld hl,08e5fh		;8cfc   ; 0x8E5F: los valores del registro 7
	ld e,a			;8cff   ; DE = indice
	ld d,000h		;8d00
	add hl,de			;8d02   ; HL = el valor
	ld e,(hl)			;8d03   ; E = valor del mezclador
	pop hl			;8d04   ; recupera el puntero
	ld a,007h		;8d05   ; registro 7
	jr L_8D0B		;8d07   ; a escribirlo
L_8D09:
	inc hl			;8d09   ; 0x26-0x2F: el registro del nibble bajo con el byte siguiente
	ld e,(hl)			;8d0a   ; E = el byte siguiente
L_8D0B:
	call 00093h		;8d0b   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;8d0e   ; ficha siguiente
	jr interpreta_ficha		;8d0f   ; y otra ficha
L_8D11:
	cp 03dh		;8d11   ; 0x3D: silencio
	jr nz,L_8D24		;8d13   ; no es 0x3D
	ld e,000h		;8d15   ; E = 0: el valor
	ld a,000h		;8d17   ; A = 0: el primer registro
	ld b,006h		;8d19   ; seis registros
L_8D1B:
	call 00093h		;8d1b   ; BIOS WRTPSG - Writes data to PSG-register | registros 0-5 a cero
	inc a			;8d1e   ; registro siguiente
	djnz L_8D1B		;8d1f   ; los seis
	inc hl			;8d21   ; ficha siguiente
	jr interpreta_ficha		;8d22   ; y otra ficha
L_8D24:
	cp 033h		;8d24   ; 0x33: salto a la direccion que sigue
	jr nz,L_8D2F		;8d26   ; no es 0x33
	inc hl			;8d28   ; el byte bajo del destino
	ld e,(hl)			;8d29   ; E = bajo
	inc hl			;8d2a   ; el alto
	ld d,(hl)			;8d2b   ; D = alto
	ex de,hl			;8d2c   ; HL = destino
	jr interpreta_ficha		;8d2d   ; sigue alli
L_8D2F:
	cp 034h		;8d2f   ; 0x34: llamada; apila la vuelta en IX
	jr nz,L_8D46		;8d31   ; no es 0x34
	inc hl			;8d33   ; el byte bajo del destino
	ld e,(hl)			;8d34   ; E = bajo
	inc hl			;8d35   ; el alto
	ld d,(hl)			;8d36   ; D = alto
	inc hl			;8d37   ; HL = la vuelta
	ld (ix-001h),h		;8d38   ; vuelta alta a la pila propia
	ld (ix-002h),l		;8d3b   ; vuelta baja
	dec ix		;8d3e   ; la pila baja dos
	dec ix		;8d40
	ex de,hl			;8d42   ; HL = destino
	jp interpreta_ficha		;8d43   ; sigue alli
L_8D46:
	cp 035h		;8d46   ; 0x35: vuelta de la llamada
	jr nz,L_8D57		;8d48   ; no es 0x35
	inc ix		;8d4a   ; la pila sube dos
	inc ix		;8d4c
	ld h,(ix-001h)		;8d4e   ; H = vuelta alta
	ld l,(ix-002h)		;8d51   ; L = vuelta baja
	jp interpreta_ficha		;8d54   ; sigue en la vuelta
L_8D57:
	cp 036h		;8d57   ; 0x36: abre un bucle; apila el puntero y la cuenta (0x1F = el tempo)
	jr nz,L_8D77		;8d59   ; no es 0x36
	inc hl			;8d5b   ; el byte de la cuenta
	ld a,(hl)			;8d5c   ; A = cuenta
	cp 01fh		;8d5d   ; cuenta 0x1F: la de (0xEF6E)
	jr nz,L_8D64		;8d5f   ; no es 0x1F: tal cual
	ld a,(0ef6eh)		;8d61   ; cuenta = el tempo
L_8D64:
	inc hl			;8d64   ; HL = primera ficha del bucle
	ld (ix-001h),h		;8d65   ; puntero alto a la pila propia
	ld (ix-002h),l		;8d68   ; puntero bajo
	ld (ix-003h),a		;8d6b   ; y la cuenta
	dec ix		;8d6e   ; la pila baja tres
	dec ix		;8d70
	dec ix		;8d72
	jp interpreta_ficha		;8d74   ; sigue dentro del bucle
L_8D77:
	cp 037h		;8d77   ; 0x37: cierra el bucle; una vuelta menos, y si quedan salta al principio
	jr nz,L_8D93		;8d79   ; no es 0x37
	dec (ix+000h)		;8d7b   ; (IX+0): la cuenta
	jr z,L_8D89		;8d7e   ; cero: se acabo el bucle
	ld l,(ix+001h)		;8d80   ; L = puntero bajo
	ld h,(ix+002h)		;8d83   ; H = puntero alto
	jp interpreta_ficha		;8d86   ; otra vuelta
L_8D89:
	inc ix		;8d89   ; cuenta agotada: saca los tres bytes y sigue
	inc ix		;8d8b   ; la pila sube tres
	inc ix		;8d8d
	inc hl			;8d8f   ; ficha siguiente
	jp interpreta_ficha		;8d90   ; sigue detras del bucle
L_8D93:
	bit 3,a		;8d93   ; bit 3 a cero: 0x30, 0x32, 0x3C, deslizamiento de tono
	jr nz,L_8DB6		;8d95   ; a uno: deslizamiento (0x8DB6)
	and 003h		;8d97   ; 0x38-0x3B: volumen del canal (bits 1-0)
	add a,008h		;8d99   ; registros 8-10
	push af			;8d9b   ; guarda el registro
	call 00096h		;8d9c   ; BIOS RDPSG - Reads value from PSG-register | el volumen actual
	and 01fh		;8d9f   ; volumen 0-15
	inc hl			;8da1   ; el byte del cambio
	add a,(hl)			;8da2   ; mas el byte siguiente, con signo
	jp p,L_8DA7		;8da3   ; negativo: cero
	xor a			;8da6   ; negativo: cero
L_8DA7:
	cp 011h		;8da7   ; tope de 16
	jr c,L_8DAD		;8da9   ; menos de 17: vale
	ld a,010h		;8dab   ; 17 o mas: 16
L_8DAD:
	ld e,a			;8dad   ; E = volumen nuevo
	pop af			;8dae   ; A = registro
	call 00093h		;8daf   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;8db2   ; ficha siguiente
	jp interpreta_ficha		;8db3   ; y otra ficha
L_8DB6:
	and 006h		;8db6   ; registro del periodo: 0, 2 o 4
	ld c,a			;8db8   ; C = registro bajo del periodo
	call 00096h		;8db9   ; BIOS RDPSG - Reads value from PSG-register | periodo actual, bajo
	ld e,a			;8dbc   ; E = periodo bajo
	ld a,c			;8dbd   ; A = registro
	inc a			;8dbe   ; el alto
	call 00096h		;8dbf   ; BIOS RDPSG - Reads value from PSG-register | y alto
	ld d,a			;8dc2   ; D = periodo alto
	inc hl			;8dc3   ; el byte del desplazamiento
	push hl			;8dc4   ; guarda el puntero
	ld a,(hl)			;8dc5   ; el desplazamiento, con signo
	ld h,000h		;8dc6   ; H = 0
	and a			;8dc8   ; signo del desplazamiento
	jp p,L_8DCD		;8dc9   ; positivo
	dec h			;8dcc   ; negativo: H = 0xFF
L_8DCD:
	ld l,a			;8dcd   ; HL = desplazamiento con signo
	add hl,de			;8dce   ; periodo nuevo
	ex de,hl			;8dcf   ; DE = periodo nuevo
	pop hl			;8dd0   ; recupera el puntero
	ld a,c			;8dd1   ; A = registro bajo
	call 00093h		;8dd2   ; BIOS WRTPSG - Writes data to PSG-register | bajo
	ld a,c			;8dd5   ; A = registro bajo
	inc a			;8dd6   ; el alto
	ld e,d			;8dd7   ; E = periodo alto
	call 00093h		;8dd8   ; BIOS WRTPSG - Writes data to PSG-register | alto
	inc hl			;8ddb   ; ficha siguiente
	jp interpreta_ficha		;8ddc   ; y otra ficha

; ----------------------------------------------------------------------
; DATOS notas: 64 periodos de 16 bits del PSG: la ficha de nota 0x40-0xFF del
;   motor de sonido escribe en los registros del canal el periodo de indice
;   (ficha & 0x3F)
;   0x8ddf..0x8e5f  (128 bytes)
DATA_notas:
	defw 006aeh,0064eh,005f3h,0059eh,0054dh,00501h,004b9h,00475h	; 8ddf
	defw 00435h,003f1h,003c0h,0038ah,00357h,00327h,002f9h,002cfh	; 8def
	defw 002a6h,00280h,0025ch,0023ah,0021ah,001f8h,001e0h,001c5h	; 8dff
	defw 001abh,00193h,0017ch,00167h,00153h,00140h,0012eh,0011dh	; 8e0f
	defw 0010dh,000fch,000f0h,000e2h,000d5h,000c9h,000beh,000b3h	; 8e1f
	defw 000a9h,000a0h,00097h,0008eh,00086h,0007eh,00078h,00071h	; 8e2f
	defw 0006ah,00064h,0005fh,00059h,00054h,00035h,0004bh,00047h	; 8e3f
	defw 00043h,0003fh,0002ah,00028h,00021h,0001fh,0001eh,00000h	; 8e4f

; ----------------------------------------------------------------------
; DATOS mezclador: Los dos valores del registro 7 (0xB8 tono en los tres
;   canales, 0xA8 ruido en el C) que escriben las fichas 0x20 y 0x21
;   0x8e5f..0x8e61  (2 bytes)
DATA_mezclador:
	defb 0b8h,0a8h	; 8e5f

; ----------------------------------------------------------------------
; DATOS piezas: Punteros a las trece piezas de sonido (la 1 y la 8 son la
;   misma, la 4, 5 y 6 tambien): 0x8C4C arranca la de indice A si su prioridad
;   lo permite
;   0x8e61..0x8e7b  (26 bytes)
DATA_piezas:
	defw 08e88h	; 8e61  -> DATA_pieza_00
	defw 08ed2h	; 8e63  -> DATA_pieza_01
	defw 094d5h	; 8e65  -> DATA_pieza_02
	defw 08e8ah	; 8e67  -> DATA_pieza_03
	defw 08e97h	; 8e69  -> DATA_pieza_04
	defw 08e97h	; 8e6b  -> DATA_pieza_04
	defw 08e97h	; 8e6d  -> DATA_pieza_04
	defw 08each	; 8e6f  -> DATA_pieza_07
	defw 08ed2h	; 8e71  -> DATA_pieza_01
	defw 08f0ch	; 8e73  -> DATA_pieza_09
	defw 08f2bh	; 8e75  -> DATA_pieza_10
	defw 092e1h	; 8e77  -> DATA_pieza_11
	defw 09456h	; 8e79  -> DATA_pieza_12

; ----------------------------------------------------------------------
; DATOS prioridad_piezas: Prioridad de cada una de las trece piezas: 0x8C5E no
;   arranca una pieza de prioridad menor que la que suena
;   0x8e7b..0x8e88  (13 bytes)
DATA_prioridad_piezas:
	defb 005h,00ch,00fh,00ah,014h,014h,00ah,019h,00ch,019h,00ah,00ah,00ah	; 8e7b  .............

; ----------------------------------------------------------------------
; DATOS pieza_00: Pieza 0: una espera y el fin (dos bytes)
;   0x8e88..0x8e8a  (2 bytes)
DATA_pieza_00:
	defb 03dh,000h	; 8e88

; ----------------------------------------------------------------------
; DATOS pieza_03: Pieza 3 (13 bytes)
;   0x8e8a..0x8e97  (13 bytes)
DATA_pieza_03:
	defb 020h,028h,00fh,029h,00fh,02ah,00fh,07bh,0bch,0fdh,01eh,03dh,000h	; 8e8a   (.).*.{...=.

; ----------------------------------------------------------------------
; DATOS pieza_04: Pieza 4, 5 y 6 (el mismo puntero con tres prioridades, 20,
;   20 y 10; 21 bytes)
;   0x8e97..0x8eac  (21 bytes)
DATA_pieza_04:
	defb 020h,028h,00fh,029h,00dh,02ah,00eh,036h,010h,05eh,09eh,0deh,002h,03ah,004h,03ch,0fch,002h,037h,03dh,000h	; 8e97   (.).*.6.^...:.<..7=.

; ----------------------------------------------------------------------
; DATOS pieza_07: Pieza 7 (38 bytes)
;   0x8eac..0x8ed2  (38 bytes)
DATA_pieza_07:
	defb 027h,0bch,028h,00fh,029h,00dh,050h,001h,07fh,090h,001h,051h,0bfh,001h,07fh,091h,001h,052h,0bfh	; 8eac  '.(.).P....Q.....R.
	defb 001h,07fh,092h,001h,03ah,003h,058h,098h,002h,036h,010h,030h,0ffh,031h,0ffh,002h,037h,03dh,000h	; 8ebf  ....:.X..6.0.1..7=.

; ----------------------------------------------------------------------
; DATOS pieza_01: Pieza 1 y 8 (la musica): llama con 0x34 a las frases de
;   0x94E9, 0x9548, 0x9504 y 0x9529 y salta en 0x8F09 a 0x94D8, el bucle que
;   comparte con la pieza 2
;   0x8ed2..0x8f0c  (58 bytes)
DATA_pieza_01:
	defb 027h,080h,026h,006h,028h,00fh,029h,00fh,02ah,00fh,063h,0a0h,0dch,002h,026h,003h	; 8ed2  '.&.(.).*.c...&.
	defb 062h,09fh,0dbh,002h,020h,05eh,09bh,0d7h,002h,05ah,097h,0d3h,002h,054h,091h,0cdh	; 8ee2  b... ^...Z...T..
	defb 001h,04ah,087h,0c3h,001h,034h,0e9h,094h,034h,048h,095h,034h,048h,095h,036h,004h	; 8ef2  .J...4..4H.4H.6.
	defb 034h,004h,095h,037h,034h,029h,095h,033h,0d8h,094h	; 8f02  4..74).3..

; ----------------------------------------------------------------------
; DATOS pieza_09: Pieza 9 (31 bytes)
;   0x8f0c..0x8f2b  (31 bytes)
DATA_pieza_09:
	defb 027h,0bch,028h,00bh,029h,009h,045h,084h,001h,046h,087h,001h,028h,00fh,029h,00dh	; 8f0c  '.(.).E..F..(.).
	defb 036h,004h,030h,0feh,031h,0feh,04dh,0bfh,002h,07fh,08ch,001h,037h,03dh,000h	; 8f1c  6.0.1.M.....7=.

; ----------------------------------------------------------------------
; DATOS pieza_10: Pieza 10 (950 bytes): el salto de 0x92DE vuelve a 0x8F42
;   0x8f2b..0x92e1  (950 bytes)
DATA_pieza_10:
	defb 020h,028h,010h,029h,010h,02ah,00eh,02ch,032h,026h,003h,02dh,000h,058h,095h,0c5h	; 8f2b   (.).*.,2&.-.X..
	defb 006h,0ffh,006h,0d5h,006h,0ffh,006h,021h,0c0h,006h,020h,03dh,006h,02dh,000h,05dh	; 8f3b  .......!.. =.-.]
	defb 095h,0d5h,006h,0ffh,006h,0c5h,006h,0ffh,006h,0d5h,006h,0ffh,006h,021h,028h,00fh	; 8f4b  .............!(.
	defb 029h,00dh,062h,098h,0c0h,006h,020h,061h,0ffh,006h,05fh,0d5h,006h,0ffh,006h,028h	; 8f5b  ).b... a.._....(
	defb 010h,029h,010h,02ch,032h,02dh,000h,061h,098h,0c5h,006h,0ffh,006h,0d5h,006h,0ffh	; 8f6b  .).,2-.a........
	defb 006h,021h,0c0h,006h,020h,0ffh,006h,02dh,000h,09dh,00ch,0c5h,006h,0ffh,006h,021h	; 8f7b  .!.. ..-.......!
	defb 0c0h,005h,020h,0ffh,007h,021h,0c5h,005h,020h,0ffh,007h,021h,0c7h,005h,020h,0ffh	; 8f8b  .. ..!.. ..!.. .
	defb 007h,02dh,000h,02ch,032h,058h,093h,0c8h,006h,0ffh,006h,0d4h,006h,0ffh,006h,021h	; 8f9b  .-.,2X.........!
	defb 0c3h,006h,020h,0ffh,006h,02dh,000h,05dh,098h,0d4h,006h,0ffh,006h,0c8h,006h,0ffh	; 8fab  .. ..-.]........
	defb 006h,0d4h,006h,0ffh,006h,021h,02dh,000h,062h,098h,0c3h,006h,020h,061h,0ffh,006h	; 8fbb  .....!-.b... a..
	defb 05fh,0d4h,006h,0ffh,006h,02dh,000h,064h,098h,0c8h,006h,0ffh,006h,0d4h,006h,0ffh	; 8fcb  _....-.d........
	defb 006h,021h,0c3h,006h,020h,0ffh,006h,0d4h,006h,0ffh,006h,0c8h,00ch,02dh,000h,021h	; 8fdb  .!.. ........-.!
	defb 05fh,098h,006h,020h,0cfh,006h,02dh,000h,060h,098h,006h,021h,05fh,006h,020h,060h	; 8feb  _.. ..-.`..!_. `
	defb 0c8h,006h,062h,006h,028h,00fh,029h,00dh,036h,002h,021h,064h,09ah,0c7h,003h,020h	; 8ffb  ..b.(.).6.!d... 
	defb 03dh,003h,037h,021h,064h,09dh,0d6h,003h,020h,03dh,009h,0d6h,00ch,021h,028h,010h	; 900b  =.7!d... =...!(.
	defb 029h,010h,02ch,028h,02dh,000h,064h,09ch,0cch,006h,020h,00ch,0ffh,006h,028h,00fh	; 901b  ).,(-.d... ...(.
	defb 029h,00dh,05fh,00ch,060h,006h,05fh,006h,060h,006h,062h,006h,036h,002h,021h,064h	; 902b  )._.`._.`.b.6.!d
	defb 09fh,0c3h,003h,020h,03dh,003h,037h,021h,064h,09ah,0cfh,003h,020h,03dh,009h,0cfh	; 903b  ... =.7!d... =..
	defb 00ch,021h,028h,010h,029h,010h,02ch,028h,02dh,000h,064h,09fh,0c8h,006h,020h,00ch	; 904b  .!(.).,(-.d... .
	defb 03dh,006h,028h,00fh,029h,00dh,05fh,00ch,060h,006h,05fh,006h,060h,006h,062h,006h	; 905b  =.(.)._.`._.`.b.
	defb 036h,002h,021h,064h,09ah,0c7h,003h,020h,03dh,003h,037h,021h,064h,09dh,0d6h,003h	; 906b  6.!d... =.7!d...
	defb 020h,03dh,009h,0d3h,006h,0c7h,006h,028h,010h,029h,010h,02ch,028h,02dh,000h,064h	; 907b   =.....(.).,(-.d
	defb 09ch,0cch,012h,03dh,006h,021h,028h,00fh,029h,00dh,05fh,09ch,0d6h,006h,020h,03dh	; 908b  ...=.!(.)._... =
	defb 006h,060h,09ch,006h,021h,062h,0cch,006h,020h,006h,03dh,006h,028h,010h,029h,010h	; 909b  .`..!b.. .=.(.).
	defb 02ch,028h,02dh,000h,062h,098h,0c5h,006h,07fh,0bfh,006h,02ch,014h,02dh,000h,060h	; 90ab  ,(-.b......,.-.`
	defb 09bh,006h,021h,07fh,0bfh,0d4h,006h,020h,02dh,000h,05fh,08fh,006h,02dh,000h,060h	; 90bb  ..!.... -._..-.`
	defb 0ffh,006h,021h,0c5h,006h,020h,006h,021h,02dh,000h,05fh,09bh,0cbh,006h,020h,07fh	; 90cb  ..!.. .!-._... .
	defb 0bfh,006h,02dh,000h,05dh,097h,0ffh,006h,021h,07fh,0bfh,0d4h,006h,020h,02dh,000h	; 90db  ..-.]...!.... -.
	defb 05bh,098h,006h,02dh,000h,05dh,094h,006h,021h,0cah,006h,020h,006h,02ch,032h,02dh	; 90eb  [..-.]..!.. .,2-
	defb 000h,056h,093h,0c3h,006h,0ffh,006h,036h,002h,0c3h,003h,0ffh,003h,037h,021h,0cfh	; 90fb  .V.....6.....7!.
	defb 003h,020h,0ffh,003h,0c3h,003h,0ffh,003h,02dh,000h,021h,05bh,093h,0cfh,006h,020h	; 910b  . ......-.![... 
	defb 006h,0c3h,00ch,0ffh,00ch,02dh,000h,060h,096h,0cfh,006h,05fh,0ffh,006h,021h,05dh	; 911b  .....-.`..._..!]
	defb 094h,0cdh,006h,020h,006h,021h,02dh,000h,05fh,096h,0c3h,006h,020h,0ffh,006h,036h	; 912b  ... .!-._... ..6
	defb 002h,0c3h,003h,0ffh,003h,037h,021h,0cfh,003h,020h,0ffh,003h,0c3h,003h,0ffh,003h	; 913b  .....7!.. ......
	defb 021h,02dh,000h,05fh,09bh,0cfh,006h,020h,006h,0ffh,00ch,021h,0cfh,003h,020h,0ffh	; 914b  !-._... ...!.. .
	defb 003h,0c3h,003h,0ffh,003h,0d0h,003h,0ffh,003h,021h,0c4h,003h,020h,0ffh,003h,021h	; 915b  .........!.. ..!
	defb 0d1h,003h,020h,0ffh,003h,0c5h,003h,0ffh,003h,02dh,000h,056h,091h,0c6h,006h,0ffh	; 916b  .. ......-.V....
	defb 006h,036h,002h,021h,0c6h,006h,020h,0ffh,006h,037h,021h,02dh,000h,05bh,096h,0d2h	; 917b  .6.!.. ..7!-.[..
	defb 003h,020h,02dh,000h,0ffh,003h,0c6h,003h,0ffh,009h,021h,0d2h,006h,020h,0ffh,006h	; 918b  . -.......!.. ..
	defb 0c6h,006h,02dh,000h,021h,060h,096h,0d2h,006h,020h,05fh,006h,05dh,0c6h,006h,0ffh	; 919b  ..-.!`... _.]...
	defb 006h,021h,02dh,000h,062h,096h,0c6h,006h,020h,0ffh,006h,036h,002h,0c3h,003h,0ffh	; 91ab  .!-.b... ..6....
	defb 003h,037h,021h,0d2h,003h,020h,0ffh,003h,0c3h,003h,0ffh,003h,021h,0d2h,006h,020h	; 91bb  .7!.. ......!.. 
	defb 006h,0ffh,00ch,028h,00fh,029h,00dh,021h,05dh,096h,0cdh,006h,020h,006h,05eh,006h	; 91cb  ...(.).!]... .^.
	defb 021h,05dh,006h,020h,05eh,006h,060h,0c6h,006h,036h,002h,021h,062h,098h,0c5h,003h	; 91db  !]. ^.`..6.!b...
	defb 020h,03dh,003h,037h,021h,062h,09bh,0d4h,003h,020h,03dh,009h,0d4h,006h,0c5h,006h	; 91eb   =.7!b... =.....
	defb 021h,062h,09ah,0cah,006h,020h,012h,021h,060h,09ah,006h,020h,07fh,0bfh,006h,028h	; 91fb  !b... .!`.. ...(
	defb 010h,029h,010h,02ch,032h,02dh,000h,05eh,09ah,006h,021h,060h,09ah,0d2h,006h,020h	; 920b  .).,2-.^..!`... 
	defb 0cah,00ch,036h,002h,028h,00fh,029h,00dh,021h,060h,099h,0c3h,003h,020h,03dh,003h	; 921b  ..6.(.).!`... =.
	defb 037h,021h,060h,099h,0cfh,003h,020h,03dh,009h,0cfh,006h,0c3h,006h,021h,060h,098h	; 922b  7!`... =.....!`.
	defb 0c8h,006h,020h,00ch,03dh,006h,05eh,098h,0c6h,006h,07fh,0bfh,006h,05dh,098h,006h	; 923b  .. .=.^......]..
	defb 021h,02dh,000h,05eh,098h,006h,020h,0cah,00ch,021h,063h,09eh,0c8h,006h,020h,03dh	; 924b  !-.^.. ..!c... =
	defb 006h,065h,0a2h,006h,021h,07fh,0bfh,0d7h,006h,020h,028h,010h,029h,010h,02ch,032h	; 925b  .e..!.... (.).,2
	defb 02dh,000h,067h,0a3h,006h,06ah,0a3h,006h,021h,0ceh,006h,020h,006h,028h,00fh,029h	; 926b  -.g..j..!.. .(.)
	defb 00dh,05bh,097h,0cdh,006h,03dh,006h,021h,05dh,099h,006h,020h,07fh,0bfh,0d7h,006h	; 927b  .[...=.!].. ....
	defb 028h,010h,029h,010h,02ch,032h,02dh,000h,05eh,09bh,006h,021h,060h,09dh,006h,020h	; 928b  (.).,2-.^..!`.. 
	defb 0cdh,00ch,028h,00fh,029h,00dh,021h,05eh,09bh,0cbh,006h,020h,096h,008h,03dh,004h	; 929b  ..(.).!^... ..=.
	defb 021h,05eh,09ah,0cbh,006h,020h,095h,008h,03dh,004h,021h,05eh,096h,0c6h,006h,020h	; 92ab  !^... ..=.!^... 
	defb 03dh,012h,021h,05dh,096h,0c7h,006h,020h,03dh,00ch,021h,05fh,096h,0cch,006h,020h	; 92bb  =.!]... =.!_... 
	defb 0c0h,009h,07fh,0bfh,003h,028h,010h,029h,010h,02dh,000h,058h,095h,0c5h,006h,0ffh	; 92cb  .....(.).-.X....
	defb 00ch,0d5h,006h,033h,042h,08fh	; 92db

; ----------------------------------------------------------------------
; DATOS pieza_11: Pieza 11 (373 bytes): el salto de 0x9453 vuelve al principio
;   0x92e1..0x9456  (373 bytes)
DATA_pieza_11:
	defb 027h,0b8h,028h,010h,029h,00dh,02ah,00eh,02ch,03ch,02dh,000h,05bh,094h,0c8h,00ch	; 92e1  '.(.).*.,<-.[...
	defb 098h,0cfh,006h,08fh,0d8h,006h,094h,0c3h,00ch,098h,0cfh,006h,08fh,0d8h,006h,094h	; 92f1  ................
	defb 0c8h,00ch,098h,0cfh,006h,08fh,0d8h,006h,02dh,000h,060h,094h,0c3h,00ch,094h,0cfh	; 9301  ........-.`.....
	defb 006h,08fh,0d8h,006h,02dh,000h,065h,08ch,0c8h,00ch,09bh,0cfh,006h,094h,0d8h,006h	; 9311  ....-.e.........
	defb 02dh,000h,064h,098h,0c8h,006h,0bfh,0ffh,006h,09bh,0d4h,006h,0bfh,0ffh,006h,02dh	; 9321  -.d............-
	defb 000h,062h,099h,0cah,006h,0bfh,0ffh,006h,099h,0d6h,006h,0bfh,0ffh,006h,02dh,000h	; 9331  .b............-.
	defb 060h,09bh,0cch,006h,0bfh,0ffh,006h,094h,0d8h,006h,0bfh,0ffh,006h,02dh,000h,05eh	; 9341  `............-.^
	defb 096h,0c3h,00ch,099h,0cfh,006h,092h,0d9h,006h,08fh,0cah,00ch,099h,0cfh,006h,092h	; 9351  ................
	defb 0d9h,006h,096h,0cfh,00ch,099h,0cfh,006h,09eh,0d6h,006h,02dh,000h,062h,0bfh,0c3h	; 9361  ...........-.b..
	defb 00ch,09eh,0cfh,006h,096h,0d9h,006h,02dh,000h,069h,0bfh,0c8h,00ch,09eh,0cfh,006h	; 9371  .......-.i......
	defb 098h,0d4h,006h,02dh,000h,067h,0bfh,0ffh,00ch,092h,0c8h,006h,0bfh,006h,02dh,000h	; 9381  ...-.g........-.
	defb 065h,092h,0cah,006h,0bfh,0ffh,006h,092h,0d9h,006h,0bfh,0ffh,006h,02dh,000h,064h	; 9391  e............-.d
	defb 094h,0cch,006h,0bfh,0ffh,006h,092h,0cfh,006h,0bfh,0ffh,006h,02dh,000h,062h,09dh	; 93a1  ............-.b.
	defb 0cdh,00ah,0bfh,0ffh,008h,09dh,0cdh,006h,0bfh,0ffh,00ch,02dh,000h,060h,090h,0c1h	; 93b1  ...........-.`..
	defb 012h,03dh,012h,02dh,000h,05fh,09ch,0cdh,004h,03dh,008h,060h,090h,0c1h,004h,03dh	; 93c1  .=.-._...=.`...=
	defb 008h,02dh,000h,062h,08fh,0c0h,00ah,0bfh,0ffh,008h,09bh,0cch,006h,0bfh,0ffh,00ch	; 93d1  .-.b............
	defb 02dh,000h,060h,09bh,0c5h,012h,03dh,012h,02dh,000h,05fh,09bh,0d1h,004h,03dh,008h	; 93e1  -.`...=.-._...=.
	defb 060h,08fh,0c5h,004h,03dh,008h,02dh,000h,067h,091h,0c1h,005h,0bfh,0ffh,007h,0d9h	; 93f1  `...=.-.g.......
	defb 005h,0ffh,007h,095h,0c5h,005h,0bfh,0ffh,007h,0ddh,005h,0ffh,007h,02dh,000h,065h	; 9401  .............-.e
	defb 094h,0cah,005h,0bfh,0ffh,00dh,09dh,0cdh,005h,02dh,000h,05ch,0bfh,0ffh,00dh,099h	; 9411  .........-.\....
	defb 0d4h,005h,0bfh,0ffh,007h,02dh,000h,064h,09ah,0cah,012h,03dh,006h,02dh,000h,065h	; 9421  .....-.d...=.-.e
	defb 0a0h,0d0h,006h,064h,0bfh,0ffh,006h,062h,093h,0cfh,012h,03dh,006h,054h,099h,0cah	; 9431  ...d...b...=.T..
	defb 003h,03dh,009h,036h,002h,053h,098h,0cfh,003h,03dh,003h,037h,04dh,093h,0c3h,006h	; 9441  .=.6.S...=.7M...
	defb 03dh,006h,033h,0e1h,092h	; 9451

; ----------------------------------------------------------------------
; DATOS pieza_12: Pieza 12 (127 bytes)
;   0x9456..0x94d5  (127 bytes)
DATA_pieza_12:
	defb 027h,0b8h,028h,00fh,029h,00dh,02ah,00eh,026h,004h,066h,0a2h,0c7h,006h,0ffh,006h	; 9456  '.(.).*.&.f.....
	defb 027h,0a8h,096h,0d3h,006h,027h,0b8h,07fh,0c7h,006h,066h,09dh,0d3h,003h,0bfh,0ffh	; 9466  '....'....f.....
	defb 003h,027h,0a8h,09dh,0c7h,006h,027h,0b8h,006h,0bfh,0ffh,006h,036h,002h,027h,0a8h	; 9476  .'....'.....6.'.
	defb 068h,09ch,0cch,003h,027h,0b8h,0bfh,0ffh,003h,037h,096h,0cch,002h,03dh,004h,064h	; 9486  h...'....7...=.d
	defb 006h,066h,006h,068h,09fh,0cch,00ch,03dh,006h,027h,0a8h,069h,0a1h,0cah,004h,027h	; 9496  .f.h...=.'.i...'
	defb 0b8h,0bfh,0ffh,008h,027h,0a8h,09ah,0cah,004h,027h,0b8h,0bfh,0ffh,008h,027h,0a8h	; 94a6  ....'....'....'.
	defb 05dh,098h,0c9h,003h,027h,0b8h,03dh,003h,027h,0a8h,05dh,096h,0c7h,003h,027h,0b8h	; 94b6  ]...'.=.'.]...'.
	defb 03dh,009h,027h,0a8h,05dh,095h,0c5h,004h,027h,0b8h,012h,07fh,006h,03dh,000h	; 94c6  =.'.]...'....=.

; ----------------------------------------------------------------------
; DATOS pieza_02: Pieza 2 (20 bytes): desde 0x94D8 es tambien el bucle final
;   de la pieza 1
;   0x94d5..0x94e9  (20 bytes)
DATA_pieza_02:
	defb 034h,0e9h,094h,036h,00dh,034h,004h,095h,037h,036h,00fh,031h,0ffh,032h,0ffh,034h,004h,095h,037h,000h	; 94d5  4..6.4..76.1.2.4..7.

; ----------------------------------------------------------------------
; DATOS frases_musica: Las cuatro frases que la musica llama con 0x34 (0x94E9,
;   0x9504, 0x9529 y 0x9548) y la cola comun de 0x9564 (0x9529 salta a ella;
;   0x956C vuelve a 0x950B)
;   0x94e9..0x956f  (134 bytes)
DATA_frases_musica:
	defb 027h,08fh,026h,01fh,028h,00fh,029h,007h,02ah,007h,036h,008h,031h,001h,032h,001h	; 94e9  '.&.(.).*.6.1.2.
	defb 003h,037h,029h,00fh,02ah,00fh,001h,029h,00ch,001h,035h,026h,01fh,031h,003h,032h	; 94f9  .7).*..)..5&.1.2
	defb 0ffh,001h,031h,0feh,032h,0ffh,001h,031h,001h,032h,001h,001h,026h,01eh,031h,0ffh	; 9509  ..1.2..1.2..&.1.
	defb 032h,0ffh,001h,026h,01dh,032h,001h,001h,026h,01ch,031h,0ffh,032h,001h,001h,035h	; 9519  2..&.2..&.1.2..5
	defb 027h,08eh,029h,00dh,02ah,00ch,078h,001h,036h,006h,038h,0fbh,002h,037h,07fh,002h	; 9529  '.).*.x.6.8..7..
	defb 075h,001h,036h,006h,038h,0fbh,001h,037h,036h,014h,038h,002h,033h,064h,095h,027h	; 9539  u.6.8..76.8.3d.'
	defb 08eh,029h,00dh,02ah,00ch,076h,001h,036h,007h,038h,0fch,001h,037h,079h,001h,036h	; 9549  .).*.v.6.8..7y.6
	defb 007h,038h,0fch,001h,037h,075h,001h,036h,010h,038h,0feh,001h,037h,027h,08fh,029h	; 9559  .8..7u.6.8..7'.)
	defb 00fh,02ah,00eh,033h,00bh,095h	; 9569

; ======================================================================
; CODIGO 0x956f..0x9682  (275 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Lectura del mando del equipo A (0 izquierda, otro derecha) =====
; ----------------------------------------------------------------------
lee_mando_lado:		; Devuelve en A los botones (bit 7 disparo, bit 6 pase), en C la direccion 0-7 (0xFF quieto) y en DE su (dx, dy); segun (0xEF98) cada lado es mando 1, mando 2 o la maquina
	push hl			;956f   ; guarda HL
	push af			;9570   ; y el lado (A)
	ld a,(0ef98h)		;9571   ; (0xEF98): modo de mandos 0-3, montado en 0x4089 con el bit 1 de 0xED56 y 0xED57 (equipo humano o maquina)
	ld c,a			;9574   ; C = modo
	add a,a			;9575   ; modo * 3: cada entrada de la tabla es un jp de tres bytes
	add a,c			;9576   ; A = modo * 3
	ld l,a			;9577   ; HL = desplazamiento en la tabla
	ld h,000h		;9578
	pop af			;957a   ; A = 0 equipo de la izquierda, otro el de la derecha
	and a			;957b   ; que lado?
	jr z,L_9583		;957c   ; cero: la izquierda
	ld de,mandos_derecha		;957e   ; tabla de la derecha
	jr L_9586		;9581
L_9583:
	ld de,mandos_izquierda		;9583   ; tabla de la izquierda
L_9586:
	add hl,de			;9586   ; HL = direccion del jp de este lado y modo
	ld de,mando_a_direccion		;9587   ; la vuelta comun 0x95A4, apilada: el jp elegido acaba con ret
	push de			;958a   ; vuelta en la pila
	jp (hl)			;958b   ; salta al lector del lado y modo
mandos_izquierda:		; Cuatro jp, uno por modo (0xEF98): mando 2, mando 1, maquina, maquina
	jp mando_2		;958c   ; modo 0: la izquierda con el mando 2
L_958F:
	jp mando_1		;958f   ; modo 1: la izquierda con el mando 1
L_9592:
	jp maquina_izquierda		;9592   ; modo 2: la izquierda la lleva la maquina
L_9595:
	jp maquina_izquierda		;9595   ; modo 3: las dos la maquina
mandos_derecha:		; Cuatro jp, uno por modo (0xEF98): mando 1, maquina, mando 1, maquina
	jp mando_1		;9598   ; modo 0: la derecha con el mando 1
L_959B:
	jp maquina_derecha		;959b   ; modo 1: la derecha la lleva la maquina
L_959E:
	jp mando_1		;959e   ; modo 2: la derecha con el mando 1
L_95A1:
	jp maquina_derecha		;95a1   ; modo 3: las dos la maquina
mando_a_direccion:		; Vuelta comun: convierte la direccion GTSTCK (1-8) en indice 0-7 y (dx, dy) de 0x9682; la maquina (bit 0 de A) se salta la conversion
	bit 0,a		;95a4   ; bit 0 de A: lo devuelve la maquina (0x01 o 0x81), no un mando
	jr nz,L_95B4		;95a6   ; maquina: sin tabla de direcciones
	ld l,c			;95a8   ; C = direccion GTSTCK 0-8
	ld h,000h		;95a9   ; HL = direccion * 2
	add hl,hl			;95ab
	ld de,09682h		;95ac   ; nueve pares (dx, dy), el 0 es quieto
	add hl,de			;95af   ; HL = su par (dx, dy)
	ld d,(hl)			;95b0   ; D = dx
	inc hl			;95b1
	ld e,(hl)			;95b2   ; E = dy
	dec c			;95b3   ; direccion 1-8 -> 0-7; quieto -> 0xFF
L_95B4:
	push af			;95b4   ; guarda los botones
	ld a,(0ef8dh)		;95b5   ; (0xEF8D): jugador cuyo mando se ignora (0xFF = ninguno; 0x5E6B lo pone a 0xFF al empezar)
	and a			;95b8   ; 0xFF: ningun jugador bloqueado
	jp m,L_95C7		;95b9
	ld hl,0ebd6h		;95bc   ; (0xEBD6): jugador que se esta leyendo
	cp (hl)			;95bf   ; es este el bloqueado?
	jr nz,L_95C7		;95c0
	ld c,0ffh		;95c2   ; si es el ignorado: quieto y sin movimiento
	ld de,00000h		;95c4   ; DE = 0: no se mueve
L_95C7:
	pop af			;95c7   ; recupera los botones
	pop hl			;95c8   ; y HL
	ret			;95c9
mando_1:		; Mando 1: joystick 1 y, si no da nada, los cursores con '[' (fila 1, bit 6) como disparo y RETURN (fila 7, bit 7) como pase
	call joystick_1		;95ca   ; primero el joystick 1
	ld b,a			;95cd   ; B = botones
	and 0c0h		;95ce   ; algun boton o alguna direccion del joystick: vale
	or c			;95d0   ; botones o direccion: hay entrada
	ld a,b			;95d1   ; A = botones
	ret nz			;95d2   ; con entrada del joystick, listo
	ld a,000h		;95d3   ; GTSTCK 0: los cursores del teclado
	call 000d5h		;95d5   ; BIOS GTSTCK - Returns the joystick status
	ld c,a			;95d8   ; C = direccion de los cursores
	ld a,001h		;95d9   ; fila 1 del teclado: 8 9 - ^ \ @ [ ;
	push bc			;95db   ; SNSMAT no respeta BC
	call 00141h		;95dc   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;95df
	ld b,000h		;95e0   ; B = botones, de momento ninguno
	xor 0ffh		;95e2   ; a 1 las pulsadas
	bit 6,a		;95e4   ; '[' pulsada: disparo
	jr z,L_95EA		;95e6   ; '[' no pulsada
	set 7,b		;95e8   ; bit 7: disparo
L_95EA:
	ld a,007h		;95ea   ; fila 7: F4 F5 ESC TAB STOP BS SELECT RETURN
	push bc			;95ec   ; SNSMAT no respeta BC
	call 00141h		;95ed   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;95f0
	xor 0ffh		;95f1
	bit 7,a		;95f3   ; RETURN pulsada: pase
	jr z,L_95F9		;95f5   ; RETURN no pulsada
	set 6,b		;95f7   ; bit 6: pase
L_95F9:
	ld a,b			;95f9   ; A = botones
	ret			;95fa
joystick_1:		; Joystick 1: GTSTCK 1 en C, GTTRIG 1 y 3 (los dos botones) en los bits 7 y 6 de A
	ld a,001h		;95fb   ; GTSTCK 1: el joystick del puerto 1
	call 000d5h		;95fd   ; BIOS GTSTCK - Returns the joystick status
	ld c,a			;9600   ; C = direccion 0-8
	ld b,000h		;9601   ; B = botones
	ld a,001h		;9603   ; GTTRIG 1: boton A del puerto 1
	push bc			;9605   ; GTTRIG no respeta BC
	call 000d8h		;9606   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;9609
	and a			;960a   ; pulsado?
	jr z,L_960F		;960b
	set 7,b		;960d   ; bit 7: disparo
L_960F:
	ld a,003h		;960f   ; GTTRIG 3: boton B del puerto 1
	push bc			;9611
	call 000d8h		;9612   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;9615
	and a			;9616   ; pulsado?
	jr z,L_961B		;9617
	set 6,b		;9619   ; bit 6: pase
L_961B:
	ld a,b			;961b   ; A = botones
	ret			;961c
mando_2:		; Mando 2: joystick 2 y, si no da nada, cuatro teclas de las filas 3 y 5 convertidas con la tabla 0x9694, con TAB (fila 7, bit 3) como disparo y CTRL (fila 6, bit 1) como pase
	call joystick_2		;961d   ; primero el joystick 2
	ld b,a			;9620   ; B = botones
	and 0c0h		;9621   ; solo los bits de boton
	or c			;9623   ; botones o direccion: hay entrada
	ld a,b			;9624   ; A = botones
	ret nz			;9625   ; con entrada del joystick, listo
	ld a,003h		;9626   ; fila 3 del teclado: B C D E F G H I
	call 00141h		;9628   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 00eh		;962b   ; se quedan C, D y E (bits 1-3)
	ld c,a			;962d   ; C = C, D, E en los bits 1-3
	ld a,005h		;962e   ; fila 5 del teclado: R S T U V W X Y
	push bc			;9630   ; SNSMAT no respeta BC
	call 00141h		;9631   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;9634
	and 001h		;9635   ; se queda R (bit 0)
	or c			;9637   ; mas R en el bit 0
	xor 00fh		;9638   ; a 1 las pulsadas: cuatro bits, 16 combinaciones
	ld d,000h		;963a   ; DE = indice en la tabla
	ld e,a			;963c
	ld hl,09694h		;963d   ; combinacion -> direccion GTSTCK 0-8
	add hl,de			;9640
	ld c,(hl)			;9641   ; C = direccion 0-8
	ld b,000h		;9642   ; B = botones, de momento ninguno
	ld a,007h		;9644   ; fila 7: TAB es el bit 3
	push bc			;9646   ; SNSMAT no respeta BC
	call 00141h		;9647   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;964a
	bit 3,a		;964b   ; TAB pulsada: disparo
	jr nz,L_9651		;964d   ; TAB no pulsada
	set 7,b		;964f   ; bit 7: disparo
L_9651:
	ld a,006h		;9651   ; fila 6: SHIFT CTRL GRAPH CAPS CODE F1 F2 F3
	push bc			;9653   ; SNSMAT no respeta BC
	call 00141h		;9654   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;9657
	bit 1,a		;9658   ; CTRL pulsada: pase
	jr nz,L_965E		;965a   ; CTRL no pulsada
	set 6,b		;965c   ; bit 6: pase
L_965E:
	ld a,b			;965e   ; A = botones
	ret			;965f
joystick_2:		; Joystick 2: GTSTCK 2 en C, GTTRIG 2 y 4 en los bits 7 y 6 de A
	ld a,002h		;9660   ; GTSTCK 2: el joystick del puerto 2
	call 000d5h		;9662   ; BIOS GTSTCK - Returns the joystick status
	ld c,a			;9665   ; C = direccion 0-8
	ld b,000h		;9666   ; B = botones
	ld a,002h		;9668   ; GTTRIG 2: boton A del puerto 2
	push bc			;966a   ; GTTRIG no respeta BC
	call 000d8h		;966b   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;966e
	and a			;966f   ; pulsado?
	jr z,L_9674		;9670
	set 7,b		;9672   ; bit 7: disparo
L_9674:
	ld a,004h		;9674   ; GTTRIG 4: boton B del puerto 2
	push bc			;9676
	call 000d8h		;9677   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;967a
	and a			;967b   ; pulsado?
	jr z,L_9680		;967c
	set 6,b		;967e   ; bit 6: pase
L_9680:
	ld a,b			;9680   ; A = botones
	ret			;9681

; ----------------------------------------------------------------------
; DATOS nueve_direcciones: Nueve pares (dx, dy): quieto y las ocho direcciones
;   del mando en el orden de GTSTCK
;   0x9682..0x9694  (18 bytes)
DATA_nueve_direcciones:
	defb 000h,000h	; 9682
	defb 0ffh,000h	; 9684
	defb 0ffh,001h	; 9686
	defb 000h,001h	; 9688
	defb 001h,001h	; 968a
	defb 001h,000h	; 968c
	defb 001h,0ffh	; 968e
	defb 000h,0ffh	; 9690
	defb 0ffh,0ffh	; 9692

; ----------------------------------------------------------------------
; DATOS cursores_a_direccion: 16 entradas: para cada combinacion de las cuatro
;   teclas del cursor (fila 8 del teclado, xor 0x0F), la direccion 0-8 como la
;   da GTSTCK; la lee 0x963D
;   0x9694..0x96a4  (16 bytes)
DATA_cursores_a_direccion:
	defb 000h,007h,005h,006h,001h,008h,000h,007h,003h,000h,004h,005h,002h,001h,003h,000h	; 9694  ................

; ======================================================================
; CODIGO 0x96a4..0x9b25  (1153 bytes)
; ======================================================================


maquina_izquierda:		; El equipo de la izquierda lo lleva la maquina: decide con 0x971B o 0x997A segun que lado ataque (bit 0 de 0xECF1)
	ld hl,0ef96h		;96a4   ; (0xEF96): flag del lado izquierdo
	call flag_a_codigo		;96a7   ; A = 0x81 si hay orden pendiente, 0x01 si no
	push af			;96aa   ; guarda el codigo
	ld a,(0ecf1h)		;96ab   ; (0xECF1) bit 0: los lados estan cambiados
	and 001h		;96ae   ; bit 0: lados cambiados
	jr nz,L_96B7		;96b0   ; cambiados: decide como el otro lado
	call decide_defensor_libre		;96b2   ; la izquierda defiende: por 0x9974
	jr L_96BA		;96b5
L_96B7:
	call decide_atacante		;96b7   ; el mismo codigo que el otro lado pero al reves
L_96BA:
	jr L_96D2		;96ba
maquina_derecha:		; El equipo de la derecha lo lleva la maquina
	ld hl,0ef97h		;96bc   ; (0xEF97): flag del lado derecho
	call flag_a_codigo		;96bf   ; A = 0x81 si hay orden pendiente, 0x01 si no
	push af			;96c2   ; guarda el codigo
	ld a,(0ecf1h)		;96c3
	and 001h		;96c6   ; bit 0: lados cambiados
	jr nz,L_96CF		;96c8   ; cambiados: decide como el otro lado
	call decide_atacante		;96ca   ; la derecha ataca: decide_atacante
	jr L_96D2		;96cd
L_96CF:
	call decide_defensor_libre		;96cf   ; la derecha defiende: por 0x9974
L_96D2:
	call anda_al_destino		;96d2   ; decide el movimiento del jugador IX
	push ix		;96d5   ; HL = su registro
	pop hl			;96d7
	pop af			;96d8   ; recupera el codigo
	ret nz			;96d9   ; con orden pendiente (0x81): devuelve el codigo tal cual
	ld a,(ix+00ch)		;96da   ; (IX+0x0C) a cero: devuelve 1 (sin boton)
	and a			;96dd   ; lleva el balon?
	jr nz,boton_de_la_maquina		;96de   ; si: mira si tira
	ld a,001h		;96e0   ; no: sin boton
	ret			;96e2
flag_a_codigo:		; A = 0x81 si (HL) no es cero, 0x01 si lo es: el bit 0 marca "maquina" para 0x95A4 y el 7 el disparo
	ld a,(hl)			;96e3   ; la orden pendiente del lado
	and a			;96e4
	ld a,081h		;96e5   ; 0x81: maquina con orden
	ret nz			;96e7
	ld a,001h		;96e8   ; 0x01: maquina sin orden
	ret			;96ea
boton_de_la_maquina:		; 0x81 (disparo) si (IX+0x0B) es negativo, 0x01 si no
	ld a,(ix+00bh)		;96eb
	and a			;96ee   ; (IX+0x0B) negativo: tirar
	ld a,081h		;96ef   ; 0x81: disparo
	ret m			;96f1
	ld a,001h		;96f2   ; 0x01: sin boton
	ret			;96f4
huerfano_es_el_controlado:		; Huerfano: devuelve 0 si el jugador controlado es el que se esta leyendo (0xEBD6), y si no el bit 6 del campo +0x0F de su registro por el +0x0F*4
	call controlado		;96f5
	ld hl,0ebd6h		;96f8   ; (0xEBD6): jugador que se esta leyendo
	cp (hl)			;96fb   ; el controlado es el que se lee?
	jr nz,L_9700		;96fc
	xor a			;96fe   ; si: cero
	ret			;96ff
L_9700:
	call registro_jugador		;9700   ; HL = registro del jugador A
pose_bit6:		; Devuelve en el flag Z el bit 6 del campo +0x0F del jugador A mezclado con el mismo campo por cuatro (la direccion de la pose)
	push hl			;9703   ; guarda el registro
	push de			;9704   ; y DE
	ld de,0000fh		;9705   ; campo +0x0F: patrones de la pose
	add hl,de			;9708
	pop de			;9709
	ld a,(hl)			;970a   ; A = patrones de la pose
	ld c,a			;970b   ; C = copia
	add a,a			;970c   ; por cuatro
	add a,a			;970d
	xor (hl)			;970e   ; mezclado con el original
	pop hl			;970f   ; recupera el registro
	bit 6,a		;9710   ; el bit 6 decide
	ret			;9712
sin_movimiento:		; A = 1 (sin boton), DE = 0 y C = 0x3F: la maquina no mueve a este jugador
	ld a,001h		;9713   ; sin boton
	ld de,00000h		;9715   ; sin movimiento
	ld c,03fh		;9718   ; direccion ninguna
	ret			;971a
decide_atacante:		; La maquina con el balon: segun el estado de 0xEF8F elige objetivo (0), corre a el (1), encara la canasta (2), tira (3) o espera (4); deja el destino en (IX+0x20, IX+0x21)
	call indice_controlado		;971b   ; B = indice del controlado
	call registro_jugador		;971e   ; HL = registro del controlado
	push hl			;9721   ; IY = ese registro
	pop iy		;9722
	push hl			;9724   ; y lo guarda para despues
	ld e,(iy+001h)		;9725   ; Y (profundidad, +1) del jugador en curso (IY = su registro)
	call cuantos_controla		;9728   ; A = cuantos jugadores controla la maquina en este lado, B = el indice
	ld hl,0c533h		;972b   ; (0xC533): X del balon a lo largo de la pista (+3 del registro 0xC530, con signo desde el centro), bit 7 = en la mitad izquierda
	bit 7,(hl)		;972e   ; bit 7: el balon en la mitad izquierda
	pop hl			;9730   ; recupera el registro
	jr nz,L_973B		;9731   ; mitad izquierda: 0x973B
	cp 003h		;9733   ; menos de tres controlados: destino X = 0xE2 (-30, hacia la canasta izquierda)
	jr nc,L_9748		;9735   ; tres o mas controlados: decidir de verdad
L_9737:
	ld d,0e2h		;9737   ; D = X del destino
	jr L_9741		;9739   ; a dejar el destino
L_973B:
	cp 003h		;973b
	jr c,L_9748		;973d   ; menos de tres controlados: decidir de verdad
L_973F:
	ld d,01eh		;973f   ; o X = 0x1E (+30, hacia la derecha)
L_9741:
	ld (ix+021h),d		;9741   ; destino: (IX+0x20) = Y (profundidad), (IX+0x21) = X
	ld (ix+020h),e		;9744   ; destino Y = la del controlado
	ret			;9747
L_9748:
	ld a,(0ef8fh)		;9748   ; (0xEF8F): estado del ataque de la maquina, 0-4
	cp 001h		;974b   ; estado 1: corriendo al destino
	jp z,ataque_corriendo		;974d
	cp 002h		;9750   ; estado 2: encarando
	jp z,ataque_encarando		;9752
	cp 003h		;9755   ; estado 3: al punto de tiro
	jp z,ataque_al_punto_de_tiro		;9757
	cp 004h		;975a   ; estado 4: esperando el tiro
	jp z,ataque_tira		;975c
	push hl			;975f   ; estado 0: guarda el registro
	call hay_sitio_para_tirar		;9760   ; hay sitio para tirar? (acarreo: si)
	pop hl			;9763   ; recupera el registro
	jp c,ataque_estado_4		;9764   ; con sitio para tirar: al estado 4
	call angulo_y_distancia_a_canasta		;9767   ; angulo (B) y distancia (A) del jugador HL a la canasta de 0xC5D3
	ld c,a			;976a   ; C = distancia del controlado
	ld e,b			;976b   ; E = su angulo
	push ix		;976c   ; HL = registro del jugador IX
	pop hl			;976e
	call angulo_y_distancia_a_canasta		;976f   ; lo mismo para el jugador IX
	ld b,a			;9772   ; B = distancia del jugador IX
	ld a,c			;9773   ; A = distancia del controlado
	sub b			;9774   ; diferencia de distancias
	jr c,L_9787		;9775   ; el jugador IX mas lejos
	cp 00bh		;9777   ; menos de 11: se acerca con la tabla C2 del desfase
	jr nc,L_9787		;9779
	ld a,(iy+00ch)		;977b
	and a			;977e
	jp nz,L_97F7		;977f
	call seno_y_coseno		;9782   ; seno y coseno del angulo del controlado
	jr L_9795		;9785   ; a calcular el punto
L_9787:
	call seno_y_coseno		;9787   ; seno y coseno del angulo del controlado
	ld a,c			;978a   ; A = distancia del controlado
	sub 00ah		;978b   ; a menos de 10 se queda quieto
	jr nc,L_9794		;978d
	ld de,00000h		;978f   ; quieto
	jr L_97A1		;9792   ; a dejar el destino
L_9794:
	ld b,a			;9794   ; B = distancia menos 10
L_9795:
	ld a,b			;9795   ; A = la distancia que se avanza
	push af			;9796   ; guardada
	call producto_con_signo		;9797   ; componente X: B * coseno (0x97C3)
	ex de,hl			;979a   ; HL = componente X, DE = seno
	pop af			;979b   ; A = la distancia otra vez
	call producto_con_signo		;979c   ; componente Y: B * seno
	ex de,hl			;979f   ; HL = componente Y, DE = componente X
	ld e,h			;97a0   ; E = X del destino
L_97A1:
	call guarda_posicion_en_f00c		;97a1   ; guarda la posicion del jugador en curso en 0xEF92/0xEF93
	ld a,e			;97a4   ; A = X del destino
	ld (0ef94h),a		;97a5   ; (0xEF94): X del destino
	ld a,d			;97a8   ; A = Y del destino
	add a,039h		;97a9   ; (0xEF95): Y del destino, 0x39 (la mitad de la pista) mas
	ld (0ef95h),a		;97ab
	ld a,001h		;97ae   ; estado 1: correr al destino
	ld (0ef8fh),a		;97b0
L_97B3:
	call corrige_destino_x		;97b3   ; corrige el destino con la posicion de los companeros
	ld a,(0ef95h)		;97b6   ; Y del destino al registro
	ld (ix+020h),a		;97b9
	ld a,(0ef94h)		;97bc   ; y la X
	ld (ix+021h),a		;97bf
	ret			;97c2
producto_con_signo:		; HL = A * L con el signo de H (multiplica16 y niega_hl)
	push bc			;97c3   ; guarda BC
	push de			;97c4   ; y DE
	ld e,a			;97c5   ; DE = A
	ld d,000h		;97c6
	ld a,h			;97c8   ; el bit 7 de H es el signo
	and a			;97c9
	push af			;97ca   ; guarda el signo
	ld h,000h		;97cb   ; HL = L sin signo
	call multiplica16		;97cd   ; HL = A * L
	pop af			;97d0   ; recupera el signo
	call m,niega_hl		;97d1   ; negativo: HL = -HL
	pop de			;97d4   ; recupera DE
	pop bc			;97d5   ; y BC
	ret			;97d6
seno_y_coseno:		; Devuelve en HL y DE las dos entradas de la tabla C2 del angulo E (0xC000-0xC2FF, montadas por 0x67DF)
	push bc			;97d7   ; guarda BC
	ld a,e			;97d8   ; A = angulo
	push af			;97d9   ; guardado
	call tabla_c2_desfase		;97da   ; HL = entrada de la tabla con desfase (coseno)
	pop af			;97dd   ; A = angulo otra vez
	push de			;97de   ; guarda el coseno
	call tabla_c2		;97df   ; HL = entrada sin desfase (seno)
	ex de,hl			;97e2   ; DE = seno
	pop de			;97e3   ; HL = coseno
	pop bc			;97e4   ; recupera BC
	ret			;97e5
ataque_corriendo:		; Estado 1: al llegar al destino, si el controlado ya no tiene el balon pasa al estado 0; si lo tiene, estado 2 y 0x12 cuadros de espera (IX+0x26)
	call ha_llegado		;97e6   ; ha llegado el controlado?
	ret nc			;97e9   ; no: sigue corriendo
	ld a,(ix+020h)		;97ea   ; (IX+0x20/0x21) a cero: ya ha llegado
	or (ix+021h)		;97ed   ; destino pendiente
	ret nz			;97f0   ; pendiente: nada
	ld a,(iy+00ch)		;97f1   ; (IY+0x0C): el jugador en curso lleva el balon
	and a			;97f4   ; lleva el balon?
	jr z,L_9805		;97f5   ; no: a encarar
L_97F7:
	call cuantos_controla		;97f7   ; A = controlados, B = indice
	push af			;97fa   ; guarda A
	xor a			;97fb   ; estado 0
	ld (0ef8fh),a		;97fc   ; vuelve al estado 0
	pop af			;97ff   ; recupera A
	ld c,015h		;9800   ; C = 0x15: la orden (la primera version: 0x10, la de tirar)
	jp L_9AC8		;9802   ; a dejar la orden en el lado
L_9805:
	call guarda_posicion_en_f00c		;9805   ; guarda la posicion
	ld (ix+026h),012h		;9808   ; (IX+0x26): cuadros de espera antes de tirar
	ld a,002h		;980c   ; estado 2: encarar la canasta
	ld (0ef8fh),a		;980e
	ret			;9811
ataque_encarando:		; Estado 2: pasada la espera, calcula el punto a cuatro de distancia de la canasta en la direccion del jugador y pasa al estado 3
	ld a,(iy+00ch)		;9812
	and a			;9815   ; lleva el balon?
	jr nz,L_97F7		;9816   ; si: a 0x97F7 (orden de tirar)
	ld a,(ix+026h)		;9818
	and a			;981b   ; espera agotada?
	ret nz			;981c   ; no: nada
	call ha_llegado		;981d   ; ha llegado?
	ret nc			;9820   ; no: nada
	ld hl,0c530h		;9821   ; 0xC530: el registro del balon
	call angulo_y_distancia_a_canasta		;9824   ; A = distancia del balon a la canasta, B = angulo
	sub 004h		;9827   ; cuatro menos: el punto de tiro
	push af			;9829   ; guarda distancia - 4
	ld e,b			;982a   ; E = angulo
	call seno_y_coseno		;982b   ; seno y coseno
	pop af			;982e   ; A = distancia - 4
	push af			;982f   ; guardada otra vez
	ex de,hl			;9830   ; HL = seno
	call producto_con_signo		;9831   ; HL = componente Y
	ld a,h			;9834   ; A = Y del punto
	add a,039h		;9835   ; mas la mitad de la pista
	ld (0ef95h),a		;9837   ; (0xEF95): Y del punto de tiro
	pop af			;983a   ; A = distancia - 4
	ex de,hl			;983b   ; HL = coseno
	call producto_con_signo		;983c   ; HL = componente X
	ld a,h			;983f   ; A = X del punto
	ld (0ef94h),a		;9840   ; (0xEF94): X del punto de tiro
	ld a,003h		;9843   ; estado 3: ir al punto de tiro
	ld (0ef8fh),a		;9845
	jp L_97B3		;9848   ; a dejar el destino
ataque_al_punto_de_tiro:		; Estado 3: en cuanto llega (destino a cero) pasa al estado 4
	ld a,(ix+020h)		;984b
	or (ix+021h)		;984e   ; destino pendiente?
	ret nz			;9851   ; pendiente: nada
ataque_estado_4:		; Estado 4: esperar el tiro
	ld a,004h		;9852   ; estado 4
	ld (0ef8fh),a		;9854
	ret			;9857
ataque_tira:		; Estado 4: si hay sitio tira (bit 0 de la pose); si no, al azar, roba o pasa el balon a un companero (0xCB34-0xCB36)
	call hay_sitio_para_tirar		;9858   ; hay sitio?
	jr c,L_9867		;985b   ; si: tira (0x9867)
	res 0,(ix+00dh)		;985d   ; sin sitio: quita el bit 0 de la pose
	call ha_llegado		;9861   ; ha llegado?
	jr c,L_9805		;9864   ; si: guarda la posicion y estado 2
	ret			;9866
L_9867:
	call azar_r		;9867   ; un byte al azar
	and 003h		;986a   ; una de cada cuatro veces sigue
	ret nz			;986c
	set 0,(ix+00dh)		;986d   ; bit 0 de la pose: tirando
	call azar_r		;9871   ; azar contra la habilidad (IX+0x1D)
	cp (ix+01dh)		;9874   ; contra la habilidad (IX+0x1D)
	jr nc,L_987F		;9877   ; pierde: a pasar
	call roba_balon		;9879   ; gana: roba el balon
	jp L_996F		;987c   ; estado 0
L_987F:
	call puede_pasar		;987f   ; puede pasar? (azar contra (IX+0x1E))
	ret nc			;9882   ; no puede: nada
	xor a			;9883   ; estado 0 de nuevo
	ld (0ef8fh),a		;9884
pasa_a_un_companero:		; Elige al azar el companero 6, 7 u 8 y anota el pase: (0xCB34) controlados, (0xCB36) quien pasa, (0xCB35) a quien
	call azar_r		;9887
	and 003h		;988a   ; 0-3
	add a,006h		;988c   ; companero 6 o 7 u 8 al azar: a quien pasa
	ld e,a			;988e   ; E = a quien
	call cuantos_controla		;988f   ; A = controlados, B = indice del que pasa
L_9892:
	ld (0cb34h),a		;9892   ; (0xCB34): pase en marcha, (0xCB36) y (0xCB35) de quien a quien
	ld a,b			;9895   ; (0xCB36): quien pasa
	ld (0cb36h),a		;9896
	ld a,e			;9899   ; (0xCB35): a quien
	ld (0cb35h),a		;989a
	ret			;989d
puede_pasar:		; Acarreo si el juego esta parado para decidir y un byte al azar no llega a la habilidad (IX+0x1E)
	call se_puede_decidir		;989e
	ret nc			;98a1   ; no se puede decidir: no
	call azar_r		;98a2   ; un byte al azar
	cp (ix+01eh)		;98a5   ; contra la habilidad (IX+0x1E): acarreo si menor
	ret			;98a8
hay_sitio_para_tirar:		; Acarreo si nadie lleva el balon, el balon esta a menos de 12 del centro (0xC533) y el jugador IX a menos de 8 de el
	call se_puede_decidir		;98a9
	ret nc			;98ac   ; no se puede decidir: no
	ld a,(0c533h)		;98ad   ; (0xC533): X del balon, con signo
	bit 7,a		;98b0   ; mitad izquierda?
	jr z,L_98B6		;98b2   ; no: ya es positivo
	neg		;98b4   ; en valor absoluto
L_98B6:
	cp 00ch		;98b6   ; a 12 o mas del centro: no
	jr nc,L_98BC		;98b8
	ccf			;98ba   ; acarreo: hay sitio
	ret			;98bb
L_98BC:
	call quien_ataca		;98bc   ; quien ataca
	ret nz			;98bf   ; nadie ataca: no
	ld hl,0c41ch		;98c0   ; campo +0x0C de los seis registros: alguien lleva el balon?
	ld b,006h		;98c3   ; los seis jugadores
	ld de,00030h		;98c5   ; 0x30 bytes por registro
L_98C8:
	ld a,(hl)			;98c8
	and a			;98c9   ; lleva el balon?
	ret nz			;98ca   ; si: no hay sitio
	add hl,de			;98cb   ; siguiente registro
	djnz L_98C8		;98cc
	ld a,(0c531h)		;98ce   ; (0xC531): Y (profundidad) del balon
	sub (ix+001h)		;98d1   ; E = diferencia de Y
	ld e,a			;98d4
	ld a,(0c533h)		;98d5
	sub (ix+003h)		;98d8   ; L = diferencia de X
	ld l,a			;98db
	call distancia		;98dc   ; distancia del jugador IX al balon
	cp 006h		;98df   ; acarreo si menos de 6 (la primera version: 8)
	ret			;98e1
se_puede_decidir:		; Acarreo (A = 6) si no hay falta ni tiempo muerto en marcha: 0xC5DF sin los bits 3 y 4, 0xCB28 y 0xED67 a cero y el estado del juego (0xC5DF & 7) por debajo de 6
	ld a,(0c5dfh)		;98e2   ; (0xC5DF): estado del partido, bits 3 y 4 = la ventana se esta moviendo
	and 018h		;98e5   ; la ventana se mueve: no
	ret nz			;98e7
	ld a,(0cb28h)		;98e8   ; (0xCB28): falta en marcha
	and a			;98eb   ; falta en marcha: no
	ret nz			;98ec
	ld a,(0ed67h)		;98ed   ; (0xED67): tiempo parado
	and a			;98f0   ; tiempo parado: no
	ret nz			;98f1
	ld a,(0ed5eh)		;98f2
	and a			;98f5
	ret nz			;98f6
	ld a,(0c5dfh)		;98f7
	and 007h		;98fa   ; estado del juego 0-7
	cp 006h		;98fc   ; acarreo si menos de 6
	ret			;98fe
quien_ataca:		; A = (0xC5E4) o (0xC5E6) segun el lado (0xECF1): el equipo que tiene el balon
	ld hl,0c5e4h		;98ff   ; (0xC5E4): quien ataca, lado normal
	ld a,(0ecf1h)		;9902
	and a			;9905   ; lados cambiados?
	jr z,L_990A		;9906
	inc hl			;9908   ; (0xC5E6): quien ataca, lados cambiados
	inc hl			;9909
L_990A:
	ld a,(hl)			;990a
	and a			;990b   ; cero = nadie
	ret			;990c
guarda_posicion_en_f00c:		; Copia la Y (IY+1) y la X (IY+3) del jugador en curso a 0xEF93 y 0xEF92
	ld a,(iy+001h)		;990d   ; Y del controlado
	ld (0ef93h),a		;9910   ; (0xEF93): Y guardada
	ld a,(iy+003h)		;9913   ; X del controlado
	ld (0ef92h),a		;9916   ; (0xEF92): X guardada
	ret			;9919
angulo_y_distancia_a_canasta:		; Para el jugador HL: A = distancia y B = angulo hasta la canasta de 0xC5D3
	push hl			;991a   ; guarda HL
	push de			;991b   ; y DE
	ld de,0c5d3h		;991c   ; 0xC5D3: la posicion de la canasta a la que se ataca
	call xy_dos_registros		;991f   ; DE y HL = la Y y la X de los dos
	call diferencia_xy		;9922   ; diferencias
	push bc			;9925
	push de			;9926
	push hl			;9927
	call angulo		;9928   ; A = angulo
	pop hl			;992b
	pop de			;992c
	pop bc			;992d
	ld b,a			;992e   ; B = angulo
	push bc			;992f
	call distancia		;9930   ; A = distancia
	pop bc			;9933
	pop de			;9934
	pop hl			;9935
	ret			;9936
cuantos_controla:		; A = los jugadores que controla la maquina en este lado y B = el indice que devuelve 0x4ED8, con los flags de aquel
	push bc			;9937
	call controlados		;9938   ; A = controlados, B = indice
	pop bc			;993b
	ld b,a			;993c   ; B = indice
	ex af,af'			;993d   ; los flags que devolvio 0x4ED8
	push af			;993e
	ex af,af'			;993f
	pop af			;9940
	ret			;9941
corrige_destino_x:		; Suma a la X del destino (0xEF94) la X de la canasta de 0xC5D6
	push bc			;9942   ; guarda BC
	ld a,(0c5d6h)		;9943   ; (0xC5D6): X de la canasta que se ataca
	ld b,a			;9946   ; B = X de la canasta
	ld a,(0ef94h)		;9947   ; X del destino
	add a,b			;994a
	ld (0ef94h),a		;994b   ; corregida
	pop bc			;994e   ; recupera BC
	ret			;994f
huerfano_niega_si_negativo:		; Huerfano: niega HL si H es negativo (nadie lo llama)
	ld a,h			;9950
	and a			;9951   ; H negativo?
	ret p			;9952   ; no: tal cual
	jp niega_hl		;9953   ; si: HL = -HL
indice_controlado:		; A = el indice que devuelve 0x9937 (el jugador controlado de este lado)
	push bc			;9956   ; guarda BC
	call cuantos_controla		;9957
	ld a,b			;995a   ; A = indice
	pop bc			;995b
	ret			;995c
ha_llegado:		; Acarreo si el jugador en curso (IY) esta justo en la posicion guardada en 0xEF92/0xEF93; si no, estado 0
	ld a,(0ef93h)		;995d   ; (0xEF93): Y guardada
	sub (iy+001h)		;9960   ; misma Y?
	jr nz,L_996F		;9963   ; no: estado 0
	ld a,(0ef92h)		;9965   ; (0xEF92): X guardada
	sub (iy+003h)		;9968   ; misma X?
	jr nz,L_996F		;996b   ; no: estado 0
	scf			;996d   ; acarreo: ha llegado
	ret			;996e
L_996F:
	xor a			;996f   ; (0xEF8F): estado del ataque a cero
	ld (0ef8fh),a		;9970
	ret			;9973
decide_defensor_libre:		; Si hay una orden pendiente (0xEF96 izquierda, 0xEF97 derecha) no decide nada; si no, sigue en decide_defensor. La primera version llamaba a decide_defensor directamente
	ld hl,(0ef96h)		;9974   ; ordenes pendientes de los dos lados
	ld a,h			;9977   ; alguna?
	or l			;9978
	ret nz			;9979   ; si: nada
decide_defensor:		; La maquina sin el balon: segun 0xEF90 va a por el que lo lleva (0), lo marca (1) o se queda (2); con 0xEF8E a uno no se mueve
	ld a,(0ef8eh)		;997a   ; (0xEF8E): a uno, la defensa no se mueve
	and a			;997d   ; defensa parada?
	jp nz,sin_movimiento		;997e   ; si: sin movimiento
	ld e,039h		;9981   ; E = 0x39, la Y de la mitad de la pista
	call indice_controlado		;9983   ; A = controlados, B = indice
	ld hl,0c533h		;9986   ; (0xC533): X del balon, bit 7 = mitad izquierda
	bit 7,(hl)		;9989   ; bit 7: balon en la mitad izquierda
	jr nz,L_9994		;998b   ; izquierda: 0x9994
	cp 003h		;998d   ; menos de tres controlados: destino abajo (0x9737)
	jp nc,L_9737		;998f   ; tres o mas: destino X = -30 y Y = la mitad
	jr L_9999		;9992   ; a decidir de verdad
L_9994:
	cp 003h		;9994   ; o arriba (0x973F)
	jp c,L_973F		;9996   ; menos de tres: destino X = +30 y Y = la mitad
L_9999:
	call cuantos_controla		;9999   ; A = controlados, B = indice
	call registro_jugador		;999c   ; HL = registro del controlado
	push hl			;999f
	pop iy		;99a0   ; IY = ese registro
	ld a,(0ef90h)		;99a2   ; (0xEF90): estado de la defensa, 0-2
	cp 001h		;99a5   ; estado 1: a por el balon
	jp z,defensa_estado_1		;99a7
	cp 002h		;99aa   ; estado 2: marcando
	jp z,defensa_estado_2		;99ac
	ld a,(ix+020h)		;99af   ; destino pendiente: nada que decidir
	or (ix+021h)		;99b2   ; destino pendiente?
	ret nz			;99b5   ; pendiente: nada
	call distancia_a_canasta		;99b6   ; distancia del jugador IX a la canasta
	cp 014h		;99b9   ; a menos de 20 de la canasta: se queda
	jp c,L_9ABF		;99bb   ; a menos de 20 de la canasta: se queda (0x9ABF)
	ld a,(0ed7bh)		;99be   ; (0xED7B): el reloj de los 30 segundos corre
	and a			;99c1
	jp z,L_9ABF		;99c2   ; los 30 segundos no corren: se queda (0x9ABF)
	push iy		;99c5   ; HL = registro del controlado
	pop hl			;99c7
	call angulo_y_distancia_a_canasta		;99c8   ; angulo y distancia del controlado (IY) a la canasta
	ld c,a			;99cb   ; C = distancia del controlado
	push bc			;99cc   ; guarda angulo y distancia
	push ix		;99cd   ; HL = registro del jugador IX
	pop hl			;99cf
	call angulo_y_distancia_a_canasta		;99d0   ; y los del jugador IX
	ld e,b			;99d3   ; E = angulo del jugador IX
	pop bc			;99d4   ; B = angulo del controlado, C = su distancia
	sub c			;99d5   ; el defensor mas lejos que el atacante: no vale
	jr c,L_9A18		;99d6
	ld a,e			;99d8   ; A = angulo IX
	sub b			;99d9   ; menos el del controlado
	jr nc,L_99DE		;99da
	neg		;99dc   ; en valor absoluto
L_99DE:
	cp 040h		;99de   ; diferencia de angulo de 64 o mas: no vale
	jr nc,L_9A18		;99e0
	call seno_y_coseno		;99e2   ; seno y coseno del angulo del atacante
	ld a,c			;99e5   ; A = distancia del controlado
	push af			;99e6   ; guardada
	call producto_con_signo		;99e7   ; HL = componente X
	ex de,hl			;99ea   ; DE = X, HL = seno
	pop af			;99eb   ; A = distancia otra vez
	call producto_con_signo		;99ec   ; HL = componente Y
	ld c,h			;99ef   ; C = Y del punto
	ld a,d			;99f0   ; A = X del punto
	ld (0ef94h),a		;99f1   ; (0xEF94): X del punto entre los dos
	call corrige_destino_x		;99f4   ; mas la X de la canasta
	ld a,(0ef94h)		;99f7   ; B = X corregida
	ld b,a			;99fa
	ld a,c			;99fb   ; A = Y del punto
	add a,039h		;99fc   ; mas la mitad de la pista
	ld c,a			;99fe   ; C = Y del punto
	ld a,(iy+001h)		;99ff   ; distancia del atacante al punto
	sub c			;9a02   ; menos la del punto
	jr nc,L_9A07		;9a03
	neg		;9a05   ; en valor absoluto
L_9A07:
	ld e,a			;9a07   ; E = diferencia de Y
	ld a,(iy+003h)		;9a08   ; X del controlado
	sub b			;9a0b   ; menos la del punto
	jr nc,L_9A10		;9a0c
	neg		;9a0e   ; en valor absoluto
L_9A10:
	ld l,a			;9a10   ; L = diferencia de X
	call distancia		;9a11
	cp 008h		;9a14   ; a menos de 8: ya esta encima (0x9A40)
	jr c,defensa_encima		;9a16
L_9A18:
	ld (ix+020h),039h		;9a18   ; destino: Y 0x39 (la mitad), X la de la canasta menos 2 (o mas 2 en la mitad izquierda)
	ld a,(0c5d6h)		;9a1c   ; X de la canasta
	inc a			;9a1f   ; mas uno
	bit 7,a		;9a20   ; mitad izquierda?
	jr nz,L_9A26		;9a22
	sub 002h		;9a24   ; derecha: dos menos (en total, uno menos)
L_9A26:
	ld (ix+021h),a		;9a26   ; destino X
	ld a,001h		;9a29   ; estado 1: ir al destino
	ld (0ef90h),a		;9a2b
	ret			;9a2e
distancia_a_canasta:		; A = distancia del jugador IX a la canasta (Y en 0xC5D4, X en 0xC5D6)
	ld a,(0c5d4h)		;9a2f   ; (0xC5D4): Y (profundidad) de la canasta
	sub (ix+001h)		;9a32   ; menos la Y del jugador
	ld e,a			;9a35   ; E = diferencia de Y
	ld a,(0c5d6h)		;9a36
	sub (ix+003h)		;9a39   ; menos la X del jugador
	ld l,a			;9a3c   ; L = diferencia de X
	jp distancia		;9a3d
defensa_encima:		; Ya esta sobre el atacante: si 0x8B3B lo permite, espera 21 cuadros (IX+0x26) y pasa al estado 2; la primera version esperaba 20 mas un azar de 0 a 15
	call indice_controlado		;9a40   ; A = indice del controlado
	ld (0ed83h),a		;9a43   ; (0xED83): jugador al que se mira
	call zona_tiro		;9a46   ; lo deja mirar?
	and a			;9a49
	jp z,L_9ABF		;9a4a   ; no: a 0x9ABF
	ld (ix+026h),015h		;9a4d   ; 21 cuadros de espera (la primera version: de 20 a 35 al azar)
	ld a,002h		;9a51   ; estado 2
	ld (0ef90h),a		;9a53
	jp L_9AD5		;9a56   ; y copia la pose del atacante
defensa_estado_1:		; Estado 1: a menos de 20 de la canasta se queda; a menos de 8 del controlado, le roba o le tapa
	ld a,(iy+001h)		;9a59   ; Y del controlado
	sub (ix+001h)		;9a5c   ; menos la del jugador IX
	ld e,a			;9a5f   ; E = diferencia de Y
	ld a,(iy+003h)		;9a60   ; X del controlado
	sub (ix+003h)		;9a63   ; menos la del jugador IX
	ld l,a			;9a66   ; L = diferencia de X
	call distancia		;9a67   ; distancia del jugador IX al controlado (IY)
	cp 008h		;9a6a   ; a menos de 8: encima (0x9A7A)
	jr c,L_9A7A		;9a6c
	ld a,(ix+020h)		;9a6e   ; destino pendiente: sigue
	or (ix+021h)		;9a71   ; destino pendiente?
	ret nz			;9a74   ; pendiente: sigue
	xor a			;9a75   ; vuelve al estado 0
	ld (0ef90h),a		;9a76
	ret			;9a79
L_9A7A:
	ld a,(ix+003h)		;9a7a   ; un paso en X hacia el centro
	and a			;9a7d   ; X del jugador: a que lado del centro
	jp p,L_9A84		;9a7e   ; positivo: hacia abajo (0x9A84)
	inc a			;9a81   ; negativo: un paso hacia el centro
	jr L_9A85		;9a82
L_9A84:
	dec a			;9a84   ; positivo: un paso hacia el centro
L_9A85:
	ld (ix+003h),a		;9a85   ; X nueva
	xor a			;9a88
	ld (ix+020h),a		;9a89   ; sin destino
	ld (ix+021h),a		;9a8c
	ld (0ef90h),a		;9a8f   ; estado 0 y sin destino
	call azar_r		;9a92   ; la mitad de las veces tapa
	and 001h		;9a95   ; un bit al azar
	jr nz,defensa_tapa		;9a97   ; a uno: a tapar
	call puede_pasar		;9a99   ; puede pasar? (azar contra la habilidad)
	jr nc,defensa_tapa		;9a9c   ; no puede pasar: a tapar
	push iy		;9a9e   ; HL = registro del controlado
	pop hl			;9aa0
	call angulo_y_distancia_a_canasta		;9aa1
	ld d,a			;9aa4   ; D = distancia del controlado
	push ix		;9aa5   ; HL = registro del jugador IX
	pop hl			;9aa7
	call angulo_y_distancia_a_canasta		;9aa8   ; el defensor mas cerca de la canasta que el atacante
	sub d			;9aab   ; distancia IX - distancia controlado
	jr c,defensa_tapa		;9aac   ; IX mas lejos: a tapar
pasa_al_companero_5:		; Anota un pase del controlado al companero 5
	call cuantos_controla		;9aae   ; A = controlados, B = indice
	ld d,a			;9ab1   ; D = controlados
	ld a,b			;9ab2   ; A = indice del que pasa
	ld b,d			;9ab3   ; B = controlados
	ld e,005h		;9ab4   ; companero 5: a quien pasa
	jp L_9892		;9ab6   ; a 0x9892: anota el pase
defensa_tapa:		; Si no hay desvio de tiro pide la orden 0x15 para el lado (0xEF96/0xEF97); si lo hay copia en la pose del defensor los bits 2-4 de la del controlado (la primera version ponia el 4: brazos arriba)
	call desvio_tiro		;9ab9
	and a			;9abc   ; hay desvio?
	jr nz,L_9AD5		;9abd   ; hay desvio: a copiar la pose
L_9ABF:
	ld c,015h		;9abf   ; C = 0x15: la orden (la primera version: 0x10)
L_9AC1:
	xor a			;9ac1   ; estado 0 de la defensa
	ld (0ef90h),a		;9ac2
	call indice_controlado		;9ac5   ; A = indice del controlado
L_9AC8:
	cp 003h		;9ac8   ; menos de tres controlados: 0xEF96, si no 0xEF97
	ld hl,0ef96h		;9aca
	jr c,L_9AD0		;9acd
	inc hl			;9acf   ; el lado derecho
L_9AD0:
	ld a,(hl)			;9ad0   ; ya hay una orden pendiente
	and a			;9ad1   ; ya hay orden?
	ret nz			;9ad2   ; si: nada
	ld (hl),c			;9ad3   ; deja la orden C
	ret			;9ad4
L_9AD5:
	ld a,(iy+00dh)		;9ad5   ; pose del controlado
	and 01ch		;9ad8   ; sus bits 2-4
	ld b,a			;9ada
	ld a,(ix+00dh)		;9adb   ; pose del defensor
	and 0e3h		;9ade   ; sin sus bits 2-4
	or b			;9ae0   ; con los del controlado
	ld (ix+00dh),a		;9ae1   ; pose nueva
	ret			;9ae4
defensa_estado_2:		; Estado 2: pasada la espera, elige al azar entre los dos companeros de 0x9B25 el que mira 0x8B3B y le pasa el balon
	ld a,(ix+026h)		;9ae5   ; (IX+0x26): cuadros de espera
	and a			;9ae8   ; espera agotada?
	ret nz			;9ae9   ; no: nada
	call azar_r		;9aea   ; un bit al azar
	and 001h		;9aed   ; a uno?
	jr z,$+66		;9aef   ; a cero: a buscar destino (0x9B31)
	call cuantos_controla		;9af1   ; B = indice del controlado
	inc b			;9af4   ; indice + 1
	ld hl,l9b23h		;9af5   ; 0x9B23 + 2 * (indice + 1): los dos companeros del controlado (tabla 0x9B25)
L_9AF8:
	inc hl			;9af8   ; dos bytes por jugador
	inc hl			;9af9
	djnz L_9AF8		;9afa
	ld a,(hl)			;9afc   ; A = primer companero
	ld (0ed83h),a		;9afd   ; (0xED83): el companero al que se mira
	call zona_tiro		;9b00   ; lo deja mirar?
	and a			;9b03   ; no: el segundo (0x9B19)
	jr z,L_9B19		;9b04
	inc hl			;9b06
	ld a,(hl)			;9b07   ; A = segundo companero
	ld (0ed83h),a		;9b08
	call zona_tiro		;9b0b   ; lo deja mirar?
	and a			;9b0e   ; no: el primero (0x9B19 con HL ya en el primero)
	jr z,L_9B19		;9b0f
	call azar_r		;9b11   ; al azar, el otro
	and 001h		;9b14   ; a cero: el segundo
	jr z,L_9B19		;9b16
	dec hl			;9b18   ; vuelve al primero
L_9B19:
	ld a,(hl)			;9b19   ; A = el companero elegido
	call ficha_suelta		;9b1a   ; anota el pase a ese companero
	xor a			;9b1d   ; estado 0
	ld (0ef90h),a		;9b1e
	ld c,008h		;9b21   ; C = 8: la orden de pasar
L_9B23:
	jr L_9AC1		;9b23

; ----------------------------------------------------------------------
; DATOS companeros: Seis pares: los dos companeros de cada uno de los seis
;   jugadores (0,1,2 en un equipo y 3,4,5 en el otro); se lee desde 0x9B23 +
;   jugador*2 + 2
;   0x9b25..0x9b31  (12 bytes)
DATA_companeros:
	defb 001h,002h	; 9b25
	defb 000h,002h	; 9b27
	defb 000h,001h	; 9b29
	defb 004h,005h	; 9b2b
	defb 003h,005h	; 9b2d
	defb 003h,004h	; 9b2f

; ======================================================================
; CODIGO 0x9b31..0x9ce3  (434 bytes)
; ======================================================================


defensa_estado_0_destino:		; Estado 0: elige un punto a 10 grados del jugador respecto a la canasta, a un lado o al otro al azar, y lo prueba hasta que cae dentro de la pista
	ld a,(ix+001h)		;9b31   ; Y relativa a la mitad de la pista (0x3A)
	sub 03ah		;9b34   ; menos la mitad de la pista (0x3A)
	ld e,a			;9b36   ; E = Y relativa
	ld a,(0c5d6h)		;9b37
	ld b,a			;9b3a   ; B = X de la canasta
	ld a,(ix+003h)		;9b3b   ; X relativa a la canasta
	sub b			;9b3e   ; A = X del jugador menos la de la canasta
	ld b,014h		;9b3f   ; 20 mas, o 0xEC (-20) en la mitad izquierda
	bit 7,(ix+003h)		;9b41
	jr z,L_9B49		;9b45   ; mitad derecha: +20
	ld b,0ech		;9b47   ; mitad izquierda: -20
L_9B49:
	add a,b			;9b49   ; X relativa corregida
	ld l,a			;9b4a   ; L = X relativa
	push hl			;9b4b   ; guarda HL
	push de			;9b4c   ; y DE
	call angulo		;9b4d   ; angulo del jugador respecto a la canasta
	pop de			;9b50   ; recupera DE
	pop hl			;9b51   ; y HL
	ld b,a			;9b52   ; B = angulo
	push bc			;9b53   ; guarda BC
	call distancia		;9b54   ; y la distancia
	pop bc			;9b57   ; recupera BC
	ld c,a			;9b58   ; C = distancia
	call azar_r		;9b59   ; un bit al azar: a que lado
	and 001h		;9b5c
	ld a,b			;9b5e   ; A = angulo
	jr nz,L_9B67		;9b5f   ; a uno: 10 grados mas
L_9B61:
	sub 00ah		;9b61   ; 10 grados menos
	ld h,000h		;9b63   ; H = 0: lado menos
	jr L_9B6B		;9b65
L_9B67:
	add a,00ah		;9b67   ; 10 grados mas
	ld h,001h		;9b69   ; H = 1: lado mas
L_9B6B:
	push hl			;9b6b   ; guarda el lado
	ld e,a			;9b6c   ; E = angulo corregido
	call seno_y_coseno		;9b6d   ; seno y coseno
	ld a,c			;9b70   ; A = distancia
	call producto_con_signo		;9b71   ; HL = componente X
	ex de,hl			;9b74   ; DE = X, HL = seno
	ld a,c			;9b75   ; A = distancia otra vez
	call producto_con_signo		;9b76   ; HL = componente Y
	ld a,039h		;9b79   ; Y del punto, 0x39 mas
	add a,h			;9b7b   ; mas la componente Y
	ld e,a			;9b7c   ; E = Y del punto
	ld a,(ix+003h)		;9b7d
	and a			;9b80   ; mitad del jugador
	ld a,d			;9b81   ; A = componente X
	jp p,L_9B89		;9b82   ; derecha: 0x9B89
	add a,0b0h		;9b85   ; X del punto en la mitad izquierda (0xB0 mas)
	jr L_9B8B		;9b87
L_9B89:
	add a,050h		;9b89   ; o en la derecha (0x50 mas)
L_9B8B:
	ld d,a			;9b8b   ; D = X del punto
	cp 064h		;9b8c   ; X fuera de 100-155: prueba el otro lado
	jr c,L_9B9C		;9b8e   ; menos de 100: fuera
	cp 09ch		;9b90
	jr nc,L_9B9C		;9b92   ; 156 o mas: fuera
L_9B94:
	pop hl			;9b94   ; recupera el lado
	ld a,h			;9b95
	and a			;9b96   ; que lado era?
	ld a,b			;9b97   ; A = angulo
	jr z,L_9B67		;9b98   ; era menos: prueba mas
	jr L_9B61		;9b9a   ; era mas: prueba menos
L_9B9C:
	ld a,e			;9b9c   ; A = Y del punto
	cp 00ah		;9b9d   ; Y fuera de 10-105: prueba el otro lado
	jr c,L_9B94		;9b9f   ; menos de 10: fuera
	cp 06ah		;9ba1
	jr nc,L_9B94		;9ba3   ; 106 o mas: fuera
	pop hl			;9ba5   ; tira el lado
	ld (ix+020h),e		;9ba6   ; destino (IX+0x20, IX+0x21)
	ld (ix+021h),d		;9ba9   ; destino X
	ld a,001h		;9bac   ; estado 1
	ld (0ef90h),a		;9bae   ; estado 1: ir al destino
	ld a,(0c616h)		;9bb1   ; (0xC616): formacion en curso, 0x3F = ninguna
	cp 03fh		;9bb4   ; ya hay formacion: listo
	ret nz			;9bb6
	call azar_r		;9bb7   ; al azar 0-3, el 2 se convierte en 3
	and 003h		;9bba   ; 0-3
	cp 002h		;9bbc   ; 0 o 1?
	jr c,L_9BC1		;9bbe
	inc a			;9bc0   ; 2 -> 3
L_9BC1:
	or 080h		;9bc1   ; bit 7: formacion recien elegida
	ld (0c616h),a		;9bc3   ; formacion nueva, marcada
	ret			;9bc6
reinicia_estados_maquina:		; Estados de ataque (0xEF8F) y de defensa (0xEF90) de la maquina a cero
	xor a			;9bc7   ; A = 0
	ld hl,0ef8fh		;9bc8   ; (0xEF8F): estado del ataque
	ld (hl),a			;9bcb   ; a cero
	inc hl			;9bcc   ; (0xEF90): estado de la defensa
	ld (hl),a			;9bcd   ; a cero
	ret			;9bce
descuenta_ordenes:		; Resta uno a las ordenes pendientes de los dos lados (0xEF96, 0xEF97) si no estan a cero
	ld a,(0ef96h)		;9bcf
	and a			;9bd2   ; orden pendiente en la izquierda?
	jr z,L_9BD9		;9bd3
	dec a			;9bd5   ; un cuadro menos
	ld (0ef96h),a		;9bd6
L_9BD9:
	ld a,(0ef97h)		;9bd9
	and a			;9bdc   ; orden pendiente en la derecha?
	ret z			;9bdd
	dec a			;9bde   ; un cuadro menos
	ld (0ef97h),a		;9bdf
	ret			;9be2
graba_equipo_sp:		; Entrada de SAVE DATA: guarda la pila en 0xEF99 (los errores de cinta vuelven aqui) y sigue en 0x9BE7
	ld (0ef99h),sp		;9be3   ; la pila, para abortar desde 0x9CCE

; ----------------------------------------------------------------------
; ===== La cinta: grabar, cargar y verificar el equipo =====
; ----------------------------------------------------------------------
graba_equipo:		; SAVE DATA: escribe en cinta el bloque HL..(0xF87D) con la cabecera de los binarios (diez 0xD0 y el nombre de 0xF866), las direcciones de inicio, fin y (0xFCBF), y los bytes uno a uno con TAPOUT; acarreo si falla
	push hl			;9be7   ; guarda el inicio del bloque
	ld a,0d0h		;9be8   ; 0xD0: la marca de los bloques BSAVE
	call graba_cabecera		;9bea   ; cabecera: motor, diez 0xD0 y los seis bytes del nombre
	xor a			;9bed   ; motor otra vez (TAPOON con A = 0: cabecera corta)
	call motor_escritura		;9bee   ; TAPOON con A = 0: cabecera corta, la de los datos
	pop hl			;9bf1   ; HL = inicio
	push hl			;9bf2   ; lo guarda otra vez
	call graba_palabra		;9bf3   ; direccion de inicio (HL = el equipo, 0xC617 o 0xC703)
	ld hl,(0f87dh)		;9bf6   ; (0xF87D): direccion de fin, SAVEND de la BIOS; 0x7AE4 la deja a HL + 0xEB
	push hl			;9bf9   ; guarda el inicio
	call graba_palabra		;9bfa   ; graba el fin
	ld hl,(0fcbfh)		;9bfd   ; (0xFCBF): la direccion de ejecucion que lleva todo BSAVE
	call graba_palabra		;9c00   ; graba la direccion de ejecucion
	pop de			;9c03   ; DE = fin
	pop hl			;9c04   ; HL = inicio
L_9C05:
	ld a,(hl)			;9c05   ; un byte del equipo
	call graba_byte_cinta		;9c06   ; a la cinta
	rst 20h			;9c09   ; DCOMPR: HL contra DE (el fin)
	jr nc,L_9C0F		;9c0a   ; HL >= DE: era el ultimo
	inc hl			;9c0c   ; siguiente byte
	jr L_9C05		;9c0d   ; otro mas
L_9C0F:
	call 000f0h		;9c0f   ; BIOS TAPOOF - Stops writing on the tape | TAPOOF: motor parado
	and a			;9c12   ; sin acarreo: bien
	ret			;9c13
graba_palabra:		; Los dos bytes de HL, el bajo primero (TAPOUT)
	ld a,l			;9c14   ; primero el byte bajo
	call graba_byte_cinta		;9c15
	ld a,h			;9c18   ; luego el alto
	jp graba_byte_cinta		;9c19
lee_palabra:		; HL = dos bytes de la cinta, el bajo primero (TAPIN)
	call lee_byte_cinta		;9c1c   ; byte bajo
	ld l,a			;9c1f   ; a L
	call lee_byte_cinta		;9c20   ; byte alto
	ld h,a			;9c23   ; a H
	ret			;9c24
carga_equipo:		; LOAD DATA: busca la cabecera con el nombre del equipo, lee inicio y fin y vuelca los bytes en HL; acarreo si falla
	ld (0ef99h),sp		;9c25   ; guarda la pila: los errores de cinta vuelven aqui con 0x9CD1
	call lee_cabecera_bsave		;9c29   ; cabecera, nombre e inicio/fin: devuelve en DE el fin
L_9C2C:
	call lee_byte_cinta		;9c2c   ; un byte de la cinta
	ld (hl),a			;9c2f   ; un byte al equipo
	rst 20h			;9c30   ; fin?
	jr z,L_9C36		;9c31   ; HL = DE: era el ultimo
	inc hl			;9c33   ; siguiente byte
	jr L_9C2C		;9c34   ; otro mas
L_9C36:
	call 000e7h		;9c36   ; BIOS TAPIOF - Stops reading from the tape | TAPIOF
	and a			;9c39   ; sin acarreo: bien
	ret			;9c3a
verifica_equipo:		; VERIFY: igual que la carga pero comparando cada byte con el que hay; acarreo si alguno no coincide
	ld (0ef99h),sp		;9c3b   ; la pila, para abortar desde 0x9CCE
	call lee_cabecera_bsave		;9c3f   ; cabecera, inicio y fin (DE)
L_9C42:
	call lee_byte_cinta		;9c42   ; un byte de la cinta
	cp (hl)			;9c45   ; distinto: error
	jr nz,L_9C53		;9c46   ; distinto: acarreo
	rst 20h			;9c48   ; HL contra DE
	jr z,L_9C4E		;9c49   ; era el ultimo
	inc hl			;9c4b   ; siguiente byte
	jr L_9C42		;9c4c   ; otro mas
L_9C4E:
	call 000e7h		;9c4e   ; BIOS TAPIOF - Stops reading from the tape
	and a			;9c51   ; sin acarreo: bien
	ret			;9c52
L_9C53:
	scf			;9c53   ; acarreo: no coincide
	ret			;9c54
lee_cabecera_bsave:		; Busca la cabecera (0x9C71), lee inicio, fin y ejecucion y deja en DE el fin trasladado a HL (HL + fin - inicio)
	push hl			;9c55   ; guarda el destino
	ld c,0d0h		;9c56   ; la marca de los binarios
	call busca_cabecera		;9c58   ; diez 0xD0 y el nombre
	call motor_lectura		;9c5b   ; el motor otra vez: el bloque de datos
	call lee_palabra		;9c5e   ; inicio en HL
	ex de,hl			;9c61   ; DE = inicio
	call lee_palabra		;9c62   ; fin en DE
	and a			;9c65   ; sin acarreo para la resta
	sbc hl,de		;9c66   ; longitud = fin - inicio
	pop de			;9c68   ; DE = destino
	add hl,de			;9c69   ; fin relativo al destino
	push hl			;9c6a   ; guarda el fin relativo
	call lee_palabra		;9c6b   ; la direccion de ejecucion, que no se usa
	ex de,hl			;9c6e   ; DE = ejecucion (se tira)
	pop de			;9c6f   ; DE = fin relativo
	ret			;9c70
busca_cabecera:		; TAPION y diez bytes seguidos iguales a C, luego los seis del nombre a 0xF866: tienen que acabar en tres 0x7F (0x7B22) o se sigue buscando
	call motor_lectura		;9c71   ; TAPION: busca una cabecera
	ld b,00ah		;9c74   ; diez marcas seguidas
L_9C76:
	call lee_byte_cinta		;9c76   ; un byte
	cp c			;9c79   ; otra cosa: vuelve a empezar
	jr nz,busca_cabecera		;9c7a   ; no es la marca: otra cabecera
	djnz L_9C76		;9c7c   ; diez seguidas
	ld hl,0f866h		;9c7e   ; FILNAM: los seis bytes del nombre
	ld b,006h		;9c81   ; seis bytes de nombre
L_9C83:
	call lee_byte_cinta		;9c83   ; un byte
	ld (hl),a			;9c86   ; a FILNAM
	inc hl			;9c87   ; siguiente
	djnz L_9C83		;9c88   ; los seis
	ld b,003h		;9c8a   ; los tres ultimos tienen que ser 0x7F
L_9C8C:
	dec hl			;9c8c   ; el ultimo, el penultimo, el antepenultimo
	ld a,(hl)			;9c8d   ; un byte del nombre
	cp 07fh		;9c8e   ; es 0x7F?
	jr nz,busca_cabecera		;9c90   ; no: no es un equipo, otra cabecera
	djnz L_9C8C		;9c92   ; los tres
	jp pinta_encontrado		;9c94   ; ensena el nombre encontrado (FOUND:)
graba_cabecera:		; Motor (TAPOON), diez veces A y los seis bytes del nombre de 0xF866
	call motor_escritura		;9c97   ; TAPOON
	ld b,00ah		;9c9a   ; diez marcas
L_9C9C:
	call graba_byte_cinta		;9c9c   ; diez marcas
	djnz L_9C9C		;9c9f   ; las diez
	ld b,006h		;9ca1   ; seis bytes de nombre
	ld hl,0f866h		;9ca3   ; FILNAM
L_9CA6:
	ld a,(hl)			;9ca6   ; un byte del nombre
	inc hl			;9ca7   ; siguiente
	call graba_byte_cinta		;9ca8   ; a la cinta
	djnz L_9CA6		;9cab   ; los seis
	jp 000f0h		;9cad   ; BIOS TAPOOF - Stops writing on the tape
lee_byte_cinta:		; TAPIN guardando los registros; si falla, aborta la operacion (0x9CCE)
	push hl			;9cb0   ; guarda los registros
	push de			;9cb1
	push bc			;9cb2
	call 000e4h		;9cb3   ; BIOS TAPIN - Reads data from the tape
	jr nc,L_9CDF		;9cb6   ; bien: a recuperarlos (0x9CDF)
	jr error_de_cinta		;9cb8   ; mal: abortar
graba_byte_cinta:		; TAPOUT guardando los registros; si falla, aborta
	push hl			;9cba   ; guarda los registros
	push de			;9cbb
	push bc			;9cbc
	push af			;9cbd
	call 000edh		;9cbe   ; BIOS TAPOUT - Writes data on the tape
	jr nc,L_9CDE		;9cc1   ; bien: a recuperarlos
	jr error_de_cinta		;9cc3   ; mal: abortar
motor_lectura:		; TAPION guardando los registros; si falla, aborta
	push hl			;9cc5   ; guarda los registros
	push de			;9cc6
	push bc			;9cc7
	push af			;9cc8
	call 000e1h		;9cc9   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	jr nc,L_9CDE		;9ccc   ; bien: a recuperarlos
error_de_cinta:		; TAPIOF, recupera la pila guardada en 0xEF99 y vuelve con acarreo al que llamo a cargar o grabar
	call 000e7h		;9cce   ; BIOS TAPIOF - Stops reading from the tape
	ld sp,(0ef99h)		;9cd1   ; (0xEF99): la pila de 0x9C25 / 0x9C3B
	scf			;9cd5   ; acarreo: fallo
	ret			;9cd6
motor_escritura:		; TAPOON guardando los registros
	push hl			;9cd7   ; guarda los registros
	push de			;9cd8
	push bc			;9cd9
	push af			;9cda
	call 000eah		;9cdb   ; BIOS TAPOON - Turns on the cassette motor and writes the header
L_9CDE:
	pop af			;9cde   ; los recupera
L_9CDF:
	pop bc			;9cdf
	pop de			;9ce0
	pop hl			;9ce1
	ret			;9ce2

; ----------------------------------------------------------------------
; DATOS relleno_ff: 24 bytes a 0xFF delante de los patrones de la red: no los
;   lee nadie
;   0x9ce3..0x9cfb  (24 bytes)
DATA_relleno_ff:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9ce3  ............
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 9cef  ............

; ----------------------------------------------------------------------
; DATOS sprites_red: Tres patrones de sprite de 16x16 (96 bytes): la red de la
;   canasta en tres cuadros; 0x5DC5 los copia a la VRAM 0x3B00
;   0x9cfb..0x9d5b  (96 bytes)
DATA_sprites_red:
	defb 007h,00dh,015h,012h,008h,00fh,006h,005h,002h,003h,002h,000h,000h,000h,000h,000h	; 9cfb  ................
	defb 0f0h,058h,054h,0a4h,008h,0f8h,0b0h,050h,0a0h,060h,0a0h,080h,000h,000h,000h,000h	; 9d0b  .XT....P.`......
	defb 007h,00dh,015h,012h,008h,00fh,00ah,005h,003h,000h,000h,000h,000h,000h,000h,000h	; 9d1b  ................
	defb 0f0h,058h,054h,0a4h,008h,0f8h,0a8h,050h,0e0h,000h,000h,000h,000h,000h,000h,000h	; 9d2b  .XT....P........
	defb 004h,00ah,012h,015h,01ch,00fh,00ah,007h,000h,000h,000h,000h,000h,000h,000h,000h	; 9d3b  ................
	defb 090h,0a8h,0a4h,054h,01ch,0f8h,0a8h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; 9d4b  ...T............

; ----------------------------------------------------------------------
; DATOS sprites_balon: Tres patrones de sprite de 16x16 (96 bytes): el balon
;   grande, el pequeno y la flecha del cursor; 0x5DD1 los copia a la VRAM
;   0x3B60
;   0x9d5b..0x9dbb  (96 bytes)
DATA_sprites_balon:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,007h,007h,007h,003h	; 9d5b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0e0h,0e0h,0e0h,0e0h,0c0h	; 9d6b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,003h	; 9d7b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0e0h,0c0h	; 9d8b  ................
	defb 000h,000h,000h,000h,080h,0e0h,0f8h,0feh,0ffh,0fch,0f0h,0c0h,000h,000h,000h,000h	; 9d9b  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9dab  ................

; ----------------------------------------------------------------------
; DATOS sprites_jugadores_a: Comprimido (formato 0x6056, 995 bytes): 2048
;   bytes a 0xD33D, los 64 primeros patrones de sprite de 16x16 de los
;   jugadores (0x5DF3)
;   0x9dbb..0xa19e  (995 bytes)
DATA_sprites_jugadores_a:
	defb 0f0h,050h,057h,000h,003h,055h,007h,000h,050h,000h,0e0h,055h,0f0h,000h,050h,000h	; 9dbb  .PW..U..P..U..P.
	defb 007h,054h,00fh,007h,000h,050h,000h,0c0h,054h,0e0h,0c0h,000h,050h,000h,003h,007h	; 9dcb  .T...P..T...P...
	defb 053h,003h,001h,000h,050h,000h,051h,005h,050h,000h,050h,005h,050h,000h,051h,009h	; 9ddb  S...P.Q.P.P.P.Q.
	defb 055h,003h,007h,007h,007h,056h,000h,055h,0e0h,0f0h,0f0h,070h,056h,000h,051h,012h	; 9deb  U....V.U...pV.Q.
	defb 051h,013h,051h,010h,051h,011h,053h,001h,053h,000h,050h,000h,0e0h,0f0h,0f0h,054h	; 9dfb  Q.Q.Q.S.S.P....T
	defb 0f8h,0f8h,056h,000h,051h,01ah,051h,01bh,051h,018h,050h,000h,001h,052h,003h,053h	; 9e0b  ..V.Q.Q.Q.P..R.S
	defb 001h,001h,056h,000h,0e0h,0e0h,055h,0f0h,0f0h,056h,000h,051h,022h,051h,023h,051h	; 9e1b  ..V...U..V.Q"Q#Q
	defb 020h,051h,021h,057h,001h,050h,021h,050h,022h,050h,023h,051h,022h,051h,023h,051h	; 9e2b   Q!W.P!P"P#Q"Q#Q
	defb 028h,051h,021h,057h,003h,003h,056h,000h,057h,0e0h,051h,031h,051h,032h,050h,031h	; 9e3b  (Q!W..V.W.Q1Q2P1
	defb 051h,030h,051h,031h,000h,003h,002h,006h,007h,003h,001h,005h,00dh,00ch,018h,018h	; 9e4b  Q0Q1............
	defb 033h,030h,060h,060h,000h,0e0h,0a0h,0b0h,0f0h,0e0h,0c0h,0d0h,0d8h,098h,00ch,00ch	; 9e5b  30``............
	defb 0e6h,006h,003h,003h,007h,006h,00eh,00eh,00ch,052h,01ch,01ch,01ch,03ch,054h,000h	; 9e6b  .........R...<T.
	defb 070h,030h,038h,038h,018h,052h,01ch,01ch,01ch,01eh,054h,000h,055h,000h,003h,008h	; 9e7b  p088.R....T.U...
	defb 018h,018h,030h,030h,067h,060h,0c0h,0c0h,055h,000h,080h,020h,030h,030h,018h,018h	; 9e8b  ..00g`..U.. 00..
	defb 0cch,00ch,006h,006h,000h,003h,002h,006h,007h,003h,000h,000h,002h,002h,006h,01ch	; 9e9b  ................
	defb 019h,003h,00fh,00eh,000h,080h,080h,053h,0c0h,000h,053h,0c0h,0d8h,080h,000h,080h	; 9eab  .......S..S.....
	defb 001h,001h,052h,002h,001h,001h,000h,001h,003h,055h,000h,070h,070h,0f0h,0e0h,0e0h	; 9ebb  ..R......U.pp...
	defb 070h,070h,0b8h,0b8h,078h,0f8h,054h,000h,051h,046h,051h,047h,051h,044h,051h,045h	; 9ecb  pp..x.T.QFQGQDQE
	defb 051h,04ah,051h,04bh,051h,048h,051h,049h,000h,003h,001h,005h,007h,003h,000h,002h	; 9edb  QJQKQHQI........
	defb 005h,005h,00ch,01ch,039h,030h,000h,001h,000h,0c0h,040h,060h,0e0h,052h,0c0h,0b0h	; 9eeb  ....90....@`.R..
	defb 0b8h,018h,01ch,0ech,00eh,006h,086h,003h,052h,006h,002h,052h,003h,007h,00fh,055h	; 9efb  ........R..R...U
	defb 000h,070h,0f0h,052h,0e0h,070h,070h,0b8h,0b8h,078h,0f0h,054h,000h,051h,056h,051h	; 9f0b  .p.R.pp..x.T.QVQ
	defb 057h,051h,054h,051h,055h,051h,05ah,051h,05bh,051h,058h,051h,059h,000h,003h,001h	; 9f1b  WQTQUQZQ[QXQY...
	defb 005h,007h,003h,000h,000h,003h,003h,007h,006h,00eh,01ch,078h,071h,052h,000h,052h	; 9f2b  ...........xqR.R
	defb 080h,0c0h,000h,053h,000h,0f0h,000h,000h,080h,003h,053h,007h,003h,003h,001h,001h	; 9f3b  ...S......S.....
	defb 003h,007h,054h,000h,0d0h,0a0h,052h,060h,0b0h,0b8h,0d8h,0d8h,0d0h,0c0h,054h,000h	; 9f4b  ..T...R`......T.
	defb 051h,066h,051h,067h,051h,064h,051h,065h,051h,06ah,051h,06bh,051h,068h,051h,069h	; 9f5b  QfQgQdQeQjQkQhQi
	defb 050h,038h,00dh,01ch,018h,018h,01bh,01ch,000h,000h,050h,03ah,0d8h,09ch,00ch,00ch	; 9f6b  P8........P:....
	defb 0ech,01ch,000h,000h,050h,040h,018h,038h,030h,030h,037h,030h,000h,000h,050h,042h	; 9f7b  ....P@.80070..PB
	defb 030h,038h,018h,018h,0d8h,018h,000h,000h,050h,044h,006h,019h,0e7h,09eh,078h,070h	; 9f8b  08......PD....xp
	defb 000h,000h,050h,046h,0c0h,0c0h,080h,000h,0f8h,000h,000h,080h,051h,046h,051h,07fh	; 9f9b  ..PF........QFQ.
	defb 051h,044h,051h,07dh,050h,054h,005h,00dh,01ch,0f9h,0e7h,01eh,01ch,001h,000h,0c0h	; 9fab  QDQ}PT..........
	defb 040h,060h,0e0h,0c0h,0c0h,080h,060h,060h,0e0h,0c0h,0b0h,000h,000h,080h,051h,086h	; 9fbb  @`....``......Q.
	defb 051h,087h,051h,054h,051h,085h,050h,064h,003h,007h,01eh,0fch,0f1h,000h,000h,001h	; 9fcb  Q.QTQ.Pd........
	defb 050h,066h,050h,067h,051h,066h,051h,067h,051h,064h,051h,08dh,050h,038h,00dh,014h	; 9fdb  PfPgQfQgQdQ.P8..
	defb 018h,018h,01bh,052h,000h,050h,03ah,0d8h,094h,00ch,00ch,0ech,052h,000h,052h,007h	; 9feb  ...R.P:.....R.R.
	defb 054h,00eh,00eh,00eh,01eh,054h,000h,052h,070h,054h,038h,051h,03dh,050h,040h,053h	; 9ffb  T....T.RpT8Q=P@S
	defb 018h,007h,052h,000h,050h,042h,053h,030h,0c0h,052h,000h,050h,044h,000h,018h,01dh	; a00b  ..R.PBS0.R.PD...
	defb 01fh,00fh,000h,000h,001h,050h,046h,052h,0c0h,080h,070h,052h,000h,002h,002h,052h	; a01b  .....PFR..pR...R
	defb 005h,002h,002h,001h,003h,006h,001h,054h,000h,0e0h,0e0h,052h,0c0h,0e0h,0e0h,070h	; a02b  .......T...R...p
	defb 070h,0f0h,0f0h,054h,000h,051h,046h,051h,0a3h,051h,044h,051h,0a1h,051h,0a6h,051h	; a03b  p..T.QFQ.QDQ.Q.Q
	defb 0a7h,051h,0a4h,051h,0a5h,050h,054h,006h,036h,03dh,03dh,001h,000h,000h,001h,050h	; a04b  .Q.Q.PT.6==....P
	defb 086h,0b0h,038h,098h,0f8h,0f0h,000h,000h,080h,051h,086h,051h,0b3h,051h,054h,051h	; a05b  ..8......Q.Q.QTQ
	defb 0b1h,050h,064h,003h,003h,019h,01fh,01fh,000h,000h,001h,050h,066h,000h,052h,080h	; a06b  .Pd........Pf.R.
	defb 070h,052h,000h,051h,066h,051h,0bbh,051h,064h,051h,0b9h,000h,003h,002h,006h,007h	; a07b  pR.QfQ.QdQ......
	defb 003h,001h,01dh,03dh,038h,000h,000h,003h,052h,000h,000h,0e0h,0a0h,0b0h,0f0h,0e0h	; a08b  ...=8...R.......
	defb 0c0h,0dch,0deh,08eh,000h,000h,0e0h,052h,000h,055h,000h,073h,078h,038h,052h,000h	; a09b  .......R.U.sx8R.
	defb 007h,052h,000h,055h,000h,09ch,03ch,038h,052h,000h,0c0h,052h,000h,000h,003h,002h	; a0ab  .R.U..<8R..R....
	defb 006h,007h,003h,080h,0c0h,07fh,07fh,000h,000h,001h,000h,000h,001h,050h,046h,0c0h	; a0bb  .............PF.
	defb 0c0h,000h,000h,0f0h,052h,000h,051h,046h,051h,0cbh,051h,0c8h,051h,0c9h,000h,003h	; a0cb  ....R.QFQ.Q.Q...
	defb 001h,005h,007h,003h,000h,006h,01ch,0e3h,0dfh,01eh,001h,000h,000h,001h,050h,086h	; a0db  ..............P.
	defb 070h,0f0h,0c0h,000h,0f0h,000h,000h,080h,051h,086h,051h,0d3h,051h,0d0h,051h,0d1h	; a0eb  p.......Q.Q.Q.Q.
	defb 000h,003h,001h,035h,0d7h,0e3h,078h,03eh,00fh,003h,000h,000h,001h,000h,000h,001h	; a0fb  ...5..x>........
	defb 050h,066h,080h,080h,000h,000h,0f0h,000h,000h,080h,051h,066h,051h,0dbh,051h,0d8h	; a10b  Pf........QfQ.Q.
	defb 051h,0d9h,050h,038h,00dh,00ch,01ch,078h,0f3h,052h,000h,050h,03ah,0d8h,09ch,00ch	; a11b  Q.P8...x.R.P:...
	defb 00eh,0e6h,006h,006h,000h,050h,038h,00dh,00ch,01ch,018h,03bh,030h,070h,0e0h,050h	; a12b  .....P8....;0p.P
	defb 03ah,050h,0e3h,050h,040h,018h,038h,030h,070h,067h,060h,060h,000h,050h,042h,030h	; a13b  :P.P@.80pg``.PB0
	defb 030h,038h,01eh,0cfh,052h,000h,050h,040h,050h,0e9h,050h,042h,030h,030h,038h,018h	; a14b  08..R.P@P.PB008.
	defb 0dch,00ch,00eh,007h,050h,044h,052h,000h,01fh,03ch,003h,003h,000h,050h,046h,0c0h	; a15b  ....PDR..<...PF.
	defb 0e0h,060h,060h,0e8h,0c0h,080h,000h,050h,044h,052h,000h,002h,004h,00bh,01bh,038h	; a16b  .``....PDR.....8
	defb 050h,046h,050h,0f3h,051h,046h,053h,003h,01dh,000h,000h,001h,051h,044h,052h,000h	; a17b  PFP.QFS.....QDR.
	defb 0f8h,0fch,052h,000h,051h,046h,050h,0f9h,051h,044h,052h,000h,080h,0c0h,0e0h,070h	; a18b  ..R.QFP.QDR....p
	defb 03ch,050h,0ffh	; a19b

; ----------------------------------------------------------------------
; DATOS sprites_jugadores_b: Comprimido (0x6056, 1144 bytes): 2048 bytes a
;   0xDB3D, los patrones de sprite 64-127 (0x5DFC)
;   0xa19e..0xa616  (1144 bytes)
DATA_sprites_jugadores_b:
	defb 0c1h,041h,000h,003h,001h,005h,007h,003h,000h,002h,005h,00dh,00ch,07ch,0f1h,000h	; a19e  .A...........|..
	defb 000h,001h,000h,0c0h,040h,060h,0e0h,0c0h,0c0h,080h,0b0h,0b8h,01ch,00ch,0ech,01ch	; a1ae  ....@`..........
	defb 01ch,080h,041h,000h,005h,005h,00ch,00ch,01dh,038h,070h,001h,041h,002h,041h,003h	; a1be  ..A......8p.A.A.
	defb 043h,002h,006h,006h,007h,003h,00dh,000h,000h,001h,043h,000h,080h,080h,000h,0f0h	; a1ce  C.........C.....
	defb 0f8h,000h,000h,080h,043h,002h,006h,006h,007h,003h,00bh,001h,000h,001h,043h,000h	; a1de  ....C.........C.
	defb 080h,080h,000h,000h,080h,0c0h,0f0h,080h,000h,003h,001h,005h,007h,003h,000h,000h	; a1ee  ................
	defb 045h,003h,01bh,01fh,01eh,000h,001h,045h,000h,045h,080h,0c0h,000h,047h,000h,070h	; a1fe  E......E.E...G.p
	defb 000h,000h,080h,043h,012h,047h,000h,00fh,000h,000h,001h,043h,010h,045h,0c0h,0fch	; a20e  ...C.G.....C.E..
	defb 07eh,000h,000h,080h,043h,012h,041h,015h,043h,010h,045h,0c0h,0e0h,070h,038h,01eh	; a21e  ~...C.A.C.E..p8.
	defb 080h,000h,000h,018h,03ch,018h,01bh,01ah,01ah,01bh,01bh,01dh,00dh,005h,045h,000h	; a22e  ....<.........E.
	defb 000h,000h,018h,01ch,00eh,0e6h,0a6h,0b6h,0f6h,0eeh,0dch,0d8h,0d0h,080h,000h,000h	; a23e  ................
	defb 003h,045h,000h,047h,007h,04dh,007h,003h,0e0h,045h,000h,047h,070h,04dh,070h,060h	; a24e  .E.G.M...E.GpMp`
	defb 018h,01ch,045h,018h,01bh,01ah,01ah,01bh,01dh,00dh,00dh,005h,045h,000h,041h,01eh	; a25e  ..E.........E.A.
	defb 041h,01fh,000h,000h,018h,038h,070h,045h,060h,060h,070h,03bh,018h,008h,045h,000h	; a26e  A....8pE``p;..E.
	defb 000h,000h,018h,03ch,047h,018h,018h,018h,0b8h,030h,020h,045h,000h,043h,022h,043h	; a27e  ...<G....0 E.C"C
	defb 023h,043h,020h,043h,021h,041h,028h,041h,029h,018h,038h,04bh,018h,018h,038h,0b0h	; a28e  #C C!A(A).8K..8.
	defb 030h,020h,045h,000h,000h,000h,004h,00ch,01ch,01bh,01ah,01ah,01bh,01dh,00eh,007h	; a29e  0 E.............
	defb 003h,045h,000h,049h,000h,080h,080h,0c0h,045h,0c0h,049h,000h,003h,045h,000h,047h	; a2ae  .E.I....E.I..E.G
	defb 001h,04dh,001h,003h,0e0h,045h,000h,047h,0c0h,04dh,0c0h,080h,060h,030h,034h,02ch	; a2be  .M...E.G.M..`04,
	defb 01ch,01bh,01ah,01ah,041h,035h,041h,036h,041h,037h,043h,036h,043h,037h,000h,000h	; a2ce  ....A5A6A7C6C7..
	defb 040h,070h,038h,0dch,04ch,06ch,0ech,0dch,038h,0f0h,0e0h,045h,000h,043h,03ah,043h	; a2de  @p8.Ll..8..E.C:C
	defb 03bh,043h,038h,043h,039h,043h,036h,043h,037h,006h,045h,00ch,018h,0d8h,058h,058h	; a2ee  ;C8C9C6C7.E...XX
	defb 0d8h,0b0h,070h,0e0h,0c0h,045h,000h,000h,000h,00ch,01ch,038h,033h,031h,035h,037h	; a2fe  ..p..E.....83157
	defb 01bh,00ch,006h,001h,001h,000h,000h,000h,000h,018h,018h,038h,0d8h,058h,058h,045h	; a30e  ...........8.XXE
	defb 0d8h,0b8h,0b0h,080h,000h,000h,003h,000h,000h,003h,047h,002h,04bh,002h,006h,001h	; a31e  ..........G.K...
	defb 0e0h,045h,000h,047h,0e0h,043h,021h,070h,078h,045h,030h,033h,031h,035h,017h,01bh	; a32e  .E.G.C!pxE0315..
	defb 00ch,006h,001h,001h,000h,000h,041h,04eh,041h,04fh,000h,000h,070h,03ch,018h,01bh	; a33e  ......ANAO..p<..
	defb 01ah,01ah,043h,04fh,000h,000h,030h,030h,018h,0d8h,098h,0a8h,043h,055h,043h,052h	; a34e  ..CO..00....CUCR
	defb 041h,021h,043h,050h,043h,051h,006h,00eh,01ch,01ch,018h,01bh,01ah,01ah,01bh,01dh	; a35e  A!CPCQ..........
	defb 00dh,00dh,005h,001h,000h,000h,041h,05ah,043h,055h,000h,000h,018h,018h,038h,033h	; a36e  ......AZCU....83
	defb 031h,035h,037h,03bh,01ch,00eh,006h,045h,000h,000h,000h,03ch,018h,045h,000h,080h	; a37e  157;...E...<.E..
	defb 080h,090h,0d0h,010h,047h,000h,003h,045h,000h,047h,003h,04dh,003h,007h,0e0h,000h	; a38e  ....G..E.G.M....
	defb 000h,060h,047h,0a0h,04dh,0a0h,000h,003h,001h,019h,018h,038h,033h,031h,035h,041h	; a39e  .`G.M......8315A
	defb 065h,080h,0c0h,0c0h,047h,000h,080h,041h,067h,000h,000h,00ch,008h,045h,000h,001h	; a3ae  e...G..Ag....E..
	defb 043h,067h,000h,000h,030h,038h,01ch,0cch,086h,0a6h,0e6h,0ceh,01ch,078h,070h,045h	; a3be  Cg..08.......xpE
	defb 000h,043h,06ah,043h,06bh,043h,068h,043h,069h,041h,070h,043h,067h,003h,007h,00eh	; a3ce  .CjCkChCiApCg...
	defb 00ch,00ch,0cch,08ch,0ach,0ech,0d8h,038h,070h,060h,045h,000h,041h,024h,041h,025h	; a3de  .......8p`E.A$A%
	defb 00ch,01ch,045h,00ch,0ech,0ach,0ach,0ech,0dch,0d8h,0d8h,0d0h,080h,000h,000h,000h	; a3ee  ..E.............
	defb 000h,038h,01ch,018h,01bh,01ah,01ah,041h,025h,000h,000h,00eh,01ch,00ch,0ech,0ach	; a3fe  .8.....A%.......
	defb 0ach,041h,07fh,030h,038h,04bh,030h,030h,038h,01bh,018h,008h,045h,000h,041h,032h	; a40e  .A.08K008...E.A2
	defb 041h,033h,000h,000h,070h,038h,047h,030h,041h,085h,000h,000h,01ch,038h,047h,018h	; a41e  A3..p8G0A....8G.
	defb 041h,033h,00ch,00ch,01ch,018h,018h,01bh,01ah,01ah,041h,035h,041h,036h,041h,037h	; a42e  A3........A5A6A7
	defb 000h,000h,070h,038h,018h,01bh,01ah,01ah,041h,035h,041h,036h,041h,037h,043h,036h	; a43e  ..p8....A5A6A7C6
	defb 043h,037h,043h,08ch,043h,035h,043h,036h,043h,037h,043h,090h,043h,035h,00ch,00eh	; a44e  C7C.C5C6C7C.C5..
	defb 01ch,018h,018h,01bh,019h,015h,017h,00bh,00ch,006h,001h,001h,000h,000h,043h,024h	; a45e  ..............C$
	defb 0d8h,0d8h,0b8h,0b0h,0b0h,080h,000h,000h,000h,000h,070h,038h,018h,01bh,019h,015h	; a46e  ..........p8....
	defb 041h,055h,000h,000h,0e0h,070h,038h,0d8h,058h,058h,041h,09fh,041h,024h,043h,09fh	; a47e  AU...p8.XXA.A$C.
	defb 043h,09ch,043h,09dh,043h,0a2h,043h,09fh,043h,0a0h,043h,055h,018h,01ch,038h,030h	; a48e  C.C.C.C.C.CU..80
	defb 030h,033h,031h,035h,041h,065h,030h,078h,038h,018h,045h,008h,088h,088h,098h,0d0h	; a49e  0315Ae0x8.E.....
	defb 010h,047h,000h,000h,000h,0e1h,070h,030h,033h,031h,035h,041h,065h,000h,000h,0e0h	; a4ae  .G....p0315Ae...
	defb 010h,045h,000h,080h,041h,067h,043h,0aeh,043h,0afh,043h,0ach,043h,065h,043h,0b2h	; a4be  .E..AgC.C.C.CeC.
	defb 043h,067h,043h,0b0h,043h,065h,000h,000h,003h,002h,006h,007h,003h,001h,005h,019h	; a4ce  CgC.Ce..........
	defb 018h,018h,000h,003h,000h,000h,000h,000h,0e0h,0a0h,0b0h,0f0h,0e0h,0c0h,0d0h,0d8h	; a4de  ................
	defb 09ch,00ch,00ch,0ech,00ch,000h,000h,04dh,007h,007h,007h,003h,049h,000h,000h,04bh	; a4ee  .......M....I..K
	defb 070h,060h,04fh,000h,041h,0bch,005h,00dh,004h,018h,018h,01bh,000h,000h,041h,0beh	; a4fe  p`O.A.........A.
	defb 0d0h,0d8h,090h,00ch,00ch,0ech,000h,000h,041h,0c0h,047h,007h,047h,000h,045h,070h	; a50e  ........A.G.G.Ep
	defb 000h,070h,060h,000h,000h,041h,0c3h,041h,0bch,005h,00dh,01ch,018h,018h,01bh,018h	; a51e  .p`..A.A........
	defb 000h,041h,0beh,0d0h,0cch,08ch,00ch,000h,0e0h,000h,000h,043h,0c2h,041h,0c3h,000h	; a52e  .A.........C.A..
	defb 04dh,070h,070h,070h,060h,049h,000h,045h,007h,000h,007h,003h,000h,000h,041h,0c3h	; a53e  Mppp`I.E......A.
	defb 041h,0d2h,047h,070h,047h,000h,04dh,000h,003h,008h,018h,018h,038h,030h,037h,000h	; a54e  A.GpG.M.....807.
	defb 000h,04dh,000h,080h,020h,030h,030h,038h,018h,0d8h,000h,000h,00eh,000h,045h,00eh	; a55e  .M.. 008......E.
	defb 006h,000h,000h,041h,0c3h,043h,0c0h,043h,0c9h,041h,0d8h,008h,018h,018h,038h,030h	; a56e  ...A.C.C.A....80
	defb 037h,030h,000h,041h,0dah,030h,038h,038h,018h,000h,0c0h,000h,000h,043h,0d2h,043h	; a57e  70.A.088.....C.C
	defb 0d7h,0e0h,000h,045h,0e0h,0c0h,000h,000h,041h,0c3h,041h,0d8h,018h,038h,038h,030h	; a58e  ...E....A.A..880
	defb 000h,007h,000h,000h,041h,0dah,020h,030h,030h,038h,018h,0d8h,018h,000h,000h,000h	; a59e  ....A. 008......
	defb 003h,001h,005h,007h,003h,000h,045h,002h,005h,005h,00dh,01ch,038h,000h,000h,0c0h	; a5ae  ......E.....8...
	defb 040h,060h,0e0h,0c0h,0c0h,080h,0b0h,038h,0d8h,0f8h,0f0h,000h,000h,041h,0ech,002h	; a5be  @`.....8.....A..
	defb 000h,006h,007h,017h,03bh,000h,000h,041h,0eeh,080h,0b0h,030h,070h,0e0h,0d0h,000h	; a5ce  ....;..A...0p...
	defb 000h,041h,0ech,045h,002h,006h,01eh,03dh,000h,000h,041h,0eeh,080h,0b0h,038h,01ch	; a5de  .A.E...=..A...8.
	defb 00ch,0dch,038h,030h,043h,0eeh,043h,0f3h,043h,0ech,040h,058h,058h,038h,0c8h,0f0h	; a5ee  ..80C.C.C.@XX8..
	defb 000h,000h,043h,0eeh,001h,00dh,00ch,00eh,007h,00bh,001h,000h,043h,0ech,040h,040h	; a5fe  ..C.........C.@@
	defb 058h,078h,078h,080h,0c0h,0f0h,041h,0ffh	; a60e  Xxx...A.

; ----------------------------------------------------------------------
; DATOS sprites_jugadores_c: Comprimido (0x6056, 992 bytes): 2048 bytes a
;   0xE33D, los patrones de sprite 128-191 (0x5E05)
;   0xa616..0xa9f6  (992 bytes)
DATA_sprites_jugadores_c:
	defb 081h,081h,000h,000h,003h,002h,006h,007h,003h,003h,001h,00dh,00ch,00eh,007h,00bh	; a616  ................
	defb 000h,000h,000h,000h,0c0h,080h,0a0h,0e0h,0c0h,000h,085h,040h,000h,0e0h,0f0h,000h	; a626  ...........@....
	defb 000h,083h,002h,000h,001h,001h,019h,01fh,01fh,000h,01ch,087h,000h,085h,080h,0c0h	; a636  ................
	defb 000h,090h,085h,080h,0b0h,000h,000h,083h,002h,030h,031h,03bh,01fh,00eh,001h,000h	; a646  .........01;....
	defb 000h,081h,006h,000h,090h,080h,000h,000h,0f0h,000h,000h,083h,002h,000h,001h,001h	; a656  ................
	defb 000h,00ch,01bh,003h,000h,081h,006h,000h,090h,0c0h,0e0h,060h,0d0h,080h,000h,083h	; a666  ...........`....
	defb 006h,083h,007h,081h,002h,030h,0b0h,0a0h,080h,0f8h,0fch,000h,000h,083h,006h,000h	; a676  .....0..........
	defb 009h,011h,011h,010h,00eh,000h,000h,081h,002h,000h,080h,080h,0c0h,0c0h,0e0h,078h	; a686  ...............x
	defb 03ch,083h,006h,008h,019h,031h,031h,011h,00dh,000h,000h,081h,002h,000h,085h,080h	; a696  <....11.........
	defb 0f8h,0fch,000h,000h,000h,000h,003h,002h,006h,007h,003h,000h,018h,018h,01ch,00eh	; a6a6  ................
	defb 006h,001h,000h,000h,000h,000h,080h,080h,087h,0c0h,000h,078h,07ch,00ch,01ch,078h	; a6b6  ...........x|..x
	defb 070h,000h,007h,00fh,01eh,089h,01ch,038h,08dh,000h,000h,0a0h,060h,0e0h,070h,07ch	; a6c6  p......8....`.p|
	defb 03fh,00fh,003h,003h,002h,089h,000h,081h,01ch,085h,000h,00ch,00fh,00fh,000h,000h	; a6d6  ?...............
	defb 081h,01eh,000h,087h,0c0h,0d0h,000h,000h,003h,085h,007h,003h,000h,001h,001h,001h	; a6e6  ................
	defb 001h,003h,007h,087h,000h,080h,0c0h,000h,0f8h,0f8h,018h,0c8h,0c0h,087h,0c0h,087h	; a6f6  ................
	defb 000h,081h,01ch,018h,018h,01dh,00fh,007h,085h,000h,081h,01eh,000h,0d8h,0cch,08ch	; a706  ................
	defb 00ch,0e8h,000h,000h,007h,00eh,01eh,089h,01ch,081h,021h,000h,085h,0e0h,070h,07ch	; a716  ..........!...p|
	defb 03fh,00fh,081h,023h,003h,006h,005h,005h,003h,003h,001h,001h,081h,029h,000h,0e0h	; a726  ?..#.........)..
	defb 0c0h,0d8h,0b8h,098h,0c8h,0c0h,081h,02bh,083h,01eh,083h,027h,083h,01ch,083h,025h	; a736  .......+...'...%
	defb 083h,036h,083h,02bh,083h,034h,083h,029h,083h,01eh,083h,02fh,083h,01ch,083h,02dh	; a746  .6.+.4.).../...-
	defb 083h,032h,083h,023h,083h,030h,083h,021h,083h,02ah,083h,02bh,083h,028h,083h,029h	; a756  .2.#.0.!.*.+.(.)
	defb 083h,01eh,083h,01fh,083h,01ch,00ch,00ch,01ch,038h,030h,040h,000h,000h,083h,022h	; a766  .........80@..."
	defb 083h,023h,083h,020h,083h,021h,083h,002h,002h,002h,01ah,01dh,01dh,001h,000h,000h	; a776  .#. .!..........
	defb 083h,000h,080h,0b0h,038h,098h,0f8h,0f0h,000h,000h,003h,007h,007h,003h,087h,000h	; a786  ....8...........
	defb 08fh,000h,080h,089h,070h,038h,038h,085h,038h,070h,087h,000h,083h,002h,002h,000h	; a796  ....p88.8p......
	defb 006h,007h,007h,003h,000h,000h,083h,000h,083h,001h,003h,007h,00fh,087h,00eh,01ch	; a7a6  ................
	defb 081h,059h,080h,085h,070h,038h,038h,03ch,01eh,00eh,006h,004h,089h,000h,001h,000h	; a7b6  .Y..p88<........
	defb 001h,001h,087h,000h,085h,000h,001h,087h,000h,0c0h,0f0h,0c0h,0f8h,0fch,00ch,0ech	; a7c6  ................
	defb 0e0h,085h,0e0h,0c0h,087h,000h,083h,002h,002h,01ah,01ah,01eh,00eh,001h,000h,000h	; a7d6  ................
	defb 083h,000h,080h,0b0h,038h,01ch,00ch,0dch,038h,030h,001h,000h,001h,003h,087h,007h	; a7e6  ....8...80......
	defb 00eh,08dh,000h,080h,0e0h,0c0h,0a0h,070h,078h,03ch,01ch,00ch,008h,08bh,000h,081h	; a7f6  .......px<......
	defb 000h,083h,06bh,081h,002h,083h,069h,083h,06eh,083h,06fh,083h,06ch,083h,06dh,081h	; a806  ..k...i.n.o.l.m.
	defb 000h,083h,057h,081h,002h,083h,055h,083h,066h,083h,067h,083h,064h,083h,065h,081h	; a816  ..W...U.f.g.d.e.
	defb 000h,081h,001h,081h,002h,083h,05dh,083h,062h,083h,063h,083h,060h,081h,059h,083h	; a826  ......].b.c.`.Y.
	defb 05ah,083h,05bh,083h,058h,081h,059h,083h,002h,000h,001h,001h,019h,01fh,01fh,000h	; a836  Z.[.X.Y.........
	defb 000h,081h,006h,000h,090h,085h,088h,0b0h,000h,000h,001h,085h,002h,087h,000h,081h	; a846  ................
	defb 059h,000h,0e0h,0e0h,085h,0ech,070h,070h,085h,070h,0e0h,087h,000h,083h,002h,081h	; a856  Y.....pp.p......
	defb 009h,081h,006h,010h,098h,08ch,00ch,008h,0f0h,000h,000h,003h,085h,006h,007h,007h	; a866  ................
	defb 00eh,000h,081h,059h,000h,085h,0e0h,070h,078h,03ch,01eh,081h,063h,003h,007h,00eh	; a876  ...Y...px<..c...
	defb 00fh,007h,085h,000h,081h,059h,080h,060h,000h,0e0h,0f0h,030h,040h,070h,081h,093h	; a886  .....Y.`...0@p..
	defb 083h,002h,00ch,00dh,005h,000h,000h,003h,003h,000h,081h,006h,000h,090h,0c0h,0e0h	; a896  ................
	defb 060h,0c0h,080h,000h,081h,060h,081h,059h,080h,0d0h,030h,070h,070h,078h,03ch,01eh	; a8a6  `....`.Y..0ppx<.
	defb 081h,063h,083h,006h,083h,0a3h,081h,002h,083h,0a1h,083h,0a6h,083h,063h,083h,060h	; a8b6  .c...........c.`
	defb 081h,059h,083h,006h,083h,08fh,081h,002h,083h,08dh,083h,09eh,083h,093h,083h,09ch	; a8c6  .Y..............
	defb 081h,059h,083h,006h,083h,097h,081h,002h,083h,009h,083h,09ah,083h,063h,083h,098h	; a8d6  .Y...........c..
	defb 081h,059h,083h,092h,083h,093h,083h,090h,081h,059h,000h,000h,003h,002h,006h,007h	; a8e6  .Y.......Y......
	defb 003h,001h,005h,00dh,00ch,00ch,038h,073h,000h,000h,000h,000h,0e0h,0a0h,0b0h,0f0h	; a8f6  ......8s........
	defb 0e0h,0c0h,0d0h,0d8h,09ch,00ch,00ch,0ech,00ch,000h,081h,0c4h,005h,00dh,00ch,01ch	; a906  ................
	defb 018h,03bh,030h,070h,081h,0c6h,0d0h,0d8h,090h,00ch,00ch,0ech,000h,000h,081h,0c4h	; a916  .;0p............
	defb 081h,0c5h,081h,0c6h,0d0h,0cch,08ch,00ch,000h,0e0h,000h,000h,08dh,000h,003h,008h	; a926  ................
	defb 018h,018h,038h,030h,037h,000h,000h,08dh,000h,080h,020h,030h,030h,038h,018h,0dch	; a936  ..807..... 008..
	defb 00ch,00eh,081h,0d0h,008h,018h,018h,038h,030h,037h,030h,000h,081h,0d2h,020h,030h	; a946  .......8070... 0
	defb 030h,010h,01ch,0ceh,000h,000h,081h,0d0h,018h,038h,038h,030h,000h,007h,000h,000h	; a956  0........880....
	defb 081h,0d2h,081h,0d7h,081h,01ch,085h,000h,00ch,00fh,00fh,010h,03ch,081h,01eh,081h	; a966  ............<...
	defb 027h,081h,01ch,018h,018h,01dh,00fh,017h,038h,000h,000h,081h,01eh,000h,0c0h,0c0h	; a976  '.......8.......
	defb 080h,000h,0f0h,000h,000h,081h,01ch,087h,000h,01eh,03eh,000h,000h,081h,01eh,000h	; a986  ..........>.....
	defb 078h,07ch,00ch,01ch,07ch,078h,000h,083h,01eh,000h,085h,003h,001h,00dh,000h,000h	; a996  x|..|x..........
	defb 083h,01ch,085h,000h,0b0h,0b0h,0c0h,0f8h,07ch,083h,01eh,083h,027h,083h,01ch,018h	; a9a6  ........|...'...
	defb 018h,038h,000h,0f8h,0fch,000h,000h,083h,01eh,008h,01bh,085h,033h,01bh,000h,000h	; a9b6  .8..........3...
	defb 083h,01ch,087h,000h,0f8h,0fch,000h,000h,000h,08bh,00eh,006h,081h,059h,000h,08dh	; a9c6  .............Y..
	defb 0e0h,0e0h,0e0h,0c0h,089h,000h,000h,08dh,00eh,00eh,00eh,006h,089h,000h,000h,08bh	; a9d6  ................
	defb 0e0h,0c0h,081h,059h,08fh,003h,003h,08dh,000h,08fh,0e0h,0e0h,08dh,000h,081h,0ffh	; a9e6  ...Y............

; ----------------------------------------------------------------------
; DATOS sprites_e400: Comprimido (formato 0x60B8, 46 bytes): 128 bytes a
;   0xEB3D, cuatro patrones de sprite de 16x16 (0x5E0E)
;   0xa9f6..0xaa24  (46 bytes)
DATA_sprites_e400:
	defb 0c0h,080h,086h,007h,084h,000h,086h,0c0h,084h,000h,00eh,00ch,01ch,01ch,018h,082h	; a9f6  ................
	defb 038h,078h,082h,000h,0e0h,060h,070h,070h,030h,082h,038h,03ch,082h,000h,080h,00eh	; aa06  8x...`pp0.8<....
	defb 084h,01ch,03ch,082h,000h,080h,0e0h,084h,070h,078h,0a2h,000h,080h,080h	; aa16  ..<.....px....

; ----------------------------------------------------------------------
; DATOS colocacion_poses: 40 fichas de ocho bytes, una por cada grupo de
;   cuatro poses (pose >> 2): los cuatro pares (Y, X) relativos de los cuatro
;   sprites de la pose, que 0x667C copia a los atributos de 0xC560 +
;   jugador*16
;   0xaa24..0xab64  (320 bytes)
DATA_colocacion_poses:
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa24  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa2c  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa34  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa3c  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa44  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa4c  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa54  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa5c  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa64  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa6c  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa74  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; aa7c  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa84  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa8c  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa94  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; aa9c  ....#...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; aaa4  ....$...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; aaac  ....$...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; aab4  ....$...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; aabc  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; aac4  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; aacc  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; aad4  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; aadc  ....$...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; aae4  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; aaec  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; aaf4  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; aafc  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab04  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab0c  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab14  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab1c  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; ab24  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; ab2c  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; ab34  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; ab3c  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab44  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab4c  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab54  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; ab5c  ....#...

; ----------------------------------------------------------------------
; DATOS poses: 160 poses de cuatro bytes: los cuatro numeros de patron (de 32
;   bytes, en 0xD33D) que 0x6653 copia a la VRAM 0x3800 + jugador*128
;   0xab64..0xade4  (640 bytes)
DATA_poses:
	defb 078h,0bdh,001h,005h	; ab64
	defb 076h,079h,001h,005h	; ab68
	defb 07ah,0beh,001h,005h	; ab6c
	defb 076h,077h,001h,005h	; ab70
	defb 0aeh,0afh,003h,00bh	; ab74
	defb 0ach,0adh,003h,00bh	; ab78
	defb 0aah,0abh,003h,00bh	; ab7c
	defb 0ach,0b0h,003h,00bh	; ab80
	defb 090h,091h,003h,00bh	; ab84
	defb 08eh,092h,003h,00bh	; ab88
	defb 093h,094h,003h,00bh	; ab8c
	defb 08eh,08fh,003h,00bh	; ab90
	defb 0a0h,0a1h,003h,00bh	; ab94
	defb 09eh,09fh,003h,00bh	; ab98
	defb 09ch,09dh,003h,00bh	; ab9c
	defb 09eh,0a2h,003h,00bh	; aba0
	defb 06fh,070h,000h,004h	; aba4
	defb 071h,075h,000h,004h	; aba8
	defb 073h,074h,000h,004h	; abac
	defb 071h,072h,000h,004h	; abb0
	defb 09ah,09bh,002h,00ah	; abb4
	defb 095h,096h,002h,00ah	; abb8
	defb 097h,098h,002h,00ah	; abbc
	defb 095h,099h,002h,00ah	; abc0
	defb 087h,088h,002h,00ah	; abc4
	defb 089h,08dh,002h,00ah	; abc8
	defb 08bh,08ch,002h,00ah	; abcc
	defb 089h,08ah,002h,00ah	; abd0
	defb 0a8h,0a9h,002h,00ah	; abd4
	defb 0a3h,0a4h,002h,00ah	; abd8
	defb 0a5h,0a6h,002h,00ah	; abdc
	defb 0a3h,0a7h,002h,00ah	; abe0
	defb 0b5h,0bdh,001h,005h	; abe4
	defb 0b4h,079h,001h,005h	; abe8
	defb 0b6h,0beh,001h,005h	; abec
	defb 0b4h,077h,001h,005h	; abf0
	defb 086h,0afh,003h,00bh	; abf4
	defb 085h,0adh,003h,00bh	; abf8
	defb 084h,0abh,003h,00bh	; abfc
	defb 085h,0b0h,003h,00bh	; ac00
	defb 0bch,091h,003h,00bh	; ac04
	defb 0bah,092h,003h,00bh	; ac08
	defb 0bbh,094h,003h,00bh	; ac0c
	defb 0bah,08fh,003h,00bh	; ac10
	defb 080h,0a1h,003h,00bh	; ac14
	defb 07fh,09fh,003h,00bh	; ac18
	defb 07eh,09dh,003h,00bh	; ac1c
	defb 07fh,0a2h,003h,00bh	; ac20
	defb 0b1h,070h,000h,004h	; ac24
	defb 0b2h,075h,000h,004h	; ac28
	defb 0b3h,074h,000h,004h	; ac2c
	defb 0b2h,072h,000h,004h	; ac30
	defb 07dh,09bh,002h,00ah	; ac34
	defb 07bh,096h,002h,00ah	; ac38
	defb 07ch,098h,002h,00ah	; ac3c
	defb 07bh,099h,002h,00ah	; ac40
	defb 0b9h,088h,002h,00ah	; ac44
	defb 0b7h,08dh,002h,00ah	; ac48
	defb 0b8h,08ch,002h,00ah	; ac4c
	defb 0b7h,08ah,002h,00ah	; ac50
	defb 083h,0a9h,002h,00ah	; ac54
	defb 081h,0a4h,002h,00ah	; ac58
	defb 082h,0a6h,002h,00ah	; ac5c
	defb 081h,0a7h,002h,00ah	; ac60
	defb 04ah,04bh,001h,005h	; ac64
	defb 04ch,04bh,001h,005h	; ac68
	defb 061h,04bh,001h,005h	; ac6c
	defb 062h,04bh,001h,005h	; ac70
	defb 05ch,05dh,003h,0c0h	; ac74
	defb 05eh,05dh,003h,0c0h	; ac78
	defb 06dh,05dh,003h,0c0h	; ac7c
	defb 06eh,05dh,003h,0c0h	; ac80
	defb 050h,051h,003h,00dh	; ac84
	defb 052h,051h,003h,00dh	; ac88
	defb 065h,051h,003h,00dh	; ac8c
	defb 066h,051h,003h,00dh	; ac90
	defb 056h,057h,003h,0c0h	; ac94
	defb 058h,057h,003h,0c0h	; ac98
	defb 069h,057h,003h,0c0h	; ac9c
	defb 06ah,057h,003h,0c0h	; aca0
	defb 047h,048h,000h,004h	; aca4
	defb 049h,048h,000h,004h	; aca8
	defb 05fh,048h,000h,004h	; acac
	defb 060h,048h,000h,004h	; acb0
	defb 053h,054h,002h,0bfh	; acb4
	defb 055h,054h,002h,0bfh	; acb8
	defb 067h,054h,002h,0bfh	; acbc
	defb 068h,054h,002h,0bfh	; acc0
	defb 04dh,04eh,002h,00ch	; acc4
	defb 04fh,04eh,002h,00ch	; acc8
	defb 063h,04eh,002h,00ch	; accc
	defb 064h,04eh,002h,00ch	; acd0
	defb 059h,05ah,002h,0bfh	; acd4
	defb 05bh,05ah,002h,0bfh	; acd8
	defb 06bh,05ah,002h,0bfh	; acdc
	defb 06ch,05ah,002h,0bfh	; ace0
	defb 03ah,0c2h,001h,005h	; ace4
	defb 03bh,0c2h,001h,005h	; ace8
	defb 027h,0c2h,001h,005h	; acec
	defb 031h,0c2h,001h,005h	; acf0
	defb 045h,01ch,003h,00bh	; acf4
	defb 046h,01ch,003h,00bh	; acf8
	defb 02fh,01ch,003h,00bh	; acfc
	defb 037h,01ch,003h,00bh	; ad00
	defb 03eh,014h,003h,007h	; ad04
	defb 03fh,014h,003h,007h	; ad08
	defb 02ah,02bh,003h,00bh	; ad0c
	defb 033h,02bh,003h,00bh	; ad10
	defb 042h,018h,003h,009h	; ad14
	defb 043h,018h,003h,009h	; ad18
	defb 02dh,018h,003h,00bh	; ad1c
	defb 035h,018h,003h,00bh	; ad20
	defb 038h,026h,000h,004h	; ad24
	defb 039h,026h,000h,004h	; ad28
	defb 025h,026h,000h,004h	; ad2c
	defb 030h,026h,000h,004h	; ad30
	defb 040h,016h,002h,008h	; ad34
	defb 041h,016h,002h,008h	; ad38
	defb 02ch,016h,002h,00ah	; ad3c
	defb 034h,016h,002h,00ah	; ad40
	defb 03ch,012h,002h,006h	; ad44
	defb 03dh,012h,002h,006h	; ad48
	defb 028h,029h,002h,00ah	; ad4c
	defb 032h,029h,002h,00ah	; ad50
	defb 044h,01ah,002h,00ah	; ad54
	defb 044h,01ah,002h,00ah	; ad58
	defb 02eh,01ah,002h,00ah	; ad5c
	defb 036h,01ah,002h,00ah	; ad60
	defb 010h,0c1h,001h,005h	; ad64
	defb 01eh,0c1h,001h,005h	; ad68
	defb 000h,000h,000h,000h	; ad6c
	defb 000h,000h,000h,000h	; ad70
	defb 01bh,01ch,003h,00bh	; ad74
	defb 024h,01ch,003h,00bh	; ad78
	defb 000h,000h,000h,000h	; ad7c
	defb 000h,000h,000h,000h	; ad80
	defb 013h,014h,003h,007h	; ad84
	defb 020h,014h,003h,007h	; ad88
	defb 000h,000h,000h,000h	; ad8c
	defb 000h,000h,000h,000h	; ad90
	defb 017h,018h,003h,009h	; ad94
	defb 022h,018h,003h,009h	; ad98
	defb 000h,000h,000h,000h	; ad9c
	defb 000h,000h,000h,000h	; ada0
	defb 00eh,00fh,000h,004h	; ada4
	defb 01dh,00fh,000h,004h	; ada8
	defb 000h,000h,000h,000h	; adac
	defb 000h,000h,000h,000h	; adb0
	defb 015h,016h,002h,008h	; adb4
	defb 021h,016h,002h,008h	; adb8
	defb 000h,000h,000h,000h	; adbc
	defb 000h,000h,000h,000h	; adc0
	defb 011h,012h,002h,006h	; adc4
	defb 01fh,012h,002h,006h	; adc8
	defb 000h,000h,000h,000h	; adcc
	defb 000h,000h,000h,000h	; add0
	defb 019h,01ah,002h,00ah	; add4
	defb 023h,01ah,002h,00ah	; add8
	defb 000h,000h,000h,000h	; addc
	defb 000h,000h,000h,000h	; ade0

; ----------------------------------------------------------------------
; DATOS patrones_pista: Comprimido (0x6056, 1114 bytes): 2000 bytes, los 250
;   patrones de 8x8 de la pista, los menus y la fuente; 0x5E26 los descomprime
;   en 0xCB3D y 0x5E3B los copia a los tres tercios de la tabla de patrones
;   0xade4..0xb23e  (1114 bytes)
DATA_patrones_pista:
	defb 0f0h,050h,057h,000h,0ffh,056h,000h,0ffh,052h,000h,008h,03eh,01ch,01ch,0ffh,000h	; ade4  .PW..V..R..>....
	defb 000h,03eh,052h,073h,07fh,0ffh,000h,000h,07eh,073h,073h,07eh,073h,0ffh,000h,000h	; adf4  .>Rs....~ss~s...
	defb 07eh,053h,073h,0ffh,000h,000h,07fh,070h,070h,07eh,070h,0ffh,000h,000h,052h,073h	; ae04  ~Ss....pp~p...Rs
	defb 07fh,073h,0ffh,000h,000h,073h,073h,076h,07ch,076h,0ffh,000h,000h,054h,070h,0ffh	; ae14  .s...ssv|v...Tp.
	defb 000h,000h,073h,07bh,07fh,077h,073h,0ffh,000h,000h,03eh,053h,073h,0ffh,000h,000h	; ae24  ..s{.ws...>Ss...
	defb 07eh,052h,073h,07eh,0ffh,000h,000h,03eh,073h,070h,03eh,003h,0ffh,000h,000h,07fh	; ae34  ~Rs~...>sp>.....
	defb 053h,01ch,0ffh,000h,000h,054h,073h,0ffh,000h,000h,052h,073h,03eh,01ch,0bbh,052h	; ae44  S....Ts...Rs>..R
	defb 03bh,053h,077h,051h,011h,053h,0efh,053h,0dfh,051h,013h,050h,000h,036h,056h,000h	; ae54  ;SwQ.S.S.Q.P.6V.
	defb 073h,073h,055h,000h,073h,07eh,055h,000h,070h,070h,055h,000h,070h,07fh,055h,000h	; ae64  ssU.s~U.ppU.p.U.
	defb 073h,03eh,055h,000h,01ch,01ch,055h,000h,076h,073h,055h,000h,036h,052h,000h,053h	; ae74  s>U...U.vsU.6R.S
	defb 001h,036h,052h,000h,053h,080h,050h,000h,03eh,03eh,02ah,03eh,01ch,03eh,07fh,07fh	; ae84  .6R.S.P.>>*>.>..
	defb 000h,01ch,03eh,02ah,03eh,01ch,03eh,07fh,03eh,07fh,063h,063h,077h,03eh,07fh,07fh	; ae94  ..>*>.>.>.ccw>..
	defb 03eh,07fh,063h,063h,036h,01ch,07fh,07fh,000h,03eh,07fh,063h,063h,01ch,03eh,07fh	; aea4  >.cc6....>.cc.>.
	defb 050h,021h,03eh,07fh,063h,063h,077h,063h,07fh,07fh,000h,01ch,03eh,03eh,02ah,03eh	; aeb4  P!>.ccwc....>>*>
	defb 01ch,07fh,050h,023h,050h,022h,050h,021h,053h,00fh,053h,01dh,051h,02ch,00ch,01ch	; aec4  ..P#P"P!S.S.Q,..
	defb 00ch,00ch,01eh,000h,0ffh,000h,00eh,013h,006h,00ch,01fh,000h,0ffh,000h,03eh,063h	; aed4  ..............>c
	defb 063h,052h,073h,03eh,000h,01ch,03ch,053h,01ch,03eh,000h,03eh,067h,007h,01ch,030h	; aee4  cRs>..<S.>.>g..0
	defb 070h,07fh,000h,03eh,067h,007h,01eh,007h,067h,03eh,000h,00eh,01eh,036h,066h,066h	; aef4  p..>g...g>...6ff
	defb 07fh,006h,000h,07fh,060h,060h,07eh,007h,007h,07eh,000h,01eh,030h,070h,07eh,073h	; af04  ....``~..~..0p~s
	defb 073h,03eh,000h,07fh,043h,006h,00ch,052h,01ch,000h,03eh,073h,073h,03eh,073h,073h	; af14  s>..C..R..>ss>ss
	defb 03eh,000h,03eh,073h,073h,03fh,003h,006h,03ch,000h,000h,00ch,00ch,000h,00ch,00ch	; af24  >.>ss?..<.......
	defb 000h,000h,054h,000h,018h,018h,000h,052h,000h,03eh,053h,000h,000h,000h,03eh,000h	; af34  ..T....R.>S...>.
	defb 03eh,052h,000h,018h,03ch,03ch,018h,000h,018h,018h,000h,03eh,067h,007h,00eh,018h	; af44  >R..<<.....>g...
	defb 000h,018h,018h,03ch,042h,09dh,0b1h,0b1h,09dh,042h,03ch,03eh,052h,073h,07fh,073h	; af54  ...<B....B<>Rs.s
	defb 073h,000h,07eh,073h,073h,07eh,073h,073h,07eh,000h,03eh,073h,073h,070h,073h,073h	; af64  s.~ss~ss~.>sspss
	defb 03eh,000h,07eh,054h,073h,07eh,000h,07fh,070h,070h,07eh,070h,070h,07fh,000h,07fh	; af74  >.~Ts~..pp~pp...
	defb 070h,070h,07eh,052h,070h,000h,03eh,073h,070h,077h,073h,073h,03eh,000h,052h,073h	; af84  pp~Rp.>spwss>.Rs
	defb 07fh,052h,073h,000h,03eh,054h,01ch,03eh,000h,01fh,052h,00eh,06eh,06eh,03ch,000h	; af94  .Rs.>T.>..R.nn<.
	defb 073h,076h,07ch,078h,07ch,076h,073h,000h,054h,070h,071h,07fh,000h,063h,077h,07fh	; afa4  sv|x|vs.Tpq..cw.
	defb 06bh,052h,063h,000h,073h,07bh,07fh,077h,052h,073h,000h,03eh,054h,073h,03eh,000h	; afb4  kRc.s{.wRs.>Ts>.
	defb 07eh,052h,073h,07eh,070h,070h,000h,03eh,052h,073h,07fh,072h,03dh,000h,07eh,052h	; afc4  ~Rs~pp.>Rs.r=.~R
	defb 073h,07eh,076h,073h,000h,03eh,073h,070h,03eh,007h,067h,03eh,000h,07fh,055h,01ch	; afd4  s~vs.>sp>.g>..U.
	defb 000h,055h,073h,03eh,000h,054h,073h,03eh,01ch,000h,063h,06bh,06bh,07fh,07fh,036h	; afe4  .Us>.Ts>..ckk..6
	defb 036h,000h,073h,073h,03eh,01ch,03eh,073h,073h,000h,052h,073h,03eh,052h,01ch,000h	; aff4  6.ss>.>ss.Rs>R..
	defb 07fh,047h,00eh,01ch,038h,071h,07fh,000h,018h,018h,008h,010h,053h,000h,006h,026h	; b004  .G..8q......S..&
	defb 007h,026h,006h,000h,0ffh,000h,067h,06ch,0ech,06fh,06ch,000h,0ffh,000h,098h,052h	; b014  .&....gl.ol....R
	defb 0d8h,0dfh,000h,0ffh,000h,07ch,060h,078h,060h,060h,000h,0ffh,000h,00fh,03fh,038h	; b024  .....|`x``....?8
	defb 077h,06fh,06eh,06ch,06ch,051h,060h,06ch,06eh,06fh,077h,038h,03fh,00fh,000h,051h	; b034  wonllQ`lnow8?..Q
	defb 062h,0ffh,0ffh,000h,0ffh,0ffh,052h,000h,000h,000h,0ffh,0ffh,000h,0ffh,0ffh,000h	; b044  b.....R.........
	defb 057h,06ch,051h,066h,0ffh,0ffh,000h,0ffh,0ffh,052h,01ch,01ch,01ch,0ffh,0ffh,000h	; b054  WlQf.....R......
	defb 0ffh,0ffh,000h,057h,01ch,054h,000h,008h,000h,000h,056h,07eh,000h,050h,06ch,03ch	; b064  ...W.T....V~.Pl<
	defb 07eh,0e7h,0c3h,0c3h,0e7h,07eh,03ch,050h,06eh,050h,054h,050h,046h,056h,03ch,000h	; b074  ~....~<PnPTPFV<.
	defb 050h,072h,054h,000h,052h,0ffh,052h,000h,053h,0ffh,000h,053h,003h,000h,0f7h,0f7h	; b084  PrT.R.R.S..S....
	defb 007h,051h,076h,057h,007h,051h,078h,053h,0bfh,053h,07eh,051h,07ah,053h,07ch,053h	; b094  .QvW.QxS.S~QzS|S
	defb 078h,051h,07ch,053h,070h,053h,060h,051h,07eh,053h,040h,053h,000h,051h,080h,052h	; b0a4  xQ|SpS`Q~S@S.Q.R
	defb 007h,053h,0f7h,007h,051h,082h,050h,000h,057h,001h,051h,085h,053h,0e0h,053h,0c0h	; b0b4  .S..Q.P.W.Q.S.S.
	defb 051h,087h,050h,087h,051h,087h,053h,080h,053h,000h,051h,08bh,050h,08bh,051h,08bh	; b0c4  Q.P.Q.S.S.Q.P.Q.
	defb 050h,000h,050h,085h,051h,085h,057h,003h,051h,092h,0ffh,0ffh,055h,000h,055h,000h	; b0d4  P.P.Q.W.Q...U.U.
	defb 0ffh,0ffh,0ffh,0ffh,055h,001h,051h,096h,055h,001h,0ffh,0ffh,051h,098h,056h,000h	; b0e4  ....U.Q.U...Q.V.
	defb 0f0h,0feh,01fh,003h,001h,053h,000h,000h,000h,0c0h,0e0h,070h,038h,018h,00ch,00ch	; b0f4  .....S.....p8...
	defb 055h,006h,00ch,0f0h,056h,000h,053h,000h,001h,003h,01fh,0feh,00ch,018h,038h,070h	; b104  U...V.S.......8p
	defb 0e0h,0c0h,000h,000h,051h,09dh,051h,09ch,051h,09bh,051h,09ah,051h,0a0h,051h,09fh	; b114  ....Q.Q.Q.Q.Q.Q.
	defb 051h,09eh,052h,000h,0ffh,0ffh,052h,000h,053h,000h,0ffh,0ffh,000h,000h,054h,000h	; b124  Q.R...R.S.....T.
	defb 0fch,0ffh,003h,055h,000h,0e0h,0fch,01fh,003h,055h,000h,080h,0f0h,07ch,00fh,003h	; b134  ...U.....U...|..
	defb 052h,000h,053h,000h,080h,0e0h,070h,018h,00ch,006h,003h,001h,001h,052h,000h,052h	; b144  R.S...p......R.R
	defb 000h,080h,0c0h,0c0h,060h,060h,030h,052h,018h,052h,00ch,006h,052h,006h,054h,003h	; b154  ....``0R.R..R.T.
	defb 003h,003h,054h,006h,00ch,00ch,00ch,052h,018h,030h,030h,060h,060h,0c0h,0c0h,080h	; b164  ..T....R.00``...
	defb 053h,000h,000h,000h,001h,003h,003h,006h,00eh,01ch,038h,070h,0e0h,0c0h,080h,052h	; b174  S.........8p...R
	defb 000h,052h,000h,001h,003h,00eh,03ch,0f0h,0c0h,056h,000h,003h,01fh,0fch,0e0h,053h	; b184  .R....<..V.....S
	defb 000h,052h,000h,007h,07fh,0f8h,080h,000h,054h,000h,007h,0ffh,0f8h,056h,000h,0ffh	; b194  .R......T....V..
	defb 050h,001h,051h,0b2h,051h,0b1h,051h,0b0h,051h,0afh,051h,0aeh,051h,0adh,051h,0ach	; b1a4  P.Q.Q.Q.Q.Q.Q.Q.
	defb 051h,0abh,051h,0aah,051h,0b3h,051h,0b4h,051h,0b5h,051h,0b6h,051h,0b7h,051h,0b8h	; b1b4  Q.Q.Q.Q.Q.Q.Q.Q.
	defb 051h,0b9h,051h,0bah,051h,0bbh,051h,0bch,050h,000h,050h,085h,051h,085h,050h,092h	; b1c4  Q.Q.Q.Q.P.P.Q.P.
	defb 051h,092h,053h,001h,053h,003h,051h,0d7h,053h,007h,053h,00fh,051h,0d9h,053h,07fh	; b1d4  Q.S.S.Q.S.S.Q.S.
	defb 053h,0ffh,051h,0dbh,056h,0ffh,0f0h,051h,0ddh,0f0h,056h,0ffh,051h,0dfh,0ffh,0feh	; b1e4  S.Q.V..Q..V.Q...
	defb 0f8h,0f0h,0e0h,0c0h,0c0h,080h,051h,0e1h,080h,0c0h,0c0h,0e0h,0f0h,0f8h,0feh,0ffh	; b1f4  ......Q.........
	defb 051h,0e3h,050h,085h,051h,085h,050h,085h,051h,085h,050h,085h,051h,085h,050h,085h	; b204  Q.P.Q.P.Q.P.Q.P.
	defb 051h,085h,080h,055h,001h,080h,051h,0edh,080h,052h,000h,007h,01fh,03fh,07fh,051h	; b214  Q..U..Q..R...?.Q
	defb 0efh,07fh,03fh,01fh,007h,052h,000h,080h,051h,0f1h,050h,000h,050h,0d7h,051h,0d7h	; b224  ..?..R..Q.P.P.Q.
	defb 050h,0d9h,051h,0d9h,050h,0dbh,051h,0dbh,050h,0ffh	; b234  P.Q.P.Q.P.

; ----------------------------------------------------------------------
; DATOS colores_area_1: Comprimido (formato 0x60FA, 264 bytes): los 2000 bytes
;   de color de los 250 patrones de la pista con la primera AREA del menu
;   (0x6BAC)
;   0xb23e..0xb346  (264 bytes)
DATA_colores_area_1:
	defb 000h,003h,0f1h,0f1h,000h,051h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; b23e  .....Q..........
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; b24e  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; b25e  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; b26e  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; b27e  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,001h,04fh,0f1h,0f1h	; b28e  .............O..
	defb 000h,002h,0f4h,0f4h,0f4h,0e4h,000h,001h,0f4h,0f4h,0f4h,0e4h,0e4h,0f4h,000h,002h	; b29e  ................
	defb 0f4h,0f4h,0f4h,0feh,000h,002h,0f4h,0f4h,0f4h,0feh,000h,033h,0f4h,0f4h,000h,007h	; b2ae  ...........3....
	defb 0f7h,0f7h,04fh,04fh,000h,002h,04ch,042h,04fh,04fh,000h,005h,04ch,042h,04fh,04fh	; b2be  ..OO..LBOO..LBOO
	defb 000h,002h,04ch,042h,04fh,04fh,000h,002h,04ch,042h,04fh,04fh,000h,002h,04ch,042h	; b2ce  ..LBOO..LBOO..LB
	defb 04fh,04fh,04ch,042h,04ch,04fh,04fh,042h,000h,001h,04ch,042h,04ch,04fh,04fh,042h	; b2de  OOLBLOOB..LBLOOB
	defb 04ch,042h,001h,00bh,0fch,0f2h,000h,013h,0fch,0fch,000h,017h,0c4h,024h,000h,01fh	; b2ee  LB...........$..
	defb 0c7h,027h,000h,002h,0fch,0f2h,0f7h,0f7h,000h,002h,0fch,0f2h,000h,001h,0f7h,0f7h	; b2fe  .'..............
	defb 000h,002h,0fch,0f2h,0f7h,0f7h,000h,002h,0fch,0f2h,000h,001h,0fch,0fch,0fch,0f7h	; b30e  ................
	defb 0f7h,0f7h,000h,001h,0fch,0fch,0fch,0f7h,000h,001h,0f7h,0f7h,0f7h,0fch,000h,001h	; b31e  ................
	defb 0fch,0fch,0f7h,0f7h,0f7h,0fch,000h,001h,0fch,0fch,000h,017h,0c7h,0c7h,000h,003h	; b32e  ................
	defb 027h,027h,000h,017h,0c4h,0c4h,000h,000h	; b33e  ''......

; ----------------------------------------------------------------------
; DATOS colores_area_2: Comprimido (0x60FA, 264 bytes): los 2000 bytes de
;   color de la segunda AREA
;   0xb346..0xb44e  (264 bytes)
DATA_colores_area_2:
	defb 000h,003h,0f1h,0f1h,000h,051h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; b346  .....Q..........
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; b356  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; b366  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; b376  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; b386  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,001h,04fh,0f1h,0f1h	; b396  .............O..
	defb 000h,002h,0fch,0fch,0fch,0ech,000h,001h,0fch,0fch,0fch,0ech,0ech,0fch,000h,002h	; b3a6  ................
	defb 0fch,0fch,0fch,0feh,000h,002h,0fch,0fch,0fch,0feh,000h,033h,0fch,0fch,000h,007h	; b3b6  ...........3....
	defb 0f7h,0f7h,0cfh,0cfh,000h,002h,0c4h,0c5h,0cfh,0cfh,000h,005h,0c4h,0c5h,0cfh,0cfh	; b3c6  ................
	defb 000h,002h,0c4h,0c5h,0cfh,0cfh,000h,002h,0c4h,0c5h,0cfh,0cfh,000h,002h,0c4h,0c5h	; b3d6  ................
	defb 0cfh,0cfh,0c4h,0c5h,0c4h,0cfh,0cfh,0c5h,000h,001h,0c4h,0c5h,0c4h,0cfh,0cfh,0c5h	; b3e6  ................
	defb 0c4h,0c5h,001h,00bh,0f4h,0f5h,000h,013h,0f4h,0f4h,000h,017h,04ch,05ch,000h,01fh	; b3f6  ............L\..
	defb 047h,057h,000h,002h,0f4h,0f5h,0f7h,0f7h,000h,002h,0f4h,0f5h,000h,001h,0f7h,0f7h	; b406  GW..............
	defb 000h,002h,0f4h,0f5h,0f7h,0f7h,000h,002h,0f4h,0f5h,000h,001h,0f4h,0f4h,0f4h,0f7h	; b416  ................
	defb 0f7h,0f7h,000h,001h,0f4h,0f4h,0f4h,0f7h,000h,001h,0f7h,0f7h,0f7h,0f4h,000h,001h	; b426  ................
	defb 0f4h,0f4h,0f7h,0f7h,0f7h,0f4h,000h,001h,0f4h,0f4h,000h,017h,047h,047h,000h,003h	; b436  ............GG..
	defb 057h,057h,000h,017h,04ch,04ch,000h,000h	; b446  WW..LL..

; ----------------------------------------------------------------------
; DATOS colores_area_3: Comprimido (0x60FA, 264 bytes): los 2000 bytes de
;   color de la tercera AREA
;   0xb44e..0xb556  (264 bytes)
DATA_colores_area_3:
	defb 000h,003h,0f1h,0f1h,000h,051h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; b44e  .....Q..........
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; b45e  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; b46e  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; b47e  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; b48e  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,001h,04fh,0f1h,0f1h	; b49e  .............O..
	defb 000h,002h,0fch,0fch,0fch,0ech,000h,001h,0fch,0fch,0fch,0ech,0ech,0fch,000h,002h	; b4ae  ................
	defb 0fch,0fch,0fch,0feh,000h,002h,0fch,0fch,0fch,0feh,000h,033h,0fch,0fch,000h,007h	; b4be  ...........3....
	defb 0f7h,0f7h,0cfh,0cfh,000h,002h,0c6h,0c8h,0cfh,0cfh,000h,005h,0c6h,0c8h,0cfh,0cfh	; b4ce  ................
	defb 000h,002h,0c6h,0c8h,0cfh,0cfh,000h,002h,0c6h,0c8h,0cfh,0cfh,000h,002h,0c6h,0c8h	; b4de  ................
	defb 0cfh,0cfh,0c6h,0c8h,0c6h,0cfh,0cfh,0c8h,000h,001h,0c6h,0c8h,0c6h,0cfh,0cfh,0c8h	; b4ee  ................
	defb 0c6h,0c8h,001h,00bh,0f6h,0f8h,000h,013h,0f6h,0f6h,000h,017h,06ch,08ch,000h,01fh	; b4fe  ............l...
	defb 067h,087h,000h,002h,0f6h,0f8h,0f7h,0f7h,000h,002h,0f6h,0f8h,000h,001h,0f7h,0f7h	; b50e  g...............
	defb 000h,002h,0f6h,0f8h,0f7h,0f7h,000h,002h,0f6h,0f8h,000h,001h,0f6h,0f6h,0f6h,0f7h	; b51e  ................
	defb 0f7h,0f7h,000h,001h,0f6h,0f6h,0f6h,0f7h,000h,001h,0f7h,0f7h,0f7h,0f6h,000h,001h	; b52e  ................
	defb 0f6h,0f6h,0f7h,0f7h,0f7h,0f6h,000h,001h,0f6h,0f6h,000h,017h,067h,067h,000h,003h	; b53e  ............gg..
	defb 087h,087h,000h,017h,06ch,06ch,000h,000h	; b54e  ....ll..

; ----------------------------------------------------------------------
; DATOS colores_2100: Comprimido (formato 0x60E2, 159 bytes): 672 bytes de
;   color para los patrones 0x20-0x73 del primer tercio (VRAM 0x2100), que
;   0x6B94 pone encima del area
;   0xb556..0xb5f5  (159 bytes)
DATA_colores_2100:
	defb 0ffh,000h,000h,0f1h,008h,014h,014h,0b4h,0b4h,0a4h,084h,084h,084h,014h,014h,014h	; b556  ................
	defb 0b4h,0b4h,0a4h,074h,074h,014h,014h,01bh,01bh,01ah,0f4h,0f4h,0f4h,014h,014h,01bh	; b566  ...tt...........
	defb 01bh,01ah,0b4h,094h,094h,014h,014h,014h,01bh,01bh,0a4h,0d4h,064h,014h,014h,0b4h	; b576  ............d...
	defb 0b4h,0a4h,064h,0a4h,064h,014h,014h,01bh,01bh,01ah,01bh,034h,034h,000h,014h,004h	; b586  ..d.d......44...
	defb 0b4h,0b4h,0a4h,0f4h,014h,014h,01bh,01bh,01ah,094h,0d4h,0b4h,014h,014h,014h,0b4h	; b596  ................
	defb 0b4h,0a4h,094h,094h,014h,014h,0b4h,0b4h,0a4h,000h,0f4h,013h,000h,021h,006h,081h	; b5a6  .............!..
	defb 000h,021h,007h,081h,021h,000h,0f1h,0ffh,000h,0f1h,061h,000h,021h,006h,081h,000h	; b5b6  .!..!.....a.!...
	defb 021h,007h,081h,000h,021h,007h,081h,000h,021h,007h,081h,021h,000h,0a1h,058h,000h	; b5c6  !...!...!..!..X.
	defb 0f1h,008h,000h,021h,008h,000h,081h,008h,041h,041h,000h,045h,004h,041h,041h,081h	; b5d6  ...!....AA.E.AA.
	defb 081h,000h,089h,004h,000h,081h,012h,000h,041h,008h,000h,081h,008h,000h,000h	; b5e6  ........A......

; ----------------------------------------------------------------------
; DATOS jugadas: Comprimido (0x6056, 415 bytes): 720 bytes a 0xC84F (0x5F14),
;   los guiones de jugada de la maquina: 5 formaciones x 6 variantes x 3
;   jugadores x 8 bytes (0x5C68 indexa 144 por formacion y 24 por variante, la
;   variante es 2 x A mas un bit al azar); cada guion es un byte de espera y
;   puntos (Y, X, codigo) hasta un 0x80
;   0xb5f5..0xb794  (415 bytes)
DATA_jugadas:
	defb 0c0h,0c0h,000h,080h,0c4h,000h,080h,000h,018h,024h,064h,080h,000h,000h,080h,0c0h	; b5f5  .........$d.....
	defb 000h,0c0h,000h,000h,060h,034h,000h,080h,000h,000h,080h,000h,01ah,05ah,064h,080h	; b605  ....`4.......Zd.
	defb 000h,000h,080h,0c0h,001h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,000h,05ch,024h	; b615  ..............\$
	defb 064h,080h,000h,000h,080h,0c0h,000h,0c0h,00bh,0c0h,000h,000h,05ah,05ah,064h,080h	; b625  d...........ZZd.
	defb 000h,000h,080h,000h,014h,034h,000h,080h,000h,000h,080h,0c0h,000h,0c0h,000h,0c0h	; b635  .....4..........
	defb 000h,000h,03bh,060h,064h,080h,000h,000h,080h,0c0h,000h,000h,030h,055h,064h,05ah	; b645  ..;`d.......0UdZ
	defb 05ah,028h,080h,0c0h,000h,000h,039h,060h,064h,080h,000h,000h,080h,0c0h,000h,0c0h	; b655  Z(....9`d.......
	defb 000h,0c0h,000h,0c0h,000h,0c0h,014h,0c0h,018h,0c0h,000h,0c0h,000h,0c0h,000h,000h	; b665  ................
	defb 044h,055h,064h,01ah,05ah,028h,080h,0c0h,000h,0c0h,000h,000h,028h,040h,078h,080h	; b675  DUd.Z(......(@x.
	defb 000h,000h,080h,0c0h,000h,0c0h,000h,0c0h,000h,000h,028h,04eh,078h,080h,000h,000h	; b685  ..........(Nx...
	defb 080h,000h,030h,036h,078h,080h,000h,000h,080h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h	; b695  ..06x...........
	defb 000h,000h,044h,036h,078h,080h,000h,000h,080h,0c0h,000h,000h,04ch,040h,078h,080h	; b6a5  ..D6x.......L@x.
	defb 000h,000h,080h,0c0h,000h,000h,04ch,04ch,078h,080h,000h,000h,080h,0c0h,000h,0c0h	; b6b5  ......LLx.......
	defb 000h,000h,034h,05ch,064h,024h,038h,03ch,080h,000h,020h,032h,078h,080h,000h,000h	; b6c5  ..4\d$8<.. 2x...
	defb 080h,0c0h,000h,000h,024h,038h,000h,034h,05ch,064h,080h,000h,014h,032h,078h,080h	; b6d5  ....$8.4\d...2x.
	defb 000h,000h,080h,0c0h,000h,000h,01ch,030h,078h,080h,000h,000h,080h,000h,030h,03ch	; b6e5  .......0x.....0<
	defb 000h,03ah,05ah,03ch,080h,0c0h,000h,0c0h,000h,000h,044h,03ch,000h,03ah,05ah,03ch	; b6f5  .:Z<......D<.:Z<
	defb 080h,000h,058h,030h,078h,080h,000h,000h,080h,0c0h,000h,000h,054h,038h,078h,080h	; b705  ..X0x.......T8x.
	defb 000h,000h,080h,000h,040h,05ch,064h,050h,038h,03ch,080h,0c0h,000h,000h,060h,032h	; b715  ....@\dP8<....`2
	defb 078h,080h,000h,000h,080h,000h,050h,038h,000h,040h,05ch,064h,080h,000h,018h,02ch	; b725  x.....P8.@\d...,
	defb 000h,03ah,024h,000h,080h,01eh,024h,038h,078h,080h,000h,000h,080h,000h,03ah,05ah	; b735  .:$...$8x.....:Z
	defb 064h,080h,000h,000h,080h,0c0h,048h,03ch,034h,048h,000h,03ah,05ah,064h,080h,000h	; b745  d.....H<4H.:Zd..
	defb 024h,038h,078h,080h,000h,000h,080h,0c0h,04dh,0c0h,000h,000h,03ah,05ch,064h,080h	; b755  $8x.....M...:\d.
	defb 000h,000h,080h,0c0h,050h,0c0h,000h,000h,050h,038h,078h,080h,000h,000h,080h,0c0h	; b765  ....P...P8x.....
	defb 04ah,01eh,050h,038h,078h,080h,000h,000h,080h,000h,05ch,02ch,000h,03ah,024h,000h	; b775  J.P8x.....\,.:$.
	defb 080h,0c0h,053h,03ch,02ch,034h,000h,03ah,05ah,064h,080h,0c0h,056h,0c0h,0ffh	; b785  ..S<,4.:Zd..V..

; ----------------------------------------------------------------------
; DATOS nombres_titulo: Comprimido (0x60B8, 300 bytes): 544 bytes, las 17
;   filas de la tabla de nombres de la pantalla de titulo (0x76C4 -> VRAM
;   0x1800)
;   0xb794..0xb8c0  (300 bytes)
DATA_nombres_titulo:
	defb 0e0h,000h,01fh,020h,020h,0e4h,0e3h,0e5h,0ddh,000h,020h,053h,055h,050h,045h,052h	; b794  ...  ..... SUPER
	defb 020h,050h,04ch,041h,059h,045h,052h,053h,020h,020h,0e4h,0e3h,0e3h,0e5h,003h,020h	; b7a4   PLAYERS  ..... 
	defb 0cch,0ceh,0c4h,0deh,0e5h,0e4h,0e5h,009h,020h,0e6h,0e7h,0e5h,000h,0c0h,0dbh,003h	; b7b4  ........ .......
	defb 020h,0c1h,0e1h,0c1h,0c1h,0e1h,0c1h,0deh,0e5h,0e4h,0e5h,003h,020h,0e4h,0e5h,0e4h	; b7c4   ........... ...
	defb 0c3h,0ceh,0c4h,0e1h,0c1h,0e1h,004h,020h,0c1h,0e1h,0c1h,0c1h,0e1h,0c1h,0c0h,0d5h	; b7d4  ....... ........
	defb 0c1h,0deh,0e5h,0e4h,0e5h,0e6h,0e7h,0e5h,0c1h,0e1h,0c1h,0c1h,0e1h,0c1h,0e1h,0c1h	; b7e4  ................
	defb 0e1h,001h,020h,000h,0edh,0c1h,0dfh,0c1h,0c1h,0e1h,0c1h,0c1h,0d6h,0c1h,0c1h,0e1h	; b7f4  .. .............
	defb 0c1h,0ebh,0c2h,0ceh,0c4h,0c1h,0deh,0c1h,0c1h,0e1h,0c1h,0e1h,0c1h,0e1h,001h,0edh	; b804  ................
	defb 000h,0f1h,0cfh,0cfh,0cbh,0d0h,0dfh,0c1h,0c1h,0e1h,0c1h,0c1h,0d7h,0d9h,0eah,0d0h	; b814  ................
	defb 0e0h,0d1h,0cch,0cdh,0c1h,0d0h,0dfh,0c1h,0e1h,0cbh,0e1h,001h,0f1h,000h,0f0h,0d4h	; b824  ................
	defb 0d4h,0cah,0cfh,0cfh,0cbh,0c1h,0e1h,0c1h,0c0h,0c0h,0dah,0f3h,0c5h,0ceh,0c4h,0c1h	; b834  ................
	defb 0e1h,0c1h,0cfh,0cfh,0cbh,0e9h,0d3h,0e8h,007h,0f0h,0c8h,0d4h,0cah,0cbh,0e1h,0cbh	; b844  ................
	defb 0c1h,0d6h,0d8h,0fdh,0d2h,0e2h,0c1h,0cbh,0e1h,0cbh,0c7h,0d4h,0cah,009h,0f0h,0eeh	; b854  ................
	defb 000h,020h,0d3h,0dch,0d3h,0cbh,0e1h,0cbh,0e0h,0cfh,0cfh,0cbh,0d3h,0dch,0d3h,0dch	; b864  . ..............
	defb 001h,020h,0efh,005h,0f0h,0eeh,004h,020h,0d3h,0dch,0d3h,0dch,0c6h,0d4h,0c9h,004h	; b874  . ..... ........
	defb 020h,0efh,002h,0f0h,01dh,0f2h,01dh,0ech,01fh,020h,0f5h,008h,0f7h,0f6h,020h,020h	; b884   ........ ....  
	defb 0f5h,008h,0f7h,0f6h,001h,020h,066h,000h,0b0h,0b1h,000h,020h,0b2h,000h,0b0h,067h	; b894  ..... f.... ...g
	defb 056h,053h,066h,000h,0b3h,0b4h,000h,020h,0b5h,000h,0b3h,067h,001h,020h,062h,008h	; b8a4  VSf.... ...g. b.
	defb 065h,063h,020h,020h,062h,008h,065h,063h,020h,020h,000h,000h	; b8b4  ec  b.ec  ..

; ----------------------------------------------------------------------
; DATOS nombres_pantalla: Comprimido (0x60B8, 276 bytes): 768 bytes, una tabla
;   de nombres entera (0x74E9 -> VRAM 0x1800)
;   0xb8c0..0xb9d4  (276 bytes)
DATA_nombres_pantalla:
	defb 0e0h,000h,009h,020h,005h,0fah,016h,020h,053h,045h,054h,03ch,055h,050h,016h,020h	; b8c0  ... ... SET<UP. 
	defb 005h,0fah,01fh,020h,01fh,020h,007h,020h,0f5h,008h,0f7h,0f6h,020h,020h,0f5h,008h	; b8d0  ... . . ....  ..
	defb 0f7h,0f6h,001h,020h,066h,000h,0b0h,0b1h,000h,020h,0b2h,000h,0b0h,067h,056h,053h	; b8e0  ... f.... ...gVS
	defb 066h,000h,0b3h,0b4h,000h,020h,0b5h,000h,0b3h,067h,001h,020h,062h,008h,065h,063h	; b8f0  f.... ...g. b.ec
	defb 020h,020h,062h,008h,065h,063h,01fh,020h,000h,020h,0f5h,015h,0f7h,0f6h,003h,020h	; b900    b.ec. . ..... 
	defb 066h,020h,048h,041h,04ch,046h,03ah,020h,020h,030h,035h,020h,020h,031h,030h,020h	; b910  f HALF:  05  10 
	defb 020h,031h,035h,020h,020h,032h,030h,020h,020h,067h,003h,020h,066h,015h,0fah,067h	; b920   15  20  g. f..g
	defb 003h,020h,066h,020h,043h,04fh,055h,052h,054h,03ah,020h,020h,000h,0feh,020h,020h	; b930  . f COURT:  ..  
	defb 000h,0ffh,020h,020h,000h,0f0h,020h,020h,067h,003h,020h,062h,015h,065h,063h,01fh	; b940  ..  ..  g. b.ec.
	defb 020h,01fh,020h,002h,020h,0f5h,00fh,0f7h,0f6h,009h,020h,066h,020h,020h,050h,04ch	; b950   . . ..... f  PL
	defb 041h,059h,009h,020h,067h,009h,020h,066h,020h,020h,053h,054h,041h,052h,054h,045h	; b960  AY. g. f  STARTE
	defb 052h,053h,005h,020h,067h,009h,020h,066h,020h,020h,043h,048h,041h,04eh,047h,045h	; b970  RS. g. f  CHANGE
	defb 020h,053h,049h,044h,045h,053h,001h,020h,067h,009h,020h,066h,020h,020h,043h,04fh	; b980   SIDES. g. f  CO
	defb 04ch,04fh,052h,020h,04fh,046h,020h,057h,045h,041h,052h,000h,020h,067h,009h,020h	; b990  LOR OF WEAR. g. 
	defb 066h,020h,020h,04ch,045h,04eh,047h,054h,048h,020h,04fh,046h,020h,048h,041h,04ch	; b9a0  f  LENGTH OF HAL
	defb 046h,020h,020h,067h,009h,020h,066h,020h,020h,043h,04fh,04ch,04fh,052h,020h,04fh	; b9b0  F  g. f  COLOR O
	defb 046h,020h,043h,04fh,055h,052h,054h,020h,020h,067h,009h,020h,062h,00fh,065h,063h	; b9c0  F COURT  g. b.ec
	defb 003h,020h,000h,000h	; b9d0

; ----------------------------------------------------------------------
; DATOS patrones_logo: Comprimido (0x6056, 339 bytes): 640 bytes, los 80
;   patrones 0xB0-0xFF del logotipo del titulo; 0x6B2F los pone en los tres
;   tercios desde la VRAM 0x0580
;   0xb9d4..0xbb27  (339 bytes)
DATA_patrones_logo:
	defb 0f0h,050h,057h,0ffh,057h,0fch,051h,001h,050h,000h,050h,001h,051h,001h,057h,000h	; b9d4  .PW.W.Q.P.P.Q.W.
	defb 050h,006h,000h,055h,080h,000h,000h,055h,0c0h,000h,000h,055h,0e0h,000h,000h,055h	; b9e4  P..U...U...U...U
	defb 0f0h,000h,000h,055h,0f8h,000h,000h,055h,0fch,000h,000h,055h,0feh,000h,000h,055h	; b9f4  ...U...U...U...U
	defb 0ffh,000h,050h,000h,057h,0feh,007h,01fh,03fh,07fh,07fh,052h,0ffh,050h,012h,0c0h	; ba04  ..P.W...?..R.P..
	defb 0f0h,0f8h,0fch,0fch,052h,0feh,0ffh,0ffh,07fh,07fh,03fh,01fh,007h,03fh,0ffh,0ffh	; ba14  ....R.....?..?..
	defb 07fh,07fh,03fh,01fh,007h,000h,050h,016h,0ffh,0ffh,07fh,07fh,03fh,01fh,007h,007h	; ba24  ..?...P.....?...
	defb 0feh,0feh,0fch,0fch,0f8h,0f0h,0c0h,000h,0feh,0feh,0fch,0fch,0f8h,0f0h,0c0h,0c0h	; ba34  ................
	defb 050h,011h,056h,0ffh,0feh,056h,0ffh,000h,056h,0ffh,001h,050h,000h,056h,0feh,0ffh	; ba44  P.V..V..V..P.V..
	defb 053h,0feh,053h,000h,0c0h,080h,001h,053h,0feh,0ffh,056h,0feh,000h,050h,01dh,080h	; ba54  S.S....S..V..P..
	defb 0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h,003h,001h,051h	; ba64  .........?.....Q
	defb 025h,0e0h,0f0h,0f8h,0fch,053h,0feh,053h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,053h	; ba74  %....S.S.......S
	defb 000h,080h,0c0h,051h,026h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,050h,014h,0feh	; ba84  ...Q&........P..
	defb 0fdh,0fbh,0f7h,0efh,0dfh,0bfh,07fh,0feh,0fdh,0fbh,0f7h,0efh,0dfh,0bfh,0feh,050h	; ba94  ...............P
	defb 000h,050h,011h,040h,080h,054h,000h,001h,050h,000h,051h,025h,051h,025h,054h,000h	; baa4  .P.@.T..P.Q%Q%T.
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,053h,0ffh,050h,02ch,051h,026h,0e0h,0c0h,080h	; bab4  .....?.S.P,Q&...
	defb 080h,0c0h,0e0h,0f0h,0f8h,053h,0ffh,0feh,0fch,0f8h,0f0h,050h,006h,050h,006h,051h	; bac4  .....S.....P.P.Q
	defb 025h,051h,026h,050h,006h,050h,006h,050h,006h,0fch,0feh,0ffh,0feh,0fdh,0fbh,0f7h	; bad4  %Q&P.P.P........
	defb 0efh,000h,000h,052h,0ffh,052h,000h,000h,00fh,03fh,038h,077h,06fh,06eh,06ch,051h	; bae4  ...R.R...?8wonlQ
	defb 045h,000h,0ffh,0ffh,000h,0ffh,0ffh,000h,000h,057h,01ch,038h,03ch,03eh,03fh,03eh	; baf4  E........W.8<>?>
	defb 03ch,038h,000h,000h,054h,0ffh,000h,000h,0f3h,0c6h,0c6h,0f3h,0c0h,0c6h,0f3h,000h	; bb04  <8..T...........
	defb 08eh,0dbh,018h,098h,0d8h,0dbh,08eh,000h,020h,040h,080h,054h,000h,050h,006h,050h	; bb14  ........ @.T.P.P
	defb 006h,050h,0ffh	; bb24

; ----------------------------------------------------------------------
; DATOS colores_logo: Comprimido (0x6056, 269 bytes): 640 bytes, los colores
;   de los 80 patrones del logotipo, en los tres tercios desde la VRAM 0x2580
;   0xbb27..0xbc34  (269 bytes)
DATA_colores_logo:
	defb 0e0h,020h,027h,081h,020h,000h,020h,000h,027h,051h,020h,003h,020h,003h,081h,025h	; bb27  . '. . .'Q . ..%
	defb 08ch,081h,081h,025h,082h,081h,020h,007h,020h,007h,020h,007h,020h,007h,020h,007h	; bb37  ...%.. . . . . .
	defb 020h,007h,020h,007h,020h,000h,027h,0f4h,020h,010h,027h,0f1h,027h,0f5h,020h,010h	; bb47   . . .'. .'.'. .
	defb 0f6h,0f8h,0f6h,0f8h,0f6h,0f8h,0f6h,048h,054h,0f4h,071h,051h,0f1h,071h,051h,0f1h	; bb57  .......HT.qQ.qQ.
	defb 054h,0f4h,074h,054h,0f4h,074h,054h,0f4h,054h,0f4h,076h,058h,0f6h,078h,056h,018h	; bb67  T.tT.tT.T.vX.xV.
	defb 020h,016h,020h,018h,026h,0f4h,074h,020h,010h,020h,010h,020h,010h,020h,01bh,020h	; bb77   . .&.t . . . . 
	defb 010h,020h,010h,064h,084h,014h,024h,0f4h,054h,0f4h,074h,054h,0f4h,074h,054h,0f1h	; bb87  . .d..$.T.tT.tT.
	defb 051h,0f1h,071h,051h,0f1h,071h,051h,0f1h,020h,010h,020h,010h,020h,010h,020h,010h	; bb97  Q.qQ.qQ. . . . .
	defb 020h,010h,020h,010h,027h,041h,020h,02bh,020h,02bh,020h,02bh,026h,041h,04fh,020h	; bba7   . .'A + + +&AO 
	defb 02bh,020h,02bh,022h,014h,024h,0f4h,020h,003h,020h,003h,027h,045h,020h,003h,020h	; bbb7  + +".$. . .'E . 
	defb 003h,046h,048h,046h,048h,046h,048h,046h,048h,020h,038h,04fh,04fh,046h,048h,046h	; bbc7  .FHFHFHFH 8OOFHF
	defb 048h,046h,048h,027h,042h,027h,0f2h,023h,0f1h,023h,0f2h,016h,018h,016h,018h,016h	; bbd7  HFH'B'.#.#......
	defb 018h,016h,018h,020h,03eh,020h,03eh,01fh,01fh,016h,018h,016h,018h,016h,018h,016h	; bbe7  ... > >.........
	defb 018h,016h,018h,016h,018h,01fh,01fh,046h,048h,046h,024h,045h,0f1h,0f1h,071h,051h	; bbf7  .......FHF$E..qQ
	defb 041h,022h,0f1h,027h,0a1h,020h,045h,020h,045h,020h,003h,027h,0d1h,0f1h,071h,051h	; bc07  A".'. E E .'..qQ
	defb 041h,051h,041h,0f1h,0f1h,027h,0f6h,020h,04bh,027h,054h,01ch,012h,01ch,012h,01ch	; bc17  AQA..'. K'T.....
	defb 012h,01ch,012h,014h,015h,014h,015h,014h,015h,014h,015h,020h,0ffh	; bc27  ........... .

; ----------------------------------------------------------------------
; DATOS curva_5deb: 128 bytes: -8..131 saltandose un valor cada vez mas a
;   menudo; 0x640F lee el de indice (hl+1), le suma 0x40 y lo recorta a 0xC0
;   0xbc34..0xbcb4  (128 bytes)
DATA_curva_5deb:
	defb 0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh,000h,001h,002h,003h,004h,005h,006h,007h	; bc34  ................
	defb 008h,009h,00ah,00bh,00ch,00dh,00eh,00fh,010h,011h,012h,013h,014h,015h,016h,017h	; bc44  ................
	defb 018h,019h,01ah,01bh,01ch,01eh,01fh,020h,021h,022h,023h,024h,025h,026h,027h,028h	; bc54  ....... !"#$%&'(
	defb 029h,02bh,02ch,02dh,02eh,02fh,030h,031h,032h,033h,035h,036h,037h,038h,039h,03ah	; bc64  )+,-./012356789:
	defb 03bh,03ch,03eh,03fh,040h,041h,042h,043h,045h,046h,047h,048h,049h,04ah,04ch,04dh	; bc74  ;<>?@ABCEFGHIJLM
	defb 04eh,04fh,050h,051h,053h,054h,055h,056h,057h,059h,05ah,05bh,05ch,05dh,05fh,060h	; bc84  NOPQSTUVWYZ[\]_`
	defb 061h,062h,064h,065h,066h,067h,069h,06ah,06bh,06ch,06eh,06fh,070h,071h,072h,073h	; bc94  abdefgijklnopqrs
	defb 074h,075h,076h,077h,078h,079h,07ah,07bh,07ch,07dh,07eh,07fh,080h,081h,082h,083h	; bca4  tuvwxyz{|}~.....

; ----------------------------------------------------------------------
; DATOS curva_5db9: 128 bytes: de 220 a 255, en escalones de dos o tres;
;   0x63DA lee el de indice (hl+1) y lo multiplica con 0x673C
;   0xbcb4..0xbd34  (128 bytes)
DATA_curva_5db9:
	defb 0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0ddh,0ddh,0ddh,0deh,0deh	; bcb4  ................
	defb 0deh,0dfh,0dfh,0dfh,0e0h,0e0h,0e0h,0e0h,0e1h,0e1h,0e1h,0e2h,0e2h,0e2h,0e3h,0e3h	; bcc4  ................
	defb 0e3h,0e4h,0e4h,0e4h,0e5h,0e5h,0e6h,0e6h,0e6h,0e7h,0e7h,0e7h,0e8h,0e8h,0e8h,0e8h	; bcd4  ................
	defb 0e9h,0e9h,0eah,0eah,0eah,0ebh,0ebh,0ebh,0ech,0ech,0edh,0edh,0edh,0eeh,0eeh,0eeh	; bce4  ................
	defb 0efh,0efh,0f0h,0f0h,0f0h,0f0h,0f1h,0f1h,0f2h,0f2h,0f2h,0f3h,0f3h,0f3h,0f4h,0f4h	; bcf4  ................
	defb 0f5h,0f5h,0f5h,0f6h,0f6h,0f7h,0f7h,0f7h,0f8h,0f8h,0f8h,0f9h,0f9h,0f9h,0fah,0fah	; bd04  ................
	defb 0fbh,0fbh,0fch,0fch,0fch,0fdh,0fdh,0feh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd14  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bd24  ................

; ----------------------------------------------------------------------
; DATOS gradas: Comprimido (0x60B8, 714 bytes): 1344 bytes, 42 filas de 32
;   numeros de patron (0x21-0x2B) que 0x65B8 descomprime en 0xCB3D
;   0xbd34..0xbffe  (714 bytes)
DATA_gradas:
	defb 0e0h,040h,021h,022h,029h,026h,024h,027h,023h,02bh,022h,021h,024h,028h,025h,02ah	; bd34  .@!")&$'#+"!$(%*
	defb 023h,021h,022h,02ah,024h,025h,028h,021h,023h,028h,025h,02ah,027h,022h,029h,025h	; bd44  #!"*$%(!#(%*'")%
	defb 021h,024h,025h,022h,023h,02ah,024h,025h,027h,029h,023h,021h,02bh,025h,027h,023h	; bd54  !$%"#*$%')#!+%'#
	defb 022h,021h,02bh,029h,021h,026h,02ah,023h,028h,021h,024h,023h,021h,025h,028h,025h	; bd64  "!+)!&*#(!$#!%(%
	defb 02ah,025h,026h,026h,02ah,021h,029h,027h,025h,02bh,029h,022h,02bh,026h,024h,02ah	; bd74  *%&&*!)'%+)"+&$*
	defb 026h,021h,027h,023h,029h,026h,02ah,02bh,022h,023h,026h,024h,025h,021h,023h,02bh	; bd84  &!'#)&*+"#&$%!#+
	defb 029h,025h,02bh,026h,024h,029h,021h,029h,025h,028h,027h,02ah,022h,027h,02bh,024h	; bd94  )%+&$)!)%('*"'+$
	defb 029h,023h,026h,025h,027h,028h,023h,029h,021h,029h,023h,028h,022h,027h,028h,024h	; bda4  )#&%'(#)!)#("'($
	defb 025h,024h,026h,02bh,023h,02ah,027h,023h,025h,028h,026h,025h,02bh,024h,023h,02ah	; bdb4  %$&+#*'#%(&%+$#*
	defb 027h,028h,024h,022h,024h,026h,027h,028h,021h,02ah,024h,022h,02ah,021h,028h,026h	; bdc4  '($"$&'(!*$"*!(&
	defb 022h,024h,026h,025h,023h,028h,022h,025h,02ah,022h,027h,024h,022h,029h,026h,022h	; bdd4  "$&%#("%*"'$")&"
	defb 02bh,026h,025h,026h,025h,024h,02bh,022h,029h,027h,021h,027h,02ah,025h,026h,029h	; bde4  +&%&%$+")'!'*%&)
	defb 02bh,025h,022h,028h,021h,029h,028h,021h,02bh,022h,021h,027h,023h,022h,028h,02ah	; bdf4  +%"(!)(!+"!'#"(*
	defb 028h,025h,028h,029h,022h,026h,025h,024h,026h,023h,021h,028h,024h,029h,021h,026h	; be04  (%()"&%$&#!($)!&
	defb 02bh,024h,023h,028h,026h,021h,02ch,02ah,027h,024h,02bh,021h,027h,02ah,023h,026h	; be14  +$#(&!,*'$+!'*#&
	defb 028h,023h,025h,028h,025h,022h,024h,021h,027h,023h,021h,024h,026h,025h,024h,028h	; be24  (#%(%"$!'#!$&%$(
	defb 021h,027h,02ah,02bh,028h,024h,027h,026h,022h,02bh,021h,027h,02ah,029h,02bh,028h	; be34  !'*+($'&"+!'*)+(
	defb 024h,02ah,027h,026h,025h,02dh,022h,027h,021h,025h,041h,002h,011h,002h,002h,001h	; be44  $*'&%-"'!%A.....
	defb 00dh,00fh,00ch,006h,00ch,001h,00ch,009h,003h,010h,006h,00ch,00dh,001h,005h,00fh	; be54  ................
	defb 00ah,008h,001h,00dh,007h,00bh,00eh,001h,002h,001h,007h,003h,009h,001h,009h,003h	; be64  ................
	defb 004h,00bh,00ch,003h,00eh,00bh,00ch,010h,001h,002h,002h,012h,041h,002h,040h,016h	; be74  ............A.@.
	defb 01eh,013h,016h,016h,015h,01bh,01bh,019h,01ah,01dh,015h,019h,01ah,017h,01ch,01ah	; be84  ................
	defb 01dh,01bh,015h,018h,01bh,017h,017h,015h,01bh,017h,01bh,01ch,015h,016h,015h,017h	; be94  ................
	defb 017h,01ah,015h,01ah,017h,018h,01bh,01dh,017h,01ch,01bh,01dh,01ch,015h,016h,016h	; bea4  ................
	defb 014h,01fh,040h,016h,040h,074h,076h,07ah,05fh,084h,049h,084h,07bh,077h,040h,074h	; beb4  ..@.@tvz_.I.{w@t
	defb 040h,084h,078h,07ch,084h,087h,051h,094h,096h,097h,051h,094h,088h,084h,07dh,079h	; bec4  @.x|..Q...Q...}y
	defb 043h,084h,078h,07eh,084h,08dh,042h,0a8h,0a9h,0aah,0abh,049h,08fh,090h,091h,049h	; bed4  C.x~..B....I...I
	defb 08fh,0c6h,0c7h,0a9h,042h,0a8h,08eh,084h,07fh,079h,040h,084h,040h,075h,082h,080h	; bee4  ....B....y@.@u..
	defb 0d7h,045h,08fh,0ach,0adh,0aeh,047h,08fh,090h,091h,047h,08fh,0c3h,0c4h,0c5h,045h	; bef4  .E....G...G....E
	defb 08fh,0d8h,081h,083h,040h,075h,042h,084h,0d9h,047h,08fh,0afh,0b0h,046h,08fh,090h	; bf04  ....@uB..G...F..
	defb 091h,046h,08fh,0c1h,0c2h,047h,08fh,0dah,047h,084h,089h,046h,095h,09ah,08fh,0b1h	; bf14  .F...G..G..F....
	defb 045h,08fh,0ddh,0e5h,0e6h,0deh,045h,08fh,0c0h,08fh,0a4h,046h,095h,08ah,047h,084h	; bf24  E.....E....F..G.
	defb 0f8h,045h,0d2h,093h,09bh,09ch,0b2h,044h,08fh,0e1h,0efh,0ebh,0ech,0f0h,0e2h,044h	; bf34  .E.....D.......D
	defb 08fh,0bfh,0a2h,0a3h,092h,045h,0d2h,0f9h,046h,084h,0f4h,045h,0d2h,0d3h,091h,08fh	; bf44  .....E..F..E....
	defb 09dh,092h,044h,08fh,0edh,0d2h,0d3h,0d4h,0d2h,0eeh,044h,08fh,093h,0a1h,08fh,090h	; bf54  ..D.......D.....
	defb 0d4h,045h,0d2h,0f5h,045h,084h,0f6h,045h,0d2h,0d5h,08fh,09fh,0a0h,0b3h,044h,08fh	; bf64  .E..E..E......D.
	defb 0e3h,0f1h,0e9h,0eah,0f2h,0e4h,044h,08fh,0c8h,0a5h,0a6h,08fh,0d6h,045h,0d2h,0f7h	; bf74  ......D......E..
	defb 045h,084h,087h,047h,094h,09eh,08fh,0b4h,045h,08fh,0dfh,0e7h,0e8h,0e0h,045h,08fh	; bf84  E..G....E.....E.
	defb 0c9h,08fh,0a7h,047h,094h,088h,045h,084h,0dbh,048h,08fh,0b6h,0b5h,046h,08fh,090h	; bf94  ...G..E..H...F..
	defb 091h,046h,08fh,0cah,0cbh,048h,08fh,0dch,044h,084h,0d7h,048h,08fh,0b8h,0b7h,047h	; bfa4  .F...H..D..H...G
	defb 08fh,090h,091h,047h,08fh,0cch,0cdh,048h,08fh,0d8h,043h,084h,0d9h,043h,08fh,0bdh	; bfb4  ...G...H..C..C..
	defb 0bdh,0bch,0bbh,0bah,0b9h,048h,08fh,090h,091h,048h,08fh,0ceh,0cfh,0d0h,0d1h,0bdh	; bfc4  .....H...H......
	defb 0bdh,043h,08fh,0dah,043h,084h,087h,043h,094h,0beh,0beh,04ch,08fh,090h,091h,04ch	; bfd4  .C..C..C...L...L
	defb 08fh,0beh,0beh,043h,094h,088h,043h,084h,08bh,054h,095h,098h,099h,054h,095h,08ch	; bfe4  ...C..C..T...T..
	defb 05fh,084h,05fh,084h,05fh,084h,04ah,084h,040h,040h	; bff4  _._._.J.@@

; ----------------------------------------------------------------------
; DATOS relleno_final: Dos bytes a 0xFF: el cartucho acaba aqui
;   0xbffe..0xc000  (2 bytes)
DATA_relleno_final:
	defb 0ffh,0ffh	; bffe

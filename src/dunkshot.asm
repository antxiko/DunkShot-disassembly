; ==========================================================================
; DUNK SHOT - HAL Laboratory - MSX1 - cartucho de 32 KB en las paginas 1 y 2
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
L_593E:	equ 0x0593e

; ----------------------------------------------------------------------
; Direcciones que solo aparecen como VALOR -en un `ld`, no en
; un salto-: son punteros que el codigo se pasa o numeros que
; casualmente coinciden con una direccion. No hay nada que
; trazar en ellas; el equ existe para que el listado ensamble.
; ----------------------------------------------------------------------
lbf1ch:	equ 0x0bf1c

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
; CODIGO 0x4010..0x43aa  (922 bytes)
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
	ld a,0c3h		;4038   ; H.TIMI = jp 0x606E (rutina de interrupcion)
	ld (0fd9fh),a		;403a   ; opcode jp
	ld hl,0606eh		;403d   ; destino del gancho
	ld (0fda0h),hl		;4040   ; la direccion del gancho: 0x606E
	ei			;4043   ; interrupciones en marcha con el gancho puesto
	call borra_ram		;4044   ; RAM 0xE500-0xF011 a cero
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
	ld (0ed90h),hl		;4061   ; cuenta atras general (la baja la interrupcion)
	call pantalla_titulo		;4064   ; fondo y creditos
espera_titulo:		; Espera un disparo en el titulo o que se acabe la cuenta y salte la demo
	ld hl,(0ed90h)		;4067   ; cuenta atras del titulo
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
	ld (0e6f4h),a		;407d   ; 0 = partido de verdad, no demo
L_4080:
	call suelta_sprites		;4080   ; reanuda la alternancia de tablas de sprites
	call borra_jugada		;4083   ; jugadores parados
	call inicia_partido		;4086   ; variables de jugada
	xor a			;4089   ; A = combinacion de mandos
	ld hl,0efd6h		;408a   ; modo del equipo izquierdo
	bit 1,(hl)		;408d   ; bit 1 del modo: equipo de la maquina (modo 2)
	jr z,L_4093		;408f   ; no es de la maquina
	set 1,a		;4091   ; bit 1: izquierdo de la maquina
L_4093:
	ld hl,0efd7h		;4093   ; modo del equipo derecho
	bit 1,(hl)		;4096   ; bit 1 del modo del equipo derecho
	jr z,L_409C		;4098   ; bit 1 de 0xEFD7 a cero: bit 0 de 0xF012 a cero
	set 0,a		;409a   ; bit 0: derecho de la maquina
L_409C:
	ld (0f012h),a		;409c   ; combinacion de mandos (indice de la tabla de saltos 0xB985)
L_409F:
	call monta_partido		;409f   ; monta la pantalla de juego
bucle_partido:		; Un cuadro del partido y las comprobaciones de fin de mitad, faltas y saques
	call cuadro_partido		;40a2   ; cuadro completo: logica, VRAM y sprites
	call violaciones		;40a5   ; cuentas de 10 y 30 segundos vencidas
	call fin_de_mitad		;40a8   ; fin de la mitad?
	jp nz,final_de_mitad		;40ab   ; si: pitido y final de mitad
	ld a,(0ed63h)		;40ae   ; canasta hecha?
	and a			;40b1   ; hay falta?
	call nz,tras_canasta		;40b2   ; si: saque de fondo tras la canasta
	ld a,(0ed6fh)		;40b5   ; infractor pendiente?
	and a			;40b8   ; hay pase?
	call p,pita_falta		;40b9   ; hay infractor: se pita la falta
	ld a,(0e850h)		;40bc   ; formacion pedida?
	and a			;40bf   ; positivo: hay formacion que pintar
	call m,inicia_formacion		;40c0   ; bit 7 de 0xE850: formacion pedida
	call vigila_formacion		;40c3   ; corta la formacion si toca
	jr bucle_partido		;40c6   ; siguiente cuadro
fin_de_mitad:		; Devuelve NZ cuando (0xED7A) dice que la mitad se ha acabado
	ld a,(0ed7ah)		;40c8   ; 1 = la mitad ha acabado
	and a			;40cb   ; cero: sigue el partido
	ret			;40cc   ; Z si el partido sigue
violaciones:		; Si salto la cuenta de 10 (0xED81) o de 30 segundos (0xED82), apunta la falta al controlado del equipo con el balon
	ld a,(0ed81h)		;40cd   ; cuenta de 10 segundos
	dec a			;40d0   ; 1 = vencida
	ld b,003h		;40d1   ; rotulo 3: 10 SECOND
	jr z,L_40DC		;40d3   ; un jugador humano ha pedido cambio
	ld a,(0ed82h)		;40d5   ; cuenta de 30 segundos
	ld b,004h		;40d8   ; rotulo 4: 30 SECOND
	dec a			;40da   ; 1 = vencida
	ret nz			;40db   ; ninguno: nada
L_40DC:
	call controlado		;40dc   ; infractor: el controlado del equipo con el balon
	ld (0ed6fh),a		;40df   ; jugador infractor
	ld a,b			;40e2   ; A = 3 o 4: que equipo
	ld (0ed70h),a		;40e3   ; tipo de falta
	ret			;40e6   ; (0xED70) = equipo del cambio
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
	call servicio_vram		;4104   ; un cuadro
	call ordena_profundidad		;4107   ; orden de pintado
	call servicio_vram		;410a   ; un cuadro
	call vuelca_sprites		;410d   ; ordena y copia los sprites a 0x1B00 y 0x1F00
	call servicio_vram		;4110   ; un cuadro
	ld hl,0e6d7h		;4113   ; cuenta de cuadros del partido
	inc (hl)			;4116   ; un cuadro mas
	ld a,(0e6f4h)		;4117   ; en la demo cualquier disparo
	and a			;411a   ; 0 = partido de verdad
	ret z			;411b   ; no esta activo: nada
	call lee_disparo		;411c   ; en la demo, un disparo la corta
	ret z			;411f   ; sin disparo: nada
	call fin_demo		;4120   ; corta la demo y vuelve al titulo
	jp vuelta_al_titulo		;4123   ; al titulo
fin_de_partido:		; GAME OVER: decide el ganador, toca su pieza y los ganadores saltan hasta que se pulse algo
	call rotulo_game_over		;4126   ; rotulo GAME OVER en el marcador
	ld b,078h		;4129   ; 120 cuadros de juego todavia en marcha
L_412B:
	push bc			;412b   ; guarda BC
	call cuadro_partido		;412c   ; sigue el juego en marcha
	pop bc			;412f   ; recupera BC
	djnz L_412B		;4130
	ld b,0ffh		;4132   ; B = 0xFF: empate
	ld a,(0ea2dh)		;4134   ; puntos del equipo izquierdo
	ld hl,0ea5dh		;4137   ; contra los del derecho
	cp (hl)			;413a   ; izquierdo contra derecho
	jr z,L_4141		;413b
	inc b			;413d   ; B = 0
	jr nc,L_4141		;413e   ; el izquierdo tiene mas: gana el
	inc b			;4140   ; B = 1: gana el derecho
L_4141:
	ld a,b			;4141
	ld (0e6f5h),a		;4142   ; 0xFF empate, 0 gana el izquierdo, 1 gana el derecho
	inc b			;4145   ; Z si gano el izquierdo
	dec b			;4146
	jp m,L_4170		;4147   ; empate: pieza 0x0C
	ld hl,(0efd6h)		;414a   ; modos de los dos equipos (L izquierdo, H derecho)
	ld a,l			;414d   ; modo del izquierdo
	jr z,L_4151		;414e
	ld a,h			;4150   ; modo del derecho
L_4151:
	and a			;4151   ; el ganador tiene que tener un equipo propio
	jr nz,L_4170		;4152   ; el ganador no es el modo 0: pieza 0x0C
	inc b			;4154
	dec b			;4155
	ld a,h			;4156   ; modo del perdedor
	jr z,L_415A		;4157
	ld a,l			;4159
L_415A:
	cp 002h		;415a   ; el perdedor tiene que ser la maquina (modo 2)
	jr nz,L_4170		;415c
	inc b			;415e   ; de que lado es el perdedor
	dec b			;415f
	ld a,(0e854h)		;4160   ; nivel del equipo izquierdo
	jr nz,L_4168		;4163
	ld a,(0e940h)		;4165   ; nivel del equipo derecho
L_4168:
	cp 008h		;4168   ; nivel del perdedor (roster +3) igual a 8
	jr nz,L_4170		;416a   ; no es la maquina de nivel 8
	ld a,00bh		;416c   ; pieza 0x0B: equipo propio gana a la maquina de nivel 8
	jr L_4172		;416e
L_4170:
	ld a,00ch		;4170   ; pieza 0x0C: final de partido normal
L_4172:
	call arranca_sonido		;4172   ; suena la pieza
	call oculta_balon		;4175   ; balon oculto
	call push_any_key		;4178   ; rotulo PUSH ANY KEY en la fila 23
celebra_ganadores:		; Bucle del GAME OVER: saltos al azar de los ganadores hasta pulsar un disparo
	call lee_disparo		;417b   ; disparo: se acabo
	jr nz,L_41DC		;417e
	ld a,007h		;4180   ; 7: balon de nadie
	ld (0e6cfh),a		;4182   ; SUPOSICION: 7 = nadie controlado
	ld ix,0e500h		;4185   ; IX = equipo izquierdo, IY = derecho
	ld iy,0e590h		;4189   ; IY = equipo derecho
	ld a,(0e6f5h)		;418d   ; resultado
	and a			;4190
	jp m,L_41D4		;4191   ; empate: nadie salta
	jr z,L_419E		;4194   ; gana el izquierdo
	ld ix,0e590h		;4196   ; gana el derecho: se cambian los papeles
	ld iy,0e500h		;419a   ; IY = equipo izquierdo
L_419E:
	ld b,003h		;419e   ; tres jugadores por equipo
L_41A0:
	ld a,(ix+00ch)		;41a0   ; ya esta en el aire
	and a			;41a3   ; en el aire?
	jr nz,L_41C1		;41a4
	call azar_r		;41a6   ; una vez de cada cuatro al azar
	and 003h		;41a9   ; 3 de cada 4 veces no salta
	jr nz,L_41C1		;41ab
	ld (ix+00ch),00fh		;41ad   ; gravedad del salto
	ld (ix+00ah),04ah		;41b1   ; velocidad vertical inicial 0x14A
	ld (ix+00bh),001h		;41b5   ; (velocidad 0x14A)
	ld (ix+00dh),052h		;41b9   ; pose 0x52: salto
	set 7,(ix+00fh)		;41bd   ; pose cambiada
L_41C1:
	ld (iy+020h),07fh		;41c1   ; SUPOSICION: destino Y 0x7F (+0x20) del perdedor
	ld a,(iy+003h)		;41c5   ; X del perdedor
	ld (iy+021h),a		;41c8   ; como destino X
	ld de,00030h		;41cb   ; siguiente jugador (registros de 0x30)
	add ix,de		;41ce   ; siguiente ganador
	add iy,de		;41d0   ; siguiente perdedor
	djnz L_41A0		;41d2
L_41D4:
	call cuadro_partido		;41d4   ; un cuadro
	call recoloca_fuera_de_pista		;41d7   ; SUPOSICION: los que salen por la derecha vuelven a la pista
	jr celebra_ganadores		;41da
L_41DC:
	call borra_jugada		;41dc   ; nueva pantalla: borra el partido
	call guarda_resultado		;41df   ; SUPOSICION: guarda el resultado del partido
	jp vuelta_al_titulo		;41e2
final_de_mitad:		; Pitido de final de mitad; tras la primera, HALF TIME y vuelta a empezar; tras la segunda, GAME OVER
	ld a,006h		;41e5
	call arranca_sonido		;41e7   ; pieza 6: bocina de final
	ld a,001h		;41ea   ; bloquea mandos, ataque, defensa, movimiento y tiro
	ld (0ed6ch),a		;41ec
	ld (0ed69h),a		;41ef
	ld (0ed6ah),a		;41f2
	ld (0ed6bh),a		;41f5
	ld (0ed6dh),a		;41f8
L_41FB:
	ld a,(0e62ch)		;41fb   ; balon libre (gravedad): se deja caer antes del pitido final
	and a			;41fe
	push af			;41ff
	call nz,cuadro_partido		;4200   ; deja que caiga
	pop af			;4203
	jr nz,L_41FB		;4204
	ld a,(0ed78h)		;4206   ; numero de mitad: 0 la primera
	and a			;4209   ; Z: primera mitad
	jp nz,fin_de_partido		;420a   ; acabo la segunda: GAME OVER
	call rotulo_half_time		;420d   ; rotulo HALF TIME
	call oculta_balon		;4210   ; sin balon en la pista
	ld hl,00078h		;4213   ; dos segundos de espera
	ld (0e6efh),hl		;4216
L_4219:
	ld hl,(0e6efh)		;4219   ; la baja la interrupcion
	ld a,h			;421c
	or l			;421d
	jr nz,L_4219		;421e
	ld a,07fh		;4220   ; destino Y 0x7F
	ld hl,0e503h		;4222   ; X del primer jugador (+3)
	ld b,006h		;4225   ; los seis jugadores
L_4227:
	ld c,(hl)			;4227   ; X del jugador
	ld de,0001dh		;4228
	add hl,de			;422b   ; destino Y (+0x20)
	ld (hl),a			;422c   ; SUPOSICION: destino (Y 0x7F, X la suya) en +0x20/+0x21
	inc hl			;422d
	ld (hl),c			;422e   ; destino X (+0x21) = la suya
	ld de,00012h		;422f   ; siguiente registro
	add hl,de			;4232
	djnz L_4227		;4233
L_4235:
	call cuadro_partido		;4235   ; se van a la banda
	call todos_llegaron		;4238   ; SUPOSICION: Z cuando todos han llegado al destino
	jr z,L_4242		;423b   ; todos llegaron
	call recoloca_fuera_de_pista		;423d   ; los que pasan de la banda se quedan en ella
	jr L_4235		;4240
L_4242:
	ld a,(0e6f4h)		;4242   ; demo?
	and a			;4245
	jr z,L_424E		;4246   ; partido de verdad: sigue
	call fin_demo		;4248   ; en la demo vuelve al titulo
	jp vuelta_al_titulo		;424b
L_424E:
	call push_any_key		;424e   ; rotulo PUSH ANY KEY
	ld a,00ah		;4251   ; pieza 0x0A
	call arranca_sonido		;4253
L_4256:
	call lee_disparo		;4256   ; espera un disparo
	jr z,L_4256		;4259
	ld hl,0ed78h		;425b   ; segunda mitad
	inc (hl)			;425e   ; mitad 1
	call congela_sprites		;425f
	call oculta_sprites		;4262   ; sin sprites
	call cambios		;4265   ; SUPOSICION: pantalla entre mitades
	call congela_sprites		;4268
	call inicia_mitad		;426b   ; reloj de la segunda mitad
	call suelta_sprites		;426e
	call muestra_balon		;4271   ; balon visible
	call borra_jugada		;4274   ; jugadores parados
	call inicia_partido		;4277   ; variables de jugada
	jp L_409F		;427a   ; al bucle del partido
arranca_demo:		; Demo del titulo: equipos de la maquina y partido con la bandera 0xE6F4 a 1
	call congela_sprites		;427d
	call prepara_demo		;4280   ; equipos de la demo
	call borra_jugada		;4283   ; jugadores parados
	call inicia_partido		;4286   ; variables de jugada
	ld a,001h		;4289
	ld (0e6f4h),a		;428b   ; 1 = demo
	jp L_4080		;428e   ; arranca el partido
recoloca_fuera_de_pista:		; SUPOSICION: los jugadores con Y mayor de 0x77 se paran y se colocan en la X (0xE6C6) negada
	ld b,006h		;4291   ; seis jugadores
	ld ix,0e500h		;4293   ; primer registro de jugador
	ld de,00030h		;4297
	ld hl,0e6c6h		;429a   ; SUPOSICION: X de la canasta
L_429D:
	ld a,077h		;429d   ; limite de la banda
	cp (ix+001h)		;429f   ; Y del jugador (+1)
	jr nc,L_42C4		;42a2   ; Y no pasa de 0x77
	ld (ix+020h),000h		;42a4   ; SUPOSICION: destino borrado
	ld (ix+021h),000h		;42a8   ; sin destino X
	ld (ix+004h),000h		;42ac   ; velocidades Y (+4/+5) y X (+6/+7) a cero
	ld (ix+005h),000h		;42b0
	ld (ix+006h),000h		;42b4
	ld (ix+007h),000h		;42b8
	ld a,(0e6c6h)		;42bc
	neg		;42bf
	ld (ix+003h),a		;42c1   ; X opuesta a la canasta
L_42C4:
	add ix,de		;42c4   ; siguiente registro
	djnz L_429D		;42c6
	ret			;42c8

; ----------------------------------------------------------------------
; ===== Comienzo de cada mitad: pista, marcador y salto entre dos =====
; ----------------------------------------------------------------------
monta_partido:		; Pista en 0xC400, ventana centrada, marcador y salto entre dos; despues da el control al equipo que se queda el balon
	call descomprime_mapa		;42c9   ; pista de 56 columnas
	ld a,00ch		;42cc   ; ventana en la columna 12 (el centro)
	ld (0e830h),a		;42ce   ; columna de la ventana
	ld a,080h		;42d1   ; X fina en el centro
	ld (0e831h),a		;42d3   ; X fina
	xor a			;42d6   ; desplazamiento 0
	call copia_ventana		;42d7   ; copia la ventana sin moverla
	call congela_sprites		;42da   ; tabla de sprites fija mientras se pinta
	call monta_marcador		;42dd   ; marcador completo
	call suelta_sprites		;42e0
	ld hl,0012ch		;42e3   ; 300 cuadros para el salto entre dos
	ld (0e6efh),hl		;42e6   ; cuenta atras del salto
	ld a,001h		;42e9   ; 1 = salto entre dos en marcha
	ld (0e6f1h),a		;42eb
bucle_salto_entre_dos:		; Cuadros del salto inicial hasta que alguien se queda el balon
	call salto_entre_dos		;42ee   ; logica del salto inicial
	call servicio_vram		;42f1   ; servicio de VRAM
	call ordena_profundidad		;42f4   ; orden de pintado
	call servicio_vram		;42f7
	call vuelca_sprites		;42fa   ; sprites
	ld a,(0e6f1h)		;42fd   ; 0 = ya hay poseedor
	and a			;4300
	jr nz,bucle_salto_entre_dos		;4301
	ld a,(0e6cfh)		;4303   ; jugador con el balon (bits 0-2)
	push af			;4306
	cp 003h		;4307   ; 0-2 equipo izquierdo, 3-5 derecho
	jr nc,L_4314		;4309   ; 3-5: equipo derecho
	call registro_jugador		;430b   ; registro del poseedor
	call controla_poseedor		;430e   ; controla a quien tiene el balon
	xor a			;4311   ; ataca el equipo izquierdo
	jr L_431C		;4312
L_4314:
	call registro_jugador		;4314   ; registro del poseedor
	call controla_poseedor		;4317
	ld a,001h		;431a   ; ataca el equipo derecho
L_431C:
	ld (0e83ch),a		;431c   ; bit 0 = equipo con el balon
	ld de,00025h		;431f   ; +0x25: su defensor emparejado, que pasa a controlarse
	add hl,de			;4322
	ld a,(hl)			;4323   ; su par
	call controla		;4324   ; controlado del otro equipo
	pop af			;4327
	ld (0e6d2h),a		;4328   ; SUPOSICION: ultimo poseedor
	call destinos_defensa		;432b   ; SUPOSICION: destinos de los que no tienen el balon
	call reloj_en_marcha		;432e   ; reloj en marcha
	call cuenta_10s		;4331   ; cuenta de 10 segundos
	jp cuenta_30s		;4334   ; y la de 30 segundos
controla_poseedor:		; Pasa el control al jugador A y lo apunta en los bits bajos de 0xE6CF
	call controla		;4337
	ld c,a			;433a
	ld a,(0e6c0h)		;433b   ; bits altos de salida (desplazamiento de ventana)
	or c			;433e
	ld (0e6cfh),a		;433f   ; poseedor
	ret			;4342
logica_jugadores:		; Recorre los seis jugadores: mando o maquina, pose y velocidad de cada uno; despues la animacion de la red
	call elige_receptor		;4343   ; elige y marca el receptor del pase
	ld ix,0e500h		;4346   ; primer registro
	exx			;434a
	ld b,006h		;434b   ; seis jugadores
	ld c,000h		;434d   ; C' = numero de jugador
L_434F:
	ld a,c			;434f   ; jugador en curso (0-5)
	ld (0e721h),a		;4350   ; jugador en curso
	ld hl,00000h		;4353
	exx			;4356
	ld c,03fh		;4357   ; sin direccion
	ld de,00000h		;4359   ; sin movimiento
	ex af,af'			;435c
	ld a,000h		;435d   ; A' = equipo izquierdo
	ex af,af'			;435f
	exx			;4360
	ld a,(0e6d8h)		;4361   ; controlado del equipo izquierdo
	cp c			;4364   ; es el controlado izquierdo?
	push af			;4365
	exx			;4366
	call z,lee_mando		;4367   ; si es el: lo mueve el mando
	pop af			;436a
	jr z,L_4385		;436b   ; ya movido por el mando
	exx			;436d
	ld a,(0e6dbh)		;436e   ; controlado del equipo derecho
	cp c			;4371   ; es el controlado derecho?
	push af			;4372
	exx			;4373
	ex af,af'			;4374
	ld a,001h		;4375   ; A' = equipo derecho
	ex af,af'			;4377
	call z,lee_mando		;4378   ; lo mueve el mando
	pop af			;437b
	jr z,L_4385		;437c   ; ya movido por el mando
	exx			;437e
	ld a,c			;437f   ; A = numero de jugador
	exx			;4380
	call maquina		;4381   ; los demas: la maquina
	ex af,af'			;4384
L_4385:
	ex af,af'			;4385   ; pose pedida a A'
	call decide_accion		;4386   ; decide la accion y la pose
	call aplica_pose		;4389   ; aplica pose y velocidad
	exx			;438c
	ld de,00030h		;438d   ; siguiente registro
	add ix,de		;4390   ; siguiente registro
	inc c			;4392   ; siguiente numero
	djnz L_434F		;4393
	exx			;4395
	call nada		;4396   ; SUPOSICION: companeros sin balon
	ld a,(0e633h)		;4399   ; paso de la animacion de la red
	and a			;439c   ; negativo: red parada
	ret m			;439d
	ld e,a			;439e
	ld d,000h		;439f
	ld hl,043aah		;43a1   ; patrones de red 0x60, 0x64, 0x68
	add hl,de			;43a4
	ld a,(hl)			;43a5   ; patron de este paso
	ld (0e6b2h),a		;43a6   ; patron de la red en curso
	ret			;43a9

; ----------------------------------------------------------------------
; DATOS cuadros_e6b2: Cinco numeros de patron (0x60 0x64 0x68 0x64 0x60):
;   0x43A1 copia a 0xE6B2 el de indice (0xE633)
;   0x43aa..0x43af  (5 bytes)
DATA_cuadros_e6b2:
	defb 060h,064h,068h,064h,060h	; 43aa

; ======================================================================
; CODIGO 0x43af..0x4bfd  (2126 bytes)
; ======================================================================


aplica_pose:		; Guarda la pose de A' (+0x0D), su direccion (+0x15) y convierte la direccion DE en velocidades Y (+4/+5) y X (+6/+7)
	ei			;43af
	ex af,af'			;43b0   ; A = pose pedida
	ld (ix+00dh),a		;43b1   ; pose nueva
	rrca			;43b4   ; bits 2-4 de la pose: direccion 0-7
	rrca			;43b5
	and 007h		;43b6
	ld c,a			;43b8
	ld (0e727h),a		;43b9   ; direccion en curso
	ld a,d			;43bc   ; hay direccion?
	or e			;43bd
	push bc			;43be
	jr z,L_43CC		;43bf
	ld a,(0e721h)		;43c1   ; jugador en curso
	ld b,a			;43c4
	ld a,(0ed69h)		;43c5   ; sin bloqueo de movimiento
	and a			;43c8
	call z,bloqueo_pase		;43c9   ; poseedor: se para un instante o rodea
L_43CC:
	pop bc			;43cc
	ld (ix+015h),c		;43cd   ; direccion del jugador
	ld l,a			;43d0   ; L = bits de la pose
	ld a,d			;43d1   ; hay movimiento?
	or e			;43d2
	jr nz,L_43DA		;43d3
	ld hl,00000h		;43d5   ; parado: velocidad cero
	jr L_43F2		;43d8
L_43DA:
	bit 0,l		;43da   ; bit 0: velocidad con balon o sin el
	jr nz,L_43E9		;43dc
	ld l,(ix+010h)		;43de   ; velocidad +0x10/+0x11
	ld h,(ix+011h)		;43e1   ; velocidad sin balon (+0x10/+0x11)
	call ajusta_velocidad		;43e4   ; menos la fatiga
	jr L_43F2		;43e7
L_43E9:
	ld l,(ix+012h)		;43e9   ; velocidad +0x12/+0x13
	ld h,(ix+013h)		;43ec   ; velocidad con balon (+0x12/+0x13)
	call ajusta_velocidad		;43ef   ; menos la fatiga
L_43F2:
	push hl			;43f2
	ld a,d			;43f3   ; signo de la direccion Y
	and a			;43f4
	call z,cero_hl		;43f5   ; D = 0: sin velocidad Y
	call m,niega_hl		;43f8   ; D negativo: velocidad negada
	ld (ix+004h),l		;43fb   ; velocidad Y
	ld (ix+005h),h		;43fe   ; (byte alto)
	pop hl			;4401
	ld a,e			;4402   ; signo de la direccion X
	and a			;4403
	call z,cero_hl		;4404   ; E = 0: sin velocidad X
	call m,niega_hl		;4407   ; X hacia atras
	ld (ix+006h),l		;440a   ; velocidad X
	ld (ix+007h),h		;440d   ; (byte alto)
	ret			;4410
cero_hl:		; HL = 0
	ld hl,00000h		;4411
	ret			;4414
niega_hl:		; HL = -HL
	ld a,h			;4415   ; complemento a dos de HL
	cpl			;4416
	ld h,a			;4417
	ld a,l			;4418
	cpl			;4419
	ld l,a			;441a
	inc hl			;441b
	ret			;441c
niega_hl_huerfano:		; Huerfano: negaria H y L por separado (no es -HL)
	ld a,h			;441d   ; niega cada byte (no es -HL)
	neg		;441e
	ld h,a			;4420
	ld a,l			;4421
	neg		;4422
	ld l,a			;4424
	ret			;4425
ajusta_velocidad:		; Resta a la velocidad HL un valor del roster (campo 0x20) del jugador +0x1F en el equipo con el balon
	push de			;4426
	push hl			;4427
	ld a,(0e83ch)		;4428   ; equipo con el balon en el bit 7
	rrca			;442b
	or (ix+01fh)		;442c   ; jugador del roster
	ld (0efcdh),a		;442f   ; equipo para 0x7E61
	ld c,020h		;4432   ; campo 0x20 del roster
	call campo_equipo		;4434   ; cuenta 0x20: cansancio del jugador
	inc hl			;4437
	ld l,(hl)			;4438   ; byte alto del cansancio
	ld h,000h		;4439
	ld d,008h		;443b
	call divide8		;443d   ; cansancio / 8
	ld h,000h		;4440
	call niega_hl		;4442   ; se resta
	pop de			;4445
	add hl,de			;4446   ; velocidad menos el cansancio
	pop de			;4447
	ret			;4448
bloqueo_pase:		; SUPOSICION: el poseedor se queda parado un cuadro de cada ocho; si un rival esta delante cambia de direccion
	ld a,(0e6cfh)		;4449   ; poseedor
	and 007h		;444c
	cp b			;444e   ; es el jugador en curso?
	jr nz,L_445D		;444f
	ld a,(0e6d7h)		;4451   ; cuenta de cuadros del partido
	and 007h		;4454   ; uno de cada ocho cuadros
	jr nz,L_445D		;4456
	ld de,00000h		;4458   ; se para ese cuadro
	and a			;445b
	ret			;445c
L_445D:
	push de			;445d
	call rival_delante		;445e   ; rival cerca en la direccion de avance?
	pop de			;4461
	ret nc			;4462
	ld a,(0e727h)		;4463   ; direccion en curso
	push af			;4466
	call maquina_roba		;4467   ; la maquina intenta robar
	push bc			;446a
	push hl			;446b
	ld b,002h		;446c   ; gira dos pasos a un lado
	ld hl,0e71ah		;446e   ; bit 7 de la cuenta: gira a un lado o al otro
	bit 7,(hl)		;4471   ; bit 7 de la cuenta de cuadros
	jr z,L_4477		;4473
	ld b,0feh		;4475   ; o dos al otro
L_4477:
	add a,b			;4477
	and 007h		;4478   ; direccion nueva
	pop hl			;447a
	pop bc			;447b
	call vector_direccion		;447c   ; SUPOSICION: direccion corregida en DE
	pop af			;447f
	ret			;4480
lee_mando:		; Jugador controlado por un humano: lee su mando segun 0xF012 y guarda la entrada del equipo
	ld a,(0ed6ch)		;4481   ; SUPOSICION: mandos bloqueados durante la falta
	and a			;4484   ; mandos bloqueados: lo lleva la maquina
	jp nz,maquina		;4485
	call controlado		;4488   ; poseedor del equipo con el balon
	ld b,a			;448b   ; controlado del equipo con el balon
	ld a,(0e721h)		;448c
	cp b			;448f   ; el jugador en curso?
	jr nz,L_44A8		;4490
	ld a,(0e6cfh)		;4492   ; pase en vuelo?
	bit 6,a		;4495
	jr z,L_44A1		;4497
	ld a,(0e850h)		;4499   ; formacion en curso
	cp 03fh		;449c
	jp nz,maquina		;449e   ; con formacion en curso, la maquina
L_44A1:
	ld a,(0ed5fh)		;44a1   ; reboteador del ataque
	and a			;44a4
	jp p,maquina		;44a5   ; va al rebote: la maquina
L_44A8:
	ex af,af'			;44a8   ; A = equipo
	and a			;44a9
	push af			;44aa
	call lee_mando_lado		;44ab   ; lee el mando del equipo A'
	ld b,a			;44ae   ; B = botones
	ld a,c			;44af   ; C = direccion (0x3F ninguna)
	and 03fh		;44b0   ; direccion 0x3F = ninguna
	or b			;44b2
	ld c,a			;44b3
	pop af			;44b4
	jr nz,L_44C3		;44b5   ; equipo derecho
	ld a,b			;44b7
	ld (0e6d3h),a		;44b8   ; entrada del equipo izquierdo
	exx			;44bb
	ld hl,(0e6dch)		;44bc   ; registro del controlado del otro equipo
	exx			;44bf
	ex af,af'			;44c0
	jr L_44CD		;44c1
L_44C3:
	ld a,b			;44c3
	ld (0e6d5h),a		;44c4   ; entrada del equipo derecho
	exx			;44c7
	ld hl,(0e6d9h)		;44c8   ; registro del controlado del otro equipo
	exx			;44cb
	ex af,af'			;44cc
L_44CD:
	push ix		;44cd
	pop hl			;44cf
	push af			;44d0
	ld a,c			;44d1   ; direccion pedida
	and 03fh		;44d2
	cp 03fh		;44d4   ; sin direccion
	jr z,L_44EF		;44d6
	call controlado		;44d8   ; controlado del equipo con el balon
	push hl			;44db
	ld hl,0e721h		;44dc
	cp (hl)			;44df   ; es el jugador en curso?
	pop hl			;44e0
	jr nz,L_44EF		;44e1
	ld a,(0ed59h)		;44e3   ; formacion elegida
	and a			;44e6
	jr z,L_44EF		;44e7   ; ninguna
	dec a			;44e9   ; pide la formacion elegida (0xED59)
	set 7,a		;44ea
	ld (0e850h),a		;44ec   ; formacion pedida
L_44EF:
	pop af			;44ef
	ret			;44f0
maquina_roba:		; Defensor de la maquina: a veces intenta robar o taponar al poseedor si lo tiene delante
	push af			;44f1
	push de			;44f2
	ld a,(0e721h)		;44f3   ; jugador en curso
	ld b,a			;44f6
	ld a,(0e6d8h)		;44f7   ; es el controlado izquierdo?
	cp b			;44fa
	jr z,L_4503		;44fb
	ld a,(0e6dbh)		;44fd   ; es el controlado derecho?
	cp b			;4500
	jr nz,L_453B		;4501   ; no es controlado: nada
L_4503:
	push hl			;4503
	ld a,b			;4504   ; equipo del jugador
	ld hl,0efd6h		;4505   ; modos de los equipos
	cp 003h		;4508
	jr c,L_450D		;450a
	inc hl			;450c
L_450D:
	ld a,(hl)			;450d   ; modo del equipo
	pop hl			;450e
	cp 002h		;450f   ; modo 2: no roba
	jr z,L_453B		;4511   ; modo 2: la maquina ya lo hace
	call hay_sitio_para_tirar		;4513   ; SUPOSICION: rival al alcance
	jr nc,L_453B		;4516   ; nadie al alcance
	ld de,0000fh		;4518
	ld a,(hl)			;451b   ; lado del rival
	xor (ix+00fh)		;451c   ; contra el del jugador
	bit 3,a		;451f   ; bit 3: mismo sentido de ataque
	jr nz,L_453B		;4521
	call aleatorio		;4523   ; una de cada cuatro veces
	and 003h		;4526
	jr nz,L_453B		;4528
	call puede_pasar		;452a   ; tiene linea de pase?
	jr nc,L_453B		;452d
	bit 3,(ix+00fh)		;452f   ; atacante o defensor
	push af			;4533
	call nz,pasa_al_companero_5		;4534   ; SUPOSICION: tapon del defensor
	pop af			;4537
	call z,pasa_a_un_companero		;4538   ; SUPOSICION: robo del atacante
L_453B:
	pop de			;453b
	pop af			;453c
	ret			;453d
rival_delante:		; Acarreo si algun otro jugador esta a menos de 8 en la direccion de avance
	ld a,b			;453e
	call registro_jugador		;453f   ; registro del jugador B
	call xy_registro		;4542   ; su posicion
	ld c,b			;4545   ; C = jugador a no mirar
	ld b,006h		;4546   ; los seis registros
	ld hl,0e500h		;4548   ; seis registros
	xor a			;454b
L_454C:
	cp c			;454c   ; no se compara consigo mismo
	push bc			;454d
	push hl			;454e
	call nz,mira_jugador		;454f   ; esta delante?
	pop hl			;4552
	pop bc			;4553
	ret c			;4554
	push de			;4555
	ld de,00030h		;4556   ; siguiente registro
	add hl,de			;4559
	pop de			;455a
	inc a			;455b   ; siguiente jugador
	djnz L_454C		;455c
	xor a			;455e   ; ninguno delante
	ret			;455f
mira_jugador:		; Distancia y rumbo al jugador A; acarreo si esta cerca y casi en la misma direccion
	ld b,a			;4560
	push bc			;4561
	push de			;4562
	push de			;4563
	call xy_registro		;4564   ; posicion del otro
	ex de,hl			;4567
	pop de			;4568
	call distancia_rumbo		;4569   ; distancia y rumbo
	cp 008h		;456c   ; a menos de 8
	call c,misma_direccion		;456e   ; y en la misma direccion?
	pop de			;4571
	pop bc			;4572
	ld a,b			;4573
	ret			;4574
misma_direccion:		; Acarreo si las direcciones 0xE727 y 0xE728 difieren menos de 2
	ld a,(0e727h)		;4575   ; direccion del jugador
	ld b,a			;4578
	ld a,(0e728h)		;4579   ; rumbo al otro
	sub b			;457c   ; diferencia
	jp p,L_4582		;457d
	neg		;4580   ; en valor absoluto
L_4582:
	cp 002h		;4582   ; acarreo si es menor de 2
	ret			;4584
distancia_rumbo:		; A = distancia entre los puntos DE y HL, (0xE728) = rumbo de uno a otro (0-7)
	call diferencia_xy		;4585   ; diferencias Y y X
	push de			;4588
	push hl			;4589
	call distancia		;458a   ; distancia
	pop hl			;458d
	pop de			;458e
	push af			;458f
	ld b,010h		;4590
	call rumbo		;4592   ; rumbo de 0 a 7
	ld (0e728h),a		;4595   ; rumbo guardado
	pop af			;4598
	ret			;4599
diferencia_xy:		; H = diferencia de Y y L = diferencia de X entre los puntos de DE y HL
	push bc			;459a
	ld b,e			;459b
	ld c,l			;459c
	call resta_con_signo		;459d   ; diferencia de las Y
	push hl			;45a0
	ld d,b			;45a1
	ld h,c			;45a2
	call resta_con_signo		;45a3   ; diferencia de las X
	pop de			;45a6
	pop bc			;45a7
	ret			;45a8
resta_con_signo:		; HL = D - H con extension de signo
	ld a,d			;45a9
	call extiende_signo		;45aa   ; D con signo
	ex de,hl			;45ad
	ld a,d			;45ae
	call extiende_signo		;45af   ; H con signo
	ex de,hl			;45b2
	sbc hl,de		;45b3   ; D - H
	ret			;45b5
xy_registro:		; D = Y (+1) y E = X (+3) del registro HL
	inc hl			;45b6
	ld d,(hl)			;45b7   ; Y (+1)
	inc hl			;45b8
	inc hl			;45b9
	ld e,(hl)			;45ba   ; X (+3)
	ret			;45bb
xy_dos_registros:		; D,E del registro DE y H,L del registro HL
	push bc			;45bc
	inc hl			;45bd
	ld b,(hl)			;45be   ; Y del registro HL
	inc hl			;45bf
	inc hl			;45c0
	ld c,(hl)			;45c1   ; X del registro HL
	ex de,hl			;45c2
	inc hl			;45c3
	ld d,(hl)			;45c4   ; Y del registro DE
	inc hl			;45c5
	inc hl			;45c6
	ld e,(hl)			;45c7   ; X del registro DE
	ld h,b			;45c8
	ld l,c			;45c9
	pop bc			;45ca
	ret			;45cb
decide_accion:		; Accion del jugador en curso: con balon, sin balon, en el aire, pase, tiro o mate
	call servicio_vram		;45cc   ; servicio de VRAM entre jugador y jugador
	di			;45cf
	call marca_pose		;45d0   ; marca pose cambiada
	call controlado		;45d3   ; controlado del equipo con el balon
	ld b,a			;45d6
	ld a,(0e721h)		;45d7
	cp b			;45da   ; es el jugador en curso?
	jr nz,L_45E4		;45db
	ld a,(0ed77h)		;45dd   ; SUPOSICION: tiro automatico en cuenta atras
	and a			;45e0
	jp nz,tiro_automatico		;45e1   ; tiro automatico en marcha
L_45E4:
	ld a,(0e721h)		;45e4
	ld b,a			;45e7
	ld a,(0e6cfh)		;45e8   ; jugador con el balon
	and 007h		;45eb
	cp b			;45ed   ; es el poseedor?
	push af			;45ee
	call nz,sin_balon		;45ef   ; no es el: sin balon
	pop af			;45f2
	jp nz,suelta_boton		;45f3   ; sin balon: boton a cero
	call en_el_aire		;45f6   ; en el aire?
	push af			;45f9
	call nz,en_aire_con_balon		;45fa   ; en el aire con balon
	pop af			;45fd
	jp nz,suelta_boton		;45fe   ; en el aire: boton a cero
	call cuadros_boton		;4601   ; cuadros que lleva pulsado el boton
	and a			;4604
	push af			;4605
	call z,anda		;4606   ; sin pulsar: anda o corre
	pop af			;4609
	jp z,suelta_boton		;460a   ; boton a cero
	bit 7,c		;460d   ; bit 7 de C: boton soltado
	push af			;460f
	call nz,soltado_con_balon		;4610   ; soltado: pasa o salta
	pop af			;4613
	ret nz			;4614
	call cuadros_boton		;4615   ; pulsacion corta: pase
	cp 00ch		;4618   ; menos de 12 cuadros
	push af			;461a
	call c,pase		;461b   ; pulsacion corta: pase
	pop af			;461e
	jp c,suelta_boton		;461f
	ld a,(0ed66h)		;4622   ; SUPOSICION: pase forzado
	and a			;4625
	push af			;4626
	call p,pase		;4627   ; pase forzado
	pop af			;462a
	jp p,suelta_boton		;462b
	call pose_bit6		;462e   ; campo propio: no salta
	jp nz,anda		;4631   ; campo propio: corre botando
	call salta		;4634   ; pulsacion larga en campo contrario: salta
	jp suelta_boton		;4637
cuadros_boton:		; A = cuadros que el equipo del jugador en curso lleva con el boton pulsado
	ld a,(0e721h)		;463a
	cp 003h		;463d   ; equipo derecho?
	jr nc,L_4645		;463f
	ld a,(0e6d4h)		;4641   ; cuadros del izquierdo
	ret			;4644
L_4645:
	ld a,(0e6d6h)		;4645   ; cuadros del derecho
	ret			;4648
pon_cuadros_boton:		; Guarda A como cuadros de boton del equipo del jugador en curso
	push af			;4649
	ld a,(0e721h)		;464a
	cp 003h		;464d   ; equipo derecho?
	jr nc,L_4656		;464f
	pop af			;4651
	ld (0e6d4h),a		;4652   ; cuadros del izquierdo
	ret			;4655
L_4656:
	pop af			;4656
	ld (0e6d6h),a		;4657   ; cuadros del derecho
	ret			;465a
tiro_automatico:		; SUPOSICION: cuenta atras de (0xED77) cada 10 cuadros; al acabar tira o salta solo
	ld a,(ix+026h)		;465b   ; retardo del jugador
	and a			;465e
	ld hl,0ed77h		;465f   ; pasos del tiro automatico
	jp nz,L_466A		;4662
	ld (ix+026h),00ah		;4665   ; diez cuadros entre pasos
	dec (hl)			;4669   ; un paso menos
L_466A:
	ld de,00000h		;466a   ; sin movimiento
	ld c,03fh		;466d   ; sin direccion
	ld a,(hl)			;466f
	dec a			;4670   ; paso 1: tira
	jp z,tira		;4671
	dec a			;4674   ; paso 2: salta
	jp z,tiro_al_caer		;4675
	dec a			;4678   ; paso 3: bota
	jp z,L_4A96		;4679
	ret			;467c
tiro_al_caer:		; SUPOSICION: si el balon no esta en el aire salta con el
	ld a,(0e62ch)		;467d   ; balon ya en el aire?
	and a			;4680
	jr nz,tira		;4681
	call salta		;4683   ; salta con el
	ld (ix+00ch),000h		;4686   ; SUPOSICION: pero sin despegar
	ld (ix+00ah),000h		;468a
	ld (ix+00bh),000h		;468e
	ret			;4692
tira:		; Con el balon en la mano lanza a canasta
	ld a,(0e6cfh)		;4693   ; balon en vuelo?
	bit 7,a		;4696
	jp nz,corre_al_balon		;4698   ; a por el balon
	ld a,001h		;469b   ; 1 = tiro forzado
	ld (0ed6dh),a		;469d   ; 1 = tiro forzado
	call lanza		;46a0   ; tira
	xor a			;46a3
	ld (0ed6dh),a		;46a4   ; fin del tiro forzado
	ret			;46a7
elige_receptor:		; Calcula los datos de los dos companeros del poseedor en 0xE6E3 y 0xE6E8 y marca al mejor para el pase
	call quita_marca		;46a8   ; quita la marca anterior
	ld a,(0e6e2h)		;46ab   ; eleccion de receptor bloqueada
	and a			;46ae
	ret nz			;46af
	ld a,(0e6cfh)		;46b0   ; bit 7 balon en vuelo, bit 6 pase
	and 0c7h		;46b3   ; bits del poseedor y del vuelo
	bit 7,a		;46b5   ; balon en vuelo
	ret nz			;46b7
	bit 6,a		;46b8   ; pase en vuelo
	ret nz			;46ba
	cp 007h		;46bb   ; nadie tiene el balon
	ret z			;46bd
	call registro_jugador		;46be   ; registro del poseedor
	ld (0e6d0h),hl		;46c1   ; registro del poseedor
	exx			;46c4
	ld de,0e6e3h		;46c5   ; dos fichas de 5 bytes desde 0xE6E3
	exx			;46c8
	cp 003h		;46c9   ; equipo izquierdo?
	call c,fichas_izquierda		;46cb   ; companeros del equipo izquierdo
	call nc,fichas_derecha		;46ce   ; companeros del equipo derecho
	call companeros_a_tiro		;46d1   ; mira cuales tiene a tiro
	dec c			;46d4   ; C = companeros a tiro
	inc c			;46d5
	ld a,0ffh		;46d6   ; ninguno a tiro
	jr z,L_4707		;46d8   ; ninguno
	ld a,003h		;46da   ; los dos a tiro?
	cp c			;46dc
	jr nz,L_46F1		;46dd
	ld c,000h		;46df
	ld a,(0e6e5h)		;46e1   ; el primero esta en la mitad del poseedor?
	and a			;46e4
	jr nz,L_4700		;46e5
	ld a,(0e6eah)		;46e7   ; y el segundo?
	and a			;46ea
	jr nz,L_46F1		;46eb
	ld a,h			;46ed   ; el mas alineado
	cp l			;46ee
	jr c,L_4700		;46ef
L_46F1:
	bit 0,c		;46f1   ; primero a tiro: se queda
	jr nz,L_4700		;46f3
	ld hl,0e6e8h		;46f5   ; el segundo pasa a ser el elegido
	ld de,0e6e3h		;46f8   ; el segundo pasa a la primera ficha
	ld bc,00005h		;46fb
	ldir		;46fe
L_4700:
	ld hl,0e6e3h		;4700   ; receptor
	ld a,(hl)			;4703
	call marca_jugador		;4704   ; parpadea el receptor
L_4707:
	cp 0ffh		;4707   ; ninguno
	ret nz			;4709
	ld (0e6e3h),a		;470a   ; sin receptor
	ret			;470d
companeros_a_tiro:		; Bits 0 y 1 de C: companero 1 o 2 dentro de 0x40 de diferencia con la direccion del poseedor
	call rumbos_companeros		;470e
	exx			;4711
	ld de,(0e6d0h)		;4712   ; registro del poseedor
	ld hl,00015h		;4716
	add hl,de			;4719
	ld a,(hl)			;471a   ; direccion del poseedor (+0x15)
	exx			;471b
	add a,a			;471c   ; por 32: angulo de 0 a 255
	add a,a			;471d
	add a,a			;471e
	add a,a			;471f
	add a,a			;4720
	ld c,a			;4721
	cp h			;4722   ; diferencia con el companero 1
	jr nc,L_4728		;4723
	ld b,a			;4725
	ld a,h			;4726
	ld h,b			;4727
L_4728:
	sub h			;4728
	jp p,L_472E		;4729
	neg		;472c   ; en valor absoluto
L_472E:
	ld h,a			;472e
	ld a,c			;472f
	cp l			;4730   ; diferencia con el companero 2
	jr nc,L_4736		;4731
	ld b,a			;4733
	ld a,l			;4734
	ld l,b			;4735
L_4736:
	sub l			;4736
	jp p,L_473C		;4737
	neg		;473a   ; en valor absoluto
L_473C:
	ld l,a			;473c
	ld c,000h		;473d
	exx			;473f
	ld hl,0e6e4h		;4740   ; mitad del 1
	ld a,(hl)			;4743
	inc hl			;4744
	inc hl			;4745
	inc hl			;4746
	inc hl			;4747
	inc hl			;4748
	exx			;4749
	and a			;474a
	jp m,L_4755		;474b   ; otra mitad o centro: no
	ld a,040h		;474e   ; a menos de 0x40
	cp h			;4750
	jr c,L_4755		;4751
	set 0,c		;4753   ; bit 0: companero 1 a tiro
L_4755:
	exx			;4755
	ld a,(hl)			;4756   ; mitad del 2
	exx			;4757
	and a			;4758
	ret m			;4759
	ld a,040h		;475a   ; a menos de 0x40
	cp l			;475c
	ret c			;475d
	set 1,c		;475e   ; bit 1: companero 2 a tiro
	ret			;4760
rumbos_companeros:		; D, E = jugadores de las dos fichas; H, L = sus rumbos
	ld bc,0e6e3h		;4761   ; primera ficha
	ld a,(bc)			;4764
	ld d,a			;4765   ; D = jugador 1
	inc bc			;4766
	inc bc			;4767
	inc bc			;4768
	inc bc			;4769
	ld a,(bc)			;476a
	ld h,a			;476b   ; H = angulo 1
	inc bc			;476c
	ld a,(bc)			;476d
	ld e,a			;476e   ; E = jugador 2
	inc bc			;476f
	inc bc			;4770
	inc bc			;4771
	inc bc			;4772
	ld a,(bc)			;4773
	ld l,a			;4774   ; L = angulo 2
	ret			;4775
fichas_izquierda:		; Ficha de los dos companeros del jugador A (equipo 0-2)
	push af			;4776
	ld c,a			;4777   ; C = poseedor
	ld a,000h		;4778
	cp c			;477a
	ld a,c			;477b
	ld c,000h		;477c   ; companero 0
	call nz,ficha_companero		;477e
	ld c,001h		;4781   ; companero 1
	cp c			;4783
	call nz,ficha_companero		;4784
	ld c,002h		;4787   ; companero 2
	cp c			;4789
	call nz,ficha_companero		;478a
	pop af			;478d
	ret			;478e
fichas_derecha:		; Ficha de los dos companeros del jugador A (equipo 3-5)
	push af			;478f
	ld c,003h		;4790   ; companero 3
	cp c			;4792
	call nz,ficha_companero		;4793
	ld c,004h		;4796   ; companero 4
	cp c			;4798
	call nz,ficha_companero		;4799
	ld c,005h		;479c   ; companero 5
	cp c			;479e
	call nz,ficha_companero		;479f
	pop af			;47a2
	ret			;47a3
ficha_companero:		; Escribe en DE' la ficha del jugador C: numero, misma mitad (0) o no (0xFF), 0, rumbo de 0 a 7 y angulo fino menos 16
	ld b,a			;47a4
	push bc			;47a5
	ld a,c			;47a6
	exx			;47a7
	ld (de),a			;47a8   ; numero de jugador
	inc de			;47a9
	exx			;47aa
	call registro_jugador		;47ab   ; registro del companero
	ld de,(0e6d0h)		;47ae   ; poseedor
	call xy_dos_registros		;47b2   ; posiciones
	call misma_mitad		;47b5   ; misma mitad o no
	exx			;47b8
	ld (de),a			;47b9
	inc de			;47ba
	exx			;47bb
	push de			;47bc
	push hl			;47bd
	call cero		;47be   ; campo vacio
	pop hl			;47c1
	pop de			;47c2
	exx			;47c3
	ld (de),a			;47c4
	inc de			;47c5
	exx			;47c6
	call diferencia_xy		;47c7   ; rumbo desde el poseedor
	ld b,010h		;47ca
	call rumbo		;47cc   ; rumbo de 0 a 7
	exx			;47cf
	ld (de),a			;47d0
	inc de			;47d1
	ld a,(0e6c2h)		;47d2   ; angulo fino menos 16
	add a,0f0h		;47d5
	ld (de),a			;47d7
	inc de			;47d8
	exx			;47d9
	pop bc			;47da
	ld a,b			;47db
	ret			;47dc
ficha_suelta:		; SUPOSICION: ficha de un solo jugador en 0xE6E3
	ld c,a			;47dd
	call registro_jugador		;47de
	ld de,(0e6d0h)		;47e1   ; desde el poseedor
	exx			;47e5
	ld de,0e6e3h		;47e6   ; en la primera ficha
	exx			;47e9
	jp ficha_companero		;47ea
misma_mitad:		; 0 si el companero (L) esta en la misma mitad que el poseedor (E); 0xFF si esta en el centro (menos de 3) o en la otra
	ld a,l			;47ed   ; X del companero
	and a			;47ee
	jp p,L_47F4		;47ef
	neg		;47f2
L_47F4:
	cp 003h		;47f4   ; menos de 3: en el centro
	ld a,0ffh		;47f6
	ret c			;47f8
	ld a,l			;47f9   ; en la misma mitad que el poseedor?
	xor e			;47fa
	and a			;47fb
	ld a,000h		;47fc   ; 0: misma mitad
	ret p			;47fe
	dec a			;47ff   ; 0xFF: la otra mitad
	ret			;4800
cero:		; A = 0
	xor a			;4801
	ret			;4802
pase:		; Lanza el pase al receptor marcado: el receptor se gira hacia el poseedor y se para
	ld a,(0e6e3h)		;4803   ; receptor elegido
	cp 0ffh		;4806   ; 0xFF: sin receptor
	jp z,anda		;4808   ; nadie: no hay pase
	ld b,a			;480b
	ld a,(0e721h)		;480c   ; jugador en curso
	cp b			;480f   ; el receptor no puede ser el mismo
	jp z,anda		;4810
	ld a,(0ed6dh)		;4813   ; SUPOSICION: tiro forzado en curso
	and a			;4816
	jp nz,anda		;4817   ; tiro forzado: no pasa
	ld a,(0e6cfh)		;481a   ; estado del balon
	or 047h		;481d   ; bit 6 = pase en vuelo, sin poseedor
	ld (0e6cfh),a		;481f
	call rumbo_receptor		;4822   ; C = rumbo al receptor
	ld a,c			;4825
	or 063h		;4826   ; pose de pase con su direccion
	push af			;4828
	push de			;4829
	ld a,(0e6e3h)		;482a   ; receptor
	call registro_jugador		;482d
	push hl			;4830
	pop iy		;4831
	ld a,(0e6e6h)		;4833   ; mira al que le pasa
	add a,004h		;4836   ; rumbo opuesto: mira al que pasa
	and 007h		;4838
	ld (iy+015h),a		;483a   ; direccion del receptor
	add a,a			;483d   ; a los bits 2-4 de la pose
	add a,a			;483e
	or 063h		;483f   ; pose de recibir
	ld (iy+00dh),a		;4841   ; pose de recibir
	xor a			;4844   ; sin destino ni velocidad
	ld (iy+020h),a		;4845   ; sin destino Y
	ld (iy+021h),a		;4848   ; sin destino X
	ld (iy+004h),a		;484b   ; sin velocidad Y
	ld (iy+005h),a		;484e
	ld (iy+006h),a		;4851   ; sin velocidad X
	ld (iy+007h),a		;4854
	call lanza_pase		;4857   ; trayectoria del balon
	pop de			;485a
	pop af			;485b
	ex af,af'			;485c   ; pose del que pasa a A'
	ret			;485d
rumbo_receptor:		; C = rumbo al receptor por 4 (campo de direccion de la pose)
	ld a,(0e6e6h)		;485e   ; rumbo al receptor (ficha +3)
	add a,a			;4861
	add a,a			;4862
	ld c,a			;4863
	ret			;4864
suelta_boton:		; Si el jugador en curso es el controlado de su equipo, pone a cero su cuenta de boton
	push af			;4865
	ld a,(0e721h)		;4866   ; jugador en curso
	ld b,a			;4869
	cp 003h		;486a   ; equipo derecho?
	jr nc,L_4873		;486c
	ld a,(0e6d8h)		;486e   ; controlado izquierdo
	jr L_4876		;4871
L_4873:
	ld a,(0e6dbh)		;4873   ; controlado derecho
L_4876:
	cp b			;4876   ; es el?
	jr nz,L_487D		;4877
	xor a			;4879
	call pon_cuadros_boton		;487a   ; cuadros de boton a cero
L_487D:
	pop af			;487d
	ret			;487e
sin_balon:		; Jugador sin balon: en el aire, recoge, defiende o corre
	call en_el_aire		;487f   ; en el aire?
	and a			;4882
	jr z,L_48A0		;4883   ; en el suelo
	ld a,(0e721h)		;4885   ; jugador en curso
	ld hl,0e6dfh		;4888   ; SUPOSICION: el que tiro
	cp (hl)			;488b
	jp z,sigue_en_aire		;488c   ; el que tiro: sigue en el aire
	ld hl,0e6e0h		;488f   ; SUPOSICION: los que saltaron por el balon
	cp (hl)			;4892
	jp z,pose_en_aire		;4893   ; saltador del izquierdo: pose del aire
	ld hl,0e6e1h		;4896   ; saltador del derecho
	cp (hl)			;4899
	jp z,pose_en_aire		;489a
	jp sigue_en_aire		;489d   ; los demas siguen en el aire
L_48A0:
	ld a,(0e6cfh)		;48a0   ; alguien tiene el balon?
	cp 007h		;48a3   ; 7 o mas: nadie con el balon
	jr c,L_48C0		;48a5   ; hay poseedor
	bit 7,c		;48a7   ; balon suelto y sin boton: corre
	jr z,corre_al_balon		;48a9   ; boton sin soltar: corre
	cp 007h		;48ab   ; 7: balon suelto
	jr z,L_48B6		;48ad
	exx			;48af
	call en_el_aire		;48b0   ; en el aire?
	exx			;48b3
	jr z,corre_al_balon		;48b4
L_48B6:
	call direccion_pose		;48b6   ; salta a por el balon
	ld a,c			;48b9   ; C = direccion
	or 042h		;48ba   ; pose de salto a por el balon
	ex af,af'			;48bc
	jp salto		;48bd   ; despega
L_48C0:
	bit 3,(ix+00fh)		;48c0   ; equipo con el balon: es atacante?
	bit 7,c		;48c4   ; boton soltado?
	jp nz,robo		;48c6   ; boton soltado: roba o tapona
	ld a,(0e6e3h)		;48c9   ; es el receptor del pase?
	ld b,a			;48cc
	ld a,(0e721h)		;48cd   ; es el jugador en curso?
	cp b			;48d0
	jr nz,corre_al_balon		;48d1
	ld a,(ix+00dh)		;48d3   ; pose actual
	and 0e3h		;48d6   ; accion y fotograma
	cp 063h		;48d8   ; sigue en pose de recibir
	jr nz,corre_al_balon		;48da
	push af			;48dc
	call direccion_pose		;48dd   ; sigue mirando igual
	pop af			;48e0
	or c			;48e1
	ex af,af'			;48e2
	ret			;48e3
corre_al_balon:		; Sin direccion pedida se gira hacia el balon; con direccion corre
	ld a,d			;48e4   ; hay direccion?
	or e			;48e5
	jp nz,corre		;48e6   ; si: corre
	push de			;48e9
	push ix		;48ea
	pop de			;48ec
	ld hl,0e620h		;48ed   ; registro del balon
	call xy_dos_registros		;48f0   ; posiciones del jugador y del balon
	call diferencia_xy		;48f3   ; diferencias
	ld b,010h		;48f6
	call rumbo		;48f8   ; rumbo al balon
	ld c,a			;48fb
	call direccion_pose		;48fc   ; C = rumbo por 4
	pop de			;48ff
	bit 3,(ix+00fh)		;4900   ; bit 3: atacante
	jr nz,L_490A		;4904   ; defensor: pose 0x80
	or 080h		;4906
	ex af,af'			;4908
	ret			;4909
L_490A:
	or 061h		;490a   ; atacante: pose 0x61
	ex af,af'			;490c
	ret			;490d
robo:		; SUPOSICION: defensor que pulsa el boton intenta robar; la suerte depende de +0x1D
	ld a,(0e6edh)		;490e   ; intento de robo pedido?
	and a			;4911
	jr z,L_4926		;4912
	xor a			;4914   ; atendido
	ld (0e6edh),a		;4915
	call hay_sitio_para_tirar		;4918   ; al alcance del poseedor?
	jr nc,L_4926		;491b
	call aleatorio		;491d   ; sale bien si el azar es menor que +0x1D
	cp (ix+01dh)		;4920   ; el azar contra la habilidad (+0x1D)
	call c,roba_balon		;4923
L_4926:
	ld c,03fh		;4926   ; sin direccion
	call direccion_pose		;4928   ; mantiene la direccion
	or 081h		;492b   ; pose de robo, sin moverse
	ld de,00000h		;492d   ; sin movimiento
	ex af,af'			;4930
	ret			;4931
roba_balon:		; SUPOSICION: el balon cambia de manos: pitido, nuevo poseedor y relojes de 10 y 30 segundos a cero
	ld a,(0e6f1h)		;4932   ; no durante el salto entre dos
	and a			;4935   ; salto entre dos en marcha
	ret nz			;4936
	ld a,(0e831h)		;4937   ; SUPOSICION: no con la ventana en el centro
	cp 080h		;493a   ; ventana en el centro: no
	ret z			;493c
	ld a,002h		;493d   ; pieza 2: robo
	call arranca_sonido		;493f
	call suelta_boton		;4942   ; boton a cero
	ld a,(0e721h)		;4945   ; el ladron
	push af			;4948
	push af			;4949
	call da_balon		;494a   ; nuevo poseedor
	call balon_quieto		;494d   ; balon parado
	ld (0e635h),a		;4950   ; SUPOSICION: canasta a la que ataca
	pop af			;4953
	call cuenta_10s		;4954   ; 10 segundos si esta en su campo
	pop af			;4957
	call fin_cuenta_10s		;4958   ; desactivada si esta en el contrario
	jp cuenta_30s		;495b   ; y 30 segundos
pose_en_aire:		; Pose 0x43 en el aire
	call direccion_actual		;495e
	or 043h		;4961   ; pose 0x43: en el aire
	ld de,00000h		;4963   ; sin movimiento
	ex af,af'			;4966
	ret			;4967
pose_en_aire_huerfano:		; Huerfano: pose del aire conservando la accion de +0x0D
	call direccion_actual		;4968
	call pose_actual		;496b
	and 0e3h		;496e   ; accion y fotograma de la pose
	or c			;4970
	ex af,af'			;4971
	ret			;4972
en_el_aire:		; NZ si el jugador IX esta en el aire (+0x0C gravedad)
	ld a,(ix+00ch)		;4973   ; gravedad (+0x0C)
	and a			;4976
	ret			;4977
en_aire_con_balon:		; En el aire con el balon: tira, pasa o machaca al soltar el boton
	push bc			;4978
	call pose_bit6		;4979   ; campo propio?
	pop bc			;497c
	call nz,suelta_boton		;497d   ; si: boton a cero
	jr nz,sigue_en_aire		;4980
	ld a,(0e6f9h)		;4982   ; 1 = puede machacar
	cp 001h		;4985   ; 1: mate
	jr z,mate		;4987
	bit 7,c		;4989   ; boton aun pulsado
	jr z,lanza		;498b
sigue_en_aire:		; Balon en lo alto del salto
	push de			;498d
	push hl			;498e
	ld hl,(0e6d0h)		;498f   ; registro del poseedor
	ld a,h			;4992
	or l			;4993
	jr z,L_499F		;4994   ; nadie
	ld de,00009h		;4996   ; altura del jugador
	add hl,de			;4999   ; altura (+9)
	ld a,(hl)			;499a
	and a			;499b
	call nz,balon_a_la_altura		;499c   ; balon a su altura
L_499F:
	pop hl			;499f
	pop de			;49a0
	call direccion_giro		;49a1   ; C = direccion
	ld a,(0e62ch)		;49a4   ; balon libre?
	and a			;49a7
	push de			;49a8
	ld de,04c0dh		;49a9   ; posiciones del balon en la mano (0x4C0D)
	call z,balon_en_mano		;49ac   ; en la mano: con el jugador
	pop de			;49af
	call pose_actual		;49b0   ; pose actual
	and 0e3h		;49b3   ; accion y fotograma
	ld de,00000h		;49b5   ; sin movimiento
	or c			;49b8
	ex af,af'			;49b9
	ret			;49ba
balon_a_la_altura:		; SUPOSICION: altura del balon segun la del jugador
	ld a,(0e62ch)		;49bb   ; balon libre: no se toca
	and a			;49be
	ret nz			;49bf
	ld a,0e3h		;49c0   ; 0xE3 mas la altura
	add a,(hl)			;49c2
	ld (0e62dh),a		;49c3   ; altura del balon
	ret			;49c6
lanza:		; Suelta el balon a canasta: trayectoria y balon en vuelo
	call direccion_giro		;49c7   ; C = direccion
	ld a,c			;49ca
	or 041h		;49cb   ; pose de tiro
	push af			;49cd
	call tiro		;49ce   ; SUPOSICION: calcula el tiro
	call al_rebote		;49d1   ; los mas cercanos van al rebote
	ld a,(0e721h)		;49d4
	ld (0e6dfh),a		;49d7   ; jugador que tiro
	ld a,(0e6cfh)		;49da   ; estado del balon
	or 087h		;49dd   ; balon en vuelo, sin poseedor
	ld (0e6cfh),a		;49df
	ld de,00000h		;49e2   ; sin movimiento
	pop af			;49e5
	ex af,af'			;49e6
	ret			;49e7
mate:		; Machaque: balon directo a la canasta, red animada y tiro anotado
	ld a,(ix+00bh)		;49e8   ; todavia subiendo
	and a			;49eb   ; velocidad alta 0: ya no sube
	jp nz,sigue_en_aire		;49ec
	ld a,(0e6cfh)		;49ef   ; poseedor
	and 007h		;49f2
	cp 007h		;49f4   ; sin balon no hay mate
	jp z,sigue_en_aire		;49f6
	call direccion_giro		;49f9   ; C = direccion
	ld a,c			;49fc
	or 041h		;49fd   ; pose de mate
	push af			;49ff
	ld a,(0e721h)		;4a00   ; el que machaca
	ld (0e6dfh),a		;4a03   ; jugador que tiro
	ld (0e6fch),a		;4a06   ; SUPOSICION: autor del mate
	ld a,001h		;4a09   ; 1 = canasta pendiente
	ld (0ed79h),a		;4a0b   ; SUPOSICION: canasta pendiente de anotar
	ld a,087h		;4a0e   ; balon en vuelo
	ld (0e6cfh),a		;4a10   ; balon en vuelo, sin poseedor
	call cuenta_tiro		;4a13
	ld a,001h		;4a16   ; balon camino de la canasta
	ld (0ed63h),a		;4a18   ; canasta hecha
	ld a,00fh		;4a1b   ; gravedad del balon
	ld (0e62ch),a		;4a1d
	ld hl,0e6c3h		;4a20   ; posicion de la canasta
	call xy_registro		;4a23   ; canasta
	ld a,d			;4a26
	ld (0e621h),a		;4a27   ; balon en la Y de la canasta
	ld a,e			;4a2a
	ld (0e623h),a		;4a2b   ; y en su X
	xor a			;4a2e   ; A = 0
	ld (0e62dh),a		;4a2f   ; balon fuera de la mano
	ld (0e620h),a		;4a32   ; fracciones a cero
	ld (0e622h),a		;4a35
	ld (0e6f6h),a		;4a38   ; sin pasos
	dec a			;4a3b
	ld (0ed62h),a		;4a3c   ; sin reboteador
	ld hl,00000h		;4a3f
	ld (0e626h),hl		;4a42   ; sin velocidad
	ld (0e624h),hl		;4a45
	ld hl,0ff9ch		;4a48   ; SUPOSICION: velocidad del balon -100
	ld (0e62ah),hl		;4a4b
	ld a,004h		;4a4e   ; cuatro botes al caer
	ld (0e6f7h),a		;4a50
	ld a,0cch		;4a53   ; altura del aro
	ld (0e629h),a		;4a55   ; Z del balon a la altura del aro
	neg		;4a58
	ld (0e6f8h),a		;4a5a   ; SUPOSICION: altura del aro en positivo
	ld a,00ah		;4a5d   ; 10 cuadros por paso de la red
	ld (0e634h),a		;4a5f
	xor a			;4a62
	ld (0e633h),a		;4a63   ; arranca la animacion de la red
	ld hl,0e6d3h		;4a66   ; boton 1 del izquierdo soltado
	res 7,(hl)		;4a69   ; botones soltados
	ld hl,0e6d5h		;4a6b   ; boton 1 del derecho
	res 7,(hl)		;4a6e
	ld de,00000h		;4a70   ; sin movimiento
	pop af			;4a73
	ex af,af'			;4a74
	ret			;4a75
pose_actual:		; A = pose (+0x0D) del jugador IX
	ld a,(ix+00dh)		;4a76
	ret			;4a79
soltado_con_balon:		; Boton soltado con el balon: en campo propio pasa, en el contrario pasa o salta
	push bc			;4a7a
	call pose_bit6		;4a7b   ; campo propio?
	pop bc			;4a7e
	jr z,bote		;4a7f   ; campo contrario: bota o salta
	call suelta_boton		;4a81   ; boton a cero
	ld a,(0e6e3h)		;4a84   ; hay receptor?
	inc a			;4a87
	jp z,anda		;4a88   ; no: sigue botando
	jp pase		;4a8b   ; pasa
bote:		; SUPOSICION: pulsacion corta en campo contrario: bota el balon en la mano
	call cuadros_boton		;4a8e   ; cuadros pulsado
	cp 00ch		;4a91   ; 12 o mas: salta
	jp nc,salta		;4a93
L_4A96:
	push de			;4a96
	call direccion_pose		;4a97   ; C = direccion
	ld de,04c0dh		;4a9a   ; posiciones de la mano
	call balon_en_mano		;4a9d
	pop de			;4aa0
	call balon_bajo		;4aa1   ; balon bajo
	ld a,c			;4aa4
	or 062h		;4aa5   ; pose de bote parado
	ex af,af'			;4aa7
	ret			;4aa8
balon_bajo:		; Altura del balon en la mano 0xF0
	ld a,0f0h		;4aa9
	ld (0e62dh),a		;4aab
	ret			;4aae
salta:		; Salto del poseedor con el balon
	ld a,(0ed6dh)		;4aaf   ; tiro forzado?
	and a			;4ab2
	jp nz,lanza		;4ab3   ; si: tira
	push de			;4ab6
	call direccion_pose		;4ab7   ; C = direccion
	ld de,04c0dh		;4aba   ; posiciones de la mano
	call balon_en_mano		;4abd
	pop de			;4ac0
	call balon_alto		;4ac1   ; balon alto
	ld a,c			;4ac4
	or 040h		;4ac5   ; pose de salto
	ld de,00000h		;4ac7   ; sin movimiento
	push af			;4aca
	call salto		;4acb   ; despega
	call giro_al_aro		;4ace   ; se gira al aro en el aire
	pop af			;4ad1
	ex af,af'			;4ad2
	ret			;4ad3
balon_alto:		; Altura del balon en la mano 0xE3
	ld a,0e3h		;4ad4
	ld (0e62dh),a		;4ad6
	ret			;4ad9
giro_al_aro:		; En el aire se va girando hacia la canasta: pasos (+0x14), rumbo (+0x16) y sentido (+0x18)
	push af			;4ada
	push de			;4adb
	push ix		;4adc
	pop de			;4ade
	ld hl,0e6c3h		;4adf   ; canasta
	call xy_dos_registros		;4ae2   ; jugador y canasta
	ld b,010h		;4ae5
	call rumbo_entre		;4ae7   ; rumbo a la canasta
	ld (ix+014h),006h		;4aea   ; seis pasos de giro
	ld (ix+016h),a		;4aee   ; rumbo de destino
	ld b,a			;4af1
	ld a,(ix+015h)		;4af2   ; direccion actual
	ld (ix+017h),a		;4af5   ; como direccion de giro
	ld c,a			;4af8
	call sentido_giro		;4af9   ; sentido de giro
	ld (ix+018h),a		;4afc   ; sentido del giro
	pop de			;4aff
	pop af			;4b00
	ret			;4b01
sentido_giro:		; 1 si el rumbo B esta a menos de media vuelta a la derecha de C, si no 0xFF
	ld a,b			;4b02   ; destino menos actual
	sub c			;4b03
	and 007h		;4b04
	cp 004h		;4b06   ; menos de media vuelta
	jr nc,L_4B0D		;4b08
	ld a,001h		;4b0a   ; 1: a la derecha
	ret			;4b0c
L_4B0D:
	ld a,0ffh		;4b0d   ; 0xFF: a la izquierda
	ret			;4b0f
anda:		; Poseedor sin pulsar: bota el balon parado o corriendo
	ld a,(0e6f2h)		;4b10   ; bote forzado?
	and a			;4b13
	jp nz,L_4A96		;4b14   ; SUPOSICION: forzado a botar
	ld a,(0e832h)		;4b17   ; balon oculto: corre sin el
	and a			;4b1a
	jp nz,corre_al_balon		;4b1b
	xor a			;4b1e
	ld (0e62ch),a		;4b1f   ; balon en la mano
	ld (0e62dh),a		;4b22   ; balon a ras de la mano
	ld a,d			;4b25   ; hay direccion?
	or e			;4b26
	jp nz,corre_botando		;4b27   ; hay direccion: corre
	call direccion_pose		;4b2a   ; C = direccion
	push de			;4b2d
	ld de,04bfdh		;4b2e   ; posiciones del bote (0x4BFD)
	call balon_en_mano		;4b31   ; balon junto al jugador
	call paso_bote		;4b34   ; fotograma del bote
	pop de			;4b37
	call sonido_bote		;4b38   ; suena el bote
	ld a,c			;4b3b
	or 060h		;4b3c   ; pose parado botando
	ex af,af'			;4b3e
	ret			;4b3f
paso_bote:		; Cada 4 cuadros cambia el fotograma del bote
	push hl			;4b40
	ld hl,0e71ah		;4b41   ; cuenta de cuadros
	bit 2,(hl)		;4b44   ; bit 2
	pop hl			;4b46
	ret z			;4b47
	inc c			;4b48   ; fotograma siguiente
	ret			;4b49
direccion_giro:		; C = rumbo del giro (+0x17) por 4, o el de C
	ld a,(ix+017h)		;4b4a   ; direccion de giro
	and a			;4b4d
	jp m,direccion_pose		;4b4e   ; sin giro: la de C
	add a,a			;4b51   ; por 4
	add a,a			;4b52
	ld c,a			;4b53
	ret			;4b54
direccion_pose:		; C = direccion por 4 (bits 2-4 de la pose)
	ld a,c			;4b55   ; direccion por 4
	add a,a			;4b56
	add a,a			;4b57
	and 03ch		;4b58   ; bits 2-5
	bit 5,a		;4b5a   ; 0x3F: sin direccion pedida
	call nz,direccion_actual		;4b5c   ; se queda la actual
	ld c,a			;4b5f
	ret			;4b60
direccion_actual:		; A = bits de direccion de la pose actual
	call pose_actual		;4b61
	and 01ch		;4b64   ; bits 2-4: direccion
	ret			;4b66
marca_pose:		; Pose cambiada (bit 7 de +0x0F)
	set 7,(ix+00fh)		;4b67
	ret			;4b6b
sonido_bote:		; Bote en el suelo: pieza 9 y balon a ras de suelo; en lo alto 0xF8
	bit 0,c		;4b6c   ; bit 0: fotograma arriba o abajo
	jr z,L_4B74		;4b6e
	ld a,0f8h		;4b70   ; balon arriba
	jr L_4B7B		;4b72
L_4B74:
	ld a,009h		;4b74   ; pieza 9: el balon toca el suelo
	call arranca_sonido		;4b76   ; pieza 9: bote
	ld a,000h		;4b79   ; balon abajo
L_4B7B:
	ld (0e62dh),a		;4b7b   ; altura del balon en la mano
	ret			;4b7e
corre_botando:		; Corre botando el balon
	ld a,(0e832h)		;4b7f   ; balon oculto?
	and a			;4b82
	jp nz,corre		;4b83
	call direccion_pose		;4b86   ; C = direccion
	push de			;4b89
	ld de,04bfdh		;4b8a   ; posiciones del bote al correr
	call balon_en_mano		;4b8d   ; balon junto al jugador
	call fotograma_carrera		;4b90   ; fotograma de la carrera
	pop de			;4b93
	call sonido_bote		;4b94   ; bote
	ld a,c			;4b97
	or 020h		;4b98   ; pose de correr
	ex af,af'			;4b9a
	ret			;4b9b
fotograma_carrera:		; Fotograma de la carrera segun la cuenta de cuadros (bits 3-4)
	ld a,(0e71ah)		;4b9c   ; cuenta de cuadros
	rrca			;4b9f
	rrca			;4ba0
	rrca			;4ba1
	and 003h		;4ba2   ; bits 3-4: fotograma 0-3
	or c			;4ba4
	ld c,a			;4ba5
	ret			;4ba6
corre:		; Corre sin balon
	call direccion_pose		;4ba7   ; C = direccion
	call fotograma_corre		;4baa   ; fotograma
	ld a,c			;4bad
	or 000h		;4bae   ; pose 0x00: correr
	ex af,af'			;4bb0
	ret			;4bb1
fotograma_corre:		; Fotograma de la carrera sin balon
	ld a,(0e71ah)		;4bb2   ; cuenta de cuadros
	rrca			;4bb5
	rrca			;4bb6
	rrca			;4bb7
	and 003h		;4bb8   ; fotograma 0-3
	or c			;4bba
	ld c,a			;4bbb
	ret			;4bbc
rumbo_entre:		; Rumbo de 0 a 7 entre los registros DE y HL
	call diferencia_xy		;4bbd   ; diferencias
rumbo:		; Rumbo de 0 a 7 de la diferencia HL; el angulo fino queda en (0xE6C2)
	call mitad_de		;4bc0   ; a la mitad
	push bc			;4bc3
	call angulo		;4bc4   ; angulo de 0 a 255
	pop bc			;4bc7
	add a,b			;4bc8   ; mas el giro B
	ld (0e6c2h),a		;4bc9   ; angulo fino
	rlca			;4bcc   ; tres bits altos
	rlca			;4bcd
	rlca			;4bce
	and 007h		;4bcf   ; rumbo de 0 a 7
	ret			;4bd1
mitad_de:		; Divide DE y HL entre 2
	ex de,hl			;4bd2
	call mitad_hl		;4bd3   ; HL / 2
	ex de,hl			;4bd6
mitad_hl:		; HL / 2 con signo
	sra h		;4bd7
	rr l		;4bd9
	ret			;4bdb
balon_en_mano:		; Pone el balon junto al jugador IX con el desplazamiento de la tabla DE segun la direccion C
	ld a,c			;4bdc   ; direccion por 2: dos bytes por entrada
	rrca			;4bdd
	ld h,000h		;4bde
	ld l,a			;4be0
	add hl,de			;4be1
	ld d,(hl)			;4be2   ; dy
	inc hl			;4be3
	ld e,(hl)			;4be4   ; dx
	exx			;4be5
	ld hl,0e620h		;4be6   ; registro del balon
	exx			;4be9
	ld a,d			;4bea
	add a,(ix+001h)		;4beb   ; Y del jugador mas desplazamiento
	ld d,a			;4bee
	exx			;4bef
	inc hl			;4bf0
	ld (hl),a			;4bf1   ; Y del balon
	inc hl			;4bf2
	exx			;4bf3
	ld a,e			;4bf4
	add a,(ix+003h)		;4bf5   ; X del jugador mas desplazamiento
	exx			;4bf8
	inc hl			;4bf9
	ld (hl),a			;4bfa   ; X del balon
	exx			;4bfb
	ret			;4bfc

; ----------------------------------------------------------------------
; DATOS pasos_a: Ocho pares (dx, dy) con signo que recorren 0x4B2E y 0x4B8A
;   0x4bfd..0x4c0d  (16 bytes)
DATA_pasos_a:
	defb 0ffh,003h	; 4bfd
	defb 0ffh,005h	; 4bff
	defb 000h,004h	; 4c01
	defb 001h,003h	; 4c03
	defb 001h,0fdh	; 4c05
	defb 001h,0fch	; 4c07
	defb 000h,0fch	; 4c09
	defb 0ffh,0fdh	; 4c0b

; ----------------------------------------------------------------------
; DATOS pasos_b: Ocho pares (dx, dy) con signo que recorren 0x49A9, 0x4A9A,
;   0x4ABA y 0x5702
;   0x4c0d..0x4c1d  (16 bytes)
DATA_pasos_b:
	defb 0ffh,001h	; 4c0d
	defb 0ffh,002h	; 4c0f
	defb 000h,003h	; 4c11
	defb 001h,001h	; 4c13
	defb 001h,0feh	; 4c15
	defb 001h,0fdh	; 4c17
	defb 000h,0fdh	; 4c19
	defb 0ffh,0ffh	; 4c1b

; ======================================================================
; CODIGO 0x4c1d..0x4dbf  (418 bytes)
; ======================================================================


salto:		; Despega al jugador IX: velocidad segun +0x1C y el roster; si va con el balon cerca del aro y alto, puede machacar
	ld a,(ix+00ch)		;4c1d   ; gravedad (+0x0C)
	and a			;4c20
	ret nz			;4c21   ; ya esta en el aire
	push de			;4c22
	push hl			;4c23
	ld (ix+00ch),00fh		;4c24   ; gravedad
	ld (ix+020h),000h		;4c28   ; sin destino
	ld (ix+021h),000h		;4c2c   ; sin destino X
	ld a,001h		;4c30   ; salto con balon (pasos si cae con el)
	ld (0e6f6h),a		;4c32   ; 1 = salto con el balon
	ld e,(ix+01ch)		;4c35   ; SUPOSICION: potencia de salto del jugador
	srl e		;4c38   ; la mitad de +0x1C
	ld d,000h		;4c3a
	ld hl,0014ah		;4c3c   ; velocidad base 0x14A
	add hl,de			;4c3f   ; base mas la mitad
	push hl			;4c40
	ld a,(0e83ch)		;4c41   ; equipo con el balon
	rrca			;4c44
	ld (0efcdh),a		;4c45   ; en el bit 7 para 0x7E61
	ld c,021h		;4c48   ; campo 0x21 del roster
	call campo_equipo		;4c4a
	ex de,hl			;4c4d
	ld l,(ix+01fh)		;4c4e   ; +0x1F: jugador en el roster
	ld h,000h		;4c51   ; jugador por 2
	add hl,hl			;4c53
	add hl,de			;4c54
	ld e,(hl)			;4c55   ; valor de la tabla del roster
	srl e		;4c56   ; entre 4
	srl e		;4c58
	ld d,000h		;4c5a
	pop hl			;4c5c
	and a			;4c5d
	sbc hl,de		;4c5e   ; se resta
	ld (ix+00ah),l		;4c60   ; velocidad vertical
	ld (ix+00bh),h		;4c63   ; (byte alto)
	ld a,(0e721h)		;4c66   ; el saltador
	call apunta_saltador		;4c69   ; apunta al saltador de su equipo
	ld a,(0e6cfh)		;4c6c   ; poseedor
	push hl			;4c6f
	ld hl,0e721h		;4c70
	cp (hl)			;4c73   ; es el que salta?
	pop hl			;4c74
	jr nz,L_4C98		;4c75   ; no: no hay mate
	push ix		;4c77
	pop de			;4c79
	push hl			;4c7a
	ld hl,0e6c3h		;4c7b   ; distancia a la canasta
	call xy_dos_registros		;4c7e   ; jugador y canasta
	call diferencia_xy		;4c81
	call distancia		;4c84   ; distancia
	cp 008h		;4c87   ; a menos de 8
	pop hl			;4c89
	jr nc,L_4C98		;4c8a   ; 8 o mas: lejos
	ld de,00190h		;4c8c   ; y velocidad de al menos 0x190
	sbc hl,de		;4c8f   ; velocidad menos 0x190
	jr c,L_4C98		;4c91   ; salto flojo: no hay mate
	ld a,001h		;4c93   ; 1 = puede machacar
	ld (0e6f9h),a		;4c95
L_4C98:
	pop hl			;4c98
	pop de			;4c99
	ret			;4c9a
mueve_jugadores:		; Suma la velocidad y limita a la pista a los seis jugadores
	ld a,(0ed6bh)		;4c9b   ; SUPOSICION: movimiento parado
	and a			;4c9e   ; 0: se mueven
	ret nz			;4c9f
	ld ix,0e500h		;4ca0   ; primer registro
	ld de,00030h		;4ca4
	ld b,006h		;4ca7   ; seis jugadores
	ld a,(0e6cfh)		;4ca9   ; poseedor
	and 007h		;4cac   ; numero del poseedor
	ld (0e721h),a		;4cae   ; como jugador en curso
	exx			;4cb1
	ld c,000h		;4cb2   ; C' = numero de jugador
	exx			;4cb4
L_4CB5:
	push bc			;4cb5
	call mueve_jugador		;4cb6   ; limites del jugador IX
	pop bc			;4cb9
	ld de,00030h		;4cba   ; siguiente registro
	add ix,de		;4cbd
	exx			;4cbf
	inc c			;4cc0   ; siguiente numero
	exx			;4cc1
	djnz L_4CB5		;4cc2
	ret			;4cc4
mueve_jugador:		; Limita la Y (+1) y la X (+3, fraccion en +2) del jugador IX a la pista y a su medio campo
	ld d,(ix+001h)		;4cc5   ; Y del jugador
	ld e,(ix+003h)		;4cc8   ; X del jugador
	call limita_y		;4ccb   ; limites de Y
	call limita_centro		;4cce   ; limites de X con la ventana en el centro
	ld a,(ix+00fh)		;4cd1   ; bits 3-6 de +0x0F: lado y campo
	and 078h		;4cd4   ; bits 3-6
	call limita_campo		;4cd6   ; limites de X segun el campo
	ld (ix+001h),d		;4cd9   ; Y limitada
	ld (ix+003h),e		;4cdc   ; X limitada
	ret			;4cdf
limita_campo:		; Limites de X segun el campo del jugador y el lado al que ataca
	bit 3,a		;4ce0   ; bit 3: sentido de ataque
	jp z,L_4D5B		;4ce2
	bit 5,a		;4ce5   ; bit 5: mitad del cuadro anterior
	jp nz,L_4CF7		;4ce7
	bit 4,a		;4cea   ; bit 4
	jp nz,L_4D23		;4cec
	bit 6,a		;4cef   ; bit 6: mitad actual
	jp nz,L_4D3A		;4cf1
	jp limite_a0		;4cf4   ; no pasa de -0x60
L_4CF7:
	bit 4,a		;4cf7   ; bit 4
	jp nz,L_4D13		;4cf9
	bit 6,a		;4cfc   ; bit 6: mitad actual
	jp nz,limite_60		;4cfe
	ld a,(0e721h)		;4d01   ; poseedor
	exx			;4d04
	cp c			;4d05   ; es el jugador en curso?
	exx			;4d06
	ret nz			;4d07
	ld a,(0e6cfh)		;4d08   ; SUPOSICION: el poseedor paso al campo contrario
	or 010h		;4d0b   ; bit 4 del estado: desplazar la ventana a la derecha
	ld (0e6cfh),a		;4d0d
	jp fin_cuenta_10s		;4d10   ; se acaba la cuenta de 10 segundos
L_4D13:
	bit 6,a		;4d13   ; bit 6: mitad actual
	jp nz,limite_60		;4d15
L_4D18:
	ld e,000h		;4d18   ; X justo en el centro
	ld (ix+002h),000h		;4d1a   ; fraccion 0
	set 6,(ix+00fh)		;4d1e   ; mitad derecha
	ret			;4d22
L_4D23:
	bit 6,a		;4d23   ; bit 6: mitad actual
	jp z,limite_a0		;4d25
	ld a,(0e721h)		;4d28   ; poseedor
	exx			;4d2b
	cp c			;4d2c   ; es el jugador en curso?
	exx			;4d2d
	ret nz			;4d2e
	ld a,(0e6cfh)		;4d2f   ; SUPOSICION: el poseedor paso al otro campo
	or 008h		;4d32   ; bit 3 del estado: desplazar la ventana a la izquierda
	ld (0e6cfh),a		;4d34
	jp fin_cuenta_10s		;4d37   ; ha pasado al campo contrario
L_4D3A:
	ld e,0ffh		;4d3a   ; X justo antes del centro
	ld (ix+002h),0ffh		;4d3c   ; fraccion 0xFF
	res 6,(ix+00fh)		;4d40   ; mitad izquierda
	ret			;4d44
limite_a0:		; X no menor de 0xA0 (-0x60, fraccion 0xFF)
	ld a,e			;4d45
	cp 0a0h		;4d46   ; X por debajo de -0x60?
	ret nc			;4d48
	ld e,0a0h		;4d49   ; tope -0x60
	ld (ix+002h),0ffh		;4d4b
	ret			;4d4f
limite_60:		; X no mayor de 0x60 (fraccion 0)
	ld a,e			;4d50
	cp 060h		;4d51   ; X por encima de 0x60?
	ret c			;4d53
	ld e,060h		;4d54   ; tope 0x60
	ld (ix+002h),000h		;4d56
	ret			;4d5a
L_4D5B:
	bit 5,a		;4d5b   ; bit 5: mitad anterior
	jr nz,L_4D6F		;4d5d
	bit 4,a		;4d5f   ; bit 4
	jr nz,L_4D69		;4d61
	bit 6,a		;4d63   ; bit 6: mitad actual
	jr nz,L_4D18		;4d65
	jr limite_a0		;4d67
L_4D69:
	bit 6,a		;4d69
	jr nz,limite_60		;4d6b
	jr limite_a0		;4d6d
L_4D6F:
	bit 4,a		;4d6f
	jr nz,L_4D79		;4d71
	bit 6,a		;4d73
	jr nz,limite_60		;4d75
	jr limite_a0		;4d77
L_4D79:
	bit 6,a		;4d79
	jr nz,limite_60		;4d7b
	jr L_4D3A		;4d7d
limita_centro:		; Con la ventana en la columna central, limites 0x3C y 0xC4 de la X
	ld a,(0e831h)		;4d7f   ; X fina de la ventana
	cp 080h		;4d82   ; 0x80: centrada
	ret nz			;4d84
	bit 6,(ix+00fh)		;4d85   ; mitad del jugador
	ld a,e			;4d89
	jr z,L_4D96		;4d8a
	cp 03ch		;4d8c   ; por debajo de 0x3C?
	ret c			;4d8e
	ld e,03ch		;4d8f   ; tope 0x3C
	ld (ix+000h),000h		;4d91
	ret			;4d95
L_4D96:
	cp 0c4h		;4d96   ; por encima de 0xC4?
	ret nc			;4d98
	ld e,0c4h		;4d99   ; tope 0xC4
	ld (ix+000h),0ffh		;4d9b
	ret			;4d9f
limita_y:		; Y entre 0x0C y 0x68
	ld a,d			;4da0
	cp 00ch		;4da1   ; por debajo de 0x0C?
	jr nc,L_4DA8		;4da3
	ld d,00ch		;4da5   ; tope 0x0C
	ret			;4da7
L_4DA8:
	cp 068h		;4da8   ; por encima de 0x68?
	ret c			;4daa
	ld d,068h		;4dab   ; tope 0x68
	ret			;4dad
registro_jugador:		; HL = registro del jugador A (tabla 0x4DBF)
	push af			;4dae
	push de			;4daf
	add a,a			;4db0   ; dos bytes por jugador
	ld e,a			;4db1
	ld d,000h		;4db2
	ld hl,04dbfh		;4db4   ; tabla de registros
	add hl,de			;4db7
	ld a,(hl)			;4db8
	inc hl			;4db9
	ld h,(hl)			;4dba
	ld l,a			;4dbb
	pop de			;4dbc
	pop af			;4dbd
	ret			;4dbe

; ----------------------------------------------------------------------
; DATOS registros_jugador: Los seis registros de jugador, de 0x30 bytes cada
;   uno, en 0xE500 0xE530 0xE560 0xE590 0xE5C0 0xE5F0: 0x4DAE devuelve en HL
;   el del jugador A
;   0x4dbf..0x4dcb  (12 bytes)
DATA_registros_jugador:
	defw 0e500h,0e530h,0e560h,0e590h,0e5c0h,0e5f0h	; 4dbf

; ======================================================================
; CODIGO 0x4dcb..0x51f0  (1061 bytes)
; ======================================================================


lados_jugadores:		; Actualiza el lado de la pista de cada jugador (bits 5-6 de +0x0F)
	ld hl,0e844h		;4dcb   ; zonas de los tres atacantes
	ld b,003h		;4dce
	call zonas_a_4		;4dd0
	ld b,006h		;4dd3   ; seis jugadores
	ld ix,0e500h		;4dd5
	ld de,00030h		;4dd9
	ld h,000h		;4ddc   ; H = numero de jugador
L_4DDE:
	ld a,(ix+003h)		;4dde   ; X del jugador
	push de			;4de1
	push hl			;4de2
	call lado_x		;4de3   ; bits 5-6 de +0x0F
	call zona_jugador		;4de6   ; zona de los atacantes
	pop hl			;4de9
	pop de			;4dea
	add ix,de		;4deb   ; siguiente registro
	inc h			;4ded
	djnz L_4DDE		;4dee
	ret			;4df0
cambio_de_posesion:		; Invierte el sentido de ataque (bit 3 de +0x0F) de los seis jugadores y la canasta atacada
	ld a,(0e83ch)		;4df1
	res 7,a		;4df4   ; cambio atendido
	ld (0e83ch),a		;4df6
	ld c,008h		;4df9   ; bit 3: sentido de ataque
	ld hl,0e723h		;4dfb   ; SUPOSICION: sin jugador asignado
	ld (hl),0ffh		;4dfe
	ld ix,0e500h		;4e00   ; seis jugadores
	ld b,006h		;4e04
	ld de,00030h		;4e06
L_4E09:
	ld a,(ix+00fh)		;4e09   ; banderas del jugador
	xor c			;4e0c   ; invierte el bit 3
	ld (ix+00fh),a		;4e0d
	add ix,de		;4e10
	djnz L_4E09		;4e12
	ld a,(0e83ch)		;4e14   ; equipo con el balon
	and a			;4e17
	ld hl,0e6c7h		;4e18   ; SUPOSICION: canasta defendida (0xE6C7)
	inc hl			;4e1b
	ld a,039h		;4e1c   ; SUPOSICION: canasta a la que se ataca
	ld (hl),a			;4e1e
	inc hl			;4e1f
	inc hl			;4e20
	jr nz,L_4E27		;4e21
	ld a,062h		;4e23   ; SUPOSICION: canasta de la derecha
	jr L_4E29		;4e25
L_4E27:
	ld a,09eh		;4e27   ; SUPOSICION: canasta de la izquierda
L_4E29:
	ld (hl),a			;4e29
	ret			;4e2a
lado_x:		; Bit 6 de +0x0F = X positiva (mitad derecha); bit 5 = el valor anterior
	and a			;4e2b
	ld a,(ix+00fh)		;4e2c   ; banderas del jugador
	call m,x_negativa		;4e2f   ; X negativa: mitad izquierda
	call p,x_positiva		;4e32   ; X positiva: mitad derecha
	ld (ix+00fh),c		;4e35   ; banderas nuevas
	ret			;4e38
x_negativa:		; C = +0x0F con el bit 6 a 0 y el anterior en el bit 5
	push af			;4e39
	and 0dfh		;4e3a   ; sin el bit 5
	ld c,a			;4e3c
	and 040h		;4e3d   ; bit 6 actual
	rra			;4e3f   ; pasa al bit 5
	or c			;4e40
	res 6,a		;4e41   ; bit 6 a 0
	ld c,a			;4e43
	pop af			;4e44
	ret			;4e45
x_positiva:		; C = +0x0F con el bit 6 a 1 y el anterior en el bit 5
	push af			;4e46
	and 0dfh		;4e47   ; sin el bit 5
	ld c,a			;4e49
	and 040h		;4e4a   ; bit 6 actual
	rra			;4e4c   ; pasa al bit 5
	or c			;4e4d
	set 6,a		;4e4e   ; bit 6 a 1
	ld c,a			;4e50
	pop af			;4e51
	ret			;4e52
destinos_defensa:		; SUPOSICION: los del equipo sin balon reciben un destino en +0x20/+0x21; los atacantes el bit 3
	ld ix,0e500h		;4e53   ; primer registro
	ld b,006h		;4e57   ; seis jugadores
	ld a,(0e83ch)		;4e59   ; equipo con el balon
	and 001h		;4e5c
	ld c,a			;4e5e
	xor a			;4e5f   ; A = numero de jugador
L_4E60:
	push af			;4e60
	cp 003h		;4e61   ; equipo derecho?
	jr c,L_4E7D		;4e63
	inc c			;4e65
	dec c			;4e66
	jr nz,L_4E6D		;4e67   ; el izquierdo tiene el balon: defiende el derecho
	ld a,008h		;4e69   ; atacante: bit 3
	jr L_4E93		;4e6b
L_4E6D:
	push de			;4e6d
	push bc			;4e6e
	call posicion_defensa		;4e6f   ; posicion de defensa
	pop bc			;4e72
	ld (ix+020h),d		;4e73   ; destino Y
	ld (ix+021h),e		;4e76   ; destino X
	pop de			;4e79
	xor a			;4e7a
	jr L_4E93		;4e7b
L_4E7D:
	inc c			;4e7d
	dec c			;4e7e
	jr z,L_4E85		;4e7f   ; el derecho tiene el balon: defiende el izquierdo
	ld a,008h		;4e81   ; atacante: bit 3
	jr L_4E93		;4e83
L_4E85:
	push de			;4e85
	push bc			;4e86
	call posicion_defensa		;4e87   ; posicion de defensa
	pop bc			;4e8a
	ld (ix+020h),d		;4e8b   ; destino Y
	ld (ix+021h),e		;4e8e   ; destino X
	pop de			;4e91
	xor a			;4e92
L_4E93:
	or (ix+00fh)		;4e93   ; bit 3 en las banderas
	ld (ix+00fh),a		;4e96
	ld de,00030h		;4e99
	pop af			;4e9c
	inc a			;4e9d   ; siguiente numero
	add ix,de		;4e9e   ; siguiente registro
	djnz L_4E60		;4ea0
	jp cambio_de_posesion		;4ea2   ; y se invierte el ataque
extiende_signo:		; DE = A con signo
	ld e,a			;4ea5
	ld d,000h		;4ea6
	and a			;4ea8   ; positivo: D = 0
	ret p			;4ea9
	dec d			;4eaa   ; negativo: D = 0xFF
	ret			;4eab
controlados:		; A = controlado del equipo con el balon, A' = el del otro
	ld a,(0e83ch)		;4eac   ; equipo con el balon
	and 001h		;4eaf
	jr nz,L_4EBC		;4eb1
	ld a,(0e6d8h)		;4eb3   ; controlado izquierdo
	ex af,af'			;4eb6
	ld a,(0e6dbh)		;4eb7   ; A' = controlado derecho
	ex af,af'			;4eba
	ret			;4ebb
L_4EBC:
	ld a,(0e6dbh)		;4ebc   ; controlado derecho
	ex af,af'			;4ebf
	ld a,(0e6d8h)		;4ec0   ; A' = controlado izquierdo
	ex af,af'			;4ec3
	ret			;4ec4
controlado:		; A = jugador controlado del equipo con el balon
	ld a,(0e83ch)		;4ec5   ; equipo con el balon
	and 001h		;4ec8
	jr nz,L_4ED0		;4eca
	ld a,(0e6d8h)		;4ecc   ; controlado izquierdo
	ret			;4ecf
L_4ED0:
	ld a,(0e6dbh)		;4ed0   ; controlado derecho
	ret			;4ed3
apunta_saltador:		; Guarda el jugador A como saltador de su equipo (0xE6E0 o 0xE6E1)
	cp 003h		;4ed4   ; equipo derecho?
	jr nc,L_4EDC		;4ed6
	ld (0e6e0h),a		;4ed8   ; saltador izquierdo
	ret			;4edb
L_4EDC:
	ld (0e6e1h),a		;4edc   ; saltador derecho
	ret			;4edf
borra_saltador:		; Borra el saltador del equipo del jugador A
	cp 003h		;4ee0
	ld hl,0e6e0h		;4ee2   ; saltador izquierdo
	jr c,L_4EEA		;4ee5
	ld hl,0e6e1h		;4ee7   ; saltador derecho
L_4EEA:
	ld (hl),0ffh		;4eea   ; ya no salta
	ld hl,(0e6dfh)		;4eec   ; HL = palabra de 0xE6DF: L el que tiro, H el saltador izquierdo (0xFF casi siempre); SUPOSICION: se queria ld hl,0xE6DF
	cp (hl)			;4eef   ; compara A con el byte de 0xFF00-0xFF05, 0xFFFF o la BIOS segun H:L
	ret nz			;4ef0
	ld (hl),0ffh		;4ef1   ; si coincide escribe 0xFF alli; 0xE6DF no se borra
	ret			;4ef3
recoge_balon:		; Balon suelto: el primero que este a menos de 10 y a su altura se lo queda
	ld a,(0e6cfh)		;4ef4   ; 7 = balon suelto
	cp 007h		;4ef7
	ret nz			;4ef9
	ld hl,0e500h		;4efa
	ld b,006h		;4efd
	ld c,000h		;4eff
L_4F01:
	push bc			;4f01
	push hl			;4f02
	ld de,0e620h		;4f03   ; registro del balon
	call xy_dos_registros		;4f06
	call diferencia_xy		;4f09
	call distancia		;4f0c
	pop hl			;4f0f
	pop bc			;4f10
	cp 00ah		;4f11   ; a menos de 10?
	jr c,L_4F1D		;4f13
L_4F15:
	ld de,00030h		;4f15
	add hl,de			;4f18
	inc c			;4f19
	djnz L_4F01		;4f1a
	ret			;4f1c
L_4F1D:
	push bc			;4f1d
	push hl			;4f1e
	ld a,(0e629h)		;4f1f   ; altura del balon
	ld c,a			;4f22
	dec c			;4f23
	ld de,00009h		;4f24   ; altura del jugador
	add hl,de			;4f27
	ld a,0e0h		;4f28
	add a,(hl)			;4f2a
	cp c			;4f2b
	pop hl			;4f2c
	pop bc			;4f2d
	jr nc,L_4F15		;4f2e
	ld a,(0e6f1h)		;4f30   ; durante el salto entre dos
	and a			;4f33
	jp nz,palmeo_salto		;4f34
	ld a,(0ed63h)		;4f37   ; tiro en vuelo
	and a			;4f3a
	jr z,L_4F44		;4f3b
	ld a,(0ed66h)		;4f3d
	and a			;4f40
	jp m,L_4F15		;4f41
L_4F44:
	ld a,(0ed61h)		;4f44   ; SUPOSICION: jugadores que no pueden cogerlo
	cp c			;4f47
	jr z,L_4F56		;4f48
	ld a,(0ed63h)		;4f4a
	and a			;4f4d
	jr nz,L_4F15		;4f4e
	ld a,(0ed62h)		;4f50
	cp c			;4f53
	jr nz,L_4F15		;4f54
L_4F56:
	ld a,(0e629h)		;4f56
	ld (0e62dh),a		;4f59
	call para_balon		;4f5c   ; SUPOSICION: canasta a la que ataca
	ld (0e624h),hl		;4f5f
	ld (0e626h),hl		;4f62
	xor a			;4f65
	ld (0ed5ah),a		;4f66
	ld (0ed79h),a		;4f69
	ld (0e6f6h),a		;4f6c
	ld a,c			;4f6f
	call da_balon		;4f70   ; nuevo poseedor
	ld a,0ffh		;4f73   ; nadie bloqueado
	ld (0e6f9h),a		;4f75
	ld (0ed61h),a		;4f78
	ld (0ed62h),a		;4f7b
	ld (0ed5fh),a		;4f7e
	ld (0ed60h),a		;4f81
	ld a,(0ed63h)		;4f84
	and a			;4f87
	ret nz			;4f88
	call cuenta_10s		;4f89   ; relojes de 10 y 30 segundos
	call cuenta_30s		;4f8c
	ret			;4f8f
da_balon:		; Da el balon al jugador A; el otro equipo pasa a controlar a su defensor emparejado (+0x25)
	push ix		;4f90
	push hl			;4f92
	push de			;4f93
	push bc			;4f94
	push af			;4f95
	call pon_poseedor		;4f96   ; poseedor nuevo y controlados
	pop af			;4f99
	call registro_jugador		;4f9a   ; registro del nuevo poseedor
	ld de,00025h		;4f9d
	add hl,de			;4fa0
	ld a,(hl)			;4fa1   ; su par (+0x25)
	call controla		;4fa2   ; pasa a ser el controlado del rival
	pop bc			;4fa5
	pop de			;4fa6
	pop hl			;4fa7
	pop ix		;4fa8
	ret			;4faa
controla:		; Jugador controlado: A menor que 3 en 0xE6D8/0xE6D9, si no en 0xE6DB/0xE6DC
	cp 003h		;4fab
	jr nc,L_4FC4		;4fad
	ld (0e6d8h),a		;4faf   ; controlado del equipo izquierdo
	push hl			;4fb2
	push af			;4fb3
	ld a,(0e83ch)		;4fb4
	and a			;4fb7
	call nz,marca_controlado		;4fb8
	pop af			;4fbb
	call registro_jugador		;4fbc
	ld (0e6d9h),hl		;4fbf   ; su registro
	pop hl			;4fc2
	ret			;4fc3
L_4FC4:
	ld (0e6dbh),a		;4fc4   ; controlado del equipo derecho
	push hl			;4fc7
	push af			;4fc8
	ld a,(0e83ch)		;4fc9   ; equipo con el balon
	and a			;4fcc
	call z,marca_controlado		;4fcd   ; el derecho ataca: marca a su controlado
	pop af			;4fd0
	call registro_jugador		;4fd1
	ld (0e6dch),hl		;4fd4   ; registro del controlado derecho
	pop hl			;4fd7
	ret			;4fd8
reloj_en_marcha:		; Pone en marcha el reloj del partido
	xor a			;4fd9
	ld (0ed7dh),a		;4fda
	ld (0ed7eh),a		;4fdd
	ret			;4fe0
espera_300:		; Cuenta atras general de 300 cuadros
	ld hl,0012ch		;4fe1
	ld (0ed90h),hl		;4fe4
	ret			;4fe7
nada_huerfano:		; Huerfano: un ret suelto
	ret			;4fe8
cuenta_10s:		; Si el poseedor esta en su campo, arranca la cuenta de 10 segundos (600 cuadros en 0xED8A)
	call controlado		;4fe9
	call registro_jugador		;4fec
	call pose_bit6		;4fef
	ret z			;4ff2
	xor a			;4ff3
	ld (0ed81h),a		;4ff4
	ld hl,00258h		;4ff7   ; 600 cuadros
	ld (0ed8ah),hl		;4ffa
	ret			;4ffd
fin_cuenta_10s:		; En el campo contrario la cuenta de 10 segundos queda desactivada (2)
	call controlado		;4ffe   ; controlado del equipo con el balon
	call registro_jugador		;5001
	call pose_bit6		;5004
	ret nz			;5007   ; aun en su campo
	ld a,002h		;5008   ; 2 = cuenta desactivada
	ld (0ed81h),a		;500a
	ret			;500d
cuenta_30s:		; Arranca la cuenta de 30 segundos (1800 cuadros en 0xED8C)
	xor a			;500e
	ld (0ed82h),a		;500f
	ld hl,00708h		;5012
	ld (0ed8ch),hl		;5015
	ret			;5018
para_30s_huerfano:		; Huerfano: desactivaria la cuenta de 30 segundos
	ld a,002h		;5019
	ld (0ed82h),a		;501b
	ret			;501e

; ----------------------------------------------------------------------
; ===== Montaje de la pantalla y estado inicial =====
; ----------------------------------------------------------------------
monta_pantalla:		; SCREEN 2, graficos de sprites y patrones de la pista
	call congela_sprites		;501f   ; pantalla parada mientras se monta
	call pon_screen2		;5022   ; SCREEN 2 con la BIOS
	call graficos_sprites		;5025   ; sprites: fijos, patrones en RAM y los atributos
	call patrones_pista		;5028   ; los 250 patrones de la pista y los colores del AREA
	jp suelta_sprites		;502b   ; pantalla en marcha, y vuelve
pon_screen2:		; Fondo y borde negros y SCREEN 2 por la BIOS
	ld a,001h		;502e   ; FORCLR = BAKCLR = 1: la tabla de colores entera a 0x11
	ld (0f3ebh),a		;5030   ; BDRCLR = 1 (negro)
	ld (0f3eah),a		;5033   ; BAKCLR = 1
	jp 00072h		;5036   ; BIOS INIGRP - Switches to SCREEN 2 (high resolution screen with 256*192 pixels)
graficos_sprites:		; Descomprime los patrones de jugador a la RAM, sprites de 16x16, red y balon a 0x3B00 y copia inicial de atributos
	call patrones_jugadores		;5039   ; los 196 patrones de sprite a la RAM (0xCC00-0xE47F)
	call sprites_16x16		;503c   ; sprites de 16x16
	call 00069h		;503f   ; BIOS CLRSPR - Initialises all sprites
	call alterna_tabla_atributos		;5042   ; limpia tambien la otra tabla de atributos
	call 00069h		;5045   ; BIOS CLRSPR - Initialises all sprites
	call alterna_tabla_atributos		;5048   ; alterna la tabla de atributos
	ld de,03b00h		;504b   ; red de la canasta: 3 patrones de 16x16
	ld hl,09665h		;504e   ; los 96 bytes de la red
	ld bc,00060h		;5051   ; tres patrones de 32 bytes
	call copia_a_vram		;5054   ; a la VRAM 0x3B00
	ld de,03b60h		;5057   ; balon, sombra y flecha
	ld hl,096c5h		;505a   ; balon, sombra y flecha
	ld bc,00060h		;505d   ; tres patrones
	call copia_a_vram		;5060   ; a la VRAM 0x3B60
	ld hl,01b00h		;5063   ; tabla de atributos limpia a la sombra 0xE730
	ld de,0e730h		;5066   ; 0xE730: el bufer de atributos
	push de			;5069   ; guardado
	ld bc,00080h		;506a   ; 0x80 bytes: los 32 sprites
	push bc			;506d   ; guardada la cuenta
	call lee_de_vram		;506e   ; los atributos que dejo CLRSPR (Y = 209), de la VRAM al bufer
	pop bc			;5071   ; recupera la cuenta
	pop hl			;5072   ; HL = 0xE730
	ld de,0e7b0h		;5073   ; y a la segunda lista 0xE7B0
	ldir		;5076   ; copia al otro bufer, 0xE7B0
	ret			;5078
patrones_jugadores:		; Descomprime los 196 patrones de 16x16 de los jugadores en 0xCC00-0xE47F
	ld de,0cc00h		;5079   ; primer banco: patrones 0-63
	ld hl,09725h		;507c   ; primer bloque a 0xCC00
	call descomprime		;507f   ; de 0x9725
	ld de,0d400h		;5082   ; segundo banco: 64-127
	ld hl,09b08h		;5085   ; segundo bloque a 0xD400
	call descomprime		;5088   ; de 0x9B08
	ld de,0dc00h		;508b   ; tercer banco: 128-191
	ld hl,09f80h		;508e   ; tercer bloque a 0xDC00
	call descomprime		;5091   ; de 0x9F80
	ld de,0e400h		;5094   ; los cuatro de 0xE400: 192-195
	ld hl,0a360h		;5097   ; cuarto bloque (solo repeticiones) a 0xE400
	call descomprime_rep		;509a   ; de 0xA360, solo repeticiones
	jp marcador_ram		;509d   ; el marcador descomprimido a 0xEF77, y vuelve
sprites_16x16:		; Bit 1 del registro 1 del VDP: sprites de 16x16
	ld a,(0f3e0h)		;50a0   ; RG1SAV
	or 002h		;50a3   ; bit 1 del registro 1: sprites de 16x16
	ld b,a			;50a5   ; B = valor
	ld c,001h		;50a6   ; registro 1
	call 00047h		;50a8   ; BIOS WRTVDP - Writes data in the VDP-register
	ret			;50ab   ; listo
patrones_pista:		; Nombres en blanco, 250 patrones de la pista en los tres tercios y colores del AREA
	call borra_nombres		;50ac   ; nombres a 0x20
	ld de,0c400h		;50af   ; a 0xC400 provisionalmente
	ld hl,0a74eh		;50b2   ; los 250 patrones comprimidos
	call descomprime		;50b5   ; a 0xC400
	ld de,00000h		;50b8   ; desde el patron 0
	call patrones_tres_tercios		;50bb   ; a los tres tercios desde la VRAM 0
	jp colores_area		;50be   ; colores del AREA elegida
patrones_tres_tercios:		; Copia los 2 KB de 0xC400 a la VRAM DE y a los dos tercios siguientes
	ld hl,0c400h		;50c1   ; el bufer
	ld b,003h		;50c4   ; tres tercios de 0x800
L_50C6:
	push bc			;50c6   ; guarda la cuenta de tercios
	push hl			;50c7   ; el origen
	push de			;50c8   ; y el destino
	ld bc,00800h		;50c9   ; un tercio: 0x800 bytes
	call 0005ch		;50cc   ; BIOS LDIRVM - Block transfers to VRAM from memory
	pop de			;50cf   ; recupera el destino
	ld hl,00800h		;50d0   ; un tercio mas
	add hl,de			;50d3   ; el siguiente
	ex de,hl			;50d4   ; DE = destino
	pop hl			;50d5   ; HL = origen
	pop bc			;50d6   ; recupera la cuenta
	djnz L_50C6		;50d7   ; los tres
	ret			;50d9
borra_nombres:		; Tabla de nombres 0x1800 entera a espacios (0x20)
	ld a,020h		;50da   ; espacio
	ld hl,01800h		;50dc   ; la tabla de nombres
	ld bc,00300h		;50df   ; las 768 celdas
	call rellena_vram		;50e2   ; rellena
	ret			;50e5
inicia_partido:		; Tablas de perspectiva, semilla al azar y todas las variables de jugada a su valor de salida
	call tablas_mates		;50e6   ; tablas de perspectiva 0xC000-0xC2FF
	ld a,r		;50e9   ; semilla del azar desde el registro R
	ld l,a			;50eb   ; L = el registro R
	ld h,000h		;50ec   ; HL = semilla
	ld (0e6feh),hl		;50ee   ; (0xE6FE): semilla del azar
	ld a,0ffh		;50f1   ; SUPOSICION: sin repeticion de mando
	ld (0f007h),a		;50f3   ; ningun jugador bloqueado
	ld (0ed66h),a		;50f6   ; SUPOSICION: tiro forzado desactivado
	ld (0ed5fh),a		;50f9   ; (0xED5F) a 0xFF
	ld (0ed60h),a		;50fc   ; (0xED60) a 0xFF
	ld (0e6d2h),a		;50ff   ; ultimo poseedor: ninguno
	ld (0e6f9h),a		;5102   ; nadie puede machacar
	ld (0e6e0h),a		;5105   ; saltadores de los dos equipos: ninguno
	ld (0e6e1h),a		;5108   ; (0xE6E1) a 0xFF
	ld (0e6dfh),a		;510b   ; nadie ha tirado
	ld (0ed61h),a		;510e   ; (0xED61) a 0xFF
	ld (0ed62h),a		;5111   ; (0xED62) a 0xFF
	ld (0ed6fh),a		;5114   ; sin infractor
	ld (0ed70h),a		;5117   ; sin tipo de falta
	ld (0ed71h),a		;511a   ; (0xED71) a 0xFF: nadie pasa
	ld a,001h		;511d   ; controlado izquierdo: jugador 1
	ld (0e6d8h),a		;511f   ; (0xE6D8) = 1: controlado de la izquierda
	ld a,004h		;5122   ; controlado derecho: jugador 4
	ld (0e6dbh),a		;5124   ; (0xE6DB) = 4: controlado de la derecha
	ld a,007h		;5127   ; balon suelto
	ld (0e6cfh),a		;5129   ; (0xE6CF) = 7: estado del partido
	ld a,03fh		;512c   ; sin formacion
	ld (0e850h),a		;512e   ; (0xE850) = 0x3F: sin formacion
	ld hl,00000h		;5131   ; HL = 0
	ld (0e71dh),hl		;5134   ; sin marca de jugador
	ld hl,0d1d1h		;5137   ; SUPOSICION: limites de la pista
	ld (0e6cbh),hl		;513a   ; (0xE6CB) = 0xD1D1
	ld de,0389eh		;513d   ; SUPOSICION: canasta (0xE6C3) en Y 0x38, X 0x9E
	ld hl,0e6c4h		;5140   ; 0xE6C4: la canasta
	ld (hl),d			;5143   ; Y de la canasta = 0x38
	inc hl			;5144   ; +2
	inc hl			;5145
	ld (hl),e			;5146   ; X de la canasta = 0x9E
	call tablas_equipos		;5147   ; tabla de cada equipo desde 0xAF5F
	call sombras_iniciales		;514a   ; colocacion inicial de los sprites
	call coloca_jugadores		;514d   ; posiciones de salida de los seis
	call sin_direccion		;5150   ; sin direccion ni giro
	jp empareja_jugadores		;5153   ; parejas de marcaje en +0x25
borra_jugada:		; Pone a cero los campos +4 a +0x17 de los seis jugadores y el balon y las banderas de la jugada
	ld hl,0e504h		;5156   ; campo +4 del primer registro
	ld b,007h		;5159   ; seis jugadores y el balon
	xor a			;515b   ; A = 0
L_515C:
	push bc			;515c   ; guarda la cuenta de registros
	ld b,014h		;515d   ; 20 bytes desde +4
L_515F:
	ld (hl),a			;515f   ; un byte a cero
	inc hl			;5160   ; siguiente
	djnz L_515F		;5161   ; 20 bytes (+4 a +0x17)
	ld de,0001ch		;5163   ; al siguiente registro (+0x30)
	add hl,de			;5166   ; mas 28: el +4 del registro siguiente
	pop bc			;5167   ; recupera la cuenta
	djnz L_515C		;5168   ; los siete (seis jugadores y el balon)
	ld (0ed6bh),a		;516a   ; (0xED6B) a cero
	ld (0ed69h),a		;516d   ; (0xED69) a cero
	ld (0ed6ah),a		;5170   ; (0xED6A) a cero
	ld (0e832h),a		;5173   ; (0xE832) a cero
	ld (0e6f2h),a		;5176   ; (0xE6F2) a cero
	ld (0ed63h),a		;5179   ; (0xED63) a cero: sin falta
	ld (0e6f6h),a		;517c   ; (0xE6F6) a cero
	ld (0ed6ch),a		;517f   ; (0xED6C) a cero
	ld (0ed6dh),a		;5182   ; (0xED6D) a cero
	ld (0e6e2h),a		;5185   ; (0xE6E2) a cero
	ret			;5188
borra_ram:		; Pone a cero 0xE500-0xF011 (0xB12 bytes): jugadores, sprites, equipos y variables
	ld hl,0e500h		;5189   ; desde 0xE500
	ld bc,00b11h		;518c   ; 0xB11 bytes: hasta 0xF010
	ld (hl),000h		;518f   ; el primero a cero
	ld d,h			;5191   ; DE = HL + 1
	ld e,l			;5192
	inc de			;5193
	ldir		;5194   ; y el resto copiando el anterior
	ret			;5196
tablas_equipos:		; Descomprime los 720 bytes de 0xAF5F en 0xEA89
	ld bc,002d0h		;5197   ; 720 bytes (no los usa 0x52CF: el bloque dice su fin)
	ld de,0ea89h		;519a   ; a 0xEA89
	ld hl,0af5fh		;519d   ; de 0xAF5F
	jp descomprime		;51a0   ; descomprime y vuelve
sombras_iniciales:		; Colocacion, patrones y colores iniciales de los 28 sprites de la sombra 0xE650
	ld hl,0e650h		;51a3   ; los atributos de los jugadores
	ld b,006h		;51a6   ; seis jugadores
L_51A8:
	ld de,051f0h		;51a8   ; colocacion de salida (0x51F0)
	push bc			;51ab   ; guarda la cuenta
	ld b,004h		;51ac   ; cuatro sprites
L_51AE:
	ld a,(de)			;51ae   ; dy
	inc de			;51af   ; siguiente
	ld (hl),a			;51b0   ; Y
	inc hl			;51b1   ; siguiente byte
	ld a,(de)			;51b2   ; dx
	inc de			;51b3   ; siguiente
	ld (hl),a			;51b4   ; X
	inc hl			;51b5   ; se salta patron y color
	inc hl			;51b6
	inc hl			;51b7
	djnz L_51AE		;51b8   ; los cuatro
	pop bc			;51ba   ; recupera la cuenta
	djnz L_51A8		;51bb   ; los seis, con los mismos cuatro pares
	ld hl,0e652h		;51bd   ; numero de patron de cada sprite
	ld de,00004h		;51c0   ; cuatro bytes por atributo
	xor a			;51c3   ; patron 0
	ld b,018h		;51c4   ; 24 sprites de jugador: 0, 4, 8...
L_51C6:
	ld (hl),a			;51c6   ; numero de patron
	add hl,de			;51c7   ; atributo siguiente
	add a,004h		;51c8   ; patron siguiente: 4 bytes mas (16x16)
	djnz L_51C6		;51ca   ; los 24 sprites de jugador: patrones 0-0x5C
	ld (hl),a			;51cc   ; el 25: patron 0x60 (la red)
	add hl,de			;51cd   ; siguiente
	ld a,06ch		;51ce   ; balon: patrones 0x6C, 0x70, 0x74
	ld b,003h		;51d0   ; tres mas
L_51D2:
	ld (hl),a			;51d2   ; patron 0x6C, 0x70, 0x74: balon, sombra, flecha
	add a,004h		;51d3   ; siguiente patron
	add hl,de			;51d5   ; siguiente atributo
	djnz L_51D2		;51d6   ; los tres
	ld hl,0e6b0h		;51d8   ; cuatro sprites del balon y la red (0x51F8)
	ld de,051f8h		;51db   ; los cuatro tripletes
	ld b,004h		;51de   ; cuatro sprites fijos
L_51E0:
	ld a,(de)			;51e0   ; Y
	inc de			;51e1   ; siguiente
	ld (hl),a			;51e2   ; al atributo
	inc hl			;51e3   ; X
	ld a,(de)			;51e4   ; X
	inc de			;51e5   ; siguiente
	ld (hl),a			;51e6   ; al atributo
	inc hl			;51e7   ; se salta el patron
	inc hl			;51e8   ; color
	ld a,(de)			;51e9   ; color
	inc de			;51ea   ; siguiente
	ld (hl),a			;51eb   ; al atributo
	inc hl			;51ec   ; siguiente atributo
	djnz L_51E0		;51ed   ; los cuatro
	ret			;51ef

; ----------------------------------------------------------------------
; DATOS sprites_jugador_yx: Cuatro pares (Y, X) de los cuatro sprites de un
;   jugador: 0x51A3 los copia a los seis grupos de cuatro atributos de 0xE650
;   0x51f0..0x51f8  (8 bytes)
DATA_sprites_jugador_yx:
	defb 01fh,008h	; 51f0
	defb 00fh,008h	; 51f2
	defb 01fh,008h	; 51f4
	defb 00fh,008h	; 51f6

; ----------------------------------------------------------------------
; DATOS sprites_fijos: Cuatro tripletes (Y, X, color) de los cuatro sprites de
;   0xE6B0 (los que no son jugadores): 0x51D8 los copia saltandose el byte del
;   patron
;   0x51f8..0x5204  (12 bytes)
DATA_sprites_fijos:
	defb 000h,0f8h,00ah	; 51f8
	defb 0f2h,0f8h,00ah	; 51fb
	defb 0f1h,0f8h,001h	; 51fe
	defb 0d1h,000h,008h	; 5201

; ======================================================================
; CODIGO 0x5204..0x5255  (81 bytes)
; ======================================================================


coloca_jugadores:		; Posiciones de salida y velocidades segun la plantilla
	call posiciones_salida		;5204   ; los seis jugadores a sus posiciones de saque
	jp velocidades		;5207   ; y las velocidades, y vuelve
posiciones_salida:		; Y, X, banderas y pose de los seis jugadores e Y, X del balon desde 0x5255
	ld ix,0e500h		;520a   ; el primer registro
	ld de,00030h		;520e   ; 0x30 por registro
	ld hl,05255h		;5211   ; la tabla de posiciones iniciales
	ld b,006h		;5214   ; seis jugadores
L_5216:
	ld a,(hl)			;5216   ; Y de salida
	inc hl			;5217   ; siguiente
	ld (ix+001h),a		;5218   ; +1: Y
	ld a,(hl)			;521b   ; X de salida (con signo desde el centro)
	inc hl			;521c   ; siguiente
	ld (ix+003h),a		;521d   ; +3: X
	ld a,(hl)			;5220   ; banderas +0x0F
	inc hl			;5221   ; siguiente
	ld (ix+00fh),a		;5222   ; +0x0F: patrones
	ld a,(hl)			;5225   ; pose de salida
	inc hl			;5226   ; siguiente
	ld (ix+00dh),a		;5227   ; +0x0D: pose
	ld (ix+022h),03fh		;522a   ; sin formacion (+0x22)
	add ix,de		;522e   ; siguiente registro
	djnz L_5216		;5230   ; los seis
	ld a,(hl)			;5232   ; posicion del balon
	inc hl			;5233   ; siguiente
	ld (ix+001h),a		;5234   ; el balon: Y
	ld a,(hl)			;5237   ; X
	ld (ix+003h),a		;5238   ; el balon: X
	ld hl,0e500h		;523b   ; el primer registro
	ld de,00030h		;523e   ; 0x30 por registro
	ld b,006h		;5241   ; seis jugadores
	ld a,080h		;5243   ; pose cambiada de cada jugador
L_5245:
	ld (0e837h),hl		;5245   ; (0xE837): registro en curso
	ld (0e836h),a		;5248   ; (0xE836): bit 7, pose cambiada
	push af			;524b   ; guarda el jugador
	call copia_pose		;524c   ; patrones de su pose a la VRAM
	pop af			;524f   ; recupera el jugador
	add hl,de			;5250   ; siguiente registro
	inc a			;5251   ; siguiente jugador
	djnz L_5245		;5252   ; los seis
	ret			;5254   ; listo

; ----------------------------------------------------------------------
; DATOS jugadores_inicial: Seis fichas de cuatro bytes (campos +1, +3, +0F y
;   +0D de cada registro de 0xE500) y dos bytes mas (+1 y +3 del septimo
;   registro, 0xE620): 0x520A las reparte al arrancar
;   0x5255..0x526f  (26 bytes)
DATA_jugadores_inicial:
	defb 02ah,0f0h,010h,069h	; 5255
	defb 03ah,0fbh,010h,069h	; 5259
	defb 04ah,010h,070h,079h	; 525d
	defb 02ah,010h,060h,098h	; 5261
	defb 03ah,005h,060h,098h	; 5265
	defb 04ah,0f0h,000h,088h	; 5269
	defb 064h,064h	; 526d

; ======================================================================
; CODIGO 0x526f..0x5a96  (2087 bytes)
; ======================================================================


velocidades:		; Velocidad con balon (+0x10) y sin balon (+0x12) a partir de la rapidez +0x1B del roster
	ld ix,0e500h		;526f
	ld de,00030h		;5273
	ld b,006h		;5276
L_5278:
	exx			;5278
	ld de,0005ah		;5279   ; base 0x5A
	call suma_rapidez		;527c
	ld (ix+010h),l		;527f
	ld (ix+011h),h		;5282
	ld de,0003fh		;5285   ; base 0x3F
	call suma_rapidez		;5288
	ld (ix+012h),l		;528b
	ld (ix+013h),h		;528e
	exx			;5291
	add ix,de		;5292
	djnz L_5278		;5294
	ret			;5296
suma_rapidez:		; HL = DE + (+0x1B)/2
	ld a,(ix+01bh)		;5297   ; rapidez del jugador (+0x1B)
	and a			;529a
	rra			;529b   ; la mitad
	ld l,a			;529c
	ld h,000h		;529d
	add hl,de			;529f   ; mas la base
	ret			;52a0
sin_direccion:		; Direccion 0x3F, rumbo y giro 0xFF y sentido 0 en los seis
	ld ix,0e500h		;52a1
	ld de,00030h		;52a5
	ld b,006h		;52a8
L_52AA:
	ld (ix+015h),03fh		;52aa   ; sin direccion
	xor a			;52ae
	dec a			;52af
	ld (ix+016h),a		;52b0   ; sin rumbo de giro
	ld (ix+017h),a		;52b3
	xor a			;52b6
	ld (ix+018h),a		;52b7   ; sin sentido de giro
	add ix,de		;52ba   ; siguiente registro
	djnz L_52AA		;52bc
	ret			;52be
empareja_jugadores:		; +0x25 de los seis: 5, 4, 3, 2, 1, 0 (cada uno con su par del otro equipo)
	ld hl,0e525h		;52bf
	ld de,00030h		;52c2
	ld c,005h		;52c5
	ld b,006h		;52c7
L_52C9:
	ld (hl),c			;52c9
	dec c			;52ca
	add hl,de			;52cb
	djnz L_52C9		;52cc
	ret			;52ce
descomprime:		; Descompresor general: cabecera mascara/valor, repeticiones y referencias de 8 bytes (directas o con los bits al reves) a lo ya escrito
	push de			;52cf   ; guarda el destino
	exx			;52d0   ; en DE': la base del diccionario (lo ya escrito)
	pop de			;52d1   ; DE' = destino inicial
	exx			;52d2   ; registros normales
	ld c,(hl)			;52d3   ; C = mascara del byte de control
	inc hl			;52d4   ; C = mascara
	ld b,(hl)			;52d5   ; B = valor que lo identifica
	inc hl			;52d6   ; B = valor de control; HL = primera ficha
L_52D7:
	push bc			;52d7   ; guarda mascara y valor
	ld a,(hl)			;52d8   ; la ficha
	and c			;52d9   ; solo los bits de la mascara
	cp b			;52da   ; es de control?
	jr nz,L_52F5		;52db   ; byte normal: literal
	ld a,c			;52dd   ; contador de repeticion
	cpl			;52de   ; A = ~mascara
	and (hl)			;52df   ; A = la ficha sin los bits de control
	inc hl			;52e0   ; siguiente byte
	bit 0,c		;52e1   ; mascara impar: contador en los bits altos
	jr z,L_52E6		;52e3   ; mascara par: tal cual
	rra			;52e5   ; mascara impar: el bit 0 era de control, fuera
L_52E6:
	cp 002h		;52e6   ; 0 o 1: referencia al diccionario
	jr c,L_52F9		;52e8   ; 0 o 1: diccionario (0x52F9)
	inc a			;52ea   ; 2 o mas: A + 1 repeticiones
	ld b,a			;52eb   ; repeticiones
L_52EC:
	ld a,(hl)			;52ec   ; el byte a repetir
L_52ED:
	ld (de),a			;52ed   ; al destino
	inc de			;52ee   ; siguiente
	djnz L_52ED		;52ef   ; B veces
L_52F1:
	inc hl			;52f1   ; ficha siguiente
	pop bc			;52f2   ; recupera mascara y valor
	jr L_52D7		;52f3   ; otra ficha
L_52F5:
	ld b,001h		;52f5   ; literal suelto
	jr L_52EC		;52f7   ; un literal: B = 1 y a copiarlo
L_52F9:
	and a			;52f9   ; 0 o 1?
	jr nz,L_5302		;52fa   ; 1: con los bits al reves (0x5302 con B = 1)
	ld b,(hl)			;52fc   ; 0xFF tras el 0: fin
	inc b			;52fd   ; indice 0xFF: fin
	jr nz,L_5302		;52fe   ; otro indice: diccionario
	pop bc			;5300   ; recupera mascara y valor
	ret			;5301   ; HL = primera direccion despues del bloque
L_5302:
	push hl			;5302   ; guarda la ficha
	ld b,a			;5303   ; B = 0 (copia) o 1 (bits al reves)
	ld a,(hl)			;5304   ; A = indice del diccionario
	exx			;5305   ; registros alternativos
	ld l,a			;5306   ; numero de bloque de 8 bytes ya escrito
	ld h,000h		;5307   ; HL' = indice
	add hl,hl			;5309   ; por dos
	add hl,hl			;530a   ; por cuatro
	add hl,hl			;530b   ; por ocho
	add hl,de			;530c   ; mas la base: la entrada de ocho bytes ya escrita
	push hl			;530d   ; guardada
	exx			;530e   ; registros normales
	pop hl			;530f   ; HL = la entrada
	ld a,b			;5310   ; copia o al reves?
	and a			;5311   ; cero: copia
	jr nz,L_531C		;5312   ; uno: al reves
	ld bc,00008h		;5314   ; copia directa
	ldir		;5317   ; ocho bytes tal cual
L_5319:
	pop hl			;5319   ; recupera el puntero de fichas
	jr L_52F1		;531a   ; ficha siguiente
L_531C:
	ld c,008h		;531c   ; copia en espejo
L_531E:
	push de			;531e   ; guarda el destino
	ld a,(hl)			;531f   ; un byte de la entrada
	ld b,008h		;5320   ; bits del byte al reves
L_5322:
	rra			;5322   ; un bit por la derecha
	rl d		;5323   ; entra por la izquierda de D
	djnz L_5322		;5325   ; los ocho bits
	ld a,d			;5327   ; A = el byte dado la vuelta
	pop de			;5328   ; recupera el destino
	ld (de),a			;5329   ; al destino
	inc de			;532a   ; siguiente
	inc hl			;532b   ; siguiente byte de la entrada
	dec c			;532c   ; los ocho
	jr nz,L_531E		;532d   ; otro byte
	jr L_5319		;532f   ; ficha siguiente
descomprime_rep:		; Descompresor de solo repeticiones; fin cuando el control va seguido de si mismo
	ld c,(hl)			;5331   ; C = mascara
	inc hl			;5332   ; siguiente
	ld b,(hl)			;5333   ; B = valor de control
	inc hl			;5334   ; HL = primera ficha
L_5335:
	push bc			;5335   ; guarda mascara y valor
	ld a,(hl)			;5336   ; la ficha
	and c			;5337   ; solo los bits de la mascara
	cp b			;5338   ; es de control?
	jr nz,L_5357		;5339   ; no: literal
	inc hl			;533b   ; el byte siguiente
	cp (hl)			;533c   ; control repetido: fin
	jr nz,L_5341		;533d   ; distinto de la ficha: repeticion
	pop bc			;533f   ; igual: recupera y acaba
	ret			;5340   ; HL = primera direccion despues del bloque
L_5341:
	ld a,c			;5341   ; A = ~mascara
	cpl			;5342   ; complemento
	dec hl			;5343   ; de vuelta a la ficha
	and (hl)			;5344   ; la ficha sin los bits de control
	inc hl			;5345   ; al byte siguiente
	bit 0,c		;5346   ; mascara impar?
	jr z,L_534B		;5348   ; par: tal cual
	rra			;534a   ; impar: el bit 0 fuera
L_534B:
	add a,003h		;534b   ; minimo 3 repeticiones
	ld b,a			;534d   ; B = A + 3 repeticiones
L_534E:
	ld a,(hl)			;534e   ; el byte a repetir
L_534F:
	ld (de),a			;534f   ; al destino
	inc de			;5350   ; siguiente
	djnz L_534F		;5351   ; B veces
	inc hl			;5353   ; ficha siguiente
	pop bc			;5354   ; recupera mascara y valor
	jr L_5335		;5355   ; otra ficha
L_5357:
	ld b,001h		;5357   ; un literal
	jr L_534E		;5359   ; a copiarlo
descomprime_marca:		; Formato c v n: con la marca c, n copias de v; fin con la marca repetida
	inc hl			;535b   ; se salta el primer byte
	ld c,(hl)			;535c   ; C = la marca
	inc hl			;535d   ; primera ficha
L_535E:
	ld a,(hl)			;535e   ; la ficha
	cp c			;535f   ; es la marca?
	jr nz,L_536F		;5360   ; no: literal
	inc hl			;5362   ; el byte siguiente
	cp (hl)			;5363   ; la marca otra vez: fin
	ret z			;5364   ; HL = la segunda marca
	ld a,(hl)			;5365   ; A = el byte a repetir
	inc hl			;5366   ; siguiente
	ld b,(hl)			;5367   ; B = cuantas veces (0 = 256)
L_5368:
	ld (de),a			;5368   ; al destino
	inc de			;5369   ; siguiente
	djnz L_5368		;536a   ; B veces
	inc hl			;536c   ; ficha siguiente
	jr L_535E		;536d   ; otra ficha
L_536F:
	ld b,001h		;536f   ; un literal
	jr L_5368		;5371   ; a copiarlo
descomprime_parejas:		; Parejas de bytes repetidas: cuenta de 12 bits y la pareja; menos de 0x10 en el primero = cuenta
	ld a,(hl)			;5373   ; el primer byte de la ficha
	cp 010h		;5374   ; 0x10 o mas: una sola pareja
	jr nc,L_5396		;5376   ; a copiarla
	ld b,a			;5378   ; cuenta alta
	inc hl			;5379   ; B = alto de la cuenta
	ld c,(hl)			;537a   ; C = bajo
	inc hl			;537b   ; HL = la pareja
	and a			;537c   ; alto a cero?
	jr nz,L_5381		;537d   ; no: cuenta de verdad
	or c			;537f   ; cuenta 0: fin
	ret z			;5380   ; cuenta cero: fin
L_5381:
	inc bc			;5381   ; cuenta + 1
	ld a,(hl)			;5382   ; A = primer byte de la pareja
L_5383:
	inc hl			;5383   ; siguiente
	push hl			;5384   ; guarda el puntero
	ld l,(hl)			;5385   ; L = segundo byte
	ld h,a			;5386   ; H = primero
L_5387:
	ld a,h			;5387   ; el primero
	ld (de),a			;5388   ; al destino
	inc de			;5389   ; siguiente
	ld a,l			;538a   ; el segundo
	ld (de),a			;538b   ; al destino
	inc de			;538c   ; siguiente
	dec bc			;538d   ; una pareja menos
	ld a,b			;538e   ; quedan?
	or c			;538f
	jr nz,L_5387		;5390   ; otra
	pop hl			;5392   ; recupera el puntero
	inc hl			;5393   ; ficha siguiente
	jr descomprime_parejas		;5394   ; otra ficha
L_5396:
	ld bc,00001h		;5396   ; pareja suelta
	jr L_5383		;5399   ; una pareja: a copiarla

; ----------------------------------------------------------------------
; ===== Movimiento de jugadores y balon (servicio de cada cuadro) =====
; ----------------------------------------------------------------------
integra_jugadores:		; Suma la velocidad a la posicion de los seis jugadores y comprueba si han llegado a su destino
	ld ix,0e500h		;539b   ; el primer registro de jugador
	ld b,006h		;539f   ; los seis
	ld c,000h		;53a1   ; C = indice
L_53A3:
	ld l,(ix+000h)		;53a3   ; Y en 8.8 (+0/+1)
	ld h,(ix+001h)		;53a6
	ld e,(ix+004h)		;53a9   ; velocidad Y (+4/+5)
	ld d,(ix+005h)		;53ac
	add hl,de			;53af
	push hl			;53b0
	ld (ix+000h),l		;53b1
	ld (ix+001h),h		;53b4
	ld l,(ix+002h)		;53b7   ; X en 8.8 (+2/+3)
	ld h,(ix+003h)		;53ba
	ld e,(ix+006h)		;53bd   ; velocidad X (+6/+7)
	ld d,(ix+007h)		;53c0
	add hl,de			;53c3
	ld (ix+002h),l		;53c4
	ld (ix+003h),h		;53c7
	pop de			;53ca
	ld e,h			;53cb
	ld h,(ix+020h)		;53cc   ; destino Y (+0x20) y X (+0x21)
	ld l,(ix+021h)		;53cf
	ld a,h			;53d2
	or l			;53d3
	jr z,L_5410		;53d4   ; sin destino
	call diferencia_xy		;53d6
	push bc			;53d9
	call distancia		;53da   ; distancia al destino
	pop bc			;53dd
	cp 006h		;53de   ; a menos de 6: ha llegado
	jr nc,L_5410		;53e0
	xor a			;53e2
	ld (ix+020h),a		;53e3   ; borra el destino
	ld (ix+021h),a		;53e6
	ld (ix+000h),a		;53e9   ; y las fracciones de Y y X
	ld (ix+002h),a		;53ec
	ld a,(0ed5fh)		;53ef   ; SUPOSICION: jugador que toma el control al llegar
	cp c			;53f2
	jr nz,L_5402		;53f3
	ld a,(0ed5fh)		;53f5
	call controla		;53f8
	ld a,0ffh		;53fb   ; atendido
	ld (0ed5fh),a		;53fd
	jr L_5410		;5400
L_5402:
	ld a,(0ed60h)		;5402   ; el del otro equipo
	cp c			;5405
	jr nz,L_5410		;5406
	call controla		;5408
	ld a,0ffh		;540b
	ld (0ed60h),a		;540d
L_5410:
	ld de,00030h		;5410   ; siguiente registro
	add ix,de		;5413
	inc c			;5415
	dec b			;5416
	jp nz,L_53A3		;5417
	ret			;541a
mueve_balon:		; Un paso del balon libre: pase en linea recta, tiro en parabola; al llegar da el balon o resuelve el tiro
	ld hl,0e62ch		;541b   ; gravedad del balon: 0 = en la mano
	ld a,(hl)			;541e
	and a			;541f
	ret z			;5420
	ld a,(0e6f1h)		;5421   ; salto entre dos
	and a			;5424
	jr nz,L_5439		;5425
	ld a,(0e6cfh)		;5427
	and 0c0h		;542a
	jp z,balon_cae		;542c   ; nadie tira ni pasa: bota o rueda
	rlca			;542f
	jr nc,L_5439		;5430   ; pase en vuelo
	ld a,(0e6f9h)		;5432   ; 1 = mate: directo al aro
	dec a			;5435
	jp z,balon_en_el_aro		;5436
L_5439:
	ld a,(0e6cfh)		;5439
	ld hl,(0e620h)		;543c   ; Y del balon
	ld de,(0e624h)		;543f   ; mas velocidad Y
	add hl,de			;5443
	ld (0e620h),hl		;5444
	ld hl,(0e622h)		;5447   ; X del balon
	ld de,(0e626h)		;544a   ; mas velocidad X
	add hl,de			;544e
	ld (0e622h),hl		;544f
	bit 6,a		;5452   ; bit 6: pase
	jr z,L_545C		;5454
	ld hl,0e635h		;5456   ; pasos del pase: llega al pasar por 0
	inc (hl)			;5459
	jr L_547F		;545a
L_545C:
	ld hl,(0e62fh)		;545c   ; altura de la mano en vuelo (+0x0F)
	ld de,(0e631h)		;545f
	add hl,de			;5463
	ld (0e62fh),hl		;5464
	ld hl,(0e62ah)		;5467   ; velocidad vertical
	ld a,(0e62ch)		;546a   ; menos la gravedad
	call extiende_signo		;546d
	sbc hl,de		;5470
	ld (0e62ah),hl		;5472
	ex de,hl			;5475
	ld hl,(0e628h)		;5476   ; Z menos velocidad
	and a			;5479
	sbc hl,de		;547a
	ld (0e628h),hl		;547c
L_547F:
	ret m			;547f   ; todavia en el aire
	ld a,(0e6cfh)		;5480
	bit 7,a		;5483
	jr nz,balon_en_el_aro		;5485   ; tiro: llega al aro
	ld a,(0e6f1h)		;5487
	and a			;548a
	ret nz			;548b
	call balon_quieto		;548c   ; balon parado
	ld a,(0e6fdh)		;548f   ; el receptor del pase
	call da_balon		;5492
	ld hl,0e6cfh		;5495
	res 6,(hl)		;5498   ; pase acabado
	ret			;549a
balon_quieto:		; Sin receptor y toda la fisica del balon a cero
	ld a,0ffh		;549b
	ld (0e6e3h),a		;549d
para_balon:		; Fisica del balon a cero (posicion fina, velocidades, altura, pasos)
	xor a			;54a0
	ld l,a			;54a1
	ld h,a			;54a2
	ld (0e62ch),a		;54a3   ; gravedad: balon en la mano
	ld (0e620h),a		;54a6   ; fracciones de Y y X
	ld (0e622h),a		;54a9
	ld (0e62fh),hl		;54ac   ; altura de la mano en vuelo
	ld (0e624h),hl		;54af   ; velocidad Y
	ld (0e626h),hl		;54b2   ; velocidad X
	ld (0e631h),hl		;54b5
	ld (0e628h),hl		;54b8   ; Z
	ld (0e62ah),hl		;54bb   ; velocidad vertical
	ld (0e635h),a		;54be   ; pasos del pase
	ret			;54c1
poseedor_salto:		; SUPOSICION: en el salto entre dos el balon va al de 0xE6E3
	ld a,(0e6e3h)		;54c2
	ld (0e6cfh),a		;54c5
	ret			;54c8
balon_en_el_aro:		; El tiro llega a la canasta: si entra suma los puntos y cae por la red; si no, rebota en el aro
	ld a,(0e6f1h)		;54c9
	and a			;54cc
	jr nz,poseedor_salto		;54cd
	ld hl,0e6cfh		;54cf
	res 7,(hl)		;54d2   ; ya no esta en vuelo
	ld a,(0ed63h)		;54d4
	and a			;54d7
	jr z,resuelve_tiro		;54d8
	ld a,0ffh		;54da   ; SUPOSICION: nadie ha tirado
	ld (0e6dfh),a		;54dc
resuelve_tiro:		; Canasta o aro segun 0xE6F9
	ld hl,00000h		;54df
	ld (0e62fh),hl		;54e2
	ld (0e631h),hl		;54e5
	ld a,(0e6f9h)		;54e8   ; bit 7: fallo
	rlca			;54eb
	jr c,rebote_en_aro		;54ec
	call suma_canasta		;54ee   ; suma la canasta a las estadisticas del tirador
	call pinta_puntos		;54f1   ; puntos al marcador
	ld a,001h		;54f4   ; pieza 1: canasta
	call arranca_sonido		;54f6
	ld a,001h		;54f9   ; canasta hecha
	ld (0ed63h),a		;54fb
	ld (0e626h),hl		;54fe   ; balon sin velocidad horizontal
	ld (0e624h),hl		;5501
	ld a,0ffh		;5504
	ld (0ed62h),a		;5506
	ld hl,(0e62ah)		;5509   ; cae a un cuarto de la velocidad
	call niega_hl		;550c
	rr h		;550f
	rr l		;5511
	and a			;5513
	rr h		;5514
	rr l		;5516
	call niega_hl		;5518
	ld (0e62ah),hl		;551b
	ld a,004h		;551e   ; cuatro botes en el suelo
	ld (0e6f7h),a		;5520
	ld a,0cch		;5523   ; altura del aro
	ld (0e629h),a		;5525
	neg		;5528
	ld (0e6f8h),a		;552a
	ld a,00ah		;552d   ; arranca la animacion de la red
	ld (0e634h),a		;552f
	xor a			;5532
	ld (0e633h),a		;5533
	ret			;5536
rebote_en_aro:		; El balon da en el aro: pieza 7, velocidades a un octavo y rebote segun el tipo de fallo
	ld a,007h		;5537   ; pieza 7: aro
	call arranca_sonido		;5539
	ld a,0cch		;553c   ; altura del aro
	ld (0e629h),a		;553e
	ld hl,(0e624h)		;5541   ; velocidad Y a un octavo
	call octavo		;5544
	ld a,(0e6f9h)		;5547   ; tipo de fallo (bits bajos)
	and 07fh		;554a
	cp 001h		;554c
	call z,cero_hl		;554e   ; 1: cae recto
	cp 002h		;5551
	call z,niega_hl		;5553   ; 2: vuelve hacia atras
	ld (0e624h),hl		;5556
	ld hl,(0e626h)		;5559   ; velocidad X a un octavo y al reves
	call octavo		;555c
	call niega_hl		;555f
	ld (0e626h),hl		;5562
	ld hl,(0e62ah)		;5565   ; sube a la mitad de la velocidad de caida
	call niega_hl		;5568
	and a			;556b
	rr h		;556c
	rr l		;556e
	ld (0e62ah),hl		;5570
	ret			;5573
octavo:		; HL/8 con signo
	ld a,h			;5574   ; signo
	and a			;5575
	push af			;5576
	rr h		;5577   ; tres desplazamientos: entre 8
	rr l		;5579
	rr h		;557b
	rr l		;557d
	rr h		;557f
	rr l		;5581
	pop af			;5583
	jp m,L_558C		;5584
	ld a,01fh		;5587   ; positivo: tres bits altos a 0
	and h			;5589
	ld h,a			;558a
	ret			;558b
L_558C:
	ld a,0e0h		;558c
	or h			;558e
	ld h,a			;558f
	ret			;5590
balon_cae:		; Balon sin poseedor ni vuelo: cae y bota en el suelo; tras los botes se queda quieto
	ld a,(0e62ch)		;5591
	and a			;5594
	ret z			;5595
	ld a,(0e6cfh)		;5596
	bit 7,a		;5599   ; tiro en vuelo
	ret nz			;559b
	bit 6,a		;559c   ; pase en vuelo
	ret nz			;559e
	ld a,(0e6f9h)		;559f
	bit 7,a		;55a2   ; rebote libre: rueda por la pista
	jr nz,rebote_libre		;55a4
	ld hl,(0e62ah)		;55a6   ; velocidad vertical menos gravedad
	ld a,(0e62ch)		;55a9
	call extiende_signo		;55ac
	and a			;55af
	sbc hl,de		;55b0
	ld (0e62ah),hl		;55b2
	ex de,hl			;55b5
	ld hl,(0e628h)		;55b6   ; Z menos velocidad
	and a			;55b9
	sbc hl,de		;55ba
	ld (0e628h),hl		;55bc
	ret m			;55bf   ; sigue en el aire
	ld a,(0e6f7h)		;55c0   ; botes que quedan
	and a			;55c3
	jr z,L_55E1		;55c4
	dec a			;55c6
	cp 003h		;55c7
	ld (0e6f7h),a		;55c9
	jr nz,L_55D3		;55cc
	ld a,002h		;55ce   ; pieza 2: bote del balon
	call arranca_sonido		;55d0
L_55D3:
	ex de,hl			;55d3
	call rebote_amortiguado		;55d4   ; rebota con tres cuartos de la velocidad
	ld (0e62ah),hl		;55d7
	ld hl,00000h		;55da   ; en el suelo
	ld (0e628h),hl		;55dd
	ret			;55e0
L_55E1:
	call para_balon		;55e1   ; sin botes: balon parado
	ld a,0ffh		;55e4
	ld (0e6f7h),a		;55e6
	ld (0e6f9h),a		;55e9
	ret			;55ec
rebote_libre:		; Balon suelto tras un fallo: avanza, bota con perdida y se frena; si sale por los lados lo recoge el controlado
	ld hl,(0e622h)		;55ed
	ld de,(0e626h)		;55f0
	add hl,de			;55f4
	ld (0e622h),hl		;55f5
	ld hl,(0e620h)		;55f8   ; Y del balon
	ld de,(0e624h)		;55fb
	add hl,de			;55ff
	ld (0e620h),hl		;5600
	ld a,h			;5603
	cp 008h		;5604   ; fuera por un lado
	jr c,balon_fuera		;5606
	cp 06ch		;5608   ; fuera por el otro
	jr nc,balon_fuera		;560a
	ld hl,(0e62ah)		;560c   ; cae con la gravedad
	ld a,(0e62ch)		;560f
	call extiende_signo		;5612
	sbc hl,de		;5615
	ld (0e62ah),hl		;5617
	ex de,hl			;561a
	ld hl,(0e628h)		;561b
	and a			;561e
	sbc hl,de		;561f
	ld (0e628h),hl		;5621
	ret m			;5624   ; en el aire
	ld hl,00000h		;5625   ; toca el suelo
	ld (0e628h),hl		;5628
	ex de,hl			;562b
	call rebote_amortiguado		;562c   ; rebote con tres cuartos
	ld (0e62ah),hl		;562f
	ld a,(0ed61h)		;5632   ; SUPOSICION: los que iban a por el balon apuntan a donde bota
	call persigue_balon		;5635
	ld a,(0ed62h)		;5638
	call persigue_balon		;563b
	ld hl,(0e626h)		;563e   ; frena la velocidad X
	call frena		;5641
	ld (0e626h),hl		;5644
	push hl			;5647
	ld hl,(0e624h)		;5648   ; frena la velocidad Y
	call frena		;564b
	ld (0e624h),hl		;564e
	pop de			;5651
	ld a,h			;5652   ; todo a cero: balon parado
	or l			;5653
	or d			;5654
	or e			;5655
	ret nz			;5656
	xor a			;5657
	ld (0e62ch),a		;5658
	ld (0e62ah),hl		;565b
	ret			;565e
persigue_balon:		; Si A es un jugador, le da como destino el balon
	and a			;565f
	ld de,0e620h		;5660
	call p,destino_punto		;5663
	ret			;5666
frena:		; Acerca HL a cero en una unidad
	ld a,h			;5667
	or l			;5668
	ret z			;5669   ; ya es cero
	ld a,h			;566a
	call extiende_signo		;566b   ; DE = 0 o 0xFFFF segun el signo
	ld a,d			;566e
	or e			;566f
	jr nz,L_5673		;5670
	inc de			;5672   ; positivo: DE = 1
L_5673:
	ex de,hl			;5673
	call niega_hl		;5674
	add hl,de			;5677
	ret			;5678
balon_fuera:		; Balon fuera por un lado: lo recibe el controlado del equipo con el balon
	ld a,0ffh		;5679   ; 0xFF: sin tiro pendiente
	ld (0e6f9h),a		;567b
	call para_balon		;567e   ; balon parado
	ld (0e626h),hl		;5681
	ld (0e624h),hl		;5684
	call controlado		;5687   ; controlado del equipo con el balon
	ld (0e6cfh),a		;568a   ; pasa a tener el balon
	ret			;568d
rebote_amortiguado:		; HL = tres cuartos de abs(HL)
	ld a,h			;568e
	and a			;568f
	call m,niega_hl		;5690   ; valor absoluto
	push hl			;5693
	srl h		;5694   ; entre 4
	rr l		;5696
	srl h		;5698
	rr l		;569a
	ex de,hl			;569c
	pop hl			;569d
	and a			;569e
	sbc hl,de		;569f   ; menos un cuarto
	ret			;56a1
lanza_pase:		; Balon del poseedor IX al receptor IY: posiciones de la mano, velocidad y numero de pasos
	push ix		;56a2
	ld a,0f0h		;56a4   ; altura del balon en la mano
	ld (0e62dh),a		;56a6
	ld a,(0e6e3h)		;56a9   ; receptor
	ld (0e6fdh),a		;56ac
	call registro_jugador		;56af
	pop de			;56b2
	call xy_dos_registros		;56b3
	call manos		;56b6   ; mas el desplazamiento de las manos
	call balon_en_de		;56b9   ; balon en la mano del que pasa
	call velocidades_vuelo		;56bc   ; velocidades del pase
	ld a,l			;56bf
	neg		;56c0
	jr z,L_56C5		;56c2
	dec a			;56c4
L_56C5:
	scf			;56c5
	rra			;56c6
	ld (0e635h),a		;56c7   ; pasos negativos hasta llegar
	ex de,hl			;56ca
	ld a,00fh		;56cb   ; gravedad: balon libre
	ld (0e62ch),a		;56cd
	jp altura_inicial		;56d0
balon_en_de:		; Balon en Y = D y X = E, fracciones a cero
	ld a,d			;56d3
	ld (0e621h),a		;56d4   ; Y del balon
	ld a,e			;56d7
	ld (0e623h),a		;56d8   ; X del balon
	xor a			;56db
	ld (0e620h),a		;56dc   ; fracciones a cero
	ld (0e622h),a		;56df
	ret			;56e2
manos:		; Suma a DE y HL el desplazamiento de la mano de IX y de IY segun su direccion
	ld a,(ix+015h)		;56e3   ; direccion del que pasa
	call mano		;56e6   ; desplazamiento de su mano
	ld a,c			;56e9
	add a,e			;56ea   ; X mas dx
	ld e,a			;56eb
	ld a,b			;56ec
	add a,d			;56ed   ; Y mas dy
	ld d,a			;56ee
	ld a,(iy+015h)		;56ef   ; direccion del receptor
	call mano		;56f2   ; desplazamiento de su mano
	ld a,c			;56f5
	add a,l			;56f6
	ld l,a			;56f7
	ld a,b			;56f8
	add a,h			;56f9
	ld h,a			;56fa
	ret			;56fb
mano:		; BC = desplazamiento (dx, dy) de la tabla 0x4C0D para la direccion A
	push de			;56fc
	push hl			;56fd
	add a,a			;56fe   ; dos bytes por direccion
	ld e,a			;56ff
	ld d,000h		;5700
	ld hl,04c0dh		;5702   ; tabla de manos
	add hl,de			;5705
	ld b,(hl)			;5706   ; B = dy
	inc hl			;5707
	ld c,(hl)			;5708   ; C = dx
	pop hl			;5709
	pop de			;570a
	ret			;570b
tiro:		; Lanza el tiro a canasta del jugador en curso: desvio, velocidades y altura inicial
	ld a,(0e6f1h)		;570c
	and a			;570f
	jr nz,L_571B		;5710
	ld a,(0e62ch)		;5712   ; balon ya libre
	and a			;5715
	ret nz			;5716
	xor a			;5717   ; no hay pasos
	ld (0e6f6h),a		;5718
L_571B:
	ld a,(0e721h)		;571b
	ld (0e6fch),a		;571e   ; SUPOSICION: autor del tiro
	ld a,001h		;5721
	ld (0ed79h),a		;5723   ; SUPOSICION: canasta pendiente de anotar
	call desvio_tiro		;5726   ; desvio del tiro (0 si entra)
	ld de,0e620h		;5729   ; del balon a la canasta
	ld hl,0e6c3h		;572c
	call xy_dos_registros		;572f
	add a,h			;5732   ; desvio en Y (a lo ancho)
	ld h,a			;5733
	call velocidades_vuelo		;5734   ; velocidades Y y X
	push hl			;5737
	ld a,(0e62dh)		;5738
	call subida_mano		;573b   ; velocidad de subida de la mano
	ld (0e631h),hl		;573e
	ld a,00fh		;5741   ; gravedad
	ld (0e62ch),a		;5743
	pop de			;5746
	call velocidad_tiro		;5747   ; velocidad vertical del tiro
	ld (0e62ah),hl		;574a
altura_inicial:		; Altura de la mano a 0xE62F y Z del balon a 0
	ld a,(0e62dh)		;574d   ; altura del balon en la mano
	ld d,a			;5750
	ld e,000h		;5751
	ld (0e62fh),de		;5753   ; como altura de vuelo 8.8
	xor a			;5757
	ld (0e62dh),a		;5758   ; balon fuera de la mano
	ld hl,00000h		;575b
	ld (0e628h),hl		;575e   ; Z = 0
	ret			;5761
velocidades_vuelo:		; Velocidades Y y X del balon para llegar en (0xE6FA) pasos; el pase va al doble
	call componentes		;5762
	push hl			;5765
	ld hl,0e6cfh		;5766
	bit 6,(hl)		;5769
	pop hl			;576b
	call nz,dobla		;576c   ; pase: el doble de rapido
	ld (0e624h),de		;576f
	ld (0e626h),hl		;5773
	ld h,a			;5776
	ld l,000h		;5777
	ld de,(0e6fah)		;5779
	call divide16		;577d   ; SUPOSICION: paso fino
	ld a,l			;5780
	and a			;5781
	ret p			;5782
	inc h			;5783
	ret			;5784
dobla:		; HL y DE por 2
	add hl,hl			;5785
	ex de,hl			;5786
	add hl,hl			;5787
	ex de,hl			;5788
	ret			;5789
subida_mano:		; Velocidad de la altura de la mano hasta la del aro (0xCC) o la del salto entre dos (0xF0)
	neg		;578a   ; altura de partida negada
	push af			;578c
	ld a,(0e6f1h)		;578d   ; salto entre dos?
	and a			;5790
	ld c,0cch		;5791   ; altura del aro
	jr z,L_5797		;5793
	ld c,0f0h		;5795   ; altura del palmeo
L_5797:
	pop af			;5797
	add a,c			;5798   ; diferencia de alturas
	jr z,L_57AB		;5799   ; ninguna: velocidad 0
	push af			;579b
	ld d,a			;579c
	ld e,000h		;579d
	ex de,hl			;579f
	call m,niega_hl		;57a0
	call divide16		;57a3   ; entre el tiempo de vuelo
	pop af			;57a6
	call m,niega_hl		;57a7   ; con el signo de la diferencia
	ret			;57aa
L_57AB:
	ld hl,00000h		;57ab
	ret			;57ae
componentes:		; Distancia y rumbo hacia el destino y sus componentes por seno y coseno
	call tiempo_vuelo		;57af   ; distancia y tiempo
	push af			;57b2
	ld e,b			;57b3
	ld l,c			;57b4
	call angulo		;57b5   ; angulo del vector
	push af			;57b8
	ld hl,(0e6fah)		;57b9   ; tiempo de vuelo
	call por_tabla_c2_desfase		;57bc   ; componente Y
	pop af			;57bf
	push hl			;57c0
	ld hl,(0e6fah)		;57c1
	call por_tabla_c2		;57c4   ; componente X
	pop de			;57c7
	pop af			;57c8
	ret			;57c9
por_tabla_c2:		; HL por el valor con signo de la tabla 0xC200 en A (SUPOSICION: seno)
	push hl			;57ca
	call tabla_c2		;57cb
	jr L_57D4		;57ce
por_tabla_c2_desfase:		; HL por el valor de la tabla 0xC200 en A-0x40 (SUPOSICION: coseno)
	push hl			;57d0
	call tabla_c2_desfase		;57d1
L_57D4:
	ld a,d			;57d4   ; signo del factor
	and a			;57d5
	pop hl			;57d6
	push af			;57d7
	ld d,000h		;57d8
	call multiplica16		;57da   ; tiempo por el factor
	ld l,h			;57dd   ; entre 256
	ld h,000h		;57de
	pop af			;57e0
	ret p			;57e1
	jp niega_hl		;57e2   ; negativo
velocidad_tiro:		; Velocidad vertical a partir del tiempo de vuelo
	call multiplica		;57e5
	and a			;57e8
	rr h		;57e9
	rr l		;57eb
	ret			;57ed
desvio_tiro:		; 0 en el salto entre dos; si no, decide si el tiro entra
	ld a,(0e6f1h)		;57ee
	and a			;57f1
	jr z,probabilidad_tiro		;57f2
	xor a			;57f4
	ret			;57f5
probabilidad_tiro:		; Probabilidad de canasta segun la distancia, el tirador (roster campo 0x21) y la defensa; A = desvio (0, 3 o -3)
	push ix		;57f6
	pop de			;57f8
	ld hl,0e6c3h		;57f9   ; distancia a la canasta
	call xy_dos_registros		;57fc
	call tiempo_vuelo		;57ff
	push af			;5802
	ld a,(0e83ch)		;5803
	rrca			;5806
	ld l,(ix+01fh)		;5807
	or l			;580a
	ld (0efcdh),a		;580b   ; equipo y jugador para 0x7E61
	ld h,000h		;580e
	add hl,hl			;5810
	ex de,hl			;5811
	ld c,021h		;5812   ; campo 0x21: punteria por distancia
	call campo_equipo		;5814
	add hl,de			;5817
	ld b,(hl)			;5818
	ld c,(ix+01ah)		;5819   ; SUPOSICION: punteria del jugador (+0x1A)
	pop af			;581c
	call probabilidad		;581d   ; probabilidad
	call dado_tiro		;5820   ; tira el dado
	jp z,cuenta_tiro		;5823
	call aleatorio		;5826   ; fallo: desvio a un lado o al otro
	bit 7,a		;5829
	jr z,L_5830		;582b
	ld a,003h		;582d
	ret			;582f
L_5830:
	ld a,0fdh		;5830
	ret			;5832
cuenta_tiro:		; Marca el tiro (bit 0 de 0xEFDE) y apunta su valor con 0x772E
	push af			;5833
	push hl			;5834
	ld hl,0efdeh		;5835   ; bandera de tiros
	set 0,(hl)		;5838   ; bit 0: hubo tiro
	call anota_tiro		;583a   ; apunta su valor
	pop hl			;583d
	pop af			;583e
	ret			;583f
tiempo_vuelo:		; A = distancia a destino; (0xE6FA) = pasos de vuelo: 2d+50 en el tiro, 255 en el pase
	call diferencia_xy		;5840   ; diferencias Y y X
	ld b,e			;5843
	ld c,l			;5844
	push bc			;5845
	call distancia		;5846   ; distancia
	pop bc			;5849
	push af			;584a
	ld hl,0e6cfh		;584b
	bit 6,(hl)		;584e   ; pase?
	jr nz,L_585A		;5850
	add a,a			;5852   ; tiro: 2 * distancia + 50
	add a,032h		;5853
	ld l,a			;5855
	ld h,000h		;5856
	jr nc,L_585D		;5858   ; sin desbordar
L_585A:
	ld hl,000ffh		;585a
L_585D:
	ld (0e6fah),hl		;585d
	pop af			;5860
	ret			;5861
probabilidad:		; Probabilidad de 0 a 255 a partir de la distancia y la punteria, menos la defensa
	push af			;5862
	ld a,c			;5863   ; punteria (C)
	cpl			;5864   ; invertida
	srl a		;5865   ; entre 8
	srl a		;5867
	srl a		;5869
	ld l,a			;586b
	pop af			;586c
	add a,l			;586d   ; mas la distancia
	ld e,a			;586e
	push bc			;586f
	call multiplica		;5870   ; por la distancia
	ld b,005h		;5873   ; entre 32
L_5875:
	srl h		;5875
	rr l		;5877
	djnz L_5875		;5879
	pop bc			;587b
	ld e,b			;587c   ; campo del roster (B)
	srl e		;587d   ; entre 8
	srl e		;587f
	srl e		;5881
	ld d,000h		;5883
	add hl,de			;5885   ; suma
	call defensa		;5886   ; penalizacion por la defensa
	ex de,hl			;5889
	ld hl,000ffh		;588a   ; 255 menos la dificultad
	and a			;588d
	sbc hl,de		;588e
	ld a,l			;5890
	ret nc			;5891   ; no negativa
	xor a			;5892   ; imposible: 0
	ret			;5893
defensa:		; Penalizacion del tiro segun la cercania del defensor emparejado (+0x25) y si salta mas alto
	push hl			;5894
	ld a,(ix+025h)		;5895   ; defensor emparejado
	call registro_jugador		;5898
	push hl			;589b
	pop iy		;589c
	ld e,(iy+001h)		;589e
	ld d,(iy+003h)		;58a1
	ld l,(ix+001h)		;58a4
	ld h,(ix+003h)		;58a7
	call distancia_aprox		;58aa
	pop hl			;58ad
	sub 00dh		;58ae   ; a menos de 13
	ret nc			;58b0
	neg		;58b1
	add a,a			;58b3   ; (13 - d) por 16
	add a,a			;58b4
	add a,a			;58b5
	add a,a			;58b6
	ld e,a			;58b7
	ld d,000h		;58b8
	add hl,de			;58ba
	ld a,(iy+00ch)		;58bb   ; el defensor salta: 32 mas
	and a			;58be
	ret z			;58bf
	ld de,00020h		;58c0
	add hl,de			;58c3
	push hl			;58c4
	ld a,(ix+009h)		;58c5   ; y si esta mas alto, 32 mas
	cp (iy+009h)		;58c8
	jr c,L_58D9		;58cb
	jr nz,L_58D7		;58cd
	ld a,(ix+008h)		;58cf
	cp (iy+008h)		;58d2
	jr c,L_58D9		;58d5
L_58D7:
	pop hl			;58d7
	ret			;58d8
L_58D9:
	pop hl			;58d9
	ld de,00020h		;58da
	add hl,de			;58dd
	ret			;58de
distancia_aprox:		; Distancia aproximada entre dos puntos
	ld a,e			;58df   ; diferencia de Y
	sub l			;58e0
	ld e,a			;58e1
	ld l,000h		;58e2
	ld a,d			;58e4   ; X del primero
	bit 7,a		;58e5   ; negativa?
	jr z,L_58EC		;58e7
	neg		;58e9
	inc l			;58eb   ; un signo negativo mas
L_58EC:
	ld d,a			;58ec   ; valor absoluto
	ld a,h			;58ed   ; X del segundo
	bit 7,a		;58ee
	jr z,L_58F5		;58f0
	neg		;58f2
	inc l			;58f4   ; un signo negativo mas
L_58F5:
	bit 0,l		;58f5
	jr z,L_58FC		;58f7
	add a,d			;58f9
	jr L_58FD		;58fa
L_58FC:
	sub d			;58fc
L_58FD:
	ld l,a			;58fd
	jp distancia		;58fe
dado_tiro:		; Compara la probabilidad A con el azar: 0xE6F9 = 0 canasta, 0x80 + tipo de rebote si falla
	push af			;5901
	call aleatorio		;5902   ; avanza el azar
	pop af			;5905
	ld hl,(0e6feh)		;5906   ; azar en L
	cp l			;5909   ; probabilidad mayor o igual: canasta
	jr nc,L_5916		;590a
	ld a,l			;590c   ; fallo: tipo de rebote de 0 a 3
	and 003h		;590d
	jr z,L_5912		;590f
	dec a			;5911   ; tipo 1-3 a 0-2
L_5912:
	or 080h		;5912
	jr L_5917		;5914
L_5916:
	xor a			;5916
L_5917:
	ld (0e6f9h),a		;5917
	ret			;591a
absolutos:		; L y E en valor absoluto
	ld a,l			;591b
	and a			;591c
	jp p,L_5923		;591d
	neg		;5920
	ld l,a			;5922
L_5923:
	ld a,e			;5923   ; abs de E
	and a			;5924
	ret p			;5925
	neg		;5926   ; negativo: se invierte
	ld e,a			;5928
	ret			;5929
cuadrados:		; HL = L al cuadrado y DE = E al cuadrado (tablas 0xC000/0xC100)
	ld h,0c0h		;592a   ; tablas de cuadrados en 0xC000/0xC100
	ld d,h			;592c
	ld a,(hl)			;592d   ; byte bajo de L al cuadrado
	inc h			;592e
	ld h,(hl)			;592f   ; byte alto
	ld l,a			;5930
	ld a,(de)			;5931   ; byte bajo de E al cuadrado
	ld c,a			;5932
	inc d			;5933
	ld a,(de)			;5934   ; byte alto
	ld d,a			;5935
	ld e,c			;5936
	ret			;5937
raiz:		; Raiz cuadrada de HL por busqueda binaria en la tabla de cuadrados
	xor a			;5938
	ld b,080h		;5939
	ex de,hl			;593b
L_593C:
	sub b			;593c   ; prueba bajando el paso B
	cp 080h		;593d
	ld l,a			;593f
	ld h,0c0h		;5940   ; cuadrado del candidato
	ld a,e			;5942
	sub (hl)			;5943   ; DE menos el cuadrado
	ld c,a			;5944
	inc h			;5945
	ld a,d			;5946
	sbc a,(hl)			;5947
	jr nc,L_5953		;5948   ; cabe: sube
	or c			;594a   ; exacto: es la raiz
	ld a,l			;594b
	ret z			;594c
	srl b		;594d   ; paso a la mitad
	jr nz,L_593C		;594f
	dec a			;5951   ; se pasa: uno menos
	ret			;5952
L_5953:
	or c			;5953   ; exacto?
	ld a,l			;5954
	ret z			;5955
	srl b		;5956   ; paso a la mitad
	jr nz,$-26		;5958
	ret			;595a
angulo:		; Angulo de 0 a 255 del vector (L, E) con la tabla de arcotangentes 0xC300
	ld a,e			;595b   ; signos de E y L
	rla			;595c
	ld a,l			;595d
	rla			;595e
	rla			;595f
	and 003h		;5960   ; cuadrante en A'
	ex af,af'			;5962
	call absolutos		;5963   ; valores absolutos
	ld a,e			;5966
	cp l			;5967   ; iguales: 45 grados
	jr z,L_599C		;5968
	jr c,L_596D		;596a
	ex de,hl			;596c   ; el menor en E
L_596D:
	push af			;596d
	ld bc,00800h		;596e
	ld a,e			;5971
L_5972:
	sla c		;5972
	add a,a			;5974
	jr c,L_597A		;5975
	cp l			;5977
	jr c,L_597C		;5978
L_597A:
	sub l			;597a
	inc c			;597b
L_597C:
	djnz L_5972		;597c
	pop af			;597e
	ld b,0c3h		;597f   ; tabla de arcotangentes 0xC300
	ld a,(bc)			;5981   ; angulo dentro del octante
	jr nc,L_5988		;5982
	sub 040h		;5984   ; complemento si se cambiaron
	neg		;5986
L_5988:
	ld c,a			;5988   ; C = angulo del octante
	ex af,af'			;5989   ; cuadrante
	jr z,L_5994		;598a
	dec a			;598c
	jr z,L_5998		;598d
	dec a			;598f
	ld a,080h		;5990   ; media vuelta
	jr z,L_5998		;5992
L_5994:
	sub c			;5994
	add a,080h		;5995
	ret			;5997
L_5998:
	add a,c			;5998
	add a,080h		;5999
	ret			;599b
L_599C:
	and a			;599c
	jr z,L_59A3		;599d
	ld a,020h		;599f
	jr L_5988		;59a1
L_59A3:
	ld a,040h		;59a3
	ret			;59a5
distancia:		; A = raiz de (dx2 + dy2) de la diferencia HL, como mucho 0x7F
	call absolutos		;59a6   ; abs de las diferencias
	call cuadrados		;59a9   ; cuadrados
	add hl,de			;59ac   ; dx2 + dy2
	call raiz		;59ad   ; raiz
	and a			;59b0
	ret p			;59b1
	ld a,07fh		;59b2   ; tope 0x7F
	ret			;59b4
multiplica:		; HL = A * E sin signo
	ld l,a			;59b5
	xor a			;59b6
	ex af,af'			;59b7
	jr L_59C0		;59b8
multiplica_signo_huerfano:		; Huerfano: multiplicaria A * E con el signo de los dos
	ld l,a			;59ba
	xor e			;59bb
	ex af,af'			;59bc
	call absolutos		;59bd
L_59C0:
	ld a,e			;59c0
	cp l			;59c1
	jr c,L_59C6		;59c2
	ex de,hl			;59c4
	ld a,e			;59c5
L_59C6:
	ld e,l			;59c6
	ld h,000h		;59c7
	ld d,h			;59c9
	ld b,008h		;59ca
L_59CC:
	add a,a			;59cc
	jr c,L_59D9		;59cd
	djnz L_59CC		;59cf
	ld l,h			;59d1
	jr L_59DB		;59d2
L_59D4:
	add hl,hl			;59d4
	rla			;59d5
	jr nc,L_59D9		;59d6
	add hl,de			;59d8
L_59D9:
	djnz L_59D4		;59d9
L_59DB:
	ex af,af'			;59db   ; signo del resultado
	jp p,L_59E6		;59dc
	xor a			;59df   ; negativo: HL = -HL
	sub l			;59e0
	ld l,a			;59e1
	sbc a,a			;59e2
	sub h			;59e3
	ld h,a			;59e4
	ret			;59e5
L_59E6:
	ld a,h			;59e6
	ret			;59e7
multiplica_d_huerfano:		; Huerfano: multiplicaria con el signo de D
	ld l,a			;59e8
	ld a,d			;59e9
	and a			;59ea
	ex af,af'			;59eb
	jr L_59C0		;59ec
multiplica16:		; HL = DE * HL (16 bits)
	ld c,l			;59ee
	ld a,h			;59ef
	ld hl,00000h		;59f0
	ld b,010h		;59f3
L_59F5:
	add hl,hl			;59f5
	sla c		;59f6
	rla			;59f8
	jr nc,L_59FC		;59f9
	add hl,de			;59fb
L_59FC:
	djnz L_59F5		;59fc
	ret			;59fe
divide16:		; HL = HL / DE
	ld c,h			;59ff
	ld a,l			;5a00
	ld hl,00000h		;5a01
	ld b,010h		;5a04
L_5A06:
	add a,a			;5a06   ; bit siguiente del dividendo
	rl c		;5a07
	adc hl,hl		;5a09   ; al resto
	push hl			;5a0b
	and a			;5a0c
	sbc hl,de		;5a0d   ; resto menos divisor
	jr c,L_5A13		;5a0f   ; no cabe
	inc a			;5a11   ; bit 1 en el cociente
	ex (sp),hl			;5a12
L_5A13:
	pop hl			;5a13
	djnz L_5A06		;5a14
	ld l,a			;5a16
	ld h,c			;5a17
	ret			;5a18
divide8:		; L = HL / D (8 pasos)
	push bc			;5a19
	ld e,000h		;5a1a
	ld b,008h		;5a1c
L_5A1E:
	add hl,hl			;5a1e   ; siguiente paso
	and a			;5a1f
	sbc hl,de		;5a20   ; resta el divisor
	inc hl			;5a22   ; bit del cociente
	jp p,L_5A29		;5a23
	add hl,de			;5a26   ; no cabia: se repone
	res 0,l		;5a27
L_5A29:
	djnz L_5A1E		;5a29
	pop bc			;5a2b
	ret			;5a2c
aleatorio:		; Generador pseudoaleatorio de 16 bits en (0xE6FE): cuatro pasos de registro de desplazamiento; devuelve el byte bajo en A
	push bc			;5a2d
	push hl			;5a2e
	ld b,004h		;5a2f
	ld hl,(0e6feh)		;5a31   ; semilla
L_5A34:
	add hl,hl			;5a34   ; desplaza la semilla
	rla			;5a35
	rla			;5a36
	xor l			;5a37   ; mezcla de bits
	rla			;5a38
	xor l			;5a39
	srl a		;5a3a
	srl a		;5a3c
	cpl			;5a3e   ; bit nuevo
	and 001h		;5a3f
	or l			;5a41   ; entra por la derecha
	ld l,a			;5a42
	djnz L_5A34		;5a43   ; cuatro bits nuevos
	ld (0e6feh),hl		;5a45   ; semilla nueva
	ld a,l			;5a48   ; A = byte bajo
	pop hl			;5a49
	pop bc			;5a4a
	ret			;5a4b
tabla_c2_desfase:		; DE = valor con signo de la tabla 0xC200 en A-0x40
	sub 040h		;5a4c
tabla_c2:		; DE = valor con signo de la tabla 0xC200 en A
	ld l,a			;5a4e
	ld h,0c2h		;5a4f   ; tabla 0xC200
	ld e,(hl)			;5a51   ; valor
	ld d,000h		;5a52
	and a			;5a54
	ret p			;5a55   ; positivo
	dec d			;5a56   ; negativo: D = 0xFF
	ret			;5a57
tablas_mates:		; Tablas de 0xC000: cuadrados (0xC000 bajo, 0xC100 alto), curva simetrica 0xC200 y arcotangentes 0xC300
	ld hl,0c000h		;5a58   ; 0xC000: la tabla de 256 palabras (bajo en 0xC0xx, alto en 0xC1xx)
L_5A5B:
	push hl			;5a5b   ; guarda la posicion
	ld a,l			;5a5c   ; A = indice 0-255
	ld e,a			;5a5d   ; E = indice
	call multiplica		;5a5e   ; n por n
	ex de,hl			;5a61   ; DE = el valor
	pop hl			;5a62   ; recupera la posicion
	ld (hl),e			;5a63   ; byte bajo del cuadrado en 0xC000
	inc h			;5a64   ; 0xC1xx
	ld (hl),d			;5a65   ; byte alto en 0xC100
	dec h			;5a66   ; 0xC0xx
	inc l			;5a67   ; siguiente indice
	jr nz,L_5A5B		;5a68   ; los 256
	xor a			;5a6a   ; A = 0: el primer valor
	ld de,0c300h		;5a6b   ; arcotangentes en 0xC300
	ld hl,05a96h		;5a6e   ; cuantas veces sale cada valor (0x5A96)
L_5A71:
	ld b,(hl)			;5a71   ; B = longitud del tramo
L_5A72:
	ld (de),a			;5a72   ; el valor, B veces
	inc e			;5a73   ; siguiente posicion
	djnz L_5A72		;5a74   ; el tramo
	inc hl			;5a76   ; siguiente longitud
	inc a			;5a77   ; valor siguiente
	cp 021h		;5a78   ; valores 0 a 0x20
	jr nz,L_5A71		;5a7a   ; hasta 0x21: 33 tramos
	and a			;5a7c   ; sin acarreo para el ultimo byte
	ld bc,05af6h		;5a7d   ; curva leida al reves desde 0x5AF6
	ld de,0c240h		;5a80   ; mitad de arriba desde 0xC240
	ld hl,0c23fh		;5a83   ; mitad de abajo desde 0xC23F
L_5A86:
	ld a,(bc)			;5a86   ; un byte de la tabla, de atras adelante
	ld (de),a			;5a87   ; hacia arriba desde 0xC240
	ld (hl),a			;5a88   ; hacia abajo desde 0xC23F
	dec bc			;5a89   ; byte anterior
	inc de			;5a8a   ; posicion de arriba
	jr z,L_5A90		;5a8b   ; L llego a cero: ya esta
	dec l			;5a8d   ; posicion de abajo
	jr L_5A86		;5a8e   ; siguiente
L_5A90:
	ld bc,00080h		;5a90   ; SUPOSICION: segunda mitad de la tabla
	ldir		;5a93   ; copia el ultimo tramo
	ret			;5a95

; ----------------------------------------------------------------------
; DATOS anchuras_perspectiva: 33 longitudes de tramo (0x5A6E las escribe como
;   ceros seguidos de un 1 en 0xC300) y, leidas al reves desde 0x5AF6 por
;   0x5A7D, el espejo que rellena 0xC240 hacia arriba y 0xC23F hacia abajo
;   0x5a96..0x5af7  (97 bytes)
DATA_anchuras_perspectiva:
	defb 004h,006h,006h,007h,006h,006h,007h,006h,007h,006h,007h	; 5a96  ...........
	defb 007h,007h,007h,007h,007h,007h,008h,007h,008h,008h,009h	; 5aa1  ...........
	defb 008h,009h,009h,00ah,009h,00ah,00bh,00bh,00bh,00ch,006h	; 5aac  ...........
	defb 000h,006h,00dh,013h,019h,01fh,026h,02ch,032h,038h,03eh	; 5ab7  ......&,28>
	defb 044h,04ah,050h,056h,05ch,062h,068h,06dh,073h,079h,07eh	; 5ac2  DJPV\bhmsy~
	defb 084h,089h,08eh,093h,098h,09dh,0a2h,0a7h,0ach,0b1h,0b5h	; 5acd  ...........
	defb 0b9h,0beh,0c2h,0c6h,0cah,0ceh,0d1h,0d5h,0d8h,0dch,0dfh	; 5ad8  ...........
	defb 0e2h,0e5h,0e7h,0eah,0edh,0efh,0f1h,0f3h,0f5h,0f7h,0f8h	; 5ae3  ...........
	defb 0fah,0fbh,0fch,0fdh,0feh,0ffh,0ffh,0ffh,0ffh	; 5aee  .........

; ======================================================================
; CODIGO 0x5af7..0x651c  (2597 bytes)
; ======================================================================


escribe_vram:		; Escribe A en la VRAM HL y apunta (0xE718)
	ld (0e718h),hl		;5af7   ; puntero de VRAM para la interrupcion
	jp 0004dh		;5afa   ; BIOS WRTVRM - Writes data in VRAM
lee_vram_huerfano:		; Huerfano: leeria el byte de VRAM HL dejando (0xE718) en modo lectura
	set 7,h		;5afd   ; bit 7 = puntero de lectura
	ld (0e718h),hl		;5aff   ; (0xE718): puntero de VRAM en curso
	res 7,h		;5b02   ; direccion de lectura
	jp 0004ah		;5b04   ; BIOS RDVRM - Reads the content of VRAM
copia_a_vram:		; Copia BC bytes de HL a la VRAM DE con outi, guardando el puntero en (0xE718) por si la interrupcion lo pisa
	ex de,hl			;5b07   ; HL = destino, DE = origen
	ld (0e718h),hl		;5b08   ; (0xE718): destino en curso
	call 00053h		;5b0b   ; BIOS SETWRT - Enables VDP to write
	ex de,hl			;5b0e   ; HL = origen
	ld a,b			;5b0f   ; B = resto, C = bloques de 256
	ld b,c			;5b10   ; B = bajo de la cuenta
	ld c,a			;5b11   ; C = alto
	inc c			;5b12   ; mas uno para el djnz implicito
L_5B13:
	push bc			;5b13   ; guarda la cuenta
	ld a,(00007h)		;5b14   ; puerto de datos del VDP segun la BIOS
	ld c,a			;5b17   ; C = puerto de datos del VDP (0x0007 de la BIOS)
	di			;5b18   ; cada byte sin interrupciones
L_5B19:
	outi		;5b19   ; un byte a la VRAM, HL++, B--
	inc de			;5b1b   ; DE lleva la cuenta del destino
	jr nz,L_5B19		;5b1c   ; los B bytes
	ld (0e718h),de		;5b1e   ; puerto VRAM al dia para la interrupcion
	ei			;5b22   ; interrupciones otra vez
	pop bc			;5b23   ; recupera la cuenta
	ld b,000h		;5b24   ; 256 mas
	dec c			;5b26   ; un bloque de 256 menos
	jr nz,L_5B13		;5b27   ; los que queden
	ret			;5b29
lee_de_vram:		; Lee BC bytes de la VRAM HL en la RAM DE
	set 7,h		;5b2a   ; bit 7 = lectura
	ld (0e718h),hl		;5b2c   ; (0xE718): el origen
	res 7,h		;5b2f   ; direccion de lectura
	call 00050h		;5b31   ; BIOS SETRD - Enables VDP to read
	ex de,hl			;5b34   ; HL = destino en RAM
	ld a,b			;5b35   ; A = bajo de la cuenta
	ld b,c			;5b36   ; B = bajo
	ld c,a			;5b37   ; C = alto
	inc c			;5b38   ; mas uno
L_5B39:
	push bc			;5b39   ; guarda la cuenta
	ld a,(00006h)		;5b3a   ; puerto de lectura del VDP
	ld c,a			;5b3d   ; C = puerto de datos
	di			;5b3e   ; sin interrupciones
L_5B3F:
	ini		;5b3f   ; un byte de la VRAM a (HL), HL++, B--
	inc de			;5b41   ; DE lleva la cuenta
	jr nz,L_5B3F		;5b42   ; los B bytes
	ld (0e718h),de		;5b44   ; (0xE718) = siguiente direccion
	ei			;5b48   ; interrupciones otra vez
	pop bc			;5b49   ; recupera la cuenta
	ld b,000h		;5b4a   ; 256 mas
	dec c			;5b4c   ; un bloque menos
	jr nz,L_5B39		;5b4d   ; los que queden
	ret			;5b4f
rellena_vram:		; Rellena BC bytes de la VRAM HL con A
	push hl			;5b50   ; guarda HL
	push de			;5b51   ; DE
	push af			;5b52   ; y el valor
	ld (0e718h),hl		;5b53   ; (0xE718): destino
	ld e,c			;5b56   ; DE = cuenta
	ld d,b			;5b57
	call 00053h		;5b58   ; BIOS SETWRT - Enables VDP to write
	ld a,(00007h)		;5b5b   ; puerto de datos del VDP
	ld c,a			;5b5e   ; en C
L_5B5F:
	pop af			;5b5f   ; el valor
	di			;5b60   ; sin interrupciones mientras se escribe
	out (c),a		;5b61   ; a la VRAM
	inc hl			;5b63   ; siguiente
	ld (0e718h),hl		;5b64   ; (0xE718) al dia
	ei			;5b67   ; interrupciones
	push af			;5b68   ; guarda el valor
	dec de			;5b69   ; uno menos
	ld a,d			;5b6a
	or e			;5b6b   ; quedan?
	jr nz,L_5B5F		;5b6c   ; otro
	pop af			;5b6e   ; recupera el valor
	pop de			;5b6f   ; DE
	pop hl			;5b70   ; y HL
	ret			;5b71
alterna_sprites:		; Interrupcion: cambia la tabla de atributos visible entre 0x1B00 y 0x1F00 salvo si esta congelada
	ld a,(0e833h)		;5b72   ; 0xE833 distinto de 0: alternancia congelada
	and a			;5b75   ; pantalla apagada?
	ret nz			;5b76   ; si: nada
alterna_tabla_atributos:		; Cambia el bit 2 del registro 5 (RG5SAV, 0xF929): la tabla de atributos pasa de 0x1B00 a 0x1F00 o al reves, y deja el puntero de VRAM (0xE718) preparado para lo que venga
	ld hl,0f929h		;5b77   ; ATRBAS alto: 0x1B o 0x1F
	ld a,(hl)			;5b7a   ; A = registro 5 guardado (RG5SAV)
	xor 004h		;5b7b   ; cambia el bit 2: 0x1B00 <-> 0x1F00
	ld (hl),a			;5b7d   ; guardado
	rla			;5b7e   ; registro 5 del VDP (0x36 o 0x3E)
	ld b,a			;5b7f   ; B = valor
	ld c,005h		;5b80   ; registro 5
	call 00047h		;5b82   ; BIOS WRTVDP - Writes data in the VDP-register
	ld hl,(0e718h)		;5b85   ; restaura el puntero de VRAM del programa
	call 00053h		;5b88   ; BIOS SETWRT - Enables VDP to write
	ld a,h			;5b8b   ; A = alto del puntero
	res 7,h		;5b8c   ; sin el bit de escritura
	and a			;5b8e   ; era de lectura?
	call m,00050h		;5b8f   ; BIOS SETRD - Enables VDP to read | bit 7: estaba leyendo
	ret			;5b92
congela_sprites:		; Para la alternancia y deja visible la tabla 0x1B00
	ld a,0ffh		;5b93   ; (0xE833) = 0xFF: pantalla parada
	ld (0e833h),a		;5b95
	ld a,(0f929h)		;5b98   ; registro 5 guardado
	cp 01bh		;5b9b   ; ya esta en 0x1B00
	ret z			;5b9d   ; 0x1B: la de la BIOS, sin alternar
	push bc			;5b9e   ; guarda BC
	push hl			;5b9f   ; y HL
	call alterna_tabla_atributos		;5ba0   ; alterna la tabla de atributos
	pop hl			;5ba3   ; recupera HL
	pop bc			;5ba4   ; y BC
	ret			;5ba5
suelta_sprites:		; Reanuda la alternancia de tablas de atributos
	xor a			;5ba6   ; (0xE833) = 0: pantalla en marcha
	ld (0e833h),a		;5ba7
	ret			;5baa
vuelca_sprites:		; Monta la lista de atributos de los siete grupos rotando su orden y la copia a 0x1B00 y 0x1F00
	call monta_atributos		;5bab   ; monta en 0xE7B0 los siete grupos de atributos en el orden de este cuadro (grupo_en_orden) y deja en HL el final
	ld b,007h		;5bae   ; siete grupos: seis jugadores y el balon
	ld de,0e72fh		;5bb0   ; DE = ultimo tamano de la lista de grupos (0xE729-0xE72F)
	exx			;5bb3   ; DE' = destino en 0xE730
	ld de,0e730h		;5bb4
	exx			;5bb7
	ld a,(de)			;5bb8   ; A = tamano del grupo
	dec de			;5bb9   ; tamano anterior
	push de			;5bba   ; guarda la lista
	ld e,a			;5bbb   ; DE = tamano
	ld d,000h		;5bbc
	and a			;5bbe   ; HL -= tamano: principio del grupo
	sbc hl,de		;5bbf
	pop de			;5bc1   ; recupera la lista
L_5BC2:
	push af			;5bc2   ; guarda el tamano
	push hl			;5bc3   ; y el origen
	exx			;5bc4
	ld c,a			;5bc5   ; BC' = tamano
	ld b,000h		;5bc6
	pop hl			;5bc8   ; HL' = origen
	push bc			;5bc9   ; guarda el tamano
	push de			;5bca   ; y el destino
	ldir		;5bcb   ; copia el grupo
	pop de			;5bcd   ; recupera el destino
	pop bc			;5bce   ; y el tamano
	ex de,hl			;5bcf   ; HL' = destino
	add hl,bc			;5bd0   ; mas el tamano
	ex de,hl			;5bd1   ; DE' = destino siguiente
	exx			;5bd2
	pop af			;5bd3   ; recupera el tamano
	push de			;5bd4   ; guarda la lista
	ld e,a			;5bd5   ; DE = tamano
	ld d,000h		;5bd6
	and a			;5bd8
	sbc hl,de		;5bd9   ; HL -= tamano: el principio del grupo anterior (0xE7B0 se recorre de atras adelante: 0xE730 queda con los grupos al reves)
	pop de			;5bdb   ; recupera la lista
	ld a,(de)			;5bdc   ; A = tamano del grupo anterior
	dec de			;5bdd   ; lista hacia atras
	djnz L_5BC2		;5bde   ; los siete grupos
	call espera_interrupcion		;5be0   ; espera la interrupcion
	ld bc,00080h		;5be3   ; lista rotada en 0xE7B0 a 0x1B00
	ld de,01b00h		;5be6   ; la tabla de atributos de 0x1B00: los grupos en el orden del cuadro
	ld hl,0e7b0h		;5be9   ; desde 0xE7B0
	call copia_a_vram		;5bec   ; 0x80 bytes: los 32 sprites
	ld bc,00080h		;5bef   ; lista en 0xE730 a 0x1F00
	ld de,01f00h		;5bf2   ; la de 0x1F00: los mismos al reves; el registro 5 (0x5B77) dice cual se ve
	ld hl,0e730h		;5bf5   ; desde 0xE730
	jp copia_a_vram		;5bf8   ; 0x80 bytes, y vuelve
oculta_sprites:		; Y = 0xD0 en el primer sprite de las dos tablas: no se pinta ninguno
	ld hl,01b00h		;5bfb   ; primera tabla de atributos
	ld a,0d0h		;5bfe   ; Y 0xD0: fin de la lista
	call escribe_vram		;5c00
	ld hl,01f00h		;5c03   ; segunda tabla
	ld a,0d0h		;5c06
	jp escribe_vram		;5c08
monta_atributos:		; Calcula los atributos de los siete grupos en la lista 0xE7B0 y el numero de sprites de cada uno en 0xE729
	ld a,(0ed92h)		;5c0b   ; SUPOSICION: parpadeo del marcador de jugador activo
	and a			;5c0e
	jr nz,L_5C20		;5c0f
	ld hl,(0e71fh)		;5c11
	ld a,h			;5c14
	or l			;5c15
	jr z,L_5C20		;5c16
	res 7,(hl)		;5c18
	ld hl,00000h		;5c1a   ; quita la marca
	ld (0e71fh),hl		;5c1d
L_5C20:
	ld b,007h		;5c20
	ld c,000h		;5c22
	exx			;5c24
	ld hl,0e7b0h		;5c25   ; lista de atributos en construccion
	exx			;5c28
	ld hl,0e729h		;5c29   ; cuenta de sprites por grupo
L_5C2C:
	push hl			;5c2c
	ld a,c			;5c2d   ; puesto de pintado C
	call grupo_en_orden		;5c2e   ; registro de ese puesto
	call atributos_grupo		;5c31   ; sus sprites a la lista
	pop hl			;5c34
	ld (hl),a			;5c35   ; numero de sprites del grupo
	inc hl			;5c36
	inc c			;5c37   ; siguiente puesto
	djnz L_5C2C		;5c38
	exx			;5c3a
	push hl			;5c3b
	exx			;5c3c
	pop hl			;5c3d   ; HL = fin de la lista
	ret			;5c3e
atributos_grupo:		; Atributos de los cuatro sprites del grupo C a partir de la posicion en pantalla (perspectiva) y la colocacion de la pose
	push bc			;5c3f
	ld c,a			;5c40
	push bc			;5c41
	call y_pantalla		;5c42   ; Y de pantalla
	ld d,a			;5c45
	call x_pantalla		;5c46   ; X de pantalla
	ld e,a			;5c49
	pop bc			;5c4a
	ld a,006h		;5c4b   ; el grupo 6 es el balon
	cp c			;5c4d
	jp z,atributos_balon		;5c4e
	push de			;5c51
	ld de,00009h		;5c52   ; +9 del registro: SUPOSICION altura de cada sprite
	add hl,de			;5c55
	push hl			;5c56
	exx			;5c57
	pop de			;5c58
	exx			;5c59
	call sombra_grupo		;5c5a   ; sombra de atributos del jugador
	pop de			;5c5d
	xor a			;5c5e
	ld b,004h		;5c5f
L_5C61:
	push af			;5c61
	push de			;5c62
	ld a,d			;5c63
	cp 0d0h		;5c64   ; Y 0xD0 o mas: fuera de pantalla
	jr nc,L_5C6D		;5c66
	exx			;5c68
	ld a,(de)			;5c69
	exx			;5c6a
	add a,d			;5c6b
	ld d,a			;5c6c
L_5C6D:
	xor a			;5c6d
	ld (0e834h),a		;5c6e   ; bit early clock apagado
	ld a,(hl)			;5c71
	inc hl			;5c72
	neg		;5c73   ; resta dy de la colocacion
	add a,d			;5c75
	exx			;5c76
	ld (hl),a			;5c77
	inc hl			;5c78
	exx			;5c79
	ld a,(hl)			;5c7a
	inc hl			;5c7b
	neg		;5c7c   ; resta dx de la colocacion
	jp p,L_5C91		;5c7e
	push af			;5c81
	ld a,e			;5c82
	cp 020h		;5c83   ; X cerca del borde izquierdo
	jr nc,L_5C90		;5c85
	ld a,080h		;5c87   ; early clock: corre el sprite 32 pixeles
	ld (0e834h),a		;5c89
	ld a,e			;5c8c
	add a,020h		;5c8d
	ld e,a			;5c8f
L_5C90:
	pop af			;5c90
L_5C91:
	add a,e			;5c91   ; X de pantalla mas dx
	exx			;5c92
	ld (hl),a			;5c93   ; X del sprite
	inc hl			;5c94
	exx			;5c95
	ld a,(hl)			;5c96   ; numero de patron
	inc hl			;5c97
	exx			;5c98
	ld (hl),a			;5c99   ; patron del sprite
	inc hl			;5c9a
	exx			;5c9b
	call color_sprite		;5c9c   ; color
	pop de			;5c9f
	pop af			;5ca0
	add a,004h		;5ca1   ; siguiente sprite: 4 bytes
	djnz L_5C61		;5ca3
	pop bc			;5ca5
	ret			;5ca6
color_sprite:		; Color del sprite con el bit early clock; el bit 7 en el cuarto sprite (camiseta) hace parpadear la marca en blanco
	ld a,b			;5ca7   ; cuarto sprite del grupo (camiseta)?
	cp 001h		;5ca8
	jr nz,L_5CB1		;5caa
	ld a,(hl)			;5cac   ; color con la marca?
	bit 7,a		;5cad
	jr nz,L_5CBE		;5caf   ; parpadea
L_5CB1:
	ld a,(hl)			;5cb1
L_5CB2:
	inc hl			;5cb2
	push hl			;5cb3
	ld hl,0e834h		;5cb4   ; bit early clock
	or (hl)			;5cb7   ; en el color
	pop hl			;5cb8
	exx			;5cb9
	ld (hl),a			;5cba   ; color del sprite
	inc hl			;5cbb
	exx			;5cbc
	ret			;5cbd
L_5CBE:
	res 7,a		;5cbe
	ld c,a			;5cc0
	ld a,(0e71ah)		;5cc1   ; cuenta de cuadros: parpadeo cada 4
	bit 2,a		;5cc4
	ld a,c			;5cc6
	jr nz,L_5CB2		;5cc7
	ld a,00fh		;5cc9   ; blanco
	jr L_5CB2		;5ccb
marca_jugador:		; Pone el bit 7 (marca) en el color del grupo A y lo recuerda en (0xE71D)
	push hl			;5ccd
	push de			;5cce
	call color_grupo		;5ccf   ; color del cuarto sprite del grupo
	set 7,(hl)		;5cd2   ; marca
	ld (0e71dh),hl		;5cd4   ; recuerda donde
	pop de			;5cd7
	pop hl			;5cd8
	ret			;5cd9
quita_marca:		; Quita la marca puesta por 0x5CCD
	push hl			;5cda
	ld hl,(0e71dh)		;5cdb   ; marca puesta
	ld a,h			;5cde
	or l			;5cdf
	jr z,L_5CE4		;5ce0   ; ninguna
	res 7,(hl)		;5ce2   ; la quita
L_5CE4:
	pop hl			;5ce4
	ret			;5ce5
color_grupo:		; HL = color del cuarto sprite (camiseta) del grupo A en la sombra 0xE650
	ld l,a			;5ce6
	ld h,000h		;5ce7
	add hl,hl			;5ce9   ; 16 bytes por grupo
	add hl,hl			;5cea
	add hl,hl			;5ceb
	add hl,hl			;5cec
	ld de,0e650h		;5ced   ; sombra de atributos
	add hl,de			;5cf0
	ld de,0000fh		;5cf1   ; color del cuarto sprite (+0x0F)
	add hl,de			;5cf4
	ret			;5cf5
marca_controlado:		; Marca al jugador controlado del bando de (0xE83C) durante 180 cuadros
	push de			;5cf6
	ld hl,(0e71fh)		;5cf7   ; marca anterior
	ld a,l			;5cfa
	or h			;5cfb
	jr z,L_5D00		;5cfc
	res 7,(hl)		;5cfe   ; la quita
L_5D00:
	ld a,(0e83ch)		;5d00
	and a			;5d03
	ld a,(0e6d8h)		;5d04   ; controlado del equipo izquierdo
	jr nz,L_5D0C		;5d07
	ld a,(0e6dbh)		;5d09   ; controlado del equipo derecho
L_5D0C:
	call color_grupo		;5d0c
	set 7,(hl)		;5d0f
	ld (0e71fh),hl		;5d11
	ld a,0b4h		;5d14   ; 180 cuadros de marca
	ld (0ed92h),a		;5d16
	pop de			;5d19
	ret			;5d1a
muestra_balon:		; (0xE832) = 0: balon y sombra visibles
	xor a			;5d1b
	ld (0e832h),a		;5d1c
	ret			;5d1f
oculta_balon:		; (0xE832) = 0x80: balon y sombra fuera de la pantalla
	ld a,080h		;5d20
	ld (0e832h),a		;5d22
	ret			;5d25
atributos_balon:		; Grupo 6: aro, balon, sombra y cuarto sprite; devuelve 16 bytes
	push de			;5d26
	push de			;5d27
	call sprite_red		;5d28   ; sprite del aro y la red
	pop de			;5d2b
	call sprite_balon		;5d2c   ; sprite del balon
	pop de			;5d2f
	call sprite_sombra		;5d30   ; sombra del balon
	call sprite_fijo		;5d33   ; cuarto sprite fijo
	ld a,010h		;5d36
	pop bc			;5d38
	ret			;5d39
sprite_red:		; Red en la posicion de pantalla (0xE6CB) mas su colocacion de 0xE6B0
	ld hl,0e6cbh		;5d3a   ; posicion de la red en pantalla
	ld d,(hl)			;5d3d
	inc hl			;5d3e
	ld e,(hl)			;5d3f
	ld hl,0e6b0h		;5d40   ; colocacion de la red
	ld a,d			;5d43
	add a,(hl)			;5d44   ; Y mas dy
	ld d,a			;5d45
	inc hl			;5d46
	ld a,e			;5d47
	add a,(hl)			;5d48   ; X mas dx
	ld e,a			;5d49
	inc hl			;5d4a
	ld b,(hl)			;5d4b   ; patron
	inc hl			;5d4c
	ld c,(hl)			;5d4d   ; color
	jp guarda_atributos		;5d4e
sprite_balon:		; Balon en Y de pantalla mas altura de la mano, la Z y la colocacion; oculto si (0xE832)
	ld a,(0e832h)		;5d51   ; balon oculto
	and a			;5d54
	jr z,L_5D5B		;5d55
	ld a,0d1h		;5d57   ; Y 0xD1: fuera de la pantalla
	jr L_5D6C		;5d59
L_5D5B:
	ld hl,0e630h		;5d5b   ; altura de la mano en vuelo
	ld a,d			;5d5e
	add a,(hl)			;5d5f
	ld hl,0e62dh		;5d60   ; altura en la mano
	add a,(hl)			;5d63
	ld hl,0e629h		;5d64   ; Z del balon
	add a,(hl)			;5d67
	ld hl,0e6b4h		;5d68
	add a,(hl)			;5d6b
L_5D6C:
	ld d,a			;5d6c   ; Y del balon
	inc hl			;5d6d
	ld a,(hl)			;5d6e   ; X de colocacion
	add a,e			;5d6f
	ld e,a			;5d70
	inc hl			;5d71
	ld b,(hl)			;5d72   ; patron
	inc hl			;5d73
	ld c,(hl)			;5d74   ; color
	jp guarda_atributos		;5d75
sprite_sombra:		; Sombra del balon en el suelo; oculta si (0xE832)
	ld a,(0e832h)		;5d78
	and a			;5d7b
	jr z,L_5D82		;5d7c
	ld a,0d1h		;5d7e
	jr L_5D87		;5d80
L_5D82:
	ld hl,0e6b8h		;5d82
	ld a,d			;5d85
	add a,(hl)			;5d86
L_5D87:
	ld d,a			;5d87   ; Y de la sombra
	inc hl			;5d88
	ld a,e			;5d89
	add a,(hl)			;5d8a   ; X de colocacion
	ld e,a			;5d8b
	inc hl			;5d8c
	ld b,(hl)			;5d8d   ; patron
	inc hl			;5d8e
	ld c,(hl)			;5d8f   ; color
	jp guarda_atributos		;5d90
sprite_fijo:		; Cuarto sprite del grupo con la colocacion fija de 0xE6BC
	ld hl,0e6bch		;5d93   ; cuarto sprite: posicion fija
	ld d,(hl)			;5d96
	inc hl			;5d97
	ld e,(hl)			;5d98
	inc hl			;5d99
	ld b,(hl)			;5d9a   ; patron
	inc hl			;5d9b
	ld c,(hl)			;5d9c   ; color
	jp guarda_atributos		;5d9d
guarda_atributos:		; Escribe Y, X, patron y color en la lista HL'
	push bc			;5da0
	push de			;5da1
	exx			;5da2   ; a la lista de HL'
	pop de			;5da3
	pop bc			;5da4
	ld (hl),d			;5da5   ; Y
	inc hl			;5da6
	ld (hl),e			;5da7   ; X
	inc hl			;5da8
	ld (hl),b			;5da9   ; patron
	inc hl			;5daa
	ld (hl),c			;5dab   ; color
	inc hl			;5dac
	exx			;5dad
	ret			;5dae
x_pantalla:		; X de pantalla: (0xE831) mas la X (+3) escalada por la curva 0xB61E segun la Y (+1); 0xE1 si se sale
	push hl			;5daf
	inc hl			;5db0
	ld a,(hl)			;5db1   ; Y (+1)
	inc hl			;5db2
	inc hl			;5db3
	ld c,(hl)			;5db4   ; X (+3)
	push de			;5db5
	ld e,a			;5db6
	ld d,000h		;5db7
	ld hl,0b61eh		;5db9   ; escala segun la profundidad
	add hl,de			;5dbc
	ld e,(hl)			;5dbd   ; factor de escala
	ld a,c			;5dbe   ; X con signo
	bit 7,a		;5dbf
	jr z,L_5DC5		;5dc1
	neg		;5dc3   ; valor absoluto
L_5DC5:
	call multiplica		;5dc5
	add hl,hl			;5dc8
	ld a,h			;5dc9
	ld hl,0e831h		;5dca   ; X fina de la ventana
	bit 7,c		;5dcd
	jr z,L_5DD8		;5dcf
	neg		;5dd1
	add a,(hl)			;5dd3
	jr nc,L_5DDE		;5dd4
	jr L_5DDB		;5dd6
L_5DD8:
	add a,(hl)			;5dd8
	jr c,L_5DDE		;5dd9
L_5DDB:
	pop de			;5ddb
L_5DDC:
	pop hl			;5ddc
	ret			;5ddd
L_5DDE:
	pop de			;5dde
	ld d,0e1h		;5ddf   ; fuera: oculto
	ld e,a			;5de1
	jr L_5DDC		;5de2
y_pantalla:		; Y de pantalla: curva 0xB59E segun la Y (+1), mas 0x40; 0xE1 si pasa de 0xC0
	push hl			;5de4
	inc hl			;5de5
	ld a,(hl)			;5de6   ; Y (+1)
	push de			;5de7
	ld e,a			;5de8
	ld d,000h		;5de9
	ld hl,0b59eh		;5deb   ; curva de la Y de pantalla
	add hl,de			;5dee
	ld a,(hl)			;5def
	add a,040h		;5df0   ; mas la linea del horizonte
	cp 0c0h		;5df2   ; fuera por abajo?
	jr c,L_5DF8		;5df4
	ld a,0e1h		;5df6   ; oculto
L_5DF8:
	pop de			;5df8
	pop hl			;5df9
	ret			;5dfa
grupo_en_orden:		; HL = registro que va en el puesto A del orden de pintado (+0x0E), C su numero
	push bc			;5dfb
	push de			;5dfc
	ld hl,0e50eh		;5dfd   ; +0x0E del primer registro
	ld de,00030h		;5e00
	ld b,007h		;5e03
	ld c,000h		;5e05
L_5E07:
	cp (hl)			;5e07   ; es este puesto?
	jr z,L_5E11		;5e08
	add hl,de			;5e0a   ; siguiente registro
	inc c			;5e0b
	djnz L_5E07		;5e0c
	ld hl,0000eh		;5e0e   ; no encontrado
L_5E11:
	and a			;5e11
	ld a,c			;5e12   ; A = numero de registro
	ld de,0000eh		;5e13   ; HL = registro
	sbc hl,de		;5e16
	pop de			;5e18
	pop bc			;5e19
	ret			;5e1a
ordena_profundidad:		; Ordena los siete registros por la profundidad +1 (mayor primero) y guarda el puesto en +0x0E
	ld hl,0e501h		;5e1b   ; +1 de cada registro
	ld de,0e721h		;5e1e   ; lista temporal en 0xE721
	ld b,007h		;5e21
L_5E23:
	ld a,(hl)			;5e23   ; Y del registro
	push de			;5e24
	ld de,00030h		;5e25   ; siguiente registro
	add hl,de			;5e28
	pop de			;5e29
	ld (de),a			;5e2a   ; a la lista
	inc de			;5e2b
	djnz L_5E23		;5e2c
	ld hl,0e721h		;5e2e   ; lista de siete
	ld d,h			;5e31
	ld e,l			;5e32
	inc hl			;5e33
	ld b,006h		;5e34   ; seis pasadas
L_5E36:
	push bc			;5e36   ; ordenacion de burbuja
	ld a,(de)			;5e37
L_5E38:
	cp (hl)			;5e38   ; menor que el siguiente?
	call c,intercambia		;5e39   ; los cambia
	inc hl			;5e3c
	djnz L_5E38		;5e3d
	inc de			;5e3f   ; siguiente posicion
	ld h,d			;5e40
	ld l,e			;5e41
	inc hl			;5e42
	pop bc			;5e43
	djnz L_5E36		;5e44
	ld de,0e500h		;5e46   ; puesto de cada registro
	ld hl,0e721h		;5e49
	ld b,007h		;5e4c
L_5E4E:
	push bc			;5e4e
	inc de			;5e4f   ; +1 del registro
	ld b,007h		;5e50   ; siete puestos
	ld c,000h		;5e52   ; C = puesto
	ld a,(de)			;5e54   ; Y del registro
	push hl			;5e55
L_5E56:
	cp (hl)			;5e56   ; es la del puesto C?
	call z,pon_puesto		;5e57   ; se lo asigna
	inc hl			;5e5a
	inc c			;5e5b   ; siguiente puesto
	djnz L_5E56		;5e5c
	ld hl,0002fh		;5e5e   ; siguiente registro (+0x30)
	add hl,de			;5e61
	ex de,hl			;5e62
	pop hl			;5e63
	pop bc			;5e64
	djnz L_5E4E		;5e65
	ret			;5e67
intercambia:		; Cambia (DE) y (HL)
	ex af,af'			;5e68
	ld a,(hl)			;5e69
	ld (de),a			;5e6a   ; el de HL a DE
	ex af,af'			;5e6b
	ld (hl),a			;5e6c   ; el de DE a HL
	ld a,(de)			;5e6d
	ret			;5e6e
pon_puesto:		; Puesto C en +0x0E y marca usada
	push hl			;5e6f
	ld hl,0000dh		;5e70   ; +0x0E del registro
	add hl,de			;5e73
	ld b,001h		;5e74   ; una sola vez
	ld a,c			;5e76
	ld (hl),a			;5e77   ; puesto
	pop hl			;5e78
	ld (hl),0ffh		;5e79   ; puesto usado
	ret			;5e7b
centra_ventana:		; Mueve la ventana una columna hacia la central (12)
	ld de,0e830h		;5e7c
	ld hl,0e6cfh		;5e7f
	ld a,(de)			;5e82
	ld c,(hl)			;5e83
	cp 00ch		;5e84   ; ya centrada
	ret z			;5e86
	and a			;5e87
	jr nz,L_5E91		;5e88
	inc a			;5e8a
	set 4,c		;5e8b   ; bit 4: hacia la derecha
	ld b,0f8h		;5e8d
	jr L_5E96		;5e8f
L_5E91:
	dec a			;5e91
	set 3,c		;5e92   ; bit 3: hacia la izquierda
	ld b,008h		;5e94
L_5E96:
	ld (de),a			;5e96   ; columna nueva
	ld (hl),c			;5e97   ; bits de desplazamiento
	ld hl,0e831h		;5e98   ; X fina
	ld a,b			;5e9b
	add a,(hl)			;5e9c   ; mas o menos 8
	ld (hl),a			;5e9d
	call desplaza_ventana		;5e9e   ; desplaza ya
desplaza_ventana:		; Si 0xE6CF pide desplazar, mueve la ventana una columna, ajusta la X fina y la canasta; si no, refresca el marcador
	ld hl,0e831h		;5ea1
	ld a,(0e6cfh)		;5ea4
	ld c,a			;5ea7
	bit 4,a		;5ea8   ; bit 4: desplaza a la derecha
	jr z,L_5EBF		;5eaa
	ld a,008h		;5eac   ; X fina mas 8
	ld b,a			;5eae
	add a,(hl)			;5eaf
	ld (hl),a			;5eb0
	ld a,0ffh		;5eb1   ; una columna menos
	ld hl,0e6c3h		;5eb3   ; canasta de la derecha
	inc hl			;5eb6
	ld (hl),039h		;5eb7
	inc hl			;5eb9
	inc hl			;5eba
	ld (hl),09eh		;5ebb
	jr L_5ED5		;5ebd
L_5EBF:
	bit 3,a		;5ebf   ; bit 3: desplaza a la izquierda
	jp z,refresca_marcador		;5ec1
	ld a,0f8h		;5ec4   ; X fina menos 8
	ld b,a			;5ec6
	add a,(hl)			;5ec7
	ld (hl),a			;5ec8
	ld a,001h		;5ec9   ; una columna mas
	ld hl,0e6c3h		;5ecb   ; canasta de la izquierda
	inc hl			;5ece
	ld (hl),039h		;5ecf
	inc hl			;5ed1
	inc hl			;5ed2
	ld (hl),062h		;5ed3
L_5ED5:
	push bc			;5ed5
	call copia_ventana		;5ed6   ; copia la ventana
	push af			;5ed9
	call nc,posicion_red		;5eda   ; recalcula la posicion de la red
	pop af			;5edd
	pop bc			;5ede
	ret nc			;5edf
	ld a,c			;5ee0   ; tope: deja de desplazar
	and 0e7h		;5ee1
	ld (0e6cfh),a		;5ee3
	ld a,b			;5ee6   ; deshace la X fina
	neg		;5ee7
	ld hl,0e831h		;5ee9
	add a,(hl)			;5eec
	ld (hl),a			;5eed
	ld a,080h		;5eee   ; repinta FORMATION=
	ld (0ed59h),a		;5ef0
	call congela_sprites		;5ef3
	call monta_marcador		;5ef6   ; marcador entero
	jp suelta_sprites		;5ef9
refresca_marcador:		; Sin desplazamiento: tiempo, faltas y rotulos pendientes
	ld a,(0efdch)		;5efc
	and a			;5eff
	call nz,pinta_tiempo		;5f00   ; tiempo en el marcador
	call zona_controlado		;5f03
	ld hl,0ed94h		;5f06
	bit 7,(hl)		;5f09
	call nz,pinta_area		;5f0b   ; AREA= pendiente
	ld hl,0ed59h		;5f0e
	bit 7,(hl)		;5f11
	call nz,pinta_formacion		;5f13   ; FORMATION= pendiente
	ret			;5f16
posicion_red:		; Posicion de pantalla de la red (0xE6CB) a partir de la canasta 0xE6C3
	ld hl,0e6c3h		;5f17   ; canasta
	call y_pantalla		;5f1a   ; Y de pantalla
	add a,0cch		;5f1d   ; menos 0x34: el aro
	ld d,a			;5f1f
	call x_pantalla		;5f20   ; X de pantalla
	ld e,a			;5f23
	ld a,(0e6cfh)		;5f24
	bit 3,a		;5f27   ; lado de la ventana
	jr nz,L_5F2C		;5f29
	dec e			;5f2b   ; un pixel a la izquierda
L_5F2C:
	ld hl,0e6cbh		;5f2c
	ld (hl),d			;5f2f
	inc hl			;5f30
	ld (hl),e			;5f31
	ret			;5f32
copia_ventana:		; Mueve la ventana A columnas (si cabe en 0-24) y copia sus 32 x 24 nombres de 0xC400 a la VRAM; acarreo si no cabe
	ld c,a			;5f33   ; C = cuantas columnas
	call cabe_columna		;5f34   ; cabe la ventana?
	ret c			;5f37   ; fuera de la pista: nada
	ld a,(0e830h)		;5f38   ; columna nueva
	add a,c			;5f3b   ; columna nueva
	ld (0e830h),a		;5f3c   ; (0xE830) al dia
	call limita_columna		;5f3f   ; entre 0 y 24
	call extiende_a		;5f42   ; DE = la columna, con signo
	ld hl,0c400h		;5f45   ; primera columna en el mapa
	add hl,de			;5f48   ; HL = la columna en la fila 0 del mapa
	ld b,018h		;5f49   ; 24 filas
	ld de,01800h		;5f4b   ; fila 0 de la tabla de nombres
L_5F4E:
	push bc			;5f4e   ; guarda la cuenta de filas
	ld bc,00020h		;5f4f   ; 32 columnas por fila
	push de			;5f52   ; guarda el destino
	push hl			;5f53   ; y el origen
	call copia_a_vram		;5f54   ; 32 bytes a la VRAM
	pop hl			;5f57   ; recupera el origen
	ld de,00038h		;5f58   ; siguiente fila del mapa (56)
	add hl,de			;5f5b   ; mas 56: la fila siguiente del mapa
	pop de			;5f5c   ; recupera el destino
	push hl			;5f5d   ; guarda el origen
	ld hl,00020h		;5f5e   ; 32 mas
	add hl,de			;5f61   ; la fila siguiente de la tabla de nombres
	ex de,hl			;5f62   ; DE = destino
	pop hl			;5f63   ; HL = origen
	pop bc			;5f64   ; recupera la cuenta
	djnz L_5F4E		;5f65   ; las 24 filas
	ret			;5f67
limita_columna:		; A = columna de la ventana entre 0 y 0x19
	ld a,(0e830h)		;5f68   ; la columna
	and a			;5f6b   ; negativa?
	jp p,L_5F71		;5f6c   ; no: mira el tope
	xor a			;5f6f   ; si: cero
	ret			;5f70
L_5F71:
	cp 019h		;5f71   ; 25 o mas?
	ret c			;5f73   ; no: vale
	ld a,019h		;5f74   ; si: 25
	ret			;5f76
cabe_columna:		; Acarreo si la columna mas C se sale de 0-24
	ld a,(0e830h)		;5f77   ; la columna
	add a,c			;5f7a   ; mas lo que se quiere mover
	jp m,L_5F84		;5f7b   ; negativa: no se puede
	cp 019h		;5f7e   ; 25 o mas: no se puede
	jr nc,L_5F84		;5f80
	and a			;5f82   ; sin acarreo: se puede
	ret			;5f83
L_5F84:
	scf			;5f84   ; acarreo: no
	ret			;5f85
extiende_a:		; DE = A con signo
	ld d,000h		;5f86   ; D = 0
	ld e,a			;5f88   ; E = A
	and a			;5f89   ; negativo?
	ret p			;5f8a   ; no: listo
	dec d			;5f8b   ; si: D = 0xFF
	ret			;5f8c
descomprime_mapa:		; Mapa de la pista de 56 x 24 (0xB69E) a 0xC400
	ld hl,0b69eh		;5f8d   ; el mapa de la pista comprimido
	ld de,0c400h		;5f90   ; al bufer
	jp descomprime_rep		;5f93   ; descomprime y vuelve
servicio_vram:		; Si ya paso la interrupcion, hace el trabajo de VRAM pendiente: patrones de la pose cambiada y la ventana de la pista
	ld a,(0e71bh)		;5f96   ; bandera que pone la interrupcion
	and a			;5f99   ; cero: nada que hacer
	ret z			;5f9a
	xor a			;5f9b   ; (0xE71B) a cero
	ld (0e71bh),a		;5f9c
	push bc			;5f9f   ; guarda todos los registros
	push de			;5fa0
	push hl			;5fa1
	ex af,af'			;5fa2
	exx			;5fa3
	push af			;5fa4
	push bc			;5fa5
	push de			;5fa6
	push hl			;5fa7
	push ix		;5fa8
	push iy		;5faa
	call copia_pose		;5fac   ; patrones de la pose cambiada
	call integra_jugadores		;5faf   ; el movimiento de los seis jugadores
	call mueve_balon		;5fb2   ; y el del balon
	pop iy		;5fb5   ; recupera todos los registros
	pop ix		;5fb7
	pop hl			;5fb9
	pop de			;5fba
	pop bc			;5fbb
	pop af			;5fbc
	ex af,af'			;5fbd
	exx			;5fbe
	pop hl			;5fbf
	pop de			;5fc0
	pop bc			;5fc1
	ret			;5fc2
copia_pose:		; Copia a 0x3800+n*128 los cuatro patrones de 16x16 de la pose del jugador marcado en (0xE836) y su colocacion a la sombra 0xE650
	ld a,(0e836h)		;5fc3   ; bit 7: hay pose cambiada; bits bajos: jugador
	bit 7,a		;5fc6   ; bit 7: la pose cambio
	ret z			;5fc8   ; no: nada
	push af			;5fc9   ; guarda A
	xor a			;5fca   ; quita la marca
	ld (0e836h),a		;5fcb
	pop af			;5fce   ; recupera A
	xor 080h		;5fcf   ; A = numero de jugador
sube_patrones_pose:		; Copia a la VRAM los cuatro patrones de la pose del registro en curso (0x3800 + jugador * 128) y los cuatro (dy, dx) de su grupo a los atributos de 0xE650 + jugador * 16
	push bc			;5fd1   ; guarda BC
	push de			;5fd2   ; DE
	push hl			;5fd3   ; y HL
	ld hl,(0e837h)		;5fd4   ; registro del jugador
	ld de,0000fh		;5fd7   ; campo +0x0F
	add hl,de			;5fda   ; HL = registro + 0x0F
	res 7,(hl)		;5fdb   ; pose ya atendida
	ld de,0fffeh		;5fdd   ; menos dos
	add hl,de			;5fe0   ; HL = registro + 0x0D: la pose
	ld l,(hl)			;5fe1   ; pose (+0x0D)
	push af			;5fe2   ; guarda el jugador
	push hl			;5fe3   ; y la pose
	ld h,000h		;5fe4   ; HL = pose
	add hl,hl			;5fe6   ; por dos
	add hl,hl			;5fe7   ; por cuatro
	ld de,0a4ceh		;5fe8   ; tabla de poses: 4 patrones por pose
	add hl,de			;5feb   ; HL = los cuatro patrones de la pose
	push hl			;5fec   ; guardados
	ld l,a			;5fed   ; L = jugador
	ld h,000h		;5fee   ; HL = jugador
	add hl,hl			;5ff0   ; por 2
	add hl,hl			;5ff1   ; por 4
	add hl,hl			;5ff2   ; por 8
	add hl,hl			;5ff3   ; por 16
	add hl,hl			;5ff4   ; por 32
	add hl,hl			;5ff5   ; por 64
	add hl,hl			;5ff6   ; por 128: cuatro patrones de 32 bytes por jugador
	ld de,03800h		;5ff7   ; patrones de sprite del jugador: 0x3800+n*128
	add hl,de			;5ffa   ; HL = su hueco en la tabla de patrones de sprite
	ex de,hl			;5ffb   ; DE = el hueco
	pop hl			;5ffc   ; HL = los cuatro patrones
	ld b,004h		;5ffd   ; cuatro patrones de 16x16
L_5FFF:
	push bc			;5fff   ; guarda la cuenta
	ld a,(hl)			;6000   ; A = numero de patron
	inc hl			;6001   ; siguiente
	push hl			;6002   ; guarda la pose
	push de			;6003   ; y el hueco
	ld l,a			;6004   ; HL = patron
	ld h,000h		;6005
	add hl,hl			;6007   ; por 2
	add hl,hl			;6008   ; por 4
	add hl,hl			;6009   ; por 8
	add hl,hl			;600a   ; por 16
	add hl,hl			;600b   ; por 32 bytes
	ld de,0cc00h		;600c   ; cada patron 32 bytes en 0xCC00
	add hl,de			;600f   ; HL = el patron en RAM
	pop de			;6010   ; DE = el hueco
	ld bc,00020h		;6011   ; 32 bytes
	push de			;6014   ; guarda el hueco
	call copia_a_vram		;6015   ; el patron a la VRAM
	pop de			;6018   ; recupera el hueco
	ld hl,00020h		;6019   ; 32 mas
	add hl,de			;601c   ; el hueco siguiente
	ex de,hl			;601d   ; DE = hueco
	pop hl			;601e   ; recupera la pose
	pop bc			;601f   ; y la cuenta
	djnz L_5FFF		;6020   ; los cuatro patrones
	pop hl			;6022   ; HL = pose
	ld a,l			;6023   ; L = pose
	and 0fch		;6024   ; sin los dos bits bajos: el grupo por cuatro
	ld l,a			;6026   ; HL = grupo * 4
	ld h,000h		;6027
	ld de,0a38eh		;6029   ; colocacion: grupo pose>>2, 4 pares (dy, dx)
	add hl,hl			;602c   ; por dos: grupo * 8
	add hl,de			;602d   ; HL = los ocho bytes de colocacion del grupo
	pop af			;602e   ; A = jugador
	push hl			;602f   ; guarda la colocacion
	add a,a			;6030   ; por 2
	add a,a			;6031   ; por 4
	add a,a			;6032   ; por 8
	add a,a			;6033   ; por 16: cuatro atributos de cuatro bytes
	ld e,a			;6034   ; DE = jugador * 16
	ld d,000h		;6035
	ld hl,0e650h		;6037   ; sombra de atributos del jugador
	add hl,de			;603a   ; HL = sus cuatro atributos
	pop de			;603b   ; DE = la colocacion
	ld b,004h		;603c   ; cuatro sprites
L_603E:
	ld a,(de)			;603e   ; dy
	inc de			;603f   ; siguiente
	ld (hl),a			;6040   ; al atributo (Y)
	inc hl			;6041   ; siguiente byte
	ld a,(de)			;6042   ; dx
	inc de			;6043   ; siguiente
	ld (hl),a			;6044   ; al atributo (X)
	inc hl			;6045   ; se salta patron y color
	inc hl			;6046
	inc hl			;6047
	djnz L_603E		;6048   ; los cuatro sprites
	pop hl			;604a   ; recupera HL
	pop de			;604b   ; DE
	pop bc			;604c   ; y BC
	ret			;604d
sombra_grupo:		; HL = 0xE650 + C*16: atributos del grupo C
	ld l,c			;604e   ; L = jugador
	ld h,000h		;604f   ; HL = jugador
	add hl,hl			;6051   ; por 2
	add hl,hl			;6052   ; por 4
	add hl,hl			;6053   ; por 8
	add hl,hl			;6054   ; por 16
	ld de,0e650h		;6055
	add hl,de			;6058   ; HL = sus atributos
	ret			;6059
espera_interrupcion:		; Espera a que la interrupcion ponga (0xE71B)
	push af			;605a   ; guarda A
	push hl			;605b   ; y HL
	ld hl,0e71bh		;605c
	ld (hl),000h		;605f   ; (0xE71B) = 0: la interrupcion lo pondra a otra cosa
L_6061:
	ld a,(hl)			;6061   ; sigue a cero?
	and a			;6062   ; comprueba
	jr z,L_6061		;6063   ; si: espera
	pop hl			;6065   ; recupera HL
	pop af			;6066   ; y A
	ret			;6067
espera_cuadros_huerfano:		; Huerfano: esperaria B interrupciones
	call espera_interrupcion		;6068   ; un cuadro
	djnz espera_cuadros_huerfano		;606b   ; B cuadros
	ret			;606d
interrupcion:		; H.TIMI: tablas de sprites, sonido, contadores, saltos y cambio de pose de un jugador por cuadro
	ld a,0ffh		;606e   ; aviso al bucle principal: ya hubo interrupcion
	ld (0e71bh),a		;6070
	call alterna_sprites		;6073
	call tick_sonido		;6076   ; tick del sonido
	ld hl,0e71ah		;6079   ; cuenta de cuadros
	inc (hl)			;607c
	ld hl,(0e6efh)		;607d   ; cuenta atras en cuadros de 0xE6EF
	ld a,h			;6080
	or l			;6081
	jr z,L_6088		;6082
	dec hl			;6084
	ld (0e6efh),hl		;6085
L_6088:
	call reloj		;6088   ; reloj y temporizadores del partido
	call descuenta_ordenes		;608b
	ld ix,0e500h		;608e   ; saltos: los seis jugadores
	ld de,00030h		;6092
	ld b,006h		;6095
L_6097:
	xor a			;6097
	or (ix+026h)		;6098   ; SUPOSICION: retardo +0x26 del jugador
	jr z,siguiente_retardo		;609b
	dec (ix+026h)		;609d
siguiente_retardo:		; Bucle de retardos (+0x26) y resto de la interrupcion: pose pendiente, botones, giro del controlado, caidas y red
	add ix,de		;60a0   ; siguiente registro
	djnz L_6097		;60a2
	ld a,(0e836h)		;60a4   ; bit 7 de 0xE836: aun hay pose por copiar
	and a			;60a7
	call p,busca_pose_cambiada		;60a8   ; sin pose pendiente: busca la siguiente
	call cuenta_botones		;60ab   ; botones de los dos equipos
	call controlado		;60ae   ; controlado del equipo con el balon
	call registro_jugador		;60b1
	ld de,00016h		;60b4   ; +0x16: rumbo al que gira
	add hl,de			;60b7
	ld a,(hl)			;60b8
	and a			;60b9
	jp m,caidas		;60ba   ; 0xFF: no gira
	dec hl			;60bd   ; +0x14: cuadros hasta el siguiente paso
	dec hl			;60be
	ld a,(hl)			;60bf
	and a			;60c0
	jr nz,espera_giro		;60c1   ; aun esperando
	inc hl			;60c3
	ld a,(hl)			;60c4   ; direccion actual (+0x15)
	inc hl			;60c5
	cp (hl)			;60c6   ; ya mira al rumbo?
	jr z,fin_giro		;60c7
	ld b,a			;60c9
	ld a,(hl)			;60ca   ; giro en curso (+0x17)
	cp b			;60cb
	jr z,fin_giro		;60cc   ; ya llego
	inc hl			;60ce
	inc hl			;60cf
	ld a,(hl)			;60d0   ; sentido del giro (+0x18)
	dec hl			;60d1
	dec hl			;60d2
	dec hl			;60d3
	add a,(hl)			;60d4   ; un paso de giro
	inc hl			;60d5
	inc hl			;60d6
	and 007h		;60d7
	ld (hl),a			;60d9   ; direccion nueva en +0x17
	dec hl			;60da
	dec hl			;60db
	dec hl			;60dc
	ld (hl),006h		;60dd   ; seis cuadros por paso
	jr caidas		;60df
espera_giro:		; Un cuadro menos para el siguiente paso de giro
	dec (hl)			;60e1
	jr caidas		;60e2
fin_giro:		; Giro acabado: rumbo y giro a 0xFF, sentido 0
	xor a			;60e4
	dec a			;60e5   ; 0xFF
	ld (hl),a			;60e6   ; rumbo: ninguno
	inc hl			;60e7
	ld (hl),a			;60e8   ; giro: ninguno
	inc hl			;60e9
	inc a			;60ea
	ld (hl),a			;60eb   ; sentido 0
caidas:		; Un paso de la caida de los seis jugadores que estan en el aire
	ld hl,0e500h		;60ec   ; caida de los jugadores en el aire
	ld b,006h		;60ef   ; seis jugadores
	ld c,000h		;60f1
L_60F3:
	push hl			;60f3
	push hl			;60f4
	ld de,0000ch		;60f5   ; +0x0C gravedad: distinto de 0 en el aire
	add hl,de			;60f8
	ld a,(hl)			;60f9
	pop hl			;60fa
	and a			;60fb
	call nz,caida		;60fc
	pop hl			;60ff
	ld de,00030h		;6100   ; siguiente registro
	add hl,de			;6103
	inc c			;6104   ; numero de jugador
	djnz L_60F3		;6105
anima_red:		; Animacion de la red tras una canasta: cinco pasos de 10 cuadros
	ld a,(0e633h)		;6107   ; paso de la red (negativo: parada)
	and a			;610a
	ret m			;610b
	ld a,(0e634h)		;610c   ; cuadros del paso
	and a			;610f
	jr z,paso_red		;6110
	dec a			;6112
	ld (0e634h),a		;6113   ; un cuadro menos
	ret			;6116
paso_red:		; Siguiente paso de la red; tras el quinto se para (0xFF)
	ld a,(0e633h)		;6117
	inc a			;611a
	cp 005h		;611b   ; cinco pasos
	jr c,L_6121		;611d
	ld a,0ffh		;611f
L_6121:
	ld (0e633h),a		;6121
	ret nc			;6124
	ld a,00ah		;6125   ; 10 cuadros por paso
	ld (0e634h),a		;6127
	ret			;612a
caida:		; Un paso de la parabola del salto: Z (+8) menos velocidad (+0x0A), velocidad menos gravedad (+0x0C); al tocar el suelo lo para
	push hl			;612b
	pop ix		;612c
	ld e,(ix+00ah)		;612e   ; velocidad vertical
	ld d,(ix+00bh)		;6131   ; (+0x0A/+0x0B)
	ld l,(ix+008h)		;6134   ; altura (negativa = en el aire)
	ld h,(ix+009h)		;6137   ; (+8/+9)
	and a			;613a
	sbc hl,de		;613b   ; Z menos velocidad
	jp p,L_6156		;613d   ; llega al suelo
	ld (ix+008h),l		;6140
	ld (ix+009h),h		;6143
	ld l,(ix+00ch)		;6146   ; la gravedad frena la subida
	ld h,000h		;6149   ; gravedad (+0x0C)
	ex de,hl			;614b
	and a			;614c
	sbc hl,de		;614d
	ld (ix+00ah),l		;614f   ; velocidad nueva
	ld (ix+00bh),h		;6152
	ret			;6155
L_6156:
	xor a			;6156   ; en el suelo: todo a cero
	ld (ix+00ch),a		;6157   ; sin gravedad: en el suelo
	ld (ix+00ah),a		;615a   ; velocidad vertical a cero
	ld (ix+00bh),a		;615d
	ld (ix+008h),a		;6160   ; altura a cero
	ld (ix+009h),a		;6163
	ld (ix+014h),a		;6166   ; sin pasos de giro
	ld (ix+018h),a		;6169   ; sentido 0
	dec a			;616c
	ld (ix+016h),a		;616d   ; SUPOSICION: sin destino de balon
	ld a,c			;6170
	call borra_saltador		;6171   ; ya no es saltador de su equipo
	ld a,(0e6cfh)		;6174   ; el que cae es el poseedor?
	cp c			;6177
	ret nz			;6178
	ld a,(0e6f6h)		;6179   ; salto con el balon?
	and a			;617c
	ret z			;617d
	xor a			;617e
	ld (0e6f6h),a		;617f   ; se acabo el salto
	ld (0ed70h),a		;6182   ; rotulo 0: TRAVELLING
	ld a,c			;6185
	ld (0ed6fh),a		;6186   ; infractor: el que cae con el balon
	ret			;6189
busca_pose_cambiada:		; Recorre los seis jugadores desde el ultimo atendido y apunta en 0xE836/0xE837 el primero con la pose cambiada
	ld a,(0e835h)		;618a   ; ultimo jugador atendido
	call siguiente_de_seis		;618d   ; empieza por el siguiente
	call registro_jugador		;6190
	ld de,0000fh		;6193   ; +0x0F del primer registro
	add hl,de			;6196
	ld de,00030h		;6197
	ld b,006h		;619a   ; seis jugadores
L_619C:
	bit 7,(hl)		;619c   ; bit 7 de +0x0F: pose cambiada
	jr nz,L_61AC		;619e
	call siguiente_de_seis		;61a0   ; siguiente numero
	jr nz,L_61A8		;61a3
	ld hl,0e4dfh		;61a5   ; al pasar del 5 vuelve a 0xE500 (0xE4DF + 0x30)
L_61A8:
	add hl,de			;61a8
	djnz L_619C		;61a9
	ret			;61ab
L_61AC:
	ld (0e835h),a		;61ac   ; ultimo atendido
	or 080h		;61af
	ld (0e836h),a		;61b1   ; jugador pendiente para 0x5FC3
	ld de,0000fh		;61b4   ; de +0x0F al registro
	and a			;61b7
	sbc hl,de		;61b8
	ld (0e837h),hl		;61ba
	ret			;61bd
siguiente_de_seis:		; A+1 dando la vuelta en 6
	inc a			;61be
	cp 006h		;61bf
	ret c			;61c1
	xor a			;61c2
	ret			;61c3
pon_poseedor:		; El jugador C tiene el balon: su equipo lo controla, el rival controla a su par y, si cambia el equipo, se invierte el ataque
	ld c,a			;61c4
	call controla		;61c5   ; controlado de su equipo
	call espejo_jugador		;61c8   ; su par del otro equipo
	call controla		;61cb   ; controlado del otro equipo
	ld a,c			;61ce
	call registro_jugador		;61cf
	ld (0e6d0h),hl		;61d2   ; registro del poseedor
	ld a,(0e6cfh)		;61d5   ; bits 0-2: poseedor
	and 0f8h		;61d8
	or c			;61da
	ld (0e6cfh),a		;61db
	and 007h		;61de
	ld b,a			;61e0
	ld a,(0e6d2h)		;61e1   ; ultimo poseedor
	and a			;61e4
	ret m			;61e5   ; negativo: no se cuenta
	ld c,a			;61e6
	ld a,b			;61e7
	cp c			;61e8   ; el mismo: nada que hacer
	ret z			;61e9
	ld (0e6d2h),a		;61ea   ; nuevo ultimo poseedor
	cp 003h		;61ed   ; equipo 0 o 1
	jr nc,L_61F4		;61ef
	xor a			;61f1
	jr L_61F6		;61f2
L_61F4:
	ld a,001h		;61f4
L_61F6:
	ld b,a			;61f6
	ld a,(0e83ch)		;61f7   ; equipo con el balon
	cp b			;61fa   ; no ha cambiado
	ret z			;61fb
	ld a,080h		;61fc   ; cambio pendiente (bit 7)
	or b			;61fe
	ld (0e83ch),a		;61ff
	jp cambio_de_posesion		;6202   ; se invierte el sentido de ataque
espejo_jugador:		; A = indice espejo (+0x25) del jugador A
	call registro_jugador		;6205
	ld de,00025h		;6208
	add hl,de			;620b
	ld a,(hl)			;620c
	ret			;620d
cuenta_botones:		; Interrupcion: cuadros que cada equipo lleva con el boton 1 pulsado
	ld hl,0e6d3h		;620e   ; entrada del equipo izquierdo
	bit 7,(hl)		;6211
	jr z,L_6219		;6213
	ld hl,0e6d4h		;6215   ; cuadros de boton del izquierdo
	inc (hl)			;6218
L_6219:
	ld hl,0e6d5h		;6219   ; entrada del equipo derecho
	bit 7,(hl)		;621c
	jr z,L_6224		;621e
	ld hl,0e6d6h		;6220   ; cuadros de boton del derecho
	inc (hl)			;6223
L_6224:
	call boton2_ataque		;6224   ; boton 2 del ataque y del defensor
	jp boton1_defensa		;6227   ; boton 1 del defensor
boton2_ataque:		; SUPOSICION: En campo contrario el boton 2 del equipo con el balon elige formacion o corta la que hay
	call boton2_defensa		;622a   ; boton 2 del equipo sin balon
	ld a,(0e6cfh)		;622d   ; poseedor
	and 007h		;6230
	call registro_jugador		;6232
	ld de,0000fh		;6235   ; lado y campo (+0x0F)
	add hl,de			;6238
	ld a,(hl)			;6239
	add a,a			;623a
	add a,a			;623b
	xor (hl)			;623c
	bit 6,a		;623d
	ret nz			;623f   ; en su campo: no hay formaciones
	ld a,(0e83ch)		;6240   ; entrada del equipo con el balon
	and 001h		;6243
	ld a,(0e6d3h)		;6245
	jr z,L_624D		;6248
	ld a,(0e6d5h)		;624a
L_624D:
	bit 6,a		;624d   ; bit 6: boton 2
	jr z,boton2_suelto		;624f
	ld a,(0e83dh)		;6251   ; ya estaba pulsado
	and a			;6254
	ret nz			;6255
	ld a,0ffh		;6256   ; pulsacion atendida
	ld (0e83dh),a		;6258
	ld a,(0e850h)		;625b   ; hay formacion en curso?
	cp 03fh		;625e
	jr z,L_626A		;6260
	ld a,03fh		;6262   ; la corta
	ld (0e850h),a		;6264
	xor a			;6267   ; FORMATION= sin letra
	jr L_6274		;6268
L_626A:
	ld a,(0ed59h)		;626a   ; siguiente formacion de las seis
	inc a			;626d
	cp 006h		;626e
	jr c,L_6274		;6270
	sub 006h		;6272
L_6274:
	set 7,a		;6274   ; bit 7: repintar
	ld (0ed59h),a		;6276
	ret			;6279
boton2_suelto:		; Boton 2 suelto
	xor a			;627a
	ld (0e83dh),a		;627b
	ret			;627e
boton2_defensa:		; SUPOSICION: El boton 2 del equipo sin balon pasa el control al siguiente de sus tres jugadores
	ld a,(0e83ch)		;627f
	and 001h		;6282   ; equipo con el balon
	ld a,(0e6d3h)		;6284   ; entrada del izquierdo si defiende
	jr nz,L_628C		;6287
	ld a,(0e6d5h)		;6289   ; entrada del derecho si defiende
L_628C:
	bit 6,a		;628c   ; bit 6: boton 2
	jr z,boton2_defensa_suelto		;628e
	ld a,(0e83eh)		;6290   ; ya estaba pulsado
	and a			;6293
	ret nz			;6294
	ld a,0ffh		;6295
	ld (0e83eh),a		;6297
	ld a,(0e83ch)		;629a   ; defiende el derecho?
	and a			;629d
	jr nz,L_62AC		;629e
	ld a,(0e6dbh)		;62a0   ; controlado del derecho
	inc a			;62a3   ; siguiente de 3 a 5
	cp 006h		;62a4
	jr c,L_62B5		;62a6
	ld a,003h		;62a8
	jr L_62B5		;62aa
L_62AC:
	ld a,(0e6d8h)		;62ac   ; controlado del izquierdo
	inc a			;62af   ; siguiente de 0 a 2
	cp 003h		;62b0
	jr c,L_62B5		;62b2
	xor a			;62b4
L_62B5:
	jp controla		;62b5   ; nuevo controlado
boton2_defensa_suelto:		; Boton 2 suelto
	xor a			;62b8
	ld (0e83eh),a		;62b9
	ret			;62bc
boton1_defensa:		; SUPOSICION: Al pulsar el boton 1 del equipo sin balon pide un intento de robo (0xE6ED)
	ld a,(0e6edh)		;62bd   ; intento aun pendiente
	and a			;62c0
	ret nz			;62c1
	ld a,(0e83ch)		;62c2   ; equipo con el balon
	and 001h		;62c5
	jr z,L_62CE		;62c7
	ld a,(0e6d3h)		;62c9   ; entrada del izquierdo
	jr L_62D1		;62cc
L_62CE:
	ld a,(0e6d5h)		;62ce   ; entrada del derecho
L_62D1:
	bit 7,a		;62d1   ; bit 7: boton 1
	ld a,000h		;62d3
	jr z,L_62D8		;62d5
	inc a			;62d7
L_62D8:
	ld hl,0e841h		;62d8   ; estado anterior del boton
	cp (hl)			;62db
	ret z			;62dc
	ld (hl),a			;62dd   ; estado nuevo
	and a			;62de
	ret z			;62df
	ld (0e6edh),a		;62e0   ; recien pulsado: intento de robo
	ret			;62e3

; ----------------------------------------------------------------------
; ===== Faltas: rotulo, tiros libres y saques =====
; ----------------------------------------------------------------------
pita_falta:		; Falta del jugador de 0xED6F: rotulo, silbato y, segun el tipo, tiros libres o saque
	ld a,(0e6cfh)		;62e4
	and 0c0h		;62e7   ; con el balon en vuelo no se pita aun
	jr nz,sin_falta		;62e9
	call balon_quieto		;62eb
	ld a,(0ed6fh)		;62ee   ; infractor
	call registro_jugador		;62f1
	call xy_registro		;62f4
	call aparta_del_centro		;62f7   ; posicion de la falta lejos del centro
	ld (0ed72h),de		;62fa   ; posicion de la falta
	call rotulo_falta		;62fe   ; rotulo, silbato y ventana hacia la falta
	ld de,sin_falta		;6301   ; al acabar, sin falta pendiente
	push de			;6304
	ld a,(0ed70h)		;6305   ; tipos 0-4 (pasos y cuentas): saque
	cp 005h		;6308
	jp c,saque		;630a
	ld a,(0ed6fh)		;630d
	call registro_jugador		;6310
	ld de,0000fh		;6313
	add hl,de			;6316
	bit 3,(hl)		;6317   ; falta en ataque: saque
	jp nz,saque		;6319
	ld a,(0ed71h)		;631c   ; jugador que recibe la falta
	ld (0ed95h),a		;631f
	call registro_jugador		;6322
	ld de,0000ch		;6325   ; estaba en el aire (tirando)
	add hl,de			;6328
	ld a,(hl)			;6329
	and a			;632a
	jp nz,tiros_libres		;632b   ; si: tiros libres
	call zona_tiro		;632e   ; zona de la victima
	ld a,(0ed94h)		;6331   ; dentro de la zona: tiros libres
	and a			;6334
	jp z,tiros_libres		;6335
	ld a,(0e83ch)		;6338   ; equipo con el balon
	ld hl,0ea2eh		;633b   ; faltas del equipo izquierdo
	and a			;633e
	jr nz,L_6344		;633f
	ld hl,0ea5eh		;6341   ; faltas del equipo derecho
L_6344:
	ld a,(hl)			;6344
	cp 007h		;6345   ; SUPOSICION: 7 o mas: tiros de bonus
	jp nc,bonus		;6347
	jp saque		;634a
sin_falta:		; Infractor, tipo y victima a 0xFF
	ld a,0ffh		;634d
	ld (0ed6fh),a		;634f
	ld (0ed70h),a		;6352
	ld (0ed71h),a		;6355
	ret			;6358
pareja_infractor:		; A = defensor emparejado (+0x25) del infractor
	ld a,(0ed6fh)		;6359   ; infractor
	call registro_jugador		;635c
	ld de,00025h		;635f
	add hl,de			;6362
	ld a,(hl)			;6363   ; su par (+0x25)
	ret			;6364
bonus:		; SUPOSICION: tiros con el bit 7 (uno mas uno)
	ld a,082h		;6365
	jr L_6381		;6367
aparta_del_centro:		; SUPOSICION: si la X de la falta esta a menos de 8 del centro la lleva a +8 o -8 segun la ventana
	ld a,e			;6369
	and a			;636a
	jp p,L_6370		;636b
	neg		;636e
L_6370:
	cp 008h		;6370   ; a 8 o mas del centro: se queda
	ret nc			;6372
	ld a,(0e830h)		;6373   ; columna de la ventana
	and a			;6376
	jr nz,L_637C		;6377
	ld e,0f8h		;6379   ; a -8
	ret			;637b
L_637C:
	ld e,008h		;637c
	ret			;637e
tiros_libres:		; Dos tiros libres para la victima: colocacion, bote, cinco segundos para tirar
	ld a,002h		;637f   ; dos tiros
L_6381:
	ld (0ed74h),a		;6381
L_6384:
	call coloca_tiros_libres		;6384   ; coloca a todos en la linea
	ld a,(0ed71h)		;6387   ; balon al tirador
	call da_balon		;638a
	call oculta_balon		;638d
	ld a,001h		;6390   ; movimiento y mandos bloqueados
	ld (0ed6ch),a		;6392
	ld (0ed69h),a		;6395
	ld (0ed6ah),a		;6398
	ld (0e6e2h),a		;639b
	call borra_entradas		;639e   ; entradas a cero
L_63A1:
	call cuadro_partido		;63a1
	call todos_llegaron		;63a4   ; hasta que lleguen todos
	jr nz,L_63A1		;63a7
siguiente_tiro_libre:		; Tirador mirando al aro, bote y cuenta de cinco segundos
	ld hl,(0ed75h)		;63a9
	ld de,00003h		;63ac
	add hl,de			;63af
	ld a,(hl)			;63b0
	call pose_tirador		;63b1   ; pose del tirador mirando a la canasta
	call muestra_balon		;63b4
	ld a,001h		;63b7   ; bote forzado
	ld (0e6f2h),a		;63b9
	ld a,03ch		;63bc   ; un segundo botando
	ld (0e6efh),a		;63be
L_63C1:
	call cuadro_partido		;63c1
	ld a,(0e6efh)		;63c4
	and a			;63c7
	jr nz,L_63C1		;63c8
	xor a			;63ca
	ld (0e6f2h),a		;63cb
	inc a			;63ce
	ld (0ed6dh),a		;63cf   ; tiro solo con el boton
	ld hl,0efdeh		;63d2
	set 6,(hl)		;63d5
	call espera_300		;63d7   ; cinco segundos para tirar
	call retardo_maquina		;63da
L_63DD:
	call cuadro_partido		;63dd
	ld a,(0e83ch)		;63e0   ; boton del equipo que tira
	call lee_mando_lado		;63e3
	bit 7,a		;63e6
	call nz,cuenta_tiro_libre		;63e8
	ld a,(0e6cfh)		;63eb   ; ya ha tirado
	bit 7,a		;63ee
	jr nz,L_63FB		;63f0
	ld hl,(0ed90h)		;63f2   ; sin tiempo: violacion
	ld a,h			;63f5
	or l			;63f6
	jr nz,L_63DD		;63f7
	jr violacion_5s		;63f9
L_63FB:
	jr tras_tiro_libre		;63fb
violacion_5s:		; Se acabo el tiempo del tiro libre o del saque: 5 SECOND y saque del rival
	xor a			;63fd
	ld (0e6e2h),a		;63fe
	ld (0ed6dh),a		;6401
	ld (0ed6ah),a		;6404
	ld (0ed77h),a		;6407
	ld a,002h		;640a   ; rotulo 2: 5 SECOND
	ld (0ed70h),a		;640c
	ld a,(0ed71h)		;640f
	and a			;6412
	call m,pareja_infractor		;6413   ; SUPOSICION: infractor el emparejado
	ld (0ed6fh),a		;6416
	push af			;6419
	call rotulo_falta		;641a
	pop af			;641d
	jp saque		;641e
cuenta_tiro_libre:		; Al pulsar arranca la cuenta del tiro automatico (4 pasos)
	ld a,(0ed77h)		;6421   ; cuenta ya en marcha
	and a			;6424
	ret nz			;6425
	ld a,004h		;6426   ; cuatro pasos
	ld (0ed77h),a		;6428
	ret			;642b
tras_tiro_libre:		; Quedan tiros? espera a que el balon se pare y repite
	ld a,(0ed74h)		;642c   ; tiros que quedan
	dec a			;642f
	bit 0,a		;6430   ; bit 0 a 0: era el ultimo
	ld (0ed74h),a		;6432
	jr z,ultimo_tiro_libre		;6435
	and a			;6437
	jp m,tiro_bonus		;6438   ; bit 7: uno mas uno
L_643B:
	call cuadro_partido		;643b   ; espera a que el balon se pare
	ld a,(0e62ch)		;643e
	and a			;6441
	jr nz,L_643B		;6442
	ld a,(0ed71h)		;6444   ; balon otra vez al tirador
	ld (0e6cfh),a		;6447
	xor a			;644a
	ld (0ed63h),a		;644b
	jp siguiente_tiro_libre		;644e
ultimo_tiro_libre:		; Tras el ultimo tiro se reanuda el juego
	call reanuda		;6451
	ld a,002h		;6454
	ld (0ed7fh),a		;6456   ; SUPOSICION: rebote pendiente
	jp al_rebote		;6459
reanuda:		; Desbloquea movimiento y mandos y pone el reloj en marcha
	xor a			;645c
	ld (0ed6dh),a		;645d   ; sin tiro forzado
	ld (0ed6ah),a		;6460   ; defensa libre
	ld (0ed69h),a		;6463   ; ataque libre
	ld (0ed6ch),a		;6466   ; mandos libres
	ld (0e6e2h),a		;6469   ; eleccion de receptor libre
	jp reloj_en_marcha		;646c
tiro_bonus:		; SUPOSICION: uno mas uno: si el primero entra se tira el segundo
	call reanuda		;646f
	ld a,001h		;6472
	ld (0ed7dh),a		;6474   ; reloj parado
	call al_rebote		;6477
L_647A:
	call cuadro_partido		;647a
	ld a,(0e6cfh)		;647d   ; espera a que el balon quede suelto
	cp 007h		;6480
	jr nz,L_647A		;6482
	ld a,(0ed74h)		;6484
	bit 0,a		;6487
	jr z,reanuda		;6489
	ld a,(0e6f9h)		;648b   ; fallo: se reanuda
	and a			;648e
	jp m,reanuda		;648f
	ld a,001h		;6492
	ld (0ed6ah),a		;6494
	ld (0ed69h),a		;6497
	ld (0ed6ch),a		;649a
	xor a			;649d
	ld (0ed6bh),a		;649e
	ld (0ed63h),a		;64a1
	dec a			;64a4
	ld (0ed66h),a		;64a5
L_64A8:
	call cuadro_partido		;64a8
	ld a,(0e62ch)		;64ab
	and a			;64ae
	jr nz,L_64A8		;64af
	jp L_6384		;64b1
todos_llegaron:		; Z cuando ningun jugador tiene destino (+0x20/+0x21)
	ld hl,0e520h		;64b4   ; destino del primer jugador
	ld de,0002fh		;64b7
	ld b,006h		;64ba
	xor a			;64bc
L_64BD:
	or (hl)			;64bd   ; destino Y
	inc hl			;64be
	or (hl)			;64bf   ; destino X
	add hl,de			;64c0   ; siguiente registro
	djnz L_64BD		;64c1
	and a			;64c3
	ret			;64c4
coloca_tiros_libres:		; Destinos de la linea de tiros libres (tablas 0x651C y 0x6528) para todos menos el tirador
	call pareja_infractor		;64c5
	call registro_jugador		;64c8   ; registro del emparejado del infractor
	ld (0ed75h),hl		;64cb
	ld de,00020h		;64ce
	add hl,de			;64d1
	cp 003h		;64d2
	ld de,0651ch		;64d4   ; tabla de un lado
	jr c,L_64DC		;64d7
	ld de,06528h		;64d9   ; tabla del otro
L_64DC:
	call pon_destino		;64dc
	ld hl,0e520h		;64df
	ld c,000h		;64e2
	ld b,006h		;64e4
L_64E6:
	ld a,(0ed71h)		;64e6   ; el tirador no se mueve
	cp c			;64e9
	call nz,pon_destino		;64ea   ; destino de la tabla
	call siguiente_registro		;64ed   ; siguiente registro
	inc c			;64f0
	djnz L_64E6		;64f1
	ret			;64f3
pose_tirador:		; Pose del tirador mirando a un lado o al otro (direccion 2 o 6)
	ex af,af'			;64f4
	ld hl,(0ed75h)		;64f5   ; registro del tirador
	ld de,0000dh		;64f8
	add hl,de			;64fb
	ld a,(hl)			;64fc
	and 0e3h		;64fd   ; pose sin la direccion
	ld c,a			;64ff
	ex af,af'			;6500
	and a			;6501   ; signo de la X del tirador (en A')
	ld a,008h		;6502   ; direccion 2
	jp p,L_6509		;6504
	ld a,018h		;6507   ; direccion 6
L_6509:
	or c			;6509
	ld (hl),a			;650a
	ret			;650b
pon_destino:		; Destino Y, X desde la tabla DE
	ld a,(de)			;650c   ; destino Y de la tabla
	inc de			;650d
	ld (hl),a			;650e
	inc hl			;650f
	ld a,(de)			;6510   ; destino X de la tabla
	inc de			;6511
	ld (hl),a			;6512
	dec hl			;6513
	ret			;6514
siguiente_registro:		; HL + 0x30
	push de			;6515
	ld de,00030h		;6516
	add hl,de			;6519
	pop de			;651a
	ret			;651b

; ----------------------------------------------------------------------
; DATOS posiciones_a: Seis pares (X, Y) que recorre 0x64D4
;   0x651c..0x6528  (12 bytes)
DATA_posiciones_a:
	defb 03ah,038h	; 651c
	defb 02ah,048h	; 651e
	defb 04ah,048h	; 6520
	defb 02ah,054h	; 6522
	defb 04ah,054h	; 6524
	defb 060h,01eh	; 6526

; ----------------------------------------------------------------------
; DATOS posiciones_b: Seis pares (X, Y) que recorre 0x64D9: las mismas X que
;   0x651C con la Y del otro lado
;   0x6528..0x6534  (12 bytes)
DATA_posiciones_b:
	defb 03ah,0c8h	; 6528
	defb 02ah,0ach	; 652a
	defb 04ah,0ach	; 652c
	defb 060h,0e2h	; 652e
	defb 02ah,0b8h	; 6530
	defb 04ah,0b8h	; 6532

; ======================================================================
; CODIGO 0x6534..0x670f  (475 bytes)
; ======================================================================


rotulo_falta:		; Prepara 0xEFCD (tipo, equipo y jugador), silbato, rotulo y desplaza la ventana hacia la falta
	ld a,(0ed6fh)		;6534
	cp 003h		;6537
	push af			;6539
	call registro_jugador		;653a
	ld de,0001fh		;653d   ; +0x1F: jugador en el roster
	add hl,de			;6540
	ld a,(hl)			;6541
	ld b,a			;6542
	pop af			;6543
	jr c,L_6548		;6544
	set 7,b		;6546   ; equipo derecho
L_6548:
	ld a,(0ed70h)		;6548   ; tipo de falta por 8
	add a,a			;654b
	add a,a			;654c
	add a,a			;654d
	or b			;654e
	ld (0efcdh),a		;654f
	ld a,003h		;6552   ; pieza 3: silbato
	call arranca_sonido		;6554
	call rotulo_falta_marcador		;6557   ; SUPOSICION: apunta la falta y su rotulo
	ld a,(0e831h)		;655a   ; solo con la ventana en el centro
	cp 080h		;655d
	ret nz			;655f
	ld hl,(0ed72h)		;6560
	ld a,l			;6563
	and a			;6564
	ld c,008h		;6565   ; bit 3: ventana a la izquierda
	jp p,L_656C		;6567
	ld c,010h		;656a   ; bit 4: ventana a la derecha
L_656C:
	ld a,(0e6cfh)		;656c
	or c			;656f
	ld (0e6cfh),a		;6570
	ld a,001h		;6573   ; movimiento parado
	ld (0ed6bh),a		;6575
	ret			;6578
saque:		; Saque del equipo que no cometio la falta: colocacion, cinco segundos y pase desde fuera
	ld a,(0ed6fh)		;6579
	call registro_jugador		;657c
	call posiciones_saque		;657f   ; posiciones del saque
	call sin_destinos		;6582   ; sin destinos los del otro equipo
	xor a			;6585   ; sin bote forzado
	ld (0e6f2h),a		;6586
	inc a			;6589
	ld (0ed6bh),a		;658a
	ld (0ed69h),a		;658d
	ld (0ed6ch),a		;6590
	call borra_entradas		;6593
	call oculta_balon		;6596   ; balon oculto mientras se colocan
	call equipo_con_balon		;6599   ; primer jugador del equipo que saca
	ld de,00020h		;659c   ; su destino: el punto de saque
	add hl,de			;659f
	ld d,(hl)			;65a0
	inc hl			;65a1
	ld e,(hl)			;65a2
	dec hl			;65a3
	push hl			;65a4
	push de			;65a5
	push hl			;65a6
L_65A7:
	call cuadro_partido		;65a7
	call todos_llegaron		;65aa   ; hasta que lleguen todos
	jr nz,L_65A7		;65ad
	call muestra_balon		;65af
	ld a,001h		;65b2
	call espera_300		;65b4   ; cinco segundos para sacar
	ld (0e6f2h),a		;65b7
	pop hl			;65ba
	ld de,00020h		;65bb
	and a			;65be
	sbc hl,de		;65bf
	call pose_saque		;65c1   ; pose del que saca
	call retardo_maquina		;65c4
L_65C7:
	call cuadro_partido		;65c7
	ld a,(0e83ch)		;65ca
	call lee_mando_lado		;65cd   ; boton del equipo que saca
	bit 7,a		;65d0
	ld c,03fh		;65d2
	ld de,00000h		;65d4
	jr nz,L_65E2		;65d7
	ld hl,(0ed90h)		;65d9   ; sin tiempo: violacion
	ld a,h			;65dc
	or l			;65dd
	jr nz,L_65C7		;65de
	jr L_662B		;65e0
L_65E2:
	call controlado		;65e2   ; controlado del equipo que saca
	call registro_jugador		;65e5
	push hl			;65e8
	pop ix		;65e9
	call pase		;65eb   ; pasa
	xor a			;65ee
	ld (0e6f2h),a		;65ef
L_65F2:
	call cuadro_partido		;65f2
	ld a,(0e6cfh)		;65f5   ; espera a que alguien lo coja
	cp 007h		;65f8
	jr nc,L_65F2		;65fa
	call reloj_en_marcha		;65fc   ; reloj en marcha
	call cuenta_30s		;65ff   ; cuenta de 30 segundos
	call pose_bit6		;6602
	call nz,cuenta_10s		;6605   ; y la de 10 si esta en su campo
	pop de			;6608
	pop hl			;6609
	ld a,d			;660a   ; punto del saque
	cp 039h		;660b
	ld d,008h		;660d   ; vuelve a la pista por un lado
	jr c,L_6613		;660f
	ld d,06ch		;6611   ; o por el otro
L_6613:
	ld (hl),d			;6613
	inc hl			;6614
	ld (hl),e			;6615
	dec hl			;6616
L_6617:
	push hl			;6617   ; hasta que llegue
	call cuadro_partido		;6618
	pop hl			;661b
	ld a,(hl)			;661c
	and a			;661d
	jr nz,L_6617		;661e
	xor a			;6620   ; juego normal
	ld (0ed69h),a		;6621
	ld (0ed6bh),a		;6624
	ld (0ed6ch),a		;6627
	ret			;662a
L_662B:
	pop de			;662b
	pop de			;662c
	jp violacion_5s		;662d
borra_entradas:		; 0xE6D3-0xE6D6 a cero: entradas y cuadros de boton de los dos equipos
	xor a			;6630
	ld hl,0e6d3h		;6631
	ld b,004h		;6634
L_6636:
	ld (hl),a			;6636
	inc hl			;6637
	djnz L_6636		;6638
	ret			;663a
sin_destinos:		; Borra el destino de los tres del otro equipo
	call equipo_sin_balon		;663b
	ld de,00020h		;663e
	add hl,de			;6641
	ld b,003h		;6642
L_6644:
	ld (hl),000h		;6644   ; destino Y a cero
	inc hl			;6646
	ld (hl),000h		;6647   ; destino X a cero
	dec hl			;6649
	call siguiente_registro		;664a   ; siguiente registro
	djnz L_6644		;664d
	ret			;664f
pose_saque:		; Pose 0x62 del que saca mirando hacia la pista
	push hl			;6650
	inc hl			;6651
	ld a,(hl)			;6652   ; Y del que saca
	dec hl			;6653
	cp 039h		;6654   ; de que lado del medio (Y 0x39)?
	ld a,000h		;6656   ; direccion 0
	jr nc,L_665C		;6658
	ld a,004h		;665a   ; direccion 4
L_665C:
	add a,a			;665c   ; por 4
	add a,a			;665d
	ld b,a			;665e
	ld de,0000dh		;665f
	add hl,de			;6662
	ld a,062h		;6663   ; pose 0x62 de saque
	or b			;6665
	ld (hl),a			;6666
	inc hl			;6667
	inc hl			;6668
	set 7,(hl)		;6669   ; pose cambiada
	pop hl			;666b
	ret			;666c
posiciones_saque:		; Elige la tabla de posiciones del saque segun el lado de la falta y el campo
	push hl			;666d
	ld de,0000fh		;666e
	add hl,de			;6671
	ld a,(hl)			;6672
	pop hl			;6673
	bit 3,a		;6674   ; bit 3: sentido de ataque
	jp z,posiciones_saque_b		;6676
	call pose_bit6		;6679
	call balon_a_sacador		;667c
	jp z,posiciones_campo_propio		;667f   ; en su campo
L_6682:
	bit 6,c		;6682   ; bit 6: mitad de la falta
	jr z,L_6695		;6684
	call punto_falta		;6686
	jr c,L_6690		;6689
	ld de,06714h		;668b   ; tabla de posiciones 0x6714
	jr L_66A2		;668e
L_6690:
	ld de,0671eh		;6690
	jr L_66A2		;6693
L_6695:
	call punto_falta		;6695
	jr c,L_669F		;6698
	ld de,0670fh		;669a
	jr L_66A2		;669d
L_669F:
	ld de,06719h		;669f
L_66A2:
	call equipo_con_balon		;66a2   ; equipo que saca
	push de			;66a5
	ld de,00020h		;66a6   ; destino del primero
	add hl,de			;66a9
	pop de			;66aa
	ld a,(de)			;66ab
	inc de			;66ac
	ld (hl),a			;66ad   ; destino Y de la tabla
	inc hl			;66ae
	ld (hl),c			;66af   ; destino X = la de la falta
	dec hl			;66b0
	ld b,002h		;66b1   ; los otros dos
L_66B3:
	call siguiente_registro		;66b3   ; siguiente registro
	call pon_destino		;66b6   ; su destino de la tabla
	djnz L_66B3		;66b9
	ld a,(0e83ch)		;66bb   ; equipo con el balon
	and a			;66be
	ld a,000h		;66bf   ; saca el jugador 0
	jp z,da_balon		;66c1
	ld a,003h		;66c4   ; o el 3
	jp da_balon		;66c6
punto_falta:		; H, L = posicion de la falta (Y, X); acarreo si la Y es menor de 0x39
	ld hl,(0ed72h)		;66c9
	ld a,h			;66cc
	ld c,l			;66cd
	cp 039h		;66ce
	ret			;66d0
posiciones_saque_b:		; Lo mismo para el otro sentido
	call pose_bit6		;66d1
	call balon_a_sacador		;66d4
	jp z,posiciones_campo_propio		;66d7
	jp L_6682		;66da
balon_a_sacador:		; Da el balon al equipo del emparejado del infractor
	push af			;66dd
	push bc			;66de
	push de			;66df
	push hl			;66e0
	call pareja_infractor		;66e1   ; par del infractor
	cp 003h		;66e4   ; de que equipo es
	ld a,000h		;66e6   ; saca el jugador 0
	jr c,L_66EC		;66e8
	ld a,003h		;66ea   ; o el 3
L_66EC:
	call da_balon		;66ec   ; le da el balon
	pop hl			;66ef
	pop de			;66f0
	pop bc			;66f1
	pop af			;66f2
	ret			;66f3
equipo_con_balon:		; HL = primer registro del equipo con el balon (0xE500 o 0xE590)
	push af			;66f4
	ld a,(0e83ch)		;66f5   ; equipo con el balon
	and a			;66f8
	ld hl,0e500h		;66f9   ; izquierdo: 0xE500
	jr z,L_6701		;66fc
	ld hl,0e590h		;66fe   ; derecho: 0xE590
L_6701:
	pop af			;6701
	ret			;6702
equipo_sin_balon:		; HL = primer registro del otro equipo
	ld a,(0e83ch)		;6703   ; equipo con el balon
	and a			;6706
	ld hl,0e500h		;6707   ; 0xE500 si ataca el derecho
	ret nz			;670a
	ld hl,0e590h		;670b   ; 0xE590 si ataca el izquierdo
	ret			;670e

; ----------------------------------------------------------------------
; DATOS posiciones_c: Cuatro fichas de cinco bytes (0x670F, 0x6714, 0x6719,
;   0x671E) que cargan 0x669A, 0x668B, 0x669F y 0x6690
;   0x670f..0x6723  (20 bytes)
DATA_posiciones_c:
	defb 070h,03ah,0dch,014h,0b8h	; 670f
	defb 070h,03ah,024h,014h,048h	; 6714
	defb 004h,03ah,0dch,014h,0b8h	; 6719
	defb 004h,03ah,024h,014h,048h	; 671e

; ======================================================================
; CODIGO 0x6723..0x6765  (66 bytes)
; ======================================================================


posiciones_campo_propio:		; Posiciones del saque en el campo propio (tablas 0x6765-0x6771)
	bit 6,c		;6723   ; bit 6: mitad de la falta
	jr z,L_6736		;6725
	call punto_falta		;6727
	jr c,L_6731		;672a
	ld de,06769h		;672c   ; tabla 0x6769
	jr L_6743		;672f
L_6731:
	ld de,06771h		;6731
	jr L_6743		;6734
L_6736:
	call punto_falta		;6736
	jr c,L_6740		;6739
	ld de,06765h		;673b
	jr L_6743		;673e
L_6740:
	ld de,0676dh		;6740
L_6743:
	call equipo_con_balon		;6743   ; equipo que saca
	push de			;6746
	ld de,00020h		;6747   ; destino del primero
	add hl,de			;674a
	pop de			;674b
	call destino_tabla		;674c   ; dos jugadores con la X de C
	call destino_tabla		;674f
	ld a,(de)			;6752   ; el tercero: Y e X de la tabla
	inc de			;6753
	ld (hl),a			;6754
	inc hl			;6755
	ld a,(de)			;6756
	ld (hl),a			;6757
	ret			;6758
destino_tabla:		; Destino Y desde la tabla y la X de C, y siguiente registro
	ld a,(de)			;6759   ; destino Y de la tabla
	inc de			;675a
	ld (hl),a			;675b
	inc hl			;675c
	ld (hl),c			;675d   ; destino X = C
	push de			;675e
	ld de,0002fh		;675f   ; siguiente registro (+0x30 desde +0x21)
	add hl,de			;6762
	pop de			;6763
	ret			;6764

; ----------------------------------------------------------------------
; DATOS posiciones_d: Cuatro fichas de cuatro bytes (0x6765, 0x6769, 0x676D,
;   0x6771) que cargan 0x673B, 0x672C, 0x6740 y 0x6731
;   0x6765..0x6775  (16 bytes)
DATA_posiciones_d:
	defb 070h,03ah,014h,048h	; 6765
	defb 070h,03ah,014h,0b8h	; 6769
	defb 004h,03ah,060h,048h	; 676d
	defb 004h,03ah,060h,0a0h	; 6771

; ======================================================================
; CODIGO 0x6775..0x693d  (456 bytes)
; ======================================================================


salto_entre_dos:		; Cuadro del salto inicial: silbato, balon arriba y salto de los dos controlados al pulsar
	ld hl,(0e6efh)		;6775   ; cuenta atras del salto
	ld a,h			;6778
	or l			;6779
	jr nz,silbato_salto		;677a
	ld a,(0e62ch)		;677c   ; balon aun sin lanzar
	and a			;677f
	call z,lanza_balon_salto		;6780
	ld a,(0e62bh)		;6783   ; el balon ya cae?
	and a			;6786
	ret p			;6787
	call recoge_balon		;6788   ; alguien lo coge?
	ld a,(0e6cfh)		;678b
	cp 007h		;678e
	jp c,fin_salto		;6790
	xor a			;6793
	call lee_mando_lado		;6794   ; boton del equipo izquierdo
	bit 7,a		;6797
	ld a,(0e6d8h)		;6799
	call nz,salta_por_el_balon		;679c
	ld a,001h		;679f
	call lee_mando_lado		;67a1   ; boton del equipo derecho
	bit 7,a		;67a4
	ld a,(0e6dbh)		;67a6
	call nz,salta_por_el_balon		;67a9
	ret			;67ac
silbato_salto:		; A tres segundos del lanzamiento, pieza 3 una sola vez
	ld de,000b4h		;67ad   ; tres segundos antes
	sbc hl,de		;67b0
	ret nc			;67b2
	ld a,(0ed6eh)		;67b3   ; silbato ya tocado
	and a			;67b6
	ret nz			;67b7
	ld a,0ffh		;67b8   ; una sola vez
	ld (0ed6eh),a		;67ba
	ld a,003h		;67bd   ; pieza 3: silbato
	jp arranca_sonido		;67bf
salta_por_el_balon:		; El controlado A salta (pose 0x41)
	ld (0e721h),a		;67c2   ; jugador en curso
	call registro_jugador		;67c5
	push hl			;67c8
	pop ix		;67c9
	ld a,(ix+00dh)		;67cb   ; direccion de la pose
	and 01ch		;67ce
	ld c,a			;67d0
	ld a,041h		;67d1   ; pose 0x41: salto
	or c			;67d3
	ld (ix+00dh),a		;67d4
	set 7,(ix+00fh)		;67d7   ; pose cambiada
	jp salto		;67db   ; despega
palmeo_salto:		; El jugador C toca el balon en el salto entre dos: lo palmea hacia un companero (3 de 4 veces) o hacia un rival
	ld a,c			;67de
	ld (0e6d2h),a		;67df   ; SUPOSICION: ultimo poseedor
	ld a,003h		;67e2   ; jugadores 0-3: palmea el del equipo izquierdo
	cp c			;67e4
	jr c,L_6813		;67e5
	ld a,001h		;67e7   ; saltador izquierdo: jugador 1
	call registro_jugador		;67e9
	push hl			;67ec
	pop ix		;67ed
	ld (ix+00dh),049h		;67ef   ; pose de palmeo
	set 7,(ix+00fh)		;67f3
	call aleatorio		;67f7   ; una vez de cada cuatro al rival
	cp 040h		;67fa
	jr c,L_6809		;67fc
	ld a,008h		;67fe   ; ventana hacia la derecha
	ld (0e6c0h),a		;6800
	ld a,002h		;6803   ; al companero 2
	ld c,07bh		;6805
	jr palmea_a		;6807
L_6809:
	xor a			;6809
	ld (0e6c0h),a		;680a
	ld a,003h		;680d   ; al rival 3
	ld c,07bh		;680f
	jr palmea_a		;6811
L_6813:
	ld a,004h		;6813   ; saltador derecho: jugador 4
	call registro_jugador		;6815
	push hl			;6818
	pop ix		;6819
	ld (ix+00dh),059h		;681b   ; pose de palmeo
	set 7,(ix+00fh)		;681f
	call aleatorio		;6823
	cp 040h		;6826
	jr nc,L_6834		;6828
	xor a			;682a
	ld (0e6c0h),a		;682b
	ld a,000h		;682e   ; al rival 0
	ld c,06bh		;6830
	jr palmea_a		;6832
L_6834:
	ld a,010h		;6834   ; ventana hacia la izquierda
	ld (0e6c0h),a		;6836
	ld a,005h		;6839   ; al companero 5
	ld c,06bh		;683b
palmea_a:		; Lanza el balon como un tiro hacia el jugador A, que se pone en pose de recibir
	ld (0e6e3h),a		;683d
	call registro_jugador		;6840
	push hl			;6843
	ld de,0000dh		;6844
	add hl,de			;6847
	ld (hl),c			;6848   ; pose de recibir
	inc hl			;6849
	inc hl			;684a
	set 7,(hl)		;684b
	pop hl			;684d
	call xy_registro		;684e
	ld a,d			;6851
	ld (0e6c4h),a		;6852   ; el destino del tiro es el receptor
	ld a,e			;6855
	ld (0e6c6h),a		;6856
	ld a,087h		;6859   ; balon en vuelo
	ld (0e6cfh),a		;685b
	ld a,(0e629h)		;685e   ; sale de la altura a la que estaba
	ld (0e62dh),a		;6861
	jp tiro		;6864
fin_salto:		; Acaba el salto entre dos: balon en la mano, canasta del equipo que lo tiene y sin falta pendiente
	xor a			;6867
	ld (0e6f1h),a		;6868   ; salto entre dos acabado
	ld (0ed79h),a		;686b
	ld hl,00000h		;686e
	ld (0e62ch),a		;6871   ; fisica del balon a cero
	ld (0e62dh),a		;6874
	ld (0e624h),hl		;6877
	ld (0e626h),hl		;687a
	ld (0e628h),hl		;687d
	ld (0e62ah),hl		;6880
	ld (0e62fh),hl		;6883
	ld (0e631h),hl		;6886
	ld a,(0e6cfh)		;6889   ; equipo del poseedor
	and 007h		;688c
	cp 003h		;688e
	ld a,062h		;6890   ; SUPOSICION: canasta a la que ataca
	jr c,L_6896		;6892
	neg		;6894
L_6896:
	ld hl,0e6c3h		;6896
	inc hl			;6899
	ld (hl),039h		;689a
	inc hl			;689c
	inc hl			;689d
	ld (hl),a			;689e
	xor a			;689f
	ld (0f008h),a		;68a0   ; balon ya no lanzado
	ld (0ed6eh),a		;68a3
	dec a			;68a6
	ld (0ed6fh),a		;68a7   ; sin falta
	ld (0ed71h),a		;68aa
	ld (0ed70h),a		;68ad
	ld a,(0e6d8h)		;68b0   ; refresca el controlado de los dos equipos
	call controla		;68b3
	ld a,(0e6dbh)		;68b6
	jp controla		;68b9
lanza_balon_salto:		; El arbitro lanza el balon: centro de la pista, altura 0xF0 y velocidad 0x244 hacia arriba
	ld a,03ah		;68bc   ; Y del centro
	ld (0e621h),a		;68be
	ld a,000h		;68c1
	ld (0e623h),a		;68c3
	ld a,00fh		;68c6   ; gravedad
	ld (0e62ch),a		;68c8
	ld a,0f0h		;68cb   ; altura de salida
	ld (0e629h),a		;68cd
	ld hl,00244h		;68d0   ; velocidad vertical
	ld (0e62ah),hl		;68d3
	ld a,0ffh		;68d6
	ld (0f008h),a		;68d8
	ret			;68db
retardo_maquina:		; SUPOSICION: 12 cuadros de reaccion de la maquina (0xF010/0xF011) si estaban a cero
	ld a,(0e83ch)		;68dc
	and a			;68df
	ld hl,0f010h		;68e0
	jr z,L_68E6		;68e3
	inc hl			;68e5
L_68E6:
	ld a,(hl)			;68e6
	and a			;68e7
	ret nz			;68e8
	ld (hl),00ch		;68e9
	ret			;68eb
maquina:		; Jugador no controlado: decide destino (ataque o defensa) y anda hacia el
	bit 3,(ix+00fh)		;68ec   ; bit 3: atacante
	jr nz,L_68F7		;68f0
	call defensa_maquina		;68f2   ; defiende
	jr anda_al_destino		;68f5
L_68F7:
	call ataque_maquina		;68f7   ; ataca
anda_al_destino:		; Jugador IX: si tiene destino (+0x20/+0x21) y no espera (+0x26), DE y C = paso y direccion hacia el; si no, parado; HL = su registro
	ld h,(ix+020h)		;68fa   ; destino
	ld l,(ix+021h)		;68fd
	bit 7,h		;6900   ; negativo: sin destino
	jr nz,L_6926		;6902
	ld a,h			;6904
	or l			;6905
	jr z,L_6926		;6906
	ld a,(ix+026h)		;6908   ; aun esperando (+0x26)
	and a			;690b
	jr nz,L_6926		;690c
	ld d,(ix+001h)		;690e
	ld e,(ix+003h)		;6911
	ld b,010h		;6914   ; rumbo al destino
	call diferencia_xy		;6916
	call mitad_de		;6919
	call rumbo		;691c
	call vector_direccion		;691f   ; vector de la direccion
	push ix		;6922
	pop hl			;6924
	ret			;6925
L_6926:
	ld de,00000h		;6926   ; se queda parado
	ld c,03fh		;6929
	push ix		;692b
	pop hl			;692d
	ret			;692e
vector_direccion:		; DE = paso (dx, dy) de la tabla 0x693D para la direccion A; C = A
	add a,a			;692f   ; dos bytes por direccion
	ld hl,0693dh		;6930   ; tabla de pasos
	ld e,a			;6933
	ld d,000h		;6934
	add hl,de			;6936
	rrca			;6937   ; A = direccion otra vez
	ld d,(hl)			;6938   ; dy
	inc hl			;6939
	ld e,(hl)			;693a   ; dx
	ld c,a			;693b
	ret			;693c

; ----------------------------------------------------------------------
; DATOS ocho_direcciones: Ocho pares (dx, dy) con signo, las ocho direcciones
;   en el orden (-1,0) (-1,1) (0,1) (1,1) (1,0) (1,-1) (0,-1) (-1,-1): los
;   recorre 0x6930
;   0x693d..0x694d  (16 bytes)
DATA_ocho_direcciones:
	defb 0ffh,000h	; 693d
	defb 0ffh,001h	; 693f
	defb 000h,001h	; 6941
	defb 001h,001h	; 6943
	defb 001h,000h	; 6945
	defb 001h,0ffh	; 6947
	defb 000h,0ffh	; 6949
	defb 0ffh,0ffh	; 694b

; ======================================================================
; CODIGO 0x694d..0x6a9c  (335 bytes)
; ======================================================================


tras_canasta:		; Saque de fondo tras una canasta: recoge el defensor, sale de la linea, cinco segundos para pasar
	ld a,001h		;694d   ; todo bloqueado
	ld (0ed69h),a		;694f
	ld (0ed6ah),a		;6952
	ld (0ed6bh),a		;6955
	ld (0e6e2h),a		;6958
	ld (0ed6dh),a		;695b
	ld (0ed6ch),a		;695e
	call espera_aterrizaje		;6961   ; espera a que caiga el que ha tirado
	call posiciones_tras_canasta		;6964   ; posiciones y quien saca
	ld a,(0ed66h)		;6967
	call registro_jugador		;696a
	ld (0ed67h),hl		;696d
L_6970:
	call cuadro_partido		;6970   ; hasta que recoja el balon
	ld a,(0e6cfh)		;6973
	ld b,a			;6976
	ld a,(0ed66h)		;6977
	cp b			;697a
	jr nz,L_6970		;697b
	ld a,0ffh		;697d   ; tiro resuelto
	ld (0e6f9h),a		;697f
	ld hl,(0ed67h)		;6982
	push hl			;6985
	push hl			;6986
	pop ix		;6987
	call tras_la_linea		;6989   ; destino detras de la linea de fondo
L_698C:
	call cuadro_partido		;698c
	ld hl,(0ed67h)		;698f   ; hasta que llegue
	ld de,00020h		;6992
	add hl,de			;6995
	ld a,(hl)			;6996
	inc hl			;6997
	or (hl)			;6998
	jr nz,L_698C		;6999
	call mira_pista		;699b   ; mirando a la pista
	xor a			;699e
	ld (0ed63h),a		;699f
	ld (0ed6dh),a		;69a2
	call borra_entradas		;69a5   ; entradas a cero
L_69A8:
	call cuadro_partido		;69a8
	ld a,(0e6e3h)		;69ab   ; hasta que llegue el receptor
	call registro_jugador		;69ae
	ld de,00020h		;69b1
	add hl,de			;69b4
	ld a,(hl)			;69b5
	inc hl			;69b6
	or (hl)			;69b7
	jr nz,L_69A8		;69b8
	xor a			;69ba
	ld (0ed6ch),a		;69bb
	ld (0e6e2h),a		;69be
	inc a			;69c1
	ld (0e6f2h),a		;69c2   ; bote forzado
	ld a,(0e6cfh)		;69c5   ; SUPOSICION: el que saca
	ld (0f007h),a		;69c8
	call espera_300		;69cb   ; cinco segundos para sacar
	pop ix		;69ce
	call retardo_maquina		;69d0
L_69D3:
	call cuadro_partido		;69d3
	ld a,(0e6cfh)		;69d6
	bit 6,a		;69d9   ; bit 6: ya ha pasado
	jr nz,saque_hecho		;69db
	ld hl,(0ed90h)		;69dd   ; sin tiempo: violacion
	ld a,h			;69e0
	or l			;69e1
	jr nz,L_69D3		;69e2
	jr violacion_saque		;69e4
saque_hecho:		; Pase de saque hecho: cuentas de 10 y 30 segundos y vuelta al juego
	xor a			;69e6
	ld (0e6f2h),a		;69e7   ; sin bote forzado
	ld (0ed6bh),a		;69ea   ; movimiento libre
	dec a			;69ed
	ld (0f007h),a		;69ee   ; SUPOSICION: sin sacador
	call cuenta_30s		;69f1   ; cuenta de 30 segundos
	call cuenta_10s		;69f4   ; y de 10
	ld hl,(0ed67h)		;69f7   ; SUPOSICION: destino Y = su Y actual
	inc hl			;69fa
	ld a,(hl)			;69fb
	ld de,0001fh		;69fc
	add hl,de			;69ff
	ld (hl),a			;6a00   ; destino Y del sacador
	xor a			;6a01
	ld (0ed6ah),a		;6a02   ; defensa y ataque libres
	ld (0ed69h),a		;6a05
	dec a			;6a08
	ld (0ed66h),a		;6a09   ; sin recogedor
	ret			;6a0c
violacion_saque:		; Cinco segundos sin sacar: 5 SECOND
	ld a,002h		;6a0d   ; rotulo 2: 5 SECOND
	ld (0ed70h),a		;6a0f
	ld a,(0e6cfh)		;6a12
	ld (0ed6fh),a		;6a15
	xor a			;6a18
	ld (0ed6ah),a		;6a19
	dec a			;6a1c
	ld (0ed66h),a		;6a1d
	ld (0f007h),a		;6a20
	ret			;6a23
espera_aterrizaje:		; Espera a que el ultimo que ha tirado (0xE6FC) toque el suelo
	ld a,(0e6fch)		;6a24
	call registro_jugador		;6a27
	ld de,0000ch		;6a2a
	add hl,de			;6a2d
L_6A2E:
	ld a,(hl)			;6a2e   ; gravedad del que tiro
	and a			;6a2f
	ret z			;6a30   ; ya en el suelo
	push hl			;6a31
	call cuadro_partido		;6a32   ; un cuadro mas
	pop hl			;6a35
	jr L_6A2E		;6a36
mira_pista:		; Pose del que saca mirando hacia la pista (direccion 6 o 2)
	ld ix,(0ed67h)		;6a38
	ld a,(ix+003h)		;6a3c   ; X del sacador
	and a			;6a3f
	ld a,006h		;6a40   ; direccion 6
	jp p,L_6A49		;6a42
	add a,004h		;6a45   ; o la opuesta (2)
	and 007h		;6a47
L_6A49:
	add a,a			;6a49   ; por 4
	add a,a			;6a4a
	ld b,a			;6a4b
	ld a,(ix+00dh)		;6a4c   ; pose actual
	and 0e3h		;6a4f   ; sin direccion
	or b			;6a51
	ld (ix+00dh),a		;6a52   ; con la nueva
	ret			;6a55
tras_la_linea:		; Destino del que saca detras de la linea de fondo (Y 0x60, X +-0x68)
	ld a,(ix+003h)		;6a56
	and a			;6a59
	ld a,068h		;6a5a
	jp p,L_6A61		;6a5c
	neg		;6a5f
L_6A61:
	ld (ix+020h),060h		;6a61
	ld (ix+021h),a		;6a65
	ret			;6a68
posiciones_tras_canasta:		; Destinos de los seis desde las tablas 0x6A9C o 0x6AAB; la marcada con 1 es el receptor
	call recoge_tras_canasta		;6a69   ; quien saca
	cp 003h		;6a6c
	ld hl,06a9ch		;6a6e   ; un lado
	jr c,L_6A76		;6a71
	ld hl,06aabh		;6a73   ; el otro
L_6A76:
	ld iy,0e500h		;6a76
	ld c,000h		;6a7a
	ld b,006h		;6a7c
L_6A7E:
	cp c			;6a7e
	jr z,L_6A93		;6a7f
	ex af,af'			;6a81
	ld a,(hl)			;6a82
	inc hl			;6a83
	and a			;6a84
	jr z,L_6A8B		;6a85
	ld a,c			;6a87   ; receptor del saque
	ld (0e6e3h),a		;6a88
L_6A8B:
	ex af,af'			;6a8b
	ld d,(hl)			;6a8c
	inc hl			;6a8d
	ld e,(hl)			;6a8e
	inc hl			;6a8f
	call destino_iy		;6a90   ; destino del jugador
L_6A93:
	ld de,00030h		;6a93
	add iy,de		;6a96
	inc c			;6a98
	djnz L_6A7E		;6a99
	ret			;6a9b

; ----------------------------------------------------------------------
; DATOS posiciones_e: Cinco tripletes (lado, X, Y) que recorre 0x6A6E
;   0x6a9c..0x6aab  (15 bytes)
DATA_posiciones_e:
	defb 000h,060h,048h	; 6a9c
	defb 001h,060h,0b8h	; 6a9f
	defb 000h,014h,03eh	; 6aa2
	defb 000h,03ah,01ah	; 6aa5
	defb 000h,060h,03eh	; 6aa8

; ----------------------------------------------------------------------
; DATOS posiciones_f: Cinco tripletes (lado, X, Y) que recorre 0x6A73
;   0x6aab..0x6aba  (15 bytes)
DATA_posiciones_f:
	defb 000h,014h,0aeh	; 6aab
	defb 000h,03ah,0d2h	; 6aae
	defb 000h,060h,0aeh	; 6ab1
	defb 000h,060h,0b8h	; 6ab4
	defb 001h,060h,048h	; 6ab7

; ======================================================================
; CODIGO 0x6aba..0x6d2b  (625 bytes)
; ======================================================================


recoge_tras_canasta:		; El defensor mas cercano al balon va a por el (0xED66 y 0xED61)
	ld a,(0e623h)		;6aba   ; lado del balon
	and a			;6abd
	ld c,000h		;6abe
	ld hl,0e500h		;6ac0
	jp m,L_6ACB		;6ac3
	ld c,003h		;6ac6   ; equipo derecho
	ld hl,0e590h		;6ac8
L_6ACB:
	exx			;6acb
	ld hl,000ffh		;6acc
	exx			;6acf
	ld b,003h		;6ad0
L_6AD2:
	push bc			;6ad2
	push hl			;6ad3
	ld de,0e620h		;6ad4   ; distancia al balon
	call xy_dos_registros		;6ad7
	call diferencia_xy		;6ada
	call distancia		;6add
	pop hl			;6ae0
	pop bc			;6ae1
	ld d,c			;6ae2
	ld e,a			;6ae3
	push de			;6ae4
	exx			;6ae5
	pop de			;6ae6
	call menor		;6ae7   ; se queda el mas cercano
	exx			;6aea
	ld de,00030h		;6aeb
	add hl,de			;6aee
	inc c			;6aef
	djnz L_6AD2		;6af0
	exx			;6af2
	ld a,h			;6af3
	exx			;6af4
	ld (0ed66h),a		;6af5   ; el que saca
	ld (0ed61h),a		;6af8
	ld c,a			;6afb
	ld a,0ffh		;6afc
	ld (0ed62h),a		;6afe
	ld hl,0e6c3h		;6b01   ; destino: el balon
	call xy_registro		;6b04
	push de			;6b07
	ld a,c			;6b08
	ld de,00020h		;6b09
	call registro_jugador		;6b0c
	add hl,de			;6b0f
	pop de			;6b10
	ld (hl),d			;6b11
	inc hl			;6b12
	ld (hl),e			;6b13
	ret			;6b14
menor:		; DE = el menor por E de DE y HL
	ld a,e			;6b15
	cp l			;6b16
	ret nc			;6b17
	ex de,hl			;6b18
	ret			;6b19
defensa_maquina:		; Defensor no controlado: se coloca entre su par (+0x25) y la canasta, o le sigue si su par corre a un destino
	ld a,(0ed6ah)		;6b1a   ; movimiento de la defensa bloqueado
	and a			;6b1d
	ret nz			;6b1e
	ld a,(ix+020h)		;6b1f   ; ya tiene destino
	or (ix+021h)		;6b22
	ret nz			;6b25
	ld a,(ix+025h)		;6b26   ; su par
	call registro_jugador		;6b29
	push hl			;6b2c
	pop iy		;6b2d
	ld a,(iy+020h)		;6b2f   ; su par va a un destino: le sigue
	or (iy+021h)		;6b32
	jp nz,sigue_par		;6b35
	push hl			;6b38
	ex de,hl			;6b39
	ld hl,0e6c7h		;6b3a   ; SUPOSICION: canasta que defiende (0xE6C7)
	call xy_dos_registros		;6b3d
	ld a,(0ed69h)		;6b40   ; con el juego parado: a un lado de la pista
	and a			;6b43
	jr z,L_6B53		;6b44
	ld l,000h		;6b46
	ld a,039h		;6b48
	cp (ix+001h)		;6b4a
	ld h,008h		;6b4d
	jr c,L_6B53		;6b4f
	ld h,06ch		;6b51
L_6B53:
	call diferencia_xy		;6b53
	call mitad_de		;6b56
	call angulo		;6b59   ; angulo del par a la canasta
	ld b,a			;6b5c
	call controlado		;6b5d   ; controlado del equipo con el balon
	call registro_jugador		;6b60
	pop de			;6b63
	push bc			;6b64
	call xy_dos_registros		;6b65
	call diferencia_xy		;6b68
	call mitad_de		;6b6b
	call angulo		;6b6e   ; angulo del par al controlado
	pop bc			;6b71
	ld c,a			;6b72
	add a,b			;6b73   ; bisectriz de los dos angulos
	rra			;6b74
	ld d,a			;6b75
	ld a,b			;6b76
	cp c			;6b77
	jr nc,L_6B7D		;6b78
	ld b,c			;6b7a
	ld c,a			;6b7b
	ld a,b			;6b7c
L_6B7D:
	sub c			;6b7d
	cp 080h		;6b7e
	ld a,d			;6b80
	jr c,L_6B85		;6b81
	xor 080h		;6b83
L_6B85:
	push af			;6b85
	ld hl,00010h		;6b86   ; 16 unidades en esa direccion
	call por_coseno		;6b89
	pop af			;6b8c
	push hl			;6b8d
	ld hl,00010h		;6b8e
	call por_seno		;6b91
	ld e,(iy+002h)		;6b94
	ld d,(iy+003h)		;6b97
	add hl,de			;6b9a
	ld a,h			;6b9b
	ld (0e843h),a		;6b9c   ; X del punto de marcaje
	ld e,(iy+000h)		;6b9f
	ld d,(iy+001h)		;6ba2
	pop hl			;6ba5
	add hl,de			;6ba6
	ld a,h			;6ba7
	ld (0e842h),a		;6ba8   ; Y del punto de marcaje
	push ix		;6bab
	pop hl			;6bad
	call xy_registro		;6bae
	ld hl,(0e842h)		;6bb1
	ld a,h			;6bb4
	call limita_60		;6bb5   ; X limitada a +-0x60
	ld h,l			;6bb8
	ld l,a			;6bb9
	push hl			;6bba
	call diferencia_xy		;6bbb
	call distancia		;6bbe
	pop hl			;6bc1
	cp 00ch		;6bc2   ; a menos de 12 no se mueve
	ret c			;6bc4
	ld (ix+020h),h		;6bc5   ; destino nuevo
	ld (ix+021h),l		;6bc8
	ret			;6bcb
sigue_par:		; Destino 12 unidades por delante del destino de su par, con un retardo de reaccion
	call controlados		;6bcc   ; controlado del equipo con el balon
	call registro_jugador		;6bcf
	call xy_registro		;6bd2   ; su posicion
	ld h,(iy+020h)		;6bd5   ; destino del par
	ld l,(iy+021h)		;6bd8
	push hl			;6bdb
	ex de,hl			;6bdc
	call diferencia_xy		;6bdd
	call mitad_de		;6be0
	call angulo		;6be3   ; angulo del controlado al destino
	push af			;6be6
	ld hl,0000ch		;6be7   ; 12 unidades
	call por_coseno		;6bea
	pop af			;6bed
	pop de			;6bee
	ex af,af'			;6bef
	ld a,h			;6bf0
	add a,d			;6bf1   ; Y del destino mas dy
	ld d,a			;6bf2
	ex af,af'			;6bf3
	push de			;6bf4
	ld hl,0000ch		;6bf5
	call por_seno		;6bf8
	pop de			;6bfb
	ld a,h			;6bfc
	add a,e			;6bfd   ; X del destino mas dx
	call limita_60		;6bfe
	ld e,a			;6c01
	push de			;6c02
	ld h,(ix+001h)		;6c03   ; posicion del defensor
	ld l,(ix+003h)		;6c06
	call diferencia_xy		;6c09
	call distancia		;6c0c   ; distancia al punto nuevo
	cp 004h		;6c0f   ; a menos de 4 no se mueve
	pop de			;6c11
	ret c			;6c12
	call destino_ix		;6c13   ; destino nuevo
	jp retardo_reaccion		;6c16   ; y retardo de reaccion
limita_60:		; A con signo limitado a +-0x60
	ld c,a			;6c19
	bit 7,c		;6c1a   ; signo
	push af			;6c1c
	jr z,L_6C22		;6c1d
	neg		;6c1f   ; valor absoluto
	ld c,a			;6c21
L_6C22:
	ld a,060h		;6c22
	cp c			;6c24
	jr nc,L_6C29		;6c25
	ld c,060h		;6c27
L_6C29:
	pop af			;6c29
	ld a,c			;6c2a
	ret z			;6c2b
	neg		;6c2c
	ret			;6c2e
retardo_reaccion:		; Retardo al azar (+0x26) segun el nivel del equipo (roster +3, 1-8)
	ld a,(0ed60h)		;6c2f   ; SUPOSICION: reboteador del otro equipo
	and a			;6c32
	ret p			;6c33
	ld a,(0e83ch)		;6c34
	and 001h		;6c37
	ld hl,0e854h		;6c39
	jr z,L_6C41		;6c3c
	ld hl,0e940h		;6c3e
L_6C41:
	ld b,(hl)			;6c41
	ld a,008h		;6c42   ; 9 menos el nivel
	sub b			;6c44
	inc a			;6c45
	ld e,006h		;6c46   ; por 6
	call multiplica		;6c48
	ld b,l			;6c4b
	call aleatorio		;6c4c   ; azar de 0 a 63 por debajo del limite
	and 03fh		;6c4f
	cp b			;6c51
	jr nc,L_6C41		;6c52
	add a,00ch		;6c54   ; minimo 12 cuadros mas el de su par
	add a,(iy+026h)		;6c56
	ld (ix+026h),a		;6c59
	ret			;6c5c
por_coseno:		; HL por la tabla 0xC200 en A-0x40, con signo
	push hl			;6c5d
	call tabla_c2_desfase		;6c5e
	jr L_6C67		;6c61
por_seno:		; HL por la tabla 0xC200 en A, con signo
	push hl			;6c63
	call tabla_c2		;6c64
L_6C67:
	ld a,d			;6c67   ; signo del factor
	and a			;6c68
	pop hl			;6c69
	push af			;6c6a
	ld d,000h		;6c6b
	call multiplica16		;6c6d   ; por HL
	pop af			;6c70
	ret p			;6c71
	jp niega_hl		;6c72   ; negativo
ataque_maquina:		; Atacante no controlado: sigue la jugada en curso (0xE850) paso a paso
	ld a,(0ed69h)		;6c75   ; movimiento bloqueado
	and a			;6c78
	ret nz			;6c79
	ld a,(ix+020h)		;6c7a   ; ya tiene destino
	or (ix+021h)		;6c7d
	ret nz			;6c80
	ld a,(0e850h)		;6c81   ; 0x3F: sin jugada
	cp 03fh		;6c84
	ret z			;6c86
	ld a,(0e721h)		;6c87
	call paso_formacion		;6c8a   ; paso de la jugada para este jugador
	ld a,(hl)			;6c8d
	inc hl			;6c8e
	ld (ix+026h),a		;6c8f   ; espera antes de moverse
	ld d,(hl)			;6c92
	inc hl			;6c93
	bit 7,d		;6c94   ; bit 7: fin de la jugada
	jr nz,L_6CAD		;6c96
	ld e,(hl)			;6c98
	bit 4,(ix+00fh)		;6c99   ; bit 4: lado, la X cambia de signo
	jr nz,L_6CA3		;6c9d
	ld a,e			;6c9f
	neg		;6ca0
	ld e,a			;6ca2
L_6CA3:
	inc hl			;6ca3
	call destino_ix		;6ca4   ; destino
	ld a,(0e721h)		;6ca7
	jp avanza_paso		;6caa   ; siguiente paso
L_6CAD:
	ld a,03fh		;6cad   ; fin: sin jugada para el
	ld (ix+022h),a		;6caf
	ret			;6cb2
formacion:		; SUPOSICION: al pedirlo (0xED99) coloca a los tres atacantes en la formacion de la zona del controlado (tabla 0x6D2B)
	ld a,(0ed99h)		;6cb3
	and a			;6cb6
	ret z			;6cb7
	xor a			;6cb8
	ld (0ed99h),a		;6cb9
	ld a,(0e850h)		;6cbc   ; con una jugada en curso no
	cp 03fh		;6cbf
	ret nz			;6cc1
	ld a,(0e6cfh)		;6cc2   ; ni con un pase en vuelo
	bit 6,a		;6cc5
	ret nz			;6cc7
	ld a,(0ed69h)		;6cc8
	and a			;6ccb
	ret nz			;6ccc
	ld a,(0ed5fh)		;6ccd
	and a			;6cd0
	ret p			;6cd1
	call controlado		;6cd2   ; controlado
	ld b,a			;6cd5
	call registro_jugador		;6cd6
	push hl			;6cd9
	pop ix		;6cda
	ld a,(ix+001h)		;6cdc   ; Y del controlado
	ld hl,06d2bh		;6cdf
	ld de,0000fh		;6ce2
	cp 029h		;6ce5   ; zona 0: menos de 0x29
	jr c,L_6CEF		;6ce7
	add hl,de			;6ce9
	cp 04bh		;6cea   ; zona 1: menos de 0x4B
	jr c,L_6CEF		;6cec
	add hl,de			;6cee
L_6CEF:
	ld c,000h		;6cef
	ld a,b			;6cf1
	cp 003h		;6cf2   ; equipo derecho: jugadores 3-5
	jr c,L_6CFA		;6cf4
	ld c,003h		;6cf6
	sub 003h		;6cf8
L_6CFA:
	push hl			;6cfa
	ld l,a			;6cfb
	ld h,000h		;6cfc
	ld e,l			;6cfe
	ld d,h			;6cff
	add hl,hl			;6d00   ; 5 bytes por jugador
	add hl,hl			;6d01
	add hl,de			;6d02
	pop de			;6d03
	add hl,de			;6d04
	push hl			;6d05
	ld a,c			;6d06
	call registro_jugador		;6d07
	push hl			;6d0a
	pop ix		;6d0b
	pop hl			;6d0d
	ld de,00030h		;6d0e
	ld b,003h		;6d11   ; tres jugadores
L_6D13:
	ld a,(hl)			;6d13   ; Y de la tabla
	inc hl			;6d14
	and a			;6d15
	jr z,L_6D26		;6d16   ; 0: este no se mueve
	ld (ix+020h),a		;6d18   ; destino Y
	ld a,(hl)			;6d1b   ; X de la tabla
	inc hl			;6d1c
	inc c			;6d1d
	dec c			;6d1e
	jr z,L_6D23		;6d1f
	neg		;6d21   ; negada en el equipo derecho
L_6D23:
	ld (ix+021h),a		;6d23   ; destino X (negada en el derecho)
L_6D26:
	add ix,de		;6d26
	djnz L_6D13		;6d28
	ret			;6d2a

; ----------------------------------------------------------------------
; DATOS posiciones_g: 45 bytes que recorre 0x6CDF
;   0x6d2b..0x6d58  (45 bytes)
DATA_posiciones_g:
	defb 000h,03ah,024h,060h,048h,03ah,024h,000h,060h,048h,03ah,024h,060h,048h,000h	; 6d2b  .:$`H:$.`H:$`H.
	defb 000h,014h,048h,060h,048h,014h,048h,000h,060h,048h,014h,048h,060h,048h,000h	; 6d3a  ..H`H.H.`H.H`H.
	defb 000h,014h,048h,03ah,024h,014h,048h,000h,03ah,024h,014h,048h,03ah,024h,000h	; 6d49  ..H:$.H.:$.H:$.

; ======================================================================
; CODIGO 0x6d58..0x6e02  (170 bytes)
; ======================================================================


al_rebote:		; Tras un tiro el mas cercano a la canasta de cada equipo va a por el rebote
	ld a,(0ed69h)		;6d58   ; ataque bloqueado
	and a			;6d5b
	ret nz			;6d5c
	push af			;6d5d
	ld a,(0ed5fh)		;6d5e   ; reboteadores ya elegidos?
	and a			;6d61
	call m,reboteadores		;6d62   ; elige los dos
	pop af			;6d65
	ret			;6d66
reboteadores:		; Atacante y defensor mas cercanos a la canasta (0xED5F/0xED62 y 0xED60/0xED61) con destino al aro
	call cercano_ataque		;6d67
	ld (0ed5fh),a		;6d6a   ; reboteador atacante
	ld (0ed62h),a		;6d6d
	call destino_canasta		;6d70
	call cercano_defensa		;6d73
	ld (0ed60h),a		;6d76   ; reboteador defensor
	ld (0ed61h),a		;6d79
destino_canasta:		; Destino del jugador A: la canasta 0xE6C3
	ld de,0e6c3h		;6d7c
destino_punto:		; Destino del jugador A: la posicion del registro DE
	call registro_jugador		;6d7f   ; registro del jugador
	push hl			;6d82
	pop iy		;6d83
	ex de,hl			;6d85
	call xy_registro		;6d86   ; posicion del punto DE
	jp destino_iy		;6d89   ; como destino
cercano_defensa:		; Jugador del equipo sin balon mas cercano a la canasta
	ld hl,000ffh		;6d8c   ; distancia minima de partida
	ld c,000h		;6d8f
	ld b,003h		;6d91
	ld a,(0e83ch)		;6d93   ; equipo con el balon
	and a			;6d96
	jr nz,L_6DAC		;6d97
	ld c,003h		;6d99   ; defiende el derecho: 3-5
	jr L_6DAC		;6d9b
cercano_ataque:		; Jugador del equipo con el balon mas cercano a la canasta
	ld hl,000ffh		;6d9d   ; distancia minima de partida
	ld c,000h		;6da0
	ld b,003h		;6da2
	ld a,(0e83ch)		;6da4   ; equipo con el balon
	and a			;6da7
	jr z,L_6DAC		;6da8
	ld c,003h		;6daa   ; ataca el derecho: 3-5
L_6DAC:
	ld a,c			;6dac   ; jugador C
	push bc			;6dad
	push hl			;6dae
	call registro_jugador		;6daf
	ld de,0e6c3h		;6db2   ; canasta
	call xy_dos_registros		;6db5
	call diferencia_xy		;6db8
	call absolutos_7f		;6dbb   ; abs de las diferencias
	call distancia		;6dbe   ; distancia a la canasta
	pop hl			;6dc1
	pop bc			;6dc2
	ld d,c			;6dc3
	ld e,a			;6dc4
	cp l			;6dc5   ; mas cerca que el mejor?
	jr nc,L_6DC9		;6dc6
	ex de,hl			;6dc8   ; nuevo mejor
L_6DC9:
	inc c			;6dc9
	djnz L_6DAC		;6dca
	ld a,h			;6dcc
	ret			;6dcd
absolutos_7f:		; Abs de H y L limitado a 0x7F
	ex de,hl			;6dce
	call absoluto_7f		;6dcf
	ex de,hl			;6dd2
absoluto_7f:		; A = abs(HL) limitado a 0x7F
	ld a,h			;6dd3
	and a			;6dd4
	ld a,l			;6dd5
	jp p,L_6DDB		;6dd6
	neg		;6dd9
L_6DDB:
	cp 080h		;6ddb
	jr c,L_6DE1		;6ddd
	ld a,07fh		;6ddf
L_6DE1:
	ld l,a			;6de1
	ld h,000h		;6de2
	ret			;6de4
posicion_defensa:		; DE = posicion de defensa del jugador A (tabla 0x6E02 o 0x6E08 segun el lado)
	push hl			;6de5
	ld hl,06e08h		;6de6
	bit 4,(ix+00fh)		;6de9
	jr z,L_6DF2		;6ded
	ld hl,06e02h		;6def
L_6DF2:
	cp 003h		;6df2
	jr c,L_6DF8		;6df4
	sub 003h		;6df6
L_6DF8:
	add a,a			;6df8   ; dos bytes por jugador
	ld e,a			;6df9
	ld d,000h		;6dfa
	add hl,de			;6dfc
	ld d,(hl)			;6dfd   ; Y de defensa
	inc hl			;6dfe
	ld e,(hl)			;6dff   ; X de defensa
	pop hl			;6e00
	ret			;6e01

; ----------------------------------------------------------------------
; DATOS posiciones_h: Tres pares (X, Y) que recorre 0x6DEF
;   0x6e02..0x6e08  (6 bytes)
DATA_posiciones_h:
	defb 014h,048h	; 6e02
	defb 03ah,024h	; 6e04
	defb 060h,048h	; 6e06

; ----------------------------------------------------------------------
; DATOS posiciones_i: Tres pares (X, Y) que recorre 0x6DE6: las mismas X que
;   0x6E02 con la Y del otro lado (0x100 - Y)
;   0x6e08..0x6e0e  (6 bytes)
DATA_posiciones_i:
	defb 014h,0b8h	; 6e08
	defb 03ah,0dch	; 6e0a
	defb 060h,0b8h	; 6e0c

; ======================================================================
; CODIGO 0x6e0e..0x74e5  (1751 bytes)
; ======================================================================


zonas_a_4:		; Cuatro en 0xE844-0xE846 salvo las negativas
	ld hl,0e844h		;6e0e
	ld b,003h		;6e11
L_6E13:
	ld a,(hl)			;6e13
	and a			;6e14
	jp m,L_6E1A		;6e15
	ld (hl),004h		;6e18
L_6E1A:
	inc hl			;6e1a
	djnz L_6E13		;6e1b
	ret			;6e1d
zona_jugador:		; SUPOSICION: apunta la zona de la pista de cada atacante en 0xE844/0xE847
	bit 3,c		;6e1e   ; solo los atacantes
	ret z			;6e20
	call carril		;6e21   ; carril del jugador
	ld c,a			;6e24
	ld a,h			;6e25
	call pon_e847		;6e26   ; se apunta
	ld a,h			;6e29
	cp 003h		;6e2a   ; jugador de 0 a 2
	jr c,L_6E30		;6e2c
	sub 003h		;6e2e
L_6E30:
	ld h,a			;6e30
	ld a,c			;6e31
	ld c,h			;6e32
	jr pon_e844		;6e33
pon_e847:		; (0xE847 + jugador mod 3) = C
	push hl			;6e35
	ld hl,0e847h		;6e36   ; tabla de carriles
	call indice_mod3		;6e39
	ld (hl),c			;6e3c   ; guarda C
	pop hl			;6e3d
	ret			;6e3e
lee_e847:		; A = (0xE847 + jugador mod 3)
	push hl			;6e3f
	ld hl,0e847h		;6e40   ; tabla de carriles
	call indice_mod3		;6e43
	ld a,(hl)			;6e46   ; lee
	pop hl			;6e47
	ret			;6e48
lee_e844:		; A = (0xE844 + jugador mod 3)
	push hl			;6e49
	ld hl,0e844h		;6e4a   ; tabla de zonas
	call indice_mod3		;6e4d
	ld a,(hl)			;6e50   ; lee
	pop hl			;6e51
	ret			;6e52
pon_e844:		; (0xE844 + C mod 3) = A mod 3
	push hl			;6e53
	ld hl,0e844h		;6e54   ; tabla de zonas
	call indice_mod3		;6e57
	ld a,c			;6e5a
	cp 003h		;6e5b   ; jugador de 0 a 2
	jr c,L_6E61		;6e5d
	sub 003h		;6e5f
L_6E61:
	ld (hl),a			;6e61
	pop hl			;6e62
	ret			;6e63
indice_mod3:		; HL + (A mod 3)
	push de			;6e64
	cp 003h		;6e65
	jr c,L_6E6B		;6e67
	sub 003h		;6e69
L_6E6B:
	ld e,a			;6e6b
	ld d,000h		;6e6c
	add hl,de			;6e6e
	pop de			;6e6f
	ret			;6e70
carril:		; A = carril segun la Y: 0 de 0x08 a 0x29, 1 hasta 0x4A, 2 hasta 0x6C
	push bc			;6e71
	push de			;6e72
	call carril_c		;6e73   ; C = carril
	ld a,c			;6e76   ; a A
	pop de			;6e77
	pop bc			;6e78
	ret			;6e79
carril_c:		; C = carril de la Y (+1) del jugador IX; NZ si esta en alguno
	ld b,(ix+001h)		;6e7a
	ld c,000h		;6e7d
	ld a,b			;6e7f
	ld de,00829h		;6e80   ; carril 0: 0x08-0x28
	call entre		;6e83
	ret nz			;6e86
	inc c			;6e87
	ld a,b			;6e88
	ld de,0294ah		;6e89   ; carril 1: 0x29-0x49
	call entre		;6e8c
	ret nz			;6e8f
	inc c			;6e90
	ld a,b			;6e91
	ld de,04a6ch		;6e92   ; carril 2: 0x4A-0x6B
entre:		; NZ si A esta entre D y E-1
	cp d			;6e95   ; por debajo de D?
	jr c,L_6E9D		;6e96
	cp e			;6e98   ; de E en adelante?
	jr nc,L_6E9D		;6e99
	and a			;6e9b   ; dentro: NZ
	ret			;6e9c
L_6E9D:
	xor a			;6e9d
	ret			;6e9e
nada:		; ret vacio
	ret			;6e9f
maximo_huerfano:		; Huerfano: buscaria el mayor de B pares de la tabla HL
	ld c,(hl)			;6ea0
	inc hl			;6ea1
	ld a,(hl)			;6ea2
	inc hl			;6ea3
L_6EA4:
	ld d,(hl)			;6ea4   ; indice
	inc hl			;6ea5
	cp (hl)			;6ea6   ; mayor que el maximo?
	jr c,L_6EAB		;6ea7
	ld c,d			;6ea9   ; nuevo maximo
	ld a,(hl)			;6eaa
L_6EAB:
	inc hl			;6eab
	djnz L_6EA4		;6eac
	ret			;6eae
distancias_al_balon:		; SUPOSICION: lista en HL' el numero y la distancia al balon de los jugadores que no son los controlados
	call controlados		;6eaf   ; controlados de los dos equipos
	cp c			;6eb2
	jr z,L_6ED5		;6eb3
	ex af,af'			;6eb5
	cp c			;6eb6
	jr z,L_6ED4		;6eb7
	ex af,af'			;6eb9
	ld a,c			;6eba
	exx			;6ebb
	ld (hl),a			;6ebc   ; numero del jugador
	inc hl			;6ebd
	exx			;6ebe
	push hl			;6ebf
	push bc			;6ec0
	ld de,0e620h		;6ec1   ; balon
	call xy_dos_registros		;6ec4
	call diferencia_xy		;6ec7
	call distancia		;6eca
	exx			;6ecd
	ld (hl),a			;6ece   ; su distancia
	inc hl			;6ecf
	exx			;6ed0
	pop bc			;6ed1
	pop hl			;6ed2
	ex af,af'			;6ed3
L_6ED4:
	ex af,af'			;6ed4
L_6ED5:
	inc c			;6ed5
	ld de,00030h		;6ed6
	add hl,de			;6ed9
	djnz distancias_al_balon		;6eda
	ret			;6edc
destino_ix:		; Destino (D, E) del jugador IX
	ld (ix+020h),d		;6edd
	ld (ix+021h),e		;6ee0
	ret			;6ee3
destino_iy:		; Destino (D, E) del jugador IY
	ld (iy+020h),d		;6ee4
	ld (iy+021h),e		;6ee7
	ret			;6eea
inicia_formacion:		; Arranca la formacion A (0-5) del equipo con el balon: pasos de cada atacante desde la tabla del equipo en 0xEA89
	ld hl,0e844h		;6eeb
	ld b,003h		;6eee
	and 007h		;6ef0
	cp 006h		;6ef2   ; solo las formaciones 0 a 5
	ret nc			;6ef4
	ld c,a			;6ef5
	ld a,004h		;6ef6   ; 4 = alguno sin zona
L_6EF8:
	cp (hl)			;6ef8
	ret z			;6ef9
	bit 7,(hl)		;6efa
	ret nz			;6efc
	inc hl			;6efd
	djnz L_6EF8		;6efe
	ld a,c			;6f00
	call pon_formacion		;6f01   ; formacion en +0x22 de los tres
	ld a,c			;6f04
	push bc			;6f05
	call bloque_formacion		;6f06   ; bloque de la tabla del equipo
	call punteros_formacion		;6f09   ; punteros de pasos de cada jugador
	pop bc			;6f0c
	ld a,c			;6f0d
	and 007h		;6f0e
	ld (0e850h),a		;6f10   ; formacion en curso
	inc a			;6f13
	ld (0ed59h),a		;6f14   ; letra que muestra FORMATION=
	ret			;6f17
pon_formacion:		; +0x22 de los tres atacantes = A
	ld b,a			;6f18
	ld hl,0e522h		;6f19   ; equipo izquierdo
	ld a,(0e83ch)		;6f1c
	and a			;6f1f
	jr z,L_6F25		;6f20
	ld hl,0e5b2h		;6f22   ; equipo derecho
L_6F25:
	ld a,b			;6f25
	ld b,003h		;6f26
	ld de,00030h		;6f28
L_6F2B:
	ld (hl),a			;6f2b
	add hl,de			;6f2c
	djnz L_6F2B		;6f2d
	ret			;6f2f
pon_formacion_huerfano:		; Huerfano: pondria C con el bit 7 en +0x22 (el puntero del equipo derecho esta mal: 0x0022)
	set 7,c		;6f30   ; bit 7 en la formacion
	ld a,(0e83ch)		;6f32
	ld hl,0e522h		;6f35   ; equipo izquierdo
	and a			;6f38
	jr z,L_6F3E		;6f39
	ld hl,00022h		;6f3b   ; equipo derecho: puntero 0x0022 (deberia ser 0xE5B2)
L_6F3E:
	ld b,003h		;6f3e
	ld de,00030h		;6f40
L_6F43:
	ld (hl),c			;6f43
	add hl,de			;6f44
	djnz L_6F43		;6f45
	ret			;6f47
bloque_formacion:		; HL = guion de 24 bytes: 144 x formacion + 24 x (2 x carril del controlado + bit al azar)
	call tabla_equipo		;6f48
	call controlados		;6f4b
	call lee_e847		;6f4e   ; zona del controlado
	add a,a			;6f51
	ld b,a			;6f52
	ld a,r		;6f53   ; al azar una de dos variantes
	and 001h		;6f55
	add a,b			;6f57
	nop			;6f58
	add a,a			;6f59   ; 24 bytes por variante
	add a,a			;6f5a
	add a,a			;6f5b
	ld b,a			;6f5c
	add a,a			;6f5d
	add a,b			;6f5e
	ld d,000h		;6f5f
	ld e,a			;6f61
	add hl,de			;6f62
	ret			;6f63
tabla_equipo:		; HL = 0xEA89 + A * 0x90 (144 bytes por formacion: 6 variantes x 3 jugadores x 8)
	ld l,a			;6f64
	ld h,000h		;6f65
	add hl,hl			;6f67   ; A por 16
	add hl,hl			;6f68
	add hl,hl			;6f69
	add hl,hl			;6f6a
	ld d,h			;6f6b
	ld e,l			;6f6c
	add hl,hl			;6f6d   ; A por 128
	add hl,hl			;6f6e
	add hl,hl			;6f6f
	add hl,de			;6f70   ; A por 144
	ld de,0ea89h		;6f71   ; tabla de formaciones del equipo
	add hl,de			;6f74
	ret			;6f75
uno_o_dos_huerfano:		; Huerfano: 1 o 2 al azar
	ld a,r		;6f76
	and 001h		;6f78
	add a,001h		;6f7a
	ret			;6f7c
paso_formacion:		; HL = puntero al siguiente paso de la formacion del jugador A
	call puntero_paso		;6f7d   ; puntero del jugador
	ld e,(hl)			;6f80   ; paso en curso
	inc hl			;6f81
	ld d,(hl)			;6f82
	ex de,hl			;6f83
	ret			;6f84
punteros_formacion:		; Puntero de cada uno de los tres atacantes: bloque mas 8 por su zona
	ld b,003h		;6f85
	ld c,008h		;6f87
	xor a			;6f89
L_6F8A:
	push hl			;6f8a
	push bc			;6f8b
	push af			;6f8c
	call lee_e844		;6f8d   ; zona del jugador
	push af			;6f90
	and a			;6f91
	jr z,L_6F99		;6f92
	ld b,a			;6f94
	xor a			;6f95
L_6F96:
	add a,c			;6f96
	djnz L_6F96		;6f97
L_6F99:
	ld e,a			;6f99   ; 8 bytes por zona
	ld d,000h		;6f9a
	add hl,de			;6f9c   ; puntero de pasos
	ex de,hl			;6f9d
	pop af			;6f9e
	call puntero_paso		;6f9f   ; hueco del jugador
	ld (hl),e			;6fa2   ; guarda el puntero
	inc hl			;6fa3
	ld (hl),d			;6fa4
	pop af			;6fa5
	pop bc			;6fa6
	pop hl			;6fa7
	inc a			;6fa8   ; siguiente jugador
	djnz L_6F8A		;6fa9
	ret			;6fab
avanza_paso:		; Guarda DE como puntero de pasos del jugador A
	ex de,hl			;6fac
	call puntero_paso		;6fad   ; hueco del jugador
	ld (hl),e			;6fb0   ; guarda el puntero
	inc hl			;6fb1
	ld (hl),d			;6fb2
	inc hl			;6fb3
	ex de,hl			;6fb4
	ret			;6fb5
puntero_paso:		; HL = 0xE84A + (A mod 3) * 2
	push af			;6fb6
	cp 003h		;6fb7
	jr c,L_6FBD		;6fb9
	sub 003h		;6fbb
L_6FBD:
	add a,a			;6fbd   ; dos bytes por jugador
	push de			;6fbe
	ld e,a			;6fbf
	ld d,000h		;6fc0
	ld hl,0e84ah		;6fc2   ; punteros de pasos
	add hl,de			;6fc5
	pop de			;6fc6
	pop af			;6fc7
	ret			;6fc8
vigila_formacion:		; Cancela la formacion en curso si se cumple alguna condicion de corte
	ld hl,0e850h		;6fc9
	ld a,03fh		;6fcc   ; 0x3F: no hay formacion
	cp (hl)			;6fce
	ret z			;6fcf
	call en_zona_poseedor		;6fd0   ; el poseedor ya esta cerca de la canasta
	jr nz,L_6FE4		;6fd3
	call acabados		;6fd5   ; dos o mas atacantes ya sin pasos
	jr c,L_6FE4		;6fd8
	call tiro_en_vuelo		;6fda   ; tiro en vuelo
	jp m,L_6FE4		;6fdd
	call hay_formacion		;6fe0
	ret nz			;6fe3
L_6FE4:
	ld hl,0e520h		;6fe4   ; destinos de los tres atacantes
	ld a,(0e83ch)		;6fe7
	and a			;6fea
	jr z,L_6FF0		;6feb
	ld hl,0e5b0h		;6fed   ; equipo derecho
L_6FF0:
	ld de,0002eh		;6ff0
	ld b,003h		;6ff3
	ld a,03fh		;6ff5
L_6FF7:
	ld (hl),000h		;6ff7   ; sin destino
	inc hl			;6ff9
	ld (hl),000h		;6ffa
	inc hl			;6ffc
	ld (hl),a			;6ffd   ; sin formacion
	add hl,de			;6ffe
	djnz L_6FF7		;6fff
	ld a,03fh		;7001
	ld (0e850h),a		;7003   ; sin formacion en curso
	ld a,080h		;7006   ; repinta FORMATION=
	ld (0ed59h),a		;7008
	ret			;700b
hay_formacion:		; NZ si hay formacion en curso
	ld a,(0e850h)		;700c
	cp 03fh		;700f
	ret			;7011
tiro_en_vuelo:		; Flags de 0xE6CF: negativo con el balon en vuelo
	ld a,(0e6cfh)		;7012
	and a			;7015
	ret			;7016
acabados:		; Acarreo si dos o mas de los tres atacantes ya no tienen pasos (+0x22 = 0x3F)
	ld hl,0e522h		;7017
	ld a,(0e83ch)		;701a
	and a			;701d
	jr z,L_7023		;701e
	ld hl,0e5b2h		;7020   ; equipo derecho
L_7023:
	ld b,003h		;7023
	ld a,03fh		;7025
	ld de,00030h		;7027
	ld c,000h		;702a
L_702C:
	cp (hl)			;702c   ; sin pasos
	jr nz,L_7030		;702d
	inc c			;702f
L_7030:
	add hl,de			;7030
	djnz L_702C		;7031
	ld a,001h		;7033
	cp c			;7035
	ret			;7036
en_zona_poseedor:		; NZ si el poseedor esta en el rectangulo de su canasta de ataque (Y de 0x29 a 0x49 o de 0x28 a 0x48 segun el lado); Z si no o si el balon esta suelto
	ld a,(0e6cfh)		;7037   ; poseedor
	and 007h		;703a
	cp 007h		;703c   ; 7: balon suelto
	jr z,L_704E		;703e
	ld hl,(0e6d0h)		;7040   ; registro del poseedor
	call xy_registro		;7043   ; su Y y su X
	ld b,d			;7046   ; B = Y
	ld c,e			;7047   ; C = X
	ld de,0000dh		;7048   ; banderas (+0x0F) via +0x0D
	add hl,de			;704b
	jr L_7050		;704c
L_704E:
	and a			;704e
	ret			;704f
L_7050:
	bit 4,(hl)		;7050   ; bit 4: lado de la canasta
	jr z,L_705C		;7052
	ld de,02941h		;7054   ; X de 0x41 a 0x5F
	ld hl,04a60h		;7057
	jr L_7072		;705a
L_705C:
	ld de,028bfh		;705c   ; X de 0xA0 a 0xBE
	ld hl,049a0h		;705f   ; limites altos
	ld a,b			;7062   ; Y menor que el minimo?
	cp d			;7063
	jr c,L_7082		;7064
	cp h			;7066   ; Y por encima del maximo?
	jr nc,L_7082		;7067
	ld a,c			;7069   ; X
	cp e			;706a
	jr nc,L_7082		;706b
	cp l			;706d
	jr c,L_7082		;706e
	jr L_7080		;7070
L_7072:
	ld a,b			;7072   ; Y menor que el minimo?
	cp d			;7073
	jr c,L_7082		;7074
	cp h			;7076   ; Y por encima del maximo?
	jr nc,L_7082		;7077
	ld a,c			;7079   ; X
	cp e			;707a
	jr c,L_7082		;707b
	cp l			;707d
	jr nc,L_7082		;707e
L_7080:
	and a			;7080
	ret			;7081
L_7082:
	xor a			;7082
	ret			;7083

; ----------------------------------------------------------------------
; ===== Plantillas: demo, jugadores en pista y jugadores al azar =====
; ----------------------------------------------------------------------
prepara_demo:		; Guarda los dos rosters, pone a cero las cuentas de equipo y crea dos equipos de nivel 4 para la demo de 60 segundos
	ld hl,0e851h		;7084   ; rosters de los dos equipos
	ld de,0ed9dh		;7087   ; copia de seguridad en 0xED9D
	ld bc,001d8h		;708a   ; 472 bytes
	ldir		;708d
	xor a			;708f
	ld hl,0ea2dh		;7090   ; cuentas del equipo izquierdo
	ld b,02ch		;7093
L_7095:
	ld (hl),a			;7095
	inc hl			;7096
	djnz L_7095		;7097
	ld hl,0ea5dh		;7099   ; cuentas del equipo derecho
	ld b,02ch		;709c
L_709E:
	ld (hl),a			;709e
	inc hl			;709f
	djnz L_709E		;70a0
	ld hl,00700h		;70a2   ; jugadores 0, 1 y 2 en la pista
	ld (0ea2fh),hl		;70a5
	ld (0ea5fh),hl		;70a8
	xor a			;70ab
	ld (0ed78h),a		;70ac   ; primera mitad
	ld a,004h		;70af   ; equipo izquierdo, nivel 4
	ld (0efcdh),a		;70b1
	call genera_equipo		;70b4   ; jugadores al azar
	ld a,084h		;70b7   ; equipo derecho, nivel 4
	ld (0efcdh),a		;70b9
	call genera_equipo		;70bc
	ld hl,(0efd6h)		;70bf   ; modos de verdad guardados
	ld (0ef75h),hl		;70c2
	ld hl,00202h		;70c5   ; los dos equipos de la maquina
	ld (0efd6h),hl		;70c8
	ld hl,0003ch		;70cb   ; mitad de 60 segundos
	jp L_73AD		;70ce
fin_demo:		; Devuelve los rosters y los modos guardados por 0x7084
	ld hl,0ed9dh		;70d1
	ld de,0e851h		;70d4
	ld bc,001d8h		;70d7
	ldir		;70da
	ld hl,(0ef75h)		;70dc   ; modos de verdad
	ld (0efd6h),hl		;70df
	ret			;70e2
crea_jugador:		; Jugador nuevo en HL: nombre de ocho ?, aspecto al azar y habilidades al azar sobre la base del equipo
	push hl			;70e3
	ld (0efcdh),a		;70e4   ; jugador y equipo para 0x7E2E
	ld bc,0001ch		;70e7   ; 29 bytes a cero
	ld d,h			;70ea
	ld e,l			;70eb
	inc de			;70ec
	ld (hl),000h		;70ed
	ldir		;70ef
	pop hl			;70f1
	ld b,008h		;70f2
L_70F4:
	ld (hl),03fh		;70f4   ; nombre ????????
	inc hl			;70f6
	djnz L_70F4		;70f7
	call azar_r		;70f9   ; aspecto al azar (0-31)
	and 01fh		;70fc
	ld (hl),a			;70fe
	ld bc,00008h		;70ff
	add hl,bc			;7102
	ex de,hl			;7103
	ld c,010h		;7104   ; campo 0x10 del roster
	call campo_jugador		;7106
	ex de,hl			;7109
	ld a,(de)			;710a
	ld (hl),a			;710b
	ld b,a			;710c
	call azar_b		;710d   ; primera habilidad al azar
	call maximo_tres		;7110
	call azar_r		;7113   ; segunda habilidad: base mas azar menos 16
	and 01fh		;7116
	ld c,a			;7118
	ld a,(de)			;7119
	add a,c			;711a
	sub 010h		;711b
	jr nc,L_7120		;711d
	ld a,(de)			;711f
L_7120:
	ld b,a			;7120
	ld (hl),a			;7121   ; segunda habilidad
	call azar_d		;7122   ; y sus topes
	call maximo_tres		;7125
	ld a,c			;7128   ; otro azar: el complemento
	cpl			;7129
	and 01fh		;712a
	inc a			;712c
	ld c,a			;712d
	ld a,(de)			;712e   ; base del equipo
	add a,c			;712f
	sub 010h		;7130   ; menos 16
	jr nc,L_7135		;7132
	ld a,(de)			;7134   ; sin bajar de la base
L_7135:
	ld b,a			;7135
	ld (hl),a			;7136
	call azar_f		;7137   ; tope de la habilidad
	cp b			;713a
	jr nc,L_7142		;713b
	dec hl			;713d
	dec hl			;713e
	ld (hl),a			;713f
	inc hl			;7140
	inc hl			;7141
L_7142:
	inc de			;7142
	inc de			;7143
	ld a,(de)			;7144
	ld (hl),a			;7145
	ld b,a			;7146
	call azar_h		;7147   ; tercera habilidad
	call maximo_tres		;714a
	ld a,(de)			;714d
	add a,008h		;714e   ; y su tope: 8 mas
	jr nc,L_7154		;7150
	ld a,0ffh		;7152
L_7154:
	ld b,a			;7154
	ld (hl),a			;7155   ; tope de la tercera
	call azar_j		;7156   ; ultimo byte al azar
	dec hl			;7159
	ld a,(hl)			;715a   ; habilidad anterior
	cp b			;715b   ; la mayor de las dos
	ret c			;715c
	dec hl			;715d
	ld (hl),a			;715e
	ret			;715f
maximo_tres:		; Si A es menor que B lo guarda tres bytes atras; DE avanza tres
	cp b			;7160   ; A menor que B?
	jr nc,L_716A		;7161
	dec hl			;7163   ; guarda A tres atras
	dec hl			;7164
	dec hl			;7165
	ld (hl),a			;7166
	inc hl			;7167
	inc hl			;7168
	inc hl			;7169
L_716A:
	inc de			;716a
	inc de			;716b
	inc de			;716c
	ret			;716d
jugadores_en_pista:		; Copia a los seis registros las caracteristicas de los jugadores en pista, sus camisetas y su piel y pelo
	ld hl,(0ea2fh)		;716e   ; SUPOSICION: bandera de mascara no vacia
	ld a,h			;7171
	or l			;7172
	ld (0ea2fh),a		;7173
	ld hl,(0ea5fh)		;7176
	ld a,h			;7179
	or l			;717a
	ld (0ea5fh),a		;717b
	xor a			;717e
	ld (0efcdh),a		;717f   ; equipo izquierdo
	ld a,(0ea30h)		;7182   ; mascara de jugadores en pista
	ld c,a			;7185
	ld ix,0e500h		;7186   ; tres registros del equipo izquierdo
	ld hl,0e864h		;718a   ; campo 0x0F del primer jugador del roster
	call copia_caracteristicas		;718d
	ld a,080h		;7190   ; equipo derecho
	ld (0efcdh),a		;7192
	ld a,(0ea60h)		;7195
	ld c,a			;7198
	ld ix,0e590h		;7199
	ld hl,0e950h		;719d
	call copia_caracteristicas		;71a0
	ld hl,0e65fh		;71a3   ; color del sprite 3 (camiseta) del jugador 0
	ld a,(0ea2ch)		;71a6   ; color del equipo izquierdo
	call camisetas		;71a9
	ld a,(0ea5ch)		;71ac   ; color del equipo derecho
	call camisetas		;71af
	ld hl,0e51fh		;71b2   ; +0x1F: jugador del roster
	ld ix,0e650h		;71b5   ; sombra de atributos
	ld b,003h		;71b9   ; tres del equipo izquierdo
L_71BB:
	ld a,(hl)			;71bb
	call piel_y_pelo		;71bc
	djnz L_71BB		;71bf
	ld b,003h		;71c1
L_71C3:
	ld a,(hl)			;71c3
	set 7,a		;71c4   ; bit 7: equipo derecho
	call piel_y_pelo		;71c6
	djnz L_71C3		;71c9
	ret			;71cb
piel_y_pelo:		; Colores de piel (sprites 0 y 1) y pelo (sprite 2) del jugador A segun su aspecto (tabla 0x80E4)
	push hl			;71cc
	ld (0efcdh),a		;71cd
	ld c,008h		;71d0   ; campo 8: aspecto
	call campo_jugador		;71d2
	ld l,(hl)			;71d5
	ld h,000h		;71d6
	add hl,hl			;71d8
	ld de,080e4h		;71d9   ; parejas (piel, pelo)
	add hl,de			;71dc
	ld a,(hl)			;71dd
	inc hl			;71de
	ld c,(hl)			;71df
	pop hl			;71e0
	ld (ix+003h),a		;71e1   ; piel del sprite 0
	ld (ix+007h),a		;71e4   ; y del sprite 1
	ld (ix+00bh),c		;71e7   ; pelo del sprite 2
	ld de,00030h		;71ea
	add hl,de			;71ed
	ld de,00010h		;71ee   ; siguiente sombra de 16 bytes
	add ix,de		;71f1
	ret			;71f3
camisetas:		; Nibble alto del color del equipo como color del sprite de camiseta de tres jugadores
	rra			;71f4
	rra			;71f5
	rra			;71f6
	rra			;71f7
	and 00fh		;71f8
	ld b,003h		;71fa   ; tres jugadores
	ld de,00010h		;71fc
L_71FF:
	ld (hl),a			;71ff
	add hl,de			;7200
	djnz L_71FF		;7201
	ret			;7203
copia_caracteristicas:		; Para cada bit de C, copia al registro IX los campos del jugador del roster HL
	ld b,008h		;7204   ; ocho del roster
	ld e,000h		;7206
siguiente_del_roster:		; Bit del jugador: si esta en pista copia sus campos al siguiente registro
	srl c		;7208   ; bit del jugador
	jr nc,L_7243		;720a   ; en el banquillo
	push hl			;720c
	ld (ix+01fh),e		;720d   ; +0x1F: numero en el roster
	ld a,(hl)			;7210   ; campo 0x0F a +0x19
	ld (ix+019h),a		;7211
	inc hl			;7214
	ld a,(hl)			;7215   ; campo 0x10 a +0x1A
	ld (ix+01ah),a		;7216
	inc hl			;7219
	inc hl			;721a
	inc hl			;721b
	ld a,(hl)			;721c   ; SUPOSICION: campo 0x13 a +0x1C (salto)
	ld (ix+01ch),a		;721d
	inc hl			;7220
	inc hl			;7221
	inc hl			;7222
	ld a,(hl)			;7223   ; SUPOSICION: campo 0x16 a +0x1B (rapidez)
	ld (ix+01bh),a		;7224
	inc hl			;7227
	inc hl			;7228
	ld a,(hl)			;7229   ; campo 0x18 a +0x1D (SUPOSICION: robo)
	ld (ix+01dh),a		;722a
	push bc			;722d
	ld c,010h		;722e   ; cuenta del equipo 0x10 + jugador
	call campo_equipo		;7230
	pop bc			;7233
	ld d,000h		;7234
	add hl,de			;7236
	ld a,(hl)			;7237
	ld (ix+01eh),a		;7238   ; a +0x1E
	pop hl			;723b
	push de			;723c
	ld de,00030h		;723d   ; siguiente registro
	add ix,de		;7240
	pop de			;7242
L_7243:
	push de			;7243
	ld de,0001dh		;7244   ; siguiente jugador del roster
	add hl,de			;7247
	pop de			;7248
	inc e			;7249
	djnz siguiente_del_roster		;724a
	ret			;724c
azar_a:		; Tres bytes al azar: 0, 0x14-0x23, 0x80-0xFF, 0xC0-0xFF
	xor a			;724d
	ld (hl),a			;724e   ; 0
	inc hl			;724f
	call azar_r		;7250   ; 0x14-0x23
	and 00fh		;7253
	add a,014h		;7255
	ld (hl),a			;7257
azar_b:		; Dos bytes al azar: 0x80-0xFF y 0xC0-0xFF
	inc hl			;7258
	call azar_r		;7259   ; 0x80-0xFF
	and 07fh		;725c
	add a,080h		;725e
	ld (hl),a			;7260
	inc hl			;7261
	call azar_r		;7262   ; 0xC0-0xFF
	and 03fh		;7265
	add a,0c0h		;7267
	ld (hl),a			;7269
	inc hl			;726a
	ret			;726b
azar_c:		; Tres bytes al azar: 0x0A-0x19, 0x08-0x0F, 0xC0-0xFF
	call azar_r		;726c
	and 00fh		;726f
	add a,00ah		;7271
	ld (hl),a			;7273
azar_d:		; Dos bytes al azar: 0x08-0x0F y 0xC0-0xFF
	inc hl			;7274
	call azar_r		;7275   ; 0x08-0x0F
	and 007h		;7278
	add a,008h		;727a
	ld (hl),a			;727c
	inc hl			;727d
	call azar_r		;727e   ; 0xC0-0xFF
	and 03fh		;7281
	add a,0c0h		;7283
	ld (hl),a			;7285
	inc hl			;7286
	ret			;7287
azar_e:		; Dos bytes al azar: 0x0A-0x19 y 0xC0-0xFF
	call azar_r		;7288
	and 00fh		;728b
	add a,00ah		;728d
	ld (hl),a			;728f
azar_f:		; Un byte al azar 0xC0-0xFF
	inc hl			;7290
	call azar_r		;7291   ; 0xC0-0xFF
	and 03fh		;7294
	add a,0c0h		;7296
	ld (hl),a			;7298
	inc hl			;7299
	ret			;729a
azar_g:		; Tres bytes al azar: 0x14-0x23, 0x04-0x07, 0x60-0x7F
	call azar_r		;729b
	and 00fh		;729e
	add a,014h		;72a0
	ld (hl),a			;72a2
azar_h:		; Dos bytes al azar: 0x04-0x07 y 0x60-0x7F
	inc hl			;72a3
	call azar_r		;72a4   ; 0x04-0x07
	and 003h		;72a7
	add a,004h		;72a9
	ld (hl),a			;72ab
	inc hl			;72ac
	call azar_r		;72ad   ; 0x60-0x7F
	and 01fh		;72b0
	add a,060h		;72b2
	ld (hl),a			;72b4
	inc hl			;72b5
	ret			;72b6
azar_i:		; Dos bytes al azar: 0x6E-0xAD y 0x32-0x51
	call azar_r		;72b7
	and 03fh		;72ba
	add a,06eh		;72bc
	ld (hl),a			;72be
azar_j:		; Un byte al azar 0x32-0x51
	inc hl			;72bf
	call azar_r		;72c0   ; 0x32-0x51
	and 01fh		;72c3
	add a,032h		;72c5
	ld (hl),a			;72c7
	inc hl			;72c8
	ret			;72c9
genera_equipo:		; Ocho jugadores de la maquina: aspecto al azar y habilidades segun el nivel de (0xEFCD)
	ld a,(0efcdh)		;72ca
	push af			;72cd
	call opcion_cero		;72ce   ; SUPOSICION: nombres de la maquina
	ld c,008h		;72d1   ; campo 8 del primer jugador
	call campo_jugador		;72d3
	pop af			;72d6
	ld (0efcdh),a		;72d7
	ld b,008h		;72da   ; ocho jugadores
L_72DC:
	push bc			;72dc
	push hl			;72dd
	call azar_r		;72de   ; aspecto al azar
	and 01fh		;72e1
	ld (hl),a			;72e3
	ld de,00008h		;72e4
	add hl,de			;72e7
	ld de,01e1eh		;72e8   ; campo 0x10: 30 por nivel mas 30
	call segun_nivel		;72eb
	ld de,01e14h		;72ee   ; campo 0x13: 30 por nivel mas 20
	call segun_nivel		;72f1
	ld de,01e19h		;72f4   ; campo 0x16: 30 por nivel mas 25
	call segun_nivel		;72f7
	dec hl			;72fa
	dec hl			;72fb
	ld (hl),a			;72fc   ; tope del 0x16 en 0x17
	inc hl			;72fd
	ld de,00a1eh		;72fe   ; campo 0x18: 10 por nivel mas 30
	call segun_nivel		;7301
	ld (hl),00ah		;7304   ; campo 0x1B = 10
	pop hl			;7306
	pop bc			;7307
	ld de,0001dh		;7308   ; siguiente jugador
	add hl,de			;730b
	djnz L_72DC		;730c
	ret			;730e
segun_nivel:		; (HL) = D * nivel + E; HL avanza tres
	ld a,(0efcdh)		;730f   ; nivel en los bits bajos
	and 00fh		;7312
	jr z,L_731C		;7314
	ld c,a			;7316
	xor a			;7317
L_7318:
	add a,d			;7318
	dec c			;7319
	jr nz,L_7318		;731a
L_731C:
	add a,e			;731c   ; mas la base E
	ld (hl),a			;731d   ; al campo
	inc hl			;731e
	inc hl			;731f
	inc hl			;7320
	ret			;7321

; ----------------------------------------------------------------------
; ===== Equipos, reloj y fatiga =====
; ----------------------------------------------------------------------
inicia_equipos:		; Equipos de salida ABC y DEF, opciones por defecto y textos de las teclas de funcion borrados
	ld hl,0f87fh		;7322   ; FNKSTR: textos de las teclas de funcion
	push hl			;7325
	ld (hl),000h		;7326
	ld de,0f880h		;7328
	ld bc,0009fh		;732b
	ldir		;732e
	pop hl			;7330
	ld (hl),07fh		;7331   ; SUPOSICION: marca para la grabacion en cinta
	ld hl,0e851h		;7333   ; nombre del equipo izquierdo
	ld a,041h		;7336   ; ABC
	ld b,003h		;7338
L_733A:
	ld (hl),a			;733a
	inc hl			;733b
	inc a			;733c
	djnz L_733A		;733d
	ld hl,0e93dh		;733f   ; nombre del equipo derecho: DEF
	ld b,003h		;7342
L_7344:
	ld (hl),a			;7344
	inc hl			;7345
	inc a			;7346
	djnz L_7344		;7347
	xor a			;7349
	ld (0efdbh),a		;734a   ; COLOR OF COURT = 0
	ld (0efd6h),a		;734d   ; modos de los dos equipos a 0
	ld (0efd7h),a		;7350
	inc a			;7353
	ld (0ed7dh),a		;7354   ; reloj parado
	ld a,001h		;7357
	ld (0efdah),a		;7359   ; LENGTH OF HALF = 1
	ld a,(0785ch)		;735c   ; color del equipo izquierdo (0x785C)
	ld (0ea2ch),a		;735f
	ld a,(0785dh)		;7362   ; color del equipo derecho (0x785D)
	ld (0ea5ch),a		;7365
	ld hl,0e855h		;7368   ; nombres de jugador del izquierdo en blanco
	call nombres_en_blanco		;736b
	ld hl,0e941h		;736e   ; y los del derecho
	call nombres_en_blanco		;7371
	ld a,0d0h		;7374   ; sprites ocultos
	ld hl,01b00h		;7376
	call 0004dh		;7379   ; BIOS WRTVRM - Writes data in VRAM
	ld hl,00002h		;737c   ; modo 2 el izquierdo, 0 el derecho
	ld (0efd6h),hl		;737f
	ld a,001h		;7382
	ld (0e854h),a		;7384   ; nivel 1 del equipo izquierdo
	dec a			;7387
	ld (0efcdh),a		;7388
	call genera_equipo		;738b
	ld a,080h		;738e
	jp roster_nuevo		;7390
inicia_reloj_partido:		; Primera mitad, cansancio al azar y reloj de la mitad
	xor a			;7393
	ld (0ed78h),a		;7394   ; mitad 0
	call azar_jugadores		;7397   ; valores al azar de los jugadores
inicia_mitad:		; Reloj de la mitad: (LENGTH OF HALF + 1) * 300 segundos, faltas de equipo a cero
	ld a,001h		;739a
	ld (0ed7dh),a		;739c   ; reloj parado
	ld a,(0efdah)		;739f   ; LENGTH OF HALF
	inc a			;73a2
	ld hl,00000h		;73a3
	ld de,0012ch		;73a6   ; 300 segundos por paso
L_73A9:
	add hl,de			;73a9
	dec a			;73aa
	jr nz,L_73A9		;73ab
L_73AD:
	ld (0ed7bh),hl		;73ad   ; tiempo de la mitad
	ld hl,0003ch		;73b0   ; 60 cuadros por segundo
	ld (0ed84h),hl		;73b3
	call desactiva_cuentas		;73b6   ; cuentas de 10 y 30 segundos desactivadas
	xor a			;73b9
	ld (0ea2eh),a		;73ba   ; faltas del equipo izquierdo
	ld (0ea5eh),a		;73bd   ; faltas del equipo derecho
	ld (0ed79h),a		;73c0   ; sin tiro pendiente
	ld (0ed7ah),a		;73c3   ; la mitad no ha acabado
	call jugadores_en_pista		;73c6
	jp patrones_pista		;73c9
nombres_en_blanco:		; Ocho nombres de 8 caracteres 0x6B en el roster HL (pasos de 29)
	ld de,0001dh		;73cc
	ld c,008h		;73cf
L_73D1:
	push hl			;73d1
	ld b,008h		;73d2
L_73D4:
	ld (hl),06bh		;73d4   ; espacio de nombre
	inc hl			;73d6
	djnz L_73D4		;73d7
	pop hl			;73d9   ; siguiente jugador
	add hl,de			;73da
	dec c			;73db
	jr nz,L_73D1		;73dc
	ret			;73de
azar_jugadores:		; Ocho valores al azar de 0x10 a 0x1F en 0xEA39 y 0xEA69
	ld hl,0ea39h		;73df
	call azar_ocho		;73e2
	ld hl,0ea69h		;73e5
azar_ocho:		; Ocho valores al azar de 0x10 a 0x1F en HL
	ld b,008h		;73e8
L_73EA:
	call azar_r		;73ea   ; azar
	and 00fh		;73ed
	add a,010h		;73ef   ; 0x10-0x1F
	ld (hl),a			;73f1
	inc hl			;73f2
	djnz L_73EA		;73f3
	ret			;73f5
reloj:		; Interrupcion: temporizadores de 0xED84 (seis de 16 bits), cuenta atras de 0xED90/0xED92 y segundero del partido
	ld a,(0ed7dh)		;73f6   ; reloj parado: solo las cuentas atras
	and a			;73f9
	jr nz,L_7424		;73fa
	ld a,(0ed79h)		;73fc
	and a			;73ff
	call nz,desactiva_cuentas		;7400   ; SUPOSICION: tiro pendiente
	ld hl,0ed84h		;7403   ; seis temporizadores de 16 bits
	ld de,0ed7eh		;7406   ; con su bandera de vencido
	ld b,006h		;7409
L_740B:
	ld a,(de)			;740b
	and a			;740c
	jr nz,L_741F		;740d   ; ya vencido
	push de			;740f
	ld e,(hl)			;7410
	inc hl			;7411
	ld d,(hl)			;7412
	dec de			;7413
	ld (hl),d			;7414
	dec hl			;7415
	ld (hl),e			;7416
	ld a,d			;7417
	or e			;7418
	pop de			;7419
	jr nz,L_741F		;741a
	ld a,001h		;741c   ; vencido: bandera a 1
	ld (de),a			;741e
L_741F:
	inc de			;741f
	inc hl			;7420
	inc hl			;7421
	djnz L_740B		;7422
L_7424:
	ld b,002h		;7424   ; dos cuentas atras: 0xED90 y 0xED92
	ld hl,0ed90h		;7426
L_7429:
	ld e,(hl)			;7429   ; cuenta atras de 16 bits
	inc hl			;742a
	ld d,(hl)			;742b
	ld a,d			;742c
	or e			;742d
	jr z,L_7435		;742e   ; ya a cero
	dec de			;7430   ; un cuadro menos
	ld (hl),d			;7431
	dec hl			;7432
	ld (hl),e			;7433
	inc hl			;7434
L_7435:
	inc hl			;7435
	djnz L_7429		;7436
	ld a,(0ed84h)		;7438   ; cuadros del segundo
	ld b,a			;743b
	and 007h		;743c
	jr nz,L_7444		;743e
	inc a			;7440
	ld (0ed98h),a		;7441   ; aviso cada 8 cuadros
L_7444:
	ld a,b			;7444
	and 01fh		;7445
	jr nz,L_744D		;7447
	inc a			;7449
	ld (0ed99h),a		;744a   ; aviso cada 32 cuadros (formacion)
L_744D:
	ld hl,(0ed7bh)		;744d   ; tiempo de la mitad
	ld a,h			;7450
	or l			;7451
	jr z,fin_por_tiempo		;7452
	ld a,(0ed7eh)		;7454   ; ha pasado un segundo?
	dec a			;7457
	ret nz			;7458
	ld hl,0003ch		;7459   ; otros 60 cuadros
	ld (0ed84h),hl		;745c
	ld (0ed7eh),a		;745f
	inc a			;7462
	ld (0efdch),a		;7463   ; hay que repintar el tiempo
	ld hl,(0ed7bh)		;7466   ; un segundo menos
	dec hl			;7469
	ld (0ed7bh),hl		;746a
	ld a,h			;746d
	or l			;746e
	jr nz,fatiga		;746f
	inc a			;7471
	ld (0ed7dh),a		;7472   ; tiempo agotado: reloj parado
fin_por_tiempo:		; Sin tiempo: la mitad acaba cuando no hay tiro en el aire ni desplazamiento de ventana
	ld a,(0ed79h)		;7475
	and a			;7478
	ret nz			;7479
	ld a,(0e6cfh)		;747a
	and 018h		;747d
	ret nz			;747f
	inc a			;7480
	ld (0ed7ah),a		;7481   ; fin de la mitad
	ret			;7484
fatiga:		; Cada segundo de juego: los ocho jugadores de cada equipo ganan cansancio en la pista y lo pierden en el banquillo
	ld a,(0ed7dh)		;7485
	and a			;7488
	ret nz			;7489
	ld a,(0ea30h)		;748a   ; jugadores en pista del izquierdo (bits)
	ld hl,0e870h		;748d   ; campo de fatiga del roster
	ld de,0ea49h		;7490   ; cansancio acumulado
	call fatiga_equipo		;7493
	ld a,(0ea60h)		;7496   ; los del equipo derecho
	ld hl,0e95ch		;7499
	ld de,0ea79h		;749c
fatiga_equipo:		; Ocho jugadores: bit a 1 suma, a 0 resta, con tope 0xFF00 y 0
	ld b,008h		;749f
L_74A1:
	rra			;74a1   ; bit del jugador
	push bc			;74a2
	push af			;74a3
	push hl			;74a4
	ld c,(hl)			;74a5
	ld b,000h		;74a6
	ld a,(de)			;74a8
	ld l,a			;74a9
	inc de			;74aa
	ld a,(de)			;74ab
	ld h,a			;74ac
	jr nc,descansa		;74ad   ; en el banquillo: descansa
	add hl,bc			;74af
	jr nc,L_74B5		;74b0
	ld hl,0ff00h		;74b2   ; tope
L_74B5:
	ld a,h			;74b5   ; byte alto
	ld (de),a			;74b6
	dec de			;74b7
	ld a,l			;74b8   ; byte bajo
	ld (de),a			;74b9
	pop hl			;74ba
	pop af			;74bb
	ld bc,0001dh		;74bc   ; siguiente jugador del roster
	add hl,bc			;74bf
	pop bc			;74c0
	inc de			;74c1   ; siguiente contador
	inc de			;74c2
	djnz L_74A1		;74c3
	ret			;74c5
descansa:		; Resta sin bajar de cero
	sbc hl,bc		;74c6
	jr nc,L_74B5		;74c8
	ld hl,00000h		;74ca
	jr L_74B5		;74cd
desactiva_cuentas:		; Cuentas de 0xED7F-0xED82 a 2 (desactivadas) y umbrales de 0x74E5 a 0xED86
	ld hl,0ed7fh		;74cf
	ld b,004h		;74d2
L_74D4:
	ld (hl),002h		;74d4   ; cuentas 0xED7F-0xED82 desactivadas (2)
	inc hl			;74d6
	djnz L_74D4		;74d7
	ld hl,074e5h		;74d9   ; umbrales de 0x74E5
	ld de,0ed86h		;74dc   ; a 0xED86
	ld bc,00008h		;74df
	ldir		;74e2
	ret			;74e4

; ----------------------------------------------------------------------
; DATOS umbrales_ed86: Cuatro palabras (210, 330, 630 y 1830) que 0x74CF copia
;   a 0xED86-0xED8D
;   0x74e5..0x74ed  (8 bytes)
DATA_umbrales_ed86:
	defw 000d2h,0014ah,00276h,00726h	; 74e5

; ======================================================================
; CODIGO 0x74ed..0x77ab  (702 bytes)
; ======================================================================


guarda_resultado:		; Suma el partido a las estadisticas de los equipos con modo 0: partidos, puntos, faltas
	ld a,(0efd6h)		;74ed
	and a			;74f0
	jr nz,L_7519		;74f1
	ld a,(0ea2dh)		;74f3   ; puntos propios
	ld b,a			;74f6
	ld a,(0ea5dh)		;74f7   ; y del rival
	call resultado		;74fa   ; 0xED97 = 1 si gano
	ld de,0ea41h		;74fd
	ld hl,0e860h		;7500
	call suma_ocho		;7503   ; puntos de los ocho jugadores
	ld a,(0ea2fh)		;7506   ; faltas
	ld hl,0e862h		;7509
	call cuenta_partidos		;750c
	ld ix,0e855h		;750f
	ld hl,0ea31h		;7513
	call mejora_equipo		;7516
L_7519:
	ld a,(0efd7h)		;7519   ; equipo derecho
	and a			;751c
	ret nz			;751d
	ld a,(0ea5dh)		;751e   ; puntos del derecho
	ld b,a			;7521
	ld a,(0ea2dh)		;7522   ; contra los del izquierdo
	call resultado		;7525   ; ganado o perdido
	ld de,0ea71h		;7528   ; puntos de los ocho
	ld hl,0e94ch		;752b
	call suma_ocho		;752e
	ld a,(0ea5fh)		;7531   ; faltas
	ld hl,0e94eh		;7534
	call cuenta_partidos		;7537   ; partidos jugados
	ld ix,0e941h		;753a   ; roster derecho
	ld hl,0ea61h		;753e
mejora_equipo:		; Experiencia y caracteristicas de los ocho jugadores tras el partido
	push af			;7541
	call experiencia		;7542   ; experiencia
	pop af			;7545
	call mejora_13		;7546   ; y las cuatro caracteristicas
	call mejora_16		;7549
	call mejora_18		;754c
	jp mejora_1b		;754f
suma_ocho:		; Suma ocho bytes de DE a ocho contadores de 16 bits del roster HL
	ld b,008h		;7552
L_7554:
	ld a,(de)			;7554   ; contador del roster
	add a,(hl)			;7555   ; mas el valor
	ld (hl),a			;7556
	jr nc,L_755C		;7557
	inc hl			;7559
	inc (hl)			;755a   ; acarreo al byte alto
	dec hl			;755b
L_755C:
	push de			;755c
	ld de,0001dh		;755d   ; siguiente jugador del roster
	add hl,de			;7560
	pop de			;7561
	inc de			;7562   ; siguiente valor
	djnz L_7554		;7563
	ret			;7565
cuenta_partidos:		; Suma 1 al contador de 16 bits de cada jugador cuyo bit de A este a 1 (roster HL, pasos de 29)
	push af			;7566
	ld b,008h		;7567
L_7569:
	rra			;7569   ; bit del jugador
	jr nc,L_7573		;756a
	ld e,(hl)			;756c
	inc hl			;756d
	ld d,(hl)			;756e
	inc de			;756f   ; uno mas
	ld (hl),d			;7570
	dec hl			;7571
	ld (hl),e			;7572
L_7573:
	ld de,0001dh		;7573
	add hl,de			;7576
	djnz L_7569		;7577
	pop af			;7579
	ret			;757a
resultado:		; (0xED97) = 1 si el equipo gano (A, puntos del rival, menor que B, los suyos); 0 si no
	cp b			;757b
	ld a,000h		;757c
	jr nc,L_7581		;757e
	inc a			;7580
L_7581:
	ld (0ed97h),a		;7581
	ret			;7584
experiencia:		; SUPOSICION: tras el partido suma la experiencia de los ocho jugadores y recalcula su habilidad (+0x0F/+0x10)
	push ix		;7585
	ld a,(0ed97h)		;7587
	ld d,a			;758a
	ld b,008h		;758b
L_758D:
	push bc			;758d
	push hl			;758e
	push de			;758f
	ld a,(hl)			;7590
	add a,(ix+009h)		;7591   ; SUPOSICION: experiencia acumulada (+9/+0x0A)
	ld (ix+009h),a		;7594
	jr nc,L_759C		;7597
	inc (ix+00ah)		;7599
L_759C:
	ld a,(hl)			;759c
	ld e,(ix+011h)		;759d
	call multiplica		;75a0   ; por el factor del jugador (+0x11)
	ld e,(ix+00fh)		;75a3
	ld d,(ix+010h)		;75a6
	add hl,de			;75a9
	ld a,(ix+012h)		;75aa   ; tope (+0x12)
	jr c,L_75B3		;75ad
	cp h			;75af
	jr c,L_75B3		;75b0
	ld a,h			;75b2
L_75B3:
	pop de			;75b3
	inc d			;75b4
	dec d			;75b5
	jr nz,L_75BD		;75b6
	sub 00ah		;75b8   ; tras perder, 10 menos
	jr nc,L_75BD		;75ba
	xor a			;75bc
L_75BD:
	ld (ix+010h),a		;75bd
	ld (ix+00fh),l		;75c0
	ld bc,0001dh		;75c3   ; siguiente jugador del roster
	add ix,bc		;75c6
	pop hl			;75c8
	pop bc			;75c9
	inc hl			;75ca
	djnz L_758D		;75cb
	pop ix		;75cd
	ret			;75cf
mejora_13:		; SUPOSICION: campo +0x13 de los jugadores en pista sube +0x14 hasta +0x15; tras perder baja 4
	push ix		;75d0
	push af			;75d2
	ld c,a			;75d3
	ld b,008h		;75d4
L_75D6:
	ld a,(ix+013h)		;75d6   ; campo 0x13
	ld e,(ix+014h)		;75d9   ; subida (+0x14)
	inc d			;75dc   ; D = 0: no ha ganado
	dec d			;75dd
	jr nz,L_75E7		;75de
	sub 004h		;75e0   ; baja 4
	jr nc,L_75F6		;75e2
	xor a			;75e4
	jr L_75F6		;75e5
L_75E7:
	rr c		;75e7   ; bit del jugador
	jr nc,L_75F9		;75e9
	add a,e			;75eb   ; sube
	cp (ix+015h)		;75ec   ; tope (+0x15)
	jr z,L_75F6		;75ef
	jr c,L_75F6		;75f1
	ld a,(ix+015h)		;75f3
L_75F6:
	ld (ix+013h),a		;75f6
L_75F9:
	push bc			;75f9
	ld bc,0001dh		;75fa
	add ix,bc		;75fd
	pop bc			;75ff
	djnz L_75D6		;7600
L_7602:
	pop af			;7602
	pop ix		;7603
	ret			;7605
mejora_16:		; SUPOSICION: campo +0x16 sube 10 hasta +0x17; tras perder baja 2
	push ix		;7606
	push af			;7608
	ld c,a			;7609
	ld b,008h		;760a
L_760C:
	ld a,(ix+016h)		;760c   ; campo 0x16
	inc d			;760f   ; D = 0: no ha ganado
	dec d			;7610
	jr nz,L_761A		;7611
	sub 002h		;7613   ; baja 2
	jr nc,L_762A		;7615
	xor a			;7617
	jr L_762A		;7618
L_761A:
	rr c		;761a   ; bit del jugador
	jr nc,L_762D		;761c
	add a,00ah		;761e   ; sube 10
	cp (ix+017h)		;7620   ; tope (+0x17)
	jr z,L_762A		;7623
	jr c,L_762A		;7625
	ld a,(ix+017h)		;7627
L_762A:
	ld (ix+016h),a		;762a
L_762D:
	push bc			;762d
	ld bc,0001dh		;762e   ; siguiente jugador del roster
	add ix,bc		;7631
	pop bc			;7633
	djnz L_760C		;7634
	jr L_7602		;7636
mejora_18:		; SUPOSICION: campo +0x18 sube +0x19 hasta +0x1A; tras perder baja 2
	push ix		;7638
	push af			;763a
	ld c,a			;763b
	ld b,008h		;763c
L_763E:
	ld a,(ix+018h)		;763e   ; campo 0x18
	ld e,(ix+019h)		;7641   ; subida (+0x19)
	inc d			;7644
	dec d			;7645
	jr nz,L_764F		;7646
	sub 002h		;7648   ; sin ganar: baja 2
	jr nc,L_765E		;764a
	xor a			;764c
	jr L_765E		;764d
L_764F:
	rr c		;764f   ; bit del jugador
	jr nc,L_7661		;7651
	add a,e			;7653   ; sube
	cp (ix+01ah)		;7654   ; tope (+0x1A)
	jr z,L_765E		;7657
	jr c,L_765E		;7659
	ld a,(ix+01ah)		;765b
L_765E:
	ld (ix+018h),a		;765e
L_7661:
	push bc			;7661
	ld bc,0001dh		;7662   ; siguiente jugador del roster
	add ix,bc		;7665
	pop bc			;7667
	djnz L_763E		;7668
	jr L_7602		;766a
mejora_1b:		; SUPOSICION: campo +0x1B baja 1 hasta +0x1C; tras perder sube 1
	ld c,a			;766c
	ld b,008h		;766d
L_766F:
	ld a,(ix+01bh)		;766f   ; campo 0x1B
	inc d			;7672
	dec d			;7673
	jr nz,L_767E		;7674
	add a,001h		;7676   ; sin ganar: sube 1
	jr nc,L_768E		;7678
	ld a,0ffh		;767a
	jr L_768E		;767c
L_767E:
	rr c		;767e   ; bit del jugador
	jr nc,L_7691		;7680
	sub 001h		;7682   ; baja 1
	cp (ix+01ch)		;7684   ; tope (+0x1C)
	jr z,L_768E		;7687
	jr c,L_768E		;7689
	ld a,(ix+01ch)		;768b
L_768E:
	ld (ix+01bh),a		;768e
L_7691:
	push bc			;7691
	ld bc,0001dh		;7692   ; siguiente jugador del roster
	add ix,bc		;7695
	pop bc			;7697
	djnz L_766F		;7698
	ret			;769a
zona_controlado:		; Cada 8 cuadros mira en que zona de tiro esta el controlado y lleva la cuenta de 3 segundos
	ld a,(0ed98h)		;769b
	and a			;769e
	ret z			;769f
	xor a			;76a0
	ld (0ed98h),a		;76a1
	call controlado		;76a4   ; controlado del equipo con el balon
	ld (0ed95h),a		;76a7
	ld a,001h		;76aa
	jr L_76AF		;76ac
zona_tiro:		; Zona del jugador (0xED95) respecto a su canasta: 0 dentro de la zona, 1 media distancia, 2 triple; vigila los 3 segundos
	xor a			;76ae
L_76AF:
	ld (0ed96h),a		;76af
	push hl			;76b2
	ld a,(0ed95h)		;76b3   ; jugador
	push af			;76b6
	call registro_jugador		;76b7
	inc hl			;76ba   ; Y e X del jugador
	ld e,(hl)			;76bb
	inc hl			;76bc
	inc hl			;76bd
	ld d,(hl)			;76be
	pop af			;76bf
	ld hl,0503ah		;76c0   ; referencia del equipo 0-2 (Y 0x3A, X 0x50)
	cp 003h		;76c3
	jr c,L_76C9		;76c5
	ld h,0b0h		;76c7   ; la del equipo 3-5 (X 0xB0)
L_76C9:
	push de			;76c9
	call distancia_aprox		;76ca   ; distancia a la canasta
	pop de			;76cd
	cp 028h		;76ce   ; 40 o mas: triple
	jr nc,L_7724		;76d0
	ld a,e			;76d2
	cp 02eh		;76d3   ; fuera del ancho de la zona
	jr c,L_7716		;76d5
	cp 046h		;76d7
	jr nc,L_7716		;76d9
	ld a,d			;76db
	bit 7,a		;76dc
	jr nz,L_7712		;76de
	cp 03ch		;76e0   ; fuera del largo de la zona
	jr c,L_7716		;76e2
L_76E4:
	xor a			;76e4   ; zona 0: dentro de la zona
	call misma_zona		;76e5
	jr z,L_770D		;76e8   ; sigue en la misma zona
	ld a,(0ed7fh)		;76ea   ; vencio la cuenta de 3 segundos?
	dec a			;76ed
	jr nz,L_76FE		;76ee
	ld a,001h		;76f0   ; rotulo 1: 3 SECOND
	ld (0ed70h),a		;76f2
	ld a,(0ed95h)		;76f5   ; infractor
	ld (0ed6fh),a		;76f8
	xor a			;76fb
	jr L_7710		;76fc
L_76FE:
	dec a			;76fe
	jr nz,L_770A		;76ff
	ld hl,000d2h		;7701   ; 210 cuadros de cuenta
	ld (0ed86h),hl		;7704
	ld (0ed7fh),a		;7707   ; cuenta de 3 segundos en marcha
L_770A:
	xor a			;770a
L_770B:
	set 7,a		;770b   ; bit 7: repintar el rotulo AREA
L_770D:
	ld (0ed94h),a		;770d   ; zona nueva
L_7710:
	pop hl			;7710
	ret			;7711
L_7712:
	cp 0c4h		;7712
	jr c,L_76E4		;7714
L_7716:
	ld a,001h		;7716   ; zona 1: media distancia
L_7718:
	call misma_zona		;7718
	jr z,L_770D		;771b
	ld hl,0ed7fh		;771d   ; fuera de la zona: cuenta desactivada
	ld (hl),002h		;7720
	jr L_770B		;7722
L_7724:
	ld a,002h		;7724   ; zona 2: triple
	jr L_7718		;7726
misma_zona:		; Z si la zona A es la de (0xED96)
	ld hl,0ed96h		;7728
	inc (hl)			;772b
	dec (hl)			;772c
	ret			;772d
anota_tiro:		; Al tirar desactiva las cuentas y guarda el valor de la canasta (1 tiro libre, 2 o 3) y a quien sumarla
	ld hl,0ed7fh		;772e
	ld b,004h		;7731
L_7733:
	ld (hl),002h		;7733
	inc hl			;7735
	djnz L_7733		;7736
	ld a,(0efdeh)		;7738   ; bits del tiro (bit 6 tiro libre)
	ld c,a			;773b
	and 03fh		;773c
	jr z,L_7783		;773e   ; sin tiro
	ld b,000h		;7740
	call controlado		;7742   ; tirador
	cp 003h		;7745
	jr c,L_774B		;7747
	set 7,b		;7749   ; bit 7: equipo derecho
L_774B:
	ld (0ed95h),a		;774b
	call campo_1f		;774e   ; +0x1F del tirador
	ld e,(hl)			;7751
	ld d,000h		;7752
	ld a,b			;7754
	ld (0efcdh),a		;7755
	push bc			;7758
	ld c,008h		;7759   ; campo 8 del roster: SUPOSICION tiros intentados
	call campo_equipo		;775b
	pop bc			;775e
	add hl,de			;775f
	ld a,001h		;7760   ; tiro libre: 1 punto
	bit 6,c		;7762
	jr nz,L_7776		;7764
	push hl			;7766
	call zona_tiro		;7767   ; zona del tiro
	ld a,(0ed94h)		;776a
	and 00fh		;776d
	inc a			;776f
	cp 001h		;7770
	jr nz,L_7775		;7772
	inc a			;7774   ; dentro de la zona tambien vale 2
L_7775:
	pop hl			;7775
L_7776:
	ld (0ed9ah),a		;7776   ; valor de la canasta
	add a,(hl)			;7779
	ld (hl),a			;777a
	ld c,004h		;777b   ; campo 4 del roster: SUPOSICION puntos del jugador
	call campo_equipo		;777d
	ld (0ed9bh),hl		;7780   ; donde se sumaran
L_7783:
	ld hl,0efdeh		;7783
	res 6,(hl)		;7786   ; tiro atendido
	ret			;7788
suma_canasta:		; Suma el valor de la canasta (0xED9A) al contador apuntado por (0xED9B), con tope 0xFF
	ld hl,(0ed9bh)		;7789
	ld a,(0ed9ah)		;778c
	add a,(hl)			;778f
	jr nc,L_7794		;7790
	ld a,0ffh		;7792
L_7794:
	ld (hl),a			;7794
	ret			;7795
campo_1f:		; HL = +0x1F del jugador A
	ld hl,0e51fh		;7796
	ld de,00030h		;7799
L_779C:
	and a			;779c
	ret z			;779d
	add hl,de			;779e
	dec a			;779f
	jr L_779C		;77a0
marcador_ram:		; Descomprime el marcador de 21 x 4 (0x77AB) a 0xEF77
	ld hl,077abh		;77a2
	ld de,0ef77h		;77a5
	jp descomprime_rep		;77a8

; ----------------------------------------------------------------------
; DATOS marcador_comprimido: Bloque comprimido en el formato de 0x5331 (50
;   bytes) que 0x77A2 descomprime en 0xEF77: 84 numeros de patron, las filas
;   del marcador (0x60-0x71, 0x5C-0x5F y los 0x65 del borde)
;   0x77ab..0x77dd  (50 bytes)
DATA_marcador_comprimido:
	defb 080h,080h,060h,064h,064h,068h,08ah,064h,068h,064h	; 77ab  ..`ddh.dhd
	defb 064h,061h,066h,070h,071h,06ah,082h,020h,05ch,05dh	; 77b5  dafpqj. \]
	defb 05eh,05fh,081h,020h,06ah,070h,071h,067h,066h,020h	; 77bf  ^_. jpqgf 
	defb 020h,06ah,08ah,020h,06ah,020h,020h,067h,062h,065h	; 77c9   j. j  gbe
	defb 065h,069h,08ah,065h,069h,065h,065h,063h,080h,080h	; 77d3  ei.eieec..

; ======================================================================
; CODIGO 0x77dd..0x785a  (125 bytes)
; ======================================================================


logotipo:		; Descomprime el logotipo (0xB33E patrones, 0xB491 colores) a los patrones 0xB0-0xFF de los tres tercios
	call borra_nombres		;77dd
	ld de,0c400h		;77e0
	ld hl,0b33eh		;77e3
	call descomprime		;77e6
	ld de,00580h		;77e9   ; patrones 0xB0-0xFF del primer tercio
	ld hl,0c400h		;77ec
	ld bc,00280h		;77ef
	call tres_tercios		;77f2
	ld hl,0b491h		;77f5   ; sus colores
	ld de,0c400h		;77f8
	call descomprime		;77fb
	ld de,02580h		;77fe   ; colores desde 0x2580
	ld hl,0c400h		;7801
	ld bc,00280h		;7804
tres_tercios:		; Copia BC bytes de HL a la VRAM DE y a los dos tercios siguientes (0x800 mas alla)
	ld a,003h		;7807   ; tres tercios
L_7809:
	push hl			;7809   ; guarda el origen
	push de			;780a   ; el destino
	push bc			;780b   ; la cuenta
	push af			;780c   ; y los tercios que quedan
	call copia_a_vram		;780d   ; un tercio
	pop af			;7810   ; recupera los tercios
	pop bc			;7811   ; la cuenta
	pop de			;7812   ; y el destino
	ld hl,00800h		;7813   ; 0x800 mas
	add hl,de			;7816   ; el tercio siguiente
	ex de,hl			;7817   ; DE = destino
	pop hl			;7818   ; recupera el origen
	dec a			;7819   ; un tercio menos
	jr nz,L_7809		;781a   ; los tres
	ret			;781c
colores_area:		; Colores de la pista segun COLOR OF COURT (tabla 0x785A) en los tres tercios y 0xAEC0 encima en 0x2100
	call congela_sprites		;781d   ; pantalla parada
	ld a,(0efdbh)		;7820   ; COLOR OF COURT
	add a,a			;7823   ; por dos
	add a,a			;7824   ; por cuatro: cuatro bytes por AREA
	ld l,a			;7825   ; HL = AREA * 4
	ld h,000h		;7826   ; HL = indice
	ld de,0785ah		;7828   ; tabla de bloques de color por AREA
	add hl,de			;782b   ; HL = la ficha del AREA
	ld e,(hl)			;782c   ; puntero bajo
	inc hl			;782d   ; siguiente
	ld d,(hl)			;782e   ; puntero alto
	ex de,hl			;782f   ; HL = la tabla de colores comprimida
	ld de,0c400h		;7830   ; a 0xC400
	call descomprime_parejas		;7833   ; parejas repetidas
	ld hl,0c400h		;7836   ; desde el bufer
	ld de,02000h		;7839   ; tabla de colores 0x2000
	ld bc,00800h		;783c   ; 0x800 bytes: los 256 colores de un tercio
	call tres_tercios		;783f   ; a los tres tercios
	ld hl,0aec0h		;7842   ; colores comunes a las tres AREAS
	ld de,0c400h		;7845   ; a 0xC400
	call descomprime_marca		;7848   ; descomprime (marca c v n)
	ld hl,0c400h		;784b   ; desde el bufer
	ld de,02100h		;784e   ; desde 0x2100
	ld bc,002a0h		;7851   ; 0x2A0 bytes: los patrones 0x20-0x73
	call tres_tercios		;7854   ; a los tres tercios desde 0x2100
	jp suelta_sprites		;7857   ; pantalla en marcha, y vuelve

; ----------------------------------------------------------------------
; DATOS areas: Tres fichas de cuatro bytes, una por AREA del menu: puntero a
;   su tabla de colores comprimida (0xABA8, 0xACB0, 0xADB8) y dos colores;
;   0x781D elige la de (0xEFDB) y la descomprime (0x5373) en 0xC400 para la
;   tabla de colores de la VRAM, y 0x826F lee los dos bytes de detras
;   0x785a..0x7866  (12 bytes)
DATA_areas:
	defw 0aba8h	; 785a  -> DATA_colores_area_1
	defb 081h,051h	; 785c
	defb 0b0h,0ach	; 785e
	defb 021h,081h	; 7860
	defb 0b8h,0adh	; 7862
	defb 051h,021h	; 7864

; ======================================================================
; CODIGO 0x7866..0x796f  (265 bytes)
; ======================================================================


rotulo_falta_marcador:		; Para el reloj y escribe en el marcador el rotulo, el jugador y sus faltas; con 5 faltas personales lo expulsa
	ld hl,0ed7dh		;7866
	ld (hl),001h		;7869   ; reloj parado
	inc hl			;786b
	ld b,005h		;786c
L_786E:
	ld (hl),002h		;786e   ; cuentas desactivadas
	inc hl			;7870
	djnz L_786E		;7871
	ld a,(0efcdh)		;7873   ; tipo de falta (bits 3-6 de 0xEFCD)
	rra			;7876
	rra			;7877
	rra			;7878
	and 00fh		;7879
	push af			;787b
	ld hl,079f1h		;787c   ; cabecera de violacion
	cp 005h		;787f
	jr c,L_7886		;7881
	ld hl,079feh		;7883   ; cabecera de falta personal
L_7886:
	ld bc,0000dh		;7886
	ld de,0182ah		;7889   ; fila 1 del marcador
	call copia_a_vram		;788c
	pop af			;788f
	push af			;7890
	call pinta_rotulo		;7891   ; rotulo del tipo
	ld c,000h		;7894
	call campo_cabecera		;7896   ; nombre del jugador
	ld de,0182bh		;7899
	ld bc,00003h		;789c
	call copia_a_vram		;789f
	ld a,(0efcdh)		;78a2   ; numero del jugador
	and 007h		;78a5
	add a,031h		;78a7
	ld hl,0182fh		;78a9
	call escribe_vram		;78ac
	ld c,018h		;78af   ; campo 0x18 del roster: faltas personales
	call campo_equipo		;78b1
	ld a,(0efcdh)		;78b4
	and 007h		;78b7
	ld c,a			;78b9
	ld b,000h		;78ba
	add hl,bc			;78bc
	pop af			;78bd
	cp 005h		;78be
	jr c,L_78D4		;78c0
	inc (hl)			;78c2   ; una falta mas
	push hl			;78c3
	ld c,005h		;78c4   ; campo 5: faltas del partido
	call campo_equipo		;78c6
	inc (hl)			;78c9
	call congela_sprites		;78ca
	call pinta_faltas_equipo		;78cd   ; faltas de equipo en el marcador
	call suelta_sprites		;78d0
	pop hl			;78d3
L_78D4:
	ld a,(hl)			;78d4   ; faltas del jugador
	and a			;78d5
	jr z,L_78E7		;78d6   ; ninguna
	push af			;78d8
	push hl			;78d9
	ld c,a			;78da
	ld b,000h		;78db
	ld a,06fh		;78dd   ; una marca por falta
	ld hl,01831h		;78df   ; fila 1, columna 17
	call rellena_vram		;78e2
	pop hl			;78e5
	pop af			;78e6
L_78E7:
	cp 005h		;78e7
	jr c,L_7904		;78e9
	push hl			;78eb
	call modo_equipo		;78ec   ; SUPOSICION: quinta falta, jugador expulsado
	ld a,(hl)			;78ef
	pop hl			;78f0
	and a			;78f1
	jr z,L_78F6		;78f2
	ld (hl),000h		;78f4
L_78F6:
	ld c,007h		;78f6
	call campo_equipo		;78f8
	and 007h		;78fb
	ld b,a			;78fd
	call bit_de		;78fe   ; fuera de la mascara de jugadores en pista
	cpl			;7901
	and (hl)			;7902
	ld (hl),a			;7903
L_7904:
	xor a			;7904
	ld (0efddh),a		;7905
	ld hl,000f0h		;7908   ; cuatro segundos de rotulo
	ld (0ed90h),hl		;790b
	ld a,(0efcdh)		;790e
	and 078h		;7911
	rra			;7913
	rra			;7914
	rra			;7915
	cp 005h		;7916
	jp c,espera_cambio		;7918   ; violacion: sigue el juego tras el rotulo
	call modo_equipo		;791b
	ld a,(hl)			;791e
	and a			;791f
	jp z,L_7B28		;7920   ; expulsado: cambio obligado
	ld a,(0efd6h)		;7923
	and a			;7926
	jp z,espera_cambio		;7927
	ld a,(0efd7h)		;792a
	and a			;792d
	jp z,espera_cambio		;792e
L_7931:
	ld hl,(0ed90h)		;7931   ; espera el rotulo
	ld a,h			;7934
	or l			;7935
	jr nz,L_7931		;7936
	call congela_sprites		;7938
	call centra_ventana		;793b   ; ventana otra vez al centro
	jp suelta_sprites		;793e
pinta_faltas_equipo:		; Faltas de equipo (0xEA2E y 0xEA5E) en 0x1847 y 0x1858
	ld de,01847h		;7941
	ld hl,(0ea2eh)		;7944
	call dos_cifras_l		;7947
	ld de,01858h		;794a
	ld hl,(0ea5eh)		;794d
dos_cifras_l:		; Numero L de dos cifras en la VRAM DE
	ld h,000h		;7950
	ld c,h			;7952
	jp L_7A96		;7953
pinta_rotulo:		; Rotulo de falta de indice A (13 caracteres de 0x796F) en 0x184A
	ld l,a			;7956   ; L = indice del rotulo
	ld h,000h		;7957   ; HL = indice
	ld c,l			;7959   ; BC = indice
	ld b,h			;795a
	add hl,hl			;795b   ; por dos
	add hl,hl			;795c   ; por cuatro
	ld e,l			;795d   ; DE = indice * 4
	ld d,h			;795e   ; guardado
	add hl,hl			;795f   ; por ocho
	add hl,de			;7960   ; mas cuatro: por doce
	add hl,bc			;7961   ; mas uno: por trece, lo que mide cada rotulo
	ld de,0796fh		;7962   ; la tabla de los doce rotulos
	add hl,de			;7965   ; HL = el rotulo
	ld de,0184ah		;7966   ; fila 2, columna 10 de la pantalla
	ld bc,0000dh		;7969   ; trece caracteres
	jp copia_a_vram		;796c   ; a la VRAM

; ----------------------------------------------------------------------
; DATOS rotulos_falta: Doce rotulos de trece caracteres (0x7956 pinta el de
;   indice A en 0x184A): TRAVELLING, 3/5/10/30 SECOND, CHARGING, HACKING,
;   HOLDING, PUSHING, BLOCKING y los dos del contador (los n son digitos). Los
;   0x6C/0x6D de los extremos son los bordes del cuadro
;   0x796f..0x7a0b  (156 bytes)
DATA_rotulos_falta:
	defb 06ch,054h,052h,041h,056h,045h,04ch,04ch,049h,04eh,047h,03eh,06ch	; 796f  lTRAVELLING>l
	defb 06ch,020h,033h,020h,053h,045h,043h,04fh,04eh,044h,03eh,020h,06ch	; 797c  l 3 SECOND> l
	defb 06ch,020h,035h,020h,053h,045h,043h,04fh,04eh,044h,03eh,020h,06ch	; 7989  l 5 SECOND> l
	defb 06ch,031h,030h,020h,053h,045h,043h,04fh,04eh,044h,03eh,03eh,06ch	; 7996  l10 SECOND>>l
	defb 06ch,033h,030h,020h,053h,045h,043h,04fh,04eh,044h,03eh,03eh,06ch	; 79a3  l30 SECOND>>l
	defb 06dh,020h,043h,048h,041h,052h,047h,049h,04eh,047h,03eh,020h,06dh	; 79b0  m CHARGING> m
	defb 06dh,020h,048h,041h,043h,04bh,049h,04eh,047h,03eh,03eh,020h,06dh	; 79bd  m HACKING>> m
	defb 06dh,020h,048h,04fh,04ch,044h,049h,04eh,047h,03eh,03eh,020h,06dh	; 79ca  m HOLDING>> m
	defb 06dh,020h,050h,055h,053h,048h,049h,04eh,047h,03eh,03eh,020h,06dh	; 79d7  m PUSHING>> m
	defb 06dh,020h,042h,04ch,04fh,043h,04bh,049h,04eh,047h,03eh,020h,06dh	; 79e4  m BLOCKING> m
	defb 06ch,020h,020h,020h,03ch,020h,020h,06eh,06eh,06eh,06eh,06eh,06ch	; 79f1  l   <  nnnnnl
	defb 06dh,020h,020h,020h,03ch,020h,020h,06eh,06eh,06eh,06eh,06eh,06dh	; 79fe  m   <  nnnnnm

; ======================================================================
; CODIGO 0x7a0b..0x7c55  (586 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Marcador del partido =====
; ----------------------------------------------------------------------
marco_marcador:		; Copia el marcador de 21 x 4 (0xEF77) a la columna 6 de la fila 0
	ld bc,00415h		;7a0b   ; 4 filas de 21
	ld hl,0ef77h		;7a0e   ; el marcador descomprimido (0x77A2)
	ld de,01806h		;7a11   ; fila 0, columna 6
	jp copia_bloque		;7a14   ; cuatro filas de 21
monta_marcador:		; Marco, tiempo, puntos, faltas, mitad y nombres de los dos equipos
	call marco_marcador		;7a17   ; el cuadro
	call pinta_tiempo		;7a1a   ; tiempo
	call pinta_puntos		;7a1d   ; puntos
	call pinta_faltas_equipo		;7a20   ; faltas de equipo
	call pinta_mitad		;7a23   ; numero de mitad
	ld de,0182ah		;7a26   ; nombre del equipo izquierdo
	ld hl,0e851h		;7a29   ; el nombre del equipo de la izquierda (0xE851)
	call copia_tres		;7a2c   ; tres letras en la VRAM DE
	ld de,01834h		;7a2f   ; nombre del equipo derecho
	ld hl,0e93dh		;7a32   ; el de la derecha (0xE93D)
	jp copia_tres		;7a35   ; tres letras
pinta_mitad:		; Numero de la mitad (patron 0x2E + (0xED78)) en 0x182E
	ld a,(0ed78h)		;7a38   ; (0xED78): mitad en curso, 0 o 1
	add a,02eh		;7a3b   ; patron 0x2E o 0x2F: el 1 o el 2 del "HALF"
	ld hl,0182eh		;7a3d   ; fila 1, columna 14
	jp escribe_vram		;7a40   ; a la VRAM
pinta_tiempo:		; Tiempo restante (0xED7B, segundos) como m:ss en 0x184E
	xor a			;7a43   ; (0xEFDC) a cero
	ld (0efdch),a		;7a44   ; tiempo ya repintado
	ld hl,(0ed7bh)		;7a47   ; HL = segundos que quedan
	ld de,0184eh		;7a4a   ; fila 2, columna 14: los minutos
	ld c,000h		;7a4d   ; digitos escritos: ninguno
	push de			;7a4f   ; guarda la posicion
	ld de,00258h		;7a50   ; 600 segundos: decenas de minuto
	call divide_resta		;7a53   ; A = decenas de minuto (600 s), C acumula
	pop de			;7a56   ; recupera la posicion
	call cifra		;7a57   ; A = digito o blanco
	call pinta_digito		;7a5a   ; a la VRAM, DE++
	inc c			;7a5d   ; los minutos siempre se pintan
	push de			;7a5e   ; guarda la posicion
	ld de,0003ch		;7a5f   ; 60 segundos
	call divide_resta		;7a62   ; A = minutos sueltos (60 s)
	pop de			;7a65   ; recupera la posicion
	call cifra		;7a66   ; digito (C ya no es cero)
	call pinta_digito		;7a69   ; a la VRAM
	ld a,03ah		;7a6c   ; dos puntos y los segundos
	jp dos_cifras		;7a6e   ; los segundos, en dos cifras, detras del ':'
pinta_puntos:		; Puntos de los dos equipos (0xEA2D y 0xEA5D) en 0x184A y 0x1854
	xor a			;7a71   ; (0xEFDE) a cero
	ld (0efdeh),a		;7a72   ; puntos ya repintados
	ld de,0184ah		;7a75   ; fila 2, columna 10: puntos de la izquierda
	ld hl,(0ea2dh)		;7a78   ; puntos del izquierdo
	call pinta_numero		;7a7b   ; tres cifras
	ld de,01854h		;7a7e   ; fila 2, columna 20: puntos de la derecha
	ld hl,(0ea5dh)		;7a81   ; puntos del derecho
pinta_numero:		; Numero L de tres cifras en la VRAM DE, sin ceros a la izquierda
	ld h,000h		;7a84   ; HL = los puntos, un byte
	push de			;7a86   ; guarda la posicion
	ld c,000h		;7a87   ; C = 0: ningun digito escrito
L_7A89:
	ld de,00064h		;7a89   ; centenas
	call divide_resta		;7a8c   ; A = centenas
	pop de			;7a8f   ; recupera la posicion
	call cifra		;7a90   ; digito o blanco
dos_cifras:		; Pinta A y luego decenas y unidades de HL
	call pinta_digito		;7a93   ; a la VRAM
L_7A96:
	push de			;7a96   ; guarda la posicion
	ld de,0000ah		;7a97   ; decenas
	call divide_resta		;7a9a   ; A = decenas
	pop de			;7a9d   ; recupera la posicion
	call cifra		;7a9e   ; digito o blanco
	call pinta_digito		;7aa1   ; a la VRAM
	ld a,l			;7aa4   ; unidades siempre
	add a,030h		;7aa5   ; las unidades, siempre
pinta_digito:		; Escribe A en la VRAM DE y avanza
	ex de,hl			;7aa7   ; HL = posicion
	call escribe_vram		;7aa8   ; el digito
	inc hl			;7aab   ; posicion siguiente
	ex de,hl			;7aac   ; DE = posicion
	ret			;7aad
pinta_cinco_cifras_huerfano:		; Huerfano: pintaria un numero de cinco cifras (10000 y 1000 antes de 0x7A89)
	push de			;7aae   ; guarda la posicion
	ld c,000h		;7aaf   ; C = 0: ningun digito escrito
	ld de,02710h		;7ab1   ; 10000
	call divide_resta		;7ab4   ; A = decenas de millar
	pop de			;7ab7   ; recupera la posicion
	call cifra		;7ab8   ; digito o blanco
	call pinta_digito		;7abb   ; a la VRAM
cuatro_cifras:		; Imprime HL en cuatro cifras (millares, centenas, decenas, unidades) con los ceros de la izquierda en blanco; la entrada de cinco cifras es 0x7AAE
	push de			;7abe   ; guarda la posicion
	ld de,003e8h		;7abf   ; 1000
	call divide_resta		;7ac2   ; A = millares
	pop de			;7ac5   ; recupera la posicion
	call cifra		;7ac6   ; digito o blanco
	call pinta_digito		;7ac9   ; a la VRAM
	push de			;7acc   ; guarda la posicion
	jr L_7A89		;7acd   ; y sigue con las tres cifras de abajo
divide_resta:		; A = HL / DE por restas, HL = resto; C cuenta las cifras no nulas
	xor a			;7acf   ; A = 0: la cuenta
L_7AD0:
	sbc hl,de		;7ad0   ; HL -= DE
	jr c,L_7AD8		;7ad2   ; ya no cabe
	inc a			;7ad4   ; una mas
	inc c			;7ad5   ; C tambien
	jr L_7AD0		;7ad6   ; otra vez
L_7AD8:
	add hl,de			;7ad8   ; deshace la ultima resta
	ret			;7ad9
cifra:		; Codigo ASCII de la cifra; espacio si aun no ha salido ninguna
	add a,030h		;7ada   ; el digito
	inc c			;7adc   ; C sin cambiar
	dec c			;7add
	ret nz			;7ade   ; C no era cero: el digito
	ld a,020h		;7adf   ; C era cero: blanco
	ret			;7ae1
pinta_formacion:		; FORMATION= y la letra de la formacion (0xED59) en la fila 23; ? si es 0
	res 7,(hl)		;7ae2   ; quita la marca de repintar
	ld c,(hl)			;7ae4   ; C = formacion
	ld hl,01aefh		;7ae5   ; fila 23, columna 15
	ld de,07db5h		;7ae8   ; "FORMATION="
	call imprime		;7aeb   ; al rotulo
	ld a,c			;7aee   ; A = formacion
	and a			;7aef   ; cero?
	jr z,L_7AF6		;7af0   ; cero: la letra de ninguna
	add a,040h		;7af2   ; 1 = A
	jr L_7AF8		;7af4   ; a escribirla
L_7AF6:
	ld a,03fh		;7af6   ; ?
L_7AF8:
	jp escribe_vram		;7af8   ; la letra a la VRAM
pinta_area:		; AREA= y la zona de tiro del controlado (0xED94) en la fila 23: 1-3, o F si es 0
	res 7,(hl)		;7afb   ; quita la marca de repintar
	ld c,(hl)			;7afd   ; C = zona
	ld hl,01ae6h		;7afe   ; fila 23, columna 6
	ld de,07dc0h		;7b01   ; "AREA="
	call imprime		;7b04   ; al rotulo
	ld a,c			;7b07   ; A = zona
	and a			;7b08   ; cero?
	jr z,L_7B0F		;7b09   ; cero: la F
	add a,031h		;7b0b   ; '1' + zona - 1: 1, 2 o 3
	jr L_7B11		;7b0d   ; a escribirla
L_7B0F:
	ld a,046h		;7b0f   ; la F
L_7B11:
	jp escribe_vram		;7b11   ; a la VRAM
espera_cambio:		; Tras un rotulo espera un disparo o el tiempo; el primer disparo ofrece MEMBER CHANGE
	call lee_disparo		;7b14   ; hay disparo o espacio?
	jr nz,L_7B28		;7b17   ; si: a cambiar
	ld hl,(0ed90h)		;7b19   ; tiempo de espera
	ld a,h			;7b1c   ; el temporizador a cero?
	or l			;7b1d   ; sigue esperando
	jr nz,espera_cambio		;7b1e
	ld a,(0efddh)		;7b20   ; SUPOSICION: se pidio cambio de jugadores
	and a			;7b23   ; cero: nada que cambiar
	jr nz,cambios		;7b24   ; hay cambios
	jr rehace_pista		;7b26   ; solo rehacer la pista
L_7B28:
	ld hl,0efddh		;7b28   ; segundo disparo: cambios
	ld a,(hl)			;7b2b   ; ya estaba el mensaje?
	and a			;7b2c   ; si: espera
	jr nz,espera_cambio		;7b2d
	inc (hl)			;7b2f   ; marca que esta
	ld hl,01ae0h		;7b30   ; fila 23 con el patron 0x84
	ld bc,00020h		;7b33   ; una fila
	ld a,084h		;7b36   ; patron 0x84
	call rellena_vram		;7b38   ; la fila entera
	call congela_sprites		;7b3b   ; sprites quietos
	ld hl,01ae9h		;7b3e   ; rotulo MEMBER CHANGE
	ld de,07e00h		;7b41   ; "MEMBER CHANGE."
	call imprime		;7b44   ; al rotulo
	call suelta_sprites		;7b47   ; sprites otra vez
	jr espera_cambio		;7b4a   ; y a esperar
cambios:		; Cambio de jugadores en el descanso si algun equipo es humano; despues rehace la pista
	ld a,(0efd6h)		;7b4c   ; (0xEFD6): modo del equipo de la izquierda
	and a			;7b4f   ; humano?
	jr z,L_7B57		;7b50   ; si: rehacer
	ld a,(0efd7h)		;7b52   ; los dos de la maquina: sin cambios
	and a			;7b55   ; (0xEFD7) humano?
	ret nz			;7b56   ; los dos de la maquina: nada
L_7B57:
	call congela_sprites		;7b57   ; sprites quietos mientras se repinta
	call logotipo		;7b5a   ; logotipo
	call monta_marcador		;7b5d   ; marcador
	call sprites_plantilla		;7b60   ; SUPOSICION: pantalla de cambios
	call titulares_humanos		;7b63   ; las posiciones de los dos equipos
	call borra_nombres		;7b66   ; nombres en blanco
	call patrones_pista		;7b69   ; patrones y colores de la pista
rehace_pista:		; Descomprime el mapa y centra la ventana
	call descomprime_mapa		;7b6c   ; el mapa de 56 columnas a 0xC400
	call centra_ventana		;7b6f   ; la ventana
	jp suelta_sprites		;7b72   ; sprites otra vez
pantalla_plantilla:		; Recuadro de la plantilla: NO PLAYER FOULS FATIGUE, ocho jugadores y estadisticas
	call opcion_cero		;7b75   ; opcion a cero
	ld hl,018a0h		;7b78   ; filas 5 a 23 en blanco
	ld bc,00260h		;7b7b   ; 0x260 bytes: 19 filas
	ld a,020h		;7b7e   ; blanco
	call rellena_vram		;7b80   ; filas 5 a 23 borradas
	ld hl,018a1h		;7b83   ; recuadro
	ld de,0121dh		;7b86   ; 18 filas de alto, 30 de ancho
	call cuadro		;7b89   ; el cuadro de la ficha
	ld hl,018c2h		;7b8c   ; fila 6, columna 2
	ld bc,01c0ch		;7b8f   ; 28 de barra, el nombre a 12
	call cabecera_equipo		;7b92   ; la barra de color con el nombre
	ld a,0fah		;7b95   ; linea bajo la cabecera
	ld hl,018e2h		;7b97   ; fila 7, columna 2
	ld bc,0001ch		;7b9a   ; 28 patrones
	call rellena_vram		;7b9d   ; la linea
	call rotulos_estadisticas		;7ba0   ; SKILL y STATISTICS
	ld hl,01a6fh		;7ba3   ; fila 19, columna 15
	ld bc,00403h		;7ba6   ; 4 filas de 3
	ld d,08fh		;7ba9   ; patron 0x8F
	call rellena_bloque		;7bab   ; el hueco de las habilidades del equipo
L_7BAE:
	call cabecera_plantilla		;7bae   ; la cabecera de la plantilla (NO PLAYER FOULS FATIGUE y 1-8)
	call pinta_nombres		;7bb1   ; los ocho nombres
	call pinta_en_pista		;7bb4   ; quien esta en pista
	call pinta_faltas		;7bb7   ; las faltas
	jp pinta_fatiga		;7bba   ; la fatiga, y vuelve
cabecera_plantilla:		; Lineas, cabecera NO PLAYER FOULS FATIGUE y numeros 1-8
	ld a,0fah		;7bbd   ; patron 0xFA: linea
	ld hl,01a42h		;7bbf   ; fila 18, columna 2
	ld bc,0001ch		;7bc2   ; 28 de ancho
	call rellena_guarda		;7bc5   ; la linea de abajo
	ld a,0f4h		;7bc8   ; patron 0xF4: linea fina
	ld hl,01922h		;7bca   ; fila 9, columna 2
	call rellena_guarda		;7bcd   ; la linea bajo la cabecera
	ld de,07c55h		;7bd0   ; NO PLAYER FOULS FATIGUE
	ld hl,01903h		;7bd3   ; fila 8, columna 3
	call imprime		;7bd6   ; NO PLAYER FOULS FATIGUE
	ld de,01944h		;7bd9   ; numeros 1 a 8 en columna
	ld hl,07c99h		;7bdc   ; "12345678"
	ld bc,00801h		;7bdf   ; ocho filas de un caracter
	jp copia_bloque		;7be2   ; la columna de numeros, y vuelve
rotulos_estadisticas:		; SKILL, STATISTICS, S J R y SCORE FOULS GAMES
	ld de,07c70h		;7be5   ; "SKILL"
	ld hl,01a76h		;7be8   ; fila 19, columna 22
	call imprime		;7beb   ; a la VRAM
	ld de,07c76h		;7bee   ; "STATISTICS"
	ld hl,01a63h		;7bf1   ; fila 19, columna 3
	call imprime		;7bf4   ; a la VRAM
	ld de,01a93h		;7bf7   ; fila 20, columna 19
	ld hl,07c81h		;7bfa   ; "S." "J." "R."
	ld bc,00302h		;7bfd   ; tres filas de dos
	call copia_bloque		;7c00   ; la columna de las habilidades
	ld de,01a83h		;7c03   ; fila 20, columna 3
	ld hl,07c87h		;7c06   ; "SCORE:" "FOULS:" "GAMES:"
	ld bc,00306h		;7c09   ; tres filas de seis
	call copia_bloque		;7c0c   ; la columna de las estadisticas
habilidades_y_estadisticas:		; Las barras de habilidad del equipo (0x7EFB) en la fila 20 y los tres numeros de SCORE, FOULS y GAMES (0x7F70)
	ld hl,01a95h		;7c0f   ; fila 20, columna 21
	call pinta_habilidad		;7c12   ; las barras de habilidad del equipo
	ld de,01a89h		;7c15   ; fila 20, columna 9
	jp pinta_estadisticas		;7c18   ; los tres numeros, y vuelve
imprime:		; Escribe en la VRAM HL la cadena DE acabada en 0
	push de			;7c1b   ; guarda el principio de la cadena
L_7C1C:
	ld a,(de)			;7c1c   ; un caracter
	and a			;7c1d   ; cero: fin
	jr nz,L_7C22		;7c1e   ; sigue
	pop de			;7c20
	ret			;7c21
L_7C22:
	call escribe_vram		;7c22
	inc de			;7c25
	inc hl			;7c26
	jr L_7C1C		;7c27
copia_bloque:		; Copia B filas de C caracteres de HL a la VRAM DE (filas de 32)
	push bc			;7c29
	push hl			;7c2a
L_7C2B:
	push bc			;7c2b
	push de			;7c2c
	ld b,000h		;7c2d
	push hl			;7c2f
	push bc			;7c30
	call copia_a_vram		;7c31   ; una fila
	pop bc			;7c34
	pop hl			;7c35
	add hl,bc			;7c36   ; siguiente fila del origen
	pop de			;7c37
	push hl			;7c38
	ld hl,00020h		;7c39   ; siguiente fila de la pantalla
	add hl,de			;7c3c
	ex de,hl			;7c3d
	pop hl			;7c3e
	pop bc			;7c3f
	djnz L_7C2B		;7c40
	pop hl			;7c42
	pop bc			;7c43
	ret			;7c44
imprime_filas:		; Imprime B cadenas seguidas en filas sucesivas
	push bc			;7c45
	push de			;7c46
	push hl			;7c47
	call imprime		;7c48   ; una cadena
	pop hl			;7c4b
	ld de,00020h		;7c4c   ; fila siguiente
	add hl,de			;7c4f
	pop de			;7c50
	pop bc			;7c51
	djnz imprime_filas		;7c52
	ret			;7c54

; ----------------------------------------------------------------------
; DATOS textos: Los textos de los menus, acabados en cero: los imprime 0x7C1B
;   caracter a caracter con 0x5AF7, y los bloques de filas (12345678, ELM JNR
;   HIG COL YUG ESP USA PRO, S J R) los copia 0x7C29 en filas de 32. El punto
;   es ';', el guion es '<' y la arroba es el (c)
;   0x7c55..0x7e0f  (442 bytes)
DATA_textos:
	defb 04eh,04fh,020h,020h,050h,04ch,041h,059h,045h,052h,020h,020h,046h,04fh,055h,04ch,053h,020h,020h,046h,041h,054h,049h,047h,055h,045h,000h	; 7c55  NO  PLAYER  FOULS  FATIGUE.
	defb 053h,04bh,049h,04ch,04ch,000h	; 7c70
	defb 053h,054h,041h,054h,049h,053h,054h,049h,043h,053h,000h	; 7c76  STATISTICS.
	defb 053h,03ch,04ah,03ch,052h,03ch,053h,043h,04fh,052h,045h,03ah,046h,04fh,055h,04ch,053h,03ah,047h,041h,04dh,045h,053h,03ah,031h,032h,033h,034h,035h,036h,037h,038h,045h,04ch,04dh,04ah,04eh,052h,048h,049h,047h,043h,04fh,04ch,059h,055h,047h,045h,053h,050h,055h,053h,041h,050h,052h,04fh,043h,04fh,04dh,050h,055h,054h,045h,052h,020h,054h,045h,041h,04dh,053h,000h	; 7c81  S<J<R<SCORE:FOULS:GAMES:12345678ELMJNRHIGCOLYUGESPUSAPROCOMPUTER TEAMS.
	defb 04ch,045h,056h,045h,04ch,000h	; 7cc8
	defb 054h,045h,041h,04dh,000h	; 7cce
	defb 04dh,041h,04bh,045h,020h,054h,045h,041h,04dh,020h,04ch,04fh,041h,044h,020h,044h,041h,054h,041h,020h,052h,045h,041h,044h,059h,03ch,04dh,041h,044h,045h,043h,04fh,04dh,050h,055h,054h,045h,052h,020h,020h,045h,044h,049h,054h,020h,054h,045h,041h,04dh,020h,053h,054h,041h,052h,054h,045h,052h,053h,000h	; 7cd3  MAKE TEAM LOAD DATA READY<MADECOMPUTER  EDIT TEAM STARTERS.
	defb 020h,054h,045h,041h,04dh,020h,04eh,041h,04dh,045h,03ah,020h,020h,020h,020h,020h,06bh,06bh,06bh,020h,020h,020h,020h,020h,054h,052h,041h,044h,045h,000h	; 7d0e   TEAM NAME:     kkk     TRADE.
	defb 04eh,041h,04dh,045h,03ah,000h	; 7d2c
	defb 053h,045h,054h,03ch,055h,050h,020h,020h,020h,020h,04ch,045h,046h,054h,020h,054h,045h,041h,04dh,020h,052h,049h,047h,048h,054h,020h,054h,045h,041h,04dh,054h,052h,041h,044h,045h,020h,020h,020h,020h,020h,040h,031h,039h,038h,036h,020h,048h,041h,04ch,020h,04ch,041h,042h,04fh,052h,041h,054h,04fh,052h,059h,000h	; 7d32  SET<UP    LEFT TEAM RIGHT TEAMTRADE     @1986 HAL LABORATORY.
	defb 046h,03bh,04eh,041h,04bh,041h,04dh,055h,052h,041h,000h	; 7d6f  F;NAKAMURA.
	defb 053h,03bh,04dh,049h,052h,052h,04fh,052h,000h	; 7d7a  S;MIRROR.
	defb 054h,045h,041h,04dh,020h,04ch,045h,056h,045h,04ch,000h	; 7d83  TEAM LEVEL.
	defb 043h,04fh,04dh,050h,055h,054h,045h,052h,020h,054h,045h,041h,04dh,000h	; 7d8e  COMPUTER TEAM.
	defb 052h,045h,041h,044h,059h,03ch,04dh,041h,044h,045h,000h	; 7d9c  READY<MADE.
	defb 04eh,04fh,020h,044h,045h,041h,04ch,044h,045h,041h,04ch,020h,020h,020h,046h,04fh,052h,04dh,041h,054h,049h,04fh,04eh,03dh,000h	; 7da7  NO DEALDEAL   FORMATION=.
	defb 041h,052h,045h,041h,03dh,000h	; 7dc0
	defb 04ch,04fh,041h,044h,020h,044h,041h,054h,041h,03bh,000h	; 7dc6  LOAD DATA;.
	defb 053h,041h,056h,045h,020h,044h,041h,054h,041h,03bh,000h	; 7dd1  SAVE DATA;.
	defb 056h,045h,052h,049h,046h,059h,03bh,000h	; 7ddc  VERIFY;.
	defb 053h,055h,052h,045h,03fh,000h	; 7de4
	defb 020h,020h,020h,045h,052h,052h,04fh,052h,03eh,020h,020h,020h,000h	; 7dea     ERROR>   .
	defb 020h,046h,04fh,055h,04eh,044h,03ah,020h,000h	; 7df7   FOUND: .
	defb 04dh,045h,04dh,042h,045h,052h,020h,043h,048h,041h,04eh,047h,045h,03eh,000h	; 7e00  MEMBER CHANGE>.

; ======================================================================
; CODIGO 0x7e0f..0x80e4  (725 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Pantallas de plantilla y SET-UP =====
; ----------------------------------------------------------------------
rellena_bloque:		; B filas de C bytes con D desde la VRAM HL
	push bc			;7e0f
L_7E10:
	push bc			;7e10
	ld a,d			;7e11   ; caracter
	ld b,000h		;7e12
	call rellena_vram		;7e14   ; una fila de C
	ld bc,00020h		;7e17   ; siguiente fila
	add hl,bc			;7e1a
	pop bc			;7e1b
	djnz L_7E10		;7e1c
	pop bc			;7e1e
	ret			;7e1f
rellena_guarda:		; Rellena la VRAM conservando A y BC
	push af			;7e20
	push bc			;7e21
	call rellena_vram		;7e22   ; conserva A y BC
	pop bc			;7e25
	pop af			;7e26
	ret			;7e27
cuadro_guarda:		; Cuadro de 0x7FC1 conservando DE
	push de			;7e28
	call cuadro		;7e29
	pop de			;7e2c
	ret			;7e2d
campo_jugador:		; HL = campo C del jugador (0xEFCD) & 7 del roster del equipo (bit 7)
	ld a,(0efcdh)		;7e2e
	ld hl,0e855h		;7e31   ; jugadores del roster izquierdo
	bit 7,a		;7e34
	jr z,L_7E3B		;7e36
	ld hl,0e941h		;7e38   ; jugadores del roster derecho
L_7E3B:
	push bc			;7e3b
	ld b,000h		;7e3c
	add hl,bc			;7e3e
	and 007h		;7e3f
	jr z,L_7E4C		;7e41
	ld b,a			;7e43
	push de			;7e44
	ld de,0001dh		;7e45   ; 29 bytes por jugador
L_7E48:
	add hl,de			;7e48
	djnz L_7E48		;7e49
	pop de			;7e4b
L_7E4C:
	pop bc			;7e4c
	ret			;7e4d
campo_cabecera:		; HL = byte C de la cabecera del roster (nombre y nivel) del equipo de (0xEFCD)
	ld a,(0efcdh)		;7e4e
	ld hl,0e851h		;7e51
	bit 7,a		;7e54
	jr z,L_7E5B		;7e56
	ld hl,0e93dh		;7e58
L_7E5B:
	push bc			;7e5b
	ld b,000h		;7e5c
	add hl,bc			;7e5e
	pop bc			;7e5f
	ret			;7e60
campo_equipo:		; HL = cuenta C del equipo de (0xEFCD) en 0xEA29 o 0xEA59
	ld a,(0efcdh)		;7e61
	ld hl,0ea29h		;7e64
	bit 7,a		;7e67
	jr z,L_7E6E		;7e69
	ld hl,0ea59h		;7e6b
L_7E6E:
	push bc			;7e6e
	ld b,000h		;7e6f
	add hl,bc			;7e71
	pop bc			;7e72
	ret			;7e73
modo_equipo:		; HL = modo del equipo de (0xEFCD): 0xEFD6 o 0xEFD7
	ld a,(0efcdh)		;7e74
	ld hl,0efd6h		;7e77   ; modo del izquierdo
	bit 7,a		;7e7a   ; equipo derecho?
	ret z			;7e7c
	inc hl			;7e7d   ; modo del derecho
	ret			;7e7e
pinta_nombres:		; Nombres de los ocho jugadores en la columna 6 desde la fila 10
	ld a,(0efcdh)		;7e7f
	push af			;7e82
	and 080h		;7e83
	ld (0efcdh),a		;7e85
	ld c,000h		;7e88
	call campo_jugador		;7e8a
	ld de,01946h		;7e8d   ; fila 10, columna 6
	ld b,008h		;7e90
L_7E92:
	push bc			;7e92
	push de			;7e93
	ld bc,00008h		;7e94   ; 8 caracteres
	push hl			;7e97
	push bc			;7e98
	call copia_a_vram		;7e99   ; nombre a la pantalla
	pop bc			;7e9c
	pop hl			;7e9d
	ld de,0001dh		;7e9e   ; siguiente jugador del roster
	add hl,de			;7ea1
	pop de			;7ea2
	push hl			;7ea3
	ld hl,00020h		;7ea4   ; siguiente fila
	add hl,de			;7ea7
	ex de,hl			;7ea8
	pop hl			;7ea9
	pop bc			;7eaa
	djnz L_7E92		;7eab
	pop af			;7ead
	ld (0efcdh),a		;7eae   ; equipo de antes
	ret			;7eb1
pinta_faltas:		; Columna FOULS: cinco casillas 0x6E con una marca 0x6F por falta personal
	ld hl,0194fh		;7eb2
	ld bc,00805h		;7eb5   ; 8 filas de 5
	ld d,06eh		;7eb8
	call rellena_bloque		;7eba
	ld c,018h		;7ebd   ; faltas personales de cada jugador
	call campo_equipo		;7ebf
	ex de,hl			;7ec2
	ld b,008h		;7ec3
	ld hl,0194fh		;7ec5
L_7EC8:
	ld a,(de)			;7ec8   ; faltas del jugador
	and a			;7ec9
	jr z,L_7ED6		;7eca
	push bc			;7ecc
	ld c,a			;7ecd
	ld b,000h		;7ece
	ld a,06fh		;7ed0   ; marca de falta
	call rellena_vram		;7ed2
	pop bc			;7ed5
L_7ED6:
	push de			;7ed6
	ld de,00020h		;7ed7   ; siguiente fila
	add hl,de			;7eda
	pop de			;7edb
	inc de			;7edc   ; siguiente jugador
	djnz L_7EC8		;7edd
	ret			;7edf
pinta_en_pista:		; Marca 0x73 en los jugadores en pista y 0x72 en los del banquillo
	ld c,007h		;7ee0   ; mascara de jugadores en pista
	call campo_equipo		;7ee2
	ld c,(hl)			;7ee5
	ld b,008h		;7ee6
	ld hl,01943h		;7ee8
	ld de,00020h		;7eeb
L_7EEE:
	ld a,072h		;7eee   ; bit del jugador
	rr c		;7ef0
	adc a,000h		;7ef2
	call escribe_vram		;7ef4
	add hl,de			;7ef7
	djnz L_7EEE		;7ef8
	ret			;7efa
pinta_habilidad:		; Tres barras de habilidad del jugador (campos 0x10, 0x13, 0x16) si el bit 6 de 0xEFCD lo pide
	push hl			;7efb
	ld a,(0efcdh)		;7efc
	push af			;7eff
	ld d,0b6h		;7f00   ; fondo de la barra
	bit 6,a		;7f02
	jr z,L_7F07		;7f04
	inc d			;7f06
L_7F07:
	ld bc,00308h		;7f07   ; 3 filas de 8
	call rellena_bloque		;7f0a
	pop af			;7f0d
	bit 6,a		;7f0e
	jr nz,L_7F14		;7f10
	pop hl			;7f12
	ret			;7f13
L_7F14:
	ld c,00fh		;7f14   ; campo 0x0F
	call campo_jugador		;7f16
	inc hl			;7f19   ; primera habilidad (0x10)
	ex de,hl			;7f1a
	pop hl			;7f1b
	call barra		;7f1c   ; barra 1
	inc de			;7f1f   ; tres bytes mas: campo 0x13
	inc de			;7f20
	inc de			;7f21
	call barra		;7f22   ; barra 2
	inc de			;7f25   ; campo 0x16: barra 3
	inc de			;7f26
	inc de			;7f27
barra:		; Barra del valor (DE)/4: bloques llenos 0xBF por cada 8 y un final 0xB7-0xBE
	push bc			;7f28
	ld a,(de)			;7f29   ; valor
	srl a		;7f2a   ; entre 4
	srl a		;7f2c
	ld c,a			;7f2e
	srl a		;7f2f   ; entre 32: bloques llenos
	srl a		;7f31
	srl a		;7f33
	ld b,a			;7f35
	push hl			;7f36
	and a			;7f37
	jr z,L_7F42		;7f38   ; ninguno lleno
L_7F3A:
	ld a,0bfh		;7f3a   ; bloque lleno
	call escribe_vram		;7f3c
	inc hl			;7f3f
	djnz L_7F3A		;7f40
L_7F42:
	ld a,c			;7f42   ; bloque final segun el resto
	and 007h		;7f43
	add a,0b7h		;7f45
	call escribe_vram		;7f47
	pop hl			;7f4a
	ld bc,00020h		;7f4b
	add hl,bc			;7f4e
	pop bc			;7f4f
	ret			;7f50
pinta_fatiga:		; Barras de FATIGUE de los ocho jugadores (byte alto del cansancio)
	ld hl,01955h		;7f51
	ld bc,00808h		;7f54
	ld d,0b7h		;7f57
	call rellena_bloque		;7f59
	ld c,020h		;7f5c   ; cansancio de los ocho
	call campo_equipo		;7f5e
	inc hl			;7f61
	ex de,hl			;7f62
	ld hl,01955h		;7f63
	ld b,008h		;7f66
L_7F68:
	call barra		;7f68
	inc de			;7f6b
	inc de			;7f6c
	djnz L_7F68		;7f6d
	ret			;7f6f
pinta_estadisticas:		; Tres contadores de 16 bits del jugador (campo 9) en cuatro cifras
	ld c,009h		;7f70
	call campo_jugador		;7f72
	ld b,003h		;7f75
L_7F77:
	push bc			;7f77
	ld c,(hl)			;7f78   ; contador de 16 bits
	inc hl			;7f79
	ld b,(hl)			;7f7a
	inc hl			;7f7b
	push hl			;7f7c
	push de			;7f7d
	ld h,b			;7f7e
	ld l,c			;7f7f
	ld c,000h		;7f80
	call cuatro_cifras		;7f82   ; cuatro cifras
	pop de			;7f85
	ld hl,00020h		;7f86   ; fila siguiente
	add hl,de			;7f89
	ex de,hl			;7f8a
	pop hl			;7f8b
	pop bc			;7f8c
	djnz L_7F77		;7f8d
	ret			;7f8f
cabecera_equipo:		; Franja del equipo (0xB0 izquierdo, 0xB3 derecho), sus extremos y el nombre
	ld d,0b0h		;7f90
	ld a,(0efcdh)		;7f92
	bit 7,a		;7f95
	jr z,L_7F9B		;7f97
	ld d,0b3h		;7f99
L_7F9B:
	ld a,d			;7f9b   ; franja del equipo
	push bc			;7f9c
	ld c,b			;7f9d
	ld b,000h		;7f9e
	call rellena_vram		;7fa0   ; B caracteres
	pop bc			;7fa3
	ld b,000h		;7fa4
	add hl,bc			;7fa6
	inc d			;7fa7   ; extremo izquierdo
	ld a,d			;7fa8
	call escribe_vram		;7fa9
	inc hl			;7fac
	inc hl			;7fad
	inc hl			;7fae
	inc hl			;7faf
	inc d			;7fb0   ; extremo derecho
	ld a,d			;7fb1
	call escribe_vram		;7fb2
	dec hl			;7fb5
	dec hl			;7fb6
	dec hl			;7fb7
	ex de,hl			;7fb8
	ld c,000h		;7fb9
	call campo_cabecera		;7fbb   ; nombre del equipo
	jp copia_tres		;7fbe
cuadro:		; Cuadro de D filas y E+1 de ancho: esquinas, lados y bordes
	push hl			;7fc1
	ld a,0f5h		;7fc2   ; esquina superior izquierda
	call escribe_vram		;7fc4
	ld a,0f7h		;7fc7   ; borde superior
	call linea		;7fc9
	ld a,0f6h		;7fcc   ; esquina superior derecha
	call escribe_vram		;7fce
	ld h,000h		;7fd1
	ld l,d			;7fd3
	add hl,hl			;7fd4
	add hl,hl			;7fd5
	add hl,hl			;7fd6
	add hl,hl			;7fd7
	add hl,hl			;7fd8
	pop bc			;7fd9
	push bc			;7fda
	add hl,bc			;7fdb
	ld a,062h		;7fdc   ; esquina inferior izquierda
	call escribe_vram		;7fde
	ld a,065h		;7fe1   ; borde inferior
	call linea		;7fe3
	ld a,063h		;7fe6   ; esquina inferior derecha
	call escribe_vram		;7fe8
	pop hl			;7feb
	ld bc,00020h		;7fec
	add hl,bc			;7fef
	push hl			;7ff0
	ld c,066h		;7ff1   ; lado izquierdo
	call columna		;7ff3
	pop hl			;7ff6
	ld b,000h		;7ff7
	ld c,e			;7ff9
	add hl,bc			;7ffa
	ld c,067h		;7ffb   ; lado derecho
columna:		; B-1 veces el caracter C hacia abajo
	ld b,d			;7ffd
	dec b			;7ffe
L_7FFF:
	ld a,c			;7fff   ; caracter del lado
	call escribe_vram		;8000
	push de			;8003
	ld de,00020h		;8004   ; fila siguiente
	add hl,de			;8007
	pop de			;8008
	djnz L_7FFF		;8009
	ret			;800b
linea:		; E caracteres A a la derecha de HL
	inc hl			;800c
	ld b,000h		;800d   ; E caracteres
	ld c,e			;800f
	push bc			;8010
	call rellena_vram		;8011   ; rellena
	pop bc			;8014
	dec hl			;8015
	add hl,bc			;8016   ; al final de la linea
	ret			;8017
sprites_plantilla:		; Pose 0x90 del jugador 0 en la VRAM y dos grupos de cuatro sprites para mostrar a los jugadores
	xor a			;8018
	call registro_jugador		;8019
	ld (0e837h),hl		;801c
	ld de,0000dh		;801f
	add hl,de			;8022
	ld (hl),090h		;8023   ; pose 0x90: de frente
	call sube_patrones_pose		;8025   ; sus patrones a 0x3800
patrones_plantilla:		; Numeros de patron de los dos grupos de sprites de la plantilla y Y 0xC0
	xor a			;8028
	ld hl,(0f928h)		;8029   ; tabla de atributos visible
	inc hl			;802c
	inc hl			;802d
	ld b,004h		;802e   ; patrones 0, 4, 8, 12
	ld de,00004h		;8030
L_8033:
	push af			;8033
	call escribe_vram		;8034
	pop af			;8037
	add a,e			;8038
	add hl,de			;8039
	djnz L_8033		;803a
	xor a			;803c   ; y el segundo grupo igual
	ld b,004h		;803d
L_803F:
	push af			;803f
	call escribe_vram		;8040
	pop af			;8043
	add a,e			;8044
	add hl,de			;8045
	djnz L_803F		;8046
	ld a,0c0h		;8048   ; Y 0xC0: ocultos de momento
	ld b,008h		;804a
	ld hl,01b00h		;804c
L_804F:
	push af			;804f
	call escribe_vram		;8050
	pop af			;8053
	add hl,de			;8054
	djnz L_804F		;8055
	ld a,0d0h		;8057   ; fin de la lista de sprites
	jp escribe_vram		;8059
viste_jugador:		; Colores del grupo de sprites del jugador de (0xEFCD) y su colocacion en DE
	push bc			;805c
	ld c,003h		;805d
	call campo_equipo		;805f   ; color del equipo
	ld a,(hl)			;8062
	and 0f0h		;8063
	rra			;8065
	rra			;8066
	rra			;8067
	rra			;8068
	ld c,00fh		;8069   ; camiseta en el sprite 3
	call atributo_plantilla		;806b
	call escribe_vram		;806e
	ld c,008h		;8071   ; aspecto del jugador
	call campo_jugador		;8073
	ld a,(hl)			;8076
	add a,a			;8077
	ld l,a			;8078
	ld h,000h		;8079
	ld de,080e4h		;807b
	add hl,de			;807e
	ld a,(hl)			;807f
	push hl			;8080
	ld c,003h		;8081
	call atributo_plantilla		;8083   ; piel en los sprites 0 y 1
	push af			;8086
	call escribe_vram		;8087
	ld de,00004h		;808a
	add hl,de			;808d
	pop af			;808e
	call escribe_vram		;808f
	pop hl			;8092
	inc hl			;8093
	ld a,(hl)			;8094
	ld c,00bh		;8095   ; pelo en el sprite 2
	call atributo_plantilla		;8097
	call escribe_vram		;809a
	ld a,090h		;809d   ; colocacion de la pose 0x90
	srl a		;809f
	srl a		;80a1
	ld l,a			;80a3
	ld h,000h		;80a4
	add hl,hl			;80a6
	add hl,hl			;80a7
	add hl,hl			;80a8
	ld de,0a38eh		;80a9
	add hl,de			;80ac
	push hl			;80ad
	pop ix		;80ae
	ld c,000h		;80b0
	call atributo_plantilla		;80b2
	pop de			;80b5
	ld b,004h		;80b6
L_80B8:
	ld a,d			;80b8
	sub (ix+000h)		;80b9   ; Y menos dy
	call escribe_vram		;80bc
	inc ix		;80bf
	inc hl			;80c1
	ld a,e			;80c2
	sub (ix+000h)		;80c3   ; X menos dx
	call escribe_vram		;80c6
	inc ix		;80c9
	inc hl			;80cb
	inc hl			;80cc
	inc hl			;80cd
	djnz L_80B8		;80ce
	ret			;80d0
atributo_plantilla:		; HL = 0x1B00 (izquierdo) o 0x1B10 (derecho) mas C
	push af			;80d1
	ld a,(0efcdh)		;80d2   ; equipo
	ld hl,01b00h		;80d5   ; sprites del izquierdo
	bit 7,a		;80d8
	jr z,L_80DF		;80da
	ld hl,01b10h		;80dc   ; sprites del derecho
L_80DF:
	ld b,000h		;80df
	add hl,bc			;80e1
	pop af			;80e2
	ret			;80e3

; ----------------------------------------------------------------------
; DATOS colores_equipo: 32 parejas de colores (piel, camiseta): la piel
;   recorre 0x0B, 0x0A y 0x01 y la camiseta once colores; 0x805C pinta la
;   pareja del equipo (hl) con 0x80D1 y 0x5AF7
;   0x80e4..0x8124  (64 bytes)
DATA_colores_equipo:
	defb 00bh,001h	; 80e4
	defb 00ah,001h	; 80e6
	defb 001h,00ah	; 80e8
	defb 00bh,00dh	; 80ea
	defb 00ah,00dh	; 80ec
	defb 001h,00dh	; 80ee
	defb 00bh,009h	; 80f0
	defb 00ah,009h	; 80f2
	defb 001h,009h	; 80f4
	defb 00bh,003h	; 80f6
	defb 00ah,003h	; 80f8
	defb 001h,003h	; 80fa
	defb 00bh,007h	; 80fc
	defb 00ah,007h	; 80fe
	defb 001h,007h	; 8100
	defb 00bh,008h	; 8102
	defb 00ah,008h	; 8104
	defb 001h,008h	; 8106
	defb 00bh,002h	; 8108
	defb 00ah,002h	; 810a
	defb 001h,002h	; 810c
	defb 00bh,005h	; 810e
	defb 00ah,005h	; 8110
	defb 001h,005h	; 8112
	defb 00bh,006h	; 8114
	defb 00ah,006h	; 8116
	defb 001h,006h	; 8118
	defb 00bh,00ch	; 811a
	defb 00ah,00ch	; 811c
	defb 001h,00ch	; 811e
	defb 00bh,004h	; 8120
	defb 00ah,004h	; 8122

; ======================================================================
; CODIGO 0x8124..0x8bf3  (2767 bytes)
; ======================================================================


borra_rotulo:		; Dos filas de 12 espacios en 0x1831
	ld hl,01831h		;8124
	ld bc,0020ch		;8127
	ld d,020h		;812a
	jp rellena_bloque		;812c

; ----------------------------------------------------------------------
; ===== SET-UP, titulo y menus de equipo =====
; ----------------------------------------------------------------------
pantalla_setup:		; Pantalla SET-UP: START, STARTERS, cambio de lados, de colores, LENGTH OF HALF y COLOR OF COURT; acarreo = ESC
	call patrones_plantilla		;812f
	call fondo_setup		;8132   ; fondo de la pantalla (0xB22A)
	call opcion_cero		;8135   ; opcion 0
setup_repinta:		; Nombres, marcas de LENGTH y de COLOR OF COURT
	call nombres_setup		;8138   ; nombres de los equipos
	call marca_length		;813b   ; marca de LENGTH OF HALF
	call marca_court		;813e   ; marca de COLOR OF COURT
setup_menu:		; Selector de seis opciones con el cursor 0x6F en la columna 8
	ld hl,01a28h		;8141   ; cursor en 0x1A28
	ld bc,0066fh		;8144   ; seis opciones, cursor 0x6F
	call selector		;8147
	ld a,c			;814a
	cp 01bh		;814b   ; ESC: vuelve al menu
	jr z,setup_esc		;814d
	cp 020h		;814f   ; espacio: elige
	jr z,L_8180		;8151
	cp 01ch		;8153   ; cursor derecha
	jr z,L_815B		;8155
	cp 01dh		;8157   ; cursor izquierda
	jr nz,setup_menu		;8159
L_815B:
	ld a,e			;815b
	cp 002h		;815c   ; opcion 2: cambia los equipos de lado
	jr nz,L_8165		;815e
	call cambia_lados		;8160
	jr setup_repinta		;8163
L_8165:
	cp 003h		;8165   ; opcion 3: cambia los colores
	jr nz,L_816E		;8167
	call cambia_colores		;8169
	jr setup_menu		;816c
L_816E:
	cp 004h		;816e   ; opcion 4: LENGTH OF HALF
	jr nz,L_8177		;8170
	call cambia_length		;8172
	jr setup_repinta		;8175
L_8177:
	cp 005h		;8177   ; opcion 5: COLOR OF COURT
	jr nz,setup_menu		;8179
	call cambia_court		;817b
	jr setup_repinta		;817e
L_8180:
	ld a,e			;8180   ; opcion 0: START
	and a			;8181
	jr nz,L_8189		;8182
	call inicia_reloj_partido		;8184   ; primera mitad y reloj
	and a			;8187   ; sin acarreo: a jugar
	ret			;8188
L_8189:
	cp 001h		;8189   ; opcion 1: STARTERS
	jr nz,setup_menu		;818b
	call pantalla_starters		;818d
	jr pantalla_setup		;8190
setup_esc:		; Acarreo: vuelta al menu del titulo
	scf			;8192
	ret			;8193
fondo_setup:		; Descomprime el fondo del SET-UP (0xB22A) y lo copia a la tabla de nombres
	ld hl,0b22ah		;8194   ; fondo comprimido
	ld de,0c400h		;8197
	call descomprime_rep		;819a   ; solo repeticiones
	ld hl,0c400h		;819d
	ld de,01800h		;81a0   ; tabla de nombres entera
	ld bc,00300h		;81a3
	jp copia_a_vram		;81a6
nombres_setup:		; Nombres de los dos equipos en 0x18C7 y 0x18D6
	ld hl,0e851h		;81a9   ; nombre del izquierdo
	ld de,018c7h		;81ac
	call copia_tres		;81af
	ld hl,0e93dh		;81b2   ; nombre del derecho
	ld de,018d6h		;81b5
	jp copia_tres		;81b8
marca_length:		; Borra las cuatro marcas y pone 0xF9 en la de LENGTH OF HALF
	ld b,004h		;81bb   ; cuatro casillas de 4 en 4
	ld hl,0194bh		;81bd
	ld de,00004h		;81c0
L_81C3:
	ld a,020h		;81c3
	call escribe_vram		;81c5
	add hl,de			;81c8
	djnz L_81C3		;81c9
	ld de,0194bh		;81cb
	ld a,(0efdah)		;81ce   ; LENGTH OF HALF por 4
	add a,a			;81d1
	add a,a			;81d2
pon_marca:		; Marca 0xF9 en DE + desplazamiento
	ld l,a			;81d3
	ld h,000h		;81d4
	add hl,de			;81d6
	ld a,0f9h		;81d7
	jp escribe_vram		;81d9
marca_court:		; Borra las tres marcas y pone la de COLOR OF COURT
	ld b,003h		;81dc   ; tres casillas de 5 en 5
	ld hl,0198ch		;81de
	ld de,00005h		;81e1
L_81E4:
	ld a,020h		;81e4   ; borra la casilla
	call escribe_vram		;81e6
	add hl,de			;81e9
	djnz L_81E4		;81ea   ; tres casillas
	ld de,0198ch		;81ec   ; primera casilla
	ld a,(0efdbh)		;81ef   ; COLOR OF COURT por 5
	ld b,a			;81f2
	add a,a			;81f3
	add a,a			;81f4
	add a,b			;81f5
	jr pon_marca		;81f6
cambia_lados:		; Intercambia los modos y los rosters (0xEC bytes) de los dos equipos
	ld hl,0efd6h		;81f8   ; modos de los dos equipos
	ld a,(hl)			;81fb
	inc hl			;81fc
	ld b,(hl)			;81fd
	ld (hl),a			;81fe
	dec hl			;81ff
	ld (hl),b			;8200
	ld hl,0e851h		;8201   ; roster izquierdo
	ld de,0e93dh		;8204   ; roster derecho
	ld bc,000ech		;8207   ; 236 bytes
intercambia_bloque:		; Intercambia BC bytes entre HL y DE
	ld a,(hl)			;820a   ; byte de HL
	push af			;820b
	ld a,(de)			;820c   ; el de DE a HL
	ld (hl),a			;820d
	pop af			;820e
	ld (de),a			;820f   ; el de HL a DE
	inc de			;8210
	inc hl			;8211
	dec bc			;8212   ; cuenta de bytes
	ld a,b			;8213
	or c			;8214
	jr nz,intercambia_bloque		;8215
	ret			;8217
cambia_colores:		; Intercambia los colores de los equipos y repinta sus franjas
	ld hl,0ea2ch		;8218   ; color del izquierdo
	ld de,0ea5ch		;821b   ; color del derecho
	ld b,(hl)			;821e
	ld a,(de)			;821f
	ld (hl),a			;8220
	ld a,b			;8221
	ld (de),a			;8222
pinta_franjas:		; Franjas de color de los dos equipos (24 bytes de color en 0x2580 y 0x2598)
	ld hl,02580h		;8223
	ld bc,00018h		;8226
	ld a,(0ea2ch)		;8229   ; color del izquierdo
	call rellena_guarda		;822c
	ld hl,02598h		;822f
	ld a,(0ea5ch)		;8232   ; color del derecho
	jp rellena_guarda		;8235
cambia_length:		; LENGTH OF HALF mas o menos uno (0-3) segun la tecla
	ld a,(0efdah)		;8238
	ld b,a			;823b
	ld a,c			;823c
	cp 01ch		;823d   ; derecha: uno mas
	jr nz,L_8244		;823f
	inc b			;8241
	jr L_8245		;8242
L_8244:
	dec b			;8244
L_8245:
	ld a,b			;8245
	and 003h		;8246   ; da la vuelta en 4
	ld (0efdah),a		;8248
	ret			;824b
cambia_court:		; COLOR OF COURT mas o menos uno (0-2) y los colores de equipo de esa pista (0x785C)
	ld a,(0efdbh)		;824c   ; COLOR OF COURT
	ld b,a			;824f
	ld a,c			;8250
	cp 01ch		;8251   ; derecha?
	jr nz,L_8258		;8253
	inc b			;8255   ; uno mas
	jr L_8259		;8256
L_8258:
	dec b			;8258
L_8259:
	ld a,b			;8259
	cp 003h		;825a   ; paso de 2 a 0
	jr z,L_8266		;825c
	cp 0ffh		;825e
	jr nz,L_8267		;8260
	ld a,002h		;8262   ; paso de 0 a 2
	jr L_8267		;8264
L_8266:
	xor a			;8266
L_8267:
	ld (0efdbh),a		;8267
	add a,a			;826a
	add a,a			;826b
	ld l,a			;826c
	ld h,000h		;826d
	ld de,0785ch		;826f   ; colores de equipo de la pista
	add hl,de			;8272
	ld a,(hl)			;8273
	ld (0ea2ch),a		;8274   ; color del izquierdo
	inc hl			;8277
	ld a,(hl)			;8278
	ld (0ea5ch),a		;8279   ; color del derecho
	jp pinta_franjas		;827c
pantalla_starters:		; STARTERS: cada equipo humano elige sus tres titulares
	call borra_nombres		;827f
	ld hl,0180bh		;8282   ; franjas de los rotulos
	ld bc,0000ah		;8285
	ld a,0fah		;8288
	call rellena_guarda		;828a
	ld hl,0184bh		;828d
	call rellena_guarda		;8290
	ld hl,0182ch		;8293   ; STARTERS
	ld de,07d05h		;8296
	call imprime		;8299
titulares_humanos:		; Cada equipo de modo 0 elige sus titulares; despues sprites y registros
	xor a			;829c
	ld (0efcdh),a		;829d   ; equipo izquierdo
	ld a,(0efd6h)		;82a0   ; modo 0: elige sus titulares
	and a			;82a3
	jr nz,L_82AC		;82a4
	call pantalla_plantilla		;82a6
	call elige_titulares		;82a9
L_82AC:
	call patrones_plantilla		;82ac
	ld hl,0efcdh		;82af   ; equipo derecho
	set 7,(hl)		;82b2
	ld a,(0efd7h)		;82b4
	and a			;82b7
	jr nz,L_82C0		;82b8
	call pantalla_plantilla		;82ba
	call elige_titulares		;82bd
L_82C0:
	call sprites_plantilla		;82c0
	jp jugadores_en_pista		;82c3   ; titulares a los registros
elige_titulares:		; Cursor sobre los ocho jugadores: espacio pone o quita, izquierda/derecha cambian de vista; ESC con tres titulares
	call 00156h		;82c6   ; BIOS KILBUF - Clears keyboard buffer
	call opcion_cero		;82c9
	ld hl,0efcdh		;82cc   ; sin barras de habilidad
	res 6,(hl)		;82cf
titulares_muestra:		; Viste el sprite del jugador del cursor
	ld bc,0b483h		;82d1
	call viste_jugador		;82d4
titulares_pinta:		; Marcas de titular
	call habilidades_y_estadisticas		;82d7
	call pinta_en_pista		;82da
titulares_menu:		; Selector de los ocho jugadores
	ld bc,008f9h		;82dd   ; ocho opciones, cursor 0xF9
	ld hl,01942h		;82e0
	call selector		;82e3
	cp 01bh		;82e6   ; ESC
	jr z,titulares_fin		;82e8
	cp 020h		;82ea   ; espacio: pone o quita
	jr z,L_8303		;82ec
	cp 01eh		;82ee   ; arriba
	jr z,titulares_muestra		;82f0
	cp 01fh		;82f2   ; abajo
	jr z,titulares_muestra		;82f4
	cp 01ch		;82f6   ; derecha
	jr z,L_82FE		;82f8
	cp 01dh		;82fa   ; izquierda
	jr nz,titulares_menu		;82fc
L_82FE:
	call cambia_vista		;82fe   ; cambia de vista
	jr titulares_pinta		;8301
L_8303:
	call alterna_titular		;8303
	jr titulares_muestra		;8306
titulares_fin:		; Solo sale con exactamente tres titulares
	ld c,007h		;8308   ; mascara de titulares
	call campo_equipo		;830a
	ld a,(hl)			;830d
	call cuenta_titulares		;830e
	jr nz,titulares_menu		;8311
	ret			;8313
cambia_vista:		; Invierte el bit 6 de 0xEFCD: barras de habilidad o estadisticas
	ld a,(0efcdh)		;8314
	bit 6,a		;8317
	jr z,L_831F		;8319
	res 6,a		;831b
	jr L_8321		;831d
L_831F:
	set 6,a		;831f
L_8321:
	ld (0efcdh),a		;8321
	ret			;8324
alterna_titular:		; Pone o quita al jugador E de la mascara de titulares; con 5 faltas no entra
	push de			;8325
	ld c,007h		;8326   ; mascara de titulares
	call campo_equipo		;8328
	pop de			;832b
	ld b,e			;832c
	call bit_de		;832d   ; bit del jugador
	ld c,a			;8330
	push bc			;8331
	push hl			;8332
	ld c,018h		;8333   ; faltas personales
	call campo_equipo		;8335
	ld d,000h		;8338
	add hl,de			;833a
	ld a,(hl)			;833b
	cp 005h		;833c   ; expulsado: fuera
	pop hl			;833e
	pop bc			;833f
	jr nc,quita_titular		;8340
	ld a,(hl)			;8342   ; ya era titular: lo quita
	and c			;8343
	jr nz,quita_titular		;8344
	ld a,(hl)			;8346
	or c			;8347
	call cuenta_titulares		;8348   ; con el cuenta mas de tres?
	jr z,L_8353		;834b
	jr c,L_8353		;834d
	ret			;834f
quita_titular:		; Quita el bit C de la mascara
	ld a,c			;8350
	cpl			;8351
	and (hl)			;8352
L_8353:
	ld (hl),a			;8353
	ret			;8354
cuenta_titulares:		; C = bits a 1 de A; Z si son tres, acarreo si menos
	ld d,a			;8355
	ld c,000h		;8356
	ld b,008h		;8358
L_835A:
	rra			;835a
	jr nc,L_835E		;835b
	inc c			;835d
L_835E:
	djnz L_835A		;835e
	ld a,c			;8360
	cp 003h		;8361
	ld a,d			;8363
	ret			;8364
bit_de:		; A = 1 desplazado B veces
	ld a,001h		;8365
	inc b			;8367
	dec b			;8368
	ret z			;8369
L_836A:
	sla a		;836a
	djnz L_836A		;836c
	ret			;836e
fondo_titulo:		; Fondo del titulo (0xB0FE) y nombres de los dos equipos
	call borra_nombres		;836f
	ld hl,0b0feh		;8372   ; fondo comprimido
	ld de,0c400h		;8375
	call descomprime_rep		;8378
	ld hl,0c400h		;837b
	ld de,01800h		;837e
	ld bc,00220h		;8381   ; 17 filas
	call copia_a_vram		;8384
	ld hl,0e851h		;8387   ; nombre del equipo izquierdo
	ld de,019e7h		;838a
	call copia_tres		;838d
	ld hl,0e93dh		;8390   ; nombre del equipo derecho
	ld de,019f6h		;8393
copia_tres:		; Copia los tres caracteres de HL a la VRAM DE (nombre de equipo)
	ld bc,00003h		;8396
	jp copia_a_vram		;8399
pantalla_titulo:		; Titulo: fondo, copyright de HAL y los dos creditos
	call fondo_titulo		;839c
	ld hl,01a66h		;839f   ; @1986 HAL LABORATORY
	ld de,07d5ah		;83a2
	call imprime		;83a5
	ld hl,01aabh		;83a8   ; F;NAKAMURA
	ld de,07d6fh		;83ab
	call imprime		;83ae
	ld hl,01acbh		;83b1   ; S;MIRROR
	ld de,07d7ah		;83b4
	jp imprime		;83b7
menu_titulo:		; Menu del titulo: SET-UP, LEFT TEAM, RIGHT TEAM y TRADE
	xor a			;83ba
	ld hl,0ea2dh		;83bb   ; cuentas del equipo izquierdo a cero
	ld b,02ch		;83be
L_83C0:
	ld (hl),a			;83c0
	inc hl			;83c1
	djnz L_83C0		;83c2
	ld hl,0ea5dh		;83c4   ; cuentas del equipo derecho a cero
	ld b,02ch		;83c7
L_83C9:
	ld (hl),a			;83c9
	inc hl			;83ca
	djnz L_83C9		;83cb
	call sprites_plantilla		;83cd
	call fondo_titulo		;83d0
	ld hl,01a48h		;83d3   ; cuadro del menu
	ld de,0050fh		;83d6
	call cuadro		;83d9
	ld hl,07d32h		;83dc   ; SET-UP, LEFT TEAM, RIGHT TEAM, TRADE
	ld de,01a6bh		;83df
	ld bc,0040ah		;83e2
	call copia_bloque		;83e5
	call opcion_cero		;83e8
suelta_espacio:		; Espera a soltar el espacio
	xor a			;83eb
	call 000d8h		;83ec   ; BIOS GTTRIG - Returns current trigger status
	jr nz,suelta_espacio		;83ef
	call 00156h		;83f1   ; BIOS KILBUF - Clears keyboard buffer
menu_titulo_elige:		; Selector de cuatro opciones; solo vale el espacio
	ld hl,01a6ah		;83f4
	ld bc,0046fh		;83f7   ; cuatro opciones, cursor 0x6F
	call selector		;83fa
	ld a,c			;83fd
	cp 020h		;83fe
	jr nz,menu_titulo_elige		;8400
	ld a,e			;8402
	and a			;8403
	jr z,titulares_por_defecto		;8404   ; SET-UP
	cp 001h		;8406   ; LEFT TEAM
	jr nz,L_8413		;8408
	xor a			;840a
L_840B:
	ld (0efcdh),a		;840b
	call menu_equipo		;840e   ; menu del equipo
	jr menu_titulo		;8411
L_8413:
	cp 002h		;8413   ; RIGHT TEAM
	jr nz,L_841B		;8415
	ld a,080h		;8417
	jr L_840B		;8419
L_841B:
	call trade		;841b   ; TRADE
	jr menu_titulo		;841e
titulares_por_defecto:		; Titulares 0, 1 y 2 en los dos equipos y a la pantalla SET-UP
	ld a,007h		;8420
	ld (0ea30h),a		;8422
	ld (0ea60h),a		;8425
	ret			;8428
trade:		; TRADE: cada equipo humano ofrece un jugador y se intercambian si se acepta DEAL
	ld hl,(0efd6h)		;8429   ; modos de los dos equipos
	ld a,h			;842c
	and a			;842d
	jr z,L_8433		;842e
	ld a,l			;8430
	and a			;8431
	ret nz			;8432
L_8433:
	call borra_nombres		;8433
	xor a			;8436   ; sin titulares mientras tanto
	ld (0ea30h),a		;8437
	ld (0ea60h),a		;843a
	ld a,0fah		;843d   ; franjas del rotulo
	ld hl,0182bh		;843f
	ld bc,00009h		;8442
	call rellena_guarda		;8445
	ld hl,0186bh		;8448
	call rellena_guarda		;844b
	ld de,07d26h		;844e   ; TRADE
	ld hl,0184dh		;8451
	call imprime		;8454
	ld hl,00000h		;8457   ; jugadores ofrecidos: 0 y 0
	ld (0efd8h),hl		;845a
	xor a			;845d
	ld (0efcdh),a		;845e
	ld a,(0efd6h)		;8461   ; equipo izquierdo humano?
	and a			;8464
	jr nz,L_846E		;8465
	call pantalla_plantilla		;8467
	call elige_ofrecido		;846a   ; elige su jugador
	ret c			;846d
L_846E:
	ld a,080h		;846e
	ld (0efcdh),a		;8470
	ld a,(0efd7h)		;8473   ; equipo derecho humano?
	and a			;8476
	jr nz,trade_mesa		;8477
	call patrones_plantilla		;8479
	call pantalla_plantilla		;847c
	call elige_ofrecido		;847f
	ret c			;8482
trade_mesa:		; Pantalla del trato: los dos jugadores ofrecidos con sus habilidades y estadisticas, y NO DEAL / DEAL
	ld hl,018a0h		;8483   ; filas 5 a 23 en blanco
	ld bc,00260h		;8486
	ld a,020h		;8489
	call rellena_vram		;848b
	ld hl,018c1h		;848e   ; recuadro izquierdo
	ld de,0090eh		;8491
	call cuadro_guarda		;8494
	ld hl,018d0h		;8497   ; recuadro derecho
	call cuadro_guarda		;849a
	ld hl,01a29h		;849d   ; recuadro del menu
	ld de,0030dh		;84a0
	call cuadro		;84a3
	ld a,0fah		;84a6   ; lineas de separacion
	ld hl,01902h		;84a8
	ld bc,0000dh		;84ab
	call rellena_guarda		;84ae
	ld hl,01911h		;84b1
	call rellena_guarda		;84b4
	ld hl,019a2h		;84b7
	call rellena_guarda		;84ba
	ld hl,019b1h		;84bd
	call rellena_guarda		;84c0
	ld hl,01922h		;84c3   ; fondos de las barras
	ld bc,00403h		;84c6
	ld d,08fh		;84c9
	call rellena_bloque		;84cb
	ld hl,01931h		;84ce
	call rellena_bloque		;84d1
	ld de,01945h		;84d4   ; S J R
	ld hl,07c81h		;84d7
	ld bc,00302h		;84da
	call copia_bloque		;84dd
	ld de,01954h		;84e0
	call copia_bloque		;84e3
	ld hl,01928h		;84e6   ; SKILL
	ld de,07c70h		;84e9
	call imprime		;84ec
	ld hl,01937h		;84ef
	call imprime		;84f2
	ld hl,019c2h		;84f5   ; NAME:
	ld de,07d2ch		;84f8
	call imprime		;84fb
	ld hl,019d1h		;84fe
	call imprime		;8501
	ld hl,(0efd6h)		;8504   ; los dos humanos: sin jugador nuevo
	ld a,l			;8507
	or h			;8508
	jr z,trade_pinta		;8509
	inc l			;850b
	dec l			;850c
	ld hl,0e941h		;850d   ; la maquina ofrece un jugador nuevo
	ld a,(0efd8h)		;8510
	jr z,L_851D		;8513
	ld hl,0e855h		;8515
	ld a,(0efd9h)		;8518
	set 7,a		;851b
L_851D:
	call crea_jugador		;851d
trade_pinta:		; Pinta los dos jugadores ofrecidos: sprite, nombre, habilidades y franja del equipo
	ld a,(0efd8h)		;8520   ; jugador del equipo izquierdo
	ld (0efcdh),a		;8523
	push af			;8526
	ld bc,0641bh		;8527   ; su sprite en (0x1B, 0x64)
	call viste_jugador		;852a
	pop af			;852d
	or 040h		;852e   ; con barras de habilidad
	ld (0efcdh),a		;8530
	ld c,000h		;8533   ; nombre
	call campo_jugador		;8535
	ld de,019c7h		;8538   ; en 0x19C7
	ld bc,00008h		;853b
	call copia_a_vram		;853e
	ld hl,01947h		;8541   ; barras de habilidad
	call pinta_habilidad		;8544
	ld hl,018e2h		;8547   ; franja del equipo
	ld bc,00d04h		;854a
	call cabecera_equipo		;854d
	ld a,(0efd9h)		;8550   ; jugador del equipo derecho
	or 080h		;8553
	ld (0efcdh),a		;8555
	push af			;8558
	ld bc,06493h		;8559   ; su sprite en (0x93, 0x64)
	call viste_jugador		;855c
	pop af			;855f
	or 0c0h		;8560
	ld (0efcdh),a		;8562
	ld c,000h		;8565   ; nombre
	call campo_jugador		;8567
	ld de,019d6h		;856a   ; en 0x19D6
	ld bc,00008h		;856d
	call copia_a_vram		;8570
	ld hl,01956h		;8573   ; barras de habilidad
	call pinta_habilidad		;8576
	ld hl,018f1h		;8579   ; franja del equipo
	ld bc,00d04h		;857c
	call cabecera_equipo		;857f
	ld de,01a4dh		;8582   ; NO DEAL / DEAL
	ld hl,07da7h		;8585
	ld bc,00207h		;8588
	call copia_bloque		;858b
	call opcion_cero		;858e
trade_elige:		; Espacio sobre NO DEAL o DEAL
	ld hl,01a4ch		;8591
	ld bc,0026fh		;8594
	call selector		;8597
	cp 020h		;859a
	jr nz,trade_elige		;859c
	ld a,e			;859e   ; NO DEAL
	and a			;859f
	ret z			;85a0
	ld a,(0efd8h)		;85a1   ; jugador ofrecido por el izquierdo
	ld (0efcdh),a		;85a4
	ld c,000h		;85a7
	call campo_jugador		;85a9
	push hl			;85ac
	ld a,(0efd9h)		;85ad   ; jugador ofrecido por el derecho
	or 080h		;85b0
	ld (0efcdh),a		;85b2
	ld c,000h		;85b5
	call campo_jugador		;85b7
	pop de			;85ba
	ld bc,0001dh		;85bb   ; intercambia sus 29 bytes
	call intercambia_bloque		;85be
	ld b,032h		;85c1   ; el borde parpadea 50 veces
L_85C3:
	push bc			;85c3
	call parpadeo_borde		;85c4
	pop bc			;85c7
	djnz L_85C3		;85c8
	ld a,001h		;85ca   ; borde negro otra vez
	ld (0f3ebh),a		;85cc
	jp 00062h		;85cf   ; BIOS CHGCLR - Changes the screen colors
parpadeo_borde:		; Siguiente color de borde y espera de dos cuadros
	ld a,(0f3ebh)		;85d2
	inc a			;85d5
	and 00fh		;85d6
	ld (0f3ebh),a		;85d8
	call 00062h		;85db   ; BIOS CHGCLR - Changes the screen colors
	ld hl,00002h		;85de   ; dos cuadros
	ld (0ed90h),hl		;85e1
L_85E4:
	ld hl,(0ed90h)		;85e4
	ld a,h			;85e7
	or l			;85e8
	jr nz,L_85E4		;85e9
	ret			;85eb
elige_ofrecido:		; Cursor sobre los ocho jugadores para elegir el que se ofrece; acarreo con ESC
	ld bc,0b483h		;85ec
	call viste_jugador		;85ef
L_85F2:
	call habilidades_y_estadisticas		;85f2
L_85F5:
	ld bc,008f9h		;85f5   ; ocho opciones
	ld hl,01942h		;85f8
	call selector		;85fb
	cp 01bh		;85fe
	jr z,elige_esc		;8600
	cp 020h		;8602   ; espacio: elegido
	jr z,L_861B		;8604
	cp 01eh		;8606
	jr z,elige_ofrecido		;8608
	cp 01fh		;860a
	jr z,elige_ofrecido		;860c
	cp 01ch		;860e
	jr z,L_8616		;8610
	cp 01dh		;8612
	jr nz,L_85F5		;8614
L_8616:
	call cambia_vista		;8616
	jr L_85F2		;8619
L_861B:
	ld a,(0efcdh)		;861b   ; jugador ofrecido del equipo
	ld hl,0efd8h		;861e
	bit 7,a		;8621
	jr z,L_8626		;8623
	inc hl			;8625
L_8626:
	ld (hl),e			;8626
	and a			;8627
	ret			;8628
elige_esc:		; Acarreo: cancelado
	scf			;8629
	ret			;862a
menu_equipo:		; Menu del equipo: MAKE TEAM, LOAD DATA, READY-MADE, COMPUTER, EDIT TEAM; DEL graba
	call borra_nombres		;862b
	ld hl,07cd3h		;862e   ; cinco opciones de 10 letras
	ld de,01804h		;8631
	ld bc,0050ah		;8634
	call copia_bloque		;8637
	call 00041h		;863a   ; BIOS DISSCR - Inhibits the screen display | pantalla apagada mientras se pinta
	ld hl,01810h		;863d
	ld de,0030dh		;8640
	call cuadro		;8643
	call pantalla_plantilla		;8646   ; plantilla
	call opcion_cero		;8649
L_864C:
	call borra_rotulo		;864c
	call panel_modo		;864f   ; panel segun el modo
	call 00044h		;8652   ; BIOS ENASCR - Displays the screen
menu_equipo_elige:		; Selector de cinco opciones del menu del equipo
	ld hl,01803h		;8655
	ld bc,0056fh		;8658
	call selector		;865b
	ld a,c			;865e
	cp 01bh		;865f   ; ESC: vuelve
	ret z			;8661
	cp 07fh		;8662   ; DEL: SAVE DATA
	jr z,pide_grabar		;8664
	cp 020h		;8666
	jr nz,menu_equipo_elige		;8668
	ld a,e			;866a
	and a			;866b
	jr nz,L_8673		;866c
	call make_team		;866e   ; MAKE TEAM
	jr L_864C		;8671
L_8673:
	cp 001h		;8673
	jr nz,L_867C		;8675
	call load_data		;8677   ; LOAD DATA
	jr L_864C		;867a
L_867C:
	cp 002h		;867c
	jr nz,L_8685		;867e
	call ready_made		;8680   ; READY-MADE
	jr L_864C		;8683
L_8685:
	cp 003h		;8685
	jr nz,L_868E		;8687
	call computer		;8689   ; COMPUTER
	jr L_864C		;868c
L_868E:
	call edit_team		;868e   ; EDIT TEAM
	jr L_864C		;8691
pide_grabar:		; Solo graba un equipo propio (modo 0)
	call modo_equipo		;8693   ; modo del equipo
	ld a,(hl)			;8696
	and a			;8697   ; 0: equipo propio
	jr nz,menu_equipo_elige		;8698
	call save_data		;869a   ; graba
	jr L_864C		;869d
make_team:		; MAKE TEAM: nombre nuevo, modo 0, jugadores nuevos al azar y edicion de sus nombres
	call pide_nombre		;869f
	ret c			;86a2
	call modo_equipo		;86a3
	ld (hl),000h		;86a6   ; modo 0: equipo propio
	ld a,(0efcdh)		;86a8
	ld (0efceh),a		;86ab
	and 080h		;86ae
	call roster_nuevo		;86b0   ; roster nuevo
edita_equipo:		; Plantilla y edicion de los ocho jugadores
	ld a,(0efcdh)		;86b3
	ld (0efceh),a		;86b6   ; opcion guardada
	call pantalla_plantilla		;86b9   ; plantilla
	call edita_nombres		;86bc   ; edita nombres y aspecto
	ld a,(0efceh)		;86bf
	ld (0efcdh),a		;86c2
	ld hl,01942h		;86c5   ; borra la columna del cursor
	ld bc,00801h		;86c8
	ld d,020h		;86cb
	jp rellena_bloque		;86cd
roster_nuevo:		; Borra el roster del equipo A y crea ocho jugadores sin nombre con caracteristicas al azar
	ld (0efcdh),a		;86d0
	ld c,000h		;86d3   ; primer jugador
	call campo_jugador		;86d5
	push hl			;86d8
	ld d,h			;86d9
	ld e,l			;86da
	inc de			;86db
	ld (hl),000h		;86dc
	ld bc,000e7h		;86de   ; 232 bytes a cero
	ldir		;86e1
	pop hl			;86e3
	call nombres_en_blanco		;86e4   ; nombres en blanco
	ld c,00fh		;86e7   ; campo 0x0F
	call campo_jugador		;86e9
	ld b,008h		;86ec   ; ocho jugadores
L_86EE:
	push hl			;86ee
	call azar_a		;86ef   ; tres azares
	call azar_c		;86f2   ; y otros
	call azar_e		;86f5
	call azar_g		;86f8
	call azar_i		;86fb
	pop hl			;86fe
	ld de,0001dh		;86ff   ; siguiente jugador
	add hl,de			;8702
	djnz L_86EE		;8703
	ret			;8705
edit_team:		; EDIT TEAM: solo con un equipo propio
	call modo_equipo		;8706
	ld a,(hl)			;8709
	and a			;870a
	ret nz			;870b
	jp edita_equipo		;870c
load_data:		; LOAD DATA: carga de cinta tras SURE?; si falla, ERROR
	ld hl,01832h		;870f   ; LOAD DATA;
	ld de,07dc6h		;8712
	call imprime		;8715
	ld hl,01854h		;8718   ; SURE?
	ld de,07de4h		;871b
	call imprime		;871e
L_8721:
	call 0009fh		;8721   ; BIOS CHGET - One character input (waiting)
	cp 01bh		;8724
	ret z			;8726
	cp 020h		;8727
	jr nz,L_8721		;8729
	xor a			;872b   ; pieza 0: silencio
	call arranca_sonido		;872c
	ld c,000h		;872f
	call campo_cabecera		;8731   ; cabecera del roster
	call carga_equipo		;8734
	push af			;8737
	ld a,00ah		;8738   ; pieza 0x0A
	call arranca_sonido		;873a
	pop af			;873d
	jr nc,cargado		;873e
error_cinta:		; Rotulo ERROR y espera el espacio
	ld hl,01851h		;8740
	ld de,07deah		;8743
	call imprime		;8746
L_8749:
	call 0009fh		;8749   ; BIOS CHGET - One character input (waiting)
	cp 020h		;874c
	jr nz,L_8749		;874e
	ret			;8750
cargado:		; Nombre del equipo cargado y modo 0
	ld c,000h		;8751   ; nombre del equipo
	call campo_cabecera		;8753
	ld de,018cfh		;8756   ; en el marcador
	call copia_tres		;8759
	call modo_equipo		;875c
	ld (hl),000h		;875f   ; modo 0: propio
	ret			;8761
save_data:		; SAVE DATA: graba el roster en cinta y ofrece VERIFY
	ld hl,01832h		;8762   ; SAVE DATA;
	ld de,07dd1h		;8765
	call imprime		;8768
	ld hl,01854h		;876b   ; SURE?
	ld de,07de4h		;876e
	call imprime		;8771
L_8774:
	call 0009fh		;8774   ; BIOS CHGET - One character input (waiting)
	cp 01bh		;8777
	ret z			;8779
	cp 020h		;877a
	jr nz,L_8774		;877c
	xor a			;877e
	call arranca_sonido		;877f
	call nombre_fichero		;8782   ; nombre de fichero
	ld c,000h		;8785
	call campo_cabecera		;8787
	push hl			;878a
	ld de,000ebh		;878b   ; fin del bloque: 0xEB bytes
	add hl,de			;878e
	ld (0f87dh),hl		;878f   ; SUPOSICION: direccion final para la grabacion
	pop hl			;8792
	call graba_equipo_sp		;8793   ; graba en cinta
	jr c,error_cinta		;8796
	call borra_rotulo		;8798
	ld hl,01833h		;879b   ; VERIFY;
	ld de,07ddch		;879e
	call imprime		;87a1
	ld hl,01854h		;87a4
	ld de,07de4h		;87a7
	call imprime		;87aa
L_87AD:
	call 0009fh		;87ad   ; BIOS CHGET - One character input (waiting)
	cp 01bh		;87b0
	ret z			;87b2
	cp 020h		;87b3
	jr nz,L_87AD		;87b5
	call nombre_fichero		;87b7
	ld c,000h		;87ba
	call campo_cabecera		;87bc
	call verifica_equipo		;87bf   ; verifica la grabacion
	push af			;87c2
	ld a,00ah		;87c3
	call arranca_sonido		;87c5
	pop af			;87c8
	jp c,error_cinta		;87c9
	ret			;87cc
nombre_fichero:		; FILNAM = las tres letras del equipo y tres 0x7F
	ld c,000h		;87cd
	call campo_cabecera		;87cf
	push hl			;87d2
	ld de,0f866h		;87d3   ; FILNAM
	ld bc,00003h		;87d6
	ldir		;87d9
	ld a,07fh		;87db
	ld b,003h		;87dd
L_87DF:
	ld (de),a			;87df
	inc de			;87e0
	djnz L_87DF		;87e1
	pop hl			;87e3
	ret			;87e4
pinta_encontrado:		; FOUND: y el nombre de FILNAM
	ld hl,01831h		;87e5
	ld de,07df7h		;87e8   ; FOUND:
	call imprime		;87eb
	ex de,hl			;87ee
	ld hl,0f866h		;87ef   ; nombre de FILNAM
	jp copia_tres		;87f2
ready_made:		; READY-MADE: nombre, TEAM LEVEL de 1 a 8 y equipo generado de ese nivel (modo 1)
	ld hl,01902h		;87f5   ; fondo del panel
	ld bc,00f1ch		;87f8
	ld d,0feh		;87fb
	call rellena_bloque		;87fd
	ld hl,01928h		;8800   ; recuadro
	ld de,00b0fh		;8803
	call cuadro		;8806
	ld hl,01949h		;8809
	ld bc,00a0eh		;880c
	ld d,020h		;880f
	call rellena_bloque		;8811
	ld hl,01969h		;8814
	ld bc,0000eh		;8817
	ld a,0f4h		;881a
	call rellena_vram		;881c
	ld hl,0194bh		;881f   ; TEAM LEVEL
	ld de,07d83h		;8822
	call imprime		;8825
	ld hl,0198dh		;8828   ; LEVEL ocho veces
	ld de,07cc8h		;882b
	ld b,008h		;882e
	call imprime_filas		;8830
	ld de,01993h		;8833   ; numeros 1 a 8
	ld hl,07c99h		;8836
	ld bc,00801h		;8839
	call copia_bloque		;883c
	call pide_nombre		;883f   ; nombre del equipo
	ret c			;8842
	ld a,(0efcdh)		;8843
	ld (0efceh),a		;8846
	and 080h		;8849
	ld (0efcdh),a		;884b
	call opcion_cero		;884e
ready_made_elige:		; Selector de los ocho niveles
	ld hl,0198ch		;8851
	ld bc,008f9h		;8854
	call selector		;8857
	ld a,c			;885a
	cp 01bh		;885b
	jr z,ready_made_esc		;885d
	cp 020h		;885f
	jr nz,ready_made_elige		;8861
	ld c,003h		;8863   ; nivel = opcion + 1 (roster +3)
	call campo_cabecera		;8865
	inc e			;8868
	ld (hl),e			;8869
	call genera_equipo		;886a   ; jugadores del nivel
	call modo_equipo		;886d
	ld (hl),001h		;8870   ; modo 1: READY-MADE
	ld hl,0198ch		;8872
	ld bc,00901h		;8875
	ld d,020h		;8878
	call rellena_bloque		;887a
	jr restaura_opcion		;887d
ready_made_esc:		; ESC: vuelve a poner el nombre anterior
	ld c,000h		;887f
	call campo_cabecera		;8881   ; nombre del equipo
	ex de,hl			;8884
	push de			;8885
	ld hl,0efd3h		;8886   ; el anterior (0xEFD3)
	ld bc,00003h		;8889
	ldir		;888c
	pop hl			;888e
	ld de,018cfh		;888f   ; en el marcador
	call copia_tres		;8892
restaura_opcion:		; Recupera 0xEFCD
	ld a,(0efceh)		;8895
	ld (0efcdh),a		;8898
	ret			;889b
computer:		; COMPUTER: equipo de la maquina de nivel 1 a 8 con su nombre de la tabla 0x7C9E (modo 2)
	call borra_rotulo		;889c
	ld hl,01902h		;889f   ; fondo del panel
	ld bc,00f1ch		;88a2
	ld d,0f0h		;88a5
	call rellena_bloque		;88a7
	ld hl,01923h		;88aa   ; recuadro
	ld de,00b19h		;88ad
	call cuadro		;88b0
	ld hl,01944h		;88b3
	ld bc,00a18h		;88b6
	ld d,020h		;88b9
	call rellena_bloque		;88bb
	ld hl,01964h		;88be
	ld bc,00018h		;88c1
	ld a,0f4h		;88c4
	call rellena_vram		;88c6
	ld de,07cb9h		;88c9   ; COMPUTER TEAMS
	ld hl,01949h		;88cc
	call imprime		;88cf
	ld de,07cc8h		;88d2   ; LEVEL ocho veces
	ld hl,01986h		;88d5
	ld b,008h		;88d8
	call imprime_filas		;88da
	ld de,07cceh		;88dd   ; TEAM ocho veces
	ld hl,01996h		;88e0
	ld b,008h		;88e3
	call imprime_filas		;88e5
	ld d,03bh		;88e8
	ld bc,00803h		;88ea
	ld hl,0198eh		;88ed
	call rellena_bloque		;88f0
	ld hl,07c99h		;88f3   ; numeros 1 a 8
	ld de,0198ch		;88f6
	ld bc,00801h		;88f9
	call copia_bloque		;88fc
	ld hl,07ca1h		;88ff   ; nombres de los ocho equipos
	ld de,01992h		;8902
	ld bc,00803h		;8905
	call copia_bloque		;8908
	ld a,(0efcdh)		;890b
	ld (0efceh),a		;890e
	call opcion_cero		;8911
computer_elige:		; Selector de los ocho equipos de la maquina
	ld hl,01985h		;8914
	ld bc,008f9h		;8917
	call selector		;891a
	ld a,c			;891d
	cp 01bh		;891e
	jr z,L_8952		;8920
	cp 020h		;8922
	jr nz,computer_elige		;8924
	ld c,003h		;8926   ; nivel = opcion + 1
	call campo_cabecera		;8928
	inc e			;892b
	ld (hl),e			;892c
	ld c,000h		;892d
	call campo_cabecera		;892f
	ex de,hl			;8932
	ld a,l			;8933   ; tres letras por equipo
	add a,a			;8934
	add a,l			;8935
	ld l,a			;8936
	ld h,000h		;8937
	ld bc,07c9eh		;8939
	add hl,bc			;893c
	ld bc,00003h		;893d
	push hl			;8940
	ldir		;8941
	pop hl			;8943
	ld de,018cfh		;8944   ; nombre en el marcador
	call copia_tres		;8947
	call genera_equipo		;894a   ; jugadores del nivel
	call modo_equipo		;894d
	ld (hl),002h		;8950   ; modo 2: maquina
L_8952:
	ld a,(0efceh)		;8952
	ld (0efcdh),a		;8955   ; opcion de antes
	ld hl,01985h		;8958   ; borra la columna del cursor
	ld bc,00901h		;895b
	ld d,020h		;895e
	jp rellena_bloque		;8960
pide_nombre:		; TEAM NAME: tres letras; guarda el anterior en 0xEFD3 y pone el nuevo
	call borra_rotulo		;8963
	ld de,01831h		;8966   ; TEAM NAME:
	ld hl,07d0eh		;8969
	ld bc,0020ch		;896c
	call copia_bloque		;896f
	ld hl,01855h		;8972
	call lee_nombre		;8975   ; lee el nombre
	ret c			;8978
	ld c,000h		;8979
	call campo_cabecera		;897b
	push hl			;897e
	ld de,0efd3h		;897f   ; nombre anterior a 0xEFD3
	ld bc,00003h		;8982
	ldir		;8985
	pop hl			;8987
	push hl			;8988
	ex de,hl			;8989
	ld hl,0efd0h		;898a   ; nombre nuevo desde 0xEFD0
	ld bc,00003h		;898d
	ldir		;8990
	pop hl			;8992
	push hl			;8993
	ld de,018cfh		;8994
	call copia_tres		;8997
	pop hl			;899a
	and a			;899b
	ret			;899c
mayusculas:		; Letras minusculas a mayusculas
	cp 061h		;899d   ; antes de la a?
	ret c			;899f
	cp 07bh		;89a0   ; despues de la z?
	ret nc			;89a2
	sub 020h		;89a3   ; a mayuscula
	ret			;89a5
lee_nombre:		; Lee tres letras en 0xEFD0 con CHGET: BS borra, RETURN acepta, ESC cancela (acarreo), punto = 0x3B
	push hl			;89a6
	ld b,003h		;89a7
	ld hl,0efd0h		;89a9
L_89AC:
	ld (hl),06bh		;89ac   ; tres huecos 0x6B
	inc hl			;89ae
	djnz L_89AC		;89af
	pop hl			;89b1
	ld de,0efd0h		;89b2
	xor a			;89b5
	ld (0efcfh),a		;89b6   ; letras escritas
L_89B9:
	push hl			;89b9
	push de			;89ba
	ex de,hl			;89bb
	ld hl,0efd0h		;89bc   ; nombre en curso
	call copia_tres		;89bf   ; a la pantalla
	pop de			;89c2
	pop hl			;89c3
L_89C4:
	call 0009fh		;89c4   ; BIOS CHGET - One character input (waiting)
	call mayusculas		;89c7
	cp 008h		;89ca   ; BS
	jr z,borra_letra		;89cc
	cp 00dh		;89ce   ; RETURN
	jr z,acepta_nombre		;89d0
	cp 01bh		;89d2   ; ESC
	jr z,L_8A19		;89d4
	cp 02eh		;89d6   ; punto
	jr z,L_89F1		;89d8
	cp 041h		;89da   ; solo letras A-Z
	jr c,L_89C4		;89dc
	cp 05bh		;89de
	jr nc,L_89C4		;89e0
L_89E2:
	ld (de),a			;89e2   ; letra
	ld a,(0efcfh)		;89e3   ; posicion
	cp 002h		;89e6   ; ya en la tercera
	jr z,L_89B9		;89e8
	inc a			;89ea   ; siguiente posicion
	inc de			;89eb
	ld (0efcfh),a		;89ec
	jr L_89B9		;89ef
L_89F1:
	ld a,03bh		;89f1
	jr L_89E2		;89f3
borra_letra:		; Retroceso en el nombre
	ld a,(0efcfh)		;89f5   ; posicion
	cp 002h		;89f8
	jr nz,L_8A0D		;89fa
	ld b,a			;89fc
	ld a,(de)			;89fd   ; letra de la tercera
	cp 06bh		;89fe   ; hueco?
	ld a,b			;8a00
	jr nz,L_8A08		;8a01
L_8A03:
	dec a			;8a03
	dec de			;8a04
	ld (0efcfh),a		;8a05
L_8A08:
	ld a,06bh		;8a08
	ld (de),a			;8a0a
	jr L_89B9		;8a0b
L_8A0D:
	and a			;8a0d
	jr z,L_89B9		;8a0e
	jr L_8A03		;8a10
acepta_nombre:		; RETURN solo con el nombre completo
	ld a,(de)			;8a12
	cp 06bh		;8a13
	jr z,L_89C4		;8a15
	xor a			;8a17
	ret			;8a18
L_8A19:
	scf			;8a19
	ret			;8a1a
edita_nombres:		; Edita los nombres de los ocho jugadores; izquierda/derecha cambian su aspecto
	ld a,(0efcdh)		;8a1b
	or 040h		;8a1e   ; vista de estadisticas
	ld (0efcdh),a		;8a20
	call rotulos_estadisticas		;8a23
L_8A26:
	ld bc,0b483h		;8a26
	call viste_jugador		;8a29
	xor a			;8a2c
	ld (0efcfh),a		;8a2d   ; posicion en el nombre
	call habilidades_y_estadisticas		;8a30
L_8A33:
	call pinta_nombres		;8a33
edita_elige:		; Selector de jugador con letras, BS, punto y cambio de aspecto
	ld hl,01942h		;8a36
	ld bc,008f9h		;8a39
	call selector		;8a3c
	ld a,c			;8a3f
	cp 01bh		;8a40   ; ESC: acaba
	ret z			;8a42
	cp 01eh		;8a43
	jr z,L_8A26		;8a45
	cp 01fh		;8a47
	jr z,L_8A26		;8a49
	cp 01ch		;8a4b   ; derecha: aspecto siguiente
	jr z,aspecto_siguiente		;8a4d
	cp 01dh		;8a4f   ; izquierda: aspecto anterior
	jr z,aspecto_anterior		;8a51
	cp 008h		;8a53   ; BS
	jr z,borra_letra_jugador		;8a55
	cp 02eh		;8a57   ; punto
	jr z,L_8A89		;8a59
	cp 041h		;8a5b   ; solo letras A-Z
	jr c,edita_elige		;8a5d
	cp 05bh		;8a5f
	jr nc,edita_elige		;8a61
L_8A63:
	push af			;8a63
	ld c,000h		;8a64
	call campo_jugador		;8a66
	ld a,(0efcfh)		;8a69
	and a			;8a6c
	jr nz,L_8A78		;8a6d   ; primera letra: borra el nombre
	ld b,008h		;8a6f
	push hl			;8a71
L_8A72:
	ld (hl),06bh		;8a72
	inc hl			;8a74
	djnz L_8A72		;8a75
	pop hl			;8a77
L_8A78:
	ld e,a			;8a78   ; posicion
	ld d,000h		;8a79
	add hl,de			;8a7b
	pop af			;8a7c
	ld (hl),a			;8a7d   ; letra en su sitio
	ld a,e			;8a7e
	cp 007h		;8a7f   ; ya en la octava
	jr z,L_8A33		;8a81
	inc a			;8a83   ; siguiente posicion
	ld (0efcfh),a		;8a84
	jr L_8A33		;8a87
L_8A89:
	ld a,03bh		;8a89
	jr L_8A63		;8a8b
aspecto_siguiente:		; Aspecto (campo 8) mas uno, de 0 a 31
	ld c,008h		;8a8d
	call campo_jugador		;8a8f
	ld a,(hl)			;8a92
	inc a			;8a93
L_8A94:
	and 01fh		;8a94
	ld (hl),a			;8a96
	jr L_8A26		;8a97
aspecto_anterior:		; Aspecto menos uno
	ld c,008h		;8a99
	call campo_jugador		;8a9b
	ld a,(hl)			;8a9e
	dec a			;8a9f
	jr L_8A94		;8aa0
borra_letra_jugador:		; Retroceso en el nombre del jugador
	ld c,000h		;8aa2
	call campo_jugador		;8aa4   ; nombre del jugador
	ld a,(0efcfh)		;8aa7   ; posicion
	ld e,a			;8aaa
	ld d,000h		;8aab
	add hl,de			;8aad
	cp 007h		;8aae   ; en la octava?
	jr nz,L_8AC3		;8ab0
	ld b,a			;8ab2
	ld a,(hl)			;8ab3   ; letra de la octava
	cp 06bh		;8ab4   ; hueco?
	ld a,b			;8ab6
	jr nz,L_8ABE		;8ab7
L_8AB9:
	dec a			;8ab9
	dec hl			;8aba
	ld (0efcfh),a		;8abb
L_8ABE:
	ld (hl),06bh		;8abe
	jp L_8A33		;8ac0
L_8AC3:
	and a			;8ac3
	jp z,L_8A33		;8ac4
	jr L_8AB9		;8ac7
selector:		; Selector de B opciones en la columna HL con el cursor C: arriba y abajo mueven (0xEFCD bits 0-5); devuelve en A y C cualquier otra tecla y en E la opcion
	ld a,(0efcdh)		;8ac9   ; bits 6-7 de 0xEFCD se conservan
	ld e,a			;8acc
	and 0c0h		;8acd
	ld d,a			;8acf
	ld a,e			;8ad0
	and 03fh		;8ad1
	ld e,a			;8ad3
	ld a,c			;8ad4
	exx			;8ad5
	ld c,a			;8ad6
	exx			;8ad7
	call pinta_cursor		;8ad8   ; pinta el cursor
	call 0009fh		;8adb   ; BIOS CHGET - One character input (waiting) | espera una tecla
	call mayusculas		;8ade
	ld c,a			;8ae1
	cp 01eh		;8ae2   ; arriba
	jr nz,L_8AEC		;8ae4
	inc e			;8ae6
	dec e			;8ae7
	ret z			;8ae8
	dec e			;8ae9
	jr L_8AF6		;8aea
L_8AEC:
	cp 01fh		;8aec   ; abajo
	ret nz			;8aee
	inc e			;8aef
	ld a,e			;8af0
	cp b			;8af1
	jr c,L_8AF6		;8af2
	dec e			;8af4
	ret			;8af5
L_8AF6:
	ld a,d			;8af6   ; opcion nueva
	or e			;8af7
	ld (0efcdh),a		;8af8   ; opcion nueva
	push bc			;8afb
	exx			;8afc
	ld a,c			;8afd   ; cursor
	exx			;8afe
	ld c,a			;8aff
	call pinta_cursor		;8b00   ; lo pinta
	pop bc			;8b03
	ld a,c			;8b04   ; A = tecla
	ret			;8b05
pinta_cursor:		; Borra la columna de B filas y pone el caracter C en la fila de la opcion
	push de			;8b06
	push hl			;8b07
	push hl			;8b08
	push bc			;8b09
	ld d,020h		;8b0a   ; espacios
	ld c,001h		;8b0c   ; columna de B filas
	call rellena_bloque		;8b0e   ; borra el cursor anterior
	pop bc			;8b11
	pop de			;8b12
	ld a,(0efcdh)		;8b13   ; opcion
	and 03fh		;8b16
	ld l,a			;8b18
	ld h,000h		;8b19
	add hl,hl			;8b1b   ; por 32: fila
	add hl,hl			;8b1c
	add hl,hl			;8b1d
	add hl,hl			;8b1e
	add hl,hl			;8b1f
	add hl,de			;8b20   ; columna del cursor
	ld a,c			;8b21   ; caracter del cursor
	call escribe_vram		;8b22
	pop hl			;8b25
	pop de			;8b26
	ret			;8b27
lee_disparo:		; NZ si se pulsa el espacio o el disparo de un joystick
	xor a			;8b28   ; espacio
	call 000d8h		;8b29   ; BIOS GTTRIG - Returns current trigger status
	and a			;8b2c
	ret nz			;8b2d
	ld a,001h		;8b2e   ; disparo del joystick 1
	call 000d8h		;8b30   ; BIOS GTTRIG - Returns current trigger status
	and a			;8b33
	ret nz			;8b34
	ld a,002h		;8b35   ; disparo del joystick 2
	call 000d8h		;8b37   ; BIOS GTTRIG - Returns current trigger status
	and a			;8b3a
	ret			;8b3b
colores_por_defecto_huerfano:		; Huerfano: pondria los colores de equipo de la primera pista
	ld hl,0785bh		;8b3c
	ld (hl),000h		;8b3f   ; SUPOSICION: COLOR OF COURT a 0 (escribe en la ROM)
	inc hl			;8b41
	ld a,(hl)			;8b42   ; color del izquierdo
	ld (0ea2ch),a		;8b43
	inc hl			;8b46
	ld a,(hl)			;8b47   ; color del derecho
	ld (0ea5ch),a		;8b48
	jp pinta_franjas		;8b4b
opcion_cero:		; Opcion 0 conservando el bit 7 (equipo)
	ld a,(0efcdh)		;8b4e
	and 080h		;8b51
	ld (0efcdh),a		;8b53
	ret			;8b56
panel_modo:		; Panel segun el modo: plantilla (0), READY-MADE (1) o COMPUTER TEAM (2) con su nivel
	call patrones_plantilla		;8b57
	call modo_equipo		;8b5a
	ld a,(hl)			;8b5d   ; modo 0: plantilla
	and a			;8b5e
	jr nz,L_8B6F		;8b5f
	ld hl,01902h		;8b61
	ld bc,00f1ch		;8b64
	ld d,020h		;8b67
	call rellena_bloque		;8b69
	jp L_7BAE		;8b6c
L_8B6F:
	cp 001h		;8b6f   ; modo 1: READY-MADE
	jr nz,L_8B81		;8b71
	ld d,0feh		;8b73
	call panel_nivel		;8b75
	ld hl,019abh		;8b78
	ld de,07d9ch		;8b7b
	jp imprime		;8b7e
L_8B81:
	ld d,0f0h		;8b81   ; modo 2: COMPUTER TEAM
	call panel_nivel		;8b83
	ld hl,019aah		;8b86
	ld de,07d8eh		;8b89
	jp imprime		;8b8c
panel_nivel:		; Fondo D, recuadro, LEVEL y el nivel del equipo
	ld hl,01902h		;8b8f   ; fondo D
	ld bc,00f1ch		;8b92
	call rellena_bloque		;8b95
	ld hl,01986h		;8b98   ; recuadro del nivel
	ld de,00413h		;8b9b
	call cuadro		;8b9e
	ld hl,019a7h		;8ba1   ; interior en blanco
	ld bc,00312h		;8ba4
	ld d,020h		;8ba7
	call rellena_bloque		;8ba9
	ld hl,019c7h		;8bac   ; linea
	ld bc,00012h		;8baf
	ld a,0f4h		;8bb2
	call rellena_vram		;8bb4
	ld hl,019edh		;8bb7   ; LEVEL
	ld de,07cc8h		;8bba
	call imprime		;8bbd
	ld c,003h		;8bc0   ; nivel (roster +3)
	call campo_cabecera		;8bc2
	ld a,(hl)			;8bc5   ; nivel
	add a,030h		;8bc6   ; en ASCII
	ld hl,019f3h		;8bc8
	jp escribe_vram		;8bcb
azar_r:		; Aleatorio mezclado con el registro R
	call aleatorio		;8bce   ; azar
	push bc			;8bd1
	ld b,a			;8bd2
	ld a,r		;8bd3   ; registro de refresco
	add a,b			;8bd5   ; mezcla
	pop bc			;8bd6
	ret			;8bd7
rotulo_half_time:		; HALF TIME en el marcador
	ld hl,08bf3h		;8bd8
	jr rotulo_dos_filas		;8bdb
rotulo_game_over:		; GAME OVER en el marcador
	ld hl,08bfdh		;8bdd
rotulo_dos_filas:		; Dos filas de cinco caracteres de HL en 0x182E
	call congela_sprites		;8be0
	ld de,0182eh		;8be3   ; fila 1, columna 14
	ld bc,00205h		;8be6   ; dos filas de cinco
	call copia_bloque		;8be9
	xor a			;8bec
	ld (0efdch),a		;8bed   ; sin repintar el tiempo
	jp suelta_sprites		;8bf0

; ----------------------------------------------------------------------
; DATOS rotulo_half_time: "HALF TIME." (diez caracteres, sin fin de cadena):
;   lo copia 0x8BD8
;   0x8bf3..0x8bfd  (10 bytes)
DATA_rotulo_half_time:
	defb 048h,041h,04ch,046h,020h,054h,049h,04dh,045h,03eh	; 8bf3  HALF TIME>

; ----------------------------------------------------------------------
; DATOS rotulo_game_over: "GAME OVER." (diez caracteres, sin fin de cadena):
;   lo copia 0x8BDD
;   0x8bfd..0x8c07  (10 bytes)
DATA_rotulo_game_over:
	defb 047h,041h,04dh,045h,020h,04fh,056h,045h,052h,03eh	; 8bfd  GAME OVER>

; ======================================================================
; CODIGO 0x8c07..0x8c21  (26 bytes)
; ======================================================================


push_any_key:		; PUSH ANY KEY en la fila 23
	call congela_sprites		;8c07
	ld hl,01ae0h		;8c0a   ; fila 23
	ld bc,00020h		;8c0d
	ld a,084h		;8c10   ; franja 0x84
	call rellena_vram		;8c12
	ld hl,01aeah		;8c15
	ld de,08c21h		;8c18   ; PUSH ANY KEY
	call imprime		;8c1b
	jp suelta_sprites		;8c1e

; ----------------------------------------------------------------------
; DATOS rotulo_push_any_key: "PUSH ANY KEY." acabado en cero: lo imprime
;   0x8C18
;   0x8c21..0x8c2f  (14 bytes)
DATA_rotulo_push_any_key:
	defb 050h,055h,053h,048h,020h,041h,04eh,059h,020h,04bh,045h,059h,03eh,000h	; 8c21  PUSH ANY KEY>.

; ======================================================================
; CODIGO 0x8c2f..0x8ed5  (678 bytes)
; ======================================================================


graba_equipo_sp:		; Entrada de SAVE DATA: guarda la pila en 0xEFDF (los errores de cinta vuelven aqui) y sigue en 0x8C33
	ld (0efdfh),sp		;8c2f   ; la pila, para abortar desde 0x8D1A

; ----------------------------------------------------------------------
; ===== La cinta: grabar, cargar y verificar el equipo =====
; ----------------------------------------------------------------------
graba_equipo:		; SAVE DATA: escribe en cinta el bloque HL..(0xF87D) con la cabecera de los binarios (diez 0xD0 y el nombre de 0xF866), las direcciones de inicio, fin y (0xFCBF), y los bytes uno a uno con TAPOUT; acarreo si falla
	push hl			;8c33   ; guarda el inicio del bloque
	ld a,0d0h		;8c34   ; 0xD0: la marca de los bloques BSAVE
	call graba_cabecera		;8c36   ; cabecera: motor, diez 0xD0 y los seis bytes del nombre
	xor a			;8c39   ; motor otra vez (TAPOON con A = 0: cabecera corta)
	call motor_escritura		;8c3a   ; TAPOON con A = 0: cabecera corta, la de los datos
	pop hl			;8c3d   ; HL = inicio
	push hl			;8c3e   ; lo guarda otra vez
	call graba_palabra		;8c3f   ; direccion de inicio (HL = el equipo, 0xE851 o 0xE93D)
	ld hl,(0f87dh)		;8c42   ; (0xF87D): direccion de fin, SAVEND de la BIOS; 0x878F la deja a HL + 0xEB
	push hl			;8c45   ; guarda el inicio
	call graba_palabra		;8c46   ; graba el fin
	ld hl,(0fcbfh)		;8c49   ; (0xFCBF): la direccion de ejecucion que lleva todo BSAVE
	call graba_palabra		;8c4c   ; graba la direccion de ejecucion
	pop de			;8c4f   ; DE = fin
	pop hl			;8c50   ; HL = inicio
L_8C51:
	ld a,(hl)			;8c51   ; un byte del equipo
	call graba_byte_cinta		;8c52   ; a la cinta
	rst 20h			;8c55   ; DCOMPR: HL contra DE (el fin)
	jr nc,L_8C5B		;8c56   ; HL >= DE: era el ultimo
	inc hl			;8c58   ; siguiente byte
	jr L_8C51		;8c59   ; otro mas
L_8C5B:
	call 000f0h		;8c5b   ; BIOS TAPOOF - Stops writing on the tape | TAPOOF: motor parado
	and a			;8c5e   ; sin acarreo: bien
	ret			;8c5f
graba_palabra:		; Los dos bytes de HL, el bajo primero (TAPOUT)
	ld a,l			;8c60   ; primero el byte bajo
	call graba_byte_cinta		;8c61
	ld a,h			;8c64   ; luego el alto
	jp graba_byte_cinta		;8c65
lee_palabra:		; HL = dos bytes de la cinta, el bajo primero (TAPIN)
	call lee_byte_cinta		;8c68   ; byte bajo
	ld l,a			;8c6b   ; a L
	call lee_byte_cinta		;8c6c   ; byte alto
	ld h,a			;8c6f   ; a H
	ret			;8c70
carga_equipo:		; LOAD DATA: busca la cabecera con el nombre del equipo, lee inicio y fin y vuelca los bytes en HL; acarreo si falla
	ld (0efdfh),sp		;8c71   ; guarda la pila: los errores de cinta vuelven aqui con 0x8D1D
	call lee_cabecera_bsave		;8c75   ; cabecera, nombre e inicio/fin: devuelve en DE el fin
L_8C78:
	call lee_byte_cinta		;8c78   ; un byte de la cinta
	ld (hl),a			;8c7b   ; un byte al equipo
	rst 20h			;8c7c   ; fin?
	jr z,L_8C82		;8c7d   ; HL = DE: era el ultimo
	inc hl			;8c7f   ; siguiente byte
	jr L_8C78		;8c80   ; otro mas
L_8C82:
	call 000e7h		;8c82   ; BIOS TAPIOF - Stops reading from the tape | TAPIOF
	and a			;8c85   ; sin acarreo: bien
	ret			;8c86
verifica_equipo:		; VERIFY: igual que la carga pero comparando cada byte con el que hay; acarreo si alguno no coincide
	ld (0efdfh),sp		;8c87   ; la pila, para abortar desde 0x8D1A
	call lee_cabecera_bsave		;8c8b   ; cabecera, inicio y fin (DE)
L_8C8E:
	call lee_byte_cinta		;8c8e   ; un byte de la cinta
	cp (hl)			;8c91   ; distinto: error
	jr nz,L_8C9F		;8c92   ; distinto: acarreo
	rst 20h			;8c94   ; HL contra DE
	jr z,L_8C9A		;8c95   ; era el ultimo
	inc hl			;8c97   ; siguiente byte
	jr L_8C8E		;8c98   ; otro mas
L_8C9A:
	call 000e7h		;8c9a   ; BIOS TAPIOF - Stops reading from the tape
	and a			;8c9d   ; sin acarreo: bien
	ret			;8c9e
L_8C9F:
	scf			;8c9f   ; acarreo: no coincide
	ret			;8ca0
lee_cabecera_bsave:		; Busca la cabecera (0x8CBD), lee inicio, fin y ejecucion y deja en DE el fin trasladado a HL (HL + fin - inicio)
	push hl			;8ca1   ; guarda el destino
	ld c,0d0h		;8ca2   ; la marca de los binarios
	call busca_cabecera		;8ca4   ; diez 0xD0 y el nombre
	call motor_lectura		;8ca7   ; el motor otra vez: el bloque de datos
	call lee_palabra		;8caa   ; inicio en HL
	ex de,hl			;8cad   ; DE = inicio
	call lee_palabra		;8cae   ; fin en DE
	and a			;8cb1   ; sin acarreo para la resta
	sbc hl,de		;8cb2   ; longitud = fin - inicio
	pop de			;8cb4   ; DE = destino
	add hl,de			;8cb5   ; fin relativo al destino
	push hl			;8cb6   ; guarda el fin relativo
	call lee_palabra		;8cb7   ; la direccion de ejecucion, que no se usa
	ex de,hl			;8cba   ; DE = ejecucion (se tira)
	pop de			;8cbb   ; DE = fin relativo
	ret			;8cbc
busca_cabecera:		; TAPION y diez bytes seguidos iguales a C, luego los seis del nombre a 0xF866: tienen que acabar en tres 0x7F (0x87CD) o se sigue buscando
	call motor_lectura		;8cbd   ; TAPION: busca una cabecera
	ld b,00ah		;8cc0   ; diez marcas seguidas
L_8CC2:
	call lee_byte_cinta		;8cc2   ; un byte
	cp c			;8cc5   ; otra cosa: vuelve a empezar
	jr nz,busca_cabecera		;8cc6   ; no es la marca: otra cabecera
	djnz L_8CC2		;8cc8   ; diez seguidas
	ld hl,0f866h		;8cca   ; FILNAM: los seis bytes del nombre
	ld b,006h		;8ccd   ; seis bytes de nombre
L_8CCF:
	call lee_byte_cinta		;8ccf   ; un byte
	ld (hl),a			;8cd2   ; a FILNAM
	inc hl			;8cd3   ; siguiente
	djnz L_8CCF		;8cd4   ; los seis
	ld b,003h		;8cd6   ; los tres ultimos tienen que ser 0x7F
L_8CD8:
	dec hl			;8cd8   ; el ultimo, el penultimo, el antepenultimo
	ld a,(hl)			;8cd9   ; un byte del nombre
	cp 07fh		;8cda   ; es 0x7F?
	jr nz,busca_cabecera		;8cdc   ; no: no es un equipo, otra cabecera
	djnz L_8CD8		;8cde   ; los tres
	jp pinta_encontrado		;8ce0   ; ensena el nombre encontrado (FOUND:)
graba_cabecera:		; Motor (TAPOON), diez veces A y los seis bytes del nombre de 0xF866
	call motor_escritura		;8ce3   ; TAPOON
	ld b,00ah		;8ce6   ; diez marcas
L_8CE8:
	call graba_byte_cinta		;8ce8   ; diez marcas
	djnz L_8CE8		;8ceb   ; las diez
	ld b,006h		;8ced   ; seis bytes de nombre
	ld hl,0f866h		;8cef   ; FILNAM
L_8CF2:
	ld a,(hl)			;8cf2   ; un byte del nombre
	inc hl			;8cf3   ; siguiente
	call graba_byte_cinta		;8cf4   ; a la cinta
	djnz L_8CF2		;8cf7   ; los seis
	jp 000f0h		;8cf9   ; BIOS TAPOOF - Stops writing on the tape
lee_byte_cinta:		; TAPIN guardando los registros; si falla, aborta la operacion (0x8D1A)
	push hl			;8cfc   ; guarda los registros
	push de			;8cfd
	push bc			;8cfe
	call 000e4h		;8cff   ; BIOS TAPIN - Reads data from the tape
	jr nc,L_8D2B		;8d02   ; bien: a recuperarlos (0x8D2B)
	jr error_de_cinta		;8d04   ; mal: abortar
graba_byte_cinta:		; TAPOUT guardando los registros; si falla, aborta
	push hl			;8d06   ; guarda los registros
	push de			;8d07
	push bc			;8d08
	push af			;8d09
	call 000edh		;8d0a   ; BIOS TAPOUT - Writes data on the tape
	jr nc,L_8D2A		;8d0d   ; bien: a recuperarlos
	jr error_de_cinta		;8d0f   ; mal: abortar
motor_lectura:		; TAPION guardando los registros; si falla, aborta
	push hl			;8d11   ; guarda los registros
	push de			;8d12
	push bc			;8d13
	push af			;8d14
	call 000e1h		;8d15   ; BIOS TAPION - Reads the header block after turning the cassette motor on
	jr nc,L_8D2A		;8d18   ; bien: a recuperarlos
error_de_cinta:		; TAPIOF, recupera la pila guardada en 0xEFDF y vuelve con acarreo al que llamo a cargar o grabar
	call 000e7h		;8d1a   ; BIOS TAPIOF - Stops reading from the tape
	ld sp,(0efdfh)		;8d1d   ; (0xEFDF): la pila de 0x8C71 / 0x8C87
	scf			;8d21   ; acarreo: fallo
	ret			;8d22
motor_escritura:		; TAPOON guardando los registros
	push hl			;8d23   ; guarda los registros
	push de			;8d24
	push bc			;8d25
	push af			;8d26
	call 000eah		;8d27   ; BIOS TAPOON - Turns on the cassette motor and writes the header
L_8D2A:
	pop af			;8d2a   ; los recupera
L_8D2B:
	pop bc			;8d2b
	pop de			;8d2c
	pop hl			;8d2d
	ret			;8d2e
sonido_apagado:		; Pieza ninguna (0xFF) y contador a cero: lo llama INIT
	xor a			;8d2f   ; A = 0
	ld (0efe6h),a		;8d30   ; (0xEFE6): cuadros que faltan para la ficha siguiente
	dec a			;8d33   ; A = 0xFF
	ld (0efe1h),a		;8d34   ; (0xEFE1): pieza que suena, (0xEFE7): su prioridad; 0xFF = ninguna
	ld (0efe7h),a		;8d37   ; prioridad ninguna
	ret			;8d3a
huerfano_espera_sonido:		; Huerfano: espera a que se acabe el sonido en curso
	ld a,(0efe6h)		;8d3b
	and a			;8d3e   ; suena algo?
	jr nz,huerfano_espera_sonido		;8d3f   ; si: sigue esperando
	ret			;8d41

; ----------------------------------------------------------------------
; ===== El motor de sonido: arrancar una pieza, el tick y el interprete =====
; ----------------------------------------------------------------------
arranca_sonido:		; Pide la pieza A (0-12) guardando los registros: si no es de prioridad menor que la que suena, la pone en marcha
	push af			;8d42   ; guarda todos los registros
	push bc			;8d43
	push de			;8d44
	push hl			;8d45
	call arranca_sonido_a		;8d46   ; la de verdad
	pop hl			;8d49   ; y los recupera
	pop de			;8d4a
	pop bc			;8d4b
	pop af			;8d4c
	ret			;8d4d
arranca_sonido_a:		; A negativo: nada. Compara la prioridad (0x8F71) con la de la pieza en curso; con 0x1E o mas no se repite la misma pieza
	and a			;8d4e   ; pieza negativa?
	ret m			;8d4f   ; si: nada
	ld e,a			;8d50   ; E = pieza
	ld c,e			;8d51   ; BC = pieza
	ld b,000h		;8d52
	ld hl,08f71h		;8d54   ; 0x8F71: prioridad de cada pieza
	add hl,bc			;8d57   ; HL = su prioridad
	ld a,(0efe7h)		;8d58   ; (0xEFE7): prioridad de la que suena (0xFF si ninguna)
	cp (hl)			;8d5b   ; menor que la actual: no entra
	ret c			;8d5c   ; menor que la que suena: no
	ld a,(hl)			;8d5d   ; A = prioridad de la nueva
	ld (0efe7h),a		;8d5e   ; ya es la que suena
	cp 01eh		;8d61   ; prioridad 30 o mas: si ya suena esa misma pieza no se reinicia
	jr c,L_8D6C		;8d63   ; menos de 30: entra siempre (0x8D6C)
	jr nc,L_8D67		;8d65   ; 30 o mas: mira si es la misma
L_8D67:
	ld a,(0efe1h)		;8d67   ; la pieza que suena
	cp e			;8d6a   ; es la misma?
	ret z			;8d6b   ; si: no se reinicia
L_8D6C:
	ld a,e			;8d6c   ; A = pieza
	ld (0efe1h),a		;8d6d   ; (0xEFE1): la pieza en curso
	add a,a			;8d70   ; dos bytes por puntero
	ld c,a			;8d71   ; BC = desplazamiento
	ld hl,08f57h		;8d72   ; 0x8F57: los trece punteros
	add hl,bc			;8d75   ; HL = su puntero
	ld e,(hl)			;8d76   ; E = byte bajo
	inc hl			;8d77
	ld d,(hl)			;8d78   ; D = byte alto
	di			;8d79   ; sin interrupciones mientras se cambia
	ld (0efe2h),de		;8d7a   ; (0xEFE2): puntero a la ficha siguiente
	ld hl,0f007h		;8d7e   ; (0xEFE4): la pila propia de las llamadas, que crece hacia abajo desde 0xF007
	ld (0efe4h),hl		;8d81   ; pila propia vacia
	ld a,001h		;8d84   ; un cuadro y empieza
	ld (0efe6h),a		;8d86   ; un cuadro de espera
	ei			;8d89   ; interrupciones otra vez
	ret			;8d8a
tick_sonido:		; Cada cuadro: si no suena nada marca 0xFF; si no, descuenta y al llegar a cero interpreta fichas hasta la siguiente espera
	ld hl,0efe6h		;8d8b   ; HL = contador
	ld a,(hl)			;8d8e   ; A = cuadros que faltan
	and a			;8d8f   ; cero: nada suena
	jr nz,L_8D9B		;8d90   ; queda espera
	ld a,0ffh		;8d92   ; nada sonando: pieza y prioridad a 0xFF
	ld (0efe7h),a		;8d94   ; prioridad ninguna
	ld (0efe1h),a		;8d97   ; pieza ninguna
	ret			;8d9a
L_8D9B:
	dec (hl)			;8d9b   ; todavia esperando
	ret nz			;8d9c   ; todavia no
	ld hl,(0efe2h)		;8d9d   ; HL = ficha siguiente, IX = la pila
	ld ix,(0efe4h)		;8da0   ; IX = la pila propia
	call interpreta_ficha		;8da4   ; interpreta hasta una espera: A = cuadros
	ld (0efe6h),a		;8da7   ; cuadros hasta la siguiente ficha
	ld (0efe2h),hl		;8daa   ; puntero nuevo
	ld (0efe4h),ix		;8dad   ; pila nueva
	ret			;8db1
interpreta_ficha:		; Lee fichas desde HL hasta dar con una espera; devuelve en A los cuadros (0 acaba la pieza) y en HL la siguiente
	ld a,(hl)			;8db2   ; bits 7-6 a cero: no es nota
	and 0c0h		;8db3   ; bits 7 y 6: el canal
	jr z,L_8DD7		;8db5   ; cero: no es nota
	rlca			;8db7   ; canal = (ficha >> 6) - 1, por dos: el registro del periodo
	rlca			;8db8   ; canal en los bits 1-0
	dec a			;8db9   ; 1-3 -> 0-2
	add a,a			;8dba   ; por dos: registros 0/1, 2/3, 4/5
	push af			;8dbb   ; guarda el registro
	ld a,(hl)			;8dbc   ; indice de nota (0-63)
	and 03fh		;8dbd   ; indice de la nota
	add a,a			;8dbf   ; dos bytes por periodo
	exx			;8dc0   ; registros alternativos para no perder HL
	ld b,000h		;8dc1   ; BC = desplazamiento
	ld c,a			;8dc3   ; bajo
	ld hl,08ed5h		;8dc4   ; 0x8ED5: los 64 periodos de 16 bits
	add hl,bc			;8dc7   ; HL = el periodo
	ld e,(hl)			;8dc8   ; E = byte bajo del periodo
	pop af			;8dc9   ; A = registro
	call 00093h		;8dca   ; BIOS WRTPSG - Writes data to PSG-register | registro bajo del periodo
	inc a			;8dcd   ; registro alto
	inc hl			;8dce   ; byte alto del periodo
	ld e,(hl)			;8dcf   ; E = byte alto
	call 00093h		;8dd0   ; BIOS WRTPSG - Writes data to PSG-register | registro alto
	exx			;8dd3   ; HL de vuelta
	inc hl			;8dd4   ; ficha siguiente
	jr interpreta_ficha		;8dd5   ; y otra ficha: la nota no espera
L_8DD7:
	ld a,(hl)			;8dd7   ; bit 5 a cero: 0x00-0x1F, una espera
	and 020h		;8dd8   ; bit 5?
	jr nz,L_8DE6		;8dda   ; a uno: orden o registro
	ld a,(hl)			;8ddc   ; A = la espera
	cp 01fh		;8ddd   ; 0x1F: la espera vale lo que diga (0xEFE8)
	jr nz,L_8DE4		;8ddf   ; no es 0x1F: tal cual
	ld a,(0efe8h)		;8de1   ; (0xEFE8): el tempo
L_8DE4:
	inc hl			;8de4   ; ficha siguiente
	ret			;8de5   ; vuelve con los cuadros en A
L_8DE6:
	ld a,(hl)			;8de6   ; A = la ficha
	bit 4,a		;8de7   ; bit 4: 0x30-0x3F, ordenes
	jr nz,L_8E07		;8de9   ; bit 4 a uno: 0x30-0x3F
	and 00fh		;8deb   ; 0x20-0x2F: registro del PSG
	cp 006h		;8ded   ; 0x20-0x25: el mezclador (registro 7) con un valor de 0x8F55
	jr nc,L_8DFF		;8def   ; 6 o mas: registro directo (0x8DFF)
	push hl			;8df1   ; guarda el puntero
	ld hl,08f55h		;8df2   ; 0x8F55: los valores del registro 7
	ld e,a			;8df5   ; DE = indice
	ld d,000h		;8df6
	add hl,de			;8df8   ; HL = el valor
	ld e,(hl)			;8df9   ; E = valor del mezclador
	pop hl			;8dfa   ; recupera el puntero
	ld a,007h		;8dfb   ; registro 7
	jr L_8E01		;8dfd   ; a escribirlo
L_8DFF:
	inc hl			;8dff   ; 0x26-0x2F: el registro del nibble bajo con el byte siguiente
	ld e,(hl)			;8e00   ; E = el byte siguiente
L_8E01:
	call 00093h		;8e01   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;8e04   ; ficha siguiente
	jr interpreta_ficha		;8e05   ; y otra ficha
L_8E07:
	cp 03dh		;8e07   ; 0x3D: silencio
	jr nz,L_8E1A		;8e09   ; no es 0x3D
	ld e,000h		;8e0b   ; E = 0: el valor
	ld a,000h		;8e0d   ; A = 0: el primer registro
	ld b,006h		;8e0f   ; seis registros
L_8E11:
	call 00093h		;8e11   ; BIOS WRTPSG - Writes data to PSG-register | registros 0-5 a cero
	inc a			;8e14   ; registro siguiente
	djnz L_8E11		;8e15   ; los seis
	inc hl			;8e17   ; ficha siguiente
	jr interpreta_ficha		;8e18   ; y otra ficha
L_8E1A:
	cp 033h		;8e1a   ; 0x33: salto a la direccion que sigue
	jr nz,L_8E25		;8e1c   ; no es 0x33
	inc hl			;8e1e   ; el byte bajo del destino
	ld e,(hl)			;8e1f   ; E = bajo
	inc hl			;8e20   ; el alto
	ld d,(hl)			;8e21   ; D = alto
	ex de,hl			;8e22   ; HL = destino
	jr interpreta_ficha		;8e23   ; sigue alli
L_8E25:
	cp 034h		;8e25   ; 0x34: llamada; apila la vuelta en IX
	jr nz,L_8E3C		;8e27   ; no es 0x34
	inc hl			;8e29   ; el byte bajo del destino
	ld e,(hl)			;8e2a   ; E = bajo
	inc hl			;8e2b   ; el alto
	ld d,(hl)			;8e2c   ; D = alto
	inc hl			;8e2d   ; HL = la vuelta
	ld (ix-001h),h		;8e2e   ; vuelta alta a la pila propia
	ld (ix-002h),l		;8e31   ; vuelta baja
	dec ix		;8e34   ; la pila baja dos
	dec ix		;8e36
	ex de,hl			;8e38   ; HL = destino
	jp interpreta_ficha		;8e39   ; sigue alli
L_8E3C:
	cp 035h		;8e3c   ; 0x35: vuelta de la llamada
	jr nz,L_8E4D		;8e3e   ; no es 0x35
	inc ix		;8e40   ; la pila sube dos
	inc ix		;8e42
	ld h,(ix-001h)		;8e44   ; H = vuelta alta
	ld l,(ix-002h)		;8e47   ; L = vuelta baja
	jp interpreta_ficha		;8e4a   ; sigue en la vuelta
L_8E4D:
	cp 036h		;8e4d   ; 0x36: abre un bucle; apila el puntero y la cuenta (0x1F = el tempo)
	jr nz,L_8E6D		;8e4f   ; no es 0x36
	inc hl			;8e51   ; el byte de la cuenta
	ld a,(hl)			;8e52   ; A = cuenta
	cp 01fh		;8e53   ; cuenta 0x1F: la de (0xEFE8)
	jr nz,L_8E5A		;8e55   ; no es 0x1F: tal cual
	ld a,(0efe8h)		;8e57   ; cuenta = el tempo
L_8E5A:
	inc hl			;8e5a   ; HL = primera ficha del bucle
	ld (ix-001h),h		;8e5b   ; puntero alto a la pila propia
	ld (ix-002h),l		;8e5e   ; puntero bajo
	ld (ix-003h),a		;8e61   ; y la cuenta
	dec ix		;8e64   ; la pila baja tres
	dec ix		;8e66
	dec ix		;8e68
	jp interpreta_ficha		;8e6a   ; sigue dentro del bucle
L_8E6D:
	cp 037h		;8e6d   ; 0x37: cierra el bucle; una vuelta menos, y si quedan salta al principio
	jr nz,L_8E89		;8e6f   ; no es 0x37
	dec (ix+000h)		;8e71   ; (IX+0): la cuenta
	jr z,L_8E7F		;8e74   ; cero: se acabo el bucle
	ld l,(ix+001h)		;8e76   ; L = puntero bajo
	ld h,(ix+002h)		;8e79   ; H = puntero alto
	jp interpreta_ficha		;8e7c   ; otra vuelta
L_8E7F:
	inc ix		;8e7f   ; cuenta agotada: saca los tres bytes y sigue
	inc ix		;8e81   ; la pila sube tres
	inc ix		;8e83
	inc hl			;8e85   ; ficha siguiente
	jp interpreta_ficha		;8e86   ; sigue detras del bucle
L_8E89:
	bit 3,a		;8e89   ; bit 3 a cero: 0x30, 0x32, 0x3C, deslizamiento de tono
	jr nz,L_8EAC		;8e8b   ; a uno: deslizamiento (0x8EAC)
	and 003h		;8e8d   ; 0x38-0x3B: volumen del canal (bits 1-0)
	add a,008h		;8e8f   ; registros 8-10
	push af			;8e91   ; guarda el registro
	call 00096h		;8e92   ; BIOS RDPSG - Reads value from PSG-register | el volumen actual
	and 01fh		;8e95   ; volumen 0-15
	inc hl			;8e97   ; el byte del cambio
	add a,(hl)			;8e98   ; mas el byte siguiente, con signo
	jp p,L_8E9D		;8e99   ; negativo: cero
	xor a			;8e9c   ; negativo: cero
L_8E9D:
	cp 011h		;8e9d   ; tope de 16
	jr c,L_8EA3		;8e9f   ; menos de 17: vale
	ld a,010h		;8ea1   ; 17 o mas: 16
L_8EA3:
	ld e,a			;8ea3   ; E = volumen nuevo
	pop af			;8ea4   ; A = registro
	call 00093h		;8ea5   ; BIOS WRTPSG - Writes data to PSG-register
	inc hl			;8ea8   ; ficha siguiente
	jp interpreta_ficha		;8ea9   ; y otra ficha
L_8EAC:
	and 006h		;8eac   ; registro del periodo: 0, 2 o 4
	ld c,a			;8eae   ; C = registro bajo del periodo
	call 00096h		;8eaf   ; BIOS RDPSG - Reads value from PSG-register | periodo actual, bajo
	ld e,a			;8eb2   ; E = periodo bajo
	ld a,c			;8eb3   ; A = registro
	inc a			;8eb4   ; el alto
	call 00096h		;8eb5   ; BIOS RDPSG - Reads value from PSG-register | y alto
	ld d,a			;8eb8   ; D = periodo alto
	inc hl			;8eb9   ; el byte del desplazamiento
	push hl			;8eba   ; guarda el puntero
	ld a,(hl)			;8ebb   ; el desplazamiento, con signo
	ld h,000h		;8ebc   ; H = 0
	and a			;8ebe   ; signo del desplazamiento
	jp p,L_8EC3		;8ebf   ; positivo
	dec h			;8ec2   ; negativo: H = 0xFF
L_8EC3:
	ld l,a			;8ec3   ; HL = desplazamiento con signo
	add hl,de			;8ec4   ; periodo nuevo
	ex de,hl			;8ec5   ; DE = periodo nuevo
	pop hl			;8ec6   ; recupera el puntero
	ld a,c			;8ec7   ; A = registro bajo
	call 00093h		;8ec8   ; BIOS WRTPSG - Writes data to PSG-register | bajo
	ld a,c			;8ecb   ; A = registro bajo
	inc a			;8ecc   ; el alto
	ld e,d			;8ecd   ; E = periodo alto
	call 00093h		;8ece   ; BIOS WRTPSG - Writes data to PSG-register | alto
	inc hl			;8ed1   ; ficha siguiente
	jp interpreta_ficha		;8ed2   ; y otra ficha

; ----------------------------------------------------------------------
; DATOS notas: 64 periodos de 16 bits del PSG: la ficha de nota 0x40-0xFF del
;   motor de sonido escribe en los registros del canal el periodo de indice
;   (ficha & 0x3F)
;   0x8ed5..0x8f55  (128 bytes)
DATA_notas:
	defw 006aeh,0064eh,005f3h,0059eh,0054dh,00501h,004b9h,00475h	; 8ed5
	defw 00435h,003f1h,003c0h,0038ah,00357h,00327h,002f9h,002cfh	; 8ee5
	defw 002a6h,00280h,0025ch,0023ah,0021ah,001f8h,001e0h,001c5h	; 8ef5
	defw 001abh,00193h,0017ch,00167h,00153h,00140h,0012eh,0011dh	; 8f05
	defw 0010dh,000fch,000f0h,000e2h,000d5h,000c9h,000beh,000b3h	; 8f15
	defw 000a9h,000a0h,00097h,0008eh,00086h,0007eh,00078h,00071h	; 8f25
	defw 0006ah,00064h,0005fh,00059h,00054h,00035h,0004bh,00047h	; 8f35
	defw 00043h,0003fh,0002ah,00028h,00021h,0001fh,0001eh,00000h	; 8f45

; ----------------------------------------------------------------------
; DATOS mezclador: Los dos valores del registro 7 (0xB8 tono en los tres
;   canales, 0xA8 ruido en el C) que escriben las fichas 0x20 y 0x21
;   0x8f55..0x8f57  (2 bytes)
DATA_mezclador:
	defb 0b8h,0a8h	; 8f55

; ----------------------------------------------------------------------
; DATOS piezas: Punteros a las trece piezas de sonido (la 1 y la 8 son la
;   misma, la 4, 5 y 6 tambien): 0x8D42 arranca la de indice A si su prioridad
;   lo permite
;   0x8f57..0x8f71  (26 bytes)
DATA_piezas:
	defw 08f7eh	; 8f57  -> DATA_pieza_00
	defw 08fc8h	; 8f59  -> DATA_pieza_01
	defw 095cbh	; 8f5b  -> DATA_pieza_02
	defw 08f80h	; 8f5d  -> DATA_pieza_03
	defw 08f8dh	; 8f5f  -> DATA_pieza_04
	defw 08f8dh	; 8f61  -> DATA_pieza_04
	defw 08f8dh	; 8f63  -> DATA_pieza_04
	defw 08fa2h	; 8f65  -> DATA_pieza_07
	defw 08fc8h	; 8f67  -> DATA_pieza_01
	defw 09002h	; 8f69  -> DATA_pieza_09
	defw 09021h	; 8f6b  -> DATA_pieza_10
	defw 093d7h	; 8f6d  -> DATA_pieza_11
	defw 0954ch	; 8f6f  -> DATA_pieza_12

; ----------------------------------------------------------------------
; DATOS prioridad_piezas: Prioridad de cada una de las trece piezas: 0x8D54 no
;   arranca una pieza de prioridad menor que la que suena
;   0x8f71..0x8f7e  (13 bytes)
DATA_prioridad_piezas:
	defb 005h,00ch,00fh,00ah,014h,014h,00ah,019h,00ch,019h,00ah,00ah,00ah	; 8f71  .............

; ----------------------------------------------------------------------
; DATOS pieza_00: Pieza 0: una espera y el fin (dos bytes)
;   0x8f7e..0x8f80  (2 bytes)
DATA_pieza_00:
	defb 03dh,000h	; 8f7e

; ----------------------------------------------------------------------
; DATOS pieza_03: Pieza 3 (13 bytes)
;   0x8f80..0x8f8d  (13 bytes)
DATA_pieza_03:
	defb 020h,028h,00fh,029h,00fh,02ah,00fh,07bh,0bch,0fdh,01eh,03dh,000h	; 8f80   (.).*.{...=.

; ----------------------------------------------------------------------
; DATOS pieza_04: Pieza 4, 5 y 6 (el mismo puntero con tres prioridades, 20,
;   20 y 10; 21 bytes)
;   0x8f8d..0x8fa2  (21 bytes)
DATA_pieza_04:
	defb 020h,028h,00fh,029h,00dh,02ah,00eh,036h,010h,05eh,09eh,0deh,002h,03ah,004h,03ch,0fch,002h,037h,03dh,000h	; 8f8d   (.).*.6.^...:.<..7=.

; ----------------------------------------------------------------------
; DATOS pieza_07: Pieza 7 (38 bytes)
;   0x8fa2..0x8fc8  (38 bytes)
DATA_pieza_07:
	defb 027h,0bch,028h,00fh,029h,00dh,050h,001h,07fh,090h,001h,051h,0bfh,001h,07fh,091h,001h,052h,0bfh	; 8fa2  '.(.).P....Q.....R.
	defb 001h,07fh,092h,001h,03ah,003h,058h,098h,002h,036h,010h,030h,0ffh,031h,0ffh,002h,037h,03dh,000h	; 8fb5  ....:.X..6.0.1..7=.

; ----------------------------------------------------------------------
; DATOS pieza_01: Pieza 1 y 8 (la musica): llama con 0x34 a las frases de
;   0x95DF, 0x963E, 0x95FA y 0x961F y salta en 0x8FFF a 0x95CE, el bucle que
;   comparte con la pieza 2
;   0x8fc8..0x9002  (58 bytes)
DATA_pieza_01:
	defb 027h,080h,026h,006h,028h,00fh,029h,00fh,02ah,00fh,063h,0a0h,0dch,002h,026h,003h	; 8fc8  '.&.(.).*.c...&.
	defb 062h,09fh,0dbh,002h,020h,05eh,09bh,0d7h,002h,05ah,097h,0d3h,002h,054h,091h,0cdh	; 8fd8  b... ^...Z...T..
	defb 001h,04ah,087h,0c3h,001h,034h,0dfh,095h,034h,03eh,096h,034h,03eh,096h,036h,004h	; 8fe8  .J...4..4>.4>.6.
	defb 034h,0fah,095h,037h,034h,01fh,096h,033h,0ceh,095h	; 8ff8  4..74..3..

; ----------------------------------------------------------------------
; DATOS pieza_09: Pieza 9 (31 bytes)
;   0x9002..0x9021  (31 bytes)
DATA_pieza_09:
	defb 027h,0bch,028h,00bh,029h,009h,045h,084h,001h,046h,087h,001h,028h,00fh,029h,00dh	; 9002  '.(.).E..F..(.).
	defb 036h,004h,030h,0feh,031h,0feh,04dh,0bfh,002h,07fh,08ch,001h,037h,03dh,000h	; 9012  6.0.1.M.....7=.

; ----------------------------------------------------------------------
; DATOS pieza_10: Pieza 10 (950 bytes): el salto de 0x93D4 vuelve a 0x9038
;   0x9021..0x93d7  (950 bytes)
DATA_pieza_10:
	defb 020h,028h,010h,029h,010h,02ah,00eh,02ch,032h,026h,003h,02dh,000h,058h,095h,0c5h	; 9021   (.).*.,2&.-.X..
	defb 006h,0ffh,006h,0d5h,006h,0ffh,006h,021h,0c0h,006h,020h,03dh,006h,02dh,000h,05dh	; 9031  .......!.. =.-.]
	defb 095h,0d5h,006h,0ffh,006h,0c5h,006h,0ffh,006h,0d5h,006h,0ffh,006h,021h,028h,00fh	; 9041  .............!(.
	defb 029h,00dh,062h,098h,0c0h,006h,020h,061h,0ffh,006h,05fh,0d5h,006h,0ffh,006h,028h	; 9051  ).b... a.._....(
	defb 010h,029h,010h,02ch,032h,02dh,000h,061h,098h,0c5h,006h,0ffh,006h,0d5h,006h,0ffh	; 9061  .).,2-.a........
	defb 006h,021h,0c0h,006h,020h,0ffh,006h,02dh,000h,09dh,00ch,0c5h,006h,0ffh,006h,021h	; 9071  .!.. ..-.......!
	defb 0c0h,005h,020h,0ffh,007h,021h,0c5h,005h,020h,0ffh,007h,021h,0c7h,005h,020h,0ffh	; 9081  .. ..!.. ..!.. .
	defb 007h,02dh,000h,02ch,032h,058h,093h,0c8h,006h,0ffh,006h,0d4h,006h,0ffh,006h,021h	; 9091  .-.,2X.........!
	defb 0c3h,006h,020h,0ffh,006h,02dh,000h,05dh,098h,0d4h,006h,0ffh,006h,0c8h,006h,0ffh	; 90a1  .. ..-.]........
	defb 006h,0d4h,006h,0ffh,006h,021h,02dh,000h,062h,098h,0c3h,006h,020h,061h,0ffh,006h	; 90b1  .....!-.b... a..
	defb 05fh,0d4h,006h,0ffh,006h,02dh,000h,064h,098h,0c8h,006h,0ffh,006h,0d4h,006h,0ffh	; 90c1  _....-.d........
	defb 006h,021h,0c3h,006h,020h,0ffh,006h,0d4h,006h,0ffh,006h,0c8h,00ch,02dh,000h,021h	; 90d1  .!.. ........-.!
	defb 05fh,098h,006h,020h,0cfh,006h,02dh,000h,060h,098h,006h,021h,05fh,006h,020h,060h	; 90e1  _.. ..-.`..!_. `
	defb 0c8h,006h,062h,006h,028h,00fh,029h,00dh,036h,002h,021h,064h,09ah,0c7h,003h,020h	; 90f1  ..b.(.).6.!d... 
	defb 03dh,003h,037h,021h,064h,09dh,0d6h,003h,020h,03dh,009h,0d6h,00ch,021h,028h,010h	; 9101  =.7!d... =...!(.
	defb 029h,010h,02ch,028h,02dh,000h,064h,09ch,0cch,006h,020h,00ch,0ffh,006h,028h,00fh	; 9111  ).,(-.d... ...(.
	defb 029h,00dh,05fh,00ch,060h,006h,05fh,006h,060h,006h,062h,006h,036h,002h,021h,064h	; 9121  )._.`._.`.b.6.!d
	defb 09fh,0c3h,003h,020h,03dh,003h,037h,021h,064h,09ah,0cfh,003h,020h,03dh,009h,0cfh	; 9131  ... =.7!d... =..
	defb 00ch,021h,028h,010h,029h,010h,02ch,028h,02dh,000h,064h,09fh,0c8h,006h,020h,00ch	; 9141  .!(.).,(-.d... .
	defb 03dh,006h,028h,00fh,029h,00dh,05fh,00ch,060h,006h,05fh,006h,060h,006h,062h,006h	; 9151  =.(.)._.`._.`.b.
	defb 036h,002h,021h,064h,09ah,0c7h,003h,020h,03dh,003h,037h,021h,064h,09dh,0d6h,003h	; 9161  6.!d... =.7!d...
	defb 020h,03dh,009h,0d3h,006h,0c7h,006h,028h,010h,029h,010h,02ch,028h,02dh,000h,064h	; 9171   =.....(.).,(-.d
	defb 09ch,0cch,012h,03dh,006h,021h,028h,00fh,029h,00dh,05fh,09ch,0d6h,006h,020h,03dh	; 9181  ...=.!(.)._... =
	defb 006h,060h,09ch,006h,021h,062h,0cch,006h,020h,006h,03dh,006h,028h,010h,029h,010h	; 9191  .`..!b.. .=.(.).
	defb 02ch,028h,02dh,000h,062h,098h,0c5h,006h,07fh,0bfh,006h,02ch,014h,02dh,000h,060h	; 91a1  ,(-.b......,.-.`
	defb 09bh,006h,021h,07fh,0bfh,0d4h,006h,020h,02dh,000h,05fh,08fh,006h,02dh,000h,060h	; 91b1  ..!.... -._..-.`
	defb 0ffh,006h,021h,0c5h,006h,020h,006h,021h,02dh,000h,05fh,09bh,0cbh,006h,020h,07fh	; 91c1  ..!.. .!-._... .
	defb 0bfh,006h,02dh,000h,05dh,097h,0ffh,006h,021h,07fh,0bfh,0d4h,006h,020h,02dh,000h	; 91d1  ..-.]...!.... -.
	defb 05bh,098h,006h,02dh,000h,05dh,094h,006h,021h,0cah,006h,020h,006h,02ch,032h,02dh	; 91e1  [..-.]..!.. .,2-
	defb 000h,056h,093h,0c3h,006h,0ffh,006h,036h,002h,0c3h,003h,0ffh,003h,037h,021h,0cfh	; 91f1  .V.....6.....7!.
	defb 003h,020h,0ffh,003h,0c3h,003h,0ffh,003h,02dh,000h,021h,05bh,093h,0cfh,006h,020h	; 9201  . ......-.![... 
	defb 006h,0c3h,00ch,0ffh,00ch,02dh,000h,060h,096h,0cfh,006h,05fh,0ffh,006h,021h,05dh	; 9211  .....-.`..._..!]
	defb 094h,0cdh,006h,020h,006h,021h,02dh,000h,05fh,096h,0c3h,006h,020h,0ffh,006h,036h	; 9221  ... .!-._... ..6
	defb 002h,0c3h,003h,0ffh,003h,037h,021h,0cfh,003h,020h,0ffh,003h,0c3h,003h,0ffh,003h	; 9231  .....7!.. ......
	defb 021h,02dh,000h,05fh,09bh,0cfh,006h,020h,006h,0ffh,00ch,021h,0cfh,003h,020h,0ffh	; 9241  !-._... ...!.. .
	defb 003h,0c3h,003h,0ffh,003h,0d0h,003h,0ffh,003h,021h,0c4h,003h,020h,0ffh,003h,021h	; 9251  .........!.. ..!
	defb 0d1h,003h,020h,0ffh,003h,0c5h,003h,0ffh,003h,02dh,000h,056h,091h,0c6h,006h,0ffh	; 9261  .. ......-.V....
	defb 006h,036h,002h,021h,0c6h,006h,020h,0ffh,006h,037h,021h,02dh,000h,05bh,096h,0d2h	; 9271  .6.!.. ..7!-.[..
	defb 003h,020h,02dh,000h,0ffh,003h,0c6h,003h,0ffh,009h,021h,0d2h,006h,020h,0ffh,006h	; 9281  . -.......!.. ..
	defb 0c6h,006h,02dh,000h,021h,060h,096h,0d2h,006h,020h,05fh,006h,05dh,0c6h,006h,0ffh	; 9291  ..-.!`... _.]...
	defb 006h,021h,02dh,000h,062h,096h,0c6h,006h,020h,0ffh,006h,036h,002h,0c3h,003h,0ffh	; 92a1  .!-.b... ..6....
	defb 003h,037h,021h,0d2h,003h,020h,0ffh,003h,0c3h,003h,0ffh,003h,021h,0d2h,006h,020h	; 92b1  .7!.. ......!.. 
	defb 006h,0ffh,00ch,028h,00fh,029h,00dh,021h,05dh,096h,0cdh,006h,020h,006h,05eh,006h	; 92c1  ...(.).!]... .^.
	defb 021h,05dh,006h,020h,05eh,006h,060h,0c6h,006h,036h,002h,021h,062h,098h,0c5h,003h	; 92d1  !]. ^.`..6.!b...
	defb 020h,03dh,003h,037h,021h,062h,09bh,0d4h,003h,020h,03dh,009h,0d4h,006h,0c5h,006h	; 92e1   =.7!b... =.....
	defb 021h,062h,09ah,0cah,006h,020h,012h,021h,060h,09ah,006h,020h,07fh,0bfh,006h,028h	; 92f1  !b... .!`.. ...(
	defb 010h,029h,010h,02ch,032h,02dh,000h,05eh,09ah,006h,021h,060h,09ah,0d2h,006h,020h	; 9301  .).,2-.^..!`... 
	defb 0cah,00ch,036h,002h,028h,00fh,029h,00dh,021h,060h,099h,0c3h,003h,020h,03dh,003h	; 9311  ..6.(.).!`... =.
	defb 037h,021h,060h,099h,0cfh,003h,020h,03dh,009h,0cfh,006h,0c3h,006h,021h,060h,098h	; 9321  7!`... =.....!`.
	defb 0c8h,006h,020h,00ch,03dh,006h,05eh,098h,0c6h,006h,07fh,0bfh,006h,05dh,098h,006h	; 9331  .. .=.^......]..
	defb 021h,02dh,000h,05eh,098h,006h,020h,0cah,00ch,021h,063h,09eh,0c8h,006h,020h,03dh	; 9341  !-.^.. ..!c... =
	defb 006h,065h,0a2h,006h,021h,07fh,0bfh,0d7h,006h,020h,028h,010h,029h,010h,02ch,032h	; 9351  .e..!.... (.).,2
	defb 02dh,000h,067h,0a3h,006h,06ah,0a3h,006h,021h,0ceh,006h,020h,006h,028h,00fh,029h	; 9361  -.g..j..!.. .(.)
	defb 00dh,05bh,097h,0cdh,006h,03dh,006h,021h,05dh,099h,006h,020h,07fh,0bfh,0d7h,006h	; 9371  .[...=.!].. ....
	defb 028h,010h,029h,010h,02ch,032h,02dh,000h,05eh,09bh,006h,021h,060h,09dh,006h,020h	; 9381  (.).,2-.^..!`.. 
	defb 0cdh,00ch,028h,00fh,029h,00dh,021h,05eh,09bh,0cbh,006h,020h,096h,008h,03dh,004h	; 9391  ..(.).!^... ..=.
	defb 021h,05eh,09ah,0cbh,006h,020h,095h,008h,03dh,004h,021h,05eh,096h,0c6h,006h,020h	; 93a1  !^... ..=.!^... 
	defb 03dh,012h,021h,05dh,096h,0c7h,006h,020h,03dh,00ch,021h,05fh,096h,0cch,006h,020h	; 93b1  =.!]... =.!_... 
	defb 0c0h,009h,07fh,0bfh,003h,028h,010h,029h,010h,02dh,000h,058h,095h,0c5h,006h,0ffh	; 93c1  .....(.).-.X....
	defb 00ch,0d5h,006h,033h,038h,090h	; 93d1

; ----------------------------------------------------------------------
; DATOS pieza_11: Pieza 11 (373 bytes): el salto de 0x9549 vuelve al principio
;   0x93d7..0x954c  (373 bytes)
DATA_pieza_11:
	defb 027h,0b8h,028h,010h,029h,00dh,02ah,00eh,02ch,03ch,02dh,000h,05bh,094h,0c8h,00ch	; 93d7  '.(.).*.,<-.[...
	defb 098h,0cfh,006h,08fh,0d8h,006h,094h,0c3h,00ch,098h,0cfh,006h,08fh,0d8h,006h,094h	; 93e7  ................
	defb 0c8h,00ch,098h,0cfh,006h,08fh,0d8h,006h,02dh,000h,060h,094h,0c3h,00ch,094h,0cfh	; 93f7  ........-.`.....
	defb 006h,08fh,0d8h,006h,02dh,000h,065h,08ch,0c8h,00ch,09bh,0cfh,006h,094h,0d8h,006h	; 9407  ....-.e.........
	defb 02dh,000h,064h,098h,0c8h,006h,0bfh,0ffh,006h,09bh,0d4h,006h,0bfh,0ffh,006h,02dh	; 9417  -.d............-
	defb 000h,062h,099h,0cah,006h,0bfh,0ffh,006h,099h,0d6h,006h,0bfh,0ffh,006h,02dh,000h	; 9427  .b............-.
	defb 060h,09bh,0cch,006h,0bfh,0ffh,006h,094h,0d8h,006h,0bfh,0ffh,006h,02dh,000h,05eh	; 9437  `............-.^
	defb 096h,0c3h,00ch,099h,0cfh,006h,092h,0d9h,006h,08fh,0cah,00ch,099h,0cfh,006h,092h	; 9447  ................
	defb 0d9h,006h,096h,0cfh,00ch,099h,0cfh,006h,09eh,0d6h,006h,02dh,000h,062h,0bfh,0c3h	; 9457  ...........-.b..
	defb 00ch,09eh,0cfh,006h,096h,0d9h,006h,02dh,000h,069h,0bfh,0c8h,00ch,09eh,0cfh,006h	; 9467  .......-.i......
	defb 098h,0d4h,006h,02dh,000h,067h,0bfh,0ffh,00ch,092h,0c8h,006h,0bfh,006h,02dh,000h	; 9477  ...-.g........-.
	defb 065h,092h,0cah,006h,0bfh,0ffh,006h,092h,0d9h,006h,0bfh,0ffh,006h,02dh,000h,064h	; 9487  e............-.d
	defb 094h,0cch,006h,0bfh,0ffh,006h,092h,0cfh,006h,0bfh,0ffh,006h,02dh,000h,062h,09dh	; 9497  ............-.b.
	defb 0cdh,00ah,0bfh,0ffh,008h,09dh,0cdh,006h,0bfh,0ffh,00ch,02dh,000h,060h,090h,0c1h	; 94a7  ...........-.`..
	defb 012h,03dh,012h,02dh,000h,05fh,09ch,0cdh,004h,03dh,008h,060h,090h,0c1h,004h,03dh	; 94b7  .=.-._...=.`...=
	defb 008h,02dh,000h,062h,08fh,0c0h,00ah,0bfh,0ffh,008h,09bh,0cch,006h,0bfh,0ffh,00ch	; 94c7  .-.b............
	defb 02dh,000h,060h,09bh,0c5h,012h,03dh,012h,02dh,000h,05fh,09bh,0d1h,004h,03dh,008h	; 94d7  -.`...=.-._...=.
	defb 060h,08fh,0c5h,004h,03dh,008h,02dh,000h,067h,091h,0c1h,005h,0bfh,0ffh,007h,0d9h	; 94e7  `...=.-.g.......
	defb 005h,0ffh,007h,095h,0c5h,005h,0bfh,0ffh,007h,0ddh,005h,0ffh,007h,02dh,000h,065h	; 94f7  .............-.e
	defb 094h,0cah,005h,0bfh,0ffh,00dh,09dh,0cdh,005h,02dh,000h,05ch,0bfh,0ffh,00dh,099h	; 9507  .........-.\....
	defb 0d4h,005h,0bfh,0ffh,007h,02dh,000h,064h,09ah,0cah,012h,03dh,006h,02dh,000h,065h	; 9517  .....-.d...=.-.e
	defb 0a0h,0d0h,006h,064h,0bfh,0ffh,006h,062h,093h,0cfh,012h,03dh,006h,054h,099h,0cah	; 9527  ...d...b...=.T..
	defb 003h,03dh,009h,036h,002h,053h,098h,0cfh,003h,03dh,003h,037h,04dh,093h,0c3h,006h	; 9537  .=.6.S...=.7M...
	defb 03dh,006h,033h,0d7h,093h	; 9547

; ----------------------------------------------------------------------
; DATOS pieza_12: Pieza 12 (127 bytes)
;   0x954c..0x95cb  (127 bytes)
DATA_pieza_12:
	defb 027h,0b8h,028h,00fh,029h,00dh,02ah,00eh,026h,004h,066h,0a2h,0c7h,006h,0ffh,006h	; 954c  '.(.).*.&.f.....
	defb 027h,0a8h,096h,0d3h,006h,027h,0b8h,07fh,0c7h,006h,066h,09dh,0d3h,003h,0bfh,0ffh	; 955c  '....'....f.....
	defb 003h,027h,0a8h,09dh,0c7h,006h,027h,0b8h,006h,0bfh,0ffh,006h,036h,002h,027h,0a8h	; 956c  .'....'.....6.'.
	defb 068h,09ch,0cch,003h,027h,0b8h,0bfh,0ffh,003h,037h,096h,0cch,002h,03dh,004h,064h	; 957c  h...'....7...=.d
	defb 006h,066h,006h,068h,09fh,0cch,00ch,03dh,006h,027h,0a8h,069h,0a1h,0cah,004h,027h	; 958c  .f.h...=.'.i...'
	defb 0b8h,0bfh,0ffh,008h,027h,0a8h,09ah,0cah,004h,027h,0b8h,0bfh,0ffh,008h,027h,0a8h	; 959c  ....'....'....'.
	defb 05dh,098h,0c9h,003h,027h,0b8h,03dh,003h,027h,0a8h,05dh,096h,0c7h,003h,027h,0b8h	; 95ac  ]...'.=.'.]...'.
	defb 03dh,009h,027h,0a8h,05dh,095h,0c5h,004h,027h,0b8h,012h,07fh,006h,03dh,000h	; 95bc  =.'.]...'....=.

; ----------------------------------------------------------------------
; DATOS pieza_02: Pieza 2 (20 bytes): desde 0x95CE es tambien el bucle final
;   de la pieza 1
;   0x95cb..0x95df  (20 bytes)
DATA_pieza_02:
	defb 034h,0dfh,095h,036h,00dh,034h,0fah,095h,037h,036h,00fh,031h,0ffh,032h,0ffh,034h,0fah,095h,037h,000h	; 95cb  4..6.4..76.1.2.4..7.

; ----------------------------------------------------------------------
; DATOS frases_musica: Las cuatro frases que la musica llama con 0x34 (0x95DF,
;   0x95FA, 0x961F y 0x963E) y la cola comun de 0x965A (0x961F salta a ella;
;   0x9662 vuelve a 0x9601)
;   0x95df..0x9665  (134 bytes)
DATA_frases_musica:
	defb 027h,08fh,026h,01fh,028h,00fh,029h,007h,02ah,007h,036h,008h,031h,001h,032h,001h	; 95df  '.&.(.).*.6.1.2.
	defb 003h,037h,029h,00fh,02ah,00fh,001h,029h,00ch,001h,035h,026h,01fh,031h,003h,032h	; 95ef  .7).*..)..5&.1.2
	defb 0ffh,001h,031h,0feh,032h,0ffh,001h,031h,001h,032h,001h,001h,026h,01eh,031h,0ffh	; 95ff  ..1.2..1.2..&.1.
	defb 032h,0ffh,001h,026h,01dh,032h,001h,001h,026h,01ch,031h,0ffh,032h,001h,001h,035h	; 960f  2..&.2..&.1.2..5
	defb 027h,08eh,029h,00dh,02ah,00ch,078h,001h,036h,006h,038h,0fbh,002h,037h,07fh,002h	; 961f  '.).*.x.6.8..7..
	defb 075h,001h,036h,006h,038h,0fbh,001h,037h,036h,014h,038h,002h,033h,05ah,096h,027h	; 962f  u.6.8..76.8.3Z.'
	defb 08eh,029h,00dh,02ah,00ch,076h,001h,036h,007h,038h,0fch,001h,037h,079h,001h,036h	; 963f  .).*.v.6.8..7y.6
	defb 007h,038h,0fch,001h,037h,075h,001h,036h,010h,038h,0feh,001h,037h,027h,08fh,029h	; 964f  .8..7u.6.8..7'.)
	defb 00fh,02ah,00eh,033h,001h,096h	; 965f

; ----------------------------------------------------------------------
; DATOS sprites_red: Tres patrones de sprite de 16x16 (96 bytes): la red de la
;   canasta en tres cuadros; 0x504B los copia a la VRAM 0x3B00
;   0x9665..0x96c5  (96 bytes)
DATA_sprites_red:
	defb 007h,00dh,015h,012h,008h,00fh,006h,005h,002h,003h,002h,000h,000h,000h,000h,000h	; 9665  ................
	defb 0f0h,058h,054h,0a4h,008h,0f8h,0b0h,050h,0a0h,060h,0a0h,080h,000h,000h,000h,000h	; 9675  .XT....P.`......
	defb 007h,00dh,015h,012h,008h,00fh,00ah,005h,003h,000h,000h,000h,000h,000h,000h,000h	; 9685  ................
	defb 0f0h,058h,054h,0a4h,008h,0f8h,0a8h,050h,0e0h,000h,000h,000h,000h,000h,000h,000h	; 9695  .XT....P........
	defb 004h,00ah,012h,015h,01ch,00fh,00ah,007h,000h,000h,000h,000h,000h,000h,000h,000h	; 96a5  ................
	defb 090h,0a8h,0a4h,054h,01ch,0f8h,0a8h,0f0h,000h,000h,000h,000h,000h,000h,000h,000h	; 96b5  ...T............

; ----------------------------------------------------------------------
; DATOS sprites_balon: Tres patrones de sprite de 16x16 (96 bytes): el balon
;   grande, el pequeno y la flecha del cursor; 0x5057 los copia a la VRAM
;   0x3B60
;   0x96c5..0x9725  (96 bytes)
DATA_sprites_balon:
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,007h,007h,007h,003h	; 96c5  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0e0h,0e0h,0e0h,0e0h,0c0h	; 96d5  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,003h,007h,003h	; 96e5  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,0c0h,0e0h,0c0h	; 96f5  ................
	defb 000h,000h,000h,000h,080h,0e0h,0f8h,0feh,0ffh,0fch,0f0h,0c0h,000h,000h,000h,000h	; 9705  ................
	defb 000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h,000h	; 9715  ................

; ----------------------------------------------------------------------
; DATOS sprites_jugadores_a: Comprimido (formato 0x52CF, 995 bytes): 2048
;   bytes a 0xCC00, los 64 primeros patrones de sprite de 16x16 de los
;   jugadores (0x5079)
;   0x9725..0x9b08  (995 bytes)
DATA_sprites_jugadores_a:
	defb 0f0h,050h,057h,000h,003h,055h,007h,000h,050h,000h,0e0h,055h,0f0h,000h,050h,000h	; 9725  .PW..U..P..U..P.
	defb 007h,054h,00fh,007h,000h,050h,000h,0c0h,054h,0e0h,0c0h,000h,050h,000h,003h,007h	; 9735  .T...P..T...P...
	defb 053h,003h,001h,000h,050h,000h,051h,005h,050h,000h,050h,005h,050h,000h,051h,009h	; 9745  S...P.Q.P.P.P.Q.
	defb 055h,003h,007h,007h,007h,056h,000h,055h,0e0h,0f0h,0f0h,070h,056h,000h,051h,012h	; 9755  U....V.U...pV.Q.
	defb 051h,013h,051h,010h,051h,011h,053h,001h,053h,000h,050h,000h,0e0h,0f0h,0f0h,054h	; 9765  Q.Q.Q.S.S.P....T
	defb 0f8h,0f8h,056h,000h,051h,01ah,051h,01bh,051h,018h,050h,000h,001h,052h,003h,053h	; 9775  ..V.Q.Q.Q.P..R.S
	defb 001h,001h,056h,000h,0e0h,0e0h,055h,0f0h,0f0h,056h,000h,051h,022h,051h,023h,051h	; 9785  ..V...U..V.Q"Q#Q
	defb 020h,051h,021h,057h,001h,050h,021h,050h,022h,050h,023h,051h,022h,051h,023h,051h	; 9795   Q!W.P!P"P#Q"Q#Q
	defb 028h,051h,021h,057h,003h,003h,056h,000h,057h,0e0h,051h,031h,051h,032h,050h,031h	; 97a5  (Q!W..V.W.Q1Q2P1
	defb 051h,030h,051h,031h,000h,003h,002h,006h,007h,003h,001h,005h,00dh,00ch,018h,018h	; 97b5  Q0Q1............
	defb 033h,030h,060h,060h,000h,0e0h,0a0h,0b0h,0f0h,0e0h,0c0h,0d0h,0d8h,098h,00ch,00ch	; 97c5  30``............
	defb 0e6h,006h,003h,003h,007h,006h,00eh,00eh,00ch,052h,01ch,01ch,01ch,03ch,054h,000h	; 97d5  .........R...<T.
	defb 070h,030h,038h,038h,018h,052h,01ch,01ch,01ch,01eh,054h,000h,055h,000h,003h,008h	; 97e5  p088.R....T.U...
	defb 018h,018h,030h,030h,067h,060h,0c0h,0c0h,055h,000h,080h,020h,030h,030h,018h,018h	; 97f5  ..00g`..U.. 00..
	defb 0cch,00ch,006h,006h,000h,003h,002h,006h,007h,003h,000h,000h,002h,002h,006h,01ch	; 9805  ................
	defb 019h,003h,00fh,00eh,000h,080h,080h,053h,0c0h,000h,053h,0c0h,0d8h,080h,000h,080h	; 9815  .......S..S.....
	defb 001h,001h,052h,002h,001h,001h,000h,001h,003h,055h,000h,070h,070h,0f0h,0e0h,0e0h	; 9825  ..R......U.pp...
	defb 070h,070h,0b8h,0b8h,078h,0f8h,054h,000h,051h,046h,051h,047h,051h,044h,051h,045h	; 9835  pp..x.T.QFQGQDQE
	defb 051h,04ah,051h,04bh,051h,048h,051h,049h,000h,003h,001h,005h,007h,003h,000h,002h	; 9845  QJQKQHQI........
	defb 005h,005h,00ch,01ch,039h,030h,000h,001h,000h,0c0h,040h,060h,0e0h,052h,0c0h,0b0h	; 9855  ....90....@`.R..
	defb 0b8h,018h,01ch,0ech,00eh,006h,086h,003h,052h,006h,002h,052h,003h,007h,00fh,055h	; 9865  ........R..R...U
	defb 000h,070h,0f0h,052h,0e0h,070h,070h,0b8h,0b8h,078h,0f0h,054h,000h,051h,056h,051h	; 9875  .p.R.pp..x.T.QVQ
	defb 057h,051h,054h,051h,055h,051h,05ah,051h,05bh,051h,058h,051h,059h,000h,003h,001h	; 9885  WQTQUQZQ[QXQY...
	defb 005h,007h,003h,000h,000h,003h,003h,007h,006h,00eh,01ch,078h,071h,052h,000h,052h	; 9895  ...........xqR.R
	defb 080h,0c0h,000h,053h,000h,0f0h,000h,000h,080h,003h,053h,007h,003h,003h,001h,001h	; 98a5  ...S......S.....
	defb 003h,007h,054h,000h,0d0h,0a0h,052h,060h,0b0h,0b8h,0d8h,0d8h,0d0h,0c0h,054h,000h	; 98b5  ..T...R`......T.
	defb 051h,066h,051h,067h,051h,064h,051h,065h,051h,06ah,051h,06bh,051h,068h,051h,069h	; 98c5  QfQgQdQeQjQkQhQi
	defb 050h,038h,00dh,01ch,018h,018h,01bh,01ch,000h,000h,050h,03ah,0d8h,09ch,00ch,00ch	; 98d5  P8........P:....
	defb 0ech,01ch,000h,000h,050h,040h,018h,038h,030h,030h,037h,030h,000h,000h,050h,042h	; 98e5  ....P@.80070..PB
	defb 030h,038h,018h,018h,0d8h,018h,000h,000h,050h,044h,006h,019h,0e7h,09eh,078h,070h	; 98f5  08......PD....xp
	defb 000h,000h,050h,046h,0c0h,0c0h,080h,000h,0f8h,000h,000h,080h,051h,046h,051h,07fh	; 9905  ..PF........QFQ.
	defb 051h,044h,051h,07dh,050h,054h,005h,00dh,01ch,0f9h,0e7h,01eh,01ch,001h,000h,0c0h	; 9915  QDQ}PT..........
	defb 040h,060h,0e0h,0c0h,0c0h,080h,060h,060h,0e0h,0c0h,0b0h,000h,000h,080h,051h,086h	; 9925  @`....``......Q.
	defb 051h,087h,051h,054h,051h,085h,050h,064h,003h,007h,01eh,0fch,0f1h,000h,000h,001h	; 9935  Q.QTQ.Pd........
	defb 050h,066h,050h,067h,051h,066h,051h,067h,051h,064h,051h,08dh,050h,038h,00dh,014h	; 9945  PfPgQfQgQdQ.P8..
	defb 018h,018h,01bh,052h,000h,050h,03ah,0d8h,094h,00ch,00ch,0ech,052h,000h,052h,007h	; 9955  ...R.P:.....R.R.
	defb 054h,00eh,00eh,00eh,01eh,054h,000h,052h,070h,054h,038h,051h,03dh,050h,040h,053h	; 9965  T....T.RpT8Q=P@S
	defb 018h,007h,052h,000h,050h,042h,053h,030h,0c0h,052h,000h,050h,044h,000h,018h,01dh	; 9975  ..R.PBS0.R.PD...
	defb 01fh,00fh,000h,000h,001h,050h,046h,052h,0c0h,080h,070h,052h,000h,002h,002h,052h	; 9985  .....PFR..pR...R
	defb 005h,002h,002h,001h,003h,006h,001h,054h,000h,0e0h,0e0h,052h,0c0h,0e0h,0e0h,070h	; 9995  .......T...R...p
	defb 070h,0f0h,0f0h,054h,000h,051h,046h,051h,0a3h,051h,044h,051h,0a1h,051h,0a6h,051h	; 99a5  p..T.QFQ.QDQ.Q.Q
	defb 0a7h,051h,0a4h,051h,0a5h,050h,054h,006h,036h,03dh,03dh,001h,000h,000h,001h,050h	; 99b5  .Q.Q.PT.6==....P
	defb 086h,0b0h,038h,098h,0f8h,0f0h,000h,000h,080h,051h,086h,051h,0b3h,051h,054h,051h	; 99c5  ..8......Q.Q.QTQ
	defb 0b1h,050h,064h,003h,003h,019h,01fh,01fh,000h,000h,001h,050h,066h,000h,052h,080h	; 99d5  .Pd........Pf.R.
	defb 070h,052h,000h,051h,066h,051h,0bbh,051h,064h,051h,0b9h,000h,003h,002h,006h,007h	; 99e5  pR.QfQ.QdQ......
	defb 003h,001h,01dh,03dh,038h,000h,000h,003h,052h,000h,000h,0e0h,0a0h,0b0h,0f0h,0e0h	; 99f5  ...=8...R.......
	defb 0c0h,0dch,0deh,08eh,000h,000h,0e0h,052h,000h,055h,000h,073h,078h,038h,052h,000h	; 9a05  .......R.U.sx8R.
	defb 007h,052h,000h,055h,000h,09ch,03ch,038h,052h,000h,0c0h,052h,000h,000h,003h,002h	; 9a15  .R.U..<8R..R....
	defb 006h,007h,003h,080h,0c0h,07fh,07fh,000h,000h,001h,000h,000h,001h,050h,046h,0c0h	; 9a25  .............PF.
	defb 0c0h,000h,000h,0f0h,052h,000h,051h,046h,051h,0cbh,051h,0c8h,051h,0c9h,000h,003h	; 9a35  ....R.QFQ.Q.Q...
	defb 001h,005h,007h,003h,000h,006h,01ch,0e3h,0dfh,01eh,001h,000h,000h,001h,050h,086h	; 9a45  ..............P.
	defb 070h,0f0h,0c0h,000h,0f0h,000h,000h,080h,051h,086h,051h,0d3h,051h,0d0h,051h,0d1h	; 9a55  p.......Q.Q.Q.Q.
	defb 000h,003h,001h,035h,0d7h,0e3h,078h,03eh,00fh,003h,000h,000h,001h,000h,000h,001h	; 9a65  ...5..x>........
	defb 050h,066h,080h,080h,000h,000h,0f0h,000h,000h,080h,051h,066h,051h,0dbh,051h,0d8h	; 9a75  Pf........QfQ.Q.
	defb 051h,0d9h,050h,038h,00dh,00ch,01ch,078h,0f3h,052h,000h,050h,03ah,0d8h,09ch,00ch	; 9a85  Q.P8...x.R.P:...
	defb 00eh,0e6h,006h,006h,000h,050h,038h,00dh,00ch,01ch,018h,03bh,030h,070h,0e0h,050h	; 9a95  .....P8....;0p.P
	defb 03ah,050h,0e3h,050h,040h,018h,038h,030h,070h,067h,060h,060h,000h,050h,042h,030h	; 9aa5  :P.P@.80pg``.PB0
	defb 030h,038h,01eh,0cfh,052h,000h,050h,040h,050h,0e9h,050h,042h,030h,030h,038h,018h	; 9ab5  08..R.P@P.PB008.
	defb 0dch,00ch,00eh,007h,050h,044h,052h,000h,01fh,03ch,003h,003h,000h,050h,046h,0c0h	; 9ac5  ....PDR..<...PF.
	defb 0e0h,060h,060h,0e8h,0c0h,080h,000h,050h,044h,052h,000h,002h,004h,00bh,01bh,038h	; 9ad5  .``....PDR.....8
	defb 050h,046h,050h,0f3h,051h,046h,053h,003h,01dh,000h,000h,001h,051h,044h,052h,000h	; 9ae5  PFP.QFS.....QDR.
	defb 0f8h,0fch,052h,000h,051h,046h,050h,0f9h,051h,044h,052h,000h,080h,0c0h,0e0h,070h	; 9af5  ..R.QFP.QDR....p
	defb 03ch,050h,0ffh	; 9b05

; ----------------------------------------------------------------------
; DATOS sprites_jugadores_b: Comprimido (0x52CF, 1144 bytes): 2048 bytes a
;   0xD400, los patrones de sprite 64-127 (0x5082)
;   0x9b08..0x9f80  (1144 bytes)
DATA_sprites_jugadores_b:
	defb 0c1h,041h,000h,003h,001h,005h,007h,003h,000h,002h,005h,00dh,00ch,07ch,0f1h,000h	; 9b08  .A...........|..
	defb 000h,001h,000h,0c0h,040h,060h,0e0h,0c0h,0c0h,080h,0b0h,0b8h,01ch,00ch,0ech,01ch	; 9b18  ....@`..........
	defb 01ch,080h,041h,000h,005h,005h,00ch,00ch,01dh,038h,070h,001h,041h,002h,041h,003h	; 9b28  ..A......8p.A.A.
	defb 043h,002h,006h,006h,007h,003h,00dh,000h,000h,001h,043h,000h,080h,080h,000h,0f0h	; 9b38  C.........C.....
	defb 0f8h,000h,000h,080h,043h,002h,006h,006h,007h,003h,00bh,001h,000h,001h,043h,000h	; 9b48  ....C.........C.
	defb 080h,080h,000h,000h,080h,0c0h,0f0h,080h,000h,003h,001h,005h,007h,003h,000h,000h	; 9b58  ................
	defb 045h,003h,01bh,01fh,01eh,000h,001h,045h,000h,045h,080h,0c0h,000h,047h,000h,070h	; 9b68  E......E.E...G.p
	defb 000h,000h,080h,043h,012h,047h,000h,00fh,000h,000h,001h,043h,010h,045h,0c0h,0fch	; 9b78  ...C.G.....C.E..
	defb 07eh,000h,000h,080h,043h,012h,041h,015h,043h,010h,045h,0c0h,0e0h,070h,038h,01eh	; 9b88  ~...C.A.C.E..p8.
	defb 080h,000h,000h,018h,03ch,018h,01bh,01ah,01ah,01bh,01bh,01dh,00dh,005h,045h,000h	; 9b98  ....<.........E.
	defb 000h,000h,018h,01ch,00eh,0e6h,0a6h,0b6h,0f6h,0eeh,0dch,0d8h,0d0h,080h,000h,000h	; 9ba8  ................
	defb 003h,045h,000h,047h,007h,04dh,007h,003h,0e0h,045h,000h,047h,070h,04dh,070h,060h	; 9bb8  .E.G.M...E.GpMp`
	defb 018h,01ch,045h,018h,01bh,01ah,01ah,01bh,01dh,00dh,00dh,005h,045h,000h,041h,01eh	; 9bc8  ..E.........E.A.
	defb 041h,01fh,000h,000h,018h,038h,070h,045h,060h,060h,070h,03bh,018h,008h,045h,000h	; 9bd8  A....8pE``p;..E.
	defb 000h,000h,018h,03ch,047h,018h,018h,018h,0b8h,030h,020h,045h,000h,043h,022h,043h	; 9be8  ...<G....0 E.C"C
	defb 023h,043h,020h,043h,021h,041h,028h,041h,029h,018h,038h,04bh,018h,018h,038h,0b0h	; 9bf8  #C C!A(A).8K..8.
	defb 030h,020h,045h,000h,000h,000h,004h,00ch,01ch,01bh,01ah,01ah,01bh,01dh,00eh,007h	; 9c08  0 E.............
	defb 003h,045h,000h,049h,000h,080h,080h,0c0h,045h,0c0h,049h,000h,003h,045h,000h,047h	; 9c18  .E.I....E.I..E.G
	defb 001h,04dh,001h,003h,0e0h,045h,000h,047h,0c0h,04dh,0c0h,080h,060h,030h,034h,02ch	; 9c28  .M...E.G.M..`04,
	defb 01ch,01bh,01ah,01ah,041h,035h,041h,036h,041h,037h,043h,036h,043h,037h,000h,000h	; 9c38  ....A5A6A7C6C7..
	defb 040h,070h,038h,0dch,04ch,06ch,0ech,0dch,038h,0f0h,0e0h,045h,000h,043h,03ah,043h	; 9c48  @p8.Ll..8..E.C:C
	defb 03bh,043h,038h,043h,039h,043h,036h,043h,037h,006h,045h,00ch,018h,0d8h,058h,058h	; 9c58  ;C8C9C6C7.E...XX
	defb 0d8h,0b0h,070h,0e0h,0c0h,045h,000h,000h,000h,00ch,01ch,038h,033h,031h,035h,037h	; 9c68  ..p..E.....83157
	defb 01bh,00ch,006h,001h,001h,000h,000h,000h,000h,018h,018h,038h,0d8h,058h,058h,045h	; 9c78  ...........8.XXE
	defb 0d8h,0b8h,0b0h,080h,000h,000h,003h,000h,000h,003h,047h,002h,04bh,002h,006h,001h	; 9c88  ..........G.K...
	defb 0e0h,045h,000h,047h,0e0h,043h,021h,070h,078h,045h,030h,033h,031h,035h,017h,01bh	; 9c98  .E.G.C!pxE0315..
	defb 00ch,006h,001h,001h,000h,000h,041h,04eh,041h,04fh,000h,000h,070h,03ch,018h,01bh	; 9ca8  ......ANAO..p<..
	defb 01ah,01ah,043h,04fh,000h,000h,030h,030h,018h,0d8h,098h,0a8h,043h,055h,043h,052h	; 9cb8  ..CO..00....CUCR
	defb 041h,021h,043h,050h,043h,051h,006h,00eh,01ch,01ch,018h,01bh,01ah,01ah,01bh,01dh	; 9cc8  A!CPCQ..........
	defb 00dh,00dh,005h,001h,000h,000h,041h,05ah,043h,055h,000h,000h,018h,018h,038h,033h	; 9cd8  ......AZCU....83
	defb 031h,035h,037h,03bh,01ch,00eh,006h,045h,000h,000h,000h,03ch,018h,045h,000h,080h	; 9ce8  157;...E...<.E..
	defb 080h,090h,0d0h,010h,047h,000h,003h,045h,000h,047h,003h,04dh,003h,007h,0e0h,000h	; 9cf8  ....G..E.G.M....
	defb 000h,060h,047h,0a0h,04dh,0a0h,000h,003h,001h,019h,018h,038h,033h,031h,035h,041h	; 9d08  .`G.M......8315A
	defb 065h,080h,0c0h,0c0h,047h,000h,080h,041h,067h,000h,000h,00ch,008h,045h,000h,001h	; 9d18  e...G..Ag....E..
	defb 043h,067h,000h,000h,030h,038h,01ch,0cch,086h,0a6h,0e6h,0ceh,01ch,078h,070h,045h	; 9d28  Cg..08.......xpE
	defb 000h,043h,06ah,043h,06bh,043h,068h,043h,069h,041h,070h,043h,067h,003h,007h,00eh	; 9d38  .CjCkChCiApCg...
	defb 00ch,00ch,0cch,08ch,0ach,0ech,0d8h,038h,070h,060h,045h,000h,041h,024h,041h,025h	; 9d48  .......8p`E.A$A%
	defb 00ch,01ch,045h,00ch,0ech,0ach,0ach,0ech,0dch,0d8h,0d8h,0d0h,080h,000h,000h,000h	; 9d58  ..E.............
	defb 000h,038h,01ch,018h,01bh,01ah,01ah,041h,025h,000h,000h,00eh,01ch,00ch,0ech,0ach	; 9d68  .8.....A%.......
	defb 0ach,041h,07fh,030h,038h,04bh,030h,030h,038h,01bh,018h,008h,045h,000h,041h,032h	; 9d78  .A.08K008...E.A2
	defb 041h,033h,000h,000h,070h,038h,047h,030h,041h,085h,000h,000h,01ch,038h,047h,018h	; 9d88  A3..p8G0A....8G.
	defb 041h,033h,00ch,00ch,01ch,018h,018h,01bh,01ah,01ah,041h,035h,041h,036h,041h,037h	; 9d98  A3........A5A6A7
	defb 000h,000h,070h,038h,018h,01bh,01ah,01ah,041h,035h,041h,036h,041h,037h,043h,036h	; 9da8  ..p8....A5A6A7C6
	defb 043h,037h,043h,08ch,043h,035h,043h,036h,043h,037h,043h,090h,043h,035h,00ch,00eh	; 9db8  C7C.C5C6C7C.C5..
	defb 01ch,018h,018h,01bh,019h,015h,017h,00bh,00ch,006h,001h,001h,000h,000h,043h,024h	; 9dc8  ..............C$
	defb 0d8h,0d8h,0b8h,0b0h,0b0h,080h,000h,000h,000h,000h,070h,038h,018h,01bh,019h,015h	; 9dd8  ..........p8....
	defb 041h,055h,000h,000h,0e0h,070h,038h,0d8h,058h,058h,041h,09fh,041h,024h,043h,09fh	; 9de8  AU...p8.XXA.A$C.
	defb 043h,09ch,043h,09dh,043h,0a2h,043h,09fh,043h,0a0h,043h,055h,018h,01ch,038h,030h	; 9df8  C.C.C.C.C.CU..80
	defb 030h,033h,031h,035h,041h,065h,030h,078h,038h,018h,045h,008h,088h,088h,098h,0d0h	; 9e08  0315Ae0x8.E.....
	defb 010h,047h,000h,000h,000h,0e1h,070h,030h,033h,031h,035h,041h,065h,000h,000h,0e0h	; 9e18  .G....p0315Ae...
	defb 010h,045h,000h,080h,041h,067h,043h,0aeh,043h,0afh,043h,0ach,043h,065h,043h,0b2h	; 9e28  .E..AgC.C.C.CeC.
	defb 043h,067h,043h,0b0h,043h,065h,000h,000h,003h,002h,006h,007h,003h,001h,005h,019h	; 9e38  CgC.Ce..........
	defb 018h,018h,000h,003h,000h,000h,000h,000h,0e0h,0a0h,0b0h,0f0h,0e0h,0c0h,0d0h,0d8h	; 9e48  ................
	defb 09ch,00ch,00ch,0ech,00ch,000h,000h,04dh,007h,007h,007h,003h,049h,000h,000h,04bh	; 9e58  .......M....I..K
	defb 070h,060h,04fh,000h,041h,0bch,005h,00dh,004h,018h,018h,01bh,000h,000h,041h,0beh	; 9e68  p`O.A.........A.
	defb 0d0h,0d8h,090h,00ch,00ch,0ech,000h,000h,041h,0c0h,047h,007h,047h,000h,045h,070h	; 9e78  ........A.G.G.Ep
	defb 000h,070h,060h,000h,000h,041h,0c3h,041h,0bch,005h,00dh,01ch,018h,018h,01bh,018h	; 9e88  .p`..A.A........
	defb 000h,041h,0beh,0d0h,0cch,08ch,00ch,000h,0e0h,000h,000h,043h,0c2h,041h,0c3h,000h	; 9e98  .A.........C.A..
	defb 04dh,070h,070h,070h,060h,049h,000h,045h,007h,000h,007h,003h,000h,000h,041h,0c3h	; 9ea8  Mppp`I.E......A.
	defb 041h,0d2h,047h,070h,047h,000h,04dh,000h,003h,008h,018h,018h,038h,030h,037h,000h	; 9eb8  A.GpG.M.....807.
	defb 000h,04dh,000h,080h,020h,030h,030h,038h,018h,0d8h,000h,000h,00eh,000h,045h,00eh	; 9ec8  .M.. 008......E.
	defb 006h,000h,000h,041h,0c3h,043h,0c0h,043h,0c9h,041h,0d8h,008h,018h,018h,038h,030h	; 9ed8  ...A.C.C.A....80
	defb 037h,030h,000h,041h,0dah,030h,038h,038h,018h,000h,0c0h,000h,000h,043h,0d2h,043h	; 9ee8  70.A.088.....C.C
	defb 0d7h,0e0h,000h,045h,0e0h,0c0h,000h,000h,041h,0c3h,041h,0d8h,018h,038h,038h,030h	; 9ef8  ...E....A.A..880
	defb 000h,007h,000h,000h,041h,0dah,020h,030h,030h,038h,018h,0d8h,018h,000h,000h,000h	; 9f08  ....A. 008......
	defb 003h,001h,005h,007h,003h,000h,045h,002h,005h,005h,00dh,01ch,038h,000h,000h,0c0h	; 9f18  ......E.....8...
	defb 040h,060h,0e0h,0c0h,0c0h,080h,0b0h,038h,0d8h,0f8h,0f0h,000h,000h,041h,0ech,002h	; 9f28  @`.....8.....A..
	defb 000h,006h,007h,017h,03bh,000h,000h,041h,0eeh,080h,0b0h,030h,070h,0e0h,0d0h,000h	; 9f38  ....;..A...0p...
	defb 000h,041h,0ech,045h,002h,006h,01eh,03dh,000h,000h,041h,0eeh,080h,0b0h,038h,01ch	; 9f48  .A.E...=..A...8.
	defb 00ch,0dch,038h,030h,043h,0eeh,043h,0f3h,043h,0ech,040h,058h,058h,038h,0c8h,0f0h	; 9f58  ..80C.C.C.@XX8..
	defb 000h,000h,043h,0eeh,001h,00dh,00ch,00eh,007h,00bh,001h,000h,043h,0ech,040h,040h	; 9f68  ..C.........C.@@
	defb 058h,078h,078h,080h,0c0h,0f0h,041h,0ffh	; 9f78  Xxx...A.

; ----------------------------------------------------------------------
; DATOS sprites_jugadores_c: Comprimido (0x52CF, 992 bytes): 2048 bytes a
;   0xDC00, los patrones de sprite 128-191 (0x508B)
;   0x9f80..0xa360  (992 bytes)
DATA_sprites_jugadores_c:
	defb 081h,081h,000h,000h,003h,002h,006h,007h,003h,003h,001h,00dh,00ch,00eh,007h,00bh	; 9f80  ................
	defb 000h,000h,000h,000h,0c0h,080h,0a0h,0e0h,0c0h,000h,085h,040h,000h,0e0h,0f0h,000h	; 9f90  ...........@....
	defb 000h,083h,002h,000h,001h,001h,019h,01fh,01fh,000h,01ch,087h,000h,085h,080h,0c0h	; 9fa0  ................
	defb 000h,090h,085h,080h,0b0h,000h,000h,083h,002h,030h,031h,03bh,01fh,00eh,001h,000h	; 9fb0  .........01;....
	defb 000h,081h,006h,000h,090h,080h,000h,000h,0f0h,000h,000h,083h,002h,000h,001h,001h	; 9fc0  ................
	defb 000h,00ch,01bh,003h,000h,081h,006h,000h,090h,0c0h,0e0h,060h,0d0h,080h,000h,083h	; 9fd0  ...........`....
	defb 006h,083h,007h,081h,002h,030h,0b0h,0a0h,080h,0f8h,0fch,000h,000h,083h,006h,000h	; 9fe0  .....0..........
	defb 009h,011h,011h,010h,00eh,000h,000h,081h,002h,000h,080h,080h,0c0h,0c0h,0e0h,078h	; 9ff0  ...............x
	defb 03ch,083h,006h,008h,019h,031h,031h,011h,00dh,000h,000h,081h,002h,000h,085h,080h	; a000  <....11.........
	defb 0f8h,0fch,000h,000h,000h,000h,003h,002h,006h,007h,003h,000h,018h,018h,01ch,00eh	; a010  ................
	defb 006h,001h,000h,000h,000h,000h,080h,080h,087h,0c0h,000h,078h,07ch,00ch,01ch,078h	; a020  ...........x|..x
	defb 070h,000h,007h,00fh,01eh,089h,01ch,038h,08dh,000h,000h,0a0h,060h,0e0h,070h,07ch	; a030  p......8....`.p|
	defb 03fh,00fh,003h,003h,002h,089h,000h,081h,01ch,085h,000h,00ch,00fh,00fh,000h,000h	; a040  ?...............
	defb 081h,01eh,000h,087h,0c0h,0d0h,000h,000h,003h,085h,007h,003h,000h,001h,001h,001h	; a050  ................
	defb 001h,003h,007h,087h,000h,080h,0c0h,000h,0f8h,0f8h,018h,0c8h,0c0h,087h,0c0h,087h	; a060  ................
	defb 000h,081h,01ch,018h,018h,01dh,00fh,007h,085h,000h,081h,01eh,000h,0d8h,0cch,08ch	; a070  ................
	defb 00ch,0e8h,000h,000h,007h,00eh,01eh,089h,01ch,081h,021h,000h,085h,0e0h,070h,07ch	; a080  ..........!...p|
	defb 03fh,00fh,081h,023h,003h,006h,005h,005h,003h,003h,001h,001h,081h,029h,000h,0e0h	; a090  ?..#.........)..
	defb 0c0h,0d8h,0b8h,098h,0c8h,0c0h,081h,02bh,083h,01eh,083h,027h,083h,01ch,083h,025h	; a0a0  .......+...'...%
	defb 083h,036h,083h,02bh,083h,034h,083h,029h,083h,01eh,083h,02fh,083h,01ch,083h,02dh	; a0b0  .6.+.4.).../...-
	defb 083h,032h,083h,023h,083h,030h,083h,021h,083h,02ah,083h,02bh,083h,028h,083h,029h	; a0c0  .2.#.0.!.*.+.(.)
	defb 083h,01eh,083h,01fh,083h,01ch,00ch,00ch,01ch,038h,030h,040h,000h,000h,083h,022h	; a0d0  .........80@..."
	defb 083h,023h,083h,020h,083h,021h,083h,002h,002h,002h,01ah,01dh,01dh,001h,000h,000h	; a0e0  .#. .!..........
	defb 083h,000h,080h,0b0h,038h,098h,0f8h,0f0h,000h,000h,003h,007h,007h,003h,087h,000h	; a0f0  ....8...........
	defb 08fh,000h,080h,089h,070h,038h,038h,085h,038h,070h,087h,000h,083h,002h,002h,000h	; a100  ....p88.8p......
	defb 006h,007h,007h,003h,000h,000h,083h,000h,083h,001h,003h,007h,00fh,087h,00eh,01ch	; a110  ................
	defb 081h,059h,080h,085h,070h,038h,038h,03ch,01eh,00eh,006h,004h,089h,000h,001h,000h	; a120  .Y..p88<........
	defb 001h,001h,087h,000h,085h,000h,001h,087h,000h,0c0h,0f0h,0c0h,0f8h,0fch,00ch,0ech	; a130  ................
	defb 0e0h,085h,0e0h,0c0h,087h,000h,083h,002h,002h,01ah,01ah,01eh,00eh,001h,000h,000h	; a140  ................
	defb 083h,000h,080h,0b0h,038h,01ch,00ch,0dch,038h,030h,001h,000h,001h,003h,087h,007h	; a150  ....8...80......
	defb 00eh,08dh,000h,080h,0e0h,0c0h,0a0h,070h,078h,03ch,01ch,00ch,008h,08bh,000h,081h	; a160  .......px<......
	defb 000h,083h,06bh,081h,002h,083h,069h,083h,06eh,083h,06fh,083h,06ch,083h,06dh,081h	; a170  ..k...i.n.o.l.m.
	defb 000h,083h,057h,081h,002h,083h,055h,083h,066h,083h,067h,083h,064h,083h,065h,081h	; a180  ..W...U.f.g.d.e.
	defb 000h,081h,001h,081h,002h,083h,05dh,083h,062h,083h,063h,083h,060h,081h,059h,083h	; a190  ......].b.c.`.Y.
	defb 05ah,083h,05bh,083h,058h,081h,059h,083h,002h,000h,001h,001h,019h,01fh,01fh,000h	; a1a0  Z.[.X.Y.........
	defb 000h,081h,006h,000h,090h,085h,088h,0b0h,000h,000h,001h,085h,002h,087h,000h,081h	; a1b0  ................
	defb 059h,000h,0e0h,0e0h,085h,0ech,070h,070h,085h,070h,0e0h,087h,000h,083h,002h,081h	; a1c0  Y.....pp.p......
	defb 009h,081h,006h,010h,098h,08ch,00ch,008h,0f0h,000h,000h,003h,085h,006h,007h,007h	; a1d0  ................
	defb 00eh,000h,081h,059h,000h,085h,0e0h,070h,078h,03ch,01eh,081h,063h,003h,007h,00eh	; a1e0  ...Y...px<..c...
	defb 00fh,007h,085h,000h,081h,059h,080h,060h,000h,0e0h,0f0h,030h,040h,070h,081h,093h	; a1f0  .....Y.`...0@p..
	defb 083h,002h,00ch,00dh,005h,000h,000h,003h,003h,000h,081h,006h,000h,090h,0c0h,0e0h	; a200  ................
	defb 060h,0c0h,080h,000h,081h,060h,081h,059h,080h,0d0h,030h,070h,070h,078h,03ch,01eh	; a210  `....`.Y..0ppx<.
	defb 081h,063h,083h,006h,083h,0a3h,081h,002h,083h,0a1h,083h,0a6h,083h,063h,083h,060h	; a220  .c...........c.`
	defb 081h,059h,083h,006h,083h,08fh,081h,002h,083h,08dh,083h,09eh,083h,093h,083h,09ch	; a230  .Y..............
	defb 081h,059h,083h,006h,083h,097h,081h,002h,083h,009h,083h,09ah,083h,063h,083h,098h	; a240  .Y...........c..
	defb 081h,059h,083h,092h,083h,093h,083h,090h,081h,059h,000h,000h,003h,002h,006h,007h	; a250  .Y.......Y......
	defb 003h,001h,005h,00dh,00ch,00ch,038h,073h,000h,000h,000h,000h,0e0h,0a0h,0b0h,0f0h	; a260  ......8s........
	defb 0e0h,0c0h,0d0h,0d8h,09ch,00ch,00ch,0ech,00ch,000h,081h,0c4h,005h,00dh,00ch,01ch	; a270  ................
	defb 018h,03bh,030h,070h,081h,0c6h,0d0h,0d8h,090h,00ch,00ch,0ech,000h,000h,081h,0c4h	; a280  .;0p............
	defb 081h,0c5h,081h,0c6h,0d0h,0cch,08ch,00ch,000h,0e0h,000h,000h,08dh,000h,003h,008h	; a290  ................
	defb 018h,018h,038h,030h,037h,000h,000h,08dh,000h,080h,020h,030h,030h,038h,018h,0dch	; a2a0  ..807..... 008..
	defb 00ch,00eh,081h,0d0h,008h,018h,018h,038h,030h,037h,030h,000h,081h,0d2h,020h,030h	; a2b0  .......8070... 0
	defb 030h,010h,01ch,0ceh,000h,000h,081h,0d0h,018h,038h,038h,030h,000h,007h,000h,000h	; a2c0  0........880....
	defb 081h,0d2h,081h,0d7h,081h,01ch,085h,000h,00ch,00fh,00fh,010h,03ch,081h,01eh,081h	; a2d0  ............<...
	defb 027h,081h,01ch,018h,018h,01dh,00fh,017h,038h,000h,000h,081h,01eh,000h,0c0h,0c0h	; a2e0  '.......8.......
	defb 080h,000h,0f0h,000h,000h,081h,01ch,087h,000h,01eh,03eh,000h,000h,081h,01eh,000h	; a2f0  ..........>.....
	defb 078h,07ch,00ch,01ch,07ch,078h,000h,083h,01eh,000h,085h,003h,001h,00dh,000h,000h	; a300  x|..|x..........
	defb 083h,01ch,085h,000h,0b0h,0b0h,0c0h,0f8h,07ch,083h,01eh,083h,027h,083h,01ch,018h	; a310  ........|...'...
	defb 018h,038h,000h,0f8h,0fch,000h,000h,083h,01eh,008h,01bh,085h,033h,01bh,000h,000h	; a320  .8..........3...
	defb 083h,01ch,087h,000h,0f8h,0fch,000h,000h,000h,08bh,00eh,006h,081h,059h,000h,08dh	; a330  .............Y..
	defb 0e0h,0e0h,0e0h,0c0h,089h,000h,000h,08dh,00eh,00eh,00eh,006h,089h,000h,000h,08bh	; a340  ................
	defb 0e0h,0c0h,081h,059h,08fh,003h,003h,08dh,000h,08fh,0e0h,0e0h,08dh,000h,081h,0ffh	; a350  ...Y............

; ----------------------------------------------------------------------
; DATOS sprites_e400: Comprimido (formato 0x5331, 46 bytes): 128 bytes a
;   0xE400, cuatro patrones de sprite de 16x16 (0x5094)
;   0xa360..0xa38e  (46 bytes)
DATA_sprites_e400:
	defb 0c0h,080h,086h,007h,084h,000h,086h,0c0h,084h,000h,00eh,00ch,01ch,01ch,018h,082h	; a360  ................
	defb 038h,078h,082h,000h,0e0h,060h,070h,070h,030h,082h,038h,03ch,082h,000h,080h,00eh	; a370  8x...`pp0.8<....
	defb 084h,01ch,03ch,082h,000h,080h,0e0h,084h,070h,078h,0a2h,000h,080h,080h	; a380  ..<.....px....

; ----------------------------------------------------------------------
; DATOS colocacion_poses: 40 fichas de ocho bytes, una por cada grupo de
;   cuatro poses (pose >> 2): los cuatro pares (Y, X) relativos de los cuatro
;   sprites de la pose, que 0x6029 copia a los atributos de 0xE650 +
;   jugador*16
;   0xa38e..0xa4ce  (320 bytes)
DATA_colocacion_poses:
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a38e  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a396  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a39e  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a3a6  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3ae  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3b6  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3be  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3c6  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a3ce  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a3d6  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a3de  ....#...
	defb 01bh,007h,00bh,007h,023h,007h,013h,007h	; a3e6  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3ee  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3f6  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a3fe  ....#...
	defb 01bh,008h,00bh,008h,023h,008h,013h,008h	; a406  ....#...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; a40e  ....$...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; a416  ....$...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; a41e  ....$...
	defb 01fh,007h,00fh,007h,024h,007h,014h,007h	; a426  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; a42e  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; a436  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; a43e  ....$...
	defb 01fh,008h,00fh,008h,024h,008h,014h,008h	; a446  ....$...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a44e  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a456  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a45e  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a466  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a46e  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a476  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a47e  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a486  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a48e  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a496  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a49e  ....#...
	defb 01ah,007h,00ah,007h,023h,007h,013h,007h	; a4a6  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a4ae  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a4b6  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a4be  ....#...
	defb 01ah,008h,00ah,008h,023h,008h,013h,008h	; a4c6  ....#...

; ----------------------------------------------------------------------
; DATOS poses: 160 poses de cuatro bytes: los cuatro numeros de patron (de 32
;   bytes, en 0xCC00) que 0x5FE8 copia a la VRAM 0x3800 + jugador*128
;   0xa4ce..0xa74e  (640 bytes)
DATA_poses:
	defb 078h,0bdh,001h,005h	; a4ce
	defb 076h,079h,001h,005h	; a4d2
	defb 07ah,0beh,001h,005h	; a4d6
	defb 076h,077h,001h,005h	; a4da
	defb 0aeh,0afh,003h,00bh	; a4de
	defb 0ach,0adh,003h,00bh	; a4e2
	defb 0aah,0abh,003h,00bh	; a4e6
	defb 0ach,0b0h,003h,00bh	; a4ea
	defb 090h,091h,003h,00bh	; a4ee
	defb 08eh,092h,003h,00bh	; a4f2
	defb 093h,094h,003h,00bh	; a4f6
	defb 08eh,08fh,003h,00bh	; a4fa
	defb 0a0h,0a1h,003h,00bh	; a4fe
	defb 09eh,09fh,003h,00bh	; a502
	defb 09ch,09dh,003h,00bh	; a506
	defb 09eh,0a2h,003h,00bh	; a50a
	defb 06fh,070h,000h,004h	; a50e
	defb 071h,075h,000h,004h	; a512
	defb 073h,074h,000h,004h	; a516
	defb 071h,072h,000h,004h	; a51a
	defb 09ah,09bh,002h,00ah	; a51e
	defb 095h,096h,002h,00ah	; a522
	defb 097h,098h,002h,00ah	; a526
	defb 095h,099h,002h,00ah	; a52a
	defb 087h,088h,002h,00ah	; a52e
	defb 089h,08dh,002h,00ah	; a532
	defb 08bh,08ch,002h,00ah	; a536
	defb 089h,08ah,002h,00ah	; a53a
	defb 0a8h,0a9h,002h,00ah	; a53e
	defb 0a3h,0a4h,002h,00ah	; a542
	defb 0a5h,0a6h,002h,00ah	; a546
	defb 0a3h,0a7h,002h,00ah	; a54a
	defb 0b5h,0bdh,001h,005h	; a54e
	defb 0b4h,079h,001h,005h	; a552
	defb 0b6h,0beh,001h,005h	; a556
	defb 0b4h,077h,001h,005h	; a55a
	defb 086h,0afh,003h,00bh	; a55e
	defb 085h,0adh,003h,00bh	; a562
	defb 084h,0abh,003h,00bh	; a566
	defb 085h,0b0h,003h,00bh	; a56a
	defb 0bch,091h,003h,00bh	; a56e
	defb 0bah,092h,003h,00bh	; a572
	defb 0bbh,094h,003h,00bh	; a576
	defb 0bah,08fh,003h,00bh	; a57a
	defb 080h,0a1h,003h,00bh	; a57e
	defb 07fh,09fh,003h,00bh	; a582
	defb 07eh,09dh,003h,00bh	; a586
	defb 07fh,0a2h,003h,00bh	; a58a
	defb 0b1h,070h,000h,004h	; a58e
	defb 0b2h,075h,000h,004h	; a592
	defb 0b3h,074h,000h,004h	; a596
	defb 0b2h,072h,000h,004h	; a59a
	defb 07dh,09bh,002h,00ah	; a59e
	defb 07bh,096h,002h,00ah	; a5a2
	defb 07ch,098h,002h,00ah	; a5a6
	defb 07bh,099h,002h,00ah	; a5aa
	defb 0b9h,088h,002h,00ah	; a5ae
	defb 0b7h,08dh,002h,00ah	; a5b2
	defb 0b8h,08ch,002h,00ah	; a5b6
	defb 0b7h,08ah,002h,00ah	; a5ba
	defb 083h,0a9h,002h,00ah	; a5be
	defb 081h,0a4h,002h,00ah	; a5c2
	defb 082h,0a6h,002h,00ah	; a5c6
	defb 081h,0a7h,002h,00ah	; a5ca
	defb 04ah,04bh,001h,005h	; a5ce
	defb 04ch,04bh,001h,005h	; a5d2
	defb 061h,04bh,001h,005h	; a5d6
	defb 062h,04bh,001h,005h	; a5da
	defb 05ch,05dh,003h,0c0h	; a5de
	defb 05eh,05dh,003h,0c0h	; a5e2
	defb 06dh,05dh,003h,0c0h	; a5e6
	defb 06eh,05dh,003h,0c0h	; a5ea
	defb 050h,051h,003h,00dh	; a5ee
	defb 052h,051h,003h,00dh	; a5f2
	defb 065h,051h,003h,00dh	; a5f6
	defb 066h,051h,003h,00dh	; a5fa
	defb 056h,057h,003h,0c0h	; a5fe
	defb 058h,057h,003h,0c0h	; a602
	defb 069h,057h,003h,0c0h	; a606
	defb 06ah,057h,003h,0c0h	; a60a
	defb 047h,048h,000h,004h	; a60e
	defb 049h,048h,000h,004h	; a612
	defb 05fh,048h,000h,004h	; a616
	defb 060h,048h,000h,004h	; a61a
	defb 053h,054h,002h,0bfh	; a61e
	defb 055h,054h,002h,0bfh	; a622
	defb 067h,054h,002h,0bfh	; a626
	defb 068h,054h,002h,0bfh	; a62a
	defb 04dh,04eh,002h,00ch	; a62e
	defb 04fh,04eh,002h,00ch	; a632
	defb 063h,04eh,002h,00ch	; a636
	defb 064h,04eh,002h,00ch	; a63a
	defb 059h,05ah,002h,0bfh	; a63e
	defb 05bh,05ah,002h,0bfh	; a642
	defb 06bh,05ah,002h,0bfh	; a646
	defb 06ch,05ah,002h,0bfh	; a64a
	defb 03ah,0c2h,001h,005h	; a64e
	defb 03bh,0c2h,001h,005h	; a652
	defb 027h,0c2h,001h,005h	; a656
	defb 031h,0c2h,001h,005h	; a65a
	defb 045h,01ch,003h,00bh	; a65e
	defb 046h,01ch,003h,00bh	; a662
	defb 02fh,01ch,003h,00bh	; a666
	defb 037h,01ch,003h,00bh	; a66a
	defb 03eh,014h,003h,007h	; a66e
	defb 03fh,014h,003h,007h	; a672
	defb 02ah,02bh,003h,00bh	; a676
	defb 033h,02bh,003h,00bh	; a67a
	defb 042h,018h,003h,009h	; a67e
	defb 043h,018h,003h,009h	; a682
	defb 02dh,018h,003h,00bh	; a686
	defb 035h,018h,003h,00bh	; a68a
	defb 038h,026h,000h,004h	; a68e
	defb 039h,026h,000h,004h	; a692
	defb 025h,026h,000h,004h	; a696
	defb 030h,026h,000h,004h	; a69a
	defb 040h,016h,002h,008h	; a69e
	defb 041h,016h,002h,008h	; a6a2
	defb 02ch,016h,002h,00ah	; a6a6
	defb 034h,016h,002h,00ah	; a6aa
	defb 03ch,012h,002h,006h	; a6ae
	defb 03dh,012h,002h,006h	; a6b2
	defb 028h,029h,002h,00ah	; a6b6
	defb 032h,029h,002h,00ah	; a6ba
	defb 044h,01ah,002h,00ah	; a6be
	defb 044h,01ah,002h,00ah	; a6c2
	defb 02eh,01ah,002h,00ah	; a6c6
	defb 036h,01ah,002h,00ah	; a6ca
	defb 010h,0c1h,001h,005h	; a6ce
	defb 01eh,0c1h,001h,005h	; a6d2
	defb 000h,000h,000h,000h	; a6d6
	defb 000h,000h,000h,000h	; a6da
	defb 01bh,01ch,003h,00bh	; a6de
	defb 024h,01ch,003h,00bh	; a6e2
	defb 000h,000h,000h,000h	; a6e6
	defb 000h,000h,000h,000h	; a6ea
	defb 013h,014h,003h,007h	; a6ee
	defb 020h,014h,003h,007h	; a6f2
	defb 000h,000h,000h,000h	; a6f6
	defb 000h,000h,000h,000h	; a6fa
	defb 017h,018h,003h,009h	; a6fe
	defb 022h,018h,003h,009h	; a702
	defb 000h,000h,000h,000h	; a706
	defb 000h,000h,000h,000h	; a70a
	defb 00eh,00fh,000h,004h	; a70e
	defb 01dh,00fh,000h,004h	; a712
	defb 000h,000h,000h,000h	; a716
	defb 000h,000h,000h,000h	; a71a
	defb 015h,016h,002h,008h	; a71e
	defb 021h,016h,002h,008h	; a722
	defb 000h,000h,000h,000h	; a726
	defb 000h,000h,000h,000h	; a72a
	defb 011h,012h,002h,006h	; a72e
	defb 01fh,012h,002h,006h	; a732
	defb 000h,000h,000h,000h	; a736
	defb 000h,000h,000h,000h	; a73a
	defb 019h,01ah,002h,00ah	; a73e
	defb 023h,01ah,002h,00ah	; a742
	defb 000h,000h,000h,000h	; a746
	defb 000h,000h,000h,000h	; a74a

; ----------------------------------------------------------------------
; DATOS patrones_pista: Comprimido (0x52CF, 1114 bytes): 2000 bytes, los 250
;   patrones de 8x8 de la pista, los menus y la fuente; 0x50AC los descomprime
;   en 0xC400 y 0x50C1 los copia a los tres tercios de la tabla de patrones
;   0xa74e..0xaba8  (1114 bytes)
DATA_patrones_pista:
	defb 0f0h,050h,057h,000h,0ffh,056h,000h,0ffh,052h,000h,008h,03eh,01ch,01ch,0ffh,000h	; a74e  .PW..V..R..>....
	defb 000h,03eh,052h,073h,07fh,0ffh,000h,000h,07eh,073h,073h,07eh,073h,0ffh,000h,000h	; a75e  .>Rs....~ss~s...
	defb 07eh,053h,073h,0ffh,000h,000h,07fh,070h,070h,07eh,070h,0ffh,000h,000h,052h,073h	; a76e  ~Ss....pp~p...Rs
	defb 07fh,073h,0ffh,000h,000h,073h,073h,076h,07ch,076h,0ffh,000h,000h,054h,070h,0ffh	; a77e  .s...ssv|v...Tp.
	defb 000h,000h,073h,07bh,07fh,077h,073h,0ffh,000h,000h,03eh,053h,073h,0ffh,000h,000h	; a78e  ..s{.ws...>Ss...
	defb 07eh,052h,073h,07eh,0ffh,000h,000h,03eh,073h,070h,03eh,003h,0ffh,000h,000h,07fh	; a79e  ~Rs~...>sp>.....
	defb 053h,01ch,0ffh,000h,000h,054h,073h,0ffh,000h,000h,052h,073h,03eh,01ch,0bbh,052h	; a7ae  S....Ts...Rs>..R
	defb 03bh,053h,077h,051h,011h,053h,0efh,053h,0dfh,051h,013h,050h,000h,036h,056h,000h	; a7be  ;SwQ.S.S.Q.P.6V.
	defb 073h,073h,055h,000h,073h,07eh,055h,000h,070h,070h,055h,000h,070h,07fh,055h,000h	; a7ce  ssU.s~U.ppU.p.U.
	defb 073h,03eh,055h,000h,01ch,01ch,055h,000h,076h,073h,055h,000h,036h,052h,000h,053h	; a7de  s>U...U.vsU.6R.S
	defb 001h,036h,052h,000h,053h,080h,050h,000h,03eh,03eh,02ah,03eh,01ch,03eh,07fh,07fh	; a7ee  .6R.S.P.>>*>.>..
	defb 000h,01ch,03eh,02ah,03eh,01ch,03eh,07fh,03eh,07fh,063h,063h,077h,03eh,07fh,07fh	; a7fe  ..>*>.>.>.ccw>..
	defb 03eh,07fh,063h,063h,036h,01ch,07fh,07fh,000h,03eh,07fh,063h,063h,01ch,03eh,07fh	; a80e  >.cc6....>.cc.>.
	defb 050h,021h,03eh,07fh,063h,063h,077h,063h,07fh,07fh,000h,01ch,03eh,03eh,02ah,03eh	; a81e  P!>.ccwc....>>*>
	defb 01ch,07fh,050h,023h,050h,022h,050h,021h,053h,00fh,053h,01dh,051h,02ch,00ch,01ch	; a82e  ..P#P"P!S.S.Q,..
	defb 00ch,00ch,01eh,000h,0ffh,000h,00eh,013h,006h,00ch,01fh,000h,0ffh,000h,03eh,063h	; a83e  ..............>c
	defb 063h,052h,073h,03eh,000h,01ch,03ch,053h,01ch,03eh,000h,03eh,067h,007h,01ch,030h	; a84e  cRs>..<S.>.>g..0
	defb 070h,07fh,000h,03eh,067h,007h,01eh,007h,067h,03eh,000h,00eh,01eh,036h,066h,066h	; a85e  p..>g...g>...6ff
	defb 07fh,006h,000h,07fh,060h,060h,07eh,007h,007h,07eh,000h,01eh,030h,070h,07eh,073h	; a86e  ....``~..~..0p~s
	defb 073h,03eh,000h,07fh,043h,006h,00ch,052h,01ch,000h,03eh,073h,073h,03eh,073h,073h	; a87e  s>..C..R..>ss>ss
	defb 03eh,000h,03eh,073h,073h,03fh,003h,006h,03ch,000h,000h,00ch,00ch,000h,00ch,00ch	; a88e  >.>ss?..<.......
	defb 000h,000h,054h,000h,018h,018h,000h,052h,000h,03eh,053h,000h,000h,000h,03eh,000h	; a89e  ..T....R.>S...>.
	defb 03eh,052h,000h,018h,03ch,03ch,018h,000h,018h,018h,000h,03eh,067h,007h,00eh,018h	; a8ae  >R..<<.....>g...
	defb 000h,018h,018h,03ch,042h,09dh,0b1h,0b1h,09dh,042h,03ch,03eh,052h,073h,07fh,073h	; a8be  ...<B....B<>Rs.s
	defb 073h,000h,07eh,073h,073h,07eh,073h,073h,07eh,000h,03eh,073h,073h,070h,073h,073h	; a8ce  s.~ss~ss~.>sspss
	defb 03eh,000h,07eh,054h,073h,07eh,000h,07fh,070h,070h,07eh,070h,070h,07fh,000h,07fh	; a8de  >.~Ts~..pp~pp...
	defb 070h,070h,07eh,052h,070h,000h,03eh,073h,070h,077h,073h,073h,03eh,000h,052h,073h	; a8ee  pp~Rp.>spwss>.Rs
	defb 07fh,052h,073h,000h,03eh,054h,01ch,03eh,000h,01fh,052h,00eh,06eh,06eh,03ch,000h	; a8fe  .Rs.>T.>..R.nn<.
	defb 073h,076h,07ch,078h,07ch,076h,073h,000h,054h,070h,071h,07fh,000h,063h,077h,07fh	; a90e  sv|x|vs.Tpq..cw.
	defb 06bh,052h,063h,000h,073h,07bh,07fh,077h,052h,073h,000h,03eh,054h,073h,03eh,000h	; a91e  kRc.s{.wRs.>Ts>.
	defb 07eh,052h,073h,07eh,070h,070h,000h,03eh,052h,073h,07fh,072h,03dh,000h,07eh,052h	; a92e  ~Rs~pp.>Rs.r=.~R
	defb 073h,07eh,076h,073h,000h,03eh,073h,070h,03eh,007h,067h,03eh,000h,07fh,055h,01ch	; a93e  s~vs.>sp>.g>..U.
	defb 000h,055h,073h,03eh,000h,054h,073h,03eh,01ch,000h,063h,06bh,06bh,07fh,07fh,036h	; a94e  .Us>.Ts>..ckk..6
	defb 036h,000h,073h,073h,03eh,01ch,03eh,073h,073h,000h,052h,073h,03eh,052h,01ch,000h	; a95e  6.ss>.>ss.Rs>R..
	defb 07fh,047h,00eh,01ch,038h,071h,07fh,000h,018h,018h,008h,010h,053h,000h,006h,026h	; a96e  .G..8q......S..&
	defb 007h,026h,006h,000h,0ffh,000h,067h,06ch,0ech,06fh,06ch,000h,0ffh,000h,098h,052h	; a97e  .&....gl.ol....R
	defb 0d8h,0dfh,000h,0ffh,000h,07ch,060h,078h,060h,060h,000h,0ffh,000h,00fh,03fh,038h	; a98e  .....|`x``....?8
	defb 077h,06fh,06eh,06ch,06ch,051h,060h,06ch,06eh,06fh,077h,038h,03fh,00fh,000h,051h	; a99e  wonllQ`lnow8?..Q
	defb 062h,0ffh,0ffh,000h,0ffh,0ffh,052h,000h,000h,000h,0ffh,0ffh,000h,0ffh,0ffh,000h	; a9ae  b.....R.........
	defb 057h,06ch,051h,066h,0ffh,0ffh,000h,0ffh,0ffh,052h,01ch,01ch,01ch,0ffh,0ffh,000h	; a9be  WlQf.....R......
	defb 0ffh,0ffh,000h,057h,01ch,054h,000h,008h,000h,000h,056h,07eh,000h,050h,06ch,03ch	; a9ce  ...W.T....V~.Pl<
	defb 07eh,0e7h,0c3h,0c3h,0e7h,07eh,03ch,050h,06eh,050h,054h,050h,046h,056h,03ch,000h	; a9de  ~....~<PnPTPFV<.
	defb 050h,072h,054h,000h,052h,0ffh,052h,000h,053h,0ffh,000h,053h,003h,000h,0f7h,0f7h	; a9ee  PrT.R.R.S..S....
	defb 007h,051h,076h,057h,007h,051h,078h,053h,0bfh,053h,07eh,051h,07ah,053h,07ch,053h	; a9fe  .QvW.QxS.S~QzS|S
	defb 078h,051h,07ch,053h,070h,053h,060h,051h,07eh,053h,040h,053h,000h,051h,080h,052h	; aa0e  xQ|SpS`Q~S@S.Q.R
	defb 007h,053h,0f7h,007h,051h,082h,050h,000h,057h,001h,051h,085h,053h,0e0h,053h,0c0h	; aa1e  .S..Q.P.W.Q.S.S.
	defb 051h,087h,050h,087h,051h,087h,053h,080h,053h,000h,051h,08bh,050h,08bh,051h,08bh	; aa2e  Q.P.Q.S.S.Q.P.Q.
	defb 050h,000h,050h,085h,051h,085h,057h,003h,051h,092h,0ffh,0ffh,055h,000h,055h,000h	; aa3e  P.P.Q.W.Q...U.U.
	defb 0ffh,0ffh,0ffh,0ffh,055h,001h,051h,096h,055h,001h,0ffh,0ffh,051h,098h,056h,000h	; aa4e  ....U.Q.U...Q.V.
	defb 0f0h,0feh,01fh,003h,001h,053h,000h,000h,000h,0c0h,0e0h,070h,038h,018h,00ch,00ch	; aa5e  .....S.....p8...
	defb 055h,006h,00ch,0f0h,056h,000h,053h,000h,001h,003h,01fh,0feh,00ch,018h,038h,070h	; aa6e  U...V.S.......8p
	defb 0e0h,0c0h,000h,000h,051h,09dh,051h,09ch,051h,09bh,051h,09ah,051h,0a0h,051h,09fh	; aa7e  ....Q.Q.Q.Q.Q.Q.
	defb 051h,09eh,052h,000h,0ffh,0ffh,052h,000h,053h,000h,0ffh,0ffh,000h,000h,054h,000h	; aa8e  Q.R...R.S.....T.
	defb 0fch,0ffh,003h,055h,000h,0e0h,0fch,01fh,003h,055h,000h,080h,0f0h,07ch,00fh,003h	; aa9e  ...U.....U...|..
	defb 052h,000h,053h,000h,080h,0e0h,070h,018h,00ch,006h,003h,001h,001h,052h,000h,052h	; aaae  R.S...p......R.R
	defb 000h,080h,0c0h,0c0h,060h,060h,030h,052h,018h,052h,00ch,006h,052h,006h,054h,003h	; aabe  ....``0R.R..R.T.
	defb 003h,003h,054h,006h,00ch,00ch,00ch,052h,018h,030h,030h,060h,060h,0c0h,0c0h,080h	; aace  ..T....R.00``...
	defb 053h,000h,000h,000h,001h,003h,003h,006h,00eh,01ch,038h,070h,0e0h,0c0h,080h,052h	; aade  S.........8p...R
	defb 000h,052h,000h,001h,003h,00eh,03ch,0f0h,0c0h,056h,000h,003h,01fh,0fch,0e0h,053h	; aaee  .R....<..V.....S
	defb 000h,052h,000h,007h,07fh,0f8h,080h,000h,054h,000h,007h,0ffh,0f8h,056h,000h,0ffh	; aafe  .R......T....V..
	defb 050h,001h,051h,0b2h,051h,0b1h,051h,0b0h,051h,0afh,051h,0aeh,051h,0adh,051h,0ach	; ab0e  P.Q.Q.Q.Q.Q.Q.Q.
	defb 051h,0abh,051h,0aah,051h,0b3h,051h,0b4h,051h,0b5h,051h,0b6h,051h,0b7h,051h,0b8h	; ab1e  Q.Q.Q.Q.Q.Q.Q.Q.
	defb 051h,0b9h,051h,0bah,051h,0bbh,051h,0bch,050h,000h,050h,085h,051h,085h,050h,092h	; ab2e  Q.Q.Q.Q.P.P.Q.P.
	defb 051h,092h,053h,001h,053h,003h,051h,0d7h,053h,007h,053h,00fh,051h,0d9h,053h,07fh	; ab3e  Q.S.S.Q.S.S.Q.S.
	defb 053h,0ffh,051h,0dbh,056h,0ffh,0f0h,051h,0ddh,0f0h,056h,0ffh,051h,0dfh,0ffh,0feh	; ab4e  S.Q.V..Q..V.Q...
	defb 0f8h,0f0h,0e0h,0c0h,0c0h,080h,051h,0e1h,080h,0c0h,0c0h,0e0h,0f0h,0f8h,0feh,0ffh	; ab5e  ......Q.........
	defb 051h,0e3h,050h,085h,051h,085h,050h,085h,051h,085h,050h,085h,051h,085h,050h,085h	; ab6e  Q.P.Q.P.Q.P.Q.P.
	defb 051h,085h,080h,055h,001h,080h,051h,0edh,080h,052h,000h,007h,01fh,03fh,07fh,051h	; ab7e  Q..U..Q..R...?.Q
	defb 0efh,07fh,03fh,01fh,007h,052h,000h,080h,051h,0f1h,050h,000h,050h,0d7h,051h,0d7h	; ab8e  ..?..R..Q.P.P.Q.
	defb 050h,0d9h,051h,0d9h,050h,0dbh,051h,0dbh,050h,0ffh	; ab9e  P.Q.P.Q.P.

; ----------------------------------------------------------------------
; DATOS colores_area_1: Comprimido (formato 0x5373, 264 bytes): los 2000 bytes
;   de color de los 250 patrones de la pista con la primera AREA del menu
;   (0x785A)
;   0xaba8..0xacb0  (264 bytes)
DATA_colores_area_1:
	defb 000h,003h,0f1h,0f1h,000h,051h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; aba8  .....Q..........
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; abb8  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; abc8  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; abd8  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h	; abe8  ................
	defb 0f1h,0f1h,0f4h,0f4h,000h,001h,0f8h,0f6h,0f1h,0f1h,0f4h,0f4h,001h,04fh,0f1h,0f1h	; abf8  .............O..
	defb 000h,002h,0f4h,0f4h,0f4h,0e4h,000h,001h,0f4h,0f4h,0f4h,0e4h,0e4h,0f4h,000h,002h	; ac08  ................
	defb 0f4h,0f4h,0f4h,0feh,000h,002h,0f4h,0f4h,0f4h,0feh,000h,033h,0f4h,0f4h,000h,007h	; ac18  ...........3....
	defb 0f7h,0f7h,04fh,04fh,000h,002h,04ch,042h,04fh,04fh,000h,005h,04ch,042h,04fh,04fh	; ac28  ..OO..LBOO..LBOO
	defb 000h,002h,04ch,042h,04fh,04fh,000h,002h,04ch,042h,04fh,04fh,000h,002h,04ch,042h	; ac38  ..LBOO..LBOO..LB
	defb 04fh,04fh,04ch,042h,04ch,04fh,04fh,042h,000h,001h,04ch,042h,04ch,04fh,04fh,042h	; ac48  OOLBLOOB..LBLOOB
	defb 04ch,042h,001h,00bh,0fch,0f2h,000h,013h,0fch,0fch,000h,017h,0c4h,024h,000h,01fh	; ac58  LB...........$..
	defb 0c7h,027h,000h,002h,0fch,0f2h,0f7h,0f7h,000h,002h,0fch,0f2h,000h,001h,0f7h,0f7h	; ac68  .'..............
	defb 000h,002h,0fch,0f2h,0f7h,0f7h,000h,002h,0fch,0f2h,000h,001h,0fch,0fch,0fch,0f7h	; ac78  ................
	defb 0f7h,0f7h,000h,001h,0fch,0fch,0fch,0f7h,000h,001h,0f7h,0f7h,0f7h,0fch,000h,001h	; ac88  ................
	defb 0fch,0fch,0f7h,0f7h,0f7h,0fch,000h,001h,0fch,0fch,000h,017h,0c7h,0c7h,000h,003h	; ac98  ................
	defb 027h,027h,000h,017h,0c4h,0c4h,000h,000h	; aca8  ''......

; ----------------------------------------------------------------------
; DATOS colores_area_2: Comprimido (0x5373, 264 bytes): los 2000 bytes de
;   color de la segunda AREA
;   0xacb0..0xadb8  (264 bytes)
DATA_colores_area_2:
	defb 000h,003h,0f1h,0f1h,000h,051h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; acb0  .....Q..........
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; acc0  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; acd0  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; ace0  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h	; acf0  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f8h,0f6h,0f1h,0f1h,0fch,0fch,001h,04fh,0f1h,0f1h	; ad00  .............O..
	defb 000h,002h,0fch,0fch,0fch,0ech,000h,001h,0fch,0fch,0fch,0ech,0ech,0fch,000h,002h	; ad10  ................
	defb 0fch,0fch,0fch,0feh,000h,002h,0fch,0fch,0fch,0feh,000h,033h,0fch,0fch,000h,007h	; ad20  ...........3....
	defb 0f7h,0f7h,0cfh,0cfh,000h,002h,0c4h,0c5h,0cfh,0cfh,000h,005h,0c4h,0c5h,0cfh,0cfh	; ad30  ................
	defb 000h,002h,0c4h,0c5h,0cfh,0cfh,000h,002h,0c4h,0c5h,0cfh,0cfh,000h,002h,0c4h,0c5h	; ad40  ................
	defb 0cfh,0cfh,0c4h,0c5h,0c4h,0cfh,0cfh,0c5h,000h,001h,0c4h,0c5h,0c4h,0cfh,0cfh,0c5h	; ad50  ................
	defb 0c4h,0c5h,001h,00bh,0f4h,0f5h,000h,013h,0f4h,0f4h,000h,017h,04ch,05ch,000h,01fh	; ad60  ............L\..
	defb 047h,057h,000h,002h,0f4h,0f5h,0f7h,0f7h,000h,002h,0f4h,0f5h,000h,001h,0f7h,0f7h	; ad70  GW..............
	defb 000h,002h,0f4h,0f5h,0f7h,0f7h,000h,002h,0f4h,0f5h,000h,001h,0f4h,0f4h,0f4h,0f7h	; ad80  ................
	defb 0f7h,0f7h,000h,001h,0f4h,0f4h,0f4h,0f7h,000h,001h,0f7h,0f7h,0f7h,0f4h,000h,001h	; ad90  ................
	defb 0f4h,0f4h,0f7h,0f7h,0f7h,0f4h,000h,001h,0f4h,0f4h,000h,017h,047h,047h,000h,003h	; ada0  ............GG..
	defb 057h,057h,000h,017h,04ch,04ch,000h,000h	; adb0  WW..LL..

; ----------------------------------------------------------------------
; DATOS colores_area_3: Comprimido (0x5373, 264 bytes): los 2000 bytes de
;   color de la tercera AREA
;   0xadb8..0xaec0  (264 bytes)
DATA_colores_area_3:
	defb 000h,003h,0f1h,0f1h,000h,051h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; adb8  .....Q..........
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; adc8  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; add8  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; ade8  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h	; adf8  ................
	defb 0f1h,0f1h,0fch,0fch,000h,001h,0f5h,0f4h,0f1h,0f1h,0fch,0fch,001h,04fh,0f1h,0f1h	; ae08  .............O..
	defb 000h,002h,0fch,0fch,0fch,0ech,000h,001h,0fch,0fch,0fch,0ech,0ech,0fch,000h,002h	; ae18  ................
	defb 0fch,0fch,0fch,0feh,000h,002h,0fch,0fch,0fch,0feh,000h,033h,0fch,0fch,000h,007h	; ae28  ...........3....
	defb 0f7h,0f7h,0cfh,0cfh,000h,002h,0c6h,0c8h,0cfh,0cfh,000h,005h,0c6h,0c8h,0cfh,0cfh	; ae38  ................
	defb 000h,002h,0c6h,0c8h,0cfh,0cfh,000h,002h,0c6h,0c8h,0cfh,0cfh,000h,002h,0c6h,0c8h	; ae48  ................
	defb 0cfh,0cfh,0c6h,0c8h,0c6h,0cfh,0cfh,0c8h,000h,001h,0c6h,0c8h,0c6h,0cfh,0cfh,0c8h	; ae58  ................
	defb 0c6h,0c8h,001h,00bh,0f6h,0f8h,000h,013h,0f6h,0f6h,000h,017h,06ch,08ch,000h,01fh	; ae68  ............l...
	defb 067h,087h,000h,002h,0f6h,0f8h,0f7h,0f7h,000h,002h,0f6h,0f8h,000h,001h,0f7h,0f7h	; ae78  g...............
	defb 000h,002h,0f6h,0f8h,0f7h,0f7h,000h,002h,0f6h,0f8h,000h,001h,0f6h,0f6h,0f6h,0f7h	; ae88  ................
	defb 0f7h,0f7h,000h,001h,0f6h,0f6h,0f6h,0f7h,000h,001h,0f7h,0f7h,0f7h,0f6h,000h,001h	; ae98  ................
	defb 0f6h,0f6h,0f7h,0f7h,0f7h,0f6h,000h,001h,0f6h,0f6h,000h,017h,067h,067h,000h,003h	; aea8  ............gg..
	defb 087h,087h,000h,017h,06ch,06ch,000h,000h	; aeb8  ....ll..

; ----------------------------------------------------------------------
; DATOS colores_2100: Comprimido (formato 0x535B, 159 bytes): 672 bytes de
;   color para los patrones 0x20-0x73 del primer tercio (VRAM 0x2100), que
;   0x7842 pone encima del area
;   0xaec0..0xaf5f  (159 bytes)
DATA_colores_2100:
	defb 0ffh,000h,000h,0f1h,008h,014h,014h,0b4h,0b4h,0a4h,084h,084h,084h,014h,014h,014h	; aec0  ................
	defb 0b4h,0b4h,0a4h,074h,074h,014h,014h,01bh,01bh,01ah,0f4h,0f4h,0f4h,014h,014h,01bh	; aed0  ...tt...........
	defb 01bh,01ah,0b4h,094h,094h,014h,014h,014h,01bh,01bh,0a4h,0d4h,064h,014h,014h,0b4h	; aee0  ............d...
	defb 0b4h,0a4h,064h,0a4h,064h,014h,014h,01bh,01bh,01ah,01bh,034h,034h,000h,014h,004h	; aef0  ..d.d......44...
	defb 0b4h,0b4h,0a4h,0f4h,014h,014h,01bh,01bh,01ah,094h,0d4h,0b4h,014h,014h,014h,0b4h	; af00  ................
	defb 0b4h,0a4h,094h,094h,014h,014h,0b4h,0b4h,0a4h,000h,0f4h,013h,000h,021h,006h,081h	; af10  .............!..
	defb 000h,021h,007h,081h,021h,000h,0f1h,0ffh,000h,0f1h,061h,000h,021h,006h,081h,000h	; af20  .!..!.....a.!...
	defb 021h,007h,081h,000h,021h,007h,081h,000h,021h,007h,081h,021h,000h,0a1h,058h,000h	; af30  !...!...!..!..X.
	defb 0f1h,008h,000h,021h,008h,000h,081h,008h,041h,041h,000h,045h,004h,041h,041h,081h	; af40  ...!....AA.E.AA.
	defb 081h,000h,089h,004h,000h,081h,012h,000h,041h,008h,000h,081h,008h,000h,000h	; af50  ........A......

; ----------------------------------------------------------------------
; DATOS jugadas: Comprimido (0x52CF, 415 bytes): 720 bytes a 0xEA89 (0x5197),
;   los guiones de jugada de la maquina: 5 formaciones x 6 variantes x 3
;   jugadores x 8 bytes (0x6F48 indexa 144 por formacion y 24 por variante, la
;   variante es 2 x A mas un bit al azar); cada guion es un byte de espera y
;   puntos (Y, X, codigo) hasta un 0x80
;   0xaf5f..0xb0fe  (415 bytes)
DATA_jugadas:
	defb 0c0h,0c0h,000h,080h,0c4h,000h,080h,000h,018h,024h,064h,080h,000h,000h,080h,0c0h	; af5f  .........$d.....
	defb 000h,0c0h,000h,000h,060h,034h,000h,080h,000h,000h,080h,000h,01ah,05ah,064h,080h	; af6f  ....`4.......Zd.
	defb 000h,000h,080h,0c0h,001h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h,000h,000h,05ch,024h	; af7f  ..............\$
	defb 064h,080h,000h,000h,080h,0c0h,000h,0c0h,00bh,0c0h,000h,000h,05ah,05ah,064h,080h	; af8f  d...........ZZd.
	defb 000h,000h,080h,000h,014h,034h,000h,080h,000h,000h,080h,0c0h,000h,0c0h,000h,0c0h	; af9f  .....4..........
	defb 000h,000h,03bh,060h,064h,080h,000h,000h,080h,0c0h,000h,000h,030h,055h,064h,05ah	; afaf  ..;`d.......0UdZ
	defb 05ah,028h,080h,0c0h,000h,000h,039h,060h,064h,080h,000h,000h,080h,0c0h,000h,0c0h	; afbf  Z(....9`d.......
	defb 000h,0c0h,000h,0c0h,000h,0c0h,014h,0c0h,018h,0c0h,000h,0c0h,000h,0c0h,000h,000h	; afcf  ................
	defb 044h,055h,064h,01ah,05ah,028h,080h,0c0h,000h,0c0h,000h,000h,028h,040h,078h,080h	; afdf  DUd.Z(......(@x.
	defb 000h,000h,080h,0c0h,000h,0c0h,000h,0c0h,000h,000h,028h,04eh,078h,080h,000h,000h	; afef  ..........(Nx...
	defb 080h,000h,030h,036h,078h,080h,000h,000h,080h,0c0h,000h,0c0h,000h,0c0h,000h,0c0h	; afff  ..06x...........
	defb 000h,000h,044h,036h,078h,080h,000h,000h,080h,0c0h,000h,000h,04ch,040h,078h,080h	; b00f  ..D6x.......L@x.
	defb 000h,000h,080h,0c0h,000h,000h,04ch,04ch,078h,080h,000h,000h,080h,0c0h,000h,0c0h	; b01f  ......LLx.......
	defb 000h,000h,034h,05ch,064h,024h,038h,03ch,080h,000h,020h,032h,078h,080h,000h,000h	; b02f  ..4\d$8<.. 2x...
	defb 080h,0c0h,000h,000h,024h,038h,000h,034h,05ch,064h,080h,000h,014h,032h,078h,080h	; b03f  ....$8.4\d...2x.
	defb 000h,000h,080h,0c0h,000h,000h,01ch,030h,078h,080h,000h,000h,080h,000h,030h,03ch	; b04f  .......0x.....0<
	defb 000h,03ah,05ah,03ch,080h,0c0h,000h,0c0h,000h,000h,044h,03ch,000h,03ah,05ah,03ch	; b05f  .:Z<......D<.:Z<
	defb 080h,000h,058h,030h,078h,080h,000h,000h,080h,0c0h,000h,000h,054h,038h,078h,080h	; b06f  ..X0x.......T8x.
	defb 000h,000h,080h,000h,040h,05ch,064h,050h,038h,03ch,080h,0c0h,000h,000h,060h,032h	; b07f  ....@\dP8<....`2
	defb 078h,080h,000h,000h,080h,000h,050h,038h,000h,040h,05ch,064h,080h,000h,018h,02ch	; b08f  x.....P8.@\d...,
	defb 000h,03ah,024h,000h,080h,01eh,024h,038h,078h,080h,000h,000h,080h,000h,03ah,05ah	; b09f  .:$...$8x.....:Z
	defb 064h,080h,000h,000h,080h,0c0h,048h,03ch,034h,048h,000h,03ah,05ah,064h,080h,000h	; b0af  d.....H<4H.:Zd..
	defb 024h,038h,078h,080h,000h,000h,080h,0c0h,04dh,0c0h,000h,000h,03ah,05ch,064h,080h	; b0bf  $8x.....M...:\d.
	defb 000h,000h,080h,0c0h,050h,0c0h,000h,000h,050h,038h,078h,080h,000h,000h,080h,0c0h	; b0cf  ....P...P8x.....
	defb 04ah,01eh,050h,038h,078h,080h,000h,000h,080h,000h,05ch,02ch,000h,03ah,024h,000h	; b0df  J.P8x.....\,.:$.
	defb 080h,0c0h,053h,03ch,02ch,034h,000h,03ah,05ah,064h,080h,0c0h,056h,0c0h,0ffh	; b0ef  ..S<,4.:Zd..V..

; ----------------------------------------------------------------------
; DATOS nombres_titulo: Comprimido (0x5331, 300 bytes): 544 bytes, las 17
;   filas de la tabla de nombres de la pantalla de titulo (0x836F -> VRAM
;   0x1800)
;   0xb0fe..0xb22a  (300 bytes)
DATA_nombres_titulo:
	defb 0e0h,000h,01fh,020h,020h,0e4h,0e3h,0e5h,0ddh,000h,020h,053h,055h,050h,045h,052h	; b0fe  ...  ..... SUPER
	defb 020h,050h,04ch,041h,059h,045h,052h,053h,020h,020h,0e4h,0e3h,0e3h,0e5h,003h,020h	; b10e   PLAYERS  ..... 
	defb 0cch,0ceh,0c4h,0deh,0e5h,0e4h,0e5h,009h,020h,0e6h,0e7h,0e5h,000h,0c0h,0dbh,003h	; b11e  ........ .......
	defb 020h,0c1h,0e1h,0c1h,0c1h,0e1h,0c1h,0deh,0e5h,0e4h,0e5h,003h,020h,0e4h,0e5h,0e4h	; b12e   ........... ...
	defb 0c3h,0ceh,0c4h,0e1h,0c1h,0e1h,004h,020h,0c1h,0e1h,0c1h,0c1h,0e1h,0c1h,0c0h,0d5h	; b13e  ....... ........
	defb 0c1h,0deh,0e5h,0e4h,0e5h,0e6h,0e7h,0e5h,0c1h,0e1h,0c1h,0c1h,0e1h,0c1h,0e1h,0c1h	; b14e  ................
	defb 0e1h,001h,020h,000h,0edh,0c1h,0dfh,0c1h,0c1h,0e1h,0c1h,0c1h,0d6h,0c1h,0c1h,0e1h	; b15e  .. .............
	defb 0c1h,0ebh,0c2h,0ceh,0c4h,0c1h,0deh,0c1h,0c1h,0e1h,0c1h,0e1h,0c1h,0e1h,001h,0edh	; b16e  ................
	defb 000h,0f1h,0cfh,0cfh,0cbh,0d0h,0dfh,0c1h,0c1h,0e1h,0c1h,0c1h,0d7h,0d9h,0eah,0d0h	; b17e  ................
	defb 0e0h,0d1h,0cch,0cdh,0c1h,0d0h,0dfh,0c1h,0e1h,0cbh,0e1h,001h,0f1h,000h,0f0h,0d4h	; b18e  ................
	defb 0d4h,0cah,0cfh,0cfh,0cbh,0c1h,0e1h,0c1h,0c0h,0c0h,0dah,0f3h,0c5h,0ceh,0c4h,0c1h	; b19e  ................
	defb 0e1h,0c1h,0cfh,0cfh,0cbh,0e9h,0d3h,0e8h,007h,0f0h,0c8h,0d4h,0cah,0cbh,0e1h,0cbh	; b1ae  ................
	defb 0c1h,0d6h,0d8h,0fdh,0d2h,0e2h,0c1h,0cbh,0e1h,0cbh,0c7h,0d4h,0cah,009h,0f0h,0eeh	; b1be  ................
	defb 000h,020h,0d3h,0dch,0d3h,0cbh,0e1h,0cbh,0e0h,0cfh,0cfh,0cbh,0d3h,0dch,0d3h,0dch	; b1ce  . ..............
	defb 001h,020h,0efh,005h,0f0h,0eeh,004h,020h,0d3h,0dch,0d3h,0dch,0c6h,0d4h,0c9h,004h	; b1de  . ..... ........
	defb 020h,0efh,002h,0f0h,01dh,0f2h,01dh,0ech,01fh,020h,0f5h,008h,0f7h,0f6h,020h,020h	; b1ee   ........ ....  
	defb 0f5h,008h,0f7h,0f6h,001h,020h,066h,000h,0b0h,0b1h,000h,020h,0b2h,000h,0b0h,067h	; b1fe  ..... f.... ...g
	defb 056h,053h,066h,000h,0b3h,0b4h,000h,020h,0b5h,000h,0b3h,067h,001h,020h,062h,008h	; b20e  VSf.... ...g. b.
	defb 065h,063h,020h,020h,062h,008h,065h,063h,020h,020h,000h,000h	; b21e  ec  b.ec  ..

; ----------------------------------------------------------------------
; DATOS nombres_pantalla: Comprimido (0x5331, 276 bytes): 768 bytes, una tabla
;   de nombres entera (0x8194 -> VRAM 0x1800)
;   0xb22a..0xb33e  (276 bytes)
DATA_nombres_pantalla:
	defb 0e0h,000h,009h,020h,005h,0fah,016h,020h,053h,045h,054h,03ch,055h,050h,016h,020h	; b22a  ... ... SET<UP. 
	defb 005h,0fah,01fh,020h,01fh,020h,007h,020h,0f5h,008h,0f7h,0f6h,020h,020h,0f5h,008h	; b23a  ... . . ....  ..
	defb 0f7h,0f6h,001h,020h,066h,000h,0b0h,0b1h,000h,020h,0b2h,000h,0b0h,067h,056h,053h	; b24a  ... f.... ...gVS
	defb 066h,000h,0b3h,0b4h,000h,020h,0b5h,000h,0b3h,067h,001h,020h,062h,008h,065h,063h	; b25a  f.... ...g. b.ec
	defb 020h,020h,062h,008h,065h,063h,01fh,020h,000h,020h,0f5h,015h,0f7h,0f6h,003h,020h	; b26a    b.ec. . ..... 
	defb 066h,020h,048h,041h,04ch,046h,03ah,020h,020h,030h,035h,020h,020h,031h,030h,020h	; b27a  f HALF:  05  10 
	defb 020h,031h,035h,020h,020h,032h,030h,020h,020h,067h,003h,020h,066h,015h,0fah,067h	; b28a   15  20  g. f..g
	defb 003h,020h,066h,020h,043h,04fh,055h,052h,054h,03ah,020h,020h,000h,0feh,020h,020h	; b29a  . f COURT:  ..  
	defb 000h,0ffh,020h,020h,000h,0f0h,020h,020h,067h,003h,020h,062h,015h,065h,063h,01fh	; b2aa  ..  ..  g. b.ec.
	defb 020h,01fh,020h,002h,020h,0f5h,00fh,0f7h,0f6h,009h,020h,066h,020h,020h,050h,04ch	; b2ba   . . ..... f  PL
	defb 041h,059h,009h,020h,067h,009h,020h,066h,020h,020h,053h,054h,041h,052h,054h,045h	; b2ca  AY. g. f  STARTE
	defb 052h,053h,005h,020h,067h,009h,020h,066h,020h,020h,043h,048h,041h,04eh,047h,045h	; b2da  RS. g. f  CHANGE
	defb 020h,053h,049h,044h,045h,053h,001h,020h,067h,009h,020h,066h,020h,020h,043h,04fh	; b2ea   SIDES. g. f  CO
	defb 04ch,04fh,052h,020h,04fh,046h,020h,057h,045h,041h,052h,000h,020h,067h,009h,020h	; b2fa  LOR OF WEAR. g. 
	defb 066h,020h,020h,04ch,045h,04eh,047h,054h,048h,020h,04fh,046h,020h,048h,041h,04ch	; b30a  f  LENGTH OF HAL
	defb 046h,020h,020h,067h,009h,020h,066h,020h,020h,043h,04fh,04ch,04fh,052h,020h,04fh	; b31a  F  g. f  COLOR O
	defb 046h,020h,043h,04fh,055h,052h,054h,020h,020h,067h,009h,020h,062h,00fh,065h,063h	; b32a  F COURT  g. b.ec
	defb 003h,020h,000h,000h	; b33a

; ----------------------------------------------------------------------
; DATOS patrones_logo: Comprimido (0x52CF, 339 bytes): 640 bytes, los 80
;   patrones 0xB0-0xFF del logotipo del titulo; 0x77DD los pone en los tres
;   tercios desde la VRAM 0x0580
;   0xb33e..0xb491  (339 bytes)
DATA_patrones_logo:
	defb 0f0h,050h,057h,0ffh,057h,0fch,051h,001h,050h,000h,050h,001h,051h,001h,057h,000h	; b33e  .PW.W.Q.P.P.Q.W.
	defb 050h,006h,000h,055h,080h,000h,000h,055h,0c0h,000h,000h,055h,0e0h,000h,000h,055h	; b34e  P..U...U...U...U
	defb 0f0h,000h,000h,055h,0f8h,000h,000h,055h,0fch,000h,000h,055h,0feh,000h,000h,055h	; b35e  ...U...U...U...U
	defb 0ffh,000h,050h,000h,057h,0feh,007h,01fh,03fh,07fh,07fh,052h,0ffh,050h,012h,0c0h	; b36e  ..P.W...?..R.P..
	defb 0f0h,0f8h,0fch,0fch,052h,0feh,0ffh,0ffh,07fh,07fh,03fh,01fh,007h,03fh,0ffh,0ffh	; b37e  ....R.....?..?..
	defb 07fh,07fh,03fh,01fh,007h,000h,050h,016h,0ffh,0ffh,07fh,07fh,03fh,01fh,007h,007h	; b38e  ..?...P.....?...
	defb 0feh,0feh,0fch,0fch,0f8h,0f0h,0c0h,000h,0feh,0feh,0fch,0fch,0f8h,0f0h,0c0h,0c0h	; b39e  ................
	defb 050h,011h,056h,0ffh,0feh,056h,0ffh,000h,056h,0ffh,001h,050h,000h,056h,0feh,0ffh	; b3ae  P.V..V..V..P.V..
	defb 053h,0feh,053h,000h,0c0h,080h,001h,053h,0feh,0ffh,056h,0feh,000h,050h,01dh,080h	; b3be  S.S....S..V..P..
	defb 0c0h,0e0h,0f0h,0f8h,0fch,0feh,0ffh,0ffh,07fh,03fh,01fh,00fh,007h,003h,001h,051h	; b3ce  .........?.....Q
	defb 025h,0e0h,0f0h,0f8h,0fch,053h,0feh,053h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,053h	; b3de  %....S.S.......S
	defb 000h,080h,0c0h,051h,026h,0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h,050h,014h,0feh	; b3ee  ...Q&........P..
	defb 0fdh,0fbh,0f7h,0efh,0dfh,0bfh,07fh,0feh,0fdh,0fbh,0f7h,0efh,0dfh,0bfh,0feh,050h	; b3fe  ...............P
	defb 000h,050h,011h,040h,080h,054h,000h,001h,050h,000h,051h,025h,051h,025h,054h,000h	; b40e  .P.@.T..P.Q%Q%T.
	defb 001h,003h,007h,00fh,01fh,03fh,07fh,053h,0ffh,050h,02ch,051h,026h,0e0h,0c0h,080h	; b41e  .....?.S.P,Q&...
	defb 080h,0c0h,0e0h,0f0h,0f8h,053h,0ffh,0feh,0fch,0f8h,0f0h,050h,006h,050h,006h,051h	; b42e  .....S.....P.P.Q
	defb 025h,051h,026h,050h,006h,050h,006h,050h,006h,0fch,0feh,0ffh,0feh,0fdh,0fbh,0f7h	; b43e  %Q&P.P.P........
	defb 0efh,000h,000h,052h,0ffh,052h,000h,000h,00fh,03fh,038h,077h,06fh,06eh,06ch,051h	; b44e  ...R.R...?8wonlQ
	defb 045h,000h,0ffh,0ffh,000h,0ffh,0ffh,000h,000h,057h,01ch,038h,03ch,03eh,03fh,03eh	; b45e  E........W.8<>?>
	defb 03ch,038h,000h,000h,054h,0ffh,000h,000h,0f3h,0c6h,0c6h,0f3h,0c0h,0c6h,0f3h,000h	; b46e  <8..T...........
	defb 08eh,0dbh,018h,098h,0d8h,0dbh,08eh,000h,020h,040h,080h,054h,000h,050h,006h,050h	; b47e  ........ @.T.P.P
	defb 006h,050h,0ffh	; b48e

; ----------------------------------------------------------------------
; DATOS colores_logo: Comprimido (0x52CF, 269 bytes): 640 bytes, los colores
;   de los 80 patrones del logotipo, en los tres tercios desde la VRAM 0x2580
;   0xb491..0xb59e  (269 bytes)
DATA_colores_logo:
	defb 0e0h,020h,027h,081h,020h,000h,020h,000h,027h,051h,020h,003h,020h,003h,081h,025h	; b491  . '. . .'Q . ..%
	defb 08ch,081h,081h,025h,082h,081h,020h,007h,020h,007h,020h,007h,020h,007h,020h,007h	; b4a1  ...%.. . . . . .
	defb 020h,007h,020h,007h,020h,000h,027h,0f4h,020h,010h,027h,0f1h,027h,0f5h,020h,010h	; b4b1   . . .'. .'.'. .
	defb 0f6h,0f8h,0f6h,0f8h,0f6h,0f8h,0f6h,048h,054h,0f4h,071h,051h,0f1h,071h,051h,0f1h	; b4c1  .......HT.qQ.qQ.
	defb 054h,0f4h,074h,054h,0f4h,074h,054h,0f4h,054h,0f4h,076h,058h,0f6h,078h,056h,018h	; b4d1  T.tT.tT.T.vX.xV.
	defb 020h,016h,020h,018h,026h,0f4h,074h,020h,010h,020h,010h,020h,010h,020h,01bh,020h	; b4e1   . .&.t . . . . 
	defb 010h,020h,010h,064h,084h,014h,024h,0f4h,054h,0f4h,074h,054h,0f4h,074h,054h,0f1h	; b4f1  . .d..$.T.tT.tT.
	defb 051h,0f1h,071h,051h,0f1h,071h,051h,0f1h,020h,010h,020h,010h,020h,010h,020h,010h	; b501  Q.qQ.qQ. . . . .
	defb 020h,010h,020h,010h,027h,041h,020h,02bh,020h,02bh,020h,02bh,026h,041h,04fh,020h	; b511   . .'A + + +&AO 
	defb 02bh,020h,02bh,022h,014h,024h,0f4h,020h,003h,020h,003h,027h,045h,020h,003h,020h	; b521  + +".$. . .'E . 
	defb 003h,046h,048h,046h,048h,046h,048h,046h,048h,020h,038h,04fh,04fh,046h,048h,046h	; b531  .FHFHFHFH 8OOFHF
	defb 048h,046h,048h,027h,042h,027h,0f2h,023h,0f1h,023h,0f2h,016h,018h,016h,018h,016h	; b541  HFH'B'.#.#......
	defb 018h,016h,018h,020h,03eh,020h,03eh,01fh,01fh,016h,018h,016h,018h,016h,018h,016h	; b551  ... > >.........
	defb 018h,016h,018h,016h,018h,01fh,01fh,046h,048h,046h,024h,045h,0f1h,0f1h,071h,051h	; b561  .......FHF$E..qQ
	defb 041h,022h,0f1h,027h,0a1h,020h,045h,020h,045h,020h,003h,027h,0d1h,0f1h,071h,051h	; b571  A".'. E E .'..qQ
	defb 041h,051h,041h,0f1h,0f1h,027h,0f6h,020h,04bh,027h,054h,01ch,012h,01ch,012h,01ch	; b581  AQA..'. K'T.....
	defb 012h,01ch,012h,014h,015h,014h,015h,014h,015h,014h,015h,020h,0ffh	; b591  ........... .

; ----------------------------------------------------------------------
; DATOS curva_5deb: 128 bytes: -8..131 saltandose un valor cada vez mas a
;   menudo; 0x5DE4 lee el de indice (hl+1), le suma 0x40 y lo recorta a 0xC0
;   0xb59e..0xb61e  (128 bytes)
DATA_curva_5deb:
	defb 0f8h,0f9h,0fah,0fbh,0fch,0fdh,0feh,0ffh,000h,001h,002h,003h,004h,005h,006h,007h	; b59e  ................
	defb 008h,009h,00ah,00bh,00ch,00dh,00eh,00fh,010h,011h,012h,013h,014h,015h,016h,017h	; b5ae  ................
	defb 018h,019h,01ah,01bh,01ch,01eh,01fh,020h,021h,022h,023h,024h,025h,026h,027h,028h	; b5be  ....... !"#$%&'(
	defb 029h,02bh,02ch,02dh,02eh,02fh,030h,031h,032h,033h,035h,036h,037h,038h,039h,03ah	; b5ce  )+,-./012356789:
	defb 03bh,03ch,03eh,03fh,040h,041h,042h,043h,045h,046h,047h,048h,049h,04ah,04ch,04dh	; b5de  ;<>?@ABCEFGHIJLM
	defb 04eh,04fh,050h,051h,053h,054h,055h,056h,057h,059h,05ah,05bh,05ch,05dh,05fh,060h	; b5ee  NOPQSTUVWYZ[\]_`
	defb 061h,062h,064h,065h,066h,067h,069h,06ah,06bh,06ch,06eh,06fh,070h,071h,072h,073h	; b5fe  abdefgijklnopqrs
	defb 074h,075h,076h,077h,078h,079h,07ah,07bh,07ch,07dh,07eh,07fh,080h,081h,082h,083h	; b60e  tuvwxyz{|}~.....

; ----------------------------------------------------------------------
; DATOS curva_5db9: 128 bytes: de 220 a 255, en escalones de dos o tres;
;   0x5DAF lee el de indice (hl+1) y lo multiplica con 0x59B5
;   0xb61e..0xb69e  (128 bytes)
DATA_curva_5db9:
	defb 0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0dch,0ddh,0ddh,0ddh,0deh,0deh	; b61e  ................
	defb 0deh,0dfh,0dfh,0dfh,0e0h,0e0h,0e0h,0e0h,0e1h,0e1h,0e1h,0e2h,0e2h,0e2h,0e3h,0e3h	; b62e  ................
	defb 0e3h,0e4h,0e4h,0e4h,0e5h,0e5h,0e6h,0e6h,0e6h,0e7h,0e7h,0e7h,0e8h,0e8h,0e8h,0e8h	; b63e  ................
	defb 0e9h,0e9h,0eah,0eah,0eah,0ebh,0ebh,0ebh,0ech,0ech,0edh,0edh,0edh,0eeh,0eeh,0eeh	; b64e  ................
	defb 0efh,0efh,0f0h,0f0h,0f0h,0f0h,0f1h,0f1h,0f2h,0f2h,0f2h,0f3h,0f3h,0f3h,0f4h,0f4h	; b65e  ................
	defb 0f5h,0f5h,0f5h,0f6h,0f6h,0f7h,0f7h,0f7h,0f8h,0f8h,0f8h,0f9h,0f9h,0f9h,0fah,0fah	; b66e  ................
	defb 0fbh,0fbh,0fch,0fch,0fch,0fdh,0fdh,0feh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b67e  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; b68e  ................

; ----------------------------------------------------------------------
; DATOS gradas: Comprimido (0x5331, 714 bytes): 1344 bytes, 42 filas de 32
;   numeros de patron (0x21-0x2B) que 0x5F8D descomprime en 0xC400
;   0xb69e..0xb968  (714 bytes)
DATA_gradas:
	defb 0e0h,040h,021h,022h,029h,026h,024h,027h,023h,02bh,022h,021h,024h,028h,025h,02ah	; b69e  .@!")&$'#+"!$(%*
	defb 023h,021h,022h,02ah,024h,025h,028h,021h,023h,028h,025h,02ah,027h,022h,029h,025h	; b6ae  #!"*$%(!#(%*'")%
	defb 021h,024h,025h,022h,023h,02ah,024h,025h,027h,029h,023h,021h,02bh,025h,027h,023h	; b6be  !$%"#*$%')#!+%'#
	defb 022h,021h,02bh,029h,021h,026h,02ah,023h,028h,021h,024h,023h,021h,025h,028h,025h	; b6ce  "!+)!&*#(!$#!%(%
	defb 02ah,025h,026h,026h,02ah,021h,029h,027h,025h,02bh,029h,022h,02bh,026h,024h,02ah	; b6de  *%&&*!)'%+)"+&$*
	defb 026h,021h,027h,023h,029h,026h,02ah,02bh,022h,023h,026h,024h,025h,021h,023h,02bh	; b6ee  &!'#)&*+"#&$%!#+
	defb 029h,025h,02bh,026h,024h,029h,021h,029h,025h,028h,027h,02ah,022h,027h,02bh,024h	; b6fe  )%+&$)!)%('*"'+$
	defb 029h,023h,026h,025h,027h,028h,023h,029h,021h,029h,023h,028h,022h,027h,028h,024h	; b70e  )#&%'(#)!)#("'($
	defb 025h,024h,026h,02bh,023h,02ah,027h,023h,025h,028h,026h,025h,02bh,024h,023h,02ah	; b71e  %$&+#*'#%(&%+$#*
	defb 027h,028h,024h,022h,024h,026h,027h,028h,021h,02ah,024h,022h,02ah,021h,028h,026h	; b72e  '($"$&'(!*$"*!(&
	defb 022h,024h,026h,025h,023h,028h,022h,025h,02ah,022h,027h,024h,022h,029h,026h,022h	; b73e  "$&%#("%*"'$")&"
	defb 02bh,026h,025h,026h,025h,024h,02bh,022h,029h,027h,021h,027h,02ah,025h,026h,029h	; b74e  +&%&%$+")'!'*%&)
	defb 02bh,025h,022h,028h,021h,029h,028h,021h,02bh,022h,021h,027h,023h,022h,028h,02ah	; b75e  +%"(!)(!+"!'#"(*
	defb 028h,025h,028h,029h,022h,026h,025h,024h,026h,023h,021h,028h,024h,029h,021h,026h	; b76e  (%()"&%$&#!($)!&
	defb 02bh,024h,023h,028h,026h,021h,02ch,02ah,027h,024h,02bh,021h,027h,02ah,023h,026h	; b77e  +$#(&!,*'$+!'*#&
	defb 028h,023h,025h,028h,025h,022h,024h,021h,027h,023h,021h,024h,026h,025h,024h,028h	; b78e  (#%(%"$!'#!$&%$(
	defb 021h,027h,02ah,02bh,028h,024h,027h,026h,022h,02bh,021h,027h,02ah,029h,02bh,028h	; b79e  !'*+($'&"+!'*)+(
	defb 024h,02ah,027h,026h,025h,02dh,022h,027h,021h,025h,041h,002h,011h,002h,002h,001h	; b7ae  $*'&%-"'!%A.....
	defb 00dh,00fh,00ch,006h,00ch,001h,00ch,009h,003h,010h,006h,00ch,00dh,001h,005h,00fh	; b7be  ................
	defb 00ah,008h,001h,00dh,007h,00bh,00eh,001h,002h,001h,007h,003h,009h,001h,009h,003h	; b7ce  ................
	defb 004h,00bh,00ch,003h,00eh,00bh,00ch,010h,001h,002h,002h,012h,041h,002h,040h,016h	; b7de  ............A.@.
	defb 01eh,013h,016h,016h,015h,01bh,01bh,019h,01ah,01dh,015h,019h,01ah,017h,01ch,01ah	; b7ee  ................
	defb 01dh,01bh,015h,018h,01bh,017h,017h,015h,01bh,017h,01bh,01ch,015h,016h,015h,017h	; b7fe  ................
	defb 017h,01ah,015h,01ah,017h,018h,01bh,01dh,017h,01ch,01bh,01dh,01ch,015h,016h,016h	; b80e  ................
	defb 014h,01fh,040h,016h,040h,074h,076h,07ah,05fh,084h,049h,084h,07bh,077h,040h,074h	; b81e  ..@.@tvz_.I.{w@t
	defb 040h,084h,078h,07ch,084h,087h,051h,094h,096h,097h,051h,094h,088h,084h,07dh,079h	; b82e  @.x|..Q...Q...}y
	defb 043h,084h,078h,07eh,084h,08dh,042h,0a8h,0a9h,0aah,0abh,049h,08fh,090h,091h,049h	; b83e  C.x~..B....I...I
	defb 08fh,0c6h,0c7h,0a9h,042h,0a8h,08eh,084h,07fh,079h,040h,084h,040h,075h,082h,080h	; b84e  ....B....y@.@u..
	defb 0d7h,045h,08fh,0ach,0adh,0aeh,047h,08fh,090h,091h,047h,08fh,0c3h,0c4h,0c5h,045h	; b85e  .E....G...G....E
	defb 08fh,0d8h,081h,083h,040h,075h,042h,084h,0d9h,047h,08fh,0afh,0b0h,046h,08fh,090h	; b86e  ....@uB..G...F..
	defb 091h,046h,08fh,0c1h,0c2h,047h,08fh,0dah,047h,084h,089h,046h,095h,09ah,08fh,0b1h	; b87e  .F...G..G..F....
	defb 045h,08fh,0ddh,0e5h,0e6h,0deh,045h,08fh,0c0h,08fh,0a4h,046h,095h,08ah,047h,084h	; b88e  E.....E....F..G.
	defb 0f8h,045h,0d2h,093h,09bh,09ch,0b2h,044h,08fh,0e1h,0efh,0ebh,0ech,0f0h,0e2h,044h	; b89e  .E.....D.......D
	defb 08fh,0bfh,0a2h,0a3h,092h,045h,0d2h,0f9h,046h,084h,0f4h,045h,0d2h,0d3h,091h,08fh	; b8ae  .....E..F..E....
	defb 09dh,092h,044h,08fh,0edh,0d2h,0d3h,0d4h,0d2h,0eeh,044h,08fh,093h,0a1h,08fh,090h	; b8be  ..D.......D.....
	defb 0d4h,045h,0d2h,0f5h,045h,084h,0f6h,045h,0d2h,0d5h,08fh,09fh,0a0h,0b3h,044h,08fh	; b8ce  .E..E..E......D.
	defb 0e3h,0f1h,0e9h,0eah,0f2h,0e4h,044h,08fh,0c8h,0a5h,0a6h,08fh,0d6h,045h,0d2h,0f7h	; b8de  ......D......E..
	defb 045h,084h,087h,047h,094h,09eh,08fh,0b4h,045h,08fh,0dfh,0e7h,0e8h,0e0h,045h,08fh	; b8ee  E..G....E.....E.
	defb 0c9h,08fh,0a7h,047h,094h,088h,045h,084h,0dbh,048h,08fh,0b6h,0b5h,046h,08fh,090h	; b8fe  ...G..E..H...F..
	defb 091h,046h,08fh,0cah,0cbh,048h,08fh,0dch,044h,084h,0d7h,048h,08fh,0b8h,0b7h,047h	; b90e  .F...H..D..H...G
	defb 08fh,090h,091h,047h,08fh,0cch,0cdh,048h,08fh,0d8h,043h,084h,0d9h,043h,08fh,0bdh	; b91e  ...G...H..C..C..
	defb 0bdh,0bch,0bbh,0bah,0b9h,048h,08fh,090h,091h,048h,08fh,0ceh,0cfh,0d0h,0d1h,0bdh	; b92e  .....H...H......
	defb 0bdh,043h,08fh,0dah,043h,084h,087h,043h,094h,0beh,0beh,04ch,08fh,090h,091h,04ch	; b93e  .C..C..C...L...L
	defb 08fh,0beh,0beh,043h,094h,088h,043h,084h,08bh,054h,095h,098h,099h,054h,095h,08ch	; b94e  ...C..C..T...T..
	defb 05fh,084h,05fh,084h,05fh,084h,04ah,084h,040h,040h	; b95e  _._._.J.@@

; ======================================================================
; CODIGO 0xb968..0xba7b  (275 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ===== Lectura del mando del equipo A (0 izquierda, otro derecha) =====
; ----------------------------------------------------------------------
lee_mando_lado:		; Devuelve en A los botones (bit 7 disparo, bit 6 pase), en C la direccion 0-7 (0xFF quieto) y en DE su (dx, dy); segun (0xF012) cada lado es mando 1, mando 2 o la maquina
	push hl			;b968   ; guarda HL
	push af			;b969   ; y el lado (A)
	ld a,(0f012h)		;b96a   ; (0xF012): modo de mandos 0-3, montado en 0x4089 con el bit 1 de 0xEFD6 y 0xEFD7 (equipo humano o maquina)
	ld c,a			;b96d   ; C = modo
	add a,a			;b96e   ; modo * 3: cada entrada de la tabla es un jp de tres bytes
	add a,c			;b96f   ; A = modo * 3
	ld l,a			;b970   ; HL = desplazamiento en la tabla
	ld h,000h		;b971
	pop af			;b973   ; A = 0 equipo de la izquierda, otro el de la derecha
	and a			;b974   ; que lado?
	jr z,L_B97C		;b975   ; cero: la izquierda
	ld de,mandos_derecha		;b977   ; tabla de la derecha
	jr L_B97F		;b97a
L_B97C:
	ld de,mandos_izquierda		;b97c   ; tabla de la izquierda
L_B97F:
	add hl,de			;b97f   ; HL = direccion del jp de este lado y modo
	ld de,mando_a_direccion		;b980   ; la vuelta comun 0xB99D, apilada: el jp elegido acaba con ret
	push de			;b983   ; vuelta en la pila
	jp (hl)			;b984   ; salta al lector del lado y modo
mandos_izquierda:		; Cuatro jp, uno por modo (0xF012): mando 2, mando 1, maquina, maquina
	jp mando_2		;b985   ; modo 0: la izquierda con el mando 2
L_B988:
	jp mando_1		;b988   ; modo 1: la izquierda con el mando 1
L_B98B:
	jp maquina_izquierda		;b98b   ; modo 2: la izquierda la lleva la maquina
L_B98E:
	jp maquina_izquierda		;b98e   ; modo 3: las dos la maquina
mandos_derecha:		; Cuatro jp, uno por modo (0xF012): mando 1, maquina, mando 1, maquina
	jp mando_1		;b991   ; modo 0: la derecha con el mando 1
L_B994:
	jp maquina_derecha		;b994   ; modo 1: la derecha la lleva la maquina
L_B997:
	jp mando_1		;b997   ; modo 2: la derecha con el mando 1
L_B99A:
	jp maquina_derecha		;b99a   ; modo 3: las dos la maquina
mando_a_direccion:		; Vuelta comun: convierte la direccion GTSTCK (1-8) en indice 0-7 y (dx, dy) de 0xBA7B; la maquina (bit 0 de A) se salta la conversion
	bit 0,a		;b99d   ; bit 0 de A: lo devuelve la maquina (0x01 o 0x81), no un mando
	jr nz,L_B9AD		;b99f   ; maquina: sin tabla de direcciones
	ld l,c			;b9a1   ; C = direccion GTSTCK 0-8
	ld h,000h		;b9a2   ; HL = direccion * 2
	add hl,hl			;b9a4
	ld de,0ba7bh		;b9a5   ; nueve pares (dx, dy), el 0 es quieto
	add hl,de			;b9a8   ; HL = su par (dx, dy)
	ld d,(hl)			;b9a9   ; D = dx
	inc hl			;b9aa
	ld e,(hl)			;b9ab   ; E = dy
	dec c			;b9ac   ; direccion 1-8 -> 0-7; quieto -> 0xFF
L_B9AD:
	push af			;b9ad   ; guarda los botones
	ld a,(0f007h)		;b9ae   ; (0xF007): jugador cuyo mando se ignora (0xFF = ninguno; 0x50F1 lo pone a 0xFF al empezar)
	and a			;b9b1   ; 0xFF: ningun jugador bloqueado
	jp m,L_B9C0		;b9b2
	ld hl,0e721h		;b9b5   ; (0xE721): jugador que se esta leyendo
	cp (hl)			;b9b8   ; es este el bloqueado?
	jr nz,L_B9C0		;b9b9
	ld c,0ffh		;b9bb   ; si es el ignorado: quieto y sin movimiento
	ld de,00000h		;b9bd   ; DE = 0: no se mueve
L_B9C0:
	pop af			;b9c0   ; recupera los botones
	pop hl			;b9c1   ; y HL
	ret			;b9c2
mando_1:		; Mando 1: joystick 1 y, si no da nada, los cursores con '[' (fila 1, bit 6) como disparo y RETURN (fila 7, bit 7) como pase
	call joystick_1		;b9c3   ; primero el joystick 1
	ld b,a			;b9c6   ; B = botones
	and 0c0h		;b9c7   ; algun boton o alguna direccion del joystick: vale
	or c			;b9c9   ; botones o direccion: hay entrada
	ld a,b			;b9ca   ; A = botones
	ret nz			;b9cb   ; con entrada del joystick, listo
	ld a,000h		;b9cc   ; GTSTCK 0: los cursores del teclado
	call 000d5h		;b9ce   ; BIOS GTSTCK - Returns the joystick status
	ld c,a			;b9d1   ; C = direccion de los cursores
	ld a,001h		;b9d2   ; fila 1 del teclado: 8 9 - ^ \ @ [ ;
	push bc			;b9d4   ; SNSMAT no respeta BC
	call 00141h		;b9d5   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;b9d8
	ld b,000h		;b9d9   ; B = botones, de momento ninguno
	xor 0ffh		;b9db   ; a 1 las pulsadas
	bit 6,a		;b9dd   ; '[' pulsada: disparo
	jr z,L_B9E3		;b9df   ; '[' no pulsada
	set 7,b		;b9e1   ; bit 7: disparo
L_B9E3:
	ld a,007h		;b9e3   ; fila 7: F4 F5 ESC TAB STOP BS SELECT RETURN
	push bc			;b9e5   ; SNSMAT no respeta BC
	call 00141h		;b9e6   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;b9e9
	xor 0ffh		;b9ea
	bit 7,a		;b9ec   ; RETURN pulsada: pase
	jr z,L_B9F2		;b9ee   ; RETURN no pulsada
	set 6,b		;b9f0   ; bit 6: pase
L_B9F2:
	ld a,b			;b9f2   ; A = botones
	ret			;b9f3
joystick_1:		; Joystick 1: GTSTCK 1 en C, GTTRIG 1 y 3 (los dos botones) en los bits 7 y 6 de A
	ld a,001h		;b9f4   ; GTSTCK 1: el joystick del puerto 1
	call 000d5h		;b9f6   ; BIOS GTSTCK - Returns the joystick status
	ld c,a			;b9f9   ; C = direccion 0-8
	ld b,000h		;b9fa   ; B = botones
	ld a,001h		;b9fc   ; GTTRIG 1: boton A del puerto 1
	push bc			;b9fe   ; GTTRIG no respeta BC
	call 000d8h		;b9ff   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;ba02
	and a			;ba03   ; pulsado?
	jr z,L_BA08		;ba04
	set 7,b		;ba06   ; bit 7: disparo
L_BA08:
	ld a,003h		;ba08   ; GTTRIG 3: boton B del puerto 1
	push bc			;ba0a
	call 000d8h		;ba0b   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;ba0e
	and a			;ba0f   ; pulsado?
	jr z,L_BA14		;ba10
	set 6,b		;ba12   ; bit 6: pase
L_BA14:
	ld a,b			;ba14   ; A = botones
	ret			;ba15
mando_2:		; Mando 2: joystick 2 y, si no da nada, cuatro teclas de las filas 3 y 5 convertidas con la tabla 0xBA8D, con TAB (fila 7, bit 3) como disparo y CTRL (fila 6, bit 1) como pase
	call joystick_2		;ba16   ; primero el joystick 2
	ld b,a			;ba19   ; B = botones
	and 0c0h		;ba1a   ; solo los bits de boton
	or c			;ba1c   ; botones o direccion: hay entrada
	ld a,b			;ba1d   ; A = botones
	ret nz			;ba1e   ; con entrada del joystick, listo
	ld a,003h		;ba1f   ; fila 3 del teclado: B C D E F G H I
	call 00141h		;ba21   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	and 00eh		;ba24   ; se quedan C, D y E (bits 1-3)
	ld c,a			;ba26   ; C = C, D, E en los bits 1-3
	ld a,005h		;ba27   ; fila 5 del teclado: R S T U V W X Y
	push bc			;ba29   ; SNSMAT no respeta BC
	call 00141h		;ba2a   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;ba2d
	and 001h		;ba2e   ; se queda R (bit 0)
	or c			;ba30   ; mas R en el bit 0
	xor 00fh		;ba31   ; a 1 las pulsadas: cuatro bits, 16 combinaciones
	ld d,000h		;ba33   ; DE = indice en la tabla
	ld e,a			;ba35
	ld hl,0ba8dh		;ba36   ; combinacion -> direccion GTSTCK 0-8
	add hl,de			;ba39
	ld c,(hl)			;ba3a   ; C = direccion 0-8
	ld b,000h		;ba3b   ; B = botones, de momento ninguno
	ld a,007h		;ba3d   ; fila 7: TAB es el bit 3
	push bc			;ba3f   ; SNSMAT no respeta BC
	call 00141h		;ba40   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;ba43
	bit 3,a		;ba44   ; TAB pulsada: disparo
	jr nz,L_BA4A		;ba46   ; TAB no pulsada
	set 7,b		;ba48   ; bit 7: disparo
L_BA4A:
	ld a,006h		;ba4a   ; fila 6: SHIFT CTRL GRAPH CAPS CODE F1 F2 F3
	push bc			;ba4c   ; SNSMAT no respeta BC
	call 00141h		;ba4d   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	pop bc			;ba50
	bit 1,a		;ba51   ; CTRL pulsada: pase
	jr nz,L_BA57		;ba53   ; CTRL no pulsada
	set 6,b		;ba55   ; bit 6: pase
L_BA57:
	ld a,b			;ba57   ; A = botones
	ret			;ba58
joystick_2:		; Joystick 2: GTSTCK 2 en C, GTTRIG 2 y 4 en los bits 7 y 6 de A
	ld a,002h		;ba59   ; GTSTCK 2: el joystick del puerto 2
	call 000d5h		;ba5b   ; BIOS GTSTCK - Returns the joystick status
	ld c,a			;ba5e   ; C = direccion 0-8
	ld b,000h		;ba5f   ; B = botones
	ld a,002h		;ba61   ; GTTRIG 2: boton A del puerto 2
	push bc			;ba63   ; GTTRIG no respeta BC
	call 000d8h		;ba64   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;ba67
	and a			;ba68   ; pulsado?
	jr z,L_BA6D		;ba69
	set 7,b		;ba6b   ; bit 7: disparo
L_BA6D:
	ld a,004h		;ba6d   ; GTTRIG 4: boton B del puerto 2
	push bc			;ba6f
	call 000d8h		;ba70   ; BIOS GTTRIG - Returns current trigger status
	pop bc			;ba73
	and a			;ba74   ; pulsado?
	jr z,L_BA79		;ba75
	set 6,b		;ba77   ; bit 6: pase
L_BA79:
	ld a,b			;ba79   ; A = botones
	ret			;ba7a

; ----------------------------------------------------------------------
; DATOS nueve_direcciones: Nueve pares (dx, dy): quieto y las ocho direcciones
;   del mando en el orden de GTSTCK
;   0xba7b..0xba8d  (18 bytes)
DATA_nueve_direcciones:
	defb 000h,000h	; ba7b
	defb 0ffh,000h	; ba7d
	defb 0ffh,001h	; ba7f
	defb 000h,001h	; ba81
	defb 001h,001h	; ba83
	defb 001h,000h	; ba85
	defb 001h,0ffh	; ba87
	defb 000h,0ffh	; ba89
	defb 0ffh,0ffh	; ba8b

; ----------------------------------------------------------------------
; DATOS cursores_a_direccion: 16 entradas: para cada combinacion de las cuatro
;   teclas del cursor (fila 8 del teclado, xor 0x0F), la direccion 0-8 como la
;   da GTSTCK; la lee 0xBA36
;   0xba8d..0xba9d  (16 bytes)
DATA_cursores_a_direccion:
	defb 000h,007h,005h,006h,001h,008h,000h,007h,003h,000h,004h,005h,002h,001h,003h,000h	; ba8d  ................

; ======================================================================
; CODIGO 0xba9d..0xbf1e  (1153 bytes)
; ======================================================================


maquina_izquierda:		; El equipo de la izquierda lo lleva la maquina: decide con 0xBB14 o 0xBD61 segun que lado ataque (bit 0 de 0xE83C)
	ld hl,0f010h		;ba9d   ; (0xF010): flag del lado izquierdo
	call flag_a_codigo		;baa0   ; A = 0x81 si hay orden pendiente, 0x01 si no
	push af			;baa3   ; guarda el codigo
	ld a,(0e83ch)		;baa4   ; (0xE83C) bit 0: los lados estan cambiados
	and 001h		;baa7   ; bit 0: lados cambiados
	jr nz,L_BAB0		;baa9   ; cambiados: decide como el otro lado
	call decide_defensor		;baab   ; la izquierda defiende: decide_defensor
	jr L_BAB3		;baae
L_BAB0:
	call decide_atacante		;bab0   ; el mismo codigo que el otro lado pero al reves
L_BAB3:
	jr L_BACB		;bab3
maquina_derecha:		; El equipo de la derecha lo lleva la maquina
	ld hl,0f011h		;bab5   ; (0xF011): flag del lado derecho
	call flag_a_codigo		;bab8   ; A = 0x81 si hay orden pendiente, 0x01 si no
	push af			;babb   ; guarda el codigo
	ld a,(0e83ch)		;babc
	and 001h		;babf   ; bit 0: lados cambiados
	jr nz,L_BAC8		;bac1   ; cambiados: decide como el otro lado
	call decide_atacante		;bac3   ; la derecha ataca: decide_atacante
	jr L_BACB		;bac6
L_BAC8:
	call decide_defensor		;bac8   ; la derecha defiende
L_BACB:
	call anda_al_destino		;bacb   ; decide el movimiento del jugador IX
	push ix		;bace   ; HL = su registro
	pop hl			;bad0
	pop af			;bad1   ; recupera el codigo
	ret nz			;bad2   ; con orden pendiente (0x81): devuelve el codigo tal cual
	ld a,(ix+00ch)		;bad3   ; (IX+0x0C) a cero: devuelve 1 (sin boton)
	and a			;bad6   ; lleva el balon?
	jr nz,boton_de_la_maquina		;bad7   ; si: mira si tira
	ld a,001h		;bad9   ; no: sin boton
	ret			;badb
flag_a_codigo:		; A = 0x81 si (HL) no es cero, 0x01 si lo es: el bit 0 marca "maquina" para 0xB99D y el 7 el disparo
	ld a,(hl)			;badc   ; la orden pendiente del lado
	and a			;badd
	ld a,081h		;bade   ; 0x81: maquina con orden
	ret nz			;bae0
	ld a,001h		;bae1   ; 0x01: maquina sin orden
	ret			;bae3
boton_de_la_maquina:		; 0x81 (disparo) si (IX+0x0B) es negativo, 0x01 si no
	ld a,(ix+00bh)		;bae4
	and a			;bae7   ; (IX+0x0B) negativo: tirar
	ld a,081h		;bae8   ; 0x81: disparo
	ret m			;baea
	ld a,001h		;baeb   ; 0x01: sin boton
	ret			;baed
huerfano_es_el_controlado:		; Huerfano: devuelve 0 si el jugador controlado es el que se esta leyendo (0xE721), y si no el bit 6 del campo +0x0F de su registro por el +0x0F*4
	call controlado		;baee
	ld hl,0e721h		;baf1   ; (0xE721): jugador que se esta leyendo
	cp (hl)			;baf4   ; el controlado es el que se lee?
	jr nz,L_BAF9		;baf5
	xor a			;baf7   ; si: cero
	ret			;baf8
L_BAF9:
	call registro_jugador		;baf9   ; HL = registro del jugador A
pose_bit6:		; Devuelve en el flag Z el bit 6 del campo +0x0F del jugador A mezclado con el mismo campo por cuatro (la direccion de la pose)
	push hl			;bafc   ; guarda el registro
	push de			;bafd   ; y DE
	ld de,0000fh		;bafe   ; campo +0x0F: patrones de la pose
	add hl,de			;bb01
	pop de			;bb02
	ld a,(hl)			;bb03   ; A = patrones de la pose
	ld c,a			;bb04   ; C = copia
	add a,a			;bb05   ; por cuatro
	add a,a			;bb06
	xor (hl)			;bb07   ; mezclado con el original
	pop hl			;bb08   ; recupera el registro
	bit 6,a		;bb09   ; el bit 6 decide
	ret			;bb0b
sin_movimiento:		; A = 1 (sin boton), DE = 0 y C = 0x3F: la maquina no mueve a este jugador
	ld a,001h		;bb0c   ; sin boton
	ld de,00000h		;bb0e   ; sin movimiento
	ld c,03fh		;bb11   ; direccion ninguna
	ret			;bb13
decide_atacante:		; La maquina con el balon: segun el estado de 0xF009 elige objetivo (0), corre a el (1), encara la canasta (2), tira (3) o espera (4); deja el destino en (IX+0x20, IX+0x21)
	call indice_controlado		;bb14   ; B = indice del controlado
	call registro_jugador		;bb17   ; HL = registro del controlado
	push hl			;bb1a   ; IY = ese registro
	pop iy		;bb1b
	push hl			;bb1d   ; y lo guarda para despues
	ld e,(iy+001h)		;bb1e   ; Y (profundidad, +1) del jugador en curso (IY = su registro)
	call cuantos_controla		;bb21   ; A = cuantos jugadores controla la maquina en este lado, B = el indice
	ld hl,0e623h		;bb24   ; (0xE623): X del balon a lo largo de la pista (+3 del registro 0xE620, con signo desde el centro), bit 7 = en la mitad izquierda
	bit 7,(hl)		;bb27   ; bit 7: el balon en la mitad izquierda
	pop hl			;bb29   ; recupera el registro
	jr nz,L_BB34		;bb2a   ; mitad izquierda: 0xBB34
	cp 003h		;bb2c   ; menos de tres controlados: destino X = 0xE2 (-30, hacia la canasta izquierda)
	jr nc,L_BB41		;bb2e   ; tres o mas controlados: decidir de verdad
L_BB30:
	ld d,0e2h		;bb30   ; D = X del destino
	jr L_BB3A		;bb32   ; a dejar el destino
L_BB34:
	cp 003h		;bb34
	jr c,L_BB41		;bb36   ; menos de tres controlados: decidir de verdad
L_BB38:
	ld d,01eh		;bb38   ; o X = 0x1E (+30, hacia la derecha)
L_BB3A:
	ld (ix+021h),d		;bb3a   ; destino: (IX+0x20) = Y (profundidad), (IX+0x21) = X
	ld (ix+020h),e		;bb3d   ; destino Y = la del controlado
	ret			;bb40
L_BB41:
	ld a,(0f009h)		;bb41   ; (0xF009): estado del ataque de la maquina, 0-4
	cp 001h		;bb44   ; estado 1: corriendo al destino
	jp z,ataque_corriendo		;bb46
	cp 002h		;bb49   ; estado 2: encarando
	jp z,ataque_encarando		;bb4b
	cp 003h		;bb4e   ; estado 3: al punto de tiro
	jp z,ataque_al_punto_de_tiro		;bb50
	cp 004h		;bb53   ; estado 4: esperando el tiro
	jp z,ataque_tira		;bb55
	push hl			;bb58   ; estado 0: guarda el registro
	call hay_sitio_para_tirar		;bb59   ; hay sitio para tirar? (acarreo: si)
	pop hl			;bb5c   ; recupera el registro
	jp c,ataque_estado_4		;bb5d   ; con sitio para tirar: al estado 4
	call angulo_y_distancia_a_canasta		;bb60   ; angulo (B) y distancia (A) del jugador HL a la canasta de 0xE6C3
	ld c,a			;bb63   ; C = distancia del controlado
	ld e,b			;bb64   ; E = su angulo
	push ix		;bb65   ; HL = registro del jugador IX
	pop hl			;bb67
	call angulo_y_distancia_a_canasta		;bb68   ; lo mismo para el jugador IX
	ld b,a			;bb6b   ; B = distancia del jugador IX
	ld a,c			;bb6c   ; A = distancia del controlado
	sub b			;bb6d   ; diferencia de distancias
	jr c,L_BB79		;bb6e   ; el jugador IX mas lejos
	cp 00bh		;bb70   ; menos de 11: se acerca con la tabla C2 del desfase
	jr nc,L_BB79		;bb72
	call seno_y_coseno		;bb74   ; seno y coseno del angulo del controlado
	jr L_BB87		;bb77   ; a calcular el punto
L_BB79:
	call seno_y_coseno		;bb79   ; seno y coseno del angulo del controlado
	ld a,c			;bb7c   ; A = distancia del controlado
	sub 00ah		;bb7d   ; a menos de 10 se queda quieto
	jr nc,L_BB86		;bb7f
	ld de,00000h		;bb81   ; quieto
	jr L_BB93		;bb84   ; a dejar el destino
L_BB86:
	ld b,a			;bb86   ; B = distancia menos 10
L_BB87:
	ld a,b			;bb87   ; A = la distancia que se avanza
	push af			;bb88   ; guardada
	call producto_con_signo		;bb89   ; componente X: B * coseno (0xBBB5)
	ex de,hl			;bb8c   ; HL = componente X, DE = seno
	pop af			;bb8d   ; A = la distancia otra vez
	call producto_con_signo		;bb8e   ; componente Y: B * seno
	ex de,hl			;bb91   ; HL = componente Y, DE = componente X
	ld e,h			;bb92   ; E = X del destino
L_BB93:
	call guarda_posicion_en_f00c		;bb93   ; guarda la posicion del jugador en curso en 0xF00C/0xF00D
	ld a,e			;bb96   ; A = X del destino
	ld (0f00eh),a		;bb97   ; (0xF00E): X del destino
	ld a,d			;bb9a   ; A = Y del destino
	add a,039h		;bb9b   ; (0xF00F): Y del destino, 0x39 (la mitad de la pista) mas
	ld (0f00fh),a		;bb9d
	ld a,001h		;bba0   ; estado 1: correr al destino
	ld (0f009h),a		;bba2
L_BBA5:
	call corrige_destino_x		;bba5   ; corrige el destino con la posicion de los companeros
	ld a,(0f00fh)		;bba8   ; Y del destino al registro
	ld (ix+020h),a		;bbab
	ld a,(0f00eh)		;bbae   ; y la X
	ld (ix+021h),a		;bbb1
	ret			;bbb4
producto_con_signo:		; HL = A * L con el signo de H (multiplica16 y niega_hl)
	push bc			;bbb5   ; guarda BC
	push de			;bbb6   ; y DE
	ld e,a			;bbb7   ; DE = A
	ld d,000h		;bbb8
	ld a,h			;bbba   ; el bit 7 de H es el signo
	and a			;bbbb
	push af			;bbbc   ; guarda el signo
	ld h,000h		;bbbd   ; HL = L sin signo
	call multiplica16		;bbbf   ; HL = A * L
	pop af			;bbc2   ; recupera el signo
	call m,niega_hl		;bbc3   ; negativo: HL = -HL
	pop de			;bbc6   ; recupera DE
	pop bc			;bbc7   ; y BC
	ret			;bbc8
seno_y_coseno:		; Devuelve en HL y DE las dos entradas de la tabla C2 del angulo E (0xC000-0xC2FF, montadas por 0x5A58)
	push bc			;bbc9   ; guarda BC
	ld a,e			;bbca   ; A = angulo
	push af			;bbcb   ; guardado
	call tabla_c2_desfase		;bbcc   ; HL = entrada de la tabla con desfase (coseno)
	pop af			;bbcf   ; A = angulo otra vez
	push de			;bbd0   ; guarda el coseno
	call tabla_c2		;bbd1   ; HL = entrada sin desfase (seno)
	ex de,hl			;bbd4   ; DE = seno
	pop de			;bbd5   ; HL = coseno
	pop bc			;bbd6   ; recupera BC
	ret			;bbd7
ataque_corriendo:		; Estado 1: al llegar al destino, si el controlado ya no tiene el balon pasa al estado 0; si lo tiene, estado 2 y 0x12 cuadros de espera (IX+0x26)
	call ha_llegado		;bbd8   ; ha llegado el controlado?
	ret nc			;bbdb   ; no: sigue corriendo
	ld a,(ix+020h)		;bbdc   ; (IX+0x20/0x21) a cero: ya ha llegado
	or (ix+021h)		;bbdf   ; destino pendiente
	ret nz			;bbe2   ; pendiente: nada
	ld a,(iy+00ch)		;bbe3   ; (IY+0x0C): el jugador en curso lleva el balon
	and a			;bbe6   ; lleva el balon?
	jr z,L_BBF7		;bbe7   ; no: a encarar
L_BBE9:
	call cuantos_controla		;bbe9   ; A = controlados, B = indice
L_BBEC:
	push af			;bbec   ; guarda A
	xor a			;bbed   ; estado 0
	ld (0f009h),a		;bbee   ; vuelve al estado 0
	pop af			;bbf1   ; recupera A
	ld c,010h		;bbf2   ; C = 0x10: la orden de tirar para 0xBEBB
	jp L_BEBB		;bbf4   ; a dejar la orden en el lado
L_BBF7:
	call guarda_posicion_en_f00c		;bbf7   ; guarda la posicion
	ld (ix+026h),012h		;bbfa   ; (IX+0x26): cuadros de espera antes de tirar
	ld a,002h		;bbfe   ; estado 2: encarar la canasta
	ld (0f009h),a		;bc00
	ret			;bc03
ataque_encarando:		; Estado 2: pasada la espera, calcula el punto a cuatro de distancia de la canasta en la direccion del jugador y pasa al estado 3
	ld a,(iy+00ch)		;bc04
	and a			;bc07   ; lleva el balon?
	jr nz,L_BBE9		;bc08   ; si: a 0xBBE9 (orden de tirar)
	ld a,(ix+026h)		;bc0a
	and a			;bc0d   ; espera agotada?
	ret nz			;bc0e   ; no: nada
	call ha_llegado		;bc0f   ; ha llegado?
	ret nc			;bc12   ; no: nada
	ld hl,0e620h		;bc13   ; 0xE620: el registro del balon
	call angulo_y_distancia_a_canasta		;bc16   ; A = distancia del balon a la canasta, B = angulo
	sub 004h		;bc19   ; cuatro menos: el punto de tiro
	push af			;bc1b   ; guarda distancia - 4
	ld e,b			;bc1c   ; E = angulo
	call seno_y_coseno		;bc1d   ; seno y coseno
	pop af			;bc20   ; A = distancia - 4
	push af			;bc21   ; guardada otra vez
	ex de,hl			;bc22   ; HL = seno
	call producto_con_signo		;bc23   ; HL = componente Y
	ld a,h			;bc26   ; A = Y del punto
	add a,039h		;bc27   ; mas la mitad de la pista
	ld (0f00fh),a		;bc29   ; (0xF00F): Y del punto de tiro
	pop af			;bc2c   ; A = distancia - 4
	ex de,hl			;bc2d   ; HL = coseno
	call producto_con_signo		;bc2e   ; HL = componente X
	ld a,h			;bc31   ; A = X del punto
	ld (0f00eh),a		;bc32   ; (0xF00E): X del punto de tiro
	ld a,003h		;bc35   ; estado 3: ir al punto de tiro
	ld (0f009h),a		;bc37
	jp L_BBA5		;bc3a   ; a dejar el destino
ataque_al_punto_de_tiro:		; Estado 3: en cuanto llega (destino a cero) pasa al estado 4
	ld a,(ix+020h)		;bc3d
	or (ix+021h)		;bc40   ; destino pendiente?
	ret nz			;bc43   ; pendiente: nada
ataque_estado_4:		; Estado 4: esperar el tiro
	ld a,004h		;bc44   ; estado 4
	ld (0f009h),a		;bc46
	ret			;bc49
ataque_tira:		; Estado 4: si hay sitio tira (bit 0 de la pose); si no, al azar, roba o pasa el balon a un companero (0xED6F-0xED71)
	call hay_sitio_para_tirar		;bc4a   ; hay sitio?
	jr c,L_BC59		;bc4d   ; si: tira (0xBC59)
	res 0,(ix+00dh)		;bc4f   ; sin sitio: quita el bit 0 de la pose
	call ha_llegado		;bc53   ; ha llegado?
	jr c,L_BBF7		;bc56   ; si: guarda la posicion y estado 2
	ret			;bc58
L_BC59:
	call azar_r		;bc59   ; un byte al azar
	and 003h		;bc5c   ; una de cada cuatro veces sigue
	ret nz			;bc5e
	set 0,(ix+00dh)		;bc5f   ; bit 0 de la pose: tirando
	call azar_r		;bc63   ; azar contra la habilidad (IX+0x1D)
	cp (ix+01dh)		;bc66   ; contra la habilidad (IX+0x1D)
	jr nc,L_BC71		;bc69   ; pierde: a pasar
	call roba_balon		;bc6b   ; gana: roba el balon
	jp L_BD5C		;bc6e   ; estado 0
L_BC71:
	call puede_pasar		;bc71   ; puede pasar? (azar contra (IX+0x1E))
	ret nc			;bc74   ; no puede: nada
	xor a			;bc75   ; estado 0 de nuevo
	ld (0f009h),a		;bc76
pasa_a_un_companero:		; Elige al azar el companero 6, 7 u 8 y anota el pase: (0xED6F) controlados, (0xED71) quien pasa, (0xED70) a quien
	call azar_r		;bc79
	and 003h		;bc7c   ; 0-3
	add a,006h		;bc7e   ; companero 6 o 7 u 8 al azar: a quien pasa
	ld e,a			;bc80   ; E = a quien
	call cuantos_controla		;bc81   ; A = controlados, B = indice del que pasa
L_BC84:
	ld (0ed6fh),a		;bc84   ; (0xED6F): pase en marcha, (0xED71) y (0xED70) de quien a quien
	ld a,b			;bc87   ; (0xED71): quien pasa
	ld (0ed71h),a		;bc88
	ld a,e			;bc8b   ; (0xED70): a quien
	ld (0ed70h),a		;bc8c
	ret			;bc8f
puede_pasar:		; Acarreo si el juego esta parado para decidir y un byte al azar no llega a la habilidad (IX+0x1E)
	call se_puede_decidir		;bc90
	ret nc			;bc93   ; no se puede decidir: no
	call azar_r		;bc94   ; un byte al azar
	cp (ix+01eh)		;bc97   ; contra la habilidad (IX+0x1E): acarreo si menor
	ret			;bc9a
hay_sitio_para_tirar:		; Acarreo si nadie lleva el balon, el balon esta a menos de 12 del centro (0xE623) y el jugador IX a menos de 8 de el
	call se_puede_decidir		;bc9b
	ret nc			;bc9e   ; no se puede decidir: no
	ld a,(0e623h)		;bc9f   ; (0xE623): X del balon, con signo
	bit 7,a		;bca2   ; mitad izquierda?
	jr z,L_BCA8		;bca4   ; no: ya es positivo
	neg		;bca6   ; en valor absoluto
L_BCA8:
	cp 00ch		;bca8   ; a 12 o mas del centro: no
	jr nc,L_BCAE		;bcaa
	ccf			;bcac   ; acarreo: hay sitio
	ret			;bcad
L_BCAE:
	call quien_ataca		;bcae   ; quien ataca
	ret nz			;bcb1   ; nadie ataca: no
	ld hl,0e50ch		;bcb2   ; campo +0x0C de los seis registros: alguien lleva el balon?
	ld b,006h		;bcb5   ; los seis jugadores
	ld de,00030h		;bcb7   ; 0x30 bytes por registro
L_BCBA:
	ld a,(hl)			;bcba
	and a			;bcbb   ; lleva el balon?
	ret nz			;bcbc   ; si: no hay sitio
	add hl,de			;bcbd   ; siguiente registro
	djnz L_BCBA		;bcbe
	ld a,(0e621h)		;bcc0   ; (0xE621): Y (profundidad) del balon
	sub (ix+001h)		;bcc3   ; E = diferencia de Y
	ld e,a			;bcc6
	ld a,(0e623h)		;bcc7
	sub (ix+003h)		;bcca   ; L = diferencia de X
	ld l,a			;bccd
	call distancia		;bcce   ; distancia del jugador IX al balon
	cp 008h		;bcd1   ; acarreo si menos de 8
	ret			;bcd3
se_puede_decidir:		; Acarreo (A = 6) si no hay falta ni tiempo muerto en marcha: 0xE6CF sin los bits 3 y 4, 0xED63 y 0xED79 a cero y el estado del juego (0xE6CF & 7) por debajo de 6
	ld a,(0e6cfh)		;bcd4   ; (0xE6CF): estado del partido, bits 3 y 4 = la ventana se esta moviendo
	and 018h		;bcd7   ; la ventana se mueve: no
	ret nz			;bcd9
	ld a,(0ed63h)		;bcda   ; (0xED63): falta en marcha
	and a			;bcdd   ; falta en marcha: no
	ret nz			;bcde
	ld a,(0ed79h)		;bcdf   ; (0xED79): tiempo parado
	and a			;bce2   ; tiempo parado: no
	ret nz			;bce3
	ld a,(0e6cfh)		;bce4
	and 007h		;bce7   ; estado del juego 0-7
	cp 006h		;bce9   ; acarreo si menos de 6
	ret			;bceb
quien_ataca:		; A = (0xE6D4) o (0xE6D6) segun el lado (0xE83C): el equipo que tiene el balon
	ld hl,0e6d4h		;bcec   ; (0xE6D4): quien ataca, lado normal
	ld a,(0e83ch)		;bcef
	and a			;bcf2   ; lados cambiados?
	jr z,L_BCF7		;bcf3
	inc hl			;bcf5   ; (0xE6D6): quien ataca, lados cambiados
	inc hl			;bcf6
L_BCF7:
	ld a,(hl)			;bcf7
	and a			;bcf8   ; cero = nadie
	ret			;bcf9
guarda_posicion_en_f00c:		; Copia la Y (IY+1) y la X (IY+3) del jugador en curso a 0xF00D y 0xF00C
	ld a,(iy+001h)		;bcfa   ; Y del controlado
	ld (0f00dh),a		;bcfd   ; (0xF00D): Y guardada
	ld a,(iy+003h)		;bd00   ; X del controlado
	ld (0f00ch),a		;bd03   ; (0xF00C): X guardada
	ret			;bd06
angulo_y_distancia_a_canasta:		; Para el jugador HL: A = distancia y B = angulo hasta la canasta de 0xE6C3
	push hl			;bd07   ; guarda HL
	push de			;bd08   ; y DE
	ld de,0e6c3h		;bd09   ; 0xE6C3: la posicion de la canasta a la que se ataca
	call xy_dos_registros		;bd0c   ; DE y HL = la Y y la X de los dos
	call diferencia_xy		;bd0f   ; diferencias
	push bc			;bd12
	push de			;bd13
	push hl			;bd14
	call angulo		;bd15   ; A = angulo
	pop hl			;bd18
	pop de			;bd19
	pop bc			;bd1a
	ld b,a			;bd1b   ; B = angulo
	push bc			;bd1c
	call distancia		;bd1d   ; A = distancia
	pop bc			;bd20
	pop de			;bd21
	pop hl			;bd22
	ret			;bd23
cuantos_controla:		; A = los jugadores que controla la maquina en este lado y B = el indice que devuelve 0x4EC5, con los flags de aquel
	push bc			;bd24
	call controlados		;bd25   ; A = controlados, B = indice
	pop bc			;bd28
	ld b,a			;bd29   ; B = indice
	ex af,af'			;bd2a   ; los flags que devolvio 0x4EC5
	push af			;bd2b
	ex af,af'			;bd2c
	pop af			;bd2d
	ret			;bd2e
corrige_destino_x:		; Suma a la X del destino (0xF00E) la X de la canasta de 0xE6C6
	push bc			;bd2f   ; guarda BC
	ld a,(0e6c6h)		;bd30   ; (0xE6C6): X de la canasta que se ataca
	ld b,a			;bd33   ; B = X de la canasta
	ld a,(0f00eh)		;bd34   ; X del destino
	add a,b			;bd37
	ld (0f00eh),a		;bd38   ; corregida
	pop bc			;bd3b   ; recupera BC
	ret			;bd3c
huerfano_niega_si_negativo:		; Huerfano: niega HL si H es negativo (nadie lo llama)
	ld a,h			;bd3d
	and a			;bd3e   ; H negativo?
	ret p			;bd3f   ; no: tal cual
	jp niega_hl		;bd40   ; si: HL = -HL
indice_controlado:		; A = el indice que devuelve 0xBD24 (el jugador controlado de este lado)
	push bc			;bd43   ; guarda BC
	call cuantos_controla		;bd44
	ld a,b			;bd47   ; A = indice
	pop bc			;bd48
	ret			;bd49
ha_llegado:		; Acarreo si el jugador en curso (IY) esta justo en la posicion guardada en 0xF00C/0xF00D; si no, estado 0
	ld a,(0f00dh)		;bd4a   ; (0xF00D): Y guardada
	sub (iy+001h)		;bd4d   ; misma Y?
	jr nz,L_BD5C		;bd50   ; no: estado 0
	ld a,(0f00ch)		;bd52   ; (0xF00C): X guardada
	sub (iy+003h)		;bd55   ; misma X?
	jr nz,L_BD5C		;bd58   ; no: estado 0
	scf			;bd5a   ; acarreo: ha llegado
	ret			;bd5b
L_BD5C:
	xor a			;bd5c   ; (0xF009): estado del ataque a cero
	ld (0f009h),a		;bd5d
	ret			;bd60
decide_defensor:		; La maquina sin el balon: segun 0xF00A va a por el que lo lleva (0), lo marca (1) o se queda (2); con 0xF008 a uno no se mueve
	ld a,(0f008h)		;bd61   ; (0xF008): a uno, la defensa no se mueve
	and a			;bd64   ; defensa parada?
	jp nz,sin_movimiento		;bd65   ; si: sin movimiento
	ld e,039h		;bd68   ; E = 0x39, la Y de la mitad de la pista
	call indice_controlado		;bd6a   ; A = controlados, B = indice
	ld hl,0e623h		;bd6d   ; (0xE623): X del balon, bit 7 = mitad izquierda
	bit 7,(hl)		;bd70   ; bit 7: balon en la mitad izquierda
	jr nz,L_BD7B		;bd72   ; izquierda: 0xBD7B
	cp 003h		;bd74   ; menos de tres controlados: destino abajo (0xBB30)
	jp nc,L_BB30		;bd76   ; tres o mas: destino X = -30 y Y = la mitad
	jr L_BD80		;bd79   ; a decidir de verdad
L_BD7B:
	cp 003h		;bd7b   ; o arriba (0xBB38)
	jp c,L_BB38		;bd7d   ; menos de tres: destino X = +30 y Y = la mitad
L_BD80:
	call cuantos_controla		;bd80   ; A = controlados, B = indice
	call registro_jugador		;bd83   ; HL = registro del controlado
	push hl			;bd86
	pop iy		;bd87   ; IY = ese registro
	ld a,(0f00ah)		;bd89   ; (0xF00A): estado de la defensa, 0-2
	cp 001h		;bd8c   ; estado 1: a por el balon
	jp z,defensa_estado_1		;bd8e
	cp 002h		;bd91   ; estado 2: marcando
	jp z,defensa_estado_2		;bd93
	ld a,(ix+020h)		;bd96   ; destino pendiente: nada que decidir
	or (ix+021h)		;bd99   ; destino pendiente?
	ret nz			;bd9c   ; pendiente: nada
	call distancia_a_canasta		;bd9d   ; distancia del jugador IX a la canasta
	cp 014h		;bda0   ; a menos de 20 de la canasta: se queda
	jr nc,L_BDAA		;bda2
L_BDA4:
	call indice_controlado		;bda4   ; A = indice del controlado
	jp L_BBEC		;bda7   ; a 0xBBEC: orden para el lado
L_BDAA:
	ld a,(0ed8dh)		;bdaa   ; (0xED8D): el reloj de los 30 segundos corre
	and a			;bdad   ; los 30 segundos no corren: se queda (0xBDA4)
	jr z,L_BDA4		;bdae
	push iy		;bdb0   ; HL = registro del controlado
	pop hl			;bdb2
	call angulo_y_distancia_a_canasta		;bdb3   ; angulo y distancia del controlado (IY) a la canasta
	ld c,a			;bdb6   ; C = distancia del controlado
	push bc			;bdb7   ; guarda angulo y distancia
	push ix		;bdb8   ; HL = registro del jugador IX
	pop hl			;bdba
	call angulo_y_distancia_a_canasta		;bdbb   ; y los del jugador IX
	ld e,b			;bdbe   ; E = angulo del jugador IX
	pop bc			;bdbf   ; B = angulo del controlado, C = su distancia
	sub c			;bdc0   ; el defensor mas lejos que el atacante: no vale
	jr c,L_BE03		;bdc1
	ld a,e			;bdc3   ; A = angulo IX
	sub b			;bdc4   ; menos el del controlado
	jr nc,L_BDC9		;bdc5
	neg		;bdc7   ; en valor absoluto
L_BDC9:
	cp 040h		;bdc9   ; diferencia de angulo de 64 o mas: no vale
	jr nc,L_BE03		;bdcb
	call seno_y_coseno		;bdcd   ; seno y coseno del angulo del atacante
	ld a,c			;bdd0   ; A = distancia del controlado
	push af			;bdd1   ; guardada
	call producto_con_signo		;bdd2   ; HL = componente X
	ex de,hl			;bdd5   ; DE = X, HL = seno
	pop af			;bdd6   ; A = distancia otra vez
	call producto_con_signo		;bdd7   ; HL = componente Y
	ld c,h			;bdda   ; C = Y del punto
	ld a,d			;bddb   ; A = X del punto
	ld (0f00eh),a		;bddc   ; (0xF00E): X del punto entre los dos
	call corrige_destino_x		;bddf   ; mas la X de la canasta
	ld a,(0f00eh)		;bde2   ; B = X corregida
	ld b,a			;bde5
	ld a,c			;bde6   ; A = Y del punto
	add a,039h		;bde7   ; mas la mitad de la pista
	ld c,a			;bde9   ; C = Y del punto
	ld a,(iy+001h)		;bdea   ; distancia del atacante al punto
	sub c			;bded   ; menos la del punto
	jr nc,L_BDF2		;bdee
	neg		;bdf0   ; en valor absoluto
L_BDF2:
	ld e,a			;bdf2   ; E = diferencia de Y
	ld a,(iy+003h)		;bdf3   ; X del controlado
	sub b			;bdf6   ; menos la del punto
	jr nc,L_BDFB		;bdf7
	neg		;bdf9   ; en valor absoluto
L_BDFB:
	ld l,a			;bdfb   ; L = diferencia de X
	call distancia		;bdfc
	cp 008h		;bdff   ; a menos de 8: ya esta encima (0xBE2B)
	jr c,defensa_encima		;be01
L_BE03:
	ld (ix+020h),039h		;be03   ; destino: Y 0x39 (la mitad), X la de la canasta menos 2 (o mas 2 en la mitad izquierda)
	ld a,(0e6c6h)		;be07   ; X de la canasta
	inc a			;be0a   ; mas uno
	bit 7,a		;be0b   ; mitad izquierda?
	jr nz,L_BE11		;be0d
	sub 002h		;be0f   ; derecha: dos menos (en total, uno menos)
L_BE11:
	ld (ix+021h),a		;be11   ; destino X
	ld a,001h		;be14   ; estado 1: ir al destino
	ld (0f00ah),a		;be16
	ret			;be19
distancia_a_canasta:		; A = distancia del jugador IX a la canasta (Y en 0xE6C4, X en 0xE6C6)
	ld a,(0e6c4h)		;be1a   ; (0xE6C4): Y (profundidad) de la canasta
	sub (ix+001h)		;be1d   ; menos la Y del jugador
	ld e,a			;be20   ; E = diferencia de Y
	ld a,(0e6c6h)		;be21
	sub (ix+003h)		;be24   ; menos la X del jugador
	ld l,a			;be27   ; L = diferencia de X
	jp distancia		;be28
defensa_encima:		; Ya esta sobre el atacante: si 0x76AE lo permite, espera 20 + azar cuadros (IX+0x26) y pasa al estado 2
	call indice_controlado		;be2b   ; A = indice del controlado
	ld (0ed95h),a		;be2e   ; (0xED95): jugador al que se mira
	call zona_tiro		;be31   ; lo deja mirar?
	and a			;be34
	jp z,L_BDA4		;be35   ; no: a 0xBDA4
	call azar_r		;be38   ; un byte al azar
	and 00fh		;be3b   ; 0-15
	add a,014h		;be3d   ; mas 20
	ld (ix+026h),a		;be3f   ; 20 a 35 cuadros de espera
	ld a,002h		;be42   ; estado 2
	ld (0f00ah),a		;be44
	ret			;be47
defensa_estado_1:		; Estado 1: a menos de 20 de la canasta se queda; a menos de 8 del controlado, le roba o le tapa
	call distancia_a_canasta		;be48
	cp 014h		;be4b   ; a menos de 20 de la canasta: se queda (0xBDA4)
	jp c,L_BDA4		;be4d
	ld a,(iy+001h)		;be50   ; Y del controlado
	sub (ix+001h)		;be53   ; menos la del jugador IX
	ld e,a			;be56   ; E = diferencia de Y
	ld a,(iy+003h)		;be57   ; X del controlado
	sub (ix+003h)		;be5a   ; menos la del jugador IX
	ld l,a			;be5d   ; L = diferencia de X
	call distancia		;be5e   ; distancia del jugador IX al controlado (IY)
	cp 008h		;be61   ; a menos de 8: encima (0xBE71)
	jr c,L_BE71		;be63
	ld a,(ix+020h)		;be65   ; destino pendiente: sigue
	or (ix+021h)		;be68   ; destino pendiente?
	ret nz			;be6b   ; pendiente: sigue
	xor a			;be6c   ; vuelve al estado 0
	ld (0f00ah),a		;be6d
	ret			;be70
L_BE71:
	ld a,(ix+003h)		;be71   ; un paso en X hacia el centro
	and a			;be74   ; X del jugador: a que lado del centro
	jp p,L_BE7B		;be75   ; positivo: hacia abajo (0xBE7B)
	inc a			;be78   ; negativo: un paso hacia el centro
	jr L_BE7C		;be79
L_BE7B:
	dec a			;be7b   ; positivo: un paso hacia el centro
L_BE7C:
	ld (ix+003h),a		;be7c   ; X nueva
	xor a			;be7f
	ld (ix+020h),a		;be80   ; sin destino
	ld (ix+021h),a		;be83
	ld (0f00ah),a		;be86   ; estado 0 y sin destino
	call azar_r		;be89   ; la mitad de las veces tapa
	and 001h		;be8c   ; un bit al azar
	jr nz,defensa_tapa		;be8e   ; a uno: a tapar
	call puede_pasar		;be90   ; puede pasar? (azar contra la habilidad)
	jr nc,defensa_tapa		;be93   ; no puede pasar: a tapar
	push iy		;be95   ; HL = registro del controlado
	pop hl			;be97
	call angulo_y_distancia_a_canasta		;be98
	ld d,a			;be9b   ; D = distancia del controlado
	push ix		;be9c   ; HL = registro del jugador IX
	pop hl			;be9e
	call angulo_y_distancia_a_canasta		;be9f   ; el defensor mas cerca de la canasta que el atacante
	sub d			;bea2   ; distancia IX - distancia controlado
	jr c,defensa_tapa		;bea3   ; IX mas lejos: a tapar
pasa_al_companero_5:		; Anota un pase del controlado al companero 5
	call cuantos_controla		;bea5   ; A = controlados, B = indice
	ld d,a			;bea8   ; D = controlados
	ld a,b			;bea9   ; A = indice del que pasa
	ld b,d			;beaa   ; B = controlados
	ld e,005h		;beab   ; companero 5: a quien pasa
	jp L_BC84		;bead   ; a 0xBC84: anota el pase
defensa_tapa:		; Si no hay desvio de tiro pide la orden 0x10 para el lado (0xF010/0xF011); si lo hay cambia la pose a la de brazos arriba (bits 2-4 de +0x0D mas 0x10)
	call desvio_tiro		;beb0
	and a			;beb3   ; hay desvio?
	jr nz,L_BEC8		;beb4   ; si: cambia la pose (0xBEC8)
	ld c,010h		;beb6   ; C = 0x10: la orden de tirar
L_BEB8:
	call indice_controlado		;beb8   ; A = indice del controlado
L_BEBB:
	cp 003h		;bebb   ; menos de tres controlados: 0xF010, si no 0xF011
	ld hl,0f010h		;bebd
	jr c,L_BEC3		;bec0
	inc hl			;bec2   ; el lado derecho
L_BEC3:
	ld a,(hl)			;bec3   ; ya hay una orden pendiente
	and a			;bec4   ; ya hay orden?
	ret nz			;bec5   ; si: nada
	ld (hl),c			;bec6   ; deja la orden C
	ret			;bec7
L_BEC8:
	ld a,(ix+00dh)		;bec8   ; pose actual
	push af			;becb   ; guarda la pose
	and 0e3h		;becc   ; quita los bits 2-4
	ld b,a			;bece   ; B = la pose sin los bits 2-4
	pop af			;becf   ; recupera la pose
	and 01ch		;bed0   ; y los pone con el 4 a uno: la pose de tapar
	or 010h		;bed2   ; bit 4 a uno: brazos arriba
	or b			;bed4   ; con lo demas
	ld (ix+00dh),a		;bed5   ; pose nueva
	ret			;bed8
defensa_estado_2:		; Estado 2: pasada la espera, elige al azar entre los dos companeros de 0xBF1E el que mira 0x76AE y le pasa el balon
	call distancia_a_canasta		;bed9
	cp 014h		;bedc   ; a menos de 20 de la canasta: se queda (0xBDA4)
	jp c,L_BDA4		;bede
	ld a,(ix+026h)		;bee1   ; (IX+0x26): cuadros de espera
	and a			;bee4   ; espera agotada?
	ret nz			;bee5   ; no: nada
	call azar_r		;bee6   ; un bit al azar
	and 001h		;bee9   ; a uno?
	jr z,$+63		;beeb   ; a cero: a buscar destino (0xBF2A)
	call cuantos_controla		;beed   ; B = indice del controlado
	inc b			;bef0   ; indice + 1
	ld hl,lbf1ch		;bef1   ; 0xBF1C + 2 * (indice + 1): los dos companeros del controlado (tabla 0xBF1E)
L_BEF4:
	inc hl			;bef4   ; dos bytes por jugador
	inc hl			;bef5
	djnz L_BEF4		;bef6
	ld a,(hl)			;bef8   ; A = primer companero
	ld (0ed95h),a		;bef9   ; (0xED95): el companero al que se mira
	call zona_tiro		;befc   ; lo deja mirar?
	and a			;beff   ; no: el segundo (0xBF12)
	jr z,L_BF12		;bf00
	inc hl			;bf02
	ld a,(hl)			;bf03   ; A = segundo companero
	call zona_tiro		;bf04   ; lo deja mirar?
	and a			;bf07   ; no: el primero (0xBF12 con HL ya en el primero)
	jr z,L_BF12		;bf08
	call azar_r		;bf0a   ; al azar, el otro
	and 001h		;bf0d   ; a cero: el segundo
	jr z,L_BF12		;bf0f
	dec hl			;bf11   ; vuelve al primero
L_BF12:
	ld a,(hl)			;bf12   ; A = el companero elegido
	call ficha_suelta		;bf13   ; anota el pase a ese companero
	xor a			;bf16   ; estado 0
	ld (0f00ah),a		;bf17
	ld c,008h		;bf1a   ; C = 8: la orden de pasar
L_BF1C:
	jr L_BEB8		;bf1c

; ----------------------------------------------------------------------
; DATOS companeros: Seis pares: los dos companeros de cada uno de los seis
;   jugadores (0,1,2 en un equipo y 3,4,5 en el otro); se lee desde 0xBF1C +
;   jugador*2 + 2
;   0xbf1e..0xbf2a  (12 bytes)
DATA_companeros:
	defb 001h,002h	; bf1e
	defb 000h,002h	; bf20
	defb 000h,001h	; bf22
	defb 004h,005h	; bf24
	defb 003h,005h	; bf26
	defb 003h,004h	; bf28

; ======================================================================
; CODIGO 0xbf2a..0xbfd4  (170 bytes)
; ======================================================================


defensa_estado_0_destino:		; Estado 0: elige un punto a 10 grados del jugador respecto a la canasta, a un lado o al otro al azar, y lo prueba hasta que cae dentro de la pista
	ld a,(ix+001h)		;bf2a   ; Y relativa a la mitad de la pista (0x3A)
	sub 03ah		;bf2d   ; menos la mitad de la pista (0x3A)
	ld e,a			;bf2f   ; E = Y relativa
	ld a,(0e6c6h)		;bf30
	ld b,a			;bf33   ; B = X de la canasta
	ld a,(ix+003h)		;bf34   ; X relativa a la canasta
	sub b			;bf37   ; A = X del jugador menos la de la canasta
	ld b,014h		;bf38   ; 20 mas, o 0xEC (-20) en la mitad izquierda
	bit 7,(ix+003h)		;bf3a
	jr z,L_BF42		;bf3e   ; mitad derecha: +20
	ld b,0ech		;bf40   ; mitad izquierda: -20
L_BF42:
	add a,b			;bf42   ; X relativa corregida
	ld l,a			;bf43   ; L = X relativa
	push hl			;bf44   ; guarda HL
	push de			;bf45   ; y DE
	call angulo		;bf46   ; angulo del jugador respecto a la canasta
	pop de			;bf49   ; recupera DE
	pop hl			;bf4a   ; y HL
	ld b,a			;bf4b   ; B = angulo
	push bc			;bf4c   ; guarda BC
	call distancia		;bf4d   ; y la distancia
	pop bc			;bf50   ; recupera BC
	ld c,a			;bf51   ; C = distancia
	call azar_r		;bf52   ; un bit al azar: a que lado
	and 001h		;bf55
	ld a,b			;bf57   ; A = angulo
	jr nz,L_BF60		;bf58   ; a uno: 10 grados mas
L_BF5A:
	sub 00ah		;bf5a   ; 10 grados menos
	ld h,000h		;bf5c   ; H = 0: lado menos
	jr L_BF64		;bf5e
L_BF60:
	add a,00ah		;bf60   ; 10 grados mas
	ld h,001h		;bf62   ; H = 1: lado mas
L_BF64:
	push hl			;bf64   ; guarda el lado
	ld e,a			;bf65   ; E = angulo corregido
	call seno_y_coseno		;bf66   ; seno y coseno
	ld a,c			;bf69   ; A = distancia
	call producto_con_signo		;bf6a   ; HL = componente X
	ex de,hl			;bf6d   ; DE = X, HL = seno
	ld a,c			;bf6e   ; A = distancia otra vez
	call producto_con_signo		;bf6f   ; HL = componente Y
	ld a,039h		;bf72   ; Y del punto, 0x39 mas
	add a,h			;bf74   ; mas la componente Y
	ld e,a			;bf75   ; E = Y del punto
	ld a,(ix+003h)		;bf76
	and a			;bf79   ; mitad del jugador
	ld a,d			;bf7a   ; A = componente X
	jp p,L_BF82		;bf7b   ; derecha: 0xBF82
	add a,0b0h		;bf7e   ; X del punto en la mitad izquierda (0xB0 mas)
	jr L_BF84		;bf80
L_BF82:
	add a,050h		;bf82   ; o en la derecha (0x50 mas)
L_BF84:
	ld d,a			;bf84   ; D = X del punto
	cp 064h		;bf85   ; X fuera de 100-155: prueba el otro lado
	jr c,L_BF95		;bf87   ; menos de 100: fuera
	cp 09ch		;bf89
	jr nc,L_BF95		;bf8b   ; 156 o mas: fuera
L_BF8D:
	pop hl			;bf8d   ; recupera el lado
	ld a,h			;bf8e
	and a			;bf8f   ; que lado era?
	ld a,b			;bf90   ; A = angulo
	jr z,L_BF60		;bf91   ; era menos: prueba mas
	jr L_BF5A		;bf93   ; era mas: prueba menos
L_BF95:
	ld a,e			;bf95   ; A = Y del punto
	cp 00ah		;bf96   ; Y fuera de 10-105: prueba el otro lado
	jr c,L_BF8D		;bf98   ; menos de 10: fuera
	cp 06ah		;bf9a
	jr nc,L_BF8D		;bf9c   ; 106 o mas: fuera
	pop hl			;bf9e   ; tira el lado
	ld (ix+020h),e		;bf9f   ; destino (IX+0x20, IX+0x21)
	ld (ix+021h),d		;bfa2   ; destino X
	ld a,001h		;bfa5   ; estado 1
	ld (0f00ah),a		;bfa7   ; estado 1: ir al destino
	ld a,(0e850h)		;bfaa   ; (0xE850): formacion en curso, 0x3F = ninguna
	cp 03fh		;bfad   ; ya hay formacion: listo
	ret nz			;bfaf
	call azar_r		;bfb0   ; al azar 0-3, el 2 se convierte en 3
	and 003h		;bfb3   ; 0-3
	cp 002h		;bfb5   ; 0 o 1?
	jr c,L_BFBA		;bfb7
	inc a			;bfb9   ; 2 -> 3
L_BFBA:
	or 080h		;bfba   ; bit 7: formacion recien elegida
	ld (0e850h),a		;bfbc   ; formacion nueva, marcada
	ret			;bfbf
descuenta_ordenes:		; Resta uno a las ordenes pendientes de los dos lados (0xF010, 0xF011) si no estan a cero
	ld a,(0f010h)		;bfc0
	and a			;bfc3   ; orden pendiente en la izquierda?
	jr z,L_BFCA		;bfc4
	dec a			;bfc6   ; un cuadro menos
	ld (0f010h),a		;bfc7
L_BFCA:
	ld a,(0f011h)		;bfca
	and a			;bfcd   ; orden pendiente en la derecha?
	ret z			;bfce
	dec a			;bfcf   ; un cuadro menos
	ld (0f011h),a		;bfd0
	ret			;bfd3

; ----------------------------------------------------------------------
; DATOS relleno: 44 bytes a 0xFF hasta el final del cartucho
;   0xbfd4..0xc000  (44 bytes)
DATA_relleno:
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfd4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bfe4  ................
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; bff4  ............

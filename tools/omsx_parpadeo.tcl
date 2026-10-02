# omsx_parpadeo.tcl - Mide el parpadeo: cada cuadro lee el registro 5, la
# tabla de atributos activa (32 sprites) y cuenta, linea a linea, cuantos
# sprites caen en cada una; los que pasan del limite del VDP (DS_LIMITE: 4 en
# el TMS9918, 8 en el V9938 en modo de sprites 2) no se pintan. Suma por
# cuadro y escribe un resumen y una lista por cuadro en DS_OUT.
#
#   DS_OUT=<dir> DS_DESDE=16 DS_HASTA=46 DS_LIMITE=4 DS_TECLAS="4 8 0x01 ..."
#   openmsx -machine <maquina> -cart <rom> -script este.tcl
set OUT $::env(DS_OUT)
file mkdir $OUT
set DESDE $::env(DS_DESDE)
set HASTA $::env(DS_HASTA)
set LIMITE $::env(DS_LIMITE)
set TECLAS [expr {[info exists ::env(DS_TECLAS)] ? $::env(DS_TECLAS) : ""}]
# DS_THROTTLE=on para verlo a velocidad real; sin el, a toda maquina
set throttle [expr {[info exists ::env(DS_THROTTLE)] ? $::env(DS_THROTTLE) : "off"}]
set cuadros 0
set sobrantes 0
set lineas_llenas 0
set peor 0
set lista {}
set r0s {}
proc tecla {fila masc} {
    keymatrixdown $fila $masc
    after time 0.2 [list keymatrixup $fila $masc]
}
proc mide {} {
    global cuadros sobrantes lineas_llenas peor lista LIMITE r0s
    set r5 [debug read "VDP regs" 5]
    set r0 [debug read "VDP regs" 0]
    # En el modo de sprites 2 (M4, SCREEN 4) el VDP ignora los bits 0-2 de R5:
    # senalan un bloque de 1 KB, colores en la primera mitad y atributos a +0x200
    if {$r0 & 0x04} {
        set sat [expr {(($r5 & 0xF8) << 7) + 0x200}]
        set terminador 216
    } else {
        set sat [expr {($r5 & 0x7F) << 7}]
        set terminador 208
    }
    set tabla [debug read_block VRAM $sat 128]
    # cuantos sprites por linea
    array set porlinea {}
    for {set l 0} {$l < 192} {incr l} { set porlinea($l) 0 }
    for {set i 0} {$i < 32} {incr i} {
        binary scan [string range $tabla [expr {$i*4}] [expr {$i*4}]] cu y
        if {$y == $terminador} break
        set y0 [expr {($y + 1) & 0xFF}]
        for {set k 0} {$k < 16} {incr k} {
            set l [expr {$y0 + $k}]
            if {$l < 192} { incr porlinea($l) }
        }
    }
    set s 0
    set ll 0
    for {set l 0} {$l < 192} {incr l} {
        if {$porlinea($l) > $LIMITE} { incr s [expr {$porlinea($l) - $LIMITE}]; incr ll }
    }
    incr cuadros
    incr sobrantes $s
    incr lineas_llenas $ll
    if {$s > $peor} { set peor $s }
    lappend lista "$cuadros $s $ll [format %02X $r0] [format %02X $r5]"
    if {[lsearch $r0s $r0] < 0} { lappend r0s $r0 }
}
proc tick {} {
    global DESDE HASTA
    set t [machine_info time]
    if {$t >= $DESDE && $t <= $HASTA} { mide }
    if {$t > $HASTA} { fin } else { after frame tick }
}
proc fin {} {
    global OUT cuadros sobrantes lineas_llenas peor lista r0s
    set f [open "$OUT/parpadeo.txt" w]
    puts $f "cuadros $cuadros"
    puts $f "sprites_no_pintados $sobrantes"
    puts $f "lineas_con_exceso $lineas_llenas"
    puts $f "peor_cuadro $peor"
    puts $f "media_por_cuadro [expr {$cuadros ? double($sobrantes)/$cuadros : 0}]"
    puts $f "r0_vistos $r0s"
    close $f
    set f [open "$OUT/por_cuadro.txt" w]
    foreach x $lista { puts $f $x }
    close $f
    # captura y volcado del ultimo instante
    screenshot "$OUT/pantalla.png"
    set f [open "$OUT/final.vram" wb]; puts -nonewline $f [debug read_block VRAM 0 16384]; close $f
    set r ""
    for {set i 0} {$i < 16} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    set f [open "$OUT/final.regs" wb]; puts -nonewline $f $r; close $f
    after time 0.5 exit
}
foreach {t fila masc} $TECLAS { after time $t [list tecla $fila $masc] }
after frame tick

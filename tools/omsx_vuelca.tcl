# omsx_vuelca.tcl - Volcados para cotejar: VRAM (16 KB), RAM 0xC000-0xFFFF y
# registros del VDP en los instantes de DS_T (segundos emulados). Pulsa las
# teclas de DS_TECLAS ("t fila mascara" por pulsacion) en su instante. Cada
# volcado va a DS_OUT/tNNN.*
#
#   DS_OUT=<dir> DS_T="5 20" openmsx -machine C-BIOS_MSX1_JP -cart dunkshot.rom \
#       -script este.tcl
set OUT $::env(DS_OUT)
file mkdir $OUT
set TS $::env(DS_T)
set TECLAS [expr {[info exists ::env(DS_TECLAS)] ? $::env(DS_TECLAS) : ""}]
set throttle off
proc guarda {nom datos} {
    set f [open "$::OUT/$nom" wb]; puts -nonewline $f $datos; close $f
}
proc vuelca {t} {
    set n [format t%03d $t]
    guarda $n.vram [debug read_block VRAM 0 16384]
    guarda $n.ram [debug read_block memory 0xC000 0x4000]
    set r ""
    for {set i 0} {$i < 8} {incr i} { append r [format %c [debug read "VDP regs" $i]] }
    guarda $n.regs $r
}
proc tecla {fila masc} {
    keymatrixdown $fila $masc
    after time 0.2 [list keymatrixup $fila $masc]
}
foreach {t fila masc} $TECLAS { after time $t [list tecla $fila $masc] }
foreach t $TS { after time $t [list vuelca $t] }
after time [expr {[lindex [lsort -real $TS] end] + 1}] exit

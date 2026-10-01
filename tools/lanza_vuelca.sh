#!/bin/sh
# lanza_vuelca.sh <dir> "<instantes>" ["<t fila mascara> ..."]: UN openMSX con
# tools/omsx_vuelca.tcl; deja <dir>/fin.txt al acabar.
#
# Se lanza FUERA del sandbox (desde PowerShell, Start-Process de bash.exe con
# este guion): desde dentro openMSX arranca pero no ejecuta el -script.
R=$(cd "$(dirname "$0")/.." && pwd)
D=$R/$1
mkdir -p $D
cd $R && DS_OUT=$D DS_T="$2" DS_TECLAS="$3" timeout 600 "/c/Program Files/openMSX/openmsx.exe" -machine C-BIOS_MSX1_JP -cart dunkshot.rom -script tools/omsx_vuelca.tcl > $D/log.txt 2>&1
echo hecho > $D/fin.txt

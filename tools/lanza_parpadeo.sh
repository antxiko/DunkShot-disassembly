#!/bin/sh
# lanza_parpadeo.sh <dir> <maquina> <rom> <limite> <desde> <hasta> "<t fila masc> ...":
# UN openMSX con tools/omsx_parpadeo.tcl. Deja <dir>/parpadeo.txt y fin.txt.
# Se lanza FUERA del sandbox (PowerShell Start-Process de bash.exe).
R=$(cd "$(dirname "$0")/.." && pwd)
D=$R/$1
mkdir -p $D
cd $R && DS_OUT=$D DS_LIMITE=$4 DS_DESDE=$5 DS_HASTA=$6 DS_TECLAS="$7" timeout 900 "/c/Program Files/openMSX/openmsx.exe" -machine $2 -cart $3 -script tools/omsx_parpadeo.tcl > $D/log.txt 2>&1
echo hecho > $D/fin.txt

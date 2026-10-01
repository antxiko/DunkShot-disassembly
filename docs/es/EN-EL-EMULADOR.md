# En el emulador

Los cotejos se hicieron con openMSX y la máquina C-BIOS_MSX1_JP. El guion
`tools/omsx_vuelca.tcl` pulsa las teclas que se le dicen en los segundos que
se le dicen y vuelca la VRAM entera, la RAM de 0xC000 en adelante y los
registros del VDP; `tools/lanza_vuelca.sh` lo lanza:

    sh tools/lanza_vuelca.sh work/v_titulo "6 12"
    sh tools/lanza_vuelca.sh work/v_partido2 "16 20 25 30 45" "4 8 0x01 8 8 0x01 12 8 0x01"
    sh tools/lanza_vuelca.sh work/v_menus "12 19 26" "4 8 0x01 7 8 0x40 9 8 0x01 14 8 0x40 16 8 0x01"

Las teclas van como `segundo fila máscara` de la matriz del teclado: espacio
es la fila 8 con 0x01 y abajo la fila 8 con 0x40. Espacio en los segundos 4,
8 y 12 lleva del título al menú, de ahí a SET-UP y de ahí al partido.

Después, `tools/coteja.py` compara la VRAM montada con el volcado: la tabla de
nombres y, de cada tercio, el patrón y el color de los tiles que se usan. Lo
que queda en la VRAM de pantallas anteriores y no se usa no cuenta.

    python3 tools/coteja.py work/partido_12.vram work/v_partido2/t020.vram work/v_partido2/t020.regs

## Lo cotejado

A 0 diferencias: el título (dos volcados), el primer menú, SET-UP, la ficha de
equipo, LOAD DATA con SURE? y con ERROR!, y el partido al saque (dos volcados,
con la ventana en la columna 12). Y los 24 sprites de los seis jugadores en
esos dos volcados: pose, patrones, colores y la posición de los pies que se
deduce de los cuatro desplazamientos.

![El título](../imagenes/titulo.png)

Los volcados no viajan con el repositorio; lo que viaja es el sha256 de cada
VRAM montada (`tests/test_juego.py`), para que un cambio en los descompresores
o en el montaje salte en los tests.

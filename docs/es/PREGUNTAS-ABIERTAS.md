# Preguntas abiertas

- Las pantallas de equipo con una plantilla humana (MAKE TEAM, EDIT TEAM,
  STARTERS, TRADE) y la de estadísticas: vistas en el emulador, sin montar
  desde la ROM.
- Los mandos del segundo jugador en el teclado: el código lee las filas 3 y 5
  de la matriz (`0xBA1F`, `0xBA27`) con la tabla de `0xBA8D`; qué teclas son
  exactamente no se ha comprobado jugando.
- Qué miden S, J y R. El juego no lo dice en ningún texto; en el código las
  habilidades que deciden robos y pases son los campos +0x1D y +0x1E del
  registro.
- `0x4EEC`: si `ld hl,(0xE6DF)` es un fallo del original o no. Lo que hace
  está medido; lo que debía hacer, no.
- El código de cada punto de las jugadas (0x64, 0x78, 0x3C, 0x28, 0x00).
- Qué poses de las 160 no se usan: las secuencias de animación están en el
  código, no en una tabla.
- El listado lleva 113 líneas marcadas SUPOSICION: lo que no está medido en
  openMSX.

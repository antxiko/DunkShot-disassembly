# The game

Dunk Shot is **three-on-three** basketball seen from the stands: a court
almost twice as wide as the screen, two teams of three players on court (from
a roster of eight) and a match in two halves of 5, 10, 15 or 20 minutes.

![The whole court](imagenes/pista_area1.png)

## The menus

Space takes you from the title to the first menu: **SET-UP**, **LEFT TEAM**,
**RIGHT TEAM** and **TRADE**. Left alone, after 1,500 frames (`0x405E`) the
demo starts.

The two team screens have MAKE TEAM (a three-letter name and eight players
of eight letters), LOAD DATA, READY-MADE, COMPUTER (the eight computer teams)
and EDIT TEAM, with STARTERS to pick the three starters and SAVE DATA and
VERIFY for the tape. TRADE swaps players between the two teams.

![The team screen](imagenes/equipo.png)

SET-UP has PLAY, STARTERS, CHANGE SIDES, COLOR OF WEAR, LENGTH OF HALF (5, 10,
15 or 20 minutes: `0x73A3` multiplies by 300 seconds) and COLOR OF COURT, the
three courts. At start-up both teams belong to the computer: with PLAY the
match plays itself.

![SET-UP](imagenes/setup.png)

## The teams

A player takes 29 bytes (`0x7E2E` returns the field asked for): eight letters
of name, the look (0-31, one of the 32 skin-and-hair pairs at `0x80E4`) and
the skills, which the statistics screen labels **S**, **J** and **R**. A team
is 0xEC bytes: three letters, the level, the colour and the eight players.

The eight computer teams, ELM, JNR, HIG, COL, YUG, ESP, USA and PRO, are
levels 1 to 8: `0x72CA` generates their players with 30, 20 and 25 points plus
30 for each level above the first, and a random look. That 0xEC-byte block is
what SAVE DATA writes to tape and what TRADE swaps (`0x8201`).

![The 32 looks](imagenes/colores_jugadores.png)

## The match

Six players on court, each with their two fixed team-mates (`0xBF1E`), the
ball and the net. The whole court is 56 columns (`0xB69E`); the screen shows
32 and jumps one column at a time (`0x5F33`, `0x5E7C`). At the top, the
scoreboard: names, team fouls (TF), points, time and half.

![The match at the tip-off](imagenes/partido.png)

A basket is worth 2 inside the key and from mid-range, 3 from forty or more
away from the basket and 1 for a free throw (`0x772E`); three seconds in the
key (210 frames, `0x76EA`) is 3 SECOND.

The fouls and violations the game calls are the twelve at `0x796F`:
TRAVELLING, 3, 5, 10 and 30 SECOND, CHARGING, HACKING, HOLDING, PUSHING and
BLOCKING, plus the two counter labels. The statistics screen carries FOULS
and FATIGUE per player. At the break, HALF TIME; at the end, GAME OVER and
PUSH ANY KEY (`0x8BF3`, `0x8C21`).

## The controls

Read from the code (`0xB9C3` and `0xBA16`): the human team on the left uses
joystick 1 or, failing that, the cursor keys with `[` to shoot and RETURN to
pass; the one on the right, joystick 2 or four keys from rows 3 and 5 of the
keyboard matrix with TAB and CTRL. Button 2 of the team with the ball in the
opponent's half changes the play; the one of the team without the ball
changes the controlled defender (`0x622A`, `0x627F`). The menus take the
cursor keys, space and ESC.

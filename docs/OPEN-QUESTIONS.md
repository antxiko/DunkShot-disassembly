# Open questions

- The team screens with a human roster (MAKE TEAM, EDIT TEAM, STARTERS,
  TRADE) and the statistics screen: seen in the emulator, not built from the
  ROM.
- The second player's keyboard controls: the code reads rows 3 and 5 of the
  matrix (`0xBA1F`, `0xBA27`) through the table at `0xBA8D`; exactly which
  keys they are has not been checked by playing.
- What S, J and R measure. The game never says; in the code, the skills that
  decide steals and passes are fields +0x1D and +0x1E of the record.
- `0x4EEC`: whether `ld hl,(0xE6DF)` is a bug in the original or not. What it
  does is measured; what it was meant to do is not.
- The code byte of each waypoint in the plays (0x64, 0x78, 0x3C, 0x28, 0x00).
- Which of the 160 poses are never used: the animation sequences are in the
  code, not in a table.
- The listing carries 113 lines marked SUPOSICION: what has not been measured
  in openMSX.

# The MSX2 patch

Dunk Shot flickers because every player is four sprites stacked on top of
each other and the TMS9918 draws no more than four per line: the game shares
them out on purpose, rotating seven groups every frame between two attribute
tables ([The code](THE-CODE.md#the-sprites-and-the-flicker)). The V9938 of
the MSX2 draws eight per line, so the same cartridge can stop sharing them
out. `parche/dunkshot_msx2.ips` is a 292-byte IPS patch that does that: 164
bytes changed in 24 stretches, and the result still plays on an MSX1 as the
original does.

## Measured, before and after

The probe `tools/omsx_parpadeo.tcl` reads, every frame, the attribute table
the VDP is showing and counts, line by line, the sprites above the VDP's
limit (four on the TMS9918, eight on the V9938 in sprite mode 2): those are
the ones that are not drawn. Thirty seconds of a match started with the
space bar from the title; the computer plays both sides, so no two matches
are the same.

| cartridge | machine | frames | sprites not drawn, per frame | worst frame |
|---|---|---|---|---|
| original | C-BIOS_MSX1_JP (MSX1, 60 Hz) | 1,798 | 66.7 | 166 |
| patched | C-BIOS_MSX1_JP (MSX1, 60 Hz) | 1,798 | 69.5 | 175 |
| patched | Philips_NMS_8250 (MSX2, 50 Hz) | 1,505 | 1.7 | 22 |

On the MSX1 the patched cartridge behaves like the original: register 5
alternates between its two tables, 899 frames each. On the MSX2 what is
left are the moments when five or six players pile up on the same lines
with the ball and its shadow, more than eight; the game's own rotation still
shares those out. The match clock runs at the same pace.

    sh tools/lanza_parpadeo.sh work/p_msx1 C-BIOS_MSX1_JP dunkshot.rom 4 16 46 "4 8 0x01 7 8 0x01 10 8 0x01"
    sh tools/lanza_parpadeo.sh work/p_msx2 Philips_NMS_8250 work/dunkshot_msx2.rom 8 20 50 "8 8 0x01 11 8 0x01 14 8 0x01"

The arguments are the output directory, the machine, the ROM, the limit, the
seconds measured and the keys as in [In the emulator](IN-THE-EMULATOR.md);
the MSX2 boots later, hence the later keys. With `DS_THROTTLE=on` it runs at
real speed, to watch it. Everything here is measured in openMSX; nobody has
run it on real hardware yet.

## What the V9938 changes

SCREEN 4 (mode G3) is SCREEN 2 with sprites in mode 2: same pattern, name
and colour tables, so the game's graphics need no change. Three things
differ:

- Register 0 gets bit 2 (M4) instead of bit 1 (M3). The TMS9918 has no M4,
  so on an MSX1 it must not be touched.
- Register 5, with bits 0-2 set to 1 (the VDP ignores them), points at a
  1 KB block: its first half is the sprite colour table, 16 bytes per
  sprite, one colour per line (bit 7 = early clock, as in the attribute),
  and the 128 bytes of attributes sit at +0x200. The colour byte of the
  attribute is ignored. It is what the BIOS does in SCREEN 4: R5 = 0x3F,
  colours at 0x1C00, attributes at 0x1E00.
- The end of the list is Y = 216, not 208.

Below the 16 KB of an MSX1 the game leaves only 0x3C00-0x3FFF unused (the
sprite patterns end at 0x3BBF), so: colours at 0x3C00-0x3DFF, attributes at
0x3E00, and the second table the MSX1 alternates at 0x3F00. On an MSX1,
R5 = 0x7C or 0x7E points at those two tables; on an MSX2, R5 is always 0x7F
and the VDP shows 0x3E00 both frames, the rotated list of 0xE7B0, from which
the colours are taken. No pattern moves.

## What changes in the cartridge

- `0x5036`: `jp INIGRP` goes to a hook in the 0xFF filler at `0xBFD4`: after
  INIGRP, ATRBAS = 0x3E00 and R5 = 0x7C; if the BIOS is an MSX2's (byte
  0x002D), also R0 = 4 and R5 = 0x7F.
- `0x5B7B`: `xor 4` becomes `xor 1`: the alternation is 0x3E00 / 0x3F00.
  Its WRTVDP (`0x5B82`) goes through `0xBFF3`, which on an MSX2 always writes
  0x7F. `0x5B9B` compares with 0x3E, the table `congela_sprites` leaves
  showing.
- `0x5BE6`, `0x5BF2`: the two copies per frame go to 0x3E00 and 0x3F00; the
  second continues at `0x7AAE` with the colour table: the 32 colours of the
  list at 0xE7B0, 16 bytes each, to 0x3C00 with `out` and interrupts off
  (`0x6EA0`). On an MSX1 it returns at once.
- `0x5BFB`, `0x7374`, `0x8057`: the ends of the list write 0xD0 and, in the
  next entry, 0xD8 (`0x6EC9`).
- `0x5063`, `0x804C`, `0x80D5`, `0x80DC`: 0x1B00 and 0x1B10 become 0x3E00
  and 0x3E10.
- `0x80CE`: the end of `viste_jugador`, the sample figure of the team cards
  and of TRADE, jumps to `0x6F30`: it reads the eight attributes back from
  VRAM and fills their colours, so the figure keeps its skin, hair and shirt
  on an MSX2 too.

The new code lives in the filler at 0xBFD4-0xBFFD and in three orphan
routines nobody calls (0x6EA0, 0x6F30, 0x7AAE). `tools/parche_msx2.py`
assembles the pieces with Pasmo, patches the operands and writes the ROM,
the IPS and `parche/parche_msx2.asm`, the listing of the new code;
`tests/test_parche.py` checks that the IPS reproduces it and touches only
those stretches.

    make parche     # work/dunkshot_msx2.rom and parche/dunkshot_msx2.ips, from dunkshot.rom

## Applying it

The IPS applies to the 32 KB cartridge (sha256 `a1891e03...`), with any IPS
tool or with these lines of Python:

    rom = bytearray(open("dunkshot.rom", "rb").read())
    ips = open("parche/dunkshot_msx2.ips", "rb").read()
    i = 5
    while ips[i:i + 3] != b"EOF":
        a, n = int.from_bytes(ips[i:i + 3], "big"), int.from_bytes(ips[i + 3:i + 5], "big")
        rom[a:a + n] = ips[i + 5:i + 5 + n]
        i += 5 + n
    open("dunkshot_msx2.rom", "wb").write(rom)

The result has sha256 `e5e14b0f7b188b77ae7b8daa28d98ee1e8c9bfc3d6479b9b93c0afbfd1037e6c`
and is not distributed either. In openMSX:

    openmsx -machine Philips_NMS_8250 -cart dunkshot_msx2.rom

Any MSX2 will do; on an MSX1 it plays as the original.

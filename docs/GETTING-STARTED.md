# Getting started

You need Python 3, GNU make, [Pasmo](https://pasmo.speccy.org/) and your own
image of the cartridge as `dunkshot.rom` at the root of the repository (32,768
bytes; `make comprueba` checks the sha256). The ROM is not distributed.

    make            # listing, reassembly, checks and tests
    make imagenes   # the website pictures, from the ROM
    make web        # the bilingual website in docs/
    make parche     # the MSX2 patch: work/dunkshot_msx2.rom and parche/dunkshot_msx2.ips

`make` generates `src/dunkshot.asm` from the binary and the notes
(`src/dunkshot.notes`), reassembles it with Pasmo and checks that the exact
ROM comes out; then it runs the checks that reassembly does not cover: that
no data is read as code, that no entry point falls inside a data area and
that not a single byte is left unassigned.

## The tools

- `tools/z80trace.py` and `tools/mkasm.py`: the tracer and the listing
  generator. The entry points the trace cannot deduce (the interrupt hook, the
  eight `jp` at 0xB985 and the orphan code) are in `src/dunkshot.entries`,
  each with its reason.
- `tools/graficos.py`: the cartridge's four decompressors and the drawing of
  patterns and sprites. `tools/pantallas.py` builds each screen in a VRAM;
  `tools/coteja.py` compares it with an openMSX dump; `tools/imagenes.py`
  generates the gallery.
- `tools/sonido.py` walks the thirteen pieces the way the engine reads them.
- `tools/lanza_vuelca.sh` and `tools/omsx_vuelca.tcl`: an openMSX that presses
  keys at the given instants and dumps VRAM, RAM and registers.
- `tools/parche_msx2.py` builds the MSX2 patch and `tools/omsx_parpadeo.tcl`
  with `tools/lanza_parpadeo.sh` measures the flicker, frame by frame
  ([The MSX2 patch](THE-MSX2-PATCH.md)).
- `tools/densidad.py`, `tools/huecos.py`, `tools/margen.py` and
  `tools/sin_bautizar.py`: the measure of the comments.

## The notes

The listing is not edited by hand: every comment is a directive in the notes
file anchored to an address (`C 0x5F33 text`), every named routine an `L`,
and every data block a `D` with its measurement. `make listado` applies them
and `tools/valida_c.py` warns if one lands mid-instruction or is repeated.

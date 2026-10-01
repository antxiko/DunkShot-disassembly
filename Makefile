# Dunk Shot (HAL Laboratory, MSX1) - desensamblado
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como dunkshot.rom, y
# `make comprueba` verifica su sha256.

ROM      = dunkshot.rom
SHA      = a1891e038566596a9f67067b8ea4694709aa9fee93c8ac0379360b30ea3abe62
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = DUNK SHOT - HAL Laboratory - MSX1 - cartucho de 32 KB en las paginas 1 y 2

all: listado verify sanity test

$(ROM):
	@echo "=================================================================="
	@echo " Falta $(ROM), y este repositorio NO lo distribuye."
	@echo ""
	@echo " Es Dunk Shot (HAL Laboratory, 1986) para MSX, 32768 bytes exactos."
	@echo " Ponlo aqui con ese nombre. Para comprobar que es el mismo:"
	@echo "     shasum -a 256 $(ROM)"
	@echo "     $(SHA)"
	@echo "=================================================================="
	@false

comprueba: $(ROM)
	@echo "$(SHA)  $(ROM)" | shasum -a 256 -c -

# El trazado sigue el flujo desde los puntos de entrada. Los que no se pueden
# deducir estaticamente -ganchos de interrupcion, destinos de saltos
# indirectos- estan declarados en el .entries, cada uno con su justificacion.
$(WORK)/dunkshot.trace.json: $(ROM) $(SRC)/dunkshot.entries $(SRC)/dunkshot.nocode
	@mkdir -p $(WORK)
	python3 tools/z80trace.py $(ROM) $(ORG) $(SRC)/dunkshot.entries \
	        $(WORK)/dunkshot $(SRC)/dunkshot.nocode

trace: $(WORK)/dunkshot.trace.json

listado: $(WORK)/dunkshot.trace.json $(SRC)/dunkshot.notes
	python3 tools/mkasm.py $(ROM) $(ORG) $(WORK)/dunkshot.trace.json \
	        $(SRC)/dunkshot.notes work/msx.sym $(SRC)/dunkshot.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/dunkshot.asm $(ROM)
	@sh tools/verify_build.sh $(SRC)/dunkshot.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/dunkshot.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 tools/check_trace.py $(WORK)/dunkshot.trace.json $(SRC)/dunkshot.nocode
	@python3 tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 tools/check_entradas.py $(SRC)/dunkshot.entries $(SRC)/dunkshot.notes \
	        $(SRC)/dunkshot.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 tools/densidad.py $(SRC)/dunkshot.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# LAS IMAGENES, montadas desde la ROM con tools/pantallas.py: ni una captura.
imagenes: $(ROM)
	python3 tools/imagenes.py $(ROM) docs/imagenes

# Y la prueba de que son las de verdad: cada pantalla contra un volcado de
# VRAM de openMSX, byte a byte (los volcados, en work/: ver coteja_todo.py).
coteja: $(ROM)
	@python3 tools/coteja_todo.py $(ROM)

# LA WEB. Bilingue: el ingles en docs/ y el castellano en docs/es/.
web: imagenes
	python3 tools/md2html.py docs en
	python3 tools/md2html.py docs/es es
	python3 tools/make_web.py docs/imagenes docs/index.html en
	python3 tools/make_web.py docs/imagenes docs/es/index.html es
	python3 tools/check_enlaces.py docs

clean:
	rm -rf $(WORK)/dunkshot.trace.json $(WORK)/dunkshot.blocks

.PHONY: all comprueba trace listado verify sanity test densidad imagenes coteja web clean

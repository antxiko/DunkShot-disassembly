# Dunk Shot, version "a" (GoodMSX [a], HAL Laboratory, MSX1) - desensamblado
#
# La corregida: el mismo programa que el primero, reensamblado y con arreglos
# (faltas, puntuacion, defensa). Vive en rom_a/ y comparte las herramientas de
# ../tools; ../DIFERENCIAS-ROM-A.md dice que cambia. `make -C rom_a`.
#
# El orden de las cosas: trazar el flujo -> generar el listado -> comprobar que
# vuelve a dar la ROM byte a byte -> las comprobaciones que el reensamblado NO
# cubre.
#
# El cartucho no se distribuye: hace falta en la raiz como dunkshot.rom (la version "a"), y
# `make comprueba` verifica su sha256.

ROM      = dunkshot.rom
SHA      = a9e759aeb5c94c3060095d4e50c8170b80ab08df95d8a5666a29badf0a912adf
SRC      = src
WORK     = work
ORG      = 0x4000
TITULO   = DUNK SHOT (version a, GoodMSX) - HAL Laboratory - MSX1 - cartucho de 32 KB en las paginas 1 y 2

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
	python3 ../tools/z80trace.py $(ROM) $(ORG) $(SRC)/dunkshot.entries \
	        $(WORK)/dunkshot $(SRC)/dunkshot.nocode

trace: $(WORK)/dunkshot.trace.json

listado: $(WORK)/dunkshot.trace.json $(SRC)/dunkshot.notes
	python3 ../tools/mkasm.py $(ROM) $(ORG) $(WORK)/dunkshot.trace.json \
	        $(SRC)/dunkshot.notes work/msx.sym $(SRC)/dunkshot.asm "$(TITULO)"

# La prueba que decide si el desensamblado es fiable.
verify: $(SRC)/dunkshot.asm $(ROM)
	@sh ../tools/verify_build.sh $(SRC)/dunkshot.asm $(ROM) $(ORG)

# Lo que el reensamblado NO puede cazar: que unos datos se esten leyendo como
# codigo. El binario sale identico igual, porque los bytes no cambian; lo unico
# que cambia es lo que decimos de ellos.
sanity: $(WORK)/dunkshot.trace.json
	@echo "=================================================================="
	@echo " ningun byte declarado como datos puede salir como codigo"
	@echo "=================================================================="
	@python3 ../tools/check_trace.py $(WORK)/dunkshot.trace.json $(SRC)/dunkshot.nocode
	@python3 ../tools/check_datos_como_codigo.py $(WORK) $(SRC)
	@echo "=================================================================="
	@echo " ningun punto de entrada puede caer dentro de una zona de datos"
	@echo "=================================================================="
	@python3 ../tools/check_entradas.py $(SRC)/dunkshot.entries $(SRC)/dunkshot.notes \
	        $(SRC)/dunkshot.nocode
	@echo "=================================================================="
	@echo " ni un byte del cartucho sin asignar"
	@echo "=================================================================="
	@python3 ../tools/presupuesto.py $(WORK) $(SRC)

densidad:
	@python3 ../tools/densidad.py $(SRC)/dunkshot.asm

test:
	@echo "=================================================================="
	@echo " Tests"
	@echo "=================================================================="
	@python3 -m unittest discover -s tests -v

# EL PARCHE MSX2: sprites en modo 2 (ocho por linea) en un MSX2, el mismo
# fichero sigue valiendo en un MSX1. Necesita pasmo en el PATH (o PASMO=...).
parche: $(ROM)
	@mkdir -p parche
	python3 ../tools/parche_msx2.py $(ROM) $(WORK)/dunkshot_a_msx2.rom parche/dunkshot_a_msx2.ips parche/parche_msx2_a.asm

clean:
	rm -rf $(WORK)/dunkshot.trace.json $(WORK)/dunkshot.blocks

.PHONY: all comprueba trace listado verify sanity test densidad parche clean

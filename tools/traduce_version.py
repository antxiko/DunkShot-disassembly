#!/usr/bin/env python3
"""Pasa el desensamblado de una VERSION de Dunk Shot a otra.

La version "a" de Dunk Shot (GoodMSX [a]) es el mismo programa reensamblado
con cambios: casi todas las rutinas estan en otro sitio y TODA la RAM de
trabajo esta repartida de otra manera (0xE6C2 pasa a ser 0xC5D2, etc.). Un
`diff` binario no sirve: cada `call`, cada `ld a,(nn)` cambia de operando.

Lo que hace esta herramienta, en orden:

 1. Empareja cada instruccion del desensamblado viejo con la de la ROM nueva.
    El patron de una instruccion es su codigo con el operando absoluto
    (>= 0x4000) como comodin; cuando el operando ya se sabe traducir
    (mapa de RAM y mapa de ROM de la pasada anterior), el comodin pasa a ser
    el valor traducido. Cuatro pasadas: cada una afina el emparejamiento de la
    siguiente, y lo que no encaja DEJA DE EMPAREJARSE: queda como CAMBIO real.
 2. Saca el mapa de RAM por votacion (cada `ld a,(nn)` emparejado es un voto
    viejo->nuevo) y exige que no haya ni un conflicto.
 3. Traduce entradas, notas y comentarios del desensamblado viejo a la ROM
    nueva (direcciones de las directivas y las que van dentro de los textos).
 4. Deja en work/version_*.txt todo lo que NO se pudo traducir o es cambio.

Uso: traduce_version.py DIR_VIEJO ROM_NUEVA DIR_SALIDA
  DIR_VIEJO  repo del desensamblado de la version vieja (dunkshot.rom,
             work/dunkshot.trace.json y src/ con entries y notes)
"""
import bisect
import collections
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import z80trace as zt  # noqa: E402

NN = {o for o in range(256) if zt.BASE_LEN[o] == 3}


class Mapa:
    def __init__(self, dir_viejo, rom_nueva):
        self.dv = dir_viejo
        self.old = open(os.path.join(dir_viejo, "dunkshot.rom"), "rb").read()
        self.new = open(rom_nueva, "rb").read()
        t = json.load(open(os.path.join(dir_viejo, "work", "dunkshot.trace.json")))
        self.blocks = t["blocks"]
        tr = zt.Tracer(self.old, 0x4000)
        self.ins = []
        for k, a, b in self.blocks:
            if k == "c":
                p = a
                while p < b:
                    n = tr.ilen(p)
                    self.ins.append((p, n))
                    p += n
        self.RAM = {}
        self.SEG = []
        self.mp = {}

    # ---- operandos absolutos de 16 bits (>= 0x4000)
    def opoff(self, a, n):
        o = a - 0x4000
        op = self.old[o]
        if n == 3 and op in NN:
            off = 1
        elif n == 4 and op == 0xED and self.old[o + 1] in zt.ED_LEN4:
            off = 2
        elif n == 4 and op in (0xDD, 0xFD) and self.old[o + 1] in (0x21, 0x22, 0x2A):
            off = 2
        else:
            return None
        v = self.old[o + off] | self.old[o + off + 1] << 8
        # 0x8000 y 0xC000 son los limites de pagina (ld hl,0x8000 = "pagina 2"),
        # no direcciones que se muevan
        return (off, v) if v >= 0x4000 and v not in (0x8000, 0xC000) else None

    def rom_map(self, v):
        i = bisect.bisect_right(self.SEG, (v, 1 << 30, 0)) - 1
        if i >= 0 and self.SEG[i][0] <= v < self.SEG[i][1]:
            return v + self.SEG[i][2]
        return None

    def tr_op(self, v):
        if v >= 0xC000:
            return self.RAM.get(v)
        return self.rom_map(v)

    def pat(self, a, n):
        b = self.old[a - 0x4000:a - 0x4000 + n]
        w = self.opoff(a, n)
        if not w:
            return re.escape(b)
        off, v = w
        m = self.tr_op(v)
        pre = re.escape(b[:off])
        if m is None:
            return pre + b".." + re.escape(b[off + 2:])
        return pre + re.escape(bytes([m & 255, m >> 8])) + re.escape(b[off + 2:])

    def alinea(self):
        new, ins = self.new, self.ins
        mp = {}
        shift = 0
        i = 0
        M = len(ins)
        pats = [self.pat(a, n) for a, n in ins]
        cre = {}

        def rx(s):
            r = cre.get(s)
            if r is None:
                r = cre[s] = re.compile(s, re.S)
            return r
        while i < M:
            a, n = ins[i]
            j = a - 0x4000 + shift
            if 0 <= j and j + n <= len(new) and rx(pats[i]).fullmatch(new, j, j + n):
                mp[a] = a + shift
                i += 1
                continue
            hecho = False
            for K in (12, 8, 6, 5, 4):
                run = [i]
                for q in range(i + 1, min(M, i + K)):
                    if ins[q][0] == ins[run[-1]][0] + ins[run[-1]][1]:
                        run.append(q)
                    else:
                        break
                if len(run) < K:
                    continue
                pt = b"".join(pats[q] for q in run)
                cands = [m.start() for m in re.finditer(b"(?=(" + pt + b"))", new, re.S)]
                if not cands:
                    continue
                exp = a - 0x4000 + shift
                cands.sort(key=lambda c: abs(c - exp))
                if K <= 5 and abs(cands[0] - exp) > 0x300:
                    continue
                if len(cands) > 1 and K < 8 and abs(cands[0] - exp) > 0x300:
                    continue
                shift = cands[0] - (a - 0x4000)
                hecho = True
                break
            if hecho:
                continue
            i += 1
        return mp

    def relativos(self, mp):
        """Saltos relativos (jr, djnz) cuyo desplazamiento cambio porque se
        inserto o quito codigo en medio: se emparejan si van detras de una
        instruccion emparejada, llevan el mismo codigo de operacion y su
        destino nuevo es la imagen del destino viejo."""
        REL = {0x10, 0x18, 0x20, 0x28, 0x30, 0x38}
        new, old = self.new, self.old
        total = 0
        while True:
            cambios = 0
            for k, (a, n) in enumerate(self.ins):
                if a in mp or n != 2 or old[a - 0x4000] not in REL or k == 0:
                    continue
                pa, pn = self.ins[k - 1]
                if pa not in mp or pa + pn != a:
                    continue
                e = mp[pa] + pn
                if new[e - 0x4000] != old[a - 0x4000]:
                    continue
                o = old[a - 0x4000 + 1]
                told = a + 2 + (o - 256 if o > 127 else o)
                x = new[e - 0x4000 + 1]
                tnew = e + 2 + (x - 256 if x > 127 else x)
                if told in mp and mp[told] == tnew:
                    mp[a] = e
                    cambios += 1
            total += cambios
            if not cambios:
                break
        return total

    def tramos(self, mp, minlen):
        segs = []
        for a, n in self.ins:
            if a not in mp:
                continue
            sh = mp[a] - a
            if segs and segs[-1][2] == sh and segs[-1][1] == a:
                segs[-1][1] = a + n
            else:
                segs.append([a, a + n, sh])
        return [tuple(s) for s in segs if s[1] - s[0] >= minlen]

    def datos_exactos(self):
        out = []
        for k, a, b in self.blocks:
            if k == "d":
                blk = self.old[a - 0x4000:b - 0x4000]
                if len(blk) >= 8 and self.new.count(blk) == 1:
                    out.append((a, b, self.new.find(blk) + 0x4000 - a))
        return out

    def votos_ram(self, mp):
        V = collections.defaultdict(collections.Counter)
        for a, n in self.ins:
            if a not in mp:
                continue
            w = self.opoff(a, n)
            if not w or w[1] < 0xC000:
                continue
            off, v = w
            j = mp[a] - 0x4000 + off
            V[v][self.new[j] | self.new[j + 1] << 8] += 1
        return V

    def construye(self, pasadas=4):
        datseg = self.datos_exactos()
        for it in range(pasadas):
            mp = self.alinea()
            self.relativos(mp)
            self.SEG[:] = sorted(set(self.tramos(mp, 16)) | set(datseg))
            V = self.votos_ram(mp)
            self.RAM.clear()
            conf = []
            for v, c in V.items():
                self.RAM[v] = c.most_common(1)[0][0]
                if len(c) > 1:
                    conf.append(v)
            print("pasada %d: %d instrucciones emparejadas de %d, %d tramos, "
                  "RAM %d, conflictos %d" % (it, len(mp), len(self.ins),
                                             len(self.SEG), len(self.RAM), len(conf)))
        if conf:
            raise SystemExit("conflictos en el mapa de RAM: %s" % [hex(x) for x in conf])
        self.mp = mp
        # destinos de ROM votados por operandos emparejados
        VR = collections.defaultdict(collections.Counter)
        for a, n in self.ins:
            if a not in mp:
                continue
            w = self.opoff(a, n)
            if not w or w[1] >= 0xC000:
                continue
            off, v = w
            j = mp[a] - 0x4000 + off
            VR[v][self.new[j] | self.new[j + 1] << 8] += 1
        self.destinos = {}
        for v, c in VR.items():
            if len(c) > 1:
                raise SystemExit("conflicto de ROM en %#x" % v)
            self.destinos[v] = next(iter(c))
        # 0xC000 (el limite de pagina) lo apartamos de los operandos: los buffers
        # de 0xC000-0xC3FF no se mueven
        self.RAM.setdefault(0xC000, 0xC000)
        self.ram_claves = sorted(self.RAM)

    # ---- traduccion de una direccion cualquiera
    def t_rom(self, v):
        if v in self.mp:
            return self.mp[v]
        if v in self.destinos:
            return self.destinos[v]
        return self.rom_map(v)

    def t_ram(self, v):
        if v in self.RAM:
            return self.RAM[v]
        ks = self.ram_claves
        i = bisect.bisect_left(ks, v)
        if 0 < i < len(ks):
            lo, hi = ks[i - 1], ks[i]
            dl, dh = self.RAM[lo] - lo, self.RAM[hi] - hi
            if dl == dh:
                return v + dl
        return None

    def t(self, v):
        if v < 0x4000:
            return v
        if v >= 0xC000:
            return self.t_ram(v)
        return self.t_rom(v)


HEX = re.compile(r"0x[0-9A-Fa-f]{4}(?![0-9A-Fa-f])")


class Traductor:
    def __init__(self, m, salida):
        self.m = m
        self.salida = salida
        self.log = collections.defaultdict(list)
        self.dblocks = []          # (ini, fin, desplazamiento) de las D viejas
        self.tok_ok = collections.Counter()

    def prepara_datos(self, notes):
        m = self.m
        Dl = []
        for ln in notes:
            mm = re.match(r"^D (0x[0-9A-Fa-f]+) (0x[0-9A-Fa-f]+) (\S+)", ln)
            if mm:
                Dl.append((int(mm.group(1), 16), int(mm.group(2), 16), mm.group(3)))
        Dl.sort()
        prev = None
        for a, b, nm in Dl:
            blk = m.old[a - 0x4000:b - 0x4000]
            cand = []
            p = m.new.find(blk) if len(blk) >= 6 else -1
            if p >= 0 and m.new.count(blk) == 1:
                cand.append(p + 0x4000 - a)
            s = m.t_rom(a)
            if s is not None:
                cand.append(s - a)
            if prev is not None and prev[1] == a:
                cand.append(prev[2])
            best = None
            for sh in cand:
                j = a + sh - 0x4000
                if j < 0 or j + len(blk) > len(m.new):
                    continue
                eq = sum(1 for x, y in zip(blk, m.new[j:j + len(blk)]) if x == y)
                if best is None or eq > best[1]:
                    best = (sh, eq)
            if best is None:
                self.log["datos_sin_sitio"].append("%#06x %#06x %s" % (a, b, nm))
                continue
            sh, eq = best
            prev = (a, b, sh)
            self.dblocks.append((a, b, sh))
            if eq != len(blk):
                self.log["datos_distintos"].append(
                    "%#06x-%#06x %s -> %#06x: %d de %d bytes iguales" % (a, b, nm, a + sh, eq, len(blk)))

    def t_dato(self, v):
        for a, b, sh in self.dblocks:
            if a <= v < b:
                return v + sh
        return None

    def t_dir(self, v):
        """Direccion de una linea de notas (instruccion o dato)."""
        r = self.m.mp.get(v)
        if r is None:
            r = self.t_dato(v)
        if r is None:
            r = self.m.t_rom(v)
        return r

    def t_texto(self, txt, donde):
        def sub(mm):
            v = int(mm.group(0), 16)
            if v < 0x4000 or v in (0x7FFF, 0x8000, 0xBFFF, 0xC000, 0xFFFF):
                return mm.group(0)      # limites de pagina y tope de 16 bits
            r = self.t_dir(v) if v < 0xC000 else self.m.t_ram(v)
            if r is None:
                self.log["texto_sin_traducir"].append("%s: %s" % (donde, mm.group(0)))
                return mm.group(0)
            self.tok_ok[(v, r)] += 1
            return "0x%04X" % r
        return HEX.sub(sub, txt)

    def traduce_notas(self, ruta_old, ruta_new):
        lines = open(ruta_old, encoding="utf-8").read().split("\n")
        self.prepara_datos(lines)
        out = []
        for n, ln in enumerate(lines, 1):
            mm = re.match(r"^([LCBF]) (0x[0-9A-Fa-f]+)(.*)$", ln)
            md = re.match(r"^D (0x[0-9A-Fa-f]+) (0x[0-9A-Fa-f]+)(.*)$", ln)
            if md:
                a, b = int(md.group(1), 16), int(md.group(2), 16)
                sh = next((s for x, y, s in self.dblocks if x == a), None)
                if sh is None:
                    self.log["lineas_perdidas"].append("D %#06x" % a)
                    continue
                out.append("D 0x%04X 0x%04X%s" % (a + sh, b + sh, self.t_texto(md.group(3), "D %#06x" % a)))
            elif mm:
                k, a = mm.group(1), int(mm.group(2), 16)
                r = self.t_dir(a)
                if r is None:
                    self.log["lineas_perdidas"].append("%s %#06x%s" % (k, a, mm.group(3)[:90]))
                    continue
                out.append("%s 0x%04X%s" % (k, r, self.t_texto(mm.group(3), "%s %#06x" % (k, a))))
            else:
                out.append(self.t_texto(ln, "linea %d" % n) if ln.startswith("#") else ln)
        open(ruta_new, "w", encoding="utf-8").write("\n".join(out))

    def traduce_entradas(self, ruta_old, ruta_new):
        out = []
        for ln in open(ruta_old, encoding="utf-8").read().split("\n"):
            mm = re.match(r"^(0x[0-9A-Fa-f]+)(\s*)(#.*)?$", ln)
            if mm:
                a = int(mm.group(1), 16)
                r = self.m.t_rom(a)
                if r is None:
                    self.log["entradas_perdidas"].append("%#06x %s" % (a, mm.group(3) or ""))
                    continue
                out.append("0x%04X%s%s" % (r, mm.group(2), self.t_texto(mm.group(3) or "", "entrada %#06x" % a)))
            else:
                out.append(self.t_texto(ln, "entradas") if ln.startswith("#") else ln)
        open(ruta_new, "w", encoding="utf-8").write("\n".join(out))

    def informe(self):
        with open(os.path.join(self.salida, "work", "version_informe.txt"), "w", encoding="utf-8") as f:
            for k, v in self.log.items():
                f.write("== %s (%d)\n" % (k, len(v)))
                for x in v:
                    f.write("  %s\n" % x)
        for k, v in self.log.items():
            print("%-22s %d" % (k, len(v)))


def main():
    if len(sys.argv) != 4:
        raise SystemExit(__doc__)
    dv, rom, salida = sys.argv[1:4]
    m = Mapa(dv, rom)
    m.construye()
    os.makedirs(os.path.join(salida, "work"), exist_ok=True)
    json.dump({"mp": {str(k): v for k, v in m.mp.items()},
               "seg": m.SEG, "ram": {str(k): v for k, v in m.RAM.items()},
               "destinos": {str(k): v for k, v in m.destinos.items()}},
              open(os.path.join(salida, "work", "mapa_version.json"), "w"))
    print("mapa guardado")
    tdr = Traductor(m, salida)
    src = os.path.join(salida, "work", "trad")   # NO pisa src/: se copia a mano UNA vez
    os.makedirs(src, exist_ok=True)
    tdr.traduce_notas(os.path.join(dv, "src", "dunkshot.notes"), os.path.join(src, "dunkshot.notes"))
    tdr.traduce_entradas(os.path.join(dv, "src", "dunkshot.entries"), os.path.join(src, "dunkshot.entries"))
    tdr.informe()


if __name__ == "__main__":
    main()

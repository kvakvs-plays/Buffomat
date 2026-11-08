import os, sys, json
sys.path.insert(0, os.path.dirname(__file__))
from db import Build, i, SETCLASS
era = Build("era"); wf = Build("wowf")
ids = json.load(open(sys.argv[1]))
def status(b, sp):
    if sp not in b.name: return "MISSING"
    parts = []
    cl = b.classlines(sp)
    if cl: parts.append("class:" + "/".join(f"{c[0]}(acq{c[1]})" for c in cl))
    t = b.talentinfo(sp)
    if t: parts.append(t)
    if b.passive(sp): parts.append("PASSIVE")
    if not cl and not t: parts.append("noSkillLine")
    return " ".join(parts)
lines = []
for o in ids:
    if o["kind"] != "S": continue
    sp = o["id"]
    if sp not in era.name and sp not in wf.name: continue
    e, w = status(era, sp), status(wf, sp)
    diffs = []
    if e != w: diffs.append(f"STATUS era[{e}] -> wf[{w}]")
    if sp in wf.name:
        if era.name.get(sp) != wf.name.get(sp): diffs.append(f"NAME {era.name.get(sp)} -> {wf.name.get(sp)}")
        de, dw = era.duration(sp), wf.duration(sp)
        if de != dw: diffs.append(f"DUR {de} -> {dw}")
        le, lw = era.lvl(sp), wf.lvl(sp)
        if le != lw: diffs.append(f"LVL {le} -> {lw}")
        re_, rw = era.reag.get(sp), wf.reag.get(sp)
        if re_ != rw: diffs.append(f"REAG {[(r, era.iname(r)) for r,_ in (re_ or [])]} -> {[(r, wf.iname(r)) for r,_ in (rw or [])]}")
        pe, pw = era.power.get(sp), wf.power.get(sp)
        if pe != pw: diffs.append(f"COST {pe} -> {pw}")
        ae, aw = [a[:3] for a in era.auras(sp)], [a[:3] for a in wf.auras(sp)]
        if ae != aw: diffs.append(f"EFF {ae} -> {aw}")
        de_, dw_ = (era.spell.get(sp) or {}).get("Description_lang",""), (wf.spell.get(sp) or {}).get("Description_lang","")
        if de_ != dw_: diffs.append(f"DESC: {dw_[:220]!r}")
    if diffs:
        lines.append(f"## {sp} {era.name.get(sp) or wf.name.get(sp)}  [{o['where'][0]}]\n  " + "\n  ".join(diffs))
open(sys.argv[2], "w", encoding="utf-8").write("\n".join(lines))
print(len(lines), "spells changed")

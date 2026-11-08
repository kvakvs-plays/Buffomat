import os, sys
from collections import defaultdict, Counter
sys.path.insert(0, os.path.dirname(__file__))
from db import Build, rows, i, CLASSMASK, SETCLASS
era = Build("era"); wf = Build("wowf")
TREECLASS = {1112:"MAGE",1089:"DRUID",1091:"HUNTER",1100:"PALADIN",1114:"PRIEST",1111:"ROGUE",1082:"SHAMAN",1116:"WARLOCK",1117:"WARRIOR"}
# --- Forever talents from Trait tables
tdef = {i(r["ID"]): r for r in rows("TraitDefinition","wowf")}
tent = {i(r["ID"]): r for r in rows("TraitNodeEntry","wowf")}
tnode = {i(r["ID"]): r for r in rows("TraitNode","wowf")}
wtal = {}  # spell -> (class, tree, maxranks, overrides)
treeSpells = defaultdict(list)
for x in rows("TraitNodeXTraitNodeEntry","wowf"):
    n = tnode.get(i(x["TraitNodeID"])); e = tent.get(i(x["TraitNodeEntryID"]))
    if not n or not e: continue
    d = tdef.get(i(e["TraitDefinitionID"]))
    if not d or not i(d["SpellID"]): continue
    tree = i(n["TraitTreeID"]); sp = i(d["SpellID"])
    treeSpells[tree].append(sp)
    wtal[sp] = [tree, i(e["MaxRanks"]), i(d["OverridesSpellID"]), d["OverrideName_lang"]]
for tree, sps in treeSpells.items():
    if tree not in TREECLASS:
        c = Counter(SETCLASS.get(wf.classopt.get(s, 0), "?") for s in sps)
        print("tree", tree, len(sps), c.most_common(3), [wf.name.get(s) for s in sps[:6]])
def cls_of(b, sp):
    for r in b.sla.get(sp, []):
        sl = b.skillline.get(i(r["SkillLine"]))
        if sl and i(sl["CategoryID"]) == 7:
            for m, c in CLASSMASK.items():
                if i(r["ClassMask"]) & m: return c
    c = SETCLASS.get(b.classopt.get(sp, 0))
    return c or "?"
def baseline(b, sp):   # trainable/auto-learned class line ability, valid spell
    return sp in b.name and any(b.skillline.get(i(r["SkillLine"])) and i(b.skillline[i(r["SkillLine"])]["CategoryID"]) == 7 for r in b.sla.get(sp, []))
eraTal = {sp for sp, (r, k) in era.talent.items() if i(r["ClassID"])}
def kind(b, sp, tal):
    if sp not in b.name: return "absent"
    k = []
    if sp in tal: k.append("talent")
    if baseline(b, sp) and sp not in tal: k.append("baseline")
    if b.passive(sp): k.append("passive")
    return "+".join(k) or "other"
BUFFEFF = {6, 35, 65, 119, 128, 129, 143, 174}   # apply aura / area auras
def bufflike(b, sp):
    effs = b.eff.get(sp, [])
    if b.passive(sp): return False
    for e in effs:
        ef, tgt, au = i(e["Effect"]), i(e["ImplicitTarget_0"]), i(e["EffectAura"])
        if ef in (54, 360, 24, 28, 157): return True   # weapon enchant, create item, summon
        if ef in BUFFEFF and tgt in (0, 1, 20, 21, 25, 30, 31, 37, 56, 57, 61, 153):
            d = b.duration(sp)
            if d in (-1, 0) or (d and d >= 60000): return True
    return False
wtalset = set(wtal)
allsp = set()
for b in (era, wf):
    for sp in b.sla: allsp.add(sp)
allsp |= eraTal | wtalset
out = defaultdict(list)
for sp in allsp:
    ke, kw = kind(era, sp, eraTal), kind(wf, sp, wtalset)
    if ke == kw: continue
    c = cls_of(wf, sp) if sp in wf.name else cls_of(era, sp)
    if c == "?" and sp in wtal: c = TREECLASS.get(wtal[sp][0], "?")
    if c in ("?", "DEATHKNIGHT"): continue
    b = wf if sp in wf.name else era
    if not (bufflike(wf, sp) or bufflike(era, sp) or "passive" in kw): continue
    if ke == "absent" and kw == "other": continue
    nm = b.name.get(sp); d = b.duration(sp)
    desc = (b.spell.get(sp) or {}).get("Description_lang", "").replace("\r\n", " ")[:200]
    extra = f" overrides={wtal[sp][2]}({wf.name.get(wtal[sp][2])})" if sp in wtal and wtal[sp][2] else ""
    out[c].append(f"  {sp:>7} {nm!s:<32} {ke:>16} -> {kw:<16} dur={d} lvl={b.lvl(sp)[1]}{extra} | {desc}")
for c in sorted(out):
    print("\n#", c, len(out[c]))
    for l in sorted(out[c], key=lambda s: s.split()[1:3]): print(l)

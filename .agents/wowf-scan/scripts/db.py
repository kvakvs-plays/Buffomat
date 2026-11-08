import csv, os, sys
from collections import defaultdict
csv.field_size_limit(10**8)
D = os.environ.get("DB2DIR")
def rows(t, tag):
    p = os.path.join(D, f"{t}.{tag}.csv")
    if not os.path.exists(p): return []
    with open(p, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))
def i(x):
    try: return int(float(x))
    except: return 0
CLASSMASK = {1:"WARRIOR",2:"PALADIN",4:"HUNTER",8:"ROGUE",16:"PRIEST",32:"DEATHKNIGHT",64:"SHAMAN",128:"MAGE",256:"WARLOCK",1024:"DRUID"}
CLASSID = {1:"WARRIOR",2:"PALADIN",3:"HUNTER",4:"ROGUE",5:"PRIEST",6:"DEATHKNIGHT",7:"SHAMAN",8:"MAGE",9:"WARLOCK",11:"DRUID"}
SETCLASS = {3:"MAGE",4:"WARRIOR",5:"WARLOCK",6:"PRIEST",7:"DRUID",8:"ROGUE",9:"HUNTER",10:"PALADIN",11:"SHAMAN"}
class Build:
    def __init__(s, tag):
        s.tag = tag
        s.name = {i(r["ID"]): r["Name_lang"] for r in rows("SpellName", tag)}
        s.spell = {i(r["ID"]): r for r in rows("Spell", tag)}
        s.misc = {}
        for r in rows("SpellMisc", tag):
            if i(r["DifficultyID"]) == 0: s.misc[i(r["SpellID"])] = r
        s.dur = {i(r["ID"]): i(r["Duration"]) for r in rows("SpellDuration", tag)}
        s.levels = {}
        for r in rows("SpellLevels", tag):
            if i(r["DifficultyID"]) == 0: s.levels[i(r["SpellID"])] = r
        s.eff = defaultdict(list)
        for r in rows("SpellEffect", tag):
            if i(r["DifficultyID"]) == 0: s.eff[i(r["SpellID"])].append(r)
        s.skillline = {i(r["ID"]): r for r in rows("SkillLine", tag)}
        s.sla = defaultdict(list)
        for r in rows("SkillLineAbility", tag): s.sla[i(r["Spell"])].append(r)
        s.talent = {}   # spell -> (talentrow, rank)
        for r in rows("Talent", tag):
            for k in range(9):
                sp = i(r[f"SpellRank_{k}"])
                if sp: s.talent[sp] = (r, k+1)
            if i(r["SpellID"]): s.talent.setdefault(i(r["SpellID"]), (r, 1))
        s.tab = {i(r["ID"]): r["Name_lang"] for r in rows("TalentTab", tag)}
        s.classopt = {i(r["SpellID"]): i(r["SpellClassSet"]) for r in rows("SpellClassOptions", tag)}
        s.reag = {}
        for r in rows("SpellReagents", tag):
            s.reag[i(r["SpellID"])] = [(i(r[f"Reagent_{k}"]), i(r[f"ReagentCount_{k}"])) for k in range(8) if i(r[f"Reagent_{k}"]) > 0]
        s.power = {}
        for r in rows("SpellPower", tag):
            s.power.setdefault(i(r["SpellID"]), (i(r["ManaCost"]), i(r["PowerCostPct"]), i(r["PowerType"])))
        s.items = {i(r["ID"]): r for r in rows("Item", tag)}
        s.isparse = {i(r["ID"]): r for r in rows("ItemSparse", tag)}
        ie = {i(r["ID"]): r for r in rows("ItemEffect", tag)}
        s.itemspells = defaultdict(list)
        x = rows("ItemXItemEffect", tag)
        if x:
            for r in x:
                e = ie.get(i(r["ItemEffectID"]))
                if e: s.itemspells[i(r["ItemID"])].append((i(e["SpellID"]), i(e["TriggerType"])))
        else:
            for e in ie.values():
                s.itemspells[i(e["ParentItemID"])].append((i(e["SpellID"]), i(e["TriggerType"])))
    def iname(s, iid):
        r = s.isparse.get(iid); return r["Display_lang"] if r else None
    def passive(s, sp):
        m = s.misc.get(sp); return bool(m and i(m["Attributes_0"]) & 0x40)
    def duration(s, sp):
        m = s.misc.get(sp)
        if not m: return None
        return s.dur.get(i(m["DurationIndex"]), 0)
    def lvl(s, sp):
        l = s.levels.get(sp); return (i(l["BaseLevel"]), i(l["SpellLevel"])) if l else (0, 0)
    def classlines(s, sp):
        out = []
        for r in s.sla.get(sp, []):
            sl = s.skillline.get(i(r["SkillLine"]))
            if sl and i(sl["CategoryID"]) == 7:
                out.append((sl["DisplayName_lang"], i(r["AcquireMethod"]), i(r["ClassMask"]), i(r["SupercedesSpell"])))
        return out
    def auras(s, sp):
        return [(i(e["Effect"]), i(e["EffectAura"]), i(e["ImplicitTarget_0"]), i(e["EffectBasePointsF"]) if e.get("EffectBasePointsF") else 0) for e in s.eff.get(sp, [])]
    def talentinfo(s, sp):
        t = s.talent.get(sp)
        if not t: return None
        r, rank = t
        return f"talent {s.tab.get(i(r['TabID']),'?')} tier{r['TierID']} r{rank}"

import os, sys, json
from collections import defaultdict
sys.path.insert(0, os.path.dirname(__file__))
from db import Build, i
from auras import buff_auras
wf = Build("wowf"); era = Build("era")
ids = json.load(open(sys.argv[1])) if len(sys.argv) > 1 else []
used = {o["id"] for o in ids}
by = defaultdict(list)
for it, r in wf.items.items():
    if i(r["ClassID"]) != 0 or i(r["SubclassID"]) != 5 or it not in wf.isparse: continue
    for s, _ in wf.itemspells.get(it, []):
        for a, d in buff_auras(wf, s):
            by[a].append((it, wf.iname(it), i((wf.isparse.get(it) or {}).get("RequiredLevel") or 0)))
print("# Forever food/drink items grouped by the Well Fed (or other) aura they grant")
print("# build wowf 1.60.1.70862; '*' = item id already referenced by Buffomat; L = required level\n")
for a in sorted(by, key=lambda a: (wf.name.get(a) != "Well Fed", a)):
    desc = (wf.spell.get(a) or {}).get("AuraDescription_lang", "").split(".")[0][:70]
    print(f"## aura {a} {wf.name.get(a)} ({(wf.duration(a) or 0)//60000}m) - {desc}")
    for it, n, lv in sorted(set(by[a]), key=lambda x: (x[2], x[0])):
        print(f"  {'*' if it in used else ' '} {it:>7} L{lv:<2} {n}")

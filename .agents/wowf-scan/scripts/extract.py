import re, os, sys, json, glob, difflib
sys.path.insert(0, os.path.dirname(__file__))
from db import Build, i
root = sys.argv[1]
era = Build("era"); wf = Build("wowf")
files = sorted(glob.glob(os.path.join(root, "Src/Knowledge/*.lua"))) + [os.path.join(root, "Src/Const/SpellIds.lua"), os.path.join(root, "Src/Const/ItemIds.lua"), os.path.join(root, "Src/Knowledge/AllBuffs.lua")]
seen = {}
ITEMCTX = re.compile(r"Item|Reagent|LockIfHave|Consumable\(|consumableGroup|conjureItem|itemId|items", re.I)
for f in dict.fromkeys(files):
    rel = os.path.relpath(f, root).replace("\\", "/")
    inItemCall = False
    for ln, line in enumerate(open(f, encoding="utf-8"), 1):
        code, _, comment = line.partition("--")
        if ITEMCTX.search(code): inItemCall = True
        if re.search(r"SingleFamily|GroupFamily|createAndRegisterBuff|New\(|ProvidesAuras|IgnoreIfHaveBuff|HideIfSpellKnown|SacrificeAura", code): inItemCall = False
        for m in re.finditer(r"(?<![\w.])(\d{3,6})(?![\w.])", code):
            n = int(m.group(1))
            if n in (1000, 3600, 1800, 600, 300, 120, 900): continue
            sn, iname = era.name.get(n) or wf.name.get(n), era.iname(n) or wf.iname(n)
            if not sn and not iname: kind = "?"
            elif sn and not iname: kind = "S"
            elif iname and not sn: kind = "I"
            else:
                c = comment.lower()
                rs = difflib.SequenceMatcher(None, c, sn.lower()).ratio(); ri = difflib.SequenceMatcher(None, c, iname.lower()).ratio()
                kind = "I" if (inItemCall or ri > rs + 0.1) and not (rs > ri + 0.1) else "S"
                if rel.endswith("ItemIds.lua"): kind = "I"
                if rel.endswith("SpellIds.lua"): kind = "S"
            seen.setdefault((kind, n), []).append(f"{rel}:{ln}")
out = [{"kind": k, "id": n, "where": w} for (k, n), w in sorted(seen.items(), key=lambda x: (x[0][0], x[0][1]))]
json.dump(out, open(sys.argv[2], "w"), indent=0)
from collections import Counter
print(Counter(o["kind"] for o in out))

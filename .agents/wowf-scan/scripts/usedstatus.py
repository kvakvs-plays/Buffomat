import os, sys, json
sys.path.insert(0, os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__), "newspells.py")).read().split("wtalset = set(wtal)")[0].replace('print("tree"', 'pass  #'))
ids = json.load(open(sys.argv[1]))
used = {}
for o in ids:
    if o["kind"] == "S": used.setdefault(o["id"], o["where"][0])
def acq(b, sp, tal):
    if sp not in b.name: return "REMOVED"
    k = []
    if sp in tal: k.append("talent")
    if baseline(b, sp): k.append("trainable")
    if b.passive(sp): k.append("passive")
    return "+".join(k) or "none"
rowsout = []
for sp, where in sorted(used.items(), key=lambda x: x[1]):
    if not ("AllSpells" in where or "SpellIds" in where): continue
    if sp not in era.name: continue
    if not (baseline(era, sp) or sp in eraTal): continue
    a, b = acq(era, sp, eraTal), acq(wf, sp, set(wtal))
    if a != b:
        rowsout.append(f"{where:<42} {sp:>6} {era.name.get(sp):<32} {a:>18} -> {b}")
print("\n".join(rowsout))

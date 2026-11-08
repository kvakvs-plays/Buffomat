import os, sys
sys.path.insert(0, os.path.dirname(__file__))
exec(open(os.path.join(os.path.dirname(__file__), "newspells.py")).read().split("wtalset = set(wtal)")[0].replace('print("tree"', 'pass  #'))
res = {}
for sp in set(wf.sla) | set(wtal):
    if sp in era.name or sp not in wf.name or wf.passive(sp): continue
    src = []
    for r in wf.sla.get(sp, []):
        sl = wf.skillline.get(i(r["SkillLine"]))
        if sl and i(sl["CategoryID"]) in (7, 9): src.append(f'{sl["DisplayName_lang"]}/acq{r["AcquireMethod"]}')
    if sp in wtal: src.append(f"TALENT tree{wtal[sp][0]}")
    if not src: continue
    c = cls_of(wf, sp)
    if c == "?" and sp in wtal: c = TREECLASS.get(wtal[sp][0], "?")
    effs = sorted({(i(e["Effect"]), i(e["EffectAura"]), i(e["ImplicitTarget_0"])) for e in wf.eff.get(sp, [])})
    d = (wf.spell.get(sp) or {}).get("Description_lang", "").replace("\r\n", " ")[:170]
    res.setdefault(c, []).append(f"  {sp:>7} {wf.name[sp]:<30} lvl={wf.lvl(sp)[1]:<2} dur={wf.duration(sp)} {','.join(src)} eff={effs[:3]} | {d}")
for c in sorted(res):
    print("\n#", c, len(res[c]))
    for l in sorted(res[c], key=lambda s: (s.split()[1], s)): print(l)

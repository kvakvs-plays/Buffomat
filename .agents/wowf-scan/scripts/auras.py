import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from db import Build, i
def buff_auras(b, sp, depth=0, seen=None):
    """Long buff auras (>=60s) reachable from a spell via trigger chains."""
    seen = seen if seen is not None else set()
    if sp in seen or depth > 3: return []
    seen.add(sp); out = []
    d = b.duration(sp)
    effs = b.eff.get(sp, [])
    if d and d >= 60000 and any(i(e["Effect"]) in (6, 35, 65) and i(e["EffectAura"]) not in (23, 226) for e in effs):
        out.append((sp, d))
    for e in effs:
        t = i(e["EffectTriggerSpell"])
        if t: out += buff_auras(b, t, depth + 1, seen)
    return out

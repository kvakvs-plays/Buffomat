# WoW: Forever data scan

Offline tools that compare WoW: Forever game data with Classic Era game data, and check the
spell and item IDs that Buffomat references. They produced the findings in `../wowf-plan.md`.

## Data source and request policy

- **Wowhead is not used here.** `https://www.wowhead.com/robots.txt` disallows `ClaudeBot`,
  `anthropic-ai` and `Claude-Web` for the whole site. For trainer lists, talents and consumable details
  use `../foreverdb/foreverdb.py` (see its README).
- **wago.tools is used.** Its robots.txt allows `/api/` and `/db2/*/csv`, and
  `https://wago.tools/llms.txt` asks AI agents to use those routes instead of HTML pages.
  Do not open `/db2/{table}` HTML pages or diff pages.
- No rate limit is published, and responses are served from the Cloudflare cache.
  `fetch.py` sends one request at a time, waits 3 seconds between requests, and never
  downloads a table twice. A full scan is about 55 requests.

## Builds compared (2026-11-08)

| Tag    | wago.tools product | Version        |
|--------|--------------------|----------------|
| `wowf` | `wowf`             | 1.60.1.70862   |
| `era`  | `wow_classic_era`  | 1.15.9.70576   |

Forever ships new builds often (70630 to 70862 in about two weeks). Find the current ones with
`curl -s https://wago.tools/api/builds/latest`, then set `WOWF_VERSION` / `ERA_VERSION`.

## Running

Keep the downloaded CSVs outside the repository (they are about 60 MB).

```sh
DB2=/path/to/scratch/db2; SCAN=.agents/wowf-scan/scripts
python -I $SCAN/fetch.py $DB2 SkillLine,SkillLineAbility,SpellName,Spell,SpellLevels,SpellMisc,SpellDuration,SpellEffect,SpellClassOptions,Talent,TalentTab,ItemSparse,Item,ItemEffect,ItemXItemEffect,SpellCategories,SpellAuraOptions,SpellReagents,SpellPower,SpellShapeshift
TAGS=wowf python -I $SCAN/fetch.py $DB2 TraitTree,TraitNode,TraitNodeEntry,TraitDefinition,TraitNodeXTraitNodeEntry,SkillLineXTraitTree,ChrSpecialization
export DB2DIR=$DB2
python -I $SCAN/extract.py . ids.json            # spell/item ids referenced by Src/Knowledge and Src/Const
python -I $SCAN/spellreport.py ids.json spell_changes.txt
python -I $SCAN/usedstatus.py ids.json           # trainable/talent/passive/removed moves of used spells
python -I $SCAN/newspells.py                     # class ability moves, all classes
python -I $SCAN/newcast.py                       # castable spells that are new in Forever
python -I $SCAN/foodmap.py ids.json              # Forever food grouped by Well Fed aura
```

`ItemXItemEffect` does not exist on Era (Era links items through `ItemEffect.ParentItemID`), so
its 400 error is expected.

## Reports (`reports/`)

| File | Content |
|------|---------|
| `used-spell-acquisition.txt` | Spells Buffomat uses that became removed, passive, baseline or talent-only |
| `used-spell-changes.txt` | Duration, name, rank level, cost and target changes of spells Buffomat uses |
| `class-ability-moves.txt` | All class abilities whose acquisition changed, including passives |
| `new-class-castables.txt` | Castable class spells that do not exist in Era |
| `unreferenced-consumables.txt` | Forever consumables with buffs of 10 minutes or more that Buffomat does not list. `NEW` = item not in Era |
| `forever-food-by-aura.txt` | Every Forever food grouped by the Well Fed aura it gives; `*` = already in Buffomat |

## Known limits

- `extract.py` guesses whether a number is a spell or an item. IDs that are both are sometimes
  wrong, so expect some noise in the food and enchantment rows of `used-spell-changes.txt`.
- DB2 shows what exists in the client and which skill line or talent tree lists it. It does not
  show what trainers teach. Some `SkillLineAbility` rows point at deleted spells.
- The Era build contains Season of Discovery rune spells, so "absent in Era" does not always mean
  "new in Forever".
- Forever talents are in the Mainline trait tables. The legacy `Talent` table still ships on
  Forever but every row has `ClassID = 0`, so do not use it.
- Ignore these systematic differences: `SpellLevels.BaseLevel` became 0, and the modify-resistance
  aura type changed from 22 to 674.

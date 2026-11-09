# WoW: Forever buff and consumable update plan

Status: phases 1-4 implemented 2026-11-08 (see section 8); in-game verification still to do.
Data: Forever live build **1.60.1.70862** compared with Classic Era **1.15.9.70576**, scanned 2026-11-08.
Tools, raw reports and re-run steps: [`wowf-scan/`](wowf-scan/README.md).

Mark `(verify)` means the game data suggests it, but it must be confirmed in the Forever client.

---

## 0. How the data was gathered

- **Wowhead was not scanned.** Its `robots.txt` disallows `ClaudeBot`, `anthropic-ai` and
  `Claude-Web` for `/`, and it answers scripted clients with 403.
- **ForeverDB** (https://foreverdb.net) welcomes tools and AI assistants. Its public addon data files
  (trainer spell lists, talents, consumables) answered several open questions; its API needs a key.
  Client: [`foreverdb/foreverdb.py`](foreverdb/README.md). Credit "Data from ForeverDB.net" wherever
  its data is shown; its addon data is GPL-3.0, so do not copy it into `Src/`.
- **wago.tools DB2 exports were used instead.** wago.tools allows `/api/` and `/db2/*/csv` for
  AI agents (`/llms.txt`). It lists Forever as product `wowf`. No rate limit is published; the
  scan sent one request every 3 seconds, about 55 requests in total, each table downloaded once.
- The tables are the client's own game data: `SpellName`, `Spell`, `SpellMisc`, `SpellDuration`,
  `SpellEffect`, `SpellLevels`, `SpellReagents`, `SpellPower`, `SkillLine`, `SkillLineAbility`,
  `Item`, `ItemSparse`, `ItemEffect`, `ItemXItemEffect`, and on Forever the Mainline talent tables
  `TraitTree`, `TraitNode`, `TraitNodeEntry`, `TraitDefinition`.
- Forever talents are Mainline trait trees: 9 class trees (one per class skill line) plus three
  account-wide **Legacy** trees (1187, 1188, 1189). The old `Talent` table still ships but is dead
  (every row has `ClassID = 0`).
- Forever keeps `Rank N` spell subtext, even where names were unified (all "Create Healthstone"
  ranks have the same name but `Rank 1`..`Rank 5` subtext). Buffomat's `/cast Name(Rank N)`
  downrank macros should keep working `(verify)`.
- Temporary weapon enchant IDs (shaman imbues, poisons, oils, stones) are identical on both builds.
  Only permanent enchants changed, and Buffomat does not track those. The imbue spell effect type
  changed from 54 to 360, which does not matter to Buffomat.

---

## 1. Findings

### 1.1 Group buffs are raid-wide

| Spell | Classic Era target | Forever target |
|-------|--------------------|----------------|
| Prayer of Fortitude 21562, 21564 | caster's party (37) | caster's raid (56) |
| Prayer of Spirit 27681, Prayer of Shadow Protection 27683 | party | raid |
| Gift of the Wild 21849, 21850 | party | raid |
| Arcane Brilliance 23028 | party | raid |
| Battle Shout, all ranks | party (20) | raid (56) |
| Trueshot Aura, Aspect of the Wild | party area aura (35) | raid area aura (65) |
| Paladin Fire / Frost / Shadow Resistance Aura | party area aura | raid area aura |
| Devotion, Retribution, Concentration, Sanctity Aura | party | **unchanged: party** |
| Greater Blessings (Might, Wisdom, Kings) | raid members of the target's class (61) | 153; tooltip still says "all members of the raid or group that share the same class" |

All tooltips now read "all party and raid members". This is the WotLK behaviour, which Buffomat
selects with `envModule.haveWotLK`, and that flag is false on Forever. See 2.1.

### 1.2 Duration changes

| Buff | Era | Forever |
|------|-----|---------|
| Mark of the Wild, Power Word: Fortitude, Arcane Intellect, Divine Spirit (single target) | 30 min | **60 min** |
| Blessing of Might, Wisdom, Kings | 5 min | **60 min** |
| Greater Blessing of Might, Wisdom, Kings | 15 min | **60 min** |
| Battle Shout | 2 min | 3 min |
| Fear Ward | 10 min | 3 min |
| Vampiric Embrace | 1 min | 30 s, now level 30 |
| Demonic Sacrifice results 18789-18792 | 30 min | **120 min** |
| Prayer / Gift / Brilliance (group) | 60 min | 60 min, unchanged |

The account talent **Permanence** makes party and raid stat buffs last longer still (1.8), so
any hard-coded duration is a minimum on Forever.

### 1.3 Removed spells

These spell IDs have no `SpellName` row on Forever:

- Paladin: Blessing of Light 19977-19979, Blessing of Salvation 1038, Blessing of Sanctuary
  20911-20914, Greater Blessing of Light 25890, Greater Blessing of Salvation 25895,
  Greater Blessing of Sanctuary 25899.
- Priest: Elune's Grace ranks 2-5 (19289, 19291, 19292, 19293). Rank 1 (2651) remains as a
  **Night Elf priest** spell from the Classic quest "Elune's Grace" (5672) (ForeverDB class spell list).
- Paladin: Sanctity Aura 20218 exists in the client, but neither ForeverDB's trainer list nor the
  talent trees contain it, so it cannot be learned.
- Shaman: Fire Nova Totem and Tranquil Air Totem (Buffomat does not use them).
- Items: Seal of the Dawn 13209, Rune of the Dawn 19812 (reputation trinkets list) and
  Carrot on a Stick 11122 (riding speed list).

### 1.4 Talent abilities that became trainable

- Blessing of Kings 20217 (now every paladin has Kings; Greater Kings 25898 was already trainable).
- Divine Spirit 14752, 14818, 14819, 27841.
- Trueshot Aura, with two new lower ranks:
  1299346 (rank 1, level 25, also the Marksmanship talent node), 1299348 (rank 2, level 32),
  19506 (rank 3, level 40), 20905 (rank 4, level 50), 20906 (rank 5, level 60).
  The client lists them under the Marksmanship skill line, but ForeverDB's trainer list does not
  include them and its talent data does, so treat Trueshot Aura as **talent-granted** (higher ranks
  probably come with the talent) `(verify)`.
- Nature's Grasp 16689-16813, 17329.

### 1.5 Abilities that became passive

- **Omen of Clarity 16864** is now a passive talent. It is no longer a 10-minute self-buff.

### 1.6 New abilities that matter to Buffomat

| Class | Spell | IDs (rank: level) | Notes |
|-------|-------|-------------------|-------|
| Druid | **Revive** (out-of-combat resurrection) | 437138 (1: 12), 1237948 (2: 24), 1237949 (3: 36), 1237950 (4: 48), 1237951 (5: 60) | Druids now have a normal resurrection |
| Paladin | **Seal of Fury** (Protection, 30 s seal, shield absorb) | 1311649 (1: 10), 1311656 (2: 18), 20163 (3: 26), 20419 (4: 34), 20421 (5: 42), 20422 (6: 50), 20423 (7: 58) | New seal |
| Paladin | **Oath of Light** (Holy talent) | 1328548 | 5-minute buff on one ally; increases your Holy Light, Flash of Light and Holy Shock healing on it. Effectively replaces Blessing of Light |
| Hunter | Aspect of the Beast, new ranks | 13161 (1: 30), 1299445 (2: 40), 1299446 (3: 50), 1299447 (4: 60) | Now also adds melee attack power |
| Hunter | Trueshot Aura, new ranks | see 1.4 | |
| Paladin | Summon Warhorse, new ID | 1279399 | Only matters for mount detection |
| Shaman | Call of the Elements / Ancestors / Spirits, Totemic Recall | 66842-66844, 36936 | The totem bar exists. Totems are out of scope for now |
| Shaman | Mana Tide Totem rank 4 | 1325256 | Not a buff Buffomat tracks |
| All | Find Fish | 43308 | Exists on Forever, not on Era. Already in `SpellIds.lua` |
| All | Camp Benefits aura | 1229741 (60 min) | Granted by resting at a camp. Optional reminder |

Spells whose names changed but whose IDs stayed (only comments and labels need updating):
Detect Lesser/Greater Invisibility became "Detect Invisibility" (132, 11743); all warlock
"Create X (Rank name)" spells are now "Create X"; Demonic Sacrifice results Burning Wish 18789
became "Burning Shadow" and Touch of Shadow 18791 became "Touch of Fire".

### 1.7 Warlock stones are weapon imbues

On Forever both Firestone and Spellstone are used on the weapon, like the WotLK model:

| Item | Use spell | Weapon enchant ID |
|------|-----------|-------------------|
| Lesser Firestone 1254 / Firestone 13699 / Greater 13700 / Major 13701 | 758 / 17945 / 17947 / 17949 | 1803 / 1823 / 1824 / 1825 |
| Spellstone 5522 / Greater 13602 / Major 13603 | 1237152 / 1237156 / 1237159 | 8059 / 8060 / 8061 |

The Classic branch in `AllSpellsWarlock.lua` treats them as held items.

### 1.8 Account-wide Legacy talents

| Talent | Spell | Effect on Buffomat |
|--------|-------|--------------------|
| Reagent Economy | 1225503 | Class abilities no longer need vendor reagents. Hide the reagent counter ("x12") for Arcane Powder, Symbol of Kings, Wild Berries/Thornroot, Holy/Sacred Candle. Soul Shards are not vendor reagents |
| Permanence (2 ranks) | 1225502 | Party/raid stat buffs and camp benefits last longer. The percentage is not in the data `(verify)` |
| Gourmand (3 ranks) | 1225499 | Food buffs last longer |
| The Quick and the Dead | 1225500 | Helpful spells cost nothing for a few minutes after being resurrected. Optional: relax out-of-mana checks |

Reagents in Buffomat are display-only (`TaskScan:FormatReagentCount`), so Reagent Economy only
changes the text. No class buff reagent changed in the data itself.

### 1.9 Consumables

**Food.** Forever rebuilt cooked food:

- Food items now cast "Nutritious Food" (48 spells) or "Nutritious Drink" (13 spells). These
  trigger the classic Food/Drink channel (433, 434, 435, 1129 and 430-1137) plus one Well Fed aura.
- Each food now gives **one stat**, with a value that scales:

  | Aura | Stat | | Aura | Stat |
  |------|------|-|------|------|
  | 1248406 | Stamina | | 1249520 | Spell Damage |
  | 1248420 | Agility | | 1249927 | Healing Power |
  | 1248421 | Intellect | | 1249926 | Spirit |
  | 1248422 | Strength | | 1249523 | Critical Strike |
  | 1249519 | Attack Power | | 1319310 | Armor |
  | 1225779 | Agility + Stamina | | 1249521 / 1249907 | Fishing / Herbalism |

  Example: Spiced Wolf Meat gives Agility, Herb Baked Egg gives Stamina, Runn Tum Tuber Surprise
  gives Intellect, Nightfin Soup and Smoked Sagefish give Spell Damage, Grilled Squid gives Crit.
  The full item list is in `wowf-scan/reports/forever-food-by-aura.txt`.
- A few foods keep their old auras: Cactus Apple Surprise and holiday candy (19705), Goblin
  Deviled Clams (19708), Clamlette Surprise (19710), Dragonbreath Chili, Savory Deviate Delight,
  Blessed Sunfruit, Rumsey Rum.
- About 75 food items are new, for example teas (Healing Power) and smoothies (Spirit).
- Buffomat's classic food groups (for example "Stamina and Spirit food") no longer match on Forever.
- Drinking detection (`BuffomatAddon.AllDrink`) keeps working because Nutritious Drink triggers the
  classic Drink auras `(verify which aura UnitAura reports)`.

**Elixirs and potions.**

- Elixir of the Mongoose (17538) and Elixir of Wisdom (3166) dropped from 60 to 30 minutes.
- Greater Arcane/Fire/Frost/Nature/Shadow Protection Potions (items 13456-13461, auras 17543-17549)
  last 2 minutes, so they are no longer long buffs. Hide them on Forever.
- Elixir of Greater Firepower 21546 was renamed **Elixir of Holy Power**; its aura is now 1310077.
- Renamed, same IDs: Elixir of Minor Strength 2454, Elixir of Ogre Strength 3391, Elixir of Greater
  Strength 9206 (was "Elixir of Giants"), Elixir of Lesser Fortitude 3825, Elixir of Greater
  Defense 13445, Minor/Lesser/Major Troll's Blood **Elixir** 3382/3388/20004, Mageblood Elixir 20007.
- 38 new elixirs (item → aura, all 30 minutes unless noted):

  | Item | Name | Aura | | Item | Name | Aura |
  |------|------|------|-|------|------|------|
  | 247754 | Minor Arcane Elixir | 1245244 | | 250342 | Lesser Arcane Elixir | 1250971 |
  | 247755 | Elixir of Minor Force | 1245249 | | 250343 | Elixir of Nature Power | 1250972 |
  | 250328 | Elixir of Cunning (Agi+Int) | 1250918 | | 250344 | Elixir of Minor Spirit | 1250974 |
  | 250329 | Elixir of the Phalanx (HP+Armor) | 1250920 | | 250345 | Elixir of Lesser Spirit | 1250976 |
  | 250330 | Minor Cleric's Elixir | 1250922 | | 250346 | Elixir of Spirit | 1250978 |
  | 250331 | Lesser Cleric's Elixir | 1250924 | | 250347 | Elixir of Greater Spirit | 1250979 |
  | 250332 | Cleric's Elixir | 1250925 | | 250348 | Elixir of the Whale (Spi+Crit) | 1250981 |
  | 250333 | Greater Cleric's Elixir | 1250926 | | 250349 | Elixir of Strength | 1250984 |
  | 250334 | Elixir of Fortitude | 1250928 | | 250350 | Elixir of Ferocity (Str+Agi) | 1250985 |
  | 250335 | Elixir of Greater Fortitude | 1250931 | | 250351 | Elixir of the Grizzly (Str+Crit) | 1250986 |
  | 250336 | Elixir of Wicked Regeneration | 1250932 | | 250353 | Elixir of Lesser Intellect | 1250988 |
  | 250337 | Elixir of the Owl (Int+Crit) | 1250940 | | 250354 | Elixir of Intellect | 1250989 |
  | 250338 | Elixir of Sages (Spi+Crit) | 1250941 | | 246948 | Distilled Firewater (20 min) | 17038 |
  | 250339 | Minor Mageblood Elixir | 1250942 | | 250340 | Lesser Mageblood Elixir | 1250944 |
  | 250341 | Greater Mageblood Elixir | 1250948 | | | | |

  Not supported: "Endless" elixirs are beta-only fun items, not expected in the Forever release
  (decision 2026-11-08). For reference, 60 minutes, percent based: Intellect 289082 → 1327736, Power 289083 → 1327737,
  Healing 289084 → 1327738, Rapidity 289086 → 1327751, Opportunity 289087 → 1327753,
  Mana 289321 → 1328032, Experience 289334 → 1328127. Elixir of Endless Growth 289329 is cosmetic.

**Flasks.** Four new 2-hour flasks: Flask of Natural Accuracy 274273 → 1293740, Aggression
274274 → 1293741, Precision 274275 → 1293742, Swiftness 274276 → 1293743. ForeverDB lists all four
as +30 Stamina, level 55, made by Alchemy. Classic flasks are unchanged.

**Scrolls.**
- 19 "Scroll of Imbue X" weapon enchants (1 hour, Mage only, staff/dagger/sword only, required level 5-46): 274947, 275067,
  277485-277489, 277494-277498, 277500-277503. Enchant IDs still need a lookup in `SpellEffect`.
- Familiar scrolls (60 minutes, Intellect): Rat 275069 → 1296202, Frog 277483 → 1302285,
  Cat 277493 → 1302303.
- Not supported, beta-only like the Endless elixirs: Scroll of Endless Fortitude 289088 → 1327754.

**Weapon stones and bait.** Rough Sharpening Stone 287978 and Elemental Sharpening Stone 287980
are new item IDs for the same spells and enchants as the classic 2862 (enchant 40) and 18262
(enchant 2506), which still exist. Only the item lists need the new IDs. "Secret" Bait 268880 uses
the Shiny Bauble enchant 263.

**Unchanged.** 179 classic item IDs that Buffomat references have the same use spells, names and
buff durations on Forever.

---

## 2. Internal API changes

### 2.1 Capability flags in `KvEnv.lua`

Core code uses expansion flags as stand-ins for behaviour. Forever has WotLK-style group buffs and
dual spec but must stay `haveTBC == false` (no flying, no TBC pet food, no TBC shaman imbue rules).
Add named capability flags and switch the callers:

| New flag | Value | Replace in |
|----------|-------|------------|
| `envModule.groupBuffsRaidWide` | `haveWotLK or isForever` | `GroupBuffTarget:GetDistanceParty`, `TaskScan:AddBuff_GroupBuff`, `TaskScan:AddBuff` |
| `envModule.hasDualSpec` | `haveWotLK or (isForever and an active-spec API exists)` | `CharacterSettings` (spec2 profiles), `ProfileSettings:Setup`, `bomGetActiveTalentGroup`, `Events` (`ACTIVE_TALENT_GROUP_CHANGED`; check it with `C_EventUtils.IsEventValid` first) |

Leave `haveTBC` checks alone: `TaskScan:IsFlying`, the dismount check in `Events.lua`,
`BuffChecks:HunterPetNeedsBuff` and `TaskScan:AddWeaponEnchant` are correct for Forever as they are.

### 2.2 Buff definition limitations (`BuffDefinition.lua`)

- Add `requireForever` and `hideInForever` to `BomSpellLimitations`, builders
  `buffDefClass:RequireForever()` and `buffDefClass:HideInForever()`, and both checks in
  `buffDefModule:CheckStaticLimitations`.
- Add `buffDefModule:foreverConsumable(dst, singleId, itemId)`, like `tbcConsumable`.
- `PerExpansionChoice`: add `forever` (appended when `isForever`) and `onlyForever` keys to
  `BomNumbersPerExpansion`. Check `onlyForever` **before** `onlyClassic`, because `isClassic` is
  also true on Forever.
- Add `allBuffsModule.ForeverOr(foreverValue, otherValue)` for scalar differences such as durations.
- Rule for definitions:
  - Only a scalar differs (duration): use `ForeverOr` inline, no second definition.
  - Rank IDs are added: use the `forever` key of `PerExpansionChoice`.
  - The spell is gone or behaves differently: `:HideInForever()` on the Classic definition, and a
    Forever definition with `:RequireForever()` if a replacement exists.

### 2.3 Dynamic checks

- **Learned talents.** Forever talents grant spells through trait nodes. Confirm that
  `envModule.IsSpellKnown` / `IsPlayerSpell` returns true for them (Oath of Light 1328548, Trueshot
  Aura rank 1 1299346) and that `SpellSetup:Setup_EachSpell_CacheUpdate` picks the highest learned
  rank `(verify)`. Rescan on `TRAIT_CONFIG_UPDATED` / `PLAYER_TALENT_UPDATE` if `SPELLS_CHANGED` does
  not fire on talent changes; check each event with `C_EventUtils.IsEventValid`.
- **Reagent Economy.** In `TaskScan:FormatReagentCount`, return `""` on Forever when
  `IsPlayerSpell(1225503)` is true.
- **Durations.** `singleDuration` is used for weapon-enchant timing (`Unit.lua`). Aura timers already
  come from `UnitAura` data. Keep it that way so Permanence and Gourmand need no special code.

### 2.4 Categories

Reuse the existing Classic categories on Forever instead of adding `forever*` ones. This needs no new
translation keys and no change to `SetupConstantsCategories`:

- `classicPhysFood`: Agility, Strength, Attack Power, Crit, Agility+Stamina.
- `classicSpellFood`: Intellect, Spell Damage, Healing Power, Spirit.
- `classicFood`: Stamina, Armor, specials.
- New elixirs go to `classicPhysElixir`, `classicSpellElixir` or `classicElixir`; new flasks to
  `classicFlask`; Familiar and Endless scrolls to `scroll`; Imbue scrolls and new stones to
  `weaponEnchantment`.

### 2.5 Module layout

- New `Src/Knowledge/AllConsumesForever.lua` (`Buffomat-AllConsumesForever`) with
  `SetupForeverFood`, `SetupForeverElixirs`, `SetupForeverFlasks`, `SetupForeverScrolls`,
  `SetupForeverWeaponEnchants`. Call it from `AllBuffsModule:SetupSpells` only when
  `envModule.isForever`.
- Register it in `Src/EarlyBoot.lua` and add it to `toc_template.toc` after the other
  `AllConsumes*` files.
- Class changes stay inline in `AllSpells<Class>.lua`; each class file is small.

### 2.6 Lists in `AllBuffs.lua`

- `SetupCancelBuffs`: drop Blessing of Salvation on Forever. It currently adds it explicitly when
  `envModule.isForever`.
- `reputationTrinketZones` and `ridingSpeedZones`: skip the removed items on Forever, or ignore
  items that `C_Item` cannot resolve.
- `AllDrink`: optionally add the Nutritious Drink IDs 1249906, 1249914-1249925 after the in-game
  check in 1.9.

### 2.7 Documentation

- `AGENTS.md`, "WoW Group And Buff Semantics": add that on Forever (and WotLK) group buffs cover the
  whole raid, Greater Blessings still go to every raid member of the target's class, and blessings
  last 60 minutes.
- `.agents/code-index.md`: add the new module, the capability flags and the Forever limitations.

---

## 3. Class work list

**Druid** (`AllSpellsDruid.lua`)
- Mark of the Wild: single duration 60 minutes on Forever. Gift of the Wild is covered by 2.1.
- Omen of Clarity: `:HideInForever()`.
- Revive: add a Forever definition next to the WotLK one: `SingleFamily({ 437138, 1237948,
  1237949, 1237950, 1237951 })`, `BuffType("resurrection")`, `RequiresCancelForm(true)`,
  `RequireForever()`. `RESURRECT_CLASSES` already lists DRUID.
- Nature's Grasp, Thorns: no change.

**Hunter** (`AllSpellsHunter.lua`)
- Trueshot Aura: add 1299346 and 1299348 through the `forever` key.
- Aspect of the Beast: add 1299445, 1299446, 1299447.
- Aspect of the Wild: no ID change; raid-wide.

**Mage** (`AllSpellsMage.lua`)
- Arcane Intellect: single duration 60 minutes on Forever. Arcane Brilliance is covered by 2.1.
- Arcane Powder: Reagent Economy (2.3).
- Armors, Dampen/Amplify Magic, Mana Shield, Ice Barrier, mana gems: no change `(verify the gem item IDs in game)`.

**Paladin** (`AllSpellsPaladin.lua`)
- `:HideInForever()`: Blessing of Light, Salvation, Sanctuary, their Greater versions, Sanctity Aura.
- `blessingDuration` and `greaterBlessingDuration`: 60 minutes on Forever.
- Blessing of Kings is baseline: decide whether it becomes `IsDefault(true)` on Forever (open question).
- Add Seal of Fury with the IDs in 1.6 and `:RequireForever()`, next to the other seals.
- Add Oath of Light 1328548 as an optional single-target class buff, default target the tank,
  `:RequireForever()`.
- Symbol of Kings: Reagent Economy (2.3).
- Resistance auras are raid-wide now; aura handling is a self toggle, so no change.

**Priest** (`AllSpellsPriest.lua`)
- Power Word: Fortitude and Divine Spirit: single duration 60 minutes on Forever.
- Elune's Grace: on Forever only rank 1 (2651), Night Elf only: `:RequirePlayerRace("NightElf")`
  in a Forever definition, and `:HideInForever()` on the Classic one.
- Fear Ward: 3 minutes on Forever.
- Vampiric Embrace: the existing definition is WotLK-only; keep it hidden on Forever (30 s debuff).
- Candles: Reagent Economy (2.3).

**Shaman**: no change. Imbue enchant IDs are unchanged. Totems stay out of scope.

**Warlock** (`AllSpellsWarlock.lua`)
- Firestone and Spellstone: on Forever use the WotLK model (conjure spell plus weapon enchant
  consumable) with the items, spells and enchant IDs in 1.7.
- Demonic Sacrifice results: 120 minutes; update the comments for the renamed auras.
- Detect Invisibility and stone names: comments only.

**Warrior**: Battle Shout lasts 3 minutes and is raid-wide; the definition sets no duration, so no change.

**Rogue**: poisons moved to a non-class skill line category (7 → 9), but Buffomat uses the poison
items, which are unchanged. No change.

---

## 4. Consumables work list

1. Classic food groups whose auras changed: `:HideInForever()` (`AllConsumesFood.lua` classic
   physical, caster and misc groups).
2. `SetupForeverFood`: one `consumableGroup` per Forever Well Fed aura (table in 1.9), with item lists
   from `forever-food-by-aura.txt`. Include the foods that kept classic auras.
3. Elixirs: `:HideInForever()` the Greater Protection Potions; switch Elixir of Greater Firepower to
   aura 1310077 on Forever; add the 38 new elixirs and the Endless series in `SetupForeverElixirs`.
4. Flasks: add the four Natural flasks after the in-game effect check.
5. Scrolls: add Familiar scrolls and Endless Fortitude; add Imbue scrolls as weapon enchantments once
   their enchant IDs are looked up (`SpellEffect.EffectMiscValue_0` of each scroll's use spell).
6. Weapon stones: add item IDs 287978 / 287980 to the existing Rough and Elemental Sharpening Stone
   definitions (same spells and enchants).
7. Update comments and names for the renamed elixirs.

---

## 5. Tests and validation

- **Lua tests.** Add `Tests/ForeverKnowledgeTest.lua` using the fixture style of
  `ForeverCompatibilityTest.lua`: `RequireForever` / `HideInForever` limits, `PerExpansionChoice`
  `forever` / `onlyForever`, `groupBuffsRaidWide` and `hasDualSpec` on Forever, Classic Era and WotLK
  fixtures. Run with `lua Tests/<name>.lua`.
- **luacheck.** `luacheck Src Tests` must stay at 0 warnings. Add new WoW globals (`C_Traits`,
  `C_EventUtils`) to `read_globals` if used.
- **Offline ID check.** After the changes, re-run `extract.py` and `usedstatus.py` against the newest
  `wowf` build. Every ID that a Forever-visible definition uses must exist on Forever.
- **In-game checklist (Forever client).**
  - `/dump IsPlayerSpell(1225503)` and `IsPlayerSpell(1328548)` return the expected values.
  - One cast of Prayer of Fortitude, Gift of the Wild or Arcane Brilliance in a raid buffs the whole
    raid, and Buffomat stops asking for other groups.
  - Druid Revive appears for dead party members out of combat.
  - Downrank macros work for unified names (`Create Healthstone(Rank 3)`).
  - Food tasks show per-stat groups; eating clears the matching task.
  - `GetWeaponEnchantInfo` reports enchant IDs 1803-1825 for Firestone and 8059-8061 for Spellstone.
  - Talent change and dual-spec swap refresh the buff list and switch profiles.
  - Spell subtext shows `Rank N`.

---

## 6. Order of work

1. **API**: capability flags (2.1), Forever limitations and `PerExpansionChoice` keys (2.2), tests.
2. **Class spells**: section 3, one commit per class.
3. **Consumables**: section 4.
4. **Legacy talents**: Reagent Economy and talent rescan (2.3).
5. **Docs and verification**: 2.7, the in-game checklist, then re-run the scan on the latest build.

---

## 7. Open questions

1. Should Blessing of Kings be on by default for paladins on Forever, now that every paladin has it?
2. Is totem support wanted, now that the totem bar exists? It is out of scope in this plan.
3. Should Buffomat remind players about Camp Benefits (1229741)?
4. What does Permanence add per rank? Gourmand? (Ask the ForeverDB API: `spells/1225502`, `spells/1225499`.)
5. Do higher Trueshot Aura ranks come with the talent, or from a trainer?

Answered from ForeverDB data (build 1.60.1.70862): Elune's Grace rank 1 stays for Night Elf priests;
Sanctity Aura cannot be learned; the Natural flasks give only Stamina.

---

## 8. Implementation status (2026-11-08)

Done, covered by `Tests/ForeverKnowledgeTest.lua`; luacheck 0 warnings; every added ID exists in the
Forever 1.60.1.70862 client data.

| Area | What changed |
|------|--------------|
| `KvEnv.lua` | `groupBuffsRaidWide`, `hasDualSpec`, `IsEventValid`, `IsPlayerSpell` |
| `BuffDefinition.lua` | `RequireForever`/`HideInForever`, `foreverConsumable`, `PerExpansionChoice` `forever`/`onlyForever` |
| `AllBuffs.lua` | `ForeverOr`, `THREE_MINUTES`, `TWO_HOURS`; Salvation not cancelled on Forever; calls `AllConsumesForever` on Forever |
| Core | `TaskScan`/`GroupBuffTarget` use `groupBuffsRaidWide`; `CharacterSettings`/`ProfileSettings`/`Events` use `hasDualSpec`; `TRAIT_CONFIG_UPDATED` rebuilds the spell list on Forever |
| Reagents | `TaskScan:IsReagentWaived` hides the counter with Reagent Economy (`ItemIds.VendorReagents`) |
| Classes | Section 3, all items except the open questions below |
| Consumables | Section 4; new `Src/Knowledge/AllConsumesForever.lua`; `SpellIds.ForeverFood` (Nutritious Food/Drink) |

Still open:

- The in-game checklist in section 5.
- ForeverDB API (key requested): Permanence and Gourmand values; whether higher Trueshot Aura ranks
  come with the talent (`.agents/foreverdb/verify-forever.txt`).
- Open questions 1-3 in section 7 (Kings default, totems, Camp Benefits reminder).
- Not done on purpose: removed reputation/riding trinkets stay in their lists (absent items are never
  in bags, so they are harmless); `AllDrink` keeps the classic Drink auras, which Nutritious Drink
  still applies.
- Imbue scrolls: each fits one weapon type (staff, dagger or one-handed sword, from `SpellEquippedItems`);
  `RequireWeaponType` makes the scan ask for them only on a fitting weapon. Off by default, caster classes only.
  The same limit could be applied to sharpening stones and weightstones later.

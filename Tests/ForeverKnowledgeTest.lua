-- Run from the repository root: lua Tests/ForeverKnowledgeTest.lua
-- Loads the real buff database (Src/Knowledge) for each class on WoW: Forever, Classic Era and
-- WotLK, runs AllBuffsModule:SetupSpells and checks what each client gets.
local function loadModule(path, globals)
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, globals)
  else
    chunk = assert(loadfile(path, "t", globals))
  end
  chunk("BuffomatClassic", {})
end

local function equal(actual, expected, label)
  assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- The Knowledge files in toc_template.toc order, plus what they need at setup time
local FILES = {
  "Src/KvLib/KvEnv.lua",
  "Src/Knowledge/AllBuffs.lua",
  "Src/Knowledge/AllSpellsMage.lua", "Src/Knowledge/AllSpellsPriest.lua", "Src/Knowledge/AllSpellsDruid.lua",
  "Src/Knowledge/AllSpellsShaman.lua", "Src/Knowledge/AllSpellsWarlock.lua", "Src/Knowledge/AllSpellsHunter.lua",
  "Src/Knowledge/AllSpellsPaladin.lua", "Src/Knowledge/AllSpellsWarrior.lua", "Src/Knowledge/AllSpellsRogue.lua",
  "Src/Knowledge/AllSpellsDeathknight.lua", "Src/Knowledge/AllConsumesScrolls.lua",
  "Src/Knowledge/AllConsumesEnchantments.lua", "Src/Knowledge/AllConsumesElixirs.lua",
  "Src/Knowledge/AllConsumesFlasks.lua", "Src/Knowledge/AllConsumesFood.lua", "Src/Knowledge/AllConsumesOther.lua",
  "Src/Knowledge/AllConsumesForever.lua",
  "Src/Const/SpellIds.lua", "Src/Const/ItemIds.lua", "Src/Core/BuffDefinition.lua",
}

local CLIENTS = {
  forever = { project = 18, interface = 16001, expansion = 0 },
  era = { project = 2, interface = 11508, expansion = 0 },
  wotlk = { project = 11, interface = 30403, expansion = 2 },
}

---Build the buff database for one client and class.
---@return table env
---@return table allBuffs buffId -> definition
---@return table enchantments spellId -> enchant ids
---@return table allBuffsModule
local function setup(clientName, class, race)
  local client = CLIENTS[clientName]
  local libs = { ["Buffomat-Buffomat"] = { Color = function(_, _color, text) return text end } }
  local globals = setmetatable({
    WOW_PROJECT_ID = client.project, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
    WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5, WOW_PROJECT_WRATH_CLASSIC = 11, WOW_PROJECT_CATACLYSM_CLASSIC = 14,
    LE_EXPANSION_LEVEL_CURRENT = client.expansion,
    GetBuildInfo = function() return "", "", "", client.interface end,
    UnitClass = function() return class, class end,
    UnitRace = function() return race, race, 1 end,
    UnitLevel = function() return 60 end,
    UnitFactionGroup = function() return "Alliance" end,
    IsSpellKnown = function() return false end,
    InCombatLockdown = function() return false end,
    NUM_BAG_SLOTS = 4,
    tinsert = table.insert,
    wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
    tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end,
    BuffomatAddon = { GetItemInfo = function() end },
    LibStub = function(name)
      if libs[name] == nil then
        libs[name] = name == "Buffomat-Languages" and setmetatable({}, { __call = function(_, key) return key end })
            or {}
      end
      return libs[name]
    end,
  }, {
    -- Blizzard string constants (ITEM_MOD_AGILITY_SHORT, ...) resolve to their own names
    __index = function(_, key)
      local value = _G[key]
      if value == nil and type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
        return key
      end
      return value
    end,
  })
  globals._G = globals
  if client.interface >= 16000 then
    globals.C_SpecializationInfo = { GetActiveSpecGroup = function() return 1 end }
  else
    globals.GetActiveTalentGroup = function() return 1 end
  end
  for _, path in ipairs(FILES) do
    loadModule(path, globals)
  end
  local allBuffsModule = libs["Buffomat-AllBuffs"]
  allBuffsModule:SetupSpells()
  return libs["KvLibShared-Env"], allBuffsModule.allBuffs, globals.BuffomatAddon.enchantList, allBuffsModule
end

local function contains(list, value)
  for _, x in ipairs(list or {}) do
    if x == value then return true end
  end
  return false
end

-- Capability flags
do
  local forever = setup("forever", "MAGE", "Human")
  local era = setup("era", "MAGE", "Human")
  local wotlk = setup("wotlk", "MAGE", "Human")
  equal(forever.isForever, true, "Forever detected")
  equal(forever.groupBuffsRaidWide, true, "Forever group buffs are raid-wide")
  equal(forever.hasDualSpec, true, "Forever has dual spec")
  equal(forever.haveTBC, false, "Forever keeps Classic rules")
  equal(era.groupBuffsRaidWide, false, "Era group buffs are party-wide")
  equal(era.hasDualSpec, false, "Era dual spec stays as it was")
  equal(wotlk.groupBuffsRaidWide, true, "WotLK group buffs are raid-wide")
  equal(wotlk.hasDualSpec, true, "WotLK has dual spec")
end

-- PerExpansionChoice and ForeverOr
do
  local _, _, _, foreverModule = setup("forever", "MAGE", "Human")
  local _, _, _, eraModule = setup("era", "MAGE", "Human")
  equal(foreverModule.ForeverOr(1, 2), 1, "ForeverOr on Forever")
  equal(eraModule.ForeverOr(1, 2), 2, "ForeverOr elsewhere")
end

-- Paladin
do
  local _, buffs = setup("forever", "PALADIN", "Human")
  local _, eraBuffs = setup("era", "PALADIN", "Human")
  for _, removed in ipairs({ 19979, 1038, 20914, 25890, 25895, 25899, 20218 }) do
    equal(buffs[removed], nil, "Forever has no paladin buff " .. removed)
    assert(eraBuffs[removed], "Era keeps paladin buff " .. removed)
  end
  equal(buffs[25291].singleDuration, 3600, "Forever Blessing of Might lasts an hour")
  equal(buffs[25916].singleDuration, 3600, "Forever Greater Blessing of Might lasts an hour")
  equal(eraBuffs[25291].singleDuration, 300, "Era Blessing of Might lasts 5 minutes")
  assert(buffs[1328548], "Forever has Oath of Light")
  equal(eraBuffs[1328548], nil, "Era has no Oath of Light")
  local fury = buffs[20423]
  assert(fury and fury.type == "seal", "Forever has Seal of Fury")
  equal(fury.singleFamily[1], 1311649, "Seal of Fury rank 1 first")
  equal(fury.singleFamily[#fury.singleFamily], 20423, "Seal of Fury rank 7 last")
  equal(eraBuffs[20423], nil, "Era has no Seal of Fury")
end

-- Priest
do
  local _, buffs = setup("forever", "PRIEST", "Human")
  local _, nightElf = setup("forever", "PRIEST", "NightElf")
  local _, eraBuffs = setup("era", "PRIEST", "Human")
  equal(buffs[10938].singleDuration, 3600, "Forever Power Word: Fortitude lasts an hour")
  equal(eraBuffs[10938].singleDuration, 1800, "Era Power Word: Fortitude lasts 30 minutes")
  equal(buffs[6346].singleDuration, 180, "Forever Fear Ward lasts 3 minutes")
  equal(buffs[19293], nil, "Forever Elune's Grace needs a Night Elf")
  assert(nightElf[19293], "Forever Night Elf priest has Elune's Grace")
  equal(#nightElf[19293].singleFamily, 1, "Forever Elune's Grace has only rank 1")
  equal(#eraBuffs[19293].singleFamily, 5, "Era Elune's Grace has 5 ranks")
end

-- Druid
do
  local _, buffs = setup("forever", "DRUID", "NightElf")
  local _, eraBuffs = setup("era", "DRUID", "NightElf")
  local _, wotlkBuffs = setup("wotlk", "DRUID", "NightElf")
  equal(buffs[16864], nil, "Forever Omen of Clarity is passive")
  assert(eraBuffs[16864], "Era keeps Omen of Clarity")
  local revive = buffs[1237951]
  assert(revive and revive.type == "resurrection", "Forever druid has Revive")
  equal(revive.singleFamily[1], 437138, "Revive rank 1 first")
  equal(eraBuffs[1237951], nil, "Era druid has no Revive")
  assert(wotlkBuffs[50763], "WotLK keeps its own Revive")
  equal(buffs[9885].singleDuration, 3600, "Forever Mark of the Wild lasts an hour")
end

-- Hunter
do
  local _, buffs = setup("forever", "HUNTER", "Dwarf")
  local trueshot = buffs[20906].singleFamily
  equal(trueshot[1], 1299346, "Trueshot Aura rank 1 first")
  equal(trueshot[2], 1299348, "Trueshot Aura rank 2 second")
  equal(trueshot[3], 19506, "Trueshot Aura rank 3 third")
  assert(contains(buffs[13161].singleFamily, 1299447), "Aspect of the Beast rank 4")
end

-- Warlock: stones are weapon enchantments on Forever
do
  local _, buffs, enchants = setup("forever", "WARLOCK", "Human")
  local _, eraBuffs, eraEnchants = setup("era", "WARLOCK", "Human")
  local fire, spell = buffs[17949], buffs[1237159]
  assert(fire and fire.type == "weapon" and fire.isConsumable, "Forever Firestone weapon buff")
  assert(spell and spell.type == "weapon" and spell.isConsumable, "Forever Spellstone weapon buff")
  equal(fire.singleDuration, 7200, "Firestone imbue lasts 2 hours")
  assert(contains(fire.items, 13701), "Major Firestone provides the buff")
  assert(contains(spell.items, 13603), "Major Spellstone provides the buff")
  assert(contains(enchants[17949], 1825), "Firestone 4 enchant mapped")
  assert(contains(enchants[1237159], 8061), "Spellstone 3 enchant mapped")
  equal(eraBuffs[17949], nil, "Era has no Firestone weapon buff")
  equal(eraEnchants[17949], nil, "Era has no Firestone enchant mapping")
end

-- Consumables
do
  local _, mage, enchants = setup("forever", "MAGE", "Gnome")
  local _, eraMage = setup("era", "MAGE", "Gnome")
  local _, warrior = setup("forever", "WARRIOR", "Human")
  local _, paladin = setup("forever", "PALADIN", "Human")

  -- Food: one stat per Well Fed aura on Forever
  assert(mage[1248421], "Forever Intellect food for a mage")
  assert(contains(mage[1248421].items, 18254), "Runn Tum Tuber Surprise is Intellect food")
  assert(contains(mage[1248421].ignoreIfBetterBuffs, 1248378), "food waits while eating Nutritious Food")
  assert(contains(mage[1248421].ignoreIfBetterBuffs, 433), "food waits while eating classic Food")
  assert(warrior[1248420] and contains(warrior[1248420].items, 2680), "Spiced Wolf Meat is Agility food")
  equal(mage[1248420], nil, "no Agility food for a mage")
  equal(eraMage[1248421], nil, "Era has no Forever food groups")
  assert(contains(mage[19705].items, 11584), "Forever Stamina/Spirit group keeps Cactus Apple Surprise")
  assert(not contains(mage[19705].items, 6888), "Herb Baked Egg moved to Stamina food on Forever")
  assert(contains(eraMage[19705].items, 6888), "Era Stamina/Spirit group keeps Herb Baked Egg")
  equal(mage[25694], nil, "Forever has no classic mana regeneration food")
  assert(eraMage[25694], "Era keeps mana regeneration food")

  -- Elixirs
  equal(paladin[26276], nil, "Forever has no Elixir of Greater Firepower")
  assert(paladin[1310077] and contains(paladin[1310077].items, 21546), "Forever Elixir of Holy Power")
  assert(eraMage[26276], "Era keeps Elixir of Greater Firepower")
  equal(mage[17543], nil, "Forever protection potions are not long buffs")
  assert(eraMage[17543], "Era keeps Greater Fire Protection Potion")
  assert(mage[1250940], "Forever Elixir of the Owl")
  equal(mage[1250922], nil, "Cleric's Elixirs are for healers")
  assert(paladin[1250922] and #paladin[1250922].items == 4, "paladin gets the 4 Cleric's Elixirs")
  equal(eraMage[1250940], nil, "Era has no Elixir of the Owl")

  -- Flasks, scrolls, weapon enchantments
  assert(mage[1293740] and #mage[1293740].items == 4, "Forever Natural flasks")
  assert(mage[1296202] and contains(mage[1296202].items, 277493), "Forever Familiar scrolls")
  local flame = mage[1302304]
  assert(flame and flame.type == "weapon" and not flame.default, "Imbue Flame scroll is an optional weapon buff")
  equal(enchants[1302304][1], 8713, "Imbue Flame enchant mapped")
  equal(#flame.weaponSubclasses, 1, "Imbue Flame fits one weapon type")
  equal(flame.weaponSubclasses[1], 10, "Imbue Flame needs a staff")
  equal(flame.extraText, "Staves", "spells dialog names the weapon type")
  equal(mage[1302227].weaponSubclasses[1], 7, "Imbue Spark needs a one-handed sword")
  equal(mage[1296225].weaponSubclasses[1], 15, "Imbue Chillknife needs a dagger")
  equal(warrior[16138].weaponSubclasses, nil, "classic sharpening stones keep no weapon limit")
  equal(warrior[1302304], nil, "Imbue scrolls are for casters")
  assert(contains(warrior[16138].items, 287978), "Forever Rough Sharpening Stone item")
end

print("PASS: Forever knowledge for capabilities, classes and consumables")

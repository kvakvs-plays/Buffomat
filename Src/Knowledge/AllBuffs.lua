local BuffomatAddon = BuffomatAddon

---@alias BuffCategoryName ""|"tracking"|"pet"|"aura"|"seal"|"blessing"|"class"|"classicPhysFood"|"classicSpellFood"|"classicFood"|"classicPhysElixir"|"classicPhysBuff"|"classicBuff"|"classicSpellElixir"|"classicElixir"|"classicFlask"|"tbcPhysFood"|"tbcSpellFood"|"tbcFood"|"tbcPhysElixir"|"tbcSpellElixir"|"tbcElixir"|"tbcFlask"|"wotlkPhysFood"|"wotlkSpellFood"|"wotlkFood"|"wotlkPhysElixir"|"wotlkSpellElixir"|"wotlkElixir"|"wotlkFlask"|"scroll"|"weaponEnchantment"|"classWeaponEnchantment"|"cataElixir"|"cataFood"|"cataFlask"

---@alias BomBuffidBuffdefLookup {[BomBuffId]: BomBuffDefinition}
---@alias BomEnchantToSpellLookup {[BomEnchantmentId]: WowSpellId}
---@alias BomBuffBySpellId {[WowSpellId]: BomBuffDefinition}

---@class AllBuffsModule
---@field allBuffs BomBuffidBuffdefLookup All buffs, same as BOM.AllBuffomatSpells for convenience
---@field allSpellIds number[]
---@field buffCategories BuffCategoryName[] Category names for buffs
---@field buffFromSpellIdLookup BomBuffBySpellId Lookup table for buff definitions by spell id
---@field CrusaderAuraSpell BomBuffDefinition
---@field enchantToSpellLookup BomEnchantToSpellLookup Reverse-maps enchantment ids back to spells
---@field itemListSpellLookup table<number, number> Map itemid to spell?
---@field selectedBuffs BomBuffDefinition[] Buffs available to the player
---@field selectedBuffsSpellIds BomBuffBySpellId All spellids from selected buffs
---@field spellIdIsSingleLookup table<number, boolean> Whether spell ids are single buffs
---@field spellIdtoBuffId {[WowSpellId]: BomBuffId} Maps spell ids to the key id of spell in the AllSpells
---@field spellToSpellLookup {[WowSpellId]: WowSpellId} Maps spells ids to other spell ids
---@field cancelForm WowSpellId[] Spell ids which cancel shapeshift form

local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]

allBuffsModule.cancelForm = {}
allBuffsModule.spellIdtoBuffId = {}
allBuffsModule.selectedBuffs = {}
allBuffsModule.selectedBuffsSpellIds = --[[@as BomBuffBySpellId]] {}
allBuffsModule.spellIdIsSingleLookup = {}
allBuffsModule.buffFromSpellIdLookup = --[[@as {[WowSpellId]: BomBuffDefinition}]] {}
allBuffsModule.enchantToSpellLookup = --[[@as BomEnchantToSpellLookup]] {}

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local elixirsModule = LibStub("Buffomat-AllConsumesElixirs") --[[@as AllConsumesElixirsModule]]
local enchantmentsModule = LibStub("Buffomat-AllConsumesEnchantments") --[[@as AllConsumesEnchantmentsModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local flasksModule = LibStub("Buffomat-AllConsumesFlasks") --[[@as AllConsumesFlasksModule]]
local foodModule = LibStub("Buffomat-AllConsumesFood") --[[@as AllConsumesFoodModule]]
local otherModule = LibStub("Buffomat-AllConsumesOther") --[[@as AllConsumesOtherModule]]
local scrollsModule = LibStub("Buffomat-AllConsumesScrolls") --[[@as AllConsumesScrollsModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

local deathknightModule = LibStub("Buffomat-AllSpellsDeathknight") --[[@as DeathknightModule]]
local druidModule = LibStub("Buffomat-AllSpellsDruid") --[[@as DruidModule]]
local hunterModule = LibStub("Buffomat-AllSpellsHunter") --[[@as HunterModule]]
local mageModule = LibStub("Buffomat-AllSpellsMage") --[[@as MageModule]]
local paladinModule = LibStub("Buffomat-AllSpellsPaladin") --[[@as PaladinModule]]
local priestModule = LibStub("Buffomat-AllSpellsPriest") --[[@as PriestModule]]
local rogueModule = LibStub("Buffomat-AllSpellsRogue") --[[@as RogueModule]]
local shamanModule = LibStub("Buffomat-AllSpellsShaman") --[[@as ShamanModule]]
local warlockModule = LibStub("Buffomat-AllSpellsWarlock") --[[@as WarlockModule]]
local warriorModule = LibStub("Buffomat-AllSpellsWarrior") --[[@as WarriorModule]]

---@alias ClassName "WARRIOR"|"MAGE"|"ROGUE"|"DRUID"|"HUNTER"|"PRIEST"|"WARLOCK"|"SHAMAN"|"PALADIN"|"DEATHKNIGHT"|"tank"|"pet"

---@type ClassName[]
allBuffsModule.ALL_CLASSES = {
  "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "PRIEST", "WARLOCK",
  "SHAMAN", "PALADIN", "DEATHKNIGHT"
}
allBuffsModule.BOM_NO_CLASSES = {} ---@type ClassName[]

---TODO: Move to constModule
---Classes which have a resurrection ability
---@type ClassName[]
local RESURRECT_CLASSES = { "SHAMAN", "PRIEST", "PALADIN", "DRUID" } -- Druid in WotLK
allBuffsModule.RESURRECT_CLASSES = RESURRECT_CLASSES

---TODO: Move to constModule
--- Classes which have mana bar and benefit from mp/5 and spirit
---@type ClassName[]
local MANA_CLASSES = { "HUNTER", "WARLOCK", "MAGE", "DRUID", "SHAMAN", "PRIEST", "PALADIN" }
BuffomatAddon.MANA_CLASSES = MANA_CLASSES --used in TaskScan.lua
allBuffsModule.MANA_CLASSES = MANA_CLASSES

---TODO: Move to constModule
--- Classes which deal spell damage
---@type ClassName[]
allBuffsModule.SPELL_CLASSES = { "WARLOCK", "MAGE", "DRUID", "SHAMAN", "PRIEST", "PALADIN", "DEATHKNIGHT", "HUNTER" }

---TODO: Move to constModule
--- Classes which hit with weapons or claws
---@type ClassName[]
allBuffsModule.MELEE_CLASSES = { "WARRIOR", "ROGUE", "DRUID", "SHAMAN", "PALADIN", "DEATHKNIGHT" }

---TODO: Move to constModule
--- Classes capable of dealing shadow damage
---@type ClassName[]
allBuffsModule.SHADOW_CLASSES = { "PRIEST", "WARLOCK", "DEATHKNIGHT" }

---TODO: Move to constModule
--- Classes capable of dealing fire damage
---@type ClassName[]
allBuffsModule.FIRE_CLASSES = { "MAGE", "WARLOCK", "SHAMAN", "HUNTER" }

---TODO: Move to constModule
--- Classes capable of dealing frost damage
---@type ClassName[]
allBuffsModule.FROST_CLASSES = { "MAGE", "SHAMAN", "DEATHKNIGHT" }

---TODO: Move to constModule
--- Classes dealing physical ranged or melee damage
---@type ClassName[]
allBuffsModule.PHYSICAL_CLASSES = { "HUNTER", "ROGUE", "SHAMAN", "WARRIOR", "DRUID", "PALADIN", "DEATHKNIGHT" }

allBuffsModule.MINUTE = 60
allBuffsModule.TWO_MINUTES = allBuffsModule.MINUTE * 2
allBuffsModule.FIVE_MINUTES = allBuffsModule.MINUTE * 5
allBuffsModule.TEN_MINUTES = allBuffsModule.MINUTE * 10
allBuffsModule.FIFTEEN_MINUTES = allBuffsModule.MINUTE * 15
allBuffsModule.TWENTY_MINUTES = allBuffsModule.MINUTE * 20
allBuffsModule.HALF_AN_HOUR = allBuffsModule.MINUTE * 30
allBuffsModule.HOUR = allBuffsModule.MINUTE * 60

--- From 2 choices return TBC if BOM.IsTBC is true, otherwise return classic
local function tbcOrClassic(tbc, classic)
  if envModule.haveTBC then
    return tbc
  end
  return classic
end
allBuffsModule.TbcOrClassic = tbcOrClassic

--- From 2 choices return TBC if BOM.IsTBC is true, otherwise return classic
function allBuffsModule.ExpansionChoice(classic, tbc, wotlk)
  if envModule.haveWotLK then
    return wotlk
  end
  if envModule.haveTBC then
    return tbc
  end
  return classic
end

---Add RESOURCE TRACKING spells
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function allBuffsModule:SetupTrackingSpells(allBuffs, enchantments)
  -- Find Herbs / kräuter
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.FindHerbs, nil)
      :BuffType("tracking")
      :IsDefault(true)
      :Category("tracking")

  -- Find Minerals / erz
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.FindMinerals, nil)
      :BuffType("tracking")
      :IsDefault(true)
      :Category("tracking")

  -- Find Treasure / Schatzsuche / Zwerge
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.FindTreasure, nil)
      :BuffType("tracking")
      :IsDefault(true)
      :Category("tracking")

  -- Find Fish (TBC daily quest reward)
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.FindFish, nil)
      :BuffType("tracking")
      :IsDefault(false)
      :Category("tracking")

  return allBuffs
end

-- Append contents of array B to array A
local function Append(A, B)
  for _, v in ipairs(B) do
    table.insert(A, v)
  end
end

function allBuffsModule:SetupConstantsCategories()
  --self.CLASSIC_PHYS_FOOD = "classicPhysFood"
  --self.CLASSIC_SPELL_FOOD = "classicSpellFood"
  --self.CLASSIC_FOOD = "classicFood"
  --self.CLASSIC_PHYS_ELIXIR = "classicPhysElixir"
  --self.CLASSIC_PHYS_BUFF = "classicPhysBuff"
  --self.CLASSIC_BUFF = "classicBuff"
  --self.CLASSIC_SPELL_ELIXIR = "classicSpellElixir"
  --self.CLASSIC_ELIXIR = "classicElixir"
  --self.CLASSIC_FLASK = "classicFlask"
  --
  --self.SCROLL = "scroll"
  --self.WEAPON_ENCHANTMENT = "weaponEnchantment"
  --self.CLASS_WEAPON_ENCHANTMENT = "classWeaponEnchantment"

  -- Categories ordered for display
  self.buffCategories = {
    "class", "classWeaponEnchantment", "blessing", "seal", "aura", "pet", "tracking",

    "classicPhysElixir", "classicPhysBuff", "classicSpellElixir", "classicElixir", "classicFlask",
    "classicFood", "classicPhysFood", "classicSpellFood",
  }

  if envModule.haveWotLK then
    Append(self.buffCategories,
      { "wotlkPhysElixir", "wotlkSpellElixir", "wotlkElixir", "wotlkFlask", "wotlkFood", "wotlkPhysFood",
        "wotlkSpellFood", })
  end
  if envModule.haveTBC then
    Append(self.buffCategories,
      { "tbcPhysElixir", "tbcSpellElixir", "tbcElixir", "tbcFlask", "tbcFood", "tbcPhysFood", "tbcSpellFood", })
  end
  if envModule.haveCata then
    Append(self.buffCategories, { "cataFood", "cataElixir", "cataFlask", })
  end
  Append(self.buffCategories, { "scroll", "weaponEnchantment", "" })
end

function allBuffsModule:SetupConstants()
  self:SetupConstantsCategories()
end

--- Filter away the 'false' element and return only keys, values become the translation strings
---@return {[string]: string}
function allBuffsModule:GetBuffCategories()
  local result = {}
  for _i, cat in ipairs(self.buffCategories) do
    if type(cat) == "string" and cat ~= "" then
      result[ --[[@as string]] cat ] = _t("Category_" .. cat)
    end
  end
  return result
end

---Filter the input `allbuffs` if the limitations check returns true
---@param allBuffs BomBuffDefinition[] Input list of all buffs
---@return BomBuffDefinition[] Filtered list
function allBuffsModule:ApplyPostLimitations(allBuffs)
  -- Apply post-limitations (added with :Limitation() functions on spell construction)
  local result = {}

  for _i, buff in ipairs(allBuffs) do
    if buff.limitations ~= nil then
      if buffDefModule:CheckStaticLimitations(buff, buff.limitations) then
        table.insert(result, buff)
      end
    end
    buff.limitations = nil -- do not need to store this
  end

  return result
end

---@alias BomBuffId string
---@alias BomEnchantmentId number #Wow Enchantment ID https://wowwiki-archive.fandom.com/wiki/EnchantId/Enchant_IDs

---@alias BomAllBuffsTable {[BomBuffId]: BomBuffDefinition}

---@alias BomEnchantmentsMapping {[WowSpellId]: BomEnchantmentId[]}

---All spells known to Buffomat
---Note: you can add your own spell in the "WTF\Account\<accountname>\SavedVariables\buffOmat.lua"
---table CustomSpells
function allBuffsModule:SetupSpells()
  local allBuffs = {} --[[@as BomBuffDefinition[] ]]
  local enchantments = {} --[[@as BomEnchantmentsMapping]]
  self:SetupConstants()

  priestModule:SetupPriestSpells(allBuffs, enchantments)
  druidModule:SetupDruidSpells(allBuffs, enchantments)
  mageModule:SetupMageSpells(allBuffs, enchantments)
  shamanModule:SetupShamanSpells(allBuffs, enchantments)
  warlockModule:SetupWarlockSpells(allBuffs, enchantments)
  hunterModule:SetupHunterSpells(allBuffs, enchantments)
  paladinModule:SetupPaladinSpells(allBuffs, enchantments)
  warriorModule:SetupWarriorSpells(allBuffs, enchantments)
  rogueModule:SetupRogueSpells(allBuffs, enchantments)
  deathknightModule:SetupDeathknightSpells(allBuffs, enchantments)

  self:SetupTrackingSpells(allBuffs, enchantments)

  scrollsModule:SetupScrolls(allBuffs, enchantments)
  enchantmentsModule:SetupEnchantments(allBuffs, enchantments)
  elixirsModule:SetupElixirs(allBuffs, enchantments)
  flasksModule:SetupFlasks(allBuffs, enchantments)
  foodModule:SetupFood(allBuffs, enchantments)
  otherModule:SetupOtherConsumables(allBuffs, enchantments)

  allBuffs = self:ApplyPostLimitations(allBuffs) --filter the list and make new shorter list

  --Preload items!
  for x, spell in ipairs(allBuffs) do
    if spell.isConsumable and spell.items then
      for _, item in ipairs(spell.items or {}) do
        BuffomatAddon.GetItemInfo(item)
      end
    end
  end

  allBuffsModule.enchantToSpellLookup = {}
  for dest, list in pairs(enchantments) do
    for i, id in ipairs(list) do
      allBuffsModule.enchantToSpellLookup[id] = dest
    end
  end

  -- Move from list of buffs to buffid-keyed buff dictionary
  self.allBuffs = {} --[[@as BomBuffidBuffdefLookup]]
  for _i, buff in ipairs(allBuffs) do
    self.allBuffs[buff.buffId] = buff
  end

  BuffomatAddon.enchantList = enchantments
end

---@class BomReputationTrinketZones
---@field itemIds WowItemId[]
---@field zoneId WowZoneId[]
---@field Link string
---@field spell WowSpellId
BuffomatAddon.reputationTrinketZones = {
  itemIds = {
    12846, -- Simple AD trinket
    13209, -- Seal of the Dawn +81 AP
    19812, -- Rune of the Dawn +48 SPELL
    23206, -- Mark of the Chamption +150 AP
    23207, -- Mark of the Chamption +85 SPELL
  },
  zoneId  = {
    329, 289, 533, 535, --Stratholme/scholomance; Naxxramas LK 10/25
    558,                -- TBC: Auchenai
    532,                -- TBC: Karazhan
  },
}

---@class BomRidingSpeedZones
---@field itemIds WowItemId[]
---@field zoneId WowZoneId[]
---@field Link string
---@field spell WowSpellId
BuffomatAddon.ridingSpeedZones = {
  itemIds = {
    11122, -- Classic: Item [Carrot on a Stick]
    25653, -- TBC: Item [Riding Crop]
    32481, -- TBC: Item [Charm of Swift Flight]
  },
  --Allow Riding Speed trinkets in:
  zoneId  = {
    0, 1, 530, -- Eastern Kingdoms, Kalimdor, Outland
    30,        -- Alterac Valley
    529,       -- Arathi Basin,
    489,       -- Warsong Gulch
    566, 968,  -- TBC: Eye of the Storm
    --1672, 1505, 572, -- TBC: Blade's Edge Arena, Nagrand Arena, Ruins of Lordaeron
  },
}

BuffomatAddon.buffExchangeId = {            -- combine-spell-ids to new one
  [18788] = { 18791, 18790, 18789, 18792 }, -- Demonic Sacrifice-Buffs to Demonic Sacrifice
  [16591] = { 16591, 16589, 16595, 16593 }, -- noggenfoger
}

allBuffsModule.spellToSpellLookup = {}
for dest, list in pairs(BuffomatAddon.buffExchangeId) do
  for i, id in ipairs(list) do
    allBuffsModule.spellToSpellLookup[id] = dest
  end
end

---@deprecated
BuffomatAddon.itemList = {
  --{6948}, -- Hearthstone | Ruhestein
  --{4604}, -- Forest Mushroom | Waldpilz
  --{8079},-- Water | wasser
  { 5232, 16892, 16893, 16895, -- Soulstone | Seelenstein
    16896 },                   -- TBC: Major Soulstone
}
allBuffsModule.itemListSpellLookup = {
  [8079]  = 432, -- Water | Wasser
  [5232]  = 20762,
  [16892] = 20762,
  [16893] = 20762,
  [16895] = 20762,
  [16896] = 20762, -- Soulstone | Seelenstein
}

-- -@return table<number, BomBuffDefinition>
function allBuffsModule:SetupCancelBuffs()
  -- Note: you can add your own spell in the "WTF\Account\<accountname>\SavedVariables\buffOmat.lua"
  -- table CustomCancelBuff
  local spirit = priestModule:CreatePrayerOfSpiritBuff()
  spirit.default = false

  local intelli = mageModule:CreateIntelligenceBuff()
  intelli.default = false

  local s = {
    priestModule:CreatePowerWordShieldBuff(),
    spirit,
    intelli,
  }

  do
    local _, class, _ = UnitClass("unit")
    if class == "HUNTER" then
      local buff = buffDefModule:New(5118) --Aspect of the Cheetah/of the pack
          :OnlyCombat(true)
          :IsDefault(true)
          :SingleFamily({ 5118, 13159 })
      table.insert(s, buff)
    end

    if (UnitFactionGroup("player")) ~= "Horde" or envModule.haveTBC or envModule.isForever then
      local buff = buffDefModule:New(1038) --Blessing of Salvation
          :IsDefault(false)
          :SingleFamily({ 1038, 25895 })
      table.insert(s, buff)
    end
  end

  BuffomatAddon.cancelBuffs = s
end

-- Having this buff on target excludes the target (phaseshifted imp for example)
BuffomatAddon.buffIgnoreAll = {
  4511 -- Phase Shift (imp)
}

local ShapeShiftTravel = {
  2645,
  783
} --Ghost wolf and travel druid

BuffomatAddon.drinkingPersonCount = 0
BuffomatAddon.AllDrink = {
  30024,                                          -- Restores 20% mana
  430,                                            -- level 5 drink
  431,                                            -- level 15 drink
  432,                                            -- level 25 drink
  1133,                                           -- level 35 drink
  1135,                                           -- level 45 drink
  1137, 29007, 43154, 24355, 25696, 43155, 26261, -- level 55 drink
  10250, 22734,                                   -- TBC: level 65 drink
  34291,                                          -- TBC: level 70 drink
  27089, 43706, 46755,                            -- TBC? level 75 drink
}

---For all spells database load data for spellids and items
function allBuffsModule:LoadItemsAndSpells()
  for _index, buffDef in pairs(self.allBuffs) do
    buffDef:Preload()
  end
end
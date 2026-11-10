local BuffomatAddon = BuffomatAddon

---@alias BuffCategoryName ""|"reminder"|"tracking"|"pet"|"aura"|"seal"|"blessing"|"class"|"classicPhysFood"|"classicSpellFood"|"classicFood"|"classicPhysElixir"|"classicPhysBuff"|"classicBuff"|"classicSpellElixir"|"classicElixir"|"classicFlask"|"tbcPhysFood"|"tbcSpellFood"|"tbcFood"|"tbcPhysElixir"|"tbcSpellElixir"|"tbcElixir"|"tbcFlask"|"wotlkPhysFood"|"wotlkSpellFood"|"wotlkFood"|"wotlkPhysElixir"|"wotlkSpellElixir"|"wotlkElixir"|"wotlkFlask"|"scroll"|"weaponEnchantment"|"classWeaponEnchantment"|"cataElixir"|"cataFood"|"cataFlask"

---@alias BomBuffidBuffdefLookup {[BomBuffId]: BomBuffDefinition}
---@alias BomEnchantToSpellLookup {[BomEnchantmentId]: WowSpellId}
---@alias BomBuffBySpellId {[WowSpellId]: BomBuffDefinition}

---@class AllBuffsModule
---@field allBuffs BomBuffidBuffdefLookup All buffs, same as BOM.AllBuffomatSpells for convenience
---@field allSpellIds number[]
---@field allSpellIdSet table<WowSpellId, boolean> The same ids as a set, for a lookup per aura
---@field drinkSpellIdSet table<WowSpellId, boolean> Auras of somebody drinking
---@field ignoreAllSpellIdSet table<WowSpellId, boolean> Auras which exclude a unit from all buffing
---@field setupVersion number Counts spell setups; the auras stored per unit depend on the setup
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

local module = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]

module.cancelForm = {}
module.spellIdtoBuffId = {}
module.selectedBuffs = {}
module.selectedBuffsSpellIds = --[[@as BomBuffBySpellId]] {}
module.spellIdIsSingleLookup = {}
module.buffFromSpellIdLookup = --[[@as {[WowSpellId]: BomBuffDefinition}]] {}
module.enchantToSpellLookup = --[[@as BomEnchantToSpellLookup]] {}

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local elixirsModule = LibStub("Buffomat-AllConsumesElixirs") --[[@as AllConsumesElixirsModule]]
local enchantmentsModule = LibStub("Buffomat-AllConsumesEnchantments") --[[@as AllConsumesEnchantmentsModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local flasksModule = LibStub("Buffomat-AllConsumesFlasks") --[[@as AllConsumesFlasksModule]]
local foodModule = LibStub("Buffomat-AllConsumesFood") --[[@as AllConsumesFoodModule]]
local foreverConsumesModule = LibStub("Buffomat-AllConsumesForever") --[[@as AllConsumesForeverModule]]
local foreverRemindersModule = LibStub("Buffomat-ForeverReminders") --[[@as ForeverRemindersModule]]
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
module.ALL_CLASSES = {
  "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "PRIEST", "WARLOCK",
  "SHAMAN", "PALADIN", "DEATHKNIGHT"
}
module.BOM_NO_CLASSES = {} ---@type ClassName[]

---TODO: Move to constModule
---Classes which have a resurrection ability
---@type ClassName[]
local RESURRECT_CLASSES = { "SHAMAN", "PRIEST", "PALADIN", "DRUID" } -- Druid in WotLK and Forever
module.RESURRECT_CLASSES = RESURRECT_CLASSES

---TODO: Move to constModule
--- Classes which have mana bar and benefit from mp/5 and spirit
---@type ClassName[]
local MANA_CLASSES = { "HUNTER", "WARLOCK", "MAGE", "DRUID", "SHAMAN", "PRIEST", "PALADIN" }
BuffomatAddon.MANA_CLASSES = MANA_CLASSES
module.MANA_CLASSES = MANA_CLASSES

---TODO: Move to constModule
--- Classes which deal spell damage
---@type ClassName[]
module.SPELL_CLASSES = { "WARLOCK", "MAGE", "DRUID", "SHAMAN", "PRIEST", "PALADIN", "DEATHKNIGHT", "HUNTER" }

---TODO: Move to constModule
--- Classes which hit with weapons or claws
---@type ClassName[]
module.MELEE_CLASSES = { "WARRIOR", "ROGUE", "DRUID", "SHAMAN", "PALADIN", "DEATHKNIGHT" }

---TODO: Move to constModule
--- Classes capable of dealing shadow damage
---@type ClassName[]
module.SHADOW_CLASSES = { "PRIEST", "WARLOCK", "DEATHKNIGHT" }

---TODO: Move to constModule
--- Classes capable of dealing fire damage
---@type ClassName[]
module.FIRE_CLASSES = { "MAGE", "WARLOCK", "SHAMAN", "HUNTER" }

---TODO: Move to constModule
--- Classes capable of dealing frost damage
---@type ClassName[]
module.FROST_CLASSES = { "MAGE", "SHAMAN", "DEATHKNIGHT" }

---TODO: Move to constModule
--- Classes dealing physical ranged or melee damage
---@type ClassName[]
module.PHYSICAL_CLASSES = { "HUNTER", "ROGUE", "SHAMAN", "WARRIOR", "DRUID", "PALADIN", "DEATHKNIGHT" }

module.MINUTE = 60
module.TWO_MINUTES = module.MINUTE * 2
module.THREE_MINUTES = module.MINUTE * 3
module.FIVE_MINUTES = module.MINUTE * 5
module.TEN_MINUTES = module.MINUTE * 10
module.FIFTEEN_MINUTES = module.MINUTE * 15
module.TWENTY_MINUTES = module.MINUTE * 20
module.HALF_AN_HOUR = module.MINUTE * 30
module.HOUR = module.MINUTE * 60
module.TWO_HOURS = module.HOUR * 2

--- From 2 choices return TBC if BOM.IsTBC is true, otherwise return classic
local function tbcOrClassic(tbc, classic)
  if envModule.haveTBC then
    return tbc
  end
  return classic
end
module.TbcOrClassic = tbcOrClassic

---Pick a value which differs on WoW: Forever, such as a buff duration.
---@generic T
---@param forever T Value on WoW: Forever
---@param other T Value on every other client
---@return T
function module.ForeverOr(forever, other)
  if envModule.isForever then
    return forever
  end
  return other
end

--- From 2 choices return TBC if BOM.IsTBC is true, otherwise return classic
function module.ExpansionChoice(classic, tbc, wotlk)
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
function module:SetupTrackingSpells(allBuffs, enchantments)
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

function module:SetupConstantsCategories()
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
    "reminder", -- synthetic buffs: Forever reminders, on/off is an account option
    "class", "classWeaponEnchantment", "blessing", "seal", "aura", "pet", "tracking",

    "classicPhysElixir", "classicPhysBuff", "classicBuff", "classicSpellElixir", "classicElixir", "classicFlask",
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

function module:SetupConstants()
  self:SetupConstantsCategories()
end

--- Filter away the 'false' element and return only keys, values become the translation strings
---@return {[string]: string}
function module:GetBuffCategories()
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
function module:ApplyPostLimitations(allBuffs)
  -- Apply post-limitations (added with :Limitation() functions on spell construction)
  local result = {}

  for _i, buff in ipairs(allBuffs) do
    if buff.limitations ~= nil then
      if buffDefModule:CheckStaticLimitations(buff, buff.limitations) then
        table.insert(result, buff)
      end
    end
    -- Keep the limitations: SpellSetup checks the dynamic ones (maxLevel, minLevel, hideIfSpellKnown)
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
function module:SetupSpells()
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
  if envModule.isForever then
    foreverConsumesModule:SetupForeverConsumables(allBuffs, enchantments)
    foreverRemindersModule:SetupForeverReminders(allBuffs)
  end

  allBuffs = self:ApplyPostLimitations(allBuffs) --filter the list and make new shorter list

  --Preload items!
  for _, spell in ipairs(allBuffs) do
    if spell.isConsumable and spell.items then
      for _, item in ipairs(spell.items or {}) do
        BuffomatAddon.GetItemInfo(item)
      end
    end
  end

  module.enchantToSpellLookup = {}
  for dest, list in pairs(enchantments) do
    for _, id in ipairs(list) do
      module.enchantToSpellLookup[id] = dest
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

module.spellToSpellLookup = {}
for dest, list in pairs(BuffomatAddon.buffExchangeId) do
  for _, id in ipairs(list) do
    module.spellToSpellLookup[id] = dest
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
module.itemListSpellLookup = {
  [8079]  = 432, -- Water | Wasser
  [5232]  = 20762,
  [16892] = 20762,
  [16893] = 20762,
  [16895] = 20762,
  [16896] = 20762, -- Soulstone | Seelenstein
}

-- -@return table<number, BomBuffDefinition>
function module:SetupCancelBuffs()
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

    -- Blessing of Salvation does not exist on Forever
    if not envModule.isForever and ((UnitFactionGroup("player")) ~= "Horde" or envModule.haveTBC) then
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

---@param ids number[]
---@return table<number, boolean>
local function toSet(ids)
  local set = {}
  for _, id in ipairs(ids) do
    set[id] = true
  end
  return set
end

module.drinkSpellIdSet = toSet(BuffomatAddon.AllDrink)
module.ignoreAllSpellIdSet = toSet(BuffomatAddon.buffIgnoreAll)
module.allSpellIdSet = {}
module.setupVersion = 0

---Called when the list of available spells was rebuilt.
function module:OnSpellSetupChanged()
  wipe(self.allSpellIdSet)
  for _, spellId in ipairs(self.allSpellIds or {}) do
    self.allSpellIdSet[spellId] = true
  end
  self.setupVersion = self.setupVersion + 1
end

---For all spells database load data for spellids and items
function module:LoadItemsAndSpells()
  for _index, buffDef in pairs(self.allBuffs) do
    buffDef:Preload()
  end
end

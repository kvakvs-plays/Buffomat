local BuffomatAddon = BuffomatAddon

---@alias BomElixirType "battle"|"guardian"|"both"
---@alias WowSpellId number
---@alias WowItemId number
---@alias WowZoneId number
---@alias WowShapeshiftFormId number
---@alias WowIconId number|string

---@class BuffDefinitionModule

local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local spellCacheModule = LibStub("Buffomat-SpellCache") --[[@as BomSpellCacheModule]]
local itemCacheModule = LibStub("Buffomat-ItemCache") --[[@as BomItemCacheModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]

---type="aura" Auras are no target buff check. True if the buff affects others in radius, and not a target buff
---type="seal" Seals are 1hand enchants which are unique for equipped weapon. Paladins use seals. Shamans also use seals but in TBC shamans have 2 independent seals.
---type="resurrection" The spell will bring up a dead person
---type="tracking" the buff grants the tracking of some resource or enemy type
---type="weapon" The buff is a temporary weapon enchant on user's weapons (poison or shaman etc)
---@alias BomBuffType "aura"|"consumable"|"weapon"|"seal"|"tracking"|"resurrection"|"summon"

---@alias BomCreatureType "Demon"|"Undead"
---@alias BomCreatureFamily "Ghoul"|"Voidwalker"|"Imp"|"Succubus"|"Incubus"|"Felhunter"|"Felguard"
---@alias BomPlayerRace "BloodElf"|"Draenei"|"Dwarf"|"Gnome"|"Human"|"NightElf"|"Orc"|"Tauren"|"Troll"|"Undead"

---@class BomSpellLimitations
---@field cancelForm boolean Casting spell requires leaving shapeshift, shadow form etc.
---@field requireTBC boolean
---@field hideInTBC boolean
---@field requireWotLK boolean
---@field hideInWotLK boolean
---@field requireCata boolean
---@field hideInCata boolean
---@field playerRace BomPlayerRace
---@field playerClass ClassName|ClassName[] Collection of classes for this spell, or classname
---@field maxLevel number Hide the spell if player is above this level (to deprecate old spells)
---@field minLevel number Hide the spell if player is below this level
---@field hideIfSpellKnown number Hide the spell if spellId is in their spellbook

---@return BomSpellLimitations
function allBuffsModule:NewSpellLimitations()
  return {}
end

---
--- A class describing a spell in available spells collection
---
-- -@shape BomBuffDefinitionTable
-- -@field [BomSpellId] BomBuffDefinition

---@alias BomForcedTargets {[string]: boolean}
---@alias BomDeadMap {[number|ClassName]: boolean}

-- Fields below belong to PlayerBuffChoice
-- -@field AllowWhisper boolean [⚠DO NOT RENAME] Allow whispering expired soulstone to the warlock
-- -@field Class table<BomClassName, boolean> [⚠DO NOT RENAME] List of classes to receive this buff
-- -@field Enable boolean [⚠DO NOT RENAME]  Whether buff is to be watched
-- -@field ExcludedTarget BomForcedTargets [⚠DO NOT RENAME] List of target names to never buff
-- -@field ForcedTarget BomForcedTargets [⚠DO NOT RENAME] List of extra targets to buff
-- -@field MainHandEnable boolean [⚠DO NOT RENAME]
-- -@field OffHandEnable boolean [⚠DO NOT RENAME]
-- -@field SelfCast boolean [⚠DO NOT RENAME]

---@class BomBuffDefinition
---@field buffId BomBuffId Spell id of level 60 spell used as key everywhere else
---@field buffSource string Unit/player who gave this buff
---@field category BuffCategoryName Group by this field and use special translation table to display headers
---@field consumableEra string One of constants BOM.CLASSIC_ERA or BOM.IsTBC_ERA which will affect buff visibility based on used choice
---@field consumableTarget string Add "[@" .. consumableTarget .. "]" to the "/use bag slot" macro
---@field creatureFamily BomCreatureFamily Warlock summon pet family for type='summon' (Imp, etc)
---@field creatureType BomCreatureType Warlock summon pet type for type='summon' (Demon)
---@field default boolean Whether the spell auto-cast is enabled by default
---@field elixirType string|nil Use this for elixir mutual exclusions on elixirs
---@field customSort string [⚠DO NOT RENAME]  Custom sorting value (default 5)
---@field extraText string Added to the right of spell name in the spells config
---@field groupDuration number Buff duration for group buff in seconds
---@field groupFamily number[]|nil Family of group buff spell ids which are mutually exclusive
---@field groupLink string Printable link for group buff
---@field groupMana number Mana cost for group buff
---@field groupsHaveDead BomDeadMap Group/class members who might be dead but their class needs this buff
---@field groupsNeedBuff table List of groups who might need this buff
---@field groupText string Name of group buff spell (from GetSpellInfo())
---@field hasCD boolean There's a cooldown on this spell
---@field highestRankGroupId WowSpellId Updated in SpellSetup for each spell cache update
---@field highestRankSingleId WowSpellId Updated in SpellSetup for each spell cache update
---@field ignoreIfBetterBuffs WowSpellId[] If these auras are present on target, the buff is not queued
---@field isBlessing boolean Spell will be cast on group members of the same class
---@field isConsumable boolean Is an item-based buff; the spell must have 'items' field too
---@field isInfo boolean Set true to send expiration whispers?
---@field isOwn boolean Spell only casts on self
---@field isScanned boolean
---@field itemIcon string|number
---@field items WowItemId[]|nil Conjuration spells create these items. Or buff is granted by an item in user's bag. Number is item id shows as the icon.
---@field limitations BomSpellLimitations|nil [Temporary] field for post-filtering on spell list creation, later zeroed
---@field lockIfHaveItem WowItemId[] Item ids which prevent this buff (unique conjured items for example)
---@field name string Loaded in spellcache.
---@field onlyUsableFor string[] list of classes which only can see this buff (hidden for others)
---@field optionText string Used to create sections in spell list in the options page
---@field reagentRequired WowItemId[] Reagent item ids required for group buff
---@field requiresForm number Required shapeshift form ID to cast this buff
---@field requiresOutdoors boolean Spell can only be cast outdoors
---@field requireWarlockPet boolean For Soul Link - must check if a demon pet is present
---@field sacrificeAuraIds WowSpellId[]|nil Aura id for demonic sacrifice of that pet. Do not summon if buff is present.
---@field section string Custom section to begin new spells group in the row builder
---@field shapeshiftFormId WowShapeshiftFormId Class-based form id (coming from GetShapeshiftFormID LUA API) if active, the spell is skipped
---@field singleDuration number - buff duration for single buff in seconds
---@field providesAuras WowSpellId[]|nil Check these if not nil; For special items which create multiple varied buffs
---@field singleFamily WowSpellId[] Family of single buff spell ids which are mutually exclusive
---@field singleLink string Printable link for single buff. Use buffdef:SingleLink() to safely handle missing value
---@field singleMana number Mana cost
---@field singleText string Name of single buff spell (from GetSpellInfo())
---@field consumeGroupTitle string Override spell name for groups of consumable buffs providing same stat
---@field consumeGroupIcon WowIconId Override buff icon for groups of consumables
---@field skipList string[] If spell cast failed, contains recently failed targets
---@field spellIcon WowIconId
---@field targetClasses ClassName[] List of target classes which are shown as toggle boxes to enable cast per class
---@field petBuff boolean True for hunter/warlock pet consumable which places aura on the pet
---@field trackingIconId WowIconId Numeric id for the tracking texture icon
---@field trackingSpellName string For tracking spells, contains string name for the spell
---@field type BomBuffType Defines type: "aura", "consumable", "weapon" for Enchant Consumables, "seal", "tracking", "resurrection"
---@field unitsHaveBetterBuff BomUnit[] List of group members who might need this buff but won't get it because they have better
---@field unitsNeedBuff BomUnit[] List of group members who might need this buff
--[deprecated] -@field frames BomBuffRowFrames Dynamic list of controls associated with this spell in the UI

local buffDefClass = {}
buffDefClass.__index = buffDefClass

---Creates a new SpellDef
---@param singleId WowSpellId Spell id also serving as buffId key
---@return BomBuffDefinition
function buffDefModule:New(singleId)
  local buff = {} --[[@as BomBuffDefinition]]
  buff.category = "" -- special value no category
  --buff.frames = buffRowModule:New(tostring(singleId)) -- spell buttons from the UI go here
  buff.buffId = singleId
  buff.highestRankSingleId = singleId
  buff.singleFamily = { singleId }
  buff.limitations = {} --[[@as BomSpellLimitations]]
  buff.ForcedTarget = {} --[[@as BomForcedTargets]]
  buff.ExcludedTarget = {} --[[@as BomForcedTargets]]
  buff.unitsNeedBuff = {}
  buff.unitsHaveBetterBuff = {}
  buff.groupsNeedBuff = {}
  buff.groupsHaveDead = {} --[[@as BomDeadMap]]
  buff.skipList = {}
  buff.targetClasses = {}

  setmetatable(buff, buffDefClass)
  return buff
end

function buffDefModule:tbcConsumable(dst, singleId, itemId)
  return self:genericConsumable(dst, singleId, itemId)
      :RequireTBC()
end

function buffDefModule:wotlkConsumable(dst, singleId, itemId)
  return self:genericConsumable(dst, singleId, itemId)
      :RequireWotLK()
end

function buffDefModule:cataConsumable(dst, singleId, itemId)
  return self:genericConsumable(dst, singleId, itemId)
      :RequireCata()
end

---@param allBuffs BomBuffDefinition[]
---@param singleId WowSpellId
---@param providedByItem WowItemId|WowItemId[] Item or multiple items giving this buff
---@return BomBuffDefinition
function buffDefModule:genericConsumable(allBuffs, singleId, providedByItem)
  local b = buffDefModule:createAndRegisterBuff(allBuffs, singleId, nil)
      :IsConsumable(true)
      :IsDefault(false)
      :CreatesOrProvidedByItem(providedByItem)
  return b
end

---@param allBuffs BomBuffDefinition[]
---@param buffId BomBuffId
---@param providesAuras WowSpellId[] Auras from the food
---@param providedByItems WowItemId[] Item or multiple items giving this buff
---@return BomBuffDefinition
function buffDefModule:consumableGroup(allBuffs, buffId, providesAuras, providedByItems)
  local b = buffDefModule:createAndRegisterBuff(allBuffs, providesAuras[1], nil)
      :IsConsumable(true)
      :IsDefault(false)
      :ProvidesAuras(providesAuras)
      :CreatesOrProvidedByItem(providedByItems)
  return b
end

local playerClass = envModule.playerClass

--TODO: Belongs to `BomBuffDefinition`
---Check the static limitations, which cannot change after the player logs in
---@param limitations BomSpellLimitations
function buffDefModule:CheckStaticLimitations(_spell, limitations)
  -- empty limitations return true
  if next(limitations) == nil then
    return true
  end

  if limitations.requireTBC == true and not envModule.haveTBC then
    return false
  end
  if limitations.hideInTBC == true and envModule.haveTBC then
    return false
  end

  if limitations.requireWotLK == true and not envModule.haveWotLK then
    return false
  end
  if limitations.hideInWotLK == true and envModule.haveWotLK then
    return false
  end
  if limitations.requireCata == true and not envModule.haveCata then
    return false
  end
  if limitations.hideInCata == true and envModule.haveCata then
    return false
  end

  if limitations.playerRace then
    local _localisedRace, englishRace, _numericId = UnitRace("player")
    if englishRace ~= limitations.playerRace then
      return false
    end
  end

  if type(limitations.playerClass) == "table" then
    -- Fail if val is a table and player class is not in it
    if not tContains(limitations.playerClass, playerClass) then
      return false
    end
  end

  -- Fail if val is not equal to the player class
  if type(limitations.playerClass) == "string"
      and limitations.playerClass ~= playerClass then
    return false
  end

  return true
end

---Checks dynamic buff limitations, which can change in the game
---@param limitations BomSpellLimitations|nil
function buffDefModule:CheckDynamicLimitations(limitations)
  -- empty limitations return true
  if not limitations or next(limitations) == nil then
    return true
  end

  if type((limitations).maxLevel) == "number"
      and UnitLevel("player") > (limitations).maxLevel then
    return false -- too old
  end

  if type((limitations).minLevel) == "number"
      and UnitLevel("player") < (limitations).minLevel then
    return false -- too young
  end

  if type((limitations).hideIfSpellKnown) == "number"
      and envModule.IsSpellKnown((limitations).hideIfSpellKnown) then
    return false -- know a blocker spell, a better version like ice armor/frost armor pair
  end

  return true
end

---Create a spelldef if the limitations apply and add to the table.
---Only check permanent limitations here like minlevel, TBC, or player class.
---@param allBuffs BomBuffDefinition[]
---@param buffSpellId number The buff spell ID is key in the AllSpells table
---@param limitations BomSpellLimitations|nil Check these conditions to skip adding the spell. Permanent conditions only like minlevel or class
---@return BomBuffDefinition
function buffDefModule:createAndRegisterBuff(allBuffs, buffSpellId, limitations)
  local spell = self:New(buffSpellId)

  if self:CheckStaticLimitations(spell, limitations or {}) then
    return self:registerBuff(allBuffs, spell)
  end

  return buffDefModule:New(0) -- limitations check failed
end

---@param dst BomBuffDefinition[]
---@return BomBuffDefinition
function buffDefModule:registerBuff(dst, spell)
  table.insert(dst, spell)
  return spell
end

---@param spellId number
---@param itemId number
function buffDefModule:conjureItem(spellId, itemId)
  return buffDefModule:New(spellId)
      :IsOwn(true)
      :IsDefault(true)
      :LockIfHaveItem({ itemId })
      :SingleFamily({ spellId })
end

---Add "[@" .. consumableTarget .. "]" to the "/use bag slot" macro
---@param unit string
---@return BomBuffDefinition
function buffDefClass:ConsumableTarget(unit)
  self.consumableTarget = unit
  return self
end

---@param own boolean
---@return BomBuffDefinition
function buffDefClass:IsOwn(own)
  self.isOwn = own
  return self
end

---@param isConsum boolean
---@return BomBuffDefinition
function buffDefClass:IsConsumable(isConsum)
  self.isConsumable = isConsum
  return self
end

local function reverseTable(tab)
  for i = 1, math.floor(#tab / 2), 1 do
    tab[i], tab[#tab - i + 1] = tab[#tab - i + 1], tab[i]
  end
  return tab
end

---@param itemId WowItemId|WowItemId[]
---@return BomBuffDefinition
function buffDefClass:CreatesOrProvidedByItem(itemId)
  if type(itemId) == "number" then
    self.items = { itemId --[[@as WowItemId]] }
  else
    self.items = itemId --[[@as WowItemId[] ]]
  end

  -- Clone item ids, and reverse
  self.itemsReverse = {}
  for _, val in pairs(self.items) do
    table.insert(self.itemsReverse, val)
  end
  reverseTable(self.itemsReverse)

  return self
end

function buffDefClass:EnsureDynamicMinLevelSet()
  -- No need to update
  if self.limitations and type(self.limitations.minLevel) == "number" then
    return
  end

  -- Set minLevel if item has minLevel, for multiple items in the array - pick lowest requirement
  -- If any of the requirements are nil, means the item cannot have the level requirement at all, reset and break loop
  for _, eachItemId in ipairs(self.items) do
    if eachItemId == nil then
      self:MinLevel(0)
      break
    end

    local onItemLoaded = function(itemInfo)
      local minLvl = 999

      if itemInfo and (itemInfo.itemMinLevel == nil or itemInfo.itemMinLevel <= 1) then
        minLvl = 0
      end

      if itemInfo and itemInfo.itemMinLevel > 1 then
        --local lim = (self.limitations)
        -- Pick lowest itemlevel of the item ids to show the buff
        if itemInfo.itemMinLevel < minLvl then
          minLvl = itemInfo.itemMinLevel
        end
      end

      self:MinLevel(minLvl)
    end

    itemCacheModule:LoadItem(eachItemId, onItemLoaded)
  end
end

---@param auraIds WowSpellId[]
---@return BomBuffDefinition
function buffDefClass:SacrificeAuraIds(auraIds)
  self.sacrificeAuraIds = auraIds
  return self
end

---@param cf BomCreatureFamily
---@return BomBuffDefinition
function buffDefClass:SummonCreatureFamily(cf)
  self.creatureFamily = cf
  return self
end

---@param ct BomCreatureType
---@return BomBuffDefinition
function buffDefClass:SummonCreatureType(ct)
  self.creatureType = ct
  return self
end

---@param cancel boolean
---@return BomBuffDefinition
function buffDefClass:RequiresCancelForm(cancel)
  self.cancelForm = cancel
  return self
end

---@param form WowShapeshiftFormId
---@return BomBuffDefinition
function buffDefClass:RequiresForm(form)
  self.requiresForm = form
  return self
end

---@param bt BomBuffType
---@return BomBuffDefinition
function buffDefClass:BuffType(bt)
  self.type = bt
  return self
end

---@param onlyCombat boolean
---@return BomBuffDefinition
function buffDefClass:OnlyCombat(onlyCombat)
  self.onlyCombat = onlyCombat
  return self
end

---@param enabled boolean
---@return BomBuffDefinition
function buffDefClass:IsDefault(enabled)
  self.default = enabled
  return self
end

---@param formId WowShapeshiftFormId
---@return BomBuffDefinition
function buffDefClass:ShapeshiftFormId(formId)
  self.shapeshiftFormId = formId
  return self
end

---@param itemIds WowItemId[]
---@return BomBuffDefinition
function buffDefClass:LockIfHaveItem(itemIds)
  self.lockIfHaveItem = itemIds
  return self
end

---@param itemIds WowItemId[]|WowItemId
---@return BomBuffDefinition
function buffDefClass:ReagentRequired(itemIds)
  if type(itemIds) == "table" then
    self.reagentRequired = --[[@as WowItemId[] ]] itemIds
  else
    self.reagentRequired = { --[[@as WowItemId]] itemIds }
  end
  return self
end

---@param spellIds WowSpellId[]
---@return BomBuffDefinition
function buffDefClass:SingleFamily(spellIds)
  self.singleFamily = spellIds
  return self
end

---@param spellIds WowSpellId[]
---@return BomBuffDefinition
function buffDefClass:GroupFamily(spellIds)
  self.groupFamily = spellIds
  return self
end

---@param isBlessing boolean
---@return BomBuffDefinition
function buffDefClass:IsBlessing(isBlessing)
  self.isBlessing = isBlessing
  return self
end

---@param duration number
---@return BomBuffDefinition
function buffDefClass:SingleDuration(duration)
  self.singleDuration = duration
  return self
end

---@param duration number
---@return BomBuffDefinition
function buffDefClass:GroupDuration(duration)
  self.groupDuration = duration
  return self
end

---@param consumeType "food"|"elixir"|"scroll"
---@param title string
---@param icon WowIconId
---@return BomBuffDefinition
function buffDefClass:ConsumeGroupTitle(consumeType, title, icon)
  local prefix

  if consumeType == "elixir" then
    prefix = buffomatModule:Color("1eff00", _t("consumeType.elixir"))
  elseif consumeType == "scroll" then
    prefix = buffomatModule:Color("1eff00", _t("consumeType.scroll"))
  elseif consumeType == "food" then
    prefix = buffomatModule:Color("1eff00", _t("consumeType.food"))
  elseif consumeType ~= "food" then
    prefix = "Unknown consume type: " .. consumeType
  end

  self.consumeGroupTitle = prefix .. " (" .. title .. ")"
  self.consumeGroupIcon = icon
  return self
end

function buffDefClass:RewriteSealBuffType()
  -- for before TBC make this a seal spell, for TBC do not modify
  if not envModule.haveTBC and not envModule.IsSpellKnown(674) then
    self.type = "seal"
  end
  return self
end

---@param cat BuffCategoryName
---@return BomBuffDefinition
function buffDefClass:Category(cat)
  self.category = cat
  return self
end

---@param requirePet boolean
---@return BomBuffDefinition
function buffDefClass:RequireWarlockPet(requirePet)
  self.requireWarlockPet = requirePet
  return self
end

---@param level number
---@return BomBuffDefinition
function buffDefClass:MaxLevel(level)
  (self.limitations).maxLevel = level
  return self
end

---@return BomBuffDefinition
---@param level number
function buffDefClass:MinLevel(level)
  if not self.limitations then
    self.limitations = allBuffsModule:NewSpellLimitations()
  end
  (self.limitations).minLevel = level
  return self
end

---@return BomBuffDefinition
---@param spellId number Do not show spell if a better spell of different spell group is available
function buffDefClass:HideIfSpellKnown(spellId)
  (self.limitations).hideIfSpellKnown = spellId
  return self
end

---@return BomBuffDefinition
function buffDefClass:RequireTBC()
  (self.limitations).requireTBC = true
  return self
end

---@param hasCD boolean
---@return BomBuffDefinition
function buffDefClass:HasCooldown(hasCD)
  self.hasCD = hasCD
  return self
end

---@return BomBuffDefinition
function buffDefClass:HideInTBC()
  (self.limitations).hideInTBC = true
  (self.limitations).hideInWotLK = true
  (self.limitations).hideInCata = true
  return self
end

---@return BomBuffDefinition
function buffDefClass:RequireWotLK()
  (self.limitations).requireWotLK = true
  return self
end

---@return BomBuffDefinition
function buffDefClass:HideInWotLK()
  (self.limitations).hideInWotLK = true
  (self.limitations).hideInCata = true
  return self
end

---@return BomBuffDefinition
function buffDefClass:HideInCata()
  (self.limitations).hideInCata = true
  return self
end

---@return BomBuffDefinition
function buffDefClass:RequireCata()
  (self.limitations).requireCata = true
  return self
end

---@return BomBuffDefinition
function buffDefClass:PetFood()
  self.petBuff = true
  return self
end

---@return BomBuffDefinition
---@param classNames ClassName[] Class names to use as the default targets (user can modify)
function buffDefClass:DefaultTargetClasses(classNames)
  self.targetClasses = classNames
  return self
end

---@param className ClassName[]|ClassName The class name or table of class names
---@return BomBuffDefinition
function buffDefClass:RequirePlayerClass(className)
  (self.limitations).playerClass = className
  return self
end

---@param raceName BomPlayerRace Player race
---@return BomBuffDefinition
function buffDefClass:RequirePlayerRace(raceName)
  (self.limitations).playerRace = raceName
  return self
end

---@param outdoors boolean
---@return BomBuffDefinition
function buffDefClass:RequiresOutdoors(outdoors)
  self.requiresOutdoors = outdoors
  return self
end

---@return BomBuffDefinition
---@param text string
function buffDefClass:ExtraText(text)
  self.extraText = text
  return self
end

---@param auras WowSpellId[]
---@return BomBuffDefinition
function buffDefClass:ProvidesAuras(auras)
  self.providesAuras = auras
  return self
end

---@param manaCost number
---@return BomBuffDefinition
function buffDefClass:SingleManaCost(manaCost)
  self.singleMana = manaCost
  return self
end

---@return BomBuffDefinition
---@param spellId WowSpellId|WowSpellId[]
function buffDefClass:IgnoreIfHaveBuff(spellId)
  self.ignoreIfBetterBuffs = self.ignoreIfBetterBuffs or {}
  if type(spellId) == "number" then
    tinsert(self.ignoreIfBetterBuffs, spellId)
  elseif type(spellId) == "table" then
    for _i, spell in ipairs( --[[@as WowSpellId[] ]] spellId) do
      tinsert(self.ignoreIfBetterBuffs, spell)
    end
  else
    BuffomatAddon:Print(string.format("Spell %s was given invalid value for 'ignoreifhavebuff' %s",
      tostring(self.buffId), tostring(spellId)))
  end
  return self
end

---@param elixirType BomElixirType
---@return BomBuffDefinition
function buffDefClass:ElixirType(elixirType)
  self.elixirType = elixirType
  return self
end

---@return boolean Whether the spell allows user to do target class choices
function buffDefClass:HasClasses()
  return not (self.isConsumable
    or self.isOwn
    or self.type == "resurrection"
    or self.type == "seal"
    or self.type == "tracking"
    or self.type == "aura"
    or self.isInfo)
end

---@param class_name string
function buffDefClass:IncrementNeedGroupBuff(class_name)
  self.groupsNeedBuff[class_name] = (self.groupsNeedBuff[class_name] or 0) + 1
end

---@param profileName ProfileName|nil
---@return BlessingState
function buffDefModule:GetProfileBlessingState(profileName)
  if profileName == nil then
    return buffomatModule.currentProfile.CurrentBlessing
    --return allBuffsModule.allBuffs[spellId]
  end

  local profile = BuffomatCharacter.profiles[profileName]
  if profile == nil then
    return --[[@as BlessingState]] {}
  end

  return profile.CurrentBlessing
end

---Returns true whether spell is enabled by the player (has checkbox)
---@param buffId number The key to the allSpells dictionary
---@param profileName ProfileName|nil
---@return boolean
function buffDefModule:IsBuffEnabled(buffId, profileName)
  local spell = profileModule:GetProfileBuff(buffId, profileName)
  if spell == nil then
    return false
  end
  return (spell).Enable
end

---Call function with the icon when icon value is ready, or immediately if value
---is available. This allows for late loaded icons.
---@param iconReadyFn fun(icon: string|WowSpellId)
function buffDefClass:GetIcon(iconReadyFn)
  if self.itemIcon then
    iconReadyFn(self.itemIcon) -- value was ready
    return
  end

  if self.spellIcon then
    iconReadyFn(self.spellIcon) -- value was ready
    return
  end

  -- Value was not ready
  self:RefreshTextAndIcon(iconReadyFn, nil)
end

---Get single text for item or spell. Apply text as a parameter to function
---immediately if ready, or when ready. This allows for late loaded names.
---@param nameReadyFn fun(name: string)
function buffDefClass:GetSingleText(nameReadyFn)
  if self.singleText then
    nameReadyFn(self.singleText)
    return
  end

  self:RefreshTextAndIcon(nil, nameReadyFn)
end

function buffDefClass:IsItem()
  -- TODO: self.isConsumable does this too?
  return self.items and next(self.items) ~= nil
end

---@param unit BomUnit
function buffDefClass:DoesUnitHaveBetterBuffs(unit)
  if type(self.ignoreIfBetterBuffs) == "table" then
    for _i, spellId in ipairs(self.ignoreIfBetterBuffs) do
      if unit.knownBuffs[spellId] ~= nil or unit.allBuffs[spellId] ~= nil then
        return true
      end
    end
  end

  if self.providesAuras then
    for i, aura in pairs(self.providesAuras) do
      if unit.allBuffs[aura] then
        return true -- have one of known provided auras, means we don't need that buff
      end
    end
  end

  return false
end

function buffDefClass:ResetBuffTargets()
  wipe(self.groupsNeedBuff)
  wipe(self.groupsHaveDead)
  wipe(self.unitsNeedBuff)
  wipe(self.unitsHaveBetterBuff)
end

---@param iconReadyFn fun(texture: string)|nil Call with result when icon value is ready
---@param nameReadyFn fun(name: string)|nil Call with result when name value is ready
function buffDefClass:RefreshTextAndIcon(iconReadyFn, nameReadyFn)
  -- TODO: If refresh is in progress and multiple requests come in parallel, that might also be a problem
  if self:IsItem() then
    local _, itemId = next(self.items)

    itemCacheModule:LoadItem(
      itemId,
      function(loadedItem)
        self.itemIcon = loadedItem.itemTexture
        if iconReadyFn ~= nil then
          iconReadyFn(loadedItem.itemTexture)
        end

        self.singleText = loadedItem.itemName
        if nameReadyFn ~= nil then
          nameReadyFn(loadedItem.itemName)
        end
      end)
    return
  end

  local _, singleId = next(self.singleFamily)
  spellCacheModule:LoadSpell(
    singleId,
    function(loadedSpell)
      self.spellIcon = loadedSpell.icon -- update own copy of icon
      if iconReadyFn ~= nil then
        iconReadyFn(loadedSpell.icon)
      end

      self.singleText = loadedSpell.name -- update own copy of spell name
      if nameReadyFn ~= nil then
        nameReadyFn(loadedSpell.name)
      end
    end)

  -- nil otherwise
end

---@return WowItemId|nil
function buffDefClass:GetFirstItem()
  local _, itemId = next(self.items)
  return itemId
end

function buffDefClass:Preload()
  local noAction = function()
    -- ok
  end

  for singleId in pairs(self.singleFamily) do
    spellCacheModule:LoadSpell(singleId, noAction)
  end

  for _index, groupId in pairs(self.groupFamily or {}) do
    spellCacheModule:LoadSpell(groupId, noAction)
  end

  for _index, itemId in pairs(self.items or {}) do
    itemCacheModule:LoadItem(itemId, noAction)
  end
end

--- Scan the buff spellids from lowest rank to highest, if the spellId is found, return the previous spellId which
--- will be one rank lower. If nothing found, return whatever was last.
---@param spellId number
---@return number
function buffDefClass:GetDownRank(spellId)
  local downrank = spellId
  for _i, eachSingleId in ipairs(self.singleFamily) do
    if eachSingleId == spellId then
      return downrank
    end
    downrank = eachSingleId
  end
  return downrank -- unsuccessful but return whatever found
end

---@param bestItemIdAvailable WowItemId|nil If set, will request item link to a specific item
function buffDefClass:SingleLink(bestItemIdAvailable)
  if bestItemIdAvailable then
    local itemInfo = BuffomatAddon.GetItemInfo(bestItemIdAvailable)
    if itemInfo then
      return (itemInfo).itemLink
    end
  end
  return (self.singleLink or self.singleText) or "?"
end

---@class BomNumbersPerExpansion
---@field classic number[]|nil
---@field onlyClassic number[]|nil
---@field tbc number[]|nil
---@field onlyTbc number[]|nil
---@field wotlk number[]|nil
---@field onlyWotlk number[]|nil
---@field cataclysm number[]|nil
---@field onlyCataclysm number[]|nil

---Construct a joined list of number for Classic, TBC, WotLK and Cataclysm based on version detected
---If any of the "onlyXXX" keys are present, those will be returned without any extra merging of other expansion data
---@param conditions BomNumbersPerExpansion
---@return number[]
function buffDefModule:PerExpansionChoice(conditions)
  if envModule.isClassic and conditions.onlyClassic then
    return conditions.onlyClassic
  elseif envModule.isTBC and conditions.onlyTbc then
    return conditions.onlyTbc
  elseif envModule.isWotLK and conditions.onlyWotlk then
    return conditions.onlyWotlk
  elseif envModule.isCata and conditions.onlyCataclysm then
    return conditions.onlyCataclysm
  end

  local result = {}
  for _, val in ipairs(conditions.classic or {}) do
    table.insert(result, val)
  end

  if envModule.haveTBC then
    for _, val in ipairs(conditions.tbc or {}) do
      table.insert(result, val)
    end
  end

  if envModule.haveWotLK then
    for _, val in ipairs(conditions.wotlk or {}) do
      table.insert(result, val)
    end
  end

  if envModule.haveCata then
    for _, val in ipairs(conditions.cataclysm or {}) do
      table.insert(result, val)
    end
  end

  return result
end

function buffDefClass:ShowItemsProvidingBuff()
  BuffomatAddon:Print(buffomatModule:Color("0070dd",
    string.format(_t("Items, which provide buff for %s:"), self.consumeGroupTitle)))

  local output = ""

  for _, itemId in ipairs(self.items or {}) do
    local info = BuffomatAddon.GetItemInfo(itemId)
    if info then
      output = output .. (info).itemLink .. " "
    end
  end

  BuffomatAddon:Print(output)
end

---Creates text for spell list dialog for this buff, if the text is not available, queries the server
---and applies the callback when its available.
---@param textReadyFn fun(text: string)
function buffDefClass:SetSpellListText(textReadyFn)
  -- Having 'consumeGroupTitle' set will override buff single text from the iteminfo
  if self.consumeGroupTitle then
    local text = self.consumeGroupTitle
    if self.extraText then
      text = text .. ": " .. buffomatModule:Color("bbbbee", self.extraText)
    end
    textReadyFn(text)
  else
    -- Await for an async request
    local buff = self
    self:GetSingleText(
      function(buffLabelText)
        if buff.type == "weapon" then
          buffLabelText = buffLabelText .. ": " .. buffomatModule:Color("bbbbee", _t("TooltipIncludesAllRanks"))
        elseif buff.extraText then
          buffLabelText = buffLabelText .. ": " .. buffomatModule:Color("bbbbee", buff.extraText)
        end
        textReadyFn(buffLabelText)
      end
    ) -- update when spell loaded
  end
end
---@class KvSharedEnvModule
---@field isClassic boolean
---@field isTBC boolean
---@field haveTBC boolean
---@field isWotLK boolean
---@field haveWotLK boolean
---@field isCata boolean
---@field haveCata boolean
---@field usesTrackingSettings boolean
---@field playerClass ClassName

local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local C_AddOns = _G["C_AddOns"]
local C_Container = _G["C_Container"]
local C_Item = _G["C_Item"]
local C_Minimap = _G["C_Minimap"]
local C_Spell = _G["C_Spell"]
local C_SpellBook = _G["C_SpellBook"]
local C_UnitAuras = _G["C_UnitAuras"]
local issecretvalue = _G["issecretvalue"]

-- local _, _, _, tocversion = GetBuildInfo()
envModule.isMistsOfPandaria = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
envModule.haveMistsOfPandaria = envModule.isMistsOfPandaria

envModule.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
envModule.haveCata = envModule.isCata

envModule.isWotLK = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
envModule.haveWotLK = envModule.isWotLK or envModule.isCata

envModule.isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
envModule.haveTBC = envModule.isWotLK or envModule.isTBC or envModule.isCata

envModule.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC

-- Select APIs by capability, not expansion: Forever has Classic content but a
-- Mainline API. Keep legacy return shapes where existing callers expect them.
---@param value any
---@return boolean
function envModule.IsSecretValue(value)
  return issecretvalue ~= nil and issecretvalue(value)
end

---@type fun(addon: string|number, field: string): string?
envModule.GetAddOnMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata or GetAddonMetadata
envModule.GetAddonMetadata = envModule.GetAddOnMetadata -- Compatibility with existing KvLib callers.

---Modern clients moved macro limits into Constants.MacroConsts.
---Read on demand so optional UI loading cannot leave cached nil limits.
---@return number? accountLimit
---@return number? characterLimit
function envModule.GetMacroLimits()
  local macroConsts = Constants and Constants.MacroConsts
  return (macroConsts and macroConsts.MAX_ACCOUNT_MACROS) or MAX_ACCOUNT_MACROS,
      (macroConsts and macroConsts.MAX_CHARACTER_MACROS) or MAX_CHARACTER_MACROS
end

-- C_Item.GetItemInfo keeps the legacy tuple, including trailing nils.
---@type fun(item: number|string): string?, string?, number?, number?, number?, string?, string?, number?, string?, number|string|nil, number?, number?, number?, number?, number?, number?, boolean?
envModule.GetItemInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
---@type fun(spell: number|string): {name: string, cost: number, type: number}[]?
envModule.GetSpellPowerCost = (C_Spell and C_Spell.GetSpellPowerCost) or GetSpellPowerCost

local legacyGetSpellInfo = GetSpellInfo
local getSpellInfo = C_Spell and C_Spell.GetSpellInfo
local getSpellSubtext = (C_Spell and C_Spell.GetSpellSubtext) or GetSpellSubtext

---@param spell number|string|nil Spell ID, name, or link (not a spellbook slot).
---@return string? rank
function envModule.GetSpellSubtext(spell)
  if spell == nil then
    return nil
  end
  if getSpellSubtext then
    return getSpellSubtext(spell)
  elseif legacyGetSpellInfo then
    local _, rank = legacyGetSpellInfo(spell)
    return rank
  end
end

---Unpack modern spell info and obtain the rank separately for Classic macros.
---@param spell number|string|nil Spell ID, name, or link (not a spellbook slot).
---@return string? name
---@return string? rank
---@return number|string? icon
---@return number? castTime
---@return number? minRange
---@return number? maxRange
---@return number? spellID
---@return number|string? originalIcon
function envModule.GetSpellInfo(spell)
  -- Optional spell references can be absent; C_Spell rejects nil identifiers.
  if spell == nil then
    return nil
  end
  if getSpellInfo then
    local info = getSpellInfo(spell)
    if info == nil then
      return nil
    end
    return info.name, envModule.GetSpellSubtext(spell), info.iconID, info.castTime,
        info.minRange, info.maxRange, info.spellID, info.originalIconID
  elseif legacyGetSpellInfo then
    return legacyGetSpellInfo(spell)
  end
end

local getSpellCooldown = C_Spell and C_Spell.GetSpellCooldown
local legacyGetSpellCooldown = GetSpellCooldown

---Return nil for unavailable/restricted data; never compare secret cooldowns.
---@param spell number|string
---@return number? startTime
---@return number? duration
---@return number? enabled Legacy 0/1 value.
---@return number? modRate
function envModule.GetSpellCooldown(spell)
  if getSpellCooldown then
    local info = getSpellCooldown(spell)
    if info == nil or envModule.IsSecretValue(info.startTime)
        or envModule.IsSecretValue(info.duration) or envModule.IsSecretValue(info.isEnabled)
        or envModule.IsSecretValue(info.modRate) then
      return nil
    end
    return info.startTime, info.duration, info.isEnabled and 1 or 0, info.modRate
  elseif legacyGetSpellCooldown then
    return legacyGetSpellCooldown(spell)
  end
end

local isSpellInRange = C_Spell and C_Spell.IsSpellInRange
local legacyIsSpellInRange = IsSpellInRange

---Preserve the legacy 1/0/nil contract used by the target-selection code.
---@param spell number|string
---@param unit string?
---@return number? inRange Unknown or restricted range returns nil.
function envModule.IsSpellInRange(spell, unit)
  if isSpellInRange then
    local inRange = isSpellInRange(spell, unit)
    if envModule.IsSecretValue(inRange) or inRange == nil then
      return nil
    end
    return inRange and 1 or 0
  elseif legacyIsSpellInRange then
    return legacyIsSpellInRange(spell, unit)
  end
end

local isSpellKnown = C_SpellBook and C_SpellBook.IsSpellKnown
local spellBanks = Enum and Enum.SpellBookSpellBank
local legacyIsSpellKnown = IsSpellKnown

---Translate the legacy pet boolean into the modern spell-bank enum.
---@param spellID number
---@param isPet boolean?
---@return boolean
function envModule.IsSpellKnown(spellID, isPet)
  if isSpellKnown and spellBanks then
    local known = isSpellKnown(spellID, isPet and spellBanks.Pet or spellBanks.Player)
    if envModule.IsSecretValue(known) then
      return false
    end
    return known
  elseif legacyIsSpellKnown then
    return legacyIsSpellKnown(spellID, isPet)
  end
  return false
end

---@type fun(bag: number): number
envModule.GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
---@type fun(bag: number, slot: number): number, number, number
envModule.GetContainerItemCooldown = (C_Container and C_Container.GetContainerItemCooldown) or GetContainerItemCooldown
local getContainerItemInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo

---@class KvContainerItemInfo
---@field iconFileID number|string
---@field stackCount number
---@field isLocked boolean
---@field quality number?
---@field isReadable boolean
---@field hasLoot boolean
---@field hyperlink string
---@field isFiltered boolean
---@field hasNoValue boolean
---@field itemID number
---@field isBound boolean?

---The inventory cache consumes the modern table, even on tuple-returning clients.
---@param bag number
---@param slot number
---@return KvContainerItemInfo? info
function envModule.GetContainerItemInfo(bag, slot)
  local icon, count, locked, quality, readable, lootable, link, filtered, noValue, itemID, bound =
      getContainerItemInfo(bag, slot)
  if icon == nil or type(icon) == "table" then
    return icon
  end
  return {
    iconFileID = icon, stackCount = count, isLocked = locked, quality = quality,
    isReadable = readable, hasLoot = lootable, hyperlink = link, isFiltered = filtered,
    hasNoValue = noValue, itemID = itemID, isBound = bound,
  }
end

---@type fun(): number
envModule.GetNumTrackingTypes = (C_Minimap and C_Minimap.GetNumTrackingTypes) or GetNumTrackingTypes
---@type fun(index: number, enabled: boolean)
envModule.SetTracking = (C_Minimap and C_Minimap.SetTracking) or SetTracking
---@type fun(): number|string|nil
envModule.GetTrackingTexture = GetTrackingTexture
local getTrackingInfo = (C_Minimap and C_Minimap.GetTrackingInfo) or GetTrackingInfo
envModule.usesTrackingSettings = (envModule.haveTBC or GetTrackingTexture == nil)
    and envModule.GetNumTrackingTypes ~= nil and getTrackingInfo ~= nil and envModule.SetTracking ~= nil

---Normalize both the Mainline tracking table and Classic tracking tuples.
---@param index number
---@return string? name
---@return number|string? texture
---@return boolean? active
---@return string? category
---@return number? nesting
---@return number? spellID
function envModule.GetTrackingInfo(index)
  local info, texture, active, category, nesting, spellID = getTrackingInfo(index)
  if type(info) == "table" then
    return info.name, info.texture, info.active, info.type, info.subType, info.spellID
  end
  return info, texture, active, category, nesting, spellID
end

---@class BomUnitAuraResult
---@field name string
---@field icon number|string
---@field count number
---@field debuffType string?
---@field duration number
---@field expirationTime number
---@field source string?
---@field isStealable boolean?
---@field nameplateShowPersonal boolean?
---@field spellId number
---@field canApplyAura boolean?
---@field isBossDebuff boolean?
---@field castByPlayer boolean?
---@field nameplateShowAll boolean?
---@field timeMod number?

local getAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local legacyUnitAura = UnitAura

---Read only public aura data outside combat, preserving Buffomat's field names.
---A missing aura ends enumeration; unreadable data must not imply missing buffs.
---@param unit string
---@param index number
---@param filter string?
---@return BomUnitAuraResult? aura
---@return boolean readable False for combat, missing API, or secret aura fields.
function envModule.GetUnitAura(unit, index, filter)
  if InCombatLockdown() then
    return nil, false
  end

  local aura ---@type BomUnitAuraResult
  if getAuraDataByIndex then
    local data = getAuraDataByIndex(unit, index, filter)
    if envModule.IsSecretValue(data) then
      return nil, false
    elseif data == nil then
      return nil, true
    end
    aura = {
      name = data.name, icon = data.icon, count = data.applications,
      debuffType = data.dispelName, duration = data.duration, expirationTime = data.expirationTime,
      source = data.sourceUnit, isStealable = data.isStealable, nameplateShowPersonal = data.nameplateShowPersonal,
      spellId = data.spellId, canApplyAura = data.canApplyAura, isBossDebuff = data.isBossAura,
      castByPlayer = data.isFromPlayerOrPlayerPet, nameplateShowAll = data.nameplateShowAll, timeMod = data.timeMod,
    }
  elseif legacyUnitAura then
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable,
        nameplateShowPersonal, spellId, canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod =
        legacyUnitAura(unit, index, filter)
    if envModule.IsSecretValue(name) then
      return nil, false
    elseif name == nil then
      return nil, true
    end
    aura = {
      name = name, icon = icon, count = count, debuffType = debuffType, duration = duration,
      expirationTime = expirationTime, source = source, isStealable = isStealable,
      nameplateShowPersonal = nameplateShowPersonal, spellId = spellId, canApplyAura = canApplyAura,
      isBossDebuff = isBossDebuff, castByPlayer = castByPlayer, nameplateShowAll = nameplateShowAll, timeMod = timeMod,
    }
  else
    return nil, false
  end

  -- Consumers use these values as keys, conditions, and arithmetic operands.
  for _, value in pairs(aura) do
    if envModule.IsSecretValue(value) then
      return nil, false
    end
  end
  return aura, true
end

envModule.playerClass = select(2, UnitClass("player"))

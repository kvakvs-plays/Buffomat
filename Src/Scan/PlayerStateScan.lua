local addonName, ns = ...

-- The reader for the player's own state: what decides whether Buffomat is active
-- (mounted, resting, dead, in an instance...), the shapeshift form, tracking, mana,
-- and the equipped weapons with their temporary enchants.

---@alias BomCastingState "cast"|"channel"|nil

---@class PlayerStateScanModule
---@field version number Changes when a read found something different
---@field casting BomCastingState Set by the cast events, not by a read
---@field mana number Current mana; maximum mana when the client hides it
---@field maxMana number 0 when the client hides it
---@field manaWakeLimit number? Mana at which a task that was too expensive becomes affordable; nil when nothing waits
---@field level number? Character level
---@field isDead boolean
---@field isMounted boolean
---@field isFlying boolean
---@field isOnTaxi boolean
---@field isInVehicle boolean
---@field isResting boolean
---@field isStealthed boolean
---@field isOutdoors boolean
---@field isPvP boolean Flagged for PvP
---@field formId number? Shapeshift form constant; nil in no form
---@field form number Shapeshift form index on the stance bar; 0 in no form
---@field instanceType KvInstanceType
---@field instanceId number? Continent or instance map id
---@field hasPet boolean
---@field petCreatureTypeId number?
---@field petCreatureFamilyId number?
---@field activeTracking table<WowSpellId, boolean> Active tracking spells, on clients with tracking settings
---@field trackingSignature number Checksum of the active tracking spells
---@field trackingTexture number|string|nil Active tracking icon, on clients with one tracking at a time
---@field weaponUnavailable boolean The client hid the weapon enchants; nothing may be concluded about them
---@field hasMainhandEnchant boolean Any temporary enchant, also one Buffomat does not know
---@field hasOffhandEnchant boolean
---@field mainhandBuffId BomBuffId? Buff definition of the main hand enchant, when Buffomat knows it
---@field offhandBuffId BomBuffId?
---@field enchantExpiresAt number? Earliest end of a temporary enchant, GetTime() based
---@field inventory table<number, WowItemId> Item ids of the equipment slots Buffomat looks at
---@field inventoryLinks table<number, string> Their links
local module = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]

local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]

module.SLOT_MAINHAND = 16
module.SLOT_OFFHAND = 17
module.SLOT_TRINKET1 = 13
module.SLOT_TRINKET2 = 14
local EQUIPMENT_SLOTS = { module.SLOT_TRINKET1, module.SLOT_TRINKET2, module.SLOT_MAINHAND, module.SLOT_OFFHAND }

module.version = 0
module.mana = 0
module.maxMana = 0
module.form = 0
module.instanceType = "none"
module.activeTracking = {}
module.trackingSignature = 0
module.weaponUnavailable = false
module.hasMainhandEnchant = false
module.hasOffhandEnchant = false
module.inventory = {}
module.inventoryLinks = {}

local changed = false -- set by `set` during a read

---@param key string Field of the module
---@param value any
local function set(key, value)
  if module[key] ~= value then
    module[key] = value
    changed = true
  end
end

-- Shapeshift form ids of the druid flight forms: swift flight form and flight form
local FLIGHT_FORMS = { [27] = true, [29] = true }

---@return number mana Current mana
---@return number maxMana 0 when the client hides it
local function readMana()
  -- Forever can hide the player's power. Falling back to 0 made every spell too
  -- expensive; assume full mana instead and let the client reject a cast.
  local maxMana = envModule.UnitPowerMax("player", 0)
  return envModule.UnitPower("player", 0) or maxMana or math.huge, maxMana or 0
end

---Mana regenerates without an event the scan listens to, so every evaluation reads it
---first. This is not a change which asks for an evaluation: only a task which waits for
---mana cares, and that one watches the power events.
function module:ReadMana()
  self.mana, self.maxMana = readMana()
end

---Whether the player may take off or land at any moment. Neither sends an event.
---@return boolean
function module:CanTakeOff()
  return envModule.haveTBC == true
      and (self.isMounted or self.isFlying or FLIGHT_FORMS[self.formId or 0] == true)
end

---Read the player's state.
---@return boolean changed
function module:Read()
  changed = false
  local mana, maxMana = readMana()
  set("maxMana", maxMana)
  set("mana", mana)

  set("level", kvUnitModule.GetLevel("player"))
  set("isDead", kvPlayerModule.IsDeadOrGhost())
  set("isMounted", kvPlayerModule.IsMounted())
  set("isFlying", kvPlayerModule.IsFlying())
  set("isOnTaxi", kvPlayerModule.IsOnTaxi())
  set("isInVehicle", kvPlayerModule.IsInVehicle())
  set("isResting", kvPlayerModule.IsResting())
  set("isStealthed", kvPlayerModule.IsStealthed())
  set("isOutdoors", kvPlayerModule.IsOutdoors())
  set("isPvP", kvUnitModule.IsPVP("player"))
  set("formId", kvPlayerModule.GetShapeshiftFormID())
  set("form", kvPlayerModule.GetShapeshiftForm())
  set("instanceType", kvPlayerModule.GetInstanceType())
  set("instanceId", kvPlayerModule.GetInstanceId())

  local hasPet = kvUnitModule.Exists("pet")
  set("hasPet", hasPet)
  set("petCreatureTypeId", hasPet and kvUnitModule.GetCreatureTypeId("pet") or nil)
  set("petCreatureFamilyId", hasPet and kvUnitModule.GetCreatureFamilyId("pet") or nil)

  if envModule.usesTrackingSettings then
    local signature = 0
    wipe(self.activeTracking)
    for index = 1, envModule.GetNumTrackingTypes() do
      local _name, _texture, active, _category, _nesting, spellId = envModule.GetTrackingInfo(index)
      if active and spellId then
        self.activeTracking[spellId] = true
        signature = signature + spellId
      end
    end
    set("trackingSignature", signature)
  else
    set("trackingTexture", envModule.GetTrackingTexture and envModule.GetTrackingTexture() or nil)
  end

  if changed then
    self.version = self.version + 1
  end
  return changed
end

---@param hasEnchant boolean?
---@param enchantId number?
---@return BomBuffId? buffId Nil for no enchant or one Buffomat does not know
local function enchantBuffId(hasEnchant, enchantId)
  if hasEnchant and enchantId then
    return allBuffsModule.enchantToSpellLookup[enchantId]
  end
  return nil
end

---Read the equipped weapons, trinkets and temporary weapon enchants, and note the
---enchants on the player's unit, where the buff checks look for them.
---@param player BomUnit
---@return boolean changed
function module:ReadEquipment(player)
  changed = false
  for _, slot in ipairs(EQUIPMENT_SLOTS) do
    local itemId = kvPlayerModule.GetInventoryItemID(slot)
    if self.inventory[slot] ~= itemId then
      self.inventory[slot] = itemId
      self.inventoryLinks[slot] = itemId and kvPlayerModule.GetInventoryItemLink(slot) or nil
      changed = true
    end
  end

  local hasMainhand, mainhandTimeLeft, _mainhandCharges, mainhandEnchantId,
  hasOffhand, offhandTimeLeft, _offhandCharges, offhandEnchantId = envModule.GetWeaponEnchantInfo()
  if hasMainhand == nil or hasOffhand == nil then
    -- Unreadable is not the same as no enchant: no weapon buff may be offered from it
    set("weaponUnavailable", true)
    set("hasMainhandEnchant", false)
    set("hasOffhandEnchant", false)
    set("mainhandBuffId", nil)
    set("offhandBuffId", nil)
    self.enchantExpiresAt = nil
  else
    set("weaponUnavailable", false)
    set("hasMainhandEnchant", hasMainhand == true)
    set("hasOffhandEnchant", hasOffhand == true)
    set("mainhandBuffId", enchantBuffId(hasMainhand, mainhandEnchantId))
    set("offhandBuffId", enchantBuffId(hasOffhand, offhandEnchantId))
    -- Time left is in milliseconds
    local timeLeft
    if hasMainhand and mainhandTimeLeft then
      timeLeft = mainhandTimeLeft
    end
    if hasOffhand and offhandTimeLeft and (timeLeft == nil or offhandTimeLeft < timeLeft) then
      timeLeft = offhandTimeLeft
    end
    self.enchantExpiresAt = timeLeft and (GetTime() + timeLeft / 1000) or nil
  end

  self:ApplyEquipment(player)
  if changed then
    self.version = self.version + 1
  end
  return changed
end

---Copy the weapon enchant state to the player's unit.
---@param player BomUnit
function module:ApplyEquipment(player)
  player.weaponDataUnavailable = self.weaponUnavailable
  player.mainhandEnchantment = self.mainhandBuffId
  player.offhandEnchantment = self.offhandBuffId
end

---Whether a tracking spell is active now.
---@param buffDef BomBuffDefinition A tracking buff
---@return boolean
function module:IsTrackingActive(buffDef)
  if envModule.usesTrackingSettings then
    for _, spellId in ipairs(buffDef.singleFamily) do
      if self.activeTracking[spellId] then
        return true
      end
    end
    return false
  end
  return envModule.GetTrackingTexture ~= nil and self.trackingTexture == buffDef.trackingIconId
end

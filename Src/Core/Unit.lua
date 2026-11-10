local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class UnitModule
local module = LibStub("Buffomat-Unit") --[[@as UnitModule]]

local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffModule = LibStub("Buffomat-Buff") --[[@as BuffModule]]

---@alias BomBuffidBuffLookup {[BomBuffId]: BomUnitBuff}

---@class BomUnit
---@field allBuffs table<number, boolean> Availability of all auras even those not supported by BOM, by id, no extra detail stored
---@field auraDataUnavailable boolean? Prevent decisions from an incomplete aura scan.
---@field weaponDataUnavailable boolean? Player weapon enchants could not be read; skip weapon buff decisions.
---@field class ClassName
---@field distance number
---@field group number Raid group number (9 if temporary moved out of the raid by BOM)
---@field guid string? Identity of the character behind the unit id
---@field auraSignature number? Checksum of the last aura read, to tell a real change from a repeated event
---@field hasReputationTrinket boolean Has AD reputation trinket equipped
---@field hasRidingTrinket boolean Has carrot riding trinket equipped
---@field hasResurrection boolean Was recently resurrected
---@field isConnected boolean Is online
---@field isDrinking boolean? Has a drinking buff
---@field isDead boolean Is this member dead
---@field isGhost boolean Is dead and corpse released
---@field isPlayer boolean Is this a player
---@field isSameZone boolean Is in the same zone
---@field isTank boolean Is this member marked as tank
---@field knownBuffs BomBuffidBuffLookup Buffs on player keyed by spell id, only buffs supported by Buffomat are stored
---@field link string
---@field mainhandEnchantment BomBuffId|nil Temporary enchant on main hand
---@field name string
---@field NeedBuff boolean
---@field offhandEnchantment BomBuffId|nil Temporary enchant on off-hand
---@field owner BomUnit|nil Owner for pet
---@field unitId string
local unitClass = {}
unitClass.__index = unitClass

---@return BomUnit
function module:New(fields)
  fields = fields or {}
  setmetatable(fields, unitClass)
  return fields
end

function unitClass:GetDistance()
  return self.distance
end

---@param id WowSpellId
function unitClass:HaveBuff(id)
  return self.knownBuffs[id] ~= nil or self.allBuffs[id] ~= nil
end

function unitClass:GetText()
  return self.link or self.name
end

function unitClass:ClearMainhandBuff()
  self.mainhandEnchantment = nil
end

---@param enchantmentId BomEnchantmentId
---@param expiration number
function unitClass:SetMainhandBuff(enchantmentId, expiration)
  local enchantBuffId = allBuffsModule.enchantToSpellLookup[enchantmentId]
  local duration

  if allBuffsModule.buffFromSpellIdLookup[enchantBuffId]
      and allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  then
    duration = allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  else
    duration = 300
  end

  self.knownBuffs[enchantBuffId] = buffModule:New(
    enchantBuffId,
    duration,
    GetTime() + expiration / 1000,
    "player",
    true)
  self.mainhandEnchantment = enchantBuffId
end

function unitClass:ClearOffhandBuff()
  self.offhandEnchantment = nil
end

---@param enchantmentId BomEnchantmentId
---@param expiration number
function unitClass:SetOffhandBuff(enchantmentId, expiration)
  local enchantBuffId = allBuffsModule.enchantToSpellLookup[enchantmentId]
  local duration

  if allBuffsModule.buffFromSpellIdLookup[enchantBuffId]
      and allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  then
    duration = allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  else
    duration = 300
  end

  self.knownBuffs[-enchantBuffId] = buffModule:New(
    -enchantBuffId,
    duration,
    GetTime() + expiration / 1000,
    "player",
    true)

  self.offhandEnchantment = enchantBuffId
end

function unitClass:UpdatePlayerWeaponEnchantments()
  ---@type boolean, number, number, BomEnchantmentId, boolean, number, number, BomEnchantmentId
  local hasMainHandEnchant, mainHandExpiration, _mainHandCharges, mainHandEnchantID
  , hasOffHandEnchant, offHandExpiration, _offHandCharges, offHandEnchantId = envModule.GetWeaponEnchantInfo()

  if hasMainHandEnchant == nil or hasOffHandEnchant == nil then
    self.auraDataUnavailable = true
    self.weaponDataUnavailable = true
    self.NeedBuff = false
    return self
  end
  self.weaponDataUnavailable = false

  if hasMainHandEnchant and mainHandEnchantID
      and allBuffsModule.enchantToSpellLookup[mainHandEnchantID] then
    self:SetMainhandBuff(mainHandEnchantID, mainHandExpiration)
  else
    self:ClearMainhandBuff()
  end

  if hasOffHandEnchant
      and offHandEnchantId
      and allBuffsModule.enchantToSpellLookup[offHandEnchantId] then
    self:SetOffhandBuff(offHandEnchantId, offHandExpiration)
  else
    self:ClearOffhandBuff()
  end

  return self
end

-- A group member, the player, or a pet, as the scan sees it. The fields are filled by
-- the readers in Src/Scan: identity and status by RosterScan, buffs by AuraScan, weapon
-- enchants by PlayerStateScan, distance by RangeScan.

---@class UnitModule
local module = LibStub("Buffomat-Unit") --[[@as UnitModule]]

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

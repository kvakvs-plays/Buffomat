local addonName, ns = ...

-- Unit, group and aura queries with one contract on every supported client.
-- Forever can return secret values from most unit APIs; every function here either
-- returns a plain value or reports that the value is unreadable. Callers never
-- need to test for secrets themselves.

---@class KvUnitModule
---@field TOO_FAR number Squared distance reported for a unit on another map
---@field UNKNOWN_DISTANCE number Squared distance reported when no range probe answered
local module = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

local C_Map = _G["C_Map"]
local C_UnitAuras = _G["C_UnitAuras"]
local isSecret = envModule.IsSecretValue

-- Larger than any real squared distance, so "nearest" comparisons ignore it
module.TOO_FAR = 1000011
module.UNKNOWN_DISTANCE = 10000

local unitFullName, unitGUID, unitExists = UnitFullName, UnitGUID, UnitExists
local getPlayerInfoByGUID = GetPlayerInfoByGUID

---@param unit string
---@return string? name Nil when the unit does not exist or the name is unreadable
---@return string? realm Nil for the player's own realm
---@return boolean unreadable True when the client hides the name
function module.GetName(unit)
  local name, realm = unitFullName(unit)
  if isSecret(name) or isSecret(realm) then
    return nil, nil, true
  end
  if realm == "" then
    realm = nil
  end
  return name, realm, false
end

---@param unit string
---@return string? guid
---@return boolean unreadable True when the client hides the GUID
function module.GetGUID(unit)
  local guid = unitGUID(unit)
  if isSecret(guid) then
    return nil, true
  end
  return guid, false
end

---Class of a player character. Pets and other creatures have no player class.
---@param guid string?
---@return ClassName? class Class token such as "PRIEST"
function module.GetPlayerClass(guid)
  if guid == nil or not getPlayerInfoByGUID then
    return nil
  end
  local _, class = getPlayerInfoByGUID(guid)
  if isSecret(class) then
    return nil
  end
  return class
end

---@param value any
---@return boolean True only for a readable true value
local function plainTrue(value)
  return not isSecret(value) and (value == true or value == 1)
end

---@param unit string
---@return boolean
function module.Exists(unit)
  return plainTrue(unitExists(unit))
end

local unitIsDeadOrGhost, unitIsGhost, unitIsFeignDeath = UnitIsDeadOrGhost, UnitIsGhost, UnitIsFeignDeath
local unitIsConnected = UnitIsConnected

---Dead or a ghost, and not a hunter feigning death.
---@param unit string
---@return boolean
function module.IsDead(unit)
  if not plainTrue(unitIsDeadOrGhost(unit)) then
    return false
  end
  return not (unitIsFeignDeath and plainTrue(unitIsFeignDeath(unit)))
end

---@param unit string
---@return boolean
function module.IsGhost(unit)
  return plainTrue(unitIsGhost(unit))
end

---An unreadable connection state counts as connected: the unit is then skipped for
---other reasons, and "offline" would hide it for good.
---@param unit string
---@return boolean
function module.IsConnected(unit)
  local connected = unitIsConnected(unit)
  if isSecret(connected) then
    return true
  end
  return connected == true or connected == 1
end

local unitHasIncomingResurrection = _G["UnitHasIncomingResurrection"]

---@param unit string
---@return boolean
function module.HasIncomingResurrection(unit)
  return unitHasIncomingResurrection ~= nil and plainTrue(unitHasIncomingResurrection(unit))
end

---@param unit string
---@return number? mapId Nil when unknown or unreadable
function module.GetMapId(unit)
  if not (C_Map and C_Map.GetBestMapForUnit) then
    return nil
  end
  local mapId = C_Map.GetBestMapForUnit(unit)
  if isSecret(mapId) then
    return nil
  end
  return mapId
end

local unitGroupRolesAssigned = _G["UnitGroupRolesAssigned"]

---Role from the dungeon finder or specialization, where the client has it.
---@param unit string
---@return boolean
function module.HasTankRole(unit)
  if not unitGroupRolesAssigned then
    return false
  end
  local role = unitGroupRolesAssigned(unit)
  return not isSecret(role) and role == "TANK"
end

local unitIsPVP, unitLevel = UnitIsPVP, UnitLevel

---@param unit string
---@return boolean
function module.IsPVP(unit)
  return plainTrue(unitIsPVP(unit))
end

---@param unit string
---@return number? level Nil when unreadable
function module.GetLevel(unit)
  local level = unitLevel(unit)
  if isSecret(level) then
    return nil
  end
  return level
end

local unitCreatureType, unitCreatureFamily = UnitCreatureType, UnitCreatureFamily

---@param unit string
---@return number? creatureTypeId Such as 3 for a demon
function module.GetCreatureTypeId(unit)
  local _, typeId = unitCreatureType(unit)
  if isSecret(typeId) then
    return nil
  end
  return typeId
end

---@param unit string
---@return number? creatureFamilyId
function module.GetCreatureFamilyId(unit)
  local _, familyId = unitCreatureFamily(unit)
  if isSecret(familyId) then
    return nil
  end
  return familyId
end

local isInRaid, isInGroup = IsInRaid, IsInGroup
local getNumGroupMembers = _G["GetNumGroupMembers"]
local getRaidRosterInfo = GetRaidRosterInfo

---@return boolean
function module.IsInRaid()
  return plainTrue(isInRaid())
end

---@return boolean In a party or a raid
function module.IsInGroup()
  return plainTrue(isInGroup())
end

---@return number count Raid members including the player; 0 outside a raid
function module.GetNumRaidMembers()
  if not module.IsInRaid() then
    return 0
  end
  local count = getNumGroupMembers and getNumGroupMembers() or 40
  if isSecret(count) then
    return 40
  end
  return count
end

---@alias KvRaidRole "MAINTANK"|"MAINASSIST"|"NONE"|"TANK"|"HEALER"|"DAMAGER"

---One raid slot. The role prefers the raid leader's main tank / main assist mark,
---then the specialization role, so a tank marked by the leader is a tank whatever
---their specialization says.
---@param raidIndex number 1 to 40; the unit is "raid" .. raidIndex
---@return number? subgroup Nil for an empty or unreadable slot
---@return KvRaidRole? role
function module.GetRaidSlot(raidIndex)
  local name, _rank, subgroup, _level, _class, _fileName, _zone, _online, _isDead, role, _isML, combatRole =
      getRaidRosterInfo(raidIndex)
  if name == nil or isSecret(name) or isSecret(subgroup) or isSecret(role) or isSecret(combatRole) then
    return nil
  end
  if role == "MAINTANK" or role == "MAINASSIST" then
    return subgroup, role
  elseif combatRole == "TANK" or combatRole == "HEALER" or combatRole == "DAMAGER" then
    return subgroup, combatRole
  end
  return subgroup, role or "NONE"
end

local unitIsPlayer, unitIsOtherPlayersPet = UnitIsPlayer, UnitIsOtherPlayersPet
local unitInParty, unitInRaid, unitCanCooperate = UnitInParty, UnitInRaid, UnitCanCooperate

---A player or another player's pet outside the group which the player could buff.
---@param unit string
---@return boolean
function module.IsBuffableOutsider(unit)
  if not module.Exists(unit) then
    return false
  end
  if not (plainTrue(unitIsPlayer(unit)) or plainTrue(unitIsOtherPlayersPet(unit))) then
    return false
  end
  if plainTrue(unitInParty(unit)) or plainTrue(unitInRaid(unit)) then
    return false
  end
  return plainTrue(unitCanCooperate("player", unit))
end

local getAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local legacyUnitAura = _G["UnitAura"]

---Read one aura as plain values, without building a table. Does not check combat or
---addon restrictions: the caller must have checked once before a batch of reads.
---The list ends when `spellId` is nil and `readable` is true.
---@param unit string
---@param index number
---@param filter string Such as "HELPFUL"
---@return number? spellId
---@return string? name
---@return number? duration
---@return number? expirationTime
---@return string? source Unit which applied the aura
---@return boolean readable False when the API is missing or any value is secret
function module.ReadAura(unit, index, filter)
  local spellId, name, duration, expirationTime, source
  if getAuraDataByIndex then
    local data = getAuraDataByIndex(unit, index, filter)
    if isSecret(data) then
      return nil, nil, nil, nil, nil, false
    elseif data == nil then
      return nil, nil, nil, nil, nil, true
    end
    spellId, name, duration, expirationTime, source =
        data.spellId, data.name, data.duration, data.expirationTime, data.sourceUnit
  elseif legacyUnitAura then
    local _
    name, _, _, _, duration, expirationTime, source, _, _, spellId = legacyUnitAura(unit, index, filter)
    if isSecret(name) then
      return nil, nil, nil, nil, nil, false
    elseif name == nil then
      return nil, nil, nil, nil, nil, true
    end
  else
    return nil, nil, nil, nil, nil, false
  end
  if isSecret(spellId) or isSecret(name) or isSecret(duration) or isSecret(expirationTime) or isSecret(source) then
    return nil, nil, nil, nil, nil, false
  end
  return spellId, name, duration, expirationTime, source, true
end

---Whether a UNIT_AURA event can have changed the unit's buffs. Newer clients say what
---changed; an update which only added harmful auras is of no interest to a buff scan.
---Anything missing, unreadable or unexpected counts as a change.
---@param updateInfo table? Second payload value of UNIT_AURA
---@return boolean
function module.AuraUpdateTouchesBuffs(updateInfo)
  if isSecret(updateInfo) or type(updateInfo) ~= "table" then
    return true
  end
  local isFullUpdate = updateInfo.isFullUpdate
  if isSecret(isFullUpdate) or isFullUpdate ~= false then
    return true
  end
  -- Removed and updated auras are known only by instance id, which says nothing about their kind
  local removed, updated = updateInfo.removedAuraInstanceIDs, updateInfo.updatedAuraInstanceIDs
  if isSecret(removed) or isSecret(updated) or (removed ~= nil and next(removed) ~= nil)
      or (updated ~= nil and next(updated) ~= nil) then
    return true
  end
  local added = updateInfo.addedAuras
  if isSecret(added) then
    return true
  elseif added ~= nil then
    for _, aura in pairs(added) do
      if isSecret(aura) or type(aura) ~= "table" then
        return true
      end
      local isHarmful = aura.isHarmful
      if isSecret(isHarmful) or isHarmful ~= true then
        return true
      end
    end
  end
  return false
end

local unitDistanceSquared = _G["UnitDistanceSquared"]
local checkInteractDistance = _G["CheckInteractDistance"]

---The interact-distance probe is blocked in combat on newer clients, and scans only
---run outside combat; still never branch on an unreadable answer.
---@param unit string
---@param distIndex number
---@return boolean
local function inInteractDistance(unit, distIndex)
  return checkInteractDistance ~= nil and plainTrue(checkInteractDistance(unit, distIndex))
end

---Squared distance to a unit in yards. Exact where the client reports it; otherwise
---the nearest of a few item and interaction ranges the unit is inside.
---Partly after DBM-Core (Paul Emmerich, Martin Verges).
---@param unit string
---@return number distanceSquared `TOO_FAR` on another map, `UNKNOWN_DISTANCE` when no probe answered
function module.DistanceSquared(unit)
  if envModule.UnitIsUnit(unit, "player") then
    return 0
  end
  if unitDistanceSquared then
    local distanceSquared, checkedDistance = unitDistanceSquared(unit)
    if not isSecret(checkedDistance) and checkedDistance and not isSecret(distanceSquared) then
      return distanceSquared
    end
  end
  if module.GetMapId(unit) ~= module.GetMapId("player") then
    return module.TOO_FAR
  elseif envModule.IsItemInRange(8149, unit) then
    return 64 -- 8 yards, Voodoo Charm
  elseif inInteractDistance(unit, 3) then
    return 100 -- 10 yards
  elseif inInteractDistance(unit, 2) then
    return 121 -- 11 yards
  elseif envModule.IsItemInRange(14530, unit) then
    return 324 -- 18 yards, Heavy Runecloth Bandage (the tooltip says 15)
  elseif envModule.IsItemInRange(21519, unit) then
    return 529 -- 23 yards, Mistletoe (the tooltip says 20)
  elseif envModule.IsItemInRange(1180, unit) then
    return 1089 -- 33 yards, Scroll of Stamina
  elseif envModule.UnitInRange(unit) then
    return 1849 -- 43 yards
  end
  return module.UNKNOWN_DISTANCE
end

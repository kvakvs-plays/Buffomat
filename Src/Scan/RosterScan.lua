local addonName, ns = ...

-- The roster reader: who is in the group, in which subgroup and role, and whether they
-- are dead, offline or in another zone. Rebuilt only when the group changes. One
-- BomUnit object exists per unit id and is reused; identity is the GUID, so a unit's
-- aura snapshot is kept for as long as the same character stays behind that unit id.

---@class BomRoster
---@field version number Changes when the members, their groups, roles or status changed
---@field isRaid boolean
---@field units BomUnit[] Player, player pet, the player's subgroup, then everybody else
---@field byUnitId table<string, BomUnit>
---@field byName table<string, BomUnit> For per-name settings and display only; never the identity
---@field groups table<number, BomUnit[]> Raid subgroup 1..8; a party and a lone player are group 1
---@field player BomUnit
---@field playerPet BomUnit?
---@field target BomUnit? Targeted player outside the group, with the BuffTarget option
---@field incomplete boolean A member's name or GUID was unreadable; decisions would be made on a partial group
---@field hasDead boolean A member is dead

---The old name of the roster, still used by the task builders.
---@alias BomParty BomRoster

---@class RosterScanModule
---@field roster BomRoster
---@field units table<string, BomUnit> One reused object per unit id
---@field playerOnly boolean? The roster was last built in aura-free mode
---@field builtWithBuffTarget boolean? Value of the BuffTarget option at the last build
local module = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]

local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local ngStringsModule = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]
local scanStatsModule = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]
local texturesModule = LibStub("Buffomat-Textures") --[[@as TexturesModule]]
local unitModule = LibStub("Buffomat-Unit") --[[@as UnitModule]]

module.units = {}
module.roster = {
  version = 0, isRaid = false, units = {}, byUnitId = {}, byName = {}, groups = {},
  incomplete = false, hasDead = false,
}
for group = 1, 8 do
  module.roster.groups[group] = {}
end

-- Unit ids are built once; a rebuild must not concatenate strings
local RAID_UNITS, PARTY_UNITS, PARTY_PET_UNITS = {}, {}, {}
for index = 1, 40 do
  RAID_UNITS[index] = "raid" .. index
end
for index = 1, 4 do
  PARTY_UNITS[index] = "party" .. index
  PARTY_PET_UNITS[index] = "partypet" .. index
end

local slotSubgroup, slotRole = {}, {} ---@type number[], KvRaidRole[] Scratch tables for one raid rebuild
local previousOrder = {} ---@type BomUnit[] Units of the previous build, to detect a real change
local changed = false -- set while filling units during a rebuild

---@param unit BomUnit
---@param isPet boolean
local function describeUnit(unit, isPet)
  local class = not isPet and kvUnitModule.GetPlayerClass(unit.guid) or nil
  if class then
    local color = constModule.CLASS_COLOR[class]
    unit.class = class
    unit.link = (constModule.CLASS_ICONS[class] or "") .. "|Hunit:" .. unit.guid .. ":" .. unit.name
        .. "|h|c" .. (color and color.colorStr or "ffffffff") .. unit.name .. "|r|h"
  else
    unit.class = "pet"
    unit.link = ngStringsModule:FormatTexture(texturesModule.ICON_PET) .. unit.name
  end
end

---Fill the reused unit object of a unit id and add it to the roster.
---@param unitId string
---@param group number
---@param role KvRaidRole?
---@param isPet boolean Pets of players are buffed as class "pet"
---@param pendingUnits BomScanDirtyUnits A unit with a new character behind it is read in this pass
---@return BomUnit? unit Nil when nobody is behind the unit id, or the client hides who it is
local function addUnit(unitId, group, role, isPet, pendingUnits)
  local roster = module.roster
  local name, realm, nameUnreadable = kvUnitModule.GetName(unitId)
  local guid, guidUnreadable = kvUnitModule.GetGUID(unitId)
  if nameUnreadable or guidUnreadable then
    roster.incomplete = true
    return nil
  end
  if name == nil then
    return nil
  end

  local unit = module.units[unitId]
  if unit == nil then
    unit = unitModule:New({ unitId = unitId, knownBuffs = {}, allBuffs = {}, distance = kvUnitModule.TOO_FAR })
    module.units[unitId] = unit
  end

  if unit.guid ~= guid or unit.name ~= name then
    -- Another character is behind this unit id now; nothing known about the old one applies
    unit.guid, unit.name = guid, name
    wipe(unit.knownBuffs)
    wipe(unit.allBuffs)
    unit.hasResurrection = false
    unit.isDead, unit.isGhost, unit.isConnected, unit.isSameZone = false, false, true, true
    unit.NeedBuff = false -- until the auras are read
    unit.auraSignature = nil
    describeUnit(unit, isPet)
    pendingUnits.auras[unitId] = true
    pendingUnits.status[unitId] = true
    changed = true
  elseif unit.class == "pet" and not isPet then
    describeUnit(unit, isPet) -- class data of a player can arrive after the first look
    changed = changed or unit.class ~= "pet"
  end

  local isTank = role == "MAINTANK" or role == "TANK" or kvUnitModule.HasTankRole(unitId)
  if unit.group ~= group or unit.isTank ~= isTank then
    unit.group, unit.isTank = group, isTank
    changed = true
  end
  unit.isPlayer = unitId == "player"
  unit.owner = nil

  roster.units[#roster.units + 1] = unit
  roster.byUnitId[unitId] = unit
  -- Two players from different realms can share a name; the second keeps the realm
  local key = name
  if roster.byName[key] ~= nil and realm then
    key = name .. "-" .. realm
  end
  roster.byName[key] = unit
  if roster.groups[group] then
    table.insert(roster.groups[group], unit)
  end
  return unit
end

---@param unitId string
---@param owner BomUnit?
---@param pendingUnits BomScanDirtyUnits
---@return BomUnit? pet
local function addPet(unitId, owner, pendingUnits)
  if owner == nil then
    return nil
  end
  local pet = addUnit(unitId, owner.group, nil, true, pendingUnits)
  if pet then
    pet.owner = owner
  end
  return pet
end

---The BuffTarget option decides whether the target is part of the roster, so the option
---changing means the roster has to be built again.
---@return boolean
function module:NeedsRebuild()
  return self.builtWithBuffTarget ~= (BuffomatShared.BuffTarget == true)
end

---Rebuild the roster from the group as it is now.
---@param pendingUnits BomScanDirtyUnits Units found to be new are added, to be read in the same pass
---@param playerOnly boolean Aura-free mode: other members' names can be secret, and nothing is read from them
function module:Rebuild(pendingUnits, playerOnly)
  scanStatsModule:Count("rosterBuilds")
  local roster = self.roster
  for index, unit in ipairs(roster.units) do
    previousOrder[index] = unit
  end
  for index = #roster.units + 1, #previousOrder do
    previousOrder[index] = nil
  end
  wipe(roster.units)
  wipe(roster.byUnitId)
  wipe(roster.byName)
  for group = 1, 8 do
    wipe(roster.groups[group])
  end
  roster.incomplete = false
  roster.playerPet, roster.target = nil, nil
  changed = self.playerOnly ~= playerOnly
  self.playerOnly = playerOnly
  self.builtWithBuffTarget = BuffomatShared.BuffTarget == true

  local raidSize = playerOnly and 0 or kvUnitModule.GetNumRaidMembers()
  local isRaid = raidSize > 0
  changed = changed or roster.isRaid ~= isRaid
  roster.isRaid = isRaid

  -- The player is always "player", also in a raid, where the raid slot only gives the subgroup
  local playerGroup, playerRole, playerSlot = 1, nil, nil
  if isRaid then
    for index = 1, raidSize do
      slotSubgroup[index], slotRole[index] = kvUnitModule.GetRaidSlot(index)
      if playerSlot == nil and slotSubgroup[index] and envModule.UnitIsUnit(RAID_UNITS[index], "player") then
        playerSlot, playerGroup, playerRole = index, slotSubgroup[index], slotRole[index]
      end
    end
  end
  roster.player = addUnit("player", playerGroup, playerRole, false, pendingUnits) or roster.player

  if not playerOnly then
    roster.playerPet = addPet("pet", roster.player, pendingUnits)

    if isRaid then
      -- The player's own subgroup first: it is read first when the read budget is short
      for index = 1, raidSize do
        if index ~= playerSlot and slotSubgroup[index] == playerGroup then
          addUnit(RAID_UNITS[index], slotSubgroup[index], slotRole[index], false, pendingUnits)
        end
      end
      for index = 1, raidSize do
        if index ~= playerSlot and slotSubgroup[index] ~= playerGroup then
          if slotSubgroup[index] then
            addUnit(RAID_UNITS[index], slotSubgroup[index], slotRole[index], false, pendingUnits)
          elseif kvUnitModule.Exists(RAID_UNITS[index]) then
            roster.incomplete = true -- somebody is there, but the client hides who
          end
        end
      end
    elseif kvUnitModule.IsInGroup() then
      for index = 1, 4 do
        local member = addUnit(PARTY_UNITS[index], 1, nil, false, pendingUnits)
        addPet(PARTY_PET_UNITS[index], member, pendingUnits)
      end
    end

    if BuffomatShared.BuffTarget and kvUnitModule.IsBuffableOutsider("target") then
      roster.target = addUnit("target", 1, nil, false, pendingUnits)
    end
  end

  if not changed then
    changed = #roster.units ~= #previousOrder
    for index = 1, #roster.units do
      changed = changed or roster.units[index] ~= previousOrder[index]
    end
  end
  if changed then
    roster.version = roster.version + 1
  end
end

---Read whether a unit is dead, a ghost, offline, being resurrected, or in another zone.
---@param unit BomUnit
---@param playerMapId number?
---@return boolean changed
function module:ReadStatus(unit, playerMapId)
  scanStatsModule:Count("statusReads")
  local unitId = unit.unitId
  local isDead = kvUnitModule.IsDead(unitId)
  local isGhost = kvUnitModule.IsGhost(unitId)
  local isConnected = kvUnitModule.IsConnected(unitId)
  -- An incoming resurrection is remembered until the unit lives again or it is forgotten
  -- on purpose: the caster may still be casting when the event has long passed
  local hasResurrection = isDead and (unit.hasResurrection or kvUnitModule.HasIncomingResurrection(unitId))
  local isSameZone = isGhost or unitId == "target" or kvUnitModule.GetMapId(unitId) == playerMapId

  if unit.isDead == isDead and unit.isGhost == isGhost and unit.isConnected == isConnected
      and unit.hasResurrection == hasResurrection and unit.isSameZone == isSameZone then
    return false
  end
  unit.isDead, unit.isGhost, unit.isConnected = isDead, isGhost, isConnected
  unit.hasResurrection, unit.isSameZone = hasResurrection, isSameZone
  return true
end

---Read the status of the units which need it.
---@param all boolean Every member
---@param deadOnly boolean Only the members known to be dead
---@param unitIds table<string, boolean> Named units; ignored when `all`
function module:ReadStatuses(all, deadOnly, unitIds)
  local roster = self.roster
  local playerMapId = kvUnitModule.GetMapId("player")
  local anyChanged, hasDead = false, false
  for _, unit in ipairs(roster.units) do
    if all or unitIds[unit.unitId] or (deadOnly and unit.isDead) then
      anyChanged = self:ReadStatus(unit, playerMapId) or anyChanged
    end
    hasDead = hasDead or unit.isDead
  end
  roster.hasDead = hasDead
  if anyChanged then
    roster.version = roster.version + 1
  end
end

---Forget who was already being resurrected, so the dead are offered for resurrection again.
function module:ForgetResurrections()
  for _, unit in pairs(self.units) do
    if unit.hasResurrection then
      unit.hasResurrection = false
      self.roster.version = self.roster.version + 1
    end
  end
end

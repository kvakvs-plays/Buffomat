local addonName, ns = ...

-- The range reader. Measuring the distance to a unit costs several API calls and has
-- no change event, so it is done only for the units a task builder asks about, at most
-- once per pass. While a task waits for range, the scheduler runs a pass every second.

---@class RangeScanModule
---@field epoch number Number of the current pass; a measurement is valid for one pass
local module = LibStub("Buffomat-RangeScan") --[[@as RangeScanModule]]

local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local scanStatsModule = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]

module.epoch = 1

---Distances measured in an earlier pass are stale from here on.
function module:BeginPass()
  self.epoch = self.epoch + 1
end

---@param unit BomUnit
---@return number distanceSquared Squared yards; KvUnit.TOO_FAR on another map
function module:Distance(unit)
  if unit.distanceEpoch ~= self.epoch then
    scanStatsModule:Count("rangeReads")
    unit.distance = kvUnitModule.DistanceSquared(unit.unitId)
    unit.distanceEpoch = self.epoch
  end
  return unit.distance
end

---@param unit BomUnit
---@return boolean Whether a group buff could reach this member
local function isReachable(unit)
  return unit.isConnected and not unit.isDead and unit.class ~= "pet"
end

---Distance to the nearest living member of a raid subgroup.
---@param roster BomRoster
---@param group number Raid subgroup 1..8
---@param includePlayer boolean The player counts as a member of their own subgroup
---@return number distanceSquared KvUnit.TOO_FAR when there is nobody
function module:NearestInGroup(roster, group, includePlayer)
  local nearest = kvUnitModule.TOO_FAR
  for _, unit in ipairs(roster.groups[group] or {}) do
    if isReachable(unit) and (includePlayer or not unit.isPlayer) then
      local distance = self:Distance(unit)
      if distance < nearest then
        nearest = distance
      end
    end
  end
  return nearest
end

---Distance to the nearest living member of a class, for class-wide blessings.
---@param roster BomRoster
---@param class ClassName
---@return number distanceSquared KvUnit.TOO_FAR when there is nobody
function module:NearestOfClass(roster, class)
  local nearest = kvUnitModule.TOO_FAR
  for _, unit in ipairs(roster.units) do
    if unit.class == class and unit.isConnected and not unit.isDead then
      local distance = self:Distance(unit)
      if distance < nearest then
        nearest = distance
      end
    end
  end
  return nearest
end

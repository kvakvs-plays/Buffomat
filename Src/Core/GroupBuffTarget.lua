---@class BomGroupBuffTargetModule
local module = LibStub("Buffomat-GroupBuffTarget") --[[@as BomGroupBuffTargetModule]]

local rangeScanModule = LibStub("Buffomat-RangeScan") --[[@as RangeScanModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomGroupBuffTarget
---@field groupIndex number|ClassName Raid subgroup 1..8, 0 for the whole raid, or a class for a blessing
local groupBuffTargetClass = {}
groupBuffTargetClass.__index = groupBuffTargetClass

---@param groupNum number|ClassName Raid subgroup 1..8, 0 for the whole raid, or a class for a blessing
---@return BomGroupBuffTarget
function module:New(groupNum)
  local fields = --[[@as BomGroupBuffTarget]] {
    groupIndex = groupNum,
  }
  setmetatable(fields, groupBuffTargetClass)

  return fields
end

---Distance to the nearest member the group buff is meant for.
---@return number distanceSquared
function groupBuffTargetClass:GetDistance()
  local roster = rosterScanModule.roster
  local group = self.groupIndex
  if group == 0 then
    return 0 -- the whole raid, cast on the player
  elseif type(group) == "string" then
    return rangeScanModule:NearestOfClass(roster, group)
  elseif envModule.groupBuffsRaidWide then
    return 0
  end
  -- In a raid the player's own subgroup is always reachable; a party is only worth a
  -- group buff when somebody else is near
  return rangeScanModule:NearestInGroup(roster, group, roster.isRaid)
end

function groupBuffTargetClass:GetText()
  if self.groupIndex == 0 then
    return _t("task.type.GroupBuff.Self")
  end

  return string.format(_t("FORMAT_GROUP_NUM"), self.groupIndex)
end
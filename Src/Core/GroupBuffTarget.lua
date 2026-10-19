---@class BomGroupBuffTargetModule

local groupBuffTargetModule = --[[@as BomGroupBuffTargetModule]] LibStub("Buffomat-GroupBuffTarget")
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomGroupBuffTarget
---@field groupIndex number
local groupBuffTargetClass = {}
groupBuffTargetClass.__index = groupBuffTargetClass

---@return BomGroupBuffTarget
function groupBuffTargetModule:New(groupNum)
  local fields = --[[@as BomGroupBuffTarget]] {
    groupIndex = groupNum,
  }
  setmetatable(fields, groupBuffTargetClass)

  return fields
end

function groupBuffTargetClass:GetDistanceRaid()
  local TOO_FAR = 1000022 -- special value to find out that the range error originates from this module
  local nearestDist = TOO_FAR
  --local nearestCount = 0

  for raidIndex = 1, 40 do
    local subgroup = select(3, GetRaidRosterInfo(raidIndex))
    local rName = "raid" .. raidIndex

    if subgroup == self.groupIndex and UnitExists(rName) and UnitIsConnected(rName) then
      local unitDistance = toolboxModule:UnitDistanceSquared(rName)
      if unitDistance < nearestDist then
        nearestDist = unitDistance
        --nearestCount = nearestCount + 1
      end
    end
  end -- for all raid members, searching for group

  return nearestDist
end

function groupBuffTargetClass:GetDistanceParty()
  if envModule.haveWotLK then
    -- in WotLK group buffs are cast on the whole group
    return 0 -- self always in range
  end

  local TOO_FAR = 1000033 -- special value to find out that the range error originates from this module
  local nearestDist = TOO_FAR
  --local nearestCount = 0

  -- Search for nearest member of 5man party, that is not myself
  for partyIndex = 1, 4 do
    local pName = "party" .. partyIndex
    if UnitExists(pName) and UnitIsConnected(pName) then -- skip offlines and missing
      local unitDistance = toolboxModule:UnitDistanceSquared(pName)
      if not UnitIsDead(pName) and unitDistance < nearestDist then
        nearestDist = unitDistance
        --nearestCount = nearestCount + 1
      end
    end
  end -- for party members

  return nearestDist
end

function groupBuffTargetClass:GetDistance()
  if IsInRaid() then
    return self:GetDistanceRaid()
  else
    return self:GetDistanceParty()
  end
end

function groupBuffTargetClass:GetText()
  if self.groupIndex == 0 then
    return _t("task.type.GroupBuff.Self")
  end

  return string.format(_t("FORMAT_GROUP_NUM"), self.groupIndex)
end
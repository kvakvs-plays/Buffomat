---@class BomUnitBuffTargetModule
local module = LibStub("Buffomat-UnitBuffTarget") --[[@as BomUnitBuffTargetModule]]

local rangeScanModule = LibStub("Buffomat-RangeScan") --[[@as RangeScanModule]]

---@class BomUnitBuffTarget
---@field unitName string Unit id, such as "raid7"
---@field link string|nil Colored unit name with class icon
---@field unit BomUnit|nil The roster unit, for the distance
local buffTargetClass = {}
buffTargetClass.__index = buffTargetClass

---@param unitName string Unit id
---@param link string|nil
---@param unit BomUnit|nil
---@return BomUnitBuffTarget
function module:New(unitName, link, unit)
  local fields = {} --[[@as BomUnitBuffTarget]]
  fields.unitName = unitName
  fields.link = link
  fields.unit = unit
  setmetatable(fields, buffTargetClass)

  return fields
end

---@param m BomUnit
---@return BomUnitBuffTarget
function module:FromUnit(m)
  return self:New(m.unitId, m.link, m)
end

---@param m BomUnit
---@return BomUnitBuffTarget
function module:FromSelf(m)
  return self:New("player", m.link, nil)
end

---@return number distanceSquared
function buffTargetClass:GetDistance()
  if self.unitName == "player" or self.unit == nil then
    return 0
  end
  return rangeScanModule:Distance(self.unit)
end

function buffTargetClass:GetText()
  if self.unitName == "player" then
    return "" -- no text for 'self' buffs
    -- return buffomatModule:Color("999999", _t("task.target.Self"))
  end
  return self.link or self.unitName
end
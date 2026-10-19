---@class BomUnitBuffTargetModule

local buffTargetModule = LibStub("Buffomat-UnitBuffTarget") --[[@as BomUnitBuffTargetModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]

---@class BomUnitBuffTarget
---@field unitName string Just the name
---@field link string|nil Colored unit name with class icon
local buffTargetClass = {}
buffTargetClass.__index = buffTargetClass

---@return BomUnitBuffTarget
function buffTargetModule:New(unitName, link)
  local fields = {} --[[@as BomUnitBuffTarget]]
  fields.unitName = unitName
  fields.link = link
  setmetatable(fields, buffTargetClass)

  return fields
end

---@param m BomUnit
---@return BomUnitBuffTarget
function buffTargetModule:FromUnit(m)
  return self:New(m.unitId, m.link)
end

---@param m BomUnit
---@return BomUnitBuffTarget
function buffTargetModule:FromSelf(m)
  return self:New("player", m.link)
end

function buffTargetClass:GetDistance()
  if self.unitName == "player" then
    return 0
  end

  return toolboxModule:UnitDistanceSquared(self.unitName)
end

function buffTargetClass:GetText()
  if self.unitName == "player" then
    return "" -- no text for 'self' buffs
    -- return buffomatModule:Color("999999", _t("task.target.Self"))
  end
  return self.link or self.unitName
end
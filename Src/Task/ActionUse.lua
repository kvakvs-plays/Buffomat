---@class BomActionUseModule

local actionUseModule = LibStub("Buffomat-ActionUse") --[[@as BomActionUseModule]]
local taskModule = LibStub("Buffomat-Task") --[[@as BomTaskModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]

---@class BomTaskActionUse: BomTaskAction Uses an equipment slot or a bag item
---@field buffDef BomBuffDefinition|nil
---@field target string
---@field bag number|nil Nil bag means use equipment slot
---@field slot number
---@field bestItemIdAvailable WowItemId|nil If set, will give a hint, which of the items providing the same buff, will be used
---@field extraText string|nil
local actionUseClass = {}
actionUseClass.__index = actionUseClass

---@param buffDef BomBuffDefinition|nil
---@param target string
---@param bag number
---@param slot number
---@return BomTaskActionUse
---@param extraText string|nil
---@param bestItemIdAvailable WowItemId|nil
function actionUseModule:New(buffDef, target, bag, slot, extraText, bestItemIdAvailable)
  local newAction = --[[@as BomTaskActionUse]] {}
  setmetatable(newAction, actionUseClass)
  newAction.buffDef = buffDef
  newAction.target = target
  newAction.bag = bag
  newAction.slot = slot
  newAction.extraText = extraText
  newAction.bestItemIdAvailable = bestItemIdAvailable
  return newAction
end

function actionUseClass:CanCast()
  return taskModule.CAN_CAST_OK
end

---@param m BomMacro
function actionUseClass:UpdateMacro(m)
  if self.bag == nil then
    table.insert(m.lines, "/use " .. self.slot)
  end
  if self.target then
    table.insert(m.lines, string.format("/use [@%s] %d %d", self.target, self.bag, self.slot))
  else
    table.insert(m.lines, string.format("/use %d %d", self.bag, self.slot))
  end
end

---@param _task BomTask
function actionUseClass:GetButtonText(_task)
  if self.buffDef == nil then
    return _t("task.UseOrOpen") .. " " .. (self.extraText or "")
  end

  local bdef = (self.buffDef)
  if bdef.isConsumable then
    return _t("task.type.Consume") .. " " .. bdef:SingleLink(self.bestItemIdAvailable)
  end
  return _t("task.type.Use") .. " " .. bdef:SingleLink(self.bestItemIdAvailable)
end
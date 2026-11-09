local BuffomatAddon = BuffomatAddon

---@class ActionMacroModule
local module = LibStub("Buffomat-ActionMacro") --[[@as ActionMacroModule]]

local taskModule = LibStub("Buffomat-Task") --[[@as TaskModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]

---@class BomTaskActionMacro: BomTaskAction Uses an equipment slot or a bag item
---@field macro string
---@field buttonText string
local actionMacroClass = {}
actionMacroClass.__index = actionMacroClass

---@param macro string
---@param buttonText string
---@return BomTaskActionMacro
function module:New(macro, buttonText)
  local a = --[[@as BomTaskActionMacro]] {}
  setmetatable(a, actionMacroClass)
  a.macro = macro
  a.buttonText = buttonText
  return a
end

function actionMacroClass:CanCast()
  return taskModule.CAN_CAST_OK
end

---@param task BomTask
function actionMacroClass:GetButtonText(task)
  return self.buttonText .. " " .. task.extraText
end

---@param m BomMacro
function actionMacroClass:UpdateMacro(m)
  table.insert(m.lines, self.macro)

  m.icon = constModule.MACRO_ICON
  m:UpdateMacro()
end

--- Clears the Buffomat macro
---@param command string|nil
function module:WipeMacro(command)
  local macro = BuffomatAddon.theMacro

  if not macro:EnsureExists() then
    return
  end
  wipe(macro.lines)

  if command then
    table.insert(macro.lines, command)
  end

  macro.icon = constModule.MACRO_ICON_DISABLED
  macro:UpdateMacro()
end

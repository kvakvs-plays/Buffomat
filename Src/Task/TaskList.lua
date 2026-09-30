local BuffomatAddon = BuffomatAddon

---@class TaskListModule

local taskListModule = LibStub("Buffomat-TaskList") --[[@as TaskListModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local taskModule = LibStub("Buffomat-Task") --[[@as BomTaskModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]

---@class BomTaskList
---@field tasks BomTask[]
---@field comments string[]
---@field lowPrioComments string[]
local taskListClass = {}
taskListClass.__index = taskListClass

---@return BomTask|nil
function taskListClass:SelectTask()
  for _, t in ipairs(self.tasks) do
    local canCast = t:CanCast()
    if canCast == taskModule.CAN_CAST_OK then
      return t
    end
  end
  return nil
end

---@return BomTaskList
function taskListModule:New()
  local fields = --[[@as BomTaskList]] {
    tasks           = {},
    comments        = {},
    lowPrioComments = {},
  }
  setmetatable(fields, taskListClass)
  return fields
end

---@param t BomTask
function taskListClass:Add(t)
  table.insert(self.tasks, t)
  self.firstToCast = t -- always first to cast is most recent; TODO: Respect prio
end

---Add a comment text which WILL auto open buffomat window when it is displayed
---@param text string
function taskListClass:Comment(text)
  table.insert(self.comments, text)
end

---Add a comment text which WILL NOT auto open buffomat window and will display in grey
---@param text string
function taskListClass:LowPrioComment(text)
  table.insert(self.lowPrioComments, text)
end

---Clear the cached text, and clear the message frame
function taskListClass:Clear()
  -- BomC_ListTab_MessageFrame:Clear()
  wipe(self.tasks)
  wipe(self.comments)
  wipe(self.lowPrioComments)
end

---@param a BomTask
---@param b BomTask
function taskListModule.OrderTasksByDistance(a, b)
  if not b then
    return false
  end
  if not a then
    return true
  end
  return a.distance < b.distance -- or
end

---@param a BomTask
---@param b BomTask
function taskListModule.OrderTasksByPriority(a, b)
  if not b then
    return false
  end
  if not a then
    return true
  end
  return a.priority < b.priority -- or
end

---@param a BomTask
---@param b BomTask
function taskListModule.OrderTasksByCustomOrderThenPriority(a, b)
  if not b then
    return false
  end
  if not a then
    return true
  end
  local aCustomSort = a.customSort or '5'
  local bCustomSort = b.customSort or '5'
  if aCustomSort == bCustomSort then
    return a.priority < b.priority
  end
  return aCustomSort < bCustomSort
end

function taskListClass:Sort()
  --table.sort(self.tasks, taskListModule.OrderTasksByDistance)
  if BuffomatShared.CustomBuffSorting then
    for _, task in pairs(self.tasks) do
      if task.linkedBuffDef then
        task.customSort = task.linkedBuffDef.customSort or '5'
      else
        task.customSort = nil
      end
    end
    table.sort(self.tasks, taskListModule.OrderTasksByCustomOrderThenPriority)
  else
    table.sort(self.tasks, taskListModule.OrderTasksByPriority)
  end
end

---Unload the contents of DisplayInfo cache into BomC_ListTab_MessageFrame
---The messages (tasks) are sorted
function taskListClass:Display()
  taskListPanelModule:Clear()

  local haveAnyTasks = next(self.lowPrioComments) or next(self.comments) or next(self.tasks)
  if haveAnyTasks and not taskListPanelModule:IsWindowVisible() then
    taskListPanelModule:AutoShow("tl:Display/haveTasks") -- have tasks, show the window
  end

  for _i, text in pairs(self.lowPrioComments) do
    taskListPanelModule:AddMessage(buffomatModule:Color("aaaaaa", text))
  end

  for _i, text in pairs(self.comments) do
    taskListPanelModule:AddMessage(text)
  end
  for _i, task in pairs(self.tasks) do
    if task.distance > 43 * 43 then
      taskListPanelModule:AddMessage(task:FormatDisabledRed(_t("task.error.range")))
    end
  end
  for _, task in pairs(self.tasks) do
    taskListPanelModule:AddMessage(task:Format())
  end
end

function taskListClass:CastButton_Nothing()
  taskListPanelModule:CastButtonText(_t("castButton.NothingToDo"), false)

  for _i, spell in ipairs(allBuffsModule.selectedBuffs) do
    if #spell.skipList > 0 then
      wipe(spell.skipList)
    end
  end
end

---Set text and enable the cast button (or disable)
---@param t string - text for the cast button
---@param enable boolean - whether to enable the button or not
function taskListClass:CastButtonText(t, enable)
  -- not really a necessary check but for safety
  if InCombatLockdown()
      or BomC_ListTab_Button == nil
      or BomC_ListTab_Button.SetText == nil then
    return
  end

  taskListPanelModule:CastButtonText(t, enable)
  --removeme
  BomC_ListTab_Button:SetText(t)

  if enable then
    BomC_ListTab_Button:Enable()
  else
    taskListModule:WipeMacro(nil)
    BomC_ListTab_Button:Disable()
  end
end

function taskListClass:CastButton_Busy()
  taskListPanelModule:CastButtonText(_t("castButton.Busy"), false)
  --removeme
  --Print player is busy (casting normal spell)
  self:CastButtonText(_t("castButton.Busy"), false)
  taskListModule:WipeMacro(nil)
end

function taskListClass:CastButton_BusyChanneling()
  taskListPanelModule:CastButtonText(_t("castButton.BusyChanneling"), false)
  --removeme
  --Print player is busy (casting channeled spell)
  self:CastButtonText(_t("castButton.BusyChanneling"), false)
  taskListModule:WipeMacro(nil)
end

---Success case, cast is allowed, macro will be set and button will be enabled
---@param task BomTask
function taskListClass:CastButton(task)
  if not BuffomatAddon.theMacro:EnsureExists() then
    return
  end
  wipe(BuffomatAddon.theMacro.lines)

  local action = task.action
  taskListPanelModule:CastButtonText(action:GetButtonText(task), true)
  --removeme
  self:CastButtonText(action:GetButtonText(task), true)

  -- Set the macro lines and update the Buffomat macro
  action:UpdateMacro(BuffomatAddon.theMacro)
  BuffomatAddon.theMacro:UpdateMacro()
end

function taskListClass:CastButton_SomeoneIsDead()
  taskListPanelModule:CastButtonText(_t("castButton.inactive.DeadMember"), false)
  --removeme
  self:CastButtonText(_t("castButton.inactive.DeadMember"), false)
end

--function taskListClass:CastButton_CantCast()
--  -- Range is good but cast is not possible
--  --self:CastButton(ERR_OUT_OF_MANA, false)
--  self:CastButtonText(_t("castButton.CantCastMaybeOOM"), false)
--end

function taskListClass:CastButton_OutOfRange()
  taskListPanelModule:CastButtonText(ERR_SPELL_OUT_OF_RANGE, false)
  --removeme
  self:CastButtonText(ERR_SPELL_OUT_OF_RANGE, false)

  local skipreset = false

  for spellIndex, spell in ipairs(allBuffsModule.selectedBuffs) do
    if #spell.skipList > 0 then
      skipreset = true
      wipe(spell.skipList)
    end
  end

  if skipreset then
    throttleModule:FastUpdateTimer()
    throttleModule:RequestTaskRescan("skipReset")
  end
end -- if inrange

--removeme
--- Clears the Buffomat macro
---@param command string|nil
function taskListModule:WipeMacro(command)
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

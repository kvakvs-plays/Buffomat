---@diagnostic disable: invisible, unused-local
local BuffomatAddon = BuffomatAddon

---@alias ShowHideCommand "show"|"hide"
---@alias AutoShowHideCommand "autoshow"|"autohide"
---@alias WindowCommand ShowHideCommand|AutoShowHideCommand|nil

---@class TaskListPanelModule
---@field taskFrame? AceGUIWidget Floating frame for task list
---@field buffButton? AceGUIWidget Button for casting a buff or reporting status
---@field scrollPanel? AceGUIWidget Scroll panel for list of tasks/messages
---@field topUiPanel? AceGUIWidget Top panel for buff button and menu
---@field titleProfile string The profile name which goes into the title of the window
---@field titleBuffGroups string The buff groups which go into the title of the window
---@field messages string[]
---@field saveBuffButtonText string Saves the button text when in combat
-- --- User show/hide and auto show/hide mechanics ---
---@field windowCommand WindowCommand Delays actual window show/hide operation till it is a safe time to do
---@field windowCommandCallLocation string The location where the window command was called from
---@field lastUserWindowCommand? ShowHideCommand Last user operation on window (not auto)

local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
taskListPanelModule.titleProfile = ""
taskListPanelModule.titleBuffGroups = ""

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local actionMacroModule = LibStub("Buffomat-ActionMacro") --[[@as BomActionMacroModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local libGUI = LibStub("AceGUI-3.0")
local ngToolboxModule = LibStub("Buffomat-NgToolbox") --[[@as NgToolboxModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]
local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]

--- Constructs the window. Only called from one location - WindowCommand()
function taskListPanelModule:ConstructWindow()
  local taskFrame = libGUI:Create("NgTaskListWindow")
  self.taskFrame = taskFrame

  taskFrame:SetLayout("Fill")
  taskFrame:ClearAllPoints()
  taskFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BuffomatShared.X or 0, BuffomatShared.Y or 0)
  taskFrame:SetWidth(BuffomatShared.Width or 300)
  taskFrame:SetHeight(BuffomatShared.Height or 200)
  taskFrame:SetCallback("OnClose", function()
    taskListPanelModule:HideWindow("tlp:closeButtonClick")
  end)
  self:SetWindowScale(tonumber(BuffomatShared.UIWindowScale) or 1.0)

  local scrollPanel = libGUI:Create("ScrollFrame")
  self.scrollPanel = scrollPanel
  scrollPanel:SetLayout("List")
  taskFrame:AddChild(scrollPanel)

  self:CreateUIRow()
  self:SetTitle()
end

function taskListPanelModule:SetTitle()
  if self.taskFrame ~= nil then
    self.taskFrame:SetTitle(self.titleProfile .. ' ' .. self.titleBuffGroups)
  end
end

---@param holdOpen boolean
function taskListPanelModule:ToggleWindow(holdOpen)
  self.windowCommandCallLocation = "tlp:toggleWindow"

  if self:IsWindowVisible() then
    self.windowCommand = "hide"
  else
    throttleModule:RequestTaskRescan("toggleWindow")
    self.windowCommand = "show"
  end
end

function taskListPanelModule:IsWindowVisible()
  return self.taskFrame ~= nil and self.taskFrame:IsVisible()
end

local function doShow()
  if taskListPanelModule.taskFrame == nil then
    taskListPanelModule:ConstructWindow()
    taskListPanelModule:SetWindowScale(tonumber(BuffomatShared.UIWindowScale) or 1.0)
  else
    taskListPanelModule.taskFrame:Show()
  end
  taskListPanelModule:SetAlpha(1.0)

  -- Show all messages if they were added while the window was hidden
  -- for _, message in pairs(self.messages or {}) do
  --   self:AddMessageLabel(message)
  -- end
  throttleModule:RequestTaskRescan("showWindow")
  taskScanModule:ScanTasks("show")
end

local function doHide()
  if taskListPanelModule.taskFrame ~= nil then
    taskListPanelModule.taskFrame:Hide()
  end

  throttleModule:RequestTaskRescan("hideWindow")
end

--- Do not call this directly. Called from the throttle module on timed updates.
---@param command WindowCommand
function taskListPanelModule:WindowCommand(command)
  if not self.windowCommand then
    return
  end

  if self.windowCommand == "hide" then
    -- User hides the window (and stay hidden)
    doHide()
    self.lastUserWindowCommand = "hide"
    -- --------------------------------------------------
  elseif self.windowCommand == "autohide" then
    -- The addon requests hiding the window
    -- Allow if either settings allow auto hiding, or the window was auto-shown from hide state
    -- doHide()
    local fade = BuffomatShared.FadeWhenNothingToDo or 0.25
    self:SetAlpha(fade) -- fade the window, default 50%
    if BuffomatShared.AutoClose then
      doHide()
    end
    -- --------------------------------------------------
  elseif self.windowCommand == "show" then
    -- The user shows the window (and it stays visible)
    doShow()
    self.lastUserWindowCommand = "show"
    -- --------------------------------------------------
  elseif self.windowCommand == "autoshow" --and self.lastUserWindowCommand ~= "hide"
  then
    -- The addon requests showing the window
    -- Allow if either settings allow auto showing, or the window was auto-hidden from show state
    doShow()
  end
  -- --------------------------------------------------
  self.windowCommand = nil
  self.windowCommandCallLocation = nil
end

---@param callLocation string The location where this is called from
function taskListPanelModule:HideWindow(callLocation)
  self.windowCommand = "hide"
  self.windowCommandCallLocation = callLocation
end

---Attempt to close if holdOpen is false (holds open if user manually called up the window)
---@param callLocation string The location where this is called from
function taskListPanelModule:AutoHide(callLocation)
  -- If the window is not hold open and the buff button exists and is disabled, attempt to close the window
  self.windowCommand = "autohide"
  self.windowCommandCallLocation = callLocation
end

---@param callLocation string The location where this is called from
function taskListPanelModule:AutoShow(callLocation)
  if not BuffomatShared.AutoOpen then
    return
  end
  self.windowCommand = "autoshow"
  self.windowCommandCallLocation = callLocation
end

---@param callLocation string The location where this is called from
function taskListPanelModule:ShowWindow(callLocation)
  self.windowCommand = "show"
  self.windowCommandCallLocation = callLocation
end

-- Reset the window to the default position and size, save the default position and size
function taskListPanelModule:ResetWindow()
  self.taskFrame:ClearAllPoints()
  self.taskFrame:SetPoint("Center", UIParent, "Center", 0, 0)
  self.taskFrame:SetWidth(200)
  self.taskFrame:SetHeight(200)
  self:SavePosition()
  self:ShowWindow("tlp:resetWindow")
  BuffomatAddon:Print("Window position is reset.")
end

-- Add a message to the scroll panel (stacking down)
function taskListPanelModule:AddMessage(text)
  self.messages = {}
  tinsert(self.messages, text)

  if self:IsWindowVisible() then
    self:AddMessageLabel(text) -- construct actual label and show it
  end
end

---Only call this if the window is visible
function taskListPanelModule:AddMessageLabel(text)
  local message = libGUI:Create("Label")
  message:SetText(text)
  message:SetFullWidth(true)
  self.scrollPanel:AddChild(message)
end

-- Clear the scroll panel and create a new row with a buff button and menu
function taskListPanelModule:Clear()
  self.buffButton = nil
  self.messages = {}

  if self:IsWindowVisible() then
    self.scrollPanel:ReleaseChildren()
    self:CreateUIRow()
  end
end

-- For a fresh emptied scroll panel, create a row with a buff button and menu
function taskListPanelModule:CreateUIRow()
  local topUiPanel = libGUI:Create("SimpleGroup")
  self.topUiPanel = topUiPanel
  topUiPanel:SetLayout("Flow")
  topUiPanel:SetFullWidth(true)
  topUiPanel:SetHeight(36)
  self.scrollPanel:AddChild(topUiPanel)

  -- Create the secure action button, as macro button
  local buffButton = libGUI:Create("NgSecureActionButton")
  self.buffButton = buffButton
  buffButton.frame:SetAttribute("type", "macro")
  buffButton.frame:SetAttribute("macro", constModule.MACRO_NAME)
  buffButton:SetFullWidth(true)
  buffButton:SetHeight(24)
  -- buffButton.frame:SetNormalTexture("Interface\\Buttons\\UI-MicroButton-Talents-Up")
  -- buffButton.frame:SetPushedTexture("Interface\\Buttons\\UI-MicroButton-Talents-Down")
  -- buffButton.frame:SetDisabledTexture("Interface\\Buttons\\UI-MicroButton-Talents-Disabled")
  buffButton:SetAutoWidth(true)
  -- buffButton:SetText("Buff")
  -- buffButton:SetCallback("OnClick", function() print("Click Buff!") end)
  ngToolboxModule:TooltipWithTranslationKey(buffButton, "tooltip.TaskList.CastButton")
  topUiPanel:AddChild(buffButton)
end

---Set text and enable the cast button (or disable)
---@param text string - text for the cast button
---@param enable boolean - whether to enable the button or not
function taskListPanelModule:CastButtonText(text, enable)
  -- not really a necessary check but for safety
  if InCombatLockdown()
      or self.buffButton == nil
      or self.buffButton.SetText == nil then
    return
  end

  self.buffButton:SetText(text)

  if enable then
    self.buffButton:SetDisabled(false)
  else
    actionMacroModule:WipeMacro(nil)
    self.buffButton:SetDisabled(true)
  end
end

function taskListPanelModule:SetAlpha(alpha)
  if self.taskFrame ~= nil then
    self.taskFrame.frame:SetAlpha(alpha)
  end
end

function taskListPanelModule:SetWindowScale(scale)
  if self.taskFrame ~= nil then
    self.taskFrame.frame:SetScale(scale)
  end
end

function taskListPanelModule:IsBuffButtonEnabled()
  return self.buffButton ~= nil and not self.buffButton.disabled
end

function taskListPanelModule:SavePosition()
  if self.taskFrame ~= nil then
    BuffomatShared.X = self.taskFrame.frame:GetLeft()
    BuffomatShared.Y = self.taskFrame.frame:GetTop()
    BuffomatShared.Width = self.taskFrame.frame:GetWidth()
    BuffomatShared.Height = self.taskFrame.frame:GetHeight()
  end
end

function taskListPanelModule:OnCombatStart()
  self:AutoHide("tlp:combatStart")

  if self.buffButton then
    self.saveBuffButtonText = self.buffButton.label:GetText()
    self.buffButton:SetText(_t("castButton.InCombat"))
  end
end

function taskListPanelModule:OnCombatStop()
  if self.buffButton and self.buffButton.label:GetText() == _t("castButton.InCombat") then
    self.buffButton:SetText(self.saveBuffButtonText)
    self.saveBuffButtonText = ''
  end
end
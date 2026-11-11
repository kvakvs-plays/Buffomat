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
---@field shownText string? The lines the visible window shows now; nil when it has to be drawn again
-- --- User show/hide and auto show/hide mechanics ---
---@field windowCommand WindowCommand Delays actual window show/hide operation till it is a safe time to do
---@field windowCommandCallLocation string The location where the window command was called from
---@field windowCommandForceHide? boolean Force the next autohide command to hide regardless of AutoClose
---@field lastUserWindowCommand? ShowHideCommand Last user operation on window (not auto)

local module = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
module.titleProfile = ""
module.titleBuffGroups = ""

-- Tracks whether last bounds check found the window off-screen, so the warning
-- is printed only once per transition into/out of the bad state.
local flagIsOutofBounds = false

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local actionMacroModule = LibStub("Buffomat-ActionMacro") --[[@as ActionMacroModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local libGUI = LibStub("AceGUI-3.0")
local ngToolboxModule = LibStub("Buffomat-NgToolbox") --[[@as NgToolboxModule]]
local scanSchedulerModule = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local slashModule = LibStub("Buffomat-SlashCommands") --[[@as SlashCommandsModule]]

--- Constructs the window. Only called from one location - WindowCommand()
function module:ConstructWindow()
  local taskFrame = libGUI:Create("NgTaskListWindow")
  self.taskFrame = taskFrame

  taskFrame:SetLayout("Fill")
  taskFrame:ClearAllPoints()
  if BuffomatShared.X == nil or BuffomatShared.Y == nil then
    taskFrame:SetPoint("CENTER", UIParent, "CENTER")
  else
    taskFrame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", BuffomatShared.X, BuffomatShared.Y)
  end
  taskFrame:SetWidth(BuffomatShared.Width or 300)
  taskFrame:SetHeight(BuffomatShared.Height or 200)
  taskFrame:SetCallback("OnClose", function()
    module:HideWindow("tlp:closeButtonClick")
  end)
  self:SetWindowScale(tonumber(BuffomatShared.UIWindowScale) or 1.0)

  local scrollPanel = libGUI:Create("ScrollFrame")
  self.scrollPanel = scrollPanel
  scrollPanel:SetLayout("List")
  taskFrame:AddChild(scrollPanel)

  self:CreateUIRow()
  self:SetTitle()
end

function module:SetTitle()
  if self.taskFrame ~= nil then
    self.taskFrame:SetTitle(self.titleProfile .. ' ' .. self.titleBuffGroups)
  end
end

---@param _holdOpen boolean
function module:ToggleWindow(_holdOpen)
  self.windowCommandCallLocation = "tlp:toggleWindow"

  if self:IsWindowVisible() then
    self.windowCommand = "hide"
  else
    self.windowCommand = "show"
  end
  scanSchedulerModule:Request("toggleWindow")
end

---Whether the window is open. This is not "can be seen": with the whole interface hidden
---(Alt-Z, a cinematic) an open window stays open, and must not be opened again every pass.
---@return boolean
function module:IsWindowVisible()
  return self.taskFrame ~= nil and self.taskFrame:IsShown() == true
end

---@param byUser boolean The user asked for the window, as opposed to tasks appearing
local function doShow(byUser)
  local wasVisible = module:IsWindowVisible()
  if module.taskFrame == nil then
    module:ConstructWindow()
    module:SetWindowScale(tonumber(BuffomatShared.UIWindowScale) or 1.0)
  else
    module.taskFrame:Show()
  end
  module:SetAlpha(1.0)

  -- Show all messages if they were added while the window was hidden
  -- for _, message in pairs(self.messages or {}) do
  --   self:AddMessageLabel(message)
  -- end
  if not wasVisible then
    -- The task list is only drawn into a visible window, so it has to be drawn now. When
    -- the user opens the window, everything is also read again.
    module.shownText = nil
    if byUser then
      scanSchedulerModule:MarkAllDirty("showWindow")
    else
      scanSchedulerModule:Request("autoShowWindow")
    end
  end
end

local function doHide()
  if module.taskFrame ~= nil then
    module.taskFrame:Hide()
  end
  module.shownText = nil
end

---@param text string All lines of the task list, joined
---@return boolean Whether the visible window already shows exactly this
function module:IsShowing(text)
  return self.shownText == text and self:IsWindowVisible()
end

---Remember what was just drawn; nothing is drawn into a hidden window.
---@param text string All lines of the task list, joined
function module:SetShowing(text)
  self.shownText = self:IsWindowVisible() and text or nil
end

--- Do not call this directly. Called from the scan pass, which never runs in combat: the window
--- holds a secure button and cannot be shown or hidden then.
---@param _command WindowCommand
function module:WindowCommand(_command)
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
    if BuffomatShared.AutoClose or self.windowCommandForceHide then
      doHide()
    end
    -- --------------------------------------------------
  elseif self.windowCommand == "show" then
    -- The user shows the window (and it stays visible)
    doShow(true)
    self.lastUserWindowCommand = "show"
    -- --------------------------------------------------
  elseif self.windowCommand == "autoshow" --and self.lastUserWindowCommand ~= "hide"
  then
    -- The addon requests showing the window
    -- Allow if either settings allow auto showing, or the window was auto-hidden from show state
    doShow(false)
  end
  -- --------------------------------------------------
  self.windowCommand = nil
  self.windowCommandCallLocation = nil
  self.windowCommandForceHide = nil
end

---@param callLocation string The location where this is called from
function module:HideWindow(callLocation)
  self.windowCommand = "hide"
  self.windowCommandCallLocation = callLocation
  self.windowCommandForceHide = nil
  scanSchedulerModule:Request("hideWindow")
end

---Attempt to close if holdOpen is false (holds open if user manually called up the window)
---@param callLocation string The location where this is called from
---@param forceHide boolean|nil Hide even when AutoClose is disabled
function module:AutoHide(callLocation, forceHide)
  -- If the window is not hold open and the buff button exists and is disabled, attempt to close the window
  self.windowCommand = "autohide"
  self.windowCommandCallLocation = callLocation
  self.windowCommandForceHide = forceHide == true
end

---@param callLocation string The location where this is called from
function module:AutoShow(callLocation)
  if not BuffomatShared.AutoOpen then
    return
  end
  self.windowCommand = "autoshow"
  self.windowCommandCallLocation = callLocation
  self.windowCommandForceHide = nil
end

---@param callLocation string The location where this is called from
function module:ShowWindow(callLocation)
  self.windowCommand = "show"
  self.windowCommandCallLocation = callLocation
  self.windowCommandForceHide = nil
  scanSchedulerModule:Request("showWindow")
end

-- Reset the window to the default position and size, save the default position and size
function module:ResetWindow()
  self.taskFrame:ClearAllPoints()
  self.taskFrame:SetPoint("Center", UIParent, "Center", 0, 0)
  self.taskFrame:SetWidth(200)
  self.taskFrame:SetHeight(200)
  self:SavePosition()
  self:ShowWindow("tlp:resetWindow")
  BuffomatAddon:Print("Window position is reset.")
end

-- Add a message to the scroll panel (stacking down)
function module:AddMessage(text)
  self.messages = {}
  tinsert(self.messages, text)

  if self:IsWindowVisible() then
    self:AddMessageLabel(text) -- construct actual label and show it
  end
end

---Only call this if the window is visible
function module:AddMessageLabel(text)
  local message = libGUI:Create("Label")
  message:SetText(text)
  message:SetFullWidth(true)
  self.scrollPanel:AddChild(message)
end

-- Clear the scroll panel and create a new row with a buff button and menu
function module:Clear()
  self.buffButton = nil
  self.messages = {}

  if self:IsWindowVisible() then
    self.scrollPanel:ReleaseChildren()
    self:CreateUIRow()
  end
end

-- For a fresh emptied scroll panel, create a row with a buff button and menu
function module:CreateUIRow()
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
function module:CastButtonText(text, enable)
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

function module:SetAlpha(alpha)
  if self.taskFrame ~= nil then
    self.taskFrame.frame:SetAlpha(alpha)
  end
end

function module:SetWindowScale(scale)
  if self.taskFrame ~= nil then
    self.taskFrame.frame:SetScale(scale)
  end
end

function module:IsBuffButtonEnabled()
  return self.buffButton ~= nil and not self.buffButton.disabled
end

function module:SavePosition()
  if self.taskFrame ~= nil then
    BuffomatShared.X = self.taskFrame.frame:GetLeft()
    BuffomatShared.Y = self.taskFrame.frame:GetTop()
    BuffomatShared.Width = self.taskFrame.frame:GetWidth()
    BuffomatShared.Height = self.taskFrame.frame:GetHeight()
  end
  self:CheckWindowBounds()
end

---Warn once when the task list window is dragged off-screen so the user knows
---to run /bom reset. Resets the latch when the window returns on-screen.
function module:CheckWindowBounds()
  if self.taskFrame == nil or self.taskFrame.isWindowOutOfBounds == nil then
    return
  end
  local outOfBounds = self.taskFrame:isWindowOutOfBounds()
  if outOfBounds and not flagIsOutofBounds then
    flagIsOutofBounds = true
    BuffomatAddon:Print("Window is off-screen. Use " .. slashModule.mainCommand .. " reset to restore it.")
  elseif not outOfBounds and flagIsOutofBounds then
    flagIsOutofBounds = false
  end
end

function module:OnCombatStart()
  self:AutoHide("tlp:combatStart")

  if self.buffButton then
    self.saveBuffButtonText = self.buffButton.label:GetText()
    self.buffButton:SetText(_t("castButton.InCombat"))
  end
end

function module:OnCombatStop()
  if self.buffButton and self.buffButton.label:GetText() == _t("castButton.InCombat") then
    self.buffButton:SetText(self.saveBuffButtonText)
    self.saveBuffButtonText = ''
  end
end

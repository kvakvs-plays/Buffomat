-- Copy of AceGUI-3.0 Window with some modifications
-- Creates a window with a title, a close button, a macro button, and a settings button
-- This is used for the Task List Panel

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local AceGUI = LibStub("AceGUI-3.0")
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local optionsPopupModule = LibStub("Buffomat-OptionsPopup") --[[@as OptionsPopupModule]]
local spellsDialogModule = LibStub("Buffomat-SpellsDialog") --[[@as SpellsDialogModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local texturesModule = LibStub("Buffomat-Textures") --[[@as TexturesModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]

-- Lua APIs
local pairs, assert, type = pairs, assert, type

-- WoW APIs
local PlaySound = PlaySound
local CreateFrame, UIParent = CreateFrame, UIParent

---@class _TLWContent: AceGUIFrame
---@field width number
---@field height number

---@class NgTaskListWindow: AceGUIWidget
---@field Type "Window"
---@field frame Frame
---@field sizer_se AceGUIFrame
---@field sizer_s AceGUIFrame
---@field sizer_e AceGUIFrame
---@field content _TLWContent
---@field titletext FontString
---@field title Button

----------------
-- Main Frame --
----------------
--[[
	Events :
		OnClose

]]
do
  local Type = "NgTaskListWindow" -- Modified AceGUI-3.0 Window
  local Version = 8

  local function frameOnShow(this)
    this.obj:Fire("OnShow")
  end

  local function frameOnClose(this)
    this.obj:Fire("OnClose")
  end

  local function closeOnClick(this)
    PlaySound(799) -- SOUNDKIT.GS_TITLE_OPTION_EXIT
    this.obj:Hide()
  end

  ---@diagnostic disable-next-line: unused-local
  local function frameOnMouseDown(_this)
    AceGUI:ClearFocus()
  end

  local function titleOnMouseDown(this)
    this:GetParent():StartMoving()
    AceGUI:ClearFocus()
  end

  local function frameOnMouseUp(this)
    local frame = this:GetParent()
    frame:StopMovingOrSizing()
    local self = frame.obj
    local status = self.status or self.localstatus
    status.width = frame:GetWidth()
    status.height = frame:GetHeight()
    status.top = frame:GetTop()
    status.left = frame:GetLeft()
    taskListPanelModule:SavePosition()
  end

  local function sizerSEOnMouseDown(this)
    this:GetParent():StartSizing("BOTTOMRIGHT")
    AceGUI:ClearFocus()
  end

  local function sizerSOnMouseDown(this)
    this:GetParent():StartSizing("BOTTOM")
    AceGUI:ClearFocus()
  end

  local function sizerEOnMouseDown(this)
    this:GetParent():StartSizing("RIGHT")
    AceGUI:ClearFocus()
  end

  local function sizerOnMouseUp(this)
    this:GetParent():StopMovingOrSizing()
    taskListPanelModule:SavePosition()
  end

  local function SetTitle(self, title)
    self.titletext:SetText(title)
  end

  ---@diagnostic disable-next-line: unused-local
  local function SetStatusText(_self, _text)
    -- self.statustext:SetText(text)
  end

  local function Hide(self)
    self.frame:Hide()
  end

  local function Show(self)
    self.frame:Show()
  end

  local function OnAcquire(self)
    self.frame:SetParent(UIParent)
    self.frame:SetFrameStrata("FULLSCREEN_DIALOG")
    self:ApplyStatus()
    self:EnableResize(true)
    self:Show()
  end

  local function OnRelease(self)
    self.status = nil
    for k in pairs(self.localstatus) do
      self.localstatus[k] = nil
    end
  end

  -- called to set an external table to store status in
  ---@param self NgTaskListWindow
  local function SetStatusTable(self, status)
    assert(type(status) == "table")
    self.status = status
    self:ApplyStatus()
  end

  ---@param self NgTaskListWindow
  local function ApplyStatus(self)
    local status = self.status or self.localstatus
    local frame = self.frame
    self:SetWidth(status.width or 700)
    self:SetHeight(status.height or 500)
    if status.top and status.left then
      frame:SetPoint("TOP", UIParent, "BOTTOM", 0, status.top)
      frame:SetPoint("LEFT", UIParent, "LEFT", status.left, 0)
    else
      frame:SetPoint("CENTER", UIParent, "CENTER")
    end
  end

  ---@param self NgTaskListWindow
  local function OnWidthSet(self, width)
    local content = self.content
    local contentwidth = width - 34
    if contentwidth < 0 then
      contentwidth = 0
    end
    content:SetWidth(contentwidth)
    content.width = contentwidth
  end

  ---@param self NgTaskListWindow
  local function OnHeightSet(self, height)
    local content = self.content
    local contentheight = height - 57
    if contentheight < 0 then
      contentheight = 0
    end
    content:SetHeight(contentheight)
    content.height = contentheight
  end

  ---@param self NgTaskListWindow
  local function EnableResize(self, state)
    local func = state and "Show" or "Hide"
    self.sizer_se[func](self.sizer_se)
    self.sizer_s[func](self.sizer_s)
    self.sizer_e[func](self.sizer_e)
  end

  ---Check if window header is dragged so far off-screen the user cannot grab it.
  ---Returns true when less than 25% of the title-bar width or less than one full
  ---title-bar height is inside the visible UIParent rectangle.
  ---@param self NgTaskListWindow
  ---@return boolean
  local function isWindowOutOfBounds(self)
    local title = self.title
    local titleLeft = title:GetLeft()
    local titleRight = title:GetRight()
    local titleTop = title:GetTop()
    local titleBottom = title:GetBottom()
    if not (titleLeft and titleRight and titleTop and titleBottom) then
      return false
    end

    local screenWidth = UIParent:GetRight() or 0
    local screenHeight = UIParent:GetTop() or 0

    local titleWidth = titleRight - titleLeft
    local titleHeight = titleTop - titleBottom

    local visibleWidth = math.max(0, math.min(titleRight, screenWidth) - math.max(titleLeft, 0))
    local visibleHeight = math.max(0, math.min(titleTop, screenHeight) - math.max(titleBottom, 0))

    if titleWidth > 0 and visibleWidth < titleWidth * 0.25 then
      return true
    end
    if titleHeight > 0 and visibleHeight < titleHeight then
      return true
    end
    return false
  end

  ---@param button Button
  local function SetButtonTexture(button, texture)
    -- button:SetNormalTexture(texture)
    local normalTex = button:GetNormalTexture()
    normalTex:SetSize(20, 20)
    normalTex:ClearAllPoints()
    normalTex:SetPoint("CENTER")
    normalTex:SetTexture(texture)

    local pressedTex = button:GetPushedTexture()
    pressedTex:SetSize(20, 20)
    pressedTex:ClearAllPoints()
    pressedTex:SetPoint("CENTER")
    pressedTex:SetTexture(texture)

    local disabledTex = button:GetDisabledTexture()
    disabledTex:SetSize(20, 20)
    disabledTex:ClearAllPoints()
    disabledTex:SetPoint("CENTER")
    disabledTex:SetTexture(texture)
  end

  ---@param window NgTaskListWindow
  local function ConstructTopButtons(window)
    --local extraButtonCount = 4
    local buttonWidthExtra = 20 -- `extraButtonCount` extra buttons 20px each left from the X button

    -- [🐰🐑] button top right for all spell settings
    local spellsButton = CreateFrame("Button", nil, window.frame, "UIPanelCloseButton")
    spellsButton:SetPoint("TOPRIGHT", 2 - buttonWidthExtra * 4, 1)
    SetButtonTexture(spellsButton, constModule.BOM_SPELL_SETTINGS_ICON_FULLPATH)
    spellsButton:SetScript("OnClick", function() spellsDialogModule:Show() end)
    toolboxModule:Tooltip(spellsButton, _t("tooltip.button.AllBuffs"))
    window.spellsButton = spellsButton
    spellsButton.obj = window

    -- [📜] button top right
    local quickPopupButton = CreateFrame("Button", nil, window.frame, "UIPanelCloseButton")
    quickPopupButton:SetPoint("TOPRIGHT", 2 - buttonWidthExtra * 3, 1)
    SetButtonTexture(quickPopupButton, constModule.BOM_OPTIONS_ICON_FULLPATH)
    quickPopupButton:SetScript("OnClick", function()
      optionsPopupModule:Setup(quickPopupButton, false)
    end)
    toolboxModule:Tooltip(quickPopupButton, _t("tooltip.button.QuickSettingsPopup"))
    window.settingsButton = quickPopupButton
    quickPopupButton.obj = window

    -- [⚙️] Settings button top right
    local settingsButton = CreateFrame("Button", nil, window.frame, "UIPanelCloseButton")
    settingsButton:SetPoint("TOPRIGHT", 2 - buttonWidthExtra * 2, 1)
    SetButtonTexture(settingsButton, texturesModule.ICON_GEAR)
    settingsButton:SetScript("OnClick", function()
      optionsPopupModule:OpenOptions()
    end)
    toolboxModule:Tooltip(settingsButton, _t("tooltip.button.AllSettings"))
    window.settingsButton = settingsButton
    settingsButton.obj = window

    -- [🧙‍♂️] button top right, draggable macro
    local macroButton = CreateFrame("Button", nil, window.frame, "UIPanelCloseButton")
    macroButton:SetPoint("TOPRIGHT", 2 - buttonWidthExtra, 1)
    SetButtonTexture(macroButton, constModule.BOM_BEAR_ICON_FULLPATH)
    macroButton:SetScript("OnClick", function()
      PickupMacro(constModule.MACRO_NAME)
    end)
    toolboxModule:Tooltip(macroButton, _t("TooltipMacroButton"))
    window.macroButton = macroButton
    macroButton.obj = window

    -- [❌] button top right
    local close = CreateFrame("Button", nil, window.frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 1)
    close:SetScript("OnClick", closeOnClick)
    toolboxModule:Tooltip(
      close,
      string.format(_t("tooltip.button.HideBuffomat"), GetBindingKey("BUFFOMAT_WINDOW") or _t("binding.notSet"))
    )
    window.closebutton = close
    close.obj = window
  end

  ---@return NgTaskListWindow
  local function Constructor()
    local frame = CreateFrame("Frame", nil, UIParent)
    ---@type NgTaskListWindow
    local window = {}
    window.type = "Window"

    window.Hide = Hide
    window.Show = Show
    window.SetTitle = SetTitle
    window.OnRelease = OnRelease
    window.OnAcquire = OnAcquire
    window.SetStatusText = SetStatusText
    window.SetStatusTable = SetStatusTable
    window.ApplyStatus = ApplyStatus
    window.OnWidthSet = OnWidthSet
    window.OnHeightSet = OnHeightSet
    window.EnableResize = EnableResize
    window.isWindowOutOfBounds = isWindowOutOfBounds

    window.localstatus = {}

    window.frame = frame
    frame.obj = window
    frame:SetWidth(250)
    frame:SetHeight(150)
    if frame.SetResizeBounds then
      frame:SetResizeBounds(200, 100)
    else
      frame:SetMinResize(200, 100)
    end
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:EnableMouse()
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetScript("OnMouseDown", frameOnMouseDown)

    frame:SetScript("OnShow", frameOnShow)
    frame:SetScript("OnHide", frameOnClose)
    frame:SetToplevel(true)

    local titlebg = frame:CreateTexture(nil, "BACKGROUND")
    titlebg:SetTexture(251966) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background
    titlebg:SetPoint("TOPLEFT", 9, -6)
    titlebg:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -28, -24)

    local dialogbg = frame:CreateTexture(nil, "BACKGROUND")
    dialogbg:SetTexture(137056) -- Interface\\Tooltips\\UI-Tooltip-Background
    dialogbg:SetPoint("TOPLEFT", 8, -24)
    dialogbg:SetPoint("BOTTOMRIGHT", -6, 8)
    dialogbg:SetVertexColor(0, 0, 0, .75)

    local topleft = frame:CreateTexture(nil, "BORDER")
    topleft:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    topleft:SetWidth(64)
    topleft:SetHeight(64)
    topleft:SetPoint("TOPLEFT")
    topleft:SetTexCoord(0.501953125, 0.625, 0, 1)

    local topright = frame:CreateTexture(nil, "BORDER")
    topright:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    topright:SetWidth(64)
    topright:SetHeight(64)
    topright:SetPoint("TOPRIGHT")
    topright:SetTexCoord(0.625, 0.75, 0, 1)

    local top = frame:CreateTexture(nil, "BORDER")
    top:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    top:SetHeight(64)
    top:SetPoint("TOPLEFT", topleft, "TOPRIGHT")
    top:SetPoint("TOPRIGHT", topright, "TOPLEFT")
    top:SetTexCoord(0.25, 0.369140625, 0, 1)

    local bottomleft = frame:CreateTexture(nil, "BORDER")
    bottomleft:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    bottomleft:SetWidth(64)
    bottomleft:SetHeight(64)
    bottomleft:SetPoint("BOTTOMLEFT")
    bottomleft:SetTexCoord(0.751953125, 0.875, 0, 1)

    local bottomright = frame:CreateTexture(nil, "BORDER")
    bottomright:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    bottomright:SetWidth(64)
    bottomright:SetHeight(64)
    bottomright:SetPoint("BOTTOMRIGHT")
    bottomright:SetTexCoord(0.875, 1, 0, 1)

    local bottom = frame:CreateTexture(nil, "BORDER")
    bottom:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    bottom:SetHeight(64)
    bottom:SetPoint("BOTTOMLEFT", bottomleft, "BOTTOMRIGHT")
    bottom:SetPoint("BOTTOMRIGHT", bottomright, "BOTTOMLEFT")
    bottom:SetTexCoord(0.376953125, 0.498046875, 0, 1)

    local left = frame:CreateTexture(nil, "BORDER")
    left:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    left:SetWidth(64)
    left:SetPoint("TOPLEFT", topleft, "BOTTOMLEFT")
    left:SetPoint("BOTTOMLEFT", bottomleft, "TOPLEFT")
    left:SetTexCoord(0.001953125, 0.125, 0, 1)

    local right = frame:CreateTexture(nil, "BORDER")
    right:SetTexture(251963) -- Interface\\PaperDollInfoFrame\\UI-GearManager-Border
    right:SetWidth(64)
    right:SetPoint("TOPRIGHT", topright, "BOTTOMRIGHT")
    right:SetPoint("BOTTOMRIGHT", bottomright, "TOPRIGHT")
    right:SetTexCoord(0.1171875, 0.2421875, 0, 1)

    ConstructTopButtons(window)

    local titletext = frame:CreateFontString(nil, "ARTWORK")
    titletext:SetFontObject(GameFontNormal)
    titletext:SetPoint("TOPLEFT", 12, -8)
    titletext:SetPoint("TOPRIGHT", -32, -8)
    titletext:SetJustifyH("LEFT")
    window.titletext = titletext

    local title = CreateFrame("Button", nil, frame)
    title:SetPoint("TOPLEFT", titlebg)
    title:SetPoint("BOTTOMRIGHT", titlebg)
    title:EnableMouse()
    title:SetScript("OnMouseDown", titleOnMouseDown)
    title:SetScript("OnMouseUp", frameOnMouseUp)
    window.title = title

    local sizer_se = CreateFrame("Frame", nil, frame)
    sizer_se:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    sizer_se:SetWidth(25)
    sizer_se:SetHeight(25)
    sizer_se:EnableMouse()
    sizer_se:SetScript("OnMouseDown", sizerSEOnMouseDown)
    sizer_se:SetScript("OnMouseUp", sizerOnMouseUp)
    window.sizer_se = sizer_se

    local line1 = sizer_se:CreateTexture(nil, "BACKGROUND")
    window.line1 = line1
    line1:SetWidth(14)
    line1:SetHeight(14)
    line1:SetPoint("BOTTOMRIGHT", -8, 8)
    line1:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
    local x = 0.1 * 14 / 17
    line1:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

    local line2 = sizer_se:CreateTexture(nil, "BACKGROUND")
    window.line2 = line2
    line2:SetWidth(8)
    line2:SetHeight(8)
    line2:SetPoint("BOTTOMRIGHT", -8, 8)
    line2:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
    x = 0.1 * 8 / 17
    line2:SetTexCoord(0.05 - x, 0.5, 0.05, 0.5 + x, 0.05, 0.5 - x, 0.5 + x, 0.5)

    local sizer_s = CreateFrame("Frame", nil, frame)
    sizer_s:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -25, 0)
    sizer_s:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    sizer_s:SetHeight(25)
    sizer_s:EnableMouse()
    sizer_s:SetScript("OnMouseDown", sizerSOnMouseDown)
    sizer_s:SetScript("OnMouseUp", sizerOnMouseUp)
    window.sizer_s = sizer_s

    local sizer_e = CreateFrame("Frame", nil, frame)
    sizer_e:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 25)
    sizer_e:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    sizer_e:SetWidth(25)
    sizer_e:EnableMouse()
    sizer_e:SetScript("OnMouseDown", sizerEOnMouseDown)
    sizer_e:SetScript("OnMouseUp", sizerOnMouseUp)
    window.sizer_e = sizer_e

    --Container Support
    local content = CreateFrame("Frame", nil, frame)
    window.content = content
    content.obj = window
    content:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -32)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -12, 13)

    AceGUI:RegisterAsContainer(window)
    return window
  end

  AceGUI:RegisterWidgetType(Type, Constructor, Version)
end
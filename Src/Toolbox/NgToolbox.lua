---@diagnostic disable: invisible
-- New Generation GUI Toolbox using WowAce (AceGUI-3.0)

---@class NgToolboxModule

local ngToolboxModule = LibStub("Buffomat-NgToolbox") --[[@as NgToolboxModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local libGUI = LibStub("AceGUI-3.0")

---@param widget AceGUIWidget
---@param text string The key to translation
function ngToolboxModule:SetTooltip(widget, text)
  widget:SetCallback("OnEnter", function()
    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
    GameTooltip:AddLine(text)
    GameTooltip:Show()
  end)
  widget:SetCallback("OnLeave", function()
    GameTooltip:Hide()
  end)
end

---@param widget AceGUIWidget
---@param translationKey string The key to translation
function ngToolboxModule:TooltipWithTranslationKey(widget, translationKey)
  widget:SetCallback("OnEnter", function()
    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
    GameTooltip:AddLine(_t(translationKey))
    GameTooltip:Show()
  end)
  widget:SetCallback("OnLeave", function()
    GameTooltip:Hide()
  end)
end

---Add onenter/onleave scripts to show the tooltip with spell
---@param widget AceGUIWidget
---@param link string The string in format "spell:<id>" or "item:<id>"
function ngToolboxModule:TooltipLink(widget, link)
  widget:SetCallback("OnEnter", function()
    GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(link)
    GameTooltip:Show()
  end)
  widget:SetCallback("OnLeave", function()
    GameTooltip:Hide()
  end)
end

---@param frame Frame
function ngToolboxModule:SetButtonTextures(frame, normalTexture, selectedTexture, disabledTexture)
  if not normalTexture then
    frame:ClearNormalTexture()
    frame:ClearPushedTexture()
    frame:ClearDisabledTexture()
    return
  end

  frame:SetNormalTexture(normalTexture)
  local normalT = frame:GetNormalTexture()
  normalT:SetSize(20, 20)
  normalT:ClearAllPoints()
  normalT:SetPoint("CENTER")

  frame:SetPushedTexture(selectedTexture or normalTexture)
  local pushedT = frame:GetPushedTexture()
  pushedT:SetSize(20, 20)
  pushedT:ClearAllPoints()
  pushedT:SetPoint("CENTER")

  frame:SetDisabledTexture(disabledTexture or normalTexture)
  local disabledT = frame:GetDisabledTexture()
  disabledT:SetSize(20, 20)
  disabledT:ClearAllPoints()
  disabledT:SetPoint("CENTER")
end

---@param tooltip string
---@param textureOn string
---@param textureOff string
---@param getValue fun(): boolean
---@param setValue fun(value: boolean)
---@return AceGUIWidget
function ngToolboxModule:CreateToggle(tooltip, width, height, textureOn, textureOff, getValue, setValue)
  local button = libGUI:Create("Button")
  button:SetWidth(width)
  button:SetHeight(height)

  local valueOnCreation = getValue()
  local setTextureOn = function()
    ngToolboxModule:SetButtonTextures(button.frame, textureOn)
  end
  local setTextureOff = function()
    ngToolboxModule:SetButtonTextures(button.frame, textureOff)
  end
  if valueOnCreation then setTextureOn() else setTextureOff() end

  ---@diagnostic disable-next-line: unused-local
  button:SetCallback("OnClick", function(_control, _mouseButton)
    local newValue = not getValue()
    setValue(newValue)
    if newValue then setTextureOn() else setTextureOff() end
  end)

  self:SetTooltip(button, tooltip)
  button.frame:SetFrameStrata("DIALOG")

  return button
end

---@param tooltip string
---@param texture string
---@param onClick fun()
---@return AceGUIWidget
function ngToolboxModule:CreateButton(text, tooltip, width, height, texture, onClick)
  local button = libGUI:Create("Button")
  button:SetWidth(width)
  button:SetHeight(height)

  if text then button:SetText(text) end
  ngToolboxModule:SetButtonTextures(button.frame, texture)
  if tooltip then self:SetTooltip(button, tooltip) end

  ---@diagnostic disable-next-line: unused-local
  button:SetCallback("OnClick", function(_control, _mouseButton) onClick() end)

  return button
end
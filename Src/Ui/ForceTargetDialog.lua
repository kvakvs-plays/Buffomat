---@class ForceTargetDialogModule

local forceTargetDialogModule = LibStub("Buffomat-ForceTargetDialog") --[[@as ForceTargetDialogModule]]
local libGUI = LibStub("AceGUI-3.0")
local ngToolboxModule = LibStub("Buffomat-NgToolbox") --[[@as NgToolboxModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]

local function targetsDictToString(dictionary)
  local result = ""
  if dictionary == nil or next(dictionary) == nil then
    return ""
  end
  for name, _ in pairs(dictionary) do
    result = result .. name .. "\n"
  end
  return result
end

local function targetsDictFromString(string)
  local result = {}
  for name in string:gmatch("[^\n]+") do
    result[name] = true
  end
  return result
end

function forceTargetDialogModule:Hide()
  if self.dialog then
    self.dialog:Hide()
    -- self.dialog:Release()
    self.dialog = nil
  end
end

---@param buffDef BomBuffDefinition
---@param getValue fun(): {[string]: boolean}
---@param setValue fun(dictionary: {[string]: boolean})
---@param title string
---@param _spellsDialog AceGUIWidget Parent dialog that we want to position against
function forceTargetDialogModule:Show(buffDef, getValue, setValue, title, _spellsDialog)
  self:Hide()
  local dialog = libGUI:Create("Window")
  self.dialog = dialog

  dialog:SetTitle(title .. " " .. buffDef.singleLink)
  dialog:SetLayout("Flow")
  dialog:SetWidth(200)
  dialog:SetHeight(300)
  dialog:EnableResize(false)
  -- dialog.frame:SetFrameStrata("DIALOG") -- float above other frames

  -- Create top panel for buttons
  -- local uiPanel = libGUI:Create("SimpleGroup")
  -- uiPanel:SetLayout("Flow")
  -- uiPanel:SetFullWidth(true)
  -- uiPanel:SetHeight(32)
  -- dialog:AddChild(uiPanel)

  -- Create the multiline edit for the names list
  local editBox = libGUI:Create("MultiLineEditBox")
  editBox:SetFullWidth(true)
  editBox:SetFullHeight(true)
  editBox:SetLabel(_t("label.ForceCast.TargetList"))
  editBox:SetText(targetsDictToString(getValue()))
  editBox:SetCallback("OnEnterPressed", function(_widget, _event, text)
    setValue(targetsDictFromString(text))
    forceTargetDialogModule:Hide()
  end)

  local addButton = ngToolboxModule:CreateButton(
    _t("button.ForceCast.AddTarget"),
    _t("buttonTooltip.ForceCast.AddTarget"),
    130, 24, nil,
    function()
      if BuffomatAddon.lastTarget then
        local dict = targetsDictFromString(editBox.editBox:GetText())
        dict[BuffomatAddon.lastTarget] = true
        editBox.editBox:SetText(targetsDictToString(dict))
        editBox.button:Enable()
      end
    end)
  dialog:AddChild(addButton)

  local removeButton = ngToolboxModule:CreateButton(
    _t("button.ForceCast.RemoveTarget"),
    _t("buttonTooltip.ForceCast.RemoveTarget"),
    130, 24, nil,
    function()
      if BuffomatAddon.lastTarget then
        local dict = targetsDictFromString(editBox.editBox:GetText())
        dict[BuffomatAddon.lastTarget] = nil
        editBox.editBox:SetText(targetsDictToString(dict))
        editBox.button:Enable()
      end
    end)
  dialog:AddChild(removeButton)

  dialog:AddChild(editBox)
  return dialog
end
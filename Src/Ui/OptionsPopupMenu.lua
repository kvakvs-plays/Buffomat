local BuffomatAddon = BuffomatAddon

---@class BomBehaviourSetting
---@field name string
---@field value boolean

---@class OptionsPopupModule
-- -@field behaviourSettings BomBehaviourSetting[]

local optionsPopupModule = LibStub("Buffomat-OptionsPopup") --[[@as OptionsPopupModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local popupModule = LibStub("Buffomat-Popup") --[[@as PopupModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local characterSettingsModule = LibStub("Buffomat-CharacterSettings") --[[@as CharacterSettingsModule]]
---Makes a tuple to pass to the menubuilder to display a settings checkbox in popup menu
---@param db table - BuffomatShared reference to read settings from it
---@param var string Variable name from optionsPopupModule.BehaviourSettings
function optionsPopupModule:MakeSettingsRow(db, var)
  return _t("options.short." .. var), false, db, var
end

function optionsPopupModule.OpenOptions()
  LibStub("AceConfigDialog-3.0"):Open(constModule.SHORT_TITLE)
end

---Populate the [⚙] popup menu
---@param minimap boolean
function optionsPopupModule:Setup(control, minimap)
  local name = (control:GetName() or "nil") .. (minimap and "Minimap" or "Normal")
  local dyn = BuffomatAddon.popupMenuDynamic ---@type GPIPopupDynamic
  local menuItems = {} --[[@as BomMenuItemDef[] ]]

  if not dyn:Wipe(name) then
    return
  end

  -- Add auto-hide functionality
  dyn._Frame:SetClampedToScreen(true)
  dyn._Frame:SetFrameStrata("DIALOG")
  dyn._Frame:EnableMouse(true)

  -- Make the frame close when clicking outside
  dyn._Frame:SetAttribute("clickOnClose", true)
  dyn._Frame:HookScript("OnLeave", function(menu)
    -- Add slight delay to allow clicking menu items
    C_Timer.After(0.5, function()
      if not envModule.MouseIsOver(menu) then
        menu:Hide()
      end
    end)
  end)

  if minimap then
    table.insert(menuItems,
      popupModule:Clickable(_t("popup.OpenBuffomat"),
        function() taskListPanelModule:ShowWindow("optionsPopupMenu:minimap") end,
        nil, nil))
    table.insert(menuItems, popupModule:Separator())
    table.insert(menuItems, popupModule:Boolean(_t("options.short.ShowMinimapButton"),
      BuffomatShared.Minimap, "hide", true))
    table.insert(menuItems, popupModule:Separator())
  end

  -- --------------------------------------------
  -- Use Profiles checkbox and submenu
  -- --------------------------------------------
  table.insert(menuItems, popupModule:Boolean(_t("options.short.UseProfiles"),
    BuffomatCharacter, "UseProfiles"))

  if BuffomatCharacter.UseProfiles then
    local subprofilesMenu = --[[@as BomMenuItemDef[] ]] {}
    table.insert(subprofilesMenu, popupModule:Clickable(characterSettingsModule:LocalizedProfileName("auto"),
      buffomatModule.ChooseProfile, "auto", nil))

    local currentProfileName = profileModule:ChooseProfile()

    for _i, eachProfileName in pairs(profileModule.ALL_PROFILES) do
      if currentProfileName == eachProfileName then
        local activeName = _t("profile.activeProfileMenuTag") ..
            " " .. characterSettingsModule:LocalizedProfileName(eachProfileName)
        table.insert(subprofilesMenu, popupModule:Clickable(buffomatModule:Color("00ff00", activeName),
          buffomatModule.ChooseProfile, eachProfileName, nil))
      else
        table.insert(subprofilesMenu,
          popupModule:Clickable(characterSettingsModule:LocalizedProfileName(eachProfileName),
            buffomatModule.ChooseProfile, eachProfileName, nil))
      end
    end

    table.insert(menuItems, popupModule:SubMenu(_t("header.Profiles"), 1, subprofilesMenu))
  end

  table.insert(menuItems, popupModule:Separator())

  -- --------------------------------------------
  -- Selected spells check on/off
  -- --------------------------------------------
  if true then
    for i, buffDef in ipairs(allBuffsModule.selectedBuffs) do
      if not buffDef.isConsumable then
        table.insert(menuItems, popupModule:Boolean(
          buffDef:SingleLink(),
          profileModule:GetProfileBuff(buffDef.buffId, nil),
          "Enable"))
      end
    end
  end

  table.insert(menuItems, popupModule:Separator())

  --self:PopupQuickOptions()

  table.insert(menuItems, popupModule:Clickable(_t("optionsMenu.Settings"),
    optionsPopupModule.OpenOptions, 1, nil))

  dyn:SetMenuItems(menuItems)
  dyn:Show(control or "cursor", 0, 0)
end
---@diagnostic disable: invisible
--
-- Module implements AceGUI dialog for choosing spells and spell settings.
-- Replaces the classic Buffomat spells tab.
--

---@class SpellsDialogContext
---@field categoryFrames {[string]: AceGUIWidget} Contains title and checkbox to show/hide the category
---@field playerIsHorde boolean
---@field useProfileName ProfileName

---@class SpellsDialogModule
---@field dialog AceGUIWidget AceGUI frame containing the spells list
---@field scrollFrame AceGUIWidget AceGUI scroll frame containing the spells list
---@field context SpellsDialogContext

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local forceTargetDialogModule = LibStub("Buffomat-ForceTargetDialog") --[[@as ForceTargetDialogModule]]
local libGUI = LibStub("AceGUI-3.0")
local ngStringsModule = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]
local ngToolboxModule = LibStub("Buffomat-NgToolbox") --[[@as NgToolboxModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local spellsDialogModule = LibStub("Buffomat-SpellsDialog") --[[@as SpellsDialogModule]]
local texturesModule = LibStub("Buffomat-Textures") --[[@as TexturesModule]]
local characterSettingsModule = LibStub("Buffomat-CharacterSettings") --[[@as CharacterSettingsModule]]

---@param preselectCategory BuffCategoryName|nil
function spellsDialogModule:Show(preselectCategory)
  -- InCombat Protection is checked by the caller (Update***Tab)
  if allBuffsModule.selectedBuffs == nil then
    return false
  end

  if InCombatLockdown() then
    return false
  end

  if self.dialog then
    self:Hide()
  end

  local dialog = libGUI:Create("Frame")
  self.dialog = dialog

  if preselectCategory then
    self.useProfileName = preselectCategory
  else
    self.useProfileName = buffomatModule.currentProfileName
  end

  dialog:SetTitle(string.format(_t("title.SpellsWindow"),
    characterSettingsModule:LocalizedProfileName(self.useProfileName)))
  dialog:SetLayout("Fill")
  dialog:SetWidth(650)
  dialog:SetHeight(400)
  dialog:SetPoint("CENTER")
  -- dialog.frame:SetFrameStrata("DIALOG") -- float above other frames
  dialog:Show()

  local scrollFrame = libGUI:Create("ScrollFrame")
  self.scrollFrame = scrollFrame
  scrollFrame:SetLayout("List")
  scrollFrame:SetFullHeight(true)
  scrollFrame:SetFullWidth(true)
  dialog:AddChild(scrollFrame)

  self:AddProfileSelector()
  self:AddGroupScanSelector()
  self:FillBuffsList()
end

function spellsDialogModule:AddProfileSelector()
  local profileSelector = libGUI:Create("Dropdown")
  profileSelector:SetWidth(250)
  profileSelector:SetLabel(_t("label.SpellsDialog.ProfileSelector"))

  for _, profileName in ipairs(characterSettingsModule.profileNames) do
    profileSelector:AddItem(profileName, characterSettingsModule:LocalizedProfileName(profileName))
  end

  profileSelector:SetValue(self.useProfileName)

  profileSelector:SetCallback("OnValueChanged", function(_control, _callbackName, value)
    spellsDialogModule:Hide()
    spellsDialogModule:Show(value)
  end)

  self.scrollFrame:AddChild(profileSelector)
end

function spellsDialogModule:FillBuffsList()
  self.context = {
    playerIsHorde = UnitFactionGroup("player") == "Horde",
    categoryFrames = {},
  } ---@type SpellsDialogContext

  self:CreateCategoryFrames(self.context)

  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, self.useProfileName)

    if not self:CategoryIsHidden(buffDef.category) then
      local categoryFrame = self.context.categoryFrames[buffDef.category]

      if profileBuff ~= nil and categoryFrame ~= nil then
        local row = self:CreateBuffRow(buffDef, profileBuff, self.context)
        categoryFrame:AddChild(row)
      end
    end
  end

  self.scrollFrame:DoLayout()
end

function spellsDialogModule:CategoryLabel(catId)
  if not catId then
    return _t("Category_none")
  end
  return _t("Category_" .. catId)
end

---@param category BuffCategoryName
---@return boolean
function spellsDialogModule:CategoryIsHidden(category)
  return BuffomatCharacter.BuffCategoriesHidden[category] == true
end

-- Pre-create category frames
---@param context SpellsDialogContext
function spellsDialogModule:CreateCategoryFrames(context)
  for _, cat in ipairs(allBuffsModule.buffCategories) do
    -- Count known buffs in this category
    local count = 0
    for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
      if buffDef.category == cat then
        count = count + 1
      end
    end
    -- Only create category frame if there are any buffs in this category
    if count > 0 then
      self:CreateCategoryFrame(context, cat)
    end
  end
end

---Contains the text heading and checkbox to show/hide the category
---@param context SpellsDialogContext
---@param cat BuffCategoryName
function spellsDialogModule:CreateCategoryFrame(context, cat)
  local categoryFrame = libGUI:Create("SimpleGroup")
  context.categoryFrames[cat] = categoryFrame
  categoryFrame:SetLayout("List")
  categoryFrame:SetFullWidth(true)
  self.scrollFrame:AddChild(categoryFrame)

  local headingPanel = libGUI:Create("SimpleGroup")
  headingPanel:SetLayout("Flow")
  headingPanel:SetFullWidth(true)
  headingPanel:SetRelativeWidth(1)
  categoryFrame:AddChild(headingPanel)

  local label = libGUI:Create("InteractiveLabel")
  label:SetText(buffomatModule:Color("aaaaaa", self:CategoryLabel(cat)))
  label:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
  label:SetWidth(label.label:GetStringWidth())
  headingPanel:AddChild(label)

  local isVisible = not self:CategoryIsHidden(cat)
  local showCategoryCheckbox = libGUI:Create("CheckBox")
  showCategoryCheckbox:SetWidth(32)
  showCategoryCheckbox:SetValue(isVisible)
  showCategoryCheckbox:SetLabel("")
  showCategoryCheckbox:SetCallback("OnValueChanged", function(_control, _callbackName, value)
    BuffomatCharacter.BuffCategoriesHidden[cat] = not value
    spellsDialogModule:Hide()
    spellsDialogModule:Show(spellsDialogModule.useProfileName)
  end)
  headingPanel:AddChild(showCategoryCheckbox)
end

-- From a buff definition, create an icon button. For consumable buffs, the icon is
-- calculated differently. Clicking the consumable icon will print all items which
-- provide this buff from the smallest to largest value.
---@param buffDef BomBuffDefinition
---@return AceGUIWidget
function spellsDialogModule:CreateInfoIcon(buffDef)
  local iconButton = libGUI:Create("Button")
  -- iconButton:SetImage(buffDef.icon)
  iconButton:SetWidth(20)
  iconButton:SetHeight(20)

  if buffDef.consumeGroupIcon then
    ngToolboxModule:SetButtonTextures(iconButton.frame, buffDef.consumeGroupIcon)

    iconButton:SetCallback("OnClick", function(_control, mouseButton)
      if mouseButton == 'LeftButton' then
        buffDef:ShowItemsProvidingBuff()
      end
    end)
    ngToolboxModule:TooltipWithTranslationKey(iconButton, "Click to print all items which provide this buff")
    iconButton:SetCallback("OnClick", function(_control, mouseButton)
      buffDef:ShowItemsProvidingBuff()
    end)
  else
    if buffDef.isConsumable then
      ngToolboxModule:TooltipLink(iconButton, "item:" .. buffDef:GetFirstItem())
    else
      ngToolboxModule:TooltipLink(iconButton, "spell:" .. buffDef.highestRankSingleId)
    end

    -- Set texture when ready, might load with a delay
    buffDef:GetIcon(function(texture)
      ngToolboxModule:SetButtonTextures(iconButton.frame, texture)
    end)
  end

  return iconButton
end

-- Player choices are stored separately in their profile
---@param buffDef BomBuffDefinition
---@param context SpellsDialogContext
function spellsDialogModule:CreateBuffRow(buffDef, profileBuff, context)
  local row = libGUI:Create("SimpleGroup")
  row:SetLayout("Flow")
  row:SetFullWidth(true)

  -- Create the icon button
  local iconButton = self:CreateInfoIcon(buffDef)
  row:AddChild(iconButton)

  -- Create the checkbox to enable/disable the buff
  local checkEnabled = libGUI:Create("CheckBox")
  checkEnabled:SetValue(profileBuff.Enable)
  checkEnabled:SetCallback("OnValueChanged", function(_control, _callbackName, value)
    profileBuff.Enable = value
  end)
  checkEnabled:SetLabel("-")
  buffDef:SetSpellListText(function(text)
    checkEnabled:SetLabel(text)
    checkEnabled:SetWidth(checkEnabled.text:GetStringWidth() + 32)
  end)
  row:AddChild(checkEnabled)

  -- Create checkboxes one per class
  if buffDef:HasClasses() then
    self:AddSelfCastToggle(row, profileBuff)
    self:AddClassRoleToggles(row, profileBuff)
    self:AddForceTargets(row, buffDef, profileBuff)
  end

  -- -- Add checkbox for spells which can be enabled and present at the same time?
  -- if (buffDef.type == "tracking"
  --       or buffDef.type == "aura"
  --       or buffDef.type == "seal")
  --     and buffDef.requiresForm == nil then
  --   local statusImage = buffDef.frames:CreateStatusCheckboxImage(buffDef)
  --   statusImage:SetPoint("TOPLEFT", infoIcon, "TOPRIGHT", rowBuilder.dx, 0)
  --   rowBuilder:ContinueRightOf(statusImage, 7)
  -- end

  ----------------------------------
  -- TODO: Add soulstone for all classes and make whisper work
  -- if buff.isInfo and buff.AllowWhisper then
  --   local whisperToggle = ngToolboxModule:CreateToggle(
  --     _t("TooltipWhisperWhenExpired"), 24, 20,
  --     texturesModule.ICON_WHISPER_ON,
  --     texturesModule.ICON_WHISPER_OFF,
  --     function() return profileBuff.Whisper end,
  --     function(value) profileBuff.Whisper = value end
  --   )
  --   row:AddChild(whisperToggle)
  -- end

  ----------------------------------
  if buffDef.type == "weapon" then
    self:AddMainhandToggle(row, profileBuff)

    -- Only warriors, rogues, dk can enchant offhand. Shamans can enchant offhand in TBC. Other classes - only mainhand/2h.
    local canEnchantOffhand = false
    if tContains({ "ROGUE", "WARRIOR", "DEATHKNIGHT" }, envModule.playerClass)
        and UnitLevel("player") >= 10
    then
      canEnchantOffhand = true
    end
    if envModule.haveTBC and envModule.playerClass == "SHAMAN" then
      canEnchantOffhand = true
    end

    if canEnchantOffhand then
      self:AddOffhandToggle(row, profileBuff)
    end
  end

  return row
end

function spellsDialogModule:AddMainhandToggle(row, profileBuff)
  local mainhandToggle = ngToolboxModule:CreateToggle(
    _t("tooltip.mainhand"),
    24, 20, texturesModule.ICON_MAINHAND_ON, texturesModule.ICON_MAINHAND_OFF,
    function() return profileBuff.MainHandEnable end,
    function(value) profileBuff.MainHandEnable = value end
  )
  row:AddChild(mainhandToggle)
end

function spellsDialogModule:AddOffhandToggle(row, profileBuff)
  local offhandToggle = ngToolboxModule:CreateToggle(
    _t("tooltip.offhand"),
    24, 20, texturesModule.ICON_OFFHAND_ON, texturesModule.ICON_OFFHAND_OFF,
    function() return profileBuff.OffHandEnable end,
    function(value) profileBuff.OffHandEnable = value end
  )
  row:AddChild(offhandToggle)
end

---Add class selector for buff which makes sense to differentiate per class.
---@param row AceGUIWidget The GUI panel where controls are added
---@param profileBuff PlayerBuffChoice The profile buff currently being displayed
function spellsDialogModule:AddSelfCastToggle(row, profileBuff)
  local selfCastTooltip = ngStringsModule:FormatTexture(texturesModule.ICON_SELF_CAST_ON)
      .. " - " .. _t("TooltipSelfCastCheckbox_Self") .. "|n"
      .. ngStringsModule:FormatTexture(texturesModule.ICON_SELF_CAST_OFF)
      .. " - " .. _t("TooltipSelfCastCheckbox_Party")

  local selfcastToggle = ngToolboxModule:CreateToggle(
    selfCastTooltip,
    24,
    20,
    texturesModule.ICON_SELF_CAST_ON,
    texturesModule.ICON_SELF_CAST_OFF,
    function() return profileBuff.SelfCast end,
    function(value) profileBuff.SelfCast = value end
  )

  ngToolboxModule:SetTooltip(selfcastToggle, selfCastTooltip)
  row:AddChild(selfcastToggle)
end

---Add Cast-on-class checkboxes one per class, and for 2 extra roles (tank, pet)
---@param row AceGUIWidget The GUI panel where controls are added
---@param profileBuff PlayerBuffChoice The profile buff currently being displayed
function spellsDialogModule:AddClassRoleToggles(row, profileBuff)
  for _, class in ipairs(constModule.CLASSES) do
    self:AddClassRoleToggle(row, profileBuff, class)
  end -- for each class in class_sort_orderend

  self:AddClassRoleToggle(row, profileBuff, "tank")
  self:AddClassRoleToggle(row, profileBuff, "pet")
end

---Creates one toggle for one class or role (call in loop)
---@param row AceGUIWidget The GUI panel where controls are added
---@param profileBuff PlayerBuffChoice The profile buff currently being displayed
---@param classOrRole ClassName
function spellsDialogModule:AddClassRoleToggle(row, profileBuff, classOrRole)
  local skip = false
  local hordePaladin = self.context.playerIsHorde and classOrRole == "PALADIN"
  local allianceShaman = not self.context.playerIsHorde and classOrRole == "SHAMAN"
  -- if not TBC hide paladin for horde, hide shaman for alliance
  if not (envModule.haveTBC or envModule.isForever) and (hordePaladin or allianceShaman) then
    skip = true
  end

  if not skip then
    local tooltip2 = constModule.CLASS_ICONS[classOrRole]
        .. " - " .. _t("TooltipCastOnClass")
        .. ": " .. constModule.CLASS_NAME[ classOrRole --[[@as ClassName]] ] .. "|n"
        .. ngStringsModule:FormatTexture(texturesModule.ICON_EMPTY) .. " - " .. _t("TabDoNotBuff")
        .. ": " .. constModule.CLASS_NAME[ classOrRole --[[@as ClassName]] ] .. "|n"
        .. ngStringsModule:FormatTexture(texturesModule.ICON_DISABLED) .. " - " .. _t("TabBuffOnlySelf")

    -- local classToggle = buffDef.frames:CreateClassToggle(class, tooltip2, bomDoBlessingOnClick)
    local classToggle = ngToolboxModule:CreateToggle(
      tooltip2,
      24,
      20,
      texturesModule.CLASS_ICONS_BUNDLED[classOrRole],
      texturesModule.ICON_EMPTY,
      function() return profileBuff.Class[classOrRole] == true end,
      function(value) profileBuff.Class[classOrRole] = value end
    )
    row:AddChild(classToggle)
  end
end

---Add two buttons: for force cast and exclude target. Clicking each button pops up a dialog
---with a list of units to choose from, add (add target) and remove (remove target) buttons.
---@param row AceGUIWidget The GUI panel where controls are added
---@param buffDef BomBuffDefinition
---@param profileBuff PlayerBuffChoice The profile buff currently being displayed
function spellsDialogModule:AddForceTargets(row, buffDef, profileBuff)
  -- Force Cast Button (+)
  local forceToggle = ngToolboxModule:CreateButton(
    nil,
    _t("TooltipForceCastOnTarget"),
    24, 20, texturesModule.ICON_TARGET_ON,
    function()
      local dialog = forceTargetDialogModule:Show(
        buffDef,
        function() return profileBuff.ForceTarget end,
        function(dictionary) profileBuff.ForceTarget = dictionary end,
        _t("title.ForceTarget"),
        self.dialog
      )
      spellsDialogModule:AttachDialog(dialog)
    end)
  row:AddChild(forceToggle)

  -- Exclude/Ignore Buff Target Button (X)
  local excludeToggle = ngToolboxModule:CreateButton(
    nil,
    _t("TooltipExcludeTarget"),
    24, 20, texturesModule.ICON_TARGET_EXCLUDE,
    function()
      local dialog = forceTargetDialogModule:Show(
        buffDef,
        function() return profileBuff.ExcludeTarget end,
        function(dictionary) profileBuff.ExcludeTarget = dictionary end,
        _t("title.ExcludeTarget"),
        self.dialog
      )
      spellsDialogModule:AttachDialog(dialog)
    end)
  row:AddChild(excludeToggle)
end

---Attach the floating dialog 'dialog' to our main 'self.dialog' right side.
function spellsDialogModule:AttachDialog(attachDialog)
  -- Instead of adding as a child, set the parent directly
  attachDialog.frame:SetParent(self.dialog.frame)

  -- Attach to the right side of the parent frame
  attachDialog.frame:ClearAllPoints()
  attachDialog.frame:SetPoint("TOPLEFT", self.dialog.frame, "TOPRIGHT", 0, 0)

  -- Make it non-movable since it should follow the parent
  attachDialog.frame:SetMovable(false)
  attachDialog.frame:SetResizable(false)
end

function spellsDialogModule:Hide()
  forceTargetDialogModule:Hide()

  if self.dialog then
    self.scrollFrame:ReleaseChildren()

    for _, categoryFrame in pairs(self.context.categoryFrames) do
      categoryFrame:ReleaseChildren()
    end
    self.context.categoryFrames = {}

    self.dialog:Release()
    self.dialog = nil
    self.scrollFrame = nil
    self.context = nil
  end
end

function spellsDialogModule:AddGroupScanSelector()
  -- Add settings frame with icon, icon is not clickable
  local frame = libGUI:Create("SimpleGroup")
  frame:SetLayout("Flow")
  frame:SetFullWidth(true)
  self.scrollFrame:AddChild(frame)

  local label = libGUI:Create("InteractiveLabel")
  label:SetText(buffomatModule:Color("aaaaaa", _t("label.SpellsDialog.GroupScanSelector")))
  --label:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
  label:SetWidth(label.label:GetStringWidth())
  frame:AddChild(label)

  -- Add "Watch Group #" buttons
  for i = 1, 8 do
    local toggle = ngToolboxModule:CreateToggle(
      string.format(_t("tooltip.SpellsDialog.watchGroup"), i),
      24, 20,
      texturesModule.ICON_SETTING_ON,
      texturesModule.ICON_SETTING_OFF,
      function() return BuffomatCharacter.WatchGroup[i] end,
      function(value) BuffomatCharacter.WatchGroup[i] = value end
    )
    frame:AddChild(toggle)
  end
end
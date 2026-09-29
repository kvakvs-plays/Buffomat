---@class BuffomatModule
---@field character CharacterSettings Refers to BuffomatCharacter global
---@field currentProfileName string
---@field currentProfile ProfileSettings
---@field throttleUpdateTimer table AceTimerHandle useful for canceling the timer

BINDING_HEADER_BUFFOMATHEADER = "Buffomat"
BINDING_NAME_BUFFOMAT_WINDOW = "Toggle Window"

local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local languagesModule = _t
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local characterSettingsModule = LibStub("Buffomat-CharacterSettings") --[[@as CharacterSettingsModule]]
local sharedSettingsModule = LibStub("Buffomat-SharedSettings") --[[@as SharedSettingsModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local eventsModule = LibStub("Buffomat-Events") --[[@as EventsModule]]
local macroModule = LibStub("Buffomat-Macro") --[[@as MacroModule]]
local optionsModule = LibStub("Buffomat-Options") --[[@as OptionsModule]]
local optionsPopupModule = LibStub("Buffomat-OptionsPopup") --[[@as OptionsPopupModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local popupModule = LibStub("Buffomat-Popup") --[[@as PopupModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local slashModule = LibStub("Buffomat-SlashCommands") --[[@as SlashCommandsModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]
local ngStringsModule = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]

buffomatModule.libIcon = LibStub("LibDBIcon-1.0")

---@alias CastingState "cast"|"channel"|nil

---global, visible from XML files and from script console and chat commands
---@class BomAddon : AceAddon
---@field activePaladinAura nil|number Spell id of aura if an unique aura was casted (only one can be active)
---@field activePaladinSeal nil|number Spell id of weapon seal, if an seal-type temporary enchant was used (only one can be active)
---@field ALL_PROFILES ProfileName[] Lists all buffomat profile names (group, solo... etc)
---@field buffExchangeId table<number, number[]> Combines spell ids of spellrank flavours into main spell id
---@field buffIgnoreAll number[] Having this buff on target excludes the target (phaseshifted imp for example)
---@field cachedPlayerBag BomCachedPlayerBag Items in player's bag
---@field cancelBuffs BomBuffDefinition[] All spells to be canceled on detection
---@field cancelBuffSource string Unit who casted the buff to be auto-canceled
---@field castFailedBuff BomBuffDefinition|nil Used for spell min level target detection (not available via API)
---@field castFailedBuffTarget BomUnit|nil
---@field castFailedSpellId number|nil
---@field checkCooldown number|nil Spell id to check cooldown for
---@field checkForError boolean Used by error suppression code
---@field currentProfile ProfileSettings Current profile from CharacterState.Profiles
---@field declineHasResurrection boolean Set to true on combat start, stop, holding Alt, cleared on party update
---@field drinkingPersonCount number Used for warning "X persons is/are drinking"
---@field AllDrink WowSpellId[] Used for warning "X persons is/are drinking"
---@field enchantList {[WowSpellId]: number[]} Spell ids mapping to enchantment ids
---@field forceProfile ProfileName|nil Nil will choose profile name automatically, otherwise this profile will be used
---@field forceTracking WowIconId|nil Defines icon id for enforced tracking
---@field forceUpdate boolean Requests immediate spells/buffs refresh
---@field inLoadingScreen boolean True while in the loading screen
---@field isPlayerCasting CastingState Indicates that the player is currently casting (updated in event handlers)
---@field isPlayerMoving boolean Indicated that the player is moving (updated in event handlers)
---@field itemList number[][] Group different ranks of item together
---@field lastAura BomBuffId|nil Buff id of active or last active aura
---@field lastTarget string|nil Last player's target
---@field loadingScreenTimeOut number|nil
---@field theMacro BomMacro
---@field MANA_CLASSES ClassName[] Classes with mana resource
---@field nextCooldownDue number Set this to next spell cooldown to force update
---@field isPartyUpdateNeeded boolean Requests player party update
---@field popupMenuDynamic GPIPopupDynamic
---@field repeatUpdate boolean Requests some sort of spells update similar to ForceUpdate
---@field reputationTrinketZones BomReputationTrinketZones Equipped AD trinket: Spell to and zone ids to check
---@field RESURRECT_CLASS ClassName[] Classes who can resurrect others
---@field ridingSpeedZones BomRidingSpeedZones Equipped Riding trinket: Spell to and zone ids to check
---@field SaveTargetName string|nil
---@field scanModifierKeyDown boolean Will update buffomat when modifier key is held down
---@field somebodyIsGhost boolean [unused?] Someone in the party is a ghost
---@field spellTabsCreatedFlag boolean Indicated spells tab already populated with controls
---@field wipeCachedItems boolean Command to reset cached items on the next call to itemListCacheModule; TODO move to itemListCacheModule
---@field setupAvailableSpellsFn function
-- -@field Print fun(self: BomAddon, msg: string): void
-- -@field RegisterEvent fun(self: BomAddon, event: string, handler: function): void

BuffomatAddon = LibStub("AceAddon-3.0"):NewAddon(
  "Buffomat",
  "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0"
) --[[@as BomAddon]]

local BuffomatAddon = BuffomatAddon
local libDB = LibStub("LibDataBroker-1.1")
local libIcon = LibStub("LibDBIcon-1.0")

---@class BomCachedBagItem
---@field a boolean Player has item
---@field b number Bag
---@field c number Slot
---@field d number Count

---@alias BomCachedPlayerBag table<string, BomCachedBagItem>

---@type table<string, BomCachedBagItem>
BuffomatAddon.cachedPlayerBag = {}

---Print a text with "BomDebug: " prefix in the game chat window
---@param t string
function BuffomatAddon:Debug(t)
  if BuffomatShared.DebugLogging then
    DEFAULT_CHAT_FRAME:AddMessage(tostring(GetTime()) .. " " .. buffomatModule:Color("883030", "BOM ") .. t)
  end
end

function buffomatModule:Color(hex, text)
  return "|cff" .. hex .. text .. "|r"
end

function BuffomatAddon.ScrollMessage(self, delta)
  self:SetScrollOffset(self:GetScrollOffset() + delta * 5);
  self:ResetAllFadeTimes()
end

-- Something changed (buff gained possibly?) update all spells and spell tabs
function buffomatModule.OptionsUpdate()
  throttleModule:RequestTaskRescan("optionsUpdate")
  taskScanModule:ScanTasks("OptionsUpdate")

  --spellButtonsTabModule:UpdateSpellsTab("OptionsUpdate")
  managedUiModule:UpdateAll()
  --BOM.minimapButton:UpdatePosition()
  --BOM.legacyOptions.DoCancel()
end

function buffomatModule:OptionsInit()
  LibStub("AceConfig-3.0"):RegisterOptionsTable(
    constModule.SHORT_TITLE, optionsModule:CreateOptionsTable(), {})

  self.optionsFrames = {
    general = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(
      constModule.SHORT_TITLE, _t("options.OptionsTitle"), nil)
  }
  self.optionsFrames.general.default = function()
    optionsModule:ResetDefaultOptions()
  end
end

---ChooseProfile
---BOM profile selection, using 'auto' by default
---@param profile ProfileName
function buffomatModule.ChooseProfile(profile)
  if profile == nil or profile == "" or profile == "auto" then
    BuffomatAddon.forceProfile = nil
  elseif BuffomatCharacter.profiles[profile] then
    BuffomatAddon.forceProfile = profile
  else
    BuffomatAddon:Print("Unknown profile: " .. profile)
    return
  end

  taskScanModule:ClearSkip()
  BuffomatAddon.popupMenuDynamic:Wipe(nil)
  throttleModule:RequestTaskRescan("profileSelected")
  taskScanModule:ScanTasks("profileSelected")

  buffomatModule:UseProfile(profile)
end

---@param profileName ProfileName
function buffomatModule:UseProfile(profileName)
  if buffomatModule.currentProfileName == profileName then
    return
  end

  buffomatModule.currentProfileName = profileName

  local selectedProfile = characterSettingsModule:GetProfile(profileName)
  buffomatModule.currentProfile = selectedProfile

  taskListPanelModule.titleProfile = ngStringsModule:FormatTexture(constModule.BOM_BEAR_ICON_FULLPATH) ..
      " " .. characterSettingsModule:LocalizedProfileName(profileName)
  taskListPanelModule:SetTitle()

  BuffomatAddon:Print("Using profile " .. characterSettingsModule:LocalizedProfileName(profileName))
end

---When BomCharacterState.WatchGroup has changed, update the buff tab text to show what's
---being buffed. Example: "Buff All", "Buff G3,5-7"...
function buffomatModule:UpdateBuffTabText()
  local selectedGroups = 0

  for i = 1, 8 do
    if BuffomatCharacter.WatchGroup[i] then
      selectedGroups = selectedGroups + 1
    end
  end

  if selectedGroups == 8 then
    taskListPanelModule.titleBuffGroups = _t("TabBuff")
    taskListPanelModule:SetTitle()
    --removeme
    -- PanelTemplates_TabResize(t, 0)
    return
  end

  if selectedGroups == 0 then
    taskListPanelModule.titleBuffGroups = _t("TabBuffOnlySelf")
    taskListPanelModule:SetTitle()
    --removeme
    -- PanelTemplates_TabResize(t, 0)
    return
  end

  local function endsWith(str, ending)
    return ending == "" or str:sub(- #ending) == ending
  end

  -- Build comma-separated group list to buff: "G1,2,3,5"...
  local groups = ""
  for i = 1, 8 do
    if BuffomatCharacter.WatchGroup[i] then
      --If we are adding number i, and previous (i-1) is in the string
      local prev = tostring(i - 1)
      local prev_range = "-" .. tostring(i - 1)

      if endsWith(groups, prev_range) then
        --"1-2" + "3" should become "1-3"
        groups = groups:gsub(prev_range, "") .. "-" .. tostring(i)
      else
        if endsWith(groups, prev) then
          --"1" + "2" should become "1-2"
          groups = groups .. "-" .. tostring(i)
        else
          --Otherwise: append comma (if not empty) and the number
          if #groups > 0 then
            groups = groups .. ","
          end
          groups = groups .. tostring(i)
        end
      end
    end
  end

  -- Set tab name to display groups too: "Buff G1-5" for example
  taskListPanelModule.titleBuffGroups = _t("TabBuff") .. " G" .. groups
  taskListPanelModule:SetTitle()
  --removeme
  -- PanelTemplates_TabResize(t, 0)
end

function buffomatModule:ScheduleUpdateTimer()
  -- Cancel timer if exists
  if self.throttleUpdateTimer then
    BuffomatAddon:CancelTimer(BuffomatAddon.throttleUpdateTimer)
    self.throttleUpdateTimer = nil
  end

  local interval = 0.5
  if BuffomatShared.SlowerHardware then
    interval = 1.5
  end

  self.throttleUpdateTimer = BuffomatAddon:ScheduleRepeatingTimer(throttleModule.UpdateTimer, interval)
end

function buffomatModule:InitUI()
  taskListPanelModule:ShowWindow("buffomat:InitUI")
  taskListPanelModule:CheckWindowBounds()
  self:ScheduleUpdateTimer()

  BuffomatAddon.popupMenuDynamic = popupModule:CreatePopup(buffomatModule.OptionsUpdate)

  local function onMinimapClick(_self1, button)
    if button == "LeftButton" then
      taskListPanelModule:ToggleWindow(false)
    else
      optionsPopupModule:Setup(Minimap, true)
    end
  end

  local buffomatLDB = libDB:NewDataObject("BuffomatIcon", {
    type = "data source",
    text = "Buffomat",
    icon = constModule.BOM_BEAR_ICON_FULLPATH,
    OnClick = onMinimapClick,
  })
  libIcon:Register("BuffomatIcon", buffomatLDB, BuffomatShared.Minimap)

  buffomatModule:OptionsInit()
  partyModule:InvalidatePartyCache()
  BuffomatAddon.repeatUpdate = false
end

function buffomatModule:InitGlobalStates()
  --BuffomatShared = BuffomatShared --[[@as SharedSettings]]
  --BuffomatCharacter = BuffomatCharacter --[[@as CharacterSettings]]
  if not BuffomatShared then
    BuffomatShared = sharedSettingsModule:NewDefaultSharedSettings()
  end
  if not BuffomatCharacter then
    BuffomatCharacter = characterSettingsModule:NewDefaultCharacterSettings()
  end

  if type(BuffomatShared.TargetTooLowLevel) ~= "table" then
    BuffomatShared.TargetTooLowLevel = {} --[[@as table<number, number>]]
  end

  -- Upgrade from previous Buffomat State if values are found
  if not BuffomatCharacter.profiles then
    BuffomatCharacter.profiles = {}
  end
  -- Upgrade: Move each named profile settings section into profiles table
  for _i, profileName in ipairs(profileModule.ALL_PROFILES) do
    if BuffomatCharacter[profileName] then
      BuffomatCharacter.profiles[profileName] = BuffomatCharacter[profileName]
      BuffomatCharacter[profileName] = nil
    else
      if not BuffomatCharacter.profiles[profileName] then
        BuffomatCharacter.profiles[profileName] = profileModule:New()
      end
    end
  end

  local soloProfileName = profileModule:SoloProfile()
  BuffomatAddon.currentProfile = BuffomatCharacter.profiles[soloProfileName or "solo"]
end

---@return BomSlashCommand[]
function BuffomatAddon:MakeSlashCommand()
  return --[[@as BomSlashCommand[] ]] {
    {
      command = "profile",
      description = "",
      handler = {
        {
          command = "%",
          description = _t("SlashProfile"),
          handler = buffomatModule.ChooseProfile
        }
      },
    },
    {
      command = "spellbook",
      description = _t("SlashSpellBook"),
      handler = BuffomatAddon.setupAvailableSpellsFn
    },
    {
      command = "update",
      description = _t("SlashUpdate"),
      handler = function()
        throttleModule:RequestTaskRescan("macro-/update")
        taskScanModule:ScanTasks("macro-/update")
      end
    },
    -- {
    --   command = "updatespellstab",
    --   description = "",
    --   handler = spellButtonsTabModule.UpdateSpellsTab
    -- },
    {
      command = "close",
      description = _t("SlashClose"),
      handler = function()
        taskListPanelModule:HideWindow("slash:close")
      end
    },
    {
      command = "reset",
      description = _t("SlashReset"),
      handler = function() taskListPanelModule:ResetWindow() end
    },
    {
      command = "_checkforerror",
      description = "",
      handler = function()
        if not InCombatLockdown() then
          BuffomatAddon.checkForError = true
        end
      end
    },
    {
      command = "",
      description = _t("SlashOpen"),
      handler = function() taskListPanelModule:ShowWindow("slash:show") end
    },
  }
end

---Called from event handler on Addon Loaded event
---Execution start here
function BuffomatAddon:Init()
  languagesModule:SetupTranslations()
  constModule:Init()
  allBuffsModule:SetupSpells()
  allBuffsModule:SetupCancelBuffs()

  BuffomatAddon.theMacro = macroModule:NewMacro(constModule.MACRO_NAME, nil)

  languagesModule:LocalizationInit()
  slashModule:RegisterSlashCommandHandler({ "/bom", "/buffomat" }, self:MakeSlashCommand())
  buffomatModule:InitUI()

  -- Which groups are watched by the buff scanner - save in character state
  if not BuffomatCharacter.WatchGroup then
    BuffomatCharacter.WatchGroup = {}
    for i = 1, 8 do
      BuffomatCharacter.WatchGroup[i] = true
    end
  end

  buffomatModule:UpdateBuffTabText()
  buffomatModule:RegisterBindings()
end

-- Key Binding section header and key translations (see Bindings.XML)
function buffomatModule:RegisterBindings()
  _G["BINDING_HEADER_BUFFOMATHEADER"] = "Buffomat Classic"
  _G["BINDING_NAME_MACRO Buffomat Classic"] = _t("ButtonCastBuff")
  _G["BINDING_NAME_BUFFOMAT_WINDOW"] = _t("ButtonBuffomatWindow")
end

---AceAddon handler
function BuffomatAddon:OnInitialize()
  -- do init tasks here, like loading the Saved Variables,
  -- or setting up slash commands.
  profileModule:Setup()
  buffomatModule:InitGlobalStates()
end

---AceAddon handler
function BuffomatAddon:OnEnable()
  -- Do more initialization here, that really enables the use of your addon.
  -- Register Events, Hook functions, Create Frames, Get information from
  -- the game that wasn't available in OnInitialize
  self:Init()
  eventsModule:InitEvents()

  local onClick = function(control, button)
    if button == "LeftButton" then
      taskListPanelModule:ToggleWindow(false)
    else
      optionsPopupModule:Setup(control, true)
    end
  end

  toolboxModule:AddDataBroker(constModule.BOM_BEAR_ICON_FULLPATH, onClick, nil, nil)
  buffomatModule:UseProfile(profileModule:SoloProfile())
end

---AceAddon handler
function BuffomatAddon:OnDisable()
end

---This is called from an Error Handler on UI_ERROR_MESSAGE event, when a casted spell
---fails due to the target level being too low. There is no other way to know the minimum level
---for a spell target, so we have to learn it from our failures.
function buffomatModule:OnFailedCast_LearnedDownrank()
  local failedBuff = BuffomatAddon.castFailedBuff
  local failedTarget = BuffomatAddon.castFailedBuffTarget

  if failedBuff and failedBuff.skipList and failedTarget then
    local failedTargetLevel = UnitLevel(failedTarget.unitId)

    if failedTargetLevel ~= nil and failedTargetLevel > -1 then
      if BuffomatShared.TargetTooLowLevel[BuffomatAddon.castFailedSpellId] == nil
          or BuffomatShared.TargetTooLowLevel[BuffomatAddon.castFailedSpellId] < failedTargetLevel
      then
        BuffomatShared.TargetTooLowLevel[BuffomatAddon.castFailedSpellId] = failedTargetLevel
        throttleModule:FastUpdateTimer()
        throttleModule:RequestTaskRescan("Downgrade")

        BuffomatAddon:Print(string.format(_t("error.castFailed.tooLowLevel"), failedBuff.singleText, failedTarget.name))
      elseif BuffomatShared.TargetTooLowLevel[BuffomatAddon.castFailedSpellId] >= failedTargetLevel then
        -- Failed to cast for some other reason, not too low level apparently
        BuffomatAddon.AddMemberToSkipList()
      end
    else
      BuffomatAddon.AddMemberToSkipList()
    end
  end
end

partyModule.unitAurasLastUpdated = --[[@as BomBuffUpdatesPerUnit]] {}

---@class BomUnitAuraResult
---@field name string The name of the spell or effect of the debuff. This is the name shown in yellow when you mouse over the icon
---@field icon string The path to the icon file
---@field count number The number of times the debuff has been applied to the target. Returns 0 for any debuff which doesn't stack.
---@field debuffType string The type of the debuff: Magic, Disease, Poison, Curse, or nothing for those with out a type
---@field duration number The full duration of the debuff in seconds
---@field expirationTime number The time in seconds (like what returns GetTime()) when the aura will expire.
---@field source string
---@field isStealable boolean 1 or nil depending on if the aura can be spellstolen
---@field nameplateShowPersonal boolean
---@field spellId number
---@field canApplyAura boolean
---@field isBossDebuff boolean
---@field castByPlayer boolean
---@field nameplateShowAll boolean

function buffomatModule:PrintCallers(prefix, callersCollection)
  if next(callersCollection) then
    local callers = ""
    for caller, count in pairs(callersCollection) do
      if count > 1 then
        callers = callers .. string.format("%s:%d; ", caller, count)
      else
        callers = callers .. string.format("%s; ", caller)
      end
    end
    BuffomatAddon:Print(prefix .. callers)
  end
end

local function perform_who_request(name)
  DEFAULT_CHAT_FRAME.editBox:SetText("/who " .. name)
  envModule.ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox)
end

local function perform_whisper_request(name)
  envModule.ChatFrame_OpenChat("/w " .. name .. " ")
end

function BuffomatAddon.EnterHyperlink(_control, link)
  --print(link,text)
  local part = toolboxModule:Split(link, ":")
  if part[1] == "spell" or part[1] == "unit" or part[1] == "item" then
    GameTooltip_SetDefaultAnchor(BomC_Tooltip, UIParent)
    BomC_Tooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    BomC_Tooltip:ClearLines()
    BomC_Tooltip:SetHyperlink(link)
    BomC_Tooltip:Show()
  end
end

function BuffomatAddon.LeaveHyperlink(self)
  BomC_Tooltip:Hide()
end

function BuffomatAddon.ClickHyperlink(self, link)
  local part = toolboxModule:Split(link, ":")
  if part[1] == "unit" then
    if IsShiftKeyDown() then
      perform_who_request(part[3])
      --SendWho( req.name )
    else
      perform_whisper_request(part[3])
    end
  end
end

function BuffomatAddon.MyButtonOnClick(self)
  buffomatModule:OptionsUpdate()
end
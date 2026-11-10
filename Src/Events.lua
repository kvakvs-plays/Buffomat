local BuffomatAddon = BuffomatAddon

-- Event handlers which are not scanning: auto-stand and dismount, spell setup, profile
-- switching, combat housekeeping. Events that change what a scan finds live in
-- Src/Scan/ScanEvents.lua.

---@class EventsModule
local module = LibStub("Buffomat-Events") --[[@as EventsModule]]

local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local spellSetupModule = LibStub("Buffomat-SpellSetup") --[[@as BomSpellSetupModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local scanEventsModule = LibStub("Buffomat-ScanEvents") --[[@as ScanEventsModule]]
local scanSchedulerModule = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]

--- Error messages which will make player stand if sitting.
---@enum ErrorNotStanding
module.ERR_NOT_STANDING = {
  ERR_CANTATTACK_NOTSTANDING, SPELL_FAILED_NOT_STANDING,
  ERR_LOOT_NOTSTANDING, ERR_TAXINOTSTANDING }

--- Error messages which will make player dismount if mounted.
---@enum ErrorIsMounted
module.ERR_IS_MOUNTED = {
  ERR_NOT_WHILE_MOUNTED, ERR_ATTACK_MOUNTED,
  ERR_TAXIPLAYERALREADYMOUNTED, SPELL_FAILED_NOT_MOUNTED }

--- Error messages which will make player cancel shapeshift.
---@enum ErrorIsShapeshift
module.ERR_IS_SHAPESHIFT = {
  ERR_EMBLEMERROR_NOTABARDGEOSET, ERR_CANT_INTERACT_SHAPESHIFTED,
  ERR_MOUNT_SHAPESHIFTED, ERR_NO_ITEMS_WHILE_SHAPESHIFTED,
  ERR_NOT_WHILE_SHAPESHIFTED, ERR_TAXIPLAYERSHAPESHIFTED,
  SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED,
  SPELL_FAILED_NOT_SHAPESHIFT, SPELL_NOT_SHAPESHIFTED,
  SPELL_NOT_SHAPESHIFTED_NOSPACE }

---Event_TAXIMAP_OPENED
---Will dismount player if mounted when opening taxi tab. Will stand and cancel
---shapeshift to be able to talk to the taxi NPC.
local function Event_TAXIMAP_OPENED()
  if IsMounted() then
    Dismount()
  else
    DoEmote("STAND")
    BuffomatAddon.CancelShapeShift()
  end
end

---On combat start will close the UI window and disable the UI. Will cancel the cancelable buffs.
local function Event_CombatStart()
  rosterScanModule:ForgetResurrections()
  taskListPanelModule:OnCombatStart()
  BuffomatAddon.DoCancelBuffs()
end

local function Event_CombatStop()
  taskScanModule:ClearSkip()
  rosterScanModule:ForgetResurrections()
  taskListPanelModule:OnCombatStop()
end

local oneTimeLoadItemsAndSpells = false

local function Event_LoadingStop()
  if not oneTimeLoadItemsAndSpells then
    oneTimeLoadItemsAndSpells = true
    allBuffsModule:LoadItemsAndSpells()
  end
end

---Remember the targeted friendly player for the "add current target" buttons of the
---forced and excluded target lists.
local function Event_PLAYER_TARGET_CHANGED()
  if InCombatLockdown() or envModule.IsAuraRestricted() then
    BuffomatAddon.lastTarget = nil
    return
  end
  local isBuffableUnit = UnitIsPlayer("target") or UnitIsOtherPlayersPet("target")
  local isPartyMember = UnitInParty("target") or UnitInRaid("target")

  -- Allow current party members, raid members or any player
  if isPartyMember or (isBuffableUnit and UnitIsFriend("target", "player")) then
    local name = UnitFullName("target")
    if not envModule.IsSecretValue(name) then
      BuffomatAddon.lastTarget = name
    else
      BuffomatAddon.lastTarget = nil
    end
  else
    BuffomatAddon.lastTarget = nil
  end
end

---Event_UI_ERROR_MESSAGE
---Will stand if sitting, will dismount if mounted, will cancel shapeshift, if
---shapeshifted while trying to cast a spell and that produces an error message.
---@param _errorType table
---@param message table
local function Event_UI_ERROR_MESSAGE(_, _errorType, message)
  if tContains(module.ERR_NOT_STANDING, message) then
    if BuffomatShared.AutoStand then
      UIErrorsFrame:Clear()
      DoEmote("STAND")
    end
  elseif tContains(module.ERR_IS_MOUNTED, message) then
    local flying = false -- prevent dismount in flight, OUCH!
    if envModule.haveTBC then
      flying = IsFlying() and not BuffomatShared.AutoDismountFlying
    end
    if not flying then
      if BuffomatShared.AutoDismount then
        UIErrorsFrame:Clear()
        Dismount()
      end
    end
  elseif BuffomatShared.AutoDisTravel
      and tContains(module.ERR_IS_SHAPESHIFT, message)
      and BuffomatAddon.CancelShapeShift() then
    UIErrorsFrame:Clear()
  elseif not InCombatLockdown() then
    if BuffomatAddon.checkForError then
      if message == SPELL_FAILED_LOWLEVEL then
        buffomatModule:OnFailedCast_LearnedDownrank()
      else
        BuffomatAddon.AddMemberToSkipList()
      end
    end
  end

  BuffomatAddon.checkForError = false
end

---Consumables with a required item level appear at that level, even when no spell was learned
local function Event_PLAYER_LEVEL_UP()
  spellSetupModule:RequestSetup()
end

local function Event_TALENT_GROUP_CHANGED(_newGroup, _oldGroup)
  buffomatModule:UseProfile(profileModule:ChooseProfile())
  scanSchedulerModule:Request("talentGroupChanged")
end

function module.Event_SpellsChanged()
  spellSetupModule:SetupAvailableSpells()
  scanSchedulerModule:Request("spellsChanged")
end

function module:InitEvents()
  -- After a loading screen: forget who was skipped and who was already being resurrected
  scanSchedulerModule.onLoadingEnd = function()
    taskScanModule:ClearSkip()
    rosterScanModule:ForgetResurrections()
  end
  scanEventsModule:Init()

  BuffomatAddon:RegisterEvent("PLAYER_LEVEL_UP", Event_PLAYER_LEVEL_UP)
  BuffomatAddon:RegisterEvent("TAXIMAP_OPENED", Event_TAXIMAP_OPENED)
  BuffomatAddon:RegisterEvent("PLAYER_TARGET_CHANGED", Event_PLAYER_TARGET_CHANGED)
  BuffomatAddon:RegisterEvent("UI_ERROR_MESSAGE", Event_UI_ERROR_MESSAGE)

  -- Dualspec talent switch (WotLK+, Forever). Modern clients throw on unknown events.
  if envModule.hasDualSpec and envModule.IsEventValid("ACTIVE_TALENT_GROUP_CHANGED") then
    BuffomatAddon:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Event_TALENT_GROUP_CHANGED)
  end

  -- Forever talents are trait nodes, and some grant buff spells (Oath of Light, Trueshot Aura).
  -- Rebuild the spell list when the talent loadout changes, in case SPELLS_CHANGED does not fire.
  if envModule.isForever and envModule.IsEventValid("TRAIT_CONFIG_UPDATED") then
    BuffomatAddon:RegisterEvent("TRAIT_CONFIG_UPDATED", module.Event_SpellsChanged)
  end

  -- "LEARNED_SPELL_IN_TAB" stopped working in TBC anniversary
  BuffomatAddon:RegisterEvent("SPELLS_CHANGED", module.Event_SpellsChanged)

  BuffomatAddon:RegisterEvent("PLAYER_REGEN_DISABLED", Event_CombatStart)
  BuffomatAddon:RegisterEvent("PLAYER_REGEN_ENABLED", Event_CombatStop)
  BuffomatAddon:RegisterEvent("PLAYER_ENTERING_WORLD", Event_LoadingStop)
  BuffomatAddon:RegisterEvent("LOADING_SCREEN_DISABLED", Event_LoadingStop)
end

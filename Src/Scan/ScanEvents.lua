local addonName, ns = ...

-- Game events which change what a scan would find. A handler only marks the domain it
-- affects as dirty in the scheduler; it never scans. See .agents/scan-plan.md section 4.

---@class ScanEventsModule
---@field dispatcher KvEventDispatcher
---@field isPlayerInGroup boolean Group membership at the last roster event
---@field outsiderName string? Name of the targeted player outside the group, with BuffTarget on
---@field aurasForGroup boolean? UNIT_AURA is registered for all units, not only the player and pet
local module = LibStub("Buffomat-ScanEvents") --[[@as ScanEventsModule]]

local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvEventsModule = LibStub("KvLibShared-Events") --[[@as KvEventsModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
local scheduler = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local taskListModule = LibStub("Buffomat-TaskList") --[[@as TaskListModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]

module.isPlayerInGroup = false

---Whether the scan reads this unit. Unit events also fire for nameplates, the focus
---and strangers; those must cost one table lookup and nothing else.
---@param unitId string?
---@return boolean
local function isScannedUnit(unitId)
  if unitId == "player" or unitId == "pet" then
    return true
  end
  local party = partyModule.theParty
  return unitId ~= nil and party ~= nil and party.byUnitId[unitId] ~= nil
end

local function onRosterChanged()
  partyModule:InvalidatePartyCache()
  partyModule.theParty = nil
  scheduler:MarkDirty("roster")
  module:RegisterAuraEvent()

  local inGroup = kvUnitModule.IsInGroup()
  if module.isPlayerInGroup ~= inGroup then
    module.isPlayerInGroup = inGroup
    if not inGroup then
      taskScanModule:MaybeResetWatchGroups()
    end
  end
end

---@param unitId string Owner of the pet
local function onUnitPet(_event, unitId)
  if isScannedUnit(unitId) then
    scheduler:MarkDirty("roster")
  end
end

---@param unitId string
local function onUnitAura(_event, unitId)
  if not isScannedUnit(unitId) then
    return
  end
  scheduler:MarkUnit(unitId)
  if unitId == "player" then
    scheduler:MarkDirty("player") -- mounts, stealth and forms are auras too
  end
end

---@param unitId string
local function onUnitStatus(_event, unitId)
  if isScannedUnit(unitId) then
    scheduler:MarkDirty("status", unitId)
  end
end

local function onPlayerLifeChanged()
  scheduler:MarkUnit("player")
  scheduler:MarkDirty("player")
end

local function onReadyCheck()
  scheduler:MarkDirty("auras")
  scheduler:MarkDirty("status")
end

local function onBagsChanged()
  BuffomatAddon.wipeCachedItems = true
  if BuffomatAddon.cachedPlayerBag then
    wipe(BuffomatAddon.cachedPlayerBag)
  end
  scheduler:MarkDirty("bags")
  scheduler:MarkDirty("bagCooldowns")
end

local function onBagCooldown()
  scheduler:MarkDirty("bagCooldowns")
end

local function onWeaponChanged()
  scheduler:MarkDirty("weapon")
end

local function onPlayerStateChanged()
  scheduler:MarkDirty("player")
end

---Members are compared with the player's zone, so every status is stale in a new zone.
local function onZoneChanged()
  scheduler:MarkDirty("player")
  scheduler:MarkDirty("status")
end

---@param powerType string
local function onPlayerPower(_event, _unitId, powerType)
  if powerType ~= "MANA" then
    return
  end
  -- Only interesting once there is enough mana for the cheapest spell that was too expensive
  local mana = envModule.UnitPower("player", 0)
  if mana ~= nil and (partyModule.playerManaLimit or 0) <= mana then
    scheduler:MarkDirty("player")
  end
end

---@param event string
local function onCastStart(event)
  playerStateModule.casting = event == "UNIT_SPELLCAST_CHANNEL_START" and "channel" or "cast"
  if not InCombatLockdown() then
    -- Keeps the same macro from casting again when the player mashes the key
    taskListModule:WipeMacro(nil)
  end
  scheduler:MarkDirty("settings")
end

local function onCastStop()
  playerStateModule.casting = nil
  BuffomatAddon.checkForError = false
  scheduler:MarkDirty("settings")
  scheduler:MarkDirty("player") -- mana was spent
end

local function onCastResult()
  BuffomatAddon.checkForError = false
  scheduler:MarkDirty("settings")
  scheduler:MarkDirty("player")
end

---With the BuffTarget option a targeted player outside the group is scanned like a member.
local function onTargetChanged()
  if not BuffomatShared.BuffTarget then
    return
  end
  local name
  if kvUnitModule.IsBuffableOutsider("target") then
    name = kvUnitModule.GetName("target")
  end
  if name ~= module.outsiderName then
    module.outsiderName = name
    scheduler:MarkDirty("roster")
    scheduler:MarkUnit("target")
  end
end

---Tasks which wait for a held modifier key change with the key. Alt also means
---"try again": the pass forgets skipped members and declined resurrections.
local function onModifierChanged()
  if BuffomatAddon.scanModifierKeyDown or kvPlayerModule.IsAltKeyDown() then
    scheduler:MarkAllDirty("modifierKey")
  end
end

local function onCombatStart()
  scheduler:OnCombatStart()
  -- Auras change constantly in combat and nothing is read until it ends
  module.dispatcher:Off("UNIT_AURA")
end

local function onCombatEnd()
  module:RegisterAuraEvent()
  scheduler:OnCombatEnd()
end

local function onLoadingStart()
  scheduler:OnLoadingStart()
end

local function onLoadingEnd()
  scheduler:OnLoadingEnd(constModule.LOADING_SCREEN_TIMEOUT)
end

local function onRestrictionChanged()
  -- Nothing is read here: during this event the restriction which is about to begin
  -- still reports inactive. The pass runs from the scheduler timer.
  partyModule:InvalidatePartyCache()
  scheduler:MarkAllDirty("restrictionChanged")
end

---Alone, only the player and pet matter and the client can filter for them. In a group,
---or when a target outside the group is buffed, every unit event arrives and is filtered
---by the roster.
function module:RegisterAuraEvent()
  local forGroup = kvUnitModule.IsInGroup() or BuffomatShared.BuffTarget == true
  if forGroup == self.aurasForGroup and self.dispatcher:IsRegistered("UNIT_AURA") then
    return
  end
  self.aurasForGroup = forGroup
  if forGroup then
    self.dispatcher:On("UNIT_AURA", onUnitAura)
  else
    self.dispatcher:OnUnit("UNIT_AURA", onUnitAura, "player", "pet")
  end
end

---Register the scan events. Called once, when the addon is enabled.
function module:Init()
  local dispatcher = kvEventsModule.NewDispatcher()
  self.dispatcher = dispatcher
  self.isPlayerInGroup = kvUnitModule.IsInGroup()

  -- Roster
  for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "GROUP_JOINED", "GROUP_LEFT", "RAID_ROSTER_UPDATE",
    "PLAYER_ROLES_ASSIGNED" }) do
    dispatcher:On(event, onRosterChanged)
  end
  dispatcher:On("UNIT_PET", onUnitPet)

  -- Auras and member status
  self:RegisterAuraEvent()
  dispatcher:On("UNIT_CONNECTION", onUnitStatus)
  dispatcher:On("INCOMING_RESURRECT_CHANGED", onUnitStatus)
  for _, event in ipairs({ "PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_UNGHOST" }) do
    dispatcher:On(event, onPlayerLifeChanged)
  end
  dispatcher:On("READY_CHECK", onReadyCheck)

  -- Bags. Whether BAG_UPDATE_DELAYED follows every change differs between clients, so both
  -- are taken; a burst of BAG_UPDATE still becomes one pass.
  dispatcher:On("BAG_UPDATE_DELAYED", onBagsChanged)
  dispatcher:On("BAG_UPDATE", onBagsChanged)
  dispatcher:On("TRADE_CLOSED", onBagsChanged)
  dispatcher:On("BAG_UPDATE_COOLDOWN", onBagCooldown)

  -- Weapons and their temporary enchants
  dispatcher:OnUnit("UNIT_INVENTORY_CHANGED", onWeaponChanged, "player")
  dispatcher:On("PLAYER_EQUIPMENT_CHANGED", onWeaponChanged)
  dispatcher:On("WEAPON_ENCHANT_CHANGED", onWeaponChanged)

  -- Player state
  for _, event in ipairs({ "UPDATE_SHAPESHIFT_FORM", "PLAYER_UPDATE_RESTING", "ZONE_CHANGED_INDOORS",
    "MINIMAP_UPDATE_TRACKING", "PLAYER_MOUNT_DISPLAY_CHANGED" }) do
    dispatcher:On(event, onPlayerStateChanged)
  end
  dispatcher:On("ZONE_CHANGED", onZoneChanged)
  dispatcher:On("ZONE_CHANGED_NEW_AREA", onZoneChanged)
  dispatcher:OnUnit("UNIT_ENTERED_VEHICLE", onPlayerStateChanged, "player")
  dispatcher:OnUnit("UNIT_EXITED_VEHICLE", onPlayerStateChanged, "player")
  dispatcher:OnUnit("UNIT_POWER_UPDATE", onPlayerPower, "player")

  -- Casting
  dispatcher:OnUnit("UNIT_SPELLCAST_START", onCastStart, "player")
  dispatcher:OnUnit("UNIT_SPELLCAST_CHANNEL_START", onCastStart, "player")
  dispatcher:OnUnit("UNIT_SPELLCAST_STOP", onCastStop, "player")
  dispatcher:OnUnit("UNIT_SPELLCAST_CHANNEL_STOP", onCastStop, "player")
  for _, event in ipairs({ "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_INTERRUPTED", "UNIT_SPELLCAST_FAILED" }) do
    dispatcher:OnUnit(event, onCastResult, "player")
  end

  dispatcher:On("PLAYER_TARGET_CHANGED", onTargetChanged)
  dispatcher:On("MODIFIER_STATE_CHANGED", onModifierChanged)

  -- Gates
  dispatcher:On("PLAYER_REGEN_DISABLED", onCombatStart)
  dispatcher:On("PLAYER_REGEN_ENABLED", onCombatEnd)
  dispatcher:On("LOADING_SCREEN_ENABLED", onLoadingStart)
  dispatcher:On("PLAYER_LEAVING_WORLD", onLoadingStart)
  dispatcher:On("PLAYER_ENTERING_WORLD", onLoadingEnd)
  dispatcher:On("LOADING_SCREEN_DISABLED", onLoadingEnd)
  if envModule.supportsAuraRestrictions then
    dispatcher:On("ADDON_RESTRICTION_STATE_CHANGED", onRestrictionChanged)
  end
end

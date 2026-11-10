local addonName, ns = ...

-- One run of the scan pipeline, started by the scheduler:
--
--   gate -> profile -> read what is dirty -> (nothing changed? stop) -> active? ->
--   evaluate who needs what -> build tasks -> side effects -> present -> schedule
--
-- Reading is incremental; evaluation and the task list are redone in full whenever a
-- snapshot changed, because they are cheap table work. See .agents/scan-plan.md.

---@class ScanPassSeenVersions
---@field roster number
---@field auras number
---@field bags number
---@field player number
---@field auraFree boolean?

---@class ScanPassModule
---@field result BomScanResult What the last evaluation worked out
---@field tasklist BomTaskList The task list, rebuilt by every evaluation
---@field seen ScanPassSeenVersions Snapshot versions the last evaluation was made from
---@field wasActive boolean The last evaluation found Buffomat active
local module = LibStub("Buffomat-ScanPass") --[[@as ScanPassModule]]

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local auraScanModule = LibStub("Buffomat-AuraScan") --[[@as AuraScanModule]]
local bagScanModule = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local rangeScanModule = LibStub("Buffomat-RangeScan") --[[@as RangeScanModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local scanEffectsModule = LibStub("Buffomat-ScanEffects") --[[@as ScanEffectsModule]]
local scanEvaluateModule = LibStub("Buffomat-ScanEvaluate") --[[@as ScanEvaluateModule]]
local scanEventsModule = LibStub("Buffomat-ScanEvents") --[[@as ScanEventsModule]]
local scanResultModule = LibStub("Buffomat-ScanResult") --[[@as ScanResultModule]]
local scanStatsModule = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]
local scheduler = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local taskBuilderModule = LibStub("Buffomat-TaskBuilder") --[[@as TaskBuilderModule]]
local taskListModule = LibStub("Buffomat-TaskList") --[[@as TaskListModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]

module.seen = { roster = -1, auras = -1, bags = -1, player = -1 }
module.wasActive = false

---Read the domains which are dirty into their snapshots.
---@param pending BomScanDirtyFlags
---@param pendingUnits BomScanDirtyUnits
---@param auraFree boolean
---@return boolean more Units are still queued for an aura read
function module:Read(pending, pendingUnits, auraFree)
  if pending.roster or rosterScanModule.playerOnly ~= auraFree then
    rosterScanModule:Rebuild(pendingUnits, auraFree)
  end
  local roster = rosterScanModule.roster
  if roster.player == nil then
    return false
  end

  if pending.status then
    rosterScanModule:ReadStatuses(true, false, pendingUnits.status)
  elseif pending.deadWatch or next(pendingUnits.status) ~= nil then
    rosterScanModule:ReadStatuses(false, pending.deadWatch == true, pendingUnits.status)
  end

  local more = false
  if auraFree then
    auraScanModule:SetAuraFree(roster)
  else
    auraScanModule:Enqueue(roster, pending.auras == true, pendingUnits.auras)
    more = auraScanModule:ReadQueued(roster)
  end

  if pending.player or playerStateModule.version == 0 then
    playerStateModule:Read()
  end
  if pending.weapon then
    playerStateModule:ReadEquipment(roster.player)
    if playerStateModule.enchantExpiresAt then
      -- The end of a weapon enchant does not reliably send an event
      scheduler:WakeAt(playerStateModule.enchantExpiresAt + 0.5, "weapon")
    end
  end

  if pending.bags or bagScanModule:NeedsRead() then
    bagScanModule:Read()
  end
  if pending.bagCooldowns then
    bagScanModule:InvalidateCooldowns()
  end
  return more
end

---Whether anything an evaluation looks at changed since the last one.
---@param pending BomScanDirtyFlags
---@param auraFree boolean
---@return boolean
function module:HasChanged(pending, auraFree)
  local seen = self.seen
  -- Settings, and range and deadlines which arrive as "settings", have no snapshot to compare
  if pending.settings or pending.range then
    return true
  end
  return seen.roster ~= rosterScanModule.roster.version
      or seen.auras ~= auraScanModule.version
      or seen.bags ~= bagScanModule.version
      or seen.player ~= playerStateModule.version
      or seen.auraFree ~= auraFree
end

---@param auraFree boolean
function module:RememberVersions(auraFree)
  local seen = self.seen
  seen.roster, seen.auras = rosterScanModule.roster.version, auraScanModule.version
  seen.bags, seen.player = bagScanModule.version, playerStateModule.version
  seen.auraFree = auraFree
end

---Show why nothing is being done, on the cast button.
---@param reason string
function module:ShowInactive(reason)
  BuffomatAddon.checkForError = false
  BuffomatAddon.theMacro:Clear()
  taskListPanelModule:CastButtonText(reason, false)
end

---Show the task list and put the first castable task on the cast button and macro.
---@param hadTasks boolean The list had tasks before this evaluation
---@param auraFree boolean
function module:Present(hadTasks, auraFree)
  local tasklist = self.tasklist
  scanStatsModule:Count("presents")

  if #tasklist.tasks > 0 or #tasklist.comments > 0 then
    taskListPanelModule:AutoShow("pass:haveTasks")
    if not hadTasks then
      scanEffectsModule:PlayTaskSound() -- only when tasks appear, not while they stay
    end
  end

  tasklist:Sort()
  tasklist:Display()

  local firstToCast = tasklist:SelectTask()
  if firstToCast then
    tasklist:CastButton(firstToCast)
  else
    taskListPanelModule:AutoHide("pass:nothing")
    tasklist:CastButton_Nothing()
    if auraFree then
      -- "Nothing to do" would suggest that everyone is buffed
      taskListPanelModule:CastButtonText(_t("castButton.inactive.PvPMatch"), false)
    end
  end
end

---Stages 5 to 9: decide, build, act, show.
---@param roster BomRoster
---@param auraFree boolean
---@return boolean active False when Buffomat is paused (resting, mounted, casting...)
function module:Evaluate(roster, auraFree)
  scanStatsModule:Count("evaluations")
  if self.tasklist == nil then
    self.tasklist = taskListModule:New()
    self.result = scanResultModule:New()
  end
  local tasklist, result = self.tasklist, self.result
  local hadTasks = #tasklist.tasks > 0
  tasklist:Clear()
  playerStateModule.manaWakeLimit = nil
  rangeScanModule:BeginPass()

  local reason, mayHideWindow = scanEvaluateModule:GetInactiveReason(roster, auraFree)
  if reason then
    self:ShowInactive(reason)
    if mayHideWindow and BuffomatShared.HideWhenScanBlocked and taskListPanelModule:IsWindowVisible() then
      taskListPanelModule:AutoHide("pass:inactive", true)
    end
    scanEventsModule:SetManaWatch(playerStateModule.manaWakeLimit ~= nil)
    return false
  end

  if auraFree then
    scanEffectsModule:NotifyPvPMatchOnce()
  end
  scanEvaluateModule:Evaluate(roster, result, auraFree)
  taskBuilderModule:Build(tasklist, roster, result, auraFree)
  scanEffectsModule:Run(result, roster.player)
  self:Present(hadTasks, auraFree)

  -- Events which only matter while a task waits for them
  scanEventsModule:SetManaWatch(playerStateModule.manaWakeLimit ~= nil)
  scanEventsModule.modifierWatch = result.needsModifierKey
  return true
end

---Timers which stand in for events the game does not send.
---@param roster BomRoster
function module:ArmWatchTimers(roster)
  if not self.wasActive then
    -- Paused: events are still read, but nothing is polled
    scheduler:CancelWake("deadWatch")
    scheduler:CancelWake("auras")
    scheduler:CancelWake("status")
    scheduler:CancelWake("range")
    return
  end
  if roster.hasDead then
    -- A resurrection by somebody else has no event
    scheduler:WakeAfter(scheduler.DEAD_WATCH, "deadWatch")
  end
  if #roster.units > 1 then
    -- Insurance against an aura or zone change of a far-away member which sent no event
    scheduler:WakeAfter(scheduler.RESYNC, "auras")
    scheduler:WakeAfter(scheduler.RESYNC, "status")
  end
end

---@param pending BomScanDirtyFlags Domains to read in this pass
---@param pendingUnits BomScanDirtyUnits Units to read in this pass
---@return BomScanPassResult
function module:Run(pending, pendingUnits)
  -- Window show and hide requests wait for a pass, because a pass never runs in combat
  taskListPanelModule:WindowCommand()

  -- Gate. A PvP match hides auras but still allows the tasks which do not read them.
  -- Any other restriction hides too much to decide anything.
  local restriction = envModule.GetAuraRestriction()
  local auraFree = restriction == "PvPMatch"
  if restriction ~= nil and not auraFree then
    self:ShowInactive(_t("castButton.inactive.AuraDataUnavailable"))
    return "blocked"
  end

  scanEventsModule:RegisterAuraEvent() -- the BuffTarget option changes which units are heard

  if pending.roster or pending.player or pending.settings then
    buffomatModule:UseProfile(profileModule:ChooseProfile())
  end

  local more = self:Read(pending, pendingUnits, auraFree)
  local roster = rosterScanModule.roster
  if roster.player == nil then
    return "blocked"
  end
  if more then
    -- Deciding on a half-read group would show tasks for buffs which are only unread
    return "continue"
  end

  if self:HasChanged(pending, auraFree) then
    self:RememberVersions(auraFree)
    self.wasActive = self:Evaluate(roster, auraFree)
  end
  self:ArmWatchTimers(roster)

  taskListPanelModule:WindowCommand() -- the pass may have asked to show or hide the window
  return nil
end

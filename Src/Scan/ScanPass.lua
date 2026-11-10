local addonName, ns = ...

-- One run of the scan pipeline, started by the scheduler: read what is dirty, work
-- out who needs which buff, build the task list and present it.

---@class ScanPassModule
local module = LibStub("Buffomat-ScanPass") --[[@as ScanPassModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local auraScanModule = LibStub("Buffomat-AuraScan") --[[@as AuraScanModule]]
local bagScanModule = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local scanEventsModule = LibStub("Buffomat-ScanEvents") --[[@as ScanEventsModule]]
local scheduler = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]

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
    if pending.weapon then
      pendingUnits.auras.player = true -- weapon enchants are stored with the player's buffs
    end
    auraScanModule:Enqueue(roster, pending.auras == true, pendingUnits.auras)
    more = auraScanModule:ReadQueued(roster)
  end

  -- Until the range reader is split out, every pass measures every unit
  for _, unit in ipairs(roster.units) do
    unit.distance = kvUnitModule.DistanceSquared(unit.unitId)
  end

  if pending.bags or bagScanModule:NeedsRead() then
    bagScanModule:Read()
  end
  if pending.bagCooldowns then
    bagScanModule:InvalidateCooldowns()
  end
  return more
end

---@param pending BomScanDirtyFlags Domains to read in this pass
---@param pendingUnits BomScanDirtyUnits Units to read in this pass
---@return BomScanPassResult
function module:Run(pending, pendingUnits)
  -- Window show and hide requests wait for a pass, because a pass never runs in combat
  taskListPanelModule:WindowCommand()

  -- A PvP match hides auras but still allows the tasks which do not read them. Any
  -- other restriction hides too much to decide anything.
  local restriction = envModule.GetAuraRestriction()
  local auraFree = restriction == "PvPMatch"
  if restriction ~= nil and not auraFree then
    taskScanModule:ShowInactive(_t("castButton.inactive.AuraDataUnavailable"))
    return "blocked"
  end

  scanEventsModule:RegisterAuraEvent() -- the BuffTarget option changes which units are heard

  local more = self:Read(pending, pendingUnits, auraFree)
  local roster = rosterScanModule.roster
  if roster.player == nil then
    return "blocked"
  end
  if more then
    -- Deciding on a half-read group would show tasks for buffs which are only unread
    return "continue"
  end

  local active = taskScanModule:ScanTasks(roster, auraFree)

  if active then
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

  taskListPanelModule:WindowCommand() -- the pass may have asked to show or hide the window
  return nil
end

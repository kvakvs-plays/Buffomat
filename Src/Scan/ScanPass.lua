local addonName, ns = ...

-- One run of the scan pipeline, started by the scheduler: read what is dirty, work
-- out who needs which buff, build the task list and present it.

---@class ScanPassModule
local module = LibStub("Buffomat-ScanPass") --[[@as ScanPassModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local bagScanModule = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local scanEventsModule = LibStub("Buffomat-ScanEvents") --[[@as ScanEventsModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]

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

  if pending.roster or rosterScanModule.playerOnly ~= auraFree then
    rosterScanModule:Rebuild(pendingUnits, auraFree)
  end
  local roster = rosterScanModule.roster
  if roster.player == nil then
    return "blocked"
  end

  -- Until the aura reader is split out, every pass re-reads every unit
  local playerMapId = kvUnitModule.GetMapId("player")
  BuffomatAddon.drinkingPersonCount = 0
  for _, unit in ipairs(roster.units) do
    unit:UpdateBuffs(roster, playerMapId)
  end
  BuffomatAddon.declineHasResurrection = false

  if pending.bags or bagScanModule:NeedsRead() then
    bagScanModule:Read()
  end
  if pending.bagCooldowns then
    bagScanModule:InvalidateCooldowns()
  end

  taskScanModule:ScanTasks(roster, auraFree)

  taskListPanelModule:WindowCommand() -- the pass may have asked to show or hide the window
  return nil
end

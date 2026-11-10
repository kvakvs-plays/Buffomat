local addonName, ns = ...

-- One run of the scan pipeline, started by the scheduler: read what is dirty, work
-- out who needs which buff, build the task list and present it.

---@class ScanPassModule
local module = LibStub("Buffomat-ScanPass") --[[@as ScanPassModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]

---@param _pending BomScanDirtyFlags Domains to read in this pass
---@param _pendingUnits BomScanDirtyUnits Units to read in this pass
---@return BomScanPassResult
function module:Run(_pending, _pendingUnits)
  -- Window show and hide requests wait for a pass, because a pass never runs in combat
  taskListPanelModule:WindowCommand()

  -- Until the readers are split by domain, any change re-reads the whole group
  partyModule:InvalidatePartyCache()
  taskScanModule:ScanTasks("pass")

  taskListPanelModule:WindowCommand() -- the pass may have asked to show or hide the window
  return nil
end

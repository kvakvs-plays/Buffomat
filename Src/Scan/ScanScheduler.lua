local addonName, ns = ...

-- Decides when a scan pass runs. Game events and UI code never scan; they mark a
-- domain dirty here, and one one-shot timer starts the pass. No timer is armed while
-- nothing is pending, in combat, or behind a loading screen. See .agents/scan-plan.md.

---One independently invalidated piece of game state.
--- - roster: who is in the group
--- - status: dead / ghost / connected / zone, per unit
--- - auras: buffs, per unit
--- - bags / bagCooldowns: bag contents and item cooldowns
--- - weapon: temporary weapon enchants and the equipped weapons
--- - player: form, mount, resting, zone, tracking, mana
--- - range: distances to units with a pending task
--- - deadWatch: status of the dead members only (a resurrection has no event)
--- - settings: nothing to read, but the task list must be evaluated again
---@alias BomScanDomain "roster"|"status"|"auras"|"bags"|"bagCooldowns"|"weapon"|"player"|"range"|"deadWatch"|"settings"

---What a pass tells the scheduler when it returns.
--- - nil: done
--- - "continue": more units are queued for reading; run again soon
--- - "blocked": nothing could be done; wait for the event that lifts the block
---@alias BomScanPassResult "continue"|"blocked"|nil

---@alias BomScanDirtyFlags table<BomScanDomain, boolean>
---@alias BomScanDirtyUnits {auras: table<string, boolean>, status: table<string, boolean>}

---@class ScanSchedulerModule
---@field dirty BomScanDirtyFlags Whole domains marked since the last pass started
---@field dirtyUnits BomScanDirtyUnits Unit ids marked since the last pass started
---@field pending BomScanDirtyFlags Input of the running pass
---@field pendingUnits BomScanDirtyUnits Input of the running pass
---@field wakeTimes table<BomScanDomain, number> Absolute time at which a domain becomes dirty by itself
---@field started boolean False until the addon UI is ready
---@field loading boolean True behind a loading screen and for a short grace time after it
---@field inPass boolean
---@field continuePass boolean? The last pass left units queued; run again even with nothing dirty
---@field lastPassAt number GetTime() when the last pass started
---@field timer table? AceTimer handle of the armed pass timer
---@field timerAt number? Absolute time the armed timer fires at
---@field graceTimer table? AceTimer handle of the loading-screen grace timer
---@field onLoadingEnd fun()? Called when the grace time after a loading screen is over
local module = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local scanPassModule = LibStub("Buffomat-ScanPass") --[[@as ScanPassModule]]
local scanStatsModule = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]

-- Seconds. The SlowerHardware option doubles all of them.
module.COALESCE = 0.1      -- from the first mark to the pass; folds an event burst into one pass
module.MIN_GAP = 0.2       -- between pass starts
module.CONTINUATION = 0.05 -- to the next pass while units are still queued for reading
module.RANGE_TICK = 1.0    -- between range checks while a task waits for range
module.DEAD_WATCH = 2.0    -- between status checks of dead members
module.RESYNC = 30         -- between full aura and status re-reads in a group

local EPSILON = 0.001

---@type BomScanDomain[]
local DOMAINS = { "roster", "status", "auras", "bags", "bagCooldowns", "weapon", "player", "range", "deadWatch",
  "settings" }
-- Marking everything re-reads everything; deadWatch is a subset of status
local READ_DOMAINS = { "roster", "status", "auras", "bags", "bagCooldowns", "weapon", "player", "range", "settings" }

module.dirty = {}
module.dirtyUnits = { auras = {}, status = {} }
module.pending = {}
module.pendingUnits = { auras = {}, status = {} }
module.wakeTimes = {}
module.started = false
module.loading = false
module.inPass = false
module.lastPassAt = 0

---@param seconds number
---@return number seconds Doubled on slower hardware
function module:Interval(seconds)
  if BuffomatShared and BuffomatShared.SlowerHardware then
    return seconds * 2
  end
  return seconds
end

---Passes run only out of combat and away from loading screens.
---@return boolean
function module:IsOpen()
  return self.started and not self.loading and not InCombatLockdown()
end

---@return boolean
function module:HasDirty()
  for _, domain in ipairs(DOMAINS) do
    if self.dirty[domain] then
      return true
    end
  end
  return next(self.dirtyUnits.auras) ~= nil or next(self.dirtyUnits.status) ~= nil
end

function module:CancelTimer()
  if self.timer then
    BuffomatAddon:CancelTimer(self.timer)
    self.timer, self.timerAt = nil, nil
  end
end

---Arm the pass timer, unless it is already armed for an earlier time.
---@param delay number Seconds from now
---@param ignoreGap boolean? Continuation passes may follow closer than the minimum gap
function module:SchedulePass(delay, ignoreGap)
  if not self:IsOpen() or self.inPass then
    return -- the event which opens the gate, or the end of the pass, schedules
  end
  local now = GetTime()
  local at = now + delay
  if not ignoreGap then
    at = math.max(at, self.lastPassAt + self:Interval(self.MIN_GAP))
  end
  if self.timer and self.timerAt <= at + EPSILON then
    return
  end
  self:CancelTimer()
  self.timerAt = at
  self.timer = BuffomatAddon:ScheduleTimer(module.OnTimer, math.max(at - now, 0.01))
end

---Mark a domain dirty and make sure a pass is scheduled.
---@param domain BomScanDomain
---@param key string? Unit id for "auras" and "status"; nil marks the whole domain
function module:MarkDirty(domain, key)
  if key ~= nil then
    self.dirtyUnits[domain][key] = true
  else
    self.dirty[domain] = true
  end
  self:SchedulePass(self:Interval(self.COALESCE))
end

---A unit's auras changed. Its status is read with them: death and resurrection have no
---cheap event of their own, but both change the auras.
---@param unitId string
function module:MarkUnit(unitId)
  self.dirtyUnits.auras[unitId] = true
  self.dirtyUnits.status[unitId] = true
  self:SchedulePass(self:Interval(self.COALESCE))
end

---Mark everything dirty: combat end, loading end, restriction change, full resync.
---@param reason string Shown by /bom scanstats
function module:MarkAllDirty(reason)
  scanStatsModule:Reason(reason)
  for _, domain in ipairs(READ_DOMAINS) do
    self.dirty[domain] = true
  end
  self:SchedulePass(self:Interval(self.COALESCE))
end

---Settings or UI changed: the task list is evaluated again without reading anything.
---@param reason string Shown by /bom scanstats
function module:Request(reason)
  scanStatsModule:Reason(reason)
  self:MarkDirty("settings")
end

---Make a domain dirty at a time in the future: a buff reaching its rebuff time, a
---cooldown ending. Asking again for a later time does not postpone it.
---@param time number Absolute time, GetTime() based
---@param domain BomScanDomain? Defaults to "settings", which only evaluates again
function module:WakeAt(time, domain)
  domain = domain or "settings"
  local known = self.wakeTimes[domain]
  if known == nil or time < known then
    self.wakeTimes[domain] = time
    if not self.inPass then
      self:SchedulePass(time - GetTime())
    end
  end
end

---@param seconds number From now; scaled for slower hardware
---@param domain BomScanDomain
function module:WakeAfter(seconds, domain)
  self:WakeAt(GetTime() + self:Interval(seconds), domain)
end

---Forget a wake time; the armed timer may still fire and will find nothing to do.
---@param domain BomScanDomain
function module:CancelWake(domain)
  self.wakeTimes[domain] = nil
end

---Turn wake times which have come due into dirty domains.
---@param now number
function module:FireWakes(now)
  for domain, at in pairs(self.wakeTimes) do
    if at <= now + EPSILON then
      self.wakeTimes[domain] = nil
      self.dirty[domain] = true
      scanStatsModule:Reason("wake:" .. domain)
    end
  end
end

---Marks made from here on belong to the next pass; the running pass reads `pending`.
function module:BeginPass()
  self.pending, self.dirty = self.dirty, self.pending
  self.pendingUnits, self.dirtyUnits = self.dirtyUnits, self.pendingUnits
  wipe(self.dirty)
  wipe(self.dirtyUnits.auras)
  wipe(self.dirtyUnits.status)
end

---A blocked pass did not consume its input; keep it for the pass after the block lifts.
function module:RestorePending()
  for domain, isDirty in pairs(self.pending) do
    if isDirty then
      self.dirty[domain] = true
    end
  end
  for unitId in pairs(self.pendingUnits.auras) do
    self.dirtyUnits.auras[unitId] = true
  end
  for unitId in pairs(self.pendingUnits.status) do
    self.dirtyUnits.status[unitId] = true
  end
end

---Timer callback: run a pass if anything is dirty, then arm the next timer.
function module.OnTimer()
  local self = module
  self.timer, self.timerAt = nil, nil
  if not self:IsOpen() then
    return
  end

  local now = GetTime()
  self:FireWakes(now)

  local result ---@type BomScanPassResult
  if self:HasDirty() or self.continuePass then
    self.continuePass = false
    self.lastPassAt = now
    self:BeginPass()
    self.inPass = true
    scanStatsModule:PassBegin()
    result = scanPassModule:Run(self.pending, self.pendingUnits)
    scanStatsModule:PassEnd()
    self.inPass = false
  end

  if result == "blocked" then
    self:RestorePending()
    return
  elseif result == "continue" then
    self.continuePass = true
    self:SchedulePass(self:Interval(self.CONTINUATION), true)
  elseif self:HasDirty() then
    self:SchedulePass(self:Interval(self.COALESCE))
  else
    local earliest
    for _, at in pairs(self.wakeTimes) do
      if earliest == nil or at < earliest then
        earliest = at
      end
    end
    if earliest then
      self:SchedulePass(earliest - GetTime())
    end
  end
end

---The addon UI is ready; the first pass reads everything.
function module:Start()
  self.started = true
  self:MarkAllDirty("start")
end

function module:OnCombatStart()
  self:CancelTimer()
end

function module:OnCombatEnd()
  self:MarkAllDirty("combatEnd")
end

function module:OnLoadingStart()
  self.loading = true
  self:CancelTimer()
  if self.graceTimer then
    BuffomatAddon:CancelTimer(self.graceTimer)
    self.graceTimer = nil
  end
end

---The world is not ready right after a loading screen: unit and item data arrive a
---moment later. The gate opens after a grace time.
---@param graceSeconds number
function module:OnLoadingEnd(graceSeconds)
  if self.graceTimer then
    BuffomatAddon:CancelTimer(self.graceTimer)
  end
  self.loading = true
  self.graceTimer = BuffomatAddon:ScheduleTimer(function()
    self.graceTimer = nil
    self.loading = false
    if self.onLoadingEnd then
      self.onLoadingEnd()
    end
    self:MarkAllDirty("loadingEnd")
  end, graceSeconds)
end

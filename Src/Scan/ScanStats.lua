local addonName, ns = ...

-- Counters for measuring the scan loop: how often a pass runs, why, how long it takes
-- and how many game API reads it makes. Collected only with debug logging enabled;
-- printed by `/bom scanstats`.

---@class ScanStatsModule
---@field enabled boolean Mirrors BuffomatShared.DebugLogging, refreshed at the start of each pass
---@field counters table<string, number> Event counts since the last reset
---@field reasons table<string, number> Why passes were requested, with counts
---@field since number GetTime() of the last reset
---@field passMsTotal number Milliseconds spent in passes since the last reset
---@field passMsMax number Longest pass in milliseconds since the last reset
---@field passStartedAt number Profile clock at the start of the running pass
local module = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]

module.enabled = false
module.counters = {}
module.reasons = {}
module.since = 0
module.passMsTotal = 0
module.passMsMax = 0
module.passStartedAt = 0

-- Printing order; counters not listed here are printed after these, sorted by name
local COUNTER_ORDER = {
  "passes", "evaluations", "presents", "rosterBuilds", "statusReads", "auraUnits", "auraReads",
  "bagScans", "bagSlotReads", "cooldownReads", "rangeReads",
}

---@param name string Counter name
---@param amount number? Defaults to 1
function module:Count(name, amount)
  if self.enabled then
    self.counters[name] = (self.counters[name] or 0) + (amount or 1)
  end
end

---@param reason string Why a pass was requested
function module:Reason(reason)
  if self.enabled then
    self.reasons[reason] = (self.reasons[reason] or 0) + 1
  end
end

function module:Reset()
  wipe(self.counters)
  wipe(self.reasons)
  self.since = GetTime()
  self.passMsTotal = 0
  self.passMsMax = 0
end

function module:PassBegin()
  local enabled = BuffomatShared ~= nil and BuffomatShared.DebugLogging == true
  if enabled and not self.enabled then
    self:Reset()
  end
  self.enabled = enabled
  if enabled then
    self.counters.passes = (self.counters.passes or 0) + 1
    self.passStartedAt = kvPlayerModule.GetProfileTime()
  end
end

function module:PassEnd()
  if self.enabled then
    local elapsed = kvPlayerModule.GetProfileTime() - self.passStartedAt
    self.passMsTotal = self.passMsTotal + elapsed
    if elapsed > self.passMsMax then
      self.passMsMax = elapsed
    end
  end
end

---@param counts table<string, number>
---@param order string[]? Keys to print first
---@return string
local function formatCounts(counts, order)
  local parts, seen = {}, {}
  for _, key in ipairs(order or {}) do
    if counts[key] then
      seen[key] = true
      parts[#parts + 1] = key .. "=" .. counts[key]
    end
  end
  local rest = {}
  for key in pairs(counts) do
    if not seen[key] then
      rest[#rest + 1] = key
    end
  end
  table.sort(rest)
  for _, key in ipairs(rest) do
    parts[#parts + 1] = key .. "=" .. counts[key]
  end
  return table.concat(parts, ", ")
end

---Lines of the report, for printing and for tests.
---@return string[]
function module:Report()
  if not self.enabled then
    return { "Scan statistics are collected while debug logging is on (BuffomatShared.DebugLogging)." }
  end
  local seconds = math.max(GetTime() - self.since, 0.001)
  local passes = self.counters.passes or 0
  return {
    string.format("Scan statistics over %.0f s: %.1f passes/min, %.2f ms/pass average, %.2f ms longest",
      seconds, passes * 60 / seconds, passes > 0 and self.passMsTotal / passes or 0, self.passMsMax),
    "Counters: " .. formatCounts(self.counters, COUNTER_ORDER),
    "Reasons: " .. formatCounts(self.reasons, nil),
  }
end

---Print the report to chat and start a new measuring period.
function module:Print()
  for _, line in ipairs(self:Report()) do
    BuffomatAddon:Print(line)
  end
  if self.enabled then
    self:Reset()
  end
end

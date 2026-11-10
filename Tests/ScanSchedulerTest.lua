-- Run from the repository root: lua Tests/ScanSchedulerTest.lua
-- The scan scheduler: coalescing, the minimum gap, deadlines, and the combat and loading gates.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local function setup()
  local f = fixture.new({})
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/Scan/ScanStats.lua")
  f:load("Src/Scan/ScanScheduler.lua")
  local scheduler = f:lib("Buffomat-ScanScheduler")
  local passes = {}
  -- Each pass records when it ran and what it was asked to read
  f:lib("Buffomat-ScanPass").Run = function(_, pending, pendingUnits)
    local pass = { at = f.state.now, domains = {}, auras = {}, status = {} }
    for domain, dirty in pairs(pending) do pass.domains[domain] = dirty end
    for unitId in pairs(pendingUnits.auras) do pass.auras[unitId] = true end
    for unitId in pairs(pendingUnits.status) do pass.status[unitId] = true end
    passes[#passes + 1] = pass
    if f.state.onPass then
      return f.state.onPass(pass)
    end
  end
  return f, scheduler, passes
end

-- Nothing runs before the addon is ready; the first pass reads everything
do
  local f, scheduler, passes = setup()
  scheduler:MarkDirty("bags")
  equal(f:pendingTimers(), 0, "no timer before Start")
  scheduler:Start()
  f:advance(1)
  equal(#passes, 1)
  equal(passes[1].domains.roster, true); equal(passes[1].domains.auras, true); equal(passes[1].domains.bags, true)
  equal(f:pendingTimers(), 0, "no timer while nothing is pending")
  print("PASS: start reads everything, then goes idle")
end

-- A burst of events becomes one pass; marks made during a pass belong to the next one
do
  local f, scheduler, passes = setup()
  scheduler:Start(); f:advance(1)
  for index = 1, 40 do
    scheduler:MarkDirty("auras", "raid" .. index)
  end
  equal(f:pendingTimers(), 1, "one timer for the whole burst")
  f:advance(0.09)
  equal(#passes, 1, "the burst is still coalescing")
  f:advance(0.02)
  equal(#passes, 2)
  equal(passes[2].auras.raid1, true); equal(passes[2].auras.raid40, true)
  equal(passes[2].domains.auras, nil, "only the named units, not the whole domain")
  equal(next(scheduler.dirtyUnits.auras), nil, "the pass took its input")

  f.state.onPass = function()
    f.state.onPass = nil
    scheduler:MarkDirty("bags") -- arrives while the pass runs
  end
  scheduler:MarkDirty("weapon")
  f:advance(0.25)
  equal(#passes, 3); equal(passes[3].domains.weapon, true); equal(passes[3].domains.bags, nil)
  f:advance(0.5)
  equal(#passes, 4, "a mark during a pass gives a second pass")
  equal(passes[4].domains.bags, true); equal(passes[4].domains.weapon, nil)
  equal(passes[4].at - passes[3].at >= scheduler.MIN_GAP - 0.001, true, "passes keep the minimum gap")
  print("PASS: coalescing, per-unit marks, marks during a pass, minimum gap")
end

-- A continuous stream of events is capped by the minimum gap
do
  local f, scheduler, passes = setup()
  scheduler:Start(); f:advance(1)
  local before = #passes
  for _ = 1, 100 do
    scheduler:MarkDirty("auras", "player")
    f:advance(0.01)
  end
  f:advance(0.5)
  local count = #passes - before
  assert(count >= 4 and count <= 6, "about five passes a second, got " .. count)
  print("PASS: an event stream runs about five passes a second")
end

-- Deadlines: a wake time makes its domain dirty at that time, and an earlier request wins
do
  local f, scheduler, passes = setup()
  scheduler:Start(); f:advance(1)
  local start = f.state.now
  scheduler:WakeAt(start + 30)
  scheduler:WakeAt(start + 10)
  scheduler:WakeAt(start + 20) -- later than the known one: ignored
  scheduler:WakeAt(start + 12, "bagCooldowns")
  f:advance(9.9)
  equal(#passes, 1, "nothing before the deadline")
  f:advance(0.2)
  equal(#passes, 2); equal(passes[2].domains.settings, true); equal(passes[2].domains.bagCooldowns, nil)
  equal(math.abs(passes[2].at - (start + 10)) < 0.011, true, "deadline fires at the requested time")
  f:advance(2)
  equal(#passes, 3); equal(passes[3].domains.bagCooldowns, true)
  f:advance(60)
  equal(#passes, 3, "a fired deadline does not repeat")
  equal(f:pendingTimers(), 0)

  -- Deadlines asked for during a pass are armed when the pass ends
  f.state.onPass = function()
    f.state.onPass = nil
    scheduler:WakeAfter(scheduler.RANGE_TICK, "range")
  end
  scheduler:Request("test")
  f:advance(0.3)
  equal(#passes, 4)
  f:advance(1)
  equal(#passes, 5); equal(passes[5].domains.range, true)
  print("PASS: deadlines fire once, at the right time, per domain")
end

-- Combat: no timers and no passes; everything is read again afterwards
do
  local f, scheduler, passes = setup()
  scheduler:Start(); f:advance(1)
  scheduler:WakeAt(f.state.now + 5)
  f.state.inCombat = true
  scheduler:OnCombatStart()
  equal(f:pendingTimers(), 0, "combat start cancels the timer")
  scheduler:MarkDirty("auras", "player")
  scheduler:MarkAllDirty("test")
  equal(f:pendingTimers(), 0, "no timer is armed in combat")
  f:advance(10)
  equal(#passes, 1, "no pass in combat")
  f.state.inCombat = false
  scheduler:OnCombatEnd()
  f:advance(0.3)
  equal(#passes, 2, "exactly one pass after combat")
  equal(passes[2].domains.roster, true); equal(passes[2].auras.player, true)
  f:advance(60)
  equal(#passes, 2)
  print("PASS: combat closes the gate and its end reads everything once")
end

-- Loading screen: closed until the grace time after it
do
  local f, scheduler, passes = setup()
  scheduler:Start(); f:advance(1)
  local cleared = 0
  scheduler.onLoadingEnd = function() cleared = cleared + 1 end
  scheduler:OnLoadingStart()
  scheduler:MarkDirty("roster")
  f:advance(5)
  equal(#passes, 1, "no pass behind a loading screen")
  scheduler:OnLoadingEnd(2)
  scheduler:OnLoadingEnd(2) -- PLAYER_ENTERING_WORLD and LOADING_SCREEN_DISABLED both arrive
  f:advance(1.9)
  equal(#passes, 1, "still inside the grace time")
  f:advance(0.5)
  equal(#passes, 2); equal(cleared, 1)
  print("PASS: loading screen gate with grace time")
end

-- A blocked pass keeps its input; a continuing pass runs again without new marks
do
  local f, scheduler, passes = setup()
  scheduler:Start(); f:advance(1)
  f.state.onPass = function() return "blocked" end
  scheduler:MarkDirty("auras", "raid3")
  scheduler:MarkDirty("bags")
  f:advance(1)
  equal(#passes, 2)
  equal(f:pendingTimers(), 0, "a blocked pass does not retry by itself")
  equal(scheduler.dirtyUnits.auras.raid3, true); equal(scheduler.dirty.bags, true)
  f.state.onPass = nil
  scheduler:MarkAllDirty("blockLifted")
  f:advance(1)
  equal(#passes, 3); equal(passes[3].auras.raid3, true)

  local left = 2
  f.state.onPass = function()
    left = left - 1
    return left >= 0 and "continue" or nil
  end
  scheduler:MarkDirty("auras")
  f:advance(0.11)
  equal(#passes, 4)
  f:advance(0.06)
  equal(#passes, 5, "continuation follows closer than the minimum gap")
  f:advance(0.06)
  equal(#passes, 6)
  f:advance(5)
  equal(#passes, 6, "continuation stops when the pass is done")

  -- Slower hardware doubles the intervals
  f.globals.BuffomatShared.SlowerHardware = true
  f.state.onPass = nil
  scheduler:MarkDirty("bags")
  f:advance(0.15)
  equal(#passes, 6)
  f:advance(0.1)
  equal(#passes, 7)
  print("PASS: blocked and continuing passes, slower hardware")
end

-- Run from the repository root: lua Tests/AuraCompatibilityTest.lua
local function loadModule(path, globals)
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, globals)
  else
    chunk = assert(loadfile(path, "t", globals))
  end
  chunk("BuffomatClassic", {})
end

local function equal(actual, expected, label)
  assert(actual == expected, label or "unexpected value")
end

local function run(mode)
  local libs = {}
  local secret = {}
  local state = { inCombat = false, calls = 0, fullName = "Tester" }
  local data = {
    name = "Test Buff", icon = 101, applications = 2, dispelName = "Magic",
    duration = 60, expirationTime = 90, sourceUnit = "player", spellId = 42,
    isStealable = false, nameplateShowPersonal = false, canApplyAura = true,
    isBossAura = false, isFromPlayerOrPlayerPet = true, nameplateShowAll = false, timeMod = 1,
  }
  local function getAura(unit, index, filter)
    assert(not state.inCombat, "aura API called in combat")
    equal(unit, "player")
    state.calls = state.calls + 1
    state.filter = filter
    if index == 1 and not state.empty then return data end
  end
  local globals = setmetatable({
    WOW_PROJECT_ID = mode == "legacy" and 2 or 1,
    WOW_PROJECT_CLASSIC = 2,
    UnitClass = function() return "Hunter", "HUNTER" end,
    InCombatLockdown = function() return state.inCombat end,
    UnitIsDeadOrGhost = function() return false end,
    UnitIsFeignDeath = function() return false end,
    UnitIsGhost = function() return false end,
    UnitIsConnected = function() return true end,
    UnitIsUnit = function(a, b) return a == b end,
    UnitFullName = function() return state.fullName end,
    GetTime = function() return 30 end,
    BuffomatAddon = { AllDrink = {}, buffIgnoreAll = {}, drinkingPersonCount = 0 },
    BuffomatShared = { Duration = {} },
    wipe = function(values) for key in pairs(values) do values[key] = nil end end,
    tContains = function(values, value)
      for _, candidate in pairs(values) do if candidate == value then return true end end
      return false
    end,
    issecretvalue = function(value) return rawequal(value, secret) end,
    CancelUnitBuff = function(unit, index, filter) state.cancelled = { unit, index, filter } end,
    LibStub = function(name)
      libs[name] = libs[name] or {}
      return libs[name]
    end,
  }, { __index = _G })
  globals._G = globals
  if mode == "modern" then
    globals.C_UnitAuras = { GetAuraDataByIndex = getAura }
    -- Modern-only case reproduces the reported nil UnitAura/UnitBuff globals.
  elseif mode ~= "unavailable" then
    globals.UnitAura = function(unit, index, filter)
      local aura = getAura(unit, index, filter)
      if not aura then return nil end
      return aura.name, aura.icon, aura.applications, aura.dispelName, aura.duration,
          aura.expirationTime, aura.sourceUnit, aura.isStealable, aura.nameplateShowPersonal,
          aura.spellId, aura.canApplyAura, aura.isBossAura, aura.isFromPlayerOrPlayerPet,
          aura.nameplateShowAll, aura.timeMod
    end
    if mode == "mixed" then globals.C_UnitAuras = {} end
  end
  loadModule("Src/KvLib/KvEnv.lua", globals)
  loadModule("Src/KvLib/KvUnit.lua", globals)
  loadModule("Src/KvLib/KvPlayer.lua", globals)
  loadModule("Src/Scan/ScanEvaluate.lua", globals)
  loadModule("Src/Scan/ScanEffects.lua", globals)
  local env = libs["KvLibShared-Env"]
  local scan = libs["Buffomat-ScanEffects"]
  local evaluate = libs["Buffomat-ScanEvaluate"]
  setmetatable(libs["Buffomat-Languages"], { __call = function(_, key) return key end })
  local player = { unitId = "player", name = "Tester", knownBuffs = {}, allBuffs = {} }
  local roster = { player = player, units = { player } }

  local aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
  if mode == "unavailable" then
    equal(aura, nil); equal(readable, false)
    equal(state.calls, 0)
    print("PASS: unavailable aura API pauses scanning")
    return
  end
  equal(readable, true); equal(aura.name, data.name); equal(aura.spellId, 42)
  equal(aura.count, 2); equal(aura.debuffType, "Magic"); equal(aura.source, "player")
  equal(aura.isBossDebuff, false); equal(aura.castByPlayer, true)
  equal(aura.duration, 60); equal(aura.expirationTime, 90); equal(aura.timeMod, 1)
  aura, readable = env.GetUnitAura("player", 2, "HELPFUL")
  equal(aura, nil); equal(readable, true, "end of list remains readable")
  equal(evaluate:IsAuraDataComplete(roster), true)

  -- Every returned primitive must be checked before use, including spell IDs,
  -- durations, source tokens, and aura names used as cache keys.
  for key, value in pairs(data) do
    data[key] = secret
    aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
    equal(aura, nil); equal(readable, false, "secret field " .. key)
    data[key] = value
  end

  state.inCombat = true
  local callsBeforeCombat = state.calls
  aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
  equal(aura, nil); equal(readable, false)
  equal(scan:CancelBuff({42}), false)
  equal(state.calls, callsBeforeCombat, "no combat aura enumeration")
  state.inCombat = false

  player.auraDataUnavailable = true
  equal(evaluate:IsAuraDataComplete(roster), false, "an unread player blocks decisions")
  player.auraDataUnavailable = false

  roster.units[2] = { auraDataUnavailable = true }
  equal(evaluate:IsAuraDataComplete(roster), false, "restricted party member blocks partial decisions")
  roster.units[2] = nil
  player.weaponDataUnavailable = true
  equal(evaluate:IsAuraDataComplete(roster), false, "unreadable weapon enchants block partial decisions")
  player.weaponDataUnavailable = false
  roster.incomplete = true
  equal(evaluate:IsAuraDataComplete(roster), false, "a member the client hides blocks partial decisions")
  roster.incomplete = false

  equal(scan:CancelBuff({42}), true)
  equal(state.filter, "HELPFUL|CANCELABLE")
  equal(state.cancelled[1], "player"); equal(state.cancelled[2], 1)
  equal(state.cancelled[3], state.filter, "cancellation uses the same filtered index")
  state.cancelled = nil
  data.spellId = secret
  equal(scan:CancelBuff({42}), false); equal(state.cancelled, nil)
  data.spellId = 42
  state.empty = true
  equal(scan:CancelBuff({42}), false)
  print("PASS: " .. mode .. " aura mapping, restrictions, and cancellation")
end

for _, mode in ipairs({ "legacy", "modern", "mixed", "unavailable" }) do run(mode) end

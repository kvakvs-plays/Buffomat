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
  loadModule("Src/Core/Buff.lua", globals)
  loadModule("Src/Core/Unit.lua", globals)
  loadModule("Src/Task/TaskScan.lua", globals)
  local env = libs["KvLibShared-Env"]
  local unitModule = libs["Buffomat-Unit"]
  local scan = libs["Buffomat-TaskScan"]
  local allBuffs = libs["Buffomat-AllBuffs"]
  allBuffs.allSpellIds = { 42 }
  allBuffs.selectedBuffsSpellIds = { [42] = { buffId = 42 } }
  allBuffs.spellIdIsSingleLookup = { [42] = true }
  libs["Buffomat-Party"].unitAurasLastUpdated = {}
  setmetatable(libs["Buffomat-Languages"], { __call = function(_, key) return key end })
  scan.ShowInactive = function(_, reason) state.paused = reason end
  local player = unitModule:New({ unitId = "player", name = "Tester", knownBuffs = {}, allBuffs = {} })
  player.UpdatePlayerWeaponEnchantments = function() state.weaponsUpdated = true end
  local context = { party = { player = player, byUnitId = { player = player } } }

  local aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
  if mode == "unavailable" then
    equal(aura, nil); equal(readable, false)
    player:ForceUpdateBuffs(player)
    equal(player.auraDataUnavailable, true)
    equal(scan:CheckAuraData(context), false)
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
  player:ForceUpdateBuffs(player)
  equal(player.knownBuffs[42].singleId, 42); equal(player.allBuffs[42], true)
  equal(globals.BuffomatShared.Duration["Test Buff"], 60)
  equal(state.weaponsUpdated, true); equal(scan:CheckAuraData(context), true)

  -- Every returned primitive must be checked before use, including spell IDs,
  -- durations, source tokens, and aura names used as cache keys.
  for key, value in pairs(data) do
    data[key] = secret
    aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
    equal(aura, nil); equal(readable, false, "secret field " .. key)
    player:ForceUpdateBuffs(player)
    equal(player.auraDataUnavailable, true); equal(player.NeedBuff, false)
    equal(next(player.knownBuffs), nil); equal(next(player.allBuffs), nil)
    equal(scan:CheckAuraData(context), false)
    data[key] = value
  end

  data.expirationTime = 0
  state.fullName = secret
  aura, readable = unitModule:UnitAura("player", 1, "HELPFUL")
  equal(aura, nil); equal(readable, false, "secret unit name in duration fallback")
  state.fullName = "Tester"
  data.expirationTime = 90

  state.inCombat = true
  local callsBeforeCombat = state.calls
  aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
  equal(aura, nil); equal(readable, false)
  player:ForceUpdateBuffs(player)
  equal(player.auraDataUnavailable, true)
  equal(scan:CancelBuff({42}), false)
  equal(state.calls, callsBeforeCombat, "no combat aura enumeration")
  state.inCombat = false
  player:ForceUpdateBuffs(player)
  equal(player.auraDataUnavailable, false); equal(player.NeedBuff, true)
  equal(scan:CheckAuraData(context), true, "public data resumes scanning")

  context.party.byUnitId.party1 = { auraDataUnavailable = true }
  equal(scan:CheckAuraData(context), false, "restricted party member blocks partial decisions")
  context.party.byUnitId.party1 = nil
  context.party.playerPet = { auraDataUnavailable = true }
  equal(scan:CheckAuraData(context), false, "restricted pet blocks partial decisions")
  context.party.playerPet = nil

  equal(scan:CancelBuff({42}), true)
  equal(state.filter, "HELPFUL|CANCELABLE")
  equal(state.cancelled[1], "player"); equal(state.cancelled[2], 1)
  equal(state.cancelled[3], state.filter, "cancellation uses the same filtered index")
  state.cancelled = nil
  data.spellId = secret
  equal(scan:CancelBuff({42}), false); equal(state.cancelled, nil)
  data.spellId = 42
  state.empty = true
  player:ForceUpdateBuffs(player)
  equal(player.auraDataUnavailable, false); equal(player.NeedBuff, true)
  equal(next(player.knownBuffs), nil, "empty public aura list can still need buffs")
  equal(scan:CancelBuff({42}), false)
  print("PASS: " .. mode .. " aura mapping, unit scan, restrictions, and cancellation")
end

for _, mode in ipairs({ "legacy", "modern", "mixed", "unavailable" }) do run(mode) end

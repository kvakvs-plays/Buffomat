-- Run from the repository root: lua Tests/KvUnitTest.lua
-- KvLib wrappers used by the scan modules: units, auras, player state, events, and the counters.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

for _, modern in ipairs({ false, true }) do
  local f = fixture.new({ modern = modern })
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvUnit.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/KvLib/KvEvents.lua")
  f:load("Src/Scan/ScanStats.lua")
  local kvUnit, kvPlayer, kvEvents = f:lib("KvLibShared-Unit"), f:lib("KvLibShared-Player"), f:lib("KvLibShared-Events")

  -- Auras come back as plain values and end with a readable nil
  f:aura("player", 42, { name = "Fortitude", duration = 60, expirationTime = 1050, source = "player" })
  local spellId, name, duration, expirationTime, source, readable = kvUnit.ReadAura("player", 1, "HELPFUL")
  equal(spellId, 42); equal(name, "Fortitude"); equal(duration, 60); equal(expirationTime, 1050)
  equal(source, "player"); equal(readable, true)
  spellId, name, duration, expirationTime, source, readable = kvUnit.ReadAura("player", 2, "HELPFUL")
  equal(spellId, nil); equal(readable, true, "end of the aura list is readable")
  equal(name, nil); equal(duration, nil); equal(expirationTime, nil); equal(source, nil)

  -- Identity and state
  equal(kvUnit.GetName("player"), "Tester")
  equal(kvUnit.GetGUID("player"), "guid-Tester")
  equal(kvUnit.GetPlayerClass("guid-Tester"), "PRIEST")
  equal(kvUnit.Exists("party1"), false)
  equal(kvUnit.IsDead("player"), false)
  f.units.player.dead = true
  equal(kvUnit.IsDead("player"), true)
  f.units.player.feign = true
  equal(kvUnit.IsDead("player"), false, "feign death is not dead")
  f.units.player.dead, f.units.player.feign = false, false
  equal(kvUnit.DistanceSquared("player"), 0)

  f:raid({
    { name = "Tester", class = "PRIEST", subgroup = 2, isPlayer = true },
    { name = "Tank", class = "WARRIOR", subgroup = 1, role = "MAINTANK", combatRole = "DAMAGER" },
    { name = "Healer", class = "DRUID", subgroup = 3, combatRole = "HEALER" },
  })
  equal(kvUnit.GetNumRaidMembers(), 3)
  local subgroup, role = kvUnit.GetRaidSlot(2)
  equal(subgroup, 1); equal(role, "MAINTANK", "the raid leader's mark wins over the specialization")
  subgroup, role = kvUnit.GetRaidSlot(3)
  equal(subgroup, 3); equal(role, "HEALER")
  equal(kvUnit.GetRaidSlot(4), nil)
  f.units.raid2.distance = 400
  equal(kvUnit.DistanceSquared("raid2"), 400)

  if modern then
    f.units.raid2.secretName = true
    local hiddenName, _, unreadable = kvUnit.GetName("raid2")
    equal(hiddenName, nil); equal(unreadable, true, "secret name is reported, not returned")
    f.units.raid2.secretName = nil
    f.units.raid2.secretAuras = true
    local hiddenSpell, _, _, _, _, hiddenReadable = kvUnit.ReadAura("raid2", 1, "HELPFUL")
    equal(hiddenSpell, nil); equal(hiddenReadable, false, "secret aura is unreadable")
    f.units.raid2.secretAuras = nil
  end

  -- Player state
  f.state.mounted, f.state.instanceType, f.state.formId = true, "raid", 5
  equal(kvPlayer.IsMounted(), true); equal(kvPlayer.GetInstanceType(), "raid")
  equal(kvPlayer.GetShapeshiftFormID(), 5)
  equal(kvPlayer.IsInVehicle(), false, "no vehicle API on this client")

  -- Events: unit filter, unknown events, unregistering
  local dispatcher = kvEvents.NewDispatcher()
  local seen = {}
  local function onAura(event, unit) seen[#seen + 1] = event .. ":" .. unit end
  equal(dispatcher:OnUnit("UNIT_AURA", onAura, "player"), true)
  f:fire("UNIT_AURA", "player")
  f:fire("UNIT_AURA", "nameplate1")
  equal(#seen, 1); equal(seen[1], "UNIT_AURA:player")
  f.state.validEvents = { UNIT_AURA = true }
  equal(dispatcher:On("NO_SUCH_EVENT", function() seen[#seen + 1] = "bad" end), false, "unknown event is refused")
  equal(dispatcher:IsRegistered("NO_SUCH_EVENT"), false)
  f.state.validEvents = nil
  dispatcher:Off("UNIT_AURA")
  f:fire("UNIT_AURA", "player")
  equal(#seen, 1, "unregistered handler is not called")

  -- Counters collect only with debug logging on
  local stats = f:lib("Buffomat-ScanStats")
  stats:PassBegin(); stats:Count("auraReads", 5); stats:PassEnd()
  equal(stats.counters.auraReads, nil, "nothing is counted with debug logging off")
  f.globals.BuffomatShared.DebugLogging = true
  stats:PassBegin(); stats:Count("auraReads", 5); stats:Reason("bagUpdate"); f:advance(0.01); stats:PassEnd()
  equal(stats.counters.passes, 1); equal(stats.counters.auraReads, 5); equal(stats.reasons.bagUpdate, 1)
  equal(stats.passMsMax, 10)
  stats:Print()
  assert(f.printed[2]:find("passes=1, auraReads=5", 1, true), f.printed[2])
  equal(stats.counters.passes, nil, "printing starts a new period")

  print("PASS: " .. (modern and "modern" or "legacy") .. " unit, aura, player, event and counter wrappers")
end

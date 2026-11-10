-- Run from the repository root: lua Tests/ScanEventsTest.lua
-- Scan events: which domain an event marks, the unit filter, and the combat and loading gates.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local function setup(options)
  local f = fixture.new(options)
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvUnit.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/KvLib/KvEvents.lua")
  f:load("Src/Scan/ScanStats.lua")
  f:load("Src/Scan/ScanScheduler.lua")
  f:load("Src/Scan/ScanEvents.lua")
  f:lib("Buffomat-Const").LOADING_SCREEN_TIMEOUT = 2
  f:lib("Buffomat-TaskList").WipeMacro = function() f.state.macroWiped = true end
  f:lib("Buffomat-ScanEffects").MaybeResetWatchGroups = function() f.state.watchGroupsReset = true end
  f:lib("Buffomat-ScanEffects").ClearSkip = function() f.state.skipCleared = true end
  local scheduler = f:lib("Buffomat-ScanScheduler")
  local passes = {}
  f:lib("Buffomat-ScanPass").Run = function(_, pending, pendingUnits)
    local pass = { domains = {}, auras = {}, status = {} }
    for domain, dirty in pairs(pending) do pass.domains[domain] = dirty end
    for unitId in pairs(pendingUnits.auras) do pass.auras[unitId] = true end
    for unitId in pairs(pendingUnits.status) do pass.status[unitId] = true end
    passes[#passes + 1] = pass
  end
  return f, scheduler, passes
end

for _, modern in ipairs({ false, true }) do
  local f, scheduler, passes = setup({ modern = modern })
  local rosterScan = f:lib("Buffomat-RosterScan")
  rosterScan.roster = { isRaid = false, byUnitId = { player = {} } }
  rosterScan.ForgetResurrections = function() f.state.resurrectionsForgotten = true end
  f.state.validEvents = modern and nil or setmetatable({}, { __index = function(_, event)
    -- Events this old client does not have
    return event ~= "WEAPON_ENCHANT_CHANGED" and event ~= "PLAYER_ROLES_ASSIGNED"
        and event ~= "UNIT_ENTERED_VEHICLE" and event ~= "UNIT_EXITED_VEHICLE"
  end })
  local events = f:lib("Buffomat-ScanEvents")
  events:Init()
  equal(events.dispatcher:IsRegistered("ADDON_RESTRICTION_STATE_CHANGED"), modern, "restriction event capability")
  equal(events.dispatcher:IsRegistered("COMBAT_LOG_EVENT_UNFILTERED"), false, "no combat log")
  equal(events.dispatcher:IsRegistered("UNIT_AURA"), true)
  scheduler:Start(); f:advance(1)
  equal(#passes, 1)

  -- Alone, the client filters UNIT_AURA to the player and pet
  f:fire("UNIT_AURA", "nameplate3")
  f:fire("UNIT_AURA", "target")
  equal(f:pendingTimers(), 0, "an aura on a stranger schedules nothing")
  f:fire("UNIT_AURA", "player")
  f:advance(0.3)
  equal(#passes, 2)
  equal(passes[2].auras.player, true); equal(passes[2].status.player, true); equal(passes[2].domains.player, true)
  equal(passes[2].domains.roster, nil); equal(passes[2].domains.bags, nil)

  -- In a group every UNIT_AURA arrives and the roster filters
  f.state.inGroup, f.state.inRaid = true, true
  f:fire("GROUP_ROSTER_UPDATE")
  f:advance(0.3)
  equal(#passes, 3); equal(passes[3].domains.roster, true)
  rosterScan.roster = { isRaid = true, byUnitId = { player = {}, raid2 = {} } }
  f:fire("UNIT_AURA", "nameplate3")
  f:fire("UNIT_AURA", "raid7") -- not in the roster snapshot
  equal(f:pendingTimers(), 0, "an aura outside the roster schedules nothing")
  f:fire("UNIT_AURA", "raid2")
  f:fire("UNIT_CONNECTION", "raid2")
  f:fire("UNIT_CONNECTION", "raid9")
  f:advance(0.3)
  equal(#passes, 4); equal(passes[4].auras.raid2, true); equal(passes[4].status.raid2, true)
  equal(passes[4].status.raid9, nil); equal(passes[4].domains.player, nil)

  -- One domain per kind of event
  local function domainsAfter(event, ...)
    f:fire(event, ...)
    f:advance(0.3)
    return passes[#passes].domains
  end
  local domains = domainsAfter("BAG_UPDATE_DELAYED")
  equal(domains.bags, true); equal(domains.bagCooldowns, true); equal(domains.auras, nil)
  domains = domainsAfter("BAG_UPDATE_COOLDOWN")
  equal(domains.bagCooldowns, true); equal(domains.bags, nil)
  domains = domainsAfter("UNIT_INVENTORY_CHANGED", "player")
  equal(domains.weapon, true); equal(domains.player, nil)
  domains = domainsAfter("UPDATE_SHAPESHIFT_FORM")
  equal(domains.player, true); equal(domains.weapon, nil)
  domains = domainsAfter("ZONE_CHANGED_NEW_AREA")
  equal(domains.player, true); equal(domains.status, true)
  local before = #passes
  f:fire("UNIT_INVENTORY_CHANGED", "raid2")
  f:fire("UNIT_SPELLCAST_START", "raid2")
  f:advance(0.3)
  equal(#passes, before, "other units' inventory and casts are ignored")

  -- Casting
  local playerState = f:lib("Buffomat-PlayerStateScan")
  f:fire("UNIT_SPELLCAST_START", "player")
  equal(playerState.casting, "cast"); equal(f.state.macroWiped, true)
  f:fire("UNIT_SPELLCAST_STOP", "player")
  equal(playerState.casting, nil)
  f:fire("UNIT_SPELLCAST_CHANNEL_START", "player")
  equal(playerState.casting, "channel")
  f:fire("UNIT_SPELLCAST_CHANNEL_STOP", "player")
  f:advance(0.3)
  equal(passes[#passes].domains.settings, true); equal(passes[#passes].domains.player, true)

  -- Mana only matters once the cheapest unaffordable spell becomes affordable
  before = #passes
  playerState.manaWakeLimit = 500
  events:SetManaWatch(true)
  f.state.mana = 300
  f:fire("UNIT_POWER_UPDATE", "player", "MANA")
  f:advance(0.3)
  equal(#passes, before, "still too little mana")
  if modern then
    f.state.mana = f.secret
    f:fire("UNIT_POWER_UPDATE", "player", "MANA")
    f:advance(0.3)
    equal(#passes, before, "secret mana is not compared")
  end
  f.state.mana = 600
  f:fire("UNIT_POWER_UPDATE", "player", "RAGE")
  f:fire("UNIT_POWER_UPDATE", "player", "MANA")
  f:advance(0.3)
  equal(#passes, before + 1); equal(passes[#passes].domains.player, true)
  events:SetManaWatch(false)
  f:fire("UNIT_POWER_UPDATE", "player", "MANA")
  f:advance(0.3)
  equal(#passes, before + 1, "no mana events while nothing waits for mana")

  -- A target outside the group, with the BuffTarget option
  before = #passes
  f:unit("target", { name = "Stranger", class = "MAGE" })
  f:fire("PLAYER_TARGET_CHANGED")
  f:advance(0.3)
  equal(#passes, before, "targets are ignored without the option")
  f.globals.BuffomatShared.BuffTarget = true
  f:fire("PLAYER_TARGET_CHANGED")
  f:advance(0.3)
  equal(#passes, before + 1); equal(passes[#passes].domains.roster, true); equal(passes[#passes].auras.target, true)
  f:fire("PLAYER_TARGET_CHANGED")
  f:advance(0.3)
  equal(#passes, before + 1, "the same target again changes nothing")

  -- Combat: no aura events, no timers; one pass afterwards
  before = #passes
  f:fire("UNIT_AURA", "raid2")
  equal(f:pendingTimers(), 1)
  f.state.inCombat = true
  f:fire("PLAYER_REGEN_DISABLED")
  equal(f:pendingTimers(), 0, "combat start cancels the timer")
  equal(events.dispatcher:IsRegistered("UNIT_AURA"), false, "aura events are not taken in combat")
  f:fire("BAG_UPDATE_DELAYED")
  f:advance(5)
  equal(#passes, before)
  f.state.inCombat = false
  f:fire("PLAYER_REGEN_ENABLED")
  equal(events.dispatcher:IsRegistered("UNIT_AURA"), true)
  f:advance(1)
  equal(#passes, before + 1, "combat end schedules exactly one pass")
  equal(passes[#passes].domains.auras, true); equal(passes[#passes].domains.roster, true)

  -- Loading screen
  before = #passes
  f:fire("PLAYER_LEAVING_WORLD")
  f:fire("GROUP_ROSTER_UPDATE")
  f:advance(5)
  equal(#passes, before)
  f:fire("PLAYER_ENTERING_WORLD")
  f:fire("LOADING_SCREEN_DISABLED")
  f:advance(3)
  equal(#passes, before + 1)

  -- Alt means "try again"; any other modifier only matters while a task waits for one
  before = #passes
  f.state.modifier = true
  f:fire("MODIFIER_STATE_CHANGED")
  f:advance(0.3)
  equal(#passes, before, "nothing waits for a modifier key")
  events.modifierWatch = true
  f:fire("MODIFIER_STATE_CHANGED")
  f:advance(0.3)
  equal(#passes, before + 1); equal(passes[#passes].domains.settings, true); equal(passes[#passes].domains.auras, nil)
  f.state.alt = true
  f:fire("MODIFIER_STATE_CHANGED")
  f:advance(0.3)
  equal(#passes, before + 2); equal(passes[#passes].domains.auras, true); equal(f.state.skipCleared, true)
  equal(f.state.resurrectionsForgotten, true)
  f.state.alt, f.state.modifier = false, false
  events.modifierWatch = false

  -- A restriction change is never scanned inside the event
  if modern then
    before = #passes
    f:fire("ADDON_RESTRICTION_STATE_CHANGED")
    equal(#passes, before, "the pass is deferred to the scheduler timer")
    f:advance(0.3)
    equal(#passes, before + 1); equal(passes[#passes].domains.auras, true)
  end

  -- Leaving the group resets the watched groups
  f.state.inGroup, f.state.inRaid = false, false
  f.globals.BuffomatShared.BuffTarget = false
  f:fire("GROUP_LEFT")
  equal(f.state.watchGroupsReset, true)
  f:advance(0.3)
  f:fire("UNIT_AURA", "raid2")
  equal(f:pendingTimers(), 0, "alone again, only the player and pet are heard")

  -- An update which only added debuffs is of no interest
  f:advance(0.3)
  before = #passes
  f:fire("UNIT_AURA", "player", { isFullUpdate = false, addedAuras = { { spellId = 5, isHarmful = true } } })
  equal(f:pendingTimers(), 0, "a debuff does not start a pass")
  f:fire("UNIT_AURA", "player", { isFullUpdate = false, addedAuras = { { spellId = 5, isHarmful = false } } })
  f:advance(0.3)
  equal(#passes, before + 1, "a buff does")
  f:fire("UNIT_AURA", "player", { isFullUpdate = false, removedAuraInstanceIDs = { 77 } })
  f:advance(0.3)
  equal(#passes, before + 2, "a removed aura could have been a buff")
  f:fire("UNIT_AURA", "player", { addedAuras = {} })
  f:advance(0.3)
  equal(#passes, before + 3, "a payload without the full-update flag is not trusted")

  print("PASS: " .. (modern and "modern" or "legacy") .. " scan events mark their domains and respect the gates")
end

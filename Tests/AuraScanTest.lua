-- Run from the repository root: lua Tests/AuraScanTest.lua
-- The aura reader: per-unit reads, the read budget, change detection, unreadable auras.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local FORTITUDE, FORTITUDE_GROUP, PHASE_SHIFT, DRINK, OTHER = 1243, 21562, 4511, 430, 9999

local function setup(options)
  local f = fixture.new(options)
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvUnit.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/Scan/ScanStats.lua")
  f:load("Src/Core/Buff.lua")
  f:load("Src/Core/Unit.lua")
  local const = f:lib("Buffomat-Const")
  const.CLASS_ICONS = {}
  const.CLASS_COLOR = setmetatable({}, { __index = function() return { colorStr = "ffffffff" } end })
  f:lib("Buffomat-NgStrings").FormatTexture = function() return "" end
  f:load("Src/Scan/RosterScan.lua")
  f:load("Src/Scan/AuraScan.lua")

  local fortitude = { buffId = FORTITUDE }
  local allBuffs = f:lib("Buffomat-AllBuffs")
  allBuffs.allSpellIdSet = { [FORTITUDE] = true, [FORTITUDE_GROUP] = true, [PHASE_SHIFT] = true }
  allBuffs.selectedBuffsSpellIds = { [FORTITUDE] = fortitude, [FORTITUDE_GROUP] = fortitude,
    [PHASE_SHIFT] = { buffId = PHASE_SHIFT } }
  allBuffs.spellIdIsSingleLookup = { [FORTITUDE] = true }
  allBuffs.drinkSpellIdSet = { [DRINK] = true }
  allBuffs.ignoreAllSpellIdSet = { [PHASE_SHIFT] = true }
  allBuffs.enchantToSpellLookup = {}
  allBuffs.setupVersion = 1

  -- Count allocated buff records
  local buffModule = f:lib("Buffomat-Buff")
  local newBuff = buffModule.New
  f.state.buffRecords = 0
  buffModule.New = function(...)
    f.state.buffRecords = f.state.buffRecords + 1
    return newBuff(...)
  end
  return f, f:lib("Buffomat-RosterScan"), f:lib("Buffomat-AuraScan")
end

local function raidOf(f, size)
  local members = { { name = "Tester", class = "PRIEST", subgroup = 5, isPlayer = true } }
  for index = 2, size do
    members[index] = { name = "Member" .. index, class = "WARRIOR", subgroup = math.ceil(index / 5) }
  end
  f:raid(members)
end

for _, modern in ipairs({ false, true }) do
  local f, rosterScan, auraScan = setup({ modern = modern })
  local roster = rosterScan.roster
  raidOf(f, 40)
  local pending = { auras = {}, status = {} }
  rosterScan:Rebuild(pending, false)
  equal(#roster.units, 40)

  -- A whole raid is read in four passes, the player and the player's subgroup first
  f:aura("player", FORTITUDE, { name = "Fortitude", duration = 1800, expirationTime = 2000 })
  f:aura("raid22", FORTITUDE_GROUP, { name = "Prayer", duration = 3600, expirationTime = 4000, source = "raid7" })
  f:aura("raid22", OTHER, { source = "raid22" })
  auraScan:Enqueue(roster, true, {})
  local passesNeeded, more = 0, true
  while more do
    f:resetCalls()
    more = auraScan:ReadQueued(roster)
    passesNeeded = passesNeeded + 1
    if passesNeeded == 1 then
      equal(roster.player.knownBuffs[FORTITUDE].expirationTime, 2000, "the player is read in the first pass")
      equal(roster.byUnitId.raid22.auraSignature ~= nil, true, "the player's subgroup is in the first pass")
      equal(roster.byUnitId.raid25.auraSignature ~= nil, true)
      equal(roster.byUnitId.raid5.auraSignature ~= nil, true, "then the others, in order, up to the budget")
      equal(roster.byUnitId.raid6.auraSignature, nil, "the eleventh unit waits for the next pass")
      -- Each unit costs one read per aura plus one for the end of the list
      equal(f:calls("aura"), 10 + 3)
    end
  end
  equal(passesNeeded, 4)
  equal(next(auraScan.queue), nil)

  -- What is stored: watched buffs by buff id, every aura by spell id
  local player, member = roster.player, roster.byUnitId.raid22
  local buff = player.knownBuffs[FORTITUDE]
  equal(buff.singleId, FORTITUDE); equal(buff.duration, 1800); equal(buff.source, "player"); equal(buff.isSingle, true)
  equal(player.allBuffs[FORTITUDE], true); equal(player.NeedBuff, true); equal(player.auraDataUnavailable, false)
  buff = member.knownBuffs[FORTITUDE]
  equal(buff.singleId, FORTITUDE_GROUP, "the group version fills the same buff slot"); equal(buff.isSingle, false)
  equal(member.allBuffs[OTHER], true); equal(member.knownBuffs[OTHER], nil, "unknown auras are only noted")
  equal(f.globals.BuffomatShared.Duration.Fortitude, 1800, "the duration seen on the player is remembered")

  -- One dirty unit costs one unit's read, and unchanged auras are not a change
  local version = auraScan.version
  f:resetCalls()
  auraScan:Enqueue(roster, false, { raid22 = true })
  equal(auraScan:ReadQueued(roster), false)
  equal(f:calls("aura"), 3, "two auras and the end of the list")
  equal(auraScan.version, version, "the same auras again change nothing")
  f.units.raid22.auras[1].expirationTime = 4100 -- refreshed
  auraScan:Enqueue(roster, false, { raid22 = true })
  auraScan:ReadQueued(roster)
  equal(auraScan.version, version + 1); equal(member.knownBuffs[FORTITUDE].expirationTime, 4100)
  f:removeAura("raid22", FORTITUDE_GROUP)
  auraScan:Enqueue(roster, false, { raid22 = true })
  auraScan:ReadQueued(roster)
  equal(auraScan.version, version + 2); equal(member.knownBuffs[FORTITUDE], nil); equal(member.allBuffs[OTHER], true)

  -- A buff of the player without a reported duration uses the remembered one
  f:aura("raid22", FORTITUDE, { name = "Fortitude", duration = 0, expirationTime = 2500 })
  auraScan:Enqueue(roster, false, { raid22 = true })
  auraScan:ReadQueued(roster)
  equal(member.knownBuffs[FORTITUDE].duration, 1800)
  f.units.raid22.auras[2].expirationTime = 0
  auraScan:Enqueue(roster, false, { raid22 = true })
  auraScan:ReadQueued(roster)
  equal(member.knownBuffs[FORTITUDE].duration, 0, "without an end time the buff never runs out")

  -- A new spell setup stores different buffs, so it is a change even with the same auras
  version = auraScan.version
  f:lib("Buffomat-AllBuffs").setupVersion = 2
  auraScan:Enqueue(roster, false, { raid22 = true })
  auraScan:ReadQueued(roster)
  equal(auraScan.version, version + 1)

  -- Drinking, the dead, and units which take no buffs at all
  f:aura("raid3", DRINK)
  f:aura("raid4", FORTITUDE)
  f:aura("raid4", PHASE_SHIFT)
  f:aura("raid4", OTHER)
  roster.byUnitId.raid5.isDead = true
  f:aura("raid5", FORTITUDE)
  auraScan:Enqueue(roster, false, { raid3 = true, raid4 = true, raid5 = true })
  auraScan:ReadQueued(roster)
  equal(auraScan.drinkingCount, 1); equal(roster.byUnitId.raid3.isDrinking, true)
  local shifted = roster.byUnitId.raid4
  equal(shifted.NeedBuff, false, "a phase-shifted unit is left alone"); equal(next(shifted.knownBuffs), nil)
  equal(shifted.allBuffs[OTHER], nil, "reading stops at the excluding aura")
  equal(next(roster.byUnitId.raid5.knownBuffs), nil, "the dead have no buffs")
  equal(roster.byUnitId.raid5.NeedBuff, true)

  -- Records are reused: a steady-state read allocates nothing
  auraScan:Enqueue(roster, true, {})
  while auraScan:ReadQueued(roster) do end
  local records = f.state.buffRecords
  auraScan:Enqueue(roster, true, {})
  while auraScan:ReadQueued(roster) do end
  equal(f.state.buffRecords, records, "no new buff records in a steady-state read")

  -- Units which left the roster are dropped from the queue
  auraScan:Enqueue(roster, false, { raid99 = true })
  equal(auraScan:ReadQueued(roster), false)
  equal(next(auraScan.queue), nil)

  -- Slower hardware halves the budget
  f.globals.BuffomatShared.SlowerHardware = true
  auraScan:Enqueue(roster, true, {})
  passesNeeded = 0
  repeat passesNeeded = passesNeeded + 1 until not auraScan:ReadQueued(roster)
  equal(passesNeeded, 8)
  f.globals.BuffomatShared.SlowerHardware = false

  if modern then
    -- Unreadable auras: only that unit is marked, and nothing is concluded from it
    version = auraScan.version
    f.units.raid22.secretAuras = true
    auraScan:Enqueue(roster, false, { raid22 = true, raid23 = true })
    auraScan:ReadQueued(roster)
    equal(member.auraDataUnavailable, true); equal(member.NeedBuff, false); equal(next(member.knownBuffs), nil)
    equal(next(member.allBuffs), nil); equal(roster.byUnitId.raid23.auraDataUnavailable, false)
    equal(auraScan.version, version + 1)
    f.units.raid22.secretAuras = nil
    auraScan:Enqueue(roster, false, { raid22 = true })
    auraScan:ReadQueued(roster)
    equal(member.auraDataUnavailable, false); equal(member.NeedBuff, true)
  end

  -- Aura-free mode: the player's auras are unreadable
  rosterScan:Rebuild({ auras = {}, status = {} }, true)
  f:resetCalls()
  auraScan:SetAuraFree(roster)
  equal(f:calls("aura"), 0, "no aura is read in aura-free mode")
  equal(roster.player.auraDataUnavailable, true); equal(roster.player.knownBuffs[FORTITUDE], nil)
  equal(roster.player.NeedBuff, false)

  print("PASS: " .. (modern and "modern" or "legacy") .. " aura reads, budget, change detection and aura-free mode")
end

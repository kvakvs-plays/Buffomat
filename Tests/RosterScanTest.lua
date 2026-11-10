-- Run from the repository root: lua Tests/RosterScanTest.lua
-- The roster reader: subgroups, reused unit objects, identity by GUID, status, secret names.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local function setup(options)
  local f = fixture.new(options)
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvUnit.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/Scan/ScanStats.lua")
  f:load("Src/Core/Buff.lua")
  f:load("Src/Core/Unit.lua")
  local const = f:lib("Buffomat-Const")
  const.CLASS_ICONS = { PRIEST = "<priest>" }
  const.CLASS_COLOR = setmetatable({}, { __index = function() return { colorStr = "ff112233" } end })
  f:lib("Buffomat-NgStrings").FormatTexture = function(_, texture) return "<" .. tostring(texture) .. ">" end
  f:lib("Buffomat-Textures").ICON_PET = "pet"
  f:load("Src/Scan/RosterScan.lua")
  return f, f:lib("Buffomat-RosterScan")
end

local function pendingUnits()
  return { auras = {}, status = {} }
end

local function names(units)
  local list = {}
  for index, unit in ipairs(units) do list[index] = unit.name end
  return table.concat(list, ",")
end

for _, modern in ipairs({ false, true }) do
  local f, rosterScan = setup({ modern = modern })
  local roster = rosterScan.roster

  -- Alone: the player, and the pet when there is one
  local pending = pendingUnits()
  rosterScan:Rebuild(pending, false)
  equal(names(roster.units), "Tester"); equal(roster.player.unitId, "player"); equal(roster.player.isPlayer, true)
  equal(roster.player.class, "PRIEST"); equal(roster.player.group, 1); equal(roster.isRaid, false)
  equal(roster.player.link, "<priest>|Hunit:guid-Tester:Tester|h|cff112233Tester|r|h")
  equal(pending.auras.player, true, "a new unit is read in the same pass"); equal(pending.status.player, true)
  equal(roster.version, 1)
  f:unit("pet", { name = "Imp" })
  rosterScan:Rebuild(pendingUnits(), false)
  equal(names(roster.units), "Tester,Imp"); equal(roster.playerPet.class, "pet")
  equal(roster.playerPet.owner, roster.player)
  equal(roster.playerPet.link, "<pet>Imp")
  equal(roster.version, 2)

  -- The same group again is not a change
  pending = pendingUnits()
  rosterScan:Rebuild(pending, false)
  equal(roster.version, 2); equal(next(pending.auras), nil, "known units are not read again")

  -- A party: members and their pets are group 1
  f.state.inGroup = true
  f:unit("party1", { name = "Mage", class = "MAGE" })
  f:unit("party2", { name = "Hunter", class = "HUNTER", tank = true })
  f:unit("partypet2", { name = "Wolf" })
  rosterScan:Rebuild(pendingUnits(), false)
  equal(names(roster.units), "Tester,Imp,Mage,Hunter,Wolf")
  equal(roster.byUnitId.partypet2.owner, roster.byUnitId.party2); equal(roster.byUnitId.partypet2.group, 1)
  equal(roster.byUnitId.party2.isTank, true, "role from the dungeon finder")
  equal(#roster.groups[1], 5); equal(roster.byName.Mage, roster.byUnitId.party1)
  f.units.party1, f.units.party2, f.units.partypet2 = nil, nil, nil

  -- A raid whose slots are not ordered by subgroup
  f:raid({
    { name = "Rogue", class = "ROGUE", subgroup = 3 },
    { name = "Tank", class = "WARRIOR", subgroup = 2, role = "MAINTANK" },
    { name = "Tester", class = "PRIEST", subgroup = 2, isPlayer = true },
    { name = "Druid", class = "DRUID", subgroup = 1 },
    { name = "Shaman", class = "SHAMAN", subgroup = 3, combatRole = "TANK" },
    { name = "Paladin", class = "PALADIN", subgroup = 2 },
  })
  f:resetCalls()
  pending = pendingUnits()
  rosterScan:Rebuild(pending, false)
  equal(f:calls("roster"), 6, "one roster call per raid member")
  equal(roster.isRaid, true)
  equal(names(roster.units), "Tester,Imp,Tank,Paladin,Rogue,Druid,Shaman",
    "player, pet, the player's subgroup, then the rest")
  equal(roster.player.group, 2, "the player's subgroup comes from the raid slot")
  equal(roster.byUnitId.raid3, nil, "the player is listed once, as 'player'")
  equal(names(roster.groups[1]), "Druid"); equal(names(roster.groups[2]), "Tester,Imp,Tank,Paladin")
  equal(names(roster.groups[3]), "Rogue,Shaman")
  equal(roster.byUnitId.raid2.isTank, true); equal(roster.byUnitId.raid5.isTank, true)
  equal(roster.byUnitId.raid6.isTank, false)
  equal(pending.auras.raid1, true); equal(pending.auras.player, nil, "the player was known already")

  -- Moving a member to another subgroup changes the roster but not their auras
  local rogue = roster.byUnitId.raid1
  rogue.knownBuffs[42] = { singleId = 42 }
  local version = roster.version
  f.raidRoster[1].subgroup = 1
  pending = pendingUnits()
  rosterScan:Rebuild(pending, false)
  equal(roster.byUnitId.raid1, rogue); equal(rogue.group, 1); equal(rogue.knownBuffs[42].singleId, 42)
  equal(pending.auras.raid1, nil); equal(roster.version, version + 1)

  -- Another character behind the same unit id: same object, nothing known about it
  f.raidRoster[1].unit = f:unit("raid1", { name = "Warlock", class = "WARLOCK" })
  pending = pendingUnits()
  rosterScan:Rebuild(pending, false)
  equal(roster.byUnitId.raid1, rogue, "the unit object is reused"); equal(rogue.name, "Warlock")
  equal(rogue.class, "WARLOCK"); equal(next(rogue.knownBuffs), nil, "the old character's auras are gone")
  equal(pending.auras.raid1, true); equal(pending.status.raid1, true); equal(rogue.NeedBuff, false)

  -- Two players with the same name from different realms
  f.raidRoster[4].unit = f:unit("raid4",
    { name = "Warlock", realm = "OtherRealm", guid = "guid-other", class = "WARLOCK" })
  rosterScan:Rebuild(pendingUnits(), false)
  equal(roster.byName.Warlock, roster.byUnitId.raid1)
  equal(roster.byName["Warlock-OtherRealm"], roster.byUnitId.raid4, "the second keeps its realm")

  -- Status: dead, ghost, offline, other zone, incoming resurrection
  rosterScan:ReadStatuses(true, false, {})
  version = roster.version
  local tank = roster.byUnitId.raid2
  equal(tank.isDead, false); equal(tank.isConnected, true); equal(tank.isSameZone, true); equal(roster.hasDead, false)
  f.units.raid2.dead, f.units.raid2.map = true, 7
  f:resetCalls()
  rosterScan:ReadStatuses(false, false, { raid2 = true })
  equal(tank.isDead, true); equal(tank.isSameZone, false); equal(roster.hasDead, true)
  equal(roster.version, version + 1)
  rosterScan:ReadStatuses(false, false, { raid2 = true })
  equal(roster.version, version + 1, "an unchanged status is not a change")
  f.units.raid2.incomingRes = true
  rosterScan:ReadStatuses(false, true, {})
  equal(tank.hasResurrection, true)
  f.units.raid2.incomingRes = false
  rosterScan:ReadStatuses(false, true, {})
  equal(tank.hasResurrection, true, "a resurrection is remembered after the cast event passed")
  rosterScan:ForgetResurrections()
  equal(tank.hasResurrection, false)
  f.units.raid2.dead, f.units.raid2.ghost = false, true
  rosterScan:ReadStatuses(false, true, {})
  equal(tank.isGhost, true); equal(tank.isSameZone, true, "a ghost counts as in the zone")
  f.units.raid2.ghost, f.units.raid2.connected = false, false
  rosterScan:ReadStatuses(true, false, {})
  equal(tank.isConnected, false); equal(tank.isDead, false); equal(roster.hasDead, false)

  -- A target outside the group, with the BuffTarget option
  f:unit("target", { name = "Stranger", class = "MAGE" })
  rosterScan:Rebuild(pendingUnits(), false)
  equal(roster.target, nil, "strangers are ignored without the option")
  f.globals.BuffomatShared.BuffTarget = true
  pending = pendingUnits()
  rosterScan:Rebuild(pending, false)
  equal(roster.target.name, "Stranger"); equal(roster.byUnitId.target, roster.target); equal(pending.auras.target, true)
  f.globals.BuffomatShared.BuffTarget = false

  if modern then
    -- A hidden name: that member is left out and the roster says it is partial
    f.units.raid5.secretName = true
    rosterScan:Rebuild(pendingUnits(), false)
    equal(roster.byUnitId.raid5, nil); equal(roster.incomplete, true)
    f.units.raid5.secretName = nil
    rosterScan:Rebuild(pendingUnits(), false)
    equal(roster.incomplete, false); equal(roster.byUnitId.raid5.name, "Shaman")
  end

  -- Aura-free mode: the player only, whatever the group
  version = roster.version
  rosterScan:Rebuild(pendingUnits(), true)
  equal(names(roster.units), "Tester"); equal(roster.playerPet, nil); equal(roster.isRaid, false)
  equal(roster.incomplete, false); equal(roster.version, version + 1); equal(rosterScan.playerOnly, true)

  -- Leaving the group: back to the player and pet, group 1
  f:solo()
  rosterScan:Rebuild(pendingUnits(), false)
  equal(names(roster.units), "Tester,Imp"); equal(roster.isRaid, false); equal(roster.player.group, 1)
  equal(#roster.groups[2], 0); equal(roster.byUnitId.raid1, nil)

  print("PASS: " .. (modern and "modern" or "legacy") .. " roster order, subgroups, identity, status and modes")
end

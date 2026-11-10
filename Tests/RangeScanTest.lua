-- Run from the repository root: lua Tests/RangeScanTest.lua
-- The range reader: distances are measured on demand, once per pass, and task targets use them.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

for _, raidWide in ipairs({ false, true }) do
  local f = fixture.new({})
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvUnit.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/Scan/ScanStats.lua")
  f:load("Src/Scan/RangeScan.lua")
  f:load("Src/Core/UnitBuffTarget.lua")
  f:load("Src/Core/GroupBuffTarget.lua")
  f:lib("KvLibShared-Env").groupBuffsRaidWide = raidWide
  local kvUnit, range = f:lib("KvLibShared-Unit"), f:lib("Buffomat-RangeScan")
  local unitTargets, groupTargets = f:lib("Buffomat-UnitBuffTarget"), f:lib("Buffomat-GroupBuffTarget")

  local function member(unitId, class, group, distance, fields)
    f:unit(unitId, { name = unitId, class = class, distance = distance })
    local unit = { unitId = unitId, class = class, group = group, isConnected = true, isDead = false }
    for key, value in pairs(fields or {}) do unit[key] = value end
    return unit
  end
  local player = member("player", "PRIEST", 2, 0, { isPlayer = true })
  local warrior = member("raid2", "WARRIOR", 1, 400)
  local mage = member("raid3", "MAGE", 1, 100)
  local deadMage = member("raid4", "MAGE", 1, 25, { isDead = true })
  local offlineMage = member("raid5", "MAGE", 3, 9, { isConnected = false })
  local rogue = member("raid6", "ROGUE", 2, 900)
  local pet = member("raidpet6", "pet", 2, 1)
  local roster = { isRaid = true, player = player,
    units = { player, rogue, pet, warrior, mage, deadMage, offlineMage },
    groups = { { warrior, mage, deadMage }, { player, rogue, pet }, { offlineMage }, {}, {}, {}, {}, {} } }
  f:lib("Buffomat-RosterScan").roster = roster

  -- Nothing is measured until somebody asks, and then once per pass
  f:resetCalls()
  range:BeginPass()
  equal(f:calls("distance"), 0)
  equal(range:Distance(warrior), 400); equal(range:Distance(warrior), 400)
  equal(f:calls("distance"), 1, "one measurement per unit and pass")
  f.units.raid2.distance = 1600
  equal(range:Distance(warrior), 400, "the same pass keeps its measurement")
  range:BeginPass()
  equal(range:Distance(warrior), 1600, "the next pass measures again")
  equal(mage.distanceEpoch, nil, "units nobody asked about are never measured")

  -- Nearest members: the dead, the offline and pets do not count
  range:BeginPass()
  equal(range:NearestInGroup(roster, 1, true), 100, "the dead mage is nearer but does not count")
  equal(range:NearestInGroup(roster, 3, true), kvUnit.TOO_FAR, "only an offline member")
  equal(range:NearestInGroup(roster, 4, true), kvUnit.TOO_FAR, "an empty group")
  equal(range:NearestInGroup(roster, 2, true), 0, "the player's own group")
  equal(range:NearestInGroup(roster, 2, false), 900, "without the player, and not the pet")
  equal(range:NearestOfClass(roster, "MAGE"), 100)
  equal(range:NearestOfClass(roster, "PALADIN"), kvUnit.TOO_FAR)

  -- Task targets
  equal(unitTargets:FromUnit(warrior):GetDistance(), 1600)
  equal(unitTargets:FromSelf(player):GetDistance(), 0)
  equal(unitTargets:FromUnit(rogue):GetText(), "raid6")
  equal(groupTargets:New(0):GetDistance(), 0, "a raid-wide group buff is cast on the player")
  equal(groupTargets:New("MAGE"):GetDistance(), 100, "a blessing reaches for the nearest of the class")
  equal(groupTargets:New(1):GetDistance(), raidWide and 0 or 100)
  equal(groupTargets:New(2):GetDistance(), 0)
  roster.isRaid = false
  equal(groupTargets:New(2):GetDistance(), raidWide and 0 or 900, "in a party the player alone is not a group")

  print("PASS: range measurement on demand, " .. (raidWide and "raid-wide" or "per-group") .. " group buffs")
end

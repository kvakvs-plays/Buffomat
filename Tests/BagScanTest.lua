-- Run from the repository root: lua Tests/BagScanTest.lua
-- The bag reader: one walk builds the index, cooldowns are read lazily, repeats change nothing.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

for _, modern in ipairs({ false, true }) do
  local f = fixture.new({ modern = modern, forever = modern })
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/Const/ItemIds.lua")
  f:load("Src/Scan/ScanStats.lua")
  f:load("Src/Scan/BagScan.lua")
  f:load("Src/BuffChecks.lua")
  local env, bags, checks = f:lib("KvLibShared-Env"), f:lib("Buffomat-BagScan"), f:lib("Buffomat-BuffChecks")
  local scheduler = f:lib("Buffomat-ScanScheduler")
  local wakes = {}
  scheduler.WakeAt = function(_, time, domain) wakes[#wakes + 1] = { time = time, domain = domain } end
  env.IsContainerItemLockedBox = function(bag, slot) return f.bags[bag][slot].lockedBox end

  equal(bags:Find(100), nil, "nothing is known before the first walk")
  f:item(0, 1, 100, 5)
  f:item(0, 3, 200, 1)
  f:item(2, 4, 100, 20)
  f:item(4, 16, 300, 2)
  if modern then
    f:item(5, 2, 400, 7) -- the reagent bag exists on Forever
  else
    f:item(5, 2, 400, 7) -- bag 5 is the first bank bag on Classic and is not walked
  end
  f:resetCalls()
  equal(bags:Read(), true)
  local slotReads = f:calls("bagSlot")
  equal(slotReads, modern and 64 or 48, "every slot of every player bag is read once")
  equal(bags.version, 1)

  -- A stack split over two bags sums, and reports its first slot
  local item = bags:Find(100)
  equal(item.count, 25); equal(item.bag, 0); equal(item.slot, 1); equal(item.link, "item:100")
  equal(bags:Count(100), 25); equal(bags:Count(300), 2); equal(bags:Count(999), 0)
  equal(bags:Count(400), modern and 7 or 0, "reagent bag only where the client has one")

  -- Lookups read nothing
  f:resetCalls()
  local has, bag, slot, count = checks:HasOneItem(100, false)
  equal(has, true); equal(bag, 0); equal(slot, 1); equal(count, 25)
  has, bag, slot, count = checks:HasOneItem(999, true)
  equal(has, false); equal(bag, nil); equal(slot, nil); equal(count, 0)
  has, bag, slot, count = checks:HasOneItem(nil, true)
  equal(has, true); equal(count, 1, "no item required")
  equal(bag, nil); equal(slot, nil)
  equal(f:calls("bagSlot"), 0); equal(f:calls("cooldown"), 0)

  -- Cooldowns are read once per item, only when asked, and wake the scheduler when they end
  has = checks:HasOneItem(100, true)
  equal(has, true); equal(f:calls("cooldown"), 1)
  checks:HasOneItem(100, true)
  equal(f:calls("cooldown"), 1, "the cooldown is remembered")
  equal(#wakes, 0)
  f.bags[0][1].cooldownStart, f.bags[0][1].cooldownDuration = 990, 60
  bags:InvalidateCooldowns()
  equal(bags.version, 2, "a cooldown change is a change")
  has, bag, slot, count = checks:HasOneItem(100, true)
  equal(has, false, "on cooldown"); equal(bag, 0); equal(slot, 1); equal(count, 25)
  equal(f:calls("cooldown"), 2)
  equal(#wakes, 1); equal(wakes[1].time, 1050, "absolute time the cooldown ends")
  equal(wakes[1].domain, "bagCooldowns")
  equal(checks:HasOneItem(100, false), true, "without the cooldown check the item counts")

  -- The same contents again: no new version, so nothing is evaluated again
  equal(bags:Read(), false)
  equal(bags.version, 2)
  equal(bags:Find(100).count, 25)
  f:item(2, 4, 100, 19) -- one used
  equal(bags:Read(), true)
  equal(bags.version, 3); equal(bags:Count(100), 24)
  f:item(0, 3, nil)
  f:item(0, 4, 200, 1) -- same item moved to another slot
  equal(bags:Read(), true, "a moved item changes the slot a macro would use")
  equal(bags:Find(200).slot, 4)

  -- Containers to open: only with the option on, and not while locked
  f:item(1, 1, 500, 1, { hasLoot = true })
  f:item(1, 2, 501, 1, { hasLoot = true, lockedBox = true })
  f:item(1, 3, f:lib("Buffomat-ItemIds").Classic_BigmouthClam, 3)
  bags:Read()
  equal(#bags.openable, 0, "openable containers are not collected with the option off")
  equal(bags:NeedsRead(), false)
  f.globals.BuffomatShared.OpenLootable = true
  equal(bags:NeedsRead(), true, "the option changed what a walk collects")
  equal(bags:Read(), true)
  equal(#bags.openable, 2)
  equal(bags.openable[1].itemId, 500); equal(bags.openable[1].bag, 1); equal(bags.openable[1].slot, 1)
  equal(bags.openable[2].slot, 3, "clams count as openable")

  -- Records are reused between walks
  local before = bags:Find(100)
  bags:Read()
  local seen = false
  for _, record in pairs(bags.byItemId) do
    if record == before then seen = true end
  end
  for _, record in ipairs(bags.openable) do
    if record == before then seen = true end
  end
  equal(seen, true, "no new tables in a steady-state walk")

  print("PASS: " .. (modern and "Forever" or "legacy") .. " bag index, cooldowns, change detection and openables")
end

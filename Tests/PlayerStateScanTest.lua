-- Run from the repository root: lua Tests/PlayerStateScanTest.lua
-- The player state reader: activity state, mana, tracking, equipment and weapon enchants.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

for _, modern in ipairs({ false, true }) do
  local f = fixture.new({ modern = modern, forever = modern })
  local tracking = { { name = "Find Herbs", active = false, spellId = 2383 },
    { name = "Find Minerals", active = true, spellId = 2580 } }
  if modern then
    f.globals.C_Minimap = {
      GetNumTrackingTypes = function() return #tracking end,
      GetTrackingInfo = function(index)
        local info = tracking[index]
        return { name = info.name, texture = 1, active = info.active, type = "spell", spellID = info.spellId }
      end,
      SetTracking = function() end,
    }
  else
    f.globals.GetTrackingTexture = function() return f.state.trackingTexture end
  end
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/KvLib/KvUnit.lua")
  f:load("Src/KvLib/KvPlayer.lua")
  f:load("Src/Scan/PlayerStateScan.lua")
  local state = f:lib("Buffomat-PlayerStateScan")
  local allBuffs = f:lib("Buffomat-AllBuffs")
  allBuffs.enchantToSpellLookup = { [10] = 100, [20] = 200 }

  -- The first read fills everything; the same state again is not a change
  f.state.mana, f.state.maxMana = 400, 1000
  equal(state:Read(), true)
  equal(state.version, 1); equal(state.mana, 400); equal(state.maxMana, 1000)
  equal(state.isMounted, false); equal(state.isResting, false); equal(state.isDead, false)
  equal(state.isOutdoors, true); equal(state.instanceType, "none"); equal(state.formId, nil); equal(state.form, 0)
  equal(state.hasPet, false); equal(state.isInVehicle, false); equal(state.isFlying, false)
  equal(state:Read(), false)
  equal(state.version, 1)

  f.state.mounted, f.state.resting, f.state.instanceType, f.state.instanceId = true, true, "raid", 533
  f.state.formId, f.state.form, f.state.mana = 5, 2, 380
  f.units.player.pvp = true
  f:unit("pet", { name = "Imp", creatureType = 3, creatureFamily = 23 })
  equal(state:Read(), true)
  equal(state.version, 2); equal(state.isMounted, true); equal(state.isResting, true)
  equal(state.instanceType, "raid"); equal(state.instanceId, 533); equal(state.formId, 5); equal(state.form, 2)
  equal(state.mana, 380); equal(state.isPvP, true)
  equal(state.hasPet, true); equal(state.petCreatureTypeId, 3); equal(state.petCreatureFamilyId, 23)
  f.units.player.dead = true
  state:Read()
  equal(state.isDead, true)

  if modern then
    -- Hidden mana must not look like an empty mana bar
    f.state.mana = f.secret
    state:Read()
    equal(state.mana, 1000, "hidden mana counts as full")
    f.state.mana, f.state.maxMana = f.secret, f.secret
    state:Read()
    equal(state.mana, math.huge); equal(state.maxMana, 0)
    f.state.mana, f.state.maxMana = 380, 1000
  end

  -- Tracking: a set of active spells with tracking settings, one icon without
  local herbs = { singleFamily = { 2383 }, trackingIconId = "herbs" }
  local minerals = { singleFamily = { 2580 }, trackingIconId = "minerals" }
  f.state.trackingTexture = "minerals"
  state:Read()
  equal(state:IsTrackingActive(minerals), true); equal(state:IsTrackingActive(herbs), false)
  local version = state.version
  tracking[1].active, tracking[2].active = true, false
  f.state.trackingTexture = "herbs"
  equal(state:Read(), true, "a tracking change is a change")
  equal(state.version, version + 1)
  equal(state:IsTrackingActive(herbs), true); equal(state:IsTrackingActive(minerals), false)

  -- Equipment and weapon enchants
  local player = {}
  f.state.inventory = { [13] = 11122, [16] = 500, [17] = 501 }
  f.state.weapon.main = { timeLeft = 120000, enchantId = 10 }
  f.state.weapon.off = { timeLeft = 60000, enchantId = 20 }
  version = state.version
  equal(state:ReadEquipment(player), true)
  equal(state.version, version + 1)
  equal(state.inventory[16], 500); equal(state.inventory[13], 11122); equal(state.inventory[14], nil)
  equal(state.inventoryLinks[17], "item:501")
  equal(state.hasMainhandEnchant, true); equal(state.mainhandBuffId, 100); equal(state.offhandBuffId, 200)
  equal(state.enchantExpiresAt, f.state.now + 60, "milliseconds left become the earliest absolute end time")
  equal(player.mainhandEnchantment, 100); equal(player.offhandEnchantment, 200)
  equal(player.weaponDataUnavailable, false)
  equal(state:ReadEquipment(player), false, "the same equipment again is not a change")
  equal(state.version, version + 1)

  -- An enchant Buffomat does not know still counts as an enchant
  f.state.weapon.main = { timeLeft = 5000, enchantId = 999 }
  f.state.weapon.off = false
  equal(state:ReadEquipment(player), true)
  equal(state.hasMainhandEnchant, true); equal(state.mainhandBuffId, nil); equal(player.mainhandEnchantment, nil)
  equal(state.hasOffhandEnchant, false); equal(player.offhandEnchantment, nil)
  equal(state.enchantExpiresAt, f.state.now + 5)
  f.state.weapon.main = false
  state:ReadEquipment(player)
  equal(state.hasMainhandEnchant, false); equal(state.enchantExpiresAt, nil)

  if modern then
    -- Unreadable enchants are not "no enchant"
    f.state.weapon.main = { timeLeft = 120000, enchantId = 10 }
    state:ReadEquipment(player)
    equal(player.mainhandEnchantment, 100)
    f.state.weapon.secret = true
    equal(state:ReadEquipment(player), true)
    equal(state.weaponUnavailable, true); equal(player.weaponDataUnavailable, true)
    equal(player.mainhandEnchantment, nil); equal(state.enchantExpiresAt, nil)
    f.state.weapon.secret = nil
    state:ReadEquipment(player)
    equal(state.weaponUnavailable, false); equal(player.weaponDataUnavailable, false)
    equal(player.mainhandEnchantment, 100)
  end

  print("PASS: " .. (modern and "Forever" or "legacy") .. " player state, tracking, equipment and weapon enchants")
end

-- Run from the repository root: lua Tests/KvEnvTest.lua
-- These fixtures deliberately omit the APIs removed from modern clients.
local function loadModule(path, globals)
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, globals)
  else
    chunk = assert(loadfile(path, "t", globals))
  end
  return chunk("BuffomatClassic", {})
end

local function equal(actual, expected, label)
  assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function fixture(mode, projectID)
  local libs = {}
  local state = { range = true, cooldown = { startTime = 10, duration = 20, isEnabled = false, modRate = 0.5 } }
  local secret = setmetatable({}, {
    __add = function() error("secret arithmetic") end,
    __lt = function() error("secret comparison") end,
  })
  local globals = setmetatable({
    WOW_PROJECT_ID = projectID,
    WOW_PROJECT_MAINLINE = 1,
    WOW_PROJECT_CLASSIC = 2,
    WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5,
    WOW_PROJECT_WRATH_CLASSIC = 11,
    WOW_PROJECT_CATACLYSM_CLASSIC = 14,
    UnitClass = function() return "Mage", "MAGE" end,
    BuffomatAddon = {},
    GetNetStats = function() return 0, 0, 20, 20 end,
    issecretvalue = mode ~= "legacy" and function(value) return rawequal(value, secret) end or nil,
    LibStub = function(name)
      libs[name] = libs[name] or {}
      return libs[name]
    end,
  }, { __index = _G })
  globals._G = globals

  local function itemInfo(id)
    if id == 99 and not state.itemLoaded then return nil end
    return "Item", "item:42", 2, 60, 50, "Armor", "Cloth", 1, "INVTYPE_HEAD", 101, 100, 4, 1, 2, 0, nil, false
  end
  local function spellInfo(id)
    assert(id ~= nil, "GetSpellInfo requires a spell identifier")
    if id == 99 and not state.spellLoaded then return nil end
    return "Spell", "Rank 2", 102, 1500, 0, 30, id, 103
  end
  local function cooldown()
    local info = state.cooldown
    if info == nil then return nil end
    return info.startTime, info.duration, info.isEnabled and 1 or 0, info.modRate
  end
  local function containerInfo(_, slot)
    if slot == 2 then return nil end
    return 101, 3, false, 2, false, true, "item:42", false, false, 42, true
  end
  local function trackingInfo(index)
    if index == 2 then return nil end
    return "Find Herbs", 104, false, "spell", 0, 2383
  end
  local powerCosts = { { name = "MANA", cost = 25, type = 0 } }
  local legacy = {
    GetItemInfo = itemInfo,
    GetSpellInfo = spellInfo,
    GetSpellSubtext = function(id)
      assert(id ~= nil, "GetSpellSubtext requires a spell identifier")
      return "Rank 2"
    end,
    GetSpellCooldown = cooldown,
    GetSpellPowerCost = function() return powerCosts end,
    IsSpellInRange = function()
      if state.range == nil then return nil end
      return state.range and 1 or 0
    end,
    IsSpellKnown = function(id, isPet) state.bank = isPet; return id == 42 end,
    GetAddOnMetadata = function(_, field) return field end,
    GetContainerNumSlots = function() return 2 end,
    GetContainerItemCooldown = function() return 10, 20, 1 end,
    GetContainerItemInfo = containerInfo,
    GetNumTrackingTypes = function() return 1 end,
    GetTrackingInfo = trackingInfo,
    SetTracking = function(index, on) state.tracking = { index, on } end,
    GetTrackingTexture = function() return 104 end,
  }
  if mode ~= "modern" then
    for name, fn in pairs(legacy) do globals[name] = fn end
  end
  if mode == "legacy" then
    globals.GetSpellSubtext = nil -- Older clients can supply the rank in GetSpellInfo.
  end
  if mode ~= "legacy" then
    globals.Enum = { SpellBookSpellBank = { Player = 0, Pet = 1 } }
    globals.C_AddOns = { GetAddOnMetadata = legacy.GetAddOnMetadata }
    globals.C_Item = { GetItemInfo = itemInfo }
    globals.C_Spell = {
      GetSpellInfo = function(id)
        local name, _, icon, castTime, minRange, maxRange, spellID, originalIcon = spellInfo(id)
        if name == nil then return nil end
        return { name = name, iconID = icon, castTime = castTime, minRange = minRange,
          maxRange = maxRange, spellID = spellID, originalIconID = originalIcon }
      end,
      GetSpellSubtext = legacy.GetSpellSubtext,
      GetSpellCooldown = function() return state.cooldown end,
      GetSpellPowerCost = legacy.GetSpellPowerCost,
      IsSpellInRange = function() return state.range end,
    }
    globals.C_SpellBook = { IsSpellKnown = function(id, bank) state.bank = bank; return id == 42 end }
    globals.C_Container = {
      GetContainerNumSlots = legacy.GetContainerNumSlots,
      GetContainerItemCooldown = legacy.GetContainerItemCooldown,
      GetContainerItemInfo = function(_, slot)
        if slot == 2 then return nil end
        return { iconFileID = 101, stackCount = 3, isLocked = false, quality = 2,
          isReadable = false, hasLoot = true, hyperlink = "item:42", isFiltered = false,
          hasNoValue = false, itemID = 42, isBound = true }
      end,
    }
    globals.C_Minimap = {
      GetNumTrackingTypes = legacy.GetNumTrackingTypes,
      GetTrackingInfo = function(index)
        if index == 2 then return nil end
        return { name = "Find Herbs", texture = 104, active = false, type = "spell", subType = 0, spellID = 2383 }
      end,
      SetTracking = legacy.SetTracking,
    }
    if mode == "mixed" then
      -- Present-but-incomplete namespaces must fall back per function.
      globals.C_Item.GetItemInfo = nil
      globals.C_Spell.GetSpellSubtext = nil
      globals.C_Minimap.GetTrackingInfo = nil
      globals.C_Container.GetContainerNumSlots = nil
      globals.GetSpellInfo = function() error("modern spell info was not preferred") end
    end
  end

  loadModule("Src/KvLib/KvEnv.lua", globals)
  local env = libs["KvLibShared-Env"]
  equal(env.GetAddOnMetadata("BuffomatClassic", "Title"), "Title")
  equal(env.GetAddonMetadata, env.GetAddOnMetadata)
  equal(env.GetSpellInfo(nil), nil, "missing spell identifier")
  equal(env.GetSpellSubtext(nil), nil, "missing spell rank identifier")
  equal(env.GetItemInfo(99), nil, "uncached item")
  equal(select(17, env.GetItemInfo(42)), false, "item tuple preserves trailing fields")
  local name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon = env.GetSpellInfo(42)
  equal(name, "Spell"); equal(rank, "Rank 2"); equal(icon, 102); equal(castTime, 1500)
  equal(minRange, 0); equal(maxRange, 30); equal(spellID, 42); equal(originalIcon, 103)
  equal(env.GetSpellInfo(99), nil, "uncached spell")
  equal(env.GetSpellPowerCost(42), powerCosts)
  local start, duration, enabled, rate = env.GetSpellCooldown(42)
  equal(start, 10); equal(duration, 20); equal(enabled, 0); equal(rate, 0.5)
  state.cooldown.isEnabled = true
  equal(select(3, env.GetSpellCooldown(42)), 1)
  equal(env.IsSpellInRange(42, "party1"), 1)
  state.range = false
  equal(env.IsSpellInRange(42, "party1"), 0)
  state.range = nil
  equal(env.IsSpellInRange(42, "party1"), nil)
  equal(env.IsSpellKnown(42), true)
  if mode == "legacy" then equal(state.bank, nil) else equal(state.bank, 0) end
  equal(env.IsSpellKnown(42, true), true)
  equal(state.bank, mode == "legacy" and true or 1)
  equal(env.IsSpellKnown(99), false)
  local bag = env.GetContainerItemInfo(0, 1)
  equal(bag.itemID, 42); equal(bag.hasLoot, true); equal(bag.isLocked, false); equal(bag.stackCount, 3)
  equal(env.GetContainerItemInfo(0, 2), nil)
  equal(env.GetContainerNumSlots(0), 2)
  equal(select(3, env.GetContainerItemCooldown(0, 1)), 1)
  local trackingName, texture, active, category, nesting, trackingSpell = env.GetTrackingInfo(1)
  equal(trackingName, "Find Herbs"); equal(texture, 104); equal(active, false)
  equal(category, "spell"); equal(nesting, 0); equal(trackingSpell, 2383)
  equal(env.GetTrackingInfo(2), nil)
  equal(env.usesTrackingSettings, mode == "modern" or projectID ~= 2)
  env.SetTracking(1, true)
  equal(state.tracking[1], 1); equal(state.tracking[2], true)

  if mode ~= "legacy" then
    state.range = secret
    equal(env.IsSpellInRange(42, "party1"), nil, "secret range")
    for _, key in ipairs({ "startTime", "duration", "isEnabled", "modRate" }) do
      local saved = state.cooldown[key]
      state.cooldown[key] = secret
      equal(env.GetSpellCooldown(42), nil, "secret cooldown " .. key)
      state.cooldown[key] = saved
    end
  end
  state.cooldown = nil
  equal(env.GetSpellCooldown(42), nil)

  -- Check real consumers as well as adapter tuples: nil data is not castable.
  libs["Buffomat-Task"] = { CAN_CAST_ON_CD = "cooldown" }
  loadModule("Src/Task/ActionCast.lua", globals)
  local action = libs["Buffomat-ActionCast"]:New(0, 42, "", {}, nil, false)
  equal(action:CanCast(), "cooldown")
  loadModule("Src/Task/TaskScan.lua", globals)
  equal(libs["Buffomat-TaskScan"]:IsInGlobalCooldown(), true)

  -- Item/Spell mixins request data and dispatch DATA_LOAD_RESULT in the client.
  -- Simulate their delayed completion with modern globals absent throughout.
  globals.C_Item = globals.C_Item or {}
  globals.C_Spell = globals.C_Spell or {}
  globals.C_Item.DoesItemExistByID = function() return true end
  globals.C_Spell.DoesSpellExist = function() return true end
  globals.Item = { CreateFromItemID = function()
    return {
      ContinueOnItemLoad = function(_, callback) state.itemCallback = callback end,
      GetItemName = function() return "Item" end,
      GetItemLink = function() return "item:42" end,
      GetItemQuality = function() return 2 end,
      GetItemIcon = function() return 101 end,
    }
  end }
  globals.Spell = { CreateFromSpellID = function()
    return {
      ContinueOnSpellLoad = function(_, callback) state.spellCallback = callback end,
      GetSpellName = function() return "Spell" end,
    }
  end }
  libs["Buffomat-Throttle"].RequestTaskRescan = function() state.rescanned = true end
  loadModule("Src/Cache/ItemCache.lua", globals)
  loadModule("Src/Cache/SpellCache.lua", globals)
  equal(globals.BuffomatAddon.GetSpellInfo(nil), nil, "missing cached spell identifier")
  equal(globals.BuffomatAddon.GetItemInfo(99), nil)
  equal(globals.BuffomatAddon.GetSpellInfo(99), nil)
  local itemResult, spellResult
  libs["Buffomat-ItemCache"]:LoadItem(99, function(result) itemResult = result end)
  libs["Buffomat-SpellCache"]:LoadSpell(99, function(result) spellResult = result end)
  equal(itemResult, nil); equal(spellResult, nil)
  state.itemLoaded = true; state.spellLoaded = true
  state.itemCallback(); state.spellCallback()
  equal(itemResult.itemName, "Item"); equal(itemResult.itemSubClassID, 1)
  equal(spellResult.name, "Spell"); equal(spellResult.rank, "Rank 2"); equal(spellResult.spellId, 99)
  equal(globals.BuffomatAddon.GetItemInfo(99), itemResult)
  equal(globals.BuffomatAddon.GetSpellInfo(99), spellResult)
  equal(state.rescanned, true)

  -- Reproduce SPELLS_CHANGED setup with item-only trinket reminder definitions.
  globals.BuffomatAddon.reputationTrinketZones = { itemIds = {}, zoneId = {} }
  globals.BuffomatAddon.ridingSpeedZones = { itemIds = {}, zoneId = {} }
  globals.BuffomatAddon.cancelBuffs = {}
  globals.BuffomatCharacter = { profiles = { solo = {} } }
  globals.BuffomatShared = {}
  globals.wipe = function(values) for key in pairs(values) do values[key] = nil end end
  libs["Buffomat-Profile"].ALL_PROFILES = { "solo" }
  libs["Buffomat-Profile"].NewBlessingState = function() return {} end
  local allBuffs = libs["Buffomat-AllBuffs"]
  allBuffs.selectedBuffs = { 42 }
  allBuffs.selectedBuffsSpellIds = {}
  allBuffs.spellIdtoBuffId = {}
  allBuffs.allBuffs = {}
  loadModule("Src/SpellSetup.lua", globals)
  libs["Buffomat-SpellSetup"]:SetupAvailableSpells()
  equal(#allBuffs.selectedBuffs, 0, "spell setup completed")
  equal(type(globals.BuffomatCharacter.profiles.solo.Spell), "table")
  equal(globals.BuffomatAddon.reputationTrinketZones.Link, nil, "no fabricated reputation spell link")
  equal(globals.BuffomatAddon.ridingSpeedZones.Link, nil, "no fabricated riding spell link")
  print("PASS: " .. mode .. " project " .. projectID .. " API adapters, consumers, and delayed caches")
end

for _, projectID in ipairs({ 2, 5, 11, 14 }) do fixture("legacy", projectID) end
fixture("modern", 1)
fixture("mixed", 2)

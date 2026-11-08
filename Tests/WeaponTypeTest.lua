-- Run from the repository root: lua Tests/WeaponTypeTest.lua
-- Weapon enchantments limited to some weapon types (Forever Imbue scrolls) are asked for only on a
-- weapon of a fitting type, on both modern (C_Item) and legacy (global) item APIs.
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
  assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

-- Equipped items: item id -> { classID, subclassID }
local ITEMS = {
  [1] = { 2, 10 }, -- staff
  [2] = { 2, 15 }, -- dagger
  [3] = { 2, 7 },  -- one-handed sword
  [4] = { 4, 6 },  -- shield (armor)
}

for _, mode in ipairs({ "modern", "legacy" }) do
  local libs = {}
  local state = { equipped = {}, profile = { MainHandEnable = true, OffHandEnable = true } }
  local function getItemInfoInstant(itemId)
    local info = ITEMS[itemId]
    return itemId, "", "", "", 0, info[1], info[2]
  end
  local globals = setmetatable({
    WOW_PROJECT_ID = mode == "modern" and 18 or 2, WOW_PROJECT_CLASSIC = 2,
    GetBuildInfo = function() return "", "", "", mode == "modern" and 16001 or 11508 end,
    LE_EXPANSION_LEVEL_CURRENT = 0,
    UnitClass = function() return "Mage", "MAGE" end,
    InCombatLockdown = function() return false end,
    NUM_BAG_SLOTS = 4,
    GetInventoryItemID = function(_, slot) return state.equipped[slot] end,
    tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end,
    BuffomatAddon = {},
    LibStub = function(name) libs[name] = libs[name] or {}; return libs[name] end,
  }, { __index = _G })
  globals._G = globals
  if mode == "modern" then
    globals.C_Item = { GetItemInfoInstant = getItemInfoInstant }
  else
    globals.GetItemInfoInstant = getItemInfoInstant
  end
  libs["Buffomat-Profile"] = { GetProfileBuff = function() return state.profile end }
  loadModule("Src/KvLib/KvEnv.lua", globals)
  loadModule("Src/Const/ItemIds.lua", globals)
  loadModule("Src/BuffChecks.lua", globals)
  local checks, ids = libs["Buffomat-BuffChecks"], libs["Buffomat-ItemIds"]

  local staffScroll = { buffId = 1, weaponSubclasses = { ids.WeaponSubclass.Staff }, unitsNeedBuff = {} }
  local daggerScroll = { buffId = 2, weaponSubclasses = { ids.WeaponSubclass.Dagger }, unitsNeedBuff = {} }
  local anyOil = { buffId = 3, unitsNeedBuff = {} }
  local player = {}

  state.equipped = { [16] = 1 } -- staff
  equal(checks:WeaponFitsBuff(staffScroll, 16), true, mode .. " staff takes a staff scroll")
  equal(checks:WeaponFitsBuff(daggerScroll, 16), false, mode .. " staff refuses a dagger scroll")
  equal(checks:WeaponFitsBuff(daggerScroll, 17), false, mode .. " empty off hand")
  equal(checks:WeaponFitsBuff(anyOil, 17), true, mode .. " unlimited buff keeps the old behaviour")

  state.equipped = { [16] = 3, [17] = 2 } -- sword and dagger
  local main, off = checks:WeaponHandsNeedingBuff(daggerScroll, player)
  equal(main, false, mode .. " sword main hand does not need the dagger scroll")
  equal(off, true, mode .. " dagger off hand needs it")
  checks:PlayerNeedsWeaponBuff(daggerScroll, player)
  equal(#daggerScroll.unitsNeedBuff, 1, mode .. " player needs the dagger scroll")
  checks:PlayerNeedsWeaponBuff(staffScroll, player)
  equal(#staffScroll.unitsNeedBuff, 0, mode .. " no staff, no staff scroll task")

  player.offhandEnchantment = 8698
  local _, enchantedOff = checks:WeaponHandsNeedingBuff(daggerScroll, player)
  equal(enchantedOff, false, mode .. " an enchanted off hand needs nothing")

  state.equipped = { [16] = 2, [17] = 4 } -- dagger and shield
  player.offhandEnchantment = nil
  main, off = checks:WeaponHandsNeedingBuff(daggerScroll, player)
  equal(main, true, mode .. " dagger main hand"); equal(off, false, mode .. " a shield is not a weapon")

  state.profile.MainHandEnable = false
  main = checks:WeaponHandsNeedingBuff(daggerScroll, player)
  equal(main, false, mode .. " disabled main hand")
  print("PASS: " .. mode .. " weapon type limits for weapon enchantments")
end

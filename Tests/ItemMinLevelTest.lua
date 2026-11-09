-- Run from the repository root: lua Tests/ItemMinLevelTest.lua
-- A consumable buff takes the lowest required level of its items as its minLevel, so it stays hidden
-- until the player can use one of them. Item data may load later than spell setup.
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

-- Item id -> required level. Items missing here do not exist in this client.
local ITEM_LEVELS = { [274947] = 5, [277503] = 46, [2862] = 1, [12404] = 35 }

local libs = {}
local cached = {}   -- items whose data is already loaded
local waiting = {}  -- load callbacks for items still loading
local setupRequests = 0
local playerLevel = 10

local globals = setmetatable({
  WOW_PROJECT_ID = 18, WOW_PROJECT_CLASSIC = 2, LE_EXPANSION_LEVEL_CURRENT = 0,
  GetBuildInfo = function() return "", "", "", 16001 end,
  UnitClass = function() return "Mage", "MAGE" end,
  UnitLevel = function() return playerLevel end,
  InCombatLockdown = function() return false end,
  NUM_BAG_SLOTS = 4,
  BuffomatAddon = {},
  LibStub = function(name) libs[name] = libs[name] or {}; return libs[name] end,
}, { __index = _G })
globals._G = globals

libs["Buffomat-ItemCache"] = {
  ItemExists = function(_, itemId) return ITEM_LEVELS[itemId] ~= nil end,
  LoadItem = function(_, itemId, onLoaded)
    if cached[itemId] then
      onLoaded({ itemMinLevel = ITEM_LEVELS[itemId] })
    else
      waiting[#waiting + 1] = function() onLoaded({ itemMinLevel = ITEM_LEVELS[itemId] }) end
    end
  end,
}
libs["Buffomat-SpellSetup"] = { RequestSetup = function() setupRequests = setupRequests + 1 end }
libs["Buffomat-AllBuffs"] = { NewSpellLimitations = function() return {} end }

loadModule("Src/KvLib/KvEnv.lua", globals)
loadModule("Src/Core/BuffDefinition.lua", globals)
local buffDefModule = libs["Buffomat-BuffDefinition"]

local function isShown(buff)
  return buffDefModule:CheckDynamicLimitations(buff.limitations)
end

-- Cached items: the lowest level wins at once, no rebuild needed
cached = { [274947] = true, [277503] = true }
local scroll = buffDefModule:New(1295720):CreatesOrProvidedByItem({ 274947, 277503 })
scroll:EnsureDynamicMinLevelSet()
equal(scroll.itemMinLevels[277503], 46, "each item level is stored")
equal(scroll.limitations.minLevel, 5, "lowest item level is the buff level")
equal(setupRequests, 0, "no rebuild when item data was already loaded")
playerLevel = 4
equal(isShown(scroll), false, "hidden below the level")
playerLevel = 5
equal(isShown(scroll), true, "shown at the level")

-- Items loading later; an item unknown to this client (287978) is skipped
cached = {}
local stone = buffDefModule:New(16138):CreatesOrProvidedByItem({ 12404, 287978 })
stone:EnsureDynamicMinLevelSet()
equal(stone.limitations.minLevel, nil, "not hidden while item data loads")
for _, done in ipairs(waiting) do done() end
waiting = {}
equal(stone.limitations.minLevel, 35, "level set once the items load")
equal(setupRequests, 1, "spell list rebuilt after late item data")
stone:EnsureDynamicMinLevelSet()
equal(setupRequests, 1, "items are read only once")

-- A level 1 item means no limit
cached = { [2862] = true, [12404] = true }
local anyLevel = buffDefModule:New(16139):CreatesOrProvidedByItem({ 12404, 2862 })
anyLevel:EnsureDynamicMinLevelSet()
equal(anyLevel.limitations.minLevel, nil, "a level 1 item leaves the buff unlimited")

-- A level from the definition is kept
local fixed = buffDefModule:New(16140):CreatesOrProvidedByItem({ 12404 }):MinLevel(20)
fixed:EnsureDynamicMinLevelSet()
equal(fixed.limitations.minLevel, 20, "definition minLevel is kept")

print("PASS: consumable buffs hidden below their lowest item level")

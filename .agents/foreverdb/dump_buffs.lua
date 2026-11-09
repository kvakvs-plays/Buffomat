-- Run from the repository root: lua .agents/foreverdb/dump_buffs.lua > .agents/foreverdb/out/buffs-forever.json
-- Loads the real buff database (Src/Knowledge) on a WoW: Forever fixture for every class and race,
-- like Tests/ForeverKnowledgeTest.lua, and prints what each class gets as JSON for verify_buffs.py.
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

local FILES = {
  "Src/KvLib/KvEnv.lua",
  "Src/Knowledge/AllBuffs.lua",
  "Src/Knowledge/AllSpellsMage.lua", "Src/Knowledge/AllSpellsPriest.lua", "Src/Knowledge/AllSpellsDruid.lua",
  "Src/Knowledge/AllSpellsShaman.lua", "Src/Knowledge/AllSpellsWarlock.lua", "Src/Knowledge/AllSpellsHunter.lua",
  "Src/Knowledge/AllSpellsPaladin.lua", "Src/Knowledge/AllSpellsWarrior.lua", "Src/Knowledge/AllSpellsRogue.lua",
  "Src/Knowledge/AllSpellsDeathknight.lua", "Src/Knowledge/AllConsumesScrolls.lua",
  "Src/Knowledge/AllConsumesEnchantments.lua", "Src/Knowledge/AllConsumesElixirs.lua",
  "Src/Knowledge/AllConsumesFlasks.lua", "Src/Knowledge/AllConsumesFood.lua", "Src/Knowledge/AllConsumesOther.lua",
  "Src/Knowledge/AllConsumesForever.lua",
  "Src/Const/SpellIds.lua", "Src/Const/ItemIds.lua", "Src/Core/BuffDefinition.lua",
}

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }
local RACES = { "Human", "Dwarf", "NightElf", "Gnome", "Orc", "Scourge", "Tauren", "Troll" }

---Build the Forever buff database for one class and race.
---@return table allBuffs buffId -> definition
local function setup(class, race)
  local libs = { ["Buffomat-Buffomat"] = { Color = function(_, _color, text) return text end } }
  local globals = setmetatable({
    WOW_PROJECT_ID = 18, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
    WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5, WOW_PROJECT_WRATH_CLASSIC = 11, WOW_PROJECT_CATACLYSM_CLASSIC = 14,
    LE_EXPANSION_LEVEL_CURRENT = 0,
    GetBuildInfo = function() return "", "", "", 16001 end,
    UnitClass = function() return class, class end,
    UnitRace = function() return race, race, 1 end,
    UnitLevel = function() return 60 end,
    UnitFactionGroup = function() return "Alliance" end,
    IsSpellKnown = function() return false end,
    InCombatLockdown = function() return false end,
    NUM_BAG_SLOTS = 4,
    tinsert = table.insert,
    wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
    tContains = function(t, v) for _, x in pairs(t) do if x == v then return true end end return false end,
    BuffomatAddon = { GetItemInfo = function() end },
    C_SpecializationInfo = { GetActiveSpecGroup = function() return 1 end },
    LibStub = function(name)
      if libs[name] == nil then
        libs[name] = name == "Buffomat-Languages" and setmetatable({}, { __call = function(_, key) return key end })
            or {}
      end
      return libs[name]
    end,
  }, {
    __index = function(_, key)
      local value = _G[key]
      if value == nil and type(key) == "string" and key:match("^[A-Z][A-Z0-9_]+$") then
        return key
      end
      return value
    end,
  })
  globals._G = globals
  for _, path in ipairs(FILES) do
    loadModule(path, globals)
  end
  local allBuffsModule = libs["Buffomat-AllBuffs"]
  allBuffsModule:SetupSpells()
  return allBuffsModule.allBuffs
end

local function encode(value)
  local t = type(value)
  if t == "nil" then
    return "null"
  elseif t == "boolean" or t == "number" then
    return tostring(value)
  elseif t == "string" then
    return '"' .. value:gsub('[%c"\\]', function(c) return string.format("\\u%04x", c:byte()) end) .. '"'
  end
  local parts = {}
  if #value > 0 then
    for _, v in ipairs(value) do
      table.insert(parts, encode(v))
    end
    return "[" .. table.concat(parts, ",") .. "]"
  end
  local keys = {}
  for k in pairs(value) do
    table.insert(keys, tostring(k))
  end
  table.sort(keys)
  for _, k in ipairs(keys) do
    local v = value[k] ~= nil and value[k] or value[tonumber(k)]
    table.insert(parts, encode(k) .. ":" .. encode(v))
  end
  return "{" .. table.concat(parts, ",") .. "}"
end

---Copy only plain list fields (spell and item ids)
local function ids(list)
  if type(list) ~= "table" then
    return nil
  end
  local out = {}
  for _, v in ipairs(list) do
    table.insert(out, v)
  end
  return out
end

-- buffId -> record, with the classes and races that get it
local records = {}
for _, class in ipairs(CLASSES) do
  for _, race in ipairs(RACES) do
    for buffId, buff in pairs(setup(class, race)) do
      local key = tostring(buffId)
      local record = records[key]
      if record == nil then
        record = {
          buffId = buffId, type = buff.type, category = buff.category,
          isConsumable = buff.isConsumable == true, default = buff.default == true,
          singleFamily = ids(buff.singleFamily), groupFamily = ids(buff.groupFamily),
          items = ids(buff.items), providesAuras = ids(buff.providesAuras),
          singleDuration = buff.singleDuration, groupDuration = buff.groupDuration,
          classes = {}, races = {}, _classSeen = {}, _raceSeen = {},
        }
        records[key] = record
      end
      if not record._classSeen[class] then
        record._classSeen[class] = true
        table.insert(record.classes, class)
      end
      if not record._raceSeen[race] then
        record._raceSeen[race] = true
        table.insert(record.races, race)
      end
    end
  end
end

local list = {}
for _, record in pairs(records) do
  record._classSeen, record._raceSeen = nil, nil
  if #record.races == #RACES then
    record.races = nil -- every race
  end
  table.insert(list, record)
end
table.sort(list, function(a, b) return a.buffId < b.buffId end)
print(encode(list))

-- A fake WoW client for the scan tests: units, auras, raid roster, bags, a manual clock,
-- capturing timers and an event pump. Load with `dofile("Tests/ScanFixture.lua")`.
--
--   local fixture = dofile("Tests/ScanFixture.lua")
--   local f = fixture.new({ modern = true })   -- C_ namespaces, secret values, restrictions
--   local f = fixture.new({})                  -- legacy tuple APIs, no issecretvalue
--   f:load("Src/KvLib/KvEnv.lua")
--   f:fire("UNIT_AURA", "player"); f:advance(0.2)

local fixture = {}

---@class ScanFixture
local fixtureClass = {}
fixtureClass.__index = fixtureClass

function fixture.equal(actual, expected, label)
  assert(actual == expected,
    (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

---Run a Lua file inside the fixture's globals, the way the client loads addon files.
---@param path string Path from the repository root
function fixtureClass:load(path)
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, self.globals)
  else
    chunk = assert(loadfile(path, "t", self.globals))
  end
  return chunk("BuffomatClassic", {})
end

---@param name string LibStub library name
---@return table
function fixtureClass:lib(name)
  self.libs[name] = self.libs[name] or {}
  return self.libs[name]
end

---Add or replace a unit. Fields: name, realm, guid, class (nil for a pet), dead, ghost,
---feign, connected, map, auras, tank, pvp, level, distance, incomingRes.
---@param unitId string
---@param fields table
---@return table unit
function fixtureClass:unit(unitId, fields)
  fields.name = fields.name or unitId
  fields.guid = fields.guid or ("guid-" .. fields.name)
  if fields.connected == nil then fields.connected = true end
  fields.map = fields.map or 1
  fields.auras = fields.auras or {}
  fields.level = fields.level or 60
  self.units[unitId] = fields
  return fields
end

---Build a raid: `members` is a list of { name, class, subgroup, role?, combatRole? } and
---the entry with `isPlayer` also becomes the "player" unit.
---@param members table[]
function fixtureClass:raid(members)
  for unitId in pairs(self.units) do
    if unitId:match("^raid") or unitId:match("^party") then
      self.units[unitId] = nil
    end
  end
  self.raidRoster = {}
  for index, member in ipairs(members) do
    local unit
    if member.isPlayer then
      unit = self.units.player
      unit.name, unit.class = member.name or unit.name, member.class or unit.class
      unit.guid = "guid-" .. unit.name
      self.units["raid" .. index] = unit
    else
      unit = self:unit("raid" .. index, { name = member.name, class = member.class, auras = member.auras })
    end
    self.raidRoster[index] = { unit = unit, subgroup = member.subgroup or 1, role = member.role or "NONE",
      combatRole = member.combatRole or "NONE" }
  end
  self.state.inRaid = true
  self.state.inGroup = true
end

---Leave the raid or party.
function fixtureClass:solo()
  for unitId in pairs(self.units) do
    if unitId:match("^raid") or unitId:match("^party") then
      self.units[unitId] = nil
    end
  end
  self.raidRoster = {}
  self.state.inRaid = false
  self.state.inGroup = false
end

---@param unitId string
---@param spellId number
---@param fields table? name, duration, expirationTime, source
function fixtureClass:aura(unitId, spellId, fields)
  fields = fields or {}
  table.insert(self.units[unitId].auras, {
    spellId = spellId, name = fields.name or ("Spell " .. spellId), duration = fields.duration or 1800,
    expirationTime = fields.expirationTime or (self.state.now + 1800), source = fields.source or "player",
  })
end

---@param unitId string
---@param spellId number
function fixtureClass:removeAura(unitId, spellId)
  local auras = self.units[unitId].auras
  for index = #auras, 1, -1 do
    if auras[index].spellId == spellId then
      table.remove(auras, index)
    end
  end
end

---@param bag number
---@param slot number
---@param itemId number? Nil empties the slot
---@param count number?
---@param fields table? hasLoot, cooldownStart, cooldownDuration
function fixtureClass:item(bag, slot, itemId, count, fields)
  self.bags[bag] = self.bags[bag] or { slots = 16 }
  if itemId == nil then
    self.bags[bag][slot] = nil
    return
  end
  fields = fields or {}
  self.bags[bag][slot] = {
    itemID = itemId, stackCount = count or 1, hyperlink = "item:" .. itemId, iconFileID = 1000 + itemId,
    hasLoot = fields.hasLoot or false, cooldownStart = fields.cooldownStart or 0,
    cooldownDuration = fields.cooldownDuration or 0, lockedBox = fields.lockedBox or false,
  }
end

---Deliver a game event to every frame and AceEvent handler registered for it.
---@param event string
function fixtureClass:fire(event, ...)
  for _, frame in ipairs(self.frames) do
    local units = frame.events[event]
    if units ~= nil and frame.scripts.OnEvent then
      if units == true or units[(...)] then
        frame.scripts.OnEvent(frame, event, ...)
      end
    end
  end
  local handler = self.aceHandlers[event]
  if handler then
    handler(event, ...)
  end
end

---Move the clock forward, running the timers which come due, in order.
---@param seconds number
function fixtureClass:advance(seconds)
  local target = self.state.now + seconds
  while true do
    local nextTimer
    for _, timer in ipairs(self.timers) do
      if not timer.cancelled and not timer.fired and timer.at <= target + 1e-9
          and (nextTimer == nil or timer.at < nextTimer.at) then
        nextTimer = timer
      end
    end
    if nextTimer == nil then
      break
    end
    self.state.now = math.max(self.state.now, nextTimer.at)
    nextTimer.fired = true
    nextTimer.fn()
  end
  self.state.now = target
end

---@return number count Timers waiting to fire
function fixtureClass:pendingTimers()
  local count = 0
  for _, timer in ipairs(self.timers) do
    if not timer.cancelled and not timer.fired then
      count = count + 1
    end
  end
  return count
end

---@param api string Counter name: "aura", "bagSlot", "cooldown", "distance", "roster"
---@return number
function fixtureClass:calls(api)
  return self.state.calls[api] or 0
end

function fixtureClass:resetCalls()
  self.state.calls = {}
end

---@param options {modern: boolean?, forever: boolean?, class: string?}
---@return ScanFixture
function fixture.new(options)
  options = options or {}
  local modern = options.modern == true
  local fx = setmetatable({
    libs = {}, units = {}, raidRoster = {}, bags = {}, frames = {}, timers = {}, aceHandlers = {},
    printed = {}, secret = {},
    state = {
      now = 1000, calls = {}, inCombat = false, inRaid = false, inGroup = false, restrictions = {},
      mounted = false, flying = false, resting = false, stealthed = false, outdoors = true, taxi = false,
      formId = nil, form = 0, instanceType = "none", instanceId = 0, modifier = false, alt = false,
      mana = 1000, maxMana = 1000, spellCooldowns = {}, spellRange = {}, knownSpells = {},
      weapon = { main = false, off = false }, inventory = {}, validEvents = nil,
    },
  }, fixtureClass)
  local state, units = fx.state, fx.units
  local secret = fx.secret

  local function count(api, amount)
    state.calls[api] = (state.calls[api] or 0) + (amount or 1)
  end
  local function unitField(unitId, field)
    local unit = units[unitId]
    if unit == nil then return nil end
    return unit[field]
  end
  local function flag(unitId, field)
    return unitField(unitId, field) == true
  end

  local function getAura(unitId, index, _filter)
    assert(not state.inCombat, "aura API called in combat")
    count("aura")
    local unit = units[unitId]
    if unit == nil then return nil end
    if unit.secretAuras then return secret end
    return unit.auras[index]
  end
  local function containerItem(bag, slot)
    count("bagSlot")
    return fx.bags[bag] and fx.bags[bag][slot]
  end

  local addon = {
    Print = function(_, text) table.insert(fx.printed, text) end,
    Debug = function() end,
    RegisterEvent = function(_, event, handler) fx.aceHandlers[event] = handler end,
    UnregisterEvent = function(_, event) fx.aceHandlers[event] = nil end,
    ScheduleTimer = function(_, fn, delay)
      local timer = { at = state.now + delay, fn = fn }
      table.insert(fx.timers, timer)
      return timer
    end,
    CancelTimer = function(_, timer)
      if timer then timer.cancelled = true end
    end,
  }

  local globals = setmetatable({
    WOW_PROJECT_ID = options.forever and 18 or (modern and 1 or 2),
    WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2, WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5,
    WOW_PROJECT_WRATH_CLASSIC = 11, WOW_PROJECT_CATACLYSM_CLASSIC = 14,
    LE_EXPANSION_LEVEL_CURRENT = 0,
    GetBuildInfo = function() return "", "", "", options.forever and 16001 or (modern and 120105 or 11508) end,
    NUM_BAG_SLOTS = 4, BACKPACK_CONTAINER = 0, LOCKED = "Locked",
    BuffomatAddon = addon,
    BuffomatShared = { Duration = {}, DebugLogging = false },
    BuffomatCharacter = { WatchGroup = { true, true, true, true, true, true, true, true } },
    RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { colorStr = "ffffffff" } end }),
    LibStub = function(name) return fx:lib(name) end,
    GetTime = function() return state.now end,
    InCombatLockdown = function() return state.inCombat end,
    wipe = function(t) for key in pairs(t) do t[key] = nil end return t end,
    tContains = function(t, value)
      for _, candidate in pairs(t) do if candidate == value then return true end end
      return false
    end,
    tinsert = table.insert,
    debugprofilestop = function() return state.now * 1000 end,
    C_Timer = { After = function(delay, fn) addon.ScheduleTimer(addon, fn, delay) end },
    CreateFrame = function()
      local frame = { events = {}, scripts = {} }
      function frame:SetScript(name, fn) self.scripts[name] = fn end
      function frame:RegisterEvent(event)
        if state.validEvents and not state.validEvents[event] then error("unknown event " .. event) end
        self.events[event] = true
      end
      function frame:RegisterUnitEvent(event, unit1, unit2)
        if state.validEvents and not state.validEvents[event] then error("unknown event " .. event) end
        self.events[event] = { [unit1] = true, [unit2 or unit1] = true }
      end
      function frame:UnregisterEvent(event) self.events[event] = nil end
      -- Any other widget method (tooltip setup and the like) does nothing
      setmetatable(frame, { __index = function() return function() end end })
      table.insert(fx.frames, frame)
      return frame
    end,

    -- Units
    UnitFullName = function(unitId)
      if flag(unitId, "secretName") then return secret end
      return unitField(unitId, "name"), unitField(unitId, "realm")
    end,
    UnitName = function(unitId) return unitField(unitId, "name") end,
    UnitGUID = function(unitId) return unitField(unitId, "guid") end,
    UnitClass = function(unitId)
      local class = unitField(unitId, "class") or options.class or "PRIEST"
      return class, class
    end,
    GetPlayerInfoByGUID = function(guid)
      for _, unit in pairs(units) do
        if unit.guid == guid then return unit.class, unit.class end
      end
    end,
    UnitExists = function(unitId) return units[unitId] ~= nil end,
    UnitIsDeadOrGhost = function(unitId) return flag(unitId, "dead") or flag(unitId, "ghost") end,
    UnitIsDead = function(unitId) return flag(unitId, "dead") end,
    UnitIsGhost = function(unitId) return flag(unitId, "ghost") end,
    UnitIsFeignDeath = function(unitId) return flag(unitId, "feign") end,
    UnitIsConnected = function(unitId) return flag(unitId, "connected") end,
    UnitHasIncomingResurrection = function(unitId) return flag(unitId, "incomingRes") end,
    UnitIsUnit = function(a, b) return units[a] ~= nil and units[a] == units[b] end,
    UnitIsPVP = function(unitId) return flag(unitId, "pvp") end,
    UnitLevel = function(unitId) return unitField(unitId, "level") end,
    UnitIsPlayer = function(unitId) return unitField(unitId, "class") ~= nil end,
    UnitIsOtherPlayersPet = function() return false end,
    UnitInParty = function(unitId) return unitId:match("^party") ~= nil end,
    UnitInRaid = function(unitId) return unitId:match("^raid") ~= nil end,
    UnitPlayerOrPetInParty = function(unitId) return state.inGroup and units[unitId] ~= nil end,
    UnitPlayerOrPetInRaid = function(unitId) return state.inRaid and units[unitId] ~= nil end,
    UnitCanCooperate = function(_, unitId) return units[unitId] ~= nil end,
    UnitGroupRolesAssigned = function(unitId) return flag(unitId, "tank") and "TANK" or "NONE" end,
    UnitCreatureType = function(unitId) return "Demon", unitField(unitId, "creatureType") end,
    UnitCreatureFamily = function(unitId) return "Imp", unitField(unitId, "creatureFamily") end,
    UnitPower = function() return state.mana end,
    UnitPowerMax = function() return state.maxMana end,
    UnitInRange = function(unitId) return (unitField(unitId, "distance") or 0) < 1849, true end,
    UnitDistanceSquared = function(unitId)
      count("distance")
      return unitField(unitId, "distance") or 0, true
    end,
    UnitOnTaxi = function() return state.taxi end,
    C_Map = { GetBestMapForUnit = function(unitId) return unitField(unitId, "map") end },

    -- Group
    IsInRaid = function() return state.inRaid end,
    IsInGroup = function() return state.inGroup end,
    GetNumGroupMembers = function() return #fx.raidRoster end,
    GetRaidRosterInfo = function(index)
      count("roster")
      local slot = fx.raidRoster[index]
      if slot == nil then return nil end
      return slot.unit.name, 0, slot.subgroup, slot.unit.level, slot.unit.class, slot.unit.class, "", true,
          slot.unit.dead, slot.role, false, slot.combatRole
    end,

    -- Player state
    IsMounted = function() return state.mounted end,
    IsFlying = function() return state.flying end,
    IsResting = function() return state.resting end,
    IsStealthed = function() return state.stealthed end,
    IsOutdoors = function() return state.outdoors end,
    GetShapeshiftFormID = function() return state.formId end,
    GetShapeshiftForm = function() return state.form end,
    IsInInstance = function() return state.instanceType ~= "none", state.instanceType end,
    GetInstanceInfo = function() return "", state.instanceType, 0, "", 0, 0, false, state.instanceId end,
    GetInventoryItemID = function(_, slot) return state.inventory[slot] end,
    GetInventoryItemLink = function(_, slot) return state.inventory[slot] and ("item:" .. state.inventory[slot]) end,
    IsModifierKeyDown = function() return state.modifier end,
    IsAltKeyDown = function() return state.alt end,
    IsShiftKeyDown = function() return false end,
    CancelUnitBuff = function(unitId, index, filter) state.cancelled = { unitId, index, filter } end,
    PlaySoundFile = function(path) state.sound = path end,
    GetSpellSubtext = function() return "" end,
    GetNetStats = function() return 0, 0, 20, 20 end,
    GetItemCount = function(itemId)
      local total = 0
      for _, bag in pairs(fx.bags) do
        for _, item in pairs(bag) do
          if type(item) == "table" and item.itemID == itemId then total = total + item.stackCount end
        end
      end
      return total
    end,
  }, { __index = _G })
  globals._G = globals
  fx.globals = globals

  local function weaponTuple()
    local main, off = state.weapon.main, state.weapon.off
    return main and true or false, main and main.timeLeft or nil, main and 0 or nil, main and main.enchantId or nil,
        off and true or false, off and off.timeLeft or nil, off and 0 or nil, off and off.enchantId or nil
  end
  local function spellCooldown(spell)
    local info = state.spellCooldowns[spell]
    if info == nil then return 0, 0, 1, 1 end
    return info.start, info.duration, 1, 1
  end

  local function spellName(spell)
    return "Spell" .. tostring(spell)
  end

  if modern then
    globals.issecretvalue = function(value) return rawequal(value, secret) end
    globals.Enum = {
      WeaponSlot = { MainHand = 0, OffHand = 1 },
      AddOnRestrictionType = { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3 },
      BagIndex = { ReagentBag = 5 },
      SpellBookSpellBank = { Player = 0, Pet = 1 },
    }
    globals.Constants = { InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 } }
    globals.C_RestrictedActions = {
      IsAddOnRestrictionActive = function(kind) return state.restrictions[kind] or false end,
    }
    globals.C_EventUtils = {
      IsEventValid = function(event) return state.validEvents == nil or state.validEvents[event] == true end,
    }
    globals.C_UnitAuras = {
      GetAuraDataByIndex = function(unitId, index, filter)
        local aura = getAura(unitId, index, filter)
        if aura == nil or aura == secret then return aura end
        return { spellId = aura.spellId, name = aura.name, duration = aura.duration,
          expirationTime = aura.expirationTime, sourceUnit = aura.source }
      end,
    }
    globals.C_Container = {
      GetContainerNumSlots = function(bag) return fx.bags[bag] and fx.bags[bag].slots or 0 end,
      GetContainerItemInfo = containerItem,
      GetContainerItemCooldown = function(bag, slot)
        count("cooldown")
        local item = fx.bags[bag] and fx.bags[bag][slot]
        if item == nil then return 0, 0, 1 end
        return item.cooldownStart, item.cooldownDuration, 1
      end,
    }
    globals.C_Item = {
      GetWeaponEnchantInfo = function(slot)
        local enchant = slot == 0 and state.weapon.main or state.weapon.off
        if state.weapon.secret then return secret end
        if not enchant then return {} end
        return { { hasEnchant = true, timeLeft = enchant.timeLeft, charges = 0, enchantID = enchant.enchantId } }
      end,
      IsItemInRange = function() return false end,
      GetItemCount = globals.GetItemCount,
    }
    globals.C_Spell = {
      GetSpellCooldown = function(spell)
        local start, duration = spellCooldown(spell)
        return { startTime = start, duration = duration, isEnabled = true, modRate = 1 }
      end,
      IsSpellInRange = function(spell, unitId)
        local unit = units[unitId]
        local known = state.spellRange[spell]
        if unit == nil then return nil end
        return (unit.distance or 0) <= (known or 900)
      end,
      GetSpellInfo = function(spell)
        return { name = spellName(spell), iconID = 1, castTime = 0, minRange = 0, maxRange = 30, spellID = spell }
      end,
      GetSpellSubtext = function() return "" end,
    }
    globals.C_SpellBook = { IsSpellKnown = function(spellId) return state.knownSpells[spellId] == true end }
  else
    globals.Enum = { BagIndex = { ReagentBag = 5 } }
    globals.Constants = { InventoryConstants = { NumBagSlots = 4 } }
    globals.UnitAura = function(unitId, index, filter)
      local aura = getAura(unitId, index, filter)
      if aura == nil then return nil end
      return aura.name, 1, 0, nil, aura.duration, aura.expirationTime, aura.source, false, false, aura.spellId
    end
    globals.GetContainerNumSlots = function(bag) return fx.bags[bag] and fx.bags[bag].slots or 0 end
    globals.GetContainerItemInfo = function(bag, slot)
      local item = containerItem(bag, slot)
      if item == nil then return nil end
      return item.iconFileID, item.stackCount, false, 1, false, item.hasLoot, item.hyperlink, false, false,
          item.itemID, false
    end
    globals.GetContainerItemCooldown = function(bag, slot)
      count("cooldown")
      local item = fx.bags[bag] and fx.bags[bag][slot]
      if item == nil then return 0, 0, 1 end
      return item.cooldownStart, item.cooldownDuration, 1
    end
    globals.GetWeaponEnchantInfo = weaponTuple
    globals.GetSpellCooldown = spellCooldown
    globals.IsSpellInRange = function(spell, unitId)
      local unit = units[unitId]
      if unit == nil then return nil end
      return ((unit.distance or 0) <= (state.spellRange[spell] or 900)) and 1 or 0
    end
    globals.IsSpellKnown = function(spellId) return state.knownSpells[spellId] == true end
    globals.GetSpellInfo = function(spell) return spellName(spell), "", 1, 0, 0, 30, spell end
    globals.IsItemInRange = function() return false end
    globals.CheckInteractDistance = function() return false end
  end

  fx:unit("player", { name = "Tester", class = options.class or "PRIEST" })
  return fx
end

return fixture

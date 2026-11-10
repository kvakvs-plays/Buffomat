local addonName, ns = ...

-- The aura reader. Reads the buffs of the units whose auras changed, a limited number
-- of units per pass, into the unit's reused tables. The caller has already checked
-- combat and addon restrictions for the whole pass.

---@class AuraScanModule
---@field version number Changes when a read found different auras than the read before
---@field queue table<string, boolean> Unit ids waiting to be read, kept between passes
---@field drinkingCount number Members with a drinking buff, for the "someone is drinking" hint
local module = LibStub("Buffomat-AuraScan") --[[@as AuraScanModule]]

local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffModule = LibStub("Buffomat-Buff") --[[@as BuffModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local scanStatsModule = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]

module.version = 0
module.queue = {}
module.drinkingCount = 0

-- Units read per pass; the rest wait for the continuation pass, so reading a whole raid
-- never happens in one frame
module.BUDGET = 10
module.BUDGET_SLOWER_HARDWARE = 5

local SIGNATURE_DEAD = -1
local SIGNATURE_UNREADABLE = -2

local pool = {} ---@type BomUnitBuff[] Buff records released by a re-read, reused by the next

---@param unit BomUnit
local function releaseBuffs(unit)
  for buffId, buff in pairs(unit.knownBuffs) do
    pool[#pool + 1] = buff
    unit.knownBuffs[buffId] = nil
  end
  wipe(unit.allBuffs)
end

---@param spellId WowSpellId The aura found on the unit
---@param duration number
---@param expirationTime number
---@param source string
---@param isSingle boolean
---@return BomUnitBuff
local function newBuff(spellId, duration, expirationTime, source, isSingle)
  local buff = table.remove(pool)
  if buff == nil then
    return buffModule:New(spellId, duration, expirationTime, source, isSingle)
  end
  buff.singleId, buff.duration, buff.expirationTime, buff.source, buff.isSingle =
      spellId, duration, expirationTime, source, isSingle
  return buff
end

---The client did not let the auras be read: nothing may be concluded from their absence.
---@param unit BomUnit
---@return boolean changed
function module:MarkUnreadable(unit)
  releaseBuffs(unit)
  unit.auraDataUnavailable = true
  unit.NeedBuff = false
  unit.isDrinking = false
  local changed = unit.auraSignature ~= SIGNATURE_UNREADABLE
  unit.auraSignature = SIGNATURE_UNREADABLE
  return changed
end

---Read every helpful aura of one unit.
---@param unit BomUnit
---@return boolean changed False when the unit has exactly the auras it had at the last read
function module:ReadUnit(unit)
  scanStatsModule:Count("auraUnits")
  releaseBuffs(unit)
  unit.auraDataUnavailable = false
  unit.NeedBuff = true
  unit.isDrinking = false

  if unit.isDead then
    -- The dead have no buffs
    local changed = unit.auraSignature ~= SIGNATURE_DEAD
    unit.auraSignature = SIGNATURE_DEAD
    return changed
  end

  local unitId = unit.unitId
  local watched = allBuffsModule.allSpellIdSet
  local selected = allBuffsModule.selectedBuffsSpellIds
  local isSingleLookup = allBuffsModule.spellIdIsSingleLookup
  local drinks, ignoreAll = allBuffsModule.drinkSpellIdSet, allBuffsModule.ignoreAllSpellIdSet
  local known, all = unit.knownBuffs, unit.allBuffs
  -- Which buffs are stored depends on the spell setup, so a new setup is a change
  local signature = allBuffsModule.setupVersion or 0
  local index = 0

  while true do
    index = index + 1
    local spellId, name, duration, expirationTime, source, readable = kvUnitModule.ReadAura(unitId, index, "HELPFUL")
    scanStatsModule:Count("auraReads")
    if not readable then
      return self:MarkUnreadable(unit)
    elseif spellId == nil then
      break
    end

    all[spellId] = true -- every aura, also those Buffomat does not cast
    if drinks[spellId] then
      unit.isDrinking = true
    end

    if watched[spellId] and source ~= nil and source ~= "" and envModule.UnitIsUnit(source, "player") then
      -- Some clients report no duration for a buff on somebody else; remember the one
      -- seen on the player for the same spell name
      if unit.isPlayer and duration ~= nil and duration > 0 then
        BuffomatShared.Duration[name] = duration
      end
      if duration == nil or duration == 0 then
        duration = BuffomatShared.Duration[name] or 0
      end
      if expirationTime == 0 then
        duration = 0 -- no end time known: the buff counts as present, never as running out
      end
    end
    signature = signature + (spellId % 1000 + 1) * ((expirationTime or 0) + 13.7) + (source == "player" and 1 or 0)

    local buffDef = selected[spellId]
    if buffDef then
      if ignoreAll[spellId] then
        -- A unit with such a buff gets nothing at all, like a phase-shifted imp
        for buffId, buff in pairs(known) do
          pool[#pool + 1] = buff
          known[buffId] = nil
        end
        unit.NeedBuff = false
        signature = signature + 0.5
        break
      end
      known[buffDef.buffId] = newBuff(spellId, duration, expirationTime, source, isSingleLookup[spellId] ~= nil)
    end
  end

  local changed = unit.auraSignature ~= signature
  unit.auraSignature = signature
  return changed
end

---Aura-free mode: nothing is read from auras, and the player's are marked unreadable.
---@param roster BomRoster
function module:SetAuraFree(roster)
  wipe(self.queue)
  local changed = self:MarkUnreadable(roster.player)
  if changed then
    self.version = self.version + 1
    self.drinkingCount = 0
  end
end

---Add units to the read queue.
---@param roster BomRoster
---@param all boolean Every unit of the roster
---@param unitIds table<string, boolean> Named units; ignored when `all`
function module:Enqueue(roster, all, unitIds)
  if all then
    for _, unit in ipairs(roster.units) do
      self.queue[unit.unitId] = true
    end
  else
    for unitId in pairs(unitIds) do
      self.queue[unitId] = true
    end
  end
end

---Read queued units in roster order (player, pet, own subgroup, the rest), up to the budget.
---@param roster BomRoster
---@return boolean more Units are still queued; the pass should continue soon
function module:ReadQueued(roster)
  local queue = self.queue
  if next(queue) == nil then
    return false
  end
  local budget = BuffomatShared.SlowerHardware and self.BUDGET_SLOWER_HARDWARE or self.BUDGET
  local read, more, changed = 0, false, false
  for _, unit in ipairs(roster.units) do
    if queue[unit.unitId] then
      if read >= budget then
        more = true
        break
      end
      queue[unit.unitId] = nil
      read = read + 1
      changed = self:ReadUnit(unit) or changed
    end
  end
  if not more then
    wipe(queue) -- whatever is left is no longer in the roster
  end

  if changed then
    self.version = self.version + 1
    local drinking = 0
    for _, unit in ipairs(roster.units) do
      if unit.isDrinking then
        drinking = drinking + 1
      end
    end
    self.drinkingCount = drinking
  end
  return more
end

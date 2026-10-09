local BuffomatAddon = BuffomatAddon
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomUnitModule

local unitModule = LibStub("Buffomat-Unit") --[[@as BomUnitModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffModule = LibStub("Buffomat-Buff") --[[@as BomBuffModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]

---@alias BomBuffidBuffLookup {[BomBuffId]: BomUnitBuff}

---@class BomUnit
---@field allBuffs table<number, boolean> Availability of all auras even those not supported by BOM, by id, no extra detail stored
---@field auraDataUnavailable boolean? Prevent decisions from an incomplete aura scan.
---@field class ClassName
---@field distance number
---@field group number Raid group number (9 if temporary moved out of the raid by BOM)
---@field hasReputationTrinket boolean Has AD reputation trinket equipped
---@field hasRidingTrinket boolean Has carrot riding trinket equipped
---@field hasResurrection boolean Was recently resurrected
---@field isConnected boolean Is online
---@field isDead boolean Is this member dead
---@field isGhost boolean Is dead and corpse released
---@field isPlayer boolean Is this a player
---@field isSameZone boolean Is in the same zone
---@field isTank boolean Is this member marked as tank
---@field knownBuffs BomBuffidBuffLookup Buffs on player keyed by spell id, only buffs supported by Buffomat are stored
---@field link string
---@field mainhandEnchantment BomBuffId|nil Temporary enchant on main hand
---@field name string
---@field NeedBuff boolean
---@field offhandEnchantment BomBuffId|nil Temporary enchant on off-hand
---@field owner BomUnit|nil Owner for pet
---@field unitId string
local unitClass = {}
unitClass.__index = unitClass

---@return BomUnit
function unitModule:New(fields)
  fields = fields or {}
  setmetatable(fields, unitClass)
  return fields
end

---Handles UnitAura WOW API call.
---For spells that are tracked by Buffomat the data is also stored in partyModule.buffs
---@param unitId string
---@param buffIndex number Index of buff/debuff slot starts 1 max 40?
---@param filter string Filter string like "HELPFUL", "PLAYER", "RAID"... etc
---@return BomUnitAuraResult?
---@return boolean readable
function unitModule:UnitAura(unitId, buffIndex, filter)
  local aura, readable = envModule.GetUnitAura(unitId, buffIndex, filter)
  if not readable or aura == nil then
    return nil, readable
  end
  local name, spellId, source = aura.name, aura.spellId, aura.source
  local duration, expirationTime = aura.duration, aura.expirationTime

  if spellId
      and allBuffsModule.allSpellIds
      and tContains(allBuffsModule.allSpellIds, spellId) then
    if source ~= nil and source ~= "" and envModule.UnitIsUnit(source, "player") then
      if envModule.UnitIsUnit(unitId, "player") and duration ~= nil and duration > 0 then
        BuffomatShared.Duration[name] = duration
      end

      if duration == nil or duration == 0 then
        duration = BuffomatShared.Duration[name] or 0
      end

      if duration > 0 and (expirationTime == nil or expirationTime == 0) then
        local destName = UnitFullName(unitId) ---@type string
        if envModule.IsSecretValue(destName) then
          return nil, false
        end
        local buffOnPlayer = partyModule.unitAurasLastUpdated[destName]

        if type(buffOnPlayer) == "table" and buffOnPlayer[name] then
          expirationTime = (buffOnPlayer[name] or 0) + duration

          local now = GetTime()

          if expirationTime <= now then
            buffOnPlayer[name] = now
            expirationTime = now + duration
          end
        end
      end

      if expirationTime == 0 then
        duration = 0
      end
    end
  end

  aura.duration = duration
  aura.expirationTime = expirationTime
  return aura, true
end

---Force updates buffs for one party member
---@param playerUnit BomUnit
function unitClass:ForceUpdateBuffs(playerUnit)
  if InCombatLockdown() or envModule.IsAuraRestricted() then
    self.auraDataUnavailable = true
    self.NeedBuff = false
    return
  end
  self.auraDataUnavailable = false
  self.isPlayer = (self == playerUnit)
  self.isDead = UnitIsDeadOrGhost(self.unitId) and not UnitIsFeignDeath(self.unitId)
  self.isGhost = UnitIsGhost(self.unitId)
  self.isConnected = UnitIsConnected(self.unitId)
  self.NeedBuff = true

  wipe(self.knownBuffs)
  wipe(self.allBuffs)

  BuffomatAddon.somebodyIsGhost = BuffomatAddon.somebodyIsGhost or self.isGhost

  if self.isDead then
    -- Clear known buffs for self, as we're very dead atm
    partyModule.unitAurasLastUpdated[self.name] = nil
    return
  end

  self.hasReputationTrinket = false
  self.hasRidingTrinket = false

  local buffIndex = 0

  repeat
    buffIndex = buffIndex + 1

    local unitAura, readable = unitModule:UnitAura(self.unitId, buffIndex, "HELPFUL")
    if not readable then
      self.auraDataUnavailable = true
      self.NeedBuff = false
      wipe(self.knownBuffs)
      wipe(self.allBuffs)
      return
    elseif unitAura == nil then
      break
    end

    if unitAura.spellId then
      self.allBuffs[unitAura.spellId] = true -- save all buffids even those not supported
      if tContains(BuffomatAddon.AllDrink, unitAura.spellId) then
        BuffomatAddon.drinkingPersonCount = BuffomatAddon.drinkingPersonCount + 1
      end
    end

    local lookupBuff = allBuffsModule.selectedBuffsSpellIds[unitAura.spellId]

    if lookupBuff then
      -- Skip members who have a buff on the global ignore list - example phaseshifted imps
      if tContains(BuffomatAddon.buffIgnoreAll, unitAura.spellId) then
        wipe(self.knownBuffs)
        self.NeedBuff = false
        break
      else
        local buffOnUnit = buffModule:New(
          unitAura.spellId,
          unitAura.duration,
          unitAura.expirationTime,
          unitAura.source,
          allBuffsModule.spellIdIsSingleLookup[unitAura.spellId] ~= nil)
        self.knownBuffs[lookupBuff.buffId] = buffOnUnit
      end
      --if tContains(BOM.ReputationTrinket.spells, spellId) then
      --  self.hasReputationTrinket = true
      --end

      --if tContains(BOM.Carrot.spells, spellId) then
      --  self.hasCarrot = true
      --end
    end
  until false -- The API returns nil at the end of the aura list.

  if self.isPlayer then
    self:UpdatePlayerWeaponEnchantments()
  end
end

---@param unitId string
---@param name string
---@param group number
---@param class ClassName
---@param link string
---@param isTank boolean
function unitClass:Construct(unitId, name, group, class, link, isTank)
  self.distance = 1000044 -- special value to find out that the range error originates from this module
  self.unitId = unitId
  self.name = name
  self.group = group
  self.hasResurrection = self.hasResurrection or false
  self.class = class
  self.link = link
  self.isTank = isTank
  self.knownBuffs = self.knownBuffs or {}
  self.allBuffs = self.allBuffs or {}
end

function unitClass:GetDistance()
  return self.distance
end

---@param id WowSpellId
function unitClass:HaveBuff(id)
  return self.knownBuffs[id] ~= nil or self.allBuffs[id] ~= nil
end

function unitClass:GetText()
  return self.link or self.name
end

function unitClass:ClearMainhandBuff()
  self.mainhandEnchantment = nil
end

---@param enchantmentId BomEnchantmentId
---@param expiration number
function unitClass:SetMainhandBuff(enchantmentId, expiration)
  local enchantBuffId = allBuffsModule.enchantToSpellLookup[enchantmentId]
  local duration

  if allBuffsModule.buffFromSpellIdLookup[enchantBuffId]
      and allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  then
    duration = allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  else
    duration = 300
  end

  self.knownBuffs[enchantBuffId] = buffModule:New(
    enchantBuffId,
    duration,
    GetTime() + expiration / 1000,
    "player",
    true)
  self.mainhandEnchantment = enchantBuffId
end

function unitClass:ClearOffhandBuff()
  self.offhandEnchantment = nil
end

---@param enchantmentId BomEnchantmentId
---@param expiration number
function unitClass:SetOffhandBuff(enchantmentId, expiration)
  local enchantBuffId = allBuffsModule.enchantToSpellLookup[enchantmentId]
  local duration

  if allBuffsModule.buffFromSpellIdLookup[enchantBuffId]
      and allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  then
    duration = allBuffsModule.buffFromSpellIdLookup[enchantBuffId].singleDuration
  else
    duration = 300
  end

  self.knownBuffs[-enchantBuffId] = buffModule:New(
    -enchantBuffId,
    duration,
    GetTime() + expiration / 1000,
    "player",
    true)

  self.offhandEnchantment = enchantBuffId
end

---@param party BomParty
---@param playerZone number
---@return BomUnit
function unitClass:UpdateBuffs(party, playerZone)
  self.isSameZone = (C_Map.GetBestMapForUnit(self.unitId) == playerZone)
      or self.isGhost
      or self.unitId == "target"

  if not self.isDead
      or BuffomatAddon.declineHasResurrection
  then
    self.hasResurrection = false
    self.distance = toolboxModule:UnitDistanceSquared(self.unitId)
  else
    self.hasResurrection = UnitHasIncomingResurrection(self.unitId)
        or self.hasResurrection
  end

  self:ForceUpdateBuffs(party.player)

  return self
end

function unitClass:UpdatePlayerWeaponEnchantments()
  ---@type boolean, number, number, BomEnchantmentId, boolean, number, number, BomEnchantmentId
  local hasMainHandEnchant, mainHandExpiration, mainHandCharges, mainHandEnchantID
  , hasOffHandEnchant, offHandExpiration, offHandCharges, offHandEnchantId = envModule.GetWeaponEnchantInfo()

  if hasMainHandEnchant == nil or hasOffHandEnchant == nil then
    self.auraDataUnavailable = true
    self.NeedBuff = false
    return self
  end

  if hasMainHandEnchant and mainHandEnchantID
      and allBuffsModule.enchantToSpellLookup[mainHandEnchantID] then
    self:SetMainhandBuff(mainHandEnchantID, mainHandExpiration)
  else
    self:ClearMainhandBuff()
  end

  if hasOffHandEnchant
      and offHandEnchantId
      and allBuffsModule.enchantToSpellLookup[offHandEnchantId] then
    self:SetOffhandBuff(offHandEnchantId, offHandExpiration)
  else
    self:ClearOffhandBuff()
  end

  return self
end

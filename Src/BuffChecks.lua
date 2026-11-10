local BuffomatAddon = BuffomatAddon

---@class BuffChecksModule

local module = LibStub("Buffomat-BuffChecks") --[[@as BuffChecksModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local bagScanModule = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]
local scanSchedulerModule = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]

---Checks whether a tracking spell is now active
---@param spell BomBuffDefinition The tracking spell which might have tracking enabled
function module:IsTrackingActive(spell)
  return playerStateModule:IsTrackingActive(spell)
end

---@param expirationTime number Buff expiration time
---@param maxDuration number Max buff duration
function module:TimeCheck(expirationTime, maxDuration)
  if expirationTime == nil
      or maxDuration == nil
      or expirationTime == 0
      or maxDuration == 0 then
    return true
  end

  local remainingTimeTrigger

  if maxDuration <= allBuffsModule.MINUTE then
    remainingTimeTrigger = BuffomatShared.Time60 or 10
  elseif maxDuration <= allBuffsModule.FIVE_MINUTES then
    remainingTimeTrigger = BuffomatShared.Time300 or 90
  elseif maxDuration <= allBuffsModule.TEN_MINUTES then
    remainingTimeTrigger = BuffomatShared.Time600 or 120
  elseif maxDuration <= allBuffsModule.HALF_AN_HOUR then
    remainingTimeTrigger = BuffomatShared.Time1800 or 180
  else
    remainingTimeTrigger = BuffomatShared.Time3600 or 180
  end

  if remainingTimeTrigger + GetTime() < expirationTime then
    -- Look again when the buff gets close enough to its end to be refreshed
    scanSchedulerModule:WakeAt(expirationTime - remainingTimeTrigger)
    return true
  end

  return false
end

---Whether the player has an item in the bags, answered from the bag snapshot.
---@param itemToCheck WowItemId
---@param cd boolean When true, an item on cooldown counts as not available
---@return boolean hasItem
---@return number? bag Bag of the first stack
---@return number? slot Slot of the first stack
---@return number? count Total in all bags
function module:HasOneItem(itemToCheck, cd)
  if itemToCheck == nil then
    return true, nil, nil, 1 -- spell.items is nil, no items required
  end

  local item = bagScanModule:Find(itemToCheck)
  if item == nil then
    return false, nil, nil, 0
  end
  if cd and not bagScanModule:IsReady(item) then
    return false, item.bag, item.slot, item.count
  end
  return true, item.bag, item.slot, item.count
end

--- Check item min level
function module:IsUsableItem(itemId)
  local itemInfo = BuffomatAddon.GetItemInfo(itemId)
  if itemInfo then
    return (itemInfo).itemMinLevel <= UnitLevel("player")
  end
  return true
end

---Check whether the player has item
-- TODO: Can move in with item cache?
---@param itemsToCheck WowItemId[]
---@param cd boolean respect the cooldown?
---@return boolean, number|nil, number|nil, number|nil, WowItemId|nil {HasItem, Bag, Slot, Count, ItemIdAvailable}
function module:HasItem(itemsToCheck, cd)
  for _, itemId in pairs(itemsToCheck) do
    if self:IsUsableItem(itemId) then
      local okEach, bagEach, slotEach, countEach = self:HasOneItem(itemId, cd)
      if okEach then
        -- save last successful result
        return okEach, bagEach, slotEach, countEach, itemId
      end
    end
  end
  return false, nil, nil, nil, nil
end

---Whether the weapon in an equipment slot can take this weapon enchantment. Buffs without a
---weapon type limit fit anything; a limited buff needs a weapon of one of its types.
---@param buff BomBuffDefinition
---@param slot number 16 main hand, 17 off hand
---@return boolean
function module:WeaponFitsBuff(buff, slot)
  if not buff.weaponSubclasses then
    return true
  end
  local itemId = playerStateModule.inventory[slot]
  if itemId == nil then
    return false
  end
  local classID, subclassID = envModule.GetItemClass(itemId)
  return classID == itemIdsModule.ITEM_CLASS_WEAPON and tContains(buff.weaponSubclasses, subclassID)
end

---Hands which need this weapon enchantment: enabled in the profile, not enchanted, and the
---weapon there fits the enchantment.
---@param buff BomBuffDefinition
---@param playerUnit BomUnit
---@return boolean needMainhand
---@return boolean needOffhand
function module:WeaponHandsNeedingBuff(buff, playerUnit)
  local profileBuff = profileModule:GetProfileBuff(buff.buffId, nil)
  if not profileBuff then
    return false, false
  end
  local needMainhand = profileBuff.MainHandEnable and playerUnit.mainhandEnchantment == nil
      and self:WeaponFitsBuff(buff, 16)
  local needOffhand = profileBuff.OffHandEnable and playerUnit.offhandEnchantment == nil
      and self:WeaponFitsBuff(buff, 17)
  return needMainhand == true, needOffhand == true
end

---@param buff BomBuffDefinition the spell to update
---@param playerUnit BomUnit the player
function module:PlayerNeedsWeaponBuff(buff, playerUnit)
  local needMainHand, needOffhand = self:WeaponHandsNeedingBuff(buff, playerUnit)
  if needMainHand or needOffhand then
    table.insert(buff.unitsNeedBuff, playerUnit)
  end
end

---@param buff BomBuffDefinition
---@param playerUnit BomUnit
function module:HunterPetNeedsBuff(buff, playerUnit)
  if not envModule.haveTBC then
    return -- pre-TBC this did not exist
  end

  local pet = rosterScanModule.roster.playerPet
  if not pet then
    return -- no pet - no problem
  end

  if pet:HaveBuff(buff.highestRankSingleId) then
    return -- have pet, have buff
  end

  table.insert(buff.unitsNeedBuff, playerUnit) -- add player to buff list, because player must consume it
end

---@param buff BomBuffDefinition
---@param playerUnit BomUnit
function module:PlayerNeedsConsumable(buff, playerUnit)
  if buff.providesAuras then
    for _, aura in pairs(buff.providesAuras) do
      if playerUnit.allBuffs[aura] then
        return -- have one of known provided auras, means we don't need that consumable
      end
    end
  end

  if not playerUnit.knownBuffs[buff.buffId] then
    table.insert(buff.unitsNeedBuff, playerUnit)
  end
end

---Runs a reminder buff's check on the player and keeps its text for the info task
---@param buffDef BomBuffDefinition
---@param playerUnit BomUnit
function module:PlayerNeedsReminder(buffDef, playerUnit)
  buffDef.reminderText = nil
  if playerUnit.isDead or playerUnit.auraDataUnavailable then
    return
  end
  local text = buffDef.reminderCheck(buffDef, playerUnit)
  if text then
    buffDef.reminderText = text
    table.insert(buffDef.unitsNeedBuff, playerUnit)
  end
end

---@param buff BomBuffDefinition
---@param party BomParty
function module:PartyNeedsInfoBuff(buff, party)
  for _i, partyMember in pairs(party.byUnitId) do
    local partyMemberBuff = partyMember.knownBuffs[buff.buffId]

    if partyMemberBuff then
      table.insert(buff.unitsNeedBuff, partyMember)

      if partyMember.isPlayer then
        buff.buffSource = partyMemberBuff.source
      end

      if envModule.UnitIsUnit("player", partyMemberBuff.source or "") then
        partyModule.itemListTarget[buff.buffId] = partyMember.name
      end
    end
  end
end

--- Checks if the player needs some buff that is in the buffs knowledge database. Must be a spell/aura that is stored in playerUnit.knownBuffs
---@param buff BomBuffDefinition
---@param playerUnit BomUnit
function module:PlayerNeedsSelfBuff(buff, playerUnit)
  if not playerUnit.isDead then
    local thisBuffOnPlayer = playerUnit.knownBuffs[buff.buffId]

    -- Check if the self-buff includes creating/conjuring an item
    if buff.lockIfHaveItem then
      if envModule.IsSpellKnown(buff.highestRankSingleId) and not (self:HasItem(buff.lockIfHaveItem, buff.hasCD)) then
        table.insert(buff.unitsNeedBuff, playerUnit)
      end

      -- Else check if the buff is on player and timer is not too short
    elseif not (thisBuffOnPlayer
          and self:TimeCheck(thisBuffOnPlayer.expirationTime, thisBuffOnPlayer.duration))
    then
      table.insert(buff.unitsNeedBuff, playerUnit)
    end
  end
end

---@param buff BomBuffDefinition
---@param party BomParty
function module:DeadNeedsResurrection(buff, party)
  for _i, member in pairs(party.byUnitId) do
    if member.isDead
        and not member.hasResurrection
        and member.isConnected
        and member.class ~= "pet"
        and (not BuffomatShared.SameZone or member.isSameZone) then
      table.insert(buff.unitsNeedBuff, member)
    end
  end
end

---@param buff BomBuffDefinition
---@param playerUnit BomUnit
function module:PlayerNeedsTracking(buff, playerUnit)
  -- Special handling: Having find herbs and find ore will be ignored if
  -- in cat form and track humanoids is enabled
  if (buff.highestRankSingleId == spellIdsModule.FindHerbs or
        buff.highestRankSingleId == spellIdsModule.FindMinerals)
      and playerStateModule.formId == envModule.CAT_FORM
      and buffDefModule:IsBuffEnabled(spellIdsModule.Druid_TrackHumanoids, nil) then
    -- Do nothing - ignore herbs and minerals in catform if enabled track humanoids
  elseif not self:IsTrackingActive(buff)
      and (BuffomatAddon.forceTracking == nil
        or BuffomatAddon.forceTracking == buff.trackingIconId) then
    table.insert(buff.unitsNeedBuff, playerUnit)
  end
end

---@param buff BomBuffDefinition
---@param playerUnit BomUnit
function module:PaladinNeedsAura(buff, playerUnit)
  if BuffomatAddon.activePaladinAura ~= buff.buffId
      and (buffomatModule.currentProfile.LastAura == nil
        or buffomatModule.currentProfile.LastAura == buff.buffId)
  then
    table.insert(buff.unitsNeedBuff, playerUnit)
  end
end

---@param spell BomBuffDefinition
---@param playerUnit BomUnit
function module:PaladinNeedsSeal(spell, playerUnit)
  if BuffomatAddon.activePaladinSeal ~= spell.buffId
      and (buffomatModule.currentProfile.LastSeal == nil
        or buffomatModule.currentProfile.LastSeal == spell.buffId)
  then
    table.insert(spell.unitsNeedBuff, playerUnit)
  end
end

---@param buffDef BomBuffDefinition
---@param party BomParty
---@param buffCtx BomBuffScanContext
function module:PartyNeedsPaladinBlessing(buffDef, party, buffCtx)
  -- Blessing user settings (regardless of the current buff)
  local currentBlessing = buffDefModule:GetProfileBlessingState(nil)
  -- Current user settings for the selected buff
  local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)

  ---@param partyMember BomUnit
  for _, partyMember in pairs(party.byUnitId) do
    local ok = false
    local notGroup = false

    if currentBlessing[partyMember.name] == buffDef.buffId
        or (partyMember.isTank and profileBuff.Class["tank"] and not profileBuff.SelfCast)
    then
      ok = true
      notGroup = true
    elseif currentBlessing[partyMember.name] == nil then
      if profileBuff.Class[partyMember.class]
          and (not IsInRaid() or BuffomatCharacter.WatchGroup[partyMember.group])
          and not profileBuff.SelfCast then
        ok = true
      end
      if profileBuff.SelfCast
          and envModule.UnitIsUnit(partyMember.unitId, "player") then
        ok = true
      end
    end

    if profileBuff.ForcedTarget[partyMember.name] then
      ok = true
    end
    if profileBuff.ExcludedTarget[partyMember.name] then
      ok = false
    end

    if partyMember.NeedBuff
        and ok
        and partyMember.isConnected
        and (not BuffomatShared.SameZone or partyMember.isSameZone) then
      local found = false
      local partyMemberBuff = partyMember.knownBuffs[buffDef.buffId]

      if partyMember.isDead then
        if partyMember.group ~= 9 and partyMember.class ~= "pet" then
          buffCtx.someoneIsDead = true
          buffDef.groupsHaveDead[partyMember.class] = true
        end
      elseif partyMemberBuff then
        found = self:TimeCheck(partyMemberBuff.expirationTime, partyMemberBuff.duration)
      end

      if not found then
        table.insert(buffDef.unitsNeedBuff, partyMember)
        if not notGroup then
          buffDef:IncrementNeedGroupBuff(partyMember.class)
        end
      elseif not notGroup
          and BuffomatShared.ReplaceSingle
          and partyMemberBuff
          and partyMemberBuff.isSingle then
        buffDef:IncrementNeedGroupBuff(partyMember.class)
      end
    end
  end
end

---@param buffDef BomBuffDefinition
---@param party BomParty
---@param buffCtx BomBuffScanContext
function module:PartyNeedsBuff(buffDef, party, buffCtx)
  --spells
  for _, partyMember in pairs(party.byUnitId) do
    local ok = false
    local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)

    if profileBuff.Class[partyMember.class]
        and (not IsInRaid() or BuffomatCharacter.WatchGroup[partyMember.group])
        and not profileBuff.SelfCast then
      ok = true
    end
    if profileBuff.SelfCast
        and envModule.UnitIsUnit(partyMember.unitId, "player") then
      ok = true
    end
    if partyMember.isTank and profileBuff.Class["tank"]
        and not profileBuff.SelfCast then
      ok = true
    end
    if profileBuff.ForcedTarget[partyMember.name] then
      ok = true
    end
    if profileBuff.ExcludedTarget[partyMember.name] then
      ok = false
    end

    if partyMember.NeedBuff
        and ok
        and partyMember.isConnected
        and (not BuffomatShared.SameZone
          or (partyMember.isSameZone
            or partyMember.class == "pet" and (partyMember.owner).isSameZone))
    then
      local found = false
      local partyMemberBuff = partyMember.knownBuffs[buffDef.buffId]

      if partyMember.isDead then
        buffCtx.someoneIsDead = true
        buffDef.groupsHaveDead[partyMember.group] = true
      elseif partyMemberBuff then
        found = self:TimeCheck(partyMemberBuff.expirationTime, partyMemberBuff.duration)
      end

      if not found then
        table.insert(buffDef.unitsNeedBuff, partyMember)
        buffDef.groupsNeedBuff[partyMember.group] = (buffDef.groupsNeedBuff[partyMember.group] or 0) + 1
      elseif BuffomatShared.ReplaceSingle
          and partyMemberBuff
          and partyMemberBuff.isSingle then
        buffDef.groupsNeedBuff[partyMember.group] = (buffDef.groupsNeedBuff[partyMember.group] or 0) + 1
      end
    end -- if needbuff and connected and samezone
  end   -- for all in party
end

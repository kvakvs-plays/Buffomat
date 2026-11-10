local BuffomatAddon = BuffomatAddon

-- Per-buff checks of the evaluation stage: does this member need this buff? They read
-- the snapshots made by Src/Scan and write who needs the buff into a BomBuffNeed.

---@class BuffChecksModule

local module = LibStub("Buffomat-BuffChecks") --[[@as BuffChecksModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
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
    return (itemInfo).itemMinLevel <= (playerStateModule.level or 0)
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
      and self:WeaponFitsBuff(buff, playerStateModule.SLOT_MAINHAND)
  local needOffhand = profileBuff.OffHandEnable and playerUnit.offhandEnchantment == nil
      and self:WeaponFitsBuff(buff, playerStateModule.SLOT_OFFHAND)
  return needMainhand == true, needOffhand == true
end

---@param buff BomBuffDefinition the weapon buff
---@param need BomBuffNeed
---@param playerUnit BomUnit the player
function module:PlayerNeedsWeaponBuff(buff, need, playerUnit)
  local needMainHand, needOffhand = self:WeaponHandsNeedingBuff(buff, playerUnit)
  if needMainHand or needOffhand then
    table.insert(need.units, playerUnit)
  end
end

---For TBC hunter pet buffs: the pet is missing the buff, but the hunter must consume it.
---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param roster BomRoster
function module:HunterPetNeedsBuff(buff, need, roster)
  if not envModule.haveTBC then
    return -- pre-TBC this did not exist
  end

  local pet = roster.playerPet
  if not pet then
    return -- no pet - no problem
  end

  if pet:HaveBuff(buff.highestRankSingleId) then
    return -- have pet, have buff
  end

  table.insert(need.units, roster.player) -- the player must consume it
end

---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param playerUnit BomUnit
function module:PlayerNeedsConsumable(buff, need, playerUnit)
  if buff.providesAuras then
    for _, aura in pairs(buff.providesAuras) do
      if playerUnit.allBuffs[aura] then
        return -- have one of known provided auras, means we don't need that consumable
      end
    end
  end

  if not playerUnit.knownBuffs[buff.buffId] then
    table.insert(need.units, playerUnit)
  end
end

---Runs a reminder buff's check on the player and keeps its text for the info task
---@param buffDef BomBuffDefinition
---@param need BomBuffNeed
---@param playerUnit BomUnit
function module:PlayerNeedsReminder(buffDef, need, playerUnit)
  if playerUnit.isDead or playerUnit.auraDataUnavailable then
    return
  end
  local text = buffDef.reminderCheck(buffDef, playerUnit)
  if text then
    need.reminderText = text
    table.insert(need.units, playerUnit)
  end
end

---An info buff is reported for every member who has it.
---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param roster BomRoster
---@param result BomScanResult
function module:PartyNeedsInfoBuff(buff, need, roster, result)
  for _, member in ipairs(roster.units) do
    local memberBuff = member.knownBuffs[buff.buffId]

    if memberBuff then
      table.insert(need.units, member)

      if memberBuff.fromPlayer then
        -- A usable item with this buff (a soulstone) goes to the same member again
        result.itemTargets[buff.buffId] = member.name
      end
    end
  end
end

--- Checks if the player needs some buff that is in the buffs knowledge database. Must be a spell/aura that is stored in playerUnit.knownBuffs
---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param playerUnit BomUnit
function module:PlayerNeedsSelfBuff(buff, need, playerUnit)
  if not playerUnit.isDead then
    local thisBuffOnPlayer = playerUnit.knownBuffs[buff.buffId]

    -- Check if the self-buff includes creating/conjuring an item
    if buff.lockIfHaveItem then
      if envModule.IsSpellKnown(buff.highestRankSingleId) and not (self:HasItem(buff.lockIfHaveItem, buff.hasCD)) then
        table.insert(need.units, playerUnit)
      end

      -- Else check if the buff is on player and timer is not too short
    elseif not (thisBuffOnPlayer
          and self:TimeCheck(thisBuffOnPlayer.expirationTime, thisBuffOnPlayer.duration))
    then
      table.insert(need.units, playerUnit)
    end
  end
end

---@param _buff BomBuffDefinition
---@param need BomBuffNeed
---@param roster BomRoster
function module:DeadNeedsResurrection(_buff, need, roster)
  for _, member in ipairs(roster.units) do
    if member.isDead
        and not member.hasResurrection
        and member.isConnected
        and member.class ~= "pet"
        and (not BuffomatShared.SameZone or member.isSameZone) then
      table.insert(need.units, member)
    end
  end
end

---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param playerUnit BomUnit
---@param result BomScanResult
function module:PlayerNeedsTracking(buff, need, playerUnit, result)
  -- Special handling: Having find herbs and find ore will be ignored if
  -- in cat form and track humanoids is enabled
  if (buff.highestRankSingleId == spellIdsModule.FindHerbs or
        buff.highestRankSingleId == spellIdsModule.FindMinerals)
      and playerStateModule.formId == envModule.CAT_FORM
      and buffDefModule:IsBuffEnabled(spellIdsModule.Druid_TrackHumanoids, nil) then
    -- Do nothing - ignore herbs and minerals in catform if enabled track humanoids
  elseif not self:IsTrackingActive(buff)
      and (result.forceTracking == nil
        or result.forceTracking == buff.trackingIconId) then
    table.insert(need.units, playerUnit)
  end
end

---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param playerUnit BomUnit
---@param result BomScanResult
function module:PaladinNeedsAura(buff, need, playerUnit, result)
  if result.activeAura ~= buff.buffId
      and (buffomatModule.currentProfile.LastAura == nil
        or buffomatModule.currentProfile.LastAura == buff.buffId)
  then
    table.insert(need.units, playerUnit)
  end
end

---@param buff BomBuffDefinition
---@param need BomBuffNeed
---@param playerUnit BomUnit
---@param result BomScanResult
function module:PaladinNeedsSeal(buff, need, playerUnit, result)
  if result.activeSeal ~= buff.buffId
      and (buffomatModule.currentProfile.LastSeal == nil
        or buffomatModule.currentProfile.LastSeal == buff.buffId)
  then
    table.insert(need.units, playerUnit)
  end
end

---@param buffDef BomBuffDefinition
---@param need BomBuffNeed
---@param roster BomRoster
function module:PartyNeedsPaladinBlessing(buffDef, need, roster)
  -- Blessing user settings (regardless of the current buff)
  local currentBlessing = buffDefModule:GetProfileBlessingState(nil)
  -- Current user settings for the selected buff
  local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)

  for _, partyMember in ipairs(roster.units) do
    local ok = false
    local notGroup = false

    if currentBlessing[partyMember.name] == buffDef.buffId
        or (partyMember.isTank and profileBuff.Class["tank"] and not profileBuff.SelfCast)
    then
      ok = true
      notGroup = true
    elseif currentBlessing[partyMember.name] == nil then
      if profileBuff.Class[partyMember.class]
          and (not roster.isRaid or BuffomatCharacter.WatchGroup[partyMember.group])
          and not profileBuff.SelfCast then
        ok = true
      end
      if profileBuff.SelfCast and partyMember.isPlayer then
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
          need.groupsHaveDead[partyMember.class] = true
        end
      elseif partyMemberBuff then
        found = self:TimeCheck(partyMemberBuff.expirationTime, partyMemberBuff.duration)
      end

      if not found then
        table.insert(need.units, partyMember)
        if not notGroup then
          need.groups[partyMember.class] = (need.groups[partyMember.class] or 0) + 1
        end
      elseif not notGroup
          and BuffomatShared.ReplaceSingle
          and partyMemberBuff
          and partyMemberBuff.isSingle then
        need.groups[partyMember.class] = (need.groups[partyMember.class] or 0) + 1
      end
    end
  end
end

---@param buffDef BomBuffDefinition
---@param need BomBuffNeed
---@param roster BomRoster
function module:PartyNeedsBuff(buffDef, need, roster)
  local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)

  for _, partyMember in ipairs(roster.units) do
    local ok = false

    if profileBuff.Class[partyMember.class]
        and (not roster.isRaid or BuffomatCharacter.WatchGroup[partyMember.group])
        and not profileBuff.SelfCast then
      ok = true
    end
    if profileBuff.SelfCast and partyMember.isPlayer then
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
            or partyMember.class == "pet" and partyMember.owner ~= nil and partyMember.owner.isSameZone))
    then
      local found = false
      local partyMemberBuff = partyMember.knownBuffs[buffDef.buffId]

      if partyMember.isDead then
        need.groupsHaveDead[partyMember.group] = true
      elseif partyMemberBuff then
        found = self:TimeCheck(partyMemberBuff.expirationTime, partyMemberBuff.duration)
      end

      if not found then
        table.insert(need.units, partyMember)
        need.groups[partyMember.group] = (need.groups[partyMember.group] or 0) + 1
      elseif BuffomatShared.ReplaceSingle
          and partyMemberBuff
          and partyMemberBuff.isSingle then
        need.groups[partyMember.group] = (need.groups[partyMember.group] or 0) + 1
      end
    end -- if needbuff and connected and samezone
  end   -- for all in party
end

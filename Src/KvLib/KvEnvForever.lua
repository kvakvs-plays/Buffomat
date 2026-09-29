local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

envModule.isForever = true
envModule.isClassic = true

envModule.GetSpellInfo = function(spell)
  if spell == nil then
    return nil
  end
  local info = C_Spell.GetSpellInfo(spell)
  if info == nil then
    return nil
  end
  return info.name, nil, info.iconID, info.castTime, info.minRange, info.maxRange, info.spellID
end

envModule.GetSpellSubtext = function(spell)
  if spell == nil then
    return nil
  end
  return C_Spell.GetSpellSubtext(spell)
end

envModule.GetSpellCooldown = function(spell)
  if spell == nil then
    return nil
  end
  local info = C_Spell.GetSpellCooldown(spell)
  if info == nil then
    return nil
  end
  return info.startTime, info.duration, info.isEnabled and 1 or 0, info.modRate
end

envModule.GetSpellPowerCost = function(spell)
  if spell == nil then
    return nil
  end
  return C_Spell.GetSpellPowerCost(spell)
end

envModule.IsSpellInRange = function(spell, unit)
  if spell == nil then
    return nil
  end
  local inRange = C_Spell.IsSpellInRange(spell, unit)
  if inRange == nil then
    return nil
  end
  return inRange and 1 or 0
end

envModule.IsSpellKnown = function(spellId)
  if spellId == nil then
    return false
  end
  return C_SpellBook.IsSpellKnown(spellId)
end

envModule.UnitAura = function(unit, index, filter)
  local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
  if not ok then
    return nil
  end
  return AuraUtil.UnpackAuraData(aura)
end

envModule.UnitBuff = function(unit, index, filter)
  local ok, aura = pcall(C_UnitAuras.GetBuffDataByIndex, unit, index, filter)
  if not ok then
    return nil
  end
  return AuraUtil.UnpackAuraData(aura)
end

envModule.UnitPower = function(unit, powerType)
  local value = UnitPower(unit, powerType)
  if issecretvalue(value) then
    return nil
  end
  return value
end

envModule.UnitInRange = function(unit)
  local inRange, checkedRange = UnitInRange(unit)
  if issecretvalue(inRange) then
    return nil
  end
  return inRange, checkedRange
end

envModule.GetItemInfo = function(item)
  if item == nil then
    return nil
  end
  return C_Item.GetItemInfo(item)
end

envModule.IsItemInRange = function(item, unit)
  if item == nil then
    return nil
  end
  return C_Item.IsItemInRange(item, unit)
end

---@param weaponSlot number
---@return boolean, number?, number?, number?
local function getWeaponEnchant(weaponSlot)
  for _, enchant in pairs(C_Item.GetWeaponEnchantInfo(weaponSlot)) do
    if enchant.hasEnchant then
      return true, enchant.timeLeft, enchant.charges, enchant.enchantID
    end
  end
  return false, nil, nil, nil
end

envModule.GetWeaponEnchantInfo = function()
  local hasMainHand, mainHandExpiration, mainHandCharges, mainHandEnchantId = getWeaponEnchant(Enum.WeaponSlot.MainHand)
  local hasOffHand, offHandExpiration, offHandCharges, offHandEnchantId = getWeaponEnchant(Enum.WeaponSlot.OffHand)
  return hasMainHand, mainHandExpiration, mainHandCharges, mainHandEnchantId,
      hasOffHand, offHandExpiration, offHandCharges, offHandEnchantId
end

envModule.GetInventorySlotInfo = C_PaperDollInfo.GetInventorySlotInfo
envModule.GetActiveTalentGroup = C_SpecializationInfo.GetActiveSpecGroup

envModule.GetTrackingInfo = function(index)
  local info = C_Minimap.GetTrackingInfo(index)
  if info == nil then
    return nil
  end
  return info.name, info.texture, info.active, info.type, info.subType, info.spellID
end

envModule.ChatEdit_SendText = function(editBox)
  editBox:SendText()
end

envModule.ChatFrame_OpenChat = ChatFrameUtil.OpenChat

envModule.MAX_ACCOUNT_MACROS = Constants.MacroConsts.MAX_ACCOUNT_MACROS
envModule.MAX_CHARACTER_MACROS = Constants.MacroConsts.MAX_CHARACTER_MACROS
envModule.CAT_FORM = 1

envModule.MouseIsOver = function(frame)
  return frame:IsMouseOver()
end

---@type number[]
local auraRestrictions = {
  Enum.AddOnRestrictionType.Combat,
  Enum.AddOnRestrictionType.Encounter,
  Enum.AddOnRestrictionType.ChallengeMode,
  Enum.AddOnRestrictionType.PvPMatch,
}

envModule.IsAuraRestricted = function()
  for _, restriction in ipairs(auraRestrictions) do
    if C_RestrictedActions.IsAddOnRestrictionActive(restriction) then
      return true
    end
  end
  return false
end

local addonName, ns = ...

-- What a scan does to the game besides showing tasks: cancelling buffs, switching
-- tracking on, and the skip list of members a cast failed on. Evaluation only decides
-- these; they are carried out here, after the task list is built.

---@class ScanEffectsModule
---@field cancelBuffSource string? Unit which cast the buff that was cancelled last
---@field pvpMatchNoticeShown boolean? The PvP match chat notice was printed this session
local module = LibStub("Buffomat-ScanEffects") --[[@as ScanEffectsModule]]

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local scheduler = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

local CANCELABLE = "HELPFUL|CANCELABLE"

---Cancel the first buff on the player which is one of the given spells.
---@param spellIds WowSpellId[]?
---@return boolean cancelled
function module:CancelBuff(spellIds)
  if spellIds == nil or InCombatLockdown() or envModule.IsAuraRestricted() then
    return false
  end
  for index = 1, 40 do
    local spellId, _name, _duration, _expirationTime, source, readable =
        kvUnitModule.ReadAura("player", index, CANCELABLE)
    if not readable or spellId == nil then
      break
    end
    if tContains(spellIds, spellId) then
      self.cancelBuffSource = source or "player"
      -- The same filter, so the index still refers to the aura just looked at
      kvPlayerModule.CancelAura(index, CANCELABLE)
      return true
    end
  end
  return false
end

---Leave a travel form. Global because the taxi and error handlers call it.
---@return boolean cancelled
function BuffomatAddon.CancelShapeShift()
  return module:CancelBuff(spellIdsModule.TravelShapeshiftForms)
end

---@param unitId string?
---@return string name Empty when unknown
local function unitName(unitId)
  return unitId and kvUnitModule.GetName(unitId) or ""
end

---On combat start: cancel the buffs the profile lists for cancelling.
function BuffomatAddon.DoCancelBuffs()
  local profile = buffomatModule.currentProfile
  if profile == nil then
    return
  end
  for _, buffDef in ipairs(BuffomatAddon.cancelBuffs or {}) do
    if profile.CancelBuff[buffDef.buffId].Enable and module:CancelBuff(buffDef.singleFamily) then
      BuffomatAddon:Print(string.format(_t("message.CancelBuff"), buffDef:SingleLink(),
        unitName(module.cancelBuffSource)))
    end
  end
end

---Switch a tracking spell on.
---@param buffDef BomBuffDefinition The tracking buff
function module:ActivateTracking(buffDef)
  if envModule.usesTrackingSettings then
    for index = 1, envModule.GetNumTrackingTypes() do
      local _name, _texture, _active, _category, _nesting, spellId = envModule.GetTrackingInfo(index)
      if spellId == buffDef.highestRankSingleId then
        envModule.SetTracking(index, true)
        return
      end
    end
  else
    kvPlayerModule.CastSpellByID(buffDef.highestRankSingleId)
  end
end

---Carry out the side effects a pass decided on.
---@param result BomScanResult
---@param playerUnit BomUnit
function module:Run(result, playerUnit)
  for _, buffDef in ipairs(result.buffsToCancel) do
    local buff = playerUnit.knownBuffs[buffDef.buffId]
    BuffomatAddon:Print(string.format(_t("message.CancelBuff"), buffDef:SingleLink(),
      unitName(buff and buff.source)))
    self:CancelBuff(buffDef.singleFamily)
  end
  for _, buffDef in ipairs(result.trackingToActivate) do
    self:ActivateTracking(buffDef)
  end
end

---If a spell cast failed, the member is temporarily added to skip list, to
---continue casting buffs on other members
function BuffomatAddon.AddMemberToSkipList()
  local failedBuff, failedTarget = BuffomatAddon.castFailedBuff, BuffomatAddon.castFailedBuffTarget
  if failedBuff and failedTarget and failedBuff.skipList then
    table.insert(failedBuff.skipList, failedTarget.name)
    scheduler:Request("skipListMemberAdded")
  end
end

---Offer every member again.
function module:ClearSkip()
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    if buffDef.skipList then
      wipe(buffDef.skipList)
    end
  end
end

---If player just left the raid or party, reset watched groups to "watch all 8"
function module:MaybeResetWatchGroups()
  if kvUnitModule.IsInGroup() then
    return
  end
  local changed = false
  for group = 1, 8 do
    if not BuffomatCharacter.WatchGroup[group] then
      BuffomatCharacter.WatchGroup[group] = true
      changed = true
    end
  end

  buffomatModule:UpdateBuffTabText()
  if changed then
    BuffomatAddon:Print(_t("ResetWatchGroups"))
  end
end

---Play the sound chosen for "a task appeared".
function module:PlayTaskSound()
  local sound = BuffomatShared.PlaySoundWhenTask
  if sound ~= nil and sound ~= "-" then
    kvPlayerModule.PlaySoundFile("Interface\\AddOns\\BuffomatClassic\\Sounds\\" .. sound)
  end
end

---Explain once per session why most buffs are not checked during a PvP match.
function module:NotifyPvPMatchOnce()
  if not self.pvpMatchNoticeShown then
    self.pvpMatchNoticeShown = true
    BuffomatAddon:Print(_t("message.PvPMatchAuraFree"))
  end
end

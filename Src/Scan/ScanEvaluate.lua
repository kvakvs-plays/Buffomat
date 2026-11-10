local addonName, ns = ...

-- The deciding stages of a scan pass: whether Buffomat is active at all, and who needs
-- which buff. Everything is decided from the snapshots; the only game queries made
-- here are spell cooldowns and "is the spell known", which have no snapshot.

---@class ScanEvaluateModule
local module = LibStub("Buffomat-ScanEvaluate") --[[@as ScanEvaluateModule]]

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffChecksModule = LibStub("Buffomat-BuffChecks") --[[@as BuffChecksModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local macroModule = LibStub("Buffomat-Macro") --[[@as MacroModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
local scheduler = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

-- Spell which is on cooldown exactly while the global cooldown runs
local GLOBAL_COOLDOWN_SPELL = 61304

---@return boolean Flying, and dismounting in the air is not wanted
function module:IsFlying()
  return envModule.haveTBC and playerStateModule.isFlying and not BuffomatShared.AutoDismountFlying
end

---Only pause the scan for a confirmed, unexpired global cooldown.
---@return boolean isInGlobalCooldown
---@return number|nil cooldownEndTime
function module:IsInGlobalCooldown()
  local start, cdDuration = envModule.GetSpellCooldown(GLOBAL_COOLDOWN_SPELL)
  if start == nil or cdDuration == nil then
    -- The GCD probe can be unavailable on modern clients. It must not block
    -- the entire scan; individual actions still check their own cooldowns.
    return false, nil
  end
  if start <= 0 or cdDuration <= 0 then
    return false, nil
  end

  -- A cooldown which ends within the latency is as good as over
  local curPing = math.min(math.max(kvPlayerModule.GetLatency() + .025, 0.05), 0.3)
  local cooldownEndTime = start + cdDuration
  if cooldownEndTime - GetTime() <= curPing then
    return false, nil
  end
  return true, cooldownEndTime
end

---A mounted paladin with the option on is offered Crusader Aura and nothing else.
---@return boolean
function module:IsMountedAndCrusaderAuraRequired()
  local state = playerStateModule
  if state.isOnTaxi or state.isInVehicle then
    return false
  end
  local crusaderAuraShapeshiftForm = (envModule.isCata and 5) or 7
  return BuffomatShared.AutoCrusaderAura == true                      -- if setting enabled
      and envModule.IsSpellKnown(spellIdsModule.Paladin_CrusaderAura) -- and has the spell
      and (state.isMounted or self:IsFlying())                        -- and mounted
      and state.form ~= crusaderAuraShapeshiftForm                    -- and not crusader aura
end

---Run checks to see if BOM should not be scanning buffs
---@param playerUnit BomUnit
---@return boolean active
---@return string whyNotActive Text for the cast button
function module:IsActive(playerUnit)
  local state = playerStateModule
  local instanceType = state.instanceType

  -- Cancel buff tasks if in combat (ALWAYS FIRST CHECK)
  if InCombatLockdown() then
    return false, _t("castButton.inactive.InCombat")
  end

  if macroModule:IsMacroFrameOpen() then
    return false, _t("castButton.inactive.MacroFrameShown")
  end

  if state.isDead then
    return false, _t("castButton.inactive.IsDead")
  end

  if instanceType == "pvp" or instanceType == "arena" then
    if not BuffomatShared.InPVP then
      return false, _t("castButton.inactive.PvpZone")
    end
  elseif instanceType == "party"
      or instanceType == "raid"
      or instanceType == "scenario"
  then
    if not BuffomatShared.InInstance then
      return false, _t("castButton.inactive.Instance")
    end
  else
    if not BuffomatShared.InWorld then
      return false, _t("castButton.inactive.OpenWorld")
    end
  end

  -- Cancel buff tasks if is in a resting area, and option to scan is not set
  if not BuffomatShared.ScanInRestArea and state.isResting then
    return false, _t("castButton.inactive.RestArea")
  end

  -- Cancel buff task scan while mounted or on taxi
  if state.isOnTaxi then
    return false, _t("castButton.inactive.Taxi")
  end
  if state.isInVehicle then
    return false, _t("castButton.inactive.Vehicle")
  end
  if not BuffomatShared.ScanWhileMounted and state.isMounted then
    return false, _t("castButton.inactive.Mounted")
  end

  -- Cancel buff tasks if is in stealth, and option to scan is not set
  if not BuffomatShared.ScanInStealth and state.isStealthed then
    return false, _t("castButton.inactive.IsStealth")
  end

  -- With Spirit Tap running, let mana regenerate up to the configured share first
  local spiritTapMana = state.maxMana * (BuffomatShared.ActivateBomOnSpiritTap or 0) * 0.01
  if playerUnit.allBuffs[spellIdsModule.Priest_SpiritTap] and state.mana < spiritTapMana then
    state.manaWakeLimit = spiritTapMana -- look again when there is that much
    return false, _t("castButton.inactive.PriestSpiritTap")
  end

  -- Having auto crusader aura enabled and Paladin class, and aura other than
  -- Crusader will block this check temporarily
  if self:IsFlying() and not self:IsMountedAndCrusaderAuraRequired() then
    -- prevent dismount in flight, OUCH!
    return false, _t("castButton.inactive.Flying")
  end

  return true, ""
end

---Whether every unit of the roster was read. A buff must not be called missing because
---the client did not let it be seen.
---@param roster BomRoster
---@return boolean
function module:IsAuraDataComplete(roster)
  if roster.incomplete or roster.player.weaponDataUnavailable then
    return false
  end
  for _, unit in ipairs(roster.units) do
    if unit.auraDataUnavailable then
      return false
    end
  end
  return true
end

---Why Buffomat does nothing right now, if so.
---@param roster BomRoster
---@param auraFree boolean PvP match: auras are known to be unreadable and are not used
---@return string? reason Text for the cast button; nil when a scan should go ahead
---@return boolean? hideWindow The reason is one the user chose (an option); the window may be hidden
function module:GetInactiveReason(roster, auraFree)
  if not auraFree and not self:IsAuraDataComplete(roster) then
    return _t("castButton.inactive.AuraDataUnavailable"), false
  end

  -- A mounted paladin who wants Crusader Aura gets it offered whatever the other options say
  if not self:IsMountedAndCrusaderAuraRequired() then
    local isActive, whyNot = self:IsActive(roster.player)
    if not isActive then
      return whyNot, true
    end
  end

  if playerStateModule.casting == "cast" then
    return _t("castButton.Busy"), false
  elseif playerStateModule.casting == "channel" then
    return _t("castButton.BusyChanneling"), false
  end

  local isInGlobalCooldown, cooldownEndTime = self:IsInGlobalCooldown()
  if isInGlobalCooldown then
    if cooldownEndTime then
      scheduler:WakeAt(cooldownEndTime)
    end
    return _t("castButton.inactive.GlobalCooldown"), false
  end
  return nil
end

---Work out which tracking may be switched on, and remember the last one the player used.
---@param result BomScanResult
function module:SelectTracking(result)
  result.forceTracking = nil

  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    if buffDef.type == "tracking" then
      if buffDefModule:IsBuffEnabled(buffDef.buffId, nil) then
        if buffDef.requiresForm ~= nil then
          if playerStateModule.formId == buffDef.requiresForm then
            result.forceTracking = buffDef.trackingIconId
          end
        elseif playerStateModule:IsTrackingActive(buffDef) then
          BuffomatCharacter.lastTrackingIconId = buffDef.trackingIconId
        end
      elseif BuffomatCharacter.lastTrackingIconId == buffDef.trackingIconId then
        BuffomatCharacter.lastTrackingIconId = nil
      end
    end
  end

  if result.forceTracking == nil then
    result.forceTracking = BuffomatCharacter.lastTrackingIconId
  end
end

---Find the paladin aura and seal which are up, and remember them as the player's choice.
---@param playerUnit BomUnit
---@param result BomScanResult
function module:SelectAuraAndSeal(playerUnit, result)
  result.activeAura, result.activeSeal = nil, nil
  local profile = buffomatModule.currentProfile

  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    if buffDef.type == "aura" or buffDef.type == "seal" then
      local buff = playerUnit.knownBuffs[buffDef.buffId]
      if buff and buff.fromPlayer and buffChecksModule:TimeCheck(buff.expirationTime, buff.duration) then
        if buffDef.type == "aura" then
          result.activeAura = buffDef.buffId
        else
          result.activeSeal = buffDef.buffId
        end
      end
    end
  end

  -- Hunter tracks used to be "aura" buffs; a profile which saved one as LastAura would otherwise
  -- block aspects forever, because tracks no longer go through the aura code.
  local lastAuraDef = allBuffsModule.allBuffs and allBuffsModule.allBuffs[profile.LastAura]
  if lastAuraDef ~= nil and lastAuraDef.type ~= "aura" then
    profile.LastAura = nil
  end

  -- The aura or seal which is up becomes the one to keep up; disabling it forgets it
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    local buffId = buffDef.buffId
    if buffDef.type == "aura" then
      if buffDefModule:IsBuffEnabled(buffId, nil) then
        if result.activeAura == buffId then
          profile.LastAura = buffId
        end
      elseif profile.LastAura == buffId then
        profile.LastAura = nil
      end
    elseif buffDef.type == "seal" then
      if buffDefModule:IsBuffEnabled(buffId, nil) then
        if result.activeSeal == buffId then
          profile.LastSeal = buffId
        end
      elseif profile.LastSeal == buffId then
        profile.LastSeal = nil
      end
    end
  end
end

---Whether a buff's need check reads only bags, weapon enchants, or tracking
---state, never unit auras, so it stays decidable while auras are secret.
---@param buffDef BomBuffDefinition
---@param playerUnit BomUnit
---@return boolean
function module:IsAuraFreeBuff(buffDef, playerUnit)
  if buffDef.type == "weapon" then
    return not playerUnit.weaponDataUnavailable
  elseif buffDef.type == "tracking" then
    return true
  end
  -- Conjured items (mana gems, healthstones...) are needed when missing from bags
  return buffDef.isOwn == true and buffDef.lockIfHaveItem ~= nil
      and not buffDef.isConsumable and not buffDef.petBuff and not buffDef.isInfo
end

---Work out who needs one buff.
---@param buffDef BomBuffDefinition
---@param roster BomRoster
---@param result BomScanResult
function module:EvaluateBuff(buffDef, roster, result)
  local need = result:Need(buffDef)
  local player = roster.player

  if buffDef:DoesUnitHaveBetterBuffs(player) then
    table.insert(need.betterBuff, player) -- noted, and nothing else is done
  elseif not buffDefModule:IsBuffEnabled(buffDef.buffId, nil) then
    -- the buff is switched off
  elseif buffDef.type == "weapon" then
    buffChecksModule:PlayerNeedsWeaponBuff(buffDef, need, player)
    -- NOTE: The pet buff check must go before the consumable check
  elseif buffDef.petBuff then
    buffChecksModule:HunterPetNeedsBuff(buffDef, need, roster)
  elseif buffDef.isConsumable then
    buffChecksModule:PlayerNeedsConsumable(buffDef, need, player)
  elseif buffDef.reminderCheck then
    buffChecksModule:PlayerNeedsReminder(buffDef, need, player)
  elseif buffDef.isInfo then
    buffChecksModule:PartyNeedsInfoBuff(buffDef, need, roster, result)
  elseif buffDef.isOwn then
    buffChecksModule:PlayerNeedsSelfBuff(buffDef, need, player)
  elseif buffDef.type == "resurrection" then
    buffChecksModule:DeadNeedsResurrection(buffDef, need, roster)
  elseif buffDef.type == "tracking" then
    buffChecksModule:PlayerNeedsTracking(buffDef, need, player, result)
  elseif buffDef.type == "aura" then
    buffChecksModule:PaladinNeedsAura(buffDef, need, player, result)
  elseif buffDef.type == "seal" then
    buffChecksModule:PaladinNeedsSeal(buffDef, need, player, result)
  elseif buffDef.isBlessing then
    buffChecksModule:PartyNeedsPaladinBlessing(buffDef, need, roster)
  else
    buffChecksModule:PartyNeedsBuff(buffDef, need, roster)
  end

  -- A spell with a cooldown is offered only when it is ready
  if buffDef.hasCD and #need.units > 0 then
    local startTime, duration = envModule.GetSpellCooldown(buffDef.highestRankSingleId)
    if startTime == nil or duration == nil then
      result:ClearNeed(buffDef)
    elseif duration ~= 0 then
      result:ClearNeed(buffDef)
      scheduler:WakeAt(startTime + duration) -- look again when the cooldown is up
    end
  end
end

---Buffs on the player which the profile says to cancel when seen.
---@param playerUnit BomUnit
---@param result BomScanResult
function module:SelectBuffsToCancel(playerUnit, result)
  local profile = buffomatModule.currentProfile
  for _, buffDef in ipairs(BuffomatAddon.cancelBuffs or {}) do
    if profile and profile.CancelBuff[buffDef.buffId].Enable and not buffDef.onlyCombat
        and playerUnit.knownBuffs[buffDef.buffId] then
      table.insert(result.buffsToCancel, buffDef)
    end
  end
end

---Work out who needs which buff.
---@param roster BomRoster
---@param result BomScanResult Emptied and filled
---@param auraFree boolean PvP match: only the buffs which can be decided without auras
function module:Evaluate(roster, result, auraFree)
  result:Reset()
  self:SelectTracking(result)

  if auraFree then
    for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
      if self:IsAuraFreeBuff(buffDef, roster.player) then
        self:EvaluateBuff(buffDef, roster, result)
      end
    end
    return
  end

  self:SelectAuraAndSeal(roster.player, result)
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    self:EvaluateBuff(buffDef, roster, result)
  end
  self:SelectBuffsToCancel(roster.player, result)
end

local BuffomatAddon = BuffomatAddon

---@class TaskScanModule
---@field taskListSizeBeforeScan number Saved size before scan
---@field saveSomeoneIsDead boolean
---@field pvpMatchNoticeShown boolean? The PvP match chat notice was printed this session
local module = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]

module.taskListSizeBeforeScan = 0
module.saveSomeoneIsDead = false
module.tasklist = nil

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local actionCastModule = LibStub("Buffomat-ActionCast") --[[@as ActionCastModule]]
local actionMacroModule = LibStub("Buffomat-ActionMacro") --[[@as ActionMacroModule]]
local actionUseModule = LibStub("Buffomat-ActionUse") --[[@as ActionUseModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local auraScanModule = LibStub("Buffomat-AuraScan") --[[@as AuraScanModule]]
local buffChecksModule = LibStub("Buffomat-BuffChecks") --[[@as BuffChecksModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local buffTargetModule = LibStub("Buffomat-UnitBuffTarget") --[[@as BomUnitBuffTargetModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local groupBuffTargetModule = LibStub("Buffomat-GroupBuffTarget") --[[@as BomGroupBuffTargetModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local bagScanModule = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]
local macroModule = LibStub("Buffomat-Macro") --[[@as MacroModule]]
local ngStringsModule = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]
local taskListModule = LibStub("Buffomat-TaskList") --[[@as TaskListModule]]
local taskModule = LibStub("Buffomat-Task") --[[@as TaskModule]]
local texturesModule = LibStub("Buffomat-Textures") --[[@as TexturesModule]]
local scanSchedulerModule = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local rosterScanModule = LibStub("Buffomat-RosterScan") --[[@as RosterScanModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]

---@class BomBuffScanContext
---@field someoneIsDead boolean

---@class BomScan_NextCastSpell
---@field buffDef BomBuffDefinition|nil
---@field spellLink string|nil
---@field targetUnit BomUnit|nil
---@field spellId number|nil
---@field manaCost number
---@field temporaryDownrank boolean Pick previous rank for certain spells, like Flametongue 10
--local nextCastSpell = {}

function module:IsFlying()
  return envModule.haveTBC and playerStateModule.isFlying and not BuffomatShared.AutoDismountFlying
end

---Only pause the scan for a confirmed, unexpired global cooldown.
---@return boolean isInGlobalCooldown
---@return number|nil cooldownEndTime
function module:IsInGlobalCooldown()
  local spellID = 61304
  local start, cdDuration = envModule.GetSpellCooldown(spellID)
  if start == nil or cdDuration == nil then
    -- The GCD probe can be unavailable on modern clients. It must not block
    -- the entire scan; individual actions still check their own cooldowns.
    return false, nil
  end
  if start <= 0 or cdDuration <= 0 then
    return false, nil
  end

  local minValue = 0.05
  local maxValue = 0.3
  local curPing = kvPlayerModule.GetLatency() + .025

  if curPing < minValue then
    curPing = minValue
  elseif curPing > maxValue then
    curPing = maxValue
  end

  local cooldownEndTime = start + cdDuration
  if cooldownEndTime - GetTime() <= curPing then
    return false, nil
  end
  return true, cooldownEndTime
end

---@return boolean
function module:IsMountedAndCrusaderAuraRequired()
  if playerStateModule.isOnTaxi or playerStateModule.isInVehicle then
    return false
  end
  local crusaderAuraShapeshiftForm = (envModule.isCata and 5) or 7
  return BuffomatShared.AutoCrusaderAura                              -- if setting enabled
      and envModule.IsSpellKnown(spellIdsModule.Paladin_CrusaderAura) -- and has the spell
      and (playerStateModule.isMounted or self:IsFlying())            -- and flying
      and playerStateModule.form ~= crusaderAuraShapeshiftForm        -- and not crusader aura
end

function module:CancelBuff(list)
  local ret = false
  if not InCombatLockdown() and not envModule.IsAuraRestricted() and list then
    for i = 1, 40 do
      local aura, readable = envModule.GetUnitAura("player", i, "HELPFUL|CANCELABLE")
      if not readable or aura == nil then
        break
      end
      if tContains(list, aura.spellId) then
        ret = true
        BuffomatAddon.cancelBuffSource = aura.source or "player"
        -- Use the same filter so the index still refers to the inspected aura.
        CancelUnitBuff("player", i, "HELPFUL|CANCELABLE")
        break
      end
    end
  end
  return ret
end

function BuffomatAddon.CancelShapeShift()
  return module:CancelBuff(spellIdsModule.TravelShapeshiftForms)
end

---If player just left the raid or party, reset watched frames to "watch all 8"
function module:MaybeResetWatchGroups()
  if UnitPlayerOrPetInParty("player") == false then
    -- We have left the party - can clear monitored groups
    local need_to_report = false

    for i = 1, 8 do
      if not BuffomatCharacter.WatchGroup[i] then
        BuffomatCharacter.WatchGroup[i] = true
        --spellButtonsTabModule.spellSettingsFrames[i]:SetState(true)
        need_to_report = true
      end
    end

    buffomatModule:UpdateBuffTabText()

    if need_to_report then
      BuffomatAddon:Print(_t("ResetWatchGroups"))
    end
  end
end

---Tries to activate tracking described by `spell`
---@param spell BomBuffDefinition The tracking spell to activate
---@param value boolean Whether tracking should be enabled
function module:SetTracking(spell, value)
  -- Mainline-based clients also use tracking settings, independent of content era.
  if envModule.usesTrackingSettings then
    for i = 1, envModule.GetNumTrackingTypes() do
      local _name, _texture, _active, _category, _nesting, spellId = envModule.GetTrackingInfo(i)
      if spellId == spell.highestRankSingleId then
        -- found, compare texture with spell icon
        --BOM:Print(_t("ActivateTracking") .. " " .. name)
        envModule.SetTracking(i, value)
        return
      end
    end
  else
    --BOM:Print(_t("ActivateTracking") .. " " .. spell.trackingSpellName)
    CastSpellByID(spell.highestRankSingleId)
  end
end

---Check per each enabled buff and each player, which targets that spell goes onto
---Update spell.NeedMember, spell.NeedGroup and spell.DeathGroup
---@param party BomParty - the party
---@param buffDef BomBuffDefinition the spell to update
---@param buffCtx BomBuffScanContext
function module:UpdateMissingBuffs_EachBuff(party, buffDef, buffCtx)
  buffCtx.someoneIsDead = false

  --local thisBuffOnPlayer = playerUnit.knownBuffs[spell.buffId]
  buffDef:ResetBuffTargets()

  -- Save skipped unit and do nothing
  if buffDef:DoesUnitHaveBetterBuffs(party.player) then
    table.insert(buffDef.unitsHaveBetterBuff, party.player)
  elseif not buffDefModule:IsBuffEnabled(buffDef.buffId, nil) then
    --nothing, the spell is not enabled!
    -- elseif spellButtonsTabModule:CategoryIsHidden(buffDef.category) then
    --   --nothing, the category is not showing!
  elseif buffDef.type == "weapon" then
    buffChecksModule:PlayerNeedsWeaponBuff(buffDef, party.player)
    -- NOTE: This must go before spell.IsConsumable clause
    -- For TBC hunter pet buffs we check if the pet is missing the buff
    -- but then the hunter must consume it
  elseif buffDef.petBuff then
    buffChecksModule:HunterPetNeedsBuff(buffDef, party.player)
  elseif buffDef.isConsumable then
    buffChecksModule:PlayerNeedsConsumable(buffDef, party.player)
  elseif buffDef.reminderCheck then
    buffChecksModule:PlayerNeedsReminder(buffDef, party.player)
  elseif buffDef.isInfo then
    buffChecksModule:PartyNeedsInfoBuff(buffDef, party)
  elseif buffDef.isOwn then
    buffChecksModule:PlayerNeedsSelfBuff(buffDef, party.player)
  elseif buffDef.type == "resurrection" then
    buffChecksModule:DeadNeedsResurrection(buffDef, party)
  elseif buffDef.type == "tracking" then
    buffChecksModule:PlayerNeedsTracking(buffDef, party.player)
  elseif buffDef.type == "aura" then
    buffChecksModule:PaladinNeedsAura(buffDef, party.player)
  elseif buffDef.type == "seal" then
    buffChecksModule:PaladinNeedsSeal(buffDef, party.player)
  elseif buffDef.isBlessing then
    buffChecksModule:PartyNeedsPaladinBlessing(buffDef, party, buffCtx)
  else
    buffChecksModule:PartyNeedsBuff(buffDef, party, buffCtx)
  end

  -- Check Spell CD
  if buffDef.hasCD and #buffDef.unitsNeedBuff > 0 then
    local startTime, duration = envModule.GetSpellCooldown(buffDef.highestRankSingleId)
    if startTime == nil or duration == nil then
      buffDef:ResetBuffTargets()
      buffCtx.someoneIsDead = false
    elseif duration ~= 0 then
      -- The buff spell is still not ready
      buffDef:ResetBuffTargets()
      startTime = startTime + duration

      -- Check again when the cooldown is up
      scanSchedulerModule:WakeAt(startTime)

      buffCtx.someoneIsDead = false
    end
  end
end

---@param spellName string
---@param units BomUnit[]
---@param groupIndex number|nil
---@param spell BomBuffDefinition
function module:GetGroupInRange(spellName, units, groupIndex, spell)
  local minDist
  local ret
  for _, member in pairs(units) do
    if member.group == groupIndex then
      if not (envModule.IsSpellInRange(spellName, member.unitId) == 1 or member.isDead) then
        if member.distance > 2000 then
          return nil
        end
      elseif (minDist == nil or member.distance < minDist)
          and not tContains(spell.skipList, member.name) then
        minDist = member.distance
        ret = member
      end
    end
  end

  return ret
end

---@param spellName string
---@param _party BomParty
---@param buffDef BomBuffDefinition
---@param playerUnit BomUnit Default if no party
function module:GetAnyPartyMemberInRange(spellName, buffDef, _party, playerUnit)
  local minDist
  local ret

  if not UnitInParty("player") then
    return playerUnit
  end

  for _, member in ipairs(buffDef.unitsNeedBuff) do
    if envModule.IsSpellInRange(spellName, member.unitId) == 1
        and not member.isDead
        and (minDist == nil or member.distance < minDist)
        and not tContains(buffDef.skipList, member.name) then
      minDist = member.distance
      ret = member
    end
    --if not (IsSpellInRange(spellName, member.unitGUID) == 1 or member.isDead) then
    --  if member.distance > 2000 then
    --    return nil
    --  end
    --elseif (minDist == nil or member.distance < minDist)
    --        and not tContains(spell.SkipList, member.name) then
    --  minDist = member.distance
    --  ret = member
    --end
  end

  return ret
end

---Return list of members of class in spell range
---@param spellName string
---@param party BomParty
---@param class string
---@param spell BomBuffDefinition
function module:GetClassInRange(spellName, party, class, spell)
  local minDist
  local ret

  ---@param member BomUnit
  for _, member in pairs(party.byUnitId) do
    if member.class == class then
      if member.isDead then
        return nil
      elseif envModule.IsSpellInRange(spellName, member.unitId) ~= 1 then
        if member.distance > 2000 then
          return nil
        end
      elseif (minDist == nil or member.distance < minDist)
          and not tContains(spell.skipList, member.name) then
        minDist = member.distance
        ret = member
      end
    end -- if class
  end

  return ret
end

---@param link string Clickable spell link with icon
---@param inactiveText string Spell name as text
---@param targetUnit BomUnit
---@return boolean True if spell cast is prevented by PvP guard, false if spell can be casted
function module:PreventPvpTagging(link, inactiveText, targetUnit)
  if BuffomatShared.PreventPVPTag then
    -- TODO: Move Player PVP check and instance check outside
    local _inInstance, instance_type = IsInInstance()
    if instance_type == "none"
        and not UnitIsPVP("player")
        and UnitIsPVP(targetUnit.name) then
      -- Text: [Spell Name] Player is PvP
      self.tasklist:Add(
        taskModule:Create(link, inactiveText)
        :PrefixText(_t("PreventPVPTagBlocked"))
        :Target(buffTargetModule:FromUnit(targetUnit))
        :IsInfo())
      return true
    end
  end
  return false
end

---Run checks to see if BOM should not be scanning buffs
---@param playerUnit BomUnit
---@return boolean, string {Active, WhyNotActive: string}
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

---Activate tracking spells
function module:ActivateSelectedTracking()
  --reset tracking
  BuffomatAddon.forceTracking = nil

  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    if buffDef.type == "tracking" then
      if buffDefModule:IsBuffEnabled(buffDef.buffId, nil) then
        if buffDef.requiresForm ~= nil then
          if playerStateModule.formId == buffDef.requiresForm
              and BuffomatAddon.forceTracking ~= buffDef.trackingIconId then
            BuffomatAddon.forceTracking = buffDef.trackingIconId
            --spellButtonsTabModule:UpdateSpellsTab("ForceUp1")
          end
        elseif buffChecksModule:IsTrackingActive(buffDef)
            and BuffomatCharacter.lastTrackingIconId ~= buffDef.trackingIconId then
          BuffomatCharacter.lastTrackingIconId = buffDef.trackingIconId
          --spellButtonsTabModule:UpdateSpellsTab("ForceUp2")
        end
      else
        if BuffomatCharacter.lastTrackingIconId == buffDef.trackingIconId
            and BuffomatCharacter.lastTrackingIconId ~= nil then
          BuffomatCharacter.lastTrackingIconId = nil
          --spellButtonsTabModule:UpdateSpellsTab("ForceUp3")
        end
      end -- if spell.enable
    end   -- if tracking
  end     -- for all spells

  if BuffomatAddon.forceTracking == nil then
    BuffomatAddon.forceTracking = BuffomatCharacter.lastTrackingIconId
  end
end

---@param playerUnit BomUnit
function module:GetActiveAuraAndSeal(playerUnit)
  --find activ aura / seal
  BuffomatAddon.activePaladinAura = nil
  BuffomatAddon.activePaladinSeal = nil

  ---@param buffDef BomBuffDefinition
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    local knownBuffOnPlayer = playerUnit.knownBuffs[buffDef.buffId]

    if knownBuffOnPlayer then
      if buffDef.type == "aura" then
        if (BuffomatAddon.activePaladinAura == nil and BuffomatAddon.lastAura == buffDef.buffId)
            or envModule.UnitIsUnit(knownBuffOnPlayer.source, "player")
        then
          if buffChecksModule:TimeCheck(knownBuffOnPlayer.expirationTime, knownBuffOnPlayer.duration) then
            BuffomatAddon.activePaladinAura = buffDef.buffId
          end
        end
      elseif buffDef.type == "seal" then
        if envModule.UnitIsUnit(knownBuffOnPlayer.source, "player") then
          --BOM:Print("seal check for " .. buffDef.buffId .. " expiration " .. knownBuffOnPlayer.expirationTime)
          if buffChecksModule:TimeCheck(knownBuffOnPlayer.expirationTime, knownBuffOnPlayer.duration) then
            BuffomatAddon.activePaladinSeal = buffDef.buffId
          end
        end
      end -- if is aura
    end   -- if player.buffs[config.id]
  end     -- for all spells
end

function module:CheckChangesAndUpdateSpelltab()
  -- Hunter tracks used to be "aura" buffs; a profile which saved one as LastAura would otherwise
  -- block aspects forever, because tracks no longer go through the aura code.
  local lastAuraDef = allBuffsModule.allBuffs and allBuffsModule.allBuffs[buffomatModule.currentProfile.LastAura]
  if lastAuraDef ~= nil and lastAuraDef.type ~= "aura" then
    buffomatModule.currentProfile.LastAura = nil
  end

  --reset aura/seal
  ---@param buffDef BomBuffDefinition
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    if buffDef.type == "aura" then
      if buffDefModule:IsBuffEnabled(buffDef.buffId, nil) then
        if BuffomatAddon.activePaladinAura == buffDef.buffId
            and buffomatModule.currentProfile.LastAura ~= buffDef.buffId then
          buffomatModule.currentProfile.LastAura = buffDef.buffId
          --spellButtonsTabModule:UpdateSpellsTab("ForceUp4")
        end
      else
        if buffomatModule.currentProfile.LastAura == buffDef.buffId
            and buffomatModule.currentProfile.LastAura ~= nil then
          buffomatModule.currentProfile.LastAura = nil
          --spellButtonsTabModule:UpdateSpellsTab("ForceUp5")
        end
      end -- if currentprofile.spell.enable
    elseif buffDef.type == "seal" then
      if buffDefModule:IsBuffEnabled(buffDef.buffId, nil) then
        if BuffomatAddon.activePaladinSeal == buffDef.buffId
            and buffomatModule.currentProfile.LastSeal ~= buffDef.buffId then
          buffomatModule.currentProfile.LastSeal = buffDef.buffId
          --spellButtonsTabModule:UpdateSpellsTab("ForceUp6")
        end
      else
        if buffomatModule.currentProfile.LastSeal == buffDef.buffId
            and buffomatModule.currentProfile.LastSeal ~= nil then
          buffomatModule.currentProfile.LastSeal = nil
          --spellButtonsTabModule:UpdateSpellsTab("ForceUp7")
        end
      end -- if currentprofile.spell.enable
    end   -- if is aura
  end
end

-- TODO: Only scan missing buffs on current roundRobinGroup while in raid
---@param party BomParty - the party
---@param buffCtx BomBuffScanContext
function module:UpdateMissingBuffs(party, buffCtx)
  -- Tracking is not a spell so it can be applied immediately
  self:ActivateSelectedTracking()

  -- Get the running aura and the running seal
  self:GetActiveAuraAndSeal(party.player)

  -- Check changes to auras and seals and update the spell tab
  self:CheckChangesAndUpdateSpelltab()

  -- =================
  -- who needs a buff?
  -- =================
  -- for each spell update spell potential targets
  buffCtx.someoneIsDead = false -- the flag that buffing cannot continue while someone is dead

  -- For each enabled buff check the targets
  for _, selectedBuff in ipairs(allBuffsModule.selectedBuffs) do
    self:UpdateMissingBuffs_EachBuff(party, selectedBuff, buffCtx)
  end

  module.saveSomeoneIsDead = buffCtx.someoneIsDead
end

---@param playerUnit BomUnit
function module:CancelBuffs(playerUnit)
  for _, spell in ipairs(BuffomatAddon.cancelBuffs or {}) do
    if buffomatModule.currentProfile
        and buffomatModule.currentProfile.CancelBuff[spell.buffId].Enable
        and not spell.onlyCombat
    then
      local player_buff = playerUnit.knownBuffs[spell.buffId]

      if player_buff then
        BuffomatAddon:Print(string.format(_t("message.CancelBuff"),
          spell:SingleLink(),
          UnitName(player_buff.source or "") or ""))
        self:CancelBuff(spell.singleFamily)
      end
    end
  end
end

---Whisper to the spell caster when the buff expired on yourself
function module:WhisperExpired(spell)
  if spell.wasPlayerActiv and not spell.playerActiv then
    spell.wasPlayerActiv = false

    local name = UnitName(spell.buffSource or "")

    if name then
      local msg = string.format(_t("message.BuffExpired"), spell.single)
      SendChatMessage(msg, "WHISPER", nil, name)

      BuffomatAddon:Print(string.format("Whisper to %s: %s", name, msg))
    end
  end
end

---@param name string Consumable name to show
---@param count number How many of that consumable is available
function module:FormatItemBuffInactiveText(name, count)
  if count == 0 then
    return string.format("%s (%s)", tostring(name), _t("task.hint.DontHaveItem"))
  end

  return string.format("%s (x%d)", name, count)
end

---@return string
function module:FormatItemBuffText(bag, slot, count)
  local itemInfo = envModule.GetContainerItemInfo(bag, slot)
  local picture = ""

  -- Iteminfo becomes nil when user throws away the consumable while the task is up
  if itemInfo ~= nil then
    picture = ngStringsModule:FormatTexture( --[[@as string]] itemInfo.iconFileID)
  end

  return string.format(" %s %s (x%d)", picture, itemInfo.hyperlink, count)
end

---On WoW: Forever the Legacy talent Reagent Economy waives vendor-sold class reagents.
---@param buffDef BomBuffDefinition
---@return boolean True when every reagent of the buff is waived
function module:IsReagentWaived(buffDef)
  if not envModule.isForever or not envModule.IsPlayerSpell(spellIdsModule.Forever_ReagentEconomy) then
    return false
  end
  for _, itemId in ipairs(buffDef.reagentRequired) do
    if not itemIdsModule.VendorReagents[itemId] then
      return false
    end
  end
  return true
end

---Reagents left for a group buff, shown after the task text: "x12", or "x0" when out.
---@param buffDef BomBuffDefinition
---@return string Empty when the buff needs no reagent
function module:FormatReagentCount(buffDef)
  if not buffDef.reagentRequired or self:IsReagentWaived(buffDef) then
    return ""
  end
  local _, _, _, count = buffChecksModule:HasItem(buffDef.reagentRequired, true)
  return "x" .. (count or 0)
end

---Add a paladin blessing
---@param buffDef BomBuffDefinition - spell to cast
---@param party BomParty - the party
---@param _buffCtx BomBuffScanContext
function module:AddBlessing(buffDef, party, _buffCtx)
  if buffDef.groupMana ~= nil
      and not BuffomatShared.NoGroupBuff
  then
    -- For each class name WARRIOR, PALADIN, PRIEST, SHAMAN... etc
    for _, eachClassName in ipairs(constModule.CLASSES) do
      if buffDef.groupsNeedBuff[eachClassName]
          and buffDef.groupsNeedBuff[eachClassName] >= BuffomatShared.MinBlessing
      then
        scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")
        local classInRange = self:GetClassInRange(
          buffDef.groupText, --[[@as BomParty]] buffDef.unitsNeedBuff, eachClassName, buffDef)

        if classInRange == nil then
          classInRange = self:GetClassInRange(buffDef.groupText, party, eachClassName, buffDef)
        end

        if classInRange ~= nil
            and (not buffDef.groupsHaveDead[eachClassName]
              or not BuffomatShared.DeathBlock)
        then
          -- Group buff (Blessing)
          -- Text: Group 5 [Spell Name] x Reagents
          self.tasklist:Add(
            taskModule:Create(buffDef.groupLink or buffDef.groupText, buffDef.singleText)
            :PrefixText(_t("TASK_BLESS_GROUP"))
            :ExtraText(self:FormatReagentCount(buffDef))
            :Target(groupBuffTargetModule:New(eachClassName))
            :InRange(true)
            :Action(actionCastModule:New(
              buffDef.groupMana, buffDef.highestRankGroupId, buffDef.groupLink,
              classInRange, buffDef, false))
            :LinkToBuffDef(buffDef)
          )
        else
          -- Group buff (Blessing) just info text
          -- Text: Group 5 [Spell Name] x Reagents
          self.tasklist:Add(
            taskModule:Create(buffDef.groupLink or buffDef.groupText, buffDef.singleText)
            :PrefixText(_t("TASK_BLESS_GROUP"))
            :ExtraText(self:FormatReagentCount(buffDef))
            :Target(groupBuffTargetModule:New(eachClassName))
            :IsInfo()
            :LinkToBuffDef(buffDef)
          )
        end
      end -- if needgroup >= minblessing
    end   -- for all classes
  end

  -- SINGLE BUFF (Ignored because better buff is found)
  for _k, unitHasBetter in ipairs(buffDef.unitsHaveBetterBuff) do
    self.tasklist:LowPrioComment(string.format(_t("tasklist.IgnoredBuffOn"),
      unitHasBetter.name, buffDef.singleText))
    -- Leave message that the target has a better or ignored buff
  end

  -- SINGLE BUFF
  for _j, needsBuff in ipairs(buffDef.unitsNeedBuff) do
    if not needsBuff.isDead
        and buffDef.singleMana ~= nil
        and (BuffomatShared.NoGroupBuff
          or buffDef.groupMana == nil
          or needsBuff.class == "pet"
          or buffDef.groupsNeedBuff[needsBuff.class] == nil
          or buffDef.groupsNeedBuff[needsBuff.class] < BuffomatShared.MinBlessing) then
      if not needsBuff.isPlayer then
        scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")
      end

      local targetIcon = "" -- marks players with a forced or assigned target
      local blessingState = buffDefModule:GetProfileBlessingState(nil)
      if blessingState[needsBuff.name] ~= nil then
        targetIcon = string.format(constModule.PICTURE_FORMAT, texturesModule.ICON_TARGET_ON)
      end

      local test_in_range = envModule.IsSpellInRange(buffDef.singleText, needsBuff.unitId) == 1
          and not tContains(buffDef.skipList, needsBuff.name)
      if self:PreventPvpTagging(buffDef:SingleLink(), buffDef.singleText, needsBuff) then
        -- Nothing, prevent poison function has already added the text
      elseif test_in_range then
        -- Single buff on group member
        -- Text: Target [Spell Name]
        self.tasklist:Add(
          taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
          :PrefixText(_t("TASK_BLESS"))
          :Target(buffTargetModule:FromUnit(needsBuff))
          :ExtraText(targetIcon)
          :InRange(true)
          :Action(actionCastModule:New(
            buffDef.singleMana, buffDef.highestRankSingleId, buffDef:SingleLink(),
            needsBuff, buffDef, false))
          :LinkToBuffDef(buffDef)
        )
      else
        -- Single buff on group member (inactive just text)
        -- Text: Target "SpellName"
        self.tasklist:Add(
          taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
          :PrefixText(_t("TASK_BLESS"))
          :Target(buffTargetModule:FromUnit(needsBuff))
          :ExtraText(targetIcon)
          :IsInfo()
          :LinkToBuffDef(buffDef)
        )
      end -- if in range
    end   -- if not dead
  end     -- for all unitsNeedBuff
end

---Search for a 5man party in the current raid or party, which is in range and needs the group buff.
---This is pre-WotLK style buffing when group buff covered only 5-man parties in a raid.
---@param groupIndex number|nil
---@param buffDef BomBuffDefinition
---@param party BomParty The party
---@param minBuff number How many missing buffs mandate the group buff
---@param _buffCtx BomBuffScanContext
function module:FindTargetForGroupBuff(groupIndex, buffDef, party, minBuff, _buffCtx)
  if buffDef.groupsNeedBuff[groupIndex]
      and buffDef.groupsNeedBuff[groupIndex] >= minBuff
  then
    scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")
    local groupInRange = self:GetGroupInRange(buffDef.groupText, buffDef.unitsNeedBuff, groupIndex, buffDef)

    --if groupInRange == nil then
    --  groupInRange = self:GetGroupInRange(buffDef.groupText, party, groupIndex, buffDef)
    --end

    --if groupInRange ~= nil and (not spell.GroupsHaveDead[groupIndex] or not BuffomatShared.DeathBlock) then
    if (groupIndex and not buffDef.groupsHaveDead[groupIndex])
        or not BuffomatShared.DeathBlock then
      -- Text: Group 5 [Spell Name]
      self.tasklist:Add(
        taskModule:Create(buffDef.groupLink or buffDef.groupText, buffDef.singleText)
        :PrefixText(_t("task.type.GroupBuff"))
        :ExtraText(self:FormatReagentCount(buffDef))
        :Target(groupBuffTargetModule:New(groupIndex))
        :InRange(true)
        :Action(actionCastModule:New(
          buffDef.groupMana, buffDef.highestRankGroupId, buffDef.groupLink,
          groupInRange or party.player, buffDef, false))
        :LinkToBuffDef(buffDef)
      )
    end -- if group not nil
  end
end

---@param buffDef BomBuffDefinition The spell to cast
---@param party BomParty The party
---@param minBuff number Option for minimum players with missing buffs to choose group buff
---@param buffCtx BomBuffScanContext
function module:AddBuff_GroupBuff(buffDef, party, minBuff, buffCtx)
  if envModule.groupBuffsRaidWide then
    -- WotLK and Forever: one group buff covers the whole raid; scan it as one
    --inRange = self:FindAnyPartyTargetForGroupBuff(buffDef, party, minBuff, inRange)
    -- Text: Group 5 [Spell Name]
    self.tasklist:Add(
      taskModule:Create(buffDef.groupLink or buffDef.groupText, buffDef.singleText)
      :PrefixText(_t("task.type.GroupBuff"))
      :ExtraText(self:FormatReagentCount(buffDef))
      :Target(groupBuffTargetModule:New(0))
      :InRange(true)
      -- WotLK buff self for group buffs
      :Action(actionCastModule:New(
        buffDef.groupMana, buffDef.highestRankGroupId, buffDef.groupLink,
        party.player, buffDef, false))
      :LinkToBuffDef(buffDef)
    )
  else
    -- For non-WotLK: Scan 5man groups in current party
    for groupIndex = 1, 8 do
      self:FindTargetForGroupBuff(groupIndex, buffDef, party, minBuff, buffCtx)
    end -- for all 8 groups
  end
end

---@param buffDef BomBuffDefinition The spell to cast
---@param minBuff number Option for minimum players with missing buffs to choose group buff
---@param _buffCtx BomBuffScanContext
function module:AddBuff_SingleBuff(buffDef, minBuff, _buffCtx)
  for _i, needBuff in pairs(buffDef.unitsNeedBuff) do
    if not needBuff.isDead
        and buffDef.singleMana ~= nil
        and (BuffomatShared.NoGroupBuff
          or buffDef.groupMana == nil
          or needBuff.group == 9
          or buffDef.groupsNeedBuff[needBuff.group] == nil
          or buffDef.groupsNeedBuff[needBuff.group] < minBuff)
    then
      if not needBuff.isPlayer then
        scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")
      end

      local targetIcon = "" -- marks players with a forced or assigned target
      local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)
      if not profileBuff then
        BuffomatAddon:Debug("No profile buff for " .. buffDef.buffId)
        return
      end

      if (profileBuff).ForcedTarget[needBuff.name] then
        targetIcon = string.format(constModule.PICTURE_FORMAT, texturesModule.ICON_TARGET_ON)
      end

      local unitIsInRange = (envModule.IsSpellInRange(buffDef.singleText, needBuff.unitId) == 1)
          and not tContains(buffDef.skipList, needBuff.name)

      if self:PreventPvpTagging(buffDef:SingleLink(), buffDef.singleText, needBuff) then
        -- Nothing, prevent poison function has already added the text
      elseif unitIsInRange then
        -- Text: Target [Spell Name]
        self.tasklist:Add(
          taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
          :PrefixText(_t("task.type.RegularBuff"))
          :Target(buffTargetModule:FromUnit(needBuff))
          :ExtraText(targetIcon)
          :InRange(true)
          :Action(actionCastModule:New(
            buffDef.singleMana, buffDef.highestRankSingleId, buffDef:SingleLink(),
            needBuff, buffDef, false))
          :LinkToBuffDef(buffDef)
        )
      else
        -- Text: Target "SpellName"
        self.tasklist:Add(
          taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
          :PrefixText(buffomatModule:Color(constModule.TASKCOLOR_BLEAK_RED, _t("task.error.range"))
            .. " " .. _t("task.type.RegularBuff"))
          :Target(buffTargetModule:FromUnit(needBuff))
          :ExtraText(targetIcon)
          :IsInfo()
          :LinkToBuffDef(buffDef)
        )
      end
    end
  end -- for all spell.needmember
end

---Add a generic buff of some sorts, or a group buff
---@param buffDef BomBuffDefinition The spell to cast
---@param party BomParty The party
---@param buffCtx BomBuffScanContext
function module:AddBuff(buffDef, party, buffCtx)
  local minBuff = BuffomatShared.MinBuff or 3

  -- Check if any group qualifies for group buffing
  local shouldUseGroupBuff = false
  if buffDef.groupMana ~= nil and not BuffomatShared.NoGroupBuff then
    if envModule.groupBuffsRaidWide then
      -- WotLK and Forever: a group buff covers the whole raid, so check the total
      shouldUseGroupBuff = #buffDef.unitsNeedBuff >= minBuff
    else
      -- Pre-WotLK: Group buff works per 5-man group, check each group
      for groupIndex = 1, 8 do
        if buffDef.groupsNeedBuff[groupIndex]
            and buffDef.groupsNeedBuff[groupIndex] >= minBuff then
          shouldUseGroupBuff = true
          break
        end
      end
    end
  end

  if shouldUseGroupBuff then
    -- Add GROUP BUFF
    -- if group buff spell costs mana
    self:AddBuff_GroupBuff(buffDef, party, minBuff, buffCtx)
  else
    -- Add SINGLE BUFF
    self:AddBuff_SingleBuff(buffDef, minBuff, buffCtx)
  end
end

---Adds a display text for a weapon buff
---@param spell BomBuffDefinition the spell to cast
---@param _playerUnit BomUnit the player
---@param _buffCtx BomBuffScanContext
function module:AddResurrection(spell, _playerUnit, _buffCtx)
  local clearskip = true

  for _, member in ipairs(spell.unitsNeedBuff) do
    if not tContains(spell.skipList, member.name) then
      clearskip = false
      break
    end
  end

  if clearskip then
    wipe(spell.skipList)
  end

  --Prefer resurrection classes first
  --TODO: This also modifies all subsequent operations on this table preferring those classes first
  table.sort(spell.unitsNeedBuff, function(a, b)
    local aResser = tContains(allBuffsModule.RESURRECT_CLASSES, a.class)
    local bResser = tContains(allBuffsModule.RESURRECT_CLASSES, b.class)
    if aResser then
      return not bResser
    end
    return false
  end)

  for _k, unitNeedsBuff in ipairs(spell.unitsNeedBuff) do
    if not tContains(spell.skipList, unitNeedsBuff.name) then
      scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")

      local prio = taskModule.PRIO_RESURRECTION
      if tContains(allBuffsModule.RESURRECT_CLASSES, unitNeedsBuff.class) then
        prio = taskModule.PRIO_RESURRECTION_FIRST
      end

      -- Is the body in range?
      local targetIsInRange = (envModule.IsSpellInRange(spell.singleText, unitNeedsBuff.unitId) == 1)
          and not tContains(spell.skipList, unitNeedsBuff.name)
      local task = taskModule:Create(spell:SingleLink(), spell.singleText)
          :PrefixText(_t("task.type.Resurrect"))
          :Target(buffTargetModule:FromUnit(unitNeedsBuff))
          :Prio(prio)
          :LinkToBuffDef(spell)
      if targetIsInRange then
        -- Text: Target [Spell Name]
        self.tasklist:Add(task:InRange(true))
      else
        -- Text: Range Target "SpellName"
        self.tasklist:Add(task:IsInfo())
      end

      -- If in range, we can res?
      -- Should we try and resurrect ghosts when their corpse is not targetable?
      if targetIsInRange or (BuffomatShared.ResGhost and unitNeedsBuff.isGhost) then
        -- Prevent resurrecting PvP players in the world?
        task:Action(actionCastModule:New(
          spell.singleMana, spell.highestRankSingleId, spell:SingleLink(),
          unitNeedsBuff, spell, false))
      end
    end
  end
end

---Adds a display text for a self buff or tracking or seal/weapon self-enchant
---@param buffDef BomBuffDefinition - the spell to cast
---@param playerMember BomUnit - the player
function module:AddSelfbuff(buffDef, playerMember)
  if buffDef.requireWarlockPet then
    if not UnitExists("pet") then
      return -- No pet - buff can not be cast
    end
    local _ucTypeName, ucType = UnitCreatureType("pet")
    if ucType ~= 3 then
      return -- Pet is not a demon - buff can not be cast
    end
  end

  local extraText = _t("task.target.SelfOnly")
  if buffDef.type == "weapon" or buffDef.type == "seal" then
    extraText = _t("task.type.Enchantment")
  end
  local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
      :PrefixText(_t("TASK_CAST"))
      :ExtraText(extraText)
      :Target(buffTargetModule:FromSelf(playerMember))
      :LinkToBuffDef(buffDef)

  if (not buffDef.requiresOutdoors or IsOutdoors())
      and not tContains(buffDef.skipList, playerMember.name) then
    -- Text: Target [Spell Name]
    self.tasklist:Add(
      task:Action(actionCastModule:New(
        buffDef.singleMana, buffDef.highestRankSingleId, buffDef:SingleLink(),
        playerMember, buffDef, false)))
  else
    -- Text: Target "SpellName"
    self.tasklist:Add(task:IsInfo())
  end
end

---Adds a summon spell to the tasks
---@param buffDef BomBuffDefinition - the spell to cast
---@param playerMember BomUnit
function module:AddSummonSpell(buffDef, playerMember)
  if buffDef.sacrificeAuraIds then
    for _, id in ipairs(buffDef.sacrificeAuraIds) do
      if playerMember.allBuffs[id] then
        return
      end
    end -- for each sacrifice aura id
  end

  local add = false

  if not UnitExists("pet") then
    -- No pet? Need summon
    add = true
  else
    -- Have pet? Check pet type
    local _ucTypeName, ucType = UnitCreatureType("pet")
    local _ucFamilyName, ucFamily = UnitCreatureFamily("pet")

    if ucType ~= buffDef.creatureType or ucFamily ~= buffDef.creatureFamily then
      add = true
    end
  end

  if add then
    -- Text: Summon [Spell Name]
    local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
        :PrefixText(_t("TASK_SUMMON"))
        :Target(buffTargetModule:FromSelf(playerMember))
        :Action(actionCastModule:New(
          buffDef.singleMana, buffDef.highestRankSingleId, buffDef:SingleLink(),
          playerMember, buffDef, false))
        :LinkToBuffDef(buffDef)
    self.tasklist:Add(task)
  end
end

---@param buffDef BomBuffDefinition - the spell to cast
---@param count number
---@param playerUnit BomUnit the player
function module:AddConsumableSelfbuff_NoItem(buffDef, count, playerUnit)
  -- Text: "ConsumableName" x Count
  local task = taskModule:Create(
        self:FormatItemBuffInactiveText(buffDef.consumeGroupTitle or buffDef.singleText, count),
        nil)
      :PrefixText(_t("task.type.Consume"))
      :Target(buffTargetModule:FromSelf(playerUnit))
      :Prio(taskModule.PRIO_CONSUMABLE)
      :IsInfo()
      :LinkToBuffDef(buffDef)
  self.tasklist:Add(task)
end

---@param buffDef BomBuffDefinition - the spell to cast
---@param bestItemIdAvailable WowItemId From the list of compatible consumables, return best available item
---@param bag number
---@param slot number
---@param count number
---@param _playerUnit BomUnit the player
---@param target string
function module:AddConsumableSelfbuff_HaveItemReady(buffDef, bestItemIdAvailable, bag, slot, count, _playerUnit,
                                                            target)
  local taskText = _t("task.type.Consume")
  if buffDef.petBuff then
    taskText = _t("task.type.tbcHunterPetBuff")
  end

  local task = taskModule:Create(self:FormatItemBuffText(bag, slot, count or 0), nil)
      :PrefixText(taskText)
      :LinkToBuffDef(buffDef)
  --:Target(buffTargetModule:FromSelf(playerUnit))

  if BuffomatShared.DontUseConsumables
      and not IsModifierKeyDown() then
    -- Text: [Icon] [Consumable Name] x Count
    self.tasklist:Add(task:ExtraText(_t("task.hint.HoldShiftConsumable"))
      :IsInfo())
  else
    if bag ~= nil and slot ~= nil then
      local action = actionUseModule:New(buffDef, target, bag, slot, nil, bestItemIdAvailable)

      -- Text: [Icon] [Consumable Name] x Count
      self.tasklist:Add(task:Action(action):InRange(true))
    else
      BuffomatAddon:Debug(string.format("Taskscan: bag %s slot %s", tostring(bag), tostring(slot)))
    end
  end

  BuffomatAddon.scanModifierKeyDown = BuffomatShared.DontUseConsumables
end

---Adds a display text for a weapon buff
---@param buffDef BomBuffDefinition - the spell to cast
---@param playerUnit BomUnit the player
---@param target string Insert this text into macro where [@player] target text would go
---@param _buffCtx BomBuffScanContext
function module:AddConsumableSelfbuff(buffDef, playerUnit, target, _buffCtx)
  -- Setting to choose best or worst. Worst useful for leveling to eat old stuff first.
  local itemsProvidingBuff = buffDef.itemsReverse
  if not BuffomatShared.BestAvailableConsume then
    itemsProvidingBuff = buffDef.items
  end

  local haveItemOffCD, bag, slot, count, bestItemIdAvailable = buffChecksModule:HasItem(itemsProvidingBuff or {}, true)

  if haveItemOffCD then
    self:AddConsumableSelfbuff_HaveItemReady(
      buffDef, bestItemIdAvailable,
      bag, slot, count,
      playerUnit, target)
  else
    self:AddConsumableSelfbuff_NoItem(buffDef, count or 0, playerUnit)
  end
end

---@param buffDef BomBuffDefinition
---@param bag number
---@param slot number
---@param count number
---@param playerUnit BomUnit
---@param texture WowIconId
---@param itemLink string
function module:AddConsumableWeaponBuff_HaveItem_Mainhand(buffDef, bag, slot, count, playerUnit, texture,
                                                                  itemLink)
  local mainhandMessage = ngStringsModule:FormatTexture( --[[@as string]] texture) .. itemLink .. "x" .. count

  if BuffomatShared.DontUseConsumables
      and not IsModifierKeyDown() then
    -- Text: [Icon] [Consumable Name] x Count (Main hand)
    self.tasklist:Add(
      taskModule:Create(mainhandMessage, nil)
      :ExtraText("(" .. _t("tooltip.mainhand") .. ") " .. _t("task.hint.HoldShiftConsumable"))
      :Target(buffTargetModule:FromSelf(playerUnit))
      :IsInfo()
      :LinkToBuffDef(buffDef)
    )
  else
    -- Text: [Icon] [Consumable Name] x Count (Main hand)
    self.tasklist:Add(
      taskModule:Create(mainhandMessage, nil)
      :ExtraText("(" .. _t("tooltip.mainhand") .. ")")
      :Target(buffTargetModule:FromSelf(playerUnit))
      :Prio(taskModule.PRIO_ENCHANTMENT)
      :Action(actionMacroModule:New(
        "/use " .. bag .. " " .. slot .. "\n/use 16",
        buffDef:SingleLink() .. " " .. _t("tooltip.mainhand"))) -- mainhand
      :LinkToBuffDef(buffDef)
    )
  end
end

---@param buffDef BomBuffDefinition
---@param bag number
---@param slot number
---@param count number
---@param playerUnit BomUnit
---@param texture WowIconId
---@param itemLink string
function module:AddConsumableWeaponBuff_HaveItem_Offhand(buffDef, bag, slot, count, playerUnit, texture,
                                                                 itemLink)
  local offhandMessage = ngStringsModule:FormatTexture( --[[@as string]] texture) .. itemLink .. "x" .. count

  if BuffomatShared.DontUseConsumables
      and not IsModifierKeyDown() then
    -- Text: [Icon] [Consumable Name] x Count (Off-hand)
    local task = taskModule:Create(offhandMessage, nil)
        :ExtraText("(" .. _t("tooltip.offhand") .. ") " .. _t("task.hint.HoldShiftConsumable"))
        :Target(buffTargetModule:FromSelf(playerUnit))
        :IsInfo()
        :LinkToBuffDef(buffDef)
    self.tasklist:Add(task)
  else
    -- Text: [Icon] [Consumable Name] x Count (Off-hand)
    local task = taskModule:Create(offhandMessage, nil)
        :ExtraText("(" .. _t("tooltip.offhand") .. ") ")
        :Target(buffTargetModule:FromSelf(playerUnit))
        :Prio(taskModule.PRIO_ENCHANTMENT)
        :Action(actionMacroModule:New(
          "/use " .. bag .. " " .. slot .. "\n/use 17",
          buffDef:SingleLink() .. " " .. _t("tooltip.offhand"))) -- offhand
        :LinkToBuffDef(buffDef)
    self.tasklist:Add(task)
  end
end

---@return boolean Whether class has a mainhand weapon and can enchant 1 or 2hand weapon, and is not a rogue in case of 2h
function module:CharacterCanEnchantMainhand()
  local mainhandId = playerStateModule.inventory[playerStateModule.SLOT_MAINHAND]
  if mainhandId == nil then
    return false
  end
  local info = BuffomatAddon.GetItemInfo(mainhandId)
  if info == nil then
    return false
  end
  local i = (info)
  return i.itemClassID == ( --[[Weapon]] 2) and i.itemSubClassID ~= ( --[[Fishing Poles]] 20)
end

---@return boolean Whether class has an offhand weapon and can enchant it
function module:CharacterCanEnchantOffhand()
  return playerStateModule.inventory[playerStateModule.SLOT_OFFHAND] ~= nil
end

---@param buffDef BomBuffDefinition
---@param bag number
---@param slot number
---@param count number
---@param playerUnit BomUnit
function module:AddConsumableWeaponBuff_HaveItem(buffDef, bag, slot, count, playerUnit)
  -- Have item, display the cast message and setup the cast button
  local itemInfo = envModule.GetContainerItemInfo(bag, slot)
  local needMainhand, needOffhand = buffChecksModule:WeaponHandsNeedingBuff(buffDef, playerUnit)

  if not self:CharacterCanEnchantMainhand() and needMainhand then
    self.tasklist:Comment(_t("task.error.missingMainhandWeapon"))
    return
  end
  if not self:CharacterCanEnchantOffhand() and needOffhand then
    self.tasklist:Comment(_t("task.error.missingOffhandWeapon"))
    return
  end

  if needOffhand then
    self:AddConsumableWeaponBuff_HaveItem_Offhand(buffDef, bag, slot, count, playerUnit,
      itemInfo.iconFileID, itemInfo.hyperlink)
  end

  if needMainhand then
    self:AddConsumableWeaponBuff_HaveItem_Mainhand(buffDef, bag, slot, count, playerUnit,
      itemInfo.iconFileID, itemInfo.hyperlink)
  end
  BuffomatAddon.scanModifierKeyDown = BuffomatShared.DontUseConsumables
end

---@param buffDef BomBuffDefinition
---@param count number
---@param playerUnit BomUnit
function module:AddConsumableWeaponBuff_DontHaveItem(buffDef, count, playerUnit)
  -- Don't have item but display the intent
  -- Text: [Icon] [Consumable Name] x Count
  if buffDef.singleText then
    -- spell.single can be nil on addon load
    local task = taskModule:Create(buffDef.singleText .. " x" .. count, nil)
        :PrefixText(_t("task.type.Enchantment"))
        :ExtraText(_t("task.type.MissingConsumable"))
        :Target(buffTargetModule:FromSelf(playerUnit))
        :IsInfo()
        :LinkToBuffDef(buffDef)
    self.tasklist:Add(task)
  end
end

---Adds a display text for a weapon buff created by a consumable item
---@param buffDef BomBuffDefinition the spell to cast
---@param playerUnit BomUnit the player
---@param _buffCtx BomBuffScanContext
function module:AddConsumableWeaponBuff(buffDef, playerUnit, _buffCtx)
  -- count - reagent count remaining for the spell
  local haveItem, bag, slot, count = buffChecksModule:HasItem(buffDef.items or {}, true)
  count = count or 0

  if haveItem then
    self:AddConsumableWeaponBuff_HaveItem(buffDef,
      bag, slot, count,
      playerUnit)
  else
    self:AddConsumableWeaponBuff_DontHaveItem(buffDef, count, playerUnit)
  end
end

local function getMainhandEnchantTaskText(isDownrank)
  if isDownrank then
    return _t("tooltip.mainhand") .. ": " .. _t("shaman.flametongueDownranked")
  end
  return _t("tooltip.mainhand")
end

---Adds a display text for a weapon buff created by a spell (shamans and paladins)
---@param buffDef BomBuffDefinition - the spell to cast
---@param playerUnit BomUnit - the player
---@param _buffCtx BomBuffScanContext
function module:AddWeaponEnchant(buffDef, playerUnit, _buffCtx)
  local playerClass = envModule.playerClass

  local isTBCShaman = envModule.haveTBC and playerClass == "SHAMAN"
  local isDualwieldShaman = envModule.IsSpellKnown(674) and playerClass == "SHAMAN"
  if not isTBCShaman and not isDualwieldShaman then
    return
  end

  -- Special handling for TBC shamans, you cannot specify slot for enchants,
  -- and it goes into main then offhand
  local hasMainhand = playerStateModule.hasMainhandEnchant

  local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)

  -- OFFHAND FIRST
  if profileBuff
      and hasMainhand
      and (profileBuff).OffHandEnable
      and playerUnit.offhandEnchantment == nil then
    -- Text: [Spell Name] (Off-hand)
    local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
        :ExtraText(_t("tooltip.offhand"))
        :Target(buffTargetModule:FromSelf(playerUnit))
        :Prio(taskModule.PRIO_ENCHANTMENT)
        :Action(actionCastModule:New(
          buffDef.singleMana, buffDef.highestRankSingleId, buffDef:SingleLink(),
          playerUnit, buffDef, false))
        :LinkToBuffDef(buffDef)
    self.tasklist:Add(task)
  end

  -- MAINHAND AFTER OFFHAND
  if profileBuff
      and (profileBuff).MainHandEnable
      and playerUnit.mainhandEnchantment == nil then
    -- Special case is ruled by the option `ShamanFlametongueRanked`
    -- Flametongue enchant for spellhancement shamans only!
    local isDownrank = buffDef.buffId == spellIdsModule.Shaman_Flametongue6
        and BuffomatShared.ShamanFlametongueRanked

    local taskText = getMainhandEnchantTaskText(isDownrank)

    -- Text: [Spell Name] (Main hand)
    local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
        :ExtraText(taskText)
        :Target(buffTargetModule:FromSelf(playerUnit))
        :Prio(taskModule.PRIO_ENCHANTMENT)
        :Action(actionCastModule:New(
          buffDef.singleMana, buffDef.highestRankSingleId, buffDef:SingleLink(),
          playerUnit, buffDef, isDownrank))
        :LinkToBuffDef(buffDef)
    self.tasklist:Add(task)
  end
end

---Check if player has rep items equipped where they should not have them
---@param _playerMember BomUnit
function module:CheckReputationItems(_playerMember)
  local instanceID = playerStateModule.instanceId
  local itemTrinket1 = playerStateModule.inventory[playerStateModule.SLOT_TRINKET1]
  local itemTrinket2 = playerStateModule.inventory[playerStateModule.SLOT_TRINKET2]

  if BuffomatShared.ReputationTrinket then
    -- settings to remind to remove AD trinket != instance compatible with AD Commission
    --if playerMember.hasReputationTrinket ~= tContains(BOM.ReputationTrinket.zoneId, instanceID) then
    local hasReputationTrinket = tContains(BuffomatAddon.reputationTrinketZones.itemIds, itemTrinket1) or
        tContains(BuffomatAddon.reputationTrinketZones.itemIds, itemTrinket2)
    if hasReputationTrinket and not tContains(BuffomatAddon.reputationTrinketZones.zoneId, instanceID) then
      -- Text: Unequip [Argent Dawn Commission]
      self.tasklist:Comment(_t("task.type.Unequip") .. " " .. _t("reminder.reputationTrinket"))
    end
  end

  if BuffomatShared.Carrot then
    local hasCarrot = tContains(BuffomatAddon.ridingSpeedZones.itemIds, itemTrinket1) or
        tContains(BuffomatAddon.ridingSpeedZones.itemIds, itemTrinket2)
    if hasCarrot and not tContains(BuffomatAddon.ridingSpeedZones.zoneId, instanceID) then
      -- Text: Unequip [Carrot on a Stick]
      self.tasklist:Comment(_t("task.type.Unequip") .. " " .. _t("reminder.ridingSpeedTrinket"))
    end
  end
end

---Check player weapons and report if they have the "Warn about missing enchants" option enabled
---@param _playerUnit BomUnit
function module:CheckMissingWeaponEnchantments(_playerUnit)
  local state = playerStateModule
  if BuffomatShared.MainHand and not state.hasMainhandEnchant and state.inventory[state.SLOT_MAINHAND] then
    self.tasklist:Comment(_t("MSG_MAINHAND_ENCHANT_MISSING"))
  end

  if BuffomatShared.SecondaryHand and not state.hasOffhandEnchant and state.inventory[state.SLOT_OFFHAND] then
    self.tasklist:Comment(_t("MSG_OFFHAND_ENCHANT_MISSING"))
  end
end

---Add a task to use or open a bag item.
---@param item BomBagItem
---@param target string? Name of the player the item is used on
---@param playerUnit BomUnit
function module:AddUseItemTask(item, target, playerUnit)
  local extraMsg = "" -- tell user they need to hold Alt or something
  if BuffomatShared.DontUseConsumables and not IsModifierKeyDown() then
    extraMsg = _t("task.hint.HoldShiftConsumable")
  end

  local actionText = ngStringsModule:FormatTexture(item.texture)
      .. item.link
      .. (target and (" @" .. target) or "")
  -- Text: [Icon] [Item Link] @Target
  local task = taskModule:Create(actionText, nil)
      :ExtraText("(" .. _t("task.UseOrOpen") .. ") " .. extraMsg)
      :Prio(taskModule.PRIO_OPEN_CONTAINER)
      :Target(buffTargetModule:FromSelf(playerUnit))

  if BuffomatShared.DontUseConsumables and not IsModifierKeyDown() then
    -- Can't use or cast
    self.tasklist:Add(task:IsInfo())
  else
    -- Will use/cast
    self.tasklist:Add(task
      :Action(actionUseModule:New(nil, target, item.bag, item.slot, item.link))
      :InRange(true))
  end
  BuffomatAddon.scanModifierKeyDown = BuffomatShared.DontUseConsumables
end

---Tasks for usable items (soulstones) which are off cooldown, and for containers to open.
---@param playerUnit BomUnit
---@param _buffCtx BomBuffScanContext
function module:CheckItemsAndContainers(playerUnit, _buffCtx)
  for _, itemIds in ipairs(BuffomatAddon.itemList) do
    for _, itemId in ipairs(itemIds) do
      local item = bagScanModule:Find(itemId)
      if item and item.link and bagScanModule:IsReady(item) then
        -- Use it on whoever had its buff from the player before
        local target = partyModule.itemListTarget[allBuffsModule.itemListSpellLookup[itemId]]
        self:AddUseItemTask(item, target, playerUnit)
      end
    end
  end

  for _, item in ipairs(bagScanModule.openable) do
    self:AddUseItemTask(item, nil, playerUnit)
  end
end

---A spell costs more mana than the player has: remember the cheapest such cost, so the
---mana event that makes it affordable starts a pass.
---@param cost number?
function module:WaitForMana(cost)
  local state = playerStateModule
  if cost and cost > state.mana and cost < state.maxMana
      and (state.manaWakeLimit == nil or cost < state.manaWakeLimit) then
    state.manaWakeLimit = cost
  end
end

---@param buffDef BomBuffDefinition
---@param party BomParty
---@param buffCtx BomBuffScanContext
function module:CreateOneBuffTask(buffDef, party, buffCtx)
  if #buffDef.unitsNeedBuff > 0
      and not buffDef.isInfo
      and not buffDef.isConsumable
  then
    self:WaitForMana(buffDef.singleMana)
    self:WaitForMana(buffDef.groupMana)
  end

  if buffDef.type == "summon" then
    self:AddSummonSpell(buffDef, party.player)
  elseif buffDef.type == "weapon" then
    if #buffDef.unitsNeedBuff > 0 then
      if buffDef.isConsumable then
        self:AddConsumableWeaponBuff(buffDef, party.player, buffCtx)
      else
        self:AddWeaponEnchant(buffDef, party.player, buffCtx)
      end
    end
  elseif buffDef.isConsumable then
    if #buffDef.unitsNeedBuff > 0 then
      self:AddConsumableSelfbuff(buffDef, party.player, buffDef.consumableTarget, buffCtx)
    end
  elseif buffDef.reminderCheck then
    if buffDef.reminderText then
      -- Text: [Spell Link] what to do; nothing to cast
      self.tasklist:Add(taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
        :ExtraText(buffDef.reminderText)
        :Target(buffTargetModule:FromSelf(party.player))
        :IsInfo()
        :LinkToBuffDef(buffDef))
    end
  elseif buffDef.isInfo then
    if #buffDef.unitsNeedBuff then
      for _m, unitNeedsBuff in ipairs(buffDef.unitsNeedBuff) do
        -- Text: [Player Link] [Spell Link]
        local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
            :Target(buffTargetModule:FromUnit(unitNeedsBuff))
            :IsInfo()
            :LinkToBuffDef(buffDef)
        self.tasklist:Add(task)
      end
    end
  elseif buffDef.type == "tracking" then
    -- TODO: Move this to its own periodic timer
    if #buffDef.unitsNeedBuff > 0 then
      if playerStateModule.casting == nil then
        self:SetTracking(buffDef, true)
      else
        -- Text: "Player" "Spell Name"
        local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
            :PrefixText(_t("TASK_ACTIVATE"))
            :ExtraText(_t("task.type.Tracking"))
            :Target(buffTargetModule:FromSelf(party.player))
            :LinkToBuffDef(buffDef)
        self.tasklist:Add(task)
      end
    end
  elseif (buffDef.isOwn
        or buffDef.type == "tracking"
        or buffDef.type == "aura"
        or buffDef.type == "seal")
  then
    if buffDef.shapeshiftFormId and playerStateModule.formId == buffDef.shapeshiftFormId then
      -- if spell is shapeshift, and is already active, skip it
    elseif #buffDef.unitsNeedBuff > 0 then
      -- self buffs are not pvp-guarded
      self:AddSelfbuff(buffDef, party.player)
    end
  elseif buffDef.type == "resurrection" then
    self:AddResurrection(buffDef, party.player, buffCtx)
  elseif buffDef.isBlessing then
    self:AddBlessing(buffDef, party, buffCtx)
  else
    self:AddBuff(buffDef, party, buffCtx)
  end
end

---@param party BomParty
---@param buffCtx BomBuffScanContext
function module:CreateBuffTasks(party, buffCtx)
  -- Go through all available and selected player buffs
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    local profileBuff = profileModule:GetProfileBuff(buffDef.buffId, nil)

    if buffDef.isInfo and profileBuff
        and (profileBuff).AllowWhisper then
      self:WhisperExpired(buffDef)
    end

    -- if spell is enabled and we're in the correct shapeshift form
    if buffDefModule:IsBuffEnabled(buffDef.buffId, nil)
        and (buffDef.requiresForm == nil or playerStateModule.formId == buffDef.requiresForm)
    then
      -- ================
      -- Scan entry point
      -- ================
      self:CreateOneBuffTask(buffDef, party, buffCtx)
    end
  end
end

---When a paladin is mounted and AutoCrusaderAura enabled,
---offer player to cast Crusader Aura.
---@return boolean True if the scanning should be interrupted and only crusader aura prompt will be visible
function module:MountedCrusaderAuraPrompt()
  local playerUnit = rosterScanModule.roster.player

  if playerUnit and self:IsMountedAndCrusaderAuraRequired() then
    local spell = allBuffsModule.CrusaderAuraSpell
    local task = taskModule:Create(spell:SingleLink(), spell.singleText)
        :PrefixText(_t("TASK_CAST"))
        :ExtraText(_t("task.target.SelfOnly"))
        :Target(buffTargetModule:FromSelf(playerUnit))
        :Action(actionCastModule:New(
          spell.singleMana, spell.highestRankSingleId, spell:SingleLink(),
          playerUnit, spell, false))
    self.tasklist:Add(task)

    return true -- only show the aura and nothing else
  end

  return false -- continue scanning spells
end

function module:SomeoneIsDrinking()
  if BuffomatShared.SomeoneIsDrinking ~= "hide" then
    local count = auraScanModule.drinkingCount

    if count > 1 then
      if BuffomatShared.SomeoneIsDrinking == "low-prio" then
        self.tasklist:LowPrioComment(string.format(_t("InfoMultipleDrinking"), count))
      else
        self.tasklist:Comment(string.format(_t("InfoMultipleDrinking"), count))
      end
    elseif count > 0 then
      if BuffomatShared.SomeoneIsDrinking == "low-prio" then
        self.tasklist:LowPrioComment(_t("InfoSomeoneIsDrinking"))
      else
        self.tasklist:Comment(_t("InfoSomeoneIsDrinking"))
      end
    end
  end
end

function module:PlayTaskSound()
  local s = BuffomatShared.PlaySoundWhenTask
  if s ~= nil and s ~= "-" then
    PlaySoundFile("Interface\\AddOns\\BuffomatClassic\\Sounds\\" .. BuffomatShared.PlaySoundWhenTask)
  end
end

---@param context TaskScanContext
function module:DoScan(context)
  local buffCtx = --[[@as BomBuffScanContext]] {
    macroCommand = "",
    castButtonTitle = "",
    inRange = false,
    someoneIsDead = module.saveSomeoneIsDead,
  }

  self:UpdateMissingBuffs(context.party, buffCtx)

  -- cancel buffs
  self:CancelBuffs(context.party.player)

  -- Cast crusader aura when mounted, without condition. Ignore all other buffs
  if self:MountedCrusaderAuraPrompt() and not playerStateModule.isOnTaxi then
    local task = taskModule:Create("Crusader", nil)
        :Action(actionMacroModule:New("/cast Crusader Aura", "Crusader Aura"))
        :InRange(true)
    self.tasklist:Add(task)
  else
    -- Otherwise scan all enabled spells
    BuffomatAddon.scanModifierKeyDown = false

    -- ================
    -- Scan entry point
    -- ================
    self:CreateBuffTasks(context.party, buffCtx)
    self:CheckMissingWeaponEnchantments(context.party.player) -- if option to warn is enabled
    self:CheckReputationItems(context.party.player)

    ---Check if someone has drink buff, print an info message self:SomeoneIsDrinking()

    self:CheckItemsAndContainers(context.party.player, buffCtx)
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

---Scan only tasks which do not depend on aura data: weapon buffs, conjured items,
---tracking, and usable or openable items. Used during a PvP match, where the
---client keeps aura data secret even out of combat.
---@param context TaskScanContext
function module:DoAuraFreeScan(context)
  local buffCtx = --[[@as BomBuffScanContext]] { someoneIsDead = false }
  local playerUnit = context.party.player

  self:ActivateSelectedTracking()
  BuffomatAddon.scanModifierKeyDown = false

  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    if self:IsAuraFreeBuff(buffDef, playerUnit) then
      self:UpdateMissingBuffs_EachBuff(context.party, buffDef, buffCtx)
      if buffDefModule:IsBuffEnabled(buffDef.buffId, nil)
          and (buffDef.requiresForm == nil or playerStateModule.formId == buffDef.requiresForm) then
        self:CreateOneBuffTask(buffDef, context.party, buffCtx)
      end
    else
      -- Targets found before the match began are stale now
      buffDef:ResetBuffTargets()
    end
  end

  if not playerUnit.weaponDataUnavailable then
    self:CheckMissingWeaponEnchantments(playerUnit)
  end
  self:CheckItemsAndContainers(playerUnit, buffCtx)
  self.tasklist:LowPrioComment(_t("task.hint.PvPMatchAuraFree"))
end

---Explain once per session why most buffs are not checked during a PvP match.
function module:NotifyPvPMatchOnce()
  if not self.pvpMatchNoticeShown then
    self.pvpMatchNoticeShown = true
    BuffomatAddon:Print(_t("message.PvPMatchAuraFree"))
  end
end

---@param context TaskScanContext
function module:Finalize(context)
  -- Open Buffomat if any cast tasks were added to the task list
  if #self.tasklist.tasks > 0 or #self.tasklist.comments > 0 then
    taskListPanelModule:AutoShow("ts:Finalize/haveTasks")

    -- to avoid repeating sound, check whether task list before we started had length of 0
    if self.taskListSizeBeforeScan == 0 then
      self:PlayTaskSound()
    end
  end

  self.tasklist:Sort()
  self.tasklist:Display() -- Show all tasks and comments

  local firstToCast = self.tasklist:SelectTask()
  if firstToCast then
    self.tasklist:CastButton(firstToCast)
  else
    taskListPanelModule:AutoHide("ts:Finalize/nothing")
    self.tasklist:CastButton_Nothing() -- this is basically equal to if #tasklist.tasks == 0 below
    if context.auraFree then
      -- "Nothing to do" would suggest that everyone is buffed
      taskListPanelModule:CastButtonText(_t("castButton.inactive.PvPMatch"), false)
    end
  end
end

---@param _context TaskScanContext
---@return boolean True if the scan should continue, false if it should be aborted
function module:Precheck(_context)
  if allBuffsModule.selectedBuffs == nil then
    return false -- Too soon the system did not initialize yet
  end

  self.tasklist:Clear()
  return true
end -- end function bomUpdateScan_PreCheck1()

---@param context TaskScanContext
---@return boolean
function module:CheckBuffomatInactive(context)
  -- Check whether BOM is disabled due to some option and a matching condition
  if not self:IsMountedAndCrusaderAuraRequired() then
    -- If mounted and crusader aura enabled, then do not do further checks, allow the crusader aura
    local isBomActive, reasonDisabled = self:IsActive(context.party.player)
    if not isBomActive then
      self:ShowInactive(reasonDisabled)
      if BuffomatShared.HideWhenScanBlocked and taskListPanelModule:IsWindowVisible() then
        taskListPanelModule:AutoHide("ts:CheckBuffomatInactive", true)
      end
      return false
    end
  end

  return true
end

---@param _context TaskScanContext
---@return boolean
function module:CheckCastingChanneling(_context)
  -- If currently casting
  if playerStateModule.casting == "cast" then
    self:ShowInactive(_t("castButton.Busy"))
    return false -- Casting a spell, do not scan
  else
    if playerStateModule.casting == "channel" then
      self:ShowInactive(_t("castButton.BusyChanneling"))
      return false -- Channeling a spell, do not scan
    end
  end

  return true
end -- end function bomUpdateScan_PreCheck2()

---Do not infer missing buffs from aura data the client did not let us read.
---@param context TaskScanContext
---@return boolean
function module:CheckAuraData(context)
  if context.auraFree then
    return true -- auras are known to be unreadable; the aura-free scan does not use them
  end
  local party = context.party
  local unavailable = party.player.auraDataUnavailable
      or (party.playerPet and party.playerPet.auraDataUnavailable)
  for _, member in pairs(party.byUnitId) do
    unavailable = unavailable or member.auraDataUnavailable
  end
  if unavailable then
    self:ShowInactive(_t("castButton.inactive.AuraDataUnavailable"))
    return false
  end
  return true
end

---@param _context TaskScanContext
---@return boolean
function module:CheckGlobalCooldown(_context)
  local isInGlobalCooldown, cooldownEndTime = self:IsInGlobalCooldown()
  if not isInGlobalCooldown then
    return true
  end

  if cooldownEndTime then
    scanSchedulerModule:WakeAt(cooldownEndTime)
  end

  self:ShowInactive(_t("castButton.inactive.GlobalCooldown"))
  return false
end

function module:ShowInactive(reason)
  BuffomatAddon.checkForError = false
  BuffomatAddon.theMacro:Clear()
  taskListPanelModule:CastButtonText(reason, false)
end

---@class TaskScanContext
---@field party BomParty
---@field auraFree boolean PvP match hides auras: scan only tasks that do not read them

--- Work out from the snapshots who needs a buff or a resurrection, and show the tasks.
---@param party BomParty The roster as read by this pass
---@param auraFree boolean PvP match hides auras: scan only tasks that do not read them
---@return boolean active False when Buffomat is paused (resting, mounted, casting...)
function module:ScanTasks(party, auraFree)
  -- to avoid re-playing the same sound, only play when task list changes from 0 to some tasks
  if not self.tasklist then
    self.tasklist = taskListModule:New()
  end
  self.taskListSizeBeforeScan = #self.tasklist.tasks
  buffomatModule:UseProfile(profileModule:ChooseProfile())

  ---@type TaskScanContext
  local context = {
    party = party,
    auraFree = auraFree,
  }

  if not self:Precheck(context)
      or not self:CheckAuraData(context)
      or not self:CheckBuffomatInactive(context)
      or not self:CheckCastingChanneling(context)
      or not self:CheckGlobalCooldown(context)
  then
    return false
  end

  -- All pre-checks passed
  if auraFree then
    self:NotifyPvPMatchOnce()
    self:DoAuraFreeScan(context)
  else
    self:DoScan(context)
  end
  self:Finalize(context) -- Sort and display the tasks, update the cast button
  return true
end

---If a spell cast failed, the member is temporarily added to skip list, to
---continue casting buffs on other members
function BuffomatAddon.AddMemberToSkipList()
  if BuffomatAddon.castFailedBuff and BuffomatAddon.castFailedBuffTarget then
    local castFailedBuffVal = BuffomatAddon.castFailedBuff
    local castFailedTarget = BuffomatAddon.castFailedBuffTarget

    if (castFailedBuffVal).skipList
        and BuffomatAddon.castFailedBuffTarget then
      table.insert(castFailedBuffVal.skipList, castFailedTarget.name)
      scanSchedulerModule:Request("skipListMemberAdded")
    end
  end
end

function module:ClearSkip()
  for _, spell in ipairs(allBuffsModule.selectedBuffs) do
    if spell.skipList then
      wipe(spell.skipList)
    end
  end
end

---On Combat Start go through cancel buffs list and cancel those bufs
function BuffomatAddon.DoCancelBuffs()
  if allBuffsModule.selectedBuffs == nil or buffomatModule.currentProfile == nil then
    return
  end

  for _, spell in ipairs(BuffomatAddon.cancelBuffs) do
    if buffomatModule.currentProfile.CancelBuff[spell.buffId].Enable
        and module:CancelBuff(spell.singleFamily)
    then
      BuffomatAddon:Print(string.format(_t("message.CancelBuff"), spell:SingleLink(),
        UnitName(BuffomatAddon.cancelBuffSource) or ""))
    end
  end
end

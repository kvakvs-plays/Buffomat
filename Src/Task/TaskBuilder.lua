local BuffomatAddon = BuffomatAddon

-- Builds the task list from what a scan pass worked out: for every buff somebody
-- needs, the task to cast it, with its target, text and macro action.

---@class TaskBuilderModule
---@field tasklist BomTaskList The list being built
---@field result BomScanResult Who needs what, from the evaluation of this pass
local module = LibStub("Buffomat-TaskBuilder") --[[@as TaskBuilderModule]]

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local actionCastModule = LibStub("Buffomat-ActionCast") --[[@as ActionCastModule]]
local actionMacroModule = LibStub("Buffomat-ActionMacro") --[[@as ActionMacroModule]]
local actionUseModule = LibStub("Buffomat-ActionUse") --[[@as ActionUseModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local auraScanModule = LibStub("Buffomat-AuraScan") --[[@as AuraScanModule]]
local bagScanModule = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]
local buffChecksModule = LibStub("Buffomat-BuffChecks") --[[@as BuffChecksModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local buffTargetModule = LibStub("Buffomat-UnitBuffTarget") --[[@as BomUnitBuffTargetModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local groupBuffTargetModule = LibStub("Buffomat-GroupBuffTarget") --[[@as BomGroupBuffTargetModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local kvPlayerModule = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local kvUnitModule = LibStub("KvLibShared-Unit") --[[@as KvUnitModule]]
local ngStringsModule = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]
local playerStateModule = LibStub("Buffomat-PlayerStateScan") --[[@as PlayerStateScanModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local rangeScanModule = LibStub("Buffomat-RangeScan") --[[@as RangeScanModule]]
local scanEvaluateModule = LibStub("Buffomat-ScanEvaluate") --[[@as ScanEvaluateModule]]
local scanSchedulerModule = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]
local taskModule = LibStub("Buffomat-Task") --[[@as TaskModule]]
local texturesModule = LibStub("Buffomat-Textures") --[[@as TexturesModule]]

---@param a BomUnit
---@param b BomUnit
---@return boolean
local function resurrectersFirst(a, b)
  return tContains(allBuffsModule.RESURRECT_CLASSES, a.class)
      and not tContains(allBuffsModule.RESURRECT_CLASSES, b.class)
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

---@param spellName string
---@param units BomUnit[]
---@param groupIndex number|nil
---@param spell BomBuffDefinition
function module:GetGroupInRange(spellName, units, groupIndex, spell)
  local minDist
  local ret
  for _, member in ipairs(units) do
    if member.group == groupIndex then
      local distance = rangeScanModule:Distance(member)
      if not (envModule.IsSpellInRange(spellName, member.unitId) == 1 or member.isDead) then
        if distance > 2000 then
          return nil
        end
      elseif (minDist == nil or distance < minDist)
          and not tContains(spell.skipList, member.name) then
        minDist = distance
        ret = member
      end
    end
  end

  return ret
end

---The nearest member of a class who is in spell range, to cast a class blessing on.
---Nobody when a member of the class is dead or far away: the blessing would miss them.
---@param spellName string
---@param units BomUnit[]
---@param class string
---@param spell BomBuffDefinition
---@return BomUnit?
function module:GetClassInRange(spellName, units, class, spell)
  local minDist
  local ret

  for _, member in ipairs(units) do
    if member.class == class then
      if member.isDead then
        return nil
      elseif envModule.IsSpellInRange(spellName, member.unitId) ~= 1 then
        if rangeScanModule:Distance(member) > 2000 then
          return nil
        end
      elseif not tContains(spell.skipList, member.name) then
        local distance = rangeScanModule:Distance(member)
        if minDist == nil or distance < minDist then
          minDist = distance
          ret = member
        end
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
    if playerStateModule.instanceType == "none"
        and not playerStateModule.isPvP
        and kvUnitModule.IsPVP(targetUnit.unitId) then
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

---Add a paladin blessing
---@param buffDef BomBuffDefinition - spell to cast
---@param party BomParty - the party
---@param need BomBuffNeed
function module:AddBlessing(buffDef, party, need)
  if buffDef.groupMana ~= nil
      and not BuffomatShared.NoGroupBuff
  then
    -- For each class name WARRIOR, PALADIN, PRIEST, SHAMAN... etc
    for _, eachClassName in ipairs(constModule.CLASSES) do
      if need.groups[eachClassName]
          and need.groups[eachClassName] >= BuffomatShared.MinBlessing
      then
        scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")
        -- Prefer somebody who needs it; anybody of the class carries the blessing to all of them
        local classInRange = self:GetClassInRange(buffDef.groupText, need.units, eachClassName, buffDef)
        if classInRange == nil then
          classInRange = self:GetClassInRange(buffDef.groupText, party.units, eachClassName, buffDef)
        end

        if classInRange ~= nil
            and (not need.groupsHaveDead[eachClassName]
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
  for _k, unitHasBetter in ipairs(need.betterBuff) do
    self.tasklist:LowPrioComment(string.format(_t("tasklist.IgnoredBuffOn"),
      unitHasBetter.name, buffDef.singleText))
    -- Leave message that the target has a better or ignored buff
  end

  -- SINGLE BUFF
  for _j, needsBuff in ipairs(need.units) do
    if not needsBuff.isDead
        and buffDef.singleMana ~= nil
        and (BuffomatShared.NoGroupBuff
          or buffDef.groupMana == nil
          or needsBuff.class == "pet"
          or need.groups[needsBuff.class] == nil
          or need.groups[needsBuff.class] < BuffomatShared.MinBlessing) then
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
---@param need BomBuffNeed
function module:FindTargetForGroupBuff(groupIndex, buffDef, party, minBuff, need)
  if need.groups[groupIndex]
      and need.groups[groupIndex] >= minBuff
  then
    scanSchedulerModule:WakeAfter(scanSchedulerModule.RANGE_TICK, "range")
    local groupInRange = self:GetGroupInRange(buffDef.groupText, need.units, groupIndex, buffDef)

    --if groupInRange == nil then
    --  groupInRange = self:GetGroupInRange(buffDef.groupText, party, groupIndex, buffDef)
    --end

    --if groupInRange ~= nil and (not spell.GroupsHaveDead[groupIndex] or not BuffomatShared.DeathBlock) then
    if (groupIndex and not need.groupsHaveDead[groupIndex])
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
---@param need BomBuffNeed
function module:AddBuff_GroupBuff(buffDef, party, minBuff, need)
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
      self:FindTargetForGroupBuff(groupIndex, buffDef, party, minBuff, need)
    end -- for all 8 groups
  end
end

---@param buffDef BomBuffDefinition The spell to cast
---@param minBuff number Option for minimum players with missing buffs to choose group buff
---@param need BomBuffNeed
function module:AddBuff_SingleBuff(buffDef, minBuff, need)
  for _i, needBuff in ipairs(need.units) do
    if not needBuff.isDead
        and buffDef.singleMana ~= nil
        and (BuffomatShared.NoGroupBuff
          or buffDef.groupMana == nil
          or needBuff.group == 9
          or need.groups[needBuff.group] == nil
          or need.groups[needBuff.group] < minBuff)
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
---@param need BomBuffNeed
function module:AddBuff(buffDef, party, need)
  local minBuff = BuffomatShared.MinBuff or 3

  -- Check if any group qualifies for group buffing
  local shouldUseGroupBuff = false
  if buffDef.groupMana ~= nil and not BuffomatShared.NoGroupBuff then
    if envModule.groupBuffsRaidWide then
      -- WotLK and Forever: a group buff covers the whole raid, so check the total
      shouldUseGroupBuff = #need.units >= minBuff
    else
      -- Pre-WotLK: Group buff works per 5-man group, check each group
      for groupIndex = 1, 8 do
        if need.groups[groupIndex]
            and need.groups[groupIndex] >= minBuff then
          shouldUseGroupBuff = true
          break
        end
      end
    end
  end

  if shouldUseGroupBuff then
    -- Add GROUP BUFF
    -- if group buff spell costs mana
    self:AddBuff_GroupBuff(buffDef, party, minBuff, need)
  else
    -- Add SINGLE BUFF
    self:AddBuff_SingleBuff(buffDef, minBuff, need)
  end
end

---Adds the tasks to resurrect the dead, members who can resurrect others first
---@param spell BomBuffDefinition the spell to cast
---@param need BomBuffNeed
function module:AddResurrection(spell, need)
  local clearskip = true

  for _, member in ipairs(need.units) do
    if not tContains(spell.skipList, member.name) then
      clearskip = false
      break
    end
  end

  if clearskip then
    wipe(spell.skipList)
  end

  -- Classes which can resurrect others come first, in the list and by task priority
  table.sort(need.units, resurrectersFirst)

  for _k, unitNeedsBuff in ipairs(need.units) do
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
    if not playerStateModule.hasPet then
      return -- No pet - buff can not be cast
    end
    if playerStateModule.petCreatureTypeId ~= 3 then
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

  if (not buffDef.requiresOutdoors or playerStateModule.isOutdoors)
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

  if not playerStateModule.hasPet then
    -- No pet? Need summon
    add = true
  elseif playerStateModule.petCreatureTypeId ~= buffDef.creatureType
      or playerStateModule.petCreatureFamilyId ~= buffDef.creatureFamily then
    -- Have pet? Check pet type
    add = true
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
      and not kvPlayerModule.IsModifierKeyDown() then
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

  self.result.needsModifierKey = BuffomatShared.DontUseConsumables == true
end

---Adds a display text for a weapon buff
---@param buffDef BomBuffDefinition - the spell to cast
---@param playerUnit BomUnit the player
---@param target string Insert this text into macro where [@player] target text would go
function module:AddConsumableSelfbuff(buffDef, playerUnit, target)
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
      and not kvPlayerModule.IsModifierKeyDown() then
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
      and not kvPlayerModule.IsModifierKeyDown() then
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
  self.result.needsModifierKey = BuffomatShared.DontUseConsumables == true
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
function module:AddConsumableWeaponBuff(buffDef, playerUnit)
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
function module:AddWeaponEnchant(buffDef, playerUnit)
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
function module:CheckReputationItems()
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
function module:CheckMissingWeaponEnchantments()
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
  if BuffomatShared.DontUseConsumables and not kvPlayerModule.IsModifierKeyDown() then
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

  if BuffomatShared.DontUseConsumables and not kvPlayerModule.IsModifierKeyDown() then
    -- Can't use or cast
    self.tasklist:Add(task:IsInfo())
  else
    -- Will use/cast
    self.tasklist:Add(task
      :Action(actionUseModule:New(nil, target, item.bag, item.slot, item.link))
      :InRange(true))
  end
  self.result.needsModifierKey = BuffomatShared.DontUseConsumables == true
end

---Tasks for usable items (soulstones) which are off cooldown, and for containers to open.
---@param playerUnit BomUnit
function module:CheckItemsAndContainers(playerUnit)
  for _, itemIds in ipairs(BuffomatAddon.itemList) do
    for _, itemId in ipairs(itemIds) do
      local item = bagScanModule:Find(itemId)
      if item and item.link and bagScanModule:IsReady(item) then
        -- Use it on whoever had its buff from the player before
        local target = self.result.itemTargets[allBuffsModule.itemListSpellLookup[itemId]]
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

---Add the tasks for one buff, from who needs it.
---@param buffDef BomBuffDefinition
---@param party BomParty
function module:CreateOneBuffTask(buffDef, party)
  local need = self.result:Need(buffDef)
  if #need.units > 0
      and not buffDef.isInfo
      and not buffDef.isConsumable
  then
    self:WaitForMana(buffDef.singleMana)
    self:WaitForMana(buffDef.groupMana)
  end

  if buffDef.type == "summon" then
    self:AddSummonSpell(buffDef, party.player)
  elseif buffDef.type == "weapon" then
    if #need.units > 0 then
      if buffDef.isConsumable then
        self:AddConsumableWeaponBuff(buffDef, party.player)
      else
        self:AddWeaponEnchant(buffDef, party.player)
      end
    end
  elseif buffDef.isConsumable then
    if #need.units > 0 then
      self:AddConsumableSelfbuff(buffDef, party.player, buffDef.consumableTarget)
    end
  elseif buffDef.reminderCheck then
    if need.reminderText then
      -- Text: [Spell Link] what to do; nothing to cast
      self.tasklist:Add(taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
        :ExtraText(need.reminderText)
        :Target(buffTargetModule:FromSelf(party.player))
        :IsInfo()
        :LinkToBuffDef(buffDef))
    end
  elseif buffDef.isInfo then
    do
      for _m, unitNeedsBuff in ipairs(need.units) do
        -- Text: [Player Link] [Spell Link]
        local task = taskModule:Create(buffDef:SingleLink(), buffDef.singleText)
            :Target(buffTargetModule:FromUnit(unitNeedsBuff))
            :IsInfo()
            :LinkToBuffDef(buffDef)
        self.tasklist:Add(task)
      end
    end
  elseif buffDef.type == "tracking" then
    if #need.units > 0 then
      if playerStateModule.casting == nil then
        -- Tracking is not a spell cast; it is switched on by the side effects stage
        table.insert(self.result.trackingToActivate, buffDef)
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
    elseif #need.units > 0 then
      -- self buffs are not pvp-guarded
      self:AddSelfbuff(buffDef, party.player)
    end
  elseif buffDef.type == "resurrection" then
    self:AddResurrection(buffDef, need)
  elseif buffDef.isBlessing then
    self:AddBlessing(buffDef, party, need)
  else
    self:AddBuff(buffDef, party, need)
  end
end

---Add the tasks for every enabled buff.
---@param party BomParty
---@param auraFree boolean Only the buffs which can be decided without auras
function module:CreateBuffTasks(party, auraFree)
  for _, buffDef in ipairs(allBuffsModule.selectedBuffs) do
    -- if spell is enabled and we're in the correct shapeshift form
    if buffDefModule:IsBuffEnabled(buffDef.buffId, nil)
        and (buffDef.requiresForm == nil or playerStateModule.formId == buffDef.requiresForm)
        and (not auraFree or scanEvaluateModule:IsAuraFreeBuff(buffDef, party.player))
    then
      self:CreateOneBuffTask(buffDef, party)
    end
  end
end

---When a paladin is mounted and AutoCrusaderAura enabled,
---offer player to cast Crusader Aura.
---@return boolean True if the scanning should be interrupted and only crusader aura prompt will be visible
---@param playerUnit BomUnit
function module:MountedCrusaderAuraPrompt(playerUnit)
  if scanEvaluateModule:IsMountedAndCrusaderAuraRequired() then
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

---Build the task list of a pass.
---@param tasklist BomTaskList Emptied by the caller
---@param roster BomRoster
---@param result BomScanResult Who needs what
---@param auraFree boolean PvP match: only the tasks which do not depend on auras
function module:Build(tasklist, roster, result, auraFree)
  self.tasklist, self.result = tasklist, result
  local player = roster.player

  if auraFree then
    self:CreateBuffTasks(roster, true)
    if not player.weaponDataUnavailable then
      self:CheckMissingWeaponEnchantments()
    end
    self:CheckItemsAndContainers(player)
    tasklist:LowPrioComment(_t("task.hint.PvPMatchAuraFree"))
    return
  end

  -- Cast crusader aura when mounted, without condition. Ignore all other buffs
  if self:MountedCrusaderAuraPrompt(player) and not playerStateModule.isOnTaxi then
    tasklist:Add(taskModule:Create("Crusader", nil)
      :Action(actionMacroModule:New("/cast Crusader Aura", "Crusader Aura"))
      :InRange(true))
    return
  end

  self:CreateBuffTasks(roster, false)
  self:CheckMissingWeaponEnchantments() -- if option to warn is enabled
  self:CheckReputationItems()
  self:CheckItemsAndContainers(player)
end

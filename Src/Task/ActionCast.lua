local BuffomatAddon = BuffomatAddon

---@class BomActionCastModule

local actionCastModule = LibStub("Buffomat-ActionCast") --[[@as BomActionCastModule]]
local taskModule = LibStub("Buffomat-Task") --[[@as BomTaskModule]]
local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomTaskActionCast: BomTaskAction Casts a spell with a power (mana) cost on a target
---@field buffDef BomBuffDefinition|nil
---@field spellLink string|nil
---@field spellId number|nil
---@field manaCost number
---@field temporaryDownrank boolean Pick previous rank for certain spells, like Flametongue 10
---@field target BomUnit
local actionCastClass = {}
actionCastClass.__index = actionCastClass

---@param cost number Resource cost (mana cost)
---@param spellId number Spell id to capture
---@param link string Spell link for a picture
---@param targetUnit BomUnit player to benefit from the spell
---@param buffDef BomBuffDefinition the spell to be added
---@param temporaryDownrank boolean Pick previous rank for certain spells, like Flametongue 10
---@return BomTaskActionCast
function actionCastModule:New(cost, spellId, link, targetUnit, buffDef, temporaryDownrank)
  local a = --[[@as BomTaskActionCast]] {}
  setmetatable(a, actionCastClass)
  a.temporaryDownrank = temporaryDownrank
  a.manaCost = cost
  a.spellId = spellId
  a.spellLink = link
  a.buffDef = buffDef
  a.target = targetUnit
  return a
end

function actionCastClass:CanCast()
  -- Unknown cooldown (nil) counts as ready. Scans never run in combat or under
  -- addon restrictions, so nil means the client gave no data; blocking left
  -- the cast button stuck on "Nothing to do" with no rescan to recover it.
  -- The client still rejects a cast that really is on cooldown.
  local cdtest = envModule.GetSpellCooldown(self.spellId)
  if cdtest ~= nil and cdtest ~= 0 then
    BuffomatAddon.checkCooldown = self.spellId
    --BomC_ListTab_Button:Disable()
    return taskModule.CAN_CAST_ON_CD
  else
    --BomC_ListTab_Button:Enable()
  end
  BuffomatAddon.castFailedBuff = self.buffDef
  BuffomatAddon.castFailedBuffTarget = self.target

  if self.buffDef
      and (self.buffDef).type ~= "resurrection"
      and self.target.isDead then
    -- Cannot cast buffs on deads, only resurrections
    return taskModule.CAN_CAST_IS_DEAD
  end

  if self.manaCost > partyModule.playerMana then
    return taskModule.CAN_CAST_OOM
  end

  return taskModule.CAN_CAST_OK
end

---@param task BomTask
function actionCastClass:GetButtonText(task)
  return (self.spellLink or "?") .. " " .. task.extraText
end

function actionCastClass:GetCancelFormMacroLine()
  if envModule.playerClass == "DRUID" then
    return "/cancelform [nocombat, noform:5]"
  end

  return "/cancelform [nocombat]"
end

---@param m BomMacro
function actionCastClass:UpdateMacro(m)
  --Downgrade-Check
  local buffDef = allBuffsModule.buffFromSpellIdLookup[self.spellId]

  if buffDef == nil then
    BuffomatAddon:Debug("Update macro: buffDef is nil for spellid=" .. tostring(self.spellId))
    return
  end

  if BuffomatShared.UseRank
      or (self.target and (self.target).unitId == "target")
  then
    local targetLevel = UnitLevel((self.target).unitId)

    if buffDef and targetLevel ~= nil and targetLevel > 0 then
      local spellChoices

      if buffDef.singleFamily
          and tContains(buffDef.singleFamily, self.spellId) then
        spellChoices = buffDef.singleFamily
      elseif buffDef.groupFamily
          and tContains(buffDef.groupFamily, self.spellId) then
        spellChoices = buffDef.groupFamily
      end

      if spellChoices and targetLevel ~= nil and targetLevel > 0 then
        local newSpellId

        -- Find the highest spell rank which has no learned min level, or a min level that satisfies the target level.
        -- Iterate over spell choices in reverse order to find highest suitable rank
        -- for _, tryRankSpellId in ipairs(spellChoices) do
        --   if BuffomatShared.TargetTooLowLevel[tryRankSpellId] == nil
        --       or targetLevel > BuffomatShared.TargetTooLowLevel[tryRankSpellId] then
        --     newSpellId = tryRankSpellId
        --   else
        --     break
        --   end
        --   if tryRankSpellId == self.spellId then
        --     -- Successfully found a spell that is suitable for the target level, no need to check lower ranks
        --     break
        --   end
        -- end
        -- self.spellId = newSpellId or self.spellId
        -- Iterate spellChoices in reverse order to find highest suitable rank
        for i = #spellChoices, 1, -1 do
          local tryRankSpellId = spellChoices[i]

          if envModule.IsSpellKnown(tryRankSpellId) then
            -- Is this spell castable on this target?
            -- * Do we not know what happens if we cast this spell? (no record in TargetTooLowLevel)
            -- * Have we learned that the target level is too low? (have record in TargetTooLowLevel)
            if BuffomatShared.TargetTooLowLevel[tryRankSpellId] == nil
                or targetLevel > BuffomatShared.TargetTooLowLevel[tryRankSpellId] then
              newSpellId = tryRankSpellId
              break -- Found highest suitable rank, stop searching
            end
          end
        end
        self.spellId = newSpellId or self.spellId
      end
    end -- if spell and level
  end

  if self.temporaryDownrank then
    self.spellId = self.buffDef:GetDownRank(self.spellId)
  end

  BuffomatAddon.castFailedSpellId = self.spellId

  -- TODO: Want to use BuffomatAddon.GetSpellInfo but it is asyncronous, while GetSpellInfo is syncronous
  local spellName = envModule.GetSpellInfo(self.spellId)
  if spellName == nil then
    BuffomatAddon:Debug("Update macro: Bad spellid=" .. tostring(self.spellId))
    return
  end

  if tContains(allBuffsModule.cancelForm, self.spellId) then
    table.insert(m.lines, self:GetCancelFormMacroLine())
  end
  -- table.insert(m.lines, "/bom _checkforerror")

  local rank = envModule.GetSpellSubtext(self.spellId) or ""

  if rank ~= "" then
    rank = "(" .. rank .. ")"
  end
  local castCommand = "/cast [@" .. (self.target).unitId .. ",nocombat]" .. spellName .. rank
  table.insert(m.lines, castCommand)
end

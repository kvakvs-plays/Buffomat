local BuffomatAddon = BuffomatAddon

---@class ProfileModule
---@field ALL_PROFILES ProfileName[]

local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---A single blessing per unit name is possible
---@alias BlessingState {[string]: BomBuffId}

---Choices made by the player for a single buff
---@class PlayerBuffChoice
---@field Enable boolean
---@field Classes {[ClassName]: boolean}
---@field ForcedTarget {[string]: boolean}
---@field ExcludedTarget {[string]: boolean}
---@field SelfCast boolean
---@field CustomSort string
---@field AllowWhisper boolean
---@field MainHandEnable boolean
---@field OffHandEnable boolean

---A collection of player choices per buff id
---@alias PlayerBuffChoiceDict {[BomBuffId]: PlayerBuffChoice}

---@return BlessingState
function profileModule:NewBlessingState()
  return {} --[[@as BlessingState]]
end

---Named options: Are addressed by their string name in translations, control names, etc
---@class ProfileSettings Snapshot of current options state as selected by the player
---@field CurrentBlessing BlessingState
---@field ReputationTrinket boolean Warn if AD trinket is equipped while in an instance
---@field AutoDismount boolean Dismount if necessary for buff cast
---@field AutoDisTravel boolean Remove travel form if necessary for buff cast
---@field AutoOpen boolean Open buffomat if required
---@field AutoStand boolean Stand up if required for a cast
---@field BuffTarget boolean Also try and buff the current target
---@field Carrot boolean Whether to track carrot equipped in dungeons
---@field DeathBlock boolean Don't cast group buffs, when somebody is dead
---@field DisableInRestArea boolean Hide BOM and clear tasks if in resting area ZZZ/city or inn
---@field DontUseConsumables boolean Prevent use of consumables
---@field SomeoneIsDrinking string When someone is drinking low-prio - Show as a comment; hide - no show; show - Show as a task and show buffomat window
---@field ActivateBomOnSpiritTap number Activate Buffomat while Priest talent 'Spirit tap' is active and mana is below X%
---@field InInstance boolean Buff while in an instance
---@field InPVP boolean Buff while in PvP instance
---@field InWorld boolean Buff in the open world
---@field MainHand boolean Warn about mainhand missing temporary enchant
---@field NoGroupBuff boolean Avoid casting group buffs
---@field OpenLootable boolean List lootable items for opening in the task list
---@field ReplaceSingle boolean Replace single buffs with group
---@field ResGhost boolean Attempt resurrecting ghosts
---@field SameZone boolean Check only in the same zone
---@field SecondaryHand boolean Warn about offhand temporary enchant missing
---@field SelfFirst boolean Buff self first
---@field ShowClassicConsumables boolean Will show pre-TBC consumables
---@field ShowTBCConsumables boolean Will show TBC consumables in the list
---@field UseRank boolean Use ranked spells
---@field SlowerHardware boolean Less frequent updates
---@field CancelBuff BomAllBuffsTable --table<BomBuffId, BomBuffDefinition>
---@field Spell PlayerBuffChoiceDict Player choices per buff id
---@field LastSeal number|nil
---@field LastAura number|nil

---@alias BomBuffDefinitionDict {[BomBuffId]: BomBuffDefinition}

---@return ProfileSettings
function profileModule:New()
  local profile = {} --[[@as ProfileSettings]]
  -- profile.AutoOpen = true
  profile.AutoStand = true
  profile.BuffTarget = true
  profile.DeathBlock = true
  profile.DisableInRestArea = true
  profile.SomeoneIsDrinking = "low-prio"
  profile.InInstance = true
  profile.InPVP = true
  profile.InWorld = true
  profile.OpenLootable = true
  profile.ReplaceSingle = true
  profile.SameZone = true
  profile.SelfFirst = true
  return profile
end

function profileModule:Setup()
  if envModule.haveWotLK or GetActiveTalentGroup ~= nil then
    self.ALL_PROFILES = {
      "solo", "solo_spec2",
      "group", "group_spec2",
      "raid", "raid_spec2",
      "battleground", "battleground_spec2"
    }
  else
    self.ALL_PROFILES = { "solo", "group", "raid", "battleground" }
  end
end

local function bomGetActiveTalentGroup()
  if envModule.haveWotLK then
    return envModule.GetActiveTalentGroup()
  else
    return nil
  end
end

---@return ProfileName
function profileModule:SoloProfile()
  local spec = bomGetActiveTalentGroup()
  if spec == 1 or spec == nil then
    return "solo"
  else
    return "solo_spec2"
  end
end

---@return ProfileName
function profileModule:GroupProfile()
  local spec = bomGetActiveTalentGroup()
  if spec == 1 or spec == nil then
    return "group"
  else
    return "group_spec2"
  end
end

---@return ProfileName
function profileModule:RaidProfile()
  local spec = bomGetActiveTalentGroup()
  if spec == 1 or spec == nil then
    return "raid"
  else
    return "raid_spec2"
  end
end

---@return ProfileName
function profileModule:BattlegroundProfile()
  local spec = bomGetActiveTalentGroup()
  if spec == 1 or spec == nil then
    return "battleground"
  else
    return "battleground_spec2"
  end
end

---Based on profile settings and current PVE or PVP instance choose the mode
---of operation
---@return ProfileName
function profileModule:ChooseProfile()
  local _inInstance, instanceType = IsInInstance()
  local selectedProfile = self:SoloProfile()

  if IsInRaid() then
    selectedProfile = self:RaidProfile()
  elseif IsInGroup() then
    selectedProfile = self:GroupProfile()
  end

  -- TODO: Refactor isDisabled into a function, also return reason why is disabled
  if BuffomatAddon.forceProfile then
    selectedProfile = BuffomatAddon.forceProfile or selectedProfile
  elseif not BuffomatCharacter.UseProfiles then
    selectedProfile = self:SoloProfile()
  elseif instanceType == "pvp" or instanceType == "arena" then
    selectedProfile = self:BattlegroundProfile()
  end

  return selectedProfile
end

---@param buffId BomBuffId
---@param profileName ProfileName|nil
---@return PlayerBuffChoice
function profileModule:GetProfileBuff(buffId, profileName)
  if profileName == nil then
    return buffomatModule.currentProfile.Spell[buffId]
  end

  local profile = BuffomatCharacter.profiles[profileName]
  if profile == nil then
    return nil
  end

  return profile.Spell[buffId]
end
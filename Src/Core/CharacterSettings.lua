---@class CharacterSettingsModule
---@field profileNames ProfileName[]

local characterSettingsModule = LibStub("Buffomat-CharacterSettings") --[[@as CharacterSettingsModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]

---@alias ProfileName "auto"|"solo"|"group"|"raid"|"battleground"|"solo_spec2"|"group_spec2"|"raid_spec2"|"battleground_spec2"
characterSettingsModule.profileNames = {
  -- "auto", -- auto is a special profile name meaning "pick from the environment" and not a real profile
  "solo",
  "group",
  "raid",
  "battleground",
  "solo_spec2",
  "group_spec2",
  "raid_spec2",
  "battleground_spec2",
}
---@alias BomSpellDurationsTable {[WowSpellId]: number}
---@alias BomHiddenCategoryTable {[BuffCategoryName]: boolean}

---@class CharacterSettings Current character state snapshots per profile
---@field profiles {[ProfileName]: ProfileSettings} Access to subprofiles [solo, group, raid, battleground, ...]
---@field UseProfiles boolean [⚠DO NOT RENAME] Checkbox to use profiles / automatic profiles
---@field remainingDurations BomSpellDurationsTable Remaining aura duration on SELF, keyed with buff names
---@field lastTrackingIconId WowIconId|nil Icon id for the last active tracking (not relevant in TBC?)
---@field BuffCategoriesHidden BomHiddenCategoryTable [⚠DO NOT RENAME] True if category is hidden (control in options)
---@field WatchGroup table<number, boolean> [⚠DO NOT RENAME] True to watch buffs in group 1..8
---@field Spell PlayerBuffChoiceDict [⚠DO NOT RENAME] Enabled/disabled buffs; see also assignment to ["Spell"] in buffomatModule:InitGlobalStates()
---@field CancelBuff table<BomBuffId, BomBuffDefinition>|nil [⚠DO NOT RENAME]
---@field LastSeal number|nil
---@field LastAura number|nil

function characterSettingsModule:LocalizedProfileName(profileName)
  return _t("profileName." .. profileName)
end

---@param init CharacterSettings|nil
---@return CharacterSettings
function characterSettingsModule:NewDefaultCharacterSettings(init)
  local tab = init or self:Defaults()
  tab.Spell = tab.Spell or {}
  tab.remainingDurations = tab.remainingDurations or {}
  tab.lastTrackingIconId = tab.lastTrackingIconId or 0

  tab.solo = tab.solo or profileModule:New()
  tab.group = tab.group or profileModule:New()
  tab.raid = tab.raid or profileModule:New()
  tab.battleground = tab.battleground or profileModule:New()

  if envModule.haveWotLK then
    tab.solo_spec2 = tab.solo_spec2 or profileModule:New()
    tab.group_spec2 = tab.group_spec2 or profileModule:New()
    tab.raid_spec2 = tab.raid_spec2 or profileModule:New()
    tab.battleground_spec2 = tab.battleground_spec2 or profileModule:New()
  end

  tab.BuffCategoriesHidden = tab.BuffCategoriesHidden or {}
  return tab
end

---@return CharacterSettings
function characterSettingsModule:Defaults()
  return {}
end

function characterSettingsModule:GetProfile(profileName)
  if BuffomatCharacter.profiles == nil then
    BuffomatCharacter.profiles = {}
  end
  local profile = BuffomatCharacter.profiles[profileName]
  if profile == nil then
    profile = profileModule:New()
    BuffomatCharacter.profiles[profileName] = profile
  end
  return profile
end
local BuffomatAddon = BuffomatAddon

---Collection of tables of buffs, indexed per unit name
---@alias BomBuffUpdatesPerUnit {[string]: number} Time when buffs updated on that unit
---@alias BomPartyCacheInvalidation {[number]: boolean}

---@class PartyModule
---@field theParty BomParty|nil Synchronized party cache, invalidated on party change events
---@field unitAurasLastUpdated BomBuffUpdatesPerUnit When each unit got their aura last updated, indexed by spellid
---@field partyCacheInvalidation BomPartyCacheInvalidation
---@field itemListTarget table<number, string> Remember who casted item buff on you?
---@field playerManaLimit number Player max mana
---@field playerMana number Player current mana

local partyModule = LibStub("Buffomat-Party") --[[@as PartyModule]]
local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]

---@type BomBuffUpdatesPerUnit
partyModule.unitAurasLastUpdated = {}

---@type {[number]: boolean}
partyModule.partyCacheInvalidation = {}
partyModule.itemListTarget = {}
partyModule.playerMana = 0
partyModule.playerManaLimit = 0

---@type BomPartyCacheInvalidation
partyModule.ALL_INVALID_GROUPS = {
  [1] = true,
  [2] = true,
  [3] = true,
  [4] = true,
  [5] = true,
  [6] = true,
  [7] = true,
  [8] = true
}

-- local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local unitCacheModule = LibStub("Buffomat-UnitCache") --[[@as UnitCacheModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]

---@alias BomUnitDictByUnitId {[string]: BomUnit}
---@alias BomUnitDictByName {[string]: BomUnit}
---@alias BomUnitDictByGroup {[number]: BomUnitDictByName}

---@class BomParty
---@field byGroup BomUnitDictByGroup Party members by group number
---@field byUnitId BomUnitDictByUnitId Party members by group number
---@field byName BomUnitDictByName Party members by name
---@field player BomUnit
---@field playerPet BomUnit|nil
---@field emptyGroups table<number, boolean> Groups without members
local partyClass = {}
partyClass.__index = partyClass

---@return BomParty
function partyModule:New()
  local p = {
    byGroup = {},
    byUnitId = {},
    byName = {},
    emptyGroups = {}
  }
  setmetatable(p, partyClass)
  return p
end

---@param unitName string
---@param _evType string
function partyModule:OnBuffsChangedEvent(unitName, _spellId, _evType)
  if self.theParty
      and not (self.theParty):IsNameInParty(unitName) then
    return
  end
  self.unitAurasLastUpdated[unitName] = self.unitAurasLastUpdated[unitName] or {}
  self.unitAurasLastUpdated[unitName] = GetTime()
end

---@param member BomUnit
function partyClass:Add(member)
  self.byUnitId[member.unitId] = member

  self.byGroup[member.group] = self.byGroup[member.group] or {}
  self.byGroup[member.group][member.name] = member

  self.byName[member.name] = member
end

---@param name string
---@return boolean
function partyClass:IsNameInParty(name)
  return self.byName[name] ~= nil
end

---Drop buffs for names which aren't in our party
---@param party BomParty
function partyModule:CleanUpBuffs(party)
  -- Clean partyModule.buffs up
  for name, _ in pairs(self.unitAurasLastUpdated) do
    if not party:IsNameInParty(name) then
      self.unitAurasLastUpdated[name] = nil
    end
  end
end

---@return number count Party size including pets
---@nodiscard
function partyModule:GetPartySize()
  local countTo
  local prefix
  local count

  if IsInRaid() then
    countTo = 40
    prefix = "raid"
    count = 0
  else
    countTo = 4
    prefix = "party"

    if UnitPlayerOrPetInParty("pet") then
      count = 2
    else
      count = 1
    end
  end

  for i = 1, countTo do
    if UnitPlayerOrPetInParty(prefix .. i) then
      count = count + 1

      if UnitPlayerOrPetInParty(prefix .. "pet" .. i) then
        count = count + 1
      end
    end
  end

  return count
end

function partyModule:InvalidatePartyCache()
  self.partyCacheInvalidation[1] = true
  self.partyCacheInvalidation[2] = true
  self.partyCacheInvalidation[3] = true
  self.partyCacheInvalidation[4] = true
  self.partyCacheInvalidation[5] = true
  self.partyCacheInvalidation[6] = true
  self.partyCacheInvalidation[7] = true
  self.partyCacheInvalidation[8] = true
end

---@param group number
function partyModule:InvalidatePartyGroup(group)
  self.partyCacheInvalidation[group] = true
end

function partyModule:ValidatePartyCache()
  wipe(self.partyCacheInvalidation)
end

---@param party BomParty
---@param invalidGroups BomPartyCacheInvalidation
function partyModule:RefreshParty(party, invalidGroups)
  if IsInRaid() then
    party:GetRaidMembers(invalidGroups)
  else
    party:Get5manPartyMembers()
  end

  local isBuffableUnit = UnitIsPlayer("target") or UnitIsOtherPlayersPet("target")
  local isPartyMember = UnitInParty("target") or UnitInRaid("target")

  if BuffomatShared.BuffTarget
      and UnitExists("target")
      and isBuffableUnit
      and not isPartyMember
  then
    -- local targetedUnit = unitCacheModule:GetUnit("target", nil, nil, nil)
    -- if targetedUnit then
    --   (targetedUnit).group = 9 --move them outside of 8 buff groups
    --   party:Add(targetedUnit)
    -- end
    -- If a drive-by buff option is enabled, always have the target in the party
    local targetUnit = unitCacheModule:GetUnit("target", nil, nil, nil)
    if targetUnit then
      party:Add(targetUnit)
    end
  end

  unitCacheModule.partyCache = party
  partyModule:CleanUpBuffs(party)
  throttleModule:RequestTaskRescan("reloadParty") -- always read all buffs on new party!
  return party
end

function partyClass:GetPlayerAndPetUnit()
  -- Get player and get pet
  local playerUnit = unitCacheModule:GetUnit("player", nil, nil, nil)
  self.player = playerUnit
  self:Add(playerUnit)

  local playerPet = unitCacheModule:GetUnit("pet", nil, nil, true)
  if playerPet then
    local pet = playerPet
    pet.owner = playerUnit
    pet.class = "pet"
    self.playerPet = pet
    self:Add(pet)
  else
    self.playerPet = nil
  end

  -- Refresh weapon-buffs
  -- Clear old
  local OldMainHandBuff = self.player.mainhandEnchantment
  local OldOffHandBuff = self.player.offhandEnchantment

  self.player:UpdatePlayerWeaponEnchantments()

  if OldMainHandBuff ~= self.player.mainhandEnchantment then
    throttleModule:RequestTaskRescan("mainHandBuffChanged")
  end

  if OldOffHandBuff ~= self.player.offhandEnchantment then
    throttleModule:RequestTaskRescan("offhandBuffChanged")
  end
end

---@return BomParty
function partyClass:Get5manPartyMembers()
  if IsInGroup() then
    for groupIndex = 1, 4 do
      local partyMember = unitCacheModule:GetUnit("party" .. groupIndex, nil, nil, nil)
      if partyMember then
        self:Add(partyMember)
      end

      local partyPet = unitCacheModule:GetUnit("partypet" .. groupIndex, nil, nil, true)
      if partyPet then
        local pet = partyPet
        pet.owner = partyMember
        pet.class = "pet"
        self:Add(pet)
      end
    end
  end

  self:GetPlayerAndPetUnit()
  return self
end

---For when player is in raid, retrieve all 40 raid members
---InvalidGroups parameter allows reloading partially 5 members at a time
---@param invalidGroups BomPartyCacheInvalidation Groups to reload
---@return BomParty
function partyClass:GetRaidMembers(invalidGroups)
  local nameGroupMap = --[[@as BomNameGroupMap]] {}
  local nameRoleMap = --[[@as BomNameRoleMap]] {}

  for groupIndex, _true in pairs(invalidGroups) do
    local raidBegin = (groupIndex - 1) * 5
    local raidEnd = raidBegin + 5
    self.emptyGroups[groupIndex] = true

    for raidIndex = raidBegin, raidEnd do
      ---@type string, string, number, number, ClassName, string, number, boolean, boolean, BomRaidRole, boolean, string
      local name, _rank, subgroup, _level, _class, _fileName, _zone, _online, _isDead
      , role, _isML, combatRole = GetRaidRosterInfo(raidIndex)

      if name then
        name = toolboxModule:Split(name, "-")[1]
        nameGroupMap[name] = subgroup
        -- Priority for role detection:
        --   1. Legacy MAINTANK/MAINASSIST flag set by raid leader (right-click "Set Main Tank")
        --      wins so a DPS-specced warrior marked MAINTANK is still recognised as a tank.
        --   2. Modern combatRole ("TANK"/"HEALER"/"DAMAGER") from spec/LFG.
        --   3. Fall back to whatever role string GetRaidRosterInfo returned ("NONE").
        if role == "MAINTANK" or role == "MAINASSIST" then
          nameRoleMap[name] = role
        elseif combatRole == "TANK" or combatRole == "HEALER" or combatRole == "DAMAGER" then
          nameRoleMap[name] = combatRole
        else
          nameRoleMap[name] = role
        end
      end

      local partyMember = unitCacheModule:GetUnit("raid" .. raidIndex, nameGroupMap, nameRoleMap, nil)
      if partyMember then
        self.emptyGroups[groupIndex] = false
        self:Add(partyMember)
      end
    end -- each member of invalidated group
  end   -- invalidated groups

  self:GetPlayerAndPetUnit()
  return self
end

---Fail if unit full name doesn't match saved member name
---@param party BomParty
---@return boolean
local function validatePartyMembers(party)
  for _, member in pairs(party.byUnitId) do
    local name = UnitFullName(member.unitId)

    if name ~= member.name then
      return false
    end
  end

  return true
end

-- local function printInvalidationMap()
--   local out = "["
--   for group, _true in pairs(partyModule.partyCacheInvalidation) do
--     out = out .. tostring(group) .. ", "
--   end
--   return out .. "]"
-- end

---@return BomParty
function partyModule:GetParty()
  -- and buffs
  local party ---@type BomParty

  BuffomatAddon.drinkingPersonCount = 0

  -- check if stored party is correct!
  if self.theParty then
    if validatePartyMembers(self.theParty) then
      -- Cache is valid, take that as a start value
      party = self.theParty
    end
  end

  if party then
    -- Partial refresh of existing raid or full party refresh
    party = partyModule:RefreshParty(party, self.partyCacheInvalidation)
  else
    -- If previous cached party failed, do full refresh
    party = partyModule:RefreshParty(partyModule:New(), self.ALL_INVALID_GROUPS)
  end

  BuffomatAddon.somebodyIsGhost = false

  local playerZone = C_Map.GetBestMapForUnit("player")

  if IsAltKeyDown() then
    BuffomatAddon.declineHasResurrection = true
    taskScanModule:ClearSkip()
  end

  -- For every party member which is in same zone, not a ghost or is a target
  for _i, member in pairs(party.byUnitId) do
    if self.partyCacheInvalidation[member.group] then
      member:UpdateBuffs(party, playerZone)
    end
  end -- for all in party

  -- For group 1 always refresh self and self-pet
  if self.partyCacheInvalidation[1] then
    party.player:UpdateBuffs(party, playerZone)

    if party.playerPet ~= nil then
      (party.playerPet):UpdateBuffs(party, playerZone)
    end
  end

  BuffomatAddon.declineHasResurrection = false
  partyModule:ValidatePartyCache()
  self.theParty = party
  return party
end
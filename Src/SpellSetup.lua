local BuffomatAddon = BuffomatAddon
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomSpellSetupModule

local spellSetupModule = LibStub("Buffomat-SpellSetup") --[[@as BomSpellSetupModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local itemCacheModule = LibStub("Buffomat-ItemCache") --[[@as BomItemCacheModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefinitionModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local ngStringsModule = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]

---Formats a spell icon + spell name as a link
-- TODO: Move to SpellDef class
---@param spellInfo BomSpellCacheElement spell info from the cache via BOM.GetSpellInfo
function spellSetupModule:FormatSpellLink(spellInfo)
  if spellInfo == nil then
    return "NIL SPELL"
  end
  if spellInfo.spellId == nil then
    return "NIL SPELLID"
  end

  return "|Hspell:" .. spellInfo.spellId
      .. "|h|r |cff71d5ff"
      .. ngStringsModule:FormatTexture( --[[@as string]] spellInfo.icon)
      .. spellInfo.name
      .. "|r|h"
end

function spellSetupModule:Setup_ResetCaches()
  wipe(allBuffsModule.selectedBuffs)
  wipe(allBuffsModule.selectedBuffsSpellIds)
  wipe(allBuffsModule.spellIdtoBuffId)

  allBuffsModule.cancelForm = {}
  allBuffsModule.allSpellIds = {}
  allBuffsModule.buffFromSpellIdLookup = --[[@as {[WowSpellId]: BomBuffDefinition}]] {}

  BuffomatShared.Cache = BuffomatShared.Cache or {}
  BuffomatShared.Cache.Item2 = BuffomatShared.Cache.Item2 or {}
end

function spellSetupModule:Setup_CancelBuffs()
  for i, cancelBuff in ipairs(BuffomatAddon.cancelBuffs) do
    -- save "buffId"
    --spell.buffId = spell.buffId or spell.singleId

    if cancelBuff.singleFamily then
      for sindex, sID in ipairs(cancelBuff.singleFamily) do
        allBuffsModule.spellIdtoBuffId[sID] = cancelBuff.buffId
      end
    end

    -- GetSpellNames and set default duration
    local spellInfo = BuffomatAddon.GetSpellInfo(cancelBuff.highestRankSingleId)

    if spellInfo then
      local spellInfoValue = spellInfo

      cancelBuff.singleText = spellInfoValue.name
      spellInfoValue.rank = envModule.GetSpellSubtext(cancelBuff.highestRankSingleId) or ""
      cancelBuff.singleLink = self:FormatSpellLink((spellInfo))
      cancelBuff.spellIcon = spellInfoValue.icon
    end

    toolboxModule:iMerge(allBuffsModule.allSpellIds, cancelBuff.singleFamily)

    for j, profileName in ipairs(profileModule.ALL_PROFILES) do
      if BuffomatCharacter.profiles[profileName].CancelBuff[cancelBuff.buffId] == nil then
        BuffomatCharacter.profiles[profileName].CancelBuff[cancelBuff.buffId] = buffDefinitionModule:New(0)
        BuffomatCharacter.profiles[profileName].CancelBuff[cancelBuff.buffId].Enable = cancelBuff.default or false
      end
    end
  end
end

---@param buffDef BomBuffDefinition
---@param add boolean
function spellSetupModule:Setup_EachSpell_Consumable(add, buffDef)
  for _i, eachItem in pairs(buffDef.items or {}) do
    -- call results are cached if they are successful, should not be a performance hit
    local itemInfo = BuffomatAddon.GetItemInfo(eachItem)

    if not buffDef.isScanned and itemInfo then
      if (not itemInfo
            or not (itemInfo).itemName
            or not (itemInfo).itemLink
            or not (itemInfo).itemTexture)
          and BuffomatShared.Cache.Item2[eachItem]
      then
        itemInfo = BuffomatShared.Cache.Item2[eachItem]
      elseif (not itemInfo
            or not (itemInfo).itemName
            or not (itemInfo).itemLink
            or not (itemInfo).itemTexture)
          and itemCacheModule.cache[buffDef:GetFirstItem()]
      then
        itemInfo = itemCacheModule.cache[buffDef:GetFirstItem()]
      end

      if itemInfo
          and (itemInfo).itemName
          and (itemInfo).itemLink
          and (itemInfo).itemTexture
      then
        add = true
        buffDef.singleText = (itemInfo).itemName
        buffDef.singleLink = ngStringsModule:FormatTexture((itemInfo).itemTexture)
            .. (itemInfo).itemLink
        buffDef.itemIcon = (itemInfo).itemTexture
        buffDef.isScanned = true

        BuffomatShared.Cache.Item2[eachItem] = itemInfo
      else
        -- Go delayed fetch
        local item = Item:CreateFromItemID(eachItem)
        item:ContinueOnItemLoad(function()
          local name = item:GetItemName()
          local link = item:GetItemLink()
          local icon = item:GetItemIcon()
          BuffomatShared.Cache.Item2[eachItem] = {
            itemName = name,
            itemLink = link,
            itemIcon = icon
          }
        end)
      end
    else
      add = true
    end
  end -- for eachItem

  return add
end

---@param spell BomBuffDefinition
function spellSetupModule:Setup_EachSpell_CacheUpdate(spell)
  -- get highest rank and store SpellID=buffId
  if spell.singleFamily then
    for sindex, eachSingleId in ipairs(spell.singleFamily) do
      allBuffsModule.spellIdtoBuffId[eachSingleId] = spell.buffId
      allBuffsModule.spellIdIsSingleLookup[eachSingleId] = true
      allBuffsModule.buffFromSpellIdLookup[eachSingleId] = spell

      if envModule.IsSpellKnown(eachSingleId) then
        spell.highestRankSingleId = eachSingleId
      end
    end
  end

  if spell.highestRankSingleId then
    allBuffsModule.spellIdtoBuffId[spell.highestRankSingleId] = spell.buffId
    allBuffsModule.spellIdIsSingleLookup[spell.highestRankSingleId] = true
    allBuffsModule.buffFromSpellIdLookup[spell.highestRankSingleId] = spell
  end

  if spell.groupFamily then
    for sindex, eachGroupId in ipairs(spell.groupFamily) do
      allBuffsModule.spellIdtoBuffId[eachGroupId] = spell.buffId
      allBuffsModule.buffFromSpellIdLookup[eachGroupId] = spell

      if envModule.IsSpellKnown(eachGroupId) then
        spell.highestRankGroupId = eachGroupId
      end
    end
  end

  if spell.highestRankGroupId then
    allBuffsModule.spellIdtoBuffId[spell.highestRankGroupId] = spell.buffId
    allBuffsModule.buffFromSpellIdLookup[spell.highestRankGroupId] = spell
  end
end

---@param buffDef BomBuffDefinition
function spellSetupModule:Setup_EachSpell_SetupNonConsumable(buffDef)
  -- Load spell info and save some good fields for later use
  local spellInfo = BuffomatAddon.GetSpellInfo(buffDef.highestRankSingleId)

  if spellInfo ~= nil then
    local spellInfoValue = spellInfo

    buffDef.singleText = spellInfoValue.name
    spellInfoValue.rank = envModule.GetSpellSubtext(buffDef.highestRankSingleId) or ""
    buffDef.singleLink = self:FormatSpellLink(spellInfoValue)
    buffDef.spellIcon = spellInfoValue.icon

    if buffDef.type == "tracking" then
      buffDef.trackingIconId = spellInfoValue.icon
      buffDef.trackingSpellName = spellInfoValue.name
    end

    if not buffDef.isInfo
        and not buffDef.isConsumable
        and buffDef.singleDuration
        and BuffomatShared.Duration[spellInfoValue.name] == nil
        and envModule.IsSpellKnown(buffDef.highestRankSingleId) then
      BuffomatShared.Duration[spellInfoValue.name] = buffDef.singleDuration
    end
  end -- spell info returned success
end

---@param spell BomBuffDefinition
function spellSetupModule:Setup_EachSpell_SetupGroupBuff(spell)
  local spellInfo = BuffomatAddon.GetSpellInfo(spell.highestRankGroupId)

  if spellInfo ~= nil then
    local spellInfoValue = spellInfo

    spell.groupText = spellInfoValue.name
    spellInfoValue.rank = envModule.GetSpellSubtext(spell.highestRankGroupId) or ""
    spell.groupLink = self:FormatSpellLink(spellInfoValue)

    if spell.groupDuration
        and BuffomatShared.Duration[spellInfoValue.name] == nil
        and envModule.IsSpellKnown(spell.highestRankGroupId)
    then
      BuffomatShared.Duration[spellInfoValue.name] = spell.groupDuration
    end
  end
end

---Adds a spell to the palette of spells to configure and use, for each profile
---@param buffDef BomBuffDefinition
function spellSetupModule:Setup_EachBuff_AddKnown(buffDef)
  tinsert(allBuffsModule.selectedBuffs, buffDef)

  for _, spellId in ipairs(buffDef.singleFamily) do
    allBuffsModule.selectedBuffsSpellIds[spellId] = buffDef
  end
  for _, spellId in ipairs(buffDef.groupFamily or {}) do
    allBuffsModule.selectedBuffsSpellIds[spellId] = buffDef
  end

  toolboxModule:iMerge(
    allBuffsModule.allSpellIds,
    buffDef.singleFamily, buffDef.groupFamily or {},
    buffDef.highestRankSingleId, buffDef.highestRankGroupId)

  if buffDef.cancelForm then
    toolboxModule:iMerge(
      allBuffsModule.cancelForm,
      buffDef.singleFamily, buffDef.groupFamily or {},
      buffDef.highestRankSingleId, buffDef.highestRankGroupId)
  end

  --setDefaultValues!
  for j, eachProfile in ipairs(profileModule.ALL_PROFILES) do
    ---@type BomBuffDefinition
    local profileSpell = BuffomatCharacter.profiles[eachProfile].Spell[buffDef.buffId]

    if profileSpell == nil then
      BuffomatCharacter.profiles[eachProfile].Spell[buffDef.buffId] = buffDefinitionModule:New(0)
      profileSpell = BuffomatCharacter.profiles[eachProfile].Spell[buffDef.buffId]

      profileSpell.Class = profileSpell.Class or {}
      profileSpell.ForcedTarget = profileSpell.ForcedTarget or {}
      profileSpell.ExcludedTarget = profileSpell.ExcludedTarget or {}
      profileSpell.Enable = buffDef.default or false

      if buffDef:HasClasses() then
        local SelfCast = true
        profileSpell.SelfCast = false

        for ci, class in ipairs(constModule.CLASSES) do
          profileSpell.Class[class] = tContains(buffDef.targetClasses or {}, class)
          SelfCast = profileSpell.Class[class] and false or SelfCast
        end

        profileSpell.ForcedTarget = {}
        profileSpell.ExcludedTarget = {}
        profileSpell.SelfCast = SelfCast
      end
    else
      profileSpell.Class = profileSpell.Class or {}
      profileSpell.ForcedTarget = profileSpell.ForcedTarget or {}
      profileSpell.ExcludedTarget = profileSpell.ExcludedTarget or {}
    end
  end -- for all profile names
end

---For each spell known to Buffomat check whether the player can use it and the
---category where it will go. Build mapping tables to quickly find spells
---@param buff BomBuffDefinition
function spellSetupModule:Setup_EachBuff(buff)
  allBuffsModule.buffFromSpellIdLookup[buff.buffId] = buff

  self:Setup_EachSpell_CacheUpdate(buff)

  -- GetSpellNames and set default duration
  if buff.highestRankSingleId and not buff.isConsumable then
    self:Setup_EachSpell_SetupNonConsumable(buff)
  end

  if buff.highestRankGroupId then
    self:Setup_EachSpell_SetupGroupBuff(buff)
  end

  -- has Spell? Manacost?
  local add = false

  -- Add single buffs which are known
  if envModule.IsSpellKnown(buff.highestRankSingleId) then
    add = true
    buff.singleMana = 0
    local cost = envModule.GetSpellPowerCost(buff.singleText)

    if type(cost) == "table" then
      for j = 1, #cost do
        if cost[j] and cost[j].name == "MANA" then
          buff.singleMana = cost[j].cost or 0
        end
      end
    end
  end

  -- Add group buffs which are known
  if buff.groupText and envModule.IsSpellKnown(buff.highestRankGroupId) then
    add = true
    buff.groupMana = 0
    -- This returns a table with possibly multiple costs
    -- {  { cost = 970, name = "MANA", type = 0, minCost = 970, requiredAuraID = 0, costPercent = 0, costPerSec = 0 },
    --    { cost = 0, name = "RAGE" }, ... }
    local costsPerEnergyType = envModule.GetSpellPowerCost(buff.highestRankGroupId)

    if type(costsPerEnergyType) == "table" then
      for _i, energyType in ipairs(costsPerEnergyType) do
        if energyType and energyType.name == "MANA" then
          buff.groupMana = energyType.cost or 0
        end
      end
    end
  end

  if buff.isConsumable then
    buff:EnsureDynamicMinLevelSet()
  end

  -- Only do this check if not a consumable group. Keep groups always visible to player
  if not buff.consumeGroupTitle and
      not buffDefinitionModule:CheckDynamicLimitations(buff.limitations) then
    return
    -- Skip the buff entirely, even consumable!
  end

  if buff.isConsumable then
    add = self:Setup_EachSpell_Consumable(add, buff)
  end

  if buff.isInfo then
    add = true
  end

  if add then
    self:Setup_EachBuff_AddKnown(buff)
  end -- if spell is OK to be added
end

---Scan all spells known to Buffomat and see if they are available to the player
function spellSetupModule:SetupAvailableSpells()
  local character = BuffomatCharacter
  for i, profileName in ipairs(profileModule.ALL_PROFILES) do
    character.profiles[profileName].Spell = character.profiles[profileName].Spell or {}
    character.profiles[profileName].CancelBuff = character.profiles[profileName].CancelBuff or {}
    character.profiles[profileName].CurrentBlessing = character.profiles[profileName].CurrentBlessing or
        profileModule:NewBlessingState()
  end

  --Spells selected for the current class/settings/profile etc
  self:Setup_ResetCaches()

  self:Setup_CancelBuffs()

  ---@param buff BomBuffDefinition
  for _buffId, buff in pairs(allBuffsModule.allBuffs) do
    self:Setup_EachBuff(buff)
  end -- for all BOM-supported spells
end

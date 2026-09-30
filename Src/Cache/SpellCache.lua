local BuffomatAddon = BuffomatAddon
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@alias BomSpellCacheKey number|string

---@class BomSpellCache
---@field [BomSpellCacheKey] BomSpellCacheElement

---@class BomSpellCacheModule
---@field cache BomSpellCache Stores arg to results mapping for GetItemInfo

local spellCacheModule = LibStub("Buffomat-SpellCache") --[[@as BomSpellCacheModule]]
spellCacheModule.cache = --[[@as BomSpellCache]] {}

local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]

---@class BomSpellCacheElement
---@field name string
---@field rank string
---@field icon WowIconId
---@field castTime number
---@field minRange number
---@field maxRange number
---@field spellId number

---Calls GetSpellInfo and saves the results, or not (if nil was returned)
---@param arg number|string|nil
---@return BomSpellCacheElement?
---@nodiscard
function BuffomatAddon.GetSpellInfo(arg)
  if spellCacheModule.cache[arg] ~= nil then
    return spellCacheModule.cache[arg]
  end

  local name, rank, icon, castTime, minRange, maxRange, spellId = envModule.GetSpellInfo(arg)
  if name == nil then
    return nil
  end

  name = name or "MISSING NAME"
  icon = icon or "MISSING ICON"

  ---@type BomSpellCacheElement
  local cacheSpell = {
    name     = name,
    rank     = rank,
    icon     = icon,
    castTime = castTime,
    minRange = minRange,
    maxRange = maxRange,
    spellId  = spellId
  }

  spellCacheModule.cache[arg] = cacheSpell
  return cacheSpell
end

---@param arg BomSpellCacheKey
---@nodiscard
function spellCacheModule:HasSpellCached(arg)
  return self.cache[arg] ~= nil
end

---Precache spell and store it
---@param spellId number
---@param onLoaded function Called with loaded BomSpellCacheElement
function spellCacheModule:LoadSpell(spellId, onLoaded)
  if spellCacheModule.cache[spellId] ~= nil then
    onLoaded(spellCacheModule.cache[spellId])
    return
  end

  local spellMixin = Spell:CreateFromSpellID(spellId)

  local cacheSpell = --[[@as BomSpellCacheElement]] {}
  cacheSpell.spellId = spellId

  local spellInfoReady_func = function()
    -- Assume the spell info is loaded here and the response is instant
    local name, rank, icon, castTime, minRange, maxRange, _spellId = envModule.GetSpellInfo(spellId)
    if name == nil then
      return
    end

    cacheSpell.name = spellMixin:GetSpellName()
    --local buffDef = allBuffsModule.allBuffs[spellId]
    --buffDef.name = cacheSpell.name

    cacheSpell.rank = rank
    cacheSpell.icon = icon
    cacheSpell.castTime = castTime
    cacheSpell.minRange = minRange
    cacheSpell.maxRange = maxRange

    self.cache[spellId] = cacheSpell
    throttleModule:RequestTaskRescan(string.format("sp:%d", spellId))

    if onLoaded ~= nil then
      onLoaded(cacheSpell)
    end
  end

  if C_Spell.DoesSpellExist(spellId) then
    spellMixin:ContinueOnSpellLoad(spellInfoReady_func)
  end
end

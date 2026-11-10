local addonName, ns = ...

-- What one scan pass works out: who needs which buff, and the side effects to run.
-- Owned by the pass and reused between passes; the buff definitions stay read-only.

---Who needs one buff.
---@class BomBuffNeed
---@field units BomUnit[] Members who need the buff
---@field groups table<number|ClassName, number> How many need it, per raid subgroup, or per class for a blessing
---@field groupsHaveDead table<number|ClassName, boolean> Subgroups or classes with a dead member who would need it
---@field betterBuff BomUnit[] Members left alone because they have a better buff
---@field reminderText string? Text of a reminder buff's check, shown in its info task

---@class BomScanResult
---@field needs table<BomBuffId, BomBuffNeed> Per buff; records stay and are emptied by Reset
---@field trackingToActivate BomBuffDefinition[] Side effect: tracking spells to switch on
---@field buffsToCancel BomBuffDefinition[] Side effect: buffs on the player to cancel
---@field activeAura BomBuffId? The paladin aura or hunter aspect which is up
---@field activeSeal BomBuffId? The paladin seal which is up
---@field forceTracking WowIconId? The only tracking which may be switched on; nil for any
---@field needsModifierKey boolean A task waits for a modifier key to be held
---@field itemTargets table<BomBuffId, string> Name of the member who has a usable item's buff from the player; kept between passes
local resultClass = {}
resultClass.__index = resultClass

---@class ScanResultModule
local module = LibStub("Buffomat-ScanResult") --[[@as ScanResultModule]]

---@return BomScanResult
function module:New()
  return setmetatable({
    needs = {},
    trackingToActivate = {},
    buffsToCancel = {},
    needsModifierKey = false,
    itemTargets = {},
  }, resultClass)
end

---@param need BomBuffNeed
local function clearNeed(need)
  wipe(need.units)
  wipe(need.groups)
  wipe(need.groupsHaveDead)
  wipe(need.betterBuff)
  need.reminderText = nil
end

---Empty the result for a new pass, keeping its tables.
function resultClass:Reset()
  for _, need in pairs(self.needs) do
    clearNeed(need)
  end
  wipe(self.trackingToActivate)
  wipe(self.buffsToCancel)
  self.activeAura, self.activeSeal, self.forceTracking = nil, nil, nil
  self.needsModifierKey = false
end

---@param buffDef BomBuffDefinition
---@return BomBuffNeed need The record for this buff, empty at the start of a pass
function resultClass:Need(buffDef)
  local need = self.needs[buffDef.buffId]
  if need == nil then
    need = { units = {}, groups = {}, groupsHaveDead = {}, betterBuff = {} }
    self.needs[buffDef.buffId] = need
  end
  return need
end

---Nobody needs this buff after all (it is on cooldown, or cannot be decided).
---@param buffDef BomBuffDefinition
function resultClass:ClearNeed(buffDef)
  clearNeed(self:Need(buffDef))
end

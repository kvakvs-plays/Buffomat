local addonName, ns = ...

-- Player state queries with one contract on every supported client: APIs which
-- exist only from some expansion on, and values Forever can report as secret.

---@class KvPlayerModule
local module = LibStub("KvLibShared-Player") --[[@as KvPlayerModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

local isSecret = envModule.IsSecretValue

---@param value any
---@return boolean True only for a readable true value
local function plainTrue(value)
  return not isSecret(value) and (value == true or value == 1)
end

local isMounted, isFlying, isResting, isStealthed, isOutdoors = IsMounted, _G["IsFlying"], IsResting, IsStealthed,
    IsOutdoors
local unitOnTaxi, unitInVehicle, unitIsDeadOrGhost = UnitOnTaxi, _G["UnitInVehicle"], UnitIsDeadOrGhost

---@return boolean
function module.IsMounted()
  return plainTrue(isMounted())
end

---@return boolean Always false where flying does not exist
function module.IsFlying()
  return isFlying ~= nil and plainTrue(isFlying())
end

---@return boolean
function module.IsResting()
  return plainTrue(isResting())
end

---@return boolean
function module.IsStealthed()
  return plainTrue(isStealthed())
end

---@return boolean
function module.IsOutdoors()
  return plainTrue(isOutdoors())
end

---@return boolean
function module.IsOnTaxi()
  return plainTrue(unitOnTaxi("player"))
end

---@return boolean Always false where vehicles do not exist
function module.IsInVehicle()
  return type(unitInVehicle) == "function" and plainTrue(unitInVehicle("player"))
end

---@return boolean
function module.IsDeadOrGhost()
  return plainTrue(unitIsDeadOrGhost("player"))
end

local getShapeshiftFormID, getShapeshiftForm = GetShapeshiftFormID, GetShapeshiftForm

---@return number? formId Constant such as CAT_FORM; nil in no form
function module.GetShapeshiftFormID()
  local formId = getShapeshiftFormID()
  if isSecret(formId) then
    return nil
  end
  return formId
end

---@return number formIndex Index on the stance bar; 0 in no form
function module.GetShapeshiftForm()
  local form = getShapeshiftForm()
  if isSecret(form) or form == nil then
    return 0
  end
  return form
end

local isInInstance, getInstanceInfo = IsInInstance, GetInstanceInfo

---@alias KvInstanceType "none"|"pvp"|"arena"|"party"|"raid"|"scenario"

---@return KvInstanceType instanceType "none" in the open world
function module.GetInstanceType()
  local _, instanceType = isInInstance()
  if isSecret(instanceType) or instanceType == nil then
    return "none"
  end
  return instanceType
end

---@return number? instanceId Continent or instance map id
function module.GetInstanceId()
  local _name, _instanceType, _difficultyID, _difficultyName, _maxPlayers, _dynamicDifficulty, _isDynamic,
  instanceId = getInstanceInfo()
  if isSecret(instanceId) then
    return nil
  end
  return instanceId
end

local getInventoryItemID, getInventoryItemLink = GetInventoryItemID, GetInventoryItemLink

---@param slot number Inventory slot, such as 16 for the main hand
---@return number? itemId
function module.GetInventoryItemID(slot)
  local itemId = getInventoryItemID("player", slot)
  if isSecret(itemId) then
    return nil
  end
  return itemId
end

---@param slot number Inventory slot
---@return string? link
function module.GetInventoryItemLink(slot)
  local link = getInventoryItemLink("player", slot)
  if isSecret(link) then
    return nil
  end
  return link
end

local isModifierKeyDown, isAltKeyDown = IsModifierKeyDown, IsAltKeyDown

---@return boolean held Any of the Shift / Ctrl / Alt keys
function module.IsModifierKeyDown()
  return plainTrue(isModifierKeyDown())
end

---@return boolean
function module.IsAltKeyDown()
  return plainTrue(isAltKeyDown())
end

local getNetStats = GetNetStats

---@return number seconds Home plus world latency
function module.GetLatency()
  local _down, _up, lagHome, lagWorld = getNetStats()
  if isSecret(lagHome) or isSecret(lagWorld) then
    return 0
  end
  return ((lagHome or 0) + (lagWorld or 0)) / 1000
end

local debugProfileStop = _G["debugprofilestop"]

---@return number milliseconds High resolution clock for measuring code; 0 where the client has none
function module.GetProfileTime()
  return debugProfileStop and debugProfileStop() or 0
end

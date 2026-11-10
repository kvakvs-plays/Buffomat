local addonName, ns = ...

-- The bag reader. One walk over every bag slot builds an index by item id; all item
-- questions of a scan are then table lookups. Cooldowns are read only for the items
-- somebody asks about, once per cooldown change.

---@class BomBagItem
---@field itemId WowItemId
---@field count number Total in all bags
---@field bag number Bag of the first stack found
---@field slot number Slot of the first stack found
---@field link string
---@field texture WowIconId
---@field cooldownStart number Valid when cooldownVersion matches the module's
---@field cooldownDuration number
---@field cooldownVersion number

---@class BagScanModule
---@field version number Changes when the bag contents or an item cooldown changed
---@field cooldownVersion number Changes when item cooldowns have to be read again
---@field byItemId table<WowItemId, BomBagItem> Every item in the bags
---@field openable BomBagItem[] Containers that can be opened, one entry per bag slot
---@field signature number Checksum of the last walk, to tell a real change from a repeated event
---@field readWithOpenLootable boolean? Value of the OpenLootable option at the last walk
local module = LibStub("Buffomat-BagScan") --[[@as BagScanModule]]

local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local scheduler = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local scanStatsModule = LibStub("Buffomat-ScanStats") --[[@as ScanStatsModule]]

module.version = 0
module.cooldownVersion = 1
module.byItemId = {}
module.openable = {}
module.signature = -1

local pool = {} ---@type BomBagItem[] Records of the previous walk, reused by the next

---@param itemId WowItemId
---@param count number
---@param bag number
---@param slot number
---@param link string
---@param texture WowIconId
---@return BomBagItem
local function newItem(itemId, count, bag, slot, link, texture)
  local item = table.remove(pool) or {}
  item.itemId, item.count, item.bag, item.slot, item.link, item.texture = itemId, count, bag, slot, link, texture
  item.cooldownVersion = 0
  return item
end

---@param itemId WowItemId
---@param hasLoot boolean
---@return boolean
function module:IsOpenable(itemId, hasLoot)
  return hasLoot
      -- Since Cataclysm, clams are not "lootable" but have an "open" spell attached
      or itemId == itemIdsModule.Classic_BigmouthClam
      or itemId == itemIdsModule.TBC_JaggalClam
      or itemId == itemIdsModule.WotLK_DarkwaterClam
      or itemId == itemIdsModule.Cataclysm_AbyssalClam
end

---The list of openable containers depends on an option, so the option changing means
---the bags have to be walked again.
---@return boolean
function module:NeedsRead()
  return self.readWithOpenLootable ~= (BuffomatShared.OpenLootable == true)
end

---Walk every bag slot once and rebuild the index.
---@return boolean changed False when the bags hold exactly what they held at the last walk
function module:Read()
  scanStatsModule:Count("bagScans")
  local byItemId, openable = self.byItemId, self.openable
  for itemId, item in pairs(byItemId) do
    pool[#pool + 1] = item
    byItemId[itemId] = nil
  end
  for index = #openable, 1, -1 do
    pool[#pool + 1] = openable[index]
    openable[index] = nil
  end

  local openLootable = BuffomatShared.OpenLootable == true
  local signature = openLootable and 1 or 0
  for bagIndex, bag in ipairs(envModule.playerBagIds) do
    local slots = envModule.GetContainerNumSlots(bag) or 0
    scanStatsModule:Count("bagSlotReads", slots)
    for slot = 1, slots do
      local itemId, count, link, texture, hasLoot = envModule.ReadContainerItem(bag, slot)
      if itemId then
        signature = signature + itemId * (bagIndex * 100 + slot) + count * 7
        local item = byItemId[itemId]
        if item then
          item.count = item.count + count
        else
          byItemId[itemId] = newItem(itemId, count, bag, slot, link, texture)
        end
        if openLootable and self:IsOpenable(itemId, hasLoot)
            and not envModule.IsContainerItemLockedBox(bag, slot) then
          openable[#openable + 1] = newItem(itemId, count, bag, slot, link, texture)
          signature = signature + slot
        end
      end
    end
  end

  self.readWithOpenLootable = openLootable
  if signature == self.signature then
    return false
  end
  self.signature = signature
  self.version = self.version + 1
  return true
end

---Item cooldowns changed: read them again when somebody asks.
function module:InvalidateCooldowns()
  self.cooldownVersion = self.cooldownVersion + 1
  self.version = self.version + 1
end

---@param itemId WowItemId?
---@return BomBagItem? item Nil when the player has none in the bags
function module:Find(itemId)
  return itemId ~= nil and self.byItemId[itemId] or nil
end

---@param itemId WowItemId
---@return number count Total in all bags
function module:Count(itemId)
  local item = self.byItemId[itemId]
  return item and item.count or 0
end

---@param item BomBagItem
---@return number? startTime Nil when the client hides the cooldown
---@return number? duration
function module:GetCooldown(item)
  if item.cooldownVersion ~= self.cooldownVersion then
    scanStatsModule:Count("cooldownReads")
    item.cooldownStart, item.cooldownDuration = envModule.GetContainerItemCooldown(item.bag, item.slot)
    item.cooldownVersion = self.cooldownVersion
  end
  return item.cooldownStart, item.cooldownDuration
end

---Whether the item can be used now. While it is on cooldown, the scheduler is asked to
---look again when the cooldown ends.
---@param item BomBagItem
---@return boolean
function module:IsReady(item)
  local startTime, duration = self:GetCooldown(item)
  if (startTime or 0) == 0 then
    return true
  end
  scheduler:WakeAt(startTime + (duration or 0), "bagCooldowns")
  return false
end

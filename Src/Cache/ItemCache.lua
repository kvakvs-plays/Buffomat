local BuffomatAddon = BuffomatAddon
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@alias BomItemCacheKey number|string

---@class BomItemCache
---@field [BomItemCacheKey] BomItemCacheElement
---@field Item2 table

---@class BomItemCacheModule
---@field cache BomItemCache Stores arg to results mapping for GetItemInfo

local itemCacheModule = LibStub("Buffomat-ItemCache") --[[@as BomItemCacheModule]]
itemCacheModule.cache = {}
local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]

---@class BomItemCacheElement
---@field itemName string
---@field itemLink string Printable colored clickable item link
---@field itemRarity number 0=poor, 1=normal, 2=uncommon, 3=rare ... etc
---@field itemLevel number
---@field itemMinLevel number
---@field itemType string One of "Armor", "Consumable", "Container", ... see Wiki "ItemType"
---@field itemSubType string Same as itemType
---@field itemStackCount number
---@field itemEquipLoc string "" or a constant INVTYPE_HEAD for example
---@field itemTexture string Texture or icon id
---@field itemSellPrice number Copper price for the item
---@field itemClassID number Numeric ID of itemType
---@field itemSubClassID number Numeric ID of itemSubType

---Calls GetItemInfo and saves the results, or not (if nil was returned).
---Immediate result is returned right away. Caches the data.
---@param arg number|string|WowItemId
---@return BomItemCacheElement|nil
function BuffomatAddon.GetItemInfo(arg)
  if itemCacheModule.cache[arg] ~= nil then
    return itemCacheModule.cache[arg]
  end

  local itemName, itemLink, itemRarity, itemLevel, itemMinLevel, itemType
  , itemSubType, itemStackCount, itemEquipLoc, itemTexture, itemSellPrice
  , itemClassID, itemSubClassID = envModule.GetItemInfo(arg)
  if itemName == nil then
    return nil
  end

  local cacheItem = --[[@as BomItemCacheElement]] {
    itemName = itemName,
    itemLink = itemLink,
    itemRarity = itemRarity,
    itemLevel = itemLevel,
    itemMinLevel = itemMinLevel,
    itemType = itemType,
    itemSubType = itemSubType,
    itemStackCount = itemStackCount,
    itemEquipLoc = itemEquipLoc,
    itemTexture = itemTexture,
    itemSellPrice = itemSellPrice,
    itemClassID = itemClassID,
    itemSubClassID = itemSubClassID
  }

  --print("Added to cache item info for ", arg)
  itemCacheModule.cache[arg] = cacheItem
  return cacheItem
end

---@param arg BomItemCacheKey
function itemCacheModule:HasItemCached(arg)
  return self.cache[arg] ~= nil
end

---Queries GetItemInfo with delayed result (asynchronous callback). Caches the data.
---Delayed result, suitable for querying large quantities of items (like on addon startup).
---@param itemId number
---@param onLoaded function Called with loaded BomItemCacheElement
function itemCacheModule:LoadItem(itemId, onLoaded)
  if itemCacheModule.cache[itemId] ~= nil then
    onLoaded(itemCacheModule.cache[itemId])
    return
  end

  local itemMixin = Item:CreateFromItemID(itemId)

  local itemLoaded = function()
    local itemName, _itemLink, _itemRarity, itemLevel, itemMinLevel, itemType
    , itemSubType, itemStackCount, itemEquipLoc, _itemTexture, itemSellPrice
    , itemClassID, itemSubClassID = envModule.GetItemInfo(itemId)
    if itemName == nil then
      return
    end

    local cacheItem = --[[@as BomItemCacheElement]] {
      itemName = itemMixin:GetItemName(),
      itemLink = itemMixin:GetItemLink(),
      itemRarity = itemMixin:GetItemQuality(),
      itemLevel = itemLevel,
      itemMinLevel = itemMinLevel,
      itemType = itemType,
      itemSubType = itemSubType,
      itemStackCount = itemStackCount,
      itemEquipLoc = itemEquipLoc,
      itemTexture = itemMixin:GetItemIcon(),
      itemSellPrice = itemSellPrice,
      itemClassID = itemClassID,
      itemSubClassID = itemSubClassID
    }

    itemCacheModule.cache[itemId] = cacheItem
    throttleModule:RequestTaskRescan(string.format("item%d", itemId))

    if onLoaded ~= nil then
      onLoaded(cacheItem)
    end
  end

  if C_Item.DoesItemExistByID(itemId) then
    itemMixin:ContinueOnItemLoad(itemLoaded)
  else
    --BOM:Print("Item does not exist: " .. itemId)
  end
end
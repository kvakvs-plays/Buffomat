local BuffomatAddon = BuffomatAddon

---@class BomItemListCacheModule

local itemListCacheModule = LibStub("Buffomat-ItemListCache") --[[@as BomItemListCacheModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

BuffomatAddon.wipeCachedItems = true

---@class GetContainerItemInfoResult
---@field Index number
---@field ID number
---@field CD table
---@field Link string
---@field Bag number
---@field Slot number
---@field Lootable boolean
---@field Texture WowIconId

---@alias BomInventory GetContainerItemInfoResult[]
-- alternative type? {[number]: GetContainerItemInfoResult}

-- Stores copies of GetContainerItemInfo parse results
local itemListCache = --[[@as BomInventory]] {}

---@return boolean
---@nodiscard
function itemListCacheModule:IsOpenable(itemInfo)
  return itemInfo and (
    itemInfo.hasLoot
    -- Since Cataclysm, clams seem to not be "lootable" but they have an "open" spell attached.
    or itemInfo.itemID == itemIdsModule.Classic_BigmouthClam
    or itemInfo.itemID == itemIdsModule.TBC_JaggalClam
    or itemInfo.itemID == itemIdsModule.WotLK_DarkwaterClam
    or itemInfo.itemID == itemIdsModule.Cataclysm_AbyssalClam
  )
end

---@return BomInventory
---@nodiscard
function itemListCacheModule:GetItemList()
  if BuffomatAddon.wipeCachedItems then
    wipe(itemListCache)
    BuffomatAddon.wipeCachedItems = false

    for _, bag in ipairs(envModule.playerBagIds) do
      for slot = 1, envModule.GetContainerNumSlots(bag) do
        --local itemID = GetContainerItemID(bag,slot)
        local itemInfo = envModule.GetContainerItemInfo(bag, slot)

        if itemInfo then
          for iList, list in ipairs(BuffomatAddon.itemList) do
            if tContains(list, itemInfo.itemID) then
              table.insert(itemListCache, --[[@as GetContainerItemInfoResult]] {
                Index = iList,
                ID = itemInfo.itemID,
                CD = {},
                Link = itemInfo.hyperlink,
                Bag = bag,
                Slot = slot,
                Texture = itemInfo.iconFileID
              })
            end
          end -- for itemList

          if self:IsOpenable(itemInfo) and BuffomatShared.OpenLootable then
            local locked = false

            for i, text in ipairs(toolboxModule:ScanToolTip("SetBagItem", bag, slot)) do
              if text == LOCKED then
                locked = true
                break
              end
            end

            if not locked then
              table.insert(itemListCache, --[[@as GetContainerItemInfoResult]] {
                Index = 0,
                ID = itemInfo.itemID,
                CD = nil,
                Link = itemInfo.hyperlink,
                Bag = bag,
                Slot = slot,
                Lootable = true,
                Texture = itemInfo.iconFileID
              })
            end -- not locked
          end   -- lootable & sharedState.openLootable
        end     -- if itemInfo
      end       -- for all bag slots in the current bag
    end         -- for all bags
  end

  --Update CD
  for i, items in ipairs(itemListCache) do
    if items.CD then
      items.CD = { envModule.GetContainerItemCooldown(items.Bag, items.Slot) }
    end
  end

  return itemListCache
end
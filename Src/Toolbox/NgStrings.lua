---@class NgStringsModule
local module = LibStub("Buffomat-NgStrings") --[[@as NgStringsModule]]

local constModule = LibStub("Buffomat-Const")

---Creates a string which will display a picture in a FontString
---@param texture WowIconId - path to UI texture file (for example can come from C_Container.GetContainerItemInfo(bag, slot) or spell info etc
function module:FormatTexture(texture)
  return string.format(constModule.ICON_FORMAT, texture)
end

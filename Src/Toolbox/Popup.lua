---@class PopupModule

local popupModule = LibStub("Buffomat-Popup") --[[@as PopupModule]]
local libDD = LibStub("LibUIDropDownMenu-4.0")

---@class GPIPopupDynamic
---@field _Frame Frame Popup currently open in the game (to see if its our popup or not)
---@field _where string Where the popup was displayed (cursor, mouse, center)
---@field _x number X offset where it was displayed
---@field _y number Y offset where it was displayed
local popupDynamicClass = {}
popupDynamicClass.__index = popupDynamicClass

---@class BomGPIControlPopup: Frame

---@return BomMenuItemDef
function popupModule:Separator()
  local newSep = --[[@as BomMenuItemDef]] {}
  newSep.type = "separator"
  return newSep
end

---@return BomMenuItemDef
function popupModule:Clickable(text, onClick, arg1, arg2)
  local newClickable = --[[@as BomMenuItemDef]] {}
  newClickable.text = text or ""
  newClickable.type = "click"
  newClickable.onClick = onClick
  newClickable.arg1 = arg1
  newClickable.arg2 = arg2
  return newClickable
end

---@type BomMenuItemType "separator"|"submenu"|"click"|"boolean"

---@class BomMenuItemDef
---@field text string
---@field type BomMenuItemType
---@field level number
---@field nested BomMenuItemDef[]
---@field value any
---@field arg1 any
---@field arg2 any

---@return BomMenuItemDef
---@param invertLogic boolean|nil
function popupModule:Boolean(text, dict, key, invertLogic)
  local newItem = --[[@as BomMenuItemDef]] {}
  newItem.text = text or ""
  newItem.type = "boolean"
  newItem.value = dict
  newItem.arg1 = key
  newItem.arg2 = invertLogic
  return newItem
end

---@return BomMenuItemDef
---@param level number
---@param nested BomMenuItemDef[]
function popupModule:SubMenu(text, level, nested)
  local subMenu = --[[@as BomMenuItemDef]] {}
  subMenu.text = text
  subMenu.type = "submenu"
  subMenu.level = level
  subMenu.nested = nested
  return subMenu
end

local popupLastWipeName ---@type string|nil

---@param WipeName string|nil
function popupDynamicClass:Wipe(WipeName)
  wipe(self._Frame.bomMenuItems)

  if UIDROPDOWNMENU_OPEN_MENU == self._Frame then
    libDD:ToggleDropDownMenu(nil, nil, self._Frame, self._where, self._x, self._y)
    if WipeName == popupLastWipeName then
      return false
    end
  end

  popupLastWipeName = WipeName
  return true
end

---@alias BomMenuItemType "separator"|"submenu"|"click"|"boolean" Submenu=nested, click=call onClick handler, boolean=toggle self.value[arg1]

---@class WowPopupMenuItem
---@field type BomMenuItemType
---@field text string
---@field notCheckable boolean
---@field checked boolean
---@field disabled boolean
---@field value any
---@field arg1 any
---@field arg2 any
---@field func function|nil
---@field hasArrow boolean
---@field menuList any
---@field keepShownOnClick boolean

---@param menuItemDef BomMenuItemDef
local function generateSubmenu(level, menuItemDef)
  ---@type WowPopupMenuItem
  local info = {}
  info.text = menuItemDef.text
  info.notCheckable = true
  info.disabled = false
  info.hasArrow = true
  info.menuList = menuItemDef.nested
  libDD:UIDropDownMenu_AddButton(info, level)
end

---@param level number
local function generateMenuSeparator(level)
  -- -@type WowPopupMenuItem
  -- local info = {}
  -- info.disabled = true
  -- info.notCheckable = true
  libDD:UIDropDownMenu_AddSeparator(level)
end

---@param level number
---@param frame BomGPIControl
---@param menuItemDef BomMenuItemDef
local function generateClickableMenuItem(level, frame, menuItemDef)
  ---@type WowPopupMenuItem
  local info = {}
  info.text = menuItemDef.text
  info.notCheckable = true
  --info.keepShownOnClick = (val.disabled == "keep")
  info.value = menuItemDef.onClick
  info.arg1 = menuItemDef.arg1
  info.arg2 = menuItemDef.arg2
  info.func = function(menuItm, a1, a2, chk)
    menuItm.value(a1, a2)
  end
  info.hasArrow = false
  libDD:UIDropDownMenu_AddButton(info, level)
end

---@param level number
---@param menuItemDef BomMenuItemDef
local function generateBooleanMenuItem(level, menuItemDef)
  ---@type WowPopupMenuItem
  local info = {}
  info.text = menuItemDef.text
  info.value = menuItemDef.value
  info.arg1 = menuItemDef.arg1
  info.arg2 = menuItemDef.arg2
  info.checked = menuItemDef.arg2 and not menuItemDef.value[menuItemDef.arg1] or menuItemDef.value[menuItemDef.arg1]
  info.func = function(menuItm, a1, a2, chk)
    menuItm.value[a1] = not menuItm.value[a1]
    local buffomatModule = LibStub("Buffomat-Buffomat") ---@type BuffomatModule
    if menuItm.arg1 == "hide" and buffomatModule and buffomatModule.libIcon then
      if menuItm.value[a1] then -- if hide is true
        buffomatModule.libIcon:Hide("BuffomatIcon")
      else -- if hide is false
        buffomatModule.libIcon:Show("BuffomatIcon")
      end
    end
  end
  info.hasArrow = false
  libDD:UIDropDownMenu_AddButton(info, level)
end

---Called implicitly by libDD:UIDropDownMenu_Initialize
---@param frame BomGPIControl
---@param menuList nil|BomMenuItemDef[]
function popupModule.GenerateMenuItems(frame, level, menuList)
  if level == nil then
    return
  end

---@diagnostic disable-next-line: unused-local
  for _index, menuItemDef in ipairs(menuList or frame.bomMenuItems) do
    --if val.menuDepth == menuList then
    if menuItemDef.type == "submenu" then
      generateSubmenu(level, menuItemDef)                  -- Submenu entry
    elseif menuItemDef.type == "click" then
      generateClickableMenuItem(level, frame, menuItemDef) -- Normal menu item, with click handler
    elseif menuItemDef.type == "boolean" then
      generateBooleanMenuItem(level, menuItemDef)          -- Menu item which toggles a boolean value
    elseif menuItemDef.type == "separator" then
      generateMenuSeparator(level)                         -- Just a narrow empty row
    end
    --end
  end
end

function popupDynamicClass:Show(where, x, y)
  where = where or "cursor"
  if UIDROPDOWNMENU_OPEN_MENU ~= self._Frame then
    libDD:UIDropDownMenu_Initialize(self._Frame, popupModule.GenerateMenuItems, "MENU",
      nil, self._Frame.bomMenuItems)
  end
  libDD:ToggleDropDownMenu(nil, nil, self._Frame, where, x, y)
  self._where = where
  self._x = x
  self._y = y
end

function popupDynamicClass:SetMenuItems(items)
  self._Frame.bomMenuItems = items
end

---@return GPIPopupDynamic
---@param callbackFn function
function popupModule:CreatePopup(callbackFn)
  local popup = {} --[[@as GPIPopupDynamic]]
  setmetatable(popup, popupDynamicClass)

  --popup._Frame = CreateFrame("Frame", nil, UIParent, "UIDropDownMenuTemplate") ---@type BomGPIControl
  popup._Frame = libDD:Create_UIDropDownMenu("BuffomatDropDownMenu", UIParent)
  popup._Frame.bomPopupMenuCallback = callbackFn
  popup._Frame.bomMenuItems = {} --[[@as BomMenuItemDef[] ]]
  return popup
end

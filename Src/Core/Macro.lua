local BuffomatAddon = BuffomatAddon
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class MacroModule
---@field lastMacroSet string A cached value of the last macro set

local macroModule = LibStub("Buffomat-Macro") --[[@as MacroModule]]
macroModule.lastMacroSet = ''

local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]

---@class BomMacro
---@field name string Macro name, default Buff'o'mat
---@field icon string Texture path to macro icon
---@field lines string[] Lines of the macro
local macroClass = {}
macroClass.__index = macroClass

---Creates a new Macro
---@param name string
---@param lines string[]|nil
---@return BomMacro
function macroModule:NewMacro(name, lines)
  local fields = --[[@as BomMacro]] {}
  fields.name  = name
  fields.lines = lines or {}

  setmetatable(fields, macroClass)
  return fields
end

function macroModule:IsMacroFrameOpen()
  return MacroFrame and MacroFrame:IsShown()
end

function macroClass:Clear()
  if InCombatLockdown() then
    return
  end
  if macroModule:IsMacroFrameOpen() then
    -- Fixes the bug when macro editor was constantly reset by Buffomat
    return
  end

  if not self:EnsureExists() then
    return
  end
  self.lines = {}
  self.icon = constModule.MACRO_ICON_DISABLED

  -- Prevent resetting to empty multiple times
  if macroModule.lastMacroSet ~= "" then
    EditMacro(self.name, nil, self.icon, "")
    macroModule.lastMacroSet = ""
  end
end

---@return string
---@nodiscard
function macroClass:GetText()
  local t = "#showtooltip\n/bom update\n/bom _checkforerror"
  for _, line in ipairs(self.lines) do
    t = t .. "\n" .. line
  end
  return t
end

function macroClass:UpdateMacro()
  if not self:EnsureExists() then
    return
  end
  local icon = self.icon or constModule.MACRO_ICON
  local newText = self:GetText()

  -- Prevent multiple times setting macro to the same value
  if macroModule.lastMacroSet ~= newText then
    EditMacro(self.name, nil, icon, newText)
    --BOM.minimapButton:SetTexture("Interface\\ICONS\\" .. icon)
    macroModule.lastMacroSet = newText
  end
end

---Prefer a character slot, then an account slot; never create in combat.
---@return boolean exists False when creation is blocked or capacity is unavailable.
function macroClass:EnsureExists()
  if InCombatLockdown() then
    return false
  end
  if GetMacroInfo(self.name) ~= nil then
    return true
  end

  local perAccount, perChar = GetNumMacros()
  local accountLimit, characterLimit = envModule.GetMacroLimits()
  local isChar
  if characterLimit ~= nil and perChar < characterLimit then
    isChar = true
  elseif accountLimit ~= nil and perAccount < accountLimit then
    isChar = false
  else
    if accountLimit ~= nil and characterLimit ~= nil then
      BuffomatAddon:Print(_t("castButton.NoMacroSlots"))
    end
    return false
  end

  local index = CreateMacro(self.name, constModule.MACRO_ICON, "", isChar)
  if index == nil or index == 0 then
    return false
  end
  -- Creation invalidates the cached body even if the old macro had the same text.
  macroModule.lastMacroSet = ""
  return true
end

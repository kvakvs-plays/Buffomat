local BuffomatAddon = BuffomatAddon

---@class MacroModule
---@field lastMacroSet string A cached value of the last macro set

local macroModule = LibStub("Buffomat-Macro") --[[@as MacroModule]]
macroModule.lastMacroSet = ''

local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
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

  self:EnsureExists()
  self.lines = {}
  self.icon = constModule.MACRO_ICON_DISABLED

  -- Prevent resetting to empty multiple times
  if macroModule.lastMacroSet ~= "" then
    EditMacro(constModule.MACRO_NAME, nil, self.icon, "")
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
  local icon = self.icon or constModule.MACRO_ICON
  local newText = self:GetText()

  -- Prevent multiple times setting macro to the same value
  if macroModule.lastMacroSet ~= newText then
    EditMacro(constModule.MACRO_NAME, nil, icon, newText)
    --BOM.minimapButton:SetTexture("Interface\\ICONS\\" .. icon)
    macroModule.lastMacroSet = newText
  end
end

function macroClass:EnsureExists()
  if (GetMacroInfo(constModule.MACRO_NAME)) == nil then
    local perAccount, perChar = GetNumMacros()
    local isChar

    if perChar < envModule.MAX_CHARACTER_MACROS then
      isChar = 1
    elseif perAccount >= envModule.MAX_ACCOUNT_MACROS then
      BuffomatAddon:Print(_t("castButton.NoMacroSlots"))
      return
    end

    CreateMacro(self.name, constModule.MACRO_ICON, "", isChar)
  end
end
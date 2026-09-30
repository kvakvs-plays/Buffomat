-- Run from the repository root: lua Tests/MacroCompatibilityTest.lua
local function loadModule(path, globals)
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, globals)
  else
    chunk = assert(loadfile(path, "t", globals))
  end
  chunk("BuffomatClassic", {})
end

local function equal(actual, expected, label)
  assert(actual == expected, label or "unexpected value")
end

local function fixture(mode)
  local libs = {}
  local state = { account = 0, character = 0, creates = 0, edits = 0, messages = 0 }
  local globals = setmetatable({
    WOW_PROJECT_ID = 1,
    UnitClass = function() return "Hunter", "HUNTER" end,
    InCombatLockdown = function() return state.combat end,
    GetNumMacros = function() return state.account, state.character end,
    GetMacroInfo = function(name)
      if state.exists then return name, "icon", state.body end
    end,
    CreateMacro = function(name, _, body, isCharacter)
      assert(not state.combat, "created a macro in combat")
      state.creates = state.creates + 1
      if state.fail then return state.failureResult end
      state.exists, state.isCharacter, state.body, state.name = true, isCharacter, body, name
      return 1
    end,
    EditMacro = function(name, _, _, body)
      assert(not state.combat, "edited a macro in combat")
      assert(state.exists, "edited a nonexistent macro")
      equal(name, state.name)
      state.edits, state.body = state.edits + 1, body
    end,
    BuffomatAddon = { Print = function() state.messages = state.messages + 1 end },
    wipe = function(values) for key in pairs(values) do values[key] = nil end end,
    LibStub = function(name)
      libs[name] = libs[name] or {}
      return libs[name]
    end,
  }, { __index = _G })
  globals._G = globals
  if mode == "modern" or mode == "mixed" then
    globals.Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 4, MAX_CHARACTER_MACROS = 2 } }
  end
  if mode == "legacy" or mode == "mixed" then
    globals.MAX_ACCOUNT_MACROS = mode == "mixed" and 40 or 4
    globals.MAX_CHARACTER_MACROS = mode == "mixed" and 20 or 2
  end
  loadModule("Src/KvLib/KvEnv.lua", globals)
  loadModule("Src/Core/Macro.lua", globals)
  loadModule("Src/Task/TaskList.lua", globals)
  loadModule("Src/Task/ActionMacro.lua", globals)
  setmetatable(libs["Buffomat-Languages"], { __call = function(_, key) return key end })
  local constants = libs["Buffomat-Const"]
  constants.MACRO_ICON, constants.MACRO_ICON_DISABLED = "icon", "disabled"
  local macro = libs["Buffomat-Macro"]:NewMacro("Buff'o'mat", { "/cast Test" })
  globals.BuffomatAddon.theMacro = macro
  return macro, state, globals, libs
end

for _, mode in ipairs({ "legacy", "modern", "mixed" }) do
  local macro, state, _, libs = fixture(mode)
  equal(macro:EnsureExists(), true)
  equal(state.isCharacter, true, "prefer character slots")
  macro:UpdateMacro()
  equal(state.edits, 1)
  macro:UpdateMacro()
  equal(state.creates, 1); equal(state.edits, 1)

  state.exists = false
  macro:UpdateMacro()
  equal(state.creates, 2); equal(state.edits, 2, "restore body after macro deletion")
  state.exists, state.character = false, 2
  equal(macro:EnsureExists(), true)
  equal(state.isCharacter, false, "fall back to account slots")

  state.exists, state.account = false, 4
  local creates, edits = state.creates, state.edits
  libs["Buffomat-TaskList"]:WipeMacro()
  equal(state.messages, 1)
  libs["Buffomat-ActionMacro"]:WipeMacro()
  equal(state.messages, 2)
  macro:UpdateMacro()
  equal(state.creates, creates); equal(state.edits, edits)

  -- Existing macros can be edited even when all slots are occupied.
  state.exists = true
  libs["Buffomat-TaskList"]:WipeMacro("/stopmacro")
  equal(state.body, "#showtooltip\n/bom update\n/bom _checkforerror\n/stopmacro")
  macro:Clear()
  equal(state.body, "")

  creates, edits = state.creates, state.edits
  state.combat = true
  macro:UpdateMacro()
  macro:Clear()
  libs["Buffomat-TaskList"]:WipeMacro()
  libs["Buffomat-ActionMacro"]:WipeMacro()
  state.exists = false
  equal(macro:EnsureExists(), false)
  equal(state.creates, creates); equal(state.edits, edits)
  state.combat, state.account, state.character = false, 0, 0
  macro:UpdateMacro()
  equal(state.creates, creates + 1); equal(state.edits, edits + 1)
  print("PASS: " .. mode .. " macro limits, capacity, recreation, and combat guards")
end

for _, failure in ipairs({ "nil", "zero" }) do
  local macro, state, _, libs = fixture("modern")
  state.fail = true
  state.failureResult = failure == "zero" and 0 or nil
  libs["Buffomat-TaskList"]:WipeMacro()
  equal(state.creates, 1, "do not retry failed creation in the same wipe")
  macro:UpdateMacro()
  macro:Clear()
  equal(state.edits, 0)
end
print("PASS: failed macro creation never triggers an edit")

do
  local macro, state, globals, libs = fixture("unavailable")
  macro:UpdateMacro()
  equal(state.creates, 0); equal(state.edits, 0)
  -- Limits can become available after module initialization.
  globals.Constants = { MacroConsts = { MAX_CHARACTER_MACROS = 2 } }
  libs["Buffomat-TaskList"]:WipeMacro()
  equal(state.creates, 1); equal(state.edits, 1)
  globals.Constants = nil
  macro:Clear()
  equal(state.edits, 2, "existing macros work without limits")
  globals.Constants = { MacroConsts = { MAX_CHARACTER_MACROS = 0 } }
  globals.MAX_CHARACTER_MACROS = 20
  globals.MAX_ACCOUNT_MACROS = 4
  state.exists = false
  equal(macro:EnsureExists(), true)
  equal(state.isCharacter, false, "zero modern limit overrides legacy character capacity")
end
print("PASS: unavailable, late-loaded, and partial macro limits")

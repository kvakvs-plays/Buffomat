-- Run from the repository root: lua Tests/SlashCommandsTest.lua
-- The slash commands chosen in the options: registration, the command in the macro, upgrades.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local function setup()
  local f = fixture.new({})
  f.globals.SlashCmdList = {}
  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/Toolbox/SlashCommands.lua")
  f:load("Src/Core/Macro.lua")
  return f, f:lib("Buffomat-SlashCommands")
end

do
  local f, slash = setup()
  local settings = {}

  -- Settings saved before the options existed get the commands Buffomat always had
  slash:UpgradeSettings(settings)
  equal(settings.SlashCommandBom, true); equal(settings.SlashCommandBfm, false)
  equal(settings.SlashCommandBuffomat, true)
  equal(table.concat(slash:ChosenCommands(settings), ","), "/bom,/buffomat")

  -- A choice the user made is kept
  settings.SlashCommandBom = false
  slash:UpgradeSettings(settings)
  equal(settings.SlashCommandBom, false)

  -- Shortest first, and never none
  settings.SlashCommandBfm = true
  equal(table.concat(slash:ChosenCommands(settings), ","), "/bfm,/buffomat")
  settings.SlashCommandBfm, settings.SlashCommandBuffomat = false, false
  equal(table.concat(slash:ChosenCommands(settings), ","), "/buffomat", "with none chosen /buffomat stays")

  -- Registration: every chosen command, and the shortest is the one used in the macro and hints
  settings.SlashCommandBfm, settings.SlashCommandBuffomat = true, true
  slash:RegisterSlashCommandHandler(slash:ChosenCommands(settings), {})
  local prefix = "SLASH_BuffomatClassic"
  equal(f.globals[prefix .. "1"], "/bfm"); equal(f.globals[prefix .. "2"], "/buffomat")
  equal(f.globals[prefix .. "3"], nil)
  equal(type(f.globals.SlashCmdList.BuffomatClassic), "function")
  equal(slash.mainCommand, "/bfm")
  equal(slash:WithMainCommand("Type /bom to show"), "Type /bfm to show")

  local macro = f:lib("Buffomat-Macro"):NewMacro("Buff'o'mat", { "/cast X" })
  equal(macro:GetText(), "#showtooltip\n/bfm update\n/bfm _checkforerror\n/cast X")
  print("PASS: slash commands chosen in the options")
end

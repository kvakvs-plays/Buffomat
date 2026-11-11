-- Run from the repository root: lua Tests/WhatsNewTest.lua
-- The What's new window's texts: the welcome message with its chat link, the option, and how a
-- changelog point is shown. The window itself needs the game's frames and is not tested here.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local LINK = "|cff71d5ff|Haddon:BuffomatClassic:whatsnew|h[What's new]|h|r"

local function setup()
  local f = fixture.new({})
  local printed = {}
  f.globals.SlashCmdList = {}
  f.globals.BuffomatShared = {}
  f.globals.BuffomatAddon.Print = function(_, text) printed[#printed + 1] = text end
  f.globals.hooksecurefunc = function(name, hook) f.hooks = f.hooks or {}; f.hooks[name] = hook end

  f:load("Src/KvLib/KvEnv.lua")
  f:load("Src/Toolbox/SlashCommands.lua")
  f:load("Src/Languages/English.lua")
  local english = f:lib("Buffomat-LanguageEnglish"):Translations()
  setmetatable(f:lib("Buffomat-Languages"), { __call = function(_, key) return english[key] or ("?" .. key) end })
  f:lib("Buffomat-Const").TOC_VERSION = "2026.11.5-abcdef12"
  f:lib("Buffomat-Const").SHORT_TITLE = "Buffomat"
  f:lib("Buffomat-Changelog").releases = {
    { version = "2026.11.5", items = { { "Lead.", "Text" }, { "Nested.", "More", 1 } } },
    { version = "2026.11.4", items = { { "Old.", "Thing" } } },
  }
  f:load("Src/Ui/WhatsNew.lua")
  return f, f:lib("Buffomat-WhatsNew"), printed
end

do
  local f, whatsNew = setup()

  -- The git hash which the build adds to the TOC version is not shown and not compared
  equal(whatsNew:Version(), "2026.11.5")
  equal(whatsNew:ChatLink(), LINK)
  equal(whatsNew:CountChanges(), 3)

  -- Never opened, opened for an older version, opened for this version
  equal(whatsNew:WelcomeText(nil),
    "|cffffffffv2026.11.5|r installed. See what it does: " .. LINK .. " or /bom changes")
  equal(whatsNew:WelcomeText("2026.11.4"),
    "Updated to |cffffffffv2026.11.5|r. See what changed: " .. LINK .. " or /bom changes")
  equal(whatsNew:WelcomeText("2026.11.5"), "|cffffffffv2026.11.5|r loaded. " .. LINK)

  -- The hint names the chat command the user chose in the options
  f:lib("Buffomat-SlashCommands").mainCommand = "/bfm"
  equal(whatsNew:WelcomeText(nil):match("or (.+)$"), "/bfm changes")
  print("PASS: welcome message for a new, an updated and a seen version")
end

do
  local f, whatsNew, printed = setup()
  local settings = f.globals.BuffomatShared

  -- Settings saved before the option existed get the message; a choice the user made is kept
  whatsNew:UpgradeSettings(settings)
  equal(settings.WelcomeMessage, true)
  settings.WelcomeMessage = false
  whatsNew:UpgradeSettings(settings)
  equal(settings.WelcomeMessage, false)

  -- Switched off: nothing is said after login
  whatsNew:Init()
  f:advance(10)
  equal(#printed, 0, "messages with the option off")

  -- Switched on: said once, a few seconds after login
  settings.WelcomeMessage = true
  whatsNew:Init()
  f:advance(1)
  equal(#printed, 0, "messages right after login")
  f:advance(10)
  equal(#printed, 1, "messages after the delay")
  equal(printed[1], whatsNew:WelcomeText(nil))

  -- The chat link is handled by a hook on SetItemRef, which ignores other links
  equal(type(f.hooks.SetItemRef), "function")
  f.hooks.SetItemRef("item:6948")
  equal(settings.SeenVersion, nil, "another link opens nothing")
  print("PASS: welcome message option and the chat link hook")
end

do
  local _, whatsNew = setup()

  equal(whatsNew:FormatItem({ "Scan statistics.", "`/bom scanstats` prints them." }),
    "|cff7a2a00Scan statistics.|r |cff1f3d7a/bom scanstats|r prints them.")
  equal(whatsNew:FormatItem({ "", "No title phrase" }), "No title phrase")
  equal(whatsNew:FormatItem({ "Only a title.", "" }), "|cff7a2a00Only a title.|r")
  -- A colour inside the red title would end the red early
  equal(whatsNew:FormatItem({ "The `/bom` command.", "Text" }), "|cff7a2a00The /bom command.|r Text")
  print("PASS: changelog points with a red title phrase")
end

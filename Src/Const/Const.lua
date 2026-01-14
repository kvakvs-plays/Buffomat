local TOCNAME, _ = ...

---@class ConstModule
---@field CLASS_NAME {[ClassName]: string}
---@field NAME_TO_CLASS {[string]: ClassName}
---@field CLASS_COLOR {[ClassName]: BomColor}
---@
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local kvEnvModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

constModule.TASKCOLOR_GRAY = "777777"
constModule.TASKCOLOR_RED = "cc4444"
constModule.TASKCOLOR_BLEAK_RED = "bb5555"

-- Same as kvEnvModule.GetAddOnMetadata but must be available on module load so calculate here
local compat_GetAddonMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddonMetadata
-- Version used for display in options
constModule.TOC_VERSION = compat_GetAddonMetadata(TOCNAME, "Version")
-- Longer title like "Buffomat Classic TBC"
constModule.TOC_TITLE = compat_GetAddonMetadata(TOCNAME, "Title")

constModule.SHORT_TITLE = "Buffomat"
constModule.MACRO_ICON = "INV_MISC_QUESTIONMARK"
constModule.MACRO_ICON_DISABLED = "INV_MISC_QUESTIONMARK"
constModule.BOM_BEAR_ICON_FULLPATH = "Interface\\ICONS\\Ability_Druid_ChallangingRoar"
constModule.BOM_OPTIONS_ICON_FULLPATH = "Interface\\ICONS\\INV_Misc_ScrollUnrolled01"
constModule.BOM_SPELL_SETTINGS_ICON_FULLPATH = "Interface\\ICONS\\Spell_Magic_PolymorphRabbit"

constModule.ICON_FORMAT = "|T%s:0:0:0:0:64:64:4:60:4:60|t"
constModule.PICTURE_FORMAT = "|T%s:0|t"

constModule.MACRO_NAME = "Buff'o'mat"
--constModule.BLESSING_ID = "blessing"
constModule.LOADING_SCREEN_TIMEOUT = 2

-- Play MP3 from Sounds/ directory when task list is not empty
constModule.TASK_NOTIFICATION_SOUNDS = --[[@as string[] ]] {
  "bubble-pop-up-alert",
  "computer-processing-short-click",
  "correct-answer-tone",
  "gaming-lock",
  "long-pop",
  "mouse-click",
  "positive-notification",
  "projector-button-push",
}

--constModule.IconClassTexture = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
--constModule.IconClassTextureWithoutBorder = "Interface\\WorldStateFrame\\ICONS-CLASSES"
--constModule.IconClassTextureCoord = CLASS_ICON_TCOORDS

-- The texture is square 4x in a row, 64 px per icon
-- https://github.com/Gethe/wow-ui-textures/blob/live/WorldStateFrame/ICONS-CLASSES.PNG
constModule.CLASS_ICONS = {
  ["WARRIOR"]     = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:0:64|t",
  ["MAGE"]        = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:0:64|t",
  ["ROGUE"]       = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:128:192:0:64|t",
  ["DRUID"]       = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:192:256:0:64|t",

  ["HUNTER"]      = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:64:128|t",
  ["SHAMAN"]      = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:64:128|t",
  ["PRIEST"]      = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:128:192:64:128|t",
  ["WARLOCK"]     = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:192:256:64:128|t",

  ["PALADIN"]     = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:0:64:128:192|t",
  ["DEATHKNIGHT"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:0:0:0:0:256:256:64:128:128:192|t",
  ["pet"]         = "|TInterface\\Addons\\BuffomatClassic\\Textures\\icon_pet:0:0:0:0:64:64:0:64:0:64|t",
  ["tank"]        = "|TInterface\\Addons\\BuffomatClassic\\Textures\\icon_tank:0:0:0:0:64:64:0:64:0:64|t",
}

-- The texture is square 4x in a row, 64 px per icon
-- https://github.com/Gethe/wow-ui-textures/blob/live/WorldStateFrame/ICONS-CLASSES.PNG
constModule.CLASS_ICONS_BIG = {
  ["WARRIOR"]     = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:0:64|t",
  ["MAGE"]        = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:0:64|t",
  ["ROGUE"]       = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:128:192:0:64|t",
  ["DRUID"]       = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:192:256:0:64|t",

  ["HUNTER"]      = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:64:128|t",
  ["SHAMAN"]      = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:64:128|t",
  ["PRIEST"]      = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:128:192:64:128|t",
  ["WARLOCK"]     = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:192:256:64:128|t",

  ["PALADIN"]     = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:0:64:128:192|t",
  ["DEATHKNIGHT"] = "|TInterface\\WorldStateFrame\\ICONS-CLASSES:18:18:-4:4:256:256:64:128:128:192|t",
}

constModule.RAID_ICON_NAMES = ICON_TAG_LIST
constModule.RAID_ICON = {
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t", -- [1]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t", -- [2]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t", -- [3]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t", -- [4]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t", -- [5]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t", -- [6]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", -- [7]
  "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t", -- [8]
}

---@alias BomColor number[] RGB or RGBA color

constModule.CLASSES = CLASS_SORT_ORDER ---@type ClassName[]
constModule.CLASS_NAME = {}
constModule.CLASS_COLOR = RAID_CLASS_COLORS
constModule.NAME_TO_CLASS = {} --[[@as {[string]: string}]]

function constModule:Init()
  for english, localized in pairs(LOCALIZED_CLASS_NAMES_MALE) do
    self.NAME_TO_CLASS[localized] = english
    self.NAME_TO_CLASS[english] = english
    self.CLASS_NAME[english] = localized
  end

  self.CLASS_NAME["pet"] = _t("Pet")
  self.CLASS_NAME["tank"] = _t("Tank")

  for eng, name in pairs(LOCALIZED_CLASS_NAMES_FEMALE) do
    self.NAME_TO_CLASS[name] = eng
  end
end
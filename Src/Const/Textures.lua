-- defined in WowInventory.lua ---@alias WowIconId string|number

---@alias WowTexCoord number[]

---@class TexturesModule
---@field CLASS_ICONS_ATLAS string
---@field CLASS_ICONS_ATLAS_TEX_COORD {[ClassName]: WowTexCoord}
---@field CLASS_ICONS_BUNDLED {[ClassName]: string}
---@field ICON_BUFF_OFF string
---@field ICON_BUFF_ON string
---@field ICON_CHECKED string
---@field ICON_CHECKED_OFF string
---@field ICON_DISABLED string
---@field ICON_EMPTY string
---@field ICON_GEAR string
---@field ICON_GROUP string
---@field ICON_GROUP_ITEM string
---@field ICON_GROUP_NONE string
---@field ICON_OPT_DISABLED string
---@field ICON_OPT_ENABLED string
---@field ICON_PET string
---@field ICON_PET_COORD WowTexCoord
---@field ICON_SELF_CAST_OFF string
---@field ICON_SELF_CAST_ON string
---@field ICON_SETTING_OFF string
---@field ICON_SETTING_ON string
---@field ICON_TANK string
---@field ICON_TANK_COORD WowTexCoord
---@field ICON_TARGET_EXCLUDE string
---@field ICON_TARGET_OFF string
---@field ICON_TARGET_ON string
---@field ICON_WHISPER_OFF string
---@field ICON_WHISPER_ON string
---@field ICON_COORD_09 WowTexCoord
---@field ICON_COORD_08 WowTexCoord

local module = LibStub("Buffomat-Textures") --[[@as TexturesModule]]

module.ICON_COORD_09 = { 0.1, 0.9, 0.1, 0.9 }
module.ICON_COORD_08 = { 0.2, 0.8, 0.2, 0.8 }

module.ICON_OPT_ENABLED = "Interface\\Buttons\\UI-CheckBox-Check"
module.ICON_OPT_DISABLED = "Interface\\Buttons\\UI-CheckBox-Up"

module.ICON_SELF_CAST_ON = "Interface\\FriendsFrame\\UI-Toast-FriendOnlineIcon"
module.ICON_SELF_CAST_OFF = "Interface\\FriendsFrame\\UI-Toast-ChatInviteIcon"

module.CLASS_ICONS_ATLAS = "Interface\\WorldStateFrame\\ICONS-CLASSES"
module.CLASS_ICONS_ATLAS_TEX_COORD = CLASS_ICON_TCOORDS --[[@as {[ClassName]: WowTexCoord} ]]
module.ICON_EMPTY = "Interface\\Buttons\\UI-MultiCheck-Disabled"

---@deprecated Unused
module.ICON_SETTING_ON = "Interface\\RAIDFRAME\\ReadyCheck-Ready"
---@deprecated Unused
module.ICON_SETTING_OFF = module.ICON_EMPTY

module.ICON_WHISPER_ON = "Interface\\Buttons\\UI-GuildButton-MOTD-Up"
module.ICON_WHISPER_OFF = "Interface\\Buttons\\UI-GuildButton-MOTD-Disabled"

module.ICON_BUFF_ON = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
module.ICON_BUFF_OFF = module.ICON_EMPTY

--Icon for when self cast is enabled
module.ICON_DISABLED = "Interface\\FriendsFrame\\StatusIcon-Offline" --grey circle

--"Interface\\COMMON\\VOICECHAT-MUTED"
module.ICON_TARGET_ON = "Interface\\CURSOR\\Crosshairs"
module.ICON_TARGET_EXCLUDE = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
module.ICON_TARGET_OFF = module.ICON_EMPTY

module.ICON_CHECKED = "Interface\\Buttons\\UI-CheckBox-Check"
module.ICON_CHECKED_OFF = module.ICON_EMPTY

module.ICON_GROUP = "Interface\\ICONS\\Achievement_GuildPerk_EverybodysFriend"
module.ICON_GROUP_ITEM = "Interface\\Buttons\\UI-PageButton-Background"
module.ICON_GROUP_NONE = module.ICON_EMPTY
module.ICON_GEAR = "Interface\\ICONS\\INV_Misc_Gear_01"

module.ICON_MAINHAND_OFF = module.ICON_EMPTY
module.ICON_MAINHAND_ON = "Interface\\ICONS\\INV_Weapon_ShortBlade_03"
module.ICON_MAINHAND_COORD = module.ICON_COORD_09

module.ICON_OFFHAND_OFF = module.ICON_EMPTY
module.ICON_OFFHAND_ON = "Interface\\ICONS\\INV_Weapon_Halberd_12"
module.ICON_OFFHAND_COORD = module.ICON_COORD_09

module.ICON_TANK = "Interface\\RAIDFRAME\\UI-RAIDFRAME-MAINTANK"
module.ICON_TANK_COORD = module.ICON_COORD_09

module.ICON_PET = "Interface\\ICONS\\Ability_Mount_JungleTiger"
module.ICON_PET_COORD = module.ICON_COORD_09

module.ON_ICON = "|TInterface\\RAIDFRAME\\ReadyCheck-Ready:0:0:0:0:64:64:4:60:4:60|t"
module.OFF_ICON = "|TInterface\\RAIDFRAME\\ReadyCheck-NotReady:0:0:0:0:64:64:4:60:4:60|t"

---@type {[ClassName]: string}
module.CLASS_ICONS_BUNDLED = {
  ["WARRIOR"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_warrior",
  ["MAGE"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_mage",
  ["PALADIN"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_paladin",
  ["HUNTER"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_hunter",
  ["DRUID"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_druid",
  ["SHAMAN"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_shaman",
  ["PRIEST"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_priest",
  ["WARLOCK"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_warlock",
  ["ROGUE"]     = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_rogue",
  ["DEATHKNIGHT"] = "Interface\\Addons\\BuffomatClassic\\Textures\\classicon_deathknight",
  ["pet"] = "Interface\\Addons\\BuffomatClassic\\Textures\\icon_pet",
  ["tank"] = "Interface\\Addons\\BuffomatClassic\\Textures\\icon_tank",
}

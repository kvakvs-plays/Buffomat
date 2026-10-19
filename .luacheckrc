-- Lint: lua "%APPDATA%\luarocks\bin\luacheck" Src Tests --codes  (see .agents/luacheck-plan.md)
std = "lua51"
max_line_length = 120
-- Type annotations (---@alias unions, ---@type tuples) and aligned trailing comments on data
-- tables cannot be wrapped usefully; the limit applies to code
max_comment_line_length = false
-- `function module:Method()` without touching self is the normal module style here
self = false
ignore = {
  "21[123]/_.*", -- a leading underscore marks a value as unused on purpose
  "211/addonName", "211/ns", -- every file starts with `local addonName, ns = ...` (see AGENTS.md)
  "542", -- a commented empty branch documents a deliberate no-op in an elseif chain
}

exclude_files = {
  "Ace3/**",
  "references/**",
  "codex-references/**",
  "Src/Deprecated/**", -- not in toc_template.toc
}

-- Written by the addon: saved variables, binding labels, slash commands, the addon object
globals = {
  "BomModuleManager", "BUFFOMAT_ADDON", "BuffomatAddon", "BuffomatShared", "BuffomatCharacter",
  "BINDING_HEADER_BUFFOMATHEADER", "BINDING_NAME_BUFFOMAT_WINDOW", "SlashCmdList", "_G",
}

-- WoW API, FrameXML globals, XML-defined frames, and client Lua extensions (bit, wipe, tContains...)
read_globals = {
  "BACKPACK_CONTAINER", "bit", "BomC_ListTab_Button", "BomC_Tooltip", "CancelUnitBuff", "CastSpellByID",
  "CAT_FORM", "ChatEdit_OnLoad", "ChatEdit_SendText", "ChatFrame_OpenChat", "CheckInteractDistance",
  "CLASS_ICON_TCOORDS", "CLASS_SORT_ORDER", "CombatLogGetCurrentEventInfo",
  "COMBATLOG_OBJECT_AFFILIATION_MINE", "COMBATLOG_OBJECT_AFFILIATION_PARTY",
  "COMBATLOG_OBJECT_AFFILIATION_RAID", "Constants", "CreateFrame", "CreateMacro", "C_Item", "C_Map",
  "C_Spell", "C_Timer", "DEFAULT_CHAT_FRAME", "Dismount", "DoEmote", "EditMacro", "Enum",
  "ERR_ATTACK_MOUNTED", "ERR_CANTATTACK_NOTSTANDING", "ERR_CANT_INTERACT_SHAPESHIFTED",
  "ERR_EMBLEMERROR_NOTABARDGEOSET", "ERR_LOOT_NOTSTANDING", "ERR_MOUNT_SHAPESHIFTED", "ERR_NOT_WHILE_MOUNTED",
  "ERR_NOT_WHILE_SHAPESHIFTED", "ERR_NO_ITEMS_WHILE_SHAPESHIFTED", "ERR_SPELL_OUT_OF_RANGE",
  "ERR_TAXINOTSTANDING", "ERR_TAXIPLAYERALREADYMOUNTED", "ERR_TAXIPLAYERSHAPESHIFTED", "GameFontNormal",
  "GameTooltip", "GameTooltip_SetDefaultAnchor", "GetActiveTalentGroup", "GetAddOnMetadata",
  "GetAddonMetadata", "GetBindingKey", "GetBuildInfo", "GetContainerItemCooldown", "GetContainerItemInfo",
  "GetContainerNumSlots", "GetCursorInfo", "GetCursorPosition", "GetGuildRosterInfo", "GetInstanceInfo",
  "GetInventoryItemID", "GetInventoryItemLink", "GetInventorySlotInfo", "GetItemInfo", "GetLocale",
  "GetMacroInfo", "GetNetStats", "GetNumGuildMembers", "GetNumMacros", "GetNumTrackingTypes",
  "GetPlayerInfoByGUID", "GetRaidRosterInfo", "GetShapeshiftForm", "GetShapeshiftFormID", "GetSpellCooldown",
  "GetSpellInfo", "GetSpellPowerCost", "GetSpellSubtext", "GetTime", "GetTrackingInfo", "GetTrackingTexture",
  "GetWeaponEnchantInfo", "ICON_TAG_LIST", "InCombatLockdown", "IsAltKeyDown", "IsFlying", "IsInGroup",
  "IsInInstance", "IsInRaid", "IsItemInRange", "IsModifierKeyDown", "IsMounted", "IsOutdoors", "IsResting",
  "IsShiftKeyDown", "IsSpellInRange", "IsSpellKnown", "IsStealthed", "Item", "ITEM_MOD_AGILITY_SHORT",
  "ITEM_MOD_ATTACK_POWER_SHORT", "ITEM_MOD_CRIT_RATING_SHORT", "ITEM_MOD_DODGE_RATING_SHORT",
  "ITEM_MOD_EXPERTISE_RATING_SHORT", "ITEM_MOD_EXTRA_ARMOR_SHORT", "ITEM_MOD_HASTE_RATING_SHORT",
  "ITEM_MOD_HEALTH_REGEN_SHORT", "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_INTELLECT_SHORT",
  "ITEM_MOD_MANA_REGENERATION_SHORT", "ITEM_MOD_MASTERY_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT",
  "ITEM_MOD_SPELL_POWER_SHORT", "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_STAMINA_SHORT", "ITEM_MOD_STRENGTH_SHORT",
  "LE_EXPANSION_LEVEL_CURRENT", "LibStub", "LOCALIZED_CLASS_NAMES_FEMALE", "LOCALIZED_CLASS_NAMES_MALE",
  "LOCKED", "MacroFrame", "MAX_ACCOUNT_MACROS", "MAX_CHARACTER_MACROS", "Minimap", "MouseIsOver",
  "NUM_BAG_SLOTS", "PanelTemplates_SetTab", "PickupMacro", "PlaySound", "PlaySoundFile", "RAID_CLASS_COLORS",
  "RESISTANCE2_NAME", "RESISTANCE3_NAME", "RESISTANCE4_NAME", "RESISTANCE5_NAME", "RESISTANCE6_NAME",
  "SendChatMessage", "SetTracking", "Spell", "SPELL_FAILED_LOWLEVEL", "SPELL_FAILED_NOT_MOUNTED",
  "SPELL_FAILED_NOT_SHAPESHIFT", "SPELL_FAILED_NOT_STANDING", "SPELL_FAILED_NO_ITEMS_WHILE_SHAPESHIFTED",
  "SPELL_NOT_SHAPESHIFTED", "SPELL_NOT_SHAPESHIFTED_NOSPACE", "tContains", "tinsert",
  "UIDROPDOWNMENU_OPEN_MENU", "UIErrorsFrame", "UIParent", "UnitAura", "UnitCanCooperate", "UnitClass",
  "UnitCreatureFamily", "UnitCreatureType", "UnitDistanceSquared", "UnitExists", "UnitFactionGroup",
  "UnitFullName", "UnitGroupRolesAssigned", "UnitGUID", "UnitHasIncomingResurrection", "UnitInParty",
  "UnitInRaid", "UnitInRange", "UnitInVehicle", "UnitIsConnected", "UnitIsDead", "UnitIsDeadOrGhost",
  "UnitIsFeignDeath", "UnitIsFriend", "UnitIsGhost", "UnitIsOtherPlayersPet", "UnitIsPlayer", "UnitIsPVP",
  "UnitIsUnit", "UnitLevel", "UnitName", "UnitOnTaxi", "UnitPlayerOrPetInParty", "UnitPlayerOrPetInRaid",
  "UnitPower", "UnitPowerMax", "UnitRace", "wipe", "WorldFrame", "WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
  "WOW_PROJECT_CATACLYSM_CLASSIC", "WOW_PROJECT_CLASSIC", "WOW_PROJECT_ID", "WOW_PROJECT_MISTS_CLASSIC",
  "WOW_PROJECT_WRATH_CLASSIC",
}

files["Src/Languages/**"] = { max_line_length = false }
-- Knowledge setup functions share one signature; not all of them use the enchantment table
files["Src/Knowledge/**"] = { ignore = { "212/enchantments" } }
-- AceConfig option callbacks receive `info` whether they need it or not
files["Src/Ui/Options.lua"] = { ignore = { "212/info" } }
files["Src/KvLib/KvOptions.lua"] = { ignore = { "212/info" } }
files["Tests/**"] = { read_globals = { "setfenv", "loadfile" } }

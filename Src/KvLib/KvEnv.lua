---@class KvSharedEnvModule
---@field isClassic boolean
---@field isTBC boolean
---@field haveTBC boolean
---@field isWotLK boolean
---@field haveWotLK boolean
---@field isCata boolean
---@field haveCata boolean
---@field isForever boolean
---@field playerClass ClassName
---@field GetSpellInfo fun(spell: number|string): string?, string?, number?, number?, number?, number?, number?
---@field GetSpellSubtext fun(spell: number|string): string?
---@field GetSpellCooldown fun(spell: number|string): number?, number?, number?, number?
---@field GetSpellPowerCost fun(spell: number|string): table?
---@field IsSpellInRange fun(spell: number|string, unit: string): number?
---@field IsSpellKnown fun(spellId: number): boolean
---@field UnitAura fun(unit: string, index: number, filter: string?): ...
---@field UnitBuff fun(unit: string, index: number, filter: string?): ...
---@field UnitPower fun(unit: string, powerType: number?): number?
---@field UnitInRange fun(unit: string): boolean?, boolean?
---@field MAX_ACCOUNT_MACROS number
---@field MAX_CHARACTER_MACROS number
---@field CAT_FORM number
---@field MouseIsOver fun(frame: Frame): boolean
---@field GetItemInfo fun(item: number|string): ...
---@field IsItemInRange fun(item: number|string, unit: string): boolean?
---@field GetWeaponEnchantInfo fun(): ...
---@field GetInventorySlotInfo fun(slotName: string): number
---@field GetActiveTalentGroup fun(): number
---@field GetTrackingInfo fun(index: number): string?, number?, boolean?, string?, number?, number?
---@field ChatEdit_SendText fun(editBox: table)
---@field ChatFrame_OpenChat fun(text: string)
---@field IsAuraRestricted fun(): boolean

local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

-- local _, _, _, tocversion = GetBuildInfo()
envModule.isMistsOfPandaria = WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC
envModule.haveMistsOfPandaria = envModule.isMistsOfPandaria

envModule.isCata = WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC
envModule.haveCata = envModule.isCata

envModule.isWotLK = WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC
envModule.haveWotLK = envModule.isWotLK or envModule.isCata

envModule.isTBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
envModule.haveTBC = envModule.isWotLK or envModule.isTBC or envModule.isCata

envModule.isClassic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
envModule.isForever = false

envModule.GetContainerNumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
envModule.GetContainerItemInfo = (C_Container and C_Container.GetContainerItemInfo) or GetContainerItemInfo
envModule.GetContainerItemCooldown = (C_Container and C_Container.GetContainerItemCooldown) or GetContainerItemCooldown
envModule.GetAddonMetadata = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddonMetadata

envModule.GetSpellInfo = GetSpellInfo
envModule.GetSpellSubtext = GetSpellSubtext
envModule.GetSpellCooldown = GetSpellCooldown
envModule.GetSpellPowerCost = GetSpellPowerCost
envModule.IsSpellInRange = IsSpellInRange
envModule.IsSpellKnown = IsSpellKnown
envModule.UnitAura = UnitAura
envModule.UnitBuff = UnitBuff
envModule.UnitPower = UnitPower
envModule.UnitInRange = UnitInRange
envModule.MAX_ACCOUNT_MACROS = MAX_ACCOUNT_MACROS
envModule.MAX_CHARACTER_MACROS = MAX_CHARACTER_MACROS
envModule.CAT_FORM = CAT_FORM
envModule.MouseIsOver = MouseIsOver
envModule.GetItemInfo = GetItemInfo
envModule.IsItemInRange = IsItemInRange
envModule.GetWeaponEnchantInfo = GetWeaponEnchantInfo
envModule.GetInventorySlotInfo = GetInventorySlotInfo
envModule.GetActiveTalentGroup = GetActiveTalentGroup
envModule.GetTrackingInfo = C_Minimap and C_Minimap.GetTrackingInfo
envModule.ChatEdit_SendText = ChatEdit_SendText
envModule.ChatFrame_OpenChat = ChatFrame_OpenChat
envModule.IsAuraRestricted = function()
  return false
end

envModule.playerClass = select(2, UnitClass("player"))
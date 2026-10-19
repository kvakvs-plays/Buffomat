---@class AllConsumesOtherModule

local otherModule = LibStub("Buffomat-AllConsumesOther") --[[@as AllConsumesOtherModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function otherModule:SetupOtherConsumables(allBuffs, enchantments)
  self:_SetupPhysicalConsumablesClassic(allBuffs, enchantments)
  --self:_SetupPhysicalConsumablesTBC(buffs, enchantments)
  --self:_SetupPhysicalConsumablesWotLK(buffs, enchantments)

  --self:_SetupCasterConsumablesClassic(buffs, enchantments)
  self:_SetupCasterConsumablesTBC(allBuffs, enchantments)
  --self:_SetupCasterConsumablesWotLK(buffs, enchantments)

  self:_SetupMiscConsumablesClassic(allBuffs, enchantments)
  --self:_SetupMiscConsumablesTBC(buffs, enchantments)
  --self:_SetupMiscConsumablesWotLK(buffs, enchantments)
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function otherModule:_SetupPhysicalConsumablesClassic(allBuffs, enchantments)
  --Winterfall Firewater
  buffDefModule:genericConsumable(allBuffs, 17038, 12820)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysBuff")

  --Juju Might +40AP
  buffDefModule:genericConsumable(allBuffs, 16329, 12460)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysBuff")

  --Juju Power +30Str
  buffDefModule:genericConsumable(allBuffs, 16323, 12451)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysBuff")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function otherModule:_SetupCasterConsumablesTBC(allBuffs, enchantments)
  -- Not visible in Classic
  --TBC: Bloodthistle (Belf only)
  buffDefModule:tbcConsumable(allBuffs, 28273, 22710)
      :RequirePlayerRace("BloodElf")
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)   -- RequireRace
      :ExtraText(_t("tooltip.buff.spellPower"))
      :Category("tbcFood")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function otherModule:_SetupMiscConsumablesClassic(allBuffs, enchantments)
  --Juju Ember +15FR
  buffDefModule:genericConsumable(allBuffs, 16326, 12455)
      :ExtraText(_t("tooltip.buff.fireResist"))
      :Category("classicBuff")

  --Juju Chill +15FrostR
  buffDefModule:genericConsumable(allBuffs, 16325, 12457)
      :ExtraText(_t("tooltip.buff.frostResist"))
      :Category("classicBuff")

  --Kreeg's Stout Beatdown +SPI minus INT
  buffDefModule:genericConsumable(allBuffs, 22790, 18284)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :ExtraText(_t("tooltip.alcohol.spirit"))
      :Category("classicFood")

  --Gordok Green Grog +STA
  buffDefModule:genericConsumable(allBuffs, 22789, 18269)
      :ExtraText(_t("tooltip.alcohol.stamina"))
      :Category("classicFood")

  --Rumsey Rum Black Label
  buffDefModule:genericConsumable(allBuffs, 25804, 21151)
      :ExtraText(_t("tooltip.alcohol.stamina"))
      :Category("classicFood")

  --Crystal Ward
  buffDefModule:genericConsumable(allBuffs, 15233, 11564)
      :Category("classicBuff")

  --Crystal Spire +12 THORNS
  buffDefModule:genericConsumable(allBuffs, 15279, 11567)
      :Category("classicBuff")

  --Crystal Force +30 SPI
  buffDefModule:genericConsumable(allBuffs, 15231, 11563)
      :ExtraText(_t("tooltip.buff.spirit"))
      :Category("classicBuff")
end
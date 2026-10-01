local BuffomatAddon = BuffomatAddon

---@class DruidModule

local druidModule = LibStub("Buffomat-AllSpellsDruid") --[[@as DruidModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

---Add DRUID spells
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function druidModule:SetupDruidSpells(allBuffs, enchantments)
  --Gift/Mark of the Wild | Gabe/Mal der Wildniss
  buffDefModule:createAndRegisterBuff(allBuffs, 9885, nil)
      :RequiresCancelForm(true)
      :IsDefault(true)
      :SingleFamily({ 1126, 5232, 6756, 5234, 8907, 9884, 9885, -- Mark of the Wild 1-7
        26990,                                                  -- TBC: Mark of the Wild 8
        48469,                                                  -- WotLK: Mark of the Wild 9
        79061 })                                                -- Cataclysm: Mark of the Wild
      :GroupFamily({ 21849, 21850,                              -- Gift of the Wild 1-2
        26991,                                                  -- TBC: Gift of the Wild 3
        48470,                                                  -- WotLK: Gift of the Wild 4
        79061 })                                                -- Cataclysm: Mark of the Wild
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :GroupDuration(allBuffsModule.HOUR)
      :ReagentRequired(buffDefModule:PerExpansionChoice(
        {
          classic = { 17021, 17026 },
          wotlk = { 44605 } -- WotLK: Wild Spineleaf
        }))
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :RequirePlayerClass("DRUID")
      :Category("class")

  --Thorns | Dornen
  buffDefModule:createAndRegisterBuff(allBuffs, 9910, nil)
      :RequiresCancelForm(false)
      :IsDefault(false)
      :SingleFamily({ 467, 782, 1075, 8914, 9756, 9910, -- Thorns 1-6
        26992,                                          -- TBC: Thorns 7
        53307 })                                        -- WotLK: Thorns 8
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :DefaultTargetClasses(allBuffsModule.MELEE_CLASSES)
      :RequirePlayerClass("DRUID")
      :Category("class")

  --Omen of Clarity
  buffDefModule:createAndRegisterBuff(allBuffs, 16864, nil)
      :IsOwn(true)
      :RequiresCancelForm(true)
      :IsDefault(true)
      :RequirePlayerClass("DRUID")
      :Category("class")

  -- Nature's Grasp | Griff der Natur
  buffDefModule:createAndRegisterBuff(allBuffs, 17329, nil)
      :IsOwn(true)
      :RequiresCancelForm(true)
      :IsDefault(false)
      :HasCooldown(true)
      :RequiresOutdoors(true)
      :SingleFamily({ 16689, 16810, 16811, 16812, 16813, 17329, -- Nature's Grasp 1-6
        27009,                                                  -- TBC: Nature's Grasp 7
        53312 })                                                -- WotLK: Nature's Grasp 8
      :RequirePlayerClass("DRUID")
      :Category("class")

  --TBC: Tree of life
  buffDefModule:createAndRegisterBuff(allBuffs, 33891, nil)
      :IsOwn(true)
      :IsDefault(false)
      :ShapeshiftFormId(2)
      :RequirePlayerClass("DRUID")
      :RequireTBC() -- Requires TBC and up
      :Category("class")

  -- Special code: This will disable herbalism and mining tracking in Cat Form
  -- Track Humanoids (Cat Form)
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Druid_TrackHumanoids, nil)
      :BuffType("tracking")
      :RequiresForm(envModule.CAT_FORM)
      :IsDefault(true)
      :ExtraText(_t("SpellLabel_TrackHumanoids"))
      :RequirePlayerClass("DRUID")
      :Category("tracking")

  -- Revive (WotLK)
  buffDefModule:createAndRegisterBuff(allBuffs, 50763, nil)
      :RequiresCancelForm(true)
      :BuffType("resurrection")
      :IsDefault(true)
      :SingleFamily({ 50769, 50768, 50767, 50766, 50765, 50764, 50763 }) -- WotLK: Revive 1-7
      :RequireWotLK()
      :RequirePlayerClass("DRUID")
      :Category("class")
end
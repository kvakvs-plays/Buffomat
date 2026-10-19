---@class PaladinModule

local paladinModule = LibStub("Buffomat-AllSpellsPaladin") --[[@as PaladinModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]

---Add PALADIN spells
---@param allBuffs BomBuffDefinition[]
---@param _enchants BomEnchantmentsMapping
function paladinModule:SetupPaladinSpells(allBuffs, _enchants)
  --Righteous Fury, same in TBC
  buffDefModule:createAndRegisterBuff(allBuffs, 25780, nil)
      :IsOwn(true)
      :IsDefault(false)
      :Category("class")

  local blessingDuration = allBuffsModule.TbcOrClassic(allBuffsModule.TEN_MINUTES, allBuffsModule.FIVE_MINUTES)
  local greaterBlessingDuration = allBuffsModule.TbcOrClassic(allBuffsModule.FIFTEEN_MINUTES, allBuffsModule
    .HALF_AN_HOUR)

  --
  -- LESSER BLESSINGS

  -- Blessing of Kings
  buffDefModule:createAndRegisterBuff(allBuffs, 20217, nil)
      :GroupFamily({ 25898 })
      :IsBlessing(true)
      :IsDefault(false)
      :SingleDuration(blessingDuration)
      :DefaultTargetClasses({ "MAGE", "HUNTER", "WARLOCK" })
      :IgnoreIfHaveBuff(25898) -- Greater Kings
      :Category("blessing")
      :HideInCata()

  -- [Cataclysm] Blessing of Kings
  buffDefModule:createAndRegisterBuff(allBuffs, 20217, nil)
      :SingleFamily({ 20217, 79063 }) -- Cataclysm: Blessing of Kings (Spell id and actual aura id)
      :GroupFamily({ 20217, 79063 })  -- Cataclysm: Blessing of Kings (Spell id and actual aura id)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.HOUR)
      :Category("blessing")
      :RequireCata()

  -- Blessing of Light (classic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 19979, nil)
      :SingleFamily({ 19977, 19978, 19979, -- Ranks 1-3
        27144 })                           -- TBC: Rank 4
      :IsBlessing(true)
      :IsDefault(false)
      :SingleDuration(blessingDuration)
      :GroupDuration(greaterBlessingDuration)
      :RequirePlayerClass("PALADIN")
      :HideInWotLK()
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :IgnoreIfHaveBuff(21177) -- Greater Light
      :Category("blessing")

  -- Blessing of Might
  buffDefModule:createAndRegisterBuff(allBuffs, 25291, nil)
      :IsBlessing(true)
      :IsDefault(true)
      :SingleFamily({ 19740, 19834, 19835, 19836, 19837, 19838, 25291, -- Blessing of Might 1-7
        27140,                                                         -- TBC: Blessing of Might 8
        48931, 48932 })                                                -- WotLK: Blessing of Might 9-10
      :SingleDuration(blessingDuration)
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.PHYSICAL_CLASSES)
      :IgnoreIfHaveBuff({ 25782, 25916, 27141 }) -- Greater Might 1-3
      :IgnoreIfHaveBuff({ 48933, 48934 })        -- WotLK: Greater Might 4-5
      :Category("blessing")
      :HideInCata()

  -- [Cataclysm] Blessing of Might
  buffDefModule:createAndRegisterBuff(allBuffs, 19740, nil)
      :IsBlessing(true)
      :IsDefault(true)
      :SingleFamily({ 19740, 79102 }) -- Cataclysm: Blessing of Might (spell id and aura id)
      :GroupFamily({ 19740, 79102 })  -- Cataclysm: Blessing of Might (spell id and aura id)
      :SingleDuration(allBuffsModule.HOUR)
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.PHYSICAL_CLASSES)
      :Category("blessing")
      :RequireCata()

  -- Blessing of Salvation (classic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 1038, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleDuration(blessingDuration)
      :RequirePlayerClass("PALADIN")
      :HideInWotLK()
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :IgnoreIfHaveBuff(25895) -- Greater Salv
      :Category("blessing")
      :HideInCata()

  -- Blessing of Wisdom
  buffDefModule:createAndRegisterBuff(allBuffs, 25290, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleFamily({ 19742, 19850, 19852, 19853, 19854, 25290, -- Blessing of Wisdom 1-6
        27142,                                                  -- TBC: Blessing of Wisdom 7
        48935, 48936 })                                         -- WotLK: Blessing of Wisdom 8-9
      :SingleDuration(blessingDuration)
      :GroupDuration(greaterBlessingDuration)
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.MANA_CLASSES)
      :Category("blessing")
      :HideInCata()

  -- Blessing of Sanctuary
  buffDefModule:createAndRegisterBuff(allBuffs, 20914, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleFamily({ 20911, 20912, 20913, 20914, -- Blessing of Sanctuary 1-4; WotLK: Blessing of Sanctuary
        27168 })                                  -- TBC: Blessing of Sanctuary 5
      :SingleDuration(blessingDuration)
      :GroupDuration(greaterBlessingDuration)
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :Category("blessing")
  --
  -- GREATER BLESSINGS
  --
  -- Greater Blessing of Kings
  buffDefModule:createAndRegisterBuff(allBuffs, 25898, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleDuration(greaterBlessingDuration)
      :ReagentRequired({ itemIdsModule.Paladin_SymbolOfKings })
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :Category("blessing")
      :HideInCata()

  -- Greater Blessing of Light
  buffDefModule:createAndRegisterBuff(allBuffs, 25890, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleFamily({ 25890, -- Greater Rank 1
        27145 })             -- TBC: Greater Rank 2
      :ReagentRequired({ itemIdsModule.Paladin_SymbolOfKings })
      :SingleDuration(greaterBlessingDuration)
      :RequirePlayerClass("PALADIN")
      :HideInWotLK()
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :Category("blessing")

  --Greater Blessing of Might
  buffDefModule:createAndRegisterBuff(allBuffs, 25916, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleFamily({ 25782, 25916, -- Greater Blessing of Might 1-2
        27141,                      -- TBC: Greater Blessing of Might 3
        48933, 48934 })             -- WotLK: Greater Blessing of Might 4-5
      :SingleDuration(greaterBlessingDuration)
      :ReagentRequired({ itemIdsModule.Paladin_SymbolOfKings })
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.PHYSICAL_CLASSES)
      :Category("blessing")
      :HideInCata()

  --Greater Blessing of Salvation
  buffDefModule:createAndRegisterBuff(allBuffs, 25895, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleDuration(greaterBlessingDuration)
      :ReagentRequired({ itemIdsModule.Paladin_SymbolOfKings })
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :Category("blessing")
      :HideInCata()

  --Greater Blessing of Wisdom
  buffDefModule:createAndRegisterBuff(allBuffs, 25918, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleFamily({ 25894, 25918, -- Greater Blessing of Wisdom 1-2
        27143,                      -- TBC: Greater Blessing of Wisdom 3
        48937, 48938 })             -- WotLK: Greater Blessing of Wisdom 4-5
      :SingleDuration(greaterBlessingDuration)
      :ReagentRequired({ itemIdsModule.Paladin_SymbolOfKings })
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.MANA_CLASSES)
      :Category("blessing")
      :HideInCata()

  --Greater Blessing of Sanctuary
  buffDefModule:createAndRegisterBuff(allBuffs, 25899, nil)
      :IsBlessing(true)
      :IsDefault(false)
      :SingleFamily({ 25899, -- Greater Rank 1
        27169 })             -- TBC: Greater Rank 2
      :SingleDuration(greaterBlessingDuration)
      :ReagentRequired({ itemIdsModule.Paladin_SymbolOfKings })
      :RequirePlayerClass("PALADIN")
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :Category("blessing")

  -- END blessings ------
  --
  -- --- AURAS ------------------------
  --
  -- Devotion Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 10293, nil)
      :BuffType("aura")
      :IsDefault(false)
      :SingleFamily({ 465, 10290, 643, 10291, 1032, 10292, 10293, -- Devotion Aura 1-7
        27149,                                                    -- TBC: Devotion Aura 8
        48941, 48942 })                                           -- WotLK: Devotion Aura 9-10
      :RequirePlayerClass("PALADIN")
      :Category("aura")

  -- Retribution Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 10301, nil)
      :BuffType("aura")
      :IsDefault(true)
      :SingleFamily({ 7294, 10298, 10299, 10300, 10301, -- Retribution Aura 1-5
        27150,                                          -- TBC: Retribution Aura 6
        54043 })                                        -- WotLK: Retribution Aura 7
      :RequirePlayerClass("PALADIN")
      :Category("aura")

  --Concentration Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 19746, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :Category("aura")

  -- Shadow Resistance Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 19896, nil)
      :BuffType("aura")
      :IsDefault(false)
      :SingleFamily({ 19876, 19895, 19896, -- Shadow Resistance Aura 1-3
        27151,                             -- TBC: Shadow Resistance Aura 4
        48943 })                           -- WotLK: Shadow Resistance Aura 5
      :RequirePlayerClass("PALADIN")
      :Category("aura")

  -- Frost Resistance Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 19898, nil)
      :BuffType("aura")
      :IsDefault(false)
      :SingleFamily({ 19888, 19897, 19898, -- Frost Resistance Aura 1-3
        27152,                             -- TBC: Frost Resistance Aura 4
        48945 })                           -- WotLK: Frost Resistance Aura 5
      :RequirePlayerClass("PALADIN")
      :Category("aura")

  -- Fire Resistance Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 19900, nil)
      :BuffType("aura")
      :IsDefault(false)
      :SingleFamily({ 19891, 19899, 19900, -- Fire Resistance Aura 1-3
        27153,                             -- TBC: Fire Resistance Aura 4
        48947 })                           -- WotLK: Fire Resistance Aura 5
      :RequirePlayerClass("PALADIN")
      :Category("aura")

  --Sanctity Aura (classic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 20218, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :HideInWotLK()
      :Category("aura")

  --TBC: Crusader Aura
  local ca = buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Paladin_CrusaderAura, nil)
      :BuffType("aura")
      :IsDefault(false)
      :ExtraText(_t("CRUSADER_AURA_COMMENT"))
      :SingleManaCost(0)
      :RequirePlayerClass("PALADIN")
      :Category("aura")
  allBuffsModule.CrusaderAuraSpell = ca

  --
  -- ----------------------------------
  --
  -- Redemption / Auferstehung
  buffDefModule:createAndRegisterBuff(allBuffs, 20773, nil)
      :BuffType("resurrection")
      :IsDefault(true)
      :SingleFamily({ 7328, 10322, 10324, 20772, 20773, -- Classic: Redemption 1-5
        48949, 48950 })                                 -- WotLK: Redemption 6-7
      :RequirePlayerClass("PALADIN")
      :Category("class")

  -- Sanctity Seal (classic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 20164, nil)
      :BuffType("seal")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :HideInTBC()
      :Category(3)                                         -- classic only

  buffDefModule:createAndRegisterBuff(allBuffs, 5502, nil) -- Sense undead
      :BuffType("tracking")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :Category("tracking")

  -- Seal of Light
  buffDefModule:createAndRegisterBuff(allBuffs, 20165, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 20165, 20347, 20348, 20349, -- Seal of Light 1-4; also WotLK: Seal of Light
        27160 })                                  -- TBC: Seal of Light 5
      :RequirePlayerClass("PALADIN")
      :Category("seal")
      :HideInCata()

  -- [Cataclysm] Seal of Justice
  buffDefModule:createAndRegisterBuff(allBuffs, 20164, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 20164 }) -- Cataclysm: Seal of Justice
      :RequirePlayerClass("PALADIN")
      :Category("seal")
      :RequireCata()

  -- [Cataclysm] Seal of Insight
  buffDefModule:createAndRegisterBuff(allBuffs, 20165, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 20165 }) -- Cataclysm: Seal of Insight
      :RequirePlayerClass("PALADIN")
      :Category("seal")
      :RequireCata()

  -- Seal of Righteousness
  buffDefModule:createAndRegisterBuff(allBuffs, 20154, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 20154, 20287, 20288, 20289, 20290, 20291, 20292, 20293, -- Seal of Righteousness 1-8
        27155,                                                                -- TBC: Seal of Righteousness 9
        21084 })                                                              -- WotLK: Seal of Righteousness
      :RequirePlayerClass("PALADIN")
      :Category("seal")
      :HideInCata()

  -- [Cataclysm] Seal of Righteousness
  buffDefModule:createAndRegisterBuff(allBuffs, 20154, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 20154 }) -- Cataclysm: Seal of Righteousness
      :RequirePlayerClass("PALADIN")
      :Category("seal")
      :RequireCata()

  -- Seal of Wisdom
  buffDefModule:createAndRegisterBuff(allBuffs, 20166, nil)
      :BuffType("seal")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :Category("seal")

  -- TBC: Seal of Vengeance
  buffDefModule:createAndRegisterBuff(allBuffs, 348704, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 31801, -- TBC: level 70 spell for Blood Elf
        348704 })            -- TBC: Base spell for the alliance races
      :RequirePlayerClass("PALADIN")
      :Category("seal")

  -- TBC: Seal of the Martyr (Draenei, Dwarf, Human)
  buffDefModule:createAndRegisterBuff(allBuffs, 348700, nil)
      :BuffType("seal")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :Category("seal")

  -- TBC: Seal of Blood
  buffDefModule:createAndRegisterBuff(allBuffs, 31892, nil)
      :BuffType("seal")
      :IsDefault(false)
      :SingleFamily({ 31892, -- TBC: Base Blood Elf spell
        38008 })             -- TBC: Alliance version???
      :RequirePlayerClass("PALADIN")
      :Category("seal")

  -- TBC/WotLK: Seal of Command
  buffDefModule:createAndRegisterBuff(allBuffs, 20375, nil)
      :BuffType("seal")
      :IsDefault(false)
      :RequirePlayerClass("PALADIN")
      :Category("seal")
end
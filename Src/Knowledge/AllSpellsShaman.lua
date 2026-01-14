local BuffomatAddon = BuffomatAddon

---@class ShamanModule

local shamanModule = LibStub("Buffomat-AllSpellsShaman") --[[@as ShamanModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

---Add SHAMAN spells
---@param allBuffs BomBuffDefinition[]
---@param enchants BomEnchantmentsMapping
function shamanModule:SetupShamanSpells(allBuffs, enchants)
  local duration = allBuffsModule.TbcOrClassic(allBuffsModule.TWENTY_MINUTES, allBuffsModule.TEN_MINUTES)
  local enchantmentDuration = allBuffsModule.TbcOrClassic(allBuffsModule.HALF_AN_HOUR, allBuffsModule.FIVE_MINUTES) -- TBC: Shaman enchants become 30min

  -- Flametongue Weapon
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Shaman_Flametongue6, nil)
      :BuffType("weapon")
      :RewriteSealBuffType()
      :IsOwn(true)
      :IsConsumable(false)
      :IsDefault(false)
      :SingleDuration(enchantmentDuration)
      :SingleFamily({ 8024, 8027, 8030, 16339, 16341, spellIdsModule.Shaman_Flametongue6, -- Flametongue Weapon 1-6
        25489,                                                                            -- TBC: Flametongue Weapon 7
        58785, 58789, 58790 })                                                            -- WotLK: Flametongue Weapon 8-10
      :RequirePlayerClass("SHAMAN")
      :Category("classWeaponEnchantment")
  enchants[spellIdsModule.Shaman_Flametongue6] = {
    3, 4, 5, 523, 1665, 1666, -- Flametongue 1-6
    2634,                     -- TBC: Flametongue 7
    3779, 3780, 3781          -- WotLK: Flametongue 8-10
  }

  -- Frostbrand Weapon
  buffDefModule:createAndRegisterBuff(allBuffs, 16356, nil)
      :BuffType("weapon")
      :RewriteSealBuffType()
      :IsOwn(true)
      :IsConsumable(false)
      :IsDefault(false)
      :SingleDuration(enchantmentDuration)
      :SingleFamily({ 8033, 8038, 10456, 16355, 16356, -- Frostbrand Weapon 1-5
        25500,                                         -- TBC: Frostbrand Weapon 6
        58794, 58795, 58796 })                         -- WotLK: Frostbrand Weapon 7-9
      :RequirePlayerClass("SHAMAN")
      :Category("classWeaponEnchantment")
  enchants[16356] = { 2, 12, 524, 1667, 1668, -- Frostbrand
    2635,                                     -- TBC: Frostbrand 6
    3782, 3783, 3784 }                        -- WotLK: Frostbrand 7-9

  -- Rockbiter Weapon (Classic and TBC)
  buffDefModule:createAndRegisterBuff(allBuffs, 16316, nil)
      :BuffType("weapon")
      :RewriteSealBuffType()
      :IsOwn(true)
      :IsConsumable(false)
      :IsDefault(false)
      :SingleDuration(enchantmentDuration)
      :SingleFamily({ 8017, 8018, 8019, 10399, 16314, 16315, 16316, -- Ranks 1-7
        25479, 25485 })                                             -- TBC: Ranks 8-9
      :RequirePlayerClass("SHAMAN")
      :HideInWotLK()
      :Category("classWeaponEnchantment")

  -- Note: in TBC all enchantIds for rockbiter have changed
  enchants[16316] = { 1, 6, 29, 503, 504, 683, 1663, 1664, -- Rockbiter, also 504 some special +80 Rockbiter?
    241,                                                   -- Classic 2025: Rockbiter 1
    3040,                                                  -- rockbiter 7
    3023, 3026, 3028, 3031, 3034, 3037, 3040,              -- TBC: Rockbiter 1-7
    2632, 2633 }                                           -- TBC: Rockbiter 8-9

  -- Windfury Weapon
  buffDefModule:createAndRegisterBuff(allBuffs, 16362, nil)
      :BuffType("weapon")
      :RewriteSealBuffType()
  --:IsOwn(true)
      :IsConsumable(false)
      :IsDefault(false)
      :SingleDuration(enchantmentDuration)
      :SingleFamily({ 8232, 8235, 10486, 16362, -- Windfury Weapon 1-4
        25505,                                  -- TBC: Windfury Weapon 5
        58801, 58803, 58804 })                  -- WotLK: Windfury Weapon 6-8
      :RequirePlayerClass("SHAMAN")
      :Category("classWeaponEnchantment")
  enchants[16362] = { 283, 284, 525, 1669, -- Windfury 1-4
    2636,                                  -- TBC: Windfury 5
    3785, 3786, 3787 }                     -- WotLK: Windfury 6-8

  -- WotLK: Earthliving Weapon
  buffDefModule:createAndRegisterBuff(allBuffs, 51730, nil)
      :BuffType("weapon")
      :RewriteSealBuffType()
      :IsOwn(true)
      :IsConsumable(false)
      :IsDefault(false)
      :SingleDuration(enchantmentDuration)
      :SingleFamily({ 51730, 51988, 51991, 51992, 51993, 51994 }) -- WotLK: Earthliving Weapon 1-6
      :RequirePlayerClass("SHAMAN")
      :Category("classWeaponEnchantment")
  enchants[51730] = { 3345, 3346, 3347, 3348, 3349, 3350 } -- WotLK: Earthliving 1-6

  -- Lightning Shield / Blitzschlagschild
  buffDefModule:createAndRegisterBuff(allBuffs, 10432, nil)
      :IsDefault(false)
      :IsOwn(true)
      :SingleDuration(duration)
      :SingleFamily({ 324, 325, 905, 945, 8134, 10431, 10432, -- Lightning Shield 1-7
        25469, 25472,                                         -- TBC: Lightning Shield 8-9
        49280, 49281 })                                       -- WotLK: Lightning Shield 10-11
      :RequirePlayerClass("SHAMAN")
      :Category("class")

  -- Water Walking (no reagent in WotLK with a glyph)
  buffDefModule:createAndRegisterBuff(allBuffs, 546, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :DefaultTargetClasses(allBuffsModule.BOM_ALL_CLASSES)
      :RequirePlayerClass("SHAMAN")
      :Category("class")

  -- Water Breathing (no reagent in WotLK with a glyph)
  buffDefModule:createAndRegisterBuff(allBuffs, 131, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :DefaultTargetClasses(allBuffsModule.BOM_ALL_CLASSES)
      :RequirePlayerClass("SHAMAN")
      :Category("class")

  -- Water Shield
  buffDefModule:createAndRegisterBuff(allBuffs, 33736, nil)
      :IsOwn(true)
      :IsDefault(true)
      :SingleDuration(duration)
      :SingleFamily({ 52127, 52129, 52131, 52134, 52136, 52138, -- WotLK: Water Shield 1-6
        24398, 33736,                                           -- TBC: Water Shield 1-2, or WotLK: Water Shield 7-8
        57960 })                                                -- WotLK: Water Shield 9
      :RequirePlayerClass("SHAMAN")
      :RequireTBC()
      :Category("class")

  -- Ancestral Spirit / Auferstehung
  buffDefModule:createAndRegisterBuff(allBuffs, 20777, nil)
      :BuffType("resurrection")
      :IsDefault(true)
      :SingleFamily({ 2008, 20609, 20610, 20776, 20777, -- Ancestral Spirit 1-5
        25590,                                          -- TBC: Ancestral Spirit 6
        49277 })                                        -- WotLK: Ancestral Spirit 7
      :RequirePlayerClass("SHAMAN")
      :Category("class")
end
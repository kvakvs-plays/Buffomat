---@class AllConsumesEnchantmentsModule

local enchantmentsModule = LibStub("Buffomat-AllConsumesEnchantments") --[[@as AllConsumesEnchantmentsModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

---SCROLLS
---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function enchantmentsModule:SetupEnchantments(allBuffs, enchantments)
  self:_SetupPhysicalEnchantments(allBuffs, enchantments)
  self:_SetupCasterEnchantments(allBuffs, enchantments)
  self:_SetupOtherEnchantments(allBuffs, enchantments)
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param spellId WowSpellId
---@return BomBuffDefinition
function enchantmentsModule:RegisterEnchantment(allBuffs, spellId)
  return buffDefModule:createAndRegisterBuff(allBuffs, spellId, nil)
      :IsConsumable(true)
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :IsDefault(false)
      :BuffType("weapon")
      :Category("weaponEnchantment")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function enchantmentsModule:_SetupCasterEnchantments(allBuffs, enchantments)
  --if BOM.HaveTBC then
  --  buffDefModule:createAndRegisterBuff(buffs, 28017, --Superior Wizard Oil +42 SPELL
  --          { item = 22522, items = { 22522 }, isConsumable = true,
  --            type = "weapon", duration = allBuffsModule.DURATION_1H, default = false
  --          })   :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
  --               :Category("weaponEnchantment")
  --end
  --Minor, Lesser, Brilliant Mana Oil
  self:RegisterEnchantment(allBuffs, 25123)
      :CreatesOrProvidedByItem(
        buffDefModule:PerExpansionChoice({
          classic = { 20748, 20747, 20745 },       -- Minor, Lesser, Brilliant Mana Oil
          tbc = { 22521 },                         -- TBC: Superior Mana Oil
          wotlk = { 36899 }
        }))                                        -- WotLK: Exceptional Mana Oil
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
  enchantments[25123] = { 2624, 2625, 2629,        -- Minor, Lesser, Brilliant Mana Oil (enchantment)
    2677,                                          -- TBC: Superior Mana Oil (enchantment)
    3298 }                                         -- WotLK: Exceptional Mana Oil (enchantment)

  -- Wizard Oil
  self:RegisterEnchantment(allBuffs, 25122)
      :CreatesOrProvidedByItem(
        buffDefModule:PerExpansionChoice({
          classic = { 20749, 20746, 20744, 20750 },       -- Minor, Lesser, "regular", Brilliant Wizard Oil
          tbc = { 22522 },                                -- TBC: Superior Wizard Oil
          wotlk = { 36900 }
        }))                                               -- WotLK: Exceptional Wizard Oil
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
  enchantments[25122] = { 2623, 2626, 2627, 2628,         --Minor, Lesser, "regular", Brilliant Wizard Oil (enchantment)
    2678,                                                 -- TBC: Superior Wizard Oil (enchantment)
    3299 }                                                -- WotLK: Exceptional Wizard Oil (enchantment)

  --Blessed Wizard Oil
  self:RegisterEnchantment(allBuffs, 28898)
      :CreatesOrProvidedByItem({ 23123 })
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
  enchantments[28898] = { 2685 }   --Blessed Wizard Oil
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function enchantmentsModule:_SetupPhysicalEnchantments(allBuffs, enchantments)
  --
  -- Weightstones for blunt weapons
  --
  --Weightstone
  self:RegisterEnchantment(allBuffs, 16622)
      :CreatesOrProvidedByItem({ 12643, 7965, 3241, 3240, 3239 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
  enchantments[16622] = { 1703, 484, 21, 20, 19 }   -- Weightstone

  --TBC: Adamantite Weightstone +12 BLUNT +14 CRIT
  self:RegisterEnchantment(allBuffs, 34340)
      :CreatesOrProvidedByItem({ 28421 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :RequireTBC()
  enchantments[34340] = { 2955 }   --TBC: Adamantite Weightstone (Weight Weapon)

  --TBC: Fel Weightstone +12 BLUNT
  self:RegisterEnchantment(allBuffs, 34339)
      :CreatesOrProvidedByItem({ 28420 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :RequireTBC()
  enchantments[34339] = { 2954 }   --TBC: Fel Weightstone (Weighted +12)

  --
  -- Sharpening Stones for sharp weapons
  --
  --Sharpening Stone
  self:RegisterEnchantment(allBuffs, 16138)
      :CreatesOrProvidedByItem({ 12404, 7964, 2871, 2863, 2862 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
  enchantments[16138] = { 1643, 483, 14, 13, 40 }   --Sharpening Stone

  --Consecrated Sharpening Stone
  self:RegisterEnchantment(allBuffs, 28891)
      :CreatesOrProvidedByItem({ 23122 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
  enchantments[28891] = { 2684 }   --Consecrated Sharpening Stone

  --Elemental Sharpening Stone
  self:RegisterEnchantment(allBuffs, 22756)
      :CreatesOrProvidedByItem({ 18262 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
  enchantments[22756] = { 2506 }   --Elemental Sharpening Stone

  --TBC: Adamantite Sharpening Stone +12 WEAPON +14 CRIT
  self:RegisterEnchantment(allBuffs, 29453)
      :CreatesOrProvidedByItem({ 23529 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :RequireTBC()

  --TBC: Fel Sharpening Stone +12 WEAPON
  self:RegisterEnchantment(allBuffs, 29452)
      :CreatesOrProvidedByItem({ 23528 })
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :RequireTBC()
  enchantments[29452] = { 2712 }   --TBC: Fel Sharpening Stone (Sharpened +12)
  enchantments[29453] = { 2713 }   --TBC: Adamantite Sharpening Stone (Sharpened +14 Crit, +12)
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function enchantmentsModule:_SetupOtherEnchantments(allBuffs, enchantments)
  -- Rune of Warding
  --
  --TBC: Greater Rune of Warding
  buffDefModule:createAndRegisterBuff(allBuffs, 32282, nil)
      :RequireTBC()
      :CreatesOrProvidedByItem({ 25521 })
      :IsConsumable(true)
      :IsDefault(false)
      :ConsumableTarget("player")
      :SingleDuration(allBuffsModule.HOUR)
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("weaponEnchantment")
end
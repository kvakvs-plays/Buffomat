---@class HunterModule

local hunterModule = LibStub("Buffomat-AllSpellsHunter") --[[@as HunterModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

---Add HUNTER spells
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function hunterModule:SetupHunterSpells(allBuffs, enchantments)
  self:_SetupHunterSpellsTBC(allBuffs, enchantments)
  self:_SetupPetBuffs(allBuffs, enchantments)
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function hunterModule:_SetupHunterSpellsTBC(allBuffs, enchantments)
  -- Trueshot Aura
  buffDefModule:createAndRegisterBuff(allBuffs, 20906, nil)
      :IsOwn(true)
      :IsDefault(true)
      :SingleFamily({ 19506, 20905, 20906,   -- Trueshot Aura 1-3, WotLK: Trueshot Aura
        27066 })                             -- TBC: Trueshot Aura 4
      :RequirePlayerClass("HUNTER")
      :Category("aura")

  -- Aspect of the Hawk
  buffDefModule:createAndRegisterBuff(allBuffs, 25296, nil)
      :BuffType("aura")
      :IsDefault(true)
      :SingleFamily({ 13165, 14318, 14319, 14320, 14321, 14322, 25296,   -- Aspect of the Hawk 1-7
        27044,                                                           -- TBC: Aspect of the Hawk 8
        61846, 61847 })                                                  -- WotLK: Aspect of the Dragonhawk 1-2
      :RequirePlayerClass("HUNTER")
      :Category("class")

  --Aspect of the monkey
  buffDefModule:createAndRegisterBuff(allBuffs, 13163, nil)
      :BuffType("aura")
      :IsDefault(false)
      :MaxLevel(74)   -- Superceded by Aspect of the Dragonhawk
      :RequirePlayerClass("HUNTER")
      :Category("class")

  -- TBC: Aspect of the Viper
  buffDefModule:createAndRegisterBuff(allBuffs, 34074, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :RequireTBC()
      :Category("class")

  -- Aspect of the Wild
  buffDefModule:createAndRegisterBuff(allBuffs, 20190, nil)
      :BuffType("aura")
      :IsDefault(false)
      :SingleFamily({ 20043, 20190,   -- Aspect of the Wild 1-2
        27045,                        -- TBC: Aspect of the Wild 3
        49071 })                      -- WotLK: Aspect of the Wild 4
      :RequirePlayerClass("HUNTER")
      :Category("aura")
  --Aspect of the Cheetah
  buffDefModule:createAndRegisterBuff(allBuffs, 5118, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("class")
  --Aspect of the Pack
  buffDefModule:createAndRegisterBuff(allBuffs, 13159, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("aura")
  -- Aspect of the Beast
  buffDefModule:createAndRegisterBuff(allBuffs, 13161, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("class")
  -- Season of Discovery: Heart of the Lion (+10% stats)
  buffDefModule:createAndRegisterBuff(allBuffs, 409580, nil)   -- Chest Rune spell id 399954
      :BuffType("aura")
      :IgnoreIfHaveBuff({ 409580,                              -- the buff on hunter
        409583 })                                              -- the buff from aura
      :IsDefault(true)
      :RequirePlayerClass("HUNTER")
      :Category("class")

  -- Track Beast
  buffDefModule:createAndRegisterBuff(allBuffs, 1494, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Demon
  buffDefModule:createAndRegisterBuff(allBuffs, 19878, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Dragonkin
  buffDefModule:createAndRegisterBuff(allBuffs, 19879, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Elemental
  buffDefModule:createAndRegisterBuff(allBuffs, 19880, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Humanoids
  buffDefModule:createAndRegisterBuff(allBuffs, 19883, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Giants / riesen
  buffDefModule:createAndRegisterBuff(allBuffs, 19882, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Undead
  buffDefModule:createAndRegisterBuff(allBuffs, 19884, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")

  -- Track Hidden / verborgenes
  buffDefModule:createAndRegisterBuff(allBuffs, 19885, nil)
      :BuffType("aura")
      :IsDefault(false)
      :RequirePlayerClass("HUNTER")
      :Category("tracking")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function hunterModule:_SetupPetBuffs(allBuffs, enchantments)
  -- Kibler's Bits (TBC)
  buffDefModule:genericConsumable(allBuffs, 65247, 33874)
      :RequireTBC()
      :PetFood()
      :ExtraText(_t("tooltip.buff.petStrength"))
      :Category("pet")
  -- Sporeling Snack (TBC)
  buffDefModule:genericConsumable(allBuffs, 33272, 27656)
      :RequireTBC()
      :PetFood()
      :ExtraText(_t("tooltip.buff.petStamina"))
      :Category("pet")
  -- Spiced Mammoth Treats (WotLK)
  buffDefModule:genericConsumable(allBuffs, 43771, 43005)
      :RequireWotLK()
      :PetFood()
      :ExtraText(_t("tooltip.buff.petStrength"))
      :Category("pet")
  -- Crispy "Bakon" Snack (Cata) +75 STR
  buffDefModule:genericConsumable(allBuffs, 87697, 62678)
      :RequireCata()
      :PetFood()
      :ExtraText(_t("tooltip.buff.petStrength"))
      :Category("pet")
  -- Enriched Fish Biscuit (Cata) +110 STAM
  buffDefModule:genericConsumable(allBuffs, 87699, 62679)
      :RequireCata()
      :PetFood()
      :ExtraText(_t("tooltip.buff.petStamina"))
      :Category("pet")
end
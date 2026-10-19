---@class AllConsumesElixirsModule

local elixirsModule = LibStub("Buffomat-AllConsumesElixirs") --[[@as AllConsumesElixirsModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

---ELIXIRS
---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:SetupElixirs(allBuffs, enchantments)
  self:_SetupBattleCasterElixirsClassic(allBuffs, enchantments)
  self:_SetupBattlePhysicalElixirsClassic(allBuffs, enchantments)
  self:_SetupGuardianElixirsClassic(allBuffs, enchantments)

  self:_SetupBattleCasterElixirsTBC(allBuffs, enchantments)
  self:_SetupBattlePhysicalElixirsTBC(allBuffs, enchantments)
  self:_SetupGuardianElixirsTBC(allBuffs, enchantments)

  self:_SetupBattleElixirsWotLK(allBuffs, enchantments)
  self:_SetupBattleCasterElixirsWotLK(allBuffs, enchantments)
  self:_SetupBattlePhysicalElixirsWotLK(allBuffs, enchantments)
  self:_SetupGuardianElixirsWotLK(allBuffs, enchantments)

  self:_SetupElixirsCata(allBuffs, enchantments)
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattleCasterElixirsTBC(allBuffs, enchantments)
  --TBC: Elixir of Major Mageblood +16 mp5
  buffDefModule:genericConsumable(allBuffs, 28509, 22840)
      :RequireTBC()
      :Category("tbcSpellElixir")
      :ElixirType("battle")

  --TBC: Elixir of Major Shadow Power +55 SHADOW
  buffDefModule:genericConsumable(allBuffs, 28503, 22835)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.SHADOW_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("battle")

  --TBC: Elixir of Major Firepower +55 FIRE
  buffDefModule:genericConsumable(allBuffs, 28501, 22833)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.FIRE_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("battle")

  --TBC: Elixir of Major Frost Power +55 FROST
  buffDefModule:genericConsumable(allBuffs, 28493, 22827)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.FROST_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("battle")

  --TBC: Elixir of Healing Power +50 HEAL
  buffDefModule:genericConsumable(allBuffs, 28491, 22825)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("battle")

  --TBC: Adept's Elixir +24 SPELL, +24 SPELLCRIT
  buffDefModule:genericConsumable(allBuffs, 54452, 28103)   -- old TBC spell id 33721
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("battle")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattleCasterElixirsClassic(allBuffs, enchantments)
  --All Spell Power elixirs
  local spellPowerItemIds = {
    9155,      -- Arcane Elixir +20
    13454,     -- Greater Arcane Elixir +35
  }
  local spellPowerAuras = {
    11390,     -- +20 SPELL
    17539,     -- +35 SPELL
  }
  buffDefModule:consumableGroup(allBuffs, "elixirSpell", spellPowerAuras, spellPowerItemIds)
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :ElixirType("battle")
      :Category("classicSpellElixir")
      :ConsumeGroupTitle("elixir", ITEM_MOD_SPELL_POWER_SHORT, 132379)   -- "inv_alchemy_imbuedvial"
      :ExtraText(_t("tooltip.consumable.bestInBag"))

  -- Elixir of Shadow Power
  buffDefModule:genericConsumable(allBuffs, 11474, 9264)
      :RequirePlayerClass(allBuffsModule.SHADOW_CLASSES)
      :Category("classicSpellElixir")
      :ElixirType("battle")

  --Elixir of Greater Firepower
  buffDefModule:genericConsumable(allBuffs, 26276, 21546)
      :RequirePlayerClass(allBuffsModule.FIRE_CLASSES)
      :Category("classicSpellElixir")
      :ElixirType("battle")

  --Elixir of Frost Power
  buffDefModule:genericConsumable(allBuffs, 21920, 17708)
      :RequirePlayerClass(allBuffsModule.FROST_CLASSES)
      :Category("classicSpellElixir")
      :ElixirType("battle")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattlePhysicalElixirsClassic(allBuffs, enchantments)
  --Elixir of the Mongoose
  buffDefModule:genericConsumable(allBuffs, 17538, 13452)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysElixir")
      :ElixirType("battle")

  -- All Agility Elixirs
  local agilityItemIds = {
    2457,     -- Elixir of Minor Agility
    3390,     -- Elixir of Lesser Agility
    8949,     -- Elixir of Agility
    9187,     -- Elixir of Greater Agility
  }
  local agilityAuras = {
    2374,      -- +4 AGI
    3160,      -- +8 AGI
    11328,     -- +15 AGI
    11334,     -- +25 AGI
  }
  buffDefModule:consumableGroup(allBuffs, "elixirAgi", agilityAuras, agilityItemIds)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysElixir")
      :ElixirType("battle")
      :ConsumeGroupTitle("elixir", ITEM_MOD_AGILITY_SHORT, 132379)   -- "inv_alchemy_imbuedvial"
      :ExtraText(_t("tooltip.consumable.bestInBag"))

  --All Strength Elixirs
  local strItemIds = {
    2454,     -- Elixir of Lion's Strength +4
    3391,     -- Elixir of Ogre's Strength +8
    6662,     -- Elixir of Giant Growth +8 +size
    9206,     -- Elixir of Giants +25
  }
  local strAuras = {
    2367,      -- +4 STR
    3164,      -- +8 STR
    8212,      -- +8 STR +SIZE
    11405,     -- +25 STR
  }
  buffDefModule:consumableGroup(allBuffs, "elixirStr", strAuras, strItemIds)
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("classicPhysElixir")
      :ElixirType("battle")
      :ConsumeGroupTitle("elixir", ITEM_MOD_STRENGTH_SHORT, 132379)   -- "inv_alchemy_imbuedvial"
      :ExtraText(_t("tooltip.consumable.bestInBag"))
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattlePhysicalElixirsTBC(allBuffs, enchantments)
  --TBC: Elixir of Major Agility +35 AGI +20 CRIT
  buffDefModule:genericConsumable(allBuffs, 54494, 22831)   -- old TBC spell id 28497
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("tbcPhysElixir")
      :ElixirType("battle")

  --TBC: Fel Strength Elixir +90AP -10 STA
  buffDefModule:genericConsumable(allBuffs, 38954, 31679)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("tbcPhysElixir")
      :ElixirType("battle")

  --TBC: Elixir of Major Strength +35 STR
  buffDefModule:genericConsumable(allBuffs, 28490, 22824)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("tbcPhysElixir")
      :ElixirType("battle")

  --TBC: Onslaught Elixir +60 AP
  buffDefModule:genericConsumable(allBuffs, 33720, 28102)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("tbcPhysElixir")
      :ElixirType("battle")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattleCasterElixirsWotLK(allBuffs, enchantments)
  -- WotLK: Spellpower Elixir +58 SPELL
  buffDefModule:genericConsumable(allBuffs, 33721, 40070)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :Category("wotlkSpellElixir")
      :ElixirType("battle")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattlePhysicalElixirsWotLK(allBuffs, enchantments)
  -- WotLK: Elixir of Expertise +45
  buffDefModule:genericConsumable(allBuffs, 60344, 44329)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("wotlkPhysElixir")
      :ElixirType("battle")

  -- WotLK: Elixir of Deadly Strikes +45 Crit
  buffDefModule:genericConsumable(allBuffs, 60341, 44327)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("wotlkPhysElixir")
      :ElixirType("battle")

  -- WotLK: Wrath Elixir +90 AP
  buffDefModule:genericConsumable(allBuffs, 53746, 40068)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("wotlkPhysElixir")
      :ElixirType("battle")

  -- WotLK: Elixir of Armor Piercing +45 ARP
  buffDefModule:genericConsumable(allBuffs, 60345, 44330)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("wotlkPhysElixir")
      :ElixirType("battle")

  -- WotLK: Elixir of Mighty Agility +45 AGI
  buffDefModule:genericConsumable(allBuffs, 28497, 39666)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("wotlkPhysElixir")
      :ElixirType("battle")

  -- WotLK: Elixir of Mighty Strength +50 STR
  buffDefModule:genericConsumable(allBuffs, 53748, 40073)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("wotlkPhysElixir")
      :ElixirType("battle")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupGuardianElixirsTBC(allBuffs, enchantments)
  --TBC: Elixir of Draenic Wisdom +30 SPI
  buffDefModule:genericConsumable(allBuffs, 39627, 32067)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("guardian")

  --TBC: Elixir of Empowerment, -30 TARGET RESIST
  buffDefModule:genericConsumable(allBuffs, 28514, 22848)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("guardian")

  --Classic: Elixir of the Sages +18 INT/+18 SPI
  buffDefModule:genericConsumable(allBuffs, 17535, 13447)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("classicSpellElixir")
      :ElixirType("guardian")

  --TBC: Elixir of Mastery +15 all stats
  buffDefModule:genericConsumable(allBuffs, 33726, 28104)
      :RequireTBC()
      :Category("tbcElixir")
      :ElixirType("guardian")

  --TBC: Elixir of Major Defense +550 ARMOR
  buffDefModule:genericConsumable(allBuffs, 28502, 22834)
      :RequireTBC()
      :Category("tbcElixir")
      :ElixirType("guardian")

  --TBC: Elixir of Ironskin +30 RESIL
  buffDefModule:genericConsumable(allBuffs, 39628, 32068)
      :RequireTBC()
      :Category("tbcElixir")
      :ElixirType("guardian")

  --TBC: Elixir of Major Fortitude +250 HP and 10 HP/5
  buffDefModule:genericConsumable(allBuffs, 39625, 32062)
      :RequireTBC()
      :Category("tbcElixir")
      :ElixirType("guardian")

  --TBC: Earthen Elixir -20 ALL DMG TAKEN
  buffDefModule:genericConsumable(allBuffs, 39626, 32063)
      :RequireTBC()
      :Category("tbcElixir")
      :ElixirType("guardian")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupGuardianElixirsClassic(allBuffs, enchantments)
  -- Mageblood Potion
  buffDefModule:genericConsumable(allBuffs, 24363, 20007)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("classicSpellElixir")
      :ElixirType("guardian")

  --All Intellect elixirs
  local _intItemIds = {
    3383,     -- Elixir of Wisdom +6
    9179,     -- Elixir of Greater Intellect +25
  }
  local _intAuras = {
    3166,      -- +6 INT
    11396,     -- +25 INT
  }
  buffDefModule:genericConsumable(allBuffs, 11396, 9179)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("tbcSpellElixir")
      :ElixirType("guardian")

  --Elixir of Fortitude
  buffDefModule:genericConsumable(allBuffs, 3593, 3825)
      :Category("classicElixir")
      :ElixirType("guardian")

  --Elixir of Superior Defense
  buffDefModule:genericConsumable(allBuffs, 11348, 13445)
      :Category("classicElixir")
      :ElixirType("guardian")

  --All health regen elixirs
  local healthRegenItemIds = {
    3382,      -- Weak Troll's Blood Potion +2 hp/5
    3388,      -- Strong Troll's Blood Potion +6 hp/5
    20004,     -- Major Troll's Blood Potion +20 hp/5
  }
  local healthRegenAuras = {
    3219,      -- +2 hp/5
    3222,      -- +6 hp/5
    24361,     -- +20 hp/5
  }
  buffDefModule:consumableGroup(allBuffs, "elixirHp5", healthRegenAuras, healthRegenItemIds)
      :Category("classicElixir")
      :ElixirType("guardian")
      :ConsumeGroupTitle("elixir", ITEM_MOD_HEALTH_REGEN_SHORT, 132379)   -- "inv_alchemy_imbuedvial"
      :ExtraText(_t("tooltip.elixir.bestInBag"))

  --Gift of Arthas
  buffDefModule:genericConsumable(allBuffs, 11371, 9088)
      :Category("classicElixir")
      :ElixirType("guardian")

  --Greater Arcane Protection Potion
  buffDefModule:genericConsumable(allBuffs, 17549, 13461)
      :HideInTBC()   -- Becomes a 2-min potion buff
      :Category("classicElixir")
      :ElixirType("guardian")

  --Greater Fire Protection Potion
  buffDefModule:genericConsumable(allBuffs, 17543, 13457)
      :HideInTBC()   -- Becomes a 2-min potion buff
      :Category("classicElixir")
      :ElixirType("guardian")

  --Greater Frost Protection Potion
  buffDefModule:genericConsumable(allBuffs, 17544, 13456)
      :HideInTBC()   -- Becomes a 2-min potion buff
      :Category("classicElixir")
      :ElixirType("guardian")

  --Greater Nature Protection Potion
  buffDefModule:genericConsumable(allBuffs, 17546, 13458)
      :HideInTBC()   -- Becomes a 2-min potion buff
      :Category("classicElixir")
      :ElixirType("guardian")

  --Greater Shadow Protection Potion
  buffDefModule:genericConsumable(allBuffs, 17548, 13459)
      :HideInTBC()   -- Becomes a 2-min potion buff
      :Category("classicElixir")
      :ElixirType("guardian")

  -- Disabled on purpose; kept as data for a possible potions category
  -- luacheck: push ignore 511
  if false then
    --
    -- 2min potion buff not real elixirs
    --
    --Major Arcane Protection Potion (crafted and cauldron)
    buffDefModule:consumableGroup(allBuffs, "tbcArcaneProt", { 28536 }, { 22845, 32840 })
        :RequireTBC()
        :Category("tbcElixir")
        :ElixirType("guardian")
        :ConsumeGroupTitle("elixir", RESISTANCE6_NAME, 132379)     -- "inv_alchemy_imbuedvial"
        :ExtraText(_t("tooltip.elixir.bestInBag"))

    --Major Fire Protection Potion (crafted and cauldron)
    buffDefModule:consumableGroup(allBuffs, "tbcFireProt", { 28511 }, { 22841, 32846 })
        :RequireTBC()
        :Category("tbcElixir")
        :ElixirType("guardian")
        :ConsumeGroupTitle("elixir", RESISTANCE2_NAME, 132379)     -- "inv_alchemy_imbuedvial"
        :ExtraText(_t("tooltip.elixir.bestInBag"))

    --Major Frost Protection Potion (crafted and cauldron)
    buffDefModule:consumableGroup(allBuffs, "tbcFrostProt", { 28512 }, { 22842, 32847 })
        :RequireTBC()
        :Category("tbcElixir")
        :ElixirType("guardian")
        :ConsumeGroupTitle("elixir", RESISTANCE4_NAME, 132379)     -- "inv_alchemy_imbuedvial"
        :ExtraText(_t("tooltip.elixir.bestInBag"))

    --Major Nature Protection Potion (crafted and cauldron)
    buffDefModule:consumableGroup(allBuffs, "tbcNatureProt", { 28513 }, { 22844, 32844 })
        :RequireTBC()
        :Category("tbcElixir")
        :ElixirType("guardian")
        :ConsumeGroupTitle("elixir", RESISTANCE3_NAME, 132379)     -- "inv_alchemy_imbuedvial"
        :ExtraText(_t("tooltip.elixir.bestInBag"))

    --Major Shadow Protection Potion (crafted and cauldron)
    buffDefModule:consumableGroup(allBuffs, "tbcShadowProt", { 28537 }, { 22846, 32845 })
        :RequireTBC()
        :Category("tbcElixir")
        :ElixirType("guardian")
        :ConsumeGroupTitle("elixir", RESISTANCE5_NAME, 132379)     -- "inv_alchemy_imbuedvial"
        :ExtraText(_t("tooltip.elixir.bestInBag"))

    --Major Holy Protection Potion (crafted)
    buffDefModule:tbcConsumable(allBuffs, 28538, { 22847 })     -- RESISTANCE1_NAME
        :Category("tbcElixir")
        :ElixirType("guardian")
  end
  -- luacheck: pop
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupGuardianElixirsWotLK(allBuffs, enchantments)
  --WotLK: Elixir of Spirit +50
  buffDefModule:wotlkConsumable(allBuffs, 53747, 40072)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("wotlkSpellElixir")
      :ElixirType("guardian")

  --WotLK: Elixir of Mighty Mageblood +30 MP5
  buffDefModule:wotlkConsumable(allBuffs, 53764, 40109)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("wotlkSpellElixir")
      :ElixirType("guardian")

  --WotLK: Elixir of Protection +800 Armor
  buffDefModule:wotlkConsumable(allBuffs, 53763, 40097)
      :Category("wotlkElixir")
      :ElixirType("guardian")

  --WotLK: Elixir of Mighty Fortitude +350 HP and 20 HP/5
  buffDefModule:wotlkConsumable(allBuffs, 53751, 40078)
      :Category("wotlkElixir")
      :ElixirType("guardian")

  --WotLK: Elixir of Mighty Defense +45 DEFR
  buffDefModule:wotlkConsumable(allBuffs, 60343, 44328)
      :Category("wotlkPhysElixir")
      :ElixirType("guardian")

  --WotLK: Elixir of Mighty Thoughts +45 INT
  buffDefModule:wotlkConsumable(allBuffs, 60347, 44332)
      :Category("wotlkSpellElixir")
      :ElixirType("guardian")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupBattleElixirsWotLK(allBuffs, enchantments)
  --WotLK: Guru's Elixir +20 All Stats
  buffDefModule:wotlkConsumable(allBuffs, 53749, 40076)
      :Category("wotlkElixir")
      :ElixirType("guardian")

  --WotLK: Elixir of Lightning Speed +45 Haste
  buffDefModule:wotlkConsumable(allBuffs, 60346, 44331)
      :Category("wotlkElixir")
      :ElixirType("battle")

  --WotLK: Elixir of Accuracy +45 HIT
  buffDefModule:wotlkConsumable(allBuffs, 60340, 44325)
      :Category("wotlkElixir")
      :ElixirType("battle")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function elixirsModule:_SetupElixirsCata(allBuffs, enchantments)
  -- Cata: Elixir of the Naga; +225 Expertise
  buffDefModule:cataConsumable(allBuffs, 79474, 58089)
      :Category("cataElixir")
      :ElixirType("battle")

  -- Cata: Elixir of the Mighty Speed; +225 Haste
  buffDefModule:cataConsumable(allBuffs, 79632, 58144)
      :Category("cataElixir")
      :ElixirType("battle")

  -- Cata: Elixir of the Cobra; +225 Crit
  buffDefModule:cataConsumable(allBuffs, 79477, 58092)
      :Category("cataElixir")
      :ElixirType("battle")

  -- Cata: Elixir of the Impossible Accuracy; +225 Hit
  buffDefModule:cataConsumable(allBuffs, 79481, 58094)
      :Category("cataElixir")
      :ElixirType("battle")

  -- Cata: Elixir of the Master; +225 Mastery
  buffDefModule:cataConsumable(allBuffs, 79635, 58148)
      :Category("cataElixir")
      :ElixirType("battle")

  -- Cata: Ghost Elixir; +225 Spirit
  buffDefModule:cataConsumable(allBuffs, 79468, 58084)
      :Category("cataElixir")
      :ElixirType("battle")

  -- Cata: Elixir of Deep Earth; +900 Armor
  buffDefModule:cataConsumable(allBuffs, 79480, 58093)
      :Category("cataElixir")
      :ElixirType("guardian")

  -- Cata: Prismatic Elixir; +90 All Resist
  buffDefModule:cataConsumable(allBuffs, 79631, 58143)
      :Category("cataElixir")
      :ElixirType("guardian")

  -- Cata: Darkmoon Firewater +450 Attack +Size
  buffDefModule:cataConsumable(allBuffs, 109933, 78883)
      :Category("cataElixir")
      :ElixirType("battle")
end
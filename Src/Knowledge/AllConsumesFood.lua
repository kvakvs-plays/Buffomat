

---@class AllConsumesFoodModule

local foodModule = LibStub("Buffomat-AllConsumesFood") --[[@as AllConsumesFoodModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:SetupFood(allBuffs, enchantments)
  self:_SetupCasterFoodClassic(allBuffs, enchantments)
  self:_SetupPhysicalFoodClassic(allBuffs, enchantments)
  self:_SetupMiscFoodClassic(allBuffs, enchantments)

  self:_SetupCasterFoodTBC(allBuffs, enchantments)
  self:_SetupPhysicalFoodTBC(allBuffs, enchantments)
  self:_SetupMiscFoodTBC(allBuffs, enchantments)

  self:_SetupCasterFoodWotLK(allBuffs, enchantments)
  self:_SetupPhysicalFoodWotLK(allBuffs, enchantments)
  self:_SetupMiscFoodWotLK(allBuffs, enchantments)

  self:_SetupMiscFoodCata(allBuffs, enchantments)
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupMiscFoodTBC(allBuffs, enchantments)
  --Well Fed +30 STA +20 SPI
  buffDefModule:tbcConsumable(allBuffs, 33257, { 33052, 27667 })
      :ExtraText(_t("tooltip.buff.stamina"))
      :Category("tbcFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)

  --Well Fed +20 STA +20 SPI
  buffDefModule:tbcConsumable(allBuffs, 35254, { 27651, 30155, 27662, 33025 })
      :ExtraText(_t("tooltip.buff.stamina"))
      :Category("tbcFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)

  --Skyguard Rations: Well Fed +15 STA +15 SPI
  buffDefModule:tbcConsumable(allBuffs, 41030, 32721)
      :ExtraText(_t("tooltip.buff.stamina"))
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("tbcFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupPhysicalFoodTBC(allBuffs, enchantments)
  --All Well Fed providers for +20 AGI +20 SPI
  local agiFoodItemIds = {
    27659, -- Warp Burger +20 AGI/SPI
    30358, -- Oronok's Tuber of Agility
    27664, -- Grilled Mudfish +20 AGI/SPI
  }
  local agiFoodAuras = {
    33261, -- Well Fed, +20 Agility, +20 Spirit
  }
  buffDefModule:consumableGroup(allBuffs, "tbcAgiFood", agiFoodAuras, agiFoodItemIds)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("tbcPhysFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
      :ConsumeGroupTitle("food", ITEM_MOD_AGILITY_SHORT .. ", " .. ITEM_MOD_SPIRIT_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  --Spicy Hot Talbuk: Well Fed +20 HITRATING +20 SPI
  buffDefModule:tbcConsumable(allBuffs, 43764, 33872)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :ExtraText(_t("tooltip.buff.hit"))
      :Category("tbcPhysFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)

  -- Well Fed +20 STR +20 SPI
  local strFoodItemIds = {
    27658,
    30359,
  }
  local strFoodAuras = {
    33256,
  }
  buffDefModule:consumableGroup(allBuffs, "tbcStrFood", strFoodAuras, strFoodItemIds)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("tbcPhysFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
      :ConsumeGroupTitle("food", ITEM_MOD_STRENGTH_SHORT .. ", " .. ITEM_MOD_SPIRIT_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  --Ravager Dog: Well Fed +40 AP +20 SPI
  buffDefModule:tbcConsumable(allBuffs, 33259, 27655)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :ExtraText(_t("tooltip.buff.attackPower"))
      :Category("tbcPhysFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)

  -- Charred Bear Kabobs +24 AP
  buffDefModule:tbcConsumable(allBuffs, 46899, 35563)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :ExtraText(_t("tooltip.buff.attackPower"))
      :Category("tbcPhysFood")
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupCasterFoodTBC(allBuffs, enchantments)
  -- All Well Fed providers +23 SPELL +20 SPI
  local spellFoodItemIds = {
    27657, -- Blackened Basilisk
    31673, -- Crunchy Serpent
    27665, -- Poached Bluefish
    30361, -- Oronok's Tuber of Spell Power
  }
  local spellFoodAuras = {
    33263, -- Well Fed, +23 Spell, +20 Spirit
  }
  buffDefModule:consumableGroup(allBuffs, "tbcSpellFood", spellFoodAuras, spellFoodItemIds)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
      :Category("tbcSpellFood")
      :ConsumeGroupTitle("food", ITEM_MOD_SPELL_POWER_SHORT .. ", " .. ITEM_MOD_SPIRIT_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- Blackened Sporefish: Well Fed +8 MP5 +20 STA
  buffDefModule:tbcConsumable(allBuffs, 33265, 27663)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
      :ExtraText(_t("tooltip.buff.mp5"))
      :Category("tbcSpellFood")

  -- All Well Fed providers +44 HEAL +20 SPI
  local healFoodItemIds = {
    27666, -- Golden Fish Sticks
    30357, -- Oronok's Tuber of Healing
  }
  local healFoodAuras = {
    33268, -- Well Fed, +44 Healing, +20 Spirit
  }
  buffDefModule:consumableGroup(allBuffs, "tbcHealFood", healFoodAuras, healFoodItemIds)
      :RequireTBC()
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
      :Category("tbcSpellFood")
      :ConsumeGroupTitle("food", _t("Healing Power") .. ", " .. ITEM_MOD_SPIRIT_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- Skullfish Soup +20 Spell Crit/20 Spirit
  buffDefModule:tbcConsumable(allBuffs, 43722, 33825)
      :IgnoreIfHaveBuff(spellIdsModule.TBCFood)
      :IgnoreIfHaveBuff(43706) -- Drinking 240 mana/second
      :ExtraText(_t("tooltip.buff.spellCrit"))
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :Category("tbcSpellFood")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupCasterFoodClassic(allBuffs, enchantments)
  -- STAM/SPIRIT
  local stamSpiritFoodIds = {
    -- Level 1: 2 STA/2 SPI - Trainer: Herb Baked Egg, Spiced Wolf Meat, Cactus Apple Surprise (Quest)
    --          Recipe: Beer Basted Boar Ribs, Crispy Bat Wing, Kaldorei Spider Kabob, Roasted Kodo Meat
    6888, 2680, 11584,
    2888, 12224, 5472, 5474,
    -- Level 5: 4 STA/4 SPI - Trainer: Boiled Clams, Coyote Steak, Crab Cake, Dry Pork Ribs
    --          Recipe: Blood Sausage, Crocolisk Steak, Fillet of Frenzy, Goretusk Liver Pie, Strider Stew
    5525, 2684, 2683, 2687,
    3220, 3662, 5476, 724, 5477,
    -- Level 15: 6 STA/6 SPI - Trainer:  Goblin Deviled Clams, Recipe: Big Bear Steak, Crispy Lizard Tail (level 12),
    --          Crocolisk Gumbo, Curiously Tasty Omelet, Gooey Spider Cake, Hot Lion Chops, Lean Venison,
    --          Lean Wolf Steak, Murloc Fin Soup, Redridge Goulash (level 10), Seasoned Wolf Kabob
    5527,
    3276, 5479, 3664, 3665, 3666, 3727, 5480, 12209, 3663, 1082, 1017,
    -- Level 25: 8 STA/8 SPI - Recipe: Carrion Surprise, Giant Clam Scorcho, Heavy Crocolisk Stew (level 20),
    --          Hot Wolf Ribs, Jungle Stew, Mystery Stew, Roast Raptor, Soothing Turtle Bisque, Tasty Lion Steak (level 20)
    12213, 6038, 20074, 13851, 12212, 12214, 12210, 3729, 3728,
    -- Level 35: 12 STA/12 SPI - Trainer: Spider Sausage, Recipe:  Heavy Kodo Stew
    17222, 12215,
    -- Level 40: 12 STA/12 SPI - Recipe:  Monster Omelet, Spiced Chili Crab, Tender Wolf Steak; Quest: Clamlette Surprise
    12218, 12216, 18045,
    16971,
  }
  local stamSpiritAuras = {
    19705, -- 2 STA/2 SPI
    19706, -- 4 STA/4 SPI
    19708, -- 6 STA/6 SPI
    19709, -- 8 STA/8 SPI
    19710, -- 12 STA/12 SPI
  }
  buffDefModule:consumableGroup(allBuffs, "foodStamSpirit", stamSpiritAuras, stamSpiritFoodIds)
      :Category("classicFood")
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :ConsumeGroupTitle("food", ITEM_MOD_STAMINA_SHORT .. " " .. ITEM_MOD_SPIRIT_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- MP5 Food
  -- Smoked Sagefish - level 10, 3 mana/5 seconds for 15 minutes.
  -- Sagefish Delight - level 30, 6 mana/5 seconds for 15 minutes.
  -- Nightfin Soup - level 35, 8 mana/5 seconds for 15 minutes.
  local mp5FoodIds = {
    21072, -- Smoked Sagefish
    21217, -- Sagefish Delight
    13931, -- Nightfin Soup
  }
  local mp5FoodAuras = {
    25694, -- Well fed, 3 mp/5
    25941, -- Well fed, 6 mp/5
    18194, -- Well fed, 8 mp/5
  }
  buffDefModule:consumableGroup(allBuffs, "foodMp5", mp5FoodAuras, mp5FoodIds)
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("classicSpellFood")
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :ConsumeGroupTitle("food", ITEM_MOD_MANA_REGENERATION_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  --Blessed Sunfruit Juice +10 SPIRIT
  buffDefModule:genericConsumable(allBuffs, 18141, 13813)
      :ExtraText(_t("tooltip.buff.spirit"))
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :Category("classicSpellFood")

  --Runn Tum Tuber Surprise
  buffDefModule:genericConsumable(allBuffs, 22730, 18254)
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :Category("classicSpellFood")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupMiscFoodClassic(allBuffs, enchantments)
  buffDefModule:genericConsumable(allBuffs, 25661, 21023) -- Dirge's Kickin' Chimaerok Chops x
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :Category("classicFood")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupPhysicalFoodClassic(allBuffs, enchantments)
  --Grilled Squid +10 Agility
  buffDefModule:genericConsumable(allBuffs, 18192, 13928)
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysFood")

  --Smoked Desert Dumplings +Strength
  buffDefModule:genericConsumable(allBuffs, 24799, 20452)
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysFood")

  --Blessed Sunfruit +STR
  buffDefModule:genericConsumable(allBuffs, 18125, 13810)
      :IgnoreIfHaveBuff(spellIdsModule.ClassicFood)
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :Category("classicPhysFood")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupCasterFoodWotLK(allBuffs, enchantments)
  -- All Spirit food buff providers
  local spiFoodItemIds = {
    42779, -- Steaming Chicken Soup +25 Stam/25 Spi
    42998, -- Cuttlesteak 40 Spirit/40 Stam
  }
  local spiFoodAuras = {
    53284, -- Well Fed, +25 Stamina, +25 Spirit
    57365, -- Well Fed, +40 Spirit, +40 Stamina
  }
  buffDefModule:consumableGroup(allBuffs, "wotlkSpiritFood", spiFoodAuras, spiFoodItemIds)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                 -- [Food] While eating Cuttlesteak
      :Category("wotlkSpellFood")
      :ConsumeGroupTitle("food", ITEM_MOD_SPIRIT_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- All Spell Power Food buff providers
  local spellFoodItemIds = {
    34749,        -- Shoveltusk Steak +35 Spell/30 Stam
    34763,        -- Smoked Salmon, +35 Spell/40 Stam
    34755, 34767, -- Tender Shoveltusk Steak/Firecracker Salmon +46 Spell/40 Stam
  }
  local spellFoodAuras = {
    57139, -- Well Fed, +35 Spell, +30 Stamina
    57097, -- Well Fed, +35 Spell, +40 Stamina
    57327, -- Well Fed, +46 Spell, +40 Stamina
  }
  buffDefModule:consumableGroup(allBuffs, "wotlkSpellFood", spellFoodAuras, spellFoodItemIds)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                      -- [Food] While eating Shoveltusk Steak
      :Category("wotlkSpellFood")
      :ConsumeGroupTitle("food", ITEM_MOD_SPELL_POWER_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- All Mana per 5 Food buff providers
  local mp5FoodItemIds = {
    34765, 34752, -- Pickled Fangtooth/Rhino Dogs +15 mp5/40 Stam
    34758, 42993, -- Mighty Rhino Dogs/Spicy Fried Herring +20 mp5/40 Stam
  }
  local mp5FoodAuras = {
    57107, -- Well Fed, +15 Mana every 5 seconds, +40 Stamina
    57334, -- Well Fed, +20 Mana every 5 seconds, +40 Stamina
  }

  buffDefModule:consumableGroup(allBuffs, "wotlkMp5Food", mp5FoodAuras, mp5FoodItemIds)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                            -- [Food] While eating Pickled Fangtooth/Rhino Dogs
      :Category("wotlkSpellFood")
      :ConsumeGroupTitle("food", ITEM_MOD_MANA_REGENERATION_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupPhysicalFoodWotLK(allBuffs, enchantments)
  --
  -- Strength Food
  --
  -- Dragonfin Filet +40 Str/40 Stam
  buffDefModule:wotlkConsumable(allBuffs, 57371, 43000)
      :ExtraText(_t("tooltip.buff.strength"))
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Dragonfin Filet
      :Category("wotlkPhysFood")
  --
  -- Agility Food
  --
  -- Blackened Dragonfin +40 Agi/40 Stam
  buffDefModule:wotlkConsumable(allBuffs, 57367, 42999)
      :ExtraText(_t("tooltip.buff.agility"))
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Blackened Dragonfin
      :Category("wotlkPhysFood")

  -- All Attack Power Food buff providers
  local apFoodItemIds = {
    34748,        -- Mammoth Meal +60 AP/30 Stam
    34762,        -- Grilled Sculpin +60 AP/40 Stam
    34762, 34766, -- Mega Mammoth Meal/Poached Northern Sculpin +80 AP/40 Stam
  }
  local apFoodAuras = {
    57111, -- Well Fed, +60 Attack Power, +30 Stamina
    57079, -- Well Fed, +60 Attack Power, +40 Stamina
    57325, -- Well Fed, +80 Attack Power, +40 Stamina
  }

  buffDefModule:consumableGroup(allBuffs, "wotlkApFood", apFoodAuras, apFoodItemIds)
      :RequireWotLK()
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                       -- [Food] While eating Mega Mammoth Meal/Poached Northern Sculpin
      :Category("wotlkPhysFood")
      :ConsumeGroupTitle("food", ITEM_MOD_ATTACK_POWER_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))
  --
  -- Expertise Food
  --
  -- Rhinolicious Wormsteak +40 Expert/40 Stam
  buffDefModule:wotlkConsumable(allBuffs, 57356, 42994)
      :ExtraText(_t("tooltip.buff.attackPower"))
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Rhinolicious Wormsteak
      :Category("wotlkPhysFood")
  --
  -- Armor Pen Food
  --
  -- Hearty Rhino +40 Armor Pen/40 Stam
  buffDefModule:wotlkConsumable(allBuffs, 57358, 42995)
      :ExtraText(_t("tooltip.buff.armorPenetration"))
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Hearty Rhino
      :Category("wotlkPhysFood")
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupMiscFoodWotLK(allBuffs, enchantments)
  -- All Haste Food buff providers
  --
  local hasteFoodItemIds = {
    34751,        -- Roasted Worg +30 Haste/30 Stam
    42942,        -- Baked Manta Ray +30 Haste/40 Stam
    34757, 34769, -- Very Burnt Worg/Imperial Manta Steak +40 Haste/40 Stam
  }
  local hasteFoodAuras = {
    57288, -- Well Fed, +30 Haste, +30 Stamina
    57102, -- Well Fed, +30 Haste, +40 Stamina
    57332, -- Well Fed, +40 Haste, +40 Stamina
  }

  buffDefModule:consumableGroup(allBuffs, "wotlkHasteFood", hasteFoodAuras, hasteFoodItemIds)
      :RequireWotLK()
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                                    -- [Food] While eating Very Burnt Worg/Imperial Manta Steak
      :Category("wotlkFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_HASTE_RATING_SHORT or "Haste") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- All HIT Food buff providers
  local hitFoodItemIds = {
    44953, 42996,                  -- Worg Tartare/Snapper Extreme +40 Hit/40 Stam
  }
  local hitFoodAuras = { 57360 } -- Well Fed, +40 Hit, +40 Stamina
  buffDefModule:consumableGroup(allBuffs, "wotlkHitFood", hitFoodAuras, hitFoodItemIds)
      :RequireWotLK()
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                                -- [Food] While eating Worg Tartare/Snapper Extreme
      :Category("wotlkFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_HIT_RATING_SHORT or "Hit") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  -- All Crit Food buff providers
  local critFoodItemIds = {
    34750,        -- Worm Delight 30 Crit/30 Stam
    34764,        -- Poached Nettlefish 30 Crit/40 Stam
    34768, 34756, -- Spicy Blue Nettlefish/Spiced Worm Burger +40 Crit/40 Stam
  }
  local critFoodAuras = {
    57286, -- Well Fed, +30 Critical Strike, +30 Stamina
    57100, -- Well Fed, +30 Critical Strike, +40 Stamina
    57329, -- Well Fed, +40 Critical Strike, +40 Stamina
  }

  buffDefModule:consumableGroup(allBuffs, "wotlkCritFood", critFoodAuras, critFoodItemIds)
      :RequireWotLK()
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood)                                                                  -- [Food] While eating Spicy Blue Nettlefish/Spiced Worm Burger
      :Category("wotlkFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_CRIT_RATING_SHORT or "Crit") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))                                                                     --

  -- All Combo Food Buff providers
  local comboFoodItemIds = {
    43268, 34753, -- Dalaran Clam Chowder/Great Feast +60 ATK/+35 Spell/+30 Stam
    43015,        -- Fish Feast +80 ATK/+46 Spell/+40 Stam
  }
  local comboFoodAuras = {
    57294, -- Well Fed, +60 Attack Power, +35 Spell Power, +30 Stamina
    57399, -- Well Fed, +80 Attack Power, +46 Spell Power, +40 Stamina
  }
  buffDefModule:consumableGroup(allBuffs, "wotlkComboMeal", comboFoodAuras, comboFoodItemIds)
      :RequireWotLK()
      :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Fish Feast
      :Category("wotlkFood")
      :ConsumeGroupTitle("food",
        ITEM_MOD_SPELL_POWER_SHORT .. ", " .. ITEM_MOD_ATTACK_POWER_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))
end

---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foodModule:_SetupMiscFoodCata(allBuffs, enchantments)
  -- All Food buff providers
  local intFoodItemIds = {
    62671, -- Severed Sagefish Head +90 Int & Stam
    62660, -- Pickled Guppy +60 Int & Stam
  }
  local intFoodAuras = {
    100368, -- +90 Stamina & Intellect
    87558,  -- +60 Stamina & Intellect
  }
  buffDefModule:consumableGroup(allBuffs, "cataIntFood", intFoodAuras, intFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                     -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", ITEM_MOD_INTELLECT_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local spiritFoodItemIds = {
    62656, -- Delicious Sagefish Tail +90 Spirit & Stam
    62666, -- Whitecrest Gumbo +60 Spirit & Stam
  }
  local spiritFoodAuras = {
    87547, 87548, 100375, -- +90 Stamina & Spirit
    87559,                -- +60 Stamina & Spirit
  }
  buffDefModule:consumableGroup(allBuffs, "cataSpiFood", spiritFoodAuras, spiritFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                  -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", ITEM_MOD_SPIRIT_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local agiFoodItemIds = {
    62669, -- Skewered Eel +90 Agility & Stam
    62658, -- Tender Baked Turtle +60 Agility & Stam
  }
  local agiFoodAuras = {
    87546, 100373, -- +90 Stamina & Agility
    87557,         -- +60 Stamina & Agility
  }
  buffDefModule:consumableGroup(allBuffs, "cataAgiFood", agiFoodAuras, agiFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                   -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", ITEM_MOD_AGILITY_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local strFoodItemIds = {
    62670, -- Beer-Basted Crocolisk +90 Strength & Stam
    62659, -- Hearty Seafood Soup +60 Strength & Stam
  }
  local strFoodAuras = {
    87545, 100377, -- +90 Stamina & Strength
    87556,         -- +60 Stamina & Strength
  }
  buffDefModule:consumableGroup(allBuffs, "cataStrFood", strFoodAuras, strFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                    -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", ITEM_MOD_STRENGTH_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local masteryFoodItemIds = {
    62663, -- Lavascale Minestrone +90 Mastery & Stam
    62653, -- Salted Eye +60 Mastery & Stam
  }
  local masteryFoodAuras = {
    87549, -- +90 Stamina & Mastery
    87560, -- +60 Stamina & Mastery
  }
  buffDefModule:consumableGroup(allBuffs, "cataMasteryFood", masteryFoodAuras, masteryFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                                         -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_MASTERY_RATING_SHORT or "Mastery") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local expertiseFoodItemIds = {
    62664, -- Crocolisk Au Gratin +90 Expertise & Stam
    62654, -- Lavascale Fillet +60 Expertise & Stam
  }
  local expertiseFoodAuras = {
    87635, -- +90 Stamina & Expertise
    87634, -- +60 Stamina & Expertise
  }
  buffDefModule:consumableGroup(allBuffs, "cataExpFood", expertiseFoodAuras, expertiseFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood) -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_EXPERTISE_RATING_SHORT or "Expertise") .. ", " .. ITEM_MOD_STAMINA_SHORT,
        134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local hitFoodItemIds = {
    62662, -- Grilled Dragon +90 Hit & Stam
    62652, -- Seasoned Crab +60 Hit & Stam
  }
  local hitFoodAuras = {
    87550, -- +90 Stamina & Hit
    87561, -- +60 Stamina & Hit
  }
  buffDefModule:consumableGroup(allBuffs, "cataHitFood", hitFoodAuras, hitFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                                 -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_HIT_RATING_SHORT or "Hit") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local hasteFoodItemIds = {
    62665, -- Basilisk Liverdog +90 Haste & Stam
    62655, -- Broiled Mountain Trout +60 Haste & Stam
  }
  local hasteFoodAuras = {
    87552, -- +90 Stamina & Haste
    87563, -- +60 Stamina & Haste
  }
  buffDefModule:consumableGroup(allBuffs, "cataHasteFood", hasteFoodAuras, hasteFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                                     -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_HASTE_RATING_SHORT or "Haste") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local critFoodItemIds = {
    62661, -- Baked Rockfish +90 Crit & Stam
    62651, -- Lightly Fried Lurker +60 Crit & Stam
  }
  local critFoodAuras = {
    87551, 87562, -- +60 Stamina & Crit
  }
  buffDefModule:consumableGroup(allBuffs, "cataCritFood", critFoodAuras, critFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                                   -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_CRIT_RATING_SHORT or "Crit") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local dodgeFoodItemIds = {
    62667, -- Mushroom Sauce Mudfish +90 Dodge & Stam
    62657, -- Lurker Lunch +60 Dodge & Stam
  }
  local dodgeFoodAuras = {
    87554, -- +90 Stamina & Dodge
    87564, -- +60 Stamina & Dodge
  }
  buffDefModule:consumableGroup(allBuffs, "cataDodgeFood", dodgeFoodAuras, dodgeFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                                     -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_DODGE_RATING_SHORT or "Dodge") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  local parryFoodItemIds = {
    62668, -- Blackbelly Sushi +90 Parry & Stam
    --, --  +60 Parry & Stam
  }
  local parryFoodAuras = {
    87555, -- +90 Stamina & Parry
    87565, -- +60 Stamina & Parry
  }
  buffDefModule:consumableGroup(allBuffs, "cataParryFood", parryFoodAuras, parryFoodItemIds)
      :RequireCata()
      :IgnoreIfHaveBuff(spellIdsModule.CataFood)                                                                     -- [Food] While eating
      :Category("cataFood")
      :ConsumeGroupTitle("food", (ITEM_MOD_PARRY_RATING_SHORT or "Parry") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
      :ExtraText(_t("tooltip.food.bestInBag"))

  ---- All HIT Food buff providers
  --local hitFoodItemIds = {
  --  34751, 42996, -- Worg Tartare/Snapper Extreme +40 Hit/40 Stam
  --}
  --local hasteFoodAuras = { 57360 } -- Well Fed, +40 Hit, +40 Stamina
  --buffDefModule:consumableGroup(allBuffs, "wotlkHitFood", hasteFoodAuras, hasteFoodItemIds)
  --             :RequireWotLK()
  --             :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Worg Tartare/Snapper Extreme
  --             :Category("wotlkFood")
  --             :ConsumeGroupTitle("food", (ITEM_MOD_HIT_RATING_SHORT or "Hit") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
  --             :ExtraText(_t("tooltip.food.bestInBag"))
  --
  ---- All Crit Food buff providers
  --local critFoodItemIds = {
  --  34750, -- Worm Delight 30 Crit/30 Stam
  --  34764, -- Poached Nettlefish 30 Crit/40 Stam
  --  34768, 34756, -- Spicy Blue Nettlefish/Spiced Worm Burger +40 Crit/40 Stam
  --}
  --local critFoodAuras = {
  --  57286, -- Well Fed, +30 Critical Strike, +30 Stamina
  --  57100, -- Well Fed, +30 Critical Strike, +40 Stamina
  --  57329, -- Well Fed, +40 Critical Strike, +40 Stamina
  --}
  --
  --buffDefModule:consumableGroup(allBuffs, "wotlkCritFood", critFoodAuras, critFoodItemIds)
  --             :RequireWotLK()
  --             :IgnoreIfHaveBuff(spellIdsModule.WotLKFood) -- [Food] While eating Spicy Blue Nettlefish/Spiced Worm Burger
  --             :Category("wotlkFood")
  --             :ConsumeGroupTitle("food", (ITEM_MOD_CRIT_RATING_SHORT or "Crit") .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
  --             :ExtraText(_t("tooltip.food.bestInBag"))  --

  -- All Combo Food Buff providers
  local _comboFoodItemIds = {
    62290, -- Seafood Magnifique Feast; +90 Stam/90 other stat
    62649, -- Fortune Cookie; +90 Stam/90 other stat
    60858, -- Goblin Barbecue; +60 Stam/60 other stat
    62289, -- Broiled Dragon Feast; +60 Stam/60 other stat
  }
  -- TODO: Figure out auras provided by combo meals
  --buffDefModule:consumableGroup(allBuffs, "cataComboMeal", cataFoodAuras, comboFoodItemIds)
  --             :RequireCata()
  --             :IgnoreIfHaveBuff(spellIdsModule.CataFood) -- [Food] While eating Feast
  --             :Category("cataFood")
  --             :ConsumeGroupTitle("food", ITEM_MOD_SPELL_POWER_SHORT .. ", " .. ITEM_MOD_ATTACK_POWER_SHORT .. ", " .. ITEM_MOD_STAMINA_SHORT, 134062) -- "inv_misc_fork-knife"
  --             :ExtraText(_t("tooltip.food.bestInBag"))
end
local addonName, ns = ...
-- WoW: Forever consumables (build 1.60.1.70862), set up only on Forever.
-- Item and aura IDs come from the Forever client data. To refresh the food lists, see
-- .agents/wowf-scan/reports/forever-food-by-aura.txt and .agents/wowf-plan.md.

---@class AllConsumesForeverModule

local foreverModule = LibStub("Buffomat-AllConsumesForever") --[[@as AllConsumesForeverModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local enchantmentsModule = LibStub("Buffomat-AllConsumesEnchantments") --[[@as AllConsumesEnchantmentsModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

local ICON_FOOD = 134062   -- inv_misc_fork-knife
local ICON_ELIXIR = 132379 -- inv_alchemy_imbuedvial
local ICON_SCROLL = 237162 -- inv_inscription_scroll

---@type ClassName[]
local HEALER_CLASSES = { "PRIEST", "DRUID", "SHAMAN", "PALADIN" }

---Blizzard stat label, or an English fallback where a client lacks the global string.
---@param globalName string
---@param fallback string
---@return string
local function label(globalName, fallback)
  local text = _G[globalName]
  return type(text) == "string" and text or fallback
end

---Auras present while eating or drinking; food tasks wait until the meal is over.
---@return WowSpellId[]
local function eatingAuras()
  local result = {}
  for _, list in ipairs({ spellIdsModule.ClassicFood, spellIdsModule.ForeverFood }) do
    for _, id in ipairs(list) do
      table.insert(result, id)
    end
  end
  return result
end

---@param allBuffs BomBuffDefinition[]
---@param auras WowSpellId[] Well Fed auras the foods give
---@param itemIds WowItemId[] Foods, lowest level first
---@param category BuffCategoryName
---@param title string
---@return BomBuffDefinition
local function addFoodGroup(allBuffs, auras, itemIds, category, title)
  return buffDefModule:consumableGroup(allBuffs, "", auras, itemIds)
      :Category(category)
      :IgnoreIfHaveBuff(eatingAuras())
      :ConsumeGroupTitle("food", title, ICON_FOOD)
      :ExtraText(_t("tooltip.food.bestInBag"))
      :RequireForever()
end

---@param allBuffs BomBuffDefinition[]
---@param auras WowSpellId[]
---@param itemIds WowItemId[] Lowest level first
---@param category BuffCategoryName
---@param title string
---@return BomBuffDefinition
local function addElixirGroup(allBuffs, auras, itemIds, category, title)
  return buffDefModule:consumableGroup(allBuffs, "", auras, itemIds)
      :Category(category)
      :ConsumeGroupTitle("elixir", title, ICON_ELIXIR)
      :ExtraText(_t("tooltip.elixir.bestInBag"))
      :RequireForever()
end

---Set up every Forever-only consumable. Classic consumables which did not change are set up by
---the other AllConsumes modules as usual.
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foreverModule:SetupForeverConsumables(allBuffs, enchantments)
  self:_SetupFood(allBuffs)
  self:_SetupElixirs(allBuffs)
  self:_SetupFlasks(allBuffs)
  self:_SetupScrolls(allBuffs)
  self:_SetupImbueScrolls(allBuffs, enchantments)
end

---Forever food gives one stat per Well Fed aura, with values that grow with the food's level.
---@param allBuffs BomBuffDefinition[]
function foreverModule:_SetupFood(allBuffs)
  -- Well Fed: Stamina
  addFoodGroup(allBuffs, { 1248406 }, {
    3663, -- L1 Murloc Fin Soup
    5472, -- L1 Kaldorei Spider Kabob
    5474, -- L1 Roasted Kodo Meat
    6888, -- L1 Herb Baked Egg
    5479, -- L5 Crispy Lizard Tail
    12213, -- L5 Carrion Surprise
    250080, -- L5 Breakfast Omelette
    263509, -- L5 Skywall Souffle
    268912, -- L5 Expiring Crab Cake
    268913, -- L5 Expiring Crocolisk Steak
    3665, -- L15 Curiously Tasty Omelet
    3666, -- L15 Gooey Spider Cake
    3729, -- L15 Soothing Turtle Bisque
    12214, -- L15 Mystery Stew
    6038, -- L25 Giant Clam Scorcho
    12215, -- L25 Heavy Kodo Stew
    250078, -- L25 Giant Scrambled Eggs
    12218, -- L35 Monster Omelet
    17222, -- L35 Spider Sausage
    250068, -- L45 Savory Turtle Stew
  }, "classicFood", label("ITEM_MOD_STAMINA_SHORT", "Stamina"))

  -- Well Fed: Armor
  addFoodGroup(allBuffs, { 1319310 }, {
    286152, -- L35 Plated Armorfish
  }, "classicFood", label("RESISTANCE0_NAME", "Armor"))

  -- Well Fed: Agility
  addFoodGroup(allBuffs, { 1248420 }, {
    2680, -- L1 Spiced Wolf Meat
    287973, -- L1 Tender Wolf Steak
    2684, -- L5 Coyote Steak
    3662, -- L5 Crocolisk Steak
    1017, -- L15 Seasoned Wolf Kabob
    3664, -- L15 Crocolisk Gumbo
    3727, -- L15 Hot Lion Chops
    12209, -- L15 Lean Wolf Steak
    3728, -- L25 Tasty Lion Steak
    13851, -- L25 Hot Wolf Ribs
    20074, -- L25 Heavy Crocolisk Stew
    12212, -- L35 Jungle Stew
    18045, -- L35 Tender Wolf Steak
    250069, -- L45 Flank au Poivre
    250072, -- L45 Swiftstrike Steak
  }, "classicPhysFood", label("ITEM_MOD_AGILITY_SHORT", "Agility"))
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)

  -- Well Fed: Strength
  addFoodGroup(allBuffs, { 1248422 }, {
    2681, -- L1 Roasted Boar Meat
    2888, -- L1 Beer Basted Boar Ribs
    6890, -- L1 Smoked Bear Meat
    724, -- L5 Goretusk Liver Pie
    2687, -- L5 Dry Pork Ribs
    3220, -- L5 Blood Sausage
    3726, -- L5 Big Bear Steak
    2685, -- L15 Succulent Pork Ribs
    5480, -- L15 Lean Venison
    250074, -- L25 Bear Brisket
    274976, -- L25 Plain Ol' Paletusk
    250065, -- L35 Savory Stag Sliders
    20452, -- L45 Smoked Desert Dumplings
    250070, -- L45 Bear Bruscitti
    250071, -- L45 Steaming Stag Steak
  }, "classicPhysFood", label("ITEM_MOD_STRENGTH_SHORT", "Strength"))
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)

  -- Well Fed: Attack Power
  addFoodGroup(allBuffs, { 1249519 }, {
    787, -- L1 Slitherskin Mackerel
    6290, -- L1 Brilliant Smallfish
    4592, -- L5 Longjaw Mud Snapper
    8364, -- L25 Mithril Head Trout
    13927, -- L35 Cooked Glossy Mightfish
    13932, -- L35 Poached Sunscale Salmon
    13934, -- L45 Mightfish Steak
  }, "classicPhysFood", label("ITEM_MOD_ATTACK_POWER_SHORT", "Attack Power"))
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)

  -- Well Fed: Critical Strike
  addFoodGroup(allBuffs, { 1249523 }, {
    287974, -- L1 Grilled Squid
    13928, -- L35 Grilled Squid
    13929, -- L35 Hot Smoked Bass
  }, "classicPhysFood", label("ITEM_MOD_CRIT_RATING_SHORT", "Critical Strike"))

  -- Well Fed: Agility
  addFoodGroup(allBuffs, { 1225779 }, {
    238638, -- L55 Filet o' Flank
  }, "classicPhysFood", label("ITEM_MOD_AGILITY_SHORT", "Agility"))
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)

  -- Well Fed: Intellect
  addFoodGroup(allBuffs, { 1248421 }, {
    2682, -- L1 Cooked Crab Claw
    5477, -- L1 Strider Stew
    12224, -- L1 Crispy Bat Wing
    250079, -- L1 Tasty Raptor Bites
    1082, -- L5 Redridge Goulash
    2683, -- L5 Crab Cake
    250077, -- L5 Twice-Spiced Raptor Slice
    263512, -- L5 Pincer Bites
    12210, -- L15 Roast Raptor
    4457, -- L25 Barbecued Buzzard Wing
    12216, -- L25 Spiced Chili Crab
    250073, -- L25 Raging Raptor Ribs
    18254, -- L35 Runn Tum Tuber Surprise
    250076, -- L35 Raptor Rouladen
    250066, -- L45 Soaring Pamplona
    250067, -- L45 Bat Hachee
    250075, -- L45 Prehistoric Pulled Raptor
  }, "classicSpellFood", label("ITEM_MOD_INTELLECT_SHORT", "Intellect"))
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)

  -- Well Fed: Spell Damage
  addFoodGroup(allBuffs, { 1249520 }, {
    5095, -- L5 Rainbow Fin Albacore
    21072, -- L10 Smoked Sagefish
    274971, -- L25 Briny Seafood Stew
    21217, -- L30 Sagefish Delight
    6887, -- L35 Spotted Yellowtail
    13931, -- L35 Nightfin Soup
    13933, -- L45 Lobster Stew
    13935, -- L45 Baked Salmon
  }, "classicSpellFood", label("ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "Spell Damage"))
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)

  -- Well Fed: Healing
  addFoodGroup(allBuffs, { 1249927 }, {
    249865, -- L1 Peace Tea
    249866, -- L5 Royal Tea
    249867, -- L15 Root Tea
    249868, -- L25 Triage Tea
    249869, -- L35 Sunny Tea
    249870, -- L45 Sage's Tea
  }, "classicSpellFood", label("ITEM_MOD_SPELL_HEALING_DONE_SHORT", "Healing"))
      :RequirePlayerClass(HEALER_CLASSES)

  -- Well Fed: Spirit
  addFoodGroup(allBuffs, { 1249926 }, {
    249871, -- L1 Venomous Smoothie
    249872, -- L5 Slimy Smoothie
    249873, -- L15 Mrrggl Smrrthle
    249874, -- L25 Calcified Smoothie
    249875, -- L35 Spicy Smoothie
    249876, -- L45 Wicked Smoothie
  }, "classicSpellFood", label("ITEM_MOD_SPIRIT_SHORT", "Spirit"))
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)

  -- Foods which kept their classic Stamina and Spirit auras
  addFoodGroup(allBuffs, { 19705, 19708, 19710 }, {
    11584, -- L0 Cactus Apple Surprise
    7806, -- L1 Lollipop
    7807, -- L1 Candy Bar
    7808, -- L1 Chocolate Square
    17197, -- L1 Gingerbread Cookie
    17198, -- L1 Egg Nog
    5527, -- L15 Goblin Deviled Clams
    16971, -- L40 Clamlette Surprise
  }, "classicFood", label("ITEM_MOD_STAMINA_SHORT", "Stamina") .. " " .. label("ITEM_MOD_SPIRIT_SHORT", "Spirit"))
end

---@param allBuffs BomBuffDefinition[]
function foreverModule:_SetupElixirs(allBuffs)
  local mana = allBuffsModule.MANA_CLASSES
  local melee = allBuffsModule.MELEE_CLASSES

  addElixirGroup(allBuffs, { 1245244, 1250971 }, { 247754, 250342 }, -- Minor, Lesser Arcane Elixir
    "classicSpellElixir", label("ITEM_MOD_SPELL_DAMAGE_DONE_SHORT", "Spell Damage"))
      :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
  addElixirGroup(allBuffs, { 1250922, 1250924, 1250925, 1250926 }, -- Minor, Lesser, (normal), Greater Cleric's Elixir
    { 250330, 250331, 250332, 250333 }, "classicSpellElixir", label("ITEM_MOD_SPELL_HEALING_DONE_SHORT", "Healing"))
      :RequirePlayerClass(HEALER_CLASSES)
  addElixirGroup(allBuffs, { 1250942, 1250944, 1250948 }, { 250339, 250340, 250341 }, -- Minor, Lesser, Greater Mageblood
    "classicSpellElixir", label("ITEM_MOD_MANA_REGENERATION_SHORT", "Mana Regeneration"))
      :RequirePlayerClass(mana)
  addElixirGroup(allBuffs, { 1250974, 1250976, 1250978, 1250979 }, -- Minor, Lesser, (normal), Greater Spirit
    { 250344, 250345, 250346, 250347 }, "classicSpellElixir", label("ITEM_MOD_SPIRIT_SHORT", "Spirit"))
      :RequirePlayerClass(mana)
  addElixirGroup(allBuffs, { 1250988, 1250989 }, { 250353, 250354 }, -- Elixir of Lesser Intellect, Elixir of Intellect
    "classicSpellElixir", label("ITEM_MOD_INTELLECT_SHORT", "Intellect"))
      :RequirePlayerClass(mana)
  addElixirGroup(allBuffs, { 1250928, 1250931 }, { 250334, 250335 }, -- Elixir of Fortitude, Greater Fortitude
    "classicElixir", label("ITEM_MOD_HEALTH_SHORT", "Health"))

  buffDefModule:foreverConsumable(allBuffs, 1245249, 247755) -- Elixir of Minor Force: melee damage
      :RequirePlayerClass(melee)
      :Category("classicPhysElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250918, 250328) -- Elixir of Cunning: Agility and Intellect
      :RequirePlayerClass({ "HUNTER", "SHAMAN", "DRUID", "PALADIN" })
      :Category("classicPhysElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250984, 250349) -- Elixir of Strength
      :RequirePlayerClass(melee)
      :Category("classicPhysElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250985, 250350) -- Elixir of Ferocity: Strength and Agility
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :Category("classicPhysElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250986, 250351) -- Elixir of the Grizzly: Strength and crit
      :RequirePlayerClass(melee)
      :Category("classicPhysElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250920, 250329) -- Elixir of the Phalanx: health and armor
      :Category("classicElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250932, 250336) -- Elixir of Wicked Regeneration: health and mana
      :Category("classicElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250940, 250337) -- Elixir of the Owl: Intellect and crit
      :RequirePlayerClass(mana)
      :Category("classicSpellElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250941, 250338) -- Elixir of Sages: Spirit and crit
      :RequirePlayerClass(mana)
      :Category("classicSpellElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250981, 250348) -- Elixir of the Whale: Spirit and crit
      :RequirePlayerClass(mana)
      :Category("classicSpellElixir")
  buffDefModule:foreverConsumable(allBuffs, 1250972, 250343) -- Elixir of Nature Power
      :RequirePlayerClass({ "DRUID", "SHAMAN" })
      :Category("classicSpellElixir")

  -- "Endless" elixirs: percent bonuses for 60 minutes
  buffDefModule:foreverConsumable(allBuffs, 1327736, 289082) -- Elixir of Endless Intellect
      :RequirePlayerClass(mana)
      :Category("classicSpellElixir")
  buffDefModule:foreverConsumable(allBuffs, 1328032, 289321) -- Elixir of Endless Mana
      :RequirePlayerClass(mana)
      :Category("classicSpellElixir")
  buffDefModule:foreverConsumable(allBuffs, 1327738, 289084) -- Elixir of Endless Healing
      :RequirePlayerClass(HEALER_CLASSES)
      :Category("classicSpellElixir")
  buffDefModule:foreverConsumable(allBuffs, 1327737, 289083) -- Elixir of Endless Power: damage
      :Category("classicElixir")
  buffDefModule:foreverConsumable(allBuffs, 1327751, 289086) -- Elixir of Endless Rapidity: haste
      :Category("classicElixir")
  buffDefModule:foreverConsumable(allBuffs, 1327753, 289087) -- Elixir of Endless Opportunity: crit
      :Category("classicElixir")
  buffDefModule:foreverConsumable(allBuffs, 1328127, 289334) -- Elixir of Endless Experience
      :Category("classicElixir")
end

---@param allBuffs BomBuffDefinition[]
function foreverModule:_SetupFlasks(allBuffs)
  -- Flasks of Natural Accuracy, Aggression, Precision, Swiftness: +30 Stamina for 2 hours (level 55)
  buffDefModule:consumableGroup(allBuffs, "", { 1293740, 1293741, 1293742, 1293743 },
        { 274273, 274274, 274275, 274276 })
      :Category("classicFlask")
      :ConsumeGroupTitle("elixir", label("ITEM_MOD_STAMINA_SHORT", "Stamina"), ICON_ELIXIR)
      :ExtraText(_t("tooltip.elixir.bestInBag"))
      :RequireForever()
end

---@param allBuffs BomBuffDefinition[]
function foreverModule:_SetupScrolls(allBuffs)
  -- Rat, Frog and Cat Familiar scrolls: an Intellect familiar for 60 minutes
  buffDefModule:consumableGroup(allBuffs, "", { 1296202, 1302285, 1302303 }, { 275069, 277483, 277493 })
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :ConsumeGroupTitle("scroll", label("ITEM_MOD_INTELLECT_SHORT", "Intellect"), ICON_SCROLL)
      :Category("scroll")
      :ExtraText(_t("tooltip.scroll.bestInBag"))
      :RequireForever()

  buffDefModule:foreverConsumable(allBuffs, 1327754, 289088) -- Scroll of Endless Fortitude: % Stamina
      :Category("scroll")
end

-- Scroll of Imbue X: a 1-hour weapon enchantment for one weapon type (SpellEquippedItems in 70862).
-- { use spell, items, weapon enchantment id, weapon type (itemIdsModule.WeaponSubclass key) }
local IMBUE_SCROLLS = {
  { 1295720, { 274947, 277503 }, 8700, "Staff" },   -- Lesser Flame (Imbue Spellbreak uses the same spell in 70862)
  { 1296225, { 275067 }, 8698, "Dagger" },          -- Chillknife
  { 1302283, { 277485 }, 8709, "Staff" },           -- Frost
  { 1302217, { 277486 }, 8708, "Staff" },           -- Striking
  { 1302219, { 277487 }, 8706, "Staff" },           -- Baleflame
  { 1302284, { 277488 }, 8710, "Dagger" },          -- Iceknife
  { 1302227, { 277489 }, 8707, "Sword1H" },         -- Spark
  { 1302306, { 277494 }, 8711, "Staff" },           -- Accuracy
  { 1302307, { 277495 }, 8712, "Staff" },           -- Quickening
  { 1302305, { 277496 }, 8714, "Staff" },           -- Balefrost
  { 1302304, { 277497 }, 8713, "Staff" },           -- Flame
  { 1302308, { 277498 }, 8715, "Dagger" },          -- Manablade
  { 1302311, { 277500 }, 8716, "Staff" },           -- Greater Flame
  { 1302312, { 277501 }, 8717, "Staff" },           -- Greater Frost
  { 1302310, { 277502 }, 8718, "Staff" },           -- Precision
}

-- English names for clients without GetItemSubClassInfo
local WEAPON_TYPE_FALLBACK = { Staff = "Staves", Dagger = "Daggers", Sword1H = "One-Handed Swords" }

---Imbue scrolls fit one weapon type each: the scan asks for them only on a fitting weapon, and the
---spells dialog names the type. They stay off by default.
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function foreverModule:_SetupImbueScrolls(allBuffs, enchantments)
  for _, imbue in ipairs(IMBUE_SCROLLS) do
    local spellId, itemIds, enchantId, weaponType = imbue[1], imbue[2], imbue[3], imbue[4]
    local subclass = itemIdsModule.WeaponSubclass[weaponType]
    local weaponName = envModule.GetItemSubClassName(itemIdsModule.ITEM_CLASS_WEAPON, subclass)
        or WEAPON_TYPE_FALLBACK[weaponType]
    enchantmentsModule:RegisterEnchantment(allBuffs, spellId)
        :CreatesOrProvidedByItem(itemIds)
        :SingleDuration(allBuffsModule.HOUR)
        :RequireWeaponType({ subclass })
        :ExtraText(weaponName)
        :RequirePlayerClass(allBuffsModule.SPELL_CLASSES)
        :RequireForever()
    enchantments[spellId] = { enchantId }
  end
end

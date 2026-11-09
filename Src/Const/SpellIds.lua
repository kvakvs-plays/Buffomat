--- Spell IDS given reasonable names

---@class SpellIdsModule

local module = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

module.ClassicFood = --[[@as WowSpellId[] ]] {
  6410, 433, 5004, 7737,                                                             -- Level 0-5 food
  25700, 25702, 25886, 25888,                                                        -- Level 10 food
  434, 2639, 5005,                                                                   -- Level 15 food, better food and buff food
  435, 24869,                                                                        -- Level 25 food and buff food
  1127, 5007, 18229, 18230, 18231, 18232, 18233, 26472, 26474,                       -- Level 35 food (including buff food)
  1129, 10256, 29008,                                                                -- Level 45 food, buff food, better food
  1131, 10257, 18234, 22731, 24005, 24704, 24800, 25695, 26260, 26401, 28616, 29073, -- Level 55 food
  25660,                                                                             -- 55 Dirge's kickin' chimaerok chops
}
---WoW: Forever "Nutritious Food" and "Nutritious Drink" auras while eating or drinking
module.ForeverFood = --[[@as WowSpellId[] ]] {
  1248377, 1248378, 1248379, 1248380, 1248381, 1248382, 1248383, 1248384,
  1248386, 1248387, 1248388, 1248389, 1248390, 1248391, 1248392, 1248393,
  1248394, 1248395, 1248396, 1248397, 1248398, 1248399, 1248400, 1248401,
  1248687, 1249500, 1249501, 1249502, 1249503, 1249504, 1249505, 1249506,
  1249507, 1249508, 1249509, 1249510, 1249511, 1249512, 1249513, 1249514,
  1249515, 1249516, 1249517, 1249522, 1249906, 1249914, 1249915, 1249916,
  1249917, 1249918, 1249919, 1249920, 1249921, 1249922, 1249923, 1249924,
  1249925, 1255415, 1294006, 1302066, 1319311,
}
module.TBCFood = --[[@as WowSpellId[] ]] {
  28616, 29073, 33253, 33260, 33266, 33269, 43777, 46898,                                    -- Level 65 eating
  33255, 33258, 33262, 33264, 33725, 35270, 35271, 40745, 40768, 41030, 43763, 45618, 46812, -- Level 75 eating
}
module.WotLKFood = --[[@as WowSpellId[] ]] {
  61829, -- Level 75 eating
  45548, -- Level 80 eating
}
-- Skip food buffing while eating some food buff
module.CataFood = --[[@as WowSpellId[] ]] {
  80168,                      -- Level 80 eating
  80169,                      -- Level 85 eating
  87644, 87604, 87915, 87643, -- Feast (eating)
  87544, 87584,               -- Str food (eating)
  87566, 87586,               -- Agi food (eating)
  87587, 87567,               -- Int food (eating)
  87568, 87588,               -- Spirit food (eating)
  87570, 87594,               -- Mastery food (eating)
  87571, 87595,               -- Hit food (eating)
  87572, 87597,               -- Crit food (eating)
  87636, 87637,               -- Exp food (eating)
  87573, 87599,               -- Haste food (eating)
  87577, 87601,               -- Dodge food (eating)
  87602,                      -- Parry food (eating)
}

module.Mage_ConjureManaSapphire = 42985
module.Mage_ConjureManaEmerald = 27101
module.Mage_ConjureManaRuby = 10054
module.Mage_ConjureManaCitrine = 10053
module.Mage_ConjureManaJade = 3552
module.Mage_ConjureManaAgate = 759
module.Mage_Cataclysm_ManaGem = 759

module.Warlock_DemonicSacrifice = 18788
module.Warlock_CreateSpellstone6 = 47888 -- WotLK
module.Warlock_CreateSpellstone5 = 47886 -- WotLK
module.Warlock_CreateSpellstone4 = 28172
module.Warlock_CreateSpellstone3 = 17728
module.Warlock_CreateSpellstone2 = 17727
module.Warlock_CreateSpellstone1 = 2362
module.Warlock_CreateFirestone1 = 6366
module.Warlock_CreateFirestone2 = 17951
module.Warlock_CreateFirestone3 = 17952
module.Warlock_CreateFirestone4 = 17953
module.Warlock_CreateFirestone5 = 27250
module.Warlock_CreateFirestone6 = 60219
module.Warlock_CreateFirestone7 = 60220

module.Priest_SpiritTap = 15271

module.Druid_TrackHumanoids = 5225
---Auras cancelled by the AutoDisTravel option: Ghost Wolf, Travel Form
module.TravelShapeshiftForms = --[[@as WowSpellId[] ]] { 2645, 783 }

module.Paladin_CrusaderAura = 32223

module.FindHerbs = 2383
module.FindMinerals = 2580
module.FindTreasure = 2481
module.FindFish = 43308

module.Shaman_Flametongue6 = 16342

-- WoW: Forever account-wide Legacy talents
module.Forever_ReagentEconomy = 1225503 -- class abilities need no vendor reagents
module.Forever_Permanence = 1225502     -- party/raid stat buffs last longer
module.Forever_Gourmand = 1225499       -- food buffs last longer
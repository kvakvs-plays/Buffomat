--- Spell IDS given reasonable names

---@class SpellIdsModule

local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

spellIdsModule.ClassicFood = --[[@as WowSpellId[] ]] {
  6410, 433, 5004, 7737,                                                             -- Level 0-5 food
  25700, 25702, 25886, 25888,                                                        -- Level 10 food
  434, 2639, 5005,                                                                   -- Level 15 food, better food and buff food
  435, 24869,                                                                        -- Level 25 food and buff food
  1127, 5007, 18229, 18230, 18231, 18232, 18233, 26472, 26474,                       -- Level 35 food (including buff food)
  1129, 10256, 29008,                                                                -- Level 45 food, buff food, better food
  1131, 10257, 18234, 22731, 24005, 24704, 24800, 25695, 26260, 26401, 28616, 29073, -- Level 55 food
  25660,                                                                             -- 55 Dirge's kickin' chimaerok chops
}
spellIdsModule.TBCFood = --[[@as WowSpellId[] ]] {
  28616, 29073, 33253, 33260, 33266, 33269, 43777, 46898,                                    -- Level 65 eating
  33255, 33258, 33262, 33264, 33725, 35270, 35271, 40745, 40768, 41030, 43763, 45618, 46812, -- Level 75 eating
}
spellIdsModule.WotLKFood = --[[@as WowSpellId[] ]] {
  61829, -- Level 75 eating
  45548, -- Level 80 eating
}
-- Skip food buffing while eating some food buff
spellIdsModule.CataFood = --[[@as WowSpellId[] ]] {
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

spellIdsModule.Mage_ConjureManaSapphire = 42985
spellIdsModule.Mage_ConjureManaEmerald = 27101
spellIdsModule.Mage_ConjureManaRuby = 10054
spellIdsModule.Mage_ConjureManaCitrine = 10053
spellIdsModule.Mage_ConjureManaJade = 3552
spellIdsModule.Mage_ConjureManaAgate = 759
spellIdsModule.Mage_Cataclysm_ManaGem = 759

spellIdsModule.Warlock_DemonicSacrifice = 18788
spellIdsModule.Warlock_CreateSpellstone6 = 47888 -- WotLK
spellIdsModule.Warlock_CreateSpellstone5 = 47886 -- WotLK
spellIdsModule.Warlock_CreateSpellstone4 = 28172
spellIdsModule.Warlock_CreateSpellstone3 = 17728
spellIdsModule.Warlock_CreateSpellstone2 = 17727
spellIdsModule.Warlock_CreateSpellstone1 = 2362
spellIdsModule.Warlock_CreateFirestone1 = 6366
spellIdsModule.Warlock_CreateFirestone2 = 17951
spellIdsModule.Warlock_CreateFirestone3 = 17952
spellIdsModule.Warlock_CreateFirestone4 = 17953
spellIdsModule.Warlock_CreateFirestone5 = 27250
spellIdsModule.Warlock_CreateFirestone6 = 60219
spellIdsModule.Warlock_CreateFirestone7 = 60220

spellIdsModule.Priest_SpiritTap = 15271

spellIdsModule.Druid_TrackHumanoids = 5225
---Auras cancelled by the AutoDisTravel option: Ghost Wolf, Travel Form
spellIdsModule.TravelShapeshiftForms = --[[@as WowSpellId[] ]] { 2645, 783 }

spellIdsModule.Paladin_CrusaderAura = 32223

spellIdsModule.FindHerbs = 2383
spellIdsModule.FindMinerals = 2580
spellIdsModule.FindTreasure = 2481
spellIdsModule.FindFish = 43308

spellIdsModule.Shaman_Flametongue6 = 16342
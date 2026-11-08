--- Item IDS given reasonable names

---@class ItemIdsModule

local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]

itemIdsModule.Deathknight_CorpseDust = 37201

itemIdsModule.Mage_ManaSapphire = 33312
itemIdsModule.Mage_ManaEmerald = 22044
itemIdsModule.Mage_ManaRuby = 8008
itemIdsModule.Mage_ManaCitrine = 8007
itemIdsModule.Mage_ManaJade = 5513
itemIdsModule.Mage_ManaAgate = 5514
itemIdsModule.Mage_Cataclysm_ManaGem = 36799

itemIdsModule.Warlock_SoulShard = 6265
itemIdsModule.Warlock_Spellstone1 = 41191
itemIdsModule.Warlock_Spellstone2 = 41192
itemIdsModule.Warlock_Spellstone3 = 41193
itemIdsModule.Warlock_Spellstone4 = 41194
itemIdsModule.Warlock_Spellstone5 = 41195
itemIdsModule.Warlock_Spellstone6 = 41196
itemIdsModule.Warlock_Firestone1 = 41170
itemIdsModule.Warlock_Firestone2 = 41169
itemIdsModule.Warlock_Firestone3 = 41171
itemIdsModule.Warlock_Firestone4 = 41172
itemIdsModule.Warlock_Firestone5 = 40773
itemIdsModule.Warlock_Firestone6 = 41173
itemIdsModule.Warlock_Firestone7 = 41174

itemIdsModule.Paladin_SymbolOfKings = 21177

itemIdsModule.ITEM_CLASS_WEAPON = 2
---Weapon item subclasses (Enum.ItemWeaponSubclass), for weapon enchantments limited to some weapons
---@enum WowWeaponSubclassName
itemIdsModule.WeaponSubclass = {
  Axe1H = 0, Axe2H = 1, Bow = 2, Gun = 3, Mace1H = 4, Mace2H = 5, Polearm = 6, Sword1H = 7, Sword2H = 8,
  Staff = 10, FistWeapon = 13, Misc = 14, Dagger = 15, Thrown = 16, Crossbow = 18, Wand = 19, FishingPole = 20,
}

---Class reagents sold by vendors. On WoW: Forever the Legacy talent Reagent Economy removes the
---need for these, but not for Soul Shards or other farmed reagents.
---@type {[WowItemId]: boolean}
itemIdsModule.VendorReagents = {
  [17020] = true, -- Arcane Powder
  [17021] = true, -- Wild Berries
  [17026] = true, -- Wild Thornroot
  [17028] = true, -- Holy Candle
  [17029] = true, -- Sacred Candle
  [21177] = true, -- Symbol of Kings
}

itemIdsModule.Classic_BigmouthClam = 7973
itemIdsModule.TBC_JaggalClam = 24476
itemIdsModule.WotLK_DarkwaterClam = 36781
itemIdsModule.Cataclysm_AbyssalClam = 52340
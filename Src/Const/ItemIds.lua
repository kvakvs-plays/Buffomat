--- Item IDS given reasonable names

---@class ItemIdsModule

local module = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]

module.Deathknight_CorpseDust = 37201

module.Mage_ManaSapphire = 33312
module.Mage_ManaEmerald = 22044
module.Mage_ManaRuby = 8008
module.Mage_ManaCitrine = 8007
module.Mage_ManaJade = 5513
module.Mage_ManaAgate = 5514
module.Mage_Cataclysm_ManaGem = 36799

module.Warlock_SoulShard = 6265
module.Warlock_Spellstone1 = 41191
module.Warlock_Spellstone2 = 41192
module.Warlock_Spellstone3 = 41193
module.Warlock_Spellstone4 = 41194
module.Warlock_Spellstone5 = 41195
module.Warlock_Spellstone6 = 41196
module.Warlock_Firestone1 = 41170
module.Warlock_Firestone2 = 41169
module.Warlock_Firestone3 = 41171
module.Warlock_Firestone4 = 41172
module.Warlock_Firestone5 = 40773
module.Warlock_Firestone6 = 41173
module.Warlock_Firestone7 = 41174

module.Paladin_SymbolOfKings = 21177

module.ITEM_CLASS_WEAPON = 2
---Weapon item subclasses (Enum.ItemWeaponSubclass), for weapon enchantments limited to some weapons
---@enum WowWeaponSubclassName
module.WeaponSubclass = {
  Axe1H = 0, Axe2H = 1, Bow = 2, Gun = 3, Mace1H = 4, Mace2H = 5, Polearm = 6, Sword1H = 7, Sword2H = 8,
  Staff = 10, FistWeapon = 13, Misc = 14, Dagger = 15, Thrown = 16, Crossbow = 18, Wand = 19, FishingPole = 20,
}

local ws = module.WeaponSubclass
-- Weapon types that weapon stones fit, from SpellEquippedItems (the same on Era, TBC and Forever).
---Sharpening stones fit bladed weapons only.
---@type WowWeaponSubclass[]
module.BladedWeapons = { ws.Axe1H, ws.Axe2H, ws.Polearm, ws.Sword1H, ws.Sword2H, ws.Dagger }
---Weightstones fit blunt weapons only.
---@type WowWeaponSubclass[]
module.BluntWeapons = { ws.Mace1H, ws.Mace2H, ws.Staff, ws.FistWeapon }
---Elemental and Consecrated stones fit any melee weapon. The game also allows a Consecrated stone on a
---fishing pole, but suggesting that is pointless.
---@type WowWeaponSubclass[]
module.MeleeWeapons = { ws.Axe1H, ws.Axe2H, ws.Polearm, ws.Sword1H, ws.Sword2H, ws.Dagger,
                               ws.Mace1H, ws.Mace2H, ws.Staff, ws.FistWeapon }

---Class reagents sold by vendors. On WoW: Forever the Legacy talent Reagent Economy removes the
---need for these, but not for Soul Shards or other farmed reagents.
---@type {[WowItemId]: boolean}
module.VendorReagents = {
  [17020] = true, -- Arcane Powder
  [17021] = true, -- Wild Berries
  [17026] = true, -- Wild Thornroot
  [17028] = true, -- Holy Candle
  [17029] = true, -- Sacred Candle
  [21177] = true, -- Symbol of Kings
}

module.Classic_BigmouthClam = 7973
module.TBC_JaggalClam = 24476
module.WotLK_DarkwaterClam = 36781
module.Cataclysm_AbyssalClam = 52340
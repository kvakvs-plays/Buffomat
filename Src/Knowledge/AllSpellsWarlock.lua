local BuffomatAddon = BuffomatAddon

---@class WarlockModule

local warlockModule = LibStub("Buffomat-AllSpellsWarlock") --[[@as WarlockModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---Add WARLOCK spells
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function warlockModule:SetupWarlockSpells(allBuffs, enchantments)
  -- Unending Breath
  buffDefModule:createAndRegisterBuff(allBuffs, 5697, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :RequirePlayerClass("WARLOCK")
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")

  -- Detect Greater Invisibility | Große Unsichtbarkeit entdecken
  buffDefModule:createAndRegisterBuff(allBuffs, 132, nil)
      :IsDefault(false)
      :SingleFamily({ 132, -- Detect Invisibility
        2970, 11743 })     -- Some other stuff
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :RequirePlayerClass("WARLOCK")
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")

  -- Shadow Ward / Schattenzauberschutz
  buffDefModule:createAndRegisterBuff(allBuffs, 28610, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleFamily({ 6229, 11739, 11740, 28610, -- Shadow Ward 1-4
        47890, 47891 })                          -- WotLK: Shadow Ward 5-6
      :RequirePlayerClass("WARLOCK")
      :Category("class")

  -- TBC: Fel Armor
  buffDefModule:createAndRegisterBuff(allBuffs, 28176, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleFamily({ 28176, 28189, -- TBC: Fel Armor 1-2
        47892, 47893 })             -- WotLK: Fel Armor 3-4
      :RequirePlayerClass("WARLOCK")
      :RequireTBC()
      :Category("class")

  -- Demon Skin / Demon Armor
  buffDefModule:createAndRegisterBuff(allBuffs, 11735, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleFamily({ 687, 696,         -- Demon Skin 1-2
        706, 1086, 11733, 11734, 11735, -- Demon Armor 5
        27260,                          -- TBC: Demon Armor 6
        47793, 47889 })                 -- WotLK: Demon Armor 7-8
      :RequirePlayerClass("WARLOCK")
      :Category("class")

  if envModule.haveWotLK then
    -- Create Firesone
    buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Warlock_CreateFirestone7, nil)
        :IsOwn(true)
        :IsDefault(true)
        :LockIfHaveItem({ itemIdsModule.Warlock_Firestone1,
          itemIdsModule.Warlock_Firestone2,
          itemIdsModule.Warlock_Firestone3,
          itemIdsModule.Warlock_Firestone4,
          itemIdsModule.Warlock_Firestone5,
          itemIdsModule.Warlock_Firestone6,
          itemIdsModule.Warlock_Firestone7 })
        :SingleFamily({ spellIdsModule.Warlock_CreateFirestone1,
          spellIdsModule.Warlock_CreateFirestone2,
          spellIdsModule.Warlock_CreateFirestone3,
          spellIdsModule.Warlock_CreateFirestone4,
          spellIdsModule.Warlock_CreateFirestone5,
          spellIdsModule.Warlock_CreateFirestone6,
          spellIdsModule.Warlock_CreateFirestone7 })
        :ExtraText(_t("tooltip.buff.conjure"))
        :RequirePlayerClass("WARLOCK")
        :Category("classWeaponEnchantment")
    -- Firestone
    buffDefModule:createAndRegisterBuff(allBuffs, 60220, nil)
        :CreatesOrProvidedByItem({ itemIdsModule.Warlock_Firestone1,
          itemIdsModule.Warlock_Firestone2,
          itemIdsModule.Warlock_Firestone3,
          itemIdsModule.Warlock_Firestone4,
          itemIdsModule.Warlock_Firestone5,
          itemIdsModule.Warlock_Firestone6,
          itemIdsModule.Warlock_Firestone7 })
        :IsConsumable(true)
        :BuffType("weapon")
        :IsDefault(false)
        :SingleDuration(allBuffsModule.HOUR)
        :RequirePlayerClass("WARLOCK")
        :Category("classWeaponEnchantment")
    enchantments[60220] = { 3609, 3610, 3611, 3612, 3597, 3613, 3614 } -- WotLK: Firestone 1-7
  else
    -- in WotLK firestone becomes a 5-charges conjured weapon enchantment item
    -- Firestone
    buffDefModule:createAndRegisterBuff(allBuffs, 17953, nil)
        :IsOwn(true)
        :IsDefault(false)
        :LockIfHaveItem(buffDefModule:PerExpansionChoice({
          classic = { 1254, 13699, 13700, 13701 },
          tbc = { 22128 }                          -- TBC: Master Firestone
        }))
        :SingleFamily({ 6366, 17951, 17952, 17953, -- Rank 1-4
          27250 })                                 -- TBC: Rank 5
        :RequirePlayerClass("WARLOCK")
        :Category("class")
  end

  if envModule.haveWotLK then
    -- Conjure Mana Stone (Max Rank)
    buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Warlock_CreateSpellstone6, nil)
        :IsOwn(true)
        :IsDefault(true)
        :LockIfHaveItem({ itemIdsModule.Warlock_Spellstone1,
          itemIdsModule.Warlock_Spellstone2,
          itemIdsModule.Warlock_Spellstone3,
          itemIdsModule.Warlock_Spellstone4,
          itemIdsModule.Warlock_Spellstone5,
          itemIdsModule.Warlock_Spellstone6 })
        :SingleFamily({ spellIdsModule.Warlock_CreateSpellstone1,
          spellIdsModule.Warlock_CreateSpellstone2,
          spellIdsModule.Warlock_CreateSpellstone3,
          spellIdsModule.Warlock_CreateSpellstone4,
          spellIdsModule.Warlock_CreateSpellstone5,
          spellIdsModule.Warlock_CreateSpellstone6 })
        :ExtraText(_t("tooltip.buff.conjure"))
        :RequirePlayerClass("WARLOCK")
        :Category("classWeaponEnchantment")

    -- Spellstone
    buffDefModule:createAndRegisterBuff(allBuffs, 55194, nil)
        :CreatesOrProvidedByItem({ itemIdsModule.Warlock_Spellstone1,
          itemIdsModule.Warlock_Spellstone2,
          itemIdsModule.Warlock_Spellstone3,
          itemIdsModule.Warlock_Spellstone4,
          itemIdsModule.Warlock_Spellstone5,
          itemIdsModule.Warlock_Spellstone6 })
        :IsConsumable(true)
        :BuffType("weapon")
        :IsDefault(false)
        :SingleDuration(allBuffsModule.HOUR)
        :RequirePlayerClass("WARLOCK")
        :Category("classWeaponEnchantment")
    enchantments[55194] = {
      3615, 3616, 3617, 3618, 3619, 3620
    } -- WotLK: Spellstone 1-6 enchantIds
  else
    -- in WotLK spellstone becomes a 5-charges conjured weapon enchantment item
    -- Spellstone (WotLK)
    buffDefModule:createAndRegisterBuff(allBuffs, 17728, nil)
        :IsOwn(true)
        :IsDefault(false)
        :LockIfHaveItem({ 5522, 13602, 13603, -- "normal", Greater, Major Spellstone
          22646 })                            -- TBC: Master Spellstone
        :SingleFamily({ 2362, 17727, 17728,   -- Rank 1-3
          28172 })                            -- TBC: Rank 4
        :RequirePlayerClass("WARLOCK")
        :Category("class")
  end

  -- Healthstone
  buffDefModule:createAndRegisterBuff(allBuffs, 11730, nil)
      :IsOwn(true)
      :IsDefault(true)
      :LockIfHaveItem({ 5512, 19005, 19004,
        5511, 19007, 19006,
        5509, 19009, 19008,
        5510, 19011, 19010,
        9421, 19013, 19012,                           -- Healthstones (3 talent ranks)
        22103, 22104, 22105,                          -- TBC: Master Healthstone (3 talent ranks)
        36889, 36890, 36891,                          -- WotLK: Demonic Healthstone (3 talent ranks)
        36892, 36893, 36894 })                        -- WotLK: Fel Healthstone (3 talent ranks)
      :SingleFamily({ 6201, 6202, 5699, 11729, 11730, -- Healthstone 1-5
        27230,                                        -- TBC: Healthstone 6
        47871, 47878 })                               -- WotLK: Demonic and Fel Healthstone (rank 7-8)
      :RequirePlayerClass("WARLOCK")
      :ExtraText(_t("tooltip.buff.conjure"))
      :Category("class")

  --Soulstone
  buffDefModule:createAndRegisterBuff(allBuffs, 20757, nil)
      :IsOwn(true)
      :IsDefault(true)
      :LockIfHaveItem({ 5232, 16892, 16893, 16895, 16896,
        22116,                                         -- TBC: Master Soulstone
        36895 })                                       -- WotLK: Demonic Soulstone
      :SingleFamily({ 693, 20752, 20755, 20756, 20757, -- Ranks 1-5
        27238,                                         -- TBC: Rank 6
        47884 })                                       -- WotLK: Rank 7
      :RequirePlayerClass("WARLOCK")
      :Category("class")

  --Sense Demons
  buffDefModule:createAndRegisterBuff(allBuffs, 5500, nil)
      :BuffType("tracking")
      :IsDefault(false)
      :RequirePlayerClass("WARLOCK")
      :Category("tracking")

  --Sense Demons
  buffDefModule:createAndRegisterBuff(allBuffs, 5500, nil)
      :BuffType("tracking")
      :IsDefault(false)
      :RequirePlayerClass("WARLOCK")
      :Category("tracking")

  ------------------------
  -- Pet Management
  ------------------------

  -- Demonic Sacrifice
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Warlock_DemonicSacrifice, nil)
      :IsOwn(true)
      :IsDefault(true)
      :RequireWarlockPet(true)
      :RequirePlayerClass("WARLOCK")
      :HideInWotLK()
      :Category("pet")

  -- TBC: Soul Link, talent spell 19028, gives buff 25228
  buffDefModule:createAndRegisterBuff(allBuffs, 19028, nil)
      :IsOwn(true)
      :IsDefault(true)
      :SingleFamily({ 19028, 25228 })
      :RequireWarlockPet(true)
      :RequirePlayerClass("WARLOCK")
      :Category("pet")

  --Summon Imp
  buffDefModule:createAndRegisterBuff(allBuffs, 688, nil)
      :BuffType("summon")
      :IsDefault(true)
      :IsOwn(true)
      :SummonCreatureFamily(23) -- "Imp"
      :SummonCreatureType(3) -- "Demon"
      :SacrificeAuraIds({ 18789 })
      :RequirePlayerClass("WARLOCK")
      :Category("pet")

  --Summon Voidwalker
  buffDefModule:createAndRegisterBuff(allBuffs, 697, nil)
      :BuffType("summon")
      :IsDefault(false)
      :IsOwn(true)
      :ReagentRequired({ itemIdsModule.Warlock_SoulShard })
      :SummonCreatureFamily(16) -- "Voidwalker"
      :SummonCreatureType(3) -- "Demon"
      :SacrificeAuraIds({ 18790, 1905 }) -- TBC: Restore 2% hp, and Classic: Shield the warlock
      :RequirePlayerClass("WARLOCK")
      :Category("pet")

  --Summon Succubus
  buffDefModule:createAndRegisterBuff(allBuffs, 712, nil)
      :BuffType("summon")
      :IsDefault(false)
      :IsOwn(true)
      :ReagentRequired({ itemIdsModule.Warlock_SoulShard })
      :SummonCreatureFamily(17) -- "Succubus"
      :SummonCreatureType(3) -- "Demon"
      :SacrificeAuraIds({ 18791 })
      :RequirePlayerClass("WARLOCK")
      :Category("pet")

  --Summon Incubus (TBC)
  buffDefModule:createAndRegisterBuff(allBuffs, 713, nil)
      :BuffType("summon")
      :IsDefault(false)
      :IsOwn(true)
      :ReagentRequired({ itemIdsModule.Warlock_SoulShard })
      :SummonCreatureFamily(302) -- "Incubus"
      :SummonCreatureType(3) -- "Demon"
      :SacrificeAuraIds({ 18791 })
      :RequirePlayerClass("WARLOCK")
      :Category("pet")

  --Summon Felhunter
  buffDefModule:createAndRegisterBuff(allBuffs, 691, nil)
      :BuffType("summon")
      :IsDefault(false)
      :IsOwn(true)
      :ReagentRequired({ itemIdsModule.Warlock_SoulShard })
      :SummonCreatureFamily(15) -- "Felhunter"
      :SummonCreatureType(3) -- "Demon"
      :SacrificeAuraIds({ 18792 })
      :RequirePlayerClass("WARLOCK")
      :Category("pet")

  --Summon Felguard
  buffDefModule:createAndRegisterBuff(allBuffs, 30146, nil)
      :BuffType("summon")
      :IsDefault(false)
      :IsOwn(true)
      :ReagentRequired({ itemIdsModule.Warlock_SoulShard })
      :SummonCreatureFamily(29) -- "Felguard"
      :SummonCreatureType(3) -- "Demon"
      :SacrificeAuraIds({ 35701 })
      :RequirePlayerClass("WARLOCK")
      :Category("pet")
end

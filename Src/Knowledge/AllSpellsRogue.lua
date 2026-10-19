---@class RogueModule

local rogueModule = LibStub("Buffomat-AllSpellsRogue") --[[@as RogueModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

---Add ROGUE spells
---@param allBuffs BomBuffDefinition[]
---@param enchants BomEnchantmentsMapping
function rogueModule:SetupRogueSpells(allBuffs, enchants)
  local duration = allBuffsModule.TbcOrClassic(allBuffsModule.HOUR, allBuffsModule.HALF_AN_HOUR) -- TBC: Poisons become 1 hour

  --Deadly Poison
  -- Cataclysm: Only 2892 is available
  buffDefModule:createAndRegisterBuff(allBuffs, 25351, nil)
      :CreatesOrProvidedByItem(buffDefModule:PerExpansionChoice({
        classic = { 20844, 8985, 8984, 2893, 2892 },
        tbc = { 22054, 22053 },   -- TBC: Deadly Poison
        wotlk = { 43232, 43233 },
        onlyCataclysm = { 2892 }, -- All poison ranks are merged into one in Cataclysm
      }))                         -- WotLK: Deadly Poison 8-9
      :IsConsumable(true)
      :BuffType("weapon")
      :SingleDuration(duration)
      :IsDefault(false)
      :MinLevel(2)
      :RequirePlayerClass("ROGUE")
      :Category("classWeaponEnchantment")
  enchants[25351] = { 2643, 2642, -- TBC: Deadly Poison
    2630, 627, 626, 8, 7,         --Deadly Poison
    3770, 3771 }                  -- WotLK: Deadly Poison 8, 9

  --Mind-numbing Poison
  -- Cataclysm: Only 5237 is available
  buffDefModule:createAndRegisterBuff(allBuffs, 11399, nil)
      :CreatesOrProvidedByItem(buffDefModule:PerExpansionChoice({
        classic = { 9186, 6951, 5237 },
        onlyCataclysm = { 5237 } -- All poison ranks are merged into one in Cataclysm
      }))
      :IsConsumable(true)
      :BuffType("weapon")
      :SingleDuration(duration)
      :IsDefault(false)
      :MinLevel(24)
      :RequirePlayerClass("ROGUE")
      :Category("classWeaponEnchantment")
  --:HideInWotLK()
  enchants[11399] = { 643, 23, 35 } -- Mind-numbing Poison (also WotLK: enchantment 35)

  --Instant Poison
  -- Cataclysm: Only 6947 is available
  buffDefModule:createAndRegisterBuff(allBuffs, 11340, nil)
      :CreatesOrProvidedByItem(buffDefModule:PerExpansionChoice({
        classic = { 8928, 8927, 8926, 6950, 6949, 6947 }, -- Instant Poison 2-7
        tbc = { 21927 },                                  -- TBC: Instant Poison
        wotlk = { 43230, 43231 },
        onlyCataclysm = { 6947 }                          -- All poison ranks are merged into one in Cataclysm
      }))                                                 -- WotLK: Instant Poison 8-9
      :IsConsumable(true)
      :BuffType("weapon")
      :SingleDuration(duration)
      :IsDefault(false)
      :MinLevel(20)
      :RequirePlayerClass("ROGUE")
      :Category("classWeaponEnchantment")
  enchants[11340] = { 2641,       -- TBC: Instant Poison
    625, 624, 623, 325, 324, 323, --Instant Poison
    3768, 3769 }                  -- WotLK: Instant Poison 8, 9

  --Wound Poison
  -- Cataclysm: Only 10918 is available
  buffDefModule:createAndRegisterBuff(allBuffs, 13227, nil)
      :CreatesOrProvidedByItem(buffDefModule:PerExpansionChoice({
        classic = { 10922, 10921, 10920, 10918 },
        tbc = { 22055 },          -- TBC: Wound Poison
        wotlk = { 43234, 43235 },
        onlyCataclysm = { 10918 } -- All poison ranks are merged into one in Cataclysm
      }))                         -- WotLK: Wound Poison 6, 7
      :IsConsumable(true)
      :BuffType("weapon")
      :SingleDuration(duration)
      :IsDefault(false)
      :MinLevel(32)
      :RequirePlayerClass("ROGUE")
      :Category("classWeaponEnchantment")
  enchants[13227] = { 2644, -- TBC: Wound Poison
    706, 705, 704, 703,     --Wound Poison
    3772, 3773 }            -- WotLK: Wound Poison 6, 7

  --Crippling Poison
  -- Cataclysm: Only 3775 is available
  buffDefModule:createAndRegisterBuff(allBuffs, 11202, nil)
      :CreatesOrProvidedByItem(buffDefModule:PerExpansionChoice({
        classic = { 3776, 3775 },
        onlyCataclysm = { 3775 } -- All poison ranks are merged into one in Cataclysm
      }))
      :IsConsumable(true)
      :BuffType("weapon")
      :SingleDuration(duration)
      :IsDefault(false)
      :MinLevel(20)
      :RequirePlayerClass("ROGUE")
      :Category("classWeaponEnchantment")
  enchants[11202] = { 603, 22 } --Crippling Poison

  --TBC: Anesthetic Poison
  buffDefModule:createAndRegisterBuff(allBuffs, 26785, nil)
      :CreatesOrProvidedByItem({ 21835, 43237 })
      :IsConsumable(true)
      :BuffType("weapon")
      :SingleDuration(duration)
      :IsDefault(false)
      :MinLevel(68)
      :RequirePlayerClass("ROGUE")
      :RequireTBC()
      :Category("classWeaponEnchantment")
  enchants[26785] = { 2640, --TBC: Anesthetic Poison
    3774 }                  -- WotLK: Anesthetic 2
end
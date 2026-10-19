---@class MageModule

local mageModule = LibStub("Buffomat-AllSpellsMage") --[[@as MageModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

function mageModule:CreateIntelligenceBuff()
  return buffDefModule:New(10157)                     --Arcane Intellect | Brilliance
      :SingleFamily({ 1459, 1460, 1461, 10156, 10157, -- Ranks 1-5
        27126,                                        -- TBC: Rank 6
        42995, 61024,                                 -- WotLK: Arcane Intellect 7; Dalaran Intellect
        79058 })                                      -- Cataclysm: Arcane Brilliance
      :GroupFamily({ 23028,                           -- Brilliance Rank 1
        27127,                                        -- TBC: Brillance Rank 2
        43002, 61316,                                 -- WotLK: Arcane Brilliance Rank 3; Dalaran Brilliance
        79058 })                                      -- Cataclysm: Arcane Brilliance
      :IsDefault(true)
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :GroupDuration(allBuffsModule.HOUR)
      :ReagentRequired({ 17020 }) -- Arcane Powder
      :DefaultTargetClasses(allBuffsModule.MANA_CLASSES)
      :RequirePlayerClass("MAGE")
      :Category("class")
end

---Add MAGE spells
---@param allBuffs BomBuffDefinition[]
---@param enchantments BomEnchantmentsMapping
function mageModule:SetupMageSpells(allBuffs, enchantments)
  table.insert(allBuffs, self:CreateIntelligenceBuff())

  --Dampen Magic
  buffDefModule:createAndRegisterBuff(allBuffs, 10174, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :SingleFamily({ 604, 8450, 8451, 10173, 10174, -- Ranks 1-5
        33944,                                       -- TBC: Rank 6
        43015 })                                     -- WotLK: Dampen Magic 7
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :RequirePlayerClass("MAGE")
      :Category("class")
      :HideInCata()
  --Amplify Magic
  buffDefModule:createAndRegisterBuff(allBuffs, 10170, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :SingleFamily({ 1008, 8455, 10169, 10170, -- Ranks 1-4
        27130, 33946,                           -- TBC: Ranks 5-6
        43017 })                                -- WotLK: Amplify Magic 7
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :RequirePlayerClass("MAGE")
      :Category("class")
      :HideInCata()
  -- Ice Armor / eisrüstung
  buffDefModule:createAndRegisterBuff(allBuffs, 10220, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :SingleFamily({ 168, 7300, 7301, -- Frost Armor 1-3
        7302, 7320, 10219, 10220,      -- Ice Armor 1-4
        27124,                         -- TBC: Ice Armor 5
        43008 })                       -- WotLK: Ice Armor 6
      :RequirePlayerClass("MAGE")
      :Category("class")
  -- Ice Barrier
  buffDefModule:createAndRegisterBuff(allBuffs, 11426, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.MINUTE)
      :SingleFamily({ 11426, 13031, 13032, 13033, -- Ice Barrier 1-4
        27134, 33405,                             -- TBC: Ice Barrier 5, 6
        43038, 43039 })                           -- WotLK: Ice Barrier 7
      :RequirePlayerClass("MAGE")
      :Category("class")
  -- TBC: Molten Armor
  buffDefModule:createAndRegisterBuff(allBuffs, 30482, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :SingleFamily({ 30482, -- TBC: Molten Armor 1
        43045, 43046 })      -- WotLK: Molten Armor 2, 3
      :RequirePlayerClass("MAGE")
      :Category("class")
      :RequireTBC()
  -- Mage Armor / magische rüstung
  buffDefModule:createAndRegisterBuff(allBuffs, 22783, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :SingleFamily({ 6117, 22782, 22783, -- Mage Armor 1-3
        27125,                            -- TBC: Mage Armor 4
        43023, 43024 })                   -- WotLK: Mage Armor 5, 6
      :RequirePlayerClass("MAGE")
      :Category("class")
  --Mana Shield | Manaschild - unabhängig von allen.
  buffDefModule:createAndRegisterBuff(allBuffs, 10193, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.MINUTE)
      :SingleFamily({ 1463, 8494, 8495, 10191, 10192, 10193, -- Mana Shield 1-6
        27131,                                               -- TBC: Mana Shield 7
        43019, 43020 })                                      -- WotLK: Mana Shield 8, 9
      :RequirePlayerClass("MAGE")
      :Category("class")

  local playerLevel = UnitLevel("player")

  if playerLevel >= 58 and playerLevel < 77 then
    -- Conjure separate mana gems of 3 kinds
    -- For WotLK only 1 mana gem can be owned
    tinsert(allBuffs,
      buffDefModule:conjureItem(spellIdsModule.Mage_ConjureManaEmerald, itemIdsModule.Mage_ManaEmerald)
      :RequirePlayerClass("MAGE")
      :Category("class")
    )
    tinsert(allBuffs,
      buffDefModule:conjureItem(spellIdsModule.Mage_ConjureManaRuby, itemIdsModule.Mage_ManaRuby)
      :RequirePlayerClass("MAGE")
      :Category("class")
    )
    if playerLevel <= 68 then
      -- Players > 68 will not be interested in Citrine
      tinsert(allBuffs,
        buffDefModule:conjureItem(spellIdsModule.Mage_ConjureManaCitrine, itemIdsModule.Mage_ManaCitrine)
        :RequirePlayerClass("MAGE")
        :Category("class")
      )
    end
  else
    -- For < 58 - Have generic conjuration of 1 gem (only max rank)
    -- Conjure Mana Stone (Max Rank)
    buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Mage_ConjureManaEmerald, nil)
        :IsOwn(true)
        :IsDefault(true)
        :LockIfHaveItem({ itemIdsModule.Mage_ManaSapphire,
          itemIdsModule.Mage_ManaAgate,
          itemIdsModule.Mage_ManaJade,
          itemIdsModule.Mage_ManaCitrine,
          itemIdsModule.Mage_ManaRuby,
          itemIdsModule.Mage_ManaEmerald })
        :SingleFamily({ spellIdsModule.Mage_ConjureManaAgate,
          spellIdsModule.Mage_ConjureManaJade,
          spellIdsModule.Mage_ConjureManaCitrine,
          spellIdsModule.Mage_ConjureManaRuby,
          spellIdsModule.Mage_ConjureManaEmerald,
          spellIdsModule.Mage_ConjureManaSapphire })
        :RequirePlayerClass("MAGE")
        :Category("class")
        :HideInCata()
  end
  -- For < 58 - Have generic conjuration of 1 gem (only max rank)
  -- Conjure Mana Stone (Max Rank)
  buffDefModule:createAndRegisterBuff(allBuffs, spellIdsModule.Mage_ConjureManaEmerald, nil)
      :IsOwn(true)
      :IsDefault(true)
      :LockIfHaveItem({ itemIdsModule.Mage_Cataclysm_ManaGem })
      :SingleFamily({ spellIdsModule.Mage_Cataclysm_ManaGem })
      :RequirePlayerClass("MAGE")
      :Category("class")
      :RequireCata()
end
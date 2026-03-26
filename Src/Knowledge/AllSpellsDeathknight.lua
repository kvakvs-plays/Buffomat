local BuffomatAddon = BuffomatAddon

---@class DeathknightModule

local deathknightModule = LibStub("Buffomat-AllSpellsDeathknight") --[[@as DeathknightModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local itemIdsModule = LibStub("Buffomat-ItemIds") --[[@as ItemIdsModule]]

---Add DEATH KNIGHT spells
---@param allBuffs BomBuffDefinition[]
---@param enchants BomEnchantmentsMapping
function deathknightModule:SetupDeathknightSpells(allBuffs, enchants)
  -- TODO: Tag presence buffs and exclude other buffs from the same family when clicking the UI
  -- Blood Presence
  buffDefModule:createAndRegisterBuff(allBuffs, 48266, nil)
      :IsOwn(true)
      :IsDefault(true)
      :ShapeshiftFormId(1)
      :RequirePlayerClass("DEATHKNIGHT")
      :Category("class")
  -- Frost Presence
  buffDefModule:createAndRegisterBuff(allBuffs, 48263, nil)
      :IsOwn(true)
      :IsDefault(false)
      :ShapeshiftFormId(2)
      :RequirePlayerClass("DEATHKNIGHT")
      :Category("class")
  -- Unholy Presence
  buffDefModule:createAndRegisterBuff(allBuffs, 48265, nil)
      :IsOwn(true)
      :IsDefault(false)
      :ShapeshiftFormId(3)
      :RequirePlayerClass("DEATHKNIGHT")
      :Category("class")
  -- Horn of Winter
  buffDefModule:createAndRegisterBuff(allBuffs, 57330, nil)
      :IsDefault(true)
      :IsOwn(true)
      :SingleFamily({ 57330, 57623 })   -- Rank 1 and 2
      :SingleDuration(allBuffsModule.TWO_MINUTES)
      :RequirePlayerClass("DEATHKNIGHT")
      :Category("class")
  -- Bone Shield
  buffDefModule:createAndRegisterBuff(allBuffs, 49222, nil)
      :IsDefault(true)
      :SingleDuration(allBuffsModule.FIVE_MINUTES)
      :IsOwn(true)
      :HasCooldown(true)
      :RequirePlayerClass("DEATHKNIGHT")
      :Category("class")
  --Raise Dead
  buffDefModule:createAndRegisterBuff(allBuffs, 46584, nil)
      :IsDefault(true)
      :IsOwn(true)
      :HasCooldown(true)
      :BuffType("summon")
      :ReagentRequired({ itemIdsModule.Deathknight_CorpseDust })
      :SummonCreatureFamily(40) -- "Ghoul"
      :SummonCreatureType(6) -- "Undead"
      :RequirePlayerClass("DEATHKNIGHT")
      :Category("pet")
end

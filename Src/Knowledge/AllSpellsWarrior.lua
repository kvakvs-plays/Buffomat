---@class WarriorModule

local warriorModule = LibStub("Buffomat-AllSpellsWarrior") --[[@as WarriorModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

---Add WARRIOR spells
function warriorModule:SetupWarriorSpells(spells, enchantments)
  --Battle Shout
  buffDefModule:createAndRegisterBuff(spells, 25289, nil)
      :IsOwn(true)
      :IsDefault(false)
      :SingleFamily({ 6673, 5242, 6192, 11549, 11550, 11551, 25289,   -- Battle Shout 1-7
        2048,                                                         -- TBC: Battle Shout 8
        47436 })                                                      -- WotLK: Battle Shout 9
      :RequirePlayerClass("WARRIOR")
      :Category("class")

  --Battle Stance
  buffDefModule:createAndRegisterBuff(spells, 2457, nil)
      :IsOwn(true)
      :IsDefault(true)
      :ShapeshiftFormId(17)
      :RequirePlayerClass("WARRIOR")
      :Category("class")

  --Defensive Stance
  buffDefModule:createAndRegisterBuff(spells, 71, nil)
      :IsOwn(true)
      :IsDefault(true)
      :ShapeshiftFormId(18)
      :RequirePlayerClass("WARRIOR")
      :Category("class")

  --Berserker Stance
  buffDefModule:createAndRegisterBuff(spells, 2458, nil)
      :IsOwn(true)
      :IsDefault(true)
      :ShapeshiftFormId(19)
      :RequirePlayerClass("WARRIOR")
      :Category("class")
end
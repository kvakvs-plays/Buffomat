---@class PriestModule

local priestModule = LibStub("Buffomat-AllSpellsPriest") --[[@as PriestModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]

function priestModule:CreatePrayerOfSpiritBuff()
  local b = buffDefModule:New(14819)              -- Divine Spirit / Prayer of Spirit / Willenstärke
  b:IsDefault(true)
      :SingleFamily({ 14752, 14818, 14819, 27841, -- Divine Spirit 1-4
        25312,                                    -- TBC: Divine Spirit 5
        48073 })                                  -- WotLK: Divine Spirit 6
      :GroupFamily({ 27681,                       -- Prayer of Spirit 1
        32999,                                    --- TBC: Prayer of Spirit 2
        48074 })                                  -- WotLK: Prayer of Spirit 3
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :GroupDuration(allBuffsModule.HOUR)
      :ReagentRequired({ 17028, 17029,
        44615 }) -- WotLK: Devout Candle
      :DefaultTargetClasses(allBuffsModule.MANA_CLASSES)
  --:IgnoreIfHaveBuff({ 46302, -- Kiru's Song of Victory (Sunwell)
  --                    54424, -- Fel Intelligence 1 (Wotlk Warlock)
  --                    57564, -- Fel Intelligence 2 (Wotlk Warlock)
  --                    57565, -- Fel Intelligence 3 (Wotlk Warlock)
  --                    57566, -- Fel Intelligence 4 (Wotlk Warlock)
  --                    57567 }) -- Fel Intelligence 5 (Wotlk Warlock)
      :Category("class")
  return b
end

function priestModule:CreatePowerWordShieldBuff()
  local b = buffDefModule:New(10901)                                              -- Power Word: Shield / Powerword:Shild
  b:IsDefault(false)
      :SingleFamily({ 17, 592, 600, 3747, 6065, 6066, 10898, 10899, 10900, 10901, -- Power Word: Shield 1-10
        25217, 25218,                                                             -- TBC: Power Word: Shield 11-12
        48065, 48066 })                                                           -- WotLK: Power Word: Shield 13-14
      :SingleDuration(30)
      :HasCooldown(true)
      :DefaultTargetClasses(allBuffsModule.BOM_NO_CLASSES)
      :Category("class")
  return b
end

---Add PRIEST spells
---@param allBuffs BomBuffDefinition[]
---@param _enchants BomEnchantmentsMapping
function priestModule:SetupPriestSpells(allBuffs, _enchants)
  -- Fortitude / Seelenstärke
  buffDefModule:createAndRegisterBuff(allBuffs, 10938, nil)
      :IsDefault(true)
      :SingleFamily({ 1243, 1244, 1245, 2791, 10937, 10938, -- Power Word: Fortitude 1-6
        25389,                                              -- TBC: Power Word: Fortitude 7
        48161 })                                            -- WotLK Power Word: Fortitude 8
      :GroupFamily({ 21562, 21564,                          -- Prayer of Fortitude 1-2
        25392,                                              -- TBC: Prayer of Fortitude 3
        48162 })                                            -- WotLK: Prayer of Fortitude 4
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :GroupDuration(allBuffsModule.HOUR)
      :ReagentRequired({ 17028, 17029, -- Candle
        44615 })                       -- WotLK: Devout Candle
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")
  --:IgnoreIfHaveBuff(46302) -- Kiru's Song of Victory (Sunwell)
      :RequirePlayerClass("PRIEST")
      :HideInCata()

  -- [Cataclysm] Fortitude / Seelenstärke
  buffDefModule:createAndRegisterBuff(allBuffs, 10938, nil)
      :IsDefault(true)
      :SingleFamily({ 21562 }) -- Cata: Power Word: Fortitude
      :GroupFamily({ 21562 })  -- Cata: Power Word: Fortitude
      :ProvidesAuras({ 79104, 79105 })
      :SingleDuration(allBuffsModule.HOUR)
      :GroupDuration(allBuffsModule.HOUR)
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")
      :RequirePlayerClass("PRIEST")
      :RequireCata()

  table.insert(allBuffs, priestModule:CreatePrayerOfSpiritBuff())

  -- Shadow Protection / Prayer of Shadow / Schattenschutz
  buffDefModule:createAndRegisterBuff(allBuffs, 10958, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :GroupDuration(allBuffsModule.TWENTY_MINUTES)
      :SingleFamily({ 976, 10957, 10958, -- Shadow Protection 1-3
        25433,                           -- TBC: Shadow Protection 4
        48169 })                         -- WotLK: Shadow Protection 5
      :GroupFamily({ 27683,              -- Prayer of Shadow Protection 1
        39374,                           -- TBC: Prayer of Shadow Protection 2
        48170 })                         -- WotLK: Prayer of Shadow Protection 3
      :ReagentRequired({ 17028, 17029,
        44615 })                         -- WotLK: Devout Candle
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")
      :RequirePlayerClass("PRIEST")
      :HideInCata()

  -- [Cataclysm] Shadow Protection / Prayer of Shadow / Schattenschutz
  buffDefModule:createAndRegisterBuff(allBuffs, 10958, nil)
      :IsDefault(true)
      :SingleFamily({ 27683 }) -- Cata: Shadow Protection
      :GroupFamily({ 27683 })  -- Cata: Shadow Protection
      :ProvidesAuras({ 79106, 79107 })
      :SingleDuration(allBuffsModule.HOUR)
      :GroupDuration(allBuffsModule.HOUR)
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")
      :RequirePlayerClass("PRIEST")
      :RequireCata()

  -- Fear Ward
  buffDefModule:createAndRegisterBuff(allBuffs, 6346, nil)
      :IsDefault(false)
      :SingleDuration(allBuffsModule.TEN_MINUTES)
      :HasCooldown(true)
      :DefaultTargetClasses(allBuffsModule.ALL_CLASSES)
      :Category("class")
      :RequirePlayerClass("PRIEST")

  table.insert(allBuffs, self:CreatePowerWordShieldBuff())

  -- Touch of Weakness / Berührung der Schwäche (Clasic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 19266, nil)
      :IsDefault(true)
      :IsOwn(true)
      :SingleFamily({ 2652, 19261, 19262, 19264, 19265, 19266, -- Ranks 1-6
        25461 })                                               -- TBC: Rank 7
      :Category("class")
      :RequirePlayerClass("PRIEST")

  -- Inner Fire / inneres Feuer
  buffDefModule:createAndRegisterBuff(allBuffs, 10952, nil)
      :IsDefault(true)
      :IsOwn(true)
      :SingleFamily({ 588, 7128, 602, 1006, 10951, 10952, -- Inner Fire 1-6
        25431,                                            -- TBC: Inner Fire 7
        48040, 48168 })                                   -- WotLK: Inner Fire 8-9
      :Category("class")
      :RequirePlayerClass("PRIEST")

  -- Shadowguard (Clasic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 19312, nil)
      :IsDefault(true)
      :IsOwn(true)
      :SingleFamily({ 18137, 19308, 19309, 19310, 19311, 19312, -- Ranks 1-6
        25477 })                                                -- TBC: Rank 7
      :Category("class")
      :RequirePlayerClass("PRIEST")

  -- Elune's Grace (Clasic and TBC only)
  buffDefModule:createAndRegisterBuff(allBuffs, 19293, nil)
      :IsDefault(true)
      :IsOwn(true)
      :SingleFamily({ 2651,           -- Rank 1 also TBC: The only rank
        19289, 19291, 19292, 19293 }) -- Ranks 2-5 (non-TBC)
      :RequirePlayerClass("PRIEST")
      :Category("class")
  -- Shadow Form
  buffDefModule:createAndRegisterBuff(allBuffs, 15473, nil)
      :IsDefault(false)
      :IsOwn(true)
      :RequirePlayerClass("PRIEST")
      :Category("class")
  -- Resurrection / Auferstehung
  buffDefModule:createAndRegisterBuff(allBuffs, 20770, nil)
      :RequiresCancelForm(true)
      :BuffType("resurrection")
      :IsDefault(true)
      :SingleFamily({ 2006, 2010, 10880, 10881, 20770, -- Resurrection 1-5
        25435,                                         -- TBC: Resurrection 6
        48171 })                                       -- WotLK: Resurrection 7
      :RequirePlayerClass("PRIEST")
      :Category("class")
  -- WotLK: Vampiric Embrace is a buff
  buffDefModule:createAndRegisterBuff(allBuffs, 15286, nil)
      :IsDefault(false)
      :IsOwn(true)
      :SingleFamily({ 15286 }) -- WotLK: Vampiric Embrace
      :RequireWotLK()
      :RequirePlayerClass("PRIEST")
      :Category("class")
end
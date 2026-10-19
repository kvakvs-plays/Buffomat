---@class AllConsumesScrollsModule

local scrollsModule = LibStub("Buffomat-AllConsumesScrolls") --[[@as AllConsumesScrollsModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---SCROLLS
---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:SetupScrolls(allBuffs, enchantments)
  self:_SetupScrollsAgility(allBuffs, enchantments)
  self:_SetupScrollsStrength(allBuffs, enchantments)
  self:_SetupScrollsProtection(allBuffs, enchantments)
  self:_SetupScrollsSpirit(allBuffs, enchantments)
  self:_SetupScrollsIntellect(allBuffs, enchantments)
  self:_SetupInscriptionScrolls(allBuffs, enchantments)
end

function scrollsModule:AddScroll(buffs, buffSpellId, itemId)
  return buffDefModule:genericConsumable(buffs, buffSpellId, itemId)
      :ConsumableTarget("player")
      :SingleDuration(allBuffsModule.HALF_AN_HOUR)
      :Category("scroll")
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:_SetupScrollsAgility(allBuffs, enchantments)
  local scrollItemIds = {
    4425,  -- Scroll of Agility 3
    10309, -- Scroll of Agility 4
  }
  if envModule.haveTBC then
    table.insert(scrollItemIds, 27498) -- Scroll of Agility 5 (TBC)
  end
  if envModule.haveWotLK then
    table.insert(scrollItemIds, 33457) -- WotLK: Scroll of Agility 6
    table.insert(scrollItemIds, 43463) -- WotLK: Scroll of Agility 7
    table.insert(scrollItemIds, 43464) -- WotLK: Scroll of Agility 8
  end
  if envModule.haveCata then
    table.insert(scrollItemIds, 63303) -- Cata: Scroll of Agility 9
  end

  local scrollAuras = {
    8117,  -- Aura for Scroll of Agility 3
    12174, -- Aura for Scroll of Agility 4
  }
  if envModule.haveTBC then
    table.insert(scrollAuras, 33077) -- Aura for Scroll of Agility 5 (TBC)
  end
  if envModule.haveWotLK then
    table.insert(scrollAuras, 43194) -- Aura for Scroll of Agility 6 (WotLK)
    table.insert(scrollAuras, 58450) -- Aura for Scroll of Agility 7 (WotLK)
    table.insert(scrollAuras, 58451) -- Aura for Scroll of Agility 8 (WotLK)
  end
  if envModule.haveCata then
    table.insert(scrollAuras, 89343) -- Aura for Scroll of Agility 9 (Cata)
  end

  buffDefModule:consumableGroup(allBuffs, "scrollAgi", scrollAuras, scrollItemIds)
      :RequirePlayerClass(allBuffsModule.PHYSICAL_CLASSES)
      :ConsumeGroupTitle("scroll", ITEM_MOD_AGILITY_SHORT, 237162) -- "inv_inscription_scroll"
      :Category("scroll")
      :ExtraText(_t("tooltip.scroll.bestInBag"))
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:_SetupScrollsStrength(allBuffs, enchantments)
  local scrollItemIds = {
    4426,  -- Scroll of Strength 3
    10310, -- Scroll of Strength 4
  }
  if envModule.haveTBC then
    table.insert(scrollItemIds, 27503) -- TBC: Scroll of Strength 5
  end
  if envModule.haveWotLK then
    table.insert(scrollItemIds, 33462) -- WotLK: Scroll of Strength 6
    table.insert(scrollItemIds, 43465) -- WotLK: Scroll of Strength 7
    table.insert(scrollItemIds, 43466) -- WotLK: Scroll of Strength 8
  end
  if envModule.haveCata then
    table.insert(scrollItemIds, 63304) -- Cata: Scroll of Strength 9
  end

  local scrollAuras = {
    8120,  -- Aura for Scroll of Strength 3
    12179, -- Aura for Scroll of Strength 4
  }
  if envModule.haveTBC then
    table.insert(scrollAuras, 33082) -- Aura for Scroll of Strength 5 (TBC)
  end
  if envModule.haveWotLK then
    table.insert(scrollAuras, 43199) -- Aura for Scroll of Strength 6 (WotLK)
    table.insert(scrollAuras, 58448) -- Aura for Scroll of Strength 7 (WotLK)
    table.insert(scrollAuras, 58449) -- Aura for Scroll of Strength 8 (WotLK)
  end
  if envModule.haveCata then
    table.insert(scrollAuras, 89346) -- Aura for Scroll of Strength 9 (Cata)
  end

  buffDefModule:consumableGroup(allBuffs, "scrollStr", scrollAuras, scrollItemIds)
      :RequirePlayerClass(allBuffsModule.MELEE_CLASSES)
      :ConsumeGroupTitle("scroll", ITEM_MOD_STRENGTH_SHORT, 237162) -- "inv_inscription_scroll"
      :Category("scroll")
      :ExtraText(_t("tooltip.scroll.bestInBag"))
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:_SetupScrollsProtection(allBuffs, enchantments)
  local scrollItemIds = {
    3013,  -- Scroll of Protection 1
    1478,  -- Scroll of Protection 2
    4421,  -- Scroll of Protection 3
    10305, -- Scroll of Protection 4
  }
  if envModule.haveTBC then
    table.insert(scrollItemIds, 27500) -- TBC: Scroll of Protection 5
  end
  if envModule.haveWotLK then
    table.insert(scrollItemIds, 33459) -- WotLK: Scroll of Protection 6
    table.insert(scrollItemIds, 43467) -- WotLK: Scroll of Protection 7
    table.insert(scrollItemIds, 43466) -- WotLK: Scroll of Protection 8
  end
  if envModule.haveCata then
    table.insert(scrollItemIds, 63308) -- Cata: Scroll of Protection 9
  end

  local scrollAuras = {
    8091,  -- Aura for Scroll of Protection 1
    8094,  -- Aura for Scroll of Protection 2
    8095,  -- Aura for Scroll of Protection 3
    12175, -- Aura for Scroll of Protection 4
  }
  if envModule.haveTBC then
    table.insert(scrollAuras, 33079) -- Aura for Scroll of Protection 5 (TBC)
  end
  if envModule.haveWotLK then
    table.insert(scrollAuras, 43196) -- Aura for Scroll of Protection 6 (WotLK)
    table.insert(scrollAuras, 58452) -- Aura for Scroll of Protection 7 (WotLK)
    table.insert(scrollAuras, 58453) -- Aura for Scroll of Protection 8 (WotLK)
  end
  if envModule.haveCata then
    table.insert(scrollAuras, 89344) -- Aura for Scroll of Protection 9 (Cata)
  end

  buffDefModule:consumableGroup(allBuffs, "scrollArmor", scrollAuras, scrollItemIds)
      :ConsumeGroupTitle("scroll", ITEM_MOD_EXTRA_ARMOR_SHORT, 237162) -- "inv_inscription_scroll"
      :Category("scroll")
      :ExtraText(_t("tooltip.scroll.bestInBag"))
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:_SetupScrollsSpirit(allBuffs, enchantments)
  local scrollItemIds = {
    1181,  -- Scroll of Spirit 1
    1712,  -- Scroll of Spirit 2
    4424,  -- Scroll of Spirit 3
    10306, -- Scroll of Spirit 4
  }
  if envModule.haveTBC then
    table.insert(scrollItemIds, 27501) -- TBC: Scroll of Spirit 5
  end
  if envModule.haveWotLK then
    table.insert(scrollItemIds, 33460) -- WotLK: Scroll of Spirit 6
    table.insert(scrollItemIds, 37097) -- WotLK: Scroll of Spirit 7
    table.insert(scrollItemIds, 37098) -- WotLK: Scroll of Spirit 8
  end
  if envModule.haveCata then
    table.insert(scrollItemIds, 63307) -- Cata: Scroll of Spirit 9
  end

  local scrollAuras = {
    8112,  -- Aura for Scroll of Spirit 1
    8113,  -- Aura for Scroll of Spirit 2
    8114,  -- Aura for Scroll of Spirit 3
    12177, -- Aura for Scroll of Spirit 4
  }
  if envModule.haveTBC then
    table.insert(scrollAuras, 33080) -- Aura for Scroll of Spirit 5 (TBC)
  end
  if envModule.haveWotLK then
    table.insert(scrollAuras, 43197) -- Aura for Scroll of Spirit 6 (WotLK)
    table.insert(scrollAuras, 48103) -- Aura for Scroll of Spirit 7 (WotLK)
    table.insert(scrollAuras, 48104) -- Aura for Scroll of Spirit 8 (WotLK)
  end
  if envModule.haveCata then
    table.insert(scrollAuras, 89342) -- Aura for Scroll of Spirit 9 (Cata)
  end

  buffDefModule:consumableGroup(allBuffs, "scrollSpi", scrollAuras, scrollItemIds)
      :ConsumeGroupTitle("scroll", ITEM_MOD_SPIRIT_SHORT, 237162) -- "inv_inscription_scroll"
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("scroll")
      :ExtraText(_t("tooltip.scroll.bestInBag"))
end

---@param allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:_SetupScrollsIntellect(allBuffs, enchantments)
  local scrollItemIds = {
    955,   -- Scroll of Intellect 1
    2290,  -- Scroll of Intellect 2
    4419,  -- Scroll of Intellect 3
    10308, -- Scroll of Intellect 4
  }
  if envModule.haveTBC then
    table.insert(scrollItemIds, 27499) -- TBC: Scroll of Intellect 5
  end
  if envModule.haveWotLK then
    table.insert(scrollItemIds, 33458) -- WotLK: Scroll of Intellect 6
    table.insert(scrollItemIds, 37091) -- WotLK: Scroll of Intellect 7
    table.insert(scrollItemIds, 37092) -- WotLK: Scroll of Intellect 8
  end
  if envModule.haveCata then
    table.insert(scrollItemIds, 63305) -- Cata: Scroll of Intellect 9
  end

  local scrollAuras = {
    8096,  -- Aura for Scroll of Intellect 1
    8097,  -- Aura for Scroll of Intellect 2
    8098,  -- Aura for Scroll of Intellect 3
    12176, -- Aura for Scroll of Intellect 4
  }
  if envModule.haveTBC then
    table.insert(scrollAuras, 33078) -- Aura for Scroll of Intellect 5 (TBC)
  end
  if envModule.haveWotLK then
    table.insert(scrollAuras, 43195) -- Aura for Scroll of Intellect 6 (WotLK)
    table.insert(scrollAuras, 48099) -- Aura for Scroll of Intellect 7 (WotLK)
    table.insert(scrollAuras, 48100) -- Aura for Scroll of Intellect 8 (WotLK)
  end
  if envModule.haveCata then
    table.insert(scrollAuras, 43195) -- Aura for Scroll of Intellect 6 (WotLK)
    table.insert(scrollAuras, 48099) -- Aura for Scroll of Intellect 7 (WotLK)
    table.insert(scrollAuras, 89347) -- Aura for Scroll of Intellect 9 (Cata)
  end

  buffDefModule:consumableGroup(allBuffs, "scrollInt", scrollAuras, scrollItemIds)
      :ConsumeGroupTitle("scroll", ITEM_MOD_INTELLECT_SHORT, 237162) -- "inv_inscription_scroll"
      :RequirePlayerClass(allBuffsModule.MANA_CLASSES)
      :Category("scroll")
      :ExtraText(_t("tooltip.scroll.bestInBag"))
end

---@param _allBuffs BomBuffDefinition[] A list of buffs (not dictionary)
---@param enchantments table<number, number[]> Key is spell id, value is list of enchantment ids
function scrollsModule:_SetupInscriptionScrolls(_allBuffs, enchantments)
  -- TODO: Brilliance scroll
  -- TODO: Fortitude scroll
  -- TODO: Cataclysm - Runescroll of Fort & Might
end
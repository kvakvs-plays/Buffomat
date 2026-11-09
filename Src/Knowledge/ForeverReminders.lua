local addonName, ns = ...
-- WoW: Forever reminders for things Buffomat cannot cast: Camp Benefits and experience bonuses.
-- Both are for levelling, so they are hidden at the level cap, in the scan and in the Spells dialog.
-- IDs from the Forever client data (build 1.60.1.70862); see .agents/wowf-plan.md section 7.

---@class ForeverRemindersModule

local module = LibStub("Buffomat-ForeverReminders") --[[@as ForeverRemindersModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local buffDefModule = LibStub("Buffomat-BuffDefinition") --[[@as BuffDefinitionModule]]
local buffChecksModule = LibStub("Buffomat-BuffChecks") --[[@as BuffChecksModule]]
local spellIdsModule = LibStub("Buffomat-SpellIds") --[[@as SpellIdsModule]]

-- Forever's level cap; the reminders show up to the level below it
local MAX_LEVEL = 60

local CAMP_BENEFITS = 1229741    -- 60 min aura after sitting by a campfire with camp features placed
local CAMP_NEAR_AURAS = {
  1283391,                       -- Campfire Nearby, area aura around a campfire
  1229739, 1289723,              -- Welcoming Campfire, while sitting by one (gives Camp Benefits after 1 min)
}
local WELL_FED_XP_BOOST = 1243969 -- passive: +5% kill experience while Well Fed (named in the settings)
-- Forever Well Fed auras whose tooltip includes the experience bonus
local WELL_FED_XP_AURAS = {
  1248406, 1248420, 1248421, 1248422, 1248688, 1249519, 1249520, 1249521, 1249523, 1249907,
  1249926, 1249927, 1319310,
}
local WELL_RESTED = 429959       -- sleeping bag: more experience, stacks up to 3 times
local COZY_SLEEPING_BAG = 211527 -- ForeverDB marks it a Season of Discovery leftover; asked for only if in bags

---@param auras table<WowSpellId, boolean> All helpful auras on the unit
---@param ids WowSpellId[]
---@return boolean
local function hasAnyAura(auras, ids)
  for _, id in ipairs(ids) do
    if auras[id] then
      return true
    end
  end
  return false
end

---@param itemId WowItemId
---@return number
local function itemCount(itemId)
  local getCount = (C_Item and C_Item.GetItemCount) or GetItemCount
  return getCount and getCount(itemId) or 0
end

---Near a campfire without Camp Benefits, or with them about to run out
---@type BomReminderCheck
function module.CampCheck(buffDef, playerUnit)
  if not hasAnyAura(playerUnit.allBuffs, CAMP_NEAR_AURAS) then
    return nil
  end
  local camp = playerUnit.knownBuffs[buffDef.buffId]
  if camp and buffChecksModule:TimeCheck(camp.expirationTime, camp.duration) then
    return nil
  end
  return _t("reminder.camp")
end

---Experience bonuses the player could have: Well Fed, and the sleeping bag when it is in the bags.
---Rested experience is added to the text. Quiet while eating, as the Well Fed aura is on its way.
---@type BomReminderCheck
function module.XpCheck(_buffDef, playerUnit)
  local auras = playerUnit.allBuffs
  if hasAnyAura(auras, spellIdsModule.ForeverFood) or hasAnyAura(auras, spellIdsModule.ClassicFood) then
    return nil
  end

  local missing = {}
  if not hasAnyAura(auras, WELL_FED_XP_AURAS) then
    table.insert(missing, _t("reminder.xp.wellFed"))
  end
  if not auras[WELL_RESTED] and itemCount(COZY_SLEEPING_BAG) > 0 then
    table.insert(missing, _t("reminder.xp.sleepingBag"))
  end
  if #missing == 0 then
    return nil
  end

  local text = table.concat(missing, ", ")
  local rested = GetXPExhaustion and GetXPExhaustion()
  local levelXp = UnitXPMax and UnitXPMax("player")
  if rested and levelXp and levelXp > 0 then
    text = text .. "; " .. string.format(_t("reminder.xp.rested"), math.floor(rested * 100 / levelXp))
  end
  return text
end

---@param allBuffs BomBuffDefinition[]
function module:SetupForeverReminders(allBuffs)
  buffDefModule:createAndRegisterBuff(allBuffs, CAMP_BENEFITS, nil)
      :Reminder(module.CampCheck, "ForeverCampReminder")
      :MaxLevel(MAX_LEVEL - 1)
      :RequireForever()

  buffDefModule:createAndRegisterBuff(allBuffs, WELL_FED_XP_BOOST, nil)
      :Reminder(module.XpCheck, "ForeverXpReminder")
      :MaxLevel(MAX_LEVEL - 1)
      :RequireForever()
end

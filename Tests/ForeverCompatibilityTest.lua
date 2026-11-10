-- Run from the repository root: lua Tests/ForeverCompatibilityTest.lua
local function loadModule(path, globals)
  local chunk
  if setfenv then
    chunk = assert(loadfile(path))
    setfenv(chunk, globals)
  else
    chunk = assert(loadfile(path, "t", globals))
  end
  chunk("BuffomatClassic", {})
end

local function equal(actual, expected, label)
  assert(actual == expected, (label or "value") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function fixture(projectID, interfaceVersion, expansion, modern)
  local libs, handlers = {}, {}
  local secret = {}
  local state = { restrictions = {}, power = 100, maxPower = 200, range = true, checked = true,
    main = { { hasEnchant = false }, { hasEnchant = true, timeLeft = 120000, charges = 3, enchantID = 10 } },
    off = { { hasEnchant = true, timeLeft = 60000, charges = 2, enchantID = 20 } },
  }
  local globals = setmetatable({
    WOW_PROJECT_ID = projectID, WOW_PROJECT_MAINLINE = 1, WOW_PROJECT_CLASSIC = 2,
    WOW_PROJECT_BURNING_CRUSADE_CLASSIC = 5, WOW_PROJECT_WRATH_CLASSIC = 11, WOW_PROJECT_CATACLYSM_CLASSIC = 14,
    LE_EXPANSION_LEVEL_CURRENT = expansion,
    GetBuildInfo = function() return "", "", "", interfaceVersion end,
    UnitClass = function() return "Shaman", "SHAMAN" end,
    UnitPower = function() return state.power end,
    UnitPowerMax = function() return state.maxPower end,
    UnitInRange = function() return state.range, state.checked end,
    UnitIsUnit = function(a, b) return a == b end,
    InCombatLockdown = function() return state.combat or false end,
    IsInRaid = function() return false end, IsInGroup = function() return false end,
    UnitIsDeadOrGhost = function() return false end,
    wipe = function(t) for k in pairs(t) do t[k] = nil end return t end,
    GetTime = function() return 100 end,
    issecretvalue = function(value) return rawequal(value, secret) end,
    ChatFrame_OpenChat = function() state.chat = true end,
    ChatEdit_SendText = function() state.sent = true end,
    BuffomatAddon = { RegisterEvent = function(_, event, handler) handlers[event] = handler end },
    LibStub = function(name) libs[name] = libs[name] or {}; return libs[name] end,
  }, { __index = _G })
  globals._G = globals
  globals.NUM_BAG_SLOTS = 4
  if modern then
    globals.Enum = { WeaponSlot = { MainHand = 0, OffHand = 1 },
      AddOnRestrictionType = { Combat = 0, Encounter = 1, ChallengeMode = 2, PvPMatch = 3 },
      BagIndex = { ReagentBag = 5 } }
    globals.Constants = { InventoryConstants = { NumBagSlots = 4, NumReagentBagSlots = 1 } }
    globals.C_RestrictedActions = {
      IsAddOnRestrictionActive = function(kind) return state.restrictions[kind] or false end,
    }
    globals.C_Item = {
      GetWeaponEnchantInfo = function(slot) if slot == 0 then return state.main else return state.off end end,
      IsItemInRange = function() return state.range end,
    }
    globals.C_PaperDollInfo = { GetInventorySlotInfo = function(slot) return slot == "MainHandSlot" and 16 or 17 end }
    globals.C_SpecializationInfo = { GetActiveSpecGroup = function() return 2 end }
    globals.C_UnitAuras = { GetAuraDataByIndex = function()
      assert(not next(state.restrictions), "restricted aura API was called")
      state.auraRead = true
    end }
    -- Some Forever builds expose the combat-log getter but prohibit registering
    -- its event. Detection must not rely solely on the getter's presence.
    globals.CombatLogGetCurrentEventInfo = function() error("combat log unavailable") end
  else
    -- Classic clients carry the shared ReagentBag enum, but bag 5 is a bank bag there.
    globals.Enum = { BagIndex = { ReagentBag = 5 } }
    globals.Constants = { InventoryConstants = { NumBagSlots = 4 } }
    globals.CAT_FORM = 1
    globals.GetWeaponEnchantInfo = function() return true, 120000, 3, 10, true, 60000, 2, 20 end
    globals.GetInventorySlotInfo = function(slot) return slot == "MainHandSlot" and 16 or 17 end
    globals.GetActiveTalentGroup = function() return 2 end
    globals.IsItemInRange = function() return state.range end
    globals.MouseIsOver = function() return true end
    globals.CombatLogGetCurrentEventInfo = function() end
  end
  loadModule("Src/KvLib/KvEnv.lua", globals)
  return libs, handlers, state, globals, secret
end

for _, client in ipairs({
  -- Forever reported WOW_PROJECT_ID 1 on beta 69913 and 18 on 1.60.1.70205.
  { 1, 16001, 0, true, true }, { 18, 16001, 0, true, true }, { 1, 120105, 11, true, false },
  { 1, 16001, 11, true, false }, { 2, 11508, 0, false, false },
  { 5, 20506, 1, false, false }, { 11, 30402, 2, false, false }, { 14, 40402, 3, false, false },
}) do
  local project, interface, expansion, modern, forever = client[1], client[2], client[3], client[4], client[5]
  local libs, _handlers, state, globals, secret = fixture(project, interface, expansion, modern)
  local env = libs["KvLibShared-Env"]
  equal(env.isForever, forever, "Forever detection")
  equal(env.isClassic, project == 2 or forever, "Classic content selection")
  equal(table.concat(env.playerBagIds, ","), modern and "0,1,2,3,4,5" or "0,1,2,3,4", "player bag IDs")
  if forever or not modern then equal(env.CAT_FORM, 1) end
  equal(env.GetInventorySlotInfo("MainHandSlot"), 16)
  equal(env.GetInventorySlotInfo("SECONDARYHANDSLOT"), 17)
  equal(env.GetActiveTalentGroup(), 2)
  equal(env.MouseIsOver({ IsMouseOver = function() return true end }), true)
  if not modern then equal(env.MouseIsOver({}), true) end

  local main, mainTime, mainCharges, mainID, off, offTime, offCharges, offID = env.GetWeaponEnchantInfo()
  equal(main, true); equal(mainTime, 120000); equal(mainCharges, 3); equal(mainID, 10)
  equal(off, true); equal(offTime, 60000); equal(offCharges, 2); equal(offID, 20)
  if modern then
    for _, key in ipairs({ "hasEnchant", "timeLeft", "charges", "enchantID" }) do
      local saved = state.main[2][key]
      state.main[2][key] = secret
      equal(env.GetWeaponEnchantInfo(), nil, "restricted weapon " .. key)
      state.main[2][key] = saved
    end
    state.main = nil
    equal(env.GetWeaponEnchantInfo(), nil, "missing enchant data is unavailable, not unenchanted")
    state.main, state.off = {}, {}
    equal(env.GetWeaponEnchantInfo(), false, "empty weapon slot is readable")
  end

  equal(env.UnitPower("player", 0), 100); equal(env.UnitPowerMax("player", 0), 200)
  state.power, state.maxPower = secret, secret
  equal(env.UnitPower("player", 0), nil); equal(env.UnitPowerMax("player", 0), nil)
  equal(env.UnitInRange("party1"), true); equal(env.IsItemInRange(42, "party1"), true)
  state.range = secret
  equal(env.UnitInRange("party1"), nil); equal(env.IsItemInRange(42, "party1"), nil)
  state.range, state.checked = true, secret
  equal(env.UnitInRange("party1"), nil, "checked range may itself be secret")
  equal(env.ChatFrame_OpenChat("/w Tester "), not forever)
  equal(env.ChatEdit_SendText({}), not forever)
  if forever then assert(not state.chat and not state.sent, "Forever must not activate chat") end

  if modern then
    local names = { [0] = "Combat", "Encounter", "ChallengeMode", "PvPMatch" }
    for kind = 0, 3 do
      state.restrictions[kind] = true
      equal(env.IsAuraRestricted(), true)
      equal(env.GetAuraRestriction(), names[kind])
      local aura, readable = env.GetUnitAura("player", 1, "HELPFUL")
      equal(aura, nil); equal(readable, false); equal(state.auraRead, nil)
      state.restrictions[kind] = nil
    end
    -- A stricter restriction wins over the PvP match
    state.restrictions[0], state.restrictions[3] = true, true
    equal(env.GetAuraRestriction(), "Combat")
    state.restrictions[0], state.restrictions[3] = nil, nil
    equal(env.IsAuraRestricted(), false)
    equal(env.GetAuraRestriction(), nil)
    local _, readable = env.GetUnitAura("player", 1, "HELPFUL")
    equal(readable, true); equal(state.auraRead, true)

    -- During ADDON_RESTRICTION_STATE_CHANGED the restriction reports Activating
    globals.Enum.AddOnRestrictionState = { Inactive = 0, Activating = 1, Active = 2 }
    globals.C_RestrictedActions.GetAddOnRestrictionState = function(kind)
      return state.restrictionState[kind] or 0
    end
    state.restrictionState = { [3] = 1 }
    loadModule("Src/KvLib/KvEnv.lua", globals)
    equal(env.GetAuraRestriction(), "PvPMatch", "Activating counts as restricted")
    state.restrictionState = { [3] = secret }
    equal(env.GetAuraRestriction(), "PvPMatch", "secret state counts as restricted")
    state.restrictionState = {}
    equal(env.GetAuraRestriction(), nil)
    globals.Enum.AddOnRestrictionState = nil
    globals.C_RestrictedActions.GetAddOnRestrictionState = nil
    loadModule("Src/KvLib/KvEnv.lua", globals)

    globals.C_Container = { GetContainerItemCooldown = function() return secret, secret, 1 end }
    loadModule("Src/KvLib/KvEnv.lua", globals)
    equal(env.GetContainerItemCooldown(0, 1), nil, "secret item cooldown")
    globals.C_Container.GetContainerItemCooldown = function() return 5, 10, 1 end
    loadModule("Src/KvLib/KvEnv.lua", globals)
    local cdStart, cdDuration = env.GetContainerItemCooldown(0, 1)
    equal(cdStart, 5); equal(cdDuration, 10)
    globals.C_Container = nil
    loadModule("Src/KvLib/KvEnv.lua", globals)
  end

  -- Forever returns a secret boolean for "targettarget" inside instances.
  local unitIsUnit = globals.UnitIsUnit
  globals.UnitIsUnit = function() return secret end
  loadModule("Src/KvLib/KvEnv.lua", globals)
  equal(env.UnitIsUnit("targettarget", "player"), false, "secret unit identity")
  equal(env.UnitIsUnit("player", "player"), true, "same token skips the API")
  globals.UnitIsUnit = unitIsUnit
  loadModule("Src/KvLib/KvEnv.lua", globals)
  print("PASS: interface " .. interface .. " detection, enchants, restrictions, power, range and chat")
end

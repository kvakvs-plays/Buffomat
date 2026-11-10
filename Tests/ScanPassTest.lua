-- Run from the repository root: lua Tests/ScanPassTest.lua
-- The whole scan pipeline on a fake client: events -> scheduler -> pass -> readers ->
-- evaluation -> task list -> cast button and macro.
local fixture = dofile("Tests/ScanFixture.lua")
local equal = fixture.equal

local FORTITUDE, PRAYER, MIGHT, GREATER_MIGHT, RESURRECTION, SHARPEN = 1243, 21562, 19740, 25782, 2006, 2828
local STONE_ITEM, SWORD_ITEM = 2862, 900

local CLASSES = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID" }

---A world with every scan module loaded, a stubbed window, and one profile.
local function setup(options)
  local f = fixture.new(options)
  local panel = { messages = {}, clears = 0, visible = true }
  f.panel = panel

  -- Stubs for what is not under test
  setmetatable(f:lib("Buffomat-Languages"), { __call = function(_, key) return key end })
  local const = f:lib("Buffomat-Const")
  const.CLASSES, const.CLASS_ICONS, const.LOADING_SCREEN_TIMEOUT = CLASSES, {}, 2
  const.CLASS_COLOR = setmetatable({}, { __index = function() return { colorStr = "ffffffff" } end })
  const.TASKCOLOR_GRAY, const.TASKCOLOR_RED, const.TASKCOLOR_BLEAK_RED = "777777", "cc4444", "bb5555"
  const.PICTURE_FORMAT, const.MACRO_ICON, const.MACRO_ICON_DISABLED = "<%s>", "icon", "icon"
  f:lib("Buffomat-NgStrings").FormatTexture = function() return "" end
  f:lib("Buffomat-Textures").ICON_PET, f:lib("Buffomat-Textures").ICON_TARGET_ON = "pet", "target"
  f:lib("Buffomat-Macro").IsMacroFrameOpen = function() return false end
  local spellIds = f:lib("Buffomat-SpellIds")
  spellIds.Priest_SpiritTap, spellIds.Paladin_CrusaderAura, spellIds.TravelShapeshiftForms = 15271, 32223, {}

  local profile = { Spell = {}, CancelBuff = {}, CurrentBlessing = {} }
  f.profile = profile
  local buffomat = f:lib("Buffomat-Buffomat")
  buffomat.currentProfile = profile
  buffomat.Color = function(_, _hex, text) return text end
  buffomat.UseProfile = function(self, name) self.currentProfileName = name end
  buffomat.UpdateBuffTabText = function() end
  local profiles = f:lib("Buffomat-Profile")
  profiles.ChooseProfile = function() return "solo" end
  profiles.GetProfileBuff = function(_, buffId) return profile.Spell[buffId] end

  function panel:WindowCommand() end
  function panel:IsWindowVisible() return self.visible end
  function panel:AutoShow() self.autoShown = true end
  function panel:AutoHide() self.autoHidden = true end
  function panel:Clear() self.messages = {}; self.clears = self.clears + 1 end
  function panel:AddMessage(text) table.insert(self.messages, text) end
  function panel:CastButtonText(text, enabled) self.buttonText, self.buttonEnabled = text, enabled end
  function panel:IsShowing(text) return self.shownText == text end
  function panel:SetShowing(text) self.shownText = text end
  for key, value in pairs(panel) do f:lib("Buffomat-TaskListPanel")[key] = value end
  panel = f:lib("Buffomat-TaskListPanel")
  f.panel = panel

  local addon = f.globals.BuffomatAddon
  addon.theMacro = {
    lines = {},
    Clear = function(self) self.lines = {}; f.state.macro = "" end,
    EnsureExists = function() return true end,
    UpdateMacro = function(self) f.state.macro = table.concat(self.lines, "\n") end,
  }
  addon.itemList, addon.cancelBuffs = {}, {}
  addon.reputationTrinketZones = { itemIds = {}, zoneId = {} }
  addon.ridingSpeedZones = { itemIds = {}, zoneId = {} }
  addon.GetItemInfo = function(itemId)
    return { itemClassID = 2, itemSubClassID = 7, itemMinLevel = 1, itemLink = "item:" .. itemId }
  end
  f.globals.BuffomatShared = {
    Duration = {}, InWorld = true, InInstance = true, InPVP = true, ScanInRestArea = true, ScanWhileMounted = true,
    ScanInStealth = true, MinBuff = 3, MinBlessing = 3, DeathBlock = true, SameZone = false,
    TargetTooLowLevel = {},
  }

  local allBuffs = f:lib("Buffomat-AllBuffs")
  allBuffs.selectedBuffs, allBuffs.selectedBuffsSpellIds, allBuffs.allBuffs = {}, {}, {}
  allBuffs.allSpellIdSet, allBuffs.spellIdIsSingleLookup, allBuffs.buffFromSpellIdLookup = {}, {}, {}
  allBuffs.drinkSpellIdSet, allBuffs.ignoreAllSpellIdSet, allBuffs.enchantToSpellLookup = {}, {}, {}
  allBuffs.itemListSpellLookup, allBuffs.cancelForm, allBuffs.setupVersion = {}, {}, 1
  allBuffs.RESURRECT_CLASSES = { "PRIEST", "PALADIN", "SHAMAN", "DRUID" }
  allBuffs.MINUTE, allBuffs.FIVE_MINUTES, allBuffs.TEN_MINUTES, allBuffs.HALF_AN_HOUR = 60, 300, 600, 1800
  allBuffs.NewSpellLimitations = function() return {} end

  for _, path in ipairs({
    "Src/KvLib/KvEnv.lua", "Src/KvLib/KvUnit.lua", "Src/KvLib/KvPlayer.lua", "Src/KvLib/KvEvents.lua",
    "Src/Const/ItemIds.lua", "Src/Core/Buff.lua", "Src/Core/Unit.lua", "Src/Core/BuffDefinition.lua",
    "Src/Core/UnitBuffTarget.lua", "Src/Core/GroupBuffTarget.lua",
    "Src/Task/Task.lua", "Src/Task/TaskList.lua", "Src/Task/ActionCast.lua", "Src/Task/ActionUse.lua",
    "Src/Task/ActionMacro.lua", "Src/Task/TaskBuilder.lua", "Src/BuffChecks.lua",
    "Src/Scan/ScanStats.lua", "Src/Scan/ScanScheduler.lua", "Src/Scan/ScanEvents.lua", "Src/Scan/BagScan.lua",
    "Src/Scan/RosterScan.lua", "Src/Scan/AuraScan.lua", "Src/Scan/PlayerStateScan.lua", "Src/Scan/RangeScan.lua",
    "Src/Scan/ScanResult.lua", "Src/Scan/ScanEvaluate.lua", "Src/Scan/ScanEffects.lua", "Src/Scan/ScanPass.lua",
  }) do
    f:load(path)
  end
  f.globals.BuffomatShared.DebugLogging = true

  ---Register a buff the player can cast, enabled in the profile for every class.
  function f:buff(fields)
    local buffDef = f:lib("Buffomat-BuffDefinition"):New(fields.id)
    for key, value in pairs(fields) do buffDef[key] = value end
    buffDef.highestRankSingleId = fields.id
    buffDef.singleText, buffDef.singleLink = fields.name, "[" .. fields.name .. "]"
    table.insert(allBuffs.selectedBuffs, buffDef)
    allBuffs.allBuffs[fields.id] = buffDef
    for _, spellId in ipairs(buffDef.singleFamily) do
      allBuffs.selectedBuffsSpellIds[spellId], allBuffs.allSpellIdSet[spellId] = buffDef, true
      allBuffs.spellIdIsSingleLookup[spellId], allBuffs.buffFromSpellIdLookup[spellId] = true, buffDef
      f.state.knownSpells[spellId] = true
    end
    for _, spellId in ipairs(buffDef.groupFamily or {}) do
      allBuffs.selectedBuffsSpellIds[spellId], allBuffs.allSpellIdSet[spellId] = buffDef, true
      allBuffs.buffFromSpellIdLookup[spellId] = buffDef
      f.state.knownSpells[spellId] = true
    end
    local choice = { Enable = true, Class = {}, ForcedTarget = {}, ExcludedTarget = {}, SelfCast = false,
      MainHandEnable = true, OffHandEnable = false }
    for _, class in ipairs(CLASSES) do choice.Class[class] = true end
    profile.Spell[fields.id] = choice
    return buffDef
  end

  function f:start()
    f:lib("Buffomat-ScanEvents"):Init()
    f:lib("Buffomat-ScanScheduler"):Start()
    f:advance(2)
  end

  ---@return string[] texts Task lines without the comments
  function f:tasks()
    local list = {}
    for index, task in ipairs(f:lib("Buffomat-ScanPass").tasklist.tasks) do
      list[index] = task:Format()
    end
    return list
  end

  function f:counter(name)
    return f:lib("Buffomat-ScanStats").counters[name] or 0
  end
  return f
end

local function raidOf(f, size, class)
  local members = { { name = "Tester", class = f.units.player.class, subgroup = 1, isPlayer = true } }
  for index = 2, size do
    members[index] = { name = "Member" .. index, class = class or "WARRIOR", subgroup = math.ceil(index / 5) }
  end
  f:raid(members)
end

local function count(texts, pattern)
  local found = 0
  for _, text in ipairs(texts) do
    if text:find(pattern, 1, true) then found = found + 1 end
  end
  return found
end

-- A priest in a 40-man raid on a client where a group buff covers one subgroup
do
  local f = setup({ class = "PRIEST" })
  local fortitude = f:buff({ id = FORTITUDE, name = "Fortitude", singleMana = 100, groupMana = 500,
    groupFamily = { PRAYER }, highestRankGroupId = PRAYER, groupText = "Prayer", groupLink = "[Prayer]" })
  raidOf(f, 40)
  local pass, scheduler = f:lib("Buffomat-ScanPass"), f:lib("Buffomat-ScanScheduler")
  -- Waiting tasks check the range every second; keep that out of the way until it is tested
  local rangeTick = scheduler.RANGE_TICK
  scheduler.RANGE_TICK = 100000
  f:start()

  -- Nobody is buffed: one group buff task per subgroup, after the whole raid was read
  equal(f:counter("auraUnits"), 40); equal(f:counter("evaluations"), 1, "one evaluation, after the last read")
  local need = pass.result.needs[FORTITUDE]
  equal(#need.units, 40)
  for group = 1, 8 do equal(need.groups[group], 5, "group " .. group) end
  local tasks = f:tasks()
  equal(#tasks, 8); equal(count(tasks, "[Prayer]"), 8); equal(count(tasks, "task.type.GroupBuff"), 8)
  equal(f.panel.buttonEnabled, true); equal(f.panel.buttonText:find("[Prayer]", 1, true) ~= nil, true)
  equal(f.state.macro:find("/cast [@", 1, true) ~= nil, true)
  equal(f.state.macro:find("Spell" .. PRAYER, 1, true) ~= nil, true)
  equal(#f.panel.messages, 8)
  equal(next(fortitude.skipList), nil); equal(fortitude.unitsNeedBuff, nil, "the definition holds no scan results")

  -- Group 2 gets the prayer: five aura events, one pass, five units read, one task less
  local auraUnits, evaluations = f:counter("auraUnits"), f:counter("evaluations")
  for index = 6, 10 do
    f:aura("raid" .. index, PRAYER, { name = "Prayer", duration = 3600, expirationTime = f.state.now + 3600 })
    f:fire("UNIT_AURA", "raid" .. index)
  end
  f:advance(0.5)
  equal(f:counter("auraUnits") - auraUnits, 5, "only the units with an event are read")
  equal(f:counter("evaluations") - evaluations, 1)
  equal(#f:tasks(), 7); equal(pass.result.needs[FORTITUDE].groups[2], nil)

  -- An event which changes nothing: read, but not evaluated or drawn again
  local clears = f.panel.clears
  evaluations = f:counter("evaluations")
  f:fire("UNIT_AURA", "raid7")
  f:advance(0.5)
  equal(f:counter("evaluations"), evaluations, "the same auras again are not evaluated")
  equal(f.panel.clears, clears)

  -- A settings change is evaluated even when it has to wait for a re-read of the whole raid
  evaluations = f:counter("evaluations")
  scheduler:Request("test")
  scheduler:MarkDirty("auras")
  f:advance(1)
  equal(f:counter("evaluations"), evaluations + 1, "the request survives the continuation passes")

  -- The other groups get the prayer too; a ready check re-reads everybody
  for index = 1, 40 do
    local unitId = index == 1 and "player" or ("raid" .. index)
    if (index <= 5 or index > 15) then
      f:aura(unitId, PRAYER, { name = "Prayer", duration = 3600, expirationTime = f.state.now + 3600 })
    end
  end
  f:fire("READY_CHECK")
  f:advance(1)
  tasks = f:tasks()
  equal(#tasks, 1, "only group 3 is left"); equal(count(tasks, "[Prayer]"), 1)

  -- Too few missing for a group buff: single buffs for those members
  for index = 11, 13 do
    f:aura("raid" .. index, FORTITUDE, { name = "Fortitude" })
    f:fire("UNIT_AURA", "raid" .. index)
  end
  f:advance(0.5)
  tasks = f:tasks()
  equal(#tasks, 2, "two single buffs"); equal(count(tasks, "[Fortitude]"), 2)
  equal(count(tasks, "task.type.RegularBuff"), 2)

  -- A buff close to its end wakes the scheduler without any event
  f:aura("raid14", FORTITUDE, { name = "Fortitude", duration = 1800, expirationTime = f.state.now + 200 })
  f:aura("raid15", FORTITUDE, { name = "Fortitude" })
  f:fire("UNIT_AURA", "raid14"); f:fire("UNIT_AURA", "raid15")
  f:advance(0.5)
  equal(#f:tasks(), 0, "everybody is buffed"); equal(f.panel.buttonText, "castButton.NothingToDo")
  equal(f.panel.buttonEnabled, false)
  f:advance(25)
  equal(count(f:tasks(), "[Fortitude]"), 1, "the buff with 175 seconds left is offered again")
  equal(f.panel.buttonEnabled, true)

  -- Not enough mana: nothing castable, and the mana event that makes it affordable is awaited
  local events = f:lib("Buffomat-ScanEvents")
  equal(events.dispatcher:IsRegistered("UNIT_POWER_UPDATE"), false)
  f.state.mana = 50
  f:fire("UNIT_SPELLCAST_SUCCEEDED", "player")
  f:advance(0.5)
  equal(f.panel.buttonEnabled, false); equal(f.panel.buttonText, "castButton.NothingToDo")
  equal(events.dispatcher:IsRegistered("UNIT_POWER_UPDATE"), true)
  f.state.mana = 90
  f:fire("UNIT_POWER_UPDATE", "player", "MANA")
  f:advance(0.5)
  equal(f.panel.buttonEnabled, false, "still below the cheapest spell")
  f.state.mana = 600
  f:fire("UNIT_POWER_UPDATE", "player", "MANA")
  f:advance(0.5)
  equal(f.panel.buttonEnabled, true)
  equal(events.dispatcher:IsRegistered("UNIT_POWER_UPDATE"), false, "nothing waits for mana any more")

  -- Mana which came back unseen: an evaluation for another reason reads it again
  f.state.mana = 50
  f:fire("UNIT_SPELLCAST_SUCCEEDED", "player")
  f:advance(0.5)
  equal(f.panel.buttonEnabled, false)
  f.state.mana = 1000
  scheduler:Request("test")
  f:advance(0.5)
  equal(f.panel.buttonEnabled, true, "decided with the mana of now, not of the last read")

  -- Out of range: the task stays as information and the range is checked every second
  f:removeAura("raid40", PRAYER)
  f.units.raid40.distance = 2500
  scheduler.RANGE_TICK = rangeTick
  f:fire("UNIT_AURA", "raid40")
  f:advance(0.5)
  tasks = f:tasks()
  equal(#tasks, 2); equal(count(tasks, "task.error.range"), 1, "the far member is shown, not offered")
  evaluations = f:counter("evaluations")
  f:advance(3.05)
  equal(f:counter("evaluations") - evaluations, 3, "one range check a second while a task waits for range")
  f.units.raid40.distance = 100
  f:advance(1.2)
  equal(count(f:tasks(), "task.error.range"), 0, "the member came into range")

  -- Paused: resting with the option off. No tasks are built and the reason is on the button
  f.globals.BuffomatShared.ScanInRestArea = false
  f.state.resting = true
  f:fire("PLAYER_UPDATE_RESTING")
  f:advance(0.5)
  equal(f.panel.buttonText, "castButton.inactive.RestArea"); equal(f.panel.buttonEnabled, false)
  equal(#f:tasks(), 0); equal(f.state.macro, "")
  local passes = f:counter("passes")
  f:advance(120)
  equal(f:counter("passes"), passes, "nothing runs while paused and nothing changes")
  f.state.resting = false
  f:fire("PLAYER_UPDATE_RESTING")
  f:advance(0.5)
  equal(#f:tasks(), 2)

  -- Mounted where flying exists: taking off and landing send no event, so the player is
  -- looked at every two seconds, also while flying pauses everything else
  local env = f.globals.LibStub("KvLibShared-Env")
  env.haveTBC = true
  f.globals.BuffomatShared.ScanWhileMounted = true
  f.state.mounted = true
  f:fire("PLAYER_MOUNT_DISPLAY_CHANGED")
  f:advance(0.5)
  equal(f.panel.buttonEnabled, true, "mounted on the ground")
  f.state.flying = true
  f:advance(2.5)
  equal(f.panel.buttonText, "castButton.inactive.Flying"); equal(f.panel.buttonEnabled, false)
  f.state.flying = false
  f:advance(2.5)
  equal(f.panel.buttonEnabled, true, "landed")
  f.state.mounted = false
  f:fire("PLAYER_MOUNT_DISPLAY_CHANGED")
  f:advance(3)
  equal(scheduler.wakeTimes.player, nil, "nobody is watched on foot")
  env.haveTBC = false

  -- A dead member: a resurrection task, and their status is watched without events
  f:buff({ id = RESURRECTION, name = "Resurrection", singleMana = 100, type = "resurrection" })
  f.units.raid14.dead = true
  f:fire("UNIT_AURA", "raid14") -- a death removes the auras
  f:advance(0.5)
  tasks = f:tasks()
  equal(count(tasks, "[Resurrection]"), 1); equal(count(tasks, "task.type.Resurrect"), 1)
  equal(count(tasks, "[Fortitude]"), 1, "no buff for the dead")
  f.units.raid14.dead = false -- resurrected by somebody else: no event at all
  f:advance(2.5)
  equal(count(f:tasks(), "[Resurrection]"), 0, "the dead watch noticed")
  equal(count(f:tasks(), "[Fortitude]"), 2)

  -- Combat: nothing runs; afterwards everything is read once
  f.state.inCombat = true
  f:fire("PLAYER_REGEN_DISABLED")
  passes = f:counter("passes")
  f:advance(60)
  equal(f:counter("passes"), passes)
  equal(f:pendingTimers(), 0, "no timer in combat")
  f.state.inCombat = false
  auraUnits = f:counter("auraUnits")
  f:fire("PLAYER_REGEN_ENABLED")
  f:advance(1)
  equal(f:counter("auraUnits") - auraUnits, 40)
  equal(scheduler.loading, false)
  print("PASS: priest in a 40-man raid: group and single buffs, deadlines, mana, range, pause, death, combat")
end

-- A paladin: a blessing covers a class
do
  local f = setup({ class = "PALADIN" })
  f:buff({ id = MIGHT, name = "Might", singleMana = 50, groupMana = 300, isBlessing = true,
    groupFamily = { GREATER_MIGHT }, highestRankGroupId = GREATER_MIGHT, groupText = "Greater Might",
    groupLink = "[Greater Might]" })
  f:raid({
    { name = "Tester", class = "PALADIN", subgroup = 1, isPlayer = true },
    { name = "War1", class = "WARRIOR", subgroup = 1 }, { name = "War2", class = "WARRIOR", subgroup = 2 },
    { name = "War3", class = "WARRIOR", subgroup = 3 }, { name = "Rogue1", class = "ROGUE", subgroup = 1 },
  })
  f:start()
  local need = f:lib("Buffomat-ScanPass").result.needs[MIGHT]
  equal(need.groups.WARRIOR, 3); equal(need.groups.ROGUE, 1); equal(need.groups.PALADIN, 1)
  local tasks = f:tasks()
  equal(count(tasks, "[Greater Might]"), 1, "three warriors get the class blessing")
  equal(count(tasks, "TASK_BLESS_GROUP"), 1)
  equal(count(tasks, "[Might]"), 2, "the rogue and the paladin get single blessings")
  equal(f.state.macro:find("/cast [@", 1, true) ~= nil, true, "one of the blessings is on the macro")

  -- A dead warrior blocks the class blessing, which would miss them
  f.units.raid3.dead = true
  f:fire("UNIT_AURA", "raid3")
  f:advance(0.5)
  tasks = f:tasks()
  equal(count(tasks, "[Greater Might]"), 1)
  local bless
  for _, task in ipairs(f:lib("Buffomat-ScanPass").tasklist.tasks) do
    if task.actionLink == "[Greater Might]" then bless = task end
  end
  equal(bless.isInfo, true, "shown, but not offered while a warrior is dead")
  print("PASS: paladin class blessings")
end

-- A warrior alone with a sharpening stone
do
  local f = setup({ class = "WARRIOR" })
  f:buff({ id = SHARPEN, name = "Sharpening Stone", type = "weapon", isConsumable = true, items = { STONE_ITEM } })
  f.state.inventory = { [16] = SWORD_ITEM }
  f:item(2, 5, STONE_ITEM, 3)
  f:start()
  local tasks = f:tasks()
  equal(#tasks, 1); equal(tasks[1]:find("item:" .. STONE_ITEM, 1, true) ~= nil, true)
  equal(tasks[1]:find("tooltip.mainhand", 1, true) ~= nil, true)
  equal(f.state.macro, "/use 2 5\n/use 16")
  equal(f:counter("auraUnits"), 1, "alone, only the player is read")

  -- The stone was used: the enchant appears and the task goes
  f.state.weapon.main = { timeLeft = 1800000, enchantId = 13 }
  f:lib("Buffomat-AllBuffs").enchantToSpellLookup[13] = SHARPEN
  f:item(2, 5, STONE_ITEM, 2)
  f:fire("UNIT_INVENTORY_CHANGED", "player")
  f:fire("BAG_UPDATE_DELAYED")
  f:advance(0.5)
  equal(#f:tasks(), 0); equal(f.panel.buttonText, "castButton.NothingToDo")

  -- The enchant runs out without an event: the scheduler looks again at its end
  f.state.weapon.main = false
  f:advance(1801)
  equal(#f:tasks(), 1, "the end of the enchant was noticed by the deadline")

  -- No stones left: the task stays as information
  f:item(2, 5, nil)
  f:fire("BAG_UPDATE_DELAYED")
  f:advance(0.5)
  tasks = f:tasks()
  equal(#tasks, 1); equal(tasks[1]:find("task.type.MissingConsumable", 1, true) ~= nil, true)
  equal(f.panel.buttonEnabled, false)
  print("PASS: solo warrior with a weapon stone")
end

-- Restrictions on a modern client
do
  local f = setup({ modern = true, forever = true, class = "PRIEST" })
  f:buff({ id = FORTITUDE, name = "Fortitude", singleMana = 100 })
  f:buff({ id = SHARPEN, name = "Sharpening Stone", type = "weapon", isConsumable = true, items = { STONE_ITEM } })
  f.state.inventory = { [16] = SWORD_ITEM }
  f:item(0, 1, STONE_ITEM, 1)
  f.state.inGroup = true
  f:unit("party1", { name = "Mage", class = "MAGE" })
  f:start()
  equal(#f:tasks(), 3, "fortitude for two and the stone")

  -- An encounter hides too much: nothing is decided, and nothing retries by itself
  f.state.restrictions[1] = true
  f:fire("ADDON_RESTRICTION_STATE_CHANGED")
  f:resetCalls()
  f:advance(1)
  equal(f.panel.buttonText, "castButton.inactive.AuraDataUnavailable"); equal(f.panel.buttonEnabled, false)
  equal(f:calls("aura"), 0, "no aura is read under a restriction")
  equal(f:pendingTimers(), 0)

  -- A PvP match: only what can be decided without auras, from the player alone
  f.state.restrictions[1], f.state.restrictions[3] = nil, true
  f:fire("ADDON_RESTRICTION_STATE_CHANGED")
  f:resetCalls()
  f:advance(1)
  local tasks = f:tasks()
  equal(#tasks, 1); equal(tasks[1]:find("item:" .. STONE_ITEM, 1, true) ~= nil, true)
  equal(f:calls("aura"), 0)
  equal(#f:lib("Buffomat-RosterScan").roster.units, 1, "the roster is the player only")
  equal(f.printed[#f.printed], "message.PvPMatchAuraFree")

  -- The match ends: everything is read and decided again
  f.state.restrictions[3] = nil
  f:fire("ADDON_RESTRICTION_STATE_CHANGED")
  f:advance(1)
  equal(#f:tasks(), 3)

  -- A member whose auras the client hides blocks decisions about the whole group
  f.units.party1.secretAuras = true
  f:fire("UNIT_AURA", "party1")
  f:advance(0.5)
  equal(f.panel.buttonText, "castButton.inactive.AuraDataUnavailable")
  f.units.party1.secretAuras = nil
  f:fire("UNIT_AURA", "party1")
  f:advance(0.5)
  equal(#f:tasks(), 3)
  print("PASS: restrictions, aura-free mode and unreadable members")
end

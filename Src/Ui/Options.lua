---@class OptionsModule
local module = LibStub("Buffomat-Options") --[[@as OptionsModule]]

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local languagesModule = _t
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local eventsModule = LibStub("Buffomat-Events") --[[@as EventsModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]
local kvOptionsModule = LibStub("KvLibShared-Options") --[[@as KvOptionsModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local scanSchedulerModule = LibStub("Buffomat-ScanScheduler") --[[@as ScanSchedulerModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local libIcon = LibStub("LibDBIcon-1.0")

---@param dict table|nil
---@param key string|nil
---@param notify function|nil Call this with (key, value) on option change
function module:TemplateCheckbox(name, dict, key, notify)
  return kvOptionsModule:TemplateCheckbox(name, dict or BuffomatShared, key or name, notify, _t)
end

---@param name string
---@param onClick function Call this when button is pressed
function module:TemplateButton(name, onClick)
  return kvOptionsModule:TemplateButton(name, onClick, _t)
end

---@param values table|function Key is sent to the setter, value is the string displayed
---@param dict table|nil
---@param notifyFn function|nil Call this with (key, value) on option change
function module:TemplateMultiselect(name, values, dict, notifyFn, setFn, getFn)
  return kvOptionsModule:TemplateMultiselect(name, values, dict or BuffomatShared, notifyFn, setFn, getFn, _t)
end

---@param values table|function Key is sent to the setter, value is the string displayed
---@param dict table|nil
---@param style string|nil "dropdown" or "radio"
---@param notifyFn function|nil Call this with (key, value) on option change
function module:TemplateSelect(name, values, style, dict, notifyFn, setFn, getFn)
  return kvOptionsModule:TemplateSelect(name, values, style, dict or BuffomatShared, notifyFn, setFn, getFn, _t)
end

---@param dict table|nil
---@param key string|nil
---@param notify function|nil Call this with (key, value) on option change
function module:TemplateInput(type, name, dict, key, notify)
  return kvOptionsModule:TemplateInput(type, name, dict or BuffomatShared, key or name, notify, _t)
end

---@param dict table|nil
---@param key string|nil
---@param notify function|nil Call this with (key, value) on option change
function module:TemplateRange(name, rangeFrom, rangeTo, step, dict, key, notify)
  return kvOptionsModule:TemplateRange(name, rangeFrom, rangeTo, step, dict or BuffomatShared, key or name, notify,
    _t)
end

function module:CreateGeneralOptionsTable()
  local sounds = --[[@as {[string]: string} ]] {}
  sounds[_t("task.notifications.no-sound")] = "-"

  ---@diagnostic disable-next-line: unused-local
  for _, sound in ipairs(constModule.TASK_NOTIFICATION_SOUNDS) do
    sounds[sound .. ".mp3"] = sound
  end

  return {
    type = "group",
    name = "01. " .. _t("options.general.group.General"),
    args = {
      language = self:CreateLanguageOption(),
      autoOpen = self:TemplateCheckbox("AutoOpen", nil, nil, nil),
      autoClose = self:TemplateCheckbox("AutoClose", nil, nil, nil),
      hideWhenScanBlocked = self:TemplateCheckbox("HideWhenScanBlocked", nil, nil, nil),
      fadeWhenNothingToDo = self:TemplateRange(
        "FadeWhenNothingToDo", 0.1, 1.0, 0.05,
        BuffomatShared, "FadeWhenNothingToDo",
        ---@diagnostic disable-next-line: unused-local
        function(_key, val)
          taskListPanelModule:SetAlpha(val)
        end
      ),
      useProfiles = self:TemplateCheckbox("UseProfiles", BuffomatCharacter, nil, nil),
      slowerHardware = self:TemplateCheckbox("SlowerHardware", BuffomatShared, nil, nil),
      minimapButtonShow = {
        type = "toggle",
        name = _t("options.short.ShowMinimapButton"),
        order = self:NextOptionsOrder(),
        get = function(info)
          return not BuffomatShared.Minimap.hide
        end,
        set = function(info, value)
          -- value is true if checkbox is checked (user wants to show button)
          -- value is false if checkbox is unchecked (user wants to hide button)
          BuffomatShared.Minimap.hide = not value

          -- Now update the icon visibility based on the new 'hide' state
          if BuffomatShared.Minimap.hide then
            libIcon:Hide("BuffomatIcon")
          else
            libIcon:Show("BuffomatIcon")
          end
        end,
      },
      uiWindowScale = self:TemplateRange(
        "UIWindowScale", 0.35, 2.0, 0.05,
        BuffomatShared, "UIWindowScale",
        ---@diagnostic disable-next-line: unused-local
        function(_key, val)
          taskListPanelModule:SetWindowScale(val)
        end
      ),
      -- Play from Interface/Addons/Buffomat/Sounds/...
      playSoundWhenTask = self:TemplateSelect("PlaySoundWhenTask", sounds, "dropdown",
        nil, nil, nil, nil),
      soundTest = self:TemplateButton("PlaySoundWhenTask.test", function()
        taskScanModule:PlayTaskSound()
      end),
      debugLogging = self:TemplateCheckbox("DebugLogging", nil, nil, nil),
    }
  }
end

function module:NextOptionsOrder()
  kvOptionsModule.optionsOrder = kvOptionsModule.optionsOrder + 1
  return kvOptionsModule.optionsOrder
end

function module:CreateLanguageOption()
  return {
    desc = _t("options.long.Language"),
    name = _t("options.short.Language"),
    order = self:NextOptionsOrder(),
    sorting = languagesModule.languageOptionsOrder,
    style = "dropdown",
    type = "select",
    values = languagesModule.languageOptions,
    width = 2.0,

    set = function(info, value)
      BuffomatShared.Language = languagesModule:NormalizeLanguageSetting(value)
    end,
    get = function(info)
      return languagesModule:NormalizeLanguageSetting(BuffomatShared.Language)
    end,
  }
end

---A checkbox shown only on WoW: Forever; its label has the "[Forever]" prefix in the translations.
---Changing it rescans, so a reminder task appears or goes away at once.
---@param name string BomSharedSettings field
function module:TemplateForeverCheckbox(name)
  local checkbox = self:TemplateCheckbox(name, nil, nil, function()
    scanSchedulerModule:Request("options:" .. name)
  end)
  checkbox.hidden = function() return not envModule.isForever end
  return checkbox
end

function module:CreateScanOptionsTable()
  return {
    type = "group",
    name = "02. " .. _t("options.general.group.Scan"),
    args = {
      scanInRestArea = self:TemplateCheckbox("ScanInRestArea", nil, nil, nil),
      scanInStealth = self:TemplateCheckbox("ScanInStealth", nil, nil, nil),
      scanWhileMounted = self:TemplateCheckbox("ScanWhileMounted", nil, nil, nil),
      inWorld = self:TemplateCheckbox("InWorld", nil, nil, nil),
      inPVP = self:TemplateCheckbox("InPVP", nil, nil, nil),
      inInstance = self:TemplateCheckbox("InInstance", nil, nil, nil),
      sameZone = self:TemplateCheckbox("SameZone", nil, nil, nil),
      bestAvailableConsume = self:TemplateCheckbox("BestAvailableConsume", nil, nil, nil),
      foreverCampReminder = self:TemplateForeverCheckbox("ForeverCampReminder"),
      foreverXpReminder = self:TemplateForeverCheckbox("ForeverXpReminder"),
    }
  }
end

function module:CreateAutoActionOptionsTable()
  return {
    type = "group",
    name = "03. " .. _t("options.general.group.AutoActions"),
    args = {
      autoCrusaderAura = self:TemplateCheckbox("AutoCrusaderAura", nil, nil, nil),
      autoDismount = self:TemplateCheckbox("AutoDismount", nil, nil, nil),
      autoDismountFlying = self:TemplateCheckbox("AutoDismountFlying", nil, nil, nil),
      autoStand = self:TemplateCheckbox("AutoStand", nil, nil, nil),
      autoDisTravel = self:TemplateCheckbox("AutoDisTravel", nil, nil, nil),
    }
  }
end

function module:CreateConvenienceOptionsTable()
  return {
    type = "group",
    name = "04. " .. _t("options.general.group.Convenience"),
    args = {
      preventPVPTag = self:TemplateCheckbox("PreventPVPTag", nil, nil, nil),
      deathBlock = self:TemplateCheckbox("DeathBlock", nil, nil, nil),
      noGroupBuff = self:TemplateCheckbox("NoGroupBuff", nil, nil, nil),
      resGhost = self:TemplateCheckbox("ResGhost", nil, nil, nil),
      replaceSingle = self:TemplateCheckbox("ReplaceSingle", nil, nil, nil),
      argentumDawn = self:TemplateCheckbox("ReputationTrinket", nil, nil, nil),
      carrot = self:TemplateCheckbox("Carrot", nil, nil, nil),
      mainHand = self:TemplateCheckbox("MainHand", nil, nil, nil),
      secondaryHand = self:TemplateCheckbox("SecondaryHand", nil, nil, nil),
      useRank = self:TemplateCheckbox("UseRank", nil, nil, nil),
      buffTarget = self:TemplateCheckbox("BuffTarget", nil, nil, nil),
      openLootable = self:TemplateCheckbox("OpenLootable", nil, nil, nil),
      selfFirst = self:TemplateCheckbox("SelfFirst", nil, nil, nil),
      dontUseConsumables = self:TemplateCheckbox("DontUseConsumables", nil, nil, nil),
      showCustomBuffSorting = self:TemplateCheckbox("CustomBuffSorting", nil, nil,
        function()
          eventsModule.Event_SpellsChanged()
        end),
      someoneIsDrinking = self:TemplateSelect("SomeoneIsDrinking", {
        ["hide"] = _t("options.convenience.SomeoneIsDrinking.Hide"),
        ["low-prio"] = _t("options.convenience.SomeoneIsDrinking.LowPrio"),
        ["show"] = _t("options.convenience.SomeoneIsDrinking.Show"),
      }, "dropdown", nil, nil, nil, nil),
      activateBomOnSpiritTap = self:TemplateRange("ActivateBomOnSpiritTap", 0, 100, 10, nil, nil, nil),
    },
  }
end

function module:CreateBuffingOptionsTable()
  return {
    type = "group",
    name = "05. " .. _t("options.general.group.Buffing"),
    args = {
      minBuff = self:TemplateRange("MinBuff", 1, 5, 1, nil, nil, nil),
      minBlessing = self:TemplateRange("MinBlessing", 1, 40, 1, nil, nil, nil),
      rebuffTime60 = self:TemplateRange("Time60", 10, 50, 5, nil, nil, nil),
      rebuffTime300 = self:TemplateRange("Time300", 30, 300 - 60, 10, nil, nil, nil),
      rebuffTime600 = self:TemplateRange("Time600", 30, 600 - 120, 10, nil, nil, nil),
      rebuffTime1800 = self:TemplateRange("Time1800", 30, 600 - 30, 30, nil, nil, nil),
      rebuffTime3600 = self:TemplateRange("Time3600", 30, 600 - 30, 30, nil, nil, nil),
    } -- end args
  }
end

function module:CreateVisibilityOptionsTable()
  return {
    type = "group",
    name = "06. " .. _t("options.general.group.Visibility"),
    args = {
      categories = self:TemplateMultiselect(
        "VisibleCategories",
        allBuffsModule:GetBuffCategories(),     -- all categories ordered
        BuffomatCharacter.BuffCategoriesHidden, -- settings table
        nil,
        ---@diagnostic disable-next-line: unused-local
        function(_state, key, value)
          BuffomatCharacter.BuffCategoriesHidden[ --[[@as string]] key ] = not value -- invert
          eventsModule.Event_SpellsChanged()
        end,
        ---@diagnostic disable-next-line: unused-local
        function(_state, key)
          return BuffomatCharacter.BuffCategoriesHidden[ --[[@as string]] key ] ~= true -- invert
        end
      ),
    } -- end args
  }
end

function module:CreateClassOptionsTable()
  return {
    type = "group",
    name = "09. " .. _t("options.general.group.Class"),
    args = {
      shamanFlametongueRanked = self:TemplateCheckbox("ShamanFlametongueRanked", nil, nil, nil),
    } -- end args
  }
end

local FOREVERDB_URL = "https://foreverdb.net"

---About page: what Buffomat does, how to use it, and credits. ForeverDB asks for a visible link
---wherever its data is used; the game cannot open links, so the URL is in a box to copy from.
---@return table AceConfig group
function module:CreateAboutOptionsTable()
  return {
    type = "group",
    name = "10. " .. _t("PanelAbout"),
    args = {
      version = {
        type = "description", order = 1, fontSize = "medium",
        name = constModule.SHORT_TITLE .. " " .. tostring(constModule.TOC_VERSION or ""),
      },
      infoHeader = { type = "header", order = 2, name = _t("HeaderInfo") },
      info = { type = "description", order = 3, name = _t("AboutInfo") },
      usageHeader = { type = "header", order = 4, name = _t("HeaderUsage") },
      usage = { type = "description", order = 5, name = _t("AboutUsage") },
      creditsHeader = { type = "header", order = 6, name = _t("HeaderCredits") },
      credits = { type = "description", order = 7, name = _t("AboutCredits") },
      foreverDbLink = {
        type = "input", order = 8, width = "double",
        name = "Data from ForeverDB.net",
        get = function() return FOREVERDB_URL end,
        set = function() end, -- read-only: shown so the link can be selected and copied
      },
    },
  }
end

function module:CreateOptionsTable()
  kvOptionsModule.optionsOrder = 0

  return {
    type = "group",
    args = {
      generalOptions = self:CreateGeneralOptionsTable(),
      scanOptions = self:CreateScanOptionsTable(),
      autoActionOptions = self:CreateAutoActionOptionsTable(),
      convenienceOptions = self:CreateConvenienceOptionsTable(),
      buffingOptions = self:CreateBuffingOptionsTable(),
      visibilityOptions = self:CreateVisibilityOptionsTable(),
      classOptions = self:CreateClassOptionsTable(),
      aboutOptions = self:CreateAboutOptionsTable(),
    } -- end args
  }   -- end
end

---Called from options' Default button
function module:ResetDefaultOptions()
end

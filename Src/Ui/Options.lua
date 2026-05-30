---@class OptionsModule

local optionsModule = LibStub("Buffomat-Options") --[[@as OptionsModule]]
local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local languagesModule = _t
local allBuffsModule = LibStub("Buffomat-AllBuffs") --[[@as AllBuffsModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local eventsModule = LibStub("Buffomat-Events") --[[@as EventsModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]
local kvOptionsModule = LibStub("KvLibShared-Options") --[[@as KvOptionsModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]
local libIcon = LibStub("LibDBIcon-1.0")

---@param dict table|nil
---@param key string|nil
---@param notify function|nil Call this with (key, value) on option change
function optionsModule:TemplateCheckbox(name, dict, key, notify)
  return kvOptionsModule:TemplateCheckbox(name, dict or BuffomatShared, key or name, notify, _t)
end

---@param name string
---@param onClick function Call this when button is pressed
function optionsModule:TemplateButton(name, onClick)
  return kvOptionsModule:TemplateButton(name, onClick, _t)
end

---@param values table|function Key is sent to the setter, value is the string displayed
---@param dict table|nil
---@param notifyFn function|nil Call this with (key, value) on option change
function optionsModule:TemplateMultiselect(name, values, dict, notifyFn, setFn, getFn)
  return kvOptionsModule:TemplateMultiselect(name, values, dict or BuffomatShared, notifyFn, setFn, getFn, _t)
end

---@param values table|function Key is sent to the setter, value is the string displayed
---@param dict table|nil
---@param style string|nil "dropdown" or "radio"
---@param notifyFn function|nil Call this with (key, value) on option change
function optionsModule:TemplateSelect(name, values, style, dict, notifyFn, setFn, getFn)
  return kvOptionsModule:TemplateSelect(name, values, style, dict or BuffomatShared, notifyFn, setFn, getFn, _t)
end

---@param dict table|nil
---@param key string|nil
---@param notify function|nil Call this with (key, value) on option change
function optionsModule:TemplateInput(type, name, dict, key, notify)
  return kvOptionsModule:TemplateInput(type, name, dict or BuffomatShared, key or name, notify, _t)
end

---@param dict table|nil
---@param key string|nil
---@param notify function|nil Call this with (key, value) on option change
function optionsModule:TemplateRange(name, rangeFrom, rangeTo, step, dict, key, notify)
  return kvOptionsModule:TemplateRange(name, rangeFrom, rangeTo, step, dict or BuffomatShared, key or name, notify,
    _t)
end

function optionsModule:CreateGeneralOptionsTable()
  local sounds = --[[@as {[string]: string} ]] {}
  sounds[_t("task.notifications.no-sound")] = "-"

  ---@diagnostic disable-next-line: unused-local
  for i, sound in ipairs(constModule.TASK_NOTIFICATION_SOUNDS) do
    sounds[sound .. ".mp3"] = sound
  end

  return {
    type = "group",
    name = "1. " .. _t("options.general.group.General"),
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
      slowerHardware = self:TemplateCheckbox("SlowerHardware", BuffomatShared, nil,
        ---@diagnostic disable-next-line: unused-local
        function(key, value)
          buffomatModule:ScheduleUpdateTimer()
        end),
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

function optionsModule:NextOptionsOrder()
  kvOptionsModule.optionsOrder = kvOptionsModule.optionsOrder + 1
  return kvOptionsModule.optionsOrder
end

function optionsModule:CreateLanguageOption()
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

function optionsModule:CreateScanOptionsTable()
  return {
    type = "group",
    name = "2. " .. _t("options.general.group.Scan"),
    args = {
      scanInRestArea = self:TemplateCheckbox("ScanInRestArea", nil, nil, nil),
      scanInStealth = self:TemplateCheckbox("ScanInStealth", nil, nil, nil),
      scanWhileMounted = self:TemplateCheckbox("ScanWhileMounted", nil, nil, nil),
      inWorld = self:TemplateCheckbox("InWorld", nil, nil, nil),
      inPVP = self:TemplateCheckbox("InPVP", nil, nil, nil),
      inInstance = self:TemplateCheckbox("InInstance", nil, nil, nil),
      sameZone = self:TemplateCheckbox("SameZone", nil, nil, nil),
      bestAvailableConsume = self:TemplateCheckbox("BestAvailableConsume", nil, nil, nil),
    }
  }
end

function optionsModule:CreateAutoActionOptionsTable()
  return {
    type = "group",
    name = "3. " .. _t("options.general.group.AutoActions"),
    args = {
      autoCrusaderAura = self:TemplateCheckbox("AutoCrusaderAura", nil, nil, nil),
      autoDismount = self:TemplateCheckbox("AutoDismount", nil, nil, nil),
      autoDismountFlying = self:TemplateCheckbox("AutoDismountFlying", nil, nil, nil),
      autoStand = self:TemplateCheckbox("AutoStand", nil, nil, nil),
      autoDisTravel = self:TemplateCheckbox("AutoDisTravel", nil, nil, nil),
    }
  }
end

function optionsModule:CreateConvenienceOptionsTable()
  return {
    type = "group",
    name = "4. " .. _t("options.general.group.Convenience"),
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

function optionsModule:CreateBuffingOptionsTable()
  return {
    type = "group",
    name = "5. " .. _t("options.general.group.Buffing"),
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

function optionsModule:CreateVisibilityOptionsTable()
  return {
    type = "group",
    name = "6. " .. _t("options.general.group.Visibility"),
    args = {
      categories = self:TemplateMultiselect(
        "VisibleCategories",
        allBuffsModule:GetBuffCategories(),     -- all categories ordered
        BuffomatCharacter.BuffCategoriesHidden, -- settings table
        nil,
        ---@diagnostic disable-next-line: unused-local
        function(state, key, value)
          BuffomatCharacter.BuffCategoriesHidden[ --[[@as string]] key ] = not value -- invert
          eventsModule.Event_SpellsChanged()
        end,
        ---@diagnostic disable-next-line: unused-local
        function(state, key)
          return BuffomatCharacter.BuffCategoriesHidden[ --[[@as string]] key ] ~= true -- invert
        end
      ),
    } -- end args
  }
end

function optionsModule:CreateClassOptionsTable()
  return {
    type = "group",
    name = "9. " .. _t("options.general.group.Class"),
    args = {
      shamanFlametongueRanked = self:TemplateCheckbox("ShamanFlametongueRanked", nil, nil, nil),
    } -- end args
  }
end

function optionsModule:CreateOptionsTable()
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
    } -- end args
  }   -- end
end

---Called from options' Default button
function optionsModule:ResetDefaultOptions()
end

---@class SharedSettingsModule

local sharedSettingsModule = LibStub("Buffomat-SharedSettings") --[[@as SharedSettingsModule]]

--- Values to use when the saved data is evolving with an update, and the key doesn't exist
sharedSettingsModule.defaults = {
  SomeoneIsDrinking = "low-prio",
}

---@class (exact) BomMinimapSettings
---@field visible boolean
---@field lock boolean
---@field lockDistance boolean
---@field position number
---@field distance number

---@class (exact) SharedSettings Current character state snapshots per profile
---@field Cache BomItemCache Caches responses from GetItemInfo() and GetSpellInfo()
---@field X number Window horizontal position
---@field Y number Window vertical position
---@field Width number Window width
---@field Height number Window height
---@field DebugLogging boolean
---@field PlaySoundWhenTask string Play a sound when task list is not empty
---@field Minimap BomMinimapSettings
---@field TargetTooLowLevel table
---@field CustomLocales table
---@field UIWindowScale number
---@field AutoOpen boolean Open the window when a task is available
---@field AutoClose boolean When last task is done, hide the window
---@field HideWhenScanBlocked boolean Hide the window when scanning is blocked by inactive conditions
---@field FadeWhenNothingToDo number Allows Buffomat window to fade when nothing to do
---@field UseProfiles boolean
---@field SlowerHardware boolean
---@field ScanInRestArea boolean
---@field ScanInStealth boolean
---@field ScanWhileMounted boolean
---@field BestAvailableConsume boolean
---@field InWorld boolean
---@field InPVP boolean
---@field InInstance boolean
---@field SameZone boolean
---@field AutoCrusaderAura boolean
---@field AutoDismount boolean
---@field AutoDismountFlying boolean
---@field AutoStand boolean
---@field AutoDisTravel boolean
---@field PreventPVPTag boolean
---@field DeathBlock boolean
---@field NoGroupBuff boolean
---@field ResGhost boolean
---@field ReplaceSingle boolean
---@field ReputationTrinket boolean
---@field Carrot boolean
---@field MainHand boolean
---@field SecondaryHand boolean
---@field UseRank boolean
---@field BuffTarget boolean
---@field OpenLootable boolean
---@field SelfFirst boolean
---@field DontUseConsumables boolean
---@field SomeoneIsDrinking string "low-prio" - Show as a comment; "hide" - no show; "show" - Show as a task and show buffomat window
---@field HideSomeoneIsDrinking nil
---@field ActivateBomOnSpiritTap number Percent mana to deactivate Buffomat if Spirit Tap is active for a priest
---@field MinBuff number How many missing buffs to prefer group buff
---@field MinBlessing number
---@field Time60 number
---@field Time300 number
---@field Time600 number
---@field Time1800 number
---@field Time3600 number
---@field Duration BomSpellDurationsTable Copy from character settings
---@field ShamanFlametongueRanked boolean Try and use rank 9 on mainhand for shaman when buffing double Flametongue
---@field CustomBuffSorting boolean Each buff row will also have a text field with sorting order

local sharedStateClass = {}
sharedStateClass.__index = sharedStateClass

---@param init SharedSettings
---@return SharedSettings
function sharedSettingsModule:NewDefaultSharedSettings(init)
  local tab = init or self:Defaults()
  tab.Minimap = tab.Minimap or {}
  tab.TargetTooLowLevel = tab.TargetTooLowLevel or {}
  tab.CustomLocales = tab.CustomLocales or {}

  -- Upgrades from older versions (SomeoneIsDrinking was renamed from HideSomeoneIsDrinking)
  tab.HideSomeoneIsDrinking = nil -- delete old key
  tab.SomeoneIsDrinking = tab.SomeoneIsDrinking or self.defaults.SomeoneIsDrinking
  tab.HideWhenScanBlocked = tab.HideWhenScanBlocked == true

  --setmetatable(tab, sharedStateClass)
  return tab
end

---@return SharedSettings
function sharedSettingsModule:Defaults()
  ---@type SharedSettings
  return {
    Duration = {},
    Width = 300,
    Height = 200,
    X = nil,
    Y = nil,

    UIWindowScale = 1,
    AutoOpen = true,
    HideWhenScanBlocked = false,
    FadeWhenNothingToDo = 1.0,
    UseProfiles = false,
    SlowerHardware = false,
    ----------------------
    ScanInRestArea = false,
    ScanInStealth = false,
    ScanWhileMounted = false,
    InWorld = true,
    InPVP = true,
    InInstance = true,
    SameZone = true,
    ----------------------
    AutoCrusaderAura = true,
    AutoDismount = true,
    AutoDismountFlying = false,
    AutoStand = true,
    AutoDisTravel = false,
    ----------------------
    PreventPVPTag = true,
    DeathBlock = true,
    NoGroupBuff = false,
    ResGhost = false,
    ReplaceSingle = true,
    ReputationTrinket = true,
    Carrot = true,
    MainHand = false,
    SecondaryHand = false,
    UseRank = true,
    BuffTarget = false,
    OpenLootable = true,
    SelfFirst = true,
    DontUseConsumables = false,
    SomeoneIsDrinking = self.defaults.SomeoneIsDrinking,
    ActivateBomOnSpiritTap = 90,
    ShamanFlametongueRanked = true,
    CustomBuffSorting = false,
    ----------------------
    MinBuff = 3,
    MinBlessing = 3,
    Time60 = 10,
    Time300 = 90,
    Time600 = 120,
    Time1800 = 180,
    Time3600 = 180,
    ----------------------
    Minimap = {
      visible = true,
      lock = false,
      lockDistance = false,
      position = 0,
      distance = 0
    },
    PlaySoundWhenTask = "-",
  }
end

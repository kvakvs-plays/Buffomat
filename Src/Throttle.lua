local BuffomatAddon = BuffomatAddon
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class ThrottleModule
---@field taskRescanRequestedBy {[string]: number} Reasons for force update, with count

local throttleModule = LibStub("Buffomat-Throttle") --[[@as ThrottleModule]]
local buffomatModule = LibStub("Buffomat-Buffomat") --[[@as BuffomatModule]]
local eventsModule = LibStub("Buffomat-Events") --[[@as EventsModule]]
local taskScanModule = LibStub("Buffomat-TaskScan") --[[@as TaskScanModule]]
local profileModule = LibStub("Buffomat-Profile") --[[@as ProfileModule]]
local taskListPanelModule = LibStub("Buffomat-TaskListPanel") --[[@as TaskListPanelModule]]

throttleModule.taskRescanRequestedBy = {}

---@class BomThrottleState
---@field lastUpdateTimestamp number
---@field lastModifierKeyState boolean
---@field fpsCheck number
---@field slowCount number
---@field SPELLS_TAB_UPDATE_DELAY number
-- -@field updateTimerLimit number
-- -@field slowerHardwareUpdateTimerLimit number
-- -@field fasterHardwareUpdateTimerLimit number
---@field BOM_THROTTLE_TIMER_LIMIT number
---@field BOM_THROTTLE_SLOWER_HARDWARE_TIMER_LIMIT number
---@field lastSpellsTabUpdate number

---@type BomThrottleState
local throttleState = {
  lastUpdateTimestamp = 0,
  lastModifierKeyState = false,
  fpsCheck = 0,
  slowCount = 0,
  SPELLS_TAB_UPDATE_DELAY = 2.0,
  updateTimerLimit = 0.500,
  fasterHardwareUpdateTimerLimit = 0.500,
  slowerHardwareUpdateTimerLimit = 1.000,
  BOM_THROTTLE_TIMER_LIMIT = 1.000,
  BOM_THROTTLE_SLOWER_HARDWARE_TIMER_LIMIT = 2.000,
  lastSpellsTabUpdate = 0,
}

function throttleModule:FastUpdateTimer()
  throttleState.lastUpdateTimestamp = 0
end

---This runs every frame, do not do any excessive work here
function throttleModule.UpdateTimer()
  local inCombat = InCombatLockdown()

  if inCombat then
    return
  end

  -- if BuffomatShared.SlowerHardware then
  --   throttleState.updateTimerLimit = throttleState.slowerHardwareUpdateTimerLimit
  -- else
  --   throttleState.updateTimerLimit = throttleState.fasterHardwareUpdateTimerLimit
  -- end

  local now = GetTime()

  if BuffomatAddon.inLoadingScreen and BuffomatAddon.loadingScreenTimeOut then
    if BuffomatAddon.loadingScreenTimeOut > now then
      return
    else
      BuffomatAddon.inLoadingScreen = false
      eventsModule:OnCombatStop()
    end
  end

  if now - throttleState.lastSpellsTabUpdate > throttleState.SPELLS_TAB_UPDATE_DELAY then
    buffomatModule:UseProfile(profileModule:ChooseProfile())
    throttleState.lastSpellsTabUpdate = now
  end

  if BuffomatAddon.nextCooldownDue and BuffomatAddon.nextCooldownDue <= now then
    throttleModule:RequestTaskRescan("cdDue")
  end

  if BuffomatAddon.checkCooldown then
    local cdtest = envModule.GetSpellCooldown(BuffomatAddon.checkCooldown)
    if cdtest == nil or cdtest == 0 then
      BuffomatAddon.checkCooldown = nil
      throttleModule:RequestTaskRescan("checkCd")
    end
  end

  if BuffomatAddon.scanModifierKeyDown and throttleState.lastModifierKeyState ~= IsModifierKeyDown() then
    throttleState.lastModifierKeyState = IsModifierKeyDown()
    throttleModule:RequestTaskRescan("ModifierKeyDown")
  end

  taskListPanelModule:WindowCommand() -- open and close window as requested

  -- This will trigger update on timer, regardless of other conditions
  local needForceUpdate = next(throttleModule.taskRescanRequestedBy) ~= nil
  -- TODO: If need slower update, need to cancel the timer in Buffomat.lua and start with a different interval
  throttleModule:Update(now, needForceUpdate)
end

---Update timers, slow hardware and auto-throttling
---@param now number
---@param needForceUpdate boolean
function throttleModule:Update(now, needForceUpdate)
  local timeSinceLastUpdate = now - (throttleState.lastUpdateTimestamp or 0)

  if (needForceUpdate or BuffomatAddon.repeatUpdate)
  --and timeSinceLastUpdate > throttleState.updateTimerLimit
  then
    throttleState.lastUpdateTimestamp = now

    self:ClearForceUpdate(nil)
    taskScanModule:ScanTasks("timer")

    -- If updatescan call above took longer than 32 ms, and repeated update, then
    -- bump the slow alarm counter, once it reaches 32 we consider throttling.
    -- 1000 ms / 32 ms = 31.25 fps
    -- if (debugprofilestop() - throttleState.fpsCheck) > 32 and BuffomatAddon.repeatUpdate then
    --   throttleState.slowCount = throttleState.slowCount + 1

    --   if throttleState.slowCount >= 20 and updateTimerLimit < 1 then
    --     throttleState.updateTimerLimit = throttleState.BOM_THROTTLE_TIMER_LIMIT
    --     throttleState.slowerHardwareUpdateTimerLimit = throttleState.BOM_THROTTLE_SLOWER_HARDWARE_TIMER_LIMIT
    --     BuffomatAddon:Print("Overwhelmed - slowing down the scans!")
    --   end
    -- else
    --   throttleState.slowCount = 0
    -- end
  end
end

function throttleModule:ClearForceUpdate(debugCallerLocation)
  if debugCallerLocation then
    BuffomatAddon:Debug("clearForceUpdate from " .. debugCallerLocation)
  end
  wipe(self.taskRescanRequestedBy)
end

---@param reason string
function throttleModule:RequestTaskRescan(reason)
  self.taskRescanRequestedBy[reason] = (self.taskRescanRequestedBy[reason] or 0) + 1
end
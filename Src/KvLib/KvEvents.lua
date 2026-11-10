local addonName, ns = ...

-- Event registration which survives the differences between clients: event names
-- that do not exist everywhere, and unit-filtered registration.

---@class KvEventsModule
local module = LibStub("KvLibShared-Events") --[[@as KvEventsModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@alias KvEventHandler fun(event: string, ...: any)

---@class KvEventDispatcher
---@field frame Frame
---@field handlers table<string, KvEventHandler> Handler per registered event
---@field unitFilters table<string, table<string, boolean>> Units per event, where the client cannot filter
local dispatcherClass = {}
dispatcherClass.__index = dispatcherClass

---One frame which dispatches by event name. Handlers get the event name first, like AceEvent.
---@return KvEventDispatcher
function module.NewDispatcher()
  local dispatcher = setmetatable({ handlers = {}, unitFilters = {} }, dispatcherClass)
  dispatcher.frame = CreateFrame("Frame")
  dispatcher.frame:SetScript("OnEvent", function(_frame, event, ...)
    local handler = dispatcher.handlers[event]
    if handler == nil then
      return
    end
    local filter = dispatcher.unitFilters[event]
    if filter ~= nil and not filter[(...)] then
      return
    end
    handler(event, ...)
  end)
  return dispatcher
end

---Modern clients throw on an unknown event and older ones cannot be asked, so the
---registration is also protected.
---@param frame Frame
---@param event string
---@param unit1 string?
---@param unit2 string?
---@return boolean
local function register(frame, event, unit1, unit2)
  if not envModule.IsEventValid(event) then
    return false
  end
  if unit1 ~= nil then
    return (pcall(frame.RegisterUnitEvent, frame, event, unit1, unit2))
  end
  return (pcall(frame.RegisterEvent, frame, event))
end

---@param event string
---@param handler KvEventHandler
---@return boolean registered False when this client does not have the event
function dispatcherClass:On(event, handler)
  self:Off(event)
  if not register(self.frame, event) then
    return false
  end
  self.handlers[event] = handler
  return true
end

---Register an event for one or two units only. The first payload value must be the unit.
---@param event string
---@param handler KvEventHandler
---@param unit1 string
---@param unit2 string?
---@return boolean registered False when this client does not have the event
function dispatcherClass:OnUnit(event, handler, unit1, unit2)
  self:Off(event)
  if self.frame.RegisterUnitEvent then
    if not register(self.frame, event, unit1, unit2) then
      return false
    end
  else
    if not register(self.frame, event) then
      return false
    end
    self.unitFilters[event] = { [unit1] = true, [unit2 or unit1] = true }
  end
  self.handlers[event] = handler
  return true
end

---@param event string
function dispatcherClass:Off(event)
  if self.handlers[event] ~= nil then
    self.frame:UnregisterEvent(event)
    self.handlers[event] = nil
    self.unitFilters[event] = nil
  end
end

---@param event string
---@return boolean
function dispatcherClass:IsRegistered(event)
  return self.handlers[event] ~= nil
end

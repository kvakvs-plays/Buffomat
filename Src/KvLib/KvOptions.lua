---@class KvOptionsModule
---@field optionsOrder number

local kvOptionsModule = --[[@as KvOptionsModule]] LibStub("KvLibShared-Options")
kvOptionsModule.optionsOrder = 0

function kvOptionsModule:ValueToText(type, value)
  if type == "string" then
    return value
  elseif type == "float" then
    return string.format("%.02f", value or 0)
  elseif type == "integer" then
    return string.format("%d", value or 0)
  end
end

function kvOptionsModule:TextToValue(type, editFieldText)
  if type == "string" then
    return editFieldText
  elseif type == "float" then
    return tonumber(editFieldText)
  elseif type == "integer" then
    return tonumber(editFieldText)
  end
end

---@param dict table
---@param key string
---@param notify function|nil Call this with (key, value) on option change
---@param translate fun(key:string):string Translation callable
function kvOptionsModule:TemplateCheckbox(name, dict, key, notify, translate)
  self.optionsOrder = self.optionsOrder + 1

  return {
    name = translate("options.short." .. name),
    desc = translate("options.long." .. name),
    type = "toggle",
    width = "full",
    order = self.optionsOrder,

    set = function(info, val)
      if dict then
        (dict)[key] = val
        if notify then
          (notify)(key, val)
        end
      end
    end,
    get = function(info)
      if dict then
        return (dict)[key] == true
      else
        return nil
      end
    end,
  }
end

---@param name string
---@param onClick function Call this when button is pressed
---@param translate fun(key:string):string Translation callable
function kvOptionsModule:TemplateButton(name, onClick, translate)
  self.optionsOrder = self.optionsOrder + 1

  return {
    name = translate("options.short." .. name),
    desc = translate("options.long." .. name),
    type = "execute",
    width = "half",
    order = self.optionsOrder,
    func = onClick,
  }
end

---@param values table|function Key is sent to the setter, value is the string displayed
---@param dict table|nil
---@param notifyFn function|nil Call this with (key, value) on option change
---@param translate fun(key:string):string Translation callable
function kvOptionsModule:TemplateMultiselect(name, values, dict, notifyFn, setFn, getFn, translate)
  self.optionsOrder = self.optionsOrder + 1

  return {
    name = translate("options.short." .. name),
    desc = translate("options.long." .. name),
    type = "multiselect",
    width = "full",
    order = self.optionsOrder,
    values = values,

    set = setFn or function(_state, key, value)
      if dict then
        ( dict)[key] = value
        if notifyFn then
          (notifyFn)(key, value)
        end
      end
    end,
    get = getFn or function(_state, key)
      if dict then
        return (dict)[key] == true
      else
        return nil
      end
    end,
  }
end

---@param values table|function Key is sent to the setter, value is the string displayed
---@param dict table
---@param style string|nil "dropdown" or "radio"
---@param notifyFn function|nil Call this with (key, value) on option change
---@param translate fun(key:string):string Translation callable
function kvOptionsModule:TemplateSelect(name, values, style, dict, notifyFn, setFn, getFn, translate)
  self.optionsOrder = self.optionsOrder + 1

  return {
    desc = translate("options.long." .. name),
    name = translate("options.short." .. name),
    order = self.optionsOrder,
    style = style or "dropdown",
    type = "select",
    values = values,
    width = 2.0,

    set = setFn or function(info, value)
      if dict then
        (dict)[name] = value
        if notifyFn then
          (notifyFn)(value)
        end
      end
    end,
    get = getFn or function(info)
      if dict then
        return (dict)[name]
      else
        return nil
      end
    end,
  }
end

---@alias RsInputValueType "string"|"float"|"integer"

---@param type RsInputValueType
---@param dict table
---@param key string
---@param notify function|nil Call this with (key, value) on option change
---@param translate fun(key:string):string Translation callable
function kvOptionsModule:TemplateInput(type, name, dict, key, notify, translate)
  self.optionsOrder = self.optionsOrder + 1

  return {
    name = translate("options.short." .. name),
    desc = translate("options.long." .. name),
    type = "input",
    width = "full",
    order = self.optionsOrder,

    set = function(info, val)
      val = self:TextToValue(type, val)
      if dict then
        (dict)[key] = val
        if notify then
          (notify)(key, val)
        end
      end
    end,
    get = function(info)
      if dict then
        return self:ValueToText(type, (dict)[key])
      else
        return nil
      end
    end,
  }
end

---@param dict table
---@param key string
---@param notify function|nil Call this with (key, value) on option change
---@param translate fun(key:string):string Translation callable
function kvOptionsModule:TemplateRange(name, rangeFrom, rangeTo, step, dict, key, notify, translate)
  self.optionsOrder = self.optionsOrder + 1

  return {
    name = translate("options.short." .. name),
    desc = translate("options.long." .. name),
    type = "range",
    min = rangeFrom,
    max = rangeTo,
    step = step,
    width = "full",
    order = self.optionsOrder,

    set = function(info, val)
      if dict then
        (dict)[key] = val
        if notify then
          (notify)(key, val)
        end
      end
    end,
    get = function(info)
      if dict then
        return (dict)[key]
      else
        return nil
      end
    end,
  }
end

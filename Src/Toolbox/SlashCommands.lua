local TOCNAME, _ = ...

---@class SlashCommandsModule
local module = LibStub("Buffomat-SlashCommands") --[[@as SlashCommandsModule]]

local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local kvEnvModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomSlashCommand
---@field command string
---@field description string
---@field handler BomSlashCommand[] | function
---@field target string|nil

local slashCommandConf ---@type BomSlashCommand[]
local slashCommandStrings ---@type string[]

---@class BomSlashCommandChoice
---@field setting string BomSharedSettings field which turns the command on
---@field command string
---@field default boolean

---The commands the user can choose from, shortest first: the first chosen one is used in
---the macro and in messages.
---@type BomSlashCommandChoice[]
module.CHOICES = {
  { setting = "SlashCommandBom", command = "/bom", default = true },
  { setting = "SlashCommandBfm", command = "/bfm", default = false },
  { setting = "SlashCommandBuffomat", command = "/buffomat", default = true },
}
-- With none chosen there would be no way to type a command, and the macro needs one
local FALLBACK_COMMAND = "/buffomat"

---The command the macro and messages use, fixed at load like the registered commands.
module.mainCommand = "/bom"

---Give the settings saved before these options existed their default values.
---@param settings SharedSettings
function module:UpgradeSettings(settings)
  for _, choice in ipairs(self.CHOICES) do
    if settings[choice.setting] == nil then
      settings[choice.setting] = choice.default
    end
  end
end

---The commands chosen in the options, shortest first; never empty.
---@param settings SharedSettings
---@return string[]
function module:ChosenCommands(settings)
  local commands = {}
  for _, choice in ipairs(self.CHOICES) do
    if settings[choice.setting] == true then
      table.insert(commands, choice.command)
    end
  end
  if #commands == 0 then
    commands[1] = FALLBACK_COMMAND
  end
  return commands
end

---Replace "/bom" in a text, such as a translated hint, with the command in use.
---@param text string
---@return string
function module:WithMainCommand(text)
  return (text:gsub("/bom", self.mainCommand))
end

---@param slashStrings string[]
---@param sep string|nil
function module:SlashUnpack(slashStrings, sep)
  local ret = ""
  sep = sep or ", "

  for i = 1, #slashStrings do
    if i ~= 1 then
      ret = ret .. sep
    end
    ret = ret .. slashStrings[i]
  end
  return ret
end

---@param prefix string|nil
---@param conf BomSlashCommand[]|nil
---@param printFn nil|fun(text: string)
function module:PrintSlashCommand(prefix, conf, printFn)
  printFn = printFn or print
  prefix = prefix or ""
  conf = conf or slashCommandConf
  self:PrintSlashCommand_1(
    prefix,
    conf,
    printFn)
end

---@param prefix string
---@param conf BomSlashCommand[]
---@param printFn fun(text: string)
function module:PrintSlashCommand_1(prefix, conf, printFn)
  local colCmd = "|cFFFF9C00"

  ---@diagnostic disable-next-line: unused-local
  for _, subcmd in ipairs(conf) do
    -- if false then
    --   local maybeFormatTable = (type(subcmd.command) == "table") and "|r(" .. colCmd
    --       .. slashModule:SlashUnpack(subcmd.command, "|r/" .. colCmd)
    --       .. "|r)" .. colCmd
    -- end
    local maybeFormatTable = false
    local words = maybeFormatTable or subcmd.command
    if words == "%" then
      words = "<value>"
    end

    if subcmd.description ~= nil and subcmd.description ~= "" then
      local maybeTable = (type(slashCommandStrings) == "table") and slashCommandStrings[1]
      printFn(colCmd .. (maybeTable or slashCommandStrings)
        .. " " .. prefix .. words .. "|r: " .. subcmd.description)
    end

    if type(subcmd.handler) == "table" then
      module:PrintSlashCommand(prefix .. words .. " ",
      --[[@as BomSlashCommand[] ]] subcmd.handler, printFn)
    end
  end
end

---@param c BomSlashCommand
function module:UnpackCommand(c)
  return c.command, c.description, c.handler, c.target
end

---@param nestingLevel number
---@param msg string[]
---@param conf BomSlashCommand[]
function module:ParseAndExecute(nestingLevel, msg, conf)
  ---@diagnostic disable-next-line: unused-local
  for _, subcmd in ipairs(conf) do
    local ok = (
          type(subcmd.command) == "table") and tContains(subcmd.command, msg[nestingLevel])
        or (subcmd.command == msg[nestingLevel]
          or (subcmd.command == "" and msg[nestingLevel] == nil)
        )

    if subcmd.command == "%" then
      local para = toolboxModule:iMerge(
        { self:UnpackCommand(subcmd) }, { unpack(msg, nestingLevel) })
      return ( --[[@as function]] subcmd.handler)(unpack(para))
    end

    if ok then
      if type(subcmd.handler) == "function" then
        return ( --[[@as function]] subcmd.handler)(self:UnpackCommand(subcmd))
      elseif type(subcmd.handler) == "table" then
        return self:ParseAndExecute(
          nestingLevel + 1,
          msg, --[[@as BomSlashCommand[] ]] subcmd.handler) -- we need to go deeper
      end
    end
  end

  self:PrintSlashCommand(toolboxModule:Combine(msg, " ", 1, nestingLevel - 1) .. " ", conf, nil)

  return nil
end

---Here the game will send input text
---@param msg string
---@param _editBox WowControl UI control, the user input box, can :Show, :SetText etc
---@diagnostic disable-next-line: unused-local
function module.HandleSlashCommand(msg, _editBox)
  if msg == "help" then
    local color = "|cFFFF9C00"
    print("|cFFFF1C1C" .. kvEnvModule.GetAddOnMetadata(TOCNAME, "Title")
      .. " " .. kvEnvModule.GetAddOnMetadata(TOCNAME, "Version")
      .. " by " .. kvEnvModule.GetAddOnMetadata(TOCNAME, "Author"))
    print(kvEnvModule.GetAddOnMetadata(TOCNAME, "Notes"))
    if type(slashCommandStrings) == "table" then
      print("SlashCommand:", color, module:SlashUnpack(slashCommandStrings, "|r, " .. color), "|r")
    end

    module:PrintSlashCommand(nil, nil, nil)
  else
    module:ParseAndExecute(1, toolboxModule:Split(msg, " "), slashCommandConf)
  end
end

---Register slash commands as strings in the _G[SLASH_<BUFFOMAT>1..N] table, and register slash handler in SlashCmdList
---See https://wowwiki-archive.fandom.com/wiki/Creating_a_slash_command
---@param cmds string[] The commands as strings
---@param subcommand BomSlashCommand[] The describing structure for slash commands
function module:RegisterSlashCommandHandler(cmds, subcommand)
  slashCommandConf = subcommand
  slashCommandStrings = cmds
  module.mainCommand = type(cmds) == "table" and cmds[1] or cmds --[[@as string]]

  if type(cmds) == "table" then
    for i, cmd in ipairs(cmds) do
      _G["SLASH_" .. TOCNAME .. i] = cmd
    end
  else
    _G["SLASH_" .. TOCNAME .. "1"] = cmds
  end

  SlashCmdList[TOCNAME] = module.HandleSlashCommand
end
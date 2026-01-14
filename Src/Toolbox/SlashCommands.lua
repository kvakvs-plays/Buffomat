local TOCNAME, _ = ...

---@class SlashCommandsModule

local slashModule = LibStub("Buffomat-SlashCommands") --[[@as SlashCommandsModule]]
local toolboxModule = LibStub("Buffomat-LegacyToolbox") --[[@as LegacyToolboxModule]]
local kvEnvModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]

---@class BomSlashCommand
---@field command string
---@field description string
---@field handler BomSlashCommand[] | function
---@field target string|nil

local slashCommandConf ---@type BomSlashCommand[]
local slashCommandStrings ---@type string[]

---@param slashStrings string[]
---@param sep string|nil
function slashModule:SlashUnpack(slashStrings, sep)
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
function slashModule:PrintSlashCommand(prefix, conf, printFn)
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
function slashModule:PrintSlashCommand_1(prefix, conf, printFn)
  local colCmd = "|cFFFF9C00"

  ---@diagnostic disable-next-line: unused-local
  for i, subcmd in ipairs(conf) do
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
      slashModule:PrintSlashCommand(prefix .. words .. " ",
      --[[@as BomSlashCommand[] ]] subcmd.handler, printFn)
    end
  end
end

---@param c BomSlashCommand
function slashModule:UnpackCommand(c)
  return c.command, c.description, c.handler, c.target
end

---@param nestingLevel number
---@param msg string[]
---@param conf BomSlashCommand[]
function slashModule:ParseAndExecute(nestingLevel, msg, conf)
  ---@diagnostic disable-next-line: unused-local
  for i, subcmd in ipairs(conf) do
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
---@param editBox WowControl UI control, the user input box, can :Show, :SetText etc
---@diagnostic disable-next-line: unused-local
function slashModule.HandleSlashCommand(msg, editBox)
  if msg == "help" then
    local color = "|cFFFF9C00"
    print("|cFFFF1C1C" .. kvEnvModule.GetAddOnMetadata(TOCNAME, "Title")
      .. " " .. kvEnvModule.GetAddOnMetadata(TOCNAME, "Version")
      .. " by " .. kvEnvModule.GetAddOnMetadata(TOCNAME, "Author"))
    print(kvEnvModule.GetAddOnMetadata(TOCNAME, "Notes"))
    if type(slashCommandStrings) == "table" then
      print("SlashCommand:", color, slashModule:SlashUnpack(slashCommandStrings, "|r, " .. color), "|r")
    end

    slashModule:PrintSlashCommand(nil, nil, nil)
  else
    slashModule:ParseAndExecute(1, toolboxModule:Split(msg, " "), slashCommandConf)
  end
end

---Register slash commands as strings in the _G[SLASH_<BUFFOMAT>1..N] table, and register slash handler in SlashCmdList
---See https://wowwiki-archive.fandom.com/wiki/Creating_a_slash_command
---@param cmds string[] The commands as strings
---@param subcommand BomSlashCommand[] The describing structure for slash commands
function slashModule:RegisterSlashCommandHandler(cmds, subcommand)
  slashCommandConf = subcommand
  slashCommandStrings = cmds

  if type(cmds) == "table" then
    for i, cmd in ipairs(cmds) do
      _G["SLASH_" .. TOCNAME .. i] = cmd
    end
  else
    _G["SLASH_" .. TOCNAME .. "1"] = cmds
  end

  SlashCmdList[TOCNAME] = slashModule.HandleSlashCommand
end
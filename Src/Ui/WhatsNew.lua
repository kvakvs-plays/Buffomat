local addonName, ns = ...

-- The What's new window: versions listed on the left, the changes of the chosen version on a
-- parchment page on the right, Newer / Older / Close below. Also the welcome message in chat
-- at login, with a [What's new] link which opens the window.
--
-- The window is built from Blizzard's templates and raw frames, not AceGUI: the page is a
-- parchment with ink-coloured text, which AceGUI has no widget for.

---@class BomChangelogItem
---@field [1] string Title phrase, shown in red; empty when the point has none
---@field [2] string The change; `text in backticks` is shown as a command
---@field [3] number|nil 1 for a point nested below the previous one

---@class BomChangelogRelease
---@field version string
---@field items BomChangelogItem[]

---@class BomChangelogModule
---@field releases BomChangelogRelease[]|nil Newest first. Written from CHANGELOG.md by wowaddon.py

---@class WhatsNewModule
---@field frame table|nil The window, created when first shown
local module = LibStub("Buffomat-WhatsNew") --[[@as WhatsNewModule]]

local _t = LibStub("Buffomat-Languages") --[[@as LanguagesModule]]
local changelogModule = LibStub("Buffomat-Changelog") --[[@as BomChangelogModule]]
local constModule = LibStub("Buffomat-Const") --[[@as ConstModule]]
local envModule = LibStub("KvLibShared-Env") --[[@as KvSharedEnvModule]]
local slashModule = LibStub("Buffomat-SlashCommands") --[[@as SlashCommandsModule]]

---The slash subcommand which opens the window: "/bom changes"
module.SLASH_COMMAND = "changes"
module.PROJECT_URL = "https://github.com/kvakvs-plays/Buffomat"

-- The "addon" link type is the client's own for addon links: a click reaches SetItemRef and
-- nothing else handles it
local LINK = "addon:" .. addonName .. ":whatsnew"
local LINK_COLOR = "|cff71d5ff"
local VERSION_COLOR = "|cffffffff"
-- How long after login the welcome message is said, so the login chat spam does not bury it
local WELCOME_DELAY = 4

local WIDTH, HEIGHT = 720, 520
local LIST_WIDTH = 240
local LIST_TOP, LIST_BOTTOM = 62, 64 -- the list and the page, from the window's edges
local ROW_HEIGHT = 26
local ROWS_TOP = 40                  -- the first row, below the list's top
local WHEEL_ROWS = 3                 -- rows per mouse wheel step
local NESTED_INDENT = 20

-- Parchment ink, like quest text
local INK = { 0.18, 0.10, 0.02 }
local INK_SOFT = { 0.32, 0.22, 0.12 }
local LEAD_COLOR = "|cff7a2a00" -- the title phrase of each point
local CODE_COLOR = "|cff1f3d7a" -- chat commands

local selected = 1   -- index of the release on the page
local firstShown = 1 -- index of the release in the list's first row

---@return BomChangelogRelease[]
local function releases()
  return changelogModule.releases or {}
end

-- Settings and texts -------------------------------------------------------------------

---Settings saved before the welcome message existed get it switched on.
---@param settings SharedSettings
function module:UpgradeSettings(settings)
  if settings.WelcomeMessage == nil then
    settings.WelcomeMessage = true
  end
end

---The addon's version without the git hash which the build adds: "2026.11.5".
---@return string
function module:Version()
  local version = constModule.TOC_VERSION
  return version and version:match("^[^-]+") or "?"
end

---@return string The [What's new] link for a chat message
function module:ChatLink()
  return LINK_COLOR .. "|H" .. LINK .. "|h[" .. _t("whatsNew.link") .. "]|h|r"
end

---The welcome message: until the window has been opened for this version, it points at it.
---@param seenVersion string|nil The version for which the window was last opened
---@return string
function module:WelcomeText(seenVersion)
  local version = VERSION_COLOR .. "v" .. self:Version() .. "|r"
  local command = slashModule.mainCommand .. " " .. self.SLASH_COMMAND

  if not seenVersion then
    return string.format(_t("whatsNew.welcome.installed"), version, self:ChatLink(), command)
  elseif seenVersion ~= self:Version() then
    return string.format(_t("whatsNew.welcome.updated"), version, self:ChatLink(), command)
  end
  return string.format(_t("whatsNew.welcome.loaded"), version, self:ChatLink())
end

---Say the welcome message in chat, unless it is switched off in the options.
function module:PrintWelcome()
  if BuffomatShared.WelcomeMessage then
    BuffomatAddon:Print(self:WelcomeText(BuffomatShared.SeenVersion))
  end
end

---One point of the changelog as the page shows it: the title phrase in red, commands coloured.
---@param item BomChangelogItem
---@return string
function module:FormatItem(item)
  local lead = (item[1]:gsub("`", ""))
  local text = (item[2]:gsub("`([^`]+)`", CODE_COLOR .. "%1|r"))

  if lead == "" then
    return text
  elseif text == "" then
    return LEAD_COLOR .. lead .. "|r"
  end
  return LEAD_COLOR .. lead .. "|r " .. text
end

---@return number The number of points in all releases
function module:CountChanges()
  local count = 0
  for _, release in ipairs(releases()) do
    count = count + #release.items
  end
  return count
end

---Call once when the addon starts: makes the chat link clickable and says the welcome message.
function module:Init()
  -- A post-hook: the client's handler for the "addon" link type does nothing, and it is not
  -- replaced, so no taint
  hooksecurefunc("SetItemRef", function(link)
    if not envModule.IsSecretValue(link) and link == LINK then
      module:Show()
    end
  end)

  C_Timer.After(WELCOME_DELAY, function()
    module:PrintWelcome()
  end)
end

-- Frames --------------------------------------------------------------------------------

---A frame from a template which only some clients have.
---@return table|nil
local function tryCreate(frameType, name, parent, template)
  local ok, frame = pcall(CreateFrame, frameType, name, parent, template)
  if ok then
    return frame
  end
end

---@param atlas string
---@return boolean
local function hasAtlas(atlas)
  return C_Texture ~= nil and C_Texture.GetAtlasInfo ~= nil and C_Texture.GetAtlasInfo(atlas) ~= nil
end

---The font of a font object at another size. The font is set from the object every time: a
---reused string would keep the font it had before, and put a heading's font on body text.
local function sizedFont(fontString, fontObject, size)
  fontString:SetFontObject(fontObject)
  local path, _, flags = fontObject:GetFont()
  if path then
    fontString:SetFont(path, size, flags)
  end
end

---The title of a ButtonFrameTemplate window; where it is kept differs between clients.
local function setWindowTitle(frame, text)
  if frame.SetTitle then
    frame:SetTitle(text)
  elseif frame.TitleContainer and frame.TitleContainer.TitleText then
    frame.TitleContainer.TitleText:SetText(text)
  elseif frame.TitleText then
    frame.TitleText:SetText(text)
  end
end

---A sunken panel for the version list.
local function createInset(parent)
  local inset = tryCreate("Frame", nil, parent, "InsetFrameTemplate")
  if not inset then
    inset = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    inset:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    inset:SetBackdropColor(0, 0, 0, 0.5)
  end
  return inset
end

---The window opens where it was last dragged to, for every character.
local function rememberPosition(frame)
  local saved = BuffomatShared.WhatsNewPoint
  if saved then
    frame:ClearAllPoints()
    frame:SetPoint(saved[1], UIParent, saved[2], saved[3], saved[4])
  end
  frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    if point then
      BuffomatShared.WhatsNewPoint = { point, relativePoint, x, y }
    end
  end)
end

-- Page ----------------------------------------------------------------------------------

-- The page's font strings and textures are reused when another release is shown
local pool = { strings = {}, textures = {}, usedStrings = 0, usedTextures = 0 }

local function pageString(content, fontObject, size, color)
  pool.usedStrings = pool.usedStrings + 1
  local fontString = pool.strings[pool.usedStrings]
  if not fontString then
    fontString = content:CreateFontString(nil, "OVERLAY")
    pool.strings[pool.usedStrings] = fontString
  end
  sizedFont(fontString, fontObject, size)
  fontString:SetTextColor(color[1], color[2], color[3])
  fontString:SetShadowOffset(0, 0)
  fontString:SetJustifyH("LEFT")
  fontString:SetWordWrap(true)
  fontString:ClearAllPoints()
  fontString:Show()
  return fontString
end

local function pageTexture(content)
  pool.usedTextures = pool.usedTextures + 1
  local texture = pool.textures[pool.usedTextures]
  if not texture then
    texture = content:CreateTexture(nil, "ARTWORK")
    pool.textures[pool.usedTextures] = texture
  end
  texture:ClearAllPoints()
  texture:Show()
  return texture
end

local function renderPage()
  local frame = module.frame
  local content = frame.content
  for _, fontString in ipairs(pool.strings) do
    fontString:Hide()
  end
  for _, texture in ipairs(pool.textures) do
    texture:Hide()
  end
  pool.usedStrings, pool.usedTextures = 0, 0

  local release = releases()[selected]
  if not release then
    return
  end

  local width = content:GetWidth()
  local y = 0
  local function place(fontString, x, gap)
    fontString:SetPoint("TOPLEFT", content, "TOPLEFT", x, -y)
    y = y + fontString:GetStringHeight() + gap
  end

  local title = pageString(content, QuestTitleFont, 26, INK)
  title:SetWidth(width)
  title:SetText(release.version)
  place(title, 0, 6)

  local count = pageString(content, QuestFont, 14, INK_SOFT)
  count:SetWidth(width)
  count:SetText(string.format(_t("whatsNew.changes"), #release.items))
  place(count, 0, 8)

  local rule = pageTexture(content)
  rule:SetColorTexture(INK_SOFT[1], INK_SOFT[2], INK_SOFT[3], 0.45)
  rule:SetHeight(1)
  rule:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
  rule:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -y)
  y = y + 14

  for _, item in ipairs(release.items) do
    local indent = (item[3] or 0) * NESTED_INDENT
    local dot = pageTexture(content)
    dot:SetTexture("Interface\\QuestFrame\\UI-Quest-BulletPoint")
    dot:SetSize(14, 14)
    dot:SetPoint("TOPLEFT", content, "TOPLEFT", 2 + indent, -y - 2)

    local text = pageString(content, QuestFont, 15, INK)
    text:SetWidth(width - 24 - indent)
    text:SetText(module:FormatItem(item))
    place(text, 22 + indent, 12)
  end

  content:SetHeight(math.max(y, 1))
  frame.scroll:SetVerticalScroll(0)
end

-- List ----------------------------------------------------------------------------------

-- The list has as many rows as fit; they show the releases from `firstShown` on. The mouse
-- wheel scrolls the list, and Newer / Older bring the chosen release into view.

local function updateList()
  local frame = module.frame
  local all = releases()

  for i, row in ipairs(frame.rows) do
    local index = firstShown + i - 1
    local release = all[index]
    row.index = index
    row:SetShown(release ~= nil)
    if release then
      local isSelected = index == selected
      local color = isSelected and HIGHLIGHT_FONT_COLOR or NORMAL_FONT_COLOR
      row.selectedBg:SetShown(isSelected)
      row.label:SetText(release.version)
      row.label:SetTextColor(color.r, color.g, color.b)
      row.count:SetText("(" .. #release.items .. ")")
      row.count:SetTextColor(color.r, color.g, color.b)
    end
  end

  frame.newer:SetEnabled(selected > 1)
  frame.older:SetEnabled(selected < #all)
end

---@param rows number Rows to scroll by; positive is towards older releases
local function scrollList(rows)
  local last = math.max(1, #releases() - #module.frame.rows + 1)
  firstShown = math.max(1, math.min(last, firstShown + rows))
  updateList()
end

---@param index number Index of the release to show on the page
local function selectRelease(index)
  selected = math.max(1, math.min(#releases(), index))
  local fit = #module.frame.rows
  if selected < firstShown then
    firstShown = selected
  elseif selected >= firstShown + fit then
    firstShown = selected - fit + 1
  end
  updateList()
  renderPage()
end

-- Window --------------------------------------------------------------------------------

local function createList(frame)
  local list = createInset(frame)
  list:SetPoint("TOPLEFT", 10, -LIST_TOP)
  list:SetPoint("BOTTOMLEFT", 10, LIST_BOTTOM)
  list:SetWidth(LIST_WIDTH)

  local listTitle = list:CreateFontString(nil, "OVERLAY")
  sizedFont(listTitle, QuestTitleFont, 18)
  listTitle:SetTextColor(NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b)
  listTitle:SetPoint("TOPLEFT", 14, -12)
  listTitle:SetText(constModule.SHORT_TITLE)

  local listCount = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  listCount:SetPoint("TOPRIGHT", -14, -17)
  listCount:SetText(string.format(_t("whatsNew.versions"), #releases()))

  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function(_, delta)
    scrollList(-delta * WHEEL_ROWS)
  end)

  frame.rows = {}
  local fit = math.max(1, math.floor((HEIGHT - LIST_TOP - LIST_BOTTOM - ROWS_TOP - 8) / ROW_HEIGHT))
  for i = 1, fit do
    local row = CreateFrame("Button", nil, list)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 8, -ROWS_TOP - (i - 1) * ROW_HEIGHT)
    row:SetPoint("TOPRIGHT", -8, -ROWS_TOP - (i - 1) * ROW_HEIGHT)
    row.selectedBg = row:CreateTexture(nil, "BACKGROUND")
    row.selectedBg:SetAllPoints()
    row.selectedBg:SetColorTexture(0.72, 0.55, 0.12, 0.85)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", 8, 0)
    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.count:SetPoint("RIGHT", -8, 0)
    row:SetScript("OnClick", function(self)
      PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
      selectRelease(self.index)
    end)
    frame.rows[i] = row
  end

  return list
end

local function createPage(frame, list)
  local page = CreateFrame("Frame", nil, frame)
  page:SetPoint("TOPLEFT", list, "TOPRIGHT", 12, 0)
  page:SetPoint("BOTTOMRIGHT", -12, LIST_BOTTOM)

  local parchment = page:CreateTexture(nil, "BACKGROUND")
  parchment:SetAllPoints()
  if hasAtlas("QuestBG-Parchment") then
    parchment:SetAtlas("QuestBG-Parchment")
  else
    parchment:SetTexture("Interface\\QuestFrame\\QuestBG")
    parchment:SetTexCoord(0, 0.586, 0, 0.65)
  end

  local scroll = tryCreate("ScrollFrame", "BuffomatWhatsNewScroll", page, "UIPanelScrollFrameTemplate")
      or CreateFrame("ScrollFrame", "BuffomatWhatsNewScroll", page)
  scroll:SetPoint("TOPLEFT", 36, -30)
  scroll:SetPoint("BOTTOMRIGHT", -40, 24)
  scroll:EnableMouseWheel(true)

  local content = CreateFrame("Frame", nil, scroll)
  content:SetSize(WIDTH - 10 - LIST_WIDTH - 12 - 12 - 36 - 40, 1)
  scroll:SetScrollChild(content)
  if not scroll.ScrollBar then
    -- No template, no scroll bar: the mouse wheel still scrolls
    scroll:SetScript("OnMouseWheel", function(self, delta)
      local max = math.max(0, content:GetHeight() - self:GetHeight())
      self:SetVerticalScroll(math.max(0, math.min(max, self:GetVerticalScroll() - delta * 40)))
    end)
  end

  frame.scroll, frame.content = scroll, content
end

local function createButtons(frame)
  frame.newer = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.newer:SetSize(110, 22)
  frame.newer:SetPoint("BOTTOMLEFT", 12, 36)
  frame.newer:SetText(_t("whatsNew.newer"))
  frame.newer:SetScript("OnClick", function() selectRelease(selected - 1) end)

  frame.older = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  frame.older:SetSize(110, 22)
  frame.older:SetPoint("LEFT", frame.newer, "RIGHT", 12, 0)
  frame.older:SetText(_t("whatsNew.older"))
  frame.older:SetScript("OnClick", function() selectRelease(selected + 1) end)

  local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
  close:SetSize(110, 22)
  close:SetPoint("BOTTOMRIGHT", -12, 36)
  close:SetText(CLOSE or "Close")
  close:SetScript("OnClick", function() frame:Hide() end)
end

---Where to send requests. The game cannot open a link, so the address is in a box to copy from.
local function createFooter(frame)
  local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  footer:SetPoint("BOTTOMLEFT", 14, 12)
  footer:SetText(_t("whatsNew.footer"))

  local url = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
  url:SetSize(250, 20)
  url:SetPoint("LEFT", footer, "RIGHT", 14, 0)
  url:SetAutoFocus(false)
  url:SetText(module.PROJECT_URL)
  url:SetCursorPosition(0)
  url:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  url:SetScript("OnTextChanged", function(self)
    if self:GetText() ~= module.PROJECT_URL then
      self:SetText(module.PROJECT_URL)
      self:HighlightText()
    end
  end)
  url:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

  local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("LEFT", url, "RIGHT", 8, 0)
  hint:SetText(_t("whatsNew.copyHint"))
end

local function createWindow()
  -- Named, so that Escape closes it (UISpecialFrames holds frame names)
  local name = "BuffomatWhatsNewFrame"
  local title = string.format(_t("whatsNew.title"), constModule.SHORT_TITLE)
      .. "  |cff9d9d9dv" .. module:Version() .. "|r"

  local frame = tryCreate("Frame", name, UIParent, "ButtonFrameTemplate")
  if frame then
    if ButtonFrameTemplate_HidePortrait then
      ButtonFrameTemplate_HidePortrait(frame)
    end
    setWindowTitle(frame, title)
    if frame.Inset then
      frame.Inset:Hide()
    end
  else
    frame = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 24,
      insets = { left = 6, right = 6, top = 6, bottom = 6 },
    })
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -12)
    titleText:SetText(title)
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -2, -2)
  end

  frame:SetSize(WIDTH, HEIGHT)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  rememberPosition(frame)
  tinsert(UISpecialFrames, name)

  local summary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  summary:SetPoint("TOPLEFT", 16, -36)
  summary:SetText(string.format(_t("whatsNew.summary"), module:CountChanges()))

  local list = createList(frame)
  createPage(frame, list)
  createButtons(frame)
  createFooter(frame)

  frame:Hide()
  return frame
end

---Show the window with the newest release on the page.
function module:Show()
  self.frame = self.frame or createWindow()
  self.frame:Show()
  selectRelease(1)
  -- The welcome message stops pointing at the window for this version
  BuffomatShared.SeenVersion = self:Version()
end

function module:Toggle()
  if self.frame and self.frame:IsShown() then
    self.frame:Hide()
  else
    self:Show()
  end
end

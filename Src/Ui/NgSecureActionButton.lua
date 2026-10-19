--[[-----------------------------------------------------------------------------
Secure Action Button Widget, extends AceGUI-3.0 Button Widget
-------------------------------------------------------------------------------]]
local Type, Version = "NgSecureActionButton", 24
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs = pairs

-- WoW APIs
local _G = _G
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	["OnAcquire"] = function(self)
		-- restore default values
		self:SetHeight(24)
		self:SetWidth(200)
		self:SetDisabled(false)
		self:SetAutoWidth(false)
		self:SetText()
	end,

	-- ["OnRelease"] = nil,

	["SetText"] = function(self, text)
    if not self.label then
      return
    end
		self.label:SetText(text)
		if self.autoWidth then
			-- self:SetWidth(self.label:GetStringWidth() + 30)
			self.label:SetWidth(self.label:GetStringWidth() + 8)
		end
	end,

	["SetAutoWidth"] = function(self, autoWidth)
		self.autoWidth = autoWidth
		if self.autoWidth then
			-- self:SetWidth(self.label:GetStringWidth() + 30)
			self.label:SetWidth(self.label:GetStringWidth() + 8)
		end
	end,

	["SetDisabled"] = function(self, disabled)
		self.disabled = disabled
		if disabled then
			self.frame:Disable()
		else
			self.frame:Enable()
		end
	end
}

--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
---@class NgSecureActionButton
---@field frame Button
---@field label SimpleFontString
---@field text string
---@field type string

local function Constructor()
	local name = "NgSecureActionButton" .. AceGUI:GetNextWidgetNum(Type)
	-- local buttonFrame = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
	local buttonFrame = CreateFrame("Button", name, UIParent, "BomC_SecureButton")
	buttonFrame:Hide()
	buttonFrame:EnableMouse(true)

	local buttonLabel = buttonFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  if buttonLabel then
    buttonLabel:ClearAllPoints()
    buttonLabel:SetPoint("TOPLEFT", 8, -4)
    buttonLabel:SetPoint("BOTTOMRIGHT", -4, 1)
    buttonLabel:SetJustifyV("MIDDLE")
  end

  -- Texture the button
  -- local buttonTex = buttonFrame:CreateTexture(nil, "BACKGROUND");
  -- buttonTex:SetAllPoints(buttonFrame);
  -- buttonTex:SetTexture("Interface\\Buttons\\UI-DialogBox-Button-Up");

  ---@type NgSecureActionButton
	local widget = {
		frame = buttonFrame,
    label = buttonLabel,
		type  = Type
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end

	return AceGUI:RegisterAsWidget(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)

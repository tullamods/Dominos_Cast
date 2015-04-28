--[[
	CastBar, by Goranaws
--]]

local Addon = _G["Dominos"]
local Frame = Addon:CreateClass('Frame', Addon.Frame)
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastingBar')
local SML = LibStub('LibSharedMedia-3.0')

--[[ Bar ]]--
function Frame:New()
	return Frame.proto.New(self, 'cast')
end

local function check(source, target)
	--you may now add new defaults at will. ~Goranaws
	if not target then 
		target = {}
	end
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] =check(value, target[key])
		else
			if (type(value) == "boolean") then
				if target[key] == nil then
					target[key] = value
				end
 			else
 				target[key] = target[key] or value
 			end
		end
	end
	return target
end

function Frame:Create(...)
	local bar = Frame.proto.Create(self, ...)
	bar.cast = CreateFrame("StatusBar",  bar:GetName().."Bar", bar, "CastingBarFrameTemplate")
	bar.cast:SetPoint("Center")
	bar.cast.unit = "player"
	bar.cast:SetAttribute("unit", "player")
	CastingBarFrame_SetLook(bar.cast, "UNITFRAME")
	bar.cast.text:SetAllPoints(bar.cast)
	bar.cast.time = bar.cast:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.cast.time:SetTextColor(1.0,1.0,1.0)
	bar.cast.time:SetAllPoints(bar.cast)
	--background handler
		--now doubles as an anchor
		--for the castBar and Icon.
	bar.skin = CreateFrame("Frame", bar:GetName().."Skin", bar.cast)
	bar.skin:SetFrameLevel(bar:GetFrameLevel()-1)
	bar.skin:SetPoint("Center", bar)
	bar.cast:HookScript("OnUpdate", function()
		local _, _, _, _, startTime, endTime = UnitCastingInfo("player")
		if not startTime then
			_, _, _, _, startTime, endTime = UnitChannelInfo("player")
		end
		if endTime and (endTime > 0) then
			local style = bar.sets.timeFormat
			if style == "Default" then
				bar.cast.time:SetText(string.format("%.1f", (endTime / 1000) - GetTime()))
			elseif style == "Percent" then
				bar.cast.time:SetText(string.format("%.0f", ((GetTime() - (startTime / 1000)) / ((endTime- startTime)/1000))*100).."%")
			elseif style == "Fraction" then
				bar.cast.time:SetText(string.format("%.1f", GetTime() - (startTime / 1000) ).."/"..string.format("%.1f", (endTime- startTime)/1000))
			end
		end
		bar.cast.icon:SetTexCoord(.15,.85,.15,.85)
	end)
	bar.cast.border:SetParent(MainMenuBarArtFrame)
	bar.cast.borderShield:SetParent(MainMenuBarArtFrame)
	bar.cast.barFlash:SetTexture("Interface\\Cooldown\\star4")
	bar.cast.barFlash:SetVertexColor(0,1,0,1)
	bar.cast.barFlash:SetBlendMode("ADD")
	bar.cast.barFlash:SetAllPoints(bar.skin)
	bar:LoadSettings()
	bar:Layout()
	return bar
end

function Frame:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		height = 1.6,
		width = 20.0,
		padding = 3,
		hideText = false,
		showIcon = true,
		inset = 3,
		color = {
			r = 0,
			g = 0,
			b = 0,
			a = 1
		},
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		timeFormat = "Default",
		alignText = "LEFT",
		alignTime = "RIGHT",
		texture = "Interface\\TargetingFrame\\UI-StatusBar",
		font = "Arial Narrow",
		hideDefault = true,
	}
end

local Version, checkSettings, requiresReset = 2.4, true, false

function Frame:CheckVersion()
	if ((not self.sets.version) or (self.sets.version ~= Version))then
		if requiresReset then
			wipe(self.sets)
		end
		self.sets.version = Version
		if checkSettings then
			self.sets = check(self:GetDefaults(), self.sets)
		end
		self.verified = true
	end
end

function Frame:Layout()
	self:CheckVersion()

	if self.sets.hideText then
		self.cast.text:SetAlpha(0)
	else
		self.cast.text:SetAlpha(1)
	end
	self:ToggleIcon()
	self:Resize()
	self:Skin()
	self:ToggleTime()
	self.cast.text:SetJustifyH(self.sets.alignText)
	self.cast.time:SetJustifyH(self.sets.alignTime)
	self:ApplyTexture()
	local SML = LibStub('LibSharedMedia-3.0', true)
	self.cast.text:SetFont(SML:Fetch('font', self.sets.font), 12)
	self.cast.time:SetFont(SML:Fetch('font', self.sets.font), 12)
	
	self:ToggleBlizzard()
	
end

function Frame:Resize()
	local pw, ph = self:GetPadding()
	local w, h = self.sets.width, self.sets.height
	self:SetSize(w + pw, h + ph)
	self.skin:SetSize(w, h)
	local offset = 0
	if self.sets.showIcon then
		offset = 19
	end
	self.cast:SetSize(w-offset, h)
	local point = "Right"
	if self.sets.isRightToLeft then 
		point = "Left"
	end
	self.cast:ClearAllPoints()
	self.cast:SetPoint(point, self.skin)
end

function Frame:ToggleIcon()
	if self.sets.showIcon then
		self.cast.icon:Show()
		local point = "Left"
		if self.sets.isRightToLeft then 
			point = "Right"
		end
		self.cast.icon:ClearAllPoints()
		self.cast.icon:SetPoint(point, self.skin)
	else
		self.cast.icon:Hide()
	end
end

function Frame:ToggleBlizzard()
	if self.sets.hideDefault then
		CastingBarFrame.parent = CastingBarFrame:GetParent():GetName()
		CastingBarFrame:SetParent(MainMenuBarArtFrame)
	else
		CastingBarFrame:SetParent(_G[CastingBarFrame.parent] or UIParent)
	end
end

function Frame:Skin()
	self.skin:SetBackdrop({
		bgFile = self.sets.bgFile,
		insets = {left = -self.sets.inset, right = -self.sets.inset, top = -self.sets.inset, bottom = -self.sets.inset},
		tile = false,
	})
	self.skin:SetBackdropColor(self.sets.color.r, self.sets.color.g, self.sets.color.b, self.sets.color.a)
end

function Frame:ToggleTime()
	if self.sets.hideTime then
		self.cast.time:Hide()
	else
		self.cast.time:Show()
	end
end

function Frame:SetLeftToRight(isLeftToRight)
    local isRightToLeft = not isLeftToRight
    self.sets.isRightToLeft = isRightToLeft and true or nil
    self:Layout()
end

function Frame:GetLeftToRight()
    return not self.sets.isRightToLeft
end

function Frame:ApplyTexture()
	local texture = (SML and SML:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
	self.cast:SetStatusBarTexture(texture)
end

function Frame:SetTexture(texture)
	self.sets.texture = texture
	self:ApplyTexture()
end

function Frame:GetBarTexture()
	return self.sets.texture
end

function Frame:SetBackground(texture)
	self.sets.bgFile = texture
	self:Skin()
end

function Frame:GetBackground()
	return self.sets.bgFile
end

function Frame:GetFont()
	return self.sets.font
end

function Frame:SetFont(font)
	self.sets.font = font
	self:Layout()
end

--[[ Menu Code ]]--
function NewWidthSlider(menu)
	return menu:NewSlider("Width", 16, 600, 1,
		function(self)
			local width = menu.owner.sets.width
			self:SetValue(width)
		end, 
		function(self, value)
			menu.owner.sets.width = value
			menu.owner:Layout()
		end
	)
end

function NewHeightSlider(menu)
	return menu:NewSlider("Height", 5, 100, 1,
		function(self)
			local height = menu.owner.sets.height
			self:SetValue(height)
		end, 
		function(self, value)
			menu.owner.sets.height= value
			menu.owner:Layout()
		end
	)
end

function NewInsetSlider(menu)
	return menu:NewSlider("Inset", -30, 100, 1,
		function(self)
			self:SetValue(menu.owner.sets.inset)
		end, 
		function(self, value)
			menu.owner.sets.inset= value
			menu.owner:Layout()
		end
	)
end

local function ShowColorPicker(r, g, b, a, changedCallback)
	ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = nil, nil
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = nil, nil, nil
	ColorPickerFrame:SetColorRGB(r,g,b)
	ColorPickerFrame.hasOpacity, ColorPickerFrame.opacity = (a ~= nil), a
	ColorPickerFrame.previousValues = {r,g,b,a}
	ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
	ColorPickerFrame:Hide() -- Need to run the OnShow handler.
	ColorPickerFrame:Show()
end

local function NewColorPicker(menu, name, key)
	local button = CreateFrame("Button", menu:GetName()..name, menu)
	button:SetSize(24, 24)
	local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetText(name)
	text:SetPoint("Left", button, "Right", 5, 0)
	button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
	button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
	button:GetHighlightTexture():SetBlendMode("ADD")
	button:SetNormalTexture('Interface\\Tooltips\\UI-Tooltip-Background')
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetAllPoints(button)
	border:SetTexture("Interface\\BUTTONS\\UI-Quickslot2")
	border:SetTexCoord(.2,.8,.2,.8)
	button:SetScript("OnShow", function(self)
		local saved = self:GetParent().owner.sets[key]
		button:GetNormalTexture():SetVertexColor(saved.r, saved.g, saved.b, saved.a)
	end)
	button:SetScript("OnClick", function(self)
		local saved = self:GetParent().owner.sets[key]
		local r, g, b, a = saved.r, saved.g, saved.b, saved.a
		ShowColorPicker(r, g, b, a, function(restore)
			local newR, newG, newB, newA
			if restore then
				newR, newG, newB, newA = unpack(restore)
			else
				newA, newR, newG, newB = OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
			end
			saved.r, saved.g, saved.b, saved.a = newR, newG, newB, newA
			self:GetScript("OnShow")(self)
			menu.owner:Layout()
		end)
	end)
	local prev = menu.checkbutton
	if prev then
		button:SetPoint('TopLeft',  prev, 'BottomLeft', 0, -2)
	else
		button:SetPoint('TOPLEFT', 2, 0)
	end
	menu.checkbutton = button
	menu.height = menu.height + 24
	return button
end

local function CheckButton(panel, name, key)
	local c = panel:NewCheckButton(name)
	c:SetScript("OnShow",
		function(self)
			self:SetChecked(self:GetParent().owner.sets[key])
		end
	)
	c:SetScript("OnClick",
		function(self)
			local owner = self:GetParent().owner
			owner.sets[key] = self:GetChecked() or false
			owner:Layout()
		end
	)
	return c
end

local function NewMenu(menu, name, key, table)
	local f = CreateFrame("Frame", menu:GetName()..name, menu)
	f:SetSize(24, 24)
	f.button = CreateFrame("Button", f:GetName().."Button", f)
	f.button:SetPoint("Top")
	f.button:SetSize(24, 24)
	f.button:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
	f.button:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
	f.button:SetDisabledTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Disabled")
	f.button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	f.text = f:CreateFontString(f:GetName() .. 'Text', "OVERLAY", "GameFontHighlightSmall")
	f.text:SetPoint("BottomLeft", f.button, "BottomRight", 6, 2)
	f.text:SetJustifyH('LEFT')
	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	title:SetPoint("TopLeft", f.button, "TopRight", 4, -2)
	title:SetText(name)	
	f:SetScript('OnShow', function(self)
		if self ~= f then
			return
		end
		f:initialize()
		f.text:SetText(f:GetParent().owner.sets[key])
		if not self.stretch then
			self.stretch = 1
			f.button:SetHitRectInsets(0, -(title:GetCenter()+ (title:GetWidth()/2)- f.button:GetCenter()+ (f.button:GetWidth()/2)), 0, 0)
		end
	end)
	f:SetScript("OnHide", function() CloseDropDownMenus() end)
	f.button:SetScript("OnClick", function(self)
		UIDropDownMenu_SetAnchor(f, -4, 6, "TopLeft", f.button, "BottomLeft")
		ToggleDropDownMenu(1, nil, f)
		PlaySound("igMainMenuOptionCheckBoxOn")
	end)
	function f:initialize()
		local owner = f:GetParent().owner
		local info = UIDropDownMenu_CreateInfo()
		for i, anchor in ipairs(table) do
			wipe(info)
			info.text = anchor
			info.func = function(item, name)
				owner.sets[key] = name
				owner:Layout()
				f.text:SetText(name)
			end
			info.checked = (anchor == owner.sets[key])
			info.arg1 = anchor
			UIDropDownMenu_AddButton(info)
		end
	end
	local dropDownList = _G["DropDownList"..1]
	dropDownList.dropdown = f
	dropDownList.shouldRefresh = true
	
	local prev = menu.checkbutton
	if prev then
		f:SetPoint('TOP', prev, 'BOTTOM', 0, -0)
	else
		f:SetPoint('TOPLEFT', 2, -5)
	end
	f.point = {f:GetPoint()}
	menu.checkbutton = f.button
	f.button:SetHitRectInsets(0, 0 , 0, 0)
	menu.height = menu.height + 24
	return f
end

local function AddTexturePanel(menu)
	local p = menu:NewPanel("Textures")
	Addon.MediaPanel:NewMediaButton(p, "Cast Bar", "StatusBar", "GetBarTexture", "SetTexture")
	Addon.MediaPanel:NewMediaButton(p, "Background", "Background", "GetBackground", "SetBackground")
	return p
end

local function AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewPaddingSlider()
	panel:NewScaleSlider()
	NewHeightSlider(panel)
	NewWidthSlider(panel)
	CheckButton(panel, "Show Icon", "showIcon")
	return panel
end

local function AddBGPanel(menu)
	local panel = menu:NewPanel("Background")
	NewInsetSlider(panel)
	NewColorPicker(panel, "Color", "color")
	return panel
end

local function AddTextPanel(menu)
	local panel = menu:NewPanel("Text")
	CheckButton(panel, "Disable Time", "hideTime")
	CheckButton(panel, "Disable Text", "hideText")
	NewMenu(panel, "Time Format", "timeFormat", {"Default", "Percent", "Fraction"})
	NewMenu(panel, "Align Text", "alignText", {"LEFT", "CENTER", "RIGHT"})
	NewMenu(panel, "Align Time", "alignTime", {"LEFT", "CENTER", "RIGHT"})
	--NewMediaButton(panel, "Font", "Font", "GetFont", "SetFont")
	
	Addon.MediaPanel:NewMediaButton(panel, "Font", "Font", "GetFont", "SetFont")

	
	return panel
end

local function AddAdvancedPanel(menu)
	local panel = menu:NewPanel("Advanced")
	panel:NewLeftToRightCheckbox()
	CheckButton(panel, "Disable Blizzard", "hideDefault")
	
	return panel
end

function Frame:CreateMenu()
	local menu = Addon:NewMenu(self.id)
	if menu then
		AddLayoutPanel(menu)
		AddBGPanel(menu)
		AddTexturePanel(menu)
		AddTextPanel(menu)
	 	AddAdvancedPanel(menu)
		self.menu = menu
	end
	return menu
end


--[[ module ]]--
local Controller = Addon:NewModule('Cast')

function Controller:Load()
	self.frame = Frame:New()
end

function Controller:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end

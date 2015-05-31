--[[
	castBar.lua, by Goranaws
--]]
local Addon = _G["Dominos"]
local CastBar = Addon:CreateClass('Frame', Addon.Frame)
local Lib = LibStub('LibSharedMedia-3.0', true)
local castLib = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastingBar')
local configLib

--[[ frame creation ]]--
function CastBar:New()
	return CastBar.proto.New(self, 'cast')
end

local function check(source, target)
	--you may now add new defaults at will. ~Goranaws
	if not target then
		target = {}
	end
	for key, value in pairs(source) do
		if type(value) == "table" then
			target[key] = check(value, target[key])
		else
			if (target[key] == nil) then
				target[key] = value
			end
		end
	end
	return target
end

function CastBar:Create(...)
	local bar = CastBar.proto.Create(self, ...)

	bar.cast = CreateFrame("StatusBar",  bar:GetName().."Bar", bar.header, "CastingBarFrameTemplate")
	bar.cast:Hide()
	bar.cast:SetPoint("Center")
	bar.cast.unit = "player"
	bar.cast:SetAttribute("unit", "player")
	CastingBarFrame_SetLook(bar.cast, "UNITFRAME")

	bar.cast.time = bar.cast:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.cast.time:SetTextColor(1.0,1.0,1.0)

	--background handler
		--now doubles as an anchor
		--for the castBar and Icon.
	bar.skin = CreateFrame("Frame", bar:GetName().."Skin", bar.cast)
	bar.skin:SetFrameLevel(bar:GetFrameLevel()-1)
	bar.skin:SetPoint("Center", bar)
	bar.cast:HookScript("OnUpdate", bar.SetTime)

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


function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		height = 19,
		width = 200,
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
		background = {
			name = "Blizzard Tooltip",
			file = "Interface\\Tooltips\\UI-Tooltip-Background",
		},
		timeFormat = "Default",
		alignText = "LEFT",
		alignTime = "RIGHT",
		texture = {
			name = "Blizzard",
			file = "Interface\\TargetingFrame\\UI-StatusBar",
		},
		font = {
			name = "Friz Quadrata TT",
			file = "",
		},
		textcolor = {r = 1,g = 1,b = 1,a = 1},
		hideDefault = true,
	}
end

--[[ version control
	This can be removed if preferred.
	It's just an easy way for me to
	tinker. ~Goranaws
--]]
local Version, checkSettings, requiresReset = 3.6, true, false

function CastBar:CheckVersion()
	if self.verified then
	--	return
	end
	if ((not self.sets.version) or (self.sets.version ~= Version))then
		if requiresReset then
			wipe(self.sets)
		end
		self.sets.version = 3
		if checkSettings then
			self.sets = check(self:GetDefaults(), self.sets)
		end
		self.verified = true
	end
end

--[[ update functions ]]--
function CastBar:Layout()
	self:CheckVersion()
	self:UpdateIcon()
	self:UpdateSize()
	self:UpdateTextures()
	self:UpdateBlizzard()
	self:UpdateText()
end

function CastBar:UpdateSize()
	local pw, ph = self:GetPadding()
	local w, h = self.sets.width, self.sets.height
	self:SetSize(w + pw, h + ph)
	self.background:SetSize(w, h)
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
	self.cast:SetPoint(point, self.background)
end

function CastBar:UpdateIcon()
	if self.sets.showIcon then
		self.cast.icon:Show()
		local point = "Left"
		if self.sets.isRightToLeft then
			point = "Right"
		end
		self.cast.icon:ClearAllPoints()
		self.cast.icon:SetPoint(point, self.background)
	else
		self.cast.icon:Hide()
	end
end

function CastBar:UpdateBlizzard()
	if self.sets.hideDefault then
		CastingBarFrame:SetParent(MainMenuBarArtFrame)
	else
		CastingBarFrame:SetParent(UIParent)
	end
end

function CastBar:UpdateTextures()
	local b = self.sets.background

	self.background:SetBackdrop({
		bgFile = Lib and Lib:Fetch('background', b.name) or b.file,
		insets = {left = -self.sets.inset, right = -self.sets.inset, top = -self.sets.inset, bottom = -self.sets.inset},
		tile = false,
	})
	self.background:SetBackdropColor(self.sets.color.r, self.sets.color.g, self.sets.color.b, self.sets.color.a)

	local t = self.sets.texture
	local castTexture = Lib and Lib:Fetch('statusbar', t.name) or t.file or DEFAULT_STATUSBAR_TEXTURE
	self.cast:SetStatusBarTexture(castTexture)
end

function CastBar:UpdateText()
	local time, text = self.cast.time, self.cast.text
	local isLeftToRight = self:GetLeftToRight()

	time:ClearAllPoints()
	text:ClearAllPoints()

	local textAlign = self.sets.alignText
	local timeAlign = self.sets.alignTime

	if isLeftToRight then
		time:SetPoint("Right", self.cast)
		text:SetPoint("Left", self.cast)
		text:SetPoint("Right", time, "Left")
	else
		time:SetPoint("Left", self.cast)
		text:SetPoint("Right", self.cast)
		text:SetPoint("Left", time, "Right")

		if textAlign == "LEFT" then
			textAlign = "RIGHT"
		elseif textAlign == "RIGHT" then
			textAlign = "LEFT"
		end
		if timeAlign == "LEFT" then
			timeAlign = "RIGHT"
		elseif timeAlign == "RIGHT" then
			timeAlign = "LEFT"
		end
	end

	text:SetJustifyH(textAlign)
	time:SetJustifyH(timeAlign)

	local f = self.sets.font
	local font = Lib and Lib:Fetch('font', f.name) or f.file
	text:SetFont(font, 12)
	time:SetFont(font, 12)

	local c = self.sets.textcolor
	text:SetTextColor(c.r, c.g, c.b, c.a )
	time:SetTextColor(c.r, c.g, c.b, c.a )

	if self.sets.hideText then
		text:SetAlpha(0)
	else
		text:SetAlpha(1)
		text:Show()
	end

	if (self.sets.hideTime == true) then
		time:SetAlpha(0)
		--time.hidden = true
	else
		time:SetAlpha(1)
		--time.hidden = nil
	end
end

function CastBar:SetTime()
	self.icon:SetTexCoord(.15,.85,.15,.85)

	if self.time.hidden == true then
		return
	end

	local sets = self:GetParent():GetParent().sets
	local startTime, endTime = self:GetParent():GetParent():GetSpellcastStartAndEndTimes()

	if endTime and (endTime > 0) then
		local style = sets.timeFormat
		local text
		local time = GetTime()
		if style == "Default" then
			text = string.format("%.1f", (endTime / 1000) - time)
		elseif style == "Percent" then
			text = string.format("%.0f", ((time - (startTime / 1000)) / ((endTime- startTime)/1000))*100).."%"
		elseif style == "Fraction" then
			text = string.format("%.1f", time - (startTime / 1000) ).."/"..string.format("%.1f", (endTime- startTime)/1000)
		end

		self.time:SetText(text or "")
	end
end

function CastBar:GetSpellcastStartAndEndTimes()
	if self.cast.casting then
		return select(5, UnitCastingInfo('player'))
	end

	if self.cast.channeling then
		return select(5, UnitChannelInfo('player'))
	end
end

--[[ menu controls ]]--
function CastBar:SetLeftToRight(isLeftToRight)
    local isRightToLeft = not isLeftToRight
    self.sets.isRightToLeft = isRightToLeft and true or nil
    self:Layout()
end

function CastBar:GetLeftToRight()
    return not self.sets.isRightToLeft
end

function CastBar:SetTexture(name)
	self.sets.texture.name = name
	self.sets.texture.file = Lib:Fetch('statusbar', name)
	self:UpdateTextures()
end

function CastBar:GetBarTexture()
	return self.sets.texture.name
end

function CastBar:SetBackground(name)
	self.sets.background.name = name
	self.sets.background.file = Lib:Fetch('background', name)
	self:UpdateTextures()
end

function CastBar:GetBackground()
	return self.sets.background.name
end

function CastBar:GetFont()
	return self.sets.font.name
end

function CastBar:SetFont(name)
	self.sets.font.name = name
	self.sets.font.file = Lib:Fetch('Font', name)
	self:Layout()
end

--[[ menu options ]]--
local function AddSlider(panel, name, key, min, max, step)
	return panel:NewSlider(name, min, max, step,
		function(self)
			self:SetValue(panel.owner.sets[key] or min + ((max - min)/2))
		end,
		function(self, value)
			panel.owner.sets[key] = value
			panel.owner:Layout()
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

local function NewColorPicker(menu, name, key) --this thing needs help.
	local button = CreateFrame("Button", menu:GetName()..name, menu)
	button:SetSize(24, 24)
	button:SetHitRectInsets(0,-75,0,0)
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

local function AddCheckButton(panel, name, key)
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

--[[ option panels ]]--
local function AddLayoutPanel(menu)
	local panel = menu:NewPanel(configLib.Layout)
	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewPaddingSlider()
	panel:NewScaleSlider()
	AddSlider(panel, "Height", "height", 5, 100, 1)
	AddSlider(panel, "Width", "width", 16, 600, 1)
	AddCheckButton(panel, "Show Icon", "showIcon")
	return panel
end

local function AddTexturePanel(menu)
	local panel = menu:NewPanel("Textures")
	Addon.MediaPanel:NewMediaButton(panel, "Background", "Background", "GetBackground", "SetBackground")
	NewColorPicker(panel, "Color", "color")
	Addon.MediaPanel:NewMediaButton(panel, "Cast Bar", "StatusBar", "GetBarTexture", "SetTexture")
	AddSlider(panel, "Background Inset", "inset", -30, 100, 1)
	return panel
end

local function AddTextPanel(menu)
	local panel = menu:NewPanel("Text")
	AddCheckButton(panel, "Disable Time", "hideTime")
	NewMenu(panel, "Time Format", "timeFormat", {"Default", "Percent", "Fraction"})
	NewMenu(panel, "Align Time", "alignTime", {"LEFT", "CENTER", "RIGHT"})


	AddCheckButton(panel, "Disable Text", "hideText")
	NewMenu(panel, "Align Text", "alignText", {"LEFT", "CENTER", "RIGHT"})
	NewColorPicker(panel, "Color", "textcolor")
	Addon.MediaPanel:NewMediaButton(panel, "Font", "Font", "GetFont", "SetFont")
	return panel
end

local function AddStatePanel(menu)
	local panel = menu:NewPanel(configLib.ShowStates)
	panel.height = 56
	local editBox = CreateFrame('EditBox', panel:GetName() .. 'StateText', panel, 'InputBoxTemplate')
	editBox:SetWidth(148) editBox:SetHeight(20)
	editBox:SetPoint('TOPLEFT', 12, -10)
	editBox:SetAutoFocus(false)
	editBox:SetScript('OnShow', function()
		editBox:SetText(panel.owner:GetShowStates() or '')
		editBox:ClearFocus()
	end)
	editBox:SetScript('OnEscapePressed', editBox:GetScript("OnShow"))
	editBox:SetScript('OnEnterPressed', function()
		local text = editBox:GetText()
		panel.owner:SetShowStates(text ~= '' and text or nil)
		editBox:ClearFocus()
	end)
	editBox:SetScript('OnEditFocusLost', function(self) self:HighlightText(0, 0) end)
	editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() end)

	local set = CreateFrame('Button', panel:GetName() .. 'Set', panel, 'UIPanelButtonTemplate')
	set:SetWidth(30) set:SetHeight(20)
	set:SetText(configLib.Set)
	set:SetPoint('BOTTOMRIGHT', -8, 2)
	set:SetScript('OnClick', editBox:GetScript("OnEnterPressed"))

	return panel
end

local function AddAdvancedPanel(menu)
	local panel = menu:NewPanel("Advanced")
	panel:NewCheckButton("Left To Right", 'GetLeftToRight', 'SetLeftToRight')
	panel:NewShowInOverrideUICheckbox()
	panel:NewShowInPetBattleUICheckbox()
	AddCheckButton(panel, "Disable Blizzard", "hideDefault")
	return panel
end

function CastBar:CreateMenu()
	local menu = Addon:NewMenu(self.id)
	if menu then
		configLib = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
		AddLayoutPanel(menu)
		AddTexturePanel(menu)
		AddTextPanel(menu)
		AddStatePanel(menu)
	 	AddAdvancedPanel(menu)
		self.menu = menu
	end
end

--[[ module control ]]--
local Controller = Addon:NewModule('Cast')

function Controller:Load()
	self.frame = CastBar:New()
end

function Controller:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end

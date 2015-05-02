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

function CastBar:Create(...)
	local bar = CastBar.proto.Create(self, ...)
	bar.cast = CreateFrame("StatusBar",  bar:GetName().."Bar", bar.header, "CastingBarFrameTemplate")
	bar.cast:Hide()
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
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		timeFormat = "Default",
		alignText = "LEFT",
		alignTime = "RIGHT",
		texture = "Interface\\TargetingFrame\\UI-StatusBar",
<<<<<<< HEAD
		font = "Friz Quadrata TT",
		textcolor = {r = 1,g = 1,b = 1,a = 1},
=======
		font = "Arial Narrow",
>>>>>>> origin/master
		hideDefault = true,
	}
end

<<<<<<< HEAD
=======
local Version, checkSettings, requiresReset = 2.4, true, false
>>>>>>> origin/master

--[[ version control]]--
local Version, checkSettings, requiresReset = 3, true, false

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

<<<<<<< HEAD

--[[ update functions ]]--

function CastBar:Layout()
	self:CheckVersion()
	self:UpdateIcon()
	self:UpdateSize()
	self:UpdateTextures()
	self:UpdateBlizzard()
	self:UpdateText()
	self:UpdateTime()
=======
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
>>>>>>> origin/master
end

function CastBar:UpdateSize()
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

function CastBar:UpdateIcon()
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

<<<<<<< HEAD
function CastBar:UpdateBlizzard()
	if self.sets.hideDefault then
		CastingBarFrame:SetParent(MainMenuBarArtFrame)
	else
		CastingBarFrame:SetParent(UIParent)
	end
end

function CastBar:UpdateTextures()
=======


function Frame:ToggleBlizzard()
	if self.sets.hideDefault then
		CastingBarFrame.parent = CastingBarFrame:GetParent():GetName()
		CastingBarFrame:SetParent(MainMenuBarArtFrame)
	elseif CastingBarFrame.parent then --only do it if we are re-enabling
		CastingBarFrame:SetParent(_G[CastingBarFrame.parent])
		CastingBarFrame.parent = nil	
	end
end

function Frame:Skin()
>>>>>>> origin/master
	self.skin:SetBackdrop({
		bgFile = self.sets.bgFile,
		insets = {left = -self.sets.inset, right = -self.sets.inset, top = -self.sets.inset, bottom = -self.sets.inset},
		tile = false,
	})
	self.skin:SetBackdropColor(self.sets.color.r, self.sets.color.g, self.sets.color.b, self.sets.color.a)
	local castTexture = (Lib and Lib:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
	self.cast:SetStatusBarTexture(castTexture)
end

function CastBar:UpdateText()
	if self.sets.hideText then
		self.cast.text:SetAlpha(0)
		return
	else
		self.cast.text:SetAlpha(1)
		self.cast.text:Show()
		self.cast.text:SetJustifyH(self.sets.alignText)
		self.cast.text:SetFont(Lib:Fetch('font', self.sets.font), 12)
		local c = self.sets.textcolor
		self.cast.text:SetTextColor(c.r, c.g, c.b, c.a )
	end
end

function CastBar:UpdateTime()
	if (self.sets.hideTime == true) then
		self.cast.time:Hide()
		return
	end
	self.cast.time:Show()
	self.cast.time:SetJustifyH(self.sets.alignTime)
	self.cast.time:SetFont(Lib:Fetch('font', self.sets.font), 12)
	local c = self.sets.textcolor
	self.cast.time:SetTextColor(c.r, c.g, c.b, c.a )
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

function CastBar:SetTexture(texture)
	self.sets.texture = texture
	self:UpdateTextures()
end

function CastBar:GetBarTexture()
	return self.sets.texture
end

function CastBar:SetBackground(texture)
	self.sets.bgFile = texture
	self:UpdateTextures()
end

function CastBar:GetBackground()
	return self.sets.bgFile
end

function CastBar:GetFont()
	return self.sets.font
end

function CastBar:SetFont(font)
	self.sets.font = font
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
<<<<<<< HEAD


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

=======
	Addon.MediaPanel:NewMediaButton(panel, "Font", "Font", "GetFont", "SetFont")
>>>>>>> origin/master
	return panel
end

local function AddAdvancedPanel(menu)
	local panel = menu:NewPanel("Advanced")
<<<<<<< HEAD
	panel:NewCheckButton("Left To Right", 'GetLeftToRight', 'SetLeftToRight')
	panel:NewClickThroughCheckbox()
	panel:NewShowInOverrideUICheckbox()
	panel:NewShowInPetBattleUICheckbox()
	AddCheckButton(panel, "Disable Blizzard", "hideDefault")
=======
	panel:NewLeftToRightCheckbox()
	CheckButton(panel, "Disable Blizzard", "hideDefault")
>>>>>>> origin/master
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

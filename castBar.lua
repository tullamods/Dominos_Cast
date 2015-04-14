--[[
	CastBar, by Goranaws
--]]

local Addon = _G["Dominos"]
local Frame = Addon:CreateClass('Frame', Addon.Frame)
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastingBar')

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
	
	bar.cast = CreateFrame("StatusBar",  bar:GetName().."Bar", bar, "DominosCastingBarFrameTemplate")
	bar.cast:SetPoint("Center")
	bar.cast.unit = "player"
	bar.cast:SetAttribute("unit", "player")
	CastingBarFrame_SetLook(bar.cast, "UNITFRAME")
	
	bar.cast.text:SetAllPoints(bar.cast)
	
	bar.cast.time = bar.cast:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
	bar.cast.time:SetTextColor(1.0,1.0,1.0)
	bar.cast.time:SetAllPoints(bar.cast)

	--background handler
	bar.skin = CreateFrame("Frame", bar:GetName().."Skin", bar.cast)
	bar.skin:SetFrameLevel(bar:GetFrameLevel()-1)

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
		height = 3.2,
		width = 30.0,
		padding = 0,
		showText = true,
		inset = 0,
		color = {
			r = 0,
			g = 0,
			b = 0,
			a = 1
		},
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		timeFormat = "Default",
		alignText = "CENTER",
		alignTime = "RIGHT",
		texture = "Interface\\TargetingFrame\\UI-StatusBar",
	}
end

function Frame:Layout()
	self.sets = check(self:GetDefaults(), self.sets)
	self:Resize()
	self:Skin()
	self:ToggleTime()
	
	self.cast.text:SetJustifyH(self.sets.alignText)
	self.cast.time:SetJustifyH(self.sets.alignTime)
	self:UpdateTexture()
end

function Frame:Resize()
	local pw, ph = self:GetPadding()
	local w, h = self.sets.width, self.sets.height
	self:SetSize((w * 10) + (pw), (h * 10) + (ph))

	local offset = -19

	if self.sets.showIcon then
		offset = 0
	end

	self.cast.icon:ClearAllPoints()

	if  self.sets.isRightToLeft then
		self.cast.icon:SetPoint("Left", self.cast, "Right", 3, 0)
		self.cast:SetPoint("Left", self, "Center",  -(((w*10)/2)), 0)
		self.cast:SetPoint("Right", self, "Center", (((w*10)/2) + offset),0)
	else
		self.cast.icon:SetPoint("Right", self.cast, "Left", -3, 0)
		self.cast:SetPoint("Left", self, "Center",  -(((w*10)/2) + offset), 0)
		self.cast:SetPoint("Right", self, "Center", (((w*10)/2)),0)
	end
	
	self.skin:SetPoint("Left", self, "Center",  -(w*5), 0)
	self.skin:SetPoint("Right", self, "Center", w*5,0)
	self.skin:SetHeight(h * 10)
	self.cast:SetHeight(h * 10)
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

function Frame:UpdateTexture()
	local LSM = LibStub('LibSharedMedia-3.0', true)
	local texture = (LSM and LSM:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
	self.cast:SetStatusBarTexture(texture)
end

function Frame:SetTexture(texture)
	self.sets.texture = texture
	self:UpdateTexture()
end

--[[ Menu Code ]]--
function NewWidthSlider(menu)
	return menu:NewSlider("Width", 16, 600, 1,
		function(self)
			local width = menu.owner.sets.width
			self:SetValue(width*10)
		end, 
		function(self, value)
			menu.owner.sets.width = value/10
			menu.owner:Layout()
		end
	)
end

function NewHeightSlider(menu)
	return menu:NewSlider("Height", 16, 100, 1,
		function(self)
			local height = menu.owner.sets.height
			self:SetValue(height*10)
		end, 
		function(self, value)
			menu.owner.sets.height= value/10
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
	local s
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
	end)

	f:SetScript("OnHide", function() CloseDropDownMenus() end)

	f.button:SetScript("OnClick", function(self)
		ToggleDropDownMenu(1, nil, f, "cursor")
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

	menu.height = menu.height + 24
	return f
end


--[[Texture Panel   I plan to do more with this.
                    I want easy SharedMedia support.
                   ~Goranaws
--]]
local NUM_ITEMS, WIDTH, HEIGHT, OFFSET = 8, 155, 20, 0

local function TextureButton_OnClick(self)
	self:GetParent().owner:SetTexture(self:GetText())
	self:GetParent():UpdateList()
end

local function TextureButton_OnMouseWheel(self, direction)
	local scrollBar = _G[self:GetParent().scroll:GetName() .. 'ScrollBar']
	scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
	parent:UpdateList()
end

local function TextureButton_Create(name, parent)
	local button = CreateFrame('Button', name, parent)
	button:SetWidth(WIDTH)
	button:SetHeight(HEIGHT)

	button.bg = button:CreateTexture()
	button.bg:SetAllPoints(button)

	local r, g, b = max(random(), 0.2), max(random(), 0.2), max(random(), 0.2)
	button.bg:SetVertexColor(r, g, b)
	button:EnableMouseWheel(true)
	button:SetScript('OnClick', TextureButton_OnClick)
	button:SetScript('OnMouseWheel', TextureButton_OnMouseWheel)
	button:SetNormalFontObject('GameFontNormalLeft')
	button:SetHighlightFontObject('GameFontHighlightLeft')
	return button
end

local function Panel_UpdateList(self)
	local SML = LibStub('LibSharedMedia-3.0')
	local textures = SML:List('statusbar')
	local currentTexture = self.owner.sets.texture

	local scroll = self.scroll
	FauxScrollFrame_Update(scroll, #textures, #self.buttons, HEIGHT + OFFSET)

	for i,button in pairs(self.buttons) do
		local index = i + scroll.offset

		if index <= #textures then
			button:SetText(textures[index])
			button.bg:SetTexture(SML:Fetch('statusbar', textures[index]))
			button:Show()
		else
			button:Hide()
		end
	end
end

local function AddTexturePanel(menu)
	local p = menu:NewPanel(L.Texture)
	p.UpdateList = Panel_UpdateList
	p:SetScript('OnShow', function() p:UpdateList() end)
	p.textures = LibStub('LibSharedMedia-3.0'):List('statusbar')

	local name = p:GetName()
	local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', p, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function(self, arg1) FauxScrollFrame_OnVerticalScroll(self, arg1, HEIGHT + OFFSET, function() p:UpdateList() end) end)
	scroll:SetScript('OnShow', function() p.buttons[1]:SetWidth(WIDTH) end)
	scroll:SetScript('OnHide', function() p.buttons[1]:SetWidth(WIDTH + 20) end)
	scroll:SetPoint('TOPLEFT', 8, 0)
	scroll:SetPoint('BOTTOMRIGHT', -24, 2)
	p.scroll = scroll

	--add list buttons
	p.buttons = {}
	for i = 1, NUM_ITEMS do
		local b = TextureButton_Create(name .. i, p)
		if i == 1 then
			b:SetPoint('TOPLEFT', 4, 0)
		else
			b:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -OFFSET)
			b:SetPoint('TOPRIGHT', name .. i-1, 'BOTTOMRIGHT', 0, -OFFSET)
		end
		p.buttons[i] = b
	end

	p.height = 5 + (NUM_ITEMS * HEIGHT)
end

local function AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewPaddingSlider()
	panel:NewScaleSlider()
	NewHeightSlider(panel)
	NewWidthSlider(panel)
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
	NewMenu(panel, "Time Format", "timeFormat", {"Default", "Percent", "Fraction"})
	NewMenu(panel, "Align Text", "alignText", {"LEFT", "CENTER", "RIGHT"})
	NewMenu(panel, "Align Time", "alignTime", {"LEFT", "CENTER", "RIGHT"})

	return panel
end

local function AddAdvancedPanel(menu)
	local panel = menu:NewPanel("Advanced")

	panel:NewLeftToRightCheckbox()
	
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

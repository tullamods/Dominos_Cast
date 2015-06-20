--[[
	Dominos_Cast/menu.lua
		the right click menu for the cast bar
--]]

local AddonName, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local LSM = LibStub('LibSharedMedia-3.0', true)
local L

--[[ helper methods ]]--

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
	local panel = menu:NewPanel(L.Layout)
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
	Dominos.MediaPanel:NewMediaButton(panel, "Background", "Background", "GetBackground", "SetBackground")
	NewColorPicker(panel, "Color", "color")
	Dominos.MediaPanel:NewMediaButton(panel, "Cast Bar", "StatusBar", "GetBarTexture", "SetTexture")
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
	Dominos.MediaPanel:NewMediaButton(panel, "Font", "Font", "GetFont", "SetFont")
	return panel
end

local function AddStatePanel(menu)
	local panel = menu:NewPanel(L.ShowStates)
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
	set:SetText(L.Set)
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

--[[ exports ]]--

Addon.CreateMenu = function(self, owner)
	local menu = Dominos:NewMenu(owner.id)

	if menu then
		L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

		AddLayoutPanel(menu)
		AddTexturePanel(menu)
		AddTextPanel(menu)
		AddStatePanel(menu)
		AddAdvancedPanel(menu)
	end

	return menu
end

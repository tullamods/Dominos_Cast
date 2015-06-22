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
	ColorPickerFrame:SetColorRGB(r, g, b)

	ColorPickerFrame.hasOpacity = a ~= nil
	ColorPickerFrame.opacity = a

	ColorPickerFrame.previousValues = {r, g, b, a}

	ColorPickerFrame.func = changedCallback
	ColorPickerFrame.opacityFunc = changedCallback
	ColorPickerFrame.cancelFunc = changedCallback

	ColorPickerFrame:Hide() -- Need to run the OnShow handler.
	ColorPickerFrame:Show()
end

local function NewColorPicker(menu, name, key) --this thing needs help.
	local button = CreateFrame('Button', menu:GetName()..name, menu)
	button:SetSize(24, 24)
	button:SetHitRectInsets(0, -75, 0, 0)

	local text = button:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	text:SetText(name)
	text:SetPoint('LEFT', button, 'RIGHT', 5, 0)

	button:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	button:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	button:GetHighlightTexture():SetBlendMode('ADD')
	button:SetNormalTexture([[Interface\Tooltips\UI-Tooltip-Background]])

	local border = button:CreateTexture(nil, 'OVERLAY')
	border:SetAllPoints(button)
	border:SetTexture([[Interface\BUTTONS\UI-Quickslot2]])
	border:SetTexCoord(0.2, 0.8, 0.2, 0.8)

	button:SetScript('OnShow', function(self)
		local saved = self:GetParent().owner.sets[key]

		button:GetNormalTexture():SetVertexColor(saved.r, saved.g, saved.b, saved.a)
	end)

	button:SetScript('OnClick', function(self)
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

			self:GetScript('OnShow')(self)

			menu.owner:Layout()
		end)
	end)

	local prev = menu.checkbutton
	if prev then
		button:SetPoint('TOPLEFT',  prev, 'BOTTOMLEFT', 0, -2)
	else
		button:SetPoint('TOPLEFT', 2, 0)
	end

	menu.checkbutton = button
	menu.height = menu.height + 24

	return button
end

local function AddCheckButton(panel, name, key)
	local checkButton = panel:NewCheckButton(name)

	checkButton:SetScript('OnShow', function(self)
		self:SetChecked(self:GetParent().owner.sets[key])
	end)

	checkButton:SetScript('OnClick', function(self)
		local owner = self:GetParent().owner

		owner.sets[key] = self:GetChecked() or false
		owner:Layout()
	end)

	return checkButton
end

local function NewMenu(parent, name, key, table)
	local menu = CreateFrame('Frame', parent:GetName()..name, parent)
	menu:SetSize(24, 24)

	menu.button = CreateFrame('Button', menu:GetName()..'Button', menu)
	menu.button:SetPoint('TOP')
	menu.button:SetSize(24, 24)
	menu.button:SetNormalTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Up]])
	menu.button:SetPushedTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Down]])
	menu.button:SetDisabledTexture([[Interface\ChatFrame\UI-ChatIcon-ScrollDown-Disabled]])
	menu.button:SetHighlightTexture([[Interface\Buttons\UI-Common-MouseHilight]])

	menu.text = menu:CreateFontString(menu:GetName() .. 'Text', 'OVERLAY', 'GameFontHighlightSmall')
	menu.text:SetPoint('BOTTOMLEFT', menu.button, 'BOTTOMRIGHT', 6, 2)
	menu.text:SetJustifyH('LEFT')

	local title = menu:CreateFontString(nil, 'OVERLAY', 'GameFontNormalSmall')
	title:SetPoint('TOPLEFT', menu.button, 'TOPRIGHT', 4, -2)
	title:SetText(name)

	menu:SetScript('OnShow', function(self)
		if self ~= menu then
			return
		end

		menu:initialize()
		menu.text:SetText(menu:GetParent().owner.sets[key])

		if not self.stretch then
			self.stretch = 1

			menu.button:SetHitRectInsets(0, -(title:GetCenter()+ (title:GetWidth()/2)- menu.button:GetCenter()+ (menu.button:GetWidth()/2)), 0, 0)
		end
	end)

	menu:SetScript('OnHide', function()
		CloseDropDownMenus()
	end)

	menu.button:SetScript('OnClick', function(self)
		UIDropDownMenu_SetAnchor(menu, -4, 6, 'TOPLEFT', menu.button, 'BOTTOMLEFT')
		ToggleDropDownMenu(1, nil, menu)
		PlaySound('igMainMenuOptionCheckBoxOn')
	end)

	menu.initialize = function(self)
		local owner = menu:GetParent().owner
		local info = UIDropDownMenu_CreateInfo()

		for i, anchor in ipairs(table) do
			wipe(info)
			info.text = anchor

			info.func = function(item, name)
				owner.sets[key] = name
				owner:Layout()
				menu.text:SetText(name)
			end

			info.checked = (anchor == owner.sets[key])

			info.arg1 = anchor

			UIDropDownMenu_AddButton(info)
		end
	end

	local dropDownList = _G['DropDownList'..1]
	dropDownList.dropdown = menu
	dropDownList.shouldRefresh = true

	local prev = parent.checkbutton
	if prev then
		menu:SetPoint('TOP', prev, 'BOTTOM', 0, -0)
	else
		menu:SetPoint('TOPLEFT', 2, -5)
	end

	menu.point = {menu:GetPoint()}

	parent.checkbutton = menu.button

	menu.button:SetHitRectInsets(0, 0 , 0, 0)

	parent.height = parent.height + 24

	return menu
end

--[[ option panels ]]--
local function AddLayoutPanel(menu)
	local panel = menu:NewPanel(L.Layout)

	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewPaddingSlider()
	panel:NewScaleSlider()
	AddSlider(panel, 'Height', 'height', 5, 100, 1)
	AddSlider(panel, 'Width', 'width', 16, 600, 1)
	AddCheckButton(panel, 'Show Icon', 'showIcon')

	return panel
end

local function AddTexturePanel(menu)
	local panel = menu:NewPanel('Textures')

	Dominos.MediaPanel:NewMediaButton(panel, 'Background', 'Background', 'GetBackground', 'SetBackground')

	NewColorPicker(panel, 'Color', 'color')

	Dominos.MediaPanel:NewMediaButton(panel, 'Cast Bar', 'StatusBar', 'GetBarTexture', 'SetTexture')

	AddSlider(panel, 'Background Inset', 'inset', -30, 100, 1)

	return panel
end

local function AddTextPanel(menu)
	local panel = menu:NewPanel('Text')

	AddCheckButton(panel, 'Disable Time', 'hideTime')
	NewMenu(panel, 'Time Format', 'timeFormat', {'Default', 'Percent', 'Fraction'})
	NewMenu(panel, 'Align Time', 'alignTime', {'LEFT', 'CENTER', 'RIGHT'})

	AddCheckButton(panel, 'Disable Text', 'hideText')
	NewMenu(panel, 'Align Text', 'alignText', {'LEFT', 'CENTER', 'RIGHT'})
	NewColorPicker(panel, 'Color', 'textcolor')

	Dominos.MediaPanel:NewMediaButton(panel, 'Font', 'Font', 'GetFont', 'SetFont')

	return panel
end

local function AddStatePanel(menu)
	local panel = menu:NewPanel(L.ShowStates)
	panel.height = 56

	local editBox = CreateFrame('EditBox', panel:GetName() .. 'StateText', panel, 'InputBoxTemplate')
	editBox:SetSize(148, 20)
	editBox:SetPoint('TOPLEFT', 12, -10)
	editBox:SetAutoFocus(false)

	editBox:SetScript('OnShow', function()
		editBox:SetText(panel.owner:GetShowStates() or '')
		editBox:ClearFocus()
	end)

	editBox:SetScript('OnEscapePressed', editBox:GetScript('OnShow'))

	editBox:SetScript('OnEnterPressed', function()
		local text = editBox:GetText()
		panel.owner:SetShowStates(text ~= '' and text or nil)
		editBox:ClearFocus()
	end)

	editBox:SetScript('OnEditFocusLost', function(self)
		self:HighlightText(0, 0)
	end)

	editBox:SetScript('OnEditFocusGained', function(self)
		self:HighlightText()
	end)

	local set = CreateFrame('Button', panel:GetName() .. 'Set', panel, 'UIPanelButtonTemplate')
	set:SetSize(30, 20)
	set:SetText(L.Set)
	set:SetPoint('BOTTOMRIGHT', -8, 2)
	set:SetScript('OnClick', editBox:GetScript('OnEnterPressed'))

	return panel
end

local function AddAdvancedPanel(menu)
	local panel = menu:NewPanel('Advanced')

	panel:NewCheckButton('Left To Right', 'GetLeftToRight', 'SetLeftToRight')
	panel:NewShowInOverrideUICheckbox()
	panel:NewShowInPetBattleUICheckbox()
	AddCheckButton(panel, 'Disable Blizzard', 'hideDefault')

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

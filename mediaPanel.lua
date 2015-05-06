--[[
	Needs rewrite for clarity.
--]]
local Addon = _G['Dominos']
local AddonName = ...
local LibSharedMedia = LibStub('LibSharedMedia-3.0')
local NUM_ITEMS, WIDTH, HEIGHT, OFFSET = 8, 150, 20, 0

--[[ buttons ]]--
local mediaButton = Addon:CreateClass('Button')
do
	function mediaButton:New(id, parent)
		local button = self:Bind(CreateFrame('Button', nil, parent))

		button:SetSize(WIDTH, HEIGHT)
		button:EnableMouse(false)
		button:SetNormalFontObject('GameFontNormal')
		button:SetHighlightFontObject('GameFontHighlight')

		return button
	end

	function mediaButton:Set(mType, filePath, fileName)
		self:SetText(fileName)

		if mType == 'border' then
			self:SetBackdrop({
				edgeFile = filePath,
				edgeSize = 16,
			})
		elseif (mType == 'background') or (mType == 'statusbar') then
			self:SetBackdrop({
				bgFile = filePath,
				tile = false,
			})
		end

		if mType == 'font' then
			self:GetFontString():SetFont(filePath, 12)
			self:SetBackdrop(nil)
		else
			self:GetFontString():SetFont(LibSharedMedia:Fetch('font', 'GameFontNormal'), 12)
		end

		self:GetFontString():SetAllPoints(self)
		self:Show()
	end
end

--[[ panel ]]--
local mediaPanel = Addon:CreateClass('Frame')

do
	function mediaPanel:New(name)
		local panel = self:Bind(CreateFrame('Frame', name, UIParent, 'TranslucentFrameTemplate'))

		-- add close button
		panel.close = CreateFrame('Button', panel:GetName() .. 'CloseButton', panel, 'UIPanelCloseButton')
		panel.close:SetPoint('TopRight', -5, -5)

		-- add title text
		panel.title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
		panel.title:SetPoint('TopLeft', 15, -15)

		-- add scroll area
		panel:CreateScrollArea()

		--add list buttons
		panel:CreateButtons()
		panel:SetSize(WIDTH+40, 50 + (NUM_ITEMS * HEIGHT))
	
		-- panel:SetScript('OnHide', function(self)
		-- 	if self.holding then
		-- 		self.holding:SetChecked(false)
		-- 		self.holding:GetScript('OnShow')(self)
		-- 		self.holding = nil
		-- 	end
		-- end)

		-- make panel close on escape
		tinsert(UISpecialFrames, panel:GetName())

		return panel
	end

	function mediaPanel:CreateScrollArea()
		local panel = self
		local updatePanelList = function() panel:UpdateList() end

		local scroll = CreateFrame('ScrollFrame', panel:GetName() .. 'ScrollFrame', panel, 'FauxScrollFrameTemplate')
		scroll:SetPoint('TOPLEFT', 8, 0)
		scroll:SetPoint('BOTTOMRIGHT', -22, 2)

		local scrollBar = _G[scroll:GetName() .. 'ScrollBar']
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint('TOPLEFT', scroll, 'TOPRIGHT', -6, -50)
		scrollBar:SetPoint('BOTTOMLEFT', scroll, 'BOTTOMRIGHT', -6, 26)



		scroll:SetScript('OnVerticalScroll', function(scroll, arg1)
			FauxScrollFrame_OnVerticalScroll(scroll, arg1, HEIGHT + OFFSET, updatePanelList)
		end)

		scroll:SetScript('OnShow', function()
			panel.buttons[1]:SetWidth(WIDTH)
		end)

		scroll:SetScript('OnHide', function()
			panel.buttons[1]:SetWidth(WIDTH + 20)
		end)

		scroll:SetScript('OnMouseWheel', function(scroll, direction)
			scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
			updatePanelList()
		end)

		scroll:SetScript('OnMouseUp', function()
			local buttons = panel.buttons

			for i, button in pairs(panel.buttons) do
				if MouseIsOver(button) then
					if panel.set then
						panel.set(panel.owner, button:GetText())
						panel:Hide()
					end
				end
			end
		end)

		panel.scroll = scroll
	end

	function mediaPanel:CreateButtons()
		local buttons = {}

		for i = 1, NUM_ITEMS do
			local button = mediaButton:New(i, self)

			if i == 1 then
				button:SetPoint('TOPLEFT', 12, -37)
			else
				button:SetPoint('TOPLEFT', buttons[i - 1], 'BOTTOMLEFT', 0, -OFFSET)
			end

			tinsert(buttons, button)
		end

		self.buttons = buttons
	end

	function mediaPanel:UpdateList()
		FauxScrollFrame_Update(self.scroll, #self.list, #self.buttons, HEIGHT + OFFSET)

		for i,button in pairs(self.buttons) do

			local index = i + self.scroll.offset

			if index <= #self.list then
				local filePath = LibSharedMedia:Fetch(self.mediatype, self.list[index])
				local fileName = self.list[index]

				button:Set(self.mediatype, filePath, fileName)
				button:Show()
			else
				button:Hide()
			end
		end
	end
end

do
	local Media = {}

	function Media:Display(anchor, clicked, mediaType, get, set)
		local panel = self:GetOrCreatePanel()
		local holding = panel.holding

		if holding then
			holding:SetChecked(false)
		end

		if clicked and (panel.holding == clicked) then
			clicked:SetChecked(false)
			panel.holding = nil
			return panel:Hide()
		end

		panel.holding = clicked
		clicked:SetChecked(true)
		panel.owner = anchor.owner
		panel:SetParent(anchor)
		panel.title:SetText(mediaType)
		panel:ClearAllPoints()
		panel:SetPoint('TopLeft', anchor:GetParent(), 'TopRight')
		panel.mediatype = string.lower(mediaType)

		panel.list = LibSharedMedia:List(string.lower(mediaType))
		panel.get = anchor.owner[get]
		panel.set = anchor.owner[set]

		panel:UpdateList()
		panel:Show()
	end

	function Media:GetOrCreatePanel()
		if not self.panel then
			self.panel = mediaPanel:New('DominosMediaPanel')
		end

		return self.panel
	end

	function Media:NewMediaButton(parent, name, mediaType, get, set)
		local button = CreateFrame('CheckButton', ('%sMediaButton%s'):format(parent:GetName(), name), parent, 'UIMenuButtonStretchTemplate')

		button:SetHeight(20)
		button:SetText(name)
		button:SetWidth(button:GetTextWidth()+8)

		button.texture = CreateFrame('Button', button:GetName()..'Display', button)
		button.texture:EnableMouse(false)
		button.texture:SetNormalFontObject('GameFontNormal')
		button.texture:SetHighlightFontObject('GameFontHighlight')
		button.texture:SetAllPoints(button)

		button:SetScript('OnClick', function()
			self:Display(parent, button, mediaType, get, set)
		end)

		-- button:SetScript('OnShow', function()
		-- 	local mtype = string.lower(mediaType)
		-- 	local got = parent.owner[get]
		--
		-- 	print('set', mtype, LibSharedMedia:Fetch(mtype, got(parent.owner)), got(parent.owner))
		-- 	button.texture:SetTexture(mtype, LibSharedMedia:Fetch(mtype, got(parent.owner)), got(parent.owner))
		-- 	button.texture:SetWidth(abs(parent:GetWidth()-(button:GetWidth()))-5)
		-- end)


		button:SetCheckedTexture(button:GetHighlightTexture():GetTexture())

		local prev = parent.checkbutton
		if prev then
			button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -0)
		else
			button:SetPoint('TOPLEFT', 2, -5)
		end

		parent.checkbutton = button
		parent.height = parent.height + 24
	end

	Addon.MediaPanel = Media
end

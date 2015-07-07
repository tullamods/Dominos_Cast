local AddonName = ...
local Addon = LibStub('AceAddon-3.0'):GetAddon(GetAddOnDependencies(AddonName))
local LibSharedMedia = LibStub('LibSharedMedia-3.0')
local NUM_ITEMS, WIDTH, HEIGHT, OFFSET = 8, 150, 20, 0

--[[ buttons ]]--

local mediaButton = Addon:CreateClass('Button')
do
	function mediaButton:New(parent)
		local button = self:Bind(CreateFrame('Button', nil, parent))

		button:SetSize(WIDTH, HEIGHT)
		button:SetNormalFontObject('GameFontNormal')
		button:SetHighlightFontObject('GameFontHighlight')

		button:SetScript('OnEnter', function(self)
			self:GetFontString():SetTextColor(1,1,1,1)
		end)

		button:SetScript('OnLeave', function(self)
			self:GetFontString():SetTextColor(1,1,0,1)
		end)

		return button
	end

	function mediaButton:Set(mType, getFileName)
		local fileName = getFileName()
		local filePath = LibSharedMedia:Fetch(mType, fileName)

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

		local fs = self:GetFontString()

		if fs then
			if mType == 'font' then
				fs:SetFont(filePath, 12)
				self:SetBackdrop(nil)
			else
				fs:SetFont(LibSharedMedia:Fetch('font', 'Friz Quadrata TT'), 12)
			end

			self:GetFontString():SetAllPoints(self)
		end

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
		panel.close:SetPoint('TOPRIGHT', -5, -5)

		-- add title text
		panel.title = panel:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
		panel.title:SetPoint('TOPLEFT', 15, -15)

		-- add scroll area
		panel:CreateScrollArea()

		--add list buttons
		panel:CreateButtons()
		panel:SetSize(WIDTH+40, 50 + (NUM_ITEMS * HEIGHT))

		panel:SetScript('OnHide', function(self)
			if self.holding then
				self.holding:SetChecked(false)
				self.holding:GetScript('OnShow')(self)
				self.holding = nil
			end
		end)

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
		scroll:EnableMouse(false)

		scroll:SetScript('OnEnter', function()
			scroll:SetScript('OnUpdate', function()
				for i, button in pairs(panel.buttons) do
					if MouseIsOver(button) and button:IsShown() then
						if not button.entered then
							button.entered = true
							button:GetScript('OnEnter')(button)
						end
					else
						if button.entered then
							button.entered = nil
							button:GetScript('OnLeave')(button)
						end
					end
				end
			end)
		end)
		scroll:SetScript('OnLeave', function()
			scroll:SetScript('OnUpdate', nil)
		end)
--Convenient, but the mediaButton's need mouseover interaction.
-- [[
		scroll:SetScript('OnMouseUp', function()
			local buttons = panel.buttons
			for i, button in pairs(panel.buttons) do
				if MouseIsOver(button) and button:IsShown() then
					if panel.set then
						panel.set(button:GetText())
						panel:Hide()
					end
				end
			end
		end)
--]]
		scroll:EnableMouse(true)
		panel.scroll = scroll
	end

	function mediaPanel:CreateButtons()
		local buttons = {}

		for i = 1, NUM_ITEMS do
			local button = mediaButton:New(self)

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
				button:Set(self.mediatype, function() return self.list[index] end)
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

		if clicked and (holding == clicked) then
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
		panel:SetPoint('TOPLEFT', anchor:GetParent(), 'TOPRIGHT')
		panel.mediatype = string.lower(mediaType)

		panel.list = LibSharedMedia:List(panel.mediatype)
		panel.get = function() return anchor.owner[get](anchor.owner) end
		panel.set = function(...) return anchor.owner[set](anchor.owner, ...) end

		panel:UpdateList()
		panel:Show()
		
		return panel
	end

	function Media:GetOrCreatePanel()
		if not self.panel then
			self.panel = mediaPanel:New(GetAddOnDependencies(AddonName)..'MediaPanel')
		end
		return self.panel
	end

	function Media:NewMediaButton(parent, name, mediaType, get, set)
		local button = CreateFrame('CheckButton', ('%sMediaButton%s'):format(parent:GetName(), name), parent, 'UIMenuButtonStretchTemplate')

		button:SetHeight(20)
		button:SetText(name)
		button:SetWidth(button:GetTextWidth()+8)

		button.get = function() return parent.owner[get](parent.owner) end
		button.set = function(...) return parent.owner[set](parent.owner, ...) end

		button:SetHitRectInsets(0,-75,0,0)

		button.preview = mediaButton:New(button)
		button.preview:SetPoint('LEFT', button,'RIGHT')
		button.preview:EnableMouse(false)

		button:SetScript('OnClick', function()
			self:Display(parent, button, mediaType, get, set)
		end)

		 button:SetScript('OnShow', function()
			button.preview:Set(string.lower(mediaType), function() return button.get() end)
			 button.preview:SetWidth(abs(parent:GetWidth()-(button:GetWidth()))-5) --don't like this here, but it glitches otherwise. ~Goranaws
		end)

		button:SetCheckedTexture(button:GetHighlightTexture():GetTexture())

		local prev = parent.checkbutton --I'd like to call it parent.button instead, everywhere. ~Goranaws
		if prev then
			button:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -2)
		else
			button:SetPoint('TOPLEFT', 2, -2)
		end

		parent.checkbutton = button
		parent.height = parent.height + 27
		return button
	end

	Addon.MediaPanel = Media
end

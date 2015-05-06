--[[
	Needs rewrite for clarity.
--]]
local Addon = _G["Dominos"]
local SML = LibStub('LibSharedMedia-3.0')
local Media = {}
Addon.MediaPanel = Media

local NUM_ITEMS, WIDTH, HEIGHT, OFFSET = 8, 150, 20, 0

--[[ buttons ]]--
local mediaButton = Addon:CreateClass('Button')
do
	function mediaButton:New(id)
		return self:Create(id)
	end

	function mediaButton:Create(id)
		local button = CreateFrame('Button', self:GetName() .. id, self)
		button:SetWidth(WIDTH)
		button:SetHeight(HEIGHT)
		button:EnableMouse(false)
		button:SetNormalFontObject('GameFontNormal')
		button:SetHighlightFontObject('GameFontHighlight')
		return button
	end
	
	function mediaButton:Set(mType, filePath, fileName)
		if mType == "hide" then
			self:Hide()
			return
		end
		self:SetText(fileName)
		if mType == "border" then
			self:SetBackdrop({
				edgeFile = filePath,
				edgeSize = 16,
			})
		elseif (mType == "background") or (mType == "statusbar") then
			self:SetBackdrop({
				bgFile = filePath,
				tile = false,
			})
		end
		if mType == "font" then
			self:GetFontString():SetFont(filePath, 12)
			self:SetBackdrop(nil)
		else
			self:GetFontString():SetFont(SML:Fetch("font", "GameFontNormal"), 12)
		end
		self:GetFontString():SetAllPoints(self)
		self:Show()
	end
end

--[[ panel ]]--
local mediaPanel = Addon:CreateClass('Frame')




do
	function mediaPanel:New(name)
		return self:Restore(name) or self:Create(name)
	end

	function mediaPanel:Create(name)
		local panel = CreateFrame('Frame', name, UIParent, "TranslucentFrameTemplate")
		tinsert(UISpecialFrames, panel:GetName())
		panel.UpdateList = self.UpdateList
		panel.close = CreateFrame("Button", panel:GetName().."CloseButton", panel, "UIPanelCloseButton")
		panel.close:SetPoint("TopRight", -5, -5)
		panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		panel.title:SetPoint("TopLeft", 15, -15)
		panel:SetScript('OnHide', function(self)
			if self.holding then
				self.holding:SetChecked(false)
				self.holding:GetScript("OnShow")()
				self.holding = nil
			end
		end)
		
		local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', panel, 'FauxScrollFrameTemplate')
		scroll:SetScript('OnVerticalScroll', function(scroll, arg1) FauxScrollFrame_OnVerticalScroll(scroll, arg1, HEIGHT + OFFSET, function() panel:UpdateList() end) end)
		scroll:SetScript('OnShow', function() panel.buttons[1]:SetWidth(WIDTH) end)
		scroll:SetScript('OnHide', function() panel.buttons[1]:SetWidth(WIDTH + 20) end)
		scroll:SetPoint('TOPLEFT', 8, 0)
		scroll:SetPoint('BOTTOMRIGHT', -22, 2)

		local scrollBar = _G[scroll:GetName() .. 'ScrollBar']
		scrollBar:ClearAllPoints()
		scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", -6, -50)
		scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -6, 26)

		scroll:SetScript('OnMouseWheel', function(scroll, direction)
			scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
			panel:UpdateList()
		end)
		scroll:SetScript("OnMouseUp", function()
			local buttons = panel.buttons
			for i, b in pairs(panel.buttons) do
				if MouseIsOver(b) then
					if panel.set then
						panel.set(panel.owner, b:GetText())
						panel:Hide()
					end
				end
			end
		end)
		panel.scroll = scroll
		
		--add list buttons
		panel.buttons = {}
		for i = 1, NUM_ITEMS do
			local button = mediaButton.proto:New(i)
			if i == 1 then
				button:SetPoint('TOPLEFT', 12, -37)
			else
				button:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -OFFSET)
			end
			panel.buttons[i] = b
		end
		panel:SetWidth(WIDTH+40)
		panel:SetHeight(50 + (NUM_ITEMS * HEIGHT))

		return panel
	end

	function mediaPanel:Restore(name)
		return _G[name]
	end
end

function Media:UpdateList()
	FauxScrollFrame_Update(self.scroll, #self.list, #self.buttons, HEIGHT + OFFSET)
	for i,button in pairs(self.buttons) do
		local index = i + self.scroll.offset
		if index <= #self.list then
			local filePath = SML:Fetch(self.mediatype, self.list[index])
			local fileName = self.list[index]
			button:Set(self.mediatype, filePath, fileName)
		else
			button:Set("hide")
		end
	end
end

function Media:Display(anchor, clicked, mediaType, get, set)
	local panel = self:GetPanel()
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
	panel:SetPoint('TopLeft', anchor:GetParent(), "TopRight")
	panel.mediatype = string.lower(mediaType)
	panel.list = SML:List(string.lower(mediaType))
	panel.get = anchor.owner[get]
	panel.set = anchor.owner[set]
	panel:UpdateList()
	panel:Show()
end

function Media:GetPanel()
	if DominosMediaPanel then
		return DominosMediaPanel
	end
	self.panel = mediaPanel.proto:New("DominosMediaPanel")
	return self.panel
end

function Media:NewMediaButton(parent, name, mediaType, get, set)
	local button = CreateFrame("CheckButton", parent:GetName()..name.."MediaButton", parent, "UIMenuButtonStretchTemplate")
	button:SetScript("OnClick", function()
		self:Display(parent, button, mediaType, get, set)
	end)
	button.texture = CreateFrame('Button', button:GetName().."Display", button)
	button:SetHeight(20)
	button:SetText(name)
	button:SetWidth(button:GetTextWidth()+8)
	button.texture:SetHeight(20)
	button.texture:EnableMouse(false)
	button.texture:SetNormalFontObject('GameFontNormal')
	button.texture:SetHighlightFontObject('GameFontHighlight')
	button.texture:SetPoint("Left", button, "Right")
	
	button:SetScript("OnShow", function()
		local mtype = string.lower(mediaType)
		local got = parent.owner[get]
		
		button.texture:Set(mtype, SML:Fetch(mtype, got(parent.owner)), got(parent.owner))
		button.texture:SetWidth(abs(parent:GetWidth()-(button:GetWidth()))-5)
	end)

	
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

--[[
	Needs rewrite for clarity.
--]]
local Addon = _G["Dominos"]
local SML = LibStub('LibSharedMedia-3.0')
local Media = {}
Addon.MediaPanel = Media

local NUM_ITEMS, WIDTH, HEIGHT, OFFSET = 8, 150, 20, 0
function Media:UpdateList()
	FauxScrollFrame_Update(self.scroll, #self.list, #self.buttons, HEIGHT + OFFSET)
	for i,button in pairs(self.buttons) do
		local index = i + self.scroll.offset
		if index <= #self.list then
			local filePath = SML:Fetch(self.mediatype, self.list[index])
			local fileName = self.list[index]
			Media:SetSelectorInfo(button, self.mediatype, filePath, fileName)
		else
			button:Hide()
		end
	end
end

function Media:SetSelectorInfo(button, mType, filePath, fileName)
	button:SetText(fileName)
	if mType == "border" then
		button:SetBackdrop({
			edgeFile = filePath,
			edgeSize = 16,
		})
	elseif (mType == "background") or (mType == "statusbar") then
		button:SetBackdrop({
			bgFile = filePath,
			tile = false,
		})
	end
	if mType == "font" then
		button:GetFontString():SetFont(filePath, 12)
		button:SetBackdrop(nil)
	else
		button:GetFontString():SetFont(SML:Fetch("font", "GameFontNormal"), 12)
	end
	button:GetFontString():SetAllPoints(button)
	button:Show()
end

function Media:Display(anchor, clicked, mediaType, get, set)
	local Media = self:GetPanel()
	local holding = Media.holding
	if holding then
		holding:SetChecked(false)
	end
	if clicked and (Media.holding == clicked) then
		clicked:SetChecked(false)
		Media.holding = nil
		return Media:Hide()
	end
	Media.holding = clicked
	clicked:SetChecked(true)
	Media.owner = anchor.owner
	Media:SetParent(anchor)
	Media.title:SetText(mediaType)
	Media:ClearAllPoints()
	Media:SetPoint('TopLeft', anchor:GetParent(), "TopRight")
	Media.mediatype = string.lower(mediaType)
	Media.list = SML:List(string.lower(mediaType))
	Media.get = anchor.owner[get]
	Media.set = anchor.owner[set]
	Media:UpdateList()
	Media:Show()
end

function Media:GetPanel()
	if DominosMediaPanel then
		return DominosMediaPanel
	end
	self.panel = CreateFrame("Frame", "DominosMediaPanel", UIParent, "TranslucentFrameTemplate")
	tinsert(UISpecialFrames, self.panel:GetName())
	self.panel.UpdateList = self.UpdateList
	self.panel.close = CreateFrame("Button", self.panel:GetName().."CloseButton", self.panel, "UIPanelCloseButton")
	self.panel.close:SetPoint("TopRight", -5, -5)
	self.panel.title = self.panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	self.panel.title:SetPoint("TopLeft", 15, -15)
	self.panel:SetScript('OnHide', function(self)
		if self.holding then
			self.holding:SetChecked(false)
			self.holding:GetScript("OnShow")()
			self.holding = nil
		end
	end)
	local name = self.panel:GetName()
	local scroll = CreateFrame('ScrollFrame', name .. 'ScrollFrame', self.panel, 'FauxScrollFrameTemplate')
	scroll:SetScript('OnVerticalScroll', function(scroll, arg1) FauxScrollFrame_OnVerticalScroll(scroll, arg1, HEIGHT + OFFSET, function() self.panel:UpdateList() end) end)
	scroll:SetScript('OnShow', function() self.panel.buttons[1]:SetWidth(WIDTH) end)
	scroll:SetScript('OnHide', function() self.panel.buttons[1]:SetWidth(WIDTH + 20) end)
	scroll:SetPoint('TOPLEFT', 8, 0)
	scroll:SetPoint('BOTTOMRIGHT', -22, 2)
	local scrollBar = _G[scroll:GetName() .. 'ScrollBar']
	scrollBar:ClearAllPoints()
	scrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", -6, -50)
	scrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -6, 26)
	scroll:SetScript('OnMouseWheel', function(scroll, direction)
		scrollBar:SetValue(scrollBar:GetValue() - direction * (scrollBar:GetHeight()/2))
		self.panel:UpdateList()
	end)
	scroll:SetScript("OnMouseUp", function()
		local buttons = self.panel.buttons
		for i, b in pairs(self.panel.buttons) do
			if MouseIsOver(b) then
				if self.panel.set then
					self.panel.set(self.panel.owner, b:GetText())
					self.panel:Hide()
				end
			end
		end
	end)
	self.panel.scroll = scroll
	--add list buttons
	self.panel.buttons = {}
	for i = 1, NUM_ITEMS do
		local b = CreateFrame('Button', name .. i, self.panel)
		b:SetWidth(WIDTH)
		b:SetHeight(HEIGHT)
		b:EnableMouse(false)
		b:SetNormalFontObject('GameFontNormal')
		b:SetHighlightFontObject('GameFontHighlight')
		if i == 1 then
			b:SetPoint('TOPLEFT', 12, -37)
		else
			b:SetPoint('TOPLEFT', name .. i-1, 'BOTTOMLEFT', 0, -OFFSET)
		end
		self.panel.buttons[i] = b
	end
	self.panel:SetWidth(WIDTH+40)
	self.panel:SetHeight(50 + (NUM_ITEMS * HEIGHT))
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
		self:SetSelectorInfo(button.texture, mtype, SML:Fetch(mtype, got(parent.owner)), got(parent.owner))
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

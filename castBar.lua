
local AddonName, Addon = ...
local Dominos = _G.Dominos

--[[ global references ]]--
local _G = _G

local GetSpellInfo = _G.GetSpellInfo
local GetTime = _G.GetTime

local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo

local IsHarmfulSpell = _G.IsHarmfulSpell
local IsHelpfulSpell = _G.IsHelpfulSpell


--[[ casting bar ]]--

local CastBar = Dominos:CreateClass('Frame', Dominos.Frame)

function CastBar:New(id, unit, ...)
	local bar = CastBar.proto.New(self, id, ...)

	bar.unit = unit
	bar:Layout()
	bar:RegisterEvents()

	return bar
end

function CastBar:OnCreate()
	self:SetFrameStrata('HIGH')
	self:SetScript('OnEvent', self.OnEvent)

	local parent = CreateFrame('Frame', nil, self)
	parent:SetAllPoints(parent:GetParent())
	parent:SetAlpha(0)

	local fout = parent:CreateAnimationGroup()
	fout:SetLooping('NONE')

	local a = fout:CreateAnimation('Alpha')

	a:SetFromAlpha(1)
	a:SetToAlpha(0)
	a:SetDuration(0.5)

	fout:SetScript('OnFinished', function()
		parent:SetAlpha(0)
		self:OnFinished()
	end)

	self.fout = fout

	local fin = parent:CreateAnimationGroup()
	fin:SetLooping('NONE')

	local a = fin:CreateAnimation('Alpha')
	a:SetFromAlpha(0)
	a:SetToAlpha(1)
	a:SetDuration(0.2)

	fin:SetScript('OnFinished', function() parent:SetAlpha(1) end)
	self.fin = fin

	local bg = parent:CreateTexture(nil, 'BACKGROUND')
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(bg:GetParent())
	self.bg = bg

	local icon = parent:CreateTexture(nil, 'ARTWORK')
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	self.icon = icon

	local sb = CreateFrame('StatusBar', nil, parent)
	sb:SetScript('OnValueChanged', function(s, value) self:OnValueChanged(value) end)
	self.statusBar = sb

	local timeText = sb:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	timeText:SetPoint('RIGHT', -2, 0)
	self.timeText = timeText

	local labelText = sb:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	labelText:SetPoint('LEFT', 2, 0)
	self.labelText = labelText

	self.properties = {}

	return self
end

function CastBar:OnLoadSettings()
	self:SetProperty("font", self:GetFontID())
	self:SetProperty("texture", self:GetTextureID())
	self:SetProperty("reaction", "neutral")
end

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		width = 240,
		height = 25,
		padW = 2,
		padH = 2,
		texture = 'blizzard',
		font = 'Friz Quadrata TT',
	}
end

--[[ frame events ]]--

function CastBar:OnEvent(event, ...)
	local func = self[event]
	if func then
		func(self, event, ...)
	end
end

function CastBar:OnUpdateCasting(elapsed)
	local sb = self.statusBar
	local vmin, vmax = sb:GetMinMaxValues()
	local v = sb:GetValue() + elapsed

	if v < vmax then
		sb:SetValue(v)
	else
		sb:SetValue(vmax)
		self:SetProperty("state", nil)
	end
end

function CastBar:OnUpdateChanneling(elapsed)
	local sb = self.statusBar
	local vmin, vmax = sb:GetMinMaxValues()
	local v = sb:GetValue() - elapsed

	if v > vmin then
		sb:SetValue(v)
	else
		sb:SetValue(vmin)
		self:SetProperty("state", nil)
	end
end

function CastBar:OnValueChanged(value)
	self.timeText:SetFormattedText('%.1f', value)
end

function CastBar:OnFinished()
	self:Reset()
end

--[[ game events ]]--

function CastBar:PLAYER_ENTERING_WORLD()
	if not (self:UpdateChannelling() or self:UpdateCasting()) then
		self:SetProperty("state", nil)
	end
end

function CastBar:UNIT_SPELLCAST_START(event, unit, ...)
	if unit ~= self.unit then return end

	self:Reset()
	self:UpdateCasting()
	self:SetProperty("state", "start")
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit, ...)
	if unit ~= self.unit then return end

	self:SetProperty("state", nil)
end

function CastBar:UNIT_SPELLCAST_FAILED(event, unit, ...)
	if unit ~= self.unit then return end

	self:SetProperty("reaction", "failed")
	self:SetProperty("label", _G.FAILED)
	self:SetProperty("state", nil)
end

function CastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit, ...)
	if unit ~= self.unit then return end

	self:SetProperty("reaction", "interrupted")
	self:SetProperty("label", _G.INTERRUPTED)
	self:SetProperty("state", nil)
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit, ...)
	if unit ~= self.unit then return end

	self:UpdateCasting()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit, ...)
	if unit ~= self.unit then return end

	self:Reset()
	self:UpdateChannelling()
	self:SetProperty("state", "start")
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, ...)
	if unit ~= self.unit then return end

	self:UpdateChannelling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, ...)
	if unit ~= self.unit then return end

	self:SetProperty("state", nil)
end

function CastBar:MIRROR_TIMER_START(event, name, value, maxvalue, step, pause, label)
	self:SetProperty("mt_" .. name, true)
end

function CastBar:MIRROR_TIMER_STOP(event, name)
	self:SetProperty("mt_" .. name, nil)
end

function CastBar:MIRROR_TIMER_PAUSE(event, duration)
end

function CastBar:RegisterEvents()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')

	self:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
	self:RegisterEvent('UNIT_SPELLCAST_DELAYED')
	self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
	self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_UPDATE')
	self:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')

	self:RegisterUnitEvent('UNIT_SPELLCAST_START', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_STOP', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_FAILED', unit)

	self:RegisterEvent('MIRROR_TIMER_PAUSE')
	self:RegisterEvent('MIRROR_TIMER_STOP')
end


--[[ attribute events ]]--

function CastBar:mode_update(mode)
	if mode == 'cast' then
		self:SetScript('OnUpdate', self.OnUpdateCasting)
	elseif mode == 'channel' then
		self:SetScript('OnUpdate', self.OnUpdateChanneling)
	elseif mode == 'demo' then
		self:SetupDemo()
	end
end

function CastBar:state_update(state)
	if state == "start" then
		self.fout:Stop()
		self.fin:Play()
	else
		self:SetScript('OnUpdate', nil)
		self.fin:Stop()
		self.fout:Play()
	end
end

function CastBar:label_update(text)
	self.labelText:SetText(text or '')
end

function CastBar:time_update(text)
	self.timeText:SetText(text or '')
end

function CastBar:icon_update(texture)
	local icon = self.icon
	if texture then
		icon:SetTexture(texture)
		icon:Show()
	else
		icon:Hide()
	end
end

function CastBar:spell_update(spellID)
	if spellID and IsHelpfulSpell(spellID) then
		self:SetProperty("reaction", "help")
	elseif spellID and IsHarmfulSpell(spellID) then
		self:SetProperty("reaction", "harm")
	else
		self:SetProperty("reaction", "neutral")
	end
end

function CastBar:reaction_update(reaction)
	if reaction == "failed" or reaction == "interrupted" then
		self.statusBar:SetStatusBarColor(1, 0, 0)
	elseif reaction == "help" then
		self.statusBar:SetStatusBarColor(0.31, 0.78, 0.47)
	elseif reaction == "harm" then
		self.statusBar:SetStatusBarColor(0.63, 0.36, 0.94)
	else
		self.statusBar:SetStatusBarColor(1, 0.7, 0)
	end
end

function CastBar:font_update(fontID)
	self.sets.font = fontID

	local newFont = LibStub('LibSharedMedia-3.0'):Fetch('font', fontID)
	local oldFont, fontSize, fontFlags = self.labelText:GetFont()

	if newFont and newFont ~= oldFont then
		self.labelText:SetFont(newFont, fontSize, fontFlags)
		self.timeText:SetFont(newFont, fontSize, fontFlags)
	end
end

function CastBar:texture_update(textureID)
	local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', textureID)

	self.bg:SetTexture(texture)
	self.bg:SetVertexColor(0, 0, 0, 0.5)
	self.statusBar:SetStatusBarTexture(texture)
end

--[[ updates ]]--

function CastBar:SetProperty(key, value)
	local oldValue = self.properties[key]

	if oldValue ~= value then
		self.properties[key] = value

		local func = self[key .. '_update']
		if func then
			func(self, value, oldValue)
		end
	end
end

function CastBar:GetProperty(key)
	return self.properties[key]
end

function CastBar:Layout()
	local padding = self:GetPadding()
	local width, height = self:GetDesiredWidth(), self:GetDesiredHeight()

	self:SetSize(width, height)

	self.icon:SetPoint('TOPLEFT', padding, -padding)
	self.icon:SetPoint('BOTTOMLEFT', padding, padding)
	self.icon:SetWidth(height - padding * 2)

	self.statusBar:SetPoint('TOPLEFT', self.icon, 'TOPRIGHT', 1, 0)
	self.statusBar:SetPoint('BOTTOMLEFT', self.icon, 'BOTTOMRIGHT', 1, 0)
	self.statusBar:SetPoint('RIGHT', -padding, 0)

	return self
end

function CastBar:UpdateChannelling()
	local name, nameSubtext, text, texture, startTime, endTime = UnitChannelInfo(self.unit)

	if name then
		self:SetProperty('mode', 'channel')
		self:SetProperty('label', text)
		self:SetProperty('icon', texture)
		self:SetProperty('spell', GetSpellInfo(name))

		local sb = self.statusBar
		sb:SetMinMaxValues(0, (endTime - startTime) / 1000)
		sb:SetValue(endTime / 1000 - GetTime())

		return true
	end

	return false
end

function CastBar:UpdateCasting()
	local name, nameSubtext, text, texture, startTime, endTime = UnitCastingInfo(self.unit)

	if name then
		self:SetProperty('mode', 'cast')
		self:SetProperty('label', text)
		self:SetProperty('icon', texture)
		self:SetProperty('spell', GetSpellInfo(name))

		local sb = self.statusBar
		sb:SetMinMaxValues(0, (endTime - startTime) / 1000)
		sb:SetValue(GetTime() - startTime / 1000)

		return true
	end

	return false
end

function CastBar:Reset()
	self:SetProperty('state', nil)
	self:SetProperty('mode', nil)
	self:SetProperty('label', nil)
	self:SetProperty('icon', nil)
	self:SetProperty('spell', nil)
	self:SetProperty('reaction', nil)
end

function CastBar:SetupDemo()
	local spellID = self:GetRandomSpellID()
	local name, rank, icon = GetSpellInfo(spellID)

	self:SetProperty("label", name)
	self:SetProperty("icon", icon)
	self:SetProperty("spell", spellID)

	self.statusBar:SetMinMaxValues(0, 1)
	self.statusBar:SetValue(1)
end

function CastBar:GetRandomSpellID()
	local spells = {}
	local offset = 0

	for i = 1, GetNumSpellTabs() do
		local offset, numSpells = select(3, GetSpellTabInfo(i))
		local tabEnd = offset + numSpells

		for j = offset, tabEnd - 1 do
			local _, spellID = GetSpellBookItemInfo(j, 'player')
			if spellID then
				table.insert(spells, spellID)
			end
		end
	end

	return spells[math.random(1, #spells)]
end


--[[ settings ]]--

function CastBar:SetDesiredWidth(width)
	self.sets.width = width
	self:Layout()
end

function CastBar:GetDesiredWidth()
	return self.sets.width or 240
end

function CastBar:SetDesiredHeight(height)
	self.sets.height = height
	self:Layout()
end

function CastBar:GetDesiredHeight()
	return self.sets.height or 25
end


--font
function CastBar:SetFontID(fontID)
	self.sets.font = fontID
	self:SetProperty('font', fontID)

	return self
end

function CastBar:GetFontID()
	return self.sets.font or 'Friz Quadrata TT'
end

--texture
function CastBar:SetTextureID(textureID)
	self.sets.texture = textureID
	self:SetProperty('texture', textureID)

	return self
end

function CastBar:GetTextureID()
	return self.sets.texture or 'blizzard'
end


--[[ menu ]]--

do
	function CastBar:CreateMenu()
		local menu = Dominos:NewMenu(self.id)

		self:AddLayoutPanel(menu)
		self:AddTexturePanel(menu)
		self:AddFontPanel(menu)

		self.menu = menu

		self.menu:HookScript('OnShow', function()
			self:SetProperty("mode", "demo")
			self:SetProperty("state", "start")
		end)

		self.menu:HookScript('OnHide', function()
			if self:GetProperty("mode") == "demo" then
				self:SetProperty("state", nil)
			end
		end)

		return menu
	end

	function CastBar:AddLayoutPanel(menu)
		local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')

		panel.widthSlider = panel:NewSlider{
			name = l.Width,

			min = 1,

			max = function()
				return math.ceil(_G.UIParent:GetWidth() / panel.owner:GetScale())
			end,

			get = function()
				return panel.owner:GetDesiredWidth()
			end,

			set = function(_, value)
				panel.owner:SetDesiredWidth(value)
			end,
		}

		panel.heightSlider = panel:NewSlider{
			name = l.Height,

			min = 1,

			max = function()
				return math.ceil(_G.UIParent:GetHeight() / panel.owner:GetScale())
			end,

			get = function()
				return panel.owner:GetDesiredHeight()
			end,

			set = function(_, value)
				panel.owner:SetDesiredHeight(value)
			end,
		}

		-- panel.spacingSlider = panel:NewSpacingSlider()
		panel.paddingSlider = panel:NewPaddingSlider()
		panel.scaleSlider = panel:NewScaleSlider()
		panel.opacitySlider = panel:NewOpacitySlider()
		panel.fadeSlider = panel:NewFadeSlider()
	end

	function CastBar:AddFontPanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')
		local panel = menu:NewPanel(l.Font)

		panel.fontSelector = Dominos.Options.FontSelector:New{
			parent = panel,

			get = function()
				return panel.owner:GetFontID()
			end,

			set = function(_, value)
				panel.owner:SetFontID(value)
			end,
		}
	end

	function CastBar:AddTexturePanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')
		local panel = menu:NewPanel(l.Texture)

		panel.textureSelector = Dominos.Options.TextureSelector:New{
			parent = panel,

			get = function()
				return panel.owner:GetTextureID()
			end,

			set = function(_, value)
				panel.owner:SetTextureID(value)
			end,
		}
	end
end

--[[ exports ]]--

Addon.CastBar = CastBar
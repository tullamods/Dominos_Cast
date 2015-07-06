local AddonName = ...
local Addon = LibStub('AceAddon-3.0'):GetAddon(GetAddOnDependencies(AddonName))
local LSM = LibStub('LibSharedMedia-3.0', true)

local CastBar = Addon:CreateClass('Frame', Addon.Frame)

--[[ frame creation ]]--

function CastBar:New()
	return CastBar.proto.New(self, 'cast')
end

local function check(source, target)
	--you may now add new defaults at will. ~Goranaws
	if (not target) or (type(target) ~= 'table') then
		target = {}
	end
	for key, value in pairs(source) do
		if type(value) == 'table' then
			target[key] =check(value, target[key])
		else
			if (type(value) == 'boolean') then
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

	bar.cast = CreateFrame('StatusBar',  bar:GetName()..'Bar', bar.header, 'CastingBarFrameTemplate')
	bar.cast:Hide()
	bar.cast:SetPoint('CENTER')
	bar.cast.unit = 'player'
	bar.cast:SetAttribute('unit', 'player')
	CastingBarFrame_SetLook(bar.cast, 'UNITFRAME')
	bar.cast:HookScript('OnUpdate', bar.SetTime)

	bar.cast.time = bar.cast:CreateFontString(nil, 'OVERLAY', 'TextStatusBarText')
	bar.cast.time:SetTextColor(1, 1, 1)

	bar.skin = CreateFrame('Frame', bar:GetName() .. 'Skin', bar.cast)
	bar.skin:SetFrameLevel(bar:GetFrameLevel() - 1)
	bar.skin:SetPoint('CENTER', bar)

	bar.cast.border:SetParent(MainMenuBarArtFrame)
	bar.cast.borderShield:SetParent(MainMenuBarArtFrame)

	bar.cast.barFlash:SetTexture([[Interface\Cooldown\star4]])
	bar.cast.barFlash:SetVertexColor(0, 1, 0, 1)
	bar.cast.barFlash:SetBlendMode('ADD')
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

		color = { r = 0, g = 0, b = 0, a = 1 },

		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],

		timeFormat = 'Default',

		alignText = 'LEFT',

		alignTime = 'RIGHT',

		texture = [[Interface\TargetingFrame\UI-StatusBar]],

		font = 'Friz Quadrata TT',

		textcolor = { r = 1,g = 1,b = 1,a = 1 },

		hideDefault = true,
	}
end

--[[ update functions ]]--
function CastBar:Layout()
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
	self.skin:SetSize(w, h)
	local offset = 0
	if self.sets.showIcon then
		offset = 19
	end
	self.cast:SetSize(w-offset, h)

	local point = 'RIGHT'
	if self.sets.isRightToLeft then
		point = 'LEFT'
	end

	self.cast:ClearAllPoints()
	self.cast:SetPoint(point, self.skin)
end

function CastBar:UpdateIcon()
	if self.sets.showIcon then
		self.cast.icon:Show()

		local point = 'LEFT'
		if self.sets.isRightToLeft then
			point = 'RIGHT'
		end

		self.cast.icon:ClearAllPoints()
		self.cast.icon:SetPoint(point, self.skin)
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
	self.skin:SetBackdrop({
		bgFile = LSM and LSM:Fetch('background', self.sets.bgFile),
		insets = {left = -self.sets.inset, right = -self.sets.inset, top = -self.sets.inset, bottom = -self.sets.inset},
		tile = false,
	})
	self.skin:SetBackdropColor(self.sets.color.r, self.sets.color.g, self.sets.color.b, self.sets.color.a)
	local castTexture = (LSM and LSM:Fetch('statusbar', self.sets.texture)) or DEFAULT_STATUSBAR_TEXTURE
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
		time:SetPoint('RIGHT', self.cast, -2, 0)
		text:SetPoint('LEFT', self.cast, 2, 0)
		text:SetPoint('RIGHT', time, 'LEFT')
	else
		time:SetPoint('LEFT', self.cast, 2, 0)
		text:SetPoint('RIGHT', self.cast, -2, 0)
		text:SetPoint('LEFT', time, 'RIGHT')

		if textAlign == 'LEFT' then
			textAlign = 'RIGHT'
		elseif textAlign == 'RIGHT' then
			textAlign = 'LEFT'
		end
		if timeAlign == 'LEFT' then
			timeAlign = 'RIGHT'
		elseif timeAlign == 'RIGHT' then
			timeAlign = 'LEFT'
		end
	end

	text:SetJustifyH(textAlign)
	time:SetJustifyH(timeAlign)

	local font = LSM:Fetch('font', self.sets.font)
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
		time.hidden = true
	else
		time:SetAlpha(1)
		time.hidden = nil
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
		if style == 'Default' then
			text = string.format('%.1f', (endTime / 1000) - time)
		elseif style == 'Percent' then
			text = string.format('%.0f', ((time - (startTime / 1000)) / ((endTime- startTime)/1000))*100)..'%'
		elseif style == 'Fraction' then
			text = string.format('%.1f', time - (startTime / 1000) )..'/'..string.format('%.1f', (endTime- startTime)/1000)
		end

		self.time:SetText(text or '')
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

--[[ bar settings ]]--

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

--[[ menu hooks ]]

function CastBar:CreateMenu()
	self.menu = Addon:CreateMenu(self)
end

--[[ exports ]]--

Addon.NewCastBar = function(self)
	return CastBar:New()
end

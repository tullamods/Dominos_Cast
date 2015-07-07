local AddonName = ...
local Addon = LibStub('AceAddon-3.0'):GetAddon(GetAddOnDependencies(AddonName))

local Module = Addon:NewModule('CastBar')

function Module:Load()
	self.frame = Addon:NewCastBar()
end

function Module:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end

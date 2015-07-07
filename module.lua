local AddonName, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')

local CastBarModule = Dominos:NewModule('CastBar')

function CastBarModule:Load()
	self.frame = Addon:NewCastBar()
end

function CastBarModule:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end

AddCSLuaFile("shared.lua")
include("shared.lua")

--------------------------------------------------------------------------------
function ENT:Initialize()
	self:SetModel("models/props_lab/binderredlabel.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
end

function ENT:Use(ply) 
	ply:ConCommand("metrostroi_train_manual")
end
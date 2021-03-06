﻿--------------------------------------------------------------------------------
-- Тяговый электродвигатель постоянного тока (ДК-117ДМ)
--------------------------------------------------------------------------------
Metrostroi.DefineSystem("DK_117DM")

function TRAIN_SYSTEM:Initialize()
	self.Name = "DK_117DM"
	
	-- Speed of train in km/h
	self.Speed = 0
	
	-- Winding resistance
	self.Rw = 0.0691 -- Ohms
	
	-- Voltage generated by engine
	self.E13 = 0.0 -- Volts
	self.E24 = 0.0 -- Volts
	
	-- Rotation rate
	self.RotationRate = 0.0
	
	-- Magnetic flux in the engine
	self.MagneticFlux13 = 0.0
	self.MagneticFlux24 = 0.0
	
	-- Moment generated by the engine
	self.Moment13 = 0.0
	self.Moment24 = 0.0
	self.BogeyMoment = 0.0 -- Moment on front and rear bogey is equal
	
	-- Need many iterations for engine simulation to converge
	self.SubIterations = 16
end

function TRAIN_SYSTEM:Inputs()
	return { "Speed" }
end

function TRAIN_SYSTEM:Outputs()
	return { "MagneticFlux13", "MagneticFlux24", "RotationRate", 
			 "E13", "E24", "Moment13", "Moment24",
			 "FieldReduction13","FieldReduction24",
			 "BogeyMoment" }
end

function TRAIN_SYSTEM:TriggerInput(name,value)
	if name == "Speed" then
		self.Speed = value
	end
end

function TRAIN_SYSTEM:Think(dT)
	local Train = self.Train
	local minimumFlux = 0.2 -- Set some minimum flux to simulate random fluctuation which can excite the field
	local Iste = 0 -- Подмагничивание при низких токах

	-- Calculate magnetic flux in the engine
	currentMagneticFlux13 = (1.0/40.0) * 100.0*(1-math.exp(-2.5*(Train.Electric.Istator13+Iste)/100))
	currentMagneticFlux24 = (1.0/40.0) * 100.0*(1-math.exp(-2.5*(Train.Electric.Istator24+Iste)/100))
	--currentMagneticFlux13 = (1.0/40.0) * Train.Electric.Istator13
	--currentMagneticFlux24 = (1.0/40.0) * Train.Electric.Istator24
	currentMagneticFlux13 = math.min(5.0,math.max(minimumFlux,currentMagneticFlux13))
	currentMagneticFlux24 = math.min(5.0,math.max(minimumFlux,currentMagneticFlux24))
	
	self.MagneticFlux13 = self.MagneticFlux13 + 8.0 * (currentMagneticFlux13 - self.MagneticFlux13) * dT
	self.MagneticFlux24 = self.MagneticFlux24 + 8.0 * (currentMagneticFlux24 - self.MagneticFlux24) * dT

	-- Get rate of engine rotation
	local currentRotationRate = 2200 * (self.Speed/90)
	self.RotationRate = self.RotationRate + 5.0 * (currentRotationRate - self.RotationRate) * dT
	
	-- Calculate voltage generated by engines from magnetic flux
	self.E13 = 0.300 * self.RotationRate * self.MagneticFlux13
	self.E24 = 0.300 * self.RotationRate * self.MagneticFlux24
	
	self.E13 = math.max(-2000,math.min(2000,self.E13))
	self.E24 = math.max(-2000,math.min(2000,self.E24))

	-- Calculate engine force (moment)
	self.Moment13 = (1.0/400.0) * Train.Electric.I13 * self.MagneticFlux13
	self.Moment24 = (1.0/400.0) * Train.Electric.I24 * self.MagneticFlux24
	
	-- Apply moment to bogeys
	if (math.abs(Train.Electric.I13) > 1.0) or (math.abs(Train.Electric.I24) > 1.0) then
		self.BogeyMoment = (self.Moment13 + self.Moment24) / 2
	else
		self.BogeyMoment = 0.0
	end
	
	-- Calculate reduction in magnetic field
	self.FieldReduction13 = math.abs(100 * Train.Electric.Istator13 / (Train.Electric.I13+1e-9))
	self.FieldReduction24 = math.abs(100 * Train.Electric.Istator24 / (Train.Electric.I24+1e-9))
end

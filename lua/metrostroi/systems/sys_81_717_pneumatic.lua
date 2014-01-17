--------------------------------------------------------------------------------
-- Пневматическая система 81-717
--------------------------------------------------------------------------------
Metrostroi.DefineSystem("81_717_Pneumatic")

function TRAIN_SYSTEM:Initialize()
	-- Maximum pneumatic brake force at P = 4.5 atm
	self.PneumaticBrakeForce = 60000.0
	-- Pressure in reservoir
	self.ReservoirPressure = 0.0 -- atm
	-- Pressure in trains feed line
	self.TrainLinePressure = 7.0 -- atm
	-- Pressure in trains brake line
	self.BrakeLinePressure = 0.0 -- atm
	-- Pressure in brake cylinder
	self.BrakeCylinderPressure = 0.0 -- atm
	
	
	-- Position of the train drivers valve
	-- 1 Charge/brake release
	-- 2 Driving
	-- 3 Closed
	-- 4 Service application
	-- 5 Emergency application
	self.DriverValvePosition = 1

	-- Rate of brake line filling from train line
	self.BrakeLineFillRate			= 0.500 -- atm/sec
	-- Rate of equalizing reservoir filling from train line
	self.ReservoirFillRate			= 1.500 -- atm/sec
	-- Replenish rate for brake line
	self.BrakeLineReplenishRate 	= 0.100 -- atm/sec
	-- Replenish rate for reservoir
	self.ReservoirReplenishRate 	= 1.000 -- atm/sec
	-- Release to atmosphere rate
	self.ReservoirReleaseRate	 	= 1.500 -- atm/sec

	-- Rate of pressure leak from reservoir
	self.ReservoirLeakRate			= 1e-3	-- atm/sec
	-- Rate of pressure leak from brake line
	self.BrakeLineLeakRate			= 1e-4	-- atm/sec
	-- Rate of release to reservoir
	self.BrakeLineReleaseRate	 	= 0.350 -- atm/sec

	-- Emergency release rate
	self.BrakeLineEmergencyRate 	= 0.800 -- atm/sec
	
	
	-- Valve #1
	self.Train:LoadSystem("PneumaticNo1","Relay")
	-- Valve #2
	self.Train:LoadSystem("PneumaticNo2","Relay")
end

function TRAIN_SYSTEM:Inputs()
	return { "BrakeUp", "BrakeDown", "BrakeSet"}
end

function TRAIN_SYSTEM:Outputs()
	return { "BrakeLinePressure", "BrakeCylinderPressure", "DriverValvePosition", 
			 "ReservoirPressure", "TrainLinePressure" }
end

function TRAIN_SYSTEM:TriggerInput(name,value)
	if name == "BrakeSet" then
		self.DriverValvePosition = math.floor(value)
		if self.DriverValvePosition < 1 then self.DriverValvePosition = 1 end
		if self.DriverValvePosition > 5 then self.DriverValvePosition = 5 end
		
		self.Train:PlayOnce("switch",true)
	elseif (name == "BrakeUp") and (value > 0.5) then
		self:TriggerInput("BrakeSet",self.DriverValvePosition+1)
	elseif (name == "BrakeDown") and (value > 0.5) then
		self:TriggerInput("BrakeSet",self.DriverValvePosition-1)
	end
end

function TRAIN_SYSTEM:Think(dT)
	-- Apply specific rate to equalize pressure
	local function equalizePressure(pressure,target,rate,fill_rate)
		if fill_rate and (target > self[pressure]) then rate = fill_rate end
		
		-- Calculate derivative
		local dPdT = rate
		if target < self[pressure] then dPdT = -dPdT end
		local dPdTramp = math.min(1.0,math.abs(target - self[pressure])*1.0)
		dPdT = dPdT*dPdTramp

		-- Update pressure
		self[pressure] = self[pressure] + dT * dPdT
		self[pressure] = math.max(0.0,math.min(7.0,self[pressure]))
		self[pressure.."_dPdT"] = (self[pressure.."_dPdT"] or 0) + dPdT
		return dPdT
	end
	
	
	-- Pressure at train line
	self.TrainToBrakeValvePressure = self.TrainLinePressure*0.70
	
	-- Accumulate derivatives
	self.BrakeLinePressure_dPdT = 0.0
	self.ReservoirPressure_dPdT = 0.0
	self.BrakeCylinderPressure_dPdT = 0.0

	-- Fill reservoir from train line, fill brake line from train line
	if (self.DriverValvePosition == 1) then
		equalizePressure("BrakeLinePressure", self.TrainToBrakeValvePressure, self.BrakeLineFillRate)
		equalizePressure("ReservoirPressure", self.TrainToBrakeValvePressure, self.ReservoirFillRate)
	end
	-- Brake line, reservoir replenished from train line
	if (self.DriverValvePosition == 2) then
		equalizePressure("BrakeLinePressure", self.TrainToBrakeValvePressure, self.BrakeLineReplenishRate)
		equalizePressure("ReservoirPressure", self.TrainToBrakeValvePressure, self.ReservoirReplenishRate)
	end
	-- Equalize pressure between reservoir and brake line
	if self.DriverValvePosition == 3 then
		equalizePressure("ReservoirPressure", self.BrakeLinePressure, self.ReservoirReleaseRate,self.ReservoirFillRate)
		equalizePressure("BrakeLinePressure", self.ReservoirPressure, self.BrakeLineReleaseRate,self.BrakeLineFillRate)
	end
	-- Reservoir open to atmosphere, brake line open to reservoir
	if self.DriverValvePosition == 4 then
		equalizePressure("ReservoirPressure", 0.0,					  self.ReservoirReleaseRate)
		equalizePressure("BrakeLinePressure", self.ReservoirPressure, self.BrakeLineReleaseRate)
	end
	-- Reservoir and brake line open to atmosphere
	if self.DriverValvePosition == 5 then
		equalizePressure("ReservoirPressure", 0.0, self.ReservoirReleaseRate)
		equalizePressure("BrakeLinePressure", 0.0, self.BrakeLineEmergencyRate)
	end
	
	-- Brake line leaks
	equalizePressure("BrakeLinePressure", 0.0, self.BrakeLineLeakRate)
	-- Reservoir leaks
	equalizePressure("ReservoirPressure", 0.0, self.ReservoirLeakRate)
	
	-- Calculate brake line pressure as seen by cylinders
	self.BrakeLineToCylinderValve = self.BrakeLinePressure
	
	-- Valve #1
	if self.Train.PneumaticNo1.Value == 1.0 then
		self.BrakeLineToCylinderValve = self.BrakeLineToCylinderValve * 0.65
	end
	
	-- Fill cylinders
	equalizePressure("BrakeCylinderPressure", 
		self.TrainToBrakeValvePressure - self.BrakeLineToCylinderValve, self.BrakeLineFillRate)
	

	--print(Format("%.3f  %.3f  %.3f  %.3f atm",
		--self.BrakeLinePressure,self.ReservoirPressure,self.TrainLinePressure,self.BrakeCylinderPressure))	
	--print(Format("%.3f  %.3f  %.3f  %.3f atm/sec",
		--self.BrakeLinePressure_dPdT,self.ReservoirPressure_dPdT,self.TrainLinePressure_dPdT or 0,self.BrakeCylinderPressure_dPdT))
	--print(self.DriverValvePosition)
	
	-- Apply brakes
	self.PneumaticBrakeForce = 110000.0
	self.Train.FrontBogey.PneumaticBrakeForce = self.PneumaticBrakeForce 
	self.Train.FrontBogey.BrakeCylinderPressure = self.BrakeCylinderPressure
	self.Train.FrontBogey.BrakeCylinderPressure_dPdT = -self.BrakeCylinderPressure_dPdT ---self.BrakeCylinderPressure_dPdT
	self.Train.RearBogey.PneumaticBrakeForce = self.PneumaticBrakeForce
	self.Train.RearBogey.BrakeCylinderPressure = self.BrakeCylinderPressure
	self.Train.RearBogey.BrakeCylinderPressure_dPdT = -self.BrakeCylinderPressure_dPdT ---self.BrakeCylinderPressure_dPdT
	
	-- Output
	self:TriggerOutput("DriverValvePosition", 		self.DriverValvePosition)
	self:TriggerOutput("BrakeLinePressure", 		self.BrakeLinePressure)
	self:TriggerOutput("BrakeCylinderPressure",  	self.BrakeCylinderPressure)
	self:TriggerOutput("ReservoirPressure", 		self.ReservoirPressure)
	self:TriggerOutput("TrainLinePressure",			self.TrainLinePressure)
end

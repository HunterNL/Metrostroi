AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")



--------------------------------------------------------------------------------
function ENT:Initialize()
	-- Initialize physics for the selected model
	if self:GetModel() == "models/error.mdl" then
		self:SetModel("models/props_lab/reciever01a.mdl")
	end
	if not self.NoPhysics then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	else
		self:SetSolid(SOLID_VPHYSICS)
	end
	self:SetUseType(SIMPLE_USE)
	
	-- Possible number of train wires
	self.TrainWireCount = self.TrainWireCount or 32
	-- Train wires
	self:ResetTrainWires()
	-- Systems defined in the train
	self.Systems = {}
	-- Initialize train systems
	self:InitializeSystems()
	-- Initialize highspeed interface
	self:InitializeHighspeedLayout()
	
	-- Prop-protection related
	if CPPI and self.Owner then
		self:CPPISetOwner(self.Owner)
	end

	-- Initialize wire interface
	self.WireIOSystems = self.WireIOSystems or { "KV", "ALS_ARS", "DURA", "Pneumatic" }
	if Wire_CreateInputs then
		local inputs = {}
		local outputs = {}
		local inputTypes = {}
		local outputTypes = {}
		for _,name in pairs(self.WireIOSystems) do
			local v = self.Systems[name]
			if v then
				local i = v:Inputs()
				local o = v:Outputs()
				
				for _,v2 in pairs(i) do 
					if type(v2) == "string" then
						table.insert(inputs,(v.Name or "")..v2) 
						table.insert(inputTypes,"NORMAL")
					elseif type(v2) == "table" then
						table.insert(inputs,(v.Name or "")..v2[1])
						table.insert(inputTypes,v2[2])
					else
						ErrorNoHalt("Invalid wire input for metrostroi subway entity")
					end
				end
				
				for _,v2 in pairs(o) do 
					if type(v2) == "string" then
						table.insert(outputs,(v.Name or "")..v2) 
						table.insert(outputTypes,"NORMAL")
					elseif type(v2) == "table" then
						table.insert(outputs,(v.Name or "")..v2[1])
						table.insert(outputTypes,v2[2])
					else
						ErrorNoHalt("Invalid wire output for metrostroi subway entity")
					end
				end
			end
		end
		
		-- Add input for a custom driver seat
		table.insert(inputs,"DriverSeat")
		table.insert(inputTypes,"ENTITY")
		
		-- Add input for wrench
		table.insert(inputs,"DriversWrenchPresent")
		table.insert(inputTypes,"NORMAL")
		
		-- Add I/O for train wires
		if self.SubwayTrain then
			--for i=1,self.TrainWireCount do
			for i=1,20 do
				table.insert(inputs,"TrainWire"..i)
				table.insert(inputTypes,"NORMAL")
				table.insert(outputs,"TrainWire"..i)
				table.insert(outputTypes,"NORMAL")
			end
		end
		
		self.Inputs = WireLib.CreateSpecialInputs(self,inputs,inputTypes)
		self.Outputs = WireLib.CreateSpecialOutputs(self,outputs,outputTypes)
	end

	-- Setup drivers controls
	self.ButtonBuffer = {}
	self.KeyBuffer = {}
	self.KeyMap = {}
	
	-- Override for if drivers wrench is present
	self.DriversWrenchPresent = false
	
	-- External interaction areas
	self.InteractionAreas = {}

	-- Joystick module support
	if joystick then
		self.JoystickBuffer = {}
	end
	self.DebugVars = {}

	-- Entities that belong to train and must be cleaned up later
	self.TrainEntities = {}
	-- All the sitting positions in train
	self.Seats = {}
	-- List of headlights, dynamic lights, sprite lights
	self.Lights = {}
	
	-- Cross-connections in train wires
	self.TrainWireCrossConnections = {}
	-- Overrides for train wire values from wiremod interface
	self.TrainWireOverrides = {}

	-- Load sounds
	self:InitializeSounds()
	
	-- Is this train 'odd' or 'even' in coupled set
	self.TrainCoupledIndex = 0
	
	-- Speed and acceleration of train
	self.Speed = 0
	self.Acceleration = 0
	
	-- Initialize train
	if Turbostroi and (not self.NoPhysics) then
		Turbostroi.InitializeTrain(self)
	end
	
	-- Passenger related data (must be set by derived trains to allow boarding)
	self.LeftDoorsOpen = false
	self.LeftDoorsBlocked = false
	self.LeftDoorPositions = { Vector(0,0,0) }
	self.RightDoorsOpen = false
	self.RightDoorsBlocked = false
	self.RightDoorPositions = { Vector(0,0,0) }
	self:SetPassengerCount(0)
	
	-- Get default train mass
	if IsValid(self:GetPhysicsObject()) then
		self.NormalMass = self:GetPhysicsObject():GetMass()
	end
end

-- Remove entity
function ENT:OnRemove()
	-- Remove all linked objects
	constraint.RemoveAll(self)
	if self.TrainEntities then
		for k,v in pairs(self.TrainEntities) do
			SafeRemoveEntity(v)
		end
	end
	
	-- Deinitialize train
	if Turbostroi then
		Turbostroi.DeinitializeTrain(self)
	end
end

-- Interaction zones
function ENT:Use(ply)
	local tr = ply:GetEyeTrace()
	if not tr.Hit then return end
	local hitpos = self:WorldToLocal(tr.HitPos)
	
	if self.InteractionZones then
		for k,v in pairs(self.InteractionZones) do
			if hitpos:Distance(v.Pos) < v.Radius then
				self:ButtonEvent(v.ID)
			end
		end
	end
end

-- Trigger output
function ENT:TriggerOutput(name,value)
	if Wire_TriggerOutput then
		Wire_TriggerOutput(self,name,tonumber(value) or 0)
	end
end

-- Trigger input
function ENT:TriggerInput(name, value)
	-- Custom seat 
	if name == "DriverSeat" then
		if IsValid(value) and value:IsVehicle() then
			self.DriverSeat = value
		else
			self.DriverSeat = nil
		end
	end
	
	-- Train wire input
	if string.sub(name,1,9) == "TrainWire" then
		local id = tonumber(string.sub(name,10))
		self.TrainWireOverrides[id] = value
	end
	
	-- Drivers wrench present
	if name == "DriversWrenchPresent" then
		self.DriversWrenchPresent = (value > 0.5)
	end

	-- Propagate inputs to relevant systems
	for k,v in pairs(self.Systems) do
		if v.Name and (string.sub(name,1,#v.Name) == v.Name) then
			local subname = string.sub(name,#v.Name+1)
			if v.IsInput[subname] then
				v:TriggerInput(subname,value)
			end
		elseif v.IsInput[name] then
			v:TriggerInput(name,value)
		end
	end
end

-- The debugger will call this
function ENT:GetDebugVars()
	return self.DebugVars 
end

--Debugging function, call via the console or something
function ENT:ShowInteractionZones()
	for k,v in pairs(self.InteractionZones) do
		debugoverlay.Sphere(self:LocalToWorld(v.Pos),v.Radius,15,Color(255,185,0),true)
	end
end




--------------------------------------------------------------------------------
-- Highspeed interface
--------------------------------------------------------------------------------
-- Initialize highspeed layout
function ENT:InitializeHighspeedLayout()
	local layout = ""
	self.HighspeedLayout = {}
	for k,v in pairs(Metrostroi.TrainHighspeedInterface) do
		local offset = v[1] + 128
		if self.Systems[v[2]] then
			self.HighspeedLayout[offset] = function(value)
				if value then
					self.Systems[v[2] ]:TriggerInput(v[3],value)
				else
					return (self.Systems[v[2] ][v[3] ] or 0)
				end
			end
		end
		
		layout = layout.."["..offset.."]\t"..v[2].."."..v[3].."\r\n"
	end
	file.Write("hs_layout.txt",layout)
	
	--[[local str = ""
	local offset = 0
	for k,v in SortedPairs(self.Systems) do
		for i=1,#v.InputsList do
			str = str.."{ "..offset..", \""..k.."\", \""..v.InputsList[i].."\" },\r\n"
			offset = offset + 1
		end
		for i=1,#v.OutputsList do
			str = str.."{ "..offset..", \""..k.."\", \""..v.OutputsList[i].."\" },\r\n"
			offset = offset + 1
		end
	end
	file.Write("hs_layout.txt",str)]]--
end

function ENT:UpdateWagonList()
	if self.LastWagonListUpdate == CurTime() then return end
	self.LastUpdate = CurTime()

	-- Populate list of wagons
	self.WagonList = {}
	local function populateList(train,checked)
		if train and IsValid(train) then
			if checked[train] then return end
			checked[train] = true

			table.insert(self.WagonList,train)
			populateList(train.RearTrain,checked)
			populateList(train.FrontTrain,checked)
		end
	end
	populateList(self,{})
end

function ENT:ReadCell(Address)
	if Address < 0 then return nil end
	if Address == 0 then
		return 1
	end
	if (Address > 0) and (Address < 128) then
		return self:ReadTrainWire(Address)
	end
	if self.HighspeedLayout[Address] then
		return self.HighspeedLayout[Address]()
	end
	if (Address >= 49152) and (Address < 49152+8192) then
		local x = (Address - (49152+64))
		local entryID = math.floor(x/4)
		local varID = x%4

		if self.Schedule then
			if (entryID >= 0) then
				local entry = self.Schedule[entryID+1]
				if entry then
					if varID >= 2 then
						return (entry[varID+1] or 0)*60
					else
						return entry[varID+1] or 0
					end
				end
			end
			if Address == 49152 then return #self.Schedule end
			if Address == 49153 then return self.Schedule.ScheduleID end
			if Address == 49154 then return self.Schedule.Interval end
			if Address == 49155 then return self.Schedule.Duration end
			if Address == 49156 then return self.Schedule.StartStation end
			if Address == 49157 then return self.Schedule.EndStation end
			if Address == 49158 then return self.Schedule.StartTime*60 end
			if Address == 49159 then return self.Schedule.EndTime*60 end
		end

		local pos = Metrostroi.TrainPositions[self]
		if (Address >= 49160) and (Address <= 49162) and pos and pos[1] then
			pos = pos[1]

			-- Get stations
			local current,next,prev = 0,0,0
			local x1,x2 = 1e9,0
			for stationID,stationData in pairs(Metrostroi.Stations) do
				for platformID,platformData in pairs(stationData) do
					if (platformData.node_start.path == pos.path) and 
						(platformData.x_start < pos.x) and 
						(platformData.x_end > pos.x) then
						current = stationID
					end
					if (platformData.node_start.path == pos.path) and 
						(platformData.x_start > pos.x) then
						if platformData.x_start < x1 then
							x1 = platformData.x_start
							next = stationID
						end
					end
					if (platformData.node_start.path == pos.path) and 
						(platformData.x_start < pos.x) then
						if platformData.x_start > x2 then
							x2 = platformData.x_start
							prev = stationID
						end
					end
				end
			end

			if Address == 49160 then return current end
			if Address == 49161 then return next end
			if Address == 49162 then return prev end
			if Address == 49163 then return x1 - pos.x end
		end
		return 0
	end

	if (Address >= 57344) and (Address < 57344+4096) then
		local x = (Address - 57344)
		local lineID = math.floor(x/800)
		local stationID = math.floor((x - lineID*800)/8)
		local platformID = math.floor((x - lineID*800 - stationID*8)/4)
		local varID = x - lineID*800 - stationID*8 - platformID*4

		local station = Metrostroi.Stations[(lineID+1)*100 + stationID]
		if station then
			local platform = station[platformID]
			if platform then
				if varID == 0 then return platform.x_start end
				if varID == 1 then return platform.x_end end
				if varID == 2 then return platform.node_start.path.id end
				if varID == 3 then return 0 end
			end
		end
		return 0
	end
	if (Address >= 65504) and (Address <= 65510) then
		local pos = Metrostroi.TrainPositions[self]
		if pos then
			if Address == 65504 then return pos.x end
			if Address == 65505 then return pos.y end
			if Address == 65506 then return pos.z end
			if Address == 65507 then return pos.distance end
			if Address == 65508 then return pos.forward and 1 or 0 end
			if Address == 65509 then return pos.node.id end
			if Address == 65510 then return pos.path.id end
		end
		return 0
	end
	if Address == 65535 then
		self:UpdateWagonList()
		return #self.WagonList
	end
	if Address >= 65536 then
		local wagonIndex = 1+math.floor(Address/65536)
		local variableAddress = Address % 65536
		self:UpdateWagonList()
		
		if self.WagonList[wagonIndex] and IsValid(self.WagonList[wagonIndex]) then
			return self.WagonList[wagonIndex]:ReadCell(variableAddress)
		else
			return 0
		end
	end
end

function ENT:WriteCell(Address, value)
	if Address < 0 then return false end
	if Address == 0 then return true end
	if (Address >= 1) and (Address < 128) then
		self.TrainWireOverrides[Address] = value
		return true
	end
	if self.HighspeedLayout[Address] then
		self.HighspeedLayout[Address](value)
		return true
	end
	if Address >= 65536 then
		local wagonIndex = 1+math.floor(Address/65536)
		local variableAddress = Address % 65536
		self:UpdateWagonList()
		
		if self.WagonList[wagonIndex] and IsValid(self.WagonList[wagonIndex]) then
			return self.WagonList[wagonIndex]:WriteCell(variableAddress,value)
		else
			return false
		end
	end
	return true
end



--------------------------------------------------------------------------------
-- Train wire I/O
--------------------------------------------------------------------------------
function ENT:TrainWireCanWrite(k)
	local lastwrite = self.TrainWireWriters[k]
	if lastwrite ~= nil then
		-- Check if someone else wrote recently
		--for writer,v in pairs(lastwrite) do
		local writer = lastwrite.e
		local v = lastwrite.t or 0
			if (writer ~= self) and (CurTime() - v < 0.25) then
				return false
			end
		--end
	end
	return true
end

function ENT:IsTrainWireCrossConnected(k)
	local lastwrite = self.TrainWireWriters[k]
	local lastTime = 0
	local ent = nil
	if lastwrite then
		--for writer,v in pairs(lastwrite) do
		local writer = lastwrite.e
		local v = lastwrite.t or 0
			if v > lastTime then
				lastTime = v
				ent = writer
			end
		--end
	end

	return ent and (ent.TrainCoupledIndex ~= self.TrainCoupledIndex)
end

function ENT:WriteTrainWire(k,v)
	-- Override values with wire interface
	if self.TrainWireOverrides[k] and (self.TrainWireOverrides[k] > 0) then
		v = self.TrainWireOverrides[k]
	end
	
	-- Check if line is write-able
	local can_write = self:TrainWireCanWrite(k)
	local wrote = false
	
	-- Writing rules for different wires
	local allowed_write = v > 0 -- Normally positive values override others
	if k == 18 then allowed_write = v <= 0 end -- For wire 18, zero values override others
	for a,b in pairs(self.TrainWireCrossConnections) do
		if self:IsTrainWireCrossConnected(a) or self:IsTrainWireCrossConnected(b) then
			    if k == a then k = b
			elseif k == b then k = a end
		end
	end
	
	-- Write only if can write (no-one else occupies it) or allowed to write (legal value)
	if can_write then
		self.TrainWires[k] = v
		wrote = true
	elseif allowed_write then
		self.TrainWires[k] = v
		wrote = true
	end
	
	-- Record us as last writer
	if wrote and (allowed_write or can_write) then
		self.TrainWireWriters[k] = self.TrainWireWriters[k] or {}
		self.TrainWireWriters[k].t = CurTime()
		self.TrainWireWriters[k].e = self
	end
end

function ENT:ReadTrainWire(k)
	-- Cross-commutate some wires
	for a,b in pairs(self.TrainWireCrossConnections) do
		if self:IsTrainWireCrossConnected(a) or self:IsTrainWireCrossConnected(b) then
			    if k == a then k = b
			elseif k == b then k = a end
		end
	end
	return self.TrainWires[k] or 0
end

function ENT:OnTrainWireError(k)

end

function ENT:ResetTrainWires()
	-- Remember old train wires reference
	local trainWires = self.TrainWires
	
	-- Create new train wires
	self.TrainWires = {}
	self.TrainWireWriters = {}
	
	-- Initialize train wires to zero values
	for i=1,128 do self.TrainWires[i] = 0 end
	
	-- Update train wires in all connected trains
	local function updateWires(train,checked)
		if not train then return end
		if checked[train] then return end
		checked[train] = true
		
		if train.TrainWires == trainWires then
			train.TrainWires = self.TrainWires
			train.TrainWireWriters = self.TrainWireWriters
		end
		updateWires(train.FrontTrain,checked)
		updateWires(train.RearTrain,checked)
	end
	updateWires(self,{})
end

function ENT:SetTrainWires(coupledTrain)
	-- Get train wires from train
	self.TrainWires = coupledTrain.TrainWires
	self.TrainWireWriters = coupledTrain.TrainWireWriters
	
	-- Update train wires in all connected trains
	local function updateWires(train,checked)
		if not train then return end
		if checked[train] then return end
		checked[train] = true
		
		if train.TrainWires ~= coupledTrain.TrainWires then
			train.TrainWires = coupledTrain.TrainWires
			train.TrainWireWriters = coupledTrain.TrainWireWriters
		end
		updateWires(train.FrontTrain,checked)
		updateWires(train.RearTrain,checked)
	end
	updateWires(self,{})
end




--------------------------------------------------------------------------------
-- Coupling logic
--------------------------------------------------------------------------------
function ENT:UpdateIndexes()
	local function updateIndexes(train,checked,newIndex)
		if not train then return end
		if checked[train] then return end
		checked[train] = true
		
		train.TrainCoupledIndex = newIndex
		
		if train.FrontTrain and (train.FrontTrain.FrontTrain == train) then
			updateIndexes(train.FrontTrain,checked,1-newIndex)
		else
			updateIndexes(train.FrontTrain,checked,newIndex)
		end
		if train.RearTrain and (train.RearTrain.RearTrain == train) then
			updateIndexes(train.RearTrain,checked,1-newIndex)
		else
			updateIndexes(train.RearTrain,checked,newIndex)
		end
	end
	updateIndexes(self,{},0)
end

function ENT:OnCouple(bogey,isfront)
	--print(self,"Coupled with ",bogey," at ",isfront)
	if isfront then
		self.FrontCoupledBogey = bogey
	else
		self.RearCoupledBogey = bogey
	end
	
	local train = bogey:GetNWEntity("TrainEntity")
	if not IsValid(train) then return end
	--Don't update train wires when there's no parent train 
	
	self:UpdateCoupledTrains()

	if ((train.FrontTrain == self) or (train.RearTrain == self)) then
		self:UpdateIndexes()
	end
	
	-- Update train wires
	self:SetTrainWires(train)
end

function ENT:OnDecouple(isfront)
	--print(self,"Decoupled from front?:" ,isfront)	
	if isfront then
		self.FrontCoupledBogey = nil
	else 
		self.RearCoupledBogey = nil
	end
	
	self:UpdateCoupledTrains()
	self:UpdateIndexes()
	self:ResetTrainWires()
end

function ENT:UpdateCoupledTrains()
	if self.FrontCoupledBogey then
		self.FrontTrain = self.FrontCoupledBogey:GetNWEntity("TrainEntity")
	else
		self.FrontTrain = nil
	end
	
	if self.RearCoupledBogey then
		self.RearTrain = self.RearCoupledBogey:GetNWEntity("TrainEntity")
	else
		self.RearTrain = nil
	end
end




--------------------------------------------------------------------------------
-- Create a bogey for the train
--------------------------------------------------------------------------------
function ENT:CreateBogey(pos,ang,forward,type)
	-- Create bogey entity
	local bogey = ents.Create("gmod_train_bogey")
	bogey:SetPos(self:LocalToWorld(pos))
	bogey:SetAngles(self:GetAngles() + ang)
	bogey.BogeyType = type
	bogey.NoPhysics = self.NoPhysics
	bogey:Spawn()

	-- Assign ownership
	if CPPI then bogey:CPPISetOwner(self:CPPIGetOwner()) end
	
	-- Some shared general information about the bogey
	self.SquealSound = self.SquealSound or math.floor(4*math.random())
	self.SquealSensitivity = self.SquealSensitivity or math.random()
	bogey.SquealSensitivity = self.SquealSensitivity
	bogey:SetNWInt("SquealSound",self.SquealSound)
	bogey:SetNWBool("IsForwardBogey", forward)
	bogey:SetNWEntity("TrainEntity", self)

	-- Constraint bogey to the train
	if self.NoPhysics then
		bogey:SetParent(self)
	else
		constraint.Axis(bogey,self,0,0,
			Vector(0,0,0),Vector(0,0,0),
			0,0,0,1,Vector(0,0,1),false)
	end

	-- Add to cleanup list
	table.insert(self.TrainEntities,bogey)
	return bogey
end


--------------------------------------------------------------------------------
-- Create an entity for the seat
--------------------------------------------------------------------------------
function ENT:CreateSeatEntity(seat_info)
	-- Create seat entity
	local seat = ents.Create("prop_vehicle_prisoner_pod")
	seat:SetModel("models/nova/jeep_seat.mdl") --jalopy
	seat:SetPos(self:LocalToWorld(seat_info.offset))
	seat:SetAngles(self:GetAngles()+Angle(0,-90,0)+seat_info.angle)
	seat:SetKeyValue("limitview",0)
	seat:Spawn()
	seat:GetPhysicsObject():SetMass(10)
	seat:SetCollisionGroup(COLLISION_GROUP_WORLD)
	
	--Assign ownership
	if CPPI then seat:CPPISetOwner(self:CPPIGetOwner()) end
	
	-- Hide the entity visually
	if seat_info.type == "passenger" then
		seat:SetColor(Color(0,0,0,0))
		seat:SetRenderMode(RENDERMODE_TRANSALPHA)
	end

	-- Set some shared information about the seat
	self:SetNWEntity("seat_"..seat_info.type,seat)
	seat:SetNWString("SeatType", seat_info.type)
	seat:SetNWEntity("TrainEntity", self)
	seat_info.entity = seat

	-- Constrain seat to this object
	-- constraint.NoCollide(self,seat,0,0)
	seat:SetParent(self)
	
	-- Add to cleanup list
	table.insert(self.TrainEntities,seat)
	return seat
end


--------------------------------------------------------------------------------
-- Create a seat position
--------------------------------------------------------------------------------
function ENT:CreateSeat(type,offset,angle)
	-- Add a new seat
	local seat_info = {
		type = type,
		offset = offset,
		angle = angle or Angle(0,0,0),
	}
	table.insert(self.Seats,seat_info)
	
	-- If needed, create an entity for this seat
	if (type == "driver") or (type == "instructor") or (type == "passenger") then
		return self:CreateSeatEntity(seat_info)
	end
end

-- Returns if KV/reverser wrench is present in cabin
function ENT:IsWrenchPresent()
	if self.DriversWrenchPresent then return end
	
	for k,v in pairs(self.Seats) do
		if IsValid(v.entity) and v.entity.GetPassenger and
			((v.type == "driver") or (v.type == "instructor")) then
			local player = self.DriverSeat:GetPassenger(0)
			if player and player:IsValid() then return true end
		end
	end
	return false
end

function ENT:GetDriver()
	if IsValid(self.DriverSeat) then
		local ply = self.DriverSeat:GetPassenger(0)
		if IsValid(ply) then return ply end
	end
end

--------------------------------------------------------------------------------
-- Turn light on or off
--------------------------------------------------------------------------------
function ENT:SetLightPower(index,power,brightness)
	local lightData = self.Lights[index]
	self.GlowingLights = self.GlowingLights or {}
	self.LightBrightness = self.LightBrightness or {}
	brightness = brightness or 1

	-- Check if light already glowing
	if (power and (self.GlowingLights[index])) and 
	   (brightness == self.LightBrightness[index]) then return end
	
	-- Turn off light
	SafeRemoveEntity(self.GlowingLights[index])
	self.GlowingLights[index] = nil
	self.LightBrightness[index] = brightness
	
	-- Create light
	if (lightData[1] == "headlight") and (power) then
		local light = ents.Create("env_projectedtexture")
		light:SetParent(self)
		light:SetLocalPos(lightData[2])
		light:SetLocalAngles(lightData[3])

		-- Set parameters
		light:SetKeyValue("enableshadows", 1)
		light:SetKeyValue("farz", 2048)
		light:SetKeyValue("nearz", 16)
		light:SetKeyValue("lightfov", lightData.fov or 120)

		-- Set Brightness
		local brightness = brightness * (lightData.brightness or 1.25)
		light:SetKeyValue("lightcolor",
			Format("%i %i %i 255",
				lightData[4].r*brightness,
				lightData[4].g*brightness,
				lightData[4].b*brightness
			)
		)

		-- Turn light on
		light:Spawn() --"effects/flashlight/caustics"
		light:Input("SpotlightTexture",nil,nil,lightData.texture or "effects/flashlight001")
		self.GlowingLights[index] = light
	end
	if (lightData[1] == "glow") and (power) then
		local light = ents.Create("env_sprite")
		light:SetParent(self)
		light:SetLocalPos(lightData[2])
		light:SetLocalAngles(lightData[3])
	
		-- Set parameters
		local brightness = brightness * (lightData.brightness or 0.5)
		light:SetKeyValue("rendercolor",
			Format("%i %i %i",
				lightData[4].r*brightness,
				lightData[4].g*brightness,
				lightData[4].b*brightness
			)
		)
		light:SetKeyValue("rendermode", lightData.type or 3) -- 9: WGlow, 3: Glow
		light:SetKeyValue("model", lightData.texture or "sprites/glow1.vmt")
--		light:SetKeyValue("model", "sprites/light_glow02.vmt")
--		light:SetKeyValue("model", "sprites/yellowflare.vmt")
		light:SetKeyValue("scale", lightData.scale or 1.0)
		light:SetKeyValue("spawnflags", 1)
	
		-- Turn light on
		light:Spawn()
		self.GlowingLights[index] = light
	end
	if (lightData[1] == "light") and (power) then
		local light = ents.Create("env_sprite")
		light:SetParent(self)
		light:SetLocalPos(lightData[2])
		light:SetLocalAngles(lightData[3])
	
		-- Set parameters
		local brightness = brightness * (lightData.brightness or 0.5)
		light:SetKeyValue("rendercolor",
			Format("%i %i %i",
				lightData[4].r*brightness,
				lightData[4].g*brightness,
				lightData[4].b*brightness
			)
		)
		light:SetKeyValue("rendermode", lightData.type or 9) -- 9: WGlow, 3: Glow
--		light:SetKeyValue("model", "sprites/glow1.vmt")
		light:SetKeyValue("model", lightData.texture or "sprites/light_glow02.vmt")
--		light:SetKeyValue("model", "sprites/yellowflare.vmt")
		light:SetKeyValue("scale", lightData.scale or 1.0)
		light:SetKeyValue("spawnflags", 1)
	
		-- Turn light on
		light:Spawn()
		self.GlowingLights[index] = light
	end
	if (lightData[1] == "dynamiclight") and (power) then
		local light = ents.Create("light_dynamic")
		light:SetParent(self)

		-- Set position
		light:SetLocalPos(lightData[2])
		light:SetLocalAngles(lightData[3])

		-- Set parameters
		light:SetKeyValue("_light",
			Format("%i %i %i",
				lightData[4].r,
				lightData[4].g,
				lightData[4].b
			)
		)
		light:SetKeyValue("style", 0)
		light:SetKeyValue("distance", lightData.distance or 300)
		light:SetKeyValue("brightness", brightness * (lightData.brightness or 2))

		-- Turn light on
		light:Spawn()
		light:Fire("TurnOn","","0")
		self.GlowingLights[index] = light
	end
end




--------------------------------------------------------------------------------
-- Joystick input
--------------------------------------------------------------------------------
function ENT:HandleJoystickInput(ply)
	for k,v in pairs(jcon.binds) do
		if v:GetCategory() == "Metrostroi" then
			local jvalue = Metrostroi.GetJoystickInput(ply,k)
			if (jvalue != nil) and (self.JoystickBuffer[k] ~= jvalue) then
				local inputname = Metrostroi.JoystickSystemMap[k]
				self.JoystickBuffer[k] = jvalue
				if inputname then
					if type(jvalue) == "boolean" then
						if jvalue then
							jvalue = 1.0
						else
							jvalue = 0.0
						end
					end
					self:TriggerInput(inputname,jvalue)
				end
			end
		end
	end
end




--------------------------------------------------------------------------------
-- Keyboard input
--------------------------------------------------------------------------------
function ENT:IsModifier(key)
	return type(self.KeyMap[key]) == "table"
end

function ENT:HasModifier(key)
	return self.KeyMods[key] ~= nil
end

function ENT:GetActiveModifiers(key)
	local tbl = {}
	local mods = self.KeyMods[key]
	for k,v in pairs(mods) do
		if self.KeyBuffer[k] ~= nil then
			table.insert(tbl,k)
		end
	end
	return tbl
end

function ENT:OnKeyEvent(key,state)
	if state then
		self:OnKeyPress(key)
	else
		self:OnKeyRelease(key)
	end
	
	if self:HasModifier(key) then
		--If we have a modifier
		local actmods = self:GetActiveModifiers(key)
		if #actmods > 0 then
			--Modifier is being preseed
			for k,v in pairs(actmods) do
				if self.KeyMap[v][key] ~= nil then
					self:ButtonEvent(self.KeyMap[v][key],state)
				end
			end
		elseif self.KeyMap[key] ~= nil then
			self:ButtonEvent(self.KeyMap[key],state)
		end
		
	elseif self:IsModifier(key) and not state then
		--Release modified keys
		for k,v in pairs(self.KeyMap[key]) do
			self:ButtonEvent(v,false)
		end
		
	elseif self.KeyMap[key] ~= nil and type(self.KeyMap[key]) == "string" then
		--If we're a regular binded key
		self:ButtonEvent(self.KeyMap[key],state)
	end
end

function ENT:OnKeyPress(key)

end

function ENT:OnKeyRelease(key)

end

function ENT:ProcessKeyMap()
	self.KeyMods = {}

	for mod,v in pairs(self.KeyMap) do
		if type(v) == "table" then
			for k,_ in pairs(v) do
				if not self.KeyMods[k] then
					self.KeyMods[k]={}
				end
				self.KeyMods[k][mod]=true
			end
		end
	end
end


local function HandleKeyHook(ply,k,state)
	local train = ply:GetTrain()
	if IsValid(train) then
		train.KeyMap[k] = state or nil
	end
end

function ENT:HandleKeyboardInput(ply)
	if not self.KeyMods and self.KeyMap then
		self:ProcessKeyMap()
	end

	-- Check for newly pressed keys
	for k,v in pairs(ply.keystate) do
		if self.KeyBuffer[k] == nil then
			self.KeyBuffer[k] = true
			self:OnKeyEvent(k,true)
		end
	end

	-- Check for newly released keys
	for k,v in pairs(self.KeyBuffer) do
		if ply.keystate[k] == nil then
			self.KeyBuffer[k] = nil
			self:OnKeyEvent(k,false)
		end
	end

end

--------------------------------------------------------------------------------
-- Process train logic
--------------------------------------------------------------------------------
-- Think and execute systems stuff
function ENT:Think()
	self.PrevTime = self.PrevTime or CurTime()
	self.DeltaTime = (CurTime() - self.PrevTime)
	self.PrevTime = CurTime()
	
	-- Read networked variables
	self:RecvPackedData()
	
	-- Calculate train acceleration
	--[[self.PreviousVelocity = self.PreviousVelocity or self:GetVelocity()
	local accelerationVector = 0.01905*(self:GetPhysicsObject():GetVelocity() - self.PreviousVelocity) / self.DeltaTime
	accelerationVector:Rotate(self:GetAngles())
	self:SetTrainAcceleration(accelerationVector)
	self.PreviousVelocity = self:GetVelocity()]]--
	
	-- Get angular velocity
	--self:SetTrainAngularVelocity(math.pi*self:GetPhysicsObject():GetAngleVelocity()/180)
	
	-- Apply mass of passengers
	if self.NormalMass then
		self:GetPhysicsObject():SetMass(self.NormalMass + 80*self:GetPassengerCount())
	end
	
	-- Calculate turn information, unused right now
	--[[if self.FrontBogey and self.RearBogey then
		self.BogeyDistance = self.BogeyDistance or self.FrontBogey:GetPos():Distance(self.RearBogey:GetPos())
		local a = math.AngleDifference(self.FrontBogey:GetAngles().y,self.RearBogey:GetAngles().y+180)
		self.TurnRadius = (self.BogeyDistance/2)/math.sin(math.rad(a/2))
		
		-- If we're pretty much going straight, correct massive values
		if math.abs(self.TurnRadius) > 1e4 then
			self.TurnRadius = 0 
		end	
	end]]--

	-- Process the keymap for modifiers 
	-- TODO: Need a neat way of calling this once after self.KeyMap is populated
	if not self.KeyMods and self.KeyMap then
		self:ProcessKeyMap()
	end

	-- Keyboard input is done via PlayerButtonDown/Up hooks that call ENT:OnKeyEvent
	-- Joystick input
	if IsValid(self.DriverSeat) then
		local ply = self.DriverSeat:GetPassenger(0) 
		
		if IsValid(ply) then
			if self.KeyMap then self:HandleKeyboardInput(ply) end
			if joystick then self:HandleJoystickInput(ply) end
		end
	end

	if Turbostroi then
		-- Simulate systems which don't need to be simulated with turbostroi
		for k,v in pairs(self.Systems) do
			if v.DontAccelerateSimulation then
				v:Think(self.DeltaTime / (v.SubIterations or 1),i)
			end
		end
	else
		-- Run iterations on systems simulation
		local iterationsCount = 1
		if (not self.Schedule) or (iterationsCount ~= self.Schedule.IterationsCount) then
			self.Schedule = { IterationsCount = iterationsCount }
			
			-- Find max number of iterations
			local maxIterations = 0
			for k,v in pairs(self.Systems) do maxIterations = math.max(maxIterations,(v.SubIterations or 1)) end

			-- Create a schedule of simulation
			for iteration=1,maxIterations do self.Schedule[iteration] = {} end

			-- Populate schedule
			for k,v in pairs(self.Systems) do
				local simIterationsPerIteration = (v.SubIterations or 1) / maxIterations
				local iterations = 0
				for iteration=1,maxIterations do
					iterations = iterations + simIterationsPerIteration
					while iterations >= 1 do
						table.insert(self.Schedule[iteration],v)
						iterations = iterations - 1
					end
				end
			end
		end
		
		-- Simulate according to schedule
		for i,s in ipairs(self.Schedule) do
			for k,v in ipairs(s) do
				v:Think(self.DeltaTime / (v.SubIterations or 1),i)
			end
		end
	end
	
	-- Wire outputs
	local triggerOutput = self.TriggerOutput
	for _,name in pairs(self.WireIOSystems) do
		local system = self.Systems[name]
		if system and system.OutputsList then
			for _,name in pairs(system.OutputsList) do
				local varname = (system.Name or "")..name
				if type(system[name]) ==  "boolean" then
					triggerOutput(self,varname,system[name] and 1 or 0)
				else
					triggerOutput(self,varname,tonumber(system[name]) or 0)
				end
			end
		end
	end
	
	-- Write and read train wires
	local readTrainWire = self.ReadTrainWire
	local writeTrainWire = self.WriteTrainWire
	for k,v in pairs(self.TrainWireOverrides) do
		if v > 0 then writeTrainWire(self,k,v) end
	end
	for i=1,32 do
		triggerOutput(self,"TrainWire"..i,readTrainWire(self,i))
	end
	
	-- Add interesting debug variables
	if (GetConVarNumber("metrostroi_debugger_enabled") > 0) then
		for i=1,32 do
			self.DebugVars["TW"..i] = self:ReadTrainWire(i)
		end
		for k,v in pairs(self.Systems) do
			for _,output in pairs(v.OutputsList) do
				self.DebugVars[(v.Name or "")..output] = v[output] or 0
			end
		end
	end
	
	-- Calculate own speed and acceleration
	local speed,acceleration = 0,0
	if IsValid(self.FrontBogey) and IsValid(self.RearBogey) then
		speed = (self.FrontBogey.Speed + self.RearBogey.Speed)/2
		acceleration = (self.FrontBogey.Acceleration + self.RearBogey.Acceleration)/2
	end
	
	-- Update speed and acceleration
	self.Speed = speed
	self.Acceleration = acceleration
	--self.DebugVars["Speed"] = speed
	--self.DebugVars["Acceleration"] = acceleration

	-- Go to next think
	self:NextThink(CurTime()+0.05)
	return true
end




--------------------------------------------------------------------------------
-- Default spawn function
--------------------------------------------------------------------------------
function ENT:SpawnFunction(ply, tr)
	local verticaloffset = 5 -- Offset for the train model
	local distancecap = 2000 -- When to ignore hitpos and spawn at set distanace
	local pos, ang = nil
	local inhibitrerail = false
	
	--TODO: Make this work better for raw base ent
	
	if tr.Hit then
		-- Setup trace to find out of this is a track
		local tracesetup = {}
		tracesetup.start=tr.HitPos
		tracesetup.endpos=tr.HitPos+tr.HitNormal*80
		tracesetup.filter=ply

		local tracedata = util.TraceLine(tracesetup)

		if tracedata.Hit then
			-- Trackspawn
			pos = (tr.HitPos + tracedata.HitPos)/2 + Vector(0,0,verticaloffset)
			ang = tracedata.HitNormal
			ang:Rotate(Angle(0,90,0))
			ang = ang:Angle()
			-- Bit ugly because Rotate() messes with the orthogonal vector | Orthogonal? I wrote "origional?!" :V
		else
			-- Regular spawn
			if tr.HitPos:Distance(tr.StartPos) > distancecap then
				-- Spawnpos is far away, put it at distancecap instead
				pos = tr.StartPos + tr.Normal * distancecap
				inhibitrerail = true
			else
				-- Spawn is near
				pos = tr.HitPos + tr.HitNormal * verticaloffset
			end
			ang = Angle(0,tr.Normal:Angle().y,0)
		end
	else
		-- Trace didn't hit anything, spawn at distancecap
		pos = tr.StartPos + tr.Normal * distancecap
		ang = Angle(0,tr.Normal:Angle().y,0)
	end

	local ent = ents.Create(self.ClassName)

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent.Owner = ply
	ent:Spawn()
	ent:Activate()
	
	if not inhibitrerail then Metrostroi.RerailTrain(ent) end
	
	-- Debug mode
	--Metrostroi.DebugTrain(ent,ply)
	return ent
end




--------------------------------------------------------------------------------
-- Process Cabin button and keyboard input
--------------------------------------------------------------------------------
function ENT:OnButtonPress(button)

end

function ENT:OnButtonRelease(button)

end

-- Clears the serverside keybuffer and fires events
function ENT:ClearKeyBuffer()
	for k,v in pairs(self.KeyBuffer) do
		local button = self.KeyMap[k]
		if button ~= nil then
			if type(button) == "string" then
				self:ButtonEvent(button,false)
			else
				--Check modifiers as well
				for k2,v2 in pairs(button) do
					self:ButtonEvent(v2,false)
				end
			end
		end
	end
	self.KeyBuffer = {}
end

local function ShouldWriteToBuffer(buffer,state)
	if state == nil then return false end
	if state == false and buffer == nil then return false end
	return true
end

local function ShouldFireEvents(buffer,state)
	if state == nil then return true end
	if buffer == nil and state == false then return false end
	return (state ~= buffer) 
end

-- Checks a button with the buffer and calls 
-- OnButtonPress/Release as well as TriggerInput

function ENT:ButtonEvent(button,state)
	if ShouldFireEvents(self.ButtonBuffer[button],state) then
		if state == false then
			self:TriggerInput(button,0.0)
			self:OnButtonRelease(button)
		else
			self:TriggerInput(button,1.0)
			self:OnButtonPress(button)
		end
	end
	
	if ShouldWriteToBuffer(self.ButtonBuffer[button],state) then
		self.ButtonBuffer[button]=state
	end
end




--------------------------------------------------------------------------------
-- Handle cabin buttons
--------------------------------------------------------------------------------
-- Receiver for CS buttons, Checks if people are the legit driver and calls buttonevent on the train
net.Receive("metrostroi-cabin-button", function(len, ply)
	local button = net.ReadString()
	local eventtype = net.ReadBit()
	local seat = ply:GetVehicle()
	local train 
	
	if seat and IsValid(seat) then 
		-- Player currently driving
		train = seat:GetNWEntity("TrainEntity")
		if (not train) or (not train:IsValid()) then return end
		if seat != train.DriverSeat then return end
	else
		-- Player not driving, check recent train
		train = ply.lastVehicleDriven:GetNWEntity("TrainEntity")
		if !IsValid(train) then return end
		if ply != train.DriverSeat.lastDriver then return end
		if CurTime() - train.DriverSeat.lastDriverTime > 1	then return end
	end
	
	train:ButtonEvent(button,(eventtype > 0))
end)

-- Denies entry if player recently sat in the same train seat
-- This prevents getting stuck in seats when trying to exit
local function CanPlayerEnter(ply,vec,role)
	local train = vec:GetNWEntity("TrainEntity")
	
	if IsValid(train) and IsValid(ply.lastVehicleDriven) and ply.lastVehicleDriven.lastDriverTime != nil then
		if CurTime() - ply.lastVehicleDriven.lastDriverTime < 1 then return false end
	end
end

-- Exiting player hook, stores some vars and moves player if vehicle was train seat
local function HandleExitingPlayer(ply, vehicle)
	vehicle.lastDriver = ply
	vehicle.lastDriverTime = CurTime()
	ply.lastVehicleDriven = vehicle

	local train = vehicle:GetNWEntity("TrainEntity")
	if IsValid(train) then
		
		-- Move exiting player
		local seattype = vehicle:GetNWString("SeatType")
		local offset 
		
		if (seattype == "driver") then
			offset = Vector(0,10,-17)
		elseif (seattype == "instructor") then
			offset = Vector(5,-10,-17)
		elseif (seattype == "passenger") then
			offset = Vector(10,0,-17)
		end
		
		offset:Rotate(train:GetAngles())
		ply:SetPos(vehicle:GetPos()+offset)
		
		ply:SetEyeAngles(vehicle:GetForward():Angle())
		
		-- Server
		train:ClearKeyBuffer()
		
		-- Client
		net.Start("metrostroi-cabin-reset")
		net.WriteEntity(train)
		net.Send(ply)
	end
end




--------------------------------------------------------------------------------
-- Register joystick buttons
-- Won't get called if joystick isn't installed
-- I've put it here for now, trains will likely share these inputs anyway
local function JoystickRegister()
	Metrostroi.RegisterJoystickInput("met_controller",true,"Controller",-3,3)
	Metrostroi.RegisterJoystickInput("met_reverser",true,"Reverser",-1,1)
	Metrostroi.RegisterJoystickInput("met_pneubrake",true,"Pneumatic Brake",1,5)
	Metrostroi.RegisterJoystickInput("met_headlight",false,"Headlight Toggle")
	
--	Metrostroi.RegisterJoystickInput("met_reverserup",false,"Reverser Up")
--	Metrostroi.RegisterJoystickInput("met_reverserdown",false,"Reverser Down")
--	Will make this somewhat better later
--	Uncommenting these somehow makes the joystick addon crap itself

	Metrostroi.JoystickSystemMap["met_controller"] = "KVControllerSet"
	Metrostroi.JoystickSystemMap["met_reverser"] = "KVReverserSet"
	Metrostroi.JoystickSystemMap["met_pneubrake"] = "PneumaticBrakeSet"
	Metrostroi.JoystickSystemMap["met_headlight"] = "HeadLightsToggle"
--	Metrostroi.JoystickSystemMap["met_reverserup"] = "KVReverserUp"
--	Metrostroi.JoystickSystemMap["met_reverserdown"] = "KVReverserDown"
end

hook.Add("JoystickInitialize","metroistroi_cabin",JoystickRegister)

hook.Add("PlayerLeaveVehicle", "gmod_subway_81-717-cabin-exit", HandleExitingPlayer )
hook.Add("CanPlayerEnterVehicle","gmod_subway_81-717-cabin-entry", CanPlayerEnter )



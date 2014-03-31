--------------------------------------------------------------------------------
-- Internal systems simulations - auto-generated by gen.lua
--------------------------------------------------------------------------------
Metrostroi.DefineSystem("Gen_Int")

-- Node values
local S = {}
-- Temporary variables
local T = {}
for i=1,100 do T[i] = 0 end
-- Converts boolean expression to a number
local function C(x) return x and 1 or 0 end

local min = math.min

function TRAIN_SYSTEM.SolveEzh3(Train,Triggers)
	local P		= Train.PositionSwitch.SelectedPosition
	local RK	= Train.RheostatController.SelectedPosition
	local B		= (Train.Battery.Voltage > 55) and 1 or 0
	
	-- Solve all circuits
	T["SDRK_ShortCircuit"] = -10*Train.RheostatController.RKP*(Train.RUT.Value+Train.RRT.Value+(1.0-Train.SR1.Value))
	Triggers["SDRK_Shunt"]( 1.0 - 0.25*C((RK >= 2) and (RK <= 7))*C(P == 1)*Train.LK2.Value )
	S["33-33Aa"] = Train.KD.Value+Train.VAD.Value
	S["U2-20"] = Train.KV["U2-20a"]+Train.KV["U2-20b"]
	S["D1-31V"] = Train.KDL.Value+Train.VDL.Value
	S["10AK-VAH1"] = Train.VAH.Value+Train.RPB.Value
	S["33B-33AVU"] = Train.AVU.Value+Train.OtklAVU.Value
	S["1T-1P"] = Train.NR.Value+Train.RPU.Value
	S["2Zh-2A"] = (1.0-Train.KSB1.Value)+(1.0-Train.TR1.Value)
	S["2Zh-2A"] = Train.KSB2.Value+S["2Zh-2A"]
	S["8A-8Ye"] = C(RK == 1)+(1.0-Train.LK4.Value)
	S["15A-15B"] = Train.KV["15A-15B"]+Train.KD.Value
	S["10AYa-10E"] = (1.0-Train.LK3.Value)+Train.Rper.Value
	S["10AP-10AD"] = Train.LK2.Value+C((P == 3) or (P == 4))
	S["10AE-10B"] = Train.TR1.Value+Train.RV1.Value
	S["10AE-10B"] = S["10AE-10B"]+Train.RV1.Value
	S["1A-1R"] = (1.0-Train.RV1.Value)*C((P == 1))+C((RK >= 1) and (RK <= 5))*C((P == 2))
	S["10-8"] = Train.KV["10-8"]+Train.KV["FR1-10"]*(1.0-Train.RPB.Value)
	S["10N-10Zh"] = (1.0-Train.RRT.Value)*(1.0-Train.RUT.Value)*Train.SR1.Value+Train.RheostatController.RKM1
	S["2V-2G"] = C((RK >= 2) and (RK <= 4))*Train.KSH1.Value+C((RK >= 5) and (RK <= 18))
	S["2G-2A"] = S["2V-2G"]*C((P == 2) or (P == 4))+C((P == 1) or (P == 3))*C((RK >= 1) and (RK <= 17))
	S["1E-1Yu"] = Train.KSH2.Value+Train.KSB2.Value*Train.KSB1.Value
	S["10AG-10AD"] = Train.TR1.Value*C((P == 1) or (P == 2) or (P == 4))*Train.TR2.Value+(1.0-Train.TR1.Value)*C((P == 2) or (P == 3) or (P == 4))*(1.0-Train.TR2.Value)
	S["10E-10AG"] = Train.LK3.Value*C(RK == 18)*C((P == 1))+S["10AP-10AD"]*(1.0-Train.LK1.Value)*S["10AG-10AD"]
	S["1G-1Zh"] = Train.LK3.Value+Train.LK2.Value*C((P == 1) or (P == 3))*C(RK == 1)*S["1E-1Yu"]
	S["10"] = 1*Train:ReadTrainWire(10)
	S["FR1/2"] = S["10"]*Train.KV["FR1-10"]
	S["20B"] = Train.A20.Value*(1.0-Train.RPvozvrat.Value)*Train:ReadTrainWire(20)
	S["10AL"] = S["10"]*Train.VU.Value
	S["10ALa"] = S["10AL"]*Train.A64.Value
	S["Sh1-43"] = S["10AL"]*Train.A45.Value
	S["10AS"] = S["10AL"]*Train.A55.Value
	S["10AK"] = S["10AL"]*Train.A54.Value
	S["6P"] = S["10AL"]*Train.A61.Value
	S["6"] = S["6P"]*Train.RVT.Value
	S["2-7R-24"] = S["6P"]*(1.0-Train.AVU.Value)
	S["29"] = S["2-7R-24"]*(1.0-Train.OtklAVU.Value)+Train.ALS_ARS["29"]
	S["8"] = S["10"]*S["10-8"]+Train.ALS_ARS["8"]
	S["F13"] = S["10"]*Train.KV["F7-10"]*Train.A46.Value
	S["10AN"] = Train.A14.Value*1*(1.0-Train.RPvozvrat.Value)*1
	S["F10"] = S["10"]*Train.KV["F7-10"]*Train.VUS.Value*Train.A47.Value
	S["1-7R-8"] = S["10AS"]*Train.KV["10AS-U4"]*Train.VozvratRP.Value
	S["1A"] = Train.A1.Value*Train:ReadTrainWire(1)
	S["B12"] = 1*Train.VB.Value*B
	S["22A"] = Train.A23.Value*1*Train:ReadTrainWire(23)+T[8]*Train.A22.Value
	S["33V"] = S["10AK"]*Train.RV2.Value*S["10AK-VAH1"]*1*S["33B-33AVU"]
	S["1"] = S["10AS"]*Train.R1_5.Value*Train.KV["10AS-33D"]*Train.ALS_ARS["33D"]
	S["33Aa"] = S["10AS"]*Train.KV["10AS-33"]*S["33-33Aa"]
	S["18A"] = Train.LK4.Value*Train.A14.Value*(1.0-Train.RPvozvrat.Value)*1
	S["1P"] = S["1A"]*C((P == 1) or (P == 2))*S["1T-1P"]+T[2]*C((P == 3) or (P == 4))
	S["B2"] = 1*Train.VB.Value*B
	S["16V"] = Train.A16.Value*(1.0-Train.RD.Value)*Train:ReadTrainWire(16)
	S["2Ye"] = S["2G-2A"]*Train.LK4.Value*S["2Zh-2A"]*Train.A2.Value*Train:ReadTrainWire(2)+T[6]*(1.0-Train.LK4.Value)
	S["1Zh"] = S["1P"]*Train.AVT.Value*(1.0-Train.RPvozvrat.Value)*S["1G-1Zh"]
	S["3A"] = Train.A3.Value*Train:ReadTrainWire(3)
	S["4B"] = (1.0-Train.RKR.Value)*Train:ReadTrainWire(4)
	S["5B"] = Train.RKR.Value*Train:ReadTrainWire(5)
	S["5V"] = Train.RKR.Value*Train:ReadTrainWire(4)+T[10]*(1.0-Train.RKR.Value)
	S["5B'"] = S["5V"]*Train.LK3.Value
	S["6A"] = Train.A6.Value*Train:ReadTrainWire(6)
	S["8A"] = Train.A8.Value*Train:ReadTrainWire(8)
	S["8Zh"] = S["8A"]*C((RK >= 17) and (RK <= 18))+T[12]*1
	S["11A"] = S["B2"]*(1.0-Train.RD.Value)
	S["12A"] = Train.A12.Value*Train:ReadTrainWire(12)
	S["D8"] = 1*Train:ReadTrainWire(15)
	S["17A"] = Train.A17.Value*Train:ReadTrainWire(17)
	S["24V"] = (1.0-Train.LK4.Value)*Train:ReadTrainWire(24)
	S["25A"] = Train.A25.Value*Train:ReadTrainWire(25)
	S["27A"] = Train.A50.Value*Train:ReadTrainWire(27)
	S["28A"] = Train.A51.Value*Train:ReadTrainWire(28)
	S["31A"] = Train.A31.Value*Train:ReadTrainWire(31)+T[3]*1
	S["32A"] = Train.A32.Value*Train:ReadTrainWire(32)+T[4]*1
	S["10AYa"] = S["B2"]*Train.A80.Value
	S["10AE"] = S["B2"]*Train.A30.Value
	S["10I"] = S["10AE"]*Train.RheostatController.RKM2
	S["10AH"] = S["10I"]*(1.0-Train.LK1.Value)+0
	S["10H"] = S["10I"]*Train.LK4.Value
	S["B8"] = S["B2"]*Train.A53.Value
	S["B22"] = S["B8"]*Train.A75.Value
	S["B28"] = S["B8"]*Train.KUP.Value
	S["36Ya"] = S["B8"]*Train.KVC.Value
	S["B13"] = S["B12"]*Train.A24.Value
	S["4"] = S["10AK"]*Train.KV["10AK-4"]
	S["5"] = S["10AK"]*Train.KV["10AK-5"]
	S["U2"] = S["10AS"]*Train.KV["U2-10AS"]
	S["24"] = S["U2"]*Train.KSN.Value
	S["2-7R-21"] = S["U2"]*1+(-10*Train:ReadTrainWire(18))
	S["2"] = S["10AK"]*Train.KV["10AK-2"]+Train.ALS_ARS["2"]
	S["3"] = S["U2"]*Train.KV["U2-3"]
	S["10B"] = S["10AE"]*S["10AE-10B"]
	S["1R"] = S["1A"]*S["1A-1R"]
	S["10/4"] = S["B12"]*Train.VB.Value*Train.A56.Value+(1-Train.VB.Value)*Train:ReadTrainWire(10)
	S["6Yu"] = S["6A"]*C((P == 3) or (P == 4))*C((RK >= 1) and (RK <= 5))
	S["10N"] = S["10AE"]*S["10N-10Zh"]*1+T["SDRK_ShortCircuit"]
	S["8G"] = S["8A"]*(1.0-Train.RT2.Value)*S["8A-8Ye"]
	S["1-7R-29"] = S["B2"]*Train.A44.Value*Train.RezMK.Value
	S["22V"] = S["22A"]*(1.0-Train.TRK.Value)
	S["1K"] = S["1Zh"]*C((P == 1) or (P == 2))
	S["1N"] = S["1Zh"]*C((P == 1) or (P == 3))
	S["D1"] = S["10/4"]*Train.A21.Value*Train.KV["D-D1"]
	S["11B"] = S["10/4"]*Train.KV["10/4-C3"]*(1.0-Train.NR.Value)+T[1]*1
	S["16"] = S["D1"]*Train.VUD1.Value*Train.VUD2.Value
	S["25"] = S["U2"]*Train.KV["U2-25"]*Train.K25.Value
	S["10AG"] = S["10AYa"]*S["10AYa-10E"]*S["10E-10AG"]
	S["10AV"] = S["10AYa"]*(1.0-Train.LK3.Value)*C((RK >= 2) and (RK <= 18))
	S["20"] = S["U2"]*S["U2-20"]+Train.ALS_ARS["20"]
	S["31V"] = S["D1"]*S["D1-31V"]
	S["10/4a"] = S["10/4"]*Train.VB.Value
	S["22K"] = S["10/4"]*Train.A10.Value
	S["U0"] = S["10/4"]*Train.A27.Value
	S["U0a"] = S["U0"]*1+(-10*S["10AN"])
	S["s3"] = S["U0"]*Train.DIPon.Value
	S["s10"] = S["U0"]*Train.DIPoff.Value
	S["F1"] = S["10/4"]*Train.KV["10/4-F1"]
	S["D4"] = S["10/4"]*Train.A13.Value
	S["15"] = S["D4"]*Train.KV["D4-15"]+(-10*Train:ReadTrainWire(11))
	S["D4/3"] = S["D4"]*1
	S["22E'"] = S["10/4"]*Train.VMK.Value*Train.AK.Value
	S["12"] = S["D1"]*Train.KRZD.Value
	S["32V"] = S["D1"]*Train.KDP.Value
	S["F2a"] = S["F1"]*Train.A7.Value
	S["F1a"] = S["F1"]*Train.A9.Value
	S["ST/1+ST/2"] = S["D4/3"]*Train.BPT.Value
	S["16V/1+16V/2"] = S["D4/3"]*(1.0-Train.RD.Value)
	S["D6/1"] = S["D4/3"]*Train.BD.Value
	S["15A"] = S["15"]*1+T[5]*Train.KV["D8-15A"]
	S["15B"] = S["15A"]*S["15A-15B"]
	S["33G"] = 1*Train.ALS_ARS["33G"]+S["U2"]*Train.KV["U2-33G"]

	-- Call all triggers
	Train.Panel["HeadLights2"] = S["F13"]
	Triggers["XR3.4"](S["36Ya"])
	Train.Panel["KUP"] = S["B28"]
	Train.Panel["RedLightLeft"] = S["F1a"]
	Train:WriteTrainWire(22,S["22E'"])
	Train:WriteTrainWire(5,S["5"])
	Triggers["RRTpod"](S["10AH"])
	Train.PneumaticNo2:TriggerInput("Set",S["8G"])
	Train.Rper:TriggerInput("Set",S["3A"])
	Train:WriteTrainWire(12,S["12"])
	Train:WriteTrainWire(31,S["31V"])
	Train:WriteTrainWire(29,S["29"])
	Train.LK3:TriggerInput("Set",S["1Zh"])
	Train.RD:TriggerInput("Set",S["D6/1"])
	Train.TR2:TriggerInput("Set",S["6A"])
	Train:WriteTrainWire(32,S["32V"])
	Train.Panel["AVU"] = S["2-7R-24"]
	Train.RV2:TriggerInput("Set",S["33Aa"])
	T[8] = min(1,Train:ReadTrainWire(22))
	Train:WriteTrainWire(6,S["6"])
	Train.RVT:TriggerInput("Set",S["33G"])
	Train.Panel["CabinLight"] = S["10ALa"]
	Triggers["XR3.7"](S["36Ya"])
	Triggers["XR3.6"](S["36Ya"])
	Train:WriteTrainWire(2,S["2"])
	Triggers["ReverserBackward"](S["4B"])
	Train.Panel["HeadLights1"] = S["F10"]
	Train.LK2:TriggerInput("Set",S["20B"])
	T[12] = min(1,Train:ReadTrainWire(29))
	Triggers["KSB2"](S["6Yu"])
	T[6] = min(1,S["10AV"])
	Triggers["XR3.2"](S["27A"])
	Train:WriteTrainWire(23,S["1-7R-29"])
	Train:WriteTrainWire(25,S["25"])
	Train.PneumaticNo1:TriggerInput("Set",S["8Zh"])
	Train.VDOL:TriggerInput("Set",S["31A"])
	T[11] = min(1,S["8Zh"])
	Train.RPU:TriggerInput("Set",S["27A"])
	Train.SR1:TriggerInput("Set",S["2Ye"])
	Train.TR1:TriggerInput("Set",S["6A"])
	Triggers["RRTuderzh"](S["25A"])
	T[10] = min(1,Train:ReadTrainWire(5))
	T[9] = min(1,S["5V"])
	T[7] = min(1,S["22A"])
	Train.RV1:TriggerInput("Set",S["2Ye"])
	Train:WriteTrainWire(18,S["18A"])
	Train:WriteTrainWire(28,S["s10"])
	Triggers["KSB1"](S["6Yu"])
	T[5] = min(1,S["D8"])
	T[4] = min(1,S["12A"])
	Train:WriteTrainWire(10,S["10/4a"])
	T[2] = min(1,S["6A"])
	T[1] = min(1,S["27A"])
	Triggers["SDRK"](S["10N"])
	Train.Panel["TrainBrakes"] = S["ST/1+ST/2"]
	Train.Panel["V1"] = S["10/4"]
	Triggers["SDPP"](S["10AG"])
	Train:WriteTrainWire(1,S["1"])
	Triggers["KSH1"](S["1R"])
	Triggers["XR3.3"](S["28A"])
	Train.Panel["GreenRP"] = S["U0a"]
	Triggers["KPP"](S["27A"])
	Train.RZ_2:TriggerInput("Set",S["24V"])
	Triggers["LK5"](S["20B"])
	Triggers["RPvozvrat"](S["17A"])
	Train.VDZ:TriggerInput("Set",S["16V"])
	Train.Panel["SD"] = S["15B"]
	Train.Panel["RedRP"] = S["2-7R-21"]
	Train.LK4:TriggerInput("Set",S["5B'"])
	Train.KUP:TriggerInput("Set",S["B22"])
	Train.Panel["Ring"] = S["11B"]
	Train.Panel["HeadLights3"] = S["F13"]
	Train:WriteTrainWire(11,S["11A"])
	Train:WriteTrainWire(27,S["s3"])
	Triggers["XT3.1"](S["B13"])
	Train.LK1:TriggerInput("Set",S["1K"])
	Train.K25:TriggerInput("Set",Train.ALS_ARS["33Zh"])
	Train:WriteTrainWire(17,S["1-7R-8"])
	Train.RUP:TriggerInput("Set",S["6Yu"])
	Triggers["KSH2"](S["1R"])
	Train:WriteTrainWire(8,S["8"])
	Train.Panel["TrainRP"] = S["2-7R-21"]
	Train.KD:TriggerInput("Set",S["15B"])
	T[3] = min(1,S["12A"])
	Train:WriteTrainWire(4,S["4"])
	Triggers["ReverserForward"](S["5B"])
	Train.Panel["RedLightRight"] = S["F2a"]
	Train.VDOP:TriggerInput("Set",S["32A"])
	Train:WriteTrainWire(20,S["20"])
	Train:WriteTrainWire(24,S["24"])
	Train.RR:TriggerInput("Set",S["1N"])
	Train:WriteTrainWire(3,S["3"])
	Train:WriteTrainWire(16,S["16"])
	Train.Panel["TrainDoors"] = S["16V/1+16V/2"]
	Triggers["RUTpod"](S["10H"])
	Train.Panel["EmergencyLight"] = S["B12"]
	Train:WriteTrainWire(9,S["10/4a"])
	Train.KK:TriggerInput("Set",S["22V"])
	Train:WriteTrainWire(15,S["15"])
	Triggers["SDRK_Coil"](S["10B"])
	Train.R1_5:TriggerInput("Set",S["33V"])
	Train.KVC:TriggerInput("Set",S["B8"])
	return S
end


function TRAIN_SYSTEM.Solve81_717(Train,Triggers)
	local P		= Train.PositionSwitch.SelectedPosition
	local RK	= Train.RheostatController.SelectedPosition
	local B		= (Train.Battery.Voltage > 55) and 1 or 0
	
	-- Solve all circuits
	T["SDRK_ShortCircuit"] = -10*Train.RheostatController.RKP*(Train.RUT.Value+Train.RRT.Value+(1.0-Train.SR1.Value))
	Triggers["SDRK_Shunt"]( 1.0 - 0.25*C((RK >= 2) and (RK <= 7))*C(P == 1)*Train.LK2.Value )
	S["33-33Aa"] = Train.KD.Value+Train.VAD.Value
	S["U2-20"] = Train.KV["U2-20a"]+Train.KV["U2-20b"]
	S["D1-31V"] = Train.KDL.Value+Train.VDL.Value
	S["10AK-VAH1"] = Train.VAH.Value+Train.RPB.Value
	S["33B-33AVU"] = Train.AVU.Value+Train.OtklAVU.Value
	S["1T-1P"] = Train.NR.Value+Train.RPU.Value
	S["2Zh-2A"] = (1.0-Train.KSB1.Value)+(1.0-Train.TR1.Value)
	S["2Zh-2A"] = Train.ThyristorBU5_6.Value+S["2Zh-2A"]
	S["8A-8Ye"] = C(RK == 1)+(1.0-Train.LK4.Value)
	S["15A-15B"] = Train.KV["15A-15B"]+Train.KD.Value
	S["10AYa-10E"] = (1.0-Train.LK3.Value)+Train.Rper.Value
	S["10AP-10AD"] = Train.LK2.Value+C((P == 3) or (P == 4))
	S["10AE-10B"] = Train.TR1.Value+Train.RV1.Value
	S["10AE-10B"] = S["10AE-10B"]+Train.RV1.Value
	S["1A-1R"] = (1.0-Train.RV1.Value)*C((P == 1))+C((RK >= 1) and (RK <= 5))*C((P == 2))
	S["10-8"] = Train.KV["10-8"]+Train.KV["FR1-10"]*(1.0-Train.RPB.Value)
	S["2V-2G"] = C((RK >= 2) and (RK <= 4))*Train.KSH1.Value+C((RK >= 5) and (RK <= 18))
	S["10N-10Zh"] = (1.0-Train.RRT.Value)*(1.0-Train.RUT.Value)*Train.SR1.Value+Train.RheostatController.RKM1
	S["2G-2A"] = S["2V-2G"]*C((P == 2) or (P == 4))+C((P == 1) or (P == 3))*C((RK >= 1) and (RK <= 17))
	S["1E-1Yu"] = Train.KSH2.Value+Train.KSB2.Value*Train.KSB1.Value
	S["10AG-10AD"] = Train.TR1.Value*C((P == 1) or (P == 2) or (P == 4))*Train.TR2.Value+(1.0-Train.TR1.Value)*C((P == 2) or (P == 3) or (P == 4))*(1.0-Train.TR2.Value)
	S["10AG-10E"] = S["10AG-10AD"]*S["10AP-10AD"]*(1.0-Train.LK1.Value)+Train.LK3.Value*C(RK == 18)*C((P == 1))
	S["1Zh-1G"] = Train.LK2.Value*C((P == 1) or (P == 3))*C(RK == 1)*S["1E-1Yu"]+Train.LK3.Value
	S["10"] = 1*Train:ReadTrainWire(10)
	S["FR1/2"] = S["10"]*Train.KV["FR1-10"]
	S["20B"] = Train.A20.Value*(1.0-Train.RPvozvrat.Value)*Train:ReadTrainWire(20)
	S["10AL"] = S["10"]*Train.VU.Value
	S["10ALa"] = S["10AL"]*Train.A64.Value
	S["Sh1-43"] = S["10AL"]*Train.A45.Value
	S["10AS"] = S["10AL"]*Train.A55.Value
	S["10AK"] = S["10AL"]*Train.A54.Value
	S["6P"] = S["10AL"]*Train.A61.Value
	S["6"] = S["6P"]*Train.RVT.Value
	S["2-7R-24"] = S["6P"]*(1.0-Train.AVU.Value)
	S["29"] = S["2-7R-24"]*(1.0-Train.OtklAVU.Value)+Train.ALS_ARS["29"]
	S["8"] = S["10"]*S["10-8"]+Train.ALS_ARS["8"]
	S["F13"] = S["10"]*Train.KV["F7-10"]*Train.A46.Value
	S["10AN"] = Train.A14.Value*1*(1.0-Train.RPvozvrat.Value)*1
	S["F10"] = S["10"]*Train.KV["F7-10"]*Train.VUS.Value*Train.A47.Value
	S["1-7R-8"] = S["10AS"]*Train.KV["10AS-U4"]*Train.VozvratRP.Value
	S["B12"] = 1*Train.VB.Value*B
	S["B2"] = 1*Train.VB.Value*B
	S["1A"] = Train.A1.Value*Train:ReadTrainWire(1)
	S["1"] = S["10AS"]*Train.R1_5.Value*Train.KV["10AS-33D"]*Train.ALS_ARS["33D"]
	S["22A"] = Train.A23.Value*1*Train:ReadTrainWire(23)+T[18]*Train.A22.Value
	S["1P"] = S["1A"]*C((P == 1) or (P == 2))*S["1T-1P"]+T[13]*C((P == 3) or (P == 4))
	S["33V"] = S["10AK"]*Train.RV2.Value*S["10AK-VAH1"]*1*S["33B-33AVU"]
	S["33Aa"] = S["10AS"]*Train.KV["10AS-33"]*S["33-33Aa"]
	S["18A"] = Train.LK4.Value*Train.A14.Value*(1.0-Train.RPvozvrat.Value)*1
	S["16V"] = Train.A16.Value*(1.0-Train.RD.Value)*Train:ReadTrainWire(16)
	S["2Ye"] = S["2G-2A"]*Train.LK4.Value*S["2Zh-2A"]*Train.A2.Value*Train:ReadTrainWire(2)+T[16]*(1.0-Train.LK4.Value)
	S["1-7R-29"] = S["B2"]*Train.A44.Value*Train.RezMK.Value
	S["3A"] = Train.A3.Value*Train:ReadTrainWire(3)
	S["4B"] = (1.0-Train.RKR.Value)*Train:ReadTrainWire(4)
	S["5B"] = Train.RKR.Value*Train:ReadTrainWire(5)
	S["5V"] = Train.RKR.Value*Train:ReadTrainWire(4)+T[20]*(1.0-Train.RKR.Value)
	S["5B'"] = S["5V"]*Train.LK3.Value
	S["6A"] = Train.A6.Value*Train:ReadTrainWire(6)
	S["8A"] = Train.A8.Value*Train:ReadTrainWire(8)
	S["8Zh"] = S["8A"]*C((RK >= 17) and (RK <= 18))+T[24]*1
	S["11A"] = S["B2"]*(1.0-Train.RD.Value)
	S["12A"] = Train.A12.Value*Train:ReadTrainWire(12)
	S["D8"] = 1*Train:ReadTrainWire(15)+T[22]*Train.KV["D8-15A"]
	S["17A"] = Train.A17.Value*Train:ReadTrainWire(17)
	S["24V"] = (1.0-Train.LK4.Value)*Train:ReadTrainWire(24)
	S["25A"] = Train.A25.Value*Train:ReadTrainWire(25)
	S["27A"] = Train.A50.Value*Train:ReadTrainWire(27)
	S["31A"] = Train.A31.Value*Train:ReadTrainWire(31)+T[14]*1
	S["32A"] = Train.A32.Value*Train:ReadTrainWire(32)+T[15]*1
	S["10AYa"] = S["B2"]*Train.A80.Value
	S["10AE"] = S["B2"]*Train.A30.Value
	S["10I"] = S["10AE"]*Train.RheostatController.RKM2
	S["10AH"] = S["10I"]*(1.0-Train.LK1.Value)+0
	S["10H"] = S["10I"]*Train.LK4.Value
	S["B8"] = S["B2"]*Train.A53.Value
	S["B22"] = S["B8"]*Train.A75.Value
	S["B28"] = S["B8"]*Train.KUP.Value
	S["36Ya"] = S["B8"]*Train.KVC.Value
	S["B13"] = S["B12"]*Train.A24.Value
	S["4"] = S["10AK"]*Train.KV["10AK-4"]
	S["5"] = S["10AK"]*Train.KV["10AK-5"]
	S["U2"] = S["10AS"]*Train.KV["U2-10AS"]
	S["24"] = S["U2"]*Train.KSN.Value
	S["2-7R-21"] = S["U2"]*1+(-10*Train:ReadTrainWire(18))
	S["2"] = S["10AK"]*Train.KV["10AK-2"]+Train.ALS_ARS["2"]
	S["3"] = S["U2"]*Train.KV["U2-3"]
	S["10B"] = S["10AE"]*S["10AE-10B"]
	S["10/4"] = S["B12"]*Train.VB.Value*Train.A56.Value+(1-Train.VB.Value)*Train:ReadTrainWire(10)
	S["1R"] = S["1A"]*S["1A-1R"]
	S["22E'"] = S["10/4"]*Train.VMK.Value*Train.AK.Value
	S["6Yu"] = S["6A"]*C((P == 3) or (P == 4))*C((RK >= 1) and (RK <= 5))
	S["10N"] = S["10AE"]*S["10N-10Zh"]*1+T["SDRK_ShortCircuit"]
	S["8G"] = S["8A"]*(1.0-Train.RT2.Value)*S["8A-8Ye"]
	S["22V"] = S["22A"]*(1.0-Train.TRK.Value)
	S["10AG"] = S["10AYa"]*S["10AYa-10E"]*S["10AG-10E"]
	S["1Zh"] = S["1P"]*S["1Zh-1G"]*Train.AVT.Value*(1.0-Train.RPvozvrat.Value)
	S["25"] = S["U2"]*Train.KV["U2-25"]*Train.K25.Value
	S["10AV"] = S["10AYa"]*(1.0-Train.LK3.Value)*C((RK >= 2) and (RK <= 18))
	S["1K"] = S["1Zh"]*C((P == 1) or (P == 2))
	S["1N"] = S["1Zh"]*C((P == 1) or (P == 3))
	S["D1"] = S["10/4"]*Train.A21.Value*Train.KV["D-D1"]
	S["11B"] = S["10/4"]*Train.KV["10/4-C3"]*(1.0-Train.NR.Value)
	S["16"] = S["D1"]*Train.VUD1.Value*Train.VUD2.Value
	S["20"] = S["U2"]*S["U2-20"]+Train.ALS_ARS["20"]
	S["31V"] = S["D1"]*S["D1-31V"]
	S["10/4a"] = S["10/4"]*Train.VB.Value
	S["22K"] = S["10/4"]*Train.A10.Value
	S["U0"] = S["10/4"]*Train.A27.Value
	S["U0a"] = S["U0"]*1+(-10*S["10AN"])
	S["s3"] = S["U0"]*Train.BPSNon.Value
	S["F1"] = S["10/4"]*Train.KV["10/4-F1"]
	S["D4"] = S["10/4"]*Train.A13.Value
	S["15"] = S["D4"]*Train.KV["D4-15"]+(-10*Train:ReadTrainWire(11))
	S["D4/3"] = S["D4"]*1
	S["12"] = S["D1"]*Train.KRZD.Value
	S["32V"] = S["D1"]*Train.KDP.Value
	S["F2a"] = S["F1"]*Train.A7.Value
	S["F1a"] = S["F1"]*Train.A9.Value
	S["ST/1+ST/2"] = S["D4/3"]*Train.BPT.Value
	S["16V/1+16V/2"] = S["D4/3"]*(1.0-Train.RD.Value)
	S["D6/1"] = S["D4/3"]*Train.BD.Value
	S["15A"] = S["15"]*1+T[21]*Train.KV["D8-15A"]
	S["15B"] = S["15A"]*S["15A-15B"]
	S["33G"] = 1*Train.ALS_ARS["33G"]+S["U2"]*Train.KV["U2-33G"]

	-- Call all triggers
	Train.Panel["HeadLights2"] = S["F13"]
	Triggers["XR3.4"](S["36Ya"])
	Train.Panel["KUP"] = S["B28"]
	Train.Panel["RedLightLeft"] = S["F1a"]
	Train:WriteTrainWire(22,S["22E'"])
	Train:WriteTrainWire(5,S["5"])
	Triggers["RRTpod"](S["10AH"])
	Train.PneumaticNo2:TriggerInput("Set",S["8G"])
	Train.Rper:TriggerInput("Set",S["3A"])
	Train:WriteTrainWire(12,S["12"])
	Train:WriteTrainWire(31,S["31V"])
	Train:WriteTrainWire(29,S["29"])
	Train.LK3:TriggerInput("Set",S["1Zh"])
	Train.RD:TriggerInput("Set",S["D6/1"])
	Train.TR2:TriggerInput("Set",S["6A"])
	Train:WriteTrainWire(32,S["32V"])
	T[17] = min(1,S["22A"])
	Train.Panel["AVU"] = S["2-7R-24"]
	Train.RV2:TriggerInput("Set",S["33Aa"])
	Train:WriteTrainWire(6,S["6"])
	Train.RVT:TriggerInput("Set",S["33G"])
	Train.Panel["CabinLight"] = S["10ALa"]
	Triggers["XR3.7"](S["36Ya"])
	Triggers["XR3.6"](S["36Ya"])
	Train:WriteTrainWire(2,S["2"])
	Triggers["ReverserBackward"](S["4B"])
	Train.Panel["HeadLights1"] = S["F10"]
	Train.LK2:TriggerInput("Set",S["20B"])
	Train.KSB2:TriggerInput("Set",S["6Yu"])
	Triggers["XR3.2"](S["27A"])
	Train:WriteTrainWire(23,S["1-7R-29"])
	Train:WriteTrainWire(25,S["25"])
	Train.PneumaticNo1:TriggerInput("Set",S["8Zh"])
	Train.VDOL:TriggerInput("Set",S["31A"])
	T[24] = min(1,Train:ReadTrainWire(29))
	Train.SR1:TriggerInput("Set",S["2Ye"])
	Train.TR1:TriggerInput("Set",S["6A"])
	Triggers["RRTuderzh"](S["25A"])
	T[20] = min(1,Train:ReadTrainWire(5))
	Train.R1_5:TriggerInput("Set",S["33V"])
	Train.Panel["TrainDoors"] = S["16V/1+16V/2"]
	Train.RUP:TriggerInput("Set",S["6Yu"])
	Train:WriteTrainWire(18,S["18A"])
	Triggers["ReverserForward"](S["5B"])
	Train.KSB1:TriggerInput("Set",S["6Yu"])
	Triggers["KPP"](S["27A"])
	T[18] = min(1,Train:ReadTrainWire(22))
	T[16] = min(1,S["10AV"])
	T[15] = min(1,S["12A"])
	Train.Panel["TrainBrakes"] = S["ST/1+ST/2"]
	T[13] = min(1,S["6A"])
	Triggers["SDRK"](S["10N"])
	Train.Panel["EmergencyLight"] = S["B12"]
	Train.Panel["V1"] = S["10/4"]
	Train.Panel["GreenRP"] = S["U0a"]
	Train.KSH1:TriggerInput("Set",S["1R"])
	Triggers["SDPP"](S["10AG"])
	Train:WriteTrainWire(1,S["1"])
	T[19] = min(1,S["5V"])
	Train.RZ_2:TriggerInput("Set",S["24V"])
	Triggers["LK5"](S["20B"])
	Triggers["RPvozvrat"](S["17A"])
	Train.VDZ:TriggerInput("Set",S["16V"])
	Train.Panel["SD"] = S["15B"]
	Train.Panel["RedRP"] = S["2-7R-21"]
	Train.RR:TriggerInput("Set",S["1N"])
	Train.KUP:TriggerInput("Set",S["B22"])
	Train.Panel["Ring"] = S["11B"]
	Train.Panel["HeadLights3"] = S["F13"]
	Train:WriteTrainWire(11,S["11A"])
	Train:WriteTrainWire(27,S["s3"])
	Triggers["XT3.1"](S["B13"])
	Train.LK1:TriggerInput("Set",S["1K"])
	Train.K25:TriggerInput("Set",Train.ALS_ARS["33Zh"])
	Train:WriteTrainWire(17,S["1-7R-8"])
	Train:WriteTrainWire(8,S["8"])
	Train.KSH2:TriggerInput("Set",S["1R"])
	Train.RV1:TriggerInput("Set",S["2Ye"])
	Train.Panel["TrainRP"] = S["2-7R-21"]
	Train.KD:TriggerInput("Set",S["15B"])
	Train:WriteTrainWire(10,S["10/4a"])
	Train:WriteTrainWire(4,S["4"])
	Train.LK4:TriggerInput("Set",S["5B'"])
	T[21] = min(1,S["D8"])
	Train.VDOP:TriggerInput("Set",S["32A"])
	Train:WriteTrainWire(20,S["20"])
	Train:WriteTrainWire(24,S["24"])
	Train.Panel["RedLightRight"] = S["F2a"]
	Train:WriteTrainWire(3,S["3"])
	Train:WriteTrainWire(16,S["16"])
	T[22] = min(1,S["15A"])
	Triggers["RUTpod"](S["10H"])
	T[14] = min(1,S["12A"])
	Train:WriteTrainWire(9,S["10/4a"])
	Train.KK:TriggerInput("Set",S["22V"])
	Train:WriteTrainWire(15,S["15"])
	Triggers["SDRK_Coil"](S["10B"])
	T[23] = min(1,S["8Zh"])
	Train.KVC:TriggerInput("Set",S["B8"])
	return S
end


function TRAIN_SYSTEM.Solve81_714(Train,Triggers)
	local P		= Train.PositionSwitch.SelectedPosition
	local RK	= Train.RheostatController.SelectedPosition
	local B		= (Train.Battery.Voltage > 55) and 1 or 0
	
	-- Solve all circuits
	T["SDRK_ShortCircuit"] = -10*Train.RheostatController.RKP*(Train.RUT.Value+Train.RRT.Value+(1.0-Train.SR1.Value))
	Triggers["SDRK_Shunt"]( 1.0 - 0.25*C((RK >= 2) and (RK <= 7))*C(P == 1)*Train.LK2.Value )
	S["1T-1P"] = Train.NR.Value+Train.RPU.Value
	S["2Zh-2A"] = (1.0-Train.KSB1.Value)+(1.0-Train.TR1.Value)
	S["8A-8Ye"] = C(RK == 1)+(1.0-Train.LK4.Value)
	S["10AYa-10E"] = (1.0-Train.LK3.Value)+Train.Rper.Value
	S["10AP-10AD"] = Train.LK2.Value+C((P == 3) or (P == 4))
	S["10AE-10B"] = Train.TR1.Value+Train.RV1.Value
	S["10AE-10B"] = S["10AE-10B"]+Train.RV1.Value
	S["2V-2G"] = C((RK >= 5) and (RK <= 18))+C((RK >= 2) and (RK <= 4))*Train.KSH1.Value
	S["1A-1R"] = (1.0-Train.RV1.Value)*C((P == 1))+C((RK >= 1) and (RK <= 5))*C((P == 2))
	S["2A-2G"] = C((P == 2) or (P == 4))*S["2V-2G"]+C((P == 1) or (P == 3))*C((RK >= 1) and (RK <= 17))
	S["1E-1Yu"] = Train.KSH2.Value+Train.KSB2.Value*Train.KSB1.Value
	S["10AD-10AG"] = Train.TR2.Value*Train.TR1.Value*C((P == 1) or (P == 2) or (P == 4))+(1.0-Train.TR1.Value)*C((P == 2) or (P == 3) or (P == 4))*(1.0-Train.TR2.Value)
	S["10Zh-10N"] = Train.SR1.Value*(1.0-Train.RRT.Value)*(1.0-Train.RUT.Value)+Train.RheostatController.RKM1
	S["1G-1Zh"] = Train.LK3.Value+Train.LK2.Value*C((P == 1) or (P == 3))*C(RK == 1)*S["1E-1Yu"]
	S["10AG-10E"] = C((P == 1))*Train.LK3.Value*C(RK == 18)+S["10AP-10AD"]*S["10AD-10AG"]*(1.0-Train.LK1.Value)
	S["10"] = 1*Train:ReadTrainWire(10)
	S["1A"] = Train.A1.Value*Train:ReadTrainWire(1)
	S["20B"] = Train.A20.Value*(1.0-Train.RPvozvrat.Value)*Train:ReadTrainWire(20)
	S["3A"] = Train.A3.Value*Train:ReadTrainWire(3)
	S["4B"] = (1.0-Train.RKR.Value)*Train:ReadTrainWire(4)
	S["5B"] = Train.RKR.Value*Train:ReadTrainWire(5)
	S["5V"] = Train.RKR.Value*Train:ReadTrainWire(4)+T[32]*(1.0-Train.RKR.Value)
	S["5B'"] = S["5V"]*Train.LK3.Value
	S["6A"] = Train.A6.Value*Train:ReadTrainWire(6)
	S["8A"] = Train.A8.Value*Train:ReadTrainWire(8)
	S["8Zh"] = S["8A"]*C((RK >= 17) and (RK <= 18))+T[34]*1
	S["12A"] = Train.A12.Value*Train:ReadTrainWire(12)
	S["10AN"] = 1*(1.0-Train.RPvozvrat.Value)*Train.A14.Value*1
	S["2Ye"] = Train.A2.Value*Train.LK4.Value*S["2Zh-2A"]*S["2A-2G"]*Train:ReadTrainWire(2)+T[28]*(1.0-Train.LK4.Value)
	S["17A"] = Train.A17.Value*Train:ReadTrainWire(17)
	S["1R"] = S["1A"]*S["1A-1R"]
	S["16V"] = Train.A16.Value*(1.0-Train.RD.Value)*Train:ReadTrainWire(16)
	S["24V"] = (1.0-Train.LK4.Value)*Train:ReadTrainWire(24)
	S["18A"] = (1.0-Train.RPvozvrat.Value)*Train.LK4.Value*Train.A14.Value*1
	S["25A"] = Train.A25.Value*Train:ReadTrainWire(25)
	S["B12"] = 1*Train.VB.Value*B
	S["27A"] = Train.A50.Value*Train:ReadTrainWire(27)
	S["31A"] = Train.A31.Value*Train:ReadTrainWire(31)+T[26]*1
	S["32A"] = Train.A32.Value*Train:ReadTrainWire(32)+T[27]*1
	S["10/4"] = S["B12"]*Train.VB.Value*Train.A56.Value
	S["6Yu"] = S["6A"]*C((P == 3) or (P == 4))*C((RK >= 1) and (RK <= 5))
	S["22A"] = Train.A23.Value*1*Train:ReadTrainWire(23)+T[30]*Train.A22.Value
	S["B2"] = 1*Train.VB.Value*B
	S["10AE"] = S["B2"]*Train.A30.Value
	S["1P"] = S["1A"]*C((P == 1) or (P == 2))*S["1T-1P"]+T[25]*C((P == 3) or (P == 4))
	S["10I"] = S["10AE"]*Train.RheostatController.RKM2
	S["10AH"] = S["10I"]*(1.0-Train.LK1.Value)
	S["10H"] = S["10I"]*Train.LK4.Value
	S["D4/3"] = S["10/4"]*Train.A13.Value*1
	S["8G"] = S["8A"]*S["8A-8Ye"]*(1.0-Train.RT2.Value)
	S["1Zh"] = S["1P"]*Train.AVT.Value*(1.0-Train.RPvozvrat.Value)*S["1G-1Zh"]
	S["B8"] = S["B2"]*Train.A53.Value
	S["B22"] = S["B8"]*Train.A75.Value
	S["B28"] = S["B8"]*Train.KUP.Value
	S["36Ya"] = S["B8"]*Train.KVC.Value
	S["10/4a"] = S["10/4"]*Train.VB.Value
	S["B13"] = S["B12"]*Train.A24.Value
	S["D"] = S["10/4"]*Train.A21.Value
	S["22V"] = S["22A"]*(1.0-Train.TRK.Value)
	S["ST/1+ST/2"] = S["D4/3"]*Train.BPT.Value
	S["16V/1+16V/2"] = S["D4/3"]*(1.0-Train.RD.Value)
	S["D6/1"] = S["D4/3"]*Train.BD.Value
	S["1K"] = S["1Zh"]*C((P == 1) or (P == 2))
	S["1N"] = S["1Zh"]*C((P == 1) or (P == 3))
	S["10B"] = S["10AE"]*S["10AE-10B"]
	S["11A"] = S["B2"]*(1.0-Train.RD.Value)
	S["10N"] = S["10AE"]*S["10Zh-10N"]*1+T["SDRK_ShortCircuit"]
	S["10AYa"] = S["B2"]*Train.A80.Value
	S["10AV"] = S["10AYa"]*(1.0-Train.LK3.Value)*C((RK >= 2) and (RK <= 18))
	S["10AG"] = S["10AYa"]*S["10AYa-10E"]*S["10AG-10E"]

	-- Call all triggers
	Train.SR1:TriggerInput("Set",S["2Ye"])
	Train.TR1:TriggerInput("Set",S["6A"])
	Triggers["XT3.1"](S["B13"])
	Triggers["XR3.4"](S["36Ya"])
	Train.Panel["KUP"] = S["B28"]
	Train.RUP:TriggerInput("Set",S["6Yu"])
	Train:WriteTrainWire(18,S["18A"])
	T[30] = min(1,Train:ReadTrainWire(22))
	Train.KSB1:TriggerInput("Set",S["6Yu"])
	Triggers["RRTpod"](S["10AH"])
	Train.PneumaticNo2:TriggerInput("Set",S["8G"])
	Train.Rper:TriggerInput("Set",S["3A"])
	Train.Panel["TrainDoors"] = S["16V/1+16V/2"]
	Triggers["SDRK_Coil"](S["10B"])
	Train.Panel["TrainBrakes"] = S["ST/1+ST/2"]
	Train.KSH1:TriggerInput("Set",S["1R"])
	Train.RD:TriggerInput("Set",S["D6/1"])
	Train:WriteTrainWire(11,S["11A"])
	Train.KVC:TriggerInput("Set",S["B8"])
	Train.TR2:TriggerInput("Set",S["6A"])
	T[31] = min(1,S["5V"])
	T[28] = min(1,S["10AV"])
	Train.Panel["EmergencyLight"] = S["B12"]
	T[29] = min(1,S["22A"])
	Train.LK4:TriggerInput("Set",S["5B'"])
	T[27] = min(1,S["12A"])
	Train.KUP:TriggerInput("Set",S["B22"])
	T[26] = min(1,S["12A"])
	T[25] = min(1,S["6A"])
	Triggers["SDRK"](S["10N"])
	Train.VDZ:TriggerInput("Set",S["16V"])
	Train.KSH2:TriggerInput("Set",S["1R"])
	Train.LK1:TriggerInput("Set",S["1K"])
	Triggers["XR3.7"](S["36Ya"])
	Triggers["XR3.6"](S["36Ya"])
	T[34] = min(1,Train:ReadTrainWire(29))
	Triggers["ReverserBackward"](S["4B"])
	Triggers["SDPP"](S["10AG"])
	Triggers["RRTuderzh"](S["25A"])
	Train.LK2:TriggerInput("Set",S["20B"])
	Train:WriteTrainWire(10,S["10/4a"])
	Train.RR:TriggerInput("Set",S["1N"])
	Triggers["KPP"](S["27A"])
	Train.KSB2:TriggerInput("Set",S["6Yu"])
	Train.VDOP:TriggerInput("Set",S["32A"])
	Triggers["ReverserForward"](S["5B"])
	Triggers["XR3.2"](S["27A"])
	Train.RZ_2:TriggerInput("Set",S["24V"])
	Triggers["LK5"](S["20B"])
	Triggers["RPvozvrat"](S["17A"])
	T[33] = min(1,S["8Zh"])
	Triggers["RUTpod"](S["10H"])
	Train.RV1:TriggerInput("Set",S["2Ye"])
	Train:WriteTrainWire(9,S["10/4a"])
	Train.KK:TriggerInput("Set",S["22V"])
	Train.PneumaticNo1:TriggerInput("Set",S["8Zh"])
	Train.VDOL:TriggerInput("Set",S["31A"])
	T[32] = min(1,Train:ReadTrainWire(5))
	Train.LK3:TriggerInput("Set",S["1Zh"])
	return S
end



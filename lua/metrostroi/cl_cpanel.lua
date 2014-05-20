--Helper function for common use
local function AddBox(panel,cmd,str)
	panel:AddControl("CheckBox",{Label=str, Command=cmd})
end

-- Build admin panel
local function AdminPanel(panel)
	if not LocalPlayer():IsAdmin() then return end
	AddBox(panel,"metrostroi_train_requirethirdrail","Trains require 3rd rail")
	--panel:AddControl("CheckBox",{Label="Trains require 3rd rail", Command = "metrostroi_train_requirethirdrail"})
	
end

-- Build regular client panel
local function ClientPanel(panel)
	--panel:AddControl("Checkbox",{Label="Draw debugging info", Command = "metrostroi_drawdebug"})
	AddBox(panel,"metrostroi_drawdebug","Draw debugging info")
	AddBox(panel,"metrostroi_stop_helper","Show stop location helper")
	AddBox(panel,"metrostroi_crazy_thomas_mode","Crazy Thomas Mode")
	
	panel:AddControl("Slider", {
		Label = "Tooltip delay",
		Type = "Integer",
		Min = "-1",
		Max = "5",
		Command = "metrostroi_tooltip_delay"
	})
	
end

hook.Add("PopulateToolMenu", "Metrostroi cpanel", function()
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi", "metrostroi_admin_panel", "Admin", "", "", AdminPanel)
	spawnmenu.AddToolMenuOption("Utilities", "Metrostroi", "metrostroi_client_panel", "Client", "", "", ClientPanel)
end)
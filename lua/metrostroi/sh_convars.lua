--Not sure about the quirks related to shared convars like this
CreateConVar("metrostroi_train_requirethirdrail",1,FCVAR_ARCHIVE,"Whether or not Metrostroi trains require power from the third rail")
CreateConVar("metrostroi_debugger_update_interval",1,FCVAR_ARCHIVE,"Seconds between debugger data messages")

RunConsoleCommand("metrostroi_train_requirethirdrail",(string.find(game.GetMap(),"gm_metrostroi") and 1 or 0))


if SERVER then return end

CreateClientConVar("metrostroi_stop_helper",0,true)
CreateClientConVar("metrostroi_drawdebug",0,true)
CreateClientConVar("metrostroi_debugger_data_timeout",2,true,false)

CreateClientConVar("metrostroi_tooltip_delay",0,true)

CreateClientConVar("metrostroi_crazy_thomas_mode",0,true)


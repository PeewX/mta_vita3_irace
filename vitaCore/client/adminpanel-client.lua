--[[
Project: vitaCore
File: adminpanel-client.lua
Author(s):	Sebihunter
]]--

adminPanelWindow = guiCreateWindow ( screenWidth / 2 - 310, screenHeight / 2 - 260, 620, 520, "Adminpanel", false )
guiWindowSetSizable ( adminPanelWindow, false )
guiSetAlpha( adminPanelWindow, 0)
guiSetVisible( adminPanelWindow, false )

guiAdminDX = {}

guiAdminDX["player_list"] = dxCreateGridList(0,0,200,400,false)
guiAdminDX["player_refresh"] = dxCreateButton(0,0,100,24,"Gamemode",false)
guiAdminDX["player_refresh2"] = dxCreateButton(0,0,100,24,"All",false)
guiAdminDX["player_level"] = dxCreateButton(0,0,150,24,"Level (0 - *)",false)
guiAdminDX["player_points"] = dxCreateButton(0,0,150,24,"Points (0 - *)",false)
guiAdminDX["player_money"] = dxCreateButton(0,0,150,24,"Money (0 - *)",false)
guiAdminDX["player_rights"] = dxCreateButton(0,0,150,24,"Rights (Member/Recruit/...)",false)
guiAdminDX["player_memes"] = dxCreateButton(0,0,150,24,"Memes [0/1]",false)
guiAdminDX["player_donator"] = dxCreateButton(0,0,150,24,"Donator [0/1]  [DATE]",false)
guiAdminDX["player_achievement"] = dxCreateButton(0,0,150,24,"Achievement [ID]",false)
guiAdminDX["player_mute"] = dxCreateButton(0,0,150,24,"Mute (Minutes)",false)
guiAdminDX["player_kick"] = dxCreateButton(0,0,150,24,"Kick",false)
guiAdminDX["player_ban"] = dxCreateButton(0,0,150,24,"Ban (Minutes)",false)
guiAdminDX["player_blow"] = dxCreateButton(0,0,150,24,"Kill",false)

guiAdminDX["maps_list"] = dxCreateGridList(0,0,300,400,false)
guiAdminDX["maps_set"] = dxCreateButton(0,0,270,24,"Set Next",false)
guiAdminDX["maps_redo"] = dxCreateButton(0,0,270,24,"Redo Current",false)
guiAdminDX["maps_skip"] = dxCreateButton(0,0,270,24,"Skip Current",false)
guiAdminDX["maps_delete"] = dxCreateButton(0,0,270,24,"Delete Selected",false)
guiAdminDX["maps_fix"] = dxCreateButton(0,0,270,24,"Fix Selected",false)

guiAdminDX["bans_list"] = dxCreateGridList(0,0,600,380,false)
guiAdminDX["bans_refresh"] = dxCreateButton(0,0,200,24,"Refresh",false)
guiAdminDX["bans_delete"] = dxCreateButton(0,0,200,24,"Delete Selected",false)
guiAdminDX["bans_serial"] = dxCreateButton(0,0,200,24,"Ban Serial",false)
guiAdminDX["bans_ip"] = dxCreateButton(0,0,185,24,"Ban IP",false)

addEventHandler ( "onClientDXClick", guiAdminDX["player_refresh"], function() refreshAdminPanel("players") end, false )
addEventHandler ( "onClientDXClick", guiAdminDX["player_refresh2"], function() refreshAdminPanel("allplayers") end, false )
addEventHandler ( "onClientDXClick", guiAdminDX["bans_refresh"], function() refreshAdminPanel("bans") end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["bans_delete"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["bans_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["bans_list"],  row ) then
		triggerServerEvent ( "clientDeleteBan", getLocalPlayer(), dxGridListGetItemData ( guiAdminDX["bans_list"],  row )) 
	else
		addNotification(1, 200, 50, 50, "No ban selected.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["bans_ip"], function() 
	executeServerCommandHandler ( "banIP", guiGetText(guiAdminGUI["bans_edit"]) )
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["bans_serial"], function() 
	executeServerCommandHandler ( "serialBan", guiGetText(guiAdminGUI["bans_edit"]) )
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["maps_set"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["maps_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["maps_list"],  row ) then
		executeServerCommandHandler ( "setnextmap", dxGridListGetItemData ( guiAdminDX["maps_list"],  row ) )
	else
		addNotification(1, 200, 50, 50, "No map selected.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["maps_skip"], function() 
	executeServerCommandHandler ( "skipMap" )
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["maps_redo"], function() 
	executeServerCommandHandler ( "redo" )
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["maps_delete"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["maps_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["maps_list"],  row ) then
		executeServerCommandHandler ( "deleteMap", dxGridListGetItemData ( guiAdminDX["maps_list"],  row ) )
	else
		addNotification(1, 200, 50, 50, "No map selected.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["maps_fix"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["maps_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["maps_list"],  row ) then
		executeServerCommandHandler ( "fixMap", dxGridListGetItemData ( guiAdminDX["maps_list"],  row ) )
	else
		addNotification(1, 200, 50, 50, "No map selected.")
	end
end, false )


addEventHandler ( "onClientDXClick", guiAdminDX["player_ban"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and tonumber(guiGetText(guiAdminGUI["player_edit"])) >= 0 then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "banPlayer", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_kick"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
		executeServerCommandHandler ( "kickPlayer", dxGridListGetItemText ( guiAdminDX["player_list"],  row ) )
	else
		addNotification(1, 200, 50, 50, "No player selected.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_blow"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
		executeServerCommandHandler ( "pkill", dxGridListGetItemText ( guiAdminDX["player_list"],  row ) )
	else
		addNotification(1, 200, 50, 50, "No player selected.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_mute"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and tonumber(guiGetText(guiAdminGUI["player_edit"])) >= 0 then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "mutePlayer", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_achievement"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and tonumber(guiGetText(guiAdminGUI["player_edit"])) > 0 then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "addachievement", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_donator"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and (tonumber(guiGetText(guiAdminGUI["player_edit"])) == 0 or tonumber(guiGetText(guiAdminGUI["player_edit"])) == 1) then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "setdonator", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_memes"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and (tonumber(guiGetText(guiAdminGUI["player_edit"])) == 0 or tonumber(guiGetText(guiAdminGUI["player_edit"])) == 1) then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "setmemeacc", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_rights"], function() 
	local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
	if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
		executeServerCommandHandler ( "setrights", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
	else
		addNotification(1, 200, 50, 50, "No player selected.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_money"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and tonumber(guiGetText(guiAdminGUI["player_edit"])) > 0 then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "setmoney", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )

addEventHandler ( "onClientDXClick", guiAdminDX["player_points"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and tonumber(guiGetText(guiAdminGUI["player_edit"])) > 0 then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "setpoints", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )


addEventHandler ( "onClientDXClick", guiAdminDX["player_level"], function() 
	if tonumber(guiGetText(guiAdminGUI["player_edit"])) and tonumber(guiGetText(guiAdminGUI["player_edit"])) > 0 then
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row and dxGridListGetItemData ( guiAdminDX["player_list"],  row ) and isElement(dxGridListGetItemData ( guiAdminDX["player_list"],  row )) then
			executeServerCommandHandler ( "setlevel", dxGridListGetItemText ( guiAdminDX["player_list"],  row ).." "..guiGetText(guiAdminGUI["player_edit"]) )
		else
			addNotification(1, 200, 50, 50, "No player selected.")
		end
	else
		addNotification(1, 200, 50, 50, "Needed information missing or corrupt in editbox.")
	end
end, false )



for i,v in pairs(guiAdminDX) do
	dxSetVisible(v, false)
end


guiAdminGUI = {}

guiAdminGUI["adminBox"] = guiCreateComboBox ( 0,0, 180, 85, "", false )
guiComboBoxAddItem( guiAdminGUI["adminBox"], "Players" )
guiComboBoxAddItem( guiAdminGUI["adminBox"], "Maps" )
guiComboBoxAddItem( guiAdminGUI["adminBox"], "Banlist" )

guiAdminGUI["player_edit"] = guiCreateEdit ( 0,0, 302, 24, "", false )
guiAdminGUI["maps_edit"] = guiCreateEdit ( 0,0, 300, 20, "", false )
guiAdminGUI["bans_edit"] = guiCreateEdit ( 0,0, 200, 20, "", false )

addEventHandler("onClientGUIChanged", guiAdminGUI["maps_edit"], function() 
	if guiGetText(source) == "" then
		if getPlayerGameMode(getLocalPlayer()) == 1 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsSH)
		elseif getPlayerGameMode(getLocalPlayer()) == 2 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsDD)
		elseif getPlayerGameMode(getLocalPlayer()) == 3 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsRA)		
		elseif getPlayerGameMode(getLocalPlayer()) == 5 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsDM)
		elseif getPlayerGameMode(localPlayer) == GAMEMODES.TT then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsDM)
		end
	else
		local mapTable = {}
		local mapTable2 = {}
		if getPlayerGameMode(getLocalPlayer()) == 1 then
			mapTable = gAllTheMapsSH
		elseif getPlayerGameMode(getLocalPlayer()) == 2 then
			mapTable = gAllTheMapsDD
		elseif getPlayerGameMode(getLocalPlayer()) == 3 then
			mapTable = gAllTheMapsRA
		elseif getPlayerGameMode(getLocalPlayer()) == 5 then
			mapTable = gAllTheMapsDM
		elseif getPlayerGameMode(localPlayer) == GAMEMODES.TT then
			mapTable = gAllTheMapsDM
		end

		for i,v in ipairs(mapTable) do
			if string.find (string.upper (tostring(v.text)), string.upper (guiGetText(source))) ~= nil then
				mapTable2[#mapTable2+1] = v
			end
		end
		dxGridListClear(guiAdminDX["maps_list"])
		dxGridListReplaceRows(guiAdminDX["maps_list"], mapTable2)
	end
end)


for i,v in pairs(guiAdminGUI) do
	guiSetVisible(v, false)
end

function refreshAdminPanel(refresh)
	if refresh == "players" or "all" then
		dxGridListClear(guiAdminDX["player_list"])
		for i,v in pairs(getGamemodePlayers(getPlayerGameMode(getLocalPlayer()))) do
			dxGridListAddRow(guiAdminDX["player_list"], getPlayerName(v), v)
		end
	end
	
	if refresh == "allplayers" then
		dxGridListClear(guiAdminDX["player_list"])
		for i,v in pairs(getElementsByType("player")) do
			if isLoggedIn(v) then
				dxGridListAddRow(guiAdminDX["player_list"], getPlayerName(v), v)
			end
		end	
	end
	
	if refresh == "maps" or "all" then
		dxGridListClear(guiAdminDX["maps_list"])
		if getPlayerGameMode(getLocalPlayer()) == 1 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsSH)
		elseif getPlayerGameMode(getLocalPlayer()) == 2 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsDD)
		elseif getPlayerGameMode(getLocalPlayer()) == 3 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsRA)		
		elseif getPlayerGameMode(getLocalPlayer()) == 5 then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsDM)
		elseif getPlayerGameMode(localPlayer) == GAMEMODES.TT then
			dxGridListReplaceRows(guiAdminDX["maps_list"], gAllTheMapsDM)
		end
	end
	
	guiSetText(guiAdminGUI["maps_edit"], "")
	guiSetText(guiAdminGUI["player_edit"], "")	
	guiSetText(guiAdminGUI["maps_edit"], "")
	
	if refresh == "bans" or "all" then
		triggerServerEvent ( "clientRequestBanList", getLocalPlayer() )
	end
end

function clientReceiveBanList(list)
	dxGridListClear(guiAdminDX["bans_list"])
	for i,v in ipairs(list) do
		dxGridListAddRow(guiAdminDX["bans_list"], v.nick.." | "..v.username.." | "..v.serial.." | "..v.ip.." | "..v.admin.." | "..v.unban, v)	
	end
end
addEvent("clientReceiveBanList", true)
addEventHandler("clientReceiveBanList", getRootElement(), clientReceiveBanList)

function showAdminPanel()
	if not guiGetVisible(adminPanelWindow) then
		dxSetEnabled(guiAdminDX["player_level"], false)
		dxSetEnabled(guiAdminDX["player_points"], false)
		dxSetEnabled(guiAdminDX["player_money"], false)
		dxSetEnabled(guiAdminDX["player_rights"], false)
		dxSetEnabled(guiAdminDX["player_memes"], false)
		dxSetEnabled(guiAdminDX["player_donator"], false)
		dxSetEnabled(guiAdminDX["player_achievement"], false)
		dxSetEnabled(guiAdminDX["player_mute"], false)
		dxSetEnabled(guiAdminDX["player_kick"], false)
		dxSetEnabled(guiAdminDX["player_ban"], false)
		dxSetEnabled(guiAdminDX["player_blow"], false)
		dxSetEnabled(guiAdminDX["maps_set"], false)
		dxSetEnabled(guiAdminDX["maps_redo"], false)
		dxSetEnabled(guiAdminDX["maps_skip"], false)
		dxSetEnabled(guiAdminDX["maps_delete"], false)
		dxSetEnabled(guiAdminDX["maps_fix"], false)		
		dxSetEnabled(guiAdminDX["bans_delete"], false)
		dxSetEnabled(guiAdminDX["bans_ip"], false)
		dxSetEnabled(guiAdminDX["bans_serial"], false)	
		
		if getElementData(getLocalPlayer(), "Level") == "Member" then
			dxSetEnabled(guiAdminDX["player_blow"], true)
			dxSetEnabled(guiAdminDX["player_mute"], true)
			dxSetEnabled(guiAdminDX["player_kick"], true)
			dxSetEnabled(guiAdminDX["maps_delete"], true)
			dxSetEnabled(guiAdminDX["maps_fix"], true)
		elseif getElementData(getLocalPlayer(), "Level") == "SeniorMember" then
			dxSetEnabled(guiAdminDX["player_blow"], true)
			dxSetEnabled(guiAdminDX["player_mute"], true)
			dxSetEnabled(guiAdminDX["player_kick"], true)
			dxSetEnabled(guiAdminDX["player_ban"], true)
			dxSetEnabled(guiAdminDX["maps_delete"], true)
			dxSetEnabled(guiAdminDX["maps_fix"], true)
		elseif getElementData(getLocalPlayer(), "Level") == "Moderator" then
			dxSetEnabled(guiAdminDX["player_blow"], true)
			dxSetEnabled(guiAdminDX["player_mute"], true)
			dxSetEnabled(guiAdminDX["player_kick"], true)
			dxSetEnabled(guiAdminDX["player_ban"], true)
			dxSetEnabled(guiAdminDX["maps_set"], true)
			dxSetEnabled(guiAdminDX["maps_redo"], true)
			dxSetEnabled(guiAdminDX["maps_skip"], true)
			dxSetEnabled(guiAdminDX["maps_delete"], true)
			dxSetEnabled(guiAdminDX["maps_fix"], true)
			dxSetEnabled(guiAdminDX["bans_ip"], true)
			dxSetEnabled(guiAdminDX["bans_serial"], true)
		elseif getElementData(getLocalPlayer(), "Level") == "CoLeader" then
			dxSetEnabled(guiAdminDX["player_blow"], true)
			dxSetEnabled(guiAdminDX["player_mute"], true)
			dxSetEnabled(guiAdminDX["player_kick"], true)
			dxSetEnabled(guiAdminDX["player_ban"], true)
			dxSetEnabled(guiAdminDX["maps_set"], true)
			dxSetEnabled(guiAdminDX["maps_redo"], true)
			dxSetEnabled(guiAdminDX["maps_skip"], true)
			dxSetEnabled(guiAdminDX["maps_delete"], true)
			dxSetEnabled(guiAdminDX["maps_fix"], true)	
			dxSetEnabled(guiAdminDX["bans_ip"], true)
			dxSetEnabled(guiAdminDX["bans_serial"], true)
		elseif getElementData(getLocalPlayer(), "Level") == "Leader" or getElementData(getLocalPlayer(), "Level") == "Owner" then
			dxSetEnabled(guiAdminDX["player_blow"], true)
			dxSetEnabled(guiAdminDX["player_mute"], true)
			dxSetEnabled(guiAdminDX["player_kick"], true)
			dxSetEnabled(guiAdminDX["player_ban"], true)
			dxSetEnabled(guiAdminDX["player_money"], true)
			dxSetEnabled(guiAdminDX["player_memes"], true)
			--dxSetEnabled(guiAdminDX["player_donator"], true)
			dxSetEnabled(guiAdminDX["player_achievement"], true)
			dxSetEnabled(guiAdminDX["player_rights"], true)
			dxSetEnabled(guiAdminDX["player_points"], true)
			dxSetEnabled(guiAdminDX["player_level"], true)
			dxSetEnabled(guiAdminDX["maps_set"], true)
			dxSetEnabled(guiAdminDX["maps_redo"], true)
			dxSetEnabled(guiAdminDX["maps_skip"], true)
			dxSetEnabled(guiAdminDX["maps_delete"], true)
			dxSetEnabled(guiAdminDX["maps_fix"], true)	
			dxSetEnabled(guiAdminDX["bans_delete"], true)
			dxSetEnabled(guiAdminDX["bans_ip"], true)
			dxSetEnabled(guiAdminDX["bans_serial"], true)			
		else return false end

		guiSetInputMode("no_binds_when_editing")
		showCursor(true)
		refreshAdminPanel("all")
		guiSetVisible(adminPanelWindow, true)
		addEventHandler("onClientRender", getRootElement(), drawAdminPanel, false, "low")		
	end
end

function hideAdminPanel()
	if guiGetVisible(adminPanelWindow) then
		if not showUserGui then
			showCursor(false)
		end
		guiSetVisible(adminPanelWindow, false)
		removeEventHandler("onClientRender", getRootElement(), drawAdminPanel)
		
		for i,v in pairs(guiAdminDX) do
			dxSetVisible(v, false)
		end		
		for i,v in pairs(guiAdminGUI) do
			guiSetVisible(v, false)
		end
	end
end

function drawAdminPanel()
	if getPlayerGameMode(getLocalPlayer()) == 0 then hideAdminPanel() end
	
	for i,v in pairs(guiAdminDX) do
		dxSetVisible(v, false)
	end		
	for i,v in pairs(guiAdminGUI) do
		if v ~= guiAdminGUI["player_edit"] and  v ~= guiAdminGUI["maps_edit"] and  v ~= guiAdminGUI["bans_edit"] then  --Must be done this way here manually cause mta 1.5 SUCKS
			guiSetVisible(v, false)
		end
	end
		
	guiSetVisible(guiAdminGUI["adminBox"], true)
	if guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == -1 then guiComboBoxSetSelected ( guiAdminGUI["adminBox"], 0 ) end

	local x, y = guiGetPosition(adminPanelWindow, false)
	local w, h = guiGetSize(adminPanelWindow, false)
	dxDrawImageSection ( x, y, w, h, 0, 0, w, h, "files/wave/gui/window.png")
	dxDrawText ( "Adminpanel", x, y+8, x+w, y+h, tocolor(255,255,255,255), 1, "default-bold", "center")
	guiSetPosition(guiAdminGUI["adminBox"], x+w-190, y+3, false)
	if guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == 0 then
		dxDrawShadowedText("Players: ", x+10,y+40, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxSetPosition(guiAdminDX["player_list"], x+10, y+60,false)
		dxSetVisible(guiAdminDX["player_list"], true)
		dxSetPosition(guiAdminDX["player_refresh"], x+10, y+465,false)
		dxSetPosition(guiAdminDX["player_refresh2"], x+10+100, y+465,false)
		dxSetVisible(guiAdminDX["player_refresh"], true)
		dxSetVisible(guiAdminDX["player_refresh2"], true)
	
		dxSetPosition(guiAdminDX["player_rights"],  x+230,y+306,false)
		dxSetPosition(guiAdminDX["player_memes"],  x+230,y+332,false)
		dxSetPosition(guiAdminDX["player_donator"],  x+230,y+358,false)
		dxSetPosition(guiAdminDX["player_achievement"],  x+230,y+384,false)
		dxSetPosition(guiAdminDX["player_mute"],  x+230,y+410,false)
		dxSetPosition(guiAdminDX["player_ban"],  x+230,y+436,false)
		dxSetPosition(guiAdminDX["player_level"],  x+382,y+332,false)
		dxSetPosition(guiAdminDX["player_points"],  x+382,y+358,false)
		dxSetPosition(guiAdminDX["player_money"],  x+382,y+384,false)
		dxSetPosition(guiAdminDX["player_blow"],  x+382,y+410,false)
		dxSetPosition(guiAdminDX["player_kick"],  x+382,y+436,false)
		
		dxSetVisible(guiAdminDX["player_rights"], true)
		dxSetVisible(guiAdminDX["player_memes"], true)
		dxSetVisible(guiAdminDX["player_donator"], true)
		dxSetVisible(guiAdminDX["player_achievement"], true)
		dxSetVisible(guiAdminDX["player_level"], true)
		dxSetVisible(guiAdminDX["player_points"], true)
		dxSetVisible(guiAdminDX["player_money"], true)
		dxSetVisible(guiAdminDX["player_mute"], true)
		dxSetVisible(guiAdminDX["player_ban"], true)
		dxSetVisible(guiAdminDX["player_kick"], true)
		dxSetVisible(guiAdminDX["player_blow"], true)
		
		guiSetPosition(guiAdminGUI["player_edit"], x+230, y+465, false)
		guiSetVisible(guiAdminGUI["player_edit"], true)
		guiSetVisible(guiAdminGUI["maps_edit"], false)
		guiSetVisible(guiAdminGUI["bans_edit"], false)
		
		local row = dxGridListGetSelectedItem ( guiAdminDX["player_list"] )
		if row then
			local data = dxGridListGetItemData ( guiAdminDX["player_list"], row )
			if data and isElement(data) then
				if getPlayerName(data) ~= dxGridListGetItemText(guiAdminDX["player_list"] , row) then dxGridListSetItemText(row, getPlayerName(data)) end
				dxDrawShadowedText("Name: ".._getPlayerName(data), x+230,y+60, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, true, true)
				dxDrawShadowedText("Accountname: "..getElementData(data, "Userid").."_"..getElementData(data,"AccountName"), x+230,y+75, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				dxDrawShadowedText("IP: "..getElementData(data, "IP"), x+230,y+90, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				dxDrawShadowedText("Serial: "..getElementData(data, "Serial"), x+230,y+105, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				dxDrawShadowedText("Rights: "..getElementData(data, "Level"), x+230,y+120, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				dxDrawShadowedText("Gamemode: "..getPlayerGameMode(data), x+230,y+135, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				dxDrawShadowedText("State: "..getElementData(data, "state"), x+230,y+150, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				dxDrawShadowedText("Muted: "..tostring(getElementData(data, "isMuted")), x+230,y+165, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
				local veh = getPedOccupiedVehicle ( data )
				if isElement(veh) then
					dxDrawShadowedText("Vehicle: "..getVehicleName ( veh ), x+230,y+180, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
					dxDrawShadowedText("Vehicle Health: "..math.round(getElementHealth(veh)), x+230,y+195, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)	
				else
					dxDrawShadowedText("Vehicle: -", x+230,y+180, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
					dxDrawShadowedText("Vehicle Health: -", x+230,y+195, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)	
				end
				return			
			end
		end
		dxDrawShadowedText("Name: -", x+230,y+60, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("IP: -", x+230,y+75, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Serial: -", x+230,y+90, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Rights: -", x+230,y+105, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Gamemode: -", x+230,y+120, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("State: -", x+230,y+135, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Muted: -", x+230,y+150, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Vehicle: -", x+230,y+165, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Vehicle Health: -", x+230,y+180, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
	elseif guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == 1 then
		if getElementData(getLocalPlayer(), "gameMode") == 4 or getElementData(getLocalPlayer(), "gameMode")  == 6 then
				dxDrawImageSection ( x, y, w, h, 0, 0, w, h, "files/wave/gui/window.png")
				dxDrawShadowedText("'Maps' currently not available",  x, y, x+w, y+h, tocolor(255,255,255,255),tocolor(0,0,0,255), 2,"default-bold", "center", "center", false, false, false, true)
		else
			dxDrawShadowedText("Gamemode Maps: ", x+10,y+40, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
			dxSetPosition(guiAdminDX["maps_list"], x+10, y+60,false)
			dxSetVisible(guiAdminDX["maps_list"], true)
			
			dxSetPosition(guiAdminDX["maps_set"],  x+330,y+332,false)
			dxSetPosition(guiAdminDX["maps_redo"],  x+330,y+358,false)
			dxSetPosition(guiAdminDX["maps_skip"],  x+330,y+384,false)		
			dxSetPosition(guiAdminDX["maps_delete"],  x+330,y+410,false)
			dxSetPosition(guiAdminDX["maps_fix"],  x+330,y+436,false)		
			dxSetVisible(guiAdminDX["maps_set"], true)
			dxSetVisible(guiAdminDX["maps_redo"], true)
			dxSetVisible(guiAdminDX["maps_skip"], true)
			dxSetVisible(guiAdminDX["maps_delete"], true)
			dxSetVisible(guiAdminDX["maps_fix"], true)
			
			guiSetPosition(guiAdminGUI["maps_edit"],x+10,y+465,false)
			guiSetVisible(guiAdminGUI["player_edit"], false)
			guiSetVisible(guiAdminGUI["maps_edit"], true)
			guiSetVisible(guiAdminGUI["bans_edit"], false)
		end
	elseif guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == 2 then
		dxDrawShadowedText("Active Bans: ", x+10,y+40, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1,"default-bold", "left", "top", false, false, false, true)
		dxSetPosition(guiAdminDX["bans_list"], x+10, y+60,false)
		dxSetVisible(guiAdminDX["bans_list"], true)
		
		guiSetPosition(guiAdminGUI["bans_edit"], x+10, y+447,false)
		guiSetVisible(guiAdminGUI["bans_edit"], true)
		guiSetVisible(guiAdminGUI["player_edit"], false)
		guiSetVisible(guiAdminGUI["maps_edit"], false)
		guiSetVisible(guiAdminGUI["bans_edit"], true)		

		dxSetPosition(guiAdminDX["bans_serial"], x+w-210, y+445,false)
		dxSetVisible(guiAdminDX["bans_serial"], true)	
		
		dxSetPosition(guiAdminDX["bans_ip"], x+w-400, y+445,false)
		dxSetVisible(guiAdminDX["bans_ip"], true)			
		
		dxSetPosition(guiAdminDX["bans_refresh"], x+10, y+475,false)
		dxSetVisible(guiAdminDX["bans_refresh"], true)	
		
		dxSetPosition(guiAdminDX["bans_delete"], x+w-210, y+475,false)
		dxSetVisible(guiAdminDX["bans_delete"], true)				
	end
end

function toggleAdminPanel()
	if showUserGui == false and getPlayerGameMode(getLocalPlayer()) ~= 0 and guiGetVisible(adminPanelWindow) == false then
		showAdminPanel()
	else
		hideAdminPanel()
	end
end
bindKey ( "P", "down", toggleAdminPanel)

function checkIfNotClickedAdminPanel ( button, state, sx, sy, worldX, worldY, worldZ, clickedElement )
	if guiGetVisible(adminPanelWindow) == true and state == "down" then
		local x,y  = guiGetPosition(guiAdminGUI["adminBox"], false)
		local w, h = guiGetSize(guiAdminGUI["adminBox"], false)
		if sx >= x and sx <= x+w and sy >= y and sy <= y+h then guiBringToFront ( guiAdminGUI["adminBox"] ) end
		
		if guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == 0 then
			x,y  = guiGetPosition(guiAdminGUI["player_edit"], false)
			w, h = guiGetSize(guiAdminGUI["player_edit"], false)
			if sx >= x and sx <= x+w and sy >= y and sy <= y+h then guiBringToFront ( guiAdminGUI["player_edit"] ) end
		elseif guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == 1 then
			x,y  = guiGetPosition(guiAdminGUI["maps_edit"], false)
			w, h = guiGetSize(guiAdminGUI["maps_edit"], false)
			if sx >= x and sx <= x+w and sy >= y and sy <= y+h then guiBringToFront ( guiAdminGUI["maps_edit"] ) end			
		elseif guiComboBoxGetSelected ( guiAdminGUI["adminBox"] ) == 2 then
			x,y  = guiGetPosition(guiAdminGUI["bans_edit"], false)
			w, h = guiGetSize(guiAdminGUI["bans_edit"], false)
			if sx >= x and sx <= x+w and sy >= y and sy <= y+h then guiBringToFront ( guiAdminGUI["bans_edit"] ) end		
		end				
	end
end
addEventHandler ( "onClientClick", getRootElement(), checkIfNotClickedAdminPanel )

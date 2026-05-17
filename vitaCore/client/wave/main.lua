--[[
Project: vitaCore - vitaWave
File: main.lua
Author(s):	Sebihunter
]]--
guiPanelWidth = 1024
guiPanelHeight = 780

guiX = screenWidth/2-guiPanelWidth/2
guiY = screenHeight/2-guiPanelHeight/2

showUserGui = false

waveAlpha = 0
waveMenuAlpha = 1
waveSelected = 1
waveNextSelected = 1


wavePlayerList = dxCreateGridList(screenWidth/2-392,screenHeight/2-215,170,430)
dxSetVisible(wavePlayerList, false)

g_achievementgui = {}
local achievementSelected = false
g_achievementgui["list_collected"] = dxCreateGridList(screenWidth/2-342,screenHeight/2-215,250,360)
addEventHandler ( "onClientDXClick", g_achievementgui["list_collected"], function()
	achievementSelected = g_achievementgui["list_collected"]
	dxGridListSetSelectedItem(g_achievementgui["list_left"], false)
end, false )

g_achievementgui["list_left"] = dxCreateGridList(screenWidth/2+102,screenHeight/2-215,250,360)
addEventHandler ( "onClientDXClick", g_achievementgui["list_left"], function()
	achievementSelected = g_achievementgui["list_left"]
	dxGridListSetSelectedItem(g_achievementgui["list_collected"], false)
end, false )

for i,v in pairs(g_achievementgui) do
	dxSetVisible(v, false)
end

function startWave()

	gWaveMenuItems =
	{
		[1] = { text = "Stats", image = "icon-home.png", clickable = clickableAreaCreate(0,0,0,0) },
		[2] = { text = "Information", image = "icon-info.png", clickable = clickableAreaCreate(0,0,0,0)  },
		[3] = { text = "Players", image = "icon-players.png", clickable = clickableAreaCreate(0,0,0,0)  },
		[4] = { text = "Achievements", image = "icon-trophy.png", clickable = clickableAreaCreate(0,0,0,0)  },
		[5] = { text = "Shop", image = "icon-shop.png", clickable = clickableAreaCreate(0,0,0,0)  },
		[6] = { text = "Meme", image = "icon-trollface.png", clickable = clickableAreaCreate(0,0,0,0)  },
		[7] = { text = "Specials", image = "icon-donator.png", clickable = clickableAreaCreate(0,0,0,0)  },
		[8] = { text = "Settings", image = "icon-settings.png", clickable = clickableAreaCreate(0,0,0,0)  }
	}
	
	for i,v in ipairs(gWaveMenuItems) do
		setElementData(v.clickable, "id", i)
		addEventHandler("onClickableAreaClick", v.clickable, function(button, state) if button == "left" and state == "down" and waveNextSelected == waveSelected and waveMenuAlpha == 1 and getElementData(source, "id") ~= waveSelected then playSound("files/audio/wave_change.mp3") waveNextSelected = getElementData(source, "id") waveMenuAlpha = "decrease" end end)
	end
	gWaveGUI = {}
end

addEvent("startWave", true)
addEventHandler("startWave", getRootElement(), startWave)

startWave()

function showWave()
	if showUserGui ~= false then return end
	guiSetInputMode("no_binds_when_editing")
	showUserGui = true
	playSound("files/audio/wave_change.mp3")
	hideAdminPanel()
	--hideGUIComponents("nextMap", "mapdisplay", "spectators", "money", "initiate", "timeleft", "timepassed")
	showChat(false)
	fadeCamera(true)
	showCursor(true)
	waveRefreshVitaMembers()
	--guiSetText(donatorWinmsg, getElementData(getLocalPlayer(), "customWintext"))
	--guiSetText(donatorStatus, getElementData(getLocalPlayer(), "customStatus"))

	dxGridListClear(g_achievementgui["list_left"])
	dxGridListClear(g_achievementgui["list_collected"])	
	dxGridListClear(g_mapshop["map_list"])
	dxGridListClear(wavePlayerList)
	
	guiSetText(gMapSearch, "")
	if getPlayerGameMode(getLocalPlayer()) == 1 then
		dxGridListReplaceRows(g_mapshop["map_list"], gAllTheMapsSH)
	elseif getPlayerGameMode(getLocalPlayer()) == 2 then
		dxGridListReplaceRows(g_mapshop["map_list"], gAllTheMapsDD)
	elseif getPlayerGameMode(getLocalPlayer()) == 3 then
		dxGridListReplaceRows(g_mapshop["map_list"], gAllTheMapsRA)		
	elseif getPlayerGameMode(localPlayer) == GAMEMODES.DM or getPlayerGameMode(localPlayer) == GAMEMODES.TT then
		dxGridListReplaceRows(g_mapshop["map_list"], gAllTheMapsDM)
	end

	for id, player in ipairs(getGamemodePlayers(getPlayerGameMode(getLocalPlayer()))) do
		dxGridListAddRow ( wavePlayerList, getPlayerName(player), player)		
	end				

	for k, v in pairs(tArchivements) do
		if localPlayer:getData("Archivements")[tostring(k)] then
			dxGridListAddRow(g_achievementgui["list_collected"], v.name, v.des)
		else
			dxGridListAddRow(g_achievementgui["list_left"], v.name, v.des)
		end
	end
	
	addEventHandler("onClientRender", getRootElement(), renderWave, false, "low")
end
addEvent("showWave", true)
addEventHandler("showWave", getRootElement(), showWave)

function renderWave()
	gColorPickerShallBeDrawn = false

	if showUserGui == true then
		if waveAlpha <= 0.9 then
			waveAlpha = waveAlpha+0.1
		end
	elseif showUserGui == "becomingFalse" then
		if (waveAlpha - 0.1) > 0 then
			waveAlpha = waveAlpha-0.1
		else
			showUserGui = false
			waveAlpha = 0
			closePicker(1)
		end
	end
	
	if waveNextSelected == waveSelected and waveMenuAlpha < 1 then
		waveMenuAlpha = waveMenuAlpha + 0.1
		if waveMenuAlpha > 1 then waveMenuAlpha = 1 end
	end
	
	if waveNextSelected ~= waveSelected and waveMenuAlpha ~= 1 then
		if waveMenuAlpha == "decrease" then waveMenuAlpha = 1 end
		waveMenuAlpha = waveMenuAlpha - 0.1
		if waveMenuAlpha == 0 or waveMenuAlpha < 0 then waveMenuAlpha = 0 waveSelected = waveNextSelected end
	end
	
	for i, v in pairs(g_settingsgui) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)
	end	
	
	for i,v in pairs(g_customization1) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)	
	end
	
	for i,v in pairs(g_customization1g) do
		guiSetVisible(v, false)
		guiSetAlpha(v, waveAlpha*waveMenuAlpha)	
	end	

	dxSetVisible(wavePlayerList, false)
	dxSetAlpha(wavePlayerList, waveAlpha*waveMenuAlpha)
	
	for i,v in pairs(g_memegui) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)	
	end		
	
	for i,v in pairs(g_mapshop) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)
	end			
	guiSetAlpha(gMapSearch, waveAlpha*waveMenuAlpha)
	if waveSelected ~= 5 or guiComboBoxGetSelected( shopBox ) ~= 2 then --Must be done this way because MTA does not like making it invisible all the time since 1.5 :(
		guiSetVisible(gMapSearch, false)
	end
	
	for i,v in pairs(g_shopgui) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)	
	end	
	
	for i,v in pairs(g_achievementgui) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)
	end
	
	for i,v in pairs(g_donatorgui) do
		dxSetVisible(v, false)
		dxSetAlpha(v, waveAlpha*waveMenuAlpha)	
	end		
	
	--[[if waveSelected ~= 7 then --Must be done this way because MTA does not like making it invisible all the time since 1.5 :(
		guiSetVisible(donatorWinmsg, false)
		guiSetVisible(donatorStatus, false)
	end]]
	
	--guiSetAlpha(donatorWinmsg, waveAlpha*waveMenuAlpha)
	--guiSetAlpha(donatorStatus, waveAlpha*waveMenuAlpha)
	
	guiSetVisible(settingsBox, false)
	guiSetAlpha(settingsBox, waveAlpha*waveMenuAlpha)
	
	guiSetVisible(helpBox, false)
	guiSetAlpha(helpBox, waveAlpha*waveMenuAlpha)
	
	
	guiSetVisible(shopBox, false)
	guiSetAlpha(shopBox, waveAlpha*waveMenuAlpha)
	
	if showUserGui == false then removeEventHandler("onClientRender", getRootElement(), renderWave) return end
	if getPlayerGameMode(getLocalPlayer()) == 0 or minigamesVoteShown == true or gIsLobbyShownMO == true then showUserGui = "becomingFalse" end

	dxDrawImageSection ( 0,0, screenWidth, screenHeight, 0, 0, screenWidth, screenHeight, "files/wave/bg1.png",  0,0, 0, tocolor(255,255,255,175*waveAlpha), false )
	dxDrawImage(-30,-30,256,256, "files/vitaonline_symbol.png",0,0,0, tocolor(255,255,255,255*waveAlpha))
	
	
	if waveSelected == 1 then
		dxDrawShadowedText(_getPlayerName(getLocalPlayer()),200,10, screenWidth, 50, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,ms_bold, "left", "top", false, false, false, true)
	else
		dxDrawShadowedText(gWaveMenuItems[waveSelected].text,200,10, screenWidth, 50, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,ms_bold, "left", "top", false, false, false, true)
	end
	
	if waveSelected == 1 then
	
		local percent = (getElementData(getLocalPlayer(), "Points")-getElementData(getLocalPlayer(), "lastScore"))/(getElementData(getLocalPlayer(), "neededScore")-getElementData(getLocalPlayer(), "lastScore"))
		local height = 500*percent
		dxDrawImage(screenWidth/2+212, screenHeight/2-240,80,500, "./files/b.png",0,0,0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha))		
		dxDrawShadowedText("Next level",screenWidth/2+202,screenHeight/2+270, screenWidth/2+302, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "center", "top", false, false, false, true)	
		dxDrawImage(screenWidth/2+212, screenHeight/2+260-height,80,height, "./files/g.png",0,0,0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha))	
		dxDrawShadowedText(tostring(getElementData(getLocalPlayer(), "Points")-getElementData(getLocalPlayer(), "lastScore")).."/"..tostring(getElementData(getLocalPlayer(), "neededScore")-getElementData(getLocalPlayer(), "lastScore")),screenWidth/2+212,screenHeight/2-240, screenWidth/2+292, screenHeight/2+260, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 0.9,"default-bold", "center", "center", false, false, false, true)
	
		local collected = dxGridListGetRowCount(g_achievementgui["list_collected"])
		local allachievements = collected + dxGridListGetRowCount(g_achievementgui["list_left"])
		percent = collected/allachievements
		height = 500*percent
		dxDrawImage(screenWidth/2+312, screenHeight/2-240,80,500, "./files/b.png",0,0,0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha))
		dxDrawShadowedText("Achievements",screenWidth/2+302,screenHeight/2+270, screenWidth/2+402, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "center", "top", false, false, false, true)			
		dxDrawImage(screenWidth/2+312, screenHeight/2+260-height,80,height, "./files/r.png",0,0,0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha))
		dxDrawShadowedText(tostring(collected).."/"..tostring(allachievements),screenWidth/2+312,screenHeight/2-240, screenWidth/2+392, screenHeight/2+260, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 0.9,"default-bold", "center", "center", false, false, false, true)
		
		dxDrawShadowedText("General",screenWidth/2-392,screenHeight/2-240, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Played maps: "..tostring(getElementData(getLocalPlayer(), "PlayedMaps")),screenWidth/2-392,screenHeight/2-220, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Won maps: "..tostring(getElementData(getLocalPlayer(), "WonMaps")),screenWidth/2-392,screenHeight/2-205, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Longest winning streak: "..tostring(getElementData(getLocalPlayer(), "WinningStreak")),screenWidth/2-392,screenHeight/2-190, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Kilometers driven: "..tostring(math.floor(getElementData(getLocalPlayer(), "KM"))).." km",screenWidth/2-392,screenHeight/2-175, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)		
		dxDrawShadowedText("Playing time: "..tostring(math.floor(getElementData(getLocalPlayer(), "TimeOnServer")/60)).." minutes",screenWidth/2-392,screenHeight/2-160, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)		
		
		dxDrawShadowedText("Deathmatch",screenWidth/2-392,screenHeight/2-130, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)		
		dxDrawShadowedText("Played DM maps: "..tostring(getElementData(getLocalPlayer(), "DMMaps")),screenWidth/2-392,screenHeight/2-110, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("Won DM maps: "..tostring(getElementData(getLocalPlayer(), "DMWon")),screenWidth/2-392,screenHeight/2-95, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("Top 12 huntertoptimes: ".. tostring(getElementData(getLocalPlayer(), "TopTimes")),screenWidth/2-392,screenHeight/2-80, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
	
		dxDrawShadowedText("Destruction Derby",screenWidth/2-392,screenHeight/2-60, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)		
		dxDrawShadowedText("Played DD maps: "..tostring(getElementData(getLocalPlayer(), "DDMaps")),screenWidth/2-392,screenHeight/2-40, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("Won DD maps: "..tostring(getElementData(getLocalPlayer(), "DDWon")),screenWidth/2-392,screenHeight/2-25, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("DD kills: "..tostring(getElementData(getLocalPlayer(), "ddkills")),screenWidth/2-392,screenHeight/2-10, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		
		dxDrawShadowedText("Shooter",screenWidth/2-392,screenHeight/2+10, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)		
		dxDrawShadowedText("Played SHOOTER maps: "..tostring(getElementData(getLocalPlayer(), "SHMaps")),screenWidth/2-392,screenHeight/2+30,screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("Won SHOOTER maps: "..tostring(getElementData(getLocalPlayer(), "SHWon")),screenWidth/2-392,screenHeight/2+45, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("SHOOTER kills: "..tostring(getElementData(getLocalPlayer(), "shooterkills")),screenWidth/2-392,screenHeight/2+60, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)		
	
		dxDrawShadowedText("Race",screenWidth/2-392,screenHeight/2+80, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)		
		dxDrawShadowedText("Played RACE maps: "..tostring(getElementData(getLocalPlayer(), "RAMaps")),screenWidth/2-392,screenHeight/2+100,screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("Won RACE maps: "..tostring(getElementData(getLocalPlayer(), "RAWon")),screenWidth/2-392,screenHeight/2+115, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)			
		dxDrawShadowedText("Top 12 toptimes: ".. tostring(getElementData(getLocalPlayer(), "TopTimesRA")),screenWidth/2-392,screenHeight/2+130, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)		
	elseif waveSelected == 2 then
		waveDrawHelp()
	elseif waveSelected == 3 then
		local wavePlayerInformation = {}
		
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then 
			if getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "gameMode") ~= 0 then
				wavePlayerInformation.gm = tostring(gRaceModes[getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "gameMode")].name)
			else
				wavePlayerInformation.gm = "-"
			end
		else
			wavePlayerInformation.gm = "-"
		end
			
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.money = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "Money")) else wavePlayerInformation.money = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.points = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "Points")) else wavePlayerInformation.points = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.level = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "Rank")) else wavePlayerInformation.level = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.played = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "PlayedMaps")) else wavePlayerInformation.played = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.won = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "WonMaps")) else wavePlayerInformation.won = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.longest = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "WinningStreak")) else wavePlayerInformation.longest = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.km = tostring(math.floor(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "KM"))).." km" else wavePlayerInformation.km = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.time = tostring(math.floor(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "TimeOnServer")/60)).." minutes" else wavePlayerInformation.time = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.dmplayed = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "DMMaps")) else wavePlayerInformation.dmplayed = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.dmwon = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "DMWon")) else wavePlayerInformation.dmwon = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.dmtt = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "TopTimes")) else wavePlayerInformation.dmtt = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.ddplayed = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "DDMaps")) else wavePlayerInformation.ddplayed = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.ddwon = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "DDWon")) else wavePlayerInformation.ddwon = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.shplayed = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "SHMaps")) else wavePlayerInformation.shplayed = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.shwon = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "SHWon")) else wavePlayerInformation.shwon = "-" end	
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.raplayed = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "RAMaps")) else wavePlayerInformation.raplayed = "-" end
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.rawon = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "RAWon")) else wavePlayerInformation.rawon = "-" end	
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.ratt = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "TopTimesRA")) else wavePlayerInformation.ratt = "-" end		
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.shkills = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "shooterkills")) else wavePlayerInformation.shkills = "-" end	
		if isElement(dxGridListGetItemData (wavePlayerList,  dxGridListGetSelectedItem (  wavePlayerList ))) then wavePlayerInformation.ddkills = tostring(getElementData(dxGridListGetItemData (wavePlayerList, dxGridListGetSelectedItem ( wavePlayerList )), "ddkills")) else wavePlayerInformation.ddkills = "-" end			
		dxDrawShadowedText("Online Players",screenWidth/2-392,screenHeight/2-240, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("General Information",screenWidth/2-207,screenHeight/2-240, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Current Gamemode: "..wavePlayerInformation.gm,screenWidth/2-207,screenHeight/2-220, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Money: "..wavePlayerInformation.money,screenWidth/2-207,screenHeight/2-205, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Points: "..wavePlayerInformation.points,screenWidth/2-207,screenHeight/2-190, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Level: "..wavePlayerInformation.level,screenWidth/2-207,screenHeight/2-175, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Played maps: "..wavePlayerInformation.played,screenWidth/2-207,screenHeight/2-160, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Won maps: "..wavePlayerInformation.won,screenWidth/2-207,screenHeight/2-145, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Longest winning streak: "..wavePlayerInformation.longest,screenWidth/2-207,screenHeight/2-130, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Kilometers driven: "..wavePlayerInformation.km,screenWidth/2-207,screenHeight/2-115, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Playing time: "..wavePlayerInformation.time,screenWidth/2-207,screenHeight/2-100, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		
		dxDrawShadowedText("Deathmatch",screenWidth/2-207,screenHeight/2-80, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Played DM maps: "..wavePlayerInformation.dmplayed,screenWidth/2-207,screenHeight/2-60, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Won DM maps: "..wavePlayerInformation.dmwon,screenWidth/2-207,screenHeight/2-45, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Top 12 huntertoptimes: "..wavePlayerInformation.dmtt,screenWidth/2-207,screenHeight/2-30, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		
		dxDrawShadowedText("Destruction Derby",screenWidth/2-207,screenHeight/2-10, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Played DD maps: "..wavePlayerInformation.ddplayed,screenWidth/2-207,screenHeight/2+10, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Won DD maps: "..wavePlayerInformation.ddwon,screenWidth/2-207,screenHeight/2+25, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("DD kills: "..wavePlayerInformation.ddkills,screenWidth/2-207,screenHeight/2+40, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		
		dxDrawShadowedText("Shooter",screenWidth/2-207,screenHeight/2+60, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Played SHOOTER maps: "..wavePlayerInformation.shplayed,screenWidth/2-207,screenHeight/2+80, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Won SHOOTER maps: "..wavePlayerInformation.shwon,screenWidth/2-207,screenHeight/2+95, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		dxDrawShadowedText("SHOOTER kills: "..wavePlayerInformation.shkills,screenWidth/2-207,screenHeight/2+110, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)		
		
		dxDrawShadowedText("Race",screenWidth/2-207,screenHeight/2+130, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Played RACE maps: "..wavePlayerInformation.raplayed,screenWidth/2-207,screenHeight/2+150, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
		dxDrawShadowedText("Won RACE maps: "..wavePlayerInformation.rawon,screenWidth/2-207,screenHeight/2+165, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)		
		dxDrawShadowedText("Top 12 toptimes: "..wavePlayerInformation.ratt,screenWidth/2-207,screenHeight/2+180, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)
	
		dxSetVisible(wavePlayerList, true)
	elseif waveSelected == 4 then
		dxDrawShadowedText("Collected Achievements",screenWidth/2-342,screenHeight/2-240, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		dxDrawShadowedText("Left Achievements",screenWidth/2+102,screenHeight/2-240, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)	
		
		dxDrawShadowedText("Description",screenWidth/2-342,screenHeight/2+170, screenWidth, screenHeight, tocolor(214,219,145,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1, ms_bold_12 , "left", "top", false, false, false, true)
		
		if achievementSelected and isElement(achievementSelected) and dxGridListGetSelectedItem(achievementSelected) then
			dxDrawShadowedText(tostring(dxGridListGetItemData(achievementSelected, dxGridListGetSelectedItem(achievementSelected))),screenWidth/2-342,screenHeight/2+190, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		else
			dxDrawShadowedText("none",screenWidth/2-342,screenHeight/2+190, screenWidth, screenHeight, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,"default-bold", "left", "top", false, false, false, true)	
		end
		
		for i,v in pairs(g_achievementgui) do
			dxSetVisible(v, true)
		end			
	elseif waveSelected == 5 then
		waveDrawShop()
	elseif waveSelected == 6 then
		waveDrawMeme()
	elseif waveSelected == 7 then
		waveDrawDonator()
	elseif waveSelected == 8 then
		waveDrawSettings()
	else
		dxDrawShadowedText("Work in Progress",0,screenHeight/2-25, screenWidth, 50, tocolor(200,0,0,255*waveAlpha*waveMenuAlpha),tocolor(0,0,0,255*waveAlpha*waveMenuAlpha), 1,ms_bold, "center", "top", false, false, false, false)
	end
	
	
	--Reactivate this to check if the menu is correctly displayed
	--dxDrawRectangle(screenWidth/2-1024/2, screenHeight/2-780/2, 1024, 780, tocolor(50,50,50,200))
	
	for i,v in ipairs(gWaveMenuItems) do
		clickableAreaSetPosition(v.clickable,screenWidth/2-74-#gWaveMenuItems/2*74+74*i,screenHeight-74)
		clickableAreaSetSize(v.clickable, 74,64)	
		if i == waveSelected then
			if clickableAreaIsHovering(v.clickable) then
				dxDrawImage(screenWidth/2-74-74*#gWaveMenuItems/2+74*i,screenHeight-74,64,64, "files/wave/"..v.image,0,0,0, tocolor(255,255,255,(255-80+80*waveMenuAlpha)*waveAlpha))
			else
				dxDrawImage(screenWidth/2-74-74*#gWaveMenuItems/2+74*i,screenHeight-74,64,64, "files/wave/"..v.image,0,0,0, tocolor(255,255,255,(255-150+150*waveMenuAlpha)*waveAlpha))
			end
		else
			if clickableAreaIsHovering(v.clickable) then
				dxDrawImage(screenWidth/2-74-74*#gWaveMenuItems/2+74*i,screenHeight-74,64,64, "files/wave/"..v.image,0,0,0, tocolor(255,255,255,(255-80*waveAlpha)*waveAlpha))
			else
				dxDrawImage(screenWidth/2-74-74*#gWaveMenuItems/2+74*i,screenHeight-74,64,64, "files/wave/"..v.image,0,0,0, tocolor(255,255,255,(255-150)*waveAlpha))
			end
		end
	end
	
	if gColorPickerShallBeDrawn == false then
		closePicker(1)
	end
end

function hideWave()
	if showUserGui ~= true then return end
	showUserGui = "becomingFalse"
	showChat(true)
	showCursor(false)
	playSound("files/audio/wave_change.mp3")
	
	--[[if tostring(guiGetText(donatorWinmsg)) ~= "Ohai Thar" then
		setElementData(getLocalPlayer(), "customWintext", tostring(guiGetText(donatorWinmsg)))
		updateSettings("customWintext", tostring(guiGetText(donatorWinmsg)))
	end	]]
	
	--[[if tostring(guiGetText(donatorStatus)) ~= "Ohai Thar" then
		if string.len(removeColorCoding(guiGetText(donatorStatus))) <= 15 then
			setElementData(getLocalPlayer(), "customStatus", tostring(guiGetText(donatorStatus)))
			updateSettings("customStatus", tostring(guiGetText(donatorStatus)))
		end
	end		]]
	--if getPlayerGameMode(getLocalPlayer()) ~= 0 then
		--showGUIComponents("nextMap", "mapdisplay", "spectators", "money", "timeleft", "timepassed")
	--end
end
addEvent("hideWave", true)
addEventHandler("hideWave", getRootElement(), hideWave)

function toggleWave()
	if showUserGui == false and getPlayerGameMode(getLocalPlayer()) ~= 0 and minigamesVoteShown == false and gIsLobbyShownMO == false then
		showWave()
	else
		hideWave()
	end
end
bindKey ( "U", "down", toggleWave)

function toggleWaveHelp()
	if showUserGui == false and getPlayerGameMode(getLocalPlayer()) ~= 0 and minigamesVoteShown == false then
		waveNextSelected = 2
		waveSelected = 2
		guiComboBoxSetSelected ( helpBox, 1 )
		showWave()
	elseif showUserGui == true then
		if waveSelected ~= 2 then
			waveMenuAlpha = "decrease"
			waveNextSelected = 2
			guiComboBoxSetSelected ( helpBox, 1 )
		else
			hideWave()
		end
	end
end
bindKey ( "F9", "down", toggleWaveHelp)
--bindKey ( "F1", "down", toggleWaveHelp)


function waveChangeMenu(key, keyState, i)
	if showUserGui ~= true or waveNextSelected ~= waveSelected or waveMenuAlpha ~= 1 then return end
	playSound("files/audio/wave_change.mp3")
	waveMenuAlpha = "decrease"
	if waveSelected + i < 1 then
		waveNextSelected = #gWaveMenuItems
		return
	elseif waveSelected + i > #gWaveMenuItems then
		waveNextSelected = 1
		return
	else
		waveNextSelected = waveSelected + i
	end
end
bindKey("arrow_l", "down", waveChangeMenu, -1)
bindKey("arrow_r", "down", waveChangeMenu, 1)

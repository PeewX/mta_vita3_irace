--[[
Project: vitaCore
File: dd-main.lua
Author(s):	Sebihunter
]]--

local databaseMapSH = false
local timesPlayed = 0

gGamemodeSH = 1
gElementSH = createElement("elementSH")
gIsSHRunning = false
gHasEndedSH = false
gSHMapTimer = false
gMetaSH = false
gRedoCounterSH = 0
countdownTimerSH = false
gRatingsSH = {}
gMapFilesSH = {}
gMapMusicSH = false

gMapResourceNameSH = "none"


gSpawnPositionsSH = {}
gRankingboardPlayersSH = {}
gShooterWaitTimer = false
setElementData(gElementSH, "rankingboard", gRankingboardPlayersSH)

gTextdisplaySH = textCreateDisplay()
gTextdisplayTextSH = textCreateTextItem ( "Testthingy", 0.5, 0.8, "low", 255, 255, 255, 255, 2.0, "center", "top", 255 )
textDisplayAddText ( gTextdisplaySH, gTextdisplayTextSH )

function startTimerSH()
	if gIsSHRunning ~= false then return end
	local maxPlayers = #getGamemodePlayers(gGamemodeSH)
	local readyPlayers = 0
	for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
		if getElementData(v, "state") == "ready" then
			readyPlayers = readyPlayers + 1
		end
	end
	
	if isTimer(gStartTimerSH) then
		local ttime, left, will = getTimerDetails ( gStartTimerSH )
		if left == 3 then
			textItemSetText(gTextdisplayTextSH, "waiting for players...")
			for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
				textDisplayAddObserver(gTextdisplaySH, v)
			end
		elseif left == 1 then
			countdownFuncSH(4)
			killTimer(gStartTimerSH)
			gStartTimerSH = false

			for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
				textDisplayRemoveObserver(gTextdisplaySH, v)
			end

			return
		end
	end
	
	if readyPlayers/maxPlayers > 0.8 then
		if isTimer(gStartTimerSH) then killTimer(gStartTimerSH) end
		countdownFuncSH(4)
		gStartTimerSH = false
		for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
			textDisplayRemoveObserver(gTextdisplaySH, v)
		end			
	end
end
gStartTimerSH = false

function loadMapSH(mapname, force)
	if not force then force = false end
	if isMapRunningSH() or gIsSHRunning == true then unloadMapSH() end
	if #getGamemodePlayers(gGamemodeSH) == 0 and force == false then return unloadMapSH() end	
	
	if mapname == "random" then 
		mapname = getRandomMap(gGamemodeSH)
		if mapname == "failed" then
			loadMapSH("random")
			return false
		end
	end
	outputServerLog("loadMapSH: "..tostring(mapname))
	
	if gRedoCounterSH - 1 > 0 then
		gRedoCounterSH = gRedoCounterSH - 1
	else
		gRedoCounterSH = 0
	end
	
	gMapMusicSH = false
	gHasEndedSH = false
	
	if betReadySH and isTimer(betReadySH) then killTimer(betReadySH) end
	if gShooterWaitTimer and isTimer(gShooterWaitTimer) then killTimer(gShooterWaitTimer) end
	
	gSpawnPositionsSH = {}
	setElementData(gElementSH, "betAvailable", true)
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if getElementData(pvpElement, "gameMode") == gGamemodeSH then
			destroyElement(pvpElement)
		end
	end	
		
	local resource = getResourceFromName ( mapname )
	
	--stopResource(getResourceFromName ( "vitaMapSH" ))
	--deleteResource ( "vitaMapSH")
	--refreshResources ( false )
	
	if not getResourceFromName ( "vitaMapSH" ) then
		createResource ( "vitaMapSH" )
	end
	
	for i,v in ipairs(gMapFilesSH) do
		fileDelete ( ":vitaMapSH/"..tostring(v) )
	end
	gMapFilesSH = {}
	
	fileDelete ( ":vitaMapSH/meta.xml" )
	local mapXML = xmlCreateFile ( ":vitaMapSH/meta.xml" ,"meta" )                                   
	local mapNode = xmlCreateChild(mapXML, "info")
	xmlNodeSetAttribute(mapNode, "description", "Vita Maploader")
	xmlNodeSetAttribute(mapNode, "type", "script")
	
	--mapNode = xmlCreateChild(mapXML, "file")
	--xmlNodeSetAttribute(mapNode, "src", "meta2.xml")
	
	mapNode = xmlCreateChild(mapXML, "script")
	xmlNodeSetAttribute(mapNode, "src", "vitaMap.lua")
	xmlNodeSetAttribute(mapNode, "type", "client")	
	fileCopy ( "files/mapLoading/vitaMapSH.lua", ":vitaMapSH/vitaMap.lua", true )
	
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)
		
	mapXML = xmlCreateFile ( ":vitaMapSH/meta2.xml" ,"meta" )
	table.insert(gMapFilesSH, "meta2.xml")

	local metaXML = xmlLoadFile ( ":"..mapname.."/meta.xml" )
	if metaXML then
		local i = 0
		while true do 
			local xmlNode = xmlFindChild ( metaXML, "map", i)
			if not xmlNode then
				break
			else
				local copyFile = xmlNodeGetAttribute(xmlNode, "src")
				fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapSH/"..copyFile, true )
				table.insert(gMapFilesSH, copyFile)
				mapNode = xmlCreateChild(mapXML, "file")
				xmlNodeSetAttribute(mapNode, "src", copyFile)
				xmlNodeSetAttribute(mapNode, "download", "false")	

				local mapfile = xmlLoadFile ( ":"..mapname.."/"..copyFile )
				if mapfile then
					local i2 = 0
					while true do
						local mapfilenode = xmlFindChild ( mapfile, "spawnpoint", i2)
						if not mapfilenode then
							break
						else
							local modelID = tonumber(xmlNodeGetAttribute(mapfilenode, "vehicle"))
							local interiorID = tonumber(xmlNodeGetAttribute(mapfilenode, "interior"))
							local posX = tonumber(xmlNodeGetAttribute(mapfilenode, "posX"))
							local posY = tonumber(xmlNodeGetAttribute(mapfilenode, "posY"))
							local posZ = tonumber(xmlNodeGetAttribute(mapfilenode, "posZ"))
							local rotX = tonumber(xmlNodeGetAttribute(mapfilenode, "rotX"))
							local rotY = tonumber(xmlNodeGetAttribute(mapfilenode, "rotY"))
							local rotZ = tonumber(xmlNodeGetAttribute(mapfilenode, "rotZ"))
							
							if not rotX then rotX = 0 end
							if not rotY then rotY = 0 end
							if not rotZ then rotZ = tonumber(xmlNodeGetAttribute(mapfilenode, "rotation")) end
							
							local spawnID = #gSpawnPositionsSH+1
							gSpawnPositionsSH[spawnID] = {}
							gSpawnPositionsSH[spawnID].posX = posX
							gSpawnPositionsSH[spawnID].posY = posY
							gSpawnPositionsSH[spawnID].posZ = posZ
							gSpawnPositionsSH[spawnID].rotX = rotX
							gSpawnPositionsSH[spawnID].rotY = rotY
							gSpawnPositionsSH[spawnID].rotZ = rotZ
							gSpawnPositionsSH[spawnID].interior = interiorID
							gSpawnPositionsSH[spawnID].vehicle = modelID
							gSpawnPositionsSH[spawnID].used = false
						end
						i2 = i2+1
					end
					xmlUnloadFile(mapfile)
				end				
				i = i + 1
				
			end
		end
		
		if #gSpawnPositionsSH == 0 or #gSpawnPositionsSH == false then
			return loadMapSH("random")
		end		
		
		local temporaryTable = {}
		i = 0
		while true do 
			local xmlNode = xmlFindChild ( metaXML, "script", i)
			if not xmlNode then
				break
			else
				local copyFile = xmlNodeGetAttribute(xmlNode, "src")
				
				--Check if the file has been already added to the meta.xml - Some mappers are so stupid to add scripts 2 times which can fail ;)
				local metaLineExists = false
				for i,v in ipairs(temporaryTable) do if v == copyFile then metaLineExists = true end end
				
				if metaLineExists == false and xmlNodeGetAttribute(xmlNode, "type") == "client" then		
					fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapSH/"..copyFile, true )
					table.insert(gMapFilesSH, copyFile)
					mapNode = xmlCreateChild(mapXML, "file")
					xmlNodeSetAttribute(mapNode, "src", copyFile)
					xmlNodeSetAttribute(mapNode, "type", "client")
					xmlNodeSetAttribute(mapNode, "download", "false")	
					temporaryTable[#temporaryTable+1] = copyFile
				end
				i = i + 1
			end
		end		
		
		temporaryTable = {}
		i = 0
		while true do 
			local xmlNode = xmlFindChild ( metaXML, "file", i)
			if not xmlNode then
				break
			else
				local copyFile = xmlNodeGetAttribute(xmlNode, "src")
				
				--Check if the file has been already added to the meta.xml - Some mappers are so stupid to add scripts 2 times which can fail ;)
				local metaLineExists = false
				for i,v in ipairs(temporaryTable) do if v == copyFile then metaLineExists = true end end
				
				if metaLineExists == false then		
					if ( string.find(copyFile, ".mp3" ) ) then
						gMapMusicSH = true	
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaStream/sh.mp3", true )
					else
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapSH/"..copyFile, true )
						table.insert(gMapFilesSH, copyFile)
						mapNode = xmlCreateChild(mapXML, "file")
						xmlNodeSetAttribute(mapNode, "src", copyFile)
						xmlNodeSetAttribute(mapNode, "download", "false")	
						temporaryTable[#temporaryTable+1] = copyFile
					end
				end
				i = i + 1
			end
		end

		local xmlSettings = xmlFindChild ( metaXML, "settings", 0)
		local xmlChild = xmlCreateChild(mapXML, "settings")
		
		i = 0
		while true do 		
			local xmlNode = xmlFindChild ( xmlSettings, "setting", i)
			if not xmlNode then
				break
			else
				mapNode = xmlCreateChild(xmlChild, "setting")
				xmlNodeSetAttribute(mapNode, "name", xmlNodeGetAttribute(xmlNode, "name"))
				xmlNodeSetAttribute(mapNode, "value", xmlNodeGetAttribute(xmlNode, "value"))		
				i = i + 1
			end
		end
		
		local xmlInfo= xmlFindChild ( metaXML, "info", 0)
		if xmlInfo then 
			local realMapname = xmlNodeGetAttribute(xmlInfo, "name")
			if realMapname then
				setElementData(gElementSH, "mapname", realMapname)
			else
				setElementData(gElementSH, "mapname", mapname)
			end
		else
			setElementData(gElementSH, "mapname", mapname)
		end
	end
	
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)

	local hFile = fileOpen(":vitaMapSH/meta2.xml")
	local buffer = ""
	if hFile then
		while not fileIsEOF(hFile) do
			buffer = buffer .."".. fileRead(hFile, 500)
		end
	end
	fileClose(hFile)
	gMetaSH = buffer

	databaseMapSH = DatabaseMap:new(mapname)
	timesPlayed = databaseMapSH.m_Timesplayed
	gRatingsSH = databaseMapSH.m_Ratings

	setElementData(gElementSH, "map", mapname)
	if mapname == getElementData(gElementSH, "nextmap") then
		setElementData(gElementSH, "nextmap", "random")
	end
	
	local duration = 10*60*1000
	setElementData(gElementSH, "duration", duration)
	
	--refreshResources ( false )
	startResource(getResourceFromName("vitaMapSH"))
	
	if gStartTimerSH == false or isTimer(gStartTimerSH) == false then
		gStartTimerSH = setTimer(startTimerSH, 5000, 6) -- 6 times = 30 seconds
	end
	
	gMapResourceNameSH = mapname
	
	setTimer(function()
	for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
		setUpSHPlayer(v)
	end end, 500,1)
end

function unloadMapSH()
	if isTimer(gStartTimerSH) then
		killTimer(gStartTimerSH)
		gStartTimerSH = false
	end
	if gShooterWaitTimer and isTimer(gShooterWaitTimer) then killTimer(gShooterWaitTimer) end

	if databaseMapSH then
		databaseMapSH.m_Ratings = gRatingsSH
		databaseMapSH.m_Timesplayed = databaseMapSH.m_Timesplayed + 1
		databaseMapSH:delete()
		databaseMapSH = false
	end
	
	gIsSHRunning = false
	--stopResource(getResourceFromName("vitaMapSH"))
	setElementData(gElementSH, "map", "none")
	setElementData(gElementSH, "mapname", "loading...")
	setElementData(gElementSH, "startTick", nil)
	gRankingboardPlayersSH = {}
	setElementData(gElementSH, "rankingboard", gRankingboardPlayersSH)
	
	if countdownTimerSH then
		if isTimer(countdownTimerSH) then
			killTimer(countdownTimerSH)
		end	
	end
	
	if gSHMapTimer then
		if isTimer(gSHMapTimer) then
			killTimer(gSHMapTimer)
		end
	end
	
	for i,v in pairs(getElementsByType("vehicle")) do 
		if getElementData(v, "isSHVeh") == true then
			if isElement(v) then
				destroyElement(v)
			end
		end
	end
	
	for i,player in pairs(getGamemodePlayers(gGamemodeSH)) do
		setElementData(player, "state", "dead")
		callClientFunction(player, "hideHurry")
		setElementData(player, "vitaShootingAllowed", false)
		setElementData(player, "vitaJumpingAllowed", false)		
		triggerClientEvent ( player, "stopMapSH", getRootElement() )		
		triggerClientEvent ( player, "onMapSoundStop", player )
	end
end

function isMapRunningSH()
	if getElementData(gElementSH, "map") ~= "none" then return true end
	return false
end

function joinSH(player)
	--DISABLING MODE
	--if player then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is deactivated.") return false end
	
	if getPlayerGameMode(player) == gGamemodeSH then return false end
	if #getGamemodePlayers(gGamemodeSH) >= gRaceModes[gGamemodeSH].maxplayers then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is currently full.") return false end
	
	local loadsNewMap = false
	if #getGamemodePlayers(gGamemodeSH) == 0 then
		loadsNewMap = true
		setElementData(gElementSH, "map", "none")
		setElementData(gElementSH, "mapname", "loading...")
		setElementData(gElementSH, "nextmap", "random")
		loadMapSH(getElementData(gElementSH, "nextmap"), true)
	elseif #getGamemodePlayers(gGamemodeSH) == 1 and  gIsSHRunning == true and gHasEndedSH == false then
		endMapSH()
	end
	setElementData(player, "gameMode", gGamemodeSH)
	setElementData(player, "mapname", getElementData(gElementSH, "mapname"))
	setElementData(player, "nextmap", getElementData(gElementSH, "nextmap"))
	setElementData(player, "winningCounter", 0)
	setElementData(player, "vitaShootingAllowed", false)
	setElementData(player, "vitaJumpingAllowed", false)
	setElementData(player, "AFK", false)
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeSH)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, true )
			setElementVisibleTo ( gPlayerBlips[v], player, true )
		end
	end	
	
	setElementDimension(player, gGamemodeSH)
	triggerClientEvent ( player, "addNotification", getRootElement(), 2, 15,150,190, "You joined 'Shooter'." )
	triggerClientEvent ( player, "hideSelection", getRootElement() )
	outputChatBoxToGamemode ( "#CCFF66:JOIN: #FFFFFF"..getPlayerName(player).."#FFFFFF has joined the gamemode.", gGamemodeSH, 255, 255, 255, true )
	
	callClientFunction(player, "showGUIComponents", "nextMap", "mapdisplay", "money")
	
	setElementData(player, "state", "joined")
	toggleControl ( player, "enter_exit", false )
	
	if loadsNewMap == false then
		setUpSHPlayer(player)
	end
	
	bindKey(player, "F", "down", playerKillFuncSH)
	bindKey(player, "enter", "down", playerKillFuncSH)
	
	if gIsSHRunning == true then
		playerWaitRoundSH(player)
	end
end
addEvent("joinSH", true)
addEventHandler("joinSH", getRootElement(), joinSH)

function quitSH(player)
	if getPlayerGameMode(player) ~= gGamemodeSH then return false end
	killSHPlayer(player, true)

	if textDisplayIsObserver(gTextdisplaySH, player) then
		textDisplayRemoveObserver(gTextdisplaySH, player)
	end	
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeSH)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, false )
			setElementVisibleTo ( gPlayerBlips[v], player, false )
		end
	end	
	
	if bettedPlayer[player] then bettedPlayer[player] = false end
	setElementData(player, "winline", nil)
	setElementData(player, "winline2", nil)
	setElementData(player, "winr", nil)
	setElementData(player, "wing", nil)
	setElementData(player, "winb", nil)
	setElementData(player, "vitaShootingAllowed", false)
	setElementData(player, "vitaJumpingAllowed", false)			
	
	
	setElementData(player, "gameMode", 0)
	spawnPlayer(player, 0,0,0)
	setElementDimension(player, 0)
	setElementInterior(player, 0)
	setElementFrozen(player, true)
	outputChatBoxToGamemode ( "#FF6666:QUIT: #FFFFFF"..getPlayerName(player).."#FFFFFF has left the gamemode.", gGamemodeSH, 255, 255, 255, true )
	
	triggerClientEvent ( player, "stopMapSH", getRootElement() )
	triggerClientEvent ( player, "onMapSoundStop", getRootElement() )
	
	if #getGamemodePlayers(gGamemodeSH) == 1 then
		for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
			triggerClientEvent(v, "foreveraloneClient",getRootElement())
			addPlayerArchivement(v, 64)
		end
	end	
	
	if #getGamemodePlayers(gGamemodeSH) == 0 then
		unloadMapSH()
	end
end
addEvent("quitSH", true)
addEventHandler("quitSH", getRootElement(), quitSH)

function downloadMapFinishedSH(player)
	local mapRating = {likes = 0, dislikes = 0}
	for _, PlayerRate in pairs(gRatingsSH) do
		mapRating.likes = mapRating.likes + PlayerRate.Rating
	end
	mapRating.dislikes = #gRatingsSH - mapRating.likes

	callClientFunction(player, "forceMapRating", getElementData(gElementSH, "mapname"), mapRating, timesPlayed)
	callClientFunction(player, "allowNewHurryFunc")
	callClientFunction(player, "showGUIComponents", "timeleft", "timepassed")
	
	if timesPlayed == 0 then addPlayerArchivement(player, 53) end

	if not gIsSHRunning then
		setElementData(player, "state", "ready")
		return
	end

	local startTick = getElementData(gElementSH, "startTick")
	if getTickCount() - startTick < MAX_PLAYER_WAITING then
		local playerVehicle = getPlayerRaceVeh(player)
		if isElement(playerVehicle) then
			setElementData(player, "state", "alive")
			setVehicleDamageProof(playerVehicle, false)
			setElementFrozen(playerVehicle, false)
		end
	end
end
addEvent( "downloadMapFinishedSH", true)
addEventHandler ( "downloadMapFinishedSH", getRootElement(), downloadMapFinishedSH )

function playerWaitRoundSH(player)
	setElementData(player, "state", "dead")
	setElementAlpha(player, 0)
	setElementFrozen(player, true)
	local timerLeft
	if gSHMapTimer then
		timerLeft, _, _ = getTimerDetails(gSHMapTimer)
		if timerLeft == false or timerLeft == nil then
			timerLeft = getElementData(gElementSH, "duration")
		end
	end
	triggerClientEvent ( player, "addNotification", getRootElement(), 1, 150,12,33, "Wait for the next round to play." )
	callClientFunction ( player, "spectateStart" )
	callClientFunction ( player, "setStartTickLater", timerLeft)
end

function playerKillFuncSH(player)
	if isInGamemode(player, gGamemodeSH) == false then return end
	if gIsSHRunning ~= true then return end
	if isPlayerAlive(player) and gIsSHRunning == true then
		killSHPlayer(player)
	end
end

function killSHPlayer(player, noSpectate)
	if isInGamemode(player, gGamemodeSH) == false then return end
	local hasBeenAlive = false

	local gamemodePlayers = getGamemodePlayers(gGamemodeSH)
	setElementData(player, "vitaShootingAllowed", false)
	setElementData(player, "vitaJumpingAllowed", false)
	
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if (getElementData(pvpElement, "player1") == player or getElementData(pvpElement, "player2") == player) and getElementData(pvpElement, "accepted") == true then 
			local player1 = getElementData(pvpElement, "player1")
			local player2 = getElementData(pvpElement, "player2")
			if player1 == player then
				addPlayerArchivement( player2, 44 )
				outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player2).." has won a PVP war against "..getPlayerName(player1).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeSH,255,0,0, true)
				setPlayerMoney(player2, getPlayerMoney(player2)+getElementData(pvpElement, "money")*2)
			elseif player2 == player then
				addPlayerArchivement( player1, 44 )
				outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player1).." has won a PVP war against "..getPlayerName(player2).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeSH,255,0,0, true)
				setPlayerMoney(player1, getPlayerMoney(player1)+getElementData(pvpElement, "money")*2)
			end
			destroyElement(pvpElement)
			break
		end                                                             
	end	
	
	if (#getAliveGamemodePlayers(gGamemodeSH) ~= 1 and #getAliveGamemodePlayers(gGamemodeSH) ~= 0) and getElementData(player, "AFK") == false and gIsSHRunning == true and getElementData(player, "state") == "alive" then
		local onlinePlayers = 0
		local players = getGamemodePlayers(gGamemodeSH)
		for theKey,thePlayer in pairs(players) do
			onlinePlayers = onlinePlayers + 1
		end
		local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeSH)-#getAliveGamemodePlayers(gGamemodeSH)+1))
		local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeSH)-#getAliveGamemodePlayers(gGamemodeSH)+1))
		if getElementData(player, "isDonator") == true then endMoney = endMoney*2 end
		--if g_eventInProgress == 1 or g_eventInProgress == 2 or g_eventInProgress == 3 then
		--	endPoints = endPoints*2
		--end
		setElementData(player, "winningCounter", 0)
		setElementData(player, "SHMaps", getElementData(player, "SHMaps")+1)
		outputChatBox("#996633:Points: #ffffff You received "..tostring(endPoints).." points and "..tostring(endMoney).." Vero for playing this map.", player, 255, 255, 255, true)
		setElementData(player, "Points", getElementData(player, "Points") + endPoints)
		setElementData(player, "Money", getElementData(player, "Money") + endMoney)
		--if isTimer ( WinTimer ) then
		--	killTimer ( WinTimer )
		--end	
	end	
	
	if getElementData(player, "state") == "alive" then
		if #gRankingboardPlayersSH == 0 then
			for i,v in pairs(getAliveGamemodePlayers(gGamemodeSH)) do
				gRankingboardPlayersSH[i] = ""
			end		
		end	
		for i = #gRankingboardPlayersSH, 1, -1 do
			if gRankingboardPlayersSH[i] == "" then
				gRankingboardPlayersSH[i] = {}
				gRankingboardPlayersSH[i].text = _getPlayerName(player).."#FFFFFF: "..msToTimeStr(getTickCount()-getElementData(gElementSH, "startTick"))
				gRankingboardPlayersSH[i].ply = player
				setElementData(player, "state", "dead")
				hasBeenAlive = true
				callClientFunction(player, "setPassedTime", msToTimeStr(getTickCount()-getElementData(gElementSH, "startTick")))
				for i,v in pairs(gamemodePlayers) do
					playSoundFrontEnd(v, 7)
				end			
				if getElementData(player, "lastCol") and isElement(getElementData(player, "lastCol")) then
					setElementData(getElementData(player, "lastCol"), "shooterkills", getElementData(getElementData(player, "lastCol"), "shooterkills")+1)
					for i,v in ipairs(getGamemodePlayers(getPlayerGameMode(player))) do
						triggerClientEvent ( v, "addKillmessage", v, player, getElementData(player, "lastCol"))
					end
				else
					for i,v in ipairs(getGamemodePlayers(getPlayerGameMode(player))) do
						triggerClientEvent ( v, "addKillmessage", v, player)
					end
				end				
				break
			end
		end
		setElementData(gElementSH, "rankingboard", gRankingboardPlayersSH)
	end	
	
	if tonumber(getElementData(gElementSH, "startTick")) then
		if getTickCount() - getElementData(gElementSH, "startTick") <= 300 and getElementData(player, "AFK") == false then
			addPlayerArchivement(player, 17)
		end		
	end
	
	setElementData(player, "state", "dead")
	setElementData( player, "ghostmod", false )
	if isElement(getPlayerRaceVeh(player)) then
		if isVehicleOnGround ( getPlayerRaceVeh(player) ) == false and getElementHealth ( getPlayerRaceVeh(player) ) <= 250 then 
			addPlayerArchivement(player, 4)
		end	
		destroyElement(getPlayerRaceVeh(player))
	end
	setElementAlpha(player, 0)
	setElementFrozen(player, true)
	
	if noSpectate ~= true then
		callClientFunction ( player, "spectateStart" )
	end

	if #getGamemodePlayers(gGamemodeSH) == 1 and noSpectate == true then
		return true
	end
	
	if gIsSHRunning == false then return true end
	
	local alivePlayers = getAliveGamemodePlayers(gGamemodeSH)
	
	if hasBeenAlive == false then return end
	                              
	if (#alivePlayers == 1) and gIsSHRunning == true then

		if getElementData(alivePlayers[1], "AFK") == false then
			local onlinePlayers = 0
			local players = getGamemodePlayers(gGamemodeSH)
			local isAllAKF = true
			for theKey,thePlayer in pairs(players) do
				onlinePlayers = onlinePlayers + 1
				if thePlayer ~= alivePlayers[1] and getElementData(thePlayer, "AFK") == false then
					isAllAFK = false
				end
			end
			local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeSH)-#getAliveGamemodePlayers(gGamemodeSH)+1))
			local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeSH)-#getAliveGamemodePlayers(gGamemodeSH)+1))
					
			if g_eventInProgress == 1 or g_eventInProgress == 2 or g_eventInProgress == 3 then
				endPoints = endPoints*2
			end
			
			--if g_eventInProgress == 1 or g_eventInProgress == 2 or g_eventInProgress == 3 then
			--	endPoints = endPoints*2
			--end
			
			if isAllAFK == false then
				outputChatBox("#996633:Points: #ffffff You received "..tostring(endPoints).." points and "..tostring(endMoney).." Vero for winning this map.", alivePlayers[1], 255, 255, 255, true)
				setElementData(alivePlayers[1], "Points", getElementData(alivePlayers[1], "Points")+ endPoints)
				setElementData(alivePlayers[1], "Money", getElementData(alivePlayers[1], "Money")+ endMoney)
			else
				outputChatBox("#996633:Points: #ffffff You received no points and Vero as all the other players are AFK.", alivePlayers[1], 255, 255, 255, true)
			end
			if onlinePlayers >= 10 then
				addPlayerArchivement( alivePlayers[1], 8 )
			end
			
			
			givePlayerBetWinning (alivePlayers[1])
			addPlayerArchivement( alivePlayers[1], 51 )
			
			setElementData(alivePlayers[1], "SHWon", getElementData(alivePlayers[1], "SHWon")+1)
			setElementData(alivePlayers[1], "SHMaps", getElementData(alivePlayers[1], "SHMaps")+1)
			if getElementData(alivePlayers[1], "SHWon") == 100 then
				addPlayerArchivement( alivePlayers[1], 48 )
			end
			if getElementData(alivePlayers[1], "SHWon") == 1000 then
				addPlayerArchivement( alivePlayers[1], 49 )
			end
		
			for i = #gRankingboardPlayersSH, 1, -1 do
				if gRankingboardPlayersSH[i] == "" then
					gRankingboardPlayersSH[i] = {}
					gRankingboardPlayersSH[i].text = _getPlayerName(alivePlayers[1]).."#FFFFFF: WINNER"
					gRankingboardPlayersSH[i].ply = alivePlayers[1]
					for i,v in pairs(gamemodePlayers) do
						playSoundFrontEnd(v, 7)
					end			
					break
				end
			end
			setElementData(gElementSH, "rankingboard", gRankingboardPlayersSH)

			local newWinningCounter = getElementData(alivePlayers[1], "winningCounter")+1
			setElementData(alivePlayers[1], "winningCounter", newWinningCounter)
			if newWinningCounter > getElementData(alivePlayers[1], "WinningStreak") then
				setElementData(alivePlayers[1], "WinningStreak", newWinningCounter)
			end

		end
		
		local ran_win_mesage = {
			[1] = "He won "..tostring(getElementData(alivePlayers[1], "SHWon")).." SHOOTER maps",
			[2] = "He drove "..tostring(math.floor(getElementData(alivePlayers[1], "KM"))).." KM in this server!",
			[3] = "He did "..tostring(getElementData(alivePlayers[1], "TopTimes")).." huntertoptimes!",
			[4] = "He is Level "..tostring(getElementData(alivePlayers[1], "Rank")).."!",
			[5] = "He got "..tostring(getElementData(alivePlayers[1], "Money")).." Vero",
			[6] = "He played "..tostring(getElementData(alivePlayers[1], "SHMaps")).." SHOOTER maps!",
			[7] = "He got "..tostring(getElementData(alivePlayers[1], "Points")).." points!",
			[8] = "His winning streak is x"..tostring(getElementData(alivePlayers[1], "winningCounter")).."!",
			[9] = "He has been already for "..tostring(math.floor(getElementData(alivePlayers[1], "TimeOnServer")/60)).." minutes on the Server!"
		}
		
		local hasCustomText = false

		local winsound = getElementData(alivePlayers[1], "useWinsound")
		if winsound ~= 0 then
			for theKey, thePlayer in ipairs(getGamemodePlayers(gGamemodeSH)) do
				if getElementData(thePlayer, "toggleWinsounds") == 1 then
					thePlayer:triggerEvent("playWinsound", winsound)
				end
			end
		end

		if getElementData(alivePlayers[1], "isDonator") == true then
			if getElementData(alivePlayers[1], "customWintext") ~= "none" then
				showWinMessage(gGamemodeSH, "#FFFFFF"..tostring(getElementData(alivePlayers[1], "customWintext")), "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
				hasCustomText = true
			end
		end
		
		if hasCustomText == false then
			showWinMessage(gGamemodeSH, "#FFFFFF".._getPlayerName(alivePlayers[1]) .. '#FFFFFF has won the map!', "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
		end
	end
		
	if (#alivePlayers == 0 or (#alivePlayers == 1 --[[and getElementData(alivePlayers[1], "isDonator") ~= true]])) and gIsSHRunning == true and gHasEndedSH == false then
		endMapSH()
	end
end
	
function endMapSH()
	if gHasEndedSH == true then return false end
	gIsSHRunning = false
	gHasEndedSH = true
	textItemSetText(gTextdisplayTextSH, "changing map in 5")
	for i,v in pairs(getElementsByType("player")) do
		if getPlayerGameMode(v) == gGamemodeSH then
			textDisplayAddObserver(gTextdisplaySH, v)
			callClientFunction(v, "hideHurry")
		else
			if textDisplayIsObserver(gTextdisplaySH, v) then
				textDisplayRemoveObserver(gTextdisplaySH, v)
			end				
		end
	end
	                                              
	setTimer(function()
		textItemSetText(gTextdisplayTextSH, "changing map in 4")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeSH then
				textDisplayAddObserver(gTextdisplaySH, v)		
			else
				if textDisplayIsObserver(gTextdisplaySH, v) then
					textDisplayRemoveObserver(gTextdisplaySH, v)
				end				
			end
		end
	end, 1000, 1)
	setTimer(function()
		textItemSetText(gTextdisplayTextSH, "changing map in 3")                                                                                                                 
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeSH then
				textDisplayAddObserver(gTextdisplaySH, v)		
			else
				if textDisplayIsObserver(gTextdisplaySH, v) then
					textDisplayRemoveObserver(gTextdisplaySH, v)
				end				
			end

		end
	end, 2000, 1)		
	setTimer(function()
		textItemSetText(gTextdisplayTextSH, "changing map in 2")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeSH then
				textDisplayAddObserver(gTextdisplaySH, v)		
			else
				if textDisplayIsObserver(gTextdisplaySH, v) then
					textDisplayRemoveObserver(gTextdisplaySH, v)
				end				
			end

		end
	end, 3000, 1)	
	setTimer(function()
		textItemSetText(gTextdisplayTextSH, "changing map in 1")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeSH then
				textDisplayAddObserver(gTextdisplaySH, v)		
			else
				if textDisplayIsObserver(gTextdisplaySH, v) then
					textDisplayRemoveObserver(gTextdisplaySH, v)
				end				
			end

		end
	end, 4000, 1)		
	setTimer(function()       
		unloadMapSH()
		for i,v in pairs(getElementsByType("player")) do
			textDisplayRemoveObserver(gTextdisplaySH, v)
		end
		setTimer(function()
			loadMapSH(getElementData(gElementSH, "nextmap"))
		end, 1000, 1)
	end, 5000, 1)
end
 
function setUpSHPlayer(player)
	callClientFunction ( player, "spectateEnd" )
	
	if gMapMusicSH == true then
		--triggerClientEvent ( player, "onMapSoundReceive", player,"http://5.230.227.95:22005/vitaStream/sh.mp3")
	end
	setElementData(player, "loadMapSH", false)
	triggerLatentClientEvent ( player, "loadMapSH", 50000, false,  getRootElement(), gMetaSH )
	RankManager:getSingleton():updateAndNotify()
	
	if gIsSHRunning ~= false then return end
	
	setElementData(player, "lastCol", false)
	setElementData(player, "state", "not ready")
	for spawn,v in ipairs(gSpawnPositionsSH) do
		if gSpawnPositionsSH[spawn].used == false then
			setCameraTarget ( player )
			spawnPlayer(player, gSpawnPositionsSH[spawn].posX, gSpawnPositionsSH[spawn].posY, gSpawnPositionsSH[spawn].posZ)
			setElementDimension(player, gGamemodeSH)
			local veh = createVehicle(gSpawnPositionsSH[spawn].vehicle, gSpawnPositionsSH[spawn].posX, gSpawnPositionsSH[spawn].posY, gSpawnPositionsSH[spawn].posZ, gSpawnPositionsSH[spawn].rotX, gSpawnPositionsSH[spawn].rotY, gSpawnPositionsSH[spawn].rotZ, "Vita")
			setElementDimension(veh, gGamemodeSH)
			setElementFrozen(veh, true)
			warpPedIntoVehicle(player, veh)
			gSpawnPositionsSH[spawn].used = true
			setElementData(veh, "isSHVeh", true)
			setElementData(player, "raceVeh", veh)
			setVehicleDamageProof ( veh, true )
			setElementAlpha(player, 255)
			setElementFrozen(player, false)			
			setElementData(player, "mapname", getElementData(gElementSH, "mapname"))
			setElementData(player, "nextmap", getElementData(gElementSH, "nextmap"))				
			break
		else
			if gSpawnPositionsSH[spawn+1] == nil then
				spawn = 1
				setCameraTarget ( player )
				spawnPlayer(player, gSpawnPositionsSH[spawn].posX, gSpawnPositionsSH[spawn].posY, gSpawnPositionsSH[spawn].posZ)
				setElementDimension(player, gGamemodeSH)
				local veh = createVehicle(gSpawnPositionsSH[spawn].vehicle, gSpawnPositionsSH[spawn].posX, gSpawnPositionsSH[spawn].posY, gSpawnPositionsSH[spawn].posZ, gSpawnPositionsSH[spawn].rotX, gSpawnPositionsSH[spawn].rotY, gSpawnPositionsSH[spawn].rotZ, "Vita")
				setElementDimension(veh, gGamemodeSH)
				setElementFrozen(veh, true)
				warpPedIntoVehicle(player, veh)
				gSpawnPositionsSH[spawn].used = true
				setElementData(veh, "isSHVeh", true)
				setElementData(player, "raceVeh", veh)
				setVehicleDamageProof ( veh, true )
				setElementAlpha(player, 255)
				setElementFrozen(player, false)			
				setElementData(player, "mapname", getElementData(gElementSH, "mapname"))
				setElementData(player, "nextmap", getElementData(gElementSH, "nextmap"))						
				break
			end
		end
	end
end

function countdownFuncSH(id)
	for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
		if isPlayerAlive(v) then
			local x, y, z = getElementPosition(v)
			if id == 4 then
				callClientFunction(v, "countdownClientFunc", id)
				callClientFunction(v, "playSound", "files/audio/countstart.mp3")
				if getElementData(v, "mapCamera") == true then
					fadeCamera (v, false, 1, 0, 0, 0)
				end
			end
			if id == 3 then
				callClientFunction(v, "countdownClientFunc", id)
				callClientFunction(v, "playSound", "files/audio/3.mp3")
				if getElementData(v, "mapCamera") == true then
					setCameraMatrix ( v, x+10, y+7, z+3, x, y, z )
					fadeCamera (v, true, 0, 0, 0, 0)
				end
			end
			if id == 2 then
				callClientFunction(v, "countdownClientFunc", id)
				callClientFunction(v, "playSound", "files/audio/2.mp3")
				if getElementData(v, "mapCamera") == true then
					setCameraMatrix ( v, x+4, y-1, z+2, x, y, z )
				end
			end
			if id == 1 then
				callClientFunction(v, "countdownClientFunc", id)
				callClientFunction(v, "playSound", "files/audio/1.mp3")
				if getElementData(v, "mapCamera") == true then
					setCameraMatrix ( v, x+0, y+0, z+15, x, y, z )
				end
			end
			if id == 0 then
				callClientFunction(v, "countdownClientFunc", id)
				callClientFunction(v, "playSound", "files/audio/0.mp3")
                if getElementData(v, "mapCamera") == true then setCameraTarget(v, v) end
				if getElementData(v, "state") == "ready" then
					setElementData(v, "state", "alive")
					if isElement(getPlayerRaceVeh(v)) then
						setVehicleDamageProof ( getPlayerRaceVeh(v), false )
						setElementFrozen(getPlayerRaceVeh(v), false)
						setElementData(v, "vitaJumpingAllowed", true)
					end
				else
					setTimer(
						function(player)
							if not isElement(player) then return end
							if getElementData(player, "state") ~= "alive" then
								killSHPlayer(player)
							end
						end, MAX_PLAYER_WAITING, 1, v)
				end
			end			
		end
	end
	
	if id == 4 then
		betReadySH = setTimer ( function() setElementData(gElementSH, "betAvailable", false) end, 20000, 1 )
		countdownTimerSH = setTimer(countdownFuncSH, 3000, 1, 3)
	elseif id == 3 then
		countdownTimerSH = setTimer(countdownFuncSH, 1000, 1, 2)
	elseif id == 2 then
		countdownTimerSH = setTimer(countdownFuncSH, 1000, 1, 1)
	elseif id == 1 then
		countdownTimerSH = setTimer(countdownFuncSH, 1000, 1, 0)
	elseif id == 0 then
		if #getAliveGamemodePlayers(gGamemodeSH) == 0 or #getAliveGamemodePlayers(gGamemodeSH) == false then --No players were able to be ready? Lets try the next map...
			loadMapSH(getElementData(gElementSH, "nextmap"))	
			return
		end	
		gIsSHRunning = true
		countdownTimerSH = false
		gSHMapTimer = setTimer(endMapSH, getElementData(gElementSH, "duration"), 1)
		setElementData(gElementSH, "startTick", getTickCount())
		gRankingboardPlayersSH = {}
		setElementData(gElementSH, "rankingboard", gRankingboardPlayersSH)
		if gShooterWaitTimer and isTimer(gShooterWaitTimer) then killTimer(gShooterWaitTimer) end
		gShooterWaitTimer = setTimer(function()
			for i,v in pairs(getGamemodePlayers(gGamemodeSH)) do
				setElementData(v, "vitaShootingAllowed", true)
				outputChatBox ("#009029:SHOOTER:#ffffff Shooting is now enabled. FIGHT!", v, 255, 255, 255, true)
			end
		end, 5000, 1)
	end
end

function onPlayerWastedSH(ammo, attacker, weapon, bodypart)
	if isInGamemode(source, gGamemodeSH) then
		killSHPlayer(source)
	end
end
addEventHandler ( "onPlayerWasted", getRootElement(), onPlayerWastedSH )
--[[
Project: vitaCore
File: dm-main.lua
Author(s):	Sebihunter
]]--

local databaseMapDM = false
local timesPlayed = 0
local hunterTable = {}

gGamemodeDM = 5
gElementDM = createElement("elementDM")
gIsDMRunning = false
gHasEndedDM = false
gDMMapTimer = false
countdownTimerDM = false
gMetaDM = false
gRedoCounterDM = 0
gRatingsDM = {}
gMapFilesDM = {}
gMapMusicDM = false


gSpawnPositionsDM = {}
gRankingboardPlayersDM = {}
setElementData(gElementDM, "rankingboard", gRankingboardPlayersDM)

gTextdisplayDM = textCreateDisplay()
gTextdisplayTextDM = textCreateTextItem ( "Testthingy", 0.5, 0.8, "low", 255, 255, 255, 255, 2.0, "center", "top", 255 )
textDisplayAddText ( gTextdisplayDM, gTextdisplayTextDM )

function startTimerDM()
	if gIsDMRunning ~= false then return end
	local maxPlayers = #getGamemodePlayers(gGamemodeDM)
	local readyPlayers = 0
	for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
		if getElementData(v, "state") == "ready" then
			readyPlayers = readyPlayers + 1
		end
	end
	
	if isTimer(gStartTimerDM) then
		local ttime, left, will = getTimerDetails(gStartTimerDM)
		if left == 3 then
			textItemSetText(gTextdisplayTextDM, "waiting for players...")
			for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
				textDisplayAddObserver(gTextdisplayDM, v)
			end
		elseif left == 1 then
			countdownFuncDM(4)
			killTimer(gStartTimerDM)
			gStartTimerDM = false

			for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
				textDisplayRemoveObserver(gTextdisplayDM, v)
			end

			return
		end
	end
	
	if readyPlayers/maxPlayers > 0.8 then
		if isTimer(gStartTimerDM) then killTimer(gStartTimerDM) end
		countdownFuncDM(4)
		gStartTimerDM = false
		for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
			textDisplayRemoveObserver(gTextdisplayDM, v)
		end			
	end
end
gStartTimerDM = false

function loadMapDM(mapname, force)
	if not force then force = false end
	if isMapRunningDM() or gIsDMRunning == true then unloadMapDM() end
	if #getGamemodePlayers(gGamemodeDM) == 0 and force == false then return unloadMapDM() end		
	
	if mapname == "random" then 
		mapname = getRandomMap(gGamemodeDM)
		if mapname == "failed" then
			loadMapDM("random")
			return false
		end
	end
	
	if gRedoCounterDM - 1 > 0 then
		gRedoCounterDM = gRedoCounterDM - 1
	else
		gRedoCounterDM = 0
	end

	hunterTable = {}
	gHasEndedDM = false
	gMapMusicDM = false

	
	if betReadyDM and isTimer(betReadyDM) then killTimer(betReadyDM) end
	
	gSpawnPositionsDM = {}
	gDeathmatchRespawns = {}
	setElementData(gElementDM, "betAvailable", true)
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if getElementData(pvpElement, "gameMode") == gGamemodeDM then
			destroyElement(pvpElement)
		end
	end		
	
	local resource = getResourceFromName ( mapname )

	if not getResourceFromName ( "vitaMapDM" ) then
		createResource ( "vitaMapDM" )
	end
       
	for i,v in ipairs(gMapFilesDM) do
		fileDelete ( ":vitaMapDM/"..tostring(v) )
	end
	gMapFilesDM = {}
	 
	fileDelete ( ":vitaMapDM/meta.xml" )
	local mapXML = xmlCreateFile ( ":vitaMapDM/meta.xml" ,"meta" )                                   
	local mapNode = xmlCreateChild(mapXML, "info")
	xmlNodeSetAttribute(mapNode, "description", "Vita Maploader")
	xmlNodeSetAttribute(mapNode, "type", "script")
	
	--mapNode = xmlCreateChild(mapXML, "file")
	--xmlNodeSetAttribute(mapNode, "src", "meta2.xml")
	
	mapNode = xmlCreateChild(mapXML, "script")
	xmlNodeSetAttribute(mapNode, "src", "vitaMap.lua")
	xmlNodeSetAttribute(mapNode, "type", "client")
	fileCopy("files/mapLoading/vitaMapDM.lua", ":vitaMapDM/vitaMap.lua", true)
	
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)
	
	mapXML = xmlCreateFile ( ":vitaMapDM/meta2.xml" ,"meta" )
	table.insert(gMapFilesDM, "meta2.xml")
	
	local metaXML = xmlLoadFile(":" .. mapname .. "/meta.xml")
	if metaXML then
		local i = 0
		while true do 
			local xmlNode = xmlFindChild(metaXML, "map", i)
			if not xmlNode then
				break
			else
				local copyFile = xmlNodeGetAttribute(xmlNode, "src")
				fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDM/"..copyFile, true )
				table.insert(gMapFilesDM, copyFile)
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
							
							local spawnID = #gSpawnPositionsDM+1
							gSpawnPositionsDM[spawnID] = {}
							gSpawnPositionsDM[spawnID].posX = posX
							gSpawnPositionsDM[spawnID].posY = posY
							gSpawnPositionsDM[spawnID].posZ = posZ
							gSpawnPositionsDM[spawnID].rotX = rotX
							gSpawnPositionsDM[spawnID].rotY = rotY
							gSpawnPositionsDM[spawnID].rotZ = rotZ
							gSpawnPositionsDM[spawnID].interior = interiorID
							gSpawnPositionsDM[spawnID].vehicle = modelID
							gSpawnPositionsDM[spawnID].used = false
						end
						i2 = i2+1
					end
					xmlUnloadFile(mapfile)
				end				
				i = i + 1
			end
		end
		
		if #gSpawnPositionsDM == 0 or #gSpawnPositionsDM == false then
			return loadMapDM("random")
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

				if not metaLineExists and (xmlNodeGetAttribute(xmlNode, "type") == "client" or xmlNodeGetAttribute(xmlNode, "type") == "shared") then
					fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDM/"..copyFile, true )
					table.insert(gMapFilesDM, copyFile)
					mapNode = xmlCreateChild(mapXML, "file")
					xmlNodeSetAttribute(mapNode, "src", copyFile)
					xmlNodeSetAttribute(mapNode, "type", "client")
					xmlNodeSetAttribute(mapNode, "download", "false")	
					temporaryTable[#temporaryTable+1] = copyFile
				end
				i = i + 1
			end
		end		
		
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
						gMapMusicDM = true
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaStream/dm.mp3", true )
					else
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDM/"..copyFile, true )
						table.insert(gMapFilesDM, copyFile)
						mapNode = xmlCreateChild(mapXML, "file")
						xmlNodeSetAttribute(mapNode, "src", copyFile)
						xmlNodeSetAttribute(mapNode, "download", "false")
						temporaryTable[#temporaryTable+1] = copyFile
					end
				end
				i = i + 1
			end
		end
		
		temporaryTable  = {}

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
				setElementData(gElementDM, "mapname", realMapname)
			else
				setElementData(gElementDM, "mapname", mapname)
			end
		else
			setElementData(gElementDM, "mapname", mapname)
		end
	end
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)
	xmlUnloadFile(metaXML)

	local hFile = fileOpen(":vitaMapDM/meta2.xml")
	local buffer = ""
	if hFile then
		while not fileIsEOF(hFile) do
			buffer = buffer .."".. fileRead(hFile, 500)
		end
	end
	fileClose(hFile)
	gMetaDM = buffer

	setElementData(gElementDM, "map", mapname)

	databaseMapDM = DatabaseMap:new(mapname)
	timesPlayed = databaseMapDM.m_Timesplayed
	gRatingsDM = databaseMapDM.m_Ratings


	if mapname == getElementData(gElementDM, "nextmap") then
		setElementData(gElementDM, "nextmap", "random")
	end
	
	local duration = 10*60*1000                                                                                      
	setElementData(gElementDM, "duration", duration)
	
	--refreshResources ( false )
	startResource(getResourceFromName("vitaMapDM"))
	
	if gStartTimerDM == false or isTimer(gStartTimerDM) == false then
		gStartTimerDM = setTimer(startTimerDM, 5000, 6) -- 6 times = 30 seconds
	end
	
	setTimer(function()
	for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
			setUpDMPlayer(v)
			textDisplayRemoveObserver(gTextdisplayDM, v)
	end end, 500,1)
end

function unloadMapDM()
	if isTimer(gStartTimerDM) then
		killTimer(gStartTimerDM)
		gStartTimerDM = false
	end
	gIsDMRunning = false

	if databaseMapDM then
		databaseMapDM.m_Ratings = gRatingsDM
		databaseMapDM.m_Timesplayed = databaseMapDM.m_Timesplayed + 1
		databaseMapDM:delete()
		databaseMapDM = false
	end

	--stopResource(getResourceFromName("vitaMapDM"))
	setElementData(gElementDM, "map", "none")
	setElementData(gElementDM, "mapname", "loading...")
	setElementData(gElementDM, "startTick", nil)
	gRankingboardPlayersDM = {}
	setElementData(gElementDM, "rankingboard", gRankingboardPlayersDM)
	
	if countdownTimerDM then
		if isTimer(countdownTimerDM) then
			killTimer(countdownTimerDM)
		end	
	end
	
	if gDMMapTimer then
		if isTimer(gDMMapTimer) then
			killTimer(gDMMapTimer)
		end
	end
	
	for i,v in pairs(getElementsByType("vehicle")) do 
		if getElementData(v, "isDMVeh") == true then
			if isElement(v) then
				destroyElement(v)
			end
		end
	end
	
	for i,player in pairs(getGamemodePlayers(gGamemodeDM)) do
		setElementData(player, "state", "dead")
		--sendToptimes(player, false)
		triggerClientEvent ( player, "stopMapDM", getRootElement() )
		callClientFunction(player, "hideHurry")
		triggerClientEvent ( player, "onMapSoundStop", player )
	end
end

function isMapRunningDM()
	if getElementData(gElementDM, "map") ~= "none" then return true end
	return false
end

function joinDM(player)
	if getPlayerGameMode(player) == gGamemodeDM then return false end
	if #getGamemodePlayers(gGamemodeDM) >= gRaceModes[gGamemodeDM].maxplayers then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is currently full.") return false end
	local loadsNewMap = false
	if #getGamemodePlayers(gGamemodeDM) == 0 then
		loadsNewMap = true
		setElementData(gElementDM, "map", "none")
		setElementData(gElementDM, "mapname", "loading...")
		setElementData(gElementDM, "nextmap", "random")
		loadMapDM(getElementData(gElementDM, "nextmap"), true)
	end
	
	bindKey ( player, "n", "down", respawnPlayerDM, false )
	bindKey ( player, "space", "down", respawnPlayerDM, false )
	bindKey ( player, "c", "down", respawnPlayerDM, true )

    databaseMapDM:sendToptimes(player)
	setElementData(player, "gameMode", gGamemodeDM)
	setElementData(player, "mapname", getElementData(gElementDM, "mapname"))
	setElementData(player, "nextmap", getElementData(gElementDM, "nextmap"))
	setElementData(player, "winningCounter", 0)

	for i, v in pairs(getGamemodePlayers(gGamemodeDM)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, true )
			setElementVisibleTo ( gPlayerBlips[v], player, true )
		end
	end

	setElementData(player, "ghostmod", true)

	setElementDimension(player, gGamemodeDM)
	triggerClientEvent ( player, "addNotification", getRootElement(), 2, 15,150,190, "You joined 'Deathmatch'." )
	triggerClientEvent ( player, "hideSelection", getRootElement() )
	outputChatBoxToGamemode ( "#CCFF66:JOIN: #FFFFFF"..getPlayerName(player).."#FFFFFF has joined the gamemode.", gGamemodeDM, 255, 255, 255, true )
	
	callClientFunction(player, "showGUIComponents", "nextMap", "mapdisplay", "money")
	
	setElementData(player, "state", "joined")
	toggleControl ( player, "enter_exit", false )
	
	if loadsNewMap == false then
		setUpDMPlayer(player)
	end
	
	bindKey(player, "F", "down", playerKillFuncDM)
	bindKey(player, "enter", "down", playerKillFuncDM)
	
	if gIsDMRunning == true then
		playerWaitRoundDM(player)
	end
end
addEvent("joinDM", true)
addEventHandler("joinDM", getRootElement(), joinDM)

function quitDM(player)
	if getPlayerGameMode(player)  ~= gGamemodeDM then return false end
	
	if bettedPlayer[player] then bettedPlayer[player] = false end
	killDMPlayer(player, true)
	unbindKey(player, "n", "down", respawnPlayerDM)
	unbindKey(player, "c", "down", respawnPlayerDM)

	if textDisplayIsObserver(gTextdisplayDM, player) then
		textDisplayRemoveObserver(gTextdisplayDM, player)
	end	
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeDM)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, false )
			setElementVisibleTo ( gPlayerBlips[v], player, false )
		end
	end
	
	toggleControl ( player, "vehicle_secondary_fire", true )
	setElementData(player, "ghostmod", false )
	setElementData(player, "winline", nil)
	setElementData(player, "winline2", nil)
	setElementData(player, "winr", nil)
	setElementData(player, "wing", nil)
	setElementData(player, "winb", nil)
	
	setElementData(player, "gameMode", 0)
	spawnPlayer(player, 0,0,0)
	setElementDimension(player, 0)
	setElementInterior(player, 0)
	setElementFrozen(player, true)
	outputChatBoxToGamemode ( "#FF6666:QUIT: #FFFFFF"..getPlayerName(player).."#FFFFFF has left the gamemode.", gGamemodeDM, 255, 255, 255, true )
	
	triggerClientEvent ( player, "stopMapDM", getRootElement() )
	triggerClientEvent ( player, "onMapSoundStop", player )
	
	if #getGamemodePlayers(gGamemodeDM) == 1 then
		for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
			triggerClientEvent(v, "foreveraloneClient",getRootElement())
			addPlayerArchivement(v, 64)
		end
	end
	
	if #getGamemodePlayers(gGamemodeDM) == 0 then
		unloadMapDM()
	end
end
addEvent("quitDM", true)
addEventHandler("quitDM", getRootElement(), quitDM)

function downloadMapFinishedDM(player)
    databaseMapDM:sendToptimes(player)
	player:triggerEvent("initTimings", getElementData(gElementDM, "mapname"), databaseMapDM:getTimings())

	callClientFunction(player, "forceToptimesOpen")
	callClientFunction(player, "allowNewHurryFunc")

	local mapRating = {likes = 0, dislikes = 0}
	for _, PlayerRate in pairs(gRatingsDM) do
		mapRating.likes = mapRating.likes + PlayerRate.Rating
	end
	mapRating.dislikes = #gRatingsDM - mapRating.likes

	callClientFunction(player, "forceMapRating", getElementData(gElementDM, "mapname"), mapRating, timesPlayed)
	callClientFunction(player, "showGUIComponents", "timeleft", "timepassed")

	if timesPlayed == 0 then addPlayerArchivement(player, 53) end

	if not gIsDMRunning then
		setElementData(player, "state", "ready")
		return
	end

	local startTick = getElementData(gElementDM, "startTick")
	if getTickCount() - startTick < MAX_PLAYER_WAITING then
		local playerVehicle = getPlayerRaceVeh(player)
		if isElement(playerVehicle) then
			setElementData(player, "state", "alive")
			setVehicleDamageProof(playerVehicle, false)
			setElementFrozen(playerVehicle, false)
		end
	end
end
addEvent( "downloadMapFinishedDM", true)
addEventHandler ( "downloadMapFinishedDM", getRootElement(), downloadMapFinishedDM )

function playerWaitRoundDM(player)
	setElementData(player, "state", "dead")
	setElementAlpha(player, 0)
	setElementFrozen(player, true)
	local timerLeft
	if gDMMapTimer then
		timerLeft, _, _ = getTimerDetails(gDMMapTimer)
		if timerLeft == false or timerLeft == nil then
			timerLeft = getElementData(gElementDM, "duration")
		end
	end
	triggerClientEvent ( player, "addNotification", getRootElement(), 1, 150,12,33, "Wait for the next round to play." )
	callClientFunction ( player, "spectateStart" )
	callClientFunction ( player, "setStartTickLater", timerLeft)
end

function playerKillFuncDM(player)
	if isInGamemode(player, gGamemodeDM) == false then return end
	if gIsDMRunning ~= true then return end
	if (isPlayerAlive(player) or getElementData(player, "state") == "replaying") and gIsDMRunning == true then
		killDMPlayer(player)
	end
end

function killDMPlayer(player, noSpectate)
	if isInGamemode(player, gGamemodeDM) == false then return end
	local hasBeenAlive = false	
	
	local gamemodePlayers = getGamemodePlayers(gGamemodeDM)
	
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if (getElementData(pvpElement, "player1") == player or getElementData(pvpElement, "player2") == player) and getElementData(pvpElement, "accepted") == true then 
			local player1 = getElementData(pvpElement, "player1")
			local player2 = getElementData(pvpElement, "player2")
			if player1 == player then
				addPlayerArchivement( player2, 44 )
				outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player2).." has won a PVP war against "..getPlayerName(player1).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeDM,255,0,0, true)
				setPlayerMoney(player2, getPlayerMoney(player2)+getElementData(pvpElement, "money")*2)
			elseif player2 == player then
				addPlayerArchivement( player1, 44 )
				outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player1).." has won a PVP war against "..getPlayerName(player2).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeDM,255,0,0, true)
				setPlayerMoney(player1, getPlayerMoney(player1)+getElementData(pvpElement, "money")*2)
			end
			destroyElement(pvpElement)
			break
		end                                                             
	end

	if (#getAliveGamemodePlayers(gGamemodeDM) ~= 1 and #getAliveGamemodePlayers(gGamemodeDM) ~= 0) and getElementData(player, "AFK") == false and gIsDMRunning == true and getElementData(player, "state") == "alive" then		local onlinePlayers = 0
		local players = getGamemodePlayers(gGamemodeDM)
		for theKey,thePlayer in pairs(players) do
			onlinePlayers = onlinePlayers + 1
		end
		local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeDM)-#getAliveGamemodePlayers(gGamemodeDM)+1))
		local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeDM)-#getAliveGamemodePlayers(gGamemodeDM)+1))
		if getElementData(player, "isDonator") == true then endMoney = endMoney*2 end
		--local endPoints = math.floor(onlinePlayers*(8.5+(onlinePlayers/100))/(#getAliveGamemodePlayers(gGamemodeDM)+1))
		--local endMoney =  math.floor(onlinePlayers*(65+(onlinePlayers/100))/(#getAliveGamemodePlayers(gGamemodeDM)+1))
		--if g_eventInProgress == 1 or g_eventInProgress == 2 or g_eventInProgress == 3 then
		--	endPoints = endPoints*2
		--end
		setElementData(player, "winningCounter", 0)
		outputChatBox("#996633:Points: #ffffff You received "..tostring(endPoints).." points and "..tostring(endMoney).." Vero for playing this map.", player, 255, 255, 255, true)
		setElementData(player, "Points", getElementData(player, "Points") + endPoints)
		setElementData(player, "Money", getElementData(player, "Money") + endMoney)
		setElementData(player, "DMMaps", getElementData(player, "DMMaps")+1)
		--if isTimer ( WinTimer ) then
		--	killTimer ( WinTimer )
		--end	
	end
	
	if getElementData(player, "state") == "alive" then
		if #gRankingboardPlayersDM == 0 then
			for i,v in pairs(getAliveGamemodePlayers(gGamemodeDM)) do
				gRankingboardPlayersDM[i] = ""
			end		
		end
		for i = #gRankingboardPlayersDM, 1, -1 do
			if gRankingboardPlayersDM[i] == "" then
				gRankingboardPlayersDM[i] = {}
				gRankingboardPlayersDM[i].text = _getPlayerName(player).."#FFFFFF: "..msToTimeStr(getTickCount()-getElementData(gElementDM, "startTick"))
				gRankingboardPlayersDM[i].ply = player
				setElementData(player, "state", "dead")
				if getElementModel(getPlayerRaceVeh(player)) ~= 425 then
					setElementData(player, "hunterReachedCounter", 0)
				end				
				hasBeenAlive = true
				callClientFunction(player, "setPassedTime", msToTimeStr(getTickCount()-getElementData(gElementDM, "startTick")))
				for i,v in pairs(gamemodePlayers) do
					playSoundFrontEnd(v, 7)
				end			
				break
			end
		end
		setElementData(gElementDM, "rankingboard", gRankingboardPlayersDM)
	end

	if tonumber(getElementData(gElementDM, "startTick")) then
		if getTickCount() - getElementData(gElementDM, "startTick") <= 300 and getElementData(player, "AFK") == false then
			addPlayerArchivement(player, 17)
		end	
	end
	
	setElementData(player, "state", "dead")
	player:triggerEvent("updateSpawnPositions", false)

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

	if #getGamemodePlayers(gGamemodeDM) == 1 and noSpectate == true then
		return true
	end
	
	if gIsDMRunning == false then return true end
	
	local alivePlayers = getAliveGamemodePlayers(gGamemodeDM)

	if (#alivePlayers == 0 or (#alivePlayers == 1 and  getElementModel(getPlayerRaceVeh(alivePlayers[1])) == 425)) and gIsDMRunning == true and gHasEndedDM == false then
		setTimer(endMapDM,50,1)
	end
	
	if hasBeenAlive == false then return end
	                              
	if (#alivePlayers == 1) and gIsDMRunning == true then

		if getElementData(alivePlayers[1], "AFK") == false then
			local onlinePlayers = 0
			local players = getGamemodePlayers(gGamemodeDM)
			local isAllAKF = true
			for theKey,thePlayer in pairs(players) do
				onlinePlayers = onlinePlayers + 1
				if thePlayer ~= alivePlayers[1] and getElementData(thePlayer, "AFK") == false then
					isAllAFK = false
				end
			end
			local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeDM)-#getAliveGamemodePlayers(gGamemodeDM)+1))
			local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeDM)-#getAliveGamemodePlayers(gGamemodeDM)+1))
					
			if g_eventInProgress == 1 or g_eventInProgress == 2 or g_eventInProgress == 3 then
				endPoints = endPoints*2
			end
			
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
			
			setElementData(alivePlayers[1], "DMWon", getElementData(alivePlayers[1], "DMWon")+1)
			setElementData(alivePlayers[1], "DMMaps", getElementData(alivePlayers[1], "DMMaps")+1)
			givePlayerBetWinning(alivePlayers[1])
			
			if getElementData(alivePlayers[1], "DMWon") >= 100 then
				addPlayerArchivement( alivePlayers[1], 19 )
			end
			if getElementData(alivePlayers[1], "DMWon") >= 1000 then
				addPlayerArchivement( alivePlayers[1], 21 )
			end
		
			for i = #gRankingboardPlayersDM, 1, -1 do
				if gRankingboardPlayersDM[i] == "" then
					gRankingboardPlayersDM[i] = {}
					gRankingboardPlayersDM[i].text = _getPlayerName(alivePlayers[1]).."#FFFFFF: WINNER"
					gRankingboardPlayersDM[i].ply = alivePlayers[1]
					for i,v in pairs(gamemodePlayers) do
						playSoundFrontEnd(v, 7)
					end			
					break
				end
			end
			setElementData(gElementDM, "rankingboard", gRankingboardPlayersDM)
			
			local newWinningCounter = getElementData(alivePlayers[1], "winningCounter")+1
			setElementData(alivePlayers[1], "winningCounter", newWinningCounter)
			if newWinningCounter > getElementData(alivePlayers[1], "WinningStreak") then
				setElementData(alivePlayers[1], "WinningStreak", newWinningCounter)
			end
			
			if newWinningCounter >= 5 then addPlayerArchivement(alivePlayers[1], 12) end
			if newWinningCounter >= 7 then addPlayerArchivement(alivePlayers[1], 13) end
			if newWinningCounter >= 11 then addPlayerArchivement(alivePlayers[1], 14) end
		end
		
		local ran_win_mesage = {
			[1] = "He won "..tostring(getElementData(alivePlayers[1], "DMWon")).." DM maps",
			[2] = "He drove "..tostring(math.floor(getElementData(alivePlayers[1], "KM"))).." KM in this server!",
			[3] = "He did "..tostring(getElementData(alivePlayers[1], "TopTimes")).." huntertoptimes!",
			[4] = "He is Level "..tostring(getElementData(alivePlayers[1], "Rank")).."!",
			[5] = "He got "..tostring(getElementData(alivePlayers[1], "Money")).." Vero",
			[6] = "He played "..tostring(getElementData(alivePlayers[1], "DMMaps")).." DM maps!",
			[7] = "He got "..tostring(getElementData(alivePlayers[1], "Points")).." points!",
			[8] = "His winning streak is x"..tostring(getElementData(alivePlayers[1], "winningCounter")).."!",
			[9] = "He has been already for "..tostring(math.floor(getElementData(alivePlayers[1], "TimeOnServer")/60)).." minutes on the Server!"
		}
		
		local hasCustomText = false

		local winsound = getElementData(alivePlayers[1], "useWinsound")
		if winsound ~= 0 then
			for theKey,thePlayer in ipairs(getGamemodePlayers(gGamemodeDM)) do
				if getElementData(thePlayer, "toggleWinsounds") == 1 then
					thePlayer:triggerEvent("playWinsound", winsound)
				end
			end
		end

		if getElementData(alivePlayers[1], "isDonator") == true then
			if getElementData(alivePlayers[1], "customWintext") ~= "none" then
				showWinMessage(gGamemodeDM, "#FFFFFF"..tostring(getElementData(alivePlayers[1], "customWintext")), "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
				hasCustomText = true
			end
		end
		
		if hasCustomText == false then
			showWinMessage(gGamemodeDM, "#FFFFFF".._getPlayerName(alivePlayers[1]) .. '#FFFFFF has won the map!', "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
		end
	end
end
	
function endMapDM()
	if gHasEndedDM == true then return false end
	gIsDMRunning = false
	gHasEndedDM = true
		
	textItemSetText(gTextdisplayTextDM, "changing map in 5")
	for i,v in pairs(getElementsByType("player")) do
		if getPlayerGameMode(v) == gGamemodeDM then
			textDisplayAddObserver(gTextdisplayDM, v)
			setElementData( v, "ghostmod", false )
			callClientFunction(v, "hideHurry")
		else
			if textDisplayIsObserver(gTextdisplayDM, v) then
				textDisplayRemoveObserver(gTextdisplayDM, v)
			end				
		end
	end
	                                              
	setTimer(function()
		textItemSetText(gTextdisplayTextDM, "changing map in 4")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDM then
				textDisplayAddObserver(gTextdisplayDM, v)		
			else
				if textDisplayIsObserver(gTextdisplayDM, v) then
					textDisplayRemoveObserver(gTextdisplayDM, v)
				end				
			end
		end
	end, 1000, 1)
	setTimer(function()
		textItemSetText(gTextdisplayTextDM, "changing map in 3")                                                                                                                 
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDM then
				textDisplayAddObserver(gTextdisplayDM, v)		
			else
				if textDisplayIsObserver(gTextdisplayDM, v) then
					textDisplayRemoveObserver(gTextdisplayDM, v)
				end				
			end

		end
	end, 2000, 1)		
	setTimer(function()
		textItemSetText(gTextdisplayTextDM, "changing map in 2")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDM then
				textDisplayAddObserver(gTextdisplayDM, v)		
			else
				if textDisplayIsObserver(gTextdisplayDM, v) then
					textDisplayRemoveObserver(gTextdisplayDM, v)
				end				
			end

		end
	end, 3000, 1)	
	setTimer(function()
		textItemSetText(gTextdisplayTextDM, "changing map in 1")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDM then
				textDisplayAddObserver(gTextdisplayDM, v)		
			else
				if textDisplayIsObserver(gTextdisplayDM, v) then
					textDisplayRemoveObserver(gTextdisplayDM, v)
				end				
			end

		end
	end, 4000, 1)		
	setTimer(function()       
		unloadMapDM()
		for i,v in pairs(getElementsByType("player")) do
			textDisplayRemoveObserver(gTextdisplayDM, v)
		end
		setTimer(function()
			loadMapDM(getElementData(gElementDM, "nextmap"))
		end, 1000, 1)
	end, 5000, 1)
end
 
function setUpDMPlayer(player)
	callClientFunction ( player, "spectateEnd" )
	toggleControl ( player, "vehicle_secondary_fire", true )
	
	if gMapMusicDM == true then
		--triggerClientEvent ( player, "onMapSoundReceive", player,"http://5.230.227.95:22005/vitaStream/dm.mp3")
	end
	
	setElementData(player, "loadMapDM", false)
	triggerLatentClientEvent ( player, "loadMapDM", 50000, false,  getRootElement(), gMetaDM )
	RankManager:getSingleton():updateAndNotify()
	
	if gIsDMRunning ~= false then setElementData( player, "ghostmod", false ) return end
	setElementData( player, "ghostmod", true )
	
	setElementData(player, "state", "not ready")

	local spawnId = 1
	for spawn,v in ipairs(gSpawnPositionsDM) do
		if gSpawnPositionsDM[spawn].used == false then
			setCameraTarget ( player )
			spawnPlayer(player, gSpawnPositionsDM[spawn].posX, gSpawnPositionsDM[spawn].posY, gSpawnPositionsDM[spawn].posZ)
			setElementDimension(player, gGamemodeDM)
			local veh = createVehicle(gSpawnPositionsDM[spawn].vehicle, gSpawnPositionsDM[spawn].posX, gSpawnPositionsDM[spawn].posY, gSpawnPositionsDM[spawn].posZ, gSpawnPositionsDM[spawn].rotX, gSpawnPositionsDM[spawn].rotY, gSpawnPositionsDM[spawn].rotZ, "Vita")
			setElementDimension(veh, gGamemodeDM)
			setElementFrozen(veh, true)
			warpPedIntoVehicle(player, veh)
			setVehicleDamageProof ( veh, true )
			gSpawnPositionsDM[spawn].used = true
			setElementData(veh, "isDMVeh", true)
			setElementData(player, "raceVeh", veh)
			setElementAlpha(player, 255)
			setElementFrozen(player, false)			
			setElementData(player, "mapname", getElementData(gElementDM, "mapname"))
			setElementData(player, "nextmap", getElementData(gElementDM, "nextmap"))
			spawnId = spawn
			break
		else
			if gSpawnPositionsDM[spawn+1] == nil then
				spawn = 1
				setCameraTarget ( player )
				spawnPlayer(player, gSpawnPositionsDM[spawn].posX, gSpawnPositionsDM[spawn].posY, gSpawnPositionsDM[spawn].posZ)
				setElementDimension(player, gGamemodeDM)
				local veh = createVehicle(gSpawnPositionsDM[spawn].vehicle, gSpawnPositionsDM[spawn].posX, gSpawnPositionsDM[spawn].posY, gSpawnPositionsDM[spawn].posZ, gSpawnPositionsDM[spawn].rotX, gSpawnPositionsDM[spawn].rotY, gSpawnPositionsDM[spawn].rotZ, "Vita")
				setElementDimension(veh, gGamemodeDM)
				setElementFrozen(veh, true)
				warpPedIntoVehicle(player, veh)
				setVehicleDamageProof ( veh, true )
				gSpawnPositionsDM[spawn].used = true
				setElementData(veh, "isDMVeh", true)
				setElementData(player, "raceVeh", veh)
				setElementAlpha(player, 255)
				setElementFrozen(player, false)			
				setElementData(player, "mapname", getElementData(gElementDM, "mapname"))
				setElementData(player, "nextmap", getElementData(gElementDM, "nextmap"))
				spawnId = spawn
				break
			end
		end
	end

	player:triggerEvent("updateSpawnPositions", gSpawnPositionsDM, spawnId, gElementDM:getData("mapname"))
end

function countdownFuncDM(id)
	for i,v in pairs(getGamemodePlayers(gGamemodeDM)) do
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
						setVehicleDamageProof(getPlayerRaceVeh(v), false)
						setElementFrozen(getPlayerRaceVeh(v), false)
					end
				else
					setTimer(
						function(player)
							if not isElement(player) then return end
							if getElementData(player, "state") ~= "alive" then
								killDMPlayer(player)
							end
						end, MAX_PLAYER_WAITING, 1, v)
				end
			end			
		end
	end
	
	if id == 4 then
		countdownTimerDM = setTimer(countdownFuncDM, 3000, 1, 3)
		betReadyDM = setTimer ( function() setElementData(gElementDM, "betAvailable", false) end, 20000, 1 )
	elseif id == 3 then
		countdownTimerDM = setTimer(countdownFuncDM, 1000, 1, 2)
	elseif id == 2 then
		countdownTimerDM = setTimer(countdownFuncDM, 1000, 1, 1)
	elseif id == 1 then
		countdownTimerDM = setTimer(countdownFuncDM, 1000, 1, 0)
	elseif id == 0 then
		if #getAliveGamemodePlayers(gGamemodeDM) == 0 or #getAliveGamemodePlayers(gGamemodeDM) == false then --No players were able to be ready? Lets try the next map...
			loadMapDM(getElementData(gElementDM, "nextmap"))		
			return
		end

		gIsDMRunning = true
		countdownTimerDM = false
		gDMMapTimer = setTimer(endMapDM, getElementData(gElementDM, "duration"), 1)
		setElementData(gElementDM, "startTick", getTickCount())
		gRankingboardPlayersDM = {}
		setElementData(gElementDM, "rankingboard", gRankingboardPlayersDM)
	end
end

function onPlayerWastedDM()
	if isInGamemode(source, gGamemodeDM) then
		killDMPlayer(source)
	end
end
addEventHandler ( "onPlayerWasted", getRootElement(), onPlayerWastedDM )

function playerGotHunter(hunterTime, timings)
	if not hunterTime then return end
	local player = client

	if hunterTable[client] then return end
	hunterTable[client] = true

	callClientFunction(player, "setWeather", 0)
	callClientFunction(player, "setTime", 0, 0)
	callClientFunction(player, "resetSkyGradient")
	setElementData(player, "ghostmod", false)
	toggleControl(player, "vehicle_secondary_fire", false)
	outputChatBox("#996633:Points: #ffffff You recieved 50 extra-points for reaching the Hunter.", player, 255, 255, 255, true)
	setElementData(player, "Points", getElementData(player, "Points") + 50)

	databaseMapDM:setTimings(player.m_ID, hunterTime, timings)
	local hasToptime, hasPosition = databaseMapDM:getToptimeFromPlayer(player.m_ID)
	local toptimeAdded = databaseMapDM:addNewToptime(player.m_ID, hunterTime)

	if toptimeAdded then
		callClientFunction(player, "forceToptimesOpen")

		local tInformation, tPosition = databaseMapDM:getToptimeFromPlayer(player.m_ID)
		outputChatBoxToGamemode(":TOPTIME:#FFFFFF ".._getPlayerName(player).."#FFFFFF finished the map ("..msToTimeStr(tInformation.time)..") and got toptime position "..tPosition..".",gGamemodeDM, 148,214,132, true)

        if tPosition <= 12 and hasToptime == false then
			setElementData(source, "TopTimes", getElementData(source, "TopTimes") + 1)
			setElementData(source, "TopTimeCounter", getElementData(source, "TopTimeCounter") + 1)
		end
		if tPosition <= 12 and (hasToptime and tPosition < hasPosition) then
			addPlayerArchivement(source, 59)
		end

		for _, v in pairs(getGamemodePlayers(gGamemodeDM)) do
			databaseMapDM:sendToptimes(v)
		end
	end

	setElementData(player, "hunterReachedCounter", getElementData(player, "hunterReachedCounter")+1)
	if getElementData(player, "hunterReachedCounter") == 3 then
		addPlayerArchivement(player, 11)
	elseif getElementData(player, "hunterReachedCounter") == 2 then
		addPlayerArchivement(player, 10)
	end		
	addPlayerArchivement(player, 9)

	if #getAliveGamemodePlayers(gGamemodeDM) == 1 then
		endMapDM()
	end
end
addEvent("playerGotHunter", true)
addEventHandler("playerGotHunter", root, playerGotHunter)
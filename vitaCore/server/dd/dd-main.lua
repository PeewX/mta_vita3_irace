--[[
Project: vitaCore
File: dd-main.lua
Author(s):	Sebihunter
]]--

local databaseMapDD = false
local timesPlayed = 0

gGamemodeDD = 2
gElementDD = createElement("elementDD")
gIsDDRunning = false
gHasEndedDD = false
gDDMapTimer = false
gMetaDD = false
gRedoCounterDD = 0
countdownTimerDD = false
gRatingsDD = {}
gMapFilesDD = {}
gMapMusicDD = false

gMapResourceNameDD = "none"


gSpawnPositionsDD = {}
gRankingboardPlayersDD = {}
setElementData(gElementDD, "rankingboard", gRankingboardPlayersDD)

gTextdisplayDD = textCreateDisplay()
gTextdisplayTextDD = textCreateTextItem ( "Testthingy", 0.5, 0.8, "low", 255, 255, 255, 255, 2.0, "center", "top", 255 )
textDisplayAddText ( gTextdisplayDD, gTextdisplayTextDD )

function startTimerDD()
	if gIsDDRunning ~= false then return end
	local maxPlayers = #getGamemodePlayers(gGamemodeDD)
	local readyPlayers = 0
	for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
		if getElementData(v, "state") == "ready" then
			readyPlayers = readyPlayers + 1
		end
	end
	
	if isTimer(gStartTimerDD) then
		local ttime, left, will = getTimerDetails ( gStartTimerDD )
		if left == 3 then
			textItemSetText(gTextdisplayTextDD, "waiting for players...")
			for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
				textDisplayAddObserver(gTextdisplayDD, v)
			end
		elseif left == 1 then
			countdownFuncDD(4)
			killTimer(gStartTimerDD)
			gStartTimerDD = false

			for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
				textDisplayRemoveObserver(gTextdisplayDD, v)
			end

			return
		end
	end
	
	if readyPlayers/maxPlayers > 0.8 then
		if isTimer(gStartTimerDD) then killTimer(gStartTimerDD) end
		countdownFuncDD(4)
		gStartTimerDD = false
		for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
			textDisplayRemoveObserver(gTextdisplayDD, v)
		end			
	end
end
gStartTimerDD = false

function loadMapDD(mapname, force)
	if not force then force = false end
	if isMapRunningDD() or gIsDDRunning == true then unloadMapDD() end
	if #getGamemodePlayers(gGamemodeDD) == 0 and force == false then return unloadMapDD() end	

	-- Make sure that the resource is stopped
	local ddRes = getResourceFromName("vitaMapDD")
	if ddRes then
		if getResourceState(ddRes) == "Running" then
			stopResource(ddRes)
			setTimer(loadMapDD, 500, 1, mapname, force)
			return
		elseif getResourceState(ddRes) == "failed to load" then
			loadMapDD("random")
			return false
		elseif getResourceState(ddRes) ~= "loaded" then
			setTimer(loadMapDD, 500, 1, mapname, force)
			return
		end
	end

	if mapname == "random" then
		mapname = getRandomMap(gGamemodeDD)
		if mapname == "failed" then
			loadMapDD("random")
			return false
		end
	end
	outputServerLog("loadMapDD: "..tostring(mapname))	
	
	if gRedoCounterDD - 1 > 0 then
		gRedoCounterDD = gRedoCounterDD - 1
	else
		gRedoCounterDD = 0
	end
	
	gMapMusicDD = false
	gHasEndedDD = false
	
	if betReadyDD and isTimer(betReadyDD) then killTimer(betReadyDD) end
	
	gSpawnPositionsDD = {}
	setElementData(gElementDD, "betAvailable", true)
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if getElementData(pvpElement, "gameMode") == gGamemodeDD then
			destroyElement(pvpElement)
		end
	end		
	
	local resource = getResourceFromName ( mapname )

	--stopResource(getResourceFromName ( "vitaMapDD" ))
	--deleteResource ( "vitaMapDD")
	--refreshResources ( false )
	if not getResourceFromName ( "vitaMapDD" ) then
		createResource ( "vitaMapDD" )
	end
	
	for i,v in ipairs(gMapFilesDD) do
		if fileExists(":vitaMapDD/"..tostring(v)) then
			fileDelete (":vitaMapDD/"..tostring(v))
		end
	end
	gMapFilesDD = {}
	
	fileDelete ( ":vitaMapDD/meta.xml" )
	local mapXML = xmlCreateFile ( ":vitaMapDD/meta.xml" ,"meta" )                                   
	local mapNode = xmlCreateChild(mapXML, "info")
	xmlNodeSetAttribute(mapNode, "description", "Vita Maploader")
	xmlNodeSetAttribute(mapNode, "type", "script")
	
	--mapNode = xmlCreateChild(mapXML, "file")
	--xmlNodeSetAttribute(mapNode, "src", "meta2.xml")
	
	mapNode = xmlCreateChild(mapXML, "script")
	xmlNodeSetAttribute(mapNode, "src", "vitaMap.lua")
	xmlNodeSetAttribute(mapNode, "type", "client")

	mapNode = xmlCreateChild(mapXML, "script")
	xmlNodeSetAttribute(mapNode, "src", "vitaMapServer.lua")
	xmlNodeSetAttribute(mapNode, "type", "server")

	fileCopy ( "files/mapLoading/vitaMapDD.lua", ":vitaMapDD/vitaMap.lua", true )
	fileCopy ( "files/mapLoading/serverDD.lua", ":vitaMapDD/vitaMapServer.lua", true )

	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)
		
	mapXML = xmlCreateFile ( ":vitaMapDD/meta2.xml" ,"meta" )
	table.insert(gMapFilesDD, "meta2.xml")

	local metaXML = xmlLoadFile ( ":"..mapname.."/meta.xml" )
	if metaXML then
		local i = 0
		while true do 
			local xmlNode = xmlFindChild ( metaXML, "map", i)
			if not xmlNode then
				break
			else
				local copyFile = xmlNodeGetAttribute(xmlNode, "src")
				fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDD/"..copyFile, true )
				table.insert(gMapFilesDD, copyFile)
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
							
							local spawnID = #gSpawnPositionsDD+1
							gSpawnPositionsDD[spawnID] = {}
							gSpawnPositionsDD[spawnID].posX = posX
							gSpawnPositionsDD[spawnID].posY = posY
							gSpawnPositionsDD[spawnID].posZ = posZ
							gSpawnPositionsDD[spawnID].rotX = rotX
							gSpawnPositionsDD[spawnID].rotY = rotY
							gSpawnPositionsDD[spawnID].rotZ = rotZ
							gSpawnPositionsDD[spawnID].interior = interiorID
							gSpawnPositionsDD[spawnID].vehicle = modelID
							gSpawnPositionsDD[spawnID].used = false
						end
						i2 = i2+1
					end
					xmlUnloadFile(mapfile)
				end				
				i = i + 1
				
			end
		end
		
		if #gSpawnPositionsDD == 0 or #gSpawnPositionsDD == false then
			return loadMapDD("random")
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

				if metaLineExists == false and (xmlNodeGetAttribute(xmlNode, "type") == "client" or xmlNodeGetAttribute(xmlNode, "type") == "shared") then
					fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDD/"..copyFile, true )
					table.insert(gMapFilesDD, copyFile)
					mapNode = xmlCreateChild(mapXML, "file")
					xmlNodeSetAttribute(mapNode, "src", copyFile)
					xmlNodeSetAttribute(mapNode, "type", "client")
					xmlNodeSetAttribute(mapNode, "download", "false")	
					temporaryTable[#temporaryTable+1] = copyFile
				end

				if not metaLineExists and (xmlNodeGetAttribute(xmlNode, "type") == "server" or xmlNodeGetAttribute(xmlNode, "type") == "shared" or not xmlNodeGetAttribute(xmlNode, "type")) then
					fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDD/"..copyFile, true )
					table.insert(gMapFilesDD, copyFile)
					mapNode = xmlCreateChild(mapXML, "file")
					xmlNodeSetAttribute(mapNode, "src", copyFile)
					xmlNodeSetAttribute(mapNode, "type", "server")
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
						gMapMusicDD = true			
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaStream/dd.mp3", true )
					else				
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapDD/"..copyFile, true )
						table.insert(gMapFilesDD, copyFile)
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
				setElementData(gElementDD, "mapname", realMapname)
			else
				setElementData(gElementDD, "mapname", mapname)
			end
		else
			setElementData(gElementDD, "mapname", mapname)
		end
	end
	
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)

	local hFile = fileOpen(":vitaMapDD/meta2.xml")
	local buffer = ""
	if hFile then
		while not fileIsEOF(hFile) do
			buffer = buffer .."".. fileRead(hFile, 500)
		end
	end
	fileClose(hFile)
	gMetaDD = buffer

	databaseMapDD = DatabaseMap:new(mapname)
	timesPlayed = databaseMapDD.m_Timesplayed
	gRatingsDD = databaseMapDD.m_Ratings

	setElementData(gElementDD, "map", mapname)
	if mapname == getElementData(gElementDD, "nextmap") then
		setElementData(gElementDD, "nextmap", "random")
	end
	
	local duration = 10*60*1000
	setElementData(gElementDD, "duration", duration)
	
	--refreshResources ( false )
	startResource(getResourceFromName("vitaMapDD"))
	
	if gStartTimerDD == false or isTimer(gStartTimerDD) == false then
		gStartTimerDD = setTimer(startTimerDD, 5000, 6) -- 6 times = 30 seconds
	end
	
	gMapResourceNameDD = mapname
	
	setTimer(
		function()
			triggerEvent("serverStartScriptDD", root)
			for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
				setUpDDPlayer(v)
			end
		end
	, 500,1)
end

function unloadMapDD()
	local ddRes = getResourceFromName("vitaMapDD")
	if ddRes then
		stopResource(ddRes)
		--deleteResource(ddRes)
	end

	if isTimer(gStartTimerDD) then
		killTimer(gStartTimerDD)
		gStartTimerDD = false
	end

	if databaseMapDD then
		databaseMapDD.m_Ratings = gRatingsDD
		databaseMapDD.m_Timesplayed = databaseMapDD.m_Timesplayed + 1
		databaseMapDD:delete()
		databaseMapDD = false
	end

	gIsDDRunning = false
	--stopResource(getResourceFromName("vitaMapDD"))
	setElementData(gElementDD, "map", "none")
	setElementData(gElementDD, "mapname", "loading...")
	setElementData(gElementDD, "startTick", nil)
	gRankingboardPlayersDD = {}
	setElementData(gElementDD, "rankingboard", gRankingboardPlayersDD)
	
	if countdownTimerDD then
		if isTimer(countdownTimerDD) then
			killTimer(countdownTimerDD)
		end	
	end
	
	if gDDMapTimer then
		if isTimer(gDDMapTimer) then
			killTimer(gDDMapTimer)
		end
	end
	
	for i,v in pairs(getElementsByType("vehicle")) do 
		if getElementData(v, "isDDVeh") == true then
			if isElement(v) then
				destroyElement(v)
			end
		end
	end
	
	for i,player in pairs(getGamemodePlayers(gGamemodeDD)) do
		setElementData(player, "state", "dead")
		triggerClientEvent ( player, "stopMapDD", getRootElement() )
		callClientFunction(player, "hideHurry")
		triggerClientEvent ( player, "onMapSoundStop", player )
	end
end

function isMapRunningDD()
	if getElementData(gElementDD, "map") ~= "none" then return true end
	return false
end

function joinDD(player)
	--DISABLING MODE
	--if player then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is deactivated.") return false end
	
	if getPlayerGameMode(player) == gGamemodeDD then return false end
	if #getGamemodePlayers(gGamemodeDD) >= gRaceModes[gGamemodeDD].maxplayers then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is currently full.") return false end
	
	local loadsNewMap = false
	if #getGamemodePlayers(gGamemodeDD) == 0 then
		loadsNewMap = true
		setElementData(gElementDD, "map", "none")
		setElementData(gElementDD, "mapname", "loading...")
		setElementData(gElementDD, "nextmap", "random")
		loadMapDD(getElementData(gElementDD, "nextmap"), true)
	elseif #getGamemodePlayers(gGamemodeDD) == 1 and  gIsDDRunning == true and gHasEndedDD == false then
		endMapDD()
	end
	setElementData(player, "gameMode", gGamemodeDD)
	setElementData(player, "mapname", getElementData(gElementDD, "mapname"))
	setElementData(player, "nextmap", getElementData(gElementDD, "nextmap"))
	setElementData(player, "winningCounter", 0)
	setElementData(player, "AFK", false)
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeDD)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, true )
			setElementVisibleTo ( gPlayerBlips[v], player, true )
		end
	end	
	
	setElementDimension(player, gGamemodeDD)
	triggerClientEvent ( player, "addNotification", getRootElement(), 2, 15,150,190, "You joined 'Destruction Derby'." )
	triggerClientEvent ( player, "hideSelection", getRootElement() )
	outputChatBoxToGamemode ( "#CCFF66:JOIN: #FFFFFF"..getPlayerName(player).."#FFFFFF has joined the gamemode.", gGamemodeDD, 255, 255, 255, true )
	
	callClientFunction(player, "showGUIComponents", "nextMap", "mapdisplay", "money")
	
	setElementData(player, "state", "joined")
	toggleControl ( player, "enter_exit", false )
	
	if loadsNewMap == false then
		setUpDDPlayer(player)
	end
	
	bindKey(player, "F", "down", playerKillFuncDD)
	bindKey(player, "enter", "down", playerKillFuncDD)
	
	if gIsDDRunning == true then
		playerWaitRoundDD(player)
	end
end
addEvent("joinDD", true)
addEventHandler("joinDD", getRootElement(), joinDD)

function quitDD(player)
	if getPlayerGameMode(player) ~= gGamemodeDD then return false end
		
	if bettedPlayer[player] then bettedPlayer[player] = false end
	killDDPlayer(player, true)

	if textDisplayIsObserver(gTextdisplayDD, player) then
		textDisplayRemoveObserver(gTextdisplayDD, player)
	end	
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeDD)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, false )
			setElementVisibleTo ( gPlayerBlips[v], player, false )
		end
	end	
	
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
	outputChatBoxToGamemode ( "#FF6666:QUIT: #FFFFFF"..getPlayerName(player).."#FFFFFF has left the gamemode.", gGamemodeDD, 255, 255, 255, true )
	
	triggerClientEvent ( player, "stopMapDD", getRootElement() )
	triggerClientEvent ( player, "onMapSoundStop", getRootElement() )

		if #getGamemodePlayers(gGamemodeDD) == 1 then
		for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
			triggerClientEvent(v, "foreveraloneClient",getRootElement())
			addPlayerArchivement(v, 64)
		end
	end
	
	if #getGamemodePlayers(gGamemodeDD) == 0 then
		unloadMapDD()
	end
end
addEvent("quitDD", true)
addEventHandler("quitDD", getRootElement(), quitDD)

function downloadMapFinishedDD(player)
	local mapRating = {likes = 0, dislikes = 0}
	for _, PlayerRate in pairs(gRatingsDD) do
		mapRating.likes = mapRating.likes + PlayerRate.Rating
	end
	mapRating.dislikes = #gRatingsDD - mapRating.likes

	callClientFunction(player, "forceMapRating", getElementData(gElementDD, "mapname"), mapRating, timesPlayed)
	callClientFunction(player, "allowNewHurryFunc")
	callClientFunction(player, "showGUIComponents", "timeleft", "timepassed")
	
	if timesPlayed == 0 then addPlayerArchivement(player, 53) end

	if not gIsDDRunning then
		setElementData(player, "state", "ready")
		return
	end

	local startTick = getElementData(gElementDD, "startTick")
	if getTickCount() - startTick < MAX_PLAYER_WAITING then
		local playerVehicle = getPlayerRaceVeh(player)
		if isElement(playerVehicle) then
			setElementData(player, "state", "alive")
			setVehicleDamageProof(playerVehicle, false)
			setElementFrozen(playerVehicle, false)
		end
	end
end
addEvent( "downloadMapFinishedDD", true)
addEventHandler ( "downloadMapFinishedDD", getRootElement(), downloadMapFinishedDD )

function playerWaitRoundDD(player)
	setElementData(player, "state", "dead")
	setElementAlpha(player, 0)
	setElementFrozen(player, true)
	local timerLeft
	if gDDMapTimer then
		timerLeft, _, _ = getTimerDetails(gDDMapTimer)
		if timerLeft == false or timerLeft == nil then
			timerLeft = getElementData(gElementDD, "duration")
		end
	end
	triggerClientEvent ( player, "addNotification", getRootElement(), 1, 150,12,33, "Wait for the next round to play." )
	callClientFunction ( player, "spectateStart" )
	callClientFunction ( player, "setStartTickLater", timerLeft)
end

function playerKillFuncDD(player)
	if isInGamemode(player, gGamemodeDD) == false then return end
	if gIsDDRunning ~= true then return end
	if isPlayerAlive(player) and gIsDDRunning == true then
		killDDPlayer(player)
	end
end

function killDDPlayer(player, noSpectate)
	if isInGamemode(player, gGamemodeDD) == false then return end
	local hasBeenAlive = false

	local gamemodePlayers = getGamemodePlayers(gGamemodeDD)
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if (getElementData(pvpElement, "player1") == player or getElementData(pvpElement, "player2") == player) and getElementData(pvpElement, "accepted") == true then 
			local player1 = getElementData(pvpElement, "player1")
			local player2 = getElementData(pvpElement, "player2")
			if player1 == player then
				addPlayerArchivement( player2, 44 )
				outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player2).." has won a PVP war against "..getPlayerName(player1).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeDD,255,0,0, true)
				setPlayerMoney(player2, getPlayerMoney(player2)+getElementData(pvpElement, "money")*2)
			elseif player2 == player then
				addPlayerArchivement( player1, 44 )
				outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player1).." has won a PVP war against "..getPlayerName(player2).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeDD,255,0,0, true)
				setPlayerMoney(player1, getPlayerMoney(player1)+getElementData(pvpElement, "money")*2)
			end
			destroyElement(pvpElement)
			break
		end                                                             
	end
	if (#getAliveGamemodePlayers(gGamemodeDD) ~= 1 and #getAliveGamemodePlayers(gGamemodeDD) ~= 0) and getElementData(player, "AFK") == false and gIsDDRunning == true and getElementData(player, "state") == "alive" then
		local onlinePlayers = 0
		local players = getGamemodePlayers(gGamemodeDD)
		for theKey,thePlayer in pairs(players) do
			onlinePlayers = onlinePlayers + 1
		end
		local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeDD)-#getAliveGamemodePlayers(gGamemodeDD)+1))
		local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeDD)-#getAliveGamemodePlayers(gGamemodeDD)+1))
		if getElementData(player, "isDonator") == true then endMoney = endMoney*2 end
		--if g_eventInProgress == 1 or g_eventInProgress == 2 or g_eventInProgress == 3 then
		--	endPoints = endPoints*2
		--end
		setElementData(player, "DDMaps", getElementData(player, "DDMaps")+1)
		setElementData(player, "winningCounter", 0)
		outputChatBox("#996633:Points: #ffffff You received "..tostring(endPoints).." points and "..tostring(endMoney).." Vero for playing this map.", player, 255, 255, 255, true)
		setElementData(player, "Points", getElementData(player, "Points") + endPoints)
		setElementData(player, "Money", getElementData(player, "Money") + endMoney)
		--if isTimer ( WinTimer ) then
		--	killTimer ( WinTimer )
		--end	
	end	
	
	if getElementData(player, "state") == "alive" then
		if #gRankingboardPlayersDD == 0 then
			for i,v in pairs(getAliveGamemodePlayers(gGamemodeDD)) do
				gRankingboardPlayersDD[i] = ""
			end		
		end	
		for i = #gRankingboardPlayersDD, 1, -1 do
			if gRankingboardPlayersDD[i] == "" then
				gRankingboardPlayersDD[i] = {}
				gRankingboardPlayersDD[i].text = _getPlayerName(player).."#FFFFFF: "..msToTimeStr(getTickCount()-getElementData(gElementDD, "startTick"))
				gRankingboardPlayersDD[i].ply = player
				setElementData(player, "state", "dead")
				hasBeenAlive = true
				callClientFunction(player, "setPassedTime", msToTimeStr(getTickCount()-getElementData(gElementDD, "startTick")))
				for i,v in pairs(gamemodePlayers) do
					playSoundFrontEnd(v, 7)
				end
				
				if getElementData(player, "lastCol") and isElement(getElementData(player, "lastCol")) then
					setElementData(getElementData(player, "lastCol"), "ddkills", getElementData(getElementData(player, "lastCol"), "ddkills")+1)
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
		setElementData(gElementDD, "rankingboard", gRankingboardPlayersDD)
	end
		
	if tonumber(getElementData(gElementDD, "startTick")) then
		if getTickCount() - getElementData(gElementDD, "startTick") <= 300 and getElementData(player, "AFK") == false then
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

	if #getGamemodePlayers(gGamemodeDD) == 1 and noSpectate == true then
		return true
	end
	
	if gIsDDRunning == false then return true end
	
	local alivePlayers = getAliveGamemodePlayers(gGamemodeDD)
	
	if hasBeenAlive == false then return end
	if (#alivePlayers == 1) and gIsDDRunning == true then

		if getElementData(alivePlayers[1], "AFK") == false then
			local onlinePlayers = 0
			local players = getGamemodePlayers(gGamemodeDD)
			local isAllAKF = true
			for theKey,thePlayer in pairs(players) do
				onlinePlayers = onlinePlayers + 1
				if thePlayer ~= alivePlayers[1] and getElementData(thePlayer, "AFK") == false then
					isAllAFK = false
				end
			end
			local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeDD)-#getAliveGamemodePlayers(gGamemodeDD)+1))
			local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeDD)-#getAliveGamemodePlayers(gGamemodeDD)+1))
					
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
			addPlayerArchivement( alivePlayers[1], 50 )
			setElementData(alivePlayers[1], "DDWon", getElementData(alivePlayers[1], "DDWon")+1)
			setElementData(alivePlayers[1], "DDMaps", getElementData(alivePlayers[1], "DDMaps")+1)
			if getElementData(alivePlayers[1], "DDWon") >= 100 then
				addPlayerArchivement( alivePlayers[1], 20 )
			end
			if getElementData(alivePlayers[1], "DDWon") >= 1000 then
				addPlayerArchivement( alivePlayers[1], 22 )
			end

			if getElementHealth ( getPedOccupiedVehicle(alivePlayers[1]) ) <= 250 then
				addPlayerArchivement( alivePlayers[1], 52 )
			end	
		
			for i = #gRankingboardPlayersDD, 1, -1 do
				if gRankingboardPlayersDD[i] == "" then
					gRankingboardPlayersDD[i] = {}
					gRankingboardPlayersDD[i].text = _getPlayerName(alivePlayers[1]).."#FFFFFF: WINNER"
					gRankingboardPlayersDD[i].ply = alivePlayers[1]
					for i,v in pairs(gamemodePlayers) do
						playSoundFrontEnd(v, 7)
					end			
					break
				end
			end
			setElementData(gElementDD, "rankingboard", gRankingboardPlayersDD)
			
			local newWinningCounter = getElementData(alivePlayers[1], "winningCounter")+1
			setElementData(alivePlayers[1], "winningCounter", newWinningCounter)
			if newWinningCounter > getElementData(alivePlayers[1], "WinningStreak") then
				setElementData(alivePlayers[1], "WinningStreak", newWinningCounter)
			end
		end
		
		local ran_win_mesage = {
			[1] = "He won "..tostring(getElementData(alivePlayers[1], "DDWon")).." DD maps",
			[2] = "He drove "..tostring(math.floor(getElementData(alivePlayers[1], "KM"))).." KM in this server!",
			[3] = "He did "..tostring(getElementData(alivePlayers[1], "TopTimes")).." huntertoptimes!",
			[4] = "He is Level "..tostring(getElementData(alivePlayers[1], "Rank")).."!",
			[5] = "He got "..tostring(getElementData(alivePlayers[1], "Money")).." Vero",
			[6] = "He played "..tostring(getElementData(alivePlayers[1], "DDMaps")).." DD maps!",
			[7] = "He got "..tostring(getElementData(alivePlayers[1], "Points")).." points!",
			[8] = "His winning streak is x"..tostring(getElementData(alivePlayers[1], "winningCounter")).."!",
			[9] = "He has been already for "..tostring(math.floor(getElementData(alivePlayers[1], "TimeOnServer")/60)).." minutes on the Server!"
		}
		local hasCustomText = false

		local winsound = getElementData(alivePlayers[1], "useWinsound")
		if winsound ~= 0 then
			for theKey, thePlayer in ipairs(getGamemodePlayers(gGamemodeDD)) do
				if getElementData(thePlayer, "toggleWinsounds") == 1 then
					thePlayer:triggerEvent("playWinsound", winsound)
				end
			end
		end

		if getElementData(alivePlayers[1], "isDonator") == true then
			if getElementData(alivePlayers[1], "customWintext") ~= "none" then
				showWinMessage(gGamemodeDD, "#FFFFFF"..tostring(getElementData(alivePlayers[1], "customWintext")), "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
				hasCustomText = true
			end
		end
		
		if hasCustomText == false then
			showWinMessage(gGamemodeDD, "#FFFFFF".._getPlayerName(alivePlayers[1]) .. '#FFFFFF has won the map!', "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
		end
	end
		
	if (#alivePlayers == 0 or (#alivePlayers == 1 --[[and getElementData(alivePlayers[1], "isDonator") ~= true]])) and gIsDDRunning == true and gHasEndedDD == false then
		endMapDD()
	end
end
	
function endMapDD()
	if gHasEndedDD == true then return false end
	gIsDDRunning = false
	gHasEndedDD = true
	textItemSetText(gTextdisplayTextDD, "changing map in 5")
	for i,v in pairs(getElementsByType("player")) do
		if getPlayerGameMode(v) == gGamemodeDD then
			textDisplayAddObserver(gTextdisplayDD, v)	
			callClientFunction(v, "hideHurry")
		else
			if textDisplayIsObserver(gTextdisplayDD, v) then
				textDisplayRemoveObserver(gTextdisplayDD, v)
			end				
		end
	end
	                                              
	setTimer(function()
		textItemSetText(gTextdisplayTextDD, "changing map in 4")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDD then
				textDisplayAddObserver(gTextdisplayDD, v)		
			else
				if textDisplayIsObserver(gTextdisplayDD, v) then
					textDisplayRemoveObserver(gTextdisplayDD, v)
				end				
			end
		end
	end, 1000, 1)
	setTimer(function()
		textItemSetText(gTextdisplayTextDD, "changing map in 3")                                                                                                                 
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDD then
				textDisplayAddObserver(gTextdisplayDD, v)		
			else
				if textDisplayIsObserver(gTextdisplayDD, v) then
					textDisplayRemoveObserver(gTextdisplayDD, v)
				end				
			end

		end
	end, 2000, 1)		
	setTimer(function()
		textItemSetText(gTextdisplayTextDD, "changing map in 2")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDD then
				textDisplayAddObserver(gTextdisplayDD, v)		
			else
				if textDisplayIsObserver(gTextdisplayDD, v) then
					textDisplayRemoveObserver(gTextdisplayDD, v)
				end				
			end

		end
	end, 3000, 1)	
	setTimer(function()
		textItemSetText(gTextdisplayTextDD, "changing map in 1")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeDD then
				textDisplayAddObserver(gTextdisplayDD, v)		
			else
				if textDisplayIsObserver(gTextdisplayDD, v) then
					textDisplayRemoveObserver(gTextdisplayDD, v)
				end				
			end

		end
	end, 4000, 1)		
	setTimer(function()       
		unloadMapDD()
		for i,v in pairs(getElementsByType("player")) do
			textDisplayRemoveObserver(gTextdisplayDD, v)
		end
		setTimer(function()
			loadMapDD(getElementData(gElementDD, "nextmap"))
		end, 1000, 1)
	end, 5000, 1)
end
 
function setUpDDPlayer(player)
	callClientFunction ( player, "spectateEnd" )
	
	setElementData(player, "loadMapDD", false)
	triggerLatentClientEvent ( player, "loadMapDD", 50000, false,  getRootElement(), gMetaDD )
	RankManager:getSingleton():updateAndNotify()
	if gMapMusicDD == true then
		--triggerClientEvent ( player, "onMapSoundReceive", player,"http://5.230.227.95:22005/vitaStream/dd.mp3")
	end
	
	if gIsDDRunning ~= false then return end
	
	setElementData(player, "state", "not ready")
	setElementData(player, "lastCol", false)
	for spawn,v in ipairs(gSpawnPositionsDD) do
		if gSpawnPositionsDD[spawn].used == false then
			setCameraTarget ( player )
			spawnPlayer(player, gSpawnPositionsDD[spawn].posX, gSpawnPositionsDD[spawn].posY, gSpawnPositionsDD[spawn].posZ)
			setElementDimension(player, gGamemodeDD)
			local veh = createVehicle(gSpawnPositionsDD[spawn].vehicle, gSpawnPositionsDD[spawn].posX, gSpawnPositionsDD[spawn].posY, gSpawnPositionsDD[spawn].posZ, gSpawnPositionsDD[spawn].rotX, gSpawnPositionsDD[spawn].rotY, gSpawnPositionsDD[spawn].rotZ, "Vita")
			setElementDimension(veh, gGamemodeDD)
			setElementFrozen(veh, true)
			warpPedIntoVehicle(player, veh)
			setVehicleDamageProof ( veh, true )
			gSpawnPositionsDD[spawn].used = true
			setElementData(veh, "isDDVeh", true)
			setElementData(player, "raceVeh", veh)
			setElementAlpha(player, 255)
			setElementFrozen(player, false)			
			setElementData(player, "mapname", getElementData(gElementDD, "mapname"))
			setElementData(player, "nextmap", getElementData(gElementDD, "nextmap"))		
			break
		else
			if gSpawnPositionsDD[spawn+1] == nil then
				spawn = 1
				setCameraTarget ( player )
				spawnPlayer(player, gSpawnPositionsDD[spawn].posX, gSpawnPositionsDD[spawn].posY, gSpawnPositionsDD[spawn].posZ)
				setElementDimension(player, gGamemodeDD)
				local veh = createVehicle(gSpawnPositionsDD[spawn].vehicle, gSpawnPositionsDD[spawn].posX, gSpawnPositionsDD[spawn].posY, gSpawnPositionsDD[spawn].posZ, gSpawnPositionsDD[spawn].rotX, gSpawnPositionsDD[spawn].rotY, gSpawnPositionsDD[spawn].rotZ, "Vita")
				setElementDimension(veh, gGamemodeDD)
				setElementFrozen(veh, true)
				warpPedIntoVehicle(player, veh)
				setVehicleDamageProof ( veh, true )
				gSpawnPositionsDD[spawn].used = true
				setElementData(veh, "isDDVeh", true)
				setElementData(player, "raceVeh", veh)
				setElementAlpha(player, 255)
				setElementFrozen(player, false)			
				setElementData(player, "mapname", getElementData(gElementDD, "mapname"))
				setElementData(player, "nextmap", getElementData(gElementDD, "nextmap"))						
				break
			end
		end
	end
end

function countdownFuncDD(id)
	for i,v in pairs(getGamemodePlayers(gGamemodeDD)) do
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
								killDDPlayer(player)
							end
						end, MAX_PLAYER_WAITING, 1, v)
				end
			end			
		end
	end
	
	if id == 4 then
		betReadyDD = setTimer ( function() setElementData(gElementDD, "betAvailable", false) end, 20000, 1 )
		countdownTimerDD = setTimer(countdownFuncDD, 3000, 1, 3)
	elseif id == 3 then
		countdownTimerDD = setTimer(countdownFuncDD, 1000, 1, 2)
	elseif id == 2 then
		countdownTimerDD = setTimer(countdownFuncDD, 1000, 1, 1)
	elseif id == 1 then
		countdownTimerDD = setTimer(countdownFuncDD, 1000, 1, 0)
	elseif id == 0 then
		triggerEvent("onRaceStateChanging", root, "Running")
		if #getAliveGamemodePlayers(gGamemodeDD) == 0 or #getAliveGamemodePlayers(gGamemodeDD) == false then --No players were able to be ready? Lets try the next map...
			loadMapDD(getElementData(gElementDD, "nextmap"))
			return
		end	
		gIsDDRunning = true
		countdownTimerDD = false
		gDDMapTimer = setTimer(endMapDD, getElementData(gElementDD, "duration"), 1)
		setElementData(gElementDD, "startTick", getTickCount())
		gRankingboardPlayersDD = {}
		setElementData(gElementDD, "rankingboard", gRankingboardPlayersDD)
	end
end

function onPlayerWastedDD()
	if isInGamemode(source, gGamemodeDD) then
		killDDPlayer(source)
	end
end
addEventHandler ( "onPlayerWasted", getRootElement(), onPlayerWastedDD )
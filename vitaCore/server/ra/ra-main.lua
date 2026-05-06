--[[
Project: vitaCore
File: dd-main.lua
Author(s):	Sebihunter
]]--


gGamemodeRA = 3
gElementRA = createElement("elementRA")
gIsRARunning = false
gHasEndedRA = false
gRAMapTimer = false
gMetaRA = false
gToptimesRA = {}
countdownTimerRA = false
gRedoCounterRA = 0
gCheckpointsRA = {}
gTimesPlayedRA = 0
gRatingsRA = {}
gMapFilesRA = {}
gMapMusicRA = false

gMapResourceNameRA = "none"


local respawnTimer = {}

gSpawnPositionsRA = {}
gRankingboardPlayersRA = {}
setElementData(gElementRA, "rankingboard", gRankingboardPlayersRA)

gTextdisplayRA = textCreateDisplay()
gTextdisplayTextRA = textCreateTextItem ( "Testthingy", 0.5, 0.8, "low", 255, 255, 255, 255, 2.0, "center", "top", 255 )
textDisplayAddText ( gTextdisplayRA, gTextdisplayTextRA )

function startTimerRA()
	if gIsRARunning ~= false then return end
	local maxPlayers = #getGamemodePlayers(gGamemodeRA)
	local readyPlayers = 0
	for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
		if getElementData(v, "state") == "ready" then
			readyPlayers = readyPlayers + 1
		end
	end
	
	if isTimer(gStartTimerRA) then
		local ttime, left, will = getTimerDetails ( gStartTimerRA )
		if left == 3 then
			textItemSetText(gTextdisplayTextRA, "waiting for players...")
			for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
				textDisplayAddObserver(gTextdisplayRA, v)
			end
		elseif left == 1 then
			countdownFuncRA(4)
			killTimer(gStartTimerRA)
			for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
				textDisplayRemoveObserver(gTextdisplayRA, v)
			end			
		end
	end
	
	if readyPlayers/maxPlayers > 0.8 then
		if isTimer(gStartTimerRA) then killTimer(gStartTimerRA) end
		countdownFuncRA(4)
		gStartTimerRA = false
		for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
			textDisplayRemoveObserver(gTextdisplayRA, v)
		end			
	end
end
gStartTimerRA = false

function loadMapRA(mapname, force)
	if not force then force = false end
	if isMapRunningRA() or gIsRARunning == true then unloadMapRA() end
	if #getGamemodePlayers(gGamemodeRA) == 0 and force == false then return unloadMapRA() end	
	
	if mapname == "random" then 
		mapname = getRandomMap(gGamemodeRA)
		if mapname == "failed" then
			loadMapRA("random")
			return false
		end
	end
	outputServerLog("loadMapRA: "..tostring(mapname))
	
	if gRedoCounterRA - 1 > 0 then
		gRedoCounterRA = gRedoCounterRA - 1
	else
		gRedoCounterRA = 0
	end	
	
	gMapMusicRA = false
	gHasEndedRA = false
	
	if betReadyRA and isTimer(betReadyRA) then killTimer(betReadyRA) end
	
	gRARespawns = {}
	gSpawnPositionsRA = {}
	setElementData(gElementRA, "betAvailable", true)
	local pvpElements = getElementsByType ( "pvpElement" )
	for theKey,pvpElement in ipairs(pvpElements) do
		if getElementData(pvpElement, "gameMode") == gGamemodeRA then
			destroyElement(pvpElement)
		end
	end		
	
	local resource = getResourceFromName ( mapname )
	
	--stopResource(getResourceFromName ( "vitaMapRA" ))
	--deleteResource ( "vitaMapRA")
	--refreshResources ( false )
	if not getResourceFromName ( "vitaMapRA" ) then
		createResource ( "vitaMapRA" )
	end
	
	for i,v in ipairs(gMapFilesRA) do
		fileDelete ( ":vitaMapRA/"..tostring(v) )
	end
	gMapFilesRA = {}
	
	fileDelete ( ":vitaMapRA/meta.xml" )
	local mapXML = xmlCreateFile ( ":vitaMapRA/meta.xml" ,"meta" )                                   
	local mapNode = xmlCreateChild(mapXML, "info")
	xmlNodeSetAttribute(mapNode, "description", "Vita Maploader")
	xmlNodeSetAttribute(mapNode, "type", "script")
	
	--mapNode = xmlCreateChild(mapXML, "file")
	--xmlNodeSetAttribute(mapNode, "src", "meta2.xml")
	
	mapNode = xmlCreateChild(mapXML, "script")
	xmlNodeSetAttribute(mapNode, "src", "vitaMap.lua")
	xmlNodeSetAttribute(mapNode, "type", "client")	
	fileCopy ( "files/mapLoading/vitaMapRA.lua", ":vitaMapRA/vitaMap.lua", true )
	
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)

	mapXML = xmlCreateFile ( ":vitaMapRA/meta2.xml" ,"meta" )
	table.insert(gMapFilesRA, "meta2.xml")

	local metaXML = xmlLoadFile ( ":"..mapname.."/meta.xml" )
	if metaXML then
		local i = 0
		while true do 
			local xmlNode = xmlFindChild ( metaXML, "map", i)
			if not xmlNode then
				break
			else
				local copyFile = xmlNodeGetAttribute(xmlNode, "src")
				fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapRA/"..copyFile, true )
				table.insert(gMapFilesRA, copyFile)
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
							
							local spawnID = #gSpawnPositionsRA+1
							gSpawnPositionsRA[spawnID] = {}
							gSpawnPositionsRA[spawnID].posX = posX
							gSpawnPositionsRA[spawnID].posY = posY
							gSpawnPositionsRA[spawnID].posZ = posZ
							gSpawnPositionsRA[spawnID].rotX = rotX
							gSpawnPositionsRA[spawnID].rotY = rotY
							gSpawnPositionsRA[spawnID].rotZ = rotZ
							gSpawnPositionsRA[spawnID].interior = interiorID
							gSpawnPositionsRA[spawnID].vehicle = modelID
							gSpawnPositionsRA[spawnID].used = false
						end
						i2 = i2+1
					end
							
					gCheckpointsRA = {}
					i2 = 0
					while true do
						local mapfilenode = xmlFindChild ( mapfile, "checkpoint", i2)
						if not mapfilenode then
							break
						else
							local posX = tonumber(xmlNodeGetAttribute(mapfilenode, "posX"))
							local posY = tonumber(xmlNodeGetAttribute(mapfilenode, "posY"))
							local posZ = tonumber(xmlNodeGetAttribute(mapfilenode, "posZ"))
							local size = tonumber(xmlNodeGetAttribute(mapfilenode, "size"))
							local ctype = xmlNodeGetAttribute(mapfilenode, "type")
							local color = xmlNodeGetAttribute(mapfilenode, "color")
							local veh = xmlNodeGetAttribute(mapfilenode, "vehicle")
							local paintjob = xmlNodeGetAttribute(mapfilenode, "paintjob")
							local upgrades = xmlNodeGetAttribute(mapfilenode, "upgrades")
							--local id = tonumber(xmlNodeGetAttribute(mapfilenode, "id"):sub(0, 10))
							
							if not ctype then ctype = "checkpoint" end
							
							local spawnID = #gCheckpointsRA+1
							local r = 0
							local g = 0
							local b = 255							
							local a = 255
							if color then
								r,g,b,a = getColorFromString ( color )
							end
							if not size then size = 4 end
							gCheckpointsRA[spawnID] = createMarker ( posX, posY, posZ, ctype, size, r,g,b,a, getRootElement() )
							setElementDimension(gCheckpointsRA[spawnID], gGamemodeRA)
							setElementData(gCheckpointsRA[spawnID], "spawnID", spawnID)
							setElementData(gCheckpointsRA[spawnID], "playerTable", {})
							if veh then setElementData(gCheckpointsRA[spawnID], "veh", tonumber(veh)) end
							if paintjob then setElementData(gCheckpointsRA[spawnID], "paintjob", tonumber(paintjob)) end
							if upgrades then
								local upgradeTable = split ( upgrades, "," )
								setElementData(gCheckpointsRA[spawnID], "upgrades", upgradeTable)
							end
							
							local blip = createBlip ( posX, posY, posZ, 0, 2, r,g,b,a)
							setElementDimension(blip, gGamemodeRA)
							setElementData(gCheckpointsRA[spawnID], "blip", blip)
						
							local col 
							if not ctype or ctype == 'checkpoint' then
								col = createColCircle(posX, posY, size + 4)
							else
								col = createColSphere(posX, posY, posZ, size + 4)
							end
							setElementDimension(col, gGamemodeRA)
							setElementData(gCheckpointsRA[spawnID], "col", col)
							setElementData(col, "cp", gCheckpointsRA[spawnID])
							
							-- Show only the first 2 checkpoints
							setElementVisibleTo ( gCheckpointsRA[spawnID], getRootElement ( ), false )
							setElementVisibleTo ( getElementData(gCheckpointsRA[spawnID], "blip"), getRootElement ( ), false )
							
							addEventHandler("onColShapeHit", col, markerHitRA)
							
							if xmlFindChild ( mapfile, "checkpoint", i2+1) then
								setMarkerIcon ( gCheckpointsRA[spawnID], "arrow" )
							else
								setMarkerIcon ( gCheckpointsRA[spawnID], "finish" )
								setElementData ( gCheckpointsRA[spawnID], "isFinishMarker", true, false ) -- Workaround: Remove this, if getMarkerIcon was fixed
							end
							if isElement(gCheckpointsRA[spawnID-1]) then
								setMarkerTarget ( gCheckpointsRA[spawnID-1], posX, posY, posZ )
							end
						end
						i2 = i2+1
					end
					
					xmlUnloadFile(mapfile)
				end				
				i = i + 1
				
			end
		end
		setElementData(gElementRA, "allCP", #gCheckpointsRA)
		
		if #gSpawnPositionsRA == 0 or #gSpawnPositionsRA == false then
			return loadMapRA("random")
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
					fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapRA/"..copyFile, true )
					table.insert(gMapFilesRA, copyFile)
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
						gMapMusicRA = true				
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaStream/ra.mp3", true )
					else				
						fileCopy ( ":"..mapname.."/"..copyFile, ":vitaMapRA/"..copyFile, true )
						table.insert(gMapFilesRA, copyFile)
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
		
		local xmlInfo = xmlFindChild ( metaXML, "info", 0)
		if xmlInfo then 
			local realMapname = xmlNodeGetAttribute(xmlInfo, "name")
			if realMapname then
				setElementData(gElementRA, "mapname", realMapname)
			else
				setElementData(gElementRA, "mapname", mapname)
			end
		else
			setElementData(gElementRA, "mapname", mapname)
		end
	end
	
	xmlSaveFile(mapXML)
	xmlUnloadFile(mapXML)

	local hFile = fileOpen(":vitaMapRA/meta2.xml")
	local buffer = ""
	if hFile then
		while not fileIsEOF(hFile) do
			buffer = buffer .."".. fileRead(hFile, 500)
		end
	end
	fileClose(hFile)
	gMetaRA = buffer
	
	gToptimesRA = loadTopTimes(getElementData(gElementRA, "mapname"))
	gTimesPlayedRA, gRatingsRA = loadRatings(getElementData(gElementRA, "mapname"))
	
	setElementData(gElementRA, "map", mapname)
	if mapname == getElementData(gElementRA, "nextmap") then
		setElementData(gElementRA, "nextmap", "random")
	end
	
	local duration = 10*60*1000
	setElementData(gElementRA, "duration", duration)
	
	--refreshResources ( false )
	startResource(getResourceFromName("vitaMapRA"))
	
	if gStartTimerRA == false or isTimer(gStartTimerRA) == false then
		gStartTimerRA = setTimer(startTimerRA, 5000, 6) -- 6 times = 30 seconds
	end
	
	gMapResourceNameRA = mapname
	
	setTimer(function()
	for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
		setUpRAPlayer(v)
	end end, 500,1)
end

function unloadMapRA()
	if isTimer(gStartTimerRA) then
		killTimer(gStartTimerRA)
		gStartTimerRA = false
	end
	gIsRARunning = false
	gTimesPlayedRA = gTimesPlayedRA+1
	saveTopTimes(getElementData(gElementRA, "mapname"), gToptimesRA)
	saveRatings(getElementData(gElementRA, "mapname"), gTimesPlayedRA, gRatingsRA)
	
	for i,v in pairs(gCheckpointsRA) do 
		if isElement(v) then
			if isElement(getElementData(v, "blip")) then
				destroyElement(getElementData(v, "blip"))
			end
			if isElement(getElementData(v, "col")) then
				destroyElement(getElementData(v, "col"))
			end			
			destroyElement(v)
		end
	end
	
	--stopResource(getResourceFromName("vitaMapRA"))
	setElementData(gElementRA, "map", "none")
	setElementData(gElementRA, "mapname", "loading...")
	setElementData(gElementRA, "startTick", nil)
	gRankingboardPlayersRA = {}
	setElementData(gElementRA, "rankingboard", gRankingboardPlayersRA)
	
	if countdownTimerRA then
		if isTimer(countdownTimerRA) then
			killTimer(countdownTimerRA)
		end	
	end
	
	if gRAMapTimer then
		if isTimer(gRAMapTimer) then
			killTimer(gRAMapTimer)
		end
	end
	
	for i,v in pairs(getElementsByType("vehicle")) do 
		if getElementData(v, "isRAVeh") == true then
			if isElement(v) then
				destroyElement(v)
			end
		end
	end
	
	for i,player in pairs(getGamemodePlayers(gGamemodeRA)) do
		setElementData(player, "state", "dead")
		setElementData(player, "racePos", false)
		callClientFunction(player, "hideHurry")
		sendToptimes(player, false)
		callClientFunction ( player, "spectateEnd" )
		triggerClientEvent ( player, "stopMapRA", getRootElement() )
		triggerClientEvent ( player, "onMapSoundStop", player )
	end
end

function isMapRunningRA()
	if getElementData(gElementRA, "map") ~= "none" then return true end
	return false
end

function joinRA(player)
	--DISABLING MODE
	--if player then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is deactivated.") return false end
	
	if getPlayerGameMode(player) == gGamemodeRA then return false end
	if #getGamemodePlayers(gGamemodeRA) >= gRaceModes[gGamemodeRA].maxplayers then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "This gamemode is currently full.") return false end
	
	local loadsNewMap = false
	if #getGamemodePlayers(gGamemodeRA) == 0 then
		loadsNewMap = true
		setElementData(gElementRA, "map", "none")
		setElementData(gElementRA, "mapname", "loading...")
		setElementData(gElementRA, "nextmap", "random")
		loadMapRA(getElementData(gElementRA, "nextmap"), true)
	end
	sendToptimes(player, false)
	setElementData(player, "nextMarker", 0)
	setElementData(player, "currentCP", 0)
	setElementData(player, "gameMode", gGamemodeRA)
	setElementData(player, "mapname", getElementData(gElementRA, "mapname"))
	setElementData(player, "nextmap", getElementData(gElementRA, "nextmap"))
	setElementData(player, "infoText", false)
	setElementData(player, "+Text", false)
	setElementData(player, "-Text", false)
	setElementData(player, "ghostmod", true )
	setElementData(player, "winningCounter", 0)
	setElementData(player, "AFK", false)
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeRA)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, true )
			setElementVisibleTo ( gPlayerBlips[v], player, true )
		end
	end	
	
	setElementDimension(player, gGamemodeRA)
	triggerClientEvent ( player, "addNotification", getRootElement(), 2, 15,150,190, "You joined 'Race'." )
	triggerClientEvent ( player, "hideSelection", getRootElement() )
	outputChatBoxToGamemode ( "#CCFF66:JOIN: #FFFFFF"..getPlayerName(player).."#FFFFFF has joined the gamemode.", gGamemodeRA, 255, 255, 255, true )
	
	callClientFunction(player, "showGUIComponents", "nextMap", "mapdisplay", "money")
	
	setElementData(player, "state", "joined")
	toggleControl ( player, "enter_exit", false )
	
	if loadsNewMap == false then
		setUpRAPlayer(player)
		setElementData(player, "nextMarker", 0)
		setElementData(player, "currentCP", 0)
	end
	
	bindKey(player, "F", "down", playerKillFuncRA)
	bindKey(player, "enter", "down", playerKillFuncRA)
end
addEvent("joinRA", true)
addEventHandler("joinRA", getRootElement(), joinRA)

function quitRA(player)
	if getPlayerGameMode(player)  ~= gGamemodeRA then return false end
	
	if isTimer(getElementData(player, "loadMapRATimer")) then
		killTimer(getElementData(player, "loadMapRATimer"))
	end			
	killRAPlayer(player, true)

	if textDisplayIsObserver(gTextdisplayRA, player) then
		textDisplayRemoveObserver(gTextdisplayRA, player)
	end	
	
	for i,v in ipairs(getGamemodePlayers(gGamemodeRA)) do
		if v ~= player then
			setElementVisibleTo ( gPlayerBlips[player], v, false )
			setElementVisibleTo ( gPlayerBlips[v], player, false )
		end
	end	
	
	if bettedPlayer[player] then bettedPlayer[player] = false end
	if respawnTimer[player] and isTimer(respawnTimer[player]) then killTimer(respawnTimer[player]) end
	setElementData(player, "winline", nil)
	setElementData(player, "winline2", nil)
	setElementData(player, "winr", nil)
	setElementData(player, "wing", nil)
	setElementData(player, "winb", nil)
	setElementData(player, "nextMarker", 0)
	setElementData(player, "currentCP", 0)
	setElementData(player, "infoText", false)
	setElementData(player, "+Text", false)
	setElementData(player, "-Text", false)
	sendToptimes(player, false)
	setElementData(player, "ghostmod", false )
	
	setElementData(player, "gameMode", 0)
	spawnPlayer(player, 0,0,0)
	setElementDimension(player, 0)
	setElementInterior(player, 0)
	setElementFrozen(player, true)
	outputChatBoxToGamemode ( "#FF6666:QUIT: #FFFFFF"..getPlayerName(player).."#FFFFFF has left the gamemode.", gGamemodeRA, 255, 255, 255, true )
	
	triggerClientEvent ( player, "stopMapRA", getRootElement() )
	triggerClientEvent ( player, "onMapSoundStop", getRootElement() )
	
	if #getGamemodePlayers(gGamemodeRA) == 1 then
		for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
			triggerClientEvent(v, "foreveraloneClient",getRootElement())
			addPlayerArchivement(v, 64)
		end
	end	
	
	if #getGamemodePlayers(gGamemodeRA) == 0 then
		unloadMapRA()
	end
	
	if getElementData(player, "loadMapRA") == true then
		if isTimer(getElementData(player, "loadMapRATimer")) then
			killTimer(getElementData(player, "loadMapRATimer"))
		end
	end
end
addEvent("quitRA", true)
addEventHandler("quitRA", getRootElement(), quitRA)

function downloadMapFinishedRA(player)
	local localRatings = 0
	for i,v in ipairs(gRatingsRA) do
		local anus = split( v,":" )
		localRatings = localRatings + tonumber(anus[2])
	end
	if localRatings ~= 0 then
		localRatings = math.round(localRatings/#gRatingsRA, 1)
	else
		localRatings = false
	end
	callClientFunction(player, "forceMapRating", getElementData(gElementRA, "mapname"), localRatings, gTimesPlayedRA)
	sendToptimes(player, gToptimesRA)
	callClientFunction(player, "forceToptimesOpen")
	callClientFunction(player, "allowNewHurryFunc")

	if gTimesPlayedRA == 0 then addPlayerArchivement(player, 53) end
	
	if gIsRARunning == false then
		setElementData(player, "state", "ready")
		savePlayerPositionRA(player)
		if gCheckpointsRA[1] and isElement(gCheckpointsRA[1]) then setElementVisibleTo ( gCheckpointsRA[1], player, true) setElementVisibleTo ( getElementData(gCheckpointsRA[1], "blip"), player, true ) end
		if gCheckpointsRA[2] and isElement(gCheckpointsRA[2]) then setElementVisibleTo ( gCheckpointsRA[2], player, true) setElementVisibleTo ( getElementData(gCheckpointsRA[2], "blip"), player, true ) end
	else
		setCameraTarget ( player )
		savePlayerPositionRA(player)
		setElementData(player, "state", "alive")
		if gCheckpointsRA[1] then setElementVisibleTo ( gCheckpointsRA[1], player, true) setElementVisibleTo ( getElementData(gCheckpointsRA[1], "blip"), player, true ) end
		if gCheckpointsRA[2] then setElementVisibleTo ( gCheckpointsRA[2], player, true) setElementVisibleTo ( getElementData(gCheckpointsRA[2], "blip"), player, true ) end
		
		local timerLeft
		if gRAMapTimer then
			timerLeft, _, _ = getTimerDetails(gRAMapTimer)
			if timerLeft == false or timerLeft == nil then
				timerLeft = getElementData(gElementRA, "duration")
			end
		end		
		callClientFunction ( player, "setStartTickLater", timerLeft)
		
		setElementData(player, "nextMarker", 1)
		setElementData(player, "currentCP", 0)
		setElementFrozen(getPlayerRaceVeh(player), false)
	end
	callClientFunction(player, "showGUIComponents", "timeleft", "timepassed")
end
addEvent( "downloadMapFinishedRA", true)
addEventHandler ( "downloadMapFinishedRA", getRootElement(), downloadMapFinishedRA )

function playerKillFuncRA(player)
	if isInGamemode(player, gGamemodeRA) == false then return end
	if gIsRARunning ~= true then return end
	if isPlayerAlive(player) and gIsRARunning == true then
		killRAPlayer(player)
	end
end

function killRAPlayer(player, noSpectate)
	if isInGamemode(player, gGamemodeRA) == false then return end

	local gamemodePlayers = getGamemodePlayers(gGamemodeRA)
	
	
	if isElement(getPlayerRaceVeh(player)) then
		local model = getElementModel(getPlayerRaceVeh(player))
		local posX, posY, posZ = getElementPosition(getPlayerRaceVeh(player))
		local rotX, rotY, rotZ = getElementRotation(getPlayerRaceVeh(player))
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
	
	if tonumber(getElementData(gElementRA, "startTick")) then
		if getTickCount() - getElementData(gElementRA, "startTick") <= 300 and getElementData(player, "AFK") == false then
			addPlayerArchivement(player, 17)
		end		
	end
	
	if gHasEndedRA == false and getElementData(player, "state")  == "alive" then
		setElementData(player, "state", "dead")
		-- Respawn him
		local counter = 5
		setElementData(player, "infoText", "respawn in "..tostring(counter))
		
		if respawnTimer[player] and isTimer(respawnTimer[player]) then killTimer(respawnTimer[player]) end
		respawnTimer[player] = setTimer(function()
			counter = counter - 1
			if counter == 0 then
				respawnPlayerRA(player, false)
				setElementData(player, "infoText", false)
			else
				setElementData(player, "infoText", "respawn in "..tostring(counter))
			end
		end, 1000, counter)
	end
end
	
function endMapRA()
	if gHasEndedRA == true then return false end
	gIsRARunning = false
	gHasEndedRA = true
	textItemSetText(gTextdisplayTextRA, "changing map in 5")
	for i,v in pairs(getElementsByType("player")) do
		if respawnTimer[player] and isTimer(respawnTimer[player]) then killTimer(respawnTimer[player]) end
		if getPlayerGameMode(v) == gGamemodeRA then
			textDisplayAddObserver(gTextdisplayRA, v)	
			callClientFunction(v, "hideHurry")
			setElementData(v, "infoText", false)
			setElementData(v, "+Text", false)
			setElementData(v, "-Text", false)
		else
			if textDisplayIsObserver(gTextdisplayRA, v) then
				textDisplayRemoveObserver(gTextdisplayRA, v)
			end				
		end
	end
	                                              
	setTimer(function()
		textItemSetText(gTextdisplayTextRA, "changing map in 4")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeRA then
				textDisplayAddObserver(gTextdisplayRA, v)		
			else
				if textDisplayIsObserver(gTextdisplayRA, v) then
					textDisplayRemoveObserver(gTextdisplayRA, v)
				end				
			end
		end
	end, 1000, 1)
	setTimer(function()
		textItemSetText(gTextdisplayTextRA, "changing map in 3")                                                                                                                 
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeRA then
				textDisplayAddObserver(gTextdisplayRA, v)		
			else
				if textDisplayIsObserver(gTextdisplayRA, v) then
					textDisplayRemoveObserver(gTextdisplayRA, v)
				end				
			end

		end
	end, 2000, 1)		
	setTimer(function()
		textItemSetText(gTextdisplayTextRA, "changing map in 2")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeRA then
				textDisplayAddObserver(gTextdisplayRA, v)		
			else
				if textDisplayIsObserver(gTextdisplayRA, v) then
					textDisplayRemoveObserver(gTextdisplayRA, v)
				end				
			end

		end
	end, 3000, 1)	
	setTimer(function()
		textItemSetText(gTextdisplayTextRA, "changing map in 1")
		for i,v in pairs(getElementsByType("player")) do
			if getPlayerGameMode(v) == gGamemodeRA then
				textDisplayAddObserver(gTextdisplayRA, v)		
			else
				if textDisplayIsObserver(gTextdisplayRA, v) then
					textDisplayRemoveObserver(gTextdisplayRA, v)
				end				
			end

		end
	end, 4000, 1)		
	setTimer(function()       
		unloadMapRA()
		for i,v in pairs(getElementsByType("player")) do
			textDisplayRemoveObserver(gTextdisplayRA, v)
		end
		setTimer(function()
			loadMapRA(getElementData(gElementRA, "nextmap"))
		end, 1000, 1)
	end, 5000, 1)
end                    
 
function setUpRAPlayer(player)
	callClientFunction ( player, "spectateEnd" )
	
	setElementData(player, "loadMapRA", false)
	if gMapMusicRA == true then
		--triggerClientEvent ( player, "onMapSoundReceive", player,"http://5.230.227.95:22005/vitaStream/ra.mp3")
	end
	local timer = setTimer(function(player)
		if isElement(player) then
			triggerLatentClientEvent ( player, "loadMapRA", 50000, false,  getRootElement(), gMetaRA )
			RankManager:getSingleton():updateAndNotify()
			if getElementData(player, "loadMapRA") == true then
				if isTimer(getElementData(player, "loadMapRATimer")) then
					killTimer(getElementData(player, "loadMapRATimer"))
				end
			end
		end
	end, 100, 0, player)
	setElementData(player, "loadMapRATimer", timer)
	setElementData(player, "racePos", false)
	
	setElementData(player, "state", "not ready")
	for spawn,v in ipairs(gSpawnPositionsRA) do
		if gSpawnPositionsRA[spawn].used == false then
			setCameraTarget ( player )
			spawnPlayer(player, gSpawnPositionsRA[spawn].posX, gSpawnPositionsRA[spawn].posY, gSpawnPositionsRA[spawn].posZ)
			setElementDimension(player, gGamemodeRA)
			local veh = createVehicle(gSpawnPositionsRA[spawn].vehicle, gSpawnPositionsRA[spawn].posX, gSpawnPositionsRA[spawn].posY, gSpawnPositionsRA[spawn].posZ, gSpawnPositionsRA[spawn].rotX, gSpawnPositionsRA[spawn].rotY, gSpawnPositionsRA[spawn].rotZ, "Vita")
			setElementDimension(veh, gGamemodeRA)
			setElementFrozen(veh, true)
			warpPedIntoVehicle(player, veh)
			setVehicleDamageProof ( veh, true )
			gSpawnPositionsRA[spawn].used = true
			setElementData(veh, "isRAVeh", true)
			setElementData(player, "raceVeh", veh)
			setElementAlpha(player, 255)
			setElementFrozen(player, false)			
			setElementData(player, "mapname", getElementData(gElementRA, "mapname"))
			setElementData(player, "nextmap", getElementData(gElementRA, "nextmap"))				
			break
		else
			if gSpawnPositionsRA[spawn+1] == nil then
				spawn = 1
				setCameraTarget ( player )
				spawnPlayer(player, gSpawnPositionsRA[spawn].posX, gSpawnPositionsRA[spawn].posY, gSpawnPositionsRA[spawn].posZ)
				setElementDimension(player, gGamemodeRA)
				local veh = createVehicle(gSpawnPositionsRA[spawn].vehicle, gSpawnPositionsRA[spawn].posX, gSpawnPositionsRA[spawn].posY, gSpawnPositionsRA[spawn].posZ, gSpawnPositionsRA[spawn].rotX, gSpawnPositionsRA[spawn].rotY, gSpawnPositionsRA[spawn].rotZ, "Vita")
				setElementDimension(veh, gGamemodeRA)
				setElementFrozen(veh, true)
				warpPedIntoVehicle(player, veh)
				setVehicleDamageProof ( veh, true )
				gSpawnPositionsRA[spawn].used = true
				setElementData(veh, "isRAVeh", true)
				setElementData(player, "raceVeh", veh)
				setElementAlpha(player, 255)
				setElementFrozen(player, false)			
				setElementData(player, "mapname", getElementData(gElementRA, "mapname"))
				setElementData(player, "nextmap", getElementData(gElementRA, "nextmap"))				
				break
			end
		end
	end
end

function countdownFuncRA(id)
	for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
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
				setCameraTarget ( v, v )
				setElementData(v, "state", "alive")
				if isElement(getPlayerRaceVeh(v)) then
					setVehicleDamageProof ( getPlayerRaceVeh(v), false )
					setElementFrozen(getPlayerRaceVeh(v), false)
				end
				setElementData(v, "nextMarker", 1)
				setElementData(v, "currentCP", 0)
			end			
		end
	end
	
	if id == 4 then
		betReadyRA = setTimer ( function() setElementData(gElementRA, "betAvailable", false) end, 20000, 1 )
		countdownTimerRA = setTimer(countdownFuncRA, 3000, 1, 3)
	elseif id == 3 then
		countdownTimerRA = setTimer(countdownFuncRA, 1000, 1, 2)
	elseif id == 2 then
		countdownTimerRA = setTimer(countdownFuncRA, 1000, 1, 1)
	elseif id == 1 then
		countdownTimerRA = setTimer(countdownFuncRA, 1000, 1, 0)
	elseif id == 0 then
		if #getAliveGamemodePlayers(gGamemodeRA) == 0 or #getAliveGamemodePlayers(gGamemodeRA) == false then --No players were able to be ready? Lets try the next map...
			loadMapRA(getElementData(gElementRA, "nextmap"))		
			return
		end	
		gIsRARunning = true
		countdownTimerRA = false
		gRAMapTimer = setTimer(endMapRA, getElementData(gElementRA, "duration"), 1)
		setElementData(gElementRA, "startTick", getTickCount())
		gRankingboardPlayersRA = {}
		setElementData(gElementRA, "rankingboard", gRankingboardPlayersRA)
	end
end

function onPlayerWastedRA()
	if isInGamemode(source, gGamemodeRA) then
		killRAPlayer(source)
	end
end
addEventHandler ( "onPlayerWasted", getRootElement(), onPlayerWastedRA )

function markerHitRA(hitElement, matchingDimension)
	if getElementType(hitElement) ~= "vehicle" then return false end
	if not isElement(getVehicleOccupant(hitElement)) then return false end
	if not isElement(getElementData(source, "cp")) then return false end
	source = getElementData(source, "cp")
	hitElement = getVehicleOccupant(hitElement)
	
	if getElementType(hitElement) == "player" and matchingDimension then
		local spawnID = getElementData(source, "spawnID")
		if spawnID ~= getElementData(hitElement, "nextMarker") then return false end
		if getElementData(hitElement, "nextMarker") == getElementData(hitElement, "currentCP") then return false end
		setElementData(hitElement, "nextMarker", getElementData(hitElement, "nextMarker")+1)
		setElementData(hitElement, "currentCP", spawnID)
		
		if getElementData(source, "veh") then callClientFunction(hitElement, "changeVehicle", getPedOccupiedVehicle(hitElement), getElementData(source, "veh")) end
		if getElementData(source, "paintjob") then setVehiclePaintjob(getPedOccupiedVehicle(hitElement), getElementData(source, "paintjob")) end
		if getElementData(source, "upgrades") then 
			local upgrades = getElementData(source, "upgrades")
			for i,v in ipairs(upgrades) do
				addVehicleUpgrade ( getPedOccupiedVehicle(hitElement), v )
			end
		end
			
		if getMarkerIcon(source) == "finish" or getElementData(source, "isFinishMarker") then
			local racePassedTime = getTickCount()-getElementData(gElementRA, "startTick")
			--outputChatBox(("%s finished"):format(getPlayerName(hitElement))) -- Placeholder
			addPlayerArchivement(hitElement, 54)
			for i = 1, gRaceModes[gGamemodeRA].maxplayers, 1 do
				if not gRankingboardPlayersRA[i] then
					gRankingboardPlayersRA[i] = {}
					gRankingboardPlayersRA[i].text = _getPlayerName(hitElement).."#FFFFFF: "..msToTimeStr(racePassedTime)
					gRankingboardPlayersRA[i].ply = hitElement
					callClientFunction(hitElement, "setPassedTime", msToTimeStr(racePassedTime))
					for i,v in pairs(getGamemodePlayers(gGamemodeRA)) do
						playSoundFrontEnd(v, 7)
					end

					local onlinePlayers = 0
					local players = getGamemodePlayers(gGamemodeRA)
					for theKey,thePlayer in pairs(players) do
						onlinePlayers = onlinePlayers + 1
					end
					
					local endPoints = math.floor(8*(#getGamemodePlayers(gGamemodeRA)-i+1))
					local endMoney = math.floor(32*(#getGamemodePlayers(gGamemodeRA)-i+1))		
					if getElementData(hitElement, "isDonator") == true then endMoney = endMoney*2 end
						
					outputChatBox("#996633:Points: #ffffff You received "..tostring(endPoints).." points and "..tostring(endMoney).." Vero for finishing this map as number "..i.." of "..onlinePlayers..".", hitElement, 255, 255, 255, true)
					setElementData(hitElement, "Points", getElementData(hitElement, "Points")+ endPoints)
					setElementData(hitElement, "Money", getElementData(hitElement, "Money")+ endMoney)
					
					setElementData(hitElement, "RAMaps", getElementData(hitElement, "RAMaps")+1)
					setElementData(hitElement, "endPosRA", i)
						
					if i == 1 then
						addPlayerArchivement(hitElement, 55)
						if isTimer(gRAMapTimer) then
							local timerLeft, _, _ = getTimerDetails(gRAMapTimer)
							if timerLeft >= 60000 then
								local duration = getElementData(gElementRA, "duration")
								setElementData(gElementRA, "duration", 60000+duration-timerLeft)
								killTimer(gRAMapTimer)
								gRAMapTimer = setTimer(endMapRA, 60000, 1)
							end
						end
						
						setElementData(hitElement, "RAWon", getElementData(hitElement, "RAWon")+1)
						
						if getElementData(hitElement, "RAWon") >= 100 then
							addPlayerArchivement( hitElement, 56 )
						end
						if getElementData(hitElement, "RAWon") >= 1000 then
							addPlayerArchivement( hitElement, 57 )
						end						
									
						givePlayerBetWinning (hitElement)
						local pvpElements = getElementsByType ( "pvpElement" )
						for theKey,pvpElement in ipairs(pvpElements) do
							if (getElementData(pvpElement, "player1") == hitElement or getElementData(pvpElement, "player2") == hitElement) and getElementData(pvpElement, "accepted") == true then 
								local player1 = getElementData(pvpElement, "player1")
								local player2 = getElementData(pvpElement, "player2")
								if player2 == hitElement then
									addPlayerArchivement( player2, 44 )
									outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player2).." has won a PVP war against "..getPlayerName(player1).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeRA,255,0,0, true)
									setPlayerMoney(player2, getPlayerMoney(player2)+getElementData(pvpElement, "money")*2)
								elseif player1 == hitElement then
									addPlayerArchivement( player1, 44 )
									outputChatBoxToGamemode("#256484:PVP: #FFFFFF"..getPlayerName(player1).." has won a PVP war against "..getPlayerName(player2).." and receives "..tostring(getElementData(pvpElement, "money")).." Vero.",gGamemodeRA,255,0,0, true)
									setPlayerMoney(player1, getPlayerMoney(player1)+getElementData(pvpElement, "money")*2)
								end
								destroyElement(pvpElement)
								break
							end                                                             
						end
							
						local newWinningCounter = getElementData(alivePlayers[1], "winningCounter")+1
						setElementData(alivePlayers[1], "winningCounter", newWinningCounter)
						if newWinningCounter > getElementData(alivePlayers[1], "WinningStreak") then
							setElementData(alivePlayers[1], "WinningStreak", newWinningCounter)
						end

					local ran_win_mesage = {
							[1] = "He won "..tostring(getElementData(hitElement, "RAWon")).." RACE maps",
							[2] = "He drove "..tostring(math.floor(getElementData(hitElement, "KM"))).." KM in this server!",
							[3] = "He did "..tostring(getElementData(hitElement, "TopTimesRA")).." toptimes!",
							[4] = "He is Level "..tostring(getElementData(hitElement, "Rank")).."!",
							[5] = "He got "..tostring(getElementData(hitElement, "Money")).." Vero",
							[6] = "He played "..tostring(getElementData(hitElement, "RAMaps")).." RACE maps!",
							[7] = "He got "..tostring(getElementData(hitElement, "Points")).." points!",
							[8] = "His winning streak is x"..tostring(getElementData(hitElement, "winningCounter")).."!",
							[9] = "He has been already for "..tostring(math.floor(getElementData(hitElement, "TimeOnServer")/60)).." minutes on the Server!"
						}
							
						local hasCustomText = false
							
						if getElementData(hitElement, "isDonator") == true then
							if getElementData(hitElement, "useWinsound") ~= 0 then
								local players = getGamemodePlayers(gGamemodeRA)
								for theKey,thePlayer in ipairs(players) do
									if getElementData(thePlayer, "toggleWinsounds") == 1 then
										triggerClientEvent(thePlayer, "playWinsound", getRootElement(), "files/winsounds/"..tostring(getElementData(hitElement, "useWinsound"))..".mp3")
									end
								end
							end
							if getElementData(hitElement, "customWintext") ~= "none" then
								showWinMessage(gGamemodeRA, "#FFFFFF"..tostring(getElementData(hitElement, "customWintext")), "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
								hasCustomText = true
							end
						end
							
						if hasCustomText == false then
							showWinMessage(gGamemodeRA, "#FFFFFF".._getPlayerName(hitElement) .. '#FFFFFF has won the map!', "#FFFFFF"..tostring(ran_win_mesage[math.random(1,9)]), 214, 219, 145)
						end
						
					else
						setElementData(hitElement, "winningCounter", 0)
					end
					
					break
				end
			end
			setElementData(gElementRA, "rankingboard", gRankingboardPlayersRA)
			setElementData(hitElement, "nextMarker", spawnID)
			setElementData(hitElement, "state", "finished")
			
			local hasToptime = getPlayerToptimeInformation(gToptimesRA, getElementData(hitElement, "AccountName"))
			local toptimeAdded = addNewToptime(gToptimesRA, getElementData(hitElement, "AccountName"), racePassedTime)
			if toptimeAdded == true then
				callClientFunction(hitElement, "forceToptimesOpen")
				local tInformation = getPlayerToptimeInformation(gToptimesRA, getElementData(hitElement, "AccountName"))
				outputChatBoxToGamemode(":TOPTIME:#FFFFFF ".._getPlayerName(hitElement).."#FFFFFF finished the map ("..msToTimeStr(tInformation.time)..") and got toptime position "..tInformation.id..".",gGamemodeRA, 148,214,132, true)
				for i,v in ipairs(getGamemodePlayers(gGamemodeRA)) do
					sendToptimes(v, gToptimesRA)
				end
				if tInformation.id <= 12 and (hasToptime == false or hasToptime.id > 12) then
					setElementData(hitElement, "TopTimesRA", getElementData(hitElement, "TopTimesRA")+1)	
				end
				if tInformation.id <= 12 and (hasToptime ~= false and hasToptime.id <= 12) then
					addPlayerArchivement(hitElement, 59)
				end
			end
			
			callClientFunction(hitElement, "freezeCamera")
			setTimer(killRAPlayer, 3000, 1, hitElement)
		
			if #getAliveGamemodePlayers(gGamemodeRA) == 0 then
				endMapRA()
			else
				local endThisMotherfucker = true
				for i,v in ipairs(getGamemodePlayers(gGamemodeRA)) do
					if getElementData(v, "state") == "dead" or getElementData(v, "state") == "spawning" or getElementData(v, "state") == "alive" or getElementData(v, "state") == "ready" or getElementData(v, "state") == "not ready" then
						if getElementData(v, "AFK") ~= true then
							endThisMotherfucker = false
						end
					end
				end
				if endThisMotherfucker == true then
					endMapRA()
				end
			end
		else
			local playerTable = getElementData(source, "playerTable")
			playerTable[#playerTable+1] = {}
			playerTable[#playerTable].player = hitElement
			playerTable[#playerTable].ttime = getTickCount()-getElementData(gElementRA, "startTick")
			setElementData(source, "playerTable", playerTable)
			
			if playerTable[#playerTable-1] and playerTable[#playerTable-1].player and isElement(playerTable[#playerTable-1].player) then
				local lastPlayerTable = playerTable[#playerTable-1]
				local currentPlayerTable = playerTable[#playerTable]
				
				if getElementData(lastPlayerTable.player, "currentCP") >= spawnID and getElementData(lastPlayerTable.player, "state") == "alive" then
					if spawnID ~= getElementData(lastPlayerTable.player, "currentCP") then
						setElementData(lastPlayerTable.player, "-Text", "-"..tostring(msToTimeStr(currentPlayerTable.ttime-lastPlayerTable.ttime)).." (-"..tostring(getElementData(lastPlayerTable.player, "currentCP")-spawnID).." CP) | "..tostring(getPlayerName(currentPlayerTable.player)))
						setElementData(currentPlayerTable.player, "+Text", "+"..tostring(msToTimeStr(currentPlayerTable.ttime-lastPlayerTable.ttime)).." (+"..tostring(getElementData(lastPlayerTable.player, "currentCP")-spawnID).." CP) | "..tostring(getPlayerName(lastPlayerTable.player)))	
					else
						setElementData(lastPlayerTable.player, "-Text", "-"..tostring(msToTimeStr(currentPlayerTable.ttime-lastPlayerTable.ttime)).." | "..tostring(getPlayerName(currentPlayerTable.player)))
						setElementData(currentPlayerTable.player, "+Text", "+"..tostring(msToTimeStr(currentPlayerTable.ttime-lastPlayerTable.ttime)).." | "..tostring(getPlayerName(lastPlayerTable.player)))
					end
				end
				setTimer (function(player1, player2, text1, text2)
					if getElementData(player1, "-Text") == text1 then
						setElementData(player1, "-Text", false)
					end
					if getElementData(player2, "+Text") == text2 then
						setElementData(player2, "+Text", false)
					end						
				end, 2500, 1, lastPlayerTable.player, currentPlayerTable.player, getElementData(lastPlayerTable.player, "-Text"), getElementData(currentPlayerTable.player,"+Text") )				
			end
		end
						
		-- Set the marker after next visible
		if gCheckpointsRA[spawnID+2] then
			setElementVisibleTo(gCheckpointsRA[spawnID+2], hitElement, true)
			setElementVisibleTo ( getElementData(gCheckpointsRA[spawnID+2], "blip"), hitElement, true )
			
			-- Set the next marker's target
			local x, y, z = getElementPosition(gCheckpointsRA[spawnID+2])
			setMarkerTarget(gCheckpointsRA[spawnID+1], x, y, z)
			if not gCheckpointsRA[spawnID+3] then setMarkerIcon ( gCheckpointsRA[spawnID+2], "finish" ) end
		end

		playSoundFrontEnd ( hitElement, 43 )
		setElementVisibleTo(gCheckpointsRA[spawnID], hitElement, false)
		setElementVisibleTo ( getElementData(gCheckpointsRA[spawnID], "blip"), hitElement, false )
		
		if getElementData(source, "veh") then
			savePlayerPositionRA(hitElement, getElementData(source, "veh"))
		else
			savePlayerPositionRA(hitElement)
		end
	end
end

function savePlayerPositionRA (ply, model)
	local vehicle = getPedOccupiedVehicle(ply)
	if isElement(vehicle) then
		if getPlayerGameMode(ply) == gGamemodeRA and getElementData(ply, "state") == "alive" then
			if tostring(gRARespawns[ply]) == "nil" then
				gRARespawns[ply] = {}
				gRARespawns[ply]["G_counter"] = 0
			end
			gRARespawns[ply]["G_counter"] = gRARespawns[ply]["G_counter"] + 1
			local Counter = gRARespawns[ply]["G_counter"]
			gRARespawns[ply][Counter] = {}
			local x, y, z = getElementPosition( vehicle )
			gRARespawns[ply][Counter]["X"] = x
			gRARespawns[ply][Counter]["Y"] = y
			gRARespawns[ply][Counter]["Z"] = z
			if model then
				gRARespawns[ply][Counter]["Model"] = model
			else
				gRARespawns[ply][Counter]["Model"] = getElementModel ( vehicle )
			end
			local rx, ry, rz = getElementRotation ( vehicle )
			gRARespawns[ply][Counter]["RX"] = rx
			gRARespawns[ply][Counter]["RY"] = ry
			gRARespawns[ply][Counter]["RZ"] = rz
			local vx, vy, vz = getElementVelocity ( vehicle )
			gRARespawns[ply][Counter]["VX"] = vx
			gRARespawns[ply][Counter]["VY"] = vy
			gRARespawns[ply][Counter]["VZ"] = vz
			local tx, ty, tz = getElementAngularVelocity ( vehicle )
			gRARespawns[ply][Counter]["TX"] = tx
			gRARespawns[ply][Counter]["TY"] = ty
			gRARespawns[ply][Counter]["TZ"] = tz
			
			local nitro	getVehicleUpgradeOnSlot ( vehicle, 8 )
			if nitro ~= false and nitro ~= 0 then
				gRARespawns[ply][Counter]["NOS"] = true
			else
				gRARespawns[ply][Counter]["NOS"] = false
			end			
			
			gRARespawns[ply][Counter]["nextMarker"] = getElementData(ply, "nextMarker")
		else
			if getElementData(ply, "state") ~= "dead" and getElementData(ply, "state") ~= "spawning" then
				gRARespawns[ply] = nil
			end
		end
	end
end 	

function calculatePositionsRA()
	if gIsRARunning == true then
		local sortinfo = {}
		for i,v in ipairs(getGamemodePlayers(gGamemodeRA )) do
			sortinfo[i] = {}
			sortinfo[i].player = v
			sortinfo[i].checkpoint = getElementData(v, "currentCP")
			if not getElementData(v, "endPosRA") then
				sortinfo[i].endpos = 0
			else
				sortinfo[i].endpos = getElementData(v, "endPosRA")
			end
			
			local nextCP = gCheckpointsRA[getElementData(v, "nextMarker")]
			if isElement(nextCP) and getElementData(v, "state") == "alive" then
				local x,y,z = getElementPosition(v)
				local x1,y1,z1 = getElementPosition(nextCP)
				local distance = getDistanceBetweenPoints2D(x, y, x1, y1)
				sortinfo[i].cpdist = distance
			elseif getElementData(v, "state") == "finished" then
				sortinfo[i].cpdist = 0
			else
				sortinfo[i].cpdist = 99999999
			end
		end
		
		table.sort( sortinfo, function(a,b)
			return a.checkpoint > b.checkpoint or
				   ( a.checkpoint == b.checkpoint and a.cpdist < b.cpdist )
					or (a.checkpoint == b.checkpoint and a.cpdist == b.cpdist and a.endpos > b.endpos)
		end )
		
		for i,v in ipairs(getGamemodePlayers(gGamemodeRA )) do
			for i2,v2 in ipairs(sortinfo) do
				if v2.player == v then
					if getElementData(v, "state") == "finished" then
						setElementData(v, "racePos", v2.endpos)
					else
						setElementData(v, "racePos", i2)
					end
				end
			end
		end
	else
		for i,v in ipairs(getGamemodePlayers(gGamemodeRA )) do
			setElementData(v, "racePos", false)
		end
	end
end
setTimer(calculatePositionsRA, 1000, 0)

function respawnPlayerRA(player, start)
	if getElementData(player, "state")  ~= "dead" and getElementData(player, "state")  ~= "spawning" then return end
	if gIsRARunning ~= true then return end
	if start == true or not gRARespawns[player] or not gRARespawns[player]["G_counter"] or gRARespawns[player]["G_counter"] <= 0 then
		callClientFunction ( player, "spectateEnd", true )
		local spawn = 1
		gRARespawns[player] = nil
		setCameraTarget ( player )
		spawnPlayer(player, gSpawnPositionsRA[spawn].posX, gSpawnPositionsRA[spawn].posY, gSpawnPositionsRA[spawn].posZ)
		setElementDimension(player, gGamemodeRA)
		local veh = createVehicle(gSpawnPositionsRA[spawn].vehicle, gSpawnPositionsRA[spawn].posX, gSpawnPositionsRA[spawn].posY, gSpawnPositionsRA[spawn].posZ, gSpawnPositionsRA[spawn].rotX, gSpawnPositionsRA[spawn].rotY, gSpawnPositionsRA[spawn].rotZ, "Vita")
		setElementDimension(veh, gGamemodeRA)
		setElementFrozen(veh, true)
		warpPedIntoVehicle(player, veh)
		setElementData(veh, "isRAVeh", true)
		setElementData(player, "raceVeh", veh)
		setElementData(player, "state", "spawning")
		setElementData(player, "nextMarker", 1)
		setElementData(player, "currentCP", 0)
		setElementAlpha(player, 255)
		setElementFrozen(player, true)
		setVehicleDamageProof ( veh, true )
		for i,v in ipairs(gCheckpointsRA) do
			setElementVisibleTo ( v, player, false)
		end		
		setElementVisibleTo ( gCheckpointsRA[1], player, true)
		if gCheckpointsRA[2] then setElementVisibleTo ( gCheckpointsRA[2], player, true) end		
		setTimer(function(player)
			setElementFrozen(getPedOccupiedVehicle(player), false)
			setElementData(player, "state", "alive")
			setVehicleDamageProof ( getPedOccupiedVehicle(player), false )
		end, 3000,1,player)
	else
		if tostring(gRARespawns[player]) == "nil" then triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "No respawn data found.") return respawnPlayerRA(player, true) end
		local Counter = gRARespawns[player]["G_counter"]
		if Counter < 1 then  triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "No respawn data found.") return respawnPlayerRA(player, true)  end
		callClientFunction ( player, "spectateEnd", true )
		gRARespawns[player]["G_counter"] = gRARespawns[player]["G_counter"]-1
		setCameraTarget ( player )
		spawnPlayer(player, gRARespawns[player][Counter]["X"], gRARespawns[player][Counter]["Y"], gRARespawns[player][Counter]["Z"])
		setElementDimension(player, gGamemodeRA)
		local veh = createVehicle(gRARespawns[player][Counter]["Model"], gRARespawns[player][Counter]["X"], gRARespawns[player][Counter]["Y"], gRARespawns[player][Counter]["Z"],  gRARespawns[player][Counter]["RX"], gRARespawns[player][Counter]["RY"], gRARespawns[player][Counter]["RZ"], "Vita")
		setElementDimension(veh, gGamemodeRA)
		setElementFrozen(veh, true)
		warpPedIntoVehicle(player, veh)
		setElementData(veh, "isRAVeh", true)
		setElementData(player, "raceVeh", veh)
		setVehicleDamageProof ( veh, true )
		setElementAlpha(player, 255)
		
		if gRARespawns[player][Counter]["NOS"] == true then
			addVehicleUpgrade ( veh, 1010 )
		end
		
		setElementData(player, "state", "spawning")
		setElementData(player, "nextMarker", gRARespawns[player][Counter]["nextMarker"])
		setElementData(player, "currentCP", gRARespawns[player][Counter]["nextMarker"]-1)
		setElementFrozen(player, true)
		for i,v in ipairs(gCheckpointsRA) do
			setElementVisibleTo ( v, player, false)
		end		
		setElementVisibleTo ( gCheckpointsRA[gRARespawns[player][Counter]["nextMarker"]], player, true)
		if gCheckpointsRA[gRARespawns[player][Counter]["nextMarker"]+1] then setElementVisibleTo ( gCheckpointsRA[gRARespawns[player][Counter]["nextMarker"]+1], player, true) end
		
		setTimer(function(player, vx, vy, vz, tx,ty,tz)
			local veh = getPedOccupiedVehicle(player)
			if isElement(veh) then
				setElementFrozen(veh, false)
				setVehicleDamageProof (  veh, false )
				setElementVelocity(veh, vx,vy,vz)
				setElementAngularVelocity(veh, tx, ty, tz)
				setElementData(player, "state", "alive")
			end
		end, 3000,1,player, gRARespawns[player][Counter]["VX"], gRARespawns[player][Counter]["VY"], gRARespawns[player][Counter]["VZ"], gRARespawns[player][Counter]["TX"], gRARespawns[player][Counter]["TY"], gRARespawns[player][Counter]["TZ"])	
	end
	
end
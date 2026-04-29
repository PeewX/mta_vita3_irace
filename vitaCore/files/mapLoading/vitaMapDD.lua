--[[
projectLight Maploading
File: loadMap.lua

Author:	Sebihunter
]]--

gChangedModels = {}
gChangedTXD = {}
gEventHandlers = {}
gMapSounds = {}
gMapBinds = {}
gMapCommands = {}
gMapMarkers = {}
gMapObjects = {}
gMapTimers = {}
gScriptsVars = {}
gScriptShaders = {}

_dxCreateShader = dxCreateShader
function dxCreateShader (filepath, priority, maxDistance, layered, elementTypes )
	if not filepath then return false end
	if not priority then priority = 0 end
	if not maxDistance then maxDistance = 0 end
	if not layered then layered = false end
	if not elementTypes then elementTypes = 0 end
	local marker = _dxCreateShader (filepath, priority, maxDistance, layered, elementTypes )
	gScriptShaders[#gScriptShaders+1] = marker
	return marker
end

_outputChatBox = outputChatBox
function outputChatBox( text, r, g, b, colorCoded)
	return true
	--[[if not text then text = "" end
	if not r then r = 231 end
	if not g then g = 217 end
	if not b then b = 176 end
	if not colorCoded then colorCoded = false end
	
	if string.find(text, "@loadstring" ) then return false end
	return outputChatBox( text, r, g, b, colorCoded)]]
end

_setTimer = setTimer
function setTimer ( theFunction, timeInterval, timesToExecute, ... )
	local timer
	if ... then
		timer = _setTimer(theFunction, timeInterval, timesToExecute, ... )
	else
		timer = _setTimer(theFunction, timeInterval, timesToExecute )
	end
	gMapTimers[#gMapTimers+1] = timer
	return timer
end

_engineImportTXD = engineImportTXD
function engineImportTXD ( txd, model_id )
	local hasFound = false
	for i,v in ipairs(gChangedTXD) do
		if v == txd then
			hasFound = true
		end
	end
	if hasFound == false then
		gChangedTXD[#gChangedTXD+1] = txd
	end
	return _engineImportTXD ( txd, model_id )
end

_engineReplaceModel = engineReplaceModel
function engineReplaceModel ( dff, model_id )
	local hasFound = false
	for i,v in ipairs(gChangedModels) do
		if v == model_id then
			hasFound = true
		end
	end
	if hasFound == false then
		gChangedModels[#gChangedModels+1] = model_id
	end
	return _engineReplaceModel ( dff, model_id )
end

_addCommandHandler = addCommandHandler
function addCommandHandler(cmd, func)
	gMapCommands[#gMapCommands+1] = cmd
	return _addCommandHandler(cmd, func, false)
end

_createMarker = createMarker
function createMarker(x, y, z, ...)
	if not x or not y or not z then return false end
	local marker = _createMarker(x, y, z, ...)
	gMapMarkers[#gMapMarkers+1] = marker
	setElementDimension(marker, getElementData(getLocalPlayer(), "gameMode"))
	return marker
end

_createObject = createObject
function createObject(modelid, x, y, z, ...)
	if not modelid or not x or not y or not z then return false end
	local object = _createObject(modelid, x, y, z, ...)
	gMapObjects[#gMapObjects+1] = object
	setElementDimension(object, getElementData(getLocalPlayer(), "gameMode"))
	return object
end

_removeCommandHandler = removeCommandHandler
function removeCommandHandler(cmd)
	for i,v in pairs(gMapCommands) do
		if v == cmd then
			v = false
		end
	end
	return _removeCommandHandler(cmd)
end

_bindKey = bindKey
function bindKey(key, keyState, handlerFunction, arguments)
	if key ~= "m" then
		local number = #gMapBinds+1
		gMapBinds[number] = {}
		gMapBinds[number].key = key
		local result
		if arguments then
			result = _bindKey(key, keyState, handlerFunction, arguments)
		else
			result = _bindKey(key, keyState, handlerFunction)
		end
		return result
	else
		return false
	end
end

_unbindKey = unbindKey
function unbindKey(key, keyState, handler)
	for i,v in pairs(gMapBinds) do
		if v.key == key then
			v.key = {}
			v.key = false
		end
	end
	return _unbindKey(key)
end

_playSound = playSound
function playSound( soundPath, looped )
	triggerEvent ( "onMapSoundReceive", root, soundPath)
	if true then return end

	if looped ~= true then looped = false end
	soundPath = string.gsub(soundPath, "vita%-online%.eu", "sebihunter%.de")
	soundPath = string.gsub(soundPath, "vita%.gamers%-board%.com", "sebihunter%.de")		
	
--	local sound
--	if string.find(soundPath, "song" ) ) or ( string.find(soundPath, "music" ) ) then
		if string.find(soundPath, "http") then
			triggerEvent ( "onMapSoundReceive",getRootElement(), soundPath)		
		else
			triggerEvent ( "onMapSoundReceive",getRootElement(),"http://85.114.142.22:22005/vitaStream/dd.mp3")
		end
		sound = _playSound( "http://sebihunter.de/serverfiles/race/nothing.wav", true)
		gMapSounds[#gMapSounds+1] = sound	
		return sound
--	else
--		sound = _playSound( soundPath, looped)
--		gMapSounds[#gMapSounds+1] = sound	
--		return sound
--	end
--	return false
end

_stopSound = stopSound
function stopSound ( theSound )
	for i,v in pairs(gMapSounds) do
		if v == theSound then
			v = false
		end
	end
	return _stopSound(theSound)
end

addEvent("onClientResourceStartScript")
addEvent("onClientResourceStopScript")
addEvent("onClientPlayerSpawnScript")
_addEventHandler = addEventHandler
function addEventHandler(event, elem, fn, getPropagated)
	if event == "onClientResourceStart" then event = "onClientResourceStartScript" end		
	if event == "onClientPlayerSpawn" then event = "onClientPlayerSpawnScript" end		
	if event == "onClientResourceStop" then event = "onClientResourceStopScript" end		
	
	getPropagated = getPropagated==nil and true or getPropagated
	local number = #gEventHandlers+1
	gEventHandlers[number] = {}
	gEventHandlers[number].event = event
	gEventHandlers[number].elem = elem
	gEventHandlers[number].fn = fn
	return _addEventHandler(event, elem, fn, getPropagated)
end

_removeEventHandler = removeEventHandler
function removeEventHandler(event, elem, fn)
	if event == "onClientResourceStart" then event = "onClientResourceStartScript" end		
	if event == "onClientResourceStop" then event = "onClientResourceStopScript" end		
	if event == "onClientPlayerSpawn" then event = "onClientPlayerSpawnScript" end		
	
	local removeNumber = {}
	for i,v in pairs(gEventHandlers) do
		if v.event == event and v.elem == elem and v.fn == fn then
			gEventHandlers[i] = nil
			removeNumber[#removeNumber] = i
		end
	end
	
	for i,v in ipairs(removeNumber) do
		table.remove(gEventHandlers, i)
	end
	return _removeEventHandler(event, elem, fn)
end

filesDownloaded = 0
scriptsDownloaded = 0
hasLoadedAlready = false


function stopMap()
	triggerEvent ( "onClientResourceStopScript",getResourceRootElement(getThisResource()))
	--triggerEvent ( "onMapSoundStop", getRootElement())
	for i,v in pairs (gMapCommands) do
		_removeCommandHandler(v)
	end
	for i,v in pairs(gEventHandlers) do
		_removeEventHandler(v.event, v.elem, v.fn)
	end
	for i,v in pairs(gMapSounds) do
		if isElement(v) then
			if getElementData(v, "mapsound") then
				if isElement(getElementData(v, "mapsound")) then
					destroyElement(getElementData(v, "mapsound"))
				end
			end
			_stopSound(v)
		end
	end	
	for i,v in pairs(gMapBinds) do
		_unbindKey(v.key)
	end
	for i,v in pairs(gMapObjects) do
		if isElement(v) then
			destroyElement(v)
		end
	end
	for i,v in pairs (gChangedTXD) do
		if isElement(v) then
			destroyElement(v)
		end
	end
	for i,v in pairs(gChangedModels) do
		engineRestoreModel ( v )
	end	
	for i,v in pairs(gScriptShaders) do
		if isElement(v) then
			destroyElement(v)
		end
	end		
	for i,v in pairs(gMapMarkers) do
		if isElement(v) then
			destroyElement(v)
		end
	end	
	for i,v in pairs(getElementsByType ( "vehicle")) do
		if getElementData(v, "isMapDDVehicle") == true then
			destroyElement(v)
		end
	end	
	for i,v in pairs(getElementsByType ( "racePickup")) do
		if getElementData(v, "mode") == "DD" then
			if getElementData(v, "col") then
				destroyElement(getElementData(v, "col"))
			end
			destroyElement(v)
		end
	end
	for i,v in pairs(gMapTimers) do
		if isTimer(v) then
			killTimer(v)
		end
	end
	
	--Delete script variables
	for k, v in pairs(_G) do 
		if not gScriptsVars[k] then
			_G[k] = nil
		end
	end		
	
	gEventHandlers = {}
	gMapSounds = {}
	gMapBinds = {}
	gMapCommands = {}
	gMapMarkers = {}
	gScriptShaders = {}
	gMapObjects = {}	
	gChangedModels = {}
	gChangedTXD = {}
	gMapTimers = {}
	filesDownloaded = 0
	scriptsDownloaded = 0
	hasLoadedAlready = false
end
addEvent ( "stopMapDD", true )
_addEventHandler ( "stopMapDD", getRootElement(), stopMap )


function checkScriptStart()
	if filesDownloaded == 0 then
		if isTimer(scriptStartTimer) then killTimer(scriptStartTimer) end
		local metaXML = xmlLoadFile ( "meta2.xml" )
		if metaXML == false then
			return false
		end
		
		--Download Scripts
		if metaXML then
			local i = 0
			while true do 
				local filenode = xmlFindChild ( metaXML, "file", i)
				if not filenode then
					break
				else
					if xmlNodeGetAttribute(filenode, "download") == "false" and xmlNodeGetAttribute(filenode, "type") == "client" then
						local fileName = xmlNodeGetAttribute(filenode, "src")
						
						--Temporary bugfix until #7291 is fixed
						--if fileExists ( fileName ) then
						--	fileDelete(fileName)
						--end			
						
						if ( string.find(fileName, ".lua" ) ) then
							scriptsDownloaded = scriptsDownloaded + 1
							exports.vitaDownload:downloadFile(fileName, fileName)
						end
					end
				end
				i = i + 1
			end
		end	
		
		--No scripts found so let us start the map	
		if scriptsDownloaded == 0 then
			triggerServerEvent("downloadMapFinishedDD", getRootElement(), getLocalPlayer())
		end		
		
		xmlUnloadFile(metaXML)
		fileDelete("meta2.xml")
	end                                    
end

function loadMap(meta2, rsnm)
	if hasLoadedAlready == true then return false end
	setElementData(getLocalPlayer(), "loadMapDD", true)
	hasLoadedAlready = true
	gMapname = rsnm
	
	if fileExists("meta2.xml") then
		fileDelete("meta2.xml")
	end
	local newFile = fileCreate("meta2.xml")
	if newFile then
		fileWrite(newFile, meta2)
		fileClose(newFile)
	end
	
	local metaXML = xmlLoadFile ( "meta2.xml" )
	if metaXML == false then
		return false
	end	
	
	resetWaterColor()
	setWaterLevel(0.01)
    resetHeatHaze()
    resetSkyGradient()
    resetWindVelocity()
	--resetWorldSounds()
	resetRainLevel()
	resetSunSize()
	resetSunColor()
	resetFarClipDistance()
	resetFogDistance()
	setGameSpeed(1)
	setGravity(0.008)
	
	
	--Map settings
	
	if metaXML then
		local i = 0
		local settingsnode = xmlFindChild ( metaXML, "settings", 0)
		if settingsnode then
			while true do 
				local filenode = xmlFindChild ( settingsnode, "setting", i)
				if not filenode then
					break
				else
					if xmlNodeGetAttribute(filenode, "name") == "#weather" then
						local value = xmlNodeGetAttribute(filenode, "value")
						if value then
							value = string.gsub(value, "%s+", "")
							value = string.gsub(value, "[%[%]]", "")
							setWeather(tonumber(value))
						else
							setWeather(0)
						end	
					elseif xmlNodeGetAttribute(filenode, "name") == "#time" then
						local value = xmlNodeGetAttribute(filenode, "value")
						if value then
							value = string.gsub(value, "%s+", "")
							value = string.gsub(value, "[%[%]]", "")
							local datTime = split(value, ":")
							setTime(datTime[1], datTime[2])
							setMinuteDuration(60000)
							mapTime = value
						else
							setTime(12,0)
							setMinuteDuration(60000)
						end			
							
					elseif xmlNodeGetAttribute(filenode, "name") == "#waveheight" then
						local value = xmlNodeGetAttribute(filenode, "value")
						if value then
							value = string.gsub(value, "%s+", "")
							value = string.gsub(value, "[%[%]]", "")				
							setWaveHeight(tonumber(value))
						else
							setWaveHeight(0)
						end				
					end			
				end
				i = i + 1
			end
		end
	end
	
	--Download files
	if metaXML then
		local i = 0
		while true do 	
			local filenode = xmlFindChild ( metaXML, "file", i)
			if not filenode then
				break
			else
				if xmlNodeGetAttribute(filenode, "download") == "false" then
					local fileName = xmlNodeGetAttribute(filenode, "src")
					if ( string.find(fileName, ".lua" ) ) == nil then
					
						--Temporary bugfix until #7291 is fixed
						--if fileExists ( fileName ) then
						--	fileDelete(fileName)
						--end
						
						exports.vitaDownload:downloadFile(fileName,fileName)
						filesDownloaded = filesDownloaded + 1
					end
				end
			end
			i = i + 1
		end
	end
	scriptStartTimer = _setTimer(checkScriptStart, 100, 0)
end
addEvent ( "loadMapDD", true )
_addEventHandler ( "loadMapDD", getRootElement(), loadMap )

function onDownloadFinish ( file )
	if getElementData(getLocalPlayer(), "gameMode") ~= 2 then  stopMap() return false end
   -- if ( source == resourceRoot ) then
        --if ( success ) then
			if filesDownloaded ~= 0 then
				filesDownloaded = filesDownloaded - 1
			end
            if ( string.find(file, ".lua" ) ) then
				local hFile = fileOpen(file)
				local buffer = ""
				if hFile then
					while not fileIsEOF(hFile) do
						buffer = buffer .."".. fileRead(hFile, 500)
					end
				end
				local commandFunction, errorMsg = loadstring(buffer)
				if commandFunction == nil then
					outputDebugString(errorMsg,1)
				else
					pcall(commandFunction)
				end
				-- pcall(commandFunction) --was used before the function above was in usage
				fileClose(hFile)
				scriptsDownloaded = scriptsDownloaded - 1
				if scriptsDownloaded == 0 then
					triggerEvent ( "onClientResourceStartScript",getResourceRootElement(getThisResource()))
					triggerEvent ( "onClientPlayerSpawnScript", getLocalPlayer())
					triggerServerEvent("downloadMapFinishedDD", getRootElement(), getLocalPlayer())
					--setElementData(getLocalPlayer(), "state", "ready")
				end
            elseif ( string.find(file, ".map" ) ) then
				local mapfile = xmlLoadFile ( file )
				if mapfile then
					local i2 = 0	
					while true do
						local mapfilenode = xmlFindChild ( mapfile, "object", i2)
						if not mapfilenode then
							break
						else
			
							local modelID = tonumber(xmlNodeGetAttribute(mapfilenode, "model"))
							local interiorID = tonumber(xmlNodeGetAttribute(mapfilenode, "interior"))
							local posX = tonumber(xmlNodeGetAttribute(mapfilenode, "posX"))
							local posY = tonumber(xmlNodeGetAttribute(mapfilenode, "posY"))
							local posZ = tonumber(xmlNodeGetAttribute(mapfilenode, "posZ"))
							local rotX = tonumber(xmlNodeGetAttribute(mapfilenode, "rotX"))
							local rotY = tonumber(xmlNodeGetAttribute(mapfilenode, "rotY"))
							local rotZ = tonumber(xmlNodeGetAttribute(mapfilenode, "rotZ"))
							local doublesided = xmlNodeGetAttribute(mapfilenode, "doublesided")
							local scale = (xmlNodeGetAttribute(mapfilenode, "scale") or 1.0)
							local alpha = (xmlNodeGetAttribute(mapfilenode, "alpha") or 255)	
							local collisions = (xmlNodeGetAttribute(mapfilenode, "collisions") or "true")
							
							local object = createObject(modelID, posX, posY, posZ, rotX, rotY, rotZ)
							if object then
								if interiorID then
									setElementInterior(object, interiorID)
								end
								setElementDimension(object, getElementData(getLocalPlayer(), "gameMode"))

								if doublesided == "true" then
									setElementDoubleSided(object, true)
								end

								if(collisions == "false" or collisions == false) then
									setElementCollisionsEnabled(object,false)
								else
									setElementCollisionsEnabled(object,true)
								end
								setObjectScale(object,scale)
								setElementAlpha(object,alpha)
							end
						end
						i2 = i2+1
					end

					i2 = 0
					while true do
						local mapfilenode = xmlFindChild ( mapfile, "marker", i2)
						if not mapfilenode then
							break
						else
							local theType = xmlNodeGetAttribute(mapfilenode, "type")
							local interiorID = tonumber(xmlNodeGetAttribute(mapfilenode, "interior"))
							local posX = tonumber(xmlNodeGetAttribute(mapfilenode, "posX"))
							local posY = tonumber(xmlNodeGetAttribute(mapfilenode, "posY"))
							local posZ = tonumber(xmlNodeGetAttribute(mapfilenode, "posZ"))
							local size = tonumber(xmlNodeGetAttribute(mapfilenode, "size"))
							local color = xmlNodeGetAttribute(mapfilenode, "color")
							
							local r = 0
							local g = 0
							local b = 255							
							local a = 255
							if color then
								r,g,b,a = getColorFromString ( color )
							end

							local object = createMarker(posX,posY,posZ,theType,size,r,g,b,a )
							
							if interiorID then
								setElementInterior(object, interiorID)
							end
							setElementDimension(object, getElementData(getLocalPlayer(), "gameMode"))

						end
						i2 = i2+1
					end

					i2 = 0
					while true do
						local mapfilenode = xmlFindChild ( mapfile, "vehicle", i2)
						if not mapfilenode then
							break
						else
							local model = tonumber(xmlNodeGetAttribute(mapfilenode, "model"))
							local interiorID = tonumber(xmlNodeGetAttribute(mapfilenode, "interior"))
							local posX = tonumber(xmlNodeGetAttribute(mapfilenode, "posX"))
							local posY = tonumber(xmlNodeGetAttribute(mapfilenode, "posY"))
							local posZ = tonumber(xmlNodeGetAttribute(mapfilenode, "posZ"))
							local rotX = tonumber(xmlNodeGetAttribute(mapfilenode, "rotX"))
							local rotY = tonumber(xmlNodeGetAttribute(mapfilenode, "rotY"))
							local rotZ = tonumber(xmlNodeGetAttribute(mapfilenode, "rotZ"))							
							local numberplate = xmlNodeGetAttribute(mapfilenode, "numberplate")
							if not numberplate then numberplate = "Vita" end


							local object = createVehicle ( model, posX, posY, posZ, rotX, rotY, rotZ, numberplate )
							setElementData( object, "isMapDDVehicle", true)
							
							if interiorID then
								setElementInterior(object, interiorID)
							end
							setElementDimension(object, getElementData(getLocalPlayer(), "gameMode"))

						end
						i2 = i2+1
					end
					
					i2 = 0
					while true do
						local mapfilenode = xmlFindChild ( mapfile, "racepickup", i2)
						if not mapfilenode then
							break
						else
							local pickup = createElement("racePickup")
							setElementData(pickup, "mode", "DD")
							local pickupType = xmlNodeGetAttribute(mapfilenode, "type")
							local posX = tonumber(xmlNodeGetAttribute(mapfilenode, "posX"))
							local posY = tonumber(xmlNodeGetAttribute(mapfilenode, "posY"))
							local posZ = tonumber(xmlNodeGetAttribute(mapfilenode, "posZ"))		
							local interiorID = tonumber(xmlNodeGetAttribute(mapfilenode, "interior"))
							local object = false
							if pickupType == "vehiclechange" then
								pickupType = "vehicle"
								object = createObject(2223, posX, posY, posZ, 0, 0, 0)
								local vehicle = tonumber(xmlNodeGetAttribute(mapfilenode, "vehicle"))		
								setElementData(pickup, "vehicle", vehicle)
							elseif pickupType == "nitro" then
								object = createObject(2221, posX, posY, posZ, 0, 0, 0)
							elseif pickupType == "repair" then
								object = createObject(2222, posX, posY, posZ, 0, 0, 0)
							end
							
							if object then
								setElementData(pickup, "type", pickupType)
								if interiorID then
									setElementInterior(object, interiorID)
								end
								setElementDimension(object, getElementData(getLocalPlayer(), "gameMode"))
								setElementData(pickup, "object", object)

								local col = createColSphere ( posX, posY, posZ, 3.5 )
								setElementData(pickup, "col", col)
								setElementData(col, "pickup", pickup)
								setElementDimension(col, getElementData(getLocalPlayer(), "gameMode"))
							end
						end
						i2 = i2+1
					end					
					xmlUnloadFile(mapfile)
				end
				fileDelete ( file )
			end
		--end
   -- end
end
addEvent("onClientDownloadComplete", true)
_addEventHandler ( "onClientDownloadComplete", getRootElement(), onDownloadFinish )

for k, v in pairs(_G) do
	gScriptsVars[k] = true
end
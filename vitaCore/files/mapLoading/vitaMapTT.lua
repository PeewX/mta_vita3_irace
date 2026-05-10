--
-- PewX (HorrorClown)
-- vitaMapTTnew.lua - Client-side script sandbox for TimeTrial maps
--

local gamemodeDim = 7

local trackedElements = {}
local trackedTimers   = {}
local trackedCommands = {}
local trackedHandlers = {}
local trackedModels   = {}
local trackedTXD      = {}
local trackedShaders  = {}

local filesDownloaded   = 0
local scriptsDownloaded = 0
local hasLoadedAlready  = false
local scriptStartTimer
local savedGlobals = {}

-- Completely blocked — map scripts must not use these
local restrictedFunctions = {
    ["createBrowser"] = true,
    ["bindKey"]       = true,
    ["unbindKey"]     = true,
}

-- Silently suppressed — return true, no side effects
local suppressedFunctions = {
    ["outputChatBox"] = true,
    ["playSound"]     = true,
    ["stopSound"]     = true,
}

-- Creator functions: element is tracked and placed in the TT dimension
local creatorFunctions = {
    ["createColSphere"]      = true,
    ["createColTube"]        = true,
    ["createColCircle"]      = true,
    ["createColPolygon"]     = true,
    ["createColRectangle"]   = true,
    ["createColCuboid"]      = true,
    ["createObject"]         = true,
    ["createMarker"]         = true,
    ["createVehicle"]        = true,
    ["createBlip"]           = true,
    ["createBlipAttachedTo"] = true,
    ["createPed"]            = true,
    ["createWater"]          = true,
    ["createPickup"]         = true,
}

for name in pairs(restrictedFunctions) do
    _G[name] = function() return false end
end

for name in pairs(suppressedFunctions) do
    _G[name] = function() return true end
end

for name in pairs(creatorFunctions) do
    local orig = _G[name]
    if orig then
        _G[name] = function(...)
            local elem = orig(...)
            if elem then
                trackedElements[#trackedElements + 1] = elem
                setElementDimension(elem, gamemodeDim)
            end
            return elem
        end
    end
end

local _engineImportTXD = engineImportTXD
function engineImportTXD(txd, modelId)
    trackedTXD[#trackedTXD + 1] = txd
    return _engineImportTXD(txd, modelId)
end

local _engineReplaceModel = engineReplaceModel
function engineReplaceModel(dff, modelId)
    trackedModels[#trackedModels + 1] = modelId
    return _engineReplaceModel(dff, modelId)
end

local _dxCreateShader = dxCreateShader
function dxCreateShader(...)
    local shader = _dxCreateShader(...)
    if shader then trackedShaders[#trackedShaders + 1] = shader end
    return shader
end

local _setTimer = setTimer
function setTimer(fn, interval, times, ...)
    local timer = _setTimer(fn, interval, times, ...)
    trackedTimers[#trackedTimers + 1] = timer
    return timer
end

local _addCommandHandler = addCommandHandler
function addCommandHandler(cmd, fn)
    trackedCommands[#trackedCommands + 1] = cmd
    return _addCommandHandler(cmd, fn, false)
end

local _removeCommandHandler = removeCommandHandler
function removeCommandHandler(cmd)
    for i, v in pairs(trackedCommands) do
        if v == cmd then trackedCommands[i] = nil end
    end
    return _removeCommandHandler(cmd)
end

addEvent("onClientResourceStartScript")
addEvent("onClientResourceStopScript")
addEvent("onClientPlayerSpawnScript")

local _addEventHandler = addEventHandler
function addEventHandler(event, elem, fn, propagated, priority)
    if not event or not elem or not fn then return false end
    if event == "onClientResourceStart" then event = "onClientResourceStartScript" end
    if event == "onClientResourceStop"  then event = "onClientResourceStopScript"  end
    if event == "onClientPlayerSpawn"   then event = "onClientPlayerSpawnScript"   end
    propagated = propagated == nil and true or propagated
    trackedHandlers[#trackedHandlers + 1] = { event = event, elem = elem, fn = fn }
    return _addEventHandler(event, elem, fn, propagated, priority)
end

local _removeEventHandler = removeEventHandler
function removeEventHandler(event, elem, fn)
    if event == "onClientResourceStart" then event = "onClientResourceStartScript" end
    if event == "onClientResourceStop"  then event = "onClientResourceStopScript"  end
    if event == "onClientPlayerSpawn"   then event = "onClientPlayerSpawnScript"   end
    for i, v in pairs(trackedHandlers) do
        if v.event == event and v.elem == elem and v.fn == fn then
            trackedHandlers[i] = nil
        end
    end
    return _removeEventHandler(event, elem, fn)
end

local _triggerServerEvent = triggerServerEvent
function triggerServerEvent(eventName, ...)
    if eventName == "playerGotHunter" then eventName = "playerGotHunterTT" end
    return _triggerServerEvent(eventName, ...)
end

local function stopMap()
    triggerEvent("onClientResourceStopScript", getResourceRootElement(getThisResource()))

    for _, cmd   in pairs(trackedCommands) do _removeCommandHandler(cmd) end
    for _, h     in pairs(trackedHandlers) do _removeEventHandler(h.event, h.elem, h.fn) end
    for _, elem  in pairs(trackedElements) do if isElement(elem)  then destroyElement(elem)       end end
    for _, txd   in pairs(trackedTXD)     do if isElement(txd)   then destroyElement(txd)        end end
    for _, model in pairs(trackedModels)  do engineRestoreModel(model) end
    for _, sh    in pairs(trackedShaders) do if isElement(sh)    then destroyElement(sh)         end end
    for _, timer in pairs(trackedTimers)  do if isTimer(timer)   then killTimer(timer)           end end

    for k in pairs(_G) do
        if not savedGlobals[k] then _G[k] = nil end
    end

    trackedElements  = {}
    trackedTimers    = {}
    trackedCommands  = {}
    trackedHandlers  = {}
    trackedModels    = {}
    trackedTXD       = {}
    trackedShaders   = {}
    filesDownloaded   = 0
    scriptsDownloaded = 0
    hasLoadedAlready  = false
end

addEvent("stopMapTT", true)
_addEventHandler("stopMapTT", getRootElement(), stopMap)

local function checkScriptStart()
    if filesDownloaded ~= 0 then return end
    if isTimer(scriptStartTimer) then killTimer(scriptStartTimer) end

    local metaXML = xmlLoadFile("meta2.xml")
    if not metaXML then return end

    local i = 0
    while true do
        local node = xmlFindChild(metaXML, "file", i)
        if not node then break end
        if xmlNodeGetAttribute(node, "download") == "false" and xmlNodeGetAttribute(node, "type") == "client" then
            local fileName = xmlNodeGetAttribute(node, "src")
            if string.find(fileName, "%.lua") then
                scriptsDownloaded = scriptsDownloaded + 1
                exports.vitaDownload:downloadFile(fileName, fileName)
            end
        end
        i = i + 1
    end

    if scriptsDownloaded == 0 then
        _triggerServerEvent("downloadMapFinishedTT", getRootElement(), getLocalPlayer())
    end

    xmlUnloadFile(metaXML)
    fileDelete("meta2.xml")
end

local function applyMapSettings(metaXML)
    resetWaterColor()
    setWaterLevel(0.01)
    resetHeatHaze()
    resetSkyGradient()
    resetWindVelocity()
    resetRainLevel()
    resetSunSize()
    resetSunColor()
    resetFarClipDistance()
    resetFogDistance()
    setGameSpeed(1)
    setGravity(0.008)

    local settingsNode = xmlFindChild(metaXML, "settings", 0)
    if not settingsNode then return end

    local i = 0
    while true do
        local node = xmlFindChild(settingsNode, "setting", i)
        if not node then break end
        local name  = xmlNodeGetAttribute(node, "name")
        local value = xmlNodeGetAttribute(node, "value")
        if value then
            value = value:gsub("%s+", ""):gsub("[%[%]]", "")
            if     name == "#weather"    then setWeather(tonumber(value))
            elseif name == "#waveheight" then setWaveHeight(tonumber(value))
            elseif name == "#time"       then
                local t = split(value, ":")
                setTime(t[1], t[2])
                setMinuteDuration(60000)
            end
        end
        i = i + 1
    end
end

local function loadMap(meta2)
    if hasLoadedAlready then return end
    hasLoadedAlready = true
    setElementData(getLocalPlayer(), "loadMapTT", true)

    if fileExists("meta2.xml") then fileDelete("meta2.xml") end
    local f = fileCreate("meta2.xml")
    if f then
        fileWrite(f, meta2)
        fileClose(f)
    end

    local metaXML = xmlLoadFile("meta2.xml")
    if not metaXML then return end

    applyMapSettings(metaXML)

    local i = 0
    while true do
        local node = xmlFindChild(metaXML, "file", i)
        if not node then break end
        if xmlNodeGetAttribute(node, "download") == "false" then
            local fileName = xmlNodeGetAttribute(node, "src")
            if not string.find(fileName, "%.lua") then
                exports.vitaDownload:downloadFile(fileName, fileName)
                filesDownloaded = filesDownloaded + 1
            end
        end
        i = i + 1
    end

    xmlUnloadFile(metaXML)

    scriptStartTimer = _setTimer(checkScriptStart, 100, 0)
end

addEvent("loadMapTT", true)
_addEventHandler("loadMapTT", getRootElement(), loadMap)

local function processLua(file)
    local hFile = fileOpen(file)
    if not hFile then return end
    local buffer = ""
    while not fileIsEOF(hFile) do
        buffer = buffer .. fileRead(hFile, 500)
    end
    fileClose(hFile)

    local fn, err = loadstring(buffer)
    if not fn then
        outputDebugString(("TT: loadstring failed: %s | %s"):format(file, tostring(err)))
    else
        pcall(fn)
    end

    scriptsDownloaded = scriptsDownloaded - 1
    if scriptsDownloaded == 0 then
        triggerEvent("onClientResourceStartScript", getResourceRootElement(getThisResource()))
        triggerEvent("onClientPlayerSpawnScript", getLocalPlayer())
        _triggerServerEvent("downloadMapFinishedTT", getRootElement(), getLocalPlayer())
    end
end

local function processMap(file)
    local mapXML = xmlLoadFile(file)
    if not mapXML then return end

    local function iterNodes(tag, fn)
        local i = 0
        while true do
            local node = xmlFindChild(mapXML, tag, i)
            if not node then break end
            fn(node, i)
            i = i + 1
        end
    end

    iterNodes("object", function(node)
        local obj = createObject(
            tonumber(xmlNodeGetAttribute(node, "model")),
            tonumber(xmlNodeGetAttribute(node, "posX")),
            tonumber(xmlNodeGetAttribute(node, "posY")),
            tonumber(xmlNodeGetAttribute(node, "posZ")),
            tonumber(xmlNodeGetAttribute(node, "rotX")),
            tonumber(xmlNodeGetAttribute(node, "rotY")),
            tonumber(xmlNodeGetAttribute(node, "rotZ"))
        )
        local interior = tonumber(xmlNodeGetAttribute(node, "interior"))
        if interior then setElementInterior(obj, interior) end
        if xmlNodeGetAttribute(node, "doublesided") == "true" then setElementDoubleSided(obj, true) end
        setElementCollisionsEnabled(obj, xmlNodeGetAttribute(node, "collisions") ~= "false")
        setObjectScale(obj, tonumber(xmlNodeGetAttribute(node, "scale")) or 1.0)
        setElementAlpha(obj, tonumber(xmlNodeGetAttribute(node, "alpha")) or 255)
    end)

    iterNodes("marker", function(node)
        local r, g, b, a = 0, 0, 255, 255
        local color = xmlNodeGetAttribute(node, "color")
        if color then r, g, b, a = getColorFromString(color) end
        local marker = createMarker(
            tonumber(xmlNodeGetAttribute(node, "posX")),
            tonumber(xmlNodeGetAttribute(node, "posY")),
            tonumber(xmlNodeGetAttribute(node, "posZ")),
            xmlNodeGetAttribute(node, "type"),
            tonumber(xmlNodeGetAttribute(node, "size")),
            r, g, b, a
        )
        local interior = tonumber(xmlNodeGetAttribute(node, "interior"))
        if interior then setElementInterior(marker, interior) end
    end)

    iterNodes("vehicle", function(node)
        local veh = createVehicle(
            tonumber(xmlNodeGetAttribute(node, "model")),
            tonumber(xmlNodeGetAttribute(node, "posX")),
            tonumber(xmlNodeGetAttribute(node, "posY")),
            tonumber(xmlNodeGetAttribute(node, "posZ")),
            tonumber(xmlNodeGetAttribute(node, "rotX")),
            tonumber(xmlNodeGetAttribute(node, "rotY")),
            tonumber(xmlNodeGetAttribute(node, "rotZ")),
            xmlNodeGetAttribute(node, "numberplate") or "Vita"
        )
        setElementData(veh, "isMapTTVehicle", true)
        local interior = tonumber(xmlNodeGetAttribute(node, "interior"))
        if interior then setElementInterior(veh, interior) end
    end)

    iterNodes("racepickup", function(node, idx)
        local x          = tonumber(xmlNodeGetAttribute(node, "posX"))
        local y          = tonumber(xmlNodeGetAttribute(node, "posY"))
        local z          = tonumber(xmlNodeGetAttribute(node, "posZ"))
        local pickupType = xmlNodeGetAttribute(node, "type")
        local interior   = tonumber(xmlNodeGetAttribute(node, "interior"))

        local modelId
        if     pickupType == "vehiclechange" then pickupType = "vehicle" ; modelId = 2223
        elseif pickupType == "nitro"         then modelId = 2221
        elseif pickupType == "repair"        then modelId = 2222
        end
        if not modelId then return end

        local pickup = createElement("racePickup")
        trackedElements[#trackedElements + 1] = pickup
        setElementData(pickup, "mode", "TT")
        setElementData(pickup, "type", pickupType)
        setElementData(pickup, "id",   idx)

        if pickupType == "vehicle" then
            setElementData(pickup, "vehicle", tonumber(xmlNodeGetAttribute(node, "vehicle")))
        end

        local obj = createObject(modelId, x, y, z, 0, 0, 0)
        if interior then setElementInterior(obj, interior) end
        setElementData(pickup, "object", obj)

        local col = createColSphere(x, y, z, 3.5)
        if interior then setElementInterior(col, interior) end
        setElementData(pickup, "col", col)
        setElementData(col, "pickup", pickup)
    end)

    xmlUnloadFile(mapXML)
    fileDelete(file)
end

local function onDownloadFinish(file)
    if getElementData(getLocalPlayer(), "gameMode") ~= gamemodeDim then
        stopMap()
        return
    end

    if string.find(file, "%.lua") then
        processLua(file)
    else
        if filesDownloaded > 0 then filesDownloaded = filesDownloaded - 1 end
        if string.find(file, "%.map") then processMap(file) end
    end
end

addEvent("onClientDownloadComplete", true)
_addEventHandler("onClientDownloadComplete", getRootElement(), onDownloadFinish)

for k in pairs(_G) do
    savedGlobals[k] = true
end

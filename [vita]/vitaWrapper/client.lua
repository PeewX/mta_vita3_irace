--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 10.05.2026 - Time: 14:45
-- pewx.de // iRace-mta.de // mtasa.de
--
local trackedElements = {}
local trackedTimers   = {}
local trackedHandlers = {}
local trackedModels   = {}
local trackedTXD      = {}
local trackedShaders  = {}

local savedGlobals = {}

-- Completely blocked, map scripts must not use these
local restrictedFunctions = {
    ["setElementData"] = true,
    ["triggerServerEvent"] = true,
    ["addCommandHandler"] = true,
    ["removeCommandHandler"] = true,

    -- GUI
    ["guiCreateBrowser"] = true,
    ["guiCreateButton"] = true,
    ["guiCreateCheckBox"] = true,
    ["guiCreateComboBox"] = true,
    ["guiCreateEdit"] = true,
    ["guiCreateGridList"] = true,
    ["guiCreateMemo"] = true,
    ["guiCreateProgressBar"] = true,
    ["guiCreateRadioButton"] = true,
    ["guiCreateScrollBar"] = true,
    ["guiCreateScrollPane"] = true,
    ["guiCreateStaticImage"] = true,
    ["guiCreateTabPanel"] = true,
    ["guiCreateTab"] = true,
    ["guiCreateLabel"] = true,
    ["guiCreateWindow"] = true
}

-- Silently suppressed, return true, no side effects
local suppressedFunctions = {
    ["outputChatBox"] = true,
    ["dxDrawText"] = true,
    ["bindKey"] = true,
    ["unbindKey"] = true,
}

-- Creator functions, element is tracked and placed in the appropriate dimension
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
    _G[name] = function() outputDebugScript(("Restricted function '%s' called"):format(name)) return false end
end

for name in pairs(suppressedFunctions) do
    _G[name] = function() return true end
end

for name in pairs(creatorFunctions) do
    local orig = _G[name]
    if orig then
        _G[name] = function(...)
            local element = orig(...)
            if element then
                table.insert(trackedElements, element)
                setElementDimension(element, localPlayer.dimension)
            end
            return element
        end
    end
end

----------------------------------------------------------------

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
    table.insert(trackedHandlers, {event = event, elem = elem, fn = fn})
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

local _playSound = playSound
function playSound(soundPath, looped)
    outputDebugString("vitaWrapper: playSound: " .. soundPath)
	triggerEvent("onMapSoundReceive", root, soundPath)
end

local _createBrowser = createBrowser
function createBrowser(width, height, isLocal, transparent)
	local browser = _createBrowser(width, height, isLocal, transparent)
    table.insert(trackedElements, browser)
	return browser
end

local _engineImportTXD = engineImportTXD
function engineImportTXD(txd, modelId)
    table.insert(trackedTXD, txd)
    return _engineImportTXD(txd, modelId)
end

local _engineReplaceModel = engineReplaceModel
function engineReplaceModel(dff, modelId)
    table.insert(trackedModels, modelId)
    return _engineReplaceModel(dff, modelId)
end

local _dxCreateShader = dxCreateShader
function dxCreateShader(...)
    local shader = _dxCreateShader(...)
    if shader then table.insert(trackedElements, shader) end
    return shader
end

local _setTimer = setTimer
function setTimer(fn, interval, times, ...)
    local timer = _setTimer(fn, interval, times, ...)
    table.insert(trackedTimers, timer)
    return timer
end

----------------------------------------------------------------

function executeMapScript(scripts)
    if getResourceName(sourceResource) ~= "vitaCore" then return end

    outputDebugString("Run Map Script")

    for _, script in ipairs(scripts) do
        local exec, error = loadstring(script.content)
        if exec then
            local bool, error = pcall(exec)
            if not bool then
                outputDebugString(("vitaWrapper: pcall: %s; %s"):format(tostring(bool), tostring(error)))
                outputDebugString("vitaWraper: Failed to load script file: " .. script.filePath)
            end
        else
            outputDebugString(("vitaWrapper: loadstring: %s; %s"):format(tostring(exec), tostring(error)))
            outputDebugString("vitaWraper: Failed to load script file: " .. script.filePath)
        end
    end

    triggerEvent("onClientResourceStartScript", resourceRoot)
    triggerEvent("onClientPlayerSpawnScript", localPlayer)
end

function stopMapScript()
    if getResourceName(sourceResource) ~= "vitaCore" then return end
    outputDebugString("Stop Map Script")

    triggerEvent("onClientResourceStopScript", resourceRoot)

    for _, h     in pairs(trackedHandlers) do _removeEventHandler(h.event, h.elem, h.fn) end
    for _, elem  in pairs(trackedElements) do if isElement(elem)  then destroyElement(elem) end end
    for _, txd   in pairs(trackedTXD)     do if isElement(txd)   then destroyElement(txd)   end end
    for _, model in pairs(trackedModels)  do engineRestoreModel(model) end
    for _, sh    in pairs(trackedShaders) do if isElement(sh)    then destroyElement(sh) end end
    for _, timer in pairs(trackedTimers)  do if isTimer(timer)   then killTimer(timer) end end

    for k in pairs(_G) do
        if not savedGlobals[k] then _G[k] = nil end
    end

    trackedElements  = {}
    trackedTimers    = {}
    trackedHandlers  = {}
    trackedModels    = {}
    trackedTXD       = {}
    trackedShaders   = {}
end

for k in pairs(_G) do
    savedGlobals[k] = true
end
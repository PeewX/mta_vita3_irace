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
local trackedCOLs     = {}
local trackedLODs     = {}
local savedGlobals    = {}

----------------------------------------------------------------

-- Completely blocked, map scripts must not use these
local restrictedFunctions = {
    ["addDebugHook"]             = true,
    ["setElementData"]           = true,
    ["triggerServerEvent"]       = true,
    ["triggerLatentServerEvent"] = true,
    ["addCommandHandler"]        = true,
    ["removeCommandHandler"]     = true,
    ["fetchRemote"]              = true,
    ["call"]                     = true,
    ["loadstring"]               = true,
    ["load"]                     = true,
    ["dofile"]                   = true,
    ["loadfile"]                 = true,
    ["require"]                  = true,
    ["debug"]                    = true,
    ["coroutine"]                = true,

    -- GUI
    ["guiCreateBrowser"]     = true,
    ["guiCreateButton"]      = true,
    ["guiCreateCheckBox"]    = true,
    ["guiCreateComboBox"]    = true,
    ["guiCreateEdit"]        = true,
    ["guiCreateGridList"]    = true,
    ["guiCreateMemo"]        = true,
    ["guiCreateProgressBar"] = true,
    ["guiCreateRadioButton"] = true,
    ["guiCreateScrollBar"]   = true,
    ["guiCreateScrollPane"]  = true,
    ["guiCreateStaticImage"] = true,
    ["guiCreateTabPanel"]    = true,
    ["guiCreateTab"]         = true,
    ["guiCreateLabel"]       = true,
    ["guiCreateWindow"]      = true
}

-- Silently suppressed, return true, no side effects
local suppressedFunctions = {
    ["outputChatBox"] = true,
    ["dxDrawText"]    = true,
    ["bindKey"]       = true,
    ["unbindKey"]     = true,
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
    ["createBrowser"]        = true,
    ["dxCreateFont"]         = true,
    ["dxCreateRenderTarget"] = true,
    ["dxCreateScreenSource"] = true,
    ["dxCreateTexture"]      = true,
    ["createElement"]        = true,
    ["guiCreateFont"]        = true,
    ["createLight"]          = true,
    ["createSearchLight"]    = true,
}

----------------------------------------------------------------

local _loadstring = loadstring
local _addEventHandler = addEventHandler
local _removeEventHandler = removeEventHandler
local _playSound = playSound

local _setTimer = setTimer
local _setCloudsEnabled = setCloudsEnabled
local _setWeather = setWeather
local _engineSetModelLODDistance = engineSetModelLODDistance
local _dxCreateShader = dxCreateShader

local _engineLoadCOL = engineLoadCOL
local _engineLoadTXD = engineLoadTXD
local _engineLoadDFF = engineLoadDFF

local _engineReplaceCOL = engineReplaceCOL
local _engineImportTXD = engineImportTXD
local _engineReplaceModel = engineReplaceModel

local function restoreWrappers()
    for name in pairs(restrictedFunctions) do
        _G[name] = function(...) outputDebugString(("Restricted function called: '%s(%s)'"):format(name, inspect({...}))) return false end
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

    addEventHandler = function(event, elem, fn, propagated, priority)
        if not event or not elem or not fn then return false end
        if event == "onClientPlayerRadioSwitch" then return false end
        if event == "onClientResourceStart" then event = "onClientResourceStartScript" end
        if event == "onClientResourceStop"  then event = "onClientResourceStopScript"  end
        if event == "onClientPlayerSpawn"   then event = "onClientPlayerSpawnScript"   end

        for _, v in pairs(trackedHandlers) do
            if v.event == event and v.fn == fn then
                -- outputDebugString(("vitaWrapper: Duplicate event handler '%s'"):format(event))
                return false
            end
        end

        table.insert(trackedHandlers, {event = event, elem = elem, fn = fn})
        return _addEventHandler(event, elem, fn, propagated, priority)
    end

    removeEventHandler = function(event, elem, fn)
        if event == "onClientPlayerRadioSwitch" then return false end
        if event == "onClientResourceStart" then event = "onClientResourceStartScript" end
        if event == "onClientResourceStop"  then event = "onClientResourceStopScript"  end
        if event == "onClientPlayerSpawn"   then event = "onClientPlayerSpawnScript"   end
        for i = #trackedHandlers, 1, -1 do
            local v = trackedHandlers[i]
            if v.event == event and v.elem == elem and v.fn == fn then
                table.remove(trackedHandlers, i)
            end
        end
        return _removeEventHandler(event, elem, fn)
    end

    playSound = function(soundPath, looped)
        outputDebugString("vitaWrapper: playSound: " .. soundPath)
        triggerEvent("onMapSoundReceive", root, soundPath)
        --Todo: Play local file only if not a stream
        --return _playSound(soundPath, looped)
    end

    setWeather = function(weatherId)
        local result = _setWeather(weatherId)
        _setCloudsEnabled(false)
        return result
    end

    setCloudsEnabled = function(_)
        return _setCloudsEnabled(false)
    end

    engineLoadCOL = function(colPath)
        local col = _engineLoadCOL(colPath)
        if col then table.insert(trackedElements, col) end
        return col
    end

    engineLoadTXD = function(txdPath, filteringEnabled)
        local txd = _engineLoadTXD(txdPath, filteringEnabled)
        if not txd then outputDebugString("Failed to load TXD: " .. txdPath) end
        if txd then table.insert(trackedElements, txd) end
        return txd
    end

    engineLoadDFF = function(dffPath)
        local dff = _engineLoadDFF(dffPath)
        if dff then table.insert(trackedElements, dff) end
        return dff
    end

    engineReplaceCOL = function(col, modelId)
        local result = _engineReplaceCOL(col, modelId)
        if result then table.insert(trackedCOLs, modelId) end
        return result
    end

    engineImportTXD = function(txd, modelId)
        return _engineImportTXD(txd, modelId)
    end

    engineReplaceModel = function(dff, modelId, alphaTransparency)
        local result = _engineReplaceModel(dff, modelId, alphaTransparency)
        if result then table.insert(trackedModels, modelId) end
        return result
    end

    dxCreateShader = function(...)
        local shader = _dxCreateShader(...)
        if shader then table.insert(trackedElements, shader) end
        return shader
    end

    setTimer = function(fn, interval, times, ...)
        local timer = _setTimer(fn, interval, times, ...)
        if timer then table.insert(trackedTimers, {timer = timer, fn = fn}) end
        return timer
    end

    engineSetModelLODDistance = function(modelId, distance, extendedLod)
        local result = _engineSetModelLODDistance(modelId, distance, extendedLod)
        if result then table.insert(trackedLODs, modelId) end
        return result
    end
end

----------------------------------------------------------------

function executeMapScript(scripts)
    if getResourceName(sourceResource) ~= "vitaCore" then return end

    restoreWrappers()
    outputDebugString("Run Map Script")

    for _, script in ipairs(scripts) do
        outputDebugString("Loading script: " .. script.filePath)
        local exec, error = _loadstring(script.content)
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
    for _, timer in pairs(trackedTimers)   do if isTimer(timer.timer) then killTimer(timer.timer) end end
    for _, elem  in pairs(trackedElements) do if isElement(elem) then destroyElement(elem) end end
    for _, model in pairs(trackedModels)   do engineRestoreModel(model) engineRestoreCOL(model) end
    for _, model in pairs(trackedCOLs)     do engineRestoreCOL(model) end
    for _, model in pairs(trackedLODs)     do engineResetModelLODDistance(model) end


    for k in pairs(_G) do if not savedGlobals[k] then _G[k] = nil end end

    trackedHandlers  = {}
    trackedTimers    = {}
    trackedElements  = {}
    trackedModels    = {}
    trackedCOLs      = {}
    trackedLODs      = {}
end

for k in pairs(_G) do savedGlobals[k] = true end
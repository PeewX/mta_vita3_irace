--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 10.05.2026 - Time: 21:05
-- pewx.de // iRace-mta.de // mtasa.de
--
MapManager = inherit(Singleton)
addRemoteEvents{"loadMap", "stopMap"}

function MapManager:constructor()
    self.m_Objects      = {}
    self.m_Markers      = {}
    self.m_Vehicles     = {}
    self.m_Peds         = {}
    self.m_RacePickups  = {}
    self.m_MapLoaded    = false

    addEventHandler("loadMap", root, bind(self.onLoadMap, self))
    addEventHandler("stopMap", root, bind(self.onStopMap, self))
end

function MapManager:onLoadMap(mapData, mapSettings, mapScript, packageName, ts)
    local tts = getTimestamp()
    self:unloadMap()

    outputDebugString(("Received Map in %d ms"):format(tts - ts))

    self.m_MapData = mapData
    self.m_Settings = mapSettings
    self.m_Script = mapScript
    self.m_Package  = packageName

    self:_loadMapElements()

    if self.m_Script and self.m_Script ~= "" and exports.vitaWrapper and exports.vitaWrapper.execMapScript then
        exports.vitaWrapper:execMapScript(self.m_Script)
    end

    if self.m_Package then
        outputDebugString("Request Package " .. self.m_Package)
        Provider:getSingleton():requestFile(self.m_Package, bind(self._onPackageReady, self), function() end)
    else
        outputDebugString("No files requested")
        self:_notifyReady()
    end

    outputDebugString(("Client loaded Map in %d ms"):format(getTimestamp() - tts))
end

function MapManager:onStopMap()
    self:unloadMap()
end

function MapManager:_onPackageReady()
    outputDebugString("Request ready")
    Package.load(self.m_Package, ":vitaWrapper")
    self:_notifyReady()
end

function MapManager:_notifyReady()
    triggerServerEvent("downloadMapFinished", localPlayer)
end

function MapManager:_loadMapElements()
    local dim = localPlayer:getDimension()

    for _, v in pairs(self.m_MapData["object"] or {}) do
        local obj = createObject(v.model, v.x, v.y, v.z, v.rx, v.ry, v.rz)
        if obj then
            obj:setInterior(v.interior or 0)
            obj:setAlpha(v.alpha or 255)
            obj:setScale(v.scale or 1)
            obj:setDoubleSided(v.doublesided)
            obj:setCollisionsEnabled(v.collisions ~= "false")
            obj:setDimension(dim)
            table.insert(self.m_Objects, obj)
        end
    end

    for _, v in pairs(self.m_MapData["marker"] or {}) do
        local marker = Marker(v.x, v.y, v.z, v.markertype, v.size, getColorFromString(v.color))
        if marker then
            marker:setInterior(v.interior or 0)
            marker:setDimension(dim)
            table.insert(self.m_Markers, marker)
        end
    end

    for _, v in pairs(self.m_MapData["vehicle"] or {}) do
        local veh = Vehicle(v.model, v.x, v.y, v.z, v.rx, v.ry, v.rz, "iRace")
        if veh then
            veh:setFrozen(true)
            veh:setInterior(v.interior or 0)
            veh:setDimension(dim)
            table.insert(self.m_Vehicles, veh)
        end
    end

    for _, v in pairs(self.m_MapData["ped"] or {}) do
        local ped = Ped(v.model, v.x, v.y, v.z, v.rz)
        if ped then
            ped:setDimension(dim)
            table.insert(self.m_Peds, ped)
        end
    end

    for _, v in pairs(self.m_MapData["racepickup"]  or {}) do
        RacePickup:new(v.pickuptype, v.model, Vector3(v.x, v.y, v.z))
    end

    local s = self.m_Settings
    if s then
        if s.Time then
            local h = tonumber(gettok(s.Time, 1, ":")) or 12
            local m = tonumber(gettok(s.Time, 2, ":")) or 0
            setTime(h, m)
        end
        if s.Weather    then setWeather(tonumber(s.Weather))          end
        if s.Gravity    then setGravity(tonumber(s.Gravity))          end
        if s.Waveheight then setWaveHeight(tonumber(s.Waveheight))    end
    end
end

function MapManager:unloadMap()
    if not self.m_MapLoaded then return end

    for _, v in pairs(self.m_Objects)     do if isElement(v) then v:destroy() end end
    for _, v in pairs(self.m_Markers)     do if isElement(v) then v:destroy() end end
    for _, v in pairs(self.m_Vehicles)    do if isElement(v) then v:destroy() end end
    for _, v in pairs(self.m_Peds)        do if isElement(v) then v:destroy() end end
    for _, v in pairs(self.m_RacePickups) do if isElement(v) then v:destroy() end end

    self.m_Objects     = {}
    self.m_Markers     = {}
    self.m_Vehicles    = {}
    self.m_Peds        = {}
    self.m_RacePickups = {}
    self.m_MapLoaded   = false
end

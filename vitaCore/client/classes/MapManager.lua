--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 10.05.2026 - Time: 21:05
-- pewx.de // iRace-mta.de // mtasa.de
--

MapManager = inherit(Singleton)
addRemoteEvents{"loadMap", "stopMap"}

function MapManager:constructor()
    self.m_ContentTable = nil
    self.m_PackageName  = nil
    self.m_Objects      = {}
    self.m_Markers      = {}
    self.m_Vehicles     = {}
    self.m_Peds         = {}
    self.m_RacePickups  = {}
    self.m_MapLoaded    = false

    addEventHandler("loadMap", root, bind(self.onLoadMap, self))
    addEventHandler("stopMap", root, bind(self.onStopMap, self))
end

function MapManager:onLoadMap(contentTable, packageName)
    self:unloadMap()

    outputDebugString("Received Map")

    self.m_ContentTable = contentTable
    self.m_PackageName  = packageName

    self:_loadMapElements(contentTable)

    local script = contentTable["ClientScript"]
    if script and script ~= "" and exports.vitaWrapper and exports.vitaWrapper.execMapScript then
        exports.vitaWrapper:execMapScript(script)
    end

    if packageName then
        Provider:getSingleton():requestFile(packageName, bind(self._onPackageReady, self), function() end)
    else
        self:_notifyReady()
    end
end

function MapManager:onStopMap()
    self:unloadMap()
end

function MapManager:_onPackageReady()
    self:_notifyReady()
end

function MapManager:_notifyReady()
    triggerServerEvent("downloadMapFinished", root, localPlayer)
end

function MapManager:_loadMapElements(ct)
    local dim = localPlayer:getDimension()

    for _, v in ipairs(ct["Object"] or {}) do
        --{attributes["model"], attributes["posX"], attributes["posY"], attributes["posZ"], attributes["rotX"], attributes["rotY"], attributes["rotZ"], int, col, a, scale}
        local obj = createObject(tonumber(v[1]), tonumber(v[2]), tonumber(v[3]), tonumber(v[4]), tonumber(v[5]), tonumber(v[6]), tonumber(v[7]))
        if obj then
            local doublesided = v[9]
            if v[8]  then obj:setInterior(tonumber(v[8])) end
            if v[10] then obj:setAlpha(tonumber(v[10])) end
            if v[11] then obj:setScale(tonumber(v[11])) end
            if v[12] then obj:setDoubleSided(v[12] == "true") end

            obj:setCollisionsEnabled(v[9] ~= "false")
            obj:setDimension(dim)
            table.insert(self.m_Objects, obj)
        end
    end

    for _, v in ipairs(ct["Marker"] or {}) do
        local r, g, b, a = getColorFromString(v[6])
        local marker = Marker(tonumber(v[1]), tonumber(v[2]), tonumber(v[3]), v[4], tonumber(v[5]), r or 255, g or 255, b or 255, a or 255)
        if marker then
            if v[7] then marker:setInterior(tonumber(v[7])) end
            marker:setDimension(dim)
            table.insert(self.m_Markers, marker)
        end
    end

    for _, v in ipairs(ct["Vehicle"] or {}) do
        local veh = Vehicle(tonumber(v[1]), tonumber(v[2]), tonumber(v[3]), tonumber(v[4]),
            tonumber(v[5]), tonumber(v[6]), tonumber(v[7]))
        if veh and isElement(veh) then
            veh:setFrozen(true)
            veh:setDimension(dim)
            table.insert(self.m_Vehicles, veh)
        end
    end

    for _, v in ipairs(ct["Ped"] or {}) do
        local ped = Ped(tonumber(v[1]),
            tonumber(v[2]), tonumber(v[3]), tonumber(v[4]))
        if ped then
            ped:setDimension(dim)
            table.insert(self.m_Peds, ped)
        end
    end

    for _, v in ipairs(ct["Racepickup"] or {}) do
        RacePickup:new(v[1], v[2], Vector3(v[3], v[4], v[5]))
    end

    local s = ct["Settings"]
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

    for _, v in ipairs(self.m_Objects)     do if isElement(v) then v:destroy() end end
    for _, v in ipairs(self.m_Markers)     do if isElement(v) then v:destroy() end end
    for _, v in ipairs(self.m_Vehicles)    do if isElement(v) then v:destroy() end end
    for _, v in ipairs(self.m_Peds)        do if isElement(v) then v:destroy() end end
    for _, v in ipairs(self.m_RacePickups) do if isElement(v) then v:destroy() end end

    self.m_Objects     = {}
    self.m_Markers     = {}
    self.m_Vehicles    = {}
    self.m_Peds        = {}
    self.m_RacePickups = {}
    self.m_MapLoaded   = false
end

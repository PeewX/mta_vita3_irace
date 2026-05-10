--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 06.05.2026 - Time: 23:05
-- pewx.de // iRace-mta.de // mtasa.de
--
MapManager = inherit(Object)

function MapManager:constructor(gamemode)
    self.m_Gamemode = gamemode
    self.m_Loaded = false
    self.m_Objects = {}

    self.ContentTable = {
        ["Object"] = {},
        ["Ped"] = {},
        ["Vehicle"] = {},
        ["Racepickup"] = {},
        ["Spawnpoint"] = {},
        ["Marker"] = {},
        ["Settings"] = {},
        ["ServerScript"] = "",
        ["ClientScript"] = "",
        --["ClientFiles"] = {},
        --["ClientFileHashes"] = {},
        ["ResourceName"] = self.ResourceName
    }
end

function MapManager:load(mapResource, callback)
    if self.m_Loaded then return end
    self.m_Loaded = true
    self.m_ResourceName = mapResource

    local meta = XML.load((":%s/meta.xml"):format(self.m_ResourceName))
    if not meta then outputServerLog(("[MapManager] Error while loading %s/meta.xml"):format(self.m_ResourceName)) return end

    --//Get map datas
    local mapNode = meta:findChild("map", 0)
    local mapPath = mapNode:getAttributes()
    local mapFile = XML.load((":%s/%s"):format(self.m_ResourceName, mapPath.src))
    if not mapFile then outputServerLog(("[MapManager] Error while loading %s/%s.map"):format(self.m_ResourceName, mapPath.src)) return end

    local mapNodes = mapFile:getChildren()
    for k, v in ipairs(mapNodes) do
        local type = v:getName()
        local attributes = v:getAttributes()

        if type == "object" then
            local col = attributes["collisions"] or true
            local a = attributes["alpha"] or 255
            local int = attributes["interior"] or 0
            local scale = attributes["scale"] or 1
            table.insert(self.ContentTable["Object"], {attributes["model"], attributes["posX"], attributes["posY"], attributes["posZ"], attributes["rotX"], attributes["rotY"], attributes["rotZ"], int, col, a, scale, attributes["doublesided"]})
        elseif type == "marker" then
            table.insert(self.ContentTable["Marker"], {attributes["posX"], attributes["posY"], attributes["posZ"], attributes["type"], attributes["size"], attributes["color"], attributes["interior"], attributes["id"]})
         elseif type == "vehicle" then
            table.insert(self.ContentTable["Vehicle"], {attributes["model"], attributes["posX"], attributes["posY"], attributes["posZ"], attributes["rotX"], attributes["rotY"], attributes["rotZ"]})
        elseif type == "racepickup" then
            table.insert(self.ContentTable["Racepickup"], {attributes["type"], attributes["vehicle"], attributes["posX"], attributes["posY"], attributes["posZ"], attributes["rotX"], attributes["rotY"], attributes["rotZ"]})
        elseif type == "spawnpoint" then
            table.insert(self.ContentTable["Spawnpoint"], {attributes["vehicle"], attributes["posX"], attributes["posY"], attributes["posZ"], attributes["rotX"], attributes["rotY"], attributes["rotZ"]})
        elseif type == "ped" then
            table.insert(self.ContentTable["Ped"], {attributes["model"], attributes["posX"], attributes["posY"], attributes["posZ"], attributes["rotX"], attributes["rotY"], attributes["rotZ"]})
        else
            outputServerLog("[MapManager] Warning: Undefined type to extract in map " .. self.m_ResourceName)
        end
    end

    local packageFiles = {}
    --//Load awesome Map scripts
    local nodes = meta:getChildren()
    for k, v in ipairs(nodes) do
        if v:getName() == "script" then
            local scriptInfo = v:getAttributes()
            if scriptInfo.type and (scriptInfo.type == "client" or scriptInfo.type == "shared") then
                local path = (":%s/%s"):format(self.m_ResourceName, scriptInfo.src)
                local scriptFile = File.open(path, true)
                if scriptFile then
                    self.ContentTable["ClientScript"] = ("%s %s"):format(self.ContentTable["ClientScript"], scriptFile:read(scriptFile:getSize()))
                    scriptFile:close()
                end
            -- For security reasons, serverside scripts are not supported
            --else
            --    local scriptFile = File((":%s/%s"):format(self.m_ResourceName, scriptInfo.src), true)
            --    if scriptFile then
            --        self.ContentTable["ServerScript"] = ("%s %s"):format(self.ContentTable["ServerScript"], scriptFile:read(scriptFile:getSize()))
            --        scriptFile:close()
            --    end
            end
        elseif v:getName() == "file" then
            local fileInfo = v:getAttributes()
            if fileInfo.src then
                local path = (":%s/%s"):format(self.m_ResourceName, fileInfo.src)
                local fileFile = File.open(path, true)
                if fileFile then
                    table.insert(packageFiles, path)
                    --table.insert(self.ContentTable["ClientFiles"], {src = fileInfo.src, content = fileFile:read(fileFile:getSize())})
                    --table.insert(self.ContentTable["ClientFileHashes"], {src = fileInfo.src, hash = md5(fileFile:read(fileFile:getSize()))})
                    fileFile:close()
                end
            end
        end
    end

    local packageName = self.m_ResourceName .. ".data"
    if #packageFiles > 0 then
        outputServerLog("Files for package: " .. tostring(#packageFiles))
        Package.save(packageName, packageFiles)
        Provider:getSingleton():offerFile(packageName)
    else
        packageName = nil
    end

    --//Load Map settings
    self.ContentTable["Settings"].Weather = tonumber(get(("#%s.weather"):format(self.m_ResourceName))) or 0
    self.ContentTable["Settings"].Time = get(("#%s.time"):format(self.m_ResourceName)) or "12:00"
    self.ContentTable["Settings"].Gravity = tonumber(get(("#%s.gravity"):format(self.m_ResourceName))) or 0.008000
    self.ContentTable["Settings"].Waveheight = tonumber(get(("#%s.waveheight"):format(self.m_ResourceName))) or 0

    outputServerLog("[MapManager] Successfully loaded: " .. self.m_ResourceName)
    outputServerLog("[MapManager] Spawnpoints: " .. #self.ContentTable["Spawnpoint"])
    setTimer(function() callback(self.ContentTable, packageName) end, 500, 1)
end

function MapManager:unload()
end
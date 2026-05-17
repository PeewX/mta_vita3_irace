--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 06.05.2026 - Time: 23:05
-- pewx.de // iRace-mta.de // mtasa.de
--
MapParser = inherit(Object)

local readFuncs = {
	object = function(attributes)
		return {model = tonumber(attributes.model), x = tonumber(attributes.posX), y = tonumber(attributes.posY), z = tonumber(attributes.posZ),
			rx = tonumber(attributes.rotX), ry = tonumber(attributes.rotY), rz = tonumber(attributes.rotZ), interior = tonumber(attributes.interior), doublesided = attributes.doublesided == "true",
			alpha = tonumber(attributes.alpha), scale = tonumber(attributes.scale), collisions = attributes.collisions}
	end;
	marker = function(attributes)
		return {markertype = attributes.type, x = tonumber(attributes.posX), y = tonumber(attributes.posY), z = tonumber(attributes.posZ),
			size = tonumber(attributes.size), color = attributes.color,  interior = tonumber(attributes.interior)}
	end;
	removeWorldObject = function(attributes)
		return {radius = tonumber(attributes.radius), model = tonumber(attributes.model), lodModel = tonumber(attributes.lodModel),
			posX = tonumber(attributes.posX), posY = tonumber(attributes.posY), posZ = tonumber(attributes.posZ), interior = tonumber(attributes.interior)}
	end;
	spawnpoint = function(attributes)
		return {model = tonumber(attributes.vehicle), x = tonumber(attributes.posX), y = tonumber(attributes.posY), z = tonumber(attributes.posZ),
			rx = tonumber(attributes.rotX), ry = tonumber(attributes.rotY), rz = tonumber(attributes.rotZ)}
	end;
	racepickup = function(attributes)
		return {pickuptype = attributes.type, x = tonumber(attributes.posX), y = tonumber(attributes.posY), z = tonumber(attributes.posZ),
			rx = tonumber(attributes.rotX), ry = tonumber(attributes.rotY), rz = tonumber(attributes.rotZ), model = tonumber(attributes.vehicle)}
	end;
	vehicle = function(attributes)
		return {model = tonumber(attributes.model), x = tonumber(attributes.posX), y = tonumber(attributes.posY), z = tonumber(attributes.posZ),
            rx = tonumber(attributes.rotX), ry = tonumber(attributes.rotY), rz = tonumber(attributes.rotZ), interior = tonumber(attributes.interior)}
	end;
	ped = function(attributes)
		return {model = tonumber(attributes.model), x = tonumber(attributes.posX), y = tonumber(attributes.posY), z = tonumber(attributes.posZ),
			rz = tonumber(attributes.rotZ), interior = tonumber(attributes.interior)}
	end;
}

function MapParser:constructor(mapResource)
    self.m_ResourceName = mapResource
    self.m_Name = ""
    self.m_Author = ""
    self.m_MapData = {}
    self.m_Files = {}
    self.m_ClientScripts = {}
    self.m_Settings = {}

    outputServerLog("[MapParser] Loading " .. self.m_ResourceName)

    local meta = XML.load((":%s/meta.xml"):format(self.m_ResourceName))
    if not meta then outputServerLog(("[MapParser] Error while loading %s/meta.xml"):format(self.m_ResourceName)) return end

	local infoNode = meta:findChild("info", 0)
	if infoNode then
		self.m_Name = infoNode:getAttribute("name")
		self.m_Author = infoNode:getAttribute("author")
	end

    local mapNode = meta:findChild("map", 0)
    local mapPath = mapNode:getAttributes()
    local mapFile = XML.load((":%s/%s"):format(self.m_ResourceName, mapPath.src))
    if not mapFile then outputServerLog(("[MapParser] Error while loading %s/%s.map"):format(self.m_ResourceName, mapPath.src)) return end

    local mapNodes = mapFile:getChildren()
    for _, node in pairs(mapNodes or {}) do
		local nodeName = node:getName()
		if readFuncs[nodeName] then
            if not self.m_MapData[nodeName] then self.m_MapData[nodeName] = {} end
			table.insert(self.m_MapData[nodeName], readFuncs[nodeName](node:getAttributes()))
        else
            outputServerLog(("[MapParser] Warning: Undefined read function '%s' for map: '%s'"):format(nodeName, self.m_ResourceName))
		end
	end

    mapFile:unload()

    local nodes = meta:getChildren()
    for _, v in pairs(nodes) do
        if v:getName() == "script" then
            local scriptInfo = v:getAttributes()
            if scriptInfo.type and (scriptInfo.type == "client" or scriptInfo.type == "shared") then
                local path = (":%s/%s"):format(self.m_ResourceName, scriptInfo.src)
                local scriptFile = File.open(path, true)
                if scriptFile then
                    table.insert(self.m_ClientScripts, {filePath = path, content = scriptFile:read(scriptFile:getSize())})
                    scriptFile:close()
                end
            -- For security reasons, serverside scripts are not supported
            -- else
            --    local scriptFile = File((":%s/%s"):format(self.m_ResourceName, scriptInfo.src), true)
            --    if scriptFile then
            --        self.m_ServerScript = ("%s %s"):format(self.m_ServerScript, scriptFile:read(scriptFile:getSize()))
            --        scriptFile:close()
            --    end
            end
        elseif v:getName() == "file" then
            local fileInfo = v:getAttributes()
            if fileInfo.src then
                local path = (":%s/%s"):format(self.m_ResourceName, fileInfo.src)
                table.insert(self.m_Files, path)
            end
        end
    end

    meta:unload()

    self.m_Settings.Weather = tonumber(get(("#%s.weather"):format(self.m_ResourceName))) or 0
    self.m_Settings.Time = get(("#%s.time"):format(self.m_ResourceName)) or "12:00"
    self.m_Settings.Gravity = tonumber(get(("#%s.gravity"):format(self.m_ResourceName))) or 0.008000
    self.m_Settings.Waveheight = tonumber(get(("#%s.waveheight"):format(self.m_ResourceName))) or 0

    if #self.m_Files > 0 then
        self.m_Package = (":vitaWrapper/_mapPackages/%s.data"):format(sha256(self.m_ResourceName))
        outputServerLog("[MapParser] Files for package: " .. tostring(#self.m_Files))
        Package.save(self.m_Package, self.m_Files, true)
        Provider:getSingleton():offerFile(self.m_Package)
    end

    outputServerLog("[MapParser] Spawnpoints: " .. #self.m_MapData["spawnpoint"])
    outputServerLog("[MapParser] Successfully loaded: " .. self.m_ResourceName)
end

function MapParser:destructor()
    self.m_ResourceName = nil
    self.m_Name = nil
    self.m_Author = nil
    self.m_MapData = nil
    self.m_Files = nil
    self.m_ClientScripts = nil
    self.m_Settings = nil
end

function MapParser:getSpawns()
    return self.m_MapData.spawnpoint or {}
end
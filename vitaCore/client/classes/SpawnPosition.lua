--
-- PewX
-- Using: IntelliJ IDEA 2020 Ultimate
-- Date: 16.08.2020 - Time: 23:19
-- pewx.de // irace-mta.de
--
SpawnPosition = inherit(Singleton)
SpawnPosition.file = ":vitaCore/files/spawns.json"

addRemoteEvents{"updateSpawnPositions"}

function SpawnPosition:constructor()
    self:loadSpawns()
    self.m_Enabled = false
    self.m_Index = 0

    self.fn_SpawnPositions = bind(self.updateSpawnPositions, self)
    self.fn_OnClientMouseWheel = bind(self.mouseWheel, self)
    addEventHandler("updateSpawnPositions", localPlayer, self.fn_SpawnPositions)
    addEventHandler("onClientKey", root, self.fn_OnClientMouseWheel)
end

function SpawnPosition:loadSpawns()
    if File.exists(SpawnPosition.file) then
        local file = File.open(SpawnPosition.file, true)
        local data = file:read(file.size)
        file:close()

        if data then
            local json = fromJSON(data)
            if json then
                self.m_localSpawns = json
            end
        end
    else
        self.m_localSpawns = {}
    end
end

function SpawnPosition:updateSpawnPositions(positions, spawnId, map)
    if self.m_Changed then
        self.m_Changed = false

        local file = File.new(SpawnPosition.file)
        file:write(toJSON(self.m_localSpawns))
        file:close()
    end

    if not positions then
        self.m_Enabled = false
        return
    end

    self.m_SpawnPositions = positions
    self.m_Index = spawnId
    self.m_Map = md5(map)
    self.m_Enabled = true

    if not localPlayer.vehicle then outputChatBox("no vehicle :C") return end

    if self.m_localSpawns[self.m_Map] then
        local savedIndex = self.m_localSpawns[self.m_Map]
        if self.m_SpawnPositions[savedIndex] then
            self.m_Index = savedIndex

            local spawn = self.m_SpawnPositions[savedIndex]
            localPlayer.vehicle:setPosition(spawn.posX or spawn.x, spawn.posY or spawn.y, spawn.posZ or spawn.z)
            localPlayer.vehicle:setRotation(spawn.rotX or spawn.rx, spawn.rotY or spawn.ry, spawn.rotZ or spawn.rz)
            setCameraTarget(localPlayer)
        end
    end
end

function SpawnPosition:mouseWheel(button)
    if not self.m_Enabled then return end
    if button ~= "mouse_wheel_up" and button ~= "mouse_wheel_down" then return end
    if not localPlayer.vehicle then return end
    if localPlayer:getData("state") ~= "not ready" and localPlayer:getData("state") ~= "ready" then return end

    local int = button == "mouse_wheel_up" and 1 or -1

    self.m_Index = self.m_Index + int
    if self.m_Index < 1 then self.m_Index = #self.m_SpawnPositions end
    if self.m_Index > #self.m_SpawnPositions then self.m_Index = 1 end

    if self.m_localSpawns[self.m_Map] ~= self.m_Index then
        self.m_localSpawns[self.m_Map] = self.m_Index
        self.m_Changed = true
    end

    local spawn = self.m_SpawnPositions[self.m_Index]
    localPlayer.vehicle:setPosition(spawn.posX or spawn.x, spawn.posY or spawn.y, spawn.posZ or spawn.z)
    localPlayer.vehicle:setRotation(spawn.rotX or spawn.rx, spawn.rotY or spawn.ry, spawn.rotZ or spawn.rz)
    setCameraTarget(localPlayer)
    playSound("files/audio/swosh.mp3")
end
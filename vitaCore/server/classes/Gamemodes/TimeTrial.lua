--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 30.04.2026 - Time: 23:23
-- pewx.de // iRace-mta.de // mtasa.de
--

TimeTrial = inherit(Singleton)
addRemoteEvents {"joinTT", "playerFinishedMap", "downloadMapFinished", "mapReady", "playerAttemptStarted"}

local LOBBY_INTERVAL   = 5000            -- ms between lobby timer ticks
local LOBBY_TICKS      = 6              -- 6 * 5000 = 30 seconds of lobby wait

-- ==================== CONSTRUCTOR ====================

function TimeTrial:constructor()
    self.m_GamemodeId = GAMEMODES.TT

    -- Element used by the legacy client HUD (racemodes-client.lua reads
    -- rankingboard, mapname, nextmap, nextmapname, duration, startTick from it)
    self.m_Element = createElement("elementTT")
    self.m_Element:setData("mapname",      "loading...")
    self.m_Element:setData("nextmap",      "random")
    self.m_Element:setData("nextmapname",  "random")
    self.m_Element:setData("rankingboard", {})
    self.m_Element:setData("map",          "none")

    self.m_CurrentMap  = nil
    self.m_NextMapname = "random"

    self.m_Players        = {}   -- [player] = true
    self.m_Is_Running     = false

    -- Ranking board (parallel to DM; kept as element data for the client HUD)
    self.m_Rankingboard = {}

    addEventHandler("joinTT",               root, bind(self.onJoin,             self))
    addEventHandler("playerAttemptStarted", root, bind(self.onPlayerAttemptStarted, self))
    addEventHandler("playerFinishedMap",    root, bind(self.onPlayerFinish,     self))
    addEventHandler("downloadMapFinished",  root, bind(self.onDownloadFinished, self))
    --addEventHandler("mapReady",             root, bind(self.onMapReady,         self))
    addEventHandler("onPlayerWasted",       root, bind(self.onPlayerWasted,     self))
    addEventHandler("onPlayerQuit",         root, bind(self.onPlayerDisconnect, self))
end

-- ==================== PUBLIC API (legacy compatibility) ====================

-- Called by the admin panel via callServerFunction("loadMapTT", mapname)
function loadMapTT(mapname)
    local tt = TimeTrial:getSingleton()
    tt.m_NextMapname = mapname or "random"
    if tt.m_CurrentMap then tt:_unloadMap() end
    tt:_loadMap(tt.m_NextMapname)
end

-- Called by the admin panel via callServerFunction("killTTPlayer", player)
function killTTPlayer(player, _noSpectate)
    local tt = TimeTrial:getSingleton()
    if not tt.m_Players[player] then return end
    if tt.m_Is_Running then
        tt:_respawnPlayer(player)
    end
end

-- ==================== JOIN / QUIT ====================

function TimeTrial:onJoin()
    if self.m_Players[client] then return end

    self.m_Players[client] = true
    client:setData("gameMode",  self.m_GamemodeId)
    client:setData("state",     "joined")
    client:setData("ghostmod",  true)
    client:setData("mapname",   self.m_Element:getData("mapname"))
    client:setData("nextmap",   self.m_Element:getData("nextmap"))
    client:setDimension(self.m_GamemodeId)

    toggleControl(client, "enter_exit", false)
    bindKey(client, "F",     "down", bind(self.onRespawnKey, self))
    bindKey(client, "enter", "down", bind(self.onRespawnKey, self))

    client:callFunction("showGUIComponents", "nextMap", "mapdisplay", "money")
    client:triggerEvent("addNotification", 2, 15, 150, 190, "You joined 'TimeTrial'.")
    client:triggerEvent("hideSelection")

    outputChatBoxToGamemode(("#CCFF66:JOIN: #FFFFFF%s#FFFFFF has joined the gamemode."):format(client:getName()), self.m_GamemodeId, 255, 255, 255, true)

    if not self.m_CurrentMap then
        self:_loadMap(self.m_NextMapname)
    else
        -- Map already loaded: set up and spawn the player
        self:_setupPlayer(client)
        if self.m_Is_Running then
            -- Late join during an active map: start them with a countdown
            self:_spawnPlayerAtStart(client)
            self:_runPlayerCountdown(client)
        end
    end
end

function TimeTrial:onQuit(player)
    if not self.m_Players[player] then return end

    self:_removePlayer(player)
    self:_resetPlayerState(player)

    player:triggerEvent("stopMap")
    player:triggerEvent("ttMapStopped")
    player:triggerEvent("onMapSoundStop")

    outputChatBoxToGamemode(("#FF6666:QUIT: #FFFFFF%s#FFFFFF has left the gamemode."):format(player:getName()), self.m_GamemodeId, 255, 255, 255, true)

    if table.size(self.m_Players) == 0 then
        self:_unloadMap()
    end
end

-- Legacy compatibility...
function quitTT(player) return TimeTrial:getSingleton():onQuit(player) end

function TimeTrial:onPlayerDisconnect()
    if not self.m_Players[source] then return end
    self:_removePlayer(source)
    if table.size(self.m_Players) == 0 then
        self:_unloadMap()
    end
end

function TimeTrial:onPlayerWasted()
    if not self.m_Players[source] then return end
    if not self.m_Is_Running then return end
    self:_respawnPlayer(source)
end

function TimeTrial:onRespawnKey(player)
    if not self.m_Players[player] then return end
    if not self.m_Is_Running then return end
    if not self.m_CurrentMap then return end
    if not self.m_CurrentMap:canRespawn(player) then return end
    self:_respawnPlayer(player)
end

-- ==================== MAP LOADING ====================

function TimeTrial:_loadMap(mapname)
    self.m_Element:setData("map",     "none")
    self.m_Element:setData("mapname", "loading...")

    if self.m_NextMapname then self.m_NextMapname = nil end

    if not mapname or mapname == "random" then
        mapname = getRandomMap(GAMEMODES.DM)
    end

    self.m_CurrentMap = Map:new(self, mapname)
    self.m_Rankingboard = {}

    for player in pairs(self.m_Players) do
        self:_setupPlayer(player)
    end

    self:_startLobbyCountdown()
end

function TimeTrial:_unloadMap()
    outputServerLog("Unloading map: " .. self.m_CurrentMap:getName())
    if isTimer(self.m_LobbyTimer) then killTimer(self.m_LobbyTimer) end
    if isTimer(self.m_CountdownTimer) then killTimer(self.m_CountdownTimer) end
    if isTimer(self.m_CountdownDoneTimer) then killTimer(self.m_CountdownDoneTimer) end

    self.m_Is_Running = false

    if self.m_CurrentMap then
        delete(self.m_CurrentMap)
        self.m_CurrentMap = nil
    end

    self.m_Element:setData("rankingboard", {})
    self.m_Rankingboard = {}

    for _, veh in pairs(getElementsByType("vehicle")) do
        if veh:getData("isTTVeh") then veh:destroy() end
    end

    for player in pairs(self.m_Players) do
        player:setData("state", "dead")
        player:triggerEvent("stopMap")
        player:triggerEvent("ttMapStopped")
        player:triggerEvent("onMapSoundStop")
    end
end

-- ==================== LOBBY COUNTDOWN ====================

function TimeTrial:_startLobbyCountdown()
    if self.m_Is_Running then return end
    self.m_LobbyTimer = setTimer(bind(self._onLobbyTick, self), LOBBY_INTERVAL, LOBBY_TICKS)
end

function TimeTrial:_onLobbyTick()
    if self.m_Is_Running then return end

    local playersCount = table.size(self.m_Players)
    if playersCount == 0 then return end

    local readyCount = 0
    for p in pairs(self.m_Players) do
        if p:getData("state") == "ready" then
            readyCount = readyCount + 1
        end
    end

    local _, remaining = getTimerDetails(self.m_LobbyTimer)

    -- At halfway point show "waiting" hint
    if remaining == 3 then
        outputChatBoxToGamemode("Waiting for players...", self.m_GamemodeId, 200, 200, 200, false)
    end

    -- Start early if 80 % or more are ready, or on the last tick
    if remaining == 1 or (playersCount > 0 and readyCount / playersCount >= 0.8) then
        if isTimer(self.m_LobbyTimer) then
            killTimer(self.m_LobbyTimer)
        end
        self:_startGlobalCountdown()
    end
end

-- ==================== GLOBAL START COUNTDOWN ====================

function TimeTrial:_startGlobalCountdown()
    local duration = self.m_CurrentMap:getDuration()
    for player in pairs(self.m_Players) do
        if player:isAlive() then player:triggerEvent("ttMapStart", duration) end
    end

    -- Wait for the sound intro, then start the map and trigger client countdowns
    self.m_CountdownTimer = setTimer(function()
        for player in pairs(self.m_Players) do
            if player:isAlive() then player:triggerEvent("ttAttemptStart") end
        end

        self.m_CountdownDoneTimer = setTimer(function()
            self.m_Is_Running = true
            self.m_CurrentMap:startTimer()

            local timeLeft = self.m_CurrentMap:getTimerLeft()
            for player in pairs(self.m_Players) do
                if player:isAlive() then player:triggerEvent("ttUpdateMapTime", duration, timeLeft) end
            end
        end, 3000, 1)
    end, 3000, 1)
end

-- ==================== PLAYER SETUP / SPAWN ====================

-- Sends the map to the client and spawns the player in their vehicle (frozen
-- until the countdown ends). Called after the map resource has started.
function TimeTrial:_setupPlayer(player)
    player:callFunction("spectateEnd")

    self.m_CurrentMap:sendToPlayer(player)

    if self.m_Is_Running then return end

    self.m_CurrentMap:assignSpawn(player)
    self:_spawnPlayerAtStart(player)

    local spawns   = self.m_CurrentMap:getSpawns()
    local spawnIdx = self.m_CurrentMap:getPlayerSpawnIndex(player)
    player:triggerEvent("updateSpawnPositions", spawns, spawnIdx, self.m_CurrentMap:getName())

    player:setData("mapname", self.m_CurrentMap:getName())
    player:setData("nextmap", self.m_NextMapname)
    player:setData("state",   "not ready")
end

-- Creates a vehicle at the player's assigned spawn. Vehicle is frozen/damage-proof
-- until released by the countdown.
function TimeTrial:_spawnPlayerAtStart(player)
    if isElement(player.vehicle) then player.vehicle:destroy() end

    local spawn = self.m_CurrentMap:getPlayerSpawn(player)
    if not spawn then return end

    player:setCameraTarget()
    player:spawn(Vector3(spawn.x, spawn.y, spawn.z))
    player:setDimension(self.m_GamemodeId)

    local veh = Vehicle(spawn.model, spawn.x, spawn.y, spawn.z, spawn.rx, spawn.ry, spawn.rz, "iRace")
    veh:setDimension(self.m_GamemodeId)
    veh:setFrozen(true)
    veh:setDamageProof(true)
    veh:setColor(player:getBoughtVehicleColor())
    veh:setHeadLightColor(player:getBoughtVehicleColor())
    player:warpIntoVehicle(veh)
    veh:setData("isTTVeh",    true)
    player:setData("raceVeh",  veh)
    player:setData("ghostmod", true)
    player:setAlpha(255)
    player:setFrozen(false)
end

-- ==================== PLAYER FINISH ====================

function TimeTrial:onPlayerFinish(finishTime, splits)
    if not self.m_Players[client] then return end
    if not self.m_CurrentMap then return end
    if not finishTime then return end
    if not self.m_CurrentMap:isAttempt(client) then return end

    -- Mark attempt as over
    self.m_CurrentMap:onAttemptEnd(client)
    client:triggerEvent("ttAttemptFinished")

    -- Record toptime
    local improved, hadToptime = self.m_CurrentMap:recordFinish(client, finishTime, splits)

    if improved then
        local tInfo, tPos = self.m_CurrentMap.m_DatabaseMap:getToptimeFromPlayer(client:getID())
        outputChatBoxToGamemode((":TOPTIME:#FFFFFF %s#FFFFFF finished (%s) - position %d."):format(_getPlayerName(client), msToTimeStr(tInfo.time), tPos), self.m_GamemodeId, 148, 214, 132, true)
        if tPos <= 12 and not hadToptime then
            client:setData("TopTimes",       client:getData("TopTimes") + 1)
            client:setData("TopTimeCounter", client:getData("TopTimeCounter") + 1)
        end
        self.m_CurrentMap:broadcastToptimes(self.m_Players, client)
    else
        local timeStr = msToTimeStr(finishTime)
        client:triggerEvent("addNotification", 2, 200, 200, 50, ("Finished: %s"):format(timeStr))
        outputChatBox(("#96c87c:FINISH: #ffffff%s#ffffff finished the map (%s)."):format(client:getName(), timeStr), client, 255, 255, 255, true)
    end

    -- Points for finishing
    if not self:_hasFinished(client) then
        client:setData("Points", client:getData("Points") + 50)
        client:setData("hunterReachedCounter", client:getData("hunterReachedCounter") + 1)
        outputChatBox("#996633:Points: #ffffff You received 50 points for finishing the map.", client, 255, 255, 255, true)
        addPlayerArchivement(client, 9)
    end

    -- Add to ranking board
    self:_addRankingEntry(client, finishTime)

    client:setData("state", "dead")
    client:setAlpha(0)
    client:callFunction("spectateStart")
end

-- ==================== DOWNLOAD FINISHED ====================

function TimeTrial:onDownloadFinished()
    if not self.m_Players[client] then return end
    if not self.m_CurrentMap then return end

    self.m_CurrentMap:sendToptimes(client, true)
    self.m_CurrentMap:sendSplits(client)
    self.m_CurrentMap:sendGhost(client)

    if not self.m_Is_Running then client:setData("state", "ready") return end

    -- Late join during a running map
    local duration = self.m_CurrentMap:getDuration()
    local timeLeft = self.m_CurrentMap:getTimerLeft()
    client:triggerEvent("ttMapStarted", duration, timeLeft)

    -- Make sure spawn is assigned and vehicle exists
    if not self.m_CurrentMap.m_PlayerSpawns[client] then
        self.m_CurrentMap:assignSpawn(client)
    end
    self:_spawnPlayerAtStart(client)
    self:_runPlayerCountdown(client)
end

-- ==================== RESPAWN ====================

function TimeTrial:_respawnPlayer(player)
    if player.m_respawnCountdown then return end
    player.m_respawnCountdown = true
    if self.m_CurrentMap then
        self.m_CurrentMap:onAttemptEnd(player)
    end

    player:triggerEvent("ttAttemptFinished")

    if isElement(player.vehicle) then player.vehicle:destroy() end

    if not self.m_CurrentMap then return end
    local spawn = self.m_CurrentMap:getPlayerSpawn(player)
    if not spawn then return end

    player:setCameraTarget()
    player:spawn(Vector3(spawn.x, spawn.y, spawn.z))
    player:setDimension(self.m_GamemodeId)

    local veh = Vehicle(spawn.model, spawn.x, spawn.y, spawn.z, spawn.rx, spawn.ry, spawn.rz, "iRace")
    veh:setDimension(self.m_GamemodeId)
    veh:setFrozen(true)
    veh:setDamageProof(true)
    veh:setColor(player:getBoughtVehicleColor())
    veh:setHeadLightColor(player:getBoughtVehicleColor())
    player:warpIntoVehicle(veh)
    veh:setData("isTTVeh",    true)
    player:setData("raceVeh",  veh)
    player:setData("state",    "ready")
    player:setData("ghostmod", true)
    player:setAlpha(255)

    player:triggerEvent("updateSpawnPositionOnRespawn")
    self:_runPlayerCountdown(player)
end

function TimeTrial:_runPlayerCountdown(player)
    if not isElement(player) or not self.m_Players[player] then return end
    player:triggerEvent("ttAttemptStart")
end

-- Called when the client reports that it has unfrozen its own vehicle at GO.
-- Syncs ghost-mode off, damage-proof off, and starts the attempt timer.
function TimeTrial:onPlayerAttemptStarted()
    if not self.m_Players[client] then return end
    if not self.m_CurrentMap then return end

    if isElement(client.vehicle) then
        client.vehicle:setDamageProof(false)
        client.vehicle:setFrozen(false)   -- ensure server-side sync (MTA issue #442)
        client:setData("ghostmod", false)
    end

    client:setData("state", "alive")

    if not self.m_CurrentMap:isAttempt(client) then
        client.m_respawnCountdown = false
        if not self.m_CurrentMap:canRespawn(client) then return end
        self.m_CurrentMap:onAttemptStart(client)
    end
end

-- ==================== MAP END ====================

-- Called by Map when the timer + grace period have both elapsed.
function TimeTrial:_onMapEnd()
    if not self.m_Is_Running then return end
    self.m_Is_Running = false
    self:_showMapChangeCountdown(5, function()
        self:_unloadMap()
        setTimer(function() if table.size(self.m_Players) > 0 then self:_loadMap(self.m_NextMapname) end end, 1000, 1)
    end)
end

-- Displays "changing map in 5 … 1" via chat and calls onDone when finished.
function TimeTrial:_showMapChangeCountdown(seconds, onDone)
    if seconds <= 0 then onDone() return end
    outputChatBoxToGamemode(("#aaaaaa:changing map in %d"):format(seconds), self.m_GamemodeId, 255, 255, 255, true)
    setTimer(function() self:_showMapChangeCountdown(seconds - 1, onDone) end, 1000, 1)
end

-- ==================== RANKING ====================

function TimeTrial:_hasFinished(player)
    for i, data in pairs(self.m_Rankingboard) do
        if data.ply == player then return i end
    end
end

function TimeTrial:_addRankingEntry(player, finishTime)
    local entry = {text = ("%s#FFFFFF: %s"):format(_getPlayerName(player), msToTimeStr(finishTime)), time = finishTime, ply = player}
    local entryIndex = self:_hasFinished(player)
    if entryIndex then
        if self.m_Rankingboard[entryIndex].time < finishTime then return end
        self.m_Rankingboard[entryIndex] = entry
    else
        table.insert(self.m_Rankingboard, entry)
    end

   table.sort(self.m_Rankingboard, function(a, b) return a.time < b.time end)
    self.m_Element:setData("rankingboard", self.m_Rankingboard)
end

-- ==================== HELPERS ====================

function TimeTrial:_removePlayer(player)
    self.m_Players[player] = nil
    if self.m_CurrentMap then self.m_CurrentMap:removePlayer(player) end

    if isElement(player.vehicle) then player.vehicle:destroy() end

    player:setAlpha(0)
    player:setFrozen(true)
    unbindKey(player, "F",     "down")
    unbindKey(player, "enter", "down")
    player:setData("ghostmod", false)
    toggleControl(player, "enter_exit", true)
end

function TimeTrial:_resetPlayerState(player)
    player:setData("gameMode", 0)
    player:setDimension(0)
    player:setInterior(0)
    player:spawn(0, 0, 0)
    player:setFrozen(true)
    player:triggerEvent("stopMap")
end

--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 30.04.2026 - Time: 23:23
-- pewx.de // iRace-mta.de // mtasa.de

TimeTrial = inherit(Singleton)
addRemoteEvents {"joinTT", "quitTT", "playerGotHunterTT", "downloadMapFinished", "mapReady"}

local MAP_DURATION     = 10 * 60 * 1000  -- 10 minutes (kept in sync with Map.lua)
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

    self.m_MapManager  = MapManager:new(self.m_GamemodeId)
    self.m_CurrentMap  = nil
    self.m_NextMapname = "random"

    self.m_Players        = {}   -- [player] = true
    self.m_Is_Running     = false
    self.m_LobbyTimer     = false
    self.m_CountdownTimer = false

    -- Ranking board (parallel to DM; kept as element data for the client HUD)
    self.m_Rankingboard = {}

    addEventHandler("joinTT",               root, bind(self.onJoin,             self))
    addEventHandler("quitTT",               root, bind(self.onQuit,             self))
    addEventHandler("playerGotHunterTT",    root, bind(self.onPlayerFinish,     self))
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
    if tt.m_CurrentMap then
        tt:_endMap()
    else
        tt:_loadMap(tt.m_NextMapname)
    end
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
    local player = client
    if self.m_Players[player] then return end

    self.m_Players[player] = true
    player:setData("gameMode",  self.m_GamemodeId)
    player:setData("state",     "joined")
    player:setData("ghostmod",  true)
    player:setData("mapname",   self.m_Element:getData("mapname"))
    player:setData("nextmap",   self.m_Element:getData("nextmap"))
    player:setDimension(self.m_GamemodeId)

    toggleControl(player, "enter_exit", false)
    bindKey(player, "F",     "down", bind(self.onRespawnKey, self))
    bindKey(player, "enter", "down", bind(self.onRespawnKey, self))

    callClientFunction(player, "showGUIComponents", "nextMap", "mapdisplay", "money")
    player:triggerEvent("addNotification", 2, 15, 150, 190, "You joined 'TimeTrial'.")
    player:triggerEvent("hideSelection")

    outputChatBoxToGamemode(("#CCFF66:JOIN: #FFFFFF%s#FFFFFF has joined the gamemode."):format(player:getName()), self.m_GamemodeId, 255, 255, 255, true)

    if not self.m_CurrentMap then
        self:_loadMap(self.m_NextMapname)
    else
        -- Map already loaded: set up and spawn the player
        self:_setupPlayer(player)
        if self.m_Is_Running then
            -- Late join during an active map: start them with a countdown
            self:_spawnPlayerAtStart(player)
            self:_runPlayerCountdown(player, bind(self._onCountdownDone, self, player))
        end
    end
end

function TimeTrial:onQuit()
    local player = client
    if not self.m_Players[player] then return end

    self:_removePlayer(player)
    self:_resetPlayerState(player)

    outputChatBoxToGamemode(("#FF6666:QUIT: #FFFFFF%s#FFFFFF has left the gamemode."):format(player:getName()), self.m_GamemodeId, 255, 255, 255, true)

    if table.size(self.m_Players) == 0 then
        self:_unloadMap()
    end
end

function TimeTrial:onPlayerDisconnect()
    if not self.m_Players[source] then return end
    self:_removePlayer(source)
    if table.size(self.m_Players) == 0 then
        self:_unloadMap()
    end
end

function TimeTrial:onPlayerWasted()
    if not isInGamemode(source, self.m_GamemodeId) then return end
    if not self.m_Is_Running then return end
    self:_respawnPlayer(source)
end

function TimeTrial:onRespawnKey(player)
    if not isInGamemode(player, self.m_GamemodeId) then return end
    if not self.m_Is_Running then return end
    if not self.m_CurrentMap then return end
    if not self.m_CurrentMap:canRespawn(player) then return end
    self:_respawnPlayer(player)
end

-- ==================== MAP LOADING ====================

function TimeTrial:_loadMap(mapname)
    outputServerLog("Loading map: " .. mapname)
    self.m_Element:setData("map",     "none")
    self.m_Element:setData("mapname", "loading...")

    -- Resolve "random" – TT uses DM maps; fall back if no TT-prefix maps exist
    if mapname == "random" then
        mapname = getRandomMap(GAMEMODES.DM)
    end

    self.m_MapManager:load(mapname,
        function(contentTable, packageName)
            local resourceName = contentTable["ResourceName"] or mapname
            local displayName  = resourceName
            local spawnPositions = contentTable["Spawnpoint"]

            self.m_CurrentMap = Map:new(resourceName, displayName, spawnPositions, contentTable, self.m_GamemodeId, bind(self._onMapEnd, self))
            self.m_CurrentPackageName = packageName

            self.m_Element:setData("map",          resourceName)
            self.m_Element:setData("mapname",      displayName)
            self.m_Element:setData("nextmap",      self.m_NextMapname)
            self.m_Element:setData("nextmapname",  self.m_NextMapname)
            self.m_Element:setData("duration",     MAP_DURATION)
            self.m_Element:setData("rankingboard", {})
            self.m_Rankingboard = {}

            for player in pairs(self.m_Players) do
                self:_setupPlayer(player)
            end

            self:_startLobbyCountdown()
        end
    )
end

function TimeTrial:_unloadMap()
    if self.m_LobbyTimer and isTimer(self.m_LobbyTimer) then
        killTimer(self.m_LobbyTimer)
        self.m_LobbyTimer = false
    end
    if self.m_CountdownTimer and isTimer(self.m_CountdownTimer) then
        killTimer(self.m_CountdownTimer)
        self.m_CountdownTimer = false
    end

    self.m_Is_Running = false

    if self.m_CurrentMap then
        delete(self.m_CurrentMap)
        self.m_CurrentMap = nil
    end

    self.m_MapManager:unload()

    self.m_Element:setData("map",          "none")
    self.m_Element:setData("mapname",      "loading...")
    self.m_Element:setData("startTick",    nil)
    self.m_Element:setData("rankingboard", {})
    self.m_Rankingboard = {}

    for _, veh in pairs(getElementsByType("vehicle")) do
        if veh:getData("isTTVeh") then veh:destroy() end
    end

    for player in pairs(self.m_Players) do
        player:setData("state", "dead")
        player:triggerEvent("stopMap")
        callClientFunction(player, "hideHurry")
    end
end

-- ==================== LOBBY COUNTDOWN ====================

function TimeTrial:_startLobbyCountdown()
    if self.m_Is_Running then return end
    self.m_LobbyTimer = setTimer(bind(self._onLobbyTick, self), LOBBY_INTERVAL, LOBBY_TICKS)
end

function TimeTrial:_onLobbyTick()
    if self.m_Is_Running then return end

    local players = getGamemodePlayers(self.m_GamemodeId)
    if #players == 0 then return end

    local readyCount = 0
    for _, p in pairs(players) do
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
    if remaining == 1 or (#players > 0 and readyCount / #players >= 0.8) then
        if isTimer(self.m_LobbyTimer) then
            killTimer(self.m_LobbyTimer)
            self.m_LobbyTimer = false
        end
        self:_startGlobalCountdown(4)
    end
end

-- ==================== GLOBAL START COUNTDOWN (4-3-2-1-0) ====================

function TimeTrial:_startGlobalCountdown(id)
    local players = getGamemodePlayers(self.m_GamemodeId)

    for _, p in pairs(players) do
        if isPlayerAlive(p) then
            local x, y, z = p:getPosition()
            callClientFunction(p, "countdownClientFunc", id)

            if id == 4 then
                callClientFunction(p, "playSound", "files/audio/countstart.mp3")
                if p:getData("mapCamera") then fadeCamera(p, false, 1, 0, 0, 0) end
            elseif id == 3 then
                callClientFunction(p, "playSound", "files/audio/3.mp3")
                if p:getData("mapCamera") then
                    setCameraMatrix(p, x+10, y+7, z+3, x, y, z)
                    fadeCamera(p, true, 0, 0, 0, 0)
                end
            elseif id == 2 then
                callClientFunction(p, "playSound", "files/audio/2.mp3")
                if p:getData("mapCamera") then setCameraMatrix(p, x+4, y-1, z+2, x, y, z) end
            elseif id == 1 then
                callClientFunction(p, "playSound", "files/audio/1.mp3")
                if p:getData("mapCamera") then setCameraMatrix(p, x, y, z+15, x, y, z) end
            elseif id == 0 then
                callClientFunction(p, "playSound", "files/audio/0.mp3")
                if p:getData("mapCamera") then setCameraTarget(p, p) end
                self:_releasePlayer(p)
            end
        end
    end

    if id == 4 then
        self.m_CountdownTimer = setTimer(bind(self._startGlobalCountdown, self), 3000, 1, 3)
    elseif id == 3 then
        self.m_CountdownTimer = setTimer(bind(self._startGlobalCountdown, self), 1000, 1, 2)
    elseif id == 2 then
        self.m_CountdownTimer = setTimer(bind(self._startGlobalCountdown, self), 1000, 1, 1)
    elseif id == 1 then
        self.m_CountdownTimer = setTimer(bind(self._startGlobalCountdown, self), 1000, 1, 0)
    elseif id == 0 then
        self.m_CountdownTimer = false
        self.m_Is_Running     = true

        self.m_CurrentMap:startTimer()
        self.m_Element:setData("startTick", getTickCount())

        for player in pairs(self.m_Players) do
            callClientFunction(player, "showGUIComponents", "timeleft", "timepassed")
            if player:getData("state") == "alive" then
                self.m_CurrentMap:onAttemptStart(player)
            end
        end
    end
end

-- Called at countdown=0 to unfreeze a player who was "ready".
function TimeTrial:_releasePlayer(player)
    if player:getData("state") ~= "ready" then return end
    player:setData("state", "alive")
    local veh = getPlayerRaceVeh(player)
    if veh and isElement(veh) then
        veh:setDamageProof(false)
        veh:setFrozen(false)
    end
    player:setData("ghostmod", false)
end

-- ==================== PLAYER SETUP / SPAWN ====================

-- Sends the map to the client and spawns the player in their vehicle (frozen
-- until the countdown ends). Called after the map resource has started.
function TimeTrial:_setupPlayer(player)
    callClientFunction(player, "spectateEnd")

    player:triggerLatentEvent("loadMap", self.m_CurrentMap.m_ContentTable,  self.m_CurrentPackageName)

    if self.m_Is_Running then return end

    self.m_CurrentMap:assignSpawn(player)
    self:_spawnPlayerAtStart(player)

    player:setData("mapname", self.m_CurrentMap.m_DisplayName)
    player:setData("nextmap", self.m_NextMapname)
    player:setData("state",   "not ready")
end

-- Creates a vehicle at the player's assigned spawn. Vehicle is frozen/damage-proof
-- until released by the countdown.
function TimeTrial:_spawnPlayerAtStart(player)
    -- Destroy any existing race vehicle
    local oldVeh = getPlayerRaceVeh(player)
    if oldVeh and isElement(oldVeh) then oldVeh:destroy() end

    local spawn = self.m_CurrentMap:getPlayerSpawn(player)
    if not spawn then return end

    player:setCameraTarget()
    player:spawn(Vector3(spawn[2], spawn[3], spawn[4]))
    player:setDimension(self.m_GamemodeId)

    local veh = Vehicle(spawn[1], spawn[2], spawn[3], spawn[4], spawn[5], spawn[6], spawn[7], "Vita")
    veh:setDimension(self.m_GamemodeId)
    veh:setFrozen(true)
    veh:setDamageProof(true)
    player:warpIntoVehicle(veh)
    veh:setData("isTTVeh",    true)
    player:setData("raceVeh",  veh)
    player:setData("ghostmod", true)
    player:setAlpha(255)
    player:setFrozen(false)
end

-- ==================== PLAYER FINISH ====================

function TimeTrial:onPlayerFinish(finishTime, timings)
    local player = client
    if not player or not self.m_Players[player] then return end
    if not self.m_CurrentMap then return end
    if not finishTime then return end

    -- Mark attempt as over
    self.m_CurrentMap:onAttemptEnd(player)

    -- Record toptime
    local improved, hadToptime = self.m_CurrentMap:recordFinish(player, finishTime, timings)

    if improved then
        callClientFunction(player, "forceToptimesOpen")
        local tInfo, tPos = self.m_CurrentMap.m_DatabaseMap:getToptimeFromPlayer(player.m_ID)
        outputChatBoxToGamemode((":TOPTIME:#FFFFFF %s#FFFFFF finished (%s) - position %d."):format(_getPlayerName(player), msToTimeStr(tInfo.time), tPos), self.m_GamemodeId, 148, 214, 132, true)
        if tPos <= 12 and not hadToptime then
            player:setData("TopTimes",       player:getData("TopTimes") + 1)
            player:setData("TopTimeCounter", player:getData("TopTimeCounter") + 1)
        end
        self.m_CurrentMap:broadcastToptimes(getGamemodePlayers(self.m_GamemodeId))
    else
        local timeStr = msToTimeStr(finishTime)
        player:triggerEvent("addNotification", 2, 200, 200, 50, ("Finished: %s"):format(timeStr))
        outputChatBox(("#96c87c:FINISH: #ffffff%s#ffffff finished the map (%s)."):format(player:getName(), timeStr), player, 255, 255, 255, true)
    end

    -- Points for finishing
    player:setData("Points", player:getData("Points") + 50)
    outputChatBox("#996633:Points: #ffffff You received 50 points for finishing the map.", player, 255, 255, 255, true)
    addPlayerArchivement(player, 9)

    -- Add to ranking board
    self:_addRankingEntry(player, finishTime)

    -- Increment counter
    player:setData("hunterReachedCounter", player:getData("hunterReachedCounter") + 1)

    -- Immediately respawn (if allowed)
    if self.m_CurrentMap:canRespawn(player) then
        self:_respawnPlayer(player)
    else
        -- Grace period; this was the player's last attempt
        player:setData("state", "dead")
        player:setAlpha(0)
        callClientFunction(player, "spectateStart")
    end
end

-- ==================== DOWNLOAD FINISHED ====================

function TimeTrial:onDownloadFinished()
    local player = client
    if not isInGamemode(player, self.m_GamemodeId) then return end
    if not self.m_CurrentMap then return end

    self.m_CurrentMap:sendToptimes(player)
    callClientFunction(player, "forceToptimesOpen")
    callClientFunction(player, "allowNewHurryFunc")
    callClientFunction(player, "showGUIComponents", "timeleft", "timepassed")

    if not self.m_Is_Running then
        player:setData("state", "ready")
        return
    end

    -- Late join during a running map
    local timeLeft = self.m_CurrentMap:getTimerLeft()
    callClientFunction(player, "setStartTickLater", timeLeft)

    -- Make sure spawn is assigned and vehicle exists
    if not self.m_CurrentMap.m_PlayerSpawns[player] then
        self.m_CurrentMap:assignSpawn(player)
    end
    self:_spawnPlayerAtStart(player)
    self:_runPlayerCountdown(player, bind(self._onCountdownDone, self, player))
end

-- ==================== RESPAWN ====================

-- Destroy the player's vehicle and place them back at their spawn with a
-- 3-2-1-GO countdown before releasing.
function TimeTrial:_respawnPlayer(player)
    if player:getData("AFK") then return end
    if self.m_CurrentMap then
        self.m_CurrentMap:onAttemptEnd(player)
    end

    local oldVeh = getPlayerRaceVeh(player)
    if oldVeh and isElement(oldVeh) then oldVeh:destroy() end

    if not self.m_CurrentMap then return end
    local spawn = self.m_CurrentMap:getPlayerSpawn(player)
    if not spawn then return end

    player:setCameraTarget()
    player:spawn(Vector3(spawn[2], spawn[3], spawn[4]))
    player:setDimension(self.m_GamemodeId)

    local veh = Vehicle(spawn[1], spawn[2], spawn[3], spawn[4], spawn[5], spawn[6], spawn[7], "Vita")
    veh:setDimension(self.m_GamemodeId)
    veh:setFrozen(true)
    veh:setDamageProof(true)
    player:warpIntoVehicle(veh)
    veh:setData("isTTVeh",    true)
    player:setData("raceVeh",  veh)
    player:setData("state",    "alive")
    player:setData("ghostmod", true)
    player:setAlpha(255)

    self:_runPlayerCountdown(player, bind(self._onCountdownDone, self, player))
end

-- Individual 3-2-1-GO countdown for a single player.
-- Calls onDone() after the "GO" beat.
function TimeTrial:_runPlayerCountdown(player, onDone)
    local steps = {3, 2, 1, 0}
    local function step(i)
        if not isElement(player) or not isInGamemode(player, self.m_GamemodeId) then return end
        local id = steps[i]
        callClientFunction(player, "countdownClientFunc", id)
        callClientFunction(player, "playSound", ("files/audio/%d.mp3"):format(id))
        if id == 0 then
            onDone()
        else
            setTimer(function() step(i + 1) end, 1000, 1)
        end
    end
    step(1)
end

-- Called after a per-player countdown finishes.
function TimeTrial:_onCountdownDone(player)
    if not isElement(player) or not isInGamemode(player, self.m_GamemodeId) then return end
    if not self.m_CurrentMap or not self.m_CurrentMap:canRespawn(player) then return end

    local veh = getPlayerRaceVeh(player)
    if veh and isElement(veh) then
        veh:setDamageProof(false)
        veh:setFrozen(false)
    end
    player:setData("ghostmod", false)
    self.m_CurrentMap:onAttemptStart(player)
end

-- ==================== MAP END ====================

-- Called by Map when the timer + grace period have both elapsed.
function TimeTrial:_onMapEnd()
    if not self.m_Is_Running then return end
    self.m_Is_Running = false
    self:_showMapChangeCountdown(5, function()
        self:_unloadMap()
        setTimer(function()
            if table.size(self.m_Players) > 0 then
                self:_loadMap(self.m_NextMapname)
            end
        end, 1000, 1)
    end)
end

-- For symmetry with _onMapEnd; can be called by admin tools.
function TimeTrial:_endMap()
    if not self.m_CurrentMap then return end
    self.m_Is_Running = false
    self:_onMapEnd()
end

-- Displays "changing map in 5 … 1" via chat and calls onDone when finished.
function TimeTrial:_showMapChangeCountdown(seconds, onDone)
    if seconds <= 0 then onDone() return end
    outputChatBoxToGamemode(("#aaaaaa:changing map in %d"):format(seconds), self.m_GamemodeId, 255, 255, 255, true)
    setTimer(function() self:_showMapChangeCountdown(seconds - 1, onDone) end, 1000, 1)
end

-- ==================== RANKING ====================

function TimeTrial:_addRankingEntry(player, finishTime)
    local entry = {
        text = _getPlayerName(player) .. "#FFFFFF: " .. msToTimeStr(finishTime),
        ply  = player,
    }
    table.insert(self.m_Rankingboard, entry)
    self.m_Element:setData("rankingboard", self.m_Rankingboard)
end

-- ==================== HELPERS ====================

function TimeTrial:_removePlayer(player)
    self.m_Players[player] = nil
    if self.m_CurrentMap then self.m_CurrentMap:removePlayer(player) end

    local veh = getPlayerRaceVeh(player)
    if veh and isElement(veh) then veh:destroy() end

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
    player:triggerEvent("stopMapTT", getRootElement())
end

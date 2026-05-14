--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 13.05.2026 - Time: 23:23
-- pewx.de // iRace-mta.de // mtasa.de
--
Map = inherit(Object)

local MAP_DURATION   = 10 * 60 * 1000  -- 10 minutes
local GRACE_DURATION =      60 * 1000  -- 60 s grace after timer expires

function Map:constructor(gamemode, resourceName)
    self.m_Gamemode = gamemode
    self.m_Map = MapParser:new(resourceName)
    self.m_ResourceName = resourceName
    self.m_SpawnPositions = self.m_Map:getSpawns()

    self.m_Gamemode.m_Element:setData("map",          resourceName)
    self.m_Gamemode.m_Element:setData("mapname",      self.m_Map.m_Name)
    self.m_Gamemode.m_Element:setData("nextmap",      "random")
    self.m_Gamemode.m_Element:setData("nextmapname",  "")
    self.m_Gamemode.m_Element:setData("duration",     MAP_DURATION)

    self.m_Has_Ended    = false   -- true once the 10-min timer fires; grace period active
    self.m_MapTimer     = false
    self.m_GraceTimer   = false

    -- Per-player tracking
    self.m_PlayerSpawns      = {}  -- [player] = spawnIndex
    self.m_PlayerActive      = {}  -- [player] = true while a player is in an active attempt
    self.m_PlayerDoneAfterEnd = {} -- [player] = true once their last attempt ended (grace period)

    self.m_OnEndCallback = bind(gamemode._onMapEnd, gamemode)
    self.m_DatabaseMap = DatabaseMap:new(self.m_ResourceName)
    self.m_TimesPlayed = self.m_DatabaseMap.m_Timesplayed
end

function Map:destructor()
    if self.m_MapTimer   and isTimer(self.m_MapTimer)   then killTimer(self.m_MapTimer)   end
    if self.m_GraceTimer and isTimer(self.m_GraceTimer) then killTimer(self.m_GraceTimer) end

    if self.m_DatabaseMap then
        self.m_DatabaseMap.m_Timesplayed = self.m_DatabaseMap.m_Timesplayed + 1
        delete(self.m_DatabaseMap)
        self.m_DatabaseMap = nil
    end

    if self.m_Map then
        delete(self.m_Map)
        self.m_Map = nil
    end

    self.m_Gamemode.m_Element:setData("map",      "none")
    self.m_Gamemode.m_Element:setData("mapname",  "loading...")
    self.m_Gamemode.m_Element:setData("startTick", nil)
end

function Map:sendToPlayer(player)
    outputDebugString("Send map to player..")
    player:triggerLatentEvent("loadMap", self.m_Map.m_MapData, self.m_Map.m_Settings, self.m_Map.m_ClientScript, self.m_Map.m_Package)
end

function Map:getName()
    return self.m_Map.m_Name or self.m_ResourceName
end

-- ==================== TIMER ====================

-- Start the 10-minute map-duration timer.
-- Returns the duration in ms so the caller can persist it on the element.
function Map:startTimer()
    self.m_MapTimer   = setTimer(bind(self._onTimerExpired, self), MAP_DURATION, 1)
    return MAP_DURATION
end

function Map:_onTimerExpired()
    self.m_Has_Ended = true
    self.m_MapTimer  = false
    -- Give active players up to GRACE_DURATION to finish their current attempt.
    self.m_GraceTimer = setTimer(self.m_OnEndCallback, GRACE_DURATION, 1)
    self:_checkGraceEnd()
end

-- Cancel the grace timer and call the end callback early if no player is
-- still in an active attempt.
function Map:_checkGraceEnd()
    if not self.m_Has_Ended then return end
    for _, active in pairs(self.m_PlayerActive) do
        if active then return end
    end
    if self.m_GraceTimer and isTimer(self.m_GraceTimer) then
        killTimer(self.m_GraceTimer)
        self.m_GraceTimer = false
    end
    self.m_OnEndCallback()
end

function Map:getTimerLeft()
    if not self.m_MapTimer or not isTimer(self.m_MapTimer) then return 0 end
    local timeLeft = getTimerDetails(self.m_MapTimer)
    return timeLeft or 0
end

-- ==================== SPAWN MANAGEMENT ====================

-- Assign an unused spawn position to the player.
-- Falls back to wrapping when all spawns are taken.
-- Returns the assigned spawn index.
function Map:assignSpawn(player)
    for i, spawn in ipairs(self.m_Map:getSpawns()) do
        if not spawn.used then
            spawn.used = true
            self.m_PlayerSpawns[player] = i
            return i
        end
    end
    -- All taken: reuse position based on player count, wrap around
    local idx = ((table.size(self.m_PlayerSpawns)) % #self.m_SpawnPositions) + 1
    self.m_PlayerSpawns[player] = idx
    return idx
end

function Map:releaseSpawn(player)
    local idx = self.m_PlayerSpawns[player]
    if idx and self.m_SpawnPositions[idx] then
        self.m_SpawnPositions[idx].used = false
    end
    self.m_PlayerSpawns[player] = nil
end

-- Returns the spawn table for the player (defaults to spawn 1 if not assigned).
function Map:getPlayerSpawn(player)
    local idx = self.m_PlayerSpawns[player] or 1
    return self.m_SpawnPositions[idx] or self.m_SpawnPositions[1]
end

-- ==================== ATTEMPT TRACKING ====================

-- Call when a player leaves the start line (countdown reaches GO).
function Map:onAttemptStart(player)
    self.m_PlayerActive[player] = true
end

-- Call when a player ends their attempt (finish, manual respawn, or disconnect).
-- If the grace period is active and this was the last active player, ends the map early.
function Map:onAttemptEnd(player)
    self.m_PlayerActive[player] = false
    if self.m_Has_Ended then
        self.m_PlayerDoneAfterEnd[player] = true
        self:_checkGraceEnd()
    end
end

-- Returns false during the grace period if the player already ended their last attempt.
function Map:canRespawn(player)
    return not (self.m_Has_Ended and self.m_PlayerDoneAfterEnd[player])
end

-- ==================== TOPTIMES ====================

-- Record a finish. Returns (improved, hadToptime, oldPosition).
-- improved = true if a new or better toptime was set.
function Map:recordFinish(player, finishTime, timings)
    if timings then
        self.m_DatabaseMap:setTimings(player.m_ID, finishTime, timings)
    end
    local hadToptime, oldPosition = self.m_DatabaseMap:getToptimeFromPlayer(player.m_ID)
    local improved = self.m_DatabaseMap:addNewToptime(player.m_ID, finishTime)
    return improved, hadToptime, oldPosition
end

function Map:sendToptimes(player)
    self.m_DatabaseMap:sendToptimes(player)
end

function Map:broadcastToptimes(players)
    for _, p in pairs(players) do
        self.m_DatabaseMap:sendToptimes(p)
    end
end

-- ==================== PLAYER REMOVAL ====================

-- Clean up all state for a player (quit or disconnect).
function Map:removePlayer(player)
    self:releaseSpawn(player)
    self.m_PlayerActive[player]       = nil
    self.m_PlayerDoneAfterEnd[player] = nil
    -- If in grace period, check if we can end early now
    if self.m_Has_Ended then
        self:_checkGraceEnd()
    end
end
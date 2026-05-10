--
-- PewX (HorrorClown)
-- Map.lua - Runtime state of a single loaded TT map
--

Map = inherit(Object)

local MAP_DURATION   = 10 * 60 * 1000  -- 10 minutes
local GRACE_DURATION =      60 * 1000  -- 60 s grace after timer expires

-- Constructor
-- @param mapname        resource name (e.g. "DM-MyMap")
-- @param displayName    human-readable name from map meta
-- @param spawnPositions array of { posX,posY,posZ, rotX,rotY,rotZ, vehicle, interior, used }
-- @param contentTable   parsed map data table from MapManager
-- @param gamemodeDim    MTA dimension for this gamemode (GAMEMODES.TT = 7)
-- @param onEndCallback  function() called when the map should end
function Map:constructor(mapname, displayName, spawnPositions, contentTable, gamemodeDim, onEndCallback)
    self.m_Mapname        = mapname
    self.m_DisplayName    = displayName
    self.m_SpawnPositions = spawnPositions
    self.m_ContentTable   = contentTable
    self.m_GamemodeDim    = gamemodeDim
    self.m_OnEndCallback  = onEndCallback

    self.m_Is_Running   = false
    self.m_Has_Ended    = false   -- true once the 10-min timer fires; grace period active
    self.m_MapTimer     = false
    self.m_GraceTimer   = false

    -- Per-player tracking
    self.m_PlayerSpawns      = {}  -- [player] = spawnIndex
    self.m_PlayerActive      = {}  -- [player] = true while a player is in an active attempt
    self.m_PlayerDoneAfterEnd = {} -- [player] = true once their last attempt ended (grace period)

    self.m_DatabaseMap = DatabaseMap:new(mapname)
    self.m_TimesPlayed = self.m_DatabaseMap.m_Timesplayed
end

function Map:destructor()
    if self.m_MapTimer   and isTimer(self.m_MapTimer)   then killTimer(self.m_MapTimer)   end
    if self.m_GraceTimer and isTimer(self.m_GraceTimer) then killTimer(self.m_GraceTimer) end

    if self.m_DatabaseMap then
        self.m_DatabaseMap.m_Timesplayed = self.m_DatabaseMap.m_Timesplayed + 1
        delete(self.m_DatabaseMap)
        self.m_DatabaseMap = false
    end
end

-- ==================== TIMER ====================

-- Start the 10-minute map-duration timer.
-- Returns the duration in ms so the caller can persist it on the element.
function Map:startTimer()
    self.m_Is_Running = true
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
    for i, spawn in ipairs(self.m_SpawnPositions) do
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

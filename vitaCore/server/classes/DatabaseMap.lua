DatabaseMap = inherit(Object)

function DatabaseMap:constructor(sMapname)
    assert(type(sMapname == "string"))

    local result = sql:queryFetchSingle("SELECT * FROM ??_maps WHERE mapname = ?", sql:getPrefix(), sMapname)
    self.m_Mapname = sMapname
    self.m_MapID = result and result.ID or false
    self.m_Ratings = result and fromJSON(result.ratings) or {}
    self.m_Timesplayed = result and tonumber(result.timesplayed) or 0
    self.m_TimePlayed = result and tonumber(result.timeplayed) or 0

    if result then
        self:loadToptimes()
        self:fetchBestSplits()
        self:fetchBestGhost()
    else
        local _, _, insertID = sql:queryFetch("INSERT INTO ??_maps (mapname) VALUES (?)", sql:getPrefix(), self.m_Mapname)
        self.m_MapID = insertID
    end
end

function DatabaseMap:destructor()
    --sql:queryExec("UPDATE ??_maps SET toptimes = ?, timings = ?, ratings = ?, timesplayed = ? WHERE ID = ?", sql:getPrefix(), toJSON(self.m_Toptimes), toJSON(self.m_Timings), toJSON(self.m_Ratings), self.m_Timesplayed, self.m_MapID)
end

function DatabaseMap:loadToptimes()
    local result = sql:queryFetch("SELECT PlayerId, Time FROM ??_map_records WHERE MapId = ? ORDER BY Time ASC", sql:getPrefix(), self.m_MapID)

    local toptimes = {}
    if result then
        for _, row in ipairs(result) do
            table.insert(toptimes, {PlayerID = row.PlayerId, time = row.Time, name = Account.getNameFromID(row.PlayerId)})
        end
    end

    self.m_Toptimes = toptimes
end

function DatabaseMap:fetchBestSplits()
    local result = sql:queryFetchSingle("SELECT PlayerId, Splits FROM ??_map_records WHERE MapId = ? AND Splits IS NOT NULL ORDER BY Time ASC LIMIT 1",
        sql:getPrefix(), self.m_MapID)

    self.m_GlobalBestSplits = result and fromJSON(result.Splits) or {}
    self.m_GlobalBestSplitsBy = result and result.PlayerId or false
end

function DatabaseMap:fetchBestGhost()
    local result = sql:queryFetchSingle("SELECT PlayerId, UNCOMPRESS(Ghost) FROM ??_map_records WHERE MapId = ? AND Ghost IS NOT NULL ORDER BY Time ASC LIMIT 1",
        sql:getPrefix(), self.m_MapID)

    self.m_GlobalBestGhost = result and result.Ghost or false
    self.m_GlobalBestGhostBy = result and result.PlayerId or false
end

function DatabaseMap:addNewToptime(player, time, splits)
    -- Check if player has an existing record
    local existing = sql:queryFetchSingle("SELECT Time FROM ??_map_records WHERE MapId = ? AND PlayerId = ?",
        sql:getPrefix(), self.m_MapID, player:getID())

    -- Return if existing record is better
    if existing and tonumber(existing.Time) <= time then
        self:backfillSplitsAndGhost(player, time, splits)
        return false
    end

    -- Snapshot rang 12
    local old12 = self.m_Toptimes[12]

    local encodedSplits = toJSON(splits)
    local now = getRealTime().timestamp
    sql:queryExec("INSERT INTO ??_map_records (MapId, PlayerId, Time, Splits, Added, Updated) VALUES (?, ?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE Time = ?, Splits = ?, Updated = ?",
        sql:getPrefix(), self.m_MapID, player:getID(), time, encodedSplits, now, now, time, encodedSplits, now)

    PlayerManager:getSingleton():requestGhost(player, self.m_MapID)

    self:loadToptimes()

    -- Check for previous Top 12 player
    local new12 = self.m_Toptimes[12]
    local droppedPlayerID = nil

    if old12 and new12 and old12.PlayerID ~= new12.PlayerID then
        droppedPlayerID = old12.PlayerID
    end

    return true, droppedPlayerID
end

function DatabaseMap:removeToptime(ID)
    -- Todo
end

function DatabaseMap:backfillSplitsAndGhost(player, time, splits)
    -- Old records doesn't have splits or a ghost, add them even if the time is slower

    local result = sql:queryFetchSingle("SELECT Splits, Ghost IS NOT NULL as HasGhost FROM ??_map_records WHERE MapId = ? AND PlayerId = ?",
        sql:getPrefix(), self.m_MapID, player:getID())

    if result then
        local updateSplits, requestGhost = false, false

        if result.Splits then
            local dbSplits = fromJSON(result.Splits)
            if dbSplits and dbSplits.backfill and dbSplits.backfill > time then
                updateSplits, requestGhost = true, true
            end
        else
            updateSplits, requestGhost = true, true
        end

        if not toboolean(result.HasGhost) then requestGhost = true end

        if updateSplits then
            splits.backfill = time
            sql:queryExec("UPDATE ??_map_records SET Splits = ? WHERE MapId = ? AND PlayerId = ?", sql:getPrefix(), toJSON(splits), self.m_MapID, player:getID())
         end

        if requestGhost then
            PlayerManager:getSingleton():requestGhost(player, self.m_MapID)
        end
    end
end

function DatabaseMap:getSplitsFromPlayer(player)
    local result = sql:queryFetchSingle("SELECT Splits FROM ??_map_records WHERE MapId = ? AND PlayerId = ?",
        sql:getPrefix(), self.m_MapID, player:getID())

    return result and fromJSON(result.Splits) or {}
end

function DatabaseMap:getGhostFromPlayer(player)
    local result = sql:queryFetchSingle("SELECT UNCOMPRESS(Ghost) FROM ??_map_records WHERE MapId = ? AND PlayerId = ?",
        sql:getPrefix(), self.m_MapID, player:getID())

    return result and result["UNCOMPRESS(Ghost)"] or false
end

function DatabaseMap:getToptimeFromPlayer(PlayerID)
    for i, v in pairs(self.m_Toptimes) do
        if v.PlayerID == PlayerID then
            return v, i
        end
    end

    return false
end

function DatabaseMap:sendToptimes(player)
    -- Deprecated, use Map Class instead
    if player then
        callClientFunction(player, "setToptimeTable", self.m_Toptimes, self.m_GlobalBestSplitsBy)
    end
    return false
end

function DatabaseMap:setTimings(playerId, hunterTime, timings)
    if self.m_Timings and self.m_Timings.hunterTime then
       if self.m_Timings.hunterTime < hunterTime then
           return false
       end
    end

    self.m_Timings.PlayerID = playerId
    self.m_Timings.hunterTime = hunterTime
    self.m_Timings.timings = timings

    return true
end

function DatabaseMap:getTimings()
    if self.m_Timings and self.m_Timings.timings then
        return self.m_Timings.timings
    end

    return false
end

function DatabaseMap.getPlayerToptimeCount(player, mapPrefix)
    local result = sql:queryFetchSingle("SELECT COUNT(*) as count FROM ??_map_records r JOIN ??_maps m ON m.ID = r.MapId WHERE r.PlayerId = ? AND m.mapname LIKE '??%' AND (SELECT COUNT(*) FROM ??_map_records r2 WHERE r2.MapId = r.MapId AND r2.Time <= r.Time) <= 12",
        sql:getPrefix(), sql:getPrefix(), player:getID(), mapPrefix, sql:getPrefix())

    return result and result.count or 0
end

function DatabaseMap.saveGhost(player, MapId, GhostData)
    sql:queryExec("UPDATE ??_map_records SET Ghost = COMPRESS(?) WHERE MapId = ? AND PlayerId = ?",
        sql:getPrefix(), GhostData, MapId, player:getID())
end

-- Short getters
function DatabaseMap:getToptimes() return self.m_Toptimes end
function DatabaseMap:getBestSplits() return self.m_GlobalBestSplits end
function DatabaseMap:getBestGhost() return self.m_GlobalBestGhost end
function DatabaseMap:getBestSplitsAndGhost() return self.m_GlobalBestSplitsBy, self.m_GlobalBestGhostBy end

-- =============================================================================================================
-- Migrate toptimes
-- =============================================================================================================

local FALLBACK_2016 = 1467051550
local FALLBACK_2020 = 1597947550

local function migrateEntry(mapId, playerId, time, added, playerTimings)
    local existing = sql:queryFetchSingle("SELECT ID FROM ??_map_records WHERE MapId = ? AND PlayerId = ?", sql:getPrefix(), mapId, playerId)

    if existing then
        iprint("[Migration] Already exists MapId=" .. mapId .. " PlayerId=" .. playerId .. ", skipping")
        return "skipped"
    end

    local writeSplits = playerTimings and toJSON(playerTimings) or nil
    local result = sql:queryFetch("INSERT INTO ??_map_records (MapId, PlayerId, Time, Splits, Added, Updated) VALUES (?, ?, ?, ?, ?, ?)", sql:getPrefix(), mapId, playerId, time, writeSplits, added, added)

    if result then
        return "inserted"
    else
        iprint("[Migration] ERROR inserting MapId=" .. mapId .. " PlayerId=" .. playerId)
        return "error"
    end
end

local function migrateTimings(timings, mapId)
    assert(type(timings == "table"))
    if timings and timings.timings then
        local splits = {}
        for k, v in pairs(timings.timings) do
            if tonumber(k) then splits[tostring(tonumber(k) + 1)] = {v} -- Legacy timings id is shifted and didn't got vehicle velocity
            elseif k == "Hunter" then splits[k] = {v}
            else iprint("[Migration] Invalid timing to split index: " .. tostring(k) .. "for MapId: " .. tostring(mapId)) end
        end
        return splits
    end
end

addCommandHandler("migrate_toptimes", function()
    iprint("[Migration] Starting toptimes migration...")

    local maps = sql:queryFetch("SELECT ID, mapname, toptimes, timings FROM ??_maps", sql:getPrefix())
    if not maps then iprint("[Migration] ERROR: Could not fetch ir_maps") return end

    local inserted = 0
    local skipped  = 0
    local errors   = 0

    for _, map in ipairs(maps) do
        local mapId    = map.ID
        local mapname  = map.mapname
        local toptimes = fromJSON(map.toptimes)
        local timings  = fromJSON(map.timings)

        local timingsPlayerId = nil
        if timings and type(timings) == "table" and timings.PlayerID then
            timingsPlayerId = tonumber(timings.PlayerID)
        end

        if not toptimes or type(toptimes) ~= "table" then
            iprint("[Migration] Skipping map '" .. tostring(mapname) .. "' no valid toptimes JSON")
            skipped = skipped + 1
        else
            for _, entry in ipairs(toptimes) do
                local playerId = tonumber(entry.PlayerID)
                local time     = tonumber(entry.time)

                if not playerId or not time then
                    iprint("[Migration] Skipping invalid entry in map '" .. tostring(mapname) .. "'")
                    errors = errors + 1
                else
                    local added
                    if entry.date and tonumber(entry.date) then
                        added = tonumber(entry.date)
                    elseif timingsPlayerId and timingsPlayerId == playerId then
                        added = FALLBACK_2020
                    else
                        added = FALLBACK_2016
                    end

                    local playerTimings = (timings and timingsPlayerId == playerId) and migrateTimings(timings, mapId) or false

                    local status = migrateEntry(mapId, playerId, time, added, playerTimings)
                    if status == "inserted" then
                        inserted = inserted + 1
                    elseif status == "skipped" then
                        skipped = skipped + 1
                    else
                        errors = errors + 1
                    end
                end
            end
        end
    end

    local summary = string.format("[Migration] Done. Inserted: %d | Skipped: %d | Errors: %d", inserted, skipped, errors)
    iprint(summary)
end)
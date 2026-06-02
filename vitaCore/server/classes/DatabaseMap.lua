DatabaseMap = inherit(Object)

function DatabaseMap:constructor(sMapname)
    assert(type(sMapname == "string"))

    local result = sql:queryFetchSingle("SELECT * FROM ??_maps WHERE mapname = ?", sql:getPrefix(), sMapname)
    self.m_Mapname = sMapname
    self.m_Toptimes = result and self:loadToptimes() or {}
    self.m_Timings = result and self:loadSplits() or {}
    self.m_Ratings = result and fromJSON(result.ratings) or {}
    self.m_Timesplayed = result and tonumber(result.timesplayed) or 0
    self.m_TimePlayed = result and tonumber(result.timeplayed) or 0

    if not result then
        local _, _, insertID = sql:queryFetch("INSERT INTO ??_maps (mapname) VALUES (?)", sql:getPrefix(), self.m_Mapname)
        self.m_MapID = insertID
    else
        self.m_MapID = result.ID
    end
end

function DatabaseMap:destructor()
    sql:queryExec("UPDATE ??_maps SET toptimes = ?, timings = ?, ratings = ?, timesplayed = ? WHERE ID = ?", sql:getPrefix(), toJSON(self.m_Toptimes), toJSON(self.m_Timings), toJSON(self.m_Ratings), self.m_Timesplayed, self.m_MapID)
end

function DatabaseMap:loadToptimes()
    local result = sql:queryFetch("SELECT PlayerId, Time FROM ??_map_records WHERE MapId = ? ORDER BY Time ASC", sql:getPrefix(), self.m_MapID)

    local toptimes = {}
    if result then
        for _, row in ipairs(result) do
            table.insert(toptimes, {PlayerID = row.PlayerId, time = row.Time, name = Account.getNameFromID(row.PlayerId)})
        end
    end

    return toptimes
end

function DatabaseMap:loadSplits()
    local result = sql:queryFetchSingle("SELECT r.PlayerId, r.Splits FROM ??_map_records r WHERE r.MapId = ? AND r.Splits != '' AND r.Splits != '[[]]' ORDER BY r.Time ASC LIMIT 1",
        sql:getPrefix(), self.m_MapID)

    return result and fromJSON(result.Splits) or {}
end

function DatabaseMap:addNewToptime(PlayerID, time)
    -- Check if player has an existing record
    local existing = sql:queryFetchSingle("SELECT Time FROM ??_map_records WHERE MapId = ? AND PlayerId = ?",
        sql:getPrefix(), self.m_MapID, PlayerID)

    -- Return if existing record is better
    if existing and tonumber(existing.Time) <= time then return false end

    -- Snapshot rang 12
    local old12 = self.m_Toptimes[12]

    local now = getRealTime().timestamp
    sql:queryExec("INSERT INTO ??_map_records (MapId, PlayerId, Time, Added, Updated) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE Time = ?, Updated = ?",
        sql:getPrefix(), self.m_MapID, PlayerID, time, now, now, time, now)

    self.m_Toptimes = self:loadToptimes()

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

function DatabaseMap:getToptimeFromPlayer(PlayerID)
    for i, v in pairs(self.m_Toptimes) do
        if v.PlayerID == PlayerID then
            return v, i
        end
    end

    return false
end

function DatabaseMap:sendToptimes(player)
    if player then
        callClientFunction(player, "setToptimeTable", self.m_Toptimes, self.m_Timings.PlayerID)
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
        sql:getPrefix(), sql:getPrefix(), player, mapPrefix, sql:getPrefix())

    return result and result.count or 0
end

---- Migrate toptimes

local FALLBACK_2016 = 1467051550
local FALLBACK_2020 = 1597947550

local function migrateEntry(mapId, playerId, time, added, playerTimings)
    local existing = sql:queryFetchSingle("SELECT ID FROM ??_map_records WHERE MapId = ? AND PlayerId = ?", sql:getPrefix(), mapId, playerId)

    if existing then
        iprint("[Migration] Already exists MapId=" .. mapId .. " PlayerId=" .. playerId .. ", skipping")
        return "skipped"
    end

    local result = sql:queryFetch("INSERT INTO ??_map_records (MapId, PlayerId, Time, Splits, Ghosts, Added, Updated) VALUES (?, ?, ?, ?, ?, ?, ?)", sql:getPrefix(), mapId, playerId, time, toJSON(playerTimings), "", added, added)

    if result then
        return "inserted"
    else
        iprint("[Migration] ERROR inserting MapId=" .. mapId .. " PlayerId=" .. playerId)
        return "error"
    end
end

addCommandHandler("migrate_toptimes", function()
    outputServerLog("[Migration] Starting toptimes migration...")
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

                    local playerTimings = (timings and timingsPlayerId == playerId) and timings or {}

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
    outputServerLog(summary)
end)
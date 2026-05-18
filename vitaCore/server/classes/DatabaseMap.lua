DatabaseMap = inherit(Object)

function DatabaseMap:constructor(sMapname)
    assert(type(sMapname == "string"))
    local result = sql:queryFetchSingle("SELECT * FROM ??_maps WHERE mapname = ?", sql:getPrefix(), sMapname)
    self.m_Mapname = sMapname

    if result then
        self.m_MapID = result.ID
        self.m_Toptimes = fromJSON(result.toptimes)
        self.m_Timings = fromJSON(result.timings)
        self.m_Ratings = fromJSON(result.ratings)
        self.m_Timesplayed = tonumber(result.timesplayed)

        self:updatePlayernames()
    else
        self.m_Toptimes = {}
        self.m_Ratings = {}
        self.m_Timings = {}
        self.m_Timesplayed = 0
        local _, _, insertID = sql:queryFetch("INSERT INTO ??_maps (mapname, toptimes, timings, ratings, timesplayed) VALUES (?, ?, ?, ?, ?)", sql:getPrefix(), self.m_Mapname, toJSON(self.m_Toptimes), toJSON(self.m_Timings), toJSON(self.m_Ratings), self.m_Timesplayed)
        self.m_MapID = insertID
        return
    end
end

function DatabaseMap:destructor()
    sql:queryExec("UPDATE ??_maps SET toptimes = ?, timings = ?, ratings = ?, timesplayed = ? WHERE ID = ?", sql:getPrefix(), toJSON(self.m_Toptimes), toJSON(self.m_Timings), toJSON(self.m_Ratings), self.m_Timesplayed, self.m_MapID)
end

function DatabaseMap:updatePlayernames()
    for _, Toptime in pairs(self.m_Toptimes) do
        Toptime.name = Account.getNameFromID(Toptime.PlayerID)
    end
end

function DatabaseMap:addNewToptime(PlayerID, time)
    -- Update current huntertime if exists
    for _, v in pairs(self.m_Toptimes) do
        if v.PlayerID == PlayerID then
            if v.time > time then
                v.time = time
                v.date = getRealTime().timestamp
                self:sortToptimes()
                return true
            end
            return false
        end
    end

    -- Anyways create one
    local newHuntertime = {}
    newHuntertime.PlayerID = PlayerID
    newHuntertime.time = time
    newHuntertime.name = Account.getNameFromID(PlayerID)
    newHuntertime.date = getRealTime().timestmap

    table.insert(self.m_Toptimes, newHuntertime)
    self:sortToptimes()
    return true
end

function DatabaseMap:removeToptime(ID)
    if self.m_Toptimes[ID] then
        table.remove(self.m_Toptimes, ID)
        self:sortToptimes()
        return true
    end
    return false
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

function DatabaseMap:sortToptimes()
    -- Storage the old last toptime
    local old12 = self.m_Toptimes[12]

    -- Sort table
    table.sort(self.m_Toptimes,
        function(a, b)
            return a.time < b.time
        end
    )

    -- Storage the new last toptime
    local new12 = self.m_Toptimes[12]

    -- Update player toptimes
    if old12 ~= new12 then
        for _, Player in pairs(getElementsByType("player")) do
           if Player.m_ID == old12.PlayerID then
               if getPlayerGameMode(Player) == gGamemodeDM then
                   Player:setData("TopTimes", Player:getData("TopTimes") - 1)
                   Player:setData("TopTimeCounter", Player:getData("TopTimeCounter") - 1)
               elseif getPlayerGameMode(Player) == gGamemodeRA then
                   Player:setData("TopTimesRA", Player:getData("TopTimesRA") - 1)
               end
           end
        end
    end
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

function DatabaseMap.getPlayerToptimeCount(player, prefix)
    local toptimeCount = 0

    local result = sql:queryFetch("SELECT mapname, toptimes FROM ??_maps ORDER BY ID ASC", sql:getPrefix())
    if result then
        for _, v in pairs(result) do
            if string.find(v.mapname, prefix) then
                local toptimeTable = fromJSON(v.toptimes)
                if toptimeTable and type(toptimeTable) == "table" then
                    for i = 1, 12 do
                        if toptimeTable[i] and toptimeTable[i].PlayerID == player.m_ID then
                            toptimeCount = toptimeCount + 1
                        end
                    end
                end
            end
        end
    end

    return toptimeCount
end
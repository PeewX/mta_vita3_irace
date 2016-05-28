Core = inherit(Object)

function Core:constructor()
    outputServerLog("Initializing Core...")

    -- Small hack to get the global core immediately
    core = self

    sql = MySQL:new(MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PW, MYSQL_DB)
    board = MySQL:new(MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PW, MYSQL_BOARD_DB)
    sql:setPrefix("ir")
    board:setPrefix("wcf1")

    self:loadAccountElements()

    -- Instantiate classes (Create objects)
    PlayerManager:new()
end

function Core:destructor()
    delete(PlayerManager:getSingleton())

    delete(sql)
end

function Core:loadAccountElements()
    -- Todo: Needs improvements in further versions

    local st = getTickCount()
    local result = sql:queryFetch("SELECT * FROM ??_account ORDER BY ID ASC", sql:getPrefix())
    if result then
        for _, row in pairs(result) do
            local userData = sql:queryFetchSingle("SELECT points, level FROM ??_player WHERE ID = ?", sql:getPrefix(), row.ID)

            local accElement = createElement("userAccount")
            setElementData(accElement, "AccountName", row.AccountName)
            setElementData(accElement, "PlayerName", row.DisplayName)
            setElementData(accElement, "Points", tonumber(userData.points))
            setElementData(accElement, "Level", userData.level)
        end

        outputServerLog(("Loaded account elements in %sms"):format(math.round(getTickCount()-st, 1)))
    else
        critical_error("Failed to load account elements")
    end
end
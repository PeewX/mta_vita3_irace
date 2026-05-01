Core = inherit(Object)

function Core:constructor()
    outputServerLog("Initializing Core...")

    -- Small hack to get the global core immediately
    core = self

    sql = MySQL:new(MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PW, MYSQL_DB)
    board = MySQL:new(MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PW, MYSQL_BOARD_DB)
    sql:setPrefix("ir")
    board:setPrefix("wcf2")

    self:loadAccountElements()
    self:generatePackage()

    -- Instantiate classes (Create objects)
    PlayerManager:new()
    Migration:new()
    TimeTrial:new()
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

function Core:generatePackage()
    local files = {}
    local xml = XML.load("meta.xml")
    for _, v in pairs(xml:getChildren()) do
        if v:getName() == "irFile" then
           table.insert(files, v:getAttribute("src"))
        end
    end

    outputServerLog("Files for package: " .. tostring(#files))

    Package.save("ir.data", files)
    Provider:getSingleton():offerFile("ir.data")

    xml:unload()
end



--[[
Benutzt 11.08.2020 um IDs aus alter Datenbank in neue zu migrieren >_>
addCommandHandler("fixIds", function()
		local boardFix = MySQL:new(MYSQL_HOST, MYSQL_PORT, MYSQL_USER, MYSQL_PW, MYSQL_BOARD_DB)
		boardFix:setPrefix("wcf2")
		
		
		local result = boardFix:queryFetch("SELECT userID FROM ??_user", boardFix:getPrefix())
		
		if result then
			for _, row in pairs(result) do
				local result2 = board:queryFetchSingle("SELECT ingameID FROM ??_user WHERE userID = ?", board:getPrefix(), row.userID)
				if result2 then
					local execString = boardFix:prepareString("UPDATE ??_user SET ingameID = ? WHERE userID = ?", boardFix:getPrefix(), result2.ingameID, row.userID)
					outputServerLog(execString)
					boardFix:queryExec("UPDATE ??_user SET ingameID = ? WHERE userID = ?", boardFix:getPrefix(), result2.ingameID, row.userID)
				end
			end
		end
		
		outputServerLog("Hopefully fixed all IDs :)")
	end
)]]
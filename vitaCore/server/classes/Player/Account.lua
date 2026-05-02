Account = inherit(Object)
addRemoteEvents{"accountlogin", "accountregister"}

Account.REGISTRATION_ACTIVATED = true

function Account.login(player, username, password, pwhash)
    if (not username or not password) and not pwhash then return false end

    --board:queryFetchSingle(Async.waitFor(self), ("SELECT userID, ingameID, username, password, banned, banReason, avatarID, disableAvatar FROM ??_user WHERE %s = ?"):format(username:find("@") and "email" or "username"), board:getPrefix(), username)
    sql:queryFetchSingle(Async.waitFor(self), ("SELECT ID, AccountName, Password, Banned FROM ??_account WHERE %s = ?"):format(username:find("@") and "EMail" or "AccountName"), sql:getPrefix(), username)
    local dbResult = Async.wait()
    if not dbResult or not dbResult.ID then
        player:triggerEvent("loginfailed", "Invalid username or password")
        return false
    end

    if not pwhash then
        local salt = string.sub(dbResult.Password, 1, 29)
        pwhash = WBBC.getDoubleSaltedHash(password, salt)
		--WBBC:debugOutput({dbHash = dbResult.password, salt = salt, pwHash = pwhash})
    end

    if pwhash ~= dbResult.Password then
        player:triggerEvent("loginfailed", "Invalid username or password")
        return false
    end

    if dbResult.Banned == 1 then
        --player:triggerEvent("loginfailed", "This Account has been banned.\nReason: " .. tostring(boardResult.banReason))
        player:triggerEvent("loginfailed", "This Account has been banned.")
        return false
    end

    --[[if boardResult.ingameID == 0 then
        local serialCheck = sql:queryFetchSingle("SELECT ID FROM ??_account WHERE LastSerial = ?", sql:getPrefix(), player.serial)
        if serialCheck then
            player:triggerEvent("loginfailed", "Invalid account for this serial")
            return false
        end

        local result, _, ID = sql:queryFetch("INSERT INTO ??_account (ForumID, AccountName, DisplayName, LastSerial, LastLogin) VALUES (?, ?, ?, ?, NOW())", sql:getPrefix(),
            boardResult.userID, boardResult.username, player.name, player.serial)

        if not result or not ID then
            player:triggerEvent("addNotification", 1, 200, 50, 50, "Internal error while creating account")
            return false
        end

        boardResult.ingameID = ID
        sql:queryExec("INSERT INTO ??_player (ID, archivements) VALUES (?, ?)", sql:getPrefix(), ID, toJSON({}))
        board:queryExec("UPDATE ??_user SET ingameID = ? WHERE userID = ?", board:getPrefix(), ID, boardResult.userID)

        local accElement = createElement("userAccount")
        setElementData(accElement, "AccountName", boardResult.username)
        setElementData(accElement, "PlayerName", player.name)
        setElementData(accElement, "Points", 0)
        setElementData(accElement, "Level", "User")
    end]]

    if Player.getFromID(dbResult.ID) then
        player:triggerEvent("loginfailed", "This account is already in use")
        return false
    end

    sql:queryExec("UPDATE ??_account SET LastSerial = ?, LastLogin = NOW() WHERE ID = ?", sql:getPrefix(), player.serial, dbResult.ID)

    --[[if boardResult.disableAvatar == 0 then
       local result = board:queryFetchSingle("SELECT fileHash FROM ??_user_avatar WHERE avatarID = ?", board:getPrefix(), boardResult.avatarID)
        if result and result.fileHash then
            boardResult.avatarFileHash = result.fileHash
        end
    end]]

    player:triggerEvent("loginsuccess", pwhash)
    player.m_Account = Account:new(dbResult.ID, dbResult.AccountName, player)
    Player.Map[dbResult.ID] = player
end
addEventHandler("accountlogin", getRootElement(), function(...) Async.create(Account.login)(client, ...) end)

function Account.register(player, username, password, email)
    if player:getAccount() then return false end
    if not username or not password or not email then return false end

    if not Account.REGISTRATION_ACTIVATED then
		player:triggerEvent("registerfailed", "Registration is currently disabled.", player)
		return false
	end

    -- Some sanity checks on the username
	-- Require at least 1 letter and a length of 3
	if not username:match("^[a-zA-Z0-9_.]*$") or #username < 3 or #username > 22 then
		player:triggerEvent("registerfailed", "Invalid username. Only alphanumeric chars are allowed!", player)
		return false
	end

	if #password < 6 then
		player:triggerEvent("registerfailed", "Password must be at least 6 characters long", player)
		return false
	end

    -- Validate mail
	if not email:match("^[%w._-]+@[%w._-]+%.%w+$") or #email > 50 then
		player:triggerEvent("registerfailed", "Invalid E-Mail", player)
		return false
	end

    -- Check Serial
    local serialCheck = sql:queryFetchSingle("SELECT ID FROM ??_account WHERE LastSerial = ?", sql:getPrefix(), player.serial)
    if serialCheck then
        player:triggerEvent("registerfailed", "You already have an account")
        return false
    end

    -- Check username is in use
    local usernameCheck = sql:queryFetchSingle("SELECT ID FROM ??_account WHERE AccountName = ?", sql:getPrefix(), username)
    if usernameCheck then
        player:triggerEvent("registerfailed", "This Username is already in use")
        return false
    end

    -- Check mail is in use
    local emailCheck = sql:queryFetchSingle("SELECT ID FROM ??_account WHERE EMail = ?", sql:getPrefix(), email)
    if emailCheck then
        player:triggerEvent("registerfailed", "This E-Mail is already in use")
        return false
    end

    local result, pwHash, ID = Account.createAccount(player, username, email, password)
    if result then
        player:triggerEvent("loginsuccess", pwHash)
        player.m_Account = Account:new(ID, username, player)
        Player.Map[ID] = player
    else
        player:triggerEvent("registerfailed", "Internal error while create account")
    end
end
addEventHandler("accountregister", getRootElement(), function(...) Async.create(Account.register)(client, ...) end)

function Account.createAccount(player, username, email, password)
    local salt = WBBC.getRandomSalt()
    local passwordHash = WBBC.getDoubleSaltedHash(password, salt)
    local result, _, ID = sql:queryFetch("INSERT INTO ??_account (ForumID, AccountName, DisplayName, EMail, Password, LastSerial, LastLogin, RegistrationDate) VALUES (-1, ?, ?, ?, ?, ?, NOW(), ?)", sql:getPrefix(),
        username, player.name, email, passwordHash, player.serial, getTimestamp())
    sql:queryExec("INSERT INTO ??_player (ID, archivements) VALUES (?, ?)", sql:getPrefix(), ID, toJSON({}))

    -- vita3 is using stupid elementData for storage and needs this shit.. yay!
    local accElement = createElement("userAccount")
    setElementData(accElement, "AccountName", username)
    setElementData(accElement, "PlayerName", player.name)
    setElementData(accElement, "Points", 0)
    setElementData(accElement, "Level", "User")

    return result, passwordHash, ID
end

function Account:constructor(id, accountname, player)
    self.m_ID = id
    self.m_Accountname = accountname
    self.m_Player = player

    player.m_ID = self.m_ID
    player.m_Accountname = self.m_Accountname

    player:getMigrationState()
    player:load()
    player:triggerEvent("retrieveInfo", {ID = id, Accountname = accountname, Migrated = player.m_Migrated})
end

function Account.getNameFromID(id)
    local player = Player.getFromID(id)
    if player and isElement(player) then
        return player:getName()
    end

    local row = sql:queryFetchSingle("SELECT DisplayName FROM ??_account WHERE ID = ?", sql:getPrefix(), id)
    return row and row.DisplayName
end

function Account.ForumToMTADB(source)
    if source.type ~= "console" then return end

    local result = sql:queryFetch("SELECT ID, ForumID, AccountName FROM ??_account", sql:getPrefix())
    if not result then return outputServerLog("Error while getting all accounts") end
    for _, account in pairs(result) do
        if tonumber(account.ID) then
            local boardAccount = board:queryFetchSingle("SELECT username, password, email, banned, registrationDate FROM ??_user WHERE ingameID = ?", board:getPrefix(), account.ID)
            if boardAccount then
                if account.AccountName ~= boardAccount.username then
                    local accName = sql:queryFetch("UPDATE ??_account SET AccountName = ? WHERE ID = ?", sql:getPrefix(), boardAccount.username, account.ID)
                    if not accName then return outputServerLog(("Error while update AccountName '%s' ->  '%s'"):format(tostring(account.AccountName), tostring(boardAccount.username))) end
                    outputServerLog(("Update AccountName '%s' ->  '%s'"):format(account.AccountName, boardAccount.username))
                end
                local mainUpdate = sql:queryFetch("UPDATE ??_account SET EMail = ?, Password = ?, RegistrationDate = ?, Banned = ? WHERE ID = ?", sql:getPrefix(), boardAccount.email, boardAccount.password, boardAccount.registrationDate, boardAccount.banned, account.ID)
                if not mainUpdate then return outputServerLog(("Error while migrate user Id '%s'"):format(tostring(account.ID))) end
                outputServerLog(("Migrated %s (%s)"):format(boardAccount.username, account.ID))
            end
        else
            outputServerLog("Invalid user ID for: " .. tostring(account.AccountName))
        end
    end
end
addCommandHandler("forumMig", Account.ForumToMTADB)

--[[
ALTER TABLE `ir_account` ADD `EMail` VARCHAR(191) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL AFTER `DisplayName`;
ALTER TABLE `ir_account` ADD `Password` VARCHAR(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL AFTER `EMail`;
ALTER TABLE `ir_account` ADD `RegistrationDate` INT(11) NOT NULL DEFAULT '0' AFTER `LastLogin`;
ALTER TABLE `ir_account` ADD `Banned` TINYINT(1) NOT NULL DEFAULT '0' AFTER `RegistrationDate`;
]]
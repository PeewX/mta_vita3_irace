PlayerManager = inherit(Singleton)
addRemoteEvents{"clientSendGhost", "playerReady"}

function PlayerManager:constructor()
    self.m_ReadyPlayers = {}
    self.m_Uploads = {}

    -- Register events
    addEventHandler("onPlayerConnect", root, bind(self.playerConnect, self))
    addEventHandler("onPlayerJoin", root, bind(self.playerJoin, self))
    addEventHandler("onPlayerQuit", root, bind(self.playerQuit, self))
    addEventHandler("playerReady", root, bind(self.playerReady, self))
    addEventHandler("clientSendGhost", root, bind(self.receiveGhost, self))
end

function PlayerManager:destructor()
    for _, v in pairs(getElementsByType"player") do
        v:delete()
    end
end

-----------------------------------------
--------       Event zone       --------- --Todo
-----------------------------------------

function PlayerManager:playerConnect(name, ip, username, serial)
    --Player Class, check if serial is banned.
end

function PlayerManager:playerJoin()

end

function PlayerManager:playerQuit()

end

function PlayerManager:playerReady()
    table.insert(self.m_ReadyPlayers, client)
end

function PlayerManager:requestGhost(player, MapId)
    local uploadId = ("%d%d"):format(player:getID(), MapId)
    self.m_Uploads[uploadId] = MapId
    player:triggerEvent("serverRequestGhost", uploadId)
end

function PlayerManager:receiveGhost(uploadId, ghostData)
    if not uploadId or not ghostData then return end
    if not self.m_Uploads[uploadId] then return end

    local MapId = self.m_Uploads[uploadId]
    DatabaseMap.saveGhost(client, MapId, ghostData)
    self.m_Uploads[uploadId] = nil
end
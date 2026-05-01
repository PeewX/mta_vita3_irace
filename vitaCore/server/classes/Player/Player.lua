Player = {}
inherit(DatabasePlayer, Player)
registerElementClass("player", Player)
Player.Map = {}

function Player:constructor()
    setPedStat(self, 160, 1000)
    setPedStat(self, 229, 1000)
    setPedStat(self, 230, 1000)
end

function Player:virtual_constructor()
    self.m_ID = -1
end

function Player:destructor()
    self:addArchivement(37)
    self:save()

    if self.m_ID > 0 then
        Player.Map[self.m_ID] = nil
    end

    if getPlayerGameMode(self) == 0 then return true end
    callServerFunction(gRaceModes[getPlayerGameMode(self)].quitfunc, self)
end

function Player:triggerEvent(ev, ...)
    triggerClientEvent(self, ev, self, ...)
end

function Player:callFunction(...)
    callClientFunction(self, ...)
end

function Player:addArchivement(id)
    addPlayerArchivement(self, id)
end

function Player:hasRights(level)
    if ADMIN_LEVEL[self.m_Level] >= ADMIN_LEVEL[level] then
        return true
    end

    return false
end

function Player.getFromID(id)
    return Player.Map[id]
end

function Player:updateTeam()
    if self.m_Level == "Leader" then
        self:setTeam(leaderTeam)
    elseif self.m_Level == "CoLeader" then
        self:setTeam(coleaderTeam)
    elseif self.m_Level == "Moderator" then
        self:setTeam(moderatorTeam)
    elseif self.m_Level == "SeniorMember" then
        self:setTeam(seniorTeam)
    elseif self.m_Level == "Member" then
        self:setTeam(memberTeam)
    elseif self.m_Level == "Recruit" then
        self:setTeam(recruitTeam)
    else
        self:setTeam(nil)
    end
end
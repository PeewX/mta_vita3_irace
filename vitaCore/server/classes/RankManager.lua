--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 05.05.2026 - Time: 22:43
-- pewx.de // iRace-mta.de // mtasa.de
--
RankManager = inherit(Singleton)

function RankManager:constructor()
    self.m_LastRank = {}   -- [accountName] = last rank pushed to client
end

-- Call once after a player has loaded (AccountName element data must be set).
-- Sets their initial rankScoreboard without triggering a notification.
function RankManager:onPlayerLogin(player)
    local accountName = player:getData("AccountName")
    if not accountName then return end

    local rankings = self:_buildRankings()
    local rank     = rankings[accountName]
    if not rank then return end

    player:setData("rankScoreboard", tostring(rank))
    self.m_LastRank[accountName] = rank
end

-- Recomputes all ranks from current userAccount Points, pushes updated
-- rankScoreboard to every online player, and fires rank-change notifications.
function RankManager:updateAndNotify()
    local rankings = self:_buildRankings()

    for _, player in pairs(getElementsByType("player")) do
        local accountName = player:getData("AccountName")
        if accountName then
            local rank = rankings[accountName]
            if rank then
                local prevRank = self.m_LastRank[accountName]
                player:setData("rankScoreboard", tostring(rank))
                if prevRank and prevRank ~= rank then
                    if rank < prevRank then
                        player:triggerEvent("addNotification", 3, 120, 100, 18, "Rank Up! New rank: " .. rank)
                    else
                        player:triggerEvent("addNotification", 3, 120, 100, 18, "Lost a rank. New rank: " .. rank)
                    end
                end
                self.m_LastRank[accountName] = rank
            end
        end
    end
end

-- Builds a lookup table {[accountName] = rank} from all userAccount elements,
-- sorted by Points DESC then AccountName ASC for a stable tie-break.
function RankManager:_buildRankings()
    local list = {}
    for _, acc in ipairs(getElementsByType("userAccount")) do
        local name   = acc:getData("AccountName")
        local points = tonumber(acc:getData("Points")) or 0
        if name then
            table.insert(list, {accountName = name, points = points})
        end
    end

    table.sort(list, function(a, b)
        if a.points ~= b.points then return a.points > b.points end
        return a.accountName < b.accountName
    end)

    local map = {}
    for i, entry in ipairs(list) do
        map[entry.accountName] = i
    end
    return map
end
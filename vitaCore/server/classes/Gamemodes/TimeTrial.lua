--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 30.04.2026 - Time: 23:23
-- pewx.de // iRace-mta.de // mtasa.de
--
TimeTrial = inherit(Singelton)
addRemoteEvents {"joinTT", "quitTT"}

function TimeTrial:constructor()
    self.GamemodeId = GAMEMODES.TT
    self.Is_Running = false
    self.Map_Timer = false
    self.Players = {}
    self.MapQueue = {}

    addEventHandler("joinTT", root, bind(self.join, self))
    addEventHandler("quitTT", root, bind(self.quit, self))
end

function TimeTrial:join()
    if getPlayerGameMode(client) == self.GamemodeId then return false end
    
    if table.size(self.Players) == 0 then
        self:loadNextMap()
    end

    self.Players[client] = true
    client:setDimension(self.GamemodeId)
    client:triggerEvent("addNotification", 2, 15, 150, 190, "Joined TimeTrial")
    client:triggerEVent("hideSelection")
    client:callFunction("showGUIComponents", "nextMap", "mapdisplay", "money")

    outputChatBoxToGamemode(("#CCFF66:JOIN: #FFFFFF%s#FFFFFF joined!"):format(client:getName()), self.GamemodeId, 255, 255, 255, true)

    toggleControl(client, "enter_exit", false)
    bindKey(client, "F", "down", bind(self.respawn, self))
    bindKey(client, "enter", "down", bind(self.respawn, self))
end

function TimeTrial:quit()
    self.Players[client] = nil
    -- Todo: Unload map if lobby is empty
end

function TimeTrial:respawn(player)
    if not isInGamemode(player, self.GamemodeId) then return end
    if not self.Is_Running then return end

    -- Respawn, start countdown for player
end
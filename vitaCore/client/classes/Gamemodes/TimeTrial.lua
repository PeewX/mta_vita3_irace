--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 25.05.2026 - Time: 18:42
-- pewx.de // iRace-mta.de // mtasa.de
--
TimeTrial = inherit(Singleton)
addRemoteEvents{"ttMapStart", "ttUpdateMapTime", "ttAttemptStarted", "ttAttemptFinished", "ttMapStopped", "ttAttemptStart", "serverRequestGhost", "serverSendGhost"}

function TimeTrial:constructor()
    self.m_Countdown   = Countdown:new()
    self.m_TimerWidget = TimerWidget:new()

    self.m_BestTry = 0
    self.m_GhostUploads = {}

    self.m_Countdown:setHook(bind(self.onCountdownFinished, self))

    addEventHandler("ttMapStart",         localPlayer, bind(self.onMapStart,           self))
    addEventHandler("ttUpdateMapTime",    localPlayer, bind(self.onUpdateMapTime,      self))
    addEventHandler("ttAttemptStart",     localPlayer, bind(self.onAttemptStart,       self))
    addEventHandler("ttAttemptFinished",  localPlayer, bind(self.onAttemptFinished,    self))
    addEventHandler("ttMapStopped",       localPlayer, bind(self.onMapStopped,         self))
    addEventHandler("serverRequestGhost", localPlayer, bind(self.onServerRequestGhost, self))
    addEventHandler("serverSendGhost",    localPlayer, bind(self.onServerSendGhost,    self))
end

function TimeTrial:onMapStart(duration)
    RaceTimer:getSingleton():init(duration)
    self.m_TimerWidget:show()
    playSound("files/audio/countstart.mp3")

    self.m_BestTry = 0
    self.m_GhostRecord = MovementRecorder:new(localPlayer.vehicle:getModel())
    self.m_GhostPlayback = MovementRecorder:new(localPlayer.vehicle:getModel())

    if self.m_ReceivedGhost then
        self.m_GhostPlayback:setEncodedRecord(self.m_ReceivedGhost)
    end
end

function TimeTrial:onUpdateMapTime(duration, timeLeft)
    RaceTimer:getSingleton():updateMapTime(duration, timeLeft)
end

function TimeTrial:onAttemptStart()
    self.m_Countdown:start()
end

function TimeTrial:onCountdownFinished()
    if not localPlayer.vehicle then return end
    localPlayer.vehicle:setFrozen(false)
    RaceTimer:getSingleton():startAttempt()
    Splits:getSingleton():reset()

    self.m_GhostRecord:startRecording()
    self.m_GhostPlayback:startPlayback()

     triggerServerEvent("playerAttemptStarted", localPlayer)
end

function TimeTrial:onAttemptFinished()
    self.m_Countdown:stop()
    RaceTimer:getSingleton():finishAttempt()

    self.m_GhostRecord:stopRecording()
    self.m_GhostPlayback:stopPlayback()

    if self.m_ReceivedGhost then return end
    local checkpointCount = table.size(Splits:getSingleton():getRecord())
    if checkpointCount > self.m_BestTry then
        self.m_GhostPlayback.m_Record = self.m_GhostRecord.m_Record
        self.m_BestTry = checkpointCount
    end
end

function TimeTrial:onServerRequestGhost(Id)
    if not localPlayer:isGamemode(GAMEMODES.TT) then return end
    if self.m_GhostRecord:isRecording() then outputDebugString("Error. Server requested ghost while recording") return end

    -- Cancel previous unfinished uploads with same Id
    if self.m_GhostUploads[Id] then
        local status = getLatentEventStatus(self.m_GhostUploads[Id])
        if status then cancelLatentEvent(self.m_GhostUploads[Id]) end
    end

    triggerLatentServerEvent("clientSendGhost", 2000000, false, localPlayer, Id, self.m_GhostRecord:getEncodedRecord())
    self.m_GhostUploads[Id] = #getLatentEventHandles()
end

function TimeTrial:onServerSendGhost(ghostData, playerId)
    if not localPlayer:isGamemode(GAMEMODES.TT) then return end
    if not ghostData then return end

    self.m_ReceivedGhost = ghostData
end

function TimeTrial:onMapStopped()
    self.m_ReceivedGhost = false
    self.m_Countdown:stop()
    self.m_TimerWidget:hide()
    delete(self.m_GhostRecord)
    delete(self.m_GhostPlayback)
end

-- TODO (future migration from racemodes-client.lua):
--   - Rankingboard rendering (dxDrawText list, currently in onClientRender ~L163-L193)
--   - Map/NextMap/Money dxText labels at bottom-left (L16-L21)
--   - Spectator count overlay (L185-L192)
--   - infoText / -Text / +Text overlays (L285-L294)

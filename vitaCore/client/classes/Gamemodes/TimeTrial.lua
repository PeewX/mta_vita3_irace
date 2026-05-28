--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 25.05.2026 - Time: 18:42
-- pewx.de // iRace-mta.de // mtasa.de
--
TimeTrial = inherit(Singleton)
addRemoteEvents{"ttMapStarted", "ttAttemptStarted", "ttAttemptFinished", "ttMapStopped", "ttAttemptStart"}

function TimeTrial:constructor()
    self.m_Countdown   = Countdown:new()
    self.m_TimerWidget = TimerWidget:new()

    self.m_Countdown:setHook(bind(self.onCountdownFinished, self))

    addEventHandler("ttMapStarted",      localPlayer, bind(self.onMapStarted,      self))
    addEventHandler("ttAttemptStart",    localPlayer, bind(self.onAttemptStart, self))
    addEventHandler("ttAttemptFinished", localPlayer, bind(self.onAttemptFinished, self))
    addEventHandler("ttMapStopped",      localPlayer, bind(self.onMapStopped,      self))
end

function TimeTrial:onMapStarted(duration, timeLeft)
    RaceTimer:getSingleton():startMap(duration, timeLeft)
    self.m_TimerWidget:show()
    playSound("files/audio/countstart.mp3")
end

function TimeTrial:onAttemptStart()
    self.m_Countdown:start()
end

function TimeTrial:onCountdownFinished()
    if not localPlayer.vehicle then return end
    localPlayer.vehicle:setFrozen(false)
    RaceTimer:getSingleton():startAttempt()
    triggerServerEvent("playerAttemptStarted", localPlayer)
end

function TimeTrial:onAttemptFinished()
    self.m_Countdown:stop()
    RaceTimer:getSingleton():finishAttempt()
end

function TimeTrial:onMapStopped()
    self.m_Countdown:stop()
    self.m_TimerWidget:hide()
end

-- TODO (future migration from racemodes-client.lua):
--   - Rankingboard rendering (dxDrawText list, currently in onClientRender ~L163-L193)
--   - Map/NextMap/Money dxText labels at bottom-left (L16-L21)
--   - Spectator count overlay (L185-L192)
--   - infoText / -Text / +Text overlays (L285-L294)

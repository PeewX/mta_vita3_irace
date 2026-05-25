--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 25.05.2026 - Time: 18:42
-- pewx.de // iRace-mta.de // mtasa.de
--
TimeTrial = inherit(Singleton)
addRemoteEvents{"ttMapStarted", "ttAttemptStarted", "ttAttemptFinished", "ttMapStopped"}

function TimeTrial:constructor()
    self.m_TimerWidget = TimerWidget:new()

    self.fn_onMapStarted     = bind(self.onMapStarted,     self)
    self.fn_onAttemptStarted = bind(self.onAttemptStarted, self)
    self.fn_onMapStopped     = bind(self.onMapStopped,     self)

    addEventHandler("ttMapStarted",     localPlayer, bind(self.onMapStarted, self))
    addEventHandler("ttAttemptStarted", localPlayer, bind(self.onAttemptStarted, self))
    addEventHandler("ttAttemptFinished",   localPlayer, bind(self.onAttemptFinished, self))
    addEventHandler("ttMapStopped",     localPlayer, bind(self.onMapStopped, self))
end

function TimeTrial:onMapStarted(duration, timeLeft)
    RaceTimer:getSingleton():startMap(duration, timeLeft)
    self.m_TimerWidget:show()
end

-- Fired after each respawn (and late-join) countdown.
function TimeTrial:onAttemptStarted(duration, timeLeft)
    RaceTimer:getSingleton():startAttempt(duration, timeLeft)
end

function TimeTrial:onAttemptFinished()
    RaceTimer:getSingleton():finishAttempt()
end

function TimeTrial:onMapStopped()
    self.m_TimerWidget:hide()
end

-- TODO (future migration from racemodes-client.lua):
--   - Rankingboard rendering (dxDrawText list, currently in onClientRender ~L163-L193)
--   - Map/NextMap/Money dxText labels at bottom-left (L16-L21)
--   - Spectator count overlay (L185-L192)
--   - infoText / -Text / +Text overlays (L285-L294)

--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 25.05.2026 - Time: 20:42
-- pewx.de // iRace-mta.de // mtasa.de
--
RaceTimer = inherit(Singleton)

function RaceTimer:constructor()
    self.m_MapStartTick     = nil
    self.m_AttemptStartTick = nil
    self.m_Duration         = nil
end

function RaceTimer:init(duration)
    self.m_Duration         = duration
    self.m_MapStartTick     = false
    self.m_AttemptStartTick = getTickCount()
    self.m_Finished         = getTickCount()
end

function RaceTimer:updateMapTime(duration, timeLeft)
    self.m_Duration     = duration
    self.m_MapStartTick = getTickCount() - (duration - timeLeft)
end

function RaceTimer:startAttempt()
    self.m_AttemptStartTick = getTickCount()
    self.m_Finished         = nil
end

function RaceTimer:finishAttempt()
    if self.m_Finished then return end
    self.m_Finished = getTickCount()
end

function RaceTimer:getPassedTime()
    if not self.m_AttemptStartTick then return nil end
    return (self.m_Finished or getTickCount()) - self.m_AttemptStartTick
end

function RaceTimer:getTimeLeft()
    if not self.m_Duration then return false end
    if self.m_Duration and not self.m_MapStartTick then return self.m_Duration end
    local left = self.m_Duration - (getTickCount() - self.m_MapStartTick)
    return left > 0 and left or 0
end

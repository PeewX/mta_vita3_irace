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

-- Called at GO (initial start). timeLeft is the remaining map duration in ms reported by the server
function RaceTimer:startMap(duration, timeLeft)
    self.m_Duration         = duration
    self.m_MapStartTick     = getTickCount() - (duration - timeLeft)
    self.m_AttemptStartTick = getTickCount()
    self.m_Finished         = getTickCount()
end

function RaceTimer:startAttempt()
    self.m_AttemptStartTick = getTickCount()
    self.m_Finished         = nil
end

function RaceTimer:finishAttempt()
    if self.m_Finished then return end
    self.m_Finished = getTickCount()
end

-- Elapsed ms since the current attempt started, or nil if not running.
function RaceTimer:getPassedTime()
    if not self.m_AttemptStartTick then return nil end
    return (self.m_Finished or getTickCount()) - self.m_AttemptStartTick
end

-- Remaining ms of the map countdown, or nil if map not started.
function RaceTimer:getTimeLeft()
    if not self.m_MapStartTick or not self.m_Duration then return nil end
    local left = self.m_Duration - (getTickCount() - self.m_MapStartTick)
    return left > 0 and left or 0
end

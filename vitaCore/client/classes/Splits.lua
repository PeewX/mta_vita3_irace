-- ****************************************************************************
-- *
--*   PROJECT:  iRace
-- *  FILE:     client/classes/Splits.lua
-- *  DATE:     02.06.2026 / 23:06
-- *  PURPOSE:  Tracks intermediate split times at checkpoints during a race attempt
-- *
-- ****************************************************************************

Splits = inherit(Singleton)
addRemoteEvents{"initSplits"}

function Splits:constructor()
    self.m_Record = {}
    self.m_PersonalBest = {}
    self.m_GlobalBest = {}

    --self.m_renderTarget = DxRenderTarget(Timings.WIDTH, Timings.HEIGHT)

    addEventHandler("initSplits", localPlayer, bind(self.initSplits, self))
    --addEventHandler("onClientRender", root, bind(self.render, self))
end

function Splits:initSplits()
end

function Splits:reset()
    self.m_Record = {}
end

function Splits:getRecord()
    return self.m_Record
end

function Splits:addSplit(Id)
    local timePassed = RaceTimer:getSingleton():getPassedTime()
    local vehicleSpeed = math.round(localPlayer.vehicle:getSpeed(), 1) * 10 -- Store speed as int
    self.m_Record[Id] =  {timePassed, vehicleSpeed}
end

function Splits:finish()
    if self.m_Finished then return end
    self.m_Finished = true
    self:addSplit("Hunter")
end
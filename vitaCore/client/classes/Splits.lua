-- ****************************************************************************
-- *
--*   PROJECT:  iRace
-- *  FILE:     client/classes/Splits.lua
-- *  DATE:     02.06.2026 / 23:06
-- *  PURPOSE:  Tracks intermediate split times at checkpoints during a race attempt
-- *
-- ****************************************************************************

Splits = inherit(Singelton)
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

function Splits:getRecord()
    return self.m_Record
end

function Splits:addSplit(Id)
    self.m_Record[Id] =  RaceTimer:getSingleton():getPassedTime()
end

function Splits:finish()
    if self.m_Finished then return end
    self.m_Finished = true
    self.m_Record["Finish"] =  RaceTimer:getSingleton():getPassedTime()
end
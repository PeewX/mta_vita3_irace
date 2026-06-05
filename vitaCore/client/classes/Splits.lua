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

Splits.COLOR = {
    BEST = {hex = "#7769c8", rgb = tocolor(170, 10, 210)},
    PERSONAL = {hex = "#6eb446", rgb = tocolor(55, 215, 50)},
    SLOWER = {hex = "#dcbe46", rgb = tocolor(255, 200, 0)},
    SPEED_FASTER = {hex = "#44FF44", rgb = tocolor(68, 255, 68)},
    SPEED_SLOWER = {hex = "#FF4444", rgb = tocolor(255, 68, 68)}
}

function Splits:constructor()
    self.m_Record = {}
    self.m_PersonalBest = {}
    self.m_GlobalBest = {}

    --self.m_renderTarget = DxRenderTarget(Timings.WIDTH, Timings.HEIGHT)

    addEventHandler("initSplits", localPlayer, bind(self.initSplits, self))
    --addEventHandler("onClientRender", root, bind(self.render, self))
end

function Splits:initSplits(globalBest, personalBest)
    self.m_GlobalBest = table.setIndexToInteger(globalBest)
    self.m_PersonalBest = table.setIndexToInteger(personalBest)

    outputDebugString("Received Global: ")
    iprint(self.m_GlobalBest)
    outputDebugString("Received PB: ")
    iprint(self.m_PersonalBest)
end

function Splits:reset()
    self.m_Record = {}
    self.m_Finished = false
end

function Splits:getRecord()
    return self.m_Record
end

function Splits:addSplit(Id)
    local timePassed = RaceTimer:getSingleton():getPassedTime()
    local vehicleSpeed = math.round(localPlayer.vehicle:getSpeed(), 1) * 10 -- Store speed as int
    self.m_Record[Id] =  {timePassed, vehicleSpeed}

    local globalTimeDiff, globalSpeedDiff = false, false
    local personalTimeDiff, personalSpeedDiff = false, false

    if self.m_GlobalBest and self.m_GlobalBest[Id] then
        globalTimeDiff = timePassed - self.m_GlobalBest[Id][1]
        if self.m_GlobalBest[Id][2] then globalSpeedDiff = (vehicleSpeed - self.m_GlobalBest[Id][2])/10 end
    end

    if self.m_PersonalBest and self.m_PersonalBest[Id] then
        personalTimeDiff = timePassed - self.m_PersonalBest[Id][1]
        if self.m_PersonalBest[Id][2] then personalSpeedDiff = (vehicleSpeed - self.m_PersonalBest[Id][2])/10 end
    end

    if globalTimeDiff and globalTimeDiff < 0 then
        self:renderInfo(globalTimeDiff, globalSpeedDiff, Splits.COLOR.BEST)
    elseif personalTimeDiff and personalTimeDiff < 0 then
        self:renderInfo(personalTimeDiff, personalSpeedDiff, Splits.COLOR.PERSONAL)
    elseif globalTimeDiff and globalTimeDiff > 0 then
        self:renderInfo(globalTimeDiff, globalSpeedDiff, Splits.COLOR.SLOWER)
    elseif personalTimeDiff and personalTimeDiff > 0 then
        self:renderInfo(personalTimeDiff, personalSpeedDiff, Splits.COLOR.SLOWER)
    end
end

function Splits:finish()
    if self.m_Finished then return end
    self.m_Finished = true
    self:addSplit("Hunter")
end

function Splits:renderInfo(timeDiff, speedDiff, color)
    local timeStr = ("%s%s%ss"):format(color.hex, (timeDiff < 0 and "-" or "+"), msToTimeStr(math.abs(timeDiff), false, true))

    local speedStr = ""
    if speedDiff then
        local speedColor = speedDiff < 0 and Splits.COLOR.SPEED_SLOWER.hex or Splits.COLOR.SPEED_FASTER.hex
        speedStr = (" %s(%s%.1f km/h)#FFFFFF"):format(speedColor, (speedDiff < 0 and "" or "+"), speedDiff)
    end

    outputChatBox((":Splits: %s%s"):format(timeStr, speedStr), 255, 255, 255, true)
end
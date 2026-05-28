Countdown = inherit(Object)

local STEPS      = {3, 2, 1, 0}
local STEP_MS    = 1000
local IMG_W_BASE = 474
local IMG_H_BASE = 204

function Countdown:constructor()
    self.m_Hook      = nil
    self.m_Step      = nil
    self.m_StepAt    = nil
    self.m_NextTimer = nil
    self.fn_onRender = bind(self.onRender, self)
end

function Countdown:setHook(fn)
    self.m_Hook = fn
end

function Countdown:start()
    if self.m_Step then self:stop() end
    self.m_Step   = 1
    self.m_StepAt = getTickCount()
    playSound("files/audio/" .. STEPS[1] .. ".mp3")
    addEventHandler("onClientRender", root, self.fn_onRender)
    self:_scheduleNext()
end

function Countdown:stop()
    removeEventHandler("onClientRender", root, self.fn_onRender)
    if self.m_NextTimer and isTimer(self.m_NextTimer) then
        killTimer(self.m_NextTimer)
    end
    self.m_NextTimer = nil
    self.m_Step      = nil
    self.m_StepAt    = nil
end

function Countdown:_scheduleNext()
    self.m_NextTimer = setTimer(function()
        self.m_NextTimer = nil
        local nextStep = self.m_Step + 1
        if nextStep == #STEPS then
            if self.m_Hook then self.m_Hook() end
        elseif nextStep > #STEPS then
            self:stop()
            return
        end
        self.m_Step   = nextStep
        self.m_StepAt = getTickCount()
        playSound("files/audio/" .. STEPS[nextStep] .. ".mp3")
        self:_scheduleNext()
    end, STEP_MS, 1)
end

function Countdown:onRender()
    if not self.m_Step then return end

    local t     = (getTickCount() - self.m_StepAt) / STEP_MS
    local alpha = math.floor(255 * (1 - t))
    if alpha <= 0 then return end

    local sw, sh = guiGetScreenSize()
    local w = resAdjust(IMG_W_BASE)
    local h = resAdjust(IMG_H_BASE)
    local x = math.floor(sw / 2 - w / 2)
    local y = math.floor(sh / 2 - h / 2)

    dxDrawImage(x, y, w, h, "files/countdown_" .. STEPS[self.m_Step] .. ".png", 0, 0, 0, tocolor(255, 255, 255, alpha))
end

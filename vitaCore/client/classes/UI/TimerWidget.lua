--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 25.05.2026 - Time: 18:41
-- pewx.de // iRace-mta.de // mtasa.de
--
TimerWidget = inherit(Object)

local COLOR_WHITE = tocolor(255, 255, 255, 255)

function TimerWidget:constructor()
    self.m_RaceTimer = RaceTimer:getSingleton()
    self.m_Visible   = false
    self.fn_onRender = bind(self.onRender, self)
end

function TimerWidget:destructor()
    self:hide()
end

function TimerWidget:show()
    if not self.m_Visible then
        self.m_Visible = true
        addEventHandler("onClientRender", root, self.fn_onRender)
    end
end

function TimerWidget:hide()
    if self.m_Visible then
        self.m_Visible = false
        removeEventHandler("onClientRender", root, self.fn_onRender)
    end
end

function TimerWidget:onRender()
    local leftMs   = self.m_RaceTimer:getTimeLeft()
    local passedMs = self.m_RaceTimer:getPassedTime()

    if not leftMs then return end
    if not passedMs then passedMs = 0 end

    local cx    = screenWidth / 2

    dxDrawImage(cx - 512, 0, 1024, 128, "files/vitatime2.png")
    dxDrawText(msToTimeStr(leftMs),   cx - 82,  23, cx - 5,  58, COLOR_WHITE, 1, "default-bold", "center", "top", false, false, false, false)
    dxDrawText(msToTimeStr(passedMs), cx + 5,   23, cx + 82, 58, COLOR_WHITE, 1, "default-bold", "center", "top", false, false, false, false)
end
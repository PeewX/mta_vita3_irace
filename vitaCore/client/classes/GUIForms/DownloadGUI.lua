DownloadGUI = inherit(Singleton)

function DownloadGUI:constructor()
    self.m_Text = "Please wait while hunting unicorns.."

    self.rt_Background = DxRenderTarget(screenWidth, LOGIN_HEIGHT, true)
    self.m_ProgressSize = screenWidth/2
    self.m_Progress = 0
    self.m_Alpha = 255

    self.m_ProgressAnimation = CAnimation:new(self, "m_Progress")
    self.m_AlphaAnimation = CAnimation:new(self, "m_Alpha")

    self.fn_Restore = function(didClearRenderTargets) if didClearRenderTargets then self:updateRenderTarget() end end
    addEventHandler("onClientRestore", root, self.fn_Restore)
end

function DownloadGUI:destructor()
    removeEventHandler("onClientRestore", root, self.fn_Restore)
    self.m_ProgressAnimation:delete()
    self.m_AlphaAnimation:delete()
end

function DownloadGUI:updateRenderTarget()
    LoginBackground:getSingleton().rt_Background:setAsTarget(true)
    LoginBackground.drawBackground()

    dxDrawText(self.m_Text, 0, LOGIN_HEIGHT-80, screenWidth, LOGIN_HEIGHT-40, tocolor(255, 255, 255, self.m_Alpha), 1, irFont(40), "center", "top")
    dxDrawRectangle(screenWidth/2 - self.m_ProgressSize/2, LOGIN_HEIGHT-40, self.m_ProgressSize, 5, tocolor(30, 30, 30, self.m_Alpha))
    dxDrawRectangle(screenWidth/2 - self.m_ProgressSize/2, LOGIN_HEIGHT-40, self.m_ProgressSize/100*self.m_Progress, 5, tocolor(200, 30, 30))
    dxDrawText(("%.2fMB / %.2fMB"):format(self.m_DownloadedSize/1024/1024, self.m_FullSize/1024/1024), 0, LOGIN_HEIGHT-40, screenWidth, LOGIN_HEIGHT, tocolor(255, 255, 255, self.m_Alpha), 1, irFont(20), "center", "center")
    dxSetRenderTarget()
end

function DownloadGUI:onProgress(p, fullSize)
    self.m_FullSize = fullSize
    self.m_DownloadedSize = (tonumber(self.m_Progress) or 0)*(self.m_FullSize/100)

    self.m_ProgressAnimation:startAnimation(1000, "OutQuad", p)
    self:updateRenderTarget()
end

function DownloadGUI:onComplete()
    self.m_ProgressAnimation:startAnimation(1000, "OutQuad", 100)
    self:updateRenderTarget()

    Package.load("ir.data")
    core:ready()

    setTimer(function() self.m_AlphaAnimation:startAnimation(400, "Linear", 0) self.m_ProgressAnimation:startAnimation(400, "OutQuad", 0)  end, 600, 1)
    setTimer(
        function()
            local lgi = LoginGUI:new()

            local username = core:get("Login", "username", "")
            local pwhash = core:get("Login", "password", "")
            local avatar = core:get("Login", "avatar", false)

            if avatar then
                if not File.exists("files/_avatar.png") then
                    core:set("Login", "avatar", nil)
                    avatar = false
                elseif not dxCreateTexture("files/_avatar.png") then
                    core:set("Login", "avatar", nil)
                    avatar = false
                end
            end

            lgi.m_Login_Username:setText(username)
            lgi.m_Login_Password:setText(pwhash)
            lgi.usePasswordHash = pwhash
            lgi.useCustomAvatar = avatar
            lgi:updateRenderTarget()
        end, 1000, 1)
end
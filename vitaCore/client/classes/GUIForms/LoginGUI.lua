LoginGUI = inherit(Singleton)

function LoginGUI:constructor()
    self.usePasswordHash = false
    self.useCustomAvatar = false
    showCursor(true)

    self.HEIGHT = screenHeight/3
    self.WHITE = tocolor(255, 255, 255)

    self.m_ActivePanel = "login"
    self.m_SubAlpha = 0
    self.m_OffsetY = -self.HEIGHT
    self.m_ContentStartX = 0
    self.m_ContentStartY = self.HEIGHT

    self.rt_Login = DxRenderTarget(screenWidth, self.HEIGHT, true)

    self:createGUI()
    self:initAnimations()

    self.HEIGHT = 0

    self.m_MainAnimation:startAnimation(1500, "OutQuad", screenHeight/3)

    setTimer(function()
        self.m_MovingAnimation:startAnimation(750, "OutQuad", 0, 255)
    end, 750, 1)

    self.fn_Restore = function(didClearRenderTargets) if didClearRenderTargets then self:updateRenderTarget() end end
    addEventHandler("onClientRestore", root, self.fn_Restore)
end

function LoginGUI:destructor()
    self.m_Login_Username:destructor()
    self.m_Login_Password:destructor()
    self.m_Login_Submit:destructor()

    self.m_Register_Email:destructor()
    self.m_Register_Username:destructor()
    self.m_Register_Password:destructor()
    self.m_Register_Password2:destructor()
    self.m_Register_Submit:destructor()
    self.m_Register_ToLogin:destructor()

    self.m_MovingAnimation:delete()
    self.m_MainAnimation:delete()
    self.rt_Login:destroy()
    removeEventHandler("onClientKey", root, self.fn_SubmitEnter)
    removeEventHandler("onClientRestore", root, self.fn_Restore)
end

function LoginGUI:initAnimations()
    self.m_MovingAnimation = CAnimation:new(self, "m_OffsetY", "m_SubAlpha")
    self.m_MainAnimation   = CAnimation:new(self, "HEIGHT")
end

function LoginGUI:createGUI()
    self.m_Enabled = true

    -- Login-Panel
    self.m_EditStartX  = screenWidth/2 - 128
    self.m_EditStartY  = 158
    self.m_EditWidth   = 256
    self.m_EditHeight  = 24

    self.m_Login_Username = GUIEdit:new("// Username", self.m_EditStartX, self.m_EditStartY, self.m_EditWidth, self.m_EditHeight, false, false, self)
    self.m_Login_Password = GUIEdit:new("// Password", self.m_EditStartX, self.m_EditStartY + self.m_EditHeight + 12, self.m_EditWidth - self.m_EditHeight, self.m_EditHeight, false, true, self)
    self.m_Label_Register = GUILabel:new("", 0, self.HEIGHT - 28, screenWidth, 20, self)
    self.m_Label_Register:setAlign("center", "center")
    self.m_Label_Register:setFont(irFont(25))

    self.m_Login_Submit = GUIButton:new(">", self.m_EditStartX + self.m_EditWidth - self.m_EditHeight, self.m_EditStartY + self.m_EditHeight + 12, self.m_EditHeight, self.m_EditHeight, {["normal"] = {180, 180, 180}, ["hover"] = {150, 150, 150}}, self)
    self.m_Login_Submit:setFont("default-bold")
    self.m_Login_Submit:setSize(1.3)

    -- Login Submit
    self.m_Login_Submit:addClickFunction(
        function()
            if self.m_ActivePanel ~= "login" then return end
            local username = self.m_Login_Username:getText()
            local pw       = self.m_Login_Password:getText()

            if self.usePasswordHash and self.usePasswordHash == pw then
                triggerServerEvent("accountlogin", root, username, "", pw)
            else
                triggerServerEvent("accountlogin", root, username, pw)
            end

            self.m_Login_Submit:setEnabled(false)
        end
    )

    self.m_Label_Register:addClickFunction(
        function()
            if self.m_ActivePanel ~= "login" then return end

            -- Disable login panel controls
            self.m_Login_Username:setEnabled(false)
            self.m_Login_Password:setEnabled(false)
            self.m_Login_Submit:setEnabled(false)

            -- Enable register panel controls
            self.m_Register_Username:setEnabled(true)
            self.m_Register_Email:setEnabled(true)
            self.m_Register_Password:setEnabled(true)
            self.m_Register_Password2:setEnabled(true)
            self.m_Register_Submit:setEnabled(true)
            self.m_Register_ToLogin:setEnabled(true)

            self.m_ActivePanel = "register"
            self:updateRenderTarget()
        end
    )

    -- Register-Panel
    local regGap = 12
    local regBtnW = 100

    self.m_Register_Username  = GUIEdit:new("// Username", self.m_EditStartX, self.m_EditStartY + (self.m_EditHeight+regGap), self.m_EditWidth, self.m_EditHeight, false, false, self)
    self.m_Register_Email     = GUIEdit:new("// E-Mail",  self.m_EditStartX, self.m_EditStartY, self.m_EditWidth, self.m_EditHeight, false, false, self)
    self.m_Register_Password  = GUIEdit:new("// Password", self.m_EditStartX, self.m_EditStartY + (self.m_EditHeight+regGap)*2, self.m_EditWidth, self.m_EditHeight, false, true,  self)
    self.m_Register_Password2 = GUIEdit:new("// Confirm Password", self.m_EditStartX, self.m_EditStartY + (self.m_EditHeight+regGap)*3, self.m_EditWidth, self.m_EditHeight, false, true,  self)

    self.m_Register_Submit = GUIButton:new(">", screenWidth/2 + self.m_EditWidth/2 - regBtnW, self.m_EditStartY + (self.m_EditHeight+regGap)*4, regBtnW, self.m_EditHeight, {["normal"] = {180, 180, 180}, ["hover"] = {150, 150, 150}}, self)
    self.m_Register_Submit:setFont("default-bold")
    self.m_Register_Submit:setSize(1.3)
    self.m_Register_Submit:setEnabled(false)

    self.m_Register_ToLogin = GUIButton:new("< Back", screenWidth/2 - self.m_EditWidth/2 , self.m_EditStartY + (self.m_EditHeight+regGap)*4, regBtnW, self.m_EditHeight, {["normal"] = {180, 180, 180}, ["hover"] = {150, 150, 150}}, self)
    self.m_Register_ToLogin:setFont(irFont(25))
    self.m_Register_ToLogin:setEnabled(false)

    self.m_Register_ToLogin:addClickFunction(
        function()
            if self.m_ActivePanel ~= "register" then return end

            -- Disable register panel controls
            self.m_Register_Username:setEnabled(false)
            self.m_Register_Email:setEnabled(false)
            self.m_Register_Password:setEnabled(false)
            self.m_Register_Password2:setEnabled(false)
            self.m_Register_Submit:setEnabled(false)
            self.m_Register_ToLogin:setEnabled(false)

            -- Enable login panel controls
            self.m_Login_Username:setEnabled(true)
            self.m_Login_Password:setEnabled(true)
            self.m_Login_Submit:setEnabled(true)

            self.m_ActivePanel = "login"
            self:updateRenderTarget()
        end
    )

    -- Register Submit
    self.m_Register_Submit:addClickFunction(
        function()
            if self.m_ActivePanel ~= "register" then return end

            local email   = self.m_Register_Email:getText()
            local user    = self.m_Register_Username:getText()
            local pw      = self.m_Register_Password:getText()
            local pwconf  = self.m_Register_Password2:getText()

            if pw ~= pwconf then
                addNotification(4, 200, 100, 50, "Passwords do not match!")
                return
            end

            if #email == 0 or #user == 0 or #pw == 0 then
                addNotification(4, 200, 100, 50, "Please fill in all fields!")
                return
            end

            triggerServerEvent("accountregister", root, user, pw, email)
            self.m_Register_Submit:setEnabled(false)
        end
    )

    -- Enter-Taste
    self.fn_SubmitEnter = function(sButton, sState)
        if not (sButton == "enter" or sButton == "num_enter") or not sState then return end
        if self.m_ActivePanel == "login" then
            self.m_Login_Submit:performClick()
        elseif self.m_ActivePanel == "register" then
            self.m_Register_Submit:performClick()
        end
    end
    addEventHandler("onClientKey", root, self.fn_SubmitEnter)
end

function LoginGUI:updateRenderTarget()
    LoginBackground:getSingleton().rt_Background:setAsTarget(true)
    LoginBackground.drawBackground()

    -- Avatar
    local avatar = {startX = screenWidth/2 - 64, startY = 17 + self.m_OffsetY, width = 128, height = 128}
    dxDrawRectangle(avatar.startX,     avatar.startY,     avatar.width,     avatar.height,     tocolor(0, 0, 0, 180, self.m_SubAlpha))
    dxDrawRectangle(avatar.startX + 1, avatar.startY + 1, avatar.width - 2, avatar.height - 2, tocolor(255, 255, 255, 230/255*self.m_SubAlpha))
    dxDrawImage    (avatar.startX + 2, avatar.startY + 2, avatar.width - 4, avatar.height - 4, self.useCustomAvatar and "files/_avatar.png" or "files/avatar.png", 0, 0, 0, tocolor(255, 255, 255, self.m_SubAlpha))

    if self.m_ActivePanel == "login" then
        if self.usePasswordHash ~= "" and self.usePasswordHash == self.m_Login_Password:getText() then
            --self.m_Login_Password:setProperty("diffY", self.m_EditStartY)
            --self.m_Login_Submit:setProperty("diffY", self.m_EditStartY)
            self.m_Label_Register:setText(("Welcome back %s!"):format(localPlayer.name))
            self.m_Login_Username:setEnabled(false)
        else
            --self.m_Login_Password:setProperty("diffY", self.m_EditStartY + self.m_EditHeight + 12)
            --self.m_Login_Submit:setProperty("diffY", self.m_EditStartY + self.m_EditHeight + 12)
            --self.m_Login_Username:render(self.m_OffsetY)
            self.m_Label_Register:setText("#ffffffClick '#ff7000here#ffffff' to register an account")
            self.m_Login_Username:setEnabled(true)
        end
        self.m_Login_Username:render(self.m_OffsetY)
        self.m_Login_Password:render(self.m_OffsetY)
        self.m_Login_Submit:render(self.m_OffsetY)
        self.m_Label_Register:render(self.m_OffsetY)
    else
        self.m_Register_Email:render(self.m_OffsetY)
        self.m_Register_Username:render(self.m_OffsetY)
        self.m_Register_Password:render(self.m_OffsetY)
        self.m_Register_Password2:render(self.m_OffsetY)
        self.m_Register_Submit:render(self.m_OffsetY)
        self.m_Register_ToLogin:render(self.m_OffsetY)
    end

    -- Toggle sound
    --dxDrawText("Press 'm' to toggle sound", 0, 0, screenWidth, self.HEIGHT - 5, self.WHITE, 1, "clear", "center", "bottom")
    dxSetRenderTarget()
end

function LoginGUI:getPosition()
    return self.m_ContentStartX, self.m_ContentStartY
end

function LoginGUI.receiveAvatar(avatar, error)
    avatar = dxConvertPixels(avatar, "png")
    if not avatar then
        core:set("Login", "avatar", nil)
        return
    end

    local file = File.new("files/_avatar.png")
    file:write(avatar)
    file:close()
end

function LoginGUI.downloadAvatar(ID, fileHash)
    if not fileHash then return end
    if core:get("Login", "avatar", "") == fileHash then return true end

    local directory  = fileHash:sub(1, 2)
    local fileString = ("%s-%s-%s.jpg"):format(ID, fileHash, 128)   --> avatarID-fileHash-size.jpg
    local downloadString = ("http://irace-mta.de/wcf/images/avatars/%s/%s"):format(directory, fileString)

    fetchRemote(downloadString, LoginGUI.receiveAvatar)
    core:set("Login", "avatar", fileHash)
end

-- Events
addEvent("loginfailed", true)
addEventHandler("loginfailed", root,
    function(text)
        LoginGUI:getSingleton().m_Login_Submit:setEnabled(true)
        addNotification(1, 200, 50, 50, text)
    end
)

addEvent("loginsuccess", true)
addEventHandler("loginsuccess", root,
    function(pwhash, avatarFileHash, avatarID)
        showCursor(false)
        initSettings()
        addNotification(2, 50, 200, 50, "Successfully logged in")

        if not core:get("Login", "video", false) then
            addNotification(3, 200, 200, 50, "You can change the login background video!\nType /bg")
        end

        core:set("Login", "username", LoginGUI:getSingleton().m_Login_Username:getText())
        core:set("Login", "password", pwhash)

        delete(LoginGUI:getSingleton())
        delete(DownloadGUI:getSingleton())
        delete(LoginBackground:getSingleton())

        core:afterLogin()

        showChat(true)
        bindKey("m", "down", toggleVitaMusic)

        --LoginGUI.downloadAvatar(avatarID, avatarFileHash)
    end
)

addEvent("registerfailed", true)
addEventHandler("registerfailed", root,
    function(text)
        LoginGUI:getSingleton().m_Register_Submit:setEnabled(true)
        addNotification(1, 200, 50, 50, text)
    end
)
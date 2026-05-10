Core = inherit(Object)

function Core:constructor()
    -- Small hack to get the global core immediately
    core = self

    -- Instantiate the localPlayer instance right now
    enew(localPlayer, LocalPlayer)

    self.m_Config = ConfigXML:new("config.xml")
    Provider:new()
    LoginBackground:new()
    DownloadGUI:new()
    MapManager:new()

    Provider:getSingleton():requestFile("ir.data", bind(DownloadGUI.onComplete, DownloadGUI:getSingleton()), bind(DownloadGUI.onProgress, DownloadGUI:getSingleton()))
    setAmbientSoundEnabled("gunfire", false)
end

function Core:destructor()
end

function Core:ready()
    ms = dxCreateFont( "files/fonts/metro.ttf", screenHeight*(screenHeight/(screenHeight*20)))
    ms_bold = dxCreateFont( "files/fonts/metro_bold.ttf", screenHeight*(screenHeight/(screenHeight*20)))
    ms_bold_12 =  dxCreateFont( "files/fonts/metro_bold.ttf", 12)
    ms_bold_10 =  dxCreateFont( "files/fonts/metro_bold.ttf", 10)

    tireShader = dxCreateShader ( "files/shader/texreplace.fx" )

    for pickupName, pickupModelID in pairs(MODEL_FOR_PICKUP_TYPE) do
        local path = ("files/models/%s.%s")
        EngineTXD(path:format(pickupName, "txd")):import(pickupModelID)
        EngineDFF(path:format(pickupName, "dff")):replace(pickupModelID)
        Engine.setModelLODDistance(pickupModelID, 100)
    end
end

function Core:afterLogin()
    AntiBounce:new()
    Sounds:new()
    SpawnPosition:new()
    Timings:new()
end

function Core:get(...)
    return self.m_Config:get(...)
end

function Core:set(...)
    return self.m_Config:set(...)
end
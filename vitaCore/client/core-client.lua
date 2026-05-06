--[[
Project: vitaCore
File: core-client.lua
Author(s):	Sebihunter
]]--

--Things for error shit
addEvent("loadMapDD", true)
addEvent("stopMapDD", true)
addEvent("loadMapSH", true)
addEvent("stopMapSH", true)
addEvent("loadMapDM", true)
addEvent("stopMapDM", true)
addEvent("loadMapRA", true)
addEvent("stopMapRA", true)

screenWidth, screenHeight = guiGetScreenSize ( )

function onClientResourceStart()
	guiSetInputMode("no_binds_when_editing")
	--Check if settings exist, if not then create it
	--[[if xmlLoadFile("vita_settings.xml") == false then
		local vitaXML = xmlCreateFile("vita_settings.xml","settings")
			
		local xmlRoot = xmlLoadFile(":race/login.xml")
		if xmlRoot then
			local curnode = xmlFindChild(xmlRoot, "autologin", 0)	
			local autologin = xmlNodeGetValue(curnode)	
			if autologin == "2" then 
				vitaNode = xmlFindChild(vitaXML, "saved", 0)
				xmlNodeSetValue ( vitaNode, "1")
			
				curnode = xmlFindChild(xmlRoot, "username", 0)
				local user = xmlNodeGetValue(curnode)
				vitaNode = xmlFindChild(vitaXML, "username", 0)
				xmlNodeSetValue ( vitaNode, user)
				
				curnode = xmlFindChild(xmlRoot, "pw", 0)
				local pass = xmlNodeGetValue(curnode)
				vitaNode = xmlFindChild(vitaXML, "password", 0)
				xmlNodeSetValue ( vitaNode, pass)
			end
		end
		xmlSaveFile(vitaXML)
		xmlUnloadFile(vitaXML)
	end]]

	
	racemodesClientStart()
	showChat(false)
	fadeCamera(true)
	--showCursor(false)
	setCameraMatrix(1468.8785400391, -919.25317382813, 100.153465271, 1468.388671875, -918.42474365234, 99.881813049316)
	setPlayerHudComponentVisible("all", false)
	setPlayerHudComponentVisible("crosshair", true)
	setPedCanBeKnockedOffBike(getLocalPlayer(), false)
	setCameraClip ( true, false )
	
	g_PickupStartTick = getTickCount()
	
	triggerServerEvent ( "onPlayerRequestInitialise", getLocalPlayer() )
	--addEventHandler ( "onClientRender", getRootElement(), notInitialisedRender)
end
addEventHandler("onClientResourceStart", getResourceRootElement(getThisResource()), onClientResourceStart)

gAllTheMapsRA = {}
gAllTheMapsDD = {}
gAllTheMapsDM = {}
gAllTheMapsSH = {}
addEvent("priorReceiveAllTheMaps", true)
addEventHandler("priorReceiveAllTheMaps", getRootElement(),
	function (maps)
		if maps then
			for i,v in pairs(maps) do
				local realname = v.realname:gsub(" %[", "%[")
				realname = realname:gsub("%] ", "%]")
				if string.find (string.upper (tostring(v.name)), "RACE") ~= nil then
					gAllTheMapsRA[#gAllTheMapsRA+1] = {}
					gAllTheMapsRA[#gAllTheMapsRA].text = realname
					gAllTheMapsRA[#gAllTheMapsRA].data = v.name
				elseif string.find (string.upper (tostring(v.name)), "DD") ~= nil then
					gAllTheMapsDD[#gAllTheMapsDD+1] = {}
					gAllTheMapsDD[#gAllTheMapsDD].text = realname
					gAllTheMapsDD[#gAllTheMapsDD].data = v.name				
				elseif string.find (string.upper (tostring(v.name)), "DM") ~= nil then
					gAllTheMapsDM[#gAllTheMapsDM+1] = {}
					gAllTheMapsDM[#gAllTheMapsDM].text = realname
					gAllTheMapsDM[#gAllTheMapsDM].data = v.name		
				elseif string.find (string.upper (tostring(v.name)), "SHOOTER") ~= nil then
					gAllTheMapsSH[#gAllTheMapsSH+1] = {}
					gAllTheMapsSH[#gAllTheMapsSH].text = realname
					gAllTheMapsSH[#gAllTheMapsSH].data = v.name							
				end
			end	
		end
		
	table.sort(gAllTheMapsDM, 
		function(a, b)
			return a.text < b.text
		end
	)
	table.sort(gAllTheMapsSH, 
		function(a, b)
			return a.text < b.text
		end
	)	
	table.sort(gAllTheMapsDD, 
		function(a, b)
			return a.text < b.text
		end
	)	
	table.sort(gAllTheMapsRA, 
		function(a, b)
			return a.text < b.text
		end
	)	
		--removeEventHandler ( "onClientRender", getRootElement(), notInitialisedRender)

	end
)

function notInitialisedRender()
	dxDrawImage ( screenWidth/2-256, screenHeight/2-256, 512, 512, "files/loading.png" )
end

addEventHandler("onClientVehicleEnter", getRootElement(),
    function(thePlayer, seat)
        if seat == 0 then
			setVehicleShaderBL(source, tonumber(getElementData(thePlayer, "Backlights")))
		end
    end
)

local vehicleShadersBL = {}
function setVehicleShaderBL(veh, id)
	if veh and isElement(veh) then
		if id == 0 then
			if getElementData(veh, "vehicleShaderBL") then
				engineRemoveShaderFromWorldTexture(getElementData(veh, "vehicleShaderBL"), "vehiclelights128", veh)
				engineRemoveShaderFromWorldTexture(getElementData(veh, "vehicleShaderBL"), "vehiclelightson128", veh)
				setElementData(veh, "vehicleShaderBL", false, false)
			end	
		else
			if not vehicleShadersBL[tostring(id)] then
				local texture = dxCreateTexture("files/backlights/"..id..".jpg","dxt1")
				if not texture then return false end
				local shader = dxCreateShader("files/shader/texreplace.fx")
				if not shader then return false end
				dxSetShaderValue(shader,"gTexture",texture)
				vehicleShadersBL[tostring(id)] = shader
			end
			
			if getElementData(veh, "vehicleShaderBL") then
				engineRemoveShaderFromWorldTexture(getElementData(veh, "vehicleShaderBL"), "vehiclelights128", veh)
				engineRemoveShaderFromWorldTexture(getElementData(veh, "vehicleShaderBL"), "vehiclelightson128", veh)
			end
			engineApplyShaderToWorldTexture(vehicleShadersBL[tostring(id)],"vehiclelights128",veh)
			engineApplyShaderToWorldTexture(vehicleShadersBL[tostring(id)],"vehiclelightson128",veh)
			setElementData(veh, "vehicleShaderBL", vehicleShadersBL[tostring(id)], false)
		end
	end
	return true
end

local rainbowPlayers = {}
local rainbowSteps = {
	[1] = {255,	1,		1},
	[2] = {255,	255,	1},
	[3] = {1,		255,	1},
	[4] = {1,		255,	255},
	[5] = {1,		1,		255},
	[6] = {255,	1,		255},
	[7] = {255,	255,	255}
}

fps1 = getTickCount() + 2000
fpsc = 0
function fpsread()
	if fps1 > getTickCount() then
		fpsc = fpsc + 1
	elseif fps1 < getTickCount() then
		fpsc = fpsc / 2
		fpsc = math.ceil ( fpsc )
		setElementData(getLocalPlayer(), "FPS", fpsc)
		fps1 = getTickCount() + 2000
		fpsc = 0
	end
	
	if showChatIcons == true then	
		for k, player in ipairs (getElementsByType( "player",getRootElement(), true)) do
			if (getElementData(player, "state") == "alive" or getElementData(player, "state") == "not ready" or getElementData(player, "state") == "ready") and getElementData(player, "isChatting") == true and isElementStreamedIn ( player ) and player ~= getLocalPlayer() then
				local playerAlpha = 1.0
				local head_x, head_y, head_z = getElementPosition ( player )
				local scr_x, scr_y = getScreenFromWorldPosition ( head_x, head_y, head_z+1, 0, false)
				if getPedOccupiedVehicle(player) and showPlayerCarfade ~= 1 then
					playerAlpha = getElementAlpha(getPedOccupiedVehicle(player))/255
				end
				if scr_x and scr_y then
					local cam_x, cam_y, cam_z, lok_x, lok_y, lok_z, cam_rol, cam_fov = getCameraMatrix()
					local dist = getDistanceBetweenPoints3D ( head_x, head_y, head_z, cam_x, cam_y, cam_z ) -- Distance between camera and head center bone
					if  dist > 0.4 and dist < 90 then
						if isLineOfSightClear ( cam_x, cam_y, cam_z, head_x, head_y, head_z, true, false, true, true, false, true, false, player ) then
							dxDrawImage ( scr_x , scr_y, 32, 32, "files/chat.png", 0, 0, 0, tocolor(255,255,255,255*playerAlpha), false )
						end
					end
				end
			end
		end
	end	
	
	if showAllTheMemes == true and not gunGame then
		for k, player in ipairs (getElementsByType( "player",getRootElement(), true)) do
			local x, y = guiGetScreenSize()
			local num = tostring(getElementData ( player, "playerMeme" ))..".png"
			if (getElementData(player, "state") == "alive" or getElementData(player, "state") == "not ready" or getElementData(player, "state") == "ready") and num ~= "0.png" and (getElementData(player, "isDonator") == true or getElementData(player, "memeActivated") == 1) and isElementStreamedIn ( player ) then	
				local head_x, head_y, head_z = getPedBonePosition ( player, 8 ) -- Get the center head bone
				local head_tx, head_ty, head_tz = getPedBonePosition ( player, 5 ) -- Bone for the top of the head
				local head_bx, head_by, head_bz = getPedBonePosition ( player, 6 ) -- Bone for the bottom of the head
				head_z = head_z + 0.06 -- Gets face centered a bit better
				local scr_x, scr_y = getScreenFromWorldPosition ( head_x, head_y, head_z, 0, false ) -- Get location of head center bone on screen
				local scr_tx, scr_ty = getScreenFromWorldPosition ( head_tx, head_ty, head_tz, 0, false ) -- Get location of head top bone on screen
				local scr_bx, scr_by = getScreenFromWorldPosition ( head_bx, head_by, head_bz, 0, false ) -- Get location of head bottom bone on screen
				local playerAlpha = 1.0

				if getPedOccupiedVehicle(player) and showPlayerCarfade ~= 1 then
					playerAlpha = getElementAlpha(getPedOccupiedVehicle(player))/255
				end
				if scr_x and scr_tx then -- If center bone and top bone are on screen
					local cam_x, cam_y, cam_z, lok_x, lok_y, lok_z, cam_rol, cam_fov = getCameraMatrix() -- Camera matrix
					local dist = getDistanceBetweenPoints3D ( head_x, head_y, head_z, cam_x, cam_y, cam_z ) -- Distance between camera and head center bone
					if  dist > 0.4 or dist < 90 or scr_bx then
						if isLineOfSightClear ( cam_x, cam_y, cam_z, head_x, head_y, head_z, true, false, true, true, false, true, false, player ) then --Line of sight check. Read the wiki to understand this.
							if getCameraViewMode (  ) == 0 and player == getLocalPlayer() then
								-- TOASTY
							else
								dxDrawImage ( scr_x - ( 80 / dist ) * x / 800 / 70 * cam_fov, scr_y - ( 100 / dist ) * y / 600 / 70 * cam_fov, ( 160 / dist ) * x / 800 / 70 * cam_fov, ( 200 / dist ) * y / 600 / 70 * cam_fov, "files/meme/"..num, -math.deg ( math.atan2 ( scr_tx - scr_bx, scr_ty - scr_by ) ), 0, 0, tocolor(255,255,255,255*playerAlpha), false )
							end
						end
					end
				end	
			end
		end
	end	
	
	for k, player in ipairs (getElementsByType( "player",getRootElement(), true)) do
		if getPedOccupiedVehicle(player) and getElementData(player, "rainbowColor") == true and getElementData(player, "discoColor") ~= true and getElementData(player, "isDonator") == true then
			if not rainbowPlayers[player] then rainbowPlayers[player] = math.random(1, #rainbowSteps) end
			vehicle = getPedOccupiedVehicle(player)
			local r,g,b = getVehicleColor ( vehicle, true)
			
			local hasStepFinished1 = false
			if r > rainbowSteps[rainbowPlayers[player]][1] and r-5 > 1 then
				r = r-5
				hasStepFinished1 = false
			elseif r < rainbowSteps[rainbowPlayers[player]][1] and r+5 < 255 then
				r = r+5
				hasStepFinished1 = false
			else
				r = rainbowSteps[rainbowPlayers[player]][1]
				hasStepFinished1 = true
			end

			local hasStepFinished2 = false
			if g > rainbowSteps[rainbowPlayers[player]][2] and g-5 > 1 then
				g = g-5
				hasStepFinished2 = false
			elseif  g < rainbowSteps[rainbowPlayers[player]][2] and g+5 < 255 then
				g = g+5
				hasStepFinished2 = false
			else
				g = rainbowSteps[rainbowPlayers[player]][2]
				hasStepFinished2 = true
			end
			
			local hasStepFinished3 = false
			if b > rainbowSteps[rainbowPlayers[player]][3] and b-5 > 1 then
				b = b-5
				hasStepFinished3 = false
			elseif b < rainbowSteps[rainbowPlayers[player]][3] and b+5 < 255 then
				b = b+5
				hasStepFinished3 = false
			else
				b = rainbowSteps[rainbowPlayers[player]][3]
				hasStepFinished3 = true
			end		
			setVehicleColor(vehicle, r,g,b,r,g,b)
			setVehicleHeadLightColor ( vehicle, r, g, b)	
			if hasStepFinished1 and hasStepFinished2 and hasStepFinished3 then
				rainbowPlayers[player] = rainbowPlayers[player]+1
				if rainbowPlayers[player] == 8 then rainbowPlayers[player] = 1 end
			end
		end
	end
	
	for i,v in ipairs(getElementsByType("restartTimer")) do
		if getElementData(v, "left") then
			dxDrawText("Server restart in: ".. tostring(msToTimeStr(getElementData(v, "left"))), 1, screenHeight-19, screenWidth, screenHeight, tocolor(0,0,0,100), 0.2, ms_bold, "center",  "top", false, false, true)
			dxDrawText("Server restart in: ".. tostring(msToTimeStr(getElementData(v, "left"))), 0, screenHeight-20, screenWidth, screenHeight, tocolor(255,0,0,255), 0.2, ms_bold, "center", "top", false, false, true)
			break
		end
	end
	
	if showUserGui == false then
		if getElementData(getLocalPlayer(), "AFK") == true then
			dxDrawRectangle ( screenWidth/2-200, screenHeight/2-100, 400, 200, tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( "AFK", screenWidth/2-200+6, screenHeight/2-100+6, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "AFK", screenWidth/2-200+5, screenHeight/2-100+5, screenWidth, screenHeight, tocolor ( 255, 150, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "Use /afk to end the AFK mode.", 1, screenHeight/2-50+1, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "clear", "center" )
			dxDrawText ( "Use /afk to end the AFK mode.", 0, screenHeight/2-50, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "clear", "center")	
		end
			
		if getElementData(getLocalPlayer(), "warnAFK") == true then
			dxDrawRectangle ( screenWidth/2-200, screenHeight/2-100, 400, 200, tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( "AFK Warning", screenWidth/2-200+6, screenHeight/2-100+6, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "AFK Warning", screenWidth/2-200+5, screenHeight/2-100+5, screenWidth, screenHeight, tocolor ( 255, 150, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "Move or you'll be blown up.", 1, screenHeight/2-50+1, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "clear", "center" )
			dxDrawText ( "Move or you'll be blown up.", 0, screenHeight/2-50, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "clear", "center")	
		end
		
		if getElementData(getLocalPlayer(), "actionFPS") == true then
			dxDrawRectangle ( screenWidth/2-200, screenHeight/2-100, 400, 200, tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( "Low FPS", screenWidth/2-200+6, screenHeight/2-100+6, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "Low FPS", screenWidth/2-200+5, screenHeight/2-100+5, screenWidth, screenHeight, tocolor ( 255, 150, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "Increase your FPS or you'll be blown up.", 1, screenHeight/2-50+1, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "clear", "center" )
			dxDrawText ( "Increase your FPS or you'll be blown up.", 0, screenHeight/2-50, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "clear", "center")	
		end
			
		if getElementData(getLocalPlayer(), "actionPing") == true then
			dxDrawRectangle ( screenWidth/2-200, screenHeight/2-100, 400, 200, tocolor ( 0, 0, 0, 150 ) )
			dxDrawText ( "High Ping", screenWidth/2-200+6, screenHeight/2-100+6, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "High Ping", screenWidth/2-200+5, screenHeight/2-100+5, screenWidth, screenHeight, tocolor ( 255, 150, 0, 255 ), 1, "bankgothic" )
			dxDrawText ( "Your ping is too high and therefore you'll be blown up.", 1, screenHeight/2-50+1, screenWidth, screenHeight, tocolor ( 0, 0, 0, 255 ), 1, "clear", "center" )
			dxDrawText ( "Your ping is too high and therefore you'll be blown up.", 0, screenHeight/2-50, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "clear", "center")	
		end
		
		if getElementData(getLocalPlayer(), "winline") ~= nil and getElementData(getLocalPlayer(), "winline") ~= false then
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline"))), 1, screenHeight*0.35,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline"))), 1, screenHeight*0.35+1,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline"))), -1, screenHeight*0.35,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline"))), -1, screenHeight*0.35-1,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawColorText(tostring(getElementData(getLocalPlayer(), "winline")), 0, screenHeight*0.35,screenWidth, screenHeight, tocolor(getElementData(getLocalPlayer(), "winr"), getElementData(getLocalPlayer(), "wing"), getElementData(getLocalPlayer(), "winb"), 255), 1.2, "bankgothic", "center", "top")
		
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline2"))), 1, screenHeight*0.35+25,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline2"))), 1, screenHeight*0.35+1+25,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline2"))), -1, screenHeight*0.35+25,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")
			dxDrawText(removeColorCoding(tostring(getElementData(getLocalPlayer(), "winline2"))), -1, screenHeight*0.35-1+25,screenWidth, screenHeight, tocolor( 0, 0, 0, 255), 1.2, "bankgothic", "center", "top")	
			dxDrawColorText(tostring(getElementData(getLocalPlayer(), "winline2")), 0, screenHeight*0.35+25,screenWidth, screenHeight, tocolor(getElementData(getLocalPlayer(), "winr"), getElementData(getLocalPlayer(), "wing"), getElementData(getLocalPlayer(), "winb"), 255), 1.2, "bankgothic", "center", "top")
		end	
	end
end
addEventHandler ( "onClientRender", getRootElement(), fpsread )

local ratingName = false
local ratingRating = false
local ratingPlayed = false
local ratingAlpha = 0
local ratingPart = 0
function forceMapRating(mapname, rating, played)
	if showMapInfo == false then return end
	ratingShown = false
	ratingName = mapname
	ratingRating = rating
	ratingPlayed = played
	ratingAlpha = 0
	ratingPart = 0
	addEventHandler("onClientRender", getRootElement(), mapratingsRender, false, "low+1")
end

function mapratingsRender()
	if ratingPart == 0 then
		ratingAlpha = ratingAlpha+0.05
		if ratingAlpha >= 1 then
			ratingPart = 1
			ratingAlpha = 1
			setTimer(function() ratingPart = 2 end, 5000, 1)
		end
	end
	if ratingPart == 2 then
		ratingAlpha = ratingAlpha-0.05
		if ratingAlpha <= 0 then
			removeEventHandler("onClientRender", getRootElement(), mapratingsRender)
		end
	end
	local x, _, _ = interpolateBetween ( 0, 0, 0, 256, 0, 0, ratingAlpha, "Linear")
	dxDrawImageSection ( screenWidth/2-x, screenHeight-300, x*2, 256, 256-x, 0, x*2, 256, "files/vitaMapinfo.png")
	
	local tx = x
	if tx > 170 then tx = 170 end
	
	dxDrawText( ratingName, screenWidth/2-tx, screenHeight-195, screenWidth/2+tx, screenHeight, tocolor(214,219,145,255), 1, "default-bold", "center", "top", true, false)
	if ratingPlayed == 0 then
		dxDrawText( "played for the first time", screenWidth/2-tx, screenHeight-175, screenWidth/2+tx, screenHeight, tocolor(255,100,100,255), 1, "default-bold", "center", "top", true, false)
	else
		dxDrawText( "played "..ratingPlayed.." times before", screenWidth/2-tx, screenHeight-175, screenWidth/2+tx, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", true, false)
	end
	
	if ratingRating == false then
		dxDrawText( "map not yet rated", screenWidth/2-tx, screenHeight-160, screenWidth/2+tx, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", true, false)
	else
		--dxDrawText( "rated "..ratingRating.."/10", screenWidth/2-tx, screenHeight-160, screenWidth/2+tx, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", true, false)
		dxDrawText(("Likes: %s / Dislikes: %s"):format(ratingRating.likes, ratingRating.dislikes), screenWidth/2-tx, screenHeight-160, screenWidth/2+tx, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", true, false)
	end
	--Todo: remove rate command text
	dxDrawText( "rate this map with /rate [0-1]", screenWidth/2-tx, screenHeight-130, screenWidth/2+tx, screenHeight, tocolor(255,255,255,255), 1, "default", "center", "top", true, false)
end

function chatCheckPulse()
    local chatState = isChatBoxInputActive() or isConsoleActive()
    if chatState then
        setElementData(getLocalPlayer(), "isChatting", true)
    else
        setElementData(getLocalPlayer(), "isChatting", false)
    end
end
setElementData(getLocalPlayer(), "isChatting", false)
setTimer( chatCheckPulse, 250, 0)

-- Todo: Move to Sound class
gVitaMapMusic = false
function onMapSoundReceive(url)
	outputConsole("Mapmusic Stream: " .. tostring(url))
	if isElement(gVitaMapMusic) then stopSound(gVitaMapMusic) end
	
	gVitaMapMusic = _playSound ( url, true )
	if getElementData(getLocalPlayer(), "disableMusic") == true or gWinsound and isElement(gWinsound) then
		setSoundPaused(gVitaMapMusic, true)
	end
end
addEvent( "onMapSoundReceive", true )
addEventHandler( "onMapSoundReceive", getRootElement(),onMapSoundReceive )

-- Todo: Move to Sound class
function onMapSoundStop()
	if isElement(gVitaMapMusic) then
		--outputDebugString("CLIENT: Stopped")
		stopSound(gVitaMapMusic)
	end
end
addEvent( "onMapSoundStop",true )
addEventHandler( "onMapSoundStop", getRootElement(),onMapSoundStop )


local vitaBackgroundAlpha = 0
local vitaBackgroundReach = 0
local isVitaBackground = false
function vitaBackgroundRender()
	if vitaBackgroundReach > vitaBackgroundAlpha and vitaBackgroundReach == 1 then vitaBackgroundAlpha = vitaBackgroundAlpha + 0.05 end
	if vitaBackgroundReach < vitaBackgroundAlpha and vitaBackgroundReach == 0 then vitaBackgroundAlpha = vitaBackgroundAlpha - 0.1 end
	if vitaBackgroundAlpha <= 0 and vitaBackgroundReach == 0 then vitaBackgroundAlpha = 0 removeEventHandler ( "onClientRender", getRootElement(), vitaBackgroundRender) end

	dxDrawImageSection ( 0,0,  screenWidth, screenHeight, 1920/2-screenWidth/2, 1080/2-screenHeight/2, screenWidth, screenHeight, "files/background.png",0,0,0,tocolor(255,255,255,255*vitaBackgroundAlpha) )
end

function vitaBackgroundToggle(toggle)
	if toggle == true and isVitaBackground == false then
		isVitaBackground = true
		vitaBackgroundReach = 1
		addEventHandler("onClientRender", getRootElement(), vitaBackgroundRender, true, "high+2")
	elseif toggle == false then
		removeEventHandler("onClientRender", getRootElement(), vitaBackgroundRender)
		isVitaBackground = false
		vitaBackgroundReach = 0
	end
end

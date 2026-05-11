--[[
Project: vitaCore
File: racemodes-client.lua
Author(s):	Sebihunter
]]--

gWaterCraftIDs = { 539, 460, 417, 447, 472, 473, 493, 595, 484, 430, 453, 452, 446, 454 }

function racemodesClientStart()
		g_Players = getElementsByType('player')

        fadeCamera(false,0.0)
		-- create GUI
		local screenWidth, screenHeight = guiGetScreenSize()
		g_dxGUI = {
			nextMap = dxText:create('#d6db91Next Map: #FFFFFF-', 5, screenHeight -( dxGetFontHeight(1, 'default-bold')/2)*-2 + 5, false, 'default-bold', 1, 'left'),
			mapdisplay = dxText:create('#d6db91Map: #FFFFFFnone', 5, screenHeight - dxGetFontHeight(1, 'default-bold')/2, false, 'default-bold', 1, 'left'),
			money = dxText:create('#d6db91Money: #FFFFFF0 Vero', 5, screenHeight -( dxGetFontHeight(1, 'default-bold')/2)*2 - 5, false, 'default-bold', 1, 'left'),
			--spectators = dxText:create('#d6db91Spectators: #FFFFFF0', 5, screenHeight - (dxGetFontHeight(1, 'default-bold')/2)*3 - 10, false, 'default-bold', 1, 'left'),
			initiate = dxText:create('A new map has been started!', screenWidth/2, screenHeight/2, false, 'bankgothic', 0.7, 'center')
		}
		
		g_GUI = {
			timeleft = guiCreateLabel(screenWidth/2-97, 23, 108, 30, '', false),
			timepassed = guiCreateLabel(screenWidth/2-13, 23, 108, 30, '', false),
			hurry = false
		}
		
		g_dxGUI.mapdisplay:type('stroke', 1, 0, 0, 0, 150)
		--g_dxGUI.spectators:type('stroke', 1, 0, 0, 0, 150)
		g_dxGUI.money:type('stroke', 1, 0, 0, 0, 150)
		g_dxGUI.nextMap:type('stroke', 1, 0, 0, 0, 150)
		g_dxGUI.initiate:type('stroke', 1, 0, 0, 0, 255)
		g_dxGUI.initiate:visible(false)		

		guiSetFont(g_GUI.timeleft, 'default-bold-small')
		guiLabelSetHorizontalAlign(g_GUI.timeleft, 'center')
		guiSetFont(g_GUI.timepassed, 'default-bold-small')
		guiLabelSetHorizontalAlign(g_GUI.timepassed, 'center')
		
		hideGUIComponents("nextMap", "mapdisplay", "money", "initiate", "timeleft", "timepassed")
		--g_WaterCheckTimer = setTimer(checkWater, 1000, 0)
		
		setCameraClip ( true, false )
end


countdownImage = false
function countdownClientFunc(id)
	if id == 4 then
		--g_dxGUI.initiate:visible(true)
		--setTimer(function() g_dxGUI.initiate:color(math.random(0,255), math.random(0,255), math.random(0,255), 255) end, 200, 10)
		--setTimer(function() g_dxGUI.initiate:visible(false) end, 2000, 1)
	else
		local countdownWidth = resAdjust(474)
		local countdownHeight = resAdjust(204)
		
		if countdownImage then
			if isElement(countdownImage[1]) then
				destroyElement(countdownImage[1])
				countdownImage = false
			end
		end
		
		countdownImage = {}
		countdownImage[1] = guiCreateStaticImage(
			math.floor(screenWidth/2 - countdownWidth/2),
			math.floor(screenHeight/2 - countdownHeight/2),
			countdownWidth,
			countdownHeight,
			"files/countdown_"..id..".png",
			false,
			nil
		)			
		
		if id ~= 0 then
			Animation.createAndPlay(
				countdownImage,
				{ from = 0, to = 1, time = 1000, fn = zoomFades, width = countdownWidth, height = countdownHeight }
			)	
		else
			raceTime_startTick = getTickCount()
			-- TODO: Special effect at 0 - this is just WIP
			Animation.createAndPlay(
				countdownImage,
				{ from = 0, to = 1, time = 1000, fn = zoomFades, width = countdownWidth, height = countdownHeight }
			)
		end
		
		setTimer(function(countdownImage)
			if isElement(countdownImage) then
				destroyElement(countdownImage)
				countdownImage = false
			end
		end, 1500, 1, countdownImage[1])
	end
end

function setStartTickLater(timerLeft)
	timerLeft = getElementData(gRaceModes[getPlayerGameMode(getLocalPlayer())].realelement, "duration")-timerLeft
	raceTime_startTick = getTickCount()-timerLeft
	guiSetText(g_GUI.timepassed, "00:00.000")
end

function setPassedTime(anus)
	guiSetText(g_GUI.timepassed, anus)
end

local animex = false
local isShown = false
function nextMapLabel ()
	local i = 0
	if animex == false and isShown == false then
		setTimer ( function ()
			i = i + 0.5
			g_dxGUI.nextMap:position(5,screenHeight +( dxGetFontHeight(0.5, 'bankgothic')/2) - i- 1.5,false)
			g_dxGUI.mapdisplay:position(5,screenHeight - dxGetFontHeight(0.5, 'bankgothic')/2 - i,false)
			--g_dxGUI.spectators:position(5,screenHeight - (dxGetFontHeight(0.5, 'bankgothic')/2)*3 - 10 - i,false)
			g_dxGUI.money:position(5,screenHeight -( dxGetFontHeight(0.5, 'bankgothic')/2)*2 - 5 - i,false)
			if i == 15 then
				isShown = true
			end			
		end
		, 50, 30)
		animex = true
	end
end

function resetNextMap ()
	local i = 0
	if isShown == true and animex == true then
		setTimer ( function ()
			i = i + 0.5
			local screenWidth, screenHeight = guiGetScreenSize()
			g_dxGUI.nextMap:position(5,screenHeight +( dxGetFontHeight(0.5, 'bankgothic')/2) + i- 1.5 - 15 ,false)
			g_dxGUI.mapdisplay:position(5,screenHeight - dxGetFontHeight(0.5, 'bankgothic')/2 + i - 15 ,false)
			--g_dxGUI.spectators:position(5,screenHeight - (dxGetFontHeight(0.5, 'bankgothic')/2)*3 - 10 + i - 15 ,false)
			g_dxGUI.money:position(5,screenHeight -( dxGetFontHeight(0.5, 'bankgothic')/2)*2 - 5 + i - 15 ,false)
			if i == 15 then
				isShown = false
			end
		end
		, 50, 30)		
		animex = false
	end
end

function onClientRender()
	setBlurLevel(0)
	
	local playerGamemode = getPlayerGameMode(getLocalPlayer())
	cX, cY, cZ = getCameraMatrix()	
	
	if playerGamemode == 0 then if isElement(g_GUI.hurry) then hideHurry() end allowNewHurry = true return false end

	local spectators = 0
	for i,v in pairs(getGamemodePlayers(playerGamemode)) do
		if getElementData(v, "spectatesPlayer") == getLocalPlayer() then
			spectators = spectators+1
		end
	end
	
	local rankingboardTable = getElementData(gRaceModes[getPlayerGameMode(getLocalPlayer())].realelement, "rankingboard")
	if rankingboardTable then
		local lp = getLocalPlayer()
		local target = getCameraTarget()
		if target and getElementType(target) == "vehicle" and isElement(getVehicleOccupant(target)) then
			lp = getVehicleOccupant(target)
		end					
		
		local rankSpectators = 0
		for i,v in ipairs(rankingboardTable) do
			if v and v ~= "" and v.text then
				if v.ply and isElement(v.ply) and getElementData(v.ply, "spectatesPlayer") == lp then
					rankSpectators = rankSpectators+1
					dxDrawImage ( 30, 220+13*i, 16, 16, "files/eye.png" )
					dxDrawText ( i..") "..removeColorCoding(tostring(v.text)), 50+1, 220+13*i+1 , screenWidth, screenHeight, tocolor(0,0,0,255) , 1, "default-bold", "left", "top", false, false, false, false, false)
					dxDrawText ( i..") "..tostring(v.text), 50, 220+13*i , screenWidth, screenHeight, tocolor(255,255,255,255) , 1, "default-bold", "left", "top", false, false, false, true, false)				
				else
					dxDrawText ( i..") "..removeColorCoding(tostring(v.text)), 30+1, 220+13*i+1 , screenWidth, screenHeight, tocolor(0,0,0,255) , 1, "default-bold", "left", "top", false, false, false, false, false)
					dxDrawText ( i..") "..tostring(v.text), 30, 220+13*i , screenWidth, screenHeight, tocolor(255,255,255,255) , 1, "default-bold", "left", "top", false, false, false, true, false)
				end
			end
		end
		if spectators > rankSpectators then
			if spectators-rankSpectators == 1 then
				dxDrawText ( "+ "..spectators-rankSpectators.." spectator", 30+1, 220+13*(#rankingboardTable+2)+1 , screenWidth, screenHeight, tocolor(0,0,0,255) , 1, "default-bold", "left", "top", false, false, false, false, false)
				dxDrawText ( "+ "..spectators-rankSpectators.." spectator", 30, 220+13*(#rankingboardTable+2) , screenWidth, screenHeight, tocolor(255,255,255,255) , 1, "default-bold", "left", "top", false, false, false, true, false)			
			else
				dxDrawText ( "+ "..spectators-rankSpectators.." spectators", 30+1, 220+13*(#rankingboardTable+2)+1 , screenWidth, screenHeight, tocolor(0,0,0,255) , 1, "default-bold", "left", "top", false, false, false, false, false)
				dxDrawText ( "+ "..spectators-rankSpectators.." spectators", 30, 220+13*(#rankingboardTable+2) , screenWidth, screenHeight, tocolor(255,255,255,255) , 1, "default-bold", "left", "top", false, false, false, true, false)
			end
		end
	end
		
		
	
	if playerGamemode == 4 then 
		if getElementData(getLocalPlayer(), "mapname") then
			g_dxGUI.mapdisplay:text("#d6db91Mode: #FFFFFF"..tostring(getElementData(getLocalPlayer(), "mapname")))
			g_dxGUI.money:text("#d6db91Money: #FFFFFF"..tostring(getPlayerMoney()).." Vero")
		end
		return
	end

	if playerGamemode == 5 and getElementData(getLocalPlayer(), "state") == "dead" and getElementData(getLocalPlayer(), "ghostmod") == true and showUserGui == false then
		dxDrawText("Press 'n' to respawn. Press 'c' to respawn at the start.", 1, screenHeight-49, screenWidth, screenHeight, tocolor(0,0,0,255), 1 , "default-bold", "center",  "top", false, false, false)
		dxDrawText("#d6db91Press 'n' to respawn. Press 'c' to respawn at the start.", 0, screenHeight-50, screenWidth, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", false, false, false, true)	
	end
	
	g_dxGUI.mapdisplay:text("#d6db91Map: #FFFFFF"..tostring(getElementData(getLocalPlayer(), "mapname")))
	g_dxGUI.nextMap:text("#d6db91Next Map: #FFFFFF"..tostring(getElementData(gRaceModes[getPlayerGameMode(getLocalPlayer())].realelement, "nextmapname")))
	g_dxGUI.money:text("#d6db91Money: #FFFFFF"..tostring(getPlayerMoney()).." Vero")

	local angle = math.fmod((getTickCount() - g_PickupStartTick) * 360 / 2000, 360)
	for _, v in pairs(getElementsByType ( "racePickup" )) do
		if getElementData(v, "object") then
			setElementRotation(getElementData(v, "object"), 0, 0, angle)
			if getElementData(v, "type") == "vehicle" then
				if isElementOnScreen (getElementData(v, "object")) then
					local x, y, z = getElementPosition(getElementData(v, "object"))
					local distanceToPickup = getDistanceBetweenPoints3D(cX, cY, cZ, x,y,z)
					if distanceToPickup < 60 then
						if isLineOfSightClear(cX, cY, cZ, x,y,z, true, false, false, true, false) then
							local sx, sy =  getScreenFromWorldPosition ( x, y, z+1.5 )
							local distanceToPickup = getDistanceBetweenPoints3D(cX, cY, cZ, x,y,z)
							local scale = (60/distanceToPickup)*0.7
							if sx and sy then
								dxDrawText ( "["..getVehicleNameFromModel ( getElementData(v, "vehicle" )).."]", sx-19, sy+1, sx+20, sy+20, tocolor(0,0,0,255), scale, "default-bold", "center", "top", false, false, false, false, true)
								dxDrawText ( "["..getVehicleNameFromModel ( getElementData(v, "vehicle" )).."]", sx-20, sy, sx+20, sy+20, tocolor(255,255,255,255), scale, "default-bold", "center", "top", false, false, false, false, true)
							end
						end
					end
				end
			end
		end
	end	
	
	if getElementData(getLocalPlayer(), "state") == "alive" then
		g_dxGUI.initiate:visible(false)
	end
	
--	g_dxGUI.spectators:text("#d6db91Spectators: #FFFFFF"..spectators)
	
	if getElementData(gRaceModes[getPlayerGameMode(getLocalPlayer())].realelement, "nextmap") ~= "random" then
		nextMapLabel ()
	else
		resetNextMap ()
	end
	
	if playerGamemode == 3 and getElementData(getLocalPlayer(), "state") ~= "not ready" and getElementData(getLocalPlayer(), "state") ~= "ready" and getElementData(gRaceModes[playerGamemode].realelement, "startTick") then
		local lp = getLocalPlayer()
		local target = getCameraTarget()
		if target and getElementType(target) == "vehicle" and isElement(getVehicleOccupant(target)) then
			lp = getVehicleOccupant(target)
		end		
		dxDrawImage(screenWidth-128, screenHeight/2-500/2, 128, 500, "files/vita_racerank.png")

		local allCheckpoints = getElementData(gRaceModes[playerGamemode].realelement, "allCP")
		
		for i,v in ipairs(getGamemodePlayers(playerGamemode)) do
			if getElementData(v, "racePos") and getElementData(v, "racePos") == 1 and v ~= lp and getElementData(v, "currentCP") ~= getElementData(lp, "currentCP") then
				local myCheckpoint = getElementData(v, "currentCP")
				local x, y, z = interpolateBetween(0,0,0,0,370,0,myCheckpoint/allCheckpoints, "Linear")
				if y ~= 0 then
					dxDrawImageSection ( screenWidth-128+97, screenHeight/2+151-y, 19, y, 0, 368-y, 19, y, "files/vita_racerank_list.png", 0, 0, 0, tocolor(150,150,0,255))
					dxDrawShadowedText("1st. "..getPlayerName(v).." ("..myCheckpoint.."/"..allCheckpoints..") ->",0,screenHeight/2+151-y-7, screenWidth-128+82, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 1, "default" , "right", "top", false, false, false, false)
				end					
				break
			end
		end
		
		local myCheckpoint = getElementData(lp, "currentCP")
		local x, y, z = interpolateBetween(0,0,0,0,370,0,myCheckpoint/allCheckpoints, "Linear")
		if y ~= 0 then
			dxDrawImageSection ( screenWidth-128+97, screenHeight/2+151-y, 19, y, 0, 368-y, 19, y, "files/vita_racerank_list.png", 0, 0, 0, tocolor(255,255,0,255))
		end
		dxDrawText ( myCheckpoint.." / "..allCheckpoints, screenWidth-128+38, screenHeight/2+189, screenWidth, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", false, false, false, false, true)
		
		local racePos = "-"
		if getElementData(lp, "racePos") then racePos = getElementData(lp, "racePos") end
		dxDrawText ( tostring(racePos).." / "..#getGamemodePlayers(playerGamemode), screenWidth-128+37, screenHeight/2+213, screenWidth, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", false, false, false, false, true)
	end		
	
	if getElementData(getLocalPlayer(), "infoText") then
		dxDrawShadowedText(tostring(getElementData(getLocalPlayer(), "infoText")),0,screenHeight-160, screenWidth, screenHeight, tocolor(255,255,255,255),tocolor(0,0,0,255), 2,"default-bold", "center", "top", false, false, false, true)	
	end

	if getElementData(getLocalPlayer(), "-Text") then
		dxDrawShadowedText(tostring(getElementData(getLocalPlayer(), "-Text")),0,screenHeight-120, screenWidth, screenHeight, tocolor(0,255,0,255),tocolor(0,0,0,255), 1.2,"default-bold", "center", "top", false, false, false, true)	
	end	
	if getElementData(getLocalPlayer(), "+Text") then
		dxDrawShadowedText(tostring(getElementData(getLocalPlayer(), "+Text")),0,screenHeight-105, screenWidth, screenHeight, tocolor(255,0,0,255),tocolor(0,0,0,255), 1.2,"default-bold", "center", "top", false, false, false, true)	
	end	

	
	if guiGetVisible(g_GUI.timeleft) == true then
		
		if getElementData(gRaceModes[playerGamemode].realelement, "startTick") then
			raceTime_duration = getElementData(gRaceModes[playerGamemode].realelement, "duration")
			raceTime_passedTime = getTickCount()-raceTime_startTick
			raceTime_leftTime = raceTime_duration - raceTime_passedTime
			guiSetText(g_GUI.timeleft, msToTimeStr(raceTime_leftTime > 0 and raceTime_leftTime or 0))
			
			--if getElementData(getLocalPlayer(), "state") == "alive" then
				guiSetText(g_GUI.timepassed, msToTimeStr(raceTime_passedTime))
			--end
		else
			raceTime_leftTime = getElementData(gRaceModes[playerGamemode].realelement, "duration")
			guiSetText(g_GUI.timeleft, msToTimeStr(raceTime_leftTime > 0 and raceTime_leftTime or 0))
			guiSetText(g_GUI.timepassed, "00:00.000")
		end
		
		if (showDeadAlive == 1) and screenWidth > 1024 and not isInGamemode(getLocalPlayer(), 3) then
			local allPeople =  #getGamemodePlayers(playerGamemode)
			local alivePeople = #getAliveGamemodePlayers(playerGamemode)
			local deadPeople = allPeople - alivePeople
			dxDrawImage(screenWidth/2-1024/2, 0, 1024, 128, "files/vitatime.png")
			dxDrawText ( tostring(deadPeople), screenWidth/2-259, 5, screenWidth/2-236, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center")
			dxDrawText ( tostring(alivePeople), screenWidth/2+235, 5, screenWidth/2+259, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center")	
			dxDrawImageSection ( screenWidth/2-111.5-69*deadPeople/allPeople, 8.5, 69*deadPeople/allPeople, 10, 0, 0, 69*deadPeople/allPeople, 10, "files/vitaprogress.png", 0, 0, 0, tocolor(255,0,0,255))	
			dxDrawImageSection ( screenWidth/2+111.5, 8.5, 69*alivePeople/allPeople, 10, 0, 0, 69*alivePeople/allPeople, 10, "files/vitaprogress.png", 0, 0, 0, tocolor(0,255,0,255))					
		elseif guiGetVisible(g_GUI.timeleft) == true then
			dxDrawImage(screenWidth/2-1024/2, 0, 1024,128, "files/vitatime2.png")
		end		
		
		if raceTime_leftTime <= 30000 and raceTime_leftTime > 0 and (not isElement(g_GUI.hurry)) and allowNewHurry == true and getElementData(getLocalPlayer(), "state") ~= "not ready" and getElementData(getLocalPlayer(), "state") ~= "ready" then
			startHurry()
		end
	else
		if isElement(g_GUI.hurry) then hideHurry() end
	end
end
addEventHandler("onClientRender", getRootElement(), onClientRender)

local allowNewHurry = true
function startHurry()
	if not isElement(g_GUI.hurry)  then
		allowNewHurry = false
		g_GUI.hurry = guiCreateStaticImage(screenWidth/2-355/2, screenHeight-150, 355, 108, 'files/hurry.png', false, nil)
		guiSetAlpha(g_GUI.hurry, 0)
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeIn(800))
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiPulse(1000))
		guiLabelSetColor(g_GUI.timeleft, 255, 0, 0)
	end
end

function hideHurry()
	if isElement(g_GUI.hurry) then
		Animation.createAndPlay(g_GUI.hurry, Animation.presets.guiFadeOut(500), destroyElement)
	end
	guiLabelSetColor(g_GUI.timeleft, 255, 255, 255)
end

function allowNewHurryFunc()
	allowNewHurry = true
end

local lastNitroTick = 0
function onClientColShapeHit(element, matchingDimension)
	if not matchingDimension then return end

	local veh = getPedOccupiedVehicle(localPlayer)
	if not veh then return false end

    if ( element == veh ) then
		local pickup = getElementData(source, "pickup")
		if pickup then
			local data = { }
			data.type = getElementData(pickup, "type")
			data.vehicle = getElementData(pickup, "vehicle")
			data.id = getElementData(pickup, "id")

			if data.type == "nitro" then
				addVehicleUpgrade(veh, 1010)
				playSoundFrontEnd(46)

				lastNitroTick = getTickCount()
				triggerServerEvent('syncVehicleNitro', getLocalPlayer())

				if getPlayerGameMode(localPlayer) == 5 and raceTime_passedTime then
					Timings:getSingleton():hitPickup(data.id, raceTime_passedTime)
				end
			elseif data.type == "repair" then
				fixVehicle(veh)
				playSoundFrontEnd(46)
			elseif data.type == "vehicle" then
				if data.vehicle ~= getElementModel(veh) then
					if getElementData(getLocalPlayer(), "state") == "replaying" and data.vehicle == 425 and getPlayerGameMode(getLocalPlayer()) == 5 then --DM Gamemode
						outputChatBox("#7A142D:Hunter: #ffffff People in replay mode are not allowed to get the hunter", 255, 255, 255, true)
						return false
					end

					--Use a timer to fake lag. I know this is horrible but some maps rely on that little lag on vehiclechange if they should work properly
					setTimer(changeVehicle, 50, 1, veh, data.vehicle)
				end
			end
		end
    end
end
addEventHandler("onClientColShapeHit",getRootElement(),onClientColShapeHit)

function changeVehicle(veh, model)
	if isElement(veh) then		
		if model ~= getElementModel(veh) then
			if getPlayerGameMode(getLocalPlayer()) == 5 and model == 425 then --DM Gamemode
				Timings:getSingleton():hitPickup("Hunter", raceTime_passedTime)

				local timings = Timings:getSingleton():getTimings()
				triggerServerEvent('playerGotHunter', localPlayer, raceTime_passedTime, timings)
			end

			alignVehicleWithUp(veh)
			setElementModel(veh, model)
			changeVehicleClient(veh)
			if getTickCount() - lastNitroTick < 200 then
				addVehicleUpgrade(veh, 1010)
			end
			playSoundFrontEnd(46)

			triggerServerEvent('syncVehicleModel', getLocalPlayer(), model)

			if getElementData(getLocalPlayer(), "Wheels") and  getElementData(getLocalPlayer(), "Wheels") ~= 0 then
				addVehicleUpgrade ( veh, getElementData(getLocalPlayer(), "Wheels") )
			end
		end
	end
end
addEvent("changeVehicle", true)

function changeVehicleClient(veh)
	local x, y, z = getElementPosition(veh)   
	local newVehicleHeight = getElementDistanceFromCentreOfMassToBaseOfModel(veh)
	if gVehicleHeight and newVehicleHeight > gVehicleHeight then
		z = z - g_PrevVehicleHeight + newVehicleHeight
	end
	
	z = z + 1 -- Classichange
	
	setElementPosition(veh, x, y, z)
	checkVehicleIsHelicopter(veh)
end
addEvent("changeVehicleClient", true)

function checkWater()
	if getPlayerGameMode(getLocalPlayer()) == 0 or getPlayerGameMode(getLocalPlayer()) == 6 then return end
	if getPlayerGameMode(getLocalPlayer()) == 4 and sumoGame == false then return end

	local veh = getPedOccupiedVehicle(getLocalPlayer())
	if veh then
		local iswater = false
		for i,v in ipairs(gWaterCraftIDs) do
			if v == getElementModel(veh) then
				iswater = true
			end
		end
			
		if (iswater == false) and (getElementData(getLocalPlayer(), "state") ~= "finished") then
			local x, y, z = getElementPosition(veh)
			z1 = z
			if z < 0 then z1 = 0 end
			local waterZ = getWaterLevel(x, y, z1)
			if waterZ and z < waterZ - 0.5 and isPlayerAlive(getLocalPlayer()) then
				triggerServerEvent('onRequestKillPlayer', getLocalPlayer())
			end
		end
	end
end
setTimer(checkWater, 1000,0)
addEventHandler("changeVehicleClient", getRootElement(), changeVehicleClient)

function clientDamage ( attacker, weapon, bodypart )
	if getElementData(getLocalPlayer(), "state") == "finished" then
		cancelEvent()
	end
end
addEventHandler ( "onClientPlayerDamage", getLocalPlayer(), clientDamage )


lastColTimer = false
addEventHandler("onClientVehicleCollision", root,
    function(collider,force, bodyPart, x, y, z, nx, ny, nz)
         if ( source == getPedOccupiedVehicle(getLocalPlayer()) ) and getElementData(getLocalPlayer(), "state" ) == "alive" then
            if collider and isElement(collider) and getElementType(collider) == "vehicle" and getVehicleController(collider) then
				setElementData(getLocalPlayer(), "lastCol", getVehicleController(collider))
				if lastColTimer and isTimer(lastColTimer) then killTimer(lastColTimer) end
				lastColTimer = setTimer(function()
					setElementData(getLocalPlayer(), "lastCol", false)
				end, 10000, 1)
			end
         end
    end
)
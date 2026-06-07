--[[
Project: vitaCore
File: toptimes_client.lua
Author(s):	Sebihunter
]]--

local showToptimes = false
local toptimeX = 435
local toptimeTimer = false
local toptimeTable = false
local topSplitsPlayerID = false
local topGhostPlayerID = false

local normalColor = tocolor(255, 255, 255)
local personalColor = tocolor(255, 255, 200)
local splitsColor = tocolor(120, 105, 200)

function toptimeRender()
	if showToptimes == true or showToptimes == "closing" then
		if showToptimes == true and toptimeX > 0 then
			toptimeX = toptimeX-15
		end
		if showToptimes == "closing" and toptimeX <= 435 then
			toptimeX = toptimeX+15
		elseif showToptimes == "closing" and toptimeX >= 435 then
			showToptimes = false
		end
		if not toptimeTable then showToptimes = false return end
		dxDrawImage(screenWidth-436+toptimeX, screenHeight/3, 512,256, "files/toptimes_bg.png",0,0,0,tocolor(255,255,255,255))
		dxDrawLine(screenWidth-352+toptimeX, screenHeight/3+45, screenWidth, screenHeight/3+45, tocolor(255,255,255,50))
		dxDrawText("Rank", screenWidth-345+toptimeX, screenHeight/3+50, screenWidth, screenHeight/3+80, tocolor(255,255,255,255), 0.8)
		dxDrawText("Time", screenWidth-305+toptimeX, screenHeight/3+50, screenWidth, screenHeight/3+80, tocolor(255,255,255,255), 0.8)
		dxDrawText("Player",screenWidth-225+toptimeX, screenHeight/3+50, screenWidth, screenHeight/3+80, tocolor(255,255,255,255), 0.8)
		local isInToptime = false
		for i = 1, 12 do
			local time = toptimeTable[i] and msToTimeStr(toptimeTable[i].time) or "-"
			local playerName = toptimeTable[i] and toptimeTable[i].name or "-"
			local color = normalColor

			if toptimeTable[i] and toptimeTable[i].PlayerID == localPlayer:getID() then
				isInToptime, color = true, personalColor
			end

			if toptimeTable[i] and toptimeTable[i].PlayerID == topSplitsPlayerID then
				color = splitsColor
			end

			local rowY = screenHeight/3+50+13*i
			dxDrawText(i .. ".",   screenWidth-345+toptimeX, rowY, screenWidth, screenHeight/3+80, color, 1, "default-bold", "left")
			dxDrawText(time, 	   screenWidth-305+toptimeX, rowY, screenWidth, screenHeight/3+80, color, 1, "default-bold", "left")
			dxDrawText(playerName, screenWidth-225+toptimeX, rowY, screenWidth, screenHeight/3+80, normalColor, 1, "default-bold", "left", "top", false, false, false, true)

			if toptimeTable[i] and toptimeTable[i].PlayerID == topGhostPlayerID then
                dxDrawImage(screenWidth-250+toptimeX, rowY - 1, 16, 16, "files/ghost_icon.png", 0, 0, 0, splitsColor)
            end
		end

		local hasTime = false
		if toptimeTable and not isInToptime then
			if toptimesCount > 12 then
				for i = 13, toptimesCount do
					if toptimeTable[i].PlayerID == localPlayer:getID() then
						hasTime = true
						dxDrawText(i .. ".", screenWidth-345+toptimeX, screenHeight/3+50+13*13, screenWidth, screenHeight/3+80, personalColor, 1, "default-bold", "left")
						dxDrawText(msToTimeStr(toptimeTable[i].time), screenWidth-305+toptimeX, screenHeight/3+50+13*13, screenWidth, screenHeight/3+80, personalColor, 1, "default-bold", "left")
						dxDrawText(toptimeTable[i].name, screenWidth-225+toptimeX, screenHeight/3+50+13*13, screenWidth, screenHeight/3+80, normalColor, 1, "default-bold", "left", "top", false, false, false, true)
					end
				end
			end

			if not hasTime then
				dxDrawText("-", screenWidth-345+toptimeX, screenHeight/3+50+13*13, screenWidth, screenHeight/3+80, personalColor, 1, "default-bold", "left")
				dxDrawText("-", screenWidth-305+toptimeX, screenHeight/3+50+13*13, screenWidth, screenHeight/3+80, personalColor, 1, "default-bold", "left")
				dxDrawText(localPlayer:getName(), screenWidth-225+toptimeX, screenHeight/3+50+13*13, screenWidth, screenHeight/3+80, normalColor, 1, "default-bold", "left", "top", false, false, false, true)
			end
		end
	end
end
addEventHandler("onClientRender", root, toptimeRender, false, "low+1")

bindKey ( "F5", "down", function(key, keyState)
	if toptimeTable == false then return false end
	if showToptimes == true then
		showToptimes = "closing"
		playSound("files/audio/swosh.mp3")
		if isTimer(toptimeTimer) then
			killTimer(toptimeTimer)
		end
	elseif showToptimes == false then
		playSound("files/audio/swosh.mp3")
		showToptimes = true
		toptimeX = 435
		toptimeTimer = setTimer(function() 
			showToptimes = "closing"
			playSound("files/audio/swosh.mp3")			
		end, 10000, 1)
	end
end )

function forceToptimesOpen()
	if showToptimes ~= true then
		playSound("files/audio/swosh.mp3")
		showToptimes = true
		toptimeX = 435
		toptimeTimer = setTimer(function() 
			showToptimes = "closing"
			playSound("files/audio/swosh.mp3")			
		end, 5000, 1)
	end
end

function setToptimeTable(ttable, splitsId, ghostId, forceOpen)
	toptimeTable = ttable
	toptimesCount = #ttable
	topSplitsPlayerID = splitsId
	topGhostPlayerID = ghostId
	if forceOpen then forceToptimesOpen() end
end
addEvent("initToptimes", true)
addEventHandler("initToptimes", localPlayer, setToptimeTable)
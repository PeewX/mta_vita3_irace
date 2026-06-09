--[[
Project: vitaCore
File: selection-client.lua
Author(s):	Jake
			Sebihunter
]]--

function drawTacho()
	if localPlayer:getGamemode() == 0 then return end
	if showUserGui ~= false then return end
	if not tachoEnabled then return end
	local targetPlayer = localPlayer
	local target = getCameraTarget()
	if target and target.type == "vehicle" then
		targetPlayer = target.controller
	end

	if targetPlayer and targetPlayer.vehicle then
		local healthVeh = targetPlayer.vehicle:getHealth() - 250 --Starts burning @ 250
		local speed = math.round(targetPlayer.vehicle:getSpeed())

		--if speed > 230 then speed = 230 end
		if healthVeh > 750 then healthVeh = 750 end

		dxDrawImage(screenWidth-240, screenHeight-218, 256, 256, "files/tacho/tacho.png",0,0,0,tocolor(255,255,255,255))
		dxDrawText(speed .. " km/h", screenWidth-210, screenHeight-50, screenWidth - 63, screenHeight, tocolor(200, 200, 200), .8, "default-bold", "center")
		local g = (healthVeh/750)*255
		local r = 255-g
		if healthVeh/10 > 0 then
			local sizeHealth = healthVeh/750
			dxDrawImageSection ( screenWidth-35, screenHeight-10-132*sizeHealth, 19, 132*sizeHealth, 0, 132-sizeHealth*132, 19, 132*sizeHealth, "files/tacho/health.png", 0, 0, 0, tocolor(r, g,0,255))
		end
		dxDrawImage(screenWidth-210,screenHeight-166,147,147,"files/tacho/nadel.png",speed+10,0,0,tocolor(255,255,255,255),true)
	end
end
addEventHandler("onClientRender", root, drawTacho)
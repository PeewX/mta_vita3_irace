--[[
Project: vitaCore
File: autoafk-client.lua
Author(s):	Sebihunter
			MrX
]]--

local afktimer = nil
local afkwarntimer = nil

function checkMain()
	if localPlayer.noAFK then return end
	if isLoggedIn(getLocalPlayer()) == true then
		if not AUTO_AFK_ENABLED[getPlayerGameMode(localPlayer)] then
			setElementData(getLocalPlayer(), "AFK", false)
			setElementData(getLocalPlayer(), "warnAFK", false)
			return
		end

		if getPedOccupiedVehicle(localPlayer) and getElementVelocity(getPedOccupiedVehicle(localPlayer)) then
			v = getElementVelocity ( getPedOccupiedVehicle ( getLocalPlayer() ) )
			if(v == 0) and getElementData(getLocalPlayer(), "AFK") ~= true then
				if not isTimer(afktimer) then
					if getElementData(getLocalPlayer(), "state") == "alive"then
						afktimer = setTimer(setAutoafk, 1000*20*1, 1)
						afkwarntimer = setTimer(setAFKWarn, 1000*15*1, 1)
					end
				else
					if getElementData(getLocalPlayer(), "state") ~= "alive" or isElementFrozen(getPedOccupiedVehicle(getLocalPlayer())) or getElementAttachedTo(getPedOccupiedVehicle(getLocalPlayer())) then
						if isTimer(afktimer) then killTimer(afktimer) end
						if isTimer(afkwarntimer) then killTimer(afkwarntimer) end
					end
				end
			else
				if isTimer(afktimer) then killTimer(afktimer) end
				if isTimer(afkwarntimer) then killTimer(afkwarntimer) end
				setElementData(getLocalPlayer(),"warnAFK", false)
			end
		else
			if isTimer(afktimer) then killTimer(afktimer) end
			if isTimer(afkwarntimer) then killTimer(afkwarntimer) end
			setElementData(getLocalPlayer(),"warnAFK", false)
		end
	end
end
setTimer ( checkMain, 100, 0)


function setAutoafk(commandName)
	if getPlayerGameMode(getLocalPlayer()) == 0 or getPlayerGameMode(getLocalPlayer()) == 3 or getPlayerGameMode(getLocalPlayer()) == 4 or getPlayerGameMode(getLocalPlayer()) == 6 then return end
	triggerServerEvent("outputChatBoxToGamemode", getRootElement(), "#00FF00:AFK: #ffffff"..getPlayerName(getLocalPlayer()).."#ffffff is now AFK (Auto AFK).", getPlayerGameMode(getLocalPlayer()), 255, 255, 255, true)
	setElementData(getLocalPlayer(),"warnAFK", false)
	setElementData(getLocalPlayer(),"AFK", true)	
end

function setAFKWarn()
	if getPlayerGameMode(getLocalPlayer()) == 0 or getPlayerGameMode(getLocalPlayer()) == 3 or getPlayerGameMode(getLocalPlayer()) == 4 or getPlayerGameMode(getLocalPlayer()) == 6 then return end
	setElementData(getLocalPlayer(), "warnAFK", true)
end

function setAfk(commandName, ...)
	if getPlayerGameMode(getLocalPlayer()) == 0 or getPlayerGameMode(getLocalPlayer()) == 3 or getPlayerGameMode(getLocalPlayer()) == 4 or getPlayerGameMode(getLocalPlayer()) == 6 then return end
	local reason = table.concat( { ... }, " " )
	if getElementData(getLocalPlayer(), "AFK") == true then
		triggerServerEvent("outputChatBoxToGamemode", getRootElement(), "#00FF00:AFK: #ffffff"..getPlayerName(getLocalPlayer()).."#ffffff is now back.", getPlayerGameMode(getLocalPlayer()), 255, 255, 255, true)
		setElementData(getLocalPlayer(), "AFK", false)
	else
		setElementData(getLocalPlayer(), "AFK", true)
		if reason ~= nil then
			triggerServerEvent("outputChatBoxToGamemode", getRootElement(), "#00FF00:AFK: #ffffff"..getPlayerName(getLocalPlayer()).."#ffffff is now AFK. ( "..reason.." )", getPlayerGameMode(getLocalPlayer()), 255, 255, 255, true)
		else
			triggerServerEvent("outputChatBoxToGamemode", getRootElement(), "#00FF00:AFK: #ffffff"..getPlayerName(getLocalPlayer()).."#ffffff is now AFK.", getPlayerGameMode(getLocalPlayer()), 255, 255, 255, true)
		end
	end
end		
addCommandHandler("afk", setAfk, false)

addEventHandler("onClientPlayerDamage", getLocalPlayer(),
	function()
		if getElementData(getLocalPlayer(), "AFK")  == true then
			cancelEvent()
		end
	end
)
--[[
Project: vitaCore
File: utils-server.lua
Author(s):	Sebihunter
]]--

function critical_error(errmsg)
	outputDebugString("[CRITICAL ERROR] "..tostring(errmsg))
	outputDebugString("[CRITICAL ERROR] iR2.0 Script will now halt")
	stopResource(getThisResource())
	error("Critical Error")
end

--calls a server function. Not triggerable by client!
function callServerFunction(funcname, ...)
    local arg = { ... }
    if (arg[1]) then
        for key, value in next, arg do arg[key] = tonumber(value) or value end
    end
	if not _G[funcname] then outputDebug(debug.traceback()) return end
    loadstring("return "..funcname)()(unpack(arg))
end

function callClientFunction(client, funcname, ...)
    local arg = { ... }
    if (arg[1]) then
        for key, value in next, arg do
            if (type(value) == "number") then arg[key] = tostring(value) end
        end
    end
    -- If the clientside event handler is not in the same resource, replace 'resourceRoot' with the appropriate element
    triggerClientEvent(client, "onServerCallsClientFunction", resourceRoot, funcname, unpack(arg or {}))
end

function setRedoCounter(gamemode, value)
	if gamemode == 1 then
		gRedoCounterSH = value
	elseif gamemode == 2 then
		gRedoCounterDD = value
	elseif gamemode == 3 then
		gRedoCounterRA = value
	elseif gamemode == 5 then
		gRedoCounterDM = value
	end
end

function getRedoCounter(gamemode)
	if gamemode == 1 then
		return gRedoCounterSH
	elseif gamemode == 2 then
		return gRedoCounterDD
	elseif gamemode == 3 then
		return gRedoCounterRA
	elseif gamemode == 5 then
		return gRedoCounterDM
	end
end

--Leere Tabelle serialized: return {{},}--|

local function exportstring( s )
	s = string.format( "%q",s )

	s = string.gsub( s,"\\\n","\\n" )
	s = string.gsub( s,"\r","\\r" )
	s = string.gsub( s,string.char(26),"\"..string.char(26)..\"" )
	return s
end

setPlayerMoney_ = setPlayerMoney
function setPlayerMoney(player, toggle)
	if player then
		setElementData(player, "Money", toggle)
	end
end

getPlayerMoney_ = getPlayerMoney
function getPlayerMoney(player)
	if player then
		return getElementData(player, "Money")
	end
end

givePlayerMoney_ = givePlayerMoney
function givePlayerMoney(player,ammount)
	if player then
		setElementData(player, "Money", getElementData(player, "Money")+ammount)
	end
end

function executeServerCommandHandler(commandHandler, args)
	executeCommandHandler(commandHandler, client, args)
end
addEvent("executeServerCommandHandler", true)
addEventHandler("executeServerCommandHandler", getRootElement(), executeServerCommandHandler)

function outputChatBoxToGamemode(text, id, r,g,b, colorCoded)
	for i,v in pairs(getGamemodePlayers(id)) do
		outputChatBox(text, v, r,g,b, colorCoded)
	end
end
addEvent("outputChatBoxToGamemode", true)
addEventHandler ( "outputChatBoxToGamemode", getRootElement(), outputChatBoxToGamemode )

local donatorBonusTable = {}
function getDonatorBonusState(player, name, maxnum)
	if isElement(player) and getElementData(player, "isDonator") == true then
		if not donatorBonusTable[player] then donatorBonusTable[player] = {} end
		if not donatorBonusTable[player][tostring(name)] then donatorBonusTable[player][tostring(name)] = 0 end
		if maxnum and maxnum > donatorBonusTable[player][tostring(name)] then
			return true
		end
	end
	return false
end

function getDonatorBonusNumber(player, name)
	if isElement(player) and getElementData(player, "isDonator") == true then
		if not donatorBonusTable[player] then donatorBonusTable[player] = {} end
		if not donatorBonusTable[player][tostring(name)] then donatorBonusTable[player][tostring(name)] = 0 end
		return donatorBonusTable[player][tostring(name)]
	end
	return false
end

function incraseDonatorBonusState(player, name)
	if isElement(player) and getElementData(player, "isDonator") == true then
		if not donatorBonusTable[player] then donatorBonusTable[player] = {} end
		if not donatorBonusTable[player][tostring(name)] then donatorBonusTable[player][tostring(name)] = 0 end
		donatorBonusTable[player][tostring(name)] = donatorBonusTable[player][tostring(name)]+1
		return true
	end
	return false
end
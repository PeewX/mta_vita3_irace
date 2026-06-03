--[[
Project: vitaCore
File: utils-shared.lua
Author(s):	Sebihunter
]]--

gSupportedLanguages = {
[1] = "None",
[2] = "Other",
[3] = "Italian",
[4] = "Polish",
[5] = "Turkish",
[6] = "Spanish",
[7] = "Portuguese",
[8] = "Dutch",
[9] = "Arabic",
[10] = "Hebrew",
[11] = "French",
[12] = "German",
[13] = "Lithuanian",
[14] = "Russian"
}

function isEventHandlerAdded( sEventName, pElementAttachedTo, func )
	if 
		type( sEventName ) == 'string' and 
		isElement( pElementAttachedTo ) and 
		type( func ) == 'function' 
	then
		local aAttachedFunctions = getEventHandlers( sEventName, pElementAttachedTo )
		if type( aAttachedFunctions ) == 'table' and #aAttachedFunctions > 0 then
			for i, v in ipairs( aAttachedFunctions ) do
				if v == func then
					return true
				end
			end
		end
	end
 
	return false
end

function table.copy(theTable)
	local t = {}
	for k, v in pairs(theTable) do
		if type(v) == "table" then
			t[k] = table.copy(theTable)
		else
			t[k] = v
		end
	end
	return t
end

function isFloat(number)
	return (math.floor(number) ~= number);
end

function escapeStuff(x)
  return (x:gsub('%%', '')
           :gsub('%^', '')
           :gsub('%$', '')
           :gsub('%(', '')
           :gsub('%)', '')
           :gsub('%.', '')
           :gsub('%[', '')
           :gsub('%]', '')
           :gsub('%*', '')
           :gsub('%+', '')
           :gsub('%-', '')
           :gsub('%?', ''))
end

function getPlayerFromName2(name)
	if not name then return nil end
	local ptable = getElementsByType("player")
	
	local player = getPlayerFromName(name)
	if player then
		return player 
	end
	name = escapeStuff(name)
	name = string.lower(name) -- case insensitive :>
	local p = {}
	for index, player in pairs(getElementsByType("player")) do
		if string.find(string.lower(escapeStuff(getPlayerName(player))), name) then
			p[#p+1] = player
		end
	end
	if #p == 0 then
		return nil
	elseif #p == 1 then
		return p[1]
	else
		return p
	end
end

function timeformat()
 	local time = getRealTime(timestamp)
 
	time.year = time.year + 1900
	time.month = time.month + 1
 
	local datetime = { d = ("%02d"):format(time.monthday), h = ("%02d"):format(time.hour), i = ("%02d"):format(time.minute), m = ("%02d"):format(time.month), s = ("%02d"):format(time.second), y = tostring(time.year):sub(-2), Y = time.year }
	return "["..tostring(datetime.d).."."..tostring(datetime.m).."."..tostring(datetime.Y).." | "..tostring(datetime.h)..":"..tostring(datetime.i)..":"..tostring(datetime.s).."]"
end

function getTimestamp()
	local time = getRealTime()
	local stamp = time.timestamp
	return stamp
end

function math.round(num, decimals)
    decimals = math.pow(10, decimals or 0)
    num = num * decimals
    if num >= 0 then num = math.floor(num + 0.5) else num = math.ceil(num - 0.5) end
    return num / decimals
end

function isLoggedIn(player)
	if getElementData(player, "isLoggedIn") == true then
		return true
	end
	return false
end

function getGamemodePlayers(id)
	local playerTable = {}
	for i,v in pairs(getElementsByType("player")) do
		if getElementData(v, "gameMode") == id then
			playerTable[#playerTable+1] = v
		end
	end
	return playerTable
end

function getAliveGamemodePlayers(id)
	local playerTable = {}
	for i,v in pairs(getElementsByType("player")) do
		if getElementData(v, "gameMode") == id and (getElementData(v, "state") == "alive" or getElementData(v, "state") == "not ready" or getElementData(v, "state") == "ready") then
			playerTable[#playerTable+1] = v
		end
	end
	return playerTable
end

function isPlayerAlive(v)
	if getElementData(v, "state") == "alive" or getElementData(v, "state") == "not ready" or getElementData(v, "state") == "ready" then
		return true
	end
	return false
end

function isInGamemode(player, id)
	if getElementData(player, "gameMode") == id then return true end
	return false
end

function getPlayerRaceVeh(player)
	return getElementData(player, "raceVeh")
end

function getPlayerGameMode(player)
	if player then
		return getElementData(player, "gameMode")
	else return 0 end
end

function getGamemodeElement(id)
	for i,v in pairs(getElementsByType(gRaceModes[id].element)) do
		return v
	end
	return false
end

function getNameFromAccountName(accountname)
	for i,v in pairs(getElementsByType ( "userAccount" )) do
		if getElementData(v, "AccountName") == accountname then
			return getElementData(v, "Name")
		end
	end
	return false
end

-- getPlayerName with color coding removed
_getPlayerName = getPlayerName
function getPlayerName ( player )
	return removeColorCoding ( _getPlayerName ( player ) )
end

-- remove color coding from string
function removeColorCoding ( name, nocentiseconds )
	return type(name)=='string' and string.gsub ( name, '#%x%x%x%x%x%x', '' ) or name
end

function msToTimeStr(ms, nocentiseconds, nm)
	if not ms then return '' end

	local centiseconds = tostring(math.floor(math.fmod(ms, 1000)))
	local s = math.floor(ms / 1000)
	local seconds = tostring(math.fmod(s, 60))
	local minutes = tostring(math.floor(s / 60))

	if nocentiseconds then
		return ("%.2d:%.2d"):format(minutes, seconds)
	elseif nm then
		return ("%d.%.3d"):format(seconds, centiseconds)
	else
		return ("%.2d:%.2d.%.3d"):format(minutes, seconds, centiseconds)
	end
end

function getTickTimeStr()
    return msToTimeStr(getTickCount())
end
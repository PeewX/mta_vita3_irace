--[[
Project: vitaCore
File: admin-server.lua
Author(s):	Sebihunter
]]--

function deletetime(player, commandname, Value)
	if not player:hasRights("Moderator") then return end
	--Todo: Anpassen an DatabaseMap Klasse
	outputChatBox ( "#FF0000:ERROR: #FFFFFFThis function is not ready now.", player, 255, 0, 0, true )
	if true then return false end

	Value = tonumber(Value)
	if Value== nil then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /deletetime [ID]", player, 255, 0, 0, true )
	else
		local gamemode = getPlayerGameMode(player)
		if gamemode == gGamemodeDM or gamemode == gGamemodeRA  then else outputChatBox ( "#FF0000:ERROR: #FFFFFFThis can be only used in DM and RACE.", player, 255, 0, 0, true ) return false end
		local localToptimes = {}
		if gamemode == gGamemodeDM then localToptimes = gToptimesDM end
		if gamemode == gGamemodeRA then localToptimes = gToptimesRA end
		if localToptimes ~= false then
			if not localToptimes[Value] then  outputChatBox ( "#FF0000:ERROR: #FFFFFFToptime with ID "..Value.." not found.", player, 255, 0, 0, true ) return false end
			if localToptimes[Value].name then
				if Value <= 12 then
					if localToptimes[13] and localToptimes[13].name and Value == 12 then
						for i,v in pairs(getElementsByType("player")) do
							if getElementData(v, "AccountName") == localToptimes[13].name then
								setElementData(v, "TopTimes", getElementData(v, "TopTimes")+1)
								setElementData(v, "TopTimeCounter", getElementData(v, "TopTimeCounter")+1)	
							end
						end							
					end
					for i,v in pairs(getElementsByType("player")) do
						if getElementData(v, "AccountName") == localToptimes[Value].name then
							setElementData(v, "TopTimes", getElementData(v, "TopTimes")-1)
							setElementData(v, "TopTimeCounter", getElementData(v, "TopTimeCounter")-1)	
						end
					end
				end			
				outputChatBoxToGamemode ("#125861:ADMIN:#FFFFFF Toptime #"..tostring(Value).." by "..tostring(localToptimes[Value].name).." has been removed by "..tostring(getPlayerName(player))..".", gamemode, 125, 125, 125, true)
				localToptimes = removeToptime(localToptimes, Value)
				for theKey,thePlayer in ipairs(getGamemodePlayers(gamemode)) do
					sendToptimes(thePlayer, localToptimes)
				end
				if gamemode == gGamemodeDM then gToptimesDM = localToptimes end
				if gamemode == gGamemodeRA then gToptimesRA = localToptimes end	
			end
		end
	end
end
addCommandHandler("deletetime", deletetime)

function skipMap(player, commandName)
	if not player:hasRights("Moderator") then return end

	local gameMode = getPlayerGameMode(player)
	if gameMode ~= 0 and gameMode ~= gGamemodeMO then
		if gameMode == gGamemodeFUN then
			unloadModeFUN()
			startVoteFUN()
			for i,v in ipairs(getGamemodePlayers(gameMode)) do
				triggerClientEvent ( v, "addNotification", getRootElement(), 3, 18, 88, 97, "Current mode skipped by "..getPlayerName(player).."." )
			end			
		else
			local gameElement
			if gameMode == 1 then gameElement = gElementSH
			elseif gameMode == 2 then gameElement = gElementDD 
			elseif gameMode == 3 then gameElement = gElementRA 
			elseif gameMode == 5 then gameElement = gElementDM
			elseif gameMode == GAMEMODES.TT then gameElement = TimeTrial:getSingleton().m_Element
			else return end
			callServerFunction(gRaceModes[gameMode].loadfunc, getElementData(gameElement, "nextmap"))
			for i,v in ipairs(getGamemodePlayers(gameMode)) do
				triggerClientEvent ( v, "addNotification", getRootElement(), 3, 18, 88, 97, "Current map skipped by "..getPlayerName(player).."." )
			end
		end
	end
end
addCommandHandler("skipMap", skipMap)

function redoMap(player, commandName)
	if not player:hasRights("Moderator") then return end

	local gameMode = getPlayerGameMode(player)
	if gameMode ~= 0 and gameMode ~= gGamemodeFUN and gameMode ~= gGamemodeMO then
		local gameModeElement = getGamemodeElement(gameMode)
		if getElementData(gameModeElement, "map") ~= "none" and getElementData(gameModeElement, "nextmap") == "random" then
			--if getRedoCounter(getPlayerGameMode(player)) == 0 then
				if setNextMap(gameMode, getElementData(gameModeElement, "map")) then
					setRedoCounter(getPlayerGameMode(player), 2)
					for i,v in ipairs(getGamemodePlayers(getPlayerGameMode(player))) do
						triggerClientEvent ( v, "addNotification", getRootElement(), 3, 18, 88, 97, "Mapredo set by "..getPlayerName(player).."." )
					end
					--outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(player).." #FFFFFFhas set the map to be replayed as next map.",gameMode, 255, 0, 0, true)
				end
			--else
			--	triggerClientEvent ( player, "addNotification", getRootElement(), 1, 255,0,0, "Map has already been redone." )
			--end
		else
			triggerClientEvent ( player, "addNotification", getRootElement(), 1, 255,0,0, "Next map is already set." )
		end
	end
end
addCommandHandler("redo", redoMap)

function setMap(player, commandName, ...)
	if not player:hasRights("Moderator") then return end

	local mapname = table.concat(arg, " ")
	local gameMode = getPlayerGameMode(player)
	if gameMode ~= 0 and gameMode ~= gGamemodeFUN  and gameMode ~= gGamemodeMO then
		local gameModeElement = getGamemodeElement(gameMode)
		if getElementData(gameModeElement, "map") ~= "none" and getElementData(gameModeElement, "nextmap") == "random" then
			if setNextMap(gameMode, mapname) or (getMapNameByRealName(mapname) ~= false and setNextMap(gameMode, getMapNameByRealName(mapname))) then
				for _, v in pairs(getGamemodePlayers(getPlayerGameMode(player))) do
					v:triggerEvent("addNotification", 3, 18, 88, 97, ("Next map (%s) set by %s"):format(gameModeElement:getData("nextmapname"), getPlayerName(player)))
					--triggerClientEvent ( v, "addNotification", getRootElement(), 3, 18, 88, 97, "Next map ("..getElementData(gameModeElement, "nextmapname")..") set by "..getPlayerName(player).."." )
				end				
				--outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(player).." #FFFFFFhas set the next map to "..getElementData(gameModeElement, "nextmapname")..".",gameMode, 255, 0, 0, true)	
			else
				triggerClientEvent ( player, "addNotification", getRootElement(), 1, 255,0,0, "Map could not be found." )
			end
		else
			triggerClientEvent ( player, "addNotification", getRootElement(), 1, 255,0,0, "Next map is already set." )
		end
	end
end
addCommandHandler("setnextmap", setMap)

function fixMap(player, commandName, ...)
	if not player:hasRights("Member") then return end

	local mapname = table.concat(arg, " ")
	if mapname == "" then
		triggerClientEvent ( player, "addNotification", getRootElement(), 1, 255,0,0, "Map could not be found." )
		return
	end

	local resource = getResourceFromName(mapname) or getResourceFromName(getMapNameByRealName(mapname))
	if resource then
		local resourcename = getResourceName(resource)
		local displayname = getResourceInfo(resource, "name")

		sql:queryFetchSingle(Async.waitFor(self), "SELECT userID, info FROM ??_markedmaps WHERE resourcename = ?", sql:getPrefix(), resourcename)
		local result = Async.wait()

		if result and result.userID and result.info then
			player:triggerEvent("addNotification", 1, 255, 0, 0, ("Map is already marked to %s by %s"):format(result.info, Account.getNameFromID(result.userID)))
			return false
		end

		sql:queryExec("INSERT INTO ??_markedmaps (resourcename, displayname, userID, info, date) VALUES (?, ?, ?, ?, NOW())", sql:getPrefix(), resourcename, displayname, player.m_ID, "fix")

		triggerClientEvent(getGamemodePlayers(getPlayerGameMode(player)), "addNotification", root, 3, 18, 88, 97, ("Map %s has been marked to be fixed by %s"):format(displayname, player.name))
	else
		player:triggerEvent("addNotification", 1, 255,0,0, "Map could not be found." )
	end
end
addCommandHandler("fixMap", function(...) Async.create(fixMap)(...) end)

function deleteMap(player, commandName, ...)
	if not player:hasRights("Member") then return end

	local mapname = table.concat(arg, " ")
	if mapname == "" then
		triggerClientEvent ( player, "addNotification", getRootElement(), 1, 255,0,0, "Map could not be found." )
		return
	end
	local resource = getResourceFromName(mapname) or getResourceFromName(getMapNameByRealName(mapname))
	if resource then
		local resourcename = getResourceName(resource)
		local displayname = getResourceInfo(resource, "name")

		sql:queryFetchSingle(Async.waitFor(self), "SELECT userID, info FROM ??_markedmaps WHERE resourcename = ?", sql:getPrefix(), resourcename)
		local result = Async.wait()

		if result and result.userID and result.info then
			player:triggerEvent("addNotification", 1, 255, 0, 0, ("Map is already marked to %s by %s"):format(result.info, Account.getNameFromID(result.userID)))
			return false
		end

		sql:queryExec("INSERT INTO ??_markedmaps (resourcename, displayname, userID, info, date) VALUES (?, ?, ?, ?, NOW())", sql:getPrefix(), resourcename, displayname, player.m_ID, "delete")

		triggerClientEvent(getGamemodePlayers(getPlayerGameMode(player)), "addNotification", root, 3, 18, 88, 97, ("Map %s has been marked to be deleted by %s"):format(displayname, player.name))
	else
		player:triggerEvent("addNotification", 1, 255,0,0, "Map could not be found." )
	end
end
addCommandHandler("deleteMap", function(...) Async.create(deleteMap)(...) end)

function badumtss(source)
	if not source:hasRights("CoLeader") then return end
	outputChatBoxToGamemode ( "#FF5435~Ba Dum Tss~", getPlayerGameMode(source), 255, 0, 0, true )
	for i,v in ipairs(getGamemodePlayers(getPlayerGameMode(source))) do
		callClientFunction(v, "playSound", "files/audio/badumtss.mp3")
	end
end
addCommandHandler("badumtss", badumtss)

function glanguage(source)
	if not source:hasRights("Member") then return end
	outputChatBox( "#FF0000:ADMIN:#FFFFFF You may only speak English in main ('T') and global ('G') chat, otherwise you will be punished (mute/kick/ban)", getRootElement(), 255, 0, 0, true )
end
addCommandHandler("glang", glanguage)

function language(source)
	if not source:hasRights("Member") then return end
	outputChatBoxToGamemode ( "#FF0000:ADMIN:#FFFFFF You may only speak English in main ('T') and global ('G') chat, otherwise you will be punished (mute/kick/ban)", getPlayerGameMode(source), 255, 0, 0, true )
end
addCommandHandler("lang", language)

function insult(source)
	if not source:hasRights("Member") then return end
	outputChatBoxToGamemode ( "#FF0000:ADMIN:#FFFFFF You may not insult otherwise you will be punished (mute/kick/ban)", getPlayerGameMode(source), 255, 0, 0, true )
end
addCommandHandler("ins", insult)

function spam(source)
	if not source:hasRights("Member") then return end
	outputChatBoxToGamemode ( "#FF0000:ADMIN:#FFFFFF You may not spam otherwise you will be punished (mute/kick/ban)", getPlayerGameMode(source), 255, 0, 0, true )
end
addCommandHandler("spam", spam)

function camp(source)
	if not source:hasRights("Member") then return end
	outputChatBoxToGamemode ( "#FF0000:ADMIN:#FFFFFF You may not camp otherwise you will be punished (blow/kick/ban)", getPlayerGameMode(source), 255, 0, 0, true )
end
addCommandHandler("camp", camp)

gMutes = {}

function mute(player, commandname, toplayer, Value )
	if not player:hasRights("Member") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player] [minutes]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				if isPlayerMuted(targetPlayer) then
					for i,v in ipairs(gMutes) do
						if v.serial == getPlayerSerial(targetPlayer) then 
							if v.timer and isTimer(v.timer) then killTimer(v.timer) end
							table.remove(gMutes, i)
						end
					end
					setPlayerMuted(targetPlayer, false)
					outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(targetPlayer).." has been unmuted by "..getPlayerName(player)..".", getPlayerGameMode(player), 255, 0, 0, true )
				else
					gMutes[#gMutes+1] = {}
					gMutes[#gMutes].serial = getPlayerSerial(targetPlayer)
					if tonumber(Value) == 0 then
						outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(targetPlayer).." has been muted by "..getPlayerName(player)..".", getPlayerGameMode(player), 255, 0, 0, true )
						setPlayerMuted(targetPlayer, true)
					else
						outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(targetPlayer).." has been muted by "..getPlayerName(player).." ("..Value.." minutes).", getPlayerGameMode(player), 255, 0, 0, true )
						gMutes[#gMutes].timer = setTimer(function(ser)
							for i,v in ipairs(gMutes) do
								if v.serial == ser then 
									if v.timer and isTimer(v.timer) then killTimer(v.timer) end
									for i2,v2 in pairs(getElementsByType("player")) do
										if getPlayerSerial(v2) == ser then
											outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(v2).." has been automaticly unmuted.", getPlayerGameMode(player), 255, 0, 0, true )
											setPlayerMuted(v2, false)
										end
									end
									table.remove(gMutes, i)
								end
							end				
						end, 1000*60*tonumber(Value), 1, getPlayerSerial(targetPlayer))
						setPlayerMuted(targetPlayer, true)
					end
				end
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player] [minutes]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("mutePlayer", mute)
addCommandHandler("pmute", mute)

function clientDeleteBan(ban)
	if getElementData(client, "Level") ~= "Leader" then return false end
	for i,v in ipairs(getBans ()) do
		if getBanUsername ( v ) == ban.username or getBanSerial( v ) == ban.serial or getBanIP ( v ) == ban.ip then
			triggerClientEvent ( client, "addNotification", getRootElement(), 3, 18, 88, 97, "Ban successfully deleted." )
			removeBan(v)
			triggerEvent ( "clientRequestBanList", getRootElement() )
			return
		end
	end
	triggerClientEvent ( client, "addNotification", getRootElement(), 1, 255,0,0, "Ban could not not be deleted." )
end
addEvent("clientDeleteBan", true)
addEventHandler("clientDeleteBan", getRootElement(), clientDeleteBan)

function clientRequestBanList()
	local localBans = {}
	for i,v in ipairs(getBans ()) do
		localBans[#localBans+1] = {}
		localBans[#localBans].ban = v
		if getBanNick ( v ) then localBans[#localBans].nick = removeColorCoding(getBanNick ( v )) else localBans[#localBans].nick = "Unnamed" end
		if getBanUsername ( v ) then localBans[#localBans].username = getBanUsername ( v ) else localBans[#localBans].username = "Guest" end
		if getBanSerial ( v ) then localBans[#localBans].serial = getBanSerial ( v ) else localBans[#localBans].serial = "No Serial" end
		if getBanIP ( v ) then localBans[#localBans].ip = getBanIP ( v ) else localBans[#localBans].ip = "No IP" end
		if getBanAdmin ( v ) then localBans[#localBans].admin = "By "..removeColorCoding(getBanAdmin ( v )) else localBans[#localBans].admin = "By Unknown" end
		if getUnbanTime ( v ) and tonumber(getRealTime(getUnbanTime ( v )).year) > 100 then  -- Look why this fucks up (Seconds cannot be negative))
			local unbanTime = getRealTime(getUnbanTime ( v ))
			localBans[#localBans].unban = unbanTime.hour..":"..unbanTime.minute.." - "..unbanTime.monthday.."."..tostring(tonumber(unbanTime.month)+1).."."..tostring(tonumber(unbanTime.year)+1900)
		else localBans[#localBans].unban = "Permaban" end
	end
	triggerClientEvent ( source, "clientReceiveBanList", getRootElement(), localBans )
end	
addEvent("clientRequestBanList", true)
addEventHandler("clientRequestBanList", getRootElement(), clientRequestBanList)

addCommandHandler ( "serialBan",
	function(player, commandname, Value)
		local targetPlayer
		if Value== nil then
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /serialBan [serial]", player, 255, 0, 0, true )
		else
			if addBan(nil, nil, tostring(Value), player, "SerialBan", 0) then
				triggerClientEvent ( player, "addNotification", getRootElement(), 3, 18, 88, 97, "Ban successfully added." )
			else
				triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "Ban could not be added.")
			end
		end
	end
)

--TODO:
--[[addCommandHandler ( "banIP",
	function(player, commandname, Value)
		local targetPlayer
		if Value== nil then
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /banIP [IP]", player, 255, 0, 0, true )
		else
			if addBan(tostring(Value), nil, nil, player, "IPBan", 0) then
				triggerClientEvent ( player, "addNotification", getRootElement(), 3, 18, 88, 97, "Ban successfully added." )
			else
				triggerClientEvent ( player, "addNotification", getRootElement(), 1, 200, 50, 50, "Ban could not be added.")
			end
		end
	end
)]]

function ban(player, commandname, toplayer, Value)
	if not player:hasRights("SeniorMember") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.."  [player] [minutes]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				if tonumber(Value) == 0 then
					outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(targetPlayer).." has been banned by "..getPlayerName(player)..".", getPlayerGameMode(player), 255, 0, 0, true )
					banPlayer(targetPlayer, true, true, true, player, "Permaban", 0)
				else
					outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(targetPlayer).." has been timebanned by "..getPlayerName(player).." ("..Value.." minutes).", getPlayerGameMode(player), 255, 0, 0, true )
					banPlayer(targetPlayer, true, true, true, player, nil, tonumber(Value)*60)
				end
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player] [minutes]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("banPlayer", ban)
addCommandHandler("pban", ban)

function kill(player, commandname, toplayer)
	if not player:hasRights("Member") then return end

	local targetPlayer
	if toplayer == nil then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil then
			targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				if getElementData(targetPlayer, "state") ~= "alive" then
					outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player is not alive which makes him unkillable.", player, 255, 0, 0, true )
				else
					if getElementData(targetPlayer, "gameMode") == gGamemodeMO then
						return false
					elseif getElementData(targetPlayer, "gameMode") == gGamemodeFUN then 
						killPed(targetPlayer)
					else
						callServerFunction(gRaceModes[getPlayerGameMode(targetPlayer)].killfunc, targetPlayer)
					end
					outputChatBox ( "#125861:ADMIN: #FFFFFFYou have killed "..tostring(getPlayerName(targetPlayer)).."." , player, 139,69,19, true )
					outputChatBox ( "#125861:ADMIN: #FFFFFFYou have been killed by "..tostring(getPlayerName(player)).."." , targetPlayer, 139,69,19, true )
				end
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("blowPlayer", kill)
addCommandHandler("pblow", kill)
addCommandHandler("pkill", kill)
--addCommandHandler ( "killPlayer" )

function kick(player, commandname, toplayer )
	if not player:hasRights("Member") then return end

	local targetPlayer
	if toplayer == nil then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil then
			targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBoxToGamemode ( "#125861:ADMIN:#FFFFFF "..getPlayerName(targetPlayer).." has been kicked by "..getPlayerName(player)..".", getPlayerGameMode(player), 255, 0, 0, true )
				kickPlayer ( targetPlayer, player)	
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /"..commandname.." [player]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("kickPlayer", kick)
addCommandHandler("pkick", kick)

function setpoints(player, commandname, toplayer, Value )
	if not player:hasRights("Leader") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setpoints [player] [Value]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBox ( "#125861:ADMIN: #FFFFFF You set the points of "..tostring(getPlayerName(targetPlayer)).." to "..tostring(Value).."!" , player, 139,69,19, true )
				setElementData(targetPlayer, "Points", tonumber(Value))
				outputChatBox ( "#125861:ADMIN: #FFFFFF Your points were set to "..tostring(Value).." by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setpoints [player] [Value]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("setpoints", setpoints)

function setlevel(player, commandname, toplayer, Value )
	if not player:hasRights("Leader") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setlevel [player] [Value]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBox ( "#125861:ADMIN: #FFFFFF You set the level of "..tostring(getPlayerName(targetPlayer)).." to "..tostring(Value).."!" , player, 139,69,19, true )
				setElementData(targetPlayer, "Rank", tonumber(Value))
				outputChatBox ( "#125861:ADMIN: #FFFFFF Your level was set to "..tostring(Value).." by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setlevel [player] [Value]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("setlevel", setlevel)

function setachievementfunc(player, commandname, toplayer, Value )
	if not player:hasRights("Leader") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /addachievement [player] [Number]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil  then
		targetPlayer = getPlayerFromName2(toplayer)
			if tonumber(Value) == false or tonumber(Value) == nil then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe value must be the achievement number.", player, 255, 0, 0, true )
			end
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBox ( "#125861:ADMIN: #FFFFFF You gave "..tostring(getPlayerName(targetPlayer)).." achievement number "..tostring(Value).."" , player, 139,69,19, true )
				addPlayerArchivement(targetPlayer, tonumber(Value))
				outputChatBox ( "#125861:ADMIN: #FFFFFF You got achievement number "..tostring(Value).." by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /addachievement [player] [Number]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("addachievement", setachievementfunc)

function setrights(player, commandname, toplayer, Value)
	if not player:hasRights("Leader") then return end
	if not toplayer or not ADMIN_GROUPS[Value] then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setrights [player] [User/Recruit/Member/SeniorMember/Moderator/CoLeader/Leader]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil  then
			local targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBox ( "#125861:ADMIN: #FFFFFF You set the rights of "..tostring(getPlayerName(targetPlayer)).." to "..tostring(Value).."" , player, 139,69,19, true )
				outputChatBox ( "#125861:ADMIN: #FFFFFF Your rights were set to "..tostring(Value).." by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )

				targetPlayer.m_Level = tostring(Value)
				targetPlayer:setData("Level", tostring(Value))
				targetPlayer:getData("accElement"):setData("Level", tostring(Value))
				targetPlayer:updateTeam()
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setrights [player] [User/Recruit/Member/SeniorMember/Moderator/CoLeader/Leader]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("setrights", setrights)

function setdonator(player, commandname, toplayer, Value, Date)
	if not player:hasRights("Leader") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setdonator [player] [0/1] [date]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				if tonumber(Value) == 1 and Date ~= nil then
					outputChatBox ( "#125861:ADMIN: #FFFFFF You set the donator status of "..tostring(getPlayerName(targetPlayer)).." to true! It expires on "..Date.."." , player, 139,69,19, true )
					setElementData(targetPlayer, "isDonator", true)
					setElementData(targetPlayer, "donatordate", Date)
					outputChatBox ( "#125861:ADMIN: #FFFFFF Your donator status was set to true by "..tostring(getPlayerName(player)).."! It expires on "..Date.."." , targetPlayer, 139,69,19, true )
				else
					outputChatBox ( "#125861:ADMIN: #FFFFFF You set the donator status of "..tostring(getPlayerName(targetPlayer)).." to false!" , player, 139,69,19, true )
					setElementData(targetPlayer, "isDonator", false)
					outputChatBox ( "#125861:ADMIN: #FFFFFF Your donator status was set to false by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )
				end
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setdonator [player] [0/1]", player, 255, 0, 0, true )
		end
	end
end
--addCommandHandler("setdonator", setdonator)

function setmemeacc(player, commandname, toplayer, Value )
	if not player:hasRights("Leader") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setmemeacc [player] [Value]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBox ( "#125861:ADMIN: #FFFFFF You set the meme status of "..tostring(getPlayerName(targetPlayer)).." to "..tostring(Value).."!" , player, 139,69,19, true )
				setElementData(targetPlayer, "memeActivated", tonumber(Value))
				outputChatBox ( "#125861:ADMIN: #FFFFFF Your meme status was set to "..tostring(Value).." by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setmemeacc [player] [Value]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("setmemeacc", setmemeacc)

function setmoney(player, commandname, toplayer, Value)
	if not player:hasRights("Leader") then return end

	local targetPlayer
	if toplayer == nil or Value	== nil or tonumber(Value) < 0 then
		outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setmoney [player] [Value]", player, 255, 0, 0, true )
	else if getPlayerFromName(toplayer) ~= false or getPlayerFromName(toplayer) ~= nil or Value >= 0  then
		targetPlayer = getPlayerFromName2(toplayer)
			if targetPlayer == false or type(targetPlayer) == "table" then
				outputChatBox ( "#FF0000:ERROR: #FFFFFFThe player doesn't exist or there are more then 1 possible player choice.", player, 255, 0, 0, true )
			else
				outputChatBox ( "#125861:ADMIN: #FFFFFF You set the money of "..tostring(getPlayerName(targetPlayer)).." to "..tostring(Value).." Vero!" , player, 139,69,19, true )
				setElementData(targetPlayer, "Money", tonumber(Value))
				outputChatBox ( "#125861:ADMIN: #FFFFFF Your money was set to "..tostring(Value).." Vero by "..tostring(getPlayerName(player)).."!" , targetPlayer, 139,69,19, true )
			end
		else
			outputChatBox ( "#FF0000:ERROR: #FFFFFFUsage: /setmoney [player] [Value]", player, 255, 0, 0, true )
		end
	end
end
addCommandHandler("setmoney", setmoney)

addCommandHandler("drun",
	function(player, cmd, ...)
		if not player:hasRights("Owner") then return end
		local codeString = table.concat({...}, " ")
		runString(codeString, player)
	end
)

addCommandHandler("dcrun",
	function(player, cmd, ...)
		if not player:hasRights("Owner") then return end
		local codeString = table.concat({...}, " ")
		player:triggerEvent("runString", codeString)
	end
)
--[[
Project: VitaRace
File: radar-client.lua
Author(s):	Aibo
			Sebihunter
]]--

local posx = screenHeight * 0.05
local posy = screenHeight * 0.725
local height = screenHeight * 0.225
if height > 256 then height = 256 end
local centerleft = posx + height / 2
local centertop = posy + height / 2
local blipsize = height / 16
local blipsizesmall = height / 32
local lpsize = height / 16
local range = 180

local lp = getLocalPlayer()

function getDistanceRotation(x, y, dist, angle)
  local a = math.rad(90 - angle)
  local dx = math.cos(a) * dist
  local dy = math.sin(a) * dist
  return x+dx, y+dy
end

function findRotation(x1,y1,x2,y2)
  local t = -math.deg(math.atan2(x2-x1,y2-y1))
  if t < 0 then t = t + 360 end
  return t
end

local rotorr = 0

addEventHandler("onClientRender", getRootElement(), 
function()
	if getPlayerGameMode(getLocalPlayer()) == 0 or getPlayerGameMode(getLocalPlayer()) == 6 or minigamesVoteShown == true then setPlayerHudComponentVisible("radar", false) return end
	if useVitaRadar == false then
		if showUserGui == false then
			setPlayerHudComponentVisible("radar", true)
		else
			setPlayerHudComponentVisible("radar", false)
		end
		return
	end
	if showUserGui ~= false then return end
	local target = getCameraTarget()
	if target and getElementType(target) == "vehicle" then
		lp = getVehicleOccupant(target)
	else
		lp = getLocalPlayer()
	end

	setPlayerHudComponentVisible("radar", false)
	if rotorr ~= 360 then rotorr = rotorr+5 else rotorr = 1 end	

	if not lp then return end
	local px, py, pz = getElementPosition(lp)
    local pr = getPedRotation(lp)
    local cx,cy,_,tx,ty = getCameraMatrix()
    local north = findRotation(cx,cy,tx,ty)
	
	dxDrawImage(posx,posy,height,height, "files/radar/radius.png")
	dxDrawImage(posx,posy,height,height, "files/radar/radarnorth.png", north)
	
	for id, player in ipairs(getElementsByType("player")) do
		local veh = getPedOccupiedVehicle(player)
		if veh and player ~= lp then
			if isPlayerAlive(player) and veh and player ~= lp and getPlayerGameMode(player) == getPlayerGameMode(getLocalPlayer()) then
				local _,_,rot = getElementRotation(veh)
				local ex, ey, ez = getElementPosition(veh)
				local dist = getDistanceBetweenPoints2D(px,py,ex,ey)
				if dist > range then
					dist = tonumber(range)
				end
				local angle = 180-north + findRotation(px,py,ex,ey)
				local cblipx, cblipy = getDistanceRotation(0, 0, height*(dist/range)/2, angle)
				local blipx = centerleft+cblipx-blipsize/2
				local blipy = centertop+cblipy-blipsize/2
				local yoff = 0
				local r,g,b,a = 255,255,255,255
				if getPlayerTeam(player) then
					r,g,b = getTeamColor( getPlayerTeam(player) )
				end
				
				if tonumber(getElementModel(veh)) == 425 then
					if (ez - pz) >= 5 then
						dxDrawImage(blipx+15, blipy, blipsize/2, blipsize/2, "files/radar/up.png", 0, 0, 0, tocolor(r,g,b,a))
					elseif (ez - pz) <= -5 then
						dxDrawImage(blipx+15, blipy, blipsize/2, blipsize/2, "files/radar/down.png", 0, 0, 0, tocolor(r,g,b,a))
					end
					dxDrawImage(blipx, blipy, blipsize, blipsize, "files/radar/rotor.png", rotorr, 0, 0, tocolor(r,g,b,a))
					dxDrawImage(blipx, blipy, blipsize, blipsize, "files/radar/hunter.png", north-rot+45, 0, 0, tocolor(r,g,b,a))
					dxDrawImage(blipx, blipy, blipsize, blipsize, "files/radar/rotor.png", rotorr, 0, 0, tocolor(r,g,b,a))
				else
					dxDrawImage(blipx, blipy, blipsize, blipsize, "files/radar/vehicle.png", north-rot+45, 0, 0, tocolor(r,g,b,a))
				end
			end
		elseif player ~= lp and isPlayerAlive(player) and getPlayerGameMode(player) == getPlayerGameMode(getLocalPlayer()) and getPlayerGameMode(getLocalPlayer()) == 4 then
			local ex, ey, ez = getElementPosition(player)
			local dist = getDistanceBetweenPoints2D(px,py,ex,ey)
			if dist > range then
				dist = tonumber(range)
			end
			local angle = 180-north + findRotation(px,py,ex,ey)
			local cblipx, cblipy = getDistanceRotation(0, 0, height*(dist/range)/2, angle)
			local blipx = centerleft+cblipx-blipsize/2
			local blipy = centertop+cblipy-blipsize/2
			local r,g,b,a = 255,255,255,255
			if getPlayerTeam(player) then
				r,g,b = getTeamColor( getPlayerTeam(player) )
			end		
			if (ez - pz) >= 5 then
				dxDrawImage(blipx, blipy, blipsizesmall, blipsizesmall, "files/radar/up.png", 0, 0, 0, tocolor(r,g,b,a))
			elseif (ez - pz) <= -5 then
				dxDrawImage(blipx, blipy, blipsizesmall, blipsizesmall, "files/radar/down.png", 0, 0, 0, tocolor(r,g,b,a))
			else
				dxDrawImage(blipx, blipy, blipsizesmall, blipsizesmall, "files/radar/checkpoint.png", 0, 0, 0, tocolor(r,g,b,a))	
			end
		end
	end
	
	for id, blip in ipairs(getElementsByType("blip")) do
		if getElementData(blip, "doDraw") == true then
			local ex,ey,ez = getElementPosition(blip)
			local dist = getDistanceBetweenPoints2D(px,py,ex,ey)
			if dist > range then
				dist = tonumber(range)
			end
			
			local angle = 180-north + findRotation(px,py,ex,ey)
			local cblipx, cblipy = getDistanceRotation(0, 0, height*(dist/range)/2, angle)
			local blipx = centerleft+cblipx-blipsize/2
			local blipy = centertop+cblipy-blipsize/2
			local yoff = 0
			local r,g,b,a = 255,255,255,255
			r,g,b,a = getBlipColor(blip)
				
			dxDrawImage(blipx, blipy, blipsize, blipsize, "files/radar/checkpoint.png", 0, 0, 0, tocolor(r,g,b,a))		
		end
	end
	
	for id, marker in ipairs(getElementsByType("marker")) do
		if getElementData(marker, "spawnID") and getElementData(getLocalPlayer(), "nextMarker") ~= 0 and (getElementData(marker, "spawnID") == getElementData(getLocalPlayer(), "nextMarker") or getElementData(marker, "spawnID") == getElementData(getLocalPlayer(), "nextMarker")+1) then
			local ex,ey,ez = getElementPosition(marker)
			local dist = getDistanceBetweenPoints2D(px,py,ex,ey)
			if dist > range then
				dist = tonumber(range)
			end
			
			if getElementData(marker, "spawnID") == getElementData(getLocalPlayer(), "nextMarker") then
				local angle = 180-north + findRotation(px,py,ex,ey)
				local cblipx, cblipy = getDistanceRotation(0, 0, height*(dist/range)/2, angle)
				local blipx = centerleft+cblipx-blipsize/2
				local blipy = centertop+cblipy-blipsize/2
				local yoff = 0
				local r,g,b,a = 255,255,255,255
				r,g,b,a = getMarkerColor(marker)
				
				dxDrawImage(blipx, blipy, blipsize, blipsize, "files/radar/checkpoint.png", 0, 0, 0, tocolor(r,g,b,a))
			else
				local angle = 180-north + findRotation(px,py,ex,ey)
				local cblipx, cblipy = getDistanceRotation(0, 0, height*(dist/range)/2, angle)
				local blipx = centerleft+cblipx-blipsizesmall/2
				local blipy = centertop+cblipy-blipsizesmall/2
				local yoff = 0
				local r,g,b,a = 255,255,255,255
				r,g,b,a = getMarkerColor(marker)
				
				dxDrawImage(blipx, blipy, blipsizesmall, blipsizesmall, "files/radar/checkpoint.png", 0, 0, 0, tocolor(r,g,b,a))			
			end
		end
	end	
	
	dxDrawImage(centerleft - lpsize/2, centertop - lpsize/2, lpsize,lpsize, "files/radar/player.png",north-pr )
end
)
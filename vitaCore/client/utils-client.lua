--[[
Project: vitaCore
File: utils-client.lua
Author(s):	Sebihunter
]]--

---------------------------------------------------------------------------
-- Vector3D
---------------------------------------------------------------------------

Vector3D = {
	new = function(self, _x, _y, _z)
		local newVector = { x = _x or 0.0, y = _y or 0.0, z = _z or 0.0 }
		return setmetatable(newVector, { __index = Vector3D })
	end,

	Copy = function(self)
		return Vector3D:new(self.x, self.y, self.z)
	end,

	Normalize = function(self)
		local mod = self:Length()
		self.x = self.x / mod
		self.y = self.y / mod
		self.z = self.z / mod
	end,

	Dot = function(self, V)
		return self.x * V.x + self.y * V.y + self.z * V.z
	end,

	Length = function(self)
		return math.sqrt(self.x * self.x + self.y * self.y + self.z * self.z)
	end,

	AddV = function(self, V)
		return Vector3D:new(self.x + V.x, self.y + V.y, self.z + V.z)
	end,

	SubV = function(self, V)
		return Vector3D:new(self.x - V.x, self.y - V.y, self.z - V.z)
	end,

	CrossV = function(self, V)
		return Vector3D:new(self.y * V.z - self.z * V.y,
							self.z * V.x - self.x * V.z,
							self.x * V.y - self.y * V.z)
	end,

	Mul = function(self, n)
		return Vector3D:new(self.x * n, self.y * n, self.z * n)
	end,

	Div = function(self, n)
		return Vector3D:new(self.x / n, self.y / n, self.z / n)
	end,
}
---------------------------------------------------------------------------

------------------------
-- Make vehicle upright
------------------------

function directionToRotation2D( x, y )
	return rem( math.atan2( y, x ) * (360/6.28) - 90, 360 )
end

-- Modulo with more useful sign handling
function rem( a, b )
	local result = a - b * math.floor( a / b )
	if result >= b then
		result = result - b
	end
	return result
end


function alignVehicleWithUp(vehicle)
	if not vehicle then return end

	local matrix = getElementMatrix( vehicle )
	local Right = Vector3D:new( matrix[1][1], matrix[1][2], matrix[1][3] )
	local Fwd	= Vector3D:new( matrix[2][1], matrix[2][2], matrix[2][3] )
	local Up	= Vector3D:new( matrix[3][1], matrix[3][2], matrix[3][3] )

	local Velocity = Vector3D:new( getElementVelocity( vehicle ) )
	local rz

	if Velocity:Length() > 0.05 and Up.z < 0.001 then
		-- If velocity is valid, and we are upside down, use it to determine rotation
		rz = directionToRotation2D( Velocity.x, Velocity.y )
	else
		-- Otherwise use facing direction to determine rotation
		rz = directionToRotation2D( Fwd.x, Fwd.y )
	end

	setElementRotation( vehicle, 0, 0, rz )
end

-- curve is { {x1, y1}, {x2, y2}, {x3, y3} ... }
function math.evalCurve( curve, input )
	-- First value
	if input<curve[1][1] then
		return curve[1][2]
	end
	-- Interp value
	for idx=2,#curve do
		if input<curve[idx][1] then
			local x1 = curve[idx-1][1]
			local y1 = curve[idx-1][2]
			local x2 = curve[idx][1]
			local y2 = curve[idx][2]
			-- Find pos between input points
			local alpha = (input - x1)/(x2 - x1);
			-- Map to output points
			return math.lerp(y1,y2,alpha)
		end
	end
	-- Last value
	return curve[#curve][2]
end

function math.lerp(from,to,alpha)
    return from + (to-from) * alpha
end

-- Custom fancy effect for final countdown image
function zoomFades(elems, val, info)
	if type( val ) == 'table' then
		return
	end

	local valinv = 1 - val
	local width = info.width
	local height = info.height

	local val = 1-((1-val) * (1-val))
	local slope = val * 0.95
	local alphas = { valinv, (valinv-0.35) * 0.20, (valinv-0.5) * 0.125 }

	if #elems > 1 then
		alphas[1] = valinv*valinv-valinv*0.5
	end

	for i,elem in ipairs(elems) do
		if isElement(elem) then
			local scalex = 1 + slope * (i-1)
			local scaley = 1 + slope * (i-1)
			local sx = width * scalex
			local sy = height * scaley
			local screenWidth, screenHeight = guiGetScreenSize()
			sx = math.min( screenWidth, sx )
			sy = math.min( screenHeight, sy )
			local px = math.floor(screenWidth/2 - sx/2)
			local py = math.floor(screenHeight/2 - sy/2)
			guiSetPosition( elem, px, py, false )
			guiSetSize( elem, sx, sy, false )
			guiSetAlpha( elem, alphas[i] )
		end
	end
end

function resAdjust(num)
	if not screenWidth then
		screenWidth, screenHeight = guiGetScreenSize()
	end
	if screenWidth < 1280 then
		return math.floor(num*screenWidth/1280)
	else
		return num
	end
end

function checkVehicleIsHelicopter(veh)
	local vehID = veh.model
	if vehID == 417 or vehID == 425 or vehID == 447 or vehID == 465 or vehID == 469 or vehID == 487 or vehID == 488 or vehID == 497 or vehID == 501 or vehID == 548 or vehID == 563 then
		veh:setVehicleRotorSpeed(0.2)
	end
end

function callClientFunction(funcname, ...)
    local arg = { ... }
    if (arg[1]) then
        for key, value in next, arg do arg[key] = tonumber(value) or value end
    end
    --loadstring("return "..funcname)()(unpack(arg))
    exec = loadstring("return "..funcname)()
	if type(exec) ~= "function" then outputDebugString("Failed to call function: " .. tostring(funcname)) return end
	exec(unpack(arg))
end
addEvent("onServerCallsClientFunction", true)
addEventHandler("onServerCallsClientFunction", resourceRoot, callClientFunction)

function executeServerCommandHandler(commandHandler, args)
	triggerServerEvent ( "executeServerCommandHandler", getLocalPlayer(), commandHandler, args )
end

function showGUIComponents(...)
	for i,name in ipairs({...}) do
		if g_dxGUI[name] then
			g_dxGUI[name]:visible(true)
		elseif type(g_GUI[name]) == 'table' then
			g_GUI[name]:show()
		else
			guiSetVisible(g_GUI[name], true)
		end
	end
end

function hideGUIComponents(...)
	for i,name in ipairs({...}) do
		if g_dxGUI[name] then
			g_dxGUI[name]:visible(false)
		elseif type(g_GUI[name]) == 'table' then
			g_GUI[name]:hide()
		else
			guiSetVisible(g_GUI[name], false)
		end
	end
end

function setGUIComponentsVisible(settings)
	for name,visible in pairs(settings) do
		if type(g_GUI[name]) == 'table' then
			g_GUI[name][visible and 'show' or 'hide'](g_GUI[name])
		else
			guiSetVisible(g_GUI[name], visible)
		end
	end
end

function getPlayerMoney()
	return getElementData(getLocalPlayer(), "Money")
end

function setPlayerMoney( value )
	setElementData(getLocalPlayer(), "Money", value)
end

gAttachedSounds = {}

function playSoundAttachedToElement(element, soundFile)
	gAttachedSounds[element] = {}
	local x, y, z = getElementPosition(element)
	local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(localPlayer))
	distance = distance * 2
	if getDistanceBetweenPoints3D(x, y, z, getElementPosition(localPlayer)) <= 200 and getElementDimension(element) == getElementDimension(localPlayer) then
		gAttachedSounds[element].sound = playSound(soundFile)
		if (1 - distance / 200) < 0 then
			setSoundVolume(gAttachedSounds[element].sound, 0)
		else
			setSoundVolume(gAttachedSounds[element].sound, 1 - distance / 200)
		end
	end
	setTimer(function(element)
		stopSound(gAttachedSounds[element].sound)
		gAttachedSounds[element].sound = {}
		gAttachedSounds[element] = {}
	end, math.floor(getSoundLength ( gAttachedSounds[element].sound )*1000), 1, element)
end

setTimer(function ()
	for k, v in pairs(gAttachedSounds) do
		if v.sound then
			if isElement(k) then
				local x, y, z = getElementPosition(k)
				local distance = getDistanceBetweenPoints3D(x, y, z, getElementPosition(localPlayer))
				distance = distance * 2
				if (1 - distance / 200) < 0 then
					setSoundVolume(v.sound, 0)
				else
					setSoundVolume(v.sound, 1 - distance / 200)
				end
			else
				gAttachedSounds[k] = nil
			end
		end
	end
end, 100, 0)

function getElementBehindCursor(worldX, worldY, worldZ)
	local x, y, z = getCameraMatrix()
	local hit, hitX, hitY, hitZ, element = processLineOfSight(x, y, z, worldX, worldY, worldZ, false, true, true, true, false)

	return element
end

function isHover(startX, startY, width, height)
	if isCursorShowing() then
		local pos = {getCursorPosition()}
		return (screenWidth*pos[1] >= startX) and (screenWidth*pos[1] <= startX + width) and (screenHeight*pos[2] >= startY) and (screenHeight*pos[2] <= startY + height)
	end
	return false
end
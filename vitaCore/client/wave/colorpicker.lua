--[[
Project: vitaCore - vitaWave
File: colorpicker.lua
Author(s):	Aibo
			Sebihunter
]]--

sw, sh = guiGetScreenSize()

colorPickersTable = {}

colorPicker = {}
colorPicker.__index = colorPicker

function openPicker(id, start, title)
  if id and not colorPickersTable[id] then
    colorPickersTable[id] = colorPicker.create(id, start, title)
    colorPickersTable[id]:updateColor()
    return true
  end
  return false
end

function closePicker(id)
  if id and colorPickersTable[id] then
    colorPickersTable[id]:destroy()
    return true
  end
  return false
end


function colorPicker.create(id, start, title)
  local cp = {}
  setmetatable(cp, colorPicker)
  cp.id = id
  cp.color = {}
  cp.color.h, cp.color.s, cp.color.v, cp.color.r, cp.color.g, cp.color.b, cp.color.hex = 0, 1, 1, 255, 0, 0, "#FF0000"
  cp.color.white = tocolor(255,255,255,255)
  cp.color.black = tocolor(0,0,0,255)
  cp.color.current = tocolor(255,0,0,255)
  cp.color.huecurrent = tocolor(255,0,0,255)
  if start and getColorFromString(start) then
    cp.color.h, cp.color.s, cp.color.v = rgb2hsv(getColorFromString(start))
  end
  cp.gui = {}
  cp.gui.width = 416
  cp.gui.height = 304
  cp.gui.snaptreshold = 0.02
  cp.gui.window = guiCreateWindow(screenWidth/2-405,screenHeight/2-245, 325, 304, tostring(title or "COLORPICKER"), false)
  cp.gui.svmap = guiCreateStaticImage(16, 32, 256, 256, "files/wave/cpicker/blank.png", false, cp.gui.window)
  cp.gui.hbar = guiCreateStaticImage(288, 32, 32, 256, "files/wave/cpicker/blank.png", false, cp.gui.window)
  cp.gui.blank = guiCreateStaticImage(336, 32, 64, 64, "files/wave/cpicker/blank.png", false, cp.gui.window)
  guiWindowSetSizable(cp.gui.window, false)	
  
  guiSetProperty ( cp.gui.svmap, "InheritsAlpha", "false")
  guiSetProperty ( cp.gui.hbar, "InheritsAlpha", "false")
  guiSetProperty ( cp.gui.blank, "InheritsAlpha", "false")
  guiSetAlpha(cp.gui.window, 0)
  guiSetProperty ( cp.gui.window, "Alpha", "0" )
  guiWindowSetSizable(cp.gui.window, false)
  guiWindowSetMovable(cp.gui.window, false)

  cp.handlers = {}
  cp.handlers.mouseDown = function() cp:mouseDown() end
  cp.handlers.mouseSnap = function() cp:mouseSnap() end
  cp.handlers.mouseUp = function(b,s) cp:mouseUp(b,s) end
  cp.handlers.mouseMove = function(x,y) cp:mouseMove(x,y) end
  cp.handlers.pickColor = function() cp:pickColor() end
  cp.handlers.destroy = function() cp:destroy() end
  
  addEventHandler("onClientGUIMouseDown", cp.gui.svmap, cp.handlers.mouseDown, false)
  addEventHandler("onClientMouseLeave", cp.gui.svmap, cp.handlers.mouseSnap, false)
  addEventHandler("onClientMouseMove", cp.gui.svmap, cp.handlers.mouseMove, false)
  addEventHandler("onClientGUIMouseDown", cp.gui.hbar, cp.handlers.mouseDown, false)
  addEventHandler("onClientMouseMove", cp.gui.hbar, cp.handlers.mouseMove, false)
  addEventHandler("onClientClick", root, cp.handlers.mouseUp)
  addEventHandler("onClientGUIMouseUp", root, cp.handlers.mouseUp)
  return cp
end

function colorPicker:render()
  -- if not self.gui.focus then return end
  local x,y = guiGetPosition(self.gui.window, false)
  dxDrawRectangle(x+16, y+32, 256, 256,  tocolor(hsva2rgba(self.color.h, 1, 1, 255*waveAlpha*waveMenuAlpha)), self.gui.focus)
  dxDrawImage(x+16, y+32, 256, 256, "files/wave/cpicker/sv.png", 0, 0, 0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha), self.gui.focus)
  dxDrawImage(x+288, y+32, 32, 256, "files/wave/cpicker/h.png", 0, 0, 0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha), self.gui.focus)
  dxDrawImageSection(x+8+math.floor(256*self.color.s), y+24+(256-math.floor(256*self.color.v)), 16, 16, 0, 0, 16, 16, "files/wave/cpicker/cursor.png", 0, 0, 0, tocolor(255,255,255,255*waveAlpha*waveMenuAlpha), self.gui.focus)
  dxDrawImageSection(x+280, y+24+(256-math.floor(256*self.color.h)), 48, 16, 16, 0, 48, 16, "files/wave/cpicker/cursor.png", 0, 0, 0, tocolor(hsva2rgba(self.color.h, 1, 1, 255*waveAlpha*waveMenuAlpha)), self.gui.focus)
end

function colorPicker:mouseDown()
  if source == self.gui.svmap or source == self.gui.hbar then
    self.gui.track = source
    local cx, cy = getCursorPosition()
    self:mouseMove(sw*cx, sh*cy)
  end  
end

function colorPicker:mouseUp(button, state)
  if not state or state ~= "down" then
    if self.gui.track then 
      triggerEvent("onColorPickerChange", root, self.id, self.color.hex, self.color.r, self.color.g, self.color.b) 
    end
    self.gui.track = false 
  end  
end

function colorPicker:mouseMove(x,y)
  if self.gui.track and source == self.gui.track then
    local gx,gy = guiGetPosition(self.gui.window, false)
    if source == self.gui.svmap then
      local offsetx, offsety = x - (gx + 16), y - (gy + 32)
      self.color.s = offsetx/255
      self.color.v = (255-offsety)/255
    elseif source == self.gui.hbar then
      local offset = y - (gy + 32)
      self.color.h = (255-offset)/255
    end 
    self:updateColor()
  end
end

function colorPicker:mouseSnap()
  if self.gui.track and source == self.gui.track then
    if self.color.s < self.gui.snaptreshold or self.color.s > 1-self.gui.snaptreshold then self.color.s = math.round(self.color.s) end
    if self.color.v < self.gui.snaptreshold or self.color.v > 1-self.gui.snaptreshold then self.color.v = math.round(self.color.v) end
    self:updateColor()
  end
end

function colorPicker:updateColor()
  self.color.r, self.color.g, self.color.b = hsv2rgb(self.color.h, self.color.s, self.color.v)
  self.color.current = tocolor(self.color.r, self.color.g, self.color.b,255)
  self.color.huecurrent = tocolor(hsv2rgb(self.color.h, 1, 1))
  self.color.hex = string.format("#%02X%02X%02X", self.color.r, self.color.g, self.color.b)
  guiSetText(g_customization1g["hex_color"], tostring(self.color.hex))
end

function updateViaHex(id)
	if colorPickersTable and colorPickersTable[id] then
		local hextext = guiGetText(g_customization1g["hex_color"])
		if getColorFromString(hextext) then
			local r, g, b, a = getColorFromString(hextext)
			colorPickersTable[id].color.hex = hextext
			colorPickersTable[id].color.current = tocolor(r, g, b, 255)
			colorPickersTable[id].color.r, colorPickersTable[id].color.g, colorPickersTable[id].color.b = r, g, b
			colorPickersTable[id].color.h, colorPickersTable[id].color.s, colorPickersTable[id].color.v = rgb2hsv(getColorFromString(hextext))
			return true
		end
	end
	return false
end


function colorPicker:pickColor()
  triggerEvent("onColorPickerOK", root, self.id, self.color.hex, self.color.r, self.color.g, self.color.b)
  self:destroy()
end

function colorPicker:getPickedColor()
	return self.color.r, self.color.g, self.color.b
end

function colorPicker:destroy()
  removeEventHandler("onClientGUIMouseDown", self.gui.svmap, self.handlers.mouseDown)
  removeEventHandler("onClientMouseLeave", self.gui.svmap, self.handlers.mouseSnap)
  removeEventHandler("onClientMouseMove", self.gui.svmap, self.handlers.mouseMove)
  removeEventHandler("onClientGUIMouseDown", self.gui.hbar, self.handlers.mouseDown)
  removeEventHandler("onClientMouseMove", self.gui.hbar, self.handlers.mouseMove)
  removeEventHandler("onClientClick", root, self.handlers.mouseUp)
  removeEventHandler("onClientGUIMouseUp", root, self.handlers.mouseUp)
  destroyElement(self.gui.window)
  colorPickersTable[self.id] = nil
  setmetatable(self, nil)
end

function areThereAnyPickers()
  for _ in pairs(colorPickersTable) do
    return true
  end
  return false
end

function hsv2rgb(h, s, v)
  local r, g, b
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  local switch = i % 6
  if switch == 0 then
    r = v g = t b = p
  elseif switch == 1 then
    r = q g = v b = p
  elseif switch == 2 then
    r = p g = v b = t
  elseif switch == 3 then
    r = p g = q b = v
  elseif switch == 4 then
    r = t g = p b = v
  elseif switch == 5 then
    r = v g = p b = q
  end
  return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

function hsva2rgba(h, s, v,a)
  local r, g, b
  local i = math.floor(h * 6)
  local f = h * 6 - i
  local p = v * (1 - s)
  local q = v * (1 - f * s)
  local t = v * (1 - (1 - f) * s)
  local switch = i % 6
  if switch == 0 then
    r = v g = t b = p
  elseif switch == 1 then
    r = q g = v b = p
  elseif switch == 2 then
    r = p g = v b = t
  elseif switch == 3 then
    r = p g = q b = v
  elseif switch == 4 then
    r = t g = p b = v
  elseif switch == 5 then
    r = v g = p b = q
  end
  return math.floor(r*255), math.floor(g*255), math.floor(b*255), a
end

function rgb2hsv(r, g, b)
  r, g, b = r/255, g/255, b/255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s 
  local v = max
  local d = max - min
  s = max == 0 and 0 or d/max
  if max == min then 
    h = 0
  elseif max == r then 
    h = (g - b) / d + (g < b and 6 or 0)
  elseif max == g then 
    h = (b - r) / d + 2
  elseif max == b then 
    h = (r - g) / d + 4
  end
  h = h/6
  return h, s, v
end

addEvent("onColorPickerOK", true)
addEvent("onColorPickerChange", true)
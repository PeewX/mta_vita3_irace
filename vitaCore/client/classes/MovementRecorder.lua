MovementRecorder = inherit(Object)

local POSITION_DELTA_THRESHOLD = 0.05
local ROTATION_DELTA_THRESHOLD = 0.5

local function encodePos(v)
	local i = math.floor((v + 10000) * 10 + 0.5)
	return math.floor(i / 65536) % 256, math.floor(i / 256) % 256, i % 256
end

local function encodeRot(v)
	local i = math.floor(v * 10 + 0.5) % 3600
	return math.floor(i / 256) % 256, i % 256
end

local function encodeTime(ms)
	return math.floor(ms / 65536) % 256, math.floor(ms / 256) % 256, ms % 256
end

local function encodeModel(id)
	return math.floor(id / 256) % 256, id % 256
end

function MovementRecorder:constructor(vehicleModel)
	self.m_VehicleDummy = createVehicle(vehicleModel, 1337, 1337, -1337)
    self.m_VehicleDummy:setDimension(localPlayer.dimension)
	self.m_VehicleDummy:setPlateText("iRace")
	self.m_VehicleDummy:setFrozen(true)
	self.m_VehicleDummy:setCollisionsEnabled(false)
	self.m_VehicleDummy:setAlpha(150)
	setVehicleOverrideLights(self.m_VehicleDummy, 2)

	self.m_DummyPed = createPed(0, 1337, 1337, -1337)
    self.m_DummyPed:setDimension(localPlayer.dimension)
	self.m_DummyPed:setCollisionsEnabled(false)
	self.m_DummyPed:setAlpha(150)
	self.m_DummyPed:warpIntoVehicle(self.m_VehicleDummy)

	self.m_Record = {}
	self.m_EncodedRecord = {}
	self.m_Recording = false
	self.m_RenderPlayback = false
	self.m_PlayRecordFrame = 1

	self.m_fnRenderRecord = bind(MovementRecorder.renderRecord, self)
	self.m_fnRenderPlayback = bind(MovementRecorder.renderPlayback, self)
end

function MovementRecorder:destructor()
	if isElement(self.m_VehicleDummy) then self.m_VehicleDummy:destroy() end
	if isElement(self.m_DummyPed) then self.m_DummyPed:destroy() end

	removeEventHandler("onClientRender", root, self.m_fnRenderRecord)
	removeEventHandler("onClientRender", root, self.m_fnRenderPlayback)
end

function MovementRecorder:startRecording()
	if self.m_Recording then return end
	if not localPlayer.vehicle then return end

	self.m_Record = {}
    self.m_EncodedRecord = {}
	self.m_Vehicle = localPlayer.vehicle
	self.m_RecordStartTick = getTickCount()
	self.m_Recording = true

	addEventHandler("onClientRender", root, self.m_fnRenderRecord)
end

function MovementRecorder:stopRecording()
	if not self.m_Recording then return end
	self.m_Recording = false
	removeEventHandler("onClientRender", root, self.m_fnRenderRecord)
end

function MovementRecorder:isRecording()
	return self.m_Recording
end

function MovementRecorder:getEncodedRecord()
	return table.concat(self.m_EncodedRecord)
end

function MovementRecorder:startPlayback()
	if not self.m_VehicleDummy then return end
    if #self.m_Record == 0 then return end
	if self.m_RenderPlayback then self:stopPlayback() end

	self.m_PlayRecordFrame = 1
	self.m_RenderPlayback = true
	self.m_PlaybackStartTick = getTickCount()
	self.m_PlaybackStartFrame = self.m_PlayRecordFrame or 1

	addEventHandler("onClientRender", root, self.m_fnRenderPlayback)
end

function MovementRecorder:stopPlayback()
	self.m_RenderPlayback = false
	removeEventHandler("onClientRender", root, self.m_fnRenderPlayback)
end

function MovementRecorder:isPlaybackRendered()
	return self.m_RenderPlayback
end

function MovementRecorder:renderRecord()
	if not localPlayer.vehicle then
		return self:stopRecording()
	end

	local model = self.m_Vehicle.model
	local position = self.m_Vehicle.position
	local rotation = self.m_Vehicle.rotation
	local elapsedTime = getTickCount() - self.m_RecordStartTick

	local last = self.m_Record[#self.m_Record]
	if last then
		local posDelta = (position - last.position):getLength()
		local rotDelta = (rotation - last.rotation):getLength()
		if posDelta < POSITION_DELTA_THRESHOLD and rotDelta < ROTATION_DELTA_THRESHOLD then	return end
	end

	table.insert(self.m_Record, {model = model, position = position, rotation = rotation, elapsedTime = elapsedTime})

	local px1, px2, px3 = encodePos(position.x)
	local py1, py2, py3 = encodePos(position.y)
	local pz1, pz2, pz3 = encodePos(position.z)
	local rx1, rx2	    = encodeRot(rotation.x)
	local ry1, ry2	    = encodeRot(rotation.y)
	local rz1, rz2      = encodeRot(rotation.z)
	local m1, m2        = encodeModel(model)
	local t1, t2, t3    = encodeTime(elapsedTime)

	table.insert(self.m_EncodedRecord, string.char(px1,px2,px3,	py1,py2,py3, pz1,pz2,pz3, rx1,rx2,	ry1,ry2, rz1,rz2, m1,m2, t1,t2,t3))
end

function MovementRecorder:renderPlayback()
	if not self.m_VehicleDummy then return end

	local elapsed = getTickCount() - self.m_PlaybackStartTick
	local recordTime = self.m_Record[self.m_PlaybackStartFrame].elapsedTime + elapsed
	local record = self.m_Record
	local count = #record

	while self.m_PlayRecordFrame < count and record[self.m_PlayRecordFrame + 1].elapsedTime <= recordTime do
		self.m_PlayRecordFrame = self.m_PlayRecordFrame + 1
	end

	local frameA = record[self.m_PlayRecordFrame]
	local frameB = record[self.m_PlayRecordFrame + 1]

	if frameB then
		local span = frameB.elapsedTime - frameA.elapsedTime
		local alpha = span > 0 and (recordTime - frameA.elapsedTime) / span or 0
		self:updateFrame(frameA, frameB, alpha)
	else
		self:updateFrame(frameA, frameA, 0)
		self:stopPlayback()
	end
end

local function lerpAngle(a, b, t)
    local diff = (b - a) % 360
    if diff > 180 then diff = diff - 360 end
    return a + diff * t
end

function MovementRecorder:updateFrame(frameA, frameB, alpha)
	local px, py, pz = interpolateBetween(frameA.position.x, frameA.position.y, frameA.position.z, frameB.position.x, frameB.position.y, frameB.position.z, alpha, "Linear")
    local rx, ry, rz = lerpAngle(frameA.rotation.x, frameB.rotation.x, alpha), lerpAngle(frameA.rotation.y, frameB.rotation.y, alpha), lerpAngle(frameA.rotation.z, frameB.rotation.z, alpha) 

	self.m_VehicleDummy:setPosition(px, py, pz)
	self.m_VehicleDummy:setRotation(rx, ry, rz)

    if frameA.model ~= self.m_VehicleDummy.model then
        self.m_VehicleDummy:setModel(frameA.model)
    end
end

function MovementRecorder:decodeRecord(encodedString)
	local record = {}
	local len = string.len(encodedString)
	local offset = 1

	while offset + 19 <= len do
		local b1,b2,b3, b4,b5,b6, b7,b8,b9, b10,b11, b12,b13, b14,b15, b16,b17, b18,b19,b20 =
			string.byte(encodedString, offset, offset + 19)

		local px = (b1 * 65536 + b2 * 256 + b3) / 10 - 10000
		local py = (b4 * 65536 + b5 * 256 + b6) / 10 - 10000
		local pz = (b7 * 65536 + b8 * 256 + b9) / 10 - 10000

		local rx = (b10 * 256 + b11) / 10
		local ry = (b12 * 256 + b13) / 10
		local rz = (b14 * 256 + b15) / 10

		local model       = b16 * 256 + b17
		local elapsedTime = b18 * 65536 + b19 * 256 + b20

		table.insert(record, {
			position    = Vector3(px, py, pz),
			rotation    = Vector3(rx, ry, rz),
			model       = model,
			elapsedTime = elapsedTime,
		})

		offset = offset + 20
	end

	return record
end
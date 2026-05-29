MovementRecorder = inherit(Object)

local POSITION_DELTA_THRESHOLD = 0.05
local ROTATION_DELTA_THRESHOLD = 0.5

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
	self.m_Vehicle = localPlayer.vehicle
	self.m_RecordStartTick = getTickCount()
	self.m_Recording = true

	addEventHandler("onClientRender", root, self.m_fnRenderRecord)
end

function MovementRecorder:stopRecording()
	if not self.m_Recording then return end
	self.m_Recording = false
	removeEventHandler("onClientRender", root, self.m_fnRenderRecord)

	self.m_Record.duration = getTickCount() - self.m_RecordStartTick
end

function MovementRecorder:isRecording()
	return self.m_Recording
end

function MovementRecorder:startPlayback()
	if not self.m_VehicleDummy then return end
    if #self.m_Record == 0 then return end
	if self.m_RenderPlayback then self:stopPlayback() end

	--if self.m_PlayRecordFrame >= #self.m_Record then
		self.m_PlayRecordFrame = 1
	--end

	self.m_RenderPlayback = true
	self.m_PlaybackStartTick = getTickCount()
	self.m_PlaybackStartFrame = self.m_PlayRecordFrame or 1
	self.m_PlaybackDuration = self.m_Record.duration - self.m_Record[self.m_PlaybackStartFrame].elapsedTime

	addEventHandler("onClientRender", root, self.m_fnRenderPlayback)
end

function MovementRecorder:stopPlayback()
	self.m_RenderPlayback = false
	removeEventHandler("onClientRender", root, self.m_fnRenderPlayback)
end

function MovementRecorder:isPlaybackRendered()
	return m_RenderPlayback
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
	end

	if elapsed >= self.m_PlaybackDuration then
		self:stopPlayback()
	end
end

function MovementRecorder:updateFrame(frameA, frameB, alpha)
	local px, py, pz = interpolateBetween(frameA.position.x, frameA.position.y, frameA.position.z, frameB.position.x, frameB.position.y, frameB.position.z, alpha, "Linear")
	local rx, ry, rz = interpolateBetween(frameA.rotation.x, frameA.rotation.y, frameA.rotation.z, frameB.rotation.x, frameB.rotation.y, frameB.rotation.z, alpha, "Linear")

	self.m_VehicleDummy:setPosition(px, py, pz)
	self.m_VehicleDummy:setRotation(rx, ry, rz)
    self.m_VehicleDummy:setModel(frameA.model)
end
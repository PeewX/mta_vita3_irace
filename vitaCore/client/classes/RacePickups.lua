--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 11.05.2026 - Time: 19:16
-- pewx.de // iRace-mta.de // mtasa.de
--

RacePickup = inherit(Object)
RacePickups = {}

function RacePickup:constructor(id, pickupType, vehicleId, position)
    self.m_Id = id
    self.m_Type = pickupType
    self.m_VehicleId = vehicleId
    self.m_ColShape = ColShape.Sphere(position, 3.5)
    self.m_Object = createObject(PICKUP_MODELS[pickupType], position)

    self.m_ColShape:setDimension(localPlayer.dimension)
    self.m_Object:setDimension(localPlayer.dimension)

    self.m_OnPickupHitBind = bind(self.onPickupHit, self)

    RacePickups[self] = true
    addEventHandler("onClientColShapeHit", self.m_ColShape, self.m_OnPickupHitBind)
end

function RacePickup:destructor()
    removeEventHandler("onClientColShapeHit", self.m_ColShape, self.m_OnPickupHitBind)
    RacePickups[self] = nil

    if isElement(self.m_ColShape) then self.m_ColShape:destroy() end
    if isElement(self.m_Object) then self.m_Object:destroy() end
end

function RacePickup:onPickupHit(hitElement, matchingDimension)
    if not matchingDimension or hitElement.type ~= "vehicle" then return end
    if hitElement.controller ~= localPlayer then return end

    if self.m_Type == "repair" then
        hitElement:fix()
    end

    if self.m_Type == "nitro" then
        Splits:getSingleton():addSplit(self.m_Id)
        hitElement:addUpgrade(1010)
        triggerServerEvent("syncVehicleNitro", localPlayer)
    end

    if self.m_Type == "vehiclechange" then
        self:changeVehicle(hitElement)
    end

    --triggerSeverEvent("onRacePickupHit") -- Add when serverside RacePickup class is rdy
    playSoundFrontEnd(46)
end

function RacePickup:changeVehicle(hitElement)
    if not isElement(hitElement) then return end
    if hitElement.model == self.m_VehicleId then return end

    if self.m_VehicleId == VEHICLES.HUNTER then
        RaceTimer:getSingleton():finishAttempt()
        Splits:getSingleton():finish()
        triggerServerEvent('playerFinishedMap', localPlayer, RaceTimer:getSingleton():getPassedTime(), Splits:getSingleton():getRecord())
        if localPlayer:isGamemode(GAMEMODES.TT) then return end
    end

    local prevDistance = hitElement.distanceFromCentreOfMassToBaseOfModel
    alignVehicleWithUp(hitElement)

    local healthFix = false
    if hitElement.vehicleType == "Plane" then
        healthFix = hitElement:getHealth()
    end

    hitElement:setModel(self.m_VehicleId)
    if hitElement.vehicleType == "Helicopter" then
        setVehicleRotorSpeed(hitElement, 0.2)
    end

    if healthFix then
        hitElement:fix()
        hitElement:setHealth(healthFix)
    end

    local newDistance = hitElement.distanceFromCentreOfMassToBaseOfModel
    local zOffset = 1 -- (Default + 1 for classic vehicle change)
    if prevDistance and newDistance > prevDistance then
        zOffset = zOffset + (newDistance - prevDistance)
    end

    hitElement:setPosition(hitElement.position + Vector3(0, 0, zOffset))
    triggerServerEvent('syncVehicleModel', localPlayer, self.m_VehicleId)
end

function RacePickup.getAll()
    return RacePickups
end

function RacePickup.rotate()
    local angle = math.fmod((getTickCount() - g_PickupStartTick) * 360 / 2000, 360)
    local camera = Vector3(getCameraMatrix())

    for v in pairs(RacePickup.getAll()) do
        if v.m_Object then
            v.m_Object:setRotation(0, 0, angle)

            if v.m_Type == "vehiclechange" and v.m_Object:isOnScreen() then
                local pos = v.m_Object.position
                local distanceToPickup = (camera - pos):getLength()
                if distanceToPickup < 60 and isLineOfSightClear(camera.x, camera.y, camera.z, pos.x, pos.y, pos.z, true, false, false, true, false) then
                    local sx, sy = getScreenFromWorldPosition(pos.x, pos.y, pos.z + 1.5)
                    if sx and sy then
                        local scale = (60 / distanceToPickup) * 0.7
                        local renderText = ("|%s|"):format(Vehicle.getNameFromModel(v.m_VehicleId))
                        dxDrawText(renderText, sx-19, sy+1, sx+20, sy+20, tocolor(0, 0, 0, 255), scale, "default-bold", "center", "top", false, false, false, false, true)
                        dxDrawText(renderText, sx-20, sy,   sx+20, sy+20, tocolor(255, 255, 255, 255), scale, "default-bold", "center", "top", false, false, false, false, true)
                    end
                end
            end
        end
    end
end
addEventHandler("onClientRender", root, RacePickup.rotate)
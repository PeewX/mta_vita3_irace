--
-- PewX (HorrorClown)
-- Using: VSCode
-- Date: 11.05.2026 - Time: 19:16
-- pewx.de // iRace-mta.de // mtasa.de
--

RacePickup = inherit(Object)
RacePickups = {}

function RacePickup:constructor(pickupType, vehicleId, position)
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
    if not hitElement.controller == localPlayer then return end

    if self.m_Type == "repair" then
        hitElement:fix()
    end

    if self.m_Type == "nitro" then
        hitElement:addUpgrade(1010)
        triggerServerEvent("syncVehicleNitro", localPlayer)
    end

    if self.m_Type == "vehiclechange" then
        -- Simulate network lag via timer, as some race maps depend on this behavior
        -- The original race resource processes race pickups server-side, which introduces a delay proportional to the player's ping
        setTimer(bind(self.changeVehicle, self), 50, 1, hitElement)
    end

    playSoundFrontEnd(46)
end

function RacePickup:changeVehicle(hitElement)
    if not isElement(hitElement) then return end
    if hitElement.model == self.m_VehicleId then return end

    self:alignVehicleUp(hitElement)
    local oldDistance = hitElement.distanceFromCentreOfMassToBaseOfModel
    hitElement:setModel(self.m_VehicleId)
    local newDistance = hitElement.distanceFromCentreOfMassToBaseOfModel

    if oldDistance and oldDistance < newDistance then
        local newPosition = hitElement.matrix:transformPosition(Vector3(0, 0, -(oldDistance + newDistance)+1))
        hitElement:setPosition(newPosition)
    end

    triggerServerEvent('syncVehicleModel', localPlayer, self.m_VehicleId)
end

function RacePickup:alignVehicleUp(vehicle)
    if not vehicle then return end

    local matrix   = vehicle.matrix
    local velocity = vehicle.velocity
    local rotation = Vector3(0, 0, 0)

    if velocity:getLength() > 0.05 and matrix:getUp().z < 0.001 then
        rotation.z = 90 - math.deg(math.atan2(velocity.y, velocity.x))
    else
        rotation.z = matrix:getRotation().z
    end

    vehicle:setRotation(rotation)
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
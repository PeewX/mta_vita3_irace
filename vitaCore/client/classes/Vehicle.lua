-- ****************************************************************************
-- *
--*   PROJECT:  iRace
-- *  FILE:     client/classes/Vehicle.lua
-- *  DATE:     03.06.2026 / 23:00
-- *  PURPOSE:  Vehicle superclass
-- *
-- ****************************************************************************

VehicleElement = inherit(Object)
registerElementClass("vehicle", VehicleElement)

function VehicleElement:constructor()
end

function VehicleElement:getSpeed()
    return (self.velocity * 180).length
end
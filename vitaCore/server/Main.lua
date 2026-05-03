local Main = {}

function Main.resourceStart()
	-- Instantiate Core
    core = Core:new()
    math.randomseed(getRealTime().timestamp)
end
addEventHandler("onResourceStart", resourceRoot, Main.resourceStart, true, "high+99999")

function Main.resourceStop()
	core:delete()
end
addEventHandler("onResourceStop", resourceRoot, Main.resourceStop, true, "low-99999")
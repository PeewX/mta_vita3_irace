screenWidth, screenHeight = guiGetScreenSize ( ) 

local latentServerEventStatus = false
local isDownloading = false

function math.round(num, decimals)
    decimals = math.pow(10, decimals or 0)
    num = num * decimals
    if num >= 0 then num = math.floor(num + 0.5) else num = math.ceil(num - 0.5) end
    return num / decimals
end

function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end

downloads = {}

function downloadFile (file, saveTo, gamemodeID)
local path = ""
	if not file then return false; end
	if not gamemodeID then gamemodeID = getElementData(getLocalPlayer(), "gameMode") end
	if string.find(file, ":") == 1 then
		path = file
	else
		if sourceResource then
			path = ":"..getResourceName(sourceResource).."/"..file
		else
			path = file
		end

	end                    
	if string.len(path) == 0 then
		outputDebugString("There must be a valid file to download from.")
		return false;
	else
		if not saveTo then return false; end
		local saveToPath = ""
		if string.find(saveTo, ":") == 1 then
			saveToPath = saveTo
		else
			if sourceResource then
				saveToPath = ":"..getResourceName(sourceResource).."/"..saveTo
			else
				saveToPath = saveTo
			end
		end
		if string.len(saveToPath) == 0 then
			outputDebugString("You must enter a place for the file to be saved to.")
			return false;
		else
			triggerServerEvent("requestFileDownload", getLocalPlayer(), path, saveToPath, gamemodeID)
			return
		end
	end
end

function getClientFileSize(file, type) -- Types, "MB", "BYTE", "KB"
local path = ""
	if not file then return false; end
	if string.find(file, ":") == 1 then
		path = file
	else
		if sourceResource then
			path = ":"..getResourceName(sourceResource).."/"..file
		else
			path = file
		end

	end
	if string.len(path) == 0 then
		outputDebugString("There must be a valid file to read from.")
		return false;
	else
		local tFile = fileOpen(path, true)
		if tFile then
			local size = fileGetSize (tFile)
			if string.upper(type) == "KB" then
				size = math.round(size / 1024, 2)
			elseif string.upper(type) == "MB" then
				size = math.round(size / 1048576, 2)
			end
			fileClose(tFile)
			return size;
		else
			return false;
		end
	end
end

addEvent("onFileReceive", true)
addEventHandler("onFileReceive", getRootElement(),
	function (file, fileData, gameModeID)
		if downloads[file] then
			local newFile = fileCreate(file)
			fileWrite(newFile, fileData)
			fileClose(newFile)
			downloads[file] = nil
			if gameModeID == getElementData(getLocalPlayer(), "gameMode") then
				triggerEvent ( "onClientDownloadComplete", getRootElement(), file )
			end
			isDownloading = false
		else
			outputDebugString("Download complete, but can't find the chunks of data?", 3)
			isDownloading = false
		end
	end
)

addEvent("onClientDownloadPreStart", true)
addEventHandler("onClientDownloadPreStart", getRootElement(),
	function (serverFile, clientFile, fileSize, gameModeID)
		if fileExists(clientFile) then
			local file = fileOpen(clientFile, true)
			if file then
				if fileGetSize ( file ) == fileSize then 
					fileClose(file)
					if gameModeID == getElementData(getLocalPlayer(), "gameMode") then
						triggerEvent ( "onClientDownloadComplete", getRootElement(), clientFile)
					end
					return true                         
				end
				fileClose(file)
			end
		end
		
		if not downloads[clientFile] then
			downloads[clientFile] = {}
			downloads[clientFile]['files'] = {}
			triggerServerEvent("startFileDownload", getLocalPlayer(), serverFile, clientFile, gameModeID)
			isDownloading = true
			latentServerEventStatus = {}
			latentServerEventStatus.percentComplete = 0
		end
	end
)


addEvent("onClientDownloadFailure", true)
addEventHandler("onClientDownloadFailure", getRootElement(),
	function ()
	end
)

addEvent("onClientGetLatentInfo", true)
addEventHandler("onClientGetLatentInfo", getRootElement(),
	function (data)
		 latentServerEventStatus = data
	end
)
function renderDownload ()
	if not isDownloading then return false end
	if not latentServerEventStatus then return false end
	if not latentServerEventStatus.percentComplete then return false end
	if latentServerEventStatus.percentComplete == 100 or latentServerEventStatus.percentComplete == 0 then return false end
	
	local percent = latentServerEventStatus.percentComplete/100
	
	dxDrawImage ( screenWidth/2-256, screenHeight-256, 512, 128, "vita_download.png" )	
	dxDrawImageSection ( screenWidth/2-94,screenHeight-185.5, 187*percent, 10, 0,0, 187*percent, 10, "vita_download_progress.png", 
    0,0,0, tocolor(255,255,0,255) )	
	
	--dxDrawRectangle ( screenWidth/2-150, screenHeight -110, 200, 50, tocolor(0,0,0,200) )
	--dxDrawText("Downloading file:\n"..latentServerEventStatus.percentComplete, 1, screenHeight-149, screenWidth, screenHeight, tocolor(0,0,0,100), 1 , "default-bold", "center",  "top", false, false, true)
	--dxDrawText("Downloading file:\n"..latentServerEventStatus.percentComplete, 0, screenHeight-150, screenWidth, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", false, false, true)
		
	--[[local myHandles = getLatentEventHandles()
	if not myHandles then return false end
	outputChatBox(tostring(getLatentEventHandles()))
	local handle = getLatentEventHandles()[#getLatentEventHandles()]
	outputChatBox(tostring(getLatentEventHandles()))
	--if myHandles[1] then
		--local handle = myHandles[1]
		local status = getLatentEventStatus(handle)
		dxDrawRectangle ( screenWidth/2-100, screenHeight -110, 200, 50, tocolor(0,0,0,200) )
		dxDrawText("Downloading file:\n"..percentComplete, 1, screenHeight-99, screenWidth, screenHeight, tocolor(0,0,0,100), 1 , "default-bold", "center",  "top", false, false, true)
		dxDrawText("Downloading file:\n"..percentComplete, 0, screenHeight-100, screenWidth, screenHeight, tocolor(255,255,255,255), 1, "default-bold", "center", "top", false, false, true)		
	--end]]--
end
addEventHandler ( "onClientRender", getRootElement(), renderDownload, true, "low-1" )
Package = {}

function Package.save(path, filelist, stripResourcePath)
    local pack = setmetatable({}, { __index = Package })
    local fh = fileCreate(path)

    if not fh then outputDebugString("[PACKAGE] Cant create package: " .. path) return end

    for k, v in pairs(filelist) do
        pack:addFile(fh, v, stripResourcePath)
    end

    fileClose(fh)
end

function Package.load(path, targetPath)
    local fh = fileOpen(path)
    while fileGetSize(fh) ~= fileGetPos(fh) do
        local name = Package._readEntry(fh, 256)
        local size = Package._readEntry(fh, 32)
        local data = fileRead(fh, tonumber(size))
        if targetPath then
            --name = name:gsub("^:[^/]+/", resourceOverwrite .. "/")
            name = ("%s/%s"):format(targetPath, name)
        end

        if fileExists(name) then fileDelete(name) end

        local ff = fileCreate(name)
        if ff then
            fileWrite(ff, data)
            fileClose(ff)
        else
            outputDebugString("[PACKAGE] Cant write file: " .. name)
        end
    end
    fileClose(fh)
end

function Package._readEntry(fh, maxlen)
    local pos = fileGetPos(fh)
    local buf = fileRead(fh, maxlen)
    local nullpos = buf:find("\00", 1, true)
    local name = buf:sub(1, nullpos - 1)
    fileSetPos(fh, pos + #name + 1)
    return name
end

function Package:addFile(fh, file, stripResourcePath)
    local r = fileOpen(file)
    if not r then
        outputDebugString("[PACKAGE] Cant open file : " .. file)
        return
    end
    local size = fileGetSize(r)
    local data = fileRead(r, size)
    fileClose(r)

    local name = file
    if stripResourcePath then
        name = file:match("^:[^/]+/(.+)$") or file
    end

    fileWrite(fh, name)
    fileWrite(fh, "\00")
    fileWrite(fh, tostring(size))
    fileWrite(fh, "\00")
    fileWrite(fh, data)
end

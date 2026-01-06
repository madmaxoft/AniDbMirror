-- moveBadSubfolders.lua

--[[
Moves all the <number>.xml files in "src" folder" (recursive) into the correct subfolder of AniDB,
based on the number in the filename: "AniDB/<number / 100>/<number>.xml"
--]]

local lfs = require("lfs")





--- Configuration
local srcDir = "src"  -- source folder
local dstDir = "AniDB"  -- destination folder





--- Ensure a directory exists, create if not
local function ensureDir(aPath)
    local attr = lfs.attributes(aPath)
    if not(attr) then
        assert(lfs.mkdir(aPath))
    elseif (attr.mode ~= "directory") then
        error(aPath .. " exists and is not a directory")
    end
end





--- Compute destination folder prefix from filename number
local function getPrefix(numStr)
    local len = #numStr
    if len <= 2 then
        return "0"
    else
        return numStr:sub(1, len - 2)
    end
end





--- Recursively scan source directory
local function scanDir(aPath)
    for entry in lfs.dir(aPath) do
        if ((entry ~= ".") and (entry ~= "..")) then
            local fullPath = aPath .. "/" .. entry
            local attr = lfs.attributes(fullPath)
            if (attr.mode == "directory") then
                scanDir(fullPath)
            elseif (attr.mode == "file") then
                local numStr = entry:match("^(%d+)%.xml$")
                if (numStr) then
                    local prefix = getPrefix(numStr)
                    local destFolder = dstDir .. "/" .. prefix
                    ensureDir(destFolder)
                    local destPath = destFolder .. "/" .. entry
                    -- Move file
                    assert(os.rename(fullPath, destPath))
                    print("Moved " .. fullPath .. " -> " .. destPath)
                end
            end
        end
    end
end





-- Ensure destination root exists
ensureDir(dstDir)
-- Start scanning
scanDir(srcDir)

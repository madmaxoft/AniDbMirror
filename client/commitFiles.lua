-- commitFiles.lua

--[[
Commits existing XML response files from the disk (in AniDB subfolder), using their last modification
time as the time of last update.
--]]




local socket = require("socket")
local sockethttp = require("socket.http")
local ltn12 = require("ltn12")
local lfs = require("lfs")
local zlib = require("zlib")

local config = require("config")
local http = require("http")
local utils = require("utils")





--- Commits the specified file
-- The ID is inferred from the filename
-- The file's last modification date is sent as well
-- Returns true on success, nil and message on failure
local function commitFile(aFileName)
	assert(type(aFileName) == "string")

	local id = aFileName:match("(%d+)%.xml")
	id = tonumber(id)
	if not(id) then
		return nil, "Cannot infer ID from the filename"
	end

	-- Read the file contents:
	local f, msg = io.open(aFileName, "rb")
	if not(f) then
		return nil, "Cannot open file: " .. tostring(msg)
	end
	local fileContents = f:read("*all")
	f:close()

	-- Decompress if the file is compressed:
	if (fileContents:sub(1,2) == "\031\139") then
		if (zlib._VERSION:match("lzlib")) then
			fileContents = zlib.inflate(fileContents)
		elseif (zlib._VERSION:match("lua%-zlib")) then
			fileContents = zlib.inflate()(fileContents)
		else
			error("Unknown ZLIB version, was expecting lua-zlib or lzlib")
		end
	end

	-- Get the file's lastmod date:
	local lastMod = lfs.attributes(aFileName, "modification")

	-- Commit the file:
	local url = config.apiBaseUrl .. "/submit"
	local body =
		"id=" .. tostring(id) ..
		"&lastMod=" .. tostring(lastMod) ..
		"&detailsBlobB64=" .. utils.urlEncode(utils.base64Encode(fileContents))
	print("  Submitting file " .. aFileName)
	local resp, msg = http.post(url, body)
	if not(resp) then
		return nil, "Failed to post the commit: " .. tostring(msg)
	end
	if not(resp.ok) then
		return nil, "Posting failed: " .. tostring(resp.error)
	end
	return true
end





--- Recursively commits all files in the specified folder
local function commitFolder(aPath)
	assert(type(aPath) == "string")

	print("Processing folder " .. aPath)
	for fnam in lfs.dir(aPath) do
		if ((fnam ~= ".") and (fnam ~= "..")) then
			local fullName = aPath .. "/" .. fnam
			local mode = lfs.attributes(fullName, "mode")
			if (mode == "directory") then
				commitFolder(fullName)
			elseif (mode == "file") then
				if (fnam:match("%d+%.xml")) then
					local isOK, msg = commitFile(fullName)
					if not(isOK) then
						print(string.format("Failed to commit file %s: %s", fullName, tostring(msg)))
					end
				end
			end
		end
	end
end





commitFolder("AniDB")

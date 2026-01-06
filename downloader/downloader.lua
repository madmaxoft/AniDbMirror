-- downloader.lua

--[[
Downloads all items from the API server into local files.
Skips files that already exist.

Accepts parameters:
	1: the API server to use
	2: the maximum ID to download
--]]




local http = require("socket.http")
local ltn12 = require("ltn12")
local mime = require("mime")
local lfs = require("lfs")




-- Parameters:
local arg = {...}
local gApiServer = arg[1] or "http://xoft.cz/AniDbMirror/api"





--- Writes binary data to a file
local function writeToFile(aPath, aData)
	local f = assert(io.open(aPath, "wb"))
	f:write(aData)
	f:close()
end





--- Fetches one dump batch from the server
-- Returns parsed Lua table
local function fetchDumpBatch(aAfterId, aLimit)
	assert(type(aAfterId) == "number")
	assert(type(aLimit) == "number")

	-- Download the batch:
	local url = string.format(
		"%s/dump?afterId=%d&limit=%d",
		gApiServer,
		aAfterId,
		aLimit
	)

	local responseChunks = {}
	local ok, statusCode = http.request{
		url = url,
		sink = ltn12.sink.table(responseChunks),
		method = "GET",
	}
	if not(ok) then
		error("HTTP request failed")
	end
	if (statusCode ~= 200) then
		error(string.format("HTTP status %s", tostring(statusCode)))
	end

	-- Parse the response as a Lua table:
	local body = table.concat(responseChunks)
	local chunk, err = load("return " .. body)
	if not(chunk) then
		error("Failed to parse Lua response: " .. tostring(err))
	end
	return chunk()
end





--- Stores a single item to disk
local function storeItem(aItem)
	assert(type(aItem) == "table")

	local idStr = tostring(aItem.id)
	local prefix
	if (#idStr > 2) then
		prefix = string.sub(idStr, 1, #idStr - 2)
	else
		prefix = "0"
	end
	local dirPath = string.format("AniDB/%s", prefix)
	lfs.mkdir(dirPath)
	local filePath = string.format("%s/%s.xml", dirPath, idStr)
	local decoded = mime.unb64(aItem.resultB64)
	writeToFile(filePath, decoded)
end





--- Main download loop
local function run()
	local afterId = 0
	local limit = 500
	local total = 0

	lfs.mkdir("AniDB")
	while (true) do
		local resp = fetchDumpBatch(afterId, limit)

		if (not resp.ok) then
			error("API error: " .. tostring(resp.error))
		end

		local items = resp.items
		if (#items == 0) then
			break
		end

		for _, item in ipairs(items) do
			storeItem(item)
			afterId = item.id
			total = total + 1
		end

		io.stdout:write(
			string.format("\rDownloaded %d items...", total)
		)
		io.stdout:flush()
	end

	print(string.format("\nDone. Total items: %d", total))
end





run()

-- main.lua

--[[
AniDbMirror Lua client main loop.
Queries the AniDbMirror CnC server for anime details to download, then downloads them
and commits them back to the CnC server.
--]]





local socket = require("socket")
local sockethttp = require("socket.http")
local ltn12 = require("ltn12")
local lom = require("lxp.lom")
local lfs = require("lfs")
local zlib = require("zlib")
local expat = require("lxp")

local config = require("config")
local http = require("http")
local utils = require("utils")





--- Log a message with timestamp
local function log(aMsg)
	print(os.date("%Y-%m-%d %H:%M:%S") .. " | " .. aMsg)
end





--- Check server status
-- Returns true if the server replies as expected
local function checkServer()
	local url = config.apiBaseUrl .. "/status.php"
	local resp, err = http.get(url)
	if not resp then
		return nil, err
	end
	if ((type(resp) ~= "table") or not(resp.ok)) then
		return nil, "invalid status response"
	end
	return true
end





--- Request a single work item
-- Returns the lua table returned from the API call
local function requestWork()
	local url = config.apiBaseUrl .. "/requestChunk.php"
	local body = ""
	return http.post(url, body)
end





--- Notifies the CnC server that we cannot complete this piece of work, let someone else handle it
local function abortWork(aId)
	assert(tonumber(aId))

	local url = config.apiBaseUrl .. "/giveBackChunk.php"
	local body = "id=" .. tostring(aId)
	return http.post(url, body)
end





--- Commit work result
local function commitWork(aId, aResult)
	assert(tonumber(aId))
	assert(type(aResult) == "string")

	local url = config.apiBaseUrl .. "/submitChunk.php"
	local body =
		"id=" .. tostring(aId) ..
		"&detailsBlobB64=" .. utils.base64Encode(aResult)
	return http.post(url, body)
end





--- Fetches AniDB XML for the specified aId
-- If the response is compressed, decompresses it.
-- Also stores the received data into a file, no matter what is received
local function fetchAniDbXml(aId)
	assert(tonumber(aId))

	-- Pause for a while not to overload the server:
	socket.sleep(3)

	local url = "http://api.anidb.net:9001/httpapi?client=localanidbmirror&clientver=3&protover=1&request=anime&aid=" .. aId
	local response = {}
	local ok, code, headers = sockethttp.request{
		url = url,
		sink = ltn12.sink.table(response),
		headers = {
			["User-Agent"] = "AniDbXref/1",
		},
	}
	if (not(ok) or (code ~= 200)) then
		return nil, "HTTP request failed: " .. tostring(code)
	end
	response = table.concat(response)

	-- Decompress if the response is compressed:
	if (response:sub(1,2) == "\031\139") then
		if (zlib._VERSION:match("lzlib")) then
			response = zlib.inflate(response)
		elseif (zlib._VERSION:match("lua%-zlib")) then
			response = zlib.inflate()(response)
		else
			error("Unknown ZLIB version, was expecting lua-zlib or lzlib")
		end
	end

	-- Save to file:
	local path = string.format("AniDB/%.03d", math.floor(aId / 100))
	lfs.mkdir("AniDB")
	lfs.mkdir(path)
	local fileName = string.format("AniDB/%.03d/%d.xml", math.floor(aId / 100), aId)
	local f = assert(io.open(fileName, "wb"))
	f:write(response)
	f:close()

	return response
end





--- Processes a single aId piece
-- Returns the work to be committed to the CnC server, or nil and error message
-- If the rate-limit is reached, blocks for 3 hours before returning a failure
local function processWork(aId)
	assert(tonumber(aId))

	local resp, msg = fetchAniDbXml(aId)
	if not(resp) then
		return nil, "Failed to fetch AniDb XML: " .. tostring(msg)
	end

	-- Assume that big responses are valid anime details:
	if (#resp > 1000) then
		return resp
	end

	-- For smaller responses, parse and check if it is an error:
	local parsedLom = lom.parse(resp)
	if (
		parsedLom and
		(parsedLom.tag == "error") and
		((parsedLom.attr or {}).code == "500")
	) then
		log("API returned rate-limit response for aid " .. aId .. ", stored to file " .. fileName)
		log("Waiting for 3 hours before re-requesting.")
		abortWork(aId)
		socket.sleep(3 * 60 * 60)
		return nil, "rate-lmit"
	end

	-- Not an error, commit it:
	return resp
end





--- Main work loop
log("Starting AniDbMirror client")

local ok, err = checkServer()
if not ok then
	error("Server check failed: " .. tostring(err))
end
log("Server verified")

-- while true do
	local resp, err = requestWork()
	if not(resp) then
		log("reserve failed: " .. tostring(err))
		socket.sleep(config.pollDelaySeconds)
		goto continue
	end

	if not(resp.ok) then
		log("no work available")
		socket.sleep(config.pollDelaySeconds)
		goto continue
	end

	local id = resp.id
	log("Reserved id " .. tostring(id))

	local result, msg = processWork(id)
	if not(result) then
		log("processing failed: " .. tostring(msg))
		os.exit(1)
	end

	local commitResp, commitErr = commitWork(id, result)
	if not(commitResp) then
		log("commit failed: " .. tostring(commitErr))
	elseif not(commitResp.ok) then
		log("commit rejected: " .. tostring(commitResp.error))
	else
		log("Committed id " .. tostring(id))
	end

	::continue::
-- end

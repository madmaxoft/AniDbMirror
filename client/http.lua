-- http.lua

--[[
Implements http helper functions for getting and posting data to the CnC server.
--]]





local http = require("socket.http")
local ltn12 = require("ltn12")
local config = require("config")





local M = {}





--- Parses the given string into a Lua table
-- Returns nil and error message on failure
local function parseLuaTable(aBody)
	local chunk, err = loadstring("return " .. aBody)
	if not chunk then
		return nil, "invalid lua response: " .. tostring(err)
	end

	local ok, result = pcall(chunk)
	if not ok then
		return nil, "lua eval failed: " .. tostring(result)
	end

	return result
end





--- Sends a GET request to the CnC server
-- Returns the response as a Lua table, or nil and message on failure
function M.get(aUrl)
	local responseChunks = {}
	local ok, code = http.request(
	{
		url = aUrl,
		sink = ltn12.sink.table(responseChunks),
		headers =
		{
			["Client-Name"] = config.clientName,
		},
	})
	if not(ok) then
		return nil, "http GET failed"
	end
	local body = table.concat(responseChunks)
	return parseLuaTable(body)
end





--- Sends a GET request to the CnC server
-- Returns the response as a Lua table, or nil and message on failure
function M.post(aUrl, aBody)
	local responseChunks = {}
	local ok, code = http.request(
	{
		url = aUrl,
		method = "POST",
		headers = {
			["Content-Type"] = "application/x-www-form-urlencoded",
			["Content-Length"] = tostring(#aBody),
			["Client-Name"] = config.clientName,
			["Client-Auth"] = config.clientAuth,
		},
		source = ltn12.source.string(aBody),
		sink = ltn12.sink.table(responseChunks),
	})
	if not(ok) then
		return nil, "http POST failed"
	end
	local body = table.concat(responseChunks)
	return parseLuaTable(body)
end





return M

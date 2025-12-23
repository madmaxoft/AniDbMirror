-- utils.lua

--[[
Implements various utilities
--]]





local M = {}





--- Base64-encode a string
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
function M.base64Encode(aData)
	assert(type(aData) == "string")

	local result = {}
	local padding = 0

	for i = 1, #aData, 3 do
		local a, b1, c = aData:byte(i, i + 2)
		if not(b1) then
			b1 = 0
			padding = padding + 1
		end
		if not(c) then
			c = 0
			padding = padding + 1
		end
		local n = a * 65536 + b1 * 256 + c
		local c1 = math.floor(n / 262144) % 64 + 1
		local c2 = math.floor(n / 4096) % 64 + 1
		local c3 = math.floor(n / 64) % 64 + 1
		local c4 = n % 64 + 1
		result[#result + 1] = b:sub(c1, c1) .. b:sub(c2, c2) .. b:sub(c3, c3) .. b:sub(c4, c4)
	end

	if (padding > 0) then
		result[#result] = result[#result]:sub(1, 4 - padding) .. string.rep("=", padding)
	end

	return table.concat(result)
end





--- URL-encodes the specified string
function M.urlEncode(aStr)
	assert(type(aStr) == "string")

	return (aStr:gsub("([^%w%-_%.~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end





return M

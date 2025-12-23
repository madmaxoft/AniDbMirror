-- updateFromLocal.lua

--[[
Imports AniDB anime IDs into remote MySQL
	- Parses local file "anime-titles.xml.gz" (in config.lua)
	- Inserts missing IDs in batches into DB's Details table
	- Outputs progress as Lua tables
--]]

local lxp = require("lxp")           -- LuaExpat XML parser
local luasql = require("luasql.mysql")
local zlib = require("zlib")         -- zlib binding for LuaJIT/Lua
local config = require("config")


-- ------------------------
-- Setup DB
-- ------------------------
local env = assert(luasql.mysql())
local conn = assert(env:connect(config.dbName, config.dbUser, config.dbPass, config.dbHost, config.dbPort))
conn:setautocommit(false)

-- ------------------------
-- Helper: execute batch insert
-- ------------------------
local function insertBatch(batch)
	if #batch == 0 then return 0 end
	local values = {}
	for _, id in ipairs(batch) do
		table.insert(values, "(" .. id .. ")")
	end
	local sql = "INSERT IGNORE INTO Details (id) VALUES " .. table.concat(values, ",")
	local cur = assert(conn:execute(sql))
	conn:commit()
	return #batch
end

-- ------------------------
-- Parse XML.GZ
-- ------------------------
local batch = {}
local total = 0
local added = 0

local function startElement(aParser, aName, aAttrs)
	if (aName == "anime") then
		local aid = tonumber(aAttrs.aid)
		if aid then
			table.insert(batch, aid)
			total = total + 1
			if (#batch >= config.batchSize) then
				added = added + insertBatch(batch)
				batch = {}
			end
		end
	end
end

local parser = lxp.new(
{
	StartElement = startElement
})

-- open gz file
local f = assert(io.open(config.xmlGzPath, "rb"))
local gz = zlib.inflate()(f:read("*a"))
f:close()

-- feed parser in chunks
local chunkSize = 8192
local pos = 1
while (pos <= #gz) do
	local chunk = gz:sub(pos, pos + chunkSize - 1)
	parser:parse(chunk)
	pos = pos + chunkSize
end
parser:parse() -- signal EOF
parser:close()

-- insert remaining batch
added = added + insertBatch(batch)

-- ------------------------
-- Done
-- ------------------------
print(string.format("{ ok = true, totalRead = %d, added = %d }", total, added))

conn:close()
env:close()

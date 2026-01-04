-- updateFromLocal.lua

--[[
Imports AniDB anime IDs into remote MySQL
	- Downloads the newest "anime-titles.xml.gz" from AniDB, if local copy is older than 1 day
	- Parses the "anime-titles.xml.gz"
	- Inserts missing IDs in batches into DB's Details table
--]]

local http = require("socket.http")
local ltn12 = require("ltn12")
local lfs = require("lfs")
local lxp = require("lxp")
local luasql = require("luasql.mysql")
local zlib = require("zlib")
local config = require("config")





-- Download the newest anime-titles.xml.gz to the current folder:
local tmpFile = "anime-titles.xml.gz"
local lastModTimestamp = lfs.attributes(tmpFile, "modification") or 0
if (lastModTimestamp < os.time() - 24 * 60 * 60) then
	print("Downloading new AniDB dump...")
	local f = assert(io.open(tmpFile, "wb"))
	http.request{ url = "http://anidb.net/api/anime-titles.xml.gz", sink = ltn12.sink.file(f) }
	print("Dump downloaded.")
else
	print("AniDB dump is recent enough, will NOT download a new one.")
end





-- Setup DB:
local env = assert(luasql.mysql())
local conn = assert(env:connect(config.dbName, config.dbUser, config.dbPass, config.dbHost, config.dbPort))
conn:setautocommit(false)





--- Batch-inserts the specified IDs into the DB, ignoring any existing ones
-- Returns the number of IDs actually inserted
local function insertBatch(aBatch)
	if (#aBatch == 0) then
		return 0
	end
	local values = {}
	for _, id in ipairs(aBatch) do
		table.insert(values, "(" .. id .. ")")
	end
	local sql = "INSERT IGNORE INTO Details (id) VALUES " .. table.concat(values, ",")
	local numInserted = assert(conn:execute(sql))
	conn:commit()
	return numInserted
end





-- Parse XML.GZ:
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
print("Inflating the dump file...")
f = assert(io.open(tmpFile, "rb"))
local gz = zlib.inflate()(f:read("*a"))
f:close()
print("Inflated.")

-- Feed the XML parser in chunks:
print("Processing XML...")
local chunkSize = 8192
local pos = 1
while (pos <= #gz) do
	local chunk = gz:sub(pos, pos + chunkSize - 1)
	parser:parse(chunk)
	pos = pos + chunkSize
end
parser:parse() -- signal EOF
parser:close()
added = added + insertBatch(batch)  -- insert the remaining batch
print(string.format("Done, read %d bytes of XML data", pos - 1))






-- Done
print(string.format("totalRead = %d, added = %d", total, added))
conn:close()
env:close()

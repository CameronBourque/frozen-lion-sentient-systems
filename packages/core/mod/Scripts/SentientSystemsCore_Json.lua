-- Encodes Lua values as JSON on one line, and prints long text in pieces the tuner can carry. The
-- bridge sends SentientSystems_PrintChunks(SentientSystems_EncodeJson(value)) and joins the lines
-- it gets back. Example: SentientSystems_EncodeJson({ cities = { { id = 65536, name = "Aduatuca" } } })
-- returns '{"cities":[{"id":65536,"name":"Aduatuca"}]}'.

-- A print longer than about 2 MiB gets no reply from the tuner, so each piece stays well under it.
-- See docs/findings/tuner-commands.md.
local CHUNK_BYTES = 1000000

-- Numbers from -2^53 to 2^53 are whole numbers that a double holds exactly.
local MAX_EXACT = 2 ^ 53

local ESCAPES = {
	["\""] = "\\\"",
	["\\"] = "\\\\",
	["\b"] = "\\b",
	["\f"] = "\\f",
	["\n"] = "\\n",
	["\r"] = "\\r",
	["\t"] = "\\t",
}

-- Quotes text, and escapes the quote, the backslash, and each control character. Other bytes,
-- such as UTF-8 text, pass through.
local function EncodeString(text)
	return "\"" .. text:gsub("[%c\"\\]", function(char)
		return ESCAPES[char] or string.format("\\u%04x", char:byte())
	end) .. "\""
end

-- JSON has no infinity or NaN, so they become null. Whole numbers print with every digit, where
-- tostring would round IDs past 14 digits.
local function EncodeNumber(number)
	if number ~= number or number == math.huge or number == -math.huge then
		return "null"
	end

	if number == math.floor(number) and math.abs(number) <= MAX_EXACT then
		return string.format("%.0f", number)
	end

	return string.format("%.14g", number)
end

-- Returns how many items a table holds when its keys are exactly 1 to n, or nil when it isn't a list.
-- An empty table is a list.
local function ListLength(value)
	local count = 0

	for _ in pairs(value) do
		count = count + 1
	end

	for i = 1, count do
		if value[i] == nil then
			return nil
		end
	end

	return count
end

local Encode

-- Adds each part of a table's JSON to parts. inProgress holds the tables being encoded, so a table
-- that holds itself raises an error instead of overflowing the stack.
local function EncodeTable(value, path, parts, inProgress)
	if inProgress[value] then
		error("can't encode a table that holds itself, at " .. path, 0)
	end

	inProgress[value] = true

	local length = ListLength(value)

	if length ~= nil then
		parts[#parts + 1] = "["

		for i = 1, length do
			if i > 1 then
				parts[#parts + 1] = ","
			end

			Encode(value[i], path .. "[" .. i .. "]", parts, inProgress)
		end

		parts[#parts + 1] = "]"
	else
		-- Sorted keys give the same text for the same state. A number key, such as a unit ID, is
		-- written as text.
		local entries = {}

		for key, item in pairs(value) do
			local keyType = type(key)

			if keyType ~= "string" and keyType ~= "number" then
				error("can't encode a " .. keyType .. " key, at " .. path, 0)
			end

			entries[#entries + 1] = { key = keyType == "number" and EncodeNumber(key) or key, item = item }
		end

		table.sort(entries, function(a, b)
			return a.key < b.key
		end)

		parts[#parts + 1] = "{"

		for i, entry in ipairs(entries) do
			if i > 1 then
				parts[#parts + 1] = ","
			end

			parts[#parts + 1] = EncodeString(entry.key) .. ":"
			Encode(entry.item, path .. "." .. entry.key, parts, inProgress)
		end

		parts[#parts + 1] = "}"
	end

	inProgress[value] = nil
end

-- Adds each part of value's JSON to parts. Encode is declared above EncodeTable, which calls it.
Encode = function(value, path, parts, inProgress)
	local valueType = type(value)

	if valueType == "table" then
		EncodeTable(value, path, parts, inProgress)
	elseif valueType == "string" then
		parts[#parts + 1] = EncodeString(value)
	elseif valueType == "number" then
		parts[#parts + 1] = EncodeNumber(value)
	elseif valueType == "boolean" then
		parts[#parts + 1] = tostring(value)
	elseif value == nil then
		parts[#parts + 1] = "null"
	else
		error("can't encode a " .. valueType .. ", at " .. path, 0)
	end
end

-- Returns value as JSON. A table whose keys are 1 to n is a list, and an empty table is an empty
-- list. Any other table is an object, with its keys sorted. Raises an error for a function or
-- userdata, a key that isn't a string or number, or a table that holds itself, and names where.
function SentientSystems_EncodeJson(value)
	local parts = {}

	Encode(value, "value", parts, {})

	return table.concat(parts)
end

-- Prints text in pieces of at most CHUNK_BYTES bytes, and at least one piece, so the bridge can join
-- the lines it gets back. The bridge decodes each print as UTF-8 on its own, so a piece never ends
-- inside a character: the cut moves back past UTF-8 continuation bytes, 0x80 to 0xBF.
function SentientSystems_PrintChunks(text)
	local start = 1

	repeat
		local finish = math.min(start + CHUNK_BYTES - 1, #text)

		while finish < #text and finish > start do
			local nextByte = text:byte(finish + 1)

			if nextByte < 0x80 or nextByte > 0xBF then
				break
			end

			finish = finish - 1
		end

		print(text:sub(start, finish))
		start = finish + 1
	until start > #text
end

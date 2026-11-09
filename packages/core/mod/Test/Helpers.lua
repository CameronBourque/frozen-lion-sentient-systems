-- Helpers that many of the Lua tests share.

local Helpers = {}

-- Returns a shallow copy of the table, with the changes on top.
function Helpers.With(original, changes)
	local copy = {}

	for key, value in pairs(original) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

-- Returns the JSON of an action that failed for the reason.
function Helpers.Failed(reason)
	return "{\"ok\":false,\"reason\":\"" .. reason .. "\"}"
end

-- Returns the entry of a player in a list of entries, or the unmet one for nil.
function Helpers.Entry(json, id)
	for entry in json:gmatch("%b{}") do
		if id == nil and entry:find("\"unmet\":true", 1, true) then
			return entry
		elseif id ~= nil and entry:find("\"player\":" .. id .. ",", 1, true) then
			return entry
		end
	end
end

return Helpers

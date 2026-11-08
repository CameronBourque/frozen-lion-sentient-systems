-- The result every action returns to the bridge, as JSON, and the helpers that
-- several actions share. See docs/design/core/mod/actions.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Text")
SentientSystems_Include("SentientSystemsCore_Lookups")

-- The most tiles a reason lists before it gives a count.
local MAX_LISTED = 8

-- Runs an action and returns its result as JSON for the bridge. The action
-- returns nil when it worked, and the reason it failed as text otherwise. A
-- Lua error in it comes back as a failure too, with the error's first line.
function SentientSystems_RunAction(name, action)
	local ok, reason = pcall(action)

	if not ok then
		reason = name .. " failed: " .. tostring(reason):match("[^\n]*")
	end

	if reason == nil then
		return SentientSystems_EncodeJson({ ok = true })
	end

	return SentientSystems_EncodeJson({ ok = false, reason = tostring(reason) })
end

-- Returns whether the list of tiles holds the tile at x and y.
function SentientSystems_HasTile(tiles, x, y)
	for _, tile in ipairs(tiles) do
		if tile.x == x and tile.y == y then
			return true
		end
	end

	return false
end

-- Returns the tiles as text for a reason: the first MAX_LISTED in the list's
-- order, then a count of the rest.
function SentientSystems_ListTiles(tiles)
	local listed = {}

	for i = 1, math.min(#tiles, MAX_LISTED) do
		listed[i] = "(" .. tiles[i].x .. ", " .. tiles[i].y .. ")"
	end

	local more = #tiles > MAX_LISTED and ", and " .. (#tiles - MAX_LISTED) .. " more" or ""

	return table.concat(listed, ", ") .. more
end

SentientSystems_Include("SentientSystemsCore_ActionsUnits")
SentientSystems_Include("SentientSystemsCore_ActionsCities")
SentientSystems_Include("SentientSystemsCore_ActionsTrade")
SentientSystems_Include("SentientSystemsCore_ActionsSpies")

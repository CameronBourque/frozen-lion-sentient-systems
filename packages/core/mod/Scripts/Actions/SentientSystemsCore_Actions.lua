-- The result every action returns to the bridge, as JSON, and the helpers that
-- several actions share. See docs/design/core/mod/actions.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Text")

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

SentientSystems_Include("SentientSystemsCore_ActionsUnits")
SentientSystems_Include("SentientSystemsCore_ActionsCities")
SentientSystems_Include("SentientSystemsCore_ActionsTrade")
SentientSystems_Include("SentientSystemsCore_ActionsSpies")

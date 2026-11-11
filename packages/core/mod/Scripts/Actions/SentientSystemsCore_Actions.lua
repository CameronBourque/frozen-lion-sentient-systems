-- The result every action returns to the bridge, as JSON, and the helpers that
-- several actions share. See docs/design/core/mod/actions/README.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Text")
SentientSystems_Include("SentientSystemsCore_Lookups")

-- The most tiles a reason lists before it gives a count.
local MAX_LISTED = 8

-- Runs an action with the arguments after it and returns its result as JSON
-- for the bridge. The action returns nil when it worked, and the reason it
-- failed as text otherwise. A Lua error in it comes back as a failure too, with
-- the error's first line.
function SentientSystems_RunAction(name, action, ...)
	local ok, reason = pcall(action, ...)

	if not ok then
		reason = name .. " failed: " .. tostring(reason):match("[^\n]*")
	end

	if reason == nil then
		return SentientSystems_EncodeJson({ ok = true })
	end

	return SentientSystems_EncodeJson({ ok = false, reason = tostring(reason) })
end

-- Returns the player's unit by ID, or nil and the reason.
function SentientSystems_FindUnit(playerID, unitID)
	local unit = UnitManager.GetUnit(playerID, unitID)

	if unit == nil then
		return nil, "Player " .. tostring(playerID) .. " has no unit " .. tostring(unitID) .. "."
	end

	return unit, nil
end

-- Returns why x and y name no tile on the map, or nil when they name one.
function SentientSystems_GetOffMapFailure(x, y)
	if x == nil or y == nil then
		return "That action needs a tile. Give x and y."
	end

	if not Map.IsPlot(x, y) then
		return "The tile (" .. x .. ", " .. y .. ") is off the map."
	end

	return nil
end

-- Returns why x and y name no tile on the map that the player sees, or nil.
function SentientSystems_GetUnseenTileFailure(playerID, x, y)
	local offMap = SentientSystems_GetOffMapFailure(x, y)

	if offMap ~= nil then
		return offMap
	end

	if not PlayersVisibility[playerID]:IsVisible(x, y) then
		return "You can't see that tile."
	end

	return nil
end

-- Returns the parameters that name the tile at x and y to a request. types is
-- the table of the request's kind, which holds its PARAM_X and PARAM_Y keys.
function SentientSystems_GetTileParams(types, x, y)
	return { [types.PARAM_X] = x, [types.PARAM_Y] = y }
end

-- Requests the unit operation when the game allows it, or returns the refusal.
-- plot is the target tile that a few operations check, and nil for the rest.
function SentientSystems_RequestUnitOperation(unit, operation, params, refusal, plot)
	if not UnitManager.CanStartOperation(unit, operation, plot, params) then
		return refusal
	end

	UnitManager.RequestOperation(unit, operation, params)

	return nil
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
SentientSystems_Include("SentientSystemsCore_ActionsResearch")
SentientSystems_Include("SentientSystemsCore_ActionsPolicies")
SentientSystems_Include("SentientSystemsCore_ActionsReligion")
SentientSystems_Include("SentientSystemsCore_ActionsGreatPeople")
SentientSystems_Include("SentientSystemsCore_ActionsGovernors")

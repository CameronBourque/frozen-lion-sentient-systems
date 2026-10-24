-- Builds one player's view of the game as JSON for the bridge, from that player's own data and
-- visibility, never from the screen. Each section of the state comes from its own file in this
-- folder, and this file puts them together. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetState(0) returns '{"cities":[{"id":65536,"name":"Rome",...}]}', on one line.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_StateCities")

-- Returns the state of the player with ID playerID as JSON. Raises an error for an ID with no
-- player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetState(playerID)).
function SentientSystems_GetState(playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	return SentientSystems_EncodeJson({ cities = SentientSystems_GetCityStates(player) })
end

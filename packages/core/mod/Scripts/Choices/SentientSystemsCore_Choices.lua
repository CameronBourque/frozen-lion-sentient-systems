-- Builds the legal options for each of one player's discrete choices as JSON for the bridge, in a
-- call of its own, so the agent reads them only when it decides. Each choice comes from its own file
-- in this folder, and this file puts them together. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetChoices(0) returns
-- '{"production":[{"city":65536,"name":"Rome","units":[...]}]}', on one line.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_ChoicesProduction")

-- Returns the choices of the player with ID playerID as JSON. Raises an error for an ID with no
-- player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetChoices(playerID)).
function SentientSystems_GetChoices(playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	return SentientSystems_EncodeJson({
		production = SentientSystems_GetProductionChoices(player),
	})
end

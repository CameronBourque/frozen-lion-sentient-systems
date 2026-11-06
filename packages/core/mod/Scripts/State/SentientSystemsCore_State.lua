-- Builds one player's view of the game as JSON, from their own data and
-- visibility, never the screen. Each section has its own file here.
-- See docs/design/core/mod/state.md. Shapes: bridge/src/state/.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_StateCities")
SentientSystems_Include("SentientSystemsCore_StateDiplomacy")
SentientSystems_Include("SentientSystemsCore_StateUnits")
SentientSystems_Include("SentientSystemsCore_StateTiles")
SentientSystems_Include("SentientSystemsCore_StateRivals")
SentientSystems_Include("SentientSystemsCore_StateBlockers")
SentientSystems_Include("SentientSystemsCore_StateReligion")
SentientSystems_Include("SentientSystemsCore_StateEnvoys")
SentientSystems_Include("SentientSystemsCore_StateGreatPeople")
SentientSystems_Include("SentientSystemsCore_StateGovernors")
SentientSystems_Include("SentientSystemsCore_StatePlayer")
SentientSystems_Include("SentientSystemsCore_StateTrade")
SentientSystems_Include("SentientSystemsCore_StateProposals")
SentientSystems_Include("SentientSystemsCore_StateScoreboard")
SentientSystems_Include("SentientSystemsCore_StateVictories")

-- Returns the state of the player with ID playerID as JSON. Raises an error for
-- an ID with no player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetState(playerID)).
function SentientSystems_GetState(playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	return SentientSystems_EncodeJson({
		blockers = SentientSystems_GetBlockerState(playerID),
		cities = SentientSystems_GetCityStates(player),
		diplomacy = SentientSystems_GetDiplomacyState(player),
		units = SentientSystems_GetUnitStates(player),
		tiles = SentientSystems_GetTileStates(playerID),
		rivals = {
			cities = SentientSystems_GetRivalCityStates(playerID),
			units = SentientSystems_GetRivalUnitStates(playerID),
		},
		religion = SentientSystems_GetReligionState(player),
		envoys = SentientSystems_GetEnvoyState(player),
		greatPeople = SentientSystems_GetGreatPeopleState(player),
		governors = SentientSystems_GetGovernorState(player),
		player = SentientSystems_GetPlayerState(player),
		trade = SentientSystems_GetTradeState(player),
		proposals = SentientSystems_GetProposalState(player),
		scoreboard = SentientSystems_GetScoreboardState(player),
		victories = SentientSystems_GetVictoryState(player),
	})
end

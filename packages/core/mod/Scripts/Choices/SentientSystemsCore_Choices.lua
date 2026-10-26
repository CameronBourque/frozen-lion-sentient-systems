-- Builds the legal options for each of one player's discrete choices as JSON for the bridge, in a
-- call of its own, so the agent reads them only when it decides. Each choice comes from its own file
-- in this folder, and this file puts them together. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetChoices(0) returns
-- '{"capturedCities":[...],"civics":[...],"envoys":{...},"government":{...},"governments":{...},
-- "greatPeople":[...],"pantheon":{...},"policies":{...},"production":[{"city":65536,"name":"Rome",
-- "units":[...]}],"purchases":[...],"techs":[...]}', on one line. A choice that the player can't make
-- now, such as the pantheon, is left out.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")

-- Returns the game's reasons from the results of a check, such as CanProduce or CanStartCommand, as
-- text. The game gives each reason as text already, and the production panel passes it through
-- Locale.Lookup, as this does. The choice files use it.
function SentientSystems_GetFailureReasons(results)
	local reasons = {}

	for i, reason in ipairs(results and results[CityCommandResults.FAILURE_REASONS] or {}) do
		reasons[i] = Locale.Lookup(reason)
	end

	return reasons
end

SentientSystems_Include("SentientSystemsCore_ChoicesProduction")
SentientSystems_Include("SentientSystemsCore_ChoicesPurchases")
SentientSystems_Include("SentientSystemsCore_ChoicesResearch")
SentientSystems_Include("SentientSystemsCore_ChoicesGovernment")
SentientSystems_Include("SentientSystemsCore_ChoicesReligion")
SentientSystems_Include("SentientSystemsCore_ChoicesEnvoys")
SentientSystems_Include("SentientSystemsCore_ChoicesGreatPeople")
SentientSystems_Include("SentientSystemsCore_ChoicesCapturedCities")

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
		purchases = SentientSystems_GetPurchaseChoices(player),
		techs = SentientSystems_GetTechChoices(player),
		civics = SentientSystems_GetCivicChoices(player),
		government = SentientSystems_GetGovernmentChoices(player),
		policies = SentientSystems_GetPolicyChoices(player),
		governments = SentientSystems_GetGovernmentOptions(player),
		pantheon = SentientSystems_GetPantheonChoices(player),
		religion = SentientSystems_GetReligionChoices(player),
		envoys = SentientSystems_GetEnvoyChoices(player),
		greatPeople = SentientSystems_GetGreatPeopleChoices(player),
		capturedCities = SentientSystems_GetCapturedCityChoices(player),
	})
end

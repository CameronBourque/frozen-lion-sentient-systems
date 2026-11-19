-- Builds the legal options for each of one player's discrete choices as JSON,
-- in a call of its own. A choice the player can't make now is left out.
-- See docs/design/core/mod/choices.md. Shapes: bridge/src/choices/

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Lookups")
SentientSystems_Include("SentientSystemsCore_Text")

SentientSystems_Include("SentientSystemsCore_ChoicesProduction")
SentientSystems_Include("SentientSystemsCore_ChoicesPurchases")
SentientSystems_Include("SentientSystemsCore_ChoicesResearch")
SentientSystems_Include("SentientSystemsCore_ChoicesGovernment")
SentientSystems_Include("SentientSystemsCore_ChoicesReligion")
SentientSystems_Include("SentientSystemsCore_ChoicesEnvoys")
SentientSystems_Include("SentientSystemsCore_ChoicesGreatPeople")
SentientSystems_Include("SentientSystemsCore_ChoicesCityFate")
SentientSystems_Include("SentientSystemsCore_ChoicesSpies")
SentientSystems_Include("SentientSystemsCore_ChoicesTradeRoutes")
SentientSystems_Include("SentientSystemsCore_ChoicesSpyMissions")
SentientSystems_Include("SentientSystemsCore_ChoicesArtifacts")
SentientSystems_Include("SentientSystemsCore_ChoicesGovernors")
SentientSystems_Include("SentientSystemsCore_ChoicesDedications")
SentientSystems_Include("SentientSystemsCore_ChoicesEmergencies")
SentientSystems_Include("SentientSystemsCore_ChoicesWorldCongress")

-- Iterates over the player's cities, in the game's order, or over only the
-- city with ID cityID when it is given. The choices with an entry for each
-- city, production and purchases, list only that city.
function SentientSystems_GetChosenCities(player, cityID)
	if cityID == nil then
		return player:GetCities():Members()
	end

	return ipairs({ player:GetCities():FindID(cityID) })
end

-- Returns the choices of the player with ID playerID as JSON. With cityID,
-- production and purchases hold only that city. Raises an error for an ID with
-- no player, or a city the player doesn't have. The bridge reads it through
-- the stash, as SentientSystems_Stash(SentientSystems_GetChoices(playerID)).
function SentientSystems_GetChoices(playerID, cityID)
	local player = SentientSystems_GetPlayer(playerID)

	if cityID ~= nil then
		local _, failure = SentientSystems_FindCity(playerID, cityID)

		if failure ~= nil then
			error(failure, 0)
		end
	end

	return SentientSystems_EncodeJson({
		production = SentientSystems_GetProductionChoices(player, cityID),
		purchases = SentientSystems_GetPurchaseChoices(player, cityID),
		techs = SentientSystems_GetTechChoices(player),
		civics = SentientSystems_GetCivicChoices(player),
		government = SentientSystems_GetGovernmentChoices(player),
		policies = SentientSystems_GetPolicyChoices(player),
		governments = SentientSystems_GetGovernmentOptions(player),
		pantheon = SentientSystems_GetPantheonChoices(player),
		religion = SentientSystems_GetReligionChoices(player),
		envoys = SentientSystems_GetEnvoyChoices(player),
		greatPeople = SentientSystems_GetGreatPeopleChoices(player),
		cityFates = SentientSystems_GetCityFateChoices(player),
		spies = SentientSystems_GetSpyChoices(player),
		tradeRoutes = SentientSystems_GetTradeRouteChoices(player),
		spyMissions = SentientSystems_GetSpyMissionChoices(player),
		artifacts = SentientSystems_GetArtifactChoices(player),
		governors = SentientSystems_GetGovernorChoices(player),
		dedications = SentientSystems_GetDedicationChoices(player),
		emergencies = SentientSystems_GetEmergencyChoices(player),
		worldCongress = SentientSystems_GetWorldCongressChoices(player),
	})
end

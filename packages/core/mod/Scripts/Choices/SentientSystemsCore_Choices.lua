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
SentientSystems_Include("SentientSystemsCore_ChoicesCapturedCities")
SentientSystems_Include("SentientSystemsCore_ChoicesSpies")
SentientSystems_Include("SentientSystemsCore_ChoicesTradeRoutes")
SentientSystems_Include("SentientSystemsCore_ChoicesSpyMissions")
SentientSystems_Include("SentientSystemsCore_ChoicesArtifacts")
SentientSystems_Include("SentientSystemsCore_ChoicesGovernors")
SentientSystems_Include("SentientSystemsCore_ChoicesDedications")
SentientSystems_Include("SentientSystemsCore_ChoicesEmergencies")
SentientSystems_Include("SentientSystemsCore_ChoicesWorldCongress")

-- Returns the choices of the player with ID playerID as JSON. Raises an error
-- for an ID with no player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetChoices(playerID)).
function SentientSystems_GetChoices(playerID)
	local player = SentientSystems_GetPlayer(playerID)

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

local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns an environment with the choices script loaded into a fake game built
-- from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env
end

describe("SentientSystems_GetChoices", function()
	it("gives each choice for a player with no cities", function()
		assert.equal("{\"civics\":[],\"government\":{\"slots\":[]},\"governments\":{\"canChange\":false,\"options\":[]},\"policies\":{\"canChange\":false},\"production\":[],\"purchases\":[],\"techs\":[]}", Load({ players = { [0] = {} } }).SentientSystems_GetChoices(0))
	end)

	it("lists only the city with the ID given in production and purchases", function()
		local env = Load({ players = { [0] = { cities = {
			{ id = 65536, name = "Rome", x = 17, y = 14, population = 3 },
			{ id = 131072, name = "Antium", x = 20, y = 14, population = 1 },
		} } } })
		local json = env.SentientSystems_GetChoices(0, 131072)

		assert.truthy(json:find("\"production\":[{\"buildings\":[],\"city\":131072,", 1, true))
		assert.truthy(json:find("\"purchases\":[{\"city\":131072,", 1, true))
		assert.is_nil(json:find("Rome", 1, true))
		assert.truthy(env.SentientSystems_GetChoices(0):find("Rome", 1, true))
	end)

	it("raises an error for a city the player doesn't have", function()
		local env = Load({ players = { [0] = {} } })

		assert.has_error(function()
			env.SentientSystems_GetChoices(0, 99)
		end, "Player 0 has no city 99.")
	end)

	it("raises an error for an ID with no player", function()
		local env = Load({ players = { [0] = {} } })

		assert.has_error(function()
			env.SentientSystems_GetChoices(5)
		end, "no player 5")
	end)

	it("loads the JSON encoder and each choice without an ERROR line, so the bridge can stash the choices", function()
		local env = Load({ players = { [0] = {} } })

		assert.same({}, env.printed)
		assert.is_function(env.SentientSystems_GetProductionChoices)
		assert.is_function(env.SentientSystems_GetPurchaseChoices)
		assert.is_function(env.SentientSystems_GetTechChoices)
		assert.is_function(env.SentientSystems_GetCivicChoices)
		assert.is_function(env.SentientSystems_GetGovernmentChoices)
		assert.is_function(env.SentientSystems_GetPolicyChoices)
		assert.is_function(env.SentientSystems_GetGovernmentOptions)
		assert.is_function(env.SentientSystems_GetPantheonChoices)
		assert.is_function(env.SentientSystems_GetReligionChoices)
		assert.is_function(env.SentientSystems_GetEnvoyChoices)
		assert.is_function(env.SentientSystems_GetGreatPeopleChoices)
		assert.is_function(env.SentientSystems_GetCityFateChoices)
		assert.is_function(env.SentientSystems_GetSpyChoices)
		assert.is_function(env.SentientSystems_GetTradeRouteChoices)
		assert.is_function(env.SentientSystems_GetSpyMissionChoices)
		assert.is_function(env.SentientSystems_GetArtifactChoices)
		assert.is_function(env.SentientSystems_GetGovernorChoices)
		assert.is_function(env.SentientSystems_GetDedicationChoices)
		assert.is_function(env.SentientSystems_GetEmergencyChoices)
		assert.is_function(env.SentientSystems_GetWorldCongressChoices)
		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_GetChoices(0)))
	end)
end)

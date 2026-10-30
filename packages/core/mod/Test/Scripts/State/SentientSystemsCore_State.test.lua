local FakeGame = require("FakeGame")
local Game = require("Game")

-- The scoreboard of a world with one player, ID 0, who has not met anyone.
local SCOREBOARD = "[{\"categories\":[{\"name\":\"LOC_CATEGORY_CIVICS_NAME\",\"score\":0,\"type\":\"CATEGORY_CIVICS\"},{\"name\":\"LOC_CATEGORY_EMPIRE_NAME\",\"score\":0,\"type\":\"CATEGORY_EMPIRE\"},{\"name\":\"LOC_CATEGORY_GREAT_PEOPLE_NAME\",\"score\":0,\"type\":\"CATEGORY_GREAT_PEOPLE\"},{\"name\":\"LOC_CATEGORY_RELIGION_NAME\",\"score\":0,\"type\":\"CATEGORY_RELIGION\"},{\"name\":\"LOC_CATEGORY_TECH_NAME\",\"score\":0,\"type\":\"CATEGORY_TECH\"},{\"name\":\"LOC_CATEGORY_WONDER_NAME\",\"score\":0,\"type\":\"CATEGORY_WONDER\"},{\"name\":\"LOC_CATEGORY_ERA_SCORE_NAME\",\"score\":0,\"type\":\"CATEGORY_ERA_SCORE\"}],\"culture\":0,\"faith\":0,\"gold\":0,\"military\":0,\"player\":0,\"science\":0,\"score\":0}]"

-- Returns an environment with the state script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env
end

-- The victories of a world with one player, ID 0, who has not met anyone.
local VICTORIES = "{\"culture\":[{\"culturePerTurn\":0,\"player\":0,\"progress\":0,\"tourismPerTurn\":0}],\"domination\":[{\"military\":0,\"player\":0,\"progress\":0}],\"religion\":[{\"cities\":0,\"faithPerTurn\":0,\"player\":0,\"progress\":0}],\"science\":[{\"player\":0,\"progress\":0,\"sciencePerTurn\":0,\"stages\":[{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"district\",\"type\":\"DISTRICT_SPACEPORT\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_EARTH_SATELLITE\"}]},{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MOON_LANDING\"}]},{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_REACTOR\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HABITATION\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HYDROPONICS\"}]}],\"techs\":0}]}"

describe("SentientSystems_GetState", function()
	it("gives empty lists for a player with no blockers, cities, tiles, or units", function()
		local env = Load({ players = { [0] = {} } })

		assert.equal("{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[],\"diplomacy\":[],\"envoys\":{\"cityStates\":[],\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0},\"greatPeople\":[],\"player\":{\"culture\":0,\"faith\":{\"balance\":0,\"perTurn\":0},\"gold\":{\"balance\":0,\"perTurn\":0},\"income\":{\"cities\":[],\"culture\":{\"total\":0},\"deals\":[],\"expenses\":{\"cities\":0,\"deals\":0,\"total\":0,\"units\":0},\"faith\":{\"total\":0},\"gold\":{\"total\":0},\"science\":{\"total\":0},\"unitUpkeep\":[]},\"resources\":[],\"science\":0,\"tourism\":0},\"proposals\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"scoreboard\":" .. SCOREBOARD .. ",\"tiles\":[],\"units\":[],\"victories\":" .. VICTORIES .. "}", env.SentientSystems_GetState(0))
	end)

	it("raises an error for an ID with no player", function()
		local env = Load({ players = { [0] = {} } })

		assert.has_error(function()
			env.SentientSystems_GetState(5)
		end, "no player 5")
	end)

	it("loads the JSON encoder, so the bridge can stash the state", function()
		local env = Load({ players = { [0] = {} } })

		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_GetState(0)))
	end)

	it("loads each section without an ERROR line", function()
		local env = Load({ players = { [0] = {} } })

		assert.same({}, env.printed)
		assert.is_function(env.SentientSystems_GetBlockerState)
		assert.is_function(env.SentientSystems_GetCityStates)
		assert.is_function(env.SentientSystems_GetUnitStates)
		assert.is_function(env.SentientSystems_GetTileStates)
		assert.is_function(env.SentientSystems_GetRivalCityStates)
		assert.is_function(env.SentientSystems_GetRivalUnitStates)
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns an environment with the state script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env
end

describe("SentientSystems_GetState", function()
	it("gives empty lists for a player with no blockers, cities, tiles, or units", function()
		local env = Load({ players = { [0] = {} } })

		assert.equal("{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[],\"envoys\":{\"cityStates\":[],\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0},\"greatPeople\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"tiles\":[],\"units\":[]}", env.SentientSystems_GetState(0))
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

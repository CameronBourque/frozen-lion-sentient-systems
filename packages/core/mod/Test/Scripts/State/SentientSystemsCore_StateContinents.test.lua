local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the continents JSON in the state for player 0, in a world with the
-- given continents.
local function ContinentsFor(continents)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = {} }, continents = continents })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"continents\":(%b[])")
end

describe("SentientSystems_GetContinentStates", function()
	it("lists each continent with its index, type, and name", function()
		assert.equal(
			"[{\"index\":3,\"name\":\"LOC_CONTINENT_PANGAEA_DESCRIPTION\",\"type\":\"CONTINENT_PANGAEA\"},"
				.. "{\"index\":10,\"name\":\"LOC_CONTINENT_MU_DESCRIPTION\",\"type\":\"CONTINENT_MU\"}]",
			ContinentsFor({ { index = 3, type = "CONTINENT_PANGAEA" }, { index = 10, type = "CONTINENT_MU" } })
		)
	end)

	it("leaves out a continent that the player has revealed none of", function()
		assert.equal(
			"[{\"index\":10,\"name\":\"LOC_CONTINENT_MU_DESCRIPTION\",\"type\":\"CONTINENT_MU\"}]",
			ContinentsFor({ { index = 3, type = "CONTINENT_PANGAEA", hidden = true }, { index = 10, type = "CONTINENT_MU" } })
		)
	end)

	it("is an empty list for a map with no continents", function()
		assert.equal("[]", ContinentsFor({}))
	end)
end)

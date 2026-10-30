local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the resources section JSON for player 0, whose data is given, in a game with the rest of
-- world, with Gathering Storm when it has expansion2.
local function ResourcesWith(data, world)
	local env = Game.new()
	local setup = { players = { [0] = data, [4] = {} }, turn = 85, text = { LOC_CITY_NAME_ROME = "Rome" } }

	for key, value in pairs(world or {}) do
		setup[key] = value
	end

	FakeGame.Install(env, setup)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"resources\":(%b[])")
end

local ROME = { id = 1, name = "LOC_CITY_NAME_ROME", population = 1 }

describe("SentientSystems_GetResourcesState", function()
	local gatheringStorm = {
		cities = { ROME, { id = 2, name = "LOC_CITY_NAME_ANTIUM", population = 1 } },
		resources = {
			{ type = "RESOURCE_IRON", class = "strategic", amount = 40, cap = 105, unitDemand = 2, powerDemand = 1, reserved = 3, imported = 1, perTurn = 4, cities = { [1] = 2 } },
			{ type = "RESOURCE_ALUMINUM", class = "strategic", amount = 105, cap = 105 },
			{ type = "RESOURCE_COAL", class = "strategic", cap = 105 },
			{ type = "RESOURCE_TURTLES", class = "luxury", amount = 3, cities = { [1] = 1 }, allocation = { [2] = 1, [1] = 2 } },
			{ type = "RESOURCE_CRABS", class = "bonus", amount = 3, cities = { [1] = 1 } },
			{ type = "RESOURCE_RELIC", class = "artifact", amount = 2 },
		},
		deals = {
			{ player = 4, resource = "RESOURCE_TURTLES", amount = 1, duration = 30, enacted = 70, outgoing = true },
			{ player = 4, resource = "RESOURCE_IRON", amount = 2, duration = 10, enacted = 80 },
			{ player = 4, resource = "RESOURCE_IRON", amount = 9, duration = 0, enacted = 80 },
			{ player = 4, gold = 7, duration = 10, enacted = 80 },
		},
	}

	-- A city-state that the player is Suzerain of, which sends a crab.
	local cityState = { minor = { name = "Kumasi", suzerain = 0, resources = { { type = "RESOURCE_CRABS", exported = 1 } } } }

	it("lists each strategic resource's sources, per turn, and its stockpile with Gathering Storm", function()
		local json = ResourcesWith(gatheringStorm, { expansion2 = true })

		assert.truthy(json:find("{\"class\":\"strategic\",\"max\":105,\"name\":\"LOC_RESOURCE_IRON_NAME\",\"perTurn\":1,\"sources\":["
			.. "{\"amount\":2,\"city\":{\"id\":1,\"owner\":0},\"kind\":\"city\",\"name\":\"Rome\"},"
			.. "{\"amount\":2,\"kind\":\"deal\",\"player\":4,\"turnsLeft\":5},"
			.. "{\"amount\":-2,\"kind\":\"units\"},{\"amount\":-1,\"kind\":\"power\"},{\"amount\":-3,\"kind\":\"reserve\"},"
			.. "{\"amount\":1,\"kind\":\"cityStates\"},{\"amount\":2,\"kind\":\"other\"}],\"stockpile\":40,\"type\":\"RESOURCE_IRON\"}", 1, true))
		assert.truthy(json:find("\"name\":\"LOC_RESOURCE_ALUMINUM_NAME\",\"perTurn\":105,\"sources\":[{\"amount\":105,\"kind\":\"other\"}],\"stockpile\":105,", 1, true))
	end)

	it("leaves out a resource with no stockpile and no source, and an artifact", function()
		local json = ResourcesWith(gatheringStorm, { expansion2 = true })

		assert.falsy(json:find("COAL", 1, true))
		assert.falsy(json:find("RELIC", 1, true))
	end)

	it("lists a luxury's exports with the turns left, what the game holds beyond them, and its cities", function()
		local json = ResourcesWith(gatheringStorm, { expansion2 = true })

		assert.truthy(json:find("{\"cities\":[{\"amount\":2,\"city\":{\"id\":1,\"owner\":0}},{\"amount\":1,\"city\":{\"id\":2,\"owner\":0}}],\"class\":\"luxury\","
			.. "\"name\":\"LOC_RESOURCE_TURTLES_NAME\",\"sources\":[{\"amount\":1,\"city\":{\"id\":1,\"owner\":0},\"kind\":\"city\",\"name\":\"Rome\"},"
			.. "{\"amount\":-1,\"kind\":\"deal\",\"player\":4,\"turnsLeft\":15},{\"amount\":3,\"kind\":\"other\"}],\"total\":3,\"type\":\"RESOURCE_TURTLES\"}", 1, true))
	end)

	it("lists what the city-states the player is Suzerain of send", function()
		local data = {}

		for key, value in pairs(gatheringStorm) do
			data[key] = value
		end

		local json = ResourcesWith(data, { expansion2 = true, players = { [0] = data, [4] = {}, [5] = cityState } })

		assert.truthy(json:find("{\"amount\":1,\"kind\":\"suzerain\",\"player\":5},{\"amount\":1,\"kind\":\"other\"}],\"total\":3,\"type\":\"RESOURCE_CRABS\"}", 1, true))
	end)

	it("counts the extractable resource tiles of each city, and the amount the player has, without Gathering Storm", function()
		local json = ResourcesWith({
			cities = {
				{
					id = 1,
					name = "LOC_CITY_NAME_ROME",
					population = 1,
					tiles = {
						{ x = 1, y = 1, resource = "RESOURCE_IRON", extractable = true },
						{ x = 2, y = 1, resource = "RESOURCE_IRON" },
						{ x = 3, y = 1, resource = "RESOURCE_CRABS", extractable = true },
						{ x = 4, y = 1 },
					},
				},
			},
			resources = {
				{ type = "RESOURCE_IRON", class = "strategic", amount = 4 },
				{ type = "RESOURCE_CRABS", class = "bonus", amount = 1 },
			},
		})

		assert.equal("[{\"class\":\"strategic\",\"name\":\"LOC_RESOURCE_IRON_NAME\",\"sources\":[{\"amount\":1,\"city\":{\"id\":1,\"owner\":0},\"kind\":\"city\",\"name\":\"Rome\"},"
			.. "{\"amount\":3,\"kind\":\"other\"}],\"total\":4,\"type\":\"RESOURCE_IRON\"},"
			.. "{\"class\":\"bonus\",\"name\":\"LOC_RESOURCE_CRABS_NAME\",\"sources\":[{\"amount\":1,\"city\":{\"id\":1,\"owner\":0},\"kind\":\"city\",\"name\":\"Rome\"}],"
			.. "\"total\":1,\"type\":\"RESOURCE_CRABS\"}]", json)
	end)

	it("is empty for a player with no resources", function()
		assert.equal("[]", ResourcesWith({}))
	end)
end)

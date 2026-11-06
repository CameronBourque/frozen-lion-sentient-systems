local FakeGame = require("FakeGame")
local Game = require("Game")

local GAIN_SOURCES = "UNITOPERATION_SPY_GAIN_SOURCES"

-- A spy unit of player 0 at x, y with the spy data it adds.
local function Spy(id, x, y, extra)
	local spy = { name = "Jakob", level = 2, ops = { [GAIN_SOURCES] = { turns = 4 } } }

	for key, value in pairs(extra or {}) do
		spy[key] = value
	end

	return { id = id, type = "UNIT_SPY", x = x, y = y, spy = spy }
end

-- Returns the espionage section JSON for player 0, who has the data given, in a
-- world with a city of player 1 at 20, 10 that owns the tile 21, 10.
local function EspionageWith(player, others)
	local env = Game.new()
	local players = { [0] = player, [1] = { cities = { { id = 1, name = "Rome", x = 20, y = 10, population = 5, ownedTiles = { { x = 21, y = 10 } } } } } }

	for id, data in pairs(others or {}) do
		players[id] = data
	end

	FakeGame.Install(env, {
		players = players,
		turn = 50,
		text = { LOC_ESPIONAGE_LEVEL_1_NAME = "Recruit", LOC_ESPIONAGE_LEVEL_2_NAME = "Agent", LOC_UNITOPERATION_SPY_GAIN_SOURCES_DESCRIPTION = "Gain Sources" },
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"espionage\":(%b{})")
end

describe("SentientSystems_GetEspionageState", function()
	it("gives an idle spy with its rank and the city whose land it stands in", function()
		assert.equal(
			"{\"capacity\":3,\"operatives\":[{\"city\":{\"id\":1,\"name\":\"Rome\",\"owner\":1},\"id\":7,\"level\":2,\"name\":\"Jakob\","
				.. "\"rank\":\"Agent\",\"status\":\"idle\"}]}",
			EspionageWith({ spyCapacity = 3, units = { Spy(7, 21, 10) } })
		)
	end)

	it("gives a spy on a mission with its operation and the turns left, after the idle spies", function()
		local mission = Spy(8, 21, 10, { operation = GAIN_SOURCES, endTurn = 52, level = 1 })
		local json = EspionageWith({ spyCapacity = 3, units = { mission, Spy(7, 21, 10) } })

		assert.truthy(json:find("\"operation\":{\"name\":\"Gain Sources\",\"totalTurns\":4,\"turnsLeft\":2,\"type\":\"UNITOPERATION_SPY_GAIN_SOURCES\"}", 1, true))
		assert.truthy(json:find("\"status\":\"idle\".-\"status\":\"mission\""))
	end)

	it("gives no turns left below 0 for a mission that is overdue", function()
		local json = EspionageWith({ units = { Spy(8, 21, 10, { operation = GAIN_SOURCES, endTurn = 40 }) } })

		assert.truthy(json:find("\"turnsLeft\":0,", 1, true))
	end)

	it("gives a spy held by another player with the index a deal uses", function()
		local json = EspionageWith({}, { [1] = { captured = { { owner = 0, name = "Mata", level = 1, index = 5 }, { owner = 2, name = "Other", level = 1, index = 6 } } } })

		assert.truthy(json:find("{\"captive\":5,\"capturedBy\":1,\"level\":1,\"name\":\"Mata\",\"rank\":\"Recruit\",\"status\":\"captured\"}", 1, true))
		assert.falsy(json:find("Other", 1, true))
	end)

	it("gives a traveling spy with its destination and the turns until it arrives, and skips one that has arrived", function()
		local json = EspionageWith({
			traveling = {
				{ name = "Axro", level = 1, x = 21, y = 10, returnTurn = 52 },
				{ name = "Done", level = 1, x = 21, y = 10, returnTurn = -1 },
			},
		})

		assert.equal(
			"{\"capacity\":0,\"operatives\":[{\"city\":{\"id\":1,\"name\":\"Rome\",\"owner\":1},\"level\":1,\"name\":\"Axro\","
				.. "\"rank\":\"Recruit\",\"status\":\"traveling\",\"turnsLeft\":2}]}",
			json
		)
	end)

	it("lists the idle and active spies, then the captured, then the traveling", function()
		local json = EspionageWith(
			{ traveling = { { name = "Axro", level = 1, x = 21, y = 10, returnTurn = 52 } }, units = { Spy(7, 21, 10) } },
			{ [1] = { captured = { { owner = 0, name = "Mata", level = 1, index = 5 } } } }
		)

		assert.truthy(json:find("idle.-captured.-traveling"))
	end)

	it("is empty with no spies", function()
		assert.equal("{\"capacity\":0,\"operatives\":[]}", EspionageWith({}))
	end)
end)

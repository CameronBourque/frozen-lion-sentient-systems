local FakeGame = require("FakeGame")
local Game = require("Game")

-- A spy of player 0's escaping from Istanbul, player 4's city at 84, 34.
local SPY = { id = 2555922, name = "LOC_CITIZEN_ROME_FEMALE_3", loot = "LOC_ESPIONAGE_LOOT_NONE", pursuer = "", x = 84, y = 34 }

-- Returns the spy choice JSON for player 0, or nil when it is left out, with the spy given,
-- Istanbul's districts, and the player's blockers, the escape route blocker when missing.
local function ChoicesWith(spy, districts, blockers)
	local env = Game.new()
	local istanbul = { id = 65536, name = "LOC_CITY_NAME_ISTANBUL", x = 84, y = 34, population = 5, districts = districts }

	FakeGame.Install(env, {
		players = { [0] = { escapingSpy = spy, blockers = blockers or { "ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE" } }, [4] = { cities = { istanbul } } },
		text = { LOC_CITIZEN_ROME_FEMALE_3 = "Laurenza", LOC_CITY_NAME_ISTANBUL = "Istanbul", LOC_ESPIONAGE_ESCAPE_CHOICE_4 = "Foot" },
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"spies\":(%b[])")
end

describe("SentientSystems_GetSpyChoices", function()
	it("gives the escaping spy with its city, loot, pursuer, and the routes the city's districts allow", function()
		assert.equal(
			"[{\"city\":{\"id\":65536,\"name\":\"Istanbul\",\"owner\":4},\"description\":\"LOC_ESPIONAGE_ESCAPE_TOOLTIP\",\"loot\":\"LOC_ESPIONAGE_LOOT_NONE\","
				.. "\"name\":\"Laurenza\",\"pursuer\":\"LOC_ESPIONAGE_ESCAPE_PURSUIT_POLICE\",\"routes\":["
				.. "{\"blocked\":[\"LOC_ESPIONAGE_ESCAPE_NO_DISTRICT(LOC_DISTRICT_AERODROME_NAME)\"],\"name\":\"LOC_ESPIONAGE_ESCAPE_CHOICE_1\",\"type\":\"DISTRICT_AERODROME\"},"
				.. "{\"name\":\"LOC_ESPIONAGE_ESCAPE_CHOICE_2\",\"turns\":2,\"type\":\"DISTRICT_HARBOR\"},"
				.. "{\"blocked\":[\"LOC_ESPIONAGE_ESCAPE_NO_DISTRICT(LOC_DISTRICT_COMMERCIAL_HUB_NAME)\"],\"name\":\"LOC_ESPIONAGE_ESCAPE_CHOICE_3\",\"type\":\"DISTRICT_COMMERCIAL_HUB\"},"
				.. "{\"name\":\"Foot\",\"turns\":4,\"type\":\"DISTRICT_CITY_CENTER\"}],\"spy\":2555922}]",
			ChoicesWith(SPY, { { type = "DISTRICT_HARBOR", x = 85, y = 34 } })
		)
	end)

	it("names the counterspy who pursues the spy", function()
		local spy = { id = SPY.id, name = SPY.name, loot = SPY.loot, pursuer = "Bob", x = SPY.x, y = SPY.y }

		assert.truthy(ChoicesWith(spy):find("\"pursuer\":\"LOC_ESPIONAGE_ESCAPE_PURSUIT_COUNTERSPY(Bob)\"", 1, true))
	end)

	it("is left out with no escaping spy", function()
		assert.is_nil(ChoicesWith(nil))
	end)

	it("reads the spy for a dragnet priority, and not at all without a spy blocker", function()
		assert.truthy(ChoicesWith(SPY, nil, { "ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY" }))
		assert.is_nil(ChoicesWith(SPY, nil, {}))
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- A city of player 1's, so a player that keeps it isn't wiped out.
local OTHER_CITY = { id = 65536, name = "Uruk", x = 10, y = 10, population = 3 }

-- Returns a city player 0 captured from player 1, who founded it, with the fields in extra.
local function Captured(extra)
	local city = { id = 131073, name = "LOC_CITY_NAME_CAGUANA", x = 47, y = 40, population = 1, originalOwner = 1, ownerBefore = 1, conqueredFrom = 1, warmonger = { keep = 50, raze = 100 } }

	for key, value in pairs(extra or {}) do
		city[key] = value
	end

	return city
end

-- Returns the captured city choice JSON for player 0, whose data is given, or nil when it is left
-- out, in a world with player 1 as given and the world fields in extra.
local function ChoicesWith(player, other, extra)
	local env = Game.new()
	local world = { players = { [0] = player, [1] = other or { cities = { OTHER_CITY } } }, text = { LOC_CITY_NAME_CAGUANA = "Caguana" } }

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"capturedCities\":(%b[])")
end

-- Returns the options JSON of the first city in a captured city choice.
local function Options(json)
	return json:match("\"options\":(%b[])")
end

describe("SentientSystems_GetCapturedCityChoices", function()
	it("gives the captured city with keep and raze, each with the warmonger level its tooltip names", function()
		assert.equal(
			"[{\"city\":131073,\"districts\":2,\"kind\":\"captured\",\"name\":\"Caguana\",\"options\":["
				.. "{\"description\":\"LOC_RAZE_CITY_KEEP_EXPLANATION(LOC_RAZE_CITY_KEEP_WARMONGER_EXPLANATION(LOC_WARMONGER_LEVEL_-50))\",\"type\":\"KEEP\"},"
				.. "{\"description\":\"LOC_RAZE_CITY_RAZE_EXPLANATION(LOC_RAZE_CITY_RAZE_WARMONGER_EXPLANATION(LOC_WARMONGER_LEVEL_-100))\",\"type\":\"RAZE\"}],"
				.. "\"population\":1,\"x\":47,\"y\":40}]",
			ChoicesWith({ captured = Captured({ districts = 2 }) })
		)
	end)

	it("words the tooltips for the last city of the player it was taken from", function()
		assert.equal(
			"[{\"description\":\"LOC_RAZE_CITY_KEEP_LAST_CITY_EXPLANATION\",\"type\":\"KEEP\"},{\"description\":\"LOC_RAZE_CITY_RAZE_LAST_CITY_EXPLANATION\",\"type\":\"RAZE\"}]",
			Options(ChoicesWith({ captured = Captured() }, {}))
		)
	end)

	it("gives grievances with Gathering Storm, doubled for keeping a player's last city", function()
		assert.equal(
			"[{\"description\":\"LOC_RAZE_CITY_KEEP_EXPLANATION(LOC_XP2_RAZE_CITY_KEEP_WARMONGER_EXPLANATION(50))\",\"type\":\"KEEP\"},"
				.. "{\"description\":\"LOC_RAZE_CITY_RAZE_EXPLANATION(LOC_XP2_RAZE_CITY_RAZE_WARMONGER_EXPLANATION(100))\",\"type\":\"RAZE\"}]",
			Options(ChoicesWith({ captured = Captured() }, nil, { expansion2 = true }))
		)
		assert.equal(
			"[{\"description\":\"LOC_XP2_RAZE_CITY_KEEP_LAST_CITY_EXPLANATION(100)\",\"type\":\"KEEP\"},{\"description\":\"LOC_XP2_RAZE_CITY_RAZE_LAST_CITY_EXPLANATION(100)\",\"type\":\"RAZE\"}]",
			Options(ChoicesWith({ captured = Captured() }, {}, { expansion2 = true }))
		)
	end)

	it("words keeping a gifted city and a Free City, and blocks razing a city the player can't raze", function()
		assert.equal(
			"[{\"description\":\"LOC_RAZE_CITY_KEEP_EXPLANATION_TRADED\",\"type\":\"KEEP\"},{\"blocked\":[\"LOC_RAZE_CITY_RAZE_DISABLED_EXPLANATION\"],\"type\":\"RAZE\"}]",
			Options(ChoicesWith({ captured = Captured({ gift = true, canRaze = false }) }))
		)
		assert.equal(
			"[{\"description\":\"LOC_XP2_RAZE_CITY_KEEP_FREE_CITY_EXPLANATION\",\"type\":\"KEEP\"},{\"description\":\"LOC_XP2_RAZE_CITY_RAZE_FREE_CITY_EXPLANATION\",\"type\":\"RAZE\"}]",
			Options(ChoicesWith({ captured = Captured() }, { cities = { OTHER_CITY }, freeCities = true }, { expansion2 = true }))
		)
	end)

	it("offers to liberate the city to its founder and to its owner before the war", function()
		local city = Captured({ originalOwner = 2, ownerBefore = 1, conqueredFrom = 3 })
		local players = { captured = city, liberate = { 1, 2 } }
		local liberate = "LOC_RAZE_CITY_LIBERATE_EXPLANATION(LOC_RAZE_CITY_LIBERATE_WARMONGER_EXPLANATION)"

		assert.truthy(Options(ChoicesWith(players, nil, { players = { [0] = players, [1] = {}, [2] = { cities = { OTHER_CITY } }, [3] = {} } })):find(
			"[{\"description\":\"" .. liberate .. "\",\"player\":2,\"type\":\"LIBERATE_FOUNDER\"},{\"description\":\"" .. liberate .. "\",\"player\":1,\"type\":\"LIBERATE_PREVIOUS_OWNER\"},",
			1,
			true
		))
	end)

	it("leaves out liberating to the player it was taken from, or to one the player can't liberate to", function()
		local json = Options(ChoicesWith({ captured = Captured({ originalOwner = 2 }), liberate = { 1 } }, nil, { players = { [0] = { captured = Captured({ originalOwner = 2 }), liberate = { 1 } }, [1] = {}, [2] = { cities = { OTHER_CITY } } } }))

		assert.falsy(json:find("LIBERATE", 1, true))
	end)

	it("gives the favor for liberating with Gathering Storm, with more for bringing a player back", function()
		local function Favor(players)
			return ChoicesWith(players[0], nil, { players = players, expansion2 = true }):match("LIBERATE_WARMONGER_EXPLANATION%((%d+)%)")
		end

		local city = Captured({ originalOwner = 2, ownerBefore = 1, conqueredFrom = 3 })

		assert.equal("100", Favor({ [0] = { captured = city, liberate = { 2 } }, [1] = {}, [2] = { cities = { OTHER_CITY } }, [3] = {} }))
		assert.equal("120", Favor({ [0] = { captured = city, liberate = { 2 } }, [1] = {}, [2] = {}, [3] = {} }))
		assert.equal("100", Favor({ [0] = { captured = city, liberate = { 2 }, revived = { 2 } }, [1] = {}, [2] = {}, [3] = {} }))
		assert.equal("50", Favor({ [0] = { captured = city, liberate = { 2 } }, [1] = {}, [2] = { minor = {} }, [3] = {} }))
	end)

	it("gives the city that rebelled to join the player, with keep and refuse", function()
		local rebelled = { id = 196610, name = "Kish", x = 5, y = 6, population = 4, districts = 1 }

		assert.equal(
			"[{\"city\":196610,\"districts\":1,\"kind\":\"disloyal\",\"name\":\"Kish\",\"options\":["
				.. "{\"description\":\"LOC_DISLOYAL_CITY_CHOOSER_KEEP_EXPLANATION\",\"type\":\"KEEP\"},{\"description\":\"LOC_DISLOYAL_CITY_CHOOSER_REFUSE_EXPLANATION\",\"type\":\"REJECT\"}],"
				.. "\"population\":4,\"x\":5,\"y\":6}]",
			ChoicesWith({ rebelled = rebelled })
		)
		assert.is_nil(ChoicesWith({ rebelled = rebelled, noRiseAndFall = true }))
	end)

	it("gives the captured city before the rebelled one, and is left out with neither", function()
		local json = ChoicesWith({ captured = Captured(), rebelled = { id = 196610, name = "Kish", x = 5, y = 6, population = 4 } })

		assert.truthy(json:find("\"kind\":\"captured\".*\"kind\":\"disloyal\""))
		assert.is_nil(ChoicesWith({}))
	end)
end)

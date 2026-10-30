local FakeGame = require("FakeGame")
local Game = require("Game")

local CITIES = {
	{ id = 65536, name = "Rome", x = 1, y = 1, population = 5, capital = true },
	{ id = 131073, name = "Antium", x = 2, y = 2, population = 3 },
	{ id = 393221, name = "Ostia", x = 3, y = 3, population = 4 },
}

-- Reyna, established in Ostia, who can be promoted to Harbormaster but not yet to Tax Collector.
local REYNA = {
	type = "GOVERNOR_THE_MERCHANT",
	city = { owner = 0, id = 393221 },
	established = true,
	canPromote = true,
	promotions = {
		{ type = "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION", has = true },
		{ type = "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER", canEarn = true },
		{ type = "GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR" },
	},
}

-- Returns the governor choice JSON for player 0, whose governors are given, or nil when it is left
-- out. options has met, the IDs player 0 has met, players, more players by ID, and world, more fields
-- of the world.
local function ChoicesWith(governors, options)
	options = options or {}

	local env = Game.new()
	local players = { [0] = { governors = governors, cities = CITIES, met = options.met } }
	local world = { players = players }

	for id, data in pairs(options.players or {}) do
		players[id] = data
	end

	for key, value in pairs(options.world or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"governors\":(%b{})")
end

-- Returns the JSON of a card with the key the fake game gives each text.
local function Card(type, turns)
	return "{\"description\":\"LOC_" .. type .. "_DESCRIPTION\",\"loyalty\":8,\"name\":\"LOC_" .. type .. "_NAME\",\"title\":\"LOC_" .. type
		.. "_TITLE\",\"turnsToEstablish\":" .. turns .. ",\"type\":\"" .. type .. "\"}"
end

describe("SentientSystems_GetGovernorChoices", function()
	it("offers the governors the player can appoint, with their cards, and none they never can", function()
		local governors = {
			points = 9,
			spent = 8,
			appointed = { REYNA },
			candidates = { { type = "GOVERNOR_THE_DEFENDER", turnsToEstablish = 3 }, { type = "GOVERNOR_THE_AMBASSADOR" }, { type = "GOVERNOR_IBRAHIM", canEver = false } },
		}

		assert.equal(
			"[" .. Card("GOVERNOR_THE_DEFENDER", 3) .. "," .. Card("GOVERNOR_THE_AMBASSADOR", 5) .. "]",
			ChoicesWith(governors):match("\"appoint\":(%b[])")
		)
	end)

	it("offers no appointment without a title to spend", function()
		local json = ChoicesWith({ canAppoint = false, appointed = { REYNA }, candidates = { { type = "GOVERNOR_THE_DEFENDER" } } })

		assert.falsy(json:find("\"appoint\"", 1, true))
		assert.truthy(json:find("\"assign\"", 1, true))
	end)

	it("offers the promotions a governor can earn now, and none they hold or can't reach", function()
		assert.equal(
			"[{\"governor\":\"GOVERNOR_THE_MERCHANT\",\"promotions\":[{\"description\":\"LOC_GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER_DESCRIPTION\","
				.. "\"name\":\"LOC_GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER_NAME\",\"type\":\"GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER\"}]}]",
			ChoicesWith({ appointed = { REYNA } }):match("\"promote\":(%b[])")
		)
	end)

	it("leaves out a governor the player can't promote, and one with no promotion to earn", function()
		local blocked = { type = REYNA.type, city = REYNA.city, canPromote = false, promotions = REYNA.promotions }
		local nothing = { type = "GOVERNOR_THE_EDUCATOR", city = REYNA.city, canPromote = true, promotions = { { type = "GOVERNOR_PROMOTION_EDUCATOR_LIBRARIAN", has = true } } }

		assert.falsy(ChoicesWith({ appointed = { blocked, nothing } }):find("\"promote\"", 1, true))
	end)

	it("offers each of the player's cities but the one the governor is in, and all of them to one with none", function()
		local unassigned = { type = "GOVERNOR_THE_EDUCATOR" }

		assert.equal(
			"[{\"cities\":[{\"id\":65536,\"name\":\"Rome\",\"owner\":0},{\"id\":131073,\"name\":\"Antium\",\"owner\":0}],\"governor\":\"GOVERNOR_THE_MERCHANT\"},"
				.. "{\"cities\":[{\"id\":65536,\"name\":\"Rome\",\"owner\":0},{\"id\":131073,\"name\":\"Antium\",\"owner\":0},{\"id\":393221,\"name\":\"Ostia\",\"owner\":0}],"
				.. "\"governor\":\"GOVERNOR_THE_EDUCATOR\"}]",
			ChoicesWith({ appointed = { REYNA, unassigned } }):match("\"assign\":(%b[])")
		)
	end)

	it("offers no assignment for a neutralized governor", function()
		local neutralized = { type = REYNA.type, city = REYNA.city, neutralized = 3 }

		assert.is_nil(ChoicesWith({ appointed = { neutralized } }))
	end)

	it("offers an Ambassador the cities of the city-states met, and a governor sent abroad the capitals met, with the game's reasons", function()
		local ambassador = { type = "GOVERNOR_THE_AMBASSADOR", city = { owner = 0, id = 65536 }, cityStates = true, abroad = true }
		local players = {
			[1] = { cities = { { id = 65536, name = "Roma", x = 5, y = 5, population = 3, capital = true } } },
			[12] = { minor = {}, cities = { { id = 65536, name = "Samarkand", x = 6, y = 6, population = 1 } } },
			[13] = { minor = {}, cities = { { id = 65536, name = "Cahokia", x = 7, y = 7, population = 1 } } },
			[62] = { minor = { cantReceive = true }, cities = { { id = 65536, name = "Free", x = 8, y = 8, population = 1 } } },
		}
		local governors = { appointed = { ambassador }, cannotAssignTo = { ["1:65536"] = { "LOC_AT_WAR" } } }

		assert.equal(
			"[{\"cities\":[{\"id\":131073,\"name\":\"Antium\",\"owner\":0},{\"id\":393221,\"name\":\"Ostia\",\"owner\":0},{\"id\":65536,\"name\":\"Samarkand\",\"owner\":12},"
				.. "{\"blocked\":[\"LOC_AT_WAR\"],\"id\":65536,\"name\":\"Roma\",\"owner\":1}],\"governor\":\"GOVERNOR_THE_AMBASSADOR\"}]",
			ChoicesWith(governors, { met = { 1, 12, 62 }, players = players }):match("\"assign\":(%b[])")
		)
	end)

	it("offers a Secret Society the player has discovered, with no loyalty or turns, and none they haven't", function()
		local owls = { type = "GOVERNOR_OWLS_OF_MINERVA" }
		local hidden = { type = "GOVERNOR_HERMETIC_ORDER", canEver = false }
		local json = ChoicesWith({ candidates = { owls, hidden, { type = "GOVERNOR_THE_DEFENDER", turnsToEstablish = 3 } } }, { world = { cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA", "GOVERNOR_HERMETIC_ORDER" } } })

		assert.equal(
			"[{\"description\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_DESCRIPTION\",\"name\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_NAME\",\"secret\":true,"
				.. "\"title\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_TITLE\",\"type\":\"GOVERNOR_OWLS_OF_MINERVA\"}," .. Card("GOVERNOR_THE_DEFENDER", 3) .. "]",
			json:match("\"appoint\":(%b[])")
		)
	end)

	it("offers a joined Secret Society the promotions it can earn, with the game's text for a hidden one", function()
		local owls = {
			type = "GOVERNOR_OWLS_OF_MINERVA",
			canPromote = true,
			promotions = {
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", base = true, has = true },
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2", requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1" }, hiddenWithoutPrereqs = true, canEarn = true },
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3", requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2" }, hiddenWithoutPrereqs = true, canEarn = true },
			},
		}
		local json = ChoicesWith({ appointed = { owls } }, {
			world = {
				cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" },
				text = { LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME = "???", LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION = "Not yet revealed." },
			},
		})

		assert.equal(
			"[{\"governor\":\"GOVERNOR_OWLS_OF_MINERVA\",\"promotions\":["
				.. "{\"description\":\"LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_DESCRIPTION\",\"name\":\"LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_NAME\",\"type\":\"GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2\"},"
				.. "{\"description\":\"Not yet revealed.\",\"hidden\":true,\"name\":\"???\",\"type\":\"GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3\"}]}]",
			json:match("\"promote\":(%b[])")
		)
	end)

	it("never offers to assign a Secret Society, who can't be assigned", function()
		local owls = { type = "GOVERNOR_OWLS_OF_MINERVA" }
		local json = ChoicesWith({ appointed = { REYNA, owls } }, { world = { cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" } } })

		assert.truthy(json:find("GOVERNOR_THE_MERCHANT", 1, true))
		assert.falsy(json:find("GOVERNOR_OWLS_OF_MINERVA", 1, true))
	end)

	it("is left out without Rise and Fall, with nothing to do, and while the World Congress is in session", function()
		local governors = { appointed = { REYNA }, candidates = { { type = "GOVERNOR_THE_DEFENDER" } } }

		assert.is_nil(ChoicesWith(nil))
		assert.is_nil(ChoicesWith({ canAppoint = false, candidates = { { type = "GOVERNOR_THE_DEFENDER" } } }))
		assert.is_nil(ChoicesWith(governors, { world = { expansion2 = true, congressInSession = true } }))
		assert.truthy(ChoicesWith(governors, { world = { congressInSession = true } }))
	end)
end)

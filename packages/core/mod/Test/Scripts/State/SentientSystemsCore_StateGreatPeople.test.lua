local FakeGame = require("FakeGame")
local Game = require("Game")

local SUN_TZU = {
	class = "GREAT_PERSON_CLASS_GENERAL",
	type = "GREAT_PERSON_INDIVIDUAL_SUN_TZU",
	name = "LOC_GREAT_PERSON_INDIVIDUAL_SUN_TZU_NAME",
	era = "ERA_CLASSICAL",
	cost = 30,
	passive = { name = "Passive Effect", effect = "+5 [ICON_Strength] Combat Strength." },
	action = { name = "Retire", usage = "Activate at a district.", effect = "The Art of War." },
	gold = { cost = 650, can = true },
	faith = { cost = 450 },
}

-- Returns a copy of a great person with the fields given changed.
local function With(person, changes)
	local copy = {}

	for key, value in pairs(person) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

-- Returns the great people section JSON for player 0, in a world with the great people and players
-- given, and the world fields in extra.
local function GreatPeopleWith(greatPeople, players, extra)
	local env = Game.new()
	local world = { greatPeople = greatPeople, players = players or { [0] = {} }, text = { LOC_GREAT_PERSON_INDIVIDUAL_SUN_TZU_NAME = "Sun Tzu" } }

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"greatPeople\":(%b[])")
end

describe("SentientSystems_GetGreatPeopleState", function()
	it("gives each great person with their era, cost, effects, patronage, and the player's progress", function()
		assert.equal(
			"[{\"action\":{\"effect\":\"The Art of War.\",\"name\":\"Retire\",\"usage\":\"Activate at a district.\"},"
				.. "\"class\":\"GREAT_PERSON_CLASS_GENERAL\",\"cost\":30,\"era\":\"ERA_CLASSICAL\",\"name\":\"Sun Tzu\","
				.. "\"passive\":\"+5 [ICON_Strength] Combat Strength.\",\"patronage\":{\"faith\":{\"can\":false,\"cost\":450},\"gold\":{\"can\":true,\"cost\":650}},"
				.. "\"progress\":[{\"perTurn\":0,\"player\":0,\"points\":0}],\"type\":\"GREAT_PERSON_INDIVIDUAL_SUN_TZU\"}]",
			GreatPeopleWith({ SUN_TZU })
		)
	end)

	it("gives the action's charges, and leaves out an empty passive and a claimed class", function()
		local aryabhata = With(SUN_TZU, {
			class = "GREAT_PERSON_CLASS_SCIENTIST",
			type = "GREAT_PERSON_INDIVIDUAL_ARYABHATA",
			charges = 1,
			passive = { name = "", effect = "" },
		})
		local json = GreatPeopleWith({ aryabhata, With(SUN_TZU, { claimed = true }) })

		assert.truthy(json:find("\"action\":{\"charges\":1,", 1, true))
		assert.falsy(json:find("passive", 1, true))
		assert.falsy(json:find("SUN_TZU", 1, true))
	end)

	it("gives the reason the player can't earn a great person, and hides a cost too high to show", function()
		local json = GreatPeopleWith({ With(SUN_TZU, { cantEarn = "You must have a coastal city center.", gold = {}, faith = {} }) })

		assert.truthy(json:find("\"cantEarn\":\"You must have a coastal city center.\",", 1, true))
		assert.falsy(json:find("patronage", 1, true))
	end)

	it("hides patronage while the player can recruit or pass, or without the capability", function()
		assert.falsy(GreatPeopleWith({ With(SUN_TZU, { canRecruit = true }) }):find("patronage", 1, true))
		assert.falsy(GreatPeopleWith({ With(SUN_TZU, { passCost = 6 }) }):find("patronage", 1, true))
		assert.truthy(GreatPeopleWith({ SUN_TZU }, nil, { offCapabilities = { CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD = true } })
			:find("\"patronage\":{\"faith\":{\"can\":false,\"cost\":450}},", 1, true))
	end)

	it("turns patronage off while Gathering Storm's World Congress is in session", function()
		local json = GreatPeopleWith({ SUN_TZU }, nil, { expansion2 = true, congressInSession = true })

		assert.truthy(json:find("\"gold\":{\"can\":false,\"cost\":650}", 1, true))
	end)

	it("lists each major player's progress, most points first, rounded, and hides the unmet", function()
		local function Points(points, perTurn)
			return { greatPeoplePoints = { GREAT_PERSON_CLASS_GENERAL = { points = points, perTurn = perTurn } } }
		end

		local players = { [0] = Points(4.26, 2.04), [1] = Points(9, 3), [2] = Points(4.26, 1), [3] = Points(1, 1), [12] = { minor = {} } }

		players[0].met = { 3 }

		assert.equal(
			"[{\"perTurn\":3,\"points\":9,\"unmet\":true},{\"perTurn\":2,\"player\":0,\"points\":4.3},"
				.. "{\"perTurn\":1,\"points\":4.3,\"unmet\":true},{\"perTurn\":1,\"player\":3,\"points\":1}]",
			GreatPeopleWith({ SUN_TZU }, players):match("\"progress\":(%b[])")
		)
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

local RA_KEDET = {
	id = 65536, name = "LOC_CITY_NAME_RA_KEDET", x = 30, y = 18, population = 2, capital = true,
	defense = { strength = 12.6, garrison = { damage = 50, max = 200 } },
}

-- Returns the rival cities JSON in the state for player 0, with Egypt as player 1.
local function RivalCitiesFor(me, egyptCities)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = me, [1] = { cities = egyptCities } },
		text = { LOC_CITY_NAME_RA_KEDET = "Râ-Kedet" },
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"rivals\":{\"cities\":(%b[])")
end

describe("SentientSystems_GetRivalCityStates", function()
	it("lists a rival city on a revealed tile, with its owner and its banner's values", function()
		assert.equal(
			"[{\"capital\":true,\"defense\":{\"garrison\":{\"max\":200,\"value\":150},\"strength\":13},\"id\":65536,"
				.. "\"name\":\"Râ-Kedet\",\"owner\":1,\"population\":2,\"x\":30,\"y\":18}]",
			RivalCitiesFor({ revealed = { { 30, 18 } } }, { RA_KEDET })
		)
	end)

	it("adds the walls' health when the city has walls", function()
		local city = {}

		for key, value in pairs(RA_KEDET) do
			city[key] = value
		end

		city.defense = { strength = 20, walls = { damage = 10, max = 100 } }

		assert.truthy(RivalCitiesFor({ visible = { { 30, 18 } } }, { city }):find("\"walls\":{\"max\":100,\"value\":90}", 1, true))
	end)

	it("leaves out a rival city on a tile the player hasn't revealed", function()
		assert.equal("[]", RivalCitiesFor({}, { RA_KEDET }))
	end)

	it("leaves out the player's own cities", function()
		local env = Game.new()

		FakeGame.Install(env, { players = { [0] = { cities = { RA_KEDET }, visible = { { 30, 18 } } } } })
		Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

		assert.truthy(env.SentientSystems_GetState(0):find("\"rivals\":{\"cities\":[]}", 1, true))
	end)
end)

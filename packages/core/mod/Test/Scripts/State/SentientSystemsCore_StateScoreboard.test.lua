local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the scoreboard JSON of player 0 in a world.
local function ScoreboardOf(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"scoreboard\":(%b[])")
end

local ME = {
	score = 48,
	military = 29.6,
	science = 3.5,
	culture = 4.4,
	gold = 107.9,
	faith = 590.6,
	favor = 11.5,
	categories = { CATEGORY_CIVICS = 3, CATEGORY_EMPIRE = 13 },
	met = { 1 },
}

-- Returns the categories JSON of a player with the points in civics and empire, and 0 in the rest.
local function Categories(civics, empire)
	return "[{\"name\":\"LOC_CATEGORY_CIVICS_NAME\",\"score\":" .. civics .. ",\"type\":\"CATEGORY_CIVICS\"},"
		.. "{\"name\":\"LOC_CATEGORY_EMPIRE_NAME\",\"score\":" .. empire .. ",\"type\":\"CATEGORY_EMPIRE\"},"
		.. "{\"name\":\"LOC_CATEGORY_GREAT_PEOPLE_NAME\",\"score\":0,\"type\":\"CATEGORY_GREAT_PEOPLE\"},"
		.. "{\"name\":\"LOC_CATEGORY_RELIGION_NAME\",\"score\":0,\"type\":\"CATEGORY_RELIGION\"},"
		.. "{\"name\":\"LOC_CATEGORY_TECH_NAME\",\"score\":0,\"type\":\"CATEGORY_TECH\"},"
		.. "{\"name\":\"LOC_CATEGORY_WONDER_NAME\",\"score\":0,\"type\":\"CATEGORY_WONDER\"},"
		.. "{\"name\":\"LOC_CATEGORY_ERA_SCORE_NAME\",\"score\":0,\"type\":\"CATEGORY_ERA_SCORE\"}]"
end

describe("SentientSystems_GetScoreboardState", function()
	it("gives the player and a met player the leader panel's numbers, and every player the score's categories", function()
		local json = ScoreboardOf({ players = { [0] = ME, [1] = { score = 25, military = 20, met = { 0 } } } })

		assert.equal(
			"[{\"categories\":" .. Categories(3, 13) .. ",\"culture\":4,\"faith\":591,\"gold\":107,\"military\":30,\"player\":0,"
				.. "\"science\":4,\"score\":48},{\"categories\":" .. Categories(0, 0)
				.. ",\"culture\":0,\"faith\":0,\"gold\":0,\"military\":20,\"player\":1,\"science\":0,\"score\":25}]",
			json
		)
	end)

	it("leaves out the ID of a player they have not met, and lists the players by score", function()
		local json = ScoreboardOf({ players = { [0] = { score = 10 }, [1] = { score = 30 }, [2] = { score = 20, met = {} } } })

		assert.equal(
			"[{\"categories\":" .. Categories(0, 0) .. ",\"score\":30},{\"categories\":" .. Categories(0, 0)
				.. ",\"score\":20},{\"categories\":" .. Categories(0, 0)
				.. ",\"culture\":0,\"faith\":0,\"gold\":0,\"military\":0,\"player\":0,\"science\":0,\"score\":10}]",
			json
		)
	end)

	it("lists players with equal scores in ID order and leaves out city-states", function()
		local json = ScoreboardOf({ players = { [0] = { score = 5 }, [1] = { score = 5 }, [2] = { score = 5, minor = {} } } })

		assert.equal(2, select(2, json:gsub("\"score\":5", "")))
		assert.truthy(json:find("\"player\":0,\"science\":0,\"score\":5},{\"categories\":[^]]*%],\"score\":5}"))
	end)

	it("adds favor for Gathering Storm, unless the diplomatic victory is off", function()
		local world = { expansion2 = true, players = { [0] = ME, [1] = {} } }

		assert.truthy(ScoreboardOf(world):find("\"favor\":12,", 1, true))

		world.noDiplomaticVictory = true

		assert.is_nil(ScoreboardOf(world):find("\"favor\"", 1, true))
	end)

	it("leaves out favor without Gathering Storm", function()
		assert.is_nil(ScoreboardOf({ players = { [0] = ME, [1] = {} } }):find("\"favor\"", 1, true))
	end)
end)

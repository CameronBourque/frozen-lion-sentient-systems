local FakeGame = require("FakeGame")
local Game = require("Game")

-- The player's era, with the score and age the tests give, in a game on turn 85 whose era ends
-- between turns 101 and 111.
local function Era(changes)
	local era = {
		score = 200,
		age = "normal",
		dark = 228,
		golden = 239,
		loyalty = 1,
		previous = { { ["Historic Moments"] = 30 }, { ["Wonders"] = 6 } },
		current = { { ["Historic Moments"] = 6 }, { ["Nothing"] = 0 }, { ["Trade Routes"] = 1 } },
		commemorations = { "ECONOMIC" },
	}

	for key, value in pairs(changes or {}) do
		era[key] = value
	end

	return era
end

-- Returns the era section JSON for player 0, whose era is given, in a game with the rest of world,
-- or nil when it is left out.
local function EraWith(era, world)
	local env = Game.new()
	local setup = {
		turn = 85,
		era = { type = "ERA_RENAISSANCE", minEnd = 101, maxEnd = 111 },
		players = { [0] = { met = { 1, 2, 3 }, era = era }, [1] = { era = { age = "golden" } }, [2] = { era = { age = "dark" } }, [3] = {}, [4] = {} },
	}

	for key, value in pairs(world or {}) do
		setup[key] = value
	end

	FakeGame.Install(env, setup)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"era\":(%b{})")
end

describe("SentientSystems_GetEraState", function()
	it("gives the era, the score and age, what the next age needs, and the turns until the next era", function()
		local json = EraWith(Era())

		assert.truthy(json:find("\"age\":\"normal\",", 1, true))
		assert.truthy(json:find("\"name\":\"LOC_ERA_RENAISSANCE_NAME\",\"nextAge\":\"dark\",\"score\":200,", 1, true))
		assert.truthy(json:find("\"thresholds\":{\"golden\":239,\"normal\":228},\"turnsUntilNext\":{\"max\":26,\"min\":16},\"type\":\"ERA_RENAISSANCE\",", 1, true))
	end)

	it("gives the score's sources, the earlier eras as one, and leaves out a source of 0", function()
		assert.truthy(EraWith(Era()):find("\"scoreBreakdown\":[{\"points\":36,\"source\":\"LOC_ERAS_PREVIOUS_ERA_TOTAL_SCORE\"},"
			.. "{\"points\":6,\"source\":\"Historic Moments\"},{\"points\":1,\"source\":\"Trade Routes\"}]", 1, true))
		assert.truthy(EraWith(Era({ previous = {}, current = {} })):find("\"scoreBreakdown\":[]", 1, true))
	end)

	it("gives the citizens' loyalty pressure and each active dedication's text for the age", function()
		assert.truthy(EraWith(Era()):find("\"effects\":{\"citizenLoyalty\":1,\"dedications\":[{\"text\":\"LOC_MOMENT_CATEGORY_ECONOMIC_BONUS_NORMAL_AGE\","
			.. "\"type\":\"COMMEMORATION_ECONOMIC\"}]}", 1, true))
		assert.truthy(EraWith(Era({ age = "dark" })):find("LOC_MOMENT_CATEGORY_ECONOMIC_BONUS_DARK_AGE", 1, true))
		assert.truthy(EraWith(Era({ age = "golden" })):find("LOC_MOMENT_CATEGORY_ECONOMIC_BONUS_GOLDEN_AGE", 1, true))
		assert.truthy(EraWith(Era({ commemorations = {} })):find("\"dedications\":[]", 1, true))
	end)

	it("lists the ages of the players it has met in the panel's order, and counts the ones it hasn't", function()
		local json = EraWith(Era())

		assert.truthy(json:find("\"civilizations\":[{\"age\":\"golden\",\"player\":1},{\"age\":\"normal\",\"player\":3},{\"age\":\"dark\",\"player\":2}]", 1, true))
		assert.truthy(json:find("\"unmet\":1}", 1, true))
	end)

	it("puts a heroic age before the golden ones", function()
		local json = EraWith(Era(), { players = { [0] = { met = { 1, 2 }, era = Era() }, [1] = { era = { age = "golden" } }, [2] = { era = { age = "heroic" } } } })

		assert.truthy(json:find("\"civilizations\":[{\"age\":\"heroic\",\"player\":2},{\"age\":\"golden\",\"player\":1}]", 1, true))
	end)

	it("gives the age the score earns, from the thresholds", function()
		assert.truthy(EraWith(Era({ score = 227 })):find("\"nextAge\":\"dark\"", 1, true))
		assert.truthy(EraWith(Era({ score = 228 })):find("\"nextAge\":\"normal\"", 1, true))
		assert.truthy(EraWith(Era({ score = 238 })):find("\"nextAge\":\"normal\"", 1, true))
		assert.truthy(EraWith(Era({ score = 239 })):find("\"nextAge\":\"golden\"", 1, true))
	end)

	it("counts the turns of a countdown that has started as one number", function()
		local json = EraWith(Era(), { era = { type = "ERA_RENAISSANCE", countdown = 3, minEnd = 101, maxEnd = 111 } })

		assert.truthy(json:find("\"turnsUntilNext\":{\"max\":4,\"min\":4}", 1, true))
	end)

	it("never gives fewer turns than the countdown takes, or fewer than none", function()
		local json = EraWith(Era(), { era = { type = "ERA_RENAISSANCE", minEnd = 88, maxEnd = 80 } })

		assert.truthy(json:find("\"turnsUntilNext\":{\"max\":0,\"min\":10}", 1, true))
	end)

	it("leaves out the normal age's threshold in the Dramatic Ages mode", function()
		assert.truthy(EraWith(Era(), { dramaticAges = true }):find("\"thresholds\":{\"golden\":239}", 1, true))
	end)

	it("has no thresholds or turns in the final era", function()
		local json = EraWith(Era(), { era = { type = "ERA_RENAISSANCE", final = true } })

		assert.truthy(json:find("\"final\":true,", 1, true))
		assert.falsy(json:find("thresholds", 1, true))
		assert.falsy(json:find("turnsUntilNext", 1, true))
		assert.falsy(json:find("nextAge", 1, true))
	end)

	it("is left out without Rise and Fall", function()
		assert.is_nil(EraWith(nil, { era = false }))
	end)
end)

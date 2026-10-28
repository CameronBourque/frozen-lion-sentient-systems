local FakeGame = require("FakeGame")
local Game = require("Game")

-- Owls of Minerva, a Secret Society, joined, with its base ability held and the next two hidden until
-- the one before is held.
local OWLS = {
	type = "GOVERNOR_OWLS_OF_MINERVA",
	promotions = {
		{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", base = true, level = 0, column = 1, has = true },
		{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2", level = 1, column = 1, requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1" }, hiddenWithoutPrereqs = true },
		{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3", level = 2, column = 1, requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2" }, hiddenWithoutPrereqs = true },
	},
}

-- Returns an environment with the shared governor rules loaded into a fake game where player 0 has
-- the governors given, and the world fields in extra.
local function Load(governors, extra)
	local env = Game.new()
	local world = {
		players = { [0] = { governors = governors } },
		cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" },
		text = { LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME = "???", LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION = "Not yet revealed." },
	}

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/SentientSystemsCore_Governors.lua")

	return env
end

-- Returns the row of a promotion, by type, from the environment's GameInfo.
local function Promotion(env, number)
	return env.GameInfo.GovernorPromotions["GOVERNOR_PROMOTION_OWLS_OF_MINERVA_" .. number]
end

-- Returns the joined society, as the player's governor list gives it.
local function Joined(env)
	local _, list = env.Players[0]:GetGovernors():GetGovernorList()

	return list[1]
end

describe("SentientSystems_IsCannotAssign", function()
	it("is true for a Secret Society and false for another governor", function()
		local env = Load({ appointed = { OWLS }, candidates = { { type = "GOVERNOR_THE_DEFENDER" } } })

		assert.is_true(env.SentientSystems_IsCannotAssign(env.GameInfo.Governors["GOVERNOR_OWLS_OF_MINERVA"]))
		assert.is_false(env.SentientSystems_IsCannotAssign(env.GameInfo.Governors["GOVERNOR_THE_DEFENDER"]))
	end)

	it("is false without the game's table of governors that can't be assigned", function()
		local env = Load({ appointed = { OWLS } })

		env.GameInfo.GovernorsCannotAssign = nil

		assert.is_false(env.SentientSystems_IsCannotAssign(env.GameInfo.Governors["GOVERNOR_OWLS_OF_MINERVA"]))
	end)
end)

describe("SentientSystems_IsPromotionHidden", function()
	it("never hides a promotion that has no condition, such as the base ability", function()
		local env = Load({ appointed = { OWLS } })

		assert.is_false(env.SentientSystems_IsPromotionHidden(Promotion(env, 1), Joined(env)))
		assert.is_false(env.SentientSystems_IsPromotionHidden(Promotion(env, 1), nil))
	end)

	it("hides a conditional promotion from a candidate, and from a governor who lacks what it follows", function()
		local env = Load({ appointed = { OWLS } })

		assert.is_true(env.SentientSystems_IsPromotionHidden(Promotion(env, 2), nil))
		assert.is_true(env.SentientSystems_IsPromotionHidden(Promotion(env, 3), Joined(env)))
	end)

	it("shows a conditional promotion once the governor holds what it follows", function()
		local env = Load({ appointed = { OWLS } })

		assert.is_false(env.SentientSystems_IsPromotionHidden(Promotion(env, 2), Joined(env)))
	end)

	it("hides nothing without the game's table of conditions", function()
		local env = Load({ appointed = { OWLS } })

		env.GameInfo.GovernorPromotionConditions = nil

		assert.is_false(env.SentientSystems_IsPromotionHidden(Promotion(env, 2), nil))
	end)
end)

describe("SentientSystems_GetPromotionTexts", function()
	it("gives a visible promotion's own name and description, and no hidden flag", function()
		local env = Load({ appointed = { OWLS } })
		local name, description, hidden = env.SentientSystems_GetPromotionTexts(Promotion(env, 2), Joined(env))

		assert.equal("LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_NAME", name)
		assert.equal("LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_DESCRIPTION", description)
		assert.is_nil(hidden)
	end)

	it("gives the game's text for a hidden promotion", function()
		local env = Load({ appointed = { OWLS } })
		local name, description, hidden = env.SentientSystems_GetPromotionTexts(Promotion(env, 3), Joined(env))

		assert.equal("???", name)
		assert.equal("Not yet revealed.", description)
		assert.is_true(hidden)
	end)

	it("gives ? for a hidden promotion when the game has no text for it", function()
		local env = Load({ appointed = { OWLS } }, { text = {} })
		local name, description, hidden = env.SentientSystems_GetPromotionTexts(Promotion(env, 3), nil)

		assert.equal("?", name)
		assert.equal("?", description)
		assert.is_true(hidden)
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- Reyna, established in Ostia with her base ability.
local REYNA = {
	type = "GOVERNOR_THE_MERCHANT",
	city = { owner = 0, id = 393221 },
	established = true,
	promotions = {
		{ type = "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION", has = true },
		{ type = "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER" },
	},
}

-- Returns the governors section JSON for player 0, whose governors are given, or nil when it is
-- left out.
local function GovernorsWith(governors, extra)
	local env = Game.new()
	local world = {
		players = { [0] = { governors = governors } },
		text = { LOC_GOVERNOR_THE_MERCHANT_NAME = "Reyna", LOC_GOVERNOR_THE_MERCHANT_TITLE = "The Financier" },
	}

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"governors\":(%b{})")
end

describe("SentientSystems_GetGovernorState", function()
	it("gives the titles and each appointed governor with their city and promotions", function()
		assert.equal(
			"{\"appointed\":[{\"city\":{\"id\":393221,\"owner\":0},\"established\":true,\"loyalty\":8,\"name\":\"Reyna\","
				.. "\"promotions\":[\"GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION\"],\"title\":\"The Financier\",\"turnsToEstablish\":5,"
				.. "\"type\":\"GOVERNOR_THE_MERCHANT\"}],\"spent\":8,\"titles\":1}",
			GovernorsWith({ points = 9, spent = 8, appointed = { REYNA } })
		)
	end)

	it("gives the turns left for a governor settling in, and the turns a neutralized one is out", function()
		local settling = { type = REYNA.type, city = REYNA.city, turnsOnSite = 2, turnsToEstablish = 3, loyalty = 10 }
		local json = GovernorsWith({ points = 1, spent = 1, appointed = { settling } })

		assert.truthy(json:find("\"established\":false,\"loyalty\":10,", 1, true))
		assert.truthy(json:find("\"turnsLeft\":1,\"turnsToEstablish\":3,", 1, true))

		local neutralized = GovernorsWith({ points = 1, spent = 1, appointed = { { type = REYNA.type, neutralized = 4 } } })

		assert.truthy(neutralized:find("\"neutralized\":4,", 1, true))
		assert.falsy(neutralized:find("city", 1, true))
	end)

	it("marks a Secret Society, which has no loyalty or turns to establish, and lists the promotions it holds", function()
		local owls = {
			type = "GOVERNOR_OWLS_OF_MINERVA",
			promotions = {
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", base = true, has = true },
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2", requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1" }, hiddenWithoutPrereqs = true },
			},
		}

		assert.equal(
			"{\"appointed\":[{\"name\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_NAME\",\"promotions\":[\"GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1\"],\"secret\":true,"
				.. "\"title\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_TITLE\",\"type\":\"GOVERNOR_OWLS_OF_MINERVA\"}],\"spent\":1,\"titles\":0}",
			GovernorsWith({ points = 1, spent = 1, appointed = { owls } }, { cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" } })
		)
	end)

	it("gives no governors before any are appointed", function()
		assert.equal("{\"appointed\":[],\"spent\":0,\"titles\":1}", GovernorsWith({ points = 1 }))
	end)

	it("is left out without Rise and Fall", function()
		assert.is_nil(GovernorsWith(nil))
	end)
end)

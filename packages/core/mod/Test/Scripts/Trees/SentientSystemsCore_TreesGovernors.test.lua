local FakeGame = require("FakeGame")
local Game = require("Game")

-- Reyna, established in Ostia with her base ability, who can earn both promotions below it.
local REYNA = {
	type = "GOVERNOR_THE_MERCHANT",
	city = { owner = 0, id = 393221 },
	established = true,
	loyalty = 10,
	turnsToEstablish = 4,
	promotions = {
		{ type = "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION", base = true, level = 0, column = 1, has = true },
		{ type = "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER", level = 1, column = 0, requires = { "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION" }, canEarn = true },
		{ type = "GOVERNOR_PROMOTION_MERCHANT_FORESTRY", level = 1, column = 2, requires = { "GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION" }, canEarn = true },
		{
			type = "GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR",
			level = 2,
			column = 1,
			requires = { "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER", "GOVERNOR_PROMOTION_MERCHANT_FORESTRY" },
		},
	},
}

-- Victor, a candidate who takes 3 turns to settle in.
local VICTOR = {
	type = "GOVERNOR_THE_DEFENDER",
	turnsToEstablish = 3,
	promotions = {
		{ type = "GOVERNOR_PROMOTION_DEFENDER_REDOUBT", base = true, level = 0, column = 1 },
		{ type = "GOVERNOR_PROMOTION_DEFENDER_GARRISON", level = 1, column = 0, requires = { "GOVERNOR_PROMOTION_DEFENDER_REDOUBT" } },
	},
}

-- Returns an environment with the governor tree script loaded into a fake game where player 0 has
-- the governors given, and the world fields in extra.
local function Load(governors, extra)
	local env = Game.new()
	local world = { players = { [0] = { governors = governors } } }

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Trees/SentientSystemsCore_TreesGovernors.lua")

	return env
end

describe("SentientSystems_GetGovernorTree", function()
	it("gives a candidate with its promotions, of which only the base ability is held", function()
		assert.equal(
			"{\"governors\":[{\"description\":\"LOC_GOVERNOR_THE_DEFENDER_DESCRIPTION\",\"loyalty\":8,\"name\":\"LOC_GOVERNOR_THE_DEFENDER_NAME\",\"promotions\":["
				.. "{\"column\":1,\"description\":\"LOC_GOVERNOR_PROMOTION_DEFENDER_REDOUBT_DESCRIPTION\",\"level\":0,\"name\":\"LOC_GOVERNOR_PROMOTION_DEFENDER_REDOUBT_NAME\","
				.. "\"requires\":[],\"status\":\"held\",\"type\":\"GOVERNOR_PROMOTION_DEFENDER_REDOUBT\"},"
				.. "{\"column\":0,\"description\":\"LOC_GOVERNOR_PROMOTION_DEFENDER_GARRISON_DESCRIPTION\",\"level\":1,\"name\":\"LOC_GOVERNOR_PROMOTION_DEFENDER_GARRISON_NAME\","
				.. "\"requires\":[\"GOVERNOR_PROMOTION_DEFENDER_REDOUBT\"],\"status\":\"locked\",\"type\":\"GOVERNOR_PROMOTION_DEFENDER_GARRISON\"}],"
				.. "\"status\":\"candidate\",\"title\":\"LOC_GOVERNOR_THE_DEFENDER_TITLE\",\"turnsToEstablish\":3,\"type\":\"GOVERNOR_THE_DEFENDER\"}]}",
			Load({ candidates = { VICTOR } }).SentientSystems_GetGovernorTree(0)
		)
	end)

	it("marks an appointed governor's promotions held, available, or locked, and gives their own loyalty and turns", function()
		local json = Load({ appointed = { REYNA } }).SentientSystems_GetGovernorTree(0)

		assert.truthy(json:find("\"loyalty\":10,\"name\":\"LOC_GOVERNOR_THE_MERCHANT_NAME\"", 1, true))
		assert.truthy(json:find("\"status\":\"appointed\",\"title\":\"LOC_GOVERNOR_THE_MERCHANT_TITLE\",\"turnsToEstablish\":4,", 1, true))
		assert.truthy(json:find("\"status\":\"held\",\"type\":\"GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION\"", 1, true))
		assert.truthy(json:find("\"status\":\"available\",\"type\":\"GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER\"", 1, true))
		assert.truthy(json:find("\"status\":\"available\",\"type\":\"GOVERNOR_PROMOTION_MERCHANT_FORESTRY\"", 1, true))
	end)

	it("lists every promotion a promotion follows, which the game needs any one of", function()
		local json = Load({ appointed = { REYNA } }).SentientSystems_GetGovernorTree(0)

		assert.truthy(json:find(
			"\"requires\":[\"GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER\",\"GOVERNOR_PROMOTION_MERCHANT_FORESTRY\"],\"status\":\"locked\",\"type\":\"GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR\"",
			1,
			true
		))
	end)

	it("lists the appointed governors, then the candidates, and leaves out a governor the player never can appoint", function()
		local ibrahim = { type = "GOVERNOR_IBRAHIM", canEver = false }
		local json = Load({ appointed = { REYNA }, candidates = { ibrahim, VICTOR } }).SentientSystems_GetGovernorTree(0)
		local statuses = {}

		for status in json:gmatch("\"status\":\"(%a+)\",\"title\"") do
			statuses[#statuses + 1] = status
		end

		assert.same({ "appointed", "candidate" }, statuses)
		assert.falsy(json:find("IBRAHIM", 1, true))
	end)

	it("gives a Secret Society the player has discovered, with its hidden promotions masked and no stats", function()
		local owls = {
			type = "GOVERNOR_OWLS_OF_MINERVA",
			promotions = {
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", base = true, level = 0, column = 1 },
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2", level = 1, column = 1, requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1" }, hiddenWithoutPrereqs = true },
			},
		}
		local env = Load({ candidates = { owls } }, {
			cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" },
			text = { LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME = "???", LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION = "Not yet revealed." },
		})

		assert.equal(
			"{\"governors\":[{\"description\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_DESCRIPTION\",\"name\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_NAME\",\"promotions\":["
				.. "{\"column\":1,\"description\":\"LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_DESCRIPTION\",\"level\":0,\"name\":\"LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1_NAME\","
				.. "\"requires\":[],\"status\":\"held\",\"type\":\"GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1\"},"
				.. "{\"column\":1,\"description\":\"Not yet revealed.\",\"hidden\":true,\"level\":1,\"name\":\"???\","
				.. "\"requires\":[\"GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1\"],\"status\":\"locked\",\"type\":\"GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2\"}],"
				.. "\"secret\":true,\"status\":\"candidate\",\"title\":\"LOC_GOVERNOR_OWLS_OF_MINERVA_TITLE\",\"type\":\"GOVERNOR_OWLS_OF_MINERVA\"}]}",
			env.SentientSystems_GetGovernorTree(0)
		)
	end)

	it("shows a joined Secret Society's next promotion once it holds the one before, and masks the rest", function()
		local owls = {
			type = "GOVERNOR_OWLS_OF_MINERVA",
			promotions = {
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", base = true, level = 0, column = 1, has = true },
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2", level = 1, column = 1, requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1" }, hiddenWithoutPrereqs = true },
				{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_3", level = 2, column = 1, requires = { "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2" }, hiddenWithoutPrereqs = true },
			},
		}
		local json = Load({ appointed = { owls } }, {
			cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" },
			text = { LOC_GOVERNOR_PROMOTION_UNKNOWN_NAME = "???", LOC_GOVERNOR_PROMOTION_UNKNOWN_DESCRIPTION = "Not yet revealed." },
		}).SentientSystems_GetGovernorTree(0)

		assert.truthy(json:find("\"secret\":true,\"status\":\"appointed\"", 1, true))
		assert.falsy(json:find("loyalty", 1, true))
		assert.truthy(json:find("\"name\":\"LOC_GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2_NAME\"", 1, true))
		assert.truthy(json:find("\"description\":\"Not yet revealed.\",\"hidden\":true,\"level\":2", 1, true))
	end)

	it("leaves out a Secret Society the player hasn't discovered", function()
		local json = Load({ candidates = { { type = "GOVERNOR_HERMETIC_ORDER", canEver = false } } }, { cannotAssign = { "GOVERNOR_HERMETIC_ORDER" } }).SentientSystems_GetGovernorTree(0)

		assert.equal("{\"governors\":[]}", json)
	end)

	it("gives an empty tree without Rise and Fall", function()
		assert.equal("{\"governors\":[]}", Load(nil).SentientSystems_GetGovernorTree(0))
	end)

	it("raises an error for an ID with no player", function()
		assert.has_error(function()
			Load(nil).SentientSystems_GetGovernorTree(5)
		end, "no player 5")
	end)
end)

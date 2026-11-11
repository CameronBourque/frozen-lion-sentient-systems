local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

local CITIES = {
	{ id = 65536, name = "Rome", x = 1, y = 1, population = 5, capital = true },
	{ id = 131073, name = "Antium", x = 2, y = 2, population = 3 },
	{ id = 393221, name = "Ostia", x = 3, y = 3, population = 4 },
}

-- Reyna, established in Ostia, who can be promoted to Harbormaster but not yet
-- to Tax Collector.
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

-- Amani, in Rome, who can go to the city-state player 0 has met, but not to
-- the one the game turns off.
local AMANI = { type = "GOVERNOR_THE_AMBASSADOR", city = { owner = 0, id = 65536 }, cityStates = true }

-- Player 0 has Reyna and Amani, 2 titles left, and can appoint Victor but never
-- Ibrahim.
local GOVERNORS = {
	points = 10,
	spent = 8,
	appointed = { REYNA, AMANI },
	candidates = { { type = "GOVERNOR_THE_DEFENDER" }, { type = "GOVERNOR_IBRAHIM", canEver = false } },
	cannotAssignTo = { ["13:65536"] = { "LOC_AT_WAR" } },
}

local CITY_STATES = {
	[12] = { minor = {}, cities = { { id = 65536, name = "Samarkand", x = 6, y = 6, population = 1 } } },
	[13] = { minor = {}, cities = { { id = 65536, name = "Cahokia", x = 7, y = 7, population = 1 } } },
}

-- Returns an environment with the actions loaded into a fake game where player
-- 0 has the governors given, GOVERNORS when nil, or none when false, as without
-- Rise and Fall, and the fields in world.
local function Load(governors, world)
	local env = Game.new()

	if governors == nil then
		governors = GOVERNORS
	end

	local players = { [0] = { governors = governors or nil, cities = CITIES, met = { 12, 13 } } }

	for id, data in pairs(CITY_STATES) do
		players[id] = data
	end

	local fields = { players = players }

	for key, value in pairs(world or {}) do
		fields[key] = value
	end

	FakeGame.Install(env, fields)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns governors like GOVERNORS, with the fields in extra.
local function GovernorsWith(extra)
	local governors = {}

	for key, value in pairs(GOVERNORS) do
		governors[key] = value
	end

	for key, value in pairs(extra) do
		governors[key] = value
	end

	return governors
end

describe("The governor actions", function()
	it("fail without Rise and Fall, and while the World Congress is in session", function()
		local closed = {
			{ Load(false), "This game has no governors. They come with Rise and Fall." },
			{ Load(GOVERNORS, { expansion2 = true, congressInSession = true }), "The World Congress is in session. Act on governors after it ends." },
		}

		for _, case in ipairs(closed) do
			local env = case[1]

			assert.equal(Failed(case[2]), env.SentientSystems_AppointGovernor(0, "GOVERNOR_THE_DEFENDER"))
			assert.equal(Failed(case[2]), env.SentientSystems_PromoteGovernor(0, "GOVERNOR_THE_MERCHANT", "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER"))
			assert.equal(Failed(case[2]), env.SentientSystems_AssignGovernor(0, "GOVERNOR_THE_MERCHANT", 0, 65536))
			assert.same({}, env.requests)
		end
	end)

	it("fail for a type that is no governor", function()
		local env = Load()
		local reason = Failed("GOVERNOR_NOPE isn't a governor. Use a type from the governors choice.")

		assert.equal(reason, env.SentientSystems_AppointGovernor(0, "GOVERNOR_NOPE"))
		assert.equal(reason, env.SentientSystems_PromoteGovernor(0, "GOVERNOR_NOPE", "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER"))
		assert.equal(reason, env.SentientSystems_AssignGovernor(0, "GOVERNOR_NOPE", 0, 65536))
		assert.equal(Failed("nil isn't a governor. Use a type from the governors choice."), env.SentientSystems_AppointGovernor(0))
	end)

	it("fail for an ID with no player", function()
		assert.equal(Failed("AppointGovernor failed: no player 3"), Load().SentientSystems_AppointGovernor(3, "GOVERNOR_THE_DEFENDER"))
	end)
end)

describe("SentientSystems_AppointGovernor", function()
	it("sends the panel's request with the governor's index", function()
		local env = Load()
		local P = env.PlayerOperations

		assert.equal("{\"ok\":true}", env.SentientSystems_AppointGovernor(0, "GOVERNOR_THE_DEFENDER"))
		assert.same({
			{ player = 0, operation = P.APPOINT_GOVERNOR, parameters = { [P.PARAM_GOVERNOR_TYPE] = env.GameInfo.Governors.GOVERNOR_THE_DEFENDER.Index } },
		}, env.requests)
	end)

	it("fails for a governor the panel wouldn't appoint", function()
		local cases = {
			{ GOVERNORS, "GOVERNOR_THE_MERCHANT", "You have appointed GOVERNOR_THE_MERCHANT already." },
			{ GOVERNORS, "GOVERNOR_IBRAHIM", "You can't appoint GOVERNOR_IBRAHIM. Use a type from the governors choice." },
			{
				GovernorsWith({ canAppoint = false }),
				"GOVERNOR_THE_DEFENDER",
				"You have no governor title to spend. The governors choice lists appointments once you do.",
			},
		}

		for _, case in ipairs(cases) do
			local env = Load(case[1])

			assert.equal(Failed(case[3]), env.SentientSystems_AppointGovernor(0, case[2]))
			assert.same({}, env.requests)
		end
	end)
end)

describe("SentientSystems_PromoteGovernor", function()
	it("sends the panel's request with the governor's and the promotion's indexes", function()
		local env = Load()
		local P = env.PlayerOperations
		local parameters = {
			[P.PARAM_GOVERNOR_TYPE] = env.GameInfo.Governors.GOVERNOR_THE_MERCHANT.Index,
			[P.PARAM_GOVERNOR_PROMOTION_TYPE] = env.GameInfo.GovernorPromotions.GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER.Index,
		}

		assert.equal("{\"ok\":true}", env.SentientSystems_PromoteGovernor(0, "GOVERNOR_THE_MERCHANT", "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER"))
		assert.same({ { player = 0, operation = P.PROMOTE_GOVERNOR, parameters = parameters } }, env.requests)
	end)

	it("fails for a promotion the panel wouldn't give", function()
		local cases = {
			{ GOVERNORS, "GOVERNOR_THE_DEFENDER", "GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER", "You haven't appointed GOVERNOR_THE_DEFENDER. Appoint them first." },
			{
				GOVERNORS,
				"GOVERNOR_THE_MERCHANT",
				"GOVERNOR_PROMOTION_NOPE",
				"GOVERNOR_PROMOTION_NOPE isn't a promotion of GOVERNOR_THE_MERCHANT. Use a type from the governors choice.",
			},
			{
				GOVERNORS,
				"GOVERNOR_THE_MERCHANT",
				"GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION",
				"GOVERNOR_THE_MERCHANT has GOVERNOR_PROMOTION_MERCHANT_LAND_ACQUISITION already.",
			},
			{
				GovernorsWith({ spent = 10 }),
				"GOVERNOR_THE_MERCHANT",
				"GOVERNOR_PROMOTION_MERCHANT_HARBORMASTER",
				"You have no governor title to spend on GOVERNOR_THE_MERCHANT. The governors choice lists promotions once you do.",
			},
			{
				GOVERNORS,
				"GOVERNOR_THE_MERCHANT",
				"GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR",
				"GOVERNOR_THE_MERCHANT can't earn GOVERNOR_PROMOTION_MERCHANT_TAX_COLLECTOR yet. Use a type from the governors choice.",
			},
		}

		for _, case in ipairs(cases) do
			local env = Load(case[1])

			assert.equal(Failed(case[4]), env.SentientSystems_PromoteGovernor(0, case[2], case[3]))
			assert.same({}, env.requests)
		end
	end)
end)

describe("SentientSystems_PromoteGovernor for a Secret Society", function()
	-- The Owls of Minerva, joined, whose second promotion waits for the
	-- Medieval era. The game can't promote them while none can be earned.
	local OWLS = {
		type = "GOVERNOR_OWLS_OF_MINERVA",
		promotions = {
			{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_1", has = true },
			{ type = "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2", era = "ERA_MEDIEVAL", hiddenWithoutPrereqs = true },
		},
	}

	it("names the era a promotion waits for, though a title is left", function()
		local env = Load(GovernorsWith({ appointed = { OWLS } }), { era = { type = "ERA_ANCIENT" } })

		assert.equal(
			Failed("GOVERNOR_OWLS_OF_MINERVA can't earn GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2 before ERA_MEDIEVAL."),
			env.SentientSystems_PromoteGovernor(0, "GOVERNOR_OWLS_OF_MINERVA", "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2")
		)
		assert.same({}, env.requests)
	end)

	it("names no era once the game is in it", function()
		local env = Load(GovernorsWith({ appointed = { OWLS } }), { era = { type = "ERA_MEDIEVAL" } })

		assert.equal(
			Failed("GOVERNOR_OWLS_OF_MINERVA can't earn GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2 yet. Use a type from the governors choice."),
			env.SentientSystems_PromoteGovernor(0, "GOVERNOR_OWLS_OF_MINERVA", "GOVERNOR_PROMOTION_OWLS_OF_MINERVA_2")
		)
	end)
end)

describe("SentientSystems_AssignGovernor", function()
	it("sends the chooser's request with the city's owner and ID", function()
		local cases = { { "GOVERNOR_THE_MERCHANT", 0, 65536 }, { "GOVERNOR_THE_AMBASSADOR", 12, 65536 } }

		for _, case in ipairs(cases) do
			local env = Load()
			local P = env.PlayerOperations
			local parameters = { [P.PARAM_GOVERNOR_TYPE] = env.GameInfo.Governors[case[1]].Index, [P.PARAM_PLAYER_ONE] = case[2], [P.PARAM_CITY_DEST] = case[3] }

			assert.equal("{\"ok\":true}", env.SentientSystems_AssignGovernor(0, case[1], case[2], case[3]))
			assert.same({ { player = 0, operation = P.ASSIGN_GOVERNOR, parameters = parameters } }, env.requests)
		end
	end)

	it("fails for a governor the panel wouldn't assign", function()
		local owls = { type = "GOVERNOR_OWLS_OF_MINERVA" }
		local neutralized = { type = REYNA.type, city = REYNA.city, neutralized = 3 }
		local cases = {
			{ GOVERNORS, "GOVERNOR_THE_DEFENDER", "You haven't appointed GOVERNOR_THE_DEFENDER. Appoint them first." },
			{ GovernorsWith({ appointed = { owls } }), "GOVERNOR_OWLS_OF_MINERVA", "GOVERNOR_OWLS_OF_MINERVA can't be assigned to a city." },
			{ GovernorsWith({ appointed = { neutralized } }), "GOVERNOR_THE_MERCHANT", "GOVERNOR_THE_MERCHANT is neutralized for 3 more turns." },
		}

		for _, case in ipairs(cases) do
			local env = Load(case[1], { cannotAssign = { "GOVERNOR_OWLS_OF_MINERVA" } })

			assert.equal(Failed(case[3]), env.SentientSystems_AssignGovernor(0, case[2], 0, 65536))
			assert.same({}, env.requests)
		end
	end)

	it("fails for a city the chooser wouldn't offer", function()
		local cases = {
			{ "GOVERNOR_THE_MERCHANT", 0, 393221, "GOVERNOR_THE_MERCHANT is in that city already." },
			{
				"GOVERNOR_THE_MERCHANT",
				12,
				65536,
				"City 65536 of player 12 isn't a place GOVERNOR_THE_MERCHANT can go. Use a city from the governors choice.",
			},
			{ "GOVERNOR_THE_AMBASSADOR", 13, 65536, "GOVERNOR_THE_AMBASSADOR can't go to Cahokia. LOC_AT_WAR" },
		}

		for _, case in ipairs(cases) do
			local env = Load()

			assert.equal(Failed(case[4]), env.SentientSystems_AssignGovernor(0, case[1], case[2], case[3]))
			assert.same({}, env.requests)
		end
	end)
end)

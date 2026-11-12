local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

local NONE = "You have no dedication to make. The dedications choice lists one when an era begins."

-- Returns an environment with the actions loaded, where player 0 may make the
-- number of dedications given from three, with the blockers given, the
-- dedication blocker when missing.
local function Load(allowed, blockers)
	local env = Game.new()
	local dedications = { era = "ERA_CLASSICAL", age = allowed > 1 and "heroic" or "golden", allowed = allowed, options = { "SCIENTIFIC", "CULTURAL", "RELIGIOUS" } }

	FakeGame.Install(env, {
		players = { [0] = { dedications = dedications, blockers = blockers or { "ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE" } } },
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the index of the dedication's row.
local function RowIndex(env, type)
	for _, row in pairs(env.GameInfo.CommemorationTypes) do
		if row.CommemorationType == type then
			return row.Index
		end
	end
end

-- Returns one request for each dedication, with its row's index.
local function Requests(env, types)
	local P = env.PlayerOperations
	local requests = {}

	for i, type in ipairs(types) do
		requests[i] = { player = 0, operation = P.COMMEMORATE, parameters = { [P.PARAM_COMMEMORATION_TYPE] = RowIndex(env, type) } }
	end

	return requests
end

describe("SentientSystems_ChooseDedications", function()
	it("sends the popup's request for the one dedication of a golden age", function()
		local env = Load(1)

		assert.equal("{\"ok\":true}", env.SentientSystems_ChooseDedications(0, { "COMMEMORATION_CULTURAL" }))
		assert.same(Requests(env, { "COMMEMORATION_CULTURAL" }), env.requests)
	end)

	it("sends one request for each of a heroic age's three dedications", function()
		local env = Load(3)
		local types = { "COMMEMORATION_RELIGIOUS", "COMMEMORATION_SCIENTIFIC", "COMMEMORATION_CULTURAL" }

		assert.equal("{\"ok\":true}", env.SentientSystems_ChooseDedications(0, types))
		assert.same(Requests(env, types), env.requests)
	end)

	it("fails for a dedication that isn't offered, or one chosen twice", function()
		local env = Load(3)

		assert.equal(
			Failed("COMMEMORATION_INFRASTRUCTURE isn't a dedication you can make. Use one of COMMEMORATION_SCIENTIFIC, COMMEMORATION_CULTURAL, COMMEMORATION_RELIGIOUS."),
			env.SentientSystems_ChooseDedications(0, { "COMMEMORATION_INFRASTRUCTURE" })
		)
		assert.equal(
			Failed("You chose COMMEMORATION_CULTURAL twice. Choose each dedication once."),
			env.SentientSystems_ChooseDedications(0, { "COMMEMORATION_CULTURAL", "COMMEMORATION_CULTURAL" })
		)
		assert.same({}, env.requests)
	end)

	it("fails for more or fewer dedications than the age allows", function()
		assert.equal(Failed("Choose 3 dedications, not 2."), Load(3).SentientSystems_ChooseDedications(0, { "COMMEMORATION_CULTURAL", "COMMEMORATION_SCIENTIFIC" }))
		assert.equal(Failed("Choose 1 dedication, not 2."), Load(1).SentientSystems_ChooseDedications(0, { "COMMEMORATION_CULTURAL", "COMMEMORATION_SCIENTIFIC" }))
	end)

	it("fails for dedications that aren't a list", function()
		assert.equal(Failed("The dedications are a list of types from the dedications choice."), Load(1).SentientSystems_ChooseDedications(0, "COMMEMORATION_CULTURAL"))
	end)

	it("fails with no dedication waiting, or without the blocker", function()
		assert.equal(Failed(NONE), Load(1, {}).SentientSystems_ChooseDedications(0, { "COMMEMORATION_CULTURAL" }))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("ChooseDedications failed: no player 3"), Load(1).SentientSystems_ChooseDedications(3, {}))
	end)
end)

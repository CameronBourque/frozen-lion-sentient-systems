local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

local RESOLVE = "Resolve the blockers first, or pass force to end the turn anyway."

-- Returns an environment with the actions loaded, on turn 5, where player 0
-- has the data given.
local function Load(player)
	local env = Game.new()

	FakeGame.Install(env, { turn = 5, players = { [0] = player or {} } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns a unit of player 0 with the ID, ready for orders when ready is true.
local function Unit(id, ready)
	return { id = id, type = "UNIT_WARRIOR", x = 7, y = 13, moves = 2, maxMoves = 2, ready = ready }
end

describe("SentientSystems_EndTurn", function()
	it("sends the Next Turn button's request with nothing blocking", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_EndTurn(0))
		assert.same({ { action = env.ActionTypes.ACTION_ENDTURN } }, env.requests)
	end)

	it("fails while a blocker is left, and names its choice", function()
		local env = Load({ blockers = { "ENDTURN_BLOCKING_RESEARCH", "ENDTURN_BLOCKING_UNIT_PROMOTION" } })

		assert.equal(
			Failed(RESOLVE .. " Blockers: ENDTURN_BLOCKING_RESEARCH (the techs choice), ENDTURN_BLOCKING_UNIT_PROMOTION."),
			env.SentientSystems_EndTurn(0)
		)
		assert.same({}, env.requests)
	end)

	it("lists the units that need orders in place of the unit blockers", function()
		local env = Load({
			blockers = { "ENDTURN_BLOCKING_UNITS", "ENDTURN_BLOCKING_PRODUCTION" },
			units = { Unit(131073, true), Unit(131074), Unit(196608, true) },
		})

		assert.equal(
			Failed(RESOLVE .. " Blockers: ENDTURN_BLOCKING_PRODUCTION (the production choice). Units that need orders: 131073, 196608."),
			env.SentientSystems_EndTurn(0)
		)
	end)

	it("ends the turn when only a stale unit blocker is left", function()
		assert.equal("{\"ok\":true}", Load({ blockers = { "ENDTURN_BLOCKING_UNITS" } }).SentientSystems_EndTurn(0))
	end)

	it("ends the turn anyway with force", function()
		local env = Load({ blockers = { "ENDTURN_BLOCKING_RESEARCH" }, units = { Unit(131073, true) } })

		assert.equal("{\"ok\":true}", env.SentientSystems_EndTurn(0, true))
		assert.same({ { action = env.ActionTypes.ACTION_ENDTURN } }, env.requests)
	end)

	it("sends one request at most in a turn, even with force", function()
		local env = Load()

		env.SentientSystems_EndTurn(0)

		assert.equal(Failed("You already ended turn 5. Wait for your next turn."), env.SentientSystems_EndTurn(0, true))
		assert.equal(1, #env.requests)
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("EndTurn failed: no player 3"), Load().SentientSystems_EndTurn(3))
	end)
end)

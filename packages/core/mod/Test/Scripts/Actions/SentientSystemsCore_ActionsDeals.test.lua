local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

-- A deal that player 4 puts to player 0: Horses for Open Borders.
local OPEN_BORDERS = {
	items = {
		{ id = 2, type = "RESOURCES", from = 0, amount = 10, value = "RESOURCE_HORSES" },
		{ id = 3, type = "AGREEMENTS", from = 4, sub = "OPEN_BORDERS", duration = 20 },
	},
}

-- Returns an environment with the actions loaded, where player 0 has the
-- proposals given, by the ID of the player who made each.
local function Load(proposals)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { proposals = proposals }, [4] = {}, [5] = {} } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_RespondToDeal", function()
	it("accepts as the Accept button does, then closes the session", function()
		local env = Load({ [4] = OPEN_BORDERS })

		assert.equal("{\"ok\":true}", env.SentientSystems_RespondToDeal(0, 4, true))
		assert.same({
			{ copy = { 0, 4 } },
			{ send = { env.DealProposalAction.ACCEPTED, 0, 4 } },
			{ close = 1 },
		}, env.requests)
	end)

	it("rejects with the Refuse button's response, then closes the session", function()
		local env = Load({ [4] = OPEN_BORDERS })

		assert.equal("{\"ok\":true}", env.SentientSystems_RespondToDeal(0, 4, false))
		assert.same({ { response = { 1, 0, "NEGATIVE" } }, { close = 1 } }, env.requests)
	end)

	it("fails to accept a deal that is no longer valid", function()
		local env = Load({ [4] = { valid = false, items = OPEN_BORDERS.items } })

		assert.equal(Failed("The deal from player 4 is no longer valid. Reject it."), env.SentientSystems_RespondToDeal(0, 4, true))
		assert.same({}, env.requests)
	end)

	it("fails with no deal waiting, or for a session the player started", function()
		local none = "Player 4 has no deal waiting for you. The proposals section lists the deals put to you."

		assert.equal(Failed(none), Load({ [5] = OPEN_BORDERS }).SentientSystems_RespondToDeal(0, 4, true))
		assert.equal(Failed(none), Load({ [4] = { started = false, items = OPEN_BORDERS.items } }).SentientSystems_RespondToDeal(0, 4, false))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("RespondToDeal failed: no player 9"), Load({}).SentientSystems_RespondToDeal(0, 9, true))
	end)
end)

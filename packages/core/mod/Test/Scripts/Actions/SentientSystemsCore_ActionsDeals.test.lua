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

-- Returns an environment with the actions loaded, where player 0 has met
-- players 4, 5, and the city-state 12, and is at war with player 5. diplomacy
-- is player 0's entry for each other player, and proposals the deals put to
-- player 0.
local function LoadWar(diplomacy, proposals)
	local env = Game.new()

	FakeGame.Install(env, {
		players = {
			[0] = { met = { 4, 5, 12 }, atWar = { 5 }, diplomacy = diplomacy, proposals = proposals },
			[4] = {},
			[5] = {},
			[9] = {},
			[12] = { minor = { name = "LOC_CIVILIZATION_HATTUSA_NAME", leader = "LEADER_MINOR_CIV_SCIENTIFIC" } },
		},
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_DeclareWar", function()
	it("asks for the war popup's session for a major civ, then closes it", function()
		local env = LoadWar()

		assert.equal("{\"ok\":true}", env.SentientSystems_DeclareWar(0, 4))
		assert.same({ { session = { 0, 4, "DECLARE_SURPRISE_WAR" } }, { close = 1 } }, env.requests)
	end)

	it("fails while another diplomacy session is open", function()
		local env = LoadWar(nil, { [5] = OPEN_BORDERS })

		assert.equal(Failed("A diplomacy session with player 5 is open. Answer it first."), env.SentientSystems_DeclareWar(0, 4))
		assert.same({}, env.requests)
	end)

	it("sends the war popup's player operation for a city-state", function()
		local env = LoadWar()
		local P = env.PlayerOperations

		assert.equal("{\"ok\":true}", env.SentientSystems_DeclareWar(0, 12))
		assert.same({ { player = 0, operation = P.DIPLOMACY_DECLARE_WAR, parameters = { [P.PARAM_PLAYER_ONE] = 0, [P.PARAM_PLAYER_TWO] = 12 } } }, env.requests)
	end)

	it("fails for a player not met, or one already at war", function()
		local env = LoadWar()

		assert.equal(Failed("You haven't met player 9."), env.SentientSystems_DeclareWar(0, 9))
		assert.equal(Failed("You are already at war with player 5."), env.SentientSystems_DeclareWar(0, 5))
		assert.same({}, env.requests)
	end)

	it("fails with the game's reasons, or its own when the game gives none", function()
		local env = LoadWar({ [4] = { noWar = { "LOC_A", "LOC_B" } }, [12] = { noWar = {} } })

		assert.equal(Failed("LOC_A LOC_B"), env.SentientSystems_DeclareWar(0, 4))
		assert.equal(Failed("The game doesn't allow a war with player 12 now."), env.SentientSystems_DeclareWar(0, 12))
		assert.same({}, env.requests)
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("DeclareWar failed: no player 7"), LoadWar().SentientSystems_DeclareWar(0, 7))
	end)
end)

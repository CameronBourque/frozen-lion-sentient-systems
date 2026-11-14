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

-- A troop warning with a promise, a war, and stop asking, and a greeting.
local SESSION_WORLD = {
	statements = {
		{ Type = "WARNING_TROOPS", SubType = "NONE", Initiator = "AI", Selections = "WARN" },
		{ Type = "FIRST_MEET", SubType = "NONE", Initiator = "AI", Selections = "MEET" },
	},
	selections = {
		{ Type = "WARN", Key = "CHOICE_POSITIVE", Sort = 0 },
		{ Type = "WARN", Key = "CHOICE_NEGATIVE", Sort = 1, DiplomaticActionType = "DIPLOACTION_DECLARE_SURPRISE_WAR" },
		{ Type = "WARN", Key = "CHOICE_STOP_ASKING", Sort = 2 },
		{ Type = "MEET", Key = "CHOICE_POSITIVE", Sort = 0 },
		{ Type = "MEET", Key = "CHOICE_EXIT", Sort = 1 },
		{ Type = "MEET", Key = "CHOICE_FOLLOW", Sort = 2 },
	},
}

-- Returns an environment with the actions loaded, where player 4 has session 7
-- open with player 0, and player 5 session 8. data replaces player 0's data.
local function LoadSessions(data)
	local env = Game.new()
	local world = { players = { [0] = data or { sessions = { [4] = { id = 7 }, [5] = { id = 8 } } }, [4] = {}, [5] = {} } }

	for key, value in pairs(SESSION_WORLD) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")
	env.requests = {}

	return env
end

-- Has player 4 make the statement of the given type in session 7.
local function Say(env, statementType)
	env.SentientSystems_HandleStatement(4, 0, { SessionID = 7, StatementType = statementType, StatementSubType = "NONE", Initiator = 4 })
	env.requests = {}
end

describe("SentientSystems_RespondToSession", function()
	it("adds the response that the leader screen adds for each option", function()
		local env = LoadSessions()

		Say(env, "WARNING_TROOPS")

		for _, option in ipairs({ "CHOICE_POSITIVE", "CHOICE_NEGATIVE", "CHOICE_STOP_ASKING" }) do
			assert.equal("{\"ok\":true}", env.SentientSystems_RespondToSession(0, 4, option))
		end

		assert.same({
			{ response = { 7, 0, "POSITIVE" } },
			{ response = { 7, 0, "NEGATIVE" } },
			{ response = { 7, 0, "REJECTED_PERMANENT" } },
		}, env.requests)
	end)

	it("closes the session for the goodbye, and sends any other key as it is", function()
		local env = LoadSessions()

		Say(env, "FIRST_MEET")

		assert.equal("{\"ok\":true}", env.SentientSystems_RespondToSession(0, 4, "CHOICE_EXIT"))
		assert.equal("{\"ok\":true}", env.SentientSystems_RespondToSession(0, 4, "CHOICE_FOLLOW"))
		assert.same({ { close = 7 }, { response = { 7, 0, "CHOICE_FOLLOW" } } }, env.requests)
	end)

	it("fails for an option the session doesn't offer, or one that is disabled", function()
		local env = LoadSessions({
			sessions = { [4] = { id = 7 } },
			diplomacy = { [4] = { noWar = { "LOC_NOT_NOW" } } },
		})

		Say(env, "WARNING_TROOPS")

		assert.equal(
			Failed("Player 4's session doesn't offer CHOICE_EXIT. It offers CHOICE_POSITIVE, CHOICE_NEGATIVE, CHOICE_STOP_ASKING."),
			env.SentientSystems_RespondToSession(0, 4, "CHOICE_EXIT")
		)
		assert.equal(Failed("CHOICE_NEGATIVE is disabled: LOC_NOT_NOW"), env.SentientSystems_RespondToSession(0, 4, "CHOICE_NEGATIVE"))
		assert.same({}, env.requests)
	end)

	it("fails for a queued session, and allows only the goodbye for an unknown one", function()
		local queued = LoadSessions()
		local unknown = LoadSessions()

		Say(queued, "FIRST_MEET")

		assert.equal(Failed("Player 5's session waits behind another one. Answer that one first."), queued.SentientSystems_RespondToSession(0, 5, "CHOICE_EXIT"))
		assert.equal(
			Failed("The core mod didn't see what player 5 said, so only CHOICE_EXIT can answer it."),
			unknown.SentientSystems_RespondToSession(0, 5, "CHOICE_POSITIVE")
		)
		assert.equal("{\"ok\":true}", unknown.SentientSystems_RespondToSession(0, 5, "CHOICE_EXIT"))
		assert.same({ { close = 8 } }, unknown.requests)
	end)

	it("fails with no session, and points a deal to the deal response", function()
		local deal = LoadSessions({ proposals = { [4] = OPEN_BORDERS } })

		assert.equal(Failed("Player 4's session holds a deal. Answer it with the deal response."), deal.SentientSystems_RespondToSession(0, 4, "CHOICE_EXIT"))
		assert.equal(
			Failed("Player 4 has no leader screen open with you. The sessions section lists them."),
			LoadSessions({}).SentientSystems_RespondToSession(0, 4, "CHOICE_EXIT")
		)
	end)
end)

describe("SentientSystems_DeclareWar", function()
	it("asks for the war popup's session for a major civ, then closes it", function()
		local env = LoadWar()

		assert.equal("{\"ok\":true}", env.SentientSystems_DeclareWar(0, 4))
		assert.same({ { session = { 0, 4, "DECLARE_SURPRISE_WAR" } }, { close = 1 } }, env.requests)
	end)

	it("fails while another diplomacy session is open, except for a city-state", function()
		local env = LoadWar(nil, { [5] = OPEN_BORDERS })

		assert.equal(Failed("A diplomacy session with player 5 is open. Answer it first."), env.SentientSystems_DeclareWar(0, 4))
		assert.same({}, env.requests)
		assert.equal("{\"ok\":true}", env.SentientSystems_DeclareWar(0, 12))
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

-- Returns an environment with the actions loaded, where player 0 has met
-- players 4, 5, and the city-state 12, and is at war with 4 and 12. diplomacy
-- is player 0's entry for each other player, and proposals the deals put to
-- player 0.
local function LoadPeace(diplomacy, proposals)
	local env = Game.new()

	FakeGame.Install(env, {
		players = {
			[0] = { met = { 4, 5, 12 }, atWar = { 4, 12 }, diplomacy = diplomacy, proposals = proposals },
			[4] = {},
			[5] = {},
			[9] = {},
			[12] = { minor = { name = "LOC_CIVILIZATION_HATTUSA_NAME", leader = "LEADER_MINOR_CIV_SCIENTIFIC" } },
		},
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_ProposePeace", function()
	it("proposes the leader screen's peace deal to a major civ, then closes the session", function()
		local env = LoadPeace()

		assert.equal("{\"ok\":true}", env.SentientSystems_ProposePeace(0, 4))
		assert.same({
			{ clear = { env.DealDirection.OUTGOING, 0, 4 } },
			{ item = { type = env.DealItemTypes.AGREEMENTS, from = 0, sub = env.DealAgreementTypes.MAKE_PEACE, locked = true } },
			{ validate = true },
			{ session = { 0, 4, "MAKE_DEAL" } },
			{ send = { env.DealProposalAction.PROPOSED, 0, 4 } },
			{ close = 1 },
		}, env.requests)
	end)

	it("sends the city-state screen's player operation for a city-state", function()
		local env = LoadPeace()
		local P = env.PlayerOperations

		assert.equal("{\"ok\":true}", env.SentientSystems_ProposePeace(0, 12))
		assert.same({ { player = 0, operation = P.DIPLOMACY_MAKE_PEACE, parameters = { [P.PARAM_PLAYER_ONE] = 0, [P.PARAM_PLAYER_TWO] = 12 } } }, env.requests)
	end)

	it("fails for a player not met, or one at peace", function()
		local env = LoadPeace()

		assert.equal(Failed("You haven't met player 9."), env.SentientSystems_ProposePeace(0, 9))
		assert.equal(Failed("You aren't at war with player 5."), env.SentientSystems_ProposePeace(0, 5))
		assert.same({}, env.requests)
	end)

	it("fails with the game's reasons, or its own for a city-state", function()
		local env = LoadPeace({ [4] = { noPeace = { "LOC_A", "LOC_B" } }, [12] = { noPeace = {} } })

		assert.equal(Failed("LOC_A LOC_B"), env.SentientSystems_ProposePeace(0, 4))
		assert.equal(
			Failed("The game doesn't allow peace with player 12 now. A city-state makes peace only some turns after the war began, and not while you are at war with its suzerain."),
			env.SentientSystems_ProposePeace(0, 12)
		)
		assert.same({}, env.requests)
	end)

	it("fails with its own reason when the game's check gives none", function()
		local env = LoadPeace({ [4] = { noPeace = {} } })

		assert.equal(Failed("The game doesn't allow peace with player 4 now."), env.SentientSystems_ProposePeace(0, 4))
	end)

	it("fails while another diplomacy session is open, except for a city-state", function()
		local env = LoadPeace(nil, { [5] = OPEN_BORDERS })

		assert.equal(Failed("A diplomacy session with player 5 is open. Answer it first."), env.SentientSystems_ProposePeace(0, 4))
		assert.same({}, env.requests)
		assert.equal("{\"ok\":true}", env.SentientSystems_ProposePeace(0, 12))
	end)
end)

describe("SentientSystems_GetPeaceResult", function()
	it("is ok once the war has ended, and fails while it goes on", function()
		local env = LoadPeace()

		assert.equal("{\"ok\":true}", env.SentientSystems_GetPeaceResult(0, 5))
		assert.equal(Failed("Player 4 hasn't accepted peace. You are still at war."), env.SentientSystems_GetPeaceResult(0, 4))
	end)
end)

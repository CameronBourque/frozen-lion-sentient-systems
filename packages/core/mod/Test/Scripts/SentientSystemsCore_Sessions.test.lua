local FakeGame = require("FakeGame")
local Game = require("Game")

-- The rows for a kudo, which offers only the goodbye, and for a request,
-- which offers a choice.
local STATEMENTS = {
	{
		Type = "DIPLOMATIC_KUDO",
		SubType = "NONE",
		Initiator = "AI",
		Selections = "EXIT_ONLY",
		StatementText = "LOC_KUDO",
		ReasonText = "LOC_KUDO_REASON",
	},
	{ Type = "DIPLOMATIC_DELEGATION", SubType = "NONE", Initiator = "AI", Selections = "CHOICE", StatementText = "LOC_ASK" },
	{ Type = "MAKE_DEAL", SubType = "HUMAN_REFUSE_DEAL", Initiator = "AI", Selections = "EXIT_ONLY", StatementText = "LOC_DEAL" },
}

local SELECTIONS = {
	{ Type = "EXIT_ONLY", Key = "CHOICE_EXIT" },
	{ Type = "CHOICE", Key = "CHOICE_POSITIVE" },
	{ Type = "CHOICE", Key = "CHOICE_EXIT" },
}

-- Returns an environment on turn 85 with the sessions script loaded, where
-- player 0 is human, player 4 is an AI with session 7 open with player 0, and
-- its world. extra changes the world.
local function Load(extra)
	local env = Game.new()
	local world = {
		turn = 85,
		players = { [0] = { human = true, sessions = { [4] = { id = 7 } } }, [4] = {}, [5] = { human = true } },
		statements = STATEMENTS,
		selections = SELECTIONS,
	}

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	env.requests = {}
	Game.run(env, "Scripts/SentientSystemsCore_Sessions.lua")

	return env, world
end

-- Returns a statement from player 4 that opened session 7, with changes.
local function Statement(changes)
	local statement = { SessionID = 7, StatementType = "DIPLOMATIC_KUDO", StatementSubType = "NONE", Initiator = 4 }

	for key, value in pairs(changes or {}) do
		statement[key] = value
	end

	return statement
end

describe("SentientSystems_HandleStatement", function()
	it("closes a statement that offers only the goodbye, and keeps what the leader said", function()
		local env = Load({ agendaReasons = { AGENDA_X = " Likes X." } })

		env.SentientSystems_HandleStatement(4, 0, Statement({ AiReason = 3, AiModifier = "AGENDA_X" }))

		assert.same({ { close = 7 } }, env.requests)
		assert.same({
			{ turn = 85, statement = "DIPLOMATIC_KUDO", text = "LOC_KUDO:4:nil:0", reason = "LOC_KUDO_REASON:4:3:AGENDA_X Likes X." },
		}, env.SentientSystems_GetSessionMessages(0, 4))
	end)

	it("leaves out a reason the game has no key for", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement())

		assert.same({ { turn = 85, statement = "DIPLOMATIC_KUDO", text = "LOC_KUDO:4:nil:0" } }, env.SentientSystems_GetSessionMessages(0, 4))
	end)

	it("leaves out the text of a statement with none", function()
		local env = Load({ statements = { { Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Selections = "EXIT_ONLY" } } })

		env.SentientSystems_HandleStatement(4, 0, Statement())

		assert.same({ { turn = 85, statement = "DIPLOMATIC_KUDO" } }, env.SentientSystems_GetSessionMessages(0, 4))
	end)

	it("leaves open a statement with a choice", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "DIPLOMATIC_DELEGATION" }))

		assert.same({}, env.requests)
		assert.same({}, env.SentientSystems_GetSessionMessages(0, 4))
	end)

	it("leaves a deal to the deal action, even with only the goodbye", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "MAKE_DEAL", StatementSubType = "HUMAN_REFUSE_DEAL" }))

		assert.same({}, env.requests)
	end)

	it("leaves open a statement from a human", function()
		local env = Load()

		env.SentientSystems_HandleStatement(5, 0, Statement({ Initiator = 5 }))

		assert.same({}, env.requests)
	end)

	it("leaves open a statement with no row", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "FIRST_MEET_NEW" }))

		assert.same({}, env.requests)
	end)

	it("reads the human rows when the player opened the session, as for the reply to a war", function()
		local env = Load({
			statements = {
				{ Type = "DECLARE_SURPRISE_WAR", SubType = "NONE", Initiator = "AI", Selections = "CHOICE" },
				{ Type = "DECLARE_SURPRISE_WAR", SubType = "NONE", Initiator = "HUMAN", Selections = "EXIT_ONLY" },
			},
		})

		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "DECLARE_SURPRISE_WAR", Initiator = 0 }))
		env.SentientSystems_HandleStatement(4, 0, Statement({ SessionID = 8, StatementType = "DECLARE_SURPRISE_WAR", Initiator = 99 }))

		assert.same({ { close = 7 }, { close = 8 } }, env.requests)
	end)

	it("reads the statement's mood, and the rows for any mood when it has none", function()
		local env = Load({
			statements = {
				{ Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Selections = "CHOICE" },
				{ Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Mood = "HAPPY", Selections = "EXIT_ONLY" },
			},
		})

		env.SentientSystems_HandleStatement(4, 0, Statement())
		env.SentientSystems_HandleStatement(4, 0, Statement({ SessionID = 8, FromPlayerMood = "HAPPY" }))
		env.SentientSystems_HandleStatement(4, 0, Statement({ SessionID = 9, FromPlayerMood = 12 }))

		assert.same({ { close = 8 } }, env.requests)
	end)

	it("takes an undefined mood from how the leader sees the player", function()
		local statements = {
			{ Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Mood = "UNHAPPY", Selections = "EXIT_ONLY" },
			{ Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Mood = "NEUTRAL", Selections = "CHOICE" },
		}
		local atWar, atWarWorld = Load({ statements = statements })
		local neutral = Load({ statements = statements })

		atWarWorld.players[4].diplomacy = { [0] = { state = "DIPLO_STATE_WAR" } }
		atWar.SentientSystems_HandleStatement(4, 0, Statement({ FromPlayerMood = -1 }))
		neutral.SentientSystems_HandleStatement(4, 0, Statement({ FromPlayerMood = -1 }))

		assert.same({ { close = 7 } }, atWar.requests)
		assert.same({}, neutral.requests)
	end)

	it("prefers the leader's own rows, statements and selections alike", function()
		local env = Load({
			statements = {
				{ Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Selections = "CHOICE" },
				{ Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Leader = "LEADER_X", Selections = "MINE" },
			},
			selections = {
				{ Type = "MINE", Key = "CHOICE_POSITIVE" },
				{ Type = "MINE", Leader = "LEADER_X", Key = "CHOICE_EXIT" },
			},
		})

		env.PlayerConfigurations[4].GetLeaderTypeName = function()
			return "LEADER_X"
		end
		env.SentientSystems_HandleStatement(4, 0, Statement())

		assert.same({ { close = 7 } }, env.requests)
	end)

	it("leaves open a statement whose selections have no rows", function()
		local env = Load({ statements = { { Type = "DIPLOMATIC_KUDO", SubType = "NONE", Initiator = "AI", Selections = "NONE" } } })

		env.SentientSystems_HandleStatement(4, 0, Statement())

		assert.same({}, env.requests)
	end)
end)

describe("SentientSystems_GetOpenStatement", function()
	it("gives a copy of the statement of a session left open, with its players", function()
		local env = Load()
		local statement = Statement({ StatementType = "DIPLOMATIC_DELEGATION" })

		env.SentientSystems_HandleStatement(4, 0, statement)
		statement.StatementType = "CHANGED"

		local open, sessionID = env.SentientSystems_GetOpenStatement(0, 4)

		assert.equal(7, sessionID)
		assert.same({
			from = 4,
			to = 0,
			SessionID = 7,
			StatementType = "DIPLOMATIC_DELEGATION",
			StatementSubType = "NONE",
			Initiator = 4,
		}, open)
	end)

	it("keeps only the latest statement of a session", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "DIPLOMATIC_DELEGATION" }))
		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "FIRST_MEET" }))

		assert.equal("FIRST_MEET", env.SentientSystems_GetOpenStatement(0, 4).StatementType)
	end)

	it("gives only the session ID when the statement is closed, forgotten, or unseen", function()
		local closed = Load()
		local forgotten = Load()
		local unseen = Load()

		closed.SentientSystems_HandleStatement(4, 0, Statement())
		forgotten.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "DIPLOMATIC_DELEGATION" }))
		forgotten.SentientSystems_ForgetSession(7)

		for _, env in ipairs({ closed, forgotten, unseen }) do
			assert.same({ nil, 7 }, { env.SentientSystems_GetOpenStatement(0, 4) })
		end
	end)

	it("gives nothing with no session open, and leaves out a statement between other players", function()
		local env = Load()

		env.SentientSystems_HandleStatement(5, 4, Statement({ StatementType = "DIPLOMATIC_DELEGATION", Initiator = 5 }))

		assert.same({}, { env.SentientSystems_GetOpenStatement(0, 5) })
		assert.same({ nil, 7 }, { env.SentientSystems_GetOpenStatement(0, 4) })
	end)
end)

describe("SentientSystems_HasOpenStatement", function()
	it("says whether a session left open with the player has its statement kept", function()
		local env = Load()

		assert.is_false(env.SentientSystems_HasOpenStatement(0))
		env.SentientSystems_HandleStatement(4, 0, Statement({ StatementType = "DIPLOMATIC_DELEGATION" }))
		assert.is_true(env.SentientSystems_HasOpenStatement(0))
		assert.is_false(env.SentientSystems_HasOpenStatement(5))
	end)
end)

describe("SentientSystems_GetSessionMessages", function()
	it("keeps a message through the next turn, and drops it after", function()
		local env, world = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement())
		world.turn = 86
		assert.equal(1, #env.SentientSystems_GetSessionMessages(0, 4))

		world.turn = 87
		assert.same({}, env.SentientSystems_GetSessionMessages(0, 4))
	end)

	it("drops the old messages when it keeps a new one", function()
		local env, world = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement())
		world.turn = 87
		env.SentientSystems_HandleStatement(4, 0, Statement({ SessionID = 8 }))

		assert.equal(1, #env.SentientSystems_SessionMessages)
	end)

	it("gives only the messages between the two players", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement())
		env.SentientSystems_HandleStatement(4, 5, Statement({ SessionID = 8 }))

		assert.equal(1, #env.SentientSystems_GetSessionMessages(0, 4))
		assert.same({}, env.SentientSystems_GetSessionMessages(4, 0))
	end)

	it("keeps the messages when the script loads again", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement())
		Game.run(env, "Scripts/SentientSystemsCore_Sessions.lua")

		assert.equal(1, #env.SentientSystems_GetSessionMessages(0, 4))
	end)
end)

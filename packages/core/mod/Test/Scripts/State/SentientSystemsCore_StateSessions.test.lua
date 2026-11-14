local FakeGame = require("FakeGame")
local Game = require("Game")

-- A delegation request, a first meeting outside both borders, a human's
-- request, and a deal, with the request's options out of order.
local STATEMENTS = {
	{
		Type = "DIPLOMATIC_DELEGATION",
		SubType = "NONE",
		Initiator = "AI",
		Selections = "ASK",
		StatementText = "LOC_ASK",
		ReasonText = "LOC_ASK_REASON",
	},
	{ Type = "FIRST_MEET", SubType = "NO_MANS", Initiator = "AI", Selections = "MEET" },
	{ Type = "DIPLOMATIC_DELEGATION", SubType = "NONE", Initiator = "HUMAN", Selections = "ASK" },
	{ Type = "MAKE_DEAL", SubType = "NONE", Initiator = "AI", Selections = "ASK" },
}

local SELECTIONS = {
	{ Type = "ASK", Key = "CHOICE_EXIT", Text = "LOC_BYE", Sort = 3 },
	{
		Type = "ASK",
		Key = "CHOICE_POSITIVE",
		Text = "LOC_YES",
		Sort = 1,
		DiplomaticActionType = "DIPLOACTION_DIPLOMATIC_DELEGATION",
	},
	{ Type = "ASK", Key = "CHOICE_STOP_ASKING", Text = "LOC_STOP", Sort = 2 },
	{ Type = "MEET", Key = "CHOICE_POSITIVE", Sort = 1 },
}

-- Returns the environment with the state loaded, where player 0 is human, 4
-- is an AI, and 5 is human, with sessions 7 and 8 open with player 0. players
-- replaces the data of each player it gives.
local function Load(players)
	local env = Game.new()
	local world = {
		players = {
			[0] = { human = true, sessions = { [4] = { id = 7 }, [5] = { id = 8 } } },
			[4] = {},
			[5] = { human = true },
		},
		statements = STATEMENTS,
		selections = SELECTIONS,
		text = { LOC_YES = "Yes", LOC_BYE = "Goodbye", LOC_STOP = "Stop asking" },
	}

	for id, data in pairs(players or {}) do
		world.players[id] = data
	end

	FakeGame.Install(env, world)
	env.requests = {}
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env
end

-- Returns a statement from the player, in the session they have open.
local function Statement(fromID, changes)
	local statement = {
		SessionID = fromID == 4 and 7 or 8,
		StatementType = "DIPLOMATIC_DELEGATION",
		StatementSubType = "NONE",
		Initiator = fromID,
	}

	for key, value in pairs(changes or {}) do
		statement[key] = value
	end

	return statement
end

local function GetSessionsJson(env)
	return env.SentientSystems_GetState(0):match("\"sessions\":(%b[])")
end

-- The player 0 with only session 7 open, with player 4.
local function WithOneSession(changes)
	local data = { human = true, sessions = { [4] = { id = 7 } } }

	for key, value in pairs(changes or {}) do
		data[key] = value
	end

	return { [0] = data }
end

describe("SentientSystems_GetSessionState", function()
	it("lists what the leader says, the reason, and the options in the screen's order", function()
		local env = Load(WithOneSession())

		env.SentientSystems_HandleStatement(4, 0, Statement(4, { AiReason = 2, AiModifier = "X" }))

		assert.equal(
			"[{\"from\":4,\"options\":[{\"key\":\"CHOICE_POSITIVE\",\"text\":\"Yes\"},"
				.. "{\"key\":\"CHOICE_STOP_ASKING\",\"text\":\"Stop asking\"},{\"key\":\"CHOICE_EXIT\",\"text\":\"Goodbye\"}],"
				.. "\"reason\":\"LOC_ASK_REASON:4:2:X\",\"statement\":\"DIPLOMATIC_DELEGATION\",\"text\":\"LOC_ASK:4:nil:0\"}]",
			GetSessionsJson(env)
		)
	end)

	it("drops the offer to stop asking for a human, and gives the subtype and an option with no text", function()
		local env = Load()

		env.SentientSystems_HandleStatement(4, 0, Statement(4, { StatementType = "FIRST_MEET", StatementSubType = "NO_MANS" }))
		env.SentientSystems_HandleStatement(5, 0, Statement(5))

		assert.equal(
			"[{\"from\":4,\"options\":[{\"key\":\"CHOICE_POSITIVE\"}],\"statement\":\"FIRST_MEET\",\"subType\":\"NO_MANS\"},"
				.. "{\"from\":5,\"options\":[{\"key\":\"CHOICE_POSITIVE\",\"text\":\"Yes\"},{\"key\":\"CHOICE_EXIT\",\"text\":\"Goodbye\"}],"
				.. "\"statement\":\"DIPLOMATIC_DELEGATION\"}]",
			GetSessionsJson(env)
		)
	end)

	it("disables an invalid option with the first reason, and drops one with none", function()
		local function GetOptionsJson(reasons)
			local invalid = { DIPLOACTION_DIPLOMATIC_DELEGATION = reasons }
			local env = Load(WithOneSession({ diplomacy = { [4] = { invalid = invalid } } }))

			env.SentientSystems_HandleStatement(4, 0, Statement(4))

			return GetSessionsJson(env):match("\"options\":(%b[])")
		end

		assert.truthy(GetOptionsJson({ "LOC_A", "LOC_B" }):find("{\"disabled\":\"LOC_A\",\"key\":\"CHOICE_POSITIVE\",", 1, true))
		assert.truthy(GetOptionsJson({}):find("{\"disabled\":\"The game gives no reason.\",", 1, true))
		assert.falsy(GetOptionsJson(false):find("CHOICE_POSITIVE", 1, true))
	end)

	it("marks a statement with no row as unknown", function()
		local env = Load(WithOneSession())

		env.SentientSystems_HandleStatement(4, 0, Statement(4, { StatementType = "DIPLOMATIC_NEW" }))

		assert.equal("[{\"from\":4,\"statement\":\"DIPLOMATIC_NEW\",\"unknown\":true}]", GetSessionsJson(env))
	end)

	it("marks a session the other player opened as unknown when the core mod didn't see its statement", function()
		local env = Load(WithOneSession({ sessions = { [4] = { id = 7 }, [5] = { id = 8, from = 0 } } }))

		assert.equal("[{\"from\":4,\"unknown\":true}]", GetSessionsJson(env))
	end)

	it("marks a session as queued while another has its statement up", function()
		local env = Load()

		env.SentientSystems_HandleStatement(5, 0, Statement(5))

		assert.truthy(GetSessionsJson(env):find("[{\"from\":4,\"queued\":true},{\"from\":5,", 1, true))
	end)

	it("leaves out a deal, which the proposals section lists", function()
		local seen = Load(WithOneSession())
		local unseen = Load({ [0] = { human = true, proposals = { [4] = { items = { { id = 2, type = "GOLD", from = 4, amount = 1 } } } } } })

		seen.SentientSystems_HandleStatement(4, 0, Statement(4, { StatementType = "MAKE_DEAL" }))

		assert.equal("[]", GetSessionsJson(seen))
		assert.equal("[]", GetSessionsJson(unseen))
	end)
end)

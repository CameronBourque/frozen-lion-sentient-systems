local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

local BETRAYAL = { TypeName = "WC_EMERGENCY_BACKSTAB", Name = "Betrayal Emergency", Description = "Punish them.", Sender = 0, Target = 10 }
local AID = { TypeName = "WC_EMERGENCY_REQUEST_AID", Name = "Aid Request", Description = "Help them.", Sender = 3, Target = 3 }
local SESSION = { "ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION" }
local NO_SESSION = "There is no World Congress session to vote in. The worldCongress choice lists one while its session is up."

-- Returns an environment with the actions loaded, where player 0 has the
-- Favor given and the blockers given, the session blocker when missing, in a
-- Special Session with the Betrayal Emergency and an Aid Request on the floor.
-- Votes cost 0, 4, and 12 Favor for 1 to 3.
local function Load(favor, blockers, inSession)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = { favor = favor or 100, blockers = blockers or SESSION } },
		congress = { inSession = inSession ~= false, maxVotes = 3, costs = { [0] = 0, 4, 12 }, proposals = { AID, BETRAYAL } },
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns a proposal vote request for player 0, then the submit request.
local function Requests(env, votes)
	local P = env.PlayerOperations
	local requests = {}

	for i, vote in ipairs(votes) do
		requests[i] = {
			player = 0,
			operation = P.WORLD_CONGRESS_DISCUSSION_VOTE,
			parameters = { [P.PARAM_PLAYER_ONE] = vote[1], [P.PARAM_PLAYER_TWO] = vote[2], [P.PARAM_WORLD_CONGRESS_VOTES] = vote[3] },
		}
	end

	requests[#requests + 1] = { player = 0, operation = P.WORLD_CONGRESS_SUBMIT_TURN, parameters = {} }

	return requests
end

describe("SentientSystems_VoteInCongress", function()
	it("votes for and against proposals by their sender and target, then submits", function()
		local env = Load()
		local votes = { { type = "WC_EMERGENCY_BACKSTAB", target = 10, votes = 3 }, { type = "WC_EMERGENCY_REQUEST_AID", target = 3, votes = 2, against = true } }

		assert.equal("{\"ok\":true}", env.SentientSystems_VoteInCongress(0, votes))
		assert.same(Requests(env, { { 0, 10, 3 }, { 3, 3, -2 } }), env.requests)
	end)

	it("submits with no votes, abstaining on every proposal", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_VoteInCongress(0, {}))
		assert.same(Requests(env, {}), env.requests)
	end)

	it("fails when the votes cost more Favor than the player has", function()
		local env = Load(15)
		local votes = { { type = "WC_EMERGENCY_BACKSTAB", target = 10, votes = 3 }, { type = "WC_EMERGENCY_REQUEST_AID", target = 3, votes = 2 } }

		assert.equal(Failed("These votes cost 16 Favor, and you have 15."), env.SentientSystems_VoteInCongress(0, votes))
		assert.same({}, env.requests)
	end)

	it("fails for a proposal that isn't on the floor, or one voted on twice", function()
		local env = Load()

		assert.equal(
			Failed("WC_EMERGENCY_BACKSTAB with target 4 isn't a proposal on the floor. Use one of WC_EMERGENCY_BACKSTAB with target 10, WC_EMERGENCY_REQUEST_AID with target 3."),
			env.SentientSystems_VoteInCongress(0, { { type = "WC_EMERGENCY_BACKSTAB", target = 4, votes = 1 } })
		)
		assert.equal(
			Failed("You voted on WC_EMERGENCY_BACKSTAB with target 10 twice. Give each proposal one vote."),
			env.SentientSystems_VoteInCongress(0, { { type = "WC_EMERGENCY_BACKSTAB", target = 10, votes = 1 }, { type = "WC_EMERGENCY_BACKSTAB", target = 10, votes = 2 } })
		)
		assert.same({}, env.requests)
	end)

	it("fails for a number of votes the screen doesn't allow", function()
		local env = Load()

		for _, count in ipairs({ 0, 4, 1.5 }) do
			assert.equal(
				Failed("Cast 1 to 3 votes on WC_EMERGENCY_BACKSTAB with target 10, not " .. count .. ". Leave a proposal out to abstain."),
				env.SentientSystems_VoteInCongress(0, { { type = "WC_EMERGENCY_BACKSTAB", target = 10, votes = count } })
			)
		end

		assert.same({}, env.requests)
	end)

	it("fails for votes that aren't a list of tables", function()
		local env = Load()

		assert.equal(Failed("The votes are a list of tables, each with a type, a target, and votes."), env.SentientSystems_VoteInCongress(0, "WC_EMERGENCY_BACKSTAB"))
		assert.equal(Failed("Each vote is a table with a type, a target, and votes."), env.SentientSystems_VoteInCongress(0, { "WC_EMERGENCY_BACKSTAB" }))
	end)

	it("fails out of session, or while the session blocker is down", function()
		assert.equal(Failed(NO_SESSION), Load(100, SESSION, false).SentientSystems_VoteInCongress(0, {}))
		assert.equal(Failed(NO_SESSION), Load(100, {}).SentientSystems_VoteInCongress(0, {}))
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("VoteInCongress failed: no player 3"), Load().SentientSystems_VoteInCongress(3, {}))
	end)
end)

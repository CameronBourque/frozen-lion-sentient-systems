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
			Failed("WC_EMERGENCY_BACKSTAB with target 4 isn't a resolution or a proposal on the floor. Use one of WC_EMERGENCY_BACKSTAB with target 10, WC_EMERGENCY_REQUEST_AID with target 3."),
			env.SentientSystems_VoteInCongress(0, { { type = "WC_EMERGENCY_BACKSTAB", target = 4, votes = 1 } })
		)
		assert.equal(
			Failed("You voted on WC_EMERGENCY_BACKSTAB with target 10 twice. Give each one vote."),
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

describe("SentientSystems_VoteInCongress in a regular session", function()
	local PATRONAGE = { type = "WC_RES_PATRONAGE", hash = -1934671345, targetType = "GreatPersonClassType", targets = { "LOC_GREAT_GENERAL", "LOC_GREAT_SCIENTIST" } }
	local TRADE = { type = "WC_RES_TRADE_TREATY", hash = -1283478990, targetType = "PlayerType", targets = { "0", "1", "2" } }

	-- Returns an environment with the actions loaded, where player 0 has the
	-- Favor given, in a regular session with two resolutions and the Betrayal
	-- Emergency on the floor.
	local function LoadRegular(favor)
		local env = Game.new()

		FakeGame.Install(env, {
			players = { [0] = { favor = favor or 100, blockers = SESSION } },
			congress = { inSession = true, maxVotes = 3, costs = { [0] = 0, 4, 12 }, resolutions = { PATRONAGE, TRADE }, proposals = { BETRAYAL } },
		})
		Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

		return env
	end

	local function ResolutionRequest(env, hash, votes, option, selection)
		local P = env.PlayerOperations

		return {
			player = 0,
			operation = P.WORLD_CONGRESS_RESOLUTION_VOTE,
			parameters = { [P.PARAM_RESOLUTION_TYPE] = hash, [P.PARAM_WORLD_CONGRESS_VOTES] = votes, [P.PARAM_RESOLUTION_OPTION] = option, [P.PARAM_RESOLUTION_SELECTION] = selection },
		}
	end

	local function Vote(type, option, target, votes)
		return { type = type, option = option, target = target, votes = votes }
	end

	it("sends each resolution's option and target, then the proposal votes, then submits", function()
		local env = LoadRegular()
		local votes = {
			{ type = "WC_EMERGENCY_BACKSTAB", target = 10, votes = 1, against = true },
			Vote("WC_RES_TRADE_TREATY", "B", 3, 2),
			Vote("WC_RES_PATRONAGE", "A", 1, 1),
		}

		assert.equal("{\"ok\":true}", env.SentientSystems_VoteInCongress(0, votes))

		local P = env.PlayerOperations

		assert.same({
			ResolutionRequest(env, -1283478990, 2, 2, 2),
			ResolutionRequest(env, -1934671345, 1, 1, 0),
			{ player = 0, operation = P.WORLD_CONGRESS_DISCUSSION_VOTE, parameters = { [P.PARAM_PLAYER_ONE] = 0, [P.PARAM_PLAYER_TWO] = 10, [P.PARAM_WORLD_CONGRESS_VOTES] = -1 } },
			{ player = 0, operation = P.WORLD_CONGRESS_SUBMIT_TURN, parameters = {} },
		}, env.requests)
	end)

	it("fails when a resolution has no vote, as the screen won't accept it", function()
		local env = LoadRegular()

		assert.equal(Failed("Vote on every resolution. WC_RES_TRADE_TREATY has no vote."), env.SentientSystems_VoteInCongress(0, { Vote("WC_RES_PATRONAGE", "A", 1, 1) }))
		assert.same({}, env.requests)
	end)

	it("fails for an option, a target, or a number of votes the screen doesn't offer", function()
		local env = LoadRegular()
		local cases = {
			{ Vote("WC_RES_PATRONAGE", "C", 1, 1), "Choose option A or B for WC_RES_PATRONAGE, not C." },
			{ Vote("WC_RES_PATRONAGE", 1, 1, 1), "Choose option A or B for WC_RES_PATRONAGE, not 1." },
			{ Vote("WC_RES_PATRONAGE", "A", 3, 1), "Choose a target from 1 to 2 for WC_RES_PATRONAGE, not 3. Use the index of one of its targets." },
			{ Vote("WC_RES_PATRONAGE", "A", 0, 1), "Choose a target from 1 to 2 for WC_RES_PATRONAGE, not 0. Use the index of one of its targets." },
			{ Vote("WC_RES_PATRONAGE", "A", 1, 4), "Cast 1 to 3 votes on WC_RES_PATRONAGE, not 4." },
		}

		for _, case in ipairs(cases) do
			assert.equal(Failed(case[2]), env.SentientSystems_VoteInCongress(0, { case[1], Vote("WC_RES_TRADE_TREATY", "A", 1, 1) }))
		end

		assert.equal(
			Failed("You voted on WC_RES_PATRONAGE twice. Give each one vote."),
			env.SentientSystems_VoteInCongress(0, { Vote("WC_RES_PATRONAGE", "A", 1, 1), Vote("WC_RES_PATRONAGE", "B", 2, 1) })
		)
		assert.same({}, env.requests)
	end)

	it("fails when the resolutions' votes cost more Favor than the player has", function()
		local env = LoadRegular(15)

		assert.equal(
			Failed("These votes cost 16 Favor, and you have 15."),
			env.SentientSystems_VoteInCongress(0, { Vote("WC_RES_PATRONAGE", "A", 1, 3), Vote("WC_RES_TRADE_TREATY", "A", 1, 2) })
		)
	end)
end)

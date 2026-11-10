local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

-- Beliefs: two free pantheon beliefs, one another player took, and a follower
-- belief.
local BELIEFS = {
	{ type = "BELIEF_RELIGIOUS_SETTLEMENTS" },
	{ type = "BELIEF_GOD_OF_THE_SEA" },
	{ type = "BELIEF_DESERT_FOLKLORE", taken = true },
	{ type = "BELIEF_FEED_THE_WORLD", class = "BELIEF_CLASS_FOLLOWER" },
}

-- Player 0 can found a pantheon.
local PLAYER = { canCreatePantheon = true }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0, whose data is given, and the beliefs.
local function Load(player)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = player or PLAYER }, beliefs = BELIEFS })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("SentientSystems_FoundPantheon", function()
	it("sends the pantheon chooser's request for the belief", function()
		local env = Load()
		local P = env.PlayerOperations
		local hash = env.GameInfo.Beliefs.BELIEF_RELIGIOUS_SETTLEMENTS.Hash

		assert.equal("{\"ok\":true}", env.SentientSystems_FoundPantheon(0, "BELIEF_RELIGIOUS_SETTLEMENTS"))
		assert.same({
			{ player = 0, operation = P.FOUND_PANTHEON, parameters = { [P.PARAM_BELIEF_TYPE] = hash, [P.PARAM_INSERT_MODE] = P.VALUE_EXCLUSIVE } },
		}, env.requests)
	end)

	it("fails for a player with a pantheon", function()
		local env = Load(With(PLAYER, { pantheon = "BELIEF_GOD_OF_THE_SEA" }))

		assert.equal(Failed("You have a pantheon already, BELIEF_GOD_OF_THE_SEA."), env.SentientSystems_FoundPantheon(0, "BELIEF_RELIGIOUS_SETTLEMENTS"))
		assert.same({}, env.requests)
	end)

	it("fails while the player can't found a pantheon", function()
		local env = Load({})

		assert.equal(
			Failed("You can't found a pantheon yet. The choices list a pantheon once you can."),
			env.SentientSystems_FoundPantheon(0, "BELIEF_RELIGIOUS_SETTLEMENTS")
		)
		assert.same({}, env.requests)
	end)

	it("fails for a type that is no belief, or no text", function()
		local env = Load()

		assert.equal(Failed("BELIEF_NOPE isn't a belief. Use a type from the pantheon choice."), env.SentientSystems_FoundPantheon(0, "BELIEF_NOPE"))
		assert.equal(Failed("nil isn't a belief. Use a type from the pantheon choice."), env.SentientSystems_FoundPantheon(0))
	end)

	it("fails for a belief of another class", function()
		local env = Load()

		assert.equal(
			Failed("BELIEF_FEED_THE_WORLD isn't a pantheon belief. Use a type from the pantheon choice."),
			env.SentientSystems_FoundPantheon(0, "BELIEF_FEED_THE_WORLD")
		)
		assert.same({}, env.requests)
	end)

	it("fails for a belief another player has", function()
		local env = Load()

		assert.equal(
			Failed("Another player has BELIEF_DESERT_FOLKLORE already. Use a type from the pantheon choice."),
			env.SentientSystems_FoundPantheon(0, "BELIEF_DESERT_FOLKLORE")
		)
		assert.same({}, env.requests)
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("FoundPantheon failed: no player 3"), Load().SentientSystems_FoundPantheon(3, "BELIEF_RELIGIOUS_SETTLEMENTS"))
	end)
end)

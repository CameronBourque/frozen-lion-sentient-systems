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

-- Beliefs a religion can take, of each class, and two it can't: one another
-- player took, and one of a class the religion has too many of.
local RELIGION_BELIEFS = {
	{ type = "BELIEF_RELIGIOUS_SETTLEMENTS" },
	{ type = "BELIEF_FEED_THE_WORLD", class = "BELIEF_CLASS_FOLLOWER" },
	{ type = "BELIEF_CHORAL_MUSIC", class = "BELIEF_CLASS_FOLLOWER" },
	{ type = "BELIEF_GURDWARA", class = "BELIEF_CLASS_WORSHIP" },
	{ type = "BELIEF_TITHE", class = "BELIEF_CLASS_FOUNDER" },
	{ type = "BELIEF_JUST_WAR", class = "BELIEF_CLASS_ENHANCER", taken = true },
	{ type = "BELIEF_PILGRIMAGE", class = "BELIEF_CLASS_FOUNDER", tooMany = true },
}
local RELIGIONS = {
	{ type = "RELIGION_PANTHEON", pantheon = true },
	{ type = "RELIGION_BUDDHISM" },
	{ type = "RELIGION_HINDUISM", founded = true },
	{ type = "RELIGION_CUSTOM_1", customName = true, name = "LOC_RELIGION_CUSTOM_1_NAME" },
}

-- Player 0 has a pantheon and two beliefs from a Great Prophet.
local FOUNDER = { pantheon = "BELIEF_RELIGIOUS_SETTLEMENTS", beliefsEarned = 2 }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0, whose data is given, the religions, and the beliefs, and the world
-- fields in extra.
local function LoadReligion(player, extra)
	local env = Game.new()
	local world = {
		players = { [0] = player or FOUNDER },
		beliefs = RELIGION_BELIEFS,
		religions = RELIGIONS,
		rename = true,
		text = { LOC_RELIGION_CUSTOM_1_NAME = "Custom Religion" },
	}

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the requests the religion screen sends to found the religion with the
-- name and add each belief.
local function ReligionRequests(env, religion, name, beliefs)
	local P = env.PlayerOperations
	local requests = {
		{
			player = 0,
			operation = P.FOUND_RELIGION,
			parameters = { [P.PARAM_RELIGION_TYPE] = env.GameInfo.Religions[religion].Hash, [P.PARAM_RELIGION_CUSTOM_NAME] = name, [P.PARAM_INSERT_MODE] = P.VALUE_EXCLUSIVE },
		},
	}

	for _, belief in ipairs(beliefs) do
		local parameters = { [P.PARAM_BELIEF_TYPE] = env.GameInfo.Beliefs[belief].Hash, [P.PARAM_INSERT_MODE] = P.VALUE_EXCLUSIVE }

		requests[#requests + 1] = { player = 0, operation = P.ADD_BELIEF, parameters = parameters }
	end

	return requests
end

describe("SentientSystems_FoundReligion", function()
	local BELIEFS_OK = { "BELIEF_FEED_THE_WORLD", "BELIEF_GURDWARA" }

	it("sends the religion screen's requests for the religion and each belief", function()
		local env = LoadReligion()

		assert.equal("{\"ok\":true}", env.SentientSystems_FoundReligion(0, "RELIGION_BUDDHISM", BELIEFS_OK))
		assert.same(ReligionRequests(env, "RELIGION_BUDDHISM", nil, BELIEFS_OK), env.requests)
	end)

	it("sends the player's name for a religion that asks for one", function()
		local env = LoadReligion()

		assert.equal("{\"ok\":true}", env.SentientSystems_FoundReligion(0, "RELIGION_CUSTOM_1", BELIEFS_OK, "Way of the Lion"))
		assert.same(ReligionRequests(env, "RELIGION_CUSTOM_1", "Way of the Lion", BELIEFS_OK), env.requests)
	end)

	it("sends the religion's own name when the game allows no renaming", function()
		local env = LoadReligion(nil, { rename = false })

		assert.equal("{\"ok\":true}", env.SentientSystems_FoundReligion(0, "RELIGION_CUSTOM_1", BELIEFS_OK))
		assert.same(ReligionRequests(env, "RELIGION_CUSTOM_1", "Custom Religion", BELIEFS_OK), env.requests)
	end)

	it("fails for a player who can't found a religion now", function()
		local cases = {
			{ With(FOUNDER, { religion = { type = "RELIGION_BUDDHISM", beliefs = BELIEFS_OK } }), "You have founded RELIGION_BUDDHISM already." },
			{ { beliefsEarned = 2 }, "Found a pantheon first. A religion needs one." },
			{ { pantheon = "BELIEF_RELIGIOUS_SETTLEMENTS", prophet = true }, "Activate your Great Prophet on a Holy Site first, with the found_religion order." },
			{ { pantheon = "BELIEF_RELIGIOUS_SETTLEMENTS" }, "You need a Great Prophet to found a religion." },
		}

		for _, case in ipairs(cases) do
			local env = LoadReligion(case[1])

			assert.equal(Failed(case[2]), env.SentientSystems_FoundReligion(0, "RELIGION_BUDDHISM", BELIEFS_OK))
			assert.same({}, env.requests)
		end
	end)

	it("fails for a religion the player can't found", function()
		local env = LoadReligion()

		assert.equal(
			Failed("Another player has founded RELIGION_HINDUISM already. Use a type from the religion choice."),
			env.SentientSystems_FoundReligion(0, "RELIGION_HINDUISM", BELIEFS_OK)
		)
		assert.equal(Failed("RELIGION_PANTHEON isn't a religion. Use a type from the religion choice."), env.SentientSystems_FoundReligion(0, "RELIGION_PANTHEON", BELIEFS_OK))
		assert.equal(Failed("nil isn't a religion. Use a type from the religion choice."), env.SentientSystems_FoundReligion(0, nil, BELIEFS_OK))
	end)

	it("fails for a name the religion can't take", function()
		local env = LoadReligion()

		assert.equal(Failed("RELIGION_CUSTOM_1 needs a name. Give one."), env.SentientSystems_FoundReligion(0, "RELIGION_CUSTOM_1", BELIEFS_OK, "  "))
		assert.equal(Failed("RELIGION_CUSTOM_1 needs a name. Give one."), env.SentientSystems_FoundReligion(0, "RELIGION_CUSTOM_1", BELIEFS_OK))
		assert.equal(
			Failed("RELIGION_BUDDHISM has a fixed name. Leave out the name."),
			env.SentientSystems_FoundReligion(0, "RELIGION_BUDDHISM", BELIEFS_OK, "Way of the Lion")
		)
	end)

	it("fails for beliefs the screen wouldn't take", function()
		local cases = {
			{ { "BELIEF_FEED_THE_WORLD" }, "Pick 2 beliefs, as the religion choice's picks says." },
			{ "BELIEF_FEED_THE_WORLD", "Pick 2 beliefs, as the religion choice's picks says." },
			{ { "BELIEF_FEED_THE_WORLD", "BELIEF_NOPE" }, "BELIEF_NOPE isn't a belief. Use a type from the religion choice." },
			{ { "BELIEF_FEED_THE_WORLD", "BELIEF_RELIGIOUS_SETTLEMENTS" }, "BELIEF_RELIGIOUS_SETTLEMENTS is a pantheon belief. Use a type from the religion choice." },
			{ { "BELIEF_FEED_THE_WORLD", "BELIEF_JUST_WAR" }, "Another player has BELIEF_JUST_WAR already. Use a type from the religion choice." },
			{ { "BELIEF_FEED_THE_WORLD", "BELIEF_PILGRIMAGE" }, "Your religion can't take another BELIEF_CLASS_FOUNDER belief." },
			{
				{ "BELIEF_GURDWARA", "BELIEF_FEED_THE_WORLD" },
				"A new religion's first belief is a follower belief, and BELIEF_GURDWARA is a BELIEF_CLASS_WORSHIP belief.",
			},
			{
				{ "BELIEF_FEED_THE_WORLD", "BELIEF_CHORAL_MUSIC" },
				"Pick one belief of each class. BELIEF_CHORAL_MUSIC is a second BELIEF_CLASS_FOLLOWER belief.",
			},
		}

		for _, case in ipairs(cases) do
			local env = LoadReligion()

			assert.equal(Failed(case[2]), env.SentientSystems_FoundReligion(0, "RELIGION_BUDDHISM", case[1]))
			assert.same({}, env.requests)
		end
	end)
end)

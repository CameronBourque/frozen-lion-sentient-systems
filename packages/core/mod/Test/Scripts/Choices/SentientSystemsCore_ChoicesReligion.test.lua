local FakeGame = require("FakeGame")
local Game = require("Game")

local BELIEFS = {
	{ type = "BELIEF_DANCE_OF_THE_AURORA", description = "LOC_BELIEF_DANCE_OF_THE_AURORA_DESCRIPTION" },
	{ type = "BELIEF_DESERT_FOLKLORE", description = "LOC_BELIEF_DESERT_FOLKLORE_DESCRIPTION", taken = true },
	{ type = "BELIEF_RELIGIOUS_COMMUNITY", class = "BELIEF_CLASS_FOUNDER", description = "" },
	{ type = "BELIEF_SACRED_PATH", description = "LOC_BELIEF_SACRED_PATH_DESCRIPTION" },
}

-- Returns the pantheon choice JSON for player 0, whose data is given, or nil when it is left out.
local function PantheonWith(player)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = player },
		beliefs = BELIEFS,
		text = { LOC_BELIEF_SACRED_PATH_DESCRIPTION = "Holy Site districts get +1 [ICON_Faith] Faith from adjacent Rainforest tiles." },
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"pantheon\":(%b{})")
end

describe("SentientSystems_GetPantheonChoices", function()
	it("lists the pantheon beliefs no player has taken, in the game's order", function()
		assert.equal(
			"{\"beliefs\":[{\"description\":\"LOC_BELIEF_DANCE_OF_THE_AURORA_DESCRIPTION\",\"type\":\"BELIEF_DANCE_OF_THE_AURORA\"},"
				.. "{\"description\":\"Holy Site districts get +1 [ICON_Faith] Faith from adjacent Rainforest tiles.\",\"type\":\"BELIEF_SACRED_PATH\"}]}",
			PantheonWith({ canCreatePantheon = true })
		)
	end)

	it("is left out while the player can't found a pantheon", function()
		assert.is_nil(PantheonWith({}))
	end)

	it("is left out once the player has a pantheon", function()
		assert.is_nil(PantheonWith({ canCreatePantheon = true, pantheon = "BELIEF_SACRED_PATH" }))
	end)
end)

local RELIGION_BELIEFS = {
	{ type = "BELIEF_GOD_OF_THE_SEA" },
	{ type = "BELIEF_TITHE", class = "BELIEF_CLASS_FOUNDER", description = "LOC_BELIEF_TITHE_DESCRIPTION" },
	{ type = "BELIEF_FEED_THE_WORLD", class = "BELIEF_CLASS_FOLLOWER", description = "LOC_BELIEF_FEED_THE_WORLD_DESCRIPTION" },
	{ type = "BELIEF_GURDWARA", class = "BELIEF_CLASS_WORSHIP", description = "LOC_BELIEF_GURDWARA_DESCRIPTION" },
	{ type = "BELIEF_CHORAL_MUSIC", class = "BELIEF_CLASS_FOLLOWER", description = "LOC_BELIEF_CHORAL_MUSIC_DESCRIPTION", taken = true },
	{ type = "BELIEF_CROSS_CULTURAL_DIALOGUE", class = "BELIEF_CLASS_FOUNDER", description = "", tooMany = true },
	{ type = "BELIEF_DEFENDER_OF_THE_FAITH", class = "BELIEF_CLASS_ENHANCER", description = "LOC_BELIEF_DEFENDER_OF_THE_FAITH_DESCRIPTION" },
}
local RELIGIONS = {
	{ type = "RELIGION_PANTHEON", pantheon = true },
	{ type = "RELIGION_BUDDHISM" },
	{ type = "RELIGION_HINDUISM", founded = true },
	{ type = "RELIGION_CUSTOM", customName = true },
}

-- Returns the religion choice JSON for player 0, whose data is given, in a world with the fields in
-- worldFields, or nil when it is left out.
local function ReligionWith(player, worldFields)
	local env = Game.new()
	local world = { players = { [0] = player }, beliefs = RELIGION_BELIEFS, religions = RELIGIONS }

	for key, value in pairs(worldFields or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"religion\":(%b{})")
end

local BELIEFS_JSON = "[{\"class\":\"BELIEF_CLASS_WORSHIP\",\"description\":\"LOC_BELIEF_GURDWARA_DESCRIPTION\",\"type\":\"BELIEF_GURDWARA\"},"
	.. "{\"class\":\"BELIEF_CLASS_FOUNDER\",\"description\":\"LOC_BELIEF_TITHE_DESCRIPTION\",\"type\":\"BELIEF_TITHE\"},"
	.. "{\"class\":\"BELIEF_CLASS_FOLLOWER\",\"description\":\"LOC_BELIEF_FEED_THE_WORLD_DESCRIPTION\",\"type\":\"BELIEF_FEED_THE_WORLD\"},"
	.. "{\"class\":\"BELIEF_CLASS_ENHANCER\",\"description\":\"LOC_BELIEF_DEFENDER_OF_THE_FAITH_DESCRIPTION\",\"type\":\"BELIEF_DEFENDER_OF_THE_FAITH\"}]"

describe("SentientSystems_GetReligionChoices", function()
	it("lists the religions no player has founded, and the beliefs on offer by class, before founding", function()
		assert.equal(
			"{\"beliefs\":" .. BELIEFS_JSON .. ",\"picks\":2,\"religions\":[{\"type\":\"RELIGION_BUDDHISM\"},{\"type\":\"RELIGION_CUSTOM\"}]}",
			ReligionWith({ pantheon = "BELIEF_GOD_OF_THE_SEA", beliefsEarned = 2 })
		)
	end)

	it("marks the religion the player must name, when the game allows renaming", function()
		local json = ReligionWith({ pantheon = "BELIEF_GOD_OF_THE_SEA", beliefsEarned = 2 }, { rename = true })

		assert.truthy(json:find("{\"customName\":true,\"type\":\"RELIGION_CUSTOM\"}", 1, true))
	end)

	it("gives only the beliefs to add once the religion is founded, with the picks left", function()
		local religion = { type = "RELIGION_BUDDHISM", beliefs = { "BELIEF_FEED_THE_WORLD" }, holyCity = 65536 }

		assert.equal(
			"{\"beliefs\":" .. BELIEFS_JSON .. ",\"picks\":1}",
			ReligionWith({ pantheon = "BELIEF_GOD_OF_THE_SEA", religion = religion, beliefsEarned = 2 })
		)
	end)

	it("is left out before a pantheon, before a belief is earned, and once every earned belief is in place", function()
		local religion = { type = "RELIGION_BUDDHISM", beliefs = { "BELIEF_FEED_THE_WORLD", "BELIEF_GURDWARA" }, holyCity = 65536 }

		assert.is_nil(ReligionWith({ beliefsEarned = 2 }))
		assert.is_nil(ReligionWith({ pantheon = "BELIEF_GOD_OF_THE_SEA" }))
		assert.is_nil(ReligionWith({ pantheon = "BELIEF_GOD_OF_THE_SEA", religion = religion }))
	end)
end)

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

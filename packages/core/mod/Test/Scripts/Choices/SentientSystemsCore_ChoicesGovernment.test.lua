local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the government choice JSON for player 0, whose government is given.
local function GovernmentWith(government)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = { government = government } } })
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"government\":(%b{})")
end

describe("SentientSystems_GetGovernmentChoices", function()
	it("gives the government and each slot in the game's order, with the policy in a filled slot", function()
		assert.equal(
			"{\"slots\":[{\"slot\":0,\"type\":\"SLOT_MILITARY\"},{\"policy\":\"POLICY_GOD_KING\",\"slot\":1,\"type\":\"SLOT_ECONOMIC\"},"
				.. "{\"slot\":2,\"type\":\"SLOT_MILITARY\"}],\"type\":\"GOVERNMENT_CHIEFDOM\"}",
			GovernmentWith({
				type = "GOVERNMENT_CHIEFDOM",
				slots = { { type = "SLOT_MILITARY" }, { type = "SLOT_ECONOMIC", policy = "POLICY_GOD_KING" }, { type = "SLOT_MILITARY" } },
			})
		)
	end)

	it("leaves out the type for a player with no government, before Code of Laws or in anarchy", function()
		assert.equal("{\"slots\":[]}", GovernmentWith(nil))
	end)
end)

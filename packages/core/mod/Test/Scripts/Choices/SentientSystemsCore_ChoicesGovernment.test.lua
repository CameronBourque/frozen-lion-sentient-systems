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

local SURVEY = { type = "POLICY_SURVEY", slot = "SLOT_MILITARY", description = "LOC_POLICY_SURVEY_DESCRIPTION" }
local AGOGE = { type = "POLICY_AGOGE", slot = "SLOT_MILITARY", description = "LOC_POLICY_AGOGE_DESCRIPTION", civic = "CIVIC_CRAFTSMANSHIP" }
local GOD_KING = { type = "POLICY_GOD_KING", slot = "SLOT_ECONOMIC", description = "LOC_POLICY_GOD_KING_DESCRIPTION" }
local CHIEFDOM = { type = "GOVERNMENT_CHIEFDOM", slots = { { type = "SLOT_MILITARY" }, { type = "SLOT_ECONOMIC", policy = "POLICY_GOD_KING" } } }

-- Returns the policy choice JSON for player 0, whose data is given, in a world with the fields in
-- worldFields.
local function PoliciesWith(player, worldFields)
	local env = Game.new()
	local world = { players = { [0] = player }, text = { LOC_POLICY_SURVEY_DESCRIPTION = "Double experience for recon units." } }

	for key, value in pairs(worldFields or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"policies\":(%b{})")
end

-- Returns a copy of CHIEFDOM with the fields in changes.
local function Chiefdom(changes)
	local copy = { type = CHIEFDOM.type, slots = CHIEFDOM.slots }

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

describe("SentientSystems_GetPolicyChoices", function()
	it("lists the policies the catalog shows by slot type, in type order, without the slotted one", function()
		assert.equal(
			"{\"canChange\":false,\"options\":{\"SLOT_MILITARY\":[{\"description\":\"LOC_POLICY_AGOGE_DESCRIPTION\",\"type\":\"POLICY_AGOGE\"},"
				.. "{\"description\":\"Double experience for recon units.\",\"type\":\"POLICY_SURVEY\"}]}}",
			PoliciesWith({ government = CHIEFDOM, policies = { SURVEY, GOD_KING, AGOGE } })
		)
	end)

	it("leaves out locked and obsolete policies, and the options when none is left", function()
		local locked = { type = "POLICY_ILKUM", slot = "SLOT_ECONOMIC", description = "", locked = true }
		local obsolete = { type = "POLICY_SURVEY", slot = "SLOT_MILITARY", description = "", obsolete = true }

		assert.equal("{\"canChange\":false}", PoliciesWith({ government = CHIEFDOM, policies = { locked, obsolete, GOD_KING } }))
	end)

	it("follows Gathering Storm's checks, which leave out banned and unslottable policies", function()
		local banned = { type = "POLICY_ILKUM", slot = "SLOT_ECONOMIC", description = "", banned = true }
		local unslottable = { type = "POLICY_SURVEY", slot = "SLOT_MILITARY", description = "", unslottable = true }

		assert.equal("{\"canChange\":false}", PoliciesWith({ government = CHIEFDOM, policies = { banned, unslottable } }, { expansion2 = true }))
		assert.equal("{\"canChange\":false}", PoliciesWith({ government = CHIEFDOM, policies = { { type = "POLICY_AGOGE", slot = "SLOT_MILITARY", description = "", locked = true } } }, { expansion2 = true }))
	end)

	it("can change after a civic or with an open slot, and marks the policies that civic unlocks as new", function()
		assert.equal(
			"{\"canChange\":true,\"options\":{\"SLOT_MILITARY\":[{\"description\":\"LOC_POLICY_AGOGE_DESCRIPTION\",\"new\":true,\"type\":\"POLICY_AGOGE\"}]}}",
			PoliciesWith({ government = Chiefdom({ civicThisTurn = "CIVIC_CRAFTSMANSHIP" }), policies = { AGOGE } })
		)
		assert.equal("{\"canChange\":true}", PoliciesWith({ government = Chiefdom({ slotsOpen = 1 }) }))
	end)

	it("can't change after a change this turn, or while the player can't act", function()
		assert.equal("{\"canChange\":false}", PoliciesWith({ government = Chiefdom({ slotsOpen = 1, changeMade = true }) }))
		assert.equal("{\"canChange\":false}", PoliciesWith({ government = Chiefdom({ slotsOpen = 1 }), noStrategicCommands = true }))
	end)

	it("gives the unlock with its gold cost, blocked with the screen's text when the player can't afford it", function()
		assert.equal("{\"canChange\":false,\"unlock\":{\"cost\":50,\"yield\":\"YIELD_GOLD\"}}", PoliciesWith({ government = Chiefdom({ unlockCost = 50 }), gold = 145 }))
		assert.equal(
			"{\"canChange\":false,\"unlock\":{\"blocked\":[\"LOC_GOVT_NEED_GOLD(50)\"],\"cost\":50,\"yield\":\"YIELD_GOLD\"}}",
			PoliciesWith({ government = Chiefdom({ unlockCost = 50 }), gold = 49 })
		)
	end)

	it("gives the unlock in faith under the faith rule", function()
		assert.equal(
			"{\"canChange\":false,\"unlock\":{\"blocked\":[\"LOC_GOVT_NEED_FAITH(50)\"],\"cost\":50,\"yield\":\"YIELD_FAITH\"}}",
			PoliciesWith({ government = Chiefdom({ unlockCost = 50 }), gold = 145, faith = 10 }, { unlockWithFaith = true })
		)
	end)

	it("blocks the unlock with no reason while the World Congress is in session", function()
		assert.equal(
			"{\"canChange\":false,\"unlock\":{\"blocked\":[],\"cost\":50,\"yield\":\"YIELD_GOLD\"}}",
			PoliciesWith({ government = Chiefdom({ unlockCost = 50 }), gold = 145 }, { expansion2 = true, congressInSession = true })
		)
		assert.equal("{\"canChange\":false,\"unlock\":{\"cost\":50,\"yield\":\"YIELD_GOLD\"}}", PoliciesWith({ government = Chiefdom({ unlockCost = 50 }), gold = 145 }, { expansion2 = true }))
	end)

	it("hides the unlock after a change this turn", function()
		assert.equal("{\"canChange\":false}", PoliciesWith({ government = Chiefdom({ unlockCost = 50, changeMade = true }), gold = 145 }))
	end)
end)

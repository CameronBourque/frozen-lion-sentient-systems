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

local CHIEFDOM_ROW = { type = "GOVERNMENT_CHIEFDOM", slots = { SLOT_MILITARY = 1, SLOT_ECONOMIC = 1 } }
local AUTOCRACY_ROW = {
	type = "GOVERNMENT_AUTOCRACY",
	civic = "CIVIC_POLITICAL_PHILOSOPHY",
	bonusType = "GOVERNMENTBONUS_WONDER_CONSTRUCTION",
	bonuses = { "LOC_GOVT_INHERENT_BONUS_AUTOCRACY", "LOC_GOVT_ACCUMULATED_BONUS_BRIEF_AUTOCRACY" },
	slots = { SLOT_MILITARY = 2, SLOT_ECONOMIC = 1, SLOT_DIPLOMATIC = 1, SLOT_WILDCARD = 1 },
	influence = { perTurn = 3, threshold = 100, envoys = 1 },
	favor = 1,
	legacyPercent = 10,
}

-- Returns the government options JSON for player 0, whose government is given, in a world with
-- Chiefdom and Autocracy and the fields in worldFields.
local function GovernmentsWith(government, worldFields, player)
	local env = Game.new()
	local world = { players = { [0] = player or {} }, governments = { CHIEFDOM_ROW, AUTOCRACY_ROW } }

	world.players[0].government = government

	for key, value in pairs(worldFields or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"governments\":(%b{})")
end

local CHIEFDOM_JSON = "{\"current\":true,\"influence\":{\"envoys\":1,\"perTurn\":1,\"threshold\":100},"
	.. "\"slots\":{\"SLOT_ECONOMIC\":1,\"SLOT_MILITARY\":1},\"type\":\"GOVERNMENT_CHIEFDOM\"}"
local AUTOCRACY_JSON = "{\"bonuses\":[\"LOC_GOVT_INHERENT_BONUS_AUTOCRACY\",\"LOC_GOVT_ACCUMULATED_BONUS_BRIEF_AUTOCRACY\"],"
	.. "\"influence\":{\"envoys\":1,\"perTurn\":3,\"threshold\":100},\"locked\":\"CIVIC_POLITICAL_PHILOSOPHY\","
	.. "\"slots\":{\"SLOT_DIPLOMATIC\":1,\"SLOT_ECONOMIC\":1,\"SLOT_MILITARY\":2,\"SLOT_WILDCARD\":1},\"type\":\"GOVERNMENT_AUTOCRACY\"}"

describe("SentientSystems_GetGovernmentOptions", function()
	it("lists every government in the game's order, the current one marked, a locked one with its civic", function()
		assert.equal(
			"{\"canChange\":false,\"options\":[" .. CHIEFDOM_JSON .. "," .. AUTOCRACY_JSON .. "]}",
			GovernmentsWith({ type = "GOVERNMENT_CHIEFDOM" })
		)
	end)

	it("adds the favor with Gathering Storm, and the legacy percent with legacy bonuses", function()
		local json = GovernmentsWith({ type = "GOVERNMENT_CHIEFDOM" }, { expansion2 = true, legacyBonuses = true })

		assert.truthy(json:find("\"favor\":1,\"influence\":{\"envoys\":1,\"perTurn\":3", 1, true))
		assert.truthy(json:find("\"favor\":0,\"influence\":{\"envoys\":1,\"perTurn\":1", 1, true))
		assert.truthy(json:find("\"legacyPercent\":10,", 1, true))
	end)

	it("gives a legacy percent of 0 to a government whose modifiers hold none", function()
		local env = Game.new()
		local autocracy = { type = "GOVERNMENT_AUTOCRACY", bonusType = "GOVERNMENTBONUS_WONDER_CONSTRUCTION", bonuses = { "", "" } }

		FakeGame.Install(env, { players = { [0] = {} }, governments = { autocracy }, legacyBonuses = true })
		Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

		assert.truthy(env.SentientSystems_GetChoices(0):find("\"legacyPercent\":0,", 1, true))
	end)

	it("gives the anarchy turns of another government, and leaves out the locked civic once unlocked", function()
		local json = GovernmentsWith({ type = "GOVERNMENT_CHIEFDOM", unlocked = { "GOVERNMENT_AUTOCRACY" }, anarchy = { GOVERNMENT_CHIEFDOM = 3, GOVERNMENT_AUTOCRACY = 2 } })

		assert.truthy(json:find("{\"anarchy\":2,\"bonuses\"", 1, true))
		assert.falsy(json:find("locked", 1, true))
		assert.truthy(json:find(CHIEFDOM_JSON, 1, true))
	end)

	it("can change after a civic, or with no government, unless a change was made or the player can't act", function()
		local function CanChange(government, player)
			government.canChangeAtAll = true

			return GovernmentsWith(government, nil, player):match("\"canChange\":(%a+)")
		end

		assert.equal("true", CanChange({ type = "GOVERNMENT_CHIEFDOM", civicThisTurn = "CIVIC_POLITICAL_PHILOSOPHY" }))
		assert.equal("true", CanChange({}))
		assert.equal("false", CanChange({ type = "GOVERNMENT_CHIEFDOM" }))
		assert.equal("false", CanChange({ governmentChangeMade = true }))
		assert.equal("false", CanChange({}, { noStrategicCommands = true }))
	end)

	it("gives the unlock only with a government in place and another unlocked, before a change", function()
		local unlock = "\"unlock\":{\"cost\":50,\"yield\":\"YIELD_GOLD\"}"
		local unlocked = { type = "GOVERNMENT_CHIEFDOM", unlocked = { "GOVERNMENT_AUTOCRACY" }, unlockCost = 50 }

		assert.truthy(GovernmentsWith(unlocked, nil, { gold = 145 }):find(unlock, 1, true))
		assert.falsy(GovernmentsWith({ type = "GOVERNMENT_CHIEFDOM", unlockCost = 50 }, nil, { gold = 145 }):find("unlock", 1, true))
		assert.falsy(GovernmentsWith({ unlocked = { "GOVERNMENT_CHIEFDOM", "GOVERNMENT_AUTOCRACY" }, unlockCost = 50 }, nil, { gold = 145 }):find("unlock", 1, true))

		unlocked.governmentChangeMade = true
		assert.falsy(GovernmentsWith(unlocked, nil, { gold = 145 }):find("unlock", 1, true))
	end)
end)

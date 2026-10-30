local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns a city-state with the ID's name, the leader given, the envoys by player ID, and the
-- suzerain.
local function CityState(name, inherit, envoys, suzerain)
	return { minor = { name = "LOC_CIVILIZATION_" .. name .. "_NAME", leader = "LEADER_MINOR_CIV_" .. name, inherit = inherit, envoys = envoys, suzerain = suzerain } }
end

-- Returns the envoys section JSON for player 0, in a world with the players given, and with
-- Gathering Storm when expansion2 is true.
local function EnvoysWith(players, expansion2)
	local env = Game.new()

	FakeGame.Install(env, {
		players = players,
		expansion2 = expansion2,
		text = { LOC_CIVILIZATION_SAMARKAND_NAME = "Samarkand", LOC_MINOR_CIV_TRADE_TRAIT_SMALL_INFLUENCE_BONUS = "+2 [ICON_Gold] Gold" },
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"envoys\":(%b{})")
end

describe("SentientSystems_GetEnvoyState", function()
	it("gives the envoy tokens and influence, with no city-states met", function()
		assert.equal(
			"{\"cityStates\":[],\"influence\":{\"envoys\":2,\"perTurn\":3,\"points\":40,\"threshold\":100},\"tokens\":1}",
			EnvoysWith({ [0] = { influence = { tokens = 1, points = 40, perTurn = 3, threshold = 100, envoys = 2 } } })
		)
	end)

	it("lists each met city-state with its kind, the player's envoys, and the envoys to be suzerain", function()
		local players = {
			[0] = { met = { 1, 12, 13 } },
			[1] = { met = { 0 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [0] = 2, [1] = 3 }, 1),
			[13] = CityState("SCIENTIFIC", nil, { [0] = 1 }),
			[14] = CityState("KUMASI", "LEADER_MINOR_CIV_TRADE", { [1] = 1 }),
		}

		assert.equal(
			"[{\"envoys\":2,\"influencedBy\":[{\"envoys\":3,\"player\":1},{\"envoys\":2,\"player\":0}],\"name\":\"Samarkand\",\"player\":12,\"suzerain\":1,\"suzerainNeeds\":4,\"type\":\"TRADE\"},"
				.. "{\"envoys\":1,\"influencedBy\":[{\"envoys\":1,\"player\":0}],\"name\":\"LOC_CIVILIZATION_SCIENTIFIC_NAME\",\"player\":13,\"suzerainNeeds\":3,\"type\":\"SCIENTIFIC\"}]",
			EnvoysWith(players):match("\"cityStates\":(%b[])")
		)
	end)

	it("needs only the player's own envoys while they are suzerain", function()
		local players = {
			[0] = { met = { 12 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [0] = 4 }, 0),
		}

		assert.truthy(EnvoysWith(players):find("\"suzerain\":0,\"suzerainNeeds\":4,", 1, true))
	end)

	it("hides a suzerain the player hasn't met", function()
		local players = {
			[0] = { met = { 12 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [2] = 3 }, 2),
		}

		assert.truthy(EnvoysWith(players):find("\"suzerainNeeds\":4,\"suzerainUnmet\":true,", 1, true))
	end)

	it("leaves out the kind of a leader with none, and the Free Cities", function()
		local freeCities = CityState("FREE_CITIES")

		freeCities.minor.cantReceive = true

		local players = {
			[0] = { met = { 12, 62 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_DEFAULT", {}),
			[62] = freeCities,
		}

		assert.equal(
			"{\"cityStates\":[{\"envoys\":0,\"influencedBy\":[],\"name\":\"Samarkand\",\"player\":12,\"suzerainNeeds\":3}],"
				.. "\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0}",
			EnvoysWith(players)
		)
	end)

	it("gives the bonuses of each kind of city-state met once", function()
		local players = {
			[0] = { met = { 12, 13 } },
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", {}),
			[13] = CityState("CAHOKIA", "LEADER_MINOR_CIV_TRADE", {}),
		}

		assert.equal(
			"{\"TRADE\":[\"+2 [ICON_Gold] Gold\",\"LOC_MINOR_CIV_TRADE_TRAIT_MEDIUM_INFLUENCE_BONUS\",\"LOC_MINOR_CIV_TRADE_TRAIT_LARGE_INFLUENCE_BONUS\"]}",
			EnvoysWith(players):match("\"bonuses\":(%b{})")
		)
	end)

	it("gives the suzerain bonus, its traits joined, and whether Gathering Storm turns it off", function()
		local samarkand = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", {})

		samarkand.minor.traits = { "Trading Domes.", "More gold." }
		samarkand.minor.uniqueDisabled = true

		local players = { [0] = { met = { 12 } }, [12] = samarkand }

		assert.truthy(EnvoysWith(players):find("\"suzerainBonus\":\"Trading Domes.[NEWLINE][NEWLINE]More gold.\",\"suzerainNeeds\":3,", 1, true))
		assert.truthy(EnvoysWith(players, true):find("\"suzerainBonus\":\"Trading Domes.[NEWLINE][NEWLINE]More gold.\",\"suzerainBonusDisabled\":true,", 1, true))
	end)

	it("lists the city-state's resources, and with Gathering Storm a strategic resource's amount per turn", function()
		local samarkand = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", {})

		samarkand.minor.resources = {
			{ type = "RESOURCE_SILK", amount = 1, exported = 1 },
			{ type = "RESOURCE_IRON", amount = 0, perTurn = 2 },
			{ type = "RESOURCE_SPICES", exported = 1 },
		}

		local players = { [0] = { met = { 12 } }, [12] = samarkand }

		assert.equal(
			"[{\"amount\":2,\"type\":\"RESOURCE_SILK\"},{\"amount\":1,\"type\":\"RESOURCE_SPICES\"}]",
			EnvoysWith(players):match("\"resources\":(%b[])")
		)
		assert.equal(
			"[{\"amount\":2,\"type\":\"RESOURCE_SILK\"},{\"amount\":2,\"type\":\"RESOURCE_IRON\"},{\"amount\":1,\"type\":\"RESOURCE_SPICES\"}]",
			EnvoysWith(players, true):match("\"resources\":(%b[])")
		)
	end)

	it("lists the quests the city-state gives the player", function()
		local samarkand = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", {})

		samarkand.minor.quests = {
			[0] = { { type = "QUEST_TRAIN_UNIT_TYPE", name = "Train a Spearman.", description = "Train a Spearman military unit.", reward = "[ICON_Envoy] 1 Envoy" } },
			[1] = { { type = "QUEST_ZONE_DISTRICT_TYPE", name = "Construct an Encampment.", description = "", reward = "" } },
		}

		assert.equal(
			"[{\"description\":\"Train a Spearman military unit.\",\"name\":\"Train a Spearman.\",\"reward\":\"[ICON_Envoy] 1 Envoy\",\"type\":\"QUEST_TRAIN_UNIT_TYPE\"}]",
			EnvoysWith({ [0] = { met = { 12 } }, [1] = {}, [12] = samarkand }):match("\"quests\":(%b[])")
		)
	end)

	it("lists the players with envoys there, most first, and hides those the player hasn't met", function()
		local players = {
			[0] = { met = { 2, 12 } },
			[1] = {},
			[2] = {},
			[3] = {},
			[12] = CityState("SAMARKAND", "LEADER_MINOR_CIV_TRADE", { [0] = 1, [1] = 1, [2] = 4, [3] = 2 }),
		}

		assert.equal(
			"[{\"envoys\":4,\"player\":2},{\"envoys\":2,\"unmet\":true},{\"envoys\":1,\"player\":0},{\"envoys\":1,\"unmet\":true}]",
			EnvoysWith(players):match("\"influencedBy\":(%b[])")
		)
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the proposals JSON of player 0, who is given the proposals.
local function ProposalsWith(proposals)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = { proposals = proposals }, [4] = {}, [5] = {} },
		text = { LOC_CITY_NAME_BAGACUM = "Bagacum" },
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"proposals\":(%b[])")
end

describe("SentientSystems_GetProposalState", function()
	it("lists what each side gives, with the turns of an item that lasts", function()
		local json = ProposalsWith({
			[4] = {
				items = {
					{ id = 2, type = "RESOURCES", from = 0, amount = 10, value = "RESOURCE_HORSES" },
					{ id = 3, type = "AGREEMENTS", from = 4, sub = "OPEN_BORDERS", duration = 20 },
					{ id = 4, type = "GOLD", from = 4, amount = 8 },
					{ id = 5, type = "GOLD", from = 4, amount = 3, duration = 30 },
				},
			},
		})

		assert.equal(
			"[{\"asks\":[{\"amount\":10,\"id\":2,\"kind\":\"resource\",\"resource\":\"RESOURCE_HORSES\"}],\"from\":4,\"gift\":false,"
				.. "\"offers\":[{\"agreement\":\"DIPLOACTION_OPEN_BORDERS\",\"id\":3,\"kind\":\"agreement\",\"turns\":20},"
				.. "{\"amount\":8,\"id\":4,\"kind\":\"gold\"},{\"amount\":3,\"id\":5,\"kind\":\"gold\",\"turns\":30}],\"valid\":true}]",
			json
		)
	end)

	it("links the items that come with a city to it", function()
		local json = ProposalsWith({
			[4] = {
				items = {
					{ id = 6, type = "CITIES", from = 0, value = 131073, sub = 2, name = "LOC_CITY_NAME_BAGACUM" },
					{ id = 7, type = "RESOURCES", from = 0, amount = 2, value = "RESOURCE_NITER", locked = true, parent = 6 },
					{ id = 9, type = "GREATWORK", from = 0, value = "GREATWORK_OVID_1", name = "LOC_GREATWORK_OVID_1_NAME", locked = true, parent = 6 },
				},
			},
		})

		assert.truthy(json:find("{\"city\":{\"id\":131073,\"owner\":0},\"id\":6,\"kind\":\"city\",\"name\":\"Bagacum\"},", 1, true))
		assert.truthy(json:find("\"id\":7,\"kind\":\"resource\",\"locked\":true,\"resource\":\"RESOURCE_NITER\",\"with\":6}", 1, true))
		assert.truthy(json:find("{\"greatWork\":\"GREATWORK_OVID_1\",\"id\":9,\"kind\":\"greatWork\",\"locked\":true,"
			.. "\"name\":\"LOC_GREATWORK_OVID_1_NAME\",\"with\":6}", 1, true))
	end)

	it("marks a city that is ceded back after an occupation", function()
		local json = ProposalsWith({ [4] = { items = { { id = 6, type = "CITIES", from = 4, value = 65536, sub = 1, name = "LOC_X" } } } })

		assert.truthy(json:find("\"cedeOccupied\":true", 1, true))
	end)

	it("gives the tech of a research agreement, the type of an alliance, and the target of a war", function()
		local json = ProposalsWith({
			[4] = {
				items = {
					{ id = 2, type = "AGREEMENTS", from = 4, sub = "RESEARCH_AGREEMENT", duration = 10, value = "TECH_WRITING" },
					{ id = 3, type = "AGREEMENTS", from = 4, sub = "ALLIANCE", value = "ALLIANCE_RESEARCH" },
					{ id = 4, type = "AGREEMENTS", from = 0, sub = "JOINT_WAR", value = 5, war = "WAR_FORMAL" },
				},
			},
		})

		assert.truthy(json:find("\"agreement\":\"DIPLOACTION_RESEARCH_AGREEMENT\",\"id\":2,\"kind\":\"agreement\",\"tech\":\"TECH_WRITING\",\"turns\":10}", 1, true))
		assert.truthy(json:find("\"agreement\":\"DIPLOACTION_ALLIANCE\",\"allianceType\":\"ALLIANCE_RESEARCH\",\"id\":3,", 1, true))
		assert.truthy(json:find("\"agreement\":\"DIPLOACTION_JOINT_WAR\",\"id\":4,\"kind\":\"agreement\",\"target\":5,\"turns\":0,\"war\":\"WAR_FORMAL\"}", 1, true))
	end)

	it("gives favor, and marks an item the other player won't accept", function()
		local json = ProposalsWith({ [4] = { items = { { id = 2, type = "FAVOR", from = 0, amount = 5, unacceptable = true } } } })

		assert.truthy(json:find("\"amount\":5,\"id\":2,\"kind\":\"favor\",\"unacceptable\":true}", 1, true))
	end)

	it("says whether the deal is a gift and whether it is valid", function()
		local json = ProposalsWith({ [4] = { gift = true, valid = false, items = { { id = 2, type = "GOLD", from = 4, amount = 1 } } } })

		assert.truthy(json:find("\"gift\":true,", 1, true))
		assert.truthy(json:find("\"valid\":false}", 1, true))
	end)

	it("leaves out a session the player started, and a deal with no items", function()
		assert.equal("[]", ProposalsWith({ [4] = { started = false, items = { { id = 2, type = "GOLD", from = 4, amount = 1 } } } }))
		assert.equal("[]", ProposalsWith({ [4] = { items = {} } }))
		assert.equal("[]", ProposalsWith({}))
	end)

	it("lists the proposals of each player in ID order", function()
		local json = ProposalsWith({
			[5] = { items = { { id = 2, type = "GOLD", from = 5, amount = 1 } } },
			[4] = { items = { { id = 2, type = "GOLD", from = 4, amount = 1 } } },
		})

		assert.truthy(json:find("\"from\":4,.*\"from\":5,"))
	end)
end)

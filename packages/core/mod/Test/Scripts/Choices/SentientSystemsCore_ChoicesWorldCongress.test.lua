local FakeGame = require("FakeGame")
local Game = require("Game")

local TEXT = {
	LOC_RESOLUTION_LUXURY_POLICY_NAME = "Luxury Policy",
	LOC_RESOLUTION_LUXURY_POLICY_A = "Improve luxury",
	LOC_RESOLUTION_LUXURY_POLICY_B = "Ban luxury",
	LOC_RESOURCE_MARBLE_NAME = "Marble",
	LOC_RESOURCE_SILK_NAME = "Silk",
	LOC_RESOLUTION_BORDER_NAME = "Border Control Treaty",
	LOC_RESOLUTION_BORDER_A = "Culture bombs",
	LOC_RESOLUTION_BORDER_B = "No growth",
	LOC_LEADER_TRAJAN_NAME = "Trajan",
	LOC_LEADER_QIN_NAME = "Qin",
	LOC_DIPLOPANEL_UNMET_PLAYER = "Unmet",
}

-- Returns the World Congress choice JSON for player 0, or nil when it is left out, with the congress
-- and blockers given.
local function ChoicesWith(congress, blockers, extra)
	local env = Game.new()
	local player = { favor = 196, met = { 1 }, playerName = "LOC_LEADER_TRAJAN_NAME", blockers = blockers }

	for key, value in pairs(extra or {}) do
		player[key] = value
	end

	FakeGame.Install(env, {
		players = { [0] = player, [1] = { playerName = "LOC_LEADER_QIN_NAME" }, [2] = { playerName = "LOC_LEADER_TRAJAN_NAME" } },
		congress = congress,
		text = TEXT,
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"worldCongress\":(%b{})")
end

local COSTS = { [0] = 0, 4, 12 }

local PROPOSAL = { TypeName = "WC_EMERGENCY_BACKSTAB", Name = "Betrayal Emergency", Description = "Punish them.", Sender = 0, Target = 10 }

describe("SentientSystems_GetWorldCongressChoices", function()
	it("offers a Special Session's proposals and the vote costs", function()
		assert.equal(
			"{\"favor\":196,\"proposals\":[{\"description\":\"Punish them.\",\"name\":\"Betrayal Emergency\",\"sender\":0,\"target\":10,"
				.. "\"type\":\"WC_EMERGENCY_BACKSTAB\"}],\"resolutions\":[],\"session\":\"special\",\"voteCosts\":[0,4]}",
			ChoicesWith({ inSession = true, maxVotes = 2, costs = COSTS, proposals = { PROPOSAL } }, { "ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION" })
		)
	end)

	it("offers a regular session's resolutions with their targets", function()
		local choice = ChoicesWith({
			inSession = true,
			maxVotes = 3,
			costs = COSTS,
			resolutions = {
				{ type = "RESOLUTION_LUXURY_POLICY", targetType = "ResourceType", targets = { "LOC_RESOURCE_MARBLE_NAME", "LOC_RESOURCE_SILK_NAME" }, favored = { 2, 1 } },
				{ type = "RESOLUTION_BORDER", targetType = "PlayerType", targets = { "0", "1", "2" }, disfavored = { 1 } },
			},
		}, { "ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION" })

		assert.truthy(choice:find("\"session\":\"regular\"", 1, true))
		assert.truthy(choice:find("\"voteCosts\":[0,4,12]", 1, true))
		assert.truthy(choice:find("\"name\":\"Luxury Policy\"", 1, true))
		assert.truthy(choice:find("\"options\":{\"A\":\"Improve luxury\",\"B\":\"Ban luxury\"}", 1, true))
		assert.truthy(choice:find("\"targets\":[{\"index\":1,\"name\":\"Marble\"},{\"index\":2,\"name\":\"Silk\"}]", 1, true))
		assert.truthy(choice:find("\"favored\":[1,2]", 1, true))
		assert.truthy(choice:find("{\"index\":1,\"name\":\"Trajan\",\"player\":0},{\"index\":2,\"name\":\"Qin\",\"player\":1},{\"index\":3,\"name\":\"Unmet\",\"player\":2}", 1, true))
		assert.truthy(choice:find("\"disfavored\":[1]", 1, true))
	end)

	it("offers the proposals it could call a Special Session for, out of a session", function()
		local choice = ChoicesWith({ available = { { TypeName = "WC_EMERGENCY_REQUEST_AID", Name = "Aid Request", Description = "Help.", Target = 0, cost = 30 },
			{ TypeName = "WC_EMERGENCY_BACKSTAB", Name = "Betrayal Emergency", Description = "Punish.", Target = 10, cost = 30, Disabled = true } } }, {})

		assert.equal(
			"{\"available\":[{\"cost\":30,\"description\":\"Punish.\",\"disabled\":true,\"name\":\"Betrayal Emergency\",\"target\":10,\"type\":\"WC_EMERGENCY_BACKSTAB\"},"
				.. "{\"cost\":30,\"description\":\"Help.\",\"disabled\":false,\"name\":\"Aid Request\",\"target\":0,\"type\":\"WC_EMERGENCY_REQUEST_AID\"}],\"favor\":196}",
			choice
		)
	end)

	it("offers the last results and the effects in effect at the results blocker", function()
		local choice = ChoicesWith({
			turnsLeft = 17,
			effects = {
				{ type = "RESOLUTION_LUXURY_POLICY", TargetType = "ResourceType", ChosenLabel = "B", ChosenOption = "LOC_RESOLUTION_LUXURY_POLICY_B", ChosenThing = "LOC_RESOURCE_MARBLE_NAME" },
			},
			review = {
				{
					type = "RESOLUTION_BORDER", TargetType = "PlayerType", ChosenLabel = "A", ChosenOption = "LOC_RESOLUTION_BORDER_A", ChosenThing = "1",
					PlayerSelections = {
						{ PlayerID = 1, OptionChosen = 1, ResolutionTarget = "1", Votes = 12 },
						{ PlayerID = 0, OptionChosen = 1, ResolutionTarget = "0", Votes = 10 },
						{ PlayerID = 2, OptionChosen = 2, ResolutionTarget = "-1", Votes = 1 },
					},
				},
				{ type = "RESOLUTION_LUXURY_POLICY", TargetType = "PlayerType", ChosenLabel = "B", ChosenOption = "LOC_RESOLUTION_LUXURY_POLICY_B", ChosenThing = "-1", PlayerSelections = {} },
			},
		}, { "ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK" })

		assert.truthy(choice:find("\"session\":\"review\"", 1, true))
		assert.truthy(choice:find("\"effects\":[{\"elected\":\"B\",\"name\":\"Luxury Policy\",\"target\":\"Marble\",\"text\":\"Ban luxury\",\"turnsLeft\":18}]", 1, true))
		assert.truthy(choice:find("{\"elected\":\"A\",\"name\":\"Border Control Treaty\",\"target\":\"Qin\",\"text\":\"Culture bombs\",\"voters\":[{\"name\":\"Trajan\",\"option\":\"A\",\"player\":0,\"target\":\"Trajan\",\"votes\":10},"
			.. "{\"name\":\"Qin\",\"option\":\"A\",\"player\":1,\"target\":\"Qin\",\"votes\":12},{\"name\":\"Unmet\",\"option\":\"B\",\"player\":2,\"target\":\"\",\"votes\":1}],\"votes\":{\"A\":22,\"B\":1}}", 1, true))
		assert.truthy(choice:find("\"target\":\"\"", 1, true))
	end)

	it("is left out with nothing to show, and reads a session only while its blocker is up", function()
		assert.is_nil(ChoicesWith({}, {}))
		assert.is_nil(ChoicesWith({ inSession = true, maxVotes = 2, costs = COSTS }, {}))
	end)
end)

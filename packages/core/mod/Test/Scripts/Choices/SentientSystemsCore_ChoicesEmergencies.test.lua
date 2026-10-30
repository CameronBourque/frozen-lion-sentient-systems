local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the emergency choice JSON for player 0, or nil when it is left out, with the emergencies
-- given as the player's and its blockers, the emergency blocker when missing.
local function ChoicesWith(emergencies, blockers)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = { emergencies = emergencies, blockers = blockers or { "ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION" } } },
		text = { LOC_EMERGENCY_NAME_CITY_STATE = "Capture City-State", LOC_CITY_HUNZA = "Hunza" },
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"emergencies\":(%b[])")
end

-- Returns a hostile emergency against player 9 that hasn't begun, with any field given.
local function Emergency(extra)
	local emergency = {
		type = "EMERGENCY_CAPTURE_CITY_STATE",
		hostile = true,
		waiting = true,
		TargetID = 9,
		TargetCityName = "LOC_CITY_HUNZA",
		NameText = "LOC_EMERGENCY_NAME_CITY_STATE",
		ShortDescriptionText = "A city-state was captured.",
		GoalDescription = "Liberate the city.",
		TurnsLeft = 30,
		MemberIDs = { 0, 4, -1 },
		GoalsTable = { { Name = "Liberate Hunza", Completed = false }, { Name = "", Completed = false } },
		TargetGoalsTable = { { Name = "Keep Hunza", Completed = false } },
		ScoreSourcesTable = { "+1 for each unit in the city" },
		BuffsText = { "+1 Movement" },
		ExtraBuffs = "Open borders.",
		MemberRewardsTextFirst = { "+1 Envoy" },
		MemberRewardsTextExtra = { "Gold" },
		ExtraRewards = "A relic.",
		TargetRewardsText = { "Target gold" },
	}

	for key, value in pairs(extra or {}) do
		emergency[key] = value
	end

	return emergency
end

describe("SentientSystems_GetEmergencyChoices", function()
	it("offers join and reject for an emergency that hasn't begun", function()
		assert.equal(
			"[{\"buffs\":[\"+1 Movement\",\"Open borders.\"],\"description\":\"A city-state was captured.\",\"goal\":\"Liberate the city.\","
				.. "\"goals\":[\"Liberate Hunza\"],\"hostile\":true,\"members\":[0,4],\"name\":\"Capture City-State\",\"options\":[\"join\",\"reject\"],"
				.. "\"rewards\":{\"members\":[\"+1 Envoy\",\"Gold\",\"A relic.\"],\"target\":[\"Target gold\"]},\"scoring\":[\"+1 for each unit in the city\"],"
				.. "\"target\":9,\"targetCity\":\"Hunza\",\"turnsLeft\":30,\"type\":\"EMERGENCY_CAPTURE_CITY_STATE\"}]",
			ChoicesWith({ Emergency() })
		)
	end)

	it("offers only acknowledge once it has begun", function()
		assert.truthy(ChoicesWith({ Emergency({ HasBegun = true }) }):find("\"options\":[\"acknowledge\"]", 1, true))
	end)

	it("shows the target's goals and no scoring to the target", function()
		local choice = ChoicesWith({ Emergency({ TargetID = 0 }) })

		assert.truthy(choice:find("\"goals\":[\"Keep Hunza\"]", 1, true))
		assert.is_nil(choice:find("\"scoring\"", 1, true))
	end)

	it("leaves out the target's rewards when it isn't hostile, and the city when it has none", function()
		local choice = ChoicesWith({ Emergency({ hostile = false, TargetCityName = "" }) })

		assert.truthy(choice:find("\"target\":[]", 1, true))
		assert.is_nil(choice:find("targetCity", 1, true))
	end)

	it("leaves out the buffs and scoring of a finished emergency", function()
		local choice = ChoicesWith({ Emergency({ TurnsLeft = -1 }) })

		assert.truthy(choice:find("\"buffs\":[]", 1, true))
		assert.truthy(choice:find("\"succeeded\":false", 1, true))
		assert.truthy(ChoicesWith({ Emergency({ TurnsLeft = -2, bSuccess = true }) }):find("\"succeeded\":true", 1, true))
		assert.is_nil(choice:find("\"scoring\"", 1, true))
	end)

	it("is left out with none waiting, or no match, and reads nothing without the blocker", function()
		assert.is_nil(ChoicesWith({ Emergency({ waiting = false }) }))
		assert.is_nil(ChoicesWith({}))
		assert.is_nil(ChoicesWith({ Emergency() }, {}))
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns a great person of the class and type given, with the fields in extra.
local function Person(name, extra)
	local person = { class = "GREAT_PERSON_CLASS_" .. name, type = "GREAT_PERSON_INDIVIDUAL_" .. name, era = "ERA_CLASSICAL", cost = 30 }

	for key, value in pairs(extra or {}) do
		person[key] = value
	end

	return person
end

-- Returns the great person choice JSON for player 0, or nil when it is left out, in a world with the
-- great people given and the world fields in extra.
local function ChoicesWith(greatPeople, extra)
	local env = Game.new()
	local world = { greatPeople = greatPeople, players = { [0] = {} } }

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"greatPeople\":(%b[])")
end

describe("SentientSystems_GetGreatPeopleChoices", function()
	it("lists the great people the player can recruit or pass, with the cost to pass", function()
		assert.equal(
			"[{\"passCost\":6,\"recruit\":true,\"type\":\"GREAT_PERSON_INDIVIDUAL_SCIENTIST\"},{\"passCost\":12,\"recruit\":false,\"type\":\"GREAT_PERSON_INDIVIDUAL_ENGINEER\"},"
				.. "{\"recruit\":true,\"type\":\"GREAT_PERSON_INDIVIDUAL_MERCHANT\"}]",
			ChoicesWith({
				Person("GENERAL"),
				Person("SCIENTIST", { canRecruit = true, passCost = 6 }),
				Person("ENGINEER", { passCost = 12 }),
				Person("MERCHANT", { canRecruit = true }),
				Person("WRITER", { canRecruit = true, claimed = true }),
			})
		)
	end)

	it("is left out with none to recruit or pass", function()
		assert.is_nil(ChoicesWith({ Person("GENERAL") }))
	end)

	it("follows the recruit and pass capabilities", function()
		local off = { CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT = true, CAPABILITY_GREAT_PEOPLE_CAN_REJECT = true }

		assert.is_nil(ChoicesWith({ Person("SCIENTIST", { canRecruit = true, passCost = 6 }) }, { offCapabilities = off }))
	end)
end)

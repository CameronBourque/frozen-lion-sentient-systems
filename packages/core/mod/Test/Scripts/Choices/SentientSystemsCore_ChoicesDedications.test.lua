local FakeGame = require("FakeGame")
local Game = require("Game")

local TEXT = {
	LOC_ERA_CLASSICAL_NAME = "Classical Era",
	LOC_MOMENT_CATEGORY_SCIENTIFIC = "Free Inquiry",
	LOC_MOMENT_CATEGORY_SCIENTIFIC_BONUS_GOLDEN_AGE = "Golden text",
	LOC_MOMENT_CATEGORY_SCIENTIFIC_BONUS_NORMAL_AGE = "Normal text",
	LOC_MOMENT_CATEGORY_SCIENTIFIC_BONUS_DARK_AGE = "Dark text",
	LOC_MOMENT_CATEGORY_CULTURAL = "Pen, Brush, and Voice",
}

-- Returns the dedication choice JSON for player 0, or nil when it is left out, with the era change
-- given as the player's dedications and its blockers, the dedication blocker when missing.
local function ChoicesWith(dedications, blockers)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = { dedications = dedications, blockers = blockers or { "ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE" } } },
		text = TEXT,
	})
	Game.run(env, "Scripts/Choices/SentientSystemsCore_Choices.lua")

	return env.SentientSystems_GetChoices(0):match("\"dedications\":(%b{})")
end

-- Returns the dedications of an era change with the age and any other field given.
local function Change(age, extra)
	local change = { era = "ERA_CLASSICAL", age = age, allowed = 1, options = { "SCIENTIFIC", "CULTURAL" } }

	for key, value in pairs(extra or {}) do
		change[key] = value
	end

	return change
end

describe("SentientSystems_GetDedicationChoices", function()
	it("offers the golden age text for each dedication", function()
		assert.equal(
			"{\"age\":\"golden\",\"era\":\"Classical Era\",\"options\":[{\"description\":\"Golden text\",\"name\":\"Free Inquiry\",\"type\":\"COMMEMORATION_SCIENTIFIC\"},"
				.. "{\"description\":\"LOC_MOMENT_CATEGORY_CULTURAL_BONUS_GOLDEN_AGE\",\"name\":\"Pen, Brush, and Voice\",\"type\":\"COMMEMORATION_CULTURAL\"}],\"picks\":1}",
			ChoicesWith(Change("golden"))
		)
	end)

	it("adds the normal text to the golden text for a player always allowed it", function()
		assert.truthy(ChoicesWith(Change("golden", { alwaysNormal = true })):find("\"description\":\"Golden text[NEWLINE]Normal text\"", 1, true))
	end)

	it("offers the golden text and several picks in a heroic age", function()
		local choice = ChoicesWith(Change("heroic", { allowed = 3 }))

		assert.truthy(choice:find("\"age\":\"heroic\"", 1, true))
		assert.truthy(choice:find("\"description\":\"Golden text\"", 1, true))
		assert.truthy(choice:find("\"picks\":3", 1, true))
	end)

	it("offers the dark text in a dark age", function()
		local choice = ChoicesWith(Change("dark"))

		assert.truthy(choice:find("\"age\":\"dark\"", 1, true))
		assert.truthy(choice:find("\"description\":\"Dark text\"", 1, true))
	end)

	it("offers the normal text in a normal age", function()
		local choice = ChoicesWith(Change("normal"))

		assert.truthy(choice:find("\"age\":\"normal\"", 1, true))
		assert.truthy(choice:find("\"description\":\"Normal text\"", 1, true))
	end)

	it("is left out without picks or options, and reads nothing without the blocker", function()
		assert.is_nil(ChoicesWith(Change("golden", { allowed = 0 })))
		assert.is_nil(ChoicesWith(Change("golden", { options = {} })))
		assert.is_nil(ChoicesWith(Change("golden"), {}))
	end)
end)

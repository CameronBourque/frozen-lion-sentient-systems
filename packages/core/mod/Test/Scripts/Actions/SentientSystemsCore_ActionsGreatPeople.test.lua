local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

-- Great people on offer: Aryabhata, whom player 0 can recruit or pass,
-- Siddhartha Gautama, whom they can patronize with faith, and Themistocles,
-- whom they can't earn.
local ARYABHATA = { class = "GREAT_PERSON_CLASS_SCIENTIST", type = "GREAT_PERSON_INDIVIDUAL_ARYABHATA", era = "ERA_CLASSICAL", cost = 30, canRecruit = true, passCost = 6 }
local SIDDHARTHA = {
	class = "GREAT_PERSON_CLASS_PROPHET",
	type = "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA",
	era = "ERA_CLASSICAL",
	cost = 30,
	gold = { cost = 620 },
	faith = { cost = 430, can = true },
}
local THEMISTOCLES = {
	class = "GREAT_PERSON_CLASS_ADMIRAL",
	type = "GREAT_PERSON_INDIVIDUAL_THEMISTOCLES",
	era = "ERA_CLASSICAL",
	cost = 30,
	cantEarn = "You must have a coastal city center or a Harbor district in order to spawn a Great Admiral.",
}
local GREAT_PEOPLE = { ARYABHATA, SIDDHARTHA, THEMISTOCLES, With(SIDDHARTHA, { type = "GREAT_PERSON_INDIVIDUAL_MOSES", claimed = true }) }

-- Player 0 has 2 prophet points.
local PLAYER = { greatPeoplePoints = { GREAT_PERSON_CLASS_PROPHET = { points = 2 } } }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 and the great people, and the world fields in extra.
local function Load(greatPeople, extra)
	local env = Game.new()
	local world = { players = { [0] = PLAYER }, greatPeople = greatPeople or GREAT_PEOPLE }

	for key, value in pairs(extra or {}) do
		world[key] = value
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the request the screen sends for the operation and the great person,
-- with the yield's name for patronage.
local function Request(env, operation, typeName, yield)
	local P = env.PlayerOperations
	local parameters = { [P.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = env.GameInfo.GreatPersonIndividuals[typeName].Index }

	if yield ~= nil then
		parameters[P.PARAM_YIELD_TYPE] = env.YieldTypes[yield]
	end

	return { player = 0, operation = P[operation], parameters = parameters }
end

describe("SentientSystems_RecruitGreatPerson and SentientSystems_PassGreatPerson", function()
	it("send the screen's request for a great person the player has the points for", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_RecruitGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_ARYABHATA"))
		assert.equal("{\"ok\":true}", env.SentientSystems_PassGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_ARYABHATA"))
		assert.same({
			Request(env, "RECRUIT_GREAT_PERSON", "GREAT_PERSON_INDIVIDUAL_ARYABHATA"),
			Request(env, "REJECT_GREAT_PERSON", "GREAT_PERSON_INDIVIDUAL_ARYABHATA"),
		}, env.requests)
	end)

	it("fail with the cost and the points for a great person the player can't claim yet", function()
		local env = Load()

		assert.equal(
			Failed("You can't recruit GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA yet. It costs 30 points, and you have 2."),
			env.SentientSystems_RecruitGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA")
		)
		assert.equal(
			Failed("You can't pass GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA yet. It costs 30 points, and you have 2."),
			env.SentientSystems_PassGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA")
		)
		assert.same({}, env.requests)
	end)

	it("fail with the screen's text for a great person the player can't earn", function()
		assert.equal(
			Failed("You can't claim GREAT_PERSON_INDIVIDUAL_THEMISTOCLES. " .. THEMISTOCLES.cantEarn),
			Load().SentientSystems_RecruitGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_THEMISTOCLES")
		)
	end)

	it("fail for a great person who isn't on offer, or no great person", function()
		local env = Load()

		assert.equal(
			Failed("GREAT_PERSON_INDIVIDUAL_MOSES isn't on offer. Use a type from the great people state."),
			env.SentientSystems_RecruitGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_MOSES")
		)
		assert.equal(Failed("nil isn't a great person. Use a type from the great people state."), env.SentientSystems_PassGreatPerson(0))
	end)

	it("fail when the game turns the button off", function()
		local env = Load(nil, { offCapabilities = { CAPABILITY_GREAT_PEOPLE_CAN_REJECT = true } })

		assert.equal(Failed("This game doesn't let players pass great people."), env.SentientSystems_PassGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_ARYABHATA"))
		assert.same({}, env.requests)
	end)
end)

describe("SentientSystems_PatronizeGreatPerson", function()
	it("sends the screen's request with the yield", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA", "faith"))
		assert.same({ Request(env, "PATRONIZE_GREAT_PERSON", "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA", "FAITH") }, env.requests)
	end)

	it("fails with the cost of patronage the player can't afford", function()
		assert.equal(
			Failed("You can't afford GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA with gold. It costs 620."),
			Load().SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA", "gold")
		)
	end)

	it("fails for a great person the player has the points for", function()
		assert.equal(
			Failed("You have the points for GREAT_PERSON_INDIVIDUAL_ARYABHATA, so recruit or pass them instead."),
			Load().SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_ARYABHATA", "gold")
		)
	end)

	it("fails with the screen's text for a great person the player can't earn", function()
		assert.equal(
			Failed("You can't claim GREAT_PERSON_INDIVIDUAL_THEMISTOCLES. " .. THEMISTOCLES.cantEarn),
			Load().SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_THEMISTOCLES", "faith")
		)
	end)

	it("fails for a yield the game turns off", function()
		local env = Load(nil, { offCapabilities = { CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH = true } })

		assert.equal(
			Failed("The game offers no patronage of GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA with faith."),
			env.SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA", "faith")
		)
	end)

	it("fails while Gathering Storm's World Congress is in session", function()
		local env = Load(nil, { expansion2 = true, congressInSession = true })

		assert.equal(
			Failed("The World Congress is in session. Patronize after it ends."),
			env.SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA", "faith")
		)
		assert.same({}, env.requests)
	end)

	it("fails for a yield that isn't gold or faith, or a great person not on offer", function()
		local env = Load()

		assert.equal(Failed("Patronize with gold or faith, not culture."), env.SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_SIDDHARTHA_GAUTAMA", "culture"))
		assert.equal(
			Failed("GREAT_PERSON_INDIVIDUAL_NOPE isn't a great person. Use a type from the great people state."),
			env.SentientSystems_PatronizeGreatPerson(0, "GREAT_PERSON_INDIVIDUAL_NOPE", "gold")
		)
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- The yields JSON for a city with every yield at 0.
local NO_YIELDS = "\"yields\":{\"culture\":0,\"faith\":0,\"food\":0,\"gold\":0,\"production\":0,\"science\":0}"

-- The amenities, defense, districts, and growth JSON for a content city with no amenities,
-- districts, or housing, that neither grows nor starves, and a garrison at full health.
local NO_GROWTH = "\"amenities\":{\"have\":0,\"mood\":\"HAPPINESS_CONTENT\",\"need\":0},\"defense\":{\"garrison\":{\"max\":200,\"value\":200},\"strength\":0},\"districts\":[],\"growth\":{\"foodSurplus\":0,\"housing\":0},"

local ROME = { id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3 }

-- Returns an environment with the state script loaded into a fake game built from world.
local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env
end

-- Returns a copy of city with the fields in changes.
local function With(city, changes)
	local copy = {}

	for key, value in pairs(city) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

describe("SentientSystems_GetCityStates", function()
	it("lists each city's ID, name, position, and population", function()
		local env = Load({
			players = { [0] = { cities = { ROME, { id = 131072, name = "LOC_CITY_NAME_ANTIUM", x = 20, y = 10, population = 1 } } } },
			text = { LOC_CITY_NAME_ROME = "Rome", LOC_CITY_NAME_ANTIUM = "Antium" },
		})

		assert.equal(
			"{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[{" .. NO_GROWTH .. "\"id\":65536,\"name\":\"Rome\",\"population\":3,\"x\":17,\"y\":14," .. NO_YIELDS .. "},"
				.. "{" .. NO_GROWTH .. "\"id\":131072,\"name\":\"Antium\",\"population\":1,\"x\":20,\"y\":10," .. NO_YIELDS .. "}],\"envoys\":{\"cityStates\":[],\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0},\"greatPeople\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"tiles\":[],\"units\":[]}",
			env.SentientSystems_GetState(0)
		)
	end)

	it("lists only the given player's cities", function()
		local env = Load({
			players = { [0] = { cities = { ROME } }, [1] = { cities = { { id = 65537, name = "Uruk", x = 10, y = 10, population = 5 } } } },
		})

		assert.equal("{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[{" .. NO_GROWTH .. "\"id\":65537,\"name\":\"Uruk\",\"population\":5,\"x\":10,\"y\":10," .. NO_YIELDS .. "}],\"envoys\":{\"cityStates\":[],\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0},\"greatPeople\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"tiles\":[],\"units\":[]}", env.SentientSystems_GetState(1))
	end)

	it("escapes a city name with quotes", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { name = "The \"Big\" City" }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"name\":\"The \\\"Big\\\" City\"", 1, true))
	end)

	it("adds the current production with its turns left", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { production = { type = "UNIT_SLINGER", turnsLeft = 2 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"production\":{\"turnsLeft\":2,\"type\":\"UNIT_SLINGER\"}", 1, true))
	end)

	it("leaves out production when the city produces nothing", function()
		local env = Load({ players = { [0] = { cities = { ROME } } } })

		assert.is_nil(env.SentientSystems_GetState(0):find("production\":{", 1, true))
	end)

	it("leaves out the type of a production that GameInfo.Types doesn't know", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { production = { hash = 77, turnsLeft = 3 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"production\":{\"turnsLeft\":3}", 1, true))
	end)

	it("adds each yield, rounded down to one decimal place as the city panel shows it", function()
		local env = Load({
			players = { [0] = { cities = { With(ROME, {
				yields = { FOOD = 9, PRODUCTION = 6, GOLD = -2.55, SCIENCE = 3.5, CULTURE = 3.8984375, FAITH = 0 },
			}) } } },
		})

		assert.truthy(env.SentientSystems_GetState(0):find(
			"\"yields\":{\"culture\":3.8,\"faith\":0,\"food\":9,\"gold\":-2.6,\"production\":6,\"science\":3.5}", 1, true))
	end)

	it("adds the city's defense, as its banner shows it", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, {
			defense = { strength = 12.6, garrison = { damage = 50, max = 200 }, walls = { damage = 10, max = 100 } },
		}) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find(
			"\"defense\":{\"garrison\":{\"max\":200,\"value\":150},\"strength\":13,\"walls\":{\"max\":100,\"value\":90}}", 1, true))
	end)

	it("adds the food surplus and the turns until the city grows", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { foodSurplus = 3.25, housing = 6, turnsUntilGrowth = 2 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"growth\":{\"foodSurplus\":3.2,\"housing\":6,\"turnsUntilGrowth\":2}", 1, true))
	end)

	it("adds the turns until a starving city loses a citizen", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { foodSurplus = -2, turnsUntilStarvation = 4 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"growth\":{\"foodSurplus\":-2,\"housing\":0,\"turnsUntilLoss\":4}", 1, true))
	end)

	it("rounds housing down to one decimal place", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { housing = 4.5 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"housing\":4.5", 1, true))
	end)

	it("adds the amenities the city has and needs, and its mood", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { amenities = 1, amenitiesNeeded = 3, happiness = 2 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"amenities\":{\"have\":1,\"mood\":\"HAPPINESS_UNHAPPY\",\"need\":3}", 1, true))
	end)

	it("leaves out a mood that GameInfo.Happinesses doesn't have", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { happiness = 9 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"amenities\":{\"have\":0,\"need\":0}", 1, true))
	end)

	it("adds loyalty, its most, and its change per turn, rounded to the nearest tenth", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { loyalty = { value = 87.46, max = 100, perTurn = -2.35 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"loyalty\":{\"max\":100,\"perTurn\":-2.3,\"value\":87.5}", 1, true))
	end)

	it("leaves out loyalty in a game without it", function()
		local env = Load({ players = { [0] = { cities = { ROME } } } })

		assert.is_nil(env.SentientSystems_GetState(0):find("loyalty", 1, true))
	end)

	it("adds each district with its position and its built buildings", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { districts = {
			{ type = "DISTRICT_CITY_CENTER", x = 17, y = 14, buildings = { { type = "BUILDING_MONUMENT" }, { type = "BUILDING_PALACE" } } },
			{ type = "DISTRICT_CAMPUS", x = 18, y = 14, buildings = { { type = "BUILDING_LIBRARY", pillaged = true } } },
		} }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find(
			"\"districts\":[{\"buildings\":[{\"pillaged\":false,\"type\":\"BUILDING_MONUMENT\"},{\"pillaged\":false,\"type\":\"BUILDING_PALACE\"}],"
				.. "\"complete\":true,\"pillaged\":false,\"type\":\"DISTRICT_CITY_CENTER\",\"x\":17,\"y\":14},"
				.. "{\"buildings\":[{\"pillaged\":true,\"type\":\"BUILDING_LIBRARY\"}],"
				.. "\"complete\":true,\"pillaged\":false,\"type\":\"DISTRICT_CAMPUS\",\"x\":18,\"y\":14}]",
			1, true))
	end)

	it("marks a district that isn't built yet, and a pillaged district", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { districts = {
			{ type = "DISTRICT_CAMPUS", x = 18, y = 14, complete = false },
			{ type = "DISTRICT_HOLY_SITE", x = 16, y = 14, pillaged = true },
		} }) } } } })
		local state = env.SentientSystems_GetState(0)

		assert.truthy(state:find("\"complete\":false,\"pillaged\":false,\"type\":\"DISTRICT_CAMPUS\"", 1, true))
		assert.truthy(state:find("\"complete\":true,\"pillaged\":true,\"type\":\"DISTRICT_HOLY_SITE\"", 1, true))
	end)

	it("leaves out a building that isn't built yet", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { districts = {
			{ type = "DISTRICT_CITY_CENTER", x = 17, y = 14, buildings = { { type = "BUILDING_MONUMENT" }, { type = "BUILDING_GRANARY", built = false } } },
		} }) } } } })
		local state = env.SentientSystems_GetState(0)

		assert.truthy(state:find("BUILDING_MONUMENT", 1, true))
		assert.is_nil(state:find("BUILDING_GRANARY", 1, true))
	end)

end)

-- Returns player 0's first city.
local function FirstCity(env)
	for _, city in env.Players[0]:GetCities():Members() do
		return city
	end
end

describe("FakeGame", function()
	it("raises an error for turns left on a production the city doesn't have", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { production = { type = "UNIT_SLINGER", turnsLeft = 2 } }) } } } })
		local city = FirstCity(env)

		assert.has_error(function()
			city:GetBuildQueue():GetTurnsLeft("UNIT_SCOUT")
		end)
	end)

	it("raises an error for a yield type the game doesn't have", function()
		local env = Load({ players = { [0] = { cities = { ROME } } } })
		local city = FirstCity(env)

		assert.has_error(function()
			city:GetYield(99)
		end, "no yield type 99")
	end)
end)

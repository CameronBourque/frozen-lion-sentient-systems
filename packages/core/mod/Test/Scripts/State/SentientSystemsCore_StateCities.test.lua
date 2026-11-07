local FakeGame = require("FakeGame")
local Game = require("Game")

-- The scoreboard of a world with one player, ID 0, who has not met anyone.
local SCOREBOARD = "[{\"categories\":[{\"name\":\"LOC_CATEGORY_CIVICS_NAME\",\"score\":0,\"type\":\"CATEGORY_CIVICS\"},{\"name\":\"LOC_CATEGORY_EMPIRE_NAME\",\"score\":0,\"type\":\"CATEGORY_EMPIRE\"},{\"name\":\"LOC_CATEGORY_GREAT_PEOPLE_NAME\",\"score\":0,\"type\":\"CATEGORY_GREAT_PEOPLE\"},{\"name\":\"LOC_CATEGORY_RELIGION_NAME\",\"score\":0,\"type\":\"CATEGORY_RELIGION\"},{\"name\":\"LOC_CATEGORY_TECH_NAME\",\"score\":0,\"type\":\"CATEGORY_TECH\"},{\"name\":\"LOC_CATEGORY_WONDER_NAME\",\"score\":0,\"type\":\"CATEGORY_WONDER\"},{\"name\":\"LOC_CATEGORY_ERA_SCORE_NAME\",\"score\":0,\"type\":\"CATEGORY_ERA_SCORE\"}],\"culture\":0,\"faith\":0,\"gold\":0,\"military\":0,\"player\":0,\"science\":0,\"score\":0}]"

-- The scoreboard of player 1 in a world with players 0 and 1, who have not met.
local SCOREBOARD_OF_1 = "[{\"categories\":[{\"name\":\"LOC_CATEGORY_CIVICS_NAME\",\"score\":0,\"type\":\"CATEGORY_CIVICS\"},{\"name\":\"LOC_CATEGORY_EMPIRE_NAME\",\"score\":0,\"type\":\"CATEGORY_EMPIRE\"},{\"name\":\"LOC_CATEGORY_GREAT_PEOPLE_NAME\",\"score\":0,\"type\":\"CATEGORY_GREAT_PEOPLE\"},{\"name\":\"LOC_CATEGORY_RELIGION_NAME\",\"score\":0,\"type\":\"CATEGORY_RELIGION\"},{\"name\":\"LOC_CATEGORY_TECH_NAME\",\"score\":0,\"type\":\"CATEGORY_TECH\"},{\"name\":\"LOC_CATEGORY_WONDER_NAME\",\"score\":0,\"type\":\"CATEGORY_WONDER\"},{\"name\":\"LOC_CATEGORY_ERA_SCORE_NAME\",\"score\":0,\"type\":\"CATEGORY_ERA_SCORE\"}],\"score\":0},{\"categories\":[{\"name\":\"LOC_CATEGORY_CIVICS_NAME\",\"score\":0,\"type\":\"CATEGORY_CIVICS\"},{\"name\":\"LOC_CATEGORY_EMPIRE_NAME\",\"score\":0,\"type\":\"CATEGORY_EMPIRE\"},{\"name\":\"LOC_CATEGORY_GREAT_PEOPLE_NAME\",\"score\":0,\"type\":\"CATEGORY_GREAT_PEOPLE\"},{\"name\":\"LOC_CATEGORY_RELIGION_NAME\",\"score\":0,\"type\":\"CATEGORY_RELIGION\"},{\"name\":\"LOC_CATEGORY_TECH_NAME\",\"score\":0,\"type\":\"CATEGORY_TECH\"},{\"name\":\"LOC_CATEGORY_WONDER_NAME\",\"score\":0,\"type\":\"CATEGORY_WONDER\"},{\"name\":\"LOC_CATEGORY_ERA_SCORE_NAME\",\"score\":0,\"type\":\"CATEGORY_ERA_SCORE\"}],\"culture\":0,\"faith\":0,\"gold\":0,\"military\":0,\"player\":1,\"science\":0,\"score\":0}]"

-- The yields JSON for a city with every yield at 0.
local NO_YIELDS = "\"yields\":{\"culture\":0,\"faith\":0,\"food\":0,\"gold\":0,\"production\":0,\"science\":0}"

-- The amenities, defense, districts, and growth JSON for a content city with no
-- amenities, districts, or housing, that neither grows nor starves, and a
-- garrison at full health.
local NO_GROWTH = "\"amenities\":{\"have\":0,\"mood\":\"HAPPINESS_CONTENT\",\"need\":0,\"warWeariness\":0},\"defense\":{\"garrison\":{\"max\":200,\"value\":200},\"strength\":0},\"districts\":[],\"growth\":{\"foodSurplus\":0,\"housing\":0,\"rate\":\"normal\"},"

local ROME = { id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3 }

local function Load(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env
end

-- Returns a state without its player's income and resources, which have tests
-- of their own.
local function WithoutIncome(state)
	return (state:gsub("\"income\":%b{},", ""):gsub("\"resources\":%b[],", ""))
end

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

-- The victories of a world with one player, ID 0, who has not met anyone.
local VICTORIES = "{\"culture\":[{\"culturePerTurn\":0,\"domesticTourists\":0,\"player\":0,\"progress\":0,\"requiredTourists\":0,\"tourismPerTurn\":0,\"visitingTourists\":0}],\"domination\":[{\"military\":0,\"player\":0,\"progress\":0}],\"religion\":[{\"cities\":0,\"faithPerTurn\":0,\"player\":0,\"progress\":0}],\"science\":[{\"player\":0,\"progress\":0,\"sciencePerTurn\":0,\"stages\":[{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"district\",\"type\":\"DISTRICT_SPACEPORT\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_EARTH_SATELLITE\"}]},{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MOON_LANDING\"}]},{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_REACTOR\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HABITATION\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HYDROPONICS\"}]}],\"techs\":0}]}"

-- The victories of player 1 in a world with players 0 and 1, who have not met.
local VICTORIES_OF_1 = "{\"culture\":[{\"domesticTourists\":0,\"requiredTourists\":1,\"touristsFromYou\":0,\"unmet\":true,\"visitingTourists\":0},{\"culturePerTurn\":0,\"domesticTourists\":0,\"player\":1,\"progress\":0,\"requiredTourists\":1,\"tourismPerTurn\":0,\"visitingTourists\":0}],\"domination\":[{\"unmet\":true},{\"military\":0,\"player\":1,\"progress\":0}],\"religion\":[{\"unmet\":true},{\"cities\":0,\"faithPerTurn\":0,\"player\":1,\"progress\":0}],\"science\":[{\"unmet\":true},{\"player\":1,\"progress\":0,\"sciencePerTurn\":0,\"stages\":[{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"district\",\"type\":\"DISTRICT_SPACEPORT\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_EARTH_SATELLITE\"}]},{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MOON_LANDING\"}]},{\"done\":false,\"progress\":0,\"tasks\":[{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_REACTOR\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HABITATION\"},{\"done\":false,\"kind\":\"project\",\"type\":\"PROJECT_LAUNCH_MARS_HYDROPONICS\"}]}],\"techs\":0}]}"

describe("SentientSystems_GetCityStates", function()
	it("lists each city's ID, name, position, and population", function()
		local env = Load({
			players = { [0] = { cities = { ROME, { id = 131072, name = "LOC_CITY_NAME_ANTIUM", x = 20, y = 10, population = 1 } } } },
			text = { LOC_CITY_NAME_ROME = "Rome", LOC_CITY_NAME_ANTIUM = "Antium" },
		})

		assert.equal(
			"{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[{" .. NO_GROWTH .. "\"id\":65536,\"name\":\"Rome\",\"population\":3,\"religion\":{\"outwardPressure\":0,\"present\":[]},\"x\":17,\"y\":14," .. NO_YIELDS .. "},"
				.. "{" .. NO_GROWTH .. "\"id\":131072,\"name\":\"Antium\",\"population\":1,\"religion\":{\"outwardPressure\":0,\"present\":[]},\"x\":20,\"y\":10," .. NO_YIELDS .. "}],\"diplomacy\":[],\"envoys\":{\"cityStates\":[],\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0},\"espionage\":{\"capacity\":0,\"captives\":[],\"cities\":[],\"history\":[],\"operatives\":[]},\"greatPeople\":[],\"greatWorks\":{\"buildings\":[],\"provides\":[],\"slots\":[],\"spaces\":0,\"works\":0},\"player\":{\"culture\":0,\"faith\":{\"balance\":0,\"perTurn\":0},\"gold\":{\"balance\":0,\"perTurn\":0},\"science\":0,\"tourism\":0},\"proposals\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"scoreboard\":" .. SCOREBOARD .. ",\"tiles\":[],\"trade\":{\"incoming\":[],\"outgoing\":[],\"tourismBonus\":25},\"units\":[],\"victories\":" .. VICTORIES .. "}",
			WithoutIncome(env.SentientSystems_GetState(0))
		)
	end)

	it("gives a city's religions with their followers, the pressure each turn and in all, and its majority", function()
		local env = Load({
			players = { [0] = { cities = { With(ROME, {
				majority = "RELIGION_SHINTO",
				outwardPressure = 2,
				religions = {
					{ followers = 4 },
					{ type = "RELIGION_SHINTO", followers = 7, pressure = 20, totalPressure = 981.5 },
					{ type = "RELIGION_ISLAM", followers = 0, pressure = 3.6, totalPressure = 28 },
				},
			}) } } },
		})

		assert.truthy(env.SentientSystems_GetState(0):find("\"religion\":{\"majority\":\"RELIGION_SHINTO\",\"outwardPressure\":2,\"present\":["
			.. "{\"followers\":4,\"type\":\"RELIGION_PANTHEON\"},"
			.. "{\"followers\":7,\"pressure\":20,\"totalPressure\":982,\"type\":\"RELIGION_SHINTO\"},"
			.. "{\"followers\":0,\"pressure\":4,\"totalPressure\":28,\"type\":\"RELIGION_ISLAM\"}]}", 1, true))
	end)

	it("leaves out the majority while no religion has the most followers", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { religions = { { followers = 4 }, { type = "RELIGION_SHINTO", followers = 1, pressure = 8.4, totalPressure = 114.5 } } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"religion\":{\"outwardPressure\":0,\"present\":[{\"followers\":4,\"type\":\"RELIGION_PANTHEON\"},{\"followers\":1,\"pressure\":8,\"totalPressure\":115,\"type\":\"RELIGION_SHINTO\"}]}", 1, true))
	end)

	it("gives the religion a city will convert to and in how many turns", function()
		local env = Load({
			players = { [0] = { cities = { With(ROME, {
				religions = { { type = "RELIGION_TAOISM", followers = 5, pressure = 28, totalPressure = 100 } },
				converting = { type = "RELIGION_TAOISM", turns = 8 },
			}) } } },
		})

		assert.truthy(env.SentientSystems_GetState(0):find("\"converting\":{\"turns\":8,\"type\":\"RELIGION_TAOISM\"}", 1, true))
	end)

	it("leaves out the conversion of a city that is not about to convert", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { religions = { { type = "RELIGION_TAOISM", followers = 5 } }, converting = { type = "RELIGION_TAOISM", turns = 0 } }) } } } })

		assert.is_nil(env.SentientSystems_GetState(0):find("converting", 1, true))
		assert.is_nil(Load({ players = { [0] = { cities = { ROME } } } }).SentientSystems_GetState(0):find("converting", 1, true))
	end)

	it("gives a city's power as the Power tab shows it", function()
		local env = Load({
			players = { [0] = { cities = { With(ROME, { power = {
				free = 2,
				required = 7,
				powered = false,
				freeSources = { { name = "Solar", power = 2 } },
				requiredSources = { { name = "Factory", power = 2 }, { name = "Stock Exchange", power = 3 }, { name = "Food Market", power = 1 }, { name = "Airport", power = 1 } },
			} }) } } },
		})

		assert.truthy(env.SentientSystems_GetState(0):find("\"power\":{\"generated\":[],"
			.. "\"required\":7,"
			.. "\"requiredBy\":[{\"name\":\"Factory\",\"power\":2},{\"name\":\"Stock Exchange\",\"power\":3},{\"name\":\"Food Market\",\"power\":1},{\"name\":\"Airport\",\"power\":1}],"
			.. "\"sources\":[{\"name\":\"Solar\",\"power\":2}],\"status\":\"unpowered\",\"usable\":2}", 1, true))
	end)

	it("says a city is powered when it is fully powered, and counts temporary power and a project", function()
		local function Power(power)
			return Load({ players = { [0] = { cities = { With(ROME, { power = power }) } } } }).SentientSystems_GetState(0)
		end

		local powered = Power({ free = 6, temporary = 1.25, required = 6, freeSources = { { name = "Hydroelectric", power = 6 } }, temporarySources = { { name = "Policy", power = 1.25 } } })

		assert.truthy(powered:find("\"sources\":[{\"name\":\"Hydroelectric\",\"power\":6},{\"name\":\"Policy\",\"power\":1.3}],\"status\":\"powered\",\"usable\":7.3", 1, true))
		assert.truthy(Power({ free = 0, required = 3, project = true }):find("\"status\":\"powered\",\"usable\":3", 1, true))
	end)

	it("says no power is needed when nothing needs it, and leaves out the power without Gathering Storm", function()
		assert.truthy(Load({ players = { [0] = { cities = { With(ROME, { power = {} }) } } } }).SentientSystems_GetState(0):find("\"status\":\"none\",\"usable\":0", 1, true))
		assert.is_nil(Load({ players = { [0] = { cities = { ROME } } } }).SentientSystems_GetState(0):find("\"power\":", 1, true))
	end)

	it("lists only the given player's cities", function()
		local env = Load({
			players = { [0] = { cities = { ROME } }, [1] = { cities = { { id = 65537, name = "Uruk", x = 10, y = 10, population = 5 } } } },
		})

		assert.equal("{\"blockers\":{\"list\":[],\"units\":[]},\"cities\":[{" .. NO_GROWTH .. "\"id\":65537,\"name\":\"Uruk\",\"population\":5,\"religion\":{\"outwardPressure\":0,\"present\":[]},\"x\":10,\"y\":10," .. NO_YIELDS .. "}],\"diplomacy\":[],\"envoys\":{\"cityStates\":[],\"influence\":{\"envoys\":1,\"perTurn\":0,\"points\":0,\"threshold\":50},\"tokens\":0},\"espionage\":{\"capacity\":0,\"captives\":[],\"cities\":[],\"history\":[],\"operatives\":[]},\"greatPeople\":[],\"greatWorks\":{\"buildings\":[],\"provides\":[],\"slots\":[],\"spaces\":0,\"works\":0},\"player\":{\"culture\":0,\"faith\":{\"balance\":0,\"perTurn\":0},\"gold\":{\"balance\":0,\"perTurn\":0},\"science\":0,\"tourism\":0},\"proposals\":[],\"religion\":{\"pantheonFaith\":25},\"rivals\":{\"cities\":[],\"units\":[]},\"scoreboard\":" .. SCOREBOARD_OF_1 .. ",\"tiles\":[],\"trade\":{\"incoming\":[],\"outgoing\":[],\"tourismBonus\":25},\"units\":[],\"victories\":" .. VICTORIES_OF_1 .. "}", WithoutIncome(env.SentientSystems_GetState(1)))
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

		assert.truthy(env.SentientSystems_GetState(0):find("\"growth\":{\"foodSurplus\":3.2,\"housing\":6,\"rate\":\"normal\",\"turnsUntilGrowth\":2}", 1, true))
	end)

	it("adds the turns until a starving city loses a citizen", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { foodSurplus = -2, turnsUntilStarvation = 4 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"growth\":{\"foodSurplus\":-2,\"housing\":0,\"rate\":\"normal\",\"turnsUntilLoss\":4}", 1, true))
	end)

	it("rounds housing down to one decimal place", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { housing = 4.5 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"housing\":4.5", 1, true))
	end)

	it("adds the amenities the city has and needs, and its mood", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { amenities = 1, amenitiesNeeded = 3, happiness = 2 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"amenities\":{\"have\":1,\"mood\":\"HAPPINESS_UNHAPPY\",\"need\":3,\"warWeariness\":0}", 1, true))
	end)

	it("leaves out a mood that GameInfo.Happinesses doesn't have", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { happiness = 9 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"amenities\":{\"have\":0,\"need\":0,\"warWeariness\":0}", 1, true))
	end)

	it("adds the growth rate status, halted, slowed, accelerated, or normal", function()
		local function Rate(growth, occupied)
			local env = Load({ players = { [0] = { cities = { With(ROME, { growth = growth, occupied = occupied }) } } } })

			return env.SentientSystems_GetState(0):match("\"rate\":\"(%a+)\"")
		end

		assert.equal("normal", Rate({}))
		assert.equal("halted", Rate({ housingModifier = 0 }))
		assert.equal("halted", Rate({}, true))
		assert.equal("slowed", Rate({ housingModifier = 0.5 }))
		assert.equal("slowed", Rate({ housingModifier = 0.25, happinessModifier = 0.2 }))
		assert.equal("accelerated", Rate({ housingModifier = 1, happinessModifier = 0.2 }))
	end)

	it("adds the amenities lost to war weariness", function()
		local env = Load({ players = { [0] = { cities = { With(ROME, { growth = { warWeariness = 2 } }) } } } })

		assert.truthy(env.SentientSystems_GetState(0):find("\"warWeariness\":2}", 1, true))
	end)

	it("adds the city's governor, and leaves it out for none or without Rise and Fall", function()
		local function State(governor)
			return Load({ players = { [0] = { cities = { With(ROME, { governor = governor }) } } } }).SentientSystems_GetState(0)
		end

		assert.truthy(State({ type = "GOVERNOR_THE_MERCHANT", established = true }):find("\"governor\":{\"established\":true,\"type\":\"GOVERNOR_THE_MERCHANT\"}", 1, true))
		assert.truthy(State({ type = "GOVERNOR_THE_MERCHANT" }):find("\"governor\":{\"established\":false,", 1, true))
		assert.falsy(State(false):find("\"governor\"", 1, true))
		assert.falsy(State(nil):find("\"governor\"", 1, true))
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

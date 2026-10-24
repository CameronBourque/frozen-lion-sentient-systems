-- A fake of the game's Lua API for tests, with players, their cities and districts, Map.GetPlot,
-- GameInfo.Types, GameInfo.Districts, GameInfo.Buildings, GameInfo.Happinesses, YieldTypes, and
-- Locale. It has only the calls the core mod makes. Example:
-- local env = Game.new()
-- FakeGame.Install(env, {
-- 	players = { [0] = { cities = { {
-- 		id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3,
-- 		growth = { foodSurplus = 3, housing = 6, turnsUntilGrowth = 2, amenities = 2, amenitiesNeeded = 2, happiness = 4 },
-- 		production = { type = "UNIT_SLINGER", turnsLeft = 2 },
-- 		yields = { FOOD = 9, PRODUCTION = 6 },
-- 		districts = { { type = "DISTRICT_CITY_CENTER", x = 17, y = 14, buildings = { { type = "BUILDING_MONUMENT" } } } },
-- 	} } } },
-- 	text = { LOC_CITY_NAME_ROME = "Rome" },
-- })
-- env.Players[0]:GetCities():Members() then lists the one city.

local FakeGame = {}

-- A list with Members(), as the game's city and unit lists have. Members() returns an iterator, as
-- in "for i, city in player:GetCities():Members() do".
local function List(items)
	return {
		Members = function()
			return ipairs(items)
		end,
	}
end

-- The width of the fake map, for plot indexes.
local MAP_WIDTH = 100

-- Returns the plot index of x and y, as Map.GetPlot(x, y):GetIndex() does.
local function PlotIndex(x, y)
	return y * MAP_WIDTH + x
end

-- GameInfo.Happinesses, by index, as in the game.
local HAPPINESSES = {
	[0] = { HappinessType = "HAPPINESS_REVOLT" },
	{ HappinessType = "HAPPINESS_UNREST" },
	{ HappinessType = "HAPPINESS_UNHAPPY" },
	{ HappinessType = "HAPPINESS_DISPLEASED" },
	{ HappinessType = "HAPPINESS_CONTENT" },
	{ HappinessType = "HAPPINESS_HAPPY" },
	{ HappinessType = "HAPPINESS_ECSTATIC" },
}

-- The YieldTypes values, as in the game.
local YIELD_TYPES = { FOOD = 0, PRODUCTION = 1, GOLD = 2, SCIENCE = 3, CULTURE = 4, FAITH = 5 }

-- A city from data. data.production is { type, turnsLeft }, or { hash, turnsLeft } for a hash that
-- GameInfo.Types doesn't know, or nil for nothing in production. data.yields maps a YieldTypes
-- name to its amount, and a missing yield is 0. data.growth has foodSurplus, housing, amenities,
-- and amenitiesNeeded, each 0 when missing, happiness, an index in GameInfo.Happinesses that is 4,
-- content, when missing, and turnsUntilGrowth and turnsUntilStarvation, which are -1 when missing,
-- as in the game. data.loyalty has value, max, and perTurn. Without it, the city has no
-- GetCulturalIdentity, as in a game without the Rise and Fall expansion. data.districts lists each
-- district with type, x, y, complete, which is true when missing, pillaged, and buildings. Each
-- building has type, built, which is true when missing, and pillaged. hashes maps each production
-- type to its hash, and indexes maps each district and building type to its GameInfo index.
local function City(data, hashes, indexes)
	local production = data.production
	local hash = production and (production.hash or hashes[production.type]) or 0
	local growth = data.growth or {}
	local loyalty = data.loyalty
	local districts = {}
	-- Each building by its index, and the indexes at each plot.
	local buildings, buildingsAt = {}, {}

	for i, district in ipairs(data.districts or {}) do
		local plotIndex = PlotIndex(district.x, district.y)

		buildingsAt[plotIndex] = {}

		for _, building in ipairs(district.buildings or {}) do
			local index = indexes[building.type]

			buildings[index] = building
			buildingsAt[plotIndex][#buildingsAt[plotIndex] + 1] = index
		end

		districts[i] = {
			GetType = function()
				return indexes[district.type]
			end,
			GetX = function()
				return district.x
			end,
			GetY = function()
				return district.y
			end,
			IsComplete = function()
				return district.complete ~= false
			end,
			IsPillaged = function()
				return district.pillaged == true
			end,
		}
	end

	local city = {
		GetDistricts = function()
			return List(districts)
		end,
		GetBuildings = function()
			return {
				GetBuildingsAtLocation = function(_, plotIndex)
					return buildingsAt[plotIndex] or {}
				end,
				HasBuilding = function(_, index)
					return buildings[index].built ~= false
				end,
				IsPillaged = function(_, index)
					return buildings[index].pillaged == true
				end,
			}
		end,
		GetGrowth = function()
			return {
				GetFoodSurplus = function()
					return growth.foodSurplus or 0
				end,
				GetHousing = function()
					return growth.housing or 0
				end,
				GetAmenities = function()
					return growth.amenities or 0
				end,
				GetAmenitiesNeeded = function()
					return growth.amenitiesNeeded or 0
				end,
				GetHappiness = function()
					return growth.happiness or 4
				end,
				GetTurnsUntilGrowth = function()
					return growth.turnsUntilGrowth or -1
				end,
				GetTurnsUntilStarvation = function()
					return growth.turnsUntilStarvation or -1
				end,
			}
		end,
		GetBuildQueue = function()
			return {
				GetCurrentProductionTypeHash = function()
					return hash
				end,
				-- The game takes a hash or a type name.
				GetTurnsLeft = function(_, typeOrHash)
					assert(production and (typeOrHash == hash or typeOrHash == production.type), "no production " .. tostring(typeOrHash))

					return production.turnsLeft
				end,
			}
		end,
		GetYield = function(_, yieldType)
			for name, value in pairs(YIELD_TYPES) do
				if value == yieldType then
					return (data.yields or {})[name] or 0
				end
			end

			error("no yield type " .. tostring(yieldType))
		end,
		GetID = function()
			return data.id
		end,
		GetName = function()
			return data.name
		end,
		GetX = function()
			return data.x
		end,
		GetY = function()
			return data.y
		end,
		GetPopulation = function()
			return data.population
		end,
	}

	if loyalty ~= nil then
		function city.GetCulturalIdentity()
			return {
				GetLoyalty = function()
					return loyalty.value
				end,
				GetMaxLoyalty = function()
					return loyalty.max
				end,
				GetLoyaltyPerTurn = function()
					return loyalty.perTurn
				end,
			}
		end
	end

	return city
end

local function Player(id, data, hashes, indexes)
	local cities = {}

	for i, city in ipairs(data.cities or {}) do
		cities[i] = City(city, hashes, indexes)
	end

	return {
		GetID = function()
			return id
		end,
		GetCities = function()
			return List(cities)
		end,
	}
end

-- Sets Players, GameInfo, YieldTypes, and Locale in env from world. world.players maps each player
-- ID to its data. world.text maps each LOC_ key to its text. Locale.Lookup returns any other key as
-- it is. GameInfo.Types holds each production type in world, under a made-up hash.
function FakeGame.Install(env, world)
	local hashes, indexes = {}, {}
	local count = 0

	env.GameInfo = { Types = {}, Districts = {}, Buildings = {}, Happinesses = HAPPINESSES }
	env.YieldTypes = YIELD_TYPES
	env.Map = {
		GetPlot = function(x, y)
			return {
				GetIndex = function()
					return PlotIndex(x, y)
				end,
			}
		end,
	}

	-- Adds a type to a GameInfo table under the next index, as the game numbers its rows.
	local function AddRow(tableName, column, typeName)
		if indexes[typeName] == nil then
			local index = #env.GameInfo[tableName] + (env.GameInfo[tableName][0] and 1 or 0)
			local row = { Index = index }

			row[column] = typeName
			env.GameInfo[tableName][index] = row
			indexes[typeName] = index
		end
	end

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			local typeName = city.production and city.production.type

			if typeName ~= nil and hashes[typeName] == nil then
				count = count + 1

				local hash = 1000000 + count

				hashes[typeName] = hash
				env.GameInfo.Types[hash] = { Type = typeName }
			end

			for _, district in ipairs(city.districts or {}) do
				AddRow("Districts", "DistrictType", district.type)

				for _, building in ipairs(district.buildings or {}) do
					AddRow("Buildings", "BuildingType", building.type)
				end
			end
		end
	end

	env.Players = {}

	for id, data in pairs(world.players or {}) do
		env.Players[id] = Player(id, data, hashes, indexes)
	end

	local text = world.text or {}

	env.Locale = {
		Lookup = function(key)
			return text[key] or key
		end,
	}
end

return FakeGame

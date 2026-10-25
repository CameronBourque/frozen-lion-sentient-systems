-- A fake of the game's Lua API for tests, with players, their cities, districts, and units, the
-- map's plots, PlayersVisibility, PlayerManager.GetAlive, DefenseTypes, UnitManager.CanStartCommand
-- for promotions, EndTurnBlockingTypes, NotificationManager.GetAllEndTurnBlocking, GameInfo.Types,
-- GameInfo.Districts, GameInfo.Buildings, GameInfo.Units, GameInfo.UnitPromotions,
-- GameInfo.Terrains, GameInfo.Features, GameInfo.Resources, GameInfo.Improvements, GameInfo.Routes,
-- GameInfo.Happinesses, YieldTypes, UnitCommandTypes,
-- UnitCommandResults, and Locale. It has only the calls the core mod makes. Example:
-- local env = Game.new()
-- FakeGame.Install(env, {
-- 	players = { [0] = { cities = { {
-- 		id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3,
-- 		growth = { foodSurplus = 3, housing = 6, turnsUntilGrowth = 2, amenities = 2, amenitiesNeeded = 2, happiness = 4 },
-- 		production = { type = "UNIT_SLINGER", turnsLeft = 2 },
-- 		yields = { FOOD = 9, PRODUCTION = 6 },
-- 		districts = { { type = "DISTRICT_CITY_CENTER", x = 17, y = 14, buildings = { { type = "BUILDING_MONUMENT" } } } },
-- 	} }, units = { { id = 196608, type = "UNIT_SCOUT", x = 24, y = 15, moves = 3, maxMoves = 3 } } } },
-- 	text = { LOC_CITY_NAME_ROME = "Rome" },
-- 	plots = { {
-- 		x = 17, y = 14, terrain = "TERRAIN_GRASS", feature = "FEATURE_FOREST", resource = "RESOURCE_DEER",
-- 		owner = 0, district = "DISTRICT_CITY_CENTER", improvement = "IMPROVEMENT_CAMP", improvementPillaged = false,
-- 		route = "ROUTE_ANCIENT_ROAD", routePillaged = false,
-- 	} },
-- })
-- A player's revealed and visible lists name plots by x and y, such as revealed = { { 17, 14 } }.
-- A player's blockers lists its end-turn blockers by name, in the game's order, such as
-- { "ENDTURN_BLOCKING_RESEARCH" }. A number in the list is a value that EndTurnBlockingTypes doesn't
-- hold. A player's hiddenResources lists the resource types its techs don't reveal yet. A city's capital is
-- true or false, and its defense has strength, garrison, and walls, each with damage and max.
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

-- The DefenseTypes values for a district's garrison and walls.
local DEFENSE_TYPES = { DISTRICT_GARRISON = 0, DISTRICT_OUTER = 1 }

-- Some EndTurnBlockingTypes values, with their hashes from the game.
local END_TURN_BLOCKING_TYPES = {
	NO_ENDTURN_BLOCKING = 0,
	ENDTURN_BLOCKING_UNITS = 23669119,
	ENDTURN_BLOCKING_RESEARCH = -286188551,
	ENDTURN_BLOCKING_CIVIC = -2034242607,
	ENDTURN_BLOCKING_PRODUCTION = -513644209,
	ENDTURN_BLOCKING_FILL_CIVIC_SLOT = -1610199318,
	ENDTURN_BLOCKING_UNIT_PROMOTION = 1706768628,
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

	local defense = data.defense or {}
	local garrison = defense.garrison or { damage = 0, max = 200 }
	local walls = defense.walls or { damage = 0, max = 0 }

	local city = {
		GetDistrictID = function()
			return data.id
		end,
		IsCapital = function()
			return data.capital == true
		end,
		-- The city center district, which the fake player's GetDistricts():FindID returns by the
		-- city's ID.
		center = {
			GetDefenseStrength = function()
				return defense.strength or 0
			end,
			GetDamage = function(_, defenseType)
				return defenseType == DEFENSE_TYPES.DISTRICT_OUTER and walls.damage or garrison.damage
			end,
			GetMaxDamage = function(_, defenseType)
				return defenseType == DEFENSE_TYPES.DISTRICT_OUTER and walls.max or garrison.max
			end,
		},
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

-- A unit from data, with id, type, x, y, moves, maxMoves, damage, which is 0 when missing,
-- maxDamage, which is 100 when missing, dead, delayedDeath, ready, which IsReadyToSelect returns, hidden, which hides it from other players'
-- IsUnitVisible, as a stealthy unit is, and experience. experience has points,
-- nextLevel, promotions, and available, a list of the promotions it can pick now. Without it, the
-- unit has no experience. indexes maps each unit and promotion type to its GameInfo index.
local function Unit(data, indexes)
	local experience = data.experience

	-- Returns the GameInfo indexes of a list of promotion types.
	local function Indexes(types)
		local list = {}

		for i, typeName in ipairs(types or {}) do
			list[i] = indexes[typeName]
		end

		return list
	end

	return {
		-- The available promotions, for the fake UnitManager.CanStartCommand.
		availablePromotions = experience and Indexes(experience.available),
		-- Whether other players' IsUnitVisible hides the unit.
		hidden = data.hidden == true,
		GetExperience = function()
			if experience == nil then
				return nil
			end

			return {
				GetExperiencePoints = function()
					return experience.points
				end,
				GetExperienceForNextLevel = function()
					return experience.nextLevel
				end,
				GetPromotions = function()
					return Indexes(experience.promotions)
				end,
			}
		end,
		GetID = function()
			return data.id
		end,
		GetType = function()
			return indexes[data.type]
		end,
		GetX = function()
			return data.x
		end,
		GetY = function()
			return data.y
		end,
		GetMovesRemaining = function()
			return data.moves
		end,
		GetMaxMoves = function()
			return data.maxMoves
		end,
		GetDamage = function()
			return data.damage or 0
		end,
		GetMaxDamage = function()
			return data.maxDamage or 100
		end,
		IsDead = function()
			return data.dead == true
		end,
		IsDelayedDeath = function()
			return data.delayedDeath == true
		end,
		IsReadyToSelect = function()
			return data.ready == true
		end,
	}
end

local function Player(id, data, hashes, indexes)
	local cities, units = {}, {}
	local hidden = {}

	for _, typeName in ipairs(data.hiddenResources or {}) do
		hidden[hashes[typeName]] = true
	end

	for i, city in ipairs(data.cities or {}) do
		cities[i] = City(city, hashes, indexes)
	end

	for i, unit in ipairs(data.units or {}) do
		units[i] = Unit(unit, indexes)
	end

	return {
		GetID = function()
			return id
		end,
		GetCities = function()
			return List(cities)
		end,
		GetUnits = function()
			return List(units)
		end,
		GetDistricts = function()
			return {
				FindID = function(_, districtID)
					for _, city in ipairs(cities) do
						if city.GetDistrictID() == districtID then
							return city.center
						end
					end
				end,
			}
		end,
		GetResources = function()
			return {
				IsResourceVisible = function(_, hash)
					return not hidden[hash]
				end,
			}
		end,
	}
end

-- Sets Players, GameInfo, YieldTypes, and Locale in env from world. world.players maps each player
-- ID to its data. world.text maps each LOC_ key to its text. Locale.Lookup returns any other key as
-- it is. GameInfo.Types holds each production type in world, under a made-up hash.
function FakeGame.Install(env, world)
	local hashes, indexes = {}, {}
	local count = 0
	-- Each plot in world.plots by its index, and the plot count, which covers the highest row.
	local plots, plotCount = {}, 0

	env.GameInfo = {
		Types = {},
		Districts = {},
		Buildings = {},
		Units = {},
		UnitPromotions = {},
		Terrains = {},
		Features = {},
		Resources = {},
		Improvements = {},
		Routes = {},
		Happinesses = HAPPINESSES,
	}
	env.UnitCommandTypes = { PROMOTE = -1259482049 }
	env.UnitCommandResults = { PROMOTIONS = 827475943 }
	-- Only the promotion command, with results, as the units state asks for it. The game returns
	-- false and no results when the unit can't promote.
	env.UnitManager = {
		CanStartCommand = function(unit, command, testOnly, withResults)
			assert(command == env.UnitCommandTypes.PROMOTE and testOnly == true and withResults == true, "no fake for this command")

			local available = unit.availablePromotions

			if available == nil or #available == 0 then
				return false, nil
			end

			return true, { [env.UnitCommandResults.PROMOTIONS] = available }
		end,
	}
	env.YieldTypes = YIELD_TYPES
	env.EndTurnBlockingTypes = END_TURN_BLOCKING_TYPES
	env.NotificationManager = {
		GetAllEndTurnBlocking = function(playerID)
			local values = {}

			for i, blocker in ipairs((world.players or {})[playerID].blockers or {}) do
				values[i] = END_TURN_BLOCKING_TYPES[blocker] or blocker
			end

			return values
		end,
	}
	env.DefenseTypes = DEFENSE_TYPES
	env.Map = {
		GetPlot = function(x, y)
			return {
				GetIndex = function()
					return PlotIndex(x, y)
				end,
			}
		end,
		GetPlotCount = function()
			return plotCount
		end,
		GetPlotByIndex = function(index)
			return assert(plots[index], "no fake plot " .. index)
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
		for _, unit in ipairs(data.units or {}) do
			AddRow("Units", "UnitType", unit.type)

			if unit.experience ~= nil then
				for _, list in ipairs({ unit.experience.promotions or {}, unit.experience.available or {} }) do
					for _, typeName in ipairs(list) do
						AddRow("UnitPromotions", "UnitPromotionType", typeName)
					end
				end
			end
		end

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

	-- Resources are added before the players, whose hidden resources are looked up by hash.
	for _, data in ipairs(world.plots or {}) do
		AddRow("Terrains", "TerrainType", data.terrain)

		if data.feature ~= nil then
			AddRow("Features", "FeatureType", data.feature)
		end

		for _, field in ipairs({ { "Districts", "DistrictType", data.district }, { "Improvements", "ImprovementType", data.improvement }, { "Routes", "RouteType", data.route } }) do
			if field[3] ~= nil then
				AddRow(field[1], field[2], field[3])
			end
		end

		if data.resource ~= nil and hashes[data.resource] == nil then
			AddRow("Resources", "ResourceType", data.resource)
			count = count + 1
			hashes[data.resource] = 2000000 + count
		end

		local index = PlotIndex(data.x, data.y)

		plotCount = math.max(plotCount, (data.y + 1) * MAP_WIDTH)
		plots[index] = {
			GetX = function()
				return data.x
			end,
			GetY = function()
				return data.y
			end,
			GetTerrainType = function()
				return indexes[data.terrain]
			end,
			-- The game returns -1 for a plot with no feature or resource.
			GetFeatureType = function()
				return data.feature and indexes[data.feature] or -1
			end,
			GetResourceType = function()
				return data.resource and indexes[data.resource] or -1
			end,
			GetResourceTypeHash = function()
				return data.resource and hashes[data.resource] or 0
			end,
			-- The game returns -1 for no owner, district, improvement, or route.
			GetOwner = function()
				return data.owner or -1
			end,
			GetDistrictType = function()
				return data.district and indexes[data.district] or -1
			end,
			GetImprovementType = function()
				return data.improvement and indexes[data.improvement] or -1
			end,
			IsImprovementPillaged = function()
				return data.improvementPillaged == true
			end,
			GetRouteType = function()
				return data.route and indexes[data.route] or -1
			end,
			IsRoutePillaged = function()
				return data.routePillaged == true
			end,
		}
	end

	env.Players = {}
	env.PlayersVisibility = {}

	for id, data in pairs(world.players or {}) do
		env.Players[id] = Player(id, data, hashes, indexes)

		-- Each listed plot's index: revealed, or visible, which is revealed too.
		local revealed, visible = {}, {}

		for _, position in ipairs(data.revealed or {}) do
			revealed[PlotIndex(position[1], position[2])] = true
		end

		for _, position in ipairs(data.visible or {}) do
			revealed[PlotIndex(position[1], position[2])] = true
			visible[PlotIndex(position[1], position[2])] = true
		end

		-- Each takes a plot index, or x and y, as in the game.
		env.PlayersVisibility[id] = {
			IsRevealed = function(_, indexOrX, y)
				return revealed[y and PlotIndex(indexOrX, y) or indexOrX] == true
			end,
			IsVisible = function(_, indexOrX, y)
				return visible[y and PlotIndex(indexOrX, y) or indexOrX] == true
			end,
			IsUnitVisible = function(_, unit)
				return not unit.hidden
			end,
		}
	end

	-- The living players, in ID order, as the game lists them.
	env.PlayerManager = {
		GetAlive = function()
			local alive = {}

			for id = 0, 63 do
				alive[#alive + 1] = env.Players[id]
			end

			return alive
		end,
	}

	local text = world.text or {}

	env.Locale = {
		Lookup = function(key)
			return text[key] or key
		end,
	}
end

return FakeGame

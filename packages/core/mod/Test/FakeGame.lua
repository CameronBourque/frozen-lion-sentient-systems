-- A fake of the game's Lua API for tests. It has only the calls the core mod makes. The core here
-- builds the shared GameInfo tables, a player's cities and units, and the fake env, and each area of
-- the game is a feature in FakeGame/, which holds the docs for the world and player data it reads. A
-- feature registers with one line at the end of this file. Example:
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
-- env.Players[0]:GetCities():Members() then lists the one city.
--
-- Where the data is documented:
-- - City: BuildCity below. Its build queue, purchases, and placement tiles are in Production,
--   Purchases, and Placement. Its governor is in Governors, and its religion in Religion.
-- - Unit: Unit below, with a player's escaping spy in Spies and digging archaeologist in Artifacts.
-- - Player: TopBar for the numbers on the top bar, Stores and Income for gold and faith, Research
--   and Governments for techs, civics, governments, and policies, Resources, Rivals, Deals, Blockers,
--   Envoys, CapturedCities, GreatPeople, and Eras. A player's era.loyalty is its civilian loyalty.
-- - World: Players for the player managers, leaders, visibility, and world.turn, Capabilities for
--   world.legacyBonuses, rename, dramaticAges, offCapabilities, and unlockWithFaith, Plots for
--   world.plots, Maintenance for world.maintenance and unitMaintenance, and Locale for world.text.
--   WorldCongress, Emergencies, Dedications, and Eras have their own data, and world.expansion2 adds
--   Gathering Storm's checks.

local FakeGame = {}

-- The features that Install runs, in registration order, and the hooks they add to each Install's
-- players and cities.
local features, playerHooks, cityHooks = {}, {}, {}

-- Registers a feature, the part of the fake that one area of the game needs. install(env, world,
-- ctx) runs in every Install, after the shared GameInfo rows and before the players are built. It
-- adds its GameInfo rows with ctx.AddRow, sets its Game.* and other globals on env, and attaches its
-- calls to players and cities with ctx.OnPlayer and ctx.OnCity. Its file has the docs for the world
-- and player data it reads. A file under FakeGame/ returns its install function, and the
-- registration lines at the end of this file list them.
function FakeGame.Register(name, install)
	for _, feature in ipairs(features) do
		assert(feature.name ~= name, "feature registered twice: " .. name)
	end

	features[#features + 1] = { name = name, install = install }
end

-- A list with Members(), as the game's city and unit lists have. Members() returns an iterator, as
-- in "for i, city in player:GetCities():Members() do". FindID(id) returns the item with that ID, or
-- nil.
local function List(items)
	return {
		Members = function()
			return ipairs(items)
		end,
		FindID = function(_, id)
			for _, item in ipairs(items) do
				if item.GetID() == id then
					return item
				end
			end
		end,
		GetCount = function()
			return #items
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

-- The MilitaryFormationTypes values. The tests don't depend on the game's numbers.
local MILITARY_FORMATION_TYPES = { STANDARD_MILITARY_FORMATION = 0, CORPS_MILITARY_FORMATION = 1, ARMY_MILITARY_FORMATION = 2 }

-- Returns the unit option, or its corps or army, for a formation.
local function Formation(unit, formation)
	if formation == MILITARY_FORMATION_TYPES.CORPS_MILITARY_FORMATION then
		return unit.corps
	elseif formation == MILITARY_FORMATION_TYPES.ARMY_MILITARY_FORMATION then
		return unit.army
	end

	return unit
end

-- The result keys of a CanProduce check. FAILURE_REASONS has the game's number.
local CITY_COMMAND_RESULTS = { FAILURE_REASONS = -2028665063, PLOTS = 2001 }
local CITY_OPERATION_RESULTS = { CAN_TRAIN_CORPS = 1001, CAN_TRAIN_ARMY = 1002, NO_SUITABLE_LOCATION = 1003, PLOTS = 1004 }

-- The operation and command values that ask for placement tiles, tiles to buy, and purchases.
local CITY_OPERATION_TYPES = { BUILD = 3001, PARAM_DISTRICT_TYPE = 3002, PARAM_BUILDING_TYPE = 3003 }
local CITY_COMMAND_TYPES = {
	PURCHASE = 4001,
	PARAM_PLOT_PURCHASE = 4002,
	PARAM_UNIT_TYPE = 4003,
	PARAM_BUILDING_TYPE = 4004,
	PARAM_DISTRICT_TYPE = 4005,
	PARAM_YIELD_TYPE = 4006,
	PARAM_MILITARY_FORMATION_TYPE = 4007,
}

-- GameInfo.Yields, by name, with each yield's index from YieldTypes.
local YIELD_ROWS = {
	YIELD_FOOD = { Index = 0 },
	YIELD_PRODUCTION = { Index = 1 },
	YIELD_GOLD = { Index = 2 },
	YIELD_SCIENCE = { Index = 3 },
	YIELD_CULTURE = { Index = 4 },
	YIELD_FAITH = { Index = 5 },
}

-- The YieldTypes values, as in the game.
local YIELD_TYPES = { FOOD = 0, PRODUCTION = 1, GOLD = 2, SCIENCE = 3, CULTURE = 4, FAITH = 5 }

-- The YieldTypes names by GameInfo.Yields index.
local YIELD_NAMES = { [0] = "FOOD", "PRODUCTION", "GOLD", "SCIENCE", "CULTURE", "FAITH" }

-- A city from data. data.production is { type, turnsLeft }, or { hash, turnsLeft } for a hash that
-- GameInfo.Types doesn't know, or nil for nothing in production. data.yields maps a YieldTypes
-- name to its amount, and a missing yield is 0. data.growth has foodSurplus, housing, amenities,
-- and amenitiesNeeded, each 0 when missing, happiness, an index in GameInfo.Happinesses that is 4,
-- content, when missing, and turnsUntilGrowth and turnsUntilStarvation, which are -1 when missing,
-- as in the game. data.loyalty has value, max, and perTurn. Without it, the city has no
-- GetCulturalIdentity, as in a game without the Rise and Fall expansion. data.districts lists each
-- district with type, x, y, complete, which is true when missing, pillaged, and buildings. Each
-- building has type, built, which is true when missing, and pillaged. The build queue's data.options
-- are in FakeGame/Production.lua, data.purchases in Purchases.lua, and the tiles to place or buy in
-- Placement.lua. hashes maps each production, unit, building, and district type to its hash,
-- and indexes maps each district, building, and unit type to its GameInfo index. ownerID is the
-- player's ID.
local function BuildCity(data, hashes, indexes, ownerID)
	local growth = data.growth or {}
	local loyalty = data.loyalty
	local districts = {}
	-- Each placed district by its GameInfo index.
	local placed = {}
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

		placed[indexes[district.type]] = district
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
			-- The district's yield and adjacency bonus for a GameInfo.Yields index, from district.yields and
			-- district.adjacency, which map a YieldTypes name to an amount.
			GetYield = function(_, yieldIndex)
				return (district.yields or {})[YIELD_NAMES[yieldIndex]] or 0
			end,
			GetAdjacencyYield = function(_, yieldIndex)
				return (district.adjacency or {})[YIELD_NAMES[yieldIndex]] or 0
			end,
		}
	end


	-- Each building option by its hash, which IsPillaged accepts.
	local buildingsByHash = {}

	for _, building in ipairs((data.options or {}).buildings or {}) do
		buildingsByHash[hashes[building.type]] = building
	end

	local defense = data.defense or {}
	local garrison = defense.garrison or { damage = 0, max = 200 }
	local walls = defense.walls or { damage = 0, max = 0 }

	local districtList = List(districts)

	-- The city's district list also answers for a district type, by its GameInfo index.
	function districtList.HasDistrict(_, index)
		return placed[index] ~= nil
	end

	function districtList.IsComplete(_, index)
		return placed[index] ~= nil and placed[index].complete ~= false
	end

	function districtList.IsPillaged(_, index)
		return placed[index] ~= nil and placed[index].pillaged == true
	end

	function districtList.IsContaminated()
		return false
	end

	local city = {
		GetOwner = function()
			return ownerID
		end,
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
			return districtList
		end,
		-- A building's yield for an index and a yield type such as "YIELD_GOLD", from building.yields,
		-- which maps a YieldTypes name to an amount.
		GetBuildingYield = function(_, index, yieldType)
			return ((buildings[index] or {}).yields or {})[yieldType:gsub("^YIELD_", "")] or 0
		end,
		-- The routes the city sends out, from data.routes, each with player, id, the destination city, and
		-- yields, a YieldTypes name to the amount it gives this city.
		GetTrade = function()
			return {
				GetOutgoingRoutes = function()
					local routes = {}

					for i, route in ipairs(data.routes or {}) do
						local origin = {}

						for name, index in pairs(YIELD_TYPES) do
							origin[#origin + 1] = { YieldIndex = index, Amount = (route.yields or {})[name] or 0 }
						end

						table.sort(origin, function(a, b)
							return a.YieldIndex < b.YieldIndex
						end)
						routes[i] = { DestinationCityPlayer = route.player, DestinationCityID = route.id, OriginYields = origin }
					end

					return routes
				end,
			}
		end,
		-- The tiles the city owns, from data.tiles, each with x, y, worked, yields, and tourism.
		GetCitizens = function()
			return {
				IsPlotWorked = function(_, x, y)
					for _, tile in ipairs(data.tiles or {}) do
						if tile.x == x and tile.y == y then
							return tile.worked == true
						end
					end

					return false
				end,
			}
		end,
		tiles = data.tiles or {},
		IsOccupied = function()
			return data.occupied == true
		end,
		GetBuildings = function()
			return {
				GetBuildingsAtLocation = function(_, plotIndex)
					return buildingsAt[plotIndex] or {}
				end,
				HasBuilding = function(_, index)
					return buildings[index].built ~= false
				end,
				-- The great works in a building, from building.greatWorks, each with type. A slot's great work
				-- is numbered by its building and slot, and its type is that great work's GameInfo index.
				GetNumGreatWorkSlots = function(_, index)
					return #(buildings[index].greatWorks or {})
				end,
				GetGreatWorkInSlot = function(_, index, slot)
					return (buildings[index].greatWorks or {})[slot + 1] and index * 100 + slot or -1
				end,
				GetGreatWorkTypeFromIndex = function(_, work)
					return indexes[buildings[math.floor(work / 100)].greatWorks[work % 100 + 1].type]
				end,
				-- The game takes an index or a hash. A building option is found by its hash.
				IsPillaged = function(_, indexOrHash)
					local building = buildingsByHash[indexOrHash] or buildings[indexOrHash]

					return building ~= nil and building.pillaged == true
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
				GetHappinessNonFoodYieldModifier = function()
					return growth.yieldModifier or 0
				end,
				GetHousingGrowthModifier = function()
					return growth.housingModifier or 1
				end,
				GetHappinessGrowthModifier = function()
					return growth.happinessModifier or 0
				end,
				GetAmenitiesLostFromWarWeariness = function()
					return growth.warWeariness or 0
				end,
				GetTurnsUntilGrowth = function()
					return growth.turnsUntilGrowth or -1
				end,
				GetTurnsUntilStarvation = function()
					return growth.turnsUntilStarvation or -1
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
-- A city with the calls that the features add to it.
local function City(data, hashes, indexes, ownerID)
	local city = BuildCity(data, hashes, indexes, ownerID)

	for _, hook in ipairs(cityHooks) do
		hook(city, data, ownerID)
	end

	return city
end

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
		GetUnitType = function()
			return indexes[data.type]
		end,
		-- The unit's formation, from data.formation, such as "CORPS_MILITARY_FORMATION", standard when
		-- missing.
		GetMilitaryFormation = function()
			return MILITARY_FORMATION_TYPES[data.formation or "STANDARD_MILITARY_FORMATION"]
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

local function BuildPlayer(id, data, hashes, indexes, env)
	local cities, units = {}, {}

	for i, city in ipairs(data.cities or {}) do
		cities[i] = City(city, hashes, indexes, id)
	end

	for i, unit in ipairs(data.units or {}) do
		units[i] = Unit(unit, indexes)
	end

	return {
		GetID = function()
			return id
		end,
		-- The player's cities.
		GetCities = function()
			local list = List(cities)

			-- The city with capital set, which a major player has.
			function list.GetCapitalCity()
				for _, city in ipairs(cities) do
					if city.IsCapital() then
						return city
					end
				end
			end

			return list
		end,
		IsFreeCities = function()
			return data.freeCities == true
		end,
		-- The loyalty pressure each of the player's citizens exerts, from data.era.loyalty.
		GetCivilianLoyalty = function()
			return (data.era or {}).loyalty or 0
		end,
		-- The player's units.
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
	}
end

-- A player with the calls that the features add to it.
local function Player(id, data, hashes, indexes, env)
	local player = BuildPlayer(id, data, hashes, indexes, env)

	for _, hook in ipairs(playerHooks) do
		hook(player, data, id)
	end

	return player
end

-- Sets Players, GameInfo, YieldTypes, and Locale in env from world. world.players maps each player
-- ID to its data. world.text maps each LOC_ key to its text. Locale.Lookup returns any other key as
-- it is. GameInfo.Types holds each production type in world, under a made-up hash.
function FakeGame.Install(env, world)
	playerHooks, cityHooks = {}, {}

	local hashes, indexes = {}, {}
	local count = 0
	-- Each plot in world.plots by its index, which FakeGame/Plots.lua fills.
	local plots = {}

	-- GameInfo.Yields finds a yield by its type or by its index, as the game's table does.
	local yieldInfo = {}

	for name, row in pairs(YIELD_ROWS) do
		yieldInfo[name] = { Index = row.Index, YieldType = name }
		yieldInfo[row.Index] = yieldInfo[name]
	end

	env.GameInfo = {
		Types = {},
		Districts = {},
		Projects = {},
		Eras = {
			ERA_ANCIENT = { ChronologyIndex = 1 },
			ERA_CLASSICAL = { ChronologyIndex = 2 },
			ERA_MEDIEVAL = { ChronologyIndex = 3 },
		},
		Yields = yieldInfo,
		Buildings = {},
		Units = {},
		GreatWorks = {},
		GreatWorks = {},
		UnitPromotions = {},
		Terrains = {},
		Features = {},
		Resources = {},
		Improvements = {},
		Routes = {},
		Happinesses = HAPPINESSES,
		Leaders = {},
		LeaderTraits = {},
		Traits = {},
	}
	-- Gives a table of rows the game's lookups: a row by its type name, as in
	-- GameInfo.Districts["DISTRICT_CAMPUS"], and a call that lists the rows in index order.
	local function TypedRows(rows, column)
		return setmetatable(rows, {
			__index = function(_, key)
				if type(key) == "string" then
					for index = 0, #rows do
						local row = rawget(rows, index)

						if row ~= nil and row[column] == key then
							return row
						end
					end
				end
			end,
			__call = function()
				local index = -1

				return function()
					index = index + 1

					return rows[index]
				end
			end,
		})
	end

	-- GameInfo.Units(), GameInfo.Buildings(), GameInfo.Districts(), and GameInfo.Projects() list the
	-- rows in index order, as the game's tables do when called, and each table finds a row by its type
	-- name, as in GameInfo.Districts["DISTRICT_CAMPUS"].
	for name, column in pairs({
		Units = "UnitType",
		GreatWorks = "GreatWorkType",
		Buildings = "BuildingType",
		Districts = "DistrictType",
		Projects = "ProjectType",
		Resources = "ResourceType",
	}) do
		TypedRows(env.GameInfo[name], column)
	end
	env.MilitaryFormationTypes = MILITARY_FORMATION_TYPES
	env.CityCommandResults = CITY_COMMAND_RESULTS
	env.CityOperationResults = CITY_OPERATION_RESULTS
	env.CityOperationTypes = CITY_OPERATION_TYPES
	env.CityCommandTypes = CITY_COMMAND_TYPES
	env.CityManager = {
		-- The city that a component ID, such as a holy city's, names.
		GetCity = function(componentID)
			local player = env.Players[componentID.player]

			return player and player:GetCities():FindID(componentID.id)
		end,
	}
	env.UI = {
		GetInterfaceModeParameter = function(parameter)
			return parameter
		end,
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
	env.DefenseTypes = DEFENSE_TYPES

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

	-- Makes a list of rows callable, as GameInfo.Government_SlotCounts() is.
	local function Callable(rows)
		return setmetatable(rows, {
			__call = function()
				local i = 0

				return function()
					i = i + 1

					return rows[i]
				end
			end,
		})
	end

	-- GameInfo.GreatWork_YieldChanges() lists what each great work in a building gives, from the
	-- building's greatWorks, each with type and yields, a YieldTypes name to the amount.
	local greatWorkYields, wonderTypes = {}, {}

	env.GameInfo.GreatWork_YieldChanges = function()
		local i = 0

		return function()
			i = i + 1

			return greatWorkYields[i]
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

			for _, unit in ipairs((city.options or {}).units or {}) do
				AddRow("Units", "UnitType", unit.type)

				local row = env.GameInfo.Units[indexes[unit.type]]

				count = count + 1
				hashes[unit.type] = hashes[unit.type] or 3000000 + count
				row.Hash = hashes[unit.type]
				row.MustPurchase = unit.mustPurchase == true
			end

			for _, building in ipairs((city.options or {}).buildings or {}) do
				AddRow("Buildings", "BuildingType", building.type)

				local row = env.GameInfo.Buildings[indexes[building.type]]

				count = count + 1
				hashes[building.type] = hashes[building.type] or 3000000 + count
				row.Hash = hashes[building.type]
				row.MustPurchase = building.mustPurchase == true
				row.IsWonder = building.wonder == true
				row.PrereqDistrict = building.district
			end

			for _, district in ipairs((city.options or {}).districts or {}) do
				AddRow("Districts", "DistrictType", district.type)

				local row = env.GameInfo.Districts[indexes[district.type]]

				count = count + 1
				hashes[district.type] = hashes[district.type] or 3000000 + count
				row.Hash = hashes[district.type]
				row.OnePerCity = district.onePerCity ~= false
				row.InternalOnly = district.internalOnly == true
			end

			for yieldName, purchases in pairs(city.purchases or {}) do
				for _, kind in ipairs({ { "units", "Units", "UnitType" }, { "buildings", "Buildings", "BuildingType" }, { "districts", "Districts", "DistrictType" } }) do
					for _, option in ipairs(purchases[kind[1]] or {}) do
						AddRow(kind[2], kind[3], option.type)

						local row = env.GameInfo[kind[2]][indexes[option.type]]

						count = count + 1
						hashes[option.type] = hashes[option.type] or 3000000 + count
						row.Hash = hashes[option.type]
						row.PurchaseYield = option.faithEnabled and "YIELD_GOLD" or yieldName
						row.OnePerCity = row.OnePerCity ~= false
					end
				end
			end

			for _, project in ipairs((city.options or {}).projects or {}) do
				AddRow("Projects", "ProjectType", project.type)

				local row = env.GameInfo.Projects[indexes[project.type]]

				count = count + 1
				hashes[project.type] = hashes[project.type] or 3000000 + count
				row.Hash = hashes[project.type]
				row.MaxPlayerInstances = project.maxPlayerInstances
			end

			if typeName ~= nil then
				count = count + 1
				hashes[typeName] = hashes[typeName] or 1000000 + count
				env.GameInfo.Types[hashes[typeName]] = { Type = typeName }
			end

			for _, district in ipairs(city.districts or {}) do
				AddRow("Districts", "DistrictType", district.type)

				for _, building in ipairs(district.buildings or {}) do
					AddRow("Buildings", "BuildingType", building.type)
					wonderTypes[building.type] = building.wonder == true or wonderTypes[building.type]

					for _, work in ipairs(building.greatWorks or {}) do
						AddRow("GreatWorks", "GreatWorkType", work.type)
						env.GameInfo.GreatWorks[indexes[work.type]].Name = "LOC_" .. work.type .. "_NAME"

						for name, amount in pairs(work.yields or {}) do
							greatWorkYields[#greatWorkYields + 1] = { GreatWorkType = work.type, YieldType = "YIELD_" .. name, YieldChange = amount }
						end
					end
				end
			end
		end
	end

	-- What a feature gets from the core: the rows and their hashes and indexes, the plots by index,
	-- and the shared helpers. NextHash(base, typeName) gives a type the hash base plus a running
	-- count, once. OnPlayer(hook) and OnCity(hook) run hook(player, data, id) and hook(city, data,
	-- ownerID) on each one built, to add its calls.
	local ctx = {
		hashes = hashes,
		indexes = indexes,
		plots = plots,
		AddRow = AddRow,
		NextHash = function(base, typeName)
			if hashes[typeName] == nil then
				count = count + 1
				hashes[typeName] = base + count
			end

			return hashes[typeName]
		end,
		TypedRows = TypedRows,
		Callable = Callable,
		List = List,
		Formation = Formation,
		PlotIndex = PlotIndex,
		wonderTypes = wonderTypes,
		MAP_WIDTH = MAP_WIDTH,
		YIELD_TYPES = YIELD_TYPES,
		YIELD_NAMES = YIELD_NAMES,
		OnPlayer = function(hook)
			playerHooks[#playerHooks + 1] = hook
		end,
		OnCity = function(hook)
			cityHooks[#cityHooks + 1] = hook
		end,
	}

	env.Game = env.Game or {}

	for _, feature in ipairs(features) do
		feature.install(env, world, ctx)
	end

	env.Players = {}
	env.PlayersVisibility = {}
	env.PlayerConfigurations = {}

	for id, data in pairs(world.players or {}) do
		env.Players[id] = Player(id, data, hashes, indexes, env)
	end
end

-- One line for each feature in FakeGame/, in the order Install runs them. Each file returns its
-- install function, as FakeGame.Register describes.
FakeGame.Register("Resources", require("FakeGame/Resources"))
FakeGame.Register("Plots", require("FakeGame/Plots"))
FakeGame.Register("Rivals", require("FakeGame/Rivals"))
FakeGame.Register("TopBar", require("FakeGame/TopBar"))
FakeGame.Register("Stores", require("FakeGame/Stores"))
FakeGame.Register("Players", require("FakeGame/Players"))
FakeGame.Register("Locale", require("FakeGame/Locale"))
FakeGame.Register("Capabilities", require("FakeGame/Capabilities"))
FakeGame.Register("Blockers", require("FakeGame/Blockers"))
FakeGame.Register("Deals", require("FakeGame/Deals"))
FakeGame.Register("Emergencies", require("FakeGame/Emergencies"))
FakeGame.Register("WorldCongress", require("FakeGame/WorldCongress"))
FakeGame.Register("Eras", require("FakeGame/Eras"))
FakeGame.Register("Dedications", require("FakeGame/Dedications"))
FakeGame.Register("Governors", require("FakeGame/Governors"))
FakeGame.Register("Religion", require("FakeGame/Religion"))
FakeGame.Register("GreatPeople", require("FakeGame/GreatPeople"))
FakeGame.Register("Envoys", require("FakeGame/Envoys"))
FakeGame.Register("Spies", require("FakeGame/Spies"))
FakeGame.Register("Artifacts", require("FakeGame/Artifacts"))
FakeGame.Register("CapturedCities", require("FakeGame/CapturedCities"))
FakeGame.Register("Research", require("FakeGame/Research"))
FakeGame.Register("Governments", require("FakeGame/Governments"))
FakeGame.Register("Production", require("FakeGame/Production"))
FakeGame.Register("Purchases", require("FakeGame/Purchases"))
FakeGame.Register("Placement", require("FakeGame/Placement"))
FakeGame.Register("Income", require("FakeGame/Income"))
FakeGame.Register("Maintenance", require("FakeGame/Maintenance"))

return FakeGame

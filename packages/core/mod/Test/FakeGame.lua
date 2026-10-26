-- A fake of the game's Lua API for tests, with players, their cities, districts, and units, the
-- map's plots, PlayersVisibility, PlayerManager.GetAlive, DefenseTypes, UnitManager.CanStartCommand
-- for promotions, EndTurnBlockingTypes, NotificationManager.GetAllEndTurnBlocking, a build queue for
-- units, buildings, and districts with MilitaryFormationTypes, CityCommandResults, and
-- CityOperationResults, CityManager and UI for placement tiles, GameInfo.Types,
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
-- true or false, and its defense has strength, garrison, and walls, each with damage and max. A
-- city's options lists what its build queue offers, such as options = { units = { { type =
-- "UNIT_SETTLER", cost = 40, turns = 6 } }, buildings = { { type = "BUILDING_GRANARY", cost = 32,
-- turns = 5 } }, districts = { { type = "DISTRICT_CAMPUS", cost = 29, turns = 6, tiles = { { x = 17,
-- y = 13, adjacency = { SCIENCE = 1 } } } } } }.
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

-- The MilitaryFormationTypes values. The tests don't depend on the game's numbers.
local MILITARY_FORMATION_TYPES = { STANDARD_MILITARY_FORMATION = 0, CORPS_MILITARY_FORMATION = 1, ARMY_MILITARY_FORMATION = 2 }

-- The result keys of a CanProduce check. FAILURE_REASONS has the game's number.
local CITY_COMMAND_RESULTS = { FAILURE_REASONS = -2028665063, PLOTS = 2001 }
local CITY_OPERATION_RESULTS = { CAN_TRAIN_CORPS = 1001, CAN_TRAIN_ARMY = 1002, NO_SUITABLE_LOCATION = 1003, PLOTS = 1004 }

-- The operation and command values that ask for placement tiles and tiles to buy.
local CITY_OPERATION_TYPES = { BUILD = 3001, PARAM_DISTRICT_TYPE = 3002, PARAM_BUILDING_TYPE = 3003 }
local CITY_COMMAND_TYPES = { PURCHASE = 4001, PARAM_PLOT_PURCHASE = 4002 }

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
-- building has type, built, which is true when missing, and pillaged. data.options.units lists each
-- unit the build queue knows, with type, cost, turns, progress, which is 0 when missing, blocked, a
-- list of reasons the queue refuses it, hidden, which the queue refuses even when it only tests, and
-- corps and army, each with cost, turns, and blocked. data.options.buildings lists each building the
-- build queue knows, with type, cost, turns, progress, blocked, and hidden in the same way, and
-- pillaged, district, its PrereqDistrict, wonder, and mustPurchase, which go in its GameInfo row. A
-- wonder also has tiles, purchaseTiles, and noLocation, the NO_SUITABLE_LOCATION result.
-- data.options.districts lists each district the build queue knows, with type, cost, turns,
-- progress, blocked, hidden, reasons, which the queue returns when it allows the district, tiles,
-- the tiles where it can go, and purchaseTiles, the tiles to buy where it can go, each with x, y,
-- and adjacency, a bonus by YieldTypes name. onePerCity, true when missing, and internalOnly go in
-- its GameInfo row. data.options.purchasable lists more tiles
-- to buy, by x and y. hashes maps each production, unit, building, and district type to its hash,
-- and indexes maps each district, building, and unit type to its GameInfo index. ownerID is the
-- player's ID.
local function City(data, hashes, indexes, ownerID)
	local production = data.production
	local hash = production and (production.hash or hashes[production.type]) or 0
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
		}
	end

	-- Each unit and building option by its hash and by its index.
	local unitsByHash, unitsByIndex = {}, {}
	local buildingsByHash, buildingsByIndex = {}, {}

	for _, unit in ipairs((data.options or {}).units or {}) do
		unitsByHash[hashes[unit.type]] = unit
		unitsByIndex[indexes[unit.type]] = unit
	end

	for _, building in ipairs((data.options or {}).buildings or {}) do
		buildingsByHash[hashes[building.type]] = building
		buildingsByIndex[indexes[building.type]] = building
	end

	-- Each district option by its hash, its index, and its type.
	local districtsByHash, districtsByIndex, districtsByType = {}, {}, {}

	for _, district in ipairs((data.options or {}).districts or {}) do
		districtsByHash[hashes[district.type]] = district
		districtsByIndex[indexes[district.type]] = district
		districtsByType[district.type] = district
	end

	-- Returns the plot indexes of a list of tiles.
	local function PlotIndexes(tiles)
		local list = {}

		for i, tile in ipairs(tiles or {}) do
			list[i] = PlotIndex(tile.x, tile.y)
		end

		return list
	end

	-- The plot indexes of every tile to buy, each once.
	local purchasable, seen = {}, {}

	for _, option in ipairs((data.options or {}).districts or {}) do
		for _, plotIndex in ipairs(PlotIndexes(option.purchaseTiles)) do
			if not seen[plotIndex] then
				seen[plotIndex] = true
				purchasable[#purchasable + 1] = plotIndex
			end
		end
	end

	for _, option in ipairs((data.options or {}).buildings or {}) do
		for _, plotIndex in ipairs(PlotIndexes(option.purchaseTiles)) do
			if not seen[plotIndex] then
				seen[plotIndex] = true
				purchasable[#purchasable + 1] = plotIndex
			end
		end
	end

	for _, plotIndex in ipairs(PlotIndexes((data.options or {}).purchasable)) do
		if not seen[plotIndex] then
			seen[plotIndex] = true
			purchasable[#purchasable + 1] = plotIndex
		end
	end

	-- Returns the unit option, or its corps or army, for a formation.
	local function Formation(unit, formation)
		if formation == MILITARY_FORMATION_TYPES.CORPS_MILITARY_FORMATION then
			return unit.corps
		elseif formation == MILITARY_FORMATION_TYPES.ARMY_MILITARY_FORMATION then
			return unit.army
		end

		return unit
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
		-- The tiles to buy, for the fake CityManager.GetCommandTargets.
		purchasable = purchasable,
		-- The plot indexes where the district or wonder that params names can go, for the fake
		-- CityManager.GetOperationTargets.
		PlacementPlots = function(params)
			local option = districtsByHash[params[CITY_OPERATION_TYPES.PARAM_DISTRICT_TYPE]] or buildingsByHash[params[CITY_OPERATION_TYPES.PARAM_BUILDING_TYPE]]

			return PlotIndexes(option and option.tiles)
		end,
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
		GetBuildings = function()
			return {
				GetBuildingsAtLocation = function(_, plotIndex)
					return buildingsAt[plotIndex] or {}
				end,
				HasBuilding = function(_, index)
					return buildings[index].built ~= false
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
				-- The game takes a hash or a type name, and a formation for a unit.
				GetTurnsLeft = function(_, typeOrHash, formation)
					local unit = unitsByHash[typeOrHash]

					if unit ~= nil then
						return Formation(unit, formation).turns
					end

					if buildingsByHash[typeOrHash] ~= nil then
						return buildingsByHash[typeOrHash].turns
					end

					if districtsByType[typeOrHash] ~= nil then
						return districtsByType[typeOrHash].turns
					end

					assert(production and (typeOrHash == hash or typeOrHash == production.type), "no production " .. tostring(typeOrHash))

					return production.turnsLeft
				end,
				-- With testOnly, whether the queue knows the unit or building. Without it, whether the
				-- city can produce it now, and the results: the reasons it can't, and for a unit, whether
				-- a corps or an army can be trained. params is a building's hash, or a table that names a
				-- unit and its formation, as in the game.
				CanProduce = function(_, params, testOnly, withResults)
					if type(params) == "number" then
						local option = buildingsByHash[params] or districtsByHash[params]

						if testOnly then
							return option ~= nil and not option.hidden
						end

						return option.blocked == nil, {
							[CITY_COMMAND_RESULTS.FAILURE_REASONS] = option.blocked or option.reasons,
							[CITY_OPERATION_RESULTS.NO_SUITABLE_LOCATION] = option.noLocation,
						}
					end

					local unit = unitsByHash[params.UnitType]

					if testOnly then
						return unit ~= nil and not unit.hidden
					end

					assert(withResults == true, "no fake without results")

					local option = Formation(unit, params.MilitaryFormationType)

					return option.blocked == nil, {
						[CITY_COMMAND_RESULTS.FAILURE_REASONS] = option.blocked,
						[CITY_OPERATION_RESULTS.CAN_TRAIN_CORPS] = unit.corps ~= nil or nil,
						[CITY_OPERATION_RESULTS.CAN_TRAIN_ARMY] = unit.army ~= nil or nil,
					}
				end,
				GetUnitCost = function(_, index)
					return unitsByIndex[index].cost
				end,
				GetUnitProgress = function(_, index)
					return unitsByIndex[index].progress or 0
				end,
				GetUnitCorpsCost = function(_, index)
					return unitsByIndex[index].corps.cost
				end,
				GetUnitArmyCost = function(_, index)
					return unitsByIndex[index].army.cost
				end,
				GetBuildingCost = function(_, index)
					return buildingsByIndex[index].cost
				end,
				GetBuildingProgress = function(_, index)
					return buildingsByIndex[index].progress or 0
				end,
				GetDistrictCost = function(_, index)
					return districtsByIndex[index].cost
				end,
				-- 0 for a district the queue doesn't know, such as a built city center.
				GetDistrictProgress = function(_, index)
					return (districtsByIndex[index] or {}).progress or 0
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
		cities[i] = City(city, hashes, indexes, id)
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
	-- GameInfo.Units(), GameInfo.Buildings(), and GameInfo.Districts() list the rows in index order, as
	-- the game's tables do when called.
	for _, name in ipairs({ "Units", "Buildings", "Districts" }) do
		setmetatable(env.GameInfo[name], {
			__call = function(rows)
				local index = -1

				return function()
					index = index + 1

					return rows[index]
				end
			end,
		})
	end
	env.MilitaryFormationTypes = MILITARY_FORMATION_TYPES
	env.CityCommandResults = CITY_COMMAND_RESULTS
	env.CityOperationResults = CITY_OPERATION_RESULTS
	env.CityOperationTypes = CITY_OPERATION_TYPES
	env.CityCommandTypes = CITY_COMMAND_TYPES
	env.CityManager = {
		GetOperationTargets = function(city, operation, params)
			assert(operation == CITY_OPERATION_TYPES.BUILD, "no fake for this operation")

			return { [CITY_OPERATION_RESULTS.PLOTS] = city.PlacementPlots(params) }
		end,
		GetCommandTargets = function(city, command, params)
			assert(command == CITY_COMMAND_TYPES.PURCHASE and params[CITY_COMMAND_TYPES.PARAM_PLOT_PURCHASE] ~= nil, "no fake for this command")

			return { [CITY_COMMAND_RESULTS.PLOTS] = city.purchasable }
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

			if typeName ~= nil then
				count = count + 1
				hashes[typeName] = hashes[typeName] or 1000000 + count
				env.GameInfo.Types[hashes[typeName]] = { Type = typeName }
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

	-- Each placement tile gets a plot, with the adjacency bonuses and the districts and wonders that
	-- CanHaveDistrict and CanHaveWonder allow on it as a tile to buy.
	local adjacencyAt, districtsAt, wondersAt = {}, {}, {}

	-- Adds a fake plot at a tile that world.plots doesn't hold, and returns its index.
	local function PlacementPlot(tile)
		local index = PlotIndex(tile.x, tile.y)

		plots[index] = plots[index] or {
			GetX = function()
				return tile.x
			end,
			GetY = function()
				return tile.y
			end,
		}
		adjacencyAt[index] = adjacencyAt[index] or {}
		districtsAt[index] = districtsAt[index] or {}
		wondersAt[index] = wondersAt[index] or {}

		return index
	end

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			local options = city.options or {}

			for _, district in ipairs(options.districts or {}) do
				for _, list in ipairs({ district.tiles or {}, district.purchaseTiles or {} }) do
					for _, tile in ipairs(list) do
						adjacencyAt[PlacementPlot(tile)][indexes[district.type]] = tile.adjacency
					end
				end

				for _, tile in ipairs(district.purchaseTiles or {}) do
					districtsAt[PlacementPlot(tile)][indexes[district.type]] = true
				end
			end

			for _, building in ipairs(options.buildings or {}) do
				for _, tile in ipairs(building.tiles or {}) do
					PlacementPlot(tile)
				end

				for _, tile in ipairs(building.purchaseTiles or {}) do
					wondersAt[PlacementPlot(tile)][indexes[building.type]] = true
				end
			end

			for _, tile in ipairs(options.purchasable or {}) do
				PlacementPlot(tile)
			end
		end
	end

	for index, plot in pairs(plots) do
		-- The bonus of a district on the plot, for a YieldTypes value.
		function plot.GetAdjacencyYield(_, _, _, districtIndex, yieldType)
			local adjacency = (adjacencyAt[index] or {})[districtIndex] or {}

			for name, value in pairs(YIELD_TYPES) do
				if value == yieldType then
					return adjacency[name] or 0
				end
			end

			return 0
		end

		function plot.CanHaveDistrict(_, districtIndex)
			return (districtsAt[index] or {})[districtIndex] == true
		end

		function plot.CanHaveWonder(_, buildingIndex)
			return (wondersAt[index] or {})[buildingIndex] == true
		end
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

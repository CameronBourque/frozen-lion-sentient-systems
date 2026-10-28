-- A fake of the game's Lua API for tests, with players, their cities, districts, and units, the
-- map's plots, PlayersVisibility, PlayerManager.GetAlive and GetAliveMinors, PlayerConfigurations,
-- PlayerManager.GetAliveMajorIDs, a player's influence and resources, Game.GetQuestsManager,
-- Game.GetGreatPeople, a player's great people points, GameInfo.GreatPersonClasses,
-- GameInfo.GreatPersonIndividuals, GameCapabilities, a player's captured and rebelled cities,
-- CityDestroyDirectives, CivilizationLevelTypes, CityTransferTypes, GlobalParameters, a player's
-- escaping spy, Cities.GetPlotPurchaseCity, a player's digging archaeologist, Game.GetArtifactByIndex,
-- a player's governors, GameInfo.Governors, GameInfo.GovernorPromotions,
-- GameInfo.GovernorPromotionSets,
-- GameInfo.Leaders, GameInfo.LeaderTraits, GameInfo.Traits, GameInfo.Quests, DefenseTypes, UnitManager.CanStartCommand
-- for promotions, EndTurnBlockingTypes, NotificationManager.GetAllEndTurnBlocking, a build queue for
-- units, buildings, and districts with MilitaryFormationTypes, CityCommandResults, and
-- CityOperationResults, CityManager and UI for placement tiles and purchases, a treasury, a
-- player's techs and civics with the advisor's recommendations and the game's
-- GetUnlockablesForTech and GetUnlockablesForCivic, GameInfo.Types, GameInfo.Yields,
-- GameInfo.Technologies, GameInfo.Civics, GameInfo.Boosts, GameInfo.Eras, UITree for player 0's
-- techs and civics, Game.GetPlayers, a player's diplomacy, a player's government and policy slots
-- with GameInfo.Governments, GameInfo.GovernmentSlots, and GameInfo.Policies,
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
-- A player's techs has current, the tech in research, and options, the techs the player knows,
-- each with type, cost, turns, progress, boost, with percent, trigger, and triggered, unlocks,
-- description, a text key, recommended, locked, which CanResearch refuses, and for the tech tree,
-- era, which is ERA_ANCIENT when missing, researched, hidden, which IsTechRevealed refuses, and
-- prerequisites, by type. techs.turnsLeft is what GetTurnsLeft returns. A player's civics has the
-- same, with civic types. A player's government has type, missing for none, and slots, each with
-- type, such as SLOT_MILITARY, and policy, missing for an empty slot, and civicThisTurn, slotsOpen,
-- changeMade, and unlockCost, as the game's culture calls give them. A player's policies lists the
-- policies the player knows, each with type, slot, its slot type, description, civic, its
-- prerequisite, and locked, obsolete, banned, and unslottable. noStrategicCommands is true while
-- the player can't act. A player's government also has unlocked, the other governments it has
-- unlocked, anarchy, the turns by government type, canChangeAtAll, and governmentChangeMade.
-- world.governments lists the ruleset's governments, each with type, civic, bonusType, bonuses,
-- its two text keys, slots, counts by slot type, influence, with perTurn, threshold, and envoys,
-- favor, and legacyPercent. world.legacyBonuses turns on the base game's legacy bonuses.
-- world.beliefs lists the ruleset's beliefs, each with type, class, BELIEF_CLASS_PANTHEON when
-- missing, description, and taken, true when a player's pantheon or religion holds it. A player's
-- pantheon is its belief type, and canCreatePantheon is true when it can found one. A player's
-- religion is the religion it founded, with type, name, beliefs, by type, and holyCity, a city ID,
-- beliefsEarned the beliefs it has earned, and prophet is true when it has a Great Prophet. A city's religions lists the religions
-- in it, each with type and followers, and majority is its majority religion's type.
-- world.pantheonFaith is the faith the next pantheon needs, 25 when missing. world.religions lists
-- more religions, each with type, pantheon, customName, and founded. A belief's tooMany is true
-- when a religion has too many of its class. world.rename turns on CAPABILITY_RENAME.
-- world.expansion2 adds Gathering Storm's checks, world.unlockWithFaith makes
-- the policy unlock cost faith, and world.congressInSession puts the World Congress in session. A
-- player's met lists the IDs of the players it has met, and atWar the IDs of the players it is at
-- war with. A player's influence has tokens, canGive, false to refuse envoys, points, perTurn,
-- threshold, and envoys, the envoys each threshold gives. A city-state's minor has name, leader,
-- inherit, the leader it inherits from, envoys, the count by player ID, suzerain, a player ID, and
-- cantReceive, true for the Free Cities, and traits, the text keys of its suzerain bonus, resources,
-- each with type, amount, exported, and perTurn, quests by player ID, each with type, name,
-- description, and reward, and uniqueDisabled, true when Gathering Storm turns off its suzerain
-- bonus. world.greatPeople lists the great people on offer, each with class, type, name, era, cost,
-- charges, passive and action, each with the text the timeline gives, canRecruit, passCost, there
-- when the player can pass, gold and faith, each with cost and can, cantEarn, and claimed, true for a
-- class whose great person is taken. A player's greatPeoplePoints maps a class type to its points
-- and perTurn. A player's captured and rebelled are the next city it captured and the next city that
-- rebelled to join it, each with id, name, x, y, population, districts, originalOwner, ownerBefore,
-- conqueredFrom, gift, true for a city given in a deal, canRaze, false for one the player can't
-- raze, and warmonger, with keep and raze points. noRiseAndFall leaves out GetNextRebelledCity. A
-- player's liberate lists the IDs it can liberate a city to, revived the IDs it has brought back,
-- and freeCities is true for the Free Cities. A player's escapingSpy is its next escaping spy, with
-- id, name, loot, pursuer, the counterspy's name or "" for the police, x, and y, the tile of the city
-- it escapes from. With one, the four escape districts get rows, with TravelTime 1 to 4. A player's
-- archaeologist is its next digging archaeologist, with id, name, x, y, and artifact, with index,
-- type, the site's kind from 0 to 5, acting and target, player IDs, and era. A player's playerName
-- is its leader's name. A player's governors has points, spent, and appointed, each with type, city,
-- with owner and id, established, turnsOnSite, turnsToEstablish, neutralized, loyalty, and
-- promotions, each with type, has, canEarn, base, true for the base ability, level, column, and
-- requires, the types of the promotions it follows, hiddenWithoutPrereqs, true for one that the panel
-- hides until its governor holds them, and canPromote, cityStates, true for one that can
-- govern city-states, and abroad, true for one that can go to other players' capitals. Its candidates
-- lists the governors it can appoint, each with type, canEver, false for one it never can,
-- turnsToEstablish, loyalty, and promotions, as for an appointed governor. canAppoint is false without a title, and cannotAssignTo maps "owner:id" of a city
-- to the reasons a governor can't go there. world.cannotAssign lists the governors of Secret
-- Societies. Without governors the player has no GetGovernors, as without Rise and Fall.
-- world.offCapabilities lists the great people capabilities that are off. A player's
-- blockers lists its end-turn
-- blockers by name, in the game's order, such as
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

-- The game's city transfer types, of which the raze screen checks only BY_GIFT.
local CITY_TRANSFER_TYPES = { BY_GIFT = 7 }

-- A captured or rebelled city from data, with the calls the raze and disloyal city screens make.
local function ChangedCity(data)
	return {
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
		GetDistricts = function()
			return {
				GetNumZonedDistrictsRequiringPopulation = function()
					return data.districts or 0
				end,
			}
		end,
		GetOriginalOwner = function()
			return data.originalOwner
		end,
		GetOwnerBeforeOccupation = function()
			return data.ownerBefore
		end,
		GetJustConqueredFrom = function()
			return data.conqueredFrom
		end,
		GetLastTransferType = function()
			return data.gift and CITY_TRANSFER_TYPES.BY_GIFT or 0
		end,
		CanRaze = function()
			return data.canRaze ~= false
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
	ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE = 1385632321,
	ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY = 2048525187,
	ENDTURN_BLOCKING_ARTIFACT = -234935529,
}

-- The MilitaryFormationTypes values. The tests don't depend on the game's numbers.
local MILITARY_FORMATION_TYPES = { STANDARD_MILITARY_FORMATION = 0, CORPS_MILITARY_FORMATION = 1, ARMY_MILITARY_FORMATION = 2 }

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
-- its GameInfo row. data.options.projects lists each project the build queue knows, with type,
-- cost, turns, progress, blocked, and hidden, and maxPlayerInstances, which goes in its GameInfo
-- row. data.options.purchasable lists more tiles
-- to buy, by x and y, each with cost, its gold cost. data.purchases maps a yield name, such as YIELD_GOLD, to the units,
-- buildings, and districts the city can buy with it. Each has type, cost, blocked, hidden, which the
-- check refuses even when it only tests, and cantAfford, and a unit has corps and army, each with
-- cost, blocked, and cantAfford. A faith purchase has faithEnabled when the game marks it for
-- another yield but the city can buy it with faith. hashes maps each production, unit, building, and district type to its hash,
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

	-- Each district and project option by its hash, its index, and its type.
	local districtsByHash, districtsByIndex, districtsByType = {}, {}, {}
	local projectsByHash, projectsByIndex, projectsByType = {}, {}, {}

	for _, project in ipairs((data.options or {}).projects or {}) do
		projectsByHash[hashes[project.type]] = project
		projectsByIndex[indexes[project.type]] = project
		projectsByType[project.type] = project
	end

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

	-- Returns the purchase option for an item's hash and a yield's index, or its corps or army for a
	-- formation, or nil.
	local function PurchaseOption(yieldIndex, hash, formation)
		for name, row in pairs(YIELD_ROWS) do
			if row.Index == yieldIndex then
				for _, kind in ipairs({ "units", "buildings", "districts" }) do
					for _, option in ipairs(((data.purchases or {})[name] or {})[kind] or {}) do
						if hashes[option.type] == hash then
							return Formation(option, formation)
						end
					end
				end
			end
		end
	end

	local city = {
		-- The purchase option for an item, for the fake CityManager.CanStartCommand and treasury.
		PurchaseOption = PurchaseOption,
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
		GetGold = function()
			return {
				GetPurchaseCost = function(_, yieldIndex, hash, formation)
					return PurchaseOption(yieldIndex, hash, formation).cost
				end,
				-- The cost of a tile to buy, from its tile in data.options.purchasable, or 0.
				GetPlotPurchaseCost = function(_, plotIndex)
					for _, tile in ipairs((data.options or {}).purchasable or {}) do
						if PlotIndex(tile.x, tile.y) == plotIndex then
							return tile.cost or 0
						end
					end

					return 0
				end,
				-- Whether the city can buy a unit or a building with faith that the game marks for
				-- another yield. The option is under YIELD_FAITH with faithEnabled.
				IsUnitFaithPurchaseEnabled = function(_, hash)
					local option = PurchaseOption(YIELD_ROWS.YIELD_FAITH.Index, hash)

					return option ~= nil and option.faithEnabled == true
				end,
				IsBuildingFaithPurchaseEnabled = function(_, hash)
					local option = PurchaseOption(YIELD_ROWS.YIELD_FAITH.Index, hash)

					return option ~= nil and option.faithEnabled == true
				end,
			}
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

					if projectsByType[typeOrHash] ~= nil then
						return projectsByType[typeOrHash].turns
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
						local option = buildingsByHash[params] or districtsByHash[params] or projectsByHash[params]

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
				GetProjectCost = function(_, index)
					return projectsByIndex[index].cost
				end,
				GetProjectProgress = function(_, index)
					return projectsByIndex[index].progress or 0
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
		-- The religions in the city, from data.religions, each with type and followers, and the
		-- majority religion, from data.majority, by their GameInfo indexes.
		GetReligion = function()
			return {
				GetMajorityReligion = function()
					return data.majority and indexes[data.majority] or -1
				end,
				GetReligionsInCity = function()
					local present = {}

					for i, religion in ipairs(data.religions or {}) do
						present[i] = { Religion = indexes[religion.type] or -1, Followers = religion.followers }
					end

					return present
				end,
			}
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

local function Player(id, data, hashes, indexes, env)
	local cities, units = {}, {}
	local techData, civicData, governmentData = data.techs or {}, data.civics or {}, data.government or {}

	-- Each tech and civic option by its GameInfo index, and each policy by its hash.
	local techsByIndex, civicsByIndex, policiesByHash = {}, {}, {}

	for _, policy in ipairs(data.policies or {}) do
		policiesByHash[hashes[policy.type]] = policy
	end

	for _, tech in ipairs(techData.options or {}) do
		techsByIndex[indexes[tech.type]] = tech
	end

	for _, civic in ipairs(civicData.options or {}) do
		civicsByIndex[indexes[civic.type]] = civic
	end

	-- The player's store of a yield, which can afford an item in a city unless the city's purchase
	-- option for it has cantAfford.
	local function Store(yieldIndex)
		return {
			CanAfford = function(_, cityID, hash, formation)
				local option = List(cities):FindID(cityID).PurchaseOption(yieldIndex, hash, formation)

				return option == nil or option.cantAfford ~= true
			end,
		}
	end
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
		-- The player's cities, and the next city it captured and the next that rebelled to join it,
		-- from data.captured and data.rebelled. Without Rise and Fall there is no
		-- GetNextRebelledCity.
		GetCities = function()
			local list = List(cities)

			function list.GetNextCapturedCity()
				return data.captured and ChangedCity(data.captured)
			end

			-- The city with capital set, which a major player has.
			function list.GetCapitalCity()
				for _, city in ipairs(cities) do
					if city.IsCapital() then
						return city
					end
				end
			end

			if not data.noRiseAndFall then
				function list.GetNextRebelledCity()
					return data.rebelled and ChangedCity(data.rebelled)
				end
			end

			return list
		end,
		IsFreeCities = function()
			return data.freeCities == true
		end,
		GetStats = function()
			return {
				GetHasRevivedPlayer = function(_, otherID)
					for _, revived in ipairs(data.revived or {}) do
						if revived == otherID then
							return true
						end
					end

					return false
				end,
			}
		end,
		GetTechs = function()
			return {
				GetResearchingTech = function()
					return techData.current and indexes[techData.current] or -1
				end,
				CanResearch = function(_, index)
					return techsByIndex[index] ~= nil and not techsByIndex[index].locked
				end,
				GetResearchCost = function(_, index)
					return techsByIndex[index].cost
				end,
				GetResearchProgress = function(_, index)
					return techsByIndex[index].progress or 0
				end,
				GetTurnsToResearch = function(_, index)
					return techsByIndex[index].turns
				end,
				HasBoostBeenTriggered = function(_, index)
					return techsByIndex[index].boost.triggered == true
				end,
				HasTech = function(_, index)
					return techsByIndex[index] ~= nil and techsByIndex[index].researched == true
				end,
				IsTechRevealed = function(_, index)
					return techsByIndex[index] ~= nil and techsByIndex[index].hidden ~= true
				end,
				GetTurnsLeft = function()
					return techData.turnsLeft or -1
				end,
			}
		end,
		GetDiplomacy = function()
			return {
				HasMet = function(_, otherID)
					for _, met in ipairs(data.met or {}) do
						if met == otherID then
							return true
						end
					end

					return false
				end,
				GetNextEscapingSpyID = function()
					return data.escapingSpy and data.escapingSpy.id or -1
				end,
				CanLiberateCityTo = function(_, otherID)
					for _, liberate in ipairs(data.liberate or {}) do
						if liberate == otherID then
							return true
						end
					end

					return false
				end,
				-- The warmonger points of keeping or razing, from data.captured.warmonger.
				ComputeCityWarmongerPoints = function(_, _, _, raze)
					local warmonger = data.captured.warmonger or {}

					return (raze and warmonger.raze or warmonger.keep) or 0
				end,
				GetWarmongerLevel = function(_, points)
					return "LOC_WARMONGER_LEVEL_" .. points
				end,
			}
		end,
		GetCulture = function()
			return {
				GetProgressingCivic = function()
					return civicData.current and indexes[civicData.current] or -1
				end,
				CanProgress = function(_, index)
					return civicsByIndex[index] ~= nil and not civicsByIndex[index].locked
				end,
				GetCultureCost = function(_, index)
					return civicsByIndex[index].cost
				end,
				GetCulturalProgress = function(_, index)
					return civicsByIndex[index].progress or 0
				end,
				GetTurnsToProgressCivic = function(_, index)
					return civicsByIndex[index].turns
				end,
				HasCivic = function(_, index)
					return civicsByIndex[index] ~= nil and civicsByIndex[index].researched == true
				end,
				IsCivicRevealed = function(_, index)
					return civicsByIndex[index] ~= nil and civicsByIndex[index].hidden ~= true
				end,
				GetTurnsLeft = function()
					return civicData.turnsLeft or -1
				end,
				GetCurrentGovernment = function()
					return governmentData.type and indexes[governmentData.type] or -1
				end,
				GetNumPolicySlots = function()
					return #(governmentData.slots or {})
				end,
				GetSlotType = function(_, i)
					return indexes[governmentData.slots[i + 1].type]
				end,
				GetSlotPolicy = function(_, i)
					local policy = governmentData.slots[i + 1].policy

					return policy and indexes[policy] or -1
				end,
				CivicCompletedThisTurn = function()
					return governmentData.civicThisTurn ~= nil
				end,
				CanChangeGovernmentAtAll = function()
					return governmentData.canChangeAtAll == true
				end,
				GovernmentChangeMade = function()
					return governmentData.governmentChangeMade == true
				end,
				-- The player's current government is always unlocked.
				IsGovernmentUnlocked = function(_, hash)
					for _, typeName in ipairs(governmentData.unlocked or {}) do
						if hashes[typeName] == hash then
							return true
						end
					end

					return governmentData.type ~= nil and hashes[governmentData.type] == hash
				end,
				GetAnarchyTurns = function(_, index)
					return (governmentData.anarchy or {})[env.GameInfo.Governments[index].GovernmentType] or 0
				end,
				GetCivicCompletedThisTurn = function()
					return governmentData.civicThisTurn and indexes[governmentData.civicThisTurn] or -1
				end,
				GetNumPolicySlotsOpen = function()
					return governmentData.slotsOpen or 0
				end,
				PolicyChangeMade = function()
					return governmentData.changeMade == true
				end,
				GetCostToUnlockPolicies = function()
					return governmentData.unlockCost or 0
				end,
				IsPolicyUnlocked = function(_, hash)
					return policiesByHash[hash] ~= nil and policiesByHash[hash].locked ~= true
				end,
				IsPolicyObsolete = function(_, hash)
					return policiesByHash[hash] ~= nil and policiesByHash[hash].obsolete == true
				end,
				IsPolicyBanned = function(_, hash)
					return policiesByHash[hash] ~= nil and policiesByHash[hash].banned == true
				end,
				-- In Gathering Storm, a locked policy can't be slotted either.
				CanPolicyBeSlotted = function(_, hash)
					local policy = policiesByHash[hash]

					return policy ~= nil and policy.locked ~= true and policy.unslottable ~= true
				end,
				IsPolicyActive = function(_, hash)
					for _, slot in ipairs(governmentData.slots or {}) do
						if slot.policy ~= nil and hashes[slot.policy] == hash then
							return true
						end
					end

					return false
				end,
				HasBoostBeenTriggered = function(_, index)
					return civicsByIndex[index].boost.triggered == true
				end,
			}
		end,
		GetGrandStrategicAI = function()
			-- Returns the recommended options, each with its hash in field.
			local function Recommendations(options, field)
				local recommendations = {}

				for _, option in ipairs(options or {}) do
					if option.recommended then
						recommendations[#recommendations + 1] = { [field] = hashes[option.type] }
					end
				end

				return recommendations
			end

			return {
				GetTechRecommendations = function()
					return Recommendations(techData.options, "TechHash")
				end,
				GetCivicsRecommendations = function()
					return Recommendations(civicData.options, "CivicHash")
				end,
			}
		end,
		-- The player's gold and faith. Each can afford an item unless its purchase option for that
		-- yield has cantAfford.
		GetTreasury = function()
			local treasury = Store(YIELD_ROWS.YIELD_GOLD.Index)

			-- The player's gold, from data.gold, which is 0 when missing.
			function treasury.GetGoldBalance()
				return data.gold or 0
			end

			return treasury
		end,
		-- The player's points toward each class of great person, from data.greatPeoplePoints by class
		-- type, each with points and perTurn.
		GetGreatPeoplePoints = function()
			local function Points(classIndex)
				return (data.greatPeoplePoints or {})[env.GameInfo.GreatPersonClasses[classIndex].GreatPersonClassType] or {}
			end

			return {
				GetPointsTotal = function(_, classIndex)
					return Points(classIndex).points or 0
				end,
				GetPointsPerTurn = function(_, classIndex)
					return Points(classIndex).perTurn or 0
				end,
			}
		end,
		-- The player's influence, from data.influence, and for a city-state, from data.minor.
		GetInfluence = function()
			local influence = data.influence or {}
			local minor = data.minor or {}

			local result = {
				GetTokensToGive = function()
					return influence.tokens or 0
				end,
				CanGiveInfluence = function()
					return influence.canGive ~= false
				end,
				GetPointsEarned = function()
					return influence.points or 0
				end,
				GetPointsPerTurn = function()
					return influence.perTurn or 0
				end,
				GetPointsThreshold = function()
					return influence.threshold or 50
				end,
				GetTokensPerThreshold = function()
					return influence.envoys or 1
				end,
				-- A city-state that can receive envoys, which the player has met and isn't at war
				-- with.
				CanGiveTokensToPlayer = function(_, otherID)
					local other = env.Players[otherID]

					for _, enemy in ipairs(data.atWar or {}) do
						if enemy == otherID then
							return false
						end
					end

					return other:GetInfluence():CanReceiveInfluence() and env.Players[id]:GetDiplomacy():HasMet(otherID)
				end,
				CanReceiveInfluence = function()
					return data.minor ~= nil and minor.cantReceive ~= true
				end,
				GetTokensReceived = function(_, playerID)
					return (minor.envoys or {})[playerID] or 0
				end,
				GetMostTokensReceived = function()
					local most = 0

					for _, envoys in pairs(minor.envoys or {}) do
						most = math.max(most, envoys)
					end

					return most
				end,
				GetSuzerain = function()
					return minor.suzerain or -1
				end,
			}

			if env.GameInfo.Governments_XP2 ~= nil then
				function result.IsSuzerainUniqueBonusDisabled()
					return minor.uniqueDisabled == true
				end
			end

			return result
		end,
		GetReligion = function()
			local religion = Store(YIELD_ROWS.YIELD_FAITH.Index)

			-- The player's faith, from data.faith, which is 0 when missing.
			function religion.GetFaithBalance()
				return data.faith or 0
			end

			-- The index of the player's pantheon belief, from data.pantheon, or -1 for none.
			function religion.GetPantheon()
				return data.pantheon and indexes[data.pantheon] or -1
			end

			function religion.CanCreatePantheon()
				return data.canCreatePantheon == true
			end

			-- The religion the player founded, from data.religion, with type and holyCity, a city ID.
			-- The beliefs earned come from data.beliefsEarned, the count of its beliefs when missing.
			local founded = data.religion or {}

			function religion.GetReligionTypeCreated()
				return founded.type and indexes[founded.type] or -1
			end

			function religion.GetHolyCityID()
				return { player = id, id = founded.holyCity }
			end

			function religion.GetNumBeliefsEarned()
				return data.beliefsEarned or #(founded.beliefs or {})
			end

			function religion.HasReligiousFoundingUnit()
				return data.prophet == true
			end

			return religion
		end,
		-- The player's units, and its escaping spy from data.escapingSpy, which FindID alone finds.
		GetUnits = function()
			local list = List(units)
			local spy = data.escapingSpy

			-- The next digging archaeologist, from data.archaeologist.
			function list.GetNextExtractingArchaeologist()
				local archaeologist = data.archaeologist

				return archaeologist and {
					GetID = function()
						return archaeologist.id
					end,
					GetName = function()
						return archaeologist.name
					end,
					GetX = function()
						return archaeologist.x
					end,
					GetY = function()
						return archaeologist.y
					end,
					GetArchaeology = function()
						return {
							GetArtifactIndex = function()
								return archaeologist.artifact.index
							end,
						}
					end,
				}
			end

			if spy ~= nil then
				local findID = list.FindID

				function list.FindID(self, unitID)
					if unitID ~= spy.id then
						return findID(self, unitID)
					end

					return {
						GetID = function()
							return spy.id
						end,
						GetX = function()
							return spy.x
						end,
						GetY = function()
							return spy.y
						end,
						GetName = function()
							return spy.name
						end,
						GetLootName = function()
							return spy.loot
						end,
						GetPursuingSpyName = function()
							return spy.pursuer or ""
						end,
					}
				end
			end

			return list
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
		-- The resources a city-state has, from data.minor.resources, each with amount, exported,
		-- and perTurn, which only Gathering Storm reads.
		GetResources = function()
			local owned = {}

			for _, resource in ipairs((data.minor or {}).resources or {}) do
				owned[indexes[resource.type]] = resource
			end

			local resources = {
				IsResourceVisible = function(_, hash)
					return not hidden[hash]
				end,
				HasResource = function(_, index)
					return owned[index] ~= nil and (owned[index].amount or 0) > 0
				end,
				HasExportedResource = function(_, index)
					return owned[index] ~= nil and (owned[index].exported or 0) > 0
				end,
				GetResourceAmount = function(_, index)
					return owned[index] and owned[index].amount or 0
				end,
				GetExportedResourceAmount = function(_, index)
					return owned[index] and owned[index].exported or 0
				end,
			}

			if env.GameInfo.Governments_XP2 ~= nil then
				function resources.GetResourceAccumulationPerTurn(_, index)
					return owned[index] and owned[index].perTurn or 0
				end
			end

			return resources
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
		Projects = {},
		Technologies = {},
		Civics = {},
		Boosts = {},
		Eras = {
			ERA_ANCIENT = { ChronologyIndex = 1 },
			ERA_CLASSICAL = { ChronologyIndex = 2 },
			ERA_MEDIEVAL = { ChronologyIndex = 3 },
		},
		Yields = YIELD_ROWS,
		Buildings = {},
		Units = {},
		UnitPromotions = {},
		Terrains = {},
		Features = {},
		Resources = {},
		Improvements = {},
		Routes = {},
		Happinesses = HAPPINESSES,
		Governments = {},
		GovernmentSlots = {},
		Policies = {},
		Beliefs = {},
		Religions = {},
		Leaders = {},
		LeaderTraits = {},
		Traits = {},
		Quests = {},
		GreatPersonClasses = {},
		Governors = {},
		GovernorPromotions = {},
		GovernorPromotionSets = {},
		GovernorsCannotAssign = {},
		GovernorPromotionPrereqs = {},
		GovernorPromotionConditions = {},
		GreatPersonIndividuals = {},
		Government_SlotCounts = {},
		GovernmentModifiers = {},
		ModifierArguments = {},
	}
	-- GameInfo.Units(), GameInfo.Buildings(), GameInfo.Districts(), and GameInfo.Projects() list the
	-- rows in index order, as the game's tables do when called, and each table finds a row by its type
	-- name, as in GameInfo.Districts["DISTRICT_CAMPUS"].
	for name, column in pairs({
		Units = "UnitType",
		Buildings = "BuildingType",
		Districts = "DistrictType",
		Projects = "ProjectType",
		Technologies = "TechnologyType",
		Civics = "CivicType",
		Boosts = "TechnologyType",
		Policies = "PolicyType",
		Governments = "GovernmentType",
		Beliefs = "BeliefType",
		Religions = "ReligionType",
		Resources = "ResourceType",
		Quests = "QuestType",
		Governors = "GovernorType",
		GovernorPromotions = "GovernorPromotionType",
	}) do
		setmetatable(env.GameInfo[name], {
			__index = function(rows, key)
				if type(key) == "string" then
					for index = 0, #rows do
						local row = rawget(rows, index)

						if row ~= nil and row[column] == key then
							return row
						end
					end
				end
			end,
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
		-- The city that a component ID, such as a holy city's, names.
		GetCity = function(componentID)
			local player = env.Players[componentID.player]

			return player and player:GetCities():FindID(componentID.id)
		end,
		GetOperationTargets = function(city, operation, params)
			assert(operation == CITY_OPERATION_TYPES.BUILD, "no fake for this operation")

			return { [CITY_OPERATION_RESULTS.PLOTS] = city.PlacementPlots(params) }
		end,
		-- With testOnly, whether the city's purchases list the item that params names. Without it,
		-- whether the city can buy it now, and the results: the reasons it can't, and for a unit,
		-- whether a corps or an army can be bought.
		CanStartCommand = function(city, command, testOnly, params, withResults)
			assert(command == CITY_COMMAND_TYPES.PURCHASE, "no fake for this command")

			local hash = params[CITY_COMMAND_TYPES.PARAM_UNIT_TYPE] or params[CITY_COMMAND_TYPES.PARAM_BUILDING_TYPE] or params[CITY_COMMAND_TYPES.PARAM_DISTRICT_TYPE]
			local yieldIndex = params[CITY_COMMAND_TYPES.PARAM_YIELD_TYPE]
			local option = city.PurchaseOption(yieldIndex, hash)

			if testOnly then
				return option ~= nil and not option.hidden
			end

			assert(withResults == true, "no fake without results")

			local formationOption = city.PurchaseOption(yieldIndex, hash, params[CITY_COMMAND_TYPES.PARAM_MILITARY_FORMATION_TYPE])

			return formationOption.blocked == nil and formationOption.cantAfford ~= true, {
				[CITY_COMMAND_RESULTS.FAILURE_REASONS] = formationOption.blocked,
				[CITY_OPERATION_RESULTS.CAN_TRAIN_CORPS] = option.corps ~= nil or nil,
				[CITY_OPERATION_RESULTS.CAN_TRAIN_ARMY] = option.army ~= nil or nil,
			}
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

	-- Adds a policy's row with a hash. A policy in a slot alone has only its type.
	local function AddPolicy(policy)
		AddRow("Policies", "PolicyType", policy.type)

		local row = env.GameInfo.Policies[indexes[policy.type]]

		if hashes[policy.type] == nil then
			count = count + 1
			hashes[policy.type] = 4000000 + count
		end

		row.Hash = hashes[policy.type]
		row.GovernmentSlotType = row.GovernmentSlotType or policy.slot
		row.Description = row.Description or policy.description
		row.PrereqCivic = row.PrereqCivic or policy.civic
	end

	-- Each belief in world.beliefs gets a row.
	for _, belief in ipairs(world.beliefs or {}) do
		AddRow("Beliefs", "BeliefType", belief.type)

		local row = env.GameInfo.Beliefs[indexes[belief.type]]

		row.BeliefClassType = belief.class or "BELIEF_CLASS_PANTHEON"
		row.Description = belief.description
		row.taken = belief.taken
		row.tooMany = belief.tooMany
	end

	-- Each religion in world.religions gets a row.
	for _, religion in ipairs(world.religions or {}) do
		AddRow("Religions", "ReligionType", religion.type)

		local row = env.GameInfo.Religions[indexes[religion.type]]

		row.Pantheon = religion.pantheon == true
		row.RequiresCustomName = religion.customName == true
		row.founded = religion.founded
	end

	-- Each religion that a player founded or a city holds gets a row, with its name, and each of a
	-- founded religion's beliefs a belief row.
	for _, data in pairs(world.players or {}) do
		local religions = { data.religion }

		for _, city in ipairs(data.cities or {}) do
			for _, present in ipairs(city.religions or {}) do
				religions[#religions + 1] = present
			end
		end

		for _, religion in ipairs(religions) do
			AddRow("Religions", "ReligionType", religion.type)
			local row = env.GameInfo.Religions[indexes[religion.type]]

			row.Name = religion.name or row.Name or religion.type

			for _, belief in ipairs(religion.beliefs or {}) do
				AddRow("Beliefs", "BeliefType", belief)
			end
		end
	end

	-- Each appointed governor gets a row, with its name, title, and a made-up hash, and each of its
	-- promotions a row and a place in its set.
	for _, data in pairs(world.players or {}) do
		local governorData = data.governors or {}

		-- Rows for a governor's promotions, with their place in its tree and their prerequisites.
		local function AddPromotions(governor)
			for _, promotion in ipairs(governor.promotions or {}) do
				AddRow("GovernorPromotions", "GovernorPromotionType", promotion.type)

				local promotionRow = env.GameInfo.GovernorPromotions[indexes[promotion.type]]

				promotionRow.Name = "LOC_" .. promotion.type .. "_NAME"
				promotionRow.Description = "LOC_" .. promotion.type .. "_DESCRIPTION"
				promotionRow.Level = promotion.level or 0
				promotionRow.Column = promotion.column or 0
				promotionRow.BaseAbility = promotion.base == true

				if promotion.hiddenWithoutPrereqs then
					table.insert(env.GameInfo.GovernorPromotionConditions, { GovernorPromotionType = promotion.type, HiddenWithoutPrereqs = true })
				end
				promotionRow.Hash = 4000000 + promotionRow.Index
				table.insert(env.GameInfo.GovernorPromotionSets, { GovernorType = governor.type, GovernorPromotion = promotion.type })

				for _, required in ipairs(promotion.requires or {}) do
					table.insert(env.GameInfo.GovernorPromotionPrereqs, { GovernorPromotionType = promotion.type, PrereqGovernorPromotion = required })
				end
			end
		end

		for _, governor in ipairs(governorData.candidates or {}) do
			AddRow("Governors", "GovernorType", governor.type)

			local row = env.GameInfo.Governors[indexes[governor.type]]

			row.Name = "LOC_" .. governor.type .. "_NAME"
			row.Title = "LOC_" .. governor.type .. "_TITLE"
			row.Description = "LOC_" .. governor.type .. "_DESCRIPTION"
			row.IdentityPressure = governor.loyalty or 8
			row.Hash = 3000000 + row.Index
			AddPromotions(governor)
		end

		for _, governor in ipairs(governorData.appointed or {}) do
			AddRow("Governors", "GovernorType", governor.type)

			local row = env.GameInfo.Governors[indexes[governor.type]]

			row.Name = "LOC_" .. governor.type .. "_NAME"
			row.Title = "LOC_" .. governor.type .. "_TITLE"
			row.Description = "LOC_" .. governor.type .. "_DESCRIPTION"
			row.IdentityPressure = 8
			row.Hash = 3000000 + row.Index
			AddPromotions(governor)
		end
	end

	-- The Secret Societies governors that can't be assigned to a city.
	for _, governorType in ipairs(world.cannotAssign or {}) do
		table.insert(env.GameInfo.GovernorsCannotAssign, { GovernorType = governorType, CannotAssign = true })
	end

	-- Each artifact's era gets a row.
	for _, data in pairs(world.players or {}) do
		if data.archaeologist ~= nil then
			AddRow("Eras", "EraType", data.archaeologist.artifact.era)
		end
	end

	-- With an escaping spy, each escape district gets a row, with its travel time and name.
	for _, data in pairs(world.players or {}) do
		if data.escapingSpy ~= nil then
			for i, districtType in ipairs({ "DISTRICT_AERODROME", "DISTRICT_HARBOR", "DISTRICT_COMMERCIAL_HUB", "DISTRICT_CITY_CENTER" }) do
				AddRow("Districts", "DistrictType", districtType)

				local row = env.GameInfo.Districts[indexes[districtType]]

				row.TravelTime = i
				row.Name = "LOC_" .. districtType .. "_NAME"
			end
		end
	end

	-- Each great person on offer gets rows for its class, era, and individual.
	for _, person in ipairs(world.greatPeople or {}) do
		AddRow("GreatPersonClasses", "GreatPersonClassType", person.class)
		AddRow("Eras", "EraType", person.era)
		AddRow("GreatPersonIndividuals", "GreatPersonIndividualType", person.type)

		local row = env.GameInfo.GreatPersonIndividuals[indexes[person.type]]

		row.Name = person.name or person.type
		row.ActionCharges = person.charges or 0
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

	-- Each government in world.governments gets its row, its slot counts, the modifier that holds
	-- its legacy percent, and its Gathering Storm row with its favor.
	local governmentsXP2 = Callable({})

	for _, government in ipairs(world.governments or {}) do
		AddRow("Governments", "GovernmentType", government.type)

		local row = env.GameInfo.Governments[indexes[government.type]]
		local influence = government.influence or {}

		count = count + 1
		hashes[government.type] = 4000000 + count
		row.Hash = hashes[government.type]
		row.PrereqCivic = government.civic
		row.BonusType = government.bonusType or "NO_GOVERNMENTBONUS"
		row.InherentBonusDesc = (government.bonuses or {})[1]
		row.AccumulatedBonusShortDesc = (government.bonuses or {})[2]
		row.InfluencePointsPerTurn = influence.perTurn or 1
		row.InfluencePointsThreshold = influence.threshold or 100
		row.InfluenceTokensPerThreshold = influence.envoys or 1

		for slotType, slotCount in pairs(government.slots or {}) do
			table.insert(env.GameInfo.Government_SlotCounts, { GovernmentType = government.type, GovernmentSlotType = slotType, NumSlots = slotCount })
		end

		if government.legacyPercent ~= nil then
			local modifierID = "MODIFIER_" .. government.type

			table.insert(env.GameInfo.GovernmentModifiers, { GovernmentType = government.type, ModifierId = modifierID })
			table.insert(env.GameInfo.ModifierArguments, { ModifierId = modifierID, Name = "BonusType", Value = row.BonusType })
			table.insert(env.GameInfo.ModifierArguments, { ModifierId = modifierID, Name = "Amount", Value = tostring(government.legacyPercent) })
		end

		table.insert(governmentsXP2, { GovernmentType = government.type, Favor = government.favor or 0 })
	end

	Callable(env.GameInfo.Government_SlotCounts)
	Callable(env.GameInfo.LeaderTraits)
	Callable(env.GameInfo.GovernorPromotionSets)
	Callable(env.GameInfo.GovernorsCannotAssign)
	Callable(env.GameInfo.GovernorPromotionPrereqs)
	Callable(env.GameInfo.GovernorPromotionConditions)
	Callable(env.GameInfo.GovernmentModifiers)
	Callable(env.GameInfo.ModifierArguments)

	-- Each government, slot type, policy, and civic completed this turn gets a row.
	for _, data in pairs(world.players or {}) do
		local government = data.government or {}

		if government.type ~= nil then
			AddRow("Governments", "GovernmentType", government.type)
		end

		if government.civicThisTurn ~= nil then
			AddRow("Civics", "CivicType", government.civicThisTurn)
		end

		for _, slot in ipairs(government.slots or {}) do
			AddRow("GovernmentSlots", "GovernmentSlotType", slot.type)

			if slot.policy ~= nil then
				AddPolicy({ type = slot.policy })
			end
		end

		for _, policy in ipairs(data.policies or {}) do
			AddPolicy(policy)
		end
	end

	-- A government only a player names gets a hash and the default influence.
	for _, row in pairs(env.GameInfo.Governments) do
		if row.Hash == nil then
			count = count + 1
			hashes[row.GovernmentType] = 4000000 + count
			row.Hash = hashes[row.GovernmentType]
			row.BonusType = "NO_GOVERNMENTBONUS"
			row.InfluencePointsPerTurn, row.InfluencePointsThreshold, row.InfluenceTokensPerThreshold = 1, 100, 1
		end
	end

	-- Gathering Storm's rows, the faith rule for paying to change policies, and the World Congress.
	env.GameInfo.Governments_XP2 = world.expansion2 and governmentsXP2 or nil
	env.GameCapabilities = {
		HasCapability = function(capability)
			return (capability == "CAPABILITY_GOVERNMENTS_LEGACY_BONUSES" and world.legacyBonuses == true)
				or (capability == "CAPABILITY_RENAME" and world.rename == true)
				or (capability:find("^CAPABILITY_GREAT_PEOPLE_") ~= nil and not (world.offCapabilities or {})[capability])
		end,
	}
	env.GlobalParameters = {
		GOVERNMENT_UNLOCK_WITH_FAITH = world.unlockWithFaith and 1 or 0,
		FAVOR_FOR_LIBERATE_PLAYER_CITY = 100,
		FAVOR_FOR_LIBERATE_CITY_STATE = 50,
		FAVOR_FOR_REVIVE_PLAYER = 20,
		WARMONGER_FINAL_MAJOR_CITY_MULTIPLIER = 200,
	}
	env.CityDestroyDirectives = { LIBERATE_FOUNDER = 0, LIBERATE_PREVIOUS_OWNER = 1, KEEP = 2, RAZE = 3, REJECT = 4 }
	env.CivilizationLevelTypes = { CIVILIZATION_LEVEL_FULL_CIV = 0 }
	env.CityTransferTypes = CITY_TRANSFER_TYPES
	env.PlayerOperationResults = { FAILURE_REASONS = 9001 }
	env.Cities = {
		-- The city of any player on the tile x, y, where an escaping spy is.
		GetPlotPurchaseCity = function(x, y)
			for id = 0, 63 do
				for _, city in (env.Players[id] and env.Players[id]:GetCities() or List({})):Members() do
					if city:GetX() == x and city:GetY() == y then
						return city
					end
				end
			end
		end,
	}

	-- Each tech and civic gets a row, a hash, and a boost row when it has a boost. The game's
	-- GetUnlockablesForTech and GetUnlockablesForCivic return what one unlocks as { type, name, key }
	-- rows.
	local unlocksByType = {}

	for _, data in pairs(world.players or {}) do
		for _, kind in ipairs({ { data.techs, "Technologies", "TechnologyType" }, { data.civics, "Civics", "CivicType" } }) do
			for _, option in ipairs((kind[1] or {}).options or {}) do
				AddRow(kind[2], kind[3], option.type)
				count = count + 1
				hashes[option.type] = hashes[option.type] or 4000000 + count

				local row = env.GameInfo[kind[2]][indexes[option.type]]

				row.Hash = hashes[option.type]
				row.Description = option.description
				row.EraType = option.era or "ERA_ANCIENT"
				unlocksByType[option.type] = option.unlocks

				if option.boost ~= nil then
					local boosts = env.GameInfo.Boosts

					boosts[#boosts + (boosts[0] and 1 or 0)] = { [kind[3]] = option.type, Boost = option.boost.percent, TriggerDescription = option.boost.trigger }
				end
			end
		end
	end

	-- Returns the unlock rows of a tech or civic type.
	local function UnlockRows(typeName)
		local rows = {}

		for i, unlock in ipairs(unlocksByType[typeName] or {}) do
			rows[i] = { unlock, unlock, unlock }
		end

		return rows
	end

	env.GetFilteredUnlockableItems = function()
		return {}
	end
	env.GetUnlockablesForTech = UnlockRows
	env.GetUnlockablesForCivic = UnlockRows

	-- Returns the nodes of a tree from player 0's techs or civics, in order, with their type in
	-- nameField, Name for a tech and CivicName for a civic, and their prerequisites in field.
	local function TreeNodes(key, nameField, field)
		local nodes = {}
		local options = (((world.players or {})[0] or {})[key] or {}).options or {}

		for i, option in ipairs(options) do
			nodes[i] = { [nameField] = option.type, [field] = option.prerequisites or {} }
		end

		return nodes
	end

	env.UITree = {
		GetAvailableTechs = function()
			return TreeNodes("techs", "Name", "PrereqTechTypes")
		end,
		GetAvailableCivics = function()
			return TreeNodes("civics", "CivicName", "PrereqCivicTypes")
		end,
	}

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
				end
			end
		end
	end

	-- A city-state's resources and quests get their rows.
	for _, data in pairs(world.players or {}) do
		for _, resource in ipairs((data.minor or {}).resources or {}) do
			AddRow("Resources", "ResourceType", resource.type)
		end

		for _, quests in pairs((data.minor or {}).quests or {}) do
			for _, quest in ipairs(quests) do
				AddRow("Quests", "QuestType", quest.type)
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
	env.PlayerConfigurations = {}

	for id, data in pairs(world.players or {}) do
		env.Players[id] = Player(id, data, hashes, indexes, env)

		-- The player's governors, from data.governors.
		if data.governors ~= nil then
			local governorData = data.governors

			env.Players[id].GetGovernors = function()
				local list = {}

				for i, governor in ipairs(governorData.appointed or {}) do
					local held = {}

					for _, promotion in ipairs(governor.promotions or {}) do
						if promotion.has then
							held[env.GameInfo.GovernorPromotions[promotion.type].Hash] = true
						end
					end

					list[i] = {
						GetType = function()
							return indexes[governor.type]
						end,
						GetAssignedCity = function()
							local city = governor.city

							return city and {
								GetOwner = function()
									return city.owner
								end,
								GetID = function()
									return city.id
								end,
							}
						end,
						IsEstablished = function()
							return governor.established == true
						end,
						GetTurnsOnSite = function()
							return governor.turnsOnSite or 0
						end,
						GetTurnsToEstablish = function()
							return governor.turnsToEstablish or 5
						end,
						GetNeutralizedTurns = function()
							return governor.neutralized or 0
						end,
						GetIdentityPressure = function()
							return governor.loyalty or 8
						end,
						HasPromotion = function(_, hash)
							return held[hash] == true
						end,
						IsGovernCityState = function()
							return governor.cityStates == true
						end,
						CanAssignToMajorCiv = function()
							return governor.abroad == true
						end,
					}
				end

				-- The candidates by hash, and the promotions each appointed governor can earn.
				local candidates, earnable, appointed = {}, {}, {}

				for _, candidate in ipairs(governorData.candidates or {}) do
					candidates[env.GameInfo.Governors[indexes[candidate.type]].Hash] = candidate
				end

				for _, governor in ipairs(governorData.appointed or {}) do
					appointed[env.GameInfo.Governors[indexes[governor.type]].Hash] = governor

					for _, promotion in ipairs(governor.promotions or {}) do
						earnable[env.GameInfo.GovernorPromotions[indexes[promotion.type]].Hash] = promotion.canEarn == true
					end
				end

				return {
					GetGovernorPoints = function()
						return governorData.points or 0
					end,
					GetGovernorPointsSpent = function()
						return governorData.spent or 0
					end,
					GetGovernorList = function()
						return #list > 0, list
					end,
					CanAppoint = function()
						return governorData.canAppoint ~= false
					end,
					HasGovernor = function(_, hash)
						return appointed[hash] ~= nil
					end,
					CanEverAppointGovernor = function(_, hash)
						return candidates[hash] ~= nil and candidates[hash].canEver ~= false
					end,
					GetTurnsToEstablish = function(_, hash)
						return candidates[hash] and candidates[hash].turnsToEstablish or 5
					end,
					CanPromoteGovernor = function(_, hash)
						return appointed[hash] ~= nil and appointed[hash].canPromote == true
					end,
					CanEarnPromotion = function(_, _, promotionHash)
						return earnable[promotionHash] == true
					end,
					-- Whether a city can take a governor, from governorData.cannotAssignTo, with the game's
					-- failure reasons.
					CanAssignGovernor = function(_, _, city)
						local reasons = (governorData.cannotAssignTo or {})[city:GetOwner() .. ":" .. city:GetID()]

						if reasons == nil then
							return true, {}
						end

						return false, { [env.PlayerOperationResults.FAILURE_REASONS] = reasons }
					end,
				}
			end
		end

		-- A city-state's name and leader, and its leader's row, with the leader it inherits from.
		local minor = data.minor or {}

		env.PlayerConfigurations[id] = {
			GetCivilizationShortDescription = function()
				return minor.name
			end,
			GetLeaderTypeName = function()
				return minor.leader
			end,
			GetCivilizationLevelTypeID = function()
				return data.minor and 1 or 0
			end,
			GetPlayerName = function()
				return data.playerName or ("LOC_LEADER_" .. id .. "_NAME")
			end,
		}

		if minor.leader ~= nil then
			env.GameInfo.Leaders[minor.leader] = { LeaderType = minor.leader, InheritFrom = minor.inherit }
		end

		for i, description in ipairs(minor.traits or {}) do
			local traitType = minor.leader .. "_TRAIT_" .. i

			table.insert(env.GameInfo.LeaderTraits, { LeaderType = minor.leader, TraitType = traitType })
			env.GameInfo.Traits[traitType] = { TraitType = traitType, Description = description }
		end

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

	-- The major players, in ID order, as Game.GetPlayers({ Major = true }) lists them.
	env.Game = env.Game or {}
	env.Game.IsAllowStrategicCommands = function(playerID)
		return (world.players or {})[playerID].noStrategicCommands ~= true
	end
	-- Whether any player's pantheon or religion holds a belief, from each belief's taken.
	env.Game.GetReligion = function()
		local function IsTaken(_, index)
			return env.GameInfo.Beliefs[index].taken == true
		end

		return {
			IsInSomePantheon = IsTaken,
			IsInSomeReligion = IsTaken,
			IsTooManyForReligion = function(_, index)
				return env.GameInfo.Beliefs[index].tooMany == true
			end,
			HasBeenFounded = function(_, index)
				return env.GameInfo.Religions[index].founded == true
			end,
			GetMinimumFaithNextPantheon = function()
				return world.pantheonFaith or 25
			end,
			GetName = function(_, index)
				return env.GameInfo.Religions[index].Name
			end,
			-- Each founded religion, with its index, founder, and belief indexes.
			GetReligions = function()
				local religions = {}

				for playerID, data in pairs(world.players or {}) do
					if data.religion ~= nil then
						local beliefs = {}

						for i, belief in ipairs(data.religion.beliefs or {}) do
							beliefs[i] = indexes[belief]
						end

						religions[#religions + 1] = { Religion = indexes[data.religion.type], Founder = playerID, Beliefs = beliefs }
					end
				end

				return religions
			end,
		}
	end
	-- The artifact of each digging archaeologist, by its index, with the site's type, the acting and
	-- target players, and the acting player's era, by its GameInfo index.
	env.Game.GetArtifactByIndex = function(index)
		for _, data in pairs(world.players or {}) do
			local artifact = data.archaeologist and data.archaeologist.artifact

			if artifact ~= nil and artifact.index == index then
				return { Type = artifact.type, ActingPlayerID = artifact.acting, TargetPlayerID = artifact.target or -1, ActingPlayerEra = indexes[artifact.era] }
			end
		end
	end
	-- The great people on offer, from world.greatPeople, by the GameInfo index of each individual.
	env.Game.GetGreatPeople = function()
		local byIndex = {}

		for _, person in ipairs(world.greatPeople or {}) do
			byIndex[indexes[person.type]] = person
		end

		local function Patronage(index, yield)
			return byIndex[index][yield == YIELD_TYPES.GOLD and "gold" or "faith"] or {}
		end

		return {
			GetTimeline = function()
				local timeline = {}

				for i, person in ipairs(world.greatPeople or {}) do
					local passive, action = person.passive or {}, person.action or {}

					timeline[i] = {
						Individual = (not person.claimed) and indexes[person.type] or nil,
						Class = indexes[person.class],
						Era = indexes[person.era],
						Cost = person.cost,
						PassiveNameText = passive.name,
						PassiveEffectText = passive.effect,
						ActionNameText = action.name,
						ActionUsageText = action.usage,
						ActionEffectText = action.effect,
					}
				end

				return timeline
			end,
			CanRecruitPerson = function(_, _, index)
				return byIndex[index].canRecruit == true
			end,
			CanRejectPerson = function(_, _, index)
				return byIndex[index].passCost ~= nil
			end,
			GetRejectCost = function(_, _, index)
				return byIndex[index].passCost
			end,
			CanPatronizePerson = function(_, _, index, yield)
				return Patronage(index, yield).can == true
			end,
			GetPatronizeCost = function(_, _, index, yield)
				return Patronage(index, yield).cost or 2147483647
			end,
			GetEarnConditionsText = function(_, _, index)
				return byIndex[index].cantEarn or ""
			end,
		}
	end
	-- The quests from data.minor.quests, by the player they are for.
	env.Game.GetQuestsManager = function()
		local function Find(playerID, cityStateID, index)
			local minor = world.players[cityStateID].minor or {}

			for _, quest in ipairs((minor.quests or {})[playerID] or {}) do
				if indexes[quest.type] == index then
					return quest
				end
			end
		end

		return {
			HasActiveQuestFromPlayer = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index) ~= nil
			end,
			GetActiveQuestName = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index).name
			end,
			GetActiveQuestDescription = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index).description
			end,
			GetActiveQuestReward = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index).reward
			end,
		}
	end
	env.Game.GetWorldCongress = function()
		return {
			IsInSession = function()
				return world.congressInSession == true
			end,
		}
	end
	env.Game.GetPlayers = function(filter)
		assert(filter.Major == true, "no fake for this filter")

		local players = {}

		for id = 0, 63 do
			if env.Players[id] ~= nil and world.players[id].minor == nil then
				players[#players + 1] = env.Players[id]
			end
		end

		return players
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
		-- The IDs of the living players without data.minor, in ID order.
		GetAliveMajorIDs = function()
			local ids = {}

			for id = 0, 63 do
				if env.Players[id] ~= nil and world.players[id].minor == nil then
					ids[#ids + 1] = id
				end
			end

			return ids
		end,
		-- The living players without data.minor, in ID order.
		GetAliveMajors = function()
			local majors = {}

			for id = 0, 63 do
				if env.Players[id] ~= nil and world.players[id].minor == nil then
					majors[#majors + 1] = env.Players[id]
				end
			end

			return majors
		end,
		-- The living city-states and Free Cities, the players with data.minor, in ID order.
		GetAliveMinors = function()
			local minors = {}

			for id = 0, 63 do
				if env.Players[id] ~= nil and world.players[id].minor ~= nil then
					minors[#minors + 1] = env.Players[id]
				end
			end

			return minors
		end,
	}

	local text = world.text or {}

	env.Locale = {
		-- With arguments, the text is followed by them in parentheses, such as "KEY(5)", so a test
		-- can check them.
		Lookup = function(key, ...)
			local arguments = { ... }

			if #arguments == 0 then
				return text[key] or key
			end

			for i, argument in ipairs(arguments) do
				arguments[i] = tostring(argument)
			end

			return (text[key] or key) .. "(" .. table.concat(arguments, ",") .. ")"
		end,
	}
end

return FakeGame

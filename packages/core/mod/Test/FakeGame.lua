-- A fake of the game's Lua API for tests, with only the calls the core mod
-- makes. The core builds the shared GameInfo tables, cities, and units. Each
-- area is a feature in FakeGame/ that registers at the end of this file.

local FakeGame = {}

-- The features that Install runs, in registration order, and the hooks they add
-- to each Install's players and cities.
local features, playerHooks, cityHooks, unitHooks = {}, {}, {}, {}

-- Registers a feature, the part of the fake that one area of the game needs.
-- install(env, world, ctx) runs in every Install, after the shared GameInfo
-- rows and before the players are built. It adds its GameInfo rows with
-- ctx.AddRow, sets its Game.* and other globals on env, and attaches its calls
-- to players and cities with ctx.OnPlayer and ctx.OnCity. Its file has the docs
-- for the world and player data it reads. A file under FakeGame/ returns its
-- install function, and the registration lines at the end of this file list
-- them.
function FakeGame.Register(name, install)
	for _, feature in ipairs(features) do
		assert(feature.name ~= name, "feature registered twice: " .. name)
	end

	features[#features + 1] = { name = name, install = install }
end

-- A list with Members(), as the game's city and unit lists have. Members()
-- returns an iterator, as in "for i, city in player:GetCities():Members() do".
-- FindID(id) returns the item with that ID, or nil.
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

local MAP_WIDTH = 100

-- Returns the plot index of x and y, as Map.GetPlot(x, y):GetIndex() does.
local function PlotIndex(x, y)
	return y * MAP_WIDTH + x
end

-- GameInfo.Yields, by name, with each yield's index from YieldTypes.
local YIELD_ROWS = {
	YIELD_FOOD = { Index = 0 },
	YIELD_PRODUCTION = { Index = 1 },
	YIELD_GOLD = { Index = 2 },
	YIELD_SCIENCE = { Index = 3 },
	YIELD_CULTURE = { Index = 4 },
	YIELD_FAITH = { Index = 5 },
}

local YIELD_TYPES = { FOOD = 0, PRODUCTION = 1, GOLD = 2, SCIENCE = 3, CULTURE = 4, FAITH = 5 }

-- The YieldTypes names by GameInfo.Yields index.
local YIELD_NAMES = { [0] = "FOOD", "PRODUCTION", "GOLD", "SCIENCE", "CULTURE", "FAITH" }

-- The districts and buildings of a city from data, which more than one feature
-- reads: placed, each district by its GameInfo index, buildings, each building
-- by its index, and buildingsAt, the building indexes at each plot. It is built
-- once for each city.
local layouts = setmetatable({}, { __mode = "k" })

local function CityLayout(data, indexes)
	if layouts[data] == nil then
		local layout = { placed = {}, buildings = {}, buildingsAt = {} }

		for _, district in ipairs(data.districts or {}) do
			local plotIndex = PlotIndex(district.x, district.y)

			layout.buildingsAt[plotIndex] = {}

			for _, building in ipairs(district.buildings or {}) do
				local index = indexes[building.type]

				layout.buildings[index] = building
				layout.buildingsAt[plotIndex][#layout.buildingsAt[plotIndex] + 1] = index
			end

			layout.placed[indexes[district.type]] = district
		end

		layouts[data] = layout
	end

	return layouts[data]
end

-- A city from data: its identity, id, name, x, y, and population. The rest is
-- added by the features, with OnCity, each describing the data it reads:
-- FakeGame/CityDistricts.lua and CityBuildings.lua, CityGrowth.lua,
-- CityYields.lua, Production.lua for data.production and the build queue's
-- options, Purchases.lua for data.purchases, and Placement.lua for the tiles to
-- place or buy. hashes maps each production, unit, building, and district type
-- to its hash, and indexes maps each district, building, and unit type to its
-- GameInfo index. ownerID is the player's ID.
local function BuildCity(data, hashes, indexes, ownerID)
	return {
		GetOwner = function()
			return ownerID
		end,
		GetDistrictID = function()
			return data.id
		end,
		GetID = function()
			return data.id
		end,
		GetName = function()
			return data.name or "LOC_CITY_NAME_UNNAMED"
		end,
		GetX = function()
			return data.x or 0
		end,
		GetY = function()
			return data.y or 0
		end,
		GetPopulation = function()
			return data.population
		end,
	}
end

local function City(data, hashes, indexes, ownerID)
	local city = BuildCity(data, hashes, indexes, ownerID)

	for _, hook in ipairs(cityHooks) do
		hook(city, data, ownerID)
	end

	return city
end

-- A unit from data: its identity, id and type, and its place, x and y. The rest
-- is added by FakeGame/Units.lua, with OnUnit, which describes the data it
-- reads. indexes maps each unit type to its GameInfo index.
local function Unit(data, indexes)
	local unit = {
		GetID = function()
			return data.id
		end,
		GetType = function()
			return indexes[data.type]
		end,
		GetUnitType = function()
			return indexes[data.type]
		end,
		GetX = function()
			return data.x
		end,
		GetY = function()
			return data.y
		end,
	}

	for _, hook in ipairs(unitHooks) do
		hook(unit, data)
	end

	return unit
end

-- A player from data: its ID, its cities and units, and the districts it finds
-- by ID. The rest is added by the features, with OnPlayer. hashes maps each
-- production, unit, building, and district type to its hash, and indexes maps
-- each district, building, and unit type to its GameInfo index.
local function BuildPlayer(id, data, hashes, indexes)
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

local function Player(id, data, hashes, indexes)
	local player = BuildPlayer(id, data, hashes, indexes)

	for _, hook in ipairs(playerHooks) do
		hook(player, data, id)
	end

	return player
end

-- Sets Players, GameInfo, YieldTypes, and Locale in env from world.
-- world.players maps each player ID to its data. world.text maps each LOC_ key
-- to its text. Locale.Lookup returns any other key as it is. GameInfo.Types
-- holds each production type in world, under a made-up hash.
function FakeGame.Install(env, world)
	playerHooks, cityHooks, unitHooks, layouts = {}, {}, {}, setmetatable({}, { __mode = "k" })

	local hashes, indexes = {}, {}
	local count = 0
	-- Each plot in world.plots by its index, which FakeGame/Plots.lua fills.
	local plots = {}

	-- GameInfo.Yields finds a yield by its type or by its index, as the game's
	-- table does.
	local yieldInfo = {}

	for name, row in pairs(YIELD_ROWS) do
		yieldInfo[name] = { Index = row.Index, YieldType = name }
		yieldInfo[row.Index] = yieldInfo[name]
	end

	env.GameInfo = {
		Types = {},
		Districts = {},
		Projects = {},
		Yields = yieldInfo,
		Buildings = {},
		Units = {},
		GreatWorks = {},
		UnitPromotions = {},
		Terrains = {},
		Features = {},
		Resources = {},
		Improvements = {},
		Routes = {},
		Leaders = {},
		LeaderTraits = {},
		Traits = {},
	}
	-- Gives a table of rows the game's lookups: a row by its type name, as in
	-- GameInfo.Districts["DISTRICT_CAMPUS"], and a call that lists the rows in
	-- index order.
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

	-- GameInfo.Units(), GameInfo.Buildings(), GameInfo.Districts(), and
	-- GameInfo.Projects() list the rows in index order, as the game's tables do
	-- when called, and each table finds a row by its type name, as in
	-- GameInfo.Districts["DISTRICT_CAMPUS"].
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
	env.YieldTypes = YIELD_TYPES

	-- Adds a type to a GameInfo table under the next index, as the game numbers
	-- its rows.
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

	-- What a feature gets from the core: the rows and their hashes and indexes,
	-- the plots by index, and the shared helpers. NextHash(base, typeName)
	-- gives a type the hash base plus a running count, once. OnPlayer(hook) and
	-- OnCity(hook) run hook(player, data, id) and hook(city, data, ownerID) on
	-- each one built, to add its calls.
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
		Layout = function(data)
			return CityLayout(data, indexes)
		end,
		PlotIndex = PlotIndex,
		MAP_WIDTH = MAP_WIDTH,
		YIELD_TYPES = YIELD_TYPES,
		YIELD_NAMES = YIELD_NAMES,
		OnPlayer = function(hook)
			playerHooks[#playerHooks + 1] = hook
		end,
		OnUnit = function(hook)
			unitHooks[#unitHooks + 1] = hook
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
		env.Players[id] = Player(id, data, hashes, indexes)
	end
end

-- One line for each feature in FakeGame/, in the order Install runs them. Each
-- file returns its install function, as FakeGame.Register describes.
FakeGame.Register("Resources", require("FakeGame/Resources"))
FakeGame.Register("Plots", require("FakeGame/Plots"))
FakeGame.Register("Rivals", require("FakeGame/Rivals"))
FakeGame.Register("TopBar", require("FakeGame/TopBar"))
FakeGame.Register("Stores", require("FakeGame/Stores"))
FakeGame.Register("Players", require("FakeGame/Players"))
FakeGame.Register("Locale", require("FakeGame/Locale"))
FakeGame.Register("Capabilities", require("FakeGame/Capabilities"))
FakeGame.Register("CityCommands", require("FakeGame/CityCommands"))
FakeGame.Register("CityDistricts", require("FakeGame/CityDistricts"))
FakeGame.Register("CityBuildings", require("FakeGame/CityBuildings"))
FakeGame.Register("GreatWorks", require("FakeGame/GreatWorks"))
FakeGame.Register("CityGrowth", require("FakeGame/CityGrowth"))
FakeGame.Register("CityYields", require("FakeGame/CityYields"))
FakeGame.Register("CityPower", require("FakeGame/CityPower"))
FakeGame.Register("Units", require("FakeGame/Units"))
FakeGame.Register("UnitMoves", require("FakeGame/UnitMoves"))
FakeGame.Register("UnitOrders", require("FakeGame/UnitOrders"))
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
FakeGame.Register("Trade", require("FakeGame/Trade"))
FakeGame.Register("SpyMissions", require("FakeGame/SpyMissions"))
FakeGame.Register("Espionage", require("FakeGame/Espionage"))
FakeGame.Register("Research", require("FakeGame/Research"))
FakeGame.Register("Governments", require("FakeGame/Governments"))
FakeGame.Register("Production", require("FakeGame/Production"))
FakeGame.Register("Purchases", require("FakeGame/Purchases"))
FakeGame.Register("Placement", require("FakeGame/Placement"))
FakeGame.Register("Income", require("FakeGame/Income"))
FakeGame.Register("Maintenance", require("FakeGame/Maintenance"))
FakeGame.Register("Diplomacy", require("FakeGame/Diplomacy"))
FakeGame.Register("Proposals", require("FakeGame/Proposals"))
FakeGame.Register("Scoreboard", require("FakeGame/Scoreboard"))
FakeGame.Register("Victories", require("FakeGame/Victories"))
FakeGame.Register("Attacks", require("FakeGame/Attacks"))
FakeGame.Register("TileOrders", require("FakeGame/TileOrders"))

return FakeGame

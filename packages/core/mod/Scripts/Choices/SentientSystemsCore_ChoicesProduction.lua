-- The production choice: what each of the player's cities can produce, as the production panel
-- lists it. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetProductionChoices(player) returns a list with one table for each city, which
-- encodes as '{"buildings":[{"cost":32,"district":"DISTRICT_CITY_CENTER","turns":5,
-- "type":"BUILDING_GRANARY"}],"city":65536,"name":"Rome","units":[{"cost":40,"turns":6,
-- "type":"UNIT_SETTLER"}],...}', on one line, with districts and wonders too. The checks follow
-- GetData in ProductionPanel.lua.

-- Returns the game's reasons from a CanProduce result, as text. The game gives each reason as text
-- already, and the panel passes it through Locale.Lookup, as this does.
local function FailureReasons(results)
	local reasons = {}

	for i, reason in ipairs(results and results[CityCommandResults.FAILURE_REASONS] or {}) do
		reasons[i] = Locale.Lookup(reason)
	end

	return reasons
end

-- Sets option.blocked to the game's reasons when the city can't produce what params names now, as
-- the panel greys it out. params is a building's hash, or a table that names a unit and its
-- formation. Returns the CanProduce results.
local function CheckBlocked(buildQueue, params, option)
	local canProduce, results = buildQueue:CanProduce(params, false, true)

	if not canProduce then
		option.blocked = FailureReasons(results)
	end

	return results
end

-- Returns the option to train a unit as a corps or an army, with its cost.
local function FormationOption(buildQueue, row, formation, cost)
	local option = { cost = cost, turns = buildQueue:GetTurnsLeft(row.Hash, formation) }

	CheckBlocked(buildQueue, { UnitType = row.Hash, MilitaryFormationType = formation }, option)

	return option
end

-- Returns the units the city's production panel lists. The panel lists each unit whose MustPurchase
-- is false and that CanProduce allows when it only tests. It greys out a listed unit that CanProduce
-- refuses with results, and offers a corps or an army when the results allow one. See GetData in
-- ProductionPanel.lua, lines 2113 to 2202.
local function GetUnitOptions(city)
	local buildQueue = city:GetBuildQueue()
	local units = {}

	for row in GameInfo.Units() do
		local params = { UnitType = row.Hash, MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION }

		if not row.MustPurchase and buildQueue:CanProduce(params, true) then
			local option = { type = row.UnitType, cost = buildQueue:GetUnitCost(row.Index), turns = buildQueue:GetTurnsLeft(row.Hash) }
			local progress = buildQueue:GetUnitProgress(row.Index)
			local results = CheckBlocked(buildQueue, params, option)

			-- The panel shows progress only once there is some.
			if progress > 0 then
				option.progress = progress
			end

			if results ~= nil and results[CityOperationResults.CAN_TRAIN_CORPS] then
				option.corps = FormationOption(buildQueue, row, MilitaryFormationTypes.CORPS_MILITARY_FORMATION, buildQueue:GetUnitCorpsCost(row.Index))
			end

			if results ~= nil and results[CityOperationResults.CAN_TRAIN_ARMY] then
				option.army = FormationOption(buildQueue, row, MilitaryFormationTypes.ARMY_MILITARY_FORMATION, buildQueue:GetUnitArmyCost(row.Index))
			end

			units[#units + 1] = option
		end
	end

	return units
end

-- Returns the hash and the type of what the city is producing. The hash is 0, and the type nil, when
-- it produces nothing. GameInfo.Types reads 0 as its first row, so 0 is checked first. A hash that
-- GameInfo.Types doesn't know has no type.
local function CurrentProduction(buildQueue)
	local hash = buildQueue:GetCurrentProductionTypeHash()
	local row = hash ~= 0 and GameInfo.Types[hash] or nil

	return hash, row and row.Type
end

-- Each yield, by its key in an adjacency bonus, and its name in YieldTypes. The keys are the same as
-- those of a city's yields in the state.
local YIELDS = {
	culture = "CULTURE",
	faith = "FAITH",
	food = "FOOD",
	gold = "GOLD",
	production = "PRODUCTION",
	science = "SCIENCE",
}

-- The failure reason that the panel ignores for a district when it has a tile to place it on, and
-- the key of the one that greys out a district to repair whose tile is flooded. The panel compares
-- the reasons with the first key itself and with the second one's text, in GetData in
-- ProductionPanel.lua, lines 1950 and 1934.
local NO_SUITABLE_LOCATION_KEY = "LOC_DISTRICT_ZONE_NO_SUITABLE_LOCATION"
local FLOODED_KEY = "LOC_DISTRICT_REPAIR_LOCATION_FLOODED"

-- Returns the tile at a plot index, with x and y. With a district's index, it adds the district's
-- adjacency bonus on the tile, by yield, when there is one, as the placement view shows it.
local function Tile(city, plotIndex, districtIndex)
	local plot = Map.GetPlotByIndex(plotIndex)
	local tile = { x = plot:GetX(), y = plot:GetY() }

	if districtIndex ~= nil then
		local adjacency = {}

		for key, name in pairs(YIELDS) do
			local bonus = plot:GetAdjacencyYield(city:GetOwner(), city:GetID(), districtIndex, YieldTypes[name])

			if bonus > 0 then
				adjacency[key] = bonus
			end
		end

		if next(adjacency) ~= nil then
			tile.adjacency = adjacency
		end
	end

	return tile
end

-- Returns the plot indexes of the tiles the city could buy, in index order. The panel asks for them
-- with the interface mode's plot purchase parameter, in AdjacencyBonusSupport.lua, lines 309 to 311.
local function PurchasablePlots(city)
	local params = {}
	local plots = {}

	params[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE)

	for _, plotIndex in pairs(CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, params)[CityCommandResults.PLOTS] or {}) do
		plots[#plots + 1] = plotIndex
	end

	table.sort(plots)

	return plots
end

-- Returns the tiles the city owns where a district or a wonder can go now, and the tiles it could
-- buy where it could go. param is the operation parameter that names it, and canHave(plot) checks a
-- tile the city could buy. districtIndex is nil for a wonder. See
-- GetCityRelatedPlotIndexesDistrictsAlternative and GetCityRelatedPlotIndexesWondersAlternative in
-- AdjacencyBonusSupport.lua. The panel shows a district's tile to buy only when it gives an
-- adjacency bonus, and this lists every one.
local function PlacementTiles(city, purchasable, param, hash, canHave, districtIndex)
	local params = {}
	local tiles, purchaseTiles = {}, {}

	params[param] = hash

	for _, plotIndex in ipairs(CityManager.GetOperationTargets(city, CityOperationTypes.BUILD, params)[CityOperationResults.PLOTS] or {}) do
		tiles[#tiles + 1] = Tile(city, plotIndex, districtIndex)
	end

	for _, plotIndex in ipairs(purchasable) do
		if canHave(Map.GetPlotByIndex(plotIndex)) then
			purchaseTiles[#purchaseTiles + 1] = Tile(city, plotIndex, districtIndex)
		end
	end

	return tiles, purchaseTiles
end

-- Returns whether a list of failure reasons holds the reason.
local function HasReason(reasons, reason)
	for _, candidate in ipairs(reasons or {}) do
		if candidate == reason then
			return true
		end
	end

	return false
end

-- Returns whether every failure reason is the reason.
local function OnlyReason(reasons, reason)
	for _, candidate in ipairs(reasons) do
		if candidate ~= reason then
			return false
		end
	end

	return true
end

-- Returns whether the city has placed the district, built or not.
local function HasPlaced(city, districtIndex)
	for _, district in city:GetDistricts():Members() do
		if district:GetType() == districtIndex then
			return true
		end
	end

	return false
end

-- Returns whether the panel shows the district as built, with a checkmark in place of turns: one
-- per city, complete, not pillaged or contaminated, and with no progress. See
-- PopulateDistrictsWithNestedBuildings in ProductionPanel.lua, line 953.
local function IsBuilt(row, cityDistricts, progress)
	return row.OnePerCity and cityDistricts:HasDistrict(row.Index) and cityDistricts:IsComplete(row.Index)
		and not cityDistricts:IsPillaged(row.Index) and not cityDistricts:IsContaminated(row.Index) and progress == 0
end

-- Returns the districts the city's production panel lists, with the tiles for each, built ones left
-- out. The panel lists a district that CanProduce allows when it only tests, or that the city has.
-- It leaves out one marked InternalOnly, and a one-per-city district in production. It greys out a
-- district that CanProduce refuses, with two changes from the tiles. A district with no tile is
-- greyed out unless it is placed already and its tile isn't flooded. One with a tile isn't greyed
-- out when its only reason is NO_SUITABLE_LOCATION_KEY. See GetData in ProductionPanel.lua, lines
-- 1898 to 2018.
local function GetDistrictOptions(city, purchasable)
	local buildQueue = city:GetBuildQueue()
	local cityDistricts = city:GetDistricts()
	local currentHash = buildQueue:GetCurrentProductionTypeHash()
	local districts = {}

	for row in GameInfo.Districts() do
		local inPanel = (row.Hash ~= currentHash or not row.OnePerCity) and not row.InternalOnly
		local progress = buildQueue:GetDistrictProgress(row.Index)

		if inPanel and (buildQueue:CanProduce(row.Hash, true) or cityDistricts:HasDistrict(row.Index)) and not IsBuilt(row, cityDistricts, progress) then
			local canProduce, results = buildQueue:CanProduce(row.Hash, false, true)
			local reasons = results and results[CityCommandResults.FAILURE_REASONS]
			local option = { type = row.DistrictType, cost = buildQueue:GetDistrictCost(row.Index), turns = buildQueue:GetTurnsLeft(row.DistrictType) }
			local blocked = not canProduce

			option.tiles, option.purchaseTiles = PlacementTiles(city, purchasable, CityOperationTypes.PARAM_DISTRICT_TYPE, row.Hash, function(plot)
				return plot:CanHaveDistrict(row.Index, city:GetOwner(), city:GetID())
			end, row.Index)

			if #option.tiles + #option.purchaseTiles == 0 then
				blocked = blocked or not HasPlaced(city, row.Index) or HasReason(reasons, Locale.Lookup(FLOODED_KEY))
			elseif blocked and reasons ~= nil and #reasons > 0 then
				blocked = not OnlyReason(reasons, NO_SUITABLE_LOCATION_KEY)
			end

			if progress > 0 then
				option.progress = progress
			end

			if cityDistricts:IsPillaged(row.Index) then
				option.repair = true
			end

			if blocked then
				option.blocked = FailureReasons(results)
			end

			districts[#districts + 1] = option
		end
	end

	return districts
end

-- Returns the building or wonder option for a row, with its cost, turns, progress, and repair.
local function BuildingOption(buildQueue, row, pillaged)
	local option = { type = row.BuildingType, cost = buildQueue:GetBuildingCost(row.Index), turns = buildQueue:GetTurnsLeft(row.Hash) }
	local progress = buildQueue:GetBuildingProgress(row.Index)

	if progress > 0 then
		option.progress = progress
	end

	if pillaged then
		option.repair = true
	end

	return option
end

-- Returns the buildings and the wonders the city's production panel lists, with the tiles for each
-- wonder. The panel leaves out the building in production, and one whose district is in production,
-- as when the district is being repaired. It lists a building that must be bought only when it is
-- pillaged, to repair it. It greys out a listed building that CanProduce refuses with results, but
-- not a wonder whose result is NO_SUITABLE_LOCATION and that has a tile. See GetData in
-- ProductionPanel.lua, lines 2020 to 2081.
local function GetBuildingAndWonderOptions(city, purchasable)
	local buildQueue = city:GetBuildQueue()
	local cityBuildings = city:GetBuildings()
	local currentHash, currentType = CurrentProduction(buildQueue)
	local buildings, wonders = {}, {}

	for row in GameInfo.Buildings() do
		local pillaged = cityBuildings:IsPillaged(row.Hash)
		local districtInProduction = row.PrereqDistrict ~= nil and row.PrereqDistrict == currentType

		if row.Hash ~= currentHash and (not row.MustPurchase or pillaged) and not districtInProduction and buildQueue:CanProduce(row.Hash, true) then
			local option = BuildingOption(buildQueue, row, pillaged)

			if row.IsWonder then
				local canProduce, results = buildQueue:CanProduce(row.Hash, false, true)

				option.tiles, option.purchaseTiles = PlacementTiles(city, purchasable, CityOperationTypes.PARAM_BUILDING_TYPE, row.Hash, function(plot)
					return plot:CanHaveWonder(row.Index, city:GetOwner(), city:GetID())
				end)

				local noLocation = results ~= nil and results[CityOperationResults.NO_SUITABLE_LOCATION] == true

				if not canProduce and not (noLocation and #option.tiles + #option.purchaseTiles > 0) then
					option.blocked = FailureReasons(results)
				end

				wonders[#wonders + 1] = option
			else
				option.district = row.PrereqDistrict
				CheckBlocked(buildQueue, row.Hash, option)
				buildings[#buildings + 1] = option
			end
		end
	end

	return buildings, wonders
end

-- Returns a list with what each of the player's cities can produce, in the game's order of cities.
function SentientSystems_GetProductionChoices(player)
	local production = {}

	for _, city in player:GetCities():Members() do
		local purchasable = PurchasablePlots(city)
		local buildings, wonders = GetBuildingAndWonderOptions(city, purchasable)

		production[#production + 1] = {
			city = city:GetID(),
			name = Locale.Lookup(city:GetName()),
			units = GetUnitOptions(city),
			buildings = buildings,
			districts = GetDistrictOptions(city, purchasable),
			wonders = wonders,
		}
	end

	return production
end

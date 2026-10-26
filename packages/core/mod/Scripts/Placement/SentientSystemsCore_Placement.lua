-- The placement tiles: where a city can place a district or a wonder, on tiles it owns or could buy,
-- with each district's adjacency bonus on each tile, as the placement view shows them when the
-- player picks one. The bridge reads them for one district or wonder at a time, in a call of their
-- own, and the production choice counts them. The UI script and the production choice load this
-- file. Example: SentientSystems_GetPlacement(0, 65536, "DISTRICT_CAMPUS") returns
-- '{"purchaseTiles":[{"adjacency":{"science":3},"x":19,"y":14}],"tiles":[{"adjacency":{"science":1},
-- "x":17,"y":13},{"x":16,"y":14}]}', on one line. The calls follow AdjacencyBonusSupport.lua.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")

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

-- Returns the plot indexes of the tiles the city could buy, in index order. The panel asks for them
-- with the interface mode's plot purchase parameter, in AdjacencyBonusSupport.lua, lines 309 to 311.
-- Ask once for each city, and pass the list to SentientSystems_GetDistrictTiles and
-- SentientSystems_GetWonderTiles.
function SentientSystems_GetPurchasablePlots(city)
	local params = {}
	local plots = {}

	params[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE)

	for _, plotIndex in pairs(CityManager.GetCommandTargets(city, CityCommandTypes.PURCHASE, params)[CityCommandResults.PLOTS] or {}) do
		plots[#plots + 1] = plotIndex
	end

	table.sort(plots)

	return plots
end

-- Returns the tiles the city owns where the district in row, a row of GameInfo.Districts, can go
-- now, and the tiles from purchasable where it could go, each with its adjacency bonus.
function SentientSystems_GetDistrictTiles(city, purchasable, row)
	return PlacementTiles(city, purchasable, CityOperationTypes.PARAM_DISTRICT_TYPE, row.Hash, function(plot)
		return plot:CanHaveDistrict(row.Index, city:GetOwner(), city:GetID())
	end, row.Index)
end

-- Returns the tiles the city owns where the wonder in row, a row of GameInfo.Buildings, can go now,
-- and the tiles from purchasable where it could go.
function SentientSystems_GetWonderTiles(city, purchasable, row)
	return PlacementTiles(city, purchasable, CityOperationTypes.PARAM_BUILDING_TYPE, row.Hash, function(plot)
		return plot:CanHaveWonder(row.Index, city:GetOwner(), city:GetID())
	end)
end

-- Returns the tiles where the city with ID cityID, of the player with ID playerID, can place the
-- district or the wonder typeName, such as DISTRICT_CAMPUS, as JSON. Raises an error for an ID with
-- no player or city, and for a type that isn't a district or a wonder. The bridge reads it through
-- the stash, as SentientSystems_Stash(SentientSystems_GetPlacement(playerID, cityID, typeName)).
function SentientSystems_GetPlacement(playerID, cityID, typeName)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	local city = player:GetCities():FindID(cityID)

	if city == nil then
		error("no city " .. tostring(cityID) .. " for player " .. tostring(playerID), 0)
	end

	local district = GameInfo.Districts[typeName]
	local building = GameInfo.Buildings[typeName]
	local tiles, purchaseTiles

	if district ~= nil then
		tiles, purchaseTiles = SentientSystems_GetDistrictTiles(city, SentientSystems_GetPurchasablePlots(city), district)
	elseif building ~= nil and building.IsWonder then
		tiles, purchaseTiles = SentientSystems_GetWonderTiles(city, SentientSystems_GetPurchasablePlots(city), building)
	else
		error(tostring(typeName) .. " isn't a district or a wonder", 0)
	end

	return SentientSystems_EncodeJson({ tiles = tiles, purchaseTiles = purchaseTiles })
end

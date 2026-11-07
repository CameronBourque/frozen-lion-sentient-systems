-- The tiles section: each revealed tile, from the player's own visibility
-- data. See docs/findings/state/tile-visibility.md.
-- Shape: bridge/src/state/tiles.ts.

-- Returns the type of the plot's resource, or nil when the plot has none or the
-- player can't see it yet. Some resources stay hidden until the player has a
-- tech. The game's tooltip checks IsResourceVisible the same way, in
-- PlotToolTip.lua.
local function GetResource(plot, resources)
	local resource = GameInfo.Resources[plot:GetResourceType()]

	if resource == nil or not resources:IsResourceVisible(plot:GetResourceTypeHash()) then
		return nil
	end

	return resource.ResourceType
end

-- Returns the column of the row at index in a GameInfo table, or nil for an
-- index of -1, which the game uses for none.
local function TypeAt(rows, index, column)
	local row = rows[index]

	return row and row[column]
end

-- Returns true when value is true, or nil, so a flag that is usually false is
-- left out of the JSON.
local function TrueOrNil(value)
	return value or nil
end

-- Returns the appeal of the plot, or nil when it is 0 or the tooltip shows
-- none: the tooltip leaves it out for water, except a natural wonder, in
-- PlotToolTip.lua. The appeal lens colors tiles by the same number.
local function GetAppeal(plot)
	local feature = GameInfo.Features[plot:GetFeatureType()]

	if plot:IsWater() and not (feature and feature.NaturalWonder) then
		return nil
	end

	local appeal = plot:GetAppeal()

	return appeal ~= 0 and appeal or nil
end

-- Returns the index of the plot's continent, or nil for a tile with none, such
-- as water. The tooltip leaves the line out for it too, in PlotToolTip.lua.
local function GetContinent(plot)
	local continent = plot:GetContinentType()

	return continent ~= -1 and continent or nil
end

-- Returns the tourism of a tile of the player's own, as its banner shows it on
-- the tourism lens, or an empty table when it has none. The banner's tooltip is
-- a name, the visiting tourists, a line of text, the sources, and the lifetime
-- tourism, which only the text holds. A tooltip with fewer lines is kept whole
-- as the sources.
local function GetTourism(culture, index)
	local tourism = culture:GetTourismAt(index)

	if tourism <= 0 then
		return {}
	end

	local lines = SentientSystems_GetTooltipLines(culture:GetTourismTooltipAt(index))
	local result = { tourism = tourism, tourists = culture:GetTouristsAt(index), sources = lines }

	if #lines >= 5 then
		result.sources = {}

		for i = 4, #lines - 1 do
			result.sources[#result.sources + 1] = lines[i]
		end

		local lifetime = (lines[#lines]:match("([%d,]+)%D*$") or ""):gsub(",", "")

		result.lifetime = tonumber(lifetime)
	end

	return result
end

-- Returns a list of the tiles that the player with ID playerID has revealed, in
-- plot index order. The tooltip shows the same values, in PlotToolTip.lua.
function SentientSystems_GetTileStates(playerID)
	local visibility = PlayersVisibility[playerID]
	local resources = Players[playerID]:GetResources()
	local culture = Players[playerID]:GetCulture()
	local tiles = {}

	for index = 0, Map.GetPlotCount() - 1 do
		if visibility:IsRevealed(index) then
			local plot = Map.GetPlotByIndex(index)
			local improvement = TypeAt(GameInfo.Improvements, plot:GetImprovementType(), "ImprovementType")
			local route = TypeAt(GameInfo.Routes, plot:GetRouteType(), "RouteType")
			local owner = plot:GetOwner()
			local tourism = owner == playerID and GetTourism(culture, index) or {}

			tiles[#tiles + 1] = {
				x = plot:GetX(),
				y = plot:GetY(),
				terrain = GameInfo.Terrains[plot:GetTerrainType()].TerrainType,
				feature = TypeAt(GameInfo.Features, plot:GetFeatureType(), "FeatureType"),
				resource = GetResource(plot, resources),
				owner = owner ~= -1 and owner or nil,
				district = TypeAt(GameInfo.Districts, plot:GetDistrictType(), "DistrictType"),
				improvement = improvement,
				improvementPillaged = improvement and TrueOrNil(plot:IsImprovementPillaged()),
				route = route,
				routePillaged = route and TrueOrNil(plot:IsRoutePillaged()),
				appeal = GetAppeal(plot),
				continent = GetContinent(plot),
				visible = visibility:IsVisible(index),
				tourism = tourism.tourism,
				tourists = tourism.tourists ~= 0 and tourism.tourists or nil,
				lifetime = tourism.lifetime,
				sources = tourism.sources,
			}
		end
	end

	return tiles
end

-- The tiles section of the state: each tile the player has revealed, from the player's own
-- visibility data, never from the screen. A tile under fog reads as it is now, as the game's tooltip
-- shows it. See docs/findings/tile-visibility.md. SentientSystemsCore_State.lua loads this file.
-- Example: SentientSystems_GetTileStates(playerID) returns a list with one table for each tile,
-- which encodes as
-- '{"feature":"FEATURE_FOREST","improvement":"IMPROVEMENT_CAMP","owner":0,"resource":"RESOURCE_DEER",
-- "route":"ROUTE_ANCIENT_ROAD","terrain":"TERRAIN_GRASS_HILLS","visible":true,"x":17,"y":15}', on one line.

-- Returns the type of the plot's resource, such as RESOURCE_IRON, or nil when the plot has none or
-- the player can't see it yet. Some resources, such as iron, stay hidden until the player has a
-- tech. The game's tooltip checks IsResourceVisible the same way, in PlotToolTip.lua.
local function GetResource(plot, resources)
	local resource = GameInfo.Resources[plot:GetResourceType()]

	if resource == nil or not resources:IsResourceVisible(plot:GetResourceTypeHash()) then
		return nil
	end

	return resource.ResourceType
end

-- Returns the column of the row at index in a GameInfo table, or nil for an index of -1, which the
-- game uses for none.
local function TypeAt(rows, index, column)
	local row = rows[index]

	return row and row[column]
end

-- Returns true when value is true, or nil, so a flag that is usually false is left out of the JSON.
local function TrueOrNil(value)
	return value or nil
end

-- Returns a list of the tiles that the player with ID playerID has revealed, in plot index order.
-- Each field but x, y, terrain, and visible is left out for a tile with none. owner is a player ID.
-- improvementPillaged and routePillaged are there only when true. The tooltip shows the same values,
-- in PlotToolTip.lua.
function SentientSystems_GetTileStates(playerID)
	local visibility = PlayersVisibility[playerID]
	local resources = Players[playerID]:GetResources()
	local tiles = {}

	for index = 0, Map.GetPlotCount() - 1 do
		if visibility:IsRevealed(index) then
			local plot = Map.GetPlotByIndex(index)
			local improvement = TypeAt(GameInfo.Improvements, plot:GetImprovementType(), "ImprovementType")
			local route = TypeAt(GameInfo.Routes, plot:GetRouteType(), "RouteType")
			local owner = plot:GetOwner()

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
				visible = visibility:IsVisible(index),
			}
		end
	end

	return tiles
end

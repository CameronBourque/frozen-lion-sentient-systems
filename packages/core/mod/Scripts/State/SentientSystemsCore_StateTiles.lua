-- The tiles section of the state: each tile the player has revealed, from the player's own
-- visibility data, never from the screen. A tile under fog reads as it is now, as the game's tooltip
-- shows it. See docs/findings/game-state.md. SentientSystemsCore_State.lua loads this file.
-- Example: SentientSystems_GetTileStates(playerID) returns a list with one table for each tile,
-- which encodes as
-- '{"feature":"FEATURE_FOREST","resource":"RESOURCE_DEER","terrain":"TERRAIN_GRASS_HILLS","visible":true,"x":17,"y":15}'.

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

-- Returns a list of the tiles that the player with ID playerID has revealed, in plot index order.
-- feature and resource are left out for a tile with none.
function SentientSystems_GetTileStates(playerID)
	local visibility = PlayersVisibility[playerID]
	local resources = Players[playerID]:GetResources()
	local tiles = {}

	for index = 0, Map.GetPlotCount() - 1 do
		if visibility:IsRevealed(index) then
			local plot = Map.GetPlotByIndex(index)
			local feature = GameInfo.Features[plot:GetFeatureType()]

			tiles[#tiles + 1] = {
				x = plot:GetX(),
				y = plot:GetY(),
				terrain = GameInfo.Terrains[plot:GetTerrainType()].TerrainType,
				feature = feature and feature.FeatureType,
				resource = GetResource(plot, resources),
				visible = visibility:IsVisible(index),
			}
		end
	end

	return tiles
end

-- The WMD launchers section: the units and missile silos that can launch each
-- device the player has now. Shape: bridge/src/state/wmd-launchers.ts.

SentientSystems_Include("SentientSystemsCore_Wmds")

-- Returns the IDs of the units that can launch the device now.
local function GetReadyUnits(player, wmd)
	local ready = {}

	for _, unit in player:GetUnits():Members() do
		if SentientSystems_IsUnitOnMap(unit) and SentientSystems_CanUnitLaunch(unit, wmd) then
			ready[#ready + 1] = unit:GetID()
		end
	end

	return ready
end

-- Returns the player's missile silos, each with its plot and city.
local function GetSilos(player)
	local silos = {}

	for _, city in player:GetCities():Members() do
		for _, plotID in ipairs(Map.GetCityPlots():GetPurchasedPlots(city)) do
			local plot = Map.GetPlotByIndex(plotID)

			if SentientSystems_IsSilo(plot) then
				silos[#silos + 1] = { plot = plot, city = city }
			end
		end
	end

	return silos
end

-- Returns the silos that can launch the device now, by position.
local function GetReadySilos(silos, wmd)
	local ready = {}

	for _, silo in ipairs(silos) do
		if SentientSystems_GetSiloTargets(silo.city, silo.plot, wmd) ~= nil then
			ready[#ready + 1] = SentientSystems_GetPosition(silo.plot)
		end
	end

	return ready
end

-- Returns the launchers of each device the player has, by device type, or nil
-- when none can launch. An empty list is left out.
function SentientSystems_GetWmdLauncherState(player)
	local stockpile = SentientSystems_GetWmdStockpile(player)

	if stockpile == nil then
		return nil
	end

	local silos = GetSilos(player)
	local state = nil

	for wmd in GameInfo.WMDs() do
		local units, siloTiles = {}, {}

		if stockpile[wmd.WeaponType] ~= nil then
			units, siloTiles = GetReadyUnits(player, wmd), GetReadySilos(silos, wmd)
		end

		if #units > 0 or #siloTiles > 0 then
			state = state or {}
			state[wmd.WeaponType] = { units = #units > 0 and units or nil, silos = #siloTiles > 0 and siloTiles or nil }
		end
	end

	return state
end

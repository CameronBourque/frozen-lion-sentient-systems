-- The WMD launchers section: the units and missile silos that can launch each
-- device the player has now. Shape: bridge/src/state/wmd-launchers.ts.

-- Returns how many of each device the player has, by type, leaving out a
-- device at 0, or nil when the player has none, as the top bar hides a count
-- at 0. See OnWMDUpdate in TopPanel.lua. The player section uses it too.
function SentientSystems_GetWmdStockpile(player)
	local wmds = player:GetWMDs()
	local stockpile = nil

	for row in GameInfo.WMDs() do
		local count = wmds:GetWeaponCount(row.Index)

		if count > 0 then
			stockpile = stockpile or {}
			stockpile[row.WeaponType] = count
		end
	end

	return stockpile
end

-- Returns the IDs of the units that can launch the device now. The unit panel
-- asks CanStartOperation for each device. See UnitPanel.lua.
local function GetReadyUnits(player, wmd)
	local parameters = { [UnitOperationTypes.PARAM_WMD_TYPE] = wmd.Index }
	local ready = {}

	for _, unit in player:GetUnits():Members() do
		if SentientSystems_IsUnitOnMap(unit) and UnitManager.CanStartOperation(unit, UnitOperationTypes.WMD_STRIKE, nil, parameters) then
			ready[#ready + 1] = unit:GetID()
		end
	end

	return ready
end

-- Returns whether the silo on the plot can launch the device now. A silo fires
-- through its city, and its banner counts it ready when the city has targets
-- for it. See UpdateWMDBanner in CityBannerManager.lua.
local function IsSiloReady(city, plot, wmd)
	local parameters = {
		[CityCommandTypes.PARAM_WMD_TYPE] = wmd.Index,
		[CityCommandTypes.PARAM_X0] = plot:GetX(),
		[CityCommandTypes.PARAM_Y0] = plot:GetY(),
	}
	local results = CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, parameters)

	return results ~= nil and results[CityCommandResults.PLOTS] ~= nil
end

-- Returns the player's missile silos, each with its plot and city. A silo is
-- an improvement with weapon slots, as the banner finds it.
local function GetSilos(player)
	local silos = {}

	for _, city in player:GetCities():Members() do
		for _, plotID in ipairs(Map.GetCityPlots():GetPurchasedPlots(city)) do
			local plot = Map.GetPlotByIndex(plotID)
			local improvement = GameInfo.Improvements[plot:GetImprovementType()]

			if improvement ~= nil and improvement.WeaponSlots > 0 then
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
		if IsSiloReady(silo.city, silo.plot, wmd) then
			ready[#ready + 1] = { x = silo.plot:GetX(), y = silo.plot:GetY() }
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

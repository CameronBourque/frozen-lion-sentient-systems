-- The WMD rules that the launchers state and the strike actions share: the
-- stockpile, whether a unit can launch, and a missile silo's strike.

-- Returns how many of each device the player has, by type, leaving out a
-- device at 0, or nil when the player has none, as the top bar hides a count
-- at 0. See OnWMDUpdate in TopPanel.lua.
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

-- Returns whether the unit can launch the device now, and the game's results.
-- The unit panel shows no operations for a unit with no moves left, though
-- CanStartOperation still allows the strike. See GetUnitActionsTable in
-- UnitPanel.lua.
function SentientSystems_CanUnitLaunch(unit, wmd)
	if unit:GetMovesRemaining() <= 0 then
		return false, nil
	end

	local parameters = { [UnitOperationTypes.PARAM_WMD_TYPE] = wmd.Index }

	return UnitManager.CanStartOperation(unit, UnitOperationTypes.WMD_STRIKE, nil, parameters, true)
end

-- Returns whether the plot holds a missile silo: an improvement with weapon
-- slots, as CityBannerManager.lua finds one.
function SentientSystems_IsSilo(plot)
	local improvement = GameInfo.Improvements[plot:GetImprovementType()]

	return improvement ~= nil and improvement.WeaponSlots > 0
end

-- Returns the parameters of a strike of the device from the silo on the plot.
-- A silo fires through its city. See ICBMStrike in WorldInput.lua.
function SentientSystems_GetSiloStrikeParams(plot, wmd)
	return {
		[CityCommandTypes.PARAM_WMD_TYPE] = wmd.Index,
		[CityCommandTypes.PARAM_X0] = plot:GetX(),
		[CityCommandTypes.PARAM_Y0] = plot:GetY(),
	}
end

-- Returns the plot indexes the silo on the plot can hit with the device, or nil
-- when it can't launch it. Its banner counts it ready when there are any. See
-- UpdateWMDBanner in CityBannerManager.lua.
function SentientSystems_GetSiloTargets(city, plot, wmd)
	local results = CityManager.GetCommandTargets(city, CityCommandTypes.WMD_STRIKE, SentientSystems_GetSiloStrikeParams(plot, wmd))

	return results and results[CityCommandResults.PLOTS]
end

-- The WMD strikes, from a unit and from a missile silo. The actions file loads
-- this file. The calls are in docs/findings/actions/wmd-strikes.md.

SentientSystems_Include("SentientSystemsCore_Wmds")

-- Returns the device types, for a reason.
local function ListDevices()
	local types = {}

	for row in GameInfo.WMDs() do
		types[#types + 1] = row.WeaponType
	end

	return table.concat(types, ", ")
end

-- Returns the device's row, or nil and why the player can't launch one.
local function FindDevice(playerID, weaponType)
	if weaponType == nil then
		return nil, "A strike needs the device to launch, one of " .. ListDevices() .. "."
	end

	local wmd = GameInfo.WMDs[weaponType]

	if wmd == nil then
		return nil, tostring(weaponType) .. " isn't a device. The devices are " .. ListDevices() .. "."
	end

	if Players[playerID]:GetWMDs():GetWeaponCount(wmd.Index) <= 0 then
		return nil, "You have no " .. Locale.Lookup(wmd.Name) .. " left."
	end

	return wmd, nil
end

-- Returns nil when x, y is one of the plots the launcher at the origin can hit,
-- and why it isn't otherwise, with how many tiles it can hit and how far. The
-- UI marks every plot of the targets as one. See
-- OnInterfaceModeChange_WMD_Strike in WorldInput.lua.
local function GetRangeFailure(plots, origin, x, y)
	local target, farthest = Map.GetPlot(x, y):GetIndex(), 0

	for _, index in ipairs(plots) do
		if index == target then
			return nil
		end

		local plot = Map.GetPlotByIndex(index)

		farthest = math.max(farthest, Map.GetPlotDistance(origin.x, origin.y, plot:GetX(), plot:GetY()))
	end

	if #plots == 0 then
		return "Nothing is in range."
	end

	return "That tile isn't a target. It can hit " .. #plots .. " tiles, up to " .. farthest .. " tiles away."
end

-- Returns why a strike on x, y would start a war, or nil. The game checks the
-- whole blast, so the tile needn't be visible. WorldInput.lua opens a
-- confirmation dialog here, which has no call to answer.
local function GetStrikeWarFailure(component, x, y, wmd)
	local wars = CombatManager.IsAttackChangeWarState(component, x, y, wmd.Index)

	if wars ~= nil and #wars > 0 then
		return "Striking there would start a war with player " .. table.concat(wars, ", player ") .. "."
	end

	return nil
end

-- Returns why the unit can't launch the device at all, or nil.
local function GetLaunchFailure(unit, wmd)
	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	local canLaunch, results = SentientSystems_CanUnitLaunch(unit, wmd)

	if canLaunch then
		return nil
	end

	local reasons = SentientSystems_GetFailureReasons(results, UnitOperationResults.FAILURE_REASONS, " ")

	return "This unit can't launch " .. Locale.Lookup(wmd.Name) .. "." .. (reasons and " " .. reasons or "")
end

local function UnitStrike(playerID, unit, x, y, weaponType)
	local wmd, failure = FindDevice(playerID, weaponType)

	failure = failure or SentientSystems_GetOffMapFailure(x, y) or GetLaunchFailure(unit, wmd)

	if failure ~= nil then
		return failure
	end

	local params = { [UnitOperationTypes.PARAM_WMD_TYPE] = wmd.Index }
	local results = UnitManager.GetOperationTargets(unit, UnitOperationTypes.WMD_STRIKE, params)
	local origin = { x = unit:GetX(), y = unit:GetY() }

	failure = GetRangeFailure(results and results[UnitOperationResults.PLOTS] or {}, origin, x, y)
		or GetStrikeWarFailure(unit:GetComponentID(), x, y, wmd)

	if failure ~= nil then
		return failure
	end

	params[UnitOperationTypes.PARAM_X] = x
	params[UnitOperationTypes.PARAM_Y] = y

	return SentientSystems_RequestUnitOperation(unit, UnitOperationTypes.WMD_STRIKE, params, "The game won't start that strike.")
end

-- A unit launches the device in type at x, y. Its range and the war check come
-- from the game. See WMDStrike in WorldInput.lua.
SentientSystems_AddUnitAction("wmd_strike", UnitStrike)

-- Returns the player's silo at x, y and its city, or nil and the reason.
local function FindSilo(playerID, x, y)
	local failure = SentientSystems_GetOffMapFailure(x, y)

	if failure ~= nil then
		return nil, nil, failure
	end

	local plot = Map.GetPlot(x, y)
	local city = Cities.GetPlotPurchaseCity(x, y)

	if not SentientSystems_IsSilo(plot) or city == nil or city:GetOwner() ~= playerID then
		return nil, nil, "You have no missile silo at (" .. x .. ", " .. y .. ")."
	end

	return plot, city, nil
end

local function SiloStrike(playerID, siloX, siloY, x, y, weaponType)
	local silo, city, failure = FindSilo(playerID, siloX, siloY)

	if failure ~= nil then
		return failure
	end

	local wmd, deviceFailure = FindDevice(playerID, weaponType)

	failure = deviceFailure or SentientSystems_GetOffMapFailure(x, y)

	if failure ~= nil then
		return failure
	end

	local plots = SentientSystems_GetSiloTargets(city, silo, wmd)

	if plots == nil then
		return "The silo at (" .. siloX .. ", " .. siloY .. ") can't launch " .. Locale.Lookup(wmd.Name) .. " now."
	end

	failure = GetRangeFailure(plots, { x = siloX, y = siloY }, x, y) or GetStrikeWarFailure(city:GetComponentID(), x, y, wmd)

	if failure ~= nil then
		return failure
	end

	local params = SentientSystems_GetSiloStrikeParams(silo, wmd)

	params[CityCommandTypes.PARAM_X1] = x
	params[CityCommandTypes.PARAM_Y1] = y

	if not CityManager.CanStartCommand(city, CityCommandTypes.WMD_STRIKE, params) then
		return "The game won't start that strike."
	end

	CityManager.RequestCommand(city, CityCommandTypes.WMD_STRIKE, params)

	return nil
end

-- Launches the device in weaponType from the player's missile silo at siloX,
-- siloY at the tile x, y, and returns the result as JSON. A silo fires through
-- the city that owns its tile. See OnICBMStrikeEnd in WorldInput.lua.
function SentientSystems_SiloStrike(playerID, siloX, siloY, x, y, weaponType)
	return SentientSystems_RunAction("SiloStrike", SiloStrike, playerID, siloX, siloY, x, y, weaponType)
end

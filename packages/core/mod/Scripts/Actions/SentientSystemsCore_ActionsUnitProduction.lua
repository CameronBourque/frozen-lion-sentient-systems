-- The order that adds production to a city's item for a build charge. The units
-- file loads this file. The calls are in docs/findings/actions/.

-- The commands, by the kind of item they add to. UnitCommandTypes lacks the
-- building one, so each hash comes from GameInfo.UnitCommands.
local COMMANDS = {
	"UNITCOMMAND_BUILDING_PRODUCTION",
	"UNITCOMMAND_DISTRICT_PRODUCTION",
	"UNITCOMMAND_WONDER_PRODUCTION",
	"UNITCOMMAND_PROJECT_PRODUCTION",
}

-- Returns the name of what the city is producing and its hash, or nil when it
-- builds nothing.
local function GetProduction(city)
	local hash = city:GetBuildQueue():GetCurrentProductionTypeHash()

	for _, tableName in ipairs({ "Buildings", "Districts", "Units", "Projects" }) do
		for row in GameInfo[tableName]() do
			if row.Hash == hash then
				return Locale.Lookup(row.Name), hash
			end
		end
	end

	return nil
end

-- Returns why the unit can't add production. The game gives no reasons, so the
-- unit, its moves, and its tile are checked in turn. A district or a wonder
-- takes a unit on its own tile, and a building or a project, one in the city.
local function GetFailure(unit)
	if not SentientSystems_IsBuilder(GameInfo.Units[unit:GetUnitType()]) then
		return "This kind of unit can't add production."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	local x, y = unit:GetX(), unit:GetY()
	local city = Cities.GetPlotPurchaseCity(x, y)

	if city == nil then
		return "The unit has to be in a city, or on the tile of a district or wonder that a city is building."
	end

	local cityName = Locale.Lookup(city:GetName())
	local production, hash = GetProduction(city)

	if production == nil then
		return cityName .. " is not building anything."
	end

	local plotIndex = city:GetBuildQueue():GetConstructionPlot(hash)

	if plotIndex ~= -1 and plotIndex ~= Map.GetPlot(x, y):GetIndex() then
		local plot = Map.GetPlotByIndex(plotIndex)

		return cityName .. " is building " .. production .. " on the tile (" .. plot:GetX() .. ", " .. plot:GetY() .. "). A unit that can add to it has to stand there."
	end

	return cityName .. " is building " .. production .. ", and this unit can't add production to it."
end

-- The game allows at most one of the commands for a unit at a time, and each
-- is requested with no parameters.
SentientSystems_AddUnitAction("add_production", function(_, unit)
	for _, name in ipairs(COMMANDS) do
		local hash = GameInfo.UnitCommands[name].Hash

		if UnitManager.CanStartCommand(unit, hash, false) then
			UnitManager.RequestCommand(unit, hash)

			return nil
		end
	end

	return GetFailure(unit)
end)

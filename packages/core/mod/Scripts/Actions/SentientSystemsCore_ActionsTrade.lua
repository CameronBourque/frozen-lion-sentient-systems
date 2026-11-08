-- The trade route action. SentientSystemsCore_Actions.lua loads this file. The
-- calls are in docs/findings/choices/trade-routes.md.

-- The route check and the idle check are the choice's.
SentientSystems_Include("SentientSystemsCore_ChoicesTradeRoutes")

-- Returns why the unit can't start a route from where it is, or nil. The
-- chooser opens only for an idle trader in a city, and the game starts a route
-- only while the player has a free slot. See Refresh in TradeRouteChooser.lua.
local function GetStartFailure(player, unit)
	if not GameInfo.Units[unit:GetUnitType()].MakeTradeRoute then
		return "This kind of unit can't make trade routes."
	end

	if SentientSystems_GetBusyTraders(player)[unit:GetID()] then
		return "The trader already has a route."
	end

	if Cities.GetCityInPlot(unit:GetX(), unit:GetY()) == nil then
		return "A trader starts a route from a city. Move it into one first."
	end

	local trade = player:GetTrade()

	if trade:GetNumOutgoingRoutes() >= trade:GetOutgoingRouteCapacity() then
		return "The player has no free trade route slot."
	end

	return nil
end

-- Starts a trade route from the trader's city to the city of the choice, and
-- returns the result as JSON. The city is named by its owner and its ID, as the
-- choice lists it. An ok result means the game took the route, which the trader
-- then travels.
function SentientSystems_TradeRoute(playerID, unitID, ownerID, cityID)
	return SentientSystems_RunAction("TradeRoute", function()
		local unit = UnitManager.GetUnit(playerID, unitID)

		if unit == nil then
			return "Player " .. playerID .. " has no unit " .. unitID .. "."
		end

		local failure = GetStartFailure(Players[playerID], unit)

		if failure ~= nil then
			return failure
		end

		local city, failure = SentientSystems_FindCity(ownerID, cityID)

		if failure ~= nil then
			return failure
		end

		local params = {}

		params[UnitOperationTypes.PARAM_X0] = city:GetX()
		params[UnitOperationTypes.PARAM_Y0] = city:GetY()
		params[UnitOperationTypes.PARAM_X1] = unit:GetX()
		params[UnitOperationTypes.PARAM_Y1] = unit:GetY()

		local origin = Cities.GetCityInPlot(unit:GetX(), unit:GetY())
		local path = Game.GetTradeManager():GetTradeRoutePath(origin:GetOwner(), origin:GetID(), ownerID, cityID)

		-- The game's check gives no reasons, so every case it refuses is one
		-- answer: the choice lists the cities that pass.
		if not UnitManager.CanStartOperation(unit, UnitOperationTypes.MAKE_TRADE_ROUTE, nil, params) or path == nil or #path == 0 then
			return "The trader can't reach " .. Locale.Lookup(city:GetName()) .. ". Pick a city from its destinations in the trade route choices."
		end

		UnitManager.RequestOperation(unit, UnitOperationTypes.MAKE_TRADE_ROUTE, params)

		return nil
	end)
end

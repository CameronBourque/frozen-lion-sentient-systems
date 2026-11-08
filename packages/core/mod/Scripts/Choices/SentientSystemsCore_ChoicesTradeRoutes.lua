-- The trade route choice, and the routes from any city. Follows
-- TradeRouteChooser.lua, TradeSupport.lua, and TradeOverview.lua.
-- Shape: bridge/src/choices/trade-routes.ts.

SentientSystems_Include("SentientSystemsCore_Math")

-- Returns the traders that already have a route, by unit ID. A trader is idle
-- when no outgoing route names it. See GetIdleTradeUnits in TradeSupport.lua.
-- The trade route action uses this too.
function SentientSystems_GetBusyTraders(player)
	local busy = {}

	for _, city in player:GetCities():Members() do
		for _, route in ipairs(city:GetTrade():GetOutgoingRoutes()) do
			busy[route.TraderUnitID] = true
		end
	end

	return busy
end

-- Returns what one end of a potential route receives, as the yields the screen
-- lists and the religious pressure on that end, and whether a trading post on
-- the path adds to the origin. See GetYieldsForRoute and
-- GetReligiousPressureForCity in TradeSupport.lua. The trade routes in the
-- state use it too.
function SentientSystems_GetRouteEnd(originCity, destinationCity, side)
	local tradeManager = Game.GetTradeManager()
	local originOwner, originID = originCity:GetOwner(), originCity:GetID()
	local destinationOwner, destinationID = destinationCity:GetOwner(), destinationCity:GetID()
	local route = tradeManager["Calculate" .. side .. "YieldsFromPotentialRoute"](tradeManager, originOwner, originID, destinationOwner, destinationID)
	local path = tradeManager["Calculate" .. side .. "YieldsFromPath"](tradeManager, originOwner, originID, destinationOwner, destinationID)
	local modifiers = tradeManager["Calculate" .. side .. "YieldsFromModifiers"](tradeManager, originOwner, originID, destinationOwner, destinationID)
	local owner = side == "Origin" and originOwner or destinationOwner
	local yields = {}
	local pathBonus = false

	for i = 1, #route do
		local info = GameInfo.Yields[i - 1]

		if info ~= nil then
			local total = route[i] + path[i] + modifiers[i]

			-- Only a route between two players gets the international
			-- multiplier.
			if originOwner ~= destinationOwner then
				total = total * Players[owner]:GetTrade():GetInternationalYieldModifier(i - 1)
			end

			if total ~= 0 then
				yields[#yields + 1] = { type = info.YieldType, amount = SentientSystems_Round(total, 1) }
			end

			pathBonus = pathBonus or path[i] > 0
		end
	end

	local religion = originCity:GetReligion():GetMajorityReligion()
	local pressure = nil

	if religion > 0 then
		local amount = tradeManager["Calculate" .. side .. "ReligiousPressureFromPotentialRoute"](tradeManager, originOwner, originID, destinationOwner, destinationID, religion)

		if amount > 0 then
			pressure = { religion = GameInfo.Religions[religion].ReligionType, amount = amount }
		end
	end

	return { yields = yields, pressure = pressure }, pathBonus
end

-- Returns the name of the city-state quest to send a route to the city, or nil.
-- See AddCityToDestinationStack in TradeRouteChooser.lua.
local function GetQuest(playerID, city)
	local quest = GameInfo.Quests["QUEST_SEND_TRADE_ROUTE"]
	local manager = Game.GetQuestsManager()

	if quest ~= nil and manager ~= nil and manager:HasActiveQuestFromPlayer(playerID, city:GetOwner(), quest.Index) then
		return manager:GetActiveQuestName(playerID, city:GetOwner(), quest.Index)
	end

	return nil
end

-- Returns one destination entry for a city that a route can go to, or nil when
-- the city has no path from the origin. See RefreshChooserPanel. The
-- destinations of a city use it too.
function SentientSystems_GetRouteDestination(player, originCity, city)
	local path = Game.GetTradeManager():GetTradeRoutePath(originCity:GetOwner(), originCity:GetID(), city:GetOwner(), city:GetID())

	if path == nil or #path == 0 then
		return nil
	end

	local origin, pathBonus = SentientSystems_GetRouteEnd(originCity, city, "Origin")

	return {
		owner = city:GetOwner(),
		id = city:GetID(),
		name = Locale.Lookup(city:GetName()),
		distance = Map.GetPlotDistance(originCity:GetX(), originCity:GetY(), city:GetX(), city:GetY()),
		tradingPost = city:GetTrade():HasActiveTradingPost(originCity:GetOwner()),
		pathBonus = pathBonus,
		quest = GetQuest(player:GetID(), city),
		origin = origin,
		destination = SentientSystems_GetRouteEnd(originCity, city, "Destination"),
	}
end

-- Returns the destinations the unit can start a route to, the player's own
-- cities first. See CheckTradeRoute in TradeRouteChooser.lua.
local function GetDestinations(player, unit, originCity)
	local owners = { player }

	for _, other in ipairs(Game.GetPlayers()) do
		if other:GetID() ~= player:GetID() then
			owners[#owners + 1] = other
		end
	end

	local destinations = {}

	for _, owner in ipairs(owners) do
		for _, city in owner:GetCities():Members() do
			local params = {}

			params[UnitOperationTypes.PARAM_X0] = city:GetX()
			params[UnitOperationTypes.PARAM_Y0] = city:GetY()
			params[UnitOperationTypes.PARAM_X1] = unit:GetX()
			params[UnitOperationTypes.PARAM_Y1] = unit:GetY()

			if UnitManager.CanStartOperation(unit, UnitOperationTypes.MAKE_TRADE_ROUTE, nil, params) then
				destinations[#destinations + 1] = SentientSystems_GetRouteDestination(player, originCity, city)
			end
		end
	end

	return destinations
end

-- Returns the trade route choice: each idle trader standing in a city, with its
-- destinations. Returns nil when there is none. The chooser opens only for a
-- trader in a city, and an idle one is the only one that can start a route.
function SentientSystems_GetTradeRouteChoices(player)
	local busy = SentientSystems_GetBusyTraders(player)
	local choices = {}

	for _, unit in player:GetUnits():Members() do
		if GameInfo.Units[unit:GetUnitType()].MakeTradeRoute and not busy[unit:GetID()] then
			local originCity = Cities.GetCityInPlot(unit:GetX(), unit:GetY())

			if originCity ~= nil then
				choices[#choices + 1] = {
					unit = unit:GetID(),
					name = Locale.Lookup(unit:GetName()),
					city = { owner = originCity:GetOwner(), id = originCity:GetID(), name = Locale.Lookup(originCity:GetName()) },
					destinations = GetDestinations(player, unit, originCity),
				}
			end
		end
	end

	return #choices > 0 and choices or nil
end

-- Returns the destinations a route from the player's city could go to, as the
-- Available Routes tab lists them for that origin, the player's own cities
-- first, or nil when the player has no such city. Unlike the choice, it needs
-- no trader. See ViewAvailableRoutes in TradeOverview.lua.
function SentientSystems_GetCityRoutes(player, cityID)
	local originCity = player:GetCities():FindID(cityID)

	if originCity == nil then
		return nil
	end

	local manager = Game.GetTradeManager()
	local owners = { player }

	for _, other in ipairs(Game.GetPlayers()) do
		if other:GetID() ~= player:GetID() then
			owners[#owners + 1] = other
		end
	end

	local destinations = {}

	for _, owner in ipairs(owners) do
		for _, city in owner:GetCities():Members() do
			if manager:CanStartRoute(originCity:GetOwner(), originCity:GetID(), city:GetOwner(), city:GetID(), true) then
				destinations[#destinations + 1] = SentientSystems_GetRouteDestination(player, originCity, city)
			end
		end
	end

	return {
		city = { owner = originCity:GetOwner(), id = originCity:GetID(), name = Locale.Lookup(originCity:GetName()) },
		destinations = destinations,
	}
end

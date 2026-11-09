-- The trade routes section, as the Trade Overview shows them. Follows
-- TradeOverview.lua. Available Routes is SentientSystems_GetCityRoutes.
-- Shape: bridge/src/state/trade.ts.

SentientSystems_Include("SentientSystemsCore_ChoicesTradeRoutes")

-- Returns one route, or nil when either city is gone. Its yields are what the
-- screen shows for the route, as GetYieldsForRoute works them out.
local function GetRoute(route)
	local origin = Players[route.OriginCityPlayer]:GetCities():FindID(route.OriginCityID)
	local destination = Players[route.DestinationCityPlayer]:GetCities():FindID(route.DestinationCityID)

	if origin == nil or destination == nil then
		return nil
	end

	local originEnd, pathBonus = SentientSystems_GetRouteEnd(origin, destination, "Origin")

	return {
		trader = route.TraderUnitID,
		origin = SentientSystems_GetCityRef(origin),
		destination = SentientSystems_GetCityRef(destination),
		pathBonus = pathBonus,
		yields = { origin = originEnd, destination = SentientSystems_GetRouteEnd(origin, destination, "Destination") },
	}
end

-- Adds the route to the list unless a city is gone.
local function AddRoute(routes, route)
	local entry = GetRoute(route)

	if entry ~= nil then
		routes[#routes + 1] = entry
	end
end

-- Returns the routes the player's cities send out, those to the player's own
-- cities first and then by the destination's owner. See ViewMyRoutes.
local function GetOutgoing(player)
	local byOwner = {}

	for _, city in player:GetCities():Members() do
		for _, route in ipairs(city:GetTrade():GetOutgoingRoutes()) do
			local owner = route.DestinationCityPlayer

			byOwner[owner] = byOwner[owner] or {}
			byOwner[owner][#byOwner[owner] + 1] = route
		end
	end

	local owners = {}

	for owner in pairs(byOwner) do
		owners[#owners + 1] = owner
	end

	table.sort(owners, function(a, b)
		if (a == player:GetID()) ~= (b == player:GetID()) then
			return a == player:GetID()
		end

		return a < b
	end)

	local routes = {}

	for _, owner in ipairs(owners) do
		for _, route in ipairs(byOwner[owner]) do
			AddRoute(routes, route)
		end
	end

	return routes
end

-- Returns the routes of other players that end in the player's cities, by the
-- origin's owner. See ViewRoutesToCities.
local function GetIncoming(player)
	local routes = {}

	for _, other in ipairs(Game.GetPlayers()) do
		if other:GetID() ~= player:GetID() then
			for _, city in other:GetCities():Members() do
				for _, route in ipairs(city:GetTrade():GetOutgoingRoutes()) do
					if route.DestinationCityPlayer == player:GetID() then
						AddRoute(routes, route)
					end
				end
			end
		end
	end

	return routes
end

-- Returns the trade routes section. The player section has the count and the
-- capacity. The bonus is the tourism a route gives against the civilization it
-- goes to, in percent. See CreatePlayerHeader.
function SentientSystems_GetTradeState(player)
	return {
		outgoing = GetOutgoing(player),
		incoming = GetIncoming(player),
		tourismBonus = GlobalParameters.TOURISM_TRADE_ROUTE_BONUS + player:GetCulture():GetExtraTradeRouteTourismModifier(),
	}
end

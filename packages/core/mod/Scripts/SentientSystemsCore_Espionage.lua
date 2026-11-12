-- The escape screen's rules that the spy choice and the escape route action
-- share: the next escaping spy, its city, and its routes. Follows OnOpen in
-- EspionageEscape.lua.

include("SentientSystemsCore_Common")

-- The routes in the screen's order, each with the district it leaves by. Every
-- city has a city center, so the screen always allows the last.
local ROUTES = { "DISTRICT_AERODROME", "DISTRICT_HARBOR", "DISTRICT_COMMERCIAL_HUB", "DISTRICT_CITY_CENTER" }

-- Returns the escape routes from a city, as the screen shows them.
local function GetRoutes(city)
	local routes = {}

	for i, districtType in ipairs(ROUTES) do
		local district = GameInfo.Districts[districtType]
		local route = { type = districtType, name = SentientSystems_LookupText("LOC_ESPIONAGE_ESCAPE_CHOICE_" .. i) }

		if i < #ROUTES and not city:GetDistricts():HasDistrict(district.Index, true, true) then
			route.blocked = { SentientSystems_LookupText("LOC_ESPIONAGE_ESCAPE_NO_DISTRICT", district.Name) }
		else
			route.turns = district.TravelTime
		end

		routes[i] = route
	end

	return routes
end

-- Returns the next escaping spy, the city it escapes from, and its routes, or
-- nil with no escaping spy. The screen opens only from a blocker's
-- notification, and its calls are safe only then: GetNextEscapingSpyID crashed
-- the game with no spy escaping, as GetNextPursuedSpyID did with none pursued,
-- so this reads the spy only while a blocker for it is up.
function SentientSystems_GetNextEscape(player)
	if not SentientSystems_HasBlocker(player:GetID(), "ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE", "ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY") then
		return nil
	end

	local spy = player:GetUnits():FindID(player:GetDiplomacy():GetNextEscapingSpyID())

	if spy == nil then
		return nil
	end

	local city = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())

	return { spy = spy, city = city, routes = GetRoutes(city) }
end

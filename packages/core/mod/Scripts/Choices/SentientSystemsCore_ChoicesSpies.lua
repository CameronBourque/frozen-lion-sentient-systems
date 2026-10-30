-- The spy choice: the escape routes for the player's next escaping spy, as the escape screen offers
-- them. The game opens the same screen to choose a dragnet priority. SentientSystemsCore_Choices.lua
-- loads this file. Example: SentientSystems_GetSpyChoices(player) returns a table that encodes as
-- '[{"city":{"id":65536,"name":"Istanbul","owner":4},"description":"Choose the escape route ...",
-- "loot":"None","name":"Laurenza","pursuer":"Police","routes":[{"blocked":["No Aerodrome in city"],
-- "name":"Airplane","type":"DISTRICT_AERODROME"},...,{"name":"Foot","turns":4,
-- "type":"DISTRICT_CITY_CENTER"}],"spy":2555922}]', on one line. The checks follow OnOpen in
-- EspionageEscape.lua.

-- The routes in the screen's order, each with the district it leaves by. Every city has a city
-- center, so the screen always allows the last.
local ROUTES = { "DISTRICT_AERODROME", "DISTRICT_HARBOR", "DISTRICT_COMMERCIAL_HUB", "DISTRICT_CITY_CENTER" }

-- Returns the escape routes from a city, each with type, its district, name, and turns, the
-- district's travel time, or in its place blocked, the screen's reason, when the city lacks the
-- district, as the screen shows them. See OnOpen in
-- EspionageEscape.lua, lines 71 to 106.
local function GetRoutes(city)
	local routes = {}

	for i, districtType in ipairs(ROUTES) do
		local district = GameInfo.Districts[districtType]
		local route = { type = districtType, name = Locale.Lookup("LOC_ESPIONAGE_ESCAPE_CHOICE_" .. i) }

		if i < #ROUTES and not city:GetDistricts():HasDistrict(district.Index, true, true) then
			route.blocked = { Locale.Lookup("LOC_ESPIONAGE_ESCAPE_NO_DISTRICT", district.Name) }
		else
			route.turns = district.TravelTime
		end

		routes[i] = route
	end

	return routes
end

-- Returns the spy choice: the next escaping spy, with spy, its unit ID, name, city, the city it
-- escapes from, with owner, id, and name, loot, what it took, pursuer, who chases it, description,
-- the tooltip the open routes share, and routes. Returns nil with no escaping spy. The screen opens
-- only from a blocker's notification, and its calls are safe only then: GetNextEscapingSpyID crashed
-- the game with no spy escaping, as GetNextPursuedSpyID did with none pursued, so this reads the spy
-- only while a blocker for it is up. See OnOpen in EspionageEscape.lua, lines 36 to 113.
function SentientSystems_GetSpyChoices(player)
	if not SentientSystems_HasBlocker(player:GetID(), "ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE", "ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY") then
		return nil
	end

	local spy = player:GetUnits():FindID(player:GetDiplomacy():GetNextEscapingSpyID())

	if spy == nil then
		return nil
	end

	local city = Cities.GetPlotPurchaseCity(spy:GetX(), spy:GetY())
	local pursuer = spy:GetPursuingSpyName()

	return {
		{
			spy = spy:GetID(),
			name = Locale.Lookup(spy:GetName()),
			city = { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()) },
			loot = Locale.Lookup(spy:GetLootName()),
			pursuer = pursuer == "" and Locale.Lookup("LOC_ESPIONAGE_ESCAPE_PURSUIT_POLICE") or Locale.Lookup("LOC_ESPIONAGE_ESCAPE_PURSUIT_COUNTERSPY", pursuer),
			description = Locale.Lookup("LOC_ESPIONAGE_ESCAPE_TOOLTIP"),
			routes = GetRoutes(city),
		},
	}
end

-- The captured city choice: what the player can do with the next city they captured, as the raze
-- screen offers it, and with the next city that rebelled to join them, as Rise and Fall's disloyal
-- city screen offers it. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetCapturedCityChoices(player) returns a table that encodes as
-- '[{"city":131073,"districts":0,"kind":"captured","name":"Caguana","options":[{"description":
-- "Keeping this opponent's final city will give all major powers 100 ...","type":"KEEP"},
-- {"description":"Razing this opponent's final city will give ...","type":"RAZE"}],"population":1,
-- "x":47,"y":40}]', on one line. The checks follow OnOpen in RazeCity.lua and its replacement in
-- RazeCity_Expansion2.lua, and OnOpen in DisloyalCityChooser.lua.

-- Returns the name of a CityDestroyDirectives value, such as KEEP, which is how the choice names an
-- option.
local function DirectiveName(directive)
	for name, value in pairs(CityDestroyDirectives) do
		if value == directive then
			return name
		end
	end
end

-- Returns a city as the screens show it: city, its ID, name, x, y, population, and districts, the
-- districts that count toward its population limit.
local function GetCity(city, kind)
	return {
		kind = kind,
		city = city:GetID(),
		name = Locale.Lookup(city:GetName()),
		x = city:GetX(),
		y = city:GetY(),
		population = city:GetPopulation(),
		districts = city:GetDistricts():GetNumZonedDistrictsRequiringPopulation(),
	}
end

-- Returns the favor that liberating a city gives with Gathering Storm: more for a major player's city
-- than a city-state's, and more again for bringing a major player back. See OnOpen in
-- RazeCity_Expansion2.lua, lines 33 to 45.
local function GetLiberationFavor(player, originalOwner)
	local isMinor = PlayerConfigurations[originalOwner]:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV
	local favor = isMinor and GlobalParameters.FAVOR_FOR_LIBERATE_CITY_STATE or GlobalParameters.FAVOR_FOR_LIBERATE_PLAYER_CITY

	if not isMinor and Players[originalOwner]:GetCities():GetCount() == 0 and not player:GetStats():GetHasRevivedPlayer(originalOwner) then
		favor = favor + GlobalParameters.FAVOR_FOR_REVIVE_PLAYER
	end

	return favor
end

-- Returns the tooltips of the raze screen's Keep and Raze buttons, and nil for Raze when the city
-- can't be razed. Each names what the choice costs: warmonger points in the base game, and
-- grievances with Gathering Storm, with their own text for a gifted city, a Free City, and the last
-- city of the player it was taken from. See OnOpen in RazeCity.lua, lines 64 to 145, and in
-- RazeCity_Expansion2.lua, lines 9 to 107.
local function GetKeepAndRaze(player, city, conqueredFrom, wipedOut)
	local expansion2 = SentientSystems_HasExpansion2()
	local diplomacy = player:GetDiplomacy()
	local freeCity = expansion2 and Players[conqueredFrom]:IsFreeCities()

	-- The text for the warmonger points of keeping or razing, as each version of the screen words it.
	local function Cost(raze)
		local points = diplomacy:ComputeCityWarmongerPoints(city, conqueredFrom, raze)
		local verb = raze and "RAZE" or "KEEP"

		if wipedOut and expansion2 then
			points = raze and points or points * GlobalParameters.WARMONGER_FINAL_MAJOR_CITY_MULTIPLIER / 100

			return Locale.Lookup("LOC_XP2_RAZE_CITY_" .. verb .. "_LAST_CITY_EXPLANATION", points)
		elseif wipedOut then
			return Locale.Lookup("LOC_RAZE_CITY_" .. verb .. "_LAST_CITY_EXPLANATION")
		elseif expansion2 then
			return Locale.Lookup("LOC_RAZE_CITY_" .. verb .. "_EXPLANATION", Locale.Lookup("LOC_XP2_RAZE_CITY_" .. verb .. "_WARMONGER_EXPLANATION", points))
		end

		return Locale.Lookup("LOC_RAZE_CITY_" .. verb .. "_EXPLANATION", Locale.Lookup("LOC_RAZE_CITY_" .. verb .. "_WARMONGER_EXPLANATION", diplomacy:GetWarmongerLevel(-points)))
	end

	local keep, raze

	if city:GetLastTransferType() == CityTransferTypes.BY_GIFT then
		keep = Locale.Lookup("LOC_RAZE_CITY_KEEP_EXPLANATION_TRADED")
	elseif freeCity then
		keep = Locale.Lookup("LOC_XP2_RAZE_CITY_KEEP_FREE_CITY_EXPLANATION")
	else
		keep = Cost(false)
	end

	if city:CanRaze() then
		raze = freeCity and Locale.Lookup("LOC_XP2_RAZE_CITY_RAZE_FREE_CITY_EXPLANATION") or Cost(true)
	end

	return keep, raze
end

-- Returns the next city the player captured with its options, in the raze screen's order: liberate
-- to the founder, when the city has changed hands since and the player can liberate it to them,
-- liberate to the owner before the war, when the player can liberate it to them, keep, and raze, with
-- blocked, the screen's reason, when the city can't be razed. A liberate option has player, the ID of
-- the player who gets the city. Returns nil with no captured city. See OnOpen in RazeCity.lua, lines
-- 64 to 145.
local function GetCapturedCity(player)
	local city = player:GetCities():GetNextCapturedCity()

	if city == nil then
		return nil
	end

	local diplomacy = player:GetDiplomacy()
	local originalOwner = city:GetOriginalOwner()
	local ownerBefore = city:GetOwnerBeforeOccupation()
	local conqueredFrom = city:GetJustConqueredFrom()
	local wipedOut = Players[originalOwner]:GetCities():GetCount() < 1
	local liberation = SentientSystems_HasExpansion2()
		and Locale.Lookup("LOC_XP2_RAZE_CITY_LIBERATE_WARMONGER_EXPLANATION", GetLiberationFavor(player, originalOwner))
		or Locale.Lookup("LOC_RAZE_CITY_LIBERATE_WARMONGER_EXPLANATION")
	local options = {}

	local function Liberate(directive, owner)
		options[#options + 1] = {
			type = DirectiveName(directive),
			player = owner,
			description = Locale.Lookup("LOC_RAZE_CITY_LIBERATE_EXPLANATION", liberation),
		}
	end

	if originalOwner ~= ownerBefore and diplomacy:CanLiberateCityTo(originalOwner) and originalOwner ~= conqueredFrom then
		Liberate(CityDestroyDirectives.LIBERATE_FOUNDER, originalOwner)
	end

	if diplomacy:CanLiberateCityTo(ownerBefore) and ownerBefore ~= conqueredFrom then
		Liberate(CityDestroyDirectives.LIBERATE_PREVIOUS_OWNER, ownerBefore)
	end

	local keep, raze = GetKeepAndRaze(player, city, conqueredFrom, wipedOut)

	options[#options + 1] = { type = DirectiveName(CityDestroyDirectives.KEEP), description = keep }
	options[#options + 1] = {
		type = DirectiveName(CityDestroyDirectives.RAZE),
		description = raze,
		blocked = raze == nil and { Locale.Lookup("LOC_RAZE_CITY_RAZE_DISABLED_EXPLANATION") } or nil,
	}

	local entry = GetCity(city, "captured")

	entry.options = options

	return entry
end

-- Returns the next city that rebelled to join the player, with its options, keep and refuse, as Rise
-- and Fall's disloyal city screen offers them. Returns nil with no such city, or without Rise and
-- Fall, whose cities have no GetNextRebelledCity. See OnOpen in DisloyalCityChooser.lua, lines 27 to
-- 56.
local function GetDisloyalCity(player)
	local cities = player:GetCities()
	local city = cities.GetNextRebelledCity and cities:GetNextRebelledCity()

	if city == nil then
		return nil
	end

	local entry = GetCity(city, "disloyal")

	entry.options = {
		{ type = DirectiveName(CityDestroyDirectives.KEEP), description = Locale.Lookup("LOC_DISLOYAL_CITY_CHOOSER_KEEP_EXPLANATION") },
		{ type = DirectiveName(CityDestroyDirectives.REJECT), description = Locale.Lookup("LOC_DISLOYAL_CITY_CHOOSER_REFUSE_EXPLANATION") },
	}

	return entry
end

-- Returns the captured city choice: the next captured city, then the next city that rebelled to join
-- the player, each there when there is one, as the game offers one at a time. Returns nil when there
-- are none.
function SentientSystems_GetCapturedCityChoices(player)
	local list = {}
	local captured = GetCapturedCity(player)
	local disloyal = GetDisloyalCity(player)

	if captured ~= nil then
		list[#list + 1] = captured
	end

	if disloyal ~= nil then
		list[#list + 1] = disloyal
	end

	return #list > 0 and list or nil
end

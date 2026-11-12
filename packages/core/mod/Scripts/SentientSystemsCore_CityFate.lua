-- The rules that the city fate choice and action share: the cities waiting for
-- a decision, and the options each screen offers. Follows OnOpen in
-- RazeCity.lua and DisloyalCityChooser.lua.

include("SentientSystemsCore_Common")

-- Returns the name of a CityDestroyDirectives value, which is how the choice
-- names an option.
local function DirectiveName(directive)
	for name, value in pairs(CityDestroyDirectives) do
		if value == directive then
			return name
		end
	end
end

-- Returns the favor that liberating a city gives with Gathering Storm: more for
-- a major player's city than a city-state's, and more again for bringing a
-- major player back. See OnOpen in RazeCity_Expansion2.lua.
local function GetLiberationFavor(player, originalOwner)
	local isMinor = PlayerConfigurations[originalOwner]:GetCivilizationLevelTypeID() ~= CivilizationLevelTypes.CIVILIZATION_LEVEL_FULL_CIV
	local favor = isMinor and GlobalParameters.FAVOR_FOR_LIBERATE_CITY_STATE or GlobalParameters.FAVOR_FOR_LIBERATE_PLAYER_CITY

	if not isMinor and Players[originalOwner]:GetCities():GetCount() == 0 and not player:GetStats():GetHasRevivedPlayer(originalOwner) then
		favor = favor + GlobalParameters.FAVOR_FOR_REVIVE_PLAYER
	end

	return favor
end

-- Returns the tooltips of the raze screen's Keep and Raze buttons, and nil for
-- Raze when the city can't be razed. Each names what the choice costs:
-- warmonger points in the base game, and grievances with Gathering Storm, with
-- their own text for a gifted city, a Free City, and the last city of the
-- player it was taken from. See OnOpen in RazeCity.lua, and in
-- RazeCity_Expansion2.lua.
local function GetKeepAndRaze(player, city, conqueredFrom, wipedOut)
	local expansion2 = SentientSystems_HasExpansion2()
	local diplomacy = player:GetDiplomacy()
	local freeCity = expansion2 and Players[conqueredFrom]:IsFreeCities()

	-- The text for the warmonger points of keeping or razing, as each version
	-- of the screen words it.
	local function Cost(raze)
		local points = diplomacy:ComputeCityWarmongerPoints(city, conqueredFrom, raze)
		local verb = raze and "RAZE" or "KEEP"

		if wipedOut and expansion2 then
			points = raze and points or points * GlobalParameters.WARMONGER_FINAL_MAJOR_CITY_MULTIPLIER / 100

			return SentientSystems_LookupText("LOC_XP2_RAZE_CITY_" .. verb .. "_LAST_CITY_EXPLANATION", points)
		elseif wipedOut then
			return SentientSystems_LookupText("LOC_RAZE_CITY_" .. verb .. "_LAST_CITY_EXPLANATION")
		elseif expansion2 then
			return SentientSystems_LookupText("LOC_RAZE_CITY_" .. verb .. "_EXPLANATION", Locale.Lookup("LOC_XP2_RAZE_CITY_" .. verb .. "_WARMONGER_EXPLANATION", points))
		end

		return SentientSystems_LookupText("LOC_RAZE_CITY_" .. verb .. "_EXPLANATION", Locale.Lookup("LOC_RAZE_CITY_" .. verb .. "_WARMONGER_EXPLANATION", diplomacy:GetWarmongerLevel(-points)))
	end

	local keep, raze

	if city:GetLastTransferType() == CityTransferTypes.BY_GIFT then
		keep = SentientSystems_LookupText("LOC_RAZE_CITY_KEEP_EXPLANATION_TRADED")
	elseif freeCity then
		keep = SentientSystems_LookupText("LOC_XP2_RAZE_CITY_KEEP_FREE_CITY_EXPLANATION")
	else
		keep = Cost(false)
	end

	if city:CanRaze() then
		raze = freeCity and SentientSystems_LookupText("LOC_XP2_RAZE_CITY_RAZE_FREE_CITY_EXPLANATION") or Cost(true)
	end

	return keep, raze
end

-- Returns the options for a captured city, in the raze screen's order:
-- liberate to the founder, when the city has changed hands since and the
-- player can liberate it to them, liberate to the owner before the war, when
-- the player can liberate it to them, keep, and raze. See OnOpen in
-- RazeCity.lua.
local function GetCapturedOptions(player, city)
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
			description = SentientSystems_LookupText("LOC_RAZE_CITY_LIBERATE_EXPLANATION", liberation),
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
		blocked = raze == nil and { SentientSystems_LookupText("LOC_RAZE_CITY_RAZE_DISABLED_EXPLANATION") } or nil,
	}

	return options
end

-- Returns the options for a city that rebelled to join the player, keep and
-- refuse, as Rise and Fall's disloyal city screen offers them. See OnOpen in
-- DisloyalCityChooser.lua.
local function GetDisloyalOptions()
	return {
		{ type = DirectiveName(CityDestroyDirectives.KEEP), description = SentientSystems_LookupText("LOC_DISLOYAL_CITY_CHOOSER_KEEP_EXPLANATION") },
		{ type = DirectiveName(CityDestroyDirectives.REJECT), description = SentientSystems_LookupText("LOC_DISLOYAL_CITY_CHOOSER_REFUSE_EXPLANATION") },
	}
end

-- Returns the cities waiting for the player to decide their fate, each with
-- its kind and options: the next captured city, then the next rebelled one,
-- each when there is one. Without Rise and Fall, cities have no
-- GetNextRebelledCity.
function SentientSystems_GetCityFates(player)
	local cities = player:GetCities()
	local captured = cities:GetNextCapturedCity()
	local rebelled = cities.GetNextRebelledCity and cities:GetNextRebelledCity()
	local fates = {}

	if captured ~= nil then
		fates[#fates + 1] = { city = captured, kind = "captured", options = GetCapturedOptions(player, captured) }
	end

	if rebelled ~= nil then
		fates[#fates + 1] = { city = rebelled, kind = "disloyal", options = GetDisloyalOptions() }
	end

	return fates
end

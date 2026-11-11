-- The city fate choice: what to do with a captured city (RazeCity.lua) or a
-- rebelled one (DisloyalCityChooser.lua), as each screen offers it.
-- Shape: bridge/src/choices/city-fate.ts.

SentientSystems_Include("SentientSystemsCore_CityFate")

-- Returns the city fate choice. Returns nil when no city is waiting.
function SentientSystems_GetCityFateChoices(player)
	local list = {}

	for i, fate in ipairs(SentientSystems_GetCityFates(player)) do
		local city = fate.city

		list[i] = {
			kind = fate.kind,
			city = city:GetID(),
			name = Locale.Lookup(city:GetName()),
			x = city:GetX(),
			y = city:GetY(),
			population = city:GetPopulation(),
			districts = city:GetDistricts():GetNumZonedDistrictsRequiringPopulation(),
			options = fate.options,
		}
	end

	return #list > 0 and list or nil
end

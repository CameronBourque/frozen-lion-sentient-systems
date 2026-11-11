-- The city fate action on the raze and disloyal city screens.
-- SentientSystemsCore_Actions.lua loads this file. The call is in
-- docs/findings/actions/city-fate.md.

SentientSystems_Include("SentientSystemsCore_CityFate")

-- Returns the waiting city with the ID, or the reason there is none.
local function FindWaitingCity(fates, cityID)
	if #fates == 0 then
		return nil, "You have no city to decide. The cityFates choice lists one once you capture a city or one rebels to join you."
	end

	local waiting = {}

	for i, fate in ipairs(fates) do
		if fate.city:GetID() == cityID then
			return fate, nil
		end

		waiting[i] = tostring(fate.city:GetID())
	end

	return nil, "City " .. tostring(cityID) .. " isn't waiting for a decision. Use a city from the cityFates choice: " .. table.concat(waiting, ", ") .. "."
end

-- Returns why the city can't take the directive, or nil. The game takes a
-- liberation that the raze screen hides, so this checks the screen's options.
local function GetDirectiveFailure(fate, directive)
	local types = {}

	for _, option in ipairs(fate.options) do
		if option.type == directive then
			return option.blocked and option.blocked[1] or nil
		end

		-- A blocked option would fail too, so the reason doesn't suggest it.
		if not option.blocked then
			types[#types + 1] = option.type
		end
	end

	local name = Locale.Lookup(fate.city:GetName())

	return tostring(directive) .. " isn't an option for " .. name .. ". Use one of " .. table.concat(types, ", ") .. "."
end

local function DecideCity(playerID, cityID, directive)
	local fates = SentientSystems_GetCityFates(SentientSystems_GetPlayer(playerID))
	local fate, failure = FindWaitingCity(fates, cityID)

	if failure ~= nil then
		return failure
	end

	failure = GetDirectiveFailure(fate, directive)

	if failure ~= nil then
		return failure
	end

	-- Every button of both screens sends this command with its directive.
	local params = { [UnitOperationTypes.PARAM_FLAGS] = CityDestroyDirectives[directive] }

	CityManager.RequestCommand(fate.city, CityCommandTypes.DESTROY, params)

	return nil
end

-- Decides the fate of a captured or rebelled city with an option type from the
-- cityFates choice, and returns the result as JSON.
function SentientSystems_DecideCity(playerID, cityID, directive)
	return SentientSystems_RunAction("DecideCity", DecideCity, playerID, cityID, directive)
end

-- The envoy action on the City-States screen. SentientSystemsCore_Actions.lua
-- loads this file. The call is in docs/findings/actions/envoys.md.

-- Returns why the player can't send the count of envoys, or nil. The screen
-- adds envoys up to the tokens the player has. See RealizeEnvoyChangeButtons
-- in CityStates.lua.
local function GetTokensFailure(influence, count)
	local tokens = influence:GetTokensToGive()

	if not influence:CanGiveInfluence() or tokens <= 0 then
		return "You have no envoys to send. The envoys choice lists city-states once you do."
	end

	if type(count) ~= "number" or count < 1 or count % 1 ~= 0 then
		return "Send a whole number of envoys, at least 1, not " .. tostring(count) .. "."
	end

	if count > tokens then
		return "You have " .. tokens .. " envoys to send, not " .. count .. "."
	end

	return nil
end

-- Returns why the player can't send envoys to the city-state, or nil. The
-- screen turns a city-state's buttons on when CanGiveTokensToPlayer is true,
-- which is false for one the player hasn't met or is at war with. See GetData
-- and RealizeEnvoyChangeButtons in CityStates.lua.
local function GetCityStateFailure(player, cityStateID)
	local cityState = type(cityStateID) == "number" and Players[cityStateID] or nil
	local influence = cityState and cityState:GetInfluence()

	if influence == nil or not influence:CanReceiveInfluence() then
		return "Player " .. tostring(cityStateID) .. " isn't a city-state. Use an ID from the envoys choice."
	end

	if player:GetInfluence():CanGiveTokensToPlayer(cityStateID) then
		return nil
	end

	local name = Locale.Lookup(PlayerConfigurations[cityStateID]:GetCivilizationShortDescription())

	if not player:GetDiplomacy():HasMet(cityStateID) then
		return "You haven't met city-state " .. cityStateID .. ". Use an ID from the envoys choice."
	end

	if player:GetDiplomacy():IsAtWarWith(cityStateID) then
		return "You are at war with " .. name .. ". Make peace first."
	end

	return "You can't send envoys to " .. name .. ". Use an ID from the envoys choice."
end

local function SendEnvoys(playerID, cityStateID, count)
	local player = SentientSystems_GetPlayer(playerID)

	count = count or 1

	local failure = GetTokensFailure(player:GetInfluence(), count) or GetCityStateFailure(player, cityStateID)

	if failure ~= nil then
		return failure
	end

	-- The screen sends one request for each envoy. See OnConfirmPlacement.
	for _ = 1, count do
		UI.RequestPlayerOperation(playerID, PlayerOperations.GIVE_INFLUENCE_TOKEN, { [PlayerOperations.PARAM_PLAYER_ONE] = cityStateID })
	end

	return nil
end

-- Sends envoys to the city-state and returns the result as JSON. The
-- city-state is an ID from the envoys choice, and the count is 1 when left
-- out.
function SentientSystems_SendEnvoys(playerID, cityState, count)
	return SentientSystems_RunAction("SendEnvoys", SendEnvoys, playerID, cityState, count)
end

-- The envoys section of the state: the player's envoy tokens and influence, and each met
-- city-state's envoys and suzerain, as the City-States screen shows them.
-- SentientSystemsCore_State.lua loads this file. Example: SentientSystems_GetEnvoyState(player)
-- returns a table that encodes as '{"cityStates":[{"envoys":2,"name":"Samarkand","player":12,
-- "suzerain":1,"suzerainNeeds":4,"type":"TRADE"}],"influence":{"envoys":1,"perTurn":0,"points":0,
-- "threshold":50},"tokens":4}', on one line. The checks follow GetData in CityStates.lua.

-- The fewest envoys that make a suzerain, which CityStates.lua also sets by hand.
local MIN_SUZERAIN_ENVOYS = 3

-- The prefix of the leader types that name each kind of city-state, such as
-- LEADER_MINOR_CIV_SCIENTIFIC.
local KIND_PREFIX = "LEADER_MINOR_CIV_"
local KINDS = { SCIENTIFIC = true, RELIGIOUS = true, TRADE = true, CULTURAL = true, MILITARISTIC = true, INDUSTRIAL = true }

-- Returns the kind of a city-state, such as TRADE, from its leader or the leader it inherits from,
-- or nil for a leader of no kind. See GetCityStateType in CityStates.lua, lines 1591 to 1613.
local function GetKind(playerID)
	local leader = PlayerConfigurations[playerID]:GetLeaderTypeName()
	local row = GameInfo.Leaders[leader]

	for _, typeName in ipairs({ leader, row and row.InheritFrom }) do
		local kind = typeName:sub(#KIND_PREFIX + 1)

		if typeName:sub(1, #KIND_PREFIX) == KIND_PREFIX and KINDS[kind] then
			return kind
		end
	end

	return nil
end

-- Returns one city-state as the screen's list shows it: player, its ID, name, type, envoys, the
-- player's envoys there, suzerain, the suzerain's ID when it is the player or a player they have
-- met, or suzerainUnmet, true for a player they haven't met, and suzerainNeeds, the envoys the
-- player needs to be suzerain, at least 3, and one more than the most any other player has. See
-- GetData in CityStates.lua, lines 1411 to 1530.
local function GetCityState(player, cityState)
	local playerID = player:GetID()
	local cityStateID = cityState:GetID()
	local influence = cityState:GetInfluence()
	local suzerain = influence:GetSuzerain()
	local most = influence:GetMostTokensReceived()
	local entry = {
		player = cityStateID,
		name = Locale.Lookup(PlayerConfigurations[cityStateID]:GetCivilizationShortDescription()),
		type = GetKind(cityStateID),
		envoys = influence:GetTokensReceived(playerID),
		suzerainNeeds = math.max(MIN_SUZERAIN_ENVOYS, suzerain == playerID and most or most + 1),
	}

	if suzerain == playerID or (suzerain >= 0 and player:GetDiplomacy():HasMet(suzerain)) then
		entry.suzerain = suzerain
	elseif suzerain >= 0 then
		entry.suzerainUnmet = true
	end

	return entry
end

-- Returns whether a living minor player is a city-state the player has met, as the screen lists
-- them. The Free Cities can't receive envoys, so the screen leaves them out.
local function IsMetCityState(player, minor)
	return minor:GetID() ~= player:GetID()
		and minor:GetInfluence():CanReceiveInfluence()
		and player:GetDiplomacy():HasMet(minor:GetID())
end

-- Returns the envoys section: tokens, the envoys the player can send now, influence, with points,
-- perTurn, threshold, and envoys, the envoys each threshold gives, as the screen's header shows
-- them, and cityStates, each met city-state in the game's order. See RealizeListHeader in
-- CityStates.lua, lines 609 to 662.
function SentientSystems_GetEnvoyState(player)
	local influence = player:GetInfluence()
	local cityStates = {}

	for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
		if IsMetCityState(player, minor) then
			cityStates[#cityStates + 1] = GetCityState(player, minor)
		end
	end

	return {
		tokens = influence:GetTokensToGive(),
		influence = {
			points = influence:GetPointsEarned(),
			perTurn = influence:GetPointsPerTurn(),
			threshold = influence:GetPointsThreshold(),
			envoys = influence:GetTokensPerThreshold(),
		},
		cityStates = cityStates,
	}
end

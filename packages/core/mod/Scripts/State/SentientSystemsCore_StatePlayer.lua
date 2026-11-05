-- The player section, as the top bar shows it. Follows RefreshYields and
-- RefreshTrade in TopPanel.lua and TopPanel_Expansion2.lua.
-- Shape: bridge/src/state/player.ts.

SentientSystems_Include("SentientSystemsCore_StatePlayerIncome")
SentientSystems_Include("SentientSystemsCore_StatePlayerEra")
SentientSystems_Include("SentientSystemsCore_StatePlayerResources")

-- Rounds a number to the nearest tenth, as the top bar's number format does.
local function RoundNearest(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Returns the player's gold: the balance, rounded down, and the income less the
-- upkeep per turn. See RefreshYields in TopPanel.lua.
local function GetGold(player)
	local treasury = player:GetTreasury()

	return {
		balance = math.floor(treasury:GetGoldBalance()),
		perTurn = RoundNearest(treasury:GetGoldYield() - treasury:GetTotalMaintenance()),
	}
end

-- Returns the player's faith, the balance and the income per turn. See
-- RefreshYields in TopPanel.lua.
local function GetFaith(player)
	local religion = player:GetReligion()

	return { balance = RoundNearest(religion:GetFaithBalance()), perTurn = RoundNearest(religion:GetFaithYield()) }
end

-- Returns the player section. tradeRoutes is left out while the capacity is 0,
-- and favor without Gathering Storm, whose players have no GetFavorPerTurn. See
-- RefreshTrade in TopPanel.lua.
function SentientSystems_GetPlayerState(player)
	local trade = player:GetTrade()
	local capacity = trade:GetOutgoingRouteCapacity()
	local state = {
		gold = GetGold(player),
		faith = GetFaith(player),
		science = RoundNearest(player:GetTechs():GetScienceYield()),
		culture = RoundNearest(player:GetCulture():GetCultureYield()),
		tourism = RoundNearest(player:GetStats():GetTourism()),
		income = SentientSystems_GetIncomeState(player),
		resources = SentientSystems_GetResourcesState(player),
		era = SentientSystems_GetEraState(player),
	}

	if capacity > 0 then
		state.tradeRoutes = { active = trade:GetNumOutgoingRoutes(), capacity = capacity }
	end

	if player.GetFavorPerTurn ~= nil then
		state.favor = { balance = player:GetFavor(), perTurn = RoundNearest(player:GetFavorPerTurn()) }
	end

	return state
end

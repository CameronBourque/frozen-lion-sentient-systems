-- The player section, as the top bar shows it. Follows RefreshYields and
-- RefreshTrade in TopPanel.lua and TopPanel_Expansion2.lua.
-- Shape: bridge/src/state/player.ts.

SentientSystems_Include("SentientSystemsCore_StatePlayerIncome")
SentientSystems_Include("SentientSystemsCore_StatePlayerEra")
SentientSystems_Include("SentientSystemsCore_StatePlayerResources")

-- Returns the player's gold: the balance, rounded down, and the income less the
-- upkeep per turn. See RefreshYields in TopPanel.lua.
local function GetGold(player)
	local treasury = player:GetTreasury()

	return {
		balance = math.floor(treasury:GetGoldBalance()),
		perTurn = SentientSystems_Round(treasury:GetGoldYield() - treasury:GetTotalMaintenance(), 1),
	}
end

-- Returns the player's faith, the balance and the income per turn. See
-- RefreshYields in TopPanel.lua.
local function GetFaith(player)
	local religion = player:GetReligion()

	return { balance = SentientSystems_Round(religion:GetFaithBalance(), 1), perTurn = SentientSystems_Round(religion:GetFaithYield(), 1) }
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
		science = SentientSystems_Round(player:GetTechs():GetScienceYield(), 1),
		culture = SentientSystems_Round(player:GetCulture():GetCultureYield(), 1),
		tourism = SentientSystems_Round(player:GetStats():GetTourism(), 1),
		income = SentientSystems_GetIncomeState(player),
		resources = SentientSystems_GetResourcesState(player),
		era = SentientSystems_GetEraState(player),
	}

	if capacity > 0 then
		state.tradeRoutes = { active = trade:GetNumOutgoingRoutes(), capacity = capacity }
	end

	if player.GetFavorPerTurn ~= nil then
		state.favor = { balance = player:GetFavor(), perTurn = SentientSystems_Round(player:GetFavorPerTurn(), 1) }
	end

	return state
end

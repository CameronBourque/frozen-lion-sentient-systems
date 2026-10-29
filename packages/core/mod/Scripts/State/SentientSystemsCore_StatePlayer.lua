-- The player section of the state: what the top bar shows about the player as a whole, the gold and
-- faith balances, the science, culture, faith, gold, and tourism per turn, the trade routes, and, with
-- Gathering Storm, diplomatic favor. SentientSystemsCore_State.lua loads this file. Example:
-- SentientSystems_GetPlayerState(player) returns a table that encodes as '{"culture":216.6,
-- "faith":{"balance":2357,"perTurn":109},"favor":{"balance":335,"perTurn":3},
-- "gold":{"balance":9610,"perTurn":265.1},"science":123.5,"tourism":92,
-- "income":{...},"resources":[...],"tradeRoutes":{"active":17,"capacity":20}}', on one line. The
-- numbers follow RefreshYields, RefreshTrade, and the favor override in TopPanel.lua and
-- TopPanel_Expansion2.lua.
-- income and resources come from SentientSystemsCore_StatePlayerIncome.lua and
-- SentientSystemsCore_StatePlayerResources.lua.

SentientSystems_Include("SentientSystemsCore_StatePlayerIncome")
SentientSystems_Include("SentientSystemsCore_StatePlayerResources")

-- Rounds a number to the nearest tenth, as the top bar's number format does.
local function RoundNearest(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Returns the player's gold: the balance, rounded down, and the income less the upkeep per turn. See
-- RefreshYields in TopPanel.lua, lines 136 to 151.
local function GetGold(player)
	local treasury = player:GetTreasury()

	return {
		balance = math.floor(treasury:GetGoldBalance()),
		perTurn = RoundNearest(treasury:GetGoldYield() - treasury:GetTotalMaintenance()),
	}
end

-- Returns the player's faith, the balance and the income per turn. See RefreshYields in TopPanel.lua,
-- lines 123 to 134.
local function GetFaith(player)
	local religion = player:GetReligion()

	return { balance = RoundNearest(religion:GetFaithBalance()), perTurn = RoundNearest(religion:GetFaithYield()) }
end

-- Returns the player section: gold, faith, science, culture, and tourism per turn, income,
-- resources, tradeRoutes, with active and capacity, left out while the capacity is 0 as the bar hides
-- it, and favor, with balance and perTurn, left out without Gathering Storm, whose players have no
-- GetFavorPerTurn. See RefreshTrade in TopPanel.lua, lines 190 to 224, and RefreshYields in
-- TopPanel_Expansion2.lua.
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
	}

	if capacity > 0 then
		state.tradeRoutes = { active = trade:GetNumOutgoingRoutes(), capacity = capacity }
	end

	if player.GetFavorPerTurn ~= nil then
		state.favor = { balance = player:GetFavor(), perTurn = RoundNearest(player:GetFavorPerTurn()) }
	end

	return state
end

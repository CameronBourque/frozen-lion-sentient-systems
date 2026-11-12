-- The player section, as the top bar shows it. Follows RefreshYields and
-- RefreshTrade in TopPanel.lua and TopPanel_Expansion2.lua.
-- Shape: bridge/src/state/player.ts.

-- Adds the items of a type that the owner gives in the deal to the list,
-- leaving out an item with no duration. sign is -1 when the player gives them.
local function AddDealItems(list, deal, itemType, ownerID, otherID, sign, turn)
	for _, item in ipairs(deal:FindItemsByType(itemType, DealItemSubTypes.NONE, ownerID) or {}) do
		local duration = item:GetDuration()

		if duration ~= 0 then
			list[#list + 1] = { item = item, player = otherID, turnsLeft = duration - (turn - item:GetEnactedTurn()), amount = sign * item:GetAmount() }
		end
	end
end

-- Returns the items of a type in the player's deals. Each has the item, the
-- other player, the turns left, and the amount, negative when the player gives
-- it. See GetData in ReportScreen.lua.
function SentientSystems_GetDealItems(playerID, itemType)
	local list = {}
	local turn = Game.GetCurrentGameTurn()

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local otherID = other:GetID()

		if otherID ~= playerID then
			for _, deal in ipairs(DealManager.GetPlayerDeals(playerID, otherID) or {}) do
				AddDealItems(list, deal, itemType, playerID, otherID, -1, turn)
				AddDealItems(list, deal, itemType, otherID, otherID, 1, turn)
			end
		end
	end

	return list
end

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
		wmds = SentientSystems_GetWmdStockpile(player),
	}

	if capacity > 0 then
		state.tradeRoutes = { active = trade:GetNumOutgoingRoutes(), capacity = capacity }
	end

	if player.GetFavorPerTurn ~= nil then
		state.favor = { balance = player:GetFavor(), perTurn = SentientSystems_Round(player:GetFavorPerTurn(), 1) }
	end

	return state
end

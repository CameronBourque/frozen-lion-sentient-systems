-- The city actions. SentientSystemsCore_Actions.lua loads this file. The calls
-- are in docs/findings/actions/.

SentientSystems_Include("SentientSystemsCore_Placement")
SentientSystems_Include("SentientSystemsCore_ChoicesPurchases")

-- Returns what the type names: the table of its row, the key of the operation
-- parameter that carries its hash, and whether it needs a tile. nil when the
-- type is no unit, building, district, wonder, or project. A wonder is a
-- building row, so its row says so. See BuildUnit, BuildBuilding, ZoneDistrict,
-- and AdvanceProject in ProductionPanel.lua.
local function FindProductionItem(item)
	if type(item) ~= "string" then
		return nil
	end

	local unit = GameInfo.Units[item]

	if unit then
		return unit, CityOperationTypes.PARAM_UNIT_TYPE, false
	end

	local building = GameInfo.Buildings[item]

	if building then
		return building, CityOperationTypes.PARAM_BUILDING_TYPE, building.RequiresPlacement
	end

	local district = GameInfo.Districts[item]

	if district then
		return district, CityOperationTypes.PARAM_DISTRICT_TYPE, district.RequiresPlacement
	end

	local project = GameInfo.Projects[item]

	if project then
		return project, CityOperationTypes.PARAM_PROJECT_TYPE, false
	end

	return nil
end

-- Returns the reason the item is none of the types FindProductionItem knows.
-- choice names the choice whose options the item comes from.
local function GetNotItemReason(item, choice)
	return tostring(item) .. " isn't a unit, building, district, wonder, or project. Use the type of an option of the " .. choice .. " choice."
end

-- Returns what CanProduce takes for the item: a standard formation of a unit,
-- or the hash of any other row.
local function GetCheckParams(row, key)
	if key == CityOperationTypes.PARAM_UNIT_TYPE then
		return { UnitType = row.Hash, MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION }
	end

	return row.Hash
end

-- Returns "<start> now" with the reasons after a colon, or without them.
local function WithReasons(start, reasons)
	if #reasons == 0 then
		return start .. " now."
	end

	return start .. " now: " .. table.concat(reasons, "; ")
end

-- Returns why the city can't produce the item, from the game's full check and
-- its reasons when it gives some, or nil when it can.
local function GetProduceFailure(buildQueue, checkParams, item)
	local canProduce, results = buildQueue:CanProduce(checkParams, false, true)

	if canProduce then
		return nil
	end

	return WithReasons("This city can't produce " .. item, SentientSystems_GetFailureReasons(results, CityCommandResults.FAILURE_REASONS))
end

-- Adds the tile at x and y to the build parameters, or returns why it is no
-- place for the district or the wonder. The city must own the tile, and the
-- item must be able to go there now. Tiles to buy get their own reason. See
-- SentientSystems_GetPlacement.
local function SetPlacementTile(parameters, city, row, key, item, x, y)
	if x == nil or y == nil then
		return item .. " goes on a tile. Give x and y, from the placement call."
	end

	local purchasable = SentientSystems_GetPurchasablePlots(city)
	local tiles, purchaseTiles

	if key == CityOperationTypes.PARAM_DISTRICT_TYPE then
		tiles, purchaseTiles = SentientSystems_GetDistrictTiles(city, purchasable, row)
	else
		tiles, purchaseTiles = SentientSystems_GetWonderTiles(city, purchasable, row)
	end

	if SentientSystems_HasTile(tiles, x, y) then
		parameters[CityOperationTypes.PARAM_X] = x
		parameters[CityOperationTypes.PARAM_Y] = y

		return nil
	end

	if SentientSystems_HasTile(purchaseTiles, x, y) then
		return "(" .. x .. ", " .. y .. ") isn't in the city's territory yet. Buy the tile first."
	end

	return "(" .. x .. ", " .. y .. ") isn't a tile where " .. item .. " can go. Use a tile from the placement call."
end

-- Returns whether the production panel would ask for a tile: the item needs
-- one, and the city hasn't placed it or built it. See BuildBuilding and
-- ZoneDistrict in ProductionPanel.lua.
local function NeedsTile(city, row, needsPlacement)
	if not needsPlacement or city:GetBuildQueue():HasBeenPlaced(row.Hash) then
		return false
	end

	return not city:GetBuildings():HasBuilding(row.Hash)
end

-- The most items the production queue holds after the current one. See
-- MAX_QUEUE_SIZE in ProductionHelper.lua.
local MAX_QUEUE_SIZE = 7

-- Sets where the build goes in the queue and returns why it can't, or nil. The
-- panel replaces the current item at position 0 when its queue is closed, and
-- adds to the end when it is open. It replaces the last item when the queue is
-- full, which the action refuses instead. See GetBuildInsertMode in
-- ProductionPanel.lua.
local function SetInsertMode(parameters, buildQueue, append)
	if not append then
		parameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_REPLACE_AT
		parameters[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION] = 0

		return nil
	end

	if buildQueue:GetSize() - 1 >= MAX_QUEUE_SIZE then
		return "This city's production queue is full. It holds " .. MAX_QUEUE_SIZE .. " items after the current one."
	end

	parameters[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_APPEND

	return nil
end

-- Requests the build, or returns why the game won't start it, with the full
-- check's reasons when it gives some.
local function StartBuild(city, parameters, buildQueue, checkParams, item)
	if not CityManager.CanStartOperation(city, CityOperationTypes.BUILD, parameters, true) then
		return GetProduceFailure(buildQueue, checkParams, item) or "The game won't start " .. item .. " in this city."
	end

	CityManager.RequestOperation(city, CityOperationTypes.BUILD, parameters)

	return nil
end

local function SetProduction(playerID, cityID, item, x, y, append)
	local city, failure = SentientSystems_FindCity(playerID, cityID)

	if failure ~= nil then
		return failure
	end

	local row, key, needsPlacement = FindProductionItem(item)

	if row == nil then
		return GetNotItemReason(item, "production")
	end

	local buildQueue = city:GetBuildQueue()
	local checkParams = GetCheckParams(row, key)

	-- The panel lists only what CanProduce allows when it only tests.
	if not buildQueue:CanProduce(checkParams, true) then
		return item .. " isn't one of this city's production choices."
	end

	local parameters = { [key] = row.Hash }

	failure = SetInsertMode(parameters, buildQueue, append)

	if failure ~= nil then
		return failure
	end

	-- CanProduce refuses a district or a wonder for want of a tile, which the
	-- tile check explains better, so only the other items are asked.
	if NeedsTile(city, row, needsPlacement) then
		failure = SetPlacementTile(parameters, city, row, key, item, x, y)
	else
		failure = GetProduceFailure(buildQueue, checkParams, item)
	end

	if failure ~= nil then
		return failure
	end

	return StartBuild(city, parameters, buildQueue, checkParams, item)
end

-- Replaces what the city is producing with the item, or adds the item to the
-- end of its queue when append is true, and returns the result as JSON. The
-- item is the type of an option of the production choice, such as UNIT_WARRIOR.
-- A district or a wonder also takes the tile, x and y, from the city's
-- placement tiles, unless the city has placed it already. See
-- ConfirmPlaceDistrict and ConfirmPlaceWonder in
-- StrategicView_MapPlacement.lua.
function SentientSystems_SetProduction(playerID, cityID, item, x, y, append)
	return SentientSystems_RunAction("SetProduction", SetProduction, playerID, cityID, item, x, y, append)
end

-- Returns the purchase command's parameters for a unit or a building bought
-- with the yield, or nil and why the item can't be bought this way.
local function GetPurchaseParams(purchase, row, key, item)
	local params = { [CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields[purchase.yield].Index }

	if key == CityOperationTypes.PARAM_UNIT_TYPE then
		params[CityCommandTypes.PARAM_UNIT_TYPE] = row.Hash
		params[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION
	elseif key == CityOperationTypes.PARAM_BUILDING_TYPE then
		params[CityCommandTypes.PARAM_BUILDING_TYPE] = row.Hash
	else
		return nil, item .. " can't be bought with this action, which buys units and buildings."
	end

	return params, nil
end

-- Returns why the city can't buy the item now, or nil. The game's full check
-- gives its reasons, and the panel's text is added when the player can't
-- afford it.
local function GetBuyFailure(city, params, canAfford, purchase, item, yield)
	local canStart, results = CityManager.CanStartCommand(city, CityCommandTypes.PURCHASE, false, params, true)

	if canStart and canAfford then
		return nil
	end

	local reasons = SentientSystems_GetFailureReasons(results, CityCommandResults.FAILURE_REASONS)

	if not canAfford then
		reasons[#reasons + 1] = SentientSystems_LookupText(purchase.cantAffordKey)
	end

	return WithReasons("This city can't buy " .. item .. " with " .. yield, reasons)
end

local function Purchase(playerID, cityID, item, yield)
	local city, failure = SentientSystems_FindCity(playerID, cityID)

	if failure ~= nil then
		return failure
	end

	local purchase = SENTIENTSYSTEMS_PURCHASE_YIELDS[yield]

	if purchase == nil then
		return tostring(yield) .. " isn't a yield to buy with. Use gold or faith."
	end

	local row, key = FindProductionItem(item)

	if row == nil then
		return GetNotItemReason(item, "purchases")
	end

	local params

	params, failure = GetPurchaseParams(purchase, row, key, item)

	if failure ~= nil then
		return failure
	end

	-- The panel lists only what CanStartCommand allows when it only tests.
	if not CityManager.CanStartCommand(city, CityCommandTypes.PURCHASE, true, params, false) then
		return item .. " isn't one of this city's " .. yield .. " purchase choices."
	end

	local canAfford = purchase.store(Players[playerID]):CanAfford(cityID, row.Hash)

	failure = GetBuyFailure(city, params, canAfford, purchase, item, yield)

	if failure ~= nil then
		return failure
	end

	CityManager.RequestCommand(city, CityCommandTypes.PURCHASE, params)

	return nil
end

-- Buys a unit or a building in the city with gold or faith, and returns the
-- result as JSON.
-- The item is the type of an option of the purchases choice, such as
-- UNIT_BUILDER, and the yield is its key, gold or faith. A unit is a standard
-- unit, not a corps or an army. The game gives no reason when the player can't
-- afford an item, so the panel's text is added, as the choice does. See
-- PurchaseUnit and PurchaseBuilding in ProductionPanel.lua.
function SentientSystems_Purchase(playerID, cityID, item, yield)
	return SentientSystems_RunAction("Purchase", Purchase, playerID, cityID, item, yield)
end

-- Returns the plot index of the tile the city can buy at x and y, or nil.
local function FindPurchasableTile(city, x, y)
	for _, plotIndex in ipairs(SentientSystems_GetPurchasablePlots(city)) do
		local plot = Map.GetPlotByIndex(plotIndex)

		if plot:GetX() == x and plot:GetY() == y then
			return plotIndex
		end
	end

	return nil
end

-- Returns the lens's tooltip when the player's gold falls short of the tile's
-- cost, or nil when it covers it.
local function GetTileCostFailure(player, city, plotIndex)
	local cost = city:GetGold():GetPlotPurchaseCost(plotIndex)
	local gold = player:GetTreasury():GetGoldBalance()

	if cost > gold then
		return SentientSystems_LookupText(SENTIENTSYSTEMS_NEED_MORE_GOLD_KEY, cost - math.floor(gold))
	end

	return nil
end

-- Requests the city command when the game allows it, or returns the refusal.
local function RequestCityCommand(city, command, params, refusal)
	if not CityManager.CanStartCommand(city, command, params) then
		return refusal
	end

	CityManager.RequestCommand(city, command, params)

	return nil
end

local function PurchaseTile(playerID, cityID, x, y)
	local city, failure = SentientSystems_FindCity(playerID, cityID)

	if failure ~= nil then
		return failure
	end

	failure = SentientSystems_GetOffMapFailure(x, y)

	if failure ~= nil then
		return failure
	end

	local plotIndex = FindPurchasableTile(city, x, y)

	if plotIndex == nil then
		return "(" .. x .. ", " .. y .. ") isn't a tile this city can buy. Use a tile from the purchases choice."
	end

	failure = GetTileCostFailure(Players[playerID], city, plotIndex)

	if failure ~= nil then
		return failure
	end

	local params = SentientSystems_GetTileParams(CityCommandTypes, x, y)

	params[CityCommandTypes.PARAM_PLOT_PURCHASE] = UI.GetInterfaceModeParameter(CityCommandTypes.PARAM_PLOT_PURCHASE)

	return RequestCityCommand(city, CityCommandTypes.PURCHASE, params, "The game won't buy (" .. x .. ", " .. y .. ") for this city.")
end

-- Buys the tile at x and y for the city with gold, and returns the result as
-- JSON. The tile is one of the tiles of the purchases choice. The game gives no
-- reason when the player can't afford it, so the lens's tooltip is the reason,
-- as the choice has it. See OnClickPurchasePlot in PlotInfo.lua.
function SentientSystems_PurchaseTile(playerID, cityID, x, y)
	return SentientSystems_RunAction("PurchaseTile", PurchaseTile, playerID, cityID, x, y)
end

-- Returns the tiles the city's shot can hit.
local function GetCityTargetTiles(city)
	local R = CityCommandResults

	return SentientSystems_GetTargetTiles(CityManager.GetCommandTargets(city, CityCommandTypes.RANGE_ATTACK, {}), R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)
end

local function CityAttack(playerID, cityID, x, y)
	local city, failure = SentientSystems_FindCity(playerID, cityID)

	if failure ~= nil then
		return failure
	end

	failure = SentientSystems_GetUnseenTileFailure(playerID, x, y)

	if failure ~= nil then
		return failure
	end

	failure = SentientSystems_GetTargetFailure(GetCityTargetTiles(city), x, y)

	if failure ~= nil then
		return failure
	end

	return RequestCityCommand(city, CityCommandTypes.RANGE_ATTACK, SentientSystems_GetTileParams(UnitOperationTypes, x, y), "The game won't start that attack.")
end

-- Orders a city to shoot at a tile in its range, and returns the result as
-- JSON. A city's shot is a city command, and the UI shows no war dialog for it.
function SentientSystems_CityAttack(playerID, cityID, x, y)
	return SentientSystems_RunAction("CityAttack", CityAttack, playerID, cityID, x, y)
end

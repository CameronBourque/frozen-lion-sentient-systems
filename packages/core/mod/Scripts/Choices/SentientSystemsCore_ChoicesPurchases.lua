-- The purchase choice: what each of the player's cities can buy, as the production panel's purchase
-- tabs list it. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetPurchaseChoices(player) returns a list with one table for each city, which
-- encodes as '{"city":65536,"faith":{...},"gold":{"buildings":[...],"districts":[],"units":[{"cost":100,
-- "type":"UNIT_BUILDER"}]},"name":"Rome"}', on one line, with faith in the same form as gold. The checks follow ComposeUnitForPurchase,
-- ComposeBldgForPurchase, and ComposeDistrictForPurchase in ProductionPanel.lua, lines 1632 to 1827.
-- The tiles to buy with gold follow ShowPurchases in PlotInfo.lua.

SentientSystems_Include("SentientSystemsCore_Placement")

-- Each yield the city can buy with: its key in a city's purchases, its name in GameInfo.Yields, the
-- player's store of it, the text key the panel adds when the player can't afford an item, and
-- whether the panel tries a unit or a building with it. The panel tries every district with each
-- yield. A city can buy some units and buildings with faith that the game marks for gold, such as
-- with a policy, and the panel asks the city for those. See GetData in ProductionPanel.lua, lines 2006 to 2016, 2084 to 2097, and 2188 to 2201.
local PURCHASE_YIELDS = {
	{
		key = "gold",
		yield = "YIELD_GOLD",
		source = function(player)
			return player:GetTreasury()
		end,
		cantAffordKey = "LOC_BUILDING_INSUFFICIENT_FUNDS",
		triesUnit = function(row)
			return row.PurchaseYield == "YIELD_GOLD"
		end,
		triesBuilding = function(row)
			return row.PurchaseYield == "YIELD_GOLD"
		end,
	},
	{
		key = "faith",
		yield = "YIELD_FAITH",
		source = function(player)
			return player:GetReligion()
		end,
		cantAffordKey = "LOC_BUILDING_INSUFFICIENT_FAITH",
		triesUnit = function(row, city)
			return row.PurchaseYield == "YIELD_FAITH" or city:GetGold():IsUnitFaithPurchaseEnabled(row.Hash)
		end,
		triesBuilding = function(row, city)
			return row.PurchaseYield == "YIELD_FAITH" or city:GetGold():IsBuildingFaithPurchaseEnabled(row.Hash)
		end,
	},
}

-- Returns the option to buy what params names, with its cost, and blocked when the panel greys it
-- out: the game's reasons, and the panel's text when the player can't afford it. formation is nil
-- for anything but a unit. The game gives no reason when the player can't afford an item, so the
-- panel adds one.
local function PurchaseOption(city, purchase, params, hash, formation)
	local yieldIndex = GameInfo.Yields[purchase.yield].Index
	local cityGold = city:GetGold()
	local source = purchase.source(Players[city:GetOwner()])
	local canStart, results = CityManager.CanStartCommand(city, CityCommandTypes.PURCHASE, false, params, true)
	local option, canAfford

	if formation == nil then
		option = { cost = cityGold:GetPurchaseCost(yieldIndex, hash) }
		canAfford = source:CanAfford(city:GetID(), hash)
	else
		option = { cost = cityGold:GetPurchaseCost(yieldIndex, hash, formation) }
		canAfford = source:CanAfford(city:GetID(), hash, formation)
	end

	if not canStart or not canAfford then
		option.blocked = SentientSystems_GetFailureReasons(results)

		if not canAfford then
			option.blocked[#option.blocked + 1] = Locale.Lookup(purchase.cantAffordKey)
		end
	end

	return option, results
end

-- Returns the parameters that name an item and the yield to buy it with.
local function PurchaseParams(param, hash, purchase)
	local params = {}

	params[param] = hash
	params[CityCommandTypes.PARAM_YIELD_TYPE] = GameInfo.Yields[purchase.yield].Index

	return params
end

-- Returns whether the panel lists the item that params names: when CanStartCommand allows it when
-- it only tests.
local function IsListed(city, params)
	return CityManager.CanStartCommand(city, CityCommandTypes.PURCHASE, true, params, false)
end

-- Returns the units the city can buy with the yield, each with a corps and an army when the results
-- allow one, as ComposeUnitForPurchase does.
local function GetUnitPurchases(city, purchase)
	local units = {}

	for row in GameInfo.Units() do
		local params = PurchaseParams(CityCommandTypes.PARAM_UNIT_TYPE, row.Hash, purchase)

		if purchase.triesUnit(row, city) and IsListed(city, params) then
			local option, results = PurchaseOption(city, purchase, params, row.Hash)

			option.type = row.UnitType

			for key, formation in pairs({ corps = "CORPS_MILITARY_FORMATION", army = "ARMY_MILITARY_FORMATION" }) do
				local canTrain = results ~= nil and results[CityOperationResults["CAN_TRAIN_" .. key:upper()]]

				if canTrain then
					local formationParams = PurchaseParams(CityCommandTypes.PARAM_UNIT_TYPE, row.Hash, purchase)

					formationParams[CityCommandTypes.PARAM_MILITARY_FORMATION_TYPE] = MilitaryFormationTypes[formation]
					option[key] = PurchaseOption(city, purchase, formationParams, row.Hash, MilitaryFormationTypes[formation])
				end
			end

			units[#units + 1] = option
		end
	end

	return units
end

-- Returns the buildings or districts the city can buy with the yield. tries(row) says whether the
-- panel tries a row, param is the parameter that names it, and column is its type's column.
local function GetPurchases(city, purchase, rows, param, column, tries)
	local options = {}

	for row in rows() do
		local params = PurchaseParams(param, row.Hash, purchase)

		if tries(row) and IsListed(city, params) then
			local option = PurchaseOption(city, purchase, params, row.Hash)

			option.type = row[column]
			options[#options + 1] = option
		end
	end

	return options
end

-- The text key of the tooltip on a tile the player can't afford, which takes the gold still needed.
local NEED_MORE_GOLD_KEY = "LOC_PLOTINFO_YOU_NEED_MORE_GOLD_TO_PURCHASE"

-- Returns the tiles the city can buy with gold, in plot index order, each with x, y, and cost. A
-- tile that costs more than the player's gold has blocked, with the text of the tooltip the purchase
-- lens shows on it, as its button is disabled. See ShowPurchases in PlotInfo.lua, lines 282 to 326.
local function GetTilePurchases(city)
	local gold = Players[city:GetOwner()]:GetTreasury():GetGoldBalance()
	local cityGold = city:GetGold()
	local tiles = {}

	for _, plotIndex in ipairs(SentientSystems_GetPurchasablePlots(city)) do
		local plot = Map.GetPlotByIndex(plotIndex)
		local cost = cityGold:GetPlotPurchaseCost(plotIndex)
		local tile = { x = plot:GetX(), y = plot:GetY(), cost = cost }

		if cost > gold then
			tile.blocked = { Locale.Lookup(NEED_MORE_GOLD_KEY, cost - math.floor(gold)) }
		end

		tiles[#tiles + 1] = tile
	end

	return tiles
end

-- Returns a list with what each of the player's cities can buy, by yield, in the game's order of
-- cities. The tiles to buy are under gold, the only yield that buys them.
function SentientSystems_GetPurchaseChoices(player)
	local purchases = {}

	for _, city in player:GetCities():Members() do
		local entry = { city = city:GetID(), name = Locale.Lookup(city:GetName()) }

		for _, purchase in ipairs(PURCHASE_YIELDS) do
			entry[purchase.key] = {
				units = GetUnitPurchases(city, purchase),
				buildings = GetPurchases(city, purchase, GameInfo.Buildings, CityCommandTypes.PARAM_BUILDING_TYPE, "BuildingType", function(row)
					return purchase.triesBuilding(row, city)
				end),
				districts = GetPurchases(city, purchase, GameInfo.Districts, CityCommandTypes.PARAM_DISTRICT_TYPE, "DistrictType", function()
					return true
				end),
			}
		end

		entry.gold.tiles = GetTilePurchases(city)
		purchases[#purchases + 1] = entry
	end

	return purchases
end

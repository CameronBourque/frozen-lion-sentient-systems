-- The income part of the player section: the gold, faith, science, and culture the player makes each
-- turn and where it comes from, the gold the player pays and for what, the upkeep of each kind of
-- unit, and the gold deals, as the Yields tab of Reports shows them. SentientSystemsCore_StatePlayer.lua
-- loads this file. Example: SentientSystems_GetIncomeState(player) returns a table that encodes as
-- '{"culture":{"cities":216.6,"total":216.6},"deals":[{"gold":3,"player":4,"turnsLeft":18}],
-- "expenses":{"cities":117,"deals":5,"total":210,"units":88},"faith":{"cities":109,"total":109},
-- "gold":{"cities":420,"deals":22,"envoys":33,"total":475.1},"science":{"cities":123.5,"total":123.5},
-- "unitUpkeep":[{"count":10,"gold":30,"name":"Musketman","type":"UNIT_MUSKETMAN"}]}', on one line. The
-- checks follow GetData and ViewYieldsPage in ReportScreen.lua.

-- The sources each yield's tooltip names, by the key they have in the state and the label that follows
-- the amount in the game's English text, as in "+33 from [ICON_Envoy] Envoys". The game gives no
-- numbers for them, only the tooltip text, and its text keys for the lines (LOC_PLAYER_YIELD_<YIELD>_FROM_
-- <SOURCE> in InGameText.xml) return an empty text when they are looked up, so the labels are
-- matched as the English file has them. In another language no label matches, and every amount
-- lands in other. Other is the game's own Other line.
local COMMON_SOURCES = {
	{ key = "cities", label = "Cities" },
	{ key = "beliefs", label = "Beliefs" },
	{ key = "envoys", label = "[ICON_Envoy] Envoys" },
	{ key = "suzerain", label = "city-states you are Suzerain of" },
	{ key = "other", label = "Other" },
}

-- Each yield: its key in the state and the sources it has besides the common ones. Culture's and
-- science's alliance lines are percentages, so they are left out.
local YIELDS = {
	{
		key = "gold",
		extra = {
			{ key = "deals", label = "Deals" },
			{ key = "interest", label = "interest on treasury (up to 1000)" },
			{ key = "nationalParks", label = "National Parks" },
		},
	},
	{
		key = "faith",
		extra = {
			{ key = "founders", label = "peaceful religion founders" },
			{ key = "alliances", label = "Religious Alliances" },
			{ key = "greatPeople", label = "excess [ICON_GREATPERSON] Great Person points" },
		},
	},
	{ key = "science", extra = {} },
	{ key = "culture", extra = {} },
}

-- A source or total below this is left out, as the lines of a tooltip are rounded to a tenth.
local MIN_REMAINDER = 0.5

-- Rounds a number to the nearest tenth, as the top bar's number format does.
local function RoundNearest(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Escapes the characters of a text that a pattern reads as magic.
local function Escape(text)
	return (text:gsub("%p", "%%%0"))
end

-- Returns the lines of a tooltip, which the game separates with [NEWLINE].
local function GetLines(tooltip)
	local lines, start = {}, 1

	while true do
		local first, last = tooltip:find("[NEWLINE]", start, true)

		if first == nil then
			lines[#lines + 1] = tooltip:sub(start)

			return lines
		end

		lines[#lines + 1] = tooltip:sub(start, first - 1)
		start = last + 1
	end
end

-- Returns the amount that one of the tooltip's lines gives for a label, or nil without one.
local function ReadSource(lines, label)
	local pattern = "^([%+%-]?[%d%.,]+) from " .. Escape(label) .. "$"

	for _, line in ipairs(lines) do
		local text = line:match(pattern)

		if text ~= nil then
			return tonumber((text:gsub(",", "")))
		end
	end

	return nil
end

-- Returns one yield's total and its sources, each left out while it is 0. What the lines don't give
-- is added to other, when it is at least half a point. See GetGoldTooltip in
-- ToolTipHelper_PlayerYields.lua.
local function GetYield(yield, total, tooltip)
	local lines = GetLines(tooltip)
	local result = { total = RoundNearest(total) }
	local found = 0

	for _, list in ipairs({ COMMON_SOURCES, yield.extra }) do
		for _, source in ipairs(list) do
			local amount = ReadSource(lines, source.label)

			if amount ~= nil and amount ~= 0 then
				result[source.key] = amount
				found = found + amount
			end
		end
	end

	local remainder = total - found

	if math.abs(remainder) >= MIN_REMAINDER then
		result.other = RoundNearest((result.other or 0) + remainder)
	end

	return result
end

-- Each yield a city makes, by its key in the state and its type, in the order the report lists them.
local CITY_YIELDS = {
	{ key = "food", type = "YIELD_FOOD" },
	{ key = "production", type = "YIELD_PRODUCTION" },
	{ key = "gold", type = "YIELD_GOLD" },
	{ key = "science", type = "YIELD_SCIENCE" },
	{ key = "culture", type = "YIELD_CULTURE" },
	{ key = "faith", type = "YIELD_FAITH" },
}

-- Returns the yields a source gives, each rounded to a tenth and left out while 0, or nil when it
-- gives none. read is called with each yield's type, and returns its amount.
local function CollectYields(read)
	local yields, found = {}, false

	for _, yield in ipairs(CITY_YIELDS) do
		local amount = RoundNearest(read(yield.type))

		if amount ~= 0 then
			yields[yield.key] = amount
			found = true
		end
	end

	return found and yields or nil
end

-- Adds a row to a city's sources unless it gives no yield and costs no upkeep. A row has kind, name,
-- type, left out for a row that isn't a district, a building, a wonder, or a great work, yields, and
-- upkeep.
local function AddSource(sources, row)
	if row.yields ~= nil or row.upkeep ~= nil then
		sources[#sources + 1] = row
	end
end

-- Returns a function that reads the amount of a yield type from a table of amounts, 0 for a missing one.
local function Reader(amounts)
	return function(yieldType)
		return amounts[yieldType] or 0
	end
end

-- Returns the gold a district or building costs each turn, which is its row's Maintenance while it
-- isn't pillaged, or nil for none. The game's own call for a building's cost returns 0 for every
-- building, so the report leaves them out, and the top bar's tooltip counts the row's cost.
local function GetUpkeep(cost, pillaged)
	return cost > 0 and not pillaged and cost or nil
end

-- Returns the rows for the great works in a building, each with the yields its row gives. See
-- GetGreatWorksForCity in Civ6Common.lua, lines 631 to 661.
local function GetGreatWorkRows(buildings, index)
	local rows = {}

	for slot = 0, buildings:GetNumGreatWorkSlots(index) - 1 do
		local work = buildings:GetGreatWorkInSlot(index, slot)

		if work ~= -1 then
			local row = GameInfo.GreatWorks[buildings:GetGreatWorkTypeFromIndex(work)]
			local amounts = {}

			for change in GameInfo.GreatWork_YieldChanges() do
				if change.GreatWorkType == row.GreatWorkType then
					amounts[change.YieldType] = change.YieldChange
				end
			end

			rows[#rows + 1] = { kind = "greatWork", name = Locale.Lookup(row.Name), type = row.GreatWorkType, yields = CollectYields(Reader(amounts)) }
		end
	end

	return rows
end

-- Adds the rows of the buildings on a district's plot to sources, and the rows of its wonders to
-- wonders, and returns the upkeep of the buildings. A wonder sits in a district of its own, which the
-- report leaves out, and its rows follow the districts'. See GetCityData in CitySupport.lua, lines
-- 687 to 755.
local function AddBuildingRows(city, plotIndex, sources, wonders)
	local buildings = city:GetBuildings()
	local upkeep = 0

	for _, index in ipairs(buildings:GetBuildingsAtLocation(plotIndex)) do
		if buildings:HasBuilding(index) then
			local row = GameInfo.Buildings[index]
			local cost = GetUpkeep(row.Maintenance, buildings:IsPillaged(index))
			local target = row.IsWonder and wonders or sources

			AddSource(target, {
				kind = row.IsWonder and "wonder" or "building",
				name = Locale.Lookup(row.Name),
				type = row.BuildingType,
				yields = CollectYields(function(yieldType)
					return city:GetBuildingYield(index, yieldType)
				end),
				upkeep = cost,
			})

			for _, work in ipairs(GetGreatWorkRows(buildings, index)) do
				AddSource(target, work)
			end

			upkeep = upkeep + (cost or 0)
		end
	end

	return upkeep
end

-- Adds the rows of the city's districts, with their adjacency bonuses and buildings, to sources, and
-- the rows of its wonders to wonders, and returns the upkeep of them all.
local function AddDistrictRows(city, sources, wonders)
	local upkeep = 0

	for _, district in city:GetDistricts():Members() do
		local row = GameInfo.Districts[district:GetType()]
		local cost = GetUpkeep(row.Maintenance, not district:IsComplete() or district:IsPillaged())

		if row.DistrictType ~= "DISTRICT_WONDER" then
			AddSource(sources, {
				kind = "district",
				name = Locale.Lookup(row.Name),
				type = row.DistrictType,
				yields = CollectYields(function(yieldType)
					return district:GetYield(GameInfo.Yields[yieldType].Index)
				end),
				upkeep = cost,
			})
			AddSource(sources, {
				kind = "adjacency",
				name = Locale.Lookup("LOC_HUD_REPORTS_ADJACENCY_BONUS"),
				yields = CollectYields(function(yieldType)
					return district:GetAdjacencyYield(GameInfo.Yields[yieldType].Index)
				end),
			})
		end

		upkeep = upkeep + (cost or 0)
			+ AddBuildingRows(city, Map.GetPlot(district:GetX(), district:GetY()):GetIndex(), sources, wonders)
	end

	return upkeep
end

-- Adds a row for each trade route the city sends out, with what it gives the city. See ViewYieldsPage
-- in ReportScreen.lua, lines 941 to 974.
local function AddRouteRows(city, sources)
	for _, route in ipairs(city:GetTrade():GetOutgoingRoutes()) do
		local amounts = {}

		for _, yield in ipairs(route.OriginYields or {}) do
			amounts[GameInfo.Yields[yield.YieldIndex].YieldType] = yield.Amount
		end

		local destination = Players[route.DestinationCityPlayer]:GetCities():FindID(route.DestinationCityID)

		AddSource(sources, {
			kind = "route",
			name = Locale.Lookup(destination:GetName()),
			city = { owner = route.DestinationCityPlayer, id = route.DestinationCityID },
			yields = CollectYields(Reader(amounts)),
		})
	end
end

-- Returns what the city's worked tiles give by yield type, and the tourism of its tiles. See
-- GetWorkedTileYieldData in ReportScreen.lua, lines 567 to 598.
local function GetTileYields(player, city)
	local amounts, tourism = {}, 0
	local citizens = city:GetCitizens()
	local culture = player:GetCulture()

	for _, plotID in ipairs(Map.GetCityPlots():GetPurchasedPlots(city)) do
		local plot = Map.GetPlotByIndex(plotID)

		tourism = tourism + culture:GetTourismAt(plotID)

		if citizens:IsPlotWorked(plot:GetX(), plot:GetY()) then
			for _, yield in ipairs(CITY_YIELDS) do
				amounts[yield.type] = (amounts[yield.type] or 0) + plot:GetYield(GameInfo.Yields[yield.type].Index)
			end
		end
	end

	return amounts, tourism
end

-- The happiness status that gives no yield, which is content.
local CONTENT = 4

-- Adds the rows for the city's worked tiles, its amenities, and its population, and returns the
-- tourism of its tiles. While the city isn't content, its amenities give a tenth of the worked tiles'
-- yields but food, scaled by the city's modifier. The population gives culture. See ViewYieldsPage in
-- ReportScreen.lua, lines 976 to 1008.
local function AddTileRows(player, city, sources)
	local amounts, tourism = GetTileYields(player, city)
	local growth = city:GetGrowth()

	AddSource(sources, { kind = "tiles", name = Locale.Lookup("LOC_HUD_REPORTS_WORKED_TILES"), yields = CollectYields(Reader(amounts)) })

	if growth:GetHappiness() ~= CONTENT then
		local percent = math.floor((1 + growth:GetHappinessNonFoodYieldModifier() / 100) * 100 + 0.5) / 100 * 0.1

		AddSource(sources, {
			kind = "amenities",
			name = Locale.Lookup("LOC_HUD_REPORTS_HEADER_AMENITIES"),
			yields = CollectYields(function(yieldType)
				return yieldType ~= "YIELD_FOOD" and (amounts[yieldType] or 0) * percent or 0
			end),
		})
	end

	AddSource(sources, {
		kind = "population",
		name = Locale.Lookup("LOC_HUD_CITY_POPULATION"),
		yields = CollectYields(function(yieldType)
			return yieldType == "YIELD_CULTURE" and city:GetPopulation() * GameInfo.GlobalParameters.CULTURE_PERCENTAGE_YIELD_PER_POP.Value / 100 or 0
		end),
	})

	return tourism
end

-- Returns each of the player's cities with the tourism its tiles give, the gold its districts and
-- buildings cost, and its sources, in the order of the report's city table, and the cost of all of
-- them. A city's other yields are in cities[].yields.
local function GetCityIncomes(player)
	local list, total = {}, 0

	for _, city in player:GetCities():Members() do
		local sources, wonders = {}, {}
		local upkeep = AddDistrictRows(city, sources, wonders)

		for _, wonder in ipairs(wonders) do
			sources[#sources + 1] = wonder
		end

		AddRouteRows(city, sources)

		list[#list + 1] = {
			city = { owner = player:GetID(), id = city:GetID() },
			tourism = RoundNearest(AddTileRows(player, city, sources)),
			upkeep = upkeep,
			sources = sources,
		}
		total = total + upkeep
	end

	return list, total
end

-- Returns the gold one unit costs each turn, less the player's discount, by its formation, as GetData
-- in ReportScreen.lua, lines 305 to 353, finds it. A unit that costs nothing after the discount is 0.
local function GetUnitCost(unit, discount)
	local row = GameInfo.Units[unit:GetUnitType()]
	local formation = unit:GetMilitaryFormation()
	local cost

	if formation == MilitaryFormationTypes.CORPS_MILITARY_FORMATION then
		cost = UnitManager.GetUnitCorpsMaintenance(row.Hash)
	elseif formation == MilitaryFormationTypes.ARMY_MILITARY_FORMATION then
		cost = UnitManager.GetUnitArmyMaintenance(row.Hash)
	else
		cost = UnitManager.GetUnitMaintenance(row.Hash)
	end

	return math.max(cost > 0 and cost - discount or 0, 0)
end

-- Returns the formation's name in the state, left out for a single unit.
local function GetFormationName(formation)
	if formation == MilitaryFormationTypes.CORPS_MILITARY_FORMATION then
		return "CORPS"
	elseif formation == MilitaryFormationTypes.ARMY_MILITARY_FORMATION then
		return "ARMY"
	end

	return nil
end

-- Returns the units that cost gold, grouped by type and formation, each with type, formation, name,
-- count, and gold, the gold they cost together, and their total. The report's own order is
-- arbitrary, so the groups are sorted by type and formation.
local function GetUnitUpkeep(player, discount)
	local groups, order, total = {}, {}, 0

	for _, unit in player:GetUnits():Members() do
		local cost = GetUnitCost(unit, discount)

		if cost > 0 then
			local row = GameInfo.Units[unit:GetUnitType()]
			local formation = GetFormationName(unit:GetMilitaryFormation())
			local key = row.UnitType .. (formation or "")

			if groups[key] == nil then
				groups[key] = { type = row.UnitType, formation = formation, name = Locale.Lookup(row.Name), count = 0, gold = 0 }
				order[#order + 1] = key
			end

			groups[key].count = groups[key].count + 1
			groups[key].gold = groups[key].gold + cost
			total = total + cost
		end
	end

	table.sort(order)

	local list = {}

	for i, key in ipairs(order) do
		list[i] = groups[key]
	end

	return list, total
end

-- Returns the gold deals the player is in, each with player, the other player's ID, turnsLeft, and
-- gold, which is negative for gold the player pays, and the gold the player pays in all. A deal item
-- with no duration is left out. See GetData in ReportScreen.lua, lines 355 to 460.
local function GetDeals(playerID)
	local list, paid = {}, 0
	local turn = Game.GetCurrentGameTurn()

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local otherID = other:GetID()

		if otherID ~= playerID then
			for _, deal in ipairs(DealManager.GetPlayerDeals(playerID, otherID) or {}) do
				for _, side in ipairs({ { owner = playerID, sign = -1 }, { owner = otherID, sign = 1 } }) do
					for _, item in ipairs(deal:FindItemsByType(DealItemTypes.GOLD, DealItemSubTypes.NONE, side.owner) or {}) do
						local duration = item:GetDuration()

						if duration ~= 0 then
							local gold = side.sign * item:GetAmount()

							list[#list + 1] = { player = otherID, turnsLeft = duration - (turn - item:GetEnactedTurn()), gold = gold }

							if gold < 0 then
								paid = paid - gold
							end
						end
					end
				end
			end
		end
	end

	return list, paid
end

-- Returns the gold the player pays each turn: total, as the top bar has it, and cities, the upkeep of
-- districts and buildings, units, and deals. What those don't cover is other, when it is at least
-- half a point.
local function GetExpenses(treasury, units, deals, cities)
	local total = treasury:GetTotalMaintenance()
	local expenses = { total = total, cities = cities, units = units, deals = deals }
	local remainder = total - cities - units - deals

	if math.abs(remainder) >= MIN_REMAINDER then
		expenses.other = RoundNearest(remainder)
	end

	return expenses
end

-- Returns the income section: gold, faith, science, and culture, each with its total per turn and its
-- sources, expenses, unitUpkeep, and deals. Gold's total is the income before the upkeep, which the
-- top bar's gold takes off.
function SentientSystems_GetIncomeState(player)
	local treasury = player:GetTreasury()
	local totals = {
		gold = treasury:GetGoldYield(),
		faith = player:GetReligion():GetFaithYield(),
		science = player:GetTechs():GetScienceYield(),
		culture = player:GetCulture():GetCultureYield(),
	}
	local tooltips = {
		gold = treasury:GetGoldYieldToolTip(),
		faith = player:GetReligion():GetFaithYieldToolTip(),
		science = player:GetTechs():GetScienceYieldToolTip(),
		culture = player:GetCulture():GetCultureYieldToolTip(),
	}
	local income = {}

	for _, yield in ipairs(YIELDS) do
		income[yield.key] = GetYield(yield, totals[yield.key], tooltips[yield.key])
	end

	local unitUpkeep, unitTotal = GetUnitUpkeep(player, treasury:GetMaintDiscountPerUnit())
	local deals, paid = GetDeals(player:GetID())

	local cities, cityUpkeep = GetCityIncomes(player)

	income.cities = cities
	income.expenses = GetExpenses(treasury, unitTotal, paid, cityUpkeep)
	income.unitUpkeep = unitUpkeep
	income.deals = deals

	return income
end

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

-- Returns the gold that districts and buildings cost each turn: each built district that isn't
-- pillaged, and each building in them that isn't. The game's own maintenance call for a building
-- returns 0 for them all, so the report leaves them out, and the cost is the row's Maintenance, as
-- the top bar's tooltip counts it. See BuildingsAndDistricts in CitySupport.lua, lines 627 to 761.
local function GetCityUpkeep(player)
	local total = 0

	for _, city in player:GetCities():Members() do
		local buildings = city:GetBuildings()

		for _, district in city:GetDistricts():Members() do
			if district:IsComplete() and not district:IsPillaged() then
				total = total + GameInfo.Districts[district:GetType()].Maintenance
			end

			local plotIndex = Map.GetPlot(district:GetX(), district:GetY()):GetIndex()

			for _, index in ipairs(buildings:GetBuildingsAtLocation(plotIndex)) do
				if buildings:HasBuilding(index) and not buildings:IsPillaged(index) then
					total = total + GameInfo.Buildings[index].Maintenance
				end
			end
		end
	end

	return total
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

	income.expenses = GetExpenses(treasury, unitTotal, paid, GetCityUpkeep(player))
	income.unitUpkeep = unitUpkeep
	income.deals = deals

	return income
end

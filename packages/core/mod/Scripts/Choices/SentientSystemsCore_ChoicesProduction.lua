-- The production choice: what each of the player's cities can produce, as the production panel
-- lists it. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetProductionChoices(player) returns a list with one table for each city, which
-- encodes as '{"city":65536,"name":"Rome","units":[{"cost":40,"turns":6,"type":"UNIT_SETTLER"}]}',
-- on one line. The checks follow GetData in ProductionPanel.lua, lines 2113 to 2202.

-- Returns the game's reasons from a CanProduce result, as text. The game gives each reason as text
-- already, and the panel passes it through Locale.Lookup, as this does.
local function FailureReasons(results)
	local reasons = {}

	for i, reason in ipairs(results and results[CityCommandResults.FAILURE_REASONS] or {}) do
		reasons[i] = Locale.Lookup(reason)
	end

	return reasons
end

-- Sets option.blocked to the game's reasons when the city can't produce what params names now, as
-- the panel greys it out. Returns the CanProduce results.
local function CheckBlocked(buildQueue, params, option)
	local canProduce, results = buildQueue:CanProduce(params, false, true)

	if not canProduce then
		option.blocked = FailureReasons(results)
	end

	return results
end

-- Returns the option to train a unit as a corps or an army, with its cost.
local function FormationOption(buildQueue, row, formation, cost)
	local option = { cost = cost, turns = buildQueue:GetTurnsLeft(row.Hash, formation) }

	CheckBlocked(buildQueue, { UnitType = row.Hash, MilitaryFormationType = formation }, option)

	return option
end

-- Returns the units the city's production panel lists. The panel lists each unit whose MustPurchase
-- is false and that CanProduce allows when it only tests. It greys out a listed unit that CanProduce
-- refuses with results, and offers a corps or an army when the results allow one.
local function GetUnitOptions(city)
	local buildQueue = city:GetBuildQueue()
	local units = {}

	for row in GameInfo.Units() do
		local params = { UnitType = row.Hash, MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION }

		if not row.MustPurchase and buildQueue:CanProduce(params, true) then
			local option = { type = row.UnitType, cost = buildQueue:GetUnitCost(row.Index), turns = buildQueue:GetTurnsLeft(row.Hash) }
			local progress = buildQueue:GetUnitProgress(row.Index)
			local results = CheckBlocked(buildQueue, params, option)

			-- The panel shows progress only once there is some.
			if progress > 0 then
				option.progress = progress
			end

			if results ~= nil and results[CityOperationResults.CAN_TRAIN_CORPS] then
				option.corps = FormationOption(buildQueue, row, MilitaryFormationTypes.CORPS_MILITARY_FORMATION, buildQueue:GetUnitCorpsCost(row.Index))
			end

			if results ~= nil and results[CityOperationResults.CAN_TRAIN_ARMY] then
				option.army = FormationOption(buildQueue, row, MilitaryFormationTypes.ARMY_MILITARY_FORMATION, buildQueue:GetUnitArmyCost(row.Index))
			end

			units[#units + 1] = option
		end
	end

	return units
end

-- Returns a list with what each of the player's cities can produce, in the game's order of cities.
function SentientSystems_GetProductionChoices(player)
	local production = {}

	for _, city in player:GetCities():Members() do
		production[#production + 1] = {
			city = city:GetID(),
			name = Locale.Lookup(city:GetName()),
			units = GetUnitOptions(city),
		}
	end

	return production
end

-- Purchases. data.purchases maps a yield name, such as YIELD_GOLD, to the units, buildings, and
-- districts the city can buy with it. Each has type, cost, blocked, hidden, which the check refuses
-- even when it only tests, and cantAfford, and a unit has corps and army, each with cost, blocked,
-- and cantAfford. Each purchase gets a GameInfo row, with a hash and the yield that buys it, which
-- is gold for a faithEnabled one. A faith purchase has faithEnabled when the game marks it for
-- another yield but the city can buy it with faith. data.options.purchasable lists tiles to buy, each with x, y, and cost,
-- its gold cost, and the player's gold and faith stores are in FakeGame/Stores.lua.

return function(env, world, ctx)
	local hashes, indexes, Formation, PlotIndex = ctx.hashes, ctx.indexes, ctx.Formation, ctx.PlotIndex
	local CITY_COMMAND_RESULTS, CITY_OPERATION_RESULTS, CITY_COMMAND_TYPES = env.CityCommandResults, env.CityOperationResults, env.CityCommandTypes
	local AddRow = ctx.AddRow

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			for yieldName, purchases in pairs(city.purchases or {}) do
				for _, kind in ipairs({ { "units", "Units", "UnitType" }, { "buildings", "Buildings", "BuildingType" }, { "districts", "Districts", "DistrictType" } }) do
					for _, option in ipairs(purchases[kind[1]] or {}) do
						AddRow(kind[2], kind[3], option.type)

						local row = env.GameInfo[kind[2]][indexes[option.type]]

						ctx.NextHash(3000000, option.type)
						row.Hash = hashes[option.type]
						row.PurchaseYield = option.faithEnabled and "YIELD_GOLD" or yieldName
						row.OnePerCity = row.OnePerCity ~= false
					end
				end
			end
		end
	end

	-- GameInfo.Yields, by name.
	local YIELD_ROWS = {}

	for name, row in pairs(env.GameInfo.Yields) do
		if type(name) == "string" then
			YIELD_ROWS[name] = row
		end
	end

	ctx.OnCity(function(city, data)

		-- Returns the purchase option for an item's hash and a yield's index, or its corps or army for a
		-- formation, or nil.
		local function PurchaseOption(yieldIndex, hash, formation)
			for name, row in pairs(YIELD_ROWS) do
				if row.Index == yieldIndex then
					for _, kind in ipairs({ "units", "buildings", "districts" }) do
						for _, option in ipairs(((data.purchases or {})[name] or {})[kind] or {}) do
							if hashes[option.type] == hash then
								return Formation(option, formation)
							end
						end
					end
				end
			end
		end

		city.PurchaseOption = PurchaseOption

		city.GetGold = function()
			return {
				GetPurchaseCost = function(_, yieldIndex, hash, formation)
					return PurchaseOption(yieldIndex, hash, formation).cost
				end,
				-- The cost of a tile to buy, from its tile in data.options.purchasable, or 0.
				GetPlotPurchaseCost = function(_, plotIndex)
					for _, tile in ipairs((data.options or {}).purchasable or {}) do
						if PlotIndex(tile.x, tile.y) == plotIndex then
							return tile.cost or 0
						end
					end

					return 0
				end,
				-- Whether the city can buy a unit or a building with faith that the game marks for
				-- another yield. The option is under YIELD_FAITH with faithEnabled.
				IsUnitFaithPurchaseEnabled = function(_, hash)
					local option = PurchaseOption(YIELD_ROWS.YIELD_FAITH.Index, hash)

					return option ~= nil and option.faithEnabled == true
				end,
				IsBuildingFaithPurchaseEnabled = function(_, hash)
					local option = PurchaseOption(YIELD_ROWS.YIELD_FAITH.Index, hash)

					return option ~= nil and option.faithEnabled == true
				end,
			}
		end
	end)

	-- With testOnly, whether the city's purchases list the item that params names. Without it,
	-- whether the city can buy it now, and the results: the reasons it can't, and for a unit,
	-- whether a corps or an army can be bought.
	env.CityManager.CanStartCommand = function(city, command, testOnly, params, withResults)
		assert(command == CITY_COMMAND_TYPES.PURCHASE, "no fake for this command")

		local hash = params[CITY_COMMAND_TYPES.PARAM_UNIT_TYPE] or params[CITY_COMMAND_TYPES.PARAM_BUILDING_TYPE] or params[CITY_COMMAND_TYPES.PARAM_DISTRICT_TYPE]
		local yieldIndex = params[CITY_COMMAND_TYPES.PARAM_YIELD_TYPE]
		local option = city.PurchaseOption(yieldIndex, hash)

		if testOnly then
			return option ~= nil and not option.hidden
		end

		assert(withResults == true, "no fake without results")

		local formationOption = city.PurchaseOption(yieldIndex, hash, params[CITY_COMMAND_TYPES.PARAM_MILITARY_FORMATION_TYPE])

		return formationOption.blocked == nil and formationOption.cantAfford ~= true, {
			[CITY_COMMAND_RESULTS.FAILURE_REASONS] = formationOption.blocked,
			[CITY_OPERATION_RESULTS.CAN_TRAIN_CORPS] = option.corps ~= nil or nil,
			[CITY_OPERATION_RESULTS.CAN_TRAIN_ARMY] = option.army ~= nil or nil,
		}
	end
end

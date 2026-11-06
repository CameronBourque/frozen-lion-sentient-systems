-- Trade routes. Fakes a trader's destinations, the trade manager's potential
-- routes, trading posts, and the international yield modifiers. CityYields.lua
-- and TopBar.lua hold a city's routes and a player's route capacity.

return function(env, world, ctx)
	local YIELD_TYPES, YIELD_NAMES = ctx.YIELD_TYPES, ctx.YIELD_NAMES

	env.UnitOperationTypes.MAKE_TRADE_ROUTE = 160
	env.UnitOperationTypes.PARAM_X0 = 161
	env.UnitOperationTypes.PARAM_Y0 = 162
	env.UnitOperationTypes.PARAM_X1 = 163
	env.UnitOperationTypes.PARAM_Y1 = 164

	for _, data in pairs(world.players or {}) do
		for _, unit in ipairs(data.units or {}) do
			if unit.trader then
				ctx.AddRow("Units", "UnitType", unit.type)
				env.GameInfo.Units[ctx.indexes[unit.type]].MakeTradeRoute = true
			end
		end
	end

	-- Returns the city of any player at x, y, or nil.
	local function CityAt(x, y)
		for id = 0, 63 do
			for _, city in (env.Players[id] and env.Players[id]:GetCities() or ctx.List({})):Members() do
				if city:GetX() == x and city:GetY() == y then
					return city
				end
			end
		end
	end

	env.Cities.GetCityInPlot = CityAt

	-- Returns whether the unit can start a route to the city.
	local function CanReach(unit, city)
		for _, target in ipairs(unit.tradeTo) do
			if target.player == city:GetOwner() and target.id == city:GetID() then
				return true
			end
		end

		return false
	end

	local canStartOperation = env.UnitManager.CanStartOperation

	env.UnitManager.CanStartOperation = function(unit, operation, target, parameters, ...)
		if operation ~= env.UnitOperationTypes.MAKE_TRADE_ROUTE then
			return canStartOperation(unit, operation, target, parameters, ...)
		end

		return CanReach(unit, CityAt(parameters[env.UnitOperationTypes.PARAM_X0], parameters[env.UnitOperationTypes.PARAM_Y0]))
	end

	-- Returns the potential route between two cities, or an empty one.
	local function Route(originOwner, originID, destinationOwner, destinationID)
		for _, route in ipairs(world.routes or {}) do
			if route.from[1] == originOwner and route.from[2] == originID and route.to[1] == destinationOwner and route.to[2] == destinationID then
				return route
			end
		end

		return {}
	end

	-- Returns the yields of one part of an end of a route, the six yields in
	-- index order.
	local function Yields(route, side, part)
		local named = ((route[side] or {})[part]) or {}
		local yields = {}

		for index = 0, #YIELD_NAMES do
			yields[index + 1] = named[YIELD_NAMES[index]] or 0
		end

		return yields
	end

	env.Game.GetTradeManager = function()
		local manager = {
			GetTradeRoutePath = function(_, ...)
				local plots = {}

				for i = 1, Route(...).path or 0 do
					plots[i] = i
				end

				return plots
			end,
		}

		for _, side in ipairs({ "Origin", "Destination" }) do
			local key = side:lower()

			for call, part in pairs({ PotentialRoute = "route", Path = "path", Modifiers = "modifiers" }) do
				manager["Calculate" .. side .. "YieldsFrom" .. call] = function(_, ...)
					return Yields(Route(...), key, part)
				end
			end

			manager["Calculate" .. side .. "ReligiousPressureFromPotentialRoute"] = function(_, ...)
				return ((Route(...)[key] or {}).pressure) or 0
			end
		end

		return manager
	end

	ctx.OnUnit(function(unit, data)
		unit.tradeTo = data.tradeTo or {}

		function unit.GetName()
			return data.name or "LOC_UNIT_TRADER_NAME"
		end
	end)

	ctx.OnCity(function(city, data)
		local getTrade = city.GetTrade

		function city.GetTrade()
			local trade = getTrade()

			function trade.HasActiveTradingPost(_, playerID)
				for _, id in ipairs(data.tradingPosts or {}) do
					if id == playerID then
						return true
					end
				end

				return false
			end

			return trade
		end
	end)

	ctx.OnPlayer(function(player, data)
		local getTrade = player.GetTrade

		function player.GetTrade()
			local trade = getTrade()

			function trade.GetInternationalYieldModifier(_, yieldIndex)
				for name, index in pairs(YIELD_TYPES) do
					if index == yieldIndex then
						return ((data.trade or {}).multipliers or {})[name] or 1
					end
				end
			end

			return trade
		end
	end)
end

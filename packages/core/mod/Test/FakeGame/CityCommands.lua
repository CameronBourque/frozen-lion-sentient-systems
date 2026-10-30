-- The city commands. CityCommandResults and CityOperationResults hold the result keys of a CanProduce
-- check, of which FAILURE_REASONS has the game's number. CityOperationTypes and CityCommandTypes hold
-- the values that ask for placement tiles, tiles to buy, and purchases. CityManager.GetCity finds the
-- city that a component ID, such as a holy city's, names. FakeGame/Production.lua, Purchases.lua, and
-- Placement.lua use these and add to CityManager.

return function(env, world, ctx)
	env.CityCommandResults = { FAILURE_REASONS = -2028665063, PLOTS = 2001 }
	env.CityOperationResults = { CAN_TRAIN_CORPS = 1001, CAN_TRAIN_ARMY = 1002, NO_SUITABLE_LOCATION = 1003, PLOTS = 1004 }
	env.CityOperationTypes = { BUILD = 3001, PARAM_DISTRICT_TYPE = 3002, PARAM_BUILDING_TYPE = 3003 }
	env.CityCommandTypes = {
		PURCHASE = 4001,
		PARAM_PLOT_PURCHASE = 4002,
		PARAM_UNIT_TYPE = 4003,
		PARAM_BUILDING_TYPE = 4004,
		PARAM_DISTRICT_TYPE = 4005,
		PARAM_YIELD_TYPE = 4006,
		PARAM_MILITARY_FORMATION_TYPE = 4007,
	}
	env.CityManager = {
		GetCity = function(componentID)
			local player = env.Players[componentID.player]

			return player and player:GetCities():FindID(componentID.id)
		end,
	}
end

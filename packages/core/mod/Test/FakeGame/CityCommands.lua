-- The city commands. Fakes the result and type tables that the build,
-- placement, and purchase checks use. FakeGame/Production.lua, Purchases.lua,
-- and Placement.lua build on them.

return function(env, world, ctx)
	env.CityCommandResults = { FAILURE_REASONS = -2028665063, PLOTS = 2001 }
	env.CityOperationResults = { CAN_TRAIN_CORPS = 1001, CAN_TRAIN_ARMY = 1002, NO_SUITABLE_LOCATION = 1003, PLOTS = 1004 }
	env.CityOperationTypes = {
		BUILD = 3001,
		PARAM_DISTRICT_TYPE = 3002,
		PARAM_BUILDING_TYPE = 3003,
		PARAM_UNIT_TYPE = 3004,
		PARAM_PROJECT_TYPE = 3005,
		PARAM_INSERT_MODE = 3006,
		PARAM_QUEUE_DESTINATION_LOCATION = 3007,
		VALUE_REPLACE_AT = 3008,
		VALUE_APPEND = 3009,
	}
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

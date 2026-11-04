-- The game's switches and parameters. Fakes GameCapabilities and the
-- GlobalParameters that the core mod reads.

return function(env, world, ctx)
	env.GameCapabilities = {
		HasCapability = function(capability)
			return (capability == "CAPABILITY_GOVERNMENTS_LEGACY_BONUSES" and world.legacyBonuses == true)
				or (capability == "CAPABILITY_RENAME" and world.rename == true)
				or (capability == "CAPABILITY_DRAMATICAGES" and world.dramaticAges == true)
				or (capability:find("^CAPABILITY_GREAT_PEOPLE_") ~= nil and not (world.offCapabilities or {})[capability])
		end,
	}
	env.GlobalParameters = {
		GOVERNMENT_UNLOCK_WITH_FAITH = world.unlockWithFaith and 1 or 0,
		FAVOR_FOR_LIBERATE_PLAYER_CITY = 100,
		FAVOR_FOR_LIBERATE_CITY_STATE = 50,
		FAVOR_FOR_REVIVE_PLAYER = 20,
		WARMONGER_FINAL_MAJOR_CITY_MULTIPLIER = 200,
		NEXT_ERA_TURN_COUNTDOWN = 10,
	}
	env.PlayerOperationResults = { FAILURE_REASONS = 9001 }
	env.GameInfo.GlobalParameters = { CULTURE_PERCENTAGE_YIELD_PER_POP = { Value = 30 } }
end

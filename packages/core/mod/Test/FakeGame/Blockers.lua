-- End-turn blockers. Fakes a player's blockers, in the game's order. Another
-- feature adds blocker types with ctx.AddBlockerType, so it must be registered
-- after this one.

-- Some EndTurnBlockingTypes values, with their hashes from the game.
local END_TURN_BLOCKING_TYPES = {
	NO_ENDTURN_BLOCKING = 0,
	ENDTURN_BLOCKING_UNITS = 23669119,
	ENDTURN_BLOCKING_RESEARCH = -286188551,
	ENDTURN_BLOCKING_CIVIC = -2034242607,
	ENDTURN_BLOCKING_PRODUCTION = -513644209,
	ENDTURN_BLOCKING_FILL_CIVIC_SLOT = -1610199318,
	ENDTURN_BLOCKING_UNIT_PROMOTION = 1706768628,
	ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE = 1385632321,
	ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY = 2048525187,
	ENDTURN_BLOCKING_ARTIFACT = -234935529,
}

return function(env, world, ctx)
	-- Each Install gets its own copy, so a type added in one doesn't stay in
	-- the next.
	local types = {}

	for name, hash in pairs(END_TURN_BLOCKING_TYPES) do
		types[name] = hash
	end

	env.EndTurnBlockingTypes = types

	ctx.AddBlockerType = function(name, hash)
		types[name] = hash
	end

	env.NotificationManager = {
		GetAllEndTurnBlocking = function(playerID)
			local values = {}

			for i, blocker in ipairs((world.players or {})[playerID].blockers or {}) do
				values[i] = types[blocker] or blocker
			end

			return values
		end,
	}
end

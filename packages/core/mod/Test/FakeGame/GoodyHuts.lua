-- Tribal villages. Fakes the reward sub-types from world.goodyHutSubTypes, and
-- DB.MakeHash, which the game uses for a sub-type's hash.

return function(env, world, ctx)
	env.GameInfo.GoodyHutSubTypes = ctx.Callable(world.goodyHutSubTypes or {})
	env.DB = env.DB or {}
	env.DB.MakeHash = function(name)
		return "hash of " .. name
	end
end

-- Rivals. A player's met lists the IDs of the players it has met, which HasMet checks. The ones it
-- is at war with, atWar, are in FakeGame/Envoys.lua. Other features add to GetDiplomacy.

return function(env, world, ctx)
	ctx.OnPlayer(function(player, data)
		function player.GetDiplomacy()
			return {
				HasMet = function(_, otherID)
					for _, met in ipairs(data.met or {}) do
						if met == otherID then
							return true
						end
					end

					return false
				end,
			}
		end
	end)
end

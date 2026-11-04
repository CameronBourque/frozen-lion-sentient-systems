-- Rivals. Fakes the players that a player has met. Other features add to
-- GetDiplomacy.

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

-- Artifacts. A player's archaeologist is its next digging archaeologist, with id, name, x, y, and
-- artifact, with index, type, the site's kind from 0 to 5, acting and target, player IDs, and era.

return function(env, world, ctx)
	local AddRow, indexes = ctx.AddRow, ctx.indexes


	-- Each artifact's era gets a row.
	for _, data in pairs(world.players or {}) do
		if data.archaeologist ~= nil then
			AddRow("Eras", "EraType", data.archaeologist.artifact.era)
		end
	end

	-- The next digging archaeologist, from data.archaeologist.
	ctx.OnPlayer(function(player, data)
		local GetUnits = player.GetUnits

		function player.GetUnits()
			local list = GetUnits()

			function list.GetNextExtractingArchaeologist()
				local archaeologist = data.archaeologist

				return archaeologist and {
					GetID = function()
						return archaeologist.id
					end,
					GetName = function()
						return archaeologist.name
					end,
					GetX = function()
						return archaeologist.x
					end,
					GetY = function()
						return archaeologist.y
					end,
					GetArchaeology = function()
						return {
							GetArtifactIndex = function()
								return archaeologist.artifact.index
							end,
						}
					end,
				}
			end

			return list
		end
	end)


	-- The artifact of each digging archaeologist, by its index, with the site's type, the acting and
	-- target players, and the acting player's era, by its GameInfo index.
	env.Game.GetArtifactByIndex = function(index)
		for _, data in pairs(world.players or {}) do
			local artifact = data.archaeologist and data.archaeologist.artifact

			if artifact ~= nil and artifact.index == index then
				return { Type = artifact.type, ActingPlayerID = artifact.acting, TargetPlayerID = artifact.target or -1, ActingPlayerEra = indexes[artifact.era] }
			end
		end
	end
end

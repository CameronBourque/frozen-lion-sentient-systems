-- The game's eras. world.era is the era, with type, final, countdown, which is -1 when missing,
-- minEnd, and maxEnd. A player's era has score, age, heroic, golden, dark, or normal, dark and
-- golden, the score's thresholds, previous and current, the score's sources, each a table of its
-- text to its points, and commemorations, the active dedications' category names, such as
-- "ECONOMIC". Without world.era, as in a game without Rise and Fall, there are none of the era's
-- calls. A player's era.loyalty is its civilian loyalty. The ChronologyIndex rows of GameInfo.Eras are in FakeGame.lua. See FakeGame/Dedications.lua
-- for the era change.

return function(env, world, ctx)
	local indexes = ctx.indexes

	env.GameInfo.CommemorationTypes = {}
	ctx.AddBlockerType("ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE", 1215684001)

	-- The era and each player's active dedications get rows, with the text keys of the game's moments.
	if world.era then
		ctx.AddRow("Eras", "EraType", world.era.type)
		env.GameInfo.Eras[indexes[world.era.type]].Name = "LOC_" .. world.era.type .. "_NAME"
	end

	for _, data in pairs(world.players or {}) do
		for _, category in ipairs((data.era or {}).commemorations or {}) do
			local type = "COMMEMORATION_" .. category

			ctx.AddRow("CommemorationTypes", "CommemorationType", type)

			local row = env.GameInfo.CommemorationTypes[indexes[type]]
			local key = "LOC_MOMENT_CATEGORY_" .. category

			row.GoldenAgeBonusDescription = key .. "_BONUS_GOLDEN_AGE"
			row.NormalAgeBonusDescription = key .. "_BONUS_NORMAL_AGE"
			row.DarkAgeBonusDescription = key .. "_BONUS_DARK_AGE"
		end
	end

	-- A player's age, from its era.age.
	local function AgeOf(id)
		local era = ((world.players or {})[id] or {}).era

		return era and era.age
	end

	env.Game.GetEras = function()
		local eras = {
			GetCurrentEra = function()
				return world.era and indexes[world.era.type]
			end,
			HasHeroicGoldenAge = function(_, id)
				return AgeOf(id) == "heroic"
			end,
			HasGoldenAge = function(_, id)
				return AgeOf(id) == "heroic" or AgeOf(id) == "golden"
			end,
			HasDarkAge = function(_, id)
				return AgeOf(id) == "dark"
			end,
		}

		if world.era then
			local function Era(id)
				return world.players[id].era or {}
			end

			eras.GetFinalEra = function()
				return world.era.final and indexes[world.era.type] or -1
			end
			eras.GetPlayerCurrentScore = function(_, id)
				return Era(id).score or 0
			end
			eras.GetPlayerDarkAgeThreshold = function(_, id)
				return Era(id).dark or 0
			end
			eras.GetPlayerGoldenAgeThreshold = function(_, id)
				return Era(id).golden or 0
			end
			eras.GetPlayerPreviousEraScoreBreakdown = function(_, id)
				return Era(id).previous or {}
			end
			eras.GetPlayerCurrentEraScoreBreakdown = function(_, id)
				return Era(id).current or {}
			end
			eras.GetNextEraCountdown = function()
				return world.era.countdown or -1
			end
			eras.GetCurrentEraMinimumEndTurn = function()
				return world.era.minEnd
			end
			eras.GetCurrentEraMaximumEndTurn = function()
				return world.era.maxEnd
			end
			eras.GetPlayerActiveCommemorations = function(_, id)
				local active = {}

				for i, category in ipairs(Era(id).commemorations or {}) do
					active[i] = indexes["COMMEMORATION_" .. category]
				end

				return active
			end
		end

		return eras
	end

	-- The loyalty pressure each of the player's citizens exerts, from data.era.loyalty.
	ctx.OnPlayer(function(player, data)
		function player.GetCivilianLoyalty()
			return (data.era or {}).loyalty or 0
		end
	end)
end

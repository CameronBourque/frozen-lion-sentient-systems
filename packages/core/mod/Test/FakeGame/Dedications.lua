-- The era change. A player's dedications is the era change it is making them for, with era, an era
-- type, age, heroic, golden, dark, or normal, allowed, the picks it needs, alwaysNormal, true for a
-- player always allowed the normal bonus too, and options, the category names, such as
-- "SCIENTIFIC", which give each its row in GameInfo.CommemorationTypes, with the keys
-- LOC_MOMENT_CATEGORY_<name>, with _BONUS_GOLDEN_AGE, _BONUS_NORMAL_AGE, and _BONUS_DARK_AGE. The
-- ages are the same for every player here, as the tests use one. Registered after Eras, it adds to
-- Eras' Game.GetEras.

return function(env, world, ctx)
	local indexes = ctx.indexes

	-- Each dedication's era and options get rows, with the text keys of the game's moments.
	for _, data in pairs(world.players or {}) do
		if data.dedications ~= nil then
			ctx.AddRow("Eras", "EraType", data.dedications.era)
			env.GameInfo.Eras[indexes[data.dedications.era]].Name = "LOC_" .. data.dedications.era .. "_NAME"

			for _, category in ipairs(data.dedications.options or {}) do
				local type = "COMMEMORATION_" .. category

				ctx.AddRow("CommemorationTypes", "CommemorationType", type)

				local row = env.GameInfo.CommemorationTypes[indexes[type]]
				local key = "LOC_MOMENT_CATEGORY_" .. category

				row.CategoryDescription = key
				row.GoldenAgeBonusDescription = key .. "_BONUS_GOLDEN_AGE"
				row.NormalAgeBonusDescription = key .. "_BONUS_NORMAL_AGE"
				row.DarkAgeBonusDescription = key .. "_BONUS_DARK_AGE"
			end
		end
	end

	-- The era change of the first player with dedications, from its data.dedications.
	local GetEras = env.Game.GetEras

	env.Game.GetEras = function()
		local eras = GetEras()
		local data

		for _, playerData in pairs(world.players or {}) do
			data = data or playerData.dedications
		end

		data = data or {}

		-- A player's age, from its era.age, or the dedications' age.
		local function AgeOf(id)
			local era = ((world.players or {})[id] or {}).era

			return era and era.age or data.age
		end

		eras.GetCurrentEra = function()
			return indexes[world.era and world.era.type or data.era]
		end
		eras.HasHeroicGoldenAge = function(_, id)
			return AgeOf(id) == "heroic"
		end
		eras.HasGoldenAge = function(_, id)
			return AgeOf(id) == "heroic" or AgeOf(id) == "golden"
		end
		eras.HasDarkAge = function(_, id)
			return AgeOf(id) == "dark"
		end
		eras.IsPlayerAlwaysAllowedCommemorationQuest = function()
			return data.alwaysNormal == true
		end
		eras.GetPlayerNumAllowedCommemorations = function()
			return data.allowed or 0
		end
		eras.GetPlayerCommemorateChoices = function()
			local choices = {}

			for i, category in ipairs(data.options or {}) do
				choices[i] = indexes["COMMEMORATION_" .. category]
			end

			return choices
		end

		return eras
	end
end

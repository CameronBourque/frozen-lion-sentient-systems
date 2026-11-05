-- The player managers. Fakes which players are alive, major or minor, what each
-- has revealed and sees, and the game turn.

return function(env, world, ctx)
	local PlotIndex = ctx.PlotIndex

	ctx.Callable(env.GameInfo.LeaderTraits)

	-- The IDs of the living players, in ID order, that pass a filter on
	-- world.players.
	local function Living(isWanted)
		local living = {}

		for id = 0, 63 do
			if env.Players[id] ~= nil and isWanted(world.players[id]) then
				living[#living + 1] = id
			end
		end

		return living
	end

	local function Major(data)
		return data.minor == nil
	end

	local function Minor(data)
		return data.minor ~= nil
	end

	local function Of(ids)
		local list = {}

		for i, id in ipairs(ids) do
			list[i] = env.Players[id]
		end

		return list
	end

	env.Game.IsAllowStrategicCommands = function(playerID)
		return (world.players or {})[playerID].noStrategicCommands ~= true
	end

	-- The major players, in ID order, as Game.GetPlayers({ Major = true })
	-- lists them.
	env.Game.GetPlayers = function(filter)
		assert(filter.Major == true, "no fake for this filter")

		return Of(Living(Major))
	end

	env.Game.GetCurrentGameTurn = function()
		return world.turn or 1
	end

	-- The living players, in ID order, as the game lists them.
	env.PlayerManager = {
		GetAlive = function()
			local alive = {}

			for id = 0, 63 do
				alive[#alive + 1] = env.Players[id]
			end

			return alive
		end,
		-- The IDs of the living players without data.minor, in ID order.
		GetAliveMajorIDs = function()
			return Living(Major)
		end,
		-- The living players without data.minor, in ID order.
		GetAliveMajors = function()
			return Of(Living(Major))
		end,
		-- The living city-states and Free Cities, the players with data.minor,
		-- in ID order.
		GetAliveMinors = function()
			return Of(Living(Minor))
		end,
	}

	ctx.OnPlayer(function(player, data, id)
		function player.IsFreeCities()
			return data.freeCities == true
		end

		-- A city-state's name and leader, and its leader's row, with the leader
		-- it inherits from.
		local minor = data.minor or {}

		env.PlayerConfigurations[id] = {
			GetCivilizationShortDescription = function()
				return minor.name
			end,
			GetLeaderTypeName = function()
				return minor.leader
			end,
			GetCivilizationLevelTypeID = function()
				return data.minor and 1 or 0
			end,
			GetPlayerName = function()
				return data.playerName or ("LOC_LEADER_" .. id .. "_NAME")
			end,
		}

		if minor.leader ~= nil then
			env.GameInfo.Leaders[minor.leader] = { LeaderType = minor.leader, InheritFrom = minor.inherit }
		end

		for i, description in ipairs(minor.traits or {}) do
			local traitType = minor.leader .. "_TRAIT_" .. i

			table.insert(env.GameInfo.LeaderTraits, { LeaderType = minor.leader, TraitType = traitType })
			env.GameInfo.Traits[traitType] = { TraitType = traitType, Description = description }
		end

		-- Each listed plot's index: revealed, or visible, which is revealed
		-- too.
		local revealed, visible = {}, {}

		for _, position in ipairs(data.revealed or {}) do
			revealed[PlotIndex(position[1], position[2])] = true
		end

		for _, position in ipairs(data.visible or {}) do
			revealed[PlotIndex(position[1], position[2])] = true
			visible[PlotIndex(position[1], position[2])] = true
		end

		-- Each takes a plot index, or x and y, as in the game.
		env.PlayersVisibility[id] = {
			IsRevealed = function(_, indexOrX, y)
				return revealed[y and PlotIndex(indexOrX, y) or indexOrX] == true
			end,
			IsVisible = function(_, indexOrX, y)
				return visible[y and PlotIndex(indexOrX, y) or indexOrX] == true
			end,
			IsUnitVisible = function(_, unit)
				return not unit.hidden
			end,
		}
	end)
end

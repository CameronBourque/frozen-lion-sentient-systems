-- Envoys. A player's influence has tokens, canGive, false to refuse envoys, points, perTurn,
-- threshold, and envoys, the envoys each threshold gives. A city-state's minor has envoys, the count
-- by player ID, suzerain, a player ID, cantReceive, true for the Free Cities, quests by player ID,
-- each with type, name, description, and reward, and uniqueDisabled, true when Gathering Storm turns
-- off its suzerain bonus. The minor's name, leader, inherit, traits, and resources are in
-- FakeGame.lua.

return function(env, world, ctx)
	local AddRow, indexes = ctx.AddRow, ctx.indexes

	env.GameInfo.Quests = ctx.TypedRows({}, "QuestType")

	-- A city-state's quests get their rows.
	for _, data in pairs(world.players or {}) do
		for _, quests in pairs((data.minor or {}).quests or {}) do
			for _, quest in ipairs(quests) do
				AddRow("Quests", "QuestType", quest.type)
			end
		end
	end


	ctx.OnPlayer(function(player, data, id)
		player.GetInfluence = function()
			local influence = data.influence or {}
			local minor = data.minor or {}

			local result = {
				GetTokensToGive = function()
					return influence.tokens or 0
				end,
				CanGiveInfluence = function()
					return influence.canGive ~= false
				end,
				GetPointsEarned = function()
					return influence.points or 0
				end,
				GetPointsPerTurn = function()
					return influence.perTurn or 0
				end,
				GetPointsThreshold = function()
					return influence.threshold or 50
				end,
				GetTokensPerThreshold = function()
					return influence.envoys or 1
				end,
				-- A city-state that can receive envoys, which the player has met and isn't at war
				-- with.
				CanGiveTokensToPlayer = function(_, otherID)
					local other = env.Players[otherID]

					for _, enemy in ipairs(data.atWar or {}) do
						if enemy == otherID then
							return false
						end
					end

					return other:GetInfluence():CanReceiveInfluence() and env.Players[id]:GetDiplomacy():HasMet(otherID)
				end,
				CanReceiveInfluence = function()
					return data.minor ~= nil and minor.cantReceive ~= true
				end,
				GetTokensReceived = function(_, playerID)
					return (minor.envoys or {})[playerID] or 0
				end,
				GetMostTokensReceived = function()
					local most = 0

					for _, envoys in pairs(minor.envoys or {}) do
						most = math.max(most, envoys)
					end

					return most
				end,
				GetSuzerain = function()
					return minor.suzerain or -1
				end,
			}

			if env.GameInfo.Governments_XP2 ~= nil then
				function result.IsSuzerainUniqueBonusDisabled()
					return minor.uniqueDisabled == true
				end
			end

			return result
		end
	end)

	-- The quests from data.minor.quests, by the player they are for.
	env.Game.GetQuestsManager = function()
		local function Find(playerID, cityStateID, index)
			local minor = world.players[cityStateID].minor or {}

			for _, quest in ipairs((minor.quests or {})[playerID] or {}) do
				if indexes[quest.type] == index then
					return quest
				end
			end
		end

		return {
			HasActiveQuestFromPlayer = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index) ~= nil
			end,
			GetActiveQuestName = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index).name
			end,
			GetActiveQuestDescription = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index).description
			end,
			GetActiveQuestReward = function(_, playerID, cityStateID, index)
				return Find(playerID, cityStateID, index).reward
			end,
		}
	end
end

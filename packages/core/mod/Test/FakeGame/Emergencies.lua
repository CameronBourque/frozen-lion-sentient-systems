-- The emergencies a player faces. A player's emergencies are the entries of the game's
-- GetEmergencyInfoTable, each with type, an EmergencyType, hostile, waiting, true for the one
-- GetNextBlockingEmergency returns, and the game's own fields, such as TargetID, TargetCityName,
-- NameText, ShortDescriptionText, GoalDescription, TurnsLeft, HasBegun, MemberIDs, GoalsTable,
-- TargetGoalsTable, ScoreSourcesTable, BuffsText, ExtraBuffs, the MemberRewardsText lists,
-- TargetRewardsText, and ExtraRewards, with a missing text 0 or "" and a missing list empty.

return function(env, world, ctx)
	local indexes = ctx.indexes

	env.GameInfo.EmergencyAlliances = {}
	env.GameInfo.Emergencies_XP2 = {}
	env.EndTurnBlockingTypes.ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION = 1215684002

	-- Each emergency gets rows in the tables the popup reads, by its GameInfo index.
	for _, data in pairs(world.players or {}) do
		for _, emergency in ipairs(data.emergencies or {}) do
			ctx.AddRow("EmergencyAlliances", "EmergencyType", emergency.type)
			env.GameInfo.Emergencies_XP2[indexes[emergency.type]] = { Hostile = emergency.hostile }
		end
	end

	-- A player's emergency entries, and the next one waiting, from data.emergencies. The game's
	-- table holds the emergency type as an index, and each list defaults to an empty one.
	env.Game.GetEmergencyManager = function()
		return {
			GetEmergencyInfoTable = function(_, playerID)
				local entries = {}

				for _, emergency in ipairs(world.players[playerID].emergencies or {}) do
					local entry = {
						EmergencyType = indexes[emergency.type],
						TargetCityName = "",
						NameText = "",
						ShortDescriptionText = "",
						GoalDescription = "",
						ExtraBuffs = "",
						ExtraRewards = "",
						TurnsLeft = 0,
						MemberIDs = {},
						GoalsTable = {},
						TargetGoalsTable = {},
						ScoreSourcesTable = {},
						BuffsText = {},
						MemberRewardsTextFirst = {},
						MemberRewardsTextTop = {},
						MemberRewardsTextBottom = {},
						MemberRewardsTextExtra = {},
						TargetRewardsText = {},
					}

					for key, value in pairs(emergency) do
						entry[key] = value
					end

					entries[#entries + 1] = entry
				end

				return entries
			end,
			GetNextBlockingEmergency = function(_, playerID)
				for _, emergency in ipairs(world.players[playerID].emergencies or {}) do
					if emergency.waiting then
						return { eTarget = emergency.TargetID, eEmergencyType = indexes[emergency.type] }
					end
				end
			end,
		}
	end
end

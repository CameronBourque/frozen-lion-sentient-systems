-- The Espionage screen. Fakes spy capacity, Gain Sources boosts, captured and
-- traveling spies, and a spy unit's mission and level. SpyMissions.lua and
-- Spies.lua hold the rest of the spy calls.

return function(env, _, ctx)
	local indexes = ctx.indexes

	env.EspionageResultTypes = {
		KILLED = 0,
		CAPTURED = 1,
		FAIL_MUST_ESCAPE = 2,
		FAIL_UNDETECTED = 3,
		SUCCESS_MUST_ESCAPE = 4,
		SUCCESS_UNDETECTED = 5,
		NO_RESULT = -1,
	}

	for _, name in ipairs({ "SPY_SIPHON_FUNDS", "SPY_GREAT_WORK_HEIST" }) do
		local row = env.GameInfo.UnitOperations[indexes["UNITOPERATION_" .. name]]

		env.UnitOperationTypes[name] = row and row.Hash
	end

	ctx.OnPlayer(function(player, data)
		local getDiplomacy = player.GetDiplomacy

		function player.GetDiplomacy()
			local diplomacy = getDiplomacy()
			local captured = data.captured or {}
			local traveling = data.traveling or {}

			function diplomacy.GetSpyCapacity()
				return data.spyCapacity or 0
			end

			function diplomacy.GetSourceTurnsRemaining(_, city)
				for _, source in ipairs(data.sources or {}) do
					if source.owner == city:GetOwner() and source.id == city:GetID() then
						return source.turns
					end
				end

				return 0
			end

			function diplomacy.GetNumSpiesCaptured()
				return #captured
			end

			function diplomacy.GetRecentMissions()
				local missions = {}

				for i, mission in ipairs(data.missions or {}) do
					missions[i] = {
						Name = mission.name,
						LevelAfter = mission.level or 1,
						Operation = indexes[mission.operation],
						CompletionTurn = mission.turn,
						InitialResult = env.EspionageResultTypes[mission.initial],
						EscapeResult = env.EspionageResultTypes[mission.escape or "NO_RESULT"],
						LootInfo = mission.loot or -1,
						CityName = mission.city,
						PlotIndex = 0,
					}
				end

				return #missions > 0 and missions or nil
			end

			function diplomacy.GetNthCapturedSpy(_, _, i)
				local spy = captured[i + 1]

				return spy and { OwningPlayer = spy.owner, Name = spy.name, Level = spy.level, NameIndex = spy.index }
			end

			function diplomacy.GetNumSpiesOffMap()
				return #traveling
			end

			function diplomacy.GetNthOffMapSpy(_, _, i)
				local spy = traveling[i + 1]

				return spy and { Name = spy.name, Level = spy.level, XLocation = spy.x, YLocation = spy.y, ReturnTurn = spy.returnTurn }
			end

			return diplomacy
		end
	end)

	ctx.OnUnit(function(unit, data)
		local spy = data.spy

		if spy == nil or spy.level == nil then
			return
		end

		function unit.GetName()
			return spy.name
		end

		function unit.GetExperience()
			return {
				GetLevel = function()
					return spy.level
				end,
				GetExperiencePoints = function()
					return 0
				end,
				GetExperienceForNextLevel = function()
					return 0
				end,
				GetPromotions = function()
					return {}
				end,
			}
		end

		function unit.GetSpyOperation()
			return spy.operation and indexes[spy.operation] or -1
		end

		function unit.GetSpyOperationEndTurn()
			return spy.endTurn or 0
		end
	end)
end

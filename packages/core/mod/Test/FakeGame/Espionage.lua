-- The Espionage screen. Fakes a player's spy capacity, the spies other players
-- hold, the spies on their way, and a spy unit's mission and level.
-- SpyMissions.lua and Spies.lua hold the rest of the spy calls.

return function(env, _, ctx)
	local indexes = ctx.indexes

	ctx.OnPlayer(function(player, data)
		local getDiplomacy = player.GetDiplomacy

		function player.GetDiplomacy()
			local diplomacy = getDiplomacy()
			local captured = data.captured or {}
			local traveling = data.traveling or {}

			function diplomacy.GetSpyCapacity()
				return data.spyCapacity or 0
			end

			function diplomacy.GetNumSpiesCaptured()
				return #captured
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

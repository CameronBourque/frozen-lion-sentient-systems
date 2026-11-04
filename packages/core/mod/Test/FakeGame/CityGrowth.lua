-- A city's growth. Fakes its food, housing, amenities, and loyalty. Without
-- loyalty the city has no GetCulturalIdentity, as without Rise and Fall.

return function(env, world, ctx)
	-- GameInfo.Happinesses, by index, as in the game.
	env.GameInfo.Happinesses = {
		[0] = { HappinessType = "HAPPINESS_REVOLT" },
		{ HappinessType = "HAPPINESS_UNREST" },
		{ HappinessType = "HAPPINESS_UNHAPPY" },
		{ HappinessType = "HAPPINESS_DISPLEASED" },
		{ HappinessType = "HAPPINESS_CONTENT" },
		{ HappinessType = "HAPPINESS_HAPPY" },
		{ HappinessType = "HAPPINESS_ECSTATIC" },
	}

	ctx.OnCity(function(city, data)
		local growth = data.growth or {}
		local loyalty = data.loyalty

		function city.IsOccupied()
			return data.occupied == true
		end

		function city.GetGrowth()
			return {
				GetFoodSurplus = function()
					return growth.foodSurplus or 0
				end,
				GetHousing = function()
					return growth.housing or 0
				end,
				GetAmenities = function()
					return growth.amenities or 0
				end,
				GetAmenitiesNeeded = function()
					return growth.amenitiesNeeded or 0
				end,
				GetHappiness = function()
					return growth.happiness or 4
				end,
				GetHappinessNonFoodYieldModifier = function()
					return growth.yieldModifier or 0
				end,
				GetHousingGrowthModifier = function()
					return growth.housingModifier or 1
				end,
				GetHappinessGrowthModifier = function()
					return growth.happinessModifier or 0
				end,
				GetAmenitiesLostFromWarWeariness = function()
					return growth.warWeariness or 0
				end,
				GetTurnsUntilGrowth = function()
					return growth.turnsUntilGrowth or -1
				end,
				GetTurnsUntilStarvation = function()
					return growth.turnsUntilStarvation or -1
				end,
			}
		end

		if loyalty ~= nil then
			function city.GetCulturalIdentity()
				return {
					GetLoyalty = function()
						return loyalty.value
					end,
					GetMaxLoyalty = function()
						return loyalty.max
					end,
					GetLoyaltyPerTurn = function()
						return loyalty.perTurn
					end,
				}
			end
		end
	end)
end

-- A city's growth. data.growth has foodSurplus, housing, amenities, and amenitiesNeeded, each 0 when
-- missing, happiness, an index in GameInfo.Happinesses that is 4, content, when missing,
-- turnsUntilGrowth and turnsUntilStarvation, which are -1 when missing, as in the game, yieldModifier,
-- the amenities' modifier, housingModifier, which is 1 when missing, happinessModifier, and
-- warWeariness, which are 0. A city's occupied is true for an occupied city. data.loyalty has value,
-- max, and perTurn. Without it, the city has no GetCulturalIdentity, as in a game without the Rise
-- and Fall expansion.

return function(env, world, ctx)
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

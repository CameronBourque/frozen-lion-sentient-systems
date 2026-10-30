-- Captured and rebelled cities. A player's captured and rebelled are the next city it captured and
-- the next city that rebelled to join it, each with id, name, x, y, population, districts,
-- originalOwner, ownerBefore, conqueredFrom, gift, true for a city given in a deal, canRaze, false for
-- one the player can't raze, and warmonger, with keep and raze points. noRiseAndFall leaves out
-- GetNextRebelledCity. A player's liberate lists the IDs it can liberate a city to, and revived the
-- IDs it has brought back.

-- The game's city transfer types, of which the raze screen checks only BY_GIFT.
local CITY_TRANSFER_TYPES = { BY_GIFT = 7 }

-- A captured or rebelled city from data, with the calls the raze and disloyal city screens make.
local function ChangedCity(data)
	return {
		GetID = function()
			return data.id
		end,
		GetName = function()
			return data.name
		end,
		GetX = function()
			return data.x
		end,
		GetY = function()
			return data.y
		end,
		GetPopulation = function()
			return data.population
		end,
		GetDistricts = function()
			return {
				GetNumZonedDistrictsRequiringPopulation = function()
					return data.districts or 0
				end,
			}
		end,
		GetOriginalOwner = function()
			return data.originalOwner
		end,
		GetOwnerBeforeOccupation = function()
			return data.ownerBefore
		end,
		GetJustConqueredFrom = function()
			return data.conqueredFrom
		end,
		GetLastTransferType = function()
			return data.gift and CITY_TRANSFER_TYPES.BY_GIFT or 0
		end,
		CanRaze = function()
			return data.canRaze ~= false
		end,
	}
end

return function(env, world, ctx)
	env.CityDestroyDirectives = { LIBERATE_FOUNDER = 0, LIBERATE_PREVIOUS_OWNER = 1, KEEP = 2, RAZE = 3, REJECT = 4 }
	env.CivilizationLevelTypes = { CIVILIZATION_LEVEL_FULL_CIV = 0 }
	env.CityTransferTypes = CITY_TRANSFER_TYPES

	ctx.OnPlayer(function(player, data)
		local GetCities, GetStats, GetDiplomacy = player.GetCities, player.GetStats, player.GetDiplomacy

		-- The next city the player captured and the next that rebelled to join it, from data.captured and
		-- data.rebelled. Without Rise and Fall there is no GetNextRebelledCity.
		function player.GetCities()
			local list = GetCities()

			function list.GetNextCapturedCity()
				return data.captured and ChangedCity(data.captured)
			end

			if not data.noRiseAndFall then
				function list.GetNextRebelledCity()
					return data.rebelled and ChangedCity(data.rebelled)
				end
			end

			return list
		end

		function player.GetStats()
			local stats = GetStats()

			function stats.GetHasRevivedPlayer(_, otherID)
				for _, revived in ipairs(data.revived or {}) do
					if revived == otherID then
						return true
					end
				end

				return false
			end

			return stats
		end

		function player.GetDiplomacy()
			local diplomacy = GetDiplomacy()

			diplomacy.CanLiberateCityTo = function(_, otherID)
				for _, liberate in ipairs(data.liberate or {}) do
					if liberate == otherID then
						return true
					end
				end

				return false
			end

			-- The warmonger points of keeping or razing, from data.captured.warmonger.
			diplomacy.ComputeCityWarmongerPoints = function(_, _, _, raze)
				local warmonger = data.captured.warmonger or {}

				return (raze and warmonger.raze or warmonger.keep) or 0
			end

			diplomacy.GetWarmongerLevel = function(_, points)
				return "LOC_WARMONGER_LEVEL_" .. points
			end

			return diplomacy
		end
	end)
end

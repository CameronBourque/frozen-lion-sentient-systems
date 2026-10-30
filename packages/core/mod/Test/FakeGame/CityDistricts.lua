-- A city's districts. data.districts lists each district with type, x, y, complete, which is true when
-- missing, pillaged, yields, and adjacency, each a YieldTypes name to an amount, and buildings, which
-- FakeGame/CityBuildings.lua describes. A city's capital is true or false. Its defense has strength,
-- garrison, and walls, the last two each with damage and max. Without them the garrison has damage 0
-- and max 200 and the walls 0 and 0. The city center is what the player's GetDistricts():FindID
-- returns by the city's ID.

return function(env, world, ctx)
	local indexes, YIELD_NAMES, List, Layout = ctx.indexes, ctx.YIELD_NAMES, ctx.List, ctx.Layout

	-- The DefenseTypes values for a district's garrison and walls.
	local DEFENSE_TYPES = { DISTRICT_GARRISON = 0, DISTRICT_OUTER = 1 }

	env.DefenseTypes = DEFENSE_TYPES

	ctx.OnCity(function(city, data)
		local placed = Layout(data).placed
		local districts = {}

		for i, district in ipairs(data.districts or {}) do
			districts[i] = {
				GetType = function()
					return indexes[district.type]
				end,
				GetX = function()
					return district.x
				end,
				GetY = function()
					return district.y
				end,
				IsComplete = function()
					return district.complete ~= false
				end,
				IsPillaged = function()
					return district.pillaged == true
				end,
				-- The district's yield and adjacency bonus for a GameInfo.Yields index, from district.yields and
				-- district.adjacency, which map a YieldTypes name to an amount.
				GetYield = function(_, yieldIndex)
					return (district.yields or {})[YIELD_NAMES[yieldIndex]] or 0
				end,
				GetAdjacencyYield = function(_, yieldIndex)
					return (district.adjacency or {})[YIELD_NAMES[yieldIndex]] or 0
				end,
			}
		end

		local defense = data.defense or {}
		local garrison = defense.garrison or { damage = 0, max = 200 }
		local walls = defense.walls or { damage = 0, max = 0 }

		local districtList = List(districts)

		-- The city's district list also answers for a district type, by its GameInfo index.
		function districtList.HasDistrict(_, index)
			return placed[index] ~= nil
		end

		function districtList.IsComplete(_, index)
			return placed[index] ~= nil and placed[index].complete ~= false
		end

		function districtList.IsPillaged(_, index)
			return placed[index] ~= nil and placed[index].pillaged == true
		end

		function districtList.IsContaminated()
			return false
		end

		function city.IsCapital()
			return data.capital == true
		end

		-- The city center district, which the fake player's GetDistricts():FindID returns by the
		-- city's ID.
		city.center = {
			GetDefenseStrength = function()
				return defense.strength or 0
			end,
			GetDamage = function(_, defenseType)
				return defenseType == DEFENSE_TYPES.DISTRICT_OUTER and walls.damage or garrison.damage
			end,
			GetMaxDamage = function(_, defenseType)
				return defenseType == DEFENSE_TYPES.DISTRICT_OUTER and walls.max or garrison.max
			end,
		}

		function city.GetDistricts()
			return districtList
		end
	end)
end

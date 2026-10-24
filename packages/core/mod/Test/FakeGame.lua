-- A fake of the game's Lua API for tests, with players, their cities, GameInfo.Types, YieldTypes,
-- and Locale. It has only the calls the core mod makes. Example:
-- local env = Game.new()
-- FakeGame.Install(env, {
-- 	players = { [0] = { cities = { {
-- 		id = 65536, name = "LOC_CITY_NAME_ROME", x = 17, y = 14, population = 3,
-- 		production = { type = "UNIT_SLINGER", turnsLeft = 2 },
-- 		yields = { FOOD = 9, PRODUCTION = 6 },
-- 	} } } },
-- 	text = { LOC_CITY_NAME_ROME = "Rome" },
-- })
-- env.Players[0]:GetCities():Members() then lists the one city.

local FakeGame = {}

-- A list with Members(), as the game's city and unit lists have. Members() returns an iterator, as
-- in "for i, city in player:GetCities():Members() do".
local function List(items)
	return {
		Members = function()
			return ipairs(items)
		end,
	}
end

-- The YieldTypes values, as in the game.
local YIELD_TYPES = { FOOD = 0, PRODUCTION = 1, GOLD = 2, SCIENCE = 3, CULTURE = 4, FAITH = 5 }

-- A city from data. data.production is { type, turnsLeft }, or { hash, turnsLeft } for a hash that
-- GameInfo.Types doesn't know, or nil for nothing in production. data.yields maps a YieldTypes
-- name to its amount, and a missing yield is 0. hashes maps each production type to its hash.
local function City(data, hashes)
	local production = data.production
	local hash = production and (production.hash or hashes[production.type]) or 0

	return {
		GetBuildQueue = function()
			return {
				GetCurrentProductionTypeHash = function()
					return hash
				end,
				-- The game takes a hash or a type name.
				GetTurnsLeft = function(_, typeOrHash)
					assert(production and (typeOrHash == hash or typeOrHash == production.type), "no production " .. tostring(typeOrHash))

					return production.turnsLeft
				end,
			}
		end,
		GetYield = function(_, yieldType)
			for name, value in pairs(YIELD_TYPES) do
				if value == yieldType then
					return (data.yields or {})[name] or 0
				end
			end

			error("no yield type " .. tostring(yieldType))
		end,
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
	}
end

local function Player(id, data, hashes)
	local cities = {}

	for i, city in ipairs(data.cities or {}) do
		cities[i] = City(city, hashes)
	end

	return {
		GetID = function()
			return id
		end,
		GetCities = function()
			return List(cities)
		end,
	}
end

-- Sets Players, GameInfo, YieldTypes, and Locale in env from world. world.players maps each player
-- ID to its data. world.text maps each LOC_ key to its text. Locale.Lookup returns any other key as
-- it is. GameInfo.Types holds each production type in world, under a made-up hash.
function FakeGame.Install(env, world)
	local hashes = {}
	local count = 0

	env.GameInfo = { Types = {} }
	env.YieldTypes = YIELD_TYPES

	for _, data in pairs(world.players or {}) do
		for _, city in ipairs(data.cities or {}) do
			local typeName = city.production and city.production.type

			if typeName ~= nil and hashes[typeName] == nil then
				count = count + 1

				local hash = 1000000 + count

				hashes[typeName] = hash
				env.GameInfo.Types[hash] = { Type = typeName }
			end
		end
	end

	env.Players = {}

	for id, data in pairs(world.players or {}) do
		env.Players[id] = Player(id, data, hashes)
	end

	local text = world.text or {}

	env.Locale = {
		Lookup = function(key)
			return text[key] or key
		end,
	}
end

return FakeGame

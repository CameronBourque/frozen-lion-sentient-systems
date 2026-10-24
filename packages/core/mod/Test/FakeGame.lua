-- A fake of the game's Lua API for tests, with players, their cities, and Locale. It has only the
-- calls the core mod makes. Example:
-- local env = Game.new()
-- FakeGame.Install(env, {
-- 	players = { [0] = { cities = { { id = 65536, name = "LOC_CITY_NAME_ADUATUCA", x = 42, y = 49, population = 1 } } } },
-- 	text = { LOC_CITY_NAME_ADUATUCA = "Aduatuca" },
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

local function City(data)
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
	}
end

local function Player(id, data)
	local cities = {}

	for i, city in ipairs(data.cities or {}) do
		cities[i] = City(city)
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

-- Sets Players and Locale in env from world. world.players maps each player ID to its data.
-- world.text maps each LOC_ key to its text. Locale.Lookup returns any other key as it is.
function FakeGame.Install(env, world)
	env.Players = {}

	for id, data in pairs(world.players or {}) do
		env.Players[id] = Player(id, data)
	end

	local text = world.text or {}

	env.Locale = {
		Lookup = function(key)
			return text[key] or key
		end,
	}
end

return FakeGame

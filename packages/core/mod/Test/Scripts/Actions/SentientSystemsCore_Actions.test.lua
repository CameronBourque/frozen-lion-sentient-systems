local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")
end)

describe("SentientSystems_RunAction", function()
	it("returns ok when the action returns nothing", function()
		assert.equal("{\"ok\":true}", env.SentientSystems_RunAction("MoveUnit", function() end))
	end)

	it("returns the reason when the action returns one", function()
		assert.equal("{\"ok\":false,\"reason\":\"That tile is out of reach.\"}", env.SentientSystems_RunAction("MoveUnit", function()
			return "That tile is out of reach."
		end))
	end)

	it("passes the arguments after the action to it, nil ones included", function()
		assert.equal("{\"ok\":false,\"reason\":\"3 nil 5\"}", env.SentientSystems_RunAction("MoveUnit", function(x, y, z)
			return x .. " " .. tostring(y) .. " " .. z
		end, 3, nil, 5))
	end)

	it("returns a Lua error as a failure with its first line", function()
		assert.equal("{\"ok\":false,\"reason\":\"MoveUnit failed: no unit 7\"}", env.SentientSystems_RunAction("MoveUnit", function()
			error("no unit 7\nstack traceback:\n\t[C]: in function 'error'", 0)
		end))
	end)

	it("loads the JSON encoder without an ERROR line, so the bridge can stash the result", function()
		assert.same({}, env.printed)
		assert.equal(1, env.SentientSystems_Stash(env.SentientSystems_RunAction("MoveUnit", function() end)))
	end)
end)

describe("SentientSystems_HasTile", function()
	local TILES = { { x = 3, y = 4 }, { x = 5, y = 6 } }

	it("finds a tile in the list", function()
		assert.is_true(env.SentientSystems_HasTile(TILES, 5, 6))
	end)

	it("misses a tile that matches only x or only y", function()
		assert.is_false(env.SentientSystems_HasTile(TILES, 3, 6))
		assert.is_false(env.SentientSystems_HasTile({}, 3, 4))
	end)
end)

describe("SentientSystems_ListTiles", function()
	local function Tiles(count)
		local tiles = {}

		for i = 1, count do
			tiles[i] = { x = i, y = 0 }
		end

		return tiles
	end

	it("lists every tile up to 8, in order", function()
		assert.equal("(1, 0), (2, 0)", env.SentientSystems_ListTiles(Tiles(2)))
		assert.equal("(1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0)", env.SentientSystems_ListTiles(Tiles(8)))
	end)

	it("lists the first 8 and counts the rest", function()
		assert.equal("(1, 0), (2, 0), (3, 0), (4, 0), (5, 0), (6, 0), (7, 0), (8, 0), and 2 more", env.SentientSystems_ListTiles(Tiles(10)))
	end)
end)

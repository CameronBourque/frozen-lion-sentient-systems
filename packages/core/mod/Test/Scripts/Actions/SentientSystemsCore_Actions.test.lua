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

local Game = require("Game")

describe("Game.new", function()
	it("leaves out the functions the game's Lua doesn't have", function()
		local env = Game.new()

		assert.is_nil(env.load)
		assert.is_nil(env.setfenv)
		assert.is_nil(env.io)
		assert.is_nil(env.debug)
		assert.is_nil(env.string.gfind)
		assert.is_nil(env.table.getn)
	end)

	it("keeps the functions the game's Lua has", function()
		local env = Game.new()

		assert.is_function(env.loadstring)
		assert.is_function(env.unpack)
		assert.is_table(env.os)
		assert.is_function(env.string.format)
		assert.is_function(env.table.concat)
	end)

	it("leaves the test's own libraries alone", function()
		Game.new()

		assert.is_function(string.gfind)
		assert.is_function(table.getn)
	end)

	it("joins print's arguments with tabs", function()
		local env = Game.new()

		env.print("a", nil, 1)

		assert.same({ "a\tnil\t1" }, env.printed)
	end)
end)

describe("Game.run", function()
	it("runs a mod file in the environment, where include loads files from Scripts", function()
		local env = Game.new()

		env.include("SentientSystemsCore_Tag")

		assert.equal("[SENTIENTSYSTEMS]", env.SENTIENTSYSTEMS_TAG)
		assert.is_nil(SENTIENTSYSTEMS_TAG)
	end)

	it("raises an error for a file that doesn't exist", function()
		assert.has_error(function()
			Game.run(Game.new(), "Scripts/Missing.lua")
		end)
	end)
end)

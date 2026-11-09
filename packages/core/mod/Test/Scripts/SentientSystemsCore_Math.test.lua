local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/SentientSystemsCore_Math.lua")
end)

describe("SentientSystems_Round", function()
	it("rounds to a whole number when places is left out", function()
		assert.equal(3, env.SentientSystems_Round(2.5))
		assert.equal(2, env.SentientSystems_Round(2.49))
	end)

	it("rounds to the decimal places given", function()
		assert.equal(1.3, env.SentientSystems_Round(1.25, 1))
		assert.equal(0.667, env.SentientSystems_Round(2 / 3, 3))
	end)

	it("rounds a half up, toward positive infinity", function()
		assert.equal(-2, env.SentientSystems_Round(-2.5))
	end)
end)

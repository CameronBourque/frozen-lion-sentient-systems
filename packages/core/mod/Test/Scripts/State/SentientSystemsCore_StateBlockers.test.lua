local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the blockers section of the state JSON for player 0, built from the player's data.
local function BlockersOf(player)
	local env = Game.new()

	FakeGame.Install(env, { players = { [0] = player } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("^{\"blockers\":(%b{}),")
end

describe("SentientSystems_GetBlockerState", function()
	it("gives empty lists when nothing blocks the end of the turn", function()
		assert.equal("{\"list\":[],\"units\":[]}", BlockersOf({}))
	end)

	it("lists each blocker by name in the game's order, with the choice that resolves it", function()
		assert.equal(
			"{\"list\":[{\"choice\":\"techs\",\"type\":\"ENDTURN_BLOCKING_RESEARCH\"},{\"choice\":\"civics\",\"type\":\"ENDTURN_BLOCKING_CIVIC\"},"
				.. "{\"choice\":\"production\",\"type\":\"ENDTURN_BLOCKING_PRODUCTION\"},{\"choice\":\"government\",\"type\":\"ENDTURN_BLOCKING_FILL_CIVIC_SLOT\"}],\"units\":[]}",
			BlockersOf({ blockers = {
				"ENDTURN_BLOCKING_RESEARCH",
				"ENDTURN_BLOCKING_CIVIC",
				"ENDTURN_BLOCKING_PRODUCTION",
				"ENDTURN_BLOCKING_FILL_CIVIC_SLOT",
			} })
		)
	end)

	it("lists a blocker that the game repeats only once", function()
		assert.equal(
			"{\"list\":[{\"choice\":\"production\",\"type\":\"ENDTURN_BLOCKING_PRODUCTION\"},{\"choice\":\"techs\",\"type\":\"ENDTURN_BLOCKING_RESEARCH\"}],\"units\":[]}",
			BlockersOf({ blockers = { "ENDTURN_BLOCKING_PRODUCTION", "ENDTURN_BLOCKING_RESEARCH", "ENDTURN_BLOCKING_PRODUCTION" } })
		)
	end)

	it("gives no choice for a unit blocker or a value that no UI file names", function()
		assert.equal(
			"{\"list\":[{\"type\":\"ENDTURN_BLOCKING_UNITS\"},{\"type\":\"ENDTURN_BLOCKING_UNIT_PROMOTION\"}],\"units\":[]}",
			BlockersOf({ blockers = { "ENDTURN_BLOCKING_UNITS", "ENDTURN_BLOCKING_UNIT_PROMOTION" } })
		)
	end)

	it("names a value that EndTurnBlockingTypes doesn't hold by its number", function()
		assert.equal("{\"list\":[{\"type\":\"12345\"}],\"units\":[]}", BlockersOf({ blockers = { 12345 } }))
	end)

	it("lists the units that need orders, in the game's order", function()
		assert.equal(
			"{\"list\":[],\"units\":[196608,131074]}",
			BlockersOf({ units = {
				{ id = 196608, type = "UNIT_SCOUT", x = 24, y = 15, moves = 3, maxMoves = 3, ready = true },
				{ id = 131073, type = "UNIT_WARRIOR", x = 7, y = 13, moves = 2, maxMoves = 2 },
				{ id = 131074, type = "UNIT_WARRIOR", x = 8, y = 13, moves = 2, maxMoves = 2, ready = true },
			} })
		)
	end)
end)

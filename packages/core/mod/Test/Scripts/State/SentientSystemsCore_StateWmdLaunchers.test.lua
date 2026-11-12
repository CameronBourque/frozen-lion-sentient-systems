local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local With = Helpers.With

local NUKE, THERMO = "WMD_NUCLEAR_DEVICE", "WMD_THERMONUCLEAR_DEVICE"
local BOMBER = { id = 9371649, type = "UNIT_JET_BOMBER", x = 46, y = 33, moves = 10, maxMoves = 10, wmdReady = { NUKE, THERMO } }
local SUBMARINE = { id = 16056482, type = "UNIT_NUCLEAR_SUBMARINE", x = 35, y = 39, moves = 4, maxMoves = 4, wmdReady = { NUKE } }
local SILO = { x = 44, y = 30, terrain = "TERRAIN_PLAINS", improvement = "IMPROVEMENT_MISSILE_SILO", weaponSlots = 1, siloReady = { NUKE, THERMO } }
local FARM = { x = 45, y = 30, terrain = "TERRAIN_PLAINS", improvement = "IMPROVEMENT_FARM" }
local CITY = { id = 589832, name = "LOC_CITY_NAME_ROME", x = 45, y = 31, population = 10, tiles = { { x = 44, y = 30 }, { x = 45, y = 30 } } }

-- Returns the state JSON of player 0, whose data is given, in a game with both
-- devices and the plots given.
local function StateWith(data, plots)
	local env = Game.new()

	FakeGame.Install(env, { wmds = { NUKE, THERMO }, plots = plots or { SILO, FARM }, players = { [0] = data } })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0)
end

-- Returns the launchers section JSON of player 0, or nil when it's left out.
local function LaunchersWith(data, plots)
	return StateWith(data, plots):match("\"wmdLaunchers\":(%b{})")
end

describe("SentientSystems_GetWmdStockpile", function()
	it("counts each device the player has, as the top bar shows them", function()
		local player = StateWith({ wmds = { [NUKE] = 3, [THERMO] = 4 } }):match("\"player\":(%b{})")

		assert.truthy(player:find("\"wmds\":{\"WMD_NUCLEAR_DEVICE\":3,\"WMD_THERMONUCLEAR_DEVICE\":4}", 1, true))
	end)

	it("leaves out a device at 0", function()
		local player = StateWith({ wmds = { [THERMO] = 1 } }):match("\"player\":(%b{})")

		assert.truthy(player:find("\"wmds\":{\"WMD_THERMONUCLEAR_DEVICE\":1}", 1, true))
	end)

	it("leaves out the stockpile when the player has no devices", function()
		assert.falsy(StateWith({}):match("\"player\":(%b{})"):find("wmds", 1, true))
	end)
end)

describe("SentientSystems_GetWmdLauncherState", function()
	it("lists the units and silos that can launch each device", function()
		assert.equal(
			"{\"WMD_NUCLEAR_DEVICE\":{\"silos\":[{\"x\":44,\"y\":30}],\"units\":[9371649,16056482]},"
				.. "\"WMD_THERMONUCLEAR_DEVICE\":{\"silos\":[{\"x\":44,\"y\":30}],\"units\":[9371649]}}",
			LaunchersWith({ wmds = { [NUKE] = 3, [THERMO] = 4 }, units = { BOMBER, SUBMARINE }, cities = { CITY } })
		)
	end)

	it("leaves out a device the player has none of, even with launchers ready", function()
		assert.equal(
			"{\"WMD_THERMONUCLEAR_DEVICE\":{\"silos\":[{\"x\":44,\"y\":30}],\"units\":[9371649]}}",
			LaunchersWith({ wmds = { [THERMO] = 4 }, units = { BOMBER, SUBMARINE }, cities = { CITY } })
		)
	end)

	it("leaves out an empty list of units or silos", function()
		assert.equal("{\"WMD_NUCLEAR_DEVICE\":{\"units\":[16056482]}}", LaunchersWith({ wmds = { [NUKE] = 1 }, units = { SUBMARINE } }))
		assert.equal(
			"{\"WMD_NUCLEAR_DEVICE\":{\"silos\":[{\"x\":44,\"y\":30}]}}",
			LaunchersWith({ wmds = { [NUKE] = 1 }, units = { With(SUBMARINE, { wmdReady = {} }) }, cities = { CITY } })
		)
	end)

	it("skips a unit with no moves left, as the unit panel shows it no strike", function()
		assert.equal(
			"{\"WMD_NUCLEAR_DEVICE\":{\"units\":[16056482]}}",
			LaunchersWith({ wmds = { [NUKE] = 1 }, units = { With(BOMBER, { moves = 0 }), SUBMARINE } })
		)
	end)

	it("skips a silo that can't launch and a unit that isn't on the map", function()
		local units = { With(BOMBER, { x = -9999, y = -9999 }) }

		assert.is_nil(LaunchersWith({ wmds = { [NUKE] = 1 }, units = units, cities = { CITY } }, { With(SILO, { siloReady = {} }), FARM }))
	end)

	it("is left out when the player has no devices, even with launchers ready", function()
		assert.is_nil(LaunchersWith({ units = { BOMBER }, cities = { CITY } }))
	end)
end)

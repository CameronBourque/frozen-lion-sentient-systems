local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local NUKE, THERMO = "WMD_NUCLEAR_DEVICE", "WMD_THERMONUCLEAR_DEVICE"
local TEXT = { LOC_WMD_NUCLEAR_DEVICE_NAME = "Nuclear Device", LOC_WMD_THERMONUCLEAR_DEVICE_NAME = "Thermonuclear Device" }

-- A jet bomber at (20, 20) that can launch both devices at two tiles, the
-- farther 10 tiles away.
local BOMBER = {
	id = 9371649,
	type = "UNIT_JET_BOMBER",
	domain = "DOMAIN_AIR",
	x = 20,
	y = 20,
	moves = 10,
	wmdReady = { NUKE, THERMO },
	wmdTargets = { { x = 30, y = 20 }, { x = 25, y = 24 } },
}

-- A silo at (44, 30) that can launch both devices at two tiles, in the city
-- that owns its tile.
local SILO = {
	x = 44,
	y = 30,
	terrain = "TERRAIN_PLAINS",
	improvement = "IMPROVEMENT_MISSILE_SILO",
	weaponSlots = 1,
	siloReady = { NUKE, THERMO },
	siloTargets = { { x = 50, y = 30 }, { x = 40, y = 30 } },
}
local FARM = { x = 45, y = 30, terrain = "TERRAIN_PLAINS", improvement = "IMPROVEMENT_FARM" }
local CITY = { id = 589832, name = "LOC_CITY_NAME_AVARICUM", x = 45, y = 31, population = 10, ownedTiles = { { x = 44, y = 30 }, { x = 45, y = 30 } } }

-- Returns an environment with the actions loaded into a fake game where player
-- 0 has the data, with both devices in stock unless the data says otherwise,
-- and the silo has the changes. With rivalCity, player 4 has the silo's city.
local function Load(data, rivalCity, silo)
	local env = Game.new()
	local player = With({ wmds = { [NUKE] = 3, [THERMO] = 4 }, units = { BOMBER }, cities = { CITY } }, data or {})
	local world = { wmds = { NUKE, THERMO }, text = TEXT, plots = { With(SILO, silo or {}), FARM }, players = { [0] = player } }

	if rivalCity ~= nil then
		world.players[0].cities = {}
		world.players[4] = { cities = { rivalCity } }
	end

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

describe("the wmd_strike unit action", function()
	local function Strike(env, x, y, weaponType)
		return env.SentientSystems_UnitAction(0, BOMBER.id, "wmd_strike", x, y, weaponType)
	end

	it("requests the strike at a target tile with the device", function()
		local env = Load()
		local types = env.UnitOperationTypes

		assert.equal("{\"ok\":true}", Strike(env, 30, 20, THERMO))
		assert.same({
			{ unit = BOMBER.id, operation = types.WMD_STRIKE, parameters = { [types.PARAM_X] = 30, [types.PARAM_Y] = 20, [types.PARAM_WMD_TYPE] = 1 } },
		}, env.requests)
	end)

	it("fails without a device, with the devices to pick from", function()
		assert.equal(Failed("A strike needs the device to launch, one of WMD_NUCLEAR_DEVICE, WMD_THERMONUCLEAR_DEVICE."), Strike(Load(), 30, 20, nil))
		assert.equal(Failed("WMD_DIRTY_BOMB isn't a device. The devices are WMD_NUCLEAR_DEVICE, WMD_THERMONUCLEAR_DEVICE."), Strike(Load(), 30, 20, "WMD_DIRTY_BOMB"))
	end)

	it("fails when the player has none of the device left", function()
		assert.equal(Failed("You have no Nuclear Device left."), Strike(Load({ wmds = { [THERMO] = 4 } }), 30, 20, NUKE))
	end)

	it("fails for a tile off the map", function()
		assert.equal(Failed("That action needs a tile. Give x and y."), Strike(Load(), nil, nil, NUKE))
	end)

	it("fails for a unit with no moves left, which the unit panel shows no strike", function()
		local env = Load({ units = { With(BOMBER, { moves = 0 }) } })

		assert.equal(Failed("The unit has no moves left."), Strike(env, 30, 20, NUKE))
		assert.same({}, env.requests)
	end)

	it("fails for a unit that can't launch the device, with the game's reasons", function()
		local env = Load({ units = { With(BOMBER, { wmdReady = { THERMO }, wmdRefusal = { "LOC_NO_ATTACKS_LEFT" } }) } })

		assert.equal(Failed("This unit can't launch Nuclear Device. LOC_NO_ATTACKS_LEFT"), Strike(env, 30, 20, NUKE))
		assert.equal(Failed("This unit can't launch Nuclear Device."), Strike(Load({ units = { With(BOMBER, { wmdReady = {} }) } }), 30, 20, NUKE))
	end)

	it("fails for a tile that isn't a target, with how many tiles it can hit and how far", function()
		assert.equal(Failed("That tile isn't a target. It can hit 2 tiles, up to 10 tiles away."), Strike(Load(), 40, 20, NUKE))
		assert.equal(Failed("Nothing is in range."), Strike(Load({ units = { With(BOMBER, { wmdTargets = {} }) } }), 40, 20, NUKE))
	end)

	it("fails when the strike would start a war", function()
		local env = Load({ units = { With(BOMBER, { startsWar = { { x = 30, y = 20, player = 4 } } }) } })

		assert.equal(Failed("Striking there would start a war with player 4."), Strike(env, 30, 20, NUKE))
		assert.same({}, env.requests)
	end)

	it("fails when the game won't start the strike", function()
		assert.equal(Failed("The game won't start that strike."), Strike(Load({ units = { With(BOMBER, { strikeBlocked = true }) } }), 30, 20, NUKE))
	end)
end)

describe("SentientSystems_SiloStrike", function()
	it("requests the strike through the silo's city", function()
		local env = Load()
		local C = env.CityCommandTypes

		assert.equal("{\"ok\":true}", env.SentientSystems_SiloStrike(0, 44, 30, 50, 30, NUKE))
		assert.same({
			{ city = CITY.id, command = C.WMD_STRIKE, parameters = { [C.PARAM_WMD_TYPE] = 0, [C.PARAM_X0] = 44, [C.PARAM_Y0] = 30, [C.PARAM_X1] = 50, [C.PARAM_Y1] = 30 } },
		}, env.requests)
	end)

	it("fails for a tile with no silo of the player's", function()
		assert.equal(Failed("You have no missile silo at (45, 30)."), Load().SentientSystems_SiloStrike(0, 45, 30, 50, 30, NUKE))
		assert.equal(Failed("You have no missile silo at (44, 30)."), Load({}, With(CITY, { id = 1 })).SentientSystems_SiloStrike(0, 44, 30, 50, 30, NUKE))
		assert.equal(Failed("You have no missile silo at (44, 30)."), Load({ cities = {} }).SentientSystems_SiloStrike(0, 44, 30, 50, 30, NUKE))
		assert.equal(Failed("That action needs a tile. Give x and y."), Load().SentientSystems_SiloStrike(0, nil, nil, 50, 30, NUKE))
	end)

	it("fails without the device or a target tile", function()
		assert.equal(Failed("You have no Thermonuclear Device left."), Load({ wmds = { [NUKE] = 1 } }).SentientSystems_SiloStrike(0, 44, 30, 50, 30, THERMO))
		assert.equal(Failed("That action needs a tile. Give x and y."), Load().SentientSystems_SiloStrike(0, 44, 30, nil, nil, NUKE))
	end)

	it("fails when the silo can't launch the device now", function()
		local env = Load({}, nil, { siloReady = { THERMO } })

		assert.equal(Failed("The silo at (44, 30) can't launch Nuclear Device now."), env.SentientSystems_SiloStrike(0, 44, 30, 50, 30, NUKE))
	end)

	it("fails for a tile that isn't a target", function()
		assert.equal(Failed("That tile isn't a target. It can hit 2 tiles, up to 6 tiles away."), Load().SentientSystems_SiloStrike(0, 44, 30, 60, 30, NUKE))
	end)

	it("fails when the strike would start a war, or the game won't start it", function()
		local war = Load({ cities = { With(CITY, { startsWar = { { x = 50, y = 30, player = 4 } } }) } })

		assert.equal(Failed("Striking there would start a war with player 4."), war.SentientSystems_SiloStrike(0, 44, 30, 50, 30, NUKE))
		assert.equal(Failed("The game won't start that strike."), Load({ cities = { With(CITY, { strikeBlocked = true }) } }).SentientSystems_SiloStrike(0, 44, 30, 50, 30, NUKE))
	end)
end)

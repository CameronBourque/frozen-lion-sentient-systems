local FakeGame = require("FakeGame")
local Game = require("Game")

local UNIT = {
	id = 7405612,
	type = "UNIT_CROSSBOWMAN",
	x = 20,
	y = 20,
	moves = 2,
	-- A crossbowman upgrades through a field cannon to a machine gun.
	upgrade = {
		cost = 180,
		steps = { { to = "UNIT_FIELD_CANNON", tech = "TECH_BALLISTICS" }, { to = "UNIT_MACHINE_GUN", tech = "TECH_MILITARY_TRAINING" } },
	},
}

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, and the techs and civics player 0 has researched.
local function Load(unit, researched)
	local env = Game.new()
	local options = {}

	for i, tech in ipairs({ "TECH_BALLISTICS", "TECH_MILITARY_TRAINING" }) do
		options[i] = { type = tech, researched = researched[tech] == true }
	end

	local civics = { { type = "CIVIC_MILITARY_TRAINING", researched = researched.CIVIC_MILITARY_TRAINING == true } }
	local world = { players = { [0] = { units = { unit }, techs = { options = options }, civics = { options = civics } } } }

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	-- The fake rows have no names, so give each type a text key.
	for _, name in ipairs({ "Units", "Technologies", "Civics" }) do
		for _, row in pairs(env.GameInfo[name]) do
			row.Name = "LOC_" .. (row.UnitType or row.TechnologyType or row.CivicType)
		end
	end

	return env
end

local function With(unit, changes)
	local copy = {}

	for key, value in pairs(unit) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

local function Failed(reason)
	return "{\"ok\":false,\"reason\":\"" .. reason .. "\"}"
end

local function Run(unit, researched)
	local env = Load(unit, researched or { TECH_BALLISTICS = true, TECH_MILITARY_TRAINING = true })

	return env.SentientSystems_UnitAction(0, UNIT.id, "upgrade"), env
end

describe("upgrade", function()
	local READY = With(UNIT, { canEver = { "upgrade" }, canNow = { "upgrade" } })

	it("requests the command the game allows", function()
		local result, env = Run(READY)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, command = env.UnitCommandTypes.UPGRADE } }, env.requests)
	end)

	it("upgrades a unit that is fortified or asleep", function()
		assert.equal("{\"ok\":true}", (Run(With(READY, { activity = "SENTRY" }))))
		assert.equal("{\"ok\":true}", (Run(With(READY, { activity = "SLEEP" }))))
	end)

	it("fails for a kind of unit with no upgrade", function()
		local settler = { id = UNIT.id, type = "UNIT_SETTLER", x = 20, y = 20, moves = 2 }

		assert.equal(Failed("This kind of unit has no upgrade."), (Run(settler)))
	end)

	it("says the unit has no moves left", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(UNIT, { moves = 0 }))))
	end)

	it("names the step of the chain that needs a tech or civic the player lacks", function()
		assert.equal(Failed("The upgrade goes through LOC_UNIT_FIELD_CANNON, which needs LOC_TECH_BALLISTICS."), (Run(UNIT, {})))
		assert.equal(Failed("The upgrade goes through LOC_UNIT_MACHINE_GUN, which needs LOC_TECH_MILITARY_TRAINING."), (Run(UNIT, { TECH_BALLISTICS = true })))

		local civic = With(UNIT, { upgrade = { cost = 180, steps = { { to = "UNIT_FIELD_CANNON", civic = "CIVIC_MILITARY_TRAINING" } } } })

		assert.equal(Failed("The upgrade goes through LOC_UNIT_FIELD_CANNON, which needs LOC_CIVIC_MILITARY_TRAINING."), (Run(civic, {})))
	end)

	it("returns the game's reasons with the unit it makes and the cost", function()
		local short = With(UNIT, { reasons = { "No gold.", "No iron." } })

		assert.equal(Failed("No gold. No iron. Upgrading to LOC_UNIT_MACHINE_GUN costs 180 gold."), (Run(short, { TECH_BALLISTICS = true, TECH_MILITARY_TRAINING = true })))
	end)

	it("cleans the icons and colors from the reasons", function()
		local short = With(UNIT, { reasons = { "No [ICON_Gold] [COLOR_RED]Gold[ENDCOLOR]." } })

		assert.equal(Failed("No Gold. Upgrading to LOC_UNIT_MACHINE_GUN costs 180 gold."), (Run(short, { TECH_BALLISTICS = true, TECH_MILITARY_TRAINING = true })))
	end)

	it("fails without a reason of its own when the game gives none", function()
		assert.equal(Failed("The unit can't upgrade now."), (Run(UNIT)))
	end)
end)

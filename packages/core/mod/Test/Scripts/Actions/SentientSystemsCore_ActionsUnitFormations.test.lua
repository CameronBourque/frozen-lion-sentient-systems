local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local KNIGHT = { id = 7405612, type = "UNIT_KNIGHT", x = 20, y = 20, moves = 4 }
local OTHER = { id = 7405613, type = "UNIT_KNIGHT", x = 21, y = 20, moves = 4 }
local BUILDER = { id = 7405614, type = "UNIT_BUILDER", x = 20, y = 20, moves = 2, formationClass = "FORMATION_CLASS_CIVILIAN" }

-- Returns an environment with the actions loaded into a fake game that has the
-- units for player 0 and the civics player 0 has researched.
local function Load(units, researched)
	local env = Game.new()
	local civics = {}

	for i, civic in ipairs({ "CIVIC_NATIONALISM", "CIVIC_MOBILIZATION" }) do
		civics[i] = { type = civic, researched = researched[civic] == true }
	end

	FakeGame.Install(env, { players = { [0] = { units = units, civics = { options = civics } } } })
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	-- The fake rows have no names, so give each type a text key.
	for _, name in ipairs({ "Units", "Civics" }) do
		for _, row in pairs(env.GameInfo[name]) do
			row.Name = "LOC_" .. (row.UnitType or row.CivicType)
		end
	end

	return env
end

-- Runs the action for the first unit, with the other units in the world.
local function Run(unit, action, other, researched, others)
	local env = Load(others or { unit, OTHER, BUILDER }, researched or { CIVIC_NATIONALISM = true, CIVIC_MOBILIZATION = true })

	return env.SentientSystems_UnitAction(0, unit.id, action, nil, nil, other), env
end

local CAN_JOIN = { { player = 0, id = OTHER.id } }

describe("form_corps and form_army", function()
	local BLOCKED = With(KNIGHT, { partners = CAN_JOIN })
	local READY = With(BLOCKED, { canNow = { "form_corps", "form_army" } })

	it("requests the command with the other unit's player and ID", function()
		for _, action in ipairs({ "form_corps", "form_army" }) do
			local result, env = Run(READY, action, OTHER.id)

			assert.equal("{\"ok\":true}", result)
			assert.same({
				{
					unit = KNIGHT.id,
					command = env.UnitCommandTypes[action:upper()],
					parameters = { [env.UnitCommandTypes.PARAM_UNIT_PLAYER] = 0, [env.UnitCommandTypes.PARAM_UNIT_ID] = OTHER.id },
				},
			}, env.requests)
		end
	end)

	it("names the civic the player lacks", function()
		assert.equal(Failed("LOC_CIVIC_NATIONALISM is needed to form a corps."), (Run(BLOCKED, "form_corps", OTHER.id, {})))
		assert.equal(Failed("LOC_CIVIC_MOBILIZATION is needed to form an army."), (Run(BLOCKED, "form_army", OTHER.id, { CIVIC_NATIONALISM = true })))
	end)

	it("fails for a unit that is not military", function()
		local builder = With(BUILDER, { partners = {} })

		assert.equal(Failed("This kind of unit can't form a corps."), (Run(builder, "form_corps", OTHER.id)))
	end)

	it("says the unit has no moves left", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(BLOCKED, { moves = 0 }), "form_corps", OTHER.id)))
	end)

	it("says no unit can join", function()
		assert.equal(Failed("No unit of the same kind next to it can form a corps with it."), (Run(With(KNIGHT, { partners = {} }), "form_corps", OTHER.id)))
	end)

	it("lists the units that can join when none or another is named", function()
		local reason = "The units that can are LOC_UNIT_KNIGHT " .. OTHER.id .. "."
		local none = Failed("Name the unit to join. " .. reason)
		local wrong = Failed("Unit " .. BUILDER.id .. " can't join. " .. reason)

		assert.equal(none, (Run(BLOCKED, "form_corps")))
		assert.equal(wrong, (Run(BLOCKED, "form_corps", BUILDER.id)))
	end)

	it("fails when the game lists the unit but won't start the command", function()
		assert.equal(Failed("The unit can't form a corps now."), (Run(BLOCKED, "form_corps", OTHER.id)))
	end)
end)

describe("enter_formation", function()
	it("requests the command with the other unit", function()
		local unit = With(KNIGHT, { canNow = { "enter_formation" }, partners = { { player = 0, id = BUILDER.id } } })
		local result, env = Run(unit, "enter_formation", BUILDER.id)

		assert.equal("{\"ok\":true}", result)
		assert.equal(env.UnitCommandTypes.ENTER_FORMATION, env.requests[1].command)
	end)

	it("says no unit on the tile can join", function()
		assert.equal(Failed("No unit on its tile can join a formation with it."), (Run(KNIGHT, "enter_formation", BUILDER.id)))
	end)
end)

describe("exit_formation", function()
	it("requests the command the game allows", function()
		local result, env = Run(With(KNIGHT, { canNow = { "exit_formation" } }), "exit_formation")

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = KNIGHT.id, command = env.UnitCommandTypes.EXIT_FORMATION } }, env.requests)
	end)

	it("says a corps or an army can't be split", function()
		for _, formation in ipairs({ "CORPS_MILITARY_FORMATION", "ARMY_MILITARY_FORMATION" }) do
			assert.equal(Failed("A corps or an army can't be split."), (Run(With(KNIGHT, { formation = formation }), "exit_formation")))
		end
	end)

	it("says the unit is not in a formation", function()
		assert.equal(Failed("The unit is not in a formation with another unit."), (Run(KNIGHT, "exit_formation")))
	end)
end)

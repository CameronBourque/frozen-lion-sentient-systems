local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed = Helpers.Failed

local SUB_TYPES = {
	GREATWORKSLOT_WRITING = { "GREATWORKOBJECT_WRITING" },
	GREATWORKSLOT_MUSIC = { "GREATWORKOBJECT_MUSIC" },
	GREATWORKSLOT_ARTIFACT = { "GREATWORKOBJECT_ARTIFACT" },
	GREATWORKSLOT_ART = { "GREATWORKOBJECT_SCULPTURE" },
	GREATWORKSLOT_PALACE = { "GREATWORKOBJECT_WRITING", "GREATWORKOBJECT_MUSIC" },
}

local function Work(type, objectType, extra)
	local work = { type = type, objectType = objectType, tourism = 2, yields = {}, creator = "A", turn = -100 }

	for key, value in pairs(extra or {}) do
		work[key] = value
	end

	return work
end

local WRITING = "GREATWORKOBJECT_WRITING"
local ARTIFACT = "GREATWORKOBJECT_ARTIFACT"

-- Player 0 has two cities. Home has an amphitheater with a writing work and an
-- empty writing slot, and a broadcast center with a music slot. Capital has a
-- great library with a writing work and an art museum with a new sculpture, and
-- a partial artifact museum. Home also has a full artifact museum and a palace
-- with a music work.
local function Load()
	local env = Game.new()
	local function city(id, x, buildings)
		return {
			id = id,
			name = "City" .. id,
			x = x,
			y = 10,
			population = 5,
			districts = { { type = "DISTRICT_CITY_CENTER", x = x, y = 10, buildings = buildings } },
		}
	end

	FakeGame.Install(env, {
		players = {
			[0] = {
				cities = {
					city(1, 10, {
						{ type = "BUILDING_AMPHITHEATER", slotKinds = { "GREATWORKSLOT_WRITING", "GREATWORKSLOT_WRITING" }, greatWorks = { Work("GREATWORK_A", WRITING) } },
						{ type = "BUILDING_BROADCAST_CENTER", slotKinds = { "GREATWORKSLOT_MUSIC" } },
						{
							type = "BUILDING_MUSEUM_ARTIFACT",
							slotKinds = { "GREATWORKSLOT_ARTIFACT", "GREATWORKSLOT_ARTIFACT" },
							greatWorks = { Work("GREATWORK_X", ARTIFACT), Work("GREATWORK_Y", ARTIFACT) },
						},
						{ type = "BUILDING_PALACE", slotKinds = { "GREATWORKSLOT_PALACE" }, greatWorks = { Work("GREATWORK_M", "GREATWORKOBJECT_MUSIC") } },
					}),
					city(2, 20, {
						{ type = "BUILDING_MUSEUM_ARTIFACT_SMALL", slotKinds = { "GREATWORKSLOT_ARTIFACT", "GREATWORKSLOT_ARTIFACT" }, greatWorks = { Work("GREATWORK_Z", ARTIFACT) } },
						{ type = "BUILDING_GREAT_LIBRARY", slotKinds = { "GREATWORKSLOT_WRITING" }, greatWorks = { Work("GREATWORK_B", WRITING) } },
						{
							type = "BUILDING_MUSEUM_ART",
							slotKinds = { "GREATWORKSLOT_ART", "GREATWORKSLOT_ART" },
							greatWorks = { Work("GREATWORK_S", "GREATWORKOBJECT_SCULPTURE", { turn = 1 }) },
						},
					}),
				},
			},
		},
		validSubTypes = SUB_TYPES,
	})
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the game's index of the work in the building at the slot, as the
-- fake game numbers them.
local function IndexOf(env, building, slot)
	return env.GameInfo.Buildings[building].Index * 100 + slot
end

describe("SentientSystems_MoveGreatWork", function()
	it("sends the screen's request for a move into an empty slot", function()
		local env = Load()
		local P = env.PlayerOperations
		local work = IndexOf(env, "BUILDING_AMPHITHEATER", 0)

		assert.equal("{\"ok\":true}", env.SentientSystems_MoveGreatWork(0, work, 1, "BUILDING_AMPHITHEATER", 1))
		assert.same({
			{
				player = 0,
				operation = P.MOVE_GREAT_WORK,
				parameters = {
					[P.PARAM_PLAYER_ONE] = 0,
					[P.PARAM_CITY_SRC] = 1,
					[P.PARAM_CITY_DEST] = 1,
					[P.PARAM_BUILDING_SRC] = env.GameInfo.Buildings.BUILDING_AMPHITHEATER.Index,
					[P.PARAM_BUILDING_DEST] = env.GameInfo.Buildings.BUILDING_AMPHITHEATER.Index,
					[P.PARAM_GREAT_WORK_INDEX] = work,
					[P.PARAM_SLOT] = 1,
				},
			},
		}, env.requests)
	end)

	it("sends a move to another city, and a swap with the work in the slot", function()
		local env = Load()
		local P = env.PlayerOperations

		assert.equal("{\"ok\":true}", env.SentientSystems_MoveGreatWork(0, IndexOf(env, "BUILDING_AMPHITHEATER", 0), 2, "BUILDING_GREAT_LIBRARY", 0))
		assert.equal(2, env.requests[1].parameters[P.PARAM_CITY_DEST])
		assert.equal(env.GameInfo.Buildings.BUILDING_GREAT_LIBRARY.Index, env.requests[1].parameters[P.PARAM_BUILDING_DEST])
	end)

	it("swaps two artifacts of a full museum", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_MoveGreatWork(0, IndexOf(env, "BUILDING_MUSEUM_ARTIFACT", 0), 1, "BUILDING_MUSEUM_ARTIFACT", 1))
		assert.equal(1, #env.requests)
	end)

	it("fails for a work or slot the player doesn't have", function()
		local env = Load()
		local work = IndexOf(env, "BUILDING_AMPHITHEATER", 0)
		local cases = {
			{ { -5, 1, "BUILDING_AMPHITHEATER", 1 }, "You have no great work -5. Use an index from the great works state." },
			{ { work, 3, "BUILDING_AMPHITHEATER", 1 }, "You have no slot 1 in BUILDING_AMPHITHEATER in city 3. Use a slot from the great works state." },
			{ { work, 1, "BUILDING_GREAT_LIBRARY", 0 }, "You have no slot 0 in BUILDING_GREAT_LIBRARY in city 1. Use a slot from the great works state." },
			{ { work, 1, "BUILDING_AMPHITHEATER", 7 }, "You have no slot 7 in BUILDING_AMPHITHEATER in city 1. Use a slot from the great works state." },
		}

		for _, case in ipairs(cases) do
			assert.equal(Failed(case[2]), env.SentientSystems_MoveGreatWork(0, table.unpack(case[1])))
		end

		assert.same({}, env.requests)
	end)

	it("fails for a move the screen would not allow", function()
		local env = Load()
		local work = IndexOf(env, "BUILDING_AMPHITHEATER", 0)
		local cases = {
			{ { work, 1, "BUILDING_AMPHITHEATER", 0 }, "LOC_GREATWORK_A_NAME is already in that slot." },
			{ { work, 1, "BUILDING_BROADCAST_CENTER", 0 }, "That slot takes GREATWORKOBJECT_MUSIC, and LOC_GREATWORK_A_NAME is GREATWORKOBJECT_WRITING." },
			{ { IndexOf(env, "BUILDING_MUSEUM_ARTIFACT", 0), 1, "BUILDING_AMPHITHEATER", 1 }, "That slot takes GREATWORKOBJECT_WRITING, and LOC_GREATWORK_X_NAME is GREATWORKOBJECT_ARTIFACT." },
			{ { IndexOf(env, "BUILDING_MUSEUM_ART", 0), 2, "BUILDING_MUSEUM_ART", 1 }, "LOC_GREATWORK_S_NAME is locked for 10 more turns." },
			{ { IndexOf(env, "BUILDING_MUSEUM_ARTIFACT_SMALL", 0), 2, "BUILDING_MUSEUM_ARTIFACT_SMALL", 1 }, "LOC_GREATWORK_Z_NAME is an artifact, and its museum isn't full." },
			{
				{ IndexOf(env, "BUILDING_MUSEUM_ARTIFACT", 0), 2, "BUILDING_MUSEUM_ARTIFACT_SMALL", 1 },
				"An artifact can't move to an empty slot. It swaps with another artifact in a full museum.",
			},
			{
				{ IndexOf(env, "BUILDING_MUSEUM_ARTIFACT", 0), 2, "BUILDING_MUSEUM_ARTIFACT_SMALL", 0 },
				"LOC_GREATWORK_Z_NAME is an artifact, and its museum isn't full.",
			},
			{
				{ work, 1, "BUILDING_PALACE", 0 },
				"That slot holds LOC_GREATWORK_M_NAME, which can't swap into a slot that takes GREATWORKOBJECT_WRITING.",
			},
		}

		for _, case in ipairs(cases) do
			assert.equal(Failed(case[2]), env.SentientSystems_MoveGreatWork(0, table.unpack(case[1])))
		end

		assert.same({}, env.requests)
	end)

	it("fails for an ID with no player", function()
		assert.equal(Failed("MoveGreatWork failed: no player 3"), Load().SentientSystems_MoveGreatWork(3, 1, 1, "BUILDING_AMPHITHEATER", 0))
	end)
end)

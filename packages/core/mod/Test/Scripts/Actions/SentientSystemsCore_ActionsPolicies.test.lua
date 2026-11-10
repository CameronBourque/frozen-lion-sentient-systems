local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

-- Policies player 0 can slot, with Diplomatic League and Colonization locked.
local POLICIES = {
	{ type = "POLICY_DISCIPLINE", slot = "SLOT_MILITARY" },
	{ type = "POLICY_SURVEY", slot = "SLOT_MILITARY" },
	{ type = "POLICY_GOD_KING", slot = "SLOT_ECONOMIC" },
	{ type = "POLICY_CHARISMATIC_LEADER", slot = "SLOT_DIPLOMATIC" },
	{ type = "POLICY_INSPIRATION", slot = "SLOT_GREAT_PERSON" },
	{ type = "POLICY_DIPLOMATIC_LEAGUE", slot = "SLOT_DIPLOMATIC", locked = true },
	{ type = "POLICY_COLONIZATION", slot = "SLOT_ECONOMIC", locked = true },
}

-- A government with a military, an economic, and a wildcard slot, and God King
-- in the economic one, with no civic completed this turn.
local NO_CIVIC = {
	type = "GOVERNMENT_CHIEFDOM",
	slots = { { type = "SLOT_MILITARY" }, { type = "SLOT_ECONOMIC", policy = "POLICY_GOD_KING" }, { type = "SLOT_WILDCARD" } },
}

-- The same government on a turn with a civic completed.
local GOVERNMENT = With(NO_CIVIC, { civicThisTurn = "CIVIC_CODE_OF_LAWS" })

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the government, and the other fields of the player and the
-- world.
local function Load(government, player, world)
	local env = Game.new()
	local players = { [0] = With({ government = government or GOVERNMENT, policies = POLICIES }, player or {}) }

	FakeGame.Install(env, With({ players = players }, world or {}))
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	return env
end

-- Returns the request that clears every slot and adds the policy types by
-- slot, from 0.
local function Request(env, types)
	local add = {}

	for slot, typeName in pairs(types) do
		add[slot] = env.GameInfo.Policies[typeName].Hash
	end

	return { player = 0, clear = { 0, 1, 2 }, add = add }
end

describe("SentientSystems_SetPolicies", function()
	it("clears every slot and adds each slot's policy, as the screen does", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetPolicies(0, { [0] = "POLICY_DISCIPLINE", [1] = "POLICY_GOD_KING", [2] = false }))
		assert.same({ Request(env, { [0] = "POLICY_DISCIPLINE", [1] = "POLICY_GOD_KING" }) }, env.requests)
	end)

	it("moves a slotted policy and empties its slot", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetPolicies(0, { [0] = false, [1] = false, [2] = "POLICY_GOD_KING" }))
		assert.same({ Request(env, { [2] = "POLICY_GOD_KING" }) }, env.requests)
	end)

	it("takes any policy in a wildcard slot, and a great person policy only there", function()
		local env = Load()

		assert.equal("{\"ok\":true}", env.SentientSystems_SetPolicies(0, { [0] = "POLICY_SURVEY", [1] = "POLICY_GOD_KING", [2] = "POLICY_CHARISMATIC_LEADER" }))
		assert.equal("{\"ok\":true}", env.SentientSystems_SetPolicies(0, { [0] = false, [1] = "POLICY_GOD_KING", [2] = "POLICY_INSPIRATION" }))
		assert.equal(
			Failed("Slot 0 is a SLOT_MILITARY slot, which can't hold POLICY_INSPIRATION, a SLOT_GREAT_PERSON policy."),
			env.SentientSystems_SetPolicies(0, { [0] = "POLICY_INSPIRATION", [1] = "POLICY_GOD_KING", [2] = false })
		)
	end)

	it("fails for a policy in a slot of another type, and sends nothing", function()
		local env = Load()

		assert.equal(
			Failed("Slot 0 is a SLOT_MILITARY slot, which can't hold POLICY_CHARISMATIC_LEADER, a SLOT_DIPLOMATIC policy."),
			env.SentientSystems_SetPolicies(0, { [0] = "POLICY_CHARISMATIC_LEADER", [1] = "POLICY_GOD_KING", [2] = false })
		)
		assert.same({}, env.requests)
	end)

	it("fails for a policy that isn't unlocked, one that isn't a policy, and one in two slots", function()
		local env = Load()

		assert.equal(
			Failed("POLICY_COLONIZATION isn't one of the policies you can slot. Use a policy from the policies choice, or one in a slot."),
			env.SentientSystems_SetPolicies(0, { [0] = false, [1] = "POLICY_COLONIZATION", [2] = false })
		)
		assert.equal(
			Failed("POLICY_NOPE isn't a policy. Use the type of a policy from the policies choice, or of one in a slot."),
			env.SentientSystems_SetPolicies(0, { [0] = "POLICY_NOPE", [1] = false, [2] = false })
		)
		assert.equal(Failed("POLICY_SURVEY is in more than one slot."), env.SentientSystems_SetPolicies(0, { [0] = "POLICY_SURVEY", [1] = false, [2] = "POLICY_SURVEY" }))
		assert.same({}, env.requests)
	end)

	it("fails unless every slot is listed once, from 0", function()
		local env = Load()
		local reason = Failed("Give a policy, or none, for each of your 3 slots, 0 to 2, as the government choice lists them.")

		assert.equal(reason, env.SentientSystems_SetPolicies(0, { [0] = "POLICY_SURVEY", [1] = "POLICY_GOD_KING" }))
		assert.equal(reason, env.SentientSystems_SetPolicies(0, { [0] = false, [1] = false, [2] = false, [3] = false }))
		assert.equal(reason, env.SentientSystems_SetPolicies(0, { [0] = false, [1] = false, [2] = false, x = false }))
		assert.equal(reason, env.SentientSystems_SetPolicies(0, "POLICY_SURVEY"))
	end)

	it("fails for slots that hold those policies already", function()
		local env = Load()

		assert.equal(Failed("Your slots hold those policies already."), env.SentientSystems_SetPolicies(0, { [0] = false, [1] = "POLICY_GOD_KING", [2] = false }))
		assert.same({}, env.requests)
	end)

	it("fails when the screen allows no change, and points at the unlock when there is one", function()
		local slots = { [0] = "POLICY_SURVEY", [1] = "POLICY_GOD_KING", [2] = false }

		assert.equal(Failed("You can change policies only on a turn you complete a civic, or while a slot is empty."), Load(NO_CIVIC).SentientSystems_SetPolicies(0, slots))
		assert.equal(
			Failed("You can change policies only on a turn you complete a civic, or while a slot is empty. The policies choice's unlock pays for a change now."),
			Load(With(NO_CIVIC, { unlockCost = 50 })).SentientSystems_SetPolicies(0, slots)
		)
		assert.equal(Failed("You changed policies this turn already."), Load(With(GOVERNMENT, { changeMade = true })).SentientSystems_SetPolicies(0, slots))
		assert.equal(Failed("You can't change policies while it isn't your turn."), Load(nil, { noStrategicCommands = true }).SentientSystems_SetPolicies(0, slots))
	end)

	it("allows a change with an empty slot and no civic this turn", function()
		local env = Load(With(NO_CIVIC, { slotsOpen = 1 }))

		assert.equal("{\"ok\":true}", env.SentientSystems_SetPolicies(0, { [0] = "POLICY_SURVEY", [1] = "POLICY_GOD_KING", [2] = false }))
	end)
end)

describe("SentientSystems_UnlockPolicies", function()
	-- No civic this turn, with the unlock for 50.
	local LOCKED = With(NO_CIVIC, { unlockCost = 50 })

	it("sends the unlock button's request", function()
		local env = Load(LOCKED, { gold = 50 })

		assert.equal("{\"ok\":true}", env.SentientSystems_UnlockPolicies(0))
		assert.same({ { player = 0, operation = env.PlayerOperations.UNLOCK_POLICIES, parameters = {} } }, env.requests)
	end)

	it("fails for an unlock the player can't afford, and sends nothing", function()
		local env = Load(LOCKED, { gold = 49 })

		assert.equal(Failed("You can't afford the unlock's 50 gold."), env.SentientSystems_UnlockPolicies(0))
		assert.equal(Failed("You can't afford the unlock's 50 faith."), Load(LOCKED, { gold = 50, faith = 49 }, { unlockWithFaith = true }).SentientSystems_UnlockPolicies(0))
		assert.same({}, env.requests)
	end)

	it("fails while the World Congress is in session", function()
		local env = Load(LOCKED, { gold = 50 }, { expansion2 = true, congressInSession = true })

		assert.equal(Failed("You can't pay the unlock while the World Congress is in session."), env.SentientSystems_UnlockPolicies(0))
	end)

	it("fails with no unlock, after a change this turn, and on another's turn", function()
		assert.equal(Failed("There's no unlock to pay for now."), Load(GOVERNMENT, { gold = 50 }).SentientSystems_UnlockPolicies(0))
		assert.equal(Failed("You changed policies this turn already."), Load(With(LOCKED, { changeMade = true }), { gold = 50 }).SentientSystems_UnlockPolicies(0))
		assert.equal(Failed("You can't pay the unlock while it isn't your turn."), Load(LOCKED, { gold = 50, noStrategicCommands = true }).SentientSystems_UnlockPolicies(0))
	end)
end)

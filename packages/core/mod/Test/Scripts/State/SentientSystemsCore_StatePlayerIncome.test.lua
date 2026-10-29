local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns a tooltip line, as the game's English text has it, such as "+33 from Envoys".
local function Line(amount, label)
	return (amount >= 0 and "+" or "") .. amount .. " from " .. label
end

-- Returns the income section JSON for player 0, whose data is given, and the other players, or nil
-- when there is none.
local function IncomeWith(data, world)
	local env = Game.new()
	local setup = { players = { [0] = data, [4] = {} }, text = { LOC_UNIT_MUSKETMAN_NAME = "Musketman" } }

	for key, value in pairs(world or {}) do
		setup[key] = value
	end

	FakeGame.Install(env, setup)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"income\":(%b{})")
end

describe("SentientSystems_GetIncomeState", function()
	it("reads each source from the yield's tooltip", function()
		local json = IncomeWith({
			gold = 100,
			goldPerTurn = 475.08,
			upkeep = 210,
			tooltips = {
				gold = Line(22, "Deals") .. "[NEWLINE] [ICON_Bullet]+5 from Menelik II for 19 turns[NEWLINE]"
					.. Line(33, "[ICON_Envoy] Envoys") .. "[NEWLINE]" .. Line(420, "Cities"),
				faith = Line(4, "Cities") .. "[NEWLINE]" .. Line(5.5, "peaceful religion founders"),
			},
			faithPerTurn = 9.5,
			science = 12,
			culture = 3,
		})

		assert.truthy(json:find("\"gold\":{\"cities\":420,\"deals\":22,\"envoys\":33,\"total\":475.1}", 1, true))
		assert.truthy(json:find("\"faith\":{\"cities\":4,\"founders\":5.5,\"total\":9.5}", 1, true))
		assert.truthy(json:find("\"science\":{\"other\":12,\"total\":12}", 1, true))
		assert.truthy(json:find("\"culture\":{\"other\":3,\"total\":3}", 1, true))
	end)

	it("leaves a line it has no label for to other", function()
		local json = IncomeWith({ goldPerTurn = 9, tooltips = { gold = "+9 from something new" } })

		assert.truthy(json:find("\"gold\":{\"other\":9,\"total\":9}", 1, true))
	end)

	it("reads the game's own Other line, and a negative amount", function()
		local json = IncomeWith({ goldPerTurn = 3, tooltips = { gold = Line(-2, "Other") .. "[NEWLINE]" .. Line(5, "Cities") } })

		assert.truthy(json:find("\"gold\":{\"cities\":5,\"other\":-2,\"total\":3}", 1, true))
	end)

	it("adds what the lines don't give to other, when it is at least half a point", function()
		local json = IncomeWith({ goldPerTurn = 40.5, tooltips = { gold = Line(40, "Cities") } })

		assert.truthy(json:find("\"gold\":{\"cities\":40,\"other\":0.5,\"total\":40.5}", 1, true))

		local rounded = IncomeWith({ goldPerTurn = 40.3, tooltips = { gold = Line(40, "Cities") } })

		assert.truthy(rounded:find("\"gold\":{\"cities\":40,\"total\":40.3}", 1, true))
	end)

	it("counts the upkeep of built districts and buildings that aren't pillaged", function()
		local json = IncomeWith({
			upkeep = 5,
			cities = {
				{
					id = 1,
					districts = {
						{ type = "DISTRICT_INDUSTRIAL_ZONE", x = 3, y = 4, buildings = { { type = "BUILDING_FACTORY" }, { type = "BUILDING_WORKSHOP", pillaged = true } } },
						{ type = "DISTRICT_HARBOR", x = 5, y = 5, complete = false, buildings = {} },
						{ type = "DISTRICT_ENCAMPMENT", x = 6, y = 6, pillaged = true, buildings = {} },
					},
				},
			},
		}, { maintenance = { DISTRICT_INDUSTRIAL_ZONE = 1, BUILDING_FACTORY = 2, BUILDING_WORKSHOP = 1, DISTRICT_HARBOR = 1, DISTRICT_ENCAMPMENT = 1 } })

		assert.truthy(json:find("\"expenses\":{\"cities\":3,\"deals\":0,\"other\":2,\"total\":5,\"units\":0}", 1, true))
	end)

	it("groups unit upkeep by type and formation, less the discount, standard units first", function()
		local json = IncomeWith({
			upkeep = 15,
			unitDiscount = 1,
			units = {
				{ id = 1, type = "UNIT_MUSKETMAN", x = 1, y = 1 },
				{ id = 2, type = "UNIT_MUSKETMAN", x = 1, y = 2 },
				{ id = 3, type = "UNIT_MUSKETMAN", x = 1, y = 3, formation = "CORPS_MILITARY_FORMATION" },
				{ id = 4, type = "UNIT_BOMBARD", x = 1, y = 4, formation = "ARMY_MILITARY_FORMATION" },
				{ id = 5, type = "UNIT_BUILDER", x = 1, y = 5 },
				{ id = 6, type = "UNIT_SCOUT", x = 1, y = 6 },
			},
		}, { unitMaintenance = { UNIT_MUSKETMAN = { unit = 3, corps = 5 }, UNIT_BOMBARD = { army = 8 }, UNIT_BUILDER = { unit = 1 } } })

		assert.truthy(json:find("\"unitUpkeep\":[{\"count\":1,\"formation\":\"ARMY\",\"gold\":7,\"name\":\"LOC_UNIT_BOMBARD_NAME\",\"type\":\"UNIT_BOMBARD\"},"
			.. "{\"count\":2,\"gold\":4,\"name\":\"Musketman\",\"type\":\"UNIT_MUSKETMAN\"},"
			.. "{\"count\":1,\"formation\":\"CORPS\",\"gold\":4,\"name\":\"Musketman\",\"type\":\"UNIT_MUSKETMAN\"}]", 1, true))
		assert.truthy(json:find("\"units\":15", 1, true))
	end)

	it("lists the gold deals with their turns left, and counts what the player pays", function()
		local json = IncomeWith({
			upkeep = 5,
			deals = {
				{ player = 4, gold = 5, duration = 30, enacted = 70, outgoing = true },
				{ player = 4, gold = 3, duration = 30, enacted = 73 },
				{ player = 4, gold = 9, duration = 0, enacted = 73 },
			},
		}, { turn = 85 })

		assert.truthy(json:find("\"deals\":[{\"gold\":-5,\"player\":4,\"turnsLeft\":15},{\"gold\":3,\"player\":4,\"turnsLeft\":18}]", 1, true))
		assert.truthy(json:find("\"expenses\":{\"cities\":0,\"deals\":5,\"total\":5,\"units\":0}", 1, true))
	end)
end)

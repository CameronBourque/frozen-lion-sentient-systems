local FakeGame = require("FakeGame")
local Game = require("Game")

-- A city with one building of the district type and the data it adds.
local function City(buildings)
	return {
		id = 1,
		name = "Home",
		x = 10,
		y = 10,
		population = 5,
		districts = { { type = "DISTRICT_CITY_CENTER", x = 10, y = 10, buildings = buildings } },
	}
end

-- Returns the great works section JSON for player 0 with one city. The theming
-- is the player's, and subTypes the object types of each slot kind.
local function GreatWorksWith(buildings, theming, subTypes)
	local env = Game.new()

	FakeGame.Install(env, {
		players = { [0] = { cities = { City(buildings) }, theming = theming } },
		validSubTypes = subTypes,
	})
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"greatWorks\":(%b{})")
end

local function Work(type, extra)
	local work = { type = type, objectType = "GREATWORKOBJECT_SCULPTURE", tourism = 2, yields = { CULTURE = 3 }, creator = "A", turn = -100 }

	for key, value in pairs(extra or {}) do
		work[key] = value
	end

	return work
end

local ART_RULES = { ThemingUniquePerson = true, ThemingSameObjectType = true, ThemingYieldMultiplier = 100, ThemingTourismMultiplier = 100 }
local ARTIFACT_RULES = { ThemingSameEras = true, ThemingUniqueCivs = true, ThemingYieldMultiplier = 100, ThemingTourismMultiplier = 100 }

describe("SentientSystems_GetGreatWorkState", function()
	it("lists every slot with its work, the building's theme, and the totals", function()
		local json = GreatWorksWith({
			{
				type = "BUILDING_MUSEUM_ART",
				theme = "LOC_THEME",
				rules = ART_RULES,
				slotKinds = { "GREATWORKSLOT_ART", "GREATWORKSLOT_ART", "GREATWORKSLOT_ART" },
				greatWorks = { Work("GREATWORK_A"), Work("GREATWORK_B", { creator = "B" }) },
			},
		})

		assert.truthy(json:find("\"works\":2", 1, true))
		assert.truthy(json:find("\"spaces\":3", 1, true))
		assert.truthy(json:find("\"kind\":\"GREATWORKSLOT_ART\"", 1, true))
		assert.truthy(json:find("\"themedWorks\":2", 1, true))
		assert.truthy(json:find("\"bonus\":\"LOC_THEME\"", 1, true))
		assert.truthy(json:find("\"themed\":true", 1, true))
		assert.truthy(json:find("\"provides\":[{\"amount\":4,\"type\":\"TOURISM\"},{\"amount\":6,\"type\":\"YIELD_CULTURE\"}]", 1, true))
	end)

	it("gives the rules of a full theme from the building's data", function()
		local json = GreatWorksWith({
			{ type = "BUILDING_MUSEUM_ARTIFACT", theme = "LOC_THEME", rules = ARTIFACT_RULES, slotKinds = { "GREATWORKSLOT_ARTIFACT" } },
		})

		assert.truthy(json:find(
			"\"rules\":{\"sameEra\":true,\"sameObjectType\":false,\"tourismMultiplier\":100,"
				.. "\"uniqueCivilizations\":true,\"uniqueCreators\":false,\"yieldMultiplier\":100}",
			1,
			true
		))
	end)

	it("lists the object types each slot takes, so a wonder can mix kinds", function()
		local json = GreatWorksWith({
			{ type = "BUILDING_BROADWAY", slotKinds = { "GREATWORKSLOT_WRITING", "GREATWORKSLOT_MUSIC", "GREATWORKSLOT_MUSIC" } },
			{ type = "BUILDING_HERMITAGE", slotKinds = { "GREATWORKSLOT_ART" } },
			{ type = "BUILDING_PALACE", slotKinds = { "GREATWORKSLOT_PALACE" } },
		}, nil, {
			GREATWORKSLOT_WRITING = { "GREATWORKOBJECT_WRITING" },
			GREATWORKSLOT_MUSIC = { "GREATWORKOBJECT_MUSIC" },
			GREATWORKSLOT_ART = { "GREATWORKOBJECT_SCULPTURE", "GREATWORKOBJECT_PORTRAIT" },
			GREATWORKSLOT_PALACE = { "GREATWORKOBJECT_WRITING", "GREATWORKOBJECT_MUSIC", "GREATWORKOBJECT_SCULPTURE" },
		})

		assert.truthy(json:find("\"accepts\":[\"GREATWORKOBJECT_MUSIC\"],\"building\":\"BUILDING_BROADWAY\"", 1, true))
		assert.truthy(json:find("\"accepts\":[\"GREATWORKOBJECT_WRITING\"],\"building\":\"BUILDING_BROADWAY\"", 1, true))
		assert.truthy(json:find("\"accepts\":[\"GREATWORKOBJECT_SCULPTURE\",\"GREATWORKOBJECT_PORTRAIT\"],\"building\":\"BUILDING_HERMITAGE\"", 1, true))
		assert.truthy(
			json:find(
				"\"accepts\":[\"GREATWORKOBJECT_WRITING\",\"GREATWORKOBJECT_MUSIC\",\"GREATWORKOBJECT_SCULPTURE\"],\"building\":\"BUILDING_PALACE\"",
				1,
				true
			)
		)
	end)

	it("gives a building with no theme bonus no theme, and no themed flag on its works", function()
		local json = GreatWorksWith({ { type = "BUILDING_PALACE", slotKinds = { "GREATWORKSLOT_PALACE" }, greatWorks = { Work("GREATWORK_A") } } })

		assert.is_nil(json:find("\"theme\"", 1, true))
		assert.is_nil(json:find("\"themed\"", 1, true))
	end)

	it("leaves a work out of the theme when its creator repeats", function()
		local json = GreatWorksWith({
			{ type = "BUILDING_MUSEUM_ART", theme = "LOC_THEME", rules = ART_RULES, greatWorks = { Work("GREATWORK_A"), Work("GREATWORK_B") } },
		})

		assert.truthy(json:find("\"themedWorks\":1", 1, true))
		assert.truthy(json:find("\"themed\":false", 1, true))
	end)

	it("leaves a work out of the theme when its object type differs from the first", function()
		local json = GreatWorksWith({
			{
				type = "BUILDING_MUSEUM_ART",
				theme = "LOC_THEME",
				rules = ART_RULES,
				greatWorks = { Work("GREATWORK_A"), Work("GREATWORK_B", { creator = "B", objectType = "GREATWORKOBJECT_PORTRAIT" }) },
			},
		})

		assert.truthy(json:find("\"themedWorks\":1", 1, true))
	end)

	it("counts an artifact museum's works of one era from different civilizations", function()
		local json = GreatWorksWith({
			{
				type = "BUILDING_MUSEUM_ARTIFACT",
				theme = "LOC_THEME",
				rules = ARTIFACT_RULES,
				greatWorks = {
					Work("GREATWORK_A", { era = "ERA_ANCIENT", owner = 1 }),
					Work("GREATWORK_B", { era = "ERA_ANCIENT", owner = 2 }),
					Work("GREATWORK_C", { era = "ERA_CLASSICAL", owner = 3 }),
				},
			},
		})

		assert.truthy(json:find("\"themedWorks\":2", 1, true))
	end)

	it("counts the works of an artifact museum with a repeated civilization as the first only", function()
		local json = GreatWorksWith({
			{
				type = "BUILDING_MUSEUM_ARTIFACT",
				theme = "LOC_THEME",
				rules = ARTIFACT_RULES,
				greatWorks = { Work("GREATWORK_A", { era = "ERA_ANCIENT", owner = 1 }), Work("GREATWORK_B", { era = "ERA_ANCIENT", owner = 1 }) },
			},
		})

		assert.truthy(json:find("\"themedWorks\":1", 1, true))
	end)

	it("counts every work under auto theming, and names the full museum bonus", function()
		local json = GreatWorksWith({
			{ type = "BUILDING_MUSEUM_ART", greatWorks = { Work("GREATWORK_A"), Work("GREATWORK_B") } },
		}, { autoEligible = true })

		assert.truthy(json:find("\"themedWorks\":2", 1, true))
		assert.truthy(json:find("\"bonus\":\"LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM\"", 1, true))
		assert.is_nil(json:find("\"rules\"", 1, true))
	end)

	it("names the full museum bonus for the auto themed building", function()
		local json = GreatWorksWith({ { type = "BUILDING_MUSEUM_ART", slotKinds = { "GREATWORKSLOT_ART" } } }, { autoThemed = "BUILDING_MUSEUM_ART" })

		assert.truthy(json:find("\"bonus\":\"LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM\"", 1, true))
	end)

	it("counts every work of a building that is themed correctly, and adds religious tourism", function()
		local json = GreatWorksWith({
			{
				type = "BUILDING_AMPHITHEATER",
				theme = "LOC_THEME",
				rules = ART_RULES,
				themed = true,
				religiousTourism = 3,
				greatWorks = { Work("GREATWORK_A"), Work("GREATWORK_B") },
			},
		})

		assert.truthy(json:find("\"complete\":true", 1, true))
		assert.truthy(json:find("\"themedWorks\":2", 1, true))
		assert.truthy(json:find("\"tourism\":7", 1, true))
	end)

	it("locks art for the turns after it was created or moved, and no other work", function()
		local json = GreatWorksWith({
			{
				type = "BUILDING_AMPHITHEATER",
				greatWorks = { Work("GREATWORK_A", { turn = 1 }), Work("GREATWORK_B", { turn = 1, objectType = "GREATWORKOBJECT_WRITING" }) },
			},
		})

		assert.truthy(json:find("\"lockedTurns\":10", 1, true))
		assert.truthy(json:find("\"lockedTurns\":0", 1, true))
		assert.truthy(json:find("\"movable\":false", 1, true))
		assert.truthy(json:find("\"movable\":true", 1, true))
	end)

	it("moves an artifact only from a full museum", function()
		local artifact = { objectType = "GREATWORKOBJECT_ARTIFACT" }
		local partial = GreatWorksWith({
			{ type = "BUILDING_MUSEUM_ARTIFACT", slotKinds = { "GREATWORKSLOT_ARTIFACT", "GREATWORKSLOT_ARTIFACT" }, greatWorks = { Work("GREATWORK_A", artifact) } },
		})
		local full = GreatWorksWith({
			{ type = "BUILDING_MUSEUM_ARTIFACT", greatWorks = { Work("GREATWORK_A", artifact), Work("GREATWORK_B", artifact) } },
		})

		assert.truthy(partial:find("\"movable\":false", 1, true))
		assert.truthy(full:find("\"movable\":true", 1, true))
		assert.is_nil(full:find("\"movable\":false", 1, true))
	end)

	it("leaves out a building with no slots", function()
		local json = GreatWorksWith({ { type = "BUILDING_MONUMENT" } })

		assert.equal("{\"buildings\":[],\"provides\":[],\"slots\":[],\"spaces\":0,\"works\":0}", json)
	end)
end)

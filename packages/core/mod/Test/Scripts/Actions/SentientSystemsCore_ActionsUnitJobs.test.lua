local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

local Failed, With = Helpers.Failed, Helpers.With

local UNIT = { id = 7405612, type = "UNIT_BUILDER", x = 20, y = 20, moves = 2, charges = 3 }
local ENGINEER = { id = 7405612, type = "UNIT_MILITARY_ENGINEER", x = 20, y = 20, moves = 2, charges = 3 }

-- Returns an environment with the actions loaded into a fake game that has
-- player 0 with the unit, the given plots, and the techs player 0 has
-- researched.
local function Load(unit, plots, techs)
	local env = Game.new()
	local options, researched = {}, {}

	for _, tech in ipairs(techs or {}) do
		researched[tech] = true
	end

	-- Every tech the tests name has a row, and only some are researched.
	for i, tech in ipairs({ "TECH_BRONZE_WORKING", "TECH_MINING", "TECH_POTTERY" }) do
		options[i] = { type = tech, researched = researched[tech] == true }
	end

	local hidden = {}

	-- Iron is the resource the player's techs don't reveal yet.
	for _, plot in ipairs(plots or {}) do
		if plot.resource == "RESOURCE_IRON" then
			hidden = { "RESOURCE_IRON" }
		end
	end

	local world = { players = { [0] = { units = { unit }, techs = { options = options }, hiddenResources = hidden } }, plots = plots }

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/Actions/SentientSystemsCore_Actions.lua")

	-- The fake rows have no names, so give each type a text key.
	for _, name in ipairs({ "Features", "Resources", "Routes", "Technologies" }) do
		for _, row in pairs(env.GameInfo[name]) do
			row.Name = "LOC_" .. (row.FeatureType or row.ResourceType or row.RouteType or row.TechnologyType)
		end
	end

	return env
end

local function Plot(changes)
	return With({ x = 20, y = 20, terrain = "TERRAIN_GRASS" }, changes or {})
end

local function Hash(env, operationType)
	return env.GameInfo.UnitOperations[operationType].Hash
end

-- Sets a feature's rules, which the fake leaves out.
local function SetFeature(env, featureType, changes)
	for _, row in pairs(env.GameInfo.Features) do
		if row.FeatureType == featureType then
			for key, value in pairs(changes) do
				row[key] = value
			end
		end
	end
end

-- Gives the harvest of a resource, as GameInfo.Resource_Harvests does.
local function AddHarvest(env, resourceType, techType)
	local rows = { { ResourceType = resourceType, YieldType = "YIELD_FOOD", Amount = 20, PrereqTech = techType } }

	env.GameInfo.Resource_Harvests = function()
		local i = 0

		return function()
			i = i + 1

			return rows[i]
		end
	end
end

-- Runs the action for the unit on a plot and returns the result.
local function Run(unit, action, plot, techs, setup, type)
	local env = Load(unit, plot and { plot } or nil, techs)

	if setup ~= nil then
		setup(env)
	end

	return env.SentientSystems_UnitAction(0, UNIT.id, action, nil, nil, type), env
end

describe("build_road", function()
	local READY = With(ENGINEER, { canNow = { "build_road" }, route = "ROUTE_RAILROAD" })

	it("requests the operation the game allows", function()
		local result, env = Run(READY, "build_road")

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_BUILD_ROUTE") } }, env.requests)
	end)

	it("takes the route the game would build, and names it when type is another", function()
		assert.equal("{\"ok\":true}", Run(READY, "build_road", nil, nil, nil, "ROUTE_RAILROAD"))
		assert.equal(Failed("The unit would build ROUTE_RAILROAD, not ROUTE_ANCIENT_ROAD."), (Run(READY, "build_road", nil, nil, nil, "ROUTE_ANCIENT_ROAD")))
	end)

	it("fails for a unit that could never build a road", function()
		assert.equal(Failed("This kind of unit can't build roads."), (Run(UNIT, "build_road")))
	end)

	it("explains the tile", function()
		local has = Plot({ route = "ROUTE_RAILROAD" })

		assert.equal(Failed("The unit has no moves left."), (Run(With(ENGINEER, { moves = 0 }), "build_road")))
		assert.equal(Failed("A road can't be built on water."), (Run(ENGINEER, "build_road", Plot({ water = true }))))
		assert.equal(Failed("The tile has LOC_ROUTE_RAILROAD, and the unit can't build a better route."), (Run(ENGINEER, "build_road", has)))
		assert.equal(Failed("The unit can't build roads now."), (Run(ENGINEER, "build_road", With(has, { routePillaged = true }))))
	end)
end)

describe("remove_feature", function()
	local READY = With(UNIT, { canNow = { "remove_feature" } })
	local FOREST = Plot({ feature = "FEATURE_FOREST", owner = 0 })

	local function Setup(env)
		SetFeature(env, "FEATURE_FOREST", { Removable = true, RemoveTech = "TECH_MINING" })
	end

	it("requests the operation the game allows", function()
		local result, env = Run(READY, "remove_feature", FOREST, { "TECH_MINING" }, Setup)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_REMOVE_FEATURE") } }, env.requests)
	end)

	it("fails for a unit that could never remove one", function()
		assert.equal(Failed("This kind of unit can't remove features."), (Run(With(UNIT, { type = "UNIT_KNIGHT" }), "remove_feature", FOREST, { "TECH_MINING" }, Setup)))
	end)

	it("explains the tile", function()
		local function Reason(unit, plot, techs, removable)
			return (Run(unit, "remove_feature", plot, techs or { "TECH_MINING" }, function(env)
				SetFeature(env, "FEATURE_FOREST", { Removable = removable ~= false, RemoveTech = "TECH_MINING" })
			end))
		end

		assert.equal(Failed("The unit has no moves left."), Reason(With(UNIT, { moves = 0 }), FOREST))
		assert.equal(Failed("The unit has no build charges left."), Reason(With(UNIT, { charges = 0 }), FOREST))
		assert.equal(Failed("There is no feature on the tile."), Reason(UNIT, Plot({ owner = 0 })))
		assert.equal(Failed("LOC_FEATURE_FOREST can't be removed."), Reason(UNIT, FOREST, nil, false))
		assert.equal(Failed("Removing LOC_FEATURE_FOREST needs LOC_TECH_MINING."), Reason(UNIT, FOREST, { "TECH_BRONZE_WORKING" }))
		assert.equal(Failed("Remove the improvement first."), Reason(UNIT, With(FOREST, { improvement = "IMPROVEMENT_CAMP" })))
		assert.equal(Failed("The tile is outside your borders."), Reason(UNIT, With(FOREST, { owner = -1 })))
		assert.equal(Failed("Another player owns the tile."), Reason(UNIT, With(FOREST, { owner = 3 })))
		assert.equal(Failed("The unit can't remove features now."), Reason(UNIT, FOREST))
	end)
end)

describe("harvest", function()
	local READY = With(UNIT, { canNow = { "harvest" } })
	local WHEAT = Plot({ resource = "RESOURCE_WHEAT", owner = 0 })

	local function Reason(unit, plot, techs, harvestTech)
		return (Run(unit, "harvest", plot, techs or { "TECH_POTTERY" }, function(env)
			if harvestTech ~= false then
				AddHarvest(env, "RESOURCE_WHEAT", harvestTech or "TECH_POTTERY")
			else
				AddHarvest(env, "RESOURCE_OTHER")
			end
		end))
	end

	it("requests the operation the game allows", function()
		local result, env = Run(READY, "harvest", WHEAT, { "TECH_POTTERY" }, function(setup)
			AddHarvest(setup, "RESOURCE_WHEAT", "TECH_POTTERY")
		end)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_HARVEST_RESOURCE") } }, env.requests)
	end)

	it("fails for a unit that could never harvest", function()
		assert.equal(Failed("This kind of unit can't harvest resources."), Reason(With(UNIT, { type = "UNIT_KNIGHT" }), WHEAT))
	end)

	it("explains the tile", function()
		assert.equal(Failed("The unit has no moves left."), Reason(With(UNIT, { moves = 0 }), WHEAT))
		assert.equal(Failed("The unit has no build charges left."), Reason(With(UNIT, { charges = 0 }), WHEAT))
		assert.equal(Failed("There is no resource on the tile."), Reason(UNIT, Plot({ owner = 0 })))
		assert.equal(Failed("LOC_RESOURCE_WHEAT can't be harvested."), Reason(UNIT, WHEAT, nil, false))
		assert.equal(Failed("Harvesting LOC_RESOURCE_WHEAT needs LOC_TECH_POTTERY."), Reason(UNIT, WHEAT, { "TECH_MINING" }))
		assert.equal(Failed("Remove the improvement first."), Reason(UNIT, With(WHEAT, { improvement = "IMPROVEMENT_FARM" })))
		assert.equal(Failed("The unit can't harvest resources now."), Reason(UNIT, WHEAT))
	end)

	it("doesn't name a resource the player can't see yet", function()
		assert.equal(Failed("There is no resource on the tile."), Reason(UNIT, Plot({ resource = "RESOURCE_IRON", owner = 0 })))
	end)
end)

describe("repair", function()
	local PILLAGED = Plot({ improvement = "IMPROVEMENT_FARM", improvementPillaged = true, owner = 0 })

	it("repairs a pillaged improvement", function()
		local result, env = Run(With(UNIT, { canNow = { "repair" } }), "repair", PILLAGED)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_REPAIR") } }, env.requests)
	end)

	it("repairs a pillaged route when the improvement is whole", function()
		local plot = Plot({ route = "ROUTE_ANCIENT_ROAD", routePillaged = true })
		local result, env = Run(With(ENGINEER, { canNow = { "repair_route" } }), "repair", plot)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_REPAIR_ROUTE") } }, env.requests)
	end)

	it("repairs the improvement first when both are pillaged", function()
		local _, env = Run(With(UNIT, { canNow = { "repair" } }), "repair", With(PILLAGED, { route = "ROUTE_ANCIENT_ROAD", routePillaged = true }))

		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_REPAIR") } }, env.requests)
	end)

	it("fails for a unit that could never repair", function()
		assert.equal(Failed("This kind of unit can't repair."), (Run(With(UNIT, { type = "UNIT_KNIGHT" }), "repair", PILLAGED)))
	end)

	it("explains the tile, and gives the reason the game gives", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(UNIT, { moves = 0 }), "repair", PILLAGED)))
		assert.equal(Failed("Nothing on the tile is pillaged."), (Run(UNIT, "repair", Plot({ improvement = "IMPROVEMENT_FARM" }))))
		assert.equal(Failed("Nothing on the tile is pillaged."), (Run(UNIT, "repair")))
		assert.equal(Failed("LOC_DROUGHT LOC_DROUGHT_MORE"), (Run(With(UNIT, { reasons = { "LOC_DROUGHT", "LOC_DROUGHT_MORE" } }), "repair", PILLAGED)))
		assert.equal(Failed("-Drought hurts."), (Run(With(UNIT, { reasons = { "[ICON_Bullet][COLOR_RED]Drought[ENDCOLOR] hurts." } }), "repair", PILLAGED)))
		assert.equal(Failed("The unit can't repair now."), (Run(UNIT, "repair", PILLAGED)))
	end)
end)

describe("remove_improvement", function()
	local FARM = Plot({ improvement = "IMPROVEMENT_FARM", owner = 0 })

	it("requests the operation the game allows", function()
		local result, env = Run(With(UNIT, { canNow = { "remove_improvement" } }), "remove_improvement", FARM)

		assert.equal("{\"ok\":true}", result)
		assert.same({ { unit = UNIT.id, operation = Hash(env, "UNITOPERATION_REMOVE_IMPROVEMENT") } }, env.requests)
	end)

	it("fails for a unit that could never remove one", function()
		assert.equal(Failed("This kind of unit can't remove improvements."), (Run(With(UNIT, { type = "UNIT_KNIGHT" }), "remove_improvement", FARM)))
	end)

	it("explains the tile", function()
		assert.equal(Failed("The unit has no moves left."), (Run(With(UNIT, { moves = 0 }), "remove_improvement", FARM)))
		assert.equal(Failed("There is no improvement on the tile."), (Run(UNIT, "remove_improvement")))
		assert.equal(Failed("The unit can't remove improvements now."), (Run(UNIT, "remove_improvement", FARM)))
	end)

	it("tells a sleeping builder to wake first", function()
		local unit = With(UNIT, { activity = "SLEEP", canNow = { "wake" }, canEver = { "wake" } })

		assert.equal(Failed("The unit is sleeping. Wake it first."), (Run(unit, "remove_improvement", FARM)))
	end)
end)

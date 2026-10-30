local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the culture entries of player 0 in a world.
local function CultureOf(players)
	local env = Game.new()

	FakeGame.Install(env, { players = players })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"culture\":(%b[])")
end

-- Returns the entry of a player in a list of entries, or the unmet one for nil.
local function Entry(json, id)
	for entry in json:gmatch("%b{}") do
		if id == nil and entry:find("\"unmet\":true", 1, true) then
			return entry
		elseif id ~= nil and entry:find("\"player\":" .. id .. ",", 1, true) then
			return entry
		end
	end
end

local TOOLTIP = "[ICON_Tourism] Tourism: 73 (current)[NEWLINE][ICON_Tourism] Tourism: 0 (lifetime)"
	.. "[NEWLINE][NEWLINE]Overall [ICON_Tourism] Tourism Reduced 5"

describe("SentientSystems_GetCultureDetails", function()
	it("lists the tourists, and what the viewing player sends, with the tooltip's lines", function()
		local json = CultureOf({
			[0] = {
				met = { 1 },
				domesticTourists = 7,
				touristsFrom = { [1] = 5 },
				touristsFromTooltip = { [1] = TOOLTIP },
			},
			[1] = { domesticTourists = 3, visitingTourists = 2 },
		})

		assert.equal(
			"{\"culturePerTurn\":0,\"domesticTourists\":3,\"player\":1,\"progress\":0,\"requiredTourists\":8,"
				.. "\"tourismBreakdown\":[\"Tourism: 73 (current)\",\"Tourism: 0 (lifetime)\",\"Overall Tourism Reduced 5\"],"
				.. "\"tourismPerTurn\":0,\"touristsFromYou\":5,\"visitingTourists\":2}",
			Entry(json, 1)
		)
		assert.equal(
			"{\"culturePerTurn\":0,\"domesticTourists\":7,\"player\":0,\"progress\":0,\"requiredTourists\":4,"
				.. "\"tourismPerTurn\":0,\"visitingTourists\":0}",
			Entry(json, 0)
		)
	end)

	it("needs one more than the most domestic tourists of any other team", function()
		local json = CultureOf({
			[0] = { met = { 1, 2 }, team = 5, domesticTourists = 1 },
			[1] = { team = 5, domesticTourists = 9 },
			[2] = { domesticTourists = 3 },
		})

		assert.truthy(Entry(json, 0):find("\"requiredTourists\":4", 1, true))
		assert.truthy(Entry(json, 2):find("\"requiredTourists\":10", 1, true))
	end)

	it("shows the tourists of a player that has not been met, without their ID or the rest", function()
		local json = CultureOf({
			[0] = { dominantOver = { 1 } },
			[1] = { domesticTourists = 2, turnsToVictory = 6 },
		})

		assert.equal(
			"{\"domesticTourists\":2,\"requiredTourists\":1,\"touristsFromYou\":0,\"unmet\":true,\"visitingTourists\":0}",
			Entry(json)
		)
	end)

	it("adds the turns to victory, and who dominates whom, for players that have been met", function()
		local json = CultureOf({
			[0] = { met = { 1, 2, 3, 4 }, dominantOver = { 1 } },
			[1] = { turnsToVictory = 12 },
			[2] = { dominantOver = { 0 } },
			[3] = { dominantOver = { 0 } },
			[4] = {},
		})

		assert.truthy(Entry(json, 0):find("\"dominatedBy\":2,\"dominating\":1", 1, true))
		assert.truthy(Entry(json, 1):find("\"dominance\":\"you\"", 1, true))
		assert.truthy(Entry(json, 1):find("\"turnsToVictory\":12", 1, true))
		assert.truthy(Entry(json, 2):find("\"dominance\":\"them\"", 1, true))
		assert.is_nil(Entry(json, 4):find("dominance", 1, true))
		assert.is_nil(Entry(json, 4):find("turnsToVictory", 1, true))
	end)

	it("leaves out the counts of players that do not dominate or are not dominated", function()
		local json = CultureOf({ [0] = { met = { 1 } }, [1] = {} })

		assert.is_nil(Entry(json, 0):find("dominat", 1, true))
	end)
end)

local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the domination entries of player 0 in a world.
local function DominationOf(players)
	local env = Game.new()

	FakeGame.Install(env, { players = players })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"domination\":(%b[])")
end

-- Returns the entry of a player in a list of entries, or the first unmet one for nil.
local function Entry(json, id)
	for entry in json:gmatch("%b{}") do
		if id == nil and entry:find("\"unmet\":true", 1, true) then
			return entry
		elseif id ~= nil and entry:find("\"player\":" .. id .. ",", 1, true) then
			return entry
		end
	end
end

local function City(id, data)
	data.id, data.name, data.x, data.y, data.population = id, "LOC_X", id, 1, 1

	return data
end

describe("SentientSystems_GetDominationDetails", function()
	it("counts the original capitals a player holds, and lists the owners that have been met", function()
		local json = DominationOf({
			[0] = {
				met = { 1, 3 },
				cities = {
					City(65536, { capital = true }),
					City(65537, { capital = false, originalCapital = true, originalOwner = 1 }),
					City(65538, { capital = false, originalCapital = true, originalOwner = 2 }),
					City(65539, { capital = false, originalCapital = true, originalOwner = 3 }),
					City(65540, { capital = false, originalCapital = false, originalOwner = 1 }),
					City(65541, { capital = false, originalCapital = true, originalOwner = 4 }),
				},
			},
			[1] = {},
			[2] = {},
			[3] = {},
			[4] = { minor = {} },
		})

		assert.equal(
			"{\"capitalsCaptured\":3,\"capturedCapitals\":[1,3],\"hasOriginalCapital\":true,\"military\":0,"
				.. "\"player\":0,\"progress\":0}",
			Entry(json, 0)
		)
	end)

	it("says whether a player has lost their original capital", function()
		local json = DominationOf({
			[0] = { cities = { City(65536, { capital = true, originalCapital = false }) } },
		})

		assert.truthy(Entry(json, 0):find("\"capitalsCaptured\":0,\"hasOriginalCapital\":false", 1, true))
		assert.is_nil(Entry(json, 0):find("capturedCapitals", 1, true))
	end)

	it("leaves out a player with no capital, and gives a player that has not been met no ID", function()
		local json = DominationOf({
			[0] = { cities = { City(65536, { capital = false }) } },
			[1] = { cities = { City(131072, { capital = true, originalCapital = true }) } },
		})

		assert.is_nil(Entry(json, 0):find("capitalsCaptured", 1, true))
		assert.equal("{\"capitalsCaptured\":0,\"hasOriginalCapital\":true,\"unmet\":true}", Entry(json))
	end)
end)

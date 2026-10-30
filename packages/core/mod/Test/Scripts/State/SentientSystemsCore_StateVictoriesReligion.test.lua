local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the religion entries of player 0 in a world.
local function ReligionOf(players)
	local env = Game.new()

	FakeGame.Install(env, { players = players })
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(0):match("\"religion\":(%b[])")
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

local BUDDHISM = "RELIGION_BUDDHISM"

describe("SentientSystems_GetReligionDetails", function()
	it("names the religion a player founded, and counts the civs that follow it, listing those met", function()
		local json = ReligionOf({
			[0] = { met = { 1 }, religion = { type = BUDDHISM, name = "Buddhism" }, majorityReligion = BUDDHISM },
			[1] = { majorityReligion = BUDDHISM },
			[2] = { majorityReligion = BUDDHISM },
			[3] = {},
		})

		assert.equal(
			"{\"cities\":0,\"civsConverted\":3,\"convertedCivs\":[0,1],\"faithPerTurn\":0,\"player\":0,\"progress\":0,"
				.. "\"religion\":\"RELIGION_BUDDHISM\",\"religionName\":\"Buddhism\"}",
			Entry(json, 0)
		)
	end)

	it("leaves out the religion of a player that founded none", function()
		local json = ReligionOf({ [0] = { met = { 1 } }, [1] = {} })

		assert.is_nil(Entry(json, 1):find("religion", 1, true))
		assert.is_nil(Entry(json, 1):find("civsConverted", 1, true))
	end)

	it("shows the religion of a player that has not been met, without their ID", function()
		local json = ReligionOf({
			[0] = {},
			[1] = { religion = { type = BUDDHISM, name = "Buddhism" }, majorityReligion = BUDDHISM },
		})

		assert.equal("{\"civsConverted\":1,\"religion\":\"RELIGION_BUDDHISM\",\"religionName\":\"Buddhism\",\"unmet\":true}", Entry(json))
	end)
end)

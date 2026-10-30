local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the victories JSON of player 0 in a world.
local function VictoriesOf(world)
	local env = Game.new()

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	-- The science stages have their own tests.
	return (env.SentientSystems_GetState(0):match("\"victories\":(%b{})"):gsub("\"stages\":%b[],", ""))
end

describe("SentientSystems_GetVictoryState", function()
	it("ranks the players by progress, with the tooltip's numbers for the player and a player they have met", function()
		local json = VictoriesOf({
			players = {
				[0] = { progress = { VICTORY_TECHNOLOGY = 0.2504 }, techsResearched = 12, science = 2.74, met = { 1 } },
				[1] = { progress = { VICTORY_TECHNOLOGY = 0.5 }, techsResearched = 20, science = 8 },
				[2] = { progress = { VICTORY_TECHNOLOGY = 0.75 } },
			},
		})

		assert.equal(
			"[{\"unmet\":true},{\"player\":1,\"progress\":0.5,\"sciencePerTurn\":8,\"techs\":20},"
				.. "{\"player\":0,\"progress\":0.25,\"sciencePerTurn\":2.7,\"techs\":12}]",
			json:match("\"science\":(%b[])")
		)
	end)

	it("breaks a tie by the tooltip's numbers, then the score, then the ID", function()
		local json = VictoriesOf({
			players = {
				[0] = { met = { 1, 2, 3 }, tourism = 5, culture = 1 },
				[1] = { tourism = 5, culture = 3 },
				[2] = { tourism = 7 },
				[3] = { tourism = 5, culture = 1, score = 9 },
				[4] = { tourism = 5, culture = 1 },
			},
		})

		local order = {}

		for entry in json:match("\"culture\":(%b[])"):gmatch("%b{}") do
			order[#order + 1] = entry:match("\"player\":(%d+)") or "unmet"
		end

		assert.same({ "2", "1", "3", "0", "unmet" }, order)
	end)

	it("lists the military strength, and the cities that follow a religion with the faith per turn", function()
		local json = VictoriesOf({ players = { [0] = { military = 20.04, followers = 3, faithPerTurn = 1.25 } } })

		assert.equal("[{\"military\":20,\"player\":0,\"progress\":0}]", json:match("\"domination\":(%b[])"))
		assert.equal("[{\"cities\":3,\"faithPerTurn\":1.3,\"player\":0,\"progress\":0}]", json:match("\"religion\":(%b[])"))
	end)

	it("leaves out a victory that is off and one that no player can win", function()
		local json = VictoriesOf({
			disabledVictories = { VICTORY_CULTURE = true },
			unwinnable = { VICTORY_RELIGIOUS = true },
			players = { [0] = {} },
		})

		assert.is_nil(json:find("\"culture\"", 1, true))
		assert.is_nil(json:find("\"religion\"", 1, true))
		assert.truthy(json:find("\"science\"", 1, true))
	end)

	it("lists the diplomatic points of every player, and the lines of their tooltip without icons", function()
		local json = VictoriesOf({
			expansion2 = true,
			players = {
				[0] = { met = { 1 } },
				[1] = {
					points = 2,
					pointsTooltip = "[ICON_Bolt] 1 from Wonders[NEWLINE][ICON_Bolt] 1 from Congress Participation",
				},
				[2] = { points = 1, pointsTooltip = "2 from Congress Participation" },
			},
		})

		assert.equal(
			"[{\"breakdown\":[\"1 from Wonders\",\"1 from Congress Participation\"],\"player\":1,\"points\":2,"
				.. "\"progress\":0,\"required\":20},"
				.. "{\"breakdown\":[\"2 from Congress Participation\"],\"points\":1,\"required\":20,\"unmet\":true},"
				.. "{\"player\":0,\"points\":0,\"progress\":0,\"required\":20}]",
			json:match("\"diplomatic\":(%b[])")
		)
	end)

	it("adds the diplomatic victory with Gathering Storm", function()
		local world = { players = { [0] = { points = 4 } } }

		assert.is_nil(VictoriesOf(world):find("\"diplomatic\"", 1, true))

		world.expansion2 = true

		assert.equal("[{\"player\":0,\"points\":4,\"progress\":0,\"required\":20}]", VictoriesOf(world):match("\"diplomatic\":(%b[])"))

		world.disabledVictories = { VICTORY_DIPLOMATIC = true }

		assert.is_nil(VictoriesOf(world):find("\"diplomatic\"", 1, true))
	end)
end)

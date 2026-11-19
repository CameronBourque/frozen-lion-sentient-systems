local FakeGame = require("FakeGame")
local Game = require("Game")

-- Headliners gains a promotion and a level, and Aging Rockers breaks the band
-- up, as the game's rows do.
local RESULTS = {
	{ Name = "LOC_HEADLINERS", Description = "LOC_HEADLINERS_TEXT", AlbumSales = 150, ExtraPromotion = true, GainsLevel = true },
	{ Name = "LOC_AGING", Description = "LOC_AGING_TEXT", AlbumSales = 0, Dies = true },
}

local TEXT = {
	LOC_HEADLINERS = "Headliners",
	LOC_HEADLINERS_TEXT = "A sold-out show.",
	LOC_AGING = "Aging Rockers",
	LOC_AGING_TEXT = "The last show.",
	LOC_ROCK_CONCERT_RESULT_TOURISM = "Tourism Generated",
	LOC_ROCK_CONCERT_RESULT_ALBUMS = "Albums Sold",
	LOC_ROCK_CONCERT_RESULT_PROMOTION = "Promotion Available!",
	LOC_ROCK_CONCERT_RESULT_LEVEL_UP = "Leveled Up!",
	LOC_ROCK_CONCERT_RESULT_UNIT_LOST = "Unit Lost",
}

-- Returns an environment on turn 85 with the events script loaded, where
-- player 0 has rock band 5, and player 63 is the barbarians. rockBand replaces
-- the band's data.
local function Load(rockBand)
	local env = Game.new()
	local world = {
		turn = 85,
		players = {
			[0] = { units = { { id = 5, type = "UNIT_ROCK_BAND", x = 1, y = 1, rockBand = rockBand or {} } } },
			[63] = { minor = { name = "LOC_BARBARIANS" } },
		},
		rockBandResults = RESULTS,
		text = TEXT,
	}

	FakeGame.Install(env, world)
	Game.run(env, "Scripts/SentientSystemsCore_Events.lua")

	return env, world
end

describe("the unit capture events", function()
	it("keeps the message of a unit lost and of a unit captured, with the other civ's name", function()
		local env = Load()

		env.SentientSystems_NoteUnitLost(0, 63)
		env.SentientSystems_NoteUnitCaptured(0, 63)

		assert.same({
			{ turn = 85, kind = "unitLost", text = "LOC_UNIT_CAPTURED(LOC_BARBARIANS)" },
			{ turn = 85, kind = "unitCaptured", text = "LOC_CAPTURE_UNIT(LOC_BARBARIANS)" },
		}, env.SentientSystems_GetEventMessages(0))
	end)
end)

describe("SentientSystems_NoteMoveCancelled", function()
	it("keeps the unit, where it stands, and the destination it can't reach", function()
		local env = Load()

		env.SentientSystems_NoteMoveCancelled(0, env.Players[0]:GetUnits():FindID(5), 9, 17)

		assert.same({
			{ turn = 85, kind = "moveCancelled", text = "Unit 5 (UNIT_ROCK_BAND) at (1, 1) can't reach (9, 17), so its move was cancelled. Give it new orders." },
		}, env.SentientSystems_GetEventMessages(0))
	end)
end)

describe("SentientSystems_NoteConcert", function()
	it("keeps the result, tourism, albums, and the promotion and level the band gained", function()
		local env = Load()

		env.SentientSystems_NoteConcert(0, 5, 0, 1000)

		assert.same({
			{
				turn = 85,
				kind = "concert",
				text = "Headliners: A sold-out show.\nTourism Generated: 1000\nAlbums Sold: 150\nPromotion Available!\nLeveled Up!",
			},
		}, env.SentientSystems_GetEventMessages(0))
	end)

	it("leaves out a promotion or level the band is already at the most of", function()
		local env = Load({ maxPromotions = true, maxLevel = true })

		env.SentientSystems_NoteConcert(0, 5, 0, 200)

		assert.equal("Headliners: A sold-out show.\nTourism Generated: 200\nAlbums Sold: 150", env.SentientSystems_GetEventMessages(0)[1].text)
	end)

	it("says the band broke up, even with the band gone", function()
		local env = Load()

		env.SentientSystems_NoteConcert(0, 99, 1, 100)

		assert.equal("Aging Rockers: The last show.\nTourism Generated: 100\nAlbums Sold: 0\nUnit Lost", env.SentientSystems_GetEventMessages(0)[1].text)
	end)

	it("keeps nothing for a result with no row", function()
		local env = Load()

		env.SentientSystems_NoteConcert(0, 5, 9, 100)

		assert.same({}, env.SentientSystems_GetEventMessages(0))
	end)
end)

describe("SentientSystems_GetEventMessages", function()
	it("gives the player's own events from the previous turn and this one", function()
		local env, world = Load()

		env.SentientSystems_NoteUnitLost(0, 63)
		env.SentientSystems_NoteUnitLost(63, 0)
		world.turn = 86
		env.SentientSystems_NoteUnitCaptured(0, 63)

		assert.equal(2, #env.SentientSystems_GetEventMessages(0))
		world.turn = 87
		assert.same({ { turn = 86, kind = "unitCaptured", text = "LOC_CAPTURE_UNIT(LOC_BARBARIANS)" } }, env.SentientSystems_GetEventMessages(0))
		assert.same({}, env.SentientSystems_GetEventMessages(63))
	end)

	it("keeps the events when the script loads again", function()
		local env = Load()

		env.SentientSystems_NoteUnitLost(0, 63)
		Game.run(env, "Scripts/SentientSystemsCore_Events.lua")

		assert.equal(1, #env.SentientSystems_GetEventMessages(0))
	end)
end)

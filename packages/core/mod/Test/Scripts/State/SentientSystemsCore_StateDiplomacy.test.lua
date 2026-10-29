local FakeGame = require("FakeGame")
local Game = require("Game")

-- Returns the diplomacy JSON of a player in a world with turn 85 and the
-- given players, with Rise and Fall unless noRiseAndFall is true.
local function DiplomacyOf(playerID, players, noRiseAndFall, gatheringStorm)
	local env = Game.new()
	local world = { turn = 85, players = players }

	world.expansion2 = gatheringStorm
	world.era = not noRiseAndFall and { type = "ERA_CLASSICAL", minEnd = 100, maxEnd = 110 } or nil
	FakeGame.Install(env, world)
	Game.run(env, "Scripts/State/SentientSystemsCore_State.lua")

	return env.SentientSystems_GetState(playerID):match("\"diplomacy\":(%b[])")
end

-- The agreements of two players with nothing agreed.
local NO_AGREEMENTS = "\"agreements\":{\"defensivePact\":false,\"delegation\":{\"mine\":false,\"theirs\":false},"
	.. "\"embassy\":{\"mine\":false,\"theirs\":false},\"jointWar\":false,"
	.. "\"openBorders\":{\"given\":false,\"received\":false}}"

describe("SentientSystems_GetDiplomacyState", function()
	it("lists the players met, with a neutral state and nothing agreed", function()
		local json = DiplomacyOf(0, { [0] = { met = { 1 } }, [1] = {}, [2] = {} })

		assert.equal(
			"[{\"access\":{\"level\":0,\"name\":\"LOC_VISIBILITY_0\"},\"agendas\":{\"hidden\":0,\"list\":[]}," .. NO_AGREEMENTS
				.. ",\"alliance\":{\"level\":1,\"points\":0,\"pointsNeeded\":40},\"atWar\":false,\"player\":1,"
				.. "\"relationship\":{\"reasons\":[]},\"state\":\"DIPLO_STATE_NEUTRAL\"}]",
			json
		)
	end)

	it("leaves out the alliance without Rise and Fall", function()
		local json = DiplomacyOf(0, { [0] = { met = { 1 } }, [1] = {} }, true)

		assert.falsy(json:find("alliance", 1, true))
	end)

	it("says whether the player is at war, and how the other sees them", function()
		local json = DiplomacyOf(0, {
			[0] = { met = { 1 }, atWar = { 1 } },
			[1] = { diplomacy = { [0] = { state = "DIPLO_STATE_WAR" } } },
		})

		assert.truthy(json:find("\"atWar\":true,\"player\":1,\"relationship\":{\"reasons\":[]},\"state\":\"DIPLO_STATE_WAR\"", 1, true))
	end)

	it("leaves out the state of a human player", function()
		local json = DiplomacyOf(0, { [0] = { met = { 1 } }, [1] = { human = true } })

		assert.falsy(json:find("state", 1, true))
		assert.truthy(json:find("\"player\":1}", 1, true))
	end)

	it("gives the access level and the government, or the turns of anarchy", function()
		local json = DiplomacyOf(0, {
			[0] = { met = { 1, 2 }, diplomacy = { [1] = { access = 2 } } },
			[1] = { government = { type = "GOVERNMENT_AUTOCRACY" } },
			[2] = { anarchyUntil = 88 },
		})

		assert.truthy(json:find("\"access\":{\"level\":2,\"name\":\"LOC_VISIBILITY_2\"}", 1, true))
		assert.truthy(json:find("\"government\":\"GOVERNMENT_AUTOCRACY\"", 1, true))
		assert.truthy(json:find("\"anarchyTurns\":3", 1, true))
	end)

	it("gives each side's delegation, embassy, and open borders, and the pacts", function()
		local json = DiplomacyOf(0, {
			[0] = {
				met = { 1 },
				diplomacy = { [1] = { delegation = true, openBorders = true, defensivePact = true, jointWar = true, research = "TECH_WRITING" } },
			},
			[1] = { diplomacy = { [0] = { embassy = true, openBorders = true } } },
		})

		assert.truthy(json:find("\"agreements\":{\"defensivePact\":true,\"delegation\":{\"mine\":true,\"theirs\":false},"
			.. "\"embassy\":{\"mine\":false,\"theirs\":true},\"jointWar\":true,\"openBorders\":{\"given\":true,\"received\":true},"
			.. "\"researchAgreement\":\"TECH_WRITING\"}", 1, true))
	end)

	it("counts the turns of a declared friendship", function()
		local json = DiplomacyOf(0, {
			[0] = { met = { 1 }, diplomacy = { [1] = { friendship = 70 } } },
			[1] = { diplomacy = { [0] = { state = "DIPLO_STATE_DECLARED_FRIEND" } } },
		})

		assert.truthy(json:find("\"state\":\"DIPLO_STATE_DECLARED_FRIEND\",\"turnsLeft\":5}", 1, true))
	end)

	it("counts the turns of a denouncement from the later turn, with the order of the players", function()
		local function TurnsLeft(playerID, otherID, ours, theirs)
			local players = {
				[playerID] = { met = { otherID }, diplomacy = { [otherID] = { denounce = ours } } },
				[otherID] = { diplomacy = { [playerID] = { state = "DIPLO_STATE_DENOUNCED", denounce = theirs } } },
			}

			return DiplomacyOf(playerID, players):match("\"turnsLeft\":(%d+)")
		end

		-- The other denounced at 74, and has the higher ID: 1 + 74 + 20 - 85 + 1.
		assert.equal("11", TurnsLeft(0, 5, -1, 74))
		-- The player denounced at 80, after the other at 74: 1 + 80 + 20 - 85, and no more
		-- as the player has the lower ID.
		assert.equal("16", TurnsLeft(0, 5, 80, 74))
		-- With the player's ID higher, the player's later denouncement adds a turn.
		assert.equal("17", TurnsLeft(5, 0, 80, 74))
	end)

	it("gives the alliance level and points, and the type, pace, and end of an alliance", function()
		local json = DiplomacyOf(0, {
			[0] = { met = { 1 }, diplomacy = { [1] = { alliance = { type = "ALLIANCE_RESEARCH", level = 2, turnsThis = 136, turnsToNext = 320, perTurn = 5, expires = 3 } } } },
			[1] = {},
		})

		assert.truthy(json:find("\"alliance\":{\"level\":2,\"points\":34,\"pointsNeeded\":80,\"pointsPerTurn\":1.25,"
			.. "\"turnsUntilExpiration\":3,\"type\":\"ALLIANCE_RESEARCH\"}", 1, true))
	end)

	it("gives max in place of the points at the highest alliance level", function()
		local json = DiplomacyOf(0, { [0] = { met = { 1 }, diplomacy = { [1] = { alliance = { level = 3 } } } }, [1] = {} })

		assert.truthy(json:find("\"alliance\":{\"level\":3,\"max\":true}", 1, true))
	end)

	it("lists the reasons for the relationship, best first, and greys out one it can't explain", function()
		local json = DiplomacyOf(0, {
			[0] = { met = { 1 } },
			[1] = {
				diplomacy = {
					[0] = {
						modifiers = {
							{ Score = 2, Text = "Friendly meeting" },
							{ Score = -6, Text = "LOC_TOOLTIP_DIPLOMACY_UNKNOWN_REASON" },
							{ Score = 0, Text = "Nothing" },
							{ Score = 9, Text = "Pleased with the highlands" },
							{ Score = 2, Text = "Another" },
						},
					},
				},
			},
		})

		assert.truthy(json:find("\"relationship\":{\"reasons\":[{\"score\":9,\"text\":\"Pleased with the highlands\"},"
			.. "{\"score\":2,\"text\":\"Another\"},{\"score\":2,\"text\":\"Friendly meeting\"},{\"score\":-6,\"unknown\":true}]}", 1, true))
	end)

	it("gives the historical agenda, and the random ones only with enough access, else their number", function()
		local agendas = { "AGENDA_HIGHLANDS", "AGENDA_DEVOUT", "AGENDA_EXPLORER" }
		local function Agendas(level)
			return DiplomacyOf(0, { [0] = { met = { 1 }, diplomacy = { [1] = { access = level } } }, [1] = { agendas = agendas } })
		end

		assert.truthy(Agendas(1):find("\"agendas\":{\"hidden\":2,\"list\":[{\"description\":\"LOC_AGENDA_HIGHLANDS_DESC\","
			.. "\"name\":\"LOC_AGENDA_HIGHLANDS_NAME\",\"type\":\"AGENDA_HIGHLANDS\"}]}", 1, true))
		assert.truthy(Agendas(2):find("\"agendas\":{\"hidden\":0,\"list\":[{\"description\":\"LOC_AGENDA_HIGHLANDS_DESC\"", 1, true))
		assert.truthy(Agendas(2):find("\"type\":\"AGENDA_DEVOUT\"},{\"description\":\"LOC_AGENDA_EXPLORER_DESC\"", 1, true))
	end)

	it("leaves out the relationship and the agendas of a human player", function()
		local json = DiplomacyOf(0, { [0] = { met = { 1 } }, [1] = { human = true, agendas = { "AGENDA_HIGHLANDS" } } })

		assert.falsy(json:find("relationship", 1, true))
		assert.falsy(json:find("agendas", 1, true))
	end)

	it("gives the grievances with Gathering Storm, the log by turn, and the balance with its sign", function()
		local json = DiplomacyOf(0, {
			[0] = {
				met = { 1 },
				diplomacy = {
					[1] = {
						grievances = {
							balance = -12,
							perTurn = 2.5,
							log = {
								{ Turn = 52, Initiator = 1, Target = 0, Amount = 100, Description = "War declared" },
								{ Turn = 20, Initiator = 0, Target = 1, Amount = 50, Description = "City occupied" },
							},
						},
					},
				},
			},
			[1] = {},
		}, false, true)

		assert.truthy(json:find("\"grievances\":{\"balance\":-12,\"log\":[{\"against\":1,\"amount\":50,\"from\":0,\"text\":\"City occupied\",\"turn\":20},"
			.. "{\"against\":0,\"amount\":100,\"from\":1,\"text\":\"War declared\",\"turn\":52}],\"perTurn\":2.5}", 1, true))
	end)

	it("leaves out the grievances without Gathering Storm", function()
		assert.falsy(DiplomacyOf(0, { [0] = { met = { 1 } }, [1] = {} }):find("grievances", 1, true))
	end)

	it("lists how the players the other has met see them, and leaves out neutral ones", function()
		local json = DiplomacyOf(0, {
			[0] = { met = { 1 } },
			[1] = { met = { 2, 3, 4 } },
			[2] = { diplomacy = { [1] = { state = "DIPLO_STATE_FRIENDLY" } } },
			[3] = {},
			[4] = { diplomacy = { [1] = { state = "DIPLO_STATE_WAR" } } },
		})

		assert.truthy(json:find("\"others\":[{\"player\":2,\"state\":\"DIPLO_STATE_FRIENDLY\"},{\"player\":4,\"state\":\"DIPLO_STATE_WAR\"}]", 1, true))
		assert.falsy(DiplomacyOf(0, { [0] = { met = { 1 } }, [1] = {} }):find("others", 1, true))
	end)
end)

local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/SentientSystemsCore_Common.lua")
end)

describe("SentientSystems_Print", function()
	it("prints the tag and each argument, joined with spaces", function()
		env.SentientSystems_Print("AGENT_TURN", 0)

		assert.same({ "[SENTIENTSYSTEMS] AGENT_TURN 0" }, env.printed)
	end)

	it("prints the tag alone with no arguments", function()
		env.SentientSystems_Print()

		assert.same({ "[SENTIENTSYSTEMS]" }, env.printed)
	end)

	it("prints nil and false arguments as text", function()
		env.SentientSystems_Print("CORE_VERSION", nil, false)

		assert.same({ "[SENTIENTSYSTEMS] CORE_VERSION nil false" }, env.printed)
	end)
end)

describe("SentientSystems_CatchErrors", function()
	it("passes the arguments to the handler and prints nothing when it succeeds", function()
		local received

		env.SentientSystems_CatchErrors("OnTest", function(...)
			received = { ... }
		end)(0, nil, true)

		assert.same({ 0, nil, true }, received)
		assert.same({}, env.printed)
	end)

	it("prints an ERROR line with the handler's name and the message", function()
		env.SentientSystems_CatchErrors("OnTest", function()
			error("boom", 0)
		end)()

		assert.same({ "[SENTIENTSYSTEMS] ERROR OnTest boom" }, env.printed)
	end)

	it("escapes backslashes and newlines, so the error is one line", function()
		env.SentientSystems_CatchErrors("OnTest", function()
			error("C:\\Mods\nline two\r\nline three", 0)
		end)()

		assert.same({ "[SENTIENTSYSTEMS] ERROR OnTest C:\\\\Mods\\nline two\\nline three" }, env.printed)
	end)

	it("escapes a percent sign as \\p, so the game's log doesn't read it as a format code", function()
		env.SentientSystems_CatchErrors("OnTest", function()
			error("invalid option '%s' at 50% done", 0)
		end)()

		assert.same({ "[SENTIENTSYSTEMS] ERROR OnTest invalid option '\\ps' at 50\\p done" }, env.printed)
	end)

	it("prints an error raised with a table", function()
		env.SentientSystems_CatchErrors("OnTest", function()
			error(setmetatable({}, { __tostring = function() return "a table" end }))
		end)()

		assert.same({ "[SENTIENTSYSTEMS] ERROR OnTest a table" }, env.printed)
	end)
end)

describe("SentientSystems_HasExpansion2", function()
	it("is true only when the game has Gathering Storm's government rows", function()
		env.GameInfo = {}
		assert.is_false(env.SentientSystems_HasExpansion2())

		env.GameInfo.Governments_XP2 = {}
		assert.is_true(env.SentientSystems_HasExpansion2())
	end)
end)

describe("SentientSystems_HasBlocker", function()
	it("is true when any of the blockers named blocks the player's turn", function()
		env.EndTurnBlockingTypes = { ENDTURN_BLOCKING_ARTIFACT = 7, ENDTURN_BLOCKING_UNITS = 9 }
		env.NotificationManager = {
			GetAllEndTurnBlocking = function(playerID)
				return playerID == 0 and { 9, 7 } or nil
			end,
		}

		assert.is_true(env.SentientSystems_HasBlocker(0, "ENDTURN_BLOCKING_RESEARCH", "ENDTURN_BLOCKING_ARTIFACT"))
		assert.is_false(env.SentientSystems_HasBlocker(0, "ENDTURN_BLOCKING_RESEARCH"))
		assert.is_false(env.SentientSystems_HasBlocker(1, "ENDTURN_BLOCKING_ARTIFACT"))
	end)
end)

describe("SentientSystems_Include", function()
	it("loads the file, returns its path, and prints nothing", function()
		local loaded = env.SentientSystems_Include("SentientSystemsCore_Json")

		assert.equal(1, #loaded)
		assert.truthy(loaded[1]:find("SentientSystemsCore_Json.lua$"))
		assert.is_function(env.SentientSystems_EncodeJson)
		assert.same({}, env.printed)
	end)

	it("prints an ERROR line when no file has the name", function()
		assert.same({}, env.SentientSystems_Include("SentientSystemsCore_Missing"))
		assert.same({
			"[SENTIENTSYSTEMS] ERROR include found no file named SentientSystemsCore_Missing. After you add a file to the .modinfo, restart the game",
		}, env.printed)
	end)

	it("prints an ERROR line when include returns nothing", function()
		env.include = function() end

		env.SentientSystems_Include("SentientSystemsCore_Json")

		assert.equal(1, #env.printed)
		assert.truthy(env.printed[1]:find("^%[SENTIENTSYSTEMS%] ERROR include found no file named SentientSystemsCore_Json"))
	end)
end)

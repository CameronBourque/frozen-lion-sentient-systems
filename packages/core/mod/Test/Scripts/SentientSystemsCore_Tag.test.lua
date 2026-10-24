local Game = require("Game")

local env

before_each(function()
	env = Game.new()
	Game.run(env, "Scripts/SentientSystemsCore_Tag.lua")
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

	it("prints an error raised with a table", function()
		env.SentientSystems_CatchErrors("OnTest", function()
			error(setmetatable({}, { __tostring = function() return "a table" end }))
		end)()

		assert.same({ "[SENTIENTSYSTEMS] ERROR OnTest a table" }, env.printed)
	end)
end)

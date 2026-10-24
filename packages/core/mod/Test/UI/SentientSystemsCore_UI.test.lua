local Game = require("Game")

local MOD_ID = "5D4B5856-E71F-492C-A434-A0938AF49451"

local env

-- A player with an ID, whether a human plays it, and whether its turn is active.
local function Player(id, isHuman, isTurnActive)
	return {
		GetID = function()
			return id
		end,
		IsHuman = function()
			return isHuman
		end,
		IsTurnActive = function()
			return isTurnActive
		end,
	}
end

-- Sets the living players, by ID.
local function SetPlayers(players)
	env.Players = players
	env.PlayerManager.GetAlive = function()
		local alive = {}

		for _, player in pairs(players) do
			alive[#alive + 1] = player
		end

		return alive
	end
end

-- Calls each handler that the script added to the event.
local function Fire(event, ...)
	for _, handler in ipairs(env.Events[event].handlers) do
		handler(...)
	end
end

before_each(function()
	env = Game.new()
	env.ContextPtr = {
		GetID = function()
			return "SentientSystemsCore_UI"
		end,
	}
	-- Each event records its handlers, so a test can fire it.
	env.Events = setmetatable({}, {
		__index = function(events, name)
			local event = { handlers = {} }

			function event.Add(handler)
				event.handlers[#event.handlers + 1] = handler
			end

			events[name] = event

			return event
		end,
	})
	env.Game = {
		GetCurrentGameTurn = function()
			return 12
		end,
	}
	env.Modding = {
		GetActiveMods = function()
			return {}
		end,
	}
	env.PlayerManager = {}
	SetPlayers({})
	Game.run(env, "UI/SentientSystemsCore_UI.lua")
	env.printed = {}
end)

describe("loading the script", function()
	it("prints CORE_LOADED with the state's name", function()
		Game.run(env, "UI/SentientSystemsCore_UI.lua")

		assert.same({ "[SENTIENTSYSTEMS] CORE_LOADED SentientSystemsCore_UI" }, env.printed)
	end)
end)

describe("SentientSystems_GetVersion", function()
	it("prints and returns the version of the active core mod", function()
		env.Modding.GetActiveMods = function()
			return {
				{ Id = "4873eb62-8ccc-4574-b784-dda455e74e68", Handle = 1 },
				{ Id = MOD_ID:lower(), Handle = 2 },
			}
		end
		env.Modding.GetModProperty = function(handle, name)
			return handle == 2 and name == "Version" and "0.4.0" or nil
		end

		assert.equal("0.4.0", env.SentientSystems_GetVersion())
		assert.same({ "[SENTIENTSYSTEMS] CORE_VERSION 0.4.0" }, env.printed)
	end)

	it("prints and returns nil when the core mod isn't active", function()
		assert.is_nil(env.SentientSystems_GetVersion())
		assert.same({ "[SENTIENTSYSTEMS] CORE_VERSION nil" }, env.printed)
	end)
end)

describe("the turn event", function()
	it("prints AGENT_TURN when a human player's turn starts", function()
		SetPlayers({ [0] = Player(0, true, true) })

		Fire("PlayerTurnActivated", 0, true)

		assert.same({ "[SENTIENTSYSTEMS] AGENT_TURN 0" }, env.printed)
	end)

	it("prints nothing for an AI player's turn", function()
		SetPlayers({ [5] = Player(5, false, true) })

		Fire("PlayerTurnActivated", 5, true)

		assert.same({}, env.printed)
	end)

	it("prints nothing for a player that doesn't exist", function()
		Fire("PlayerTurnActivated", 7, true)

		assert.same({}, env.printed)
	end)

	it("prints an ERROR line when the handler fails", function()
		env.Players = setmetatable({}, {
			__index = function()
				error("no players", 0)
			end,
		})

		Fire("PlayerTurnActivated", 0, true)

		assert.same({ "[SENTIENTSYSTEMS] ERROR OnPlayerTurnActivated no players" }, env.printed)
	end)
end)

describe("SentientSystems_Resync", function()
	it("prints AGENT_TURN for each human player whose turn is active", function()
		SetPlayers({
			[0] = Player(0, true, true),
			[1] = Player(1, true, false),
			[5] = Player(5, false, true),
		})

		env.SentientSystems_Resync()

		assert.same({ "[SENTIENTSYSTEMS] AGENT_TURN 0" }, env.printed)
	end)

	it("prints nothing between turns", function()
		SetPlayers({ [0] = Player(0, true, false) })

		env.SentientSystems_Resync()

		assert.same({}, env.printed)
	end)
end)

describe("the load signal", function()
	it("prints LOAD_READY when the loading screen shows its button", function()
		Fire("LoadGameViewStateDone")

		assert.same({ "[SENTIENTSYSTEMS] LOAD_READY" }, env.printed)
	end)

	it("prints GAME_READY with the turn when the loading screen closes", function()
		Fire("LoadScreenClose")

		assert.same({ "[SENTIENTSYSTEMS] GAME_READY 12" }, env.printed)
	end)
end)

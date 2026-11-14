local Game = require("Game")

local MOD_ID = "5D4B5856-E71F-492C-A434-A0938AF49451"

local env

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

-- Returns a table of events in which each event records its handlers, so a
-- test can fire it.
local function EventTable()
	return setmetatable({}, {
		__index = function(events, name)
			local event = { handlers = {} }

			function event.Add(handler)
				event.handlers[#event.handlers + 1] = handler
			end

			events[name] = event

			return event
		end,
	})
end

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
	env.Events = EventTable()
	env.LuaEvents = EventTable()
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

describe("the diplomacy statement event", function()
	-- Records each statement passed on, in place of closing it.
	local closed

	before_each(function()
		closed = {}
		env.SentientSystems_HandleStatement = function(fromID, toID, statement)
			closed[#closed + 1] = { fromID, toID, statement.SessionID }
		end
	end)

	it("passes a statement to a human player on, to close a goodbye or remember it", function()
		SetPlayers({ [0] = Player(0, true, true) })

		Fire("DiplomacyStatement", 4, 0, { SessionID = 7 })

		assert.same({ { 4, 0, 7 } }, closed)
	end)

	it("leaves a statement to an AI player or a player that doesn't exist", function()
		SetPlayers({ [5] = Player(5, false, true) })

		Fire("DiplomacyStatement", 4, 5, { SessionID = 7 })
		Fire("DiplomacyStatement", 4, 9, { SessionID = 8 })

		assert.same({}, closed)
	end)
end)

describe("the diplomacy session closed event", function()
	it("forgets the statement of the session", function()
		env.SentientSystems_OpenStatements[7] = { from = 4, to = 0 }
		env.SentientSystems_OpenStatements[8] = { from = 5, to = 0 }

		Fire("DiplomacySessionClosed", 7)

		assert.same({ [8] = { from = 5, to = 0 } }, env.SentientSystems_OpenStatements)
	end)
end)

describe("the wonder built popup", function()
	-- Counts the calls to close the popup, in place of closing it.
	local closes
	local realClose

	local function Show(localPlayer)
		env.Game.GetLocalPlayer = function()
			return localPlayer
		end

		for _, handler in ipairs(env.LuaEvents.WonderBuiltPopup_Shown.handlers) do
			handler()
		end
	end

	before_each(function()
		closes = 0
		realClose = env.SentientSystems_CloseWonderPopup
		env.SentientSystems_CloseWonderPopup = function()
			closes = closes + 1
		end
	end)

	it("closes the popup for a human player", function()
		SetPlayers({ [0] = Player(0, true, true) })

		Show(0)

		assert.equal(1, closes)
	end)

	it("leaves the popup for an AI player or a player that doesn't exist", function()
		SetPlayers({ [5] = Player(5, false, true) })

		Show(5)
		Show(-1)

		assert.equal(0, closes)
	end)

	it("sends the closed signal when the batch of game events ends", function()
		local closedSignals = 0

		env.UI = {
			ReferenceCurrentEvent = function()
				return 9
			end,
			PlaySound = function() end,
			ReleaseEventID = function() end,
			SetInterfaceMode = function() end,
		}
		env.UIManager = { DequeuePopup = function() end }
		env.Input = { PopContext = function() end }
		env.UILens = { RestoreActiveLens = function() end }
		env.InterfaceModeTypes = { SELECTION = 1 }
		env.ContextPtr.LookUpControl = function() end
		env.LuaEvents.WonderBuiltPopup_Closed = function()
			closedSignals = closedSignals + 1
		end
		env.SentientSystems_CloseWonderPopup = realClose
		SetPlayers({ [0] = Player(0, true, true) })

		Show(0)
		assert.equal(0, closedSignals)
		Fire("GameCoreEventPublishComplete")
		Fire("GameCoreEventPublishComplete")

		assert.equal(1, closedSignals)
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

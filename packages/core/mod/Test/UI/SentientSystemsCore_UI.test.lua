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
		GetLocalPlayer = function()
			return -1
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
	env.SentientSystems_CancelDeadMoves = function() end
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

	it("forgets the end turn request when a human player's turn starts again", function()
		local forgot = 0

		env.SentientSystems_ForgetEndTurn = function()
			forgot = forgot + 1
		end
		SetPlayers({ [0] = Player(0, true, true) })

		Fire("PlayerTurnActivated", 0, false)

		assert.equal(1, forgot)
		assert.same({ "[SENTIENTSYSTEMS] AGENT_TURN 0 again" }, env.printed)
	end)

	it("prints nothing for an AI player's turn", function()
		local forgot = 0

		env.SentientSystems_ForgetEndTurn = function()
			forgot = forgot + 1
		end
		SetPlayers({ [5] = Player(5, false, true) })

		Fire("PlayerTurnActivated", 5, true)

		assert.same({}, env.printed)
		assert.equal(0, forgot)
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

describe("the move checks", function()
	it("checks a human player's units when their turn starts", function()
		local checked = {}

		env.SentientSystems_CancelDeadMoves = function(playerID)
			checked[#checked + 1] = playerID
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		Fire("PlayerTurnActivated", 0, true)
		Fire("PlayerTurnActivated", 0, false)
		Fire("PlayerTurnActivated", 5, true)

		assert.same({ 0, 0 }, checked)
	end)

	it("checks a human player's unit when its move ends", function()
		local checked = {}

		env.SentientSystems_CancelDeadMove = function(playerID, unitID)
			checked[#checked + 1] = { playerID, unitID }
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		Fire("UnitMoveComplete", 0, 131073, 11, 17)
		Fire("UnitMoveComplete", 5, 22, 1, 1)

		assert.same({ { 0, 131073 } }, checked)
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

describe("the popups", function()
	local function SetLocalPlayer(localPlayer)
		env.Game.GetLocalPlayer = function()
			return localPlayer
		end
	end

	it("closes the popups when a batch of game events or a load ends, or the interface is idle, for a human player only", function()
		local sweeps = 0

		env.SentientSystems_ClosePopups = function()
			sweeps = sweeps + 1
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		SetLocalPlayer(0)
		Fire("GameCoreEventPublishComplete")
		Fire("LoadScreenClose")
		Fire("UIIdle")
		SetLocalPlayer(5)
		Fire("GameCoreEventPublishComplete")
		Fire("LoadScreenClose")
		Fire("UIIdle")

		assert.equal(3, sweeps)
	end)

	it("passes a dialog raised through InGamePopup on, for a human player only", function()
		local noted = {}

		env.SentientSystems_NoteRaisedDialog = function(id)
			noted[#noted + 1] = id
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		SetLocalPlayer(0)
		for _, handler in ipairs(env.LuaEvents.OnRaisePopupInGame.handlers) do
			handler("UnitCaptured", {})
		end
		SetLocalPlayer(5)
		for _, handler in ipairs(env.LuaEvents.OnRaisePopupInGame.handlers) do
			handler("UnitCaptured", {})
		end

		assert.same({ "UnitCaptured" }, noted)
	end)

	it("keeps a unit capture for each human player on either side", function()
		local noted = {}

		env.SentientSystems_NoteUnitLost = function(playerID, capturerID)
			noted[#noted + 1] = { "lost", playerID, capturerID }
		end
		env.SentientSystems_NoteUnitCaptured = function(playerID, ownerID)
			noted[#noted + 1] = { "captured", playerID, ownerID }
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		Fire("UnitCaptured", 0, 77, 0, 5)
		Fire("UnitCaptured", 5, 78, 5, 0)
		Fire("UnitCaptured", 5, 79, 5, 63)

		assert.same({ { "lost", 0, 5 }, { "captured", 0, 5 } }, noted)
	end)

	it("keeps a village reward of a human player's only", function()
		local noted = {}

		env.SentientSystems_NoteVillageReward = function(...)
			noted[#noted + 1] = { ... }
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		Fire("GoodyHutReward", 0, 196608, 11, 12)
		Fire("GoodyHutReward", 5, 22, 11, 12)

		assert.same({ { 0, 196608, 12 } }, noted)
	end)

	it("keeps a concert of a human player's only", function()
		local noted = {}

		env.SentientSystems_NoteConcert = function(...)
			noted[#noted + 1] = { ... }
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		Fire("PostTourismBomb", 0, 21, 4, 5, 2, 1000)
		Fire("PostTourismBomb", 5, 22, 4, 5, 2, 1000)

		assert.same({ { 0, 21, 2, 1000 } }, noted)
	end)

	it("turns off the tech, civic, and boost popups when a load ends, for a human player only", function()
		local turnedOff = 0

		env.LuaEvents.TutorialUIRoot_DisableTechAndCivicPopups = function()
			turnedOff = turnedOff + 1
		end
		SetPlayers({ [0] = Player(0, true, true), [5] = Player(5, false, true) })

		SetLocalPlayer(0)
		Fire("LoadGameViewStateDone")
		SetLocalPlayer(5)
		Fire("LoadGameViewStateDone")

		assert.equal(1, turnedOff)
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

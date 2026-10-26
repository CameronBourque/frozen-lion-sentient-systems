-- The core mod's UI script. It runs in its own UI Lua state, where the request functions work.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_State")
SentientSystems_Include("SentientSystemsCore_Choices")
SentientSystems_Include("SentientSystemsCore_Placement")

-- The id attribute in SentientSystemsCore.modinfo.
local MOD_ID = "5D4B5856-E71F-492C-A434-A0938AF49451"

-- Prints "[SENTIENTSYSTEMS] CORE_VERSION <version>" and returns the version. The version comes
-- from <Properties><Version> in the .modinfo. Gameplay states have no Modding, so only a UI
-- state can read it.
function SentientSystems_GetVersion()
	local version = nil

	for _, mod in ipairs(Modding.GetActiveMods()) do
		if mod.Id:upper() == MOD_ID then
			version = Modding.GetModProperty(mod.Handle, "Version")
			break
		end
	end

	SentientSystems_Print("CORE_VERSION", version)

	return version
end

-- Whether an agent plays this player. Every turn check goes through here. For now agents play the
-- human slots. Later an agent can play any slot, human or AI, and only this check changes.
local function IsAgentPlayer(player)
	return player:IsHuman()
end

-- Prints the turn signal, "[SENTIENTSYSTEMS] AGENT_TURN <playerID>", when an agent player's turn
-- starts. isFirstTime is false when the event fires again for a turn that already started.
local function OnPlayerTurnActivated(playerID, isFirstTime)
	local player = Players[playerID]

	if player ~= nil and IsAgentPlayer(player) then
		SentientSystems_Print("AGENT_TURN", playerID)
	end
end

Events.PlayerTurnActivated.Add(SentientSystems_CatchErrors("OnPlayerTurnActivated", OnPlayerTurnActivated))

-- Prints the turn signal again for each agent player whose turn is active now, so a bridge that
-- connects in the middle of a turn learns of it. Prints nothing between turns or during AI turns.
-- PlayerManager.GetAlive() lists every living player, AI and city-states too, so the loop needs no
-- change when agents can play other slots.
function SentientSystems_Resync()
	for _, player in ipairs(PlayerManager.GetAlive()) do
		if IsAgentPlayer(player) and player:IsTurnActive() then
			SentientSystems_Print("AGENT_TURN", player:GetID())
		end
	end
end

-- Prints "[SENTIENTSYSTEMS] LOAD_READY" when the loading screen shows its button. The tuner
-- carries the line, but doesn't run commands until the click. In games that click the button for
-- the player, such as hotseat, the click follows at once.
local function OnLoadGameViewStateDone()
	SentientSystems_Print("LOAD_READY")
end

Events.LoadGameViewStateDone.Add(SentientSystems_CatchErrors("OnLoadGameViewStateDone", OnLoadGameViewStateDone))

-- Prints "[SENTIENTSYSTEMS] GAME_READY <turn>" when the player clicks the loading screen's button,
-- or the game clicks it for them. Commands work from then on. The tuner's socket resets right
-- after the click, and the line reaches the bridge before the reset.
local function OnLoadScreenClose()
	SentientSystems_Print("GAME_READY", Game.GetCurrentGameTurn())
end

Events.LoadScreenClose.Add(SentientSystems_CatchErrors("OnLoadScreenClose", OnLoadScreenClose))

-- Prints "[SENTIENTSYSTEMS] CORE_LOADED <state>" each time the script loads, including after a live
-- reload, so the log shows where the core mod started.
SentientSystems_Print("CORE_LOADED", ContextPtr:GetID())

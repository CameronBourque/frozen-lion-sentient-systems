-- The core mod's UI script. It runs in its own UI Lua state, where the request functions work.

include("SentientSystemsCore_Tag")

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

Events.PlayerTurnActivated.Add(OnPlayerTurnActivated)

-- Prints "[SENTIENTSYSTEMS] CORE_LOADED <state>" each time the script loads, including after a live
-- reload, so the log shows where the core mod started.
SentientSystems_Print("CORE_LOADED", ContextPtr:GetID())

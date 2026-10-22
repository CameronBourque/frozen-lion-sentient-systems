-- The core mod's gameplay script. It runs in a gameplay Lua state.

include("SentientSystemsCore_Tag")

-- Prints the turn signal, "[SENTIENTSYSTEMS] AGENT_TURN <playerID>", when a human player's turn starts.
local function OnPlayerTurnStarted(playerID)
	local player = Players[playerID]

	if player ~= nil and player:IsHuman() then
		SentientSystems_Print("AGENT_TURN", playerID)
	end
end

GameEvents.PlayerTurnStarted.Add(OnPlayerTurnStarted)

print("SentientSystemsCore_Gameplay loaded")

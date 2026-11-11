-- The artifact action on the artifact screen. SentientSystemsCore_Actions.lua
-- loads this file. The call is in docs/findings/actions/great-works.md.

SentientSystems_Include("SentientSystemsCore_Artifacts")

-- Returns why the player can't choose the artifact's player, or nil. The
-- game takes a player the artifact doesn't offer, so this checks the options
-- of the artifacts choice. See OnOpen in ChooseArtifact.lua.
local function GetArtifactFailure(pending, artifactPlayer)
	if pending == nil then
		return "You have no artifact to choose. The artifacts choice lists one once an archaeologist digs."
	end

	if not SentientSystems_Contains(pending.players, artifactPlayer) then
		return "Player " .. tostring(artifactPlayer) .. " isn't one of this artifact's players. Use a player from the artifacts choice."
	end

	return nil
end

local function ChooseArtifact(playerID, artifactPlayer)
	local pending = SentientSystems_GetNextArtifact(SentientSystems_GetPlayer(playerID))
	local failure = GetArtifactFailure(pending, artifactPlayer)

	if failure ~= nil then
		return failure
	end

	-- Both buttons of the screen send the player they name. See OnButton1.
	UI.RequestPlayerOperation(playerID, PlayerOperations.CHOOSE_ARTIFACT_PLAYER, { [PlayerOperations.PARAM_PLAYER_ONE] = artifactPlayer })

	return nil
end

-- Chooses whose artifact the digging archaeologist uncovers, a player from the
-- options of the artifacts choice, and returns the result as JSON.
function SentientSystems_ChooseArtifact(playerID, artifactPlayer)
	return SentientSystems_RunAction("ChooseArtifact", ChooseArtifact, playerID, artifactPlayer)
end

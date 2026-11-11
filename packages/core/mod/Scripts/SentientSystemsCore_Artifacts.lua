-- The artifact screen's rules that the artifact choice and the artifact action
-- share: the artifact the next digging archaeologist uncovers, and whose it can
-- be. Follows OnOpen in ChooseArtifact.lua.

include("SentientSystemsCore_Common")

-- The explanation for each type of site, and whether it offers both players. A
-- tribal village, a barbarian camp, and a heroic relic come from one player.
local SITES = {
	[0] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_NO_TYPE", choice = true },
	[1] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_GOODY_HUT" },
	[2] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_BARBARIAN_CAMP" },
	[3] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_BATTLE_FOUGHT", choice = true },
	[4] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_SHIP_SUNK", choice = true },
	[5] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_HEROIC_RELIC" },
}

-- Returns the artifact the next digging archaeologist uncovers, or nil with no
-- archaeologist digging or no artifact. It has the archaeologist, the artifact,
-- the explanation key of its site, and the players it can be chosen for: the
-- acting player, and the target player when the site offers both. The screen
-- opens only from the blocker's notification, so this reads the artifact only
-- while the blocker is up, as the spy choice must.
function SentientSystems_GetNextArtifact(player)
	if not SentientSystems_HasBlocker(player:GetID(), "ENDTURN_BLOCKING_ARTIFACT") then
		return nil
	end

	local archaeologist = player:GetUnits():GetNextExtractingArchaeologist()
	local artifact = archaeologist and Game.GetArtifactByIndex(archaeologist:GetArchaeology():GetArtifactIndex())

	if artifact == nil then
		return nil
	end

	local site = SITES[artifact.Type] or SITES[0]
	local players = { artifact.ActingPlayerID }

	if site.choice then
		players[2] = artifact.TargetPlayerID
	end

	return { archaeologist = archaeologist, artifact = artifact, key = site.key, players = players }
end

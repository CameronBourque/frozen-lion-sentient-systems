-- The artifact choice: whose artifact the player's next digging archaeologist uncovers, as the
-- artifact screen offers it. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetArtifactChoices(player) returns a table that encodes as
-- '[{"archaeologist":2686995,"description":"Your Archaeologist Remo has discovered an ancient
-- battlefield littered with items from Trajan and Free Cities.","era":"ERA_INDUSTRIAL","name":"Remo",
-- "options":[{"name":"Trajan","player":0},{"name":"Free Cities","player":62}],"x":48,"y":25}]', on
-- one line. The checks follow OnOpen in ChooseArtifact.lua.

-- The explanation for each type of site, and whether it offers both players. A tribal village, a
-- barbarian camp, and a heroic relic come from one player.
local SITES = {
	[0] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_NO_TYPE", choice = true },
	[1] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_GOODY_HUT" },
	[2] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_BARBARIAN_CAMP" },
	[3] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_BATTLE_FOUGHT", choice = true },
	[4] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_SHIP_SUNK", choice = true },
	[5] = { key = "LOC_CHOOSE_ARTIFACT_EXPLANATION_HEROIC_RELIC" },
}

-- Returns a player as an option: player, the ID the choice sends, and name.
local function Option(playerID)
	return { player = playerID, name = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()) }
end

-- Returns the artifact choice: the next digging archaeologist's artifact, with archaeologist, its
-- unit ID, name, x, y, era, the era the site is from, description, the screen's explanation, and
-- options, the players whose artifact it can be: the one player for a site with one, and the two
-- players for a battle or a shipwreck. Returns nil with no archaeologist digging, or no artifact. The
-- screen opens only from the blocker's notification, so this reads the artifact only while the
-- blocker is up, as the spy choice must. See OnOpen in ChooseArtifact.lua, lines 4 to 77.
function SentientSystems_GetArtifactChoices(player)
	if not SentientSystems_HasBlocker(player:GetID(), "ENDTURN_BLOCKING_ARTIFACT") then
		return nil
	end

	local archaeologist = player:GetUnits():GetNextExtractingArchaeologist()
	local artifact = archaeologist and Game.GetArtifactByIndex(archaeologist:GetArchaeology():GetArtifactIndex())

	if artifact == nil then
		return nil
	end

	local site = SITES[artifact.Type] or SITES[0]
	local acting, target = artifact.ActingPlayerID, artifact.TargetPlayerID
	local actingName = Locale.Lookup(PlayerConfigurations[acting]:GetPlayerName())
	local name = Locale.Lookup(archaeologist:GetName())
	local entry = {
		archaeologist = archaeologist:GetID(),
		name = name,
		x = archaeologist:GetX(),
		y = archaeologist:GetY(),
		era = GameInfo.Eras[artifact.ActingPlayerEra].EraType,
	}

	if site.choice then
		entry.description = Locale.Lookup(site.key, name, actingName, Locale.Lookup(PlayerConfigurations[target]:GetPlayerName()))
		entry.options = { Option(acting), Option(target) }
	else
		entry.description = Locale.Lookup(site.key, name, actingName)
		entry.options = { Option(acting) }
	end

	return { entry }
end

-- The artifact choice: whose artifact the next digging archaeologist uncovers,
-- as the artifact screen offers it. Follows OnOpen in ChooseArtifact.lua.
-- Shape: bridge/src/choices/artifacts.ts.

SentientSystems_Include("SentientSystemsCore_Artifacts")

local function Option(playerID)
	return { player = playerID, name = Locale.Lookup(PlayerConfigurations[playerID]:GetPlayerName()) }
end

-- Returns the artifact choice: the next digging archaeologist's artifact.
-- Returns nil with no archaeologist digging, or no artifact.
function SentientSystems_GetArtifactChoices(player)
	local pending = SentientSystems_GetNextArtifact(player)

	if pending == nil then
		return nil
	end

	local archaeologist, artifact = pending.archaeologist, pending.artifact
	local name = Locale.Lookup(archaeologist:GetName())
	local actingName = Locale.Lookup(PlayerConfigurations[artifact.ActingPlayerID]:GetPlayerName())
	local options = {}

	for i, playerID in ipairs(pending.players) do
		options[i] = Option(playerID)
	end

	local description
	if #options == 2 then
		description = SentientSystems_LookupText(pending.key, name, actingName, options[2].name)
	else
		description = SentientSystems_LookupText(pending.key, name, actingName)
	end

	return { {
		archaeologist = archaeologist:GetID(),
		name = name,
		x = archaeologist:GetX(),
		y = archaeologist:GetY(),
		era = GameInfo.Eras[artifact.ActingPlayerEra].EraType,
		description = description,
		options = options,
	} }
end

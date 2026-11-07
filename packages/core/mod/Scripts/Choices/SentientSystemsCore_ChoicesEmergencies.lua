-- The emergency choice, as the emergency popup offers it. Follows
-- OnEmergencyAvailable and ShowEmergency in WorldCrisisPopup.lua.
-- Shape: bridge/src/choices/emergencies.ts.

-- Returns the lines of a list of texts, as the popup shows them, cleaned of
-- the icons and colors, and without the empty ones.
local function Lines(list)
	local lines = {}

	for _, line in ipairs(list or {}) do
		lines[#lines + 1] = SentientSystems_CleanText(line)
	end

	return lines
end

-- Returns the goals the popup lists: the target's own for the target, and the
-- members' for anyone else, each by its name, leaving out one with no name.
local function GetGoals(entry, playerID)
	local goals = {}

	for _, goal in ipairs(entry.TargetID == playerID and entry.TargetGoalsTable or entry.GoalsTable or {}) do
		local name = SentientSystems_CleanText(goal.Name)

		if name ~= nil then
			goals[#goals + 1] = name
		end
	end

	return goals
end

-- Returns the rewards the popup lists: the members' first, top, bottom, and
-- extra tiers' lines and the extra rewards, and the target's lines, for a
-- hostile emergency.
local function GetRewards(entry, hostile)
	local members = {}

	for _, list in ipairs({ entry.MemberRewardsTextFirst, entry.MemberRewardsTextTop, entry.MemberRewardsTextBottom, entry.MemberRewardsTextExtra }) do
		for _, line in ipairs(Lines(list)) do
			members[#members + 1] = line
		end
	end

	members[#members + 1] = SentientSystems_CleanText(entry.ExtraRewards)

	return { members = members, target = hostile and Lines(entry.TargetRewardsText) or {} }
end

-- Returns the emergency choice: the next emergency that needs the player's
-- attention. targetCity is the city's name, as the popup looks it up. Returns
-- nil with none to look at. The popup reads the emergency only from the
-- blocker's notification, so this reads it only while the blocker is up, as the
-- spy choice must. See OnEmergencyAvailable in WorldCrisisPopup.lua.
function SentientSystems_GetEmergencyChoices(player)
	local playerID = player:GetID()

	if not SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION") then
		return nil
	end

	local manager = Game.GetEmergencyManager()
	local waiting = manager:GetNextBlockingEmergency(playerID)
	local entry

	for _, candidate in ipairs(waiting and manager:GetEmergencyInfoTable(playerID) or {}) do
		if candidate.EmergencyType == waiting.eEmergencyType and candidate.TargetID == waiting.eTarget then
			entry = candidate
			break
		end
	end

	if entry == nil then
		return nil
	end

	local hostile = GameInfo.Emergencies_XP2[entry.EmergencyType].Hostile == true
	local ongoing = entry.TurnsLeft >= 0
	local members = {}
	local buffs = ongoing and Lines(entry.BuffsText) or {}

	for _, memberID in ipairs(entry.MemberIDs) do
		if memberID ~= -1 then
			members[#members + 1] = memberID
		end
	end

	if ongoing then
		buffs[#buffs + 1] = SentientSystems_CleanText(entry.ExtraBuffs)
	end

	local succeeded

	if not ongoing then
		succeeded = entry.bSuccess == true
	end

	return {
		{
			type = GameInfo.EmergencyAlliances[entry.EmergencyType].EmergencyType,
			name = Locale.Lookup(entry.NameText),
			description = SentientSystems_CleanText(entry.ShortDescriptionText),
			goal = SentientSystems_CleanText(entry.GoalDescription),
			target = entry.TargetID,
			targetCity = entry.TargetCityName ~= "" and Locale.Lookup(entry.TargetCityName) or nil,
			hostile = hostile,
			turnsLeft = entry.TurnsLeft,
			succeeded = succeeded,
			options = entry.HasBegun and { "acknowledge" } or { "join", "reject" },
			members = members,
			goals = GetGoals(entry, playerID),
			scoring = ongoing and entry.TargetID ~= playerID and Lines(entry.ScoreSourcesTable) or nil,
			buffs = buffs,
			rewards = GetRewards(entry, hostile),
		},
	}
end

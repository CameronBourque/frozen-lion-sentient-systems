-- The emergency choice: the emergency the player has to look at, as the emergency popup offers it.
-- SentientSystemsCore_Choices.lua loads this file. Example: SentientSystems_GetEmergencyChoices(player)
-- returns a table that encodes as '[{"buffs":["..."],"description":"...","goal":"...","goals":["..."],
-- "hostile":true,"members":[0,4],"name":"Capture City-State","options":["join","reject"],
-- "rewards":{"members":["..."],"target":["..."]},"scoring":["..."],"target":9,"targetCity":"Hunza",
-- "turnsLeft":30,"type":"EMERGENCY_CAPTURE_CITY_STATE"}]', on one line. The checks follow
-- OnEmergencyAvailable and ShowEmergency in WorldCrisisPopup.lua and ProcessEmergency_WorldCrisisPopup
-- in WorldCrisisSupport.lua. Checked in a running game against the popup of an ongoing emergency. The
-- blocker's own case, with join and reject, hasn't been seen.

-- Returns the lines of a list of texts, as the popup shows them.
local function Lines(list)
	local lines = {}

	for _, line in ipairs(list or {}) do
		lines[#lines + 1] = line
	end

	return lines
end

-- Returns the goals the popup lists: the target's own for the target, and the members' for anyone
-- else, each by its name, leaving out one with no name.
local function GetGoals(entry, playerID)
	local goals = {}

	for _, goal in ipairs(entry.TargetID == playerID and entry.TargetGoalsTable or entry.GoalsTable or {}) do
		if goal.Name ~= "" then
			goals[#goals + 1] = goal.Name
		end
	end

	return goals
end

-- Returns the rewards the popup lists: members, the first, top, bottom, and extra tiers' lines and
-- the extra rewards, and target, the target's lines, for a hostile emergency.
local function GetRewards(entry, hostile)
	local members = {}

	for _, list in ipairs({ entry.MemberRewardsTextFirst, entry.MemberRewardsTextTop, entry.MemberRewardsTextBottom, entry.MemberRewardsTextExtra }) do
		for _, line in ipairs(Lines(list)) do
			members[#members + 1] = line
		end
	end

	if entry.ExtraRewards ~= "" then
		members[#members + 1] = entry.ExtraRewards
	end

	return { members = members, target = hostile and Lines(entry.TargetRewardsText) or {} }
end

-- Returns the emergency choice: the next emergency that needs the player's attention, with type,
-- such as EMERGENCY_CAPTURE_CITY_STATE, name, description, and goal, the popup's texts, target, the
-- target's player ID, targetCity, its city's name, as the popup looks it up, left out with none, hostile, turnsLeft, negative
-- for a finished one, options, join and reject for one that hasn't begun, and acknowledge for any
-- other, members, their player IDs, goals, scoring, how to gain score, left out for the target,
-- buffs, and rewards. Returns nil with none to look at. The popup reads the emergency only from the
-- blocker's notification, so this reads it only while the blocker is up, as the spy choice must. See
-- OnEmergencyAvailable in WorldCrisisPopup.lua, lines 31 to 61.
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

	if ongoing and entry.ExtraBuffs ~= "" then
		buffs[#buffs + 1] = entry.ExtraBuffs
	end

	return {
		{
			type = GameInfo.EmergencyAlliances[entry.EmergencyType].EmergencyType,
			name = Locale.Lookup(entry.NameText),
			description = entry.ShortDescriptionText,
			goal = entry.GoalDescription,
			target = entry.TargetID,
			targetCity = entry.TargetCityName ~= "" and Locale.Lookup(entry.TargetCityName) or nil,
			hostile = hostile,
			turnsLeft = entry.TurnsLeft,
			options = entry.HasBegun and { "acknowledge" } or { "join", "reject" },
			members = members,
			goals = GetGoals(entry, playerID),
			scoring = ongoing and entry.TargetID ~= playerID and Lines(entry.ScoreSourcesTable) or nil,
			buffs = buffs,
			rewards = GetRewards(entry, hostile),
		},
	}
end

-- The blockers section of the state: what stops the end of the turn, as the Next Turn button sees it,
-- and the units that need orders. SentientSystemsCore_State.lua loads this file. Example:
-- SentientSystems_GetBlockerState(0) returns a table that encodes as
-- '{"list":[{"choice":"techs","type":"ENDTURN_BLOCKING_RESEARCH"}],"units":[196608]}', on one line.

-- The key in the choices that resolves each blocker. A blocker that isn't here gets no choice: the
-- unit blockers, which the units list resolves, and the values that no UI file names. See
-- docs/findings/game-state.md.
local CHOICES = {
	ENDTURN_BLOCKING_PRODUCTION = "production",
	ENDTURN_BLOCKING_RESEARCH = "techs",
	ENDTURN_BLOCKING_CIVIC = "civics",
	ENDTURN_BLOCKING_FILL_CIVIC_SLOT = "government",
	ENDTURN_BLOCKING_CONSIDER_GOVERNMENT_CHANGE = "government",
	ENDTURN_BLOCKING_PANTHEON = "pantheon",
	ENDTURN_BLOCKING_RELIGION = "religion",
	ENDTURN_BLOCKING_BELIEF = "religion",
	ENDTURN_BLOCKING_GIVE_INFLUENCE_TOKEN = "envoys",
	ENDTURN_BLOCKING_CLAIM_GREAT_PERSON = "greatPeople",
	ENDTURN_BLOCKING_CONSIDER_RAZE_CITY = "capturedCities",
	ENDTURN_BLOCKING_CONSIDER_DISLOYAL_CITY = "capturedCities",
	ENDTURN_BLOCKING_SPY_CHOOSE_ESCAPE_ROUTE = "spies",
	ENDTURN_BLOCKING_SPY_CHOOSE_DRAGNET_PRIORITY = "spies",
	ENDTURN_BLOCKING_ARTIFACT = "artifacts",
	ENDTURN_BLOCKING_GOVERNOR_APPOINTMENT = "governors",
	ENDTURN_BLOCKING_GOVERNOR_OPPORTUNITY = "governors",
	ENDTURN_BLOCKING_GOVERNOR_PROMOTION = "governors",
	ENDTURN_BLOCKING_GOVERNOR_IDLE = "governors",
	ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE = "dedications",
	ENDTURN_BLOCKING_EMERGENCY_NEEDS_ATTENTION = "emergencies",
	ENDTURN_BLOCKING_WORLD_CONGRESS_LOOK = "worldCongress",
	ENDTURN_BLOCKING_WORLD_CONGRESS_SESSION = "worldCongress",
}

-- Returns the name of a blocker value. The values are hashes, so the name comes from searching
-- EndTurnBlockingTypes. A value the table doesn't hold keeps its number, as text.
local function BlockerName(value)
	for name, candidate in pairs(EndTurnBlockingTypes) do
		if candidate == value then
			return name
		end
	end

	return tostring(value)
end

-- Returns each blocker once, in the game's order, with the choice that resolves it. The game lists a
-- blocker once for each of its notifications, so a blocker can repeat. The first one is the Next Turn
-- button's prompt.
local function GetBlockerList(playerID)
	local list, seen = {}, {}

	for _, value in ipairs(NotificationManager.GetAllEndTurnBlocking(playerID) or {}) do
		if not seen[value] then
			local name = BlockerName(value)

			seen[value] = true
			list[#list + 1] = { type = name, choice = CHOICES[name] }
		end
	end

	return list
end

-- Returns the IDs of the player's units that need orders: those with moves left and no standing
-- order, such as fortify. The unit flags dim every other unit with IsReadyToSelect, in
-- UnitFlagManager.lua, line 380. The game updates the unit blockers only on its own events, so the
-- list comes from the units, not from the blockers.
local function GetUnitsNeedingOrders(player)
	local ids = {}

	for _, unit in player:GetUnits():Members() do
		if unit:IsReadyToSelect() then
			ids[#ids + 1] = unit:GetID()
		end
	end

	return ids
end

-- Returns the blockers of the player with ID playerID.
function SentientSystems_GetBlockerState(playerID)
	return {
		list = GetBlockerList(playerID),
		units = GetUnitsNeedingOrders(Players[playerID]),
	}
end

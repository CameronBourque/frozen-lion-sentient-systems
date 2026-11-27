-- The end turn action on the Next Turn button. SentientSystemsCore_Actions.lua
-- loads this file. The call is in docs/findings/actions/end-turn.md.

SentientSystems_Include("SentientSystemsCore_StateBlockers")
SentientSystems_Include("SentientSystemsCore_StateProposals")

-- The unit blockers. The game updates them only on its own events, so the
-- units list stands in for them. See docs/findings/state/end-turn-blockers.md.
local UNIT_BLOCKERS = {
	ENDTURN_BLOCKING_UNITS = true,
	ENDTURN_BLOCKING_UNIT_NEEDS_ORDERS = true,
	ENDTURN_BLOCKING_STACKED_UNITS = true,
}

-- The turn of the last end turn request, or nil before the first one and
-- after the turn starts again. A second request in one turn can skip a turn.
local requestedTurn = nil

-- Forgets the last end turn request. Call it when the player's turn starts.
-- The game cancels the end of a turn when a queued move stops short, and
-- starts the same turn again, so the request no longer stands. See
-- docs/findings/actions/end-turn.md.
function SentientSystems_ForgetEndTurn()
	requestedTurn = nil
end

-- Returns the player's blockers, with the unit blockers left out of the list,
-- since the units that need orders stand in for them.
local function GetTurnBlockers(playerID)
	local blockers = SentientSystems_GetBlockerState(playerID)
	local list = {}

	for _, blocker in ipairs(blockers.list) do
		if not UNIT_BLOCKERS[blocker.type] then
			list[#list + 1] = blocker
		end
	end

	return { list = list, units = blockers.units }
end

-- Returns the blockers as a reason lists them.
local function ListBlockers(list)
	local listed = {}

	for _, blocker in ipairs(list) do
		local choice = blocker.choice and " (the " .. blocker.choice .. " choice)" or ""

		listed[#listed + 1] = blocker.type .. choice
	end

	return listed
end

-- Returns why the turn can't end, or nil. The Next Turn button ends the turn
-- only with no blocker left. See DoEndTurn in ActionPanel.lua.
local function GetBlockedFailure(blockers)
	local listed = ListBlockers(blockers.list)
	local parts = {}

	if #listed > 0 then
		parts[#parts + 1] = " Blockers: " .. table.concat(listed, ", ") .. "."
	end

	if #blockers.units > 0 then
		parts[#parts + 1] = " Units that need orders: " .. table.concat(blockers.units, ", ") .. "."
	end

	if #parts == 0 then
		return nil
	end

	return "Resolve the blockers first, or pass force to end the turn anyway." .. table.concat(parts)
end

-- Returns why the turn can't end while a diplomacy session is open, or nil.
-- The request would only close the leader screen, and the AI turns wait for
-- the session. See docs/findings/actions/end-turn.md.
local function GetSessionFailure(playerID)
	local otherID = SentientSystems_FindOpenSession(playerID)

	if otherID == nil then
		return nil
	end

	if SentientSystems_GetProposedDeal(playerID, otherID) ~= nil then
		return "Player " .. otherID .. " has a deal waiting for you. Answer it with the deal response first."
	end

	return "Player " .. otherID .. " has a leader screen open with you. Answer it with the session response first."
end

local function EndTurn(playerID, force)
	SentientSystems_GetPlayer(playerID)

	local turn = Game.GetCurrentGameTurn()

	if requestedTurn == turn then
		return "You already ended turn " .. turn .. ". Wait for your next turn."
	end

	local sessionFailure = GetSessionFailure(playerID)

	if sessionFailure ~= nil then
		return sessionFailure
	end

	local blockers = GetTurnBlockers(playerID)

	if not force then
		local failure = GetBlockedFailure(blockers)

		if failure ~= nil then
			return failure
		end
	end

	UI.RequestAction(ActionTypes.ACTION_ENDTURN)
	requestedTurn = turn

	if force then
		return nil, { skipped = blockers }
	end

	return nil
end

-- Ends the player's turn, and returns the result as JSON. Without force, it
-- fails while a blocker is left. With force, the game skips the blockers, and
-- the result lists them. It fails while a diplomacy session is open, with or
-- without force.
function SentientSystems_EndTurn(playerID, force)
	return SentientSystems_RunAction("EndTurn", EndTurn, playerID, force)
end

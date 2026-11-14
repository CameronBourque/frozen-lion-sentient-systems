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

-- The turn of the last end turn request, or nil before the first one. A
-- second request in one turn can skip a turn.
local requestedTurn = nil

-- Returns the blockers other than the unit blockers, as a reason lists them.
local function ListBlockers(list)
	local listed = {}

	for _, blocker in ipairs(list) do
		if not UNIT_BLOCKERS[blocker.type] then
			local choice = blocker.choice and " (the " .. blocker.choice .. " choice)" or ""

			listed[#listed + 1] = blocker.type .. choice
		end
	end

	return listed
end

-- Returns why the turn can't end, or nil. The Next Turn button ends the turn
-- only with no blocker left. See DoEndTurn in ActionPanel.lua.
local function GetBlockedFailure(playerID)
	local blockers = SentientSystems_GetBlockerState(playerID)
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

	if not force then
		local failure = GetBlockedFailure(playerID)

		if failure ~= nil then
			return failure
		end
	end

	UI.RequestAction(ActionTypes.ACTION_ENDTURN)
	requestedTurn = turn

	return nil
end

-- Ends the player's turn, and returns the result as JSON. Without force, it
-- fails while a blocker is left. With force, the game skips the blockers. It
-- fails while a diplomacy session is open, with or without force.
function SentientSystems_EndTurn(playerID, force)
	return SentientSystems_RunAction("EndTurn", EndTurn, playerID, force)
end

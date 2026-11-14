-- The sessions section: the leader screens other players have opened with the
-- player, other than deals, as DiplomacyActionView.lua shows them.
-- Shape: bridge/src/state/sessions.ts.

-- The text for a disabled option whose check gives an empty list of reasons.
local NO_REASON = "The game gives no reason."

local function GetSortedSelections(selections)
	local sorted = {}

	for i, selection in ipairs(selections) do
		sorted[i] = selection
	end

	table.sort(sorted, function(a, b)
		return (a.Sort or 0) < (b.Sort or 0)
	end)

	return sorted
end

-- Returns whether the leader screen shows the option, and why it is disabled,
-- as DiplomacySupport_RemoveInvalidSelections in DiplomacyStatementSupport.lua
-- decides. It drops an invalid option the check gives no reasons for.
local function GetOptionStatus(player, otherID, selection)
	if selection.DiplomaticActionType == nil then
		return true, nil
	end

	local valid, results = player:GetDiplomacy():IsDiplomaticActionValid(selection.DiplomaticActionType, otherID, true)

	if valid then
		return true, nil
	end

	if results == nil or results.FailureReasons == nil then
		return false, nil
	end

	return true, SentientSystems_GetFailureReasons(results, "FailureReasons")[1] or NO_REASON
end

local function GetOptions(player, otherID, selections)
	local options = {}

	for _, selection in ipairs(GetSortedSelections(selections)) do
		local shown, disabled = GetOptionStatus(player, otherID, selection)

		-- The leader screen offers to stop asking only to an AI.
		if selection.Key == "CHOICE_STOP_ASKING" and PlayerConfigurations[otherID]:IsHuman() then
			shown = false
		end

		if shown then
			options[#options + 1] = {
				key = selection.Key,
				text = selection.Text and SentientSystems_CleanText(Locale.Lookup(selection.Text)),
				disabled = disabled,
			}
		end
	end

	return options
end

-- Returns the entry of a session whose statement the core mod saw, or nil for
-- a deal.
local function GetStatementEntry(player, otherID, statement)
	local typeName = DiplomacyManager.GetKeyName(statement.StatementType)
	local subTypeName = DiplomacyManager.GetKeyName(statement.StatementSubType)

	if SentientSystems_IsDealStatement(typeName) then
		return nil
	end

	local entry = { from = otherID, statement = typeName, subType = subTypeName ~= "NONE" and subTypeName or nil }
	local row, selections = SentientSystems_GetStatementRows(otherID, player:GetID(), statement)

	if row == nil then
		entry.unknown = true

		return entry
	end

	entry.text, entry.reason = SentientSystems_GetStatementText(row, otherID, player:GetID(), statement)
	entry.options = GetOptions(player, otherID, selections)

	return entry
end

-- Returns the entry of the session the other player has open with the player,
-- or nil for none, for a deal, and for a session the player started that has
-- no answer yet. See docs/findings/actions/first-meetings.md.
local function GetSessionEntry(player, otherID)
	local playerID = player:GetID()
	local statement, sessionID = SentientSystems_GetOpenStatement(playerID, otherID)

	if statement ~= nil then
		return GetStatementEntry(player, otherID, statement)
	end

	if sessionID == nil or DiplomacyManager.GetSessionInfo(sessionID).FromPlayer ~= otherID
		or SentientSystems_GetProposedDeal(playerID, otherID) ~= nil then
		return nil
	end

	-- A queued session looks open to every call. With a statement up, the
	-- others wait behind it. With none, as when the game loads with a session
	-- open, the core mod missed it, and the agent can still close it.
	if SentientSystems_HasOpenStatement(playerID) then
		return { from = otherID, queued = true }
	end

	return { from = otherID, unknown = true }
end

-- Returns the open sessions, one for each other player, in ID order.
function SentientSystems_GetSessionState(player)
	local list = {}

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local entry = other:GetID() ~= player:GetID() and GetSessionEntry(player, other:GetID())

		if entry then
			list[#list + 1] = entry
		end
	end

	return list
end

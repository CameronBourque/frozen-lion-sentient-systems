-- The leader screen sessions an AI opens with a player. Closes the ones that
-- offer only a goodbye and keeps what the leader said, and remembers the
-- statement of each one left open. See docs/findings/actions/ai-sessions.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Text")

-- The statements that hold a deal. The proposals section and the deal action
-- handle their sessions.
local DEAL_STATEMENTS = { MAKE_DEAL = true, MAKE_DEMAND = true }

-- The mood of each diplomatic state that isn't NEUTRAL, as
-- DiplomacySupport_GetPlayerMood in DiplomacyStatementSupport.lua gives it.
local STATE_MOODS = {
	DIPLO_STATE_ALLIED = "HAPPY",
	DIPLO_STATE_DECLARED_FRIEND = "HAPPY",
	DIPLO_STATE_DENOUNCED = "UNHAPPY",
	DIPLO_STATE_WAR = "UNHAPPY",
}

-- The messages of the goodbyes closed, oldest first. A global, so including
-- this file again keeps them. They are lost when the game loads.
SentientSystems_SessionMessages = SentientSystems_SessionMessages or {}

-- The latest statement of each session left open, by session ID. No game call
-- returns it, so it is lost when the game loads.
SentientSystems_OpenStatements = SentientSystems_OpenStatements or {}

-- Returns the mood name the leader screen picks rows with. A statement sent
-- before its action takes effect has no mood, so the screen uses the
-- diplomatic state, as GetStatementMood in DiplomacyActionView.lua does.
local function GetMoodName(fromID, toID, mood)
	if mood == nil then
		return "ANY"
	end

	if mood ~= DiplomacyMoodTypes.UNDEFINED then
		return DiplomacyManager.GetKeyName(mood) or "ANY"
	end

	local index = Players[fromID]:GetDiplomaticAI():GetDiplomaticStateIndex(toID)

	return STATE_MOODS[GameInfo.DiplomaticStates[index].StateType] or "NEUTRAL"
end

-- Returns the rows that match, for one leader and mood.
local function GetMatchingRows(rows, matches, leader, mood)
	local found = {}

	for row in rows() do
		if row.Leader == leader and row.Mood == mood and matches(row) then
			found[#found + 1] = row
		end
	end

	return found
end

-- Returns the rows for the first leader and mood pair that has any, in the
-- order DiplomacySupport_ExtractStatement tries them.
local function FindStatementRows(rows, matches, leader, mood)
	for _, pair in ipairs({ { leader, mood }, { leader, "ANY" }, { "ANY", mood }, { "ANY", "ANY" } }) do
		local found = GetMatchingRows(rows, matches, pair[1], pair[2])

		if #found > 0 then
			return found
		end
	end

	return {}
end

-- Returns a statement's row and its selection rows, or nil for a statement
-- with no row. Follows DiplomacySupport_ExtractStatement, which treats an
-- unknown initiator as a human.
function SentientSystems_GetStatementRows(fromID, toID, statement)
	local config = statement.Initiator ~= nil and PlayerConfigurations[statement.Initiator]
	local initiator = (config and not config:IsHuman()) and "AI" or "HUMAN"
	local typeName = DiplomacyManager.GetKeyName(statement.StatementType)
	local subTypeName = DiplomacyManager.GetKeyName(statement.StatementSubType)
	local leader = PlayerConfigurations[fromID]:GetLeaderTypeName() or "ANY"
	local mood = GetMoodName(fromID, toID, statement.FromPlayerMood)
	local row = FindStatementRows(GameInfo.DiplomacyStatements, function(candidate)
		return candidate.Type == typeName and candidate.SubType == subTypeName and candidate.Initiator == initiator
	end, leader, mood)[1]

	if row == nil then
		return nil
	end

	return row, FindStatementRows(GameInfo.DiplomacySelections, function(candidate)
		return candidate.Type == row.Selections
	end, leader, mood)
end

function SentientSystems_IsDealStatement(typeName)
	return DEAL_STATEMENTS[typeName] == true
end

-- Returns whether every selection is the goodbye, CHOICE_EXIT.
local function IsGoodbyeOnly(selections)
	for _, selection in ipairs(selections) do
		if selection.Key ~= "CHOICE_EXIT" then
			return false
		end
	end

	return #selections > 0
end

-- Returns the reason the leader screen shows under the text, with the agenda,
-- as ApplyStatement in DiplomacyActionView.lua builds it, or nil for none.
local function GetStatementReason(row, fromID, toID, statement)
	local key = DiplomacyManager.FindReasonTextKey(row.ReasonText, fromID, statement.AiReason, statement.AiModifier)

	if key == nil then
		return nil
	end

	local agenda = DiplomacyManager.FindReasonAgendaTextKey(fromID, toID, statement.AiReason, statement.AiModifier)

	return SentientSystems_CleanText(Locale.Lookup(key) .. (agenda or ""))
end

-- Returns what the leader says, and the reason under it, as the leader screen
-- shows them. Either is nil when the statement has none.
function SentientSystems_GetStatementText(row, fromID, toID, statement)
	-- The leader screen passes FromMood, which statements don't have.
	local text = row.StatementText and SentientSystems_CleanText(
		Locale.Lookup(DiplomacyManager.FindTextKey(row.StatementText, fromID, statement.FromMood, toID))
	)

	return text, GetStatementReason(row, fromID, toID, statement)
end

-- Keeps a message, and drops those from before the previous turn, so each
-- lasts through the agent's next turn.
local function AddSessionMessage(message)
	local kept = {}

	for _, old in ipairs(SentientSystems_SessionMessages) do
		if old.turn >= message.turn - 1 then
			kept[#kept + 1] = old
		end
	end

	kept[#kept + 1] = message
	SentientSystems_SessionMessages = kept
end

-- Returns whether the statement is an AI's that offers the player only the
-- goodbye. A deal, a request, or a statement with no row isn't.
local function IsGoodbyeStatement(fromID, toID, statement, row, selections)
	local typeName = DiplomacyManager.GetKeyName(statement.StatementType)

	return not PlayerConfigurations[fromID]:IsHuman() and not DEAL_STATEMENTS[typeName]
		and row ~= nil and IsGoodbyeOnly(selections)
end

local function CopyStatement(fromID, toID, statement)
	local copy = { from = fromID, to = toID }

	for key, value in pairs(statement) do
		copy[key] = value
	end

	return copy
end

-- Closes a session when an AI's statement to the player offers only the
-- goodbye, and keeps what the leader said. Remembers the statement of any
-- other session, which stays open.
function SentientSystems_HandleStatement(fromID, toID, statement)
	local row, selections = SentientSystems_GetStatementRows(fromID, toID, statement)

	if not IsGoodbyeStatement(fromID, toID, statement, row, selections) then
		-- The game may reuse the table, so this keeps a copy.
		SentientSystems_OpenStatements[statement.SessionID] = CopyStatement(fromID, toID, statement)

		return
	end

	local text, reason = SentientSystems_GetStatementText(row, fromID, toID, statement)

	DiplomacyManager.CloseSession(statement.SessionID)
	SentientSystems_OpenStatements[statement.SessionID] = nil
	AddSessionMessage({
		from = fromID,
		to = toID,
		turn = Game.GetCurrentGameTurn(),
		statement = DiplomacyManager.GetKeyName(statement.StatementType),
		text = text,
		reason = reason,
	})
end

function SentientSystems_ForgetSession(sessionID)
	SentientSystems_OpenStatements[sessionID] = nil
end

-- Returns the latest statement of the session open between the player and the
-- other player, with its from and to, or nil. Also returns the session ID, or
-- nil when no session is open.
function SentientSystems_GetOpenStatement(playerID, otherID)
	local sessionID = DiplomacyManager.FindOpenSessionID(playerID, otherID)

	if sessionID == nil or sessionID == -1 then
		return nil
	end

	local statement = SentientSystems_OpenStatements[sessionID]

	if statement ~= nil and statement.to == playerID and statement.from == otherID then
		return statement, sessionID
	end

	return nil, sessionID
end

-- Returns the messages from the other player to the player, from the previous
-- turn and this one, oldest first. Shape: bridge/src/state/diplomacy.ts.
function SentientSystems_GetSessionMessages(playerID, otherID)
	local turn = Game.GetCurrentGameTurn()
	local list = {}

	for _, message in ipairs(SentientSystems_SessionMessages) do
		if message.to == playerID and message.from == otherID and message.turn >= turn - 1 then
			list[#list + 1] = { turn = message.turn, statement = message.statement, text = message.text, reason = message.reason }
		end
	end

	return list
end

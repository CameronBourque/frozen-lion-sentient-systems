-- Leader screen sessions. Fakes the statement and selection tables and the
-- DiplomacyManager calls that read a statement. A hash here is the name
-- itself, so GetKeyName returns a name as it is and has none for a number.

-- Returns the rows with ANY for a leader or mood they don't give.
local function WithAnyLeaderAndMood(rows)
	for _, row in ipairs(rows) do
		row.Leader = row.Leader or "ANY"
		row.Mood = row.Mood or "ANY"
	end

	return rows
end

return function(env, world, ctx)
	local manager = env.DiplomacyManager

	env.GameInfo.DiplomacyStatements = ctx.Callable(WithAnyLeaderAndMood(world.statements or {}))
	env.GameInfo.DiplomacySelections = ctx.Callable(WithAnyLeaderAndMood(world.selections or {}))
	env.DiplomacyMoodTypes = { UNDEFINED = -1 }

	function manager.GetKeyName(value)
		if type(value) == "string" then
			return value
		end
	end

	-- The key names the players, so a test can check them.
	function manager.FindTextKey(text, fromID, mood, toID)
		return text .. ":" .. fromID .. ":" .. tostring(mood) .. ":" .. toID
	end

	function manager.FindReasonTextKey(reasonText, fromID, aiReason, aiModifier)
		if reasonText ~= nil and aiModifier ~= nil then
			return reasonText .. ":" .. fromID .. ":" .. tostring(aiReason) .. ":" .. aiModifier
		end
	end

	-- The game returns the agenda as text to add to the reason.
	function manager.FindReasonAgendaTextKey(_, _, _, aiModifier)
		return (world.agendaReasons or {})[aiModifier]
	end
end

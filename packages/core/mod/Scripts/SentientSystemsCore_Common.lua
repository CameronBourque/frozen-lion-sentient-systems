-- Helpers that every core mod script loads first: tagged lines for the bridge, error catching for
-- event handlers, and a checked include. Each tagged line starts with the tag, so the bridge can
-- tell it apart from other game output. Example: SentientSystems_Print("AGENT_TURN", 0) prints
-- "[SENTIENTSYSTEMS] AGENT_TURN 0".

SENTIENTSYSTEMS_TAG = "[SENTIENTSYSTEMS]"

function SentientSystems_Print(...)
	local parts = { SENTIENTSYSTEMS_TAG }

	for i = 1, select("#", ...) do
		parts[#parts + 1] = tostring(select(i, ...))
	end

	print(table.concat(parts, " "))
end

-- Loads an imported file by name, as include does, and returns the paths it loaded. When no file has
-- the name, include returns an empty list and raises no error, so this prints
-- "[SENTIENTSYSTEMS] ERROR include <message>" for the bridge to log. The game finds a file added to
-- the .modinfo only after a restart. See docs/findings/lua-contexts.md. Example:
-- SentientSystems_Include("SentientSystemsCore_State")
function SentientSystems_Include(name)
	local loaded = include(name)

	if loaded == nil or #loaded == 0 then
		SentientSystems_Print("ERROR", "include", "found no file named " .. name .. ". After you add a file to the .modinfo, restart the game")
	end

	return loaded
end

-- Escapes text for one tagged line: each backslash as \\ and each newline as \n. The tuner sends
-- each line of a print as its own line, and only the first one has the state's name in front.
local function EscapeLine(text)
	return (text:gsub("\\", "\\\\"):gsub("\r?\n", "\\n"))
end

-- Returns a function that calls handler with the same arguments, and prints
-- "[SENTIENTSYSTEMS] ERROR <name> <message>" in place of a Lua error, so the bridge logs it. name
-- is the handler's name, because a Lua function doesn't know its own. The game's Lua puts the stack
-- trace in the error message, so pcall gets it with no debug library, which UI states don't have.
-- Example:
-- Events.PlayerTurnActivated.Add(SentientSystems_CatchErrors("OnPlayerTurnActivated", OnPlayerTurnActivated))
function SentientSystems_CatchErrors(name, handler)
	return function(...)
		local ok, err = pcall(handler, ...)

		if not ok then
			SentientSystems_Print("ERROR", name, EscapeLine(tostring(err)))
		end
	end
end

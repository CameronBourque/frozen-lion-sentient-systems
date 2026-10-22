-- Prints machine-readable lines for the bridge. Each line starts with the tag, so the bridge can
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

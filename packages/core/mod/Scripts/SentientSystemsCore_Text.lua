-- Helpers for the game's own text, which carries markup that the agent has no
-- use for.

-- Returns the lines of a tooltip, without the icons and the empty lines, as the
-- game separates them with [NEWLINE].
function SentientSystems_GetTooltipLines(tooltip)
	local lines = {}

	for line in (tooltip .. "[NEWLINE]"):gmatch("(.-)%[NEWLINE%]") do
		line = line:gsub("%[ICON_%w+%]%s*", ""):match("^%s*(.-)%s*$")

		if line ~= "" then
			lines[#lines + 1] = line
		end
	end

	return lines
end

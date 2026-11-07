-- Helpers for the game's own text, which carries markup that the agent has no
-- use for.

-- Icons that the game uses as list bullets. A tooltip's lines drop them, and
-- cleaned text writes a dash for one at the start of a line.
local LIST_MARKERS = { bullet = true, bolt = true }

-- Icons that only decorate the screen's own text.
local DROPPED = { checkmark = true, checkmarkblue = true }

-- The words that make an icon redundant when they follow it, for an icon that
-- the words of its own name don't repeat.
local FOLLOWERS = {
	citizen = { "Population" },
	pressureup = { "Rising" },
	pressuredown = { "Falling" },
	strength = { "Combat" },
}

-- The icons whose names have more than one word, as the game's font icons
-- spell them, to give the words of a name that the text writes in capitals.
local MULTIWORD = {
	"GreatPerson", "TradeRoute", "TradingPost", "FoodPerTurn", "FoodSurplus",
	"FoodDeficit", "InfluencePerTurn", "CivicBoosted", "TechBoosted",
	"GreatAdmiral", "GreatArtist", "GreatEngineer", "GreatGeneral",
	"GreatMerchant", "GreatMusician", "GreatProphet", "GreatScientist",
	"GreatWriter", "CityStateQuest", "HousingInsufficient",
	"AmenitiesInsufficient", "UnderSiege",
}

local MULTIWORD_BY_LOWER = {}

for _, name in ipairs(MULTIWORD) do
	MULTIWORD_BY_LOWER[name:lower()] = name
end

-- Returns the words of an icon's name, split at its capitals and underscores,
-- without a Large size. A name in capitals is spelled as the game's font icons
-- have it, or else as capitalized words after a resource or district prefix.
local function GetIconName(name)
	if not name:find("%l") then
		local spelled = MULTIWORD_BY_LOWER[name:lower()]

		if spelled == nil then
			local words = name:lower():gsub("^resource_", ""):gsub("^district_", ""):gsub("_", " ")

			return (words:gsub("(%a)(%a*)", function(first, rest)
				return first:upper() .. rest
			end))
		end

		name = spelled
	end

	name = name:gsub("_?Large$", ""):gsub("_", " ")

	return (name:gsub("(%l)(%u)", "%1 %2"))
end

-- Returns whether the text starts with the phrase as a word, or as its plural.
local function StartsWithWord(text, phrase)
	if text:sub(1, #phrase):lower() ~= phrase:lower() then
		return false
	end

	local tail = text:sub(#phrase + 1)

	if tail:match("^s$") or tail:match("^s%A") then
		tail = tail:sub(2)
	end

	return not tail:match("^%a")
end

-- Returns whether the text that follows an icon already says what the icon
-- shows.
local function IsFollowedByName(rest, key, name)
	for _, phrase in ipairs(FOLLOWERS[key] or { name }) do
		if StartsWithWord(rest, phrase) then
			return true
		end
	end

	return false
end

-- Returns a line without its color tags, and with each icon replaced: a list
-- marker at the start of the line by a dash when keepMarkers is set, and any
-- other marker, a decorative icon, or an icon followed by its own name by
-- nothing. Any other icon becomes its name.
local function CleanLine(line, keepMarkers)
	local result, position = "", 1

	line = line:gsub("%[COLOR[_:][%w_]+%]", ""):gsub("%[ENDCOLOR%]", "")

	while true do
		local first, last, icon = line:find("%[ICON_([%w_]+)%]", position)

		if first == nil then
			return result .. line:sub(position)
		end

		result = result .. line:sub(position, first - 1)

		local key, name = icon:lower(), GetIconName(icon)
		local rest = line:sub(last + 1)
		local text = rest:match("^%s*(.*)$")
		local replacement = name
		local skipSpace = false

		if DROPPED[key] or IsFollowedByName(text, key, name) then
			replacement, skipSpace = "", true
		elseif LIST_MARKERS[key] then
			if keepMarkers and result:match("^%s*$") then
				replacement = "-"
			else
				replacement, skipSpace = "", true
			end
		end

		result = result .. replacement
		position = last + 1 + (skipSpace and #rest - #text or 0)
	end
end

-- Calls handle with each line of a tooltip, which the game separates with
-- [NEWLINE].
local function EachLine(tooltip, handle)
	for line in (tooltip .. "[NEWLINE]"):gmatch("(.-)%[NEWLINE%]") do
		handle(line)
	end
end

-- Returns the text with each icon cleaned as CleanLine does, so that the text
-- reads without the icons. The lines stay separated with [NEWLINE].
function SentientSystems_CleanText(text)
	local lines = {}

	EachLine(text, function(line)
		lines[#lines + 1] = CleanLine(line, true)
	end)

	return table.concat(lines, "[NEWLINE]")
end

-- Returns the lines of a tooltip, cleaned of the icons, trimmed, and without
-- the empty lines, as the game separates them with [NEWLINE]. Meant for
-- reading a line, so it leaves out the dash that cleaned text has for a list
-- marker.
function SentientSystems_GetTooltipLines(tooltip)
	local lines = {}

	EachLine(tooltip, function(line)
		line = CleanLine(line, false):match("^%s*(.-)%s*$")

		if line ~= "" then
			lines[#lines + 1] = line
		end
	end)

	return lines
end

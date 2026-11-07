-- Helpers for the game's own text, which carries markup that the agent has no
-- use for.

-- Icons that the game uses as list bullets. A tooltip's lines drop them, and
-- cleaned text writes a dash for one at the start of a line.
local LIST_MARKERS = { bullet = true, bolt = true }

-- Icons that only decorate the screen's own text.
local DROPPED = { checkmark = true, checkmarkblue = true }

-- The words that make an icon redundant when they are next to it, besides the
-- words of its own name, for the icons that the game words differently.
local ALIASES = {
	citizen = { "Population" },
	pressureup = { "Rising" },
	pressuredown = { "Falling" },
	strength = { "Combat", "Defense" },
	greatperson = { "Great People" },
	techboosted = { "Eureka" },
	civicboosted = { "Inspiration" },
	religion = { "Religious" },
	favor = { "Diplomatic Favor" },
}

-- The prefixes that group icon names. The words of one are also said next to
-- an icon of its group.
local PREFIXES = { "resource", "district", "greatwork" }

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

-- Returns the words of a name in capitals, spelled as the game's font icons
-- have them, or else as capitalized words.
local function GetCapitalsName(name)
	local spelled = MULTIWORD_BY_LOWER[name:lower()]

	if spelled ~= nil then
		return spelled
	end

	return (name:lower():gsub("_", " "):gsub("(%a)(%a*)", function(first, rest)
		return first:upper() .. rest
	end))
end

-- Returns the words of a name, split at its capitals and underscores, without a
-- Large size.
local function SplitName(name)
	if not name:find("%l") then
		name = GetCapitalsName(name)
	end

	name = name:gsub("_?Large$", ""):gsub("_", " ")

	return (name:gsub("(%l)(%u)", "%1 %2"))
end

-- Returns the words of an icon's name without its group prefix, and the words
-- of the prefix, if it has one.
local function GetIconName(icon)
	local lower = icon:lower()

	for _, prefix in ipairs(PREFIXES) do
		if lower:sub(1, #prefix + 1) == prefix .. "_" then
			return SplitName(icon:sub(#prefix + 2)), SplitName(icon:sub(1, #prefix))
		end
	end

	return SplitName(icon), nil
end

-- Returns a word without its plural ending, in lower case, so that a word and
-- its plural are the same.
local function Stem(word)
	word = word:lower()

	if word:match("ies$") then
		return word:sub(1, -4) .. "y"
	elseif word:match("[^s]s$") then
		return word:sub(1, -2)
	end

	return word
end

-- Returns whether the text starts with the words of the phrase.
local function StartsWithWords(text, phrase)
	local position = 1

	for word in phrase:gmatch("%a+") do
		local _, last, found = text:find("^%s*(%a+)", position)

		if found == nil or Stem(found) ~= Stem(word) then
			return false
		end

		position = last + 1
	end

	return true
end

-- Returns whether the text ends with the words of the phrase.
local function EndsWithWords(text, phrase)
	local words = {}

	for word in phrase:gmatch("%a+") do
		words[#words + 1] = word
	end

	for i = #words, 1, -1 do
		local before, found = text:match("^(.-)(%a+)%s*$")

		if found == nil or Stem(found) ~= Stem(words[i]) then
			return false
		end

		text = before
	end

	return true
end

-- Returns the phrases that say what an icon shows when they are next to it: the
-- words of its name and its prefix, and any others the game words it with.
local function GetPhrases(key, name, prefix)
	local phrases = { name, prefix }

	for _, alias in ipairs(ALIASES[key] or {}) do
		phrases[#phrases + 1] = alias
	end

	return phrases
end

-- Returns whether the text that follows an icon already says what the icon
-- shows, after an amount if it starts with one.
local function IsFollowedByName(rest, phrases)
	local named = rest:match("^[%+%-]?[%d%.,]+%s*(.*)$") or rest

	for _, phrase in ipairs(phrases) do
		if StartsWithWords(rest, phrase) or StartsWithWords(named, phrase) then
			return true
		end
	end

	return false
end

-- Returns whether the text before an icon ends with what the icon shows.
local function IsPrecededByName(before, phrases)
	for _, phrase in ipairs(phrases) do
		if EndsWithWords(before, phrase) then
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

		local key = icon:lower()
		local name, prefix = GetIconName(icon)
		local rest = line:sub(last + 1)
		local text = rest:match("^%s*(.*)$")
		local phrases = GetPhrases(key, name, prefix)
		local replacement = name
		local skipSpace = false

		if DROPPED[key] or IsFollowedByName(text, phrases) then
			replacement, skipSpace = "", true
		elseif IsPrecededByName(result, phrases) then
			replacement, skipSpace = "", true

			if text:match("^[%.,;:%)]") then
				result = result:gsub("%s+$", "")
			end
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
-- reads without the icons. The lines stay separated with [NEWLINE]. Returns nil
-- for no text, or for text that is empty once cleaned.
function SentientSystems_CleanText(text)
	if text == nil then
		return nil
	end

	local lines = {}

	EachLine(text, function(line)
		lines[#lines + 1] = CleanLine(line, true)
	end)

	local cleaned = table.concat(lines, "[NEWLINE]")

	return cleaned ~= "" and cleaned or nil
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

-- Returns the text of a text key, looked up with its arguments, cleaned as
-- SentientSystems_CleanText does. Always returns text, which is empty for a
-- blank text.
function SentientSystems_LookupText(key, ...)
	return SentientSystems_CleanText(Locale.Lookup(key, ...)) or ""
end

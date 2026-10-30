-- The victories section of the state: how close each living major player is to each victory, in the
-- order the Overall tab of World Rankings ranks them, with the values its icon tooltips show.
-- SentientSystemsCore_State.lua loads this file. Format: docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetVictoryState(player) returns a table that encodes as '{"culture":[...],
-- "domination":[...],"religion":[...],"science":[{"player":0,"progress":0,"sciencePerTurn":2.7,
-- "techs":3},{"unmet":true}]}', on one line. The order and values follow
-- PopulateOverallInstance in WorldRankings.lua and g_victoryData in WorldRankings_Expansion2.lua.
-- The details of each victory come from SentientSystemsCore_StateVictories*.lua.

-- Returns whether the player is the other player or has met them. The tabs
-- show who a player is only then.
function SentientSystems_IsKnownPlayer(player, id)
	return id == player:GetID() or player:GetDiplomacy():HasMet(id)
end

-- Returns the lines of a tooltip, without the icons, as the game separates
-- them with [NEWLINE].
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

SentientSystems_Include("SentientSystemsCore_StateVictoriesScience")
SentientSystems_Include("SentientSystemsCore_StateVictoriesCulture")
SentientSystems_Include("SentientSystemsCore_StateVictoriesDomination")
SentientSystems_Include("SentientSystemsCore_StateVictoriesReligion")

-- Rounds to the nearest tenth, as the tooltips round.
local function RoundNearest(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Rounds a progress to the nearest thousandth, which the game's single precision floats leave long.
local function RoundProgress(progress)
	return math.floor(progress * 1000 + 0.5) / 1000
end

-- The victories in the Overall tab's order. values returns the two numbers that the tooltip shows
-- and that break a tie, the first one first, and what the section names them. A player is in the
-- section as { primary, secondary, values }. details, if there is one, returns more keys for a
-- player's entry, and is told whether the player has met them.
local VICTORIES = {
	{
		key = "science",
		type = "VICTORY_TECHNOLOGY",
		details = function(player, other, met)
			return met and SentientSystems_GetScienceDetails(player, other) or {}
		end,
		values = function(other)
			return other:GetStats():GetNumTechsResearched(), other:GetTechs():GetScienceYield(), "techs", "sciencePerTurn"
		end,
	},
	{
		key = "culture",
		type = "VICTORY_CULTURE",
		details = SentientSystems_GetCultureDetails,
		values = function(other)
			return other:GetStats():GetTourism(), other:GetCulture():GetCultureYield(), "tourismPerTurn", "culturePerTurn"
		end,
	},
	{
		key = "domination",
		type = "VICTORY_CONQUEST",
		details = SentientSystems_GetDominationDetails,
		values = function(other)
			local strength = other:GetStats():GetMilitaryStrengthWithoutTreasury()

			return strength, strength, "military", nil
		end,
	},
	{
		key = "religion",
		type = "VICTORY_RELIGIOUS",
		details = SentientSystems_GetReligionDetails,
		values = function(other)
			return other:GetStats():GetNumCitiesFollowingReligion(), other:GetReligion():GetFaithYield(), "cities", "faithPerTurn"
		end,
	},
	{
		key = "diplomatic",
		type = "VICTORY_DIPLOMATIC",
		expansion2 = true,
		details = function(_, other)
			local stats = other:GetStats()
			local lines = SentientSystems_GetTooltipLines(stats:GetDiplomaticVictoryPointsTooltip())

			return {
				points = stats:GetDiplomaticVictoryPoints(),
				required = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED,
				breakdown = #lines > 0 and lines or nil,
			}
		end,
		values = function(other)
			local points = other:GetStats():GetDiplomaticVictoryPoints()

			return points, points, nil, nil
		end,
	},
}

-- Returns the entry of a player in a victory's ranking, and what it sorts by. A player that the
-- player has not met has unmet, true, and no ID, and only the keys that the victory's tab shows
-- for them.
local function GetRanked(player, other, victory)
	local id = other:GetID()
	local met = SentientSystems_IsKnownPlayer(player, id)
	local first, second, firstKey, secondKey = victory.values(other)
	local ranked = {
		id = id,
		progress = Game.GetVictoryProgressForTeam(victory.type, other:GetTeam()),
		first = first,
		second = second,
		score = other:GetScore(),
		entry = { unmet = true },
	}

	if met then
		ranked.entry = { player = id, progress = RoundProgress(ranked.progress) }

		if firstKey ~= nil then
			ranked.entry[firstKey] = RoundNearest(first)
		end

		if secondKey ~= nil then
			ranked.entry[secondKey] = RoundNearest(second)
		end
	end

	if victory.details ~= nil then
		for key, value in pairs(victory.details(player, other, met)) do
			ranked.entry[key] = value
		end
	end

	return ranked
end

-- Returns the players that can win a victory, best first: by progress, the two tooltip numbers, the
-- player's score, and the lower ID, as PopulateOverallInstance sorts the teams.
local function GetRanking(player, victory)
	local ranking = {}

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		if Game.GetVictoryProgressForTeam(victory.type, other:GetTeam()) ~= nil then
			ranking[#ranking + 1] = GetRanked(player, other, victory)
		end
	end

	table.sort(ranking, function(a, b)
		for _, field in ipairs({ "progress", "first", "second", "score" }) do
			if a[field] ~= b[field] then
				return a[field] > b[field]
			end
		end

		return a.id < b.id
	end)

	local entries = {}

	for i, ranked in ipairs(ranking) do
		entries[i] = ranked.entry
	end

	return entries
end

-- Returns a table with a list for each victory that is on and that a player can win, science,
-- culture, domination, religion, and, with Gathering Storm, diplomatic. Each list has one entry for
-- each living major player, best first. The player and each player they have met have player, their
-- ID, progress, from 0 to 1, and the tooltip's two numbers. Every other player has unmet, true, and
-- no ID. The keys that the tabs show for every player are in the details of each victory.
function SentientSystems_GetVictoryState(player)
	local victories = {}

	for _, victory in ipairs(VICTORIES) do
		if Game.IsVictoryEnabled(victory.type) and (not victory.expansion2 or SentientSystems_HasExpansion2()) then
			local ranking = GetRanking(player, victory)

			if #ranking > 0 then
				victories[victory.key] = ranking
			end
		end
	end

	return victories
end

-- The victories section of the state: how close each living major player is to each victory, in the
-- order the Overall tab of World Rankings ranks them, with the values its icon tooltips show.
-- SentientSystemsCore_State.lua loads this file. Format: docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetVictoryState(player) returns a table that encodes as '{"culture":[...],
-- "domination":[...],"religion":[...],"science":[{"player":0,"progress":0,"sciencePerTurn":2.7,
-- "techs":3},{"unmet":true}]}', on one line. The order and values follow
-- PopulateOverallInstance in WorldRankings.lua and g_victoryData in WorldRankings_Expansion2.lua.

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
-- section as { primary, secondary, values }.
local VICTORIES = {
	{
		key = "science",
		type = "VICTORY_TECHNOLOGY",
		values = function(other)
			return other:GetStats():GetNumTechsResearched(), other:GetTechs():GetScienceYield(), "techs", "sciencePerTurn"
		end,
	},
	{
		key = "culture",
		type = "VICTORY_CULTURE",
		values = function(other)
			return other:GetStats():GetTourism(), other:GetCulture():GetCultureYield(), "tourismPerTurn", "culturePerTurn"
		end,
	},
	{
		key = "domination",
		type = "VICTORY_CONQUEST",
		values = function(other)
			local strength = other:GetStats():GetMilitaryStrengthWithoutTreasury()

			return strength, strength, "military", nil
		end,
	},
	{
		key = "religion",
		type = "VICTORY_RELIGIOUS",
		values = function(other)
			return other:GetStats():GetNumCitiesFollowingReligion(), other:GetReligion():GetFaithYield(), "cities", "faithPerTurn"
		end,
	},
	{
		key = "diplomatic",
		type = "VICTORY_DIPLOMATIC",
		expansion2 = true,
		values = function(other)
			local points = other:GetStats():GetDiplomaticVictoryPoints()

			return points, points, "points", nil
		end,
	},
}

-- Returns the entry of a player in a victory's ranking, and what it sorts by. A player that the
-- player has not met has only unmet, true, as the tab shows only their place.
local function GetRanked(player, other, victory)
	local id = other:GetID()
	local first, second, firstKey, secondKey = victory.values(other)
	local ranked = {
		id = id,
		progress = Game.GetVictoryProgressForTeam(victory.type, other:GetTeam()),
		first = first,
		second = second,
		score = other:GetScore(),
		entry = { unmet = true },
	}

	if id == player:GetID() or player:GetDiplomacy():HasMet(id) then
		ranked.entry = { player = id, progress = RoundProgress(ranked.progress), [firstKey] = RoundNearest(first) }

		if secondKey ~= nil then
			ranked.entry[secondKey] = RoundNearest(second)
		end

		if victory.expansion2 then
			ranked.entry.required = GlobalParameters.DIPLOMATIC_VICTORY_POINTS_REQUIRED
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
-- ID, progress, from 0 to 1, and the tooltip's two numbers: techs and sciencePerTurn, tourismPerTurn and
-- culturePerTurn, military, cities and faithPerTurn, and points, with required. Every other player
-- has unmet, true, and no ID.
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

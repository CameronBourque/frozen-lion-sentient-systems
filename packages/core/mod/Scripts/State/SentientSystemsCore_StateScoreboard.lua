-- The scoreboard section: each major player's score and the leader panel's
-- numbers. Follows ViewScore in WorldRankings.lua and UpdateStatValues in
-- DiplomacyRibbon.lua. Shape: bridge/src/state/scoreboard.ts.

-- Returns the scoring categories that add to a score, each with its type, name,
-- and the player's points. The tab's details list only the categories with a
-- multiplier.
local function GetCategories(other)
	local categories = {}

	for row in GameInfo.ScoringCategories() do
		if row.Multiplier > 0 then
			categories[#categories + 1] = {
				type = row.CategoryType,
				name = Locale.Lookup(row.Name),
				score = other:GetCategoryScore(row.Index),
			}
		end
	end

	return categories
end

-- Adds the leader panel's numbers for a player to an entry. Gold is rounded
-- down and the rest to the nearest whole number. The panel adds favor only with
-- Gathering Storm, when the diplomatic victory is on.
local function AddLeaderPanel(entry, other)
	entry.military = SentientSystems_Round(other:GetStats():GetMilitaryStrengthWithoutTreasury())
	entry.science = SentientSystems_Round(other:GetTechs():GetScienceYield())
	entry.culture = SentientSystems_Round(other:GetCulture():GetCultureYield())
	entry.gold = math.floor(other:GetTreasury():GetGoldBalance())
	entry.faith = SentientSystems_Round(other:GetReligion():GetFaithBalance())

	if other.GetFavorPerTurn ~= nil and Game.IsVictoryEnabled("VICTORY_DIPLOMATIC") then
		entry.favor = SentientSystems_Round(other:GetFavor())
	end
end

-- Returns a list with one entry for each living major player, highest score
-- first and, for equal scores, in ID order. The tab shows the score and
-- categories for a player that has not been met too, so only the leader panel's
-- numbers and the ID are left out for one.
function SentientSystems_GetScoreboardState(player)
	local ranked = {}
	local diplomacy = player:GetDiplomacy()

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local id = other:GetID()
		local entry = { score = other:GetScore(), categories = GetCategories(other) }

		if id == player:GetID() or diplomacy:HasMet(id) then
			entry.player = id
			AddLeaderPanel(entry, other)
		end

		ranked[#ranked + 1] = { id = id, entry = entry }
	end

	table.sort(ranked, function(a, b)
		if a.entry.score ~= b.entry.score then
			return a.entry.score > b.entry.score
		end

		return a.id < b.id
	end)

	local scoreboard = {}

	for i, item in ipairs(ranked) do
		scoreboard[i] = item.entry
	end

	return scoreboard
end

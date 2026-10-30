-- The scoreboard section of the state: each living major player's score, as the Score tab of World
-- Rankings shows it, and the leader panel's numbers for the player and each player they have met.
-- SentientSystemsCore_State.lua loads this file. Format: docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetScoreboardState(player) returns a list that encodes as '[{"categories":[{"name":
-- "Civics","score":3,"type":"CATEGORY_CIVICS"}],"culture":4,"faith":591,"gold":107,
-- "military":30,"player":0,"science":4,"score":48},{"categories":[...],"score":25}]', on one line. The
-- numbers follow ViewScore in WorldRankings.lua and UpdateStatValues in DiplomacyRibbon.lua and
-- DiplomacyRibbon_Expansion2.lua.

-- Rounds to the nearest whole number, as the game's Round does.
local function Round(number)
	return math.floor(number + 0.5)
end

-- Returns the scoring categories that add to a score, each with its type, name, and the player's
-- points. The tab's details list only the categories with a multiplier.
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

-- Adds the leader panel's numbers for a player to an entry. Gold is rounded down and the rest to the
-- nearest whole number. The panel adds favor only with Gathering Storm, when the diplomatic victory
-- is on.
local function AddLeaderPanel(entry, other)
	entry.military = Round(other:GetStats():GetMilitaryStrengthWithoutTreasury())
	entry.science = Round(other:GetTechs():GetScienceYield())
	entry.culture = Round(other:GetCulture():GetCultureYield())
	entry.gold = math.floor(other:GetTreasury():GetGoldBalance())
	entry.faith = Round(other:GetReligion():GetFaithBalance())

	if other.GetFavorPerTurn ~= nil and Game.IsVictoryEnabled("VICTORY_DIPLOMATIC") then
		entry.favor = Round(other:GetFavor())
	end
end

-- Returns a list with one entry for each living major player, highest score first and, for equal
-- scores, in ID order. An entry has score and categories, which the tab shows for a player that has
-- not been met too. The player and each player they have met also have player, their ID, and the
-- leader panel's military, science, culture, gold, faith, and favor. An unmet player's ID is left
-- out, as the tab hides who they are, so the entry's place in the list is all that names them.
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

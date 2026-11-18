-- Helpers that many of the Lua tests share.

local Helpers = {}

-- Returns a shallow copy of the table, with the changes on top.
function Helpers.With(original, changes)
	local copy = {}

	for key, value in pairs(original) do
		copy[key] = value
	end

	for key, value in pairs(changes) do
		copy[key] = value
	end

	return copy
end

-- Returns the JSON of an action that failed for the reason.
function Helpers.Failed(reason)
	return "{\"ok\":false,\"reason\":\"" .. reason .. "\"}"
end

-- Returns the entry of a player in a list of entries, or the unmet one for nil.
function Helpers.Entry(json, id)
	for entry in json:gmatch("%b{}") do
		if id == nil and entry:find("\"unmet\":true", 1, true) then
			return entry
		elseif id ~= nil and entry:find("\"player\":" .. id .. ",", 1, true) then
			return entry
		end
	end
end

-- The text of the Civilopedia world below.
Helpers.CIVILOPEDIA_TEXT = {
	LOC_CONCEPTS = "Concepts",
	LOC_UNITS = "Units",
	LOC_MOVEMENT_1_NAME = "Movement Points",
	LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_1_CHAPTER_CONTENT_PARA_1 = "All units have [ICON_Movement] Movement points. They spend them to move.",
	LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_1_CHAPTER_CONTENT_PARA_2 = "Terrain sets the cost.",
	LOC_MOVEMENT_4_NAME = "Naval Movement",
	LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_4_CHAPTER_CONTENT_BODY = "Ships move on water",
	LOC_UNIT_SETTLER_NAME = "Settler",
	LOC_UNIT_SETTLER_DESCRIPTION = "May create new cities.",
	LOC_PEDIA_UNITS_PAGE_UNIT_SETTLER_CHAPTER_HISTORY_PARA_1 = "Settlers settled.",
	LOC_UNIT_SKIRMISHER_NAME = "Skirmisher",
	LOC_UNIT_SKIRMISHER_DESCRIPTION = "Recon unit that guards settler escorts on the move.",
}

-- Returns a Civilopedia with two Concepts pages, two units from a query, and
-- a leader from a query whose section the Civilopedia doesn't have, with the
-- changes on top.
function Helpers.Civilopedia(changes)
	return Helpers.With({
		sections = {
			{ SectionId = "CONCEPTS", Name = "LOC_CONCEPTS", SortIndex = 0 },
			{ SectionId = "UNITS", Name = "LOC_UNITS", SortIndex = 1 },
		},
		pages = {
			{ SectionId = "CONCEPTS", PageId = "MOVEMENT_1", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_1_NAME" },
			{ SectionId = "CONCEPTS", PageId = "MOVEMENT_4", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_4_NAME" },
		},
		queries = {
			{
				SectionId = "UNITS",
				SQL = "SELECT UnitType AS PageId FROM Units",
				PageIdColumn = "PageId",
				NameColumn = "Name",
				PageLayoutIdColumn = "PageLayoutId",
				rows = {
					{ PageId = "UNIT_SETTLER", Name = "LOC_UNIT_SETTLER_NAME", PageLayoutId = "Unit" },
					{ PageId = "UNIT_SKIRMISHER", Name = "LOC_UNIT_SKIRMISHER_NAME", PageLayoutId = "Unit" },
				},
			},
			{
				SectionId = "LEADERS",
				SQL = "SELECT LeaderType AS PageId FROM Leaders",
				PageIdColumn = "PageId",
				NameColumn = "Name",
				PageLayoutIdColumn = "PageLayoutId",
				rows = { { PageId = "LEADER_GORGO", Name = "LOC_LEADER_GORGO_NAME", PageLayoutId = "Leader" } },
			},
		},
		layoutChapters = {
			{ PageLayoutId = "Simple", ChapterId = "CONTENT", SortIndex = 10 },
			{ PageLayoutId = "Unit", ChapterId = "HISTORY", SortIndex = 10 },
		},
		tables = {
			Units = {
				UNIT_SETTLER = { Description = "LOC_UNIT_SETTLER_DESCRIPTION", Cost = 80 },
				UNIT_SKIRMISHER = { Description = "LOC_UNIT_SKIRMISHER_DESCRIPTION" },
			},
		},
	}, changes or {})
end

return Helpers

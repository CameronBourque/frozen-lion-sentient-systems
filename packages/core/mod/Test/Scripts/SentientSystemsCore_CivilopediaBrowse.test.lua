local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

-- Concepts pages in two groups and none, out of order, with the group text.
local CONCEPTS = {
	pages = {
		{ SectionId = "CONCEPTS", PageId = "COMBAT_2", PageLayoutId = "Simple", Name = "LOC_FLANKING", PageGroupId = "COMBAT", SortIndex = 2 },
		{ SectionId = "CONCEPTS", PageId = "MOVEMENT_4", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_4_NAME", PageGroupId = "MOVEMENT" },
		{ SectionId = "CONCEPTS", PageId = "COMBAT_1", PageLayoutId = "Simple", Name = "LOC_ATTACKS", PageGroupId = "COMBAT", SortIndex = 2 },
		{ SectionId = "CONCEPTS", PageId = "COMBAT_3", PageLayoutId = "Simple", Name = "LOC_ZOC", PageGroupId = "COMBAT", SortIndex = 1 },
		{ SectionId = "CONCEPTS", PageId = "INTRO", PageLayoutId = "Simple", Name = "LOC_INTRO", SortIndex = 0 },
		{ SectionId = "CONCEPTS", PageId = "MOVEMENT_1", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_1_NAME", PageGroupId = "MOVEMENT" },
	},
	groups = {
		{ SectionId = "CONCEPTS", PageGroupId = "MOVEMENT", Name = "LOC_GROUP_MOVEMENT", SortIndex = 1 },
		{ SectionId = "CONCEPTS", PageGroupId = "COMBAT", Name = "LOC_GROUP_COMBAT", SortIndex = 1 },
	},
}

local CONCEPTS_TEXT = {
	LOC_FLANKING = "Flanking",
	LOC_ATTACKS = "Attacks",
	LOC_ZOC = "Zone of Control",
	LOC_INTRO = "Basic Concepts",
	LOC_GROUP_MOVEMENT = "Movement",
	LOC_GROUP_COMBAT = "Combat",
}

-- Returns an environment with the browse script loaded into a fake game with
-- the Civilopedia's changes and the extra text.
local function Load(changes, text)
	local env = Game.new()

	FakeGame.Install(env, {
		civilopedia = Helpers.Civilopedia(changes),
		text = Helpers.With(Helpers.With(Helpers.CIVILOPEDIA_TEXT, CONCEPTS_TEXT), text or {}),
	})
	Game.run(env, "Scripts/SentientSystemsCore_CivilopediaBrowse.lua")

	return env
end

describe("SentientSystems_LookupSections", function()
	it("lists the sections by their sort index, with their titles and page counts", function()
		local env = Load({
			sections = {
				{ SectionId = "UNITS", Name = "LOC_UNITS", SortIndex = 1 },
				{ SectionId = "EMPTY", Name = "LOC_EMPTY" },
				{ SectionId = "CONCEPTS", Name = "LOC_CONCEPTS", SortIndex = 0 },
			},
		}, { LOC_EMPTY = "Empty" })

		assert.equal(
			"{\"sections\":[{\"pageCount\":0,\"sectionID\":\"EMPTY\",\"title\":\"Empty\"},"
				.. "{\"pageCount\":2,\"sectionID\":\"CONCEPTS\",\"title\":\"Concepts\"},"
				.. "{\"pageCount\":2,\"sectionID\":\"UNITS\",\"title\":\"Units\"}]}",
			env.SentientSystems_LookupSections()
		)
	end)
end)

describe("SentientSystems_LookupSection", function()
	it("lists a section's pages in its groups, as the game orders them, with no group first", function()
		assert.equal(
			"{\"groups\":[{\"pages\":[{\"pageID\":\"INTRO\",\"title\":\"Basic Concepts\"}]},"
				.. "{\"pages\":[{\"pageID\":\"COMBAT_3\",\"title\":\"Zone of Control\"},{\"pageID\":\"COMBAT_1\",\"title\":\"Attacks\"},{\"pageID\":\"COMBAT_2\",\"title\":\"Flanking\"}],\"title\":\"Combat\"},"
				.. "{\"pages\":[{\"pageID\":\"MOVEMENT_1\",\"title\":\"Movement Points\"},{\"pageID\":\"MOVEMENT_4\",\"title\":\"Naval Movement\"}],\"title\":\"Movement\"}],"
				.. "\"sectionID\":\"CONCEPTS\",\"title\":\"Concepts\"}",
			Load(CONCEPTS).SentientSystems_LookupSection("concepts")
		)
	end)

	it("orders groups by sort index before title, then by ID, with no sort index first", function()
		local env = Load(Helpers.With(CONCEPTS, {
			groups = {
				{ SectionId = "CONCEPTS", PageGroupId = "MOVEMENT", Name = "LOC_GROUP_MOVEMENT" },
				{ SectionId = "CONCEPTS", PageGroupId = "COMBAT", Name = "LOC_GROUP_COMBAT", SortIndex = 1 },
			},
		}))
		local json = env.SentientSystems_LookupSection("CONCEPTS")

		assert.truthy(json:find("\"title\":\"Movement\"},{\"pages\":[{\"pageID\":\"COMBAT_3\"", 1, true))

		env = Load(Helpers.With(CONCEPTS, {
			groups = {
				{ SectionId = "CONCEPTS", PageGroupId = "MOVEMENT", Name = "LOC_SAME", SortIndex = 1 },
				{ SectionId = "CONCEPTS", PageGroupId = "COMBAT", Name = "LOC_SAME", SortIndex = 1 },
			},
		}), { LOC_SAME = "Rules" })
		json = env.SentientSystems_LookupSection("CONCEPTS")

		assert.truthy(json:find("{\"pageID\":\"COMBAT_2\",\"title\":\"Flanking\"}],\"title\":\"Rules\"},{\"pages\":[{\"pageID\":\"MOVEMENT_1\"", 1, true))
	end)

	it("takes groups from the group queries, titles them from their TAB_NAME key, and leaves out a hidden group's pages", function()
		local env = Load(Helpers.With(CONCEPTS, {
			groups = {},
			groupQueries = {
				{
					SectionId = "CONCEPTS",
					SQL = "SELECT Id FROM Groups",
					PageGroupIdColumn = "Id",
					NameColumn = "Name",
					SortIndexColumn = "Sort",
					rows = { { Id = "COMBAT", Name = "LOC_GROUP_COMBAT", Sort = 2 }, { Id = "MOVEMENT", Name = "LOC_GROUP_MOVEMENT" } },
				},
				{ SectionId = "CONCEPTS", SQL = "SELECT Id FROM Others", NameColumn = "Name", SortIndex = 5, rows = { { Name = "LOC_NONE" } } },
			},
			groupExcludes = { { SectionId = "CONCEPTS", PageGroupId = "MOVEMENT" } },
		}), { LOC_PEDIA_CONCEPTS_PAGE_COMBAT_TAB_NAME = "Fighting" })
		local json = env.SentientSystems_LookupSection("CONCEPTS")

		assert.truthy(json:find("\"title\":\"Fighting\"}],\"sectionID\"", 1, true))
		assert.is_nil(json:find("MOVEMENT", 1, true))
	end)

	it("gives an error that lists the sections for a section ID that no section has", function()
		assert.equal(
			"{\"error\":\"No section has the ID LEADERS. Give one of: CONCEPTS, UNITS.\"}",
			Load().SentientSystems_LookupSection("LEADERS")
		)
		assert.equal(
			"{\"error\":\"No section has the ID nil. Give one of: CONCEPTS, UNITS.\"}",
			Load().SentientSystems_LookupSection(nil)
		)
	end)
end)

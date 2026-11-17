local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

-- Returns an environment with the Civilopedia script loaded into a fake game
-- with the Civilopedia's changes and the extra text.
local function Load(changes, text)
	local env = Game.new()

	FakeGame.Install(env, {
		civilopedia = Helpers.Civilopedia(changes),
		text = Helpers.With(Helpers.CIVILOPEDIA_TEXT, text or {}),
	})
	Game.run(env, "Scripts/SentientSystemsCore_Civilopedia.lua")

	return env
end

-- Returns the section and page IDs of the pages, in order.
local function PageKeys(env)
	local keys = {}

	for _, page in ipairs(env.SentientSystems_GetCivilopedia().pages) do
		keys[#keys + 1] = page.sectionID .. "|" .. page.pageID
	end

	return keys
end

describe("SentientSystems_GetCivilopedia", function()
	it("lists the sections with their titles", function()
		assert.same({
			{ sectionID = "CONCEPTS", title = "Concepts", sortIndex = 0 },
			{ sectionID = "UNITS", title = "Units", sortIndex = 1 },
		}, Load().SentientSystems_GetCivilopedia().sections)
	end)

	it("lists the fixed pages, then each query's pages, without a section it doesn't have", function()
		assert.same({ "CONCEPTS|MOVEMENT_1", "CONCEPTS|MOVEMENT_4", "UNITS|UNIT_SETTLER", "UNITS|UNIT_SKIRMISHER" }, PageKeys(Load()))
	end)

	it("leaves out the excluded sections and pages", function()
		local env = Load({
			sectionExcludes = { { SectionId = "UNITS" } },
			pageExcludes = { { SectionId = "CONCEPTS", PageId = "MOVEMENT_4" } },
		})

		assert.same({ "CONCEPTS|MOVEMENT_1" }, PageKeys(env))
		assert.equal(1, #env.SentientSystems_GetCivilopedia().sections)
	end)

	it("gives a unit its Description as its text, without the history chapter", function()
		local settler = Load().SentientSystems_GetCivilopediaPage("UNITS", "UNIT_SETTLER")

		assert.equal("Settler", settler.title)
		assert.equal("May create new cities.", settler.text)
		assert.equal(80, settler.row.Cost)
		assert.equal("Units", settler.tableName)
	end)

	it("gives a Concepts page its paragraphs in order, with the icons named, or its one body", function()
		local env = Load()

		assert.equal("All units have Movement points. They spend them to move.\nTerrain sets the cost.", env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_1").text)
		assert.equal("Ships move on water", env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_4").text)
	end)

	it("takes a chapter's paragraphs from CivilopediaPageChapterParagraphs first, by their sort order", function()
		local page = Load({
			paragraphs = {
				{ SectionId = "CONCEPTS", PageId = "MOVEMENT_4", ChapterId = "CONTENT", Paragraph = "LOC_SECOND", SortIndex = 2 },
				{ SectionId = "CONCEPTS", PageId = "MOVEMENT_4", ChapterId = "CONTENT", Paragraph = "LOC_FIRST", SortIndex = 1 },
			},
		}, { LOC_FIRST = "First.", LOC_SECOND = "Second." }).SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_4")

		assert.equal("First.\nSecond.", page.text)
	end)

	it("gives no text to a page with none", function()
		local env = Load({ tables = {} })

		assert.is_nil(env.SentientSystems_GetCivilopediaPage("UNITS", "UNIT_SETTLER").text)
	end)

	it("takes a title from the page's title key before its name, and its prefix's keys first", function()
		local env = Load({
			pages = {
				{ SectionId = "CONCEPTS", PageId = "MOVEMENT_1", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_1_NAME" },
				{ SectionId = "CONCEPTS", PageId = "MOVEMENT_4", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_4_NAME", TextKeyPrefix = "LOC_NAVY" },
				{ SectionId = "CONCEPTS", PageId = "COMBAT_1", PageLayoutId = "Simple" },
			},
		}, {
			LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_1_TITLE = "Moving Units",
			LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_4_TITLE = "Not This",
			LOC_NAVY_MOVEMENT_4_TITLE = "Ships",
			LOC_NAVY_MOVEMENT_4_CHAPTER_CONTENT_BODY = "Ships sail.",
		})

		assert.equal("Moving Units", env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_1").title)
		assert.equal("Ships", env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_4").title)
		assert.equal("Ships sail.", env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_4").text)
		assert.equal("COMBAT_1", env.SentientSystems_GetCivilopediaPage("CONCEPTS", "COMBAT_1").title)
	end)

	it("gives a page its search terms from the table and the term queries", function()
		local env = Load({
			searchTerms = { { SectionId = "CONCEPTS", PageId = "MOVEMENT_1", Term = "LOC_TERM_MOVES" } },
			searchTermQueries = {
				{
					SQL = "SELECT Term FROM Terms",
					SectionIdColumn = "SectionId",
					PageIdColumn = "PageId",
					SearchTermColumn = "Term",
					rows = { { SectionId = "CONCEPTS", PageId = "MOVEMENT_1", Term = "LOC_TERM_STEPS" }, { SectionId = "CONCEPTS" } },
				},
			},
		}, { LOC_TERM_MOVES = "Moves", LOC_TERM_STEPS = "Steps" })

		assert.same({ "Moves", "Steps" }, env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_1").terms)
		assert.same({}, env.SentientSystems_GetCivilopediaPage("CONCEPTS", "MOVEMENT_4").terms)
	end)

	it("builds the pages once", function()
		local env = Load()

		assert.equal(env.SentientSystems_GetCivilopedia(), env.SentientSystems_GetCivilopedia())
	end)

	it("finds no page for an ID the section doesn't have", function()
		assert.is_nil(Load().SentientSystems_GetCivilopediaPage("UNITS", "MOVEMENT_1"))
	end)
end)

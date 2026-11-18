local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

-- A unit layout that draws as the game's does, with each kind of drawing
-- call, under the template UnitTemplate.
local function UnitLayouts(env)
	return {
		UnitTemplate = function(page)
			local unit = env.GameInfo.Units[page.PageId]

			env.SetPageHeader(page.Title)
			env.SetPageSubHeader("LOC_SUBTITLE")
			env.AddPortrait("ICON_" .. page.PageId)
			env.AddQuote("LOC_QUOTE")
			env.AddRightColumnStatBox("LOC_TRAITS", function(s)
				s:AddSeparator()
				s:AddHeader("LOC_COSTS")
				s:AddLabel("LOC_COST")
				s:AddSmallLabel("LOC_SMALL")
				s:AddIconLabel({ "ICON_TECH", "LOC_TECH", "TECH_X" }, "LOC_TECH")
				s:AddIconLabel({ "ICON_TECH", "LOC_ICON_NAME", "TECH_X" }, nil)
				s:AddIconNumberLabel({ "ICON_MOVES" }, 2, "LOC_MOVES")
				s:AddIconList({ "ICON_A", "LOC_A" }, { "ICON_B", "LOC_B" })
			end)
			env.AddRightColumnStatBox("LOC_EMPTY_BOX", function(s)
				s:AddSeparator()
			end)
			env.AddHeader("LOC_UNIQUE")
			env.AddHeaderBody("LOC_RETIRE", "LOC_RETIRE_BODY")
			env.AddIconHeaderBody("ICON_X", "LOC_PASSIVE", { "LOC_PASSIVE_BODY" })
			env.AddParagraph("[ICON_Bullet] [COLOR_Red]Red[ENDCOLOR]")
			env.AddChapter("LOC_DESCRIPTION", unit.Description)

			for _, chapter in ipairs(env.GetPageChapters(page.PageLayoutId)) do
				env.AddChapter(env.GetChapterHeader(page.SectionId, page.PageId, chapter.ChapterId), env.GetChapterBody(page.SectionId, page.PageId, chapter.ChapterId))
			end
		end,
	}
end

-- The text the unit layout draws.
local UNIT_TEXT = {
	LOC_SUBTITLE = "Ancient Era",
	LOC_TRAITS = "Traits",
	LOC_COSTS = "Costs",
	LOC_COST = "Base Cost: 80 [ICON_Production]  Production",
	LOC_SMALL = "Small",
	LOC_TECH = "Pottery",
	LOC_ICON_NAME = "Writing",
	LOC_MOVES = "Movement Points",
	LOC_A = "Shrine",
	LOC_B = "Holy Site",
	LOC_EMPTY_BOX = "Empty",
	LOC_UNIQUE = "Unique Ability",
	LOC_RETIRE = "Retire",
	LOC_RETIRE_BODY = "Grants a promotion.",
	LOC_PASSIVE = "Passive",
	LOC_PASSIVE_BODY = "Moves faster.",
	LOC_DESCRIPTION = "Description",
}

-- Returns an environment with the page script loaded into a fake game with
-- the unit layout, the Civilopedia's changes, and the extra text.
local function Load(changes, text)
	local env = Game.new()

	FakeGame.Install(env, {
		civilopedia = Helpers.Civilopedia(Helpers.With({
			layouts = { { PageLayoutId = "Unit", ScriptTemplate = "UnitTemplate" } },
			pageLayouts = UnitLayouts,
		}, changes or {})),
		text = Helpers.With(Helpers.With(Helpers.CIVILOPEDIA_TEXT, UNIT_TEXT), text or {}),
	})
	Game.run(env, "Scripts/SentientSystemsCore_CivilopediaPage.lua")

	return env
end

-- Returns the text of a page's JSON, with its escapes undone.
local function PageText(json)
	return json:match("\"text\":\"(.-)\",\"title\"") and json:match("\"text\":\"(.-)\",\"title\""):gsub("\\n", "\n")
end

describe("SentientSystems_LookupPage", function()
	it("gives the page as its layout draws it, with each box, heading, and paragraph as lines", function()
		assert.equal(table.concat({
			"Ancient Era",
			"## Traits",
			"### Costs",
			"- Base Cost: 80 Production",
			"- Small",
			"- Pottery",
			"- Writing",
			"- 2 Movement Points",
			"- Shrine",
			"- Holy Site",
			"## Unique Ability",
			"### Retire",
			"Grants a promotion.",
			"### Passive",
			"Moves faster.",
			"- Red",
			"## Description",
			"May create new cities.",
		}, "\n"), PageText(Load().SentientSystems_LookupPage("UNIT_SETTLER")))
	end)

	it("gives the page's section, page ID, and title", function()
		local json = Load().SentientSystems_LookupPage("unit_settler")

		assert.truthy(json:find("{\"pageID\":\"UNIT_SETTLER\",\"sectionID\":\"UNITS\",\"text\":", 1, true))
		assert.truthy(json:find(",\"title\":\"Settler\"}", 1, true))
	end)

	it("gives the layout the chapters that aren't history, with their headers", function()
		local text = PageText(Load({
			layoutChapters = {
				{ PageLayoutId = "Unit", ChapterId = "HISTORY", SortIndex = 10 },
				{ PageLayoutId = "Unit", ChapterId = "RULES", SortIndex = 5 },
			},
			chapterHeaders = { { SectionId = "UNITS", PageId = "UNIT_SETTLER", ChapterId = "RULES", Header = "LOC_RULES" } },
		}, {
			LOC_RULES = "Rules",
			LOC_PEDIA_UNITS_PAGE_UNIT_SETTLER_CHAPTER_RULES_PARA_1 = "Settle on a river.",
		}).SentientSystems_LookupPage("UNIT_SETTLER"))

		assert.truthy(text:find("\n## Rules\nSettle on a river.$"))
		assert.is_nil(text:find("Settlers settled.", 1, true))
	end)

	it("takes a chapter's header from the generic chapter keys, and gives no header or body for a chapter the page doesn't have", function()
		local env = Load({ layoutChapters = { { PageLayoutId = "Unit", ChapterId = "RULES", SortIndex = 5 } } }, {
			LOC_PEDIA_UNITS_PAGE_CHAPTER_RULES_TITLE = "How to Use",
			LOC_PEDIA_PAGE_UNIT_SETTLER_CHAPTER_RULES_BODY = "Found a city.",
		})

		assert.truthy(PageText(env.SentientSystems_LookupPage("UNIT_SETTLER")):find("\n## How to Use\nFound a city.$"))
		assert.is_nil(env.GetChapterHeader("UNITS", "UNIT_SETTLER", "OTHER"))
		assert.is_nil(env.GetChapterBody("UNITS", "UNIT_NONE", "RULES"))
	end)

	it("draws the full-width and left-column calls as the plain ones, and skips an empty caption", function()
		local env = Load({
			pageLayouts = function(env)
				return {
					Unit = function()
						env.AddLeftColumnParagraph("")
						env.AddFullWidthParagraph(nil)
						env.AddFullWidthHeader("LOC_A")
						env.AddFullWidthParagraphs({ "LOC_B" })
						env.AddLeftColumnIconHeaderBody("ICON_X", "LOC_PASSIVE", "LOC_PASSIVE_BODY")
						env.ShowFrontPageHeader()
						env.AddTallImage("IMAGE")
					end,
				}
			end,
			layouts = {},
		})

		assert.equal("## Shrine\nHoly Site\n### Passive\nMoves faster.", PageText(env.SentientSystems_LookupPage("UNIT_SETTLER")))
	end)

	it("gives a page with no layout its text and its row's stats, without the columns that say nothing", function()
		local env = Load({
			pageLayouts = function()
				return {}
			end,
			tables = {
				Units = {
					UNIT_SETTLER = { Description = "LOC_UNIT_SETTLER_DESCRIPTION", Cost = 80, Domain = "DOMAIN_LAND", Combat = 0, CanCapture = false, FoundCity = true, Hash = 5, Extra = {} },
				},
			},
		})

		assert.equal("May create new cities.\n## Stats\n- Cost: 80\n- Domain: DOMAIN_LAND\n- FoundCity: true", PageText(env.SentientSystems_LookupPage("UNIT_SETTLER")))
		assert.same({}, env.printed)
	end)

	it("keeps what a failing layout drew, adds the page's text and the row's stats, and prints an ERROR line", function()
		local env = Load({
			pageLayouts = function(env)
				return {
					UnitTemplate = function()
						env.AddHeader("LOC_UNIQUE")
						env.AddParagraph("LOC_RETIRE_BODY")
						error("no chapters")
					end,
				}
			end,
		})

		assert.equal("## Unique Ability\nGrants a promotion.\nMay create new cities.\n## Stats\n- Cost: 80", PageText(env.SentientSystems_LookupPage("UNIT_SETTLER")))
		assert.equal(1, #env.printed)
		assert.truthy(env.printed[1]:find("^%[SENTIENTSYSTEMS%] ERROR CivilopediaPage_Unit .*no chapters"))
	end)

	it("doesn't add the page's text again when a failing layout drew it, double spaces and all", function()
		local env = Load({
			pageLayouts = function(env)
				return {
					UnitTemplate = function(page)
						env.AddChapter("LOC_DESCRIPTION", env.GameInfo.Units[page.PageId].Description)
						error("no chapters")
					end,
				}
			end,
		}, { LOC_UNIT_SETTLER_DESCRIPTION = "May create  new cities.\nCosts a citizen." })

		assert.equal("## Description\nMay create new cities.\nCosts a citizen.\n## Stats\n- Cost: 80", PageText(env.SentientSystems_LookupPage("UNIT_SETTLER")))
	end)

	it("gives no text to a page with no layouts loaded, no text, and no row", function()
		assert.equal(
			"{\"pageID\":\"MOVEMENT_4\",\"sectionID\":\"CONCEPTS\",\"title\":\"Naval Movement\"}",
			Load({ pageLayouts = false, layoutChapters = {} }).SentientSystems_LookupPage("MOVEMENT_4")
		)
	end)

	it("finds a page in the section given, and asks for a section when more than one has the ID", function()
		local env = Load({
			pages = {
				{ SectionId = "CONCEPTS", PageId = "INTRO", PageLayoutId = "Simple", Name = "LOC_A" },
				{ SectionId = "UNITS", PageId = "INTRO", PageLayoutId = "Simple", Name = "LOC_B" },
			},
			queries = {},
			layoutChapters = {},
		})

		assert.equal("{\"error\":\"INTRO is in more than one section. Give one of: CONCEPTS, UNITS.\"}", env.SentientSystems_LookupPage("INTRO"))
		assert.equal("{\"pageID\":\"INTRO\",\"sectionID\":\"UNITS\",\"title\":\"Holy Site\"}", env.SentientSystems_LookupPage("INTRO", "UNITS"))
	end)

	it("gives an error for a page ID that no page has", function()
		local env = Load()

		assert.equal("{\"error\":\"No page has the ID UNIT_NONE. Search with lookup first.\"}", env.SentientSystems_LookupPage("UNIT_NONE"))
		assert.equal("{\"error\":\"No page has the ID UNIT_SETTLER in CONCEPTS. Search with lookup first.\"}", env.SentientSystems_LookupPage("UNIT_SETTLER", "CONCEPTS"))
		assert.equal("{\"error\":\"No page has the ID nil. Search with lookup first.\"}", env.SentientSystems_LookupPage(nil))
	end)
end)

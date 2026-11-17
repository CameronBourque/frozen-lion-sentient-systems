local FakeGame = require("FakeGame")
local Game = require("Game")
local Helpers = require("Helpers")

-- Returns an environment with the search script loaded into a fake game with
-- the Civilopedia's changes and the extra text.
local function Load(changes, text)
	local env = Game.new()

	FakeGame.Install(env, {
		civilopedia = Helpers.Civilopedia(changes),
		text = Helpers.With(Helpers.CIVILOPEDIA_TEXT, text or {}),
	})
	Game.run(env, "Scripts/SentientSystemsCore_CivilopediaSearch.lua")

	return env
end

-- Returns the page IDs of a search's results, in order.
local function PageIDs(json)
	local ids = {}

	for id in json:gmatch("\"pageID\":\"([^\"]+)\"") do
		ids[#ids + 1] = id
	end

	return ids
end

describe("SentientSystems_Lookup", function()
	it("gives each result's section, page ID, title, and the first sentence of its text", function()
		assert.equal(
			"{\"results\":[{\"pageID\":\"MOVEMENT_1\",\"sectionID\":\"CONCEPTS\",\"snippet\":\"All units have Movement points.\",\"title\":\"Movement Points\"}]}",
			Load().SentientSystems_Lookup("Movement Points")
		)
	end)

	it("ranks exact page IDs, then titles that start with the query, titles that hold it, the game's search, and page IDs that hold it", function()
		local env = Load({
			pages = {
				{ SectionId = "CONCEPTS", PageId = "MOVEMENT_1", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_1_NAME" },
				{ SectionId = "CONCEPTS", PageId = "MOVEMENT_4", PageLayoutId = "Simple", Name = "LOC_MOVEMENT_4_NAME" },
				{ SectionId = "CONCEPTS", PageId = "SETTLER_TIPS", PageLayoutId = "Simple", Name = "LOC_TIPS" },
				{ SectionId = "CONCEPTS", PageId = "SETTLER", PageLayoutId = "Simple", Name = "LOC_FOUNDING" },
				{ SectionId = "CONCEPTS", PageId = "CITIES_1", PageLayoutId = "Simple", Name = "LOC_FIRST_SETTLER" },
			},
		}, { LOC_TIPS = "Founding Tips", LOC_FOUNDING = "Founding", LOC_FIRST_SETTLER = "Your First Settler" })

		assert.same({ "SETTLER", "UNIT_SETTLER", "CITIES_1", "UNIT_SKIRMISHER", "SETTLER_TIPS" }, PageIDs(env.SentientSystems_Lookup("settler")))
	end)

	it("matches a page ID in any case", function()
		assert.same({ "UNIT_SETTLER" }, PageIDs(Load().SentientSystems_Lookup(" unit_settler ")))
	end)

	it("gives the game's excerpt as the snippet of a match in the text", function()
		local json = Load().SentientSystems_Lookup("escorts")

		assert.truthy(json:find("\"snippet\":\"...Recon unit that guards settler escorts on the move....\"", 1, true))
	end)

	it("cuts a long first sentence, and gives a page with no text no snippet", function()
		local env = Load({ tables = {} }, { LOC_PEDIA_CONCEPTS_PAGE_MOVEMENT_4_CHAPTER_CONTENT_BODY = string.rep("a", 250) .. ". More." })

		assert.truthy(env.SentientSystems_Lookup("Naval"):find("\"snippet\":\"" .. string.rep("a", 200) .. "...\"", 1, true))
		assert.equal("{\"results\":[{\"pageID\":\"UNIT_SETTLER\",\"sectionID\":\"UNITS\",\"title\":\"Settler\"}]}", env.SentientSystems_Lookup("Settler"))
	end)

	it("gives at most 10 results, each once", function()
		local pages = {}

		for i = 1, 12 do
			pages[i] = { SectionId = "CONCEPTS", PageId = "MOVE_" .. i, PageLayoutId = "Simple", Name = "LOC_MOVE" }
		end

		local ids = PageIDs(Load({ pages = pages }, { LOC_MOVE = "Move" }).SentientSystems_Lookup("move"))

		assert.equal(10, #ids)
		assert.equal("MOVE_10", ids[10])
	end)

	it("matches nothing for an empty query", function()
		assert.equal("{\"results\":[]}", Load().SentientSystems_Lookup("  "))
		assert.equal("{\"results\":[]}", Load().SentientSystems_Lookup(nil))
	end)

	it("prints an ERROR line once when the game has no Search, and still matches page IDs and titles", function()
		local env = Load({ noSearch = true })

		assert.same({ "UNIT_SETTLER" }, PageIDs(env.SentientSystems_Lookup("Settler")))
		assert.same({}, PageIDs(env.SentientSystems_Lookup("escorts")))
		assert.same({ "[SENTIENTSYSTEMS] ERROR SentientSystems_Lookup the game has no Search, so the lookup matches page IDs and titles only" }, env.printed)
	end)
end)

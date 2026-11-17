-- Searches the Civilopedia's pages by page ID, title, and text, with the game's
-- own search and substring matches. See docs/findings/civilopedia.md#search.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Civilopedia")

-- The most results a search returns.
local MAX_RESULTS = 10

-- The longest first sentence a snippet keeps, in characters.
local MAX_SNIPPET = 200

-- Our own search context, apart from the Civilopedia screen's.
local SEARCH_CONTEXT = "SentientSystemsLookup"

-- Whether the search context holds the pages, or nil before the first search.
-- The game builds a new UI state for each load, so a load starts with nil.
local indexed = nil

-- Adds every page to the game's search context, with its text as the
-- description, so the search matches words in the text too. Returns false,
-- and prints an ERROR line, when the game has no Search.
local function IndexPages()
	if Search == nil then
		SentientSystems_Print("ERROR", "SentientSystems_Lookup", "the game has no Search, so the lookup matches page IDs and titles only")

		return false
	end

	Search.DestroyContext(SEARCH_CONTEXT)
	Search.CreateContext(SEARCH_CONTEXT, "", "", "...")

	for _, page in ipairs(SentientSystems_GetCivilopedia().pages) do
		Search.AddData(SEARCH_CONTEXT, page.sectionID .. "|" .. page.pageID, page.title, page.text or "", page.terms)
	end

	Search.Optimize(SEARCH_CONTEXT)

	return true
end

-- Returns the first sentence of the text, cut to MAX_SNIPPET characters, or
-- nil for no text.
local function GetFirstSentence(text)
	if text == nil then
		return nil
	end

	local sentence = text:match("^(.-[%.!?])%s") or text:match("^[^\n]*")

	if #sentence > MAX_SNIPPET then
		sentence = sentence:sub(1, MAX_SNIPPET) .. "..."
	end

	return sentence
end

-- Returns the pages that match the query in the game's search, in its order,
-- each with the excerpt it gives around the match.
local function SearchText(query)
	local found = {}

	for _, result in ipairs(Search.Search(SEARCH_CONTEXT, query) or {}) do
		local sectionID, pageID = result[1]:match("^([^|]+)|(.+)$")
		local page = SentientSystems_GetCivilopediaPage(sectionID, pageID)

		if page ~= nil then
			local excerpt = result[3]

			found[#found + 1] = { page = page, snippet = excerpt ~= "" and excerpt or nil }
		end
	end

	return found
end

-- Returns the pages whose page ID or title passes the test, in table order.
local function FindPages(test)
	local found = {}

	for _, page in ipairs(SentientSystems_GetCivilopedia().pages) do
		if test(page.pageID:lower(), page.title:lower()) then
			found[#found + 1] = { page = page }
		end
	end

	return found
end

-- Returns the matches for the query, best first: exact page IDs, titles that
-- start with the query, titles that hold it, the game's search, then page IDs
-- that hold it. A page can be in more than one list. Titles come before the
-- game's search, which ranks "+1 Movement" promotions above Naval Movement.
local function GetMatchLists(query)
	local lower = query:lower()

	return {
		FindPages(function(pageID)
			return pageID == lower
		end),
		FindPages(function(_, title)
			return title:sub(1, #lower) == lower
		end),
		FindPages(function(_, title)
			return title:find(lower, 1, true) ~= nil
		end),
		indexed and SearchText(query) or {},
		FindPages(function(pageID)
			return pageID:find(lower, 1, true) ~= nil
		end),
	}
end

-- Returns the Civilopedia pages that match the query as JSON, at most 10, best
-- first. Each has its section, page ID, title, and a snippet: the game's
-- excerpt around a match in the text, or the page's first sentence. An empty
-- query matches nothing. Shape: bridge/src/lookup.ts*.
function SentientSystems_Lookup(query)
	query = tostring(query or ""):match("^%s*(.-)%s*$")

	if indexed == nil and query ~= "" then
		indexed = IndexPages()
	end

	local results, seen = {}, {}

	for _, list in ipairs(query ~= "" and GetMatchLists(query) or {}) do
		for _, match in ipairs(list) do
			local page = match.page
			local key = page.sectionID .. "|" .. page.pageID

			if #results < MAX_RESULTS and not seen[key] then
				seen[key] = true
				results[#results + 1] = {
					sectionID = page.sectionID,
					pageID = page.pageID,
					title = page.title,
					snippet = match.snippet or GetFirstSentence(page.text),
				}
			end
		end
	end

	return SentientSystems_EncodeJson({ results = results })
end

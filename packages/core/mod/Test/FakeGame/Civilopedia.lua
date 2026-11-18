-- The Civilopedia. Fakes its GameInfo tables, DB.Query for its queries, the
-- rows its queries read, and the game's Search.

-- Returns whether the text holds the query, ignoring case.
local function Holds(text, query)
	return text ~= nil and text:lower():find(query:lower(), 1, true) ~= nil
end

-- A fake of the game's Search: a context matches an entry whose title,
-- description, or terms hold the query, in the order added, at most 10. A
-- description match gives the description, between dots, as its excerpt.
local function FakeSearch()
	local contexts = {}

	return {
		CreateContext = function(name)
			contexts[name] = {}

			return true
		end,
		DestroyContext = function(name)
			contexts[name] = nil
		end,
		AddData = function(name, key, title, description, terms)
			table.insert(contexts[name], { key = key, title = title, description = description, terms = terms })
		end,
		Optimize = function() end,
		Search = function(name, query)
			local results = {}

			for _, entry in ipairs(contexts[name]) do
				local excerpt = Holds(entry.description, query) and "..." .. entry.description .. "..." or ""
				local matched = Holds(entry.title, query) or excerpt ~= ""

				for _, term in ipairs(entry.terms) do
					matched = matched or Holds(term, query)
				end

				if matched and #results < 10 then
					results[#results + 1] = { entry.key, entry.title, excerpt, entry.title }
				end
			end

			return #results > 0 and results or nil
		end,
	}
end

-- world.civilopedia holds the rows of each table: sections, sectionExcludes,
-- pageExcludes, pages, layouts, layoutChapters, chapterHeaders, paragraphs,
-- and searchTerms. Its queries and searchTermQueries are rows of
-- CivilopediaPageQueries and CivilopediaPageSearchTermQueries, and each one's
-- rows are what DB.Query gives for its SQL. Its tables give rows by page ID
-- for the GameInfo table of each name. Its pageLayouts(env) returns the game's
-- page layout functions, by template, which call the drawing calls in env.
-- Set its noSearch to leave the game without Search.
return function(env, world, ctx)
	local data = world.civilopedia or {}

	env.PageLayouts = data.pageLayouts and data.pageLayouts(env)

	for name, field in pairs({
		CivilopediaSections = "sections",
		CivilopediaSectionExcludes = "sectionExcludes",
		CivilopediaPageExcludes = "pageExcludes",
		CivilopediaPages = "pages",
		CivilopediaPageQueries = "queries",
		CivilopediaPageLayoutChapters = "layoutChapters",
		CivilopediaPageChapterParagraphs = "paragraphs",
		CivilopediaPageChapterHeaders = "chapterHeaders",
		CivilopediaPageLayouts = "layouts",
		CivilopediaPageSearchTerms = "searchTerms",
		CivilopediaPageSearchTermQueries = "searchTermQueries",
	}) do
		env.GameInfo[name] = ctx.Callable(data[field] or {})
	end

	for name, rows in pairs(data.tables or {}) do
		local existing = env.GameInfo[name]

		if existing == nil then
			env.GameInfo[name] = rows
		else
			for pageID, row in pairs(rows) do
				rawset(existing, pageID, row)
			end
		end
	end

	env.DB = {
		Query = function(sql)
			for _, query in ipairs(data.queries or {}) do
				if query.SQL == sql then
					return query.rows
				end
			end

			for _, query in ipairs(data.searchTermQueries or {}) do
				if query.SQL == sql then
					return query.rows
				end
			end

			error("no fake rows for " .. sql)
		end,
	}

	if not data.noSearch then
		env.Search = FakeSearch()
	end
end

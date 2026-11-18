-- The Civilopedia's sections and pages, with each page's title, chapters, and
-- text, read once per load from the tables CivilopediaSupport.lua reads. See
-- docs/findings/civilopedia.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Text")

-- Chapters that hold history, not rules. The Leader layout's CAPSULE and
-- DETAILED chapters are history too.
local HISTORY_CHAPTERS = { HISTORY = true, CAPSULE = true, DETAILED = true }

-- The index, built on the first call. The game builds a new UI state for each
-- load, so a load starts with none.
local civilopedia = nil

-- Returns a section's and page's key, as CivilopediaSupport.lua writes it.
local function PageKey(sectionID, pageID)
	return sectionID .. "|" .. pageID
end

-- Returns the first of the text keys that has text, or nil.
local function FindTextKey(keys)
	for _, key in ipairs(keys) do
		if Locale.HasTextKey(key) then
			return key
		end
	end
end

-- Returns the text keys a page's text may have, with the suffix, in the order
-- FindPageTextKey in CivilopediaSupport.lua tries them.
local function GetPageKeys(page, suffix)
	local keys = {}

	if page.prefix ~= nil then
		keys[#keys + 1] = page.prefix .. "_" .. page.pageID .. suffix
		keys[#keys + 1] = page.prefix .. suffix
	end

	keys[#keys + 1] = "LOC_PEDIA_" .. page.sectionID .. "_PAGE_" .. page.pageID .. suffix
	keys[#keys + 1] = "LOC_PEDIA_PAGE_" .. page.pageID .. suffix

	return keys
end

-- Returns the first text key a chapter's text has with the tag, or nil, in the
-- order FindChapterTextKey in CivilopediaSupport.lua tries them.
local function FindChapterKey(page, chapterID, tag)
	local suffix = "_CHAPTER_" .. chapterID .. "_" .. tag
	local keys = {}

	if page.prefix ~= nil then
		keys[#keys + 1] = page.prefix .. "_" .. page.pageID .. suffix
		keys[#keys + 1] = page.prefix .. suffix
	end

	keys[#keys + 1] = "LOC_PEDIA_" .. page.sectionID .. "_PAGE_" .. page.pageID .. suffix
	keys[#keys + 1] = "LOC_PEDIA_" .. page.sectionID .. "_PAGE" .. suffix
	keys[#keys + 1] = "LOC_PEDIA_PAGE_" .. page.pageID .. suffix
	keys[#keys + 1] = "LOC_PEDIA_PAGE" .. suffix

	return FindTextKey(keys)
end

-- Returns the text keys of a chapter's paragraphs, as GetChapterBody does.
local function GetChapterKeys(page, chapterID, listed)
	if listed ~= nil and listed.paragraphs ~= nil then
		return listed.paragraphs
	end

	local body = FindChapterKey(page, chapterID, "BODY")

	if body ~= nil then
		return { body }
	end

	local keys = {}

	repeat
		local key = FindChapterKey(page, chapterID, "PARA_" .. #keys + 1)

		keys[#keys + 1] = key
	until key == nil

	return keys
end

-- Returns the chapters of a page's layout that aren't history, each with its
-- header's text key, or nil, and its paragraphs' text keys, as
-- GetChapterHeader and GetChapterBody give them.
local function GetRulesChapters(page, layoutChapters, overrides)
	local chapters = {}

	for _, chapterID in ipairs(layoutChapters[page.layout] or {}) do
		if not HISTORY_CHAPTERS[chapterID] then
			local override = overrides[PageKey(page.sectionID, page.pageID) .. "|" .. chapterID] or {}

			chapters[#chapters + 1] = {
				chapterID = chapterID,
				header = override.header or FindChapterKey(page, chapterID, "TITLE"),
				paragraphs = GetChapterKeys(page, chapterID, override),
			}
		end
	end

	return chapters
end

-- Returns a page's rules text: the Description of its row, then the paragraphs
-- of its chapters, or nil for none.
local function GetPageText(row, chapters)
	local parts = {}

	if row ~= nil and row.Description ~= nil then
		parts[#parts + 1] = SentientSystems_LookupText(row.Description)
	end

	for _, chapter in ipairs(chapters) do
		for _, key in ipairs(chapter.paragraphs) do
			parts[#parts + 1] = SentientSystems_LookupText(key)
		end
	end

	local text = table.concat(parts, "\n")

	return text ~= "" and text or nil
end

-- Returns the chapters of each layout, in order, by layout ID.
local function GetLayoutChapters()
	local rows = {}

	for row in GameInfo.CivilopediaPageLayoutChapters() do
		rows[#rows + 1] = row
	end

	table.sort(rows, function(a, b)
		return a.SortIndex < b.SortIndex
	end)

	local chapters = {}

	for _, row in ipairs(rows) do
		local list = chapters[row.PageLayoutId] or {}

		list[#list + 1] = row.ChapterId
		chapters[row.PageLayoutId] = list
	end

	return chapters
end

-- Returns the header text key and the paragraph text keys, in order, that
-- CivilopediaPageChapterHeaders and CivilopediaPageChapterParagraphs give a
-- chapter, by section, page, and chapter.
local function GetChapterOverrides()
	local overrides = {}

	local function GetOverride(row)
		local key = PageKey(row.SectionId, row.PageId) .. "|" .. row.ChapterId

		overrides[key] = overrides[key] or {}

		return overrides[key]
	end

	for row in GameInfo.CivilopediaPageChapterHeaders() do
		GetOverride(row).header = row.Header
	end

	local rows = {}

	for row in GameInfo.CivilopediaPageChapterParagraphs() do
		rows[#rows + 1] = row
	end

	table.sort(rows, function(a, b)
		return a.SortIndex < b.SortIndex
	end)

	for _, row in ipairs(rows) do
		local override = GetOverride(row)

		override.paragraphs = override.paragraphs or {}
		override.paragraphs[#override.paragraphs + 1] = row.Paragraph
	end

	return overrides
end

-- Returns the key of a page group, as CivilopediaSupport.lua writes it.
local function GroupKey(sectionID, groupID)
	return sectionID .. "|:" .. groupID
end

-- Returns the sections and the hidden sections, pages, and page groups, from
-- the excludes.
local function GetSections()
	local hidden = {}

	for row in GameInfo.CivilopediaSectionExcludes() do
		hidden[row.SectionId] = true
	end

	for row in GameInfo.CivilopediaPageExcludes() do
		hidden[PageKey(row.SectionId, row.PageId)] = true
	end

	for row in GameInfo.CivilopediaPageGroupExcludes() do
		hidden[GroupKey(row.SectionId, row.PageGroupId)] = true
	end

	local sections, byID = {}, {}

	for row in GameInfo.CivilopediaSections() do
		if not hidden[row.SectionId] then
			local section = { sectionID = row.SectionId, title = Locale.Lookup(row.Name), sortIndex = row.SortIndex }

			sections[#sections + 1] = section
			byID[row.SectionId] = section
		end
	end

	return sections, byID, hidden
end

-- Returns every page the Civilopedia shows, from CivilopediaPages and the
-- rows of each CivilopediaPageQueries query, without hidden pages, pages of a
-- hidden group, or pages of a section it doesn't have, as AddPage does. A
-- query page keeps the table its SQL reads, which holds its row, and each page
-- keeps its group and sort index.
local function GetPages(byID, hidden)
	local pages = {}

	local function AddPage(page)
		local inHiddenGroup = page.groupID ~= nil and hidden[GroupKey(page.sectionID, page.groupID)]

		if byID[page.sectionID] ~= nil and not hidden[PageKey(page.sectionID, page.pageID)] and not inHiddenGroup then
			pages[#pages + 1] = page
		end
	end

	for row in GameInfo.CivilopediaPages() do
		AddPage({
			sectionID = row.SectionId,
			pageID = row.PageId,
			groupID = row.PageGroupId,
			sortIndex = row.SortIndex,
			layout = row.PageLayoutId,
			name = row.Name,
			prefix = row.TextKeyPrefix,
		})
	end

	for query in GameInfo.CivilopediaPageQueries() do
		local tableName = query.SQL:match("[Ff][Rr][Oo][Mm]%s+([%w_]+)")

		for _, row in ipairs(DB.Query(query.SQL)) do
			AddPage({
				sectionID = query.SectionId,
				pageID = row[query.PageIdColumn],
				groupID = query.PageGroupIdColumn and row[query.PageGroupIdColumn],
				sortIndex = query.SortIndexColumn and row[query.SortIndexColumn] or query.SortIndex,
				layout = row[query.PageLayoutIdColumn],
				name = row[query.NameColumn],
				prefix = query.TextKeyPrefixColumn and row[query.TextKeyPrefixColumn],
				tableName = tableName,
			})
		end
	end

	return pages
end

-- Returns the page groups of each section, by section and group ID, each with
-- its title and sort index, from CivilopediaPageGroups and the rows of each
-- CivilopediaPageGroupQueries query. A group's title has the page keys with
-- its ID as the page ID, as CacheData_ProcessData looks it up.
local function GetPageGroups(byID, hidden)
	local groups = {}

	local function AddGroup(sectionID, groupID, name, sortIndex)
		if byID[sectionID] ~= nil and groupID ~= nil and not hidden[GroupKey(sectionID, groupID)] then
			local titleKey = FindTextKey(GetPageKeys({ sectionID = sectionID, pageID = groupID }, "_TAB_NAME")) or name or groupID

			groups[GroupKey(sectionID, groupID)] = { title = SentientSystems_LookupText(titleKey), sortIndex = sortIndex }
		end
	end

	for row in GameInfo.CivilopediaPageGroups() do
		AddGroup(row.SectionId, row.PageGroupId, row.Name, row.SortIndex)
	end

	for query in GameInfo.CivilopediaPageGroupQueries() do
		for _, row in ipairs(DB.Query(query.SQL)) do
			local sortIndex = query.SortIndexColumn and row[query.SortIndexColumn] or query.SortIndex

			AddGroup(query.SectionId, query.PageGroupIdColumn and row[query.PageGroupIdColumn], row[query.NameColumn], sortIndex)
		end
	end

	return groups
end

-- Returns the extra search words of each page, by section and page, from
-- CivilopediaPageSearchTerms and CivilopediaPageSearchTermQueries.
local function GetSearchTerms()
	local terms = {}

	local function AddTerm(sectionID, pageID, term)
		if sectionID ~= nil and pageID ~= nil and term ~= nil then
			local key = PageKey(sectionID, pageID)
			local list = terms[key] or {}

			list[#list + 1] = Locale.Lookup(term)
			terms[key] = list
		end
	end

	for row in GameInfo.CivilopediaPageSearchTerms() do
		AddTerm(row.SectionId, row.PageId, row.Term)
	end

	for query in GameInfo.CivilopediaPageSearchTermQueries() do
		for _, row in ipairs(DB.Query(query.SQL)) do
			AddTerm(row[query.SectionIdColumn], row[query.PageIdColumn], row[query.SearchTermColumn])
		end
	end

	return terms
end

-- Fills each page's title, row, chapters, text, and search words.
local function FillPages(pages)
	local layoutChapters, overrides, terms = GetLayoutChapters(), GetChapterOverrides(), GetSearchTerms()

	for _, page in ipairs(pages) do
		local titleKey = FindTextKey(GetPageKeys(page, "_TITLE")) or page.name or page.pageID
		local rows = page.tableName and GameInfo[page.tableName]

		page.title = SentientSystems_LookupText(titleKey)
		page.row = rows and rows[page.pageID]
		page.chapters = GetRulesChapters(page, layoutChapters, overrides)
		page.text = GetPageText(page.row, page.chapters)
		page.terms = terms[PageKey(page.sectionID, page.pageID)] or {}
	end
end

-- Returns the Civilopedia's sections and pages, building them on the first
-- call. Pages are in table order, each with its group's title and sort index,
-- if it has a group, and byKey finds a page by section and page.
function SentientSystems_GetCivilopedia()
	if civilopedia == nil then
		local sections, byID, hidden = GetSections()
		local pages = GetPages(byID, hidden)
		local groups = GetPageGroups(byID, hidden)
		local byKey = {}

		FillPages(pages)

		for _, page in ipairs(pages) do
			byKey[PageKey(page.sectionID, page.pageID)] = page
			page.group = page.groupID and groups[GroupKey(page.sectionID, page.groupID)]
		end

		civilopedia = { sections = sections, pages = pages, byKey = byKey }
	end

	return civilopedia
end

-- Returns the page in the section, or nil.
function SentientSystems_GetCivilopediaPage(sectionID, pageID)
	return SentientSystems_GetCivilopedia().byKey[PageKey(sectionID, pageID)]
end

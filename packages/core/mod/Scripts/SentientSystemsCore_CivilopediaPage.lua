-- Gives one Civilopedia page as text, by running the game's own page layout
-- with drawing calls that write lines in place of controls. See
-- docs/findings/civilopedia.md#page-layouts.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Text")
SentientSystems_Include("SentientSystemsCore_Civilopedia")

-- The row columns that say nothing about the game, left out of a page's stats.
local HIDDEN_COLUMNS = {
	Hash = true, Index = true, RowId = true, rowid = true, PrimaryKey = true, Name = true, Description = true,
}

-- The lines of the page being drawn, and the page.
local lines, drawing = nil, nil

-- Whether the game's page layouts are loaded, or nil before the first page.
local layoutsLoaded = nil

-- Returns a caption as clean text, or nil. A caption is a text key or text.
local function GetCaption(caption)
	if type(caption) ~= "string" or caption == "" then
		return nil
	end

	local text = SentientSystems_CleanText(Locale.Lookup(caption))

	-- A dropped icon can leave two spaces, as in "1 Military  Slot".
	return text and (text:gsub("  +", " "))
end

local function AddLine(prefix, caption)
	local text = GetCaption(caption)

	if text ~= nil then
		lines[#lines + 1] = prefix .. text
	end
end

-- Adds each paragraph, which may be one text or a list of them.
local function AddParagraphLines(paragraphs)
	if type(paragraphs) ~= "table" then
		paragraphs = { paragraphs }
	end

	for _, paragraph in ipairs(paragraphs) do
		AddLine("", paragraph)
	end
end

-- Returns the name in an icon from a page layout, which is a list of the icon,
-- its name, and its type.
local function GetIconName(icon)
	return type(icon) == "table" and icon[2] or nil
end

-- A stat box that writes each label as a line under its box's heading.
local function DrawStatBox(title, populate)
	local box = {}

	AddLine("## ", title)

	function box.AddSeparator() end

	function box.AddHeader(_, caption)
		AddLine("### ", caption)
	end

	function box.AddLabel(_, caption)
		AddLine("- ", caption)
	end

	box.AddSmallLabel = box.AddLabel

	function box.AddIconLabel(_, icon, caption)
		AddLine("- ", caption or GetIconName(icon))
	end

	function box.AddIconNumberLabel(_, icon, value, caption)
		AddLine("- " .. tostring(value) .. " ", caption or GetIconName(icon))
	end

	function box.AddIconList(_, ...)
		for i = 1, select("#", ...) do
			AddLine("- ", GetIconName(select(i, ...)))
		end
	end

	populate(box)
end

-- A header and its body sit under the heading before them, as Unique Ability
-- holds a great person's Retire.
local function DrawHeaderBody(header, body)
	AddLine("### ", header)
	AddParagraphLines(body)
end

local function DrawChapter(header, paragraphs)
	AddLine("## ", header)
	AddParagraphLines(paragraphs)
end

local function IgnoreDrawing() end

-- Returns the chapter of the page being drawn, or nil.
local function FindChapter(sectionID, pageID, chapterID)
	local page = SentientSystems_GetCivilopediaPage(sectionID, pageID)

	for _, chapter in ipairs(page and page.chapters or {}) do
		if chapter.chapterID == chapterID then
			return chapter
		end
	end
end

local function AddHeaderLine(caption)
	AddLine("## ", caption)
end

local function AddParagraphLine(paragraph)
	AddLine("", paragraph)
end

local function DrawIconHeaderBody(_, header, body)
	DrawHeaderBody(header, body)
end

local function DrawSubHeader(caption)
	AddLine("", caption)
end

-- Returns the chapters of the page being drawn, as GetPageChapters does.
local function GetDrawnChapters()
	local chapters = {}

	for _, chapter in ipairs(drawing.chapters) do
		chapters[#chapters + 1] = { ChapterId = chapter.chapterID }
	end

	return chapters
end

local function GetIndexedChapterHeader(sectionID, pageID, chapterID)
	local chapter = FindChapter(sectionID, pageID, chapterID)

	return chapter and chapter.header
end

local function GetIndexedChapterBody(sectionID, pageID, chapterID)
	local chapter = FindChapter(sectionID, pageID, chapterID)

	return chapter and chapter.paragraphs
end

-- Loads the game's page layouts into this state, as CivilopediaScreen.lua
-- does, then replaces the drawing calls of CivilopediaSupport.lua with ones
-- that write lines, and its chapter calls, which read its own caches, with
-- ones that read the index and so leave out history. Quotes, portraits, and
-- images say nothing about the rules, so they draw nothing. The game's Lua has
-- no _G, so each global is set by name.
local function LoadLayouts()
	include("CivilopediaSupport")
	include("CivilopediaPage_", true)

	SetPageHeader, ShowFrontPageHeader, SetPageSubHeader = IgnoreDrawing, IgnoreDrawing, DrawSubHeader
	AddQuote, AddPortrait, AddTallPortrait = IgnoreDrawing, IgnoreDrawing, IgnoreDrawing
	AddImage, AddTallImage, AddTallImageNoScale = IgnoreDrawing, IgnoreDrawing, IgnoreDrawing
	AddRightColumnStatBox, AddChapter, AddHeader = DrawStatBox, DrawChapter, AddHeaderLine
	AddParagraph, AddParagraphs = AddParagraphLine, AddParagraphLines
	AddHeaderBody, AddIconHeaderBody = DrawHeaderBody, DrawIconHeaderBody
	AddFullWidthChapter, AddFullWidthHeader, AddFullWidthParagraph = DrawChapter, AddHeaderLine, AddParagraphLine
	AddFullWidthParagraphs, AddFullWidthHeaderBody = AddParagraphLines, DrawHeaderBody
	AddFullWidthIconHeaderBody = DrawIconHeaderBody
	AddLeftColumnChapter, AddLeftColumnHeader, AddLeftColumnParagraph = DrawChapter, AddHeaderLine, AddParagraphLine
	AddLeftColumnParagraphs, AddLeftColumnHeaderBody = AddParagraphLines, DrawHeaderBody
	AddLeftColumnIconHeaderBody = DrawIconHeaderBody
	GetPageChapters, GetChapterHeader, GetChapterBody = GetDrawnChapters, GetIndexedChapterHeader, GetIndexedChapterBody

	return true
end

-- Returns the page's row as lines of stats, sorted, without the columns that
-- say nothing and the ones that are 0 or false.
local function GetRowLines(row)
	local stats = {}

	for column, value in pairs(row or {}) do
		local kind = type(value)

		if not HIDDEN_COLUMNS[column] and value ~= 0 and value ~= false and (kind == "string" or kind == "number" or kind == "boolean") then
			stats[#stats + 1] = "- " .. column .. ": " .. tostring(value)
		end
	end

	table.sort(stats)

	return stats
end

-- Returns the heading level of a line, or nil for a line that isn't a heading.
local function GetHeadingLevel(line)
	local marks = line:match("^(#+) ")

	return marks and #marks
end

-- Returns the lines without each heading that has nothing under it: a heading
-- that the end or a heading of its level or higher follows. Works from the
-- end, so a heading that held only empty headings goes too.
local function DropEmptyHeadings(drawn)
	local kept = {}

	for i = #drawn, 1, -1 do
		local level = GetHeadingLevel(drawn[i])
		local nextLevel = kept[1] and GetHeadingLevel(kept[1])

		if level == nil or kept[1] ~= nil and (nextLevel == nil or nextLevel > level) then
			table.insert(kept, 1, drawn[i])
		end
	end

	return kept
end

-- Returns whether a drawn line holds the first line of the text. Drawn lines
-- have their double spaces collapsed, so the text's are too.
local function HasDrawn(text)
	local first = text:match("^[^\n]*"):gsub("  +", " ")

	for _, line in ipairs(lines) do
		if line:find(first, 1, true) then
			return true
		end
	end

	return false
end

-- Returns the page's text from its layout, or from its text and row when the
-- layout is missing or fails, which prints an ERROR line.
local function DrawPage(page, templates)
	local layout = PageLayouts and PageLayouts[templates[page.layout] or page.layout]
	local finished = false

	lines, drawing = {}, page

	if layout ~= nil then
		SentientSystems_CatchErrors("CivilopediaPage_" .. tostring(page.layout), function()
			layout({
				SectionId = page.sectionID,
				PageId = page.pageID,
				PageLayoutId = page.layout,
				Title = page.title,
				TextKeyPrefix = page.prefix,
			})
			finished = true
		end)()
	end

	-- A layout that fails partway has drawn the top of the page already, so its
	-- lines stay. The page's own text follows unless the layout drew it, as a
	-- unit's layout draws its Description last, and then the stats.
	if not finished then
		if page.text ~= nil and not HasDrawn(page.text) then
			lines[#lines + 1] = page.text
		end

		lines[#lines + 1] = "## Stats"

		for _, line in ipairs(GetRowLines(page.row)) do
			lines[#lines + 1] = line
		end
	end

	local text = table.concat(DropEmptyHeadings(lines), "\n")

	return text ~= "" and text or nil
end

-- Returns the pages with the page ID, in any case, in the section if it is
-- given.
local function FindPages(pageID, sectionID)
	local found = {}

	for _, page in ipairs(SentientSystems_GetCivilopedia().pages) do
		if page.pageID:upper() == pageID:upper() and (sectionID == nil or page.sectionID == sectionID) then
			found[#found + 1] = page
		end
	end

	return found
end

-- Returns the script template of each page layout, by layout ID.
local function GetTemplates()
	local templates = {}

	for row in GameInfo.CivilopediaPageLayouts() do
		templates[row.PageLayoutId] = row.ScriptTemplate
	end

	return templates
end

-- Returns one Civilopedia page as JSON, with its section, page ID, title, and
-- its text as the game's page shows it. sectionID is needed only for a page ID
-- that more than one section has, such as INTRO. A page that isn't found
-- gives an error. Shape: bridge/src/lookup/lookup.ts.
function SentientSystems_LookupPage(pageID, sectionID)
	local pages = FindPages(tostring(pageID or ""), sectionID)

	if #pages == 0 then
		return SentientSystems_EncodeJson({ error = "No page has the ID " .. tostring(pageID) .. (sectionID and " in " .. sectionID or "") .. ". Search with lookup first." })
	end

	if #pages > 1 then
		local sections = {}

		for i, page in ipairs(pages) do
			sections[i] = page.sectionID
		end

		return SentientSystems_EncodeJson({ error = pages[1].pageID .. " is in more than one section. Give one of: " .. table.concat(sections, ", ") .. "." })
	end

	if layoutsLoaded == nil then
		layoutsLoaded = LoadLayouts()
	end

	local page = pages[1]

	return SentientSystems_EncodeJson({
		sectionID = page.sectionID,
		pageID = page.pageID,
		title = page.title,
		text = DrawPage(page, GetTemplates()),
	})
end

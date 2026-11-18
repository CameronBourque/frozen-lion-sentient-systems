-- Lists the Civilopedia's sections, and the pages of one section by group, in
-- the order the game's Civilopedia shows them. Follows CacheData_SortData in
-- CivilopediaSupport.lua.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_Civilopedia")

-- Returns whether a comes before b, with nil first, as SortNumberOrNil does.
local function IsBeforeOrNil(a, b)
	if a == nil or b == nil then
		return a == nil and b ~= nil
	end

	return a < b
end

-- Returns whether page a comes before page b: by group, with no group first,
-- then by the group's sort index and title, then the page's sort index and
-- title, as SortPages and SortPageGroups do.
local function IsPageBefore(a, b)
	if a.groupID ~= b.groupID then
		local groupA, groupB = a.group or {}, b.group or {}

		if a.group == nil or b.group == nil then
			return a.group == nil
		elseif groupA.sortIndex ~= groupB.sortIndex then
			return IsBeforeOrNil(groupA.sortIndex, groupB.sortIndex)
		elseif groupA.title ~= groupB.title then
			return groupA.title < groupB.title
		end

		return a.groupID < b.groupID
	elseif a.sortIndex ~= b.sortIndex then
		return IsBeforeOrNil(a.sortIndex, b.sortIndex)
	end

	return a.title < b.title
end

-- Returns the section with the ID, in any case, or nil.
local function FindSection(sectionID)
	for _, section in ipairs(SentientSystems_GetCivilopedia().sections) do
		if section.sectionID:upper() == sectionID:upper() then
			return section
		end
	end
end

-- Returns the section IDs, joined, in the game's order.
local function ListSectionIDs(sections)
	local ids = {}

	for i, section in ipairs(sections) do
		ids[i] = section.sectionID
	end

	return table.concat(ids, ", ")
end

-- Returns the sections in the game's order.
local function GetSortedSections()
	local sections = {}

	for i, section in ipairs(SentientSystems_GetCivilopedia().sections) do
		sections[i] = section
	end

	table.sort(sections, function(a, b)
		return IsBeforeOrNil(a.sortIndex, b.sortIndex)
	end)

	return sections
end

-- Returns the Civilopedia's sections as JSON, in the game's order, each with
-- its ID, title, and how many pages it has. Shape: bridge/src/lookup/lookup.ts.
function SentientSystems_LookupSections()
	local counts = {}

	for _, page in ipairs(SentientSystems_GetCivilopedia().pages) do
		counts[page.sectionID] = (counts[page.sectionID] or 0) + 1
	end

	local sections = {}

	for i, section in ipairs(GetSortedSections()) do
		sections[i] = { sectionID = section.sectionID, title = section.title, pageCount = counts[section.sectionID] or 0 }
	end

	return SentientSystems_EncodeJson({ sections = sections })
end

-- Returns one section's pages as JSON, in the game's order, in its groups.
-- Each group has its title, which pages with no group don't have, and the ID
-- and title of each of its pages. A section that isn't found gives an error.
-- Shape: bridge/src/lookup/lookup.ts.
function SentientSystems_LookupSection(sectionID)
	local section = FindSection(tostring(sectionID or ""))

	if section == nil then
		return SentientSystems_EncodeJson({ error = "No section has the ID " .. tostring(sectionID) .. ". Give one of: " .. ListSectionIDs(GetSortedSections()) .. "." })
	end

	local pages = {}

	for _, page in ipairs(SentientSystems_GetCivilopedia().pages) do
		if page.sectionID == section.sectionID then
			pages[#pages + 1] = page
		end
	end

	table.sort(pages, IsPageBefore)

	local groups, previous = {}, nil

	for i, page in ipairs(pages) do
		if i == 1 or page.groupID ~= previous.groupID then
			groups[#groups + 1] = { title = page.group and page.group.title, pages = {} }
		end

		local list = groups[#groups].pages

		list[#list + 1] = { pageID = page.pageID, title = page.title }
		previous = page
	end

	return SentientSystems_EncodeJson({ sectionID = section.sectionID, title = section.title, groups = groups })
end

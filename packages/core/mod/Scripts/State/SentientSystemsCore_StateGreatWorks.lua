-- The great works section, as the Great Works screen shows it. Shape:
-- bridge/src/state/great-works.ts. The slots and moves are in
-- SentientSystemsCore_GreatWorks.lua, which the great work actions share.

SentientSystems_Include("SentientSystemsCore_GreatWorks")

-- Returns the great works in a building, in slot order, as the screen's
-- GetGreatWorksInBuilding does.
local function GetWorks(buildings, index)
	local works = {}

	for slot = 0, buildings:GetNumGreatWorkSlots(index) - 1 do
		local work = buildings:GetGreatWorkInSlot(index, slot)

		if work ~= -1 then
			works[#works + 1] = work
		end
	end

	return works
end

-- Returns whether the work is the first by its creator in the building. See
-- IsFirstGreatWorkByArtist.
local function IsFirstByArtist(buildings, index, work)
	local artist = buildings:GetCreatorNameFromIndex(work)

	for _, other in ipairs(GetWorks(buildings, index)) do
		if other == work then
			return true
		end

		if buildings:GetCreatorNameFromIndex(other) == artist then
			return false
		end
	end

	return true
end

-- Returns whether the works in an artifact museum are all from different
-- civilizations. See GreatWorkFitsTheme.
local function HasNoDuplicatePlayer(buildings, index)
	local seen = {}

	for _, work in ipairs(GetWorks(buildings, index)) do
		local owner = Game.GetGreatWorkPlayer(work)

		if seen[owner] then
			return false
		end

		seen[owner] = true
	end

	return true
end

-- Returns the theming rules of a building from Building_GreatWorks, or nil
-- when it has none. The table is the game's own list of what a full theme
-- needs, which the screen shows only as text.
local function GetThemeRules(building)
	for row in GameInfo.Building_GreatWorks() do
		if row.BuildingType == building.BuildingType
			and (row.ThemingUniquePerson or row.ThemingSameObjectType or row.ThemingSameEras or row.ThemingUniqueCivs)
		then
			return {
				uniqueCreators = row.ThemingUniquePerson == true,
				sameObjectType = row.ThemingSameObjectType == true,
				sameEra = row.ThemingSameEras == true,
				uniqueCivilizations = row.ThemingUniqueCivs == true,
				yieldMultiplier = row.ThemingYieldMultiplier,
				tourismMultiplier = row.ThemingTourismMultiplier,
			}
		end
	end

	return nil
end

-- Returns whether a work counts toward the theme of its building, as
-- GreatWorkFitsTheme works it out, but from the building's rules. The first
-- work always counts, because the others are measured against it.
local function FitsTheme(buildings, index, rules, work, first)
	if first == nil or rules == nil then
		return false
	end

	if buildings:IsBuildingThemedCorrectly(index) or work.index == first.index then
		return true
	end

	return (not rules.uniqueCreators or IsFirstByArtist(buildings, index, work.index))
		and (not rules.sameObjectType or first.objectType == work.objectType)
		and (not rules.sameEra or first.era == work.era)
		and (not rules.uniqueCivilizations or HasNoDuplicatePlayer(buildings, index))
end

-- Returns the localized text of the theming bonus, or nil when the building
-- has none. See GetThemeDescription.
local function GetThemeBonus(culture, building)
	if culture:GetAutoThemedBuilding() == building.Index or culture:IsAutoThemedEligible(building.Hash) then
		return SentientSystems_LookupText("LOC_BUILDING_THEMINGBONUS_FULL_MUSEUM")
	end

	for row in GameInfo.Building_GreatWorks() do
		if row.BuildingType == building.BuildingType and row.ThemingBonusDescription ~= nil then
			return SentientSystems_LookupText(row.ThemingBonusDescription)
		end
	end

	return nil
end

-- Returns what the building's great works give: the yields of each type above
-- 0, and the tourism with the religious tourism.
local function GetBuildingYields(buildings, index)
	local yields = {}

	for row in GameInfo.Yields() do
		local amount = buildings:GetBuildingYieldFromGreatWorks(row.Index, index)

		if amount > 0 then
			yields[#yields + 1] = { type = row.YieldType, amount = amount }
		end
	end

	local tourism = buildings:GetBuildingTourismFromGreatWorks(false, index) + buildings:GetBuildingTourismFromGreatWorks(true, index)

	return yields, tourism
end

-- Returns one building with great work slots as an entry for how far its theme
-- has come and what its works give, and the list of its slots.
local function GetBuilding(city, building, culture)
	local buildings = city:GetBuildings()
	local index = building.Index
	local bonus = GetThemeBonus(culture, building)
	local rules = GetThemeRules(building)
	local slots = SentientSystems_GetGreatWorkSlots(city, building)
	local count, themed = 0, 0
	local first

	for _, entry in ipairs(slots) do
		first = first or entry.work
	end

	for _, entry in ipairs(slots) do
		if entry.work ~= nil then
			count = count + 1

			if bonus ~= nil then
				entry.themed = FitsTheme(buildings, index, rules, entry.work, first)
				themed = themed + (entry.themed and 1 or 0)
			end
		end
	end

	local yields, tourism = GetBuildingYields(buildings, index)
	local theme

	if bonus ~= nil then
		theme = {
			bonus = bonus,
			complete = buildings:IsBuildingThemedCorrectly(index),
			themedWorks = culture:IsAutoThemedEligible() and count or themed,
			rules = rules,
		}
	end

	return {
		city = slots[1].city,
		type = building.BuildingType,
		name = Locale.Lookup(building.Name),
		spaces = #slots,
		works = count,
		theme = theme,
		yields = yields,
		tourism = tourism,
	}, slots
end

-- Adds a list of yields to the totals, which are keyed by yield type.
local function AddTotals(totals, order, yields)
	for _, yield in ipairs(yields) do
		if totals[yield.type] == nil then
			order[#order + 1] = yield.type
			totals[yield.type] = 0
		end

		totals[yield.type] = totals[yield.type] + yield.amount
	end
end

-- Returns the great works section: every slot, every building with slots, and
-- the totals the screen shows: the works, the display spaces, and what they
-- provide. The tourism is a yield of the totals, under TOURISM.
function SentientSystems_GetGreatWorkState(player)
	local culture = player:GetCulture()
	local buildings, slots, works, spaces = {}, {}, 0, 0
	local totals, order = {}, {}

	for _, found in ipairs(SentientSystems_GetGreatWorkBuildings(player)) do
		local entry, entrySlots = GetBuilding(found.city, found.building, culture)

		buildings[#buildings + 1] = entry
		works = works + entry.works
		spaces = spaces + entry.spaces

		for _, slot in ipairs(entrySlots) do
			slots[#slots + 1] = slot
		end

		AddTotals(totals, order, entry.yields)
		AddTotals(totals, order, { { type = "TOURISM", amount = entry.tourism } })
	end

	table.sort(order)

	local provides = {}

	for _, yield in ipairs(order) do
		if totals[yield] > 0 then
			provides[#provides + 1] = { type = yield, amount = totals[yield] }
		end
	end

	return { slots = slots, buildings = buildings, works = works, spaces = spaces, provides = provides }
end

-- Returns where the great work with the game's index can move, as the screen
-- lights up the slots when the work is picked up, or nil when the player has no
-- such work. Moves is empty when the work can't be moved at all. A move into a
-- filled slot swaps the two works. See OnClickGreatWork.
function SentientSystems_GetGreatWorkMoves(player, workIndex)
	local slots = SentientSystems_GetAllGreatWorkSlots(player)

	local source = SentientSystems_FindGreatWork(slots, workIndex)

	if source == nil then
		return nil
	end

	local moves = {}

	for _, destination in ipairs(slots) do
		if SentientSystems_GetGreatWorkMoveFailure(source, destination) == nil then
			moves[#moves + 1] = {
				city = destination.city,
				building = destination.building,
				slot = destination.slot,
				swap = destination.work and { index = destination.work.index, name = destination.work.name } or nil,
			}
		end
	end

	return {
		work = { index = workIndex, name = source.work.name },
		from = { city = source.city, building = source.building, slot = source.slot },
		moves = moves,
	}
end

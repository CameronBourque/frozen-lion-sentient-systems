-- The Great Works screen's rules that the great works state and the great work
-- actions share: the slots of the player's buildings, and where a work can
-- move. Follows GreatWorksOverview.lua and its Expansion 2 replacement.

include("SentientSystemsCore_Common")

local ARTIFACT_TYPE = "GREATWORKOBJECT_ARTIFACT"

local ART_TYPES = {
	GREATWORKOBJECT_SCULPTURE = true,
	GREATWORKOBJECT_LANDSCAPE = true,
	GREATWORKOBJECT_PORTRAIT = true,
	GREATWORKOBJECT_RELIGIOUS = true,
}

-- The turns an art work stays where it was put when the game sets no time.
local DEFAULT_LOCK_TURNS = 10

-- Returns the yields a great work row gives, as a list.
local function GetWorkYields(row)
	local yields = {}

	for change in GameInfo.GreatWork_YieldChanges() do
		if change.GreatWorkType == row.GreatWorkType then
			yields[#yields + 1] = { type = change.YieldType, amount = change.YieldChange }
		end
	end

	return yields
end

-- Returns the turns before the work can be moved again. Only art is locked,
-- from the turn it was created or moved in. See CanMoveWorkAtAll.
local function GetLockedTurns(buildings, work, objectType)
	if not ART_TYPES[objectType] then
		return 0
	end

	local lock = GlobalParameters.GREATWORK_ART_LOCK_TIME or DEFAULT_LOCK_TURNS

	return math.max(0, buildings:GetTurnFromIndex(work) + lock - Game.GetCurrentGameTurn())
end

-- Returns the great work in a slot, or nil for an empty one.
local function GetWork(buildings, index, slot)
	local work = buildings:GetGreatWorkInSlot(index, slot)

	if work == -1 then
		return nil
	end

	local row = GameInfo.GreatWorks[buildings:GetGreatWorkTypeFromIndex(work)]

	return {
		index = work,
		type = row.GreatWorkType,
		name = Locale.Lookup(row.Name),
		objectType = row.GreatWorkObjectType,
		era = row.EraType,
		tourism = row.Tourism,
		yields = GetWorkYields(row),
		lockedTurns = GetLockedTurns(buildings, work, row.GreatWorkObjectType),
	}
end

-- Returns the object types a kind of slot takes, as the empty slot's tooltip
-- lists them.
local function GetAccepts(kind)
	local types = {}

	for row in GameInfo.GreatWork_ValidSubTypes() do
		if row.GreatWorkSlotType == kind then
			types[#types + 1] = row.GreatWorkObjectType
		end
	end

	return types
end

-- Returns whether the screen lets a work be dragged: not locked, and an
-- artifact only when its museum is full. See CanMoveWorkAtAll.
local function CanMove(work, museumFull)
	return work.lockedTurns == 0 and (work.objectType ~= ARTIFACT_TYPE or museumFull)
end

-- Returns the player's buildings that have great work slots, each with its
-- city and building row, as UpdateGreatWorks walks them.
function SentientSystems_GetGreatWorkBuildings(player)
	local found = {}

	for _, city in player:GetCities():Members() do
		for building in GameInfo.Buildings() do
			if city:GetBuildings():HasBuilding(building.Index) and city:GetBuildings():GetNumGreatWorkSlots(building.Index) > 0 then
				found[#found + 1] = { city = city, building = building }
			end
		end
	end

	return found
end

-- Returns the slots of one building in slot order, each with its city, kind,
-- the object types it takes, and its work. A work knows whether it can move.
function SentientSystems_GetGreatWorkSlots(city, building)
	local buildings = city:GetBuildings()
	local index = building.Index
	local cityRef = { id = city:GetID(), name = Locale.Lookup(city:GetName()) }
	local slots, count = {}, 0

	for slot = 0, buildings:GetNumGreatWorkSlots(index) - 1 do
		local kind = GameInfo.GreatWorkSlotTypes[buildings:GetGreatWorkSlotType(index, slot)].GreatWorkSlotType
		local work = GetWork(buildings, index, slot)

		slots[#slots + 1] = {
			city = cityRef,
			building = building.BuildingType,
			slot = slot,
			kind = kind,
			accepts = GetAccepts(kind),
			work = work,
		}
		count = count + (work and 1 or 0)
	end

	for _, entry in ipairs(slots) do
		if entry.work ~= nil then
			entry.work.movable = CanMove(entry.work, count == #slots)
		end
	end

	return slots
end

-- Returns the slots of every building of the player's cities.
function SentientSystems_GetAllGreatWorkSlots(player)
	local all = {}

	for _, found in ipairs(SentientSystems_GetGreatWorkBuildings(player)) do
		for _, slot in ipairs(SentientSystems_GetGreatWorkSlots(found.city, found.building)) do
			all[#all + 1] = slot
		end
	end

	return all
end

-- Returns why the work can't be picked up, or nil. See CanMoveWorkAtAll.
local function GetPickUpFailure(work)
	if work.movable then
		return nil
	end

	if work.lockedTurns > 0 then
		return work.name .. " is locked for " .. work.lockedTurns .. " more turns."
	end

	return work.name .. " is an artifact, and its museum isn't full."
end

-- Returns why the work in the source slot can't go into the destination slot,
-- or nil, as CanMoveGreatWork works it out. An artifact never goes to an empty
-- slot, and a swap needs the other work to fit the source slot and be free to
-- move. A source or destination that the lookup didn't find gives the reason
-- from the request, which names the work and the slot as the great works state
-- does: work, city, building, and slot.
function SentientSystems_GetGreatWorkMoveFailure(source, destination, request)
	if source == nil then
		return "You have no great work " .. tostring(request.work) .. ". Use an index from the great works state."
	end

	if destination == nil then
		return "You have no slot " .. tostring(request.slot) .. " in " .. tostring(request.building) .. " in city " .. tostring(request.city) .. ". Use a slot from the great works state."
	end

	local work, other = source.work, destination.work

	if source == destination then
		return work.name .. " is already in that slot."
	end

	local failure = GetPickUpFailure(work)

	if failure ~= nil then
		return failure
	end

	if not SentientSystems_Contains(destination.accepts, work.objectType) then
		return "That slot takes " .. table.concat(destination.accepts, ", ") .. ", and " .. work.name .. " is " .. work.objectType .. "."
	end

	if other == nil then
		return work.objectType == ARTIFACT_TYPE and "An artifact can't move to an empty slot. It swaps with another artifact in a full museum." or nil
	end

	if not SentientSystems_Contains(source.accepts, other.objectType) then
		return "That slot holds " .. other.name .. ", which can't swap into a slot that takes " .. table.concat(source.accepts, ", ") .. "."
	end

	return GetPickUpFailure(other)
end

-- Returns the slot that holds the great work with the game's index, or nil.
function SentientSystems_FindGreatWork(slots, workIndex)
	for _, entry in ipairs(slots) do
		if entry.work ~= nil and entry.work.index == workIndex then
			return entry
		end
	end

	return nil
end

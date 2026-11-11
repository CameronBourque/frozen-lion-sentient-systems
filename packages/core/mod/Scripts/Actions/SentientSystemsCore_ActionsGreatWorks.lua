-- The great work move action on the Great Works screen.
-- SentientSystemsCore_Actions.lua loads this file. The call is in
-- docs/findings/actions/great-works.md.

SentientSystems_Include("SentientSystemsCore_GreatWorks")

-- Returns the slot of the city's building with the number, or nil.
local function FindSlot(slots, cityID, buildingType, slot)
	for _, entry in ipairs(slots) do
		if entry.city.id == cityID and entry.building == buildingType and entry.slot == slot then
			return entry
		end
	end

	return nil
end

local function MoveGreatWork(playerID, workIndex, cityID, buildingType, slot)
	local slots = SentientSystems_GetAllGreatWorkSlots(SentientSystems_GetPlayer(playerID))
	local source = SentientSystems_FindGreatWork(slots, workIndex)
	local destination = FindSlot(slots, cityID, buildingType, slot)
	local failure = SentientSystems_GetGreatWorkMoveFailure(source, destination, { work = workIndex, city = cityID, building = buildingType, slot = slot })

	if failure ~= nil then
		return failure
	end

	-- The screen names the cities and buildings of both slots, and the slot of
	-- the destination. See MoveGreatWork.
	UI.RequestPlayerOperation(playerID, PlayerOperations.MOVE_GREAT_WORK, {
		[PlayerOperations.PARAM_PLAYER_ONE] = playerID,
		[PlayerOperations.PARAM_CITY_SRC] = source.city.id,
		[PlayerOperations.PARAM_CITY_DEST] = destination.city.id,
		[PlayerOperations.PARAM_BUILDING_SRC] = GameInfo.Buildings[source.building].Index,
		[PlayerOperations.PARAM_BUILDING_DEST] = GameInfo.Buildings[destination.building].Index,
		[PlayerOperations.PARAM_GREAT_WORK_INDEX] = workIndex,
		[PlayerOperations.PARAM_SLOT] = destination.slot,
	})

	return nil
end

-- Moves the great work with the game's index to a slot of the great works
-- state, given by its city ID, building type, and slot number, and returns the
-- result as JSON. A filled slot swaps the two works.
function SentientSystems_MoveGreatWork(playerID, workIndex, city, building, slot)
	return SentientSystems_RunAction("MoveGreatWork", MoveGreatWork, playerID, workIndex, city, building, slot)
end

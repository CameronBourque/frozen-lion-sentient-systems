-- The units section of the state: the player's own units, as the unit panel shows them.
-- SentientSystemsCore_State.lua loads this file. Example: SentientSystems_GetUnitStates(player)
-- returns a list with one table for each unit, which encodes as
-- '{"availablePromotions":[],"experience":{"nextLevel":15,"points":0},"health":{"max":100,"value":100},
-- "id":196608,"moves":{"left":3,"max":3},"promotions":[],"type":"UNIT_SCOUT","x":24,"y":15}', on one
-- line.

-- The X position of a unit that isn't on the map. civ6-mcp skips these units. See
-- docs/findings/game-api.md.
local OFF_MAP = -9999

-- Returns whether the unit is on the map and alive. UnitFlagManager.lua skips a unit that is dead or
-- about to die.
local function IsOnMap(unit)
	return unit:GetX() ~= OFF_MAP and not unit:IsDead() and not unit:IsDelayedDeath()
end

-- Returns the type of each promotion index in a list, such as PROMOTION_RANGER.
local function PromotionTypes(indexes)
	local types = {}

	for _, index in ipairs(indexes) do
		types[#types + 1] = GameInfo.UnitPromotions[index].UnitPromotionType
	end

	return types
end

-- Returns the promotions the unit can pick now, or an empty list. The unit panel asks
-- CanStartCommand for PROMOTE with results, and lists UnitCommandResults.PROMOTIONS. See
-- UnitPanel.lua, lines 435 to 446.
local function GetAvailablePromotions(unit)
	local canPromote, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)

	if not canPromote or results == nil or results[UnitCommandResults.PROMOTIONS] == nil then
		return {}
	end

	return PromotionTypes(results[UnitCommandResults.PROMOTIONS])
end

-- Adds the unit's experience, its promotions, and the promotions it can pick now to state. A unit
-- with no experience gets none of them.
local function AddPromotions(unit, state)
	local experience = unit:GetExperience()

	if experience == nil then
		return
	end

	state.experience = { points = experience:GetExperiencePoints(), nextLevel = experience:GetExperienceForNextLevel() }
	state.promotions = PromotionTypes(experience:GetPromotions())
	state.availablePromotions = GetAvailablePromotions(unit)
end

-- Returns a list of the player's units on the map. Health is the most damage less the damage taken,
-- as the unit panel shows it.
function SentientSystems_GetUnitStates(player)
	local units = {}

	for _, unit in player:GetUnits():Members() do
		if IsOnMap(unit) then
			local state = {
				id = unit:GetID(),
				type = GameInfo.Units[unit:GetType()].UnitType,
				x = unit:GetX(),
				y = unit:GetY(),
				moves = { left = unit:GetMovesRemaining(), max = unit:GetMaxMoves() },
				health = { value = unit:GetMaxDamage() - unit:GetDamage(), max = unit:GetMaxDamage() },
			}

			AddPromotions(unit, state)
			units[#units + 1] = state
		end
	end

	return units
end

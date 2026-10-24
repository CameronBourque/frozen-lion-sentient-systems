-- The units section of the state: the player's own units, as the unit panel shows them.
-- SentientSystemsCore_State.lua loads this file. Example: SentientSystems_GetUnitStates(player)
-- returns a list with one table for each unit, which encodes as
-- '{"health":{"max":100,"value":100},"id":196608,"moves":{"left":3,"max":3},"type":"UNIT_SCOUT","x":24,"y":15}'.

-- The X position of a unit that isn't on the map. civ6-mcp skips these units. See
-- docs/findings/game-api.md.
local OFF_MAP = -9999

-- Returns whether the unit is on the map and alive. UnitFlagManager.lua skips a unit that is dead or
-- about to die.
local function IsOnMap(unit)
	return unit:GetX() ~= OFF_MAP and not unit:IsDead() and not unit:IsDelayedDeath()
end

-- Returns a list of the player's units on the map. Health is the most damage less the damage taken,
-- as the unit panel shows it.
function SentientSystems_GetUnitStates(player)
	local units = {}

	for _, unit in player:GetUnits():Members() do
		if IsOnMap(unit) then
			units[#units + 1] = {
				id = unit:GetID(),
				type = GameInfo.Units[unit:GetType()].UnitType,
				x = unit:GetX(),
				y = unit:GetY(),
				moves = { left = unit:GetMovesRemaining(), max = unit:GetMaxMoves() },
				health = { value = unit:GetMaxDamage() - unit:GetDamage(), max = unit:GetMaxDamage() },
			}
		end
	end

	return units
end

-- The unit actions. SentientSystemsCore_Actions.lua loads this file. The calls
-- are in docs/findings/game-actions.md.

-- Returns why the unit can't move to x, y, or nil when it can. The game's check
-- for a move gives no reasons and passes any target, so each case is checked
-- here, with the path the game's cursor draws.
local function GetMoveFailure(playerID, unit, x, y)
	if not Map.IsPlot(x, y) then
		return "The tile (" .. x .. ", " .. y .. ") is off the map."
	end

	if x == unit:GetX() and y == unit:GetY() then
		return "The unit is already on that tile."
	end

	-- Air units deploy or attack instead of moving. See Civ6Common.lua.
	if GameInfo.Units[unit:GetUnitType()].Domain == "DOMAIN_AIR" then
		return "Air units can't move with this action."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	-- Civ6Common.lua opens a confirmation dialog here and doesn't move.
	if PlayersVisibility[playerID]:IsVisible(x, y) then
		local wars = CombatManager.IsAttackChangeWarState(unit:GetComponentID(), x, y)

		if wars ~= nil and #wars > 0 then
			return "Moving there would start a war with player " .. wars[1] .. "."
		end
	end

	local index = Map.GetPlot(x, y):GetIndex()
	local plots = UnitManager.GetMoveToPathEx(unit, index).plots

	if plots[#plots] ~= index then
		return "The unit has no route to that tile."
	end

	return nil
end

-- Moves the unit to x, y by the game's own path, over as many turns as it
-- takes, and returns the result as JSON. It never attacks: a tile with an enemy
-- unit has no route. A result of ok means the game took the request, not that
-- the unit has arrived.
function SentientSystems_MoveUnit(playerID, unitID, x, y)
	return SentientSystems_RunAction("MoveUnit", function()
		local unit = UnitManager.GetUnit(playerID, unitID)

		if unit == nil then
			return "Player " .. playerID .. " has no unit " .. unitID .. "."
		end

		local failure = GetMoveFailure(playerID, unit, x, y)

		if failure ~= nil then
			return failure
		end

		local parameters = {
			[UnitOperationTypes.PARAM_X] = x,
			[UnitOperationTypes.PARAM_Y] = y,
			[UnitOperationTypes.PARAM_MODIFIERS] = UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION,
		}

		if not UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, parameters) then
			return "The game won't start that move."
		end

		UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, parameters)
	end)
end

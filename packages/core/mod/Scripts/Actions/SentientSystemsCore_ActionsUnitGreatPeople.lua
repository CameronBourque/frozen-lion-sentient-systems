-- The great person orders: activate, and harvest a wonder. The units file
-- loads this file. The calls are in docs/findings/actions/.

-- Returns whether the unit is a great person.
local function IsGreatPerson(unit)
	local person = unit:GetGreatPerson()

	return person ~= nil and GameInfo.GreatPersonClasses[person:GetClass()] ~= nil
end

-- Requests the command with no parameters, as UnitPanel.lua does, or returns
-- why the unit can't. The game's real check names what the unit needs, such as
-- a tile that the player owns.
local function DoGreatPersonCommand(unit, action, commandType)
	local hash = GameInfo.UnitCommands[commandType].Hash
	local canStart, results = UnitManager.CanStartCommand(unit, hash, false, true)

	if canStart then
		UnitManager.RequestCommand(unit, hash)

		return nil
	end

	return SentientSystems_GetOrderFailure(unit, action, IsGreatPerson(unit), function()
		return SentientSystems_GetFailureReasons(results, UnitCommandResults.FAILURE_REASONS, " ")
	end)
end

-- A great engineer's production goes to the wonder it stands on, so it is an
-- activate, and the game's reason names the wonder. The builders' commands that
-- add production are in the production file.
SentientSystems_AddUnitAction("activate", function(_, unit)
	return DoGreatPersonCommand(unit, "activate", "UNITCOMMAND_ACTIVATE_GREAT_PERSON")
end)

SentientSystems_AddUnitAction("harvest_wonder", function(_, unit)
	return DoGreatPersonCommand(unit, "harvest_wonder", "UNITCOMMAND_HARVEST_WONDER")
end)

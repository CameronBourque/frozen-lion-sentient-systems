-- The formation orders: a corps, an army, and a stack of units. The units file
-- loads this file. The calls are in docs/findings/actions/.

-- The orders that join the unit with another, by action name. noun and where
-- finish the reasons, and the corps and the army need moves and a military
-- unit.
local JOINS = {
	form_corps = {
		command = "FORM_CORPS",
		row = "UNITCOMMAND_FORM_CORPS",
		noun = "form a corps",
		where = "of the same kind next to it",
		military = true,
	},
	form_army = {
		command = "FORM_ARMY",
		row = "UNITCOMMAND_FORM_ARMY",
		noun = "form an army",
		where = "of the same kind next to it",
		military = true,
	},
	enter_formation = {
		command = "ENTER_FORMATION",
		row = "UNITCOMMAND_ENTER_FORMATION",
		noun = "join a formation",
		where = "on its tile",
	},
}

-- Returns the units the command can join the unit with, as the game lists them,
-- each with a player and an ID.
local function GetPartners(unit, command)
	local targets = UnitManager.GetCommandTargets(unit, command)

	return targets and targets[UnitCommandResults.UNITS] or {}
end

-- Returns the partners as text, each a name with its ID.
local function DescribePartners(partners)
	local texts = {}

	for i, partner in ipairs(partners) do
		local other = UnitManager.GetUnit(partner.player, partner.id)

		texts[i] = Locale.Lookup(GameInfo.Units[other:GetUnitType()].Name) .. " " .. partner.id
	end

	return table.concat(texts, ", ")
end

-- Returns why the unit can't join with the unit, or nil when the game gives
-- no more. The game gives no reasons for these commands, so each is checked.
local function GetJoinFailure(playerID, unit, action, otherID)
	local join = JOINS[action]
	local civic = GameInfo.UnitCommands[join.row].PrereqCivic

	if civic ~= nil and not Players[playerID]:GetCulture():HasCivic(GameInfo.Civics[civic].Index) then
		return Locale.Lookup(GameInfo.Civics[civic].Name) .. " is needed to " .. join.noun .. "."
	end

	if join.military and GameInfo.Units[unit:GetUnitType()].FormationClass == "FORMATION_CLASS_CIVILIAN" then
		return "This kind of unit can't " .. join.noun .. "."
	end

	if join.military and unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	local partners = GetPartners(unit, UnitCommandTypes[join.command])

	if #partners == 0 then
		return "No unit " .. join.where .. " can " .. join.noun .. " with it."
	end

	for _, partner in ipairs(partners) do
		if partner.id == otherID then
			return "The unit can't " .. join.noun .. " now."
		end
	end

	local lead = otherID == nil and "Name the unit to join." or "Unit " .. tostring(otherID) .. " can't join."

	return lead .. " The units that can are " .. DescribePartners(partners) .. "."
end

-- Requests the command with the other unit, or returns why it can't start.
-- The UI asks for the other unit's player and ID, and checks the command with
-- them first.
local function Join(playerID, unit, action, otherID)
	local command = UnitCommandTypes[JOINS[action].command]

	if otherID ~= nil then
		local parameters = {
			[UnitCommandTypes.PARAM_UNIT_PLAYER] = playerID,
			[UnitCommandTypes.PARAM_UNIT_ID] = otherID,
		}

		if UnitManager.CanStartCommand(unit, command, parameters) then
			UnitManager.RequestCommand(unit, command, parameters)

			return nil
		end
	end

	return GetJoinFailure(playerID, unit, action, otherID)
end

for action in pairs(JOINS) do
	SentientSystems_AddUnitAction(action, function(playerID, unit, _, _, type)
		return Join(playerID, unit, action, type)
	end)
end

-- A corps or an army can't leave its formation.
SentientSystems_AddUnitAction("exit_formation", function(_, unit)
	local formation = unit:GetMilitaryFormation()

	if UnitManager.CanStartCommand(unit, UnitCommandTypes.EXIT_FORMATION, false) then
		UnitManager.RequestCommand(unit, UnitCommandTypes.EXIT_FORMATION)

		return nil
	end

	if formation == MilitaryFormationTypes.CORPS_MILITARY_FORMATION or formation == MilitaryFormationTypes.ARMY_MILITARY_FORMATION then
		return "A corps or an army can't be split."
	end

	return "The unit is not in a formation with another unit."
end)

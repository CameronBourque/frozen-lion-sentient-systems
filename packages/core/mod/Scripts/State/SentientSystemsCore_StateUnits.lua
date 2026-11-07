-- The units section: the player's own units, as the unit panel shows them.
-- Shape: bridge/src/state/units.ts.

-- The X position of a unit that isn't on the map. civ6-mcp skips these units.
-- See docs/findings/game-api.md.
local OFF_MAP = -9999

-- Returns health as the game shows it: the most damage less the damage taken,
-- out of the most damage. The unit panel shows a unit's health this way, and
-- the city banner a garrison's and walls'. The cities and rivals sections use
-- it too.
function SentientSystems_GetHealth(maxDamage, damage)
	return { value = maxDamage - damage, max = maxDamage }
end

-- Returns whether the unit is on the map and alive. UnitFlagManager.lua skips a
-- unit that is dead or about to die. The rivals section uses it too.
function SentientSystems_IsUnitOnMap(unit)
	return unit:GetX() ~= OFF_MAP and not unit:IsDead() and not unit:IsDelayedDeath()
end

-- Returns the type of each promotion index in a list.
local function PromotionTypes(indexes)
	local types = {}

	for _, index in ipairs(indexes) do
		types[#types + 1] = GameInfo.UnitPromotions[index].UnitPromotionType
	end

	return types
end

-- Returns the promotions the unit can pick now, or an empty list. The unit
-- panel asks CanStartCommand for PROMOTE with results, and lists
-- UnitCommandResults.PROMOTIONS. See UnitPanel.lua.
local function GetAvailablePromotions(unit)
	local canPromote, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.PROMOTE, true, true)

	if not canPromote or results == nil or results[UnitCommandResults.PROMOTIONS] == nil then
		return {}
	end

	return PromotionTypes(results[UnitCommandResults.PROMOTIONS])
end

-- Adds the unit's experience, its promotions, and the promotions it can pick
-- now to state. A unit with no experience gets none of them.
local function AddPromotions(unit, state)
	local experience = unit:GetExperience()

	if experience == nil then
		return
	end

	state.experience = { points = experience:GetExperiencePoints(), nextLevel = experience:GetExperienceForNextLevel() }
	state.promotions = PromotionTypes(experience:GetPromotions())
	state.availablePromotions = GetAvailablePromotions(unit)
end

-- The activities a unit reports, by the name the state gives. The unit list
-- shows sleep and skip turn as icons. See UnitPanel.lua, AddUnitToUnitList.
local ACTIVITIES = {
	{ type = "ACTIVITY_AWAKE", name = "awake" },
	{ type = "ACTIVITY_SLEEP", name = "sleep" },
	{ type = "ACTIVITY_HOLD", name = "skip" },
	{ type = "ACTIVITY_SENTRY", name = "sentry" },
	{ type = "ACTIVITY_HEAL", name = "heal" },
	{ type = "ACTIVITY_INTERCEPT", name = "intercept" },
	{ type = "ACTIVITY_OPERATION", name = "operation" },
}

-- Returns what the unit is doing, or nil for NO_ACTIVITY.
local function GetActivity(unit)
	local activity = UnitManager.GetActivityType(unit)

	for _, row in ipairs(ACTIVITIES) do
		if activity == ActivityTypes[row.type] then
			return row.name, activity
		end
	end

	return nil, activity
end

-- Returns whether the unit can attack, as UnitInfo's combat values say. A
-- civilian reports one attack left too.
local function CanAttack(unit)
	return unit:GetCombat() > 0 or unit:GetRangedCombat() > 0 or unit:GetBombardCombat() > 0
end

-- Adds what the unit is doing and its charges to state. The unit list marks a
-- unit as fortified when it isn't awake and has fortify turns, and the panel
-- shows a charge only above 0. See UnitPanel.lua.
local function AddActivity(unit, state)
	local name, activity = GetActivity(unit)

	state.activity = name

	if activity ~= ActivityTypes.ACTIVITY_AWAKE and unit:GetFortifyTurns() > 0 then
		state.fortified = true
	end

	if CanAttack(unit) then
		state.attacksLeft = unit:GetAttacksRemaining()
	end

	if unit:GetBuildCharges() > 0 then
		state.buildCharges = unit:GetBuildCharges()
	end

	local formation = unit:GetMilitaryFormation()

	if formation == MilitaryFormationTypes.CORPS_MILITARY_FORMATION then
		state.formation = "corps"
	elseif formation == MilitaryFormationTypes.ARMY_MILITARY_FORMATION then
		state.formation = "army"
	end
end

function SentientSystems_GetUnitStates(player)
	local units = {}

	for _, unit in player:GetUnits():Members() do
		if SentientSystems_IsUnitOnMap(unit) then
			local state = {
				id = unit:GetID(),
				type = GameInfo.Units[unit:GetType()].UnitType,
				x = unit:GetX(),
				y = unit:GetY(),
				moves = { left = unit:GetMovesRemaining(), max = unit:GetMaxMoves() },
				health = SentientSystems_GetHealth(unit:GetMaxDamage(), unit:GetDamage()),
			}

			AddActivity(unit, state)
			AddPromotions(unit, state)
			units[#units + 1] = state
		end
	end

	return units
end

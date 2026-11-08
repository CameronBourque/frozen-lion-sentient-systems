-- The religious unit orders: found, spread, remove heresy, heal, and condemn.
-- The units file loads this file. The calls are in docs/findings/actions/.

-- Returns an order's check for a kind of unit that has charges: the units that
-- spread or heal have them in their row. The game's loose check fails with the
-- tile too, as for a pillage.
local function HasCharges(field)
	return function(row)
		return (row[field] or 0) > 0
	end
end

-- Requests an operation that takes no parameters, as UnitPanel.lua does, and
-- gives the game's reasons for a refusal, such as the district a prophet must
-- stand on. The game gives none for a spread or a heal, so need says what they
-- take.
local function DoReligiousOperation(unit, action, operation, kind, need)
	return SentientSystems_DoOperation(unit, action, operation, {
		kind = kind,
		hint = function()
			return SentientSystems_GetOperationReasons(unit, GameInfo.UnitOperations[operation].Hash) or need
		end,
	})
end

-- A great prophet founds a religion on its Holy Site. The player then picks the
-- religion's name and beliefs in the religion blocker's action.
SentientSystems_AddUnitAction("found_religion", function(_, unit)
	return DoReligiousOperation(unit, "found_religion", "UNITOPERATION_FOUND_RELIGION", function(row)
		return row.FoundReligion
	end)
end)

SentientSystems_AddUnitAction("spread_religion", function(_, unit)
	return DoReligiousOperation(unit, "spread_religion", "UNITOPERATION_SPREAD_RELIGION", HasCharges("SpreadCharges"), "It spreads from a city, and needs a religion and a charge left.")
end)

-- An Inquisitor removes the other religions from a city of its player's
-- religion, in place of spreading its own. Its row says it needs the
-- inquisition.
SentientSystems_AddUnitAction("remove_heresy", function(_, unit)
	return DoReligiousOperation(unit, "remove_heresy", "UNITOPERATION_REMOVE_HERESY", function(row)
		return row.RequiresInquisition
	end, "It removes other religions from a city that follows your religion, and needs a charge left.")
end)

SentientSystems_AddUnitAction("heal_followers", function(_, unit)
	return DoReligiousOperation(unit, "heal_followers", "UNITOPERATION_RELIGIOUS_HEAL", HasCharges("ReligiousHealCharges"), "It needs a wounded religious unit on its tile or next to it, itself included.")
end)

-- Condemning acts on a religious unit on the unit's own tile, so the loose
-- check fails with the tile and any kind of unit might have a target. The
-- game's texts name what the target must be.
SentientSystems_AddUnitAction("condemn_heretic", function(_, unit)
	return SentientSystems_DoCommand(unit, "condemn_heretic", {
		kind = function()
			return true
		end,
		hint = function()
			local _, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.CONDEMN_HERETIC, false, true)

			return SentientSystems_GetFailureReasons(results, UnitCommandResults.FAILURE_REASONS, " ") or "It needs a religious unit of another religion, owned by a player at war with you, on its tile."
		end,
	})
end)

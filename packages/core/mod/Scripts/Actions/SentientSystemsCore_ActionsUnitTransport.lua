-- The land unit orders that move by air: airlift and paradrop. Air units rebase
-- instead. The units file loads this file after the tile orders runner. The
-- calls are in docs/findings/actions/.

-- Returns whether the unit's kind has the paradrop ability, which the type
-- tags give.
local function CanParadrop(unit)
	local unitType = GameInfo.Units[unit:GetUnitType()].UnitType

	for row in GameInfo.TypeTags() do
		if row.Type == unitType and row.Tag == "CLASS_PARADROP" then
			return true
		end
	end

	return false
end

local function IsLandUnit(unit)
	return GameInfo.Units[unit:GetUnitType()].Domain == "DOMAIN_LAND"
end

SentientSystems_AddTileOrders({
	airlift = {
		command = "AIRLIFT",
		verb = "airlift",
		noun = "airlift",
		prep = "to",
		kind = IsLandUnit,
		moves = true,
		none = "An airlift needs the unit on or next to a city or aerodrome with an airport, and another to land in.",
	},
	paradrop = {
		command = "PARADROP",
		verb = "paradrop",
		noun = "paradrop",
		prep = "to",
		kind = CanParadrop,
		moves = true,
		none = "The unit has to start in a city or on an airstrip to paradrop.",
	},
})

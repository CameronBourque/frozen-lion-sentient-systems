-- The air unit orders that name a tile: rebase and deploy. The units file loads
-- this file after the tile orders runner. The calls are in
-- docs/findings/actions/.

local function IsAirUnit(unit)
	return GameInfo.Units[unit:GetUnitType()].Domain == "DOMAIN_AIR"
end

SentientSystems_AddTileOrders({
	rebase = {
		operation = "REBASE",
		verb = "rebase",
		noun = "rebase",
		prep = "to",
		kind = IsAirUnit,
		moves = true,
		none = "The unit has no tile in range to rebase to.",
	},
	deploy = {
		operation = "DEPLOY",
		verb = "deploy",
		noun = "deploy",
		prep = "to",
		kind = IsAirUnit,
		none = "The unit has no tile in range to deploy to.",
	},
})

-- Deals. A player's deals lists the gold and resource deals it has, each with player, the other
-- player's ID, gold or resource and amount, duration, enacted, and outgoing, true for what the player
-- pays. A deal with several items has one entry for each, in a deal of its own.

return function(env, world, ctx)
	local indexes = ctx.indexes

	env.DealItemTypes = { GOLD = 1, RESOURCES = 2 }
	env.ResultFormat = { SUMMARY = 1 }
	env.DealItemSubTypes = { NONE = 0 }
	env.DealManager = {
		GetPlayerDeals = function(playerID, otherID)
			local deals = {}

			for _, entry in ipairs(world.players[playerID].deals or {}) do
				if entry.player == otherID then
					deals[#deals + 1] = {
						FindItemsByType = function(_, itemType, _, owner)
							local payer = entry.outgoing and playerID or otherID

							if owner ~= payer or (entry.resource ~= nil) ~= (itemType == env.DealItemTypes.RESOURCES) then
								return nil
							end

							return {
								{
									GetAmount = function()
										return entry.amount or entry.gold
									end,
									GetValueType = function()
										return indexes[entry.resource]
									end,
									GetDuration = function()
										return entry.duration
									end,
									GetEnactedTurn = function()
										return entry.enacted
									end,
								},
							}
						end,
					}
				end
			end

			return deals
		end,
	}
end

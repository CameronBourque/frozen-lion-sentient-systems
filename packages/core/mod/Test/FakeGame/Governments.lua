-- Governments and policies. A player's government has type, missing for none, and slots, each with
-- type, such as SLOT_MILITARY, and policy, missing for an empty slot, and civicThisTurn, slotsOpen,
-- changeMade, and unlockCost, as the game's culture calls give them. A player's policies lists the
-- policies the player knows, each with type, slot, its slot type, description, civic, its
-- prerequisite, and locked, obsolete, banned, and unslottable. A player's government also has
-- unlocked, the other governments it has unlocked, anarchy, the turns by government type,
-- canChangeAtAll, and governmentChangeMade. world.governments lists the ruleset's governments, each
-- with type, civic, bonusType, bonuses, its two text keys, slots, counts by slot type, influence, with
-- perTurn, threshold, and envoys, favor, and legacyPercent. Registered after Research, whose Civics
-- table holds the civic completed this turn.

return function(env, world, ctx)
	local AddRow, indexes, hashes = ctx.AddRow, ctx.indexes, ctx.hashes

	env.GameInfo.Governments = ctx.TypedRows({}, "GovernmentType")
	env.GameInfo.GovernmentSlots = {}
	env.GameInfo.Policies = ctx.TypedRows({}, "PolicyType")
	env.GameInfo.Government_SlotCounts = ctx.Callable({})
	env.GameInfo.GovernmentModifiers = ctx.Callable({})
	env.GameInfo.ModifierArguments = ctx.Callable({})

	-- Adds a policy's row with a hash. A policy in a slot alone has only its type.
	local function AddPolicy(policy)
		AddRow("Policies", "PolicyType", policy.type)

		local row = env.GameInfo.Policies[indexes[policy.type]]

		row.Hash = ctx.NextHash(4000000, policy.type)
		row.GovernmentSlotType = row.GovernmentSlotType or policy.slot
		row.Description = row.Description or policy.description
		row.PrereqCivic = row.PrereqCivic or policy.civic
	end

	-- Each government in world.governments gets its row, its slot counts, the modifier that holds
	-- its legacy percent, and its Gathering Storm row with its favor.
	local governmentsXP2 = ctx.Callable({})

	for _, government in ipairs(world.governments or {}) do
		AddRow("Governments", "GovernmentType", government.type)

		local row = env.GameInfo.Governments[indexes[government.type]]
		local influence = government.influence or {}

		row.Hash = ctx.NextHash(4000000, government.type)
		row.PrereqCivic = government.civic
		row.BonusType = government.bonusType or "NO_GOVERNMENTBONUS"
		row.InherentBonusDesc = (government.bonuses or {})[1]
		row.AccumulatedBonusShortDesc = (government.bonuses or {})[2]
		row.InfluencePointsPerTurn = influence.perTurn or 1
		row.InfluencePointsThreshold = influence.threshold or 100
		row.InfluenceTokensPerThreshold = influence.envoys or 1

		for slotType, slotCount in pairs(government.slots or {}) do
			table.insert(env.GameInfo.Government_SlotCounts, { GovernmentType = government.type, GovernmentSlotType = slotType, NumSlots = slotCount })
		end

		if government.legacyPercent ~= nil then
			local modifierID = "MODIFIER_" .. government.type

			table.insert(env.GameInfo.GovernmentModifiers, { GovernmentType = government.type, ModifierId = modifierID })
			table.insert(env.GameInfo.ModifierArguments, { ModifierId = modifierID, Name = "BonusType", Value = row.BonusType })
			table.insert(env.GameInfo.ModifierArguments, { ModifierId = modifierID, Name = "Amount", Value = tostring(government.legacyPercent) })
		end

		table.insert(governmentsXP2, { GovernmentType = government.type, Favor = government.favor or 0 })
	end

	-- Each government, slot type, policy, and civic completed this turn gets a row.
	for _, data in pairs(world.players or {}) do
		local government = data.government or {}

		if government.type ~= nil then
			AddRow("Governments", "GovernmentType", government.type)
		end

		if government.civicThisTurn ~= nil then
			AddRow("Civics", "CivicType", government.civicThisTurn)
		end

		for _, slot in ipairs(government.slots or {}) do
			AddRow("GovernmentSlots", "GovernmentSlotType", slot.type)

			if slot.policy ~= nil then
				AddPolicy({ type = slot.policy })
			end
		end

		for _, policy in ipairs(data.policies or {}) do
			AddPolicy(policy)
		end
	end

	-- A government only a player names gets a hash and the default influence.
	for _, row in pairs(env.GameInfo.Governments) do
		if row.Hash == nil then
			row.Hash = ctx.NextHash(4000000, row.GovernmentType)
			row.BonusType = "NO_GOVERNMENTBONUS"
			row.InfluencePointsPerTurn, row.InfluencePointsThreshold, row.InfluenceTokensPerThreshold = 1, 100, 1
		end
	end

	-- Gathering Storm's rows, with each government's favor.
	env.GameInfo.Governments_XP2 = world.expansion2 and governmentsXP2 or nil

	ctx.OnPlayer(function(player, data)
		local governmentData = data.government or {}

		-- Each policy by its hash.
		local policiesByHash = {}

		for _, policy in ipairs(data.policies or {}) do
			policiesByHash[hashes[policy.type]] = policy
		end

		local GetCulture = player.GetCulture

		function player.GetCulture()
			local culture = GetCulture()

			culture.GetCurrentGovernment = function()
				return governmentData.type and indexes[governmentData.type] or -1
			end

			culture.GetNumPolicySlots = function()
				return #(governmentData.slots or {})
			end

			culture.GetSlotType = function(_, i)
				return indexes[governmentData.slots[i + 1].type]
			end

			culture.GetSlotPolicy = function(_, i)
				local policy = governmentData.slots[i + 1].policy

				return policy and indexes[policy] or -1
			end

			culture.CivicCompletedThisTurn = function()
				return governmentData.civicThisTurn ~= nil
			end

			culture.CanChangeGovernmentAtAll = function()
				return governmentData.canChangeAtAll == true
			end

			culture.GovernmentChangeMade = function()
				return governmentData.governmentChangeMade == true
			end

			-- The player's current government is always unlocked.
			culture.IsGovernmentUnlocked = function(_, hash)
				for _, typeName in ipairs(governmentData.unlocked or {}) do
					if hashes[typeName] == hash then
						return true
					end
				end

				return governmentData.type ~= nil and hashes[governmentData.type] == hash
			end

			culture.GetAnarchyTurns = function(_, index)
				return (governmentData.anarchy or {})[env.GameInfo.Governments[index].GovernmentType] or 0
			end

			culture.GetCivicCompletedThisTurn = function()
				return governmentData.civicThisTurn and indexes[governmentData.civicThisTurn] or -1
			end

			culture.GetNumPolicySlotsOpen = function()
				return governmentData.slotsOpen or 0
			end

			culture.PolicyChangeMade = function()
				return governmentData.changeMade == true
			end

			culture.GetCostToUnlockPolicies = function()
				return governmentData.unlockCost or 0
			end

			culture.IsPolicyUnlocked = function(_, hash)
				return policiesByHash[hash] ~= nil and policiesByHash[hash].locked ~= true
			end

			culture.IsPolicyObsolete = function(_, hash)
				return policiesByHash[hash] ~= nil and policiesByHash[hash].obsolete == true
			end

			culture.IsPolicyBanned = function(_, hash)
				return policiesByHash[hash] ~= nil and policiesByHash[hash].banned == true
			end

			-- In Gathering Storm, a locked policy can't be slotted either.
			culture.CanPolicyBeSlotted = function(_, hash)
				local policy = policiesByHash[hash]

				return policy ~= nil and policy.locked ~= true and policy.unslottable ~= true
			end

			culture.IsPolicyActive = function(_, hash)
				for _, slot in ipairs(governmentData.slots or {}) do
					if slot.policy ~= nil and hashes[slot.policy] == hash then
						return true
					end
				end

				return false
			end

			return culture
		end
	end)
end

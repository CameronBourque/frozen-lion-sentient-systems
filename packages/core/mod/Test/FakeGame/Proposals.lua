-- Deals that other players put to a player. Fakes a player's proposals, the
-- items of each, and the answers to them, which go in env.requests.

local AGREEMENTS = {
	ALLIANCE = 1764885355,
	JOINT_WAR = 594401930,
	MAKE_PEACE = 547027585,
	OPEN_BORDERS = -242352742,
	RESEARCH_AGREEMENT = 1618981909,
	THIRD_PARTY_WAR = -1258934878,
}

local TYPES = { "AGREEMENTS", "CITIES", "GREATWORK", "CAPTIVE", "UNITS", "TECHNOLOGY", "FAVOR" }

return function(env, world, ctx)
	local indexes = ctx.indexes

	for i, name in ipairs(TYPES) do
		env.DealItemTypes[name] = 2 + i
	end

	env.DealAgreementTypes = AGREEMENTS
	env.DealDirection = { INCOMING = 1, OUTGOING = 0 }
	env.GameInfo.DiplomaticActions = {}
	env.GameInfo.Wars = ctx.TypedRows({}, "WarType")

	for name, hash in pairs(AGREEMENTS) do
		env.GameInfo.DiplomaticActions[hash] = { DiplomaticActionType = "DIPLOACTION_" .. name }
	end

	-- The rows that the items' values name, in the tables that hold them.
	local TABLES = {
		RESOURCES = { "Resources", "ResourceType" },
		TECHNOLOGY = { "Technologies", "TechnologyType" },
		GREATWORK = { "GreatWorks", "GreatWorkType" },
	}

	for _, data in pairs(world.players or {}) do
		for _, proposal in pairs(data.proposals or {}) do
			for _, item in ipairs(proposal.items or {}) do
				local row = TABLES[item.type]

				if row and type(item.value) == "string" then
					ctx.AddRow(row[1], row[2], item.value)
				end

				if item.sub == "RESEARCH_AGREEMENT" then
					ctx.AddRow("Technologies", "TechnologyType", item.value)
				end

				if item.sub == "ALLIANCE" then
					ctx.AddRow("Alliances", "AllianceType", item.value)
				end

				if item.war then
					ctx.AddRow("Wars", "WarType", item.war)
				end
			end
		end
	end

	local function Value(item)
		return type(item.value) == "string" and indexes[item.value] or item.value or -1
	end

	local function Item(data)
		local item = {}

		function item.GetID()
			return data.id
		end
		function item.GetType()
			return env.DealItemTypes[data.type]
		end
		function item.GetSubType()
			return AGREEMENTS[data.sub] or data.sub or 0
		end
		function item.GetFromPlayerID()
			return data.from
		end
		function item.GetAmount()
			return data.amount or 0
		end
		function item.GetDuration()
			return data.duration or 0
		end
		function item.GetValueType()
			return Value(data)
		end
		function item.GetValueTypeNameID()
			return data.name
		end
		function item.GetParameterValue()
			return data.war and indexes[data.war] or -1
		end
		function item.IsUnacceptable()
			return data.unacceptable == true
		end
		function item.IsLocked()
			return data.locked == true
		end

		return item
	end

	local function Deal(proposal)
		local items, byID, deal = {}, {}, {}

		for i, data in ipairs(proposal.items or {}) do
			items[i] = Item(data)
			byID[data.id] = items[i]
		end

		function deal.Items()
			local i = 0

			return function()
				i = i + 1

				return items[i]
			end
		end
		function deal.GetItemCount()
			return #items
		end
		function deal.GetItemParent(_, item)
			for i, data in ipairs(proposal.items) do
				if items[i] == item then
					return byID[data.parent]
				end
			end
		end
		function deal.IsGift()
			return proposal.gift == true
		end
		function deal.IsValid()
			return proposal.valid ~= false
		end
		function deal.Validate() end

		return deal
	end

	function env.DealManager.GetWorkingDeal(_, playerID, otherID)
		return Deal((world.players[playerID].proposals or {})[otherID] or {})
	end

	env.DealProposalAction = { ACCEPTED = 1, REJECTED = 2 }

	function env.DealManager.CopyIncomingToOutgoingWorkingDeal(playerID, otherID)
		env.requests[#env.requests + 1] = { copy = { playerID, otherID } }
	end

	function env.DealManager.SendWorkingDeal(action, playerID, otherID)
		env.requests[#env.requests + 1] = { send = { action, playerID, otherID } }
	end

	local sessions = {}

	env.DiplomacyManager = {
		FindOpenSessionID = function(playerID, otherID)
			local proposal = (world.players[playerID].proposals or {})[otherID]

			if proposal == nil then
				return -1
			end

			sessions[#sessions + 1] = { ToPlayer = playerID, FromPlayer = proposal.started == false and playerID or otherID }

			return #sessions
		end,
		GetSessionInfo = function(sessionID)
			return sessions[sessionID]
		end,
		AddResponse = function(sessionID, playerID, response)
			env.requests[#env.requests + 1] = { response = { sessionID, playerID, response } }
		end,
		CloseSession = function(sessionID)
			env.requests[#env.requests + 1] = { close = sessionID }
		end,
	}
end

-- The proposals section: the deals other players have put to the player.
-- Follows DiplomacyDealView.lua.
-- Shape: bridge/src/state/proposals.ts.

SentientSystems_Include("SentientSystemsCore_Sessions")

-- The deal item types, by the name of each in DealItemTypes.
local KINDS = {
	GOLD = "gold",
	RESOURCES = "resource",
	AGREEMENTS = "agreement",
	CITIES = "city",
	GREATWORK = "greatWork",
	CAPTIVE = "captive",
	UNITS = "unit",
	TECHNOLOGY = "technology",
	FAVOR = "favor",
}

-- The sub type of a city that is ceded back after an occupation.
local CEDE_OCCUPIED = 1

-- The deal items that the screen names with the game's own text.
local NAMED = { city = true, greatWork = true, captive = true, unit = true, technology = true }

-- Returns the kind of a deal item from its type in DealItemTypes, or nil for a
-- type that isn't in KINDS.
local function GetItemKind(itemType)
	for name, kind in pairs(KINDS) do
		if DealItemTypes[name] == itemType then
			return kind
		end
	end
end

-- Returns an agreement's details. The value is a tech for a research
-- agreement, an alliance type, or the player a war is against.
local function AddAgreement(entry, item)
	local action = GameInfo.DiplomaticActions[item:GetSubType()]
	local value = item:GetValueType()

	entry.agreement = action and action.DiplomaticActionType
	entry.turns = item:GetDuration()

	if item:GetSubType() == DealAgreementTypes.RESEARCH_AGREEMENT then
		entry.tech = GameInfo.Technologies[value].TechnologyType
	elseif item:GetSubType() == DealAgreementTypes.ALLIANCE then
		entry.allianceType = GameInfo.Alliances[value].AllianceType
	elseif item:GetSubType() == DealAgreementTypes.JOINT_WAR
		or item:GetSubType() == DealAgreementTypes.THIRD_PARTY_WAR then
		entry.target = value

		local war = GameInfo.Wars[item:GetParameterValue("WarType")]

		entry.war = war and war.WarType
	end
end

local function GetItem(item, deal)
	local kind = GetItemKind(item:GetType())
	local parent = deal:GetItemParent(item)
	local value = item:GetValueType()
	local entry = {
		id = item:GetID(),
		kind = kind,
		with = parent and parent:GetID(),
		unacceptable = item:IsUnacceptable() or nil,
		locked = item:IsLocked() or nil,
	}

	-- A captive can have no name, and the deal screen then shows none, as
	-- PopulateDealCaptives in DiplomacyDealView.lua does.
	local nameID = item:GetValueTypeNameID()

	if NAMED[kind] and nameID ~= nil then
		entry.name = Locale.Lookup(nameID)
	end

	if kind == "gold" or kind == "favor" or kind == "resource" then
		entry.amount = item:GetAmount()
		entry.turns = item:GetDuration() > 0 and item:GetDuration() or nil
	end

	if kind == "resource" then
		entry.resource = GameInfo.Resources[value].ResourceType
	elseif kind == "agreement" then
		AddAgreement(entry, item)
	elseif kind == "city" then
		entry.city = { owner = item:GetFromPlayerID(), id = value }
		entry.cedeOccupied = item:GetSubType() == CEDE_OCCUPIED or nil
	elseif kind == "greatWork" then
		-- The value is the work's index in the game, not its row, and the
		-- sub type is 0. The deal screen names the icon from the type ID, in
		-- PopulateDealGreatWorks.
		entry.greatWork = item:GetValueTypeID()
	end

	return entry
end

local function GetItems(deal, playerID)
	local asks, offers = {}, {}

	for item in deal:Items() do
		local list = item:GetFromPlayerID() == playerID and asks or offers

		list[#list + 1] = GetItem(item, deal)
	end

	return asks, offers
end

-- Returns whether the core mod saw the session's statement, and it isn't a
-- deal. The incoming deal can keep the items of an old one, such as a peace
-- deal, while the session holds a promise.
local function IsOtherStatement(playerID, otherID)
	local statement = SentientSystems_GetOpenStatement(playerID, otherID)

	return statement ~= nil
		and not SentientSystems_IsDealStatement(DiplomacyManager.GetKeyName(statement.StatementType))
end

-- Returns the deal the other player has put to the player, and its session,
-- or nil. A deal is put to the player when the other player started an open
-- session and the incoming deal has items.
function SentientSystems_GetProposedDeal(playerID, otherID)
	local sessionID = DiplomacyManager.FindOpenSessionID(playerID, otherID)
	local deal = DealManager.GetWorkingDeal(DealDirection.INCOMING, playerID, otherID)

	if otherID ~= playerID and sessionID and sessionID ~= -1
		and DiplomacyManager.GetSessionInfo(sessionID).FromPlayer == otherID
		and deal ~= nil and deal:GetItemCount() > 0
		and not IsOtherStatement(playerID, otherID) then
		return deal, sessionID
	end

	return nil
end

-- Returns the deals put to the player, one for each other player, in ID order.
function SentientSystems_GetProposalState(player)
	local playerID = player:GetID()
	local list = {}

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local otherID = other:GetID()
		local deal = SentientSystems_GetProposedDeal(playerID, otherID)

		if deal ~= nil then
			local asks, offers = GetItems(deal, playerID)

			deal:Validate()
			list[#list + 1] = {
				from = otherID,
				gift = deal:IsGift(),
				valid = deal:IsValid(),
				asks = asks,
				offers = offers,
			}
		end
	end

	return list
end

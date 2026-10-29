-- The diplomacy section of the state: where the player stands with each
-- player they have met. Format: docs/design/core/in-game-lua.md. The checks
-- follow the Intel Report in DiplomacyActionView.lua.

-- The alliance level at which the screen shows MAX in place of points.
local MAX_ALLIANCE_LEVEL = 3

-- The game counts alliance points in a multiple, which the screen divides.
local function ToPoints(amount)
	return amount / GlobalParameters.ALLIANCE_POINTS_MULTIPLIER
end

-- The screen counts from the later denounce turn, and adds a turn when the
-- tie or the order of the players says so.
local function GetDenounceTurnsLeft(playerID, otherID)
	local ours = Players[playerID]:GetDiplomacy():GetDenounceTurn(otherID)
	local theirs = Players[otherID]:GetDiplomacy():GetDenounceTurn(playerID)
	local firstIsOther = theirs >= ours
	local adjustment = ((firstIsOther and otherID > playerID) or (not firstIsOther and playerID > otherID)) and 1 or 0
	local limit = Game.GetGameDiplomacy():GetDenounceTimeLimit()

	return 1 + math.max(ours, theirs) + limit - Game.GetCurrentGameTurn() + adjustment
end

-- Turns until a declared friendship or a denouncement ends, or nil for
-- other states.
local function GetTurnsLeft(playerID, otherID, stateType)
	if stateType == "DIPLO_STATE_DENOUNCED" then
		return GetDenounceTurnsLeft(playerID, otherID)
	elseif stateType == "DIPLO_STATE_DECLARED_FRIEND" then
		local turn = Players[playerID]:GetDiplomacy():GetDeclaredFriendshipTurn(otherID)
		local limit = Game.GetGameDiplomacy():GetDenounceTimeLimit()

		return turn + limit - Game.GetCurrentGameTurn()
	end

	return nil
end

-- Returns the government type, or the turns of anarchy that are left.
local function GetGovernment(other)
	local culture = other:GetCulture()
	local index = culture:GetCurrentGovernment()

	if index ~= -1 then
		return GameInfo.Governments[index].GovernmentType, nil
	elseif culture:IsInAnarchy() then
		return nil, culture:GetAnarchyEndTurn() - Game.GetCurrentGameTurn()
	end

	return nil, nil
end

-- Returns the agreements between the two players, from each side.
local function GetAgreements(playerID, otherID)
	local mine = Players[playerID]:GetDiplomacy()
	local theirs = Players[otherID]:GetDiplomacy()
	local research = mine:GetResearchAgreementTech(otherID)

	return {
		delegation = { mine = mine:HasDelegationAt(otherID), theirs = theirs:HasDelegationAt(playerID) },
		embassy = { mine = mine:HasEmbassyAt(otherID), theirs = theirs:HasEmbassyAt(playerID) },
		openBorders = { received = mine:HasOpenBordersFrom(otherID), given = theirs:HasOpenBordersFrom(playerID) },
		defensivePact = mine:HasDefensivePact(otherID),
		researchAgreement = research ~= -1 and GameInfo.Technologies[research].TechnologyType or nil,
		jointWar = mine:IsFightingAnyJointWarWith(otherID),
	}
end

-- Returns the alliance level and points, with the alliance's type and its
-- pace and end while there is one. Needs Rise and Fall.
local function GetAlliance(playerID, otherID)
	local diplomacy = Players[playerID]:GetDiplomacy()

	if diplomacy.GetAllianceLevel == nil then
		return nil
	end

	local level = diplomacy:GetAllianceLevel(otherID)
	local alliance = { level = level }
	local type = diplomacy:GetAllianceType(otherID)

	if level >= MAX_ALLIANCE_LEVEL then
		alliance.max = true
	else
		alliance.points = ToPoints(diplomacy:GetAllianceTurnsThisLevel(otherID))
		alliance.pointsNeeded = ToPoints(diplomacy:GetAllianceTurnsToNextLevel(otherID))
	end

	if type ~= -1 then
		alliance.type = GameInfo.Alliances[type].AllianceType
		alliance.pointsPerTurn = ToPoints(diplomacy:GetAlliancePointsPerTurn(otherID))
		alliance.turnsUntilExpiration = diplomacy:GetAllianceTurnsUntilExpiration(otherID)
	end

	return alliance
end

-- The text key that the screen greys out for a reason it can't explain.
local UNKNOWN_REASON_KEY = "LOC_TOOLTIP_DIPLOMACY_UNKNOWN_REASON"

-- The first diplomatic state that is not between two major players.
local FIRST_MINOR_STATE = 7

-- Returns why the other player feels as they do, best reason first, as
-- the Relationship tab lists them.
local function GetReasons(other, playerID)
	local unknownText = Locale.Lookup(UNKNOWN_REASON_KEY)
	local reasons = {}

	for _, modifier in ipairs(other:GetDiplomaticAI():GetDiplomaticModifiers(playerID) or {}) do
		if modifier.Score ~= 0 then
			local unknown = modifier.Text == UNKNOWN_REASON_KEY or modifier.Text == unknownText

			reasons[#reasons + 1] = {
				score = modifier.Score,
				text = not unknown and Locale.Lookup(modifier.Text) or nil,
				unknown = unknown or nil,
			}
		end
	end

	table.sort(reasons, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end

		return (a.text or "") < (b.text or "")
	end)

	return reasons
end

-- Returns whether the access level lets the player see random agendas.
local function CanSeeRandomAgendas(level)
	for row in GameInfo.Visibilities() do
		if row.Index <= level and row.RevealAgendas then
			return true
		end
	end

	return false
end

-- Returns the other player's agendas. The first is the historical agenda,
-- which always shows. The random ones show with enough access, and
-- otherwise only their number does.
local function GetAgendas(other, level)
	local types = other:GetAgendaTypes()
	local visible = CanSeeRandomAgendas(level)
	local list = {}

	for i, agendaType in ipairs(types) do
		if i == 1 or visible then
			local row = GameInfo.Agendas[agendaType]

			list[#list + 1] = {
				type = row.AgendaType,
				name = Locale.Lookup(row.Name),
				description = Locale.Lookup(row.Description),
			}
		end
	end

	return { list = list, hidden = visible and 0 or math.max(#types - 1, 0) }
end

-- Returns the balance of grievances, positive when the player has them
-- against the other, the change each turn, and the log by turn. Needs
-- Gathering Storm.
local function GetGrievances(player, otherID)
	local diplomacy = player:GetDiplomacy()

	if diplomacy.GetGrievancesAgainst == nil then
		return nil
	end

	local game = Game.GetGameDiplomacy()
	local log = {}

	for _, entry in ipairs(game:GetGrievanceLogEntries(otherID, player:GetID())) do
		log[#log + 1] = {
			turn = entry.Turn,
			from = entry.Initiator,
			against = entry.Target,
			amount = entry.Amount,
			text = entry.Description,
		}
	end

	table.sort(log, function(a, b)
		return a.turn < b.turn
	end)

	return {
		balance = diplomacy:GetGrievancesAgainst(otherID),
		perTurn = game:GetGrievanceChangePerTurn(otherID, player:GetID()),
		log = log,
	}
end

-- Returns how each other player the other has met sees them, left out
-- when neutral, as the Relationships row of the Overview shows them.
local function GetOthers(other, playerID)
	local list = {}

	for _, third in ipairs(PlayerManager.GetAliveMajors()) do
		local thirdID = third:GetID()

		if thirdID ~= playerID and thirdID ~= other:GetID()
			and other:GetDiplomacy():HasMet(thirdID) then
			local index = third:GetDiplomaticAI():GetDiplomaticStateIndex(other:GetID())
			local stateType = GameInfo.DiplomaticStates[index].StateType

			if index < FIRST_MINOR_STATE and stateType ~= "DIPLO_STATE_NEUTRAL" then
				list[#list + 1] = { player = thirdID, state = stateType }
			end
		end
	end

	return list
end

-- Returns one met player's entry. The state, with the relationship and the
-- agendas, is how they see the player and is left out for a human.
local function GetEntry(player, other)
	local playerID, otherID = player:GetID(), other:GetID()
	local diplomacy = player:GetDiplomacy()
	local government, anarchyTurns = GetGovernment(other)
	local entry = {
		player = otherID,
		atWar = diplomacy:IsAtWarWith(otherID),
		access = { level = diplomacy:GetVisibilityOn(otherID) },
		government = government,
		anarchyTurns = anarchyTurns,
		agreements = GetAgreements(playerID, otherID),
		alliance = GetAlliance(playerID, otherID),
		grievances = GetGrievances(player, otherID),
		others = GetOthers(other, playerID),
	}

	if #entry.others == 0 then
		entry.others = nil
	end

	entry.access.name = Locale.Lookup(GameInfo.Visibilities[entry.access.level].Name)

	if not PlayerConfigurations[otherID]:IsHuman() then
		local index = other:GetDiplomaticAI():GetDiplomaticStateIndex(playerID)
		local stateType = GameInfo.DiplomaticStates[index].StateType

		entry.state = stateType
		entry.turnsLeft = GetTurnsLeft(playerID, otherID, stateType)
		entry.relationship = { reasons = GetReasons(other, playerID) }
		entry.agendas = GetAgendas(other, entry.access.level)
	end

	return entry
end

-- Returns the players the player has met, in ID order.
function SentientSystems_GetDiplomacyState(player)
	local list = {}

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		if other:GetID() ~= player:GetID() and player:GetDiplomacy():HasMet(other:GetID()) then
			list[#list + 1] = GetEntry(player, other)
		end
	end

	return list
end

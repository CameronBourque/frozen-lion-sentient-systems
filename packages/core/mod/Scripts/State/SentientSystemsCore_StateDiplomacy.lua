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

-- Returns one met player's entry. The state is how they see the player, as
-- the screen's Our Relationship row has it, and is left out for a human.
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
	}

	entry.access.name = Locale.Lookup(GameInfo.Visibilities[entry.access.level].Name)

	if not PlayerConfigurations[otherID]:IsHuman() then
		local index = other:GetDiplomaticAI():GetDiplomaticStateIndex(playerID)
		local stateType = GameInfo.DiplomaticStates[index].StateType

		entry.state = stateType
		entry.turnsLeft = GetTurnsLeft(playerID, otherID, stateType)
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

-- The actions on the Great People screen: recruit, pass, and patronize.
-- SentientSystemsCore_Actions.lua loads this file. The calls are in
-- docs/findings/actions/great-people.md.

SentientSystems_Include("SentientSystemsCore_GreatPeople")

-- Recruit and pass, each with the capability that shows its button, the
-- game's check, and the request it sends. See AddRecruit in
-- GreatPeoplePopup.lua, OnRecruitButtonClick, and OnRejectButtonClick.
local CLAIMS = {
	recruit = {
		name = "recruit",
		capability = "CAPABILITY_GREAT_PEOPLE_CAN_RECRUIT",
		can = function(greatPeople, playerID, individual)
			return greatPeople:CanRecruitPerson(playerID, individual)
		end,
		operation = "RECRUIT_GREAT_PERSON",
	},
	pass = {
		name = "pass",
		capability = "CAPABILITY_GREAT_PEOPLE_CAN_REJECT",
		can = function(greatPeople, playerID, individual)
			return greatPeople:CanRejectPerson(playerID, individual)
		end,
		operation = "REJECT_GREAT_PERSON",
	},
}

-- Returns the timeline entry of the great person by type, or nil and the
-- reason. The timeline lists the great person on offer in each class. See
-- PopulateData in GreatPeoplePopup.lua.
local function FindOffer(greatPeople, typeName)
	local row = type(typeName) == "string" and GameInfo.GreatPersonIndividuals[typeName] or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a great person. Use a type from the great people state."
	end

	for _, entry in ipairs(greatPeople:GetTimeline()) do
		if entry.Individual == row.Index then
			return entry, nil
		end
	end

	return nil, typeName .. " isn't on offer. Use a type from the great people state."
end

-- Returns why the player can't claim the great person, as the screen's Cannot
-- Recruit text gives it, or nil. See GetEarnConditionsText.
local function GetCantEarnFailure(greatPeople, playerID, entry)
	local text = SentientSystems_CleanText(greatPeople:GetEarnConditionsText(playerID, entry.Individual))

	if text == nil then
		return nil
	end

	return "You can't claim " .. GameInfo.GreatPersonIndividuals[entry.Individual].GreatPersonIndividualType .. ". " .. text
end

-- Returns why the player can't recruit or pass the great person, or nil.
local function GetClaimFailure(claim, greatPeople, playerID, entry)
	if not GameCapabilities.HasCapability(claim.capability) then
		return "This game doesn't let players " .. claim.name .. " great people."
	end

	if claim.can(greatPeople, playerID, entry.Individual) then
		return nil
	end

	local typeName = GameInfo.GreatPersonIndividuals[entry.Individual].GreatPersonIndividualType
	local points = SentientSystems_GetPlayer(playerID):GetGreatPeoplePoints():GetPointsTotal(entry.Class)

	return GetCantEarnFailure(greatPeople, playerID, entry)
		or "You can't " .. claim.name .. " " .. typeName .. " yet. It costs " .. entry.Cost .. " points, and you have " .. math.floor(points) .. "."
end

local function ClaimGreatPerson(claimName, playerID, typeName)
	local claim = CLAIMS[claimName]
	local greatPeople = Game.GetGreatPeople()
	local entry, failure = FindOffer(greatPeople, typeName)

	if failure ~= nil then
		return failure
	end

	failure = GetClaimFailure(claim, greatPeople, playerID, entry)

	if failure ~= nil then
		return failure
	end

	UI.RequestPlayerOperation(playerID, PlayerOperations[claim.operation], { [PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = entry.Individual })

	return nil
end

-- Returns the patronage yield by its key, gold or faith, or nil and the reason.
local function FindPatronageYield(key)
	for _, entry in ipairs(SENTIENTSYSTEMS_PATRONAGE) do
		if entry.key == key then
			return entry, nil
		end
	end

	return nil, "Patronize with gold or faith, not " .. tostring(key) .. "."
end

-- Returns why the player can't patronize the great person with the yield, or
-- nil. The screen shows a patronage button only while the player can neither
-- recruit nor pass, and turns both off while the World Congress is in session.
local function GetPatronageFailure(greatPeople, playerID, entry, yield)
	local typeName = GameInfo.GreatPersonIndividuals[entry.Individual].GreatPersonIndividualType

	if greatPeople:CanRecruitPerson(playerID, entry.Individual) or greatPeople:CanRejectPerson(playerID, entry.Individual) then
		return "You have the points for " .. typeName .. ", so recruit or pass them instead."
	end

	local patronage = SentientSystems_GetPatronage(greatPeople, playerID, entry.Individual)
	local option = patronage and patronage[yield.key]

	if option == nil then
		return GetCantEarnFailure(greatPeople, playerID, entry) or "The game offers no patronage of " .. typeName .. " with " .. yield.key .. "."
	end

	if SentientSystems_IsPatronageClosed() then
		return "The World Congress is in session. Patronize after it ends."
	end

	if not option.can then
		return "You can't afford " .. typeName .. " with " .. yield.key .. ". It costs " .. option.cost .. "."
	end

	return nil
end

local function PatronizeGreatPerson(playerID, typeName, key)
	local greatPeople = Game.GetGreatPeople()
	local entry, failure = FindOffer(greatPeople, typeName)

	if failure ~= nil then
		return failure
	end

	local yield

	yield, failure = FindPatronageYield(key)

	if failure ~= nil then
		return failure
	end

	failure = GetPatronageFailure(greatPeople, playerID, entry, yield)

	if failure ~= nil then
		return failure
	end

	local parameters = {
		[PlayerOperations.PARAM_GREAT_PERSON_INDIVIDUAL_TYPE] = entry.Individual,
		[PlayerOperations.PARAM_YIELD_TYPE] = YieldTypes[yield.yield],
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations.PATRONIZE_GREAT_PERSON, parameters)

	return nil
end

-- Recruits the great person with the player's points and returns the result as
-- JSON. The great person is a type from the greatPeople choice, such as
-- GREAT_PERSON_INDIVIDUAL_ARYABHATA.
function SentientSystems_RecruitGreatPerson(playerID, greatPerson)
	return SentientSystems_RunAction("RecruitGreatPerson", ClaimGreatPerson, "recruit", playerID, greatPerson)
end

-- Passes on the great person, as RecruitGreatPerson takes them, and returns the
-- result as JSON.
function SentientSystems_PassGreatPerson(playerID, greatPerson)
	return SentientSystems_RunAction("PassGreatPerson", ClaimGreatPerson, "pass", playerID, greatPerson)
end

-- Recruits the great person with gold or faith, the yield, and returns the
-- result as JSON. The great person is a type from the great people state.
function SentientSystems_PatronizeGreatPerson(playerID, greatPerson, yield)
	return SentientSystems_RunAction("PatronizeGreatPerson", PatronizeGreatPerson, playerID, greatPerson, yield)
end

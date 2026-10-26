-- The great people section of the state: each great person on offer, with their era, cost, effects,
-- patronage costs, and each major player's progress toward them, as the Great People screen shows
-- them. SentientSystemsCore_State.lua loads this file. Example:
-- SentientSystems_GetGreatPeopleState(player) returns a table that encodes as
-- '[{"action":{"effect":"The Art of War ([ICON_GreatWork_Writing] Writing).","name":"Retire",
-- "usage":"Activate at a district or wonder with an available Great Work slot."},
-- "class":"GREAT_PERSON_CLASS_GENERAL","cost":30,"era":"ERA_CLASSICAL","name":"Sun Tzu",
-- "passive":"+5 [ICON_Strength] Combat Strength ...","patronage":{"faith":{"can":false,"cost":450},
-- "gold":{"can":false,"cost":650}},"progress":[{"perTurn":0,"player":0,"points":0},...],
-- "type":"GREAT_PERSON_INDIVIDUAL_SUN_TZU"},...]', on one line. The checks follow PopulateData and
-- AddRecruit in GreatPeoplePopup.lua.

-- The screen hides a patronage cost at or above this, which the game gives a great person the player
-- can't earn.
local MAX_PATRONAGE_COST = 1000000

-- The patronage yields, each with the capability the screen checks for its button.
local PATRONAGE = {
	{ key = "gold", yield = "GOLD", capability = "CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD" },
	{ key = "faith", yield = "FAITH", capability = "CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH" },
}

-- Rounds a number to the nearest tenth, as the screen's Round(x, 1) does.
local function RoundTenth(number)
	return math.floor(number * 10 + 0.5) / 10
end

-- Returns the patronage costs of a great person, gold and faith, each with cost and can, true when the
-- screen's button is on. The screen shows a button only while the player can neither recruit nor pass
-- the person, and turns it off while Gathering Storm's World Congress is in session. Returns nil when
-- it shows neither. See AddRecruit in GreatPeoplePopup.lua, lines 241 to 262, and IsReadOnly in
-- GreatPeoplePopup_Expansion2.lua.
local function GetPatronage(greatPeople, playerID, individual)
	if greatPeople:CanRecruitPerson(playerID, individual) or greatPeople:CanRejectPerson(playerID, individual) then
		return nil
	end

	local readOnly = SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession()
	local patronage

	for _, entry in ipairs(PATRONAGE) do
		local yield = YieldTypes[entry.yield]
		local cost = greatPeople:GetPatronizeCost(playerID, individual, yield)

		if GameCapabilities.HasCapability(entry.capability) and cost < MAX_PATRONAGE_COST then
			patronage = patronage or {}
			patronage[entry.key] = { cost = cost, can = greatPeople:CanPatronizePerson(playerID, individual, yield) and not readOnly }
		end
	end

	return patronage
end

-- Returns each major player's progress toward a class of great person: points and perTurn, each
-- rounded to the nearest tenth, and player, its ID, when it is the player or a player they have met,
-- or unmet, true for one they haven't met. The most points come first, then the lowest ID. See
-- PopulateData in GreatPeoplePopup.lua, lines 780 to 814, and AddRecruit, lines 296 to 321.
local function GetProgress(player, classIndex)
	local progress = {}

	for _, other in ipairs(Game.GetPlayers({ Major = true, Alive = true })) do
		local otherID = other:GetID()
		local points = other:GetGreatPeoplePoints()
		local known = otherID == player:GetID() or player:GetDiplomacy():HasMet(otherID)

		progress[#progress + 1] = {
			id = otherID,
			player = known and otherID or nil,
			unmet = (not known) or nil,
			points = RoundTenth(points:GetPointsTotal(classIndex)),
			perTurn = RoundTenth(points:GetPointsPerTurn(classIndex)),
		}
	end

	table.sort(progress, function(a, b)
		if a.points ~= b.points then
			return a.points > b.points
		end

		return a.id < b.id
	end)

	for _, entry in ipairs(progress) do
		entry.id = nil
	end

	return progress
end

-- Returns one great person on offer: class, type, name, era, cost, the points to recruit them,
-- passive, the passive effect, action, the action's name, usage, effect, and charges, above 0 only,
-- patronage, cantEarn, the reason the player can't earn them, and progress. See PopulateData in
-- GreatPeoplePopup.lua, lines 708 to 777, and AddRecruit, lines 153 to 330.
local function GetGreatPerson(player, greatPeople, entry)
	local playerID = player:GetID()
	local individual = GameInfo.GreatPersonIndividuals[entry.Individual]
	local cantEarn = greatPeople:GetEarnConditionsText(playerID, entry.Individual)
	local person = {
		class = GameInfo.GreatPersonClasses[entry.Class].GreatPersonClassType,
		type = individual.GreatPersonIndividualType,
		name = Locale.Lookup(individual.Name),
		era = GameInfo.Eras[entry.Era].EraType,
		cost = entry.Cost,
		patronage = GetPatronage(greatPeople, playerID, entry.Individual),
		cantEarn = cantEarn ~= "" and cantEarn or nil,
		progress = GetProgress(player, entry.Class),
	}

	if entry.PassiveNameText ~= nil and entry.PassiveNameText ~= "" then
		person.passive = entry.PassiveEffectText
	end

	if entry.ActionNameText ~= nil and entry.ActionNameText ~= "" then
		person.action = {
			name = entry.ActionNameText,
			usage = entry.ActionUsageText,
			effect = entry.ActionEffectText,
			charges = individual.ActionCharges > 0 and individual.ActionCharges or nil,
		}
	end

	return person
end

-- Returns the great people on offer, in the screen's order. A class whose great person someone has
-- claimed, which the screen shows as claimed, is left out. See PopulateData in GreatPeoplePopup.lua,
-- lines 682 to 778.
function SentientSystems_GetGreatPeopleState(player)
	local greatPeople = Game.GetGreatPeople()
	local list = {}

	for _, entry in ipairs(greatPeople:GetTimeline()) do
		if entry.Individual ~= nil then
			list[#list + 1] = GetGreatPerson(player, greatPeople, entry)
		end
	end

	return list
end

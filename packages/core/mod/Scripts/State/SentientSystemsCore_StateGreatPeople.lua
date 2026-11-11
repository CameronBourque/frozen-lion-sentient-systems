-- The great people section, as the Great People screen shows it. Follows
-- PopulateData and AddRecruit in GreatPeoplePopup.lua.
-- Shape: bridge/src/state/great-people.ts.

SentientSystems_Include("SentientSystemsCore_GreatPeople")

-- Returns each major player's progress toward a class of great person. The most
-- points come first, then the lowest ID. See PopulateData in
-- GreatPeoplePopup.lua, and AddRecruit.
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
			points = SentientSystems_Round(points:GetPointsTotal(classIndex), 1),
			perTurn = SentientSystems_Round(points:GetPointsPerTurn(classIndex), 1),
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

-- Returns one great person on offer. See PopulateData in GreatPeoplePopup.lua,
-- and AddRecruit.
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
		patronage = SentientSystems_GetPatronage(greatPeople, playerID, entry.Individual),
		cantEarn = SentientSystems_CleanText(cantEarn),
		progress = GetProgress(player, entry.Class),
	}

	if entry.PassiveNameText ~= nil and entry.PassiveNameText ~= "" then
		person.passive = SentientSystems_CleanText(entry.PassiveEffectText)
	end

	if entry.ActionNameText ~= nil and entry.ActionNameText ~= "" then
		person.action = {
			name = SentientSystems_CleanText(entry.ActionNameText),
			usage = SentientSystems_CleanText(entry.ActionUsageText),
			effect = SentientSystems_CleanText(entry.ActionEffectText),
			charges = individual.ActionCharges > 0 and individual.ActionCharges or nil,
		}
	end

	return person
end

-- Returns the great people on offer, in the screen's order. A class whose great
-- person someone has claimed, which the screen shows as claimed, is left out.
-- See PopulateData in GreatPeoplePopup.lua.
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

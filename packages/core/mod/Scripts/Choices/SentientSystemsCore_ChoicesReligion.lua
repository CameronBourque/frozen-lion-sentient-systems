-- The religion choices: the pantheon beliefs the player can found a pantheon with, as the pantheon
-- chooser lists them, and the religions and beliefs the player can found a religion with or add to
-- it, as the religion screen lists them. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetPantheonChoices(player) returns a table that encodes as
-- '{"beliefs":[{"description":"Holy Site districts get +1 [ICON_Faith] Faith from adjacent Tundra
-- tiles.","type":"BELIEF_DANCE_OF_THE_AURORA"},...]}', on one line, and
-- SentientSystems_GetReligionChoices(player) one that encodes as '{"beliefs":[{"class":
-- "BELIEF_CLASS_WORSHIP","description":"Allows construction of Gurdwaras.","type":"BELIEF_GURDWARA"},
-- ...],"picks":2,"religions":[{"type":"RELIGION_BUDDHISM"},...]}'. The checks follow
-- PantheonChooser.lua and ReligionScreen.lua.

-- Returns the pantheon choice, with beliefs, the pantheon beliefs no player has taken, in the
-- game's order, each with its type and description. Returns nil unless the player can found a
-- pantheon now, as the launch bar opens the chooser only then. See Realize and CanSelectBelief in
-- PantheonChooser.lua, lines 23 to 72, and LaunchBar.lua, lines 136 to 140.
function SentientSystems_GetPantheonChoices(player)
	local religion = player:GetReligion()

	if religion:GetPantheon() >= 0 or not religion:CanCreatePantheon() then
		return nil
	end

	local gameReligion = Game.GetReligion()
	local beliefs = {}

	for row in GameInfo.Beliefs() do
		if row.BeliefClassType == "BELIEF_CLASS_PANTHEON"
			and not gameReligion:IsInSomePantheon(row.Index)
			and not gameReligion:IsInSomeReligion(row.Index)
		then
			beliefs[#beliefs + 1] = { type = row.BeliefType, description = Locale.Lookup(row.Description) }
		end
	end

	return { beliefs = beliefs }
end

-- Returns the beliefs the founder of a religion has added to it, or none before they found one.
local function CountBeliefs(playerID)
	for _, entry in ipairs(Game.GetReligion():GetReligions()) do
		if entry.Founder == playerID then
			return #entry.Beliefs
		end
	end

	return 0
end

-- Returns the religions that no player has founded, in the game's order, each with its type, and
-- customName, true for one the player must name. See ChooseReligion in ReligionScreen.lua, lines
-- 604 to 688.
local function GetReligionOptions()
	local gameReligion = Game.GetReligion()
	local canRename = GameCapabilities.HasCapability("CAPABILITY_RENAME")
	local religions = {}

	for row in GameInfo.Religions() do
		if not row.Pantheon and not gameReligion:HasBeenFounded(row.Index) then
			religions[#religions + 1] = { type = row.ReligionType, customName = (row.RequiresCustomName and canRename) or nil }
		end
	end

	return religions
end

-- Returns the beliefs the screen offers for the player's religion: those that aren't pantheon
-- beliefs, that no player has taken, and of which the religion doesn't have too many, each with
-- its type, class, and description, ordered by class as the screen orders them. See
-- PopulateAvailableBeliefs in ReligionScreen.lua, lines 446 to 486.
local function GetBeliefOptions(religionType)
	local gameReligion = Game.GetReligion()
	local rows = {}

	for row in GameInfo.Beliefs() do
		if row.BeliefClassType ~= "BELIEF_CLASS_PANTHEON"
			and not gameReligion:IsInSomePantheon(row.Index)
			and not gameReligion:IsInSomeReligion(row.Index)
			and not gameReligion:IsTooManyForReligion(row.Index, religionType)
		then
			rows[#rows + 1] = row
		end
	end

	-- The screen sorts by class, from the last name to the first, and keeps no order within a class,
	-- so the game's order breaks ties.
	table.sort(rows, function(a, b)
		if a.BeliefClassType ~= b.BeliefClassType then
			return a.BeliefClassType > b.BeliefClassType
		end

		return a.Index < b.Index
	end)

	local beliefs = {}

	for i, row in ipairs(rows) do
		beliefs[i] = { type = row.BeliefType, class = row.BeliefClassType, description = Locale.Lookup(row.Description) }
	end

	return beliefs
end

-- Returns the religion choice: religions, the religions the player can found, there only before
-- they found one, picks, the beliefs they choose now, and beliefs, the beliefs on offer. In one
-- round the player picks at most one belief of each class, and the first belief of a new religion
-- is a follower belief. Returns nil unless the screen offers a religion or beliefs: after the
-- pantheon, with more beliefs earned than the religion has. See ViewMyReligion in ReligionScreen.lua,
-- lines 308 to 336, and OnBeliefSelected, lines 488 to 500.
function SentientSystems_GetReligionChoices(player)
	local religion = player:GetReligion()
	local picks = religion:GetNumBeliefsEarned() - CountBeliefs(player:GetID())
	local religionType = religion:GetReligionTypeCreated()

	if religion:GetPantheon() < 0 or picks <= 0 then
		return nil
	end

	return {
		religions = religionType < 0 and GetReligionOptions() or nil,
		picks = picks,
		beliefs = GetBeliefOptions(religionType),
	}
end

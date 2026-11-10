-- The pantheon and religion actions. SentientSystemsCore_Actions.lua loads
-- this file. The calls are in docs/findings/actions/religion.md.

SentientSystems_Include("SentientSystemsCore_Religion")

-- Returns why the player can't found a pantheon now, or nil. The launch bar
-- opens the pantheon chooser only for a player with no pantheon who can create
-- one. See LaunchBar.lua.
local function GetPantheonFailure(religion)
	local pantheon = religion:GetPantheon()

	if pantheon >= 0 then
		return "You have a pantheon already, " .. GameInfo.Beliefs[pantheon].BeliefType .. "."
	end

	if not religion:CanCreatePantheon() then
		return "You can't found a pantheon yet. The choices list a pantheon once you can."
	end

	return nil
end

-- Returns the row of the belief by its type, or nil and the reason. choice
-- names the choice that lists the beliefs to pick from.
local function FindBeliefRow(typeName, choice)
	local row = type(typeName) == "string" and GameInfo.Beliefs[typeName] or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a belief. Use a type from the " .. choice .. " choice."
	end

	return row, nil
end

-- Returns why another player's pantheon or religion holds the belief, or nil.
-- choice names the choice that lists the beliefs to pick from.
local function GetTakenBeliefFailure(row, choice)
	if SentientSystems_IsBeliefTaken(Game.GetReligion(), row.Index) then
		return "Another player has " .. row.BeliefType .. " already. Use a type from the " .. choice .. " choice."
	end

	return nil
end

-- Returns why the belief can't be the player's pantheon, or nil. See
-- CanSelectBelief in PantheonChooser.lua.
local function GetPantheonBeliefFailure(row)
	if row.BeliefClassType ~= "BELIEF_CLASS_PANTHEON" then
		return row.BeliefType .. " isn't a pantheon belief. Use a type from the pantheon choice."
	end

	return GetTakenBeliefFailure(row, "pantheon")
end

-- Sends the request the pantheon chooser sends. See ConfirmPantheon in
-- PantheonChooser.lua.
local function RequestPantheon(playerID, row)
	local parameters = {
		[PlayerOperations.PARAM_BELIEF_TYPE] = row.Hash,
		[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE,
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations.FOUND_PANTHEON, parameters)
end

local function FoundPantheon(playerID, typeName)
	local failure = GetPantheonFailure(SentientSystems_GetPlayer(playerID):GetReligion())

	if failure ~= nil then
		return failure
	end

	local row

	row, failure = FindBeliefRow(typeName, "pantheon")

	if failure ~= nil then
		return failure
	end

	failure = GetPantheonBeliefFailure(row)

	if failure ~= nil then
		return failure
	end

	RequestPantheon(playerID, row)

	return nil
end

-- Returns why the player can't found a religion now, or nil. The religion
-- screen offers a religion after the pantheon, once a Great Prophet has earned
-- its beliefs, until the player founds one. See ViewMyReligion in
-- ReligionScreen.lua.
local function GetFoundReligionFailure(player)
	local religion = player:GetReligion()
	local created = religion:GetReligionTypeCreated()

	if created >= 0 then
		return "You have founded " .. GameInfo.Religions[created].ReligionType .. " already."
	end

	if religion:GetPantheon() < 0 then
		return "Found a pantheon first. A religion needs one."
	end

	if SentientSystems_GetBeliefPicks(player) > 0 then
		return nil
	end

	if religion:HasReligiousFoundingUnit() then
		return "Activate your Great Prophet on a Holy Site first, with the found_religion order."
	end

	return "You need a Great Prophet to found a religion."
end

-- Returns the row of a religion that no player has founded, by its type, or nil
-- and the reason. See ChooseReligion in ReligionScreen.lua.
local function FindOpenReligionRow(typeName)
	local row = type(typeName) == "string" and GameInfo.Religions[typeName] or nil

	if row == nil or row.Pantheon then
		return nil, tostring(typeName) .. " isn't a religion. Use a type from the religion choice."
	end

	if Game.GetReligion():HasBeenFounded(row.Index) then
		return nil, "Another player has founded " .. typeName .. " already. Use a type from the religion choice."
	end

	return row, nil
end

-- Returns the name the screen sends for the religion, or nil for none, and the
-- reason it can't. A religion with RequiresCustomName takes the player's name
-- when the game allows renaming, and its own name otherwise. The screen takes
-- no name that is empty or only spaces. See ChooseReligion and
-- IsReligionNameValid in ReligionScreen.lua.
local function GetReligionName(row, name)
	if not row.RequiresCustomName then
		return nil, name ~= nil and row.ReligionType .. " has a fixed name. Leave out the name." or nil
	end

	if not GameCapabilities.HasCapability("CAPABILITY_RENAME") then
		return Locale.Lookup(row.Name), nil
	end

	if type(name) ~= "string" or name:find("[^ ]") == nil then
		return nil, row.ReligionType .. " needs a name. Give one."
	end

	return name, nil
end

-- Returns why a religion of the type can't take the belief, or nil. The
-- religion type is -1 before the player founds one. See
-- PopulateAvailableBeliefs in ReligionScreen.lua.
local function GetReligionBeliefFailure(row, religionType)
	if row.BeliefClassType == "BELIEF_CLASS_PANTHEON" then
		return row.BeliefType .. " is a pantheon belief. Use a type from the religion choice."
	end

	if Game.GetReligion():IsTooManyForReligion(row.Index, religionType) then
		return "Your religion can't take another " .. row.BeliefClassType .. " belief."
	end

	return GetTakenBeliefFailure(row, "religion")
end

-- Returns the rows of the beliefs that found a new religion, or nil and the
-- reason. The screen asks for every belief earned: a follower belief first,
-- then at most one belief of each other class. See SelectReligionBeliefs,
-- PopulateAvailableBeliefs, and OnBeliefSelected in ReligionScreen.lua.
local function FindFoundingBeliefs(player, beliefs)
	local picks = SentientSystems_GetBeliefPicks(player)

	if type(beliefs) ~= "table" or #beliefs ~= picks then
		return nil, "Pick " .. picks .. " beliefs, as the religion choice's picks says."
	end

	local rows, classes = {}, {}

	for i, typeName in ipairs(beliefs) do
		local row, failure = FindBeliefRow(typeName, "religion")

		failure = failure or GetReligionBeliefFailure(row, -1)

		if failure ~= nil then
			return nil, failure
		end

		if i == 1 and row.BeliefClassType ~= "BELIEF_CLASS_FOLLOWER" then
			return nil, "A new religion's first belief is a follower belief, and " .. row.BeliefType .. " is a " .. row.BeliefClassType .. " belief."
		end

		if classes[row.BeliefClassType] then
			return nil, "Pick one belief of each class. " .. row.BeliefType .. " is a second " .. row.BeliefClassType .. " belief."
		end

		classes[row.BeliefClassType] = true
		rows[i] = row
	end

	return rows, nil
end

-- Sends the requests the religion screen's confirm sends: the religion, then
-- each belief. See ConfirmReligionBeliefs in ReligionScreen.lua.
local function RequestReligion(playerID, row, name, beliefRows)
	local P = PlayerOperations
	local parameters = {
		[P.PARAM_RELIGION_TYPE] = row.Hash,
		[P.PARAM_RELIGION_CUSTOM_NAME] = name,
		[P.PARAM_INSERT_MODE] = P.VALUE_EXCLUSIVE,
	}

	UI.RequestPlayerOperation(playerID, P.FOUND_RELIGION, parameters)

	for _, belief in ipairs(beliefRows) do
		UI.RequestPlayerOperation(playerID, P.ADD_BELIEF, { [P.PARAM_BELIEF_TYPE] = belief.Hash, [P.PARAM_INSERT_MODE] = P.VALUE_EXCLUSIVE })
	end
end

local function FoundReligion(playerID, typeName, beliefs, name)
	local player = SentientSystems_GetPlayer(playerID)
	local failure = GetFoundReligionFailure(player)

	if failure ~= nil then
		return failure
	end

	local row, beliefRows

	row, failure = FindOpenReligionRow(typeName)

	if failure ~= nil then
		return failure
	end

	name, failure = GetReligionName(row, name)

	if failure ~= nil then
		return failure
	end

	beliefRows, failure = FindFoundingBeliefs(player, beliefs)

	if failure ~= nil then
		return failure
	end

	RequestReligion(playerID, row, name, beliefRows)

	return nil
end

-- Founds the player's pantheon with the belief and returns the result as JSON.
-- The belief is a type from the pantheon choice, such as
-- BELIEF_RELIGIOUS_SETTLEMENTS.
function SentientSystems_FoundPantheon(playerID, belief)
	return SentientSystems_RunAction("FoundPantheon", FoundPantheon, playerID, belief)
end

-- Founds the player's religion and adds its beliefs, and returns the result as
-- JSON. The religion is a type from the religion choice, such as
-- RELIGION_BUDDHISM, and the beliefs a list of the types it offers, a follower
-- belief first. The name is for a religion whose customName is true.
function SentientSystems_FoundReligion(playerID, religion, beliefs, name)
	return SentientSystems_RunAction("FoundReligion", FoundReligion, playerID, religion, beliefs, name)
end

-- The tech and civic actions. SentientSystemsCore_Actions.lua loads this file.
-- The calls are in docs/findings/actions/research.md.

SentientSystems_Include("SentientSystemsCore_Research")

-- Returns the row of the tech or civic by its type, or nil and the reason.
local function FindResearchRow(kind, typeName)
	local row = type(typeName) == "string" and kind.row(typeName) or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a " .. kind.name .. ". Use the type of an option of the " .. kind.choice .. " choice."
	end

	return row, nil
end

-- Returns why the player can't research the row now, or nil. The game takes a
-- request for any tech or civic, even one whose prerequisites the player
-- lacks, so the action allows only what the chooser lists.
local function GetResearchOptionFailure(kind, store, row)
	if SentientSystems_IsResearchOption(kind, store, kind.current(store), row.Index) then
		return nil
	end

	local typeName = row[kind.typeColumn]

	if kind.has(store, row.Index) then
		return "You have " .. typeName .. " already."
	end

	return typeName .. " isn't one of the " .. kind.choice .. " you can research now. Use the type of an option of the " .. kind.choice .. " choice."
end

-- Sends the chooser's request, which replaces the one in research. See
-- OnChooseResearch in ResearchChooser.lua and OnChooseCivic in
-- CivicsChooser.lua.
local function RequestResearch(kind, playerID, row)
	local parameters = {
		[PlayerOperations[kind.parameter]] = row.Hash,
		[PlayerOperations.PARAM_INSERT_MODE] = PlayerOperations.VALUE_EXCLUSIVE,
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations[kind.operation], parameters)
end

local function ChooseResearch(kindName, playerID, typeName)
	local kind = SENTIENTSYSTEMS_RESEARCH_KINDS[kindName]
	local store = kind.store(SentientSystems_GetPlayer(playerID))
	local row, failure = FindResearchRow(kind, typeName)

	if failure ~= nil then
		return failure
	end

	failure = GetResearchOptionFailure(kind, store, row)

	if failure ~= nil then
		return failure
	end

	RequestResearch(kind, playerID, row)

	return nil
end

-- Sets the tech the player researches, and returns the result as JSON. The
-- tech is the type of an option of the techs choice, such as TECH_MINING.
function SentientSystems_SetResearch(playerID, tech)
	return SentientSystems_RunAction("SetResearch", ChooseResearch, "tech", playerID, tech)
end

-- Sets the civic the player researches, and returns the result as JSON. The
-- civic is the type of an option of the civics choice, such as
-- CIVIC_MYSTICISM.
function SentientSystems_SetCivic(playerID, civic)
	return SentientSystems_RunAction("SetCivic", ChooseResearch, "civic", playerID, civic)
end

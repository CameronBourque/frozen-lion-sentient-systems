-- The tech and civic actions. SentientSystemsCore_Actions.lua loads this file.
-- The calls are in docs/findings/actions/research.md.

SentientSystems_Include("SentientSystemsCore_Research")

-- Returns the row of the tech or civic by its type, or nil and the reason.
local function FindResearchRow(kind, typeName)
	local row = type(typeName) == "string" and kind.row(typeName) or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a " .. kind.name .. ". Use a type from the " .. kind.choice .. " choice or the " .. kind.name .. " tree."
	end

	return row, nil
end

-- Returns why the player can't research the row, now or after its
-- prerequisites, or nil. The tree screen takes no click on a researched or an
-- unrevealed node. See STATUS_ART in TechTree.lua, and in CivicsTree.lua.
local function GetResearchTargetFailure(kind, store, row)
	local typeName = row[kind.typeColumn]

	if kind.has(store, row.Index) then
		return "You have " .. typeName .. " already."
	end

	if not kind.revealed(store, row.Index) then
		return typeName .. " isn't revealed yet. Use the type of a " .. kind.name .. " the " .. kind.name .. " tree names."
	end

	return nil
end

-- Sends the tree screen's request with the path to the row: the row and each
-- prerequisite the player lacks, in order. The game takes a request for any
-- tech or civic, even without its prerequisites, so the action always sends
-- the path. With append, the path goes to the end of the queue, and the game
-- skips what is queued already. Otherwise it replaces the queue. See
-- SetCurrentNode in TechTree.lua, and in CivicsTree.lua.
local function RequestResearch(kind, store, playerID, row, append)
	local path = kind.path(store, row.Hash)

	if path == nil or #path == 0 then
		return "The game finds no path to " .. row[kind.typeColumn] .. "."
	end

	local parameters = {
		[PlayerOperations[kind.parameter]] = path,
		[PlayerOperations.PARAM_INSERT_MODE] = append and PlayerOperations.VALUE_APPEND or PlayerOperations.VALUE_EXCLUSIVE,
	}

	UI.RequestPlayerOperation(playerID, PlayerOperations[kind.operation], parameters)

	return nil
end

local function ChooseResearch(kindName, playerID, typeName, append)
	local kind = SENTIENTSYSTEMS_RESEARCH_KINDS[kindName]
	local store = kind.store(SentientSystems_GetPlayer(playerID))
	local row, failure = FindResearchRow(kind, typeName)

	if failure ~= nil then
		return failure
	end

	failure = GetResearchTargetFailure(kind, store, row)

	if failure ~= nil then
		return failure
	end

	return RequestResearch(kind, store, playerID, row, append)
end

-- Researches the tech and the prerequisites it needs, in place of the queue,
-- or after it when append is true, and returns the result as JSON. The tech is
-- a type from the techs choice or the tech tree, such as TECH_MINING.
function SentientSystems_SetResearch(playerID, tech, append)
	return SentientSystems_RunAction("SetResearch", ChooseResearch, "tech", playerID, tech, append)
end

-- Researches the civic and the prerequisites it needs, as SetResearch does for
-- a tech, and returns the result as JSON. The civic is a type from the civics
-- choice or the civic tree, such as CIVIC_MYSTICISM.
function SentientSystems_SetCivic(playerID, civic, append)
	return SentientSystems_RunAction("SetCivic", ChooseResearch, "civic", playerID, civic, append)
end

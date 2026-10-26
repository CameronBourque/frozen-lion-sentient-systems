-- Builds one player's tech tree as JSON for the bridge, in a call of its own, as the tech tree screen
-- shows it, so the agent can plan a route through the tree. It reads the tree from the running game,
-- because the Tech and Civic Shuffle mode changes it. See docs/design/core/in-game-lua.md. Example:
-- SentientSystems_GetTechTree(0) returns '{"nodes":[{"cost":25,"era":"ERA_ANCIENT",
-- "prerequisites":[],"status":"ready","type":"TECH_MINING",...}],"players":[{"player":0,...}]}', on
-- one line. The checks follow GetCurrentData and PopulateNode in TechTree.lua.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")
SentientSystems_Include("SentientSystemsCore_ChoicesResearch")

-- The game's calls for the tech tree. The tree screen lists the nodes from UITree, with the
-- prerequisites the running game has. See PopulateItemData in TechTree.lua, lines 1374 to 1447.
local TREES = {
	tech = {
		nodes = function()
			return UITree.GetAvailableTechs()
		end,
		prerequisites = "PrereqTechTypes",
		row = function(name)
			return GameInfo.Technologies[name]
		end,
		has = function(store, index)
			return store:HasTech(index)
		end,
		-- Without the Tech and Civic Shuffle mode, a store may have no IsTechRevealed, and every
		-- node is revealed. See GetCurrentData in TechTree.lua, lines 1244 to 1252.
		revealed = function(store, index)
			return store.IsTechRevealed == nil or store:IsTechRevealed(index)
		end,
		count = function(player)
			local count = 0
			local store = player:GetTechs()

			for row in GameInfo.Technologies() do
				if store:HasTech(row.Index) then
					count = count + 1
				end
			end

			return count
		end,
		highestEra = function(player)
			local store = player:GetTechs()
			local highest

			for row in GameInfo.Technologies() do
				if store:HasTech(row.Index) and (highest == nil or GameInfo.Eras[row.EraType].ChronologyIndex > GameInfo.Eras[highest].ChronologyIndex) then
					highest = row.EraType
				end
			end

			return highest
		end,
	},
}

-- Returns a node's status, as the tree screen colors it: researched, current, ready, or blocked.
-- See GetCurrentData in TechTree.lua, lines 1099 to 1109.
local function Status(tree, reader, row)
	if tree.has(reader.store, row.Index) then
		return "researched"
	elseif row.Index == reader.current then
		return "current"
	elseif reader.kind.canProgress(reader.store, row.Index) then
		return "ready"
	end

	return "blocked"
end

-- Returns the name of each node by its type: its type when the player has revealed it, and "?1",
-- "?2", and so on, in the tree's order, when the screen shows it as Unrevealed. The numbers link a
-- hidden node to the nodes it leads to within one call, as the screen's lines do.
local function NodeNames(tree, reader, nodes)
	local names = {}
	local hidden = 0

	for _, node in ipairs(nodes) do
		if tree.revealed(reader.store, tree.row(node.Name).Index) then
			names[node.Name] = node.Name
		else
			hidden = hidden + 1
			names[node.Name] = "?" .. hidden
		end
	end

	return names
end

-- Returns a node as the tree screen shows it. A revealed node has what the chooser shows, except
-- that the screen shows no boost or progress for a researched node, and turns only while they are
-- above 0. An unrevealed node shows no name, cost, boost, or unlocks. The node in research shows the
-- turns from GetTurnsLeft. See PopulateNode in TechTree.lua, lines 778 to 967.
local function Node(tree, reader, node, names)
	local row = tree.row(node.Name)
	local status = Status(tree, reader, row)
	local entry

	if names[node.Name] == node.Name then
		entry = reader.Option(row)
	else
		entry = { type = names[node.Name], turns = reader.kind.turns(reader.store, row.Index) }

		local progress = reader.kind.progress(reader.store, row.Index)

		if progress > 0 then
			entry.progress = progress
		end
	end

	if status == "current" then
		entry.turns = reader.store:GetTurnsLeft()
	end

	if status == "researched" then
		entry.boost, entry.progress, entry.recommended = nil, nil, nil
	end

	if status == "researched" or entry.turns <= 0 then
		entry.turns = nil
	end

	entry.era = row.EraType
	entry.status = status
	entry.prerequisites = {}

	for i, prerequisite in ipairs(node[tree.prerequisites]) do
		entry.prerequisites[i] = names[prerequisite]
	end

	return entry
end

-- Returns the player and each player they have met, with the number of nodes they have researched,
-- and the latest era they have researched in, as the timeline at the bottom of the screen marks it.
-- The era is left out for a player who has researched nothing. See GetCurrentData in TechTree.lua,
-- lines 1143 to 1177.
local function PlayerProgress(tree, player)
	local players = {}
	local diplomacy = player:GetDiplomacy()

	for _, other in ipairs(Game.GetPlayers({ Major = true })) do
		local id = other:GetID()

		if id == player:GetID() or diplomacy:HasMet(id) then
			players[#players + 1] = { player = id, researched = tree.count(other), era = tree.highestEra(other) }
		end
	end

	return players
end

-- Returns the tree of a kind for the player with ID playerID as JSON.
local function GetTree(kindName, playerID)
	local player = Players[playerID]

	if player == nil then
		error("no player " .. tostring(playerID), 0)
	end

	local tree = TREES[kindName]
	local reader = SentientSystems_GetResearchReader(kindName, player)
	local nodes = tree.nodes()
	local names = NodeNames(tree, reader, nodes)
	local entries = {}

	for i, node in ipairs(nodes) do
		entries[i] = Node(tree, reader, node, names)
	end

	return SentientSystems_EncodeJson({ nodes = entries, players = PlayerProgress(tree, player) })
end

-- Returns the tech tree of the player with ID playerID as JSON. Raises an error for an ID with no
-- player. The bridge reads it through the stash, as
-- SentientSystems_Stash(SentientSystems_GetTechTree(playerID)).
function SentientSystems_GetTechTree(playerID)
	return GetTree("tech", playerID)
end

-- The tech and civic choices: the techs and civics the player can research now, as the research and
-- civics choosers list them. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetTechChoices(player) returns a list with one table for each tech, which encodes
-- as '{"boost":{"percent":40,"trigger":"Found a city on the Coast.","triggered":false},"cost":25,
-- "description":"Allows Builders to embark.","turns":1,"type":"TECH_SAILING",
-- "unlocks":["UNIT_GALLEY","IMPROVEMENT_FISHING_BOATS"]}', on one line.
-- SentientSystems_GetCivicChoices(player) returns civics in the same form. The checks follow GetData
-- in ResearchChooser.lua and CivicsChooser.lua, and GetResearchData and GetCivicData in
-- TechAndCivicSupport.lua.

-- The game's calls for techs and for civics. Each reads from the player's store: GetTechs for techs,
-- and GetCulture for civics.
local KINDS = {
	tech = {
		rows = function()
			return GameInfo.Technologies()
		end,
		typeColumn = "TechnologyType",
		store = function(player)
			return player:GetTechs()
		end,
		current = function(store)
			return store:GetResearchingTech()
		end,
		canProgress = function(store, index)
			return store:CanResearch(index)
		end,
		cost = function(store, index)
			return store:GetResearchCost(index)
		end,
		progress = function(store, index)
			return store:GetResearchProgress(index)
		end,
		turns = function(store, index)
			return store:GetTurnsToResearch(index)
		end,
		recommendations = function(strategicAI)
			return strategicAI:GetTechRecommendations()
		end,
		hashField = "TechHash",
		-- The game's function from TechAndCivicUnlockables.lua, read when it is called, as the file
		-- may load later.
		unlocksFunction = function()
			return GetUnlockablesForTech
		end,
	},
	civic = {
		rows = function()
			return GameInfo.Civics()
		end,
		typeColumn = "CivicType",
		store = function(player)
			return player:GetCulture()
		end,
		current = function(store)
			return store:GetProgressingCivic()
		end,
		canProgress = function(store, index)
			return store:CanProgress(index)
		end,
		cost = function(store, index)
			return store:GetCultureCost(index)
		end,
		progress = function(store, index)
			return store:GetCulturalProgress(index)
		end,
		turns = function(store, index)
			return store:GetTurnsToProgressCivic(index)
		end,
		recommendations = function(strategicAI)
			return strategicAI:GetCivicsRecommendations()
		end,
		hashField = "CivicHash",
		unlocksFunction = function()
			return GetUnlockablesForCivic
		end,
	},
}

-- Returns the boost of a tech or civic, with its percent of the cost, the text of its trigger, and
-- whether it has been triggered, or nil for one with no boost. A row of GameInfo.Boosts names a tech
-- in TechnologyType, or a civic in CivicType. See GetResearchData and GetCivicData in
-- TechAndCivicSupport.lua, lines 550 to 557 and 667 to 674.
local function Boost(kind, store, row)
	for boost in GameInfo.Boosts() do
		if boost[kind.typeColumn] == row[kind.typeColumn] then
			return {
				percent = boost.Boost,
				trigger = Locale.Lookup(boost.TriggerDescription),
				triggered = store:HasBoostBeenTriggered(row.Index),
			}
		end
	end
end

-- Returns a set of the hashes the game's advisor recommends, as the choosers mark them. See GetData
-- in ResearchChooser.lua, lines 56 to 61, and in CivicsChooser.lua, lines 54 to 58.
local function Recommended(kind, player)
	local hashes = {}
	local strategicAI = player:GetGrandStrategicAI()

	for _, recommendation in pairs(strategicAI and kind.recommendations(strategicAI) or {}) do
		hashes[recommendation[kind.hashField]] = true
	end

	return hashes
end

-- Returns a function that lists what a tech or civic unlocks, by type, with the game's own
-- GetUnlockablesForTech or GetUnlockablesForCivic from TechAndCivicUnlockables.lua, which the
-- choosers draw as icons. For techs, the list of the player's unlockable items is built once, as it
-- is slow to build. Without the file, the function returns nil, and nothing has unlocks. The game's
-- UI states have no _G, so each kind returns its function in place of naming it.
local function UnlocksReader(kind, playerID)
	if kind.unlocksFunction() == nil then
		include("TechAndCivicUnlockables")
	end

	local getUnlockables = kind.unlocksFunction()

	if getUnlockables == nil then
		return function()
			return nil
		end
	end

	local items = kind == KINDS.tech and GetFilteredUnlockableItems(playerID) or nil

	return function(row)
		local unlocks = {}

		for i, unlock in ipairs(getUnlockables(row[kind.typeColumn], playerID, items)) do
			unlocks[i] = unlock[1]
		end

		return unlocks
	end
end

-- Returns a list of the techs or civics the player can research now, and the one in research, in
-- the game's order. See GetData in ResearchChooser.lua, lines 66 to 96, and in CivicsChooser.lua,
-- lines 63 to 93.
local function GetResearchChoices(kind, player)
	local store = kind.store(player)
	local current = kind.current(store)
	local recommended = Recommended(kind, player)
	local unlocksOf = UnlocksReader(kind, player:GetID())
	local options = {}

	for row in kind.rows() do
		if row.Index == current or kind.canProgress(store, row.Index) then
			local option = {
				type = row[kind.typeColumn],
				cost = kind.cost(store, row.Index),
				turns = kind.turns(store, row.Index),
				boost = Boost(kind, store, row),
				unlocks = unlocksOf(row),
			}
			local progress = kind.progress(store, row.Index)

			if progress > 0 then
				option.progress = progress
			end

			-- The choosers draw the description as one more unlock icon, a star, with the text as its
			-- tooltip. See PopulateUnlockablesForTech and PopulateUnlockablesForCivic in
			-- TechAndCivicSupport.lua, lines 391 to 412 and 310 to 331. The civics chooser leaves out the
			-- star for some civics, which show an icon for an envoy or a governor title in its place.
			if row.Description ~= nil then
				option.description = Locale.Lookup(row.Description)
			end

			if row.Index == current then
				option.current = true
			end

			if recommended[row.Hash] then
				option.recommended = true
			end

			options[#options + 1] = option
		end
	end

	return options
end

-- Returns a list of the techs the player can research now, and the tech in research.
function SentientSystems_GetTechChoices(player)
	return GetResearchChoices(KINDS.tech, player)
end

-- Returns a list of the civics the player can research now, and the civic in research.
function SentientSystems_GetCivicChoices(player)
	return GetResearchChoices(KINDS.civic, player)
end

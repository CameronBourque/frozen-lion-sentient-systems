-- The tech choice: the techs the player can research now, as the research chooser lists them.
-- SentientSystemsCore_Choices.lua loads this file. Example: SentientSystems_GetTechChoices(player)
-- returns a list with one table for each tech, which encodes as '{"boost":{"percent":40,
-- "trigger":"Found a city on the Coast.","triggered":false},"cost":25,"turns":1,
-- "type":"TECH_SAILING","unlocks":["UNIT_GALLEY","IMPROVEMENT_FISHING_BOATS"]}', on one line. The
-- checks follow GetData in ResearchChooser.lua and GetResearchData in TechAndCivicSupport.lua.

-- Returns the boost of a tech, with its percent of the cost, the text of its trigger, and whether it
-- has been triggered, or nil for a tech with no boost. See GetResearchData in
-- TechAndCivicSupport.lua, lines 550 to 557.
local function Boost(techs, row)
	for boost in GameInfo.Boosts() do
		if boost.TechnologyType == row.TechnologyType then
			return {
				percent = boost.Boost,
				trigger = Locale.Lookup(boost.TriggerDescription),
				triggered = techs:HasBoostBeenTriggered(row.Index),
			}
		end
	end
end

-- Returns a set of the hashes of the techs the game's advisor recommends, as the chooser marks them.
-- See GetData in ResearchChooser.lua, lines 56 to 61.
local function Recommended(player)
	local hashes = {}
	local strategicAI = player:GetGrandStrategicAI()

	for _, recommendation in pairs(strategicAI and strategicAI:GetTechRecommendations() or {}) do
		hashes[recommendation.TechHash] = true
	end

	return hashes
end

-- Returns a function that lists what a tech unlocks, by type, with the game's own
-- GetUnlockablesForTech from TechAndCivicUnlockables.lua, which the chooser draws as icons. The
-- list of the player's unlockable items is built once, as it is slow to build. Without the file,
-- the function returns nil, and the techs have no unlocks.
local function UnlocksReader(playerID)
	if GetUnlockablesForTech == nil then
		include("TechAndCivicUnlockables")
	end

	if GetUnlockablesForTech == nil then
		return function()
			return nil
		end
	end

	local items = GetFilteredUnlockableItems(playerID)

	return function(row)
		local unlocks = {}

		for i, unlock in ipairs(GetUnlockablesForTech(row.TechnologyType, playerID, items)) do
			unlocks[i] = unlock[1]
		end

		return unlocks
	end
end

-- Returns a list of the techs the player can research now, and the tech in research, in the game's
-- order. See GetData in ResearchChooser.lua, lines 66 to 96.
function SentientSystems_GetTechChoices(player)
	local techs = player:GetTechs()
	local current = techs:GetResearchingTech()
	local recommended = Recommended(player)
	local unlocksOf = UnlocksReader(player:GetID())
	local options = {}

	for row in GameInfo.Technologies() do
		if row.Index == current or techs:CanResearch(row.Index) then
			local option = {
				type = row.TechnologyType,
				cost = techs:GetResearchCost(row.Index),
				turns = techs:GetTurnsToResearch(row.Index),
				boost = Boost(techs, row),
				unlocks = unlocksOf(row),
			}
			local progress = techs:GetResearchProgress(row.Index)

			if progress > 0 then
				option.progress = progress
			end

			-- The chooser draws the description as one more unlock icon, a star, with the text as its
			-- tooltip. See PopulateUnlockablesForTech in TechAndCivicSupport.lua, lines 391 to 412.
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

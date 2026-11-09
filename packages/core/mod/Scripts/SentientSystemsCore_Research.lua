-- The game's calls for techs and for civics, which the choices, the trees, and
-- the actions share. Follows ResearchChooser.lua and CivicsChooser.lua.

include("SentientSystemsCore_Common")

-- Each kind by name, "tech" or "civic". Each reads from the player's store:
-- GetTechs for techs, and GetCulture for civics. operation and parameter name
-- the request the chooser sends, as keys of PlayerOperations. See
-- OnChooseResearch in ResearchChooser.lua and OnChooseCivic in
-- CivicsChooser.lua.
SENTIENTSYSTEMS_RESEARCH_KINDS = {
	tech = {
		name = "tech",
		choice = "techs",
		rows = function()
			return GameInfo.Technologies()
		end,
		row = function(typeName)
			return GameInfo.Technologies[typeName]
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
		has = function(store, index)
			return store:HasTech(index)
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
		-- The game's function from TechAndCivicUnlockables.lua, read when it is
		-- called, as the file may load later.
		unlocksFunction = function()
			return GetUnlockablesForTech
		end,
		operation = "RESEARCH",
		parameter = "PARAM_TECH_TYPE",
	},
	civic = {
		name = "civic",
		choice = "civics",
		rows = function()
			return GameInfo.Civics()
		end,
		row = function(typeName)
			return GameInfo.Civics[typeName]
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
		has = function(store, index)
			return store:HasCivic(index)
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
		operation = "PROGRESS_CIVIC",
		parameter = "PARAM_CIVIC_TYPE",
	},
}

-- Returns whether the chooser lists the row: the one in research, or one the
-- player can research now. See GetData in ResearchChooser.lua, and in
-- CivicsChooser.lua.
function SentientSystems_IsResearchOption(kind, store, current, index)
	return index == current or kind.canProgress(store, index)
end

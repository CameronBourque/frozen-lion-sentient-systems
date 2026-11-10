-- The game's calls for techs and for civics, which the choices, the trees, and
-- the actions share. Follows the research choosers and the tree screens.

include("SentientSystemsCore_Common")

-- Each kind by name, "tech" or "civic". Each reads from the player's store:
-- GetTechs for techs, and GetCulture for civics. Without the Tech and Civic
-- Shuffle mode, a store may have no IsTechRevealed or IsCivicRevealed, and
-- every row is revealed. path lists the indexes to research, in order, to reach
-- a row, and queue the indexes in the queue, the one in research first.
-- operation and parameter name the request the tree screen sends, as keys of
-- PlayerOperations. See SetCurrentNode in TechTree.lua, and in CivicsTree.lua.
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
		revealed = function(store, index)
			return store.IsTechRevealed == nil or store:IsTechRevealed(index)
		end,
		path = function(store, hash)
			return store:GetResearchPath(hash)
		end,
		queue = function(store)
			return store:GetResearchQueue()
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
		revealed = function(store, index)
			return store.IsCivicRevealed == nil or store:IsCivicRevealed(index)
		end,
		path = function(store, hash)
			return store:GetCivicPath(hash)
		end,
		queue = function(store)
			return store:GetCivicQueue()
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

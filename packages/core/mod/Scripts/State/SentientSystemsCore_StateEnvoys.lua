-- The envoys section, as the City-States screen shows it. Follows GetData in
-- CityStates.lua.
-- Shape: bridge/src/state/envoys.ts.

-- The fewest envoys that make a suzerain, which CityStates.lua also sets by
-- hand.
local MIN_SUZERAIN_ENVOYS = 3

-- The prefix of the leader types that name each kind of city-state.
local KIND_PREFIX = "LEADER_MINOR_CIV_"
local KINDS = { SCIENTIFIC = true, RELIGIOUS = true, TRADE = true, CULTURAL = true, MILITARISTIC = true, INDUSTRIAL = true }

-- The sizes in the text keys of the bonuses at 1, 3, and 6 envoys.
local BONUS_SIZES = { "SMALL", "MEDIUM", "LARGE" }

-- Returns the kind of a city-state from its leader or the leader it inherits
-- from, or nil for a leader of no kind. See GetCityStateType in CityStates.lua.
local function GetCityStateKind(playerID)
	local leader = PlayerConfigurations[playerID]:GetLeaderTypeName()
	local row = GameInfo.Leaders[leader]

	for _, typeName in ipairs({ leader, row and row.InheritFrom }) do
		local kind = typeName:sub(#KIND_PREFIX + 1)

		if typeName:sub(1, #KIND_PREFIX) == KIND_PREFIX and KINDS[kind] then
			return kind
		end
	end

	return nil
end

-- Returns the bonuses of a kind of city-state at 1, 3, and 6 envoys, as text.
-- See GetBonusText in CityStates.lua.
local function GetKindBonuses(kind)
	local bonuses = {}

	for i, size in ipairs(BONUS_SIZES) do
		bonuses[i] = SentientSystems_LookupText("LOC_MINOR_CIV_" .. kind .. "_TRAIT_" .. size .. "_INFLUENCE_BONUS")
	end

	return bonuses
end

-- Returns the descriptions of a city-state's own traits, its suzerain bonus, as
-- text, or nil for a city-state with none. See GetSuzerainBonusText in
-- CityStates.lua.
local function GetSuzerainBonus(playerID)
	local leader = PlayerConfigurations[playerID]:GetLeaderTypeName()
	local texts = {}

	for row in GameInfo.LeaderTraits() do
		local trait = row.LeaderType == leader and GameInfo.Traits[row.TraitType]

		if trait and trait.Description ~= nil then
			texts[#texts + 1] = SentientSystems_LookupText(trait.Description)
		end
	end

	return #texts > 0 and table.concat(texts, "\n\n") or nil
end

-- Returns the resources a city-state has, which its suzerain gets, each with
-- type and amount, or nil for none. With Gathering Storm, a strategic
-- resource's amount is what it gains each turn. See GetSuzerainBonusText in
-- CityStates_Expansion2.lua.
local function GetResources(cityState)
	local resources = cityState:GetResources()
	local list = {}

	for row in GameInfo.Resources() do
		local index = row.Index
		local perTurn = resources.GetResourceAccumulationPerTurn and resources:GetResourceAccumulationPerTurn(index) or 0

		if resources:HasResource(index) or resources:HasExportedResource(index) or perTurn > 0 then
			local amount = perTurn > 0 and perTurn or resources:GetResourceAmount(index) + resources:GetExportedResourceAmount(index)

			list[#list + 1] = { type = row.ResourceType, amount = amount }
		end
	end

	return #list > 0 and list or nil
end

-- Returns the quests a city-state gives the player, or nil for none. See
-- GetQuests in CityStates.lua.
local function GetQuests(playerID, cityStateID)
	local manager = Game.GetQuestsManager()
	local quests = {}

	for row in GameInfo.Quests() do
		if manager:HasActiveQuestFromPlayer(playerID, cityStateID, row.Index) then
			quests[#quests + 1] = {
				type = row.QuestType,
				name = SentientSystems_CleanText(manager:GetActiveQuestName(playerID, cityStateID, row.Index)),
				description = SentientSystems_CleanText(manager:GetActiveQuestDescription(playerID, cityStateID, row.Index)),
				reward = SentientSystems_CleanText(manager:GetActiveQuestReward(playerID, cityStateID, row.Index)),
			}
		end
	end

	return #quests > 0 and quests or nil
end

-- Returns the players with envoys at a city-state, most envoys first, as the
-- Influenced By tab lists them. Ties keep the game's order. See ViewCityState
-- in CityStates.lua, and AddInfluenceRow.
local function GetInfluencedBy(player, influence)
	local list = {}

	for i, otherID in ipairs(PlayerManager.GetAliveMajorIDs()) do
		local envoys = influence:GetTokensReceived(otherID)

		if envoys > 0 then
			local known = otherID == player:GetID() or player:GetDiplomacy():HasMet(otherID)

			list[#list + 1] = { order = i, envoys = envoys, player = known and otherID or nil, unmet = (not known) or nil }
		end
	end

	table.sort(list, function(a, b)
		if a.envoys ~= b.envoys then
			return a.envoys > b.envoys
		end

		return a.order < b.order
	end)

	for _, entry in ipairs(list) do
		entry.order = nil
	end

	return list
end

-- Returns one city-state as the screen's list shows it. See GetData in
-- CityStates.lua.
local function GetCityState(player, cityState)
	local playerID = player:GetID()
	local cityStateID = cityState:GetID()
	local influence = cityState:GetInfluence()
	local suzerain = influence:GetSuzerain()
	local most = influence:GetMostTokensReceived()
	local entry = {
		player = cityStateID,
		name = Locale.Lookup(PlayerConfigurations[cityStateID]:GetCivilizationShortDescription()),
		type = GetCityStateKind(cityStateID),
		envoys = influence:GetTokensReceived(playerID),
		suzerainNeeds = math.max(MIN_SUZERAIN_ENVOYS, suzerain == playerID and most or most + 1),
		suzerainBonus = GetSuzerainBonus(cityStateID),
		suzerainBonusDisabled = (influence.IsSuzerainUniqueBonusDisabled and influence:IsSuzerainUniqueBonusDisabled()) or nil,
		resources = GetResources(cityState),
		quests = GetQuests(playerID, cityStateID),
		influencedBy = GetInfluencedBy(player, influence),
	}

	if suzerain == playerID or (suzerain >= 0 and player:GetDiplomacy():HasMet(suzerain)) then
		entry.suzerain = suzerain
	elseif suzerain >= 0 then
		entry.suzerainUnmet = true
	end

	return entry
end

-- Returns whether a living minor player is a city-state the player has met, as
-- the screen lists them. The Free Cities can't receive envoys, so the screen
-- leaves them out.
local function IsMetCityState(player, minor)
	return minor:GetID() ~= player:GetID()
		and minor:GetInfluence():CanReceiveInfluence()
		and player:GetDiplomacy():HasMet(minor:GetID())
end

-- Returns the envoys section. See RealizeListHeader in CityStates.lua.
function SentientSystems_GetEnvoyState(player)
	local influence = player:GetInfluence()
	local cityStates = {}
	local bonuses

	for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
		if IsMetCityState(player, minor) then
			local entry = GetCityState(player, minor)

			cityStates[#cityStates + 1] = entry

			if entry.type ~= nil then
				bonuses = bonuses or {}
				bonuses[entry.type] = bonuses[entry.type] or GetKindBonuses(entry.type)
			end
		end
	end

	return {
		bonuses = bonuses,
		tokens = influence:GetTokensToGive(),
		influence = {
			points = influence:GetPointsEarned(),
			perTurn = influence:GetPointsPerTurn(),
			threshold = influence:GetPointsThreshold(),
			envoys = influence:GetTokensPerThreshold(),
		},
		cityStates = cityStates,
	}
end

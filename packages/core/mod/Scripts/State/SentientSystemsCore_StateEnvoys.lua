-- The envoys section of the state: the player's envoy tokens and influence, the bonuses of each kind
-- of city-state, and each met city-state's envoys, suzerain, suzerain bonus, resources, quests, and
-- the players with envoys there, as the City-States screen shows them.
-- SentientSystemsCore_State.lua loads this file. Example: SentientSystems_GetEnvoyState(player)
-- returns a table that encodes as '{"bonuses":{"TRADE":["+2 [ICON_Gold] Gold in the ...",...]},
-- "cityStates":[{"envoys":2,"influencedBy":[{"envoys":3,"player":1},{"envoys":2,"player":0}],
-- "name":"Samarkand","player":12,"quests":[{"description":"Recruit one [ICON_GreatGeneral] Great
-- General.","name":"Recruit a Great General.","reward":"[ICON_Envoy] 1 Envoy",
-- "type":"QUEST_RECRUIT_GREAT_PERSON_CLASS"}],"suzerain":1,"suzerainBonus":"Your Builders can now
-- make Trading Dome improvements. ...","suzerainNeeds":4,"type":"TRADE"}],"influence":{"envoys":1,
-- "perTurn":0,"points":0,"threshold":50},"tokens":4}', on one line. The checks follow GetData in
-- CityStates.lua.

-- The fewest envoys that make a suzerain, which CityStates.lua also sets by hand.
local MIN_SUZERAIN_ENVOYS = 3

-- The prefix of the leader types that name each kind of city-state, such as
-- LEADER_MINOR_CIV_SCIENTIFIC.
local KIND_PREFIX = "LEADER_MINOR_CIV_"
local KINDS = { SCIENTIFIC = true, RELIGIOUS = true, TRADE = true, CULTURAL = true, MILITARISTIC = true, INDUSTRIAL = true }

-- The sizes in the text keys of the bonuses at 1, 3, and 6 envoys.
local BONUS_SIZES = { "SMALL", "MEDIUM", "LARGE" }

-- Returns the kind of a city-state, such as TRADE, from its leader or the leader it inherits from,
-- or nil for a leader of no kind. See GetCityStateType in CityStates.lua, lines 1591 to 1613.
local function GetKind(playerID)
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

-- Returns the bonuses of a kind of city-state at 1, 3, and 6 envoys, as text. See GetBonusText in
-- CityStates.lua, lines 130 to 189.
local function GetKindBonuses(kind)
	local bonuses = {}

	for i, size in ipairs(BONUS_SIZES) do
		bonuses[i] = Locale.Lookup("LOC_MINOR_CIV_" .. kind .. "_TRAIT_" .. size .. "_INFLUENCE_BONUS")
	end

	return bonuses
end

-- Returns the descriptions of a city-state's own traits, its suzerain bonus, as text, or nil for a
-- city-state with none. See GetSuzerainBonusText in CityStates.lua, lines 197 to 250.
local function GetSuzerainBonus(playerID)
	local leader = PlayerConfigurations[playerID]:GetLeaderTypeName()
	local texts = {}

	for row in GameInfo.LeaderTraits() do
		local trait = row.LeaderType == leader and GameInfo.Traits[row.TraitType]

		if trait and trait.Description ~= nil then
			texts[#texts + 1] = Locale.Lookup(trait.Description)
		end
	end

	return #texts > 0 and table.concat(texts, "[NEWLINE][NEWLINE]") or nil
end

-- Returns the resources a city-state has, which its suzerain gets, each with type and amount, or nil
-- for none. With Gathering Storm, a strategic resource's amount is what it gains each turn. See
-- GetSuzerainBonusText in CityStates_Expansion2.lua, lines 50 to 72.
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

-- Returns the quests a city-state gives the player, each with type, name, description, and reward,
-- or nil for none. See GetQuests in CityStates.lua, lines 255 to 275.
local function GetQuests(playerID, cityStateID)
	local manager = Game.GetQuestsManager()
	local quests = {}

	for row in GameInfo.Quests() do
		if manager:HasActiveQuestFromPlayer(playerID, cityStateID, row.Index) then
			quests[#quests + 1] = {
				type = row.QuestType,
				name = manager:GetActiveQuestName(playerID, cityStateID, row.Index),
				description = manager:GetActiveQuestDescription(playerID, cityStateID, row.Index),
				reward = manager:GetActiveQuestReward(playerID, cityStateID, row.Index),
			}
		end
	end

	return #quests > 0 and quests or nil
end

-- Returns the players with envoys at a city-state, most envoys first, as the Influenced By tab lists
-- them, each with envoys and player, its ID, when it is the player or a player they have met, or
-- unmet, true for a player they haven't met. Ties keep the game's order. See ViewCityState in
-- CityStates.lua, lines 1235 to 1275, and AddInfluenceRow, lines 1314 to 1333.
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

-- Returns one city-state as the screen's list shows it: player, its ID, name, type, envoys, the
-- player's envoys there, suzerain, the suzerain's ID when it is the player or a player they have
-- met, or suzerainUnmet, true for a player they haven't met, and suzerainNeeds, the envoys the
-- player needs to be suzerain, at least 3, and one more than the most any other player has. It adds
-- suzerainBonus, and suzerainBonusDisabled, true when Gathering Storm turns it off, resources,
-- quests, and influencedBy. See GetData in CityStates.lua, lines 1411 to 1530.
local function GetCityState(player, cityState)
	local playerID = player:GetID()
	local cityStateID = cityState:GetID()
	local influence = cityState:GetInfluence()
	local suzerain = influence:GetSuzerain()
	local most = influence:GetMostTokensReceived()
	local entry = {
		player = cityStateID,
		name = Locale.Lookup(PlayerConfigurations[cityStateID]:GetCivilizationShortDescription()),
		type = GetKind(cityStateID),
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

-- Returns whether a living minor player is a city-state the player has met, as the screen lists
-- them. The Free Cities can't receive envoys, so the screen leaves them out.
local function IsMetCityState(player, minor)
	return minor:GetID() ~= player:GetID()
		and minor:GetInfluence():CanReceiveInfluence()
		and player:GetDiplomacy():HasMet(minor:GetID())
end

-- Returns the envoys section: tokens, the envoys the player can send now, influence, with points,
-- perTurn, threshold, and envoys, the envoys each threshold gives, as the screen's header shows
-- them, bonuses, the bonuses at 1, 3, and 6 envoys of each kind of city-state met, left out with
-- none, and cityStates, each met city-state in the game's order. See RealizeListHeader in
-- CityStates.lua, lines 609 to 662.
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

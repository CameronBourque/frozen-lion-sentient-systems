-- The era part of the player section, as the Era Progress panel shows it. Rise
-- and Fall adds ages, so without it the part is left out.
-- SentientSystemsCore_StatePlayer.lua loads this file. The shape is in
-- bridge/src/state/era.ts. The checks follow GetData, Refresh, and
-- PopulateCivilizationIcons in EraProgressPanel.lua in DLC/Expansion1 and
-- DLC/Expansion2, which are the same.

SentientSystems_Include("SentientSystemsCore_Eras")

-- The order the panel lists the other players' ages in.
local AGE_ORDER = { "heroic", "golden", "normal", "dark" }

-- Returns what the player's era score is made of: the total of the earlier eras
-- as one entry, when it is above 0, then each source of this era that is above
-- 0. See GetData.
local function GetScoreBreakdown(eras, playerID)
	local list, previous = {}, 0

	for _, source in ipairs(eras:GetPlayerPreviousEraScoreBreakdown(playerID)) do
		for _, points in pairs(source) do
			previous = previous + points
		end
	end

	if previous > 0 then
		list[1] = { source = Locale.Lookup("LOC_ERAS_PREVIOUS_ERA_TOTAL_SCORE"), points = previous }
	end

	for _, source in ipairs(eras:GetPlayerCurrentEraScoreBreakdown(playerID)) do
		for text, points in pairs(source) do
			if points > 0 then
				list[#list + 1] = { source = text, points = points }
			end
		end
	end

	return list
end

-- Returns the least and the most turns until the next era. Once the countdown
-- has started, it is one number, counted so that its last turn is 1. Before it,
-- the era can end at its earliest end turn at the soonest, but not before the
-- countdown would run out, and at its latest end turn. See GetData.
local function GetTurnsUntilNext(eras)
	local countdown = eras:GetNextEraCountdown() + 1

	if countdown > 0 then
		return { min = countdown, max = countdown }
	end

	local turn = Game.GetCurrentGameTurn()

	return {
		min = math.max(eras:GetCurrentEraMinimumEndTurn() - turn, GlobalParameters.NEXT_ERA_TURN_COUNTDOWN),
		max = math.max(eras:GetCurrentEraMaximumEndTurn() - turn, 0),
	}
end

-- Returns the age the player earns for the next era at their score: golden at
-- the golden threshold, normal at the dark one, and dark below it. See GetData.
local function GetNextAge(score, normalFrom, goldenFrom)
	if score >= goldenFrom then
		return "golden"
	elseif score >= normalFrom then
		return "normal"
	end

	return "dark"
end

-- Returns the effects of the player's age. See GetData.
local function GetEffects(eras, player, age)
	local playerID = player:GetID()
	local dedications = {}

	for _, index in ipairs(eras:GetPlayerActiveCommemorations(playerID)) do
		local row = GameInfo.CommemorationTypes[index]

		dedications[#dedications + 1] = { type = row.CommemorationType, text = SentientSystems_GetDedicationText(eras, playerID, row, age) }
	end

	return { citizenLoyalty = player:GetCivilianLoyalty(), dedications = dedications }
end

-- Returns the ages of the players the player has met, in the panel's order, and
-- the number of players it hasn't, which the panel shows with no age. See
-- PopulateCivilizationIcons.
local function GetCivilizations(eras, player)
	local byAge, unmet = {}, 0

	for _, age in ipairs(AGE_ORDER) do
		byAge[age] = {}
	end

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local otherID = other:GetID()

		if otherID ~= player:GetID() then
			if player:GetDiplomacy():HasMet(otherID) then
				local list = byAge[SentientSystems_GetAge(eras, otherID)]

				list[#list + 1] = otherID
			else
				unmet = unmet + 1
			end
		end
	end

	local civilizations = {}

	for _, age in ipairs(AGE_ORDER) do
		for _, otherID in ipairs(byAge[age]) do
			civilizations[#civilizations + 1] = { player = otherID, age = age }
		end
	end

	return civilizations, unmet
end

-- Returns the era section, or nil without Rise and Fall, whose game has no
-- ages. See Refresh in EraProgressPanel.lua.
function SentientSystems_GetEraState(player)
	local eras = Game.GetEras()

	if eras.GetPlayerDarkAgeThreshold == nil then
		return nil
	end

	local playerID = player:GetID()
	local row = GameInfo.Eras[eras:GetCurrentEra()]
	local age = SentientSystems_GetAge(eras, playerID)
	local score = eras:GetPlayerCurrentScore(playerID)
	local civilizations, unmet = GetCivilizations(eras, player)
	local state = {
		type = row.EraType,
		name = Locale.Lookup(row.Name),
		score = score,
		age = age,
		scoreBreakdown = GetScoreBreakdown(eras, playerID),
		effects = GetEffects(eras, player, age),
		civilizations = civilizations,
		unmet = unmet,
	}

	if eras:GetCurrentEra() == eras:GetFinalEra() then
		state.final = true

		return state
	end

	local normalFrom = eras:GetPlayerDarkAgeThreshold(playerID)
	local goldenFrom = eras:GetPlayerGoldenAgeThreshold(playerID)
	local dramatic = GameCapabilities.HasCapability("CAPABILITY_DRAMATICAGES")

	state.nextAge = GetNextAge(score, normalFrom, goldenFrom)
	state.thresholds = { normal = not dramatic and normalFrom or nil, golden = goldenFrom }
	state.turnsUntilNext = GetTurnsUntilNext(eras)

	return state
end

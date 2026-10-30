-- The culture part of the victories section of the state: the tourists of
-- each player, as the Culture tab of World Rankings shows them.
-- SentientSystemsCore_StateVictories.lua loads this file. Format:
-- docs/findings/game-victories.md.

-- Returns the tourists a player needs: one more than the most domestic
-- tourists of any player on another team, as GatherCultureData counts them.
local function GetRequiredTourists(other)
	local required = 0

	for _, rival in ipairs(PlayerManager.GetAliveMajors()) do
		if rival:GetTeam() ~= other:GetTeam() then
			local staycationers = rival:GetCulture():GetStaycationers()

			if staycationers >= required then
				required = staycationers + 1
			end
		end
	end

	return required
end

-- Returns the cultural dominance keys of a player: for the viewing player,
-- the counts of players that they dominate and that dominate them, and for
-- another player, who dominates whom. A zero count is left out.
local function GetDominance(player, other)
	local culture = player:GetCulture()
	local id = other:GetID()

	if id ~= player:GetID() then
		if culture:IsDominantOver(id) then
			return { dominance = "you" }
		elseif other:GetCulture():IsDominantOver(player:GetID()) then
			return { dominance = "them" }
		end

		return {}
	end

	local dominating, dominatedBy = 0, 0

	for _, rival in ipairs(PlayerManager.GetAliveMajors()) do
		if rival:GetID() ~= id then
			if culture:IsDominantOver(rival:GetID()) then
				dominating = dominating + 1
			elseif rival:GetCulture():IsDominantOver(id) then
				dominatedBy = dominatedBy + 1
			end
		end
	end

	return {
		dominating = dominating > 0 and dominating or nil,
		dominatedBy = dominatedBy > 0 and dominatedBy or nil,
	}
end

-- Returns the culture keys of a player's entry. The tab shows the tourists
-- of every player, and the turns and dominance only for a player that the
-- viewing player knows.
function SentientSystems_GetCultureDetails(player, other, met)
	local culture = other:GetCulture()
	local id = other:GetID()
	local details = {
		domesticTourists = culture:GetStaycationers(),
		visitingTourists = culture:GetTouristsTo(),
		requiredTourists = GetRequiredTourists(other),
	}

	if id ~= player:GetID() then
		local viewing = player:GetCulture()
		local lines = SentientSystems_GetTooltipLines(viewing:GetTouristsFromTooltip(id))

		details.touristsFromYou = viewing:GetTouristsFrom(id)
		details.tourismBreakdown = #lines > 0 and lines or nil
	end

	if met then
		-- The tab checks for the call, so older versions may lack it.
		local turns = culture.GetTurnsUntilVictory ~= nil and culture:GetTurnsUntilVictory() or -1

		details.turnsToVictory = turns > 0 and turns or nil

		for key, value in pairs(GetDominance(player, other)) do
			details[key] = value
		end
	end

	return details
end

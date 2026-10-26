-- The envoy choice: the city-states the player can send envoys to, as the City-States screen's
-- send mode offers them. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetEnvoyChoices(player) returns a table that encodes as
-- '{"cityStates":[12,13,14,15],"tokens":4}', on one line. The checks follow GetData and
-- RealizeEnvoyChangeButtons in CityStates.lua.

-- Returns the envoy choice: tokens, the envoys the player can send, and cityStates, the IDs of the
-- city-states that can take one now, in the game's order. The screen's buttons allow a city-state
-- the player has met and isn't at war with. Returns nil unless the player can send envoys and some
-- city-state can take one. See GetData in CityStates.lua, lines 1411 to 1500, and
-- RealizeEnvoyChangeButtons, lines 667 to 701.
function SentientSystems_GetEnvoyChoices(player)
	local influence = player:GetInfluence()
	local tokens = influence:GetTokensToGive()
	local cityStates = {}

	if not influence:CanGiveInfluence() or tokens <= 0 then
		return nil
	end

	for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
		if influence:CanGiveTokensToPlayer(minor:GetID()) then
			cityStates[#cityStates + 1] = minor:GetID()
		end
	end

	if #cityStates == 0 then
		return nil
	end

	return { tokens = tokens, cityStates = cityStates }
end

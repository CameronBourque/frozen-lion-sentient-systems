-- The envoy choice: the city-states the player can send envoys to, as the
-- City-States screen offers them. Follows GetData in CityStates.lua.
-- Shape: bridge/src/choices/envoys.ts.

-- Returns the envoy choice. The screen's buttons allow a city-state the player
-- has met and isn't at war with. Returns nil unless the player can send envoys
-- and some city-state can take one. See GetData in CityStates.lua, and
-- RealizeEnvoyChangeButtons.
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

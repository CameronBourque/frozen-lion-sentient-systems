-- Player requests. Fakes PlayerOperations and UI.RequestPlayerOperation, which
-- the research, policy, and religion actions send.

return function(env)
	env.PlayerOperations = {
		RESEARCH = 11,
		PROGRESS_CIVIC = 12,
		PARAM_TECH_TYPE = 13,
		PARAM_CIVIC_TYPE = 14,
		PARAM_INSERT_MODE = 15,
		VALUE_EXCLUSIVE = 16,
		VALUE_APPEND = 17,
		UNLOCK_POLICIES = 18,
		FOUND_PANTHEON = 19,
		PARAM_BELIEF_TYPE = 20,
	}
	env.UI = env.UI or {}

	-- Each player operation goes in env.requests.
	env.UI.RequestPlayerOperation = function(playerID, operation, parameters)
		env.requests[#env.requests + 1] = { player = playerID, operation = operation, parameters = parameters }
	end
end

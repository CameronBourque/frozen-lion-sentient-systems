-- Player requests. Fakes PlayerOperations and UI.RequestPlayerOperation, which
-- the research, policy, religion, and great person actions send.

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
		RECRUIT_GREAT_PERSON = 21,
		REJECT_GREAT_PERSON = 22,
		PATRONIZE_GREAT_PERSON = 23,
		PARAM_GREAT_PERSON_INDIVIDUAL_TYPE = 24,
		PARAM_YIELD_TYPE = 25,
	}
	env.UI = env.UI or {}

	-- Each player operation goes in env.requests.
	env.UI.RequestPlayerOperation = function(playerID, operation, parameters)
		env.requests[#env.requests + 1] = { player = playerID, operation = operation, parameters = parameters }
	end
end

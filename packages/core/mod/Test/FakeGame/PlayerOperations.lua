-- Player requests. Fakes PlayerOperations and UI.RequestPlayerOperation, which
-- the research, policy, religion, great person, governor, envoy, and great work
-- actions send.

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
		FOUND_RELIGION = 26,
		ADD_BELIEF = 27,
		PARAM_RELIGION_TYPE = 28,
		PARAM_RELIGION_CUSTOM_NAME = 29,
		APPOINT_GOVERNOR = 30,
		PROMOTE_GOVERNOR = 31,
		ASSIGN_GOVERNOR = 32,
		PARAM_GOVERNOR_TYPE = 33,
		PARAM_GOVERNOR_PROMOTION_TYPE = 34,
		PARAM_PLAYER_ONE = 35,
		PARAM_CITY_DEST = 36,
		GIVE_INFLUENCE_TOKEN = 37,
		MOVE_GREAT_WORK = 38,
		PARAM_CITY_SRC = 39,
		PARAM_BUILDING_SRC = 40,
		PARAM_BUILDING_DEST = 41,
		PARAM_GREAT_WORK_INDEX = 42,
		PARAM_SLOT = 43,
	}
	env.UI = env.UI or {}

	-- Each player operation goes in env.requests.
	env.UI.RequestPlayerOperation = function(playerID, operation, parameters)
		env.requests[#env.requests + 1] = { player = playerID, operation = operation, parameters = parameters }
	end
end

-- The end of the turn. Fakes ActionTypes and UI.RequestAction, which the end
-- turn action sends.

return function(env)
	env.ActionTypes = { ACTION_ENDTURN = 61 }
	env.UI = env.UI or {}

	-- Each action request goes in env.requests.
	env.UI.RequestAction = function(action)
		env.requests[#env.requests + 1] = { action = action }
	end
end

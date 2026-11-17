-- Locale. Fakes Locale.Lookup, which returns a key with no text as it is,
-- Locale.HasTextKey, and Locale.ToUpper.

return function(env, world, ctx)
	local text = world.text or {}

	env.Locale = {
		-- With arguments, the text is followed by them in parentheses, so a
		-- test can check them.
		Lookup = function(key, ...)
			local arguments = { ... }

			if #arguments == 0 then
				return text[key] or key
			end

			for i, argument in ipairs(arguments) do
				arguments[i] = tostring(argument)
			end

			return (text[key] or key) .. "(" .. table.concat(arguments, ",") .. ")"
		end,
		HasTextKey = function(key)
			return text[key] ~= nil
		end,
		ToUpper = function(key)
			return (text[key] or key):upper()
		end,
	}
end

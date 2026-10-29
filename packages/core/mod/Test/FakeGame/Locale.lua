-- Locale. world.text maps each LOC_ key to its text. Locale.Lookup returns any other key as it is.

return function(env, world, ctx)
	local text = world.text or {}

	env.Locale = {
		-- With arguments, the text is followed by them in parentheses, such as "KEY(5)", so a test
		-- can check them.
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
	}
end

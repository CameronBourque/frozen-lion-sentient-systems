-- A city's power. Fakes the Power tab's calls for a city with power set, which
-- has the usable and required power and the sources of each. Without it the
-- city's GetPower returns nil, as without Gathering Storm.

return function(_, _, ctx)
	-- Returns the game's list of a breakdown: one table for each source, with
	-- the text of the source as its only key.
	local function Lines(sources)
		local lines = {}

		for i, source in ipairs(sources or {}) do
			lines[i] = { [source.name] = source.power }
		end

		return lines
	end

	ctx.OnCity(function(city, data)
		local power = data.power

		function city.GetPower()
			if power == nil then
				return nil
			end

			return {
				GetFreePower = function()
					return power.free or 0
				end,
				GetTemporaryPower = function()
					return power.temporary or 0
				end,
				GetRequiredPower = function()
					return power.required or 0
				end,
				IsFullyPowered = function()
					return power.powered ~= false
				end,
				IsFullyPoweredByActiveProject = function()
					return power.project == true
				end,
				GetFreePowerSources = function()
					return Lines(power.freeSources)
				end,
				GetTemporaryPowerSources = function()
					return Lines(power.temporarySources)
				end,
				GetRequiredPowerSources = function()
					return Lines(power.requiredSources)
				end,
				GetGeneratedPowerSources = function()
					return Lines(power.generatedSources)
				end,
			}
		end
	end)
end

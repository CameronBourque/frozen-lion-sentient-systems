-- Number helpers that the state and the choices share.

-- Returns the number rounded half up to a number of decimal places, or to a
-- whole number when places is left out.
function SentientSystems_Round(number, places)
	local scale = 10 ^ (places or 0)

	return math.floor(number * scale + 0.5) / scale
end

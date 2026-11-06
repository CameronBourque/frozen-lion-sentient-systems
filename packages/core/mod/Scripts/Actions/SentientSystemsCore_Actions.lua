-- The result every action returns to the bridge, as JSON. See
-- docs/design/core/mod/actions.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Json")

-- Runs an action and returns its result as JSON for the bridge. The action
-- returns nil when it worked, and the reason it failed as text otherwise. A
-- Lua error in it comes back as a failure too, with the error's first line.
function SentientSystems_RunAction(name, action)
	local ok, reason = pcall(action)

	if not ok then
		reason = name .. " failed: " .. tostring(reason):match("[^\n]*")
	end

	if reason == nil then
		return SentientSystems_EncodeJson({ ok = true })
	end

	return SentientSystems_EncodeJson({ ok = false, reason = tostring(reason) })
end

SentientSystems_Include("SentientSystemsCore_ActionsUnits")
SentientSystems_Include("SentientSystemsCore_ActionsCities")
SentientSystems_Include("SentientSystemsCore_ActionsTrade")

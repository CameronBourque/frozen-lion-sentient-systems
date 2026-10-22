-- The core mod's UI script. It runs in its own UI Lua state, where the request functions work.

include("SentientSystemsCore_Tag")

-- The id attribute in SentientSystemsCore.modinfo.
local MOD_ID = "5D4B5856-E71F-492C-A434-A0938AF49451"

-- Prints "[SENTIENTSYSTEMS] CORE_VERSION <version>" and returns the version. The version comes
-- from <Properties><Version> in the .modinfo. Gameplay states have no Modding, so only a UI
-- state can read it.
function SentientSystems_GetVersion()
	local version = nil

	for _, mod in ipairs(Modding.GetActiveMods()) do
		if mod.Id:upper() == MOD_ID then
			version = Modding.GetModProperty(mod.Handle, "Version")
			break
		end
	end

	SentientSystems_Print("CORE_VERSION", version)

	return version
end

print("SentientSystemsCore_UI loaded, context is " .. ContextPtr:GetID())

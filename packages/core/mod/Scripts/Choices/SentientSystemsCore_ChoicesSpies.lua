-- The spy choice: escape routes for the next escaping spy, as the escape
-- screen offers them. Follows OnOpen in EspionageEscape.lua.
-- Shape: bridge/src/choices/spies.ts.

SentientSystems_Include("SentientSystemsCore_Espionage")

-- Returns the spy choice: the next escaping spy. Returns nil with no escaping
-- spy.
function SentientSystems_GetSpyChoices(player)
	local escape = SentientSystems_GetNextEscape(player)

	if escape == nil then
		return nil
	end

	local spy, city = escape.spy, escape.city
	local pursuer = spy:GetPursuingSpyName()

	return {
		{
			spy = spy:GetID(),
			name = Locale.Lookup(spy:GetName()),
			city = { owner = city:GetOwner(), id = city:GetID(), name = Locale.Lookup(city:GetName()) },
			loot = SentientSystems_LookupText(spy:GetLootName()),
			pursuer = pursuer == "" and SentientSystems_LookupText("LOC_ESPIONAGE_ESCAPE_PURSUIT_POLICE") or SentientSystems_LookupText("LOC_ESPIONAGE_ESCAPE_PURSUIT_COUNTERSPY", pursuer),
			description = SentientSystems_LookupText("LOC_ESPIONAGE_ESCAPE_TOOLTIP"),
			routes = escape.routes,
		},
	}
end

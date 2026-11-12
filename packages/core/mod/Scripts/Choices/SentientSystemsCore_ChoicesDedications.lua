-- The dedication choice, as the dedication popup offers it. Follows
-- OnGameEraChanged and CreateCommemoration in DedicationPopup.lua.
-- Shape: bridge/src/choices/dedications.ts.

SentientSystems_Include("SentientSystemsCore_Eras")

-- Returns the dedication choice. Returns nil with no dedication to make.
function SentientSystems_GetDedicationChoices(player)
	local pending = SentientSystems_GetPendingDedication(player)

	if pending == nil then
		return nil
	end

	local eras = pending.eras
	local options = {}

	for i, row in ipairs(pending.rows) do
		options[i] = {
			type = row.CommemorationType,
			name = Locale.Lookup(row.CategoryDescription),
			description = SentientSystems_GetDedicationText(eras, player:GetID(), row, pending.age),
		}
	end

	return {
		era = Locale.Lookup(GameInfo.Eras[eras:GetCurrentEra()].Name),
		age = pending.age,
		picks = pending.picks,
		options = options,
	}
end

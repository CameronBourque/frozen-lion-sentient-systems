-- The Great People screen's rules that the great people state and the great
-- person actions share. Follows AddRecruit in GreatPeoplePopup.lua.

include("SentientSystemsCore_Common")

-- The screen hides a patronage cost at or above this, which the game gives a
-- great person the player can't earn.
local MAX_PATRONAGE_COST = 1000000

-- The patronage yields, each with the capability the screen checks for its
-- button.
SENTIENTSYSTEMS_PATRONAGE = {
	{ key = "gold", yield = "GOLD", capability = "CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_GOLD" },
	{ key = "faith", yield = "FAITH", capability = "CAPABILITY_GREAT_PEOPLE_RECRUIT_WITH_FAITH" },
}

-- Returns whether the screen turns off its patronage buttons, as Gathering
-- Storm's does while the World Congress is in session. See IsReadOnly in
-- GreatPeoplePopup_Expansion2.lua.
function SentientSystems_IsPatronageClosed()
	return SentientSystems_HasExpansion2() and Game.GetWorldCongress():IsInSession()
end

-- Returns the patronage costs of a great person, gold and faith. The screen
-- shows a button only while the player can neither recruit nor pass the person.
-- Returns nil when it shows neither. See AddRecruit in GreatPeoplePopup.lua.
function SentientSystems_GetPatronage(greatPeople, playerID, individual)
	if greatPeople:CanRecruitPerson(playerID, individual) or greatPeople:CanRejectPerson(playerID, individual) then
		return nil
	end

	local closed = SentientSystems_IsPatronageClosed()
	local patronage

	for _, entry in ipairs(SENTIENTSYSTEMS_PATRONAGE) do
		local yield = YieldTypes[entry.yield]
		local cost = greatPeople:GetPatronizeCost(playerID, individual, yield)

		if GameCapabilities.HasCapability(entry.capability) and cost < MAX_PATRONAGE_COST then
			patronage = patronage or {}
			patronage[entry.key] = { cost = cost, can = greatPeople:CanPatronizePerson(playerID, individual, yield) and not closed }
		end
	end

	return patronage
end

-- The religion section of the state: the player's pantheon, their progress toward a religion, and
-- the religion they founded with its followers, as the religion screen's My Religion tab shows them.
-- SentientSystemsCore_State.lua loads this file. Example: SentientSystems_GetReligionState(player)
-- returns a table that encodes as '{"founded":{"beliefs":["BELIEF_TITHE"],"cities":[{"city":65536,
-- "followers":5,"owner":0}],"holyCity":65536,"majority":1,"name":"Buddhism",
-- "type":"RELIGION_BUDDHISM"},"pantheon":"BELIEF_GOD_OF_THE_SEA"}', on one line. The checks follow
-- ViewMyReligion and ViewReligion in ReligionScreen.lua.

-- Returns the religion the player founded, with its type, name, beliefs, holy city, majority, the
-- count of cities where it is the majority, and cities, each city where it has followers, from
-- every living player, as the screen's cities panel lists them. Returns nil before the player
-- founds one. See ViewReligion in ReligionScreen.lua, lines 964 to 1170.
local function GetFounded(religion)
	local religionType = religion:GetReligionTypeCreated()

	if religionType < 0 then
		return nil
	end

	local founded = {
		type = GameInfo.Religions[religionType].ReligionType,
		name = Locale.Lookup(Game.GetReligion():GetName(religionType)),
		beliefs = {},
		majority = 0,
		cities = {},
	}

	for _, entry in ipairs(Game.GetReligion():GetReligions()) do
		if entry.Religion == religionType then
			for _, beliefIndex in ipairs(entry.Beliefs) do
				founded.beliefs[#founded.beliefs + 1] = GameInfo.Beliefs[beliefIndex].BeliefType
			end
		end
	end

	local holyCity = CityManager.GetCity(religion:GetHolyCityID())

	founded.holyCity = holyCity and holyCity:GetID()

	for _, owner in ipairs(PlayerManager.GetAlive()) do
		for _, city in owner:GetCities():Members() do
			local cityReligion = city:GetReligion()

			if cityReligion:GetMajorityReligion() == religionType then
				founded.majority = founded.majority + 1
			end

			for _, present in ipairs(cityReligion:GetReligionsInCity()) do
				if present.Religion == religionType and present.Followers > 0 then
					founded.cities[#founded.cities + 1] = { owner = owner:GetID(), city = city:GetID(), followers = present.Followers }
				end
			end
		end
	end

	return founded
end

-- Returns the religion section: pantheon, the type of the player's pantheon belief, or
-- pantheonFaith, the faith the next pantheon needs, before the player has one; prophet, whether the
-- player has a Great Prophet, between their pantheon and their first belief; and founded, the
-- religion they founded. See ViewMyReligion, WorkingTowardsPantheon, and WorkingTowardsReligion in
-- ReligionScreen.lua, lines 308 to 403.
function SentientSystems_GetReligionState(player)
	local religion = player:GetReligion()
	local pantheon = religion:GetPantheon()
	local state = { founded = GetFounded(religion) }

	if pantheon < 0 then
		state.pantheonFaith = Game.GetReligion():GetMinimumFaithNextPantheon()
	else
		state.pantheon = GameInfo.Beliefs[pantheon].BeliefType

		if religion:GetNumBeliefsEarned() == 0 then
			state.prophet = religion:HasReligiousFoundingUnit()
		end
	end

	return state
end

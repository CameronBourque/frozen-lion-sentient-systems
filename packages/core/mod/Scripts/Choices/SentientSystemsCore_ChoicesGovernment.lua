-- The government choice: the player's government, its policy slots, and the policy in each slot, as
-- the government screen's My Government tab shows them. SentientSystemsCore_Choices.lua loads this
-- file. Example: SentientSystems_GetGovernmentChoices(player) returns a table that encodes as
-- '{"slots":[{"slot":0,"type":"SLOT_MILITARY"},{"policy":"POLICY_GOD_KING","slot":1,
-- "type":"SLOT_ECONOMIC"}],"type":"GOVERNMENT_CHIEFDOM"}', on one line. The checks follow
-- PopulateLivePlayerData in GovernmentScreen.lua.

-- Returns the player's government, with type, its type, left out when the player has none, before
-- Code of Laws or in anarchy, and slots, each policy slot in the game's order. Each slot has slot,
-- its index, which the game's policy changes take, type, and policy, left out for an empty slot.
-- See PopulateLivePlayerData in GovernmentScreen.lua, lines 2250 to 2318.
function SentientSystems_GetGovernmentChoices(player)
	local culture = player:GetCulture()
	local governmentIndex = culture:GetCurrentGovernment()
	local slots = {}

	for i = 0, culture:GetNumPolicySlots() - 1 do
		local slot = { slot = i, type = GameInfo.GovernmentSlots[culture:GetSlotType(i)].GovernmentSlotType }
		local policyIndex = culture:GetSlotPolicy(i)

		if policyIndex ~= -1 then
			slot.policy = GameInfo.Policies[policyIndex].PolicyType
		end

		slots[#slots + 1] = slot
	end

	return {
		type = governmentIndex ~= -1 and GameInfo.Governments[governmentIndex].GovernmentType or nil,
		slots = slots,
	}
end

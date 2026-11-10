-- The policy actions. SentientSystemsCore_Actions.lua loads this file. The
-- calls are in docs/findings/actions/policies.md.

SentientSystems_Include("SentientSystemsCore_Government")

-- Returns the row of the screen that a slot type or a policy's slot type goes
-- in. A great person slot or policy goes in the wildcard row. See
-- IsSlotTypeLegalInRow in GovernmentScreen.lua.
local function GetPolicyRow(slotType)
	return slotType == "SLOT_GREAT_PERSON" and "SLOT_WILDCARD" or slotType
end

-- Returns why the slots don't list each of the player's count slots, from 0,
-- once, with a policy type or false, or nil when they do.
local function GetSlotListFailure(slots, count)
	local reason = "Give a policy, or none, for each of your " .. count .. " slots, 0 to " .. (count - 1) .. ", as the government choice lists them."

	if type(slots) ~= "table" then
		return reason
	end

	for slot in pairs(slots) do
		if type(slot) ~= "number" or slot % 1 ~= 0 or slot < 0 or slot >= count then
			return reason
		end
	end

	for slot = 0, count - 1 do
		if slots[slot] == nil then
			return reason
		end
	end

	return nil
end

-- Returns the row of the policy for the slot, or nil for an empty slot, or nil
-- and why the slot can't hold it. A policy can stay in a slot or move to
-- another, so one in a slot counts as one the player can slot. seen holds the
-- policies of the slots before it.
local function FindSlotPolicy(culture, slot, typeName, seen)
	if typeName == false then
		return nil, nil
	end

	local row = type(typeName) == "string" and GameInfo.Policies[typeName] or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a policy. Use the type of a policy from the policies choice, or of one in a slot."
	end

	if not culture:IsPolicyActive(row.Hash) and not SentientSystems_IsPolicyAvailable(culture, row.Hash) then
		return nil, typeName .. " isn't one of the policies you can slot. Use a policy from the policies choice, or one in a slot."
	end

	if seen[typeName] then
		return nil, typeName .. " is in more than one slot."
	end

	local slotType = GameInfo.GovernmentSlots[culture:GetSlotType(slot)].GovernmentSlotType
	local slotRow = GetPolicyRow(slotType)

	if slotRow ~= "SLOT_WILDCARD" and slotRow ~= GetPolicyRow(row.GovernmentSlotType) then
		return nil, "Slot " .. slot .. " is a " .. slotType .. " slot, which can't hold " .. typeName .. ", a " .. row.GovernmentSlotType .. " policy."
	end

	seen[typeName] = true

	return row, nil
end

-- Returns the hash of the policy for each slot, by slot, and whether any slot
-- changes, or nil and why a slot can't hold its policy.
local function GetSlotHashes(culture, slots, count)
	local hashes, changed, seen = {}, false, {}

	for slot = 0, count - 1 do
		local row, failure = FindSlotPolicy(culture, slot, slots[slot], seen)

		if failure ~= nil then
			return nil, false, failure
		end

		hashes[slot] = row and row.Hash
		changed = changed or (row and row.Index or -1) ~= culture:GetSlotPolicy(slot)
	end

	return hashes, changed, nil
end

-- Sends the screen's request: clear every slot, then add each slot's policy.
-- The screen clears first so that a policy can move between slots. See
-- OnConfirmPolicies in GovernmentScreen.lua.
local function RequestPolicies(culture, hashes, count)
	local clearList = {}

	for slot = 0, count - 1 do
		clearList[#clearList + 1] = slot
	end

	culture:RequestPolicyChanges(clearList, hashes)
end

local function SetPolicies(playerID, slots)
	local culture = SentientSystems_GetPlayer(playerID):GetCulture()
	local failure = SentientSystems_GetPolicyChangeFailure(playerID, culture)

	if failure ~= nil then
		return failure
	end

	local count = culture:GetNumPolicySlots()

	failure = GetSlotListFailure(slots, count)

	if failure ~= nil then
		return failure
	end

	local hashes, changed

	hashes, changed, failure = GetSlotHashes(culture, slots, count)

	if failure ~= nil then
		return failure
	end

	-- A request marks the turn's change as made, so none goes out for nothing.
	if not changed then
		return "Your slots hold those policies already."
	end

	RequestPolicies(culture, hashes, count)

	return nil
end

-- Sets the policy in every slot of the player's government, and returns the
-- result as JSON. slots holds a policy type, or false for an empty slot, for
-- each slot by its number in the government choice, from 0. The game takes a
-- policy in the wrong slot type, or a change at any time, so the action checks
-- every slot first, as the screen does.
function SentientSystems_SetPolicies(playerID, slots)
	return SentientSystems_RunAction("SetPolicies", SetPolicies, playerID, slots)
end

-- Returns why the player can't pay the unlock, or nil when they can. The
-- action takes the unlock when the policies tab or the View Governments tab
-- shows it. The policies tab hides it after a policy change this turn.
local function GetUnlockFailure(playerID)
	if not Game.IsAllowStrategicCommands(playerID) then
		return "You can't pay the unlock while it isn't your turn."
	end

	local player = SentientSystems_GetPlayer(playerID)
	local culture = player:GetCulture()
	local governmentsHidden = SentientSystems_IsGovernmentUnlockHidden(culture)

	if culture:PolicyChangeMade() and governmentsHidden and culture:GetCostToUnlockPolicies() > 0 then
		return "You changed policies this turn already, and the governments choice has no unlock."
	end

	local unlock = SentientSystems_GetUnlock(player, culture, culture:PolicyChangeMade() and governmentsHidden)

	if unlock == nil then
		return "There's no unlock to pay for now."
	end

	if unlock.blocked == nil then
		return nil
	end

	if #unlock.blocked == 0 then
		return "You can't pay the unlock while the World Congress is in session."
	end

	local yield = unlock.yield == "YIELD_FAITH" and "faith" or "gold"

	return "You can't afford the unlock's " .. unlock.cost .. " " .. yield .. "."
end

-- Sends the unlock button's request. See OnUnlockPolicies in
-- GovernmentScreen.lua.
local function UnlockPolicies(playerID)
	local failure = GetUnlockFailure(playerID)

	if failure ~= nil then
		return failure
	end

	UI.RequestPlayerOperation(playerID, PlayerOperations.UNLOCK_POLICIES, {})

	return nil
end

-- Pays the gold or faith that lets the player change policies and the
-- government on a turn with no civic completed, as the unlock buttons do, and
-- returns the result as JSON. The policies and governments choices' unlock
-- gives the cost.
function SentientSystems_UnlockPolicies(playerID)
	return SentientSystems_RunAction("UnlockPolicies", UnlockPolicies, playerID)
end

-- Returns the row of the government to change to, or nil and why the player
-- can't change to it.
local function FindGovernment(culture, typeName)
	local row = type(typeName) == "string" and GameInfo.Governments[typeName] or nil

	if row == nil then
		return nil, tostring(typeName) .. " isn't a government. Use a type from the governments choice."
	end

	if row.Index == culture:GetCurrentGovernment() then
		return nil, typeName .. " is your government already."
	end

	if not culture:IsGovernmentUnlocked(row.Hash) then
		return nil, typeName .. " isn't unlocked yet. The governments choice gives the civic it needs."
	end

	return row, nil
end

-- Sends the screen's request once the player confirms the change. See
-- OnGovernmentSelected in GovernmentScreen.lua, and OnAcceptGovernmentChange.
local function SetGovernment(playerID, typeName)
	local culture = SentientSystems_GetPlayer(playerID):GetCulture()
	local failure = SentientSystems_GetGovernmentChangeFailure(playerID, culture)

	if failure ~= nil then
		return failure
	end

	local row

	row, failure = FindGovernment(culture, typeName)

	if failure ~= nil then
		return failure
	end

	if not culture:RequestChangeGovernment(row.Hash) then
		return "The game refused the change to " .. typeName .. "."
	end

	return nil
end

-- Changes the player's government, as the View Governments tab does, and
-- returns the result as JSON. government is a type from the governments
-- choice. A government with anarchy turns starts after them.
function SentientSystems_SetGovernment(playerID, government)
	return SentientSystems_RunAction("SetGovernment", SetGovernment, playerID, government)
end

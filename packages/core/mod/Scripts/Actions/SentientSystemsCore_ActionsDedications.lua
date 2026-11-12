-- The dedication action on the dedication popup.
-- SentientSystemsCore_Actions.lua loads this file. The call is in
-- docs/findings/actions/dedications.md.

SentientSystems_Include("SentientSystemsCore_Eras")

-- Returns the offered row with the type, or nil.
local function FindDedicationRow(pending, type)
	for _, row in ipairs(pending.rows) do
		if row.CommemorationType == type then
			return row
		end
	end

	return nil
end

-- Returns the offered types, as a reason lists them.
local function ListDedications(pending)
	local types = {}

	for i, row in ipairs(pending.rows) do
		types[i] = row.CommemorationType
	end

	return table.concat(types, ", ")
end

-- Returns why the dedications can't be made, or nil. The popup enables
-- Confirm only once the player has picked as many as the age allows, each one
-- of the offered dedications. See OnCommemorationClicked and OnConfirm.
local function GetDedicationsFailure(pending, dedications)
	if pending == nil then
		return "You have no dedication to make. The dedications choice lists one when an era begins."
	end

	if type(dedications) ~= "table" then
		return "The dedications are a list of types from the dedications choice."
	end

	local seen = {}

	for _, dedication in ipairs(dedications) do
		if FindDedicationRow(pending, dedication) == nil then
			return tostring(dedication) .. " isn't a dedication you can make. Use one of " .. ListDedications(pending) .. "."
		end

		if seen[dedication] then
			return "You chose " .. dedication .. " twice. Choose each dedication once."
		end

		seen[dedication] = true
	end

	if #dedications ~= pending.picks then
		local noun = pending.picks == 1 and " dedication" or " dedications"

		return "Choose " .. pending.picks .. noun .. ", not " .. #dedications .. "."
	end

	return nil
end

local function ChooseDedications(playerID, dedications)
	local pending = SentientSystems_GetPendingDedication(SentientSystems_GetPlayer(playerID))
	local failure = GetDedicationsFailure(pending, dedications)

	if failure ~= nil then
		return failure
	end

	local P = PlayerOperations

	-- Confirm sends each pick with its row's index. See OnConfirm.
	for _, dedication in ipairs(dedications) do
		local params = { [P.PARAM_COMMEMORATION_TYPE] = FindDedicationRow(pending, dedication).Index }

		UI.RequestPlayerOperation(playerID, P.COMMEMORATE, params)
	end

	return nil
end

-- Makes the era's dedications, a list of types from the dedications choice
-- with as many as its picks, and returns the result as JSON.
function SentientSystems_ChooseDedications(playerID, dedications)
	return SentientSystems_RunAction("ChooseDedications", ChooseDedications, playerID, dedications)
end

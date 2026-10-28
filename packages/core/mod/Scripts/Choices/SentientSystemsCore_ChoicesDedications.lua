-- The dedication choice: the dedications the player may make for the era that began, as the
-- dedication popup offers them. SentientSystemsCore_Choices.lua loads this file. Example:
-- SentientSystems_GetDedicationChoices(player) returns a table that encodes as
-- '{"age":"golden","era":"Classical Era","options":[{"description":"Free Inquiry Golden Age:\n...",
-- "name":"Free Inquiry","type":"COMMEMORATION_SCIENTIFIC"}],"picks":1}', on one line. The checks
-- follow OnGameEraChanged and CreateCommemoration in DedicationPopup.lua.

-- Returns the player's age for the era that ended, as the popup decides it: heroic before golden,
-- and golden before dark.
local function GetAge(eras, playerID)
	if eras:HasHeroicGoldenAge(playerID) then
		return "heroic"
	elseif eras:HasGoldenAge(playerID) then
		return "golden"
	elseif eras:HasDarkAge(playerID) then
		return "dark"
	end

	return "normal"
end

-- Returns the text of a dedication for the age: the golden text, with the normal text after it for a
-- player always allowed the normal bonus, in a golden age, the dark text in a dark age, and the
-- normal text otherwise, as the popup shows it. A heroic age counts as golden.
local function GetDescription(eras, playerID, row, age)
	if age == "heroic" or age == "golden" then
		local text = Locale.Lookup(row.GoldenAgeBonusDescription)

		if eras:IsPlayerAlwaysAllowedCommemorationQuest(playerID) then
			text = text .. "[NEWLINE]" .. Locale.Lookup(row.NormalAgeBonusDescription)
		end

		return text
	elseif age == "dark" then
		return Locale.Lookup(row.DarkAgeBonusDescription)
	end

	return Locale.Lookup(row.NormalAgeBonusDescription)
end

-- Returns the dedication choice: era, the name of the era that began, age, heroic, golden, dark, or
-- normal, picks, how many dedications the player must make, and options, each with type, the type
-- the choice sends, name, the popup's category text, and description, its bonus for the age.
-- Returns nil with no dedication to make. The calls read the era's choices only while the blocker is
-- up, as the spy choice must. See DedicationPopup.lua, lines 25 to 120.
function SentientSystems_GetDedicationChoices(player)
	local playerID = player:GetID()

	if not SentientSystems_HasBlocker(playerID, "ENDTURN_BLOCKING_COMMEMORATION_AVAILABLE") then
		return nil
	end

	local eras = Game.GetEras()
	local picks = eras:GetPlayerNumAllowedCommemorations(playerID)
	local age = GetAge(eras, playerID)
	local options = {}

	for _, index in ipairs(eras:GetPlayerCommemorateChoices(playerID)) do
		local row = GameInfo.CommemorationTypes[index]

		options[#options + 1] = {
			type = row.CommemorationType,
			name = Locale.Lookup(row.CategoryDescription),
			description = GetDescription(eras, playerID, row, age),
		}
	end

	if picks <= 0 or #options == 0 then
		return nil
	end

	return {
		era = Locale.Lookup(GameInfo.Eras[eras:GetCurrentEra()].Name),
		age = age,
		picks = picks,
		options = options,
	}
end

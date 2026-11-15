-- What a popup that the core mod closes would have told the player, kept for
-- the agent's next turn: units captured and rock band concerts. See
-- docs/design/core/mod/state.md.

include("SentientSystemsCore_Common")
SentientSystems_Include("SentientSystemsCore_Text")

-- The events of every player, oldest first. A global, so including this file
-- again keeps them. They are lost when the game loads.
SentientSystems_EventMessages = SentientSystems_EventMessages or {}

-- The lines of a concert's result after its tourism and albums, as
-- RockBandPopup.lua shows them. band is the unit's rock band, or nil.
local CONCERT_OUTCOMES = {
	{
		key = "LOC_ROCK_CONCERT_RESULT_PROMOTION",
		applies = function(result, band)
			return result.ExtraPromotion and band ~= nil and not band:IsMaxPromotions()
		end,
	},
	{
		key = "LOC_ROCK_CONCERT_RESULT_LEVEL_UP",
		applies = function(result, band)
			return result.GainsLevel and band ~= nil and not band:IsMaxLevel()
		end,
	},
	{
		key = "LOC_ROCK_CONCERT_RESULT_UNIT_LOST",
		applies = function(result)
			return result.Dies
		end,
	},
}

local function AddEventMessage(playerID, kind, text)
	SentientSystems_EventMessages = SentientSystems_AddRecent(SentientSystems_EventMessages, {
		player = playerID,
		turn = Game.GetCurrentGameTurn(),
		kind = kind,
		text = text,
	})
end

local function GetCivShortName(playerID)
	local config = PlayerConfigurations[playerID]

	return config ~= nil and config:GetCivilizationShortDescription() or ""
end

-- Keeps the message of a unit of the player's that another player captured,
-- as OnUnitCaptured in UnitCaptured.lua words it. The event's unit ID doesn't
-- find the unit under its new owner, so the message can't name it.
function SentientSystems_NoteUnitLost(playerID, capturerID)
	AddEventMessage(playerID, "unitLost", SentientSystems_LookupText("LOC_UNIT_CAPTURED", GetCivShortName(capturerID)))
end

-- Keeps the message of a unit the player captured from another player.
function SentientSystems_NoteUnitCaptured(playerID, ownerID)
	AddEventMessage(playerID, "unitCaptured", SentientSystems_LookupText("LOC_CAPTURE_UNIT", GetCivShortName(ownerID)))
end

-- Keeps the result of a rock band's concert, as RockBandPopup.lua shows it.
-- Call it from PostTourismBomb, while the band is still on the map.
function SentientSystems_NoteConcert(playerID, unitID, resultID, tourism)
	local result = GameInfo.Unit_RockbandResults_XP2[resultID]

	if result == nil then
		return
	end

	local unit = Players[playerID]:GetUnits():FindID(unitID)
	local band = unit and unit:GetRockBand()
	local lines = {
		SentientSystems_LookupText(result.Name) .. ": " .. SentientSystems_LookupText(result.Description),
		SentientSystems_LookupText("LOC_ROCK_CONCERT_RESULT_TOURISM") .. ": " .. tourism,
		SentientSystems_LookupText("LOC_ROCK_CONCERT_RESULT_ALBUMS") .. ": " .. result.AlbumSales,
	}

	for _, outcome in ipairs(CONCERT_OUTCOMES) do
		if outcome.applies(result, band) then
			lines[#lines + 1] = SentientSystems_LookupText(outcome.key)
		end
	end

	AddEventMessage(playerID, "concert", table.concat(lines, "\n"))
end

-- Returns the player's events from the previous turn and this one, oldest
-- first. Shape: bridge/src/state/events.ts.
function SentientSystems_GetEventMessages(playerID)
	local turn = Game.GetCurrentGameTurn()
	local list = {}

	for _, message in ipairs(SentientSystems_EventMessages) do
		if message.player == playerID and message.turn >= turn - 1 then
			list[#list + 1] = { turn = message.turn, kind = message.kind, text = message.text }
		end
	end

	return list
end

-- Diplomacy status. A player's diplomacy maps another player's ID to what it
-- has with that player: state, a DIPLO_STATE_ type for how it sees them, access,
-- the visibility level, delegation, embassy, openBorders, from the other player,
-- defensivePact, research, a tech type, jointWar, friendship, the turn it
-- declared one, denounce, the turn it denounced them, and alliance, with type,
-- level, turnsThis, turnsToNext, expires, and perTurn. A player's atWar and
-- met, in FakeGame/Rivals.lua and Envoys.lua, say who it fights and has met,
-- and human is true for a human. The alliance calls need world.era, as Rise and
-- Fall does. world.denounceLimit is the turns a friendship or denouncement
-- lasts, 20 when missing. A player's anarchyUntil is the turn its anarchy ends.
-- Its agendas lists its agenda types, the first historical. What a player has
-- with another also has modifiers, each with Score and Text, and grievances,
-- with balance, perTurn, and log, each entry with Turn, Initiator, Target,
-- Amount, and Description. The grievance calls need world.expansion2.

local STATES = {
	"DIPLO_STATE_ALLIED",
	"DIPLO_STATE_DECLARED_FRIEND",
	"DIPLO_STATE_FRIENDLY",
	"DIPLO_STATE_NEUTRAL",
	"DIPLO_STATE_UNFRIENDLY",
	"DIPLO_STATE_DENOUNCED",
	"DIPLO_STATE_WAR",
}

return function(env, world, ctx)
	local indexes = ctx.indexes

	env.GameInfo.DiplomaticStates = ctx.TypedRows({}, "StateType")
	env.GameInfo.Visibilities = ctx.TypedRows({}, "VisibilityType")
	env.GameInfo.Agendas = ctx.TypedRows({}, "AgendaType")
	env.GameInfo.Alliances = ctx.TypedRows({}, "AllianceType")
	env.GlobalParameters.ALLIANCE_POINTS_MULTIPLIER = 4
	env.Game.GetGameDiplomacy = function()
		local game = {
			GetDenounceTimeLimit = function()
				return world.denounceLimit or 20
			end,
		}

		if world.expansion2 then
			local function Grievances(selectedID, localID)
				return (((world.players[localID].diplomacy or {})[selectedID] or {}).grievances) or {}
			end

			function game.GetGrievanceLogEntries(_, selectedID, localID)
				return Grievances(selectedID, localID).log or {}
			end

			function game.GetGrievanceChangePerTurn(_, selectedID, localID)
				return Grievances(selectedID, localID).perTurn or 0
			end
		end

		return game
	end

	for _, stateType in ipairs(STATES) do
		ctx.AddRow("DiplomaticStates", "StateType", stateType)
		env.GameInfo.DiplomaticStates[indexes[stateType]].Name = "LOC_" .. stateType
	end

	for level = 0, 4 do
		env.GameInfo.Visibilities[level] = {
			Index = level,
			Name = "LOC_VISIBILITY_" .. level,
			RevealAgendas = level == 2,
		}
	end

	for _, data in pairs(world.players or {}) do
		for _, agenda in ipairs(data.agendas or {}) do
			ctx.AddRow("Agendas", "AgendaType", agenda)
			env.GameInfo.Agendas[indexes[agenda]].Name = "LOC_" .. agenda .. "_NAME"
			env.GameInfo.Agendas[indexes[agenda]].Description = "LOC_" .. agenda .. "_DESC"
		end

		for _, with in pairs(data.diplomacy or {}) do
			if with.research then
				ctx.AddRow("Technologies", "TechnologyType", with.research)
			end

			if (with.alliance or {}).type then
				ctx.AddRow("Alliances", "AllianceType", with.alliance.type)
			end
		end
	end

	-- What a player has with another player.
	local function With(data, otherID)
		return (data.diplomacy or {})[otherID] or {}
	end

	local function Contains(list, id)
		for _, value in ipairs(list or {}) do
			if value == id then
				return true
			end
		end

		return false
	end

	ctx.OnPlayer(function(player, data, id)
		local GetDiplomacy, GetCulture = player.GetDiplomacy, player.GetCulture

		function player.GetDiplomacy()
			local diplomacy = GetDiplomacy()

			local function Flag(call, field)
				diplomacy[call] = function(_, otherID)
					return With(data, otherID)[field] == true
				end
			end

			Flag("HasDelegationAt", "delegation")
			Flag("HasEmbassyAt", "embassy")
			Flag("HasOpenBordersFrom", "openBorders")
			Flag("HasDefensivePact", "defensivePact")
			Flag("IsFightingAnyJointWarWith", "jointWar")

			function diplomacy.IsAtWarWith(_, otherID)
				return Contains(data.atWar, otherID)
			end

			function diplomacy.GetVisibilityOn(_, otherID)
				return With(data, otherID).access or 0
			end

			function diplomacy.GetResearchAgreementTech(_, otherID)
				local tech = With(data, otherID).research

				return tech and indexes[tech] or -1
			end

			function diplomacy.GetDeclaredFriendshipTurn(_, otherID)
				return With(data, otherID).friendship or -1
			end

			function diplomacy.GetDenounceTurn(_, otherID)
				return With(data, otherID).denounce or -1
			end

			if world.expansion2 then
				function diplomacy.GetGrievancesAgainst(_, otherID)
					return (With(data, otherID).grievances or {}).balance or 0
				end
			end

			if world.era then
				local function Alliance(otherID)
					return With(data, otherID).alliance or {}
				end

				function diplomacy.GetAllianceLevel(_, otherID)
					return Alliance(otherID).level or 1
				end

				function diplomacy.GetAllianceType(_, otherID)
					local type = Alliance(otherID).type

					return type and indexes[type] or -1
				end

				for call, field in pairs({
					GetAllianceTurnsThisLevel = "turnsThis",
					GetAllianceTurnsUntilExpiration = "expires",
					GetAlliancePointsPerTurn = "perTurn",
				}) do
					diplomacy[call] = function(_, otherID)
						return Alliance(otherID)[field] or 0
					end
				end

				function diplomacy.GetAllianceTurnsToNextLevel(_, otherID)
					return Alliance(otherID).turnsToNext or 160
				end
			end

			return diplomacy
		end

		function player.GetDiplomaticAI()
			return {
				GetDiplomaticStateIndex = function(_, otherID)
					return indexes[With(data, otherID).state or "DIPLO_STATE_NEUTRAL"]
				end,
				GetDiplomaticModifiers = function(_, otherID)
					return With(data, otherID).modifiers or {}
				end,
			}
		end

		function player.GetAgendaTypes()
			local types = {}

			for i, agenda in ipairs(data.agendas or {}) do
				types[i] = indexes[agenda]
			end

			return types
		end

		function player.GetCulture()
			local culture = GetCulture()

			culture.IsInAnarchy = function()
				return data.anarchyUntil ~= nil
			end
			culture.GetAnarchyEndTurn = function()
				return data.anarchyUntil
			end

			return culture
		end

		env.PlayerConfigurations[id].IsHuman = function()
			return data.human == true
		end
	end)
end

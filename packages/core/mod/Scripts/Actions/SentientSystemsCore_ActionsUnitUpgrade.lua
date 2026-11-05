-- The upgrade order. SentientSystemsCore_ActionsUnits.lua loads this file. The
-- calls are in docs/findings/actions/.

-- Returns the rows of the units the given kind of unit upgrades through, the
-- nearest first. The game upgrades a unit to the last one it can reach.
local function GetChain(unitType)
	local chain = {}
	local current = unitType

	while current ~= nil do
		local nextType

		for row in GameInfo.UnitUpgrades() do
			if row.Unit == current then
				nextType = row.UpgradeUnit
			end
		end

		if nextType ~= nil then
			chain[#chain + 1] = GameInfo.Units[nextType]
		end

		current = nextType
	end

	return chain
end

-- Returns the unit in the chain that needs a tech or civic the player lacks,
-- and the name of that tech or civic. The upgrade needs every unit in the chain
-- to exist, so one missing step blocks it. Returns nil when none is missing.
local function GetMissingPrereq(playerID, chain)
	for _, unit in ipairs(chain) do
		if unit.PrereqTech ~= nil then
			local tech = GameInfo.Technologies[unit.PrereqTech]

			if not Players[playerID]:GetTechs():HasTech(tech.Index) then
				return unit, Locale.Lookup(tech.Name)
			end
		end

		if unit.PrereqCivic ~= nil then
			local civic = GameInfo.Civics[unit.PrereqCivic]

			if not Players[playerID]:GetCulture():HasCivic(civic.Index) then
				return unit, Locale.Lookup(civic.Name)
			end
		end
	end

	return nil
end

-- Returns the reasons the game gives, joined, or nil. The game names the gold
-- and the resources the player lacks and the territory the unit must stand in.
local function GetGameReasons(results)
	local reasons = results and results[UnitCommandResults.FAILURE_REASONS]

	if reasons == nil or #reasons == 0 then
		return nil
	end

	local texts = {}

	for i, reason in ipairs(reasons) do
		texts[i] = Locale.Lookup(reason)
	end

	return table.concat(texts, " ")
end

-- Returns why the unit can't upgrade. The game's loose check fails for a unit
-- with no moves left or a missing tech too, and gives no reason for them. The
-- game's real check names the unit the upgrade makes.
local function GetUpgradeFailure(playerID, unit, results)
	local chain = GetChain(GameInfo.Units[unit:GetUnitType()].UnitType)

	if #chain == 0 then
		return "This kind of unit has no upgrade."
	end

	if unit:GetMovesRemaining() <= 0 then
		return "The unit has no moves left."
	end

	local step, prereq = GetMissingPrereq(playerID, chain)

	if step ~= nil then
		return "The upgrade goes through " .. Locale.Lookup(step.Name) .. ", which needs " .. prereq .. "."
	end

	local reasons = GetGameReasons(results)

	if reasons == nil then
		return "The unit can't upgrade now."
	end

	local becomes = GameInfo.Units[results[UnitCommandResults.UNIT_TYPE]]

	return reasons .. " Upgrading to " .. Locale.Lookup(becomes.Name) .. " costs " .. unit:GetUpgradeCost() .. " gold."
end

-- The panel checks the command loosely first and then for real. A unit that
-- is fortified, asleep, or on alert can still upgrade.
SentientSystems_AddUnitAction("upgrade", function(playerID, unit)
	local canNow, results = UnitManager.CanStartCommand(unit, UnitCommandTypes.UPGRADE, false, true)

	if canNow then
		UnitManager.RequestCommand(unit, UnitCommandTypes.UPGRADE)

		return nil
	end

	return GetUpgradeFailure(playerID, unit, results)
end)

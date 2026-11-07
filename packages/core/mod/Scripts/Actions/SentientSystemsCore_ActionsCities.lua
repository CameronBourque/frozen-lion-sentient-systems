-- The city actions. SentientSystemsCore_Actions.lua loads this file. The calls
-- are in docs/findings/actions/.

-- Returns what the type names: the table of its row, the key of the operation
-- parameter that carries its hash, and whether it needs a tile. nil when the
-- type is no unit, building, district, wonder, or project. A wonder is a
-- building row, so its row says so. See BuildUnit, BuildBuilding, ZoneDistrict,
-- and AdvanceProject in ProductionPanel.lua.
local function FindProductionItem(item)
	if type(item) ~= "string" then
		return nil
	end

	local unit = GameInfo.Units[item]

	if unit then
		return unit, CityOperationTypes.PARAM_UNIT_TYPE, false
	end

	local building = GameInfo.Buildings[item]

	if building then
		return building, CityOperationTypes.PARAM_BUILDING_TYPE, building.RequiresPlacement
	end

	local district = GameInfo.Districts[item]

	if district then
		return district, CityOperationTypes.PARAM_DISTRICT_TYPE, district.RequiresPlacement
	end

	local project = GameInfo.Projects[item]

	if project then
		return project, CityOperationTypes.PARAM_PROJECT_TYPE, false
	end

	return nil
end

-- Replaces what the city is producing with the item, and returns the result as
-- JSON. The item is the type of an option of the production choice, such as
-- UNIT_WARRIOR. A district or a wonder needs a tile, which this doesn't take
-- yet. The panel replaces the current item at position 0 when its queue is
-- closed. See GetBuildInsertMode in ProductionPanel.lua.
function SentientSystems_SetProduction(playerID, cityID, item)
	return SentientSystems_RunAction("SetProduction", function()
		local player = Players[playerID]
		local city = player and player:GetCities():FindID(cityID)

		if city == nil then
			return "Player " .. playerID .. " has no city " .. cityID .. "."
		end

		local row, key, needsTile = FindProductionItem(item)

		if row == nil then
			return tostring(item) .. " isn't a unit, building, district, wonder, or project. Use the type of an option of the production choice."
		end

		local buildQueue = city:GetBuildQueue()
		local checkParams = row.Hash

		if key == CityOperationTypes.PARAM_UNIT_TYPE then
			checkParams = { UnitType = row.Hash, MilitaryFormationType = MilitaryFormationTypes.STANDARD_MILITARY_FORMATION }
		end

		-- The panel lists only what CanProduce allows when it only tests.
		if not buildQueue:CanProduce(checkParams, true) then
			return item .. " isn't one of this city's production choices."
		end

		local canProduce, results = buildQueue:CanProduce(checkParams, false, true)

		if not canProduce then
			local reasons = {}

			for i, reason in ipairs(results and results[CityCommandResults.FAILURE_REASONS] or {}) do
				reasons[i] = SentientSystems_LookupText(reason)
			end

			if #reasons == 0 then
				return "This city can't produce " .. item .. " now."
			end

			return "This city can't produce " .. item .. " now: " .. table.concat(reasons, "; ")
		end

		if needsTile then
			return item .. " goes on a tile, which this action doesn't take yet."
		end

		local parameters = {
			[key] = row.Hash,
			[CityOperationTypes.PARAM_INSERT_MODE] = CityOperationTypes.VALUE_REPLACE_AT,
			[CityOperationTypes.PARAM_QUEUE_DESTINATION_LOCATION] = 0,
		}

		if not CityManager.CanStartOperation(city, CityOperationTypes.BUILD, parameters, true) then
			return "The game won't start " .. item .. " in this city."
		end

		CityManager.RequestOperation(city, CityOperationTypes.BUILD, parameters)

		return nil
	end)
end

-- Orders a city to shoot at a tile in its range, and returns the result as
-- JSON. A city's shot is a city command, and the UI shows no war dialog for it.
function SentientSystems_CityAttack(playerID, cityID, x, y)
	return SentientSystems_RunAction("CityAttack", function()
		local player = Players[playerID]
		local city = player and player:GetCities():FindID(cityID)

		if city == nil then
			return "Player " .. playerID .. " has no city " .. cityID .. "."
		end

		if x == nil or y == nil or not Map.IsPlot(x, y) then
			return "That tile is off the map."
		end

		if not PlayersVisibility[playerID]:IsVisible(x, y) then
			return "You can't see that tile."
		end

		local R = CityCommandResults
		local parameters = { [UnitOperationTypes.PARAM_X] = x, [UnitOperationTypes.PARAM_Y] = y }
		local tiles = SentientSystems_GetTargetTiles(CityManager.GetCommandTargets(city, CityCommandTypes.RANGE_ATTACK, {}), R.PLOTS, R.MODIFIERS, R.MODIFIER_IS_TARGET)

		for _, tile in ipairs(tiles) do
			if tile.x == x and tile.y == y then
				if not CityManager.CanStartCommand(city, CityCommandTypes.RANGE_ATTACK, parameters) then
					return "The game won't start that attack."
				end

				CityManager.RequestCommand(city, CityCommandTypes.RANGE_ATTACK, parameters)

				return nil
			end
		end

		return SentientSystems_GetNotTargetReason(tiles)
	end)
end

-- The resources part of the player section: each strategic, luxury, and bonus resource the player has,
-- where it comes from, and, with Gathering Storm, the strategic stockpiles, as the Resources tab of
-- Reports shows them. SentientSystemsCore_StatePlayer.lua loads this file. Example:
-- SentientSystems_GetResourcesState(player) returns a list that encodes as '[{"class":"luxury",
-- "cities":[{"amount":1,"city":{"id":65536,"owner":0}}],"name":"Turtles","sources":[{"amount":1,
-- "city":{"id":196610,"owner":0},"kind":"city","name":"Ratumacos"},{"amount":-1,"kind":"deal",
-- "player":8,"turnsLeft":19},{"amount":1,"kind":"other"}],"total":1,"type":"RESOURCE_TURTLES"}]', on one
-- line. The checks follow GetData, AddResourceData, GetCityResourceData, and ViewResourcesPage in
-- ReportScreen.lua, and AppendXP2ResourceData and AddMiscResourceData in ReportScreen_Expansion2.lua.

-- The class each resource class type has in the state.
local CLASSES = {
	RESOURCECLASS_STRATEGIC = "strategic",
	RESOURCECLASS_LUXURY = "luxury",
	RESOURCECLASS_BONUS = "bonus",
}

-- Adds an amount to a resource's entry, and a source for it unless source is nil, which only makes
-- sure the resource has an entry. The report leaves out artifacts. See AddResourceData in
-- ReportScreen.lua, lines 506 to 536.
local function Add(entries, index, source, amount)
	local row = GameInfo.Resources[index]
	local class = CLASSES[row.ResourceClassType]

	if class == nil then
		return
	end

	if entries[index] == nil then
		entries[index] = { type = row.ResourceType, name = Locale.Lookup(row.Name), class = class, sources = {}, total = 0 }
	end

	if source ~= nil then
		source.amount = amount
		entries[index].sources[#entries[index].sources + 1] = source
	end

	entries[index].total = entries[index].total + amount
end

-- Adds what each city owns, as GetResourcesExtractedByCity gives it with Gathering Storm, and
-- otherwise as the count of the city's extractable resource tiles, in the order of the resources. See
-- GetCityResourceData in ReportScreen.lua, lines 541 to 562, and in ReportScreen_Expansion2.lua.
local function AddOwned(player, entries, stockpiles)
	local resources = player:GetResources()

	for _, city in player:GetCities():Members() do
		local amounts = {}

		if stockpiles then
			for _, extracted in ipairs(resources:GetResourcesExtractedByCity(city:GetID(), ResultFormat.SUMMARY) or {}) do
				if extracted.Amount > 0 then
					amounts[extracted.ResourceType] = extracted.Amount
				end
			end
		else
			for _, plotID in ipairs(Map.GetCityPlots():GetPurchasedPlots(city)) do
				local plot = Map.GetPlotByIndex(plotID)
				local index = plot:GetResourceType()

				if index ~= -1 and resources:IsResourceExtractableAt(plot) then
					amounts[index] = (amounts[index] or 0) + 1
				end
			end
		end

		local indexes = {}

		for index in pairs(amounts) do
			indexes[#indexes + 1] = index
		end

		table.sort(indexes)

		for _, index in ipairs(indexes) do
			Add(entries, index, { kind = "city", city = { owner = player:GetID(), id = city:GetID() }, name = Locale.Lookup(city:GetName()) }, amounts[index])
		end
	end
end

-- Adds the resources the player trades in deals that haven't ended, as exports, which are negative,
-- and imports, with the turns left. See GetData in ReportScreen.lua, lines 355 to 460.
local function AddDeals(player, entries)
	local playerID = player:GetID()
	local turn = Game.GetCurrentGameTurn()

	for _, other in ipairs(PlayerManager.GetAliveMajors()) do
		local otherID = other:GetID()

		if otherID ~= playerID then
			for _, deal in ipairs(DealManager.GetPlayerDeals(playerID, otherID) or {}) do
				for _, side in ipairs({ { owner = playerID, sign = -1 }, { owner = otherID, sign = 1 } }) do
					for _, item in ipairs(deal:FindItemsByType(DealItemTypes.RESOURCES, DealItemSubTypes.NONE, side.owner) or {}) do
						local duration = item:GetDuration()

						if duration ~= 0 then
							local source = { kind = "deal", player = otherID, turnsLeft = duration - (turn - item:GetEnactedTurn()) }

							Add(entries, item:GetValueType(), source, side.sign * item:GetAmount())
						end
					end
				end
			end
		end
	end
end

-- Adds the resources the city-states that the player is Suzerain of export to the player. See GetData
-- in ReportScreen.lua, lines 462 to 478.
local function AddSuzerain(player, entries)
	for _, minor in ipairs(PlayerManager.GetAliveMinors()) do
		local influence = minor:GetInfluence()

		if influence ~= nil and influence:GetSuzerain() == player:GetID() then
			for row in GameInfo.Resources() do
				local amount = minor:GetResources():GetExportedResourceAmount(row.Index)

				if amount > 0 then
					Add(entries, row.Index, { kind = "suzerain", player = minor:GetID() }, amount)
				end
			end
		end
	end
end

-- Adds the Gathering Storm sources: what units and power plants use each turn, what is reserved, and
-- what city-states send, and the stockpile a resource has that no source explains. See
-- AppendXP2ResourceData in ReportScreen_Expansion2.lua, lines 8 to 54.
local function AddGatheringStorm(player, entries)
	local resources = player:GetResources()

	for row in GameInfo.Resources() do
		local units = resources:GetUnitResourceDemandPerTurn(row.Hash)
		local power = resources:GetPowerResourceDemandPerTurn(row.Hash)
		local reserved = resources:GetReservedResourceAmount(row.Hash)
		local stockpile = resources:GetResourceAmount(row.Hash)
		local imported = resources:GetResourceImportPerTurn(row.Hash)

		if units > 0 then
			Add(entries, row.Index, { kind = "units" }, -units)
		end

		if power > 0 then
			Add(entries, row.Index, { kind = "power" }, -power)
		end

		if reserved > 0 then
			Add(entries, row.Index, { kind = "reserve" }, -reserved)
		end

		if entries[row.Index] == nil and stockpile > 0 then
			Add(entries, row.Index, { kind = imported > 0 and "cityStates" or "other" }, stockpile)
		elseif imported > 0 then
			Add(entries, row.Index, { kind = "cityStates" }, imported)
		end
	end
end

-- Returns the amount the game holds for a resource that the sources should reach: with Gathering Storm
-- a strategic resource's accumulation less its use each turn, and otherwise the amount the player has.
local function GetHeld(resources, row, stockpiles)
	if stockpiles and row.ResourceClassType == "RESOURCECLASS_STRATEGIC" then
		return resources:GetResourceAccumulationPerTurn(row.ResourceType)
			- resources:GetUnitResourceDemandPerTurn(row.ResourceType)
			- resources:GetPowerResourceDemandPerTurn(row.ResourceType)
	end

	return resources:GetResourceAmount(row.Index)
end

-- Adds the rest of what the game holds as a source named other, which the report calls Gameplay
-- Bonuses, and with Gathering Storm gives each resource in the stockpile an entry. See
-- AddMiscResourceData in ReportScreen.lua, lines 485 to 502, and in ReportScreen_Expansion2.lua,
-- lines 91 to 123.
local function AddOther(player, entries, stockpiles)
	local resources = player:GetResources()

	for row in GameInfo.Resources() do
		local held = GetHeld(resources, row, stockpiles)
		local entry = entries[row.Index]

		if stockpiles and held ~= 0 or held > 0 then
			if entry == nil then
				Add(entries, row.Index, { kind = "other" }, held)
			elseif held > entry.total then
				Add(entries, row.Index, { kind = "other" }, held - entry.total)
			end
		end

		if stockpiles and resources:GetResourceAmount(row.ResourceType) > 0 then
			Add(entries, row.Index, nil, 0)
		end
	end
end

-- Returns the cities the game allocates a luxury to, each with the amount, or nil for none. See
-- ViewResourcesPage in ReportScreen.lua, lines 1224 to 1244.
local function GetAllocation(player, index)
	local cities = {}

	for _, allocation in ipairs(player:GetResources():GetResourceAllocationCities(index)) do
		cities[#cities + 1] = { city = { owner = player:GetID(), id = allocation.CityID }, amount = allocation.AllocationAmount }
	end

	return #cities > 0 and cities or nil
end

-- Returns the resources section: a list of the resources the report lists, in the game's order. Each
-- has type, name, class, which is strategic, luxury, or bonus, sources, each with kind, one of city,
-- with city and name, deal, with player and turnsLeft, suzerain, with player, units, power, reserve,
-- cityStates, and other, and amount, cities, the cities it is allocated to, left out for none, and
-- total, the sum of the sources. With Gathering Storm a strategic resource has perTurn in place of
-- total, for what it adds to the stockpile each turn, and stockpile and max.
function SentientSystems_GetResourcesState(player)
	local resources = player:GetResources()
	local stockpiles = resources.GetResourceStockpileCap ~= nil
	local entries, list = {}, {}

	AddOwned(player, entries, stockpiles)
	AddDeals(player, entries)
	AddSuzerain(player, entries)

	if stockpiles then
		AddGatheringStorm(player, entries)
	end

	AddOther(player, entries, stockpiles)

	for row in GameInfo.Resources() do
		local entry = entries[row.Index]

		if entry ~= nil then
			entry.cities = GetAllocation(player, row.Index)

			if stockpiles and entry.class == "strategic" then
				entry.perTurn, entry.total = entry.total, nil
				entry.stockpile = resources:GetResourceAmount(row.Index)
				entry.max = resources:GetResourceStockpileCap(row.Index)
			end

			list[#list + 1] = entry
		end
	end

	return list
end

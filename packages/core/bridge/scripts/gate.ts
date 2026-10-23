// The phase 0 gate: it lists your cities and units from the bridge, checks a move into deep water,
// and moves one unit, following the method in docs/findings/game-api.md. It prints each call, the
// Lua state it ran in, and what came back, for the results table there. Run it with `npm run gate`,
// with a game loaded and the core mod on. Options: `--unit <id>` picks the unit to move, and
// `--port <port>` sets another port, such as `npm run gate -- --unit 131073`. Throwaway code:
// phase 1 builds the real action API, and this file goes when phase 0 closes.

import { once } from "node:events";
import { parseArgs } from "node:util";
import { CORE_STATE } from "../src/connect.js";
import { log, warn } from "../src/log.js";
import { TunerClient } from "../src/tuner/client.js";
import { DEFAULT_PORT } from "../src/tuner/connection.js";

// The read-only gameplay state, for comparing what it sees with the UI state.
const GAMEPLAY_STATE = "GameCore_Tuner";
// The base UI's state, where the move is tried again if the core mod's state can't move the unit.
const FALLBACK_STATE = "InGame";
// A move may finish after RequestOperation returns, so the position is read a few times.
const POSITION_READS = 5;
const POSITION_WAIT_MS = 1_000;

// The move's parameters, as MoveUnitToPlot in Base/Assets/UI/Civ6Common.lua builds them.
const MOVE_PARAMS = `
	local function MoveParams(x, y)
		local params = {}
		params[UnitOperationTypes.PARAM_X] = x
		params[UnitOperationTypes.PARAM_Y] = y
		params[UnitOperationTypes.PARAM_MODIFIERS] =
			UnitOperationMoveModifiers.ATTACK + UnitOperationMoveModifiers.MOVE_IGNORE_UNEXPLORED_DESTINATION
		return params
	end
	-- The plot indexes the unit can reach this turn, as a set. CanStartOperation passes for tiles the
	-- unit can't enter, such as water for a land unit, so the UI's movement range in
	-- Base/Assets/UI/WorldView/SelectedUnit.lua comes from this call instead.
	local function Reachable(unit)
		local reachable = {}
		for _, index in ipairs(UnitManager.GetReachableMovement(unit) or {}) do reachable[index] = true end
		return reachable
	end`;

const { values } = parseArgs({
	options: {
		port: { type: "string", default: String(DEFAULT_PORT) },
		unit: { type: "string" },
	},
});
const client = new TunerClient({ port: Number(values.port) });

// Runs Lua in a state and prints what it printed, one line each. A failure prints a warning and
// returns no lines, so the later steps still run.
async function step(label: string, state: string, lua: string): Promise<string[]> {
	log(`${label}, in ${state}`);

	try {
		const { lines } = await client.run(state, lua);

		if (lines.length === 0) {
			console.log("          (no lines)");
		}

		lines.forEach((line) => console.log(`          ${line}`));

		return lines;
	} catch (error) {
		warn(`${label} failed in ${state}: ${error instanceof Error ? error.message : String(error)}`);

		return [];
	}
}

// Prints "id, name, x, y, population" for each of the player's cities, tab-separated. Gameplay
// states may have no Locale, so the name stays a text key there.
function citiesLua(playerId: number): string {
	return `
		for _, city in Players[${playerId}]:GetCities():Members() do
			local name = city:GetName()
			if Locale ~= nil then name = Locale.Lookup(name) end
			print(table.concat({ city:GetID(), name, city:GetX(), city:GetY(), city:GetPopulation() }, "\\t"))
		end`;
}

// Prints "id, type, x, y, moves left" for each of the player's units on the map, tab-separated.
// Units off the map, such as one inside a transport, have an X of -9999.
function unitsLua(playerId: number): string {
	return `
		for _, unit in Players[${playerId}]:GetUnits():Members() do
			if unit:GetX() ~= -9999 then
				local info = GameInfo.Units[unit:GetType()]
				local unitType = info and info.UnitType or unit:GetType()
				print(table.concat({ unit:GetID(), unitType, unit:GetX(), unit:GetY(), unit:GetMovesRemaining() }, "\\t"))
			end
		end`;
}

// Finds the deep-water tile nearest the unit and checks a move there twice: the plain check, which
// returns a boolean, and the form with true as a fifth argument, which civ6-mcp reads a reason
// table from. Prints each result, every field of the table, and whether the tile is reachable.
function negativeLua(playerId: number, unitId: number): string {
	return `${MOVE_PARAMS}
		local unit = UnitManager.GetUnit(${playerId}, ${unitId})
		if unit == nil then print("no unit") return end
		local target, distance = nil, nil
		for index = 0, Map.GetPlotCount() - 1 do
			local plot = Map.GetPlotByIndex(index)
			if plot:IsWater() and not plot:IsShallowWater() then
				local d = Map.GetPlotDistance(unit:GetX(), unit:GetY(), plot:GetX(), plot:GetY())
				if distance == nil or d < distance then target, distance = plot, d end
			end
		end
		if target == nil then print("no deep water on the map") return end
		print("target", target:GetX(), target:GetY(), "distance", distance)
		print("reachable", tostring(Reachable(unit)[target:GetIndex()] == true))
		local params = MoveParams(target:GetX(), target:GetY())
		print("plain", tostring(UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, params)))
		local ok, result = UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, params, true)
		print("with true", tostring(ok), type(result))
		if type(result) == "table" then
			for key, value in pairs(result) do
				if type(value) == "table" then
					for _, item in pairs(value) do print("  " .. tostring(key), tostring(item)) end
				else
					print("  " .. tostring(key), tostring(value))
				end
			end
		end`;
}

// Moves the unit to the first adjacent tile that it can reach and that passes the check, and prints
// "target x y" before the request. Prints "no target" if no adjacent tile qualifies.
function moveLua(playerId: number, unitId: number): string {
	return `${MOVE_PARAMS}
		local unit = UnitManager.GetUnit(${playerId}, ${unitId})
		if unit == nil then print("no unit") return end
		print("from", unit:GetX(), unit:GetY())
		local reachable = Reachable(unit)
		for direction = 0, DirectionTypes.NUM_DIRECTION_TYPES - 1 do
			local plot = Map.GetAdjacentPlot(unit:GetX(), unit:GetY(), direction)
			if plot ~= nil and reachable[plot:GetIndex()] then
				local params = MoveParams(plot:GetX(), plot:GetY())
				if UnitManager.CanStartOperation(unit, UnitOperationTypes.MOVE_TO, nil, params) then
					print("target", plot:GetX(), plot:GetY())
					UnitManager.RequestOperation(unit, UnitOperationTypes.MOVE_TO, params)
					print("requested")
					return
				end
			end
		end
		print("no target")`;
}

// Prints "x y moves" for the unit, read in the gameplay state.
function positionLua(playerId: number, unitId: number): string {
	return `
		local unit = Players[${playerId}]:GetUnits():FindID(${unitId})
		if unit == nil then print("no unit") return end
		print(unit:GetX(), unit:GetY(), unit:GetMovesRemaining())`;
}

// Lua's print puts a tab between its arguments.
function fields(line: string | undefined): string[] {
	return line?.split("\t") ?? [];
}

// Requests the move from one state, then reads the position until the unit is on the target.
// Returns whether it got there.
async function move(state: string, playerId: number, unitId: number): Promise<boolean> {
	const lines = await step("Move", state, moveLua(playerId, unitId));
	const [, x, y] = fields(lines.find((line) => line.startsWith("target")));

	if (x === undefined || !lines.includes("requested")) {
		return false;
	}

	for (let read = 1; read <= POSITION_READS; read++) {
		await new Promise((resolve) => setTimeout(resolve, POSITION_WAIT_MS));

		const [position] = await step(`Position, read ${read}`, GAMEPLAY_STATE, positionLua(playerId, unitId));
		const [atX, atY] = fields(position);

		if (atX === x && atY === y) {
			log(`The unit reached (${x}, ${y}) after a request from ${state}`);

			return true;
		}
	}

	warn(`The unit didn't reach (${x}, ${y}) after a request from ${state}`);

	return false;
}

log(`Waiting for the game's tuner on port ${values.port}...`);
client.connect();
await once(client, "connected");

const [playerLine] = await step("Local player", CORE_STATE, "print(Game.GetLocalPlayer())");
const playerId = Number(playerLine);

if (!Number.isInteger(playerId)) {
	warn("No local player, so the gate can't go on. Load a game with the core mod on");
	client.close();
	process.exit(1);
}

await step("Cities", GAMEPLAY_STATE, citiesLua(playerId));
await step("Cities", CORE_STATE, citiesLua(playerId));
const units = await step("Units", CORE_STATE, unitsLua(playerId));
// The first unit with moves left, unless --unit picks one.
const unitId = values.unit === undefined
	? Number(fields(units.find((line) => Number(fields(line)[4]) > 0))[0])
	: Number(values.unit);

if (!Number.isInteger(unitId)) {
	warn("No unit with moves left, so the gate can't check or make a move. Pick one with --unit <id>");
	client.close();
	process.exit(1);
}

log(`Using unit ${unitId}`);
// The negative test goes first, because it only checks and changes nothing.
await step("Move into deep water", CORE_STATE, negativeLua(playerId, unitId));

if (!await move(CORE_STATE, playerId, unitId)) {
	log(`Trying the move again from ${FALLBACK_STATE}, to tell the core mod's state apart from UI states in general`);
	await move(FALLBACK_STATE, playerId, unitId);
}

client.close();

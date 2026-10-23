// The phase 0 gate: it lists your cities and units from the bridge, following the method in
// docs/findings/game-api.md. It prints each call, the Lua state it ran in, and what came back, for
// the results table there. Run it with `npm run gate`, with a game loaded and the core mod on. An
// option such as `npm run gate -- --port 4400` sets another port. Throwaway code: phase 1 builds
// the real action API, and this file goes when phase 0 closes.

import { once } from "node:events";
import { parseArgs } from "node:util";
import { CORE_STATE } from "../src/connect.js";
import { log, warn } from "../src/log.js";
import { TunerClient } from "../src/tuner/client.js";
import { DEFAULT_PORT } from "../src/tuner/connection.js";

// The read-only gameplay state, for comparing what it sees with the UI state.
const GAMEPLAY_STATE = "GameCore_Tuner";

const { values } = parseArgs({
	options: {
		port: { type: "string", default: String(DEFAULT_PORT) },
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
await step("Units", CORE_STATE, unitsLua(playerId));

client.close();

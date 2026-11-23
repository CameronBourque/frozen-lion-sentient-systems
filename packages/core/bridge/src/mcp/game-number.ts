// Reads one whole number from the game, such as the local player or the turn,
// for the tools that need it.

import { CORE_STATE } from "../connect.js";
import { explainFailure } from "../errors.js";
import type { TunerClient } from "../tuner/client.js";

export type NumberResult =
	| { ok: true; value: number }
	| { ok: false; error: string };

// call is a Lua call that returns the number. what names it in errors.
export async function readGameNumber(client: TunerClient, call: string, what: string): Promise<NumberResult> {
	let lines: string[];

	try {
		({ lines } = await client.run(CORE_STATE, `print(${call})`));
	} catch (error) {
		return { ok: false, error: explainFailure(error, `${what} request`) };
	}

	const value = Number(lines[0]);

	return lines.length === 1 && Number.isInteger(value) && value >= 0
		? { ok: true, value }
		: { ok: false, error: `${call} printed ${JSON.stringify(lines)}, not a ${what}` };
}

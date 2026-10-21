// The marker wrapper: the Lua that the client puts around each command, and the parser for the
// marker lines it prints. The markers tell the client which output belongs to which command,
// because the game sends every print the same way. docs/findings/tuner-commands.md has the probe
// results that this wrapper is built on.

// How a wrapped command ended, from its end marker.
export type Ending =
	| { kind: "ok" }
	| { kind: "error"; message: string }
	// ContextPtr:GetID() named another state, so the client's state list is stale.
	| { kind: "state"; actual: string };

export type Marker =
	| { kind: "begin"; id: number }
	| { kind: "end"; id: number; ending: Ending };

// The whole wrapper is one expression, so it runs both inside _cmdr = {...} and as a plain chunk.
// The caller's Lua sits on lines of its own, so a -- comment at its end can't hide the closing end.
// The pcall keeps a runtime error from skipping the end marker. Main State and gameplay states have
// no ContextPtr, so the state check runs only in UI states.
export function wrap(id: number, stateName: string, lua: string): string {
	return [
		"(function()",
		`print("@@ss:begin:${id}")`,
		// JSON escapes quotes and backslashes the way Lua does, so it gives a Lua string for a state name.
		`if ContextPtr and ContextPtr:GetID() ~= ${JSON.stringify(stateName)} then print("@@ss:end:${id}:state:" .. ContextPtr:GetID()) return end`,
		"local ok, err = pcall(function()",
		lua,
		"end)",
		`print("@@ss:end:${id}:" .. (ok and "ok" or "error:" .. tostring(err)))`,
		"end)()",
	].join("\n");
}

// "InGame: @@ss:begin:7" and "InGame: @@ss:end:7:error:boom". The state prefix is optional,
// because Main State prints have none. Only the endings that wrap() prints count, so any other line
// that starts with @@ss: is an ordinary print.
const prefix = "(?:[^:\\n]+: )?";
const id = "(\\d+)";
// ok, error:<message>, or state:<the state's real name>. An error message can span lines.
const ending = "(?:(ok)|error:([\\s\\S]*)|state:(.*))";
const beginPattern = new RegExp(`^${prefix}@@ss:begin:${id}$`);
const endPattern = new RegExp(`^${prefix}@@ss:end:${id}:${ending}$`);

// Returns undefined for a line that isn't a marker.
export function parseMarker(text: string): Marker | undefined {
	const begin = beginPattern.exec(text);

	if (begin) {
		return { kind: "begin", id: Number(begin[1]) };
	}

	const match = endPattern.exec(text);

	if (!match) {
		return undefined;
	}

	const [, id, ok, message, actual] = match;

	if (ok) {
		return { kind: "end", id: Number(id), ending: { kind: "ok" } };
	}

	if (message !== undefined) {
		return { kind: "end", id: Number(id), ending: { kind: "error", message } };
	}

	return { kind: "end", id: Number(id), ending: { kind: "state", actual } };
}

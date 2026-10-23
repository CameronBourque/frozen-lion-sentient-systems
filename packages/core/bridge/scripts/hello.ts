// Checks the tuner client end to end against the running game: it connects, prints the state list,
// and runs three commands in InGame through the marker wrapper. It exits with code 1 if any result
// differs from what it should be. Run it with `npm run hello`, with a game loaded. An argument such
// as `npm run hello -- 4400` sets another port. In PowerShell, write the `--` as `'--'`, as
// docs/rules/code.md says.

import { TunerClient, TunerLuaError } from "../src/tuner/client.js";
import { DEFAULT_PORT } from "../src/tuner/connection.js";

const STATE = "InGame";

// Each check runs its Lua and compares what comes back.
const checks = [
	{
		name: "one line",
		lua: "print(\"hello from bridge\")",
		lines: ["hello from bridge"],
	},
	{
		name: "several lines, with a local and a comment",
		lua: "local message = \"from line one\"\nprint(message)\nprint(\"from line three\") -- a comment",
		lines: ["from line one", "from line three"],
	},
	{
		name: "a runtime error",
		lua: "print(\"before the error\")\nerror(\"boom\")",
		lines: ["before the error"],
		error: "boom",
	},
];

const port = Number(process.argv[2] ?? DEFAULT_PORT);
const client = new TunerClient({ port });
let failures = 0;

function check(passed: boolean, text: string): void {
	console.log(`  ${passed ? "ok  " : "FAIL"}  ${text}`);
	failures += passed ? 0 : 1;
}

client.on("output", (line) => console.log(`  output: ${line}`));
console.log(`Waiting for the game's tuner on port ${port}...`);
client.connect();

const states = await client.listStates();

console.log(`\n${states.length} Lua states:`);
states.forEach(({ index, name }) => console.log(`  ${index}  ${name}`));

for (const { name, lua, lines, error } of checks) {
	console.log(`\n${name}`);

	try {
		const result = await client.run(STATE, lua);

		console.log(`  lines: ${JSON.stringify(result.lines)}`);
		check(JSON.stringify(result.lines) === JSON.stringify(lines), `lines are ${JSON.stringify(lines)}`);
		check(error === undefined, error === undefined ? "no error" : `an error whose first line ends in ${JSON.stringify(error)}`);
	} catch (caught) {
		if (!(caught instanceof TunerLuaError)) {
			throw caught;
		}

		console.log(`  error: ${caught.message}`);
		console.log(`  lines: ${JSON.stringify(caught.lines)}`);
		check(JSON.stringify(caught.lines) === JSON.stringify(lines), `lines are ${JSON.stringify(lines)}`);
		// The game puts a stack trace after the message, so only the first line ends in the error.
		const firstLine = caught.message.split("\n")[0];

		check(error !== undefined && firstLine.endsWith(error), `an error whose first line ends in ${JSON.stringify(error)}`);
	}
}

client.close();
console.log(failures === 0 ? "\nAll checks passed." : `\n${failures} checks failed.`);
process.exitCode = failures === 0 ? 0 : 1;

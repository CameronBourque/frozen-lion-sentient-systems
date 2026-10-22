// Starts the bridge. It connects to the game's tuner and logs each event the core mod prints, until
// you press Ctrl+C.

import { describeEvent, parseLine, stripState } from "./events.js";
import { log, warn } from "./log.js";
import { TunerClient } from "./tuner/client.js";

const client = new TunerClient();

client.on("connected", () => log("connected to the tuner"));
client.on("disconnected", () => log("disconnected from the tuner"));
client.on("output", (line) => {
	const parsed = parseLine(stripState(line));

	if (parsed.result === "event") {
		log(describeEvent(parsed.event));
	} else if (parsed.result === "invalid") {
		warn(`${parsed.reason}: ${line}`);
	}
});
process.on("SIGINT", () => {
	client.close();
	process.exit(0);
});

log("Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
client.connect();

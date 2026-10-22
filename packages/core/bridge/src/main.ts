// Starts the bridge. It connects to the game's tuner and logs each event the core mod prints, until
// you press Ctrl+C.

import { readLine } from "./events.js";
import { log } from "./log.js";
import { TunerClient } from "./tuner/client.js";

const client = new TunerClient();

client.on("connected", () => log("connected to the tuner"));
client.on("disconnected", () => log("disconnected from the tuner"));
client.on("output", (line) => readLine(line));
process.on("SIGINT", () => {
	client.close();
	process.exit(0);
});

log("Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
client.connect();

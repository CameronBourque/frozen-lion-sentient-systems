// Starts the bridge. It reads the config file, connects to the game's tuner, logs the core mod's
// version and any active turn on each connect, and logs each event the core mod prints, until you
// press Ctrl+C.

import { isSea } from "node:sea";
import { onConnect } from "./connect.js";
import { readLine } from "./events.js";
import { startConfig } from "./load-config.js";
import { log, warn } from "./log.js";
import { TunerClient } from "./tuner/client.js";

// Start by loading the configuration.
const started = startConfig({ args: process.argv.slice(2), cwd: process.cwd(), execPath: process.execPath, isExecutable: isSea() });

if (!started.ok) {
	warn(started.error);
	process.exit(1);
}

log(`config from ${started.path}`);
started.warnings.forEach((warning) => warn(warning));

// Start the tuner client and handle its events.
const client = new TunerClient();

client.on("connected", () => {
	log("connected to the tuner");
	// onConnect warns about its own failures, so nothing waits on it.
	void onConnect(client);
});
client.on("disconnected", () => log("disconnected from the tuner"));
client.on("output", (line) => readLine(line));
process.on("SIGINT", () => {
	client.close();
	process.exit(0);
});

log("Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
client.connect();

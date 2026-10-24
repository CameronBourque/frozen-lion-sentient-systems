// Starts the bridge. It reads the config file, connects to the game's tuner, logs the core mod's
// version and any active turn on each connect, and logs each event the core mod prints, until you
// press Ctrl+C. Each game gets its own log file.

import { isSea } from "node:sea";
import { onConnect } from "./connect.js";
import { readLine } from "./events.js";
import { startConfig } from "./load-config.js";
import { logFilePath, Logger } from "./log.js";
import { TunerClient } from "./tuner/client.js";

// The default level until the config file sets one. Lines before then go to the console only,
// because the log folder is next to the config file.
const logger = new Logger();

// Start by loading the configuration.
const started = startConfig({ args: process.argv.slice(2), cwd: process.cwd(), execPath: process.execPath, isExecutable: isSea() });

if (!started.ok) {
	logger.error("config_failed", started.error);
	process.exit(1);
}

logger.level = started.config.logLevel;
// The first file holds the startup lines and the first game.
logger.openFile(logFilePath(started.path, new Date()));
logger.info("config_loaded", `Read the config file ${started.path}`, { path: started.path });
started.warnings.forEach((warning) => logger.warn("config_warning", warning));

// Start the tuner client and handle its events.
const client = new TunerClient();
// A load resets the socket, so until the load signal in step 4, each connect after the first starts
// a new game.
let hasConnected = false;

client.on("connected", () => {
	if (hasConnected) {
		logger.openFile(logFilePath(started.path, new Date()));
	}

	hasConnected = true;
	logger.info("connected", "Connected to the game's tuner");
	// onConnect warns about its own failures, so nothing waits on it.
	void onConnect(client, logger);
});
client.on("disconnected", () => logger.info("disconnected", "Disconnected from the game's tuner"));
client.on("output", (line) => readLine(line, logger));
process.on("SIGINT", () => {
	client.close();
	logger.closeFile();
	process.exit(0);
});

logger.info("started", "Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
client.connect();

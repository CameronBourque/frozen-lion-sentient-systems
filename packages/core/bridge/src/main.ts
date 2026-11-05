// Starts the bridge: reads the config, connects to the tuner, and logs each
// event the core mod prints, with a log file per game, until Ctrl+C.

import { isSea } from "node:sea";
import { onConnect } from "./connect.js";
import { readLine } from "./events.js";
import { onLoadEvent } from "./game-load.js";
import { startConfig } from "./load-config.js";
import { logFilePath, Logger } from "./log.js";
import { TunerClient } from "./tuner/client.js";

// The default level until the config file sets one. Lines before then go to the
// console only, because the log folder is next to the config file.
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

const client = new TunerClient();

client.on("connected", () => {
	logger.info("connected", "Connected to the game's tuner");
	// onConnect warns about its own failures, so nothing waits on it.
	void onConnect(client, logger);
});
client.on("disconnected", () => logger.info("disconnected", "Disconnected from the game's tuner"));
// Each load starts a new log file.
client.on("output", (line) => readLine(line, logger, (event) => onLoadEvent(event, client, logger, () => logFilePath(started.path, new Date()))));
process.on("SIGINT", () => {
	client.close();
	logger.closeFile();
	process.exit(0);
});

logger.info("started", "Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
client.connect();

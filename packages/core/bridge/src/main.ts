// Starts the bridge: reads the config, asks for the model, connects to the
// tuner, logs each core mod event to a file per game, and serves the MCP tools
// with --mcp, until Ctrl+C.

import path from "node:path";
import { getAsset, getAssetKeys, isSea } from "node:sea";
import { KEY_VARIABLES } from "./config.js";
import { onConnect } from "./connect.js";
import { readLine } from "./events.js";
import { onLoadEvent } from "./game-load.js";
import { KNOWLEDGE_FOLDER, knowledgeFromAssets, knowledgeFromFolder } from "./knowledge.js";
import { startConfig } from "./load-config.js";
import { logFilePath, Logger } from "./log.js";
import { type McpHttp, startMcpHttp } from "./mcp/http.js";
import { localPlayer } from "./mcp/player.js";
import { chooseModel } from "./model/choose.js";
import { listModels } from "./model/list-models.js";
import { askMenu } from "./model/menu.js";
import { cachedFacts, factsCachePath } from "./model/model-facts.js";
import { TunerClient } from "./tuner/client.js";

// The default level until the config file sets one. Lines before then go to the
// console only, because the log folder is next to the config file.
const logger = new Logger();

// Start by loading the configuration.
const started = startConfig({ args: process.argv.slice(2), cwd: process.cwd(), execPath: process.execPath, isExecutable: isSea(), env: process.env });

if (!started.ok) {
	logger.error("config_failed", started.error);
	process.exit(1);
}

logger.level = started.config.logLevel;
// The first file holds the startup lines and the first game.
logger.openFile(logFilePath(started.path, new Date()));
logger.info("config_loaded", `Read the config file ${started.path}`, { path: started.path });
started.warnings.forEach((warning) => logger.warn("config_warning", warning));
started.environmentKeys.forEach((provider) => logger.info("environment_key", `Using the ${provider} API key from ${KEY_VARIABLES[provider]}`, { provider }));

// The executable carries the knowledge files. In development, npm runs the
// bridge in its own folder, as startConfig also assumes.
const knowledge = isSea() ? knowledgeFromAssets(getAssetKeys(), (key) => getAsset(key, "utf8")) : knowledgeFromFolder(path.join(process.cwd(), KNOWLEDGE_FOLDER));

logger.info("knowledge_loaded", `Read ${knowledge.size} knowledge files`, { count: knowledge.size });

const client = new TunerClient();

client.on("connected", () => {
	logger.info("connected", "Connected to the game's tuner");
	// onConnect warns about its own failures, so nothing waits on it.
	void onConnect(client, logger);
});
client.on("disconnected", () => logger.info("disconnected", "Disconnected from the game's tuner"));
// Each load starts a new log file.
client.on("output", (line) => readLine(line, logger, (event) => onLoadEvent(event, client, logger, () => logFilePath(started.path, new Date()))));
// Undefined until the MCP server starts, and without --mcp.
let mcp: McpHttp | undefined;

process.on("SIGINT", () => {
	client.close();
	logger.closeFile();
	// Exits after the MCP server closes, so no request is cut off mid-reply.
	void (mcp?.close() ?? Promise.resolve()).finally(() => process.exit(0));
});

const terminal = { input: process.stdin, write: (text: string) => process.stdout.write(text) };
// Without a terminal, such as a piped input, the bridge can't ask.
const ask = process.stdin.isTTY ? (title: string, labels: string[], start: number) => askMenu(title, labels, start, terminal) : undefined;

// No top-level await, because the executable's bundle is CommonJS.
void chooseModel(started.config, started.path, logger, { ask, list: listModels, facts: () => cachedFacts(factsCachePath(started.path)) }).then((chosen) => {
	if (!chosen) {
		logger.closeFile();
		process.exit(0);
	}

	logger.info("started", "Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
	client.connect();

	if (started.mcp) {
		void startMcpHttp(started.config.mcpPort, { client, player: localPlayer(client), logger }).then((http) => {
			mcp = http;
		});
	}
});

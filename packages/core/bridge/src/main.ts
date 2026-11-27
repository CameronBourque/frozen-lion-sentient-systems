// Starts the bridge: reads the config, asks for the model, connects to the
// tuner, logs each core mod event to a file per game, and plays each agent's
// turn on its signal. With --mcp, it serves the MCP tools and plays no turns.

import path from "node:path";
import { getAsset, getAssetKeys, isSea } from "node:sea";
import { describeSpend, noSpend, spendWarnings } from "./agents/spend.js";
import { type TurnSignal, turnSignal } from "./agents/turn-signal.js";
import { KEY_VARIABLES } from "./config.js";
import { onConnect } from "./connect.js";
import { type CoreEvent, readLine } from "./events.js";
import { onLoadEvent } from "./game-load.js";
import { KNOWLEDGE_FOLDER, knowledgeFromAssets, knowledgeFromFolder } from "./knowledge.js";
import { startConfig } from "./load-config.js";
import { logFilePath, Logger } from "./log.js";
import { type McpHttp, startMcpHttp } from "./mcp/http.js";
import { localPlayer } from "./mcp/player.js";
import { memoryFolder } from "./memory/store.js";
import { chooseModel } from "./model/choose.js";
import { askMenu, processTerminal } from "./model/menu.js";
import { cachedFacts, factsCachePath } from "./model/model-facts.js";
import { providers } from "./model/providers/index.js";
import { agentRunner } from "./model/target.js";
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
const memory = (playerID: number): string => memoryFolder(started.path, playerID);
// Undefined until the model is chosen, and when agents can't play.
let agents: TurnSignal | undefined;

// The turn's own promise never rejects, so nothing waits on it.
const onEvent = (event: CoreEvent): void => {
	onLoadEvent(event, client, logger, () => logFilePath(started.path, new Date()));
	void agents?.onEvent(event);
};

client.on("connected", () => {
	logger.info("connected", "Connected to the game's tuner");
	// onConnect warns about its own failures, so nothing waits on it.
	void onConnect(client, logger, onEvent);
});
client.on("disconnected", () => logger.info("disconnected", "Disconnected from the game's tuner"));
// Each load starts a new log file.
client.on("output", (line) => readLine(line, logger, onEvent));
// Undefined until the MCP server starts, and without --mcp.
let mcp: McpHttp | undefined;

let stopping = false;
const runSpend = noSpend();

// Sends no end turn, so the game waits on the agent's turn, and a restart
// resumes it. docs/design/agents/turn-loop/stopping.md has the design.
const stopBridge = async (reason: string): Promise<void> => {
	// A turn that ends while the bridge stops may reach the turn count.
	if (stopping) {
		return;
	}

	stopping = true;
	logger.info("stopping", "Stopping once the Lua command in progress ends. Press Ctrl+C again to exit at once.");
	// Each turn waits for its Lua command, so the client closes after them.
	await agents?.stop();
	logger.warn("stopped", `Stopped the bridge: ${reason}. The run spent ${describeSpend(runSpend)}`, { reason, ...runSpend });
	client.close();
	// Closes the MCP server first, so no request is cut off mid-reply.
	await mcp?.close();
	logger.closeFile();
	process.exit(0);
};

process.on("SIGINT", () => {
	if (stopping) {
		process.exit(1);
	}

	void stopBridge("Ctrl+C was pressed");
});

const { turns } = started;

const onTurnEnded = turns === undefined ? undefined : (ended: number): void => {
	if (ended === turns) {
		void stopBridge(`The agents reached --turns ${turns}`);
	}
};

const terminal = processTerminal();
// Without a terminal, such as a piped input, the bridge can't ask.
const ask = process.stdin.isTTY ? (title: string, labels: string[], start: number) => askMenu(title, labels, start, terminal) : undefined;

const offered = providers(path.dirname(started.path), logger);

// Asks for the model and sets the agent loop to play each agent's turn with
// it. Returns false when the person quits the picker.
const startAgents = async (): Promise<boolean> => {
	const mode = await chooseModel(started.config, started.path, logger, { ask, providers: offered, facts: () => cachedFacts(factsCachePath(started.path)) });

	if (mode === undefined) {
		return false;
	}

	const built = agentRunner(started.config, mode, offered);

	if (built.ok) {
		const { config } = started;

		// After the picker, which may have filled in the price.
		spendWarnings(config.limits, config.model.price).forEach((warning) => logger.warn("spend_warning", warning));

		const onStopRun = (reason: string): void => {
			void stopBridge(reason);
		};

		agents = turnSignal({ client, logger, runner: built.runner, model: config.model, journalEntries: config.journalEntries, limits: config.limits, runSpend, now: () => new Date(), knowledge, memory, onTurnEnded, onStopRun });
	} else {
		logger.warn("agents_off", `Agents won't play their turns: ${built.error}`, { reason: built.error });
	}

	return true;
};

// With --mcp, the MCP client plays the turns, so a model playing them too would
// act on the same turn and cost model calls.
const skipAgents = (): Promise<boolean> => {
	logger.info("agents_off", "Agents won't play their turns, because the MCP client plays them with --mcp", { reason: "mcp" });

	return Promise.resolve(true);
};

// No top-level await, because the executable's bundle is CommonJS.
void (started.mcp ? skipAgents() : startAgents()).then((go) => {
	if (!go) {
		logger.closeFile();
		process.exit(0);
	}

	logger.info("started", "Sentient Systems bridge. Waiting for the game's tuner. Press Ctrl+C to stop.");
	client.connect();

	if (started.mcp) {
		void startMcpHttp(started.config.mcpPort, { client, player: localPlayer(client), memory, logger }).then((http) => {
			mcp = http;
		});
	}
});

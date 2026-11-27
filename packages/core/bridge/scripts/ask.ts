// Sends one prompt with one fake tool to the chosen model, and prints the tool
// call, its tokens, and its cost. Run it with `npm run ask`, with no game.
// Exits with code 1 if the model can't be called or calls no tool.

import path from "node:path";
import { isSea } from "node:sea";
import { startConfig } from "../src/load-config.js";
import { Logger } from "../src/log.js";
import { chooseModel } from "../src/model/choose.js";
import { type ModelRequest, callModel } from "../src/model/client.js";
import { askMenu, processTerminal } from "../src/model/menu.js";
import { cachedFacts, factsCachePath } from "../src/model/model-facts.js";
import { providers } from "../src/model/providers/index.js";
import { modelTarget } from "../src/model/target.js";
import { logModelCall } from "../src/model/usage.js";

// A question that only a tool call answers well, so a model that writes text
// instead shows that tools don't reach it.
const REQUEST: ModelRequest = {
	system: "You are checking a connection to a game. Answer only by calling the tool.",
	messages: [{ role: "user", content: "Name one civilization from Civilization VI, and report it with the tool." }],
	tools: [{
		name: "report_civilization",
		description: "Reports the name of one civilization.",
		inputSchema: {
			type: "object",
			properties: { name: { type: "string", description: "The civilization's name." } },
			required: ["name"],
		},
	}],
};

const logger = new Logger();

async function main(): Promise<void> {
	const started = startConfig({ args: process.argv.slice(2), cwd: process.cwd(), execPath: process.execPath, isExecutable: isSea(), env: process.env });

	if (!started.ok) {
		logger.error("config_failed", started.error);
		process.exitCode = 1;

		return;
	}

	const { config } = started;
	const terminal = processTerminal();
	const ask = process.stdin.isTTY ? (title: string, labels: string[], start: number) => askMenu(title, labels, start, terminal) : undefined;

	logger.level = config.logLevel;
	started.warnings.forEach((warning) => logger.warn("config_warning", warning));

	const offered = providers(path.dirname(started.path), logger);

	const mode = await chooseModel(config, started.path, logger, { ask, providers: offered, facts: () => cachedFacts(factsCachePath(started.path)) });

	if (mode === undefined) {
		return;
	}

	const built = modelTarget(config, mode, offered);

	if (!built.ok) {
		logger.error("model_failed", built.error);
		process.exitCode = 1;

		return;
	}

	const result = await callModel(built.target, REQUEST);

	if (!result.ok) {
		logger.warn("model_failed", result.error);
		process.exitCode = 1;

		return;
	}

	logModelCall(logger, config.model, result.reply.usage);

	for (const call of result.reply.toolCalls) {
		console.log(`${call.name}(${JSON.stringify(call.input)})`);
	}

	if (result.reply.toolCalls.length === 0) {
		console.error(`The model called no tool. It wrote: ${result.reply.text}`);
		process.exitCode = 1;
	}
}

void main();

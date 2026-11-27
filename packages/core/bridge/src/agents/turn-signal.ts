// Starts an agent's turn on its turn signal. The core mod prints AGENT_TURN
// only for agent players, so each player it names gets an agent, built the
// first time. docs/design/agents/turn-loop/README.md has the design.

import type { CoreEvent } from "../events.js";
import type { Knowledge } from "../knowledge.js";
import type { MemorySource } from "../mcp/context.js";
import { connectClient, toolDefinitions } from "../mcp/in-process.js";
import { createServer } from "../mcp/server.js";
import { DEFAULT_PROFILE, systemPrompt } from "./prompt.js";
import { type Agent, type CancelReason, type LoopContext, playTurn } from "./loop.js";

export interface SignalContext extends LoopContext {
	knowledge: Knowledge;
	memory: MemorySource;
}

// onEvent handles the core mod's events. stop cancels the running turns and
// settles once they end, and no turn starts after it.
export interface TurnSignal {
	onEvent: (event: CoreEvent) => Promise<void>;
	stop: () => Promise<void>;
}

// A turn in progress, and the controller that cancels it.
interface RunningTurn {
	controller: AbortController;
	done: Promise<void>;
}

// One turn runs at a time for each agent, so a signal for a turn that is still
// running is skipped. A game load cancels the running turns. The promise
// onEvent returns settles when the turn it started ends, and never rejects.
export function turnSignal(context: SignalContext): TurnSignal {
	const { logger } = context;
	const agents = new Map<number, Agent>();
	const running = new Map<number, RunningTurn>();
	// The agents whose game loaded since their last turn.
	const loaded = new Set<number>();
	let stopped = false;

	const cancelAll = (reason: CancelReason): void => running.forEach(({ controller }) => controller.abort(reason));

	const play = async (playerId: number, again: boolean, signal: AbortSignal): Promise<void> => {
		try {
			const agent = agents.get(playerId) ?? await buildAgent(context, playerId);

			agents.set(playerId, agent);

			// The loaded game may be an earlier save of the same turn, or
			// another game, so the agent starts over as it does on a restart.
			if (loaded.delete(playerId)) {
				agent.first = true;
				agent.endedTurn = undefined;
			}

			const result = await playTurn(agent, context, { again, signal });

			if (result.ended) {
				logger.info("turn_ended", `Player ${playerId} ended turn ${agent.endedTurn}`, { player: playerId, turn: agent.endedTurn });
			}
		} catch (error) {
			// A turn that throws must not stop the bridge, and the next signal
			// tries again.
			logger.warn("turn_failed", `Player ${playerId}'s turn failed: ${String(error)}`, { player: playerId, reason: String(error) });
		} finally {
			running.delete(playerId);
		}
	};

	const stop = async (): Promise<void> => {
		stopped = true;
		cancelAll("stop");
		await Promise.all([...running.values()].map(({ done }) => done));
	};

	const onEvent = async (event: CoreEvent): Promise<void> => {
		if (event.type === "game_ready") {
			agents.forEach((_, playerId) => loaded.add(playerId));
			cancelAll("load");

			return;
		}

		if (event.type !== "turn") {
			return;
		}

		const { playerId } = event;
		const current = running.get(playerId);

		// A cancelled turn may still wait on a call. The new turn waits for it,
		// so the two never share the agent.
		if (current?.controller.signal.aborted === true) {
			await current.done;
		}

		// A stopping bridge exits once its turns end, so a new one would only
		// be cut off.
		if (stopped) {
			return;
		}

		if (running.has(playerId)) {
			logger.info("turn_skipped", `Player ${playerId}'s turn is already being played`, { player: playerId });

			return;
		}

		const controller = new AbortController();
		const done = play(playerId, event.again, controller.signal);

		running.set(playerId, { controller, done });
		await done;
	};

	return { onEvent, stop };
}

// Each agent gets its own MCP server, whose tools act for its player.
async function buildAgent(context: SignalContext, playerID: number): Promise<Agent> {
	const { client, logger, memory } = context;
	const system = systemPrompt(context.knowledge, DEFAULT_PROFILE);

	system.warnings.forEach((warning) => logger.warn("prompt_warning", warning, { player: playerID }));

	const tools = await connectClient(createServer({ client, player: () => Promise.resolve({ ok: true, playerID }), memory, logger }));

	return { playerID, system: system.text, tools, definitions: await toolDefinitions(tools), memoryFolder: memory(playerID), first: true };
}

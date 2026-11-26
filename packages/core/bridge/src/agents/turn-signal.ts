// Starts an agent's turn on its turn signal. The core mod prints AGENT_TURN
// only for agent players, so each player it names gets an agent, built the
// first time. docs/design/agents/turn-loop.md has the design.

import type { CoreEvent } from "../events.js";
import type { Knowledge } from "../knowledge.js";
import type { MemorySource } from "../mcp/context.js";
import { connectClient, toolDefinitions } from "../mcp/in-process.js";
import { createServer } from "../mcp/server.js";
import { DEFAULT_PROFILE, systemPrompt } from "./prompt.js";
import { type Agent, type LoopContext, playTurn } from "./loop.js";

export interface SignalContext extends LoopContext {
	knowledge: Knowledge;
	memory: MemorySource;
}

// A turn in progress, and the controller a game load aborts it with.
interface RunningTurn {
	controller: AbortController;
	done: Promise<void>;
}

// Returns the handler for the core mod's events. One turn runs at a time for
// each agent, so a signal for a turn that is still running is skipped. A game
// load cancels the running turns. The returned promise settles when the turn
// it started ends, and never rejects.
export function turnSignal(context: SignalContext): (event: CoreEvent) => Promise<void> {
	const { logger } = context;
	const agents = new Map<number, Agent>();
	const running = new Map<number, RunningTurn>();
	// The agents whose game loaded since their last turn.
	const loaded = new Set<number>();

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
				logger.info("turn_ended", `Player ${playerId} ended its turn`, { player: playerId });
			}
		} catch (error) {
			// A turn that throws must not stop the bridge, and the next signal
			// tries again.
			logger.warn("turn_failed", `Player ${playerId}'s turn failed: ${String(error)}`, { player: playerId, reason: String(error) });
		} finally {
			running.delete(playerId);
		}
	};

	return async (event) => {
		if (event.type === "game_ready") {
			agents.forEach((_, playerId) => loaded.add(playerId));
			running.forEach(({ controller }) => controller.abort());

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

		if (running.has(playerId)) {
			logger.info("turn_skipped", `Player ${playerId}'s turn is already being played`, { player: playerId });

			return;
		}

		const controller = new AbortController();
		const done = play(playerId, event.again, controller.signal);

		running.set(playerId, { controller, done });
		await done;
	};
}

// Each agent gets its own MCP server, whose tools act for its player.
async function buildAgent(context: SignalContext, playerID: number): Promise<Agent> {
	const { client, logger, memory } = context;
	const system = systemPrompt(context.knowledge, DEFAULT_PROFILE);

	system.warnings.forEach((warning) => logger.warn("prompt_warning", warning, { player: playerID }));

	const tools = await connectClient(createServer({ client, player: () => Promise.resolve({ ok: true, playerID }), memory, logger }));

	return { playerID, system: system.text, tools, definitions: await toolDefinitions(tools), memoryFolder: memory(playerID), first: true };
}

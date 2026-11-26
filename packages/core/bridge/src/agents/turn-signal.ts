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

// Returns the handler for the core mod's events. One turn runs at a time for
// each agent, so a signal for a turn that is still running is skipped. The
// returned promise settles when the turn it started ends, and never rejects.
export function turnSignal(context: SignalContext): (event: CoreEvent) => Promise<void> {
	const { logger } = context;
	const agents = new Map<number, Agent>();
	const playing = new Set<number>();

	return async (event) => {
		if (event.type !== "turn") {
			return;
		}

		const { playerId } = event;

		if (playing.has(playerId)) {
			logger.info("turn_skipped", `Player ${playerId}'s turn is already being played`, { player: playerId });

			return;
		}

		playing.add(playerId);

		try {
			const agent = agents.get(playerId) ?? await buildAgent(context, playerId);

			agents.set(playerId, agent);

			const result = await playTurn(agent, context);

			if (result.ended) {
				logger.info("turn_ended", `Player ${playerId} ended its turn`, { player: playerId });
			}
		} catch (error) {
			// A turn that throws must not stop the bridge, and the next signal
			// tries again.
			logger.warn("turn_failed", `Player ${playerId}'s turn failed: ${String(error)}`, { player: playerId, reason: String(error) });
		} finally {
			playing.delete(playerId);
		}
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

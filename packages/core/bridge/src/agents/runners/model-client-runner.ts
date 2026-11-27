// The runner for the API key and subscription token modes: the bridge's own
// tool loop, which calls the model through the model client.
// docs/design/agents/turn-loop/README.md#runners has the design.

import type { ModelMessage, ToolModelMessage } from "ai";
import { callTool } from "../../mcp/in-process.js";
import { type ModelTarget, type ToolCall, type Usage, callModel } from "../../model/client.js";
import { logModelCall } from "../../model/usage.js";
import { addSpend, reachedSpendLimit } from "../spend.js";
import { type AgentRunner, type TurnEnd, type TurnRun, afterCall, beforeCall, startRun } from "./shared.js";

const NUDGE = "You wrote no tool call. Take your next action, or call end_turn when you are done.";

// The model call failure that stops the run: a plan's usage limit, which fails
// every call until the plan resets.
const RUN_FAILURE = "limit";

// Each mode builds it with its own model.
export function modelClientRunner(target: ModelTarget): AgentRunner {
	return {
		runTurn: async ({ agent, message, context }, signal) => {
			const run = startRun(agent, context, signal);
			const end = await converse(run, target, [{ role: "user", content: message }]);

			return { end, spend: run.tally.spend };
		},
	};
}

// Calls the model and runs its tool calls until end_turn goes through, or
// the turn reaches a limit. A reply with no tool call gets a nudge.
async function converse(run: TurnRun, target: ModelTarget, messages: ModelMessage[]): Promise<TurnEnd> {
	const { agent, context, signal, tally } = run;

	for (;;) {
		const result = await callModel(target, { system: agent.system, messages, tools: agent.definitions, signal });

		// An aborted call fails, and that failure isn't the model's.
		if (signal.aborted) {
			return { aborted: true };
		}

		if (!result.ok) {
			return { failed: result.error, stopRun: result.kind === RUN_FAILURE };
		}

		logModelCall(context.logger, context.model, result.reply.usage);

		const spent = spendCall(run, result.reply.usage);

		if (spent !== undefined) {
			return spent;
		}

		messages.push(...result.reply.messages);

		if (result.reply.toolCalls.length === 0) {
			tally.failures += 1;

			if (tally.failures > context.limits.retriesPerAction) {
				return { limit: "retriesPerAction" };
			}

			messages.push({ role: "user", content: NUDGE });
			continue;
		}

		const ran = await runCalls(run, result.reply.toolCalls);

		if (!("role" in ran)) {
			return ran;
		}

		messages.push(ran);
	}
}

// Adds the call to the turn's and the run's spend. At a spending limit, the
// reply's tool calls don't run. A run at its limit stops, which wins over a
// turn at its limit, since a forced end would start more turns.
function spendCall({ context, tally }: TurnRun, usage: Usage): TurnEnd | undefined {
	addSpend(tally.spend, usage, context.model.price);
	addSpend(context.runSpend, usage, context.model.price);

	const runLimit = reachedSpendLimit(context.runSpend, context.limits, "run");

	if (runLimit !== undefined) {
		return { runLimit };
	}

	const limit = reachedSpendLimit(tally.spend, context.limits, "turn");

	return limit === undefined ? undefined : { limit };
}

// Runs the calls in order, and stops at the first that ends the turn.
async function runCalls(run: TurnRun, calls: ToolCall[]): Promise<TurnEnd | ToolModelMessage> {
	const message: ToolModelMessage = { role: "tool", content: [] };

	for (const call of calls) {
		const aborted = beforeCall(run);

		if (aborted !== undefined) {
			return aborted;
		}

		const output = await callTool(run.agent.tools, call.name, call.input);
		const end = await afterCall(run, call.name, call.input, output);

		if (end !== undefined) {
			return end;
		}

		message.content.push({
			type: "tool-result",
			toolCallId: call.id,
			toolName: call.name,
			output: { type: output.isError ? "error-text" : "text", value: output.text },
		});
	}

	return message;
}


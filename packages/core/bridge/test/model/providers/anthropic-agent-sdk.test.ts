// Tests for model/providers/anthropic-agent-sdk.ts: the SDK's model list, with
// a fake session, and the runner the mode builds.

import type { ModelInfo as SdkModel, Options } from "@anthropic-ai/claude-agent-sdk";
import { expect, test } from "vitest";
import { type AgentSdk, type InfoSession, agentSdkMode } from "../../../src/model/providers/anthropic-agent-sdk.js";
import { configWithKeys } from "../fake-providers.js";

interface FakeSdk {
	sdk: AgentSdk;
	options: Options[];
	closed: () => boolean;
	// Settles once the session's prompt ends.
	promptEnded: Promise<void>;
}

function fakeSdk(models: () => Promise<SdkModel[]>): FakeSdk {
	const options: Options[] = [];
	let closed = false;
	let endPrompt: () => void = () => undefined;
	const promptEnded = new Promise<void>((resolve) => {
		endPrompt = resolve;
	});

	const info = ({ prompt, options: given }: Parameters<AgentSdk["info"]>[0]): InfoSession => {
		options.push(given);

		void (async () => {
			for await (const message of prompt) {
				throw new Error(`The idle prompt sent ${JSON.stringify(message)}`);
			}

			endPrompt();
		})();

		return {
			supportedModels: models,
			close: () => {
				closed = true;
			},
		};
	};

	return { sdk: { query: () => (async function* () {})(), info }, options, closed: () => closed, promptEnded };
}

const CONFIG = configWithKeys({});

test("lists the SDK's models by alias, each with the efforts it takes", async () => {
	const fake = fakeSdk(() => Promise.resolve([
		{ value: "opus", displayName: "Opus", description: "Most capable", supportedEffortLevels: ["low", "high", "max"] },
		{ value: "haiku", displayName: "Haiku", description: "Fastest" },
	]));

	expect(await agentSdkMode(fake.sdk).listModels(CONFIG)).toEqual({
		ok: true,
		models: [
			{ id: "opus", name: "Opus", efforts: ["provider-default", "low", "high", "max"] },
			{ id: "haiku", name: "Haiku", efforts: ["provider-default"] },
		],
	});
	expect(fake.options[0]).toEqual({ tools: [], settingSources: [], strictMcpConfig: true, persistSession: false });
	expect(fake.closed()).toBe(true);
	await fake.promptEnded;
});

test("a list that fails says why, and still closes the session", async () => {
	const fake = fakeSdk(() => Promise.reject(new Error("Claude Code not found")));

	expect(await agentSdkMode(fake.sdk).listModels(CONFIG)).toEqual({ ok: false, error: "The Agent SDK couldn't list its models: Error: Claude Code not found" });
	expect(fake.closed()).toBe(true);
});

test("is ready, and builds a runner for the chosen model", () => {
	const mode = agentSdkMode(fakeSdk(() => Promise.resolve([])).sdk);
	const built = mode.runner({ ...CONFIG, model: { ...CONFIG.model, id: "opus" } });

	expect(mode.ready(CONFIG)).toEqual({ ok: true });
	expect(built.ok && typeof built.runner.runTurn).toBe("function");
});

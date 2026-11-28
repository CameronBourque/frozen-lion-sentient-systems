// Tests for model/providers/anthropic-agent-sdk.ts: the SDK's login check and
// model list, with a fake session, and the environment each sign-in plays in.

import type { AccountInfo, ModelInfo as SdkModel, Options } from "@anthropic-ai/claude-agent-sdk";
import { expect, test } from "vitest";
import { type AgentSdk, type InfoSession, agentSdkMode } from "../../../src/model/providers/anthropic-agent-sdk.js";
import type { PlanLogin } from "../../../src/model/providers/provider.js";
import { configWithKeys } from "../fake-providers.js";

interface FakeSession {
	models?: () => Promise<SdkModel[]>;
	account?: () => Promise<AccountInfo>;
}

interface FakeSdk {
	sdk: AgentSdk;
	// The options of each session the mode opened.
	options: Options[];
	closed: () => number;
	// Settles once every session's prompt ends.
	promptsEnded: () => Promise<void[]>;
}

function fakeSdk({ models = () => Promise.resolve([]), account = () => Promise.resolve({}) }: FakeSession = {}): FakeSdk {
	const options: Options[] = [];
	const ended: Promise<void>[] = [];
	let closed = 0;

	const info = ({ prompt, options: given }: Parameters<AgentSdk["info"]>[0]): InfoSession => {
		options.push(given);
		ended.push((async () => {
			for await (const message of prompt) {
				throw new Error(`The idle prompt sent ${JSON.stringify(message)}`);
			}
		})());

		return {
			supportedModels: models,
			accountInfo: account,
			close: () => {
				closed += 1;
			},
		};
	};

	return { sdk: { query: () => (async function* () {})(), info }, options, closed: () => closed, promptsEnded: () => Promise.all(ended) };
}

const ENVIRONMENT = { PATH: "/opt/game", ANTHROPIC_API_KEY: "sk-from-environment" };

const CONFIG = configWithKeys({ anthropic: { apiKey: "sk-from-config" } });

function planLogin(fake: FakeSdk): PlanLogin {
	return agentSdkMode(fake.sdk, ENVIRONMENT).planLogin as PlanLogin;
}

test("lists the SDK's models by alias, each with the efforts it takes", async () => {
	const fake = fakeSdk({
		models: () => Promise.resolve([
			{ value: "opus", displayName: "Opus", description: "Most capable", supportedEffortLevels: ["low", "high", "max"] },
			{ value: "haiku", displayName: "Haiku", description: "Fastest" },
		]),
	});

	expect(await agentSdkMode(fake.sdk, ENVIRONMENT).listModels(CONFIG)).toEqual({
		ok: true,
		models: [
			{ id: "opus", name: "Opus", efforts: ["provider-default", "low", "high", "max"] },
			{ id: "haiku", name: "Haiku", efforts: ["provider-default"] },
		],
	});
	expect(fake.options[0]).toEqual({ tools: [], settingSources: [], strictMcpConfig: true, persistSession: false, env: { PATH: "/opt/game" } });
	expect(fake.closed()).toBe(1);
	await fake.promptsEnded();
});

test("a list that fails says why, and still closes the session", async () => {
	const fake = fakeSdk({ models: () => Promise.reject(new Error("Claude Code not found")) });

	expect(await agentSdkMode(fake.sdk, ENVIRONMENT).listModels(CONFIG)).toEqual({ ok: false, error: "The Agent SDK couldn't list its models: Error: Claude Code not found" });
	expect(fake.closed()).toBe(1);
});

test("the plan login is ready when the account has a plan, checked with no key set", async () => {
	const fake = fakeSdk({ account: () => Promise.resolve({ email: "player@example.com", subscriptionType: "max" }) });

	expect(await planLogin(fake).check()).toEqual({ ok: true });
	expect(fake.options[0].env).toEqual({ PATH: "/opt/game" });
	expect(fake.closed()).toBe(1);
});

test("the plan login isn't ready with no plan, or when the check fails", async () => {
	expect(await planLogin(fakeSdk({ account: () => Promise.resolve({}) })).check()).toEqual({ ok: false, reason: expect.stringContaining("No Claude plan is logged in") as unknown });
	expect(await planLogin(fakeSdk({ account: () => Promise.reject(new Error("spawn ENOENT")) })).check()).toEqual({ ok: false, reason: "The Agent SDK couldn't check the Claude login: Error: spawn ENOENT" });
});

test("plays on the plan with no key, until the user picks the API key, which comes from the config", async () => {
	const fake = fakeSdk();
	const mode = agentSdkMode(fake.sdk, ENVIRONMENT);

	await mode.listModels(CONFIG);
	mode.planLogin?.use("api-key");
	await mode.listModels(CONFIG);

	expect(fake.options.map(({ env }) => env)).toEqual([{ PATH: "/opt/game" }, { PATH: "/opt/game", ANTHROPIC_API_KEY: "sk-from-config" }]);
});

test("is ready, and builds a runner for the chosen model", () => {
	const mode = agentSdkMode(fakeSdk().sdk, ENVIRONMENT);
	const built = mode.runner({ ...CONFIG, model: { ...CONFIG.model, id: "opus" } });

	expect(mode.ready(CONFIG)).toEqual({ ok: true });
	expect(mode.planLogin?.label).toBe("Claude plan");
	expect(built.ok && typeof built.runner.runTurn).toBe("function");
});

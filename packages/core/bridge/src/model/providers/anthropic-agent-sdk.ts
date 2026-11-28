// Anthropic's Agent SDK run mode: the SDK checks the login and lists the
// models, and the Agent SDK runner plays the turns.
// docs/design/core/anthropic-agent-sdk-runner.md has the design.

import { type AccountInfo, type ModelInfo as SdkModel, type Options, type SDKUserMessage, query as sdkQuery } from "@anthropic-ai/claude-agent-sdk";
import { type QueryFunction, anthropicAgentSdkRunner } from "../../agents/runners/anthropic-agent-sdk-runner.js";
import { type Config, type Effort, KEY_VARIABLES } from "../../config.js";
import type { ListResult, ModelInfo } from "../list-models.js";
import type { ModeSupport, Ready, SignInChoice } from "./provider.js";

// A session that only reports what the SDK has, such as its models.
export interface InfoSession {
	supportedModels: () => Promise<SdkModel[]>;
	accountInfo: () => Promise<AccountInfo>;
	close: () => void;
}

// The SDK's query(), or fakes in tests: one that plays turns, and one that
// opens a session only to read from it.
export interface AgentSdk {
	query: QueryFunction;
	info: (params: { prompt: AsyncIterable<SDKUserMessage>; options: Options }) => InfoSession;
}

const SDK: AgentSdk = { query: sdkQuery, info: sdkQuery };

// The session loads no tools, settings, or files, and makes no model call.
const INFO_OPTIONS: Options = { tools: [], settingSources: [], strictMcpConfig: true, persistSession: false };

const KEY = KEY_VARIABLES.anthropic;

const NO_PLAN = "No Claude plan is logged in. Log in to Claude Code with your plan, then start the bridge again";

// The mode keeps the user's sign-in, which the picker sets, and plays on the
// plan until then.
export function agentSdkMode(sdk: AgentSdk = SDK, environment: NodeJS.ProcessEnv = process.env): ModeSupport {
	let choice: SignInChoice = "plan";
	const env = (config: Config): Options["env"] => sdkEnv(choice, config, environment);

	return {
		ready: () => ({ ok: true }),
		planLogin: {
			label: "Claude plan",
			check: () => checkPlan(sdk, sdkEnv("plan", undefined, environment)),
			use: (picked) => {
				choice = picked;
			},
		},
		listModels: (config) => listModels(sdk, env(config)),
		runner: (config) => ({ ok: true, runner: anthropicAgentSdkRunner({ id: config.model.id, effort: config.model.effort, env: env(config) }, sdk.query) }),
	};
}

// Claude Code signs in with the key whenever it is set, so the plan's
// environment has no key, and the key's has the one from the config file.
function sdkEnv(choice: SignInChoice, config: Config | undefined, environment: NodeJS.ProcessEnv): Options["env"] {
	const rest = Object.fromEntries(Object.entries(environment).filter(([name]) => name !== KEY));

	return choice === "plan" ? rest : { ...rest, [KEY]: config?.providers.anthropic?.apiKey };
}

// A session on the plan's environment reports the account it is logged in
// to. A Claude plan has a subscription type.
async function checkPlan(sdk: AgentSdk, env: Options["env"]): Promise<Ready> {
	const read = await readSession(sdk, env, (session) => session.accountInfo());

	if (!read.ok) {
		return { ok: false, reason: `The Agent SDK couldn't check the Claude login: ${read.error}` };
	}

	return read.value.subscriptionType === undefined ? { ok: false, reason: NO_PLAN } : { ok: true };
}

// The SDK names its models by alias, such as opus, which OpenRouter doesn't
// list, so each model brings its own efforts.
async function listModels(sdk: AgentSdk, env: Options["env"]): Promise<ListResult> {
	const read = await readSession(sdk, env, (session) => session.supportedModels());

	return read.ok ? { ok: true, models: read.value.map(modelInfo) } : { ok: false, error: `The Agent SDK couldn't list its models: ${read.error}` };
}

type ReadResult<Value> =
	| { ok: true; value: Value }
	| { ok: false; error: string };

// Opens a session only to read from it, and closes it.
async function readSession<Value>(sdk: AgentSdk, env: Options["env"], read: (session: InfoSession) => Promise<Value>): Promise<ReadResult<Value>> {
	const done = new AbortController();
	const session = sdk.info({ prompt: idle(done.signal), options: { ...INFO_OPTIONS, env } });

	try {
		return { ok: true, value: await read(session) };
	} catch (error) {
		return { ok: false, error: String(error) };
	} finally {
		done.abort();
		session.close();
	}
}

function modelInfo({ value, displayName, supportedEffortLevels }: SdkModel): ModelInfo {
	const efforts: Effort[] = ["provider-default", ...(supportedEffortLevels ?? [])];

	return { id: value, name: displayName, efforts };
}

// A prompt that sends nothing, so the session waits until it closes.
function idle(signal: AbortSignal): AsyncIterable<SDKUserMessage> {
	const end = new Promise<IteratorResult<SDKUserMessage>>((resolve) => signal.addEventListener("abort", () => resolve({ done: true, value: undefined }), { once: true }));

	return { [Symbol.asyncIterator]: () => ({ next: () => end }) };
}

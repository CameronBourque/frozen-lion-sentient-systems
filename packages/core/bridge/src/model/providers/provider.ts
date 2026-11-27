// The shape every provider has: the run modes it supports, and what each mode
// does. docs/design/core/run-modes.md has the design.

import type { LanguageModel } from "ai";
import type { AgentRunner } from "../../agents/runners/shared.js";
import type { Config, Provider } from "../../config.js";
import type { CallMode } from "../client.js";
import type { Fetch, ListResult } from "../list-models.js";
import type { SecretResult } from "./mode.js";

// In the order the Run mode menu lists them.
export const RUN_MODES = [
	{ mode: "api-key", label: "API key" },
	{ mode: "subscription", label: "Subscription token" },
	{ mode: "agent-sdk", label: "Agent SDK" },
	{ mode: "cli", label: "CLI" },
] as const;

export type RunModeRow = typeof RUN_MODES[number];

export type RunMode = RunModeRow["mode"];

export const RUN_MODE_NAMES = RUN_MODES.map(({ mode }) => mode);

export function runModeLabel(mode: RunMode): string {
	return (RUN_MODES.find((row) => row.mode === mode) as RunModeRow).label;
}

export type Ready =
	| { ok: true }
	| { ok: false; reason: string };

export type ModelResult =
	| { ok: true; model: LanguageModel }
	| { ok: false; error: string };

export type BuiltRunner =
	| { ok: true; runner: AgentRunner }
	| { ok: false; error: string };

// A plan mode's sign-in: its row in the provider menu, and what picking it
// runs.
export interface SignIn {
	label: string;
	run: () => Promise<SecretResult>;
}

export interface ModeSupport {
	ready: (config: Config) => Ready;
	// Only in a mode that signs in through the browser.
	signIn?: SignIn;
	listModels: (config: Config, fetchPage?: Fetch) => Promise<ListResult>;
	// Plays the agents' turns with the model in config.model.
	runner: (config: Config) => BuiltRunner;
}

// A mode the model client calls also builds the model on its own, for a
// single call.
export interface CallModeSupport extends ModeSupport {
	model: (config: Config, modelId: string) => ModelResult;
}

export type ModeSupports = { [Mode in RunMode]?: Mode extends CallMode ? CallModeSupport : ModeSupport };

export interface ProviderDef {
	name: Provider;
	// A run mode missing here isn't available for the provider.
	modes: ModeSupports;
}

// The shape every provider has: the run modes it supports, and what each mode
// does. docs/design/core/run-modes.md has the design.

import type { LanguageModel } from "ai";
import type { Config, Provider } from "../../config.js";
import type { Fetch, ListResult } from "../list-models.js";

// In the order the Run mode menu lists them.
export const RUN_MODES = [
	{ mode: "api-key", label: "API key" },
	{ mode: "subscription", label: "Subscription token" },
	{ mode: "agent-sdk", label: "Agent SDK" },
	{ mode: "cli", label: "CLI" },
] as const;

export type RunModeRow = typeof RUN_MODES[number];

export type RunMode = RunModeRow["mode"];

export type Ready =
	| { ok: true }
	| { ok: false; reason: string };

export type ModelResult =
	| { ok: true; model: LanguageModel }
	| { ok: false; error: string };

export interface ModeSupport {
	ready: (config: Config) => Ready;
	listModels: (config: Config, fetchPage?: Fetch) => Promise<ListResult>;
	model: (config: Config, modelId: string) => ModelResult;
}

export interface ProviderDef {
	name: Provider;
	// A run mode missing here isn't available for the provider.
	modes: Partial<Record<RunMode, ModeSupport>>;
}

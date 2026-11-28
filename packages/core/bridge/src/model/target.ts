// Builds what agents play with, from the chosen model and run mode: the runner
// for their turns, or the model target for a single call.
// docs/design/core/run-modes.md has the design.

import type { Config, Provider } from "../config.js";
import { type ModelTarget, isCallMode } from "./client.js";
import { type BuiltRunner, type ModeSupports, type ProviderDef, type RunMode, runModeLabel } from "./providers/provider.js";

export type TargetResult =
	| { ok: true; target: ModelTarget }
	| { ok: false; error: string };

type ModeResult<Mode extends RunMode> =
	| { ok: true; provider: Provider; support: NonNullable<ModeSupports[Mode]> }
	| { ok: false; error: string };

function findMode<Mode extends RunMode>(config: Config, mode: Mode, offered: ProviderDef[]): ModeResult<Mode> {
	const { provider } = config.model;

	if (provider === "") {
		return { ok: false, error: "No model is chosen" };
	}

	const support = offered.find(({ name }) => name === provider)?.modes[mode];

	return support === undefined ? { ok: false, error: `${provider} has no ${runModeLabel(mode)} mode` } : { ok: true, provider, support };
}

// Every run mode builds a runner, whoever runs the tool loop.
export function agentRunner(config: Config, mode: RunMode, offered: ProviderDef[]): BuiltRunner {
	const found = findMode(config, mode, offered);

	return found.ok ? found.support.runner(config) : found;
}

// The Agent SDK and CLI modes run their own loop, so the model client can't
// call them.
export function modelTarget(config: Config, mode: RunMode, offered: ProviderDef[]): TargetResult {
	if (!isCallMode(mode)) {
		return { ok: false, error: `${runModeLabel(mode)} mode runs its own loop, which the model client can't call` };
	}

	const found = findMode(config, mode, offered);

	if (!found.ok) {
		return found;
	}

	const { id, effort } = config.model;
	const built = found.support.model(config, id);

	return built.ok ? { ok: true, target: { model: built.model, provider: found.provider, mode, effort } } : built;
}

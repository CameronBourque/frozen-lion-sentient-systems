// Builds the model target that agents call, from the chosen model and run
// mode. docs/design/core/model-client.md has the design.

import type { Config } from "../config.js";
import { type ModelTarget, isCallMode } from "./client.js";
import { type ProviderDef, type RunMode, runModeLabel } from "./providers/provider.js";

export type TargetResult =
	| { ok: true; target: ModelTarget }
	| { ok: false; error: string };

// The Agent SDK and CLI modes run their own loop, so the model client can't
// call them.
export function modelTarget(config: Config, mode: RunMode, offered: ProviderDef[]): TargetResult {
	const { provider, id, effort } = config.model;

	if (provider === "") {
		return { ok: false, error: "No model is chosen" };
	}

	if (!isCallMode(mode)) {
		return { ok: false, error: `${runModeLabel(mode)} mode runs its own loop, which the bridge can't call yet` };
	}

	const built = offered.find(({ name }) => name === provider)?.modes[mode]?.model(config, id);

	if (built === undefined) {
		return { ok: false, error: `${provider} has no ${runModeLabel(mode)} mode` };
	}

	return built.ok ? { ok: true, target: { model: built.model, provider, mode, effort } } : built;
}

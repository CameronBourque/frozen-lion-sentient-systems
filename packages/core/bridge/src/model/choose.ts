// Chooses the model when the bridge starts: the picker in a terminal, or the
// saved model without one. docs/design/core/picker.md has the design.

import type { Config } from "../config.js";
import { saveModel } from "../load-config.js";
import type { Logger } from "../log.js";
import { type PickerIo, offeredProviders, pickModel, savedModelWarning } from "./picker.js";
import { RUN_MODES, type RunMode, type RunModeRow } from "./providers/provider.js";

// With no ask, there is no terminal to ask in.
export interface ChooseIo {
	ask?: PickerIo["ask"];
	providers: PickerIo["providers"];
	facts: PickerIo["facts"];
}

function logChosen(logger: Logger, config: Config, mode: RunMode): void {
	const { provider, id, effort } = config.model;
	const { label } = RUN_MODES.find((row) => row.mode === mode) as RunModeRow;

	logger.info("model_chosen", `Agents use ${provider} ${id} in ${label} mode, with ${effort === "" ? "the provider's default" : effort} effort`, { mode, provider, id, effort });
}

// Sets config.model to the choice, saves a new one, and logs the model agents
// use, or why they can't play. Returns the run mode, or undefined when the
// user cancels.
export async function chooseModel(config: Config, file: string, logger: Logger, { ask, providers, facts }: ChooseIo): Promise<RunMode | undefined> {
	// Without a terminal, the bridge uses API key mode with the saved model.
	if (ask === undefined) {
		// With no key at all, keyWarning already says what to do.
		if (offeredProviders(config, providers, "api-key").length > 0) {
			const warning = savedModelWarning(config, file, providers);

			if (warning === undefined) {
				logChosen(logger, config, "api-key");
			} else {
				logger.warn("model_warning", warning);
			}
		}

		return "api-key";
	}

	const picked = await pickModel(config, { ask, providers, facts, warn: (text) => logger.warn("model_warning", text) });

	if (picked.result === "cancelled") {
		return undefined;
	}

	// A kept model may differ from the saved one in its price.
	config.model = picked.model;

	if (picked.result === "picked") {
		const saveError = saveModel(file, picked.model);

		if (saveError !== undefined) {
			logger.warn("model_warning", saveError);
		}
	}

	// The picker returns only a model that can play in its mode.
	logChosen(logger, config, picked.mode);

	return picked.mode;
}

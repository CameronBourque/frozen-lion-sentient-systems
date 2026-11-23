// Chooses the model when the bridge starts: the picker in a terminal, or the
// saved model without one. docs/design/core/model-client.md has the design.

import type { Config } from "../config.js";
import { saveModel } from "../load-config.js";
import type { Logger } from "../log.js";
import { type PickerIo, offeredProviders, pickModel, savedModelWarning } from "./picker.js";

// With no ask, there is no terminal to ask in.
export interface ChooseIo {
	ask?: PickerIo["ask"];
	providers: PickerIo["providers"];
	facts: PickerIo["facts"];
}

// Sets config.model to the choice, saves a new one, and logs the model agents
// use, or why they can't play. Returns false when the user cancels.
export async function chooseModel(config: Config, file: string, logger: Logger, { ask, providers, facts }: ChooseIo): Promise<boolean> {
	if (ask !== undefined) {
		const picked = await pickModel(config, { ask, providers, facts, warn: (text) => logger.warn("model_warning", text) });

		if (picked.result === "cancelled") {
			return false;
		}

		if (picked.result === "picked") {
			config.model = picked.model;

			const saveError = saveModel(file, picked.model);

			if (saveError !== undefined) {
				logger.warn("model_warning", saveError);
			}
		}
	}

	// With no key at all, keyWarning already says what to do, and no model can
	// play. In a terminal, the picker returns only a mode that can play.
	if (offeredProviders(config, providers, "api-key").length === 0) {
		return true;
	}

	const warning = savedModelWarning(config, file, providers);
	const { provider, id, effort } = config.model;

	if (warning === undefined) {
		logger.info("model_chosen", `Agents use ${provider} ${id}, with ${effort === "" ? "the provider's default" : effort} effort`, { provider, id, effort });
	} else {
		logger.warn("model_warning", warning);
	}

	return true;
}

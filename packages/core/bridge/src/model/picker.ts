// Asks the user for the provider, the model, and the effort when the bridge
// starts in a terminal. docs/design/core/model-client.md has the design.

import { type Config, EFFORTS, type ModelSetting, NO_PRICE, PROVIDERS, type Provider } from "../config.js";
import type { ListResult, ModelInfo } from "./list-models.js";

export interface PickerIo {
	// Returns the chosen row, or undefined when the user cancels.
	ask: (title: string, labels: string[], start: number) => Promise<number | undefined>;
	list: (provider: Provider, apiKey: string) => Promise<ListResult>;
	warn: (text: string) => void;
}

// The new choice, or the saved one when there is nothing to ask, or
// cancelled when the user pressed Ctrl+C.
export type PickResult =
	| { result: "picked"; model: ModelSetting }
	| { result: "kept"; model: ModelSetting }
	| { result: "cancelled" };

export function keyedProviders(config: Config): Provider[] {
	return PROVIDERS.filter((provider) => (config.providers[provider]?.apiKey ?? "") !== "");
}

function modelLabel({ id, name }: ModelInfo): string {
	return name === id ? id : `${name} (${id})`;
}

// Asks one menu, starting on the saved choice, or on the first row when the
// saved choice isn't in the list.
async function askFor<T>(io: PickerIo, title: string, choices: readonly T[], labels: string[], saved: unknown): Promise<T | undefined> {
	const row = await io.ask(title, labels, Math.max(choices.findIndex((choice) => choice === saved), 0));

	return row === undefined ? undefined : choices[row];
}

export async function pickModel(config: Config, io: PickerIo): Promise<PickResult> {
	const saved = config.model;
	const keyed = keyedProviders(config);

	// keyWarning already says that no provider has a key.
	if (keyed.length === 0) {
		return { result: "kept", model: saved };
	}

	const provider = keyed.length === 1 ? keyed[0] : await askFor(io, "Provider", keyed, keyed, saved.provider);

	if (provider === undefined) {
		return { result: "cancelled" };
	}

	const listed = await io.list(provider, config.providers[provider]?.apiKey ?? "");

	if (!listed.ok || listed.models.length === 0) {
		io.warn(`${listed.ok ? `${provider} listed no models` : listed.error}, so the bridge keeps the saved model`);

		return { result: "kept", model: saved };
	}

	const ids = listed.models.map(({ id }) => id);
	const id = await askFor(io, `${provider} model`, ids, listed.models.map(modelLabel), saved.id);

	if (id === undefined) {
		return { result: "cancelled" };
	}

	const effort = await askFor(io, "Effort", EFFORTS, [...EFFORTS], saved.effort);
	// The saved price belongs to the saved model.
	const price = provider === saved.provider && id === saved.id ? saved.price : NO_PRICE;

	return effort === undefined ? { result: "cancelled" } : { result: "picked", model: { provider, id, effort, price } };
}

// Says why the saved choice can't play, or nothing when it can.
export function savedModelWarning(config: Config, file: string): string | undefined {
	const { provider, id } = config.model;

	if (provider === "" || id === "") {
		return `No model is picked, so agents can't play. Start the bridge in a terminal to pick one, or set model in ${file}`;
	}

	return keyedProviders(config).includes(provider)
		? undefined
		: `The picked model is from ${provider}, which has no API key, so agents can't play. Add one in ${file}, or start the bridge in a terminal to pick another model`;
}

// Asks the user for the provider, the model, and the effort when the bridge
// starts in a terminal. docs/design/core/model-client.md has the design.

import { type Config, type Effort, type ModelSetting, NO_PRICE, PROVIDERS, type Price, type Provider } from "../config.js";
import type { ListResult, ModelInfo } from "./list-models.js";
import { type Facts, type FactsResult, callsTools, effortsFor, priceFor, priceLabel } from "./model-facts.js";

export interface PickerIo {
	// Returns the chosen row, or undefined when the user cancels.
	ask: (title: string, labels: string[], start: number) => Promise<number | undefined>;
	list: (provider: Provider, apiKey: string) => Promise<ListResult>;
	facts: () => Promise<FactsResult>;
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

function modelLabel({ id, name }: ModelInfo, provider: Provider, facts: Facts): string {
	return `${name === id ? id : `${name} (${id})`}, ${priceLabel(priceFor(facts, provider, id))}`;
}

// Names the level that provider-default means, when OpenRouter says.
function effortLabel(effort: Effort, defaultEffort: string | undefined): string {
	return effort === "provider-default" && defaultEffort !== undefined ? `${effort} (${defaultEffort})` : effort;
}

function isPriced(price: Price): boolean {
	return price.input !== "" && price.output !== "";
}

// A price the user saved for the same model wins, since they may have entered
// it themselves. Otherwise OpenRouter's, or blank.
function chosenPrice(saved: ModelSetting, provider: Provider, id: string, facts: Facts): Price {
	if (provider === saved.provider && id === saved.id && isPriced(saved.price)) {
		return saved.price;
	}

	return priceFor(facts, provider, id) ?? NO_PRICE;
}

// Asks one menu, starting on the saved choice, or on the first row when the
// saved choice isn't in the list.
async function askFor<T>(io: PickerIo, title: string, choices: readonly T[], labels: string[], saved: unknown): Promise<T | undefined> {
	const row = await io.ask(title, labels, Math.max(choices.findIndex((choice) => choice === saved), 0));

	return row === undefined ? undefined : choices[row];
}

type AfterFailure = "again" | "use" | "quit";

// After a failed model list, the user decides. The first row is never the
// saved model, so Enter never spends money on a model the user didn't pick.
// Use appears only when the saved model can play.
async function askAfterFailure(io: PickerIo, config: Config, keyed: Provider[]): Promise<AfterFailure> {
	const { provider, id } = config.model;
	const choices: AfterFailure[] = ["again", ...(canPlay(config) ? ["use" as const] : []), "quit"];
	const labels: Record<AfterFailure, string> = {
		again: keyed.length > 1 ? "Pick another provider" : "Try again",
		use: `Use ${id} (${provider})`,
		quit: "Quit",
	};
	const row = await io.ask("What now?", choices.map((choice) => labels[choice]), 0);

	return row === undefined ? "quit" : choices[row];
}

// The models that call tools. Without OpenRouter's facts there is nothing to
// go on, so every model stays.
function usableModels(models: ModelInfo[], provider: Provider, fetched: FactsResult): ModelInfo[] {
	return fetched.ok ? models.filter(({ id }) => callsTools(fetched.facts, provider, id)) : models;
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

	const [listed, fetched] = await Promise.all([io.list(provider, config.providers[provider]?.apiKey ?? ""), io.facts()]);

	if (!fetched.ok) {
		io.warn(`${fetched.error}, so the menu lists every model ${provider} has, with no prices`);
	}

	const models = listed.ok ? usableModels(listed.models, provider, fetched) : [];

	if (models.length > 0) {
		return pickFromList(config, io, provider, models, fetched);
	}

	io.warn(listed.ok ? `${provider} listed no models that call tools` : listed.error);

	const next = await askAfterFailure(io, config, keyed);

	if (next === "again") {
		return pickModel(config, io);
	}

	return next === "use" ? { result: "kept", model: saved } : { result: "cancelled" };
}

// Asks for the model and the effort from a provider's list.
async function pickFromList(config: Config, io: PickerIo, provider: Provider, models: ModelInfo[], fetched: FactsResult): Promise<PickResult> {
	const saved = config.model;
	const facts = fetched.ok ? fetched.facts : {};
	const ids = models.map(({ id }) => id);
	const labels = models.map((model) => modelLabel(model, provider, facts));
	const id = await askFor(io, `${provider} model`, ids, labels, saved.id);

	if (id === undefined) {
		return { result: "cancelled" };
	}

	const { efforts, defaultEffort } = effortsFor(facts, provider, id);
	const effortLabels = efforts.map((effort) => effortLabel(effort, defaultEffort));
	const effort = await askFor(io, "Effort", efforts, effortLabels, saved.effort);

	if (effort === undefined) {
		return { result: "cancelled" };
	}

	const price = chosenPrice(saved, provider, id, facts);

	if (fetched.ok && !isPriced(price)) {
		io.warn(`OpenRouter lists no price for ${id}, so the log shows no cost. Set model.price in the config file to see it`);
	}

	return { result: "picked", model: { provider, id, effort, price } };
}

// A saved model can play when it is picked and its provider has a key.
function canPlay(config: Config): boolean {
	const { provider, id } = config.model;

	return provider !== "" && id !== "" && keyedProviders(config).includes(provider);
}

// Says why the saved choice can't play, or nothing when it can.
export function savedModelWarning(config: Config, file: string): string | undefined {
	const { provider, id } = config.model;

	if (canPlay(config)) {
		return undefined;
	}

	return provider === "" || id === ""
		? `No model is picked, so agents can't play. Start the bridge in a terminal to pick one, or set model in ${file}`
		: `The picked model is from ${provider}, which has no API key, so agents can't play. Add one in ${file}, or start the bridge in a terminal to pick another model`;
}

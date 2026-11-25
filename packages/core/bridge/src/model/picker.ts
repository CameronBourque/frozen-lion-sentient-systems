// Asks the user for the run mode, the provider, the model, and the effort when
// the bridge starts in a terminal. docs/design/core/run-modes.md and
// docs/design/core/model-client.md have the design.

import { type Config, type Effort, type ModelSetting, NO_PRICE, type Price, type Provider } from "../config.js";
import type { ModelInfo } from "./list-models.js";
import { type Facts, type FactsResult, callsTools, effortsFor, priceFor, priceLabel } from "./model-facts.js";
import { type ModeSupport, type ProviderDef, RUN_MODES, type RunMode, type RunModeRow } from "./providers/provider.js";

export interface PickerIo {
	// Returns the chosen row, or undefined when the user cancels.
	ask: (title: string, labels: string[], start: number) => Promise<number | undefined>;
	// providers(), or fakes in tests.
	providers: ProviderDef[];
	facts: () => Promise<FactsResult>;
	warn: (text: string) => void;
}

// The new choice, or the saved one when the user keeps it, each with its run
// mode, or cancelled when the user quit or pressed Ctrl+C.
export type PickResult =
	| { result: "picked"; mode: RunMode; model: ModelSetting }
	| { result: "kept"; mode: RunMode; model: ModelSetting }
	| { result: "cancelled" };

interface Offered {
	name: Provider;
	mode: ModeSupport;
}

// The providers that can play in a run mode.
export function offeredProviders(config: Config, providers: ProviderDef[], mode: RunMode): Offered[] {
	return providers.flatMap(({ name, modes }) => {
		const support = modes[mode];

		return support !== undefined && support.ready(config).ok ? [{ name, mode: support }] : [];
	});
}

// Why each provider that has a run mode can't play in it.
function notReadyReasons(config: Config, providers: ProviderDef[], mode: RunMode): string[] {
	return providers.flatMap(({ modes }) => {
		const ready = modes[mode]?.ready(config);

		return ready?.ok === false ? [ready.reason] : [];
	});
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

// Each price the user saved for the same model wins, since they may have
// entered it themselves. A blank one takes OpenRouter's, so a price saved
// before the cache prices existed gains them.
function chosenPrice(saved: ModelSetting, provider: Provider, id: string, facts: Facts): Price {
	const listed = priceFor(facts, provider, id) ?? NO_PRICE;

	if (provider !== saved.provider || id !== saved.id) {
		return listed;
	}

	const fields = Object.keys(listed) as (keyof Price)[];

	return Object.fromEntries(fields.map((field) => [field, saved.price[field] === "" ? listed[field] : saved.price[field]])) as Price;
}

// Asks one menu, starting on the saved choice, or on the first row when the
// saved choice isn't in the list.
async function askFor<T>(io: PickerIo, title: string, choices: readonly T[], labels: string[], saved: unknown): Promise<T | undefined> {
	const row = await io.ask(title, labels, Math.max(choices.findIndex((choice) => choice === saved), 0));

	return row === undefined ? undefined : choices[row];
}

type AfterFailure = "provider" | "mode" | "use" | "quit";

// After a failed model list, the user decides. The first row is never the
// saved model, so Enter never spends money on a model the user didn't pick.
// Use appears only when the saved model can play.
async function askAfterFailure(io: PickerIo, config: Config, offered: Offered[]): Promise<AfterFailure> {
	const { provider, id } = config.model;
	const choices: AfterFailure[] = ["provider", "mode", ...(canPlay(config, offered) ? ["use" as const] : []), "quit"];
	const labels: Record<AfterFailure, string> = {
		provider: offered.length > 1 ? "Pick another provider" : "Try again",
		mode: "Pick another run mode",
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

// Asks for the run mode until the user picks one that a provider has, or
// quits. Quit is the last row, after the modes.
async function askRunMode(io: PickerIo): Promise<RunModeRow | undefined> {
	const available = (mode: RunMode) => io.providers.some(({ modes }) => modes[mode] !== undefined);
	const labels = RUN_MODES.map(({ mode, label }) => available(mode) ? label : `${label} (not available yet)`);
	const row = await io.ask("Run mode", [...labels, "Quit"], 0);

	if (row === undefined || row === RUN_MODES.length) {
		return undefined;
	}

	const chosen = RUN_MODES[row];

	if (!available(chosen.mode)) {
		io.warn(`${chosen.label} isn't available yet, so pick another run mode`);

		return askRunMode(io);
	}

	return chosen;
}

export async function pickModel(config: Config, io: PickerIo): Promise<PickResult> {
	const run = await askRunMode(io);

	if (run === undefined) {
		return { result: "cancelled" };
	}

	if (offeredProviders(config, io.providers, run.mode).length === 0) {
		const reasons = notReadyReasons(config, io.providers, run.mode);

		io.warn(`No provider can play in ${run.label}, so pick another run mode or Quit. ${reasons.join(". ")}`);

		return pickModel(config, io);
	}

	return pickProvider(config, io, run.mode);
}

// Asks for the provider in a run mode, then its model and effort.
async function pickProvider(config: Config, io: PickerIo, runMode: RunMode): Promise<PickResult> {
	const saved = config.model;
	const offered = offeredProviders(config, io.providers, runMode);
	const names = offered.map(({ name }) => name);
	const provider = names.length === 1 ? names[0] : await askFor(io, "Provider", names, names, saved.provider);

	if (provider === undefined) {
		return { result: "cancelled" };
	}

	const { mode } = offered[names.indexOf(provider)];
	const [listed, fetched] = await Promise.all([mode.listModels(config), io.facts()]);

	if (!fetched.ok) {
		io.warn(`${fetched.error}, so the menu lists every model ${provider} has, with no prices`);
	}

	const models = listed.ok ? usableModels(listed.models, provider, fetched) : [];

	if (models.length > 0) {
		return pickFromList(config, io, runMode, provider, models, fetched);
	}

	io.warn(listed.ok ? `${provider} listed no models that call tools` : listed.error);

	const next = await askAfterFailure(io, config, offered);

	if (next === "provider") {
		return pickProvider(config, io, runMode);
	}

	if (next === "mode") {
		return pickModel(config, io);
	}

	return next === "use" ? { result: "kept", mode: runMode, model: saved } : { result: "cancelled" };
}

// Asks for the model and the effort from a provider's list.
async function pickFromList(config: Config, io: PickerIo, runMode: RunMode, provider: Provider, models: ModelInfo[], fetched: FactsResult): Promise<PickResult> {
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

	return { result: "picked", mode: runMode, model: { provider, id, effort, price } };
}

// A saved model can play when it is picked and its provider is offered.
function canPlay(config: Config, offered: Offered[]): boolean {
	const { provider, id } = config.model;

	return provider !== "" && id !== "" && offered.some(({ name }) => name === provider);
}

// Says why the saved choice can't play in API key mode, which the bridge uses
// without a terminal, or nothing when it can.
export function savedModelWarning(config: Config, file: string, providers: ProviderDef[]): string | undefined {
	const { provider, id } = config.model;

	if (canPlay(config, offeredProviders(config, providers, "api-key"))) {
		return undefined;
	}

	return provider === "" || id === ""
		? `No model is picked, so agents can't play. Start the bridge in a terminal to pick one, or set model in ${file}`
		: `The picked model is from ${provider}, which has no API key, so agents can't play. Add one in ${file}, or start the bridge in a terminal to pick another model`;
}

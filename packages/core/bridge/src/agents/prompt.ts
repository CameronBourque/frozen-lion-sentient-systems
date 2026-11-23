// Builds an agent's prompt: the system prompt once per agent, and a turn
// message each turn. docs/design/agents/prompt.md has the design.

import type { Knowledge } from "../knowledge.js";
import type { JournalEntry, Memory } from "../memory/store.js";
import type { State } from "../state/state.js";

// The names of an agent's personality and sweat level files, without ".md".
export interface AgentProfile {
	personality: string;
	sweatLevel: string;
}

// Until the setup screen has its dropdowns, every agent plays this way.
export const DEFAULT_PROFILE: AgentProfile = { personality: "neutral", sweatLevel: "balanced" };

// What a turn message is built from. journalEntries is the config file's cap
// on the newest entries it holds.
export interface TurnInput {
	state: State;
	memory: Memory;
	journalEntries: number;
}

// The turn message's parts, in order.
const TURN_PARTS: ((input: TurnInput) => string)[] = [
	({ state }) => `# Turn ${state.turn}\n\nIt's your turn.`,
	({ memory }) => `## Your plan\n\n${memory.plan === "" ? "You have no plan yet. Make one with update_plan." : memory.plan}`,
	({ memory, journalEntries }) => `## Your journal\n\n${journalText(memory.journal, journalEntries)}`,
	({ state }) => `## End-turn blockers\n\n${blockersText(state.blockers)}`,
	({ state }) => `## State\n\n${stateText(state)}`,
];

// The state fields that have parts of their own.
const STATE_PARTS_SEPARATED = new Set(["turn", "blockers"]);

// The knowledge files in order. It takes no state, so the system prompt stays
// the same between turns and the provider's prompt cache keeps it. A name with
// no file falls back to the default, so a typo doesn't stop the game.
export function systemPrompt(knowledge: Knowledge, profile: AgentProfile): { text: string; warnings: string[] } {
	const warnings: string[] = [];

	const file = (folder: string, name: string, fallback: string): string => {
		if (knowledge.has(`${folder}/${name}.md`)) {
			return `${folder}/${name}.md`;
		}

		warnings.push(`There is no ${folder}/${name}.md, so the agent uses ${fallback}`);

		return `${folder}/${fallback}.md`;
	};

	const files = ["rules/play.md", file("personalities", profile.personality, DEFAULT_PROFILE.personality), file("sweat", profile.sweatLevel, DEFAULT_PROFILE.sweatLevel)];

	return { text: files.flatMap((name) => knowledge.get(name)?.trim() ?? []).join("\n\n"), warnings };
}

export function turnMessage(input: TurnInput): string {
	return TURN_PARTS.map((part) => part(input)).join("\n\n");
}

// The newest entries, oldest first, so they read in the order they happened.
function journalText(journal: JournalEntry[], cap: number): string {
	const newest = cap === 0 ? [] : journal.slice(-cap);

	if (newest.length === 0) {
		return "No entries yet. Add one with add_journal_entry when something happens that a later turn needs to know.";
	}

	const shown = newest.length < journal.length ? `Your newest ${newest.length} of ${journal.length} entries.\n\n` : "";

	return shown + newest.map((entry) => `### Turn ${entry.turn}\n\n${entry.text}`).join("\n\n");
}

function blockersText(blockers: State["blockers"]): string {
	const lines = blockers.list.map(({ type, choice }) => (choice === undefined ? `- ${type}` : `- ${type}, resolved by ${choice} in get_choices`));

	if (blockers.units.length > 0) {
		lines.push(`- Units that need orders: ${blockers.units.join(", ")}`);
	}

	return lines.length > 0 ? lines.join("\n") : "None. End the turn when your other actions are done.";
}

// The state as get_state returns it, without the fields that have parts.
function stateText(state: State): string {
	return JSON.stringify(Object.fromEntries(Object.entries(state).filter(([field]) => !STATE_PARTS_SEPARATED.has(field))));
}

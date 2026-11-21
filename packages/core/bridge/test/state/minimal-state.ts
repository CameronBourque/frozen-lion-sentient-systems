// The smallest state the schema accepts, for tests that need a whole state.
// The schemas are checked in contract.test.ts.

import type { State } from "../../src/state/state.js";

// Every section, empty where it can be, with one blocker, so state.test.ts has
// a name to cut in the middle.
export const MINIMAL_STATE: State = {
	turn: 1,
	blockers: { list: [{ type: "ENDTURN_BLOCKING_RESEARCH" }], units: [] },
	cities: [],
	units: [],
	tiles: [],
	proposals: [],
	sessions: [],
	events: [],
	scoreboard: [],
	victories: {},
	religion: {},
	diplomacy: [],
	envoys: { tokens: 0, influence: { points: 0, perTurn: 0, threshold: 0, envoys: 0 }, cityStates: [] },
	espionage: { capacity: 0, operatives: [], cities: [], history: [], captives: [] },
	greatPeople: [],
	continents: [],
	greatWorks: { slots: [], buildings: [], works: 0, spaces: 0, provides: [] },
	trade: { outgoing: [], incoming: [], tourismBonus: 0 },
	player: {
		gold: { balance: 0, perTurn: 0 },
		faith: { balance: 0, perTurn: 0 },
		science: 0,
		culture: 0,
		tourism: 0,
		resources: [],
		income: {
			gold: { total: 0 },
			faith: { total: 0 },
			science: { total: 0 },
			culture: { total: 0 },
			expenses: { total: 0, cities: 0, units: 0, deals: 0 },
			cities: [],
			unitUpkeep: [],
			deals: [],
		},
	},
	rivals: { cities: [], units: [] },
};

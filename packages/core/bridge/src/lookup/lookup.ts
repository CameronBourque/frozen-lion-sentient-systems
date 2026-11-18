// Reads game facts from the Civilopedia through the core mod: a search, one
// page, the sections, and one section's pages, through the stash in stash.ts.
// docs/design/core/mod/civilopedia.md describes the lookup.

import { z } from "zod";
import { readStash, type StashResult } from "../stash.js";
import type { TunerClient } from "../tuner/client.js";

const SECTION_ID = z.string().describe("Such as UNITS or CONCEPTS.");
const PAGE_ID = z.string().describe("Such as UNIT_SETTLER or MOVEMENT_1. A game object's page ID is its type.");

const SEARCH_RESULT = z.object({
	sectionID: SECTION_ID,
	pageID: PAGE_ID,
	title: z.string().describe("In the game's language."),
	snippet: z.string().optional().describe(
		"The text around the match, or the page's first sentence. Left out for a page with no text.",
	),
});

export const SEARCH = z.object({
	results: z.array(SEARCH_RESULT).describe("At most 10, best match first."),
});

export type Search = z.infer<typeof SEARCH>;

export const PAGE = z.object({
	sectionID: SECTION_ID,
	pageID: PAGE_ID,
	title: z.string().describe("In the game's language."),
	text: z.string().optional().describe(
		"The page as the game's Civilopedia shows it, without history, with ## headings for its boxes and parts and - lines for their entries. Left out for an empty page.",
	),
});

export type Page = z.infer<typeof PAGE>;

export const SECTIONS = z.object({
	sections: z.array(z.object({
		sectionID: SECTION_ID,
		title: z.string().describe("In the game's language."),
		pageCount: z.number(),
	})).describe("In the game's order."),
});

export type Sections = z.infer<typeof SECTIONS>;

export const SECTION = z.object({
	sectionID: SECTION_ID,
	title: z.string().describe("In the game's language."),
	groups: z.array(z.object({
		title: z.string().optional().describe("Such as Combat or Movement. Left out for the pages with no group, which come first."),
		pages: z.array(z.object({ pageID: PAGE_ID, title: z.string() })),
	})).describe("The section's pages by group, in the game's order."),
});

export type Section = z.infer<typeof SECTION>;

// What the core mod gives when it can't find a page or a section: an error
// that says what to do instead.
const NOT_FOUND = z.object({ error: z.string() });

// The page call's JSON, a page or an error. The contract test reads the page
// call's fixtures with it.
export const PAGE_REPLY = z.union([PAGE, NOT_FOUND]);

// The section call's JSON, a section or an error.
export const SECTION_REPLY = z.union([SECTION, NOT_FOUND]);

// Returns the text as a Lua string literal. A query is the model's own text,
// so each quote, backslash, and control character is escaped, as \ddd for a
// control character, which Lua 5.1 reads.
export function luaString(text: string): string {
	const escaped = [...text].map((character) => {
		const code = character.charCodeAt(0);

		return code < 32 || code === 127 || character === "\"" || character === "\\" ? `\\${String(code).padStart(3, "0")}` : character;
	});

	return `"${escaped.join("")}"`;
}

// Returns the read with a not-found reply turned into a failure with its
// error.
function failNotFound<T extends object>(result: StashResult<T | { error: string }>): StashResult<T> {
	if (result.ok && "error" in result.value) {
		return { ok: false, error: result.value.error };
	}

	return result as StashResult<T>;
}

// Searches the Civilopedia's page IDs, titles, and text for the query.
export function lookup(client: TunerClient, query: string): Promise<StashResult<Search>> {
	return readStash(client, `SentientSystems_Lookup(${luaString(query)})`, SEARCH, "lookup");
}

// Reads one page by its page ID, in any case. The section is needed only for
// a page ID that more than one section has, such as INTRO.
export async function lookupPage(client: TunerClient, pageID: string, sectionID?: string): Promise<StashResult<Page>> {
	const args = sectionID === undefined ? luaString(pageID) : `${luaString(pageID)}, ${luaString(sectionID)}`;

	return failNotFound(await readStash(client, `SentientSystems_LookupPage(${args})`, PAGE_REPLY, "Civilopedia page"));
}

export function lookupSections(client: TunerClient): Promise<StashResult<Sections>> {
	return readStash(client, "SentientSystems_LookupSections()", SECTIONS, "Civilopedia sections");
}

// Reads one section's pages by group, by its section ID, in any case.
export async function lookupSection(client: TunerClient, sectionID: string): Promise<StashResult<Section>> {
	return failNotFound(await readStash(client, `SentientSystems_LookupSection(${luaString(sectionID)})`, SECTION_REPLY, "Civilopedia section"));
}
